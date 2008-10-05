// Functionality for editing prodrop tokens

// Embed "private" variables and functions in an ExtJS-style object
var Prodrop = function() {

    // private variables

    var new_id = 0;
    var verbs = null;
    var selected_verb = null;
    var menu = null;
    var menu_dimensions = null;

    var prodrop_text = {sub: 'PRO-SUB', obj: 'PRO-OBJ', obl: 'PRO-OBL'};
    var prodrop_positions = {sub: 'before', obj: 'after', obl: 'after'};

    // private functions

    function setEventHandlingForProdropMenu() {
        $$('div.prodrop-menu-item').invoke('observe', 'click', menuItemClickHandler);
    }

    function menuItemClickHandler(event) {
        var relation = $w(this.className).last();
        var insertion = $H();
        var prodrop_token = $(document.createElement('span'));

        prodrop_token.writeAttribute('id', 'token-new' + new_id++);
        prodrop_token.addClassName('highlight info-annotatable old info-changed prodrop-' +
                                   relation + '-' + selected_verb.id);
        prodrop_token.update(prodrop_text[relation]);
        insertion.set(prodrop_positions[relation], prodrop_token);
        selected_verb.insert(insertion.toObject());

        menu.hide();
        InfoStatus.setAnnotatablesAndUnannotatables();
        InfoStatus.selectToken(prodrop_token);
        event.stop();
    }

    function setEventHandlingForVerbs() {
        verbs.invoke('observe', 'click', verbClickHandler);
    }

    function verbClickHandler(event) {
        if(event.ctrlKey) return;      // we don't handle ctrl-clicks here

        selected_verb = this;
        showProdropMenuFor(this);
        event.stop();
    }

    function setEventHandlingForDocument() {
        document.observe('click', function() {
            menu.hide();
        });
        document.observe('keydown', function(event) {
            if(event.keyCode === Event.KEY_ESC) {
                menu.hide();
            }
        });
    }

    function showProdropMenuFor(elm) {
        var offset = elm.cumulativeOffset();
        menu.setStyle({
            top: (offset['top'] - menu_dimensions['height']) + 'px',
            left: (offset['left'] - ((menu_dimensions['width'] - elm.getWidth()) / 2) - 2) + 'px'
        });
        menu.show();
    }

    return {

        // public functions

        init: function() {
            if(verbs != null) return;  // because the script may be included several times on the same page

            menu = $('prodrop-menu');
            verbs = $$('.verb');
            setEventHandlingForProdropMenu();
            setEventHandlingForVerbs();
            setEventHandlingForDocument();

            menu_dimensions = menu.getDimensions();
        }
    }
}();

document.observe('dom:loaded', function() {
    Prodrop.init();
});
