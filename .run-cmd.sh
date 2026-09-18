#!/bin/bash
cd /Users/ernest/projects/yt-thumbnail-generator

# Read prompt and pass as single argument
PROMPT=$(<.cmd-prompt.txt)

# Use xargs to ensure single argument
echo "$PROMPT" | xargs -d '\n' cmd -y
