class FileSendingKit{

  constructor(){
    this.applicationJS      = new ApplicationJS();
    this.organization_id    = $('input:hidden[name="organization_id"]').val();
    this.add_new_rule_modal = $('#add-new-rule.modal');
    this.file_sending_kits_edit = $('#file_sending_kits_edit.modal');
    this.select_multiple       = $('#select_for_orders.modal');
    this.action_locker      = false;
  }

  generate_manual_paper_set_order(url, data){
    this.applicationJS.sendRequest({
      'url': url,
      'data': data,
      'type': 'POST',
      'dataType': 'json',
    }).then((result)=>{
      $(".manual-paper-set-loading-content").remove();
      $('#download-manual-paper-set-order .show-notify-content').hide('fade', 100);
      $('#download-manual-paper-set-order .pending-generation').addClass('hide');
      $('#download-manual-paper-set-order .error-generation').addClass('hide');
      $('#download-manual-paper-set-order .success-generation').removeClass('hide');
      $('#download-manual-paper-set-order .download-manual-paper-set-order-folder-pdf').show();
      $("#generate-manual-paper-set-order").removeAttr("disabled");
      $(".canceling-manual-order").removeAttr("disabled");
     }).catch((result)=>{ 
      this.action_locker = false;

      console.error(result);
      let message = 'Une erreur a été rencontré lors de la régénération de votre commande ... veuillez réessayer svp'
      if(result.status == '603'){
        message = result.responseText;
      }

      $(".manual-paper-set-loading-content").remove();
      $('#download-manual-paper-set-order .pending-generation').addClass('hide');
      $('#download-manual-paper-set-order .success-generation').addClass('hide');
      $('#download-manual-paper-set-order .error-generation').html(message);
      $("#generate-manual-paper-set-order").attr('disabled', 'disabled');
      $("#generate-manual-paper-set-order").removeAttr('disabled');
      $(".canceling-manual-order").removeAttr("disabled");
    });
  }

  edit_file_sending_kits_view(url){
    this.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      this.file_sending_kits_edit.find('.modal-body').html($(element).find('.file_sending_kits_edit').html());
      if ((this.select_multiple).hasClass('show')) {
        this.select_multiple.modal('hide');
      }
      this.file_sending_kits_edit.modal('show');
    }).catch((error)=> { 
      console.error(error);
    });
  }

  select_for_orders(url){
    this.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      this.select_multiple.find('.modal-body').html($(element).find('.file_sending_kits_select').html());
      this.remve_footer_content();

      this.select_multiple.modal('show');
    }).catch((error)=> {
      console.log(error)
    });
  }

  remve_footer_content(){ this.select_multiple.find('.form-footer-content').remove(); }

  select_for_multiple_result(response){
    this.remve_footer_content();
    file_sending_kits_main_events();
  }
}