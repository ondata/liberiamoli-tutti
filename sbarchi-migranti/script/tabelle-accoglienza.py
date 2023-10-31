import argparse
import os
import tabula

# Creazione del parser degli argomenti
parser = argparse.ArgumentParser(description='Estrai la prima tabella da un file PDF e salvala in un file CSV.')
parser.add_argument('input_file', help='Il nome del file PDF di input')
parser.add_argument('page', type=int, help='Il numero della pagina da cui estrarre la tabella')

# Parsing degli argomenti
args = parser.parse_args()

# Estrazione delle tabelle dal file PDF specificato
tables = tabula.read_pdf(args.input_file, pages=args.page, pandas_options={'dtype': str})

# Estrazione della prima tabella (se presente)
if len(tables) > 0:
    table = tables[0]
    output_file = os.path.splitext(args.input_file)[0] + '-accoglienza.csv'
    table.to_csv(output_file, index=False)
    print(f"Prima tabella estratta e salvata come {output_file}")
else:
    print("Nessuna tabella trovata nel file PDF specificato.")
