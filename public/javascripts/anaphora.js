// Functionality for creating and removing anaphoric links and contrast groups.
// Created by Anders Nøklestad
// Drawing of anaphor links inspired by code in the BREDT demonstrator (http://bredt.uib.no) by Øystein Reigem.

var current_contrast_group_letter_code;

// Embed "private" variables and functions in an ExtJS-style object
var AnaphoraAndContrast = function() {

    // private variables

    var tokens = null;
    var group_no = 0;
    var first_letter_code = 65; // keycode for the 'a' key
    var max_contrast_groups = 5;

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

    /////////////////////////////////////
    //
    // Event handling for tokens
    //
    /////////////////////////////////////

    function setEventHandlingForTokens() {
        tokens.invoke('observe', 'click', antecedentClickHandler);
        tokens.invoke('observe', 'click', contrastClickHandler);
    }

    function antecedentClickHandler(event) {
        if(!(event.ctrlKey || event.metaKey) || event.altKey) return;

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
        selected_token.addClassName('info-changed');
    }

    function contrastClickHandler(event) {
        if(!current_contrast_group_letter_code) return;

        var selected_contrast = $F('contrast-select');
        if(!selected_contrast) {
            alert('Please select or create a contrast.');
            return;
        }
        var contrast_group = (current_contrast_group_letter_code - first_letter_code + 1);
        var display_class_name = 'contrast' + contrast_group;
        var group_class_name = 'con-' + selected_contrast + String.fromCharCode(current_contrast_group_letter_code).toLowerCase();

        this.addClassName('info-changed');

        if(this.hasClassName(group_class_name)) {
            // The user has clicked a second time in order to remove the contrast item
            this.removeClassName(group_class_name);
            this.removeClassName(display_class_name);
        }
        else {
            this.addClassName(group_class_name);
            this.addClassName(display_class_name);
        }
    }

    /////////////////////////////////////
    //
    // Miscellaneous functions
    //
    /////////////////////////////////////

    function setEventHandlingForDocument() {
        document.observe('keydown', function(event) {
            if(event.keyCode >= first_letter_code && event.keyCode < first_letter_code + max_contrast_groups) {
                // As long as this key is pressed, clicked-on tokens will be put in the contrast
                // group with the letter given by event.keyCode
                current_contrast_group_letter_code = event.keyCode;
            }
        });
        document.observe('keyup', function(event) {
            current_contrast_group_letter_code = null;
        });
    }

    function removeAntecedentLink(anaphor, antecedent, antecedentClass) {
        // Remove the class containing the antecedent id from the anaphor
        anaphor.removeClassName(antecedentClass);

        // Remove the antecedent style from the dropped antecedent
        antecedent.removeClassName('antecedent');

        // Remove the visual link between anaphor and antecedent
        AnaphoraAndContrast.removeAnaphoraLines();
    }

    function createAntecedentLink(anaphor, antecedent, antecedentClass) {
        if(InfoStatus.getTokenId(antecedent) >= InfoStatus.getTokenId(anaphor) && !antecedent.innerHTML.startsWith('PRO-')) {
            alert('Antecedents must precede their anaphors!');
            return;
        }

        // Remove any antecedent style from all other tokens
        tokens.invoke('removeClassName', 'antecedent');

        // Put an antecedent style on the selected antecedent
        antecedent.addClassName('antecedent');

        // Remove any other visual links between anaphors and antecedents
        AnaphoraAndContrast.removeAnaphoraLines();

        drawLineBetweenElements(anaphor, antecedent);

        // Remove any old antecedent id
        anaphor.removeClassName(AnaphoraAndContrast.getAntecedentClassFor(anaphor));

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

    function getAntecedentIdFor(anaphor) {
        var antecedentClass = AnaphoraAndContrast.getAntecedentClassFor(anaphor);
        if(antecedentClass) {
            return antecedentClass.substr('ant-'.length);
        }
        else {
            return null;
        }
    }

    function clearContrasts() {
        $R(1, max_contrast_groups).each(function(number) {
            $$('.sentence-divisions .contrast'+ number).invoke('removeClassName', 'contrast' + number);
        });
    }

    return {

        // public functions

        init: function() {
            if(tokens != null) return;  // because the script may be included several times on the same page

            tokens = $$('.sentence-divisions span[id][lang]');

            jg = new jsGraphics("info-status");
            jg.setColor(colour);

            setEventHandlingForTokens();
            setEventHandlingForDocument();
        },

        showAntecedentFor: function(token, keep_others) {
            if(tokens === null) {
                // Because this function may be called by another module before we get a chance to call init
                this.init();
            }

            if(!keep_others) {
                // Stop showing any other antecedent
                tokens.invoke('removeClassName', 'antecedent');
                AnaphoraAndContrast.removeAnaphoraLines();
            }

            var antecedentId = getAntecedentIdFor(token);
            if(!antecedentId) return;

            var antecedent = $('token-' + antecedentId);
            if(antecedent) {
                antecedent.addClassName('antecedent');
                drawLineBetweenElements(token, antecedent);
            }
        },

        showAntecedentsForAllAnaphors: function() {
            $$('.sentence-divisions span[id][lang]').each(function(token) {
                if(token.className.include('ant-')) {
                    AnaphoraAndContrast.showAntecedentFor(token, true);
                }
            });
        },

        // Show the specified contrast number
        showContrastNo: function(number) {
            clearContrasts();

            if(!number) return;

            $R(1, max_contrast_groups).each(function(group_no) {
                $$('.sentence-divisions .con-' + number + String.fromCharCode(first_letter_code + group_no - 1).toLowerCase()).invoke('addClassName', 'contrast' + group_no);
            });
        },

        createNewContrast: function() {
            clearContrasts();
            var options = $('contrast-select').options;
            var highest_contrast_no = parseInt(options[options.length - 1].value);
            if(isNaN(highest_contrast_no)) {
                highest_contrast_no = 0;
            }
            var new_contrast_no = highest_contrast_no + 1;
            options[options.length] = new Option(new_contrast_no, new_contrast_no, false, true);
        },

        deleteContrast: function() {
            var selected_contrast = parseInt($F('contrast-select'));
            if(!(isFinite(selected_contrast) && selected_contrast > 0)) {
                alert('Please select a contrast');
                return;
            }
            if(confirm('Do you want to delete contrast number ' + selected_contrast + '?')) {
                new Ajax.Request(document.location.href.match(url_without_last_part)[0] + 'delete_contrast',
                                 {
                                     method: 'post',
                                     parameters: {
                                         contrast: selected_contrast,
                                         authenticity_token: authenticity_token
                                     },
                                     onSuccess: function() {
                                         $R(1, max_contrast_groups).each(function(group_no) {
                                             var cls = 'con-' + selected_contrast + String.fromCharCode(first_letter_code + group_no - 1).toLowerCase();
                                             var elements = $$('.sentence-divisions .' + cls).invoke('removeClassName', 'contrast' + group_no);

                                             // Sometimes an element contains more than one instance of e.g. con-1a in its class
                                             // attribute, so we cannot simply use removeClassName :-\
                                             elements.each(function(element) {
                                                 element.className = element.className.gsub(cls, '');
                                             });
                                         });

                                         // Remove the selected contrast from the contrast list
                                         var cs = $('contrast-select');
                                         cs.remove(cs.selectedIndex);

                                         var elm = $('server-message');
                                         elm.update('Contrast group removed');
                                         elm.show();
                                         elm.highlight();
                                         elm.fade({delay: 2.0});
                                     },
                                     onFailure: function(response) {
                                         var elm = $('server-message');
                                         elm.show();
                                         elm.update('Error: ' + response.responseText);
                                         elm.highlight({startcolor: 'ff0000'});
                                         elm.fade({delay: 2.0});
                                     }
                                 }
                                );
            }
        },

        // Adds the given token, which should be a token-span, to the tokens array
        addToken: function(token) {
            token.observe('click', antecedentClickHandler);
            token.observe('click', contrastClickHandler);
            tokens.push(token);
        },

        // Removes all lines that have been drawn
        removeAnaphoraLines: function() {
            jg.clear();
        },

        getAntecedentClassFor: function(anaphor) {
            return $w(anaphor.className).find(function(cls) {
                return cls.startsWith('ant-');
            });
        }
    }
}();

document.observe('dom:loaded', function() {
    AnaphoraAndContrast.init();
});
