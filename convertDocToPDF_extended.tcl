#Extended version of convert to pdf..
#Convert Microsoft Doc's to PDF's on Linux using
#wvPDF and pdftk 
#Convert to pdf, add a password 
#to PDF (using latex encoding):
#	wvPDF lucrare.doc lucrare.pdf
#Watermark it..
#	pdftk lucrare.pdf background ~/wm.pdf output lucrare-wm.pdf

#Add a owner & user password..
# pdftk lucrare.pdf stamp ~/wm.pdf output lucrare-stamp.pdf encrypt_128bit owner_pw No1CanGuessThis user_pw theGoodTesting

##########################################################################-=-=-=-=-=-=-=
#source the things you need, include the packages.. use variables
########################################################-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
source zipper.tcl
foreach pkg {vfs::zip zipper fileutil sqlite3 mysqltcl} { package require $pkg }

foreach pkg {zlib} { catch {package require $pkg} }

set database mysql

set site "www_andreiclinciu_net_"

set urlfiletext "\[InternetShortcut\]\nURL=http://www.andreiclinciu.net/"
saf [
set readme {
**************************************************************************************
				README
**************************************************************************************
	INSERT A PROPER README
**************************************************************************************
				END README
**************************************************************************************
}

set readme [regsub -all  "\n"   $readme  "\r\n" ]

##########################################################################-=-=-=-=-=-=-=
#Database Related stuff
########################################################-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

proc connectToDb {} {
	global db
	set db [mysql::connect -host localhost -user root -password 123456 -db database]	
}
proc closeDB {} {
	global db
	mysql::close $db
	puts "Closed the DB" 
}
#set the database type sqlite3 or mysql
set database mysql

proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}
proc DatabaseQuery {statement} {
	global database db
	try {
		if {$database == "sqlite3"} {
			return [db eval $statement]
		} else {
			return [::mysql::sel $db $statement -flatlist]
		}
	} on error {databaseError} { puts " Database error <b>Within</b> $databaseError<br/>" ;  }
}

proc DatabaseExec {statement} {
	global database db
	try {
		if {$database == "sqlite3"} {
			return [db eval $statement]
		} else {
			return [::mysql::exec $db $statement]
		}
	} on error {databaseError} { puts " Database error <b>Within</b> $databaseError<br/>" ;  }
}
proc DatabaseFetchArray {statement} {
	global database db
	try {
		if {$database == "sqlite3"} {
			db eval $statement sqlarray {}
			return [array get sqlarray]
		} else {
			set values [mysql::sel $db $statement -flatlist]
			set cols [::mysql::col $db -current name]
			foreach val $values col $cols { set sqlarray($col) $val }
			return [array get sqlarray]
		}
	} on error {databaseError} { puts " Database error <b>Within</b> $databaseError<br/>" ;  }
}
proc getLastId {} {
	global database db
	if {[catch {
		if {$database == "sqlite3"} {
			set toReturn [db eval {$statement}] ;# todo.. search how to do this in sqlite
		} else {
			set toReturn [::mysql::insertid $db]
		}
	} databaseError]} { web::put " Database error <b>Within</b> $databaseError<br/>" ; 	}
	return $toReturn
}

##########################################################################-=-=-=-=-=-=-=
#Misc functions
########################################################-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	
#Copy all files to a local folder copyright http://objectmix.com/tcl/374837-gzip-zlib-tcl.html
proc extractFromZip {fileName destination {pattern *}} {
	#set mount [file join $::env(TEMP) mountPoint [file rootname [file tail $fileName]] 	];
	set mount $fileName

	if {[catch {
		set fd [vfs::zip::Mount $fileName $mount];
	} reason options] == 1} {
		return -options $options $reason;
	}

	if {[file exists $destination]} {
		if {![file isdirectory $destination]} {
			vfs::filesystem unmount $mount
			close $fd;

			error "no such directory \"$destination\"" 	"" \[list ENOENT $destination];
		}
	} else {
		if {[catch {
			file mkdir $destination;
		} reason options] == 1} {
			vfs::filesystem unmount $mount
			close $fd;

			return -options $options $reason;
		}
	}

	if {[catch {
		file copy -force {*}[glob -nocomplain -directory $mount -- $pattern] $destination;
	} reason options] == 1} {
		vfs::filesystem unmount $mount
		close $fd;

		return -options $options $reason;
	}

	vfs::filesystem unmount $mount
	close $fd;

	return;
}


