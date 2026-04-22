import json
import csv

INPUT_JSON = "carros_marcas_modelos.json"
OUT_CSV = "carros_modelos_limpados_com_exemplo.csv"

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    # key: (brand, model_clean) -> example_original
    first_example = {}

    for item in data:
        brand = (item.get("brand") or "").strip()
        model_original = (item.get("model") or "").strip()

        if not brand or not model_original:
            continue

        model_clean = model_original.split()[0]
        key = (brand, model_clean)

        # guarda o primeiro exemplo que aparecer
        if key not in first_example:
            first_example[key] = model_original

    rows = [(b, m, ex) for (b, m), ex in first_example.items()]
    rows.sort(key=lambda x: (x[0].lower(), x[1].lower(), x[2].lower()))

    with open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model_clean", "example_original"])
        for brand, model_clean, example_original in rows:
            w.writerow([brand, model_clean, example_original])

    print("✅ Gerado:", OUT_CSV)
    print("Total linhas (deduplicado):", len(rows))

if __name__ == "__main__":
    main()