//= require './events'
//= require './ignored_pre_assignment'
//= require './duplicated_pre_assignment'

class PiecesErrorsMain{
  constructor(){
    this.applicationJS = new ApplicationJS();
    this.action_locker = false;
    this.per_page_of    = { 'ignored-pre-assignment': 20 };
  }

  load_all(){
    this.load_datas('ignored-pre-assignment');
    this.action_locker = false;
    this.load_datas('duplicated-pre-assignment');
    this.action_locker = false;
    this.load_datas('failed-delivery');
  }

  filter_page(type, action='validate'){
    if(action == 'reset')
      $(`.modal form#filter-${type}-form`)[0].reset();

    this.load_datas(type);
    $(`.modal#filter-${type}`).modal('hide');
  }

  load_datas(type='ignored-pre-assignment', page=1, per_page=0){
    if(this.action_locker)
      return false;

    this.action_locker = true;
    let params = [];

    if(per_page > 0)
      this.per_page_of[type] = per_page;

    params.push(`page=${page}`);

    if(this.per_page_of[type] > 0){ params.push(`per_page=${ this.per_page_of[type] }`); }

    try{
      params.push($(`.modal form#filter-${type}-form`).serialize().toString());
    }catch(e){}

    if ($('#account_id').val() != 'all')
      params.push(`account_id=${$('#account_id').val()}`);

    let ajax_params =   {
                          'url': `/pieces/${type.replace(/\-/g, '_')}?${params.join('&')}`,
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
  let main = new PiecesErrorsMain();
  let ignored = new IgnoredPreAssignment(main);
  let duplicated = new DuplicatedPreAssignment(main);

  main.load_all();

  AppListenTo('window.change-per-page.pieces_errors', (e)=>{ main.load_datas(e.detail.name, 1, e.detail.per_page); });
  AppListenTo('account_filter', (e)=>{ main.load_all(); });
  AppListenTo('window.change-page.pieces_errors', (e)=>{ main.load_datas(e.detail.name, e.detail.page); });

  AppListenTo('pieces_errors_filter_page', (e)=>{ main.filter_page(e.detail.target, e.detail.action); });
  AppListenTo('pieces_errors_update_ignored_pieces', (e)=>{ ignored.update_ignored_pieces(e.detail.type); })
  AppListenTo('pieces_errors_update_duplicated_preseizures', (e)=>{ duplicated.update_duplicated_preseizures(e.detail.type); })
});