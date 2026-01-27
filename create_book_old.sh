#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$ROOT_DIR/export"
TMP_BOOK="$OUT_DIR/Receptbok_merged.md"
TAGS_TMP="$OUT_DIR/_tags_tmp.txt"

mkdir -p "$OUT_DIR"
export LC_ALL=C
export PATH="/Library/TeX/texbin:$PATH"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/å/a/g; s/ä/a/g; s/ö/o/g' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

get_title_from_h1() {
  local file="$1"
  awk '
    /^# / {
      line=$0
      sub(/^# /, "", line)
      print line
      exit
    }
  ' "$file"
}

get_tags_from_frontmatter() {
  local file="$1"
  awk '
    BEGIN { inFM=0 }
    NR==1 && $0=="---" { inFM=1; next }
    inFM==1 && $0=="---" { exit }
    inFM==1 && $0 ~ /^tags:/ {
      gsub(/^tags:[ ]*/, "", $0)
      gsub(/[\[\]]/, "", $0)
      gsub(/,/, " ", $0)
      gsub(/[ ]+/, " ", $0)
      print $0
      exit
    }
  ' "$file" || true
}

append_body_clean() {
  local file="$1"
  awk '
    BEGIN { inFM=0; removedH1=0 }

    NR==1 && $0=="---" { inFM=1; next }
    inFM==1 && $0=="---" { inFM=0; next }
    inFM==1 { next }

    /^# / && removedH1==0 { removedH1=1; next }

    { print }
  ' "$file"
}

append_category_dir() {
  local category_title="$1"
  local category_dir="$2"

  [ -d "$ROOT_DIR/$category_dir" ] || return 0

  if ! find "$ROOT_DIR/$category_dir" -maxdepth 1 -type f -name "*.md" | grep -q .; then
    return 0
  fi

  echo "# $category_title" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"

  while IFS= read -r f; do
    [ -e "$f" ] || continue

    title="$(get_title_from_h1 "$f")"
    if [ -z "$title" ]; then
      title="$(basename "$f" .md | tr '_' ' ' | tr '-' ' ')"
    fi

    recipe_id="${category_dir}-$(slugify "$title")"

    echo "## $title {#$recipe_id}" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"

    append_body_clean "$f" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"
    echo "---" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"
  done < <(find "$ROOT_DIR/$category_dir" -maxdepth 1 -type f -name "*.md" | sort)

  echo "" >> "$TMP_BOOK"
}

# ------------------------------------------------------------
# Build header
# ------------------------------------------------------------
cat > "$TMP_BOOK" <<EOF
% Receptbok
% RAG
% Uppdaterad: $(date +%Y-%m-%d)

EOF

# ------------------------------------------------------------
# Collect tags into a temp file:
# Format: tag|[Title](#id)
# ------------------------------------------------------------
: > "$TAGS_TMP"

collect_tags_from_dir() {
  local category_dir="$1"
  [ -d "$ROOT_DIR/$category_dir" ] || return 0

  while IFS= read -r f; do
    [ -e "$f" ] || continue

    title="$(get_title_from_h1 "$f")"
    if [ -z "$title" ]; then
      title="$(basename "$f" .md | tr '_' ' ' | tr '-' ' ')"
    fi

    recipe_id="${category_dir}-$(slugify "$title")"
    link="[$title](#$recipe_id)"

    tags="$(get_tags_from_frontmatter "$f" || true)"
    if [ -n "$tags" ]; then
      echo "$tags" | tr ' ' '\n' | sed '/^$/d' | while IFS= read -r t; do
        t="$(echo "$t" | sed 's/^ *//; s/ *$//')"
        t="$(echo "$t" | tr '[:upper:]' '[:lower:]')"
        [ -z "$t" ] && continue
        echo "${t}|${link}" >> "$TAGS_TMP"
      done
    fi
  done < <(find "$ROOT_DIR/$category_dir" -maxdepth 1 -type f -name "*.md" | sort)
}

STANDARD_DIRS="breakfast mains sides sauces salads soups baking desserts drinks snacks"

for d in $STANDARD_DIRS; do
  collect_tags_from_dir "$d"
done

# Extra mappar
KNOWN_DIRS="breakfast mains sides sauces salads soups baking desserts drinks snacks export"

EXTRA_DIRS=$(find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "." -exec basename {} \; | sort)
for d in $EXTRA_DIRS; do
  if echo " $KNOWN_DIRS " | grep -q " $d "; then
    continue
  fi
  collect_tags_from_dir "$d"
done

# ------------------------------------------------------------
# Write Tag index (if tags exist)
# ------------------------------------------------------------
if [ -s "$TAGS_TMP" ]; then
  echo "# Taggar" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"
  echo "_Klicka för att hoppa till recept._" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"

  # Sort by tag then link
  sort -u "$TAGS_TMP" | awk -F'|' '
    BEGIN { current="" }
    {
      tag=$1
      link=$2
      if (tag != current) {
        if (current != "") print ""
        print "## " tag
        print ""
        current = tag
      }
      print "- " link
    }
  ' >> "$TMP_BOOK"

  echo "" >> "$TMP_BOOK"
  echo "---" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"
fi

# ------------------------------------------------------------
# Categories in preferred order
# ------------------------------------------------------------
append_category_dir "Frukost"            "breakfast"
append_category_dir "Huvudrätter"        "mains"
append_category_dir "Tillbehör"          "sides"
append_category_dir "Såser & Dressing"   "sauces"
append_category_dir "Sallader"           "salads"
append_category_dir "Soppor"             "soups"
append_category_dir "Bakning"            "baking"
append_category_dir "Dessert"            "desserts"
append_category_dir "Dryck"              "drinks"
append_category_dir "Snacks"             "snacks"

# Extra mappar under Övrigt (om de har .md)
EXTRA_DIRS_FILTERED=""
for d in $EXTRA_DIRS; do
  if echo " $KNOWN_DIRS " | grep -q " $d "; then
    continue
  fi
  if find "$ROOT_DIR/$d" -maxdepth 1 -type f -name "*.md" | grep -q .; then
    EXTRA_DIRS_FILTERED="$EXTRA_DIRS_FILTERED $d"
  fi
done

if [ -n "$EXTRA_DIRS_FILTERED" ]; then
  echo "# Övrigt" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"
  for d in $EXTRA_DIRS_FILTERED; do
    TITLE="$(echo "$d" | tr '_' ' ' | tr '-' ' ')"
    append_category_dir "$TITLE" "$d"
  done
fi

echo "✅ Merged markdown created: $TMP_BOOK"

# ------------------------------------------------------------
# Export
# ------------------------------------------------------------

# PDF (kräver xelatex + pdf_style.tex)
pandoc "$TMP_BOOK" \
  -o "$OUT_DIR/Receptbok.pdf" \
  --toc \
  --toc-depth=2 \
  --pdf-engine=xelatex \
  --include-in-header="$ROOT_DIR/pdf_style.tex"

echo "✅ PDF created: $OUT_DIR/Receptbok.pdf"

# EPUB
pandoc "$TMP_BOOK" \
  -o "$OUT_DIR/Receptbok.epub" \
  --toc \
  --toc-depth=2 \
  --metadata title="Receptbok"

echo "✅ EPUB created: $OUT_DIR/Receptbok.epub"
echo "🎉 Done! Files are in: $OUT_DIR"
