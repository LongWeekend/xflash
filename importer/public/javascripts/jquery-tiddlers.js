//  
//	Originally made using code written by Phil Hawksworth (http://www.hawksworx.com/journal/category/jigglywiki/)
//  Requires jQuery 1.2.6
//  Requires jQuery Autocomplete 1.0.2
//  Requires jQuery TextboxList 2
//  Requires Url.decode function to convert from URL encoded back to plaintext
//

// Dynamically load external dependencies
// TURN OFF FOR NPEDIA
// document.write('<script src="jquery-tag-ac.js" type="text/javascript"></script>');
// document.write('<script src="jquery-tag-ac.js" type="text/javascript"></script>');

loadJQueryExtensions = function() {
	jQuery.fn.reverse = Array.prototype.reverse;
	jQuery.fn.swooshIn = function(){
		end =  this.css('top');
		start = parseInt(end.substr(0,end.length-2)) + 5 + 'px';
		this.hide().css({top:start, opacity: '0.96'});
		this.animate({top:end, opacity:'show'}, 200);
		return this;
	};
	jQuery.fn.swooshOut = function(){
		start =this.css('top');
		end = parseInt(start.substr(0,start.length-2)) - 50 + 'px';
		this.animate({top:end, opacity:'0'}, 200, function(){ $(this).hide(); });
		return this;
	};
};

// =============== setup  ================

var jtiddler = {};
jtiddler.history = {};
jtiddler.state = {};
jtiddler.i18nStrings = {};
jtiddler.decorator = {};
jtiddler.authentication = {};
jtiddler.data = {};
jtiddler.options = {};
jtiddler.TEMPLATES = {};
jtiddler.log = function(str) {
	if(window.console && window.console.log) {
		console.log(str);
	} else {
		alert(str);
	}
};
jtiddler.init = function() {
	loadJQueryExtensions();
	jtiddler.addEventHandlers();
};

// =============== options =================

jtiddler.options.defaultHeight = 400;
jtiddler.options.language = 'en';


// =============== i18n strings ================

jtiddler.i18nStrings['en'] = {};
jtiddler.i18nStrings['en']['cleared']  = 'Cleared';
jtiddler.i18nStrings['en']['confirm']  = 'Are you sure you wish to clear this list?';
jtiddler.i18nStrings['en']['list_empty'] = "List Is Empty";
jtiddler.i18nStrings['en']['no_recent_searches'] = "No recent searches";
jtiddler.i18nStrings['en']['no_recent_topics'] = "No recent topics";
jtiddler.i18nStrings['en']['login_for_starred_lists'] = "Login to use the starred list";


// ============== state tracking ============

jtiddler.state.lastFocusedEle = null;


// =============== i18n helper ================

jtiddler.i18n = function(key, lang){
  if(!lang) lang = jtiddler.options.language;
  if(jtiddler.i18nStrings[lang][key])
    return jtiddler.i18nStrings[lang][key];
  else
    return key;
};


// =============== templates ================

jtiddler.TEMPLATES.user_list_empty = '<li class="empty">'+ jtiddler.i18n('list_empty') + '</li>';
jtiddler.TEMPLATES.search_history_empty = '<li class="empty">'+ jtiddler.i18n('no_recent_searches') + '</li>';
jtiddler.TEMPLATES.link_history_empty = '<li class="empty">'+ jtiddler.i18n('no_recent_topics') + '</li>';
jtiddler.TEMPLATES.large_spinner = '<div class="progress_indicator_large" style="display:true"></div>';
jtiddler.TEMPLATES.spinner = '<img class="progress_indicator" style="margin: 0pt 0pt -2px 2px; display: none;" src="/images/smallicons/progress1.gif"/>';
jtiddler.TEMPLATES.tiddler_content = function(content) { return '<div class="contents">' + (content =="" ? "" : content) + '</div>'; }; // not used, kept as example!

// =============== event handlers ================

