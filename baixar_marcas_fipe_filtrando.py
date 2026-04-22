import csv
import json
import io

INPUT_FILE = "marcas_fipe_carros.csv"
OUTPUT_JSON = "marcas_filtradas.json"
OUTPUT_CSV = "marcas_filtradas.csv"

def read_text_with_fallback(path: str) -> str:
    # Lê bytes e tenta decodificar com fallback
    raw = open(path, "rb").read()

    encodings = ["utf-8-sig", "utf-8", "cp1252", "latin-1"]
    last_err = None

    for enc in encodings:
        try:
            return raw.decode(enc)
        except UnicodeDecodeError as e:
            last_err = e

    # latin-1 normalmente não falha; se falhar aqui, algo muito fora do padrão
    raise last_err  # pragma: no cover

def detect_dialect(sample: str) -> csv.Dialect:
    # Tenta sniff; se falhar, assume ; (Excel BR) ou , (padrão)
    try:
        return csv.Sniffer().sniff(sample, delimiters=";,")
    except Exception:
        class DefaultDialect(csv.Dialect):
            delimiter = ";"
            quotechar = '"'
            doublequote = True
            skipinitialspace = True
            lineterminator = "\n"
            quoting = csv.QUOTE_MINIMAL
        return DefaultDialect()

def normalize_header(s: str) -> str:
    return (s or "").strip().lower().replace(" ", "")

def main():
    text = read_text_with_fallback(INPUT_FILE)

    sample = text[:4096]
    dialect = detect_dialect(sample)

    f = io.StringIO(text)
    reader = csv.DictReader(f, dialect=dialect)

    if not reader.fieldnames:
        print("❌ Não consegui ler o cabeçalho do CSV (fieldnames vazio).")
        return

    # Mapeia cabeçalhos para lidar com variações tipo "S-N", "s-n", "s_n", etc.
    field_map = {normalize_header(name): name for name in reader.fieldnames}

    # Tentativas aceitáveis para a coluna sim/não
    sn_key = None
    for candidate in ["s-n", "sn", "s_n", "s/n"]:
        if normalize_header(candidate) in field_map:
            sn_key = field_map[normalize_header(candidate)]
            break

    if sn_key is None:
        print("❌ Não encontrei a coluna 's-n' (ou variações) no CSV.")
        print("Colunas encontradas:", reader.fieldnames)
        return

    # Colunas esperadas (tolerante)
    codigo_key = field_map.get("codigo", None)
    nome_key = field_map.get("nome", None)

    if codigo_key is None or nome_key is None:
        print("❌ Não encontrei colunas 'codigo' e 'nome' no CSV.")
        print("Colunas encontradas:", reader.fieldnames)
        return

    filtradas = []
    for row in reader:
        val = (row.get(sn_key) or "").strip().lower()
        if val == "sim":
            filtradas.append({
                "codigo": (row.get(codigo_key) or "").strip(),
                "nome": (row.get(nome_key) or "").strip(),
            })

    # JSON
    with open(OUTPUT_JSON, "w", encoding="utf-8") as out:
        json.dump(filtradas, out, ensure_ascii=False, indent=2)

    # CSV
    with open(OUTPUT_CSV, "w", encoding="utf-8", newline="") as out:
        w = csv.writer(out)
        w.writerow(["codigo", "nome"])
        for m in filtradas:
            w.writerow([m["codigo"], m["nome"]])

    print("✅ Gerado:", OUTPUT_JSON)
    print("✅ Gerado:", OUTPUT_CSV)
    print("Total selecionadas:", len(filtradas))

if __name__ == "__main__":
    main()