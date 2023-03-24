//=require './events'
//**** File Sending kits JS *******/
//=require '../../../file_sending_kits/assets/javascripts/events'
//=require '../../../file_sending_kits/assets/javascripts/file_sending_kit'
//=require './order'


jQuery(function () {
  let order = new Order();
  let file_sending_kit = new FileSendingKit();

  if ($('#order form, form#new_edit_order_customer').length > 0){
    order.update_casing_counts();
    order.update_price();
  }

  AppListenTo('update_casing_counts', (e)=>{ order.update_casing_counts(); });
  AppListenTo('update_price', (e)=>{ order.update_price(); });
  AppListenTo('check_casing_size_and_count', (e)=>{ order.check_casing_size_and_count(); });

  AppListenTo('new_edit_order_view', (e)=>{ order.new_edit_order_view(e.detail.url); });
  AppListenTo('rebind_order_events', (e)=>{ bind_all_events_order(); });

  AppListenTo('edit_file_sending_kits_view', (e)=>{ file_sending_kit.edit_file_sending_kits_view(e.detail.url); file_sending_kits_main_events(); });

  AppListenTo('select_for_orders', (e)=>{ file_sending_kit.select_for_orders(e.detail.url); file_sending_kits_main_events(); });
  AppListenTo('select_for_multiple_result', (e)=>{ file_sending_kit.select_for_multiple_result(e.detail.response); file_sending_kits_main_events(); });
});