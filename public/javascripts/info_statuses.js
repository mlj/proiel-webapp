// Functionality for the information status editing view

// Embed "private" variables and functions in an ExtJS-style object
var InfoStatus = function() {

    // private variables

    var classes = new Array('new', 'acc', 'acc-gen', 'acc-disc', 'acc-inf', 'old', 'no-info-status');
    var menu = null;
    var menu_dimensions = null;
    var annotatables = null;
    var selected_token = null;
    const FIRST_NUMERICAL_CODE = 49; // keycode for the 1 key

    // private functions

    function setEventHandlingForAnnotatables() {
        annotatables.invoke('observe', 'click', function(event) {
            selectToken(this);
            event.stop();
        });
    }

    function selectToken(elm) {
        selected_token = elm;
        annotatables.invoke('removeClassName', 'info-selected');
        selected_token.addClassName('info-selected');
        showInfoStatusMenuFor(elm);
    }

    function showInfoStatusMenuFor(elm) {
        var offset = elm.cumulativeOffset();
        menu.setStyle({
            top: (offset['top'] - menu_dimensions['height']) + 'px',
            left: (offset['left'] - ((menu_dimensions['width'] - elm.getWidth()) / 2) - 2) + 'px'
        });
        menu.show();
    }

    function setEventHandlingForInfoStatusMenu() {
        $$('div.info-menu-item').invoke('observe', 'click', function() {
            setInfoStatusClass($w(this.className).last());
        });
    }

    function setInfoStatusClass(klass) {
        classes.each(function(removed_class) {
            selected_token.removeClassName(removed_class);
        });
        selected_token.addClassName(klass);
    }

    function setEventHandlingForDocument() {
        document.observe('click', function() {
            menu.hide();
        });

        document.observe('keydown', function(event) {
            if(selected_token && menu.visible() &&
               event.keyCode >= FIRST_NUMERICAL_CODE && event.keyCode < FIRST_NUMERICAL_CODE + classes.length) {
                setInfoStatusClass(classes[event.keyCode - FIRST_NUMERICAL_CODE]);
            }
        });
    }

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