jtiddler.addEventHandlers = function() {

	// Bind events for clicks within tiddlers 
	$('#search_results').click(function(e){
		// tiddler internal clicks
		if( $(e.target).is('a') && e.originalEvent.target.type != "submit" && e.originalEvent.target.type != "button" ) {
  		e.preventDefault();
			if(e.target.tagName != "A") {
				var klass = e.target.parentNode.className;
				var target = e.target.parentNode;
			} else {
				var klass = e.target.className;
				var target = e.target;
			}
			var tiddler = jtiddler.containingTiddler(e.target);
      // Some anchor tags have multiple classes, so loop em
			var arr = klass.split(' ');
			for(var i=arr.length-1; i>=0; --i) {
  			if(jtiddler.controls[arr[i]] !== undefined) {
  				jtiddler.controls[arr[i]].handler(tiddler, target);
  			} else {
  			  // dev use only
  				//jtiddler.log("No handler for " + arr[i]);
  			}
  		}
		}
	});

	// Bind handler to clicks in ul.tiddler_commands
	$('.tiddler_commands,.tiddler_command').click(function(e){
		if(e.target.tagName == "A") {
  		e.preventDefault();
      jtiddler.commandHandler(e.target.href);
    }
		return false;
	});

	// Bind handler to any submission inside tiddle
  $("#search_results").submit(function(e) {
    e.preventDefault();
		jtiddler.submitTiddlerForm(e.target, e);
		return false;
  });

	// Bind handler to #search_form
	$("form.tiddler_query_form").submit(function(e) {
	  e.preventDefault();
		jtiddler.searchFormHandler(e);
		return false;
	});

	// Bind handler to search_form reset links
	$("a#search_form_clear").click(function(e) {
	  e.preventDefault();
	  $("input#query")[0].value="";
	  $("input#query_tags")[0].value="";
	  $queryTagAc.clearSelection(); // NASTY GLOBAL CALL! fancy tag auto-complete integration
	  $("input#query")[0].focus();
		return false;
	});
	// NOTE ABOUT "NASTY GLOBAL CALL!" ... need to create an external hook to register actions on external events!

  $("a#search_results_clear").click(function(e) {
	  e.preventDefault();
		jtiddler.closeAllTiddlers(false);
		$('#search_results').append( jtiddler.tiddlify("<strong>"+ jtiddler.i18n('cleared')+"</strong>") );
		$('#search_results div.tiddler').fadeOut(2000);
	  $("input#query")[0].focus();
		return false;
	});

  // Add decorative handlers
  jtiddler.decorator.init();

	// Add authentication handlers
  jtiddler.authentication.init();

	// Add history/list handlers
	jtiddler.history.init();

};

jtiddler.controls = {
	'load_form': {
		handler: function(tiddler, target) { jtiddler.loadInCurrentTiddler(tiddler, target); }
	},
	'tiddler_link_external': {
		handler: function(tiddler, target) { window.open(target.href); }
	},
	'tiddler_link_static': {
		handler: function(tiddler, target) { jtiddler.loadInCurrentTiddler(tiddler, target); }
	},
	'tiddler_link': {
		handler: function(tiddler, target) { jtiddler.tiddlerLinkClick(tiddler, target); }
	},
	'star': {
		handler: function(tiddler, target) { jtiddler.starLinkClick(tiddler, target); }
	},
	'monitorship': {
		handler: function(tiddler, target) { jtiddler.monitorshipLinkClick(tiddler, target); }
	},
	'vote': {
		handler: function(tiddler, target) { jtiddler.voteLinkClick(tiddler, target); }
	},
	'add_scrap_button': {
		handler: function(tiddler, target) { jtiddler.loadTiddlerFromTemplate(target, 'add_scrap_form'); }
	},
	'expand': {
		handler: function(tiddler, target) { jtiddler.expandTiddler(tiddler); }
	},
	'flatten': {
		handler: function(tiddler, target) { jtiddler.flattenTiddler(tiddler); }
	},
	'more': {
		handler: function(tiddler, target) { jtiddler.moreResultsClick(tiddler, target); }
	},
	'close_tiddler': {
		handler: function(tiddler, target) { jtiddler.closeTiddler(tiddler, true); }
	},
	'close_others': {
		handler: function(tiddler, target) { jtiddler.closeOtherTiddlers(tiddler, true); }
	},
	'close_all': {
		handler: function(tiddler, target) { jtiddler.closeAllTiddlers(true); }
	},
	'close_status_message': {
		handler: function(tiddler, target) { jtiddler.closeStatusMessage(target, true); }
	}
};


// =============== jtiddler dom events ================

jtiddler.createTiddler = function() {
	var new_id = jtiddler.createTiddlerID();
	var $new_tiddler = jtiddler.tiddlify(jtiddler.TEMPLATES.large_spinner, new_id);
  $('#search_results').prepend($new_tiddler);
  return [new_id, $new_tiddler];
};

jtiddler.flattenTiddler = function(tiddler) {
	tiddler_div_id = '#' + tiddler[0].id + ' div.contents';
	if(jtiddler.options.defaultHeight >= $(tiddler_div_id).height()){
		$(tiddler_div_id).height('auto');
		$(tiddler_div_id).attr('overflow', 'visible');
	} else {
		$(tiddler_div_id).height(jtiddler.options.defaultHeight + 'px');
		$(tiddler_div_id).attr('overflow', 'auto');
	}
	return false;
};

jtiddler.expandTiddler = function(tiddler) {
	tiddler_div_id = '#' + tiddler[0].id + ' div.contents';
	$(tiddler_div_id).height( $(tiddler_div_id).height()+100 );
	$('html,body').animate({scrollTop: $('html,body').attr('scrollTop')+100}, 500);
	return false;
};

jtiddler.closeTiddler = function(tiddler, witheffect) {
	if(witheffect)
		tiddler.fadeOut("fast", function(){	tiddler.remove();	});
	else
 		tiddler.remove();
};

