COMP1204 Data Management
Coursework-2 LINUX
Group Members:
No.	Name	University Email
1.	Brandon Ting Wee Kang	bwkt1n22@soton.ac.uk
2.	Pang Jia Hui	jhp1n22@soton.ac.uk

Submitted Documents in ZIP File:
No.	Documents	File Name
1.	Report	DM CW2 – Report.pdf
2.	Scraper/Tracker Script:	product_details_tracker.sh
product_details_graph.sh
3.	Database	pricetracker.sql
4.	Github Repository	https://github.com/brandon-nx/OnlinePromotionStoreTracker 


 
1.0 Introduction
The project is an online store promotion tracker that monitors key data such as pricing, rating, stock availability and number of items sold for products listed on the Shoppu platform. By collecting this data regularly and tracking changes over time, the tracker intends to assist customers in making more informed purchasing decisions. In today's dynamic online business, where prices and promotions change quickly, automated tracking of online store promotions has various advantages over manual monitoring. It allows consumers to identify price trends and promotions easily. Furthermore, the tracker simplifies the decision-making process for customers, allowing them to make quick decisions and act promptly on opportunities to save money. 
 
The project collects data using Unix scripts to ensure that it is collected within a particular period and stored in a MySQL database. Once enough data has been collected, the next step is to produce graphs to visualise trends and analyse patterns in the data, allowing users to track data and make quick decisions about purchasing things on an online platform. 
Overall, the online store promotion tracker is an effective tool for consumers seeking to optimize their online shopping experience by staying up to date with special offers, price variations, and stock reminders on the Shoppu platform. The tracker enables customers to make better purchase decisions and save more money by providing them with fast and accurate information. 
 


 
2.0 Table of Content
1.0 Introduction	2
2.0 Table of Content	3
3.0 Timeline	4
4.0 Database Design	5
5.0 Scraper/Tracker Script (product_details_tracker.sh)	6
5.1 Fetching Web Data	6
5.2 Parsing Data	7
5.3 Data Manipulation	8
5.4 Insert into Database	9
6.0 Contab Setup and Error Handling	11
6.1 Crontab Setup	11
6.2 Error Handling Examples	12
7.0 Plotting Script (product_details_graph.sh)	13
8.0 Conclusion	17
9.0 Appendices	18
 
3.0 Timeline 
  ![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/9b0ee8b6-7a5e-44e5-944b-f35be6325dd2)

4.0 Database Design
 ![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/6b14c91e-88c5-4489-aebc-0fbd262303ec)
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/f5e5de61-d0b0-465a-a40b-ce9c535ad211)

Table ‘productdetails’
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/b7781796-0981-411d-ab88-8e1f2f1566a7)

Table ‘products’
 ![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/c3316360-db21-4a2c-95d4-72d6e7bfe53f)

Table ‘trackdetails’
 ![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/43d2bf86-c778-4866-abd6-598106b0146a)

 
