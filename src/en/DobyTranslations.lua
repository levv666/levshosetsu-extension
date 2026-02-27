-- {"id":1244231,"ver":"1.0.1","libVer":"1.0.0","author":"Lev616","repo":"","dep":[]}

----------------
-- METADATA
----------------

local id = 1244231
local name = "Doby Translations"
local baseURL = "https://dobytranslations.com"
local imageURL = ""
local hasCloudFlare = false
local hasSearch = true
local isSearchIncrementing = false
local chapterType = ChapterType.HTML
local startIndex = 1

----------------
-- URL HELPERS
----------------

local function shrinkURL(url, type)
    return url:gsub(baseURL, "")
end

local function expandURL(url, type)
    return baseURL .. url
end

----------------
-- LISTING (Latest)
----------------

local listings = {
    Listing("Latest", true, function(data)

        local page = data[PAGE]
        local url = baseURL .. "/page/" .. page .. "/"

        local document = GETDocument(url)

        return map(document:select("div.excstf > div"), function(card)

            local linkElement = card:selectFirst("a.series-link")
            if linkElement == nil then return nil end

            local titleElement = linkElement:selectFirst("h3.epic-title")
            local imageElement = card:selectFirst("div.imgu img")

            return Novel {
                title = titleElement and titleElement:text() or "No Title",
                link = shrinkURL(linkElement:attr("href"), KEY_NOVEL_URL),
                imageURL = imageElement and imageElement:attr("src") or nil
            }
        end)
    end)
}

----------------
-- SEARCH
----------------

local function search(data)

    local query = data[QUERY]
    local url = baseURL .. "/search/?keywords=" .. query

    local doc = GETDocument(url)

    return map(doc:select(".UpdateList .clearfix.itemBox"), function(v)
        return Novel {
            title = v:selectFirst(".itemTxt .title"):text(),
            imageURL = v:selectFirst(".itemImg a img"):attr("src"),
            link = shrinkURL(v:selectFirst("a"):attr("href"), KEY_NOVEL_URL)
        }
    end)
end

----------------
-- PARSE NOVEL
----------------

local function parseNovel(novelURL)

    local url = expandURL(novelURL, KEY_NOVEL_URL)
    local document = GETDocument(url)

    local title = document:selectFirst("h1"):text()

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

----------------
-- GET PASSAGE
----------------

local function getPassage(chapterURL)

    local url = expandURL(chapterURL, KEY_CHAPTER_URL)
    local document = GETDocument(url)

    local content = document:selectFirst("article")

    return pageOfElem(content, true)
end

----------------
-- RETURN
----------------

return {
    -- Required
    id = id,
    name = name,
    baseURL = baseURL,
    listings = listings,
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional
    imageURL = imageURL,
    hasCloudFlare = hasCloudFlare,
    hasSearch = hasSearch,
    isSearchIncrementing = isSearchIncrementing,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required because hasSearch = true
    search = search,
}