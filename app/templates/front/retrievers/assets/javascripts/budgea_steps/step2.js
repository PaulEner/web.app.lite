class ConfigurationStep2{
  constructor(mainConfig){
    this.mainConfig = mainConfig;
  }

  /*** COMMON METHODS ***/
    primary_action(){ this.create_connector(); }

    secondary_action(){ if(this.budgea_id <= 0) { this.mainConfig.goto(1); } }
  /*** COMMON METHODS ***/

  init_form(retriever={}){
    this.retriever = retriever || {};

    let ajax_params =   {
                          'url': `/retriever/budgea_step2`,
                          'type': 'POST',
                          'data': { id: (this.retriever['id'] || 0), connector: this.mainConfig.current_connector },
                          'dataType': 'html',
                        };

    this.mainConfig.applicationJS.sendRequest(ajax_params)
                                  .then((e)=>{
                                    this.mainConfig.main_modal.find('#step2').html(e);

                                    this.budgea_id    = this.retriever['budgea_id'] || 0;
                                    this.form         = this.mainConfig.main_modal.find('.step2 #ido_form');
                                    this.contact_form = this.mainConfig.main_modal.find('.step2 #contact_form');
                                    
                                    this.form.find('.field_website').unbind('change')
                                                                    .bind('change', (e)=>{ this.check_field_website(); });
                                    this.check_field_website();

                                    //Go to next step if retriever state is "Waiting_additionnal_info"
                                    if(this.retriever.state == 'waiting_additionnal_info'){
                                      AppLoading('show');
                                      $('.budgea_fields').html('Connexion externe en cours .... Veuillez patientez svp!');
                                      this.create_connector();
                                    }
                                  });
  }

  check_field_website(){
    let self          = this;
    let found_pro     = false;
    this.with_contact = false;
    this.mainConfig.main_modal.find('#step2 .field_website').each(function(e){ if($(this).val() == 'pro'){ found_pro = true } });

    if(found_pro){
      this.with_contact = true;
      this.mainConfig.main_modal.find('#step2 .contact-box').removeClass('hide');
      this.set_contact_values();
    }else{
      this.with_contact = false;
      this.mainConfig.main_modal.find('#step2 .contact-box').addClass('hide');
    }
  }

  set_contact_values(){
    let contact = this.mainConfig.budgeaApi.user_profiles.contact || {}
    this.contact_form.find('#society').val(contact.society || this.contact_form.find('#local_company').val() || '');
    this.contact_form.find('#name').val(contact.name || this.contact_form.find('#local_name').val() || '');
    this.contact_form.find('#first_name').val(contact.first_name || this.contact_form.find('#local_first_name').val() || '');
  }

  valid_fields(){
    this.required_fields = [];
    let is_valid = true;

    let selector = 'input'
    if(this.budgea_id > 0){
      selector = 'input.idocus_field'
    }

    this.form.find(selector).each((e, el)=>{
      if( $(el).attr('required') && ($(el).val() == null || $(el).val() == '' || $(el).val() == 'undefined') ){
        this.required_fields.push($(el).parents('.form-group:last').find('label').text())

        is_valid = false;
      }
    });

    return is_valid;
  }

  create_connector(){
    let self = this;

    if( this.valid_fields() ){
      let oauth_presence = this.form.find('.oauth').val();

      if(oauth_presence){
        let account_id = $('#account_id').val();

        let options = {
                        'ido_capabilities': this.form.find('#ido_capabilities').val(),
                        'ido_connector_id': this.form.find('#ido_connector_id').val(),
                        'ido_custom_name': this.form.find('#ido_custom_name').val(),
                        'ido_connector_name': this.form.find('#ido_connector_name').val(),
                      }

        if(this.budgea_id > 0)
          this.mainConfig.budgeaApi.webauth(account_id, this.budgea_id, false, options);
        else
          this.mainConfig.budgeaApi.webauth(account_id, this.mainConfig.current_connector['id'], true, options);
      }else{
        let all_datas   = this.form.serializeObject();
        let data_remote = JSON.parse(JSON.stringify(all_datas)); //Cloning all_datas

        delete data_remote.ido_connector_id;
        delete data_remote.ido_custom_name;
        delete data_remote.ido_connector_name;
        delete data_remote.ido_journal;

        if(this.budgea_id == 0){
          if( this.mainConfig.current_connector['capabilities'].find(e=>{ return e == 'document' }) )
            Object.assign(data_remote, data_remote, { id_provider: this.form.find('#ido_connector_id').val() })
          else
            Object.assign(data_remote, data_remote, { id_bank: this.form.find('#ido_connector_id').val() })
        }

        let data_local =  all_datas;

        let fetch_connection = ()=>{
          self.mainConfig.budgeaApi.create_or_update_connection(self.budgea_id, data_remote, data_local).then(
            (data)=>{
              if( (data.remote_response.fields != '' && data.remote_response.fields != undefined && data.remote_response.fields != null) && (data.remote_response.additionnal_fields == '' || data.remote_response.additionnal_fields == undefined || data.remote_response.additionnal_fields == null) )
                Object.assign(data.remote_response, data.remote_response, { additionnal_fields: data.remote_response.fields });

              if( data.remote_response.additionnal_fields != '' && data.remote_response.additionnal_fields != undefined && data.remote_response.additionnal_fields != null )
                self.mainConfig.goto(3, data.remote_response);
              else
                self.mainConfig.goto(4, data.remote_response);

              console.log(data.remote_response);
              AppLoading('hide');
            },
            (error)=>{
              AppLoading('hide');
              self.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString());
            }
          );
        }

        if(this.with_contact){
          let data_contact = this.contact_form.serializeObject();
          delete data_contact.local_company;
          delete data_contact.local_name;
          delete data_contact.local_first_name;

          this.mainConfig.budgeaApi.update_contact(data_contact).then(
            (data)=>{ fetch_connection() },
            (error)=> { AppLoading('hide'); self.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()) }
          )
        }else{
          fetch_connection();
        }

      }
    }else{
      AppLoading('hide');
      self.mainConfig.applicationJS.noticeErrorMessageFrom(null, `Veuillez remplir correctement les champs obligatoires! <br/><hr /><strong class='bold'>${this.required_fields.join(', ')}</strong>`)
    }
  }
}