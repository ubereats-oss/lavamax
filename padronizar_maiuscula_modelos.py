import csv

INPUT_CSV = "carros_modelos_final.csv"
OUT_CSV = "carros_modelos_final_padronizado.csv"

ENCODINGS_TO_TRY = ["utf-8-sig", "cp1252", "latin-1"]

def cap_first(s: str) -> str:
    s = (s or "").strip()
    if not s:
        return ""
    s_low = s.lower()
    return s_low[0].upper() + s_low[1:]

def read_rows(path: str):
    last_err = None
    for enc in ENCODINGS_TO_TRY:
        try:
            with open(path, "r", encoding=enc, newline="") as f:
                sample = f.read(4096)
                f.seek(0)

                # detecta delimitador simples (; ou ,)
                delimiter = ";" if sample.count(";") >= sample.count(",") else ","

                reader = csv.DictReader(f, delimiter=delimiter)
                rows = list(reader)
                return rows, reader.fieldnames or [], delimiter, enc
        except UnicodeDecodeError as e:
            last_err = e
    raise RuntimeError(f"Não consegui ler o CSV com {ENCODINGS_TO_TRY}. Último erro: {last_err}")

def main():
    rows, fieldnames, delimiter, used_enc = read_rows(INPUT_CSV)

    # normaliza nomes de colunas (tira espaços)
    norm = { (fn or "").strip(): fn for fn in fieldnames }
    # pega nomes reais do arquivo
    brand_col = norm.get("brand")
    model_col = norm.get("model_clean") or norm.get("model")  # fallback

    if not brand_col or not model_col:
        raise RuntimeError(f"Colunas não encontradas. Achei: {fieldnames}")

    out_rows = []
    for r in rows:
        brand = cap_first(r.get(brand_col, ""))
        model = cap_first(r.get(model_col, ""))
        out_rows.append({"brand": brand, "model_clean": model})

    with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["brand", "model_clean"], delimiter=delimiter)
        w.writeheader()
        w.writerows(out_rows)

    print("✅ Lido com encoding:", used_enc)
    print("✅ Delimitador:", repr(delimiter))
    print("✅ Gerado:", OUT_CSV)
    print("Total linhas:", len(out_rows))

if __name__ == "__main__":
    main()