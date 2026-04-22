@echo off
echo Buildando LavaMax APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo.
    echo ERRO no build. Verifique as mensagens acima.
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\lavamax.apk
echo.
echo Build concluido com sucesso!
echo APK disponivel em: build\app\outputs\flutter-apk\lavamax.apk
pause