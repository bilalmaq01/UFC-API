"""HTTP endpoints for fighters: fuzzy search, list, and detail."""

from fastapi import APIRouter, Depends, HTTPException, Query
from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.fighter import Fighter
from app.schemas.fighter import FighterOut

router = APIRouter(prefix="/fighters", tags=["fighters"])


@router.get("/search", response_model=list[FighterOut])
def search_fighters(
    q: str = Query(min_length=3, description="Name to search for"),
    limit: int = Query(5, ge=1, le=5, description="Max matches to return"),
    db: Session = Depends(get_db),
):
    fighters = db.execute(select(Fighter).where(Fighter.name != "")).scalars().all()
    names = [f.name.lower() for f in fighters]
    matches = process.extract(q.lower(), names, scorer=fuzz.WRatio, score_cutoff=67, limit=limit)
    return [fighters[i] for _, _, i in matches]


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
