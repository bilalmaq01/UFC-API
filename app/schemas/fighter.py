from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict


class FighterOut(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    nickname: str | None = None
    height: str | None = None
    weight: str | None = None
    reach: int | None = None
    stance: str | None = None
    dob: date | None = None
    wins: int | None = None
    losses: int | None = None
    draws: int | None = None
    slpm: float | None = None
    str_acc: int | None = None
    sapm: float | None = None
    str_def: int | None = None
    td_avg: float | None = None
    td_acc: int | None = None
    td_def: int | None = None
    sub_avg: float | None = None


class FighterComparison(BaseModel):
    """Two fighters plus a per-stat verdict of who wins.

    comparison maps each career stat to the winner: "a", "b", "draw", or null
    when the stat can't be compared (one side's value is missing).
    """

    a: FighterOut
    b: FighterOut
    comparison: dict[str, Literal["a", "b", "draw"] | None]

