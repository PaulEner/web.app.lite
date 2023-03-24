function bind_ibizabox_documents_events() {
  if ($('#ibizabox_documents.select').length > 0){
    $('#master_checkbox').unbind('change').bind('change', function(e) {
      if ($(this).is(':checked'))
        $('.checkbox').attr('checked', true);
      else
        $('.checkbox').attr('checked', false);
    });
  }
}

jQuery(function() {
  bind_ibizabox_documents_events();
});