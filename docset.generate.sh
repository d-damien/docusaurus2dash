#!/bin/bash
# Generate Kapeli Dash docset from https://day.js.org doc
# WIP

# Edit variables
NAME='DayJS'
REPO='https://github.com/dayjs/dayjs-website'
FOLDER='dayjs-website'

dependencies=(git jq perl pandoc sqlite3 tar)
for dep in ${dependencies[@]}; do
  hash $dep || exit 1
done

# cleanup
rm -rf $NAME.docset /tmp/$NAME

# basic folders & files
[ -d $FOLDER ] || git clone $REPO
mkdir -p $NAME.docset/Contents/Resources/Documents/
mkdir /tmp/$NAME/
sqlite3 $NAME.docset/Contents/Resources/docSet.dsidx '
  CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
  CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
'

# ordered categories
IFS="
"
categories=$(jq -r '.docs | keys_unsorted | .[]' < $FOLDER/website/sidebars.json)

# concatenate each category in single file + index.md
for cat in ${categories[@]}; do
  for subcat in $(jq -r ".docs[\"$cat\"] | .[]" < $FOLDER/website/sidebars.json); do
    cat $FOLDER/docs/$subcat.md >> /tmp/$NAME/$cat.md
  done

  # replace docusaurus ---\n slug \n title \n--- with pandoc markdown title
  perl -0777 -pi -e 's/---\n[^:]*: ([^\n]*)\n[^:]*: ([^\n]*)\n---/\n\n## \2 {#\1}/g' /tmp/$NAME/$cat.md
  # md -> html
  pandoc -f markdown -t html -s\
    --metadata pagetitle="$cat"\
    -o $NAME.docset/Contents/Resources/Documents/$cat.html\
    /tmp/$NAME/$cat.md
  # sqlite
  sqlite3 $NAME.docset/Contents/Resources/docSet.dsidx "
    INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ($cat, 'Category', $cat.html);
  "
done

# @todo
# css
# index ?
# ancres commonmark ??
# icon

# tar zcf docset
