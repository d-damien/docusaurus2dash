#!/bin/bash
# Generate Kapeli Dash docset from https://day.js.org doc
# WIP

# Edit variables
NAME='DayJS'
REPO='https://github.com/dayjs/dayjs-website'
FOLDER='dayjs-website'

function checkDependencies() {
  dependencies=(git jq perl pandoc sqlite3 tar)
  for dep in ${dependencies[@]}; do
    hash $dep || exit 1
  done
}

function cleanup() {
  rm -rf $NAME.docset /tmp/$NAME
}

function setupBasicFiles() {
  [ -d $FOLDER ] || git clone $REPO
  mkdir -p $NAME.docset/Contents/Resources/Documents/
  mkdir /tmp/$NAME/
  cp -r $FOLDER/docs/* style.css /tmp/$NAME/
}

# extract title from header
function fileTitle() {
  perl -0777 -wnE 'say /---\n[^:]*: [^\n]*\n[^:]*: [^\n]*\n---/g' $1\
    | grep 'title:'\
    | cut -f  2 -d:\
    | tr -d ' '
}

# convert one md file to html
function mdToHtml() {
  # replace docusaurus ---\n slug \n title \n--- with pandoc markdown title
  perl -0777 -pi -e 's/---\n[^:]*: ([^\n]*)\n[^:]*: ([^\n]*)\n---/\n\n## \2 {#\1}/g' "$1"
  # md -> html
  outputFile=${1%.md}.html
  pandoc -f markdown -t html --quiet\
    --metadata pagetitle="$(fileTitle $1)"\
    -o $outputFile "$1"
  # css
  echo -e "<link href='../style.css' rel='stylesheet'>\n" >> $outputFile
}


function indexFiles() {
  echo "# $NAME : table of contents" > /tmp/$NAME/index.md

  # index DB
  sqlite3 $NAME.docset/Contents/Resources/docSet.dsidx '
    CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
    CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
  '
  # ordered categories
  IFS="
  "
  categories=$(jq -r '.docs | keys_unsorted | .[]' < $FOLDER/website/sidebars.json)

  # index.md + sqlite index
  for cat in ${categories[@]}; do
    echo -e "\n## $cat" >> /tmp/$NAME/index.md
    echo "debug" $cat ".docs[\"$cat\"]"
    for subCatFile in $(jq -r ".docs[\"$cat\"] | .[]" < $FOLDER/website/sidebars.json); do
      subCatTitle=$(fileTitle /tmp/$NAME/$subCatFile.md)
      echo Indexing $subCatTitle...

      echo "- [$subCatTitle]($subCatFile.html)" >> /tmp/$NAME/index.md
      indexValues+=",(\"$cat : $subCatTitle\", 'Element', \"$subCatFile.html\")"
    done
  done

  sqlite3 $NAME.docset/Contents/Resources/docSet.dsidx "
    INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ${indexValues#,};
  "
}

function convertFiles() {
  for mdFile in $(find /tmp/$NAME -name "*.md"); do
    echo Converting $mdFile...
    mdToHtml "$mdFile"
    rm "$mdFile"
  done
  mv /tmp/$NAME/* $NAME.docset/Contents/Resources/Documents/
}

function docusaurus2dash() {
  checkDependencies
  cleanup
  setupBasicFiles
  indexFiles
  convertFiles
}

docusaurus2dash


# @todo
# css
# icon

# tar zcf docset
