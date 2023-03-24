//=require './events'
//=require './budgea_api'
//=require './retrievers_list'
//=require './budgea_actions'
//=require './budgea_steps/configuration_steps'

class RetrieverMain{
  constructor(){
    this.applicationJS  = new ApplicationJS();

    this.action_locker = false;
    this.account_select = $('#account_id');
    this.search_name    = $('#filter-retriever #search_name');
    this.search_state   = $('#filter-retriever #search_state');
    this.page = 1;
  }

  load_retrievers(target_page='one'){
    if(this.action_locker)
      return false;

    this.action_locker = true;
    let params = [];

    if(target_page == 'next_page' && this.page > 0)
      this.page += 1
    else if(target_page == 'one')
      this.page = 1

    if(this.page < 0){
      this.action_locker = false;
      return false
    }

    params.push(`page=${this.page}`)
    params.push(`account_id=${this.account_select.val()}`);

    if(this.search_name.val()){ params.push(`name=${encodeURIComponent(this.search_name.val())}`) }
    if(this.search_state.val()){ params.push(`state=${this.search_state.val()}`) }

    let ajax_params =   {
                          'url': `/retrievers?${params.join('&')}`,
                          'dataType': 'html',
                          'target': (this.page == 1)? '.retrievers-list' : ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((e)=>{
                        $('.choose_retriever_action').html($(e).find('.choose_retriever_action').html());
                        if(this.page > 1)
                        {
                          if($(e).find('.no-data-found').length == 0){
                            $('.retrievers-list').append( $(e).find('.retrievers-list').html() );
                          }
                          else{
                            this.page = -1
                          }
                        }else{
                          $('.total-count').text($(e).find('.total-count').text());
                        }

                        this.action_locker = false;
                        bind_all_events();
                      })
                      .catch(()=>{ this.action_locker = false; });
  }

  specific_setup(banking_provider, retriever_id=0){
    let account_id = this.account_select.val();

    if(account_id > 0){
      if(banking_provider == 'bridge'){
        window.location.href = `/bridge/setup_item?account_id=${account_id}`
      }else{
        let url = '/retrievers/new_internal';
        if(retriever_id > 0)
          url = `/retrievers/edit_internal?id=${retriever_id}`;
        this.applicationJS.sendRequest({ url: url, type: 'GET', dataType: 'html' })
                          .then((e)=>{
                            $('.modal#add-internal-retriever .modal-body').html(e);
                            $('.modal#add-internal-retriever').modal('show');
                          });
      }
    }else{
      this.applicationJS.noticeErrorMessageFrom(null, 'Veuillez selectionnez un dossier!');
    }
  }

  specific_setup_validate(banking_provider){
    if(banking_provider != 'internal'){ return false }

    let retriever_id = $('#internal-retrievers #retriever_id').val();
    let url          = '/retrievers';
    let type         = 'POST';

    if(retriever_id > 0){
      url  = `/retrievers/${retriever_id}`;
      type = 'PUT';
    }

    let data         = $(`#internal-retrievers form#internal-retriever-form`).serializeObject();
    let ajax_params  =   {
                            'url': url,
                            'type': type,
                            'data': data,
                            'dataType': 'json'
                          };

    this.applicationJS.sendRequest(ajax_params)
                      .then((e)=>{
                        if(e.json_flash.success)
                          $('.modal#add-internal-retriever').modal('hide');
                      })
  }
}

jQuery(function() {
  let main = new RetrieverMain();

  AppListenTo('retriever_specific_setup', (e)=>{ main.specific_setup(e.detail.banking_provider, e.detail.retriever_id); })
  AppListenTo('retriever_specific_setup_validate', (e)=>{ main.specific_setup_validate(e.detail.banking_provider); })

  AppListenTo('retriever_reload_all', (e)=>{ main.load_retrievers('one'); });
  AppListenTo('documents_next_page', (e)=>{ main.load_retrievers('next_page'); });
});