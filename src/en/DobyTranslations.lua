-- {"id":1244231,"ver":"1.0.4","libVer":"1.0.0","author":"Lev616"}

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

local function parseListing(listingURL)
    local doc = GETDocument(listingURL)

    return map(doc:select("div.excstf > div"), function(card)

        local linkElement = card:selectFirst("a.series-link")
        local titleElement = card:selectFirst("h3.epic-title")
        local imageElement = card:selectFirst("div.imgu img")

        -- IMPORTANT: Never return nil
        if linkElement == nil or titleElement == nil then
            return Novel {
                title = "Unknown",
                link = ""
            }
        end

        return Novel {
            title = titleElement:text(),
            link = shrinkURL(linkElement:attr("href")),
            imageURL = imageElement and imageElement:attr("src") or nil
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/page/" .. page .. "/"
    return parseListing(url)
end

local function search(data)
    local function getSearchResult(queryContent)
        return GETDocument(baseURL .. "/search/?keywords=" .. queryContent)
    end


    local queryContent = data[QUERY]
    local doc = getSearchResult(queryContent)

    return map(doc:select(".UpdateList .clearfix.itemBox"), function(v)
        return Novel {
            title = v:selectFirst(".itemTxt .title"):text(),
            imageURL = v:selectFirst(".itemImg a img"):attr("src"),
            link = v:selectFirst("a"):attr("href")
        }
    end)
end


-- =========================
-- PARSE NOVEL
-- =========================

local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    -- Basic info
    local titleElement = doc:selectFirst("h1")
    local imageElement = doc:selectFirst("img.ts-post-image")
    local descriptionElement = doc:selectFirst(".entry-content")

    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("src") or nil,
        description = descriptionElement and descriptionElement:text() or "",
        status = NovelStatus.UNKNOWN
    }

    if loadChapters then
        -- Prepare "fake" POST body if needed (ScribbleHub uses pagenum=-1 to get all)
        -- For DobyTranslations, you can just fetch the page directly, no AJAX needed
        local chapterItems = doc:select("li[data-id]")  -- all <li> with chapters

        local chapters = AsList(map(chapterItems, function(v, i)
            local a = v:selectFirst("a")
            local titleDiv = a:selectFirst(".epl-title")
            local dateDiv = a:selectFirst(".epl-date")

            return NovelChapter {
                order = i + 1,
                title = titleDiv and titleDiv:text() or a:text(),
                link = shrinkURL(a:attr("href")),
                release = dateDiv and dateDiv:text() or nil
            }
        end))

        -- Reverse chapters if the site lists newest first
        Reverse(chapters)

        -- Set chapters to novel info
        info:setChapters(chapters)
    end

    return info
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
    id = 1244231,
    name = "Doby Translations",
    baseURL = baseURL,
    hasSearch = true,
    listings = {
        Listing("Latest", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    chapterType = ChapterType.HTML,
    search = search
}