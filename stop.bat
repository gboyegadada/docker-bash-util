@ECHO OFF
setlocal DISABLEDELAYEDEXPANSION
SET CurrentDirectry=%~dp0
for %%B in (%CurrentDirectry%.) do set parent=%%~dpB
cd %parent%

call docker\config.cmd

@for /f "tokens=*" %%i IN ('docker container ls -aq --filter "name=%container%"') DO docker container stop %%i
