//= require ckeditor/config

class AdminNews {
  constructor(){
    this.applicationJS      = new ApplicationJS;    
    this.news_filter_modal  = $('#filter-news.modal');
    this.news_modal         = $('#news-modal.modal');
  }

  load_news(id=0, read_only=false){
    let self = this;

    let url = '/admin/news/new'

    if (id != 0)
      url = '/admin/news/'+ id +'/edit'

    if (read_only)
      url = '/admin/news/'+ id

    let ajax_params = {
                        url: url,
                        type: 'GET',
                        dataType: 'html',
                      }

    self.applicationJS.sendRequest(ajax_params).then((e)=>{
      self.news_modal.find('.modal-body').html(e);

      self.news_modal.modal('show');
    });
  }

  load_events(){
    let self = this;

    $('.filter-news').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.news_filter_modal.modal('show');
    });

    $('.new-news').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_news();
    });


    $('.edit-news').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_news($(this).data('id'));
    });

    $('.view-news').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_news($(this).data('id'), true);
    });
  }

  main() {
    this.load_events();    
  }
}

jQuery(function() {
  let news = new AdminNews();
  news.main();

  bind_globals_events();

  AppListenTo('update_email_content', (e)=>{
    for ( instance in CKEDITOR.instances )
    {
      CKEDITOR.instances[instance].updateElement();
    }
  });
});
