@ECHO OFF
setlocal DISABLEDELAYEDEXPANSION
cd .

call docker\config.cmd

for /f %%i in ('docker images -q %image%:latest') do set IMAGEID=%%i

if "%~1" == "-b" (
    echo Removing old container images...
    @for /f "tokens=*" %%i IN ('docker container ls -aq --filter "name=%container%"') DO docker container stop %%i
    @for /f "tokens=*" %%i IN ('docker container ls -aq --filter "name=%container%"') DO docker container rm %%i
    @for /f %%i in ('docker images -q %image%') do docker rmi %%i

    @for %%n in (prod dev test) do (
        if exist app\logs\%%n.log del app\logs\%%n.log /q
    )

    echo Please wait while I build your new docker image -- Subsequent calls will be much faster..
    set NEWBUILD=true
    docker build -m 3000MB --memory-swap 3000MB -t %image%:latest .
) else (
    if "%IMAGEID%" == "" (
        echo Please wait while I build your docker image -- Subsequent calls will be much faster..
        set NEWBUILD=true
        docker build -m 3000MB --memory-swap 3000MB -t %image%:latest .
    ) else (
        set NEWBUILD=false
    )
)

if exist app\cache\prod rmdir app\cache\prod /q /s
if exist app\cache\dev rmdir app\cache\dev /q /s
if not exist app\config\parameters.yml copy app\config\parameters.yml.dist app\config\parameters.yml

echo Starting container... %CD%

set AVAILABLE=false
@for /f %%i in ('docker ps -aq --filter "name=%container%"') do set AVAILABLE=%%i

if "%AVAILABLE%" == "false" (
    if not exist .composer mkdir .composer
    docker run -p %httpport%:80 -p %mysqlport%:3306 -h localhost -d -v %CD%:/var/www -v %CD%/.composer:/root/.composer --name %container% %image%
    docker exec %container% composer install --ansi  --no-progress --no-suggest --optimize-autoloader --classmap-authoritative
    docker exec %container% docker/bin/mysql_setup
) else (
    @for /f "tokens=*" %%i IN ('docker container ls -aq --filter "name=%container%"') DO docker container stop %%i
    docker start %container%
    docker exec %container% service mysql start
    docker exec %container% /etc/init.d/apache2 reload
)

if "%NEWBUILD%" == "true" (
    if exist app\config\parameters.yml rm app\config\parameters.yml

    docker exec %container% composer install --ansi  --no-progress --no-suggest --optimize-autoloader --classmap-authoritative
    docker exec %container% npm install
    docker exec %container% gulp
)
docker exec %container% php bin/console cache:clear --env=prod

@for /f %%i in ('docker inspect -f "{{ .NetworkSettings.IPAddress }}" %container%') do set IPADDRESS=%%i
@for /f %%i in ('docker inspect -f "{{(index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort}}" %container%') do set HOSTPORT=%%i
echo Assigned IP address is: %IPADDRESS%:%HOSTPORT% (for non windows machines only). If you are on a Windows machine navigate to: http:://localhost:%HOSTPORT%.

start "" http://localhost:%HOSTPORT%
