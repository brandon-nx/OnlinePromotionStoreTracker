set terminal png font 'Times new roman' size 1400,600
set output 'graphs/stock_by_category_graph.png'
set xlabel 'Date/Time'
set ylabel 'Average Stock Level'
set title 'Stock Changes Over Time by Category'
set xdata time
set timefmt "%Y-%m-%d %H:%i"
set format x "%d-%m-%Y"
set xtics rotate by -45
set grid
set key outside right top vertical Left reverse enhanced autotitles columnhead nobox
plot  'data_files/stock_data_category_BakingTools.dat' using 1:2 with lines title 'BakingTools', 'data_files/stock_data_category_HomeCareHouseholdOrganizer.dat' using 1:2 with lines title 'HomeCareHouseholdOrganizer', 'data_files/stock_data_category_KitchenwareTools.dat' using 1:2 with lines title 'KitchenwareTools'
