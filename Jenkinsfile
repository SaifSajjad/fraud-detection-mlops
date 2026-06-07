// ============================================================
// Demo-oriented CI pipeline — fraud-detection-mlops (Phase 5)
// ============================================================
// IMPORTANT: The Deploy stage is GATED behind the environment
// variable DEPLOY (default = 'false').  Jenkins will never
// auto-touch the live fraud-mlops-p4 cluster unless a build is
// triggered with DEPLOY=true set as a build parameter.
//
// Assumed agent: Windows node with Python 3.11, Docker Desktop,
// and kubectl in PATH.  All Kubernetes commands are hard-scoped
// to --context=fraud-mlops-p4 (Project 4).  The Minikube
// profile 'minikube' (Project 3) is never referenced here.
//
// Stages
//   1. Checkout       — clone / workspace update via SCM
//   2. Setup          — create .venv and pip install requirements.txt
//   3. Lint / Test    — run the 5 pytest tests in tests/
//   4. Docker Build   — build fraud-detection-api:latest from Dockerfile
//   5. Deploy         — kubectl apply (only when DEPLOY=true)
// ============================================================

pipeline {
    agent any

    environment {
        DEPLOY        = 'false'
        K8S_CONTEXT   = 'fraud-mlops-p4'
        K8S_NAMESPACE = 'fraud-mlops'
        DOCKER_IMAGE  = 'fraud-detection-api:latest'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                // Creates .venv if absent, upgrades pip, installs requirements.txt
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\bootstrap.ps1'
            }
        }

        stage('Lint / Test') {
            steps {
                // Runs the 5 existing tests in tests/test_api.py via .venv pytest
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\test.ps1'
            }
            post {
                always {
                    // Collect JUnit results if pytest-junit output is configured
                    junit allowEmptyResults: true, testResults: 'test-results/**/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                // Builds fraud-detection-api:latest using the project Dockerfile
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\build-docker.ps1'
            }
        }

        stage('Deploy') {
            // Gate: only runs when the build is triggered with DEPLOY=true
            when {
                environment name: 'DEPLOY', value: 'true'
            }
            steps {
                // Core API manifests
                bat "kubectl --context=%K8S_CONTEXT% apply -f kubernetes\\namespace.yaml"
                bat "kubectl --context=%K8S_CONTEXT% apply -f kubernetes\\deployment.yaml"
                bat "kubectl --context=%K8S_CONTEXT% apply -f kubernetes\\service.yaml"
                // Monitoring manifests (Prometheus + Grafana)
                bat "kubectl --context=%K8S_CONTEXT% apply -f kubernetes\\monitoring\\"
                // Wait for API rollout — scoped to Project 4 only
                bat "kubectl --context=%K8S_CONTEXT% -n %K8S_NAMESPACE% rollout status deploy/fraud-detection-api --timeout=120s"
            }
        }
    }

    post {
        always {
            // Archive evidence docs and safe artifacts; never archives model binaries
            archiveArtifacts(
                artifacts: 'docs/**,artifacts/metrics.json,artifacts/sample_request.json,screenshots/**',
                fingerprint: true,
                allowEmptyArchive: true
            )
        }
        success {
            echo 'Pipeline passed. Cluster was NOT modified (DEPLOY=false by default).'
        }
        failure {
            echo 'Pipeline failed — check the Lint/Test or Docker Build stage output.'
        }
    }
}
