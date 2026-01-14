#!/bin/bash
# Deployment script for Nextcloud Docker containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="files_retention"
CONTAINER_NAME="${1:-nextcloud}"  # First argument or default to "nextcloud"
NEXTCLOUD_APPS_PATH="/var/www/html/apps"

echo -e "${GREEN}Building Files Retention app for Docker deployment...${NC}"

# Step 1: Build frontend assets
echo -e "${YELLOW}Step 1: Building frontend assets...${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed. Please install Node.js and npm.${NC}"
    exit 1
fi

npm ci
npm run build

# Step 2: Install PHP dependencies using Composer Docker image
echo -e "${YELLOW}Step 2: Installing PHP dependencies...${NC}"
if command -v composer &> /dev/null; then
    echo "Using local composer..."
    composer install --no-dev --optimize-autoloader
elif command -v docker &> /dev/null; then
    echo "Using Composer Docker image..."
    docker run --rm -v "$(pwd):/app" -w /app composer:latest install --no-dev --optimize-autoloader
else
    echo -e "${YELLOW}Warning: Neither composer nor docker found. Skipping PHP dependencies.${NC}"
    echo -e "${YELLOW}You may need to install them manually in the container.${NC}"
fi

# Step 3: Check if container exists
echo -e "${YELLOW}Step 3: Checking Docker container...${NC}"
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container '${CONTAINER_NAME}' not found.${NC}"
    echo -e "${YELLOW}Available containers:${NC}"
    docker ps -a --format '{{.Names}}'
    exit 1
fi

# Step 4: Copy app to container
echo -e "${YELLOW}Step 4: Copying app to container '${CONTAINER_NAME}'...${NC}"
docker exec "${CONTAINER_NAME}" mkdir -p "${NEXTCLOUD_APPS_PATH}/${APP_NAME}" || true
docker cp . "${CONTAINER_NAME}:${NEXTCLOUD_APPS_PATH}/${APP_NAME}"

# Step 5: Set permissions
echo -e "${YELLOW}Step 5: Setting permissions...${NC}"
docker exec "${CONTAINER_NAME}" chown -R www-data:www-data "${NEXTCLOUD_APPS_PATH}/${APP_NAME}"

# Step 6: Enable the app
echo -e "${YELLOW}Step 6: Enabling app in Nextcloud...${NC}"
# Try different methods to run occ command
if docker exec -u www-data "${CONTAINER_NAME}" php /var/www/html/occ app:enable "${APP_NAME}" 2>/dev/null; then
    echo -e "${GREEN}App enabled successfully (as www-data user)${NC}"
elif docker exec "${CONTAINER_NAME}" php /var/www/html/occ app:enable "${APP_NAME}" 2>/dev/null; then
    echo -e "${GREEN}App enabled successfully${NC}"
elif docker exec -u www-data "${CONTAINER_NAME}" sh -c "cd /var/www/html && php occ app:enable ${APP_NAME}" 2>/dev/null; then
    echo -e "${GREEN}App enabled successfully (from /var/www/html directory)${NC}"
else
    echo -e "${RED}Error: Failed to enable app. Trying manual command...${NC}"
    echo -e "${YELLOW}Please run manually:${NC}"
    echo -e "  docker exec -u www-data ${CONTAINER_NAME} php /var/www/html/occ app:enable ${APP_NAME}"
    exit 1
fi

# Step 7: Run database migrations
echo -e "${YELLOW}Step 7: Running database migrations...${NC}"
if docker exec -u www-data "${CONTAINER_NAME}" php /var/www/html/occ upgrade 2>/dev/null; then
    echo -e "${GREEN}Database migrations completed${NC}"
elif docker exec "${CONTAINER_NAME}" php /var/www/html/occ upgrade 2>/dev/null; then
    echo -e "${GREEN}Database migrations completed${NC}"
elif docker exec -u www-data "${CONTAINER_NAME}" sh -c "cd /var/www/html && php occ upgrade" 2>/dev/null; then
    echo -e "${GREEN}Database migrations completed${NC}"
else
    echo -e "${YELLOW}Warning: Could not run database migrations automatically.${NC}"
    echo -e "${YELLOW}Please run manually:${NC}"
    echo -e "  docker exec -u www-data ${CONTAINER_NAME} php /var/www/html/occ upgrade"
fi

echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "${GREEN}The app '${APP_NAME}' has been installed and enabled.${NC}"
