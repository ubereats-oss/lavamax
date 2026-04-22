@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%cd%"
set "LIB_PATH=%PROJECT_ROOT%\lib"

echo.
echo ========================================
echo  LAVAMAX - Corrigindo Imports
echo ========================================
echo.

REM Usar PowerShell para fazer o replace em todos os arquivos .dart
powershell -Command "Get-ChildItem -Path '%LIB_PATH%' -Filter '*.dart' -Recurse | ForEach-Object { (Get-Content $_.FullName) -replace 'package:lavamax_agendamento', 'package:lavamax' | Set-Content $_.FullName }"

echo ✓ Todos os imports foram corrigidos de 'lavamax_agendamento' para 'lavamax'
echo.
echo ========================================
echo  ✓✓✓ IMPORTS CORRIGIDOS COM SUCESSO
echo ========================================
echo.
pause