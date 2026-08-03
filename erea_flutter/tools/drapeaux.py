#!/usr/bin/env python3
"""Génère lib/data/drapeaux.dart : le drapeau de chaque pays jouable.

Un drapeau emoji n'est pas un caractère : c'est une paire d'« indicateurs
régionaux », un par lettre du code ISO du pays. 🇫🇷 s'écrit donc F+R en
indicateurs régionaux. On peut ainsi les calculer au lieu de les recopier,
ce qui évite les coquilles invisibles à l'œil nu.

Le script échoue si un pays de la base n'est pas dans la table : mieux
vaut une erreur bruyante qu'un drapeau blanc dans la roulette.

    python3 tools/drapeaux.py
"""
import collections
import json
import os
import sys
import unicodedata

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'assets', 'events.json')
SORTIE = os.path.join(RACINE, 'lib', 'data', 'drapeaux.dart')

# Nom français → code ISO 3166-1 alpha-2. Volontairement plus large que
# la base actuelle : le reclassement en ajoute, et une table trop courte
# ferait échouer la génération à chaque nouveau pays.
ISO = {
    'Afghanistan': 'AF', 'Afrique du Sud': 'ZA', 'Albanie': 'AL',
    'Algérie': 'DZ', 'Allemagne': 'DE', 'Angola': 'AO',
    'Arabie saoudite': 'SA', 'Argentine': 'AR', 'Arménie': 'AM',
    'Australie': 'AU', 'Autriche': 'AT', 'Azerbaïdjan': 'AZ',
    'Bahreïn': 'BH', 'Bangladesh': 'BD', 'Belgique': 'BE', 'Bénin': 'BJ',
    'Biélorussie': 'BY', 'Birmanie': 'MM', 'Bolivie': 'BO',
    'Bosnie-Herzégovine': 'BA', 'Botswana': 'BW', 'Brésil': 'BR',
    'Bulgarie': 'BG', 'Burkina Faso': 'BF', 'Burundi': 'BI',
    'Côte d’Ivoire': 'CI',
    'Cambodge': 'KH', 'Cameroun': 'CM', 'Canada': 'CA', 'Chili': 'CL',
    'Chine': 'CN', 'Chypre': 'CY', 'Colombie': 'CO', 'Comores': 'KM',
    'Congo': 'CG', 'Corée du Nord': 'KP', 'Corée du Sud': 'KR',
    'Costa Rica': 'CR', "Côte d'Ivoire": 'CI', 'Croatie': 'HR',
    'Cuba': 'CU', 'Danemark': 'DK', 'Djibouti': 'DJ', 'Égypte': 'EG',
    'Émirats arabes unis': 'AE', 'Équateur': 'EC', 'Érythrée': 'ER',
    'Espagne': 'ES', 'Estonie': 'EE', 'Eswatini': 'SZ',
    'États-Unis': 'US', 'Éthiopie': 'ET', 'Fidji': 'FJ',
    'Finlande': 'FI', 'France': 'FR', 'Gabon': 'GA', 'Gambie': 'GM',
    'Géorgie': 'GE', 'Ghana': 'GH', 'Grèce': 'GR', 'Guatemala': 'GT',
    'Guinée': 'GN', 'Haïti': 'HT', 'Honduras': 'HN', 'Hongrie': 'HU',
    'Îles Cook': 'CK', 'Îles Marshall': 'MH', 'Îles Salomon': 'SB',
    'Inde': 'IN', 'Indonésie': 'ID', 'Irak': 'IQ', 'Iran': 'IR',
    'Irlande': 'IE', 'Islande': 'IS', 'Israël': 'IL', 'Italie': 'IT',
    'Jamaïque': 'JM', 'Japon': 'JP', 'Jordanie': 'JO',
    'Kazakhstan': 'KZ', 'Kenya': 'KE', 'Kirghizistan': 'KG',
    'Koweït': 'KW', 'Laos': 'LA', 'Lettonie': 'LV', 'Liban': 'LB',
    'Liberia': 'LR', 'Libye': 'LY', 'Lituanie': 'LT',
    'Luxembourg': 'LU', 'Madagascar': 'MG', 'Malaisie': 'MY',
    'Malawi': 'MW', 'Mali': 'ML', 'Malte': 'MT', 'Maroc': 'MA',
    'Maurice': 'MU', 'Mauritanie': 'MR', 'Mexique': 'MX',
    'Micronésie': 'FM', 'Moldavie': 'MD', 'Mongolie': 'MN',
    'Monténégro': 'ME', 'Mozambique': 'MZ', 'Namibie': 'NA',
    'Népal': 'NP', 'Nicaragua': 'NI', 'Niger': 'NE', 'Nigeria': 'NG',
    'Norvège': 'NO', 'Nouvelle-Zélande': 'NZ', 'Oman': 'OM',
    'Ouganda': 'UG', 'Ouzbékistan': 'UZ', 'Pakistan': 'PK',
    'Palestine': 'PS', 'Panama': 'PA',
    'Papouasie-Nouvelle-Guinée': 'PG', 'Paraguay': 'PY',
    'Pays-Bas': 'NL', 'Pérou': 'PE', 'Philippines': 'PH',
    'Pologne': 'PL', 'Portugal': 'PT', 'Qatar': 'QA',
    'République démocratique du Congo': 'CD',
    'République dominicaine': 'DO', 'République tchèque': 'CZ',
    'Roumanie': 'RO', 'Royaume-Uni': 'GB', 'Russie': 'RU',
    'Rwanda': 'RW', 'Salvador': 'SV', 'Samoa': 'WS', 'Sénégal': 'SN',
    'Serbie': 'RS', 'Sierra Leone': 'SL', 'Singapour': 'SG',
    'Slovaquie': 'SK', 'Slovénie': 'SI', 'Somalie': 'SO',
    'Soudan': 'SD', 'Soudan du Sud': 'SS', 'Sri Lanka': 'LK',
    'Suède': 'SE', 'Suisse': 'CH', 'Syrie': 'SY', 'Tanzanie': 'TZ',
    'Tchad': 'TD', 'Thaïlande': 'TH', 'Timor oriental': 'TL',
    'Togo': 'TG', 'Tonga': 'TO', 'Tunisie': 'TN',
    'Turkménistan': 'TM', 'Turquie': 'TR', 'Ukraine': 'UA',
    'Uruguay': 'UY', 'Vatican': 'VA', 'Vanuatu': 'VU', 'Venezuela': 'VE',
    'Vietnam': 'VN', 'Yémen': 'YE', 'Zambie': 'ZM', 'Zimbabwe': 'ZW',
}


