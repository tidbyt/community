load("random.star", "random")
load("render.star", "render")

quotes = [
    {
        "id": "1",
        "quote": "clock speed",
    },
    {
        "id": "2",
        "quote": "solar flares",
    },
    {
        "id": "3",
        "quote": "electromagnetic radiation from satellite debris",
    },
    {
        "id": "4",
        "quote": "static from nylon underwear",
    },
    {
        "id": "5",
        "quote": "static from plastic slide rules",
    },
    {
        "id": "6",
        "quote": "global warming",
    },
    {
        "id": "7",
        "quote": "poor power conditioning",
    },
    {
        "id": "8",
        "quote": "static buildup",
    },
    {
        "id": "9",
        "quote": "doppler effect",
    },
    {
        "id": "10",
        "quote": "hardware stress fractures",
    },
    {
        "id": "11",
        "quote": "magnetic interference from money/credit cards",
    },
    {
        "id": "12",
        "quote": "dry joints on cable plug",
    },
    {
        "id": "13",
        "quote": "we're waiting for [the phone company] to fix that line",
    },
    {
        "id": "14",
        "quote": "sounds like a Windows problem, try calling Microsoft support",
    },
    {
        "id": "15",
        "quote": "temporary routing anomaly",
    },
    {
        "id": "16",
        "quote": "somebody was calculating pi on the server",
    },
    {
        "id": "17",
        "quote": "fat electrons in the lines",
    },
    {
        "id": "18",
        "quote": "excess surge protection",
    },
    {
        "id": "19",
        "quote": "floating point processor overflow",
    },
    {
        "id": "20",
        "quote": "divide-by-zero error",
    },
    {
        "id": "21",
        "quote": "POSIX compliance problem",
    },
    {
        "id": "22",
        "quote": "monitor resolution too high",
    },
    {
        "id": "23",
        "quote": "improperly oriented keyboard",
    },
    {
        "id": "24",
        "quote": "network packets travelling uphill (use a carrier pigeon)",
    },
    {
        "id": "25",
        "quote": "Decreasing electron flux",
    },
    {
        "id": "26",
        "quote": "first Saturday after first full moon in Winter",
    },
    {
        "id": "27",
        "quote": "radiosity depletion",
    },
    {
        "id": "28",
        "quote": "CPU radiator broken",
    },
    {
        "id": "29",
        "quote": "It works the way the Wang did, what's the problem",
    },
    {
        "id": "30",
        "quote": "positron router malfunction",
    },
    {
        "id": "31",
        "quote": "cellular telephone interference",
    },
    {
        "id": "32",
        "quote": "techtonic stress",
    },
    {
        "id": "33",
        "quote": "piezo-electric interference",
    },
    {
        "id": "34",
        "quote": "(l)user error",
    },
    {
        "id": "35",
        "quote": "working as designed",
    },
    {
        "id": "36",
        "quote": "dynamic software linking table corrupted",
    },
    {
        "id": "37",
        "quote": "heavy gravity fluctuation, move computer to floor rapidly",
    },
    {
        "id": "38",
        "quote": "secretary plugged hairdryer into UPS",
    },
    {
        "id": "39",
        "quote": "terrorist activities",
    },
    {
        "id": "40",
        "quote": "not enough memory, go get system upgrade",
    },
    {
        "id": "41",
        "quote": "interrupt configuration error",
    },
    {
        "id": "42",
        "quote": "spaghetti cable cause packet failure",
    },
    {
        "id": "43",
        "quote": "boss forgot system password",
    },
    {
        "id": "44",
        "quote": "bank holiday - system operating credits  not recharged",
    },
    {
        "id": "45",
        "quote": "virus attack, luser responsible",
    },
    {
        "id": "46",
        "quote": "waste water tank overflowed onto computer",
    },
    {
        "id": "47",
        "quote": "Complete Transient Lockout",
    },
    {
        "id": "48",
        "quote": "bad ether in the cables",
    },
    {
        "id": "49",
        "quote": "Bogon emissions",
    },
    {
        "id": "50",
        "quote": "Change in Earth's rotational speed",
    },
    {
        "id": "51",
        "quote": "Cosmic ray particles crashed through the hard disk platter",
    },
    {
        "id": "52",
        "quote": "Smell from unhygienic janitorial staff wrecked the tape heads",
    },
    {
        "id": "53",
        "quote": "Little hamster in running wheel had coronary",
    },
    {
        "id": "54",
        "quote": "Evil dogs hypnotised the night shift",
    },
    {
        "id": "55",
        "quote": "Plumber mistook routing panel for decorative wall fixture",
    },
    {
        "id": "56",
        "quote": "Electricians made popcorn in the power supply",
    },
    {
        "id": "57",
        "quote": "Groundskeepers stole the root password",
    },
    {
        "id": "58",
        "quote": "high pressure system failure",
    },
    {
        "id": "59",
        "quote": "failed trials, system needs redesigned",
    },
    {
        "id": "60",
        "quote": "system has been recalled",
    },
    {
        "id": "61",
        "quote": "not approved by the FCC",
    },
    {
        "id": "62",
        "quote": "need to wrap system in aluminum foil to fix problem",
    },
    {
        "id": "63",
        "quote": "not properly grounded, please bury computer",
    },
    {
        "id": "64",
        "quote": "CPU needs recalibration",
    },
    {
        "id": "65",
        "quote": "system needs to be rebooted",
    },
    {
        "id": "66",
        "quote": "bit bucket overflow",
    },
    {
        "id": "67",
        "quote": "descramble code needed from software company",
    },
    {
        "id": "68",
        "quote": "only available on a need to know basis",
    },
    {
        "id": "69",
        "quote": "knot in cables caused data stream to become twisted and kinked",
    },
    {
        "id": "70",
        "quote": "nesting roaches shorted out the ether cable",
    },
    {
        "id": "71",
        "quote": "The file system is full of it",
    },
    {
        "id": "72",
        "quote": "Satan did it",
    },
    {
        "id": "73",
        "quote": "Daemons did it",
    },
    {
        "id": "74",
        "quote": "You're out of memory",
    },
    {
        "id": "75",
        "quote": "There isn't any problem",
    },
    {
        "id": "76",
        "quote": "Unoptimized hard drive",
    },
    {
        "id": "77",
        "quote": "Typo in the code",
    },
    {
        "id": "78",
        "quote": "Yes, yes, its called a design limitation",
    },
    {
        "id": "79",
        "quote": "Look, buddy:  Windows 3.1 IS A General Protection Fault.",
    },
    {
        "id": "80",
        "quote": "That's a great computer you have there; have you considered how it would work as a BSD machine?",
    },
    {
        "id": "81",
        "quote": "Please excuse me, I have to circuit an AC line through my head to get this database working.",
    },
    {
        "id": "82",
        "quote": "Yeah, yo mama dresses you funny and you need a mouse to delete files.",
    },
    {
        "id": "83",
        "quote": "Support staff hung over, send aspirin and come back LATER.",
    },
    {
        "id": "84",
        "quote": "Someone is standing on the ethernet cable, causing a kink",
    },
    {
        "id": "85",
        "quote": "Windows 95 undocumented \\\"feature\\\"",
    },
    {
        "id": "86",
        "quote": "Runt packets",
    },
    {
        "id": "87",
        "quote": "Password is too complex to decrypt",
    },
    {
        "id": "88",
        "quote": "Boss' kid fucked up the machine",
    },
    {
        "id": "89",
        "quote": "Electromagnetic energy loss",
    },
    {
        "id": "90",
        "quote": "Budget cuts",
    },
    {
        "id": "91",
        "quote": "Mouse chewed through power cable",
    },
    {
        "id": "92",
        "quote": "Stale file handle (next time use Tupperware(tm)!)",
    },
    {
        "id": "93",
        "quote": "Feature not yet implemented",
    },
    {
        "id": "94",
        "quote": "Internet outage",
    },
    {
        "id": "95",
        "quote": "Pentium FDIV bug",
    },
    {
        "id": "96",
        "quote": "Vendor no longer supports the product",
    },
    {
        "id": "97",
        "quote": "Small animal kamikaze attack on power supplies",
    },
    {
        "id": "98",
        "quote": "The vendor put the bug there.",
    },
    {
        "id": "99",
        "quote": "SIMM crosstalk.",
    },
    {
        "id": "100",
        "quote": "IRQ dropout",
    },
    {
        "id": "101",
        "quote": "Collapsed Backbone",
    },
    {
        "id": "102",
        "quote": "Power company testing new voltage spike (creation) equipment",
    },
    {
        "id": "103",
        "quote": "operators on strike due to broken coffee machine",
    },
    {
        "id": "104",
        "quote": "UPS interrupted the server's power",
    },
    {
        "id": "105",
        "quote": "The electrician didn't know what the yellow cable was so he yanked the ethernet out.",
    },
    {
        "id": "106",
        "quote": "The keyboard isn't plugged in",
    },
    {
        "id": "107",
        "quote": "The air conditioning water supply pipe ruptured over the machine room",
    },
    {
        "id": "108",
        "quote": "The electricity substation in the car park blew up.",
    },
    {
        "id": "109",
        "quote": "The rolling stones concert down the road caused a brown out",
    },
    {
        "id": "110",
        "quote": "The salesman drove over the CPU board.",
    },
    {
        "id": "111",
        "quote": "The monitor is plugged into the serial port",
    },
    {
        "id": "112",
        "quote": "Root nameservers are out of sync",
    },
    {
        "id": "113",
        "quote": "electro-magnetic pulses from French above ground nuke testing.",
    },
    {
        "id": "114",
        "quote": "your keyboard's space bar is generating spurious keycodes.",
    },
    {
        "id": "115",
        "quote": "the real ttys became pseudo ttys and vice-versa.",
    },
    {
        "id": "116",
        "quote": "the printer thinks its a router.",
    },
    {
        "id": "117",
        "quote": "the router thinks its a printer.",
    },
    {
        "id": "118",
        "quote": "evil hackers from Serbia.",
    },
    {
        "id": "119",
        "quote": "we just switched to FDDI.",
    },
    {
        "id": "120",
        "quote": "halon system went off and killed the operators.",
    },
    {
        "id": "121",
        "quote": "user to computer ratio too high.",
    },
    {
        "id": "122",
        "quote": "user to computer ration too low.",
    },
    {
        "id": "123",
        "quote": "we just switched to Sprint.",
    },
    {
        "id": "124",
        "quote": "it has Intel Inside",
    },
    {
        "id": "125",
        "quote": "Sticky bits on disk.",
    },
    {
        "id": "126",
        "quote": "Power Company having EMP problems with their reactor",
    },
    {
        "id": "127",
        "quote": "The ring needs another token",
    },
    {
        "id": "128",
        "quote": "new management",
    },
    {
        "id": "129",
        "quote": "telnet: Unable to connect to remote host: Connection refused",
    },
    {
        "id": "130",
        "quote": "SCSI Chain overterminated",
    },
    {
        "id": "131",
        "quote": "It's not plugged in.",
    },
    {
        "id": "132",
        "quote": "because of network lag due to too many people playing deathmatch",
    },
    {
        "id": "133",
        "quote": "You put the disk in upside down.",
    },
    {
        "id": "134",
        "quote": "Daemons loose in system.",
    },
    {
        "id": "135",
        "quote": "User was distributing pornography on server",
    },
    {
        "id": "136",
        "quote": "BNC (brain not connected)",
    },
    {
        "id": "137",
        "quote": "UBNC (user brain not connected)",
    },
    {
        "id": "138",
        "quote": "LBNC (luser brain not connected)",
    },
    {
        "id": "139",
        "quote": "disks spinning backwards - toggle the hemisphere jumper.",
    },
    {
        "id": "140",
        "quote": "new guy cross-connected phone lines with ac power bus.",
    },
    {
        "id": "141",
        "quote": "had to use hammer to free stuck disk drive heads.",
    },
    {
        "id": "142",
        "quote": "Too few computrons available.",
    },
    {
        "id": "143",
        "quote": "Communications satellite used by the military for star wars.",
    },
    {
        "id": "144",
        "quote": "Party-bug in the Aloha protocol.",
    },
    {
        "id": "145",
        "quote": "Insert coin for new game",
    },
    {
        "id": "146",
        "quote": "Dew on the telephone lines.",
    },
    {
        "id": "147",
        "quote": "Arcserve crashed the server again.",
    },
    {
        "id": "148",
        "quote": "Some one needed the powerstrip, so they pulled the switch plug.",
    },
    {
        "id": "149",
        "quote": "My pony-tail hit the on/off switch on the power strip.",
    },
    {
        "id": "150",
        "quote": "Big to little endian conversion error",
    },
    {
        "id": "151",
        "quote": "You can tune a file system, but you can't tune a fish (from most tunefs man pages)",
    },
    {
        "id": "152",
        "quote": "Dumb terminal",
    },
    {
        "id": "153",
        "quote": "Zombie processes haunting the computer",
    },
    {
        "id": "154",
        "quote": "Incorrect time synchronization",
    },
    {
        "id": "155",
        "quote": "Defunct processes",
    },
    {
        "id": "156",
        "quote": "Stubborn processes",
    },
    {
        "id": "157",
        "quote": "non-redundant fan failure",
    },
    {
        "id": "158",
        "quote": "monitor VLF leakage",
    },
    {
        "id": "159",
        "quote": "bugs in the RAID",
    },
    {
        "id": "160",
        "quote": "no \\\"any\\\" key on keyboard",
    },
    {
        "id": "161",
        "quote": "root rot",
    },
    {
        "id": "162",
        "quote": "Backbone Scoliosis",
    },
    {
        "id": "163",
        "quote": "/pub/lunch",
    },
    {
        "id": "164",
        "quote": "excessive collisions & not enough packet ambulances",
    },
    {
        "id": "165",
        "quote": "le0: no carrier: transceiver cable problem?",
    },
    {
        "id": "166",
        "quote": "broadcast packets on wrong frequency",
    },
    {
        "id": "167",
        "quote": "popper unable to process jumbo kernel",
    },
    {
        "id": "168",
        "quote": "NOTICE: alloc: /dev/null: filesystem full",
    },
    {
        "id": "169",
        "quote": "pseudo-user on a pseudo-terminal",
    },
    {
        "id": "170",
        "quote": "Recursive traversal of loopback mount points",
    },
    {
        "id": "171",
        "quote": "Backbone adjustment",
    },
    {
        "id": "172",
        "quote": "OS swapped to disk",
    },
    {
        "id": "173",
        "quote": "vapors from evaporating sticky-note adhesives",
    },
    {
        "id": "174",
        "quote": "sticktion",
    },
    {
        "id": "175",
        "quote": "short leg on process table",
    },
    {
        "id": "176",
        "quote": "multicasts on broken packets",
    },
    {
        "id": "177",
        "quote": "ether leak",
    },
    {
        "id": "178",
        "quote": "Atilla the Hub",
    },
    {
        "id": "179",
        "quote": "endothermal recalibration",
    },
    {
        "id": "180",
        "quote": "filesystem not big enough for Jumbo Kernel Patch",
    },
    {
        "id": "181",
        "quote": "loop found in loop in redundant loopback",
    },
    {
        "id": "182",
        "quote": "system consumed all the paper for paging",
    },
    {
        "id": "183",
        "quote": "permission denied",
    },
    {
        "id": "184",
        "quote": "Reformatting Page. Wait...",
    },
    {
        "id": "185",
        "quote": "..disk or the processor is on fire.",
    },
    {
        "id": "186",
        "quote": "SCSI's too wide.",
    },
    {
        "id": "187",
        "quote": "Proprietary Information.",
    },
    {
        "id": "188",
        "quote": "Just type 'mv * /dev/null'.",
    },
    {
        "id": "189",
        "quote": "runaway cat on system.",
    },
    {
        "id": "190",
        "quote": "Did you pay the new Support Fee?",
    },
    {
        "id": "191",
        "quote": "We only support a 1200 bps connection.",
    },
    {
        "id": "192",
        "quote": "We only support a 28000 bps connection.",
    },
    {
        "id": "193",
        "quote": "Me no internet, only janitor, me just wax floors.",
    },
    {
        "id": "194",
        "quote": "I'm sorry a pentium won't do, you need an SGI to connect with us.",
    },
    {
        "id": "195",
        "quote": "Post-it Note Sludge leaked into the monitor.",
    },
    {
        "id": "196",
        "quote": "the curls in your keyboard cord are losing electricity.",
    },
    {
        "id": "197",
        "quote": "The monitor needs another box of pixels.",
    },
    {
        "id": "198",
        "quote": "RPC_PMAP_FAILURE",
    },
    {
        "id": "199",
        "quote": "kernel panic: write-only-memory (/dev/wom0) capacity exceeded.",
    },
    {
        "id": "200",
        "quote": "Write-only-memory subsystem too slow for this machine.",
    },
    {
        "id": "201",
        "quote": "Quantum dynamics are affecting the transistors",
    },
    {
        "id": "202",
        "quote": "Police are examining all internet packets in the search for a narco-net-trafficker",
    },
    {
        "id": "203",
        "quote": "We are currently trying a new concept of using a live mouse.",
    },
    {
        "id": "204",
        "quote": "Your mail is being routed through Germany ... and they're censoring us.",
    },
    {
        "id": "205",
        "quote": "Only people with names beginning with 'A' are getting mail this week (a la Microsoft)",
    },
    {
        "id": "206",
        "quote": "We didn't pay the Internet bill and it's been cut off.",
    },
    {
        "id": "207",
        "quote": "Lightning strikes.",
    },
    {
        "id": "208",
        "quote": "Of course it doesn't work. We've performed a software upgrade.",
    },
    {
        "id": "209",
        "quote": "Change your language to Finnish.",
    },
    {
        "id": "210",
        "quote": "Fluorescent lights are generating negative ions.",
    },
    {
        "id": "211",
        "quote": "High nuclear activity in your area.",
    },
    {
        "id": "212",
        "quote": "What office are you in? Oh, that one.",
    },
    {
        "id": "213",
        "quote": "The MGs ran out of gas.",
    },
    {
        "id": "214",
        "quote": "The UPS doesn't have a battery backup.",
    },
    {
        "id": "215",
        "quote": "Recursivity.  Call back if it happens again.",
    },
    {
        "id": "216",
        "quote": "Someone thought The Big Red Button was a light switch.",
    },
    {
        "id": "217",
        "quote": "The mainframe needs to rest.  It's getting old, you know.",
    },
    {
        "id": "218",
        "quote": "I'm not sure.  Try calling the Internet's head office -- it's in the book.",
    },
    {
        "id": "219",
        "quote": "The lines are all busy (busied out, that is -- why let them in to begin with?).",
    },
    {
        "id": "220",
        "quote": "Jan  9 16:41:27 huber su: 'su root' succeeded for .... on /dev/pts/1",
    },
    {
        "id": "221",
        "quote": "It's those computer people in X {city of world}.",
    },
    {
        "id": "222",
        "quote": "A star wars satellite accidently blew up the WAN.",
    },
    {
        "id": "223",
        "quote": "Fatal error right in front of screen",
    },
    {
        "id": "224",
        "quote": "That function is not currently supported",
    },
    {
        "id": "225",
        "quote": "wrong polarity of neutron flow",
    },
    {
        "id": "226",
        "quote": "Lusers learning curve appears to be fractal",
    },
    {
        "id": "227",
        "quote": "We had to turn off that service to comply with the CDA Bill.",
    },
    {
        "id": "228",
        "quote": "Ionization from the air-conditioning",
    },
    {
        "id": "229",
        "quote": "TCP/IP UDP alarm threshold is set too low.",
    },
    {
        "id": "230",
        "quote": "Fanout dropping voltage too much",
    },
    {
        "id": "231",
        "quote": "Plate voltage too low on demodulator tube",
    },
    {
        "id": "232",
        "quote": "You did wha... oh _dear_....",
    },
    {
        "id": "233",
        "quote": "CPU needs bearings repacked",
    },
    {
        "id": "234",
        "quote": "Too many little pins on CPU confusing it",
    },
    {
        "id": "235",
        "quote": "_Rosin_ core solder? But...",
    },
    {
        "id": "236",
        "quote": "Software uses US measurements, but the OS is in metric...",
    },
    {
        "id": "237",
        "quote": "The computer fleetly, mouse and all.",
    },
    {
        "id": "238",
        "quote": "Your cat tried to eat the mouse.",
    },
    {
        "id": "239",
        "quote": "The Borg tried to assimilate your system. Resistance is futile.",
    },
    {
        "id": "240",
        "quote": "It must have been the lightning storm we had",
    },
    {
        "id": "241",
        "quote": "Too much radiation coming from the soil.",
    },
    {
        "id": "242",
        "quote": "Unfortunately we have run out of bits/bytes/whatever.",
    },
    {
        "id": "243",
        "quote": "Program load too heavy for processor to lift.",
    },
    {
        "id": "244",
        "quote": "Processes running slowly due to weak power supply",
    },
    {
        "id": "245",
        "quote": "Our ISP is having switching/routing problems",
    },
    {
        "id": "246",
        "quote": "We've run out of licenses",
    },
    {
        "id": "247",
        "quote": "Interference from lunar radiation",
    },
    {
        "id": "248",
        "quote": "Standing room only on the bus.",
    },
    {
        "id": "249",
        "quote": "You need to install an RTFM interface.",
    },
    {
        "id": "250",
        "quote": "That would be because the software doesn't work.",
    },
    {
        "id": "251",
        "quote": "That's easy to fix, but I can't be bothered.",
    },
    {
        "id": "252",
        "quote": "Someone's tie is caught in the printer",
    },
    {
        "id": "253",
        "quote": "We're upgrading /dev/null",
    },
    {
        "id": "254",
        "quote": "The Usenet news is out of date",
    },
    {
        "id": "255",
        "quote": "Our POP server was kidnapped by a weasel.",
    },
    {
        "id": "256",
        "quote": "It's stuck in the Web.",
    },
    {
        "id": "257",
        "quote": "Your modem doesn't speak English.",
    },
    {
        "id": "258",
        "quote": "The mouse escaped.",
    },
    {
        "id": "259",
        "quote": "All of the packets are empty.",
    },
    {
        "id": "260",
        "quote": "The UPS is on strike.",
    },
    {
        "id": "261",
        "quote": "Neutrino overload on the nameserver",
    },
    {
        "id": "262",
        "quote": "Melting hard drives",
    },
    {
        "id": "263",
        "quote": "Someone has messed up the kernel pointers",
    },
    {
        "id": "264",
        "quote": "The kernel license has expired",
    },
    {
        "id": "265",
        "quote": "Netscape has crashed",
    },
    {
        "id": "266",
        "quote": "The cord jumped over and hit the power switch.",
    },
    {
        "id": "267",
        "quote": "It was OK before you touched it.",
    },
    {
        "id": "268",
        "quote": "Bit rot",
    },
    {
        "id": "269",
        "quote": "U.S. Postal Service",
    },
    {
        "id": "270",
        "quote": "Your Flux Capacitor has gone bad.",
    },
    {
        "id": "271",
        "quote": "The Dilithium Crystals need to be rotated.",
    },
    {
        "id": "272",
        "quote": "The static electricity routing is acting up...",
    },
    {
        "id": "273",
        "quote": "Traceroute says that there is a routing problem. Not my problem",
    },
    {
        "id": "274",
        "quote": "The co-locator cannot verify the frame-relay gateway to the ISDN server.",
    },
    {
        "id": "275",
        "quote": "condensation  has contaminated your subnet mask.",
    },
    {
        "id": "276",
        "quote": "Lawn mower blade in your fan need sharpening",
    },
    {
        "id": "277",
        "quote": "Electrons on a bender",
    },
    {
        "id": "278",
        "quote": "Telecommunications is upgrading.",
    },
    {
        "id": "279",
        "quote": "Telecommunications is downgrading.",
    },
    {
        "id": "280",
        "quote": "Telecommunications is downshifting.",
    },
    {
        "id": "281",
        "quote": "Hard drive sleeping. Let it wake up on it's own...",
    },
    {
        "id": "282",
        "quote": "Interference between the keyboard and the chair.",
    },
    {
        "id": "283",
        "quote": "The CPU has shifted, and become decentralized.",
    },
    {
        "id": "284",
        "quote": "Due to the CDA, we no longer have a root account.",
    },
    {
        "id": "285",
        "quote": "We ran out of dial tone",
    },
    {
        "id": "286",
        "quote": "You must've hit the wrong any key.",
    },
    {
        "id": "287",
        "quote": "PCMCIA slave driver",
    },
    {
        "id": "288",
        "quote": "The Token fell out of the ring. Call us when you find it.",
    },
    {
        "id": "289",
        "quote": "The hardware bus needs a new token.",
    },
    {
        "id": "290",
        "quote": "Too many interrupts",
    },
    {
        "id": "291",
        "quote": "Not enough interrupts",
    },
    {
        "id": "292",
        "quote": "The data on your hard drive is out of balance.",
    },
    {
        "id": "293",
        "quote": "Digital Manipulator exceeding velocity parameters",
    },
    {
        "id": "294",
        "quote": "appears to be a Slow/Narrow SCSI-0 Interface problem",
    },
    {
        "id": "295",
        "quote": "microelectronic Riemannian curved-space fault in write-only file system",
    },
    {
        "id": "296",
        "quote": "fractal radiation jamming the backbone",
    },
    {
        "id": "297",
        "quote": "routing problems on the neural net",
    },
    {
        "id": "298",
        "quote": "IRQ-problems with the Un-Interruptible-Power-Supply",
    },
    {
        "id": "299",
        "quote": "CPU-angle has to be adjusted because of vibrations coming from the nearby road",
    },
    {
        "id": "300",
        "quote": "emissions from GSM-phones",
    },
    {
        "id": "301",
        "quote": "CD-ROM server needs recalibration",
    },
    {
        "id": "302",
        "quote": "firewall needs cooling",
    },
    {
        "id": "303",
        "quote": "asynchronous inode failure",
    },
    {
        "id": "304",
        "quote": "transient bus protocol violation",
    },
    {
        "id": "305",
        "quote": "incompatible bit-registration operators",
    },
    {
        "id": "306",
        "quote": "your process is not ISO 9000 compliant",
    },
    {
        "id": "307",
        "quote": "You need to upgrade your VESA local bus to a MasterCard local bus.",
    },
    {
        "id": "308",
        "quote": "The recent proliferation of Nuclear Testing",
    },
    {
        "id": "309",
        "quote": "Elves on strike. (Why do they call EMAG Elf Magic)",
    },
    {
        "id": "310",
        "quote": "Your EMAIL is now being delivered by the USPS.",
    },
    {
        "id": "311",
        "quote": "Your computer hasn't been returning all the bits it gets from the Internet.",
    },
    {
        "id": "312",
        "quote": "You've been infected by the Telescoping Hubble virus.",
    },
    {
        "id": "313",
        "quote": "Scheduled global CPU outage",
    },
    {
        "id": "314",
        "quote": "Your Pentium has a heating problem",
    },
    {
        "id": "315",
        "quote": "Your processor has processed too many instructions.",
    },
    {
        "id": "316",
        "quote": "Your packets were eaten by the terminator",
    },
    {
        "id": "317",
        "quote": "Your processor does not develop enough heat.",
    },
    {
        "id": "318",
        "quote": "We need a licensed electrician to replace the light bulbs in the computer room.",
    },
    {
        "id": "319",
        "quote": "The POP server is out of Coke",
    },
    {
        "id": "320",
        "quote": "Fiber optics caused gas main leak",
    },
    {
        "id": "321",
        "quote": "Server depressed, needs Prozac",
    },
    {
        "id": "322",
        "quote": "quantum decoherence",
    },
    {
        "id": "323",
        "quote": "those damn raccoons!",
    },
    {
        "id": "324",
        "quote": "suboptimal routing experience",
    },
    {
        "id": "325",
        "quote": "A plumber is needed, the network drain is clogged",
    },
    {
        "id": "326",
        "quote": "50% of the manual is in .pdf readme files",
    },
    {
        "id": "327",
        "quote": "the AA battery in the wallclock sends magnetic interference",
    },
    {
        "id": "328",
        "quote": "the xy axis in the trackball is coordinated with the summer solstice",
    },
    {
        "id": "329",
        "quote": "the butane lighter causes the pincushioning",
    },
    {
        "id": "330",
        "quote": "old inkjet cartridges emanate barium-based fumes",
    },
    {
        "id": "331",
        "quote": "manager in the cable duct",
    },
    {
        "id": "332",
        "quote": "We'll fix that in the next (upgrade, update, patch release, service pack).",
    },
    {
        "id": "333",
        "quote": "HTTPD Error 666 : BOFH was here",
    },
    {
        "id": "334",
        "quote": "HTTPD Error 4004 : very old Intel cpu - insufficient processing power",
    },
    {
        "id": "335",
        "quote": "Network failure -  call NBC",
    },
    {
        "id": "336",
        "quote": "Having to manually track the satellite.",
    },
    {
        "id": "337",
        "quote": "The rubber band broke",
    },
    {
        "id": "338",
        "quote": "We're on Token Ring, and it looks like the token got loose.",
    },
    {
        "id": "339",
        "quote": "Stray Alpha Particles from memory packaging caused Hard Memory Error on Server.",
    },
    {
        "id": "340",
        "quote": "paradigm shift...without a clutch",
    },
    {
        "id": "341",
        "quote": "PEBKAC (Problem Exists Between Keyboard And Chair)",
    },
    {
        "id": "342",
        "quote": "The cables are not the same length.",
    },
    {
        "id": "343",
        "quote": "Second-system effect.",
    },
    {
        "id": "344",
        "quote": "Chewing gum on /dev/sd3c",
    },
    {
        "id": "345",
        "quote": "Boredom in the Kernel.",
    },
    {
        "id": "346",
        "quote": "the daemons! the daemons! the terrible daemons!",
    },
    {
        "id": "347",
        "quote": "I'd love to help you -- it's just that the Boss won't let me",
    },
    {
        "id": "348",
        "quote": "struck by the Good Times virus",
    },
    {
        "id": "349",
        "quote": "YOU HAVE AN I/O ERROR -> Incompetent Operator error",
    },
    {
        "id": "350",
        "quote": "Your parity check is overdrawn and you're out of cache.",
    },
    {
        "id": "351",
        "quote": "Communist revolutionaries taking over the server room",
    },
    {
        "id": "352",
        "quote": "Plasma conduit breach",
    },
    {
        "id": "353",
        "quote": "Out of cards on drive D:",
    },
    {
        "id": "354",
        "quote": "Sand fleas eating the Internet cables",
    },
    {
        "id": "355",
        "quote": "parallel processors running perpendicular today",
    },
    {
        "id": "356",
        "quote": "ATM cell has no roaming feature turned on, notebooks can't connect",
    },
    {
        "id": "357",
        "quote": "Webmasters kidnapped by evil cult.",
    },
    {
        "id": "358",
        "quote": "Failure to adjust for daylight savings time.",
    },
    {
        "id": "359",
        "quote": "Virus transmitted from computer to sysadmins.",
    },
    {
        "id": "360",
        "quote": "Virus due to computers having unsafe sex.",
    },
    {
        "id": "361",
        "quote": "Incorrectly configured static routes on the corerouters.",
    },
    {
        "id": "362",
        "quote": "Forced to support NT servers; sysadmins quit.",
    },
    {
        "id": "363",
        "quote": "Suspicious pointer corrupted virtual machine",
    },
    {
        "id": "364",
        "quote": "It's the InterNIC's fault.",
    },
    {
        "id": "365",
        "quote": "Root name servers corrupted.",
    },
    {
        "id": "366",
        "quote": "Budget cuts forced us to sell all the power cords for the servers.",
    },
    {
        "id": "367",
        "quote": "Someone hooked the twisted pair wires into the answering machine.",
    },
    {
        "id": "368",
        "quote": "Operators killed by year 2000 bug bite.",
    },
    {
        "id": "369",
        "quote": "We've picked COBOL as the language of choice.",
    },
    {
        "id": "370",
        "quote": "Operators killed when huge stack of backup tapes fell over.",
    },
    {
        "id": "371",
        "quote": "Robotic tape changer mistook operator's tie for a backup tape.",
    },
    {
        "id": "372",
        "quote": "Someone was smoking in the computer room",
    },
    {
        "id": "373",
        "quote": "it's an ID-10-T error",
    },
    {
        "id": "374",
        "quote": "Dyslexics retyping hosts file on servers",
    },
    {
        "id": "375",
        "quote": "The Internet is being scanned for viruses.",
    },
    {
        "id": "376",
        "quote": "Your computer's union contract is set to expire at midnight.",
    },
    {
        "id": "377",
        "quote": "Bad user karma.",
    },
    {
        "id": "378",
        "quote": "/dev/clue was linked to /dev/null",
    },
    {
        "id": "379",
        "quote": "Increased sunspot activity.",
    },
    {
        "id": "380",
        "quote": "We already sent around a notice about that.",
    },
    {
        "id": "381",
        "quote": "It's union rules. There's nothing we can do about it. Sorry.",
    },
    {
        "id": "382",
        "quote": "Interference from the Van Allen Belt.",
    },
    {
        "id": "383",
        "quote": "Jupiter is aligned with Mars.",
    },
    {
        "id": "384",
        "quote": "Redundant ACLs.",
    },
    {
        "id": "385",
        "quote": "Mail server hit by UniSpammer.",
    },
    {
        "id": "386",
        "quote": "T-1's congested due to porn traffic to the news server.",
    },
    {
        "id": "387",
        "quote": "Data for intranet got routed through the extranet and landed on the internet.",
    },
    {
        "id": "388",
        "quote": "We are a 100% Microsoft Shop.",
    },
    {
        "id": "389",
        "quote": "Sales staff sold a product we don't offer.",
    },
    {
        "id": "390",
        "quote": "Secretary sent chain letter to all 5000 employees.",
    },
    {
        "id": "391",
        "quote": "Sysadmin didn't hear pager go off due to loud music from bar-room speakers.",
    },
    {
        "id": "392",
        "quote": "Sysadmin accidentally destroyed pager with a large hammer.",
    },
    {
        "id": "393",
        "quote": "Sysadmins unavailable because they are in a meeting",
    },
    {
        "id": "394",
        "quote": "Bad cafeteria food landed all the sysadmins in the hospital.",
    },
    {
        "id": "395",
        "quote": "Route flapping at the NAP.",
    },
    {
        "id": "396",
        "quote": "Computers under water due to SYN flooding.",
    },
    {
        "id": "397",
        "quote": "The vulcan-death-grip ping has been applied.",
    },
    {
        "id": "398",
        "quote": "Electrical conduits in machine room are melting.",
    },
    {
        "id": "399",
        "quote": "Traffic jam on the Information Superhighway.",
    },
    {
        "id": "400",
        "quote": "Radial Telemetry Infiltration",
    },
    {
        "id": "401",
        "quote": "Cow-tippers tipped a cow onto the server.",
    },
    {
        "id": "402",
        "quote": "tachyon emissions overloading the system",
    },
    {
        "id": "403",
        "quote": "Maintenance window broken",
    },
    {
        "id": "404",
        "quote": "We're out of slots on the server",
    },
    {
        "id": "405",
        "quote": "Computer room being moved.  Our systems are down for the weekend.",
    },
    {
        "id": "406",
        "quote": "Sysadmins busy fighting SPAM.",
    },
    {
        "id": "407",
        "quote": "Repeated reboots of the system failed to solve problem",
    },
    {
        "id": "408",
        "quote": "Feature was not beta tested",
    },
    {
        "id": "409",
        "quote": "Domain controller not responding",
    },
    {
        "id": "410",
        "quote": "Someone else stole your IP address, call the Internet detectives!",
    },
    {
        "id": "411",
        "quote": "It's not RFC-822 compliant.",
    },
    {
        "id": "412",
        "quote": "operation failed because: there is no message for this error (#1014)",
    },
    {
        "id": "413",
        "quote": "stop bit received",
    },
    {
        "id": "414",
        "quote": "internet is needed to catch the etherbunny",
    },
    {
        "id": "415",
        "quote": "network down, IP packets delivered via UPS",
    },
    {
        "id": "416",
        "quote": "Firmware update in the coffee machine",
    },
    {
        "id": "417",
        "quote": "Temporal anomaly",
    },
    {
        "id": "418",
        "quote": "Mouse has out-of-cheese-error",
    },
    {
        "id": "419",
        "quote": "Borg implants are failing",
    },
    {
        "id": "420",
        "quote": "Borg nanites have infested the server",
    },
    {
        "id": "421",
        "quote": "error: one bad user found in front of screen",
    },
    {
        "id": "422",
        "quote": "Please state the nature of the technical emergency",
    },
    {
        "id": "423",
        "quote": "Internet shut down due to maintenance",
    },
    {
        "id": "424",
        "quote": "Daemon escaped from pentagram",
    },
    {
        "id": "425",
        "quote": "crop circles in the corn shell",
    },
    {
        "id": "426",
        "quote": "sticky bit has come loose",
    },
    {
        "id": "427",
        "quote": "Hot Java has gone cold",
    },
    {
        "id": "428",
        "quote": "Cache miss - please take better aim next time",
    },
    {
        "id": "429",
        "quote": "Hash table has woodworm",
    },
    {
        "id": "430",
        "quote": "Trojan horse ran out of hay",
    },
    {
        "id": "431",
        "quote": "Zombie processes detected, machine is haunted.",
    },
    {
        "id": "432",
        "quote": "overflow error in /dev/null",
    },
    {
        "id": "433",
        "quote": "Browser's cookie is corrupted -- someone's been nibbling on it.",
    },
    {
        "id": "434",
        "quote": "Mailer-daemon is busy burning your message in hell.",
    },
    {
        "id": "435",
        "quote": "According to Microsoft, it's by design",
    },
    {
        "id": "436",
        "quote": "vi needs to be upgraded to vii",
    },
    {
        "id": "437",
        "quote": "greenpeace free'd the mallocs",
    },
    {
        "id": "438",
        "quote": "astropneumatic oscillations in the water-cooling",
    },
    {
        "id": "439",
        "quote": "Somebody ran the operating system through a spelling checker.",
    },
    {
        "id": "440",
        "quote": "Rhythmic variations in the voltage reaching the power supply.",
    },
    {
        "id": "441",
        "quote": "Keyboard Actuator Failure.  Order and Replace.",
    },
    {
        "id": "442",
        "quote": "Packet held up at customs.",
    },
    {
        "id": "443",
        "quote": "Propagation delay.",
    },
    {
        "id": "444",
        "quote": "High line impedance.",
    },
    {
        "id": "445",
        "quote": "Someone set us up the bomb.",
    },
    {
        "id": "446",
        "quote": "Power surges on the Underground.",
    },
    {
        "id": "447",
        "quote": "Don't worry; it's been deprecated. The new one is worse.",
    },
    {
        "id": "448",
        "quote": "Excess condensation in cloud network",
    },
    {
        "id": "449",
        "quote": "It is a layer 8 problem",
    },
    {
        "id": "450",
        "quote": "The math co-processor had an overflow error",
    },
    {
        "id": "451",
        "quote": "Leap second overloaded RHEL6 servers",
    },
    {
        "id": "452",
        "quote": "DNS server drank too much and had a hiccup",
    },
    {
        "id": "453",
        "quote": "Your machine had the fuses in backwards.",
    },
]

def main():
    rand_num = random.number(1, len(quotes))
    index = rand_num % len(quotes)  # Calculate the index based on the random number
    selected_quote = quotes[index]

    quoteId = selected_quote["id"]
    quote = selected_quote["quote"]

    return render.Root(
        child = render.Column(
            expanded = False,
            children = [
                render.Text(
                    font = "CG-pixel-4x5-mono",
                    color = "#0a0",
                    content = " ",
                ),
                render.Text(
                    font = "CG-pixel-4x5-mono",
                    color = "#0a0",
                    content = " BOFH Excuse",
                ),
                render.Text(
                    font = "Dina_r400-6",
                    content = ("   # %s " % quoteId),
                    color = "#0a0",
                ),
                render.Marquee(
                    width = 64,
                    height = 16,
                    child = render.WrappedText(
                        font = "CG-pixel-3x5-mono",
                        height = 16,
                        linespacing = -1,
                        content = ("%s" % quote),
                    ),
                ),
            ],
        ),
    )