jtiddler.closeOtherTiddlers = function(tiddler, witheffect) {
	if(!witheffect) witheffect = false; else witheffect = true;
	$('#search_results div.tiddler').each(function(){
		if(this !== tiddler[0]) jtiddler.closeTiddler($(this), witheffect);
	});
};

jtiddler.closeAllTiddlers = function(witheffect) {
	if(!witheffect) witheffect = false; else witheffect = true;
	$('#search_results div.tiddler').each(function(){
	  jtiddler.closeTiddler($(this), witheffect);
	});
};

jtiddler.closeStatusMessage = function(target, witheffect) {
  div = jtiddler.containingDivByClass(target, 'tiddler_status_message');
	if(witheffect)
		div.fadeOut("fast", function(){	div.remove();	});
	else
 	  div.remove();
};

jtiddler.closeStatusMessages = function(tiddler) {
  $('#' + tiddler.id +' .tiddler_status_message').each(function() { 
    $(this).remove(); 
  });
};

jtiddler.closeTiddlerMessages = function() {
  $('.tiddler_msg').each(function() {
    jtiddler.containingTiddler(this).remove();
	});
};

jtiddler.makeTiddlerVisible = function(tiddler) {
	y = $(tiddler).offset().top; 
	$('html,body').animate({scrollTop: y}, 500);	
};


// =============== jtiddler ajax events ================

jtiddler.displayErrorMessage = function(spinner_id, tiddler_id, response_text) {
  $(spinner_id).remove();
  if ($('#' + tiddler_id + ' div.contents').length < 1)
    $('#' + tiddler_id).prepend(response_text);
  else
    $('#' + tiddler_id + ' div.contents').prepend(response_text);
  jtiddler.decorator.decorateHTML(tiddler_id);
};

jtiddler.commandHandler = function(url) {
	var new_id = jtiddler.createTiddler()[0];
  jtiddler.loadAjaxIntoTiddler(url, new_id, 'div.progress_indicator_large');
  return false;
};

jtiddler.loadAjaxIntoTiddler = function(url, tiddler_id, spinner_id, callback){
  spinner_id = '#' + tiddler_id + ' ' + spinner_id;
	$.ajax( {
		beforeSend	: function(request) { jtiddler.closeTiddlerMessages(); request.setRequestHeader("Accept", "text/javascript"); $(spinner_id).show(); },
		complete		: function(request) { $(spinner_id).hide(); jtiddler.decorator.decorateHTML(tiddler_id); },
		success			: function(request) { 
	            	    $('#' + tiddler_id).append(request);
            		    jtiddler.sizeTiddler('#' + tiddler_id);
            		    if($.isFunction(callback)) callback.call(this);
            		  },
		error       : function(request) { jtiddler.displayErrorMessage(spinner_id, tiddler_id, request.responseText); },
		type				: 'get',
		url				  : url } );
};

jtiddler.searchFormHandler = function(e) {
  // Form submissions
  if(e.currentTarget.nodeName == "FORM"){
    var form = e.target;
    var url = form.action + '?' + $.param($(form).serializeArray());
  	if(jtiddler.trim(form.q.value)=="" && jtiddler.trim(form.t.value)=="") return;
    if(form.t.value != "") {
      var caption = form.q.value + ' [tag:'+ jtiddler.trim(form.t.value) +']';
    } else {
      var caption = form.q.value;
    }
  	jtiddler.history.addToHistory("search", caption, url);
  } else {
    var caption = e.originalEvent.target.innerHTML;
    var url = e.originalEvent.target.href;
    jtiddler.history.addToHistory("search", caption, url);
  }

	var new_id = jtiddler.createTiddler()[0];
  jtiddler.loadAjaxIntoTiddler( 
    url, new_id, 'div.progress_indicator_large', 
    function() { jtiddler.decorator.queryTermHighlight(caption, new_id); });
  return false;
};

jtiddler.tiddlerLinkClick = function(tiddler, target) {
	jtiddler.history.addToHistory("link", target.textContent, target.href);
	var obj = jtiddler.createTiddler();
	var new_id = obj[0];
	var $new_tiddler = obj[1];
  // Not working due to refactoring!! 
  //if(tiddler == 1) $(tiddler).before($new_tiddler); else $("#search_results").prepend($new_tiddler);
  jtiddler.loadAjaxIntoTiddler( 
    target.href, new_id, 'div.progress_indicator_large', 
    function() { if(jtiddler.authentication.confirmLoggedIn()) jtiddler.history.getUserListItems(target.textContent, jtiddler.history.activeUserList) }
  );
	return false;
};

jtiddler.starLinkClick = function(tiddler, target) {
  if($(target).hasClass('star_clicked'))
    $(target).removeClass('star_clicked');
  else
    $(target).addClass('star_clicked');
  $(target).blur();
  jtiddler.history.addToUserList(target.href);
  return false;
};

