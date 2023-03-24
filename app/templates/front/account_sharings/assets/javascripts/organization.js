//=require './organization_events'

class AccountSharingsOrganization{
  constructor(){
    this.applicationJS   = new ApplicationJS();
    this.organization_id = $('input#organization_id').val();

    this.base_url        = `/account_sharings/organization/${this.organization_id}`
    this.current_form    = 'contact'
  }

  load_all(){
    this.load_accounts();
    this.load_contacts();
  }

  validate_sharing(){
    if(this.current_form == 'account')
      this.validate_account();
    else
      this.validate_contact();
  }


  load_accounts(page=1, per_page=20){
    let ajax_params = {
                        url: `${this.base_url}/accounts?page=${page}&per_page=${per_page}`,
                        type: 'GET',
                        dataType: 'html',
                      }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.tab-pane#shared_accounts').html(e); });
  }

  load_contacts(page=1, per_page=20){
    let ajax_params = {
                        url: `${this.base_url}/contacts?page=${page}&per_page=${per_page}`,
                        type: 'GET',
                        dataType: 'html',
                      }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.tab-pane#contacts').html(e); });
  }

  add_account(){
    let ajax_params = {
                        url: `${this.base_url}/new_account`,
                        type: 'GET',
                        dataType: 'html',
                      }

    this.applicationJS.sendRequest(ajax_params)
                      .then((e)=>{
                        this.current_form = 'account';
                        $('.modal#account-sharing .modal-title').html('Partager un dossier');
                        $('.modal#account-sharing .modal-body').html(e);
                        $('.modal#account-sharing').modal('show');
                      });
  }

  validate_account(){
    let data = $(`.modal#account-sharing form#shared_accounts_form`).serializeObject();
    let ajax_params = {
                        url: `${this.base_url}/create_account`,
                        type: 'POST',
                        dataType: 'json',
                        data: data
                      }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.modal#account-sharing').modal('hide'); this.load_accounts( 1, $('.per_page.sharing_accounts').val() ); });
  }

  edit_contact(id=0){
    this.contact_id = id;

    console.log(id);

    let url = '/new_contact'
    if(id > 0)
      url = `/edit_contact/${id}`

    let ajax_params = {
                        url: `${this.base_url}${url}`,
                        type: 'GET',
                        dataType: 'html',
                      }

    this.applicationJS.sendRequest(ajax_params)
                      .then((e)=>{
                        this.current_form = 'contact';
                        $('.modal#account-sharing .modal-title').html('Edition de contact');
                        $('.modal#account-sharing .modal-body').html(e);
                        $('.modal#account-sharing').modal('show');
                      });
  }

  validate_contact(){
    let url = '/create_contact'
    if(this.contact_id > 0)
      url = `/update_contact/${this.contact_id}`

    let data = $(`.modal#account-sharing form#shared_contacts_form`).serializeObject();
    let ajax_params = {
                        url: `${this.base_url}${url}`,
                        type: 'POST',
                        dataType: 'json',
                        data: data
                      }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.modal#account-sharing').modal('hide'); this.load_contacts( 1, $('.per_page.sharing_contacts').val() ); });
  }

}

jQuery(function() {
  let main = new AccountSharingsOrganization();

  main.load_all();

  AppListenTo('account_sharings_add_account', (e)=>{ main.add_account() });
  AppListenTo('account_sharings_edit_contact', (e)=>{ main.edit_contact(e.detail.id) });

  AppListenTo('account_sharings_validate_sharing', (e)=>{ main.validate_sharing() });

  AppListenTo('window.change-per-page.sharing_accounts', (e)=>{ main.load_accounts(e.detail.page, e.detail.per_page) });
  AppListenTo('window.change-page.sharing_accounts', (e)=>{ main.load_accounts(e.detail.page, e.detail.per_page) });

  AppListenTo('window.change-per-page.sharing_contacts', (e)=>{ main.load_contacts(e.detail.page, e.detail.per_page) });
  AppListenTo('window.change-page.sharing_contacts', (e)=>{ main.load_contacts(e.detail.page, e.detail.per_page) });
});