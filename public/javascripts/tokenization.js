var useXML = false;
var useVisibleSpace = false;
var visibleSpace = "\u2423";
var tokenDivider = " ";

var MyUtils = {
  nextText: function(element) {
    var s = '';

    while ((element = element.previousSibling)) {
      if (element.nodeType == 8) {
        // Comment. Ignore.
      } else if (element.nodeType == 3) {
        // Text. Append.
        s = s + element.data;
      } else {
        break;
      }
    }

    return s;
  }
}

Element.addMethods(MyUtils);

function updateForm() {
  if (useXML) {
    $('new_presentation').value = $('presentationxml').innerHTML; // XML version
  } else
    $('new_presentation').value = $('presentation').innerHTML; // HTML version
}

function mergeWordElements(left, right, source, target) {
  // FIXME: this version does not work. For some reason there is
  // always at least one white-space character between each element.
  //target.innerHTML = left.innerHTML + left.nextText() + right.innerHTML;
  // Replacement version:
  if (left.next() != right) {
    target.innerHTML = left.innerHTML + left.next().innerHTML + right.innerHTML;
    left.next().remove();
  } else
    target.innerHTML = left.innerHTML + right.innerHTML;

  Droppables.remove(source);
  source.remove();

  target.highlight();

  updateForm();
}

function areWordElementsAdjacent(left, right) {
  var next = left.next();

  // FIXME: this version does not work for the same reason as above.
  //return next == right;
  // Replacement version:
  if (useXML) {
    return (next == right || (next && 
          (next.nodeName == 'S' || next.nodeName == 's') &&
          next.next() == right));
   } else
    return (next == right || (next && 
          next.hasClassName('s') &&
          next.next() == right));
}

function splitWordElement(element) {
  var ts = element.innerHTML.split(tokenDivider);

  if (ts.length > 1) {
    element.innerHTML = ts[0];
    element.highlight();

    var c = element;
    for (var i = 1; i < ts.length; i++) {
      var m, n;

      if (useXML)
        m = new Element('s');
      else
        m = new Element('span', { "class": 's' });

      m.innerHTML = tokenDivider;

      if (useXML)
        n = new Element('w');
      else
        n = new Element('span', { "class": 'w' });

      n.innerHTML = ts[i];

      c.insert({ after: m });
      m.insert({ after: n });

      activateWordElement(n);
      n.highlight();

      c = n;
    }

    updateForm();
  } else {
    alert("Token cannot be split.");
  }
}

function activateWordElement(el) {
  new Draggable(el, { revert: true });

  Droppables.add(el, {
    hoverclass: 'selected', // FIXME: does not seem to work after a drop on the same element
    onDrop: function(draggable_element, droppable_element) {
      if (areWordElementsAdjacent(droppable_element, draggable_element)) {
        mergeWordElements(droppable_element, draggable_element, draggable_element, droppable_element);
      } else if (areWordElementsAdjacent(draggable_element, droppable_element)) {
        mergeWordElements(draggable_element, droppable_element, draggable_element, droppable_element);
      } else {
        alert("The tokens cannot be merged.");
      }

    //  new Ajax.Request('/alignments/set_anchor/' + drag_id, {
    //    asynchronous: true,
    //    evalScripts: true,
    //    parameters: 'anchor_id=' + drop_id + '&authenticity_token=' + authenticity_token
    //  }); return false;
    }
  });

  el.observe('dblclick', function(ev) {
    var el = Event.element(ev);
    splitWordElement(el);
  });
}

Event.observe(window, 'load', function() {
  if (useVisibleSpace) {
    // Change spaces in s-elements to visible spaces.
    $$('s').each(function(el) {
      if (el.innerHTML == tokenDivider)
        el.innerHTML = visibleSpace;
    });
  }

  updateForm();

  if (useXML)
    $$('w').each(function(el) { activateWordElement(el) });
  else
    $$('.w').each(function(el) { activateWordElement(el) });
});
