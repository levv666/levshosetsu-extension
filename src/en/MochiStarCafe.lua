-- {"id":134652,"ver":"1.0.5","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://mochistar.org"
local DobyTranslationsLogo = "https://mochistar.org/wp-content/uploads/2026/02/stardust_mochi_129x129.png"
local HTMLToString = Require("unhtml").HTMLToString

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
    if not doc then return {} end

    return mapNotNil(doc:select("#list-of-stories li.card"), function(card)
        local linkEl  = card:selectFirst("h3.card__title a")
        local titleEl = card:selectFirst("h3.card__title a")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst("a.card__image")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(linkEl:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("href")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/stories/page/" .. page .. "/"
    return parseListing(url)
end

local function search(data)
    local query = data[QUERY] or ""
    local page  = data[PAGE] or 1

    local url = baseURL .. "/page/" .. page .. "/?s=" .. query .. "&post_type=fcn_story"

    local doc = GETDocument(url)
    return mapNotNil(doc:select("#search-result-list li.card"), function(card)
        local linkEl  = card:selectFirst("h3.card__title a")
        local titleEl = card:selectFirst("h3.card__title a")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst("a.card__image")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(linkEl:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("href")
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
    local imageElement = doc:selectFirst("div.main__wrapper a")
    local descriptionElement = doc:selectFirst("section.story__summary")
    local genrelist = doc:selectFirst("div.tag-group")

    local s = doc:selectFirst("span.story__meta-item.story__status._completed") and NovelStatus.COMPLETED
            or doc:selectFirst("span.story__meta-item.story__status._hiatus") and NovelStatus.PAUSED
            or NovelStatus.PUBLISHING


    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("href") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a.tag-pill"), function(v) return v:text() end) or nil,
        status = s
    }

    if loadChapters then
        local chapterItems = doc:select("li[data-group='free']")

        local temp = map(chapterItems, function(v)
            local a = v:selectFirst("a")
            local titleDiv = v:selectFirst("a")

            if a == nil or titleDiv == nil then
                return nil
            end

            local dateDiv = (v:select("span.list-view")[1] and v:select("span.list-view")[1]:text()) or nil
            local cleanTitle = titleDiv:text():
                                        gsub("%s+", " "):
                                        gsub("^%s*(.-)%s*$", "%1")
            local chapterNum = tonumber(cleanTitle:match("Chapter%s+(%d+)")) or 0
            return {
                id = chapterNum,
                title = cleanTitle,
                link = shrinkURL(a:attr("href")),
                release = dateDiv,
                order = chapterNum
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
    local htmlElement = GETDocument(expandURL(chapterURL))
    local title = htmlElement:selectFirst("h1.entry-title"):text()
    htmlElement = htmlElement:selectFirst("div.epcontent.entry-content")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:selectFirst("div.code-block"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

return {
    id = 134652,
    name = "MochiStar Cafe",
    imageURL = DobyTranslationsLogo,
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