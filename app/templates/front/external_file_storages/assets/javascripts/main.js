class EFSMain{
  constructor(){
    this.applicationJS = new ApplicationJS();
  }

  use_service(e){
    let elem    = e.detail.element
    let service = elem.attr('id').split('_')[1];
    let is_used = elem.is(":checked");

    if(is_used)
      $(".service_config_"+service).show();
    else
      $(".service_config_"+service).hide();

    let datas = { service: service, is_enable: is_used };
    
    e.set_key('datas', datas);
  }
}

jQuery(function() {
  let main = new EFSMain();

  AppListenTo('efs_init_enabling_service', (e)=>{ main.use_service(e); });
});