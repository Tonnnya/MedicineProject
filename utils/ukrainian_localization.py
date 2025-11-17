#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Модуль української локалізації для CHIEF
Ukrainian Localization Module for CHIEF

Цей модуль надає функціонал для перекладу медичних термінів
та анатомічних локалізацій на українську мову.

This module provides functionality for translating medical terms
and anatomical locations to Ukrainian language.
"""

import yaml
from typing import Dict, Optional


class UkrainianLocalization:
    """Клас для української локалізації CHIEF"""

    def __init__(self, config_path: str = "./configs/anatomic_mapping_uk.yaml"):
        """
        Ініціалізація модуля локалізації

        Args:
            config_path: шлях до конфігураційного файлу з перекладами
        """
        self.config_path = config_path
        self.translations = self._load_translations()

    def _load_translations(self) -> Dict:
        """
        Завантаження перекладів з YAML файлу

        Returns:
            Dict: словник з перекладами
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            return data
        except FileNotFoundError:
            print(f"Попередження: Файл {self.config_path} не знайдено.")
            print("Використовуються базові переклади.")
            return self._get_default_translations()

    def _get_default_translations(self) -> Dict:
        """
        Отримання базових перекладів (якщо файл не знайдено)

        Returns:
            Dict: базовий словник перекладів
        """
        return {
            'Anatomic': {
                'brain': 0,
                'breast': 1,
                'bladder': 2,
                'kidney': 3,
                'prostate': 4,
                'testis': 5,
                'lung': 6,
                'pancreas': 7,
                'liver': 8,
                'skin': 9,
                'ovary': 10,
                'cervix': 11,
                'uterus': 12,
                'colon': 13,
                'esophagus': 14,
                'stomach': 15,
                'thyroid': 16,
                'adrenal gland': 17,
                'soft tissue': 18
            },
            'Anatomic_Ukrainian': {
                'головний мозок': 0,
                'молочна залоза': 1,
                'сечовий міхур': 2,
                'нирка': 3,
                'передміхурова залоза': 4,
                'яєчко': 5,
                'легеня': 6,
                'підшлункова залоза': 7,
                'печінка': 8,
                'шкіра': 9,
                'яєчник': 10,
                'шийка матки': 11,
                'матка': 12,
                'товста кишка': 13,
                'стравохід': 14,
                'шлунок': 15,
                'щитоподібна залоза': 16,
                'надниркова залоза': 17,
                'м\'які тканини': 18
            }
        }

    def get_anatomic_index(self, organ_name: str, language: str = 'uk') -> Optional[int]:
        """
        Отримання індексу анатомічного органу

        Args:
            organ_name: назва органу (українською або англійською)
            language: мова ('uk' або 'en')

        Returns:
            Optional[int]: індекс органу або None якщо не знайдено
        """
        if language == 'uk':
            return self.translations.get('Anatomic_Ukrainian', {}).get(organ_name.lower())
        else:
            return self.translations.get('Anatomic', {}).get(organ_name.lower())

    def get_organ_name(self, index: int, language: str = 'uk') -> Optional[str]:
        """
        Отримання назви органу за індексом

        Args:
            index: індекс органу (0-18)
            language: мова ('uk' або 'en')

        Returns:
            Optional[str]: назва органу або None якщо не знайдено
        """
        mapping_key = 'Anatomic_Ukrainian' if language == 'uk' else 'Anatomic'
        mapping = self.translations.get(mapping_key, {})

        for organ, idx in mapping.items():
            if idx == index:
                return organ

        return None

    def translate_medical_term(self, term: str, to_language: str = 'uk') -> str:
        """
        Переклад медичного терміну

        Args:
            term: термін для перекладу
            to_language: цільова мова ('uk' або 'en')

        Returns:
            str: перекладений термін або оригінал якщо переклад не знайдено
        """
        medical_terms = self.translations.get('Medical_Terms_Mapping', {})

        if to_language == 'uk':
            # Переклад з англійської на українську
            return medical_terms.get(term, term)
        else:
            # Переклад з української на англійську
            for en_term, uk_term in medical_terms.items():
                if uk_term == term:
                    return en_term
            return term

    def format_diagnosis(self, organ: str, diagnosis: str, confidence: float,
                        language: str = 'uk') -> str:
        """
        Форматування діагнозу для звіту

        Args:
            organ: анатомічна локалізація
            diagnosis: діагноз
            confidence: впевненість моделі (0-1)
            language: мова звіту ('uk' або 'en')

        Returns:
            str: відформатований діагноз
        """
        if language == 'uk':
            confidence_text = self._get_confidence_text_uk(confidence)
            return f"""
РЕЗУЛЬТАТИ АВТОМАТИЗОВАНОГО АНАЛІЗУ

Анатомічна локалізація: {organ}
Висновок: {diagnosis}
Впевненість моделі: {confidence:.1%} ({confidence_text})

УВАГА: Це попередній висновок автоматизованої системи.
Остаточний діагноз має бути встановлений кваліфікованим патологоанатомом.
            """
        else:
            confidence_text = self._get_confidence_text_en(confidence)
            return f"""
AUTOMATED ANALYSIS RESULTS

Anatomical Location: {organ}
Conclusion: {diagnosis}
Model Confidence: {confidence:.1%} ({confidence_text})

WARNING: This is a preliminary conclusion from an automated system.
Final diagnosis must be established by a qualified pathologist.
            """

    def _get_confidence_text_uk(self, confidence: float) -> str:
        """Отримання текстового опису впевненості українською"""
        if confidence >= 0.9:
            return "дуже висока"
        elif confidence >= 0.7:
            return "висока"
        elif confidence >= 0.5:
            return "помірна"
        else:
            return "низька"

    def _get_confidence_text_en(self, confidence: float) -> str:
        """Отримання текстового опису впевненості англійською"""
        if confidence >= 0.9:
            return "very high"
        elif confidence >= 0.7:
            return "high"
        elif confidence >= 0.5:
            return "moderate"
        else:
            return "low"

    def get_all_organs(self, language: str = 'uk') -> Dict[str, int]:
        """
        Отримання всіх доступних органів

        Args:
            language: мова ('uk' або 'en')

        Returns:
            Dict[str, int]: словник {назва_органу: індекс}
        """
        mapping_key = 'Anatomic_Ukrainian' if language == 'uk' else 'Anatomic'
        return self.translations.get(mapping_key, {})

    def print_all_organs(self, language: str = 'uk'):
        """
        Виведення всіх доступних органів

        Args:
            language: мова ('uk' або 'en')
        """
        organs = self.get_all_organs(language)

        if language == 'uk':
            print("\n=== ДОСТУПНІ АНАТОМІЧНІ ЛОКАЛІЗАЦІЇ ===\n")
        else:
            print("\n=== AVAILABLE ANATOMICAL LOCATIONS ===\n")

        for organ, index in sorted(organs.items(), key=lambda x: x[1]):
            print(f"{index:2d}. {organ}")

        print()


