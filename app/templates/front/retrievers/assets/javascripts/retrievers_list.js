class RetrieversList{
  constructor(){
    this.applicationJS  = new ApplicationJS();
    this.budgeaApi      = new BudgeaApi();

    this.ul_banks       = $('ul.banks');
    this.ul_providers   = $('ul.providers');

    this.connectors     = [];

    this.providers_connectors = [];
    this.banks_connectors     = [];
  }

  fetch_list(){
    let can_manage_providers = VARIABLES.get('can_manage_providers');

    if(can_manage_providers == 1)
      $('.modal#connectors-list .providers-box').removeClass('hide');
    else
      $('.modal#connectors-list .providers-box').addClass('hide');

    $('.modal#connectors-list').modal('show');

    if(this.connectors.length > 0){
      this.fill_ul_list();
    }
    else{
      this.budgeaApi.get_connectors()
                    .then((connectors)=>{
                      this.connectors = connectors;
                      this.fill_ul_list();
                    })
                    .catch((e)=>{ this.applicationJS.noticeErrorMessageFrom(null, e.toString()); })
    }
  }

  fill_ul_list(filter=null){
    let regEx = new RegExp((`^${filter}` || '.*'), 'i');
    let banks_size     = 0;
    let providers_size = 0;

    this.ul_banks.html('');
    this.ul_providers.html('');

    this.banks_connectors     = [];
    this.providers_connectors = [];

    this.connectors.forEach((connector)=>{
      if( connector['capabilities'].find(c=>{ return c === 'bank' }) ){
        if( filter == null || filter == 'undefined' || regEx.test(connector['name']) ){
          banks_size++;
          this.ul_banks.append(`<li><a href="#" title="${connector['name']}">${connector['name']}</a></li>`);
        }

        this.banks_connectors.push(connector);
      }else if( connector['capabilities'].find(c=>{ return c === 'document' }) ){
        if( filter == null || filter == 'undefined' || regEx.test(connector['name']) ){
          providers_size++;
          this.ul_providers.append(`<li><a href="#" title="${connector['name']}">${connector['name']}</a></li>`);
        }

        this.providers_connectors.push(connector);
      }
    });

    $('.banks-size').text(banks_size);
    $('.providers-size').text(providers_size);
  }

  export_list(){
    if(confirm('Voulez vous vraiment exporter la liste des automates disponible?')){
      let ajax_params = {
                          'url': '/retrievers/export_connector_to_xls',
                          'type': 'POST',
                          'data': { banks: this.banks_connectors.map(e=>{ return e['name']; }).join(';'), documents: this.providers_connectors.map(e=>{ return e['name']; }).join(';') },
                          'dataType': 'json'
                        }

      this.applicationJS.sendRequest(ajax_params)
                        .then((e)=>{
                          window.location.href = '/retrievers/get_connector_xls/' + e.key
                        })
    }
  }
}

jQuery(function() {
  let main = new RetrieversList();

  AppListenTo('retrievers_list', (e)=>{ main.fetch_list(); });
  AppListenTo('retrievers_list_filter', (e)=>{ main.fill_ul_list(e.detail.pattern); });
  AppListenTo('retrievers_list_export', (e)=>{ main.export_list(); });
});