def drapeau(code):
    """Deux indicateurs régionaux, calculés depuis le code ISO."""
    return ''.join(chr(0x1F1E6 + ord(c) - ord('A')) for c in code)


def main():
    with open(BASE, encoding='utf-8') as f:
        ev = json.load(f)
    presents = collections.Counter(
        e['pays'] for e in ev if e.get('pays'))

    inconnus = sorted(p for p in presents if p not in ISO)
    if inconnus:
        print('Pays absents de la table ISO :', file=sys.stderr)
        for p in inconnus:
            print(f'  « {p} » ({presents[p]} faits)', file=sys.stderr)
        raise SystemExit(1)

    lignes = [
        "// Fichier GÉNÉRÉ par tools/drapeaux.py — ne pas modifier à la main.",
        "//",
        "// Un drapeau emoji est une paire d'« indicateurs régionaux », un par",
        "// lettre du code ISO du pays : 🇫🇷 s'écrit F + R. Les recopier à la",
        "// main invite la coquille invisible, d'où cette génération.",
        '',
        'const Map<String, String> drapeaux = {',
    ]
    for pays in sorted(presents, key=lambda p: unicodedata.normalize('NFD', p)):
        lignes.append(f"  '{pays}': '{drapeau(ISO[pays])}',")
    lignes += [
        '};',
        '',
        '/// Le drapeau du pays, ou un globe si on ne le connaît pas — jamais',
        '/// de case vide dans la roulette.',
        "String drapeauDe(String pays) => drapeaux[pays] ?? '🌍';",
        '',
    ]
    with open(SORTIE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lignes))
    print(f'{len(presents)} drapeaux écrits dans {SORTIE}')


if __name__ == '__main__':
    main()
