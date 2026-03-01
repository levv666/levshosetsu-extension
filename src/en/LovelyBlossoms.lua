-- {"id":1742321,"ver":"1.0.7","libVer":"1.0.0","author":"Lev616","dep":["Madara>=2.2.0"]}

local madara = Require("Madara")("https://lovelyblossoms.com", {
    id = 1742321,
    name = "Lovely Blossoms",
    imageURL = "https://lovelyblossoms.com/wp-content/uploads/2025/09/lovely-blossoms-2-Photoroom-1.png",

    chaptersScriptLoaded = true,
    novelPageTitleSel = "div.post-title > h1",

    latestNovelSel = "div.page-listing-item",
    novelListingURLPath = "novel",
    shrinkURLNovel = "novel",
    searchHasOper = true,
    chaptersListSelector = "li.wp-manga-chapter.free-chap",

    genres = {
        "Action",
        "Adult",
        "Adventure",
        "Comedy",
        "Drama",
        "Ecchi",
        "Fantasy",
        "Fighting",
        "Fun",
        "Games",
        "Harem",
        "Historical",
        "Horror",
        "LGBT",
        "Martial Arts",
        "Mystery",
        "Psychological",
        "Realistic",
        "Reincarnation",
        "Romance",
        "School Life",
        "Sci-Fi",
        "Shoujo Ai",
        "Smut",
        "Sports",
        "Supernatural",
        "Tragedy",
        "Urban",
        "Yaoi",
        "Yuri",
    },
})

-- 🔥 Force the main listing tab to use search() instead of latest()
madara.listings = {
    Listing("Novels", true, madara.search)
}

return madara