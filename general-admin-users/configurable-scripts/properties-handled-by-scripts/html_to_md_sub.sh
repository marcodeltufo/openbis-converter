#!/bin/bash
echo "--------------"
MAINFILENAME=${PWD##*/}.md
touch $MAINFILENAME
while read URL
do
    echo "$URL"
    FILENAME=$(echo ${URL##*/}).md
    curl --silent --user fdegior:Aj6G8VAo=NRJ "$URL/" | pandoc --from html --to markdown_strict-raw_html-native_divs-native_spans-fenced_divs-bracketed_spans --shift-heading-level-by=1 -o $FILENAME
    FIRSTLINE=116
    sed -i 1,${FIRSTLINE}d $FILENAME
    LASTLINE=$(($(wc -l < ${FILENAME})-$(grep -n "No labels" $FILENAME | head -1 | cut -d":" -f1)))
    head -n -${LASTLINE} $FILENAME > temp && mv temp $FILENAME
    echo " " >> $MAINFILENAME
    cat $FILENAME >> $MAINFILENAME
    rm $FILENAME
done < urls_sub.txt

sed -i "1 i\====" ./$MAINFILENAME
title=${PWD##*/}
title=$(echo $title | sed "s/-/ /g" | sed -e "s/\b\(.\)/\u\1/g")
sed -i "1 i\\${title}" ./$MAINFILENAME

rm ../$MAINFILENAME
mv ./$MAINFILENAME ../