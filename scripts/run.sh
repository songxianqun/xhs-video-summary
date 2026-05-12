#!/bin/bash

URL=$1
if [ -z "$URL" ]; then
    echo "Error: Please provide a Xiaohongshu URL."
    exit 1
fi

echo "1/4 Extracting metadata..."
# Check if python or python3 is available
PYTHON_CMD="python"
if ! command -v $PYTHON_CMD &> /dev/null; then
    PYTHON_CMD="python3"
fi

$PYTHON_CMD ~/.agents/skills/xiaohongshu-extract/scripts/xiaohongshu_extract.py "$URL" --flat-only --output xhs_meta.json

if [ ! -f "xhs_meta.json" ]; then
    echo "Error: Metadata extraction failed."
    exit 1
fi

# Extract video URL using python to handle JSON reliably
VIDEO_URL=$($PYTHON_CMD -c "import json; print(json.load(open('xhs_meta.json')).get('video_stream_url', ''))" 2>/dev/null)

if [ -z "$VIDEO_URL" ]; then
    echo "Error: No video URL found in metadata."
    exit 1
fi

echo "2/4 Downloading video..."
curl -s -L "$VIDEO_URL" -o xhs_temp.mp4

echo "3/4 Extracting audio..."
ffmpeg -i xhs_temp.mp4 -vn -acodec libmp3lame -q:a 2 xhs_temp.mp3 -y -loglevel error

if [ ! -f "xhs_temp.mp3" ]; then
    echo "Error: Audio extraction failed."
    exit 1
fi

echo "4/4 Transcribing audio with Whisper..."
whisper xhs_temp.mp3 --model base --language zh --output_dir . --output_format txt

echo "======================================"
echo "Done! Outputs generated:"
echo "- Metadata: xhs_meta.json"
echo "- Transcript: xhs_temp.txt"
