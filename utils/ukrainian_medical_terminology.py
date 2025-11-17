#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Розширений модуль української медичної термінології для CHIEF
Extended Ukrainian Medical Terminology Module for CHIEF

Відповідно до стандартів:
- МОЗ України
- МКХ-11 (ICD-11)
- SNOMED CT
- WHO Classification of Tumours
- Terminologia Anatomica

According to standards:
- Ukrainian Ministry of Health
- ICD-11
- SNOMED CT
- WHO Classification of Tumours
- Terminologia Anatomica
"""

import yaml
from typing import Dict, List, Optional, Tuple
from pathlib import Path


class UkrainianMedicalTerminology:
    """
    Клас для роботи з українською медичною термінологією
    Class for working with Ukrainian medical terminology
    """

    def __init__(self, config_path: str = "./configs/anatomic_mapping_uk_extended.yaml"):
        """
        Ініціалізація модуля медичної термінології

        Args:
            config_path: шлях до розширеного конфігураційного файлу
        """
        self.config_path = config_path
        self.terminology = self._load_terminology()

    def _load_terminology(self) -> Dict:
        """Завантаження термінології з YAML файлу"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            raise FileNotFoundError(
                f"Файл {self.config_path} не знайдено. "
                f"Переконайтеся що розширена термінологія встановлена."
            )

    def get_anatomic_term(self, index: int, language: str = 'uk') -> Dict:
        """
        Отримати повну інформацію про анатомічний термін

        Args:
            index: індекс органу (0-18)
            language: мова ('uk', 'en', 'lat')

        Returns:
            Dict з повною інформацією про термін

        Example:
            >>> term = terminology.get_anatomic_term(13, 'uk')
            >>> print(term['official'])
            'товста кишка'
            >>> print(term['latin'])
            'intestinum crassum, colon'
        """
        if index < 0 or index > 18:
            raise ValueError(f"Індекс має бути від 0 до 18, отримано: {index}")

        data = self.terminology.get('Anatomic_Ukrainian_Official', {}).get(index, {})

        if not data:
            return {'error': f'Термін з індексом {index} не знайдено'}

        return data

    def get_icd11_code(self, organ: str, cancer_type: str = None) -> Optional[str]:
        """
        Отримати код МКХ-11 (ICD-11) для органу або типу раку

        Args:
            organ: назва органу англійською (напр. 'brain', 'lung')
            cancer_type: тип раку (опціонально)

        Returns:
            Код МКХ-11 або None

        Example:
            >>> code = terminology.get_icd11_code('lung')
            >>> print(code)
            '2C25'
        """
        cancer_types = self.terminology.get('Cancer_Types_ICD11', {})

        if organ in cancer_types:
            cancer_data = cancer_types[organ]
            return cancer_data.get('code')

        return None

    def format_diagnosis_report(
        self,
        anatomic_index: int,
        diagnosis_type: str,
        confidence: float,
        histology: str = None,
        grade: str = None,
        tnm: Dict = None
    ) -> str:
        """
        Форматувати медичний звіт українською мовою

        Args:
            anatomic_index: індекс анатомічної локалізації
            diagnosis_type: тип діагнозу ('malignant', 'benign', 'suspicious', 'normal')
            confidence: впевненість моделі (0-1)
            histology: гістологічний тип (опціонально)
            grade: ступінь диференціювання (опціонально)
            tnm: TNM стадіювання (опціонально)

        Returns:
            Відформатований звіт українською

        Example:
            >>> report = terminology.format_diagnosis_report(
            ...     anatomic_index=6,
            ...     diagnosis_type='malignant',
            ...     confidence=0.87,
            ...     histology='adenocarcinoma',
            ...     grade='G2'
            ... )
        """
        # Отримання анатомічної локалізації
        organ_data = self.get_anatomic_term(anatomic_index, 'uk')
        organ_name = organ_data.get('official', 'невідомий орган')
        latin_name = organ_data.get('latin', '')

        # Отримання діагнозу
        diagnosis_templates = self.terminology.get('Diagnosis_Templates', {})
        diagnosis_text = diagnosis_templates.get(diagnosis_type, {}).get('uk', 'Не визначено')

        # Визначення рівня впевненості
        if confidence >= 0.9:
            confidence_text = diagnosis_templates.get(diagnosis_type, {}).get(
                'confidence_high', 'з високою ймовірністю'
            )
        elif confidence >= 0.7:
            confidence_text = diagnosis_templates.get(diagnosis_type, {}).get(
                'confidence_moderate', 'з помірною ймовірністю'
            )
        else:
            confidence_text = diagnosis_templates.get(diagnosis_type, {}).get(
                'confidence_low', 'з низькою ймовірністю'
            )

        # Гістологічний тип
        histology_text = ""
        if histology:
            histology_data = self.terminology.get('Histological_Types', {}).get(histology, {})
            histology_uk = histology_data.get('uk', histology)
            histology_text = f"\n  Гістологічний тип: {histology_uk}"

        # Ступінь диференціювання
        grade_text = ""
        if grade:
            grade_data = self.terminology.get('Tumor_Grade', {}).get(grade, {})
            grade_uk = grade_data.get('uk', grade)
            grade_description = grade_data.get('description', '')
            grade_text = f"\n  Ступінь диференціювання: {grade} - {grade_uk} ({grade_description})"

        # TNM класифікація
        tnm_text = ""
        if tnm:
            tnm_staging = self.terminology.get('TNM_Staging', {})
            tnm_parts = []
            for component in ['T', 'N', 'M']:
                if component in tnm:
                    value = tnm[component]
                    description = tnm_staging.get(component, {}).get('values', {}).get(value, value)
                    tnm_parts.append(f"{component}: {value} ({description})")
            if tnm_parts:
                tnm_text = "\n  TNM: " + ", ".join(tnm_parts)

        # Формування звіту
        report = f"""
{'=' * 80}
АВТОМАТИЗОВАНИЙ АНАЛІЗ ГІСТОПАТОЛОГІЧНОГО ПРЕПАРАТУ
{'=' * 80}

АНАТОМІЧНА ЛОКАЛІЗАЦІЯ:
  Українська назва: {organ_name}
  Латинська назва: {latin_name}
  Топографія: {organ_data.get('topography', 'не вказано')}

РЕЗУЛЬТАТ АНАЛІЗУ:
  {diagnosis_text} {confidence_text}
  Впевненість моделі: {confidence:.1%}{histology_text}{grade_text}{tnm_text}

ПРИМІТКИ:
  - Код МКХ-11: {organ_data.get('icd11', 'не вказано')}
  - Дата аналізу: {self._get_current_date()}
  - Версія моделі: CHIEF Ukraine v2.0

{'=' * 80}
ВАЖЛИВЕ ЗАСТЕРЕЖЕННЯ
{'=' * 80}

Цей висновок створено автоматизованою системою аналізу гістопатологічних
зображень CHIEF (Clinical Histopathology Imaging Evaluation Foundation) та
є ЛИШЕ ДОПОМІЖНИМ ІНСТРУМЕНТОМ для прийняття клінічних рішень.

ОСТАТОЧНИЙ ДІАГНОЗ має бути встановлений кваліфікованим лікарем-
патологоанатомом на основі:
  - Комплексного аналізу всіх клінічних даних
  - Особистого мікроскопічного дослідження препарату
  - Додаткових досліджень (при необхідності)
  - Клініко-анамнестичних даних

Система відповідає вимогам МОЗ України та не замінює професійного
медичного судження.

{'=' * 80}
        """

        return report

    def get_tnm_explanation(self, tnm_code: str) -> Dict[str, str]:
        """
        Отримати пояснення TNM коду українською

        Args:
            tnm_code: TNM код (напр. 'T2', 'N1', 'M0')

        Returns:
            Dict з поясненням українською

        Example:
            >>> explanation = terminology.get_tnm_explanation('T2')
            >>> print(explanation)
            {'component': 'T', 'value': 'T2',
             'description': 'пухлина більшого розміру, але в межах органу'}
        """
        component = tnm_code[0]  # T, N, або M
        value = tnm_code  # T2, N1, тощо

        tnm_staging = self.terminology.get('TNM_Staging', {})
        component_data = tnm_staging.get(component, {})

        return {
            'component': component,
            'name': component_data.get('name', ''),
            'value': value,
            'description': component_data.get('values', {}).get(value, 'Опис не знайдено')
        }

    def get_cancer_stage(self, stage: str) -> Dict:
        """
        Отримати інформацію про стадію раку

        Args:
            stage: стадія ('stage_0', 'stage_I', 'stage_II', 'stage_III', 'stage_IV')

        Returns:
            Dict з інформацією про стадію

        Example:
            >>> stage_info = terminology.get_cancer_stage('stage_II')
            >>> print(stage_info['uk'])
            'стадія II'
        """
        stages = self.terminology.get('Cancer_Stages', {})
        return stages.get(stage, {'uk': 'Не визначено', 'description': '', 'prognosis': ''})

    def get_all_anatomic_locations(self) -> List[Dict]:
        """
        Отримати список всіх анатомічних локалізацій з повною інформацією

        Returns:
            List[Dict] всіх органів

        Example:
            >>> locations = terminology.get_all_anatomic_locations()
            >>> for loc in locations:
            ...     print(f"{loc['index']}: {loc['official']} ({loc['latin']})")
        """
        result = []
        anatomic_data = self.terminology.get('Anatomic_Ukrainian_Official', {})

        for index in range(19):  # 0-18
            if index in anatomic_data:
                data = anatomic_data[index].copy()
                data['index'] = index
                result.append(data)

        return result

    def print_anatomic_reference_table(self):
        """
        Вивести довідкову таблицю всіх анатомічних локалізацій

        Example:
            >>> terminology.print_anatomic_reference_table()
        """
        print("\n" + "=" * 100)
        print("ДОВІДКОВА ТАБЛИЦЯ АНАТОМІЧНИХ ЛОКАЛІЗАЦІЙ")
        print("=" * 100)
        print(f"{'№':<4} {'Українська назва':<25} {'Латинська назва':<35} {'МКХ-11':<10}")
        print("-" * 100)

        locations = self.get_all_anatomic_locations()
        for loc in locations:
            print(f"{loc['index']:<4} {loc['official']:<25} {loc['latin']:<35} {loc['icd11']:<10}")

        print("=" * 100 + "\n")

    def get_abbreviation(self, abbr: str, category: str = 'medical') -> str:
        """
        Розшифрувати медичне скорочення

        Args:
            abbr: скорочення
            category: категорія ('medical' або 'technical')

        Returns:
            Розшифровка скорочення

        Example:
            >>> full = terminology.get_abbreviation('МКХ')
            >>> print(full)
            'Міжнародна класифікація хвороб'
        """
        abbreviations = self.terminology.get('Abbreviations', {})
        return abbreviations.get(category, {}).get(abbr, abbr)

    def validate_for_certification(self) -> Dict:
        """
        Перевірити відповідність термінології вимогам сертифікації

        Returns:
            Dict з результатами перевірки

        Example:
            >>> validation = terminology.validate_for_certification()
            >>> print(validation['compliant'])
            True
        """
        cert = self.terminology.get('Certification', {})

        checks = {
            'has_moh_standards': 'regulatory' in cert,
            'has_quality_standards': 'quality_standards' in cert,
            'has_intended_use': 'intended_use' in cert,
            'has_icd11_codes': bool(self.terminology.get('Cancer_Types_ICD11')),
            'has_tnm_staging': bool(self.terminology.get('TNM_Staging')),
        }

        return {
            'compliant': all(checks.values()),
            'checks': checks,
            'regulatory_body': cert.get('regulatory', {}).get('ukraine', {}).get('body', 'N/A')
        }

    def _get_current_date(self) -> str:
        """Отримати поточну дату у форматі ДД.МЛ.РРРР"""
        from datetime import datetime
        return datetime.now().strftime("%d.%m.%Y")

    def export_terminology_summary(self, output_file: str = "terminology_summary.txt"):
        """
        Експортувати зведення термінології у текстовий файл

        Args:
            output_file: шлях до файлу для збереження

        Example:
            >>> terminology.export_terminology_summary("summary.txt")
        """
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("ЗВЕДЕННЯ УКРАЇНСЬКОЇ МЕДИЧНОЇ ТЕРМІНОЛОГІЇ CHIEF\n")
            f.write("=" * 80 + "\n\n")

            # Метадані
            metadata = self.terminology.get('Metadata', {})
            f.write("МЕТАДАНІ:\n")
            for key, value in metadata.items():
                f.write(f"  {key}: {value}\n")
            f.write("\n")

            # Анатомічні локалізації
            f.write("АНАТОМІЧНІ ЛОКАЛІЗАЦІЇ:\n")
            locations = self.get_all_anatomic_locations()
            for loc in locations:
                f.write(f"\n{loc['index']}. {loc['official'].upper()}\n")
                f.write(f"   Латинська: {loc['latin']}\n")
                f.write(f"   Топографія: {loc['topography']}\n")
                f.write(f"   МКХ-11: {loc['icd11']}\n")

            # Гістологічні типи
            f.write("\n" + "=" * 80 + "\n")
            f.write("ГІСТОЛОГІЧНІ ТИПИ:\n\n")
            hist_types = self.terminology.get('Histological_Types', {})
            for key, data in hist_types.items():
                f.write(f"  {data['uk']} ({data['lat']}) - SNOMED: {data['snomed']}\n")

            # TNM класифікація
            f.write("\n" + "=" * 80 + "\n")
            f.write("TNM КЛАСИФІКАЦІЯ:\n\n")
            tnm = self.terminology.get('TNM_Staging', {})
            for component, data in tnm.items():
                f.write(f"{component} - {data['name']}:\n")
                for value, description in data.get('values', {}).items():
                    f.write(f"  {value}: {description}\n")
                f.write("\n")

        print(f"Зведення термінології збережено у файлі: {output_file}")


