-- {"id":1244231,"ver":"1.0.8","libVer":"1.0.0","author":"Lev616"}

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
    if doc == nil then
        return {}
    end

    local cards = doc:select("div.excstf > div")

    return map(filter(cards, function(card)
        return card:selectFirst("a.series-link") ~= nil
                and card:selectFirst("h3.epic-title") ~= nil
    end), function(card)

        local linkElement = card:selectFirst("a.series-link")
        local titleElement = card:selectFirst("h3.epic-title")
        local imageElement = card:selectFirst("div.imgu img")

        local href = linkElement:attr("href")

        return Novel {
            title = titleElement:text(),
            link = href and shrinkURL(href) or "",
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
    local content = doc:selectFirst("main#primary") or doc  -- ensure content is not nil

    -- Basic info
    local titleElement = doc:selectFirst("h1")
    local imageElement = doc:selectFirst("img.ts-post-image")
    local descriptionElement = doc:selectFirst(".entry-content")
    local genrelist = doc:selectFirst("div.sertogenre")


    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("src") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a[rel=tag]"), function(v) return v:text() end) or nil,
        status = NovelStatus.UNKNOWN
    }

    if loadChapters then
        local chapterItems = content:select("li[data-id]")

        local temp = map(chapterItems, function(v)
            local a = v:selectFirst("a")
            local titleDiv = v:selectFirst(".epl-title")

            if a == nil or titleDiv == nil then
                return nil
            end

            -- Skip premium chapters
            if titleDiv:selectFirst(".mycred-price") ~= nil then
                return nil
            end

            local dateDiv = v:selectFirst(".epl-date")
            local dataId = tonumber(v:attr("data-id")) or 0

            return {
                id = dataId,
                title = titleDiv:text()
                                :gsub("%s+", " ")
                                :gsub("^%s*(.-)%s*$", "%1"),
                link = shrinkURL(a:attr("href")),
                release = dateDiv and dateDiv:text() or nil
            }
        end)

        -- Remove nils
        temp = filter(temp, function(v) return v ~= nil end)

        -- Sort by data-id ascending
        table.sort(temp, function(a, b)
            return a.id < b.id
        end)

        -- Convert to Shosetsu List
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