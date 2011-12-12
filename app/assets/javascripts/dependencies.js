// Globals
var palette = null;
var sentence_widget = null;
var tree_widget = null;
var controller = null;
var model = null;
var hotkeys = {
  a: "adv",
  A: "xadv",
  c: "comp",
  g: "ag",
  j: "obj",
  J: "xobj",
  l: "obl",
  n: "narg",
  o: "obj",
  O: "xobj",
  p: "pred",
  P: "piv",
  r: "part",
  s: "sub",
  t: "atr",
  v: "voc",
  x: "aux"
};

var Widget = Class.create({
  initialize: function(id, id_prefix) {
    this.widget = $(id);
    this.id_prefix = id_prefix;
    this.selected = null;
    this.entries = this.widget.getElementsBySelector('li');
  },

  find: function(id_or_element) {
    if (Object.isString(id_or_element))
      return $(this.id_prefix + id_or_element);
    else
      return id_or_element;
  },

  selected: function() { return this.selected; },

  deselect: function() {
    if (this.selected) {
      this.find(this.selected).removeClassName("selected");
      this.selected = null;
    }
  },

  select: function(id) {
    r = this.find(id);
    if (!r.hasClassName('unavailable')) {
      this.deselect();
      if (r) {
        r.addClassName("selected");
        this.selected = id;
      }
      return true;
    } else {
      return false;
    }
  },

  disable: function() {
    this.deselect();
    this.entries.invoke('addClassName', 'unavailable');
  },

  enable: function() { this.entries.invoke('removeClassName', 'unavailable'); }
});

