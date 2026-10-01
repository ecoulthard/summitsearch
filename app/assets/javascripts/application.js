// Application JavaScript Bundle for SummitSearch


// === jMenu-jquery.js ===

/************************************************************************
*************************************************************************
@Name :       	jMenu - jQuery Plugin
@Revison :    	1.8
@Date : 		01/2012
@Author:     	ALPIXEL - (www.myjqueryplugins.com - www.alpixel.fr)
@Support:    	FF, IE7, IE8, MAC Firefox, MAC Safari
@License :		Open Source - MIT License : http://www.opensource.org/licenses/mit-license.php
 
**************************************************************************
*************************************************************************/

/** 
@ IsHovered Plugin 
@ Thanks to Chad Smith fr his isHovered Plugin 
@ source : http://mktgdept.com/jquery-ishovered
**/
;(function(b,c){b('*').hover(function(){b(this).data(c,1)},function(){b(this).data(c,0)}).data(c,0);b[c]=function(a){return b(a)[c]()};b.fn[c]=function(a){a=0;b(this).each(function(){a+=b(this).data(c)});return a>0}})(jQuery,'isHovered');


/** jMenu Plugin **/
(function($){

    var activeAt = new Date(); // A flag indicating when the menu was last activated

	$.jMenu = {
		/**************/
		/** OPTIONS **/
		/**************/
		defaults: {
			ulWidth : 'auto',
			absoluteTop : 30,
			absoluteLeft : 0,
			effects : {
				effectSpeedOpen : 350,
				effectSpeedClose : 350,
				effectTypeOpen : 'slide',
				effectTypeClose : 'slide',
				effectOpen : 'linear',
				effectClose : 'linear'
			},
			TimeBeforeOpening : 200,
			TimeBeforeClosing : 200,
			animatedText : false,
			paddingLeft: 7,
			openClick : false
		},
		
		/*****************/
		/** Init Method **/
		/*****************/
		init:function(options){
			/* vars **/
			opts = $.extend({}, $.jMenu.defaults, options);
			
			$("#jMenu a:not(.fNiv)").each(function(){
				var $thisChild = $(this);
				
				/* Add css - arrow right */
				if($.jMenu._IsParent($thisChild))
					$thisChild.addClass('isParent');
					
				/* Add the animation on hover **/
				if(opts.animatedText)
					$.jMenu._animateText($thisChild);
				
				/* Actions on hover */
				if(!opts.openClick)
				    $thisChild.bind({
					    mouseover:function(){
                            activeAt = new Date();
						    $.jMenu._hide($thisChild);
						    $.jMenu._showNextChild($thisChild);
					    }
				    });
				else{
				    $thisChild.bind({
					    click:function(){
                            activeAt = new Date();
						    $.jMenu._hide($thisChild);
						    $.jMenu._showNextChild($thisChild);
					    }
				    });
                    $thisChild.bind({
					    mouseover:function(){
                            activeAt = new Date();
					    }
				    });
                }
			});
			
			/* Actions on parents links */
			if(!opts.openClick)
			    $('#jMenu li a.fNiv').bind({
				    mouseover:function(){
                        activeAt = new Date();
					    var $this = $(this);
					    var $child = $this.next();
					    ULWidth = $.jMenu._returnUlWidth($this);
					    $.jMenu._closeList($("#jMenu ul"));
					    if($child.is(':hidden'))
						    $.jMenu._showFirstChild($this);
				    }
			    });
			else {
            	$('#jMenu li a.fNiv').bind({
				    mouseover:function(){
                        activeAt = new Date();
                    }
                });
			    $('#jMenu li a.fNiv').bind({
				    click:function(e){
                        activeAt = new Date();
					    e.preventDefault();
					    var $this = $(this);
					    var $child = $this.next();
					    ULWidth = $.jMenu._returnUlWidth($this);
					    $.jMenu._closeList($("#jMenu ul"));
					    if($child.is(':hidden'))
						    $.jMenu._showFirstChild($this);
				    }
			    });
            }
			/* Close all when mouse  leaves */
			$('#jMenu').bind({
				mouseleave : function(){
                    var timeout = new Date();
					setTimeout(function(){
                        //If they haven't hovered over the menu since the timeout began then close.
                        if(activeAt < timeout)
                            $.jMenu._closeAll();
                    },opts.TimeBeforeClosing);
				}
			});
		},
		
		
		/****************************
		*****************************
			jMenu Methods Below
		*****************************
		****************************/
		
		/** Show the First Child Lists **/
		_showFirstChild:function(el){
			
			if($.jMenu._IsParent(el))
			{
				var SecondList = el.next();
				
				if(SecondList.is(":hidden"))
				{
					var position = el.position();
					
					SecondList
					.css({
						top : position.top + opts.absoluteTop,
						left : position.left + opts.absoluteLeft,
						width : ULWidth
					})
					.children().css({
						width: ULWidth
					});
					
					$.jMenu._show(SecondList);
				}
			}
			else
				return false;
		},
		
		/** Show all others Child lists except the first list **/
		_showNextChild:function(el){
			if($.jMenu._IsParent(el))
			{
				var ChildList = el.next();
				if(ChildList.is(":hidden"))
				{
					var position = el.position();
					
					ChildList
					.css({
						top : position.top,
						left : position.left + ULWidth,
						width : ULWidth
					})
					.children().css({
						width:ULWidth
					});
					$.jMenu._show(ChildList);
					
				}
			}
			else
				return false;
		},
		
		
		/**************************************/
		/** Short Methods - Generals actions **/
		/**************************************/
		_hide:function(el){
			if($.jMenu._IsParent(el) && !el.next().is(':hidden')) 
				$.jMenu._closeList(el.next());
			else if(($.jMenu._IsParent(el) && el.next().is(':hidden')) || !$.jMenu._IsParent(el)) 
				$.jMenu._closeList(el.parent().parent().find('ul'));
			else
				return false;
		},
		
		_show:function(el) {
			switch(opts.effects.effectTypeOpen)
			{
				case 'slide':
					el.stop(true, true).delay(opts.TimeBeforeOpening).slideDown(opts.effects.effectSpeedOpen, opts.effects.effectOpen);
					break;
				case 'fade':
					el.stop(true, true).delay(opts.TimeBeforeOpening).fadeIn(opts.effects.effectSpeedOpen, opts.effects.effectOpen);
					break;
				default :
					el.stop(true, true).delay(opts.TimeBeforeOpening).show();
			}
		},
		
		_closeList:function(el) {
			switch(opts.effects.effectTypeClose)
			{
				case 'slide':
					el.stop(true,true).slideUp(opts.effects.effectSpeedClose, opts.effects.effectClose);
					break;
				case 'fade':
					el.stop(true,true).fadeOut(opts.effects.effectSpeedClose, opts.effects.effectClose);
					break;
				default :
					el.hide();
			}
			
		},
		
		_closeAll:function(){
			if(!$('#jMenu').isHovered()) {
				$('#jMenu ul').each(function(){
					$.jMenu._closeList($(this));
				});
			}
		},
		
		_IsParent:function(el) {
			if(el.next().is('ul')) return true;
			else return false;
		},
		
		_returnUlWidth:function(el) {
			switch(opts.ulWidth) {
				case "auto" :
					ULWidth = parseInt(el.parent().outerWidth());
					break;
				default :
					ULWidth = parseInt(opts.ulWidth);
			}
			return ULWidth;
		},
		
		_animateText:function(el) {
			var paddingInit = parseInt(el.css('padding-left'));
			
			el.hover(function(){
				$(this)
				.stop(true,true)
				.animate({
					paddingLeft: paddingInit + opts.paddingLeft
				}, 100);
			}, function(){
				$(this)
				.stop(true,true)
				.animate({
					paddingLeft:paddingInit
				}, 100);
			});
		},
		
		_isReadable:function(){
			if($("a.fNiv").length > 0)	return true;
			else return false;
		},
		
		_error:function(){
			//alert('Please, check you have the \'.fNiv\' class on your first level links.');
		}
	};
	
	jQuery.fn.jMenu = function(options){
		if($.jMenu._isReadable())
			$.jMenu.init(options);
		else
			$.jMenu._error();
	};
})(jQuery); 


// === jquery.easing.1.3.js ===

/*
 * jQuery Easing v1.3 - http://gsgd.co.uk/sandbox/jquery/easing/
 *
 * Uses the built in easing capabilities added In jQuery 1.1
 * to offer multiple easing options
 *
 * TERMS OF USE - jQuery Easing
 * 
 * Open source under the BSD License. 
 * 
 * Copyright © 2008 George McGinley Smith
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, this list of 
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list 
 * of conditions and the following disclaimer in the documentation and/or other materials 
 * provided with the distribution.
 * 
 * Neither the name of the author nor the names of contributors may be used to endorse 
 * or promote products derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 *  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
*/

// t: current time, b: begInnIng value, c: change In value, d: duration
jQuery.easing['jswing'] = jQuery.easing['swing'];

jQuery.extend( jQuery.easing,
{
	def: 'easeOutQuad',
	swing: function (x, t, b, c, d) {
		//alert(jQuery.easing.default);
		return jQuery.easing[jQuery.easing.def](x, t, b, c, d);
	},
	easeInQuad: function (x, t, b, c, d) {
		return c*(t/=d)*t + b;
	},
	easeOutQuad: function (x, t, b, c, d) {
		return -c *(t/=d)*(t-2) + b;
	},
	easeInOutQuad: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t + b;
		return -c/2 * ((--t)*(t-2) - 1) + b;
	},
	easeInCubic: function (x, t, b, c, d) {
		return c*(t/=d)*t*t + b;
	},
	easeOutCubic: function (x, t, b, c, d) {
		return c*((t=t/d-1)*t*t + 1) + b;
	},
	easeInOutCubic: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t + b;
		return c/2*((t-=2)*t*t + 2) + b;
	},
	easeInQuart: function (x, t, b, c, d) {
		return c*(t/=d)*t*t*t + b;
	},
	easeOutQuart: function (x, t, b, c, d) {
		return -c * ((t=t/d-1)*t*t*t - 1) + b;
	},
	easeInOutQuart: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
		return -c/2 * ((t-=2)*t*t*t - 2) + b;
	},
	easeInQuint: function (x, t, b, c, d) {
		return c*(t/=d)*t*t*t*t + b;
	},
	easeOutQuint: function (x, t, b, c, d) {
		return c*((t=t/d-1)*t*t*t*t + 1) + b;
	},
	easeInOutQuint: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
		return c/2*((t-=2)*t*t*t*t + 2) + b;
	},
	easeInSine: function (x, t, b, c, d) {
		return -c * Math.cos(t/d * (Math.PI/2)) + c + b;
	},
	easeOutSine: function (x, t, b, c, d) {
		return c * Math.sin(t/d * (Math.PI/2)) + b;
	},
	easeInOutSine: function (x, t, b, c, d) {
		return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;
	},
	easeInExpo: function (x, t, b, c, d) {
		return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
	},
	easeOutExpo: function (x, t, b, c, d) {
		return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
	},
	easeInOutExpo: function (x, t, b, c, d) {
		if (t==0) return b;
		if (t==d) return b+c;
		if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
		return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
	},
	easeInCirc: function (x, t, b, c, d) {
		return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;
	},
	easeOutCirc: function (x, t, b, c, d) {
		return c * Math.sqrt(1 - (t=t/d-1)*t) + b;
	},
	easeInOutCirc: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;
		return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;
	},
	easeInElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
	},
	easeOutElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
	},
	easeInOutElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
		return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
	},
	easeInBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*(t/=d)*t*((s+1)*t - s) + b;
	},
	easeOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
	},
	easeInOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158; 
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	},
	easeInBounce: function (x, t, b, c, d) {
		return c - jQuery.easing.easeOutBounce (x, d-t, 0, c, d) + b;
	},
	easeOutBounce: function (x, t, b, c, d) {
		if ((t/=d) < (1/2.75)) {
			return c*(7.5625*t*t) + b;
		} else if (t < (2/2.75)) {
			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
		} else if (t < (2.5/2.75)) {
			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
		} else {
			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
		}
	},
	easeInOutBounce: function (x, t, b, c, d) {
		if (t < d/2) return jQuery.easing.easeInBounce (x, t*2, 0, c, d) * .5 + b;
		return jQuery.easing.easeOutBounce (x, t*2-d, 0, c, d) * .5 + c*.5 + b;
	}
});

/*
 *
 * TERMS OF USE - EASING EQUATIONS
 * 
 * Open source under the BSD License. 
 * 
 * Copyright © 2001 Robert Penner
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, this list of 
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list 
 * of conditions and the following disclaimer in the documentation and/or other materials 
 * provided with the distribution.
 * 
 * Neither the name of the author nor the names of contributors may be used to endorse 
 * or promote products derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 *  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 */

// === jquery.textarea-expander.js ===

/**
 * TextAreaExpander plugin for jQuery
 * v1.0
 * Expands or contracts a textarea height depending on the
 * quatity of content entered by the user in the box.
 *
 * By Craig Buckler, Optimalworks.net
 *
 * As featured on SitePoint.com:
 * http://www.sitepoint.com/blogs/2009/07/29/build-auto-expanding-textarea-1/
 *
 * Please use as you wish at your own risk.
 */

