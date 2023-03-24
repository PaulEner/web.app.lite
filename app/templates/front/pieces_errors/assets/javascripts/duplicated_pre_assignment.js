class DuplicatedPreAssignment{
  constructor(mainJS){
    this.main = mainJS;
  }

  update_duplicated_preseizures(type='unlock_preseizures'){
    let preseizures_ids = []
    $('table input.check-piece-duplicated').each((e, elem)=>{
      if($(elem).is(':checked')){
        preseizures_ids.push($(elem).data('value'));
      }
    });

    let confirm_mess = 'Voulez vous vraiment ignorer les pièces séléctionnées?';
    let data         = { duplicate_ids: preseizures_ids, approve_block: '1' };

    if(type == 'unlock_preseizures'){
      confirm_mess = 'Voulez vous vraiment débloquer les doublons séléctionnées?';
      data         = { duplicate_ids: preseizures_ids, unblock: '1' };
    }

    if(confirm(confirm_mess)){
      let ajax_params = {
                          'url': '/pieces/update_duplicated_preseizures',
                          'data': data,
                          'type': 'POST',
                          'dataType': 'json'
                        };

      this.main.applicationJS.sendRequest(ajax_params).then((e)=>{ this.main.load_datas('duplicated-pre-assignment'); });
    }
  }
}