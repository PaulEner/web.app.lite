//= require './events'

class Customer{

  constructor(){
    this.applicationJS         = new ApplicationJS;
    this.create_customer_modal = $('#create-customer.modal');
    this.filter_customer_modal = $('#customers-filter.modal');
    this.new_edit_order_modal = $('#new_edit_order.modal');
    this.select_multiple       = $('#select_for_orders.modal');
    this.account_close_confirm_modal = $('#account_close_confirm.modal');
    this.file_sending_kits_edit = $('#file_sending_kits_edit.modal');
    this.account_book_type_view = $('#account_book_type_modal.modal');
    this.organization_id       = $('input:hidden[name="organization_id"]').val();
    this.action_locker = false;
  }

  main(){
    this.add_customer();
    this.filter_customer();
    this.show_ibiza_customer();
    this.show_exact_online_customer();
    this.show_my_unisoft_customer();
    this.show_sage_gec_customer();

    if ($('.packages_list').length > 0 ) { this.subscription_event(); }
    if ($('#journals select#copy-journals-into-customer').length > 0) { searchable_option_copy_journals_list(); }

    ApplicationJS.set_checkbox_radio(this);
  }

  subscription_event(){
    let self = this;

    self.show_subscription_option();
    self.update_price();
    self.check_commitment_pending();
    ApplicationJS.set_checkbox_radio(this);
  }

  check_commitment_pending(){
    if( $('.commitment_pending').length > 0 ){
      $('.main-option').attr('disabled', 'disabled');
      $('.main-option.commitment_pending').each(function(e){
        if($(this).is(':checked')){
          ($(this).removeAttr('disabled'));
        }
      });
    }
  }

  update_price() {    
    let price = 0;
    let number_of_journals = $('.package.active .number_of_journals');

    price += $('.package.active .main-option').data('price') || 0;

    $('.package.active .option_checkbox:checked').each(function() {      
      price += $(this).data('price');
    });
    
    if (parseInt(number_of_journals.val()) > 5) {
      price += number_of_journals.data('price') * (parseInt(number_of_journals.val()) - 5);
    }

    if ($('.package.active').data('name') == 'ido_classic')
      price -= 9
    
    $('.total_price').html(price + ",00€ HT");
  }

  show_subscription_option(){
    let self = this;

    $('.packages_list .main-option').unbind('click').bind('click', function(e){
      e.stopPropagation();

      $('.options').addClass('hide');
      $('.package').removeClass('active');
      $(this).closest('.package').find('.options').removeClass('hide');
      $(this).closest('.package').addClass('active');

      self.update_price();
    });

    $('.option_checkbox').unbind('click').bind('click', function(e){
      e.stopPropagation();
      
      self.update_price();
    });

    $('.number_of_journals').unbind('change').bind('change', function(e){
      e.stopPropagation();
      
      self.update_price();
    });    
  }

  add_customer(){
    var self = this;
    $('.new-customer').unbind('click.open_new_customer').bind('click.open_new_customer',function(e) {
      e.stopPropagation();
      self.get_customer_first_step_form();
    });
  }


  set_customer_carousel_on_slide(){
    let self = this;
    self.show_ibiza_customer();

    ApplicationJS.set_checkbox_radio(self);

    $('#carousel_customer_form').on('slide.bs.carousel', function (event) {
      switch (event.to) {
        case 0:
          // customer basic form

          self.create_customer_modal.find('.modal-title').text('Créer un nouveau client');
          self.create_customer_modal.find('.next').removeClass('hide');
          self.create_customer_modal.find('.previous').addClass('hide');
          self.create_customer_modal.find('.submit_customer').addClass('hide');

          self.show_ibiza_customer();

          ApplicationJS.set_checkbox_radio(self);

          break;
        case 1:
          // package subscription form

          self.create_customer_modal.find('.modal-title').text('Sélectionner un abonnement');
          self.create_customer_modal.find('.previous').removeClass('hide');
          self.create_customer_modal.find('.next').addClass('hide');
          self.create_customer_modal.find('.submit_customer').removeClass('hide');

          if ($('#personalize_subscription_package_form').length > 0 ) {
            // self.update_price();
            self.check_input_number();
            self.show_subscription_option();
            ApplicationJS.set_checkbox_radio(self);
          }

          bind_customer_events();

          ApplicationJS.set_checkbox_radio(self);
          break;
        default:
          //Default
      }
    });
  }


