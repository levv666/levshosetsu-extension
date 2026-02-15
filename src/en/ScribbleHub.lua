-- {"id":86802,"ver":"1.1.4","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- --- CONSTANTS & DATA ---

local QUERY = 1

-- Filter Keys (Start high to avoid conflicts)
local FILTER_SORT = 100
local FILTER_ORDER = 101
local FILTER_STATUS = 102
local FILTER_TAG_TEXT = 103

local GENRE_FILTER_KEY = 200
local WARNING_FILTER_KEY = 300

-- ScribbleHub Genre IDs
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

-- Ordered list for display
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
local ORDER_KEYS = { "daily", "weekly", "monthly", "alltime" } 

-- --- HELPERS ---

-- Helper to safely use TriStateFilter if available, otherwise fallback to Checkbox
local function TriStateFilter_(int, str)
	if TriStateFilter then
		return TriStateFilter(int, str)
	else
		return CheckboxFilter(int, str)
	end
end

local function MultiTriStateFilter(offset, names, stop)
	local f = {}
	for i = 1, stop do
		table.insert(f, TriStateFilter_(offset + i, names[i]))
	end
	return f
end

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

-- --- PARSERS ---

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

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

-- --- MAIN OBJECT ---

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
		local tagInput = data[FILTER_TAG_TEXT]

		-- 1. SEARCH BY TAG NAME
		if tagInput and tagInput ~= "" then
			local tagSlug = tagInput:lower():gsub(" ", "-")
			local sortIdx = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			return parse(GETDocument(qs({
				sort = SORT_KEYS[sortIdx],
				order = "desc"
			}, baseURL .. "/tag/" .. tagSlug .. "/")))
		end

		-- 2. SERIES FINDER / STANDARD SEARCH
		-- Logic: If filters are used, use Series Finder. Else, use basic search.
		
		-- Collect Tri-State Filter Data
		local gi, ge, cti, cte = {}, {}, {}, {}
		
		-- Helper to process Tri-State values
		local function ProcessTriState(list, startKey, mapping, incTable, excTable)
			for i, name in ipairs(list) do
				local val = data[startKey + i]
				if val == 1 then -- 1 = Include (Green)
					table.insert(incTable, mapping[name])
				elseif val == 2 then -- 2 = Exclude (Red)
					table.insert(excTable, mapping[name])
				end
			end
		end

		ProcessTriState(GENRE_LIST, GENRE_FILTER_KEY, GENRES, gi, ge)
		ProcessTriState(WARNING_LIST, WARNING_FILTER_KEY, WARNINGS, cti, cte)
		
		local hasFilters = (#gi > 0 or #ge > 0 or #cti > 0 or #cte > 0 or data[FILTER_STATUS])

		if (not query or query == "") and hasFilters then
			local params = { sf = 1 }
			
			if #gi > 0 then params["gi"] = table.concat(gi, ",") params["mgi"] = "or" end
			if #ge > 0 then params["ge"] = table.concat(ge, ",") params["mge"] = "or" end
			if #cti > 0 then params["cti"] = table.concat(cti, ",") end
			-- Note: Series Finder URL usually doesn't have explicit Exclude for Warnings (cte), 
			-- but we supported the logic just in case.

			local statusIdx = data[FILTER_STATUS]
			if statusIdx == 1 then params["sto"] = "completed"
			elseif statusIdx == 2 then params["sto"] = "ongoing"
			elseif statusIdx == 3 then params["sto"] = "hiatus"
			end

			local sortIdx = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			params["sort"] = SORT_KEYS[sortIdx]
			params["order"] = "desc"

			return parse(GETDocument(qs(params, baseURL .. "/series-finder/")))
		else
			return parse(GETDocument(qs({
				s = query,
				post_type = "fictionposts"
			}, baseURL .. "/")))
		end
	end,
	
	isSearchIncrementing = false,
	
	searchFilters = {
		DropdownFilter(FILTER_SORT, "Sort by", { "Popularity", "Favorites", "Activity", "Readers", "Rising" }),
		DropdownFilter(FILTER_ORDER, "Order", { "Daily", "Weekly", "Monthly", "All Time" }),
		DropdownFilter(FILTER_STATUS, "Status", { "All", "Completed", "Ongoing", "Hiatus" }),
		InputFilter(FILTER_TAG_TEXT, "Tag (Exact Name)", ""),
		
		FilterGroup("Genres (Click x2 to Exclude)", MultiTriStateFilter(GENRE_FILTER_KEY, GENRE_LIST, #GENRE_LIST)),
		FilterGroup("Content Warnings", MultiTriStateFilter(WARNING_FILTER_KEY, WARNING_LIST, #WARNING_LIST))
	}
}