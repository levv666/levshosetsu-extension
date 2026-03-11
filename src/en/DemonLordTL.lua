-- {"id":4249881,"ver":"1.0.9","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://demonlordtl.com"
local DemonLordTLLogo = "https://demonlordtl.com/wp-content/uploads/2025/05/new.png"
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

    return mapNotNil(doc:select("div.listupd article"), function(card)
        local linkEl  = card:selectFirst("h2 a")
        local titleEl = card:selectFirst("h2 a")
        if not (linkEl and titleEl) then return nil end

        local imgEl = card:selectFirst(".mdthumb img")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(linkEl:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("src")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/series/?page=" .. page .. "&status=&type=&order=update"
    return parseListing(url)
end

local function search(data)
    local query = data[QUERY] or ""
    local page  = data[PAGE] or 1
    local url = baseURL .. "/page/" .. page .. "/?s=" .. query

    local doc = GETDocument(url)
    return map(doc:select("div.listupd article"), function(v)
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
        local freeHeader = content:selectFirst('span.ts-chl-collapsible:matchesOwn(^Chapters$)')
        local chapterItems = freeHeader and freeHeader:nextElementSibling():select("li[data-id]") or content:select("li[data-id]")

        local temp = map(chapterItems, function(v)
            local dataId = tonumber(v:attr("data-id"))
            if not dataId then return nil end
            local a = v:selectFirst("a")
            local titleDiv = a:selectFirst("div.epl-title")
            local number = a:selectFirst("div.epl-num")

            -- Extract numeric chapter number
            local chapterNumber = 0
            if number then
                local numText = number:text()
                -- Extract digits from "Ch. 117" or similar
                chapterNumber = tonumber(numText:match("%d+")) or 0
            end

            local titleText = (number and number:text() or "") .. " - " .. (titleDiv and titleDiv:text() or "")
            local dateDiv = a:selectFirst("div.epl-date")

            return {
                chapterNumber = chapterNumber,
                title = titleText
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
            return a.chapterNumber < b.chapterNumber
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
    local title = htmlElement:selectFirst("div.cat-series"):text()
    local content = htmlElement:selectFirst("div.epcontent.entry-content")
    local html = content:html()
    html = html:gsub("<br%s*/?>", "</p><p>")
    content:html(html)
    content:select("#wrap-button-remove-blur"):remove()
    content:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(content, true)
end

return {
    id = 4249881,
    name = "Demon Lord Translation",
    imageURL = DemonLordTLLogo,
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