/**
 * Usage:
 *
 * From JavaScript, use:
 *     $(<node>).TextAreaExpander(<minHeight>, <maxHeight>);
 *     where:
 *       <node> is the DOM node selector, e.g. "textarea"
 *       <minHeight> is the minimum textarea height in pixels (optional)
 *       <maxHeight> is the maximum textarea height in pixels (optional)
 *
 * Alternatively, in you HTML:
 *     Assign a class of "expand" to any <textarea> tag.
 *     e.g. <textarea name="textarea1" rows="3" cols="40" class="expand"></textarea>
 *
 *     Or assign a class of "expandMIN-MAX" to set the <textarea> minimum and maximum height.
 *     e.g. <textarea name="textarea1" rows="3" cols="40" class="expand50-200"></textarea>
 *     The textarea will use an appropriate height between 50 and 200 pixels.
 */

(function($) {

	// jQuery plugin definition
	$.fn.TextAreaExpander = function(minHeight, maxHeight) {

		//var hCheck = !($.browser.msie || $.browser.opera);

		// resize a textarea
		function ResizeTextarea(e) {

			// event or initialize element?
			e = e.target || e;

			// find content length and box width
			var vlen = e.value.length, ewidth = e.offsetWidth;
			if (vlen != e.valLength || ewidth != e.boxWidth) {

				//if (hCheck && (vlen < e.valLength || ewidth != e.boxWidth)) e.style.height = "0px";
				var h = Math.max(e.expandMin, Math.min(e.scrollHeight, e.expandMax));

				e.style.overflow = (e.scrollHeight > h ? "auto" : "hidden");
				e.style.height = h + "px";

				e.valLength = vlen;
				e.boxWidth = ewidth;
			}

			return true;
		};

		// initialize
		this.each(function() {

			// is a textarea?
			if (this.nodeName.toLowerCase() != "textarea") return;

			// set height restrictions
			var p = this.className.match(/expand(\d+)\-*(\d+)*/i);
			this.expandMin = minHeight || (p ? parseInt('0'+p[1], 10) : 0);
			this.expandMax = maxHeight || (p ? parseInt('0'+p[2], 10) : 99999);

			// initial resize
			ResizeTextarea(this);

			// zero vertical padding and add events
			if (!this.Initialized) {
				this.Initialized = true;
				$(this).css("padding-top", 0).css("padding-bottom", 0);
				$(this).bind("keyup", ResizeTextarea).bind("focus", ResizeTextarea);
			}
		});

		return this;
	};

})(jQuery);


// initialize all expanding textareas
jQuery(document).ready(function() {
	jQuery("textarea[class*=expand]").TextAreaExpander();
});


// === trimble.mytopo.v3.js ===

﻿var trimble = {
    scriptBaseUrl: null,
    myTopo: {
        partnerID: null,
        hash: null,
        isError: function () {
            if (!this.partnerID || !this.hash) {
                var el = typeof $ !== 'undefined' ? $("#trimble-data") : null;
                if (el && el.length) {
                    this.partnerID = this.partnerID || el.data("partner-id");
                    this.hash = this.hash || el.data("hash");
                }
            }
            return !(this.partnerID && this.hash);
        },
        MapTypeId: {
            Topo: "MyTopoTopoBaseLayer"
        },
        topoBaseLayer: null,
        getTopoBaseLayer: function () {
            if (!this.topoBaseLayer && typeof google !== 'undefined' && google.maps && google.maps.ImageMapType) {
                this.topoBaseLayer = new google.maps.ImageMapType({
                    getTileUrl: function (coord, zoom, ownerDocument) {
                        return "http://tileserver.mytopo.com/SecureTile/TileHandler.ashx?mapType=Topo&partnerID=" + trimble.myTopo.partnerID + "&hash=" + trimble.myTopo.hash + "&x=" + coord.x + "&y=" + coord.y + "&z=" + zoom;
                    },
                    tileSize: new google.maps.Size(256, 256),
                    name: 'MyTopo',
                    //alt: 'MyTopo Enhanced Topo Maps',
                    maxZoom: 16,
                    minZoom: 9
                });
            }
            return this.topoBaseLayer;
        },
        map: null,
        //Call this to initialize your map database, so that you can reference map types by ID.
        init: function (map) {
            this.map = map;
            if (this.isError()) {
                alert("[MyTopo]: You must supply both the partnerID and hash in the query string of the trimble.mytopo.js");
            } else {
                var layer = this.getTopoBaseLayer();
                if (layer) {
                    map.mapTypes.set(trimble.myTopo.MapTypeId.Topo, layer);
                    map.mapTypeControlOptions.mapTypeIds.splice(0, 0, trimble.myTopo.MapTypeId.Topo);
                }
            }

            if (typeof google !== 'undefined' && google.maps && google.maps.event) {
                google.maps.event.addListener(map, 'maptypeid_changed', this.updateCopyright);
            }

            if (this.copyrightDiv == null) {
                // Create div for showing copyrights.
                this.copyrightDiv = document.createElement('div');
                this.copyrightDiv.id = 'mytopo-copyright-control';
                this.copyrightDiv.style.fontSize = '11px';
                this.copyrightDiv.style.fontFamily = 'Arial, sans-serif';
                this.copyrightDiv.style.margin = '0 2px 2px 0';
                this.copyrightDiv.style.whiteSpace = 'nowrap';
                this.copyrightDiv.style.color = '#FF4500';
                this.copyrightDiv.index = 0;
                this.copyrightDiv.innerHTML = trimble.myTopo.getBannerHtml();
            }
            if (typeof google !== 'undefined' && google.maps && google.maps.ControlPosition) {
                map.controls[google.maps.ControlPosition.BOTTOM_RIGHT].push(this.copyrightDiv);
            }
            this.updateCopyright();
        },
        printMap: function () {
            var lat = trimble.myTopo.map.getCenter().lat();
            var lng = trimble.myTopo.map.getCenter().lng();
            var url = 'http://www.mytopo.com/searchgeo.cfm?lat=' + lat + '&lon=' + lng + '&partnerid=' + trimble.myTopo.partnerID;
            //setup our fancybox
            jQuery.fancybox({
                'width': '803',
                'height': '70%',
                'autoScale': false,
                'transitionIn': 'none',
                'transitionOut': 'none',
                'type': 'iframe',
                'href': url
            });
            return false;
        },
        getBannerHtml: function () {
            switch (trimble.myTopo.partnerID) {
                case 839:
                    return '&#169; MyTopo <a href="http://mytopo.com/about/terms.cfm" target="_blank"><b>(MyTopo Terms of Use)</b></a>';
                    break;
				case 12288:
                    return '&#169; MyTopo <a href="http://mytopo.com/about/terms.cfm" target="_blank"><b>(MyTopo Terms of Use)</b></a>';
                    break;
                //case 49: 
                default:
                    return "<a id='printMyTopoMap' href='#printMap' onclick='return trimble.myTopo.printMap();'><img src='" + trimble.scriptBaseUrl + "../Images/button_print.png' alt='Print MyTopo Map' border='0' /></a>" +
                    "<a href='http://get.it/trimbleoutdoors/8pAD' target='_blank'><img src='" + trimble.scriptBaseUrl + "../Images/button_get.png' id='Get MyTopo App' border='0' /></a>" +
                    "<a href='http://www.mytopo.com/' target='_blank'><img src='" + trimble.scriptBaseUrl + "../Images/SmallMyTopoLogo.png' alt='MyTopo Logo' border='0'/></a><br/>" +
                    "<a href='http://mytopo.com/about/terms.cfm' target='_blank'><b>(MyTopo Terms of Use)</b></a>";

            }
        },
        updateCopyright: function () {
            trimble.myTopo.copyrightDiv.style.display = (trimble.myTopo.map.getMapTypeId() == trimble.myTopo.MapTypeId.Topo) ? "inline" : "none";
        },
        tellDeveloper: function (msg) {
            alert(msg + "\n\nPlease email partner@mytopo.com if you need any assistance getting this setup.");
        },
        copyrightDiv: null
    }
};

{
    trimble.scriptBaseUrl = "http://www.mytopo.com/TileService/Scripts/";
    trimble.myTopo.partnerID = $("#trimble-data").data("partner-id");
    trimble.myTopo.hash = $("#trimble-data").data("hash");
}


// === modal_window.js ===

//This file contains jquery for modal popups
  function showDialog() {
    //Get the dialog tag
    var id = $("#dialog");
     
    //Get the screen height and width
    var maskHeight = $(document).height();
    var maskWidth = $(window).width();
    
    //Set height and width to mask to fill up the whole screen
    $('#mask').css({'width':maskWidth,'height':maskHeight});
         
    //transition effect    
    $('#mask').fadeIn(1000);   
    $('#mask').fadeTo("slow",0.8); 
     
    //Get the window height and width
    var winH = $(window).height();
    var winW = $(window).width();
               
    //Set the popup window to center
    $(id).css('top',  winH/2-$(id).height()/2);
    $(id).css('left', winW/2-$(id).width()/2);
     
    //transition effect
    $(id).fadeIn(2000);
  }

$(document).ready(function() { 

  //if close button is clicked
  $('.window .close').click(function (e) {
    //Cancel the link behavior
    e.preventDefault();
    $('#mask, .window').hide();
  });    
     
  //if mask is clicked
  $('#mask').click(function () {
    $(this).hide();
    $('.window').hide();
  });
});


// === fileuploader.js ===

/**
 * http://github.com/valums/file-uploader
 * 
 * Multiple file upload component with progress-bar, drag-and-drop. 
 * © 2010 Andrew Valums ( andrew(at)valums.com ) 
 * 
 * Licensed under GNU GPL 2 or later, see license.txt.
 */    

//
// Helper functions
//

var qq = qq || {};

/**
 * Adds all missing properties from second obj to first obj
 */ 
qq.extend = function(first, second){
    for (var prop in second){
        first[prop] = second[prop];
    }
};  

/**
 * Searches for a given element in the array, returns -1 if it is not present.
 * @param {Number} [from] The index at which to begin the search
 */
qq.indexOf = function(arr, elt, from){
    if (arr.indexOf) return arr.indexOf(elt, from);
    
    from = from || 0;
    var len = arr.length;    
    
    if (from < 0) from += len;  

    for (; from < len; from++){  
        if (from in arr && arr[from] === elt){  
            return from;
        }
    }  
    return -1;  
}; 
    
qq.getUniqueId = (function(){
    var id = 0;
    return function(){ return id++; };
})();

//
// Events

qq.attach = function(element, type, fn){
    if (element.addEventListener){
        element.addEventListener(type, fn, false);
    } else if (element.attachEvent){
        element.attachEvent('on' + type, fn);
    }
};
qq.detach = function(element, type, fn){
    if (element.removeEventListener){
        element.removeEventListener(type, fn, false);
    } else if (element.attachEvent){
        element.detachEvent('on' + type, fn);
    }
};

qq.preventDefault = function(e){
    if (e.preventDefault){
        e.preventDefault();
    } else{
        e.returnValue = false;
    }
};

//
// Node manipulations

/**
 * Insert node a before node b.
 */
qq.insertBefore = function(a, b){
    b.parentNode.insertBefore(a, b);
};
qq.remove = function(element){
    element.parentNode.removeChild(element);
};

qq.contains = function(parent, descendant){       
    // compareposition returns false in this case
    if (parent == descendant) return true;
    
    if (parent.contains){
        return parent.contains(descendant);
    } else {
        return !!(descendant.compareDocumentPosition(parent) & 8);
    }
};

/**
 * Creates and returns element from html string
 * Uses innerHTML to create an element
 */
qq.toElement = (function(){
    var div = document.createElement('div');
    return function(html){
        div.innerHTML = html;
        var element = div.firstChild;
        div.removeChild(element);
        return element;
    };
})();

//
// Node properties and attributes

/**
 * Sets styles for an element.
 * Fixes opacity in IE6-8.
 */
qq.css = function(element, styles){
    if (styles.opacity != null){
        if (typeof element.style.opacity != 'string' && typeof(element.filters) != 'undefined'){
            styles.filter = 'alpha(opacity=' + Math.round(100 * styles.opacity) + ')';
        }
    }
    qq.extend(element.style, styles);
};
qq.hasClass = function(element, name){
    var re = new RegExp('(^| )' + name + '( |$)');
    return re.test(element.className);
};
qq.addClass = function(element, name){
    if (!qq.hasClass(element, name)){
        element.className += ' ' + name;
    }
};
qq.removeClass = function(element, name){
    var re = new RegExp('(^| )' + name + '( |$)');
    element.className = element.className.replace(re, ' ').replace(/^\s+|\s+$/g, "");
};
qq.setText = function(element, text){
    element.innerText = text;
    element.textContent = text;
};

//
// Selecting elements

qq.children = function(element){
    var children = [],
    child = element.firstChild;

    while (child){
        if (child.nodeType == 1){
            children.push(child);
        }
        child = child.nextSibling;
    }

    return children;
};

