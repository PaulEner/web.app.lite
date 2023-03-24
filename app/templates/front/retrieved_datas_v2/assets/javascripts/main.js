//=require './events'

class RetrievedDatasV2Main{
  constructor(){
    this.applicationJS = new ApplicationJS();
    this.action_locker = false;
    this.account_select = $('#account_id');
    this.per_page_of = { 'operations': 20, 'documents': 20 };
  }

  load_all(){
    this.load_datas('operations');
    this.action_locker = false;
    this.load_datas('documents');
  }

  load_datas(type='operations', page=1, per_page=0){
    if(this.action_locker)
      return false;

    this.action_locker = true;
    let params = [];

    if(per_page > 0)
      this.per_page_of[type] = per_page;

    params.push(`page=${page}`);
    params.push(`account_id=${this.account_select.val()}`);

    if(this.per_page_of[type] > 0){ params.push(`per_page=${ this.per_page_of[type] }`); }

    params.push($(`#filter-${type}-form`).serialize().toString());

    let ajax_params =   {
                          'url': `/retrieved_v2/${type}?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((html)=>{
                        $(`.tab-pane#${type}`).html(html);
                        $(`span#total-${type}`).text( $(`input#${type}-size`).val() );

                        this.action_locker = false;
                        bind_all_events();
                      })
                      .catch(()=>{ this.action_locker = false; });
  }
}

jQuery(function() {
  let main = new RetrievedDatasV2Main();
  main.load_all();

  AppListenTo('retrieved_datas_reload_all', (e)=>{ main.load_all(); });
  AppListenTo('retrieved_datas_reload_operations', (e)=>{ this.load_datas('operations'); });

  AppListenTo('retrieved_datas_filter', (e)=>{ $(`.modal#filter-${e.detail.type}`).modal('hide'); main.load_datas(e.detail.type); });
  AppListenTo('retrieved_datas_reset_filter', (e)=>{ $(`.modal#filter-${e.detail.type}`).modal('hide'); $(`#filter-${e.detail.type}-form`)[0].reset(); main.load_datas(e.detail.type); });

  AppListenTo('window.change-per-page.retrieved_data', (e)=>{ main.load_datas(e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.retrieved_data', (e)=>{ main.load_datas(e.detail.name, e.detail.page); });
});