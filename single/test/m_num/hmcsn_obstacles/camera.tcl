# This script is created by NSG2 beta1
# <http://wushoupong.googlepages.com/nsg>
# modified by Piglet

#===================================
#     Simulation parameters setup
#===================================
set opt(chan)   Channel/WirelessChannel    ;# channel type
set opt(prop)   Propagation/TwoRayGround   ;# radio-propagation model
#set opt(netif)  Phy/WirelessPhy/802_15_4  ;# network interface type
#set opt(mac)    Mac/802_15_4              ;# MAC type
set opt(netif)  Phy/WirelessPhy            ;# network interface type
set opt(mac)    Mac/802_11                 ;# MAC type
set opt(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set opt(ll)     LL                         ;# link layer type
set opt(ant)    Antenna/OmniAntenna        ;# antenna model
set opt(ifqlen) 50                         ;# max packet in ifq
set opt(rp)     DSDV                       ;# routing protocol
set Pi [expr acos(-1)];         # Pi, which should be 3.1415926535897931
set opt(normal) "normal.tcl";               # file for normal distribution
set tcl_precision 17;                       # Tcl variaty
set opt(trace_file) "out.tr"
set opt(nam_file) "out.nam"
# ==============================================================================
set opt(x)      100                        ;# X dimension of topography
set opt(y)      100                        ;# Y dimension of topography
set opt(stop)   100                        ;# time of simulation end
set opt(nmnode) 10                         ;# number of mobile nodes
set opt(node_size) 1                       ;# Size of nodes
set opt(target_size) 2                     ;# Size of the target
set opt(d_fov) 10;                         # Length of Field of View
set opt(mnode_speed) 1;                     # Velocity of Mobile nodes
set opt(target_speed_max) 3;                    # Maximum velocity of the Target
set opt(target_speed_min) 0.7;                  # Minimum velocity of the Target
set opt(time_click) 1;                      # Duration of a time slice
set opt(grid_length) [expr sqrt(2) * $opt(d_fov)]; # Length of a subregion
set opt(dist_limit) [expr 3 * sqrt(2) * $opt(d_fov)]; \
    # Maximum distance from target to chosen camera nodes
set opt(ntarget) 1;                         # number of targets
set opt(target_theta) "";                    # Direction of target
set opt(grid) "";               # Coodinates List of Subregions
set opt(moving_list) "";        # List of moving sensors
set opt(tracking_index) -1;     # Index of Tracking sensor
set opt(level2_index) -1;       # Index of Level 2 sensor
set opt(effective_monitoring_time) 0; # Effective Monitoring Time
set opt(total_moving_distance) 0;
set opt(s_posi_list) "";        # Positions of sensors
#set opt(radius_m) 15                       ;# Sensing Radius of Mobile nodes
#set opt(nfnode) 100                        ;# number of fixed nodes
#set opt(lag_time) [expr 3 * $opt(time_click)]
#set opt(EC) 0;                              # Energy Consumption
#set opt(weight_GT) 0.1;              # Weight of attracting force from target
#set opt(weight_GM) [expr 1 - $opt(weight_GT)]; \
#    # Weight of repulsive force from other mobile nodes
#set opt(AVG_EMT) 0;           # Average Effective Monitoring Time of targets
#set opt(energy_consumption) 0;           # Energy comsumption of fixed noded
#set opt(valid_time) 0;                      # Valid surveillance time
#set opt(noise_avg) 0.1;                       # Noise average
#set opt(noise_std) 0.2;                       # Noise standard deviation
#set opt(source_signal_max) 5;              # Maximum of source singal
#set opt(decay_factor) 2;                    # Decay factor
#set opt(dist_threshold_f) 7             ;# Distance threshold of Fixed nodes
#set opt(dist_threshold_m) 6;            # Distance threshold of Mobile nodes
#set opt(sen_intensity_threshold) 5;        # threshold of Sensing intensity
#set opt(sys_proba_threshold) 0.8;           # System Sensing probability
set opt(obstacle_number) 5;                     # number of obstacles
set opt(obstacle_length) 30;                    # Length of a obstacle edge

source $opt(normal)
if {0 < $argc} {
    #set opt(nfnode) [lindex $argv 0]
    set opt(nmnode) [lindex $argv 0]
    #set opt(hole_number) [lindex $argv 0]
    #set opt(target_speed_max) [lindex $argv 0]
    #set opt(weight_GM) [lindex $argv 0]
    set opt(result_file) [lindex $argv 1]
    #set opt(x) [lindex $argv 0]
    #set opt(y) [lindex $argv 1]
    #set opt(nfnode) [lindex $argv 2]
    #set opt(nmnode) [lindex $argv 3]
    #set opt(target_speed_max) [lindex $argv 4]
    #set opt(result_file) [lindex $argv 5]
    #set opt(dist_limit) \
    #set opt(dist_limit) 15
}
set opt(nn) [expr $opt(ntarget) + $opt(nmnode)] ;# sum of nodes
#===================================
#        Initialization
#===================================
#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo [new Topography]
$topo load_flatgrid $opt(x) $opt(y)
create-god $opt(nn)

#Open the NS trace file
set tracefile [open $opt(trace_file) w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open $opt(nam_file) w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $opt(x) $opt(y)

#===================================
#     Node parameter setup
#===================================
$ns node-config -adhocRouting  $opt(rp) \
                -llType        $opt(ll) \
                -macType       $opt(mac) \
                -ifqType       $opt(ifq) \
                -ifqLen        $opt(ifqlen) \
                -antType       $opt(ant) \
                -propInstance  [new $opt(prop)] \
                -phyType       $opt(netif) \
                -channel       [new $opt(chan)] \
                -topoInstance  $topo \
                -agentTrace    OFF \
                -routerTrace   OFF \
                -macTrace      OFF \
                -movementTrace OFF

#===================================
#        Collection of Random
#===================================
# Settings for Random X positions
set rng_x [new RNG]
$rng_x seed 0
set rd_x [new RandomVariable/Uniform]
$rd_x use-rng $rng_x
$rd_x set min_ 0
$rd_x set max_ $opt(x)

# Settings for Random Y positions
set rng_y [new RNG]
$rng_y seed 0
set rd_y [new RandomVariable/Uniform]
$rd_y use-rng $rng_y
$rd_y set min_ 0
$rd_y set max_ $opt(y)

# Settings of random Speed for Target
set rng_target_speed [new RNG]
$rng_target_speed seed 0
set rd_target_speed [new RandomVariable/Uniform]
$rd_target_speed use-rng $rng_target_speed
$rd_target_speed set min_ $opt(target_speed_min)
$rd_target_speed set max_ $opt(target_speed_max)

#===================================
#        Nodes Definition
#===================================

## Create Fixed nodes
#for {set i 0} {$i < $opt(nfnode)} {incr i} {
#    set fnode($i) [$ns node]
#    set xf [$rd_x value]
#    set yf [$rd_y value]
#    create_holes xf yf
#    $fnode($i) set X_ $xf
#    $fnode($i) set Y_ $yf
#    $fnode($i) set Z_ 0
#    $fnode($i) random-motion 0
#    $ns initial_node_pos $fnode($i) $opt(node_size)
#    $fnode($i) color "black"
#    $fnode($i) shape "circle"
#    set lag([$fnode($i) id]) 0
#    set sense_target($i) -1
#}

# Create Obstacles
proc create_obstacles {x_ y_} {
    global opt rd_x rd_y
    upvar 1 $x_ x
    upvar 1 $y_ y
    set h $opt(obstacle_length)
    set g [expr ($opt(x) - 3 * $h) / 4.0]
    set p1 $g
    set p2 [expr $g + $h]
    set p3 [expr 2.0 * $g + $h]
    switch -exact -- $opt(obstacle_number) {
        1 {
            while {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2} {
                set x [$rd_x value]
                set y [$rd_y value]
            }
        }
        2 {
            while {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2} {
                set x [$rd_x value]
                set y [$rd_y value]
            }
        }
        3 {
            while {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]}  {
                set x [$rd_x value]
                set y [$rd_y value]
            }
        }
        4 {
            while {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]  \
                || $p1 <= $x && $x <= $p2 && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1]} {
                set x [$rd_x value]
                set y [$rd_y value]
            }
        }
        5 {
            while {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]  \
                || $p1 <= $x && $x <= $p2 && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1] \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1]} {
                set x [$rd_x value]
                set y [$rd_y value]
            }
        }
        default {
            set x 0
            set y 0
            puts "something wrong.";
        }
    }
}; # 11/01/2016

