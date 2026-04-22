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

# status comuns para instabilidade e rate limit
RETRY_STATUS = {429, 500, 502, 503, 504}

# timeouts para não "pendurar": (conexão, leitura)
TIMEOUT = (10, 20)

# reduzir ritmo para evitar 429
DELAY_BETWEEN_REQUESTS = 0.9   # pausa após cada request bem-sucedido
DELAY_BETWEEN_MODELS = 0.4     # pausa entre modelos

MAX_TRIES = 12

session = requests.Session()
session.headers.update({"User-Agent": "carros-fipe-loader/2.0"})

def _sleep_backoff(attempt: int):
    # backoff exponencial + jitter (até ~60s)
    s = min((2 ** attempt), 55) + random.random() * 3
    time.sleep(s)

def request_json(url: str, ctx: str):
    last_err = None

    for attempt in range(MAX_TRIES):
        try:
            r = session.get(url, timeout=TIMEOUT)

            if r.status_code in RETRY_STATUS:
                if r.status_code == 429:
                    # respeita Retry-After se existir
                    ra = r.headers.get("Retry-After")
                    if ra:
                        try:
                            wait_s = float(ra) + 1 + random.random() * 2
                        except ValueError:
                            wait_s = min((2 ** attempt), 55) + random.random() * 3
                    else:
                        wait_s = min((2 ** attempt), 55) + random.random() * 3

                    print(f"⚠️ 429 (rate limit) | {ctx} | aguardando {wait_s:.1f}s | tentativa {attempt+1}/{MAX_TRIES}")
                    time.sleep(wait_s)
                    continue

                print(f"⚠️ HTTP {r.status_code} | {ctx} | tentativa {attempt+1}/{MAX_TRIES}")
                _sleep_backoff(attempt)
                continue

            r.raise_for_status()
            data = r.json()
            time.sleep(DELAY_BETWEEN_REQUESTS)
            return data

        except requests.Timeout as e:
            last_err = e
            print(f"⚠️ TIMEOUT | {ctx} | tentativa {attempt+1}/{MAX_TRIES}")
            _sleep_backoff(attempt)

        except requests.RequestException as e:
            last_err = e
            print(f"⚠️ ERRO | {ctx} | {e} | tentativa {attempt+1}/{MAX_TRIES}")
            _sleep_backoff(attempt)

    raise RuntimeError(f"Falhou após {MAX_TRIES} tentativas | {ctx} | último erro: {last_err}")

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
    # para retomar sem duplicar
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

    print(f"Marcas selecionadas: {len(brands)}")
    print(f"Já no progresso: {len(done)}")
    print("Checkpoint:", PROGRESS_JSONL)
    print("Se der erro/fechar, rode novamente que ele continua.\n")

    total_written = len(done)

    for i, brand in enumerate(brands, start=1):
        marca_id = brand["codigo"]
        marca_nome = brand["nome"]

        print(f"=== [{i}/{len(brands)}] Marca: {marca_nome} (id {marca_id}) ===")

        modelos_url = f"{BASE}/marcas/{marca_id}/modelos"
        modelos_resp = request_json(modelos_url, ctx=f"{marca_nome} | modelos")
        modelos = modelos_resp.get("modelos", []) or []

        print(f"{marca_nome}: modelos encontrados = {len(modelos)}")

        for idx_modelo, modelo in enumerate(modelos, start=1):
            modelo_id = modelo.get("codigo")
            modelo_nome = (modelo.get("nome") or "").strip()
            if not modelo_id or not modelo_nome:
                continue

            print(f"- {marca_nome} | modelo {idx_modelo}/{len(modelos)}: {modelo_nome}")

            anos_url = f"{BASE}/marcas/{marca_id}/modelos/{modelo_id}/anos"
            anos = request_json(anos_url, ctx=f"{marca_nome} | {modelo_nome} | anos")

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

            time.sleep(DELAY_BETWEEN_MODELS)

        print(f"✅ OK: {marca_nome} | total registros até agora: {total_written}\n")

    # monta JSON final a partir do set done
    items = [{"brand": b, "model": m, "year": y} for (b, m, y) in done]
    items.sort(key=lambda x: (x["brand"], x["model"], x["year"]))

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    print("✅ Finalizado")
    print("✅ Gerado:", OUTPUT_JSON)
    print("✅ Checkpoint mantido:", PROGRESS_JSONL)
    print("Registros finais:", len(items))

if __name__ == "__main__":
    main()