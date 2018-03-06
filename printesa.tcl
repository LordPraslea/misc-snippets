#!/usr/bin/env tclsh 

if {[clock seconds] > [clock scan "1-11-2015"]} {
	puts "Nu ai voie sa vezi asta pana pe 1 noiembrie 2015!:D"
	exit
}

array set default {
	printesa Adriana
	erou Andrei
}
array set settings {
	energie 100
	poezi 0
	aur 0
	dragoste 0
	
	ciocolata 0
	ursulet 0
	flori 0
	
	telefon 0
	actiuni 0
	cheat 0
}
puts "Bine ati venit la jocul Cucereste Printesa! Cu dedicatie speciala pentru Adriana scumpa mea:). Ai sansa sa joci rolul meu:D, rolul eroului!"
puts "Rolul jocului este sa ajungi la nivelul 100 dragoste cucerind inima favoritei... Mai greu, mai usor, mai haios succes!\n"

puts "Care este numele Printesei iubite? (default $default(printesa)) "
gets stdin printesa
if {[string length $printesa] < 3} { set printesa $default(printesa) }
puts "Care este numele eroului? (default $default(erou)) "
gets stdin erou
if {[string length $erou] < 3} { set erou $default(erou) }

set settings(erou) $erou
set settings(printesa) $printesa
puts \n[string repeat =- 33]\n
puts "Extraordinar!  \n
Asa incepe povestea eroului nostru $erou care a pornit la un drum lung si anevoios in a ii cuceri
inima printesei lui iubite si dragi $printesa "


proc rnd {min max} {
		expr {int(($max - $min + 1) * rand()) + $min}
}
proc arataMeniu {meniu text} {
	global meniuCurent
	set meniuCurent ""
	set i 0
	puts [string repeat =- 33]
	puts $text
	foreach {optiune proc} $meniu {
		incr i
		puts "$i. $optiune"
		dict set meniuCurent $i $proc
	}
	puts -nonewline "\noptiune (1-$i)> "
	dict set meniuCurent 77 cheat
}
proc citesteOptiuniUtilizator {} {
	global meniuCurent
	while { !([gets stdin meniu]  &&  [dict exists $meniuCurent $meniu ])} {
		puts "Aceasta optiune nu exista, incearca din nou."
	}
	 eval [dict get $meniuCurent $meniu]
}
proc meniuPrincipal {} {
	global settings
	arataMeniu { 
		"Mergi la magazin" mergiLaMagazin
		"Mergi la munca" mergiLaMunca
		"Viziteaza Turnul Printesei" viziteazaPrintesa
		"Dormi si te odihneste" dormi
		"Statistici erou"  {statusErou meniuPrincipal}
	} "Actiuni generale. Ce actiune va lua dragul nostru erou pentru minunata lui printesa $settings(printesa) ?" 
	citesteOptiuniUtilizator
}
proc dormi {} {
	global settings
	incr settings(energie) 10
	set dragosteMinus [expr int(ceil($settings(dragoste)*0.1))]
	incr settings(dragoste) -$dragosteMinus
	puts "Obosit te-ai pus sa dormi putin si ai recapatat 10 energie. Printesa ta $settings(printesa) ti-a dus dorul, nivelul ei de dragoste a scazut cu $dragosteMinus"
	meniuPrincipal
}
proc verificaEnergie {nivel text {meniuAlternativ meniuPrincipal} } {
	global settings
	if {$settings(energie) < $nivel} { 
		puts "$text (Ai nevoie de $nivel energie, tu ai doar $settings(energie) , odihneste-te!)" 
		after 2000 [list $meniuAlternativ]
		return -level 2
	}
}
proc mergiLaMunca {} {
	global settings
	verificaEnergie 10 "Sunt extenuat si as vrea sa mai lucrez.. pentru tine un palat sa cladesc scumpa mea $settings(printesa) !"
	incr settings(energie) -10
	incr settings(aur) 10
	puts "Pentru tine scumpa mea eu merg la munca. Ca sa pot sa te-ngrijesc.
	Cu daruri sa te imbogatesc 
	Si cu tine sa ma plimb
	Pe meleaguri departate in ochii tai sa ma pierd.
	Dupa zile lungi de munca, mi-as dori si eu.. sa fiu cu tine..
	(-10 energie +10 aur)"
	meniuPrincipal
}

