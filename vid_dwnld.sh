#!/bin/sh

# CSV file
CSV_FILE="$1"

# Set UTF-8 locale (for glibc-based distros)
export LC_ALL=C.UTF-8

# Function to detect awk
detect_awk() {
    if command -v gawk >/dev/null 2>&1; then
        echo "gawk"
    elif command -v awk >/dev/null 2>&1; then
        echo "awk"
    elif command -v busybox >/dev/null 2>&1 && busybox awk >/dev/null 2>&1; then
        echo "busybox awk"
    else
        echo "none"
    fi
}

AWK_CMD=$(detect_awk)

# Abort if awk not found
if [ "$AWK_CMD" = "none" ]; then
    echo "❌ Error: No awk found" >&2
    exit 1
fi

# Warn if not gawk (for UTF-8 handling)
if [ "$AWK_CMD" != "gawk" ]; then
    echo "⚠ Warning: Using $AWK_CMD — UTF-8 support may be limited." >&2
fi

# Use awk to extract URLs and download with yt-dlp
$AWK_CMD -F',' '
BEGIN {
    COUNTER = 1
}
NR > 1 {  # Skip header row

    # Print counter (for logging)
    printf("📼 Processing video" COUNTER ":\n")

    # Remove quotes from field 1 (assuming URL is in column 1)
    CHAPTER = $1
    NAME = $2
    VIDEO_URL = $3
    CC_URL = $4
    VIDEO = CHAPTER "." COUNTER " VID " NAME ".mp4"
    SUB = CHAPTER "." COUNTER " SUB " NAME ".vtt"
    gsub(/^"|"$/, "", VIDEO_URL)
    gsub(/^"|"$/, "", CC_URL)

    # Build command to download video with yt-dlp
    video_cmd = "yt-dlp -o \"" VIDEO "\" -f bestvideo+bestaudio \"" VIDEO_URL "\""
    print "📥 Downloading:", VIDEO_URL
    system(video_cmd)
    
    # Build command to download subs with yt-dlp
    cc_cmd = "yt-dlp -o \"" SUB "\" \"" CC_URL "\""
    print "📥 Downloading:", CC_URL
    system(cc_cmd)

    # Merge video and subtitles
    print "🔀 Merging " VIDEO " and " SUB " :"
    merge_cmd = "ffmpeg -i \"" VIDEO "\" -i \"" SUB "\" -c copy -c:s mov_text \"" CHAPTER "." COUNTER " "  NAME ".mp4\""
    system(merge_cmd)

    COUNTER++

}
' "$CSV_FILE"
