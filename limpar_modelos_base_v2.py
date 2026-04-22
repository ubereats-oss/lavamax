import json
import csv
import re

INPUT_JSON = "carros_marcas_modelos.json"
OUT_CLEAN_CSV = "carros_modelos_limpados.csv"
OUT_MAP_CSV = "carros_modelos_map.csv"

# Tokens técnicos a remover
DROP_TOKENS = {
    "flex", "gasolina", "diesel", "alcool", "álcool", "etanol", "gnv",
    "turbo", "biturbo", "tbi", "tsi", "tfsi", "t-jet", "tgdi", "dohc", "sohc",
    "cvvt", "vvt", "multijet", "hdi", "tdi", "cdti", "dci", "crdi",
    "aut", "auto", "automatico", "automático", "at", "mt", "cvt", "dsg",
    "tiptronic", "4x4", "4x2", "4wd", "awd", "fwd", "rwd",
    "2p", "4p", "5p", "3p",
    "16v", "20v", "8v", "12v", "24v", "32v",
    "v6", "v8", "v10", "v12",
    "sedan", "sportback", "cabriolet", "coupe", "roadster",
    "hatch", "hatchback", "sw", "wagon", "avant", "touring",
    "variant", "perua", "pickup", "pick-up", "picape",
    "van", "furgão", "furgao", "minivan",
    "suv", "crossover"
}

def normalize_spaces(s: str) -> str:
    s = s.replace("/", " ").replace("-", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s

def remove_engine_patterns(s: str) -> str:
    s = re.sub(r"\b\d\.\d\b", " ", s)          # 1.0 / 2.0 etc
    s = re.sub(r"\b\d{3,4}\b", " ", s)        # 1000 / 2000 etc
    return s

def clean_model_name(model: str) -> str:
    s = model.strip()

    # remove texto entre parênteses
    s = re.sub(r"\([^)]*\)", " ", s)

    s = remove_engine_patterns(s)
    s = normalize_spaces(s)

    tokens = s.split(" ")
    cleaned = []

    for t in tokens:
        tl = re.sub(r"[^\wáàãâéêíóôõúç]", "", t.lower())

        if not tl:
            continue

        if tl.isdigit():
            continue

        if tl in DROP_TOKENS:
            continue

        cleaned.append(t)

    base = " ".join(cleaned).strip()
    base = normalize_spaces(base)

    # fallback se tudo foi removido
    if not base and tokens:
        base = tokens[0]

    return base

def main():
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    mapped = []
    clean_set = set()

    for item in data:
        brand = (item.get("brand") or "").strip()
        model = (item.get("model") or "").strip()
        if not brand or not model:
            continue

        model_clean = clean_model_name(model)
        if not model_clean:
            continue

        mapped.append((brand, model, model_clean))
        clean_set.add((brand, model_clean))

    mapped.sort(key=lambda x: (x[0].lower(), x[2].lower(), x[1].lower()))
    clean_list = sorted(clean_set, key=lambda x: (x[0].lower(), x[1].lower()))

    with open(OUT_CLEAN_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model"])
        for brand, model_clean in clean_list:
            w.writerow([brand, model_clean])

    with open(OUT_MAP_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["brand", "model_original", "model_clean"])
        for brand, model_orig, model_clean in mapped:
            w.writerow([brand, model_orig, model_clean])

    print("✅ Gerado:", OUT_CLEAN_CSV, "| linhas:", len(clean_list))
    print("✅ Gerado:", OUT_MAP_CSV, "| linhas:", len(mapped))

if __name__ == "__main__":
    main()