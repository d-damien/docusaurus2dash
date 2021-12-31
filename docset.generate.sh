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

[ -d $FOLDER ] || git clone $REPO
mkdir -p $SLUG.docset/Contents/Resources/Documents/
mkdir /tmp/$SLUG/

# ordered categories
IFS="
"
categories=$(jq '.docs | keys_unsorted | .[]' < $FOLDER/website/sidebars.json)

# concatenate each category in single file + index.md
for cat in ${categories[@]}; do
  for subcat in $(jq -r ".docs[$cat] | .[]" < $FOLDER/website/sidebars.json); do
    cat $FOLDER/docs/$subcat.md >> /tmp/$SLUG/$cat.md
  done

  commonmark /tmp/$SLUG/$cat.md > $SLUG.docset/Contents/Resources/Documents/$cat.html
done

# ... cd, for loop, jq & sidebars.json etc


perl -0777 -pi -e 's/---\n[^\n]*\n[^\n]*\n---/abc/g' /tmp/dayjs/$d.md

# sqlite entries
# mardown to html
# tar zcf docset
