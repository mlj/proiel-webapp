// Functionality for creating and removing anaphoric links.
// Created by Anders Nøklestad
// Drawing of anaphor links inspired by code made for the BREDT demonstrator (http://bredt.uib.no) by Øystein Reigem.

// Embed "private" variables and functions in an ExtJS-style object
var Anaphora = function() {

    // private variables

    var tokens = null;

    // jsGraphics object used to draw lines
    var jg = null;
    // default line width
    var stroke_width = 2;

    // various values and objects needed for drawing lines between elements.
    var lineheight;
    var half_fontsize;
    var x_offset_for_line_end;
    var y_down_offset_for_line_end;
    var space = 3;
    var colour = 'blue';

    // private functions

    function setEventHandlingForTokens() {
        tokens.invoke('observe', 'click', tokenClickHandler);
    }

    function tokenClickHandler(event) {
        if(!event.ctrlKey) {
            // This is not a ctrl-click, so just clean up any antecedent-related stuff

            // Remove any antecedent style from all tokens
            tokens.invoke('removeClassName', 'antecedent');

            // Remove all anaphor-antecedent lines
            jg.clear();
            return;
        }

        var selected_token = InfoStatus.getSelectedToken();

        // A class name for the anaphor that is really just a way to store the id of its
        // antecedent without resorting to non-standard attributes
        var antecedentClass = 'ant-' + InfoStatus.getTokenId(this);

        if(selected_token.hasClassName(antecedentClass)) {
            // The user has clicked a second time in order to remove the antecedent
            removeAntecedentLink(selected_token, this, antecedentClass);
        }
        else {
            createAntecedentLink(selected_token, this, antecedentClass);
        }
    }

    function removeAntecedentLink(anaphor, antecedent, antecedentClass) {
        // Remove the class containing the antecedent id from the anaphor
        anaphor.removeClassName(antecedentClass);

        // Remove the antecedent style from the dropped antecedent
        antecedent.removeClassName('antecedent');

        // Remove the visual link between anaphor and antecedent
        removeLines();
    }

    function createAntecedentLink(anaphor, antecedent, antecedentClass) {
        if(InfoStatus.getTokenId(antecedent) >= InfoStatus.getTokenId(anaphor)) {
            alert('Antecedents must precede their anaphors!');
            return;
        }

        if(!$w(anaphor.className).include('old')) {
            alert('Only tokens with information status "old" can have antecedents!');
            return;
        }

        // Remove any antecedent style from all other tokens
        tokens.invoke('removeClassName', 'antecedent');

        // Put an antecedent style on the selected antecedent
        antecedent.addClassName('antecedent');

        // Remove any other visual links between anaphors and antecedents
        removeLines();

        drawLineBetweenElements(anaphor, antecedent);

        // Remove any old antecedent id
        anaphor.removeClassName(getAntecedentClassFor(anaphor));

        // Mark the anaphor with the new antecedent id
        anaphor.addClassName(antecedentClass);
    }

    function drawLineBetweenElements(from_span_element, to_span_element) {

        determineValues();

        // Calculate the anchor point for each span
        var from_x = from_span_element.offsetLeft + x_offset_for_line_end;
        var from_y = from_span_element.offsetTop + 1 + half_fontsize;
        var to_x = to_span_element.offsetLeft + x_offset_for_line_end;
        var to_y = to_span_element.offsetTop + 1 + half_fontsize + 2;

        // Calculate start/end points for lines.

        // Find the two possible locations for lines to start and end -
        // top or bottom of highlighted rectangle
        var upper_from_y = from_y - y_down_offset_for_line_end + 1;
        var upper_to_y = to_y - y_down_offset_for_line_end + 1;
        var lower_to_y = to_y + y_down_offset_for_line_end + 9;

        var from_line = Math.round(from_span_element.offsetTop / lineheight);
        var to_line = Math.round(to_span_element.offsetTop / lineheight);

        if (from_line == to_line) {
            drawLine(from_x, upper_from_y, from_x, upper_from_y - space);
            drawLine(from_x, upper_from_y - space, to_x, upper_from_y - space);
            drawLine(to_x, upper_from_y - space, to_x, upper_from_y);
        } else {
            drawLine(from_x, upper_from_y, from_x, upper_from_y - space);
            drawLine(from_x, upper_from_y - space, to_x, upper_from_y - space);
            drawLine(to_x, upper_from_y - space, to_x, lower_to_y);
        }
    }

    function determineValues() {

        var fontsize = parseInt(tokens[0].getStyle('font-size'));
        lineheight = parseInt(tokens[0].getStyle('line-height'));

        // Let the stroke width depend on font size
        stroke_width = Math.round(1.5 + (fontsize / 24));
        if (stroke_width < 1) { stroke_width = 1; }

        half_fontsize = Math.round(fontsize / 2);

        // Calculate the horizontal distance from the rectangle's left border to the anchor point
        x_offset_for_line_end = Math.round(half_fontsize * 1.25);
        // Calculate the vertical distances from the anchor point to the lines' start/end points
        y_down_offset_for_line_end = half_fontsize + 2 + Math.round(stroke_width/2 - 0.1);
    }

    // Draws a straight line between two points
    function drawLine(x1, y1, x2, y2) {
        jg.setStroke(stroke_width);
        jg.drawLine(x1, y1, x2, y2);
        jg.paint();

    }

    // Removes all lines that have been drawn
    function removeLines() {
        jg.clear();
    }

    function getAntecedentClassFor(anaphor) {
        return $w(anaphor.className).find(function(cls) {
            return cls.startsWith('ant-');
        });
    }

    function getAntecedentIdFor(anaphor) {
        var antecedentClass = getAntecedentClassFor(anaphor);
        if(antecedentClass) {
            return antecedentClass.substr('ant-'.length);
        }
        else {
            return null;
        }
    }

    return {

        // public functions

        init: function() {
            if(tokens != null) return;  // because the script may be included several times on the same page

            tokens = $$('.sentence-divisions span[id][lang]');

            jg = new jsGraphics("info-status");
            jg.setColor(colour);

            setEventHandlingForTokens();
        },

        showAntecedentFor: function(token) {
            if(tokens === null) {
                // Because this function may be called by another module before we get a chance to call init
                this.init();
            }

            // Stop showing any other antecedent
            tokens.invoke('removeClassName', 'antecedent');
            removeLines();

            var antecedentId = getAntecedentIdFor(token);
            if(!antecedentId) return;

            var antecedent = $('token-' + antecedentId);
            if(antecedent) {
                antecedent.addClassName('antecedent');
                drawLineBetweenElements(token, antecedent);
            }
        }
    }
}();

document.observe('dom:loaded', function() {
    Anaphora.init();
});