var DependencyStructureWidget = Class.create(Widget, {
  initialize: function($super, id) { $super(id, 'rel-'); },

  addEntry: function(parent_token_id, new_token_id, child_token_id, word_form, relation) {
    var ul;

    if (!parent_token_id)
      ul = this.widget;
    else
      ul = this.findOrCreateUL(parent_token_id);

    if (!relation) {
      if (parent_token_id) {
        var morphtag = model.getMorphTag(parent_token_id);
        var relation = tree_widget.getRelation(parent_token_id);
        relation = getRecommendedRelation(relation, morphtag, model.getMorphTag(new_token_id));
      } else {
        relation = getRecommendedRelation(null, null, model.getMorphTag(new_token_id));
      }
    }

    var new_node;

    var bad_or_not = '';
    if (new_token_id != 'ROOT' && !isValidRelation(relation))
      bad_or_not = 'bad';

    new_node = ul.insert('<li id="rel-' + new_token_id + '"><span class="user-value"><tt class="relation ' + bad_or_not + '">' + relation + '</tt><span class="slashes"></span>&nbsp;' + word_form + '</span><span class="token-number">' + model.getTokenNumber(new_token_id) + '</span></li>');

    if (child_token_id) {
      // We have a child token ID, i.e. we need to insert a new node between the given
      // head and child.
      var ul_for_new_node = this.findOrCreateUL(new_token_id);
      var child = this.find(child_token_id);
      ul_for_new_node.appendChild(child);
    }
  },

  findOrCreateUL: function(id) {
    var e = this.find(id);
    var ul = e.down("ul");
    if (!ul) {
      e.insert("<ul></ul>");
      ul = e.down("ul");
    }
    return ul;
  },

  clear: function() {
    var e = this.widget.down('li');
    if (e) {
      this.deselect();
      e.remove();
    }
    this.addEntry(null, 'ROOT', null, '-', 'ROOT');
  },

  removeEntry: function(id) { this.find(id).remove(); },

  // Returns an array of non-empty descendants of ID.
  getNonemptyDescendants: function(id) {
    var a = new Array;
    this.find(id).descendants().each(function(e) {
      if (e.tagName.toLowerCase() == 'li') {
        var desc_id = e.identify().sub('rel-', '');
        if (!model.isEmpty(desc_id))
          a.push(desc_id);
      }
    });
    return a;
  },

  getRelation: function(id) {
    var p = this.find(id);
    return p ? p.down('tt').innerHTML : null;
  },

  setRelation: function(id, r) {
    var p = this.find(id);
    p.down('tt').innerHTML = r;
  },

  getParentEntry: function(token_id) {
    var p = this.find(token_id).up('li');
    if (p) {
      return p.identify().sub('rel-', '');
    } else {
      return null;
    }
  },

  getFirstChildEntry: function(token_id) {
    var p = this.find(token_id).down('li');
    if (p) {
      return p.identify().sub('rel-', '');
    } else {
      return null;
    }
  },

  getPrevSiblingEntry: function(token_id) {
    var p = this.find(token_id).previous('li');
    if (p) {
      return p.identify().sub('rel-', '');
    } else {
      return null;
    }
  },

  getNextSiblingEntry: function(token_id) {
    var p = this.find(token_id).next('li');
    if (p) {
      return p.identify().sub('rel-', '');
    } else {
      return null;
    }
  },

  _updateJSON: function() {
    var root = this.widget.down('ul');
    $('output').value = root ? this._getSubtree(root).toJSON() : '';
  },

  _getSubtree: function(lst) {
    var subtree = new Hash();

    var list_elements = lst.childElements();
    for (var j = 0; j < list_elements.length; j++) {
      var i = list_elements[j];
      if (i.tagName.toLowerCase() == 'li') {
        var value = new Hash();

        value.set('relation', i.down("tt").innerHTML);

        var dependents = i.down("ul");
        if (dependents)
          value.set('dependents', this._getSubtree(dependents));

        var id = i.identify().sub('rel-', '');
        value.set('empty', model.isEmpty(id));

        // Return the pos to make slash interpretation possible. If
        // graphs from the editor and graphs from the base were to be
        // treated in the same way, we'd actually need to return
        // enough data to make possible the creation of a full
        // morphtag object, but that seems too much
        var m = model.getMorphTag(id);
        value.set('pos', $H(m).get('pos'));

        if (this.hasSlashes(id)) {
          value.set('slashes', this.getSlashes(id));
        }

        subtree.set(id, value);
      }
    }

    return subtree;
  },

  // Returns a list of select options with all token numbers
  _getSelectOptions: function(selected_id) {
    var options = '';
    // FIXME: sorting by ID won't always get us what we want
    model.getTokenIDs().sort().each(function(id) {
      var selected = '';
      if (selected_id && selected_id == id)
        selected = " selected='selected'";

      options += '<option value="' + id + '"' + selected + '>' + model.getTokenNumber(id) + '</option>';
    });
    return options;
  },

  addSlash: function(id, selected_slash_id) {
    var p = this.find(id).down('span.slashes');
    var options = this._getSelectOptions(selected_slash_id);
    p.insert("/<select onchange='onSlashSelect()'>" + options + "</select>");
  },

  hasSlashes: function(id) {
    var p = this.find(id).down('span.slashes').down('select');
    return p ? true : false;
  },

  getSlashes: function(id) {
    var slashes = new Array();
    var p = this.find(id).down('span.slashes');
    p.descendants().each(function(e) {
      if (e.tagName.toLowerCase() == 'select') {
        slashes.push(getSelectSelection(e));
      }
    });
    return slashes;
  },

  removeSlashes: function(id) {
    var p = this.find(id).down('span.slashes');
    removeAllChildren(p);
  },

  // FIXME: Don't like this...
  updateSlashSelects: function() {
    this.widget.select('.slashes select').each(function(select) {
      var options = tree_widget._getSelectOptions(getSelectSelection(select));
      select.replace("<select onchange='onSlashSelect()'>" + options + "</selecr>");
    });
  } ,

  cut: function(id, cut_buffer) {
    var subtree = this.find(id);
    subtree.remove();
    subtree.removeClassName("selected");
    //cut_buffer.appendChild(subtree);
    this.selected = null;
    cut_buffer.push(subtree);
  },

  paste: function(id, cut_buffer) {
    var ul = this.findOrCreateUL(id);
    //ul.appendChild(cut_buffer.down('li'));
    ul.appendChild(cut_buffer.pop());
    // This serves no purpose other than to ensure that the ul-level is updated
    // properly (in Firefox 1.5 the tree view will not change unless the ul-level
    // is somehow touched).
    ul.addClassName('foobar');
    ul.removeClassName('foobar');
  }
});

