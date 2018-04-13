#		Convert your documents to .txt files that are imported in SQlite databases
#		uses FTS4 for full text search, get the data fast!
#			made by Clinciu Andrei George
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 3 of the License, or
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
#       
#Convert .doc & .pdf files to .txt files..;
# This needs you to have antiword & pdftotext (xpdf) on your system.
#
#example: pdftotext "/home/lostone/Carti/Physics Complete/Modern Physics/Particle Physics/Building Blocks of Matter A Supplement to the Macmillan Encyclopedia of Physics - John S. Rigden.pdf" /home/lostone/particlePhysics.txt

package require sqlite3
package require fileutil
proc ConvertToTxt {inputdir outputdir } {
	global alreadyconverted
	set alreadyconverted ""
	#Create dir if it doesn't exist
	if {![file exists $outputdir]} {  file mkdir $outputdir }
	
	#Convert all .pdf and .doc to .txt
	set allfiles [::fileutil::findByPattern $inputdir "*.doc *.pdf"]
	
	puts "Starting the Conversion of [llength $allfiles]"
	set toreport [expr {[llength $allfiles]/10}]
	
	foreach infile $allfiles {
		incr filecount

		if {[lsearch $alreadyconverted $infile] == -1} { 
			if {[string match -nocase *pdf* [file extension $infile]]} {
				if {[catch {exec pdftotext -q $infile [file join $outputdir [file tail $infile].txt]}]} {
					puts "Error converting $infile... "
				}  else { puts "Converted $infile with success!" }
			} else {
				#The antiword puts the text to the stdin.. so redirect it
					if {[catch {exec antiword $infile > [file join $outputdir [file tail $infile].txt]}]} {
						puts "Error converting $infile... "
					} else { puts "Converted $infile with success!" }
			}
			
			lappend alreadyconverted $infile
		}
		
		if {[expr {$filecount%$toreport}]==0} { puts "Finished converting [expr {double(${filecount})/$toreport*10}]% of files.." }
	}
}

#


proc AddBooksToDb {databaseLocation inputdir {splitPages 1}} {
	sqlite3 booksDB $databaseLocation 
	
	booksDB eval {
		CREATE TABLE Books(bookID INTEGER PRIMARY KEY autoincrement, BookName TEXT COLLATE NOCASE, categoryID INT DEFAULT 0, authorID INT DEFAULT 0, pages INT DEFAULT 0);
		CREATE VIRTUAL TABLE BooksFTS USING fts4(bookname,pages,data);
		CREATE VIRTUAL TABLE BooksData USING fts4(bookid,bookpage, data);
		}
		#Testing purposes only.. remove afterwards
	
	set allfiles [::fileutil::findByPattern $inputdir "*.txt"]
	foreach thefile $allfiles {
		set openFile [open $thefile]
		set theData [split [read $openFile]]
		set theData [regexp -all -inline {.[^]+} $theData]
				
		set bookname [file tail $thefile]
		
		set words [llength  $theData]
		set pages [expr {int(ceil($words/double(830)))}]
		
		#start transaction
		booksDB eval {BEGIN IMMEDIATE TRANSACTION}

		booksDB	eval {INSERT INTO Books (BookName,pages) VALUES($bookname,$pages)}
	
		set bookID [booksDB eval {SELECT bookid FROM Books WHERE BookName=$bookname}]
		if {$splitPages} {
			for {set i 0} {$i<$pages} {incr i} {
				set newData [lrange $theData  [expr {$i*830}] [expr {($i+1)*830}]]
				booksDB	eval {INSERT INTO BooksData (bookid,bookpage,data) VALUES($bookID,$i,$newData)}						
			}
		} else {
			booksDB	eval {INSERT INTO BooksFTS (BookName,pages,data) VALUES($bookname,$pages,$theData)}
		}

		booksDB eval {COMMIT TRANSACTION}
		
		close $openFile
		puts "Done writing $thefile to the database!"
	}
}
#ConvertToTxt "/home/lostone/School/IT Privacy & Law/" "/home/lostone/School/IT Privacy & Law/extracts" 
AddBooksToDb "/home/lostone/School/IT Privacy & Law/books.sqlite" "/home/lostone/School/IT Privacy & Law/extracts" 1

#Curious about timing normal database search with LIKE vs full text search 4
#time {booksDB2 eval {SELECT rowid FROM BooksData WHERE data LIKE '%Flowers%'}} 100
#2699524.55 microseconds per iteration
#time {booksDB eval {SELECT rowid FROM BooksData WHERE data MATCH '*Flowers*'}} 100
#15978.82 microseconds per iteration

#So almost 168 times faster..:D#
