#       ExclusiveArticleGenerator.tcl
#       
#       Copyright 2013 Clinciu Andrei George <andrei.clinciu@howest.be>
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
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.

############################
#Definitions and package management
############################
package provide eag 1.0

foreach pkg {http Tk Tkhtml html tdom  tls sqlite3} {
	package require $pkg
}

namespace eval eag {
	variable settings
	variable articleKeywords
	set useragents {
	Mozilla/5.0 (Windows NT 5.1; rv:15.0) Gecko/20100101 Firefox/13.0.1
	Mozilla/5.0 (Windows NT 6.2; WOW64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1
	Mozilla/5.0 (X11; U; Linux x86_64; ca-ad) AppleWebKit/531.2+ (KHTML, like Gecko) Safari/531.2+ Epiphany/2.30.6
	w3m/0.52
	Mozilla/5.0 (Windows; U; Windows NT 5.1; RW; rv:1.8.0.7) Gecko/20110321 MultiZilla/4.33.2.6a SeaMonkey/8.6.55
	Opera/12.02 (Android 4.1; Linux; Opera Mobi/ADR-1111101157; U; en-US) Presto/2.9.201 Version/12.02
	Opera/9.80 (S60; SymbOS; Opera Mobi/1181; U; en-GB) Presto/2.5.28 Version/10.1
	Opera/9.80 (BlackBerry; Opera Mini/6.24209/27.1366; U; en) Presto/2.8.119 Version/11.10
	Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0
	Mozilla/5.0 (compatible; MSIE 10.0; Macintosh; Intel Mac OS X 10_7_3; Trident/6.0)
	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1150.1  Iron/20.0.1150.1 Safari/536.11
	Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en; rv:1.7.12) Gecko/20050928 Firefox/1.0.7 Madfox/3.0
	Wget/1.9+cvs-stable (Red Hat modified)
	Lynx/2.8.8dev.3 libwww-FM/2.14 SSL-MM/1.4.1
	Lynx/2.8.6rel.5 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.8g
	Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.2; Lunascape 6.3.2.22803)	
	}
	set bot [dict create user Enotsoul pass andreib0t email lostone@lba.im maxresourcelvl 0]
	set cookies [list]
	set downloadlocation "./downloaded"

  proc get_url { url } {
         set token [::http::geturl $url]
         set data [::http::data $token]
         ::http::cleanup $token
         return $data
  }

  proc get_image {uri} {
       #if the 'url' passed is an image name
       if { [lsearch [image names]  $uri] > -1 } {
            return $uri
       }

       # if the 'url' passed is a file on disk
       if { [file exists $uri] } {
            #create image using file
            image create photo  $uri -file $uri
            return $uri
       }

       #if the 'url' is an http url.
       if { [string equal -length 7 $uri http://] } {
            image create photo $uri -data [get_url $uri]
            return $uri
       }
  }

############################
#Logic and general functions
############################

#TODO make this multi-threaded.. using multiple proxy ip's for google search..
#1 search in google=> Download first 10 pages..
#Save text somehow.. use sqlite to search through it..
#Search through doc(x) and PDF's after they have been downloaded and 
#Save their location so you don't redownload it too many times..
#TODO if you have a file of 100 pages... 4000 searches.... search using OR AND with "" ?

#TODO.. give more keywords.. Search MULTIPLE ones separated by "my keywords" OR "other keywords"
#	ALSO start 20 as query string:D
#  name: search_keyword 
#  @param keyword {site google}
#  @return html page
proc search_keyword {keyword} {
	variable cookies
 #using cookie..
	set query [http::formatQuery q $keyword ie "utf-8" oe "utf-8" channel suggest]
	set url [http::geturl  http://www.google.com/search?${query}]
	#other code
	set data [http::data $url]
	#delete page request
	::http::cleanup $url
	return $data
}
#  ::eag::process_website --
#		Function that extracts the specific links from Google 
#		Returns list of link + link text
proc extract_links {siteData} {
	variable 
	set all [regexp -inline -all -- {<h3.*?><a.*?href\s*=\s*[\"']([^\"']+)[^>]*>(.*?)</a></h3>} $siteData ]

	#add to DB 
	foreach {bla link text} $all {
		lappend data $link $text
	}
	return $data
}


#  ::eag::process_website --
#   	Go to the URL, save it as html and text if possible otherwise
#		if it's a binary file save it. (pdf,exe,doc, etc.)
#	Arguments: url of the website to get
#			keyword (optional) to search for
#	Returns the name of the file downloaded
proc process_website {url {keyword ""}} {
	global downloadlocation
	set url [string map  { {&amp;} & } $url]
	
	#TODO verify if page contains HTML tag..? OTHERWISE JUST DOWNLOAD
	if {[catch {
		set siteurl [http::geturl  $url -timeout 10000 -command [list ::eag::continue_process_website $url $keyword]]
	} urlError]} { puts "Url problem:\n $urlError" ; return "" 	}
}

#This event continues the processing of a website
#Downloading the data/html and/or files if non parsable
#It then registers the keyword and url with the files downloaded
#so they can be parsed later
proc continue_process_website {url keyword siteurl} {
	variable articleKeywords
	variable downloadlocation
    switch -- [http::status $siteurl] {
        error {
            puts "ERROR for keyword $keyword at link $url: [http::error $siteurl]"
        }
        eof {
            puts "EOF reading response"
        }
        ok {
            puts "OK; code: [http::ncode $siteurl]  Size: [http::size $siteurl]"
            set ext [site_extension $url]	
			if {[string match -nocase *html* $ext]} { set parsable 1 ; set htmlfile 1 } else { set parsable 0 ; 	set htmlfile 0  }
		
			if {$parsable} {
				set siteData [http::data $siteurl]
				
				#TODO if document isn4t parsable (bad html) Just download the WHOLE page
				if {[catch {
					set doc [dom parse -html  $siteData]
					#Get the root documentElement
					set root [$doc documentElement]
					#Remove all script thingies
					set javascript [$root selectNodes {//script}]
					if {$javascript != ""} {	foreach js $javascript {  $js delete }	}
					#Remove all style thingies
					set style [$root selectNodes {//style}]
					if {$style != ""} {	foreach sty $style {  $sty delete }	}
				
				} domParseError]} { puts "Dom parse problem:\n $domParseError" ; set parsable 0 	}
			}
			set web_name [lindex [regexp -inline -- {//(.*?)/} $url] 1]
			
			set generated_code [generateCode 3]
			set filelocation [format "%s/%s-%s-%s%s" $downloadlocation $web_name $generated_code $web_name  ${keyword} ${ext} ]
			set filelocation_txt [format "%s/%s-%s-%s%s" $downloadlocation  $generated_code $web_name  ${keyword} .txt ]
			set file [open $filelocation  w];
			
			if {$parsable} {	
				#Download the file
				puts $file [$root asHTML];
				set filetxt [open $filelocation_txt  w];
				puts $filetxt [$root asText];
				close $filetxt
				$doc delete 
				
				dict set articleKeywords $keyword $url html_file $filelocation
				dict set articleKeywords $keyword $url text_file $filelocation_txt

				eagDB	eval {INSERT INTO KeywordLinks (key_id,url,html_file_downloaded,text_file_downloaded)	
					VALUES((SELECT key_id FROM Keywords WHERE keyword=$keyword),$url,$filelocation,$filelocation_txt)}	
			} else {
				#If we had an parsing error and is a html file.. download the data for further processing..
				#Some sites contain very bad html
				if {$htmlFile} {
					puts $file $siteData
					dict set articleKeywords $keyword $url html_file $filelocation
					eagDB	eval {INSERT INTO KeywordLinks (key_id,url,html_file_downloaded)
						VALUES((SELECT key_id FROM Keywords WHERE keyword=$keyword),$url,$filelocation)}	
				} else {
					#If data isn4t parsable HTML (exe,pdf..) Download it! (useful later)
					fconfigure $file -translation binary -encoding binary
					set siteurl [::http::geturl $url -channel $file]
					dict set articleKeywords $keyword $url binary_file $filelocation

				eagDB	eval {INSERT INTO KeywordLinks (key_id,url,binary_file_downloaded)	
					VALUES((SELECT key_id FROM Keywords WHERE keyword=$keyword),$url,$filelocation)}	
				}
			}
			set kw_info [eagDB	eval {SELECT link_id,(SELECT key_id FROM Keywords WHERE keyword=$keyword) as keyId \
					FROM KeywordLinks 	WHERE key_id = keyId }]
			lassign $kw_info  link_id key_id
			dict set articleKeywords $keyword $url link_id $link_id
			dict set articleKeywords $keyword $url key_id $key_id
				
			close $file 
			#What to do with file location?
			#Can't return it.. add it to a global variable for the current action?
			return $filelocation

        }
    }
    ::http::cleanup $siteurl
}


#	Return the extension, if not .html.. don4t parse it just download it
#
proc site_extension {url} {
	set ext [file extension $url]
	switch -nocase -- $ext {
		.pdf { return $ext }
		.docx { return $ext }
		.doc { return $ext }
		.odt { return $ext }
		default { return .html }
	}
} 

proc CleanDOM {} {
	foreach doc [dom documents] {
		$doc delete
	}
}

proc commands {} {
	#Required for webpages that use TLS SSL like FACEBOOK
	http::register https 443 tls::socket
	http::config -accept "image/jpeg" -useragent "Mozilla/5.0 (X11; Linux x86_64; rv:2.0) Gecko/20100101 Firefox/4.0"	
}

############################
#Program interaction
############################

#  ::eag::addKw --
#		Add keywords to the Todo list, clearing the entry
proc addKw {} {
	variable txtKeyword
	if {[string is space $::eag::txtKeyword ]} { return }
	lappend ::eag::lstTodo $::eag::txtKeyword
	set ::eag::txtKeyword ""
}

	#grid [ttk::button .nb.t1.btnClear -text "Clear" -command [list ::eag::ClearList ]] -column 0 -row 14 -sticky w
	#grid [ttk::button .nb.t1.btnRemove -text "Remove" -command [list ::eag::removeKw ]] -column 1 -row 14
	#grid [ttk::button .nb.t1.btnView -text "View" -command [list ::eag::viewFoundKw ]] -column 3 -row 14 -sticky e
	
proc ClearList {} {
	set ::eag::lstTodo ""
}

#  ::eag::removeKw --
#		Remove the selected keywords from the Todo list
proc removeKw {} {
	set all [lreverse [.nb.t1.lstTodo curselection]]
	foreach kw $all {
		.nb.t1.lstTodo  delete $kw 
	}
}

#  ::eag::viewFoundKw --
#		View the html and text results of the keyword.
proc viewFoundKw {} {
	
}

#  ::eag::startSearch --
#		Start an internet search for all the keywords in the Todo list.
#		For each keyword download the pages, save them and show them.
proc startSearch {} {
	variable articleKeywords
	variable currentProject
	#TODO modify the state of this button
	# Start -> Pause <=> Resume 
	#Disable this button untill we've got each keyword
	#TODO pause the execution later on
	.nb.t1.btnStart state disabled
	set pagesToView  [.nb.settings.spinPages get]
	#TODO Iterate over each keyword search it,
	#When done searching.. move it to the done
	#And make it available in the keywords section..
	set currentProject_id [dict get $currentProject id]
	#Get the google data & Links for each article
	#TODO implement a maximum of links to be processed
	#TODO stop/pause execution by putting all the links left in a 
	#	variable/dictionary and when resuming... continuing from there
	foreach kw $::eag::lstTodo {		
		#TODO future search if keyword matches $text found.. if NOT.. give UP
		#Foreach Link.. Surf to that site, and extract the TEXT
		#Or save the page, add it to a FULL TEXT SEARCH database and parse it later?
		#Add Keyword to DB
		eagDB eval {INSERT INTO Keywords (keyword)	VALUES($kw)}
		eagDB eval {INSERT INTO ProjectKeywords (proj_id,key_id) VALUES ($currentProject_id,(SELECT key_id from Keywords where keyword=$kw))}
		

		set currentPage 1	
		foreach {link text} [extract_links [search_keyword $kw]] {
			dict set articleKeywords $kw $link textlink $text
			#add all links to DB, process only some pages
			if {$currentPage > $pagesToView } { break }
			process_website $link $kw
			puts "Done processing for $kw at $link"
			incr currentPage 
		} 
		#Update some values afterwards..
		lappend ::eag::lstDone $kw
		#set ::eag::cboKeywords $::eag::lstDone 
		
		.nb.t2.cboKeywords configure -values $::eag::lstDone
		set ::eag::lstTodo [lrange $::eag::lstTodo  1 end]
	}
}

#When selecting a keyword that is finished, show the links downloaded
#from the dict 
proc selectedKeyword {} {
	variable articleKeywords
	set idx [.nb.t2.cboKeywords current]
    if {$idx >= 0} {
        set keyword [.nb.t2.cboKeywords get]
        set ::eag::currentSelKeyword $keyword
        puts "You've selected the keyword $keyword"
        #TODO FILL cboLink with info
        foreach link [dict keys [dict get $articleKeywords $keyword]] {
			lappend links $link
		}
       # set ::eag::cboLink $links
		.nb.t2.cboLink configure -values $links
    }
}
#Bindings for selecting the link to return html and text data
#in their appropiate window
proc selectedLink {} {
	#TODO select data..
	set idx [.nb.t2.cboLink current]
     if {$idx >= 0} {
        set link [.nb.t2.cboLink  get]
		puts "You've selected the link $link"
		set ::eag::currentSelLink $link
        #TODO LOAD FILES in HTML & Text
        #Load data, If only HTML data, show only the data
	#If only a pdf,doc.. etc.. Don't show anything just tell the info
	#Disable the save/delete/save all buttons
		if {[openFileGiveText $::eag::currentSelKeyword $::eag::currentSelLink binary]} {
			set text "The file we downloaded from this link is binary, please open it manually\
				Or open the original link to view it: $::eag::currentSelLink"
			writeToTextBox .nb.t2.nbTexts.text.txtText $text
			writeToTextBox .nb.t2.nbTexts.html.txtHtml $text
		} else {
			set html_data [openFileGiveText $::eag::currentSelKeyword $::eag::currentSelLink html]
			set text_data [openFileGiveText $::eag::currentSelKeyword $::eag::currentSelLink text]
			#todo if it's 0 then tell us that no file has been downloaded or preprocessed..
			writeToTextBox .nb.t2.nbTexts.text.txtText $text_data
			writeToTextBox .nb.t2.nbTexts.html.txtHtml $html_data
		
		}
    }
}

proc writeToTextBox {textbox data} {
	$textbox  delete 0.0 end
	$textbox  insert 0.0 $data 
}

#See if the file exists and return the appropiate text
#Return 0 if it's not existing (thus not downloaded)
#Return 1 only if the binary type file exists
proc openFileGiveText {keyword link type} { 
	variable articleKeywords
	
	if {![dict exists  $articleKeywords $keyword $link $type\_file]} {
		return 0
	}
	set fileToOpen [dict get $articleKeywords $keyword $link $type\_file ]
	set fullFileName $fileToOpen
	puts "verify if file $fullFileName exists"
	if {![file exists $fullFileName]} {
		return 0 
	} else {
		if {$type == "binary"} { return 1 };#Is there any binary file?
		set file [open $fullFileName]
		set data [read $file]
		close $file
		return $data
	}
}

#This procedure saves the current TEXTBOX edit of the html and text files..
#Inserts if doesn't exist, updates if already exists
proc SaveDataFiles {} {
	variable currentSelKeyword
	variable currentSelLink
	variable articleKeywords

	set link_id [dict get $articleKeywords $currentSelKeyword $currentSelLink link_id]
	foreach typeName {Text Html} type {1 2}  {
		#set data [openFileGiveText $currentSelKeyword $currentSelLink type]
		#1 = text, 2=html, 3= binary (save file..))
		set data [.nb.t2.nbTexts.html.txt$typeName get 0.0 end]
		eagDB eval {INSERT INTO DataInfo (link_id,type,data) VALUES ($link_id,$type,$data)}

	}
}
#This Procedure deletes both .txt and .html files..
#Could also be used to remove from database
proc DeleteDataFile {} {
	
}

#Save all current data files for this current keyword
#Or save all current keywords..?
proc SaveAllDataFiles {} {
	variable currentSelKeyword
	variable articleKeywords

	#
	foreach typeName {Text Html} type {1 2}  {
		#set data [openFileGiveText $currentSelKeyword $currentSelLink type]
		#1 = text, 2=html, 3= binary (save file..))
		set data [.nb.t2.nbTexts.html.txt$typeName get 0.0 end]
		eagDB eval {INSERT INTO DataInfo (link_id,type,data) VALUES ($link_id,$type,$data)}

	}
}
#  ::eag::pauseSearch --
#		Pause the search sequence..

#  ::eag::resumeSearch --
#		Resume the search sequence..


############################
#GUI design
############################

proc DrawGUI {} {
	#disable Motif tearoff interface!
	option add *Menu.tearOff 0
	#grid [canvas .c -background white] -sticky news
	#Menu thingy
	menu .menubar
    . configure -menu .menubar
    .menubar add cascade -label File -menu .menubar.file -underline 0
    menu .menubar.file
    .menubar.file add command -label "Import keywords" -underline 0 -command niy 
    .menubar.file add command -label "Save All the charts" -underline 0 -command niy
    .menubar.file add command -label "Save Current tab" -underline 0 -command niy
    .menubar.file add separator
    .menubar.file add command -label Exit -underline 1 -command exit
    
    .menubar add cascade -label Options -menu .menubar.options -underline 0
	menu .menubar.options
    .menubar.options add command -label "Do nothing yet " -underline 0 -command niy
    
	menu .menubar.help
    .menubar add cascade -label Help -menu .menubar.help -underline 0
	.menubar.help add command -label "About" -underline 0 -command [list tk_messageBox -title "About" -icon info -message "VERSION 1.0\n Article Generator software.\n\nMade by Andrei clinciu"]
	
	set nb_padding 10
	grid [ttk::notebook .nb  -width 800 -height 600 -padding $nb_padding] 
	.nb add [canvas .nb.t1 -width 800 -height 600 ] -text "Search" -padding $nb_padding
	.nb add [canvas .nb.t2 -width 800 -height 600] -text "Keywords Info" -padding $nb_padding
	.nb add [canvas .nb.settings -width 800 -height 600] -text "Settings" -padding $nb_padding

	#.nb select .nb.t1
	ttk::notebook::enableTraversal .nb
	#Search tab
	grid [ttk::entry .nb.t1.txtKeyword -textvariable ::eag::txtKeyword] -column 0 -row 1 -sticky news
	grid [ttk::button .nb.t1.btnAdd -text "Add" -command [list ::eag::addKw ]] -column 1 -row 1 -sticky news
	grid [ttk::button .nb.t1.btnStart -text "Start search" -command [list ::eag::startSearch ]] -column 0 -row 16 -sticky news -ipady 5 -ipadx 5 -padx 5 -pady 10 -columnspan 3
	grid [ttk::button .nb.t1.btnStop -text "Stop search" -command [list ::eag::stopSearch ]] -column 3 -row 16 -sticky news -ipady 5 -ipadx 5 -padx 5 -pady 10 -columnspan 2
	
	grid [ttk::label .nb.t1.lblTodo -text "Todo"] -column 0 -row 3 -sticky news
	grid [ttk::label .nb.t1.lblDone -text "Done"] -column 3 -row 3 -sticky news
	
	grid [listbox .nb.t1.lstTodo  -height 10 -listvariable ::eag::lstTodo -selectmode extended] -column 0 -row 4 -sticky news -columnspan 2 -rowspan 10 -pady 3 
	grid [listbox .nb.t1.lstDone  -height 10 -listvariable ::eag::lstDone -selectmode extended] -column 3 -row 4 -sticky news -columnspan 2 -rowspan 10 -pady 3 -padx 3
	
	grid [ttk::button .nb.t1.btnClear -text "Clear" -command [list ::eag::ClearList ]] -column 0 -row 14 -sticky w
	grid [ttk::button .nb.t1.btnRemove -text "Remove" -command [list ::eag::removeKw ]] -column 1 -row 14
	grid [ttk::button .nb.t1.btnView -text "View" -command [list ::eag::viewFoundKw ]] -column 3 -row 14 -sticky e
		
	#Keywords Info ab

	grid [ttk::label .nb.t2.lblKeywords -text "Keywords"] -column 1 -row 0 -sticky news
	grid [ttk::label .nb.t2.lblLink -text "Link"] -column 1 -row 1 -sticky news

	
	grid [ttk::combobox .nb.t2.cboKeywords -textvariable ::eag::cboKeywords -state readonly] -column 2 -row 0 -sticky news -columnspan 3
	grid [ttk::combobox .nb.t2.cboLink -textvariable ::eag::cboLink -state readonly] -column 2 -row 1 -sticky news -columnspan 3
	
	grid [ttk::label .nb.t2.lblStatus -text "Current File Status"] -column 0 -row 3 -sticky news -columnspan 3
	set nbTexts_height 470
	set nbTexts_width 750
	grid [ttk::notebook .nb.t2.nbTexts  -width $nbTexts_width -height $nbTexts_height -padding 10] -column 1 -row 5 -columnspan 4
	.nb.t2.nbTexts  add [canvas .nb.t2.nbTexts.text -width $nbTexts_width -height $nbTexts_height ] -text "Text" -padding 10
	.nb.t2.nbTexts  add [canvas .nb.t2.nbTexts.html -width $nbTexts_width -height $nbTexts_height ] -text "HTML" -padding 10

	#.nb select .nb.t1
	ttk::notebook::enableTraversal .nb.t2.nbTexts 
	
	grid [text .nb.t2.nbTexts.text.txtText -width 110 -height 30] -column 1 -row 1 -sticky news -columnspan 4
	grid [text .nb.t2.nbTexts.html.txtHtml -width 110 -height 30] -column 1 -row 1 -sticky news -columnspan 4
	
	
	grid [ttk::button .nb.t2.btnSave -text "Save" -command [list ::eag::SaveDataFiles ]] -column 1 -row 6 -sticky w
	grid [ttk::button .nb.t2.btnDelete -text "Delete" -command [list ::eag::DeleteDataFile ]] -column 2 -row 6
	grid [ttk::button .nb.t2.btnSaveAll -text "Save All" -command [list ::eag::SaveAllDataFiles ]] -column 3 -row 6 -sticky e
	
	#Settings tab
	grid [ttk::label .nb.settings.lblThreads -text "Threads"] -column 1 -row 1 -sticky news
	grid [ttk::label .nb.settings.lblPages -text "Search Pages"] -column 1 -row 2 -sticky news
	
	grid [ttk::spinbox .nb.settings.spinThreads -from 1 -to 64 ] -column 2 -row 1 -sticky news
	grid [ttk::spinbox .nb.settings.spinPages -from 1 -to 10  ] -column 2 -row 2 -sticky news
	grid [ttk::checkbutton .nb.settings.chkAlternateUseragents  -variable ::eag::chkAlternateUseragents -text "Alternate Useragents" ] -column 1 -row 3 -sticky news
	grid [ttk::checkbutton .nb.settings.chkUseProxy  -variable ::eag::chkUseProxy  -text "Use Proxy"] -column 1 -row 4 -sticky news
	grid [ttk::checkbutton .nb.settings.chkDownloadImages  -variable ::eag::chkDownloadImages  -text "Download and link images"] -column 1 -row 5 -sticky news

	grid [ttk::button .nb.settings.btnUseragentSettings -text "Settings" -command [list niy ]] -row 4 -column 2  -sticky news
	grid [ttk::button .nb.settings.btnUseProxySettings -text "Settings" -command [list niy ]] -row 5 -column 2 -sticky news
	
	.nb.settings.spinPages set 5
	.nb.settings.spinThreads set 1
	set ::eag::rbTextType text
	#grid [text .txtOriginalText  -width 70 -height 4] -column 1 -row 0 -sticky news
	#grid [text .txtKeywords -width 70 -height 4] -column 1 -row 10 -sticky news
	#grid [text .txtEndText  -width 70 -height 4] -column 1 -row 20 -sticky news

   #label .nb.settings -text "This version of Tk is too old..."
	
	#Events
	#bind .nb <Configure> {doResize}
	bind .nb.t2.cboKeywords <<ComboboxSelected>> ::eag::selectedKeyword
	bind .nb.t2.cboLink <<ComboboxSelected>> ::eag::selectedLink
	#bind . <F12> saveAll
	#bind . <F2> getAllInfo
	#bind . <Control-s>  save_current_canvas
	
	#fillComboboxWithLogs
}
proc niy {} {
	puts "Sorry, not implemented yet!"
}
############################
#Misc Commands
############################
proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}

proc generateCode {length {type 1}} {
	if {$type == 1} {
		set string "azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789"
	} elseif {$type == 2} { set string AZERTYUIOPQSDFGHJKLMWXCVBN0123456789 
	} elseif {$type == 3} { set string azertyuiopqsdfghjklmwxcvbn0123456789 
	} elseif {$type == 4} { set string AZERTYUIOPQSDFGHJKLMWXCVBN } else {  set string 0123456789 }
	set code ""
	set stringlength [expr {[string length $string]-1}]
	for {set i 0} {$i<$length} {incr i} {
		append code [string index $string [rnd 0 $stringlength]]
	}
	return $code
}
proc makeDirs {} {
	file mkdir downloaded
}
proc makeDb {} {
	eagDB eval {BEGIN IMMEDIATE TRANSACTION}

	eagDB eval {
	CREATE TABLE IF NOT EXISTS Projects (  
    proj_id INT AUTO_INCREMENT PRIMARY KEY,  
	proj_name TEXT COLLATE NOCASE
);  
	CREATE TABLE IF NOT EXISTS Keywords (  
    key_id INT AUTO_INCREMENT PRIMARY KEY,  
    keyword TEXT COLLATE NOCASE,
    timestamp INT   
);  
	CREATE TABLE IF NOT EXISTS ProjectKeywords (  
    proj_id INT,  
    key_id INT,  
    FOREIGN KEY (proj_id) REFERENCES Projects(proj_id),
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id)
);  

	CREATE TABLE IF NOT EXISTS KeywordLinks (  
    link_id INT AUTO_INCREMENT PRIMARY KEY,  
    key_id INT,  
    url TEXT,
    working INT,
    html_file_downloaded TEXT,  
    text_file_downloaded TEXT,
    binary_file_downloaded TEXT,
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id)  
);  
	CREATE TABLE IF NOT EXISTS KeywordImages (  
    img_id INT AUTO_INCREMENT PRIMARY KEY,
    key_id INT,  
    img_name TEXT,  
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id)   
);  
	CREATE TABLE IF NOT EXISTS DataInfo (  
    data_id INT AUTO_INCREMENT PRIMARY KEY,  
    link_id INT,  
    type INT,  
    fileName TEXT,  
    data BLOB,
	FOREIGN KEY (link_id) REFERENCES KeywordLinks(link_id) 
);  
}
if {0} {
	CREATE TABLE IF NOT EXISTS Keywords (  
    key_id INT AUTO_INCREMENT PRIMARY KEY,  
    keyword TEXT COLLATE NOCASE, 
);  
	CREATE TABLE IF NOT EXISTS Pages (  
    page_id INT AUTO_INCREMENT PRIMARY KEY,   
    title TEXT,  
    data BLOB,  
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id)   
);  
	CREATE TABLE IF NOT EXISTS PageKeyword (  
    page_id INT,  
    key_id INT,   
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id),   
    FOREIGN KEY (page_id) REFERENCES Pages(page_id),   
);  
	CREATE TABLE IF NOT EXISTS KeywordImages (  
    img_id INT AUTO_INCREMENT PRIMARY KEY,  
    key_id INT,  
    img_name TEXT,  
    FOREIGN KEY (key_id) REFERENCES Keywords(key_id)   
);  
}

	#eagDB eval {CREATE INDEX idx_keywords ON Keywords(keyword); CREATE INDEX idx_keywords_id ON KeywordLinks(key_id) }
#	eagDB eval {CREATE INDEX idx_ioID ON DataInfo(key_id); CREATE INDEX idx_device ON ioActivityData(device)}
	
	
	eagDB eval {COMMIT TRANSACTION}
	puts "Created DB! You'll need to provide the name for a new project!"
	getNewProjectName
	
}
proc getNewProjectName {} {
	variable currentProject
	if {[tk_getString .gs projName "Enter a new project name"]} {
		eagDB eval {INSERT INTO Projects (proj_name) VALUES ($projName)}
		set proj_id [eagDB {SELECT proj_id FROM Projects WHERE proj_name=$proj_name}]
		
	dict set currentProject [id $proj_id name $projName]
	}
}
############################
#Run the main program
############################
proc main {} {
	#Misc commands
	commands 
	#Init Gui
	DrawGUI
	#Run Startup Things
	makeDirs
	#Load data from folders and/or database! Forget to save it automatically to a file each time (or append?)
	#FUNCTION to start sqlite database.. and load all existing keywords/projects
	if {![file exists "raw_eag_projects.sqlite"]} { sqlite3 eagDB ./raw_eag_projects.sqlite ; makeDb } else { sqlite3 eagDB ./raw_eag_projects.sqlite }
}
main



}

if {0} {
package provide app-uniquify 1.0

package require Tk
set VERSION "1.0.0"
#catch {console show}
set PROGRAMMSG "
 VERSION $::VERSION \nUniqueify your text preserving the keywords.."	
set characters [dict create uppercase "
	I {\u0406 \u0399}
	J \u0408 
	A {\u0410 \u0391}
	B {\u0412 \u0392}
	E {\u0415 \u0395}
	M {\u041C \u039C}
	N \u039D
	H {\u041D \u0397}
	O {\u041E \u039F}
	P {\u0420 \u03A1}
	C {\u0421 \u03F9}
	T {\u0422 \u03A4}
	X {\u0425 \u03A7}
	Y {\u04AE \u03A5}
	S \u0405
	G \u0262
	Z \u0396
	K \u039A
	" lowercase "
	a \u0251
	y {\u0443 \u03B3}
	e \u0435 
	o {\u043E \u03BF}
	p \u0440
	c {\u0441 \u03F2}
	x \u0445 
	s \u0455 
	i \u0456
	j {\u0458 \u03F3}
	h \u04BB 
	g \u0261
"]
	set max_lowerRand  9
	set max_upperRand 7
		
	proc randomSelect {} {
		global characters max_lowerRand max_upperRand
		#Chose 6 lowercase char -> chose equivalent uppercase
		#and chose 3 random unique uppercase
		# if >2 random chose one
		#lowercase & uppercase 	ijaehocxygs
		#uppercase only BMNTZK
		set use_chars ""
		set lowercase [dict get $characters lowercase]
		set uppercase [dict get $characters uppercase]
		set keys [dict keys $lowercase]
		set uppercase_keys [split BMNTZK ""]
		set lower_l [llength $keys]
		
		for {set i 1} {$i<=$max_lowerRand} {incr i} {
			set nr_char [rnd 1 $lower_l]
			set the_char [lindex $keys ${nr_char}-1]
			set charDict [dict get $lowercase $the_char]
		
			if {[set charDict_l [llength $charDict]]>1} {
				set char [lindex $charDict [rnd 1 $charDict_l]-1]
			} else { set char $charDict }
			#Get uppercase version
			set up_charDict [dict get $characters uppercase [string toupper $the_char]]
			if {[set up_charDict_l [llength $up_charDict]]>1} {
				set up_char [lindex $up_charDict [rnd 1 $up_charDict_l]-1]
			} else { set up_char $up_charDict }
			
			append use_chars $char $up_char
			append orig_chars $the_char [string toupper $the_char]
			#Cleanup
			incr lower_l -1
			#set lowercase [dict remove $lowercase $the_char]
			lremove $keys $the_char
		}
	
		#Get another 3 random characters 
		for {set j 1} {$j<=$max_upperRand} {incr j} {
			set nr_char [rnd 1 [llength $uppercase_keys]]
			set the_char [lindex $uppercase_keys ${nr_char}-1]
			set charDict [dict get $uppercase $the_char]
		
			if {[set charDict_l [llength $charDict]]>1} {
				set char [lindex $charDict [rnd 1 $charDict_l]-1]
			} else { set char $charDict }
			
			append use_chars $char
			append orig_chars $the_char
			#Cleanup
			lremove $uppercase_keys $the_char
		}
		return  "good $use_chars orig $orig_chars"
	}
proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}
proc replaceCharacters {} {
	set text [.txtOriginalText get 0.0  end]
	set keywords [.txtKeywords get 0.0  end]
	set randomChars [randomSelect]
	set count 1
	foreach kw $keywords {
		lappend kwReplace $kw @$count@ 
		lappend reverseKwReplace @$count@ $kw
		incr count
	}
	set newText [string map -nocase $kwReplace $text]
	
	foreach char [split [dict get $randomChars orig] ""] newChar [split [dict get $randomChars good] ""] {
		lappend charMap $char $newChar
	}
	set data [string map $reverseKwReplace [string map $charMap $newText]]
	processing
	.txtEndText delete 0.0 end
	.txtEndText insert 0.0 $data 
}
#Artificial Processing
proc processing {} {
	for {set i 0} {$i<=100} {incr i 5} {
		.lblProcessing configure -text "Processing... $i\% done"
		
	}
		
}
proc DrawGUI {} {
#disable Motif tearoff interface!
    option add *Menu.tearOff 0
#grid [canvas .c -background white] -sticky news
#Menu thingy
	menu .menubar
	. configure -menu .menubar
	.menubar add cascade -label Program -menu .menubar.file -underline 0
	menu .menubar.file
	.menubar.file add command -label "Do It" -underline 0 -command [list puts "Not working yet" ]
	.menubar.file add separator
	.menubar.file add command -label Exit -underline 1 -command exit

	menu .menubar.help
	.menubar add cascade -label Help -menu .menubar.help -underline 0
	.menubar.help add command -label "About" -underline 0 -command [list tk_messageBox -title "About" -icon info -message $::PROGRAMMSG]

	grid [ttk::label .lblOriginalText -text "Original Text"] -column 0 -row 0 -sticky news
	grid [ttk::label .lblKeywords -text "Keywords"] -column 0 -row 10 -sticky news
	grid [ttk::label .lblEndText -text "Output"] -column 0 -row 20 -sticky news
	grid [ttk::label .lblProcessing -text "Ready to convert!"] -column 0 -row 30 -sticky news -columnspan 2
	
	grid [text .txtOriginalText  -width 70 -height 4] -column 1 -row 0 -sticky news
	grid [text .txtKeywords -width 70 -height 4] -column 1 -row 10 -sticky news
	grid [text .txtEndText  -width 70 -height 4] -column 1 -row 20 -sticky news
		
	grid [ttk::button .btnConvert -text "Convert" -command [list replaceCharacters ]] -row 100 -column 0 
	grid [ttk::button .btnClear -text "Clear" -command [list clearAll ]] -row 100 -column 1 



	puts "GUI is drawn!"
}
proc clearAll {} {
	.txtOriginalText delete 0.0 end	
	.txtKeywords delete 0.0 end	
	.txtEndText delete 0.0 end	
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
DrawGUI

	
}
