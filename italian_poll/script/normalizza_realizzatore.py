import pandas as pd
import unicodedata
from rapidfuzz import process
import json

# Funzione migliorata di fingerprint: normalizza e pulisce la stringa
def fingerprint(text):
    # Rimuovi accenti
    text = ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    # Trasforma tutto in minuscolo, rimuovi spazi e caratteri speciali
    text = text.lower().replace('.', '').replace(',', '').replace('&', '').replace(' ', '')
    # Riordina alfabeticamente i caratteri
    text = ''.join(sorted(text))
    return text

# Funzione per trovare e unire cluster basati su fingerprint e soglia fuzzy
def cluster_by_key_collision(df, column, threshold=90):
    # Crea una nuova colonna con i fingerprint
    df['fingerprint'] = df[column].apply(fingerprint)

    unique_fingerprints = df['fingerprint'].unique()

    clusters = {}
    for fp in unique_fingerprints:
        # Trova valori con fingerprint simili
        matches = process.extract(fp, unique_fingerprints, score_cutoff=threshold)

        # Unisci i valori che si trovano entro la soglia
        if matches:
            cluster_values = df[df['fingerprint'] == fp][column].unique()
            representative_value = cluster_values[0]  # Prendi il primo valore come rappresentante
            for value in cluster_values:
                clusters[value] = representative_value

    # Aggiungi una colonna realizzatore_normalizzato senza alterare quella originale
    df['realizzatore_normalizzato'] = df[column].replace(clusters)

    # Rimuovi la colonna fingerprint prima di salvare
    df = df.drop(columns=['fingerprint'])

    # Ritorna il DataFrame con la nuova colonna
    return df

# Leggi il file JSONL
input_file_path = '../data/italian_polls_metadata.jsonl'
data = []

# Carica il file JSONL come lista di dizionari
with open(input_file_path, 'r', encoding='utf-8') as f:
    for line in f:
        data.append(json.loads(line))

# Converti la lista di dizionari in un DataFrame
df_input = pd.DataFrame(data)

# Applica la funzione di clustering automatico alla colonna 'realizzatore'
df_cleaned = cluster_by_key_collision(df_input, 'realizzatore', threshold=85)

# Salva i risultati in un nuovo file JSONL
output_file_path = '../data/italian_polls_metadata.jsonl'
with open(output_file_path, 'w', encoding='utf-8') as f:
    for record in df_cleaned.to_dict(orient='records'):
        f.write(json.dumps(record) + '\n')