qq.getByClass = function(element, className){
    if (element.querySelectorAll){
        return element.querySelectorAll('.' + className);
    }

    var result = [];
    var candidates = element.getElementsByTagName("*");
    var len = candidates.length;

    for (var i = 0; i < len; i++){
        if (qq.hasClass(candidates[i], className)){
            result.push(candidates[i]);
        }
    }
    return result;
};

/**
 * obj2url() takes a json-object as argument and generates
 * a querystring. pretty much like jQuery.param()
 * 
 * how to use:
 *
 *    `qq.obj2url({a:'b',c:'d'},'http://any.url/upload?otherParam=value');`
 *
 * will result in:
 *
 *    `http://any.url/upload?otherParam=value&a=b&c=d`
 *
 * @param  Object JSON-Object
 * @param  String current querystring-part
 * @return String encoded querystring
 */
qq.obj2url = function(obj, temp, prefixDone){
    var uristrings = [],
        prefix = '&',
        add = function(nextObj, i){
            var nextTemp = temp 
                ? (/\[\]$/.test(temp)) // prevent double-encoding
                   ? temp
                   : temp+'['+i+']'
                : i;
            if ((nextTemp != 'undefined') && (i != 'undefined')) {  
                uristrings.push(
                    (typeof nextObj === 'object') 
                        ? qq.obj2url(nextObj, nextTemp, true)
                        : (Object.prototype.toString.call(nextObj) === '[object Function]')
                            ? encodeURIComponent(nextTemp) + '=' + encodeURIComponent(nextObj())
                            : encodeURIComponent(nextTemp) + '=' + encodeURIComponent(nextObj)                                                          
                );
            }
        }; 

    if (!prefixDone && temp) {
      prefix = (/\?/.test(temp)) ? (/\?$/.test(temp)) ? '' : '&' : '?';
      uristrings.push(temp);
      uristrings.push(qq.obj2url(obj));
    } else if ((Object.prototype.toString.call(obj) === '[object Array]') && (typeof obj != 'undefined') ) {
        // we wont use a for-in-loop on an array (performance)
        for (var i = 0, len = obj.length; i < len; ++i){
            add(obj[i], i);
        }
    } else if ((typeof obj != 'undefined') && (obj !== null) && (typeof obj === "object")){
        // for anything else but a scalar, we will use for-in-loop
        for (var i in obj){
            add(obj[i], i);
        }
    } else {
        uristrings.push(encodeURIComponent(temp) + '=' + encodeURIComponent(obj));
    }

    return uristrings.join(prefix)
                     .replace(/^&/, '')
                     .replace(/%20/g, '+'); 
};

//
//
// Uploader Classes
//
//

var qq = qq || {};
    
/**
 * Creates upload button, validates upload, but doesn't create file list or dd. 
 */
qq.FileUploaderBasic = function(o){
    this._options = {
        // set to true to see the server response
        debug: false,
        action: '/server/upload',
        params: {},
        button: null,
        multiple: true,
        maxConnections: 3,
        // validation        
        allowedExtensions: [],               
        sizeLimit: 0,   
        minSizeLimit: 0,                             
        // events
        // return false to cancel submit
        onSubmit: function(id, fileName){},
        onProgress: function(id, fileName, loaded, total){},
        onComplete: function(id, fileName, responseJSON){},
        onCancel: function(id, fileName){},
        // messages                
        messages: {
            typeError: "{file} has invalid extension. Only {extensions} are allowed.",
            sizeError: "{file} is too large, maximum file size is {sizeLimit}.",
            minSizeError: "{file} is too small, minimum file size is {minSizeLimit}.",
            emptyError: "{file} is empty, please select files again without it.",
            onLeave: "The files are being uploaded, if you leave now the upload will be cancelled."            
        },
        showMessage: function(message){
            alert(message);
        }               
    };
    qq.extend(this._options, o);
        
    // number of files being uploaded
    this._filesInProgress = 0;
    this._handler = this._createUploadHandler(); 
    
    if (this._options.button){ 
        this._button = this._createUploadButton(this._options.button);
    }
                        
    this._preventLeaveInProgress();         
};
   
qq.FileUploaderBasic.prototype = {
    setParams: function(params){
        this._options.params = params;
    },
    getInProgress: function(){
        return this._filesInProgress;         
    },
    _createUploadButton: function(element){
        var self = this;
        
        return new qq.UploadButton({
            element: element,
            multiple: this._options.multiple && qq.UploadHandlerXhr.isSupported(),
            onChange: function(input){
                self._onInputChange(input);
            }        
        });           
    },    
    _createUploadHandler: function(){
        var self = this,
            handlerClass;        
        
        if(qq.UploadHandlerXhr.isSupported()){           
            handlerClass = 'UploadHandlerXhr';                        
        } else {
            handlerClass = 'UploadHandlerForm';
        }

        var handler = new qq[handlerClass]({
            debug: this._options.debug,
            action: this._options.action,         
            maxConnections: this._options.maxConnections,   
            onProgress: function(id, fileName, loaded, total){                
                self._onProgress(id, fileName, loaded, total);
                self._options.onProgress(id, fileName, loaded, total);                    
            },            
            onComplete: function(id, fileName, result){
                self._onComplete(id, fileName, result);
                self._options.onComplete(id, fileName, result);
            },
            onCancel: function(id, fileName){
                self._onCancel(id, fileName);
                self._options.onCancel(id, fileName);
            }
        });

        return handler;
    },    
    _preventLeaveInProgress: function(){
        var self = this;
        
        qq.attach(window, 'beforeunload', function(e){
            if (!self._filesInProgress){return;}
            
            var e = e || window.event;
            // for ie, ff
            e.returnValue = self._options.messages.onLeave;
            // for webkit
            return self._options.messages.onLeave;             
        });        
    },    
    _onSubmit: function(id, fileName){
        this._filesInProgress++;  
    },
    _onProgress: function(id, fileName, loaded, total){        
    },
    _onComplete: function(id, fileName, result){
        this._filesInProgress--;                 
        if (result.error){
            this._options.showMessage(result.error);
        }             
    },
    _onCancel: function(id, fileName){
        this._filesInProgress--;        
    },
    _onInputChange: function(input){
        if (this._handler instanceof qq.UploadHandlerXhr){                
            this._uploadFileList(input.files);                   
        } else {             
            if (this._validateFile(input)){                
                this._uploadFile(input);                                    
            }                      
        }               
        this._button.reset();   
    },  
    _uploadFileList: function(files){
        for (var i=0; i<files.length; i++){
            if ( !this._validateFile(files[i])){
                return;
            }            
        }
        
        for (var i=0; i<files.length; i++){
            this._uploadFile(files[i]);        
        }        
    },       
    _uploadFile: function(fileContainer){      
        var id = this._handler.add(fileContainer);
        var fileName = this._handler.getName(id);
        
        if (this._options.onSubmit(id, fileName) !== false){
            this._onSubmit(id, fileName);
            this._handler.upload(id, this._options.params);
        }
    },      
    _validateFile: function(file){
        var name, size;
        
        if (file.value){
            // it is a file input            
            // get input value and remove path to normalize
            name = file.value.replace(/.*(\/|\\)/, "");
        } else {
            // fix missing properties in Safari
            name = file.fileName != null ? file.fileName : file.name;
            size = file.fileSize != null ? file.fileSize : file.size;
        }
                    
        if (! this._isAllowedExtension(name)){            
            this._error('typeError', name);
            return false;
            
        } else if (size === 0){            
            this._error('emptyError', name);
            return false;
                                                     
        } else if (size && this._options.sizeLimit && size > this._options.sizeLimit){            
            this._error('sizeError', name);
            return false;
                        
        } else if (size && size < this._options.minSizeLimit){
            this._error('minSizeError', name);
            return false;            
        }
        
        return true;                
    },
    _error: function(code, fileName){
        var message = this._options.messages[code];        
        function q(name, replacement){ message = message.replace(name, replacement); }
        
        q('{file}', this._formatFileName(fileName));        
        q('{extensions}', this._options.allowedExtensions.join(', '));
        q('{sizeLimit}', this._formatSize(this._options.sizeLimit));
        q('{minSizeLimit}', this._formatSize(this._options.minSizeLimit));
        
        this._options.showMessage(message);                
    },
    _formatFileName: function(name){
        if (name.length > 33){
            name = name.slice(0, 19) + '...' + name.slice(-13);    
        }
        return name;
    },
    _isAllowedExtension: function(fileName){
        var ext = (-1 !== fileName.indexOf('.')) ? fileName.replace(/.*[.]/, '').toLowerCase() : '';
        var allowed = this._options.allowedExtensions;
        
        if (!allowed.length){return true;}        
        
        for (var i=0; i<allowed.length; i++){
            if (allowed[i].toLowerCase() == ext){ return true;}    
        }
        
        return false;
    },    
    _formatSize: function(bytes){
        var i = -1;                                    
        do {
            bytes = bytes / 1024;
            i++;  
        } while (bytes > 99);
        
        return Math.max(bytes, 0.1).toFixed(1) + ['kB', 'MB', 'GB', 'TB', 'PB', 'EB'][i];          
    }
};
    
       
/**
 * Class that creates upload widget with drag-and-drop and file list
 * @inherits qq.FileUploaderBasic
 */
qq.FileUploader = function(o){
    // call parent constructor
    qq.FileUploaderBasic.apply(this, arguments);
    
    // additional options    
    qq.extend(this._options, {
        element: null,
        // if set, will be used instead of qq-upload-list in template
        listElement: null,
                
        template: '<div class="qq-uploader">' + 
                '<div class="qq-upload-drop-area"><span>Drop files here to upload</span></div>' +
                '<div class="qq-upload-button">Upload photos</div>' +
                '<ul class="qq-upload-list"></ul>' + 
             '</div>',

        // template for one item in file list
        fileTemplate: '<li>' +
                '<span class="qq-upload-file"></span>' +
                '<span class="qq-upload-spinner"></span>' +
                '<span class="qq-upload-size"></span>' +
                '<a class="qq-upload-cancel" href="#">Cancel</a>' +
                '<span class="qq-upload-failed-text">Failed</span>' +
            '</li>',        
        
        classes: {
            // used to get elements from templates
            button: 'qq-upload-button',
            drop: 'qq-upload-drop-area',
            dropActive: 'qq-upload-drop-area-active',
            list: 'qq-upload-list',
                        
            file: 'qq-upload-file',
            spinner: 'qq-upload-spinner',
            size: 'qq-upload-size',
            cancel: 'qq-upload-cancel',

            // added to list item when upload completes
            // used in css to hide progress spinner
            success: 'qq-upload-success',
            fail: 'qq-upload-fail'
        }
    });
    // overwrite options with user supplied    
    qq.extend(this._options, o);       

    this._element = this._options.element;
    this._element.innerHTML = this._options.template;        
    this._listElement = this._options.listElement || this._find(this._element, 'list');
    
    this._classes = this._options.classes;
        
    this._button = this._createUploadButton(this._find(this._element, 'button'));        
    
    this._bindCancelEvent();
    this._setupDragDrop();
};

// inherit from Basic Uploader
qq.extend(qq.FileUploader.prototype, qq.FileUploaderBasic.prototype);

qq.extend(qq.FileUploader.prototype, {
    /**
     * Gets one of the elements listed in this._options.classes
     **/
    _find: function(parent, type){                                
        var element = qq.getByClass(parent, this._options.classes[type])[0];        
        if (!element){
            throw new Error('element not found ' + type);
        }
        
        return element;
    },
    _setupDragDrop: function(){
        var self = this,
            dropArea = this._find(this._element, 'drop');                        

        var dz = new qq.UploadDropZone({
            element: dropArea,
            onEnter: function(e){
                qq.addClass(dropArea, self._classes.dropActive);
                e.stopPropagation();
            },
            onLeave: function(e){
                e.stopPropagation();
            },
            onLeaveNotDescendants: function(e){
                qq.removeClass(dropArea, self._classes.dropActive);  
            },
            onDrop: function(e){
                dropArea.style.display = 'none';
                qq.removeClass(dropArea, self._classes.dropActive);
                self._uploadFileList(e.dataTransfer.files);    
            }
        });
                
        dropArea.style.display = 'none';

        qq.attach(document, 'dragenter', function(e){     
            if (!dz._isValidFileDrag(e)) return; 
            
            dropArea.style.display = 'block';            
        });                 
        qq.attach(document, 'dragleave', function(e){
            if (!dz._isValidFileDrag(e)) return;            
            
            var relatedTarget = document.elementFromPoint(e.clientX, e.clientY);
            // only fire when leaving document out
            if ( ! relatedTarget || relatedTarget.nodeName == "HTML"){               
                dropArea.style.display = 'none';                                            
            }
        });                
    },
    _onSubmit: function(id, fileName){
        qq.FileUploaderBasic.prototype._onSubmit.apply(this, arguments);
        this._addToList(id, fileName);  
    },
    _onProgress: function(id, fileName, loaded, total){
        qq.FileUploaderBasic.prototype._onProgress.apply(this, arguments);

        var item = this._getItemByFileId(id);
        var size = this._find(item, 'size');
        size.style.display = 'inline';
        
        var text; 
        if (loaded != total){
            text = Math.round(loaded / total * 100) + '% from ' + this._formatSize(total);
        } else {                                   
            text = this._formatSize(total);
        }          
        
        qq.setText(size, text);         
    },
    _onComplete: function(id, fileName, result){
        qq.FileUploaderBasic.prototype._onComplete.apply(this, arguments);

        // mark completed
        var item = this._getItemByFileId(id);                
        qq.remove(this._find(item, 'cancel'));
        qq.remove(this._find(item, 'spinner'));
        
        if (result.success){
            qq.addClass(item, this._classes.success);    
        } else {
            qq.addClass(item, this._classes.fail);
        }         
    },
    _addToList: function(id, fileName){
        var item = qq.toElement(this._options.fileTemplate);                
        item.qqFileId = id;

        var fileElement = this._find(item, 'file');        
        qq.setText(fileElement, this._formatFileName(fileName));
        this._find(item, 'size').style.display = 'none';        

        this._listElement.appendChild(item);
    },
    _getItemByFileId: function(id){
        var item = this._listElement.firstChild;        
        
        // there can't be txt nodes in dynamically created list
        // and we can  use nextSibling
        while (item){            
            if (item.qqFileId == id) return item;            
            item = item.nextSibling;
        }          
    },
    /**
     * delegate click event for cancel link 
     **/
    _bindCancelEvent: function(){
        var self = this,
            list = this._listElement;            
        
        qq.attach(list, 'click', function(e){            
            e = e || window.event;
            var target = e.target || e.srcElement;
            
            if (qq.hasClass(target, self._classes.cancel)){                
                qq.preventDefault(e);
               
                var item = target.parentNode;
                self._handler.cancel(item.qqFileId);
                qq.remove(item);
            }
        });
    }    
});
    
