#!/bin/bash
# Generate Kapeli Dash docset from https://day.js.org doc
# WIP

# Edit variables
SLUG='dayjs'
NAME='DayJS'
REPO='https://github.com/dayjs/dayjs-website'
FOLDER='dayjs-website'

dependencies=(git perl jq commonmark sqlite3)
for dep in ${dependencies[@]}; do
  hash $dep && exit 1
done

# cleanup
rm -rf $SLUG.docset /tmp/$SLUG

# basic folders & files
[ -d $FOLDER ] || git clone $REPO
mkdir $SLUG.docset/Contents/Resources/Documents/
mkdir /tmp/$SLUG/

# ordered categories
IFS="
"
categories=$(jq '.docs | keys_unsorted | .[]' < $FOLDER/website/sidebars.json)

# concatenate each category in single file + index.md
for cat in ${categories[@]}; do
  echo "# $cat" > /tmp/$SLUG/$cat.md
  for subcat in $(jq -r ".docs[$cat] | .[]" < $FOLDER/website/sidebars.json); do
    cat $FOLDER/docs/$subcat.md >> /tmp/$SLUG/$cat.md
  done

  # replace docusaurus ---\n slug \n title \n--- with md title
  perl -0777 -pi -e 's/---\n[^\n]*\n[^:]*: ([^\n]*)\n---/## \1/g' /tmp/$SLUG/$cat.md
  # md -> html
  commonmark /tmp/$SLUG/$cat.md > $SLUG.docset/Contents/Resources/Documents/$cat.html
done

# sqlite entries
# tar zcf docset
