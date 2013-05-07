    /* Section ready */
    $('#section').on('section.loaded', function(event) {
        /* Initialize the action field */
        $('#ruleActions tr:not(.hidden) select[name$=type]').each(function() {
            updateAction($(this));
        });
        /* Disable checked columns from import tab since they are required */
        $('#columns :checked').attr('disabled', 'disabled');
    });

    /* Create user(s) */
    $('#section').on('submit', 'form[name="users"]', function(event) {
        var form = $(this),
        btn = form.find('[type="submit"]'),
        disabled_inputs = form.find('.hidden :input, .tab-pane:not(.active) :input'),
        valid;

        // Don't submit inputs from hidden rows and tabs.
        // The functions isFormValid and serialize will ignore disabled inputs.
        disabled_inputs.attr('disabled', 'disabled');

        // Identify the type of creation (single, multiple or import) from the selected tab
        form.find('input[name="type"]').val($('.nav-tabs .active a').attr('href').substring(1));
        valid = isFormValid(form);

        if (valid) {
            btn.button('loading');
            resetAlert($('#section'));

            // Since we can be uploading a file, the form target is an iframe from which
            // we read the JSON returned by the server.
            var iform = $("#iframe_form");
            iform.one('load', function(event) {
                // Restore disabled inputs
                disabled_inputs.removeAttr('disabled');

                $("body,html").animate({scrollTop:0}, 'fast');
                btn.button('reset');
                var body = $(this).contents().find('body');
                if (body.find('form').length) {
                    // We received a HTML form
                    var modal = $('#modalPasswords');
                    modal.empty();
                    modal.append(body.children());
                    modal.modal({ backdrop: 'static', shown: true });
                }
                else {
                    // We received JSON
                    var data = $.parseJSON(body.text());
                    if (data.status < 300)
                        showPermanentSuccess(form, data.status_msg);
                    else
                        showPermanentError(form, data.status_msg);
                }
            });
        }
        else {
            // Restore disabled inputs
            disabled_inputs.removeAttr('disabled');
        }

        return valid;
    });

    /* Print passwords */
    $('#section').on('click', '#modalPasswords a[href$="print"]', function(event) {
        var btn = $(this);
        var form = btn.closest('form');
        form.attr('action', btn.attr('href'));
        form.attr('target', '_blank');
        form.submit();

        return false;
    });

    /* Send passwords by email */
    $('#section').on('click', '#modalPasswords a[href$="mail"]', function(event) {
        var btn = $(this);
        var form = btn.closest('form');
        var modal_body = form.find('.modal-body');

        btn.button('loading');
        $.ajax({
            type: 'POST',
            url: btn.attr('href'),
            data: form.serialize()
        })
        .always(function() {
            $("body,html").animate({scrollTop:0}, 'fast');
            btn.button('reset');
            resetAlert(modal_body);
        })
        .done(function(data) {
            showSuccess(modal_body.children().first(), data.status_msg);
        })
        .fail(function(jqXHR) {
            var status_msg = getStatusMsg(jqXHR);
            showPermanentError(modal_body.children().first(), status_msg);
        });

        return false;
    });
