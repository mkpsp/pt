#!/bin/sh

mkdir -p /usr/local/bin

curl -s https://raw.githubusercontent.com/mkpsp/pt/main/src/pt -o /usr/local/bin/pt

chmod +x /usr/local/bin/pt
