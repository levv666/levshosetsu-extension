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

local FILTER_SORT = 2
local FILTER_ORDER = 3

local FILTER_QUERY = 1
local FILTER_STATUS = 2
local FILTER_GENRE_ANDOR = 3
local FILTER_SORT_BY = 4
local FILTER_ORDER_BY = 5

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

---@param shortNum string
---@return number
local function expandNumber(shortNum)
	local number, suffix = shortNum:match("^(%d+%.?%d*)([kKmMbB]?)$")

	number = tonumber(number)
	if not number then return nil end

	if suffix == "k" or suffix == "K" then
		return math.floor(number * 1e3 + 0.5)
	elseif suffix == "m" or suffix == "M" then
		return math.floor(number * 1e6 + 0.5)
	elseif suffix == "b" or suffix == "B" then
		return math.floor(number * 1e9 + 0.5)
	else
		return math.floor(number + 0.5)
	end
end

---@param elements Elements
---@param stat string
---@return number | nil
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
	if elementToRemove then
		elementToRemove:remove()
	end
end

local function parse(doc)
	return map(doc:selectFirst("#page"):select(".wi_fic_wrap .search_main_box"), function(v)
		local body = v:selectFirst(".search_body")
		if body == nil then
			body = v
		end
		local t = v:selectFirst(".search_title a")
		local stats = body:select(".search_stats .nl_stat")
		local words = findStat(stats, "Words")
		local views = findStat(stats, "Views")
		local chapters = findStat(stats, "Chapters")
		local comments = findStat(stats, "Reviews")
		local favorites = findStat(stats, "Favorites")
		local genres = map(v:select(".search_genre .fic_genre"), function(g)
			return g:text()
		end)
		local author = v:selectFirst(".a_un_st"):text()
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

return {
	id = 86802,
	name = "ScribbleHub",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
	chapterType = ChapterType.HTML,
	hasCloudFlare = true,

	listings = {
		Listing("Novels", false, function(data)
			local sort = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			local order = data[FILTER_ORDER]
							and data[FILTER_ORDER] + 1
							or default_order[sort]

			return parse(GETDocument(qs({
				sort = sort, order = order
			}, baseURL .. "/series-ranking/")))
		end)
	},

	searchFilters = {
		DropdownFilter(FILTER_SORT, "Sort by", { "Popularity", "Favorites", "Activity", "Readers", "Rising" }),
		DropdownFilter(FILTER_ORDER, "Order", { "Daily", "Weekly", "Monthly", "All Time" })
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
		if s:match("Ongoing") then
			s = NovelStatus.PUBLISHING
		elseif s:match("Complete") then
			s = NovelStatus.COMPLETED
		elseif s:match("Hiatus") then
			s = NovelStatus.PAUSED
		else
			s = NovelStatus.UNKNOWN
		end

		local text = function(v) return v:text() end
		local info = NovelInfo {
			title = novel:selectFirst(".fic_title"):text(),
			imageURL = novel:selectFirst(".fic_image img"):attr("src"),
			description = HTMLToString(wrap:selectFirst(".wi_fic_desc")),
			genres = map(wrap:selectFirst(".wi_fic_genre"):select("a"), text),
			tags = map(wrap:selectFirst(".wi_fic_showtags"):select("a"), text),
			authors = { novel:selectFirst("span[property=name] .auth_name_fic"):text() },
			status = s
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

		-- Remove <p></p>.
		local toRemove = {}
		chap:traverse(NodeVisitor(function(v)
			if v:tagName() == "p" and v:childrenSize() == 0 and v:text() == "" then
				toRemove[#toRemove+1] = v
			end
			if v:hasAttr("border") then
				v:removeAttr("border")
			end
		end, nil, true))
		for _,v in pairs(toRemove) do
			v:remove()
		end

		-- Chapter title inserted before chapter text
		chap:child(0):before("<h1>" .. title .. "</h1>");

		return pageOfElem(chap, false, css)
	end,

	search = function(data)
		return parse(GETDocument(qs({
			s = data[QUERY], post_type = "fictionposts"
		}, baseURL .. "/")))
	end,
	isSearchIncrementing = false

    searchFilters = {
        TextFilter(FILTER_QUERY, "Title Contains"),
        DropdownFilter(FILTER_STATUS, "Story Status", { "All", "Completed", "Ongoing", "Hiatus" }),
        DropdownFilter(FILTER_GENRE_ANDOR, "Genre Mode", { "OR", "AND" }),
        DropdownFilter(FILTER_SORT_BY, "Sort By", { 
            "Pageviews", "Ratings", "Chapters", "Favorites", "Reviews", "Total Words", "Date Added" 
        }),
        DropdownFilter(FILTER_ORDER_BY, "Order", { "Descending", "Ascending" }),
        
        -- Genres Section
        SeparatorFilter("Genres"),
        CheckBoxFilter(10, "Action"), -- ID 9
        CheckBoxFilter(11, "Adult"), -- ID 902
        CheckBoxFilter(12, "Adventure"), -- ID 8
        CheckBoxFilter(13, "Boys Love"), -- ID 891
        CheckBoxFilter(14, "Comedy"), -- ID 7
        CheckBoxFilter(15, "Drama"), -- ID 903
        CheckBoxFilter(16, "Ecchi"), -- ID 904
        CheckBoxFilter(17, "Fanfiction"), -- ID 38
        CheckBoxFilter(18, "Fantasy"), -- ID 19
        CheckBoxFilter(19, "Gender Bender"), -- ID 905
        CheckBoxFilter(20, "Girls Love"), -- ID 892
        CheckBoxFilter(21, "Harem"), -- ID 1015
        CheckBoxFilter(22, "Historical"), -- ID 21
        CheckBoxFilter(23, "Horror"), -- ID 22
        CheckBoxFilter(24, "Isekai"), -- ID 37
        CheckBoxFilter(25, "Josei"), -- ID 906
        CheckBoxFilter(26, "LitRPG"), -- ID 1180
        CheckBoxFilter(27, "Martial Arts"), -- ID 907
        CheckBoxFilter(28, "Mature"), -- ID 20
        CheckBoxFilter(29, "Mystery"), -- ID 909
        CheckBoxFilter(30, "Psychological"), -- ID 910
        CheckBoxFilter(31, "Romance"), -- ID 6
        CheckBoxFilter(32, "School Life"), -- ID 911
        CheckBoxFilter(33, "Sci-fi"), -- ID 912
        CheckBoxFilter(34, "Seinen"), -- ID 913
        CheckBoxFilter(35, "Slice of Life"), -- ID 914
        CheckBoxFilter(36, "Sports"), -- ID 916
        CheckBoxFilter(37, "Supernatural"), -- ID 5
        CheckBoxFilter(38, "Tragedy"), -- ID 901
    },

    search = function(data)
        local queryParams = {}
        
        -- Basic Filters
        queryParams["seriescontains"] = data[FILTER_QUERY]
        
        local statusMap = { [1] = "all", [2] = "completed", [3] = "ongoing", [4] = "hiatus" }
        queryParams["fic_storystatus"] = statusMap[data[FILTER_STATUS] or 1]
        
        queryParams["gi_mm"] = (data[FILTER_GENRE_ANDOR] == 2) and "and" or "or"
        
        local sortMap = { 
            [1] = "pageviews", [2] = "ratings", [3] = "chapters", 
            [4] = "favorites", [5] = "reviews", [6] = "totalwords", [7] = "dateadded"
        }
        queryParams["sort"] = sortMap[data[FILTER_SORT_BY] or 1]
        queryParams["order"] = (data[FILTER_ORDER_BY] == 2) and "asc" or "desc"

        -- Genre Logic (gi[] parameter)
        local genres = {}
        local genreMap = {
            [10]=9, [11]=902, [12]=8, [13]=891, [14]=7, [15]=903, [16]=904,
            [17]=38, [18]=19, [19]=905, [20]=892, [21]=1015, [22]=21, [23]=22,
            [24]=37, [25]=906, [26]=1180, [27]=907, [28]=20, [29]=909, [30]=910,
            [31]=6, [32]=911, [33]=912, [34]=913, [35]=914, [36]=916, [37]=5, [38]=901
        }

        for filterId, siteId in pairs(genreMap) do
            if data[filterId] then
                table.insert(genres, tostring(siteId))
            end
        end

        -- Construct the URL
        local url = baseURL .. "/series-finder/?sf=1"
        if #genres > 0 then
            -- ScribbleHub needs multiple gi[] keys for multiple genres
            for _, gId in ipairs(genres) do
                url = url .. "&gi[]=" .. gId
            end
        end
        
        -- Append the rest of the query string
        url = url .. "&" .. qs(queryParams)

        return parse(GETDocument(url))
    end,
}
