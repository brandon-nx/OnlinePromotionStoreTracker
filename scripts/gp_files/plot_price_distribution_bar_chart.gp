set terminal pngcairo size 800,600 enhanced font 'Verdana,10'
set output 'graphs/price_distribution_bar_chart.png'
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

plot 'data_files/price_distribution_by_category.dat' using 3:xtic(1) title '0-50'
