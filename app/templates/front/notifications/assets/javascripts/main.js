class NotifierMain{
  constructor(){
    this.applicationJS = new ApplicationJS();
  }

  get_latest_notification(){
    let ajax_params = {
                        url: '/notifications/latest',
                        type: 'GET',
                        dataType: 'html',
                        no_loading: true
                      }

    this.applicationJS.sendRequest(ajax_params)
                       .then((e)=>{
                          $('#notifications_notifier').html(e);
                          let unread_count = $(e).find('input#unread_count').val();

                          if(unread_count > 0){
                            $('span#notification_count').text(unread_count);
                            $('span#notification_count').css('display', 'inline-block');
                          }else{
                            $('span#notification_count').css('display', 'none');
                          }
                       });
  }

  see_all_notification(page = 1){
    let ajax_params = {
                        url: `/notifications?page=${page}&per_page=10`,
                        type: 'GET',
                        dataType: 'html',
                      }

    this.applicationJS.sendRequest(ajax_params)
                       .then((e)=>{
                          $('.modal#all_notifications .modal-body').html(e);
                          $('.modal#all_notifications').modal('show');
                       });
  }
}

jQuery(function() {
  let main = new NotifierMain();

  main.get_latest_notification();
  // window.setInterval((e)=>{ main.get_latest_notification(); }, (60*1000)); //every 60 seconds

  AppListenTo('window.change-page.notifications', (e)=>{ main.see_all_notification(e.detail.page) });

  $('#see_all_notifications button#see_all').unbind('click').bind('click', function(e){ main.see_all_notification(); });
});