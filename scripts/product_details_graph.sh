#!/bin/bash
# Database credentials
DB_USER="root"
DB_PASS=""
DB_NAME="pricetracker"

# Get all unique productIDs from productdetails table
product_ids=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT DISTINCT productID FROM productdetails;")

# Define output directory for the graphs
mkdir -p data_files
mkdir -p graphs
mkdir -p gp_files
GP_OUTDIR="gp_files"

plotPriceGraph() {
    # Define output directory for price data
    local PRICE_OUTDIR="data_files"

    for product_id in $product_ids; do
        # Define output file for each productID
        local PRICE_OUTFILE="$PRICE_OUTDIR/price_data_${product_id}.dat"

        # Fetch trackID, price, and dateCollected for each productID
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT pd.trackID, td.price, td.dateCollected FROM productdetails pd JOIN trackdetails td ON pd.trackID = td.trackID WHERE pd.productID = '${product_id}';" | while read -r track_id price date_collected; do
            # Format the dateCollected field to mm-dd hh:mm
            formatted_date=$(date -d "$date_collected" +"%m-%d %H:%M")
            echo "$track_id $price $formatted_date"
        done >"$PRICE_OUTFILE"

        echo "Data has been successfully extracted and formatted to $PRICE_OUTFILE"
    done

    local graph_title="$1"
    # Generate Gnuplot command to plot each data file
    local plot_command=""

    for file in $PRICE_OUTDIR/price_data_P*.dat; do
        local product_id=$(echo "$file" | sed -n 's/.*price_data_\(P[0-9]*\)\.dat/\1/p')
        plot_command+=" '$file' using (\$0+1):2 with linespoints title '$product_id',"
    done

    # Remove the last comma from the plot command string
    plot_command=${plot_command%,}

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_price_graph.gp"
    # Write the Gnuplot script
    cat <<EOF >"$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output 'graphs/price_graph.png'
set xlabel 'Date'
set ylabel 'Price'
set title 'Price Changes Over Date'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics ('05-07' 1, '05-08' 3, '05-09' 26, '05-10' 50)
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"

    echo "Graph generated: price_graph.png"
}

plotStockGraph() {
    # Define output directory for stock data
    local STOCK_OUTDIR="data_files"
    for product_id in $product_ids; do
        # Define output file for each productID
        local STOCK_OUTFILE="$STOCK_OUTDIR/stock_data_${product_id}.dat"

        # Fetch trackID, stock, and dateCollected for each productID
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT pd.trackID, td.stock, td.dateCollected FROM productdetails pd JOIN trackdetails td ON pd.trackID = td.trackID WHERE pd.productID = '${product_id}';" | while read -r track_id stock date_collected; do
            # Format the dateCollected field to mm-dd hh:mm
            formatted_date=$(date -d "$date_collected" +"%m-%d %H:%M")
            echo "$track_id $stock $formatted_date"
        done >"$STOCK_OUTFILE"

        echo "Data has been successfully extracted and formatted to $STOCK_OUTFILE"
    done

    local graph_title="$1"

    # Generate Gnuplot command to plot each data file
    local plot_command=""

    for file in $STOCK_OUTDIR/stock_data_P*.dat; do
        # Extract productID from the filename
        product_id=$(echo "$file" | sed -n 's/.*stock_data_\(P[0-9]*\)\.dat/\1/p')

        # Append to the plot command with the proper label
        plot_command+=" '$file' using (\$0+1):2 with linespoints title '$product_id',"
    done
    # Remove the last comma from the plot command string
    plot_command=${plot_command%,}

    # Gnuplot script to plot the graph
    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_stock_graph.gp"

    # Write the Gnuplot script
    cat <<EOF >"$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output 'graphs/stock_graph.png'
set xlabel 'Date'
set ylabel 'Stock'
set title 'Stock Changes Over Date'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics ('05-07' 1, '05-08' 3, '05-09' 26, '05-10' 50)
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"

    echo "Graph generated: stock_graph.png"
}

