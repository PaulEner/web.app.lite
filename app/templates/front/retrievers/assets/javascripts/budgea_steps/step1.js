class ConfigurationStep1{
  constructor(mainConfig){
    this.mainConfig = mainConfig;

    this.connectors = [];
  }

  /*** COMMON METHODS ***/
    primary_action(){
      if(this.mainConfig.current_connector){
        this.mainConfig.goto(2, this.retriever);
      }else{
        this.mainConfig.applicationJS.noticeErrorMessageFrom(null, 'Veuillez selectionnez un connecteur avant de poursuivre svp ...');
      }
    }

    secondary_action(){}
  /*** COMMON METHODS ***/

  init_form(retriever={}){
    this.retriever = retriever || {};

    let current_account = $('#account_id').val();

    if(this.retriever['id'] && this.retriever['id'] > 0){
      current_account = this.retriever['user_id'];
      $('#account_id').val(current_account).change();

      $('.step1 #connector-search-name').val('');
      this.mainConfig.main_modal.find('.step1 select#connectors-list').attr('disabled', 'disabled');
      $('.step1 #connector-search-name').attr('disabled', 'disabled');
    }else{
      this.mainConfig.main_modal.find('.step1 select#connectors-list').removeAttr('disabled');
      $('.step1 #connector-search-name').removeAttr('disabled');
    }
  
    if( current_account != 'all' && parseInt(current_account) > 0 ){
      this.mainConfig.main_modal.modal('show');

      AppLoading('show');

      this.fetch_connectors(0);
      this.mainConfig.budgeaApi.check_cgu();
    }else{
      this.mainConfig.applicationJS.noticeErrorMessageFrom(null, 'Veuillez selectionnez un compte avant de poursuivre svp ...');
    }
  }

  fetch_connectors(retry_count=0){
    let normal_size = 290;

    if(this.connectors.length >= normal_size || retry_count > 3 )
    {
      this.fill_connectors();
    }
    else
    {
      let cache_connectors = GetCache('connectors_list');
      if(cache_connectors.length >= normal_size)
      {
        this.connectors = cache_connectors;
        this.fill_connectors();
      }
      else
      {
        console.log(`++++> retry_fetching: ${retry_count} / ${this.connectors.length}`);
        this.mainConfig.budgeaApi.get_connectors()
                                  .then((connectors)=>{
                                    let distinct = (value, index, self)=>{
                                      return self.findIndex((e)=>{ return value['id'] == e['id'] }) == index
                                    }

                                    this.connectors = connectors.filter(distinct);
                                    SetCache('connectors_list', this.connectors);

                                    this.fetch_connectors(retry_count + 1);

                                  })
                                  .catch((e)=>{ this.mainConfig.applicationJS.noticeErrorMessageFrom(null, e.toString()); })
      }
    }
  }

  fill_connectors(){
    console.log(`++++> Total: ${this.connectors.length}`);

    let filter     = $('.step1 #connector-search-name').val();
    if(filter.length < 3){ filter = null };

    let type = 'bank';
    let can_manage_providers = VARIABLES.get('can_manage_providers');

    if(can_manage_providers == 1){
      $('.bank_and_document_selector').removeClass('hide');
      type = $('.step1 #choose-selector').val() || 'all';
    }
    else{
      $('.bank_and_document_selector').addClass('hide');
      type = "bank";
    }

    //add document capabilities if edition
    if(this.retriever['budgea_connector_id'] && this.retriever['budgea_connector_id'] > 0){
      type = 'all';
    }

    let regEx      = new RegExp((`${filter}` || '.*'), 'i');
    let total_size = 0;
    let options    = '';

    let select = this.mainConfig.main_modal.find('.step1 select#connectors-list');
    select.html('');

    this.connectors = this.connectors.sort((a,b)=>{
      if(a['name'].toLowerCase() < b['name'].toLowerCase())
        return -1;
      if(a['name'].toLowerCase() > b['name'].toLowerCase())
        return 1;
      return 0;
    });

    this.connectors.forEach((connector)=>{
      if( filter == '' || filter == null || filter == 'undefined' || regEx.test(connector['name']) ){
        if(type == 'all' || connector['capabilities'].find((e)=>{ return e == type })){
          total_size++;

          let selected = '';
          if(this.retriever['budgea_connector_id'] && this.retriever['budgea_connector_id'] > 0 && this.retriever['budgea_connector_id'] == connector['id'])
            selected = 'selected="selected"';

          options += `<option value="${connector['id']}" ${selected}>${connector['name']}</option>`;
        }
      }
    });

    AppLoading('hide');

    select.html(options);
    $('.step1 .connectors-size').text(total_size);

    if(this.retriever['budgea_connector_id'] && this.retriever['budgea_connector_id'] > 0){
      this.select_connector();
      this.mainConfig.goto(2, this.retriever);
    }
  }

  select_connector(){
    let connector_id = this.mainConfig.main_modal.find('select#connectors-list').val();
    this.mainConfig.current_connector = this.connectors.find((e)=>{ return e['id'] == connector_id });

    let html = '<ul>';
    this.mainConfig.current_connector['urls'].forEach((url)=>{
      html += `<li>${url}</li>`;
    })

    html += '</ul>'

    //Add field exception for Paypal API REST
    if(this.mainConfig.current_connector['name'] == 'Paypal REST API'){
      this.mainConfig.current_connector['fields'] = [{ label: '', name: 'paypal_oauth', value: 'true', regex: null, required: false, type: "oauth" }];
    }
    console.log(this.mainConfig.current_connector);

    this.mainConfig.main_modal.find('.step1 .urls-box').html(html);
  }
}