# Check if the ordinates are in with the obstacle
proc is_in_obstacles_ord {x y} {
    global opt rd_x rd_y
    #upvar 1 $x_ x
    #upvar 1 $y_ y
    set h $opt(obstacle_length)
    set g [expr ($opt(x) - 3 * $h) / 4.0]
    set p1 $g
    set p2 [expr $g + $h]
    set p3 [expr 2.0 * $g + $h]
    set flag 0
    switch -exact -- $opt(obstacle_number) {
        1 {
            if {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2} {
                set flag 1
            }
        }
        2 {
            if {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2} {
                set flag 1
            }
        }
        3 {
            if {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]}  {
                set flag 1
            }
        }
        4 {
            if {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]  \
                || $p1 <= $x && $x <= $p2 && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1]} {
                set flag 1
            }
        }
        5 {
            if {$p1 <= $x && $x <= $p2 && \
                   $p1 <= $y && $y <= $p2 \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   $p1 <= $y && $y <= $p2 \
                || $p3 <= $x && $x <= [expr 100 - $p3] && \
                   $p3 <= $y && $y <= [expr 100 - $p3]  \
                || $p1 <= $x && $x <= $p2 && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1] \
                || [expr 100 - $p2] <= $x && $x <= [expr 100 - $p1] && \
                   [expr 100 - $p2] <= $y && $y <= [expr 100 - $p1]} {
                set flag 1
            }
        }
        default {
            puts "something wrong.";
        }
    }
    return $flag
}; # 11/01/2016

