-- {"id":86802,"ver":"1.1.2","libVer":"1.0.0","author":"TechnoJo4, StormX4 (updated by lev666)","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

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

local FILTER_GENRE = 4
local FILTER_GENRE_MODE = 5

local default_order = {
	[1] = 2, -- Popularity -> Weekly
	[2] = 4, -- Favorites -> All Time
	[3] = 2, -- Activity -> Weekly
	[4] = 2, -- Readers -> Weekly
	[5] = 1, -- Rising -> Daily
}

local FILTER_SORT = 6
local FILTER_ORDER = 7

local SORT_VALUES = {
    "chapters",
    "frequency",
    "dateadded",
    "favorites",
    "lastchpdate",
    "numofrate",
    "pages",
    "pageviews",
    "ratings",
    "readers",
    "reviews",
    "totalwords"
}


local FILTER_GENRE_ACTION        = 100
local FILTER_GENRE_ADULT         = 101
local FILTER_GENRE_ADVENTURE     = 102
local FILTER_GENRE_BOYS_LOVE     = 103
local FILTER_GENRE_COMEDY        = 104
local FILTER_GENRE_DRAMA         = 105
local FILTER_GENRE_ECCHI         = 106
local FILTER_GENRE_FANFICTION    = 107
local FILTER_GENRE_FANTASY       = 108
local FILTER_GENRE_GENDER_BENDER = 109
local FILTER_GENRE_GIRLS_LOVE    = 110
local FILTER_GENRE_HAREM         = 111
local FILTER_GENRE_HISTORICAL    = 112
local FILTER_GENRE_HORROR        = 113
local FILTER_GENRE_ISEKAI        = 114
local FILTER_GENRE_JOSEI         = 115
local FILTER_GENRE_LITRPG        = 116
local FILTER_GENRE_MARTIAL_ARTS  = 117
local FILTER_GENRE_MATURE        = 118
local FILTER_GENRE_MECHA         = 119
local FILTER_GENRE_MYSTERY       = 120
local FILTER_GENRE_PSYCHOLOGICAL = 121
local FILTER_GENRE_ROMANCE       = 122
local FILTER_GENRE_SCHOOL_LIFE   = 123
local FILTER_GENRE_SCI_FI        = 124
local FILTER_GENRE_SEINEN        = 125
local FILTER_GENRE_SLICE_OF_LIFE = 126
local FILTER_GENRE_SMUT          = 127
local FILTER_GENRE_SPORTS        = 128
local FILTER_GENRE_SUPERNATURAL  = 129
local FILTER_GENRE_TRAGEDY       = 130

local GENRE_FILTERS = {
        { filterId = FILTER_GENRE_ACTION,        gi = "9"    }, -- Action
        { filterId = FILTER_GENRE_ADULT,         gi = "902"  }, -- Adult
        { filterId = FILTER_GENRE_ADVENTURE,     gi = "8"    }, -- Adventure
        { filterId = FILTER_GENRE_BOYS_LOVE,     gi = "891"  }, -- Boys Love
        { filterId = FILTER_GENRE_COMEDY,        gi = "7"    }, -- Comedy
        { filterId = FILTER_GENRE_DRAMA,         gi = "903"  }, -- Drama
        { filterId = FILTER_GENRE_ECCHI,         gi = "904"  }, -- Ecchi
        { filterId = FILTER_GENRE_FANFICTION,    gi = "38"   }, -- Fanfiction
        { filterId = FILTER_GENRE_FANTASY,       gi = "19"   }, -- Fantasy
        { filterId = FILTER_GENRE_GENDER_BENDER, gi = "905"  }, -- Gender Bender
        { filterId = FILTER_GENRE_GIRLS_LOVE,    gi = "892"  }, -- Girls Love
        { filterId = FILTER_GENRE_HAREM,         gi = "1015" }, -- Harem
        { filterId = FILTER_GENRE_HISTORICAL,    gi = "21"   }, -- Historical
        { filterId = FILTER_GENRE_HORROR,        gi = "22"   }, -- Horror
        { filterId = FILTER_GENRE_ISEKAI,        gi = "37"   }, -- Isekai
        { filterId = FILTER_GENRE_JOSEI,         gi = "906"  }, -- Josei
        { filterId = FILTER_GENRE_LITRPG,        gi = "1180" }, -- LitRPG
        { filterId = FILTER_GENRE_MARTIAL_ARTS,  gi = "907"  }, -- Martial Arts
        { filterId = FILTER_GENRE_MATURE,        gi = "20"   }, -- Mature
        { filterId = FILTER_GENRE_MECHA,         gi = "908"  }, -- Mecha
        { filterId = FILTER_GENRE_MYSTERY,       gi = "909"  }, -- Mystery
        { filterId = FILTER_GENRE_PSYCHOLOGICAL, gi = "910"  }, -- Psychological
        { filterId = FILTER_GENRE_ROMANCE,       gi = "6"    }, -- Romance
        { filterId = FILTER_GENRE_SCHOOL_LIFE,   gi = "911"  }, -- School Life
        { filterId = FILTER_GENRE_SCI_FI,        gi = "912"  }, -- Sci-fi
        { filterId = FILTER_GENRE_SEINEN,        gi = "913"  }, -- Seinen
        { filterId = FILTER_GENRE_SLICE_OF_LIFE, gi = "914"  }, -- Slice of Life
        { filterId = FILTER_GENRE_SMUT,          gi = "915"  }, -- Smut
        { filterId = FILTER_GENRE_SPORTS,        gi = "916"  }, -- Sports
        { filterId = FILTER_GENRE_SUPERNATURAL,  gi = "5"    }, -- Supernatural
        { filterId = FILTER_GENRE_TRAGEDY,       gi = "901"  }  -- Tragedy
    }

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

local function getSelectedGenres(data)
    local selected = {}
    local genreData = data[FILTER_GENRE]

    if not genreData then return nil end

    for i, checked in pairs(genreData) do
        if checked then
            table.insert(selected, GENRES[i].id)
        end
    end

    if #selected == 0 then
        return nil
    end

    return table.concat(selected, ",")
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

local function buildGenreGI(data)
    local selected = {}

    for _, g in ipairs(GENRE_FILTERS) do
        if data[g.filterId] == true then
            table.insert(selected, g.gi)
        end
    end

    if #selected == 0 then
        return nil
    end

    return table.concat(selected, ",")
end


return {
	id = 86802,
	name = "ScribbleHub",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
	chapterType = ChapterType.HTML,
	hasCloudFlare = true,

	listings = {
		Listing("Novels", true, function(data)
            local page = data[PAGE] or 1

            -- SORT
            local sortIndex = data[FILTER_SORT] or 7 -- default Pageviews
            local sort = SORT_VALUES[sortIndex + 1] or "pageviews"

            -- ORDER
            local order = (data[FILTER_ORDER] == 0) and "asc" or "desc"

            -- GENRE
            local gi = buildGenreGI(data)
            local matchMode = (data[FILTER_GENRE_MODE] == 1) and "or" or "and"

            local params = {
                sf = 1,
                sort = sort,
                order = order,
                pg = page
            }

            if gi then
                params.gi = gi
                params.mgi = matchMode
            end

            local url = qs(params, baseURL .. "/series-finder/")
            print("URL =", url)

            return parse(GETDocument(url))
        end)

    },

	searchFilters = {
        DropdownFilter(FILTER_SORT, "Sort by", {
                "Chapters",
                "Chapters / Week",
                "Date Added",
                "Favorites",
                "Last Update",
                "Number of Ratings",
                "Pages",
                "Pageviews",
                "Ratings",
                "Readers",
                "Reviews",
                "Total Words"
            }),
        DropdownFilter(FILTER_ORDER, "Order", { "Ascending", "Descending" }),

        FilterGroup("Genre", {
            CheckboxFilter(FILTER_GENRE_ACTION,        "Action"),
            CheckboxFilter(FILTER_GENRE_ADULT,         "Adult"),
            CheckboxFilter(FILTER_GENRE_ADVENTURE,     "Adventure"),
            CheckboxFilter(FILTER_GENRE_BOYS_LOVE,     "Boys Love"),
            CheckboxFilter(FILTER_GENRE_COMEDY,        "Comedy"),
            CheckboxFilter(FILTER_GENRE_DRAMA,         "Drama"),
            CheckboxFilter(FILTER_GENRE_ECCHI,         "Ecchi"),
            CheckboxFilter(FILTER_GENRE_FANFICTION,    "Fanfiction"),
            CheckboxFilter(FILTER_GENRE_FANTASY,       "Fantasy"),
            CheckboxFilter(FILTER_GENRE_GENDER_BENDER, "Gender Bender"),
            CheckboxFilter(FILTER_GENRE_GIRLS_LOVE,    "Girls Love"),
            CheckboxFilter(FILTER_GENRE_HAREM,         "Harem"),
            CheckboxFilter(FILTER_GENRE_HISTORICAL,    "Historical"),
            CheckboxFilter(FILTER_GENRE_HORROR,        "Horror"),
            CheckboxFilter(FILTER_GENRE_ISEKAI,        "Isekai"),
            CheckboxFilter(FILTER_GENRE_JOSEI,         "Josei"),
            CheckboxFilter(FILTER_GENRE_LITRPG,        "LitRPG"),
            CheckboxFilter(FILTER_GENRE_MARTIAL_ARTS,  "Martial Arts"),
            CheckboxFilter(FILTER_GENRE_MATURE,        "Mature"),
            CheckboxFilter(FILTER_GENRE_MECHA,         "Mecha"),
            CheckboxFilter(FILTER_GENRE_MYSTERY,       "Mystery"),
            CheckboxFilter(FILTER_GENRE_PSYCHOLOGICAL, "Psychological"),
            CheckboxFilter(FILTER_GENRE_ROMANCE,       "Romance"),
            CheckboxFilter(FILTER_GENRE_SCHOOL_LIFE,   "School Life"),
            CheckboxFilter(FILTER_GENRE_SCI_FI,        "Sci-fi"),
            CheckboxFilter(FILTER_GENRE_SEINEN,        "Seinen"),
            CheckboxFilter(FILTER_GENRE_SLICE_OF_LIFE, "Slice of Life"),
            CheckboxFilter(FILTER_GENRE_SMUT,          "Smut"),
            CheckboxFilter(FILTER_GENRE_SPORTS,        "Sports"),
            CheckboxFilter(FILTER_GENRE_SUPERNATURAL,  "Supernatural"),
            CheckboxFilter(FILTER_GENRE_TRAGEDY,       "Tragedy"),
        }),

        DropdownFilter(FILTER_GENRE_MODE, "Genre Match", { "AND", "OR" })
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
}
