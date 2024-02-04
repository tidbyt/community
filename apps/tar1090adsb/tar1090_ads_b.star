"""
Applet: TAR1090 ADS-B
Summary: ADS-B From Your Station
Description: ADS-B Information from your publically available tar1090 instance.
Author: Cameron Battagler
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

TAR1090_URL_DEFAULT = "SET YOUR URL"

# Use aeronautical units by default
DEFAULT_CONVERSION_UNITS = "a"

FEET_TO_METERS_RATIO = 0.3048
NMI_TO_KM_RATIO = 1.8520
NMI_TO_MI_RATIO = 1.1508

# Taken from https://github.com/wiedehopf/tar1090/blob/5f12e20935806e69f352066ca8010c75a647ffc9/html/flags.js as the mappings are the same
ICAO_Ranges = [
    # Mostly generated from the assignment table in the appendix to Chapter 9 of
    # Annex 10 Vol III, Second Edition, July 2007 (with amendments through 88-A, 14/11/2013)
    {"start": 0x004000, "end": 0x0043FF, "country": "Zimbabwe", "flag_image": "Zimbabwe.png"},
    {"start": 0x006000, "end": 0x006FFF, "country": "Mozambique", "flag_image": "Mozambique.png"},
    {"start": 0x008000, "end": 0x00FFFF, "country": "South Africa", "flag_image": "South_Africa.png"},
    {"start": 0x010000, "end": 0x017FFF, "country": "Egypt", "flag_image": "Egypt.png"},
    {"start": 0x018000, "end": 0x01FFFF, "country": "Libyan Arab Jamahiriya", "flag_image": "Libya.png"},
    {"start": 0x020000, "end": 0x027FFF, "country": "Morocco", "flag_image": "Morocco.png"},
    {"start": 0x028000, "end": 0x02FFFF, "country": "Tunisia", "flag_image": "Tunisia.png"},
    {"start": 0x030000, "end": 0x0303FF, "country": "Botswana", "flag_image": "Botswana.png"},
    {"start": 0x032000, "end": 0x032FFF, "country": "Burundi", "flag_image": "Burundi.png"},
    {"start": 0x034000, "end": 0x034FFF, "country": "Cameroon", "flag_image": "Cameroon.png"},
    {"start": 0x035000, "end": 0x0353FF, "country": "Comoros", "flag_image": "Comoros.png"},
    {"start": 0x036000, "end": 0x036FFF, "country": "Congo", "flag_image": "Republic_of_the_Congo.png"},  # probably?
    {"start": 0x038000, "end": 0x038FFF, "country": "Cote d'Ivoire", "flag_image": "Cote_d_Ivoire.png"},
    {"start": 0x03E000, "end": 0x03EFFF, "country": "Gabon", "flag_image": "Gabon.png"},
    {"start": 0x040000, "end": 0x040FFF, "country": "Ethiopia", "flag_image": "Ethiopia.png"},
    {"start": 0x042000, "end": 0x042FFF, "country": "Equatorial Guinea", "flag_image": "Equatorial_Guinea.png"},
    {"start": 0x044000, "end": 0x044FFF, "country": "Ghana", "flag_image": "Ghana.png"},
    {"start": 0x046000, "end": 0x046FFF, "country": "Guinea", "flag_image": "Guinea.png"},
    {"start": 0x048000, "end": 0x0483FF, "country": "Guinea-Bissau", "flag_image": "Guinea_Bissau.png"},
    {"start": 0x04A000, "end": 0x04A3FF, "country": "Lesotho", "flag_image": "Lesotho.png"},
    {"start": 0x04C000, "end": 0x04CFFF, "country": "Kenya", "flag_image": "Kenya.png"},
    {"start": 0x050000, "end": 0x050FFF, "country": "Liberia", "flag_image": "Liberia.png"},
    {"start": 0x054000, "end": 0x054FFF, "country": "Madagascar", "flag_image": "Madagascar.png"},
    {"start": 0x058000, "end": 0x058FFF, "country": "Malawi", "flag_image": "Malawi.png"},
    {"start": 0x05A000, "end": 0x05A3FF, "country": "Maldives", "flag_image": "Maldives.png"},
    {"start": 0x05C000, "end": 0x05CFFF, "country": "Mali", "flag_image": "Mali.png"},
    {"start": 0x05E000, "end": 0x05E3FF, "country": "Mauritania", "flag_image": "Mauritania.png"},
    {"start": 0x060000, "end": 0x0603FF, "country": "Mauritius", "flag_image": "Mauritius.png"},
    {"start": 0x062000, "end": 0x062FFF, "country": "Niger", "flag_image": "Niger.png"},
    {"start": 0x064000, "end": 0x064FFF, "country": "Nigeria", "flag_image": "Nigeria.png"},
    {"start": 0x068000, "end": 0x068FFF, "country": "Uganda", "flag_image": "Uganda.png"},
    {"start": 0x06A000, "end": 0x06A3FF, "country": "Qatar", "flag_image": "Qatar.png"},
    {"start": 0x06C000, "end": 0x06CFFF, "country": "Central African Republic", "flag_image": "Central_African_Republic.png"},
    {"start": 0x06E000, "end": 0x06EFFF, "country": "Rwanda", "flag_image": "Rwanda.png"},
    {"start": 0x070000, "end": 0x070FFF, "country": "Senegal", "flag_image": "Senegal.png"},
    {"start": 0x074000, "end": 0x0743FF, "country": "Seychelles", "flag_image": "Seychelles.png"},
    {"start": 0x076000, "end": 0x0763FF, "country": "Sierra Leone", "flag_image": "Sierra_Leone.png"},
    {"start": 0x078000, "end": 0x078FFF, "country": "Somalia", "flag_image": "Somalia.png"},
    {"start": 0x07A000, "end": 0x07A3FF, "country": "Swaziland", "flag_image": "Swaziland.png"},
    {"start": 0x07C000, "end": 0x07CFFF, "country": "Sudan", "flag_image": "Sudan.png"},
    {"start": 0x080000, "end": 0x080FFF, "country": "Tanzania", "flag_image": "Tanzania.png"},
    {"start": 0x084000, "end": 0x084FFF, "country": "Chad", "flag_image": "Chad.png"},
    {"start": 0x088000, "end": 0x088FFF, "country": "Togo", "flag_image": "Togo.png"},
    {"start": 0x08A000, "end": 0x08AFFF, "country": "Zambia", "flag_image": "Zambia.png"},
    {"start": 0x08C000, "end": 0x08CFFF, "country": "DR Congo", "flag_image": "Democratic_Republic_of_the_Congo.png"},
    {"start": 0x090000, "end": 0x090FFF, "country": "Angola", "flag_image": "Angola.png"},
    {"start": 0x094000, "end": 0x0943FF, "country": "Benin", "flag_image": "Benin.png"},
    {"start": 0x096000, "end": 0x0963FF, "country": "Cape Verde", "flag_image": "Cape_Verde.png"},
    {"start": 0x098000, "end": 0x0983FF, "country": "Djibouti", "flag_image": "Djibouti.png"},
    {"start": 0x09A000, "end": 0x09AFFF, "country": "Gambia", "flag_image": "Gambia.png"},
    {"start": 0x09C000, "end": 0x09CFFF, "country": "Burkina Faso", "flag_image": "Burkina_Faso.png"},
    {"start": 0x09E000, "end": 0x09E3FF, "country": "Sao Tome and Principe", "flag_image": "Sao_Tome_and_Principe.png"},
    {"start": 0x0A0000, "end": 0x0A7FFF, "country": "Algeria", "flag_image": "Algeria.png"},
    {"start": 0x0A8000, "end": 0x0A8FFF, "country": "Bahamas", "flag_image": "Bahamas.png"},
    {"start": 0x0AA000, "end": 0x0AA3FF, "country": "Barbados", "flag_image": "Barbados.png"},
    {"start": 0x0AB000, "end": 0x0AB3FF, "country": "Belize", "flag_image": "Belize.png"},
    {"start": 0x0AC000, "end": 0x0ACFFF, "country": "Colombia", "flag_image": "Colombia.png"},
    {"start": 0x0AE000, "end": 0x0AEFFF, "country": "Costa Rica", "flag_image": "Costa_Rica.png"},
    {"start": 0x0B0000, "end": 0x0B0FFF, "country": "Cuba", "flag_image": "Cuba.png"},
    {"start": 0x0B2000, "end": 0x0B2FFF, "country": "El Salvador", "flag_image": "El_Salvador.png"},
    {"start": 0x0B4000, "end": 0x0B4FFF, "country": "Guatemala", "flag_image": "Guatemala.png"},
    {"start": 0x0B6000, "end": 0x0B6FFF, "country": "Guyana", "flag_image": "Guyana.png"},
    {"start": 0x0B8000, "end": 0x0B8FFF, "country": "Haiti", "flag_image": "Haiti.png"},
    {"start": 0x0BA000, "end": 0x0BAFFF, "country": "Honduras", "flag_image": "Honduras.png"},
    {"start": 0x0BC000, "end": 0x0BC3FF, "country": "Saint Vincent and the Grenadines", "flag_image": "Saint_Vincent_and_the_Grenadines.png"},
    {"start": 0x0BE000, "end": 0x0BEFFF, "country": "Jamaica", "flag_image": "Jamaica.png"},
    {"start": 0x0C0000, "end": 0x0C0FFF, "country": "Nicaragua", "flag_image": "Nicaragua.png"},
    {"start": 0x0C2000, "end": 0x0C2FFF, "country": "Panama", "flag_image": "Panama.png"},
    {"start": 0x0C4000, "end": 0x0C4FFF, "country": "Dominican Republic", "flag_image": "Dominican_Republic.png"},
    {"start": 0x0C6000, "end": 0x0C6FFF, "country": "Trinidad and Tobago", "flag_image": "Trinidad_and_Tobago.png"},
    {"start": 0x0C8000, "end": 0x0C8FFF, "country": "Suriname", "flag_image": "Suriname.png"},
    {"start": 0x0CA000, "end": 0x0CA3FF, "country": "Antigua and Barbuda", "flag_image": "Antigua_and_Barbuda.png"},
    {"start": 0x0CC000, "end": 0x0CC3FF, "country": "Grenada", "flag_image": "Grenada.png"},
    {"start": 0x0D0000, "end": 0x0D7FFF, "country": "Mexico", "flag_image": "Mexico.png"},
    {"start": 0x0D8000, "end": 0x0DFFFF, "country": "Venezuela", "flag_image": "Venezuela.png"},
    {"start": 0x100000, "end": 0x1FFFFF, "country": "Russia", "flag_image": "Russian_Federation.png"},
    {"start": 0x201000, "end": 0x2013FF, "country": "Namibia", "flag_image": "Namibia.png"},
    {"start": 0x202000, "end": 0x2023FF, "country": "Eritrea", "flag_image": "Eritrea.png"},
    {"start": 0x300000, "end": 0x33FFFF, "country": "Italy", "flag_image": "Italy.png"},
    {"start": 0x340000, "end": 0x37FFFF, "country": "Spain", "flag_image": "Spain.png"},
    {"start": 0x380000, "end": 0x3BFFFF, "country": "France", "flag_image": "France.png"},
    {"start": 0x3C0000, "end": 0x3FFFFF, "country": "Germany", "flag_image": "Germany.png"},
    # UK territories are officially part of the UK range
    # add extra entries that are above the UK and take precedence
    # this is a mess ... let's still try
    {"start": 0x400000, "end": 0x4001BF, "country": "Bermuda", "flag_image": "Bermuda.png"},
    {"start": 0x4001C0, "end": 0x4001FF, "country": "Cayman Islands", "flag_image": "Cayman_Islands.png"},
    {"start": 0x400300, "end": 0x4003FF, "country": "Turks and Caicos Islands", "flag_image": "Turks_and_Caicos_Islands.png"},
    {"start": 0x424135, "end": 0x4241F2, "country": "Cayman Islands", "flag_image": "Cayman_Islands.png"},
    {"start": 0x424200, "end": 0x4246FF, "country": "Bermuda", "flag_image": "Bermuda.png"},
    {"start": 0x424700, "end": 0x424899, "country": "Cayman Islands", "flag_image": "Cayman_Islands.png"},
    {"start": 0x424B00, "end": 0x424BFF, "country": "Isle of Man", "flag_image": "Isle_of_Man.png"},
    {"start": 0x43BE00, "end": 0x43BEFF, "country": "Bermuda", "flag_image": "Bermuda.png"},
    {"start": 0x43E700, "end": 0x43EAFD, "country": "Isle of Man", "flag_image": "Isle_of_Man.png"},
    {"start": 0x43EAFE, "end": 0x43EEFF, "country": "Guernsey", "flag_image": "Guernsey.png"},
    # catch all United Kingdom for the even more obscure stuff
    {"start": 0x400000, "end": 0x43FFFF, "country": "United Kingdom", "flag_image": "United_Kingdom.png"},
    {"start": 0x440000, "end": 0x447FFF, "country": "Austria", "flag_image": "Austria.png"},
    {"start": 0x448000, "end": 0x44FFFF, "country": "Belgium", "flag_image": "Belgium.png"},
    {"start": 0x450000, "end": 0x457FFF, "country": "Bulgaria", "flag_image": "Bulgaria.png"},
    {"start": 0x458000, "end": 0x45FFFF, "country": "Denmark", "flag_image": "Denmark.png"},
    {"start": 0x460000, "end": 0x467FFF, "country": "Finland", "flag_image": "Finland.png"},
    {"start": 0x468000, "end": 0x46FFFF, "country": "Greece", "flag_image": "Greece.png"},
    {"start": 0x470000, "end": 0x477FFF, "country": "Hungary", "flag_image": "Hungary.png"},
    {"start": 0x478000, "end": 0x47FFFF, "country": "Norway", "flag_image": "Norway.png"},
    {"start": 0x480000, "end": 0x487FFF, "country": "Kingdom of the Netherlands", "flag_image": "Netherlands.png"},
    {"start": 0x488000, "end": 0x48FFFF, "country": "Poland", "flag_image": "Poland.png"},
    {"start": 0x490000, "end": 0x497FFF, "country": "Portugal", "flag_image": "Portugal.png"},
    {"start": 0x498000, "end": 0x49FFFF, "country": "Czechia", "flag_image": "Czech_Republic.png"},
    {"start": 0x4A0000, "end": 0x4A7FFF, "country": "Romania", "flag_image": "Romania.png"},
    {"start": 0x4A8000, "end": 0x4AFFFF, "country": "Sweden", "flag_image": "Sweden.png"},
    {"start": 0x4B0000, "end": 0x4B7FFF, "country": "Switzerland", "flag_image": "Switzerland.png"},
    {"start": 0x4B8000, "end": 0x4BFFFF, "country": "Turkey", "flag_image": "Turkey.png"},
    {"start": 0x4C0000, "end": 0x4C7FFF, "country": "Serbia", "flag_image": "Serbia.png"},
    {"start": 0x4C8000, "end": 0x4C83FF, "country": "Cyprus", "flag_image": "Cyprus.png"},
    {"start": 0x4CA000, "end": 0x4CAFFF, "country": "Ireland", "flag_image": "Ireland.png"},
    {"start": 0x4CC000, "end": 0x4CCFFF, "country": "Iceland", "flag_image": "Iceland.png"},
    {"start": 0x4D0000, "end": 0x4D03FF, "country": "Luxembourg", "flag_image": "Luxembourg.png"},
    {"start": 0x4D2000, "end": 0x4D2FFF, "country": "Malta", "flag_image": "Malta.png"},
    {"start": 0x4D4000, "end": 0x4D43FF, "country": "Monaco", "flag_image": "Monaco.png"},
    {"start": 0x500000, "end": 0x5003FF, "country": "San Marino", "flag_image": "San_Marino.png"},
    {"start": 0x501000, "end": 0x5013FF, "country": "Albania", "flag_image": "Albania.png"},
    {"start": 0x501C00, "end": 0x501FFF, "country": "Croatia", "flag_image": "Croatia.png"},
    {"start": 0x502C00, "end": 0x502FFF, "country": "Latvia", "flag_image": "Latvia.png"},
    {"start": 0x503C00, "end": 0x503FFF, "country": "Lithuania", "flag_image": "Lithuania.png"},
    {"start": 0x504C00, "end": 0x504FFF, "country": "Moldova", "flag_image": "Moldova.png"},
    {"start": 0x505C00, "end": 0x505FFF, "country": "Slovakia", "flag_image": "Slovakia.png"},
    {"start": 0x506C00, "end": 0x506FFF, "country": "Slovenia", "flag_image": "Slovenia.png"},
    {"start": 0x507C00, "end": 0x507FFF, "country": "Uzbekistan", "flag_image": "Uzbekistan.png"},
    {"start": 0x508000, "end": 0x50FFFF, "country": "Ukraine", "flag_image": "Ukraine.png"},
    {"start": 0x510000, "end": 0x5103FF, "country": "Belarus", "flag_image": "Belarus.png"},
    {"start": 0x511000, "end": 0x5113FF, "country": "Estonia", "flag_image": "Estonia.png"},
    {"start": 0x512000, "end": 0x5123FF, "country": "Macedonia", "flag_image": "Macedonia.png"},
    {"start": 0x513000, "end": 0x5133FF, "country": "Bosnia and Herzegovina", "flag_image": "Bosnia.png"},
    {"start": 0x514000, "end": 0x5143FF, "country": "Georgia", "flag_image": "Georgia.png"},
    {"start": 0x515000, "end": 0x5153FF, "country": "Tajikistan", "flag_image": "Tajikistan.png"},
    {"start": 0x516000, "end": 0x5163FF, "country": "Montenegro", "flag_image": "Montenegro.png"},
    {"start": 0x600000, "end": 0x6003FF, "country": "Armenia", "flag_image": "Armenia.png"},
    {"start": 0x600800, "end": 0x600BFF, "country": "Azerbaijan", "flag_image": "Azerbaijan.png"},
    {"start": 0x601000, "end": 0x6013FF, "country": "Kyrgyzstan", "flag_image": "Kyrgyzstan.png"},
    {"start": 0x601800, "end": 0x601BFF, "country": "Turkmenistan", "flag_image": "Turkmenistan.png"},
    {"start": 0x680000, "end": 0x6803FF, "country": "Bhutan", "flag_image": "Bhutan.png"},
    {"start": 0x681000, "end": 0x6813FF, "country": "Micronesia, Federated States of", "flag_image": "Micronesia.png"},
    {"start": 0x682000, "end": 0x6823FF, "country": "Mongolia", "flag_image": "Mongolia.png"},
    {"start": 0x683000, "end": 0x6833FF, "country": "Kazakhstan", "flag_image": "Kazakhstan.png"},
    {"start": 0x684000, "end": 0x6843FF, "country": "Palau", "flag_image": "Palau.png"},
    {"start": 0x700000, "end": 0x700FFF, "country": "Afghanistan", "flag_image": "Afghanistan.png"},
    {"start": 0x702000, "end": 0x702FFF, "country": "Bangladesh", "flag_image": "Bangladesh.png"},
    {"start": 0x704000, "end": 0x704FFF, "country": "Myanmar", "flag_image": "Myanmar.png"},
    {"start": 0x706000, "end": 0x706FFF, "country": "Kuwait", "flag_image": "Kuwait.png"},
    {"start": 0x708000, "end": 0x708FFF, "country": "Laos", "flag_image": "Laos.png"},
    {"start": 0x70A000, "end": 0x70AFFF, "country": "Nepal", "flag_image": "Nepal.png"},
    {"start": 0x70C000, "end": 0x70C3FF, "country": "Oman", "flag_image": "Oman.png"},
    {"start": 0x70E000, "end": 0x70EFFF, "country": "Cambodia", "flag_image": "Cambodia.png"},
    {"start": 0x710000, "end": 0x717FFF, "country": "Saudi Arabia", "flag_image": "Saudi_Arabia.png"},
    {"start": 0x718000, "end": 0x71FFFF, "country": "South Korea", "flag_image": "South_Korea.png"},
    {"start": 0x720000, "end": 0x727FFF, "country": "North Korea", "flag_image": "North_Korea.png"},
    {"start": 0x728000, "end": 0x72FFFF, "country": "Iraq", "flag_image": "Iraq.png"},
    {"start": 0x730000, "end": 0x737FFF, "country": "Iran", "flag_image": "Iran.png"},
    {"start": 0x738000, "end": 0x73FFFF, "country": "Israel", "flag_image": "Israel.png"},
    {"start": 0x740000, "end": 0x747FFF, "country": "Jordan", "flag_image": "Jordan.png"},
    {"start": 0x748000, "end": 0x74FFFF, "country": "Lebanon", "flag_image": "Lebanon.png"},
    {"start": 0x750000, "end": 0x757FFF, "country": "Malaysia", "flag_image": "Malaysia.png"},
    {"start": 0x758000, "end": 0x75FFFF, "country": "Philippines", "flag_image": "Philippines.png"},
    {"start": 0x760000, "end": 0x767FFF, "country": "Pakistan", "flag_image": "Pakistan.png"},
    {"start": 0x768000, "end": 0x76FFFF, "country": "Singapore", "flag_image": "Singapore.png"},
    {"start": 0x770000, "end": 0x777FFF, "country": "Sri Lanka", "flag_image": "Sri_Lanka.png"},
    {"start": 0x778000, "end": 0x77FFFF, "country": "Syria", "flag_image": "Syria.png"},
    {"start": 0x789000, "end": 0x789FFF, "country": "Hong Kong", "flag_image": "Hong_Kong.png"},
    {"start": 0x780000, "end": 0x7BFFFF, "country": "China", "flag_image": "China.png"},
    {"start": 0x7C0000, "end": 0x7FFFFF, "country": "Australia", "flag_image": "Australia.png"},
    {"start": 0x800000, "end": 0x83FFFF, "country": "India", "flag_image": "India.png"},
    {"start": 0x840000, "end": 0x87FFFF, "country": "Japan", "flag_image": "Japan.png"},
    {"start": 0x880000, "end": 0x887FFF, "country": "Thailand", "flag_image": "Thailand.png"},
    {"start": 0x888000, "end": 0x88FFFF, "country": "Viet Nam", "flag_image": "Vietnam.png"},
    {"start": 0x890000, "end": 0x890FFF, "country": "Yemen", "flag_image": "Yemen.png"},
    {"start": 0x894000, "end": 0x894FFF, "country": "Bahrain", "flag_image": "Bahrain.png"},
    {"start": 0x895000, "end": 0x8953FF, "country": "Brunei", "flag_image": "Brunei.png"},
    {"start": 0x896000, "end": 0x896FFF, "country": "United Arab Emirates", "flag_image": "UAE.png"},
    {"start": 0x897000, "end": 0x8973FF, "country": "Solomon Islands", "flag_image": "Soloman_Islands.png"},  # flag typo?
    {"start": 0x898000, "end": 0x898FFF, "country": "Papua New Guinea", "flag_image": "Papua_New_Guinea.png"},
    {"start": 0x899000, "end": 0x8993FF, "country": "Taiwan", "flag_image": "Taiwan.png"},
    {"start": 0x8A0000, "end": 0x8A7FFF, "country": "Indonesia", "flag_image": "Indonesia.png"},
    {"start": 0x900000, "end": 0x9003FF, "country": "Marshall Islands", "flag_image": "Marshall_Islands.png"},
    {"start": 0x901000, "end": 0x9013FF, "country": "Cook Islands", "flag_image": "Cook_Islands.png"},
    {"start": 0x902000, "end": 0x9023FF, "country": "Samoa", "flag_image": "Samoa.png"},
    {"start": 0xA00000, "end": 0xAFFFFF, "country": "United States", "flag_image": "United_States_of_America.png"},
    {"start": 0xC00000, "end": 0xC3FFFF, "country": "Canada", "flag_image": "Canada.png"},
    {"start": 0xC80000, "end": 0xC87FFF, "country": "New Zealand", "flag_image": "New_Zealand.png"},
    {"start": 0xC88000, "end": 0xC88FFF, "country": "Fiji", "flag_image": "Fiji.png"},
    {"start": 0xC8A000, "end": 0xC8A3FF, "country": "Nauru", "flag_image": "Nauru.png"},
    {"start": 0xC8C000, "end": 0xC8C3FF, "country": "Saint Lucia", "flag_image": "Saint_Lucia.png"},
    {"start": 0xC8D000, "end": 0xC8D3FF, "country": "Tonga", "flag_image": "Tonga.png"},
    {"start": 0xC8E000, "end": 0xC8E3FF, "country": "Kiribati", "flag_image": "Kiribati.png"},
    {"start": 0xC90000, "end": 0xC903FF, "country": "Vanuatu", "flag_image": "Vanuatu.png"},
    {"start": 0xE00000, "end": 0xE3FFFF, "country": "Argentina", "flag_image": "Argentina.png"},
    {"start": 0xE40000, "end": 0xE7FFFF, "country": "Brazil", "flag_image": "Brazil.png"},
    {"start": 0xE80000, "end": 0xE80FFF, "country": "Chile", "flag_image": "Chile.png"},
    {"start": 0xE84000, "end": 0xE84FFF, "country": "Ecuador", "flag_image": "Ecuador.png"},
    {"start": 0xE88000, "end": 0xE88FFF, "country": "Paraguay", "flag_image": "Paraguay.png"},
    {"start": 0xE8C000, "end": 0xE8CFFF, "country": "Peru", "flag_image": "Peru.png"},
    {"start": 0xE90000, "end": 0xE90FFF, "country": "Uruguay", "flag_image": "Uruguay.png"},
    {"start": 0xE94000, "end": 0xE94FFF, "country": "Bolivia", "flag_image": "Bolivia.png"},
    {"start": 0xF00000, "end": 0xF07FFF, "country": "ICAO (temporary)", "flag_image": "blank.png"},
    {"start": 0xF09000, "end": 0xF093FF, "country": "ICAO (special use)", "flag_image": "blank.png"},

    # Block assignments mentioned in Chapter 9 section 4, at the end so they are only used if
    # nothing above applies
    {"start": 0x200000, "end": 0x27FFFF, "country": "Unassigned (AFI region)", "flag_image": "blank.png"},
    {"start": 0x280000, "end": 0x28FFFF, "country": "Unassigned (SAM region)", "flag_image": "blank.png"},
    {"start": 0x500000, "end": 0x5FFFFF, "country": "Unassigned (EUR / NAT regions)", "flag_image": "blank.png"},
    {"start": 0x600000, "end": 0x67FFFF, "country": "Unassigned (MID region)", "flag_image": "blank.png"},
    {"start": 0x680000, "end": 0x6FFFFF, "country": "Unassigned (ASIA region)", "flag_image": "blank.png"},
    {"start": 0x900000, "end": 0x9FFFFF, "country": "Unassigned (NAM / PAC regions)", "flag_image": "blank.png"},
    {"start": 0xB00000, "end": 0xBFFFFF, "country": "Unassigned (reserved for future use)", "flag_image": "blank.png"},
    {"start": 0xEC0000, "end": 0xEFFFFF, "country": "Unassigned (CAR region)", "flag_image": "blank.png"},
    {"start": 0xD00000, "end": 0xDFFFFF, "country": "Unassigned (reserved for future use)", "flag_image": "blank.png"},
    {"start": 0xF00000, "end": 0xFFFFFF, "country": "Unassigned (reserved for future use)", "flag_image": "blank.png"},
]

# Get the flag from the public ADSBExachnge servers
def find_flag(icao):
    # convert hex string to actual number
    flag_icon_file = "blank.png"

    # Determine country code based on ICAO ranges (listed above)
    hex_icao = int(icao, 16)
    for icao_range in ICAO_Ranges:
        if hex_icao >= icao_range["start"] and hex_icao <= icao_range["end"]:
            flag_icon_file = icao_range["flag_image"]

    # Cache flags for a week, they don't change that often
    flag_response = http.get("%s/flags-tiny/%s" % ("https://globe.adsbexchange.com", flag_icon_file), ttl_seconds = 604800)
    if flag_response.status_code != 200:
        print("ADSB-EX request for flag icon failed with status %d" % (flag_response.status_code))

        # If we can't reach the server, return a copy of the blank flag
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89+bN/rXXPues852zzwfACAyWSDNRNYAMqUIeEeCDx8TG4eQuQIEKJHAAEAizZCFz/SMBAPh+PDwrIsAHvgABeNMLCADATZvAMByH/w/qQplcAYCEAcB0kThLCIAUAEB6jkKmAEBGAYCdmCZTAKAEAGDLY2LjAFAtAGAnf+bTAICd+Jl7AQBblCEVAaCRACATZYhEAGg7AKzPVopFAFgwABRmS8Q5ANgtADBJV2ZIALC3AMDOEAuyAAgMADBRiIUpAAR7AGDIIyN4AISZABRG8lc88SuuEOcqAAB4mbI8uSQ5RYFbCC1xB1dXLh4ozkkXKxQ2YQJhmkAuwnmZGTKBNA/g88wAAKCRFRHgg/P9eM4Ors7ONo62Dl8t6r8G/yJiYuP+5c+rcEAAAOF0ftH+LC+zGoA7BoBt/qIl7gRoXgugdfeLZrIPQLUAoOnaV/Nw+H48PEWhkLnZ2eXk5NhKxEJbYcpXff5nwl/AV/1s+X48/Pf14L7iJIEyXYFHBPjgwsz0TKUcz5IJhGLc5o9H/LcL//wd0yLESWK5WCoU41EScY5EmozzMqUiiUKSKcUl0v9k4t8s+wM+3zUAsGo+AXuRLahdYwP2SycQWHTA4vcAAPK7b8HUKAgDgGiD4c93/+8//UegJQCAZkmScQAAXkQkLlTKsz/HCAAARKCBKrBBG/TBGCzABhzBBdzBC/xgNoRCJMTCQhBCCmSAHHJgKayCQiiGzbAdKmAv1EAdNMBRaIaTcA4uwlW4Dj1wD/phCJ7BKLyBCQRByAgTYSHaiAFiilgjjggXmYX4IcFIBBKLJCDJiBRRIkuRNUgxUopUIFVIHfI9cgI5h1xGupE7yAAygvyGvEcxlIGyUT3UDLVDuag3GoRGogvQZHQxmo8WoJvQcrQaPYw2oefQq2gP2o8+Q8cwwOgYBzPEbDAuxsNCsTgsCZNjy7EirAyrxhqwVqwDu4n1Y8+xdwQSgUXACTYEd0IgYR5BSFhMWE7YSKggHCQ0EdoJNwkDhFHCJyKTqEu0JroR+cQYYjIxh1hILCPWEo8TLxB7iEPENyQSiUMyJ7mQAkmxpFTSEtJG0m5SI+ksqZs0SBojk8naZGuyBzmULCAryIXkneTD5DPkG+Qh8lsKnWJAcaT4U+IoUspqShnlEOU05QZlmDJBVaOaUt2ooVQRNY9aQq2htlKvUYeoEzR1mjnNgxZJS6WtopXTGmgXaPdpr+h0uhHdlR5Ol9BX0svpR+iX6AP0dwwNhhWDx4hnKBmbGAcYZxl3GK+YTKYZ04sZx1QwNzHrmOeZD5lvVVgqtip8FZHKCpVKlSaVGyovVKmqpqreqgtV81XLVI+pXlN9rkZVM1PjqQnUlqtVqp1Q61MbU2epO6iHqmeob1Q/pH5Z/YkGWcNMw09DpFGgsV/jvMYgC2MZs3gsIWsNq4Z1gTXEJrHN2Xx2KruY/R27iz2qqaE5QzNKM1ezUvOUZj8H45hx+Jx0TgnnKKeX836K3hTvKeIpG6Y0TLkxZVxrqpaXllirSKtRq0frvTau7aedpr1Fu1n7gQ5Bx0onXCdHZ4/OBZ3nU9lT3acKpxZNPTr1ri6qa6UbobtEd79up+6Ynr5egJ5Mb6feeb3n+hx9L/1U/W36p/VHDFgGswwkBtsMzhg8xTVxbzwdL8fb8VFDXcNAQ6VhlWGX4YSRudE8o9VGjUYPjGnGXOMk423GbcajJgYmISZLTepN7ppSTbmmKaY7TDtMx83MzaLN1pk1mz0x1zLnm+eb15vft2BaeFostqi2uGVJsuRaplnutrxuhVo5WaVYVVpds0atna0l1rutu6cRp7lOk06rntZnw7Dxtsm2qbcZsOXYBtuutm22fWFnYhdnt8Wuw+6TvZN9un2N/T0HDYfZDqsdWh1+c7RyFDpWOt6azpzuP33F9JbpL2dYzxDP2DPjthPLKcRpnVOb00dnF2e5c4PziIuJS4LLLpc+Lpsbxt3IveRKdPVxXeF60vWdm7Obwu2o26/uNu5p7ofcn8w0nymeWTNz0MPIQ+BR5dE/C5+VMGvfrH5PQ0+BZ7XnIy9jL5FXrdewt6V3qvdh7xc+9j5yn+M+4zw33jLeWV/MN8C3yLfLT8Nvnl+F30N/I/9k/3r/0QCngCUBZwOJgUGBWwL7+Hp8Ib+OPzrbZfay2e1BjKC5QRVBj4KtguXBrSFoyOyQrSH355jOkc5pDoVQfujW0Adh5mGLw34MJ4WHhVeGP45wiFga0TGXNXfR3ENz30T6RJZE3ptnMU85ry1KNSo+qi5qPNo3ujS6P8YuZlnM1VidWElsSxw5LiquNm5svt/87fOH4p3iC+N7F5gvyF1weaHOwvSFpxapLhIsOpZATIhOOJTwQRAqqBaMJfITdyWOCnnCHcJnIi/RNtGI2ENcKh5O8kgqTXqS7JG8NXkkxTOlLOW5hCepkLxMDUzdmzqeFpp2IG0yPTq9MYOSkZBxQqohTZO2Z+pn5mZ2y6xlhbL+xW6Lty8elQfJa7OQrAVZLQq2QqboVFoo1yoHsmdlV2a/zYnKOZarnivN7cyzytuQN5zvn//tEsIS4ZK2pYZLVy0dWOa9rGo5sjxxedsK4xUFK4ZWBqw8uIq2Km3VT6vtV5eufr0mek1rgV7ByoLBtQFr6wtVCuWFfevc1+1dT1gvWd+1YfqGnRs+FYmKrhTbF5cVf9go3HjlG4dvyr+Z3JS0qavEuWTPZtJm6ebeLZ5bDpaql+aXDm4N2dq0Dd9WtO319kXbL5fNKNu7g7ZDuaO/PLi8ZafJzs07P1SkVPRU+lQ27tLdtWHX+G7R7ht7vPY07NXbW7z3/T7JvttVAVVN1WbVZftJ+7P3P66Jqun4lvttXa1ObXHtxwPSA/0HIw6217nU1R3SPVRSj9Yr60cOxx++/p3vdy0NNg1VjZzG4iNwRHnk6fcJ3/ceDTradox7rOEH0x92HWcdL2pCmvKaRptTmvtbYlu6T8w+0dbq3nr8R9sfD5w0PFl5SvNUyWna6YLTk2fyz4ydlZ19fi753GDborZ752PO32oPb++6EHTh0kX/i+c7vDvOXPK4dPKy2+UTV7hXmq86X23qdOo8/pPTT8e7nLuarrlca7nuer21e2b36RueN87d9L158Rb/1tWeOT3dvfN6b/fF9/XfFt1+cif9zsu72Xcn7q28T7xf9EDtQdlD3YfVP1v+3Njv3H9qwHeg89HcR/cGhYPP/pH1jw9DBY+Zj8uGDYbrnjg+OTniP3L96fynQ89kzyaeF/6i/suuFxYvfvjV69fO0ZjRoZfyl5O/bXyl/erA6xmv28bCxh6+yXgzMV70VvvtwXfcdx3vo98PT+R8IH8o/2j5sfVT0Kf7kxmTk/8EA5jz/GMzLdsAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAAACNJREFUeNpi/P//PwM1ARMDlcGogaMGjho4IAYCAAAA//8DAH75AxfMJfXIAAAAAElFTkSuQmCC")
    return flag_response.body()

# Get our database version
def get_db_version(tar_url):
    response = http.get(tar_url + "/version.json", ttl_seconds = 1800)
    if response.status_code != 200:
        print("Failed to get database version, throwing error.")
        return None
    return response.json()["databaseVersion"]

# Aircraft descriptions
def lookup_aircraft_desc(tar_url, aircraft_data, db_version):
    response = http.get("%s/db-%s/%s.js" % (tar_url, db_version, "icao_aircraft_types"), ttl_seconds = 86400)
    if response.status_code != 200:
        print("Couldn't get aircraft types file, throwing error")
        return None
    aircraft_types = response.json()

    typeDesignator = aircraft_data[1].upper()
    if typeDesignator in aircraft_types:
        return aircraft_types[typeDesignator]["desc"]
    else:
        return None

# We grab the icao aircraft info via nested API calls
# Caching all files as needed for 24 hours, again database keyed
def lookup_db(tar_url, icao, level, db_version):
    icao = icao.upper()
    bkey = icao[0:level]
    dkey = icao[level:]

    response = http.get("%s/db-%s/%s.js" % (tar_url, db_version, bkey), ttl_seconds = 86400)
    if response.status_code != 200:
        print("Cannot get aircraft DB file " + bkey + " throwing error")
        return None
    aircraft_db = response.json()

    if dkey in aircraft_db:
        return aircraft_db[dkey]
    elif "children" in aircraft_db:
        return lookup_db(tar_url, icao, level + 1, db_version)
    else:
        return None

# Sort alg for aircraft by distance
def aircraft_distance_sort(aircraft):
    if "r_dst" in aircraft:
        return aircraft["r_dst"]
    else:
        # If we don't have dst return arbitrary high number
        return 10000

# Return nearest aircraft to station
def find_nearest_aircraft(aircrafts):
    return sorted(aircrafts, key = aircraft_distance_sort)[0]

# Handling some results not having callsigns
def get_callsign(aircraft):
    if "flight" in aircraft:
        return aircraft["flight"]
    else:
        return "None"

# Get the aircraft icon, this hits a public API that maps the aircraft info
# to a PNG icon that the color is alt based
def get_aircraft_icon(category, designator, description, addrtype, color):
    aircraft_icon_response = http.get("https://tar1090tidbyt.azurewebsites.net/api/aircraft_icon?category=%s&typeDesignator=%s&typeDescription=%s&addrtype=%s&color=%s" % (category, designator, description, addrtype, color), ttl_seconds = 86400)
    if aircraft_icon_response.status_code != 200:
        fail("tar1090 request failed with status %d" % (aircraft_icon_response.status_code))
    aircraft_icon = aircraft_icon_response.body()
    return aircraft_icon

# Determine the color of the icon based on altitude of the aircraft
def get_altitude_icon_color(altitude):
    if altitude == "ground":
        altitude = 0
    if altitude <= 1000:
        color = "EF6913"
    elif altitude > 1000 and altitude <= 2000:
        color = "F07819"
    elif altitude > 2000 and altitude <= 4000:
        color = "F19820"
    elif altitude > 4000 and altitude <= 6000:
        color = "E9B714"
    elif altitude > 6000 and altitude <= 8000:
        color = "C2C50E"
    elif altitude > 8000 and altitude <= 10000:
        color = "61C70D"
    elif altitude > 10000 and altitude <= 20000:
        color = "20C231"
    elif altitude > 20000 and altitude <= 30000:
        color = "0FB5bE"
    elif altitude > 30000 and altitude <= 40000:
        color = "3C3dEF"
    else:
        color = "CC0DCE"
    return color

# Conversion of our units to different types, everything starts in aeronautical units
def convert_alt(unit, value):
    if unit == "a":
        return value
    elif unit == "i":
        return value
    elif unit == "m":
        return value * FEET_TO_METERS_RATIO
    else:
        return None

def convert_spd(unit, value):
    if unit == "a":
        return value
    elif unit == "i":
        return value * NMI_TO_MI_RATIO
    elif unit == "m":
        return value * NMI_TO_KM_RATIO
    else:
        return None

def convert_dst(unit, value):
    if unit == "a":
        return value
    elif unit == "i":
        return value * NMI_TO_MI_RATIO
    elif unit == "m":
        return value * NMI_TO_KM_RATIO
    else:
        return None

# Our error display routine, spiced it up to be a bit more fun
def unable_to_reach_tar_error(tar_url):
    return render.Root(
        child = render.Column(
            children = [
                render.Image(
                    src = base64.decode("R0lGODlhQAAZAIABAP8BAf///yH/C05FVFNDQVBFMi4wAwEAAAAh/wtYTVAgRGF0YVhNUDw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMC1jMDAwIDc5LjE3MWMyN2ZhYiwgMjAyMi8wOC8xNi0yMjozNTo0MSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI0LjEgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkQ0NUI3NjRBOURBRTExRUQ4MEEwQTk2MDdGOEJGRjgxIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkQ0NUI3NjRCOURBRTExRUQ4MEEwQTk2MDdGOEJGRjgxIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RDQ1Qjc2NDg5REFFMTFFRDgwQTBBOTYwN0Y4QkZGODEiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RDQ1Qjc2NDk5REFFMTFFRDgwQTBBOTYwN0Y4QkZGODEiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B//79/Pv6+fj39vX08/Lx8O/u7ezr6uno5+bl5OPi4eDf3t3c29rZ2NfW1dTT0tHQz87NzMvKycjHxsXEw8LBwL++vby7urm4t7a1tLOysbCvrq2sq6qpqKempaSjoqGgn56dnJuamZiXlpWUk5KRkI+OjYyLiomIh4aFhIOCgYB/fn18e3p5eHd2dXRzcnFwb25tbGtqaWhnZmVkY2JhYF9eXVxbWllYV1ZVVFNSUVBPTk1MS0pJSEdGRURDQkFAPz49PDs6OTg3NjU0MzIxMC8uLSwrKikoJyYlJCMiISAfHh0cGxoZGBcWFRQTEhEQDw4NDAsKCQgHBgUEAwIBAAAh+QQJFAABACwAAAAAQAAZAAACQoyPqcvtD6OctNqLs968+78B4JgAJomaIjqqbLcG7huuM42p+o1T+967nGTDoCXGMwqLymWseWRCK8+p9YrNarfaAgAh+QQJFAABACwAAAAAQAAZAAACQ4yPqcvtD6OctNqLs968+w8qQEgewFmS55iCa8uxwQtr6HzX18rTOtXr/Sw33xBoyh13ymXF6AQ2oxMZ9YrNardcUgEAIfkECRQAAQAsAAAAAEAAGQAAAkKMj6nL7Q+jnLTai7PevPsPVkBIHsBZkueYgmvLscELa+h819fK0zrV6/0sN98QaModd8qlqOmcGKNIqvWKzWq3mQIAIfkECRQAAQAsAAAAAEAAGQAAAkGMj6nL7Q+jnLTai7PevPsPhg0glgGAmiFKqh/rbu2ZxlkN2xfL5/rU6/0quNqQMvMdLcol0uh8zqJIqvWKzWqpBQAh+QQFFAABACwAAAAAQAAZAAACQoyPqcvtD6OctNqLs968+w+GDiCWAYCaIUqqH+tu7ZnGWQ3P9sT28E7x9YAWXI0YPPyQlyWz4nzyjtJk9YrNarfPAgA7"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text("!!! CAN'T REACH TAR1090 @ " + tar_url + " !!!"),
                    scroll_direction = "horizontal",
                ),
            ],
        ),
    )

def validate_url(url):
    url_regex = "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*(),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"
    url_search = re.findall(url_regex, url)
    if len(url_search) > 0:
        return True
    else:
        return False

def main(config):
    tar_url = config.str("tar1090url", TAR1090_URL_DEFAULT)

    if tar_url == TAR1090_URL_DEFAULT:
        return unable_to_reach_tar_error(tar_url)

    if validate_url(tar_url) == False:
        return unable_to_reach_tar_error(tar_url)

    db_version = get_db_version(tar_url)
    if db_version == None:
        return unable_to_reach_tar_error(tar_url)

    conversion_unit = config.str("units", DEFAULT_CONVERSION_UNITS)

    response = http.get(tar_url + "/data/aircraft.json")
    if response.status_code != 200:
        return unable_to_reach_tar_error(tar_url)

    aircrafts = response.json()["aircraft"]

    aircraft = find_nearest_aircraft(aircrafts)

    flag = find_flag(aircraft["hex"])

    # This is the first "version dependant" call
    aircraft_data = lookup_db(tar_url, aircraft["hex"], 1, db_version)
    if aircraft_data == None:
        return unable_to_reach_tar_error(tar_url)

    aircraft_desc = lookup_aircraft_desc(tar_url, aircraft_data, db_version)
    if aircraft_desc == None:
        return unable_to_reach_tar_error(tar_url)

    aircraft_icon = get_aircraft_icon(
        aircraft["category"],
        aircraft_data[1],
        aircraft_desc,
        aircraft["type"],
        get_altitude_icon_color(aircraft["alt_baro"]),
    )

    animation_frames = list()
    frame1 = list()
    frame2 = list()

    frame1.append(
        render.Row(
            children = [
                render.Image(src = flag),
                render.Box(
                    height = 12,
                    width = 45,
                    child = render.Column(
                        children = [
                            render.Text(content = "CALLSIGN", font = "CG-pixel-4x5-mono"),
                            render.Text(content = get_callsign(aircraft).strip().upper()),
                        ],
                        cross_align = "center",
                    ),
                ),
            ],
            main_align = "space_around",
            expanded = True,
        ),
    )

    frame1.append(
        render.Row(
            children = [
                render.Box(
                    child = render.Text(content = "Alt: %d" % (convert_alt(conversion_unit, aircraft["alt_baro"]))),
                    height = 10,
                ),
            ],
            main_align = "space_around",
            expanded = True,
        ),
    )

    frame1.append(
        render.Row(
            children = [
                render.Box(
                    child = render.Text(content = "Sp: %d Dst: %d" % (convert_spd(conversion_unit, aircraft["gs"]), convert_dst(conversion_unit, aircraft["r_dst"]))),
                ),
            ],
            main_align = "space_around",
            expanded = True,
        ),
    )

    frame2.append(
        render.Row(
            children = [
                render.Image(src = aircraft_icon, height = 18),
                render.Box(
                    height = 18,
                    padding = 1,
                    child = render.Column(
                        children = [
                            render.Text(content = "ICAO HEX", font = "CG-pixel-4x5-mono"),
                            render.Text(content = aircraft["hex"].upper()),
                        ],
                        cross_align = "center",
                    ),
                ),
            ],
            expanded = True,
        ),
    )

    aircraft_long_name = ""
    if aircraft_data[3] != None:
        aircraft_long_name = aircraft_data[3]
    else:
        aircraft_long_name = "No Description"

    frame2.append(
        render.Row(
            children = [
                render.Box(
                    child = render.WrappedText(
                        content = aircraft_long_name,
                        height = 12,
                        align = "center",
                        font = "tom-thumb",
                    ),
                ),
            ],
        ),
    )

    animation_frames.append(
        render.Column(
            children = frame1,
            cross_align = "center",
        ),
    )
    animation_frames.append(
        render.Column(
            children = frame2,
            cross_align = "center",
        ),
    )

    return render.Root(
        delay = 5000,
        child = render.Animation(children = animation_frames),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Aeronautical",
            value = "a",
        ),
        schema.Option(
            display = "Metric",
            value = "m",
        ),
        schema.Option(
            display = "Imperial",
            value = "i",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "tar1090url",
                name = "tar1090 Url",
                desc = "Your self hosted, publically availble tar1090 instance to use as an ADS-B data source.",
                icon = "plane",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Unit type measurements will be displayed in.",
                icon = "brush",
                default = options[0].value,
                options = options,
            ),
        ],
    )
