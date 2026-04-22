import json
import time
import requests

BASE = "https://parallelum.com.br/fipe/api/v1/carros"
MIN_YEAR = 2010

def get_json(url):
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    return r.json()

def main():
    out = []
    marcas = get_json(f"{BASE}/marcas")

    for i, marca in enumerate(marcas, start=1):
        marca_id = marca["codigo"]
        marca_nome = marca["nome"]

        modelos_resp = get_json(f"{BASE}/marcas/{marca_id}/modelos")
        modelos = modelos_resp.get("modelos", [])

        for modelo in modelos:
            modelo_id = modelo["codigo"]
            modelo_nome = modelo["nome"]

            anos = get_json(f"{BASE}/marcas/{marca_id}/modelos/{modelo_id}/anos")
            for a in anos:
                # exemplo: a["codigo"] = "2015-1"
                codigo = str(a.get("codigo", ""))
                ano_str = codigo.split("-")[0] if "-" in codigo else codigo

                try:
                    ano = int(ano_str)
                except ValueError:
                    continue

                if ano >= MIN_YEAR:
                    out.append({
                        "brand": marca_nome,
                        "model": modelo_nome,
                        "year": ano
                    })

            # pequeno delay pra não “martelar” o servidor
            time.sleep(0.05)

        print(f"[{i}/{len(marcas)}] OK: {marca_nome} (total registros: {len(out)})")

    # remover duplicados (pode acontecer por variações)
    uniq = {(x["brand"], x["model"], x["year"]): x for x in out}
    out = list(uniq.values())

    out.sort(key=lambda x: (x["brand"], x["model"], x["year"]))

    with open("carros_br_2010_mais.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    print("✅ Gerado: carros_br_2010_mais.json")
    print("Registros:", len(out))

if __name__ == "__main__":
    main()