# Create Mobile nodes
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    set mnode($i) [$ns node]
    set xm [$rd_x value]
    set ym [$rd_y value]
    create_obstacles xm ym; # 11/01/2016
    $mnode($i) set X_ $xm
    $mnode($i) set Y_ $ym
    $mnode($i) set Z_ 0
    $mnode($i) random-motion 0
    $ns initial_node_pos $mnode($i) $opt(node_size)
    $mnode($i) color "black"
    $mnode($i) shape "square"
    #$ns at 0 "$mnode($i) color \"blue\""
    set lag([$mnode($i) id]) 0
    set to_target($i) -1
    #puts "Node $i: ($xm, $ym)"; # test
}

# Create the Target
for {set i 0} {$i < $opt(ntarget)} {incr i} {
    set target($i) [$ns node]
    set xt [$rd_x value]
    set yt [$rd_y value]
    create_obstacles xt yt; # 11/01/2016
    $target($i) set X_ $xt
    $target($i) set Y_ $yt
    $target($i) set Z_ 0
    $target($i) random-motion 0
    $ns initial_node_pos $target($i) $opt(target_size)
    $target($i) color "black"
    $target($i) shape "hexagon"
    $ns at 0 "$target($i) color \"red\""
    set EMT($i) 0
}

#===================================
#        Utilities
#===================================

# Set destination of the node to the target
proc set_destination {node target itime} {
    global ns opt
    $node update_position
    $target update_position
    set target_x [$target set X_]
    set target_y [$target set Y_]
    set node_x [$node set X_]
    set node_y [$node set Y_]
    set delta [expr ($opt(node_size) + $opt(target_size)) / 2.0]
    set dist [distance $node $target $itime]
    if {$dist < $delta} {
        return
    }
    set cos_theta [expr ($target_x - $node_x) / $dist]
    set sin_theta [expr ($target_y - $node_y) / $dist]
    set dest_x [expr $target_x - $delta * $cos_theta]
    set dest_y [expr $target_y - $delta * $sin_theta]
    $node setdest $dest_x $dest_y $opt(mnode_speed)
}

# Set destination of the node by coordinate
proc destination_xy_dfov {node_ t_x t_y time_stamp} {
    global opt

    upvar 1 $node_ node
    set node_x [$node set X_]
    set node_y [$node set Y_]
    set dist [distance_xy $node_x $node_y $t_x $t_y]
    set delta [expr $opt(d_fov) * 0.5]
    if {$dist <= $delta} {
        return
    }
    set cos_theta [expr ($t_x - $node_x) / $dist]
    set sin_theta [expr ($t_y - $node_y) / $dist]
    set dest_x [expr $t_x - $delta * $cos_theta]
    set dest_y [expr $t_y - $delta * $sin_theta]
    $node setdest $dest_x $dest_y $opt(mnode_speed)
}

