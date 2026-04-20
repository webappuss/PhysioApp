#!/usr/bin/env bash
# PhysioConnect — First-run setup script
# Run once on the server after the container is up:
#   docker exec physioconnect_api bash /var/www/html/scripts/first-run.sh
set -euo pipefail

echo "=== PhysioConnect First-Run Setup ==="
echo "Started: $(date)"

APP_DIR="/var/www/html"

# ── 1. Generate app key if missing ───────────────────────────────────────────
if grep -q '^APP_KEY=$' "$APP_DIR/.env" 2>/dev/null || ! grep -q '^APP_KEY=' "$APP_DIR/.env" 2>/dev/null; then
  echo "[1/7] Generating APP_KEY..."
  php "$APP_DIR/artisan" key:generate --force
else
  echo "[1/7] APP_KEY already set — skipping"
fi

# ── 2. Run migrations ─────────────────────────────────────────────────────────
echo "[2/7] Running database migrations..."
php "$APP_DIR/artisan" migrate --force

# ── 3. Seed required data ─────────────────────────────────────────────────────
echo "[3/7] Seeding database..."
php "$APP_DIR/artisan" db:seed --force

# ── 4. Cache config/routes/views ──────────────────────────────────────────────
echo "[4/7] Caching configuration..."
php "$APP_DIR/artisan" config:cache
php "$APP_DIR/artisan" route:cache
php "$APP_DIR/artisan" view:cache

# ── 5. Create storage symlink ─────────────────────────────────────────────────
echo "[5/7] Creating storage symlink..."
php "$APP_DIR/artisan" storage:link --force

# ── 6. Warm up queue ──────────────────────────────────────────────────────────
echo "[6/7] Restarting queue workers..."
php "$APP_DIR/artisan" queue:restart

# ── 7. Health check ───────────────────────────────────────────────────────────
echo "[7/7] Running health check..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
if [ "$STATUS" = "200" ]; then
  echo "Health check PASSED (HTTP 200)"
else
  echo "Health check FAILED (HTTP $STATUS)" >&2
  exit 1
fi

echo ""
echo "=== Setup complete! $(date) ==="
echo ""
echo "Next steps:"
echo "  - Seed demo physios: php artisan db:seed --class=DemoPhysioSeeder"
echo "  - Set up Razorpay webhook at: POST https://api.physioconnect.in/api/v1/payments/webhook"
echo "  - Verify admin login at: POST https://api.physioconnect.in/api/v1/admin/login"
echo "    Email: admin@physioconnect.in"
echo "    Password: \$ADMIN_DEFAULT_PASSWORD"
