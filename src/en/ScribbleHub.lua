-- {"id":86802,"ver":"1.2.0","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"

local qs = Require("url").querystring
local HTMLToString = Require("unhtml").HTMLToString
local css = Require("CommonCSS").table

-- --- CONSTANTS & MAPPINGS ---

local GENRES_FILTER_EXT = {
    "Action", "Adult", "Adventure", "Boys Love", "Comedy", "Drama", "Ecchi", "Fanfiction",
    "Fantasy", "Gender Bender", "Girls Love", "Harem", "Historical", "Horror", "Isekai",
    "Josei", "LitRPG", "Martial Arts", "Mature", "Mecha", "Mystery", "Psychological",
    "Romance", "School Life", "Sci-fi", "Seinen", "Slice of Life", "Smut", "Sports",
    "Supernatural", "Tragedy"
}
local GENRES_FILTER_KEY = 200
local GENRES_FILTER_INT = { -- Map to ScribbleHub IDs
    [GENRES_FILTER_KEY+1] = 9,    [GENRES_FILTER_KEY+2] = 902,  [GENRES_FILTER_KEY+3] = 8,
    [GENRES_FILTER_KEY+4] = 891,  [GENRES_FILTER_KEY+5] = 7,    [GENRES_FILTER_KEY+6] = 903,
    [GENRES_FILTER_KEY+7] = 904,  [GENRES_FILTER_KEY+8] = 38,   [GENRES_FILTER_KEY+9] = 19,
    [GENRES_FILTER_KEY+10] = 905, [GENRES_FILTER_KEY+11] = 892, [GENRES_FILTER_KEY+12] = 1015,
    [GENRES_FILTER_KEY+13] = 21,  [GENRES_FILTER_KEY+14] = 22,  [GENRES_FILTER_KEY+15] = 37,
    [GENRES_FILTER_KEY+16] = 906, [GENRES_FILTER_KEY+17] = 1180, [GENRES_FILTER_KEY+18] = 907,
    [GENRES_FILTER_KEY+19] = 20,  [GENRES_FILTER_KEY+20] = 908,  [GENRES_FILTER_KEY+21] = 909,
    [GENRES_FILTER_KEY+22] = 910, [GENRES_FILTER_KEY+23] = 6,    [GENRES_FILTER_KEY+24] = 911,
    [GENRES_FILTER_KEY+25] = 912, [GENRES_FILTER_KEY+26] = 913,  [GENRES_FILTER_KEY+27] = 914,
    [GENRES_FILTER_KEY+28] = 915, [GENRES_FILTER_KEY+29] = 916,  [GENRES_FILTER_KEY+30] = 5,
    [GENRES_FILTER_KEY+31] = 901
}

local WARNINGS_FILTER_EXT = {"Gore", "Sexual Content", "Strong Language"}
local WARNINGS_FILTER_KEY = 400
local WARNINGS_FILTER_INT = {
    [WARNINGS_FILTER_KEY+1] = 48,
    [WARNINGS_FILTER_KEY+2] = 49,
    [WARNINGS_FILTER_KEY+3] = 50
}

local STATUS_FILTER_EXT = {"All", "Completed", "Ongoing", "Hiatus"}
local STATUS_FILTER_KEY = 600
local STATUS_FILTER_INT = {
    [STATUS_FILTER_KEY+1] = "all",
    [STATUS_FILTER_KEY+2] = "completed",
    [STATUS_FILTER_KEY+3] = "ongoing",
    [STATUS_FILTER_KEY+4] = "hiatus"
}

local SORT_FILTER_EXT = {"Popularity", "Favorites", "Activity", "Readers", "Rising"}
local SORT_FILTER_KEY = 700
local SORT_FILTER_INT = {
    [0] = "pageviews", -- Default
    "favorites",
    "activity",
    "readers",
    "rising"
}

local ORDER_FILTER_EXT = {"Daily", "Weekly", "Monthly", "All Time"}
local ORDER_FILTER_KEY = 800
local ORDER_FILTER_INT = {
    [0] = "daily",
    "weekly",
    "monthly",
    "alltime"
}

local TAG_SEARCH_KEY = 900 -- Text input for exact tag search

-- --- HELPER FUNCTIONS (RoyalRoad Style) ---

local function shrinkURL(url)
    return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
    return baseURL .. "/" .. url
end

local function TriStateFilter_(int, str)
    if TriStateFilter then
        return TriStateFilter(int, str)
    else
        return CheckboxFilter(int, str)
    end
end

local function MultiTriStateFilter(offset, filter_ext, stop)
    local f={}
    for i=1,stop do
        f[#f+1] = TriStateFilter_(offset+i, filter_ext[i])
    end
    return f
end

local function createFilterString(data)
    -- 1. Check for Tag Search (Overrides everything)
    if data[TAG_SEARCH_KEY] and data[TAG_SEARCH_KEY] ~= "" then
        local tag = data[TAG_SEARCH_KEY]:gsub(" ", "-")
        return "/tag/" .. tag .. "/"
    end

    -- 2. Build Series Finder Params
    local params = { sf = 1 }

    -- Genres (Include/Exclude)
    local gi = {}
    local ge = {}
    for i=1, #GENRES_FILTER_EXT do
        local val = data[GENRES_FILTER_KEY+i]
        if val == 1 then table.insert(gi, GENRES_FILTER_INT[GENRES_FILTER_KEY+i])
        elseif val == 2 then table.insert(ge, GENRES_FILTER_INT[GENRES_FILTER_KEY+i])
        end
    end
    if #gi > 0 then params["gi"] = table.concat(gi, ",") params["mgi"] = "or" end
    if #ge > 0 then params["ge"] = table.concat(ge, ",") params["mge"] = "or" end

    -- Warnings (Include only for now, mapped to ScribbleHub logic)
    local cti = {}
    for i=1, #WARNINGS_FILTER_EXT do
        if data[WARNINGS_FILTER_KEY+i] == 1 then
            table.insert(cti, WARNINGS_FILTER_INT[WARNINGS_FILTER_KEY+i])
        end
    end
    if #cti > 0 then params["cti"] = table.concat(cti, ",") end

    -- Status
    if data[STATUS_FILTER_KEY] then
        params["sto"] = STATUS_FILTER_INT[STATUS_FILTER_KEY + data[STATUS_FILTER_KEY] + 1] -- fix 0-index offset
    end

    -- Sort & Order
    if data[SORT_FILTER_KEY] then
        params["sort"] = SORT_FILTER_INT[data[SORT_FILTER_KEY]]
    else
        params["sort"] = "pageviews"
    end
    
    if data[ORDER_FILTER_KEY] then
        params["order"] = ORDER_FILTER_INT[data[ORDER_FILTER_KEY]]
    else
         params["order"] = "desc" -- Series finder default
    end

    -- Query
    if data[QUERY] and data[QUERY] ~= "" then
         -- ScribbleHub Series Finder doesn't support text query easily + filters
         -- We fallback to standard search if ONLY query is present, handled in search()
    end

    return "/series-finder/?" .. qs(params)
end

-- --- PARSING ---

local function expandNumber(shortNum)
	local number, suffix = shortNum:match("^(%d+%.?%d*)([kKmMbB]?)$")
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

local function parseListing(doc)
    -- Determine selector based on page type
	local container = doc:selectFirst("#page")
	local boxes = container:select(".wi_fic_wrap .search_main_box")
	if boxes:isEmpty() then boxes = container:select(".search_main_box") end

	return map(boxes, function(v)
		local body = v:selectFirst(".search_body")
		if body == nil then body = v end
		
		local t = v:selectFirst(".search_title a")
		local stats = body:select(".search_stats .nl_stat")
		local words = findStat(stats, "Words")
		local views = findStat(stats, "Views")
		local chapters = findStat(stats, "Chapters")
		local comments = findStat(stats, "Reviews")
		local favorites = findStat(stats, "Favorites")
		local genres = map(v:select(".search_genre .fic_genre"), function(g) return g:text() end)
		local authorElem = v:selectFirst(".a_un_st")
		local author = authorElem and authorElem:text() or "Unknown"
		
		local description = body:ownText()
		if description == nil or description:len() == 0 then
			local element = body:selectFirst("> div:last-child")
			if element then
				removeElements(element, ".dots")
				removeElements(element, ".morelink")
				description = HTMLToString(element)
			end
		else
			removeElements(body, ".dots")
			removeElements(body, ".morelink")
			removeElements(body, ".search_title")
			removeElements(body, ".search_stats")
			removeElements(body, ".search_genre")
			description = HTMLToString(body)
		end

		return Novel {
			title = t:text(),
			link = t:attr("href"):match("/series/(%d+)"),
			imageURL = v:selectFirst(".search_img img"):attr("src"),
			wordCount = words,
			viewCount = views,
			chapterCount = chapters,
			commentCount = comments,
			favoriteCount = favorites,
			genres = genres,
			description = description,
			authors = { author }
		}
	end)
end

-- --- MAIN OBJECT ---

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

return {
    id = 86802,
    name = "ScribbleHub",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
    chapterType = ChapterType.HTML,
    hasCloudFlare = true,

    listings = {
        Listing("Popular (Weekly)", false, function(data)
            return parseListing(GETDocument(qs({ sort = 1, order = 2 }, baseURL .. "/series-ranking/")))
        end),
        Listing("Latest Series", true, function(data)
            return parseListing(GETDocument(baseURL .. "/latest-series/"))
        end)
    },

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    parseNovel = function(url, loadChapters)
        local doc = GETDocument(baseURL.."/series/"..url.."/a/"):selectFirst(".site-content-contain")
		local novel = doc:selectFirst("div[typeof=Book]")
		local wrap = novel:selectFirst(".box_fictionpage")
		removeElements(wrap, ".dots")
		removeElements(wrap, ".morelink")
		
		local s = doc:selectFirst(".copyright ul"):children()
		s = s:get(s:size() - 1):children()
		s = s:get(s:size() - 1)
		s = s:ownText()
		
		local status = NovelStatus.UNKNOWN
		if s:match("Ongoing") then status = NovelStatus.PUBLISHING
		elseif s:match("Complete") then status = NovelStatus.COMPLETED
		elseif s:match("Hiatus") then status = NovelStatus.PAUSED
		end

		local text = function(v) return v:text() end
		local info = NovelInfo {
			title = novel:selectFirst(".fic_title"):text(),
			imageURL = novel:selectFirst(".fic_image img"):attr("src"),
			description = HTMLToString(wrap:selectFirst(".wi_fic_desc")),
			genres = map(wrap:selectFirst(".wi_fic_genre"):select("a"), text),
			tags = map(wrap:selectFirst(".wi_fic_showtags"):select("a"), text),
			authors = { novel:selectFirst("span[property=name] .auth_name_fic"):text() },
			status = status
		}

		if loadChapters then
			local body = RequestBody("action=wi_getreleases_pagination&pagenum=-1&mypostid="..url, MTYPE)
			local cdoc = RequestDocument(POST("https://www.scribblehub.com/wp-admin/admin-ajax.php", HEADERS, body))
			local chapters = AsList(map(cdoc:selectFirst("ol"):select("li"), function(v, i)
				local a = v:selectFirst("a")
				return NovelChapter {
					order = v:attr("order"),
					title = a:text(),
					link = shrinkURL(a:attr("href"))
				}
			end))
			Reverse(chapters)
			info:setChapters(chapters)
		end

		return info
    end,

    getPassage = function(url)
        local chap = GETDocument(expandURL(url)):getElementById("main read chapter")
		local title = chap:selectFirst(".chapter-title"):text()
		chap = chap:getElementById("chp_raw")

		local toRemove = {}
		chap:traverse(NodeVisitor(function(v)
			if v:tagName() == "p" and v:childrenSize() == 0 and v:text() == "" then
				toRemove[#toRemove+1] = v
			end
			if v:hasAttr("border") then v:removeAttr("border") end
		end, nil, true))
		for _,v in pairs(toRemove) do v:remove() end

		chap:child(0):before("<h1>" .. title .. "</h1>");
		return pageOfElem(chap, false, css)
    end,

    search = function(data)
        -- Fallback to standard search if just Query is present
        if (data[QUERY] and data[QUERY] ~= "") and not (data[TAG_SEARCH_KEY] or data[GENRES_FILTER_KEY+1]) then
             return parseListing(GETDocument(qs({
				s = data[QUERY],
				post_type = "fictionposts"
			}, baseURL .. "/")))
        end

        local filterString = createFilterString(data)
        return parseListing(GETDocument(baseURL .. filterString))
    end,
    
    isSearchIncrementing = false,

    searchFilters = {
        TextFilter(TAG_SEARCH_KEY, "Tag Search (Exact Name)"),
        FilterGroup("Genres", MultiTriStateFilter(GENRES_FILTER_KEY, GENRES_FILTER_EXT, #GENRES_FILTER_EXT)),
        FilterGroup("Content Warnings", MultiTriStateFilter(WARNINGS_FILTER_KEY, WARNINGS_FILTER_EXT, #WARNINGS_FILTER_EXT)),
        DropdownFilter(STATUS_FILTER_KEY, "Status", STATUS_FILTER_EXT),
        DropdownFilter(SORT_FILTER_KEY, "Sort By", SORT_FILTER_EXT),
        DropdownFilter(ORDER_FILTER_KEY, "Order", ORDER_FILTER_EXT),
    }
}