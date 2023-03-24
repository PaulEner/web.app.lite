class VatAccount {
  constructor(){
    this.applicationJS         = new ApplicationJS;
    this.organization_id       = $('input:hidden[name="organization_id"]').val();
    this.add_vat_account_modal = $('#add-vat-account.modal');
    this.customer_id           = $('input:hidden[name="customer_id"]').val();
  }


  add_vat_account(){
    let self = this;
    $('.edit-vat-account').unbind('click').bind('click', function(e) {
      e.stopPropagation();
      e.preventDefault();

      self.get_edit_view($(this).attr('data-vat-account-id'));

      self.add_vat_account_modal.modal('show');
    })
  }

  main() {
    if ($('#vat_accounts .edit-vat-account').length > 0) {
      this.add_vat_account();
    }

    this.handle_edit_delete_submenu();
    ApplicationJS.set_checkbox_radio();
  }


  get_edit_view(id=0){
    let self = this;    

    let url = '/organizations/' + self.organization_id + '/customers/' + self.customer_id + '/accounting_plan/vat_accounts/'+ id +'/edit';

    if (id == 0)
      url = '/organizations/' + self.organization_id + '/customers/' + self.customer_id + '/accounting_plan/vat_accounts/new';
    
    self.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      self.add_vat_account_modal.find('.modal-body').html($(element));

      if (id != 0) { self.add_vat_account_modal.find('.modal-title').text('Éditer un compte TVA'); }      
    });
  }


  handle_edit_delete_submenu(){
    $('.action.edit-delete-menu').unbind('click').bind('click',function(e) {
      e.stopPropagation();

      $('.sub_menu').not(this).each(function(){
        $(this).addClass('hide');
      });

      $(this).parent().find('.sub_menu').removeClass('hide');
    });
  }
}



jQuery(function() {
  let accounting_plan = new VatAccount();
  accounting_plan.main();

  AppListenTo('show_accounting_plan', (e)=>{ if (e.detail.response.json_flash.success) { window.location.href = e.detail.response.url } });
});