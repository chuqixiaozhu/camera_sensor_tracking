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
set opt(Pi) [expr acos(-1)];         # Pi, which should be 3.1415926535897931
set opt(normal) "normal.tcl";               # file for normal distribution
set tcl_precision 17;                       # Tcl variaty
set opt(trace_file) "out.tr"
set opt(nam_file) "out.nam"
# ===========================================================================
set opt(x)      100                        ;# X dimension of topography
set opt(y)      100                        ;# Y dimension of topography
set opt(stop)   100                        ;# time of simulation end
set opt(nmnode) 10                         ;# number of mobile nodes
set opt(node_size) 1                       ;# Size of nodes
set opt(target_size) 2                     ;# Size of the target
set opt(d_fov) 10;                         # Length of Field of View
set opt(mnode_speed) 1;                    # Velocity of Mobile nodes
set opt(target_speed_max) 3;               # Maximum velocity of the Target
set opt(target_speed_min) 0.7;             # Minimum velocity of the Target
set opt(time_click) 1;                     # Duration of a time slice
set opt(grid_length) [expr sqrt(2) * $opt(d_fov)]; # Length of a subregion
set opt(dist_limit) [expr 3 * sqrt(2) * $opt(d_fov)]; \
    # Maximum distance from target to chosen camera nodes
set opt(ntarget) 3;                         # number of targets
#set opt(target_theta) {};                    # Direction of target
#set opt(grid) {};               # Coodinates List of Subregions
#set opt(moving_list) {};        # List of moving sensors
#set opt(tracking_index) -1;     # Index of Tracking sensor
#set opt(level2_index) -1;       # Index of Level 2 sensor
#set opt(effective_monitoring_time) 0; # Effective Monitoring Time
set opt(total_moving_distance) 0; # Total moving distance of mobile nodes
set opt(precision) 0.0000001;   # Precision for position adjustment
set opt(nine) 9;                # Number of subregions in a monitoring region

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

# Create Mobile nodes
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    set mnodes($i) [$ns node]
    set xm [$rd_x value]
    set ym [$rd_y value]
    #create_holes xm ym
    $mnodes($i) set X_ $xm
    $mnodes($i) set Y_ $ym
    $mnodes($i) set Z_ 0
    $mnodes($i) random-motion 0
    $ns initial_node_pos $mnodes($i) $opt(node_size)
    $mnodes($i) color "black"
    $mnodes($i) shape "square"
    #set lag([$mnodes($i) id]) 0
    #set is_candidate($i) 0; # If node i is a moving candidate for any target
    set to_target($i) -1;       # Which target it is following
}

