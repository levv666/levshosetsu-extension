-- {"id":86802,"ver":"1.4.0","libVer":"1.0.0","author":"TechnoJo4, StormX4, Modified","dep":["url>=1.0.0","CommonCSS>=1.0.0","unhtml>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring
local css = Require("CommonCSS").table
local HTMLToString = Require("unhtml").HTMLToString

-- ==========================================
-- 1. GENRES (Updated with IDs from your link)
-- ==========================================
local genres = {
    { "Action", 9 },
    { "Adult", 902 },
    { "Adventure", 8 },
    { "Boys Love", 891 },
    { "Comedy", 7 },
    { "Drama", 903 },
    { "Ecchi", 904 },
    { "Fanfiction", 38 },
    { "Fantasy", 19 },
    { "Gender Bender", 905 },
    { "Girls Love", 892 },
    { "Harem", 1015 },
    { "Historical", 21 },
    { "Horror", 22 },
    { "Isekai", 37 },
    { "Josei", 906 },
    { "LitRPG", 1180 },
    { "Martial Arts", 907 },
    { "Mature", 20 },
    { "Mecha", 908 },
    { "Mystery", 909 },
    { "Psychological", 910 },
    { "Romance", 6 },
    { "School Life", 911 },
    { "Sci-fi", 912 },
    { "Seinen", 913 },
    { "Slice of Life", 914 },
    { "Smut", 915 },
    { "Sports", 916 },
    { "Supernatural", 5 },
    { "Tragedy", 901 }
}
local genreNames = map(genres, function(v) return v[1] end)

-- ==========================================
-- 2. TAGS
-- ==========================================
-- I kept the ones we found earlier. You still need IDs for the others (marked 0).
local tags = {
    { "Abandoned children", 119 },
    { "Absent Parent", 121 },
    { "Anti-Hero Lead", 0 }, -- Example: ID is 19 if you need it
    { "Artificial Intelligence", 0 },
    { "Attractive MC", 0 },
    { "Cyberpunk", 0 },
    { "Dungeon", 0 },
    { "Dystopia", 0 },
    { "Female Lead", 0 },
    { "First Contact", 0 },
    { "Game Lit", 0 },
    { "Genetically Engineered", 0 },
    { "Grimdark", 0 },
    { "Hard Sci-fi", 0 },
    { "High Fantasy", 0 },
    { "Loop", 0 },
    { "Low Fantasy", 0 },
    { "Magic", 0 },
    { "Male Lead", 0 },
    { "Multiple Lead Characters", 0 },
    { "Mythos", 0 },
    { "Non-Human lead", 0 },
    { "Post-Apocalyptic", 0 },
    { "Progression", 0 },
    { "Reader interactive", 0 },
    { "Reincarnation", 0 },
    { "Ruling Class", 0 },
    { "Secret Identity", 0 },
    { "Soft Sci-fi", 0 },
    { "Space Opera", 0 },
    { "Steampunk", 0 },
    { "Strategy", 0 },
    { "Strong Lead", 0 },
    { "Superheroes", 0 },
    { "Technologically Engineered", 0 },
    { "Time Travel", 0 },
    { "Urban Fantasy", 0 },
    { "Villainous Lead", 0 },
    { "Virtual Reality", 0 },
    { "War and Military", 0 },
    { "Wuxia", 0 },
    { "Xianxia", 0 }
}
local tagNames = map(tags, function(v) return v[1] end)

local function shrinkURL(url)
    return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
    return baseURL .. "/" .. url
end

-- Filter Index Constants
local F_SORT = 0
local F_GENRE_MODE = 1
local F_GENRES = 2
local F_TAG_MODE = 3
local F_TAGS = 4

-- Sort keys: "pageviews" is usually best for "Popularity" in Series Finder
local default_order = { "date", "pageviews", "activity", "readers", "favorites" }

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

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

    listings = {
        Listing("Series Finder", false, function(data)
            -- 1. Sort Order
            local sortValue = default_order[data[F_SORT] + 1]

            -- 2. Build Query Table
            local query = {
                sf = 1,
                sort = sortValue,
                order = "desc" 
            }

            -- 3. Handle GENRES (gi & mgi)
            if data[F_GENRES] and #data[F_GENRES] > 0 then
                local selectedGIs = {}
                for _, index in ipairs(data[F_GENRES]) do
                    table.insert(selectedGIs, genres[index + 1][2])
                end
                query["gi"] = table.concat(selectedGIs, ",")
                
                -- Genre Mode: 0=AND (and), 1=OR (or)
                if data[F_GENRE_MODE] == 1 then
                    query["mgi"] = "or"
                else
                    query["mgi"] = "and"
                end
            end

            -- 4. Handle TAGS (tgi & mtgi)
            if data[F_TAGS] and #data[F_TAGS] > 0 then
                local selectedTIs = {}
                for _, index in ipairs(data[F_TAGS]) do
                    table.insert(selectedTIs, tags[index + 1][2])
                end
                query["tgi"] = table.concat(selectedTIs, ",")

                -- Tag Mode: 0=AND (and), 1=OR (or)
                if data[F_TAG_MODE] == 1 then
                    query["mtgi"] = "or"
                else
                    query["mtgi"] = "and"
                end
            end

            return parse(GETDocument(qs(query, baseURL .. "/series-finder/")))
        end)
    },

    searchFilters = {
        DropdownFilter(F_SORT, "Sort by", { "Date Added", "Popularity", "Activity", "Readers", "Favorites" }),
        
        -- Genre Filters
        DropdownFilter(F_GENRE_MODE, "Genre Mode", { "AND (All)", "OR (Any)" }),
        MultiSelectFilter(F_GENRES, "Include Genres", genreNames),
        
        -- Tag Filters
        DropdownFilter(F_TAG_MODE, "Tag Mode", { "AND (All)", "OR (Any)" }),
        MultiSelectFilter(F_TAGS, "Include Tags", tagNames)
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
            if v:hasAttr("border") then
                v:removeAttr("border")
            end
        end, nil, true))
        for _,v in pairs(toRemove) do
            v:remove()
        end

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
