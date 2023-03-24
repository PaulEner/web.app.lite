//=require './sortable_dom'

jQuery(function() {
  // IMPORTANT: position represent the default position of the node element
  var piece_name_nodes =  [ 
                            { name: 'code', position: 100 },
                            { name: 'code_wp', position: 101 },
                            { name: 'journal', position: 102 },
                            { name: 'period', position: 103 },
                            { name: 'number', position: 104 }
                          ];
  var sortable_piece_name = new SortableDom('piece_name', piece_name_nodes);


  // IMPORTANT: position represent the default position of the node element
  var description_nodes = [ 
                            { name: 'operation_label', position: 100 },
                            { name: 'date', position: 101 },
                            { name: 'third_party', position: 102 },
                            { name: 'amount', position: 103 },
                            { name: 'currency', position: 104 },
                            { name: 'conversion_rate', position: 105 },
                            { name: 'observation', position: 106 },
                            { name: 'journal', position: 107 },
                            { name: 'piece_name', position: 108 },
                            { name: 'piece_number', position: 109 },
                          ];
  var sortable_description = new SortableDom('description', description_nodes);


  sortable_piece_name.init();
  sortable_description.init();
});