# Function to extract and format hourly data for price and stock
extractHourlyData() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"

    # Get all unique productIDs from productdetails table
    local product_ids=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT DISTINCT productID FROM productdetails;")
    
    for product_id in $product_ids; do
        local OUTFILE_PRICE="$OUTDIR/hourly_price_data_${product_id}.dat"
        local OUTFILE_STOCK="$OUTDIR/hourly_stock_data_${product_id}.dat"

        # Fetch hourly price and stock data
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT HOUR(td.dateCollected) AS hour, AVG(td.price) AS avg_price, AVG(td.stock) AS avg_stock FROM productdetails pd JOIN trackdetails td ON pd.trackID = td.trackID WHERE pd.productID = '${product_id}' GROUP BY HOUR(td.dateCollected) ORDER BY HOUR(td.dateCollected);" | while read -r hour avg_price avg_stock; do
            echo "$hour $avg_price" >> "$OUTFILE_PRICE"
            echo "$hour $avg_stock" >> "$OUTFILE_STOCK"
        done

        echo "Hourly data extracted and formatted to $OUTFILE_PRICE and $OUTFILE_STOCK"
    done
}

# Function to plot hourly trends for price or stock
plotHourlyGraph() {
    local graph_type="$1" # price or stock
    local title="$2"
    local ylabel="$3"
    local file_prefix="$4"

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_hourly_${graph_type}_graph.gp"
    local plot_command=""

    for file in data_files/hourly_${file_prefix}_data_P*.dat; do
        local product_id=$(echo "$file" | sed -n "s/data_files\/hourly_${file_prefix}_data_\(P[0-9]*\)\.dat/\1/p")
        plot_command+=" '$file' using 1:2 with linespoints title '$product_id',"
    done
    plot_command=${plot_command%,}

    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output 'graphs/hourly_${graph_type}_graph.png'
set xlabel 'Hour of the Day'
set ylabel '$ylabel'
set title '$title'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics (0, 6, 12, 18, 24)
plot $plot_command
EOF

    gnuplot "$GNUPLOT_SCRIPT"
    echo "Graph generated: graphs/hourly_${graph_type}_graph.png"
}

# Function to plot price changes date by category
plotPriceByCategoryGraph() {
    # Define output directory for price data
    local PRICE_OUTDIR="data_files"
    mkdir -p "$PRICE_OUTDIR"

    # Fetch unique categories
    local categories=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT DISTINCT p.category 
    FROM productdetails pd 
    JOIN products p 
    ON pd.productID = p.productID;")

    for category in $categories; do
        # Define output file for each category
        local CATEGORY_OUTFILE="$PRICE_OUTDIR/price_data_${category// /_}.dat"

        # Fetch price data for products in the current category
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
        SELECT pd.trackID, td.price, td.dateCollected
        FROM productdetails pd
        JOIN products p ON pd.productID = p.productID
        JOIN trackdetails td ON pd.trackID = td.trackID
        WHERE p.category = '${category}';" | while read -r track_id price date_collected; do
            # Format the dateCollected field to mm-dd hh:mm
            formatted_date=$(date -d "$date_collected" +"%m-%d %H:%M")
            echo "$track_id $price $formatted_date"
        done > "$CATEGORY_OUTFILE"

        echo "Data has been successfully extracted and formatted to $CATEGORY_OUTFILE"
    done

    local graph_title="Price Changes Over Date by Category"
    # Generate Gnuplot command to plot each data file
    local plot_command=""

    for file in $PRICE_OUTDIR/price_data_*.dat; do
        local category=$(echo "$file" | sed -n 's/.*price_data_\(.*\)\.dat/\1/p' | tr '_' ' ')  # Replace underscores with spaces in category names
        plot_command+=" '$file' using (\$0+1):2 with linespoints title '$category',"
    done

    # Remove the last comma from the plot command string
    plot_command=${plot_command%,}

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_price_by_category_graph.gp"
    # Write the Gnuplot script
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output 'graphs/price_by_category_graph.png'
set xlabel 'Date'
set ylabel 'Price'
set title 'Price Changes Over Date by Category'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics ('05-07' 1, '05-08' 3, '05-09' 26, '05-10' 104)
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"

    echo "Graph generated: price_by_category_graph.png"
}

