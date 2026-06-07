import json
import time
import warnings
from pathlib import Path

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException, Request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from starlette.responses import Response

from app.schemas import PredictionResponse, TransactionRequest


ROOT_DIR = Path(__file__).resolve().parents[1]
ARTIFACT_DIR = ROOT_DIR / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "fraud_model.joblib"
FEATURE_NAMES_PATH = ARTIFACT_DIR / "feature_names.json"

app = FastAPI(
    title="Real-Time Fraud Detection API",
    description="FastAPI service for RandomForest-based financial transaction fraud detection.",
    version="1.0.0",
)

fraud_api_requests_total = Counter(
    "fraud_api_requests_total",
    "Total API requests received by the fraud detection service.",
)
fraud_predictions_total = Counter(
    "fraud_predictions_total",
    "Total predictions labeled as fraudulent.",
)
legitimate_predictions_total = Counter(
    "legitimate_predictions_total",
    "Total predictions labeled as legitimate.",
)
fraud_api_errors_total = Counter(
    "fraud_api_errors_total",
    "Total API errors raised by the fraud detection service.",
)
fraud_prediction_latency_seconds = Histogram(
    "fraud_prediction_latency_seconds",
    "Latency in seconds for fraud prediction requests.",
)


def _load_model():
    if not MODEL_PATH.exists() or not FEATURE_NAMES_PATH.exists():
        return None, []
    model = joblib.load(MODEL_PATH)
    feature_names = json.loads(FEATURE_NAMES_PATH.read_text(encoding="utf-8"))
    return model, feature_names


MODEL, FEATURE_NAMES = _load_model()


@app.middleware("http")
async def count_requests(request: Request, call_next):
    fraud_api_requests_total.inc()
    try:
        return await call_next(request)
    except Exception:
        fraud_api_errors_total.inc()
        raise


@app.get("/")
def root():
    return {
        "service": "fraud-detection-api",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
    }


@app.get("/ping")
def ping():
    return {"status": "ok"}


@app.get("/health")
def health():
    return {
        "status": "healthy" if MODEL is not None else "degraded",
        "model_loaded": MODEL is not None,
        "model_path": str(MODEL_PATH),
    }


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/predict", response_model=PredictionResponse)
def predict(transaction: TransactionRequest):
    if MODEL is None or not FEATURE_NAMES:
        fraud_api_errors_total.inc()
        raise HTTPException(status_code=503, detail="Model artifact is not loaded.")

    started = time.perf_counter()
    try:
        payload = transaction.model_dump()
        row = np.array([[payload[name] for name in FEATURE_NAMES]], dtype=float)
        with warnings.catch_warnings():
            warnings.filterwarnings("ignore", message="X does not have valid feature names.*")
            prediction = int(MODEL.predict(row)[0])
            probability = float(MODEL.predict_proba(row)[0][1])
        label = "Fraudulent" if prediction == 1 else "Legitimate"

        if prediction == 1:
            fraud_predictions_total.inc()
        else:
            legitimate_predictions_total.inc()

        return {
            "prediction": prediction,
            "label": label,
            "fraud_probability": round(probability, 4),
        }
    except HTTPException:
        raise
    except Exception as exc:
        fraud_api_errors_total.inc()
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc
    finally:
        fraud_prediction_latency_seconds.observe(time.perf_counter() - started)