var SentenceWidget = Class.create(RadioGroup, {
  setConsumed: function(id) { this.find(id).addClassName("consumed"); },

  setUnconsumed: function(id) { this.find(id).removeClassName("consumed"); },

  clear: function() { this.widget.descendants().invoke('removeClassName', 'consumed'); },

  isConsumed: function(id) { return this.find(id).hasClassName("consumed"); },

  // Returns all unconsumed tokens
  getUnconsumedTokens: function() { return this.buttons().findAll(function(e) { return !e.hasClassName("consumed"); }); }
});

function getRecommendedRelation(head_relation, head, dependent) {
  var guess = inferRelation(head, dependent);

  if (guess == 'COPY')
    return head_relation;
  else
    return guess;
}

// Actual event handlers

function onDependencyStructureClick(ev) {
  var id = findAffectedID(ev, 'li', 'rel-');

  if (id)
    controller.select(id);
}

function onSentenceClick(ev) {
  var id = sentence_widget.selection();

  if (id)
    controller.select(id);
}

/* Returns the element that is affected by an event by testing for the
   element type and, if necessary, ascending the hierarchy until one
   is found. */
function findAffectedElement(ev, name) {
  var element = ev.element();

  if (element.tagName != name.toUpperCase() && element.tagName != name.toLowerCase())
    element = element.up(name);

  return element;
}

/* Same as findAffectedElement, but returns the ID instead. */
function findAffectedID(ev, name, prefix) {
  var element = findAffectedElement(ev, name);

  if (element)
    return element.identify().sub(prefix, '');
  else
    return null;
}

function onSlashSelect() { tree_widget._updateJSON(); }

function onPaletteClick(ev) {
  var element = findAffectedElement(ev, 'input');

  if (element)
    controller.changeRelation(element.identify());
}

function onChangeDirectionClick() { controller.toggleBuildDirection(); }

// Controller

