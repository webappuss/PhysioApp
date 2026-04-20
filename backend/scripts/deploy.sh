#!/usr/bin/env bash
# PhysioConnect — Zero-downtime deploy script
# Called by GitHub Actions SSM command after new image is pulled
set -euo pipefail

COMPOSE_FILE="/opt/physioconnect/docker-compose.prod.yml"
ECR_REGISTRY="${ECR_REGISTRY:?ECR_REGISTRY env var required}"
REGION="${AWS_DEFAULT_REGION:-ap-south-1}"

echo "=== PhysioConnect Deploy ==="
echo "Image: ${ECR_REGISTRY}/physioconnect-api:latest"
echo "Started: $(date)"

# Login to ECR
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Pull new image
docker pull "${ECR_REGISTRY}/physioconnect-api:latest"

# Rolling restart (keeps existing container up until new one is healthy)
docker compose -f "$COMPOSE_FILE" up -d --no-deps --wait api

# Run migrations (idempotent — safe to run on every deploy)
docker exec physioconnect_api php artisan migrate --force

# Refresh caches
docker exec physioconnect_api php artisan config:cache
docker exec physioconnect_api php artisan route:cache

# Graceful queue restart
docker exec physioconnect_api php artisan queue:restart

# Health check
MAX_RETRIES=10
for i in $(seq 1 $MAX_RETRIES); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
  if [ "$STATUS" = "200" ]; then
    echo "Health check passed (attempt $i)"
    break
  fi
  if [ "$i" = "$MAX_RETRIES" ]; then
    echo "Health check failed after $MAX_RETRIES attempts — rolling back" >&2
    docker compose -f "$COMPOSE_FILE" rollback api 2>/dev/null || true
    exit 1
  fi
  echo "Health check attempt $i failed (HTTP $STATUS) — retrying in 5s..."
  sleep 5
done

# Clean up old images
docker image prune -f

echo "=== Deploy complete: $(date) ==="
