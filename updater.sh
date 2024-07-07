# Credits: ChatGPT
#!/bin/bash

# Define the owner and repository
OWNER="gogo100people"
REPO="devenv"

# Paths to the local version file, configuration file, and .zshrc file
LOCAL_VERSION_FILE="$HOME/.zshhelper/zshhelper.conf"
ZSHRC_FILE="$HOME/.zshrc"
ZSHHELPER_MARKER_START="#ZSHHELPER"
ZSHHELPER_MARKER_END="#ZSHHELPEREND"

# Fetch the latest release version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/$OWNER/$REPO/releases/latest | jq -r '.tag_name')

# Check if the version was retrieved successfully
if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Failed to fetch the latest version of $OWNER/$REPO"
    exit 1
fi

# Read the local version
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(grep 'version=' "$LOCAL_VERSION_FILE" | cut -d '=' -f2)
else
    echo "Local version file not found. Assuming no local version."
    LOCAL_VERSION="0.0.0"
fi

# Compare versions
if [ "$LOCAL_VERSION" != "$LATEST_VERSION" ]; then
    echo "Updating to version $LATEST_VERSION..."

    # Fetch the download URL for the latest release asset
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$OWNER/$REPO/releases/latest | jq -r '.assets[0].browser_download_url')

    # Check if the download URL was found
    if [ "$DOWNLOAD_URL" = "null" ]; then
        echo "No assets found for the latest release of $OWNER/$REPO"
        exit 1
    fi

    # Download the latest release asset
    TEMP_FILE=$(mktemp)
    curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"

    # Prepare the new content for .zshrc
    ZSHHELPER_CONTENT=$(cat <<EOF
$ZSHHELPER_MARKER_START
source $TEMP_FILE
$ZSHHELPER_MARKER_END
EOF
)

    # Check if markers exist in .zshrc
    if grep -q "$ZSHHELPER_MARKER_START" "$ZSHRC_FILE"; then
        # Update the content between the markers
        sed -i "/$ZSHHELPER_MARKER_START/,/$ZSHHELPER_MARKER_END/c\\
$ZSHHELPER_CONTENT
" "$ZSHRC_FILE"
    else
        # Append the content at the end of .zshrc
        echo -e "\n$ZSHHELPER_CONTENT" >> "$ZSHRC_FILE"
    fi

    # Update the local version file
    mkdir -p "$(dirname "$LOCAL_VERSION_FILE")"
    echo "version=$LATEST_VERSION" > "$LOCAL_VERSION_FILE"

    echo "Updated to version $LATEST_VERSION successfully."
else
    echo "Already up-to-date with version $LATEST_VERSION."
fi
# Credits: ChatGPT