# Function to extract and format stock data by category
extractStockDataByCategory() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"

    # Fetch unique categories
    local categories=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT DISTINCT p.category 
    FROM productdetails pd 
    JOIN products p 
    ON pd.productID = p.productID;")

    for category in $categories; do
        # Define output file for each category
        local STOCK_OUTFILE="$OUTDIR/stock_data_category_${category// /_}.dat"

        # Fetch stock data for products in the current category
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
        SELECT DATE_FORMAT(td.dateCollected, '%Y-%m-%d %H:%i') AS formatted_date, AVG(td.stock) AS avg_stock
        FROM productdetails pd
        JOIN trackdetails td ON pd.trackID = td.trackID
        JOIN products p ON pd.productID = p.productID
        WHERE p.category = '${category}'
        GROUP BY formatted_date
        ORDER BY formatted_date;" | while read -r date_collected avg_stock; do
            echo "$date_collected $avg_stock"
        done > "$STOCK_OUTFILE"

        echo "Data for stock changes in category '$category' has been extracted to $STOCK_OUTFILE"
    done
}

# Function to plot stock changes by category
plotStockByCategoryGraph() {
    local OUTDIR="data_files"
    local GRAPHDIR="graphs"
    mkdir -p "$GRAPHDIR"

    local plot_command=""

    for file in ${OUTDIR}/stock_data_category_*.dat; do
        local category=$(echo "$file" | sed -n 's/.*stock_data_category_\(.*\)\.dat/\1/p' | tr '_' ' ')  # Replace underscores with spaces in category names
        plot_command+=" '$file' using 1:2 with lines title '$category',"
    done
    plot_command=${plot_command%,}  # Remove the last comma

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_stock_by_category_graph.gp"
    # Write the Gnuplot script
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output '${GRAPHDIR}/stock_by_category_graph.png'
set xlabel 'Date/Time'
set ylabel 'Average Stock Level'
set title 'Stock Changes Over Time by Category'
set xdata time
set timefmt "%Y-%m-%d %H:%i"
set format x "%d-%m-%Y"
set xtics rotate by -45
set grid
set key outside right top vertical Left reverse enhanced autotitles columnhead nobox
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"
    echo "Graph generated: ${GRAPHDIR}/stock_by_category_graph.png"
}

# Function to extract and format average price data by category
extractAveragePriceDataByCategory() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"

    # Fetch unique categories and extract average price data
    local categories=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT DISTINCT p.category 
    FROM productdetails pd 
    JOIN products p 
    ON pd.productID = p.productID;")

    for category in $categories; do
        local PRICE_OUTFILE="$OUTDIR/avg_price_data_${category// /_}.dat"

        # Fetch average price data for each category
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
        SELECT DATE_FORMAT(td.dateCollected, '%Y-%m-%d %H:%i') AS formatted_date, AVG(td.price) AS avg_price
        FROM productdetails pd
        JOIN trackdetails td ON pd.trackID = td.trackID
        JOIN products p ON pd.productID = p.productID
        WHERE p.category = '${category}'
        GROUP BY formatted_date
        ORDER BY formatted_date;" | while read -r date_collected avg_price; do
            echo "$date_collected $avg_price"
        done > "$PRICE_OUTFILE"

        echo "Data for average price changes in category '$category' has been extracted to $PRICE_OUTFILE"
    done
}

# Function to plot average price changes by category
plotAveragePriceByCategoryGraph() {
    local OUTDIR="data_files"
    local GRAPHDIR="graphs"
    mkdir -p "$GRAPHDIR"

    local plot_command=""

    for file in ${OUTDIR}/avg_price_data_*.dat; do
        local category=$(echo "$file" | sed -n 's/.*avg_price_data_\(.*\)\.dat/\1/p' | tr '_' ' ')  # Replace underscores with spaces in category names
        plot_command+=" '$file' using 1:2 with lines title '$category',"
    done
    plot_command=${plot_command%,}  # Remove the last comma

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_avg_price_by_category_graph.gp"
    # Write the Gnuplot script
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output '${GRAPHDIR}/avg_price_by_category_graph.png'
set xlabel 'Date/Time'
set ylabel 'Average Price'
set title 'Average Price by Category Over Date'
set xdata time
set timefmt "%Y-%m-%d %H:%i"
set format x "%d-%m-%Y"
set xtics rotate by -45
set grid
set key outside right top vertical Left reverse enhanced autotitles columnhead nobox
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"
    echo "Graph generated: ${GRAPHDIR}/avg_price_by_category_graph.png"
}

