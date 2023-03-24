function bind_softwares_setting_events(){
  $('.btn#csv-descriptor-format').unbind('click.descriptor').bind('click.descriptor', function(e){ AppEmit('csv_descriptor_open_edition', { id: $(this).data('organization-id') }) });

  $('img.use-software, span.use-software').unbind('click');
  $('img.use-software, span.use-software').bind('click', function(){
    if (!$(this).parent().hasClass('selected')) { $(this).parent().addClass('selected'); }

    $('#use-software-' + $(this).parent().attr('id')).modal('show');
  });

  $('#edit_customer_csv_descriptor').unbind('click').bind('click', function(e){ AppEmit('csv_descriptor_edit_customer_format', { id: $(this).data('id'), organization_id: $(this).data('organization-id') }) });

  if ($('.customer_softwares_setting_list').length > 0){ $('.head_customer_link#softwares-list').addClass('active'); }

  ApplicationJS.set_checkbox_radio();
}

jQuery(function() {
  bind_softwares_setting_events();
});