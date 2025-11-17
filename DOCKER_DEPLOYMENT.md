# Розгортання CHIEF за допомогою Docker

## 📦 Зміст

1. [Передумови](#передумови)
2. [Швидкий старт](#швидкий-старт)
3. [Детальна інструкція](#детальна-інструкція)
4. [Конфігурація](#конфігурація)
5. [Використання](#використання)
6. [Моніторинг](#моніторинг)
7. [Troubleshooting](#troubleshooting)

---

## Передумови

### Системні вимоги

- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM**: Мінімум 16GB, рекомендовано 32GB+
- **GPU**: NVIDIA GPU з підтримкою CUDA 11.1+ (мінімум 8GB VRAM)
- **Disk**: Мінімум 100GB вільного місця
- **CPU**: 8+ cores

### Необхідне програмне забезпечення

1. **Docker** 20.10+
2. **Docker Compose** 1.29+
3. **NVIDIA Docker Runtime** (для GPU підтримки)
4. **NVIDIA Driver** 470+

---

## Швидкий старт

### Крок 1: Встановлення залежностей

```bash
# Встановлення Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Встановлення Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Встановлення NVIDIA Docker Runtime
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# Перевірка
docker --version
docker-compose --version
nvidia-smi
```

### Крок 2: Клонування репозиторію

```bash
git clone https://github.com/Tonnnya/MedicineProject.git
cd MedicineProject
```

### Крок 3: Підготовка конфігурації

```bash
# Створення необхідних директорій
mkdir -p data/{slides,features,results,metadata,temp,archive,queue}
mkdir -p logs
mkdir -p model_weight
mkdir -p monitoring/{prometheus,grafana}

# Копіювання конфігурації
cp configs/ukrainian_hospital_config.yaml configs/my_config.yaml

# Редагування конфігурації (опціонально)
nano configs/my_config.yaml
```

### Крок 4: Завантаження ваг моделі

```bash
# Завантажте ваги моделі з Google Drive
# https://drive.google.com/drive/folders/1uRv9A1HuTW5m_pJoyMzdN31bE1i-tDaV

# Розмістіть файли у директорії model_weight/
# Необхідні файли:
# - CHIEF_pretraining.pth
# - CHIEF_CTransPath.pth
# - Text_emdding.pth
```

### Крок 5: Запуск Docker Compose

```bash
# Збірка образів
docker-compose build

# Запуск всіх сервісів
docker-compose up -d

# Перевірка статусу
docker-compose ps
```

### Крок 6: Перевірка роботи

```bash
# Перевірка GPU в контейнері
docker-compose exec chief nvidia-smi

# Перевірка Python та PyTorch
docker-compose exec chief python3 -c "import torch; print(torch.cuda.is_available())"

# Запуск демо локалізації
docker-compose exec chief python3 utils/ukrainian_localization.py
```

---

## Детальна інструкція

### Архітектура Docker Compose

Проєкт включає наступні сервіси:

1. **chief** - Основний контейнер з CHIEF
2. **postgres** - База даних для метаданих
3. **redis** - Кеш та черги
4. **nginx** - Reverse proxy
5. **prometheus** - Збір метрик
6. **grafana** - Візуалізація метрик

```
┌─────────────────────────────────────────────────────┐
│                    Nginx (Port 80)                   │
│              Reverse Proxy & Load Balancer           │
└──────────┬──────────────────────────────────────────┘
           │
           ├──────────> CHIEF Main (GPU)
           │            - API (Port 8000)
           │            - Web UI (Port 5000)
           │            - TensorBoard (Port 6006)
           │
           ├──────────> PostgreSQL (Port 5432)
           │            - Метадані
           │            - Результати
           │
           ├──────────> Redis (Port 6379)
           │            - Кеш
           │            - Черги обробки
           │
           └──────────> Monitoring
                        - Prometheus (Port 9090)
                        - Grafana (Port 3000)
```

### Конфігураційні файли

#### docker-compose.yml

Основна конфігурація для production використання:

- Всі сервіси з автоматичним перезапуском
- Volumes для персистентності даних
- Мережа для ізоляції
- Health checks
- Resource limits

#### docker-compose.dev.yml

Конфігурація для розробки:

```bash
# Запуск в режимі розробки
docker-compose -f docker-compose.dev.yml up

# Включає:
# - Live reload коду
# - Jupyter Notebook (Port 8888)
# - Монтування локальних директорій
# - Debug режим
```

### Volumes (Постійні дані)

Docker Compose створює наступні volumes:

```yaml
volumes:
  chief_data_slides:        # WSI зображення
  chief_data_features:      # Витягнуті ознаки
  chief_data_results:       # Результати аналізу
  chief_data_metadata:      # CSV файли з метаданими
  chief_postgres_data:      # База даних
  chief_redis_data:         # Redis дані
  chief_logs:              # Логи системи
```

Для резервного копіювання:

```bash
# Бекап всіх volumes
docker run --rm \
  -v chief_data_results:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/results_$(date +%Y%m%d).tar.gz /data

# Відновлення
docker run --rm \
  -v chief_data_results:/data \
  -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/results_20250101.tar.gz -C /
```

### Мережа

Всі контейнери підключені до ізольованої мережі `chief_network`:

```bash
# Перегляд мережі
docker network inspect chief_network

# Підключення до мережі
docker network connect chief_network my_container
```

---

## Конфігурація

### Змінні середовища

Створіть файл `.env` у корені проєкту:

```bash
# .env file

# CHIEF Configuration
CHIEF_MODEL_PATH=/app/model_weight
CHIEF_DATA_DIR=/data
CHIEF_LOG_LEVEL=INFO

# GPU Configuration
CUDA_VISIBLE_DEVICES=0
NVIDIA_VISIBLE_DEVICES=all

# Database
POSTGRES_DB=chief_db
POSTGRES_USER=chief_user
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=YOUR_REDIS_PASSWORD_HERE

# Security
SECRET_KEY=YOUR_SECRET_KEY_HERE
JWT_SECRET=YOUR_JWT_SECRET_HERE

# Ukrainian Settings
TZ=Europe/Kyiv
LANG=uk_UA.UTF-8
```

### Конфігурація CHIEF

Редагуйте `configs/ukrainian_hospital_config.yaml`:

```yaml
general:
  experiment_name: "my_hospital"
  language: "uk"

data:
  slides_dir: "/data/slides"
  features_dir: "/data/features"
  results_dir: "/data/results"

model:
  pretrained_weights: "/app/model_weight/CHIEF_pretraining.pth"
  size_arg: "small"

# ... інші налаштування
```

---

## Використання

### Основні команди Docker Compose

```bash
# Запуск всіх сервісів
docker-compose up -d

# Зупинка
docker-compose down

# Перезапуск
docker-compose restart

# Перегляд логів
docker-compose logs -f chief

# Виконання команд в контейнері
docker-compose exec chief bash

# Масштабування (якщо потрібно)
docker-compose up -d --scale chief=3
```

### Робота з CHIEF контейнером

#### Інтерактивна оболонка

```bash
# Увійти в контейнер
docker-compose exec chief bash

# Активувати conda (якщо потрібно)
# conda activate chief

# Запустити аналіз
python3 Get_CHIEF_patch_feature.py
```

#### Аналіз окремого зображення

```bash
# Копіювання зображення в контейнер
docker cp ./my_slide.svs chief_main:/data/slides/

# Запуск аналізу
docker-compose exec chief python3 Get_CHIEF_WSI_level_feature.py \
  --input /data/slides/my_slide.svs \
  --output /data/results/
```

#### Пакетна обробка

```bash
# Розмістити CSV файл з списком зразків
docker cp ./slides_list.csv chief_main:/data/metadata/

# Запустити пакетну обробку
docker-compose exec chief python3 Get_CHIEF_WSI_level_feature_batch.py \
  --csv /data/metadata/slides_list.csv \
  --features_dir /data/features \
  --output_dir /data/results
```

### Використання API (якщо реалізовано)

```bash
# Перевірка здоров'я
curl http://localhost/health

# Відправка зображення на аналіз (приклад)
curl -X POST http://localhost/api/analyze \
  -F "file=@/path/to/slide.svs" \
  -F "anatomic_site=13"

# Отримання результатів
curl http://localhost/api/results/{result_id}
```

### Jupyter Notebook

```bash
# Запуск Jupyter в режимі розробки
docker-compose -f docker-compose.dev.yml up jupyter

# Відкрити в браузері
# http://localhost:8888
```

---

## Моніторинг

### Grafana

Відкрийте http://localhost:3000

- **Логін**: admin
- **Пароль**: admin_change_me (змініть в docker-compose.yml)

Дашборди для моніторингу:
- Використання GPU
- Швидкість обробки зображень
- Статус черги
- Помилки системи

### Prometheus

Відкрийте http://localhost:9090

Метрики:
- `chief_processing_time_seconds` - Час обробки
- `chief_queue_size` - Розмір черги
- `chief_gpu_utilization` - Використання GPU
- `chief_errors_total` - Кількість помилок

### Логи

```bash
# Всі логи
docker-compose logs

# Логи конкретного сервісу
docker-compose logs -f chief

# Останні 100 рядків
docker-compose logs --tail=100 chief

# Логи з timestamp
docker-compose logs -t chief

# Збереження логів у файл
docker-compose logs chief > chief_logs.txt
```

### Системні метрики

```bash
# Використання ресурсів
docker stats

# Детальна інформація про контейнер
docker inspect chief_main

# Дисковий простір
docker system df
```

---

## Troubleshooting

### Проблема: Контейнер не може знайти GPU

**Рішення:**

```bash
# Перевірка NVIDIA Docker Runtime
docker run --rm --gpus all nvidia/cuda:11.1-base nvidia-smi

# Якщо помилка, перезапустіть Docker
sudo systemctl restart docker

# Перевірка конфігурації Docker
cat /etc/docker/daemon.json
# Має містити:
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

### Проблема: Out of Memory

**Рішення:**

```bash
# Збільшення swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Обмеження пам'яті для контейнера (в docker-compose.yml)
services:
  chief:
    deploy:
      resources:
        limits:
          memory: 16G
```

### Проблема: Повільна обробка

**Перевірте:**

1. Використання GPU:
```bash
docker-compose exec chief nvidia-smi
```

2. Розмір batch:
```yaml
# В конфігурації
inference:
  batch_size: 1  # Зменшіть якщо OOM
```

3. Кількість workers:
```yaml
data:
  num_workers: 4  # Налаштуйте під ваш CPU
```

### Проблема: Не можу підключитися до PostgreSQL

**Рішення:**

```bash
# Перевірка статусу
docker-compose ps postgres

# Перевірка логів
docker-compose logs postgres

# Підключення до БД
docker-compose exec postgres psql -U chief_user -d chief_db

# Скидання пароля (якщо потрібно)
docker-compose exec postgres psql -U chief_user -d chief_db -c "ALTER USER chief_user WITH PASSWORD 'new_password';"
```

### Проблема: Порти зайняті

**Рішення:**

```bash
# Перевірка зайнятих портів
sudo netstat -tulpn | grep LISTEN

# Зміна портів у docker-compose.yml
services:
  chief:
    ports:
      - "8001:8000"  # Зміна з 8000 на 8001
```

### Очищення системи

```bash
# Зупинка всіх контейнерів
docker-compose down

# Видалення volumes (УВАГА: видалить дані!)
docker-compose down -v

# Очищення невикористаних образів
docker image prune -a

# Повне очищення Docker
docker system prune -a --volumes
```

---

## Оновлення

### Оновлення коду

```bash
# Зупинити контейнери
docker-compose down

# Отримати останні зміни
git pull origin main

# Пересібрати образи
docker-compose build --no-cache

# Запустити
docker-compose up -d
```

### Оновлення ваг моделі

```bash
# Завантажити нові ваги
# Розмістити у model_weight/

# Перезапустити контейнер
docker-compose restart chief
```

---

## Безпека

### Рекомендації

1. **Змініть паролі за замовчуванням**:
```bash
# В docker-compose.yml
POSTGRES_PASSWORD: YOUR_SECURE_PASSWORD
REDIS_PASSWORD: YOUR_SECURE_PASSWORD
GF_SECURITY_ADMIN_PASSWORD: YOUR_SECURE_PASSWORD
```

2. **Використовуйте HTTPS**:
```bash
# Додайте SSL сертифікати в nginx/ssl/
# Оновіть nginx конфігурацію
```

3. **Обмежте доступ до портів**:
```yaml
# Не відкривайте порти назовні якщо не потрібно
ports:
  - "127.0.0.1:5432:5432"  # Тільки локально
```

4. **Регулярні бекапи**:
```bash
# Налаштуйте cron для автоматичних бекапів
0 2 * * * /path/to/backup_script.sh
```

---

## Додаткові ресурси

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NVIDIA Docker](https://github.com/NVIDIA/nvidia-docker)
- [CHIEF GitHub](https://github.com/hms-dbmi/CHIEF)

---

## Підтримка

Якщо виникли проблеми:

1. Перевірте логи: `docker-compose logs`
2. Перегляньте FAQ вище
3. Створіть Issue на GitHub
4. Зверніться до спільноти

---

**Версія документа**: 1.0
**Останнє оновлення**: Листопад 2025
**Автор**: CHIEF Ukraine Adaptation Team
