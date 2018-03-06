# Misc Stuff and Scripts

This is a list of misc stuff and scripts i've built over the time.
I have a huge list of snippets out of which I consider these to be of use for other people.
Please note that the scripts included here are proof of concepts and prototypes. 
Most of them have been refactored, enhanced and implemented in projects that my clients use.
If you're interested in the extended version contact me at [link AndreiClinciu.net](http://andreiclinciu.net) or at enotsoul[at]lba.im.



## convertDocToPDF.tcl 
This is a older version of a script I've been working on and revising for quite some time.
It scans a folder containing hunderds of thousands of DOC files.
It extracts the text, and creates a PDF

Further revisions of this program also make small PNG/JPG images for a image gallery.  And add a ton of enhancements.

If I'd reimplement it again I'd use Elixir + Ecto since the concurrency work in Elixir is extraordinary.


## ExclusiveArticleGenerator.tcl
On the first run it generates the database AND creates a download folder. Run it a second time to actually run it.

What it does is search the internet for certain keywords, downloads articles and extracts data.
It then generates random articles making the text "random" by using certain characters.

It was the MVP and prototype project before I started working on a Plagiarism Detector and Anti Plagiarism Obfuscator.
I'll write a blog post in the future about my experiences in the plagiarism domain.

I've never used it and neither should you, since plagiarism is copyright infrigment.


## Life Beyond Apocalypse.tcl 
This is a Zombie Simulation in which a user can roam a city - in the command line-  infested with zombies.

The city starts with 1 to 3 zombies and a NPC population of 100.. How will it end?

## Lista_nume.tcl

A List of 40.000+ family names in Romanian. Also contains firstnames for boys and girls.
It has functions to randomly generate names.
```
genName
```

## musicfromplaylist.tcl
A very old script that downloaded mp3 files from magnatune.


## names_generator.tcl
Contains 12.000 unique english names

## Printesa.tcl

Save the princess commandline game in ROmanian written for my wife.

## Site crawler
A basic site crawler written in Tcl. Very basic and very old. Should not be used today. I've since then moved on to use headless browsers with full javascript support.




# Copyright
All code is BSD - Contact me if you use something and need enhancements.
