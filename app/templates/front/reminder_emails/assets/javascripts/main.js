jQuery(function() {
  AppListenTo('update_reminder_email_content', (e)=>{
    for ( instance in CKEDITOR.instances )
    {
      CKEDITOR.instances[instance].updateElement();
    }
  });
});