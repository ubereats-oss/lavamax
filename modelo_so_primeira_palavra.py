import json
import csv

INPUT_JSON = "carros_marcas_modelos.json"
OUT_CSV = "carros_modelos_primeira_palavra.csv"
OUT_MAP = "carros_modelos_primeira_palavra_map.csv"

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    cleaned_set = set()
    mapped = []

    for item in data:
        brand = (item.get("brand") or "").strip()
        model = (item.get("model") or "").strip()

        if not brand or not model:
            continue

        primeira_palavra = model.split()[0]

        cleaned_set.add((brand, primeira_palavra))
        mapped.append((brand, model, primeira_palavra))

    # ordenar
    cleaned_list = sorted(cleaned_set, key=lambda x: (x[0].lower(), x[1].lower()))
    mapped.sort(key=lambda x: (x[0].lower(), x[2].lower(), x[1].lower()))

    # CSV limpo
    with open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model"])
        for brand, model in cleaned_list:
            w.writerow([brand, model])

    # CSV de mapeamento (para você auditar)
    with open(OUT_MAP, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model_original", "model_primeira_palavra"])
        for row in mapped:
            w.writerow(row)

    print("✅ Gerado:", OUT_CSV, "| linhas:", len(cleaned_list))
    print("✅ Gerado:", OUT_MAP, "| linhas:", len(mapped))

if __name__ == "__main__":
    main()