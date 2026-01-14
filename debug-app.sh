#!/bin/bash
# Debug script to check why app can't be enabled

CONTAINER_NAME="${1:-nextcloud}"
APP_NAME="files_retention"
APP_PATH="/var/www/html/apps/${APP_NAME}"

echo "=== Checking app installation ==="
echo ""

echo "1. Checking if app directory exists:"
docker exec "${CONTAINER_NAME}" test -d "${APP_PATH}" && echo "✓ Directory exists" || echo "✗ Directory missing"

echo ""
echo "2. Checking required files:"
docker exec "${CONTAINER_NAME}" test -f "${APP_PATH}/appinfo/info.xml" && echo "✓ info.xml exists" || echo "✗ info.xml missing"
docker exec "${CONTAINER_NAME}" test -f "${APP_PATH}/appinfo/app.php" && echo "✓ app.php exists" || echo "✗ app.php missing"
docker exec "${CONTAINER_NAME}" test -d "${APP_PATH}/lib" && echo "✓ lib/ directory exists" || echo "✗ lib/ directory missing"

echo ""
echo "3. Checking frontend assets:"
docker exec "${CONTAINER_NAME}" test -d "${APP_PATH}/js" && echo "✓ js/ directory exists" || echo "✗ js/ directory missing (needs: npm run build)"
docker exec "${CONTAINER_NAME}" test -f "${APP_PATH}/js/files_retention-main.js" && echo "✓ Main JS file exists" || echo "✗ Main JS file missing"

echo ""
echo "4. Checking PHP dependencies:"
docker exec "${CONTAINER_NAME}" test -d "${APP_PATH}/vendor" && echo "✓ vendor/ directory exists" || echo "✗ vendor/ directory missing (needs: composer install)"

echo ""
echo "5. Checking permissions:"
docker exec "${CONTAINER_NAME}" ls -ld "${APP_PATH}" | awk '{print "Permissions: " $1 " Owner: " $3 ":" $4}'

echo ""
echo "6. Trying to get app status:"
docker exec -u www-data "${CONTAINER_NAME}" php /var/www/html/occ app:check-code "${APP_NAME}" 2>&1 || echo "Could not check code"

echo ""
echo "7. Checking Nextcloud logs for errors:"
docker exec "${CONTAINER_NAME}" tail -20 /var/www/html/data/nextcloud.log 2>/dev/null | grep -i "${APP_NAME}" || echo "No recent errors found in log"
