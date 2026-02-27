-- {"id": 91919124, "ver": "1.0.0", "libVer": "1.0.0", "author": "lev616", "dep": ["Madara>=2.2.0"]}

return Require("Madara")("https://dobytranslations.com", {
    id = 91919124,
    name = "Doby Translations",
    imageURL = "https://dobytranslations.com/wp-content/uploads/2024/05/a-adult-male-maltes-white-dog-reading-a-book.jpg",

    shrinkURLNovel = "series",

    latestNovelSel = "article.maindet",
    searchNovelSel = "article.maindet",

    novelPageTitleSel = "h1",

    chaptersScriptLoaded = true,
    chaptersOrderReversed = true,

    hasCloudFlare = false,
    isSearchIncrementing = true,

    -- ✅ CORRECT pagination override
    listingURL = function(self, page)
        page = page or 1
        return "/series/?page=" .. page .. "&m_orderby=latest"
    end,

    genres = {
        "Antihero Protagonist",
        "Comedy",
        "Completed Premium/Ongoing Free Unlock",
        "Completely Free",
        "Cthulhu",
        "Drama",
        "Ecchi",
        "Fantasy",
        "Farming",
        "Female Protagonist",
        "Gender Bender",
        "Harem",
        "Horror",
        "Male Protagonist",
        "Male to Female",
        "No Romance",
        "Psychological",
        "Revenge",
        "Romance",
        "Slice of Life",
        "System",
        "Villain Protagonist",
        "Yuri"
    }
})