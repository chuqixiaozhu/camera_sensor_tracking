#set terminal pdfcairo enhanced font "Times New Roman, 20"
#set output "20_m_num_vs_vt.pdf"
#set terminal postscript eps color solid font "Times New Roman, 20"
set terminal postscript eps color solid
#set terminal emf color solid enhanced font "Times New Roman, 20"
set output "100_m_num_vs_emt.eps"
#set terminal qt font "Times New Roman, 20"
#set xlabel "{/SimSun=20 空洞数量}"
set xlabel "Number of Mobile Nodes"
set xrange [2:20]
set xtics 2
set mxtics 1
#set ylabel "{/SimSun=20 有效监测时间率 (%)}"
set ylabel "Effective Monitoring Ratio (%)"
set yrange [20:100]
set ytics 20
set mytics 1
set format y "%.1f"
set grid
set key box
set key Left
#set key width 10
#set key spacing 10
#set key right top at 4.93, 78.2
plot "m_num-grid_vs_emt" w lp lt 1 lw 2 pt 5 ps 2 title "Relay", \
     "m_num-m_vs_emt" w lp lt 2 lw 2 pt 2 ps 2 title "Direct"
     #"m_num-fl_vs_vt" w lp lt 3 lw 2 pt 3 ps 2 title "MFT"
set output
#!pdftops -eps 20_m_num_vs_vt.pdf