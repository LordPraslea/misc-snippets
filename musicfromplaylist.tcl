#       musicfromplaylist.tcl
#		Get MP3/OGG from online playlist PLS/M3U
#		WARNING! This only work with non-streaming links!
#       
#       Copyright 2011 Clinciu Andrei-George <andrei.clinciu@howest.be>
#       
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.

package require Thread
package require http
package require tdom
package require sqlite3
###############################
# The main function
###############################
proc savePlsList {plsList exitfolder} {

	#Create our threads :D
	set tid1 [thread::create]
	set tid2 [thread::create]

	#Misc thread settings
	::tsv::set settings folder $exitfolder
	
	#Open the file
	set file [open $plsList r+]
	set plsData [read $file]
	
	foreach {plsItem1 plsItem2} [string trim $plsData] {
		puts "Current album pls links .. $plsItem1 & $plsItem2"
		getPls $tid1 $plsItem1 
		if {$plsItem2 != ""} { getPls $tid2 $plsItem2 }
		
	}
	puts "Finished downloading the files:)"
}
proc getPls {tid plsItem} {
	#thread::send $tid {after 2000 ; puts "Printed after two seconds"}
	#	thread::send –async $tid {after 2000 ; puts "Printed in the	background"}
	::tsv::set settings currentlink $plsItem
	upvar exitfolder exitfolder


	#Get the pls link
	set plsLink [http::geturl $plsItem]
	#set plsLink [http::geturl [::tsv::get settings currentlink]]

	set currentPls [string trim [http::data $plsLink]]
	::http::cleanup $plsLink
		
	#Set the music list.. removing the first  line thingie
	set musiclist [lrange [split "$currentPls" "\n"] 1 end]

	#set exitfolder [::tsv::get settings folder]
	
	#Create the folder if doesn't exist
	catch {file mkdir $exitfolder}

	foreach {name link} $musiclist {
		if {[catch {
			set fileName [file tail $link]
	
			if {![file exists $fileName]} {
				set thisLink [http::geturl $link]
				set currentFile [open $exitfolder/$fileName w]
				fconfigure $currentFile -translation binary -encoding binary
				puts $currentFile [http::data $thisLink]
				close $currentFile
				
				::http::cleanup $thisLink
				puts "Finished downloading $fileName ..."
			} else { puts "$fileName already exists locally.. " }
		} erInfo]} { puts "Error while downloading $link .. following error occured: $erInfo " }
	}
}
###############################
# Site crawler extraction part:)
###############################