qq.UploadDropZone = function(o){
    this._options = {
        element: null,  
        onEnter: function(e){},
        onLeave: function(e){},  
        // is not fired when leaving element by hovering descendants   
        onLeaveNotDescendants: function(e){},   
        onDrop: function(e){}                       
    };
    qq.extend(this._options, o); 
    
    this._element = this._options.element;
    
    this._disableDropOutside();
    this._attachEvents();   
};

qq.UploadDropZone.prototype = {
    _disableDropOutside: function(e){
        // run only once for all instances
        if (!qq.UploadDropZone.dropOutsideDisabled ){

            qq.attach(document, 'dragover', function(e){
                if (e.dataTransfer){
                    e.dataTransfer.dropEffect = 'none';
                    e.preventDefault(); 
                }           
            });
            
            qq.UploadDropZone.dropOutsideDisabled = true; 
        }        
    },
    _attachEvents: function(){
        var self = this;              
                  
        qq.attach(self._element, 'dragover', function(e){
            if (!self._isValidFileDrag(e)) return;
            
            var effect = e.dataTransfer.effectAllowed;
            if (effect == 'move' || effect == 'linkMove'){
                e.dataTransfer.dropEffect = 'move'; // for FF (only move allowed)    
            } else {                    
                e.dataTransfer.dropEffect = 'copy'; // for Chrome
            }
                                                     
            e.stopPropagation();
            e.preventDefault();                                                                    
        });
        
        qq.attach(self._element, 'dragenter', function(e){
            if (!self._isValidFileDrag(e)) return;
                        
            self._options.onEnter(e);
        });
        
        qq.attach(self._element, 'dragleave', function(e){
            if (!self._isValidFileDrag(e)) return;
            
            self._options.onLeave(e);
            
            var relatedTarget = document.elementFromPoint(e.clientX, e.clientY);                      
            // do not fire when moving a mouse over a descendant
            if (qq.contains(this, relatedTarget)) return;
                        
            self._options.onLeaveNotDescendants(e); 
        });
                
        qq.attach(self._element, 'drop', function(e){
            if (!self._isValidFileDrag(e)) return;
            
            e.preventDefault();
            self._options.onDrop(e);
        });          
    },
    _isValidFileDrag: function(e){
        var dt = e.dataTransfer,
            // do not check dt.types.contains in webkit, because it crashes safari 4            
            isWebkit = navigator.userAgent.indexOf("AppleWebKit") > -1;                        

        // dt.effectAllowed is none in Safari 5
        // dt.types.contains check is for firefox            
        return dt && dt.effectAllowed != 'none' && 
            (dt.files || (!isWebkit && dt.types.contains && dt.types.contains('Files')));
        
    }        
}; 

qq.UploadButton = function(o){
    this._options = {
        element: null,  
        // if set to true adds multiple attribute to file input      
        multiple: false,
        // name attribute of file input
        name: 'file',
        onChange: function(input){},
        hoverClass: 'qq-upload-button-hover',
        focusClass: 'qq-upload-button-focus'                       
    };
    
    qq.extend(this._options, o);
        
    this._element = this._options.element;
    
    // make button suitable container for input
    qq.css(this._element, {
        position: 'relative',
        overflow: 'hidden',
        // Make sure browse button is in the right side
        // in Internet Explorer
        direction: 'ltr'
    });   
    
    this._input = this._createInput();
};

qq.UploadButton.prototype = {
    /* returns file input element */    
    getInput: function(){
        return this._input;
    },
    /* cleans/recreates the file input */
    reset: function(){
        if (this._input.parentNode){
            qq.remove(this._input);    
        }                
        
        qq.removeClass(this._element, this._options.focusClass);
        this._input = this._createInput();
    },    
    _createInput: function(){                
        var input = document.createElement("input");
        
        if (this._options.multiple){
            input.setAttribute("multiple", "multiple");
        }
                
        input.setAttribute("type", "file");
        input.setAttribute("name", this._options.name);
        
        qq.css(input, {
            position: 'absolute',
            // in Opera only 'browse' button
            // is clickable and it is located at
            // the right side of the input
            right: 0,
            top: 0,
            fontFamily: 'Arial',
            // 4 persons reported this, the max values that worked for them were 243, 236, 236, 118
            fontSize: '118px',
            margin: 0,
            padding: 0,
            cursor: 'pointer',
            opacity: 0
        });
        
        this._element.appendChild(input);

        var self = this;
        qq.attach(input, 'change', function(){
            self._options.onChange(input);
        });
                
        qq.attach(input, 'mouseover', function(){
            qq.addClass(self._element, self._options.hoverClass);
        });
        qq.attach(input, 'mouseout', function(){
            qq.removeClass(self._element, self._options.hoverClass);
        });
        qq.attach(input, 'focus', function(){
            qq.addClass(self._element, self._options.focusClass);
        });
        qq.attach(input, 'blur', function(){
            qq.removeClass(self._element, self._options.focusClass);
        });

        // IE and Opera, unfortunately have 2 tab stops on file input
        // which is unacceptable in our case, disable keyboard access
        if (window.attachEvent){
            // it is IE or Opera
            input.setAttribute('tabIndex', "-1");
        }

        return input;            
    }        
};

/**
 * Class for uploading files, uploading itself is handled by child classes
 */
qq.UploadHandlerAbstract = function(o){
    this._options = {
        debug: false,
        action: '/upload.php',
        // maximum number of concurrent uploads        
        maxConnections: 999,
        onProgress: function(id, fileName, loaded, total){},
        onComplete: function(id, fileName, response){},
        onCancel: function(id, fileName){}
    };
    qq.extend(this._options, o);    
    
    this._queue = [];
    // params for files in queue
    this._params = [];
};
qq.UploadHandlerAbstract.prototype = {
    log: function(str){
        if (this._options.debug && window.console) console.log('[uploader] ' + str);        
    },
    /**
     * Adds file or file input to the queue
     * @returns id
     **/    
    add: function(file){},
    /**
     * Sends the file identified by id and additional query params to the server
     */
    upload: function(id, params){
        var len = this._queue.push(id);

        var copy = {};        
        qq.extend(copy, params);
        this._params[id] = copy;        
                
        // if too many active uploads, wait...
        if (len <= this._options.maxConnections){               
            this._upload(id, this._params[id]);
        }
    },
    /**
     * Cancels file upload by id
     */
    cancel: function(id){
        this._cancel(id);
        this._dequeue(id);
    },
    /**
     * Cancells all uploads
     */
    cancelAll: function(){
        for (var i=0; i<this._queue.length; i++){
            this._cancel(this._queue[i]);
        }
        this._queue = [];
    },
    /**
     * Returns name of the file identified by id
     */
    getName: function(id){},
    /**
     * Returns size of the file identified by id
     */          
    getSize: function(id){},
    /**
     * Returns id of files being uploaded or
     * waiting for their turn
     */
    getQueue: function(){
        return this._queue;
    },
    /**
     * Actual upload method
     */
    _upload: function(id){},
    /**
     * Actual cancel method
     */
    _cancel: function(id){},     
    /**
     * Removes element from queue, starts upload of next
     */
    _dequeue: function(id){
        var i = qq.indexOf(this._queue, id);
        this._queue.splice(i, 1);
                
        var max = this._options.maxConnections;
        
        if (this._queue.length >= max){
            var nextId = this._queue[max-1];
            this._upload(nextId, this._params[nextId]);
        }
    }        
};

/**
 * Class for uploading files using form and iframe
 * @inherits qq.UploadHandlerAbstract
 */
qq.UploadHandlerForm = function(o){
    qq.UploadHandlerAbstract.apply(this, arguments);
       
    this._inputs = {};
};
// @inherits qq.UploadHandlerAbstract
qq.extend(qq.UploadHandlerForm.prototype, qq.UploadHandlerAbstract.prototype);

qq.extend(qq.UploadHandlerForm.prototype, {
    add: function(fileInput){
        fileInput.setAttribute('name', 'qqfile');
        var id = 'qq-upload-handler-iframe' + qq.getUniqueId();       
        
        this._inputs[id] = fileInput;
        
        // remove file input from DOM
        if (fileInput.parentNode){
            qq.remove(fileInput);
        }
                
        return id;
    },
    getName: function(id){
        // get input value and remove path to normalize
        return this._inputs[id].value.replace(/.*(\/|\\)/, "");
    },    
    _cancel: function(id){
        this._options.onCancel(id, this.getName(id));
        
        delete this._inputs[id];        

        var iframe = document.getElementById(id);
        if (iframe){
            // to cancel request set src to something else
            // we use src="javascript:false;" because it doesn't
            // trigger ie6 prompt on https
            iframe.setAttribute('src', 'javascript:false;');

            qq.remove(iframe);
        }
    },     
    _upload: function(id, params){                        
        var input = this._inputs[id];
        
        if (!input){
            throw new Error('file with passed id was not added, or already uploaded or cancelled');
        }                

        var fileName = this.getName(id);
                
        var iframe = this._createIframe(id);
        var form = this._createForm(iframe, params);
        form.appendChild(input);

        var self = this;
        this._attachLoadEvent(iframe, function(){                                 
            self.log('iframe loaded');
            
            var response = self._getIframeContentJSON(iframe);

            self._options.onComplete(id, fileName, response);
            self._dequeue(id);
            
            delete self._inputs[id];
            // timeout added to fix busy state in FF3.6
            setTimeout(function(){
                qq.remove(iframe);
            }, 1);
        });

        form.submit();        
        qq.remove(form);        
        
        return id;
    }, 
    _attachLoadEvent: function(iframe, callback){
        qq.attach(iframe, 'load', function(){
            // when we remove iframe from dom
            // the request stops, but in IE load
            // event fires
            if (!iframe.parentNode){
                return;
            }
	    try{
              // fixing Opera 10.53
              if (iframe.contentDocument &&
                  iframe.contentDocument.body &&
                  iframe.contentDocument.body.innerHTML == "false"){
                  // In Opera event is fired second time
                  // when body.innerHTML changed from false
                  // to server response approx. after 1 sec
                  // when we upload file with iframe
                  return;
	       }
            } catch(err){;}

            callback();
        });
    },
    /**
     * Returns json object received by iframe from server.
     */
    _getIframeContentJSON: function(iframe){
        // iframe.contentWindow.document - for IE<7
	var doc = '';
        doc = iframe.contentDocument ? iframe.contentDocument: iframe.contentWindow.document;
        
        this.log("converting iframe's innerHTML to JSON");
        this.log("innerHTML = " + doc.body.innerHTML);
                        
        try {
            response = eval("(" + doc.body.innerHTML + ")");
        } catch(err){
            response = {};
        }        

        return response;
    },
    /**
     * Creates iframe with unique name
     */
    _createIframe: function(id){
        // We can't use following code as the name attribute
        // won't be properly registered in IE6, and new window
        // on form submit will open
        // var iframe = document.createElement('iframe');
        // iframe.setAttribute('name', id);

        var iframe = qq.toElement('<iframe src="javascript:false;" name="' + id + '" />');
        // src="javascript:false;" removes ie6 prompt on https

        iframe.setAttribute('id', id);

        iframe.style.display = 'none';
        document.body.appendChild(iframe);

        return iframe;
    },
    /**
     * Creates form, that will be submitted to iframe
     */
    _createForm: function(iframe, params){
        // We can't use the following code in IE6
        // var form = document.createElement('form');
        // form.setAttribute('method', 'post');
        // form.setAttribute('enctype', 'multipart/form-data');
        // Because in this case file won't be attached to request
        var form = qq.toElement('<form method="post" enctype="multipart/form-data"></form>');

        var queryString = qq.obj2url(params, this._options.action);

        form.setAttribute('action', queryString);
        form.setAttribute('target', iframe.name);
        form.style.display = 'none';
        document.body.appendChild(form);

        return form;
    }
});

