# Makefile для CHIEF Ukraine
# Зручне управління Docker Compose

.PHONY: help build up down restart logs clean test shell backup

# Кольори для виводу
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Показати цю довідку
	@echo "$(BLUE)CHIEF - Ukrainian Adaptation$(NC)"
	@echo "$(GREEN)Доступні команди:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

build: ## Збудувати всі Docker образи
	@echo "$(BLUE)Збірка Docker образів...$(NC)"
	docker-compose build

build-no-cache: ## Збудувати образи без кешу
	@echo "$(BLUE)Збірка Docker образів без кешу...$(NC)"
	docker-compose build --no-cache

up: ## Запустити всі сервіси
	@echo "$(GREEN)Запуск сервісів...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Сервіси запущено!$(NC)"
	@make status

up-dev: ## Запустити в режимі розробки
	@echo "$(GREEN)Запуск в режимі розробки...$(NC)"
	docker-compose -f docker-compose.dev.yml up -d
	@echo "$(GREEN)Jupyter доступний на http://localhost:8888$(NC)"

down: ## Зупинити всі сервіси
	@echo "$(YELLOW)Зупинка сервісів...$(NC)"
	docker-compose down

down-volumes: ## Зупинити сервіси та видалити volumes (УВАГА!)
	@echo "$(RED)УВАГА: Це видалить всі дані!$(NC)"
	@read -p "Ви впевнені? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
	fi

restart: ## Перезапустити всі сервіси
	@echo "$(YELLOW)Перезапуск сервісів...$(NC)"
	docker-compose restart

restart-chief: ## Перезапустити тільки CHIEF
	@echo "$(YELLOW)Перезапуск CHIEF...$(NC)"
	docker-compose restart chief

logs: ## Переглянути логи всіх сервісів
	docker-compose logs -f

logs-chief: ## Переглянути логи CHIEF
	docker-compose logs -f chief

logs-postgres: ## Переглянути логи PostgreSQL
	docker-compose logs -f postgres

status: ## Показати статус сервісів
	@echo "$(BLUE)Статус сервісів:$(NC)"
	@docker-compose ps

shell: ## Увійти в CHIEF контейнер
	@echo "$(GREEN)Підключення до CHIEF контейнера...$(NC)"
	docker-compose exec chief bash

shell-postgres: ## Увійти в PostgreSQL
	docker-compose exec postgres psql -U chief_user -d chief_db

test: ## Запустити тести
	@echo "$(BLUE)Запуск тестів...$(NC)"
	docker-compose exec chief python3 -m pytest tests/

test-gpu: ## Перевірити GPU
	@echo "$(BLUE)Перевірка GPU...$(NC)"
	docker-compose exec chief nvidia-smi
	docker-compose exec chief python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())"

test-localization: ## Тестувати українську локалізацію
	@echo "$(BLUE)Тестування локалізації...$(NC)"
	docker-compose exec chief python3 utils/ukrainian_localization.py

clean: ## Очистити тимчасові файли
	@echo "$(YELLOW)Очищення тимчасових файлів...$(NC)"
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.log" -delete
	@echo "$(GREEN)Очищення завершено!$(NC)"

clean-docker: ## Очистити невикористані Docker ресурси
	@echo "$(YELLOW)Очищення Docker...$(NC)"
	docker system prune -f

backup: ## Створити резервну копію даних
	@echo "$(BLUE)Створення резервної копії...$(NC)"
	./scripts/backup.sh

restore: ## Відновити дані з резервної копії
	@echo "$(BLUE)Відновлення даних...$(NC)"
	./scripts/restore.sh

init: ## Початкове налаштування проєкту
	@echo "$(BLUE)Ініціалізація проєкту...$(NC)"
	mkdir -p data/{slides,features,results,metadata,temp,archive,queue}
	mkdir -p logs
	mkdir -p model_weight
	mkdir -p monitoring/{prometheus,grafana}
	mkdir -p notebooks
	@echo "$(GREEN)Директорії створено!$(NC)"
	@echo "$(YELLOW)Не забудьте завантажити ваги моделі в model_weight/$(NC)"

install: init build ## Повне встановлення (init + build)
	@echo "$(GREEN)Встановлення завершено!$(NC)"
	@echo "$(YELLOW)Для запуску використайте: make up$(NC)"

monitor: ## Відкрити інструменти моніторингу
	@echo "$(GREEN)Grafana: http://localhost:3000 (admin/admin_change_me)$(NC)"
	@echo "$(GREEN)Prometheus: http://localhost:9090$(NC)"
	@echo "$(GREEN)TensorBoard: http://localhost:6006$(NC)"

ps: ## Показати запущені контейнери (alias для status)
	@make status

exec: ## Виконати команду в CHIEF контейнері (використання: make exec CMD="python script.py")
	docker-compose exec chief $(CMD)

# Приклади використання
example-patch: ## Приклад: аналіз окремого фрагменту
	docker-compose exec chief python3 Get_CHIEF_patch_feature.py

example-wsi: ## Приклад: аналіз цілого слайду
	docker-compose exec chief python3 Get_CHIEF_WSI_level_feature.py

example-batch: ## Приклад: пакетна обробка
	docker-compose exec chief python3 Get_CHIEF_WSI_level_feature_batch.py

# Розробка
dev-install: ## Встановити залежності для розробки
	pip install -r requirements-dev.txt

dev-format: ## Форматувати код (black, isort)
	black .
	isort .

dev-lint: ## Перевірити якість коду
	flake8 .
	pylint **/*.py

# Документація
docs: ## Відкрити документацію
	@echo "$(GREEN)Документація:$(NC)"
	@echo "  - README_uk.md - Основна документація"
	@echo "  - DOCKER_DEPLOYMENT.md - Розгортання Docker"
	@echo "  - examples_uk/QUICK_START_uk.md - Швидкий старт"
	@echo "  - docs_uk/INTEGRATION_GUIDE_uk.md - Посібник з інтеграції"

# За замовчуванням
.DEFAULT_GOAL := help