# Set destination for Level 2 Sensor
proc destination_xy_level2 {node_ t_x t_y time_stamp} {
    global opt Pi

    upvar 1 $node_ node
    set theta [lindex $opt(target_theta) $time_stamp]
    set pi2eight [expr $Pi / 8]
    set s_x [lindex [lindex $opt(grid) 1] 0]
    set s_y [lindex [lindex $opt(grid) 1] 1]
    set short_d [expr $opt(grid_length) / 2]

    # Set Edges
    set right [expr $s_x + $short_d]
    if {$right >= $opt(x)} {
        set right [expr $opt(x) - 0.0000001]
    }
    set left [expr $s_x - $short_d]
    if {$left <= 0} {
        set left 0.0000001
    }
    set top [expr $s_y + $short_d]
    if {$top >= $opt(y)} {
        set top [expr $opt(y) - 0.0000001]
    }
    set bottom [expr $s_y - $short_d]
    if {$bottom <= 0} {
        set bottom 0.0000001
    }

    # Set destination
    set dest_x $t_x
    set dest_y $t_y
    if {$dest_x > $right} {
        set dest_x $right
    } elseif {$dest_x < $left} {
        set dest_x $left
    }
    if {$dest_y > $top} {
        set dest_y $top
    } elseif {$dest_y < $bottom} {
        set dest_y $bottom
    }
    #if {$theta >= -$pi2eight && $theta < $pi2eight } {
    #    set dest_x [expr $s_x - $short_d]
    #    set dest_y $s_y
    #} elseif {$theta >= $pi2eight && $theta < 3*$pi2eight} {
    #    set dest_x [expr $s_x - $short_d]
    #    set dest_y [expr $s_y - $short_d]
    #} elseif {$theta >= 3*$pi2eight && $theta < 5*$pi2eight} {
    #    set dest_x [expr $s_x]
    #    set dest_y [expr $s_y - $short_d]
    #} elseif {$theta >= 5*$pi2eight && $theta < 7*$pi2eight} {
    #    set dest_x [expr $s_x + $short_d]
    #    set dest_y [expr $s_y - $short_d]
    #} elseif {$theta >= 7*$pi2eight || $theta < -7*$pi2eight} {
    #    set dest_x [expr $s_x + $short_d]
    #    set dest_y [expr $s_y]
    #} elseif {$theta >= -7*$pi2eight && $theta < -5*$pi2eight} {
    #    set dest_x [expr $s_x + $short_d]
    #    set dest_y [expr $s_y + $short_d]
    #} elseif {$theta >= -5*$pi2eight && $theta < -3*$pi2eight} {
    #    set dest_x [expr $s_x]
    #    set dest_y [expr $s_y + $short_d]
    #} elseif {$theta >= -3*$pi2eight && $theta < -$pi2eight} {
    #    set dest_x [expr $s_x - $short_d]
    #    set dest_y [expr $s_y + $short_d]
    #}
    #if {$dest_x <= 0} {
    #    set dest_x 0.0000001
    #} elseif {$dest_x >= $opt(x)} {
    #    set dest_x [expr $opt(x) - 0.0000001]
    #}
    #if {$dest_y <= 0} {
    #    set dest_y 0.0000001
    #} elseif {$dest_y => $opt(y)} {
    #    set dest_y [expr $opt(y) - 0.0000001]
    #}
    $node setdest $dest_x $dest_y $opt(mnode_speed)
    #puts "LEVEL 2 START MOVING NOW !"; # test
}

# Compute the distance bewteen node and target
proc distance {node_ target_ time_stamp} {
    upvar 1 $node_ node
    upvar 1 $target_ target
    $node update_position
    $target update_position
    set target_x [$target set X_]
    set target_y [$target set Y_]
    set node_x [$node set X_]
    set node_y [$node set Y_]
    set dx [expr $node_x - $target_x]
    set dy [expr $node_y - $target_y]
    set dist [expr sqrt($dx * $dx + $dy * $dy)]
    return $dist
}

# Get the distance based on coordinates
proc distance_xy {sx sy tx ty} {
    set dx [expr $sx - $tx]
    set dy [expr $sy - $ty]
    set dist [expr sqrt($dx * $dx + $dy * $dy)]
    return $dist
}

# If the target or sensor is in Level 1 or 2 subregion
proc in_subregion {target_ level time_stamp} {
    global opt
    upvar 1 $target_ target
    $target update_position

    if {![llength $opt(grid)]} {
        return 0
    }
    incr level -1
    set t_x [$target set X_]
    set t_y [$target set Y_]
    set g_x [lindex [lindex $opt(grid) $level] 0]
    set g_y [lindex [lindex $opt(grid) $level] 1]
    set vari [expr $opt(grid_length) / 2.0]
    set right [expr $g_x + $vari]
    set left [expr $g_x - $vari]
    set top [expr $g_y + $vari]
    set bottom [expr $g_y - $vari]
    if {$t_x >= $left && $t_x <= $right && $t_y >= $bottom && $t_y <= $top} {
        return 1
    } else {
        return 0
    }
}

