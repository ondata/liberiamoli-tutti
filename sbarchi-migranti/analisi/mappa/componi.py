"""Mappa finale: titolo, sottotitolo, legenda e fonte attorno alla mappa di mapshaper."""
import re
from pathlib import Path

mappa = Path("mappa_base.svg").read_text(encoding="utf-8")
w, h = [float(x) for x in re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', mappa).groups()]
interno = mappa[mappa.index(">", mappa.index("<svg")) + 1 : mappa.rindex("</svg>")]
# etichette: testo scuro con alone chiaro, leggibile su ogni riempimento
interno = re.sub(r'(<text[^>]*?)stroke-width="[\d.]+"', r'\1stroke-width="3.5" paint-order="stroke" stroke-linejoin="round"', interno)

SUP, T1, T2 = "#fcfcfb", "#0b0b0b", "#52514e"
alto, basso = 150, 80
H = alto + h + basso
colori = Path("colori.txt").read_text().strip().split(",")
classi = list(zip(colori, ["meno di 20", "20 - 50", "50 - 100", "100 - 200", "oltre 200"])) + [("#e6e5e1", "nazionalità non elencata")]
legenda, x = [], 30
for colore, testo in classi:
    legenda.append(f'<rect x="{x}" y="112" width="16" height="16" rx="3" fill="{colore}"/><text x="{x + 22}" y="125" font-size="13" fill="{T1}">{testo}</text>')
    x += 22 + 8 * len(testo) + 26
# riquadro nello spazio libero in basso a destra: quota di sbarcati con nazionalità attribuita
import csv
naz = [r for r in csv.DictReader(open("../../dati/nazionalita.csv", encoding="utf-8")) if r["Data_Report"] == "2025-12-31"]
totale = sum(int(r["Valore"]) for r in naz)
altre = sum(int(r["Valore"]) for r in naz if r["Nazione"] == "altre")
elencate = totale - altre
punto = lambda v: f"{v:,}".replace(",", ".")
pct = lambda v: f"{100 * v / totale:.1f}".replace(".", ",")
bx, by, bw, bh = 730, alto + h - 150, 340, 24
we = bw * elencate / totale
riquadro = f'''<g font-size="12" fill="{T1}">
<text x="{bx}" y="{by - 34}" font-size="13" font-weight="bold">Quanti sbarcati hanno un paese d'origine</text>
<text x="{bx}" y="{by - 15}" fill="{T2}">Totale 2025: {punto(totale)} persone</text>
<rect x="{bx}" y="{by}" width="{we - 1:.1f}" height="{bh}" rx="4" fill="#52514e"/>
<rect x="{bx + we + 1:.1f}" y="{by}" width="{bw - we - 1:.1f}" height="{bh}" rx="4" fill="#e6e5e1"/>
<text x="{bx}" y="{by + bh + 20}"><tspan font-weight="bold">{pct(elencate)}%</tspan> nazionalità elencata ({punto(elencate)})</text>
<text x="{bx + bw}" y="{by + bh + 40}" text-anchor="end"><tspan font-weight="bold">{pct(altre)}%</tspan> "altre", non attribuibili ({punto(altre)})</text>
</g>'''

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{H:.0f}" viewBox="0 0 {w:.0f} {H:.0f}" font-family="DejaVu Sans">
<rect width="100%" height="100%" fill="{SUP}"/>
<text x="30" y="40" font-size="22" font-weight="bold" fill="{T1}">Migranti sbarcati in Italia nel 2025, per milione di abitanti del paese d'origine</text>
<text x="30" y="70" font-size="14" fill="{T2}">In valore assoluto il primo paese è il Bangladesh (20.164 persone); in rapporto alla popolazione è l'Eritrea,</text>
<text x="30" y="90" font-size="14" fill="{T2}">con 2.101 sbarcati per milione di abitanti, quasi dodici volte la Somalia (176), seconda.</text>
{"".join(legenda)}
<g transform="translate(0 {alto})">{interno}</g>
{riquadro}
<text x="30" y="{alto + h + 24}" font-size="11" fill="{T2}">Sbarcati: nazionalità dichiarate allo sbarco, anno 2025 (report del 31/12/2025). Il PDF elenca solo le 15 nazionalità principali; le altre (6,9%) non sono attribuibili a un paese.</text>
<text x="30" y="{alto + h + 42}" font-size="11" fill="{T2}">Popolazione: Banca Mondiale, World Development Indicators (SP.POP.TOTL), 2025. Somalia comprende il Somaliland. Fonte sbarchi: Ministero dell'Interno, Cruscotto statistico giornaliero.</text>
<text x="30" y="{alto + h + 58}" font-size="11" fill="{T2}">Le stime della popolazione dell'Eritrea variano molto fra le fonti (3,6 milioni Banca Mondiale, 6,1 milioni nella stima di Natural Earth): con la seconda il valore sarebbe circa 1.250.</text>
<text x="30" y="{alto + h + 74}" font-size="11" fill="{T2}">Confini: Natural Earth. Proiezione azimutale equivalente di Lambert. Elaborazione: Liberiamoli tutti! (CC-BY 4.0)</text>
</svg>
'''
Path("sbarchi_per_milione_2025.svg").write_text(svg, encoding="utf-8")
print("ok", w, H)
