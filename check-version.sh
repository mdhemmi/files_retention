#!/bin/bash
# Check Nextcloud version and app compatibility

CONTAINER="${1:-nextcloud_nextcloud_app}"

echo "Checking Nextcloud version..."
docker exec -u www-data "$CONTAINER" php /var/www/html/occ status | grep -i "version\|nextcloud"

echo ""
echo "Checking app compatibility requirements..."
echo "Current app requires: Nextcloud 33.x"
echo ""
echo "To fix compatibility, we can update info.xml to support your version."
