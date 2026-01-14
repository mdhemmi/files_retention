#!/bin/bash
# Script to help enable the app with correct syntax

CONTAINER="${1:-nextcloud}"

echo "Trying different methods to enable the app..."
echo ""

# Method 1: Direct occ command
echo "Method 1: Direct occ command"
docker exec -u www-data "$CONTAINER" php /var/www/html/occ app:enable files_retention 2>&1

# If that fails, try Method 2
if [ $? -ne 0 ]; then
    echo ""
    echo "Method 2: From /var/www/html directory"
    docker exec -u www-data "$CONTAINER" sh -c "cd /var/www/html && php occ app:enable files_retention" 2>&1
fi

# If that fails, try Method 3 with force
if [ $? -ne 0 ]; then
    echo ""
    echo "Method 3: With --force flag"
    docker exec -u www-data "$CONTAINER" php /var/www/html/occ app:enable --force files_retention 2>&1
fi

echo ""
echo "Checking app status:"
docker exec -u www-data "$CONTAINER" php /var/www/html/occ app:list | grep retention
