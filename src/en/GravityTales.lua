-- {"id":981363135,"ver":"1.0.6","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://gravitytales.com"
local GravityTalesLogo = "https://th.bing.com/th/id/ODF.cEEqnSt1RywCg37Cq5NC4w"
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

local function parseListing(data)
    local page  = data[PAGE] or 1

    local url = baseURL .. "/page/" .. page .. "/?s&post_type=fcn_story&orderby=modified"

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
    local doc = GETDocument(expandURL(novelURL))-- ensure content is not nil

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
        local chapterItems = doc:select("li[data-group='unassigned']")

        local temp = map(chapterItems, function(v)
            local a = v:selectFirst("a")
            local titleDiv = v:selectFirst("a")

            if a == nil or titleDiv == nil then
                return nil
            end

            local dateDiv = v:selectFirst("time.chapter-group__list-item-date > span.list-view")
            local cleanTitle = titleDiv:text():
            gsub("%s+", " "):
            gsub("^%s*(.-)%s*$", "%1")
            local chapterNum = tonumber(cleanTitle:match("Chapter%s+(%d+)")) or 0
            return {
                id = chapterNum,
                title = cleanTitle,
                link = shrinkURL(a:attr("href")),
                release = dateDiv and dateDiv:text() or nil,
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
    local title = htmlElement:selectFirst("h1.chapter__title"):text()
    htmlElement = htmlElement:selectFirst("div.chapter-formatting")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    local paragraphs = htmlElement:select("p")
    for i = 0, paragraphs:size() - 1 do
        local p = paragraphs:get(i)
        local text = p:text()

        -- This regex checks for:
        -- %s (standard spaces/tabs/newlines)
        -- \227\128\128 (The UTF-8 byte sequence for the full-width space '　')
        if text == "" or text:match("^[%s\227\128\128]+$") then
            p:remove()
        end
    end
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

return {
    id = 981363135,
    name = "Gravity Tales",
    imageURL = GravityTalesLogo,
    baseURL = baseURL,
    hasSearch = true,
    listings = {
        Listing("Latest", true, parseListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    chapterType = ChapterType.HTML,
    search = search
}

