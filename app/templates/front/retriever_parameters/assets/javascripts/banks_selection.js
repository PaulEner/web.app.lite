class RPBanksSelection{
  constructor(main){
    this.main = main;
    this.budgeaApi = new BudgeaApi();

    this.filter_form      = $('.modal#filter-banks-selection form#filter-banks-selection-form');
    this.connector_id     = 0;
    this.remote_accounts  = [];
    this.local_accounts   = []; // the result is a collection of api_ids
  }

  init_form(budgea_id){
    this.connector_id   = budgea_id;

    this.fetch_accounts().then((e)=>{ this.show() });
  }

  show(){
    let ajax_params =   {
                          'url': `/retriever/budgea_step4`,
                          'type': 'POST',
                          'data': { local_accounts: this.local_accounts, remote_accounts: this.remote_accounts },
                          'dataType': 'html',
                        };

    this.main.applicationJS.sendRequest(ajax_params)
                            .then((e)=>{
                              this.mainConfig.main_modal.find('#bank_selection').html(e);
                            });
  }

  fetch_accounts(){
    return new Promise((resolve, reject)=>{
      this.budgeaApi.get_accounts_of(this.connector_id)
                    .then((data)=>{
                      this.remote_accounts = data.remote_accounts;
                      this.local_accounts  = data.my_accounts; // the result is a collection of api_ids
                      resolve();
                    })
                    .catch((error)=>{ this.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()) });
    });
  }

  submit_selected_accounts(){
    if(confirm('Etes vous sûr?')){
      let self = this
      let data = this.mainConfig.main_modal.find('.step4 form#account-selection').serializeObject();

      let selected_accounts  = this.remote_accounts.filter((account)=>{ return data['bank_accounts'].find(d=>{ return d == account['id'] }); });

      if(selected_accounts.length > 0){
        this.mainConfig.budgeaApi.update_my_accounts(selected_accounts)
                                  .then(()=>{ this.configuration_finished(); })
                                  .catch(error=>{ this.mainConfig.applicationJS.noticeErrorMessageFrom(null, error.toString()); });
      }else{
        this.configuration_finished();
      }
    }
  }

  configuration_finished(){

  }
}