# Create the Target
for {set i 0} {$i < $opt(ntarget)} {incr i} {
    set targets($i) [$ns node]
    $targets($i) set X_ [$rd_x value]
    $targets($i) set Y_ [$rd_y value]
    $targets($i) set Z_ 0
    $targets($i) random-motion 0
    $ns initial_node_pos $targets($i) $opt(target_size)
    $targets($i) color "black"
    $targets($i) shape "hexagon"
    $ns at 0 "$targets($i) color \"red\""
    set thetas($i) {};         # Moving directions of target i
    set subregions($i) {}; # Subregions List of target i
    set moving_sensors($i) {};    # List of Moving Sensors to target i
    set candidates($i) {};        # List of Candidate-sensor for target i
    set tracking_index($i) -1; # Index of Tracking Sensor for target i
    set level2_index($i) -1;    # Index of Level 2 sensor for target i
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
    set delta [expr $opt(d_fov) * 0.5] ; # Why 0.5? Maybe for energy saving.
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
proc destination_xy_level2 {node_ k t_x t_y time_stamp} {
    global opt thetas subregions

    upvar 1 $node_ node
    #set theta [lindex $opt(target_theta) $time_stamp]
    set theta [lindex thetas($k) $time_stamp]
    set pi2eight [expr $opt(Pi) / 8]
    #set s_x [lindex [lindex $opt(grid) 1] 0]
    #set s_y [lindex [lindex $opt(grid) 1] 1]
    set s_x [lindex [lindex $subregions($k) 1] 0]
    set s_y [lindex [lindex $subregions($k) 1] 1]
    set short_d [expr $opt(grid_length) / 2]

    # Set Edges
    set right [expr $s_x + $short_d]
    if {$right >= $opt(x)} {
        set right [expr $opt(x) - $opt(precision)]
    }
    set left [expr $s_x - $short_d]
    if {$left <= 0} {
        set left $opt(precision)
    }
    set top [expr $s_y + $short_d]
    if {$top >= $opt(y)} {
        set top [expr $opt(y) - $opt(precision)]
    }
    set bottom [expr $s_y - $short_d]
    if {$bottom <= 0} {
        set bottom $opt(precision)
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
proc in_subregion {target_ k level time_stamp} {
    global opt
    upvar 1 $target_ target
    $target update_position

    #if {![llength $opt(grid)]} {}
    if {![llength $subregions($k)]} {
        return 0
    }
    incr level -1
    set t_x [$target set X_]
    set t_y [$target set Y_]
    #set g_x [lindex [lindex $opt(grid) $level] 0]
    #set g_y [lindex [lindex $opt(grid) $level] 1]
    set g_x [lindex [lindex $subregions($k) $level] 0]
    set g_y [lindex [lindex $subregions($k) $level] 1]
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

## If the target is in Monitoring Region
#proc in_region {target_ time_stamp} {
#    global opt
#    upvar 1 $target_ target
#    $target update_position
#    if {![llength $opt(grid)]} {
#        return 0
#    }
#    set t_x [$target set X_]
#    set t_y [$target set Y_]
#    set g_x [lindex [lindex $opt(grid) 0] 0]
#    set g_y [lindex [lindex $opt(grid) 0] 1]
#    set vari [expr $opt(grid_length) * 3.0 / 2]
#    set right [expr $g_x + $vari]
#    set left [expr $g_x - $vari]
#    set top [expr $g_y + $vari]
#    set bottom [expr $g_y - $vari]
#    if {$t_x >= $left && $t_x <= $right && $t_y >= $bottom && $t_y <= $top} {
#        return 1
#    } else {
#        return 0
#    }
#}

# Build up the Monitoring Field for the target
#proc gridding {target_ time_stamp} {}
proc gridding {k time_stamp} {
    global opt subregions targets thetas mnodes candidates
    #upvar 1 $target_ target
    set target $targets($k)
    $target update_position

    # Get candidate set S for Target k
    set candidates($k) {};
    $targets($k) update_position
    set tx [$targets($k) set X_]
    set ty [$targets($k) set Y_]
    for {set m 0} {$m < $opt(nmnode)} {incr m} {
        set sx [$mnodes($m) set X_]
        set sy [$mnodes($m) set Y_]
        set dist [distance_xy $sx $sy $tx $ty]
        if {$dist <= $opt(dist_limit)} {
            lappend candidates($k) $m
        }
    }

    # Set subregions for Target k
    set subregions($k) {}
    set theta [lindex $thetas($k) $time_stamp]
    set pi2eight [expr $opt(Pi) / 8]
    set target_x [$target set X_]
    set target_y [$target set Y_]
    lappend subregions($k) [list $target_x $target_y]; # Level-1
    set x1 $target_x
    set y1 $target_y
    set x_right [expr $x1 + $opt(grid_length)]
    set x_left [expr $x1 - $opt(grid_length)]
    set y_top [expr $y1 + $opt(grid_length)]
    set y_bottom [expr $y1 - $opt(grid_length)]
    if {$x_right >= $opt(x)} {
        set x_right [expr $opt(x) - $opt(precision)]
    }
    if {$x_left <= 0} {
        set x_left $opt(precision)
    }
    if {$y_top >= $opt(y)} {
        set y_top [expr $opt(y) - $opt(precision)]
    }
    if {$y_bottom <= 0} {
        set y_bottom $opt(precision)
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
        lappend subregions($k) $sub(right); # Level-2
        lappend subregions($k) $sub(top_right); # Level-3
        lappend subregions($k) $sub(bottom_right); # Level-3
        lappend subregions($k) $sub(top); # Level-4
        lappend subregions($k) $sub(bottom); # Level-4
        lappend subregions($k) $sub(top_left); # Level-5
        lappend subregions($k) $sub(bottom_left); # Level-5
        lappend subregions($k) $sub(left); # Level-6
    } elseif {$theta >= $pi2eight && $theta < 3*$pi2eight} {
        lappend subregions($k) $sub(top_right); # Level-2
        lappend subregions($k) $sub(top); # Level-3
        lappend subregions($k) $sub(right); # Level-3
        lappend subregions($k) $sub(top_left); # Level-4
        lappend subregions($k) $sub(bottom_right); # Level-4
        lappend subregions($k) $sub(left); # Level-5
        lappend subregions($k) $sub(bottom); # Level-5
        lappend subregions($k) $sub(bottom_left); # Level-6
    } elseif {$theta >= 3*$pi2eight && $theta < 5*$pi2eight} {
        lappend subregions($k) $sub(top); # Level-2
        lappend subregions($k) $sub(top_left); # Level-3
        lappend subregions($k) $sub(top_right); # Level-3
        lappend subregions($k) $sub(left); # Level-4
        lappend subregions($k) $sub(right); # Level-4
        lappend subregions($k) $sub(bottom_left); # Level-5
        lappend subregions($k) $sub(bottom_right); # Level-5
        lappend subregions($k) $sub(bottom); # Level-6
    } elseif {$theta >= 5*$pi2eight && $theta < 7*$pi2eight} {
        lappend subregions($k) $sub(top_left); # Level-2
        lappend subregions($k) $sub(left); # Level-3
        lappend subregions($k) $sub(top); # Level-3
        lappend subregions($k) $sub(bottom_left); # Level-4
        lappend subregions($k) $sub(top_right); # Level-4
        lappend subregions($k) $sub(bottom); # Level-5
        lappend subregions($k) $sub(right); # Level-5
        lappend subregions($k) $sub(bottom_right); # Level-6
    } elseif {$theta >= 7*$pi2eight || $theta < -7*$pi2eight} {
        lappend subregions($k) $sub(left); # Level-2
        lappend subregions($k) $sub(bottom_left); # Level-3
        lappend subregions($k) $sub(top_left); # Level-3
        lappend subregions($k) $sub(bottom); # Level-4
        lappend subregions($k) $sub(top); # Level-4
        lappend subregions($k) $sub(bottom_right); # Level-5
        lappend subregions($k) $sub(top_right); # Level-5
        lappend subregions($k) $sub(right); # Level-6
    } elseif {$theta >= -7*$pi2eight && $theta < -5*$pi2eight} {
        lappend subregions($k) $sub(bottom_left); # Level-2
        lappend subregions($k) $sub(bottom); # Level-3
        lappend subregions($k) $sub(left); # Level-3
        lappend subregions($k) $sub(bottom_right); # Level-4
        lappend subregions($k) $sub(top_left); # Level-4
        lappend subregions($k) $sub(right); # Level-5
        lappend subregions($k) $sub(top); # Level-5
        lappend subregions($k) $sub(top_right); # Level-6
    } elseif {$theta >= -5*$pi2eight && $theta < -3*$pi2eight} {
        lappend subregions($k) $sub(bottom); # Level-2
        lappend subregions($k) $sub(bottom_right); # Level-3
        lappend subregions($k) $sub(bottom_left); # Level-3
        lappend subregions($k) $sub(right); # Level-4
        lappend subregions($k) $sub(left); # Level-4
        lappend subregions($k) $sub(top_right); # Level-5
        lappend subregions($k) $sub(top_left); # Level-5
        lappend subregions($k) $sub(top); # Level-6
    } elseif {$theta >= -3*$pi2eight && $theta < -$pi2eight} {
        lappend subregions($k) $sub(bottom_right); # Level-2
        lappend subregions($k) $sub(right); # Level-3
        lappend subregions($k) $sub(bottom); # Level-3
        lappend subregions($k) $sub(top_right); # Level-4
        lappend subregions($k) $sub(bottom_left); # Level-4
        lappend subregions($k) $sub(top); # Level-5
        lappend subregions($k) $sub(left); # Level-5
        lappend subregions($k) $sub(top_left); # Level-6
    }
}

# Return its Level number for the index in the subregion list
proc index2level {index} {
    switch -exact -- $index {
        0 {return 1}
        1 {return 2}
        2 -
        3 {return 3}
        4 -
        5 {return 4}
        6 -
        7 {return 5}
        8 {return 6}
        default {return "Error"}
    }
}

# Return corresponding metric value for the node and the subregion
proc get_metric {mx my sx sy level} {
    set dist [distance_xy $mx $my $sx $sy]
    set result [expr $dist * $level]
    return $result
}

# Calculate the metric set W for all sensors with all subregions
# An candidate should be a list of {m, k, z, metric}
proc get_all_metrics {metrics_ time_stamp} {
    global opt mnodes subregions candidates
    upvar 1 $metrics_ metrics
    set metrics {}
    # Get all candidates (maybe not all sensors)
    for {set m 0} {$m < $opt(nmnode)} {incr m} {
        set is_candidate($m) 0; # flag
    }
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        foreach ele $candidates($k) {
            set is_candidate($ele) 1; # record all candidates with 1
        }
    }

    # Calculate all metrics
    for {set m 0} {$m < $opt(nmnode)} {incr m} {
        if {!$is_candidate($m)} {
            continue
        }
        $mnodes($m) update_position
        set mx [$mnodes($m) set X_]; # coordinates of mobile node
        set my [$mnodes($m) set Y_]
        for {set k 0} {$k < $opt(ntarget)} {incr k} {
            set size [llength $subregions($k)]
            for {set z 0} {$z < $size} {incr z} {
                # coordinates of subregion
                set sx [lindex [lindex $subregions($k) $z] 0]
                set sy [lindex [lindex $subregions($k) $z] 1]
                set level [index2level $z]
                set metric [get_metric $mx $my $sx $sy $level]
                # Insert metric orderly
                set length [llength $metrics]
                for {set i 0} {$i < $length} {incr i} {
                    set tmp_m [lindex [lindex $metrics $i] 3]
                    if {$tmp_m > $metric} {
                        break
                    }
                }
                set metrics [linsert $metrics $i [list $m $k $z $metric]]
            }
        }
    }
}

# Dispatch mobile sensors for tarcking
#proc dispatching {target_ time_stamp} {}
proc dispatching {time_stamp} {
    global opt mnode moving_sensors subregions level2_index
    # Stop moving sensors
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        foreach index $moving_sensors($k) {
            $mnodes($index) update_position
            set x [$mnodes($index) set X_]
            set y [$mnodes($index) set Y_]
            $mnodes($index) setdest $x $y $opt(mnode_speed)
        }
        set moving_sensors($k) {}
    }

    # Reset all level-2 node
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        set level2_index($k) -1
    }

    # Get all metrics
    set metrics {}
    get_all_metrics metrics $time_stamp;  # Need a Test now.

    # Flags for nodes
    for {set m 0} {$m < $opt(nmnode)} {incr m} {
        set node_flag 0
    }
    # Flags for subregions of all targets
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        set sr_flag($k) {}
        for {set z 0} {$z < $opt(nine)} {incr z} {
            lappend sr_flag($k) 0
        }
    }

    # Dispatching sensor
    foreach ele $metrics {
        set m [lindex $ele 0];  # Index of Node
        set k [lindex $ele 1];  # Index of Target
        set z [lindex $ele 2];  # Index of Subregion
        if {$node_flag($m) || [lindex $sr_flag($k) $z]} {
            continue
        }

        # Todo 20160123-23:11
        # Dispatch Sensor m to Subregion z of Target k
        # Add Sensor m to moving_sensors($k)
        # if z==1 then set level2_index($k) m
    }
}

