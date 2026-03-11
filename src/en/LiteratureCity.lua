-- {"id":1092721,"ver":"1.0.2","libVer":"1.0.0","author":"Lev616"}

local baseURL = "https://literaturecity.com"
local LiteratureCityLogo = "https://literaturecity.com/wp-content/uploads/2025/08/cropped-IMG_0460-1.png"
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

    return mapNotNil(doc:select("div.novel-list a"), function(card)
        local titleEl = card:selectFirst("p.novel-item-title")
        local imgEl = card:selectFirst("img.novel-item-Cover")

        return Novel {
            title = titleEl:text(),
            link = shrinkURL(card:attr("href") or ""),
            imageURL = imgEl and imgEl:attr("src")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local url = baseURL .. "/novels/page/" .. page .. "/?search&language&status&sort"
    return parseListing(url)
end

local function search(data)
    local query = data[QUERY] or ""
    local page  = data[PAGE] or 1
    local url = baseURL .. "/novels/page/" .. page .. "/?search=" .. query .. "&language&status&sort"

    local doc = GETDocument(url)
    return map(doc:select("div.novel-list a"), function(v)
        return Novel {
            title = v:selectFirst("p.novel-item-title"):text(),
            imageURL = v:selectFirst("img.novel-item-Cover"):attr("src"),
            link = shrinkURL(v:attr("href"))
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
    local titleElement = doc:selectFirst("h1.title")
    local imageElement = doc:selectFirst("div#novel_info_left img")
    local descriptionElement = doc:selectFirst("div.desc_div")
    local genrelist = doc:selectFirst("div#tags_div")

    local s = doc:selectFirst("span.Completed") and NovelStatus.COMPLETED
            or doc:selectFirst("span.Hiatus") and NovelStatus.PAUSED
            or NovelStatus.PUBLISHING


    local info = NovelInfo {
        title = titleElement and titleElement:text() or "No Title",
        imageURL = imageElement and imageElement:attr("src") or nil,
        description = descriptionElement and HTMLToString(descriptionElement) or "",
        genres = genrelist and map(genrelist:select("a.novel_genre"), function(v) return v:text() end) or nil,
        status = s
    }

    if loadChapters then
        local chapterItems = content:select("div.novel_index a.free_chap")

        local temp = map(chapterItems, function(v)
            return {
                title = v:text():gsub("%s+", " ")
                                :gsub("^%s*(.-)%s*$", "%1"),
                link = shrinkURL(v:attr("href")),
            }
        end)

        -- Remove nils
        temp = filter(temp, function(v) return v ~= nil end)

        -- Convert to Shosetsu List
        local chapters = AsList(map(temp, function(v, i)
            return NovelChapter {
                order = i,
                title = v.title,
                link = v.link,
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
    local title = htmlElement:selectFirst("h1.title"):text()
    htmlElement = htmlElement:selectFirst("article.small.single")
    htmlElement:select("script"):remove()
    htmlElement:select("style"):remove()
    htmlElement:select("#font-options-bar"):remove()
    htmlElement:select("#novel_nav"):remove()
    htmlElement:select("div.confuse"):remove()
    htmlElement:select("div.post-rating-wrapper"):remove()
    htmlElement:select("div#donation-msg"):remove()
    htmlElement:select("div#novel_nav"):remove()
    htmlElement:select("div.mycred-sell-this-wrapper"):remove()
    htmlElement:select("div.clearfix"):remove()
    htmlElement:select("nav.navigation.post-navigation"):remove()
    htmlElement:before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

return {
    id = 1092721,
    name = "Literature City",
    imageURL = LiteratureCityLogo,
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
