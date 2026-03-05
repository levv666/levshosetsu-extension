-- {"id":9915592,"ver":"1.1.1","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://pienovels.com"
local PieNovelsLogo = "https://pienovels.com/wp-content/uploads/2025/01/logo-pie-png.webp"
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

    return mapNotNil(doc:select("div.novel-grid div.novel-item"), function(card)
        local linkEl  = card:selectFirst("a")
        local titleEl = card:selectFirst("div.novel-content-text h1")
        if not (linkEl and titleEl) then return nil end

        local href = linkEl:attr("href") or ""
        local slug = href:match("/novels/([^/]+)/?")
        local title = slug and slug:gsub("-", " ") or titleEl:text()

        local imgEl = card:selectFirst("img")

        print("title : " .. title)
        print("link: " .. shrinkURL(linkEl:attr("href") or ""))
        print("img : " .. (imgEl and imgEl:attr("src")))

        return Novel {
            title = title,
            link = shrinkURL(linkEl:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("src")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/novels/?page=" .. page .. "&sort_by=latest_updated"
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
        imageURL = imageElement and imageElement:attr("src"):match("^[^?]+") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a[rel=tag]"), function(v) return v:text() end) or nil,
        status = s
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
    local htmlElement = GETDocument(expandURL(chapterURL))
    local title = htmlElement:selectFirst("h1.entry-title"):text()
    htmlElement = htmlElement:selectFirst("div.epcontent.entry-content")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:selectFirst("div.code-block"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

return {
    id = 9915592,
    name = "Pie Novels",
    imageURL = PieNovelsLogo,
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