def demo():
    """Демонстрація роботи модуля"""

    print("\n" + "=" * 80)
    print("ДЕМОНСТРАЦІЯ УКРАЇНСЬКОЇ МЕДИЧНОЇ ТЕРМІНОЛОГІЇ CHIEF")
    print("=" * 80 + "\n")

    # Ініціалізація
    term = UkrainianMedicalTerminology()

    # 1. Довідкова таблиця
    term.print_anatomic_reference_table()

    # 2. Детальна інформація про орган
    print("\n--- Детальна інформація про легеню ---")
    lung_info = term.get_anatomic_term(6, 'uk')
    print(f"Офіційна назва: {lung_info['official']}")
    print(f"Латинська назва: {lung_info['latin']}")
    print(f"Синоніми: {', '.join(lung_info['synonyms'])}")
    print(f"МКХ-11: {lung_info['icd11']}")
    print(f"Топографія: {lung_info['topography']}")

    # 3. МКХ-11 код
    print("\n--- МКХ-11 коди ---")
    icd_code = term.get_icd11_code('lung')
    print(f"Код для раку легені: {icd_code}")

    # 4. TNM пояснення
    print("\n--- TNM класифікація ---")
    tnm_t2 = term.get_tnm_explanation('T2')
    print(f"T2: {tnm_t2['description']}")

    # 5. Приклад повного звіту
    print("\n--- ПРИКЛАД МЕДИЧНОГО ЗВІТУ ---")
    report = term.format_diagnosis_report(
        anatomic_index=6,  # Легеня
        diagnosis_type='malignant',
        confidence=0.87,
        histology='adenocarcinoma',
        grade='G2',
        tnm={'T': 'T2', 'N': 'N1', 'M': 'M0'}
    )
    print(report)

    # 6. Валідація сертифікації
    print("\n--- ВАЛІДАЦІЯ СЕРТИФІКАЦІЇ ---")
    validation = term.validate_for_certification()
    print(f"Відповідає вимогам: {validation['compliant']}")
    print(f"Регуляторний орган: {validation['regulatory_body']}")

    # 7. Експорт зведення
    print("\n--- ЕКСПОРТ ЗВЕДЕННЯ ---")
    term.export_terminology_summary("terminology_summary_demo.txt")


if __name__ == "__main__":
    demo()
