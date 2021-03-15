#!/bin/bash
function get-translations(){
  echo $2
    curl -H "X-Api-Token: $2" -X GET -H \
    "Content-type: application/json" \
    >temp.lua \
    "https://wow.curseforge.com/api/projects/453921/localization/export?lang=$1"

    sed -e '/--.*$/{r temp.lua' -e 'd}' Journalator/Journalator/Locales/$1.lua >temp2.lua
    awk '{gsub("\\\\\\\\n", "\\n", $0); print}' temp2.lua >temp.lua
    mv temp.lua Journalator/Locales/$1.lua
    rm temp2.lua
}
get-translations $1 $2

