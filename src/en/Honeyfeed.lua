-- {"id":95565,"ver":"1.0.7","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://www.honeyfeed.fm"
local HoneyfeedLogo = "https://www.honeyfeed.fm/assets/main/pages/home/logo-honey-bomon-70595250eae88d365db99bd83ecdc51c917f32478fa535a6b3b6cffb9357c1b4.png"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://www.honeyfeed.fm/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. "/" .. url
end

local GENRE_FILTER = 2
local GENRE_VALUES = { 
    "All",
    "Action",
    "Adventure",
    "Boys Love",
    "Comedy",
    "Crime",
    "Culinary",
    "Cyberpunk",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Game",
    "Girls Love",
    "Gun Action",
    "Harem",
    "Historical",
    "Horror",
    "Isekai",
    "LGBTQ+",
    "LitRPG",
    "Magic",
    "Martial Arts",
    "Mecha",
    "Military / War",
    "Music",
    "Mystery",
    "Paranormal",
    "Philosophical",
    "Post-Apocalyptic",
    "Psychological",
    "Romance",
    "School",
    "Sci-Fi",
    "Seinen",
    "Shoujo",
    "Shounen",
    "Slice of Life",
    "Sports",
    "Supernatural",
    "Survival",
    "Thriller",
    "Time travel",
    "Tragedy",
    "Western",
}
local GENRE_PARAMS = {
    "All",
    "?genre_ids=1",
    "?genre_ids=2",
    "?genre_ids=49",
    "?genre_ids=5",
    "?genre_ids=14",
    "?genre_ids=6",
    "?genre_ids=67",
    "?genre_ids=9",
    "?genre_ids=10",
    "?genre_ids=11",
    "?genre_ids=13",
    "?genre_ids=47",
    "?genre_ids=16",
    "?genre_ids=17",
    "?genre_ids=19",
    "?genre_ids=20",
    "?genre_ids=63",
    "?genre_ids=72",
    "?genre_ids=68",
    "?genre_ids=26",
    "?genre_ids=28",
    "?genre_ids=29",
    "?genre_ids=30",
    "?genre_ids=32",
    "?genre_ids=33",
    "?genre_ids=70",
    "?genre_ids=36",
    "?genre_ids=66",
    "?genre_ids=38",
    "?genre_ids=40",
    "?genre_ids=42",
    "?genre_ids=43",
    "?genre_ids=44",
    "?genre_ids=46",
    "?genre_ids=48",
    "?genre_ids=50",
    "?genre_ids=52",
    "?genre_ids=53",
    "?genre_ids=45",
    "?genre_ids=55",
    "?genre_ids=69",
    "?genre_ids=65",
    "?genre_ids=71"
}

local SORT_BY_FILTER = 3
local SORT_BY_VALUES = {"Monthly Ranking", "Weekly Ranking", "New Novels" }
local SORT_BY_PARAMS = {"/ranking/monthly", "/ranking/weekly", "/novels"}

local ADULT_FILTER = 4
local ADULT_VALUES = {"No", "Only"}
local ADULT_PARAMS = {"", "/nsfw"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(SORT_BY_FILTER, "Sort By", SORT_BY_VALUES),
    DropdownFilter(ADULT_FILTER, "Adult", ADULT_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    local title = htmlElement:selectFirst("h1"):text()
    htmlElement = htmlElement:selectFirst(".wrap-body")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local page = data[PAGE]
    local doc = GETDocument(baseURL .. "/search/novel_title?k=" .. queryContent .. "&page=" .. page)
    return map(doc:selectFirst(".list-unit-novel"):select(".novel-unit-type-h.row"), function(v)
        local imgURL = HoneyfeedLogo
        local imgElement = v:selectFirst("img")
        if imgElement then
            imgURL = imgElement:attr("src")
        end
        return Novel {
            title = v:selectFirst("h3"):text(),
            imageURL = imgURL,
            link = v:selectFirst(".wrap-novel-links a"):attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = GETDocument(url)
    local chapterDocument = GETDocument(url.."/chapters")
    document:select("#wrap-button-remove-blur"):remove()
    local imgURL = HoneyfeedLogo
    local imgElement = document:selectFirst(".wrap-img-novel-mask img")
    if imgElement then
        imgURL = imgElement:attr("src")
    end
    return NovelInfo {
        title = document:selectFirst("div.mt8"):text(),
        description = document:selectFirst(".wrap-novel-body"):text(),
        imageURL = imgURL,
        status = ({
            Ongoing = NovelStatus.PUBLISHING,
            Finished = NovelStatus.COMPLETED,
        })[document:selectFirst("span.pr8"):text()],
        authors = { document:selectFirst("span.text-break-all.f14"):text()},
        genres = map(document:selectFirst("div.wrap-novel-genres"):select("a.btn-genre-link btn"), text ),
        chapters = AsList(
                map(chapterDocument:select("#wrap-chapter .list-chapter .list-group-item a"), function(v)
                    return NovelChapter {
                        order = v,
                        title = "[" .. v:selectFirst("div.f12"):text() .. "] " .. v:selectFirst("div.text-bold"):text(),
                        link = baseURL .. v:attr("href"),
                        release = (a_span and (a_span:attr("title") or a_span:attr("unixtime") or v:selectLast("a"):text())) or nil
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:selectFirst(".list-unit-novel"):select(".novel-unit-type-h.row"), function(v)
        local imgURL = HoneyfeedLogo
        local imgElement = v:selectFirst("img")
        if imgElement then
            imgURL = imgElement:attr("src")
        end
        return Novel {
            title = v:selectFirst("h3"):text(),
            imageURL = imgURL,
            link = v:selectFirst(".wrap-novel-links a"):attr("href")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE] or 1
    local genre = data[GENRE_FILTER]
    local genreValue = ""
    local sortby = data[SORT_BY_FILTER]
    local sortByValue = ""
    local adult = data[ADULT_FILTER]
    local adultValue = ""
    if adult ~= nil then
        adultValue = ADULT_PARAMS[adult+1]
    end
    if genre ~= nil then
        genreValue = GENRE_PARAMS[genre+1]
    end
    if sortby ~= nil then
        sortByValue = SORT_BY_PARAMS[sortby+1]
    end
    
    local url = baseURL .. sortByValue .. genreValue .. "&page=" .. page
    if genreValue == "All" then
        url = baseURL .. sortByValue .. "&page=" .. page
    end
    if adultValue == "/nsfw" then
        url = baseURL .. adultValue .. sortByValue .. "&page=" .. page
    end
    return parseListing(url)
end

return {
    id = 95565,
    name = "Honeyfeed",
    baseURL = baseURL,
    imageURL = HoneyfeedLogo,
    hasSearch = true,
    listings = {
        Listing("Default", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    searchFilters = searchFilters
}