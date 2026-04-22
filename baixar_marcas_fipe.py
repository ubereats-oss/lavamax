import json
import csv
import requests

URL = "https://parallelum.com.br/fipe/api/v1/carros/marcas"

def main():
    r = requests.get(URL, timeout=30)
    r.raise_for_status()
    marcas = r.json()  # lista de { "codigo": "...", "nome": "..." }

    # JSON
    with open("marcas_fipe_carros.json", "w", encoding="utf-8") as f:
        json.dump(marcas, f, ensure_ascii=False, indent=2)

    # CSV (pra filtrar fácil)
    with open("marcas_fipe_carros.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["codigo", "nome"])
        for m in marcas:
            w.writerow([m.get("codigo"), m.get("nome")])

    print("✅ Gerado: marcas_fipe_carros.json")
    print("✅ Gerado: marcas_fipe_carros.csv")
    print("Total de marcas:", len(marcas))

if __name__ == "__main__":
    main()