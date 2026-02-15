-- {"id":86802,"ver":"1.2.9","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring

local css = Require("CommonCSS").table

local HTMLToString = Require("unhtml").HTMLToString

local function shrinkURL(url)
	return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end


local default_order = {
	[1] = 2, -- Popularity -> Weekly
	[2] = 4, -- Favorites -> All Time
	[3] = 2, -- Activity -> Weekly
	[4] = 2, -- Readers -> Weekly
	[5] = 1, -- Rising -> Daily
}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- Filter IDs
local FILTER_QUERY = 1
local FILTER_STATUS = 2
local FILTER_GENRE_ANDOR = 3
local FILTER_SORT_BY = 4
local FILTER_ORDER_BY = 5

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

local function shrinkURL(url)
    return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
    return baseURL .. "/" .. url
end

local function expandNumber(shortNum)
    local number, suffix = shortNum:match("^(%d+%.?%d*)([kKmMbB]?)$")
    number = tonumber(number)
    if not number then return nil end
    if suffix == "k" or suffix == "K" then return math.floor(number * 1e3 + 0.5)
    elseif suffix == "m" or suffix == "M" then return math.floor(number * 1e6 + 0.5)
    elseif suffix == "b" or suffix == "B" then return math.floor(number * 1e9 + 0.5)
    else return math.floor(number + 0.5) end
end

local function findStat(elements, stat)
    local matchDesktop = " " .. stat .."$"
    local matchMobile = "^" .. stat ..": "
    for i = 0, elements:size() - 1 do
        local part = elements:get(i):text()
        if part:match(matchDesktop) ~= nil or part:match(matchMobile) ~= nil then
            local number = part:gsub(matchDesktop, ""):gsub(matchMobile, ""):gsub(",", ""):gsub(" ", "")
            return expandNumber(number)
        end
    end
end

local function removeElements(element, attr)
    local elementToRemove = element:select(attr)
    if elementToRemove then elementToRemove:remove() end
end

local function parse(doc)
    return map(doc:selectFirst("#page"):select(".wi_fic_wrap .search_main_box"), function(v)
        local body = v:selectFirst(".search_body") or v
        local t = v:selectFirst(".search_title a")
        local stats = body:select(".search_stats .nl_stat")
        
        local genres = map(v:select(".search_genre .fic_genre"), function(g) return g:text() end)
        
        local element = body:selectFirst("> div:last-child")
        local description = ""
        if element then
            removeElements(element, ".dots")
            removeElements(element, ".morelink")
            description = HTMLToString(element)
        end

        return Novel {
            title = t:text(),
            link = t:attr("href"):match("/series/(%d+)"),
            imageURL = v:selectFirst(".search_img img"):attr("src"),
            wordCount = findStat(stats, "Words"),
            viewCount = findStat(stats, "Views"),
            chapterCount = findStat(stats, "Chapters"),
            commentCount = findStat(stats, "Reviews"),
            favoriteCount = findStat(stats, "Favorites"),
            genres = genres,
            description = description,
            authors = { v:selectFirst(".a_un_st"):text() }
        }
    end)
end

return {
    id = 86802,
    name = "ScribbleHub",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
    chapterType = ChapterType.HTML,
    hasCloudFlare = true,

    listings = {
        Listing("Novels", false, function(data)
            return parse(GETDocument(baseURL .. "/series-ranking/"))
        end)
    },

    searchFilters = {
        TextFilter(FILTER_QUERY, "Title Contains"),
        DropdownFilter(FILTER_STATUS, "Story Status", { "All", "Completed", "Ongoing", "Hiatus" }),
        DropdownFilter(FILTER_GENRE_ANDOR, "Genre Mode", { "OR", "AND" }),
        DropdownFilter(FILTER_SORT_BY, "Sort By", { "Pageviews", "Ratings", "Chapters", "Favorites", "Reviews", "Total Words" }),
        DropdownFilter(FILTER_ORDER_BY, "Order", { "Descending", "Ascending" }),
        SeparatorFilter("Genres"),
        CheckBoxFilter(10, "Action"), CheckBoxFilter(11, "Adult"), CheckBoxFilter(12, "Adventure"),
        CheckBoxFilter(13, "Boys Love"), CheckBoxFilter(14, "Comedy"), CheckBoxFilter(15, "Drama"),
        CheckBoxFilter(16, "Ecchi"), CheckBoxFilter(17, "Fanfiction"), CheckBoxFilter(18, "Fantasy"),
        CheckBoxFilter(19, "Gender Bender"), CheckBoxFilter(20, "Girls Love"), CheckBoxFilter(21, "Harem"),
        CheckBoxFilter(22, "Historical"), CheckBoxFilter(23, "Horror"), CheckBoxFilter(24, "Isekai"),
        CheckBoxFilter(25, "Josei"), CheckBoxFilter(26, "LitRPG"), CheckBoxFilter(27, "Martial Arts"),
        CheckBoxFilter(28, "Mature"), CheckBoxFilter(29, "Mystery"), CheckBoxFilter(30, "Psychological"),
        CheckBoxFilter(31, "Romance"), CheckBoxFilter(32, "School Life"), CheckBoxFilter(33, "Sci-fi"),
        CheckBoxFilter(34, "Seinen"), CheckBoxFilter(35, "Slice of Life"), CheckBoxFilter(36, "Sports"),
        CheckBoxFilter(37, "Supernatural"), CheckBoxFilter(38, "Tragedy")
    },

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    parseNovel = function(url, loadChapters)
        local doc = GETDocument(baseURL.."/series/"..url.."/a/"):selectFirst(".site-content-contain")
        local novel = doc:selectFirst("div[typeof=Book]")
        local wrap = novel:selectFirst(".box_fictionpage")
        local statusText = doc:selectFirst(".copyright ul"):select("li"):last():text()
        
        local s = NovelStatus.UNKNOWN
        if statusText:match("Ongoing") then s = NovelStatus.PUBLISHING
        elseif statusText:match("Complete") then s = NovelStatus.COMPLETED
        elseif statusText:match("Hiatus") then s = NovelStatus.PAUSED end

        local info = NovelInfo {
            title = novel:selectFirst(".fic_title"):text(),
            imageURL = novel:selectFirst(".fic_image img"):attr("src"),
            description = HTMLToString(wrap:selectFirst(".wi_fic_desc")),
            genres = map(wrap:selectFirst(".wi_fic_genre"):select("a"), function(v) return v:text() end),
            authors = { novel:selectFirst(".auth_name_fic"):text() },
            status = s
        }

        if loadChapters then
            local body = RequestBody("action=wi_getreleases_pagination&pagenum=-1&mypostid="..url, MTYPE)
            local cdoc = RequestDocument(POST(baseURL .. "/wp-admin/admin-ajax.php", HEADERS, body))
            local chapters = AsList(map(cdoc:selectFirst("ol"):select("li"), function(v)
                local a = v:selectFirst("a")
                return NovelChapter { order = v:attr("order"), title = a:text(), link = shrinkURL(a:attr("href")) }
            end))
            Reverse(chapters)
            info:setChapters(chapters)
        end
        return info
    end,

    getPassage = function(url)
        local chap = GETDocument(expandURL(url)):getElementById("main read chapter")
        local title = chap:selectFirst(".chapter-title"):text()
        local raw = chap:getElementById("chp_raw")
        raw:child(0):before("<h1>" .. title .. "</h1>")
        return pageOfElem(raw, false, css)
    end,

    search = function(data)
        local p = {}
        p["seriescontains"] = data[FILTER_QUERY]
        local sMap = { [1]="all", [2]="completed", [3]="ongoing", [4]="hiatus" }
        p["fic_storystatus"] = sMap[data[FILTER_STATUS] or 1]
        p["gi_mm"] = (data[FILTER_GENRE_ANDOR] == 2) and "and" or "or"
        local sortMap = { [1]="pageviews", [2]="ratings", [3]="chapters", [4]="favorites", [5]="reviews", [6]="totalwords" }
        p["sortval"] = sortMap[data[FILTER_SORT_BY] or 1]
        p["order"] = (data[FILTER_ORDER_BY] == 2) and "asc" or "desc"

        local url = baseURL .. "/series-finder/?sf=1"
        local gMap = { [10]=9, [11]=902, [12]=8, [13]=891, [14]=7, [15]=903, [16]=904, [17]=38, [18]=19, [19]=905, [20]=892, [21]=1015, [22]=21, [23]=22, [24]=37, [25]=906, [26]=1180, [27]=907, [28]=20, [29]=909, [30]=910, [31]=6, [32]=911, [33]=912, [34]=913, [35]=914, [36]=916, [37]=5, [38]=901 }
        for fid, sid in pairs(gMap) do
            if data[fid] then url = url .. "&gi[]=" .. sid end
        end
        return parse(GETDocument(url .. "&" .. qs(p)))
    end
}