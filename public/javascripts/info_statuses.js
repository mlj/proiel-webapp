// Functionality for the information status editing view

// Embed "private" variables and functions in an ExtJS-style object
var InfoStatus = function() {

    // private variables

    var classes = new Array('new', 'acc', 'acc-gen', 'acc-disc', 'acc-inf', 'old', 'no-info-status');
    var menu = null;
    var menu_dimensions = null;
    var annotatables = null;
    var selected_token = null;

    // private functions

    function setEventHandlingForAnnotatables() {
        annotatables.invoke('observe', 'click', function(event) {
            selectToken(this);
            event.stop();
        });
    }

    function setEventHandlingForInfoStatusMenu() {
        $$('div.info-menu-item').invoke('observe', 'click', function() {
            classes.each(function(klass) {
                selected_token.removeClassName(klass);
            });
            selected_token.addClassName($w(this.className).last());
        });
    }

    function setEventHandlingForDocument() {
        document.observe('click', function() {
            menu.hide();
        });
    }

    function selectToken(elm) {
        selected_token = elm;
        annotatables.invoke('removeClassName', 'info-selected');
        selected_token.addClassName('info-selected');
        showInfoStatusMenuFor(elm);
    };

    function showInfoStatusMenuFor(elm) {
        var offset = elm.cumulativeOffset();
        menu.setStyle({
            top: (offset['top'] - menu_dimensions['height']) + 'px',
            left: (offset['left'] - ((menu_dimensions['width'] - elm.getWidth()) / 2) - 2) + 'px'
        });
        menu.show();
    };

    return {

        // public functions

        init: function() {
            if(annotatables != null) {
                return;  // because the script may be included several times on the same page
            }
            menu = $('info-menu');
            annotatables = $$('span.info-annotatable');

            setEventHandlingForAnnotatables();
            setEventHandlingForInfoStatusMenu();
            setEventHandlingForDocument();

            menu_dimensions = menu.getDimensions();
        }
    }
}();

document.observe('dom:loaded', function() {
    InfoStatus.init();
});
