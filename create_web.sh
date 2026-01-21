#!/bin/bash
# create_web.sh - Simulates the static site generation

# Output directory
OUTPUT_DIR="export/web"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/assets"

# Create a sample index.html with the required marker
cat > "$OUTPUT_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="sv">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receptbok</title>
    <!-- iOS support -->
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="Recept">
    <link rel="apple-touch-icon" href="assets/icon-180.png">
    
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #1a1a1a; color: #e0e0e0; margin: 0; padding: 20px; }
        h1 { color: #fff; }
        .recipe-list { margin-top: 20px; }
        .download-btn { display: inline-block; padding: 10px 15px; background: #007aff; color: white; text-decoration: none; border-radius: 8px; margin-right: 10px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1>Mina Recept</h1>
    
    <!--BUILD_META-->

    <div class="recipe-list">
        <p>Här kommer recepten...</p>
        <ul>
            <li><a href="#" style="color: #4da6ff;">Pannkakor</a></li>
            <li><a href="#" style="color: #4da6ff;">Köttbullar</a></li>
        </ul>
    </div>
</body>
</html>
EOF

echo "Web build complete in $OUTPUT_DIR"
