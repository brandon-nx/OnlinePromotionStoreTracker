#!/bin/bash
# Database credentials
DB_USER="root"
DB_PASS=""
DB_NAME="pricetracker"

# Function to extract data from database and format it for each product
extract_and_format_data() {
    mkdir -p data_files
    # Get all unique productIDs from productdetails table
    local product_ids=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT DISTINCT productID FROM productdetails;")
    
    for product_id in $product_ids; do
        # Define output file for each productID
        local OUTFILE="data_files/price_data_${product_id}.dat"
        
        # Fetch trackID, price, and dateCollected for each productID
        mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT pd.trackID, td.price, td.dateCollected FROM productdetails pd JOIN trackdetails td ON pd.trackID = td.trackID WHERE pd.productID = '${product_id}';" | while read -r track_id price date_collected; do
            # Format the dateCollected field to mm-dd hh:mm
            formatted_date=$(date -d "$date_collected" +"%m-%d %H:%M")
            echo "$track_id $price $formatted_date"
        done > "$OUTFILE"
        
        echo "Data has been successfully extracted and formatted to $OUTFILE"
    done
}
extract_and_format_data


# Define output directory for the graphs
mkdir -p graphs

plotPriceGraph(){

    local graph_title="$1"
    # Generate Gnuplot command to plot each data file
    local plot_command=""

    for file in data_files/price_data_P*.dat; do
        local product_id=$(echo "$file" | sed -n 's/price_data_\(P[0-9]*\)\.dat/\1/p') 
        plot_command+=" '$file' using (\$0+1):2 with linespoints title '$product_id',"
    done

    # Remove the last comma from the plot command string
    plot_command=${plot_command%,}

    local GNUPLOT_SCRIPT="plot_price_graph.gp"
    # Write the Gnuplot script
    cat << EOF > "$GNUPLOT_SCRIPT"
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


# Check if a title was provided
if [ "$#" -eq 0 ]; then
    echo "Please provide a title for the graph. Usage: $0 \"Graph Title\""
    exit 1
fi

# Main execution
plotPriceGraph "$1"