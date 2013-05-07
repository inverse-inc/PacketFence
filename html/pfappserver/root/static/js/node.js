"use strict";

/*
 * The Nodes class defines the operations available from the controller.
 */
var Nodes = function() {
};

Nodes.prototype.get = function(options) {
    $.ajax({
        url: options.url
    })
        .always(options.always)
        .done(options.success)
        .fail(function(jqXHR) {
            var status_msg = getStatusMsg(jqXHR);
            showError(options.errorSibling, status_msg);
        });
};

Nodes.prototype.post = function(options) {
    $.ajax({
        url: options.url,
        type: 'POST',
        data: options.data
    })
        .done(options.success)
        .fail(function(jqXHR) {
            var status_msg = getStatusMsg(jqXHR);
            showError(options.errorSibling, status_msg);
        });
};

Nodes.prototype.toggleViolation = function(options) {
    var action = options.status? "open" : "close";
    var url = ['/node',
               action,
               options.name.substr(10)];
    $.ajax({ url: url.join('/') })
        .always(options.always)
        .done(options.success)
        .fail(options.error);
};

/*
 * The NodeView class defines the DOM operations from the Web interface.
 */
var NodeView = function(options) {
    this.nodes = options.nodes;
    this.disableToggleViolation = false;

    var read = $.proxy(this.readNode, this);
    options.parent.on('click', '#nodes [href*="node"][href$="/read"]', read);

    var update = $.proxy(this.updateNode, this);
    $('body').on('submit', '#modalNode form[name="modalNode"]', update);

    var delete_node = $.proxy(this.deleteNode, this);
    $('body').on('click', '#modalNode [href$="/delete"]', delete_node);

    var read_violations = $.proxy(this.readViolations, this);
    $('body').on('show', 'a[data-toggle="tab"][href="#nodeViolations"]', read_violations);

    var toggle_violation = $.proxy(this.toggleViolation, this);
    $('body').on('switch-change', '#modalNode .switch', toggle_violation);

    var trigger_violation = $.proxy(this.triggerViolation, this);
    $('body').on('click', '#modalNode #addViolation', trigger_violation);

    /* Update the advanced search form to the next page or resort the query */
    var advanced_search_updater = $.proxy(this.advancedSearchUpdater, this);
    $('body').on('click', 'a[href*="#node/advanced_search"]', advanced_search_updater);
};

NodeView.prototype.readNode = function(e) {
    e.preventDefault();

    var section = $('#section');
    var loader = section.prev('.loader');
    loader.show();
    section.fadeTo('fast', 0.5);
    this.nodes.get({
        url: $(e.target).attr('href'),
        always: function() {
            loader.hide();
            section.stop();
            section.fadeTo('fast', 1.0);
        },
        success: function(data) {
            $('body').append(data);
            var modal = $("#modalNode");
            modal.on('shown', function() {
                modal.find('.chzn-select').chosen();
                modal.find('.chzn-deselect').chosen({allow_single_deselect: true});
                modal.find('.timepicker-default').each(function() {
                    // Keep the placeholder visible if the input has no value
                    var that = $(this);
                    var defaultTime = that.val().length? 'value' : false;
                    that.timepicker({ defaultTime: defaultTime, showSeconds: false, showMeridian: false });
                    that.on('hidden', function (e) {
                        // Stop the hidden event bubbling up to the modal
                        e.stopPropagation();
                    });
                });
                modal.find('.datepicker').datepicker({ autoclose: true });
                modal.find('[data-toggle="tooltip"]').tooltip({placement: 'right'}).click(function(e) {
                    e.preventDefault;
                    return false;
                });
            });
            modal.on('hidden', function (e) {
                if ($(e.target).hasClass('modal'))
                    $(this).remove();
            });
            modal.modal({ show: true });
        },
        errorSibling: section.find('h2').first()
    });
};

NodeView.prototype.readViolations = function(e) {
    var btn = $(e.target);
    var name = btn.attr("href");
    var target = $(name.substr(name.indexOf('#')));
    var url = btn.attr("data-href");
    if (target.children().length == 0)
        target.load(btn.attr("data-href"), function() {
            target.find('.switch').bootstrapSwitch();
        });
    return true;
};

NodeView.prototype.toggleViolation = function(e) {
    e.preventDefault();

    // Ignore event if it occurs while processing a toggling
    if (this.disableToggleViolation) return;
    this.disableToggleViolation = true;

    var that = this;
    var btn = $(e.target);
    var name = btn.find('input:checkbox').attr('name');
    var status = btn.bootstrapSwitch('status');
    var pane = $('#nodeViolations');
    resetAlert(pane.parent());
    this.nodes.toggleViolation({
        name: name,
        status: status,
        success: function(data) {
            showSuccess(pane.children().first(), data.status_msg);
            that.disableToggleViolation = false;
        },
        error: function(jqXHR) {
            var status_msg = getStatusMsg(jqXHR);
            showError(pane.children().first(), status_msg);
            // Restore switch state
            btn.bootstrapSwitch('setState', !status, true);
            that.disableToggleViolation = false;
        }
    });
};

NodeView.prototype.updateNode = function(e) {
    e.preventDefault();

    var modal = $('#modalNode');
    var modal_body = modal.find('.modal-body').first();
    var form = modal.find('form').first();
    var btn = form.find('[type="submit"]').first();
    var valid = isFormValid(form);
    if (valid) {
        resetAlert(modal_body);
        btn.button('loading');

        this.nodes.post({
            url: form.attr('action'),
            data: form.serialize(),
            always: function() {
                btn.button('reset');
            },
            success: function(data) {
                modal.on('hidden', function() {
                    $(window).hashchange();
                });
                modal.modal('hide');
            },
            errorSibling: modal_body.children().first()
        });
    }
};

NodeView.prototype.deleteNode = function(e) {
    e.preventDefault();

    var modal = $('#modalNode');
    var modal_body = modal.find('.modal-body');
    var btn = $(e.target);
    var url = btn.attr('href');
    this.nodes.get({
        url: url,
        success: function(data) {
            modal.modal('hide');
            modal.on('hidden', function() {
                $(window).hashchange();
            });
        },
        errorSibling: modal_body.children().first()
    });
};

NodeView.prototype.triggerViolation = function(e) {
    e.preventDefault();

    var modal = $('#modalNode');
    var modal_body = modal.find('.modal-body');
    var btn = $(e.target);
    var href = btn.attr('href');
    var vid = modal.find('#vid').val();
    var pane = $('#nodeViolations');
    resetAlert(pane);
    this.nodes.get({
        url: [href, vid].join('/'),
        success: function(data) {
            pane.html(data);
            pane.find('.switch').bootstrapSwitch();
        },
        errorSibling: pane.children().first()
    });
};

NodeView.prototype.advancedSearchUpdater = function(e) {
    e.preventDefault();
    var link = $(e.currentTarget);
    var form = $('#advancedSearch');
    var href = link.attr("href");
    if(href) {
        href = href.replace(/^.*#node\/advanced_search\//,'');
        var values = href.split("/");
        for(var i =0;i<values.length;i+=2) {
            var name = values[i];
            var value = values[i + 1];
            form.find('[name="' + name + '"]:not(:disabled)').val(value);
        }
        form.submit();
    }
    return false;
};
