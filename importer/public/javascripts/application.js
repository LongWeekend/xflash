//Global Variables
var $navBarPinned=true;
var $queryTagAc=null;

$(document).ready(function(){

  // ---------------------------------------------------------
  // Pin Helper Functions
  // ---------------------------------------------------------
  setOrCreatePinCookie = function(state) {
    if(!$.cookie('npedia_pin_cookie'))
  		$.cookie('npedia_pin_cookie', state, { expires: 30 /*, domain: 'npedia.org' */ });
  	else
		  $.cookie('npedia_pin_cookie', state);
  };
  pinNavBar = function() {
    setOrCreatePinCookie(1);
    $("div.textboxlist").css({ zIndex: "99", position: "fixed", marginLeft: 0, marginTop: 0, top: $("#query_tags").attr('offsetTop'), left: $("#query_tags").attr('offsetLeft') });
    $("ul#commands_expanded").css('position', 'fixed');
		$("#header #pin").toggleClass("pin_off");
		$("body").toggleClass("sticky_header");
    $navBarPinned = true;
  };
  unPinNavBar = function() {
    setOrCreatePinCookie(0);
    $("div.textboxlist").css({ zIndex: "99", position: "absolute", marginLeft: 0, marginTop: 0, top: $("#query_tags").attr('offsetTop'), left: $("#query_tags").attr('offsetLeft') });
    $("ul#commands_expanded").each(function() {
      var pos = $(this).position();
      $(this).css({ position: "absolute", marginLeft: 0, marginTop: 0, top: pos.top, left: pos.left });
    });
		$("#header #pin").toggleClass("pin_off");
		$("body").toggleClass("sticky_header");
    $navBarPinned = false;
  };
  
  // Pin click handler
	$("#header #pin").click( function() {
		if($navBarPinned) unPinNavBar(); else pinNavBar();
	});

  // Set default pin state
	if(!$.cookie('npedia_pin_cookie') || $.cookie('npedia_pin_cookie') == 0) pinNavBar(); else unPinNavBar();


  // ---------------------------------------------------------
	// Search by Tags - fancy autocomplete with pinning support
  // ---------------------------------------------------------
  $('#query_tags').click( function() { 
    $("div.textboxlist").css('top', $("#query_tags").attr('offsetTop'));
    $("div.textboxlist").css('left', $("#query_tags").attr('offsetLeft'));
    $('div.textboxlist').show();
  });
	$queryTagAc = new TextboxList('#query_tags', {unique: true, uniqueInsensitive: true, grows: false, plugins: {autocomplete: {}}});
	$queryTagAc.getContainer().addClass('tags_auto_loading');
  var queryTagLoaders = function(key){
  	$.ajax({url: '/autocomplete/tags?key='+key, dataType: 'json', success: function(r){
  		$queryTagAc.plugins['autocomplete'].setValues(r);
  		$queryTagAc.getContainer().removeClass('tags_auto_loading');
  	}});
	}
  $("#query_tags").show();
	$queryTagAc.addEvent('blur', function(){ 
	  $("div.textboxlist .textboxlist-bits").css('height', '19px');
	  $("div.textboxlist .textboxlist-bits").css('overflow', 'auto');
	  $("div.textboxlist .textboxlist-bits").css('max-height','61px');
	});
	$queryTagAc.addEvent('focus', function(){ 
	  $("div.textboxlist .textboxlist-bits").css('overflow', 'auto');
	  $("div.textboxlist .textboxlist-bits").css('height','auto');
	  $("div.textboxlist .textboxlist-bits").css('*height', '61px');
	  $("div.textboxlist .textboxlist-bits").css('max-height','61px');
  });
	$('#query_tags').trigger('click');
	var resizeTimer = null;
  $(window).bind('resize', function() {
    // on window resize, move fancy tag box to match liquid layout
    if (resizeTimer) clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {$("div.textboxlist").css('left', $("#query_tags").attr('offsetLeft'));}, 16);
  });

  // ---------------------------------------------------------
  // Npedia Tab Form Nav
  // ---------------------------------------------------------
  $('#navigation li').click( function(e) { 
    e.preventDefault();
    $(e.target).blur();
    var targetTag = (e.target.tagName == "A" ? e.target.parentNode : e.target);
    queryTagLoaders(targetTag.id); // reload the Tag AC data
    
    // Switch the active tab
    $('#navigation li').removeClass('active');
    $(targetTag).addClass('active');
    // Switch the form action
    $('#search_form').attr('action', '/search/'+targetTag.id)
    // Display form elements based on with class=common OR class=targetTagID
    $('#search_form_elements div.form_element').each(function(){
      if(($(this).hasClass('common') || $(this).hasClass(targetTag.id)) && !$(this).hasClass('not_'+targetTag.id))
        $(this).show();
      else
        $(this).hide();
    });
    return false;
  });
  $('#navigation li.active').click(); // trigger active tab on load
  
  // ---------------------------------------------------------
  // Command Menu - click handler
  // ---------------------------------------------------------
  var commands_close_timeout;
  $('ul#commands').click( function() { 
    if($("ul#commands_expanded").length < 1) {
      $("ul#commands").clone(true).prependTo("body").attr('id', 'commands_expanded').hide();
      $('ul#commands_expanded').hover( 
        function(){ 
          // stop auto-close timeout
          clearTimeout(commands_close_timeout); 
          $("ul#commands_expanded").show();
        },
        function(){ 
          // set auto-close timeout
          commands_close_timeout = setTimeout(function() { 
            $('ul#commands_expanded').hide(); 
            $('ul#commands_expanded li').hide(); }, 77);
        }
      );
    }
    $("ul#commands_expanded").css('top', $("ul#commands").attr('offsetTop'));
    $("ul#commands_expanded").css('left', $("ul#commands").attr('offsetLeft'));
    if($navBarPinned) $("ul#commands_expanded").css('position', 'fixed');
    $("ul#commands_expanded li").show();
    $('ul#commands_expanded').show(); 
  });
  $('ul#commands').hover( 
    function(){ clearTimeout(commands_close_timeout); $('ul#commands').trigger('click');}, 
    function(){ return }
  );
  $(window).scroll(function(){ 
    // Hide if window scrolls (prevents miss layout)
    if(!$navBarPinned) $("ul#commands_expanded").hide(); 
  });

  // ---------------------------------------------------------
	// init jquery tiddlers
  // ---------------------------------------------------------
	if(jtiddler) jtiddler.init(); else window.console.log("jTiddler did not load!");

/*
  // Turned off for development
  window.onbeforeunload = function(){ return "WARNING: Any search results currently displayed will not be saved." } */
});

// rich text editor interface
function npediaEditor(obj_id) {
	return new nicEditor({buttonList : ['bold','italic','underline','strikeThrough','subscript','superscript','fontSize','image','html']}).panelInstance(obj_id);
}