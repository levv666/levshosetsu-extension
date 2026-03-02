-- {"id":48761468,"ver":"1.0.1","libVer":"1.0.0","author":"Lev616","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://bailiantales.com", {
    id = 48761468,
    name = "BaiLianTales",
    imageURL = "https://bailiantales.com/wp-content/uploads/2025/08/Add-a-heading-Tag-US-2-1.png",
    chaptersScriptLoaded = true,
    novelPageTitleSel = "div.post-title > h1",

    latestNovelSel = "div.page-listing-item",
    novelListingURLPath = "novel",
    shrinkURLNovel = "novel",
    hasSearch = true,
    searchHasOper = true,
    chaptersListSelector= "li.wp-manga-chapter.free-chap",

    genres = {
        "Action",
        "Adult",
        "Adventure",
        "BL",
        "Comedy",
        "Drama",
        "Fantasy",
        "Gender Bender",
        "Historical",
        "Horror",
        ["martial-arts"] = "Martial Arts",
        "Mature",
        "Mystery",
        "Reincarnation",
        "Romance",
        ["school-life"] = "School Life",
        ["sci-fi"] = "Sci-fi",
        ["shouju-ai"] = "Shoujo Ai",
        "Smut",
        "Supernatural",
        "Tragedy",
        "Xianxia",
        "Yaoi",
        "Yuri",
    }
})

