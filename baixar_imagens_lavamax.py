"""
Execute este script na RAIZ do projeto Flutter (onde está o pubspec.yaml).
Ele baixa as imagens dos serviços do site Lavamax e a logo, salvando nas
pastas corretas de assets.

Comando para rodar no cmd:
    python baixar_imagens_lavamax.py
"""

import urllib.request
import os

# Pasta destino
os.makedirs("assets/images/services", exist_ok=True)

imagens = [
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2025/04/lavamax-logo.png",
        "assets/images/lavamax_logo.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/pelicula-150x150.png",
        "assets/images/services/ppf.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/05/vitrificacao-150x150.png",
        "assets/images/services/vitrificacao.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/lavagem-especial-150x150.png",
        "assets/images/services/lavagem_premium.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/lavagem-150x150.png",
        "assets/images/services/polimentos.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/higienizacao-150x150.png",
        "assets/images/services/higienizacao.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/pelicula-150x150.png",
        "assets/images/services/peliculas.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/05/limpeza-motor-1-150x150.png",
        "assets/images/services/limpeza_motor.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/05/limpeza-farol-1-150x150.png",
        "assets/images/services/restauracao_farois.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/martelinho-de-ouro-150x150.png",
        "assets/images/services/martelinho.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/craiyon_035908_icon_of_a_spray_gun_inside_a_green_circle__clean__svg_style__simplified__no_details-1-150x150.png",
        "assets/images/services/funilaria.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/rodas-150x150.png",
        "assets/images/services/rodas.png",
    ),
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/d6cd9e6328fadc04e8bf396a01fae1a5-1-1-1-150x150.png",
        "assets/images/services/customizacao.png",
    ),
    # Home Car Detail: sem imagem própria no site, reutiliza higienização
    (
        "https://lavamaxstudiocar.com.br/wp-content/uploads/2023/04/higienizacao-150x150.png",
        "assets/images/services/home_car_detail.png",
    ),
]

headers = {"User-Agent": "Mozilla/5.0"}

print("Baixando imagens...\n")
for url, destino in imagens:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r, open(destino, "wb") as f:
            f.write(r.read())
        print(f"  OK  {destino}")
    except Exception as e:
        print(f"  ERRO {destino}: {e}")

print("\nConcluído! Verifique as pastas assets/images/ e assets/images/services/")
