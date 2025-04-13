"""
Applet: FE GBA Sprites
Summary: FE GBA Sprite Randomizer
Description: This app will present a random sprite from the Game Boy Advanced Fire Emblem Games. Animations are pulled directly from the Fire Emblem Wiki.
Author: ClocktimusTime
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

def getAnimation():
    # Below is a series of links to various gifs
    # These gifs are then randomly selected and played
    recruit = [
        "https://cdn.fireemblemwiki.org/5/56/Ba_fe08_amelia_recruit_lance.gif?20180125202858",
        "https://cdn.fireemblemwiki.org/0/07/Ba_fe08_amelia_recruit_lance_critical.gif?20180125202927",
    ]
    jman = [
        "https://cdn.fireemblemwiki.org/f/f8/Ba_fe08_ross_journeyman_axe.gif",
        "https://cdn.fireemblemwiki.org/4/4f/Ba_fe08_ross_journeyman_axe_critical.gif",
    ]
    pupil = ["https://static.wikia.nocookie.net/fireemblem/images/1/17/Ewan.gif/revision/latest?cb=20080913121334"]

    #Tier 1s
    pegknight = [
        "https://cdn.fireemblemwiki.org/f/f4/Ba_fe07_florina_pegasus_knight_lance.gif?20180125013316",
        "https://cdn.fireemblemwiki.org/3/38/Ba_fe07_florina_pegasus_knight_lance_critical.gif?20180125013537",
        "https://cdn.fireemblemwiki.org/0/08/Ba_fe08_tana_pegasus_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/f/f0/Ba_fe08_tana_pegasus_knight_lance_critical.gif?20180125205747",
        "https://cdn.fireemblemwiki.org/f/f3/Ba_fe08_vanessa_pegasus_knight_lance.gif?20180129051608",
        "https://cdn.fireemblemwiki.org/e/ea/Ba_fe08_vanessa_pegasus_knight_lance_critical.gif?20180129051639",
    ]
    wrider = ["https://cdn.fireemblemwiki.org/8/89/Ba_fe08_cormag_wyvern_rider_lance.gif"]

    mage = [
        "https://cdn.fireemblemwiki.org/d/d9/Ba_fe06_lilina_mage_anima.gif",
        "https://cdn.fireemblemwiki.org/3/32/Ba_fe06_hugh_mage_anima.gif",
        "https://cdn.fireemblemwiki.org/8/85/Ba_fe08_ewan_mage_anima.gif",
        "https://cdn.fireemblemwiki.org/1/17/Ba_fe08_ewan_mage_anima_critical.gif",
    ]
    shaman = [
        "https://cdn.fireemblemwiki.org/4/40/Ba_fe08_knoll_shaman_dark.gif",
        "https://cdn.fireemblemwiki.org/e/ee/Ba_fe08_ewan_shaman_dark.gif",
        "https://cdn.fireemblemwiki.org/2/23/Ba_fe08_novala_shaman_dark.gif",
    ]
    monk = [
        "https://cdn.fireemblemwiki.org/d/d8/Ba_fe08_artur_monk_light.gif?20180128213653",
        "https://cdn.fireemblemwiki.org/6/6a/Ba_fe08_artur_monk_light_critical.gif?20180128213736",
    ]

    pirate = [
        "https://cdn.fireemblemwiki.org/e/e5/Ba_fe06_geese_pirate_axe.gif",
        "https://cdn.fireemblemwiki.org/8/8f/Ba_fe08_ross_pirate_axe.gif",
    ]
    fighter = [
        "https://cdn.fireemblemwiki.org/e/ee/Ba_fe08_ross_fighter_axe.gif",
        "https://cdn.fireemblemwiki.org/7/72/Ba_fe08_ross_fighter_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/b/b6/Ba_fe08_garcia_fighter_axe.gif?20180128222942",
        "https://cdn.fireemblemwiki.org/f/fe/Ba_fe08_garcia_fighter_axe_critical.gif?20180128223004",
        "https://cdn.fireemblemwiki.org/f/f0/Ba_fe08_o%27neill_fighter_axe_critical.gif?20180129043543",
    ]
    merc = [
        "https://cdn.fireemblemwiki.org/6/61/Ba_fe06_dieck_mercenary_sword.gif",
        "https://cdn.fireemblemwiki.org/6/6f/Ba_fe08_gerik_mercenary_sword.gif",
        "https://cdn.fireemblemwiki.org/7/78/Ba_fe08_gerik_mercenary_sword_critical.gif",
    ]
    archer = [
        "https://cdn.fireemblemwiki.org/9/98/Ba_fe06_dorothy_archer_bow.gif?20110603040509",
        "https://cdn.fireemblemwiki.org/1/15/Ba_fe06_dorothy_archer_bow_critical.gif?20110603040509",
        "https://cdn.fireemblemwiki.org/5/55/Ba_fe08_neimi_archer_bow.gif?20180125205325",
        "https://cdn.fireemblemwiki.org/c/c8/Ba_fe08_neimi_archer_bow_critical.gif?20180125205352",
    ]
    thief = [
        "https://cdn.fireemblemwiki.org/c/c0/Ba_fe08_colm_thief_sword.gif",
        "https://cdn.fireemblemwiki.org/8/84/Ba_fe08_colm_thief_sword_critical.gif",
    ]
    myrm = ["https://static.wikia.nocookie.net/fireemblem/images/2/2c/Rutger_myrmidon_sword_critical.gif/revision/latest?cb=20111031233706"]

    knight = [
        "https://cdn.fireemblemwiki.org/thumb/7/73/Ba_fe06_bors_knight_lance.gif/120px-Ba_fe06_bors_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/7/7d/Ba_fe06_bors_knight_lance_critical.gif?20110508224246",
        "https://cdn.fireemblemwiki.org/thumb/d/d5/Ba_fe06_barthe_knight_lance.gif/120px-Ba_fe06_barthe_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/thumb/d/d1/Ba_fe06_barthe_knight_lance_critical.gif/120px-Ba_fe06_barthe_knight_lance_critical.gif",
    ]
    cavalier = [
        "https://cdn.fireemblemwiki.org/thumb/3/3c/Ba_fe06_alen_cavalier_lance.gif/120px-Ba_fe06_alen_cavalier_lance.gif",
        "https://cdn.fireemblemwiki.org/5/5f/Ba_fe06_alen_cavalier_lance_critical.gif?20110508222530",
        "https://cdn.fireemblemwiki.org/3/31/Ba_fe06_alen_cavalier_sword.gif",
        "https://cdn.fireemblemwiki.org/1/11/Ba_fe06_alen_cavalier_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/thumb/f/ff/Ba_fe08_forde_cavalier_lance.gif/120px-Ba_fe08_forde_cavalier_lance.gif",
        "https://cdn.fireemblemwiki.org/2/26/Ba_fe08_forde_cavalier_lance_critical.gif?20180128220833",
        "https://cdn.fireemblemwiki.org/7/72/Ba_fe08_forde_cavalier_sword.gif",
        "https://cdn.fireemblemwiki.org/4/41/Ba_fe08_forde_cavalier_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/thumb/2/28/Ba_fe08_franz_cavalier_lance.gif/120px-Ba_fe08_franz_cavalier_lance.gif",
        "https://cdn.fireemblemwiki.org/d/d0/Ba_fe08_franz_cavalier_lance_critical.gif?20180128221933",
        "https://cdn.fireemblemwiki.org/a/aa/Ba_fe08_franz_cavalier_sword.gif",
        "https://cdn.fireemblemwiki.org/1/1e/Ba_fe08_franz_cavalier_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/thumb/7/70/Ba_fe08_kyle_cavalier_lance.gif/120px-Ba_fe08_kyle_cavalier_lance.gif",
        "https://cdn.fireemblemwiki.org/e/ea/Ba_fe08_kyle_cavalier_lance_critical.gif?20180129041641",
        "https://cdn.fireemblemwiki.org/4/4c/Ba_fe08_kyle_cavalier_sword.gif",
        "https://cdn.fireemblemwiki.org/0/03/Ba_fe08_kyle_cavalier_sword_critical.gif",
    ]

    #Tier 2s
    fknight = ["https://www.bwdyeti.com/fe/anims/tier2/Falcoknight-Lance.gif"]
    wyknight = ["https://cdn.fireemblemwiki.org/6/60/Ba_fe08_valter_wyvern_knight_lance.gif?20180129051824"]
    wylord = [
        "https://cdn.fireemblemwiki.org/2/2f/Ba_fe06_galle_wyvern_lord_lance.gif?20110603040832",
        "https://cdn.fireemblemwiki.org/2/2a/Ba_fe06_galle_wyvern_lord_lance_critical.gif?20110603040832",
    ]

    summoner = [
        "https://cdn.fireemblemwiki.org/b/b4/Ba_fe08_ewan_summoner_dark.gif",
        "https://cdn.fireemblemwiki.org/b/bb/Ba_fe08_ewan_summoner_dark_critical.gif",
    ]
    druid = [
        "https://cdn.fireemblemwiki.org/e/e8/Ba_fe08_ewan_druid_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/3/37/Ba_fe08_knoll_druid_magic_critical.gif",
    ]
    sage = [
        "https://cdn.fireemblemwiki.org/0/08/Ba_fe06_brunnya_sage_anima.gif",
        "https://cdn.fireemblemwiki.org/d/d2/Ba_fe06_brunnya_sage_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/3/35/Ba_fe06_guinivere_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/b/be/Ba_fe06_guinivere_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/a/a2/Ba_fe06_lilina_sage_anima.gif",
        "https://cdn.fireemblemwiki.org/d/d6/Ba_fe06_lilina_sage_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/e/e8/Ba_fe06_hugh_sage_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/0/07/Ba_fe08_artur_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/1/1b/Ba_fe08_artur_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/2/2c/Ba_fe08_ewan_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/4/49/Ba_fe08_ewan_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/7/73/Ba_fe08_lute_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/a/ae/Ba_fe08_lute_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/8/83/Ba_fe08_moulder_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/b/bc/Ba_fe08_moulder_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/0/05/Ba_fe08_pablo_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/b/be/Ba_fe08_pablo_sage_magic_critical.gif",
        "https://cdn.fireemblemwiki.org/b/b9/Ba_fe08_saleh_sage_magic.gif",
        "https://cdn.fireemblemwiki.org/d/d6/Ba_fe08_saleh_sage_magic_critical.gif",
    ]
    mknight = [
        "https://cdn.fireemblemwiki.org/9/95/Ba_fe08_selena_mage_knight_anima.gif",
        "https://cdn.fireemblemwiki.org/7/7e/Ba_fe08_selena_mage_knight_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/8/8c/Ba_fe08_lute_mage_knight_anima.gif",
        "https://cdn.fireemblemwiki.org/1/10/Ba_fe08_lute_mage_knight_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/6/68/Ba_fe08_l%27arachel_mage_knight_anima.gif",
        "https://cdn.fireemblemwiki.org/9/90/Ba_fe08_l%27arachel_mage_knight_anima_critical.gif",
    ]
    valkyrie = [
        "https://cdn.fireemblemwiki.org/a/a1/Ba_fe06_cecilia_valkyrie_anima.gif",
        "https://cdn.fireemblemwiki.org/a/a1/Ba_fe06_cecilia_valkyrie_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/9/95/Ba_fe06_clarine_valkyrie_anima.gif",
        "https://cdn.fireemblemwiki.org/c/cb/Ba_fe06_clarine_valkyrie_anima_critical.gif",
        "https://cdn.fireemblemwiki.org/e/e5/Ba_fe08_natasha_valkyrie_light.gif",
        "https://cdn.fireemblemwiki.org/5/59/Ba_fe08_natasha_valkyrie_light_critical.gif",
        "https://cdn.fireemblemwiki.org/5/53/Ba_fe08_l%27arachel_valkyrie_light_critical.gif",
        "https://cdn.fireemblemwiki.org/d/d5/Ba_fe08_l%27arachel_valkyrie_light.gif",
    ]
    bishop = [
        "https://cdn.fireemblemwiki.org/3/31/Ba_fe06_elen_bishop_magic.gif",
        "https://cdn.fireemblemwiki.org/5/51/Ba_fe06_elen_bishop_light_critical.gif",
        "https://cdn.fireemblemwiki.org/f/fa/Ba_fe08_natasha_bishop_magic.gif",
        "https://cdn.fireemblemwiki.org/e/e4/Ba_fe08_natasha_bishop_light_critical.gif",
        "https://cdn.fireemblemwiki.org/3/38/Ba_fe08_artur_bishop_magic.gif",
        "https://cdn.fireemblemwiki.org/5/53/Ba_fe08_artur_bishop_light_critical.gif",
        "https://cdn.fireemblemwiki.org/3/30/Ba_fe08_moulder_bishop_magic.gif",
        "https://cdn.fireemblemwiki.org/f/f4/Ba_fe08_moulder_bishop_light_critical.gif",
        "https://cdn.fireemblemwiki.org/c/c1/Ba_fe08_riev_bishop_magic.gif",
        "https://cdn.fireemblemwiki.org/8/83/Ba_fe08_riev_bishop_light_critical.gif",
    ]

    hero = [
        "https://cdn.fireemblemwiki.org/1/17/Ba_fe06_echidna_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/b/b1/Ba_fe06_dieck_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/e/e4/Ba_fe08_caellach_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/3/32/Ba_fe08_caellach_hero_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/c/cb/Ba_fe08_caellach_hero_axe.gif",
        "https://cdn.fireemblemwiki.org/4/4b/Ba_fe08_gerik_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/2/25/Ba_fe08_gerik_hero_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/5/5e/Ba_fe08_gerik_hero_axe.gif",
        "https://cdn.fireemblemwiki.org/f/fb/Ba_fe08_garcia_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/b/be/Ba_fe08_garcia_hero_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/5/5a/Ba_fe08_garcia_hero_axe.gif",
        "https://cdn.fireemblemwiki.org/c/c6/Ba_fe08_ross_hero_sword.gif",
        "https://cdn.fireemblemwiki.org/6/62/Ba_fe08_ross_hero_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/5/56/Ba_fe08_ross_hero_axe.gif",
        "https://static.wikia.nocookie.net/fireemblem/images/a/ac/Linus_Hero_Sprite_%28FE7%29.gif/revision/latest?cb=20120708075858",
    ]
    ranger = [
        "https://cdn.fireemblemwiki.org/2/2b/Ba_fe06_dayan_nomadic_trooper_bow.gif?20110603040359",
        "https://cdn.fireemblemwiki.org/6/67/Ba_fe06_dayan_nomadic_trooper_sword.gif",
        "https://cdn.fireemblemwiki.org/8/81/Ba_fe08_gerik_ranger_bow.gif",
        "https://cdn.fireemblemwiki.org/9/91/Ba_fe08_gerik_ranger_bow_critical.gif?20180128224045",
        "https://cdn.fireemblemwiki.org/1/14/Ba_fe08_hayden_ranger_bow.gif",
        "https://cdn.fireemblemwiki.org/f/f1/Ba_fe08_hayden_ranger_bow_critical.gif?20180129040516",
    ]
    sniper = [
        "https://cdn.fireemblemwiki.org/b/b9/Ba_fe06_dorothy_sniper_bow.gif?20160122003016",
        "https://cdn.fireemblemwiki.org/d/d6/Ba_fe06_dorothy_sniper_bow_critical.gif?20160122002446",
        "https://cdn.fireemblemwiki.org/0/04/Ba_fe08_neimi_sniper_bow.gif?20180125205452",
        "https://cdn.fireemblemwiki.org/7/77/Ba_fe08_neimi_sniper_bow_critical.gif?20180125205530",
        "https://cdn.fireemblemwiki.org/e/ed/Ba_fe08_innes_sniper_bow.gif?20180125204637",
        "https://cdn.fireemblemwiki.org/3/30/Ba_fe08_innes_sniper_bow_critical.gif?20180125204718",
    ]
    warrior = [
        "https://cdn.fireemblemwiki.org/2/2b/Ba_fe08_garcia_warrior_axe.gif",
        "https://cdn.fireemblemwiki.org/c/c5/Ba_fe08_garcia_warrior_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/4/40/Ba_fe08_garcia_warrior_bow.gif",
        "https://cdn.fireemblemwiki.org/f/f3/Ba_fe08_garcia_warrior_bow_critical.gif?20180128223227",
        "https://cdn.fireemblemwiki.org/7/73/Ba_fe08_ross_warrior_axe.gif",
        "https://cdn.fireemblemwiki.org/4/4d/Ba_fe08_ross_warrior_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/e/e4/Ba_fe08_ross_warrior_bow.gif",
        "https://cdn.fireemblemwiki.org/2/28/Ba_fe08_ross_warrior_bow_critical.gif?20180129050244",
        "https://cdn.fireemblemwiki.org/5/5a/Ba_fe06_bartre_warrior_axe.gif",
        "https://cdn.fireemblemwiki.org/4/4b/Ba_fe06_bartre_warrior_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/d/d9/Ba_fe06_bartre_warrior_bow.gif",
        "https://cdn.fireemblemwiki.org/6/68/Ba_fe06_bartre_warrior_bow_critical.gif?20110508224231",
    ]
    berserker = [
        "https://cdn.fireemblemwiki.org/0/08/Ba_fe08_ross_berserker_axe.gif?20180129045245",
        "https://cdn.fireemblemwiki.org/e/e3/Ba_fe08_ross_berserker_axe_critical.gif?20180129045306",
        "https://cdn.fireemblemwiki.org/4/49/Ba_fe06_geese_berserker_axe.gif",
        "https://cdn.fireemblemwiki.org/a/a8/Ba_fe06_geese_berserker_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/9/99/Ba_fe06_garret_berserker_axe.gif",
        "https://cdn.fireemblemwiki.org/6/6c/Ba_fe06_garret_berserker_axe_critical.gif",
    ]

    rogue = [
        "https://cdn.fireemblemwiki.org/f/f9/Ba_fe08_colm_rogue_sword.gif",
        "https://cdn.fireemblemwiki.org/9/97/Ba_fe08_colm_rogue_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/8/82/Ba_fe08_rennac_rogue_sword.gif",
        "https://cdn.fireemblemwiki.org/b/bf/Ba_fe08_rennac_rogue_sword_critical.gif",
    ]
    smaster = [
        "https://cdn.fireemblemwiki.org/thumb/d/d0/Ba_fe08_carlyle_swordmaster_sword.gif/120px-Ba_fe08_carlyle_swordmaster_sword.gif",
        "https://cdn.fireemblemwiki.org/thumb/f/ff/Ba_fe08_carlyle_swordmaster_sword_critical.gif/120px-Ba_fe08_carlyle_swordmaster_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/thumb/e/e7/Ba_fe08_joshua_swordmaster_sword.gif/120px-Ba_fe08_joshua_swordmaster_sword.gif",
        "https://cdn.fireemblemwiki.org/thumb/0/0d/Ba_fe08_joshua_swordmaster_sword_critical.gif/120px-Ba_fe08_joshua_swordmaster_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/6/6d/Ba_fe06_fir_swordmaster_sword.gif?20110603040832",
        "https://cdn.fireemblemwiki.org/c/c7/Ba_fe06_fir_swordmaster_sword_critical.gif?20160122002818",
        "https://static.wikia.nocookie.net/fireemblem/images/3/36/Th_Lloyd.gif/revision/latest?cb=20110616235551",
    ]
    assassin = [
        "https://cdn.fireemblemwiki.org/5/58/Ba_fe07_jaffar_assassin_sword.gif?20180124232144",
        "https://cdn.fireemblemwiki.org/7/71/Ba_fe07_jaffar_assassin_sword_critical.gif?20180124232309",
        "https://cdn.fireemblemwiki.org/7/71/Ba_fe08_marisa_assassin_sword.gif?20180125204947",
        "https://cdn.fireemblemwiki.org/1/1e/Ba_fe08_marisa_assassin_sword_critical.gif?20180125205012",
        "https://cdn.fireemblemwiki.org/a/a7/Ba_fe08_joshua_assassin_sword.gif?20160122004812",
        "https://cdn.fireemblemwiki.org/7/7a/Ba_fe08_joshua_assassin_sword_critical.gif?20240615150743",
        "https://cdn.fireemblemwiki.org/d/dc/Ba_fe08_colm_assassin_sword.gif?20180125203154",
        "https://cdn.fireemblemwiki.org/0/06/Ba_fe08_colm_assassin_sword_critical.gif?20180125203216",
    ]

    general = [
        "https://cdn.fireemblemwiki.org/1/11/Ba_fe06_hector_general_lance.gif?20110603041120",
        "https://cdn.fireemblemwiki.org/d/d7/Ba_fe06_hector_general_lance_critical.gif?20160122003952",
        "https://cdn.fireemblemwiki.org/6/65/Ba_fe06_hector_general_axe.gif?20110603041119",
        "https://cdn.fireemblemwiki.org/8/8c/Ba_fe06_hector_general_axe_critical.gif?20110603041119",
        "https://cdn.fireemblemwiki.org/5/57/Ba_fe06_douglas_general_lance.gif?20110603040719",
        "https://cdn.fireemblemwiki.org/8/89/Ba_fe06_douglas_general_lance_critical.gif?20110603040719",
        "https://cdn.fireemblemwiki.org/b/bf/Ba_fe06_douglas_general_axe.gif?20110815063011",
        "https://cdn.fireemblemwiki.org/3/30/Ba_fe06_douglas_general_axe_critical.gif?20110603040510",
        "https://cdn.fireemblemwiki.org/thumb/5/57/Ba_fe06_barthe_general_lance.gif/120px-Ba_fe06_barthe_general_lance.gif",
        "https://cdn.fireemblemwiki.org/thumb/c/cd/Ba_fe06_barthe_general_lance_critical.gif/120px-Ba_fe06_barthe_general_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/2/2f/Ba_fe06_barthe_general_axe.gif",
        "https://cdn.fireemblemwiki.org/thumb/4/41/Ba_fe06_barthe_general_axe_critical.gif/120px-Ba_fe06_barthe_general_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/8/8c/Ba_fe06_bors_general_lance.gif?20110508224243",
        "https://cdn.fireemblemwiki.org/a/ac/Ba_fe06_bors_general_lance_critical.gif?20110508224241",
        "https://cdn.fireemblemwiki.org/a/a1/Ba_fe06_bors_general_axe.gif",
        "https://cdn.fireemblemwiki.org/f/f5/Ba_fe06_bors_general_axe_critical.gif?20110508224236",
        "https://cdn.fireemblemwiki.org/5/5d/Ba_fe08_fado_general_lance.gif?20180128220356",
        "https://cdn.fireemblemwiki.org/1/1a/Ba_fe08_fado_general_lance_critical.gif?20180128220431",
        "https://cdn.fireemblemwiki.org/7/7e/Ba_fe08_fado_general_axe.gif",
        "https://cdn.fireemblemwiki.org/5/53/Ba_fe08_fado_general_axe_critical.gif?20180128220223",
        "https://cdn.fireemblemwiki.org/d/d6/Ba_fe08_gilliam_general_lance.gif?20180129035818",
        "https://cdn.fireemblemwiki.org/thumb/5/5d/Ba_fe08_gilliam_general_lance_critical.gif/120px-Ba_fe08_gilliam_general_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/7/7b/Ba_fe08_gilliam_general_axe.gif",
        "https://cdn.fireemblemwiki.org/thumb/e/ed/Ba_fe08_gilliam_general_axe_critical.gif/120px-Ba_fe08_gilliam_general_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/f/f5/Ba_fe08_gilliam_general_sword.gif?20180129035938",
        "https://cdn.fireemblemwiki.org/thumb/d/d2/Ba_fe08_gilliam_general_sword_critical.gif/120px-Ba_fe08_gilliam_general_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/1/1c/Ba_fe08_amelia_general_lance.gif?20180125201915",
        "https://cdn.fireemblemwiki.org/7/74/Ba_fe08_amelia_general_lance_critical.gif?20180125202134",
        "https://cdn.fireemblemwiki.org/8/81/Ba_fe08_amelia_general_axe.gif",
        "https://cdn.fireemblemwiki.org/a/a4/Ba_fe08_amelia_general_axe_critical.gif?20180125201527",
        "https://cdn.fireemblemwiki.org/2/2c/Ba_fe08_amelia_general_sword.gif?20180125202218",
        "https://cdn.fireemblemwiki.org/8/8b/Ba_fe08_amelia_general_sword_critical.gif?20180125202246",
        "https://cdn.fireemblemwiki.org/thumb/6/6b/Ba_fe08_tirado_general_lance.gif/120px-Ba_fe08_tirado_general_lance.gif",
        "https://cdn.fireemblemwiki.org/thumb/3/31/Ba_fe08_tirado_general_lance_critical.gif/120px-Ba_fe08_tirado_general_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/4/41/Ba_fe08_tirado_general_axe.gif",
        "https://cdn.fireemblemwiki.org/thumb/6/6b/Ba_fe08_tirado_general_axe_critical.gif/120px-Ba_fe08_tirado_general_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/thumb/3/39/Ba_fe08_vigarde_general_lance.gif/120px-Ba_fe08_vigarde_general_lance.gif",
        "https://cdn.fireemblemwiki.org/thumb/6/60/Ba_fe08_vigarde_general_lance_critical.gif/120px-Ba_fe08_vigarde_general_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/0/00/Ba_fe08_vigarde_general_axe.gif",
        "https://cdn.fireemblemwiki.org/thumb/f/f6/Ba_fe08_vigarde_general_axe_critical.gif/120px-Ba_fe08_vigarde_general_axe_critical.gif",
    ]
    gknight = [
        "https://cdn.fireemblemwiki.org/e/e1/Ba_fe08_aias_great_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/8/8f/Ba_fe08_aias_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/c/ca/Ba_fe08_aias_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/e/e8/Ba_fe08_aias_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/6/60/Ba_fe08_aias_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/c/c9/Ba_fe08_aias_great_knight_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/2/24/Ba_fe08_amelia_great_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/f/f3/Ba_fe08_amelia_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/6/67/Ba_fe08_amelia_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/7/7b/Ba_fe08_amelia_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/5/54/Ba_fe08_amelia_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/e/ee/Ba_fe08_amelia_great_knight_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/7/77/Ba_fe08_forde_great_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/7/77/Ba_fe08_forde_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/1/1f/Ba_fe08_forde_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/0/04/Ba_fe08_forde_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/3/38/Ba_fe08_forde_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/d/dc/Ba_fe08_forde_great_knight_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/0/09/Ba_fe08_franz_great_knight_lance.gif?20180128222203",
        "https://cdn.fireemblemwiki.org/f/ff/Ba_fe08_franz_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/5/5f/Ba_fe08_franz_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/a/a3/Ba_fe08_franz_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/8/8b/Ba_fe08_franz_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/6/6e/Ba_fe08_franz_great_knight_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/8/82/Ba_fe08_gilliam_great_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/4/4e/Ba_fe08_gilliam_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/0/04/Ba_fe08_gilliam_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/6/66/Ba_fe08_gilliam_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/b/b4/Ba_fe08_gilliam_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/5/55/Ba_fe08_gilliam_great_knight_sword_critical.gif",
        "https://cdn.fireemblemwiki.org/e/ea/Ba_fe08_kyle_great_knight_lance.gif",
        "https://cdn.fireemblemwiki.org/9/98/Ba_fe08_kyle_great_knight_lance_critical.gif",
        "https://cdn.fireemblemwiki.org/1/1a/Ba_fe08_kyle_great_knight_axe.gif",
        "https://cdn.fireemblemwiki.org/5/57/Ba_fe08_kyle_great_knight_axe_critical.gif",
        "https://cdn.fireemblemwiki.org/3/30/Ba_fe08_kyle_great_knight_sword.gif",
        "https://cdn.fireemblemwiki.org/3/3a/Ba_fe08_kyle_great_knight_sword_critical.gif",
    ]
    paladin = [
        "https://cdn.fireemblemwiki.org/1/1f/Ba_fe08_seth_paladin_lance.gif?20180126024340",
        "https://cdn.fireemblemwiki.org/3/30/Ba_fe08_seth_paladin_lance_critical.gif?20180126024434",
        "https://cdn.fireemblemwiki.org/b/bc/Ba_fe08_seth_paladin_sword.gif?20180126024554",
        "https://cdn.fireemblemwiki.org/6/6b/Ba_fe08_seth_paladin_sword_critical.gif?20180126024620",
        "https://cdn.fireemblemwiki.org/e/ed/Ba_fe08_amelia_paladin_sword.gif?20180125202834",
        "https://cdn.fireemblemwiki.org/e/e7/Ba_fe08_forde_paladin_lance.gif?20180128221328",
        "https://cdn.fireemblemwiki.org/4/4f/Ba_fe08_forde_paladin_lance_critical.gif?20180128221401",
        "https://cdn.fireemblemwiki.org/d/d8/Ba_fe08_forde_paladin_sword.gif?20180128221434",
        "https://cdn.fireemblemwiki.org/5/5a/Ba_fe08_forde_paladin_sword_critical.gif?20180128221509",
        "https://cdn.fireemblemwiki.org/5/5c/Ba_fe08_franz_paladin_lance.gif?20180128222322",
        "https://cdn.fireemblemwiki.org/d/de/Ba_fe08_franz_paladin_lance_critical.gif?20180128222348",
        "https://cdn.fireemblemwiki.org/0/0e/Ba_fe08_franz_paladin_sword.gif?20180128222414",
        "https://cdn.fireemblemwiki.org/d/d1/Ba_fe08_franz_paladin_sword_critical.gif?20180128222449",
        "https://cdn.fireemblemwiki.org/b/b8/Ba_fe08_kyle_paladin_lance.gif?20180129042016",
        "https://cdn.fireemblemwiki.org/e/ee/Ba_fe08_kyle_paladin_lance_critical.gif?20180129042047",
        "https://cdn.fireemblemwiki.org/1/1f/Ba_fe08_kyle_paladin_sword.gif?20180129042111",
        "https://cdn.fireemblemwiki.org/9/9c/Ba_fe08_kyle_paladin_sword_critical.gif?20180129042143",
        "https://cdn.fireemblemwiki.org/8/82/Ba_fe08_orson_paladin_lance.gif?20180129043747",
        "https://cdn.fireemblemwiki.org/1/14/Ba_fe08_orson_paladin_lance_critical.gif?20180129043813",
        "https://cdn.fireemblemwiki.org/4/45/Ba_fe08_orson_paladin_sword.gif?20180129043832",
        "https://cdn.fireemblemwiki.org/f/fd/Ba_fe08_orson_paladin_sword_critical.gif?20180129043904",
        "https://cdn.fireemblemwiki.org/9/93/Ba_fe06_eliwood_paladin_lance.gif?20110603040831",
        "https://cdn.fireemblemwiki.org/9/95/Ba_fe06_eliwood_paladin_lance_critical.gif?20110603040721",
        "https://cdn.fireemblemwiki.org/5/5f/Ba_fe06_eliwood_paladin_axe.gif?20110603040720",
        "https://cdn.fireemblemwiki.org/6/6c/Ba_fe06_eliwood_paladin_axe_critical.gif?20110603040720",
        "https://cdn.fireemblemwiki.org/1/19/Ba_fe06_eliwood_paladin_sword.gif?20110603040832",
        "https://cdn.fireemblemwiki.org/0/0e/Ba_fe06_eliwood_paladin_sword_critical.gif?20110603040832",
        "https://cdn.fireemblemwiki.org/c/c2/Ba_fe06_alen_paladin_lance.gif?20110815062555",
        "https://fireemblemwiki.org/wiki/File:Ba_fe06_alen_paladin_lance_critical.gif",
        "https://fireemblemwiki.org/wiki/File:Ba_fe06_alen_paladin_axe.gif",
        "https://fireemblemwiki.org/wiki/File:Ba_fe06_alen_paladin_axe_critical.gif",
        "https://fireemblemwiki.org/wiki/File:Ba_fe06_alen_paladin_sword.gif",
        "https://fireemblemwiki.org/wiki/File:Ba_fe06_alen_paladin_sword_critical.gif",
    ]

    #Extra
    eirika = [
        "https://cdn.fireemblemwiki.org/d/df/Ba_fe08_eirika_lord_sword.gif",
        "https://static.wikia.nocookie.net/fireemblem/images/5/52/Eirika_Great_Lord.gif/revision/latest?cb=20101013074316",
    ]
    ephraim = [
        "https://cdn.fireemblemwiki.org/8/8a/Ba_fe08_ephraim_lord_lance_critical.gif",
        "https://static.wikia.nocookie.net/fireemblem/images/0/08/Ephraim_Great_Lord.gif/revision/latest?cb=20101014065914",
    ]
    lyon = ["https://cdn.fireemblemwiki.org/9/93/Ba_fe08_lyon_necromancer_dark_critical.gif"]
    roy = [
        "https://static.wikia.nocookie.net/fireemblem/images/c/c3/Roy_lord_sword_normalattack.gif/revision/latest?cb=20111101000401",
        "https://static.wikia.nocookie.net/fireemblem/images/5/55/Roy_lord_sword.gif/revision/latest?cb=20100723040818",
        "https://static.wikia.nocookie.net/fireemblem/images/2/29/Roy_masterlord_sword.gif/revision/latest?cb=20111031235847",
        "https://static.wikia.nocookie.net/fireemblem/images/a/ac/Animation_Roy_Master_Lord.gif/revision/latest?cb=20090430064933",
    ]
    eliwood = [
        "https://static.wikia.nocookie.net/fireemblem/images/0/07/Eliwood_lord_sword_normal.gif/revision/latest?cb=20120201032146",
        "https://static.wikia.nocookie.net/fireemblem/images/2/24/Eliwood_lord_sword.gif/revision/latest?cb=20100723041142",
        "https://static.wikia.nocookie.net/fireemblem/images/5/5d/Eliwood_knightlord_lance.gif/revision/latest?cb=20120201031954",
    ]
    hector = [
        "https://static.wikia.nocookie.net/fireemblem/images/0/03/Hector_attack.gif/revision/latest?cb=20150319092532",
        "https://static.wikia.nocookie.net/fireemblem/images/4/47/Hector_lord_axe_crit.gif/revision/latest?cb=20170531235536",
        "https://static.wikia.nocookie.net/fireemblem/images/c/c1/Hector_greatlord_sword.gif/revision/latest?cb=20170531234902",
        "https://static.wikia.nocookie.net/fireemblem/images/e/ed/Hector_Great_Lord_with_Armads.gif/revision/latest?cb=20150319092413",
    ]
    lyn = [
        "https://cdn.fireemblemwiki.org/e/ec/Ba_fe07_lyn_lord_sword.gif",
        "https://static.wikia.nocookie.net/fireemblem/images/5/52/Bladelord.gif/revision/latest?cb=20080810173413",
        "https://static.wikia.nocookie.net/fireemblem/images/2/2a/Lyn_bladelord_bow.gif/revision/latest?cb=20120201012353",
    ]
    ddruid = ["https://static.wikia.nocookie.net/fireemblem/images/3/3f/Dark_druid.gif/revision/latest?cb=20081004182202"]
    zking = ["https://static.wikia.nocookie.net/fireemblem/images/2/22/Zephiel_king.gif/revision/latest?cb=20081217110241"]

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
        cavalier,
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
        general,
        gknight,
        paladin,
        eirika,
        ephraim,
        lyon,
        roy,
        eliwood,
        hector,
        lyn,
        ddruid,
        zking,
    ]

    classPick = random.number(0, 44)
    chosen_class = class_list[classPick]
    spritePick = random.number(0, len(chosen_class) - 1)
    animation = chosen_class[spritePick]
    return animation

def main():
    current = getAnimation()
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
