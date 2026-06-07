import json
from pathlib import Path

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)
ROOT_DIR = Path(__file__).resolve().parents[1]


def test_ping_returns_200():
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_health_confirms_model_loaded():
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["model_loaded"] is True
    assert payload["model_path"]


def test_predict_accepts_saved_sample_request():
    sample = json.loads((ROOT_DIR / "artifacts" / "sample_request.json").read_text(encoding="utf-8"))
    response = client.post("/predict", json=sample)
    assert response.status_code == 200
    payload = response.json()
    assert "prediction" in payload
    assert "label" in payload
    assert "fraud_probability" in payload
    assert payload["label"] in {"Fraudulent", "Legitimate"}
    assert 0 <= payload["fraud_probability"] <= 1


def test_metrics_returns_prometheus_text():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "fraud_api_requests_total" in response.text
    assert "fraud_prediction_latency_seconds" in response.text


def test_invalid_input_returns_client_error():
    response = client.post("/predict", json={"amount": -1})
    assert response.status_code in {400, 422}

