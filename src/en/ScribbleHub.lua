-- {"id":86802,"ver":"1.1.2","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- --- Constants & IDs ---

local QUERY = 1

-- Filter IDs
local FILTER_SORT = 2
local FILTER_ORDER = 3
local FILTER_STATUS = 4
local FILTER_TAG = 5

-- ID Ranges for Checkboxes (Start ID)
local ID_WARN_START = 100
local ID_GENRE_INC_START = 200
local ID_GENRE_EXC_START = 300

-- --- Data Mappings ---

local GENRES = {
	["Action"] = 9, ["Adult"] = 902, ["Adventure"] = 8, ["Boys Love"] = 891,
	["Comedy"] = 7, ["Drama"] = 903, ["Ecchi"] = 904, ["Fanfiction"] = 38,
	["Fantasy"] = 19, ["Gender Bender"] = 905, ["Girls Love"] = 892, ["Harem"] = 1015,
	["Historical"] = 21, ["Horror"] = 22, ["Isekai"] = 37, ["Josei"] = 906,
	["LitRPG"] = 1180, ["Martial Arts"] = 907, ["Mature"] = 20, ["Mecha"] = 908,
	["Mystery"] = 909, ["Psychological"] = 910, ["Romance"] = 6, ["School Life"] = 911,
	["Sci-fi"] = 912, ["Seinen"] = 913, ["Slice of Life"] = 914, ["Smut"] = 915,
	["Sports"] = 916, ["Supernatural"] = 5, ["Tragedy"] = 901
}

local GENRE_LIST = {
	"Action", "Adult", "Adventure", "Boys Love", "Comedy", "Drama", "Ecchi", "Fanfiction",
	"Fantasy", "Gender Bender", "Girls Love", "Harem", "Historical", "Horror", "Isekai",
	"Josei", "LitRPG", "Martial Arts", "Mature", "Mecha", "Mystery", "Psychological",
	"Romance", "School Life", "Sci-fi", "Seinen", "Slice of Life", "Smut", "Sports",
	"Supernatural", "Tragedy"
}

local WARNINGS = {
	["Gore"] = 48,
	["Sexual Content"] = 49,
	["Strong Language"] = 50
}
local WARNING_LIST = { "Gore", "Sexual Content", "Strong Language" }

local SORT_KEYS = { "pageviews", "favorites", "activity", "readers", "rising" }

-- --- Helper Functions ---

local function map(list, func)
	local new_list = {}
	for i, v in ipairs(list) do
		local res = func(v, i)
		if res ~= nil then table.insert(new_list, res) end
	end
	return new_list
end

local function shrinkURL(url)
	return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

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

-- --- Parsers ---

local function parse(doc)
	local container = doc:selectFirst("#page")
	local boxes = container:select(".wi_fic_wrap .search_main_box")
	if boxes:isEmpty() then boxes = container:select(".search_main_box") end

	return map(AsList(boxes), function(v)
		local body = v:selectFirst(".search_body")
		if body == nil then body = v end
		
		local t = v:selectFirst(".search_title a")
		local stats = body:select(".search_stats .nl_stat")
		local words = findStat(stats, "Words")
		local views = findStat(stats, "Views")
		local chapters = findStat(stats, "Chapters")
		local comments = findStat(stats, "Reviews")
		local favorites = findStat(stats, "Favorites")
		local genres = map(AsList(v:select(".search_genre .fic_genre")), function(g) return g:text() end)
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

-- --- Build Filter List Procedurally ---
-- We do this to avoid using 'FilterGroup' which caused the crash, 
-- and to ensure we use standard Filter.Check + Filter.Header

local searchFiltersList = {
	Filter.Select(FILTER_SORT, "Sort by", { "Popularity", "Favorites", "Activity", "Readers", "Rising" }),
	Filter.Select(FILTER_ORDER, "Order", { "Daily", "Weekly", "Monthly", "All Time" }),
	Filter.Select(FILTER_STATUS, "Status", { "All", "Completed", "Ongoing", "Hiatus" }),
	Filter.Text(FILTER_TAG, "Tag (Exact Name)", ""),
	Filter.Separator()
}

-- Add Warnings
table.insert(searchFiltersList, Filter.Header("Content Warnings (Include)"))
for i, name in ipairs(WARNING_LIST) do
	table.insert(searchFiltersList, Filter.Check(ID_WARN_START + i, name))
end

-- Add Genres Include
table.insert(searchFiltersList, Filter.Header("Genres (Include)"))
for i, name in ipairs(GENRE_LIST) do
	table.insert(searchFiltersList, Filter.Check(ID_GENRE_INC_START + i, name))
end

-- Add Genres Exclude
table.insert(searchFiltersList, Filter.Header("Genres (Exclude)"))
for i, name in ipairs(GENRE_LIST) do
	table.insert(searchFiltersList, Filter.Check(ID_GENRE_EXC_START + i, name))
end


-- --- Main Extension Object ---

return {
	id = 86802,
	name = "ScribbleHub",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
	chapterType = ChapterType.HTML,
	hasCloudFlare = true,

	listings = {
		Listing("Popular (Weekly)", false, function(data)
			return parse(GETDocument(qs({ sort = 1, order = 2 }, baseURL .. "/series-ranking/")))
		end),
		Listing("Latest Series", true, function(data)
			return parse(GETDocument(baseURL .. "/latest-series/"))
		end)
	},

	searchFilters = searchFiltersList,

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
			genres = map(AsList(wrap:selectFirst(".wi_fic_genre"):select("a")), text),
			tags = map(AsList(wrap:selectFirst(".wi_fic_showtags"):select("a")), text),
			authors = { novel:selectFirst("span[property=name] .auth_name_fic"):text() },
			status = status
		}

		if loadChapters then
			local body = RequestBody("action=wi_getreleases_pagination&pagenum=-1&mypostid="..url, MTYPE)
			local cdoc = RequestDocument(POST("https://www.scribblehub.com/wp-admin/admin-ajax.php", HEADERS, body))
			local chapters = AsList(map(AsList(cdoc:selectFirst("ol"):select("li")), function(v, i)
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
		local query = data[QUERY]
		local tagInput = data[FILTER_TAG]

		-- Check if any advanced filters are active
		local hasWarnings = false
		local hasGenres = false
		
		-- Helper to check ID ranges
		for i=1, #WARNING_LIST do if data[ID_WARN_START + i] then hasWarnings = true break end end
		for i=1, #GENRE_LIST do if data[ID_GENRE_INC_START + i] or data[ID_GENRE_EXC_START + i] then hasGenres = true break end end

		-- 1. TAG SEARCH MODE
		if tagInput and tagInput ~= "" then
			local tagSlug = tagInput:lower():gsub(" ", "-")
			local sortIdx = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			local sortKey = SORT_KEYS[sortIdx]
			return parse(GETDocument(qs({
				sort = sortKey,
				order = "desc"
			}, baseURL .. "/tag/" .. tagSlug .. "/")))

		-- 2. SERIES FINDER MODE
		elseif (not query or query == "") and (hasWarnings or hasGenres or data[FILTER_STATUS]) then
			local params = { sf = 1 }
			
			-- Collect Genres Include
			local gi = {}
			for i, name in ipairs(GENRE_LIST) do
				if data[ID_GENRE_INC_START + i] then table.insert(gi, GENRES[name]) end
			end
			if #gi > 0 then params["gi"] = table.concat(gi, ",") params["mgi"] = "or" end
			
			-- Collect Genres Exclude
			local ge = {}
			for i, name in ipairs(GENRE_LIST) do
				if data[ID_GENRE_EXC_START + i] then table.insert(ge, GENRES[name]) end
			end
			if #ge > 0 then params["ge"] = table.concat(ge, ",") params["mge"] = "or" end
			
			-- Collect Warnings
			local cti = {}
			for i, name in ipairs(WARNING_LIST) do
				if data[ID_WARN_START + i] then table.insert(cti, WARNINGS[name]) end
			end
			if #cti > 0 then params["cti"] = table.concat(cti, ",") end

			-- Status
			local statusIdx = data[FILTER_STATUS]
			if statusIdx == 1 then params["sto"] = "completed"
			elseif statusIdx == 2 then params["sto"] = "ongoing"
			elseif statusIdx == 3 then params["sto"] = "hiatus"
			end

			-- Sort
			local sortIdx = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			params["sort"] = SORT_KEYS[sortIdx]
			params["order"] = "desc"

			return parse(GETDocument(qs(params, baseURL .. "/series-finder/")))

		-- 3. STANDARD SEARCH MODE
		else
			return parse(GETDocument(qs({
				s = query,
				post_type = "fictionposts"
			}, baseURL .. "/")))
		end
	end,
	
	isSearchIncrementing = false
}