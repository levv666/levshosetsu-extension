-- {"id":134867,"ver":"1.0.2","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://fenrirealm.com/"
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

    return mapNotNil(doc:select("div.grid.gap-5.py-5.grid-cols-1 > a.transition-all"), function(card)
        local linkEl  = card:selectFirst("h3")
        local titleEl = card:attr("href") or ""
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst(".mdthumb img")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(linkEl),
            imageURL = imgEl and imgEl:attr("src")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "series/?page=" .. page .. "&per_page=36&status=any&sort=latest"
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


return {
    id = 134867,
    name = "Fenrir Realm",
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