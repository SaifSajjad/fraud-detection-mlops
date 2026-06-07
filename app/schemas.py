from pydantic import BaseModel, Field


class TransactionRequest(BaseModel):
    amount: float = Field(..., ge=0)
    old_balance_sender: float = Field(..., ge=0)
    new_balance_sender: float = Field(..., ge=0)
    old_balance_receiver: float = Field(..., ge=0)
    new_balance_receiver: float = Field(..., ge=0)
    transaction_hour: int = Field(..., ge=0, le=23)
    previous_failed_attempts: int = Field(..., ge=0)


class PredictionResponse(BaseModel):
    prediction: int
    label: str
    fraud_probability: float