#Search all the subfolders of the current folder and start converting to 
#PDF and watermarking everything.
#Delete the .out .tex and images after it's done
#Compress it to a .ZIP with a .txt file and a .url


proc renameFoldersAndFiles {dir} {
	if {$dir != "" && [file exists $dir]} {
		puts "Starting renaming.."
		set startTime [clock milliseconds]
		set allfiles [lreverse 	[glob  $dir -type d */*]]
		set totalFiles [llength $allfiles]
		
		puts "Allfiles $allfiles"
		foreach f $allfiles {
			if {[file isdir $f]} {
				puts "FOlder: $f"
				
				
				set newf [removeDiacritics $f]
				if {0} {
					if {[string match "* *" $f]} {
						set filez [split $f "/"]
						set newf [join [lreplace $filez end end [join [lindex $filez end] "_"]] "/"]
						catch {file rename $f $newf}
					
						puts "Renamed $f to $newf "
					}
				}
			}
		}
		
		puts "\nStarting to rename the files\n"
		#re-get all files.. with the correct path..
		set allfiles [::fileutil::find $dir]
		
		foreach f $allfiles {
			if {[file isfile $f]} {
				set newf [removeDiacritics $f]
				catch {file rename $f $newf}
			}
		}
		
		set endTime [clock milliseconds]
		puts "Finished renaming $totalFiles in [expr {($endTime-$startTime)/1000.}] seconds"
	}
}
#@TODO sqlite table of information..
#sqlite3 WikiDB  [file dirname [web::config script]]/gamesys/WikiDatabase.sqlite
proc convertAllToPdf {dir watermark storeDir} {
	global site

	if {$dir != "" && [file exists $dir]} {
		connectToDb
		catch {file mkdir $storeDir}
		puts "Dir OK!"
		set startTime [clock milliseconds]
		
		#set directories [glob -directory $dir  *]
		set directories [glob  $dir -type d */*]
			
		foreach currentCatDirWorks $directories {		
			set allfiles [::fileutil::findByPattern $currentCatDirWorks  -- {*.DOC *.doc *.DOCX *.docx}]
			set totalFiles [llength $allfiles]
			set oldDir "."
			set infoFile [open $storeDir/info.txt w]; #File where you write the text info if db fails:)
			puts $infoFile "{Work Name} {filename}"
			puts "Categoria $currentCatDirWorks  .. $totalFiles fisiere\n"
			
		
			#set exists_licentaID [DatabaseQuery "SELECT licentaID FROM ListaLicente WHERE "]  
			foreach f $allfiles {
				set currentDir [file dirname $f]
				set numeLucrare [lrange [file tail $currentDir] 1 end]
				set exists_licentaID [DatabaseQuery "SELECT licentaID FROM ListaLicente WHERE Name='$numeLucrare'"]
				
				#If it already exists, skip some things.. Just compress the doc/x & extract the PDF
				#Else do everything
				#IF it doesn't exist, add the text, remove the diacritics etc..
				#Otherwise, you HAVE the ID.. add it to the db
				set fnoDiacritics $f
				if {$exists_licentaID<0} { 
					#Remove diacritics..
					set fnoDiacritics [removeDiacritics $f]
					if {![string match $fnoDiacritics $f]} {	catch {file rename $f $fnoDiacritics} }
					
					#Convert file to .txt
					docToText $fnoDiacritics				
				}
					if {![regexp -nocase "prima pagina|antet|nu afisa" $fnoDiacritics]} {
						catch {file copy $fnoDiacritics  "${site}_[file tail $fnoDiacritics]"}
					}
					
	
				# Compress it to a .ZIP with a .txt file and a .url and add it to the DB
				if {![string match $oldDir $currentDir] && $oldDir != "."} { 
					set currentZip [zipMyContents $oldDir $storeDir]
					addFileToDb $currentZip $storeDir $infoFile $oldDir $exists_licentaID;#MAYBE add this one in a new foreach?
					#Cleanup
					puts "Am creat zip-ul $currentZip \n"
					deleteTexContentsFromDir $oldDir
				}
				set oldDir $currentDir
			
			}
			close $infoFile
			closeDB
			set endTime [clock milliseconds]
			puts "Finished converting.. $totalFiles in [expr {($endTime-$startTime)/1000.}] seconds. Also deleted some:)"
			unset allfiles
		}
	}
	puts "Am terminat toata treaba!"
}
#Add all the files to a DB renaming the original file name to something hard to guess.. When someone downloads, give them a fake name:D
#This is a kind of protection against linking..
proc addFileToDb {zipFileName storeDir infoFile oldDir {exists_licentaID 0}} {
		#!!!! IF THE THING CONTAINS EIGHER ONE OF THESE, DON'T USE IT prima pagina, antet, nu afisa
		#regexp -nocase "prima pagina|antet|nu afisa" $file
	global db database
	#Create the category if it doesn't already exist, otherwise just get the ID:D

	set catName [lindex [file split $oldDir] end-1]
	set catID [DatabaseQuery "SELECT catID from Categories WHERE catName='$catName' LIMIT 1"]
	
	#Add the category if it doesn't exist already
	if {$catID == ""} {
		DatabaseExec "INSERT INTO Categories(catName) VALUES ('$catName')" 
		set catID [DatabaseQuery "SELECT catID from Categories WHERE catName='$catName' LIMIT 1"]
	}
	#See if the license already existed or NOT.. add it if it existed 
	#Add license to db
	set uniqueName "[generateCode 23].zip"
	set workName [regsub -nocase -- {.zip} [lrange $zipFileName 1 end] ""] 
	#Licente(licentaID INTEGER PRIMARY KEY auto_increment, Name VARCHAR(250), virtualName VARCHAR(250), fileName VARCHAR(250))"
	catch {file rename ${storeDir}/$zipFileName ${storeDir}/${uniqueName}}
	puts $infoFile "{$workName} {$uniqueName}"
	
	if {$exists_licentaID < 0} {
		DatabaseExec "INSERT INTO ListaLicente(Name,docArchives) VALUES ('$workName','$uniqueName')"
		set licentaID [DatabaseQuery "SELECT licentaID FROM ListaLicente WHERE docArchives='$uniqueName'"]
		DatabaseExec "INSERT INTO ToCat(catID,licentaID) VALUES ('$catID','$licentaID')";#Last Inserted auto_incremented ID
	} else {
		DatabaseExec "UPDATE ListaLicente SET docArchives='$uniqueName' WHERE licentaID='$exists_licentaID'"
		set licentaID $exists_licentaID
	}
	flush $infoFile
	
	#Adauga bibliografia
	if {$exists_licentaID < 0} {
		set allfiles [::fileutil::findByPattern $oldDir  -- {www_*}]
		foreach f $allfiles {
			if {[string match -nocase "*bibliografie*" $f]} {
				set uniqueBibName "[generateCode 23].pdf"
				DatabaseExec "INSERT INTO BibliografieLicente(licentaID,fileName) VALUES ('$licentaID','$uniqueBibName')"
				file copy $f $storeDir/${uniqueBibName}
				break;
			}
		}
	}
	
	if {$exists_licentaID < 0} {
		#Add the text from the "cuprins" into the DB
		#Add sample exerpts from the file!
		set allfiles [::fileutil::findByPattern $oldDir  -- {*_Add_to_DB.txt}]
		set biggestSize 0
		set cuprins ""
		if {$allfiles != ""} {
			foreach f $allfiles {
				set currentSize [file size $f]
				if {$currentSize >= $biggestSize} { set  biggestSize $currentSize ; set biggestFile $f }
				if {[string match -nocase "*cuprins*" $f]} { 
					set openFile [open $f r]
					set cuprins [read $openFile]
					close $openFile
				 }
			}
			
			
				set openFile [open $biggestFile r]
				set biggestFileContent [read $openFile]
				close $openFile
			
			
			#add cuprins to DB
			if {$cuprins != ""} {
				set cuprins [::mysql::escape $cuprins]	
				DatabaseExec "INSERT INTO Texts(licentaID,type,value) VALUES ('$licentaID','cuprins','$cuprins')"; 
			}

			set fileLength [string length $biggestFileContent]
			#add 4 random excerpts to db 
			for {set i 1} {$i<=7} {incr i} {
				set rnd [rnd 1 $fileLength]
				set excerptText [::mysql::escape [string range $biggestFileContent $rnd $rnd+1000]]
				DatabaseExec "INSERT INTO Texts(licentaID,type,value) VALUES ('$licentaID','text.$i','$excerptText')";
			}
		}
	}
}

proc zipMyContents { oldDir storeDir } {
	global urlfiletext readme site
	#Find all the good working files in the
	set usableFiles [::fileutil::findByPattern $oldDir "www_*"]
	#@TODO generate a code to link to the database:)
	#Create/Open the zip file..
	set folderName [lindex [split  $oldDir /] end]
	puts "$oldDir $folderName "
	set fileName "${site}_${folderName}"
	zipper::initialize [open [file normalize $storeDir/${fileName}.zip] w]
	
	foreach uf $usableFiles {
		set f [open $uf r]
		fconfigure $f -translation binary
		zipper::addentry ${fileName}/[file tail $uf] [read $f]
		close $f
	
	}
	#add the urlfiletext & the readme
	zipper::addentry ${fileName}/VisitUs.url $urlfiletext
	zipper::addentry ${fileName}/Citeste-ma.txt $readme

	#Finalize the zip file..
	close [zipper::finalize]
	puts "Created $fileName"
	return "${fileName}.zip";#return the full name:)
} ; # end proc

proc deleteTexContentsFromDir {dir } {
	#Delete all the files that have been created for creating the PDF:) and also delete the www_* or *.pdf 's?
	set toDeleteFiles [::fileutil::findByPattern $dir  -- {*.aux *.eps *.tex *.jpg *.png *.emf *.log *.wmf *.pdf *_Add_to_DB.txt}]
	foreach f $toDeleteFiles {
		file delete $f
	}
} ; # end proc
proc docToText {filename} {
	global site
	#The antiword puts the text to the stdin.. so redirect it
	set newName [regsub -nocase -- {.doc|.docx} $filename "_Add_to_DB.txt"]
	
	if {[string match -nocase "*.docx*"  [file extension $filename]]} {
		if {[catch {exec abiword --to=txt $filename -o $newName} theErr]} { puts $theErr}
	} else {	
		if {[catch {exec antiword $filename > "$newName"} conversion_error]} {
			puts "Error converting to txt: $filename...  \n\n$conversion_error"
		} 
	}


}
#Misc functions
proc removeDiacritics {name} {
	set charMap {
		Ţ	T
		ţ	t
		Ş	S
		ş	s
		Ț	T
		ț	t
		Ș	S
		ș	s
		Î	I
		î 	i
		Â	A
		â	a
		Ă 	A
		ă	a
	}
	return [string map $charMap $name]
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
proc rnd {min max} {
	expr {int(($max - $min + 1) * rand()) + $min}
}

#url

#convertAllToPdf "/home/lostone/Programare/Tcl/Projects/Licente/lucrari" "/home/lostone/Programare/Tcl/Snippets/watermark.pdf" "/home/lostone/Programare/Tcl/Projects/Licente/zips"
if { $::argc > 0 } {
	set i 1
	foreach arg $::argv {
		puts "argument $i is $arg"
		incr i
	}

}
if {[lindex $::argv 0] != "norename"} {
	renameFoldersAndFiles /mnt/lucrari
}
  
renameFoldersAndFiles /mnt/lucrari
convertAllToPdf "/mnt/lucrari" "/home/dragos/Desktop/andrei/watermark.pdf" "/mnt/zips"
puts "Bye!"
