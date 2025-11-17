# Docker - Швидкий довідник для CHIEF

## 🚀 Найпоширеніші команди

### Базові операції

```bash
# Запуск проєкту
make up
# або
docker-compose up -d

# Зупинка
make down
# або
docker-compose down

# Перезапуск
make restart
# або
docker-compose restart

# Статус
make status
# або
docker-compose ps

# Логи
make logs
# або
docker-compose logs -f
```

### Вхід у контейнер

```bash
# CHIEF контейнер
make shell
# або
docker-compose exec chief bash

# PostgreSQL
make shell-postgres
# або
docker-compose exec postgres psql -U chief_user -d chief_db
```

### Перевірка GPU

```bash
# Швидка перевірка
make test-gpu

# Детальна інформація
docker-compose exec chief nvidia-smi
docker-compose exec chief python3 -c "import torch; print(torch.cuda.is_available())"
```

## 📁 Створені файли

### Основні Docker файли (8 файлів)

| Файл | Рядків | Опис |
|------|--------|------|
| `Dockerfile` | 67 | Основний образ CHIEF з CUDA підтримкою |
| `docker-compose.yml` | 284 | Production конфігурація всіх сервісів |
| `docker-compose.dev.yml` | 84 | Конфігурація для розробки з Jupyter |
| `.dockerignore` | 53 | Виключення файлів з Docker образу |
| `nginx/nginx.conf` | 32 | Основна конфігурація Nginx |
| `nginx/conf.d/chief.conf` | 72 | Конфігурація проксі для CHIEF |
| `sql/init.sql` | 146 | Ініціалізація PostgreSQL БД |
| `DOCKER_DEPLOYMENT.md` | 612 | Повна документація з розгортання |

**Додатково:**
- `Makefile` - 185 рядків (зручне управління)
- `scripts/backup.sh` - 97 рядків (резервне копіювання)
- `scripts/restore.sh` - 118 рядків (відновлення)
- `DOCKER_QUICK_REFERENCE.md` - цей файл

**Усього Docker інфраструктури: ~1750+ рядків коду**

### Попередньо створені файли адаптації (8 файлів)

| Файл | Рядків | Опис |
|------|--------|------|
| `README_uk.md` | 262 | Українська документація |
| `UKRAINE_ADAPTATION.md` | 348 | Опис адаптації |
| `configs/anatomic_mapping_uk.yaml` | 71 | Анатомічні терміни UK |
| `configs/ukrainian_hospital_config.yaml` | 310 | Конфігурація медзакладу |
| `docs_uk/INTEGRATION_GUIDE_uk.md` | 619 | Посібник з інтеграції |
| `examples_uk/QUICK_START_uk.md` | 415 | Швидкий старт UK |
| `utils/ukrainian_localization.py` | 300 | Модуль локалізації |
| `README.md` (modified) | +8 | Посилання на UK документацію |

**Усього адаптації: 2331+ рядків коду**

**ЗАГАЛЬНА КІЛЬКІСТЬ: 4000+ рядків нового коду для України! 🇺🇦**

## 🏗️ Структура проєкту

