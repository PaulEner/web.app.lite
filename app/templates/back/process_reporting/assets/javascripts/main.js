class AdminProcessReporting {
  constructor(){
    this.applicationJS  = new ApplicationJS;        
  }

  finalize_process(){
    let result = [0,0,0,0,0,0,0,0,0,0,0];

    $('#process_reporting .organization_list tr.row_organizations').each(function(e){
      $('td.raw_text', this).each(function(index, val){
        let raw_text = $(this).text();

        if (parseInt(raw_text) >= 0){
          result[index] += parseInt(raw_text)
        }

      })
    });       

    $('#process_reporting .organization_list').append('<tr id="process_reporting-total-appended" style="opacity:1;"></tr>');
      $('#process_reporting .organization_list tr').last().append('<td>Total</td>');

    $(result).each(function(){
      $('#process_reporting .organization_list tr#process_reporting-total-appended').last().append('<td class="aligncenter"><b>' + this + '</b></td>')
    });   
  }

  get_data(){
    let self = this;
    let date = new Date();
    let url_location = window.location.href;
    let raw_element = url_location.split('reporting')[1];
    let element = raw_element.split('/');
    let current_year = element[1];
    let current_month = element[2];
    let elements_count = $('#process_reporting .organization_list tr.row_organizations').size();

    $('#process_reporting .organization_list tr.row_organizations').each(function(e){
      let organization_id = $(this).attr('id').split('-')[1];

      let ajax_params =  {
                  'url': '/admin/process_reporting/process_reporting_table',
                  'type': 'GET',
                  'data': { organization_id: organization_id, year: current_year, month: current_month },                  
                  'contentType': 'application/json'
                };

      self.applicationJS.sendRequest(ajax_params).then((result)=>{
        $("#process_reporting .organization_list tr#row-" + organization_id).html(result);

        if(elements_count > 1)
          elements_count -= 1
        else
          window.setTimeout(self.finalize_process, 1000);
      });
    });
  }

  main() {
    this.get_data();    
  }  
}

jQuery(function() {
  let admin_pr = new AdminProcessReporting();
  admin_pr.main();
});