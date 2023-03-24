class NewsMain{
  constructor(){
    this.applicationJS = new ApplicationJS();
  }

  get_latest_news(){
    let ajax_params = {
                        url: '/news',
                        type: 'GET',
                        dataType: 'html',
                        no_loading: true
                      }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ 
        $('#news_box').append(e);

        let step  = 1000; //1 seconds
        let delay = 0;
        $('.toast.new').each(function(e){
          delay = delay + step;
          setTimeout(()=>{
            $(this).toast('show');
            $(this).removeClass('new');
            $(this).addClass('derivationRight');
          }, delay);
        })
    });
  }
}

jQuery(function() {
  let main = new NewsMain();

  setTimeout(()=>{ main.get_latest_news(); }, 1000);
});