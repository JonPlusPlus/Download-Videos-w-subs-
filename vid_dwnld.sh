#!/bin/sh

# CSV file
CSV_FILE="$1"

# Set UTF-8 locale (for glibc-based distros)
export LC_ALL=C.UTF-8

#Check yt-dlp is installed
if ! which yt-dlp > /dev/null; then
        printf "\n\n\033[1;33mNOTICE: \033[0mThis script uses the third-party 'yt-dlp' package to download your videos.
        \n\033[1;31mERROR: \033[0mThe 'which' binary did not find yt-dlp on your device.
        \n\n\033[38;5;214mTo download and install the package, use your package-manager:
        \n\033[0mLinux: \n
        Agnostic package-managers - 'flatpak install yt-dlp' OR 'sudo snap yt-dlp'\n
        Alpine - sudo apk add yt-dlp\n
        Arch-based distro - 'sudo pacman -S yt-dlp' OR 'yay -S yt-dlp'\n
        Debian-based distro - sudo apt install yt-dlp\n
        Fedora-based distro - 'sudo dnf install yt-dlp' OR 'sudo yum install yt-dlp' OR 'sudo rpm -i yt-dlp'\n
        Gentoo-based distro - 'sudo emerge app-misc/yt-dlp' OR via 'pip'\n
        OpenSUSE-based distro - sudo zypper install yt-dlp\n
        Slackware-based distro - via 'pip'\n

        \nPython (via pip):\n
        python3 -m pip install -U yt-dlp\n

        \nUnix:\n
        FreeBSD - sudo pkg install yt-dlp\n
        NetBSD - sudo pkgin install yt-dlp\n
        MacOS - 'brew install yt-dlp' OR 'sudo port install yt-dlp'\n
        OpenBSD - sudo pkg_add yt-dlp\n

        \nWindows:\n
        Use Windows Subsystems for Linux (WSL)\n"
        exit 1
fi

#If no.args != 1, echo & exit
if [ "$#" -ne 1 ]; then
        printf "Usage: $0 <input_file>\n"
        
        # MY INSERT
        printf "Input CSV File..."
        read CSV_FILE
fi

# Check if the input file exists
if [ ! -f "$CSV_FILE" ]; then
    printf "Error: File '$CSV_FILE' not found!"
    exit 1
fi

# Function to detect awk
detect_awk() {
    if command -v gawk >/dev/null 2>&1; then
        printf "gawk"
    elif command -v awk >/dev/null 2>&1; then
        printf "awk"
    elif command -v busybox >/dev/null 2>&1 && busybox awk >/dev/null 2>&1; then
        printf "busybox awk"
    else
        printf "none"
    fi
}

AWK_CMD=$(detect_awk)

# Abort if awk not found
if [ "$AWK_CMD" = "none" ]; then
    printf "❌ Error: No awk found" >&2
    exit 1
fi

# Warn if not gawk (for UTF-8 handling)
if [ "$AWK_CMD" != "gawk" ]; then
    printf "⚠ Warning: Using $AWK_CMD — UTF-8 support may be limited." >&2
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