/**
 * Class for uploading files using xhr
 * @inherits qq.UploadHandlerAbstract
 */
qq.UploadHandlerXhr = function(o){
    qq.UploadHandlerAbstract.apply(this, arguments);

    this._files = [];
    this._xhrs = [];
    
    // current loaded size in bytes for each file 
    this._loaded = [];
};

// static method
qq.UploadHandlerXhr.isSupported = function(){
    var input = document.createElement('input');
    input.type = 'file';        
    
    return (
        'multiple' in input &&
        typeof File != "undefined" &&
        typeof (new XMLHttpRequest()).upload != "undefined" );       
};

// @inherits qq.UploadHandlerAbstract
qq.extend(qq.UploadHandlerXhr.prototype, qq.UploadHandlerAbstract.prototype)

qq.extend(qq.UploadHandlerXhr.prototype, {
    /**
     * Adds file to the queue
     * Returns id to use with upload, cancel
     **/    
    add: function(file){
        if (!(file instanceof File)){
            throw new Error('Passed obj in not a File (in qq.UploadHandlerXhr)');
        }
                
        return this._files.push(file) - 1;        
    },
    getName: function(id){        
        var file = this._files[id];
        // fix missing name in Safari 4
        return file.fileName != null ? file.fileName : file.name;       
    },
    getSize: function(id){
        var file = this._files[id];
        return file.fileSize != null ? file.fileSize : file.size;
    },    
    /**
     * Returns uploaded bytes for file identified by id 
     */    
    getLoaded: function(id){
        return this._loaded[id] || 0; 
    },
    /**
     * Sends the file identified by id and additional query params to the server
     * @param {Object} params name-value string pairs
     */    
    _upload: function(id, params){
        var file = this._files[id],
            name = this.getName(id),
            size = this.getSize(id);
                
        this._loaded[id] = 0;
                                
        var xhr = this._xhrs[id] = new XMLHttpRequest();
        var self = this;
                                        
        xhr.upload.onprogress = function(e){
            if (e.lengthComputable){
                self._loaded[id] = e.loaded;
                self._options.onProgress(id, name, e.loaded, e.total);
            }
        };

        xhr.onreadystatechange = function(){            
            if (xhr.readyState == 4){
                self._onComplete(id, xhr);                    
            }
        };

        // build query string
        params = params || {};
        params['qqfile'] = name;
        var queryString = qq.obj2url(params, this._options.action);

        xhr.open("POST", queryString, true);
        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        xhr.setRequestHeader("X-File-Name", encodeURIComponent(name));
        xhr.setRequestHeader("Content-Type", "application/octet-stream");
        xhr.send(file);
    },
    _onComplete: function(id, xhr){
        // the request was aborted/cancelled
        if (!this._files[id]) return;
        
        var name = this.getName(id);
        var size = this.getSize(id);
        
        this._options.onProgress(id, name, size, size);
                
        if (xhr.status == 200){
            this.log("xhr - server response received");
            this.log("responseText = " + xhr.responseText);
                        
            var response;
                    
            try {
                response = eval("(" + xhr.responseText + ")");
            } catch(err){
                response = {};
            }
            
            this._options.onComplete(id, name, response);
                        
        } else {                   
            this._options.onComplete(id, name, {});
        }
                
        this._files[id] = null;
        this._xhrs[id] = null;    
        this._dequeue(id);                    
    },
    _cancel: function(id){
        this._options.onCancel(id, this.getName(id));
        
        this._files[id] = null;
        
        if (this._xhrs[id]){
            this._xhrs[id].abort();
            this._xhrs[id] = null;                                   
        }
    }
});


// === facebook.js ===

// Facebook SDK integration with Turbo Drive compatibility
let fbRoot = null;
let fbEventsBound = false;

window.saveFacebookRoot = function() {
  const root = $('#fb-root');
  if (root.length > 0) {
    fbRoot = root.detach();
  }
};

window.restoreFacebookRoot = function() {
  if ($('#fb-root').length > 0) {
    if (fbRoot) $('#fb-root').replaceWith(fbRoot);
  } else if (fbRoot) {
    $('body').append(fbRoot);
  }
};

window.initializeFacebookSDK = function() {
  if (typeof FB === "undefined") return;

  FB.init({
    appId: typeof facebookAppId !== "undefined" ? facebookAppId : null,
    channelUrl: typeof facebookChannelUrl !== "undefined" ? facebookChannelUrl : null,
    status: false,
    cookie: true,
    xfbml: true
  });

  FB.Event.subscribe('edge.create', function(response) {
    if (typeof socialUpdate === 'function') {
      socialUpdate('true', '');
    }
  });

  FB.Event.subscribe('edge.remove', function(response) {
    if (typeof socialUpdate === 'function') {
      socialUpdate('false', '');
    }
  });
};

window.loadFacebookSDK = function() {
  window.fbAsyncInit = window.initializeFacebookSDK;
  if ($('.fb-like, #fb-root').length > 0) {
    $.getScript('//connect.facebook.net/en_US/all.js#xfbml=1');
  }
};

window.bindFacebookEvents = function() {
  $(document)
    .on('turbo:before-render', window.saveFacebookRoot)
    .on('turbo:render', window.restoreFacebookRoot)
    .on('turbo:load ready', function() {
      if (typeof FB !== "undefined" && FB.XFBML) {
        FB.XFBML.parse();
      }
    });
  fbEventsBound = true;
};

$(function() {
  window.loadFacebookSDK();
  if (!fbEventsBound) {
    window.bindFacebookEvents();
  }
});


// === twitter.js ===

// Twitter widgets integration with Turbo Drive compatibility
let twttrEventsBound = false;

window.renderTweetButtons = function() {
  $('.twitter-share-button').each(function() {
    const button = $(this);
    if (!button.data('url')) {
      button.attr('data-url', document.location.href);
    }
    if (!button.data('text')) {
      button.attr('data-text', document.title);
    }
  });

  if (typeof twttr !== "undefined" && twttr.widgets) {
    twttr.widgets.load();
  }
};

window.loadTwitterSDK = function() {
  if ($('.twitter-share-button').length > 0) {
    $.getScript('//platform.twitter.com/widgets.js');
  }
};

window.bindTwitterEventHandlers = function() {
  $(document).on('turbo:load ready', window.renderTweetButtons);
  twttrEventsBound = true;
};

$(function() {
  window.loadTwitterSDK();
  if (!twttrEventsBound) {
    window.bindTwitterEventHandlers();
  }
});


// === share.js ===

// Google Analytics Code
if (typeof doNotTrack === "undefined" || !doNotTrack) {
  window._gaq = window._gaq || [];
  window._gaq.push(['_setAccount', 'UA-26814612-1']);
  window._gaq.push(['_trackPageview']);

  (function() {
    const ga = document.createElement("script");
    ga.type = "text/javascript";
    ga.async = true;
    ga.src = (document.location.protocol === "https:" ? "https://" : "http://") + "stats.g.doubleclick.net/dc.js";
    const s = document.getElementsByTagName("script")[0];
    if (s && s.parentNode) {
      s.parentNode.insertBefore(ga, s);
    }
  })();
}

const isTouchDevice = () => ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || (window.Modernizr && window.Modernizr.touch);

// Converts the string coord to decimal if in deg:min:sec or deg:min else returns string as is
window.convertToDecimal = function(coord) {
  if (!coord || typeof coord !== "string") return coord;
  coord = coord.trim();
  const colonIndex = coord.indexOf(":");
  if (colonIndex === -1) return coord;

  let dec = parseInt(coord.substring(0, colonIndex), 10);
  const sign = dec >= 0 ? 1 : -1;

  // If deg:min:sec (e.g. 51:12:30 or -115:30:15)
  if (/^-?\d{1,3}:\d{1,2}:\d{1,2}$/.test(coord)) {
    const lastColon = coord.lastIndexOf(":");
    const min = parseFloat(coord.substring(colonIndex + 1, lastColon));
    const sec = parseFloat(coord.substring(lastColon + 1));
    dec += sign * (min / 60.0 + sec / 3600.0);
    return dec;
  }
  // If deg:min (e.g. 51:12.5)
  else if (/^-?\d{1,3}:\d{1,2}(\.\d*)?$/.test(coord)) {
    const min = parseFloat(coord.substring(colonIndex + 1));
    dec += sign * (min / 60.0);
    return dec;
  }
  return coord;
};

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

let photo_load_called = false;

function loadPhotosIfOnScreen(getpath) {
  if (photo_load_called) return;
  const target = $('#photos_go_here');
  if (!target.length) return;

  const hT = target.offset().top;
  const wH = $(window).height();
  const wS = $(window).scrollTop();

  if (wS + wH < hT - 300) return;

  photo_load_called = true;
  const object_id = target.data('object_id');
  target.html('<p style="font-size:larger"><span class="ajax-loader"></span> Loading photos</p>');
  const resolvedPath = getpath.replace("{{id}}", object_id);

  $.get(resolvedPath, function(data) {
    $("#photos_go_here").replaceWith(data);
    if ($.fn.button) {
      $("input:submit, input:button, button, .linkButton").button();
    }
  });
}

// Called on load in the show page for something that has photos
window.setupPhotoLoad = function(getpath) {
  photo_load_called = false;
  loadPhotosIfOnScreen(getpath);

  $(window).off('scroll.photoLoad resize.photoLoad').on('scroll.photoLoad resize.photoLoad', function() {
    loadPhotosIfOnScreen(getpath);
  });
};

// jQuery insertAtCaret plugin
if (window.jQuery) {
  jQuery.fn.extend({
    insertAtCaret: function(myValue) {
      return this.each(function() {
        if (document.selection) {
          this.focus();
          const sel = document.selection.createRange();
          sel.text = myValue;
          this.focus();
        } else if (this.selectionStart || this.selectionStart === 0 || this.selectionStart === '0') {
          const startPos = this.selectionStart;
          const endPos = this.selectionEnd;
          const scrollTop = this.scrollTop;
          this.value = this.value.substring(0, startPos) + myValue + this.value.substring(endPos, this.value.length);
          this.focus();
          this.selectionStart = startPos + myValue.length;
          this.selectionEnd = startPos + myValue.length;
          this.scrollTop = scrollTop;
        } else {
          this.value += myValue;
          this.focus();
        }
      });
    }
  });
}

