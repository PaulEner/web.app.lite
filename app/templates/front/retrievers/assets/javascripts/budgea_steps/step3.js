class ConfigurationStep3{
  constructor(mainConfig){
    this.mainConfig = mainConfig;
  }

  /*** COMMON METHODS ***/
    primary_action(){ this.submit_additionnal_infos(); }

    secondary_action(){}
  /*** COMMON METHODS ***/

  init_form(params){
    this.connector = params;

    let ajax_params =   {
                          'url': `/retriever/budgea_step3`,
                          'type': 'POST',
                          'data': { connector: params },
                          'dataType': 'html',
                        };

    this.mainConfig.applicationJS.sendRequest(ajax_params)
                                  .then((e)=>{
                                    this.mainConfig.main_modal.find('#step3').html(e);

                                    this.form = this.mainConfig.main_modal.find('form#additionnal-info');
                                  })
  }

  valid_fields(){
    let is_valid = true;
    this.form.find('input').each((e, el)=>{
      if( $(el).attr('required') && ($(el).val() == null || $(el).val() == '' || $(el).val() == 'undefined') ){
        is_valid = false;
      }
    });

    return is_valid;
  }

  submit_additionnal_infos(){
    let self = this;
    if(this.valid_fields()){
      let data_local  = { budgea_id: this.connector['id'] };
      let data_remote = this.form.serializeObject();

      this.mainConfig.budgeaApi.update_additionnal_infos(this.connector['id'], data_remote, data_local)
                                .then((e)=>{ self.mainConfig.goto(4, this.connector); })
                                .catch((error)=>{ self.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()); })
    }else{
      self.mainConfig.applicationJS.noticeErrorMessageFrom(null, 'Veuillez remplir correctement les champs obligatoires!');
    }
  }
}