jtiddler.monitorshipLinkClick = function(tiddler, target) {
  if($(target).hasClass('monitorship_clicked'))
    $(target).removeClass('monitorship_clicked');
  else
    $(target).addClass('monitorship_clicked');
  $(target).blur();
  $.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		complete		: function(request) { if($.evalJSON(request)){ $(target).removeClass('monitorship_clicked'); $(target).addClass('monitorship_clicked'); } else { $(target).removeClass('monitorship_clicked'); } },
		url				  : target.href }
	);
  return false;
};

jtiddler.voteLinkClick = function(tiddler, target) {
  if($(target).hasClass('vote_up'))
    var type = "up";
  else
    var type = "dn";
  $(target).blur();
  //Vote in the direction specified
  return false;
};

jtiddler.moreResultsClick = function(tiddler, target) {
	// Retrieve key DOM elements
	tiddler_id = tiddler[0].id;
	tiddler_contents_id = '#' + tiddler_id + ' div.contents';
	spinner_id = '#' + tiddler_id+' .progress_indicator';
	next_page_id = '#' + tiddler_id + ' code.next_page';
	next_page = $(next_page_id).attr('textContent');
	$tiddler_contents = $(tiddler_contents_id);
	var ht = $(tiddler_contents_id + ' ol.scrap_list').attr('scrollHeight'); // get height of list
	if(next_page == "0") return; // exit if at last page

  url=target.href;
  caption="";
  if(url.indexOf("q=") >0) {
    caption = url.substring(url.indexOf("q=")+2, url.length);
    endofstr = (caption.indexOf("&") > 0 ? caption.indexOf("&") : caption.length);
    caption = Url.decode(caption.substring(0,endofstr));
  }
  
	// request the next page
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); $(spinner_id).show(); },
		complete		: function(request) { 
										$(spinner_id).hide(); 
                    jtiddler.decorator.decorateHTML(tiddler_id);
                    jtiddler.decorator.queryTermHighlight(caption, tiddler_id);
										$tiddler_contents.animate({ scrollTop: ht }, 333);
										if($(next_page_id).attr('textContent') == "0")
											$('#' + tiddler_id + ' a.more').html('[end]'); // change button label
									},
		success			: function(request) { $(tiddler_contents_id + ' > ol.scrap_list').append( request ); },
		url					: jtiddler.concatQueryString(target.href, 'page=' + next_page + '&more=true') } );
	$(next_page_id +':first').remove(); // kill prev "nextpage" entry
	return false;
};

jtiddler.loadInCurrentTiddler = function(tiddler, target) {
  if(target.className.split(' ').indexOf("updates_parent") > -1)
    var target_element = target.parentNode.parentNode;
  else
    var target_element = jtiddler.containingTiddler(target)[0];
  if($(target_element).find(".progress_indicator").length > 0) return; // No double clicking please...
	jtiddler.history.addToHistory("link", target.textContent, target.href);
  $(target).after(jtiddler.TEMPLATES.spinner);
  var spinner =  $(target_element).find(".progress_indicator");
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); $(spinner).show(); },
  	complete		: function(request) { $(spinner).remove(); jtiddler.decorator.decorateHTML(tiddler.attr('id')); },
		success			: function(request) { $(target_element).empty(); $(target_element).prepend( request ); },
		url					: target.href } );
  return false;
};

jtiddler.submitTiddlerForm = function(target, e, callback) {
  e.preventDefault();
  if($(target).find(".progress_indicator").length > 0) return; // No double clicking or double processing allowed...
  tiddler = jtiddler.containingTiddler(target)[0];
  if(target.className =="updates_parent")
    var target_element = target.parentNode;
  else
    var target_element = tiddler;
  var form = target;
  var cancel_clicked = (jtiddler.state.lastFocusedEle.value == "Cancel" ? "&cancel=1" : "");
  $(jtiddler.state.lastFocusedEle).after(jtiddler.TEMPLATES.spinner);
  var spinner = $(target_element).find(".progress_indicator");
	$.ajax( {
		beforeSend	: function(request) { 
		  jtiddler.closeStatusMessages(tiddler);
		  jtiddler.closeTiddlerMessages();
		  request.setRequestHeader("Accept", "text/javascript");
		  $(spinner).show();
		},
    complete    : function(request) { $(spinner).remove(); jtiddler.decorator.decorateHTML(tiddler.id); },
		data				: $.param($(form).serializeArray()) + cancel_clicked,
		success			: function(request) { 
		  $(target_element).empty(); 
		  $(target_element).prepend( request ); 
		  if($.isFunction(callback)) callback.call(this);
		},
		error       : function(request) { jtiddler.displayErrorMessage(spinner, target_element.id, request.responseText); },
		type				: 'post',
		url				  : form.action } );
  return false;
};


// =============== history methods ================