# Scheduling mobile node actions
proc mobile_node_action {time_stamp} {
    global opt mnodes targets moving_sensors tracking_index level2_index
    puts "================= At $time_stamp ================="; # test
    # Need to set up new subregions
    set dispatch_flag 0;        # If need re-dispatch nodes to targets
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        if {$tracking_index($k) == -1 \
                || ![in_subregion targets($k) $k 1 $time_stamp]} {
            #puts "Let's MOVE NOW!"; # test
            puts "Target $k needs grid."; # test
            gridding $k $time_stamp
            set dispatch_flag 1
        }
    }
    if {$dispatch_flag} {
        dispatching $time_stamp
        #if {![llength $opt(moving_list)]} {
        #    return
        #}
    }

    # Todo 20160123-23:11
    # Dispatch the Level 2 node of all targets
    # Dispatch the closest node of every target for tracking
    # Update the EMT of all targets

    #===============================================
    # Old codes.
    # Need a For Loop for all targets
    #===============================================
    ## Get the closest sensor
    #set dist_min [expr 2 * $opt(x)]
    #set index_min -1
    #foreach index $opt(moving_list) {
    #    set dist [distance mnodes($index) targets(0) $time_stamp]
    #    if {$dist < $dist_min} {
    #        set dist_min $dist
    #        set index_min $index
    #    }
    #}

    ## Dispatch the Level 2 sensor for tracking
    #if {$opt(level2_index) != -1 && \
    #    [in_subregion mnodes($opt(level2_index)) 2 $time_stamp]} {
    #    $targets(0) update_position
    #    set t_x [$targets(0) set X_]
    #    set t_y [$targets(0) set Y_]
    #    destination_xy_level2 mnodes($opt(level2_index)) $t_x $t_y $time_stamp
    #}

    ## Dispatch the sensor for tracking
    #$targets(0) update_position
    #set t_x [$targets(0) set X_]
    #set t_y [$targets(0) set Y_]
    #destination_xy_dfov mnodes($index_min) $t_x $t_y $time_stamp
    ##puts "Tracking sensor: $index_min"; # test


    ## Update the EMT and Total Movement
    #if {$dist_min <= $opt(d_fov)} {
    #    set opt(tracking_index) $index_min
    #    incr opt(effective_monitoring_time) $opt(time_click)
    #    foreach i $opt(moving_list) { ; # Stop other sensors
    #        if {$i == $index_min} {
    #            continue
    #        }
    #        $mnodes($i) update_position
    #        set x [$mnodes($i) set X_]
    #        set y [$mnodes($i) set Y_]
    #        $mnodes($i) setdest $x $y $opt(mnode_speed)
    #    }
    #} else {
    #    set opt(tracking_index) -1
    #    #puts "Can't monitor the target"; # test
    #}
    #===============================================
    # /Old codes.
    #===============================================
}