  show_ibiza_customer(){
    let ibiza_softwares_section = $('#create-customer-form-data .softwares-section');
    const show_ibiza_list = (selector) => {
      if ($(selector).is(':checked')) {
        ibiza_softwares_section.css('display', 'block');
        ibiza_softwares_section.attr('load', 'YES');
      } else {
        ibiza_softwares_section.css('display', 'none');
        ibiza_softwares_section.attr('load', 'NO');
      }

      if ( (ibiza_softwares_section.attr('load') === 'YES') && $('#create-customer-form-data .softwares-section .ibiza-customers-list').length > 0) {
        get_ibiza_customers_list($('#create-customer-form-data .softwares-section .ibiza-customers-list'));
      }
    };

    const get_ibiza_customers_list = (selector) => {
      AppLoading('show');
      this.applicationJS.sendRequest({
        'url': selector.data('users-list-url'),
        'type': 'GET',
        'dataType': 'json'
      }).then((result)=>{
        if(result['message'] === undefined || result['message'] === null)
        {
          let original_value = selector.data('original-value') || '';
          for (let iterator = 0; iterator < result.length; iterator++) {
            let _element = result[iterator];
            let option_html = '';
            if (original_value.length > 0 && original_value === _element['id']) {
              option_html = '<option value="' + _element['id'] + '" selected="selected">' + _element['name'] + '</option>';
            } else {
              option_html = '<option value="' + _element['id'] + '">' + _element['name'] + '</option>';
            }
            selector.append(option_html);
          }

          AppLoading('hide');
          selector.chosen({
            search_contains: true,
            no_results_text: 'Aucun résultat correspondant à'
          });
        }
      });
    }

    const ibiza_checkbox_selector = $('#create-customer-form-data input[type="checkbox"].check-ibiza');

    show_ibiza_list(ibiza_checkbox_selector);

    ibiza_checkbox_selector.change(function() {
      show_ibiza_list(this);
    });

    if ($('#edit_ibiza_form').length > 0 ) {
      get_ibiza_customers_list($('#user_ibiza_attributes_ibiza_id'));

      let update_ibiza_btn = $('button[type=button].update_ibiza_organization_users');
      if (update_ibiza_btn.length > 0){
        update_ibiza_btn.removeAttr('disabled');
      }
    }
  }

  show_exact_online_customer(){
    if ($('#exact-online-form').length > 0 ) {
      $('.check-api-value').change(function() {        
        if ($('#user_exact_online_attributes_client_id').val() != '' && $('#user_exact_online_attributes_client_secret').val() != ''){
          $('button[type=button].exact_online_validation').removeAttr('disabled');
        }
        else{
          $('button[type=button].exact_online_validation').attr('disabled', true);
        }
      });
    }
  }

  show_my_unisoft_customer(){
    if ($('#my-unisoft-form').length > 0 ) {
      $('#society-id').change(function() {        
        if ($(this).val() != ''){
          $('button[type=button].my_unisoft_validation').removeAttr('disabled');
        }
        else{
          $('button[type=button].my_unisoft_validation').attr('disabled', true);
        }
      });
    }
  }

  show_sage_gec_customer(){
    if ($('#sage-gec-form').length > 0 ) {
      $('.key-sage-gec').change(function() {        
        if ($(this).val() != ''){
          $('button[type=button].sage_gec_validation').removeAttr('disabled');
        }
        else{
          $('button[type=button].sage_gec_validation').attr('disabled', true);
        }
      });
    }
  }

  show_acd_customer(){
    if ($('#acd-form').length > 0 ) {
      $('.key-acd').change(function() {        
        if ($(this).val() != ''){
          $('button[type=button].acd_validation').removeAttr('disabled');
        }
        else{
          $('button[type=button].acd_validation').attr('disabled', true);
        }
      });
    }
  }


  get_customer_first_step_form(){
    this.applicationJS.sendRequest({ 'url': '/organizations/' + this.organization_id + '/customers/new' }).then((element)=>{
      this.create_customer_modal.find('.modal-body').html($(element).find('.customer-form-content').html());
      this.create_customer_modal.find('.normal-form-action').remove();
      
      $('select#select-group-list').removeClass('form-control');
      $('select#select-group-list').asMultiSelect({
        'noneText': 'Selectionner un/des groupe(s)',
        'allText': 'Tous séléctionnés'
      });
      
      this.create_customer_modal.modal('show');

      this.set_customer_carousel_on_slide();

      this.subscription_event();
    });
  }