5.0 Scraper/Tracker Script (product_details_tracker.sh)
5.1 Fetching Web Data
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

 
5.2 Parsing Data 
Use tools like grep and awk to extract relevant information from the HTML content.
parseData() {
    local file="$1"
    local product_name="$2"
    local product_url="$3"
    
    # Parse price
    price=$(grep -oP 'product:price:amount" content="\K[\d.]+' "$file")
    if [ -z "$price" ]; then
        echo "Error: Price not found for product: $product_name"
        return 1
    fi

    # Parse stock
    stock=$(awk 'BEGIN{RS="<"; FS=">"; IGNORECASE=1} /class="product_qty_availble"/ && !found {print $2; found=1}' "$file" | grep -oP '\d+' | head -n 1 | tr -d '\n')
    if [ -z "$stock" ]; then
        echo "Error: Stock not found for product: $product_name"
        return 1
    fi

    # Parse category
    category=$(grep -oP 'property="product:category" content="\K[^"]+' "$file")
    if [ -z "$category" ]; then
        echo "Error: Category not found for product: $product_name"
        return 1
    fi
    
    echo "Parsed Data: Product: $product_name, Price: RM$price, Stock: $stock, Category: $category"
    dataManipulation "$product_name" "$price" "$stock" "$category" "$product_url"
}

 
5.3 Data Manipulation
Process and convert extracted data into appropriate formats.
dataManipulation() {
    local product_name="$1"
    local price="$2"
    local stock="$3"
    local category="$4"
    local product_url="$5"
    
    # Check if price is a valid number
    if ! [[ $price =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid price format for product: $product_name"
        return 1
    fi
    
    # Check if stock is a valid integer
    if ! [[ $stock =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid stock format for product: $product_name"
        return 1
    fi
    
    # Convert price to a float if it's not already
    price=$(printf "%.2f" "$price")
    
    # Ensure stock is an integer
    stock=$(printf "%d" "$stock")
    
    echo "Manipulated Data: Product: $product_name, Price: RM$price, Stock: $stock, Category: $category"
    insertIntoDatabase "$product_name" "$price" "$stock" "$category" "$product_url"
}

 
5.4 Insert into Database 
Add MySQL commands to insert collected data into the database, ensuring error handling for database interactions.
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
        if ! insert_data "products" "productID, productName, category, URL" "'$new_product_id', '$product_name', '$category', '$product_url'"; then
            return 1
        fi
    else
        echo "No need to insert product; URL already exists."
        new_product_id=$(getProductIDbyURL "$product_url") # Get existing productID if URL exists
    fi

    # Insert data into the trackdetails table
    new_track_id=$(generateTrackID)
    if ! insert_data "trackdetails" "trackID, price, stock, dateCollected" "'$new_track_id', $price, $stock, '$current_datetime'"; then
        return 1
    fi

    # Insert data into the productdetails table
    new_details_id=$(generateDetailsID)
    if ! insert_data "productdetails" "detailsID, productID, trackID" "'$new_details_id', '$new_product_id', '$new_track_id'"; then
        return 1
    fi
}

}

 
6.0 Contab Setup and Error Handling
6.1 Crontab Setup
 ![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/b09056a5-b18b-4b05-b47e-591260b183db)
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/6efdd79f-7efc-40e3-b8f5-fb2584eef656)
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/76a6a15c-b0fb-4d72-9463-b9ab7c232c69)

6.2 Error Handling Examples
1.	Error handling if data cannot be inserted into the database.
    error=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$query" 2>&1 > /dev/null)
    if [ ! -z "$error" ]; then
        echo "Error inserting into $table: $error"
    else
        echo "Data inserted successfully into $table."
    fi


2.	Error handling if the price is not a valid number.
# Check if price is a valid number
    if ! [[ $price =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid price format for product: $product_name"
        return 1
    fi

3.	Error handling if number of stocks can't be fetched from specific product
# Parse stock
    stock=$(awk 'BEGIN{RS="<"; FS=">"; IGNORECASE=1} /class="product_qty_availble"/ && !found {print $2; found=1}' "$file" | grep -oP '\d+' | head -n 1 | tr -d '\n')
    if [ -z "$stock" ]; then
        echo "Error: Stock not found for product: $product_name"
        return 1
    fi

 
7.0 Plotting Script (product_details_graph.sh)
1.	Price Changes Over Date:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/045947d4-d466-40fb-bf64-d5010dbe0bf6)

2.	Stock Changes Over Date:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/80fd8141-cf6b-4c14-88e7-3b0fbca0caf5)

3.	Hourly Price Trends:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/bf9b37df-c96c-4eb4-a07d-d1856cf6cdf8)

4.	Hourly Stock Trends:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/7255319d-2aad-4ead-b17a-b95cf51c29e3)
 
5.	Price Changes Over Date by Category:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/3cbe2c07-fe22-48a0-a226-8ca3fa813c70)

6.	Stock Changes Over Date by Category:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/073bcfc1-e10c-46e7-8bd4-c3e55b186505)