def demo():
    """Демонстрація роботи модуля локалізації"""

    print("=" * 60)
    print("Демонстрація української локалізації CHIEF")
    print("=" * 60)

    # Ініціалізація
    loc = UkrainianLocalization()

    # Виведення всіх органів українською
    loc.print_all_organs(language='uk')

    # Приклади використання
    print("\n--- Приклади використання ---\n")

    # Отримання індексу
    organ_uk = "товста кишка"
    index = loc.get_anatomic_index(organ_uk, language='uk')
    print(f"Індекс для '{organ_uk}': {index}")

    # Отримання назви за індексом
    organ_name = loc.get_organ_name(13, language='uk')
    print(f"Орган з індексом 13: {organ_name}")

    # Переклад медичного терміну
    term = "colon_cancer"
    translated = loc.translate_medical_term(term, to_language='uk')
    print(f"Переклад '{term}': {translated}")

    # Форматування діагнозу
    print("\n--- Приклад звіту ---")
    diagnosis = loc.format_diagnosis(
        organ="товста кишка",
        diagnosis="Виявлено ознаки злоякісної пухлини",
        confidence=0.87,
        language='uk'
    )
    print(diagnosis)

    print("\n--- Тестування всіх органів ---\n")
    all_organs = loc.get_all_organs(language='uk')
    for organ_name, organ_idx in list(all_organs.items())[:5]:
        en_name = loc.get_organ_name(organ_idx, language='en')
        print(f"{organ_idx}: {organ_name} ({en_name})")


if __name__ == "__main__":
    demo()
