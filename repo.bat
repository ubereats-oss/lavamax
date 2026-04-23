REM === GERA O ARQUIVO COM NUMERACAO NATIVA DO REPOMIX ===
call npx repomix --output-show-line-numbers --quiet -o repomix-output.xml

REM === VALIDAR SAIDA ===
if exist repomix-output.xml (
    echo OK: repomix-output.xml criado com numeracao de linhas
) else (
    echo ERRO: falha ao gerar repomix-output.xml
    exit /b 1
)