function initSharedUI() {
  const isTouch = isTouchDevice();

  if (!isTouch) {
    $("#banner").on("click", function(event) {
      if ($(event.target).is("#banner") || $(event.target).is("#BannerLogo")) {
        $("html").css({ cursor: "wait" });
        const href = $("#BannerLink").prop("href");
        if (href) {
          if (window.Turbo) window.Turbo.visit(href);
          else window.location.href = href;
        }
      }
    });
  } else {
    $(".clickable, #menu li > a").on("click", function(e) {
      const firstclick = $(this).hasClass("firstClick");
      $(".clickable, #menu li > a").removeClass("firstClick");
      if (!firstclick) {
        $(this).addClass("firstClick");
        e.preventDefault();
        return false;
      }
    });

    $("#banner").on("click", function() {
      $("#menu").css("left", "0px");
    });
  }

  // Dialogs
  if ($.fn.dialog) {
    if ($("#dlgSignin").length) {
      $("#dlgSignin").dialog({ autoOpen: false, modal: true, width: 350 });
      $(".signin").on("click", function(e) {
        $("#dlgSignin").dialog("open");
        e.preventDefault();
        return false;
      });
    }

    if ($("#dlgSignup").length) {
      $("#dlgSignup").dialog({ autoOpen: false, modal: true, width: 350 });
      $(".signup").on("click", function(e) {
        $("#dlgSignup").dialog("open");
        e.preventDefault();
        return false;
      });
    }
  }

  // Captions on hover / touch
  if (!isTouch) {
    $(document).on('mouseenter', '.entry, .thumbDiv', function() {
      $(this).children('.captionDiv, .abstractDiv').show();
    });
    $(document).on('mouseleave', '.entry, .thumbDiv', function() {
      $(this).children('.captionDiv, .abstractDiv').hide();
    });
  } else {
    $(document).on('click', '.entry, .thumbDiv', function() {
      $(".entry, .thumbDiv").children('.captionDiv, .abstractDiv').hide();
      $(this).children('.captionDiv, .abstractDiv').show();
    });
  }

  // Tooltip
  if ($.fn.tooltip) {
    $(document).tooltip({
      items: ".showHover",
      show: false,
      hide: false,
      close: false,
      position: {
        my: "center top",
        at: "center bottom"
      },
      classes: {
        "ui-tooltip": "ui-tooltip"
      },
      content: function() {
        const element = $(this);
        if (element.is(".showHover")) {
          return element.children(".hover:first").html();
        }
        return "";
      }
    });
  }

  // Clickable items
  $(document).on('click', '.clickable', function(event) {
    if ($(event.target).is("a") || $(event.target).parent().is("a")) {
      return true;
    }
    if (!isTouch || $(this).hasClass("firstClick")) {
      const link = $(this).find("a:first")[0];
      if (link && link.href) {
        if (window.Turbo) window.Turbo.visit(link.href);
        else window.location.href = link.href;
      }
    }
  });

  // Notice timeout
  setTimeout(function() {
    $("#notice").slideUp('slow');
  }, 10000);

  // jQuery UI buttons
  if ($.fn.button) {
    $("input:submit, input:button, button, .linkButton").button();
  }

  $(document).on('nested:fieldAdded', function(event) {
    if (event.field && $.fn.button) {
      event.field.find("input:submit, input:button, button, .linkButton").button();
    }
  });

  // Toggle buttons
  $('.toggleButton').each(function() {
    const toggleText = $(this).prevAll().find('.place_description');
    if (toggleText.length === 0 || (toggleText.prop("scrollHeight") <= toggleText.prop("offsetHeight"))) {
      $(this).hide();
    } else if ($.fn.button) {
      $(this).button();
    }
  });

  $(document).on("click", '.toggleButton', function(e) {
    e.stopPropagation();
    const toggleText = $(this).prevAll().find('.place_description');
    const buttonText = $(this).text();
    if (buttonText.indexOf("Read more") === 0) {
      const h = toggleText.prop("scrollHeight");
      toggleText.animate({ maxHeight: h });
      $(this).text("Read less" + buttonText.substring(9));
    } else {
      toggleText.animate({ maxHeight: '600px' });
      $(this).text("Read more" + buttonText.substring(9));
    }
  });

  // Block enter
  $(document).on("keypress", '.noenter', function(e) {
    if (e.keyCode === 13 || e.which === 13) {
      e.preventDefault();
      return false;
    }
  });

  // MarkItUp editor
  if (typeof mySettings !== "undefined" && $.fn.markItUp) {
    mySettings.previewParserPath = "/markitup/preview";
    mySettings.onEnter = {
      keepDefault: false,
      replaceWith: "<br />\n"
    };
    $(".editor").markItUp(mySettings);
  }
}

window.onAppReady(function() {
  initSharedUI();
});


// === default.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

// Autocomplete search handling
window.onAppReady(function() {
  if ($('body.default').length && $('#search').length && $.fn.autocomplete) {
    $('#search').autocomplete({
      minLength: 4,
      position: {
        my: "right top",
        at: "right bottom"
      },
      source: function(request, response) {
        $.ajax({
          url: "/search.json",
          dataType: "json",
          data: {
            search: request.term,
            open_best_result: "off"
          },
          async: true,
          success: function(data) {
            response(data);
          },
          error: function() {}
        });
      },
      select: function(event, ui) {
        $("*").css({ cursor: "wait" });
        let targetUrl = null;
        if (ui.item.album) {
          targetUrl = `/albums/${ui.item.id}`;
        } else if (ui.item.place) {
          targetUrl = `/places/${ui.item.id}`;
        } else if (ui.item.photo) {
          targetUrl = `/photos/${ui.item.id}`;
        } else if (ui.item.route) {
          targetUrl = `/routes/${ui.item.id}`;
        } else if (ui.item.trip_report) {
          targetUrl = `/trip_reports/${ui.item.id}`;
        } else if (ui.item.user) {
          targetUrl = `/users/${ui.item.id}`;
        }

        if (targetUrl) {
          if (window.Turbo) {
            window.Turbo.visit(targetUrl);
          } else {
            window.location.href = targetUrl;
          }
        }
      }
    });
  }
});


// === nomenu.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.nomenu').length) {
    // Make banner clickable to return to home
    $("#short_banner").on("click", function() {
      const href = $(this).children("a").prop("href");
      if (href) {
        if (window.Turbo) {
          window.Turbo.visit(href);
        } else {
          window.location.href = href;
        }
      }
    });

    // Prevent double click submits
    $(document).on("submit", "form", function() {
      $("input:submit, BUTTON").prop("disabled", true);
      return true;
    });

    // Block pressing enter when we don't want it to submit a form
    $(document).on("keypress", ".noenter", function(e) {
      if (e.keyCode === 13 || e.which === 13) {
        e.preventDefault();
        return false;
      }
    });

    $(document).on("nested:fieldAdded", function(e) {
      if (e.field && $.fn.TextAreaExpander) {
        e.field.find("textarea.expand").TextAreaExpander();
      }
    });
  }
});


// === forem.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.forem').length && !$('body.ie7').length && $.fn.jMenu) {
    $("#jMenu").jMenu({
      ulWidth: 150,
      TimeBeforeOpening: 100,
      TimeBeforeClosing: 400,
      absoluteTop: 24,
      absoluteLeft: -20
    });
  }
});


// === waypoint.js ===

var Waypoint = window.Waypoint = class Waypoint {
  constructor(id, parent_index, title, latitude, longitude, height, distance, height_gain, height_loss, description, icon, icon_src, window_content) {
    this.id = id;
    this.parent_index = parent_index;
    this.title = title;
    this.latitude = latitude;
    this.longitude = longitude;
    this.height = height;
    this.distance = distance;
    this.height_gain = height_gain;
    this.height_loss = height_loss;
    this.description = description;
    this.icon = icon;
    this.icon_src = icon_src;
    this.window_content = window_content;

    this._destroy = false;
    this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
    this.marker = new google.maps.Marker({
      position: this.latLon,
      map: window.map,
      title: "A waypoint",
      draggable: true,
      icon: "/assets/markers/yellow-dot.png"
    });
    this.infowindow = new google.maps.InfoWindow({
      content: window.Route ? window.Route.setUpWindowContent(this.id, this.window_content) : ""
    });
    this.window_open = false; // info window is closed by default
    this.path = null;

    if (!this.isRoot()) {
      if (this.parent()) {
        this.parent().resetIcon(); // Reset parent waypoint icon
        this.path = new google.maps.Polyline({
          path: [this.parent().marker.getPosition(), this.latLon],
          strokeColor: '#FF0000',
          strokeOpacity: 1.0,
          strokeWeight: 2,
          map: window.map
        });
      }
    }

    // If height is 0 it is probably a new waypoint so look up elevation using Google's elevation service
    if (this.height === 0) {
      this.getElevation();
    }

    this.setHeightChange();

    // If not set yet compute the distance to the trailhead from this point
    if (!this.isRoot() && this.distance === 0.0 && this.parent()) {
      this.setDistance(this.parent().distance + (google.maps.geometry.spherical.computeDistanceBetween(this.latLon, this.parent().latLon) / 1000.0));
    }

    this.addEvents();
  }

  // Ask Google for elevation
  getElevation() {
    const index = this.id;
    if (!window.Route || !window.Route.elevator) return;
    window.Route.elevator.getElevationForLocations({ locations: [this.latLon] }, (results, status) => {
      if (status === google.maps.ElevationStatus.OK) {
        if (results && results[0] && results[0].elevation !== undefined) {
          const wp = window.Route.getWaypoint(index);
          if (wp) wp.setHeight(Math.round(results[0].elevation));
        } else {
          window.Route.removeWaypoint(index);
          alert("Couldn't retrieve elevation of waypoint from Google. You will need to re-enter the waypoint.");
        }
      } else {
        window.Route.removeWaypoint(index);
        alert(`Google's elevation service failed due to: ${status}. You will need to re-enter the waypoint.`);
      }
    });
  }

  // Add functions to handle events for the waypoint
  addEvents() {
    const index = this.id;

    // When the marker is clicked open the window and load the object's values
    this.markerClickListener = google.maps.event.addListener(this.marker, 'click', () => {
      const waypoint = window.Route.getWaypoint(index);
      if (waypoint) {
        if (waypoint.window_open) {
          window.Route.activateWaypoint(index);
        }
        waypoint.infowindow.open(window.map, waypoint.marker);
      }
    });

    // When an info window is opened load values into it
    this.infoWindowOpenListener = google.maps.event.addListener(this.infowindow, 'domready', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.openWindow();
      const fieldset = $(`#bubble_fieldset_${index}`);
      fieldset.children("BR").remove();
      if ($.fn.TextAreaExpander) {
        fieldset.find("textarea.expand").TextAreaExpander();
      }
    });

    // When an info window is closed update flag
    this.infoWindowCloseListener = google.maps.event.addListener(this.infowindow, 'closeclick', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.setWindowOpen(false);
    });

    // Right click to remove waypoint
    this.markerRightClickListener = google.maps.event.addListener(this.marker, 'rightclick', () => {
      window.Route.removeWaypoint(index);
    });

    // Path click to insert waypoint
    if (this.path) {
      this.pathClickListener = google.maps.event.addListener(this.path, 'click', (event) => {
        window.Route.insertWaypoint(index, event.latLng.lat(), event.latLng.lng());
      });
    }

    // Drag start
    this.dragstartListener = google.maps.event.addListener(this.marker, 'dragstart', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.infowindow.close();
    });

    // Drag end
    this.dragendListener = google.maps.event.addListener(this.marker, 'dragend', (event) => {
      const waypoint = window.Route.getWaypoint(index);
      if (!waypoint) return;

      if (google.maps.geometry.spherical.computeDistanceBetween(event.latLng, new google.maps.LatLng(waypoint.latitude, waypoint.longitude)) > 100000) {
        waypoint.marker.setPosition(waypoint.latLon);
        alert("Waypoints cannot be moved by more than 100km.");
        return;
      }
      waypoint.setLatitude(event.latLng.lat());
      waypoint.setLongitude(event.latLng.lng());
      waypoint.latLon = event.latLng;
      waypoint.redrawLines();
      waypoint.getElevation();
      setTimeout(() => {
        window.Route.computeDistances();
      }, 500);
    });
  }

  removeEvents() {
    if (this.markerClickListener) google.maps.event.removeListener(this.markerClickListener);
    if (this.infoWindowOpenListener) google.maps.event.removeListener(this.infoWindowOpenListener);
    if (this.infoWindowCloseListener) google.maps.event.removeListener(this.infoWindowCloseListener);
    if (this.markerRightClickListener) google.maps.event.removeListener(this.markerRightClickListener);
    if (this.pathClickListener) google.maps.event.removeListener(this.pathClickListener);
    if (this.dragstartListener) google.maps.event.removeListener(this.dragstartListener);
    if (this.dragendListener) google.maps.event.removeListener(this.dragendListener);
  }

  openWindow() {
    this.window_open = true;
    $(`#title_${this.id}`).val(this.title);
    $(`#latitude_${this.id}`).val(this.latitude);
    $(`#longitude_${this.id}`).val(this.longitude);
    $(`#height_${this.id}`).val(this.height);
    $(`#distance_${this.id}`).text(Math.round(this.distance * 100) / 100);
    $(`#height_gain_${this.id}`).text(this.height_gain);
    $(`#height_loss_${this.id}`).text(this.height_loss);
    $(`#description_${this.id}`).val(this.description);
    $(`#icon_${this.id}_${this.icon}`).prop("checked", true);
  }

  destroy() {
    if (this.isRoot() && this.numChildren() > 1) return;
    this.infowindow.close();
    this.marker.setMap(null);
    if (this.path) {
      this.path.setMap(null);
    }
    this.setDestroy(true);
  }

  isRoot() {
    return this.parent_index === null || this.parent_index === undefined || isNaN(this.parent_index) || this.parent_index === this.id || this.parent_index < 0;
  }

  parent() {
    if (!this.isRoot() && window.Route) {
      return window.Route.getWaypoint(this.parent_index);
    }
    return null;
  }

  midLatitude() {
    if (!this.isRoot() && this.parent()) {
      return (parseFloat(this.latitude) + parseFloat(this.parent().latitude)) / 2.0;
    }
    return parseFloat(this.latitude) + 0.005;
  }

  midLongitude() {
    if (!this.isRoot() && this.parent()) {
      return (parseFloat(this.longitude) + parseFloat(this.parent().longitude)) / 2.0;
    }
    return parseFloat(this.longitude) + 0.005;
  }

  setID(newID) {
    this.id = newID;
    this.infowindow.setContent(window.Route.setUpWindowContent(this.id, this.window_content));
    this.removeEvents();
    this.addEvents();
  }

  setTitle(newTitle) {
    this.title = newTitle;
    if (this.icon_src === null || this.icon_src === "") {
      this.icon_src = "/assets/markers/green-dot.png";
      this.marker.setIcon(this.icon_src);
    }
    $(`#route_waypoints_attributes_${this.id}_title`).val(newTitle);
  }

  setLatitude(newLatitude) {
    if (typeof newLatitude === "string") {
      newLatitude = window.convertToDecimal ? window.convertToDecimal(newLatitude) : newLatitude;
      if (newLatitude === "" || isNaN(newLatitude)) {
        $(`#latitude_${this.id}`).val(this.latitude);
        alert("Latitude must be a number.");
        return;
      }
    }
    const latLng = new google.maps.LatLng(newLatitude, this.longitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      $(`#latitude_${this.id}`).val(this.latitude);
      alert("Waypoints cannot be moved by more than 100km apart.");
      return;
    }
    this.latitude = newLatitude;
    $(`#route_waypoints_attributes_${this.id}_latitude`).val(newLatitude);
    if (this.marker.getPosition().lat() !== this.latitude) {
      this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
      this.marker.setPosition(this.latLon);
      this.redrawLines();
    }
  }

  setLongitude(newLongitude) {
    if (typeof newLongitude === "string") {
      newLongitude = window.convertToDecimal ? window.convertToDecimal(newLongitude) : newLongitude;
      if (newLongitude === "" || isNaN(newLongitude)) {
        $(`#longitude_${this.id}`).val(this.longitude);
        alert("Longitude must be a number.");
        return;
      }
    }
    const latLng = new google.maps.LatLng(this.latitude, newLongitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      $(`#longitude_${this.id}`).val(this.longitude);
      alert("Waypoints cannot be moved by more than 100km apart.");
      return;
    }
    this.longitude = newLongitude;
    $(`#route_waypoints_attributes_${this.id}_longitude`).val(newLongitude);
    if (this.marker.getPosition().lng() !== this.longitude) {
      this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
      this.marker.setPosition(this.latLon);
      this.redrawLines();
    }
  }

  setParentIndex(newParentIndex) {
    this.parent_index = newParentIndex;
    $(`#route_waypoints_attributes_${this.id}_parent_index`).val(newParentIndex);
    this.computeDistance();
  }

  setHeight(newHeight) {
    this.height = newHeight;
    $(`#route_waypoints_attributes_${this.id}_height`).val(newHeight);
    if (window.Route) window.Route.computeDistances();
  }

  getHeightChangeToParent() {
    if (this.isRoot() || !this.parent()) {
      return 0;
    }
    return this.height - this.parent().height;
  }

  setHeightChange() {
    if (this.isRoot() || !this.parent()) {
      this.height_gain = 0;
      this.height_loss = 0;
    } else {
      const heightChange = this.getHeightChangeToParent();
      this.height_gain = this.parent().height_gain || 0;
      this.height_loss = this.parent().height_loss || 0;
      if (heightChange >= 0) {
        this.height_gain += heightChange;
      } else {
        this.height_loss -= heightChange;
      }
    }
    $(`#route_waypoints_attributes_${this.id}_height_gain`).val(this.height_gain);
    $(`#route_waypoints_attributes_${this.id}_height_loss`).val(this.height_loss);
  }

  distToParent() {
    if (this.isRoot() || !this.parent()) {
      return 0.0;
    }
    return google.maps.geometry.spherical.computeDistanceBetween(this.latLon, this.parent().latLon) / 1000.0;
  }

  computeDistance() {
    if (this.isRoot() || !this.parent()) {
      this.setDistance(0.0);
    } else {
      this.setDistance(this.parent().distance + this.distToParent());
    }
  }

  setDistance(newDistance) {
    this.distance = newDistance;
    $(`#route_waypoints_attributes_${this.id}_distance`).val(newDistance);
  }

  setDescription(newDescription) {
    this.description = newDescription;
    if (this.icon_src === null || this.icon_src === "") {
      this.icon_src = "/assets/markers/green-dot.png";
      this.marker.setIcon(this.icon_src);
    }
    $(`#route_waypoints_attributes_${this.id}_description`).val(newDescription);
  }

  resetIcon() {
    this.marker.setIcon(this.icon_src);
  }

  setIcon(newIcon, icon_src) {
    this.icon = newIcon;
    this.icon_src = icon_src;
    this.marker.setIcon(icon_src);
    $(`#route_waypoints_attributes_${this.id}_icon`).val(newIcon);
  }

  setWindowOpen(open) {
    this.window_open = open;
  }

  setDestroy(newDestroy) {
    this._destroy = newDestroy;
    $(`#route_waypoints_attributes_${this.id}__destroy`).val(newDestroy);
  }

  setPath() {
    if (!this.isRoot() && this.parent()) {
      if (this.path) {
        this.path.setPath([this.parent().latLon, this.latLon]);
      } else {
        this.path = new google.maps.Polyline({
          path: [this.parent().latLon, this.latLon],
          strokeColor: '#FF0000',
          strokeOpacity: 1.0,
          strokeWeight: 2,
          map: window.map
        });
      }
    } else if (this.path) {
      this.path.setMap(null);
      this.path = null;
    }
  }

  redrawLines() {
    this.setPath();
    if (!window.Route || !window.Route.waypoints) return;
    for (let i = this.id + 1; i < window.Route.local_index; i++) {
      const waypoint = window.Route.waypoints[i];
      if (waypoint && !waypoint._destroy) {
        waypoint.setPath();
      }
    }
  }

  save() {
    $(`#route_waypoints_attributes_${this.id}_parent_index`).val(this.parent_index);
    $(`#route_waypoints_attributes_${this.id}_title`).val(this.title);
    $(`#route_waypoints_attributes_${this.id}_latitude`).val(this.latitude);
    $(`#route_waypoints_attributes_${this.id}_longitude`).val(this.longitude);
    $(`#route_waypoints_attributes_${this.id}_height`).val(this.height);
    $(`#route_waypoints_attributes_${this.id}_distance`).val(this.distance);
    $(`#route_waypoints_attributes_${this.id}_height_gain`).val(this.height_gain);
    $(`#route_waypoints_attributes_${this.id}_height_loss`).val(this.height_loss);
    $(`#route_waypoints_attributes_${this.id}_description`).val(this.description);
    $(`#route_waypoints_attributes_${this.id}_icon`).val(this.icon);
    $(`#route_waypoints_attributes_${this.id}__destroy`).val(this._destroy);
  }

  numChildren() {
    let count = 0;
    if (!window.Route || !window.Route.waypoints) return 0;
    for (let i = this.id + 1; i < window.Route.local_index; i++) {
      const waypoint = window.Route.waypoints[i];
      if (waypoint && !waypoint._destroy && waypoint.parent_index === this.id) {
        count++;
      }
    }
    return count;
  }
}

