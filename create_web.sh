#!/bin/bash
# create_web.sh - Generates Static Website from recipes

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECEPT_DIR="$ROOT_DIR/recept"
OUTPUT_DIR="$ROOT_DIR/export/web"

mkdir -p "$OUTPUT_DIR/recipes"
mkdir -p "$OUTPUT_DIR/assets"

# HTML Header/Footer templates
HEADER='<!DOCTYPE html>
<html lang="sv">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recept | TITLE_PLACEHOLDER</title>
    <!-- iOS support -->
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <link rel="apple-touch-icon" href="/assets/icon-180.png">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #1a1a1a; color: #e0e0e0; margin: 0; padding: 20px; line-height: 1.6; }
        h1 { color: #fff; border-bottom: 2px solid #333; padding-bottom: 10px; }
        a { color: #4da6ff; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .back-link { display: inline-block; margin-bottom: 20px; color: #888; }
        .content { max-width: 800px; margin: 0 auto; }
        img { max-width: 100%; height: auto; border-radius: 8px; }
        ul, ol { padding-left: 20px; }
        li { margin-bottom: 5px; }
    </style>
</head>
<body>
<div class="content">
<a href="/" class="back-link">← Tillbaka till menyn</a>
'

FOOTER='
</div>
</body>
</html>
'

# Generate Index
INDEX_FILE="$OUTPUT_DIR/index.html"
cat > "$INDEX_FILE" <<EOF
<!DOCTYPE html>
<html lang="sv">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receptbok</title>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="Recept">
    <link rel="apple-touch-icon" href="assets/icon-180.png">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #1a1a1a; color: #e0e0e0; margin: 0; padding: 20px; }
        h1 { text-align: center; color: #fff; margin-bottom: 30px; }
        h2 { color: #888; border-bottom: 1px solid #333; margin-top: 30px; }
        ul { list-style: none; padding: 0; }
        li { margin-bottom: 15px; background: #252525; padding: 15px; border-radius: 8px; }
        a { color: #fff; text-decoration: none; display: block; font-size: 18px; font-weight: 500; }
        .download-btn { display: inline-block; padding: 10px 15px; background: #007aff; color: white; text-decoration: none; border-radius: 8px; margin-right: 10px; margin-bottom: 10px; font-size: 14px; }
        .meta-section { text-align: center; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Mina Recept</h1>
    
    <!--BUILD_META-->

    <div id="recipe-list">
EOF

# Function to process a directory
process_dir() {
    local dir_name="$1"
    local dir_path="$RECEPT_DIR/$dir_name"
    
    [ -d "$dir_path" ] || return 0
     if ! ls "$dir_path"/*.md >/dev/null 2>&1; then return 0; fi

    local display_title="$(echo "$dir_name" | tr '[:lower:]' '[:upper:]' | sed 's/MAINS/HUVUDRÄTTER/; s/BREAKFAST/FRUKOST/; s/SIDES/TILLBEHÖR/; s/SAUCES/SÅSER/; s/SALADS/SALLADER/; s/BAKING/BAKNING/; s/DESSERTS/EFTERRÄTTER/; s/DRINKS/DRYCK/; s/SNACKS/SNACKS/')"

    echo "<h2>$display_title</h2><ul>" >> "$INDEX_FILE"

    for f in "$dir_path"/*.md; do
        filename=$(basename "$f")
        name="${filename%.*}"
        title=$(head -n 1 "$f" | sed 's/^# //')
        [ -z "$title" ] && title="$name"

        # Output HTML file
        out_html="$OUTPUT_DIR/recipes/${dir_name}_${name}.html"
        
        # Convert MD to HTML body
        body_content=$(pandoc "$f" -f markdown -t html)
        
        # Write full HTML
        echo "${HEADER/TITLE_PLACEHOLDER/$title}" > "$out_html"
        echo "$body_content" >> "$out_html"
        echo "$FOOTER" >> "$out_html"

        # Add link to index
        echo "<li><a href=\"recipes/${dir_name}_${name}.html\">$title</a></li>" >> "$INDEX_FILE"
    done
    echo "</ul>" >> "$INDEX_FILE"
}

# Process specific order
process_dir "breakfast"
process_dir "mains"
process_dir "sides"
process_dir "sauces"
process_dir "salads"
process_dir "soups"
process_dir "baking"
process_dir "desserts"
process_dir "drinks"
process_dir "snacks"

# Close Index
cat >> "$INDEX_FILE" <<EOF
    </div>
</body>
</html>
EOF

echo "Web build complete."