# Function to extract and format average stock level by category
extractAverageStockDataByCategory() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"

    # Fetch unique categories and extract average stock data
    local categories=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT DISTINCT p.category 
    FROM productdetails pd 
    JOIN products p 
    ON pd.productID = p.productID;")

    for category in $categories; do
        local STOCK_OUTFILE="$OUTDIR/avg_stock_data_${category// /_}.dat"

        # Fetch average stock data for each category
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
        SELECT DATE_FORMAT(td.dateCollected, '%Y-%m-%d %H:%i') AS formatted_date, AVG(td.stock) AS avg_stock
        FROM productdetails pd
        JOIN trackdetails td ON pd.trackID = td.trackID
        JOIN products p ON pd.productID = p.productID
        WHERE p.category = '${category}'
        GROUP BY formatted_date
        ORDER BY formatted_date;" | while read -r date_collected avg_stock; do
            echo "$date_collected $avg_stock"
        done > "$STOCK_OUTFILE"

        echo "Data for average stock changes in category '$category' has been extracted to $STOCK_OUTFILE"
    done
}

# Function to plot average stock level by category
plotAverageStockByCategoryGraph() {
    local OUTDIR="data_files"
    local GRAPHDIR="graphs"
    mkdir -p "$GRAPHDIR"

    local plot_command=""

    for file in ${OUTDIR}/avg_stock_data_*.dat; do
        local category=$(echo "$file" | sed -n 's/.*avg_stock_data_\(.*\)\.dat/\1/p' | tr '_' ' ')  # Replace underscores with spaces in category names
        plot_command+=" '$file' using 1:2 with lines title '$category',"
    done
    plot_command=${plot_command%,}  # Remove the last comma

    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_avg_stock_by_category_graph.gp"
    # Write the Gnuplot script
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png font 'Times new roman' size 1400,600
set output '${GRAPHDIR}/avg_stock_by_category_graph.png'
set xlabel 'Date/Time'
set ylabel 'Average Stock Level'
set title 'Average Stock Level by Category Over Date'
set xdata time
set timefmt "%Y-%m-%d %H:%i"
set format x "%d-%m-%Y"
set xtics rotate by -45
set grid
set key outside right top vertical Left reverse enhanced autotitles columnhead nobox
plot $plot_command
EOF

    # Run Gnuplot script
    gnuplot "$GNUPLOT_SCRIPT"
    echo "Graph generated: ${GRAPHDIR}/avg_stock_by_category_graph.png"
}

# Function to extract and format total stock by category
extractTotalStockByCategory() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"
    local STOCK_OUTFILE="$OUTDIR/total_stock_by_category.dat"

    # Fetch total stock data grouped by category
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT p.category, SUM(td.stock) AS total_stock
    FROM productdetails pd
    JOIN products p ON pd.productID = p.productID
    JOIN trackdetails td ON pd.trackID = td.trackID
    GROUP BY p.category
    ORDER BY total_stock DESC;" | while read -r category total_stock; do
        echo "$category $total_stock"
    done > "$STOCK_OUTFILE"

    echo "Data for total stock by category has been extracted to $STOCK_OUTFILE"
}

# Function to plot total stock by category using bar chart
plotBarChartOfTotalStockByCategory() {
    local OUTDIR="data_files"
    local GRAPHDIR="graphs"
    mkdir -p "$GRAPHDIR"

    local DATA_FILE="${OUTDIR}/total_stock_by_category.dat"
    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_total_stock_bar_chart.gp"

    # Write the Gnuplot script
    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal png size 800,600
set output '${GRAPHDIR}/total_stock_bar_chart.png'
set title 'Total Stock by Category'
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.75
set xtic rotate by -45 scale 0
set grid y
set ylabel 'Total Stock'

plot '$DATA_FILE' using 2:xtic(1) with boxes title ''
EOF

    # Run Gnuplot script to generate the bar chart
    gnuplot "$GNUPLOT_SCRIPT"
    echo "Bar chart generated: ${GRAPHDIR}/total_stock_bar_chart.png"
}


