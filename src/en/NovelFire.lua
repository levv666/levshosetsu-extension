-- {"id":134867,"ver":"1.0.4","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://novelfire.net"
local NovelFireLogo = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Novelfire.png"
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

    return mapNotNil(doc:select("ul.novel-list.col6 li.novel-item"), function(card)
        local linkEl  = card:selectFirst("a")
        local titleEl = card:selectFirst("h4.novel-title.text2row")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst("figure.novel-cover img")

        return Novel {
            title = titleEl:text(),
            link = linkEl:attr("href") or "",
            imageURL = imgEl and expandURL(imgEl:attr("data-src")) or nil
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/genre-all/sort-new/status-all/all-novel?page=" .. page
    return parseListing(url)
end


local function search(data)
    local query = data[QUERY] or ""
    local page  = data[PAGE] or 1
    local url = baseURL .. "/search?keyword=" .. query .. "&type=title&page=" .. page

    local doc = GETDocument(url)
    return mapNotNil(doc:select("ul.novel-list.horizontal.col2.chapters li.novel-item"), function(card)
        local linkEl  = card:selectFirst("a")
        local titleEl = card:selectFirst("h4.novel-title.text1row")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst("figure.novel-cover img")

        return Novel {
            title = titleEl:text(),
            link = linkEl:attr("href") or "",
            imageURL = imgEl and expandURL(imgEl:attr("src")) or nil
        }
    end)
end

-- =========================
-- PARSE NOVEL
-- =========================

local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    -- Basic info
    local titleElement = doc:selectFirst("div.novel-info h1")
    local imageElement = doc:selectFirst("div.fixed-img img")
    local descriptionElement = doc:selectFirst("div.content.expand-wrapper")
    local genrelist = doc:selectFirst("div.categories")

    local s = doc:selectFirst("span.Completed") and NovelStatus.COMPLETED
            or doc:selectFirst("span.Hiatus") and NovelStatus.PAUSED
            or NovelStatus.PUBLISHING

    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("src") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a.property-item"), function(v)
            return v:text()
        end) or nil,
        status = s
    }

    -- Load chapters
    if loadChapters then
        local page = 1
        local chapters = {}

        while true do
            local chapterDoc = GETDocument(expandURL(novelURL) .. "/chapters?page=" .. page)
            if not chapterDoc then break end

            local items = chapterDoc:select("ul.chapter-list li a")
            if items:size() == 0 then break end

            for i = 0, items:size() - 1 do
                local a = items:get(i)

                local titleEl = a:selectFirst(".chapter-title")
                local dateEl = a:selectFirst("time.chapter-update")

                chapters[#chapters + 1] = NovelChapter {
                    order = #chapters + 1,
                    title = titleEl and titleEl:text():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1") or a:text(),
                    link = shrinkURL(a:attr("href")),
                    release = dateEl and dateEl:text() or nil
                }
            end

            page = page + 1
        end

        info:setChapters(AsList(chapters))
    end

    return info
end

-- =========================
-- GET PASSAGE
-- =========================

local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))
    local titleEl = doc:selectFirst("span.chapter-title")
    local title = titleEl and titleEl:text() or ""
    local content = doc:selectFirst("#content")
    if not content then return nil end
    content:select(".nf-ads, script, iframe, ins"):remove()
    content:child(0):before("<h1>" .. title .. "</h1>")
    return pageOfElem(content, true)
end


return {
    id = 134867,
    name = "Novel Fire",
    imageURL = NovelFireLogo,
    baseURL = baseURL,
    hasSearch = true,
    listings = {
        Listing("Latest", true, getListing),
    },
    searchFilters = searchFilters,
    parseNovel = parseNovel,
    getPassage = getPassage,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    chapterType = ChapterType.HTML,
    search = search
}