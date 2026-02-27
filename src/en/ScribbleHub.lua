-- {"id":86802,"ver":"1.3.1","libVer":"1.0.0","author":"TechnoJo4, StormX4 (updated by lev616)","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring

local css = Require("CommonCSS").table

local HTMLToString = Require("unhtml").HTMLToString

local function shrinkURL(url)
	return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local FILTER_GENRE_MODE = 5

local FILTER_SORT = 6
local FILTER_ORDER = 7

local FILTER_STATUS = 8
local FILTER_CW_MODE = 10

local FILTER_TAG_INCLUDE = 40
local FILTER_TAG_EXCLUDE = 41
local FILTER_TAG_MODE    = 42

local SORT_VALUES = {
    "pageviews",
    "frequency",
    "dateadded",
    "favorites",
    "lastchpdate",
    "numofrate",
    "pages",
    "chapters",
    "ratings",
    "readers",
    "reviews",
    "totalwords"
}


local FILTER_GENRE_ACTION        = 100
local FILTER_GENRE_ADULT         = 101
local FILTER_GENRE_ADVENTURE     = 102
local FILTER_GENRE_BOYS_LOVE     = 103
local FILTER_GENRE_COMEDY        = 104
local FILTER_GENRE_DRAMA         = 105
local FILTER_GENRE_ECCHI         = 106
local FILTER_GENRE_FANFICTION    = 107
local FILTER_GENRE_FANTASY       = 108
local FILTER_GENRE_GENDER_BENDER = 109
local FILTER_GENRE_GIRLS_LOVE    = 110
local FILTER_GENRE_HAREM         = 111
local FILTER_GENRE_HISTORICAL    = 112
local FILTER_GENRE_HORROR        = 113
local FILTER_GENRE_ISEKAI        = 114
local FILTER_GENRE_JOSEI         = 115
local FILTER_GENRE_LITRPG        = 116
local FILTER_GENRE_MARTIAL_ARTS  = 117
local FILTER_GENRE_MATURE        = 118
local FILTER_GENRE_MECHA         = 119
local FILTER_GENRE_MYSTERY       = 120
local FILTER_GENRE_PSYCHOLOGICAL = 121
local FILTER_GENRE_ROMANCE       = 122
local FILTER_GENRE_SCHOOL_LIFE   = 123
local FILTER_GENRE_SCI_FI        = 124
local FILTER_GENRE_SEINEN        = 125
local FILTER_GENRE_SLICE_OF_LIFE = 126
local FILTER_GENRE_SMUT          = 127
local FILTER_GENRE_SPORTS        = 128
local FILTER_GENRE_SUPERNATURAL  = 129
local FILTER_GENRE_TRAGEDY       = 130


local FILTER_CW_GORE       = 901
local FILTER_CW_SEXUAL_CONTENT         = 902
local FILTER_CW_STRONG_LANGUAGE = 903

local CW_FILTERS = {
        { cwId = FILTER_CW_GORE,        cti = "48"    }, -- Action
        { cwId = FILTER_CW_SEXUAL_CONTENT,         cti = "50"  }, -- Adult
        { cwId = FILTER_CW_STRONG_LANGUAGE,     cti = "49"    }, -- Adventure
    }

local GENRE_FILTERS = {
        { filterId = FILTER_GENRE_ACTION,        gi = "9"    }, -- Action
        { filterId = FILTER_GENRE_ADULT,         gi = "902"  }, -- Adult
        { filterId = FILTER_GENRE_ADVENTURE,     gi = "8"    }, -- Adventure
        { filterId = FILTER_GENRE_BOYS_LOVE,     gi = "891"  }, -- Boys Love
        { filterId = FILTER_GENRE_COMEDY,        gi = "7"    }, -- Comedy
        { filterId = FILTER_GENRE_DRAMA,         gi = "903"  }, -- Drama
        { filterId = FILTER_GENRE_ECCHI,         gi = "904"  }, -- Ecchi
        { filterId = FILTER_GENRE_FANFICTION,    gi = "38"   }, -- Fanfiction
        { filterId = FILTER_GENRE_FANTASY,       gi = "19"   }, -- Fantasy
        { filterId = FILTER_GENRE_GENDER_BENDER, gi = "905"  }, -- Gender Bender
        { filterId = FILTER_GENRE_GIRLS_LOVE,    gi = "892"  }, -- Girls Love
        { filterId = FILTER_GENRE_HAREM,         gi = "1015" }, -- Harem
        { filterId = FILTER_GENRE_HISTORICAL,    gi = "21"   }, -- Historical
        { filterId = FILTER_GENRE_HORROR,        gi = "22"   }, -- Horror
        { filterId = FILTER_GENRE_ISEKAI,        gi = "37"   }, -- Isekai
        { filterId = FILTER_GENRE_JOSEI,         gi = "906"  }, -- Josei
        { filterId = FILTER_GENRE_LITRPG,        gi = "1180" }, -- LitRPG
        { filterId = FILTER_GENRE_MARTIAL_ARTS,  gi = "907"  }, -- Martial Arts
        { filterId = FILTER_GENRE_MATURE,        gi = "20"   }, -- Mature
        { filterId = FILTER_GENRE_MECHA,         gi = "908"  }, -- Mecha
        { filterId = FILTER_GENRE_MYSTERY,       gi = "909"  }, -- Mystery
        { filterId = FILTER_GENRE_PSYCHOLOGICAL, gi = "910"  }, -- Psychological
        { filterId = FILTER_GENRE_ROMANCE,       gi = "6"    }, -- Romance
        { filterId = FILTER_GENRE_SCHOOL_LIFE,   gi = "911"  }, -- School Life
        { filterId = FILTER_GENRE_SCI_FI,        gi = "912"  }, -- Sci-fi
        { filterId = FILTER_GENRE_SEINEN,        gi = "913"  }, -- Seinen
        { filterId = FILTER_GENRE_SLICE_OF_LIFE, gi = "914"  }, -- Slice of Life
        { filterId = FILTER_GENRE_SMUT,          gi = "915"  }, -- Smut
        { filterId = FILTER_GENRE_SPORTS,        gi = "916"  }, -- Sports
        { filterId = FILTER_GENRE_SUPERNATURAL,  gi = "5"    }, -- Supernatural
        { filterId = FILTER_GENRE_TRAGEDY,       gi = "901"  }  -- Tragedy
    }

local TAG_MAP = {
    ["abandoned children"] = "119",
    ["ability steal"] = "120",
    ["absent parents"] = "121",
    ["abusive characters"] = "122",
    ["academy"] = "123",
    ["accelerated growth"] = "124",
    ["acting"] = "125",
    ["adopted children"] = "137",
    ["adopted protagonist"] = "138",
    ["adultery"] = "139",
    ["adventurers"] = "140",
    ["affair"] = "141",
    ["age progression"] = "142",
    ["age regression"] = "143",
    ["aggressive characters"] = "144",
    ["alchemy"] = "145",
    ["aliens"] = "146",
    ["all-girls school"] = "147",
    ["alternate world"] = "148",
    ["amnesia"] = "149",
    ["amusement park"] = "150",
    ["ancient china"] = "152",
    ["ancient times"] = "153",
    ["androgynous characters"] = "154",
    ["androids"] = "155",
    ["angels"] = "156",
    ["animal characteristics"] = "157",
    ["animal rearing"] = "158",
    ["anti-magic"] = "159",
    ["anti-social protagonist"] = "160",
    ["antihero protagonist"] = "161",
    ["antique shop"] = "162",
    ["apartment life"] = "163",
    ["apathetic protagonist"] = "164",
    ["apocalypse"] = "165",
    ["appearance changes"] = "166",
    ["appearance different from actual age"] = "167",
    ["archery"] = "168",
    ["aristocracy"] = "169",
    ["arms dealers"] = "170",
    ["army"] = "171",
    ["army building"] = "172",
    ["arranged marriage"] = "173",
    ["arrogant characters"] = "174",
    ["artifact crafting"] = "175",
    ["artifacts"] = "176",
    ["artificial intelligence"] = "177",
    ["artists"] = "178",
    ["assassins"] = "179",
    ["astrologers"] = "180",
    ["autism"] = "181",
    ["automatons"] = "182",
    ["average-looking protagonist"] = "183",
    ["awkward protagonist"] = "185",
    ["bands"] = "186",
    ["based on a movie"] = "187",
    ["based on a song"] = "188",
    ["based on a video game"] = "190",
    ["based on a visual novel"] = "191",
    ["based on an anime"] = "192",
    ["battle academy"] = "193",
    ["battle competition"] = "194",
    ["bdsm"] = "195",
    ["beast companions"] = "196",
    ["beastkin"] = "197",
    ["beasts"] = "198",
    ["beautiful couple"] = "199",
    ["beautiful female lead"] = "200",
    ["betrayal"] = "202",
    ["bickering couple"] = "203",
    ["biochip"] = "204",
    ["biography"] = "205",
    ["bisexual protagonist"] = "206",
    ["black belly"] = "207",
    ["blackmail"] = "208",
    ["blacksmith"] = "209",
    ["blind dates"] = "210",
    ["blind protagonist"] = "211",
    ["blood manipulation"] = "212",
    ["bloodlines"] = "213",
    ["body swap"] = "214",
    ["body tempering"] = "215",
    ["body-double"] = "216",
    ["bodyguards"] = "217",
    ["books"] = "218",
    ["bookworm"] = "219",
    ["boss-subordinate relationship"] = "220",
    ["boy's love subplot"] = "760",
    ["brainwashing"] = "221",
    ["broken engagement"] = "223",
    ["brother complex"] = "224",
    ["brotherhood"] = "225",
    ["buddhism"] = "226",
    ["bullying"] = "227",
    ["business management"] = "228",
    ["businessmen"] = "229",
    ["butlers"] = "230",
    ["calm protagonist"] = "231",
    ["cannibalism"] = "232",
    ["card games"] = "233",
    ["carefree protagonist"] = "234",
    ["caring protagonist"] = "235",
    ["cautious protagonist"] = "236",
    ["celebrities"] = "237",
    ["character growth"] = "238",
    ["charismatic protagonist"] = "239",
    ["charming protagonist"] = "240",
    ["chat rooms"] = "241",
    ["cheating"] = "20892",
    ["cheats"] = "242",
    ["chefs"] = "243",
    ["child abuse"] = "244",
    ["child protagonist"] = "245",
    ["childcare"] = "246",
    ["childhood friends"] = "247",
    ["childhood love"] = "248",
    ["childhood promise"] = "249",
    ["childish protagonist"] = "250",
    ["chuunibyou"] = "251",
    ["clan building"] = "252",
    ["classic"] = "253",
    ["clever protagonist"] = "254",
    ["clingy lover"] = "255",
    ["clones"] = "256",
    ["clubs"] = "257",
    ["clumsy love interests"] = "258",
    ["co-workers"] = "259",
    ["cohabitation"] = "260",
    ["cold love interests"] = "261",
    ["cold protagonist"] = "262",
    ["collection of short stories"] = "263",
    ["college/university"] = "264",
    ["coma"] = "265",
    ["comedic undertone"] = "266",
    ["coming of age"] = "267",
    ["complex family relationships"] = "268",
    ["conditional power"] = "269",
    ["confident protagonist"] = "270",
    ["confinement"] = "271",
    ["conflicting loyalties"] = "272",
    ["conspiracies"] = "273",
    ["contracts"] = "274",
    ["cooking"] = "275",
    ["corruption"] = "276",
    ["cosmic wars"] = "277",
    ["cosplay"] = "278",
    ["couple growth"] = "279",
    ["court official"] = "280",
    ["cousins"] = "281",
    ["cowardly protagonist"] = "282",
    ["crafting"] = "283",
    ["crazy protagonist"] = "1534",
    ["crime"] = "284",
    ["criminals"] = "285",
    ["cross-dressing"] = "286",
    ["crossover"] = "287",
    ["cruel characters"] = "288",
    ["cryostasis"] = "289",
    ["cultivation"] = "290",
    ["cunning protagonist"] = "292",
    ["curious protagonist"] = "293",
    ["curses"] = "294",
    ["cute children"] = "295",
    ["cute protagonist"] = "296",
    ["cute story"] = "297",
    ["cyberpunk"] = "960",
    ["dancers"] = "298",
    ["dao companion"] = "299",
    ["dao comprehension"] = "300",
    ["daoism"] = "301",
    ["dark"] = "302",
    ["dead protagonist"] = "303",
    ["death"] = "304",
    ["death of loved ones"] = "305",
    ["debts"] = "306",
    ["delinquents"] = "307",
    ["delusions"] = "308",
    ["demi-humans"] = "309",
    ["demon lord"] = "310",
    ["demonic cultivation technique"] = "311",
    ["demons"] = "312",
    ["dense protagonist"] = "313",
    ["depictions of cruelty"] = "314",
    ["depression"] = "315",
    ["destiny"] = "316",
    ["detectives"] = "317",
    ["determined protagonist"] = "318",
    ["devoted love interests"] = "319",
    ["different social status"] = "320",
    ["disabilities"] = "321",
    ["discrimination"] = "322",
    ["disfigurement"] = "323",
    ["dishonest protagonist"] = "324",
    ["distrustful protagonist"] = "325",
    ["divination"] = "326",
    ["divine protection"] = "327",
    ["divorce"] = "328",
    ["doctors"] = "329",
    ["dolls/puppets"] = "330",
    ["domestic affairs"] = "331",
    ["doting love interests"] = "332",
    ["doting older siblings"] = "333",
    ["doting parents"] = "334",
    ["dragon riders"] = "335",
    ["dragon slayers"] = "336",
    ["dragons"] = "337",
    ["dreams"] = "338",
    ["drugs"] = "339",
    ["druids"] = "340",
    ["dungeon master"] = "341",
    ["dungeons"] = "342",
    ["dwarfs"] = "343",
    ["dystopia"] = "344",
    ["e-sports"] = "345",
    ["early romance"] = "346",
    ["earth invasion"] = "347",
    ["easy going life"] = "348",
    ["economics"] = "349",
    ["editors"] = "350",
    ["eidetic memory"] = "351",
    ["elderly protagonist"] = "352",
    ["elemental magic"] = "353",
    ["elves"] = "354",
    ["emotionally weak protagonist"] = "355",
    ["empires"] = "356",
    ["enemies become allies"] = "357",
    ["enemies become lovers"] = "358",
    ["engagement"] = "359",
    ["engineer"] = "360",
    ["enlightenment"] = "361",
    ["episodic"] = "362",
    ["eunuch"] = "363",
    ["european ambience"] = "364",
    ["evil gods"] = "365",
    ["evil organizations"] = "366",
    ["evil protagonist"] = "367",
    ["evil religions"] = "368",
    ["evolution"] = "369",
    ["exhibitionism"] = "370",
    ["exorcism"] = "371",
    ["eye powers"] = "372",
    ["fairies"] = "373",
    ["fallen angels"] = "374",
    ["fallen nobility"] = "375",
    ["familial love"] = "376",
    ["familiars"] = "377",
    ["family"] = "378",
    ["family business"] = "379",
    ["family conflict"] = "380",
    ["famous parents"] = "381",
    ["famous protagonist"] = "382",
    ["fanaticism"] = "383",
    ["fantasy creatures"] = "385",
    ["fantasy world"] = "386",
    ["farming"] = "387",
    ["fast cultivation"] = "388",
    ["fast learner"] = "389",
    ["fat protagonist"] = "390",
    ["fat to fit"] = "391",
    ["fated lovers"] = "392",
    ["fearless protagonist"] = "393",
    ["female master"] = "395",
    ["female protagonist"] = "396",
    ["female to male"] = "397",
    ["feng shui"] = "398",
    ["firearms"] = "399",
    ["first love"] = "400",
    ["first-time intercourse"] = "401",
    ["flashbacks"] = "402",
    ["fleet battles"] = "403",
    ["folklore"] = "404",
    ["forced into a relationship"] = "405",
    ["forced living arrangements"] = "406",
    ["forced marriage"] = "407",
    ["forgetful protagonist"] = "408",
    ["former hero"] = "409",
    ["fourth wall"] = "1150",
    ["fox spirits"] = "410",
    ["friends become enemies"] = "411",
    ["friendship"] = "412",
    ["fujoshi"] = "413",
    ["futanari"] = "414",
    ["futuristic setting"] = "415",
    ["galge"] = "416",
    ["gambling"] = "417",
    ["game elements"] = "418",
    ["game ranking system"] = "419",
    ["gamers"] = "420",
    ["gangs"] = "421",
    ["gate to another world"] = "422",
    ["genderless protagonist"] = "423",
    ["generals"] = "424",
    ["genetic modifications"] = "425",
    ["genies"] = "426",
    ["genius protagonist"] = "427",
    ["ghosts"] = "428",
    ["girl's love subplot"] = "759",
    ["gladiators"] = "429",
    ["glasses-wearing love interests"] = "430",
    ["glasses-wearing protagonist"] = "431",
    ["goblins"] = "432",
    ["god protagonist"] = "433",
    ["god-human relationship"] = "434",
    ["goddesses"] = "435",
    ["godly powers"] = "436",
    ["gods"] = "437",
    ["golems"] = "438",
    ["gore"] = "439",
    ["grave keepers"] = "440",
    ["grinding"] = "441",
    ["guardian relationship"] = "442",
    ["guilds"] = "443",
    ["gunfighters"] = "444",
    ["hackers"] = "445",
    ["half-human protagonist"] = "446",
    ["handjob"] = "447",
    ["handsome male lead"] = "448",
    ["hard-working protagonist"] = "449",
    ["harem-seeking protagonist"] = "450",
    ["harsh training"] = "451",
    ["hated protagonist"] = "452",
    ["healers"] = "453",
    ["healing"] = "942",
    ["heartwarming"] = "454",
    ["heaven"] = "455",
    ["heavenly tribulation"] = "456",
    ["hell"] = "457",
    ["helpful protagonist"] = "458",
    ["herbalist"] = "459",
    ["heroes"] = "460",
    ["heterochromia"] = "461",
    ["hidden abilities"] = "462",
    ["hiding true abilities"] = "463",
    ["hiding true identity"] = "464",
    ["hikikomori"] = "465",
    ["homunculus"] = "466",
    ["honest protagonist"] = "467",
    ["hospital"] = "468",
    ["hot-blooded protagonist"] = "469",
    ["human experimentation"] = "470",
    ["human weapon"] = "471",
    ["human-nonhuman relationship"] = "472",
    ["humanoid protagonist"] = "473",
    ["hunters"] = "474",
    ["hypnotism"] = "475",
    ["identity crisis"] = "476",
    ["imaginary friend"] = "477",
    ["immortals"] = "478",
    ["imperial harem"] = "479",
    ["incest"] = "480",
    ["incubus"] = "481",
    ["indecisive protagonist"] = "482",
    ["industrialization"] = "483",
    ["inferiority complex"] = "484",
    ["inheritance"] = "485",
    ["inscriptions"] = "486",
    ["insects"] = "487",
    ["interconnected storylines"] = "488",
    ["interdimensional travel"] = "489",
    ["introverted protagonist"] = "490",
    ["investigations"] = "491",
    ["invisibility"] = "492",
    ["jack of all trades"] = "493",
    ["jealousy"] = "494",
    ["jiangshi"] = "495",
    ["jobless class"] = "496",
    ["kidnappings"] = "498",
    ["kind love interests"] = "499",
    ["kingdom building"] = "500",
    ["kingdoms"] = "501",
    ["knights"] = "502",
    ["kuudere"] = "503",
    ["lack of common sense"] = "504",
    ["language barrier"] = "505",
    ["late romance"] = "506",
    ["lawyers"] = "507",
    ["lazy protagonist"] = "508",
    ["leadership"] = "509",
    ["legends"] = "510",
    ["level system"] = "511",
    ["library"] = "512",
    ["limited lifespan"] = "513",
    ["living abroad"] = "514",
    ["living alone"] = "515",
    ["loli"] = "516",
    ["loneliness"] = "517",
    ["loner protagonist"] = "518",
    ["long separations"] = "519",
    ["long-distance relationship"] = "520",
    ["lost civilizations"] = "521",
    ["lottery"] = "522",
    ["love at first sight"] = "523",
    ["love interest falls in love first"] = "524",
    ["love rivals"] = "525",
    ["love triangles"] = "526",
    ["lovers reunited"] = "527",
    ["low-key protagonist"] = "528",
    ["loyal subordinates"] = "529",
    ["lucky protagonist"] = "530",
    ["magic"] = "531",
    ["magic beasts"] = "532",
    ["magic formations"] = "533",
    ["magical girls"] = "534",
    ["magical space"] = "535",
    ["magical technology"] = "536",
    ["maids"] = "537",
    ["male protagonist"] = "538",
    ["male to female"] = "539",
    ["male yandere"] = "540",
    ["management"] = "541",
    ["mangaka"] = "542",
    ["manipulative characters"] = "543",
    ["manly gay couple"] = "544",
    ["marriage"] = "545",
    ["marriage of convenience"] = "546",
    ["martial spirits"] = "547",
    ["masochistic characters"] = "548",
    ["master-disciple relationship"] = "549",
    ["master-servant relationship"] = "550",
    ["masturbation"] = "551",
    ["matriarchy"] = "552",
    ["mature protagonist"] = "553",
    ["medical knowledge"] = "554",
    ["medieval"] = "555",
    ["mercenaries"] = "556",
    ["merchants"] = "557",
    ["military"] = "558",
    ["mind break"] = "559",
    ["mind control"] = "560",
    ["misandry"] = "561",
    ["mismatched couple"] = "562",
    ["misunderstandings"] = "563",
    ["mmorpg"] = "564",
    ["mob protagonist"] = "565",
    ["models"] = "566",
    ["modern day"] = "567",
    ["modern fantasy"] = "1268",
    ["modern knowledge"] = "568",
    ["modern time"] = "1536",
    ["money grubber"] = "569",
    ["monster girls"] = "570",
    ["monster society"] = "571",
    ["monster tamer"] = "572",
    ["monsters"] = "573",
    ["movies"] = "574",
    ["mpreg"] = "575",
    ["multiple identities"] = "576",
    ["multiple personalities"] = "577",
    ["multiple pov"] = "578",
    ["multiple protagonists"] = "579",
    ["multiple realms"] = "580",
    ["multiple reincarnated individuals"] = "581",
    ["multiple timelines"] = "582",
    ["multiple transported individuals"] = "583",
    ["murders"] = "584",
    ["music"] = "585",
    ["mutated creatures"] = "586",
    ["mutations"] = "587",
    ["mute character"] = "588",
    ["mysterious family background"] = "589",
    ["mysterious illness"] = "590",
    ["mysterious past"] = "591",
    ["mystery solving"] = "592",
    ["mythical beasts"] = "593",
    ["mythology"] = "594",
    ["naive protagonist"] = "595",
    ["narcissistic protagonist"] = "596",
    ["nationalism"] = "597",
    ["near-death experience"] = "598",
    ["necromancer"] = "599",
    ["neet"] = "600",
    ["netorare"] = "601",
    ["netorase"] = "602",
    ["netori"] = "603",
    ["nightmares"] = "604",
    ["ninjas"] = "605",
    ["nobles"] = "606",
    ["non-human protagonist"] = "1428",
    ["non-humanoid protagonist"] = "607",
    ["non-linear storytelling"] = "608",
    ["nudity"] = "609",
    ["nurses"] = "610",
    ["obsessive love"] = "611",
    ["office romance"] = "612",
    ["older love interests"] = "613",
    ["omegaverse"] = "614",
    ["oneshot"] = "615",
    ["online romance"] = "616",
    ["onmyouji"] = "617",
    ["orcs"] = "618",
    ["organized crime"] = "619",
    ["orphans"] = "621",
    ["otaku"] = "622",
    ["otome game"] = "623",
    ["outcasts"] = "624",
    ["outdoor intercourse"] = "625",
    ["outer space"] = "626",
    ["overpowered protagonist"] = "627",
    ["overprotective siblings"] = "628",
    ["pacifist protagonist"] = "629",
    ["paizuri"] = "630",
    ["pansexual protagonist"] = "1037",
    ["parallel worlds"] = "631",
    ["parasites"] = "632",
    ["parent complex"] = "633",
    ["parody"] = "634",
    ["part-time job"] = "635",
    ["past plays a big role"] = "636",
    ["past trauma"] = "637",
    ["persistent love interests"] = "638",
    ["personality changes"] = "639",
    ["perverted protagonist"] = "640",
    ["pets"] = "641",
    ["pharmacist"] = "642",
    ["philosophical"] = "643",
    ["phobias"] = "644",
    ["phoenixes"] = "645",
    ["photography"] = "646",
    ["pill based cultivation"] = "647",
    ["pill concocting"] = "648",
    ["pilots"] = "649",
    ["pirates"] = "650",
    ["playboys"] = "651",
    ["playful protagonist"] = "652",
    ["poetry"] = "653",
    ["poisons"] = "654",
    ["police"] = "655",
    ["polite protagonist"] = "656",
    ["politics"] = "657",
    ["polyandry"] = "658",
    ["polygamy"] = "659",
    ["poor protagonist"] = "660",
    ["poor to rich"] = "661",
    ["popular love interests"] = "662",
    ["possession"] = "663",
    ["possessive characters"] = "664",
    ["post-apocalyptic"] = "665",
    ["power couple"] = "666",
    ["power struggle"] = "667",
    ["pragmatic protagonist"] = "668",
    ["precognition"] = "669",
    ["pregnancy"] = "670",
    ["pretend lovers"] = "671",
    ["previous life talent"] = "672",
    ["priestesses"] = "673",
    ["priests"] = "674",
    ["prison"] = "675",
    ["proactive protagonist"] = "676",
    ["programmer"] = "677",
    ["prophecies"] = "678",
    ["prostitutes"] = "679",
    ["protagonist falls in love first"] = "680",
    ["protagonist loyal to love interest"] = "681",
    ["protagonist strong from the start"] = "682",
    ["protagonist with multiple bodies"] = "683",
    ["psychic powers"] = "684",
    ["psychopaths"] = "685",
    ["puppeteers"] = "686",
    ["quiet characters"] = "687",
    ["quirky characters"] = "688",
    ["r-15"] = "689",
    ["r-18"] = "690",
    ["race change"] = "691",
    ["racism"] = "692",
    ["rape"] = "693",
    ["rebellion"] = "695",
    ["reincarnated as a monster"] = "696",
    ["reincarnated as an object"] = "697",
    ["reincarnated into a game world"] = "698",
    ["reincarnated into another world"] = "699",
    ["reincarnation"] = "700",
    ["religions"] = "701",
    ["reluctant protagonist"] = "702",
    ["reporters"] = "703",
    ["restaurant"] = "704",
    ["resurrection"] = "705",
    ["returning from another world"] = "706",
    ["revenge"] = "707",
    ["reverse harem"] = "708",
    ["reverse rape"] = "709",
    ["rich to poor"] = "710",
    ["righteous protagonist"] = "711",
    ["rivalry"] = "712",
    ["romantic subplot"] = "713",
    ["roommates"] = "714",
    ["royalty"] = "715",
    ["rpg"] = "1089",
    ["ruthless protagonist"] = "716",
    ["sadistic characters"] = "717",
    ["saints"] = "718",
    ["salaryman"] = "719",
    ["samurai"] = "720",
    ["satire"] = "1976",
    ["saving the world"] = "721",
    ["scheming"] = "722",
    ["schizophrenia"] = "723",
    ["scientists"] = "724",
    ["sculptors"] = "725",
    ["sealed power"] = "726",
    ["second chance"] = "727",
    ["secret crush"] = "728",
    ["secret identity"] = "729",
    ["secret organizations"] = "730",
    ["secret relationship"] = "731",
    ["secretive protagonist"] = "732",
    ["secrets"] = "733",
    ["sect development"] = "734",
    ["seduction"] = "735",
    ["seeing things other humans can't"] = "736",
    ["selfish protagonist"] = "737",
    ["selfless protagonist"] = "738",
    ["seme protagonist"] = "739",
    ["senpai-kouhai relationship"] = "740",
    ["sentient objects"] = "741",
    ["sentimental protagonist"] = "742",
    ["serial killers"] = "743",
    ["servants"] = "744",
    ["seven deadly sins"] = "745",
    ["seven virtues"] = "746",
    ["sex friends"] = "747",
    ["sexual abuse"] = "749",
    ["sexual cultivation technique"] = "750",
    ["shameless protagonist"] = "751",
    ["shapeshifters"] = "752",
    ["sharing a body"] = "753",
    ["sharp-tongued characters"] = "754",
    ["shield user"] = "755",
    ["shikigami"] = "756",
    ["short story"] = "757",
    ["shota"] = "758",
    ["showbiz"] = "761",
    ["shy characters"] = "762",
    ["sibling rivalry"] = "763",
    ["siblings"] = "765",
    ["siblings care"] = "764",
    ["siblings not related by blood"] = "766",
    ["sickly characters"] = "767",
    ["sign language"] = "768",
    ["singers"] = "769",
    ["single parent"] = "770",
    ["sister complex"] = "771",
    ["skill assimilation"] = "772",
    ["skill books"] = "773",
    ["skill creation"] = "774",
    ["slave harem"] = "775",
    ["slave protagonist"] = "776",
    ["slaves"] = "777",
    ["sleeping"] = "778",
    ["slow growth at start"] = "779",
    ["slow romance"] = "780",
    ["smart couple"] = "781",
    ["social outcasts"] = "782",
    ["soldiers"] = "783",
    ["soul power"] = "784",
    ["souls"] = "785",
    ["spatial manipulation"] = "786",
    ["spear wielder"] = "787",
    ["special abilities"] = "788",
    ["special forces"] = "497",
    ["spies"] = "789",
    ["spirit advisor"] = "790",
    ["spirit users"] = "791",
    ["spirits"] = "792",
    ["stalkers"] = "793",
    ["stockholm syndrome"] = "794",
    ["stoic characters"] = "795",
    ["store owner"] = "796",
    ["straight seme"] = "797",
    ["straight uke"] = "798",
    ["strategic battles"] = "799",
    ["strategist"] = "800",
    ["strength-based social hierarchy"] = "801",
    ["strong love interests"] = "802",
    ["strong to stronger"] = "803",
    ["stubborn protagonist"] = "804",
    ["student council"] = "805",
    ["student-teacher relationship"] = "806",
    ["subtle romance"] = "807",
    ["succubus"] = "808",
    ["sudden strength gain"] = "809",
    ["sudden wealth"] = "810",
    ["suicides"] = "811",
    ["summoned hero"] = "812",
    ["summoning magic"] = "813",
    ["superheroes"] = "44746",
    ["survival"] = "814",
    ["survival game"] = "815",
    ["sword and magic"] = "816",
    ["sword wielder"] = "817",
    ["system administrator"] = "818",
    ["teachers"] = "819",
    ["teamwork"] = "820",
    ["technological gap"] = "821",
    ["tentacles"] = "822",
    ["terminal illness"] = "823",
    ["terrorists"] = "824",
    ["thieves"] = "825",
    ["threesome"] = "826",
    ["thriller"] = "827",
    ["time loop"] = "828",
    ["time manipulation"] = "829",
    ["time paradox"] = "830",
    ["time skip"] = "831",
    ["time travel"] = "832",
    ["timid protagonist"] = "833",
    ["tomboyish female lead"] = "834",
    ["torture"] = "835",
    ["toys"] = "836",
    ["tragic past"] = "837",
    ["transformation ability"] = "838",
    ["transgender"] = "1088",
    ["transmigration"] = "839",
    ["transplanted memories"] = "840",
    ["transported into a game world"] = "841",
    ["transported into another world"] = "842",
    ["transported modern structure"] = "843",
    ["trap"] = "844",
    ["tribal society"] = "845",
    ["trickster"] = "846",
    ["trolls"] = "1071",
    ["tsundere"] = "847",
    ["twins"] = "848",
    ["twisted personality"] = "849",
    ["ugly protagonist"] = "850",
    ["ugly to beautiful"] = "851",
    ["unconditional love"] = "852",
    ["underestimated protagonist"] = "853",
    ["unique cultivation technique"] = "854",
    ["unique weapon user"] = "855",
    ["unique weapons"] = "856",
    ["unlucky protagonist"] = "857",
    ["unreliable narrator"] = "858",
    ["unrequited love"] = "859",
    ["valkyries"] = "860",
    ["vampires"] = "861",
    ["villainess noble girls"] = "862",
    ["virtual reality"] = "863",
    ["vocaloid"] = "864",
    ["voice actors"] = "865",
    ["voyeurism"] = "866",
    ["waiters"] = "867",
    ["war records"] = "868",
    ["wars"] = "869",
    ["weak protagonist"] = "870",
    ["weak to strong"] = "871",
    ["wealthy characters"] = "872",
    ["werebeasts"] = "873",
    ["wishes"] = "874",
    ["witches"] = "875",
    ["wizards"] = "876",
    ["world hopping"] = "877",
    ["world invasion"] = "1036",
    ["world travel"] = "878",
    ["world tree"] = "879",
    ["writers"] = "880",
    ["wuxia"] = "1143",
    ["xianxia"] = "1142",
    ["xuanhuan"] = "1141",
    ["yandere"] = "881",
    ["youkai"] = "882",
    ["younger brothers"] = "883",
    ["younger love interests"] = "884",
    ["younger sisters"] = "885",
    ["zombies"] = "886",

}

local STATUS_VALUES = {
    "all",        -- index 0
    "completed",  -- index 1
    "ongoing",    -- index 2
    "hiatus"      -- index 3
}


local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

---@param shortNum string
---@return number
local function expandNumber(shortNum)
	local number, suffix = shortNum:match("^(%d+%.?%d*)([kKmMbB]?)$")

	number = tonumber(number)
	if not number then return nil end

	if suffix == "k" or suffix == "K" then
		return math.floor(number * 1e3 + 0.5)
	elseif suffix == "m" or suffix == "M" then
		return math.floor(number * 1e6 + 0.5)
	elseif suffix == "b" or suffix == "B" then
		return math.floor(number * 1e9 + 0.5)
	else
		return math.floor(number + 0.5)
	end
end

---@param elements Elements
---@param stat string
---@return number | nil
local function findStat(elements, stat)
	local matchDesktop = " " .. stat .."$"
	local matchMobile = "^" .. stat ..": "
	for i = 0, elements:size() - 1 do
		local part = elements:get(i):text()
		if part:match(matchDesktop) ~= nil or part:match(matchMobile) ~= nil then
			local number = part:gsub(matchDesktop, ""):gsub(matchMobile, ""):gsub(",", ""):gsub(" ", "")
			return expandNumber(number)
		end
	end
end

local function removeElements(element, attr)
	local elementToRemove = element:select(attr)
	if elementToRemove then
		elementToRemove:remove()
	end
end

local function parse(doc)
	return map(doc:selectFirst("#page"):select(".wi_fic_wrap .search_main_box"), function(v)
		local body = v:selectFirst(".search_body")
		if body == nil then
			body = v
		end
		local t = v:selectFirst(".search_title a")
		local stats = body:select(".search_stats .nl_stat")
		local words = findStat(stats, "Words")
		local views = findStat(stats, "Views")
		local chapters = findStat(stats, "Chapters")
		local comments = findStat(stats, "Reviews")
		local favorites = findStat(stats, "Favorites")
		local genres = map(v:select(".search_genre .fic_genre"), function(g)
			return g:text()
		end)
		local author = v:selectFirst(".a_un_st"):text()
		local description = body:ownText()
		if description == nil or description:len() == 0 then
			local element = body:selectFirst("> div:last-child")
			if element then
				removeElements(element, ".dots")
				removeElements(element, ".morelink")
				description = HTMLToString(element)
			end
		else
			removeElements(body, ".dots")
			removeElements(body, ".morelink")
			removeElements(body, ".search_title")
			removeElements(body, ".search_stats")
			removeElements(body, ".search_genre")
			description = HTMLToString(body)
		end

		return Novel {
			title = t:text(),
			link = t:attr("href"):match("/series/(%d+)"),
			imageURL = v:selectFirst(".search_img img"):attr("src"),
			wordCount = words,
			viewCount = views,
			chapterCount = chapters,
			commentCount = comments,
			favoriteCount = favorites,
			genres = genres,
			description = description,
			authors = { author }
		}
	end)
end

local function buildGenreParams(data)
    local include = {}
    local exclude = {}

    for _, g in ipairs(GENRE_FILTERS) do
        local state = data[g.filterId]

        if state == 1 then
            include[#include + 1] = g.gi
        elseif state == 2 then
            exclude[#exclude + 1] = g.gi
        end
    end

    return
        (#include > 0 and table.concat(include, ",")) or nil,
        (#exclude > 0 and table.concat(exclude, ",")) or nil
end

local function buildCWParams(data)
    local include = {}
    local exclude = {}

    for _, cw in ipairs(CW_FILTERS) do
        local state = data[cw.cwId]

        if state == 1 then
            table.insert(include, cw.cti)
        elseif state == 2 then
            table.insert(exclude, cw.cti)
        end
    end

    local cti = (#include > 0) and table.concat(include, ",") or nil
    local cte = (#exclude > 0) and table.concat(exclude, ",") or nil

    return cti, cte
end

local function normalizeTag(tag)
    return tag
            :lower()
            :gsub("%s+", " ")          -- collapse multiple spaces
            :gsub("^%s*(.-)%s*$", "%1") -- trim
end

local function buildTagParams(data)

    local includeRaw = data[FILTER_TAG_INCLUDE]
    local excludeRaw = data[FILTER_TAG_EXCLUDE]

    local include = {}
    local exclude = {}

    if includeRaw then
        for tag in includeRaw:gmatch("[^,]+") do
            local id = TAG_MAP[normalizeTag(tag)]
            if id then table.insert(include, id) end
        end
    end

    if excludeRaw then
        for tag in excludeRaw:gmatch("[^,]+") do
            local id = TAG_MAP[normalizeTag(tag)]
            if id then table.insert(exclude, id) end
        end
    end

    local ti = (#include > 0) and table.concat(include, ",") or nil
    local te = (#exclude > 0) and table.concat(exclude, ",") or nil

    return ti, te
end

local function applySort(params, data)
    local sortIndex = data[FILTER_SORT] or 7
    params.sort = SORT_VALUES[sortIndex + 1] or "pageviews"
end

local function applyOrder(params, data)
    params.order = (data[FILTER_ORDER] == 0) and "desc" or "asc"
end

local function applyStatus(params, data)
    local statusIndex = data[FILTER_STATUS] or 0
    local status = STATUS_VALUES[statusIndex + 1]

    if status and status ~= "all" then
        params.cp = status
    end
end

local function applyGenre(params, data)
    local gi, ge = buildGenreParams(data)

    if gi then
        params.gi = gi

        if gi:find(",") then
            params.mgi = (data[FILTER_GENRE_MODE] == 1) and "or" or "and"
        end
    end

    if ge then
        params.ge = ge
    end
end

local function applyContentWarning(params, data)
    local cti, cte = buildCWParams(data)

    if cti then
        params.cti = cti

        if cti:find(",") then
            params.mct = (data[FILTER_CW_MODE] == 1) and "or" or "and"
        end
    end

    if cte then
        params.cte = cte
    end
end

local function applyTags(params, data)
    local tgi, tge = buildTagParams(data)

    if tgi then
        params.tgi = tgi

        if tgi:find(",") then
            params.mtgi = (data[FILTER_TAG_MODE] == 1) and "or" or "and"
        end
    end

    if tge then
        params.tge = tge
    end
end

return {
	id = 86802,
	name = "ScribbleHub",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
	chapterType = ChapterType.HTML,
	hasCloudFlare = true,

	listings = {
        Listing("Novels", true, function(data)

            local params = {
                sf = 1,
                pg = data[PAGE] or 1
            }

            applySort(params, data)
            applyOrder(params, data)
            applyStatus(params, data)
            applyGenre(params, data)
            applyContentWarning(params, data)
            applyTags(params, data)

            local url = qs(params, baseURL .. "/series-finder/")
            print("FINAL URL =", url)

            return parse(GETDocument(url))
        end)
    },

    searchFilters = {
	    DropdownFilter(FILTER_STATUS, "Story Status", {
            "All",
            "Completed",
            "Ongoing",
            "Hiatus"
        }),

        DropdownFilter(FILTER_SORT, "Sort by", {
                "Pageviews",
                "Chapters / Week",
                "Date Added",
                "Favorites",
                "Last Update",
                "Number of Ratings",
                "Pages",
                "Chapters",
                "Ratings",
                "Readers",
                "Reviews",
                "Total Words"
            }),
        DropdownFilter(FILTER_ORDER, "Order", { "Descending", "Ascending" }),

        FilterGroup("Genre", {
            TriStateFilter(FILTER_GENRE_ACTION,        "Action"),
            TriStateFilter(FILTER_GENRE_ADULT,         "Adult"),
            TriStateFilter(FILTER_GENRE_ADVENTURE,     "Adventure"),
            TriStateFilter(FILTER_GENRE_BOYS_LOVE,     "Boys Love"),
            TriStateFilter(FILTER_GENRE_COMEDY,        "Comedy"),
            TriStateFilter(FILTER_GENRE_DRAMA,         "Drama"),
            TriStateFilter(FILTER_GENRE_ECCHI,         "Ecchi"),
            TriStateFilter(FILTER_GENRE_FANFICTION,    "Fanfiction"),
            TriStateFilter(FILTER_GENRE_FANTASY,       "Fantasy"),
            TriStateFilter(FILTER_GENRE_GENDER_BENDER, "Gender Bender"),
            TriStateFilter(FILTER_GENRE_GIRLS_LOVE,    "Girls Love"),
            TriStateFilter(FILTER_GENRE_HAREM,         "Harem"),
            TriStateFilter(FILTER_GENRE_HISTORICAL,    "Historical"),
            TriStateFilter(FILTER_GENRE_HORROR,        "Horror"),
            TriStateFilter(FILTER_GENRE_ISEKAI,        "Isekai"),
            TriStateFilter(FILTER_GENRE_JOSEI,         "Josei"),
            TriStateFilter(FILTER_GENRE_LITRPG,        "LitRPG"),
            TriStateFilter(FILTER_GENRE_MARTIAL_ARTS,  "Martial Arts"),
            TriStateFilter(FILTER_GENRE_MATURE,        "Mature"),
            TriStateFilter(FILTER_GENRE_MECHA,         "Mecha"),
            TriStateFilter(FILTER_GENRE_MYSTERY,       "Mystery"),
            TriStateFilter(FILTER_GENRE_PSYCHOLOGICAL, "Psychological"),
            TriStateFilter(FILTER_GENRE_ROMANCE,       "Romance"),
            TriStateFilter(FILTER_GENRE_SCHOOL_LIFE,   "School Life"),
            TriStateFilter(FILTER_GENRE_SCI_FI,        "Sci-fi"),
            TriStateFilter(FILTER_GENRE_SEINEN,        "Seinen"),
            TriStateFilter(FILTER_GENRE_SLICE_OF_LIFE, "Slice of Life"),
            TriStateFilter(FILTER_GENRE_SMUT,          "Smut"),
            TriStateFilter(FILTER_GENRE_SPORTS,        "Sports"),
            TriStateFilter(FILTER_GENRE_SUPERNATURAL,  "Supernatural"),
            TriStateFilter(FILTER_GENRE_TRAGEDY,       "Tragedy"),
        }),

        DropdownFilter(FILTER_GENRE_MODE, "Genre Match", { "AND", "OR" }),

        TextFilter(FILTER_TAG_INCLUDE, "Include Tags (comma separated)"),
        TextFilter(FILTER_TAG_EXCLUDE, "Exclude Tags (comma separated)"),
        DropdownFilter(FILTER_TAG_MODE, "Tag Match", { "AND", "OR" }),

        FilterGroup("Content Warning", {
            TriStateFilter(FILTER_CW_GORE, "Gore"),
            TriStateFilter(FILTER_CW_SEXUAL_CONTENT, "Sexual Content"),
            TriStateFilter(FILTER_CW_STRONG_LANGUAGE, "Strong Language"),
        }),

        DropdownFilter(FILTER_CW_MODE, "CW Match", { "AND", "OR" })

    },



	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(baseURL.."/series/"..url.."/a/"):selectFirst(".site-content-contain")
		local novel = doc:selectFirst("div[typeof=Book]")
		local wrap = novel:selectFirst(".box_fictionpage")
		removeElements(wrap, ".dots")
		removeElements(wrap, ".morelink")
		local s = doc:selectFirst(".copyright ul"):children()

		s = s:get(s:size() - 1):children()
		s = s:get(s:size() - 1)
		s = s:ownText()
		if s:match("Ongoing") then
			s = NovelStatus.PUBLISHING
		elseif s:match("Complete") then
			s = NovelStatus.COMPLETED
		elseif s:match("Hiatus") then
			s = NovelStatus.PAUSED
		else
			s = NovelStatus.UNKNOWN
		end

		local text = function(v) return v:text() end

        local genresList = map(doc:select(".wi_fic_genre a"), text)
        local tagsList = map(doc:select(".wi_fic_showtags a"), text)

        -- Merge tags into genres (because app likely doesn't display tags)
        for _, tag in ipairs(tagsList) do
            table.insert(genresList, tag)
        end

        local info = NovelInfo {
            title = novel:selectFirst(".fic_title"):text(),
            imageURL = novel:selectFirst(".fic_image img"):attr("src"),
            description = HTMLToString(doc:selectFirst(".wi_fic_desc")),
            genres = genresList,  -- use merged list
            authors = { novel:selectFirst("span[property=name] .auth_name_fic"):text() },
            status = s
        }

		if loadChapters then
			local body = RequestBody("action=wi_getreleases_pagination&pagenum=-1&mypostid="..url, MTYPE)
			local cdoc = RequestDocument(POST("https://www.scribblehub.com/wp-admin/admin-ajax.php", HEADERS, body))
			local chapters = AsList(map(cdoc:selectFirst("ol"):select("li"), function(v, i)
				local a = v:selectFirst("a")
                local a_span = v:selectFirst("span")
				return NovelChapter {
					order = v:attr("order"),
					title = a:text(),
					link = shrinkURL(a:attr("href")),
                    release = (a_span and (a_span:attr("title") or a_span:attr("unixtime") or v:selectLast("a"):text())) or nil
				}
			end))
			Reverse(chapters)
			info:setChapters(chapters)
		end

		return info
	end,

	getPassage = function(url)
		local chap = GETDocument(expandURL(url)):getElementById("main read chapter")
		local title = chap:selectFirst(".chapter-title"):text()
		chap = chap:getElementById("chp_raw")

		-- Remove <p></p>.
		local toRemove = {}
		chap:traverse(NodeVisitor(function(v)
			if v:tagName() == "p" and v:childrenSize() == 0 and v:text() == "" then
				toRemove[#toRemove+1] = v
			end
			if v:hasAttr("border") then
				v:removeAttr("border")
			end
		end, nil, true))
		for _,v in pairs(toRemove) do
			v:remove()
		end

		-- Chapter title inserted before chapter text
		chap:child(0):before("<h1>" .. title .. "</h1>");

		return pageOfElem(chap, false, css)
	end,

	search = function(data)
		return parse(GETDocument(qs({
			s = data[QUERY], post_type = "fictionposts"
		}, baseURL .. "/")))
	end,
	isSearchIncrementing = false
}
