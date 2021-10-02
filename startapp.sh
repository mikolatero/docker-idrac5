#!/bin/sh

RED='\033[0;31m'
NC='\033[0m'

download() {
  jar=$1
  path=$2
  if [ ! -f "${path}/${jar}" ]; then
    URI="Java/release"
    wget --load-cookies=cookies -O "${path}/${jar}" https://${IDRAC_HOST}/${URI}/${jar} --no-check-certificate
    if [ ! $? -eq 0 ]; then
      echo -e "${RED}Failed to download ${jar}, please check your settings${NC}"
      sleep 2
      exit 2
    fi
  fi
}

echo "Starting"
echo "Based on: https://github.com/ncerny/docker-idrac"


if [ -z "${IDRAC_HOST}" ]; then
    echo -e "${RED}Please set a proper idrac host with IDRAC_HOST${NC}"
    sleep 2
    exit 1
fi

if [ -z "${IDRAC_USER}" ]; then
    echo -e "${RED}Please set a proper idrac user with IDRAC_USER${NC}"
    sleep 2
    exit 1
fi

if [ -z "${IDRAC_PASSWORD}" ]; then
    echo -e "${RED}Please set a proper idrac password with IDRAC_PASSWORD${NC}"
    sleep 2
    exit 1
fi

echo "Environment ok"
cd /app


echo "Creating library folder if not exists"
if [ ! -d "lib" ]; then
    echo "Creating library folder"
    mkdir lib
fi


COOKIE=$(curl -k --data "WEBVAR_USERNAME=${IDRAC_USER}&WEBVAR_PASSWORD=${IDRAC_PASSWORD}" https://${IDRAC_HOST}/rpc/WEBSES/create.asp 2> /dev/null | grep SESSION_COOKIE | cut -d\' -f 4)
echo "Cookie=SessionCookie=${COOKIE}" > cookies

echo "Downloading required files"

download JViewer.jar .
download Linux_x86_64.jar lib

cd lib

if [ ! -f "libjavacdromwrapper.so" ]; then
    echo "Extracting Linux_x86_64.jar"
    jar -xf Linux_x86_64.jar
fi

cd ..

args=$(curl -k --cookie Cookie=SessionCookie=${COOKIE} https://${IDRAC_HOST}/Java/jviewer.jnlp | awk -F '[<>]' '/argument/ { print $3 }')

exec java -Djava.library.path="lib" -jar JViewer.jar $args
