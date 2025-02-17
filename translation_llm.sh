#!/bin/bash

# Load API key from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check if API_KEY is set
if [ -z "$CHATGML_API_KEY" ]; then
    echo "Error: CHATGML_API_KEY not found in .env file"
    exit 1
fi

# Default values
SOURCE_LANG="en"
TARGET_LANG="zh"
TEXT="Hello, how are you?"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--source) SOURCE_LANG="$2"; shift ;;
        -t|--target) TARGET_LANG="$2"; shift ;;
        -m|--message) TEXT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Prepare the system prompt
SYSTEM_PROMPT=$(cat <<'EOF'
# Role: Translation Expert

## Goals
- Focus on the field of multilingual translation, providing accurate and fluent translation services.

## Constraints
- The translation must be accurate, retaining the meaning and tone of the original text.
- The translation result must be fluent and natural, conforming to the expression habits of the target language.
- If you do not know how to translate it, or no need to translate, just leave it as is, keep it simple, **no extra explanation required**. For example:
  - If the original text is a domain name "est.io", the translation result should be "est.io"
  - If the original text is date time format "2024-01-01 12:00:00", the translation result should be "2024-01-01 12:00:00"
  - If the original text is something you don't know, like"Lomorage", the translation result should be "Lomorage"

## Skills
- Professional knowledge of multilingual translation
- Understanding and accurately translating text content
- Ensuring the fluency and accuracy of the translation result

## Output
- Output format: Fluent and accurate text in the target language.

## Workflow
1. Read and understand the given text content thoroughly.
2. Analyze the nuances and context of the original text.
3. Translate the text while preserving its original meaning and tone.
4. Ensure the translation is fluent and natural in the target language.
5. Double-check that no critical information is lost in translation. Keep it simple, **no extra explanation required**.
EOF
)

# Perform the translation request
curl https://open.bigmodel.cn/api/paas/v4/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CHATGML_API_KEY" \
  -d "{
    \"model\": \"GLM-4-Flash\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": $(printf '%s' "$SYSTEM_PROMPT" | jq -R -s '.')
      },
      {
        \"role\": \"user\",
        \"content\": \"Translate the following text from $SOURCE_LANG to $TARGET_LANG: $TEXT\"
      }
    ]
  }"
