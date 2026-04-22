import json
import csv

INPUT_JSON = "carros_marcas_modelos.json"
OUT_CSV = "carros_modelos_primeira_palavra_com_original.csv"

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    rows = []

    for item in data:
        brand = (item.get("brand") or "").strip()
        model_original = (item.get("model") or "").strip()

        if not brand or not model_original:
            continue

        primeira_palavra = model_original.split()[0]

        rows.append((brand, model_original, primeira_palavra))

    # ordenar para facilitar leitura
    rows.sort(key=lambda x: (x[0].lower(), x[2].lower(), x[1].lower()))

    with open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model_original", "model_primeira_palavra"])
        for row in rows:
            w.writerow(row)

    print("✅ Gerado:", OUT_CSV)
    print("Total linhas:", len(rows))

if __name__ == "__main__":
    main()