namespace eval ::insult {
    # channel flag for enabling/disabling
    setudef flag insult

    # insult parts from insultd.cf in insultd source code
    variable adjectives "acidic annoying antique appalling asisine atrocious bad-breathed bad-tempered bawdy beef-witted
    bewildered bizarre blithering blundering boil-brained bootless boring brainless bungling cantankerous churlish
    clapper-clawed clouted clueless cockered common-kissing confused contemptible coughed-up cranky craven creepy beslubbering
    crochety crook-pated crooked crude culturally-unsound currish dankish decayed decrepit deeply-disturbed demented
    depraved deranged despicable detestable dim-witted disdainful disgraceful disgusting dismal dizzy-eyed double-ugly
    dread-bolted dreadfull driveling droning dumb dumpy egg-sucking elf-skinned embarrassing erratic evil fawning wretched
    feeble-minded fen-sucked fermented festering flap-mouthed flea-bitten fly-bitten fobbing folly-fallen fool-born foul
    friendless frothy full-gorged fulminating gleeking goatish god-awful good-for-nothing goofy gorbellied grotesque
    hacked-up half-faced halfbaked hallucinating hasty-witted headless hedge-born hopeless horn-beat hugger-muggered humid
    hypocritical ignorant ill-borne illiterate imp-bladdereddle-headed impertinent impure inadequate incapable indecent
    indescribable industrial inept infantile infected inferior infuriating inhuman insane insignificant insufferable
    irrational irresponsible it-fowling jarring knotty-pated lackluster laughable lazy left-over lewd-minded loathsome
    loggerheaded low-budget low-quality lumpish malodorous malt-wormy mammering mangled measled mentally-deficient yeasty
    milk-livered miserable monotonous motley-mind neurotic oblivious obnoxious off-color offensive onion-eyed opinionated
    outrageous pathetic penguin-molesting perverted petrified pickled pignutted pitiable pitiful plume-plucked pointy-nosed
    pompous porous pox-marked predictable preposterous pribbling psychotic puking puny rank rediculous reeky repulsive
    retarded revolting rude-snouted rump-fed ruttish salty saucyspleened sausage-snorfling self-exalting shameless sheep-biting
    sick sickening skaggy sleazy sloppy slovenly slutty spam-sucking spastic spongy spur-galled squishy stupid subhuman surly
    swag-bellied tastless tempestuous tepid testy thick tickle-brained tiny-brained toad-spotted tofu-nibbling tottering ugly
    uncouth uncultivated uncultured undisciplined uneducated ungodly unimpressive uninspiring unintelligent unmuzzled unoriginal
    unspeakable useless vain vapid vassal-willed villainous warped wayward weasel-smelling weather-bitten weedy witless worthless"

    variable amounts "accumulation ass-full assload bag ball barrel blob bowl box bucket bunch
    coagulation collection crate crock enema-bucketful excuse glob gob half-mouthful heap cake
    load loaf lump mass mound mountain ooze petrification pile plate puddle quart sack clump
    shovel-full stack thimbleful toilet-full tongueful truckload tub vat wheelbarrel-full"

    variable nouns "anal|warts ape|puke armadillo|snouts armpit|hairs barf|curds bat|guano bat|toenails buffalo|chips
    bug|parts bug|spit buzzard|barf buzzard|gizzards buzzard|leavings camel|fleas camel|flops camel|manure
    carp|guts carrion cat-hair-balls cat|bladders cat|hair chicken|guts chicken|piss cigar|butts cockroaches
    cold|sores compost cow|cud cow|pies coyote|snot craptacular|carpet|droppings dandruff|flakes dog|balls yoo-hoo
    dog|barf dog|meat dog|phlegm dog|vomit drain|clogs dung ear|wax eel|guts eel|ooze elephant|plaque entrails
    fat-woman's|stomach-bile fish|heads fish|lips foot|fungus frog|fat garbage goat|carcusses guano gunk gutter|mud
    hippo|vomit hogwash hog|livers hog|swill horse|puckies jizzum jock|straps leprousy|scabs lizard|bums llama|spit
    maggot|brains maggot|fodder maggot|guts monkey|zits moose|entrails mule|froth nasal|hairs navel|lint nose|nuggetts
    nose|pickings parrot|droppings pigeon|bombs pig|bowels pig|droppings pig|hickies pig|slop pimple|pus pimple|squeezings
    pods pond|scum poop poopy puke|lumps pus rabbit|raisins rat-farts rat|boogers rat|cysts rat|retch red|dye|number-9
    rodent|droppings rubbish seagull|puke sewage sewer|seepage shark|snot sinus|clots sinus|drainage skunk|waste zit|cheese
    sludge slug|slime slurpee-backwash snake|assholes snake|bait snake|innards snake|snot spitoon|spillage squirrel|guts
    stable|sweepings Stimpy-drool Sun|IPC|manuals swamp|mud sweat|socks swine|remains toad|tumors toe|jam toxic|waste
    tripe turkey|puke underwear urine|samples vulture|gizzards waffle-house|grits walrus|blubber weasel|warts whale|waste"
}

proc ::insult::insult {nick host hand chan arg} {
    variable adjectives
    variable amounts
    variable nouns

    # check channel flag if enabled in this channel
    if {![channel get $chan insult]} {
        return 0
    }

    # set name of insulted person
    set insultnick $nick
    if {$arg ne ""} {
        set insultnick [lindex $arg 0]

        if {[string tolower $insultnick] eq [string tolower $::botnick]} {
            if {[botisop $chan]} {
                putserv "KICK $chan $nick :You're an insult to your family!"
            } else {
                putserv "PRIVMSG $chan :You're an insult to your family!"
            }
            return
        }
    }

    # generate insult
    # You are nothing but a(n) {adj1} {amt} of {adj2} {noun}
    set adj1 [lindex $adjectives [rand [llength $adjectives]]]
    set adj2 [lindex $adjectives [rand [llength $adjectives]]]
    set amt [lindex $amounts [rand [llength $amounts]]]
    set noun [lindex $nouns [rand [llength $nouns]]]
    set noun [string map {"|" " "} $noun]
    set an "a"
    if {[string match {[aeiouh]} [string index $adj1 0]]} {
        set an "an"
    }
    set insult "You are nothing but $an $adj1 $amt of $adj2 $noun"

    putserv "PRIVMSG $chan :$insultnick, $insult"
}

namespace eval ::insult {
    bind pub - !insult ::insult::insult
    putlog "insult.tcl loaded"
}