var Controller = Class.create({
  initialize: function() {
    this.has_cut_data = false;
    this.selection = null; // Currently selected token
    this.top_down = true; // Build direction
    this.depth_first = true; // Build direction
    this.cut_buffer = new Array();
  },

  setSelection: function(token_id) {
    if (this.selection) {
      // Do de-selections and disable buttons and palette
      sentence_widget.deselect();
      tree_widget.deselect();
    }

    if (token_id) {
      // Do selections and enable buttons and palette
      if (!model.isEmpty(token_id))
        sentence_widget.select(token_id);
      tree_widget.select(token_id);

      r = tree_widget.getRelation(token_id);

      if (isValidRelation(r)) {
        palette.enable();
        palette.select(r);
      }
    }

    // Save the new reference
    this.selection = token_id;

    this.updateControls();
  },

  getSelection: function() { return this.selection; },

  // Actions

  select: function(token_id) {
    // Check if we have already been selected, in which case we do nothing.
    if (this.getSelection() == token_id)
      return;

    if (!model.isEmpty(token_id) && !sentence_widget.isConsumed(token_id)) {
      // The user wants to insert a new token in the dependency structure.
      if (this.top_down) {
        tree_widget.addEntry(this.selection, token_id, null,
            model.getWordForm(token_id), null);
      } else {
        var h = tree_widget.getParentEntry(this.selection);
        tree_widget.addEntry(h, token_id, this.selection,
            model.getWordForm(token_id), null);
      }

      // Flag the token as consumed
      sentence_widget.setConsumed(token_id);

      // Determine where to move reference. If depth first, select the
      // recently inserted token, otherwise stay where we are.
      if (this.depth_first)
        this.setSelection(token_id);
    } else {
      // The user wants to move the reference somewhere.
      this.setSelection(token_id);
    }

    tree_widget._updateJSON();
  },

  clear: function() {
    sentence_widget.clear();
    tree_widget.clear();
    this.setSelection('ROOT');
    this.updateControls();

    tree_widget._updateJSON();
  },

  removeEntry: function() {
    var id = this.selection;

    // Make tokens available in the sentence widget
    if (!model.isEmpty(id))
      sentence_widget.setUnconsumed(id);

    tree_widget.getNonemptyDescendants(id).each(function(d) { sentence_widget.setUnconsumed(d); });

    // Determine where to move reference.
    this.setSelection(tree_widget.getParentEntry(id));

    // Remove the entries.
    tree_widget.removeEntry(id);

    // If the entry represents a an empty token, remove it from the model.
    if (model.isEmpty(id))
      model.deleteEmptyToken(id);

    // Ensure that all slash select boxes are updated
    tree_widget.updateSlashSelects();

    tree_widget._updateJSON();
  },

  addEmptyEntry: function(sort) {
    var new_id;

    // Add new token to the model.
    new_id = model.createEmptyToken(sort);

    // Add a new entry to the tree widget.
    if (this.top_down)
      tree_widget.addEntry(this.selection, new_id, null, sort, null);
    else {
      var h = tree_widget.getParentEntry(this.selection);
      tree_widget.addEntry(h, new_id, this.selection, sort, null);
    }

    // Ensure that all slash select boxes are updated
    tree_widget.updateSlashSelects();

    // Determine where to move reference.
    if (this.depth_first)
      this.setSelection(new_id);

    tree_widget._updateJSON();
  },

  changeRelation: function(relation) {
    tree_widget.setRelation(tree_widget.selected, relation);
    tree_widget._updateJSON();
  },

  moveUp: function() {
    if (this.selection) {
      var new_id = tree_widget.getParentEntry(this.selection);
      if (new_id)
        this.select(new_id);
    }

    tree_widget._updateJSON();
  },

  moveDown: function() {
    if (this.selection) {
      var new_id = tree_widget.getFirstChildEntry(this.selection);
      if (new_id)
        this.select(new_id);
    }

    tree_widget._updateJSON();
  },

  moveLeft: function() {
    if (this.selection) {
      var new_id = tree_widget.getPrevSiblingEntry(this.selection);
      if (new_id)
        this.select(new_id);
    }

    tree_widget._updateJSON();
  },

  moveRight: function() {
    if (this.selection) {
      var new_id = tree_widget.getNextSiblingEntry(this.selection);
      if (new_id)
        this.select(new_id);
    }

    tree_widget._updateJSON();
  },

  addSlash: function() {
    if (this.selection)
      tree_widget.addSlash(this.selection);

    this.updateControls();
    tree_widget._updateJSON();
  },

  removeSlashes: function() {
    if (this.selection)
      tree_widget.removeSlashes(this.selection);

    this.updateControls();
    tree_widget._updateJSON();
  },

  cut: function() {
    if (this.selection) {
      //tree_widget.cut(this.selection, $('cut-buffer'));
      tree_widget.cut(this.selection, this.cut_buffer);
      this.has_cut_data = true;
      this.selection = null;
    }

    this.updateControls();
    tree_widget._updateJSON();
  },

  paste: function() {
    if (this.selection && this.has_cut_data) {
      //tree_widget.paste(this.selection, $("cut-buffer"));
      tree_widget.paste(this.selection, this.cut_buffer);
      this.has_cut_data = this.cut_buffer.length > 0;
    }

    this.updateControls();
    tree_widget._updateJSON();
  },

  // Reset structure and controls to starting state.
  reset: function() {
    // Make sure that everything is cleared first
    sentence_widget.clear();
    tree_widget.clear();

    // Update structure with whatever we got as input
    this._resetStructure(model.structure, 'ROOT');

    // Reset all controls to sane starting states
    this.resetControls();

    tree_widget._updateJSON();
  },

  _resetStructure: function(obj, parent_id) {
    $H(obj).each(function(e) {
      var token_id = e[0];
      var relation = e[1]['relation'];
      var dependents = e[1]['dependents'];
      var empty = e[1]['empty'];
      var slashes = e[1]['slashes'];

      // We may receive nodes with new IDs, i.e. unsaved empty nodes, as
      // input data. We deal with this by adding the nodes to the model
      if (token_id.startsWith('new')) {
        var token_number = Number(token_id.sub('new', ''));

        //FIXME
        var values = new Hash;
        values.set('empty', empty);
        values.set('token_number', token_number);
        model.tokens.set(token_id, values);
        if (model.new_token_number >= token_number)
          model.new_token_number = token_number + 1;
      }

      if (empty)
        tree_widget.addEntry(parent_id, token_id, null, empty, relation);
      else {
        sentence_widget.setConsumed(token_id);
        tree_widget.addEntry(parent_id, token_id, null,
          model.getWordForm(token_id), relation);
      }

      if (slashes) {
        $A(slashes).each(function(slash) {
          tree_widget.addSlash(token_id, slash);
        });
      }

      controller._resetStructure(dependents, token_id);
    });
  },

  // Behaviour changes

  toggleBuildDirection: function() { this.top_down = !this.top_down; },

  buildDownwards: function() {
    this.top_down = true;
    $('build-up').checked = false;
    $('build-down').checked = true;
  },

  // Control updating

  resetControls: function() {
    // Reset buttons
    $('button-delete').disable();
    $('button-cut').disable();
    $('button-paste').disable();
    $('button-clear').enable();
    $('button-insert-empty-conjunction-node').enable();
    $('button-insert-empty-verbal-node').enable();
    $('button-add-slash').disable();
    $('button-remove-slashes').disable();

    this.buildDownwards();

    palette.disable();

    this.setSelection('ROOT');
  },

  updateControls: function() {
    var no_actionable_element = !this.selection || this.selection == 'ROOT';

    $('button-delete').disabled = no_actionable_element;
    $('button-add-slash').disabled = no_actionable_element;

    $('build-up').disabled = no_actionable_element;
    if (no_actionable_element)
      this.buildDownwards();

    if (no_actionable_element) {
      $('button-remove-slashes').disable();
      $('button-cut').disable();
    } else {
      $('button-remove-slashes').disabled = !tree_widget.hasSlashes(this.selection);
      //$('button-cut').disabled = this.has_cut_data;
      $('button-cut').disabled = false;
    }

    if (!this.selection)
      $('button-paste').disable();
    else {
      if (this.has_cut_data)
        $('button-paste').enable();
      else
        $('button-paste').disable();
    }

    if (no_actionable_element)
      palette.disable();
    else
      palette.enable();

    // IE hacks
    updateTreeLast();
  }
});

