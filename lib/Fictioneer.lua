-- {"ver":"2.0.4","author":"Lev616","dep":["url"]}

return function(baseURL, _self)

    local HTMLToString = Require("unhtml").HTMLToString

    local defaults = {

        listingSelector = "#list-of-stories li.card",
        searchSelector = "#search-result-list li.card",
        chapterSelector = "li[data-group='free']",

        listingPath = "/stories/page/",
        searchPostType = "fcn_story",
        latestMode = "default",

        chapterType = ChapterType.HTML,
        hasSearch = true,
    }

    function defaults:shrinkURL(url)
        return url:gsub(self.baseURL, "")
    end

    function defaults:expandURL(url)
        return self.baseURL .. url
    end

    -- =========================
    -- LISTING
    -- =========================
    function defaults:parseListing(url)
        local doc = GETDocument(url)
        if not doc then return {} end

        return mapNotNil(doc:select(self.listingSelector), function(card)
            local a = card:selectFirst("h3.card__title a")
            if not a then return nil end

            local imgEl = card:selectFirst("a.card__image")

            return Novel {
                title = a:text(),
                link = self:shrinkURL(a:attr("href") or ""),
                imageURL = imgEl and imgEl:attr("href")
            }
        end)
    end

    function defaults:latest(data)
        data = data or {}
        local page = (PAGE and data[PAGE]) or 1
        local url = self.baseURL .. self.listingPath .. page .. "/"
        return self:parseListing(url)
    end


    -- =========================
    -- SEARCH BUT LATEST FOR SITE WITH BROKEN HOMEPAGE
    -- =========================
    function defaults:search2(data)
        data = data or {}

        local query = (QUERY and data[QUERY]) or ""
        local page  = (PAGE and data[PAGE]) or 1

        local url = self.baseURL ..
                "/page/" .. page ..
                "/?s=" .. query ..
                "&post_type=" .. self.searchPostType ..
                "&orderby=modified"

        local doc = GETDocument(url)

        return mapNotNil(doc:select(self.searchSelector), function(card)
            local a = card:selectFirst("h3.card__title a")
            if not a then return nil end

            local imgEl = card:selectFirst("a.card__image")

            return Novel {
                title = a:text(),
                link = self:shrinkURL(a:attr("href") or ""),
                imageURL = imgEl and imgEl:attr("href")
            }
        end)
    end

    -- =========================
    -- SEARCH
    -- =========================
    function defaults:search(data)
        data = data or {}

        local query = (QUERY and data[QUERY]) or ""
        local page  = (PAGE and data[PAGE]) or 1

        local url = self.baseURL ..
                "/page/" .. page ..
                "/?s=" .. query ..
                "&post_type=" .. self.searchPostType

        local doc = GETDocument(url)

        return mapNotNil(doc:select(self.searchSelector), function(card)
            local a = card:selectFirst("h3.card__title a")
            if not a then return nil end

            local imgEl = card:selectFirst("a.card__image")

            return Novel {
                title = a:text(),
                link = self:shrinkURL(a:attr("href") or ""),
                imageURL = imgEl and imgEl:attr("href")
            }
        end)
    end

    -- =========================
    -- PARSE NOVEL
    -- =========================
    function defaults:parseNovel(novelURL, loadChapters)

        local doc = GETDocument(self:expandURL(novelURL))

        local titleElement = doc:selectFirst("h1")
        local imageElement = doc:selectFirst("div.main__wrapper a")
        local descriptionElement = doc:selectFirst("section.story__summary")
        local genrelist = doc:selectFirst("div.tag-group")

        local status =
        doc:selectFirst("._completed") and NovelStatus.COMPLETED or
                doc:selectFirst("._hiatus") and NovelStatus.PAUSED or
                NovelStatus.PUBLISHING

        local info = NovelInfo {
            title = titleElement and titleElement:text() or "No Title",
            imageURL = imageElement and imageElement:attr("href"),
            description = descriptionElement and HTMLToString(descriptionElement) or "",
            genres = genrelist and map(genrelist:select("a.tag-pill"), function(v)
                return v:text()
            end),
            status = status
        }

        if loadChapters then
            local chapterItems = doc:select(self.chapterSelector)

            local chapters = AsList(mapNotNil(chapterItems, function(v, i)
                local a = v:selectFirst("a")
                if not a then return nil end

                return NovelChapter {
                    order = i + 1,
                    title = a:text(),
                    link = self:shrinkURL(a:attr("href"))
                }
            end))

            info:setChapters(chapters)
        end

        return info
    end

    function defaults:getPassage(chapterURL)
        local doc = GETDocument(self:expandURL(chapterURL))
        local title = doc:selectFirst("h1.chapter__title"):text()
        local content = doc:selectFirst("div.chapter-formatting")

        content:child(0):before("<h1>" .. title .. "</h1>")

        return pageOfElem(content, true)
    end

    -- =========================
    -- INIT ENGINE
    -- =========================\


    _self = setmetatable(_self or {}, {
        __index = function(_, k)
            local d = defaults[k]
            return type(d) == "function" and function(...)
                return d(_self, select(2, ...))
            end or d
        end
    })

    _self.baseURL = baseURL

    _self.latestMode = _self.latestMode or "default"

    -- map available latest handlers
    local latestMap = {
        default = _self.latest,
        search2 = _self.search2,
        search  = _self.search
    }

    -- select handler safely
    local latestHandler = latestMap[_self.latestMode] or _self.latest

    _self.listings = {
        Listing(
                "Latest",
                true,
                latestHandler
        )
    }

    return _self

end