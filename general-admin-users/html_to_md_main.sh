#!/bin/bash

INDEXFILE=/home/marco/openbis-converter-new/general-users/index.rst
LASTINDEXLINE=$(($(wc -l < ${INDEXFILE})-$(grep -n ":maxdepth:" $INDEXFILE | head -1 | cut -d":" -f1)))
echo $LASTINDEXLINE
LASTINDEXLINE=$((LASTINDEXLINE-1))
head -n -${LASTINDEXLINE} $INDEXFILE > temp && mv temp $INDEXFILE
while read URL
do
    echo "$URL"
    FILENAME=$(echo ${URL##*/}).md
    curl --silent "$URL/" | pandoc --from html --to markdown_strict-raw_html-native_divs-native_spans-fenced_divs-bracketed_spans --shift-heading-level-by=1 -o $FILENAME
    FIRSTLINE=177
    sed -i 1,${FIRSTLINE}d $FILENAME
    LASTLINE=$(($(wc -l < ${FILENAME})-$(grep -n "Updated on" $FILENAME | head -1 | cut -d":" -f1)))
    head -n -${LASTLINE} $FILENAME > temp && mv temp $FILENAME
    echo "   $FILENAME" | cut -d"." -f1 >> $INDEXFILE
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

            url=$(echo "$line" | grep -Eo 'https://[^ >]+.png' |head -1 | sed 's/)//g')
            wget -P ./img "$url"
            newline="![image info](img/${url##*/})"
            sed -i "${i}s|^.*$|${newline}|" $page
        fi
        ((i++))
    done < $page
done
