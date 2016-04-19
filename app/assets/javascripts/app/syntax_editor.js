var SyntaxEditor = Vue.extend({
  template: '#syntax-editor-template',

  data: function() {
    return {
      store: store,

      selected: 'ROOT',
      cutBuffer: null,
      buildDirection: "down",
      depthFirst: true,

      hotkeys: {
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
      }
    }
  },

  computed: {
    schema: function() {
      return this.store.schema;
    },

    language: function() {
      return this.store.language;
    },

    tokenIndex: function() {
      return this.store.tokenIndex;
    },

    dependentIndex: function() {
      return this.store.dependentIndex;
    },

    isValid: function() {
      return _.every(this.tokenIndex, function(t) { return !!t.relation_tag; }) && !this.cutBuffer;
    },

    newTokenNumber: function() {
      var t = _.reject(this.tokenIndex, function(t) { return t.relation_tag == 'ROOT'; });

      if (_.isEmpty(t))
        return 0;
      else
        return _.max(t, function(t) { return t.token_number; }).token_number + 1;
    },

    parentTokenID: function() {
      return this.findParentTokenID(this.selected);
    },

    rootToken: function() {
      return this.tokenIndex['ROOT'];
    },

    // Returns an array of tokens ordered by token number. Only visible tokens have a valid token number, so only visible tokens are included.
    orderedTokens: function() {
      return _.sortBy(
          _.reject(this.tokenIndex, function(t) { return !!t.empty_token_sort; }),
          function(t) { return t.token_number });
    },

    selectedToken: function() {
      return this.tokenIndex[this.selected];
    },

    topDown: function() {
      return this.buildDirection == "down";
    },

    noActionableElement: function() {
      return !this.selected || this.selected == 'ROOT';
    },

    noCutableElement: function() {
      return this.selected == 'ROOT' || this.cutBuffer;
    },

    noPasteableElement: function() {
      return this.selected == 'ROOT' || !this.cutBuffer;
    },

    noRemoveableSlashes: function() {
      return this.noActionableElement || !this.hasSlashes(this.selected);
    }
  },

  methods: {
    testInferenceCriteria: function(head, dependent, criteria) {
      var failure = _.some(criteria, function(value, key) {
        var a, k;

        if (key == "language") {
          k = "language";
          a = head;
        } else {
          l = key.split("_");
          k = l[1];

          if (l[0] == "head")
            a = head;
          else if (l[0] == "dependent")
            a = dependent;
          else {
            console.error("unknown inference criterion " + key);
            return true;
          }
        }

        var v;

        switch (k) {
          case 'language':
            v = this.language;
            break;
          case 'pos':
            v = a.lemma ? a.lemma.part_of_speech_tag : null;
            break;
          case 'relation':
            v = a.relation_tag;
            break;
          case 'finite':
            v = a.msd ? ("ismo".indexOf(a.msd.mood) != -1) : null;
            break;
          case 'mood':
            v = a.msd ? a.msd.mood : null;
            break;
          case 'case':
            v = a.msd ? a.msd.case : null;
            break;
          case 'lemma':
            v = a.lemma ? a.lemma.form : null;
            break;
          default:
            v = null;
        }

        if (!v) // Treat the absence of a value as false
          v = false;

        var c = new RegExp(value);

        return !c.test(v);
      });

      return !failure;
    },

    guessRelation: function(head, dependent) {
      var c = _.find(this.schema.relation_inferences,
                     function(clause) {
                       if (!clause.criteria || this.testInferenceCriteria(head, dependent, clause.criteria))
                         return true;
                     }, this);

      if (c)
        return c.actions.inferred_relation == 'COPY' ? head.relation_tag : c.actions.inferred_relation;
      else {
        console.error("relation inference failed");
        return "AUX";
      }
    },

    submit: function() {
      this.$parent.save();
    },

    isConsumed: function(token) {
      return !!token.relation_tag;
    },

    findParentTokenID: function(tokenID) {
      return _.findKey(this.dependentIndex,
                       function(dependents, id) {
                         return _.some(dependents,
                                       function(id) {
                                         return id == tokenID;
                                       },
                                       this);
                       },
                       this);
    },

    hasSlashes: function(id) {
      return this.tokenIndex[id].slashes.length > 0;
    },

    // Cut subtree and store in cut buffer
    cut: function() {
      if (this.selected) {
        this.cutBuffer = this.selected;
        this.removeTokenFromDependentIndex(this.selected);
      }
    },

    // Paste subtree stored in cut buffer
    paste: function() {
      if (this.selected && this.cutBuffer) {
        this.addTokenToDependentIndex(this.selected, this.cutBuffer);
        this.cutBuffer = null;
      }
    },

    reset: function() {
      this.$parent.reset();
    },

    clear: function() {
      this.selected = 'ROOT';

      _.each(this.dependentIndex['ROOT'], function(id) {
        this.removeSubtree(id);
      }, this);
    },

    remove: function() {
      if (this.selected != 'ROOT') { // check we don't remove the ROOT so that we can assume there is always a parent
        var id = this.selected;
        this.selected = this.parentTokenID;
        this.removeSubtree(id);
      }
    },

    collectSubtreeIDs: function(id) {
      var ids = _.flatten(_.map(this.dependentIndex[id], function(i) { return this.collectSubtreeIDs(i); }, this));
      ids.push(id);
      return ids;
    },

    removeSubtree: function(id) {
      if (this.tokenIndex[id].relation_tag != 'ROOT') { // never alter the root token
        // Remove ourself from the tree
        this.removeTokenFromDependentIndex(id);

        // Clean the dependent index and token index for ourself and all our dependents
        var ids = this.collectSubtreeIDs(id);

        _.each(ids, function(i) {
          this.tokenIndex[i].relation_tag = null;
          this.tokenIndex[i].slashes = [];
          this.dependentIndex[i] = [];

          if (this.tokenIndex[i].empty_token_sort) {
            delete this.tokenIndex[i];
            delete this.dependentIndex[i];

            // Remove any references to this token from other tokens' slash lists.
            _.each(this.tokenIndex,
                   function(j) {
                     //TODO
                   },
                   this);
          }
        }, this);
      }
    },

    // Removes a token (= the subtree headed by the token) from the dependent
    // index. Returns true if successful.
    removeTokenFromDependentIndex: function(id) {
      var p = this.findParentTokenID(id);

      if (p) {
        var i = this.dependentIndex[p].indexOf(id);

        if (i > -1) {
          this.dependentIndex[p].splice(i, 1);
          return true;
        }
      }

      return false;
    },

    addTokenToDependentIndex: function(head, dependent) {
      this.dependentIndex[head].push(dependent);
    },

    addToStructure: function(new_token_id, parent_token_id, childTokenID) {
      this.tokenIndex[new_token_id].relation_tag =
        this.guessRelation(this.tokenIndex[parent_token_id], this.tokenIndex[new_token_id]);

      this.dependentIndex[parent_token_id].push(new_token_id);

      if (childTokenID) {
        // Detach child from its current parent
        this.removeTokenFromDependentIndex(childTokenID);

        // Add child to new parent
        this.addTokenToDependentIndex(new_token_id, childTokenID);
      }
    },

    addEntry: function(idToInsert, idOfInsertionPoint) {
      if (this.topDown)
        this.addToStructure(idToInsert, idOfInsertionPoint, null);
      else
        this.addToStructure(idToInsert, this.parentTokenID, idOfInsertionPoint);

      if (this.depthFirst) // Move to inserted token if doing depth first insertions
        this.selected = idToInsert;
    },

    addEmptyC: function() {
      this.addEmpty("C");
    },

    addEmptyV: function() {
      this.addEmpty("V");
    },

    addEmpty: function(sort) {
      var newID = 'new' + this.newTokenNumber;

      this.tokenIndex[newID] = {
        id: newID,
        relation_tag: null,
        form: null,
        empty_token_sort: sort,
        token_number: this.newTokenNumber,
        slashes: []
      }

      this.dependentIndex[newID] = [];

      //TODO: make this available in slash select boxes

      this.addEntry(newID, this.selected);
    },

    addSlash: function() {
      if (this.selected)
        this.tokenIndex[this.selected].slashes.push({ target_id: this.selected });
    },

    removeSlashes: function() {
      if (this.selected)
        this.tokenIndex[this.selected].slashes = [];
    },

    keyHandler: function(e) {
      if (this.selected) {
        var stop_event = true;

        if (!e)
          var e = window.event;

        var code = e.keyCode || e.which;

        switch (code) { // Note: WebKit-based browsers do not fire events for arrow keys
          case 38: // up
            this.selected = this.parentTokenID;
            break;
          case 40: // down
            this.selected = this._depgetFirstChildEntry(); //TODO
            break;
          case 37: // left
            this.selected = this._depgetPrevSiblingEntry(); //TODO
            break;
          case 39: // right
            this.selected = this._depgetNextSiblingEntry(); //TODO
            break;
          default:
            var character = String.fromCharCode(code);

            if (character in this.hotkeys)
              this.tokenIndex[this.selected].relation_tag = this.hotkeys[character];
            else
              stop_event = false;
        }

        if (stop_event) {
          e.preventDefault();
          e.stopPropagation();
        }
      }
    }
  },

  watch: {
    selected: function(newValue, oldValue) {
      if (!this.tokenIndex[newValue].relation_tag)
        // Token without relation tag selected. This means user wants to insert
        // a token in the tree. newValue is the ID of the token to be inserted
        // and oldValue is the ID of the insertion point.
        this.addEntry(newValue, oldValue);
    }
  },

  ready: function() {
    document.addEventListener('keypress', self.keyHandler);
  }
});

Vue.component('syntax-editor', SyntaxEditor);
