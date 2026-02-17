-- {"id":86802,"ver":"1.0.6","libVer":"1.0.0","author":"TechnoJo4, StormX4","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- ==========================================
-- 1. CONFIGURATION & GER DEFINITIONS
-- ==========================================

-- HELPER: Page Wrapper
local function pageOfElem(elem, hasTitle, css)
    return "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><style>" .. (css or "") .. "</style></head><body>" .. elem:outerHtml() .. "</body></html>"
end

local function shrinkURL(url)
    return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
    return baseURL .. "/" .. url
end

local FILTER_SORT = 2
local FILTER_ORDER = 3

-- LIST: We define this ONCE, like RoyalRoad's GENRES_FILTER_INT
-- Structure: { Name, ID }
local GENRES_LIST = {
    {"Action", 9},
    {"Adult", 902},
    {"Adventure", 8},
    {"Boys Love", 891},
    {"Comedy", 7},
    {"Drama", 903},
    {"Ecchi", 904},
    {"Fanfiction", 38},
    {"Fantasy", 19},
    {"Gender Bender", 905},
    {"Girls Love", 892},
    {"Harem", 1015},
    {"Historical", 21},
    {"Horror", 22},
    {"Isekai", 37},
    {"Josei", 906},
    {"LitRPG", 1180},
    {"Martial Arts", 907},
    {"Mature", 20},
    {"Mecha", 908},
    {"Mystery", 909},
    {"Psychological", 910},
    {"Romance", 6},
    {"School Life", 911},
    {"Sci-fi", 912},
    {"Seinen", 913},
    {"Slice of Life", 914},
    {"Smut", 915},
    {"Sports", 916},
    {"Supernatural", 5},
    {"Tragedy", 901}
}

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

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()


-- ==========================================
-- 2. UTILITY FUNCTIONS
-- ==========================================

local function expandNumber(shortNum)
    if not shortNum then return 0 end
    local number, suffix = shortNum:match("^(%d+%.?%d*)([kKmMbB]?)$")
    if not number then return 0 end
    number = tonumber(number)

    if suffix == "k" or suffix == "K" then return math.floor(number * 1e3 + 0.5)
    elseif suffix == "m" or suffix == "M" then return math.floor(number * 1e6 + 0.5)
    elseif suffix == "b" or suffix == "B" then return math.floor(number * 1e9 + 0.5)
    else return math.floor(number + 0.5)
    end
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
    return 0
end

local function removeElements(element, attr)
    local elementsToRemove = element:select(attr)
    for i = 0, elementsToRemove:size() - 1 do
        elementsToRemove:get(i):remove()
    end
end

-- HELPER: Dynamic Filter Creator (RoyalRoad Style)
-- Creates the visual checkbox list for the Settings menu
local function createGenreFilters()
    local filters = {}
    for _, genre in ipairs(GENRES_LIST) do
        -- genre[1] is Name, genre[2] is ID
        table.insert(filters, CheckboxFilter(genre[2], genre[1]))
    end
    return filters
end

local function parse(doc)
    local container = doc:selectFirst("#page")
    if not container then return {} end

    return map(container:select(".wi_fic_wrap .search_main_box"), function(v)
       local body = v:selectFirst(".search_body")
       if body == nil then body = v end

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
          local clone = body:clone()
          removeElements(clone, ".dots")
          removeElements(clone, ".morelink")
          removeElements(clone, ".search_title")
          removeElements(clone, ".search_stats")
          removeElements(clone, ".search_genre")
          description = HTMLToString(clone)
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
          authors = { v:selectFirst(".a_un_st"):text() },
          description = description
       }
    end)
end

