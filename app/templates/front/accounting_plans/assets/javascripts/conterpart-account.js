class ConterpartAccount {
  constructor(){
    this.appJS            = new ApplicationJS;
    this.modal            = $('.modal#conterpart_accounts');
    this.type             = 'provider';
  }

  init_form(type){
    let self = this;
    this.type = type;
    let url   = $('input.conterpart-show').val();
    let param = `?kind=${self.type}`;

    let aj_params =   {
                        url: url + param,
                        type: 'GET',
                        dataType: 'html',
                      }
    self.appJS.sendRequest(aj_params).then((res)=>{
      self.modal.find('.modal-body .conterpart-body-form').html(res);

      self.account_selector = $('select.account-item-selector');
      self.get_accounts_list();
    })
  }

  hide_additionnal_view(){
    $('#conterpart-accounts-body .additionnal-fields').addClass('hide');
    $('#conterpart-accounts-body .select-from-customer').addClass('hide');
  }

  delete_account(ids = []){
    if(ids.length < 0){ return false }

    if(confirm('Etes vous sûr de vouloir supprimer les catégories séléctionnées?')){
      let self  = this;
      let url   = $('input.conterpart-deletion').val();
      let param = `?ids=${ids.join(',')}`;

      let aj_params =   {
                          url: url + param,
                          type: 'DELETE',
                          dataType: 'json',
                        }
      self.appJS.sendRequest(aj_params).then((res)=>{
        AppEmit('ca.refresh_accounts_list');
      })
    }
  }

  get_accounts_list(){
    let self  = this;
    this.hide_additionnal_view();

    let url  = $('input.conterpart-accounts-list').val();
    url      = url.replace('/type', `/${this.type}`);

    let aj_params =   {
                        url: url,
                        type: 'GET',
                        dataType: 'json',
                      }
    self.appJS.sendRequest(aj_params).then((res)=>{
      let selector_container = $('.account-item-selector-container');
      let selector = this.account_selector.clone();
      selector.html('');

      res.accounts.forEach((account)=>{
        selector.append(`<option value='${account.id}'>${account.name} - ${account.number}</option>`);
      });

      // selector.addClass('chosen-list');
      // selector.unbind('change.account-selection').bind('change.account-selection', function(e){ self.init_form($(this).val()) });

      selector_container.html(selector);
    });
  }

  fetch_account(id, action_kind){
    let self = this;
    let url   = $('input.conterpart-edition').val();
    let param = `?kind=${this.type}&action_kind=${action_kind}`;
    if(id > 0)
      param = param + `&id=${id}`;

    this.hide_additionnal_view();
    let aj_params =   {
                        url: url + param,
                        type: 'GET',
                        dataType: 'html',
                      }
    self.appJS.sendRequest(aj_params).then((res)=>{
      self.modal.find('.modal-body .additionnal-fields').html(res);
      $('#conterpart-accounts-body .additionnal-fields').removeClass('hide');
    })
  }

  add_from_customer(customer_id = 0){
    if(customer_id > 0)
    {
      let self = this;
      let url   = $('input.conterpart-add-from-customer').val();
      let param = `?kind=${self.type}`;
      param = param + `&selected_id=${customer_id}`

      let aj_params =   {
                          url: url + param,
                          type: 'GET',
                          dataType: 'json',
                        }
      self.appJS.sendRequest(aj_params).then((res)=>{
        let selector_container = $('.select-conterpart-customer-container');
        let selector = selector_container.find('.select-conterpart-customer').clone();
        selector.html('');

        if(res.accounts.length > 0)
            $('.select-from-customer .select-from-customer-button').removeClass('hide');

        res.accounts.forEach((account)=>{
          selector.append(`<option value='${account.id}'>${account.name} - ${account.number}</option>`);
        });

        // selector.addClass('chosen-list');
        // selector.unbind('change.account-selection').bind('change.account-selection', function(e){ self.init_form($(this).val()) });

        selector_container.html(selector);
      });
    }
  }
}

jQuery(function() {
  let conterpart_account = new ConterpartAccount();

  AppListenTo('ca.edit-conterpart-account', (e)=>{
    conterpart_account.fetch_account(0, 'conterpart_account');
  });

  AppListenTo('ca.show-customers-selection', (e)=>{
    conterpart_account.hide_additionnal_view();
    $('.select-from-customer .select-from-customer-button').addClass('hide');
    $('#conterpart-accounts-body .select-from-customer').removeClass('hide');
  });

  AppListenTo('ca.add-from-customer', (e)=>{
    let customer_id = e.detail.obj.val();
    conterpart_account.add_from_customer(customer_id);
  });

  AppListenTo('ca.refresh_accounts_list', (e)=>{
    let type = $('.modal#conterpart_accounts').find('input#conterpart-kind').val();
    conterpart_account.get_accounts_list();
  });

  AppListenTo('ca.delete-conterpart-account', (e)=>{
    // let kind = $('.modal#conterpart_accounts').find('input#conterpart-kind').val();
    conterpart_account.delete_account($('select.account-item-selector').val());
  });

  AppListenTo('ca.select-conterpart', (e)=>{
    let elem  = e.detail.obj;
    let value = elem.val();

    conterpart_account.fetch_account(parseInt(value[0]), 'conterpart_account');
  });

  AppListenTo('ca.select-third-part', (e)=>{
    let elem  = e.detail.obj;
    let value = elem.val();

    conterpart_account.fetch_account(parseInt(value[0]), 'third_part');
  });

  AppListenTo('window.application_auto_rebind', (e)=>{
    $('button.manage-conterpart-accounts').unbind('click.manage-conterpart-accounts').bind('click.manage-conterpart-accounts', function(e){
      let type = ($(this).hasClass('customer'))? 'customer' : 'provider';
      $('.modal#conterpart_accounts').modal('show');
      $('.modal#conterpart_accounts').find('input#conterpart-kind').val(type);
      conterpart_account.init_form(type);
    });
  });
});