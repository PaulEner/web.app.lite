jQuery(function() {
  $('a.do-showInvoice').unbind('click').bind('click', function(e) {
    var $invoiceDialog;
    e.preventDefault();
    $invoiceDialog = $('#showInvoice');
    $invoiceDialog.find('h3').text($(this).attr('title'));
    $invoiceDialog.find("iframe").attr('src', $(this).attr('href'));
    $invoiceDialog.modal('show');
  });

  $('.select-date.requested_at').unbind('change').bind('change', function(e) {
    var data, number;
    number = $(this).parents('tr').attr('id').split('_')[1];
    data = {
      invoice: {
        requested_at: $(this).val()
      }
    };
    return $.ajax({
      url: "/admin/invoices/" + number + ".json",
      data: data,
      datatype: 'json',
      type: 'PATCH'
    });
  });

  $('.select-date.received_at').unbind('change').bind('change', function(e) {
    var data, number;
    number = $(this).parents('tr').attr('id').split('_')[1];
    data = {
      invoice: {
        received_at: $(this).val()
      }
    };
    return $.ajax({
      url: "/admin/invoices/" + number + ".json",
      data: data,
      datatype: 'json',
      type: 'PATCH'
    });
  });

  $("#check_all").unbind('change').bind('change', function(e) {
    return $(".invoices").prop('checked', $(this).prop('checked'));
  });

  $('.filter-news').unbind('click').bind('click', function(e){ $('.modal#filter-invoices').modal('show'); });
  $('.sepa-order').unbind('click').bind('click', function(e){ $('.modal#sepa-order').modal('show'); });
});