-- ==========================================
-- 3. MAIN EXTENSION DEFINITION
-- ==========================================
return {
    id = 86802,
    name = "ScribbleHub",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
    chapterType = ChapterType.HTML,
    hasCloudFlare = true,

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

    searchFilters = {
           DropdownFilter(FILTER_SORT, "Sort by", { "Popularity", "Favorites", "Activity", "Readers", "Rising" }),
           DropdownFilter(FILTER_ORDER, "Order", { "Daily", "Weekly", "Monthly", "All Time" }),
           -- The Group name is "Genres", containing our dynamically created list
           FilterGroup("Genres", createGenreFilters())
        },

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    parseNovel = function(url, loadChapters)
       local doc = GETDocument(baseURL.."/series/"..url.."/a/"):selectFirst(".site-content-contain")
       local novel = doc:selectFirst("div[typeof=Book]")
       local wrap = novel:selectFirst(".box_fictionpage")
       removeElements(wrap, ".dots")
       removeElements(wrap, ".morelink")

       local statusStr = ""
       local copyright = doc:select(".copyright ul li")
       if copyright:size() > 0 then
           statusStr = copyright:get(copyright:size() - 1):text()
       end

       local status = NovelStatus.UNKNOWN
       if statusStr:match("Ongoing") then status = NovelStatus.PUBLISHING
       elseif statusStr:match("Complete") then status = NovelStatus.COMPLETED
       elseif statusStr:match("Hiatus") then status = NovelStatus.PAUSED
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
       local doc = GETDocument(expandURL(url))
       local chap = doc:getElementById("chp_raw")
       local titleElem = doc:selectFirst(".chapter-title")
       local title = titleElem and titleElem:text() or ""

       local paragraphs = chap:select("p")
       for i = 0, paragraphs:size() - 1 do
           local p = paragraphs:get(i)
           if p:childrenSize() == 0 and (p:text() == nil or p:text() == "") then
               p:remove()
           end
           if p:hasAttr("border") then
               p:removeAttr("border")
           end
       end

       chap:prepend("<h1>" .. title .. "</h1>")
       return pageOfElem(chap, false, css)
    end,

    -- ==========================================
    -- 4. SEARCH LOGIC (RoyalRoad Architecture)
    -- ==========================================
    search = function(data)
           local query = data[QUERY]

           -- =========================================================
           -- ROBUST GENRE DETECTION (Reverse Lookup)
           -- =========================================================

           -- 1. Build a "String Map" of our valid genres.
           -- This lets us match keys even if one is a String ("9") and one is a Number (9).
           local valid_genres = {}
           for _, genre in ipairs(GENRES_LIST) do
               -- Key = String representation ("9"), Value = Original Number (9)
               valid_genres[tostring(genre[2])] = genre[2]
           end

           local selectedIDs = {}

           -- 2. Iterate through ALL data sent by the app (pairs)
           -- This guarantees we see every key, no matter its internal type.
           for key, value in pairs(data) do
               if value == true then
                   -- Convert whatever key the app sent (Int, Float, String) to a String
                   local keyStr = tostring(key)

                   -- If this key matches one of our genres, add the ORIGINAL ID to our list
                   if valid_genres[keyStr] then
                       table.insert(selectedIDs, valid_genres[keyStr])
                   end
               end
           end

           -- =========================================================
           -- URL CONSTRUCTION
           -- =========================================================

           -- PATH A: Text Search
           if query and query ~= "" then
               return parse(GETDocument(qs({
                  s = query,
                  post_type = "fictionposts"
               }, baseURL .. "/")))
           end

           -- PATH B: Series Finder
           local params = {
               sf = 1,
               mgi = "and",
               sort = SORT_KEYS[data[FILTER_SORT]] or "pageviews",
               order = ORDER_KEYS[data[FILTER_ORDER]] or "desc"
           }

           if #selectedIDs > 0 then
               params["gi"] = table.concat(selectedIDs, ",")
           end

           if data[PAGE] and data[PAGE] > 1 then
               params["pg"] = data[PAGE]
           end

           return parse(GETDocument(qs(params, baseURL .. "/series-finder/")))
        end,
}