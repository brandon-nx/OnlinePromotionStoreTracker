set terminal png size 800,600
set output 'graphs/total_stock_bar_chart.png'
set title 'Total Stock by Category'
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.75
set xtic rotate by -45 scale 0
set grid y
set ylabel 'Total Stock'

plot 'data_files/total_stock_by_category.dat' using 2:xtic(1) with boxes title ''
