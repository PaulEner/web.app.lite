function update_journal_fields(code) {
  const fileUploadParams = $('#data-invoice-integration').data('params');

  var accountBookTypes, comptaProcessable, content, i, journalsComptaProcessable, name;
  accountBookTypes = fileUploadParams[code]['journals'];
  journalsComptaProcessable = fileUploadParams[code]['journals_compta_processable'] || [];
  content = '';
  i = 0;
  while (i < accountBookTypes.length) {
    name = accountBookTypes[i].split(' ')[0].trim();
    comptaProcessable = journalsComptaProcessable.includes(name) ? '1' : '0';
    content = content + '<option compta-processable=' + comptaProcessable + ' value=' + name + '>' + accountBookTypes[i] + '</option>';
    i++;
  }

  $('#invoice_setting_journal_code').html(content);
};

jQuery(function () {
  AppListenTo('integration_bind_user_change', (e)=>{
    $('#invoice_setting_user_code').on('change', function() {
      if ($(this).val() !== ''){
        update_journal_fields($(this).val());
        $('#invoice_setting_journal_code').val();
        $('#invoice_setting_journal_code').change();
      } else {
        $('#invoice_setting_journal_code').html('');
      }
    });
  });

  AppListenTo('set_synchronisation_id', (e)=>{ 
    let id = e.detail.obj.data('id');
    $('form#synchronization-invoice-form #invoice_setting_id').val(id);
  });


  AppListenTo('set_iframe_url', (e)=>{
    let url = e.detail.obj.data('url');
    $('#invoice_view iframe').attr('src', url);
  })

  // Need to hide some elements [vs reload page] on hidden(close) modal
  $('#general_idocus_main_modal').on('hidden.bs.modal', function () {
    // window.location.reload();

    $('#synchronization').addClass('hide');
    $('#integration').addClass('hide');
    $('#invoice_view iframe').attr('src', '');
  });
});