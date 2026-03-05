-- {"id":134867,"ver":"1.0.4","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://novelfire.net"
local FenrirLogo = "https://fenrirealm.com/img/logo/fenrir-logo.png"
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
    local content = doc:selectFirst("main#primary") or doc

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
        imageURL = imageElement and expandURL(imageElement:attr("src")) or nil,
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
    local htmlElement = GETDocument(expandURL(chapterURL))
    local title = htmlElement:selectFirst("h1.entry-title"):text()
    htmlElement = htmlElement:selectFirst("div.epcontent.entry-content")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:selectFirst("div.code-block"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end


return {
    id = 134867,
    name = "Novel Fire",
    imageURL = FenrirLogo,
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