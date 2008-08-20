// Functionality for the information status editing view

// Embed "private" variables and functions in an ExtJS-style object
var InfoStatus = function() {

    // private variables

    var classes = new Array('new', 'acc', 'acc-gen', 'acc-disc', 'acc-inf', 'old', 'no-info-status');
    var annotatables = null;
    var selected_token = null;
    var selected_token_index = null;
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

        annotatables.each(function(annotatable, i) {
            if(annotatables[i] === selected_token) {
                selected_token_index = i;
                throw $break;
            }
        });
    }

    function setInfoStatusClass(klass) {
        classes.each(function(removed_class) {
            selected_token.removeClassName(removed_class);
        });
        selected_token.addClassName(klass);
    }

    function setEventHandlingForDocument() {
        document.observe('keydown', function(event) {
            if(!selected_token) return;

            if(event.keyCode >= FIRST_NUMERICAL_CODE && event.keyCode < FIRST_NUMERICAL_CODE + classes.length) {
                setInfoStatusClass(classes[event.keyCode - FIRST_NUMERICAL_CODE]);
                event.stop();
            }
            else if(event.keyCode === Event.KEY_TAB) {
                var index;

                if(event.shiftKey) {
                    index = selected_token_index === 0 ? annotatables.length - 1 : selected_token_index - 1;
                }
                else {
                    index = selected_token_index === annotatables.length - 1 ? 0 : selected_token_index + 1;
                }
                selectToken(annotatables[index]);
                event.stop();
            }
        });
    }

    return {

        // public functions

        init: function() {
            if(annotatables != null) return;  // because the script may be included several times on the same page

            annotatables = $$('span.info-annotatable');

            setEventHandlingForAnnotatables();
            setEventHandlingForDocument();

            selectToken(annotatables[0]);
        }
    }
}();

document.observe('dom:loaded', function() {
    InfoStatus.init();
});
