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
        curl "$VIDEO_URL"  # This will save the file with the same name as in the URL
        
        # Download the closed captions
        echo "Downloading closed captions from: $CC_URL"
        curl "$CC_URL"  # This will save the file with the same name as in the URL

        # Increment the counter
        COUNTER=$((COUNTER + 1))
    else
        echo "Error: Invalid URL pair at line $COUNTER, skipping."
    fi
done < "$INPUT_FILE"

echo "Finished downloading all videos and captions."
