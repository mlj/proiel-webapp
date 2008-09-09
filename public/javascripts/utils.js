var ExclusiveSelectionClass = Class.create({
  initialize: function(class_name, must_deselect) {
    this.class_name = class_name;
    this.current_selection = null;
    this.must_deselect = must_deselect;
  },
  getSelection: function() {
    return this.current_selection;
  },
  onSelection: function(element_or_id, onActivate, onDeactivate) {
    e = $(element_or_id);

    // Ignore event if a different element has already been selected.
    if (!this.current_selection || !this.must_deselect || this.current_selection == e) {
      if (toggleClassName(e, this.class_name)) {
        if (this.current_selection) { // only for the !must_deselect case
          toggleClassName(this.current_selection, this.class_name);
          onDeactivate(this.current_selection);
        }
        this.current_selection = e;
        onActivate(e);
      } else {
        onDeactivate(this.current_selection);
        this.current_selection = null;
      }
    }
  }
});

// Toggles a class of an element. Returns true if the class name was added, false otherwise.
function toggleClassName(element, class_name)
{
  element.toggleClassName(class_name);
  return element.hasClassName(class_name);
}

function setSelectedByValue(element_or_id, value)
{
  var e = $(element_or_id);

  for (var i = 0; i < e.options.length; i++) {
    if (e.options[i].value == value) {
      e.options[i].selected = true;
    }
  }
}

// Returns the current selection from a selector. 
function getSelectSelection(element_or_id) {
  var element = $(element_or_id);

  for (var i = 0; i < element.options.length; i++) {
    if (element.options[i].selected)
      return element.options[i].value;
  }

  return null;
}

// Hides all elements that match a CSS selector.
function hideAll(selector) {
  $$(selector).each(function(e) { e.hide(); });
}

// Removes all children of a DOM element
function removeAllChildren(e) {
  while (e.hasChildNodes())
    e.removeChild(e.firstChild);
}

// A rather primitive container for a radio group. It is primitive in the sense that it assumes
// some form of container element, whose ID is expected upon instantiation, and that any input
// element that within this element is a radio button that belongs to the radio group.
var RadioGroup = Class.create({
  // Creates a new radio group container.  
  initialize: function(id) {
    this.widget = $(id);
  },

  // Returns a radio button by value.
  find: function(value) {
    return this.buttons().find(function(e) { return e.value == value; });
  },

  // Returns all radio buttons in group.
  buttons: function() { return this.widget.getElementsBySelector('input'); },

  // Selects a radio button by value.
  select: function(value) {
    r = this.find(value);
    if (r)
      r.checked = true;
  },

  // Deselects all radio buttons in a radio group.
  deselect: function() { this.buttons().each(function(e) { e.checked = false; }); },

  // Returns the current selection within this radio group.
  selection: function() { 
    var selected = this.buttons().find(function(e) { return e.checked; });
    return selected ? selected.value : null;
  },

  // Disables the radio group.
  disable: function() { this.buttons().invoke('disable'); },

  // Enables the radio group.
  enable: function() { this.buttons().invoke('enable'); }
});
