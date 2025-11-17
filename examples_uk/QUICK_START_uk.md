# Швидкий старт CHIEF для українських медичних закладів

## Зміст
1. [Вступ](#вступ)
2. [Встановлення](#встановлення)
3. [Базові приклади](#базові-приклади)
4. [Адаптація для українських даних](#адаптація-для-українських-даних)
5. [Поширені питання](#поширені-питання)

## Вступ

CHIEF - це фундаментальна модель для аналізу гістопатологічних зображень, розроблена Гарвардською медичною школою. Цей посібник допоможе швидко почати використання CHIEF у вашому медичному закладі.

## Встановлення

### Крок 1: Підготовка середовища

```bash
# Встановіть Anaconda, якщо ще не встановлена
wget https://repo.anaconda.com/archive/Anaconda3-2023.03-Linux-x86_64.sh
bash Anaconda3-2023.03-Linux-x86_64.sh

# Створіть нове віртуальне середовище
conda create -n chief python=3.8
conda activate chief
```

### Крок 2: Встановлення залежностей

```bash
# Встановіть OpenSlide (необхідно для обробки WSI)
sudo apt-get update
sudo apt-get install openslide-tools

# Встановіть Python-пакети
pip install torch==1.8.1+cu111 torchvision==0.9.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html
pip install -r requirements.txt
```

### Крок 3: Завантаження моделей

```bash
# Завантажте попередньо навчені ваги моделі
# Зверніться за доступом до Google Drive:
# https://drive.google.com/drive/folders/1uRv9A1HuTW5m_pJoyMzdN31bE1i-tDaV

# Створіть директорію для ваг
mkdir -p model_weight

# Розмістіть завантажені файли у директорії model_weight/
```

## Базові приклади

### Приклад 1: Аналіз окремого фрагменту зображення

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Приклад використання CHIEF для аналізу окремого фрагменту
гістопатологічного зображення
"""

import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
from models.ctran import ctranspath

def analyze_patch(image_path):
    """
    Аналізує окремий фрагмент гістопатологічного зображення

    Параметри:
        image_path (str): Шлях до зображення

    Повертає:
        torch.Tensor: Вектор ознак розміру [1, 768]
    """
    # Параметри нормалізації
    mean = (0.485, 0.456, 0.406)
    std = (0.229, 0.224, 0.225)

    # Трансформації зображення
    transform = transforms.Compose([
        transforms.Resize(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std)
    ])

    # Завантаження моделі
    model = ctranspath()
    model.head = nn.Identity()

    # Завантаження ваг
    checkpoint = torch.load('./model_weight/CHIEF_CTransPath.pth')
    model.load_state_dict(checkpoint['model'], strict=True)
    model.eval()

    # Обробка зображення
    image = Image.open(image_path)
    image_tensor = transform(image).unsqueeze(0)

    # Інференс
    with torch.no_grad():
        features = model(image_tensor)

    print(f"Розмір вектора ознак: {features.size()}")
    return features

# Використання
if __name__ == "__main__":
    features = analyze_patch("./example/example.tif")
    print(f"Успішно витягнуто ознаки з розміром: {features.shape}")
```

### Приклад 2: Аналіз цілого слайду (WSI)

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Приклад використання CHIEF для аналізу цілого слайду (WSI)
"""

import torch
import torch.nn as nn
from models.CHIEF import CHIEF

def analyze_wsi(features_path, anatomic_site):
    """
    Аналізує цілий слайд за допомогою попередньо витягнутих ознак

    Параметри:
        features_path (str): Шлях до файлу з ознаками
        anatomic_site (int): Анатомічна локалізація (0-18)

    Повертає:
        dict: Результати аналізу
    """
    # Мапінг анатомічних сайтів (український переклад)
    anatomic_mapping = {
        0: 'головний мозок',
        1: 'молочна залоза',
        2: 'сечовий міхур',
        3: 'нирка',
        4: 'передміхурова залоза',
        5: 'яєчко',
        6: 'легеня',
        7: 'підшлункова залоза',
        8: 'печінка',
        9: 'шкіра',
        10: 'яєчник',
        11: 'шийка матки',
        12: 'матка',
        13: 'товста кишка',
        14: 'стравохід',
        15: 'шлунок',
        16: 'щитоподібна залоза',
        17: 'надниркова залоза',
        18: "м'які тканини"
    }

    # Завантаження моделі
    model = CHIEF(size_arg="small", dropout=True, n_classes=2)
    checkpoint = torch.load('./model_weight/CHIEF_pretraining.pth')
    model.load_state_dict(checkpoint, strict=True)
    model.eval()

    # Завантаження ознак
    features = torch.load(features_path, map_location=torch.device('cpu'))

    # Інференс
    with torch.no_grad():
        result = model(features, torch.tensor([anatomic_site]))

    wsi_features = result['WSI_feature']

    print(f"Анатомічна локалізація: {anatomic_mapping[anatomic_site]}")
    print(f"Розмір вектора ознак WSI: {wsi_features.size()}")

    return result

# Використання
if __name__ == "__main__":
    # Приклад: аналіз зразка товстої кишки (colon = 13)
    result = analyze_wsi(
        features_path="./Downstream/Tumor_origin/src/feature/tcga/TCGA-LN-A8I1-01Z-00-DX1.F2C4FBC3-1FFA-45E9-9483-C3F1B2B7EF2D.pt",
        anatomic_site=13
    )
    print("Аналіз успішно завершено!")
```

### Приклад 3: Пакетна обробка декількох зразків

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Приклад пакетної обробки множини WSI зразків
"""

import os
import torch
import pandas as pd
from models.CHIEF import CHIEF
from tqdm import tqdm

def batch_analyze_wsi(csv_file, features_dir, output_file):
    """
    Пакетна обробка множини WSI зразків

    Параметри:
        csv_file (str): CSV файл зі списком зразків
        features_dir (str): Директорія з файлами ознак
        output_file (str): Файл для збереження результатів
    """
    # Завантаження моделі
    model = CHIEF(size_arg="small", dropout=True, n_classes=2)
    checkpoint = torch.load('./model_weight/CHIEF_pretraining.pth')
    model.load_state_dict(checkpoint, strict=True)
    model.eval()

    # Завантаження списку зразків
    df = pd.read_csv(csv_file)
    results = []

    # Обробка кожного зразка
    for idx, row in tqdm(df.iterrows(), total=len(df), desc="Обробка зразків"):
        try:
            # Завантаження ознак
            feature_path = os.path.join(features_dir, f"{row['slide_id']}.pt")
            features = torch.load(feature_path, map_location=torch.device('cpu'))

            # Інференс
            with torch.no_grad():
                result = model(features, torch.tensor([row['anatomic_site']]))

            # Збереження результатів
            results.append({
                'slide_id': row['slide_id'],
                'anatomic_site': row['anatomic_site'],
                'features_shape': result['WSI_feature'].shape,
                'status': 'success'
            })

        except Exception as e:
            results.append({
                'slide_id': row['slide_id'],
                'status': 'failed',
                'error': str(e)
            })

    # Збереження результатів
    results_df = pd.DataFrame(results)
    results_df.to_csv(output_file, index=False)
    print(f"Результати збережено у {output_file}")

    return results_df

# Використання
if __name__ == "__main__":
    results = batch_analyze_wsi(
        csv_file="./example_csv/test_tcga.csv",
        features_dir="./Downstream/Tumor_origin/src/feature/tcga",
        output_file="./results/batch_analysis_results.csv"
    )
    print(f"Оброблено {len(results)} зразків")
    print(f"Успішно: {sum(results['status'] == 'success')}")
    print(f"Помилок: {sum(results['status'] == 'failed')}")
```

## Адаптація для українських даних

### Структура даних

Організуйте ваші дані наступним чином:

```
/path/to/your/data/
├── slides/              # WSI зображення
│   ├── patient_001.svs
│   ├── patient_002.svs
│   └── ...
├── features/            # Витягнуті ознаки
│   ├── patient_001.pt
│   ├── patient_002.pt
│   └── ...
└── metadata/            # Метадані
    ├── train.csv
    ├── val.csv
    └── test.csv
```

### Формат метаданих (CSV)

```csv
slide_id,patient_id,anatomic_site,diagnosis,hospital
patient_001,PAT001,1,рак молочної залози,Київський онкоцентр
patient_002,PAT002,13,рак товстої кишки,Львівська обласна лікарня
patient_003,PAT003,6,рак легені,Харківський медуніверситет
```

### Конфігурація для українського закладу

```yaml
# config_ukrainian_hospital.yaml

# Загальні налаштування
experiment_name: "ukrainian_hospital_pilot"
language: "uk"

# Налаштування даних
data:
  slides_dir: "/path/to/slides"
  features_dir: "/path/to/features"
  csv_file: "/path/to/metadata/train.csv"

# Налаштування моделі
model:
  size_arg: "small"
  dropout: true
  n_classes: 2

# Використання української локалізації
use_ukrainian_mapping: true
anatomic_mapping_file: "./configs/anatomic_mapping_uk.yaml"

# Налаштування навчання
training:
  batch_size: 1
  num_epochs: 50
  learning_rate: 0.0001

# Налаштування валідації
validation:
  frequency: 5  # кожні 5 епох
  metrics: ["accuracy", "auc", "f1"]
```

## Поширені питання

### Q1: Які вимоги до обладнання?

**Відповідь**: Мінімальні вимоги:
- GPU: NVIDIA з 8GB+ VRAM (рекомендовано 16GB+)
- RAM: 32GB+
- Диск: 500GB+ SSD для зберігання WSI та ознак

### Q2: Як підготувати WSI зображення?

**Відповідь**:
1. Переконайтеся, що зображення у форматі .svs, .tif або .ndpi
2. Рекомендована роздільна здатність: 40x або 20x
3. Переконайтеся в якості фарбування (H&E)
4. Використовуйте стандартні протоколи підготовки тканин

### Q3: Скільки часу займає обробка одного зразка?

**Відповідь**:
- Витягування ознак: 5-15 хвилин на WSI
- Інференс з готовими ознаками: <1 секунди
- Загальний час залежить від розміру зображення та обладнання

### Q4: Чи можна використовувати для інших типів фарбування?

**Відповідь**: CHIEF навчалась на H&E зображеннях. Для інших типів фарбування (IHC, IF) може знадобитися додаткове тонке налаштування.

### Q5: Як забезпечити конфіденційність пацієнтів?

**Відповідь**:
1. Видаліть всі персональні дані з метаданих
2. Використовуйте анонімні ідентифікатори
3. Дотримуйтесь українського законодавства про захист даних
4. Обробляйте дані локально, не передаючи через інтернет

### Q6: Де отримати підтримку?

**Відповідь**:
- Документація: README_uk.md
- GitHub Issues: https://github.com/hms-dbmi/CHIEF/issues
- Email авторів: xiyue.wang.scu@gmail.com
- Локальна українська спільнота: (створюється)

## Корисні ресурси

- [Повна документація](../README_uk.md)
- [Конфігурація анатомічних термінів](../configs/anatomic_mapping_uk.yaml)
- [Оригінальна публікація в Nature](https://www.nature.com/articles/s41586-024-07894-z)
- [Docker образи](https://hub.docker.com/r/chiefcontainer/chief/)

## Приклад повного робочого процесу

```bash
# 1. Активуйте середовище
conda activate chief

# 2. Витягніть ознаки з WSI
python3 Get_CHIEF_patch_feature.py

# 3. Проведіть аналіз
python3 Get_CHIEF_WSI_level_feature.py

# 4. Для пакетної обробки
python3 Get_CHIEF_WSI_level_feature_batch.py

# 5. Для тонкого налаштування на ваших даних
cd Downstream/Tumor_origin/src
python3 train_valid_test.py --classification_type='tumor_origin' --exec_mode='train' --exp_name='ukrainian_hospital'
```

---

**Примітка**: Цей посібник постійно оновлюється. Якщо у вас є пропозиції щодо покращення, будь ласка, створіть Issue в GitHub репозиторії.