if {0} {
#database creation if it doesn't exist, if it does exist open it
sqlite3 lba ./Docs.sqlite
lba eval {CREATE TABLE IF NOT EXISTS Content(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, category TEXT, content TEXT}
}

# Set the useragent so we aren't considered a bot
http::config -useragent {Mozilla/5.0 (X11; U; Linux x86_64; en-GB; rv:1.9.2.6) Gecko/20100628 Ubuntu/10.04 (lucid) Firefox/3.6.6}
http::config -proxyhost 173.201.183.172
http::config -proxyport 8080

proc
#Proxy settings..
global Proxy
# 193.251.176.55 8000 208.115.216.66 80 	24.155.96.93 80
set Proxy(list) {211.138.124.196 80 221.130.17.26 80 221.130.7.76 80
195.238.241.10 3128 	221.130.17.252 80 	174.143.150.83 80	
	122.209.123.151 80 	221.130.162.249 80 	137.89.133.12 80
221.130.17.243 80 	83.244.88.145 8080 	218.201.21.178 80
220.250.22.173 808 	200.195.132.75 8080 195.200.118.184 8080
219.139.241.134 80  	221.130.17.240 80 211.142.22.22 80 	221.130.7.83 80
174.142.24.204 3128		76.99.139.80 8008 	114.30.47.10 80
213.0.88.86 8080 	61.6.163.33 80 	212.160.130.217 80
83.244.116.206 8080 	200.192.89.231 80	 221.130.17.254 80
211.138.124.211 80 	72.51.41.235 3128 	124.238.242.87 80
119.167.219.78 80 	195.200.82.161 80 	80.193.72.145 80
173.203.101.86 3128 	208.115.216.66 80 	67.99.190.246 3128
83.244.88.145 8080 	221.130.13.232 80 	221.130.7.73 80
211.138.124.200 80 	124.160.27.162 808 	208.92.249.118 80
218.29.234.50 3128	 83.244.115.109 8080 	66.42.182.178 3128
128.232.103.203 3127 221.130.162.247	 80 221.130.17.73	 80 221.130.13.47 80}
set Proxy(count) 0
set Proxy(max) [expr [llength $Proxy(list)]-1]

#Change proxy every time you go to a new page
proc nextProxy {} {
	global Proxy
catch {	http::config -proxyhost [lindex $Proxy(list) $Proxy(count)]
		http::config -proxyport [lindex $Proxy(list) $Proxy(count)+1] }
	incr Proxy(count) 2
	if {$Proxy(count) > $Proxy(max)} { set Proxy(count) 0}
}

#Set the site
set theSite "http://facultate.regielive.ro"
#Used to get the data
set token [::http::geturl $theSite]
set siteData [http::data $token]

#Parse the data as html not as xml(errors otherwise)
set doc [dom parse -html $siteData]

#Get the root documentElement
set root [$doc documentElement]

#Select the ALL the categories links(find the perfect DOM for this)
set categories [$root selectNodes {//td[@class="abstract"]/a}]

foreach category $categories {
	#$category getAttribute href
	#$category getAttribute title OR $category text
	set categoryName [$category text]
	set categoryLink $theSite[$category getAttribute href]
	puts "The category $categoryName at link $categoryLink"

	#############
	#Dissect each category
	#############
	
	#Get ALL the pages from each category
	set nextSiteData [http::data [::http::geturl $categoryLink]]

	#Get the DOM and root documentElement
	set nextDoc [dom parse -html $nextSiteData]
	set nextRoot [$nextDoc documentElement]

	#Get the link with the href to the last page
	set lastCategoryLink [lindex [$nextRoot selectNodes {//td/a[@class="link_navbar"]}] end]

	#This regular Expression helps us get the total pages for each category to find..
	regexp {.+/.+\-(\d+).html} [$lastCategoryLink getAttribute href] -> pages

	puts "This category currently has $pages pages."
	
	set page [string range $categoryLink 0 [string last . $categoryLink]-1]

	#############
	#Open each category page to list all the links there and then open each of them
	#starting from the first page, this site supports that
	#############
	for {set i 1} {$i<=$pages} {incr i} {
		set nextSiteData [http::data [::http::geturl ${page}-${i}.html]]
		set nextDoc [dom parse -html $nextSiteData]
		set nextRoot [$nextDoc documentElement]

		#Get all the links
		set datalinks [$nextRoot selectNodes {//tr[@class="tr_list_f"]/td/a}]
		foreach datalink $datalinks { lappend contentLinks [[$datalink firstChild] text] [$datalink getAttribute href] }
		#wait a little bit till you get the next one
		puts "Finished page nr $i for $categoryName .. Waiting a little bit till we go to the next. Changing proxy"
		nextProxy
		after 50
	}
}
puts "Finished getting the links.'"
puts $contentLinks
#############
#Open all the content links and copy the data to the database
#############

if {0} {
	#Get the content from each page accordingly
	foreach {contentTitle contentLink} $contentLinks {
		set content /referate/agronomie/organizarea_comuna_de_piata_a_laptelui_si_produselor_lactate-62689.html
		set contentData [http::data [::http::geturl ${theSite}/${content}.html]]
		
		set contentData [http::data [::http::geturl http://localhost:8080/microbiologia_specifica_produselor_alimentare-172686.html ]]
		set contentDoc [dom parse -html $contentData]
		set contentRoot [$contentDoc documentElement]

		#Get all the info of the document.. later select only the one we need
		set pageData [$contentRoot selectNode {//tr[@class='tr_list_f']/td}]
		#Extract the data or place it in a database..:)
		lbd eval {INSERT INTO Content VALUES('$contentTitle','','$pageData'}
		foreach data $pageData {
			set theData [$data text]
		
		 }
	}
}


proc httpcopy { url {proxyhost ""} {proxyport ""}} {
	http::config -useragent {Mozilla/5.0 (X11; U; Linux x86_64; en-GB; rv:1.9.2.6) Gecko/20100628 Ubuntu/10.04 (lucid) Firefox/3.6.6}
	if {$proxyhost != "" && $proxyport != ""} {
		http::config -proxyhost $proxyhost
		http::config -proxyport $proxyport
	}
	
	set token [::http::geturl $url]
	set data   [http::data $token]
   # This ends the line started by httpCopyProgress
   puts stderr ""

   upvar #0 $token state
   set max 0
   foreach {name value} $state(meta) {
      if {[string length $name] > $max} {
         set max [string length $name]
      }
      if {[regexp -nocase ^location$ $name]} {
         # Handle URL redirects
         puts stderr "Location:$value"
         return [httpcopy [string trim $value]  $proxyhost $proxyport]
      }
   }
   incr max
   foreach {name value} $state(meta) {
      puts [format "%-*s %s" $max $name: $value]
   }
   return "token: $token .. data: $data"
}

###############################
# Misc Commands
###############################

proc generateCode {length {type 1}} {
	if {$type == 1} {
		set string "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789"
	} elseif {$type == 2} { set string AZERTYUIOPQSDFGHJKLMWXCVBN0123456789 
	} elseif {$type == 3} { set string azertyuiopqsdfghjklmwxcvbn0123456789 } else {  set string 0123456789 }
	set code ""
	set stringlength [expr {[string length $string]-1}]
	for {set i 0} {$i<$length} {incr i} {
		append code [string index $string [rnd 0 $stringlength]]
	}
	return $code
}
proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}
###############################
# Run
###############################

savePlsList /home/lostone/Programare/Tcl/Snippets/plslist.txt /home/lostone/Music/creativecommons/