# If the target is in Monitoring Region
proc in_region {target_ time_stamp} {
    global opt
    upvar 1 $target_ target
    $target update_position
    if {![llength $opt(grid)]} {
        return 0
    }
    set t_x [$target set X_]
    set t_y [$target set Y_]
    set g_x [lindex [lindex $opt(grid) 0] 0]
    set g_y [lindex [lindex $opt(grid) 0] 1]
    set vari [expr $opt(grid_length) * 3.0 / 2]
    set right [expr $g_x + $vari]
    set left [expr $g_x - $vari]
    set top [expr $g_y + $vari]
    set bottom [expr $g_y - $vari]
    if {$t_x >= $left && $t_x <= $right && $t_y >= $bottom && $t_y <= $top} {
        return 1
    } else {
        return 0
    }
}

# Build up the Monitoring Field for the target
proc gridding {target_ time_stamp} {
    global opt Pi
    upvar 1 $target_ target
    $target update_position

    set opt(grid) ""
    set theta [lindex $opt(target_theta) $time_stamp]
    set pi2eight [expr $Pi / 8]
    set target_x [$target set X_]
    set target_y [$target set Y_]
    lappend opt(grid) [list $target_x $target_y]; # Level-1
    set x1 $target_x
    set y1 $target_y
    set x_right [expr $x1 + $opt(grid_length)]
    set x_left [expr $x1 - $opt(grid_length)]
    set y_top [expr $y1 + $opt(grid_length)]
    set y_bottom [expr $y1 - $opt(grid_length)]
    if {$x_right >= $opt(x)} {
        set x_right [expr $opt(x) - 0.0000001]
    }
    if {$x_left <= 0} {
        set x_left 0.0000001
    }
    if {$y_top >= $opt(y)} {
        set y_top [expr $opt(y) - 0.0000001]
    }
    if {$y_bottom <= 0} {
        set y_bottom 0.0000001
    }

    set sub(top_right) [list $x_right $y_top]; # Top Right
    set sub(top) [list $x1 $y_top]; # Top
    set sub(right) [list $x_right $y1]; # Right
    set sub(top_left) [list $x_left $y_top]; # Top Left
    set sub(bottom_right) [list $x_right $y_bottom]; # Bottom Right
    set sub(left) [list $x_left $y1]; # Left
    set sub(bottom) [list $x1 $y_bottom]; # Bottom
    set sub(bottom_left) [list $x_left $y_bottom]; # Bottom Left

    if {$theta >= -$pi2eight && $theta < $pi2eight } {
        lappend opt(grid) $sub(right); # Level-2
        lappend opt(grid) $sub(top_right); # Level-3
        lappend opt(grid) $sub(bottom_right); # Level-3
        lappend opt(grid) $sub(top); # Level-4
        lappend opt(grid) $sub(bottom); # Level-4
        lappend opt(grid) $sub(top_left); # Level-5
        lappend opt(grid) $sub(bottom_left); # Level-5
        lappend opt(grid) $sub(left); # Level-6
    } elseif {$theta >= $pi2eight && $theta < 3*$pi2eight} {
        lappend opt(grid) $sub(top_right); # Level-2
        lappend opt(grid) $sub(top); # Level-3
        lappend opt(grid) $sub(right); # Level-3
        lappend opt(grid) $sub(top_left); # Level-4
        lappend opt(grid) $sub(bottom_right); # Level-4
        lappend opt(grid) $sub(left); # Level-5
        lappend opt(grid) $sub(bottom); # Level-5
        lappend opt(grid) $sub(bottom_left); # Level-6
    } elseif {$theta >= 3*$pi2eight && $theta < 5*$pi2eight} {
        lappend opt(grid) $sub(top); # Level-2
        lappend opt(grid) $sub(top_left); # Level-3
        lappend opt(grid) $sub(top_right); # Level-3
        lappend opt(grid) $sub(left); # Level-4
        lappend opt(grid) $sub(right); # Level-4
        lappend opt(grid) $sub(bottom_left); # Level-5
        lappend opt(grid) $sub(bottom_right); # Level-5
        lappend opt(grid) $sub(bottom); # Level-6
    } elseif {$theta >= 5*$pi2eight && $theta < 7*$pi2eight} {
        lappend opt(grid) $sub(top_left); # Level-2
        lappend opt(grid) $sub(left); # Level-3
        lappend opt(grid) $sub(top); # Level-3
        lappend opt(grid) $sub(bottom_left); # Level-4
        lappend opt(grid) $sub(top_right); # Level-4
        lappend opt(grid) $sub(bottom); # Level-5
        lappend opt(grid) $sub(right); # Level-5
        lappend opt(grid) $sub(bottom_right); # Level-6
    } elseif {$theta >= 7*$pi2eight || $theta < -7*$pi2eight} {
        lappend opt(grid) $sub(left); # Level-2
        lappend opt(grid) $sub(bottom_left); # Level-3
        lappend opt(grid) $sub(top_left); # Level-3
        lappend opt(grid) $sub(bottom); # Level-4
        lappend opt(grid) $sub(top); # Level-4
        lappend opt(grid) $sub(bottom_right); # Level-5
        lappend opt(grid) $sub(top_right); # Level-5
        lappend opt(grid) $sub(right); # Level-6
    } elseif {$theta >= -7*$pi2eight && $theta < -5*$pi2eight} {
        lappend opt(grid) $sub(bottom_left); # Level-2
        lappend opt(grid) $sub(bottom); # Level-3
        lappend opt(grid) $sub(left); # Level-3
        lappend opt(grid) $sub(bottom_right); # Level-4
        lappend opt(grid) $sub(top_left); # Level-4
        lappend opt(grid) $sub(right); # Level-5
        lappend opt(grid) $sub(top); # Level-5
        lappend opt(grid) $sub(top_right); # Level-6
    } elseif {$theta >= -5*$pi2eight && $theta < -3*$pi2eight} {
        lappend opt(grid) $sub(bottom); # Level-2
        lappend opt(grid) $sub(bottom_right); # Level-3
        lappend opt(grid) $sub(bottom_left); # Level-3
        lappend opt(grid) $sub(right); # Level-4
        lappend opt(grid) $sub(left); # Level-4
        lappend opt(grid) $sub(top_right); # Level-5
        lappend opt(grid) $sub(top_left); # Level-5
        lappend opt(grid) $sub(top); # Level-6
    } elseif {$theta >= -3*$pi2eight && $theta < -$pi2eight} {
        lappend opt(grid) $sub(bottom_right); # Level-2
        lappend opt(grid) $sub(right); # Level-3
        lappend opt(grid) $sub(bottom); # Level-3
        lappend opt(grid) $sub(top_right); # Level-4
        lappend opt(grid) $sub(bottom_left); # Level-4
        lappend opt(grid) $sub(top); # Level-5
        lappend opt(grid) $sub(left); # Level-5
        lappend opt(grid) $sub(top_left); # Level-6
    }
}

