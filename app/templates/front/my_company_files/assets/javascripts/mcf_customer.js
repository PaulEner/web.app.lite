class McfCustomer{
  constructor(){
    this.applicationJS = new ApplicationJS;
  }

  show_mcf_edition(url){
    const edit_mcf = $('#edit_mcf_customer_modal.modal');
    AppLoading('show');
    this.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      edit_mcf.find('.modal-body').html($(element).find('#customer.edit.mcf').html());
      edit_mcf.modal('show');

      this.get_users_mcf_list();
    }).catch((error)=> { 
      console.error(error);
    });
  }

  get_users_mcf_list(){
    let user_mcf_storage = $('#user_mcf_storage');
    this.applicationJS.sendRequest({ 'url': user_mcf_storage.data('users-list-url'), 'dataType': 'json' }).then((elements)=>{
      let original_value = $('#user_mcf_storage').data('original-value') || '';

      elements.forEach((d)=>{
        let option = '';
        if (original_value.length > 0 && original_value === d['id']){
          option = `<option value="${d['id']}" selected="selected">${d['name']}</option>`;
        }
        else{
          option = `<option value="${d['id']}">${d['name']}</option>`;
        }

        user_mcf_storage.append(option);
        user_mcf_storage.show();

        $('button.validate_user_mcf_storage').removeAttr('disabled');
        AppLoading('hide');
      });
    }).catch((error)=> {
      user_mcf_storage.after(`<span class="badge bg-danger error">Erreur : ${error} ==> connexion non autorisé à accéder à My Company Files</span>`);
      AppLoading('hide');
    });
  }
}