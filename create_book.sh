#!/bin/bash
# create_book.sh - Generates PDF/EPUB from recipe markdown files
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECEPT_DIR="$ROOT_DIR/recept"  # Changed: Source from recept/ subdir
OUT_DIR="$ROOT_DIR/export"
TMP_BOOK="$OUT_DIR/Receptbok_merged.md"
TAGS_TMP="$OUT_DIR/_tags_tmp.txt"

mkdir -p "$OUT_DIR"
export LC_ALL=C

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/å/a/g; s/ä/a/g; s/ö/o/g' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

get_title_from_h1() {
  local file="$1"
  awk '/^# / { sub(/^# /, ""); print; exit }' "$file"
}

get_tags_from_frontmatter() {
  local file="$1"
  # Simple awk extraction of YAML tags
  awk '
    BEGIN { inFM=0 }
    NR==1 && $0=="---" { inFM=1; next }
    inFM==1 && $0=="---" { exit }
    inFM==1 && $0 ~ /^tags:/ {
      sub(/^tags:[ ]*/, ""); gsub(/[\[\]]/, ""); gsub(/,/, " "); gsub(/[ ]+/, " ");
      print; exit
    }
  ' "$file" || true
}

append_body_clean() {
  local file="$1"
  # Print content, removing YAML frontmatter and the primary H1
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
  local full_path="$RECEPT_DIR/$category_dir"

  [ -d "$full_path" ] || return 0

  # Check if md files exist using ls to avoid find piping issues if empty
  if ! ls "$full_path"/*.md >/dev/null 2>&1; then
    return 0
  fi

  echo "# $category_title" >> "$TMP_BOOK"
  echo "" >> "$TMP_BOOK"

  for f in "$full_path"/*.md; do
    [ -e "$f" ] || continue

    title="$(get_title_from_h1 "$f")"
    [ -z "$title" ] && title="$(basename "$f" .md | tr '_' ' ' | tr '-' ' ')"

    # Make ID unique per category to avoid collisions
    recipe_id="${category_dir}-$(slugify "$title")"

    echo "## $title {#$recipe_id}" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"

    append_body_clean "$f" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"
    echo "---" >> "$TMP_BOOK"
    echo "" >> "$TMP_BOOK"
  done
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
# Process Categories
# ------------------------------------------------------------
# Preferred order
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

# Handle unknown folders in recept/
KNOWN_DIRS="breakfast mains sides sauces salads soups baking desserts drinks snacks"
for d in "$RECEPT_DIR"/*; do
  [ -d "$d" ] || continue
  dirname=$(basename "$d")
  # Use space checking
  if [[ " $KNOWN_DIRS " != *" $dirname "* ]]; then
      TITLE="$(echo "$dirname" | tr '_' ' ' | tr '-' ' ' | tr '[:lower:]' '[:upper:]')"
      append_category_dir "$TITLE" "$dirname"
  fi
done

echo "Merged Markdown created at $TMP_BOOK"

# ------------------------------------------------------------
# Export
# ------------------------------------------------------------

# PDF
# Check if styles exist, else create minimal
if [ ! -f "$ROOT_DIR/pdf_style.tex" ]; then
    touch "$ROOT_DIR/pdf_style.tex"
fi

echo "Generating PDF..."
pandoc "$TMP_BOOK" \
  -o "$OUT_DIR/Receptbok.pdf" \
  --toc \
  --toc-depth=2 \
  --pdf-engine=xelatex \
  --include-in-header="$ROOT_DIR/pdf_style.tex"

echo "Generating EPUB..."
pandoc "$TMP_BOOK" \
  -o "$OUT_DIR/Receptbok.epub" \
  --toc \
  --toc-depth=2 \
  --metadata title="Receptbok"

echo "Book generation complete."
