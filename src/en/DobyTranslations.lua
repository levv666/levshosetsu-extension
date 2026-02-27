-- {"id":1244231,"ver":"1.0.0","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://dobytranslations.com"

local function shrinkURL(url)
    return url:gsub(baseURL, "")
end

local function expandURL(url)
    return baseURL .. url
end

-- =========================
-- LISTING (Homepage)
-- =========================

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/page/" .. page .. "/"

    local document = GETDocument(url)

    -- Each project card
    return map(document:select("div.excstf > div"), function(card)

        local linkElement = card:selectFirst("a.series-link")
        if linkElement == nil then return nil end

        local titleElement = linkElement:selectFirst("h3.epic-title")
        local imageElement = card:selectFirst("div.imgu img")

        return Novel {
            title = titleElement and titleElement:text() or "No Title",
            link = shrinkURL(linkElement:attr("href")),
            imageURL = imageElement and imageElement:attr("src") or nil
        }
    end)
end

-- =========================
-- PARSE NOVEL
-- =========================

local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local document = GETDocument(url)

    local title = document:selectFirst("h1"):text()

    local content = document:selectFirst("article")

    return NovelInfo {
        title = title,
        description = "",
        imageURL = "",
        chapters = {
            NovelChapter {
                title = title,
                link = novelURL,
                order = 1
            }
        }
    }
end

-- =========================
-- GET PASSAGE
-- =========================

local function getPassage(chapterURL)
    local url = expandURL(chapterURL)
    local document = GETDocument(url)

    local content = document:selectFirst("article")

    return pageOfElem(content, true)
end

return {
    id = 95561,
    name = "Doby Translations",
    baseURL = baseURL,
    listings = {
        Listing("Latest", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    chapterType = ChapterType.HTML
}