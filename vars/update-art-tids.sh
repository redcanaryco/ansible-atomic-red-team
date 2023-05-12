#!/bin/bash

IFS=$'\n'
ghuser="redcanaryco"
branch="master"

echo "---" | tee art-tids.yml

function fetch-art-index-to-yml () {
    url="https://github.com/${ghuser}/atomic-red-team/raw/${branch}/atomics/Indexes/Indexes-CSV/${1}-index.csv"
    tidlist=( $(curl -sL $url | awk -F, '/T1/{print $2}' | sort -u) )
        echo "art_tids_${1}:" | tee -a art-tids.yml
        for tid in ${tidlist[*]}; do
            echo "  - ${tid}"
        done | tee -a art-tids.yml
}

for os in linux macos windows; do
    fetch-art-index-to-yml ${os}
done
