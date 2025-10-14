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


        # Define the output template and filename
        VIDEO_OUTPUT_TEMPLATE="%(title)s.%(ext)s"

        # Download the video
        echo "Downloading video from: $VIDEO_URL"
        yt-dlp -o "$VIDEO_OUTPUT_TEMPLATE" -f bestvideo+bestaudio "$VIDEO_URL"

        # Extract the actual downloaded filename from the output template
        VIDEO_FILE=$(find . -maxdepth 1 -name "*.mp4" -print | sort -t/ -k2 | tail -n 1)

        echo "Downloaded video file: $VIDEO_FILE"
        

        # Define the output template and filename
        CC_OUTPUT_TEMPLATE="%(title)s-en.vtt"

        # Download the subtitle
        echo "Downloading subtitles video from: $CC_URL"
        yt-dlp -o "$CC_OUTPUT_TEMPLATE" "$CC_URL"

        # Extract the actual downloaded filename from the output template
        CC_FILE=$(find . -maxdepth 1 -name "*.vtt" -print | sort -t/ -k2 | tail -n 1)

        echo "Downloaded subtitles video file: $CC_FILE"


        # Merge video and subtitles
        echo "Merging video and subtitles..."
        ffmpeg -i "$VIDEO_FILE" -i "$CC_FILE" -c copy -c:s mov_text "output_with_subtitles.mp4"

        
        # Increment the counter
        COUNTER=$(expr $COUNTER + 1)
    else
        echo "Error: Invalid URL pair at line $COUNTER, skipping."
    fi
done < "$INPUT_FILE"

echo "Finished downloading all videos and captions."
