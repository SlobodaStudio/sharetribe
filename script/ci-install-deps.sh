#!/bin/bash

echo 'deb http://deb.debian.org/debian jessie-backports main' | sudo tee -a /etc/apt/sources.list

sudo apt-get update && sudo apt-get install sphinxsearch

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

. ~/.nvm/nvm.sh

nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