# Function to extract and format price distribution by category
extractPriceDistributionByCategory() {
    local OUTDIR="data_files"
    mkdir -p "$OUTDIR"
    local PRICE_DIST_OUTFILE="$OUTDIR/price_distribution_by_category.dat"

    # Define price ranges
    local ranges=(
        "0-50"
        "51-100"
        "101-150"
        "151-200"
        "201-300"
        "301+"
    )

    # Fetch price distribution data grouped by category and price range
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "
    SELECT p.category, 
           CASE 
               WHEN td.price BETWEEN 0 AND 50 THEN '0-50'
               WHEN td.price BETWEEN 51 AND 100 THEN '51-100'
               WHEN td.price BETWEEN 101 AND 150 THEN '101-150'
               WHEN td.price BETWEEN 151 AND 200 THEN '151-200'
               WHEN td.price BETWEEN 201 AND 300 THEN '201-300'
               ELSE '301+'
           END AS price_range,
           COUNT(*) AS count
    FROM productdetails pd
    JOIN products p ON pd.productID = p.productID
    JOIN trackdetails td ON pd.trackID = td.trackID
    GROUP BY p.category, price_range
    ORDER BY p.category, price_range;" | while read -r category price_range count; do
        echo "$category $price_range $count"
    done > "$PRICE_DIST_OUTFILE"

    echo "Data for price distribution by category has been extracted to $PRICE_DIST_OUTFILE"
}

# Function to plot price distribution by category
plotBarChartOfPriceDistributionByCategory() {
    local OUTDIR="data_files"
    local GRAPHDIR="graphs"
    mkdir -p "$GRAPHDIR"

    local DATA_FILE="${OUTDIR}/price_distribution_by_category.dat"
    local GNUPLOT_SCRIPT="$GP_OUTDIR/plot_price_distribution_bar_chart.gp"

    cat <<EOF > "$GNUPLOT_SCRIPT"
set terminal pngcairo size 800,600 enhanced font 'Verdana,10'
set output '${GRAPHDIR}/price_distribution_bar_chart.png'
set title 'Price Distribution by Category'
set style data histograms
set style fill solid 1.00 border -1
set xtics nomirror rotate by -45 scale 0 font ",8"
set ytics nomirror
set ylabel 'Number of Products'
set xlabel 'Categories'
set grid y
set auto x
set boxwidth 0.9 relative
set style histogram clustered gap 1 title  offset character 0, 0, 0

plot '$DATA_FILE' using 3:xtic(1) title '0-50'
EOF

    gnuplot "$GNUPLOT_SCRIPT"
    echo "Bar chart generated: ${GRAPHDIR}/price_distribution_bar_chart.png"
}


# Check if a title was provided
if [ "$#" -eq 0 ]; then
    echo "Please provide a title for the graph. Usage: $0 \"Graph Title\""
    exit 1
fi

# Main execution logic based on graph type
case "$1" in
    "Price Changes Over Date")
        plotPriceGraph "Price Changes Over Date"
        ;;
    "Stock Changes Over Date")
        plotStockGraph "Stock Changes Over Date"
        ;;
    "Hourly Price Trend")
        extractHourlyData
        plotHourlyGraph "price" "Hourly Price Trends" "Average Price" "price"
        ;;
    "Hourly Stock Trend")
        extractHourlyData
        plotHourlyGraph "stock" "Hourly Stock Trends" "Average Stock Level" "stock"
        ;;
    "Price Changes Over Date by Category")
        plotPriceByCategoryGraph
        ;;
    "Stock Changes Over Date by Category")
        extractStockDataByCategory
        plotStockByCategoryGraph
        ;;
    "Average Price by Category Over Date")
        extractAveragePriceDataByCategory
        plotAveragePriceByCategoryGraph
        ;;
    "Average Stock Level by Category Over Date")
        extractAverageStockDataByCategory
        plotAverageStockByCategoryGraph
        ;;
    "Bar Chart of Total Stock by Category")
        extractTotalStockByCategory
        plotBarChartOfTotalStockByCategory
        ;;
    "Bar Chart of Price Distribution by Category")
        extractPriceDistributionByCategory
        plotBarChartOfPriceDistributionByCategory
        ;;
    *)
        echo "Invalid graph type specified. Valid types are:"
        echo "  - Price Changes Over Date"
        echo "  - Stock Changes Over Date"
        echo "  - Hourly Price Trend"
        echo "  - Hourly Stock Trend"
        echo "  - Price Changes Over Date by Category"
        echo "  - Stock Changes Over Date by Category"
        echo "  - Average Price by Category Over Date"
        echo "  - Average Stock Level by Category Over Date"
        echo "  - Bar Chart of Total Stock by Category"
        echo "  - Bar Chart of Price Distribution by Category"
        exit 1
        ;;
esac