# Dispatch mobile sensors for tarcking
proc dispatching {target_ time_stamp} {
    global opt mnode
    upvar 1 $target_ target
    set moving_mnode_list ""
    foreach index $opt(moving_list) { # Stop moving sensors
        $mnode($index) update_position
        set x [$mnode($index) set X_]
        set y [$mnode($index) set Y_]
        $mnode($index) setdest $x $y $opt(mnode_speed)
    }
    set opt(moving_list) ""

    # Choose sensor in a certain range
    for {set i 0} {$i < $opt(nmnode)} {incr i} {
        set to_target($i) 0
        set dist [distance mnode($i) target $time_stamp]
        if {$dist > $opt(dist_limit)} {
            continue
        }
        lappend moving_mnode_list [list $i $dist]
    }
    set sum_sensor [llength $moving_mnode_list]
    if {!$sum_sensor} {
        return
    }
    #set opt(tarcking_index) -1;
    set opt(level2_index) -1;

    # Level 1 sensor
    set dest_x [lindex [lindex $opt(grid) 0] 0]
    set dest_y [lindex [lindex $opt(grid) 0] 1]
    #set temp_list [lsort -real -index 1 $moving_mnode_list]
    set temp_list ""
    foreach ele [lsort -real -index 1 $moving_mnode_list] {
        set index [lindex $ele 0]
        lappend temp_list $index
    }
    #set index [lindex [lindex $temp_list 0] 0]
    set index [lindex $temp_list 0]
    #puts "@551 level 0: sensor $index"; # test
    if {[is_in_obstacles_ord $dest_x $dest_y] == 0} {
        $mnode($index) setdest $dest_x $dest_y $opt(mnode_speed)
        set to_target($index) 1
        lappend opt(moving_list) $index
    };                          # 11/01/2016
    #$mnode($index) setdest $dest_x $dest_y $opt(mnode_speed)
    #set to_target($index) 1
    #lappend opt(moving_list) $index
    #set opt(tracking_index) $index

    # Level 2 to 6 sensor
    for {set i 1} {$i < $sum_sensor && $i < 9} {incr i} {
        set p_list ""
        # Destination in subregion
        set dest_x [lindex [lindex $opt(grid) $i] 0]
        set dest_y [lindex [lindex $opt(grid) $i] 1]
        if {[is_in_obstacles_ord $dest_x $dest_y] == 1} {
            continue
        };                      # 11/01/2016
        # Candidates list
        foreach index $temp_list {
            #set index [lindex $ele 0]
            if {$to_target($index)} {
                continue
            }
            $mnode($index) update_position
            set s_x [$mnode($index) set X_]
            set s_y [$mnode($index) set Y_]
            set dist [distance_xy $s_x $s_y $dest_x $dest_y]
            lappend p_list [list $index $dist]
        }
        # Get the closest one
        set p_list [lsort -real -index 1 $p_list]
        set index [lindex [lindex $p_list 0] 0]
        # Dispatch it to its subregion
        $mnode($index) setdest $dest_x $dest_y $opt(mnode_speed)
        if {$i == 1} {
            set opt(level2_index) $index
        }
        set to_target($index) 1
        lappend opt(moving_list) $index
        #puts "level $i: sensor $index"; # test
        # Update the temp_list
        set temp_list ""
        foreach ele $p_list {
            set index [lindex $ele 0]
            lappend temp_list $index
        }
    }
}

