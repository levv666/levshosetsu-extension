-- {"id":981363135,"ver":"1.1.0","libVer":"1.0.0","author":"Lev616","dep":["Fictioneer>=2.0.0"]}

return Require("Fictioneer")("https://gravitytales.com", {
    id = 981363135,
    name = "Gravity Tales",
    imageURL = "https://lovelyblossoms.com/wp-content/uploads/2025/09/lovely-blossoms-2-Photoroom-1.png",
    listingSelector = "#list-of-stories li.card",
    searchSelector = "#search-result-list li.card",
    chapterSelector = "li[data-group='unassigned']",

    searchPostType = "fcn_story",

    latest = function(self, data)
        print("self.baseURL =", self.baseURL)
        print("self.searchPostType =", self.searchPostType)
        print("PAGE =", PAGE)

        data = data or {}
        local page = (PAGE and data[PAGE]) or 1
        print("page =", page)

        local url = self.baseURL ..
                "/page/" .. page ..
                "/?s&post_type=" .. self.searchPostType ..
                "&orderby=modified"

        return self.parse(GETDocument(url))
    end,

    searchPostType = "fcn_story",

    chapterType = ChapterType.HTML,
    hasSearch = true,
})

