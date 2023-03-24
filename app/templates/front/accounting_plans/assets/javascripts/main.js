//=require './conterpart-account'

class AccountingPlan {
  constructor(){
    this.applicationJS       = new ApplicationJS;
    this.organization_id     = $('input:hidden[name="organization_id"]').val();
    this.edit_provider_modal = $('#edit-provider-customer.modal');
    this.customer_id         = $('input:hidden[name="customer_id"]').val();
  }

  set_auto_update(){
    let self = this;
    $('#auto-update-accounting-plan').unbind('click').bind('click', function(e) {
      e.stopPropagation();

      let current_element = $(this);

      let element         = current_element.attr('info').split('-');
      let organization_id = element[0];
      let customer_id     = element[1];
      let software        = element[2];

      var promise = new Promise(function(resolve, reject) {
       window.setTimeout(function() {
         resolve(self.get_data(current_element, software));
       });
      }).then(function(data) {
        const params =  {
                    'url': '/organizations/' + organization_id + '/customers/' + customer_id + '/accounting_plan/auto_update',
                    'type': 'POST',
                    'data': data,
                    'dataType': 'json',
                    'contentType': 'application/json'
                  };

        self.applicationJS.sendRequest(params).then((result)=>{ self.applicationJS.noticeSuccessMessageFrom(null, result.message); });
     });
    });
  }

  get_data(current_element, software){
    let auto_updating_accounting_plan = 0;
    let software_table  = 'ibiza';

    if (current_element.val() === 'true'){
      auto_updating_accounting_plan = 1
    }
    if (software === 'My Unisoft'){
      software_table = 'my_unisoft'
    }

    if (software === 'Sage GEC'){
      software_table = 'sage_gec'
    }

    return JSON.stringify({
      auto_updating_accounting_plan: auto_updating_accounting_plan,
      software: software,
      software_table: software_table
    });
  }


  edit_provider_customer(){
    let self = this;
    $('.edit-accounting-plan').unbind('click').bind('click', function(e) {
      e.stopPropagation();
      e.preventDefault();

      if ($(this).hasClass('provider')) { self.get_edit_view($(this).attr("data-account-id"), 'provider'); }
      else if ($(this).hasClass('customer')) { self.get_edit_view($(this).attr("data-account-id"), 'customer'); }

      self.edit_provider_modal.modal('show');
    })
  }

  get_vat_accounts_view(){
    let customer_id = $('input:hidden[name="customer_id"]').val();
    this.applicationJS.sendRequest({ 'url': '/organizations/' + this.organization_id + '/customers/' + customer_id + '/accounting_plan/vat_accounts' }).then((result)=>{
      $('#vat_accounts').html($(result).find('#vat_accounts').html());
      $('.vat_accounts_count').text($(result).find('#vat_accounts').attr('vat_accounts_count'));
    });
  }

  main() {
    let self = this;
    if ($('form#auto_update_accounting_plan #auto-update-accounting-plan').length > 0) {
      this.set_auto_update();
    }
  
    if ($('#import_dialog').length > 0){
      setTimeout(function(){ $('#import_dialog').modal('show');

      $('.close_modal_fec').unbind('click').bind('click',function(e) {
        $(this).attr('disabled', true);
        $(this).html('<img src="/assets/application/bar_loading.gif" alt="chargement..." >');
      });

      $('.mask_verif_account, .part_account').unbind('keyup').bind('keyup',function(e) {
        value = $(this).val();

        regex = /^\d+$/

        if (!regex.exec(value)){
          $(this).val('');
        }
      });

      $('#add_part_account').unbind('click').bind('click',function(e) {
        e.preventDefault()
        $('.counter_part_account').append($('.add_part_account').html());
        self.handle_edit_delete_sub_menu();
      });

    }, 3000);
    }

    this.get_vat_accounts_view();

    this.edit_provider_customer();
    this.edit_general_account();
    this.handle_edit_delete_sub_menu();    
    ApplicationJS.set_checkbox_radio();
  }


  get_edit_view(accounting_id, type){
    let self = this;

    let url = '/organizations/' + self.organization_id + '/customers/' + self.customer_id + '/accounting_plan/edit?accounting_id='+ accounting_id +'&type='+ type

    if (accounting_id == "")
      url = '/organizations/' + self.organization_id + '/customers/' + self.customer_id + '/accounting_plan/new?type='+ type    

    self.applicationJS.sendRequest({ 'url': url }).then((element)=>{      
      self.edit_provider_modal.find('.modal-body').html(element);
      if (type === 'customer') { self.edit_provider_modal.find('.modal-title').text('Éditer un client'); }      
    });
  }

  edit_general_account(){
    let self = this;

    $('.add-general-account-provider, .add-general-account-customer').unbind('click').bind('click',function(e) {
      let kind = "provider";
      let general_account = $(".general-account-provider").val();

      if ($(this).hasClass("add-general-account-customer")){
        kind = "customer";
        general_account = $(".general-account-customer").val();
      }

      if (general_account == "" || general_account === undefined){
        return false;
      }

      let params = {
        "url" : '/organizations/' + self.organization_id + '/customers/' + self.customer_id + '/accounting_plan/insert_general_account',
        "data" : { general_account : general_account, kind: kind },
        "type" : "POST",
        "dataType" : "json"
      }

      self.applicationJS.sendRequest(params).then((element)=>{
        if (element.json_flash.success) { window.location.href = element.url }
      });
    });
  }


  handle_edit_delete_sub_menu(){
    $('.action.edit-delete-menu').unbind('click').bind('click',function(e) {
      e.stopPropagation();

      $('.sub_menu').not(this).each(function(){
        $(this).addClass('hide');
      });

      $(this).parent().find('.sub_menu').removeClass('hide');
    });

    $('.delete_part_account').unbind('click').bind('click',function(e) {
      e.preventDefault();
      $(this).closest('.part-account').remove();
    });

    $('.search-content input#acc_plan_search').unbind('keyup').bind('keyup',function(e) {
      e.preventDefault();
      let _find_text = $(this).val().toLowerCase();

      $('.tab-pane.active .table tr').not('.header').each(function(e) {
        if ($.trim($(this).children().not('.allow-action').text().toLowerCase().indexOf(_find_text)) > -1)
          $(this).show();
        else
          $(this).hide();
      });
    });
  }
}

jQuery(function() {
  let accounting_plan = new AccountingPlan();
  accounting_plan.main();

  AppListenTo('show_accounting_plan', (e)=>{ if (e.detail.response.json_flash.success) { window.location.href = e.detail.response.url } });
});