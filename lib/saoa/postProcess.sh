
baseName=`basename "$1" "$2"`
cat "$1" |sed -ne '/<xmlData/,/<\/xmlData>/p' |sed -e 's/<xmlData>//' -e 's/<\/xmlData>//' -e 's/\&amp;/\&/g' -e "s/\&apos;/\'/g" -e 's/\&gt;/>/g' -e 's/\&lt;/</g' > "$baseName.csv"