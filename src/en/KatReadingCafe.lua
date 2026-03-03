-- {"id":977513,"ver":"1.0.9","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://katreadingcafe.com/"
local CatReadingCafeLogo = "https://katreadingcafe.com/wp-content/uploads/2025/01/2717291-2-3-e1737942920628.png"
local HTMLToString = Require("unhtml").HTMLToString

local function shrinkURL(url)
    return url:gsub(baseURL, "")
end

local function expandURL(url)
    return baseURL .. url
end

local GENRES = {
    -- Genres
    { key = 201, name = "Action", slug = "action" },
    { key = 202, name = "Adult", slug = "adult" },
    { key = 203, name = "Adventure", slug = "adventure" },
    { key = 204, name = "Comedy", slug = "comedy" },
    { key = 205, name = "Crossdressing", slug = "crossdressing" },
    { key = 206, name = "Cruel Depictions", slug = "cruel-depictions" },
    { key = 207, name = "Depiction of Cruelty", slug = "depiction-of-cruelty" },
    { key = 208, name = "Drama", slug = "drama" },
    { key = 209, name = "Ecchi", slug = "ecchi" },
    { key = 210, name = "Fantasy", slug = "fantasy" },
    { key = 211, name = "Female", slug = "female" },
    { key = 212, name = "Gender Bender", slug = "gender-bender" },
    { key = 213, name = "Gore", slug = "gore" },
    { key = 214, name = "Harem", slug = "harem" },
    { key = 215, name = "Historical", slug = "historical" },
    { key = 216, name = "Horror", slug = "horror" },
    { key = 217, name = "Josei", slug = "josei" },
    { key = 218, name = "Magic", slug = "magic" },
    { key = 219, name = "Martial Arts", slug = "martial-arts" },
    { key = 220, name = "Mature", slug = "mature" },
    { key = 221, name = "Misunderstanding", slug = "misunderstanding" },
    { key = 222, name = "MTL", slug = "mtl" },
    { key = 223, name = "Mystery", slug = "mystery" },
    { key = 224, name = "No Romance", slug = "no-romance" },
    { key = 225, name = "Psychological", slug = "psychological" },
    { key = 226, name = "Pure Love", slug = "pure-love" },
    { key = 227, name = "R15", slug = "r15" },
    { key = 228, name = "Revenge", slug = "revenge" },
    { key = 229, name = "Romance", slug = "romance" },
    { key = 230, name = "School Life", slug = "school-life" },
    { key = 231, name = "Sci-fi", slug = "sci-fi" },
    { key = 232, name = "Seinen", slug = "seinen" },
    { key = 233, name = "Shoujo", slug = "shoujo" },
    { key = 234, name = "Shoujo Ai", slug = "shoujo-ai" },
    { key = 235, name = "Shounen", slug = "shounen" },
    { key = 236, name = "Slice of Life", slug = "slice-of-life" },
    { key = 237, name = "Smut", slug = "smut" },
    { key = 238, name = "Straight", slug = "straight" },
    { key = 239, name = "Supernatural", slug = "supernatural" },
    { key = 240, name = "Tragedy", slug = "tragedy" },
    { key = 241, name = "Wuxia", slug = "wuxia" },
    { key = 242, name = "Xianxia", slug = "xianxia" },
    { key = 243, name = "Xuanhuan", slug = "xuanhuan" },
    { key = 244, name = "Yuri", slug = "yuri" },
}

local ORDER_OPTIONS = {
    { key = 301, name = "A-Z", value = "title" },
    { key = 302, name = "Z-A", value = "titlereverse" },
    { key = 303, name = "Latest Updated", value = "update" },
    { key = 304, name = "Latest Added", value = "latest" },
    { key = 305, name = "Popular", value = "popular" },
    { key = 306, name = "Rating", value = "rating" },
}

local function createFilterString(data)
    local parts = {}

    -- genres
    for _, g in ipairs(GENRES) do
        if data[g.key] then
            parts[#parts + 1] = "genre[]=" .. g.slug
        end
    end

    -- order by
    local selectedOrderKey = data[301]  -- dropdown key
    if selectedOrderKey then
        local orderValue = ORDER_OPTIONS[selectedOrderKey - 301 + 1].value
        parts[#parts + 1] = "order=" .. orderValue
    else
        parts[#parts + 1] = "order=update"
    end

    -- page
    if data[PAGE] then
        parts[#parts + 1] = "page=" .. data[PAGE]
    end

    if #parts > 0 then
        return "&" .. table.concat(parts, "&")
    end

    return ""
end

-- =========================
-- LISTING (Homepage)
-- =========================

local function parseListing(listingURL)
    local doc = GETDocument(listingURL)
    if not doc then return {} end

    return mapNotNil(doc:select("div.listupd > article"), function(card)
        local linkEl  = card:selectFirst("h2 a")
        local titleEl = card:selectFirst("h2 a")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst(".mdthumb img")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(linkEl:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("src")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "series/?page=" .. page .. "&order=update"
    return parseListing(url)
end

local function getFilterListing(data)
    local page = data[PAGE] or 1
    local filterString = createFilterString(data)

    local url = baseURL .. "series/?page=" .. page .. filterString
    return parseListing(url)
end

local function search(data)
    local query = data[QUERY] or ""
    local page  = data[PAGE] or 1

    local url = page == 1
            and (baseURL .. "?s=" .. query)
            or  (baseURL .. "/page/" .. page .. "/?s=" .. query)

    local doc = GETDocument(url)
    return map(doc:select("div.listupd > article"), function(v)
        return Novel {
            title = v:selectFirst("h2 a"):text(),
            imageURL = v:selectFirst(".mdthumb img"):attr("src"),
            link = shrinkURL(v:selectFirst("h2 a"):attr("href"))
        }
    end)
end


-- =========================
-- PARSE NOVEL
-- =========================

local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))
    local content = doc:selectFirst("main#primary") or doc  -- ensure content is not nil

    -- Basic info
    local titleElement = doc:selectFirst("h1")
    local imageElement = doc:selectFirst("img.ts-post-image")
    local descriptionElement = doc:selectFirst(".entry-content")
    local genrelist = doc:selectFirst("div.sertogenre")

    local s = doc:selectFirst("span.Completed") and NovelStatus.COMPLETED
            or doc:selectFirst("span.Hiatus") and NovelStatus.PAUSED
            or NovelStatus.PUBLISHING


    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("src") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a[rel=tag]"), function(v) return v:text() end) or nil,
        status = s
    }

    if loadChapters then
        local chapterItems = content:select("li[data-id]")

        local temp = map(chapterItems, function(v)
            local a = v:selectFirst("a")
            local title = v:selectFirst(".epl-title")
            local number = v:selectFirst(".epl-num")

            -- Check elements BEFORE using them
            if a == nil or title == nil or number == nil then
                return nil
            end

            -- Skip premium chapters (check from HTML element)
            local numDiv = v:selectFirst(".epl-num")

            if numDiv and numDiv:text():find("🔒") then
                return nil
            end

            local titleDiv = number:text() .. " - " .. title:text()
            local dateDiv = v:selectFirst(".epl-date")
            local dataId = tonumber(v:attr("data-id")) or 0

            return {
                id = dataId,
                title = titleDiv
                        :gsub("%s+", " ")
                        :gsub("^%s*(.-)%s*$", "%1"),
                link = shrinkURL(a:attr("href")),
                release = dateDiv and dateDiv:text() or nil
            }
        end)

        temp = filter(temp, function(v) return v ~= nil end)

        table.sort(temp, function(a, b)
            return a.id < b.id
        end)

        local chapters = AsList(map(temp, function(v, i)
            return NovelChapter {
                order = i,
                title = v.title,
                link = v.link,
                release = v.release
            }
        end))

        info:setChapters(chapters)
    end

    return info
end

-- =========================
-- GET PASSAGE
-- =========================

local function getPassage(chapterURL)
    local htmlElement = GETDocument(expandURL(chapterURL))
    local title = htmlElement:selectFirst("h1.entry-title"):text()
    htmlElement = htmlElement:selectFirst("div.epcontent.entry-content")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:selectFirst("div.code-block"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

local searchFilters = {
    FilterGroup("Genres", (function()
        local t = {}
        for _, g in ipairs(GENRES) do
            t[#t+1] = CheckboxFilter(g.key, g.name)
        end
        return t
    end)()),
    DropdownFilter(999, "Order By", {"A-Z", "Latest Updated", "Latest Added", "Popular", "Rating"}),
}

return {
    id = 977513,
    name = "Kat Reading Cafe",
    imageURL = CatReadingCafeLogo,
    baseURL = baseURL,
    hasSearch = true,
    listings = {
        Listing("Latest", true, getListing),
        Listing("Filter Series", true, getFilterListing),
        Listing("Search", true, search)
    },
    searchFilters = searchFilters,
    parseNovel = parseNovel,
    getPassage = getPassage,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    chapterType = ChapterType.HTML,
    search = search
}