jtiddler.history.init = function() {
  jtiddler.history.clickHandlers();
  jtiddler.history.loadFromCookie('search');
  jtiddler.history.loadFromCookie('link');
  jtiddler.history.activeUserList = "starred"; // this will become dynamic
  $(".tiddler").each( function() {　jtiddler.decorator.decorateHTML(this.id)　} ); // decorate statically loaded tiddlers
  if(jtiddler.authentication.confirmLoggedIn())
    jtiddler.history.getUserList(jtiddler.history.activeUserList);
  else
    jtiddler.history.showLoginPromptForUserList();
};

jtiddler.history.clickHandlers = function() {
	// Bind clicks from history lists
	$('#user_list, #link_history').click(function(e){
		e.preventDefault();
	  if($(e.target).is('a.remove'))
		  jtiddler.history.removeFromList(e.target);
		else if($(e.target).is('a') && e.target.className != "empty")
	    jtiddler.tiddlerLinkClick($('#search_results div.tiddler:first'), e.target);
		return false;
	});
	$('#search_history').click(function(e){
		e.preventDefault();
		if($(e.target).is('a') && e.target.className != "empty")
			jtiddler.searchFormHandler(e);
		return false;
	});
	// Clear User List
	$('a#clear_user_list').click(function(e){
    if(!confirm(jtiddler.i18n('confirm'))) return false;
		jtiddler.history.clearUL('user_list');
		jtiddler.history.clearUserList('user_list');
		return false;
	});
	// Clear Search History
	$('a#clear_search_history').click(function(e){
    if(!confirm(jtiddler.i18n('confirm'))) return false;
		jtiddler.history.clearCookie("search");
		jtiddler.history.clearUL('search');
		return false;
	});
	// Clear ScrapTopic History
	$('a#clear_link_history').click(function(e){
    if(!confirm(jtiddler.i18n('confirm'))) return false;
		jtiddler.history.clearCookie("link");
		jtiddler.history.clearUL('link');
		return false;
	});
};

jtiddler.history.getIdentifier = function(type) {
  if(type == 'search')
    return type + '_history';
  else if(type == 'link')
    return type + '_history';
  else if(type == 'user_list')
    return type;
};

jtiddler.history.clearUL = function(type) {
  var identifier = jtiddler.history.getIdentifier(type);
  var container = 'ul#' + identifier;
	$(container + ' li').remove();
	$(container).append( eval('jtiddler.TEMPLATES.' + identifier + '_empty') );
};

jtiddler.history.addToHistory = function(type, caption, url) {
  var container = 'ul#' + jtiddler.history.getIdentifier(type);
	$(container + ' li.empty').remove();
	$(container + ' li').each(function(){
		if(this.firstChild.href == url) $(this).remove();
	});
	$(container).hide().prepend('<li><a href="'+ url +'">' + caption + '</li>').fadeIn("fast");
	jtiddler.history.saveCookie(type);
};

jtiddler.history.getCookieName = function(type) {
  return 'npedia_' + jtiddler.history.getIdentifier(type);
};

jtiddler.history.loadFromCookie = function(type) {
  var container = 'ul#' + jtiddler.history.getIdentifier(type);
  var cookie_name = jtiddler.history.getCookieName(type);
	var cookie_data = $.cookie(cookie_name);
	var history_data = (cookie_data != "" ? $.evalJSON(cookie_data) : "");
	if(history_data) {
		$(container + ' li:first').remove();
		for (i=0;i<history_data.length;i++)
			$(container).append('<li><a href="'+ history_data[i][0] +'">' + history_data[i][1] + '</li>');
  } else {
		jtiddler.history.clearUL(type);
	}
};

jtiddler.history.saveCookie = function(type) {
  var container = 'ul#' + jtiddler.history.getIdentifier(type);
  var cookie_name = jtiddler.history.getCookieName(type);
	var history_array = new Array();
	$.cookie(cookie_name, "");
	$(container + ' li a').each(function(){
    history_array.push([$(this).attr('href'), $(this).attr('textContent')]);
	});
	$.cookie(cookie_name, $.toJSON(history_array));
};

jtiddler.history.clearCookie = function(type) {
  cookie_name = jtiddler.history.getCookieName(type);
  $.cookie(cookie_name, "");
};

jtiddler.history.getUserList = function(list_name) {
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		success			: function(request) { jtiddler.history.clearUserList(); $('ul#user_list').hide().append(request).fadeIn("fast"); },
		error       : function(request) { jtiddler.history.showLoginPromptForUserList(); },
		type				: 'get',
		url				  : '/list/load?name=' + list_name } );
};

jtiddler.history.getUserListItems = function(key, list_name) {
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		success			: function(request) { jtiddler.decorator.updateStars(request); },
		type				: 'get',
		url				  : '/list/contains?name=' + list_name +'&scrap_topic_id=' + key } );
};

jtiddler.history.addToUserList = function(url_stem) {
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		success			: function(request) { jtiddler.history.clearUserList(); $('ul#user_list').hide().append(request).fadeIn("fast"); },
		type				: 'get',
		url				  : jtiddler.concatQueryString(url_stem, 'name=' + jtiddler.history.activeUserList) } );
};

