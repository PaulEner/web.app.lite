//=require './events'
//=require './banks_params'
//=require './documents_selection'

//**** Bank Selection JS *******/
//=require '../../../retrievers/assets/javascripts/budgea_api'
//=require '../../../retrievers/assets/javascripts/budgea_steps/step4'


class RetrievedParametersMain{
  constructor(){
    this.applicationJS      = new ApplicationJS();

    this.action_locker  = false;
    this.account_select = $('#account_id');
    this.per_page_of    = { 'documents-selection': 20 };

    // Must be at last of constructor
    this.budgeaApi          = new BudgeaApi();
    this.bank_select_object = new ConfigurationStep4(this, null, true);
  }

  load_all(){
    this.load_datas('banks-selection');
    this.action_locker = false;
    this.load_datas('documents-selection');
    this.action_locker = false;
    this.load_datas('banks-params');
  }

  filter_page(type, action='validate'){
    if(action == 'reset')
      $(`.modal form#filter-${type}-form`)[0].reset();

    this.load_datas(type);
    $(`.modal#filter-${type}`).modal('hide');
  }

  load_datas(type='banks-params', page=1, per_page=0){
    if(this.action_locker)
      return false;

    this.action_locker = true;
    let params = [];

    if(per_page > 0)
      this.per_page_of[type] = per_page;

    params.push(`page=${page}`);
    params.push(`account_id=${this.account_select.val()}`);

    if(this.per_page_of[type] > 0){ params.push(`per_page=${ this.per_page_of[type] }`); }

    try{
      params.push($(`.modal form#filter-${type}-form`).serialize().toString());
    }catch(e){}

    let ajax_params =   {
                          'url': `/retriever/${type.replace(/\-/g, '_')}?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((html)=>{
                        $(`.tab-pane#${type}`).html(html);
                        $(`span#total-${type}`).text( $(`input#${type}-size`).val() );

                        if(type == 'banks-selection'){
                          window.setTimeout(()=>{
                            this.bank_select_object.target_html = $('#banks-selection #bank_selection');
                            this.bank_select_object.init_form({ id: $('#retriever_selector').val() });
                          }, 1000)
                        }

                        this.action_locker = false;
                      })
                      .catch(()=>{ this.action_locker = false; });
  }
}

jQuery(function() {
  let main        = new RetrievedParametersMain();
  let doc_select  = new RPDocumentsSelection(main);
  let bank_params = new RPBanksParams(main);

  AppListenTo('window.budgea_api_initialized', (e)=>{ main.load_all(); });

  AppListenTo('retriever_integrate_documents', (e)=>{ doc_select.integrate_documents() });

  AppListenTo('retriever_bank_activation', (e)=>{ bank_params.bank_activation(e.detail.id, e.detail.type) });

  AppListenTo('retriever_parameters_filter_page', (e)=>{ main.filter_page(e.detail.target, e.detail.action); });
  AppListenTo('retriever_parameters_reload_all', (e)=>{ main.load_all(); });

  AppListenTo('window.change-per-page.retriever_parameters', (e)=>{ main.load_datas(e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.retriever_parameters', (e)=>{ main.load_datas(e.detail.name, e.detail.page); });

  AppListenTo('retriever_change_retriever_selection', (e)=>{ main.bank_select_object.init_form({ id: e.detail.budgea_id }) });
  AppListenTo('retriever_validate_retriever_selection', (e)=>{ 
    main.bank_select_object.submit_selected_accounts((e)=>{
      main.bank_select_object.init_form({ id: $('#retriever_selector').val() });
      main.applicationJS.noticeSuccessMessageFrom(null, 'Configuration temrminée!');
    });
  });

  AppListenTo('retriever_bank_edition', (e)=>{ bank_params.edit_bank_account(e.detail.id) });
  $('#form-bank-account.modal button.validate').unbind('click').bind('click', (e)=>{ bank_params.update_bank_account(); });
  $('#form-bank-account.modal button.cancel').unbind('click').bind('click', (e)=>{ $('#form-bank-account.modal').modal('hide'); });
});