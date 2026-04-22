import csv
import json
import os
import re
import time
import requests

TOKEN = "24873|IURoncd42NZzYP2hjCBUtqCzZBXL9ifx"

BASE = "https://api.invertexto.com/v1/fipe"
TYPE_CAR = 1

INPUT_BRANDS_CSV = "marcas_filtradas.csv"
OUT_JSON = "carros_marcas_modelos.json"

session = requests.Session()
session.headers.update({
    "Authorization": f"Bearer {TOKEN}",
    "User-Agent": "carros-base-model/1.0"
})

def load_selected_brand_ids():
    ids = set()
    with open(INPUT_BRANDS_CSV, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                ids.add(int(row["codigo"]))
            except:
                pass
    return ids

def extrair_modelo_base(nome_modelo):
    """
    Extrai modelo base removendo motorização e versão.
    """
    # Remove conteúdo após primeiro padrão numérico com ponto (ex: 1.4, 2.0)
    match = re.split(r'\s\d\.\d', nome_modelo)
    base = match[0]

    # Remove padrões comuns
    base = re.split(r'\s\d', base)[0]
    base = base.strip()

    return base

def main():
    selected_ids = load_selected_brand_ids()
    print("Marcas selecionadas:", len(selected_ids))

    brands = session.get(f"{BASE}/brands/{TYPE_CAR}", timeout=30).json()
    brands = [b for b in brands if b["id"] in selected_ids]

    print("Marcas após filtro:", len(brands))

    resultado = set()

    for i, b in enumerate(brands, start=1):
        brand_id = b["id"]
        brand_name = b["brand"]

        print(f"[{i}/{len(brands)}] Marca: {brand_name}")

        models = session.get(f"{BASE}/models/{brand_id}", timeout=30).json()

        for m in models:
            model_full = m.get("model", "")
            if not model_full:
                continue

            model_base = extrair_modelo_base(model_full)

            if model_base:
                resultado.add((brand_name, model_base))

        time.sleep(0.05)

    lista_final = [
        {"brand": b, "model": m}
        for (b, m) in sorted(resultado)
    ]

    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(lista_final, f, ensure_ascii=False, indent=2)

    print("\n✅ Finalizado")
    print("Total modelos únicos:", len(lista_final))
    print("Arquivo gerado:", OUT_JSON)

if __name__ == "__main__":
    main()