# Scheduling mobile node actions
proc mobile_node_action {time_stamp} {
    global opt mnode target lag to_target Pi
    #puts "================= At $time_stamp ================="; # test

    # Need to set up new subregions
    #if {![llength $opt(grid)] || ![in_subregion target(0) 1 $time_stamp]} {}
    #if {$opt(tracking_index) == -1 || ![in_region target(0) $time_stamp]} {}
    #puts "Now: target is at ([$target(0) set X_], [$target(0) set Y_])"; # test
    if {$opt(tracking_index) == -1 || ![in_subregion target(0) 1 $time_stamp]} {
        #puts "Let's MOVE NOW!"; # test
        gridding target(0) $time_stamp
        ## test
        #$target(0) update_position
        #set t_x [$target(0) set X_]
        #set t_y [$target(0) set Y_]
        #set theta [expr [lindex $opt(target_theta) $time_stamp] / $Pi * 180]
        #puts "Target: ($t_x, $t_y), THETA: $theta"
        #gridding target(0) $time_stamp
        #set i 0
        #foreach sub $opt(grid) {
        #    puts "Subregion $i: ([lindex $sub 0], [lindex $sub 1])"
        #    incr i
        #}
        ## /test
        dispatching target(0) $time_stamp
        #puts "Moving List: $opt(moving_list)"; # test
        if {![llength $opt(moving_list)]} {
            return
        }
    }
    # Get the closest sensor
    set dist_min [expr 2 * $opt(x)]
    set index_min -1
    foreach index $opt(moving_list) {
        set dist [distance mnode($index) target(0) $time_stamp]
        if {$dist < $dist_min} {
            set dist_min $dist
            set index_min $index
        }
    }

    # Dispatch the Level 2 sensor for tracking
    if {$opt(level2_index) != -1 && \
        [in_subregion mnode($opt(level2_index)) 2 $time_stamp]} {
        $target(0) update_position
        set t_x [$target(0) set X_]
        set t_y [$target(0) set Y_]
        destination_xy_level2 mnode($opt(level2_index)) $t_x $t_y $time_stamp
    }

    # Dispatch the sensor for tracking
    $target(0) update_position
    set t_x [$target(0) set X_]
    set t_y [$target(0) set Y_]
    destination_xy_dfov mnode($index_min) $t_x $t_y $time_stamp
    #puts "Tracking sensor: $index_min"; # test


    # Update the EMT and Total Movement
    if {$dist_min <= $opt(d_fov)} {
        set opt(tracking_index) $index_min
        incr opt(effective_monitoring_time) $opt(time_click)
        foreach i $opt(moving_list) { ; # Stop other sensors
            if {$i == $index_min} {
                continue
            }
            $mnode($i) update_position
            set x [$mnode($i) set X_]
            set y [$mnode($i) set Y_]
            $mnode($i) setdest $x $y $opt(mnode_speed)
        }
    } else {
        set opt(tracking_index) -1
        #puts "Can't monitor the target"; # test
    }
}

