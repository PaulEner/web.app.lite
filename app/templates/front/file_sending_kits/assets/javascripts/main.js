//=require './events'
//=require './file_sending_kit'

class FileSendingKitMain{

  constructor(){
    this.applicationJS      = new ApplicationJS();
    this.organization_id    = $('input:hidden[name="organization_id"]').val();
    this.add_new_rule_modal = $('#add-new-rule.modal');
    this.action_locker      = false;
  }

  main(){
    // TODO ...
  }
}


jQuery(function () {
  let main = new FileSendingKitMain();
  let file_sending_kit = new FileSendingKit();
  AppListenTo('generate_manual_paper_set_order', (e)=>{ file_sending_kit.generate_manual_paper_set_order(e.detail.url, e.detail.data); file_sending_kits_main_events(); });

  AppListenTo('edit_file_sending_kits_view', (e)=>{ file_sending_kit.edit_file_sending_kits_view(e.detail.url); file_sending_kits_main_events(); });

  AppListenTo('select_for_orders', (e)=>{ file_sending_kit.select_for_orders(e.detail.url); file_sending_kits_main_events(); });
  AppListenTo('select_for_multiple_result', (e)=>{ file_sending_kit.select_for_multiple_result(e.detail.response); file_sending_kits_main_events(); });
});