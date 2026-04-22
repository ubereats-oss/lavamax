import csv
import json
import time
import random
import os
import requests

BASE = "https://parallelum.com.br/fipe/api/v1/carros"
MIN_YEAR = 2010

INPUT_BRANDS_CSV = "marcas_filtradas.csv"
PROGRESS_JSONL = "carros_progress.jsonl"
OUTPUT_JSON = "carros_br_2010_mais_filtrado.json"

RETRY_STATUS = {429, 500, 502, 503, 504}

session = requests.Session()
session.headers.update({"User-Agent": "carros-fipe-loader/1.1"})

def request_json(url: str, max_tries: int = 8):
    for attempt in range(max_tries):
        try:
            r = session.get(url, timeout=30)
            if r.status_code in RETRY_STATUS:
                # backoff + jitter
                sleep_s = min(2 ** attempt, 30) + random.random()
                print(f"⚠️ {r.status_code} em {url} | retry em {sleep_s:.1f}s")
                time.sleep(sleep_s)
                continue
            r.raise_for_status()
            return r.json()
        except requests.RequestException as e:
            sleep_s = min(2 ** attempt, 30) + random.random()
            print(f"⚠️ erro em {url}: {e} | retry em {sleep_s:.1f}s")
            time.sleep(sleep_s)
    raise RuntimeError(f"Falhou após {max_tries} tentativas: {url}")

def load_selected_brands():
    brands = []
    with open(INPUT_BRANDS_CSV, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            codigo = (row.get("codigo") or "").strip()
            nome = (row.get("nome") or "").strip()
            if codigo and nome:
                brands.append({"codigo": codigo, "nome": nome})
    return brands

def load_done_keys():
    # Para retomar sem duplicar: guarda (brand, model, year)
    done = set()
    if not os.path.exists(PROGRESS_JSONL):
        return done
    with open(PROGRESS_JSONL, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                done.add((obj["brand"], obj["model"], int(obj["year"])))
            except Exception:
                pass
    return done

def append_progress(obj):
    with open(PROGRESS_JSONL, "a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")

def main():
    brands = load_selected_brands()
    done = load_done_keys()
    total_written = len(done)

    print(f"Marcas selecionadas: {len(brands)}")
    print(f"Já no progresso: {total_written}")

    for i, brand in enumerate(brands, start=1):
        marca_id = brand["codigo"]
        marca_nome = brand["nome"]

        modelos_resp = request_json(f"{BASE}/marcas/{marca_id}/modelos")
        modelos = modelos_resp.get("modelos", [])

        for modelo in modelos:
            modelo_id = modelo.get("codigo")
            modelo_nome = (modelo.get("nome") or "").strip()
            if not modelo_id or not modelo_nome:
                continue

            anos = request_json(f"{BASE}/marcas/{marca_id}/modelos/{modelo_id}/anos")
            for a in anos:
                codigo = str(a.get("codigo", ""))
                ano_str = codigo.split("-")[0] if "-" in codigo else codigo
                try:
                    ano = int(ano_str)
                except ValueError:
                    continue

                if ano < MIN_YEAR:
                    continue

                key = (marca_nome, modelo_nome, ano)
                if key in done:
                    continue

                obj = {"brand": marca_nome, "model": modelo_nome, "year": ano}
                append_progress(obj)
                done.add(key)
                total_written += 1

            # delay leve entre modelos
            time.sleep(0.05)

        print(f"[{i}/{len(brands)}] OK: {marca_nome} | total registros: {total_written}")

    # Gera JSON final a partir do JSONL (garante ordenação e sem duplicados)
    items = [{"brand": b, "model": m, "year": y} for (b, m, y) in done]
    items.sort(key=lambda x: (x["brand"], x["model"], x["year"]))

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    print("✅ Gerado:", OUTPUT_JSON)
    print("✅ Progresso (checkpoint):", PROGRESS_JSONL)
    print("Registros finais:", len(items))

if __name__ == "__main__":
    main()