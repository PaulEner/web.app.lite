//=require './events'

class AccountNumberRule{
  constructor(){
    this.applicationJS      = new ApplicationJS();
    this.organization_id    = $('input:hidden[name="organization_id"]').val();
    this.add_new_rule_modal = $('#add-new-rule.modal');
    this.action_locker      = false;
  }


  load_data(search_pattern=false, type='account_number_rules', page=1, per_page=0){
    if(this.action_locker) { return false; }

    this.action_locker = true;
    let params = [];

    params.push(`page=${page}`);

    if (per_page > 0) { params.push(`per_page=${ per_page }`); }

    let search_text = '';

    if (search_pattern) {
      search_text = $('.search-content #search_input').val();
      if(search_text && search_text != ''){ params.push(`account_number_rule_contains[text]=${encodeURIComponent(search_text)}`); }
    }

    let ajax_params =   {
                          'url': `/organizations/${this.organization_id}/account_number_rules?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((html)=>{
                        if (search_pattern) {
                          $('.bank-affectation').html($(html).find('.bank-affectation').html());
                          $('.search-content #search_input').val(search_text);
                        }
                        this.action_locker = false;
                      })
                      .catch(()=>{ this.action_locker = false; });
  }


  validate_account_number_rule_fields(){
    let required_fields_count = 0;

    $('.required_field').each(function() {
      if ($(this).val() !== '') {
        required_fields_count += 1;
      }
    });

    if (required_fields_count >= 6) {
      this.add_new_rule_modal.find('.validate-account-number-rule').removeAttr('disabled');
      bind_all_events_account_number_rules();
    }
  }

  create_or_update_account_number_rules(url){
    this.applicationJS.sendRequest({ 'url': url }).catch((error)=> { 
      console.log(error)
    }).then((element)=>{
      let from        = '#account_number_rule.new';
      let modal_title = 'Créer une nouvelle règle';
      let modal_btn_validate = 'Ajouter';

      if (url.indexOf("/edit") >= 0) {
        from        = '#account_number_rule.edit';
        modal_title = 'Éditer une règle';
        modal_btn_validate = 'Éditer';
      }
      else if (url.indexOf("template=") >= 0) {
        modal_title = 'Dupliquer cette règle';
        modal_btn_validate = 'Dupliquer';
      }

      this.add_new_rule_modal.find('.modal-body').html($(element).find(from).html());
      this.add_new_rule_modal.find('.modal-title').text(modal_title);
      this.add_new_rule_modal.find('.validate-account-number-rule').text(modal_btn_validate);
      this.add_new_rule_modal.find('.validate-account-number-rule').attr('disabled', true);

      this.add_new_rule_modal.modal('show');

      this.validate_account_number_rule_fields();
    });
  }

  skip_accounting_plan(url, account_list, account_validation){
    this.applicationJS.sendRequest({
        'url': url,
        'data': { account_list: account_list, account_validation: account_validation },
        'type': 'POST',
        'dataType': 'json',
      }).then((e)=>{ /*this.applicationJS.noticeSuccessMessageFrom(null, e.message);*/ });
  }
}

jQuery(function() {

  let account_number_rule = new AccountNumberRule();

  AppListenTo('create_or_update_account_number_rules', (e)=>{ account_number_rule.create_or_update_account_number_rules(e.detail.url); });
  AppListenTo('validate_account_number_rule_fields', (e)=>{ account_number_rule.validate_account_number_rule_fields(); });

  AppListenTo('skip_accounting_plan', (e)=>{ account_number_rule.skip_accounting_plan(e.detail.url, e.detail.account_list, e.detail.account_validation); });

  
  AppListenTo('account_number_rule_contains_search_text', (e)=>{ account_number_rule.load_data(true); });

  AppListenTo('window.change-per-page.account_number_rules', (e)=>{ account_number_rule.load_data(true, e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.account_number_rules', (e)=>{ account_number_rule.load_data(true, e.detail.name, e.detail.page, e.detail.per_page); });
  AppListenTo('reload_page', (e)=>{ if (e.detail.response.json_flash.success) { if ($('.search-content #search_input').val() != "")
                                                                                  account_number_rule.load_data(true);
                                                                                else
                                                                                  window.location.reload(true);
                                                                              } });
});