###########################################################################
###########################################################################
# We don't want any fun by default
set fun 0
# Check if someone wants his fun
foreach arg $::argv {
    set wantFun [regexp -nocase fun $arg]
    if $wantFun {set fun 1}
}
if {$fun} {
    package require snack
    package require snackogg
    # Animation interval
    set  interval 30
    # "Sun" x and y coordinates
    set  sx 0
    set  sy 10
    # Sun's horizontal and vertical velocities
    set  dx  1
    set  dy  1
    # We need some canvas to draw our sun on
    canvas .c -height 80 -background #6495ed
    # Pack canvas
    pack   .c -fill x
    proc init-anim {} {
	global cwidth cheight numclouds
	# Open image for sun
	image create photo imSun -format png \
	    -file [file join [file dirname [info script]] sun.png]
	# Open image for clouds
	image create photo imCloud -format png \
	    -file [file join [file dirname [info script]] cloud.png]
	# Dimensions of canvas
	set cwidth  800
	set cheight [.c cget -height]
	set numclouds [expr round($cwidth / 370 * 5)]
	# Generate coordinates and horizontal velocities for each cloud
	for {set i 0} {$i < $numclouds} {incr i} {
	    # Coordinates
	    global clx$i
	    global cly$i
	    global cldx$i
	    set clx$i  [expr int(rand()*$cwidth)]
	    set cly$i  [expr int(rand()*($cheight))] 
	    # Horizontal velocities
	    set cldx$i [expr 1+rand()*2]
	}
	# Bind animation proc
	bind   .c <Map> animate
    }
    # Command for drawing the sun
    proc sun {x y} {
	# For now our sun is simply the image
	.c create image $x $y -image imSun
    }
    # Do the hard work of animation
    proc animate {} {
	# Animation interval
	global interval
	# Sun coordinates
	global sx sy
	# Sun velocities
	global dx dy
	# Canvas dimensions
	global cheight
	set cwidth [winfo width .]
	# Number of clouds
	global numclouds
	# Generate bindings for cloud coords and velocities
	for {set i 0} {$i < 5} {incr i} {	
	    global clx$i cly$i
	    global cldx$i
	}
	# Clear canvas before each frame
	.c delete all
	# Redraw clouds
	for {set i 0} {$i < $numclouds} {incr i} {
	    # Pass cloud coordinates...
	    upvar clx$i clx
	    upvar cly$i cly
	    # ...and velocity
	    upvar cldx$i cldx
	    # Draw cloud
	    .c create image $clx $cly -image imCloud
	    # Check if we're out of canvas
	    if {$clx > $cwidth + 64} {
		#Oh, God, we are!
		# Put the cloud at the beginning...
		set clx -64
		# ...with random y coordinate...
		set cly  [expr int(rand()*($cheight))] 
		# ...and random velocity
		set cldx [expr 1+rand()*2]
	    }
	    # Move the cloud forward
	    incr clx [expr int($cldx)]
	}
	# We're done with clouds, draw the sun
	sun $sx $sy
	# Sun reflection
	if {$sy + 30 > $cheight} {set dy -1}
	if {$sy < 30}            {set dy 1}
	if {$sx + 30 > $cwidth}  {set dx -1}
	if {$sx < 30}            {set dx 1}
	# Advance sun coordinates
	incr sx $dx
	incr sy $dy
	# Draw next frame
	after $interval animate
    }
    # Oh, you want a sound!
    # Let's create some snack object
    snack::sound music
    # Open our sound file
    music configure -file [file join [file dirname [info script]] music.ogg]
    # Looping sound procedure
    proc play-sound {} {music play -command play-sound}
    # Start extra-fun!
    play-sound
    init-anim
}