#!/bin/bash
# /app/deploy.sh
# Dockerized version

REPO_DIR="/app/repo"
# The shared volume is mounted at /data
# Nginx expects to serve /data/public
BASE_OUTPUT="/data"
PUBLIC_DIR="$BASE_OUTPUT/public"
PUBLIC_NEW="$BASE_OUTPUT/public_new"
PUBLIC_OLD="$BASE_OUTPUT/public_old"

WEB_EXPORT="$REPO_DIR/export/web"
BOOK_PDF="$REPO_DIR/export/Receptbok.pdf"
BOOK_EPUB="$REPO_DIR/export/Receptbok.epub"

# Ensure we are in the repo
cd "$REPO_DIR" || { echo "ERROR: Could not cd to $REPO_DIR"; exit 1; }

# 1. Check for updates
git fetch origin main

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/main)

# Force build on first run if output doesn't exist
if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ -d "$PUBLIC_DIR" ]; then
    echo "No changes detected and site exists."
    exit 0
fi

echo "Updates found or initial build! Pulling..."
git reset --hard origin/main
git pull --ff-only

# Gather git info
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_SUBJECT=$(git log -1 --pretty=%s)
BUILD_DATE=$(date '+%Y-%m-%d %H:%M')

echo "Building version $COMMIT_HASH..."

# 3. Build Web
# In Docker, we rely on the scripts being in the container or repo
# The repo scripts might need the container tools.
# We map the scripts from /app if they are helpers, or use repo ones.
# Repo scripts:
if [ -f "./create_web.sh" ]; then
    chmod +x ./create_web.sh
    ./create_web.sh
elif [ -f "/app/create_web.sh" ]; then
    # Fallback to baked-in script if repo doesn't have it yet
    cd /app && ./create_web.sh && cd "$REPO_DIR"
    # Move output if it was generated in /app/export
    if [ -d "/app/export/web" ]; then
        mkdir -p "$WEB_EXPORT"
        cp -r /app/export/web/* "$WEB_EXPORT/"
    fi
fi

# 4. Build Books (PDF/EPUB)
if [ -f "./create_book.sh" ]; then
    chmod +x ./create_book.sh
    ./create_book.sh
elif [ -f "/app/create_book.sh" ]; then
     cd /app && ./create_book.sh && cd "$REPO_DIR"
     if [ -f "/app/export/Receptbok.pdf" ]; then
        cp /app/export/Receptbok.* "$REPO_DIR/export/"
     fi
fi

# 5. Verify Outputs
if [ ! -f "$WEB_EXPORT/index.html" ]; then
    echo "ERROR: Web export missing index.html"; exit 1;
fi

# 6. Prepare New Public Folder (Atomic Deploy)
rm -rf "$PUBLIC_NEW"
mkdir -p "$PUBLIC_NEW/downloads"

# Copy web files
cp -r "$WEB_EXPORT/"* "$PUBLIC_NEW/"

# Copy books if they exist
[ -f "$BOOK_PDF" ] && cp "$BOOK_PDF" "$PUBLIC_NEW/downloads/"
[ -f "$BOOK_EPUB" ] && cp "$BOOK_EPUB" "$PUBLIC_NEW/downloads/"

# 7. Inject Metadata
TARGET_INDEX="$PUBLIC_NEW/index.html"
MARKER="<!--BUILD_META-->"
INJECT_HTML="<div style='background: #252525; padding: 15px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #333;'>
    <h3 style='margin-top:0; color:#fff; font-size:16px;'>Ladda ner</h3>
    <a href='downloads/Receptbok.pdf' class='download-btn'>📄 Ladda ner PDF</a>
    <a href='downloads/Receptbok.epub' class='download-btn'>📱 Ladda ner EPUB</a>
    <div style='margin-top: 10px; font-size: 12px; color: #888;'>
        Senast uppdaterad: $BUILD_DATE<br>
        Version: $COMMIT_HASH
    </div>
</div>"

if grep -q "$MARKER" "$TARGET_INDEX"; then
    echo "$INJECT_HTML" > /tmp/recept_inject.html
    sed -e "/$MARKER/r /tmp/recept_inject.html" -e "/$MARKER/d" "$TARGET_INDEX" > "$TARGET_INDEX.tmp" && mv "$TARGET_INDEX.tmp" "$TARGET_INDEX"
    rm /tmp/recept_inject.html
fi

# 8. Atomic Swap on Volume
echo "Swapping directories on volume..."
# We are in /data (mapped via BASE_OUTPUT variable logic usually, but here we work on full paths)
# Moves must be atomic on the same filesystem
if [ -d "$PUBLIC_DIR" ]; then
    rm -rf "$PUBLIC_OLD"
    mv "$PUBLIC_DIR" "$PUBLIC_OLD"
fi
mv "$PUBLIC_NEW" "$PUBLIC_DIR"

echo "Deploy complete! $COMMIT_HASH live."
exit 0