7.	Average Price by Category Over Date:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/4a59a816-d30e-47f5-842f-c9897ffd13dd)

8.	Average Stock Level by Category Over Date:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/5ea5055f-0bbf-42bc-9c30-fa9c42ed2f45)
 
9.	Bar Chart of Total Stock by Category: 
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/87d9b73b-fd22-4043-bad5-18435cfef239)

10.	Bar Chart of Price Distribution by Category:
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/8766c2fe-11f7-4fd8-8d74-af56b97fccb7)

8.0 Conclusion
To summarise, the online store promotion tracker developed for the Shoppu platform represents a significant development in the field of online shopping platforms. The tracker is an invaluable tool for consumers intending to make informed purchasing decisions because it consistently collects and analyses key data such as pricing, rating, stock availability, and the number of things sold. Throughout this project, we have demonstrated how automated tracking can provide consumers with fast and accurate information on product promotions and pricing patterns. By eliminating the need for manual data collection and analysis, the tracker simplifies consumer decision-making, allowing them to move quickly on opportunities to save money and take advantage of promotional offers. The project also further proved the reliability of Unix scripts for data collection and storage. 

By using Unix scripts to collect data periodically and store it in a MySQL database, we ensure that users have access to the most current information when making purchasing decisions. Furthermore, the implementation of data visualisation techniques like graph plotting enables users to monitor trends pricing patterns and stock availability, allowing them to make intelligent decisions about when to buy, sell, or wait for great deals. Looking ahead, there are various chances for future improvements and expansions to the online store promotion tracker. This involves enhancing data collection techniques, providing support for new online tools, and including features like email notifications for price decreases and stock updates. 

By continuing to innovate and improve the existing structure, we can increase the tracker's utility and efficiency in supporting consumers with their online shopping needs. In conclusion, the online store promotion tracker is a useful tool for consumers wishing to improve their online shopping experience by staying updated about special offers, pricing variations, and stock availability on the Shoppu platform. By providing customers with fast and accurate information, the tracker enables them to make better purchase decisions and save more money.
 
9.0 Appendices
![image](https://github.com/brandon-nx/OnlinePromotionStoreTracker/assets/139194109/5ea12cd1-d1e7-47dc-9aab-1c893683e932)
 
fake_product_page.html 
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Product Page</title>
</head>
<body>
    <div class="product-details">
        <span class="price" data-price="1300.50">RM1300.50898</span>
        <div class="stock-info" data-stock="20">20 units available.</div>
        <div class="ratings" data-rating="4.7">Rated 4.7 out of 5 stars</div>
    </div>
</body>
</html>


test_parseDataAndDataManipulation.sh
#!/bin/bash

# Function to parse data
parseData() {
    local file="$1"
    local product_name="$2"
    
    # Parse price from the new format
    price=$(grep -oP 'class="price" data-price="\K[\d.]+' "$file")
    
    # Parse stock from the new format
    stock=$(grep -oP 'class="stock-info" data-stock="\K[\d.]+' "$file")
    
    # Parse rating from the new format
    rating=$(grep -oP 'class="ratings" data-rating="\K[\d.]+' "$file")
    
    echo "Parsed Data: Price: RM$price, Stock: $stock units, Rating: $rating stars"
    dataManipulation "$product_name" "$price" "$stock" "$rating"
}

# Function to manipulate data
dataManipulation() {
    local product_name="$1"
    local price="$2"
    local stock="$3"
    local rating="$4"
    
    # Convert price to a float
    price=$(printf "%.2f" "$price")
    
    # Ensure stock is an integer
    stock=$(printf "%d" "$stock")
    
    # Convert rating to one decimal place
    rating=$(printf "%.1f" "$rating")
    
    echo "Manipulated Data: Product: $product_name, Price: RM$price, Stock: $stock units, Rating: $rating stars"
}

# Testing the parseData function with the new HTML file format
echo "Testing parseData function..."
parseData "fake_product_page.html" "Smartphone Galaxy S22 Ultra"


