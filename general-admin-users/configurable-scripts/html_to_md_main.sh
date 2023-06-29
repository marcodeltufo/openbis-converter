#!/bin/bash

INDEXFILE=/home/marco/openbis-converter/general-admin-users/configurable-scripts/index.rst
LASTINDEXLINE=$(($(wc -l < ${INDEXFILE})-$(grep -n ":maxdepth:" $INDEXFILE | head -1 | cut -d":" -f1)))
echo $LASTINDEXLINE
LASTINDEXLINE=$((LASTINDEXLINE-1))
head -n -${LASTINDEXLINE} $INDEXFILE > temp && mv temp $INDEXFILE
while read URL
do
    echo "$URL"
    FILENAME=$(echo ${URL##*/}).md
    curl --silent --user fdegior:Aj6G8VAo=NRJ "$URL/" | pandoc --from html --to markdown_strict-raw_html-native_divs-native_spans-fenced_divs-bracketed_spans --shift-heading-level-by=1 -o $FILENAME
    FIRSTLINE=114
    sed -i 1,${FIRSTLINE}d $FILENAME
    LASTLINE=$(($(wc -l < ${FILENAME})-$(grep -n "No labels" $FILENAME | head -1 | cut -d":" -f1)))
    head -n -${LASTLINE} $FILENAME > temp && mv temp $FILENAME
    #echo "   $FILENAME" | cut -d"." -f1 >> $INDEXFILE
done < urls.txt

CARTELLA=$(pwd)

for d in */ ; do
    echo "eseguo: $d"
    cd $CARTELLA
    cd $d
    sh html_to_md_sub.sh
done

cd $CARTELLA
for page in *.md; do
    echo $page
    echo "   $(basename ${page})" | cut -d"." -f1 >> $INDEXFILE
done

cd $CARTELLA
for page in *.md; do
    temp_file=$(mktemp)
    grep -vE '^#+[^a-zA-Z]*$' "$page" > "$temp_file"
    mv "$temp_file" "$page"
    #sed -i 's,#,##,' "$page"
    read -r first_line < $page
    modified_first_line=${first_line//##/#}
    sed -i "1s~$first_line~$modified_first_line~" $page
    sed -i -E 's/^#+\s+!/!/' $page
    i=1
    while IFS= read -r line; do
        if [[ $line == *".png"* ]]; then
            mainurl="https://unlimited.ethz.ch/"
            url=$(echo "$line" | grep -Eo 'download[^ >]+=v2' |head -1 | sed 's/)//g')
            url="${mainurl}${url}"
            wget --user fdegior --password Aj6G8VAo=NRJ -P ./img -O "./img/${i}.png" "$url"
            #imagename=${url##*/}
            #imagename=${imagename%%.*}.png
            #newline="![image info](img/${imagename})"
            newline="![image info](img/${i}.png)"
            sed -i "${i}s|^.*$|${newline}|" $page
        fi
        ((i++))
    done < $page
done