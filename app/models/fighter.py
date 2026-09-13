from sqlalchemy import BigInteger, Column, Date, Float, Integer, Text

from app.db import Base


class Fighter(Base):
    __tablename__ = "fighters"

    id = Column(BigInteger, primary_key=True)
    name = Column(Text, nullable=False)
    nickname = Column(Text)

    height = Column(Text)
    weight = Column(Text)
    reach = Column(BigInteger)
    stance = Column(Text)
    dob = Column(Date)

    wins = Column(Integer)
    losses = Column(Integer)
    draws = Column(Integer)

    slpm = Column(Float)
    str_acc = Column(Integer)
    sapm = Column(Float)
    str_def = Column(Integer)
    td_avg = Column(Float)
    td_acc = Column(Integer)
    td_def = Column(Integer)
    sub_avg = Column(Float)

    url = Column(Text)
