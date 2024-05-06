#!/bin/bash

# Database credentials
DB_USER="root"
DB_PASS=""
DB_NAME="pricetracker"

# Function to generate a new product ID
generateProductID() {
    max_product_id=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT MAX(productID) FROM products;")
    if [ -z "$max_product_id" ] || [ "$max_product_id" == "NULL" ]; then
        new_product_id="P001"
    else
        current_number=$(echo "$max_product_id" | tail -n 1 | sed 's/P//')
        if [ -z "$current_number" ]; then
            new_product_id="P001"
        else
            new_number=$((10#$current_number + 1))
            new_product_id="P$(printf "%03d" "$new_number")"
        fi
    fi
    echo "$new_product_id"
}

# Function to generate a new details ID
generateDetailsID() {
    max_details_id=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT MAX(detailsID) FROM productdetails;")
    if [ -z "$max_details_id" ] || [ "$max_details_id" == "NULL" ]; then
        new_details_id="D001"
    else
        current_number=$(echo "$max_details_id" | grep -o '[0-9]*')
        new_number=$((10#$current_number + 1))
        new_details_id="D$(printf "%03d" "$new_number")"
    fi
    echo "$new_details_id"
}

# Function to generate a new track ID
generateTrackID() {
    max_track_id=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT MAX(trackID) FROM trackdetails;")
    if [ -z "$max_track_id" ] || [ "$max_track_id" == "NULL" ]; then
        new_track_id="T001"
    else
        current_number=$(echo "$max_track_id" | grep -o '[0-9]*')
        new_number=$((10#$current_number + 1))
        new_track_id="T$(printf "%03d" "$new_number")"
    fi
    echo "$new_track_id"
}



# 4. Insert Data into Database
insert_data() {
    table=$1
    columns=$2
    values=$3

    # MySQL command to insert data into the specified table
    echo "Inserting data into the table $table"
    query="INSERT INTO $table ($columns) VALUES ($values);"
    error=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$query" 2>&1 > /dev/null)
    if [ ! -z "$error" ]; then
        echo "Error inserting into $table: $error"
    else
        echo "Data inserted successfully into $table."
    fi
}

insertIntoDatabase() {
    product_name="$1"
    price="$2"
    stock="$3"
    category="$4"
    product_url="$5"

    # Get the current datetime
    current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

    # Generate new product ID
    new_product_id=$(generateProductID)
    new_details_id=$(generateDetailsID)
    new_track_id=$(generateTrackID)

    # Insert data into the products table
    insert_data "products" "productID, productName, category, URL" "'$new_product_id', '$product_name', '$category', '$product_url'"

    # Insert data into the trackdetails table
    insert_data "trackdetails" "trackID, price, stock, dateCollected" "'$new_track_id', $price, $stock, '$current_datetime'"

    # Insert data into the productdetails table
    insert_data "productdetails" "detailsID, productID, trackID" "'$new_details_id', '$new_product_id', '$new_track_id'"
}


# 3. Data Manipulation (Data manipulation complexity, such as arranging data to array, converting to number or date, etc)
dataManipulation() {
    local product_name="$1"
    local price="$2"
    local stock="$3"
    local category="$4"
    local product_url="$5"
    
    # Convert price to a float if it's not already
    price=$(printf "%.2f" "$price")
    
    # Ensure stock is an integer
    stock=$(printf "%d" "$stock")
    
    echo "Manipulated Data: Product: $product_name, Price: RM$price, Stock: $stock, Category: $category"
    insertIntoDatabase "$product_name" "$price" "$stock" "$category" "$product_url"
}

# 2. Parsing Data (Data parsing complexity - Getting the right data and cleaning them)
parseData() {
    local file="$1"
    local product_name="$2"
    local product_url="$3"
    
    # Parse price
    price=$(grep -oP 'product:price:amount" content="\K[\d.]+' "$file")

    # Parse stock
    stock=$(awk 'BEGIN{RS="<"; FS=">"; IGNORECASE=1} /class="product_qty_availble"/ && !found {print $2; found=1}' "$file" | grep -oP '\d+' | head -n 1 | tr -d '\n')

    # Parse category
    category=$(grep -oP 'property="product:category" content="\K[^"]+' "$file")
    
    echo "Parsed Data: Product: $product_name, Price: RM$price, Stock: $stock, Category: $category"
    dataManipulation "$product_name" "$price" "$stock" "$category" "$product_url"
}



# 1. Fetching Web Data

# List of product URLs to track
PRODUCT_URLS=(
    "https://www.jsshoppu.com/showproducts/productid/4312336/cid/448063/laundry-cleaner-detergent-paper-tablet-pembersih-baju-%E6%B4%97%E8%A1%A3%E7%BA%B8-%E6%B3%A1%E6%B3%A1%E7%BA%B8/",
    "https://www.jsshoppu.com/showproducts/productid/4312047/cid/448063/seamless-wall-hanging-mop-hook-bathroom-broom-hanger-%E5%BC%BA%E5%8A%9B%E6%97%A0%E7%97%95%E6%8B%96%E6%8A%8A%E5%A4%B9-%E5%85%8D%E6%89%93%E5%AD%94%E6%8C%82%E6%89%AB%E6%8A%8A%E6%9E%B6-1-pc/",
    "https://www.jsshoppu.com/showproducts/productid/4308930/cid/448063/simple-towel-hanger-towel-holder-pemegang-tuala-rak-tuala-%E6%AF%9B%E5%B7%BE%E6%9E%B6/",
    "https://www.jsshoppu.com/showproducts/productid/4308972/cid/448063/creative-2l-gradient-frosted-colorful-scale-straw-portable-water-bottle-%E6%B8%90%E5%8F%98%E8%89%B2%E7%A3%A8%E7%A0%82%E7%82%AB%E5%BD%A9%E5%88%BB%E5%BA%A6%E5%90%B8%E7%AE%A1%E4%BE%BF%E6%90%BA%E6%B0%B4%E7%93%B6/",
    "https://www.jsshoppu.com/showproducts/productid/4312065/cid/448063/super-clean-gel-compound-cleaning-gel-jelly-dust-cleaning-80g%E5%8D%A4/"
)

for URL in "${PRODUCT_URLS[@]}"; do
    PRODUCT_NAME=$(echo "$URL" | awk -F '/' '{print $(NF-1)}' | cut -c1-30)

    OUTPUT_FILE="${PRODUCT_NAME}_page.html"
    curl -s "$URL" -o "$OUTPUT_FILE"

    # Check if curl succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to fetch data from $URL"
        continue
    fi

    echo "Web data successfully fetched and saved to $OUTPUT_FILE"
    parseData "$OUTPUT_FILE" "$PRODUCT_NAME" "$URL" 
done


# 5. Crontab setup

## Error handling, such as what if network is down or the website itself is down while the script is running, or what if the website blocks your script 