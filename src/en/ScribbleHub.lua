-- {"id":86802,"ver":"1.1.1","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- 1. GENRE LIST
local GENRES = {
	{"Action", 9}, {"Adult", 902}, {"Adventure", 8}, {"Boys Love", 891},
	{"Comedy", 7}, {"Drama", 903}, {"Ecchi", 904}, {"Fanfiction", 38},
	{"Fantasy", 19}, {"Gender Bender", 905}, {"Girls Love", 892}, {"Harem", 1015},
	{"Historical", 21}, {"Horror", 22}, {"Isekai", 37}, {"Josei", 906},
	{"LitRPG", 1180}, {"Martial Arts", 907}, {"Mature", 20}, {"Mecha", 908},
	{"Mystery", 909}, {"Psychological", 910}, {"Romance", 6}, {"School Life", 911},
	{"Sci-fi", 912}, {"Seinen", 913}, {"Slice of Life", 914}, {"Smut", 915},
	{"Sports", 916}, {"Supernatural", 5}, {"Tragedy", 901}
}

-- 2. SORT MAPS
local SORT_KEYS = {
    [0] = "pageviews",
    [1] = "favorites",
    [2] = "readers",
    [3] = "chapters",
    [4] = "reviews"
}

local ORDER_KEYS = {
    [0] = "desc",
    [1] = "asc"
}

-- 3. FIXED IDs (Must start at 0 and be sequential)
local FILTER_SORT = 0
local FILTER_ORDER = 1
-- The Genre filters will start at ID 2 (0, 1, 2...)
local FILTER_GENRE_START = 2

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
          wordCount = findStat(stats, "Words"),
          viewCount = findStat(stats, "Views"),
          chapterCount = findStat(stats, "Chapters"),
          commentCount = findStat(stats, "Reviews"),
          favoriteCount = findStat(stats, "Favorites"),
          genres = map(v:select(".search_genre .fic_genre"), function(g) return g:text() end),
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

    -- Updated Listings to use Series Finder URL structure
    listings = {
       Listing("Latest Novels", false, function(data)
          return parse(GETDocument(qs({
             sf = 1,
             sort = "pageviews",
             order = "desc",
             mgi = "and",
             pg = data[PAGE]
          }, baseURL .. "/series-finder/")))
       end)
    },

    -- Updated Filters with Sequential IDs (0, 1, 2...)
    searchFilters = {
       DropdownFilter(FILTER_SORT, "Sort By", { "Popularity", "Favorites", "Readers", "Chapters", "Reviews" }),
       DropdownFilter(FILTER_ORDER, "Order", { "Descending", "Ascending" }),
       FilterGroup("Genres", map(GENRES, function(v, i)
           -- i starts at 1 in Lua, but we subtract 1 from index to ensure
           -- sequential ID mapping if needed, or just append strictly.
           -- Actually, map index 'i' in Lua is 1-based.
           -- FILTER_GENRE_START is 2.
           -- First genre ID = 2 + 1 - 1 = 2. Next is 3, etc.
           return CheckboxFilter(FILTER_GENRE_START + (i - 1), v[1])
       end))
    },

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    parseNovel = function(url, loadChapters)
       local doc = GETDocument(baseURL.."/series/"..url.."/a/"):selectFirst(".site-content-contain")
       local novel = doc:selectFirst("div[typeof=Book]")
       local wrap = novel:selectFirst(".box_fictionpage")
       removeElements(wrap, ".dots")
       removeElements(wrap, ".morelink")
       local s_node = doc:selectFirst(".copyright ul"):children()
       local s_text = s_node:get(s_node:size() - 1):children():get(0):ownText()

       local status = NovelStatus.UNKNOWN
       if s_text:match("Ongoing") then status = NovelStatus.PUBLISHING
       elseif s_text:match("Complete") then status = NovelStatus.COMPLETED
       elseif s_text:match("Hiatus") then status = NovelStatus.PAUSED end

       local info = NovelInfo {
          title = novel:selectFirst(".fic_title"):text(),
          imageURL = novel:selectFirst(".fic_image img"):attr("src"),
          description = HTMLToString(wrap:selectFirst(".wi_fic_desc")),
          genres = map(wrap:selectFirst(".wi_fic_genre"):select("a"), function(v) return v:text() end),
          tags = map(wrap:selectFirst(".wi_fic_showtags"):select("a"), function(v) return v:text() end),
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
       chap:traverse(NodeVisitor(function(v)
          if v:tagName() == "p" and v:childrenSize() == 0 and v:text() == "" then v:remove() end
          if v:hasAttr("border") then v:removeAttr("border") end
       end, nil, true))
       chap:child(0):before("<h1>" .. title .. "</h1>");
       return pageOfElem(chap, false, css)
    end,

    search = function(data)
       local query = data[QUERY]
       if query and query ~= "" then
          return parse(GETDocument(qs({
             s = query,
             post_type = "fictionposts"
          }, baseURL .. "/")))
       end

       local selectedIDs = {}
       for i, genre in ipairs(GENRES) do
           -- Retrieve using the same ID logic: start + (i - 1)
           if data[FILTER_GENRE_START + (i - 1)] == true then
               table.insert(selectedIDs, genre[2])
           end
       end

       local params = {
           sf = 1,
           mgi = "and",
           sort = SORT_KEYS[data[FILTER_SORT]] or "pageviews",
           order = ORDER_KEYS[data[FILTER_ORDER]] or "desc",
           pg = data[PAGE]
       }

       if #selectedIDs > 0 then
           params["gi"] = table.concat(selectedIDs, ",")
       end

       return parse(GETDocument(qs(params, baseURL .. "/series-finder/")))
    end,
    isSearchIncrementing = false
}