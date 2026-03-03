-- {"id":981363135,"ver":"1.0.4","libVer":"1.0.0","author":"Lev616","dep":["Fictioneer>=2.0.0"]}

return Require("Fictioneer")("https://gravitytales.com", {
    id = 981363135,
    name = "Gravity Tales",
    imageURL = "https://lovelyblossoms.com/wp-content/uploads/2025/09/lovely-blossoms-2-Photoroom-1.png",
    listingSelector = "#list-of-stories li.card",
    searchSelector = "#search-result-list li.card",
    useSearchAsListing = true,
    chapterSelector = "li[data-group='unassigned']",

    listingPath = "/stories/page/",
    searchPostType = "fcn_story",

    chapterType = ChapterType.HTML,
    hasSearch = true,
})

