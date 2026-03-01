-- {"id":1742321,"ver":"1.0.3","libVer":"1.0.0","author":"Lev616","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://lovelyblossoms.com", {
    id = 1742321,
    name = "Lovely Blossoms",
    imageURL = "https://lovelyblossoms.com/wp-content/uploads/2025/09/lovely-blossoms-2-Photoroom-1.png",

    chaptersScriptLoaded = true,
    novelPageTitleSel = "div.post-title > h1",
    searchHasOper = true,
    chaptersListSelector = "li.wp-manga-chapter.free-chap",

    -------------------------------------------------
    -- 🔥 CUSTOM SEARCH BUILDER
    -------------------------------------------------
    createSearchString = function(self, tbl)
        local query = tbl[QUERY] or ""
        local url = self.baseURL .. "/?s=" .. Require("url").encode(query)
                .. "&post_type=wp-manga"

        -- genres
        for key, value in pairs(self.genres_map) do
            if tbl[key] then
                url = url .. "&genre[]=" .. value
            end
        end

        -- operator
        url = url .. "&op=" .. (tbl[self.searchOperId] and "0" or "")

        -- required empty fields
        url = url .. "&author=&artist=&release=&adult="

        -- status filters
        if tbl[STATUS_FILTER_KEY_ONGOING] then
            url = url .. "&status[]=on-going"
        end
        if tbl[STATUS_FILTER_KEY_COMPLETED] then
            url = url .. "&status[]=end"
        end
        if tbl[STATUS_FILTER_KEY_CANCELED] then
            url = url .. "&status[]=canceled"
        end

        -- LovelyBlossoms has upcoming
        if tbl[STATUS_FILTER_KEY_ON_HOLD] then
            url = url .. "&status[]=upcoming"
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
