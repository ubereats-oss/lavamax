import json
import csv

INPUT_JSON = "carros_marcas_modelos.json"
OUTPUT_CSV = "carros_marcas_modelos.csv"

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    rows = []
    for item in data:
        brand = (item.get("brand") or "").strip()
        model = (item.get("model") or "").strip()
        if brand and model:
            rows.append((brand, model))

    rows = sorted(set(rows), key=lambda x: (x[0].lower(), x[1].lower()))

    with open(OUTPUT_CSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["brand", "model"])
        for brand, model in rows:
            writer.writerow([brand, model])

    print("✅ CSV gerado:", OUTPUT_CSV)
    print("Total linhas:", len(rows))

if __name__ == "__main__":
    main()