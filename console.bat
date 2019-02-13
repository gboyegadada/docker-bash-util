@ECHO OFF
setlocal DISABLEDELAYEDEXPANSION
cd .

call docker\config.cmd

echo Emptying Symfony cache folder...
if exist app\cache\prod rmdir app\cache\prod /q /s
if exist app\cache\dev rmdir app\cache\dev /q /s
if not exist app\config\parameters.yml copy app\config\parameters.yml.dist app\config\parameters.yml

@for /f %%i in ('docker inspect -f {{.State.Running}} %container%') DO set RUNNING=%%i

if not "%RUNNING%" == "true" (docker\run)

echo Attached to running container...
docker exec -it %container% bash