  filter_customer(){
    let self = this;
    $('.customer-filter').unbind('click').bind('click',function(e) {
      e.stopPropagation();

      $('#customers-filter').modal('show');

      ApplicationJS.set_checkbox_radio();
    });
  }


  close_or_reopen_confirm_view(url, target_action){
    this.applicationJS.sendRequest({ 'url': url }).then((elements)=>{
      this.account_close_confirm_modal.find('.close_reopen_confirm_content').html($(elements).find('.close_or_reopen').html());

      if (target_action === 'close') {
        this.account_close_confirm_modal.find('.modal-title').text('Clôturer le dossier');
      }

      else if (target_action === 'reopen') {
        const text = $(elements).find('.close_or_reopen').attr('text');
        this.account_close_confirm_modal.find('.modal-title').text(text);
        this.account_close_confirm_modal.find('.close_or_reopen_confirm').attr('link', $(elements).find('.close_or_reopen').attr('link'));
        this.account_close_confirm_modal.find('.close_or_reopen_confirm').text(text);
        this.account_close_confirm_modal.find('.close_or_reopen_confirm').removeClass('close');
      }

      this.account_close_confirm_modal.modal('show');

      this.rebind_customer_all_events();
    });
  }

  close_or_reopen_confirm(url, data={}){
    let params = {};
    let redirect_to = `/organizations/${(url.split('organizations/')[1].split('/customers')[0] || this.organization_id)}/customers`;

    if (url.indexOf("reopen_account") >= 0) {
      params = {'url': url, 'type': 'POST', data: { _method: 'PATCH' }, 'dataType': 'html'};
      let raw_customer_ids = url.split('/');
      let  customer_id = raw_customer_ids[raw_customer_ids.length - 2]
      redirect_to = `${redirect_to}/${customer_id}`;
    }
    else if (url.indexOf("close_account") >= 0) {
      params = {'url': url, 'data': data, 'type': 'POST', 'dataType': 'html'};
    }

    this.applicationJS.sendRequest(params).then((response)=>{
      this.account_close_confirm_modal.modal('hide');

      window.location.replace(redirect_to);
    }).catch((response)=>{

    });
  }

  validate_first_slide_form(){
    let required_fields_count = 0;

    $('input.required_field').each(function() {
      if ($(this).val() !== '') {
        required_fields_count += 1;
      }
    });

    if (required_fields_count >= 3) { this.create_customer_modal.find('.carousel-item-action .next').removeAttr('disabled'); }
  }


   load_data(search_pattern=false, type='customers', page=1, per_page=0){
    if(this.action_locker) { return false; }

    this.action_locker = true;
    let params = [];

    let search_text = '';

    if (search_pattern) {
      search_text = $(`.search-content input[name='user_contains[text]']#search_input`).val();
      if(search_text && search_text != ''){ params.push(`user_contains[text]=${encodeURIComponent(search_text)}`); }
    }

    params.push(`page=${page}`);

    if (per_page > 0) { params.push(`per_page=${ per_page }`); }

    let ajax_params =   {
                          'url': `/organizations/${this.organization_id}/${type}?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
    .then((response)=>{
      $('.list-customers').html($(response).find('.list-customers').html());

      $(`.search-content input[name='user_contains[text]']#search_input`).val(search_text);

      this.action_locker = false;
 
      this.rebind_customer_all_events();
    })
    .catch(()=>{ this.action_locker = false; });
  }

  rebind_customer_all_events(){
    this.main();
    bind_customer_events();
    ApplicationJS.set_checkbox_radio();
  }
}


jQuery(function () {
  var customer = new Customer();

  AppListenTo('validate_first_slide_form', (e)=>{ customer.validate_first_slide_form(); });

  AppListenTo('search_text', (e)=>{ customer.load_data(true); });

  AppListenTo('close_or_reopen_confirm_view', (e)=>{ customer.close_or_reopen_confirm_view(e.detail.url, e.detail.target); });
  AppListenTo('close_or_reopen_confirm', (e)=>{ customer.close_or_reopen_confirm(e.detail.url, e.detail.data); });

  AppListenTo('bind_api_user_events', (e)=>{ customer.rebind_customer_all_events(); });
  AppListenTo('reload_subscription_event', (e)=>{ customer.subscription_event() });
  
  customer.main();

  AppListenTo('show_new_customer', (e)=>{ if (e.detail.response.json_flash.success) { window.location.href = e.detail.response.url } });  
});