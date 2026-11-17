#!/usr/bin/env bash

set -euo pipefail

# Configuration
POSTS_DIR="posts"
TEMPLATE="templates/post.html"
CSS_DIR="css"
ASSETS_DIR="assets"
OUTPUT_DIR="."

SITE_TITLE="Notes"
SITE_DESCRIPTION=""

# Check dependencies
if ! command -v pandoc >/dev/null 2>&1; then
    echo "Error: Pandoc is not installed."
    exit 1
fi

# Prepare output directories
mkdir -p "$CSS_DIR"
mkdir -p "images"

# Copy images into the website root
if [ -d "$ASSETS_DIR/images" ]; then
    cp -R "$ASSETS_DIR/images/." "images/"
fi

# Copy CSS into the website
# CSS is already in the repository, so no copy is needed.

# Homepage entries
ENTRIES=""

shopt -s nullglob

for post in "$POSTS_DIR"/*.md; do
    filename=$(basename "$post" .md)
    html_file="$filename.html"

    echo "Converting: $post"

    # Extract title and date from YAML front matter
    title=$(sed -n 's/^title: *//p' "$post" | head -n 1)
    title="${title#\"}"
    title="${title%\"}"

    date_value=$(sed -n 's/^date: *//p' "$post" | head -n 1)
    date_value="${date_value#\"}"
    date_value="${date_value%\"}"

    # Format date
    display_date=$(date -d "$date_value" "+%B %d, %Y" 2>/dev/null || echo "$date_value")

    # Generate standalone HTML article
    pandoc "$post" \
        --standalone \
        --template="$TEMPLATE" \
        --css="css/style.css" \
        --metadata="title:$title" \
        --metadata="date:$display_date" \
        --metadata="date-meta:$date_value" \
        --output="$OUTPUT_DIR/$html_file"

    # Add article to homepage
    ENTRIES+="
                <li>
                    <a href=\"$html_file\">$title</a>
                    <time datetime=\"$date_value\">$display_date</time>
                </li>"
done

# Generate homepage
cat > index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$SITE_TITLE</title>
    <meta name="description" content="$SITE_DESCRIPTION">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <main class="container">
        <header class="home-header">
            <h1>$SITE_TITLE</h1>
            <p>$SITE_DESCRIPTION</p>
        </header>

        <section>
            <h2>Articles</h2>
            <ul class="article-list">
$ENTRIES
            </ul>
        </section>

        <footer class="site-footer">
            <p>&copy; $(date +%Y) $SITE_TITLE</p>
        </footer>
    </main>
</body>
</html>
EOF

echo ""
echo "Website generated successfully!"
echo ""
echo "Generated files:"
echo "  index.html"
for post in "$POSTS_DIR"/*.md; do
    [ -f "$post" ] || continue
    echo "  $(basename "$post" .md).html"
done
echo ""
echo "Images: images/"
echo "Styles: css/"
echo ""