jtiddler.history.removeFromList = function(target) {
  parent = target.parentNode;
  url = target.href;
	$(target.parentNode).remove();
	$.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		success			: function(request) { jtiddler.decorator.clearStar(target.id); },
		type				: 'get',
		url				  : jtiddler.concatQueryString(url, 'name=' + jtiddler.history.activeUserList) } );
};

jtiddler.history.clearUserList = function(id) {
  $('ul#user_list li').remove();
  $('ul#user_list li').hide().append(jtiddler.TEMPLATES.user_list_empty).fadeIn("fast");
};

jtiddler.history.deleteUserList = function(id) {
  $.ajax( {
		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
		url				  : '/list/empty' + '?name=' + jtiddler.history.activeUserList } 
	);
}

jtiddler.history.showLoginPromptForUserList = function(id) {
  $('ul#user_list').empty();
  $('ul#user_list').append('<small>* '+jtiddler.i18nStrings['en']['login_for_starred_lists']+'</small>');
}


// =============== utility methods ================

jtiddler.loadTiddlerFromTemplate = function(e, id, into){
  if(!into) into ="tiddler";

  // Into new tiddler?
  if(into == "search_results"){
  	var new_id = jtiddler.createTiddler()[0];
  	var $new_tiddler = jtiddler.createTiddler()[1];
    spinner_id = '#'+new_id+' div.progress_indicator_large';
    $(spinner_id).show();
    $('#'+ id).clone(true).prependTo('#'+new_id);
    $(spinner_id).hide();
    $('#'+ new_id + ' .contents').attr('id','');
    $('#'+ new_id + ' .contents').show();
  }
  else {
    // Into tiddler's scrap_list <li> of existing tiddler?
    var tiddler_id = jtiddler.containingTiddler(e).attr('id');
    var new_form_id = tiddler_id +'_add_scrap_form';
    var template = id +'_template';
    $('#' + template).clone(false).insertAfter('#' + tiddler_id +' h2');
    $('#' + tiddler_id + ' div.add_scrap_form').attr('id', new_form_id);
    $('#' + tiddler_id + ' div.add_scrap_form').show();
    //This code is hacky, it should be made more generic
    $('#' + tiddler_id + ' div.add_scrap_form form').each(function(){
      if(this.action.indexOf("SCRAP_TOPIC_ID") > -1)
        //Rewrite the form actions, replacing the "SCRAP_TOPIC_ID" marker with the embedded id
  	    this.action = this.action.replace("SCRAP_TOPIC_ID", $('#' + tiddler_id + ' code.scrap_topic_id')[0].textContent);
  	});
  }
  jtiddler.decorator.enableTabs(tiddler_id);
  return;
};

jtiddler.sizeTiddler = function(id) {
	var ht = $(id + ' div.contents' + ' ol.scrap_list').attr('scrollHeight'); // get height of list
  if(ht > jtiddler.options.defaultHeight)
    $(id + ' div.contents').height(jtiddler.options.defaultHeight + 'px');
  else
    $(id + ' div.contents').height('auto');
};

jtiddler.containingTiddler = function(ele) {
	$tiddler = $(ele).parents('div.tiddler');
	if($tiddler.length == 1) {
		return $tiddler;
	} else {
		return null;
	}	
};

jtiddler.containingDivByClass = function(ele, klass) {
	$div = $(ele).parents('div.' + klass);
	if($div.length == 1) {
		return $div;
	} else {
		return null;
	}	
};

jtiddler.createTiddlerID = function() {
	return String((new Date()).getTime()).replace(/\D/gi,'') + '-'+ Math.floor(Math.random()*10001);
};

jtiddler.tiddlify = function(html, id) {
  if(!id) id = jtiddler.createTiddlerID();
	str = '<div class="tiddler" id="'+ id + '">' + html + '</div>';
	$('#spinner'+id).remove();
	return str;
};

jtiddler.trim = function(str) {
	str = str.replace(/^\s+/, '');
	for (var i = str.length - 1; i >= 0; i--) {
		if (/\S/.test(str.charAt(i))) {
			str = str.substring(0, i + 1);
			break;
		}
	}
	return str;
};

jtiddler.concatQueryString = function(url, suffix){
  qstr_arr = url.split('?');
  if(qstr_arr.length > 1){
    //Question mark found
    if(url.substr(url.length, -1) == "&")
      return url + suffix;
    else
      return url + '&' + suffix;
  }
  else
    return url + '?' + suffix;
};


// =============== autocomplete data storage ================

jtiddler.data['ac'] = {};
jtiddler.getACData = function(id){
  if(!jtiddler.data.ac[id]){
    $.ajax( {
  		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
  	  complete    : function(request) { jtiddler.data.ac[id] = request.responseText.split("\n"); },
  	  async       :   false,
    	url				  : '/autocomplete/'+ id +'?q=' }
  	);
  }
  return jtiddler.data.ac[id];
};