// View

var Model = Class.create({
  initialize: function(tokens, structure, relations) {
    this.tokens = $H(tokens);
    this.structure = $H(structure);
    this.relations = $H(relations);
    this.new_token_number = 1000; //FIXME: set to highest free number
  },

  _getTokenKey: function(id, key) {
    var t = this.tokens.get(id);
    if (t)
      return $H(t).get(key);
    else
      return null;
  },

  getMorphTag: function(id) { return this._getTokenKey(id, 'morph_features'); },

  getWordForm: function(id) { return this._getTokenKey(id, 'form'); },

  // Returns true if the token is empty, false otherwise.
  isEmpty: function(id) { return id == 'ROOT' || this._getTokenKey(id, 'empty'); },

  // Returns the token number for a particular token ID
  getTokenNumber: function(id) { return this._getTokenKey(id, 'token_number'); },

  // Returns all token IDs in the structure
  getTokenIDs: function() { return this.tokens.keys(); },

  // Create new empty token
  createEmptyToken: function(sort) {
    var id = 'new' + this.new_token_number;
    var token_number = this.new_token_number;
    this.new_token_number++;

    var values = new Hash;
    values.set('empty', sort);
    values.set('token_number', token_number);
    this.tokens.set(id, values);

    return id;
  },

  // Delete empty token
  deleteEmptyToken: function(id) {
    var empty = this._getTokenKey(id, 'empty');
    if (!empty)
      throw new Error("Cannot remove non-empty token");

    this.tokens.unset(id);
  }
});

