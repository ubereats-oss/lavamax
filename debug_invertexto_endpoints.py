import requests
import json

TOKEN = "24873|IURoncd42NZzYP2hjCBUtqCzZBXL9ifx"
BASE = "https://api.invertexto.com/v1/fipe"
TYPE_CAR = 1

session = requests.Session()
session.headers.update({
    "User-Agent": "carros-invertexto-debug/1.0",
    "Authorization": f"Bearer {TOKEN}",
})

def p(title, obj):
    print("\n" + "="*80)
    print(title)
    print("="*80)
    print(json.dumps(obj, ensure_ascii=False, indent=2)[:4000])

def get(url):
    r = session.get(url, timeout=30)
    print("\nURL:", url)
    print("STATUS:", r.status_code)
    try:
        return r.json()
    except Exception:
        return {"_text": r.text[:1000]}

def main():
    brands = get(f"{BASE}/brands/{TYPE_CAR}")
    p("BRANDS (amostra)", brands)

    # tenta pegar o 1º id de marca
    brand_id = None
    if isinstance(brands, list) and len(brands) > 0:
        brand_id = brands[0].get("id") or brands[0].get("codigo") or brands[0].get("code")
    elif isinstance(brands, dict):
        lst = brands.get("brands") or brands.get("data") or brands.get("result")
        if isinstance(lst, list) and len(lst) > 0:
            brand_id = lst[0].get("id") or lst[0].get("codigo") or lst[0].get("code")

    if not brand_id:
        print("\n❌ Não consegui extrair brand_id da resposta de brands.")
        return

    models = get(f"{BASE}/models/{brand_id}")
    p("MODELS (amostra)", models)

    # tenta pegar algum identificador de modelo/código FIPE
    fipe_code = None
    candidates = []

    def collect_candidates(x):
        if isinstance(x, list):
            for it in x:
                if isinstance(it, dict):
                    candidates.append(it)
        elif isinstance(x, dict):
            for k in ["models", "data", "result", "items"]:
                v = x.get(k)
                if isinstance(v, list):
                    for it in v:
                        if isinstance(it, dict):
                            candidates.append(it)

    collect_candidates(models)

    for it in candidates[:20]:
        for key in ["fipe_code", "codigo_fipe", "code", "id", "fipeCode", "codigo"]:
            if key in it and it[key]:
                fipe_code = it[key]
                break
        if fipe_code:
            break

    if not fipe_code:
        print("\n❌ Não consegui achar um campo tipo fipe_code/codigo nos modelos.")
        print("Primeiro item de modelo:", candidates[0] if candidates else None)
        return

    years = get(f"{BASE}/years/{fipe_code}")
    p("YEARS (amostra)", years)

if __name__ == "__main__":
    main()