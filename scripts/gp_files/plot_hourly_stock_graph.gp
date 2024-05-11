set terminal png font 'Times new roman' size 1400,600
set output 'graphs/hourly_stock_graph.png'
set xlabel 'Hour of the Day'
set ylabel 'Average Stock Level'
set title 'Hourly Stock Trends'
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set style increment user
set xtics (0, 6, 12, 18, 24)
plot  'data_files/hourly_stock_data_P001.dat' using 1:2 with linespoints title 'P001', 'data_files/hourly_stock_data_P002.dat' using 1:2 with linespoints title 'P002', 'data_files/hourly_stock_data_P003.dat' using 1:2 with linespoints title 'P003', 'data_files/hourly_stock_data_P004.dat' using 1:2 with linespoints title 'P004', 'data_files/hourly_stock_data_P005.dat' using 1:2 with linespoints title 'P005'
