#!/bin/bash

# Database credentials
DB_USER="root"
DB_PASS=""
DB_NAME="pricetracker"

# Function to check if URL already exists in the database
checkURLExists() {
    url=$1
    exists=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT EXISTS(SELECT 1 FROM products WHERE URL = '$url');")
    echo $exists
}

# Function to get existing product ID by URL
getProductIDbyURL() {
    local url=$1
    local product_id=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT productID FROM products WHERE URL = '$url';")
    echo $product_id
}

# Function to generate a new product ID
generateProductID() {
    local url=$1
    local url_exists=$(checkURLExists "$url")
    if [ "$url_exists" -eq 1 ]; then
        echo "exists"  # Indicates that the URL already exists, no need to generate a new ID
    else
        local max_product_id=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT MAX(productID) FROM products;")
        local new_product_id
        if [ -z "$max_product_id" ] || [ "$max_product_id" == "NULL" ]; then
            new_product_id="P001"
        else
            local current_number=$(echo "$max_product_id" | tail -n 1 | sed 's/P//')
            local new_number=$((10#$current_number + 1))
            new_product_id="P$(printf "%03d" "$new_number")"
        fi
        echo "$new_product_id"
    fi
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

    # Insert data into the products table
    url_exists=$(checkURLExists "$product_url")
    if [ "$url_exists" -eq 0 ]; then
        new_product_id=$(generateProductID)
        # Insert new product if URL does not exist
        insert_data "products" "productID, productName, category, URL" "'$new_product_id', '$product_name', '$category', '$product_url'"
    else
        echo "No need to insert product; URL already exists."
        new_product_id=$(getProductIDbyURL "$product_url") # Get existing productID if URL exists
    fi

    # Insert data into the trackdetails table
    new_track_id=$(generateTrackID)
    insert_data "trackdetails" "trackID, price, stock, dateCollected" "'$new_track_id', $price, $stock, '$current_datetime'"

    # Insert data into the productdetails table
    new_details_id=$(generateDetailsID)
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
    https://www.publicpackaging.com/showproducts/productid/4312040/cid/448076/11pcs-foodgrade-silicone-kitchen-measuring-tools-ready-stock-measuring-spoon/
    https://www.publicpackaging.com/showproducts/productid/4312333/cid/448072/super-clean-gel-compound-cleaning-gel-jelly-dust-cleaning-70g%E5%8D%A4/,
    https://www.publicpackaging.com/showproducts/productid/4312382/cid/448073/dish-wash-pure-colour-pad-2-pcs-in-1-pack/,
    https://www.publicpackaging.com/showproducts/productid/4312283/cid/448072/creative-desktop-shake-lid-mini-trash-bin-%E5%88%9B%E6%84%8F%E6%A1%8C%E9%9D%A2%E6%91%87%E7%9B%96%E8%BF%B7%E4%BD%A0%E5%9E%83%E5%9C%BE%E6%A1%B6/,
    https://www.publicpackaging.com/showproducts/productid/4312254/cid/448073/kitchen-knife-3pcs-set-fruit-knife-pemotong-sayur-dadu-multi-slicer-%E6%B0%B4%E7%9A%AE%E6%B0%B4%E6%9E%9C%E5%88%80%E6%B2%BE%E6%9D%BF%E4%B8%89%E4%BB%B6%E5%A5%97/
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