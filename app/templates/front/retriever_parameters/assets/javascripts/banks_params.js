class RPBanksParams{
  constructor(mainJS){
    this.modal         = $('#form-bank-account.modal');
    this.main          = mainJS;
    this.bank_id       = 0;

    this.connectors    = [];
  }

  fetch_connectors(){
    AppLoading('show');
    if(this.connectors.length > 0)
    {
      this.fill_connectors();
    }
    else
    {
      let cache_connectors = GetCache('connectors_list');
      if(cache_connectors.length > 0)
      {
        this.connectors = cache_connectors;
        this.fill_connectors();
      }
      else
      {
        this.main.budgeaApi.get_connectors()
                            .then((connectors)=>{
                              let distinct = (value, index, self)=>{
                                return self.findIndex((e)=>{ return value['id'] == e['id'] }) == index
                              }

                              this.connectors = connectors.filter(distinct);
                              SetCache('connectors_list', this.connectors);
                              this.fill_connectors();
                            })
                            .catch((e)=>{ this.main.applicationJS.noticeErrorMessageFrom(null, e.toString()); })
      }
    }
  }

  fill_connectors(){
    let options    = '';

    let select = this.modal.find('#bank_account_bank_name');
    select.html('');

    // ADD MANUAL BANKS HERE
      this.connectors.push({ name: 'UBS', capabilities: ['bank'] })
      this.connectors.push({ name: 'EFG', capabilities: ['bank'] })
      this.connectors.push({ name: 'CAIXA', capabilities: ['bank'] })
      this.connectors.push({ name: 'OuiTrust', capabilities: ['bank'] })
      this.connectors.push({ name: 'Banque Delubac & Cie', capabilities: ['bank'] })
      this.connectors.push({ name: 'Nuger', capabilities: ['bank'] })
    // MANUAL BANKS

    this.connectors = this.connectors.sort((a,b)=>{
      if(a['name'].toLowerCase() < b['name'].toLowerCase())
        return -1;
      if(a['name'].toLowerCase() > b['name'].toLowerCase())
        return 1;
      return 0;
    });

    this.connectors.forEach((connector)=>{
      if(connector['capabilities'].find((e)=>{ return e == 'bank' })){
        options += `<option value="${connector['name']}">${connector['name']}</option>`;
      }
    });

    select.html(options);

    AppLoading('hide');
  }

  bank_activation(id, type='disable'){
    let action = (type == "disable")? "supprimer" : "activer";

    if(confirm(`Voulez-vous vraiment ${action} ce compte bancaire?`)){
      let ajax_params = {
                          'url': '/retriever/bank_activation',
                          'data': { id: id, type: type },
                          'type': 'POST',
                          'dataType': 'json'
                        };

      this.main.applicationJS.sendRequest(ajax_params).then((e)=>{ this.main.load_datas('banks-params'); this.main.applicationJS.noticeSuccessMessageFrom(null, e.message); });
    }
  }

  edit_bank_account(id=0){
    this.bank_id = id;

    let url = '/retriever/new/bank'
    let title = 'Création de compte bancaire';

    if(this.bank_id > 0){
      url   = `/retriever/bank/${this.bank_id}`;
      title = 'Editon de compte bancaire';
    }
    

    let ajax_params = {
                        'url': url,
                        'dataType': 'html'
                      };

    this.main.applicationJS.sendRequest(ajax_params)
                            .then((e)=>{ 
                              this.modal.modal('show');
                              this.modal.find('.modal-title').text(title);
                              this.modal.find('.modal-body').html(e);

                              //fetching bank_accounts list if creation
                              if(this.bank_id == 0)
                                this.fetch_connectors();
                            });
  }

  update_bank_account(){
    let url = '/retriever/new/bank'

    if(this.bank_id > 0){
      url = `/retriever/bank/${this.bank_id}`
    }

    let datas = $(`#form-bank-params`).serialize();

    let ajax_params = {
                        'url': url,
                        'type': 'PATCH',
                        'data': datas,
                        'dataType': 'json'
                      };

    this.main.applicationJS.sendRequest(ajax_params)
                      .then((e)=>{ 
                        if(e.success){
                          this.main.load_datas('banks-params');
                          this.modal.modal('hide');
                          this.main.applicationJS.noticeSuccessMessageFrom(null, e.message);
                        }else{
                          this.main.applicationJS.noticeErrorMessageFrom(null, e.message);
                        }
                      });
  }
}