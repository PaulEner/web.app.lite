//=require './events'

//**** File Sending kits JS *******/
//=require '../../../file_sending_kits/assets/javascripts/events'
//=require '../../../file_sending_kits/assets/javascripts/file_sending_kit'


class PaperSetOrder{

  constructor(){
    this.applicationJS         = new ApplicationJS();
    this.organization_id       = $('input:hidden[name="organization_id"]').val();
    this.is_manual             = $('input:hidden[name="manual_paper_set_order"]').val();
    this.paper_set_link        = $('input:hidden[name="manual_paper_set_order"]').attr('view');
    this.add_new               = $('#add-new-paper-set-order.modal');
    this.file_sending_kits_edit = $('#file_sending_kits_edit.modal');
    this.select_multiple       = $('#select_for_orders.modal');
    this.create_order_multiple = $('#create_order_multiple.modal');
    this.action_locker         = false;
  }


  load_data(search_pattern=false, type='paper_set_orders', page=1, per_page=0){
    if(this.action_locker) { return false; }

    this.action_locker = true;
    let params = [];

    params.push(`page=${page}`);

    if (per_page > 0) { params.push(`per_page=${ per_page }`); }

    let search_text = '';

    if (search_pattern) {
      search_text = $('.search-content #search_input').val();
      if(search_text && search_text != ''){ params.push(`order_contains[text]=${encodeURIComponent(search_text)}`); }
    }

    let ajax_params =   {
                          'url': `/organizations/${this.organization_id}/${type}?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
                      .then((html)=>{
                        if (search_pattern && search_text != '') {
                          $('.paper-set-order-view').html($(html).find('.paper-set-order-view').html());
                          $('.search-content #search_input').val(search_text);
                        }
                        this.action_locker = false;
                        file_sending_kits_main_events();
                      })
                      .catch(()=>{ this.action_locker = false; });
  }

  select_for_orders(){
    this.applicationJS.sendRequest({ 'url': this.paper_set_link }).catch((error)=> { 
      console.log(error)
    }).then((element)=>{
      if (this.is_manual === 'true') {
        this.select_multiple.find('.modal-body').html($(element).find('.file_sending_kits_select').html());
      }
      else{
        this.select_multiple.find('.modal-body').html($(element).find('.select_to_order').html());
        this.select_multiple.find('.edit-file-sending-kits').remove();
      }

      this.select_multiple.find('.form-footer-content').remove();

      file_sending_kits_main_events();
    });
  }

  order_multiple_paper_set(url, data){
    if (data.length > 0) {
      this.applicationJS.sendRequest({
        'url': url,
        'data': data,
        'type': 'POST',
      }).then((result)=>{
        this.create_order_multiple.find('.modal-body').html($(result).find('#paper_set_orders.order_multiple .form-content').html());
        this.create_order_multiple.find('.modal-title').html($(result).find('#paper_set_orders.order_multiple .modal-title').html());
        this.create_order_multiple.find('.form-footer-content').remove();
        /*file_sending_kits_main_events();*/

       }).catch((result)=>{ 
        this.action_locker = false;
        console.error(result);
      });
    }
  }


  add_or_edit_paper_set_order(url){
    this.applicationJS.sendRequest({ 'url': url }).catch((error)=> { 
      console.log(error)
    }).then((element)=>{
      this.add_new.find('.modal-body').html($(element).find('#paper_set_order .form-content').html());
      this.add_new.find('.modal-title').html($(element).find('#paper_set_order .modal-title').html());
      this.add_new.find('.form-footer-content').remove(); 

      /*file_sending_kits_main_events();*/
    });
  }


  paper_set_prices(){
    /*return JSON.parse('[[[27, 36, 44, 53, 62, 70, 79, 88, 96, 105, 113, 122, 133, 142, 151, 159, 168, 177, 185, 194, 202, 211, 220, 228], [27, 36, 45, 53, 62, 71, 79, 88, 97, 106, 117, 126, 134, 143, 152, 161, 169, 178, 187, 195, 204, 213, 222, 230], [27, 36, 45, 54, 62, 71, 80, 89, 98, 109, 118, 127, 135, 144, 153, 162, 171, 179, 188, 197, 206, 215, 223, 232], [27, 36, 45, 54, 63, 72, 81, 89, 101, 110, 119, 128, 136, 145, 154, 163, 172, 181, 190, 198, 207, 216, 225, 234], [27, 36, 45, 54, 63, 72, 81, 93, 102, 111, 120, 129, 137, 146, 155, 164, 173, 182, 191, 200, 209, 218, 227, 236], [28, 37, 46, 55, 64, 73, 84, 93, 102, 111, 120, 129, 138, 147, 157, 166, 175, 184, 193, 202, 211, 220, 229, 238]], [[32, 43, 55, 67, 78, 90, 102, 113, 125, 137, 148, 160, 175, 186, 198, 210, 221, 233, 245, 256, 268, 280, 291, 303], [32, 44, 55, 67, 79, 91, 102, 114, 126, 138, 152, 164, 176, 188, 199, 211, 223, 235, 246, 258, 270, 282, 293, 305], [32, 44, 56, 67, 79, 91, 103, 115, 127, 141, 153, 165, 177, 189, 201, 212, 224, 236, 248, 260, 272, 283, 295, 307], [32, 44, 56, 68, 80, 92, 104, 115, 130, 142, 154, 166, 178, 190, 202, 214, 226, 238, 250, 261, 273, 285, 297, 309], [32, 44, 56, 68, 80, 92, 104, 119, 131, 143, 155, 167, 179, 191, 203, 215, 227, 239, 251, 263, 275, 287, 299, 311], [32, 44, 56, 68, 81, 93, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 229, 241, 253, 265, 277, 289, 301, 313]], [[33, 47, 61, 75, 89, 103, 117, 131, 145, 159, 173, 187, 204, 218, 232, 246, 260, 274, 288, 302, 316, 330, 344, 358], [33, 47, 61, 75, 90, 104, 118, 132, 146, 160, 177, 191, 205, 219, 233, 247, 261, 275, 289, 303, 317, 332, 346, 360], [33, 47, 62, 76, 90, 104, 118, 132, 146, 164, 178, 192, 206, 220, 234, 248, 263, 277, 291, 305, 319, 333, 347, 362], [33, 48, 62, 76, 90, 105, 119, 133, 150, 164, 179, 193, 207, 221, 235, 250, 264, 278, 292, 307, 321, 335, 349, 364], [33, 48, 62, 76, 91, 105, 119, 137, 151, 165, 179, 194, 208, 222, 237, 251, 265, 280, 294, 308, 322, 337, 351, 365], [34, 48, 62, 77, 91, 105, 123, 137, 152, 166, 180, 195, 209, 223, 238, 252, 267, 281, 295, 310, 324, 339, 353, 367]]]');*/
    return JSON.parse($('#paper_set_prices').val() || '[]');
  }

  casing_size_index_of(size){
    const paper_set_casing_size = parseInt(size);

    if (paper_set_casing_size === 500) { return 0 }
    else if (paper_set_casing_size === 1000) { return 1 }
    else if (paper_set_casing_size) { return 2 }
  }

  folder_count_index(){
    return parseInt($('#order_paper_set_folder_count, #orders__paper_set_folder_count').val()) - 5;
  }

  period_index_of(start_date, end_date, period_duration){
    period_duration = parseInt(period_duration);
    const ms_day = 1000*60*60*24*28;
    const count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration;
    return (count / period_duration) - 1;
  }

  discount_price_of(price, size, tr_index) {
    let unit_price = 0;
    let selected_casing_count = 0;
    let max_casing_count = 0;

    if(tr_index < 0){
      selected_casing_count = parseInt($('#order_paper_set_casing_count option:selected').text());
      max_casing_count = parseInt($('#order_paper_set_casing_count option').first().text());
    }
    else{
      selected_casing_count = parseInt($(`.casing_count_${tr_index} option:selected`).text());
      max_casing_count = parseInt($(`.casing_count_${tr_index} option`).first().text());
    }

    switch(this.casing_size_index_of(size)){
      case 0:
        unit_price = 6;
        break;
      case 1:
        unit_price = 9;
        break;
      case 2:
        unit_price = 12;
        break;
      default:
        unit_price = 0;
    }

    if(selected_casing_count > 0 && max_casing_count > 0){
      const casing_rest = max_casing_count - selected_casing_count
      const discount_price = unit_price * casing_rest
      return price - discount_price;
    }
    else { return price; }
  }

  price_of_periods(){
    const size = $('#order_paper_set_casing_size').val();
    const start_date = new Date($('#order_paper_set_start_date').val());
    const end_date   = new Date($('#order_paper_set_end_date').val());
    const period_index = this.period_index_of(start_date, end_date, $('#order_period_duration').val());

    if (start_date <= end_date){
      if (is_manual_paper_set_order_applied()){
        let paper_set_folder_count = parseInt($("input[name*='paper_set_folder_count']").val());
        return paper_set_folder_count * (period_index + 1);
      }
      else{ return this.discount_price_of(this.paper_set_prices()[this.casing_size_index_of(size)][this.folder_count_index()][period_index], size, -1); }
    }
    else{ return 0; }
  }

  update_price(){
    const price = this.price_of_periods();
    $('.total_price').html(price + ",00€ HT");
    if (price === 0){
      $('#order_paper_set_start_date').parents('.control-group').addClass('error');
      $('#order_paper_set_start_date').next('.help-inline').remove();
      $("<span class='help-inline'>n\'est pas valide</span>").insertAfter($('#order_paper_set_start_date'));
    }
    else{
      $('#order_paper_set_start_date').parents('.control-group').removeClass('error');
      $('#order_paper_set_start_date').next('.help-inline').remove();
    }
  }

  update_casing_counts(){
    const start_date = new Date($('#order_paper_set_start_date').val());
    const end_date   = new Date($('#order_paper_set_end_date').val());

    if(start_date > 0 && end_date > 0){
      let counts = this.period_index_of(start_date, end_date, $('#order_period_duration').val()) + 1;
      let options = ``;
      let curr_val = parseInt($("#paper_set_casing_count_hidden").val()) || 0;
      if(curr_val == 0){ curr_val = counts; }

      while(counts > 0){
        let selected = curr_val === counts ? 'selected="selected"' : '';
        options += `<option value="${counts}" ${selected}>${counts}</option>`;
        selected ='';
        counts--;
      }

      $('#order_paper_set_casing_count').html(options);
    }
    else{
      $('#order_paper_set_casing_count').html('');
    }

    this.check_casing_size_and_count();
  }

  check_casing_size_and_count(){
    const selected_val = parseInt($('#order_paper_set_casing_count option:selected').text());
    const max_val = parseInt($('#order_paper_set_casing_count option').first().text());

    if((max_val - selected_val) >= 2){
      $('.select.order_paper_set_casing_count i.help-block').removeClass('hide');
    }
  }


  update_table_price(){
    const orders = $('#paper_set_orders.order_multiple tbody tr, form.order_multiple_form tbody tr');
    let total_price = 0
    let price = 0;
    let self = this;

    orders.each(function(i){
      let order = this;
      let paper_set_casing_size  = parseInt($(order).find("select[name*='paper_set_casing_size']").val());

      let paper_set_folder_count_index = parseInt($(order).find("select[name*='paper_set_folder_count']").val()) - 5;
      let start_date = new Date($(order).find("select[name*='paper_set_start_date']").val());
      let end_date = new Date($(order).find("select[name*='paper_set_end_date']").val());
      let period_index = self.period_index_of(start_date, end_date , $(order).find("input[name*='period_duration']").val());
      if (start_date <= end_date){
        if (is_manual_paper_set_order_applied()){
          let folder_count = parseInt($(order).find("input[name*='paper_set_folder_count']").val());
          price = folder_count * (period_index + 1);
        }
        else{
          price = self.discount_price_of(self.paper_set_prices()[self.casing_size_index_of(paper_set_casing_size)][paper_set_folder_count_index][period_index], paper_set_casing_size, $(order).attr('data-index'));
          $(order).find("select[name*='paper_set_start_date']").parents('.control-group').removeClass('error');
          $(order).find("select[name*='paper_set_start_date']").next('.help-inline').remove();
        }
      }
      else{
        $(order).find("select[name*='paper_set_start_date']").parents('.control-group').addClass('error');
        $(order).find("select[name*='paper_set_start_date']").next('.help-inline').remove();
        $("<span class='help-inline'>n\'est pas valide</span>").insertAfter($(order).find("select[name*='paper_set_start_date']"));
      }
      total_price += price;
      $(order).find('.price').html(price + ",00€");
      $('.total_price').html(total_price + ",00€ HT");
    });
  }

  update_table_casing_counts(index){
    let monthDiff = (dateFrom, dateTo) =>  (dateTo.getMonth() - dateFrom.getMonth() + (12 * (dateTo.getFullYear() - dateFrom.getFullYear()))) + 1;
    let fill_options_of = (ind) => {
      let start_date = new Date($('.date_order.start_date_' + ind).val());
      let end_date = new Date($('.date_order.end_date_' + ind).val());

      if(start_date > 0 && end_date > 0){
        let counts = this.period_index_of(start_date, end_date, $('.period_duration_' + ind ).val()) + 1;
        let options = '';
        let selected = 'selected="selected"';

        while(counts > 0){
          options += '<option value="' + counts + '" ' + selected + '>' + counts + '</option>';
          selected='';
          counts--;
        }

        $('.casing_count_' + ind ).html(options);
      }
      else{
        $('.casing_count_' + ind ).html('');
      }
    };

    if(index < 0){
      $('#paper_set_orders.order_multiple tbody#list_orders > tr, form.order_multiple_form tbody#list_orders tr').each(function(e){
        let key = $(this).attr("data-index");
        fill_options_of(key);
      });
    }
    else{
      fill_options_of(index);
    }
  }


  edit_file_sending_kits_view(url){
    this.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      this.file_sending_kits_edit.find('.modal-body').html($(element).find('.file_sending_kits_edit').html());
      this.select_multiple.modal('hide');
      this.file_sending_kits_edit.modal('show');

    }).catch((error)=> { 
      console.error(error);
    });
  }

}


jQuery(function () {
  let paper_set_order = new PaperSetOrder();
  let file_sending_kit = new FileSendingKit();

  if ($('form.paper_set_order_form').length > 0){
    paper_set_order.update_casing_counts();
    paper_set_order.update_price();
  }

  if ($('.order_multiple form, form.order_multiple_form').length > 0){
    paper_set_order.update_table_casing_counts(-1);
    paper_set_order.update_table_price();
  }

  AppListenTo('select_for_orders', (e)=>{ paper_set_order.select_for_orders(); });
  AppListenTo('add_or_edit_paper_set_order', (e)=>{ paper_set_order.add_or_edit_paper_set_order(e.detail.url); });

  AppListenTo('update_casing_counts', (e)=>{ paper_set_order.update_casing_counts(); });
  AppListenTo('update_price', (e)=>{ paper_set_order.update_price(); });
  AppListenTo('check_casing_size_and_count', (e)=>{ paper_set_order.check_casing_size_and_count(); });
  AppListenTo('update_table_price', (e)=>{ paper_set_order.update_table_price(); });
  AppListenTo('update_table_casing_counts', (e)=>{ paper_set_order.update_table_casing_counts(e.detail.index); });

  AppListenTo('order_multiple_paper_set', (e)=>{ paper_set_order.order_multiple_paper_set(e.detail.url, e.detail.data); });

  AppListenTo('edit_file_sending_kits_view', (e)=>{ paper_set_order.edit_file_sending_kits_view(e.detail.url); });

  AppListenTo('generate_manual_paper_set_order', (e)=>{ file_sending_kit.generate_manual_paper_set_order(e.detail.url, e.detail.data); file_sending_kits_main_events(); });

  AppListenTo('window.change-per-page.paper_set_orders', (e)=>{ paper_set_order.load_data(true, e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.paper_set_orders', (e)=>{ paper_set_order.load_data(true, e.detail.name, e.detail.page, e.detail.per_page); });
});