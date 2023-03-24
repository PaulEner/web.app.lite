//=require './step1'
//=require './step2'
//=require './step3'
//=require './step4'

class ConfigurationSteps{
  constructor(){
    this.applicationJS = new ApplicationJS();
    this.budgeaApi     = new BudgeaApi();

    this.current_step        = 1;
    this.current_step_object = null;
    this.current_connector   = null;

    this.main_modal       = $('.modal#add-retriever');
    this.primary_button   = $('.modal#add-retriever button.primary');
    this.secondary_button = $('.modal#add-retriever button.secondary');

    this.objectStep1   = new ConfigurationStep1(this);
    this.objectStep2   = new ConfigurationStep2(this);
    this.objectStep3   = new ConfigurationStep3(this);
    this.objectStep4   = new ConfigurationStep4(this, this.main_modal.find('#step4'));
  }

  primary_action(){
    this.current_step_object.primary_action();
  }

  secondary_action(){
    this.current_step_object.secondary_action();
  }

  goto(step=1, params={}){
    this.current_step = step;
    this.main_modal.find('.steps').addClass('hide');
    this.main_modal.find(`.step${step}`).removeClass('hide');

    if(this.current_step == 1)
    {
      this.current_connector = null;
      this.current_step_object = this.objectStep1;
      this.primary_button.text('Suivant');
      this.secondary_button.attr('disabled', 'disabled');
      this.secondary_button.text('Précédent');
    }
    else if(this.current_step == 2)
    {
      this.current_step_object = this.objectStep2;
      this.primary_button.text('Suivant');
      this.secondary_button.removeAttr('disabled');
      this.secondary_button.text('Précédent');

      this.current_step_object.init_form(params);
    }
    else if(this.current_step == 3)
    {
      this.current_step_object = this.objectStep3;
      this.primary_button.text('Suivant');
      this.secondary_button.attr('disabled', 'disabled');
      this.secondary_button.text('Précédent');

      this.current_step_object.init_form(params);
    }
    else if(this.current_step == 4)
    {
      this.current_step_object = this.objectStep4;
      this.primary_button.text('Valider');
      this.secondary_button.removeAttr('disabled');
      this.secondary_button.text('Plus tard');

      this.current_step_object.init_form(params)
    }
  }

  edit_retriever(retriever=null){
    this.goto(1);
    this.current_step_object.init_form(retriever);
  }

  delete_connection(id){
    if(confirm('Voulez vous vraiment supprimer cette automate? La suppression peut prendre un moment.')){
      this.budgeaApi.delete_connection(id)
                    .then((e)=>{ this.applicationJS.noticeSuccessMessageFrom(null, 'Suppression terminée'); AppEmit('retriever_reload_all'); })
                    .catch((e)=>{ this.applicationJS.noticeErrorMessageFrom(null, e.toString()); AppEmit('retriever_reload_all'); });
    }
  }

  trigger_connection(id){
    if(confirm('Voulez vous vraiment synchroniser cette automate? La synchronisation peut prendre un moment.')){
      this.budgeaApi.trigger_connection(id)
                    .then((e)=>{ this.applicationJS.noticeSuccessMessageFrom(null, 'Synchronisation terminée'); AppEmit('retriever_reload_all'); })
                    .catch((e)=>{ this.applicationJS.noticeErrorMessageFrom(null, e.toString()); AppEmit('retriever_reload_all'); });
    }
  }
}

jQuery(function() {
  let main = new ConfigurationSteps();

  AppListenTo('retriever_delete_connection',  (e)=>{ main.delete_connection(e.detail.id) });
  AppListenTo('retriever_trigger_connection', (e)=>{ main.trigger_connection(e.detail.id) });
  AppListenTo('retriever_edit_connection',    (e)=>{ main.edit_retriever(e.detail.retriever); });

  AppListenTo('add_retriever_primary_action',   (e)=>{ main.primary_action(); });
  AppListenTo('add_retriever_secondary_action', (e)=>{ main.secondary_action(); });

  /** Listener Step1 **/
    AppListenTo('add_retriever_search_connector', (e)=>{ main.current_step_object.fill_connectors(); });
    AppListenTo('add_retriever_connector_selection',  (e)=>{ main.current_step_object.select_connector(); });
});