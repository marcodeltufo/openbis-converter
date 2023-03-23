#!/bin/bash

rm /home/marco/pandoc/*.md
rmdir /home/marco/openbis-test/docs/*
rm /home/marco/openbis-test/docs/*.md

INDEXFILE=/home/marco/openbis-test/docs/index.rst
LASTINDEXLINE=$(($(wc -l < ${INDEXFILE})-$(grep -n ":maxdepth:" $INDEXFILE | head -1 | cut -d":" -f1)))
echo $LASTINDEXLINE
LASTINDEXLINE=$((LASTINDEXLINE-1))
head -n -${LASTINDEXLINE} $INDEXFILE > temp && mv temp $INDEXFILE
while read URL
do
    echo "$URL"
    FILENAME=$(echo ${URL##*/}).md
    curl --silent "$URL/" | pandoc --from html --to markdown_strict -o $FILENAME
    FIRSTLINE=$(grep -n "===" $FILENAME | head -1 | cut -d":" -f1)
    FIRSTLINE=$((FIRSTLINE-2))
    sed -i 1,${FIRSTLINE}d $FILENAME
    LASTLINE=$(($(wc -l < ${FILENAME})-$(grep -n "Updated on" $FILENAME | head -1 | cut -d":" -f1)))
    head -n -${LASTLINE} $FILENAME > temp && mv temp $FILENAME
    linestoreplace=$(grep -n "\-\-\-" $FILENAME | cut -d":" -f1)
    for line in $linestoreplace; do
	    sed -i "${line}s/---*/^^^^/i" $FILENAME
    done
    linestoreplace=$(grep -n "===" $FILENAME | tail -n +2 | cut -d":" -f1)
    for line in $linestoreplace; do
            sed -i "${line}s/===*/----/i" $FILENAME
    done
    
    while [ $(grep -c "<img" ${FILENAME}) -ne 0 ]
    do 
	    IMGLINE=$(grep -n "<img" $FILENAME | head -1 | cut -d":" -f1)
	    IMGURL=$(sed "${IMGLINE}q;d" $FILENAME | awk -F '"' '{print $2}')
	    sed -i "${IMGLINE}s|^.*$|.. image:: ${IMGURL}|" $FILENAME
    done
    
    while [ $(grep -c "<figure>" ${FILENAME}) -ne 0 ]
    do
	    FIGURELINE=$(grep -n "<figure>" $FILENAME | head -1 | cut -d":" -f1)
	    sed -i "${FIGURELINE}d" $FILENAME
    done
    
    while [ $(grep -c "</figure>" ${FILENAME}) -ne 0 ]
    do
	    FIGURELINE=$(grep -n "</figure>" $FILENAME | head -1 | cut -d":" -f1)
            sed -i "${FIGURELINE}d" $FILENAME
    done
    sed -i -e 's/<[^>]*>//g' $FILENAME
    echo "   $FILENAME" | cut -d"." -f1 >> $INDEXFILE
done < urls.txt

CARTELLA=$(pwd)

for d in */ ; do
    echo "eseguo: $d"
    cd $CARTELLA
    cd $d
    sh html_to_md_sub.sh
done

cp /home/marco/pandoc/* /home/marco/openbis-test/docs/
rm /home/marco/openbis-test/docs/*.txt
rm /home/marco/openbis-test/docs/*.sh

#sh /home/marco/openbis-test/pulizia_push.sh

cd /home/marco/openbis-test
git add docs/
git commit -am "commit"
git push