// =============== authentication methods ================
// Controls login form loading, login form submission, 
// login link and logout link
/* How to use it?
  1. (optional) Specify jtiddler.authentication.pageElements (login/logout link IDs)
  2. Upon clicking 'login', special event handler added on success
  3. User submits login form, 200 = success, 401 = error (dispayed using in-tiddler status message ... new!)
  4. On Successful Login/Logout, related UI elements refreshed from server */

// default selectors for page elements
jtiddler.authentication.pageElements = {};
jtiddler.authentication.pageElements.loginLinkSelector  = "#navbar #rightbar #login";
jtiddler.authentication.pageElements.logoutLinkSelector  = "#navbar #rightbar #logout";
jtiddler.authentication.pageElements.loginFormSelector = "form#login_form";
jtiddler.authentication.loggedInURL = "/users/ajax_logged_in";
jtiddler.authentication.loggedInStatus = null;
jtiddler.authentication.loggedInLastChecked = null; // don't set this manually!

jtiddler.authentication.init = function() {
  // add click handlers to nav bar (#logout, #login)
	$(jtiddler.authentication.pageElements.loginLinkSelector).unbind("click").click(function(e) { jtiddler.authentication.loadLoginForm(e); e.stopPropagation(); });
	$(jtiddler.authentication.pageElements.logoutLinkSelector).unbind("click").click(function(e) { jtiddler.authentication.logoutClickHandler(e); e.stopPropagation(); });
};

jtiddler.authentication.loadLoginForm = function(target) {
  // upon clicking login, refresh elements on success, errors passed back via in-tiddler "status messages" (new!)
  target.preventDefault();
	var new_id = jtiddler.createTiddler()[0];
  jtiddler.loadAjaxIntoTiddler(target.currentTarget.href, new_id, 'div.progress_indicator_large',
    function() { 
      $(jtiddler.authentication.pageElements.loginFormSelector).unbind("submit").submit(function(e) { jtiddler.submitTiddlerForm(e.target, e, 
        function(e) { jtiddler.authentication.setAsLoggedIn(); jtiddler.history.getUserList(jtiddler.history.activeUserList); });
      });
    }
  );
  return false;
};

jtiddler.authentication.logoutClickHandler = function(target) {
  // upon clicking logout, refresh elements on completion
   target.preventDefault();
 	 var new_id = jtiddler.createTiddler()[0];
   jtiddler.loadAjaxIntoTiddler(target.currentTarget.href, new_id, 'div.progress_indicator_large', 
    function(){ jtiddler.authentication.setAsLoggedOut(); jtiddler.history.showLoginPromptForUserList(); }
  );
};

jtiddler.authentication.toggleLoginUIElements = function(action) {
  if(action == 'login') {
    $('.login_required_element').show();
    $('.logout_required_element').hide();
  }
  else if (action == 'logout'){
    $('.login_required_element').hide();
    $('.logout_required_element').show();
  }
  else {
    // Blind toggle - check status and change accordingly
    if(jtiddler.authentication.confirmLoggedIn()) {
      $('.login_required_element').show();
      $('.logout_required_element').hide();
    }
    else{
      $('.login_required_element').hide();
      $('.logout_required_element').show();
    }
  }
}

jtiddler.authentication.setAsLoggedOut = function(mode) {
  now = new Date();
  jtiddler.authentication.loggedInStatus = false;
  jtiddler.authentication.loggedInLastChecked = now; 
}

jtiddler.authentication.setAsLoggedIn = function(mode) {
  now = new Date();
  jtiddler.authentication.loggedInStatus = true;
  jtiddler.authentication.loggedInLastChecked = now; 
}


jtiddler.authentication.confirmLoggedIn = function(mode) {
  var doCheckLogin = false;
  var now = new Date();
  if(mode=='force') doCheckLogin = true;
  if(jtiddler.authentication.loggedInLastChecked == null){
    // Check now if never checked!
    jtiddler.authentication.loggedInLastChecked = new Date();
    doCheckLogin = true;
  }
  else if (jtiddler.authentication.loggedInLastChecked ){
    if ( (now.getTime()  - jtiddler.authentication.loggedInLastChecked.getTime()) / 60000 > 3) // check again every 3 minutes
      doCheckLogin = true;
  }

  if (doCheckLogin){
    var response = $.ajax( {
    		beforeSend	: function(request) { request.setRequestHeader("Accept", "text/javascript"); },
    	  async       : false,
    		url				  : jtiddler.authentication.loggedInURL }
    );
    response = (response.responseText == "true" ? true : false);
    jtiddler.authentication.loggedInLastChecked = now;
    jtiddler.authentication.loggedInStatus = response;
    return response;
  }
  else {
    return jtiddler.authentication.loggedInStatus;
  }
};


// =============== decorator methods ================
// These are methods that have multiple external dependancies beyond the 
// core search interface (#search_results, #user_list, #search_results, #link_history)

