# Dockerfile для CHIEF - Ukrainian Adaptation
# Base image з CUDA підтримкою
FROM nvidia/cuda:11.1.1-cudnn8-devel-ubuntu20.04

# Метадані
LABEL maintainer="CHIEF Ukraine Adaptation"
LABEL description="CHIEF - Clinical Histopathology Imaging Evaluation Foundation Model for Ukraine"
LABEL version="1.0-ukraine"

# Уникнення інтерактивних запитів під час встановлення
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Kyiv

# Встановлення системних залежностей
RUN apt-get update && apt-get install -y \
    python3.8 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    openslide-tools \
    libopencv-dev \
    build-essential \
    vim \
    nano \
    htop \
    tzdata \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Налаштування локалі для української мови
RUN locale-gen uk_UA.UTF-8 en_US.UTF-8
ENV LANG=uk_UA.UTF-8
ENV LANGUAGE=uk_UA:uk
ENV LC_ALL=uk_UA.UTF-8

# Налаштування часового поясу
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Створення робочої директорії
WORKDIR /app

# Копіювання requirements.txt
COPY requirements.txt .

# Встановлення Python залежностей
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install torch==1.8.1+cu111 torchvision==0.9.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install -r requirements.txt

# Копіювання всього проєкту
COPY . .

# Створення необхідних директорій
RUN mkdir -p /data/slides \
             /data/features \
             /data/results \
             /data/temp \
             /data/archive \
             /data/metadata \
             /data/queue \
             /var/log/chief \
             model_weight

# Налаштування прав доступу
RUN chmod -R 755 /app
RUN chmod -R 777 /data
RUN chmod -R 777 /var/log/chief

# Змінні середовища
ENV PYTHONPATH=/app
ENV CUDA_VISIBLE_DEVICES=0

# Expose порти (для моніторингу, API, тощо)
EXPOSE 8000 5000 6006

# Встановлення точки входу
ENTRYPOINT ["python3"]
CMD ["--version"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import torch; print(torch.cuda.is_available())" || exit 1