proc mergiLaMagazin {} {
	global settings
	incr settings(energie) -1
	verificaEnergie 1 "Printesei mele doresc sa-i cumpar ceva frumos, insa nu mai am energie!"
	arataMeniu  { 
		"O carte de poezii (+10 poezi) -15 AUR" {cumpara carte}
		"Ciocolata +1 dragoste -3 AUR" { cumpara ciocolata}
		"Buchet de flori cu: Nu ma uita, Margarete, Lalele si Trandafiri +2 dragoste -5 AUR " {cumpara flori}
		"Ursulet de Plus +3 dragoste -7 AUR" { cumpara ursulet}
		"Statistici erou" {statusErou mergiLaMagazin}
		"Nu mai vreau sa fac cumparaturi.." meniuPrincipal
	} "Bine ai venit la magazin. Locul unde cheltuiesti bani pentru printesa ta. Merita orice bunatati! (-1 energie)
	Ce vrei sa cumperi?" 
	citesteOptiuniUtilizator
}

proc cumpara {item} {
	global settings 
	switch -- $item {
		carte {  set aur 15 ; set art " o " }
		ciocolata { set aur 3 ; set art " o "  }
		ursulet { set aur 7 ; set art " un " }
		flori { set aur 5 ; set art "un buchet de" }
	}
	if {$settings(aur) < $aur} {
		puts [string repeat # 33]
		 puts "Nu ai destul aur pentru a cumpara acest cadou pentru printesa ta.. "
		 puts [string repeat # 33]
		 
	 }  else {
		 incr settings(aur) -$aur
		 incr settings($item) 
		 puts [string repeat * 33]
		 if {$item == "carte"} { incr settings(poezi) 10; puts "Ai cumparat o carte de poezii ca sa-i reciti printesei tale!" } else {
			  puts "Ai cumparat $art $item pentru printesa ta minunata"
		 }
		 puts [string repeat * 33]
	 }
	 mergiLaMagazin
}

proc viziteazaPrintesa {{vizitaNoua 1}} {
	global settings
	verificaEnergie 10 "Nu ai destula energie pentru a-ti petrece timpul cu minunata printesa $settings(printesa) .." [list viziteazaPrintesa 0]
	
	if {$vizitaNoua} {
		 puts [string repeat * 33]
		puts "Ai pornit voios la drum sa-ti vizitezi printesa (-2 energie)"
		incr settings(energie) -2
		if {$settings(telefon)} { set rnd [rnd 1 100] } else { set rnd [rnd 1 10] } 
		if {$rnd < 5  } { 
			puts "Te apropii de usa si vezi un bilet pe care scrie mare: \"Ne pare rau dar domnisoara $settings(printesa)  nu este acasa! Incercati mai tarziu!\""
				meniuPrincipal
	
		}
	}
	
	if {$settings(poezi) > 0} {
		lappend actiuni 	"Recita o poezie +1 dragoste -2 energie" [list actiunePrintesa recitaPoezie]
	}

	if {$settings(telefon) == 0} {
		lappend actiuni "Cere numarul de telefon pentru a purta conversatii romantice de la distanta" [list actiunePrintesa cereNumarTelefon]
	}

	lappend actiuni "Daruieste un cadou" [list actiunePrintesa daruiesteCadou]

	if {$settings(dragoste) > 30} {
		lappend actiuni "Imbratiseaza printesa +3 dragoste -2 energie" [list actiunePrintesa imbratiseazaPrintesa]
		lappend actiuni "Saruta buzitele printesei +1 dragoste -1 energie" [list actiunePrintesa sarutaPrintesa]
	}
	lappend actiuni "O zi placuta iti doresc...ne mai vedem.. (iubita mea)" meniuPrincipal
	lappend actiuni "Statistici erou" [list statusErou [list viziteazaPrintesa 0]]
	arataMeniu  $actiuni  "Ai ajuns la turnul al fermecatoarei printese $settings(printesa) 
	Ce urmeaza sa faci?" 
	citesteOptiuniUtilizator
}

proc actiunePrintesa {actiune} {
	set scuze	{ "Am putina treaba.. Ne vedem in alta zi, bine?"
	"Multumesc pentru vizita, trebuie sa invat. Paa"
	"Am avut o zi grea azi si-mi doresc sa ma odihnesc.. multumesc pentru vizita" 
	"Este cam tarziu, nu ar fii bine sa te intorci acasa?" }
	
	$actiune
	
	verificareFinalJoc

	if {[rnd 1 3] == 1} {
		set text [lindex $scuze [rnd 1 [llength $scuze]]-1]
		puts "Din buzitele scumpe ale printesei auzi urmatorele cuvinte:
		\" $text \"
		E clar ca acuma esti nevoit sa te intorci acasa la tine... "
		meniuPrincipal
	} else {
		viziteazaPrintesa 0
	}
}
proc verificareFinalJoc {} {
	global settings
	if {$settings(dragoste) >= 100} {
		puts [string repeat * 70]
		puts [string repeat {^_^} 5]
		puts "Se pare ca eroul nostru $settings(erou) atins nivelul de dragoste $settings(dragoste) pentru $settings(printesa)!"
puts "
_________          _______    _______  _        ______   _ 
\__   __/|\     /|(  ____ \  (  ____ \( (    /|(  __  \ ( )
   ) (   | )   ( || (    \/  | (    \/|  \  ( || (  \  )| |
   | |   | (___) || (__      | (__    |   \ | || |   ) || |
   | |   |  ___  ||  __)     |  __)   | (\ \) || |   | || |
   | |   | (   ) || (        | (      | | \   || |   ) |(_)
   | |   | )   ( || (____/\  | (____/\| )  \  || (__/  ) _ 
   )_(   |/     \|(_______/  (_______/|/    )_)(______/ (_)                                                           
"
		puts "Joc cu dedicatie speciala pentru Adriana Mardan :)"
		puts "
  _______     _____      _                                  _      _                   _ 
 |__   __|   |_   _|    | |                        /\      | |    (_)                 | |
    | | ___    | | _   _| |__   ___  ___  ___     /  \   __| |_ __ _  __ _ _ __   __ _| |
    | |/ _ \   | || | | | '_ \ / _ \/ __|/ __|   / /\ \ / _` | '__| |/ _` | '_ \ / _` | |
    | |  __/  _| || |_| | |_) |  __/\__ \ (__   / ____ \ (_| | |  | | (_| | | | | (_| |_|
    |_|\___| |_____\__,_|_.__/ \___||___/\___| /_/    \_\__,_|_|  |_|\__,_|_| |_|\__,_(_)
                                                                                         
                                                                                         "
		puts [string repeat * 70]
	}
	
}

proc recitaPoezie {} {
	global settings
	global listaPoezi
	
	incr settings(energie) -2
	incr settings(dragoste) 1
	incr settings(poezi) -1
	
	puts [string repeat * 70]
	puts "Privind-o-n ochi incepi sa-i reciti o poezie (-2 energie, -1 poezie, +1 dragoste):"
	puts [lindex $listaPoezi [rnd 1 [llength $listaPoezi]]-1]
	puts [string repeat * 70]
}

proc cereNumarTelefon {} {
	global settings
	
	set scuze {
		"Afla-l si tu!:)"
		"E secret, dar poti sa-l cauti pe net"
		"Data viitoare ti-l voi da!"
		"Mai intreaba-ma ca-mi place.. poate ti-l dau:)"
	}
	incr settings(energie) -1
	puts [string repeat * 70]
	puts "Draga mea, dar numarul tau de telefon nu mi-l dai, sa pastram si noi contact... (-1 energie)"
	if {$settings(dragoste) < 25} {
		puts "printesa ta iti raspunde: Mai trebuie sa astepti putin:)"
	} else {
		if {[rnd 1 3] == 3} {
			puts "Da, numarul este xxxxxxx... sa ma suni!"
			puts "De acuma nu te vei mai intoarce din drum daca printesa nu este acasa!"
			set settings(telefon) 1
		} else {
			puts [lindex $scuze [rnd 1 [llength $scuze]]-1]
		}
	}
	puts [string repeat * 70]
}


proc daruiesteCadou {{cadou ""}} {
	if {$cadou == ""} { daruiesteCadouMeniu }
	global settings
	puts [string repeat * 70]
	if {$cadou == "flori"} {
		incr settings(dragoste) 2
		incr settings(flori) -1
		puts "I-ai oferit niste flori minunate, ea bucuroasa le-a pus intr-o vaza."
	} elseif {$cadou == "ciocolata"} {
		incr settings(dragoste) 1
		incr settings(ciocolata) -1
		puts "Uite o ciocolata ca sa fii cea mai dulce fata din lume!"
	} elseif {$cadou == "ursulet"} {
		incr settings(dragoste) 3
		incr settings(ursulet) -1
		puts "Uite un ursulet sa aibe cine sa te protejeze cand dormi."
	} 
	puts [string repeat * 70]
	viziteazaPrintesa 0
}
proc daruiesteCadouMeniu {} {
	global settings
	
	if {$settings(flori) > 0} { 
		lappend actiuni "Daruieste un buchet minunat de flori!" [list daruiesteCadou flori]
	}
	if {$settings(ciocolata) > 0} { 
		lappend actiuni "Ofera o ciocolata sa devina si mai dulce!" [list daruiesteCadou ciocolata]
	}
	if {$settings(ursulet) > 0} { 
		lappend actiuni "Daruieste un ursulet dragalas" [list daruiesteCadou ursulet]
	}
	
	lappend actiuni "Altceva..." [list viziteazaPrintesa 0]
	lappend actiuni "Statistici erou" [list statusErou [list viziteazaPrintesa 0]]
	
	arataMeniu  $actiuni  "Ce cadou ii vei darui scumpei tale $settings(printesa)  ?" 
	citesteOptiuniUtilizator
}
proc imbratiseazaPrintesa {} {
	global settings
	incr settings(energie) -2
	incr settings(dragoste) 3
	puts "Ai imbratisat printesa (-1 energie, +3 dragoste) si parca e de puf!"
	
}
proc sarutaPrintesa {} {
	global settings
	incr settings(energie) -1
	incr settings(dragoste) 1
	
	puts "Ai sarutat printesa  si zici ca are gustul ca de miere! (-1 energie, +1 dragoste)"
}


proc statusErou {meniu} {
	global settings
	puts [string repeat =- 33]\n
	puts "Statisticile lui $settings(erou):"
	
	foreach {var} {energie poezi aur ciocolata ursulet flori } {
		puts "[string totitle $var]: $settings($var)"
	}
	if {$settings(telefon)} { puts "Ai numarul de telefon al printesei!" } else { puts "Inca NU ai numarul de telefon al printesei" }
	puts "Nivelul dragostei reciproce: $settings(dragoste)"
	puts [string repeat =- 33]\n
	after 1500  $meniu
}
# "Statistici erou" statusErou

proc cheat {} {
	global settings
	puts [string repeat @ 77]
	puts "
   ___ _                _            
  / __\ |__   ___  __ _| |_ ___ _ __ 
 / /  | '_ \ / _ \/ _` | __/ _ \ '__|
/ /___| | | |  __/ (_| | ||  __/ |   
\____/|_| |_|\___|\__,_|\__\___|_|   
                                     
"
	puts "Care este numele mijlociu al iubitei lui Andrei?"
	gets stdin nume
	
	if {[string trim [string tolower $nume]] == "claudia"} {
		incr settings(dragoste) 50
		incr settings(aur) 50
		incr settings(energie) 50
		incr settings(cheat) 1
		incr settings(actiuni) 77
		puts "Bravo, ai primit +50 dragoste/aur/energie !"
	} else {
		puts "Nope, nice try!"
	}	
	puts [string repeat @ 77]
	meniuPrincipal
}
lappend listaPoezi {
... si iara prind corabiile vant...
E marea o sirena care cheama,
Matrozii uita tot - iubita, mama
Si uita chiar si strigatul "Pamant!"

Asa-s si eu: cand vocea ta unduie,
Cand ochii tai ma-nvaluie... cand palma
s-asaza balnd si ganduri vin de-a valma,
Uit tot!...
      Iubirea-n mine suie... } 
      
lappend listaPoezi { Cand ai sa-mi iesi in cale iar
Sa nu-mi spui nici o vorba, doar

sa te apropii-ncet, tacut
sa regasim intr-un sarut

Trecutul-ntreg, imbratisati
uitand de noi, de toti uitati

si sa ramanem astfel, dusi
ca in "Sarutul" lui Brancusi.}

lappend listaPoezi {
Miroase inc-a toamna dezmatata
aceste ganduri calde cand iti scriu.
Nici tu nu vii, nici nu ma lasi sa viu...
te mai stiu oare, cea adevarata?...

Rememorez, ma zbat intre extreme,
Ma tem de vorbe, le rostesc precaut
Si-apoi pornesc din nou ca sa te caut...
Da, te astept iubito, nu te teme.

Miroase inc-a pajisti prin artere,
A fan cosit si-a-nvaluiri de ape...
Miroase-a clipa cand erai aproape...
Cat te iubesc!
   Iar restul e tacere...
}

lappend listaPoezi {
Eu toamnei te aseaman tot mai mult...

ca soapta ei, eu glasul ti-l ascult:
Ai vocea clara ca o dimineata;
te-nvalui in mister ca seara-n ceata;
ai izbucniri sagalnice, cochete
si-n zambet - lume-ntreaga de regrete;
ai stropi de roua ce-i ascunzi sub pleoapa
si ochii tai in departari se-ngroapa;
ai nostalgii ca in amurguri, seara
si te-nfiori ca sub arcus - vioara;
ma ametesti ca vinul din podgorii
si-apoi te duci ca-n vantul serii - norii...

... si ma intreb mereu: care e doamna
care ma fascineaza: tu sau toamna?
}

lappend listaPoezi {
Stii ce-am visat azi noapte
la ceasul cand pentru somn visele sunt coapte?
Tu nu erai femeie, nici eu barbat
ci doua viori. Nu-i asa ce ciudat?
Si vibram amandoi la fel, ah
ca-n dublul concert al lui Bach.
}

lappend listaPoezi {
Setos iti beau mirasma si-ti cuprind obrajii
cu palmele-amindoua, cum cuprinzi
în suflet o minune.
Ne arde-apropierea, ochi în ochi cum stam.
Si totusi tu-mi soptesti: "Mi-asa de dor de tine!"
Asa de tainic tu mi-o spui si dornic, parc-as fi
pribeag pe-un alt pamânt.

Femeie,
ce mare porti în inima si cine esti?
Mai cânta-mi inc-o data dorul tau,
sa te ascult
si clipele sa-mi para niste muguri plini,
din care infloresc aievea -- vesnicii.
}

lappend listaPoezi {
Intelepciunea unui mag mi-a povestit odata
de-un val prin care nu putem strabate cu privirea,
paienjenis ce-ascunde pretutindeni firea,
de nu vedem nimic din ce-i aievea.

Si-acum, când tu-mi ineci obrajii, ochii
în parul tau,
eu, ametit de valurile-i negre si bogate
visez
ca valul ce preface-n mister
tot largul lumii e urzit
din parul tau --
si strig,
si strig,
si-ntaia oara simt
intreaga vraja ce-a cuprins-o magul în povestea lui.
}

lappend listaPoezi {
Si vine toamna iar'
ca dup-un psalm aminul.
Doi suntem gata să gustam
cu miere-amestecat veninul.

Doi suntem gata s-ajutam
brindusile ardorii
să infloreasca iar' în noi
si-n toamna-aceasta de apoi.

Doi suntem, când cu umbra lor
ne impresoara-n lume norii.
Ce ginduri are soarele cu noi --
nu stim, dar suntem doi.
}

lappend listaPoezi {
I
Deoarece soarele nu poate să apună
făr’ de a-si întoarce privirea după fecioarele
cetătii, mă-ntreb:
de ce-as fi altfel decât soarele?

II
O fată frumoasă e
O fereastră deschisă spre paradis.
Mai verosimil decât adevărul
e câteodată un vis.

III
O fată frumoasă e
lutul ce-si umple tiparele,
desăvârsindu-se pe-o treaptă
unde povestile asteaptă.

IV
Ce umbră curată
aruncă-n lumină o fată!
E aproape ca nimicul,
singurul lucru fără de pată.

V
O fată frumoasă e
a traiului ceriste,
cerul cerului,
podoabă inelului.

VI
Frumsete din frumsete te-ai ivit
întruchipată fără veste,
cum “într-o mie si una de nopti“
povestea naste din poveste.

VII
O fată frumoasă e
o închipuire ca fumul,
de ale cărei tălpi, când umblă,
s-ar atârna tărna si drumul.

VIII
O fată frumoasă e
mirajul din zariste,
aurul graiului,
lacrima raiului.

IX
O fată frumoasă e
cum ne-o arată soarele:
pe cale veche o minune nouă,
curcubeul ce sare din rouă.

X
Tu, fată frumoasă, vei rămânea
tărâmului nostru o prelungire
de vis, iar printre legende
singura adevărată amintire.

Iar tu esti fata mea frumoasa!
}

lappend listaPoezi {
A venit toamna, acopera-mi inima cu ceva,
cu umbra unui copac sau mai bine cu umbra ta.

Mă tem ca n-am să te mai vad, uneori,
ca or să-mi creasca aripi ascutite pana la nori,
ca ai să te ascunzi intr-un ochi strain,
si el o să se-nchida cu o frunza de pelin.

Si-atunci mă apropii de pietre si tac,
iau cuvintele si le-nec în mare.
Suier luna si o rasar si o prefac
intr-o dragoste mare.

}

lappend listaPoezi {
Ce bine că esti
E o întâmplare a fiintei mele
si atunci fericirea dinlauntrul meu
e mai puternica decât mine, decât oasele mele,
pe care mi le scrisnesti intr-o imbratisare
mereu dureroasa, minunata mereu.

Să stam de vorba, să vorbim, să spunem cuvinte
lungi, sticloase, ca niste dalti ce despart
fluviul rece în delta fierbinte,
ziua de noapte, bazaltul de bazalt.

Du-mă, fericire, în sus, si izbeste-mi
timpla de stele, până când
lumea mea prelunga si în nesfirsire
se face coloana sau altceva
mult mai inalt si mult mai curând.

Ce bine ca esti, ce mirare ca sunt!
Doua cântece diferite, lovindu-se amestecindu-se,
doua culori ce nu s-au văzut niciodata,
una foarte de jos, intoarsa spre pământ,
una foarte de sus, aproape rupta
în infrigurata, neasemuita lupta
a minunii ca esti, a-ntimplarii ca sunt.
}

lappend listaPoezi {
Spune-mi, dacă te-aş prinde-ntr-o zi
şi ţi-aş săruta talpa piciorului,
nu-i aşa că ai şchiopăta puţin, după aceea,
de teamă să nu-mi striveşti sărutul?...
}

lappend listaPoezi {
Numai cât te gândesc,
și sângele dansează în jurul inimii,
numai cât te aud,
și sângele se resfiră ca o harfă.
Poate nu știi, poate n-ai să știi,
dar mersul tău e-un alfabet copilăresc,
și numai cu el îmi scriu poemele,
sub recele pojar al stelelor.
Numai cât surâzi,
și dezleg alchimiile,
numai cât te gândesc,
și-aud în lacul neliniștit al inimii
un foșnet: se desprimăvărează.
}

lappend listaPoezi {
Fara frumusetea ta, frumusetea lumii e scrum si cenusa,

Fara bratele tale, bratul oricui e pentru mine lat de spânzuratoare.
Traiesc numai ca sa masor, în fiece clipa, neîndurarea mortii.

Fara ochii tai, ochii mei nu vad decît întuneric,
Nimic nu mai are glas, stinsa e orice lumina.
Ce grea e moartea într-un univers care el însusi moare.

Fara numele tau, numele meu numeste neantul,
Vânat urca din adânc valul marii, urlându-si disperarea.

Fara frumusetea ta, frumusetea lumii e scrum si cenusa.
}

lappend listaPoezi {
Ci, de-am fi singuri amândoi
Si nime sa ne asculte,
Uitându-ma în ochii tai,
Ti-as spune asa de multe...

Ar trece vremea si n'am sti
Ce e aceia vreme
Si n'ar fi nimene din vis
În lume sa ne cheme.

Am fi departe tare dusi,
Straini de lumea'ntreaga:
Pe vesnicie ti-as fi drag,
Tu vesnic mi-ai fi draga;

Cu sarutari am sterge'n ochi
A'lacrimilor urme,
Si cine oare s'a'ndura
Al nostru raiu sa-l curme?

Ti-as spune vorbe dulci încet:
Ca sa le-auzi mai bine,
Tot mai aproape ai pleca
Obrazul tau de mine.

Si-atuncea de ne-om saruta,
A cui sa fie vina?
Nici tu, ca nu ma auziai,
Nici eu n'oiu fi pricina.
}

if {[clock seconds] > [clock scan "1-11-2015"]} {
	puts "Nu ai voie sa vezi asta pana pe 1 noiembrie 2015!:D"
	exit
}

meniuPrincipal
vwait forever
