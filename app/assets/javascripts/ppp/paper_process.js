(function() {
  var create_return_labels, day, isKitFormValid, month, new_return_labels, year;

  year = function() {
    return $('#date_year').val();
  };

  month = function() {
    return $('#date_month').val();
  };

  day = function() {
    return $('#date_day').val();
  };

  create_return_labels = function() {
    return $.ajax({
      url: "/scans/return_labels/" + (year()) + "/" + (month()) + "/" + (day()),
      data: $('#returnLabelsForm .form').serialize(),
      datatype: 'json',
      type: 'POST',
      success: function(data) {
        $('#returnLabelsForm input[type=submit]').removeClass('disabled');
        return $('#returnLabelsDialog iframe').attr('src', '/scans/return_labels');
      }
    });
  };

  new_return_labels = function() {
    $('#returnLabelsForm').html('');
    $('#returnLabelsDialog iframe').attr('src', '');
    return $.ajax({
      url: "/scans/return_labels/new/" + (year()) + "/" + (month()) + "/" + (day()),
      data: {},
      datatype: 'json',
      type: 'GET',
      success: function(data) {
        $('#returnLabelsForm').html(data);
        return $('#returnLabelsForm input[type=submit]').click(function(e) {
          e.preventDefault();
          if (!$(this).hasClass('disabled')) {
            $(this).addClass('disabled');
            return create_return_labels();
          }
        });
      }
    });
  };

  isKitFormValid = function(customer_codes) {
    var good;
    good = true;
    if ($('#paper_process_tracking_number').val().length < 13) {
      good = false;
    }
    if ($.inArray($('#paper_process_customer_code').val(), customer_codes) === -1) {
      good = false;
    }
    if (parseInt($('#paper_process_journals_count').val()) <= 0) {
      good = false;
    }
    if (parseInt($('#paper_process_periods_count').val()) <= 0) {
      good = false;
    }
    if (parseInt($('#paper_process_order_id').val()) <= 0) {
      good = false;
    }
    return good;
  };

  initJS = function(){
    var base, customer_codes;
    if ($('#kits').length > 0) {
      base = 'kits';
    }
    if ($('#receipts').length > 0) {
      base = 'receipts';
    }
    if ($('#scans').length > 0) {
      base = 'scans';
    }
    if ($('#returns').length > 0) {
      base = 'returns';
    }

    $('.date select').unbind('change.ppp').bind('change.ppp', function() {
      return window.location.href = "/" + base + "/" + (year()) + "/" + (month()) + "/" + (day());
    });

    $('#paper_process_tracking_number').unbind('keyup.ppp').bind('keyup.ppp', function() {
      if ($(this).val().length === 13) {
        return $('#paper_process_customer_code').focus();
      }
    });

    if ($('#kits, #receipts, #returns').length > 0) {
      customer_codes = $('#kits, #receipts, #returns').data('codes');
      $('#paper_process_customer_code').unbind('keyup.ppp').bind('keyup.ppp', function() {
        if ($.inArray($(this).val(), customer_codes) >= 0) {
          if ($('#kits').length > 0) {
            return $('#paper_process_journals_count').focus();
          } else if ($('#receipts').length > 0) {
            return $('#new_paper_process').submit();
          } else if ($('#returns').length > 0) {
            return $('#paper_process_letter_type').focus();
          }
        }
      });

      if ($('#kits').length > 0) {
        $(window).unbind('keydown.ppp').bind('keydown.ppp', function(event) {
          if ((event.keyCode === 13) && (isKitFormValid(customer_codes) === false)) {
            event.preventDefault();
            return false;
          }
        });
      }
    }

    $('.ppp-filter').unbind('click.ppp').bind('click.ppp', function(e){
      e.preventDefault();
      $('#ppp-filter.modal').modal('show');
    });

    $('#paper_process_letter_type').unbind('keyup.ppp').bind('keyup.ppp', function() {
      var val;
      val = $(this).val();
      if (val === '5' || val === '500') {
        $(this).val('500');
        return $('#new_paper_process').submit();
      } else if (val === '1' || val === '1000') {
        $(this).val('1000');
        return $('#new_paper_process').submit();
      } else if (val === '3' || val === '3000') {
        $(this).val('3000');
        return $('#new_paper_process').submit();
      }
    });

    return $('#returnLabelsDialog').on('shown.bs.modal', function() {
      return new_return_labels();
    });
  }

  jQuery(function() {
    initJS();
    AppListenTo('paper_set_order_reset_filter', (e)=>{
      $('#filter-documents-selection-form').trigger("reset");
    });

    AppListenTo('window.application_auto_rebind', (e)=>{ initJS() });
  });

}).call(this);