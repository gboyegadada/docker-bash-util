@ECHO OFF
setlocal DISABLEDELAYEDEXPANSION
cd .

call docker\config.cmd

@for /f %%i in ('docker images -q %image%') do set IMAGEID=%%i
@for %%n in (prod dev test) do (
    if exist app\logs\%%n.log del app\logs\%%n.log /q
)
if "%IMAGEID%" == "" (docker build -m 3000MB --memory-swap 3000MB -t %image%:latest .)

if not exist app\config\parameters.yml copy app\config\parameters.yml.dist app\config\parameters.yml

docker run --rm -v %CD%:/var/www %image% phpunit %*