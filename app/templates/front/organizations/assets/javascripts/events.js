function bind_organization_events() {
  $('.valid-modification').unbind('click').bind('click', function(e) {
    e.preventDefault();
    
    if (confirm('Vous venez de changer les paramètres, voulez-vous enregister les modifications apportées ?')) {
      $('form#organization_edit').submit();
    }
  });
}


jQuery(function () {
  bind_organization_events();
});