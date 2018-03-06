#!/usr/bin/env tclsh

source names_generator.tcl

set gametag {
 _     _  __        ____                             _ 
| |   (_)/ _| ___  | __ )  ___ _   _  ___  _ __   __| |
| |   | | |_ / _ \ |  _ \ / _ \ | | |/ _ \| '_ \ / _` |
| |___| |  _|  __/ | |_) |  __/ |_| | (_) | | | | (_| |
|_____|_|_|  \___| |____/ \___|\__, |\___/|_| |_|\__,_|
                               |___/                   
    _                          _                      
   / \   _ __   ___   ___ __ _| |_   _ _ __  ___  ___ 
  / _ \ | '_ \ / _ \ / __/ _` | | | | | '_ \/ __|/ _ \
 / ___ \| |_) | (_) | (_| (_| | | |_| | |_) \__ \  __/
/_/   \_\ .__/ \___/ \___\__,_|_|\__, | .__/|___/\___|
        |_|                      |___/|_|                      
                                                 
}       


array set settings {
	money 20
	health 20
	maxhealth 20
	energy 50
	maxenergy 50
	experience 0
	totalexperience 0
	
	attack 3
	defence 3
	
	infected 0
	
	water 10
	food 10
	x 5
	y 5
}         
array set visitedTiles {
	5,5 1
}
#For every 100 XP increase
# 5 hp, 10 energy, 1 attack, 1 defence    
#nextlevel expr 2**7*17
set enemystats {
	rat { hp 10 defence 1 attack 1  }
	bat { hp 10 defence 1 attack 2  }
	crow { hp 15 defence 2 attack 2 }
	dog { hp 20 defence 3 attack 4  }
	zombie { hp 30 defence 5 attack 5 }
}        

#InfectionChance means 1 in nr chance to get infected when attacking zombie
set items {
	"First Aid Kit" { health 5 oneuse 1 price 10  }
	"Energizer" { energy 10 oneuse 1  price 10 }
	
	"Baseball Bat" { damage 2 accuracy 50 price 30 infectionChance 4 }
	Axe { damage 3 accuracy 50 price 70 infectionChance 5 }
	"Kantana" { damage 4 accuracy 60 price 100  infectionChance 7}
	"Bullet" { usewith Gun  accuracy 50 price 0.2 }
	Gun { requires Bullet damage 5 price 170 infectionChange 13}
	
	"Noob Armour" { defence 2 price 30 }
	"Simple Armour" { defence 3 price 70  }
	"Protective Armour" { defence 4 price 100  }
	"Zombie Slayer Armour" { defence 5 price 170  }
	
	"Canned Food" { food 5 }
	"Water Bottle" { water 5 }
	
	"Survival Syringe" { price 50 }
}

