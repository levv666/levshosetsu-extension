-- {"id":17692548,"ver":"1.0.0","libVer":"1.0.0","author":"OceaniaRose","dep":["NovelFull>=2.0.2"]}

return Require("NovelFull")("http://novel-next.com", {
	id = 17692548,
	name = "Novel-Next",
	imageURL = "https://novel-next.com/img/logo.png",
	
	meta_offset = 0,
	ajax_hot = "/ajax-search?type=hot",
	ajax_latest = "/ajax-search?type=latest",
	ajax_chapters = "/ajax-chapter-option",
	searchListSel = "list.list-truyen.col-xs-12",
	searchTitleSel = ".truyen-title"
})
