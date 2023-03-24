class MyDocumentsPreseizures{
  constructor(){
    this.applicationJS = new ApplicationJS;
    this.action_locker = false;
    this.edit_modal    = $('#edit_preseizures.modal');

    this.input_can_focusout = true;
    this.id = 0;
  }

  refresh_view(preseizure_id, lock=true){
    if(lock && this.action_locker)
      return false;

    this.action_locker = true;

    let params =  {
                    'url': `/my_documents/preseizures/${preseizure_id}`,
                    'data': { view: 'by_type' },
                    'dataType': 'html'
                  }

    this.applicationJS.sendRequest(params)
                      .then((e)=>{
                        let dynamic_box = $(e).find('.dynamic_box');

                        $('.dynamic_box').each((e, self)=>{
                          let tmp_id = $(self).attr('data-preseizure-id');
                          let tmp_type = $(self).attr('data-type');

                          if(parseInt(preseizure_id) == parseInt(tmp_id)){
                            $(self).html(dynamic_box.html());
                            bind_all_events();
                          }
                        });

                        this.action_locker = false;
                      })
                      .catch(()=>{ this.action_locker = false; });
  }

  edit_preseizures(elem){
    this.id = elem.attr('data-id');

    let params =  {
                    'url': `/my_documents/preseizures/${this.id}`,
                    'dataType': 'html'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{
      this.edit_modal.find('.modal-body').html(e);
      this.edit_modal.modal('show');
    });
  }

  edit_multiple_preseizures(ids){
    let params =  {
                    'url': `/my_documents/preseizures/edit_multiple_preseizures/${ids}`,
                    'dataType': 'html'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{
       this.edit_modal.find('.modal-body').html(e);
       this.edit_modal.modal('show');
    });
  }

  update_preseizures(){
    let self = this

    let datas = self.edit_modal.find('#preseizure_edition_form').serialize();
    datas += `&id=${self.id}`;

    let ids = $('#preseizure_edition_form #preseizures_ids').val();

    let update = ids != undefined ? 'update_multiple_preseizures' : 'update'

    let params =  {
                    'url': `/my_documents/preseizures/${update}`,
                    'type': 'POST',
                    'data': datas,
                    'dataType': 'json'
                  }

    self.applicationJS.sendRequest(params).then((e)=>{
      if(e.error.toString() == '')
      {
        if (update == 'update_multiple_preseizures' ){
          $.each(ids.split(','), function( index, id ) {
            self.refresh_view(id, false);
          });

          $('.select-all').prop('checked', false);
          $('.action-selected').addClass('hide');
        }else{
          self.refresh_view(this.id);
        }

        $('.select-box-document, .select-box-operation').removeClass('selected');
        $('.select-document, .select-operation').prop('checked', false);

        self.applicationJS.noticeSuccessMessageFrom(null, 'Modifié avec succès');
        self.edit_modal.modal('hide');
      }
      else
      {
        self.applicationJS.noticeErrorMessageFrom(null, e.error);
      }
    });
  }

  edit_entry_account(elem){
    let me = this;
    let id = elem.closest('table.entries').attr('data-preseizure-id');
    let account_id = elem.closest("tr").find('.account_id_hidden').val();
    let edit_content     = elem.parent('td').find('.edit_account');    
    let content_account  = elem;
    let input            = edit_content.find('.edit_account_number');
    let current_value    = input.val();

    if (input.length > 0)
    {
      const validate_input = (el)=>{
        edit_content.hide();
        content_account.show();
        let new_value = $(el).val();

        if(current_value != new_value)
          me.update_entry_amount(account_id, new_value, "account", id);
      }

      me.input_can_focusout = true;
      edit_content.show();
      content_account.hide();
      input.unbind('focusout');
      input.select();
      input.blur().focus().focusout(function(){
        if(me.input_can_focusout)
          validate_input(this);
      }).on('keypress',function(e) {          
            if(e.which == 13)
              validate_input(this);
      }).on('keyup', function(e){
        me.account_auto_completion($(this), $(this).val(), account_id);
      });
    }
  }

  edit_entry_amount(elem){
    let me = this;
    let id = elem.closest('table.entries').attr('data-preseizure-id');
    let edit_content    = elem.parent().find('.edit_amount');
    let content_amount  = elem;
    let input           = edit_content.find('input').first();
    let current_value   = input.val();

    if (input.length > 0)
    {
      const validate_input = (el)=>{
        var new_value   = $(el).val();
        edit_content.hide();
        content_amount.show();

        if(current_value != new_value)
        {
          var account_id = $(el).closest("tr").find('.entry_id_hidden').val();          
          me.update_entry_amount(account_id, new_value, "entry", id);
        }
      }

      edit_content.show();
      content_amount.hide();
      input.unbind('focusout');
      input.select();
      input.blur().focus().focusout(function(e){ validate_input(this) }).on('keypress',function(e) { if(e.which == 13) { validate_input(this) }; });
    }
  }

  change_entry_type(elem){
    let id = elem.closest('table.entries').attr('data-preseizure-id');
    let entry_type = elem.closest('td').find('.entry_type').val();
    let account_id = elem.closest("tr").find('.entry_id_hidden').val();    

    this.update_entry_amount(account_id, (entry_type == 1)? 2 : 1, "change_type", id);
  }

  update_entry_amount(account_id, new_value, type, preseizure_id){
    let params =  {
                    'url': '/my_documents/preseizures/account/'+preseizure_id+'/update',
                    'type': 'POST',
                    'data': { account_id: account_id, new_value: new_value, type: type },
                    'dataType': 'json'
                  };

    this.applicationJS.sendRequest(params).then((e)=>{ 
      if(e.error != '')
        this.applicationJS.noticeErrorMessageFrom(null, e.error);
      else
        this.applicationJS.noticeSuccessMessageFrom(null, 'Modifié avec succès');

      this.refresh_view(preseizure_id); 
    });
  }

  account_auto_completion(input, value, account_id = 0){
    let me = this;

    const bind_completions_actions = () => {
        $(".suggestion_account_list ul li").unbind('click').unbind('mouseout').unbind('mouseover');
        $(".suggestion_account_list ul li").on('click',function(e){
          e.preventDefault();
          $(this).closest(".edit_account").find('input').val($(this).attr('id')).blur().focus();
          $(this).closest(".suggestion_account_list").hide();
          return false;
        }).on('mouseover', function(e){
          me.input_can_focusout = false
        }).on('mouseout', function(e){
          me.input_can_focusout = true
        });
    }

    var html_autocomplete = input.parent().find('.suggestion_account_list');

    if(value.length > 0)
    { 
      const finalize = (data=null) => {
        if(data != null)
          html_autocomplete.html(data);

        html_autocomplete.find('ul').children().hide();
        var result_found = html_autocomplete.find('ul').children('[id*='+value+']');

        if(result_found.length > 0)
          result_found.show();
        else
          html_autocomplete.find('.no_result').show();

        bind_completions_actions();
        html_autocomplete.show();
      };

      if (html_autocomplete.children().length == 0)
      {
        let _prm =  {
                      'url': `/my_documents/preseizures/accounts_list/${account_id}`,
                      'type': "GET",
                    };

        this.applicationJS.sendRequest(_prm).then((data)=>{ finalize(data); });
      }
      else
      {
        finalize();
      }
    }
    else
    {
      html_autocomplete.addClass('hide');
    }
  }

  edit_third_party(details){
    let type  = details[0].type;
    let value = details[0].value;
    let id    = details[0].id;


    let params =  {
                  'url': `/my_documents/preseizures/edit_third_party`,
                  'type' : 'POST',
                  'data' : { id: id, type: type, value: value },
                  'dataType': 'json'
                }

    this.applicationJS.sendRequest(params).then((e)=>{
      if(e.error != '')
        this.applicationJS.noticeErrorMessageFrom(null, e.error);
      else
        this.applicationJS.noticeSuccessMessageFrom(null, 'Modifié avec succès');

      this.refresh_view(id); 
    });
  }



  insert_new_entry(element, preseizure_id){
    let data = { id: preseizure_id, type_account: element.find('.type_account').val() , account: element.find('.account input').val(), entry_type_1: element.find('.entry #type_1').val(), entry_type_2: element.find('.entry #type_2').val() }

    let params =  {
                    'url': `/my_documents/preseizures/new_entry`,
                    type: 'POST',
                    'data': data,
                    'dataType': 'json'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{
      this.refresh_view(preseizure_id);
    });
  }

  remove_entry(preseizure_id, account_id, entry_id){
    let data = { id: preseizure_id, account: account_id, entry: entry_id }

    let params =  {
                    'url': `/my_documents/preseizures/remove_entry`,
                    type: 'POST',
                    'data': data,
                    'dataType': 'json'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{
      this.refresh_view(preseizure_id);
    });
  }

  
}

