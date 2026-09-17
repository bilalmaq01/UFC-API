"""HTTP endpoints for fighters: fuzzy search, list, and detail."""

import time
from typing import Final

from fastapi import APIRouter, Depends, HTTPException, Query
from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.fighter import Fighter
from app.schemas.fighter import FighterComparison, FighterOut

router = APIRouter(prefix="/fighters", tags=["fighters"])


_CACHE_TTL_SECONDS: Final = 3600  # one hour

_fighters_cache: list[Fighter] | None = None
_names_cache: list[str] | None = None
_cache_built_at: float = 0.0


def _get_search_index(db: Session) -> tuple[list[Fighter], list[str]]:
    global _fighters_cache, _names_cache, _cache_built_at

    age = time.monotonic() - _cache_built_at
    if _fighters_cache is None or age > _CACHE_TTL_SECONDS:
        _fighters_cache = db.scalars(select(Fighter).where(Fighter.name != "")).all()
        _names_cache = [fighter.name.casefold() for fighter in _fighters_cache]
        _cache_built_at = time.monotonic()

    return _fighters_cache, _names_cache


@router.get("/search", response_model=list[FighterOut])
def search_fighters(
    q: str = Query(min_length=3, description="Name to search for"),
    limit: int = Query(5, ge=1, le=5, description="Max matches to return"),
    db: Session = Depends(get_db),
):
    fighters, names = _get_search_index(db)
    matches = process.extract(q.casefold(), names, scorer=fuzz.partial_ratio, score_cutoff=67, limit=limit)
    return [fighters[i] for _, _, i in matches]


# --- Two-fighter comparison -----------------------------------------------

_STAT_DIRECTIONS: Final = {
    "slpm": True,
    "str_acc": True,
    "str_def": True,
    "td_avg": True,
    "td_acc": True,
    "td_def": True,
    "sub_avg": True,
    "sapm": False,
}


def _winner(
    a_val: int | float | None,
    b_val: int | float | None,
    higher_wins: bool,
) -> str | None:
    """Decide one stat: 'a', 'b', 'draw', or None when it can't be compared."""
    if a_val is None or b_val is None:
        return None  # missing data on either side -> not comparable
    if a_val == b_val:
        return "draw"
    a_is_better = a_val > b_val if higher_wins else a_val < b_val
    return "a" if a_is_better else "b"


def _stat_winners(a: Fighter, b: Fighter) -> dict[str, str | None]:
    """Build the per-stat winner map for two fighters."""
    return {
        stat: _winner(getattr(a, stat), getattr(b, stat), higher_wins=higher_wins)
        for stat, higher_wins in _STAT_DIRECTIONS.items()
    }


@router.get("/compare", response_model=FighterComparison)
def compare_fighters(
    a: int = Query(description="First fighter's id"),
    b: int = Query(description="Second fighter's id"),
    db: Session = Depends(get_db),
):
    fighter_a = db.get(Fighter, a)
    fighter_b = db.get(Fighter, b)
    missing = [str(i) for i, f in ((a, fighter_a), (b, fighter_b)) if f is None]
    if missing:
        raise HTTPException(status_code=404, detail=f"Fighter(s) not found: {', '.join(missing)}")
    return {
        "a": fighter_a,
        "b": fighter_b,
        "comparison": _stat_winners(fighter_a, fighter_b),
    }


@router.get("", response_model=list[FighterOut])
def list_fighters(
    limit: int = Query(50, ge=1, le=200, description="Page size"),
    offset: int = Query(0, ge=0, description="Rows to skip"),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Fighter)
        .where(Fighter.name != "")
        .order_by(Fighter.name)
        .limit(limit)
        .offset(offset)
    )
    return db.execute(stmt).scalars().all()


@router.get("/{fighter_id}", response_model=FighterOut)
def get_fighter(fighter_id: int, db: Session = Depends(get_db)):
    fighter = db.get(Fighter, fighter_id)
    if fighter is None:
        raise HTTPException(status_code=404, detail="Fighter not found")
    return fighter
