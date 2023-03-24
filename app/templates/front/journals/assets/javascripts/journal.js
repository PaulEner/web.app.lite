class Journal{
  constructor(){
    this.applicationJS              = new ApplicationJS;
    this.organization_id            = $('input:hidden[name="organization_id"]').val();
    this.journal_form_modal         = $('#journal-form.modal');
    this.default_vat_accounts_label = 'Compte de TVA par défaut attribué au journal comptable iDocus';
    this.action_locker              = false;
  }

  set_carousel_content_on_slide(){
    let self = this;
    const set_default_carousel_slide = () => {
      self.journal_form_modal.find('.previous').addClass('hide');
      self.journal_form_modal.find('.validate').addClass('hide');
      self.journal_form_modal.find('.next').removeClass('hide');
      self.journal_form_modal.find('.next').text('Suivant');

      self.select_entry_type();
      self.required_fields();
      self.validate_first_slide_form();
    };

    set_default_carousel_slide();
    self.update_form();

    $('#carousel-journal-form').on('slide.bs.carousel', function (event) {
      switch (event.to) {
        case 0:
          // do something for .journal-first-step-form
          set_default_carousel_slide();

          break;
        case 1:
          // do something for .knowings-configuration .pre-assignment-attributes ...
          self.journal_form_modal.find('.previous-next-controls .next').removeAttr('disabled');
          self.journal_form_modal.find('.previous').removeClass('hide');
          self.journal_form_modal.find('.validate').addClass('hide');
          self.journal_form_modal.find('.next').removeClass('hide');
          self.journal_form_modal.find('.next').text('Suivant');

          $('.add_vat_account_field').unbind('click.more_vats').bind('click.more_vats', function(e) {
            e.stopPropagation();

            self.add_vat_account_field('', '', '');

            self.remove_vat_account_field();
          });

          self.remove_vat_account_field();
          $('input[name="account_book_type[account_type]"]').unbind('click.show_type').bind('click.show_type', function(e) {
            if ($(this).is(":checked")){
              $(this).attr('checked', 'checked');
            }

            self.update_form();
          });

          if (parseInt($("#account_book_type_entry_type").val()) === 0){
            $('.no_entry_selected').html($('.carousel_item_last_slide').html());
            self.journal_form_modal.find('.next').addClass('hide');
            self.journal_form_modal.find('.validate').removeClass('hide');

            self.submit_journal_form(true);
          }

          break;
        case 2:
          // do something for .ido-instruction, .default-options
          self.journal_form_modal.find('.previous-next-controls .next').removeAttr('disabled');
          self.serialize_vat_accounts('#journal-form.modal form .account_book_type_vat_accounts');
          self.journal_form_modal.find('.next').addClass('hide');
          self.journal_form_modal.find('.validate').removeClass('hide');
          self.submit_journal_form();

          break;
        default:
          //Default
      }
    });
  }


  submit_journal_form(no_entry_selected=false){
    let self = this;
    $('.previous-next-controls .validate').unbind('click.submit_journal').bind('click.submit_journal', function(e) {
      e.stopPropagation();
      AppLoading('show');

      if (no_entry_selected) {
        $('.carousel_item_last_slide').remove();
      }

      let applicationJS = new ApplicationJS();
      let data = $('form#new-journal-form, form#edit-journal-form').serialize();

      let ajax_params = {
                          url: $('form#new-journal-form, form#edit-journal-form').attr('action'),
                          type: $('form#new-journal-form, form#edit-journal-form').attr('method'),
                          data: data,
                          dataType: 'json'
                        }

      applicationJS.sendRequest(ajax_params).then((e)=>{
        AppLoading('hide');

        if(!e.json_flash.error){
          setTimeout(()=>{ window.location.href = e.response_url }, 2000);
        }
      });
    });
  }

  select_entry_type(){
    let self = this;
    $('#account_book_type_entry_type').unbind('change').bind('change', function(e) {
      e.stopPropagation();
      self.update_form();
    });
  }

  add_vat_account_field(rate, vat_account, conterpart_account){
    let cloned_field = '.account_book_type_vat_accounts_field';

    $('.pre-assignment-attributes #account_book_type_with_default_vat_accounts').append($(cloned_field).html());

    bind_vat_accounts_events();
  }

  remove_vat_account_field(){
    let self = this;
    $('.remove_vat_accounts_field').unbind('click').bind('click', function(e) {
      e.stopPropagation();

      $('[data-toggle="tooltip"]').tooltip("hide");
      $(this).closest('.account_book_type_vat_accounts').remove();
    });
  }

  serialize_vat_accounts(form){
    let self = this;
    let vat_accounts = {};

    $(form).each(function() {
      let vat_account                     = $(this);
      let label                           = vat_account.find('input[type="text"].vat_accounts_label, select.vat_accounts_label').val();
      let vat_accounts_field              = vat_account.find('input[type="text"].vat_accounts').val();
      let conterpart_vat_accounts_field   = vat_account.find('input[type="text"].vat_accounts_conterpart').val();
      let vat_account_exonorated_field    = vat_account.find('input[type="text"].vat_account_exonorated').val();

      if ((label === self.default_vat_accounts_label) || /Compte de TVA par défaut/.test(label) ){
        label = '0';
      }

      if (!(/undefined/.test(vat_accounts_field) || /undefined/.test(label) || label === null || label === undefined || label === '' || vat_accounts_field === null || vat_accounts_field === '' || vat_accounts_field === undefined)){
        vat_accounts[label] = [vat_accounts_field, conterpart_vat_accounts_field];
      }

      if(label == -1){
        vat_accounts['-1'] = ['', conterpart_vat_accounts_field];
      }
    });

    vat_accounts = JSON.stringify(vat_accounts);
    $('input[type=hidden]#account-book-type-vat-accounts-hidden').attr('value', vat_accounts);
  }

  required_fields(){
    let self = this;
    let required_fields_count = 0;

    $('input[type="text"].required_field').each(function() {
      if ($(this).val() !== '') {
        required_fields_count += 1;
      }
    });

    if (required_fields_count >= 2) { self.journal_form_modal.find('.previous-next-controls .next').removeAttr('disabled'); }
  }

  validate_first_slide_form(){
    let self = this;

    $('input[type="text"].required_field').unbind('keypress.journal_form_field input.journal_form_field')
    .bind('keypress.journal_form_field input.journal_form_field', function(e) { self.required_fields(); });
  }

  update_form(){
    if (parseInt($("#account_book_type_entry_type").val()) > 1 && parseInt($("#account_book_type_entry_type").val()) < 4){
      this.toggle_required_field('enable');
      $('.pre-assignment-attributes').removeClass('hide');
      $('.no_entry_selected').addClass('hide');
    }
    else if( ['0', '1', '4'].find((e)=>{ return parseInt(e) === parseInt( $("#account_book_type_entry_type").val() ) }) ){
      $('.pre-assignment-attributes').addClass('hide');
      if( parseInt( $("#account_book_type_entry_type").val() ) > 0 ){
        let label = $("#account_book_type_entry_type option:selected").text()
        $('.no_entry_selected').text(`Type de pré-saisie << ${label} >>`);
      }

      $('.no_entry_selected').removeClass('hide');
    }
    else{
      this.toggle_required_field('disable');
      $('.pre-assignment-attributes').addClass('hide');
      $('.no_entry_selected').addClass('hide');
    }
  }

  edit_analytics(id, customer_id, code){
    $('#comptaAnalysisEdition.modal').modal('show');
    this.analytic_journal_id = id;
    this.analytic_customer_id = customer_id;

    AppEmit('compta_analytics.main_loading', { code: code, pattern: id, type: 'journal', is_used: true });
  }

  update_analytics(data){
    let params =  {
                    url: `/organizations/${this.organization_id}/customers/${this.analytic_customer_id}/journals/update_analytics`,
                    type: 'POST',
                    data: { id: this.analytic_journal_id, analysis: data },
                    dataType: 'json'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{ $('#comptaAnalysisEdition.modal').modal('hide'); });
  }

  load_journals(type='journals', page=1, per_page=0){
    if(this.action_locker) { return false; }

    this.action_locker = true;
    let params = [];

    params.push(`page=${page}`);

    if (per_page > 0) { params.push(`per_page=${ per_page }`); }

    let ajax_params =   {
                          'url': `/organizations/${this.organization_id}/journals?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((html)=>{
                        this.action_locker = false;
                        this.main();
                      })
                      .catch(()=>{ this.action_locker = false; });
  }

  main() {
    this.new_edit_account_book_type_view()
    ApplicationJS.set_checkbox_radio();
    this.select_entry_type();
    this.set_carousel_content_on_slide();
  }

  new_edit_account_book_type_view(){
    let self = this;
   
    $('.new_edit_account_book_type').unbind('click.new_edit_jo').bind('click.new_edit_jo', function(e) {
      e.stopPropagation();

      const url = $(this).attr('link');

      self.applicationJS.sendRequest({ 'url': url }).then((element)=>{
        let from        = '#journal.new';
        let modal_title = 'Nouveau journal comptable';

        if (url.indexOf("edit") >= 0) {
          from        = '#journal.edit';
          modal_title = 'Édition de journal comptable';
        }

        self.journal_form_modal.find('.modal-body').html($(element).find(from).html());
        self.journal_form_modal.find('.modal-title').text(modal_title);
        self.journal_form_modal.find('.previous-next-controls .next').attr('disabled', 'disabled');
        self.journal_form_modal.modal('show');

        ApplicationJS.set_checkbox_radio();
        self.set_carousel_content_on_slide();
      });
    });
  }

  toggle_required_field(type){
    if (type === 'enable'){
      $('#new_account_book_type .can_be_required').attr('required', 'required');
    }
    else{
      $('#new_account_book_type .can_be_required').removeAttr('required');
    }
  }
}