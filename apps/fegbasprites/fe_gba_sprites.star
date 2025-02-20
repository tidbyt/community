"""
Applet: FE GBA Sprites
Summary: FE GBA Sprite Randomizer
Description: This app will present a random sprite from the Game Boy Advanced Fire Emblem Games. Animations are pulled directly from the Fire Emblem Wiki.
Author: ClocktimusTime
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

def getanimation():
    recruit = "https://static.wikia.nocookie.net/fireemblem/images/7/72/Recruit.gif/revision/latest?cb=20081214130647"
    jman = "https://static.wikia.nocookie.net/fireemblem/images/6/6f/Ross_journeyman_axe.gif/revision/latest?cb=20110420222227"
    pupil = "https://static.wikia.nocookie.net/fireemblem/images/1/17/Ewan.gif/revision/latest?cb=20080913121334"

    #Tier 1s
    pegknight = "https://static.wikia.nocookie.net/fireemblem/images/e/eb/Tana_pegasusknight_lance.gif/revision/latest?cb=20110421232911"
    wrider = "https://static.wikia.nocookie.net/fireemblem/images/f/f9/Cormag_wyvernrider_lance.gif/revision/latest?cb=20110422140405"

    mage = "https://static.wikia.nocookie.net/fireemblem/images/e/ee/Mage_animation.gif/revision/latest?cb=20080602162350"
    shaman = "https://static.wikia.nocookie.net/fireemblem/images/8/85/Shaman_animation.gif/revision/latest?cb=20080602162809"
    monk = "https://static.wikia.nocookie.net/fireemblem/images/5/56/Monk_animation.gif/revision/latest?cb=20080602162413"

    pirate = "https://static.wikia.nocookie.net/fireemblem/images/0/06/Ross_pirate_axe.gif/revision/latest?cb=20110420222322"
    fighter = "https://static.wikia.nocookie.net/fireemblem/images/3/31/Ross_fighter_axe.gif/revision/latest?cb=20110420222303"
    merc = "https://static.wikia.nocookie.net/fireemblem/images/f/f8/Mercenary_animation.gif/revision/latest?cb=20080530203813"
    archer = "https://static.wikia.nocookie.net/fireemblem/images/f/f7/Neimi_%28Archer%29.gif/revision/latest?cb=20101013073844"

    thief = "https://static.wikia.nocookie.net/fireemblem/images/d/db/Colm_thief_sword.gif/revision/latest?cb=20110420230403"
    myrm = "https://static.wikia.nocookie.net/fireemblem/images/2/2c/Rutger_myrmidon_sword_critical.gif/revision/latest?cb=20111031233706"

    knight = "https://static.wikia.nocookie.net/fireemblem/images/4/49/Knight_animation.gif/revision/latest?cb=20080530223732"
    scav = "https://static.wikia.nocookie.net/fireemblem/images/c/ca/Kyle_cavalier_sword.gif/revision/latest?cb=20110421232425"
    lcav = "https://static.wikia.nocookie.net/fireemblem/images/f/fc/Forde_cavalier_lance.gif/revision/latest?cb=20110421232045"

    #Tier 2s
    fknight = "https://www.bwdyeti.com/fe/anims/tier2/Falcoknight-Lance.gif"
    wyknight = "https://static.wikia.nocookie.net/fireemblem/images/b/bd/Wyvernknight_animation.gif/revision/latest?cb=20080602163031"
    wylord = "https://static.wikia.nocookie.net/fireemblem/images/f/f7/Wyvernlord_animation.gif/revision/latest?cb=20080602163055"

    summoner = "https://static.wikia.nocookie.net/fireemblem/images/6/6a/Ewan_summoner_magic.gif/revision/latest?cb=20110420231423"
    druid = "https://static.wikia.nocookie.net/fireemblem/images/4/4b/Ewan_druid_magic.gif/revision/latest?cb=20110420231339"
    sage = "https://static.wikia.nocookie.net/fireemblem/images/c/c7/Saleh_sage_magic.gif/revision/latest?cb=20110422140117"
    mknight = "https://static.wikia.nocookie.net/fireemblem/images/8/8c/L%60arachel_mageknight_magic_normal.gif/revision/latest?cb=20120201001350"
    valkyrie = "https://static.wikia.nocookie.net/fireemblem/images/8/8b/Natasha_valkyrie_magic.gif/revision/latest?cb=20110421231039"
    bishop = "https://static.wikia.nocookie.net/fireemblem/images/4/40/Moulder_bishop_magic.gif/revision/latest?cb=20110420221249"

    hero = "https://static.wikia.nocookie.net/fireemblem/images/5/5b/Garcia_hero_sword.gif/revision/latest?cb=20110420230013"
    ranger = "https://static.wikia.nocookie.net/fireemblem/images/1/1c/Gerik_ranger_bow.gif/revision/latest?cb=20110422134558"
    sniper = "https://static.wikia.nocookie.net/fireemblem/images/2/29/Innes_sniper_bow.gif/revision/latest?cb=20110420201911"
    warrior = "https://static.wikia.nocookie.net/fireemblem/images/7/76/Ross_warrior_axe.gif/revision/latest?cb=20110420222438"
    berserker = "https://static.wikia.nocookie.net/fireemblem/images/a/a6/Ross_berserker_axe.gif/revision/latest?cb=20110420222522"

    rogue = "https://static.wikia.nocookie.net/fireemblem/images/0/02/Rennac_rogue_sword.gif/revision/latest?cb=20110422135732"
    smaster = "https://static.wikia.nocookie.net/fireemblem/images/2/21/Joshua_swordmaster_sword.gif/revision/latest?cb=20110421231417"
    assassin = "https://static.wikia.nocookie.net/fireemblem/images/1/14/Jaffar_assassin_animation.gif/revision/latest?cb=20080602162203"

    lgeneral = "https://static.wikia.nocookie.net/fireemblem/images/9/9e/Vigarde_general_lance.gif/revision/latest?cb=20120101024332"
    ageneral = "https://static.wikia.nocookie.net/fireemblem/images/a/ae/Barth_general_axe.gif/revision/latest?cb=20120101025303"
    lgknight = "https://static.wikia.nocookie.net/fireemblem/images/4/48/Gilliam_greatknight_lance.gif/revision/latest?cb=20110420195929"
    agknight = "https://static.wikia.nocookie.net/fireemblem/images/a/a7/Franz_greatknight_axe.gif/revision/latest?cb=20110420200627"
    sgknight = "https://static.wikia.nocookie.net/fireemblem/images/8/84/Greatknight_animation.gif/revision/latest?cb=20080602162137"
    lpaladin = "https://static.wikia.nocookie.net/fireemblem/images/c/c6/Seth_Lance_Animation.gif/revision/latest?cb=20101014072409"
    spaladin = "https://static.wikia.nocookie.net/fireemblem/images/4/4b/Franz_paladin_sword.gif/revision/latest?cb=20110420200727"

    #Extra
    eirika = "https://static.wikia.nocookie.net/fireemblem/images/2/26/Eirika_Lord.gif/revision/latest?cb=20101013074431"
    ephraim = "https://static.wikia.nocookie.net/fireemblem/images/5/5c/Ephraim_%28Lord%29.gif/revision/latest?cb=20101014065949"
    roy = "https://static.wikia.nocookie.net/fireemblem/images/c/c3/Roy_lord_sword_normalattack.gif/revision/latest?cb=20111101000401"
    eliwood = "https://static.wikia.nocookie.net/fireemblem/images/4/4c/Eliwood_knightlord_durandal.gif/revision/latest?cb=20100723041358"
    hector = "https://static.wikia.nocookie.net/fireemblem/images/e/ed/Hector_Great_Lord_with_Armads.gif/revision/latest?cb=20150319092413"
    lyn = "https://static.wikia.nocookie.net/fireemblem/images/c/cf/Lyn_lord_sword.gif/revision/latest?cb=20120201012622"
    ddruid = "https://static.wikia.nocookie.net/fireemblem/images/3/3f/Dark_druid.gif/revision/latest?cb=20081004182202"
    zking = "https://static.wikia.nocookie.net/fireemblem/images/2/22/Zephiel_king.gif/revision/latest?cb=20081217110241"

    class_list = [
        recruit,
        jman,
        pupil,
        pegknight,
        wrider,
        mage,
        shaman,
        monk,
        pirate,
        fighter,
        merc,
        archer,
        thief,
        myrm,
        knight,
        scav,
        lcav,
        fknight,
        wyknight,
        wylord,
        summoner,
        druid,
        sage,
        mknight,
        valkyrie,
        bishop,
        hero,
        ranger,
        sniper,
        warrior,
        berserker,
        rogue,
        smaster,
        assassin,
        lgeneral,
        ageneral,
        lgknight,
        agknight,
        sgknight,
        lpaladin,
        spaladin,
        eirika,
        ephraim,
        roy,
        eliwood,
        hector,
        lyn,
        ddruid,
        zking,
    ]

    num = random.number(0, 48)
    chosen_class = class_list[num]

    return chosen_class

def main():
    current = getanimation()
    img = http.get(current).body()
    return render.Root(
        delay = 0,
        child = render.Box(
            render.Image(
                src = img,
                width = 64,
                height = 32,
            ),
        ),
    )
