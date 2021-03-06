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
set opt(nmnode) 30                         ;# number of mobile nodes
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
set opt(AVG_EMT) 0;             # Average Effective Monitoring Time

source $opt(normal)
if {0 < $argc} {
    #set opt(nfnode) [lindex $argv 0]
    #set opt(nmnode) [lindex $argv 0]
    #set opt(hole_number) [lindex $argv 0]
    set opt(target_speed_max) [lindex $argv 0]
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
    #set subregions($i) {}; # Subregions List of target i
    set moving_sensors($i) {};    # List of Moving Sensors to target i
    set candidates($i) {};        # List of Candidate-sensor for target i
    set tracking_index($i) -1; # Index of Tracking Sensor for target i
    #set level2_index($i) -1;    # Index of Level 2 sensor for target i
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


# Build up the Monitoring Field for the target
#proc gridding {target_ time_stamp} {}
proc gridding {k time_stamp} {
    global opt targets thetas mnodes candidates
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
}

# Return corresponding metric value for the node and the target
proc get_metric {mx my tx ty} {
    global opt
    set dist [distance_xy $mx $my $tx $ty]
    set result $dist
    return $result
}

# Calculate the metric set W for all sensors with all subregions
# An candidate should be a list of {m, k, metric}
proc get_all_metrics {metrics_ time_stamp} {
    global opt mnodes targets candidates
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
            set tx [$targets($k) set X_]
            set ty [$targets($k) set Y_]
            set metric [get_metric $mx $my $tx $ty]
            # Insert metric orderly
            set length [llength $metrics]
            for {set i 0} {$i < $length} {incr i} {
                set tmp_m [lindex [lindex $metrics $i] 2]
                if {$tmp_m > $metric} {
                    break
                }
            }
            set metrics [linsert $metrics $i [list $m $k $metric]]
        }
    }
}

# Dispatch mobile sensors for tarcking
proc dispatching {time_stamp} {
    global opt mnodes moving_sensors targets
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

    # Get all metrics
    set metrics {}
    get_all_metrics metrics $time_stamp

    # Flags for nodes
    for {set m 0} {$m < $opt(nmnode)} {incr m} {
        set node_flag($m) 0
    }
    ## Flags for all targets
    #for {set k 0} {$k < $opt(ntarget)} {incr k} {
    #    set target_flag($k) 0
    #}

    # Dispatching sensor
    foreach ele $metrics {
        set m [lindex $ele 0];  # Index of Node
        set k [lindex $ele 1];  # Index of Target
        #puts "{m, k, z}: {$m, $k, $z}"; # test
        if {$node_flag($m)} {
            continue
        }
        set node_flag($m) 1
        #set sr_flag($k) [lreplace $sr_flag($k) $z $z 1]

        # Dispatch Sensor m to Target k
        set dest_x [$targets($k) set X_]
        set dest_y [$targets($k) set Y_]
        #puts "dest: ($dest_x, $dest_y), m = $m"; # test
        #puts "Dispatch: {m$m, k$k, z$z}"; # test
        $mnodes($m) setdest $dest_x $dest_y $opt(mnode_speed)
        #destination_xy_dfov mnodes($m) $dest_x $dest_y $time_stamp
        # Add Sensor m to moving_sensors($k)
        lappend moving_sensors($k) $m
        ## If it is Level-2 node
        #if {$z == 1} {
        #    set level2_index($k) $m
        #}
    }
}

# Scheduling mobile node actions
proc mobile_node_action {time_stamp} {
    global opt mnodes targets moving_sensors tracking_index EMT
    #puts "================= At $time_stamp ================="; # test
    # Need to set up new subregions
    set dispatch_flag 0;        # If need re-dispatch nodes to targets
    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        if {$tracking_index($k) == -1} {
            #puts "Let's MOVE NOW!"; # test
            #puts "Target $k needs grid."; # test
            gridding $k $time_stamp
            set dispatch_flag 1
        }
    }
    if {$dispatch_flag} {
        dispatching $time_stamp
    }

    for {set k 0} {$k < $opt(ntarget)} {incr k} {
        $targets($k) update_position
        set tx [$targets($k) set X_]
        set ty [$targets($k) set Y_]
        # Dispatch the closest node of every target for tracking
        set dist_min [expr 2.0 * $opt(x)]
        set index_min -1
        # The moving_sensors is in order actually!
        if {[llength $moving_sensors($k)]} {
            set index_min [lindex $moving_sensors($k) 0]
            set dist_min [distance mnodes($index_min) targets($k) $time_stamp]
        }

        #foreach index $moving_sensors($k) {
        #    set dist [distance mnodes($index) targets($k) $time_stamp]
        #    puts "Sensor $index to Target $k ($dist)"; # test
        #    if {$dist < $dist_min} {
        #        set dist_min $dist
        #        set index_min $index
        #    }
        #}
        #if {$index_min != -1} {
        #    destination_xy_dfov mnodes($index_min) $tx $ty $time_stamp
        #    #$mnodes($index_min) setdest $tx $ty $opt(mnode_speed)
        #}
        # Update the EMT of all targets
        #puts "dist_min (Sensor $index_min): $dist_min / ($opt(d_fov))"; # test
        if {$dist_min <= $opt(d_fov)} {
            #puts "YES! Track."; # test
            set tracking_index($k) $index_min
            incr EMT($k) $opt(time_click)
            foreach ele $moving_sensors($k) {
                if {$ele == $index_min} {
                    continue
                }
                $mnodes($ele) update_position
                set x [$mnodes($ele) set X_]
                set y [$mnodes($ele) set Y_]
                $mnodes($ele) setdest $x $y $opt(mnode_speed)
            }
        } else {
            #puts "No. lost.";   # test
            set tracking_index($k) -1
        }
        #puts "EMT($k): $EMT($k)"; # test
    }
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
proc average_emt {} {
    global EMT opt
    set sum 0
    for {set i 0} {$i < $opt(ntarget)} {incr i} {
        incr sum $EMT($i)
        #puts "EMT($i): $EMT($i)"; # test
    }
    set opt(AVG_EMT) [expr 1.0 * $sum / $opt(ntarget)]
}

# Calculate the results
proc getting_results {} {
    average_emt
}

# Define a 'finish' procedure
proc output_file {} {
    global ns opt
    set result_file [open $opt(result_file) a]
    puts $result_file \
         "$opt(target_speed_max) \
          $opt(AVG_EMT) \
          $opt(total_moving_distance)"
    flush $result_file
    close $result_file
}
proc finish {} {
    global ns tracefile namfile opt argc
    getting_results
    #puts "Effective Monitoring Time: $opt(effective_monitoring_time)"
    puts "Average Effective Monitoring Time: $opt(AVG_EMT)"
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
