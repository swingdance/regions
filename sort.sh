#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo -e "\nThe entity type is required, plase choose one below:\n" \
  "  - r or region\n" \
  "  - c or city\n"
  exit 1
fi
readonly ENTITY_TYPE=$1
readonly REGION=$2

tmp=$(mktemp)
echo

# Sort regions.csv
if [ "$ENTITY_TYPE" = "r" ] || [ "$ENTITY_TYPE" = "region" ]; then
  readonly FILE="regions.csv"
  readonly CSV_SORT_COLUMNS="continent,key"
  echo -e "Start reordering file: $FILE ($CSV_SORT_COLUMNS)\n"
  # Error Case: RuntimeWarning: Error sniffing CSV dialect: Could not determine delimiter
  # Solution: https://csvkit.readthedocs.io/en/1.0.0/tricks.html
  csvsort -I --snifflimit 0 -d ',' -q '"' -S -I --blanks -c "$CSV_SORT_COLUMNS" "$FILE" > "$tmp" && mv "$tmp" "$FILE"

# Sort /city/*.csv
elif [ "$ENTITY_TYPE" = "c" ] || [ "$ENTITY_TYPE" = "city" ]; then
  readonly CSV_SORT_COLUMNS="pr,key"
  readonly FOLDER="city"
  
  if [ -n "$REGION" ]; then
    readonly FILE="$FOLDER/$REGION.csv"
    if [ ! -f "$FILE" ]; then
      echo -e "\n::error:: File not found: $FILE\n"
      exit 1
    fi
    echo -e "Start reordering file: $FILE ($CSV_SORT_COLUMNS)"
    csv_query_statement="SELECT * FROM $REGION ORDER BY pr DESC, key ASC"
    csvsql --snifflimit 0 -d ',' -q '"' -S -I --blanks --query "$csv_query_statement" "$FILE" > "$tmp" && mv "$tmp" "$FILE"
    # csvsort -I --snifflimit 0 -d ',' -q '"' -S -I --blanks -c "$CSV_SORT_COLUMNS" "$FILE" > "$tmp" && mv "$tmp" "$FILE"

  else    
    echo -e "Start reordering files: /$FOLDER/*.csv ($CSV_SORT_COLUMNS)"
    while read -r csv_file; do
      echo "- $csv_file"
      table="$(basename "$csv_file" ".csv")"
      csv_query_statement="SELECT * FROM $table ORDER BY pr DESC, key ASC"
      csvsql --snifflimit 0 -d ',' -q '"' -S -I --blanks --query "$csv_query_statement" "$csv_file" > "$tmp" && mv "$tmp" "$csv_file"
      # csvsort -I --snifflimit 0 -d ',' -q '"' -S -I --blanks -c "$CSV_SORT_COLUMNS" "$csv_file" > "$tmp" && mv "$tmp" "$csv_file"
    done < <(find "$FOLDER" -name "*.csv" -type f | sort)
  fi

else
  echo -e "\n::error:: Unknown entity type: $ENTITY_TYPE, plase choose one below:\n" \
  "  - r or region\n" \
  "  - c or city\n"
  exit 1
fi

echo -e "\nDone.\n"
