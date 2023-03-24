jQuery(function () {
  $('.commande').unbind('click')
  $(".commande").bind('click',function(e) {
      e.stopPropagation()
      $('#integration').modal('show')
  });
});