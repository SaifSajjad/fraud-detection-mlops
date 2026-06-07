import json
from pathlib import Path

import joblib
import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split


ROOT_DIR = Path(__file__).resolve().parents[1]
ARTIFACT_DIR = ROOT_DIR / "artifacts"
DOCS_DIR = ROOT_DIR / "docs"
MLFLOW_URI = "sqlite:///mlflow.db"
EXPERIMENT_NAME = "fraud-detection-experiment"

FEATURE_NAMES = [
    "amount",
    "old_balance_sender",
    "new_balance_sender",
    "old_balance_receiver",
    "new_balance_receiver",
    "transaction_hour",
    "previous_failed_attempts",
]


def _scale_column(values: np.ndarray, low: float, high: float) -> np.ndarray:
    minimum = values.min()
    maximum = values.max()
    if maximum == minimum:
        return np.full_like(values, low, dtype=float)
    normalized = (values - minimum) / (maximum - minimum)
    return low + normalized * (high - low)


def build_dataset() -> tuple[pd.DataFrame, pd.Series]:
    raw_features, labels = make_classification(
        n_samples=6000,
        n_features=len(FEATURE_NAMES),
        n_informative=5,
        n_redundant=1,
        n_repeated=0,
        n_classes=2,
        weights=[0.93, 0.07],
        class_sep=1.7,
        flip_y=0.01,
        random_state=42,
    )

    rng = np.random.default_rng(42)
    amount = np.round(_scale_column(raw_features[:, 0], 5, 12500), 2)
    old_sender = np.round(_scale_column(raw_features[:, 1], 50, 25000), 2)
    balance_delta = np.clip(amount * rng.uniform(0.75, 1.15, len(amount)), 0, old_sender)
    new_sender = np.round(np.maximum(old_sender - balance_delta, 0), 2)
    old_receiver = np.round(_scale_column(raw_features[:, 2], 0, 40000), 2)
    new_receiver = np.round(old_receiver + amount * rng.uniform(0.55, 1.25, len(amount)), 2)
    hour = np.rint(_scale_column(raw_features[:, 3], 0, 23)).astype(int)
    failed_attempts = np.rint(_scale_column(raw_features[:, 4], 0, 6)).astype(int)

    frame = pd.DataFrame(
        {
            "amount": amount,
            "old_balance_sender": old_sender,
            "new_balance_sender": new_sender,
            "old_balance_receiver": old_receiver,
            "new_balance_receiver": new_receiver,
            "transaction_hour": hour,
            "previous_failed_attempts": failed_attempts,
        }
    )
    return frame, pd.Series(labels, name="is_fraud")


def main() -> None:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    features, labels = build_dataset()
    x_train, x_test, y_train, y_test = train_test_split(
        features,
        labels,
        test_size=0.2,
        random_state=42,
        stratify=labels,
    )

    model = RandomForestClassifier(
        n_estimators=150,
        random_state=42,
        class_weight="balanced",
        n_jobs=-1,
    )
    model.fit(x_train, y_train)

    predictions = model.predict(x_test)
    probabilities = model.predict_proba(x_test)[:, 1]
    cm = confusion_matrix(y_test, predictions)
    metrics = {
        "accuracy": round(float(accuracy_score(y_test, predictions)), 4),
        "precision": round(float(precision_score(y_test, predictions, zero_division=0)), 4),
        "recall": round(float(recall_score(y_test, predictions, zero_division=0)), 4),
        "f1_score": round(float(f1_score(y_test, predictions, zero_division=0)), 4),
        "dataset_size": int(len(features)),
        "feature_count": int(len(FEATURE_NAMES)),
        "train_size": int(len(x_train)),
        "test_size": int(len(x_test)),
        "fraud_records": int(labels.sum()),
        "legitimate_records": int((labels == 0).sum()),
        "confusion_matrix": cm.tolist(),
    }

    joblib.dump(model, ARTIFACT_DIR / "fraud_model.joblib")
    (ARTIFACT_DIR / "feature_names.json").write_text(
        json.dumps(FEATURE_NAMES, indent=2),
        encoding="utf-8",
    )
    (ARTIFACT_DIR / "metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )
    (ARTIFACT_DIR / "confusion_matrix.json").write_text(
        json.dumps({"confusion_matrix": cm.tolist()}, indent=2),
        encoding="utf-8",
    )
    (ARTIFACT_DIR / "confusion_matrix.txt").write_text(str(cm), encoding="utf-8")

    sample_index = int(np.argmax(probabilities))
    sample_request = x_test.iloc[sample_index].to_dict()
    for key, value in sample_request.items():
        if key in {"transaction_hour", "previous_failed_attempts"}:
            sample_request[key] = int(value)
        else:
            sample_request[key] = float(value)
    (ARTIFACT_DIR / "sample_request.json").write_text(
        json.dumps(sample_request, indent=2),
        encoding="utf-8",
    )

    mlflow.set_tracking_uri(MLFLOW_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)
    with mlflow.start_run(run_name="random-forest-fraud-detector") as run:
        mlflow.log_params(
            {
                "model_type": "RandomForestClassifier",
                "n_estimators": 150,
                "random_state": 42,
                "class_weight": "balanced",
                "n_jobs": -1,
                "dataset_size": len(features),
                "feature_count": len(FEATURE_NAMES),
            }
        )
        mlflow.log_metrics(
            {
                "accuracy": metrics["accuracy"],
                "precision": metrics["precision"],
                "recall": metrics["recall"],
                "f1_score": metrics["f1_score"],
            }
        )
        mlflow.log_artifact(str(ARTIFACT_DIR / "metrics.json"))
        mlflow.log_artifact(str(ARTIFACT_DIR / "confusion_matrix.json"))
        mlflow.sklearn.log_model(model, artifact_path="model", input_example=features.head(5))
        metrics["mlflow_run_id"] = run.info.run_id

    (ARTIFACT_DIR / "metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )

    print("Fraud Detection RandomForest training complete")
    print(f"Accuracy: {metrics['accuracy']}")
    print(f"Precision: {metrics['precision']}")
    print(f"Recall: {metrics['recall']}")
    print(f"F1-score: {metrics['f1_score']}")
    print("Confusion matrix:")
    print(cm)
    print(f"MLflow run id: {metrics['mlflow_run_id']}")


if __name__ == "__main__":
    main()

