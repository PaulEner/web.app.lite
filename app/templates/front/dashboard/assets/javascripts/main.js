function bind_favorite_clicks(){
  $('.favorite-link').unbind('click');
  $('.favorite-link').bind('click',function(e) {
    e.stopPropagation();
    var id = $(this).attr('id');
    
    if ($(this).children().hasClass('rotate')){      
      $(this).children().removeClass('rotate').addClass('rotate-reset');
      $('#details_'+id).hide('');
    }
    else{
      $(this).children().removeClass('rotate-reset').addClass('rotate');
      $('#details_'+id).show('');
    }    
  });
}

jQuery(function(){
  let applicationJS = new ApplicationJS();

  bind_favorite_clicks();
});