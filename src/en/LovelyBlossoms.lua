-- {"id":1742321,"ver":"1.0.1","libVer":"1.0.0","author":"Lev616","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://lovelyblossoms.com", {
    id = 1742321,
    name = "Lovely Blossoms",
    imageURL = "https://lovelyblossoms.com/wp-content/uploads/2025/09/lovely-blossoms-2-Photoroom-1.png",

    chaptersScriptLoaded = true,
    novelPageTitleSel = "div.post-title > h1",
    searchHasOper = true,
    chaptersListSelector = "li.wp-manga-chapter.free-chap",

    genres = {
        ["action"] = "Action",
        ["adult"] = "Adult",
        ["adventure"] = "Adventure",
        ["comedy"] = "Comedy",
        ["drama"] = "Drama",
        ["ecchi"] = "Ecchi",
        ["fantasy"] = "Fantasy",
        ["fighting"] = "Fighting",
        ["fun"] = "Fun",
        ["games"] = "Games",
        ["harem"] = "Harem",
        ["historical"] = "Historical",
        ["horror"] = "Horror",
        ["lgbt"] = "LGBT",
        ["martial-arts"] = "Martial Arts",
        ["mystery"] = "Mystery",
        ["psychological"] = "Psychological",
        ["realistic"] = "Realistic",
        ["reincarnation"] = "Reincarnation",
        ["romance"] = "Romance",
        ["school-life"] = "School Life",
        ["sci-fi"] = "Sci-Fi",
        ["shoujo-ai"] = "Shoujo Ai",
        ["smut"] = "Smut",
        ["sports"] = "Sports",
        ["supernatural"] = "Supernatural",
        ["tragedy"] = "Tragedy",
        ["urban"] = "Urban",
        ["yaoi"] = "Yaoi",
        ["yuri"] = "Yuri"
    }
})

