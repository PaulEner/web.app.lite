//***** THIS CLASS IS USED BY EVERY BANK SELECTION PAGES ****//
//***1- RETRIEVER CREATION AND EDION PAGE
//***2- BANK PARAMETERS (SELECTION) PAGE

class ConfigurationStep4{
  constructor(mainConfig, target_html=null, minimal_view = false){
    this.mainConfig = mainConfig;

    this.minimal_view = minimal_view;
    this.target_html  = target_html || $('.not_found_object_jquery'); //this undefined object is needed to avoid jquery bugs

    this.connector_id     = 0;
    this.remote_accounts  = [];
    this.local_accounts   = []; // the result is a collection of api_ids
  }

  /*** COMMON METHODS ***/
    primary_action(){ this.submit_selected_accounts(); }

    secondary_action(){ this.configuration_finished(); }
  /*** COMMON METHODS ***/

  init_form(params){
    this.connector_id   = params['id'];

    this.fetch_accounts().then((e)=>{ this.show() }); 
  }

  show(){
    let ajax_params =   {
                          'url': `/retriever/budgea_step4`,
                          'type': 'POST',
                          'data': { local_accounts: this.local_accounts, remote_accounts: this.remote_accounts, budgea_id: this.connector_id },
                          'dataType': 'html',
                        };

    this.mainConfig.applicationJS.sendRequest(ajax_params)
                                  .then((e)=>{
                                    if(this.minimal_view){
                                      this.target_html.html($(e).find('.bank_accounts').html());
                                    }else{
                                      this.target_html.html(e);
                                    }
                                  });
  }

  fetch_accounts(){
    return new Promise((resolve, reject)=>{
      this.mainConfig.budgeaApi.get_accounts_of(this.connector_id)
                                .then((data)=>{
                                  this.remote_accounts = data.remote_accounts;
                                  this.local_accounts  = data.my_accounts; // the result is a collection of api_ids
                                  resolve();
                                })
                                .catch((error)=>{ this.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()) });
    });
  }

  submit_selected_accounts(callback=null){
    if(confirm('Etes vous sûr?')){
      let self = this
      let data = this.target_html.find(`form#account-selection`).serializeObject();

      let selected_accounts  = this.remote_accounts.filter((account)=>{ return data['bank_accounts'].find(d=>{ return d == account['id'] }); });

      if(selected_accounts.length > 0){
        this.mainConfig.budgeaApi.update_my_accounts(selected_accounts)
                                  .then(()=>{ if(callback){ callback(); }else{ this.configuration_finished(); } })
                                  .catch(error=>{ this.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()); });
      }else{
        if(callback){ callback(); }else{ this.configuration_finished(); }
      }
    }
  }

  configuration_finished(){
    try{ this.mainConfig.main_modal.modal('hide'); }catch(e){}
    this.mainConfig.applicationJS.sendRequest({ url: '/retrievers', type: 'GET', target: '.retrievers-list' }).then((e)=>{
      this.mainConfig.applicationJS.noticeSuccessMessageFrom(null, 'Configuration automate terminée. Votre automate sera mis à jour dans quelques minutes ...');
    });
  }
}