array set bashcolor {
	bold \033\[1m
	dim \033\[2m
	underline \033\[4m
	blink \033\[5m
	inverted \033\[7m
	hidden \033\[8m
	reset \033\[0m
	
	black \033\[30m
	red \033\[31m
	green \033\[32m
	yellow \033\[33m
	blue \033\[34m
	magenta \033\[35m
	purple \033\[35m
	cyan \033\[36m
	lightgray \033\[37m
	darkgray \033\[90m
	lightred \033\[91m
	lightgreen \033\[92m
	lightyellow \033\[93m
	lightblue \033\[94m
	lightmagenta \033\[95m
	lightpurple \033\[95m
	lightcyan \033\[96m
	white \033\[97m
	
	blackbackground  \033\[40m
	redbackground  \033\[41m
	greenbackground  \033\[42m
	yellowbackground  \033\[43m
	bluebackground  \033\[44m
	magentabackground  \033\[45m
	purplebackground  \033\[45m
	cyanbackground  \033\[46m
	lightgraybackground  \033\[47m
	
	darkgraybackground \033\[100m
	lightredbackground \033\[101m
	lightgreenbackground \033\[102m
	lightyellowbackground \033\[103m
	lightbluebackground \033\[104m
	lightmagentabackground \033\[105m
	lightpurplebackground \033\[105m
	lightcyanackground \033\[106m
	whitebackground \033\[107m
	
}

proc color {color} {
	global bashcolor
	return  $bashcolor($color)
}
proc rnd {min max} {
		expr {int(($max - $min + 1) * rand()) + $min}
}

proc progressbar {current max {char "#"} {level 25}} {
	set currentNr [expr {int($current/double($max)*$level)}]
	set maxNr [expr {int($max/double($max)*$level)-$currentNr}]
	set full [string repeat $char $currentNr]
	set empty [string repeat - $maxNr]
	return "\[$full$empty\]"
}
set currentMenu  { w {move w}   west {move w}  
		e {move e} east {move e}   north {move n}  n {move n}
		s {move s} south {move s}
		help generalHelp 
		who whoIsHere
		map drawMap
		stats userStats
		statistics userStats
		search searchForItems
		gamestatus gameStatus
		status gameStatus
		
		sleep sleepToRecoverEnergy
		rest sleepToRecoverEnergy
}
proc generalHelp {} {
	global bashcolor
	puts "[color lightblue]=-=-=-=-= HELP  / COMMANDS =-=-=-=-= [color lightgray]"
	puts "Everything you type is a potential command, you have case specific commands for various situations and global commands.
[color underline]A list of global commands available anywhere:[color reset]"
	puts "[color lightgreen][color bold] w(est), e(ast), n(orth), w(est)[color reset] are commands that can be used to move around the map"
	puts "[color lightgreen][color bold] who [color reset] to view who is at a location type"
	puts "[color lightgreen][color bold] stats [color reset] to view your user stats"
	puts "[color lightgreen][color bold] map [color reset] to view an up to date map"
	puts "[color lightgreen][color bold] search [color reset] to search for something useful"
	puts "[color lightgreen][color bold] status [color reset] to see the game status" 
	puts "[color lightgreen][color bold] sleep | rest [color reset] to recover energy and some HP" 
	puts "[color lightblue]=-=-=-=-= END OF HELP  / COMMANDS =-=-=-=-=[color reset]"
	readUserOption 1
}
proc showMenu {menu text {numeric 1}} {
	global currentMenu
	set oldMenu $currentMenu
	set currentMenu ""
	set i 0
	puts [string repeat =- 33]
	puts $text
	foreach {option proc} $menu {
		incr i
		puts "$i. $option"
		dict set currentMenu $i $proc
	}
	puts -nonewline "\noption (1-$i)> "
	append currentMenu " " $oldMenu
}
proc readUserOption {{verbose 0}} {
	global currentMenu
	if {$verbose} {
		puts -nonewline "\n> "
	}
	set isOk 0
	while { !$isOk } {
		gets stdin menu
		set menu [string tolower $menu]
		if {[dict exists $currentMenu [set partial [string trim [lindex $menu 0]]]]} { set isOk 1 ; break}
		puts "This option doesn't exist."
		puts -nonewline "\n> "
	}
	puts "$menu "
	#if {[info args [dict get $currentMenu $partial ]] != "" } {
#		{*}[dict get $currentMenu $partial] [lrange $menu 1 end]
	#} else {
		{*}[dict get $currentMenu $partial]
	#}
}
proc mainMenu {} {
	global settings
	showMenu { 
		"General Help" generalHelp
		"See who is here" whoIsHere
		"Sleep" sleepToRecoverEnergy
		"View map" drawMap
		"User stats"  {userStats}
	} "What do you do next?" 
	readUserOption
}
proc useEnergy {reqEnergy {text ""} } {
	global settings bahcolor warnings
	if {![verifyAlive]}  { return -level 2 }
	if {[expr {$settings(energy)/double($settings(maxenergy))}] < 0.2 && ![info exists warnings(energy)]} { 
		puts "[color red]WARNING![color reset] Your energy level is low, find a place to rest!" 
		set warnings(energy) 1
		after 10000 [list unset warnings(energy)]
	}
	if {$settings(energy) < $reqEnergy} { 
		puts [report warning "You do not have enough energy to perform this action. " ]
		after 1 [readUserOption 1]
		return -level 2
	}
	incr settings(energy) -$reqEnergy
	gameActions
}

proc useEnergyNPC {npcID reqEnergy } {
	
	if {$settings(energy) < $reqEnergy} { 
		puts [report warning "You do not have enough energy to perform this action. " ]
		after 1 [readUserOption 1]
		return -level 2
	}

}
proc showHealth {min max {length 25}} {
	global bashcolor
	set relative [expr {$min/double($max)}]
	if {$relative > 0.75} {
		set color [color lightgreen]
	} elseif {$relative > 0.50} {
		set color [color lightblue]
	} elseif {$relative > 0.25} {
		set color [color lightyellow]
	} else {
		set color [color red]
	}
	return "$color[progressbar $min $max # $length][color reset]"
}
proc userStats {} {
	global settings bashcolor
	puts [string repeat =- 33]\n
	puts "Your stats:"
	
	puts [format "%-20s %s%s %s" [string totitle health]: [color lightgreen] [progressbar $settings(health) $settings(maxhealth)] "($settings(health)/$settings(maxhealth)) [color reset]"]
	puts [format "%-20s %s%s %s" [string totitle Energy]: [color lightcyan] [progressbar $settings(energy) $settings(maxenergy)] "($settings(energy)/$settings(maxenergy)) [color reset]"]
	
		
	foreach {var} {money  experience totalexperience  water food attack defence  } {
		puts [format "%-20s  %s%s%s" [string totitle $var]: [color lightgreen] $settings($var) [color reset]]
	}
	
	puts [string repeat =- 33]\n
	readUserOption 1
}
proc searchForItems {} {
	global settings map
foreach {nr} { 1 2 3 4 5 6 7 8 9 0} {
	useEnergy  1
	set x $settings(x)
	set y $settings(y)
	set tile [string index [lindex [dict get $map map] $y-1] $x-1]

	switch -- $tile {
		"#" { set chance 3 }
		=  {  set chance 6 }
		@  { set chance 8 }
	}
	if {[rnd 1 10]  >= $chance} {
		set money [rnd 1 7]
		puts [report success "While searching you've found [color green]\$$money [color reset]"]
		incr settings(money) $money
	} else {
		puts [report info "You searched but didn't find anything."]
	}
}
	readUserOption 1
}

proc sleepToRecoverEnergy {} {
	global settings
	foreach {var} {1 2 3 4 5} { gameActions }
	set text "You've slept and now feel rested. "
	set settings(energy) $settings(maxenergy)
	if {$settings(maxhealth)>$settings(health) && !$settings(infected)} {
		incr $settings(health) [set hp [rnd 1 2]]
		append text "You've recovered $hp health."
	}
	puts [report success  $text ]
	readUserOption 1
}
#TODO make user chose to respawn as NPC (10 randomly selected NPC's)
proc verifyAlive {} {
	global settings
	handleInfection
	if {$settings(health) <= 0} {
		puts [report danger "You are dead.. Respawn as a NPC"]
		after 1 [readUserOption 1]
		return 0
	}
	return 1
}
proc handleInfection {} {
	global settings
	if {$settings(infected)} {
		incr $settings(health) -[set hp [rnd 1 2]]
		puts [report notice "INFECTION: -$hp HP"]
		if {$settings(health) <= 0} {
			puts [report danger "You have died because of the infection!"]
		}
	}
}

proc gameStatus {} {
	global map
	puts "[color blue][string repeat =- 13] Game status [string repeat -= 13][color reset]"
	puts "[color bold][color green] Alive: [dict get $map alive] \t[color red]Zombies: [dict get $map zombies] \t[color yellow] Dead: [dict get $map dead][color reset]"
	puts "[color blue][string repeat =- 33][color reset]"
	readUserOption 1
}
                  
if {0} {
	MAP
	
@ Forest
# Building 
= Street
& Forest
$ Shop
? Unknown
! Action Required

map {
#=#=#=#=#@@@@	
#=#=#=#=#@@@@	
#=#=#=#=#@@#@	
#=#=#=#=#@@@@	
#=#=#=#=#===#	
#=#=#=#=#@@@@	
#=#=#=#=#@@@@
}

PEOPLE
Status: Friend/Hostile/Infected/Zombie/Dead

ORDERS based on friendship levels
LVL 5: Stay Here/Protect Zone
LVL 7: Follow me
LVL 8: Go to x,y and report

	
Each action you do takes time (5 minutes to 1 hour)
For each action you do, there is a % chance someone will do something (attack, be attacked, change location, die and become zombie)
#LightGreen YOU
#Green FRIEND
}
set map {
	map {#=#=#=#=#@@@@
#=#=#=#=#@@@@
#=#=#=#=#@@#@
#=#=#=#=#@@@@
#=#=#=#=#===#
#=#=#=#=#@@@@
#=#=#=#=#@@@@}
	name "Broken Hopes"
	alive 100
	zombies 1
	dead 0
	infected 0
	x 13
	y 7
}

#############################
# User Actions
#############################
proc drawMapOld {mapData} {
	global settings map visitedTiles bashcolor
	puts "You are in [dict get $map name]  at ($settings(x),$settings(y))"
	set x 1; set y 1
	foreach {yloc} [split $mapData \n] {
		foreach {location} [split [string trim $yloc] ""] {
			#puts -nonewline $location
			if {$x == $settings(x) && $y == $settings(y)} { puts -nonewline [color lightgreen] }
			if {[info exists visitedTiles($x,$y)]} { puts -nonewline $location[color reset] } else { puts  -nonewline [color lightred]?[color reset] }
			incr x
		}
		puts ""
		incr y; set x 1
	}
}
proc drawMap {{mapData ""}} {
	global settings map visitedTiles bashcolor
	if {$mapData == ""} { set mapData [dict get $map map] ; after 1 [list readUserOption 1] }
	puts "You are in [dict get $map name]  at ($settings(x),$settings(y))"

	for {set y 1} {$y<=[dict get $map y]} { incr y} {
		for {set x 1} {$x<=[dict get $map x]} { incr x} {
			if {$x == $settings(x) && $y == $settings(y)} { puts -nonewline [color lightgreen] }
			if {[info exists visitedTiles($x,$y)]} { puts -nonewline [string index [lindex $mapData $y-1] $x-1][color reset] } else { puts  -nonewline [color lightred]?[color reset] }
		}
		puts ""
	}

}

proc whoIsHere {} {
	global npc npcAtLocation settings bashcolor
	set x $settings(x)
	set y $settings(y)
	after 1 [list readUserOption 1]
	if {![info exists npcAtLocation($x,$y)]} {
		puts "There seems to be no one here"
		return 0
	}
	if {$npcAtLocation($x,$y) == ""} { 
		puts "There seems to be no one here"
		return 0
	}
	append peopleHere "People currently located here:\n"
	foreach nr $npcAtLocation($x,$y) {
		set status [dict get $npc($nr) status]
		set name [dict get $npc($nr)  name]
		switch $status {
			Friend { 	set statusColor [color greenbackground][color white]	} 
			"Hostile" {	set statusColor [color redbackground][color white]	}
			Infected {	set statusColor [color purplebackground][color white]	}
			
			Friend { 	set statusColor [color lightgreen]	} 
			"Hostile" {	set statusColor [color lightred]	}
			Infected {	set statusColor [color magenta]	}
			Dead { continue }
			Zombie { set statusColor  "[color lightred]" ; set name Zombie }
		}
		append peopleHere "$statusColor[color bold]$name[color reset][color lightgray] HP:[showHealth [dict get $npc($nr)  health] [dict get $npc($nr)  maxhealth]  10], "
	}	
	puts $peopleHere

	return [llength $nr]
}
proc move {location} {
	global map settings visitedTiles
	set x $settings(x)
	set y $settings(y)
	set maxx [dict get $map x]
	set maxy [dict get $map y]
	switch $location {
		n { incr y -1} 
		e { incr x 1} 
		w { incr x -1} 
		s { incr y 1} 
	}
	if {$x >= 1 && $y >= 1 && $maxx >= $x && $maxy>=$y} {
		useEnergy 1
		set settings(x) $x 
		set settings(y) $y
		set visitedTiles($x,$y) 1
	#	drawMap [dict get $map map]
	puts "You moved to ($x,$y)."
	} else { puts "You are at the edge of the town [dict get $map name]. You have nowhere else to go" }
	readUserOption 1
}

#############################
# NPC AI Actions
#############################
proc getNPC {id value} {
	global npc
	return [dict get $npc($id) $value]
}
proc setNPC {id key value} {
	global npc
	dict set npc($id) $key $value
}
proc incrNPC {id key value} {
	global npc
	dict incr npc($id) $key $value
}

proc getNPCName {id} {
	global npc
	if {[dict get $npc($id) status] == "Zombie"} {
		return "a Zombie"
	}
	return [dict get $npc($id) name]
}

#Player NPC Actions 
#For each 1 action of a player, the NPC's also do an action (which may be or may not be visible)

proc gameActions {} {
	zombieActions
	NPCActions
}
#Zombies always do actions: 
# attack (option  infect OR kill) 60% chance (if no one here, move)
#Move (30% chance)
# Attack barricade if no one here and building
#TODO implant chip in zombie to track it
proc zombieActions {} {
	global zombies npc npcAtLocation
	foreach zID $zombies {
		if {![verifyNPCAlive $zID]} {  set zombies [lremove $zombies $zID] ;  continue }
			RestIfLowOnEnergy  $zID
		if {[verifyPeopleHereForNPC $zID]} {
			#80% Attack people, 20% move
			if {[rnd 1 100] > 20} {
				set npcListToAttack [getNPCListWithoutZombiesForLocation $zID $zID]
				set attackID [lindex $npcListToAttack [rnd 1 [llength $npcListToAttack]]-1]
				if {$attackID != ""} { 
					puts "Zombie $zID attacks $attackID .. no one here?"
					NPCAttackNPC $zID $attackID
				}
			} else {
				changeLocationNPC $zID
			}		
		} else {
			#Attack barricade if building
			#OR move
			changeLocationNPC $zID
		}
	}
}

#RANDOM CHOSE 1 function.. 
#VERIFY IF POSSIBLE... and logical if not RANDOM CHOSE ANOTHER FUNCTION! 

# If people here
#	AND my status = Hostile => attack
#	AND my status = Friend => heal, socialize	
#If location= not building
# 	Actions: move  , search
#If Location = building 
#Move, attack  1 zombies or  2 humans if status = enemy, heal self (+1~3 HP), heal other(only if status=friend 1~3 HP), barricade building, 
# search items, craft something, rest, socialize, read book

proc NPCActions {} {
	global npc npcAtLocation zombies map
	#We only require alive NPC's for this one
	set npcList [getNPCListWithoutZombies]
	#puts "NPC's [llength $npcList]: \n $npcList"
	foreach npcID $npcList {
		if {![verifyNPCAlive $npcID]} {  continue }
		handleInfectedNPC $npcID
		
		RestIfLowOnEnergy  $npcID
		
		changeLocationIfNotInBuilding $npcID
		
		HealMyself $npcID
		
		if {[verifyPeopleHereForNPC $npcID]} {
			AttackZombiesHere $npcID
			if {[getNPC $npcID status] == "Hostile"} {
				HostileAttackNPC $npcID
				HostileAttackHumans $npcID
			} else {
				HealHumansHere  $npcID
				HealNPCHere $npcID
				# SocializeWithOtherNPC $npcID
			}
		}
		# BarricadeBuilding
		# SearchItemsNPC
		
		#IF Infected
		#RadioBroadcastNeedCure
		#If by fate you come here, just 50% to changelocation
		if {[rnd 1 100] > 50} {
			changeLocationNPC $npcID
		}
	}
}
proc getNPCListWithoutZombies {{excludeID ""}} {
	global npc zombies
	set list [lremove [array names npc] $zombies]
	if {$excludeID != "" } { set list [lremove $list $excludeID] }
	return $list
}

proc getNPCListWithoutZombiesForLocation {npcID {excludeID ""}} {
	global npc zombies
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	set list [getNPCListForLocation $x $y]
	set list [lremove $list $zombies]
	if {$excludeID != "" } { set list [lremove $list $excludeID] }
	return $list
}

proc getNPCListForLocation {x y} {
	global npcAtLocation
	return $npcAtLocation($x,$y)
}
proc getNPCZombiesListForLocation {x y} {
	global npcAtLocation zombies
	set list ""
	foreach zID  $npcAtLocation($x,$y)  {
		if {$zID in $zombies} { lappend list $zID }
		#if {[getNPC $zID status] == "Zombie"} { lappend list $zID }
	}
	return $list
}

proc handleInfectedNPC {npcID} {
	global zombies
	if {[getNPC $npcID status] == "Infected"} {
		incrNPC $npcID health -[set hp [rnd 1 2]]
		showMsgEventAtYourLocation $npcID [report notice "[getNPC $npcID name] decreased in health by $hp because the infection"]
		if {[getNPC $npcID health] <= 0} {
			showMsgEventAtYourLocation $npcID [report danger "[getNPC $npcID name] has died infected, a new zombie will respawn!"]
			setNPC $npcID health [getNPC $npcID maxhealth]
			setNPC $npcID status Zombie
			dict incr map alive -1
			dict incr map zombies 1
			lappend zombies $npcID
			return -code continue
		}
	}
}
proc RestIfLowOnEnergy {npcID} {
	if {[rnd 5 20] > [getNPC $npcID energy]} {
		incrNPC $npcID energy 7
		return -code continue
	}

}
proc changeLocationIfNotInBuilding {npcID} {
	global map
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	set tile [string index [lindex [dict get $map map] $y-1] $x-1]
	
	if {$tile != "#"} {
		changeLocationNPC $npcID
		return -code continue
	}
}
#33% chance to heal yourself..
proc HealMyself {npcID} {
	if {[getNPC $npcID health] < [getNPC $npcID maxhealth]} {
		if {[rnd 1 3] != 3} { return }
		incrNPC $npcID health [rnd 1 2]
		#TODO msg at location
		return -code continue
	}
}

proc AttackZombiesHere {npcID} { 
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	set zombiesList [getNPCZombiesListForLocation $x $y]
	if {$zombiesList == ""} { return }
	if {[rnd 1 2] == 2} { return }
	
	set zID [lindex $zombiesList [rnd 1 [llength $zombiesList]]-1]
	NPCAttackNPC $npcID $zID
	return -code continue
}

proc HostileAttackNPC {npcID} {
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	#50% chance to attack
	set npclist [getNPCListWithoutZombiesForLocation $npcID $npcID]

	if {$npclist == ""} { return }
	if {[rnd 1 2] == 2} { return }
	set othernpcID [lindex $npclist [rnd 1 [llength $npclist]]-1]
	NPCAttackNPC $npcID $othernpcID
	return -code continue
}
proc HostileAttackHumans {npcID} {
	global settings
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	if {$settings(x) == $x && $settings(y) == $y} { 
		if {[rnd 1 2] == 2} { return }
		#TODO handle Attack
		return -code continue
	}
}
proc HealHumansHere {npcID} {
	global settings
	set x [getNPC $npcID x]
	set y [getNPC $npcID y]
	
	if {$settings(x) != $x && $settings(y) != $y} { return 0 }
	if {$settings(health) < $settings(maxhealth)} {
		if {[rnd 1 10] < 4} { return }
		set hp [rnd 1 2]
		incr settings(health) $hp
		showMsgEventAtYourLocation $npcID [report info "[color green][color bold][getNPCName $npcID][color reset] healed you +$hp HP"]
		return -code continue
	}
}

proc HealNPCHere {npcID} {
	global settings
	set npclist [getNPCListWithoutZombiesForLocation $npcID $npcID]
	set healNPC  0
	foreach otherNPC [shuffle $npclist] {
		if {[getNPC $otherNPC health] < [getNPC $otherNPC maxhealth] } { set attackedNPC $healNPC ; break }
	}
	if {!$healNPC} { return }

	if {[rnd 1 10] < 5} { return }
	set hp [rnd 1 2]
	incrNPC $healNPC $hp
	showMsgEventAtYourLocation $npcID [report info "[color green][color bold][getNPCName $npcID][color reset] has healed [getNPCName $healNPC] for  +$hp HP"]
	return -code continue
}
#############################
# NPC Verification Functions
#############################
proc verifyNPCAlive {npcID} {
	global npc
	set status [dict get $npc($npcID) status]
	if {$status == "Dead" || [dict get $npc($npcID) health] <= 0} {
		return 0
	}
	return 1
}

proc verifyPeopleHereForNPC {npcID} {
	global npc npcAtLocation settings bashcolor
	set x [dict get $npc($npcID) x]
	set y [dict get $npc($npcID) y]
	
	if {$settings(x) == $x  && $settings(y) == $y} { return 1 }
	
	if {![info exists npcAtLocation($x,$y)]} {
		return 0
	}
	if {$npcAtLocation($x,$y) == "" || $npcAtLocation($x,$y) == $npcID} { 
		return 0
	}
	return 1
}
proc changeLocationNPC {npcID} {
	global map  npc npcAtLocation
	set location [lindex "n e w s" [rnd 0 3]]
	set x [dict get $npc($npcID) x]
	set y [dict get $npc($npcID) y]
	set oldX $x; set oldY $y
	
	set maxx [dict get $map x]
	set maxy [dict get $map y]
	switch $location {
		n { incr y -1} 
		e { incr x 1} 
		w { incr x -1} 
		s { incr y 1} 
	}
	if {$x >= 1 && $y >= 1 && $maxx >= $x && $maxy>=$y} {
		dict set npc($npcID) x $x 
		dict set npc($npcID) y $y
		set npcAtLocation($oldX,$oldY) [lremove $npcAtLocation($oldX,$oldY) $npcID]
		lappend npcAtLocation($x,$y) $npcID
		showMsgEventAtYourLocation $npcID [report info "[getNPCName $npcID] walked to $x,$y from $oldX,$oldY "]
	} else {  changeLocationNPC $npcID  }
}


proc FightBetweenNPCAndHuman {attackerID defenderID} {
	
}
#This function should be used on another NPC
proc NPCAttackNPC {attackerID defenderID} {
	global npc npcAtLocation
	if {$attackerID == "" || $defenderID == ""} { report warning "NPCATTACKNPC att $attackerID defid $defenderID" ; return }
	set attacker_dmg [calculateNPCDamage $attackerID]
	set defender_damage [calculateNPCDamage $defenderID]
	
	set attacker_def [calculateNPCDefence $attackerID]
	set defender_def [calculateNPCDefence $defenderID]
	
	set defender_final_damage [expr {$defender_def-$attacker_dmg}]
	set attacker_final_damage [expr {$attacker_def-$defender_damage}]

	if {[NPCAttackNPCDoDamage $attackerID $defenderID $defender_final_damage]} {
		NPCAttackNPCDoDamage $defenderID $attackerID  $attacker_final_damage
	}
}

proc NPCAttackNPCDoDamage {attackerID defenderID hp} {
	global npc
	dict incr $npc($defenderID) health $hp
	#if hp > 0 then "missed hit"
	# If HP = 0 it can still be a infectious bite!
	if {$hp > 0} { return 1 }
		showMsgEventAtYourLocation $defenderID [report notice "[color bold][getNPCName $defenderID][color reset] has been hit by [color bold][getNPCName $attackerID][color reset] for $hp damage."]
	if {[verifyNPCAlive $defenderID]} {
		NPCInfectNPC $attackerID $defenderID
		return 1
	} else {
		showMsgEventAtYourLocation $defenderID [report warning "[color bold][getNPCName $defenderID][color reset] has been killed by [color bold][getNPCName $attackerID]"]
		return 0
	}
}
proc NPCInfectNPC {attackerID defenderID} {
	global map
	if {[getNPC $attackerID status] == "Zombie" && [getNPC $defenderID status] != "Zombie"} {
		if {[rnd 1 3] != 3} { 
			setNPC $defenderID status Infected
			dict incr map infected 1
			showMsgEventAtYourLocation $defenderID [report warning "[color red][getNPCName $defenderID][color reset] has been infected by a Zombie"]
		}
	}
}

#Random between attack +/-attack/3
proc calculateNPCDamage {npcID} {
	global npc
	set attack [dict get $npc($npcID) attack]
	set coef [expr {$attack/3}]
	set min [expr {$attack-$coef}]
	set max [expr {$attack+$coef}]
	return [rnd $min $max]
}
#Random between defence-defence/2 and defence
proc calculateNPCDefence {npcID} {
	global npc
	set defence [dict get $npc($npcID) defence]
	set coef [expr {$defence/2}]
	set min [expr {$defence-$coef}]
	return [rnd $min $defence]
}

proc calculateUserDamage {} {
	global settings
	set attack  $settings(attack)
	set coef [expr {$attack/3}]
	set min [expr {$attack-$coef}]
	set max [expr {$attack+$coef}]
	return [rnd $min $max]
}
proc calculateUserDamage {} {
	global settings
	set defence  $settings(defence)
	set coef [expr {$defence/2}]
	set min [expr {$defence-$coef}]
	return [rnd $min $defence]
}

#Maybe sometime create a universal calculator...
proc calculateUserSetting {variable divider} {
	global settings
	set usersetting  $settings($variable)
	set coef [expr {$usersetting/$divider}]
	set min [expr {$usersetting-$coef}]
	set max [expr {$usersetting+$coef}]
	return [rnd $min $max]
}

#############################
# Population Generation
#############################

proc generateCityPopulation {} {
	global map npc npcAtLocation zombies
	set generatedPeople 0
	set generatedZombies 0
	set peopleNeeded [dict get $map alive]
	set zombiesNeeded [dict get $map zombies]
	set gender "M F"
	
	while {$generatedPeople < $peopleNeeded} {
		incr generatedPeople 
		generateNPC
	}
	while {$generatedZombies < $zombiesNeeded} {
		incr generatedPeople 
		incr generatedZombies
		lappend zombies [generateNPC Zombie]
	}
	puts "Generated $generatedPeople population ($generatedZombies zombies, [expr {$generatedPeople -$generatedZombies}] alive humans)"
}
proc generateNPC {{type ""}} {
	global npc map npcAtLocation 
	foreach {var} {gender generatedPeople generatedZombie npcgender x y} { upvar $var $var }
	set x [rnd 1 [dict get $map x]]
	set y [rnd 1 [dict get $map y]]
	set npcgender [lindex $gender [rnd 0 1]]
	set npc($generatedPeople) [dict create gender $npcgender name "[namegenerator::genRealFirstname $npcgender] [namegenerator::genRealLastname]" age [rnd 15 70] x $x y $y]
	set health [rnd 15 [rnd 30 40]]
	dict set npc($generatedPeople) health $health
	dict set npc($generatedPeople) maxhealth $health
	dict set npc($generatedPeople) attack [rnd 3 7]
	dict set npc($generatedPeople) defence [rnd 3 7]
	dict set npc($generatedPeople) energy [rnd 15 50]
	if {[rnd 0 100] > 30} {
		set status Friend
	}  else { set status Hostile }
	if {$type == "Zombie"} { set status $type }
	dict set npc($generatedPeople) status $status
	lappend npcAtLocation($x,$y) $generatedPeople
	return $generatedPeople
}

proc report {type text} {
	set data ""
	switch -- $type {
		success {  append data [color lightgreen][color bold]SUCCESS:[color reset] }
		info {  append data [color lightblue][color bold]INFO:[color reset] }
		notice {  append data [color yellow][color bold]NOTICE:[color reset] }
		warning {  append data [color magenta][color bold]WARNING:[color reset] }
		danger	{  append data [color red][color bold]/!\\DANGER/!\\:[color reset] }	 
	}
	append data " " $text [color reset]
	return $data
}
proc showMsgEventAtYourLocation {npcID message} {
	global settings
	set npcx [getNPC $npcID x]
	set npcy [getNPC $npcID y]
	if {$npcx == $settings(x) && $npcy == $settings(y)} {
		puts $message
	}
}

if {0} {
array set visitedTiles {
	5,5 1
	5,4 1
	5,6 1
	6,5 1
	7,5 1
} 
for {set y 1} {$y < 20} {incr y} {
	for {set x 1} {$x < 20} {incr x} {
		set visitedTiles($x,$y) 1
	}
}
}
  proc K { x y } { set x }
#http://wiki.tcl.tk/941
proc shuffle { list } {
      set n [llength $list]
      for { set i 0 } { $i < $n } { incr i } {
          set j [expr {int(rand()*$n)}]
          set temp1 [lindex $list $j]
          set temp2 [lindex $list $i]
          set list [lreplace [K $list [set list {}]] $j $j $temp2]
          set list [lreplace [K $list [set list {}]] $i $i $temp1]
      }
      return $list
}

proc lremove {args} {

    array set opts {-all 0 pattern -exact}
    while {[string match -* [lindex $args 0]]} {
	switch -glob -- [lindex $args 0] {
	    -a*	{ set opts(-all) 1 }
	    -g*	{ set opts(pattern) -glob }
	    -r*	{ set opts(pattern) -regexp }
	    --	{ set args [lreplace $args 0 0]; break }
	    default {return -code error "unknown option \"[lindex $args 0]\""}
	}
	set args [lreplace $args 0 0]
    }
    set l [lindex $args 0]
    foreach i [join [lreplace $args 0 0]] {
	if {[set ix [lsearch $opts(pattern) $l $i]] == -1} continue
	set l [lreplace $l $ix $ix]
	if {$opts(-all)} {
	    while {[set ix [lsearch $opts(pattern) $l $i]] != -1} {
		set l [lreplace $l $ix $ix]
	    }
	}
    }
    return $l	
	
}
#puts [time {drawMap [dict get $map map]} 100]
#puts [time {drawMapNew [dict get $map map]} 100]
proc startGame {} {
	global map
	generateCityPopulation
	drawMap [dict get $map map]
	mainMenu
}
#puts "[color purplebackground][color white] HELLO THERE SUNSHINE!\n[color reset][color cyan]Hi dude![color darkgray] -silence- [color lightcyan] What's up?"
startGame
vwait forever


