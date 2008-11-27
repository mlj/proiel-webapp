function fatal_msg(msg)
{
  alert(msg);
}

var edge_count_el = null;

Event.observe(window, 'load', function() {
  var edge_count_el = $('edge_count');

  if (!edge_count_el)
    alert('Unable to find element "edge_count"');

  $$('.selectable').each(function(el) {
    Event.observe(el, 'click', function() {
      // Reset all the stuff that has already been selected.
      $$('.groupable').each(function(e) { e.removeClassName('grouped'); });
      $$('.selectable').each(function(e) { e.removeClassName('selected'); });
      edge_count_el.innerHTML = '';

      // Grab the ID, request data using AJAX and flag the affected
      // elements using style classes.
      el.addClassName('selected');

      new Ajax.Request('/tokens/' + el.identify().sub('w', '') + '/dependency_alignment_group', {
        method: 'get',
        asynchronous: false, // We need to do it synchronously or bad things will start to happen
        parameters: 'authenticity_token=' + authenticity_token,
        onComplete: function(req) {
          var response = req.responseText.evalJSON();

          var group = response['alignment_set'];
          var edge_count = response['edge_count'];

          group.each(function(group_el_id) {
            var group_el = $('w' + group_el_id);

            if (group_el)
              group_el.addClassName('grouped');
            else
              fatal_msg("Invalid element ID " + group_el_id + " returned by dependency_alignment_group");
          });

          edge_count_el.innerHTML = edge_count + ' edge(s) traversed';
        },
        on404: function(req) { fatal_msg("dependency_alignment_group returned status code 404"); },
        on500: function(req) { fatal_msg("dependency_alignment_group returned status code 500"); }
      });
    });
  });

//--------------------------------------------------
//   $$('.droppable').each(function(el) {
//     Droppables.add(el, {
//       accept: 'draggable',
//       hoverclass: 'selected',
//       onDrop: function(draggable_element, droppable_element) {
//         draggable_element.highlight();
//         droppable_element.highlight();
// 
//         var drag_id = draggable_element.identify().sub('sentence-', '');
//         var drop_id = droppable_element.identify().sub('sentence-', '');
// 
//         new Ajax.Request('/alignments/set_anchor/' + drag_id, {
//           asynchronous: true,
//           evalScripts: true,
//           parameters: 'anchor_id=' + drop_id + '&authenticity_token=' + authenticity_token
//         }); return false;
//       }
//     });
//   });
//-------------------------------------------------- 
});
