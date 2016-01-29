#set terminal pdfcairo enhanced font "Times New Roman, 20"
#set output "20_hole_vs_vt.pdf"
#set terminal postscript eps color solid font "Times New Roman, 20"
set terminal postscript eps color solid
#set terminal emf color solid enhanced font "Times New Roman, 20"
set output "100_m_num_vs_tmd.eps"
#set terminal qt font "Times New Roman, 20"
#set xlabel "{/SimSun=20 空洞数量}"
set xlabel "Alpha"
set xrange [0:0.1]
set xtics 0.01
set mxtics 1
#set ylabel "{/SimSun=20 有效监测时间率 (%)}"
set ylabel "Total Moving Distance (m)"
set yrange [0:800]
set ytics 200
set mytics 1
#set format y "%.1f"
set grid
set key box
set key Left
#set key width 10
#set key spacing 10
#set key left bottom at 0.3, 0.11
#plot "m_num-m_vs_tmd" u 1:($2/1000.0) w lp lt 1 lw 2 pt 5 ps 2 title "MT", "m_num-f_vs_tmd" u 1:($2/1000.0) w lp lt 2 lw 2 pt 2 ps 2 title "FT", "m_num-fl_vs_tmd" u 1:($2/1000.0) w lp lt 3 lw 2 pt 3 ps 2 title "MFT", "m_num-c_vs_tmd" u 1:($2/1000.0) w lp lt 4 lw 2 pt 4 ps 2 title "CT"
plot "m_num-subregion_vs_tmd" w lp lt 1 lw 2 pt 5 ps 2 title "Subregion"#, \
     "m_num-closest_vs_tmd" w lp lt 2 lw 2 pt 2 ps 2 title "Closest"
     #"m_num-s_vs_tmd" w lp lt 3 lw 2 pt 3 ps 2 title "Static"
set output
#!pdftops -eps 20_hole_vs_vt.pdf