#===================================
#        Generate movement
#===================================
# The schedule of Targets' Movement
for {set i 0}  {$i < $opt(ntarget)} {incr i} {
    set time_line 0
    set target_lx [$target($i) set X_]
    set target_ly [$target($i) set Y_]
    set to_move 1
    while {$time_line < $opt(stop)} {
        set time_stamp $time_line

# A Stop after a movement
        if {!$to_move} {
            set stop_time [expr int($move_time / 3)]
            #set stop_time 100
            if {!$stop_time} {
                set stop_time 1
            }
            if {$opt(stop) <= [expr $time_line + $stop_time]} {
                set stop_time [expr $opt(stop) - $time_line]
            }
            for {set j 0} {$j < $stop_time} {incr j} {
                lappend opt(target_theta) $target_theta
            }
            incr time_line $stop_time
            set to_move 1
            continue
        }

# A Movement of this Target
        set dest_x [$rd_x value]
        set dest_y [$rd_y value]
        create_obstacles dest_x dest_y; # 11/01/2016
        set target_speed [$rd_target_speed value]
        set dx [expr $dest_x - $target_lx]
        set dy [expr $dest_y - $target_ly]
        set target_theta [expr atan2($dy, $dx)]
        set target_lx $dest_x
        set target_ly $dest_y
        set dist [expr sqrt(pow($dx, 2) + pow($dy, 2))]
        set move_time [expr int(floor(double($dist) / $target_speed) + 1)]
        if {$opt(stop) <= [expr $time_line + $move_time]} {
            set move_time [expr $opt(stop) - $time_line]
        }
        for {set j 0} {$j < $move_time} {incr j} {
            lappend opt(target_theta) $target_theta
        }
        $ns at $time_line "$target($i) setdest $dest_x $dest_y $target_speed"
        incr time_line $move_time
        set to_move 0
    }
}

# The schedule of Mobile Nodes' Movement
set time_line 0
while {$time_line < $opt(stop)} {
    $ns at $time_line "mobile_node_action $time_line"
    incr time_line $opt(time_click)
}

# Calculate the total moving distance of sensors
proc step_distance {time_stamp} {
    global opt mnode

    set total_dist 0
    set temp_list ""
    for {set i 0} {$i < $opt(nmnode)} {incr i} {
        set lx [lindex [lindex $opt(s_posi_list) $i] 0]
        set ly [lindex [lindex $opt(s_posi_list) $i] 1]
        $mnode($i) update_position
        set px [$mnode($i) set X_]
        set py [$mnode($i) set Y_]
        lappend temp_list [list $px $py]
        set dist [distance_xy $lx $ly $px $py]
        set total_dist [expr $total_dist + $dist]
        ## test
        #puts "******* At $time_stamp *******"
        #puts "($lx, $ly) -> ($px, $py), dist: $dist, total: $total_dist"
        ## /test
    }
    set opt(s_posi_list) $temp_list
    set opt(total_moving_distance) [expr $opt(total_moving_distance) + $total_dist]
    #puts "~~~~~~~ total moving distance: $opt(total_moving_distance)"; # test
}

set time_line 1
set opt(s_posi_list) ""
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    set x [$mnode($i) set X_]
    set y [$mnode($i) set Y_]
    lappend opt(s_posi_list) [list $x $y]
}
while {$time_line <= $opt(stop)} {
    $ns at $time_line "step_distance $time_line"
    incr time_line $opt(time_click)
}
#$ns at [expr $opt(stop) -1 ] "$mnode(0) setdest 50 50 $opt(mnode_speed)"; # test
#===================================
#        Agents Definition
#===================================
#===================================
#        Applications Definition
#===================================
#===================================
#        Termination
#===================================

# Calculate Averaget Effective Monitoring Time of targets
#proc average_emt {} {
#    global EMT opt
#    set sum 0
#    for {set i 0} {$i < $opt(ntarget)} {incr i} {
#        incr sum $EMT($i)
#    }
#    set opt(AVG_EMT) [expr 1.0 * $sum / $opt(ntarget)]
#}

# Calculate the results
#proc getting_results {} {
#    #average_emt
#}

# Define a 'finish' procedure
proc output_file {} {
    global ns opt
    set result_file [open $opt(result_file) a]
    puts $result_file \
         "$opt(nmnode) \
          $opt(effective_monitoring_time) \
          $opt(total_moving_distance)"
    flush $result_file
    close $result_file
}
proc finish {} {
    global ns tracefile namfile opt argc
    #getting_results
    puts "Effective Monitoring Time: $opt(effective_monitoring_time)"
    puts "Total Moving Distance: $opt(total_moving_distance)"
    $ns flush-trace
    if {0 < $argc} {
        output_file
    }
    $ns at $opt(stop) "$ns nam-end-wireless $opt(stop)"
    close $tracefile
    close $namfile
    #exec nam out.nam &
    exit 0
}

# Reset nodes
for {set i 0} {$i < $opt(ntarget)} {incr i} {
    $ns at $opt(stop) "$target($i) reset"
}
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    $ns at $opt(stop) "$mnode($i) reset"
}
#for {set i 0} {$i < $opt(nfnode)} {incr i} {
#    $ns at $opt(stop) "$fnode($i) reset"
#}

# Finish
$ns at $opt(stop) "finish"
$ns at $opt(stop) "puts \"Done.\"; $ns halt"
$ns run