jtiddler.decorator.updateStars = function(json) {
  var data = eval(json);
  for(var i=data.length-1; i>=0; --i) {
    if(data[i].listable_type =="ScrapTopic")
      $("#star_scrap_topic_" + data[i].listable_id).removeClass("star_clicked").addClass("star_clicked");
    else
      $("#star_scrap_" + data[i].listable_id).removeClass("star_clicked").addClass("star_clicked");
  }
};

jtiddler.decorator.updateMonitored = function(json) {
/*
//Not finished!!!
  var data = eval(json);
  for(var i=data.length-1; i>=0; --i) {
    if(data[i].listable_type =="ScrapTopic")
      $("#star_scrap_topic_" + data[i].listable_id).removeClass("monitorship_clicked").addClass("monitorship_clicked");
    else
      $("#star_scrap_" + data[i].listable_id).removeClass("monitorship_clicked").addClass("monitorship_clicked");
  }
*/
};

jtiddler.decorator.clearStar = function(star_id) {
	if(star_id.search("remove")) star_id.replace("star", "remove");
  $(star_id).removeClass("star_clicked");
};

jtiddler.decorator.focusCursor = function(tiddler) {
  // TODO - give the first input element the focus (inside given tiddler)
};

jtiddler.decorator.decorateHTML = function(tiddler_id) {

  //Toggle login dependant items
  jtiddler.authentication.toggleLoginUIElements();
  
  // Bind auto complete to tags input field
  $('#'+ tiddler_id +' input.scrap_topics_auto').autocomplete("/autocomplete/scrap_topics", {
	  matchSubset: true,
    width: 450,
    delay: 200,
    smorgasbord: true,
    unique: true,
    highlight: false,
    multiple: false,
    multipleSeparator: " ",
    inputClass: "scrap_topics_auto",
    loadingClass: "scrap_topics_auto_loading",
    scroll: true,
    cacheLength: 300,
    scrollHeight: 200
	});

  // Enforce default button submissions - add listener to tiddler forms
  $('#'+ tiddler_id +' form').each(function() { // loop thru all forms on the page
		var def_btn = this.getElementsByClassName("default_submit"); // search default submit button
		if(def_btn!=null && def_btn.length>0){
		  $('input', this).keypress(function(e){ 
        // attach onkeypress event listener for each input field
        var keycode;
				if (window.event) { //IE
					keycode = window.event.keyCode;
				}else if (e) { //FF
					keycode = e.which;
				}else {
					return true;
				}
				if(keycode==13) {
					def_btn[0].click();  // emulates click on btn
					return false;   // stops event bubbling up
        }
      });
    }
  });
  
  // Apply tag-ac decorator
  //$('')
  
  // Add listener to form elements
  jtiddler.decorator.trackFormElementFocus(tiddler_id);
};

jtiddler.decorator.init = function () {
  // tiddler toolbar mouse-over/out opacity control
	$("div#search_results").mouseout(function(e){
		tgt = $(e.target);
    if (tgt.is('div.toolbar') || tgt.is('div.toolbarsmall')) {
			tgt.css("opacity", "0.45");
		} else if (tgt.is('a.close_tiddler') || tgt.is('a.close_others') || tgt.is('a.more') || tgt.is('a.expand') || tgt.is('a.flatten')) {
    	tgt.parent().css("opacity", "0.45");

		}
  }).mouseover(function(e){
		tgt = $(e.target);
    if (tgt.is('div.toolbar') || tgt.is('div.toolbarsmall')) {
			tgt.css("opacity", "0.8");
		} else if (tgt.is('a.close_tiddler') || tgt.is('a.close_others') || tgt.is('a.more') || tgt.is('a.expand') || tgt.is('a.flatten')) {
    	tgt.parent().css("opacity", "0.8");
		}
  });
  // Add listener to form elements
  jtiddler.decorator.trackFormElementFocus();
};

jtiddler.decorator.trackFormElementFocus= function(tiddler_id){
  // Track which form element last had the focus
  var myselector = (tiddler_id == null ? 'div#search_results :input' : '#'+ tiddler_id + ' :input');
  $(myselector).each(function(){
      $(this).unbind("focus").unbind("blur");
      $(this).focus( function(e) { jtiddler.state.lastFocusedEle = this; });
      $(this).click( function(e) { jtiddler.state.lastFocusedEle = this; });
      $(this).blur( function() { jtiddler.state.lastFocusedEle = null; });
  });
}

jtiddler.decorator.queryTermHighlight = function(qs, tiddler_id) {
  // Syntax highlight search results
/*  if(qs == "" || qs == null) return;
  qs = qs.replace(/\u3000/g, " "); //replace zenkaku spaces!
  jQuery.each(qs.split(" "), function(idx, val) { 
    $("#" + tiddler_id + " div.contents li").highlight(val);
  });
  // Causing endless loops sometimes!!
*/
};