```
MedicineProject/
├── Dockerfile                              # Основний образ
├── docker-compose.yml                      # Production
├── docker-compose.dev.yml                  # Development
├── .dockerignore                           # Виключення
├── Makefile                                # Команди управління
│
├── configs/
│   ├── anatomic_mapping_uk.yaml           # 🇺🇦 Анатомічні терміни
│   └── ukrainian_hospital_config.yaml     # 🇺🇦 Конфігурація
│
├── docs_uk/
│   └── INTEGRATION_GUIDE_uk.md            # 🇺🇦 Посібник інтеграції
│
├── examples_uk/
│   └── QUICK_START_uk.md                  # 🇺🇦 Швидкий старт
│
├── nginx/
│   ├── nginx.conf                         # Основна конфігурація
│   └── conf.d/
│       └── chief.conf                     # CHIEF проксі
│
├── scripts/
│   ├── backup.sh                          # Резервне копіювання
│   └── restore.sh                         # Відновлення
│
├── sql/
│   └── init.sql                           # Ініціалізація БД
│
├── utils/
│   └── ukrainian_localization.py          # 🇺🇦 Модуль локалізації
│
├── data/                                   # Дані (створюється автоматично)
│   ├── slides/                            # WSI зображення
│   ├── features/                          # Витягнуті ознаки
│   ├── results/                           # Результати
│   ├── metadata/                          # CSV метадані
│   └── ...
│
├── model_weight/                          # Ваги моделей (завантажити)
│   ├── CHIEF_pretraining.pth
│   ├── CHIEF_CTransPath.pth
│   └── Text_emdding.pth
│
├── README_uk.md                           # 🇺🇦 Головна документація
├── UKRAINE_ADAPTATION.md                  # 🇺🇦 Опис адаптації
├── DOCKER_DEPLOYMENT.md                   # Документація Docker
└── DOCKER_QUICK_REFERENCE.md             # Цей файл
```

## 🐳 Сервіси Docker Compose

### Production (docker-compose.yml)

| Сервіс | Порт | Опис |
|--------|------|------|
| **chief** | 8000, 5000, 6006 | Основний контейнер CHIEF з GPU |
| **postgres** | 5432 | База даних PostgreSQL 14 |
| **redis** | 6379 | Кеш та черги Redis 7 |
| **nginx** | 80, 443 | Reverse proxy Nginx |
| **prometheus** | 9090 | Збір метрик Prometheus |
| **grafana** | 3000 | Візуалізація Grafana |

### Development (docker-compose.dev.yml)

| Сервіс | Порт | Опис |
|--------|------|------|
| **chief-dev** | 8000, 5000, 6006, 8888 | Розробка з live reload |
| **jupyter** | 8888 | Jupyter Lab для експериментів |

## 💻 Приклади використання

### 1. Початкове налаштування

```bash
# Клонування
git clone https://github.com/Tonnnya/MedicineProject.git
cd MedicineProject

# Ініціалізація
make init

# Завантажити ваги моделі в model_weight/

# Збірка
make build

# Запуск
make up
```

### 2. Аналіз зображення

```bash
# Копіювання зображення
docker cp my_slide.svs chief_main:/data/slides/

# Вхід в контейнер
make shell

# В контейнері
python3 Get_CHIEF_WSI_level_feature.py \
  --input /data/slides/my_slide.svs \
  --output /data/results/
```

### 3. Пакетна обробка

```bash
# Підготовка CSV файлу
cat > data/metadata/batch.csv << EOF
slide_id,anatomic_site
patient_001,13
patient_002,1
patient_003,6
EOF

# Запуск обробки
docker-compose exec chief python3 Get_CHIEF_WSI_level_feature_batch.py \
  --csv /data/metadata/batch.csv \
  --features_dir /data/features \
  --output_dir /data/results
```

### 4. Українська локалізація

```bash
# Тест локалізації
make test-localization

# Використання в Python
docker-compose exec chief python3 << EOF
from utils.ukrainian_localization import UkrainianLocalization

loc = UkrainianLocalization()
loc.print_all_organs(language='uk')

# Отримання індексу
index = loc.get_anatomic_index("товста кишка", language='uk')
print(f"Індекс: {index}")
EOF
```

### 5. Моніторинг

```bash
# Відкрити Grafana
xdg-open http://localhost:3000

# Відкрити Prometheus
xdg-open http://localhost:9090

# Переглянути метрики
docker-compose exec chief python3 << EOF
import psutil
print(f"CPU: {psutil.cpu_percent()}%")
print(f"RAM: {psutil.virtual_memory().percent}%")
EOF
```

### 6. Резервне копіювання

```bash
# Створити бекап
make backup
# або
./scripts/backup.sh

# Відновити з бекапу
make restore
# або
./scripts/restore.sh
```

### 7. Розробка

```bash
# Запуск в режимі розробки
make up-dev

# Jupyter доступний на http://localhost:8888

# Live reload коду - просто редагуйте файли
```

