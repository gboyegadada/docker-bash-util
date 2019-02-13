set image=my-docker-image
set container=my-docker-app
set mysqlport=44060
set httpport=9090
set network=my-docker-net


echo -------------------- ENV ----------------------
echo Docker Image: %image%
echo Docker Container: %container%
echo MYSQL Port: %mysqlport%
echo HTTP Port: %httpport%
echo -----------------------------------------------