#!/bin/zsh

set -ev

# Crowin_Latest_Build="https://crowdin.com/backend/download/project/<TBD>.zip"

if [[ -d output ]]; then
    rm -rf output
fi
mkdir output

cd Intents
if [[ -d output ]]; then
    rm -rf output
fi
mkdir output
cd ..

swift run
