#!/bin/sh


# Expected format of input-file:
# http://example.com/video1.mp4 http://example.com/cc1.vtt
# http://example.com/video2.mp4 http://example.com/cc2.vtt
# http://example.com/video3.mp4 http://example.com/cc3.vtt


# Ensure that exactly one argument (the file) is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Assign the input file from the argument
INPUT_FILE=$1

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found!"
    exit 1
fi

# Read the input file line by line
COUNTER=1
while IFS=" " read -r VIDEO_URL CC_URL; do
    if [ -n "$VIDEO_URL" ] && [ -n "$CC_URL" ]; then
        # Inform the user which pair we are processing
        echo "Processing pair $COUNTER..."

        # Download the video
        echo "Downloading video from: $VIDEO_URL"
        yt-dlp -o "%(title)s.%(ext)s" -f bestvideo+bestaudio "$VIDEO_URL"
        VIDEO_FILE=$(yt-dlp -g "$VIDEO_URL" | head -n 1 | sed 's/^.*\///;s/\?.*$//')  # Extract filename from URL

        # Download the closed captions
        echo "Downloading closed captions from: $CC_URL"
        yt-dlp -o "%(title)s-en.vtt" "$CC_URL"
        CC_FILE="${VIDEO_FILE%-*}-en.vtt"  # Assuming captions file matches video name pattern

        # Merge video and subtitles
        echo "Merging video and subtitles..."
        ffmpeg -i "$VIDEO_FILE" -i "$CC_FILE" -c copy -c:s mov_text "output_with_subtitles.mp4"

        # Increment the counter
        COUNTER=$((COUNTER + 1))
    else
        echo "Error: Invalid URL pair at line $COUNTER, skipping."
    fi
done < "$INPUT_FILE"


echo "Finished downloading all videos and captions."
