#!/bin/bash

# Define the fallback quote immediately
fallback_quote="<b>\"Of what use is a philosopher who does not hurt anyone's feelings?\" ~ Diogenes of Sinope</b>"

# If curl or jq are missing, instantly print the fallback and exit
if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "$fallback_quote"
    exit 0
fi

# Fetch with a strict 2-second timeout
fetch_response=$(curl -s -m 2 "https://dummyjson.com/quotes/random")

# If curl succeeds and we get data
if [ $? -eq 0 ] && [ -n "$fetch_response" ]; then
    quote_text=$(echo "$fetch_response" | jq -r '.quote')
    quote_author=$(echo "$fetch_response" | jq -r '.author')

    # Ensure jq actually parsed something valid
    if [ -n "$quote_text" ] && [ "$quote_text" != "null" ]; then
        echo "<b>\"${quote_text}\" ~ ${quote_author}</b>"
        exit 0
    fi
fi

# If anything above fails or times out, print the fallback
echo "$fallback_quote"
