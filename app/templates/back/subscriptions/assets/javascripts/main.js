class SubscriptionAdmin{
  constructor(){ }

  load_events(){
    $('#statistic_table #period').unbind('change.search').bind('change.search', function(e){
      window.location.href = `/admin/subscriptions?p=${ $(this).val() }`;
    });

    $('#statistic_table .search_organization').unbind('keyup.search').bind('keyup.search', function(e){
      let keycode = e.keyCode;
      let pattern = $(this).val();

      if(pattern == '')
        $('#statistic_table tr.loaded').removeClass('hide');

      if(keycode == '13')
      {
        if(pattern == '')
        {
          $('#statistic_table tr.loaded').removeClass('hide');
        }
        else
        {
          $('#statistic_table tr.loaded').addClass('hide');

          $('#statistic_table tr.loaded').each(function(e){
            let td_name = $(this).find('td.information.name').text();
            let td_code = $(this).find('td.information.code').text();
            let reg       = new RegExp(pattern, 'gi');

            if( reg.test(td_name) || reg.test(td_code) )
              $(this).removeClass('hide');
          });
        }
      }
    });

    $('table td .do-showAccounts').unbind('click.show').bind('click.show', function(e){
      let app    = new ApplicationJS();

      let type   = $(this).parent().attr('class').replace('subscription', '').replace('options', '').trim();
      let org_id = $(this).attr('org_id');

      let param = type

      if( org_id )
        param = `${param}?org_id=${org_id.trim()}`

      let ajx_param = {
                        url: `/admin/subscriptions/accounts/${param}`,
                        type: 'post',
                      }

      app.sendRequest(ajx_param).then(e => {
        let modal = $('#showAccounts.modal');
        modal.modal('show');
        modal.find('.modal-header h3').html( $(`#recapitulation th.${type}_title`).text() );
        modal.find('.modal-body').html(e);
      });
    });
  }

  calculate_total(){
    let counts      = {};

    $('#statistic_table tbody tr.loaded td').each(function(e){
      if( $(this).hasClass('subscription') || $(this).hasClass('clients') || $(this).hasClass('options') )
      {
        let class_type = $(this).attr('class').replace('subscription', '').replace('clients', '').replace('options', '').trim();
        let count      = parseInt( $(this).text() );

        try{
          if( isNaN(counts[class_type]) ){
            counts[class_type] = count;
          }else{
            counts[class_type] = counts[class_type] + count;
          }
        }
        catch(e){
          counts[class_type] = count;
        }

        $(`#statistic_table tr.total td.${class_type}`).html(counts[class_type]);
      }
    });
  }

  load_datas(){
    let self = this;

    let waiting_datas = $('tr.waiting_datas');

    if( waiting_datas.length > 0)
    {
      waiting_datas.each(function(e){
        let loaded_data = $(this).find('tr.loaded').html();

        if(loaded_data){
          $(this).removeClass('waiting_datas');
          $(this).addClass('loaded');
          $(this).html(loaded_data);
        }
      });

      setTimeout((e)=>{ self.load_datas() }, 1000);
    }
    else
    {
      self.calculate_total();
      AppLoading('hide');
    }
  }
}

jQuery(function() {
  let app = new SubscriptionAdmin();

  AppLoading('show');
  app.load_datas();

  AppListenTo('window.application_auto_rebind', (e)=>{ app.load_events() });
});