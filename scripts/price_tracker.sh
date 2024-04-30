#!/bin/bash

# 1. Fetching Web Data

# List of product URLs to track
PRODUCT_URLS=(
    "https://www.lazada.com.my/products/smartphone-galaxy-s22-ultra-sale-original-big-sale-2022-65inch-12gb-ram-512gb-rom-android-cellphone-on-sale-5000mah-wifi-bluetooth-5g-smartphone-online-learning-google-game-phone-legal-cell-cellphone-lowest-price-mobile-phone-free-shipping-cod-i3177845655-s19763201563.html"
)

for URL in "${PRODUCT_URLS[@]}"; do
    # Extract a unique identifier from the URL
    PRODUCT_NAME=$(echo "$URL" | awk -F '/' '{print $(NF-1)}')

    # Output file to store the HTML content
    OUTPUT_FILE="${PRODUCT_NAME}_page.html"

    # Fetch the webpage content
    curl -s "$URL" -o "$OUTPUT_FILE"

    # Check if curl succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to fetch data from $URL"
        continue
    fi

    echo "Web data successfully fetched and saved to $OUTPUT_FILE"
done

# 2. Parsing Data (Data parsing complexity - Getting the right data and cleaning them)

# 3. Data Manipulation (Data manipulation complexity, such as arranging data to array, converting to number or date, etc)

# 4. Insert Data into Database

# 5. Crontab setup

## Error handling, such as what if network is down or the website itself is down while the script is running, or what if the website blocks your script 