//= require './events'
//= require './statistics'

// TODO - LOADER TO CLASS
function load_reporting_invoices(){
  let applicationJS = new ApplicationJS();

  // console.log($('.reporting #customer_filter').val());
  let customers_ids   = $('.reporting #customer_filter').val();
  let ajax_params = {
                      url: `/reporting/invoices`,
                      type: 'POST',
                      data : `ids=${customers_ids}`,
                      dataType: 'html',
                    }

  VARIABLES['reporting_loading']++;
  applicationJS.sendRequest(ajax_params).then(e=>{ 
    $('.reporting #invoices').html(e);

    VARIABLES['reporting_loading']--;
    if(VARIABLES['reporting_loading'] <= 0){
      VARIABLES['reporting_loading'] = 0;
      VARIABLES['reporting_customer_change'] = false;
      AppLoading('hide');
    }
  });
}

function handle_customer_change(statistics){
  if(!VARIABLES['reporting_customer_change'])
  {
    VARIABLES['reporting_customer_change'] = true;

    try{ clearTimeout(VARIABLES['reporting_customer_change_timer']); }catch(e){ console.log(e) };
    VARIABLES['reporting_customer_change_timer'] = null;

    VARIABLES['reporting_customer_change_timer'] = setTimeout(()=>{
                                                                    AppLoading('show');

                                                                    load_reporting_invoices();

                                                                    if( $('li.reporting_links.statistics').hasClass('active') )
                                                                    {
                                                                      statistics.load_all();
                                                                    }
                                                                    else
                                                                    {
                                                                      $('li.reporting_links.statistics').addClass('need_refresh');
                                                                    }
                                                                  }, 2000);
  }
}


jQuery(function() {
  let statistics  = new ReportingStatistics();

  VARIABLES['reporting_loading'] = 0;
  VARIABLES['reporting_customer_change'] = false;

  handle_customer_change(statistics);

  AppListenTo('reporting_load_statistics', (e)=>{ 
    VARIABLES['reporting_loading'] = 0;
    VARIABLES['reporting_customer_change'] = true;

    AppLoading('show');
    statistics.load_all();
  });
  AppListenTo('reporting_load_all', (e)=>{ handle_customer_change(statistics); });
  AppListenTo('export_xls', (e)=>{ statistics.export_xls(e.detail.action)});



});
