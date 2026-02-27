-- {"id":8437659,"ver":"1.0.0","libVer":"1.0.0","author":"lev616"}

-- {"id": 91919124, "ver": "1.0.0", "libVer": "2.9.2", "author": "muzdalifah", "dep": ["Madara>=2.2.0"]}

return Require("Madara")("https://dobytranslations.com", {
    id = 91919124, -- ⚠️ change to unique ID
    name = "Doby Translations",
    imageURL = "https://dobytranslations.com/wp-content/uploads/2024/05/a-adult-male-maltes-white-dog-reading-a-book.jpg",

    novelListingURLPath = "series",
    shrinkURLNovel = "series",

    latestNovelSel = "a.series-link",
    searchNovelSel = "a.series-link",

    novelPageTitleSel = "h1",

    chaptersScriptLoaded = true,
    chaptersOrderReversed = true,

    hasCloudFlare = false,
    isSearchIncrementing = true,

    latest = function(self, data)
        local page = data[PAGE]
        local url = self.baseURL .. "/series/?page=" .. page .. "&m_orderby=latest"
        return self.parse(GETDocument(url))
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