jQuery(function() {
  let main = new MyDocumentsPreseizures();

  AppListenTo('documents_edit_preseizures', (e)=>{ main.edit_preseizures($(e.detail.obj)); });
  AppListenTo('documents_edit_multiple_preseizures', (e)=>{ main.edit_multiple_preseizures( e.detail.ids ); });
  AppListenTo('documents_edit_entry_account', (e)=>{ main.edit_entry_account($(e.detail.obj)); });
  AppListenTo('documents_edit_entry_amount', (e)=>{ main.edit_entry_amount($(e.detail.obj)); });
  AppListenTo('documents_change_entry_type', (e)=>{ main.change_entry_type($(e.detail.obj)); });
  AppListenTo('edit_third_party', (e)=>{ main.edit_third_party($(e.detail)); });

  $('#edit_preseizures.modal').on('shown.bs.modal', function(e){   
    $('#date-preseizure, #deadline-date-preseizure').asDateRange({ defaultBlank: true, singleDatePicker: true, locale: { format: 'YYYY-MM-DD' }});
  });
  $('#edit_preseizures.modal #preseizures_edit').unbind('click').bind('click', function(e){ main.update_preseizures(); });


  AppListenTo('new_entry', (e)=>{ main.insert_new_entry(e.detail.elt, e.detail.preseizure_id) });
  AppListenTo('remove_entry', (e)=>{ main.remove_entry(e.detail.preseizure_id, e.detail.account_id, e.detail.entry_id) });
});