function validate(ev) {
  var errors = sentence_widget.getUnconsumedTokens();

  // Unconsumed tokens is a reliable *except* if the user has cut a
  // subtree, since the tokens in the cut subtree won't be marked as
  // unconsumed.
  if (controller.has_cut_data > 0) {
    alert("Annotation is incomplete. You have a subtree in the paste buffer.");

    Event.stop(ev) // stop event propagation
  } else if (errors.length > 0) {
    alert("Annotation is incomplete. Please correct the indicated errors before saving.");

    errors.each(function(e) {
      // Go up to the label and colour that since the input element itself isn't displayed at all
      new Effect.Highlight(e.up("label"), { startcolor: '#ff9999', endcolor: '#ffffff' });
      e.addClassName("validation-error");
    });
    Event.stop(ev) // stop event propagation
  }
}

// Document hooks

Event.observe(window, 'load', function() {
  // Create model and grab hold of input data
  model = new Model($('input-tokens').value.evalJSON(),
    $('input-structure').value.evalJSON(),
    null
    //$('input-relations').value.evalJSON()
    );

  // Set up "controller"
  controller = new Controller();

  // Create widgets
  sentence_widget = new SentenceWidget('words');
  tree_widget = new DependencyStructureWidget('relations');
  palette = new RadioGroup('palette');
  palette.disable();

  // Connect event handlers
  $('palette').observe('change', onPaletteClick);
  $('words').observe('change', onSentenceClick);
  $('relations').observe('click', onDependencyStructureClick);
  $('button-delete').observe('click', function(ev) { controller.removeEntry(); });
  $('button-clear').observe('click', function(ev) { controller.clear(); });
  $('button-reset').observe('click', function(ev) { controller.reset(); });
  $('button-insert-empty-conjunction-node').observe('click', function(ev) { controller.addEmptyEntry("C"); });
  $('button-insert-empty-verbal-node').observe('click', function(ev) { controller.addEmptyEntry("V"); });
  $('button-add-slash').observe('click', function(ev) { controller.addSlash(); });
  $('button-remove-slashes').observe('click', function(ev) { controller.removeSlashes(); });
  $('button-cut').observe('click', function(ev) { controller.cut(); });
  $('button-paste').observe('click', function(ev) { controller.paste(); });
  $('dependencies-form').observe('submit', validate, false);

  // Set starting state.
  controller.reset();

  // Set up key event observers
  Event.observe(document, 'keypress', function(e) {
    var code;
    var stop_event = false;

    if (!e)
      var e = window.event;

    if (e.keyCode)
      code = e.keyCode;
    else if (e.which)
      code = e.which;

    if (code == Event.KEY_UP) {
      controller.moveUp();
      stop_event = true;
    }
    else if (code == Event.KEY_DOWN) {
      controller.moveDown();
      stop_event = true;
    }
    else if (code == Event.KEY_LEFT) {
      controller.moveLeft();
      stop_event = true;
    }
    else if (code == Event.KEY_RIGHT) {
      controller.moveRight();
      stop_event = true;
    }
    else {
      var character = String.fromCharCode(code);

      if (character in hotkeys) {
        palette.select(hotkeys[character]);
        controller.changeRelation(hotkeys[character]);
        stop_event = true;
      }
    }

    if(stop_event) {
      Event.stop(e);
    }
  });
});
