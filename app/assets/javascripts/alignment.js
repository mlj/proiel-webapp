function alignmentSetup() {
  $$('.draggable').each(function(el) {
    new Draggable(el, {
      revert: true
    });
  });

  $$('.droppable').each(function(el) {
    Droppables.add(el, {
      accept: 'draggable',
      hoverclass: 'selected',
      onDrop: function(draggable_element, droppable_element) {
        draggable_element.highlight();
        droppable_element.highlight();

        var drag_id = draggable_element.identify().sub('sentence-', '');
        var drop_id = droppable_element.identify().sub('sentence-', '');

        new Ajax.Request('/alignments/set_anchor/' + drag_id, {
          asynchronous: true,
          evalScripts: true,
          parameters: 'anchor_id=' + drop_id + '&authenticity_token=' + authenticity_token
        }); return false;
      }
    });
  });
}