### 8. Troubleshooting

```bash
# Перевірка логів
make logs-chief

# Перевірка GPU
make test-gpu

# Перевірка стану
make status

# Повний рестарт
make down
make up
```

## 📊 Volumes (Постійні дані)

| Volume | Призначення | Розмір |
|--------|-------------|--------|
| `chief_data_slides` | WSI зображення | Великий (TB) |
| `chief_data_features` | Витягнуті ознаки | Середній (GB) |
| `chief_data_results` | Результати аналізу | Середній (GB) |
| `chief_data_metadata` | CSV метадані | Малий (MB) |
| `chief_postgres_data` | База даних | Середній (GB) |
| `chief_redis_data` | Redis дані | Малий (MB) |
| `chief_logs` | Логи системи | Малий (MB) |

### Управління volumes

```bash
# Перегляд всіх volumes
docker volume ls | grep chief

# Розмір volumes
docker system df -v

# Очищення (УВАГА: видалить дані!)
docker-compose down -v

# Бекап окремого volume
docker run --rm \
  -v chief_data_results:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/results.tar.gz /data
```

## 🔒 Безпека

### Паролі за замовчуванням (ЗМІНІТЬ!)

```yaml
# В docker-compose.yml
POSTGRES_PASSWORD: chief_password_change_me
REDIS_PASSWORD: chief_redis_password_change_me
GF_SECURITY_ADMIN_PASSWORD: admin_change_me
```

### Створення .env файлу

```bash
cat > .env << EOF
# PostgreSQL
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE

# Redis
REDIS_PASSWORD=YOUR_REDIS_PASSWORD_HERE

# Grafana
GF_SECURITY_ADMIN_PASSWORD=YOUR_GRAFANA_PASSWORD_HERE

# JWT
SECRET_KEY=$(openssl rand -hex 32)
EOF
```

## 🔍 Корисні команди Docker

### Інформація

```bash
# Використання ресурсів
docker stats

# Інформація про контейнер
docker inspect chief_main

# Логи з timestamp
docker-compose logs -t -f chief

# Останні 100 рядків
docker-compose logs --tail=100 chief
```

### Очищення

```bash
# Очищення зупинених контейнерів
docker container prune

# Очищення невикористаних образів
docker image prune -a

# Очищення volumes (УВАГА!)
docker volume prune

# Повне очищення
docker system prune -a --volumes
```

### Мережа

```bash
# Перегляд мережі
docker network inspect chief_network

# Підключення до мережі
docker network connect chief_network my_container

# Тест з'єднання
docker-compose exec chief ping postgres
```

## 📈 Моніторинг та метрики

### Prometheus запити

```promql
# Використання GPU
nvidia_gpu_utilization_percent

# Час обробки
chief_processing_time_seconds

# Розмір черги
chief_queue_size

# Помилки
rate(chief_errors_total[5m])
```

### Grafana дашборди

1. **System Overview**
   - CPU, RAM, GPU usage
   - Disk I/O
   - Network traffic

2. **CHIEF Performance**
   - Processing time per slide
   - Queue size
   - Throughput (slides/hour)

3. **Database**
   - PostgreSQL connections
   - Query performance
   - Table sizes

## 🆘 Підтримка

### Де шукати допомогу

1. **Документація:**
   - `DOCKER_DEPLOYMENT.md` - Повна інструкція
   - `README_uk.md` - Основна документація
   - `docs_uk/INTEGRATION_GUIDE_uk.md` - Посібник

2. **Логи:**
   ```bash
   make logs          # Всі сервіси
   make logs-chief    # Тільки CHIEF
   make logs-postgres # База даних
   ```

3. **GitHub Issues:**
   - https://github.com/hms-dbmi/CHIEF/issues

4. **Email:**
   - xiyue.wang.scu@gmail.com
   - Kun-Hsing_Yu@hms.harvard.edu

---

**Версія:** 1.0
**Дата:** Листопад 2025
**Автор:** CHIEF Ukraine Adaptation Team 🇺🇦
