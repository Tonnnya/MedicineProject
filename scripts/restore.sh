#!/bin/bash
# Скрипт відновлення CHIEF з резервної копії

set -e

# Кольори
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфігурація
BACKUP_DIR="./backups"

echo -e "${BLUE}=== CHIEF Restore Script ===${NC}"

# Перевірка наявності бекапів
if [ ! -d "${BACKUP_DIR}" ] || [ -z "$(ls -A ${BACKUP_DIR})" ]; then
    echo -e "${RED}Бекапи не знайдено в ${BACKUP_DIR}${NC}"
    exit 1
fi

# Показати доступні бекапи
echo -e "${YELLOW}Доступні бекапи:${NC}"
ls -lh "${BACKUP_DIR}"/*.tar.gz | awk '{print NR") " $9 " (" $5 ")"}'

# Вибір бекапу
read -p "Введіть номер бекапу для відновлення: " BACKUP_NUM

BACKUP_FILE=$(ls "${BACKUP_DIR}"/*.tar.gz | sed -n "${BACKUP_NUM}p")

if [ -z "${BACKUP_FILE}" ]; then
    echo -e "${RED}Невірний номер бекапу${NC}"
    exit 1
fi

echo -e "${BLUE}Обрано: ${BACKUP_FILE}${NC}"

# Підтвердження
echo -e "${RED}УВАГА: Це замінить всі поточні дані!${NC}"
read -p "Продовжити? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Скасовано${NC}"
    exit 0
fi

# Розпакування
echo -e "${BLUE}Розпакування бекапу...${NC}"
RESTORE_DIR="${BACKUP_DIR}/restore_temp"
mkdir -p "${RESTORE_DIR}"
tar xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"

BACKUP_NAME=$(basename "${BACKUP_FILE}" .tar.gz)
RESTORE_PATH="${RESTORE_DIR}/${BACKUP_NAME}"

# Зупинка сервісів
echo -e "${YELLOW}Зупинка сервісів...${NC}"
docker-compose down

# 1. Відновлення PostgreSQL
echo -e "${BLUE}[1/5] Відновлення PostgreSQL...${NC}"
docker-compose up -d postgres
sleep 5
cat "${RESTORE_PATH}/database.sql" | docker-compose exec -T postgres psql -U chief_user chief_db
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PostgreSQL restored${NC}"
else
    echo -e "${RED}✗ PostgreSQL restore failed${NC}"
fi

# 2. Відновлення Redis
echo -e "${BLUE}[2/5] Відновлення Redis...${NC}"
docker-compose up -d redis
sleep 5
docker cp "${RESTORE_PATH}/redis_dump.rdb" chief_redis:/data/dump.rdb
docker-compose restart redis
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Redis restored${NC}"
else
    echo -e "${RED}✗ Redis restore failed${NC}"
fi

# 3. Відновлення результатів
echo -e "${BLUE}[3/5] Відновлення результатів...${NC}"
docker run --rm \
    -v chief_data_results:/data \
    -v "$(pwd)/${RESTORE_PATH}":/backup \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/results.tar.gz -C /"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Results restored${NC}"
else
    echo -e "${RED}✗ Results restore failed${NC}"
fi

# 4. Відновлення метаданих
echo -e "${BLUE}[4/5] Відновлення метаданих...${NC}"
docker run --rm \
    -v chief_data_metadata:/data \
    -v "$(pwd)/${RESTORE_PATH}":/backup \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/metadata.tar.gz -C /"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Metadata restored${NC}"
else
    echo -e "${RED}✗ Metadata restore failed${NC}"
fi

# 5. Відновлення конфігурацій
echo -e "${BLUE}[5/5] Відновлення конфігурацій...${NC}"
echo -e "${YELLOW}Конфігурації знаходяться в: ${RESTORE_PATH}/configs${NC}"
echo -e "${YELLOW}Скопіюйте їх вручну якщо потрібно${NC}"

# Очищення
echo -e "${BLUE}Очищення тимчасових файлів...${NC}"
rm -rf "${RESTORE_DIR}"

# Запуск сервісів
echo -e "${BLUE}Запуск сервісів...${NC}"
docker-compose up -d

echo -e "${GREEN}=== Відновлення завершено! ===${NC}"
echo -e "${YELLOW}Перевірте статус сервісів: docker-compose ps${NC}"
