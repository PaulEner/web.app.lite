class IgnoredPreAssignment{
  constructor(mainJS){
    this.main = mainJS;
  }

  update_ignored_pieces(type='force_pre_assignment'){
    let piece_ids = []
    $('table input.check-piece-ignored').each((e, elem)=>{
      if($(elem).is(':checked')){
        piece_ids.push($(elem).data('value'));
      }
    });

    let confirm_mess = 'Voulez vous vraiment ignorer les pièces séléctionnées?';
    let data         = { ignored_ids: piece_ids, confirm_ignorance: '1' };

    if(type == 'force_pre_assignment'){
      confirm_mess = 'Voulez vous vraiment forcer la pré-affectation des pièces séléctionnées?';
      data         = { ignored_ids: piece_ids, force_pre_assignment: '1' };
    }

    if(confirm(confirm_mess)){
      let ajax_params = {
                          'url': '/pieces/update_ignored_pieces',
                          'data': data,
                          'type': 'POST',
                          'dataType': 'json'
                        };

      this.main.applicationJS.sendRequest(ajax_params).then((e)=>{ this.main.load_datas('ignored-pre-assignment'); });
    }
  }
}