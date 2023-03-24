function calculate_space(link){
  var parent_div = link.parent('div');
  var target_div = parent_div.find('.auto-scroll-div').first();

  var button_width = link.outerWidth() + 10
  var parent_width = parent_div.innerWidth() - (button_width * 2)
  var target_width = $('.auto-scroll-div')[0].offsetWidth

  window.parent_width = parent_width;
  window.target_width = target_width;
}

function generate_auto_scroll_for_div(link, direction){
  var target_div = link.parent('div').find('.auto-scroll-div').first();

  var leftPos   = target_div.scrollLeft();
  var stepPos   = Math.abs(window.target_width - window.parent_width) + (target_div.outerWidth() / 2)

  var stepPixel = direction == "right" ? leftPos + stepPos : leftPos - stepPos

  target_div.animate({scrollLeft: stepPixel }, 800);
}

function show_hide_overflow(){
  if( $('.auto-scroll-div').length > 0 ){
    button_span = $('.main-menu-content.auto-scroll-div').parent('div').find('span[class^="auto-scroll-span"]').first();
    calculate_space(button_span)

    if (window.parent_width < window.target_width){
        $('span[class^="auto-scroll-span"]').removeClass('hide')
        $('.auto-scroll-div').removeClass('mr-auto')
    }
    else{    
      $('span[class^="auto-scroll-span"]').addClass('hide')
      $('.auto-scroll-div').addClass('mr-auto')
    }
  }
}

jQuery(function () {  
  show_hide_overflow();

  $( window ).resize(function() {
    show_hide_overflow();
  });

  $('span[class^="auto-scroll-span"]').unbind('click').bind('click', function(e){
      var class_name = $(this).attr('class').split(' ')[0];
      var direction  = class_name.split('-')[3];
      generate_auto_scroll_for_div($(this), direction);
    });

  $('.auto-scroll-div .dropdown a').unbind('click').bind('click', function(e){
    $('.auto-scroll-div .dropdown-menu').css({ 'position' : 'fixed !important', 'right' : 'auto', 'top' : 'auto', 'left' : $(this).offset().left });
  });
});