#===================================
#        Generate movement
#===================================
# The schedule of Targets' Movement
for {set i 0}  {$i < $opt(ntarget)} {incr i} {
    set time_line 0
    set target_lx [$targets($i) set X_]
    set target_ly [$targets($i) set Y_]
    set to_move 1
# The schedule of Target i
    while {$time_line < $opt(stop)} {
        #set time_stamp $time_line

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
                #lappend opt(target_theta) $target_theta
                lappend thetas($i) $target_theta
            }
            incr time_line $stop_time
            set to_move 1
            continue
        }

# A Movement of this Target
        set dest_x [$rd_x value]
        set dest_y [$rd_y value]
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
            lappend thetas($i) $target_theta
        }
        $ns at $time_line "$targets($i) setdest $dest_x $dest_y $target_speed"
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
set opt(s_posi_list) {};        # Positions of sensors
proc step_distance {time_stamp} {
    global opt mnodes

    set total_dist 0
    set temp_list {}
    for {set i 0} {$i < $opt(nmnode)} {incr i} {
        set lx [lindex [lindex $opt(s_posi_list) $i] 0]
        set ly [lindex [lindex $opt(s_posi_list) $i] 1]
        $mnodes($i) update_position
        set px [$mnodes($i) set X_]
        set py [$mnodes($i) set Y_]
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
set opt(s_posi_list) {}
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    set x [$mnodes($i) set X_]
    set y [$mnodes($i) set Y_]
    lappend opt(s_posi_list) [list $x $y]
}
while {$time_line <= $opt(stop)} {
    $ns at $time_line "step_distance $time_line"
    incr time_line $opt(time_click)
}
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
    #puts "Effective Monitoring Time: $opt(effective_monitoring_time)"
    #puts "Total Moving Distance: $opt(total_moving_distance)"
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
    $ns at $opt(stop) "$targets($i) reset"
}
for {set i 0} {$i < $opt(nmnode)} {incr i} {
    $ns at $opt(stop) "$mnodes($i) reset"
}
#for {set i 0} {$i < $opt(nfnode)} {incr i} {
#    $ns at $opt(stop) "$fnode($i) reset"
#}

# Finish
$ns at $opt(stop) "finish"
$ns at $opt(stop) "puts \"Done.\"; $ns halt"
$ns run
