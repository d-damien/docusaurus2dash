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

# extract title from header
function fileTitle() {
  perl -0777 -wnE 'say /---\n[^:]*: [^\n]*\n[^:]*: [^\n]*\n---/g' $1\
    | grep 'title:'\
    | cut -f  2 -d:\
    | tr -d ' '
}

# convert one md file to html
function _mdToHtml() {
  # replace docusaurus ---\n slug \n title \n--- with pandoc markdown title
  perl -0777 -pi -e 's/---\n[^:]*: ([^\n]*)\n[^:]*: ([^\n]*)\n---/\n\n## \2 {#\1}/g' "$1"
  # md -> html
  pandoc -f markdown -t html -s\
    --metadata pagetitle="todo"\
    --quiet
    -o ${1%md}.html\
    "$1"
}

# index.md + sqlite index
cp -r $FOLDER/docs/* /tmp/$NAME/
echo "# $NAME : table of contents" > /tmp/$NAME/index.md

for cat in ${categories[@]}; do
  echo "## $cat" >> /tmp/$NAME/index.md
  for subCatFile in $(jq -r ".docs[\"$cat\"] | .[]" < $FOLDER/website/sidebars.json); do
    subCatTitle=$(fileTitle $subCatFile.md)
    echo "- [$subCatTitle]($subCatFile.html)" >> /tmp/$NAME/index.md

    sqlite3 $NAME.docset/Contents/Resources/docSet.dsidx "
      INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ($subCatTitle, 'Element', $subCatFile.html);
    "
  done
done

for mdFile in $(find /tmp/$NAME -name "*.md"); do
  _mdToHtml $mdFile
  rm $mdFile
done
mv /tmp/$NAME/* $NAME.docset/Contents/Resources/Documents/


# @todo
# css
# index ?
# ancres commonmark ??
# icon

# tar zcf docset
