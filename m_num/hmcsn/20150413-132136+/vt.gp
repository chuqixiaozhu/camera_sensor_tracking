#set terminal pdfcairo enhanced font "Times New Roman, 20"
#set output "20_m_num_vs_vt.pdf"
#set terminal postscript eps color solid font "Times New Roman, 20"
set terminal postscript eps color solid
#set terminal emf color solid enhanced font "Times New Roman, 20"
set output "100_m_num_vs_vt.eps"
#set terminal qt font "Times New Roman, 20"
#set xlabel "{/SimSun=20 空洞数量}"
set xlabel "Number of Mobile Nodes"
set xrange [0:20]
set xtics 5
set mxtics 5
#set ylabel "{/SimSun=20 有效监测时间率 (%)}"
set ylabel "Effective Monitoring Ratio (%)"
set yrange [40:80]
set ytics 10
set mytics 1
set format y "%.1f"
set grid
set key box
set key Left
#set key width 10
#set key spacing 10
#set key right top at 4.93, 78.2
plot "m_num-m_vs_vt" w lp lt 1 lw 2 pt 5 ps 2 title "MT", "m_num-f_vs_vt" w lp lt 2 lw 2 pt 2 ps 2 title "FT", "m_num-fl_vs_vt" w lp lt 3 lw 2 pt 3 ps 2 title "MFT", "m_num-c_vs_vt" w lp lt 4 lw 2 pt 4 ps 2 title "CT"
set output
#!pdftops -eps 20_m_num_vs_vt.pdf