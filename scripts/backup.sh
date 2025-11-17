#!/bin/bash
# Скрипт резервного копіювання CHIEF

set -e

# Кольори
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфігурація
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="chief_backup_${TIMESTAMP}"

echo -e "${BLUE}=== CHIEF Backup Script ===${NC}"
echo -e "${YELLOW}Початок резервного копіювання...${NC}"

# Створення директорії для бекапів
mkdir -p "${BACKUP_DIR}"

# Створення директорії для поточного бекапу
CURRENT_BACKUP="${BACKUP_DIR}/${BACKUP_NAME}"
mkdir -p "${CURRENT_BACKUP}"

# 1. Бекап PostgreSQL
echo -e "${BLUE}[1/5] Резервне копіювання PostgreSQL...${NC}"
docker-compose exec -T postgres pg_dump -U chief_user chief_db > "${CURRENT_BACKUP}/database.sql"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PostgreSQL backed up${NC}"
else
    echo -e "${RED}✗ PostgreSQL backup failed${NC}"
    exit 1
fi

# 2. Бекап Redis
echo -e "${BLUE}[2/5] Резервне копіювання Redis...${NC}"
docker-compose exec -T redis redis-cli --pass chief_redis_password_change_me SAVE
docker cp chief_redis:/data/dump.rdb "${CURRENT_BACKUP}/redis_dump.rdb"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Redis backed up${NC}"
else
    echo -e "${RED}✗ Redis backup failed${NC}"
fi

# 3. Бекап результатів
echo -e "${BLUE}[3/5] Резервне копіювання результатів...${NC}"
docker run --rm \
    -v chief_data_results:/data \
    -v "$(pwd)/${CURRENT_BACKUP}":/backup \
    alpine tar czf /backup/results.tar.gz /data
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Results backed up${NC}"
else
    echo -e "${RED}✗ Results backup failed${NC}"
fi

# 4. Бекап метаданих
echo -e "${BLUE}[4/5] Резервне копіювання метаданих...${NC}"
docker run --rm \
    -v chief_data_metadata:/data \
    -v "$(pwd)/${CURRENT_BACKUP}":/backup \
    alpine tar czf /backup/metadata.tar.gz /data
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Metadata backed up${NC}"
else
    echo -e "${RED}✗ Metadata backup failed${NC}"
fi

# 5. Бекап конфігурацій
echo -e "${BLUE}[5/5] Резервне копіювання конфігурацій...${NC}"
cp -r configs "${CURRENT_BACKUP}/"
cp docker-compose.yml "${CURRENT_BACKUP}/"
cp .env "${CURRENT_BACKUP}/" 2>/dev/null || echo "No .env file"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configs backed up${NC}"
else
    echo -e "${RED}✗ Configs backup failed${NC}"
fi

# Створення архіву
echo -e "${BLUE}Створення архіву...${NC}"
cd "${BACKUP_DIR}"
tar czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"
cd ..

# Розмір бекапу
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

echo -e "${GREEN}=== Резервне копіювання завершено! ===${NC}"
echo -e "${GREEN}Файл: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${GREEN}Розмір: ${BACKUP_SIZE}${NC}"

# Очищення старих бекапів (залишити останні 7)
echo -e "${YELLOW}Очищення старих бекапів...${NC}"
cd "${BACKUP_DIR}"
ls -t | tail -n +8 | xargs -r rm -f
cd ..

echo -e "${GREEN}Готово!${NC}"
