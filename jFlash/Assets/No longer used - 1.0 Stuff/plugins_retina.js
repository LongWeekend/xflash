function highdpi_init()
{
	if (jQuery('.retina').css('font-size') == "1px") {
		var els = jQuery(".replace-2x").get();
		for(var i in els) {
			var src = els[i].src
			src = src.replace(".png", "@2x.png");
			els[i].src = src;
		}
	}
}