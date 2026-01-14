#!/bin/bash
# Script to update info.xml and enable the app

CONTAINER="${1:-nextcloud_nextcloud_app}"
APP_PATH="/var/www/html/apps/files_retention"

echo "Updating appinfo/info.xml for Nextcloud 32 compatibility..."
echo ""

# Copy the updated info.xml
echo "1. Copying updated info.xml..."
docker cp appinfo/info.xml "$CONTAINER:$APP_PATH/appinfo/info.xml"
docker exec "$CONTAINER" chown www-data:www-data "$APP_PATH/appinfo/info.xml"

# Clear Nextcloud cache
echo "2. Clearing Nextcloud cache..."
docker exec -u www-data "$CONTAINER" php /var/www/html/occ files:scan --all 2>/dev/null || true
docker exec -u www-data "$CONTAINER" php /var/www/html/occ maintenance:mode --off 2>/dev/null || true

# Try to enable
echo "3. Enabling app..."
docker exec -u www-data "$CONTAINER" php /var/www/html/occ app:enable files_retention

# Run migrations
echo "4. Running database migrations..."
docker exec -u www-data "$CONTAINER" php /var/www/html/occ upgrade

echo ""
echo "Done! Check if the app is enabled:"
docker exec -u www-data "$CONTAINER" php /var/www/html/occ app:list | grep retention
