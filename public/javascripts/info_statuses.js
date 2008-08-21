// Functionality for the information status editing view

// Embed "private" variables and functions in an ExtJS-style object
var InfoStatus = function() {

    // private variables

    var classes = new Array('new', 'acc', 'acc-gen', 'acc-disc', 'acc-inf', 'old', 'no-info-status', 'info-unannotatable');
    var annotatables = null;
    var unannotatables = null;
    var selected_token = null;
    var selected_token_index = null;
    const FIRST_NUMERICAL_CODE = 49; // keycode for the 1 key

    // private functions

    function setAnnotatablesAndUnannotatables() {
        // Make sure old event handling is removed before determining the two sets again
        if(annotatables) {
            removeEventHandlingForAnnotatables();
        }
        if(unannotatables) {
            removeEventHandlingForUnannotatables();
        }

        annotatables = $$('span.info-annotatable');
        unannotatables = $$('span.info-unannotatable');

        setEventHandlingForAnnotatables();
        setEventHandlingForUnannotatables();
    }

    /////////////////////////////////////
    //
    // Event handling for annotatables
    //
    /////////////////////////////////////

    function removeEventHandlingForAnnotatables() {
        annotatables.invoke('stopObserving', 'click', annotatableClickHandler);
    }

    function setEventHandlingForAnnotatables() {
        annotatables.invoke('observe', 'click', annotatableClickHandler);
    }

    function annotatableClickHandler(event) {
        selectToken(this);
        event.stop();
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

    /////////////////////////////////////
    //
    // Event handling for unannotatables
    //
    /////////////////////////////////////

    function removeEventHandlingForUnannotatables() {
        unannotatables.invoke('stopObserving', 'click', unannotatableClickHandler);
    }

    function setEventHandlingForUnannotatables() {
        unannotatables.invoke('observe', 'click', unannotatableClickHandler);
    }

    function unannotatableClickHandler(event) {
        makeAnnotatable(this);
        event.stop();
    }

    function makeAnnotatable(elm) {
        if(!confirm('Do you want to make ' + elm.innerHTML + ' annotatable?')) {
            return;
        }
        elm.removeClassName('info-unannotatable');
        elm.addClassName('info-annotatable no-info-status');
        setAnnotatablesAndUnannotatables();
        selectToken(elm);
    }

    /////////////////////////////////////
    //
    // Miscellaneous functions
    //
    /////////////////////////////////////

    function setInfoStatusClass(klass) {
        classes.each(function(removed_class) {
            selected_token.removeClassName(removed_class);
        });
        selected_token.addClassName(klass);
        selected_token.addClassName('info-changed');
    }

    function setEventHandlingForDocument() {
        document.observe('keydown', function(event) {
            if(!selected_token) return;

            if(event.keyCode >= FIRST_NUMERICAL_CODE && event.keyCode < FIRST_NUMERICAL_CODE + classes.length) {
                var css = classes[event.keyCode - FIRST_NUMERICAL_CODE];
                setInfoStatusClass(css);

                if(css == 'info-unannotatable') {
                    selected_token.removeClassName('info-annotatable');
                    selected_token.removeClassName('info-selected');

                    setAnnotatablesAndUnannotatables();

                    // This will select the next token, since we have just removed the current one
                    // from the annotatables
                    selectToken(annotatables[selected_token_index === annotatables.length ? 0 : selected_token_index]);
                }

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

    function setEventHandlingForSaveButton() {
        var btn = $('save');
        btn.observe('click', function(event) {
            alert('hei');
            event.stop();
        });
    }

    return {

        // public functions

        init: function() {
            if(annotatables != null) return;  // because the script may be included several times on the same page

            setAnnotatablesAndUnannotatables();
            setEventHandlingForDocument();
            setEventHandlingForSaveButton();

            selectToken(annotatables[0]);
        }
    }
}();

document.observe('dom:loaded', function() {
    InfoStatus.init();
});
