set terminal png font 'Times new roman' size 1400,600
set output 'graphs/price_by_category_graph.png'
set xlabel 'Date'
set ylabel 'Price'
set title 'Price Changes Over Date by Category'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics ('05-07' 1, '05-08' 3, '05-09' 26, '05-10' 104)
plot  'data_files/price_data_BakingTools.dat' using ($0+1):2 with linespoints title 'BakingTools', 'data_files/price_data_HomeCareHouseholdOrganizer.dat' using ($0+1):2 with linespoints title 'HomeCareHouseholdOrganizer', 'data_files/price_data_KitchenwareTools.dat' using ($0+1):2 with linespoints title 'KitchenwareTools', 'data_files/price_data_P001.dat' using ($0+1):2 with linespoints title 'P001', 'data_files/price_data_P002.dat' using ($0+1):2 with linespoints title 'P002', 'data_files/price_data_P003.dat' using ($0+1):2 with linespoints title 'P003', 'data_files/price_data_P004.dat' using ($0+1):2 with linespoints title 'P004', 'data_files/price_data_P005.dat' using ($0+1):2 with linespoints title 'P005'
