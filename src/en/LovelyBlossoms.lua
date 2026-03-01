-- {"id":1742321,"ver":"1.0.3","libVer":"1.0.0","author":"Lev616","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://lovelyblossoms.com", {
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
    isSearchIncrementing = false,

    -------------------------------------------------
    -- 🔥 CUSTOM SEARCH BUILDER (no genres_map usage)
    -------------------------------------------------
    createSearchString = function(self, tbl)
        local encode = Require("url").encode
        local query = tbl[QUERY] or ""
        local page = tbl[PAGE] or 1

        local url = self.baseURL ..
                "/page/" .. page .. "/?s=" .. encode(query) ..
                "&post_type=wp-manga" ..
                "&author=&artist=&release="

        -- iterate through genres manually
        local genreStartIndex = 100 -- Madara starts genre keys at 100
        for i, name in ipairs(self.genres) do
            local key = genreStartIndex + i
            if tbl[key] then
                local slug = name:lower():gsub(" ", "-")
                url = url .. "&genre[]=" .. slug
            end
        end

        -- operator
        if self.searchOperId then
            url = url .. "&op=" .. (tbl[self.searchOperId] and "0" or "1")
        end

        return url
    end,
    -------------------------------------------------

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
        "Yuri"
    }
})
