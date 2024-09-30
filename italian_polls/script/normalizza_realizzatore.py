import pandas as pd
import unicodedata
from rapidfuzz import process, fuzz  # Import corretto di fuzz
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
def cluster_by_key_collision(df, column, threshold=90, fuzzy_threshold=85):
    # Crea una copia temporanea della colonna e la trasformiamo in lowercase senza modificare quella originale
    temp_column = df[column].str.lower()

    # Crea una nuova colonna con i fingerprint
    df['fingerprint'] = temp_column.apply(fingerprint)

    unique_fingerprints = df['fingerprint'].unique()

    clusters = {}
    for fp in unique_fingerprints:
        # Trova valori con fingerprint simili
        matches = process.extract(fp, unique_fingerprints, scorer=fuzz.ratio, score_cutoff=fuzzy_threshold)

        # Unisci i valori che si trovano entro la soglia
        cluster_values = df[df['fingerprint'].isin([match[0] for match in matches])][column].value_counts()

        # Verifica se il cluster contiene valori validi
        if not cluster_values.empty:
            representative_value = cluster_values.idxmax()  # Prendi il valore più frequente
            # Assegna tutti i valori del cluster al rappresentante scelto
            for value in cluster_values.index:
                clusters[value] = representative_value

    # Aggiungi una colonna realizzatore_normalizzato senza alterare quella originale
    df['realizzatore_normalizzato'] = df[column].replace(clusters)

    # Rimuovi la colonna fingerprint prima di salvare
    df = df.drop(columns=['fingerprint'])

    # Ritorna il DataFrame con la nuova colonna
    return df

# Funzione per caricare il file JSONL e preservare i caratteri Unicode
def read_jsonl(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = [json.loads(line) for line in f]
    return pd.DataFrame(data)

# Funzione per salvare il file JSONL mantenendo i caratteri accentati e gli a capo
def write_jsonl(file_path, df):
    with open(file_path, 'w', encoding='utf-8') as f:
        for record in df.to_dict(orient='records'):
            json.dump(record, f, ensure_ascii=False)  # ensure_ascii=False mantiene i caratteri accentati
            f.write('\n')  # Mantieni gli a capo

# Leggi il file JSONL
input_file_path = '../data/anagrafica.jsonl'
df_input = read_jsonl(input_file_path)

# Applica la funzione di clustering automatico alla colonna 'realizzatore' senza modificarla
df_cleaned = cluster_by_key_collision(df_input, 'realizzatore', threshold=90, fuzzy_threshold=85)

# Sovrascrivi il file JSONL di input con la nuova colonna realizzatore_normalizzato
write_jsonl(input_file_path, df_cleaned)
