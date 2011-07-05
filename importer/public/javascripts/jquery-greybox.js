/* Greybox Redux
 * Required: http://jquery.com/
 * Written by: John Resig
 * Based on code by: 4mir Salihefendic (http://amix.dk)
 * License: LGPL (read more in LGPL.txt)
 */

var GB_ANIMATION = true;
function GB_init() {
  if($("#GB_overlay").length < 1) {
    $(document.body).append("<div id='GB_overlay'></div><div id='GB_window'><div id='GB_caption'></div><img src='/images/close.gif' alt='Close window'/></div>");
    $(window).resize(GB_position);
    GB_hide();
    $("#GB_window img").click(GB_hide);
    $("#GB_overlay").click(GB_hide);
  }
}

function GB_show(caption, content_or_url, width, height) {
  GB_HEIGHT = height || 200;
  GB_WIDTH = width || 400;
  if($("#GB_overlay").length < 1) GB_init();

  $("#GB_frame").remove();
  $("#GB_div").remove();
  
  if(isUrl(content_or_url))
    $("#GB_window").prepend("<iframe id='GB_frame' src='"+qualifyURL(content_or_url)+"'></iframe>");
  else
    $("#GB_window").prepend("<div id='GB_div>"+ content_or_url + "</div>");

  $("#GB_caption").html(caption);
  $("#GB_overlay").show();
  GB_position();

  if(GB_ANIMATION)
    $("#GB_window").slideDown("slow");
  else
    $("#GB_window").show();
}

function GB_hide() {
  $("#GB_window,#GB_overlay").hide();
}

function GB_position() {
  var de = document.documentElement;
  var w = self.innerWidth || (de&&de.clientWidth) || document.body.clientWidth;
  $("#GB_window").css({width:GB_WIDTH+"px",height:GB_HEIGHT+"px",
    left: ((w - GB_WIDTH)/2)+"px" });
  $("#GB_frame").css("height",GB_HEIGHT - 20 +"px");
}

function isUrl(s) {
	var regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
	return regexp.test(s);
}

function qualifyURL(url){
    var img = document.createElement('img');
    img.src = url;
    url = img.src;
    img.src = null;
    return url;
}