window.Waypoint = Waypoint;


// === route.js ===

const RouteObject = {
  allow_branches: true,
  centerLatLng: null,
  elevator: null,
  active_index: null,
  local_index: 0,
  waypoints: [],

  coordinatesTooFarAway(latitude, longitude) {
    const latLng = new google.maps.LatLng(latitude, longitude);
    if (this.active_index !== null && this.waypoints[this.active_index]) {
      return google.maps.geometry.spherical.computeDistanceBetween(this.waypoints[this.active_index].marker.getPosition(), latLng) > 100000;
    }
    return false;
  },

  initRoute(branches_allowed, startLatitude, startLongitude, startContent, startName) {
    this.allow_branches = branches_allowed;
    this.centerLatLng = new google.maps.LatLng(startLatitude, startLongitude);
    const centerContentString = `<div class='reference_window'>${startContent}</div>`;
    const centerInfowindow = new google.maps.InfoWindow({ content: centerContentString });
    const centerMarker = new google.maps.Marker({
      position: this.centerLatLng,
      clickable: false,
      zIndex: -100,
      map: window.map,
      icon: "/assets/markers/center-dot.png",
      shape: {
        coord: [15, 18, 6],
        type: 'circle'
      },
      title: startName
    });

    google.maps.event.addListener(window.map, "click", this.mapClicked);
    this.elevator = new google.maps.ElevationService();
  },

  mapClicked(event) {
    if (window.Route && window.Route.local_index > 0) {
      for (let index = 0; index < window.Route.local_index; index++) {
        const waypoint = window.Route.waypoints[index];
        if (!waypoint || waypoint._destroy) continue;
        const lat = waypoint.latitude;
        const lng = waypoint.longitude;
        let threshold = 0.005;
        switch (window.map.getZoom()) {
          case 13: threshold = 0.003; break;
          case 14: threshold = 0.002; break;
          case 15: threshold = 0.001; break;
          case 16: threshold = 0.0005; break;
          case 17: threshold = 0.0003; break;
          case 18: threshold = 0.0001; break;
          case 19: threshold = 0.00005; break;
        }

        if (
          Math.abs(lat - event.latLng.lat()) < threshold &&
          Math.abs(lng - event.latLng.lng()) < threshold &&
          index !== window.Route.active_index &&
          window.Route.waypoints[window.Route.active_index] &&
          window.Route.waypoints[window.Route.active_index].parent_index !== index
        ) {
          $("#Latitude").val(window.Route.waypoints[index].latitude);
          $("#Longitude").val(window.Route.waypoints[index].longitude);
          $("#btnAddWaypoint").click();
          return;
        }
      }
    }

    $("#Latitude").val(event.latLng.lat());
    $("#Longitude").val(event.latLng.lng());
    $("#btnAddWaypoint").click();
  },

  setUpWindowContent(id, content) {
    if (!content) return "";
    content = content.replace('id="bubble_fieldset"', `id="bubble_fieldset_${id}"`);
    content = content.replace('id="title"', `id="title_${id}"`);
    content = content.replace('id="latitude"', `id="latitude_${id}"`);
    content = content.replace('id="longitude"', `id="longitude_${id}"`);
    content = content.replace('id="height"', `id="height_${id}"`);
    content = content.replace('id="distance"', `id="distance_${id}"`);
    content = content.replace('id="height_gain"', `id="height_gain_${id}"`);
    content = content.replace('id="height_loss"', `id="height_loss_${id}"`);
    content = content.replace('id="description"', `id="description_${id}"`);
    content = content.replace(/id="icon_/g, `id="icon_${id}_`);
    content = content.replace(/name="icon"/g, `name="icon_${id}"`);
    content = content.replace('onchange="title"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setTitle($(this).val());"`);
    content = content.replace('onchange="latitude"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setLatitude($(this).val());"`);
    content = content.replace('onchange="longitude"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setLongitude($(this).val());"`);
    content = content.replace('onchange="height"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setHeight(parseInt($(this).val()));"`);
    content = content.replace('onchange="description"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setDescription($(this).val());"`);
    content = content.replace(/onchange="icon"/g, `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setIcon($(this).val(),$(this).prev('img').prop('src'));"`);
    content = content.replace('onclick=";"', `onmouseup="window.Route.activateWaypoint(${id});"`);
    content = content.replace('onclick=";"', `onmouseup="window.Route.insertWaypointClicked(${id});"`);
    content = content.replace('onclick=";"', `onmouseup="if(confirm('Really delete this waypoint?')) window.Route.removeWaypoint(${id});"`);
    return content;
  },

  loadWaypoint(id, window_content, icon_src) {
    let parent_index = parseInt($(`#route_waypoints_attributes_${id}_parent_index`).val(), 10);
    if (isNaN(parent_index) || parent_index === this.local_index) {
      parent_index = null;
    }
    this.waypoints[id] = new Waypoint(
      id,
      parent_index,
      $(`#route_waypoints_attributes_${id}_title`).val(),
      $(`#route_waypoints_attributes_${id}_latitude`).val(),
      $(`#route_waypoints_attributes_${id}_longitude`).val(),
      parseInt($(`#route_waypoints_attributes_${id}_height`).val(), 10) || 0,
      parseFloat($(`#route_waypoints_attributes_${id}_distance`).val()) || 0.0,
      parseInt($(`#route_waypoints_attributes_${id}_height_gain`).val(), 10) || 0,
      parseInt($(`#route_waypoints_attributes_${id}_height_loss`).val(), 10) || 0,
      $(`#route_waypoints_attributes_${id}_description`).val(),
      $(`#route_waypoints_attributes_${id}_icon`).val(),
      icon_src,
      window_content
    );
    this.local_index = this.waypoints.length;
    this.active_index = this.local_index - 1;
    this.computeDistances();
  },

  addNewWaypoint(button, association, content, window_content) {
    const latVal = $("#Latitude").val();
    const lngVal = $("#Longitude").val();
    let latitude = window.convertToDecimal ? window.convertToDecimal(latVal) : latVal;
    let longitude = window.convertToDecimal ? window.convertToDecimal(lngVal) : lngVal;
    if (latitude === "" || longitude === "" || isNaN(latitude) || isNaN(longitude) || this.coordinatesTooFarAway(latitude, longitude)) {
      alert("Latitude and Longitude must be numbers at most 500km away from the center of this area and no more than 100km away from the previous waypoint added.");
      return;
    }
    content = content.replace(new RegExp(`new_${association}`, "g"), this.local_index);
    content = content.replace('type="hidden" />', `type="hidden" value="${latitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${longitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.local_index}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.active_index}" />`);
    this.waypoints[this.local_index] = new Waypoint(this.local_index, this.active_index, "", latitude, longitude, 0, 0.0, 0, 0, "", "", null, window_content);
    this.active_index = this.local_index;
    this.local_index++;
    $(button).after(content);
    setTimeout(() => {
      this.computeDistances();
    }, 500);
  },

  insertWaypoint(insert_index, lat, lon) {
    if (this.waypoints[insert_index].isRoot()) {
      alert("Cannot insert a point before the first point");
      return;
    }
    $("#Latitude").val(lat);
    $("#Longitude").val(lon);
    $("#btnAddWaypoint").click();
    setTimeout(() => {
      this.continueInsertingWaypoint(insert_index);
    }, 500);
  },

  continueInsertingWaypoint(insert_index) {
    const inserted = this.waypoints[this.active_index];

    for (let index = this.local_index - 1; index >= insert_index; index--) {
      const waypoint = this.waypoints[index];
      waypoint.setID(index + 1);
      if (waypoint.parent_index >= insert_index) {
        waypoint.parent_index++;
      }
      this.waypoints[index + 1] = waypoint;
      waypoint.save();
    }

    const child = this.waypoints[insert_index + 1];
    inserted.setID(insert_index);
    inserted.parent_index = child.parent_index;
    inserted.computeDistance();
    inserted.setPath();
    this.waypoints[insert_index] = inserted;
    inserted.save();
    this.active_index = insert_index;

    child.setParentIndex(insert_index);
    child.setPath();
    child.save();
    this.computeDistances();
  },

  insertWaypointClicked(insert_index) {
    this.insertWaypoint(insert_index, this.waypoints[insert_index].midLatitude(), this.waypoints[insert_index].midLongitude());
  },

  activateWaypoint(index) {
    if ((this.allow_branches && this.active_index !== index) || (this.activeWaypoint() && this.activeWaypoint()._destroy)) {
      if (this.getWaypoint(index)) {
        this.getWaypoint(index).marker.setIcon("/assets/markers/yellow-dot.png");
      }
      if (this.activeWaypoint()) {
        this.activeWaypoint().resetIcon();
      }
      this.active_index = index;
    }
  },

  removeWaypoint(index) {
    const removed = this.getWaypoint(index);
    if (!removed) return;
    if (removed.isRoot() && removed.numChildren() > 1) {
      alert("Cannot remove the root point since this will disconnect the route");
      return;
    }
    removed.destroy();

    let reassign_active_index = this.active_index === index;
    const grandparent_index = removed.parent_index;

    for (let i = index; i < this.local_index; i++) {
      const waypoint = this.waypoints[i];
      if (!waypoint || waypoint._destroy) continue;
      const parent_index = waypoint.parent_index;
      if (parent_index === index) {
        waypoint.setParentIndex(grandparent_index);
        if (grandparent_index !== null && grandparent_index !== undefined) {
          waypoint.setPath();
        } else if (waypoint.path) {
          waypoint.path.setMap(null);
        }
      }
      if (reassign_active_index) {
        this.activateWaypoint(i);
        reassign_active_index = false;
      }
    }

    if (reassign_active_index) {
      if (grandparent_index !== null && grandparent_index !== undefined) {
        this.activateWaypoint(grandparent_index);
      } else {
        this.active_index = null;
        for (let i = this.local_index - 1; i >= 1; i--) {
          if (this.waypoints[i] && !this.waypoints[i]._destroy) {
            this.activateWaypoint(i);
            break;
          }
        }
      }
    }

    this.computeDistances();
  },

  getWaypoint(index) {
    return this.waypoints[index];
  },

  activeWaypoint() {
    return this.waypoints[this.active_index];
  },

  computeDistances() {
    let distance = 0;
    let height_gain = 0;
    let height_loss = 0;
    for (let i = 0; i < this.local_index; i++) {
      const waypoint = this.waypoints[i];
      if (!waypoint || waypoint._destroy) continue;
      waypoint.computeDistance();
      waypoint.setHeightChange();
      distance += waypoint.distToParent();
      const heightChange = waypoint.getHeightChangeToParent();
      if (heightChange >= 0) {
        height_gain += heightChange;
      } else {
        height_loss -= heightChange;
      }
    }
    $("#route_distance").val(Math.round(distance * 100) / 100);
    $("#route_height_gain").val(height_gain);
    $("#route_height_loss").val(height_loss);
  }
};

window.Route = RouteObject;


// === border_point.js ===

// Our constructor for creating border points. Used for both new and loaded border points.
var BorderPoint = window.BorderPoint = class BorderPoint {
  constructor(id, latitude, longitude) {
    this.id = id;
    this.latitude = latitude;
    this.longitude = longitude;
    this._destroy = false;
    this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
    this.marker = new google.maps.Marker({
      position: this.latLon,
      map: window.map,
      title: "A border point",
      draggable: true,
      icon: "/assets/markers/yellow-dot.png"
    });

    // Set parent icon to red if id > 0
    if (this.id > 0 && window.Place && window.Place.borderPoints && window.Place.borderPoints[this.id - 1]) {
      window.Place.borderPoints[this.id - 1].marker.setIcon();
    }

    // Make sure local_index value is equal to the index used by Place
    $(`#place_border_points_attributes_${this.id}_local_index`).val(this.id);
    const index = this.id;

    // Remove marker when right clicked
    google.maps.event.addListener(this.marker, 'rightclick', () => {
      window.Place.removeBorderPoint(index);
    });

    // Change the border point lat/lon to the new coordinate for the marker
    google.maps.event.addListener(this.marker, 'dragend', (event) => {
      window.Place.moveBorderPoint(index, event.latLng.lat(), event.latLng.lng());
    });
  }

  destroy() {
    this.marker.setMap(null);
    this.setDestroy(true);
  }

  setPosition(newLatitude, newLongitude) {
    const latLng = new google.maps.LatLng(newLatitude, newLongitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      alert("Border points cannot be moved by more than 100km apart.");
      return;
    }
    this.latitude = newLatitude;
    this.longitude = newLongitude;
    $(`#place_border_points_attributes_${this.id}_latitude`).val(newLatitude);
    $(`#place_border_points_attributes_${this.id}_longitude`).val(newLongitude);
    this.latLon = latLng;
    this.marker.setPosition(this.latLon);
  }

  setDestroy(newDestroy) {
    this._destroy = newDestroy;
    $(`#place_border_points_attributes_${this.id}__destroy`).val(newDestroy);
  }
}

window.BorderPoint = BorderPoint;


// === place.js ===

const PlaceObject = {
  local_index: 0,
  active_index: null,
  borderPoints: [],
  pathCoordinates: [],
  path: null,
  thinPath: null,

  // If the place was submitted then this line would close the loop
  // It is drawn as a reference to show people they don't have to close the loop themselves.
  updateThinPlaceConnectingLine() {
    if (this.thinPath !== null) {
      this.thinPath.setMap(null);
    }
    if (this.pathCoordinates.length > 2) {
      this.thinPath = new google.maps.Polyline({
        path: [this.pathCoordinates[0], this.pathCoordinates[this.pathCoordinates.length - 1]],
        strokeColor: '#00FF00',
        strokeOpacity: 0.5,
        strokeWeight: 1,
        map: window.map
      });
    }
  },

  // Called when loading a pre-existing border point (editing an existing place)
  loadBorderPoint(id) {
    this.borderPoints[id] = new BorderPoint(
      id,
      $(`#place_border_points_attributes_${id}_latitude`).val(),
      $(`#place_border_points_attributes_${id}_longitude`).val()
    );
    this.pathCoordinates[id] = this.borderPoints[id].latLon;
    this.updateThinPlaceConnectingLine();
    this.local_index = this.borderPoints.length;
    this.active_index = this.local_index - 1;
  },

  // Adds the new border point to the form
  addNewBorderPoint(button, association, content) {
    const latVal = $("#Latitude").val();
    const lngVal = $("#Longitude").val();
    let latitude = window.convertToDecimal ? window.convertToDecimal(latVal) : latVal;
    let longitude = window.convertToDecimal ? window.convertToDecimal(lngVal) : lngVal;
    $("#Latitude").val(latitude);
    $("#Longitude").val(longitude);

    if (latitude === "" || longitude === "" || isNaN(latitude) || isNaN(longitude)) {
      alert("Latitude and Longitude must be numbers at most 500km away from the center of this place and no more than 100km away from the previous waypoint added.");
      return;
    }

    content = content.replace(new RegExp(`new_${association}`, "g"), this.local_index);
    content = content.replace('type="hidden" />', `type="hidden" value="${latitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${longitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.local_index}" />`);
    $(button).after(content);

    this.borderPoints[this.local_index] = new BorderPoint(this.local_index, latitude, longitude);
    this.pathCoordinates.push(this.borderPoints[this.local_index].latLon);

    if (this.active_index !== null && this.active_index !== undefined) {
      if (this.borderPoints[this.active_index]) {
        this.borderPoints[this.active_index].marker.setIcon(); // Reset parent waypoint icon
      }
      if (this.path) {
        this.path.setMap(null);
      }
      this.path = new google.maps.Polyline({
        path: this.pathCoordinates,
        strokeColor: '#FF0000',
        strokeOpacity: 1.0,
        strokeWeight: 2,
        map: window.map
      });
    }

    this.updateThinPlaceConnectingLine();
    this.active_index = this.local_index;
    this.local_index++;
  },

  // Remove point at index
  removeBorderPoint(index) {
    this.borderPoints[index].destroy();

    // Remove point from polyline
    const marker = this.borderPoints[index].marker;
    let i = 0;
    for (i = 0; i < this.pathCoordinates.length; i++) {
      const coord = this.pathCoordinates[i];
      if (marker.getPosition().lat() === coord.lat() && marker.getPosition().lng() === coord.lng()) {
        break;
      }
    }
    this.pathCoordinates.splice(i, 1);
    if (this.path) {
      this.path.setMap(null);
    }
    this.path = new google.maps.Polyline({
      path: this.pathCoordinates,
      strokeColor: '#FF0000',
      strokeOpacity: 1.0,
      strokeWeight: 2,
      map: window.map
    });
    this.updateThinPlaceConnectingLine();

    // Need to assign active index to next available point
    if (this.active_index === index) {
      for (let j = parseInt(index) - 1; j >= 1; j--) {
        const point = this.borderPoints[j];
        if (point && !point._destroy) {
          point.marker.setIcon("/assets/markers/yellow-dot.png");
          this.active_index = j;
          break;
        }
      }
    }
  },

  moveBorderPoint(index, latitude, longitude) {
    this.borderPoints[index].setPosition(latitude, longitude);
    this.redraw();
  },

  redraw() {
    if (this.path) {
      this.path.setMap(null);
    }
    this.pathCoordinates = [];
    for (const point of this.borderPoints) {
      if (point && !point._destroy) {
        this.pathCoordinates.push(point.latLon);
      }
    }
    this.path = new google.maps.Polyline({
      path: this.pathCoordinates,
      strokeColor: '#FF0000',
      strokeOpacity: 1.0,
      strokeWeight: 2,
      map: window.map
    });
    this.updateThinPlaceConnectingLine();
  }
};

window.Place = PlaceObject;


// === main/shared.js ===

let busy = false;

window.Main = {
  // Show menu bar
  showMenuBar() {
    $("#menuSearchBar").show();
    $("#searchDiv").width(Math.max(150, $("body").width() - $("#menuDiv").width()));
  },

  // Loads new photos for the user corresponding to the summary div
  loadUserPhotos(summaryDiv, type) {
    if (!summaryDiv.hasClass('User_Photo_Summary')) {
      summaryDiv = summaryDiv.parents('.User_Photo_Summary');
    }
    const elemId = summaryDiv.prop('id') || "";
    const user_id = elemId.substring(elemId.indexOf(":") + 1);
    const displayDivID = "#divUserPhotos" + user_id;

    if (busy || $(displayDivID).is(':visible')) return;
    busy = true;

    $('.User_Photo_Summary').css('background-color', 'white');
    summaryDiv.css('background-color', '#bbb');

    const getpath = `/users/${user_id}/photos?type=${type}`;
    $('.User_Photos').html('<p style="font-size:larger"><span class="ajax-loader"></span> Loading member photos</p>');

    $.get(getpath, function(data) {
      $(".User_Photos").html(data);
      busy = false;
    });
  },

  // Init callbacks for user photo summaries
  initPhotoSummaries(type) {
    busy = false;
    const isTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || (window.Modernizr && window.Modernizr.touch);

    if (!isTouch) {
      $('.User_Photo_Summary').on('mouseenter', (e) => {
        this.loadUserPhotos($(e.target), type);
      });
    } else {
      $('.User_Photo_Summary').on('click', (e) => {
        this.loadUserPhotos($(e.target), type);
      });
    }
  }
};


// === main/index.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.main.index').length && window.Main) {
    window.Main.showMenuBar();
    window.Main.initPhotoSummaries('new');
  }
});


// === main/updated.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.main.updated').length && window.Main) {
    window.Main.showMenuBar();
    window.Main.initPhotoSummaries('updated');
  }
});


// === places/show.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.places.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/places/{{id}}/photos");
  }
});


// === routes/show.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.routes.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/routes/{{id}}/photos");
  }
});


// === albums/show.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.albums.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/albums/{{id}}/photos");
  }
});


// === trip_reports/show.js ===

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.trip_reports.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/trip_reports/{{id}}/photos");
  }
});
