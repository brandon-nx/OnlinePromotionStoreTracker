set terminal png font 'Times new roman' size 1400,600
set output 'graphs/avg_stock_by_category_graph.png'
set xlabel 'Date/Time'
set ylabel 'Average Stock Level'
set title 'Average Stock Level by Category Over Date'
set xdata time
set timefmt "%Y-%m-%d %H:%i"
set format x "%d-%m-%Y"
set xtics rotate by -45
set grid
set key outside right top vertical Left reverse enhanced autotitles columnhead nobox
plot  'data_files/avg_stock_data_BakingTools.dat' using 1:2 with lines title 'BakingTools', 'data_files/avg_stock_data_HomeCareHouseholdOrganizer.dat' using 1:2 with lines title 'HomeCareHouseholdOrganizer', 'data_files/avg_stock_data_KitchenwareTools.dat' using 1:2 with lines title 'KitchenwareTools'
