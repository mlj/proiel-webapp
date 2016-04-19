var MorphologyEditor = Vue.extend({
  template: '#morphology-editor-template',

  data: function() {
    return {
      store: store,
      selected: null
    }
  },

  filters: {
    posToText: function(pos) {
      return this.present_pos_tag(pos);
    },

    msdToText: function(msd) {
      return this.present_morphology(msd);
    },

    lemmaToForm: function(lemma) {
      return lemma.form;
    },

    lemmaToGloss: function(lemma) {
      return lemma.gloss ? ("‘" + lemma.gloss + "’") : "";
    }
  },

  computed: {
    // Returns an array of tokens ordered by token number. Only visible tokens have a valid token number, so only visible tokens are included.
    orderedTokens: function() {
      return _.sortBy(
          _.reject(this.store.sentence.tokens, function(t) { return !!t.empty_token_sort; }),
          function(t) { return t.token_number });
    },

    schema: function() {
      return this.store.schema;
    },

    sentence: function() {
      return this.store.sentence;
    },

    availablePartsOfSpeech: function() {
      var tags = _.keys(this.schema.tag_space).sort();
      var a = [];

      for (var i = 0; i < tags.length; i++) {
        var tag = tags[i];

        if (tag != '-')
          a.push({ tag: tag, long: this.schema.explanations.part_of_speech_tags[tag].long });
      }

      return a;
    },

    availableInflections: function() {
      return this.extractLegalFieldValues("inflection");
    },

    availableMoods: function() {
      return this.extractLegalFieldValues("mood");
    },

    availableTenses: function() {
      return this.extractLegalFieldValues("tense");
    },

    availableVoices: function() {
      return this.extractLegalFieldValues("voice");
    },

    availableDegrees: function() {
      return this.extractLegalFieldValues("degree");
    },

    availableCases: function() {
      return this.extractLegalFieldValues("case");
    },

    availablePersons: function() {
      return this.extractLegalFieldValues("person");
    },

    availableNumbers: function() {
      return this.extractLegalFieldValues("number");
    },

    availableGenders: function() {
      return this.extractLegalFieldValues("gender");
    },

    availableStrengths: function() {
      return this.extractLegalFieldValues("strength");
    },

    isSelected: function() {
      return this.selected !== null;
    },

    selectedToken: function() {
      for (var i = 0; i < this.sentence.tokens.length; i++) {
        if (this.sentence.tokens[i].id == this.selected)
          return this.sentence.tokens[i];
      }

      return null;
    },

    suggestions: function() {
      return this.selectedToken.guesses;
    },

    isValid: function() {
      if (this.sentence && this.sentence.tokens) {
        for (var i = 0; i < this.sentence.tokens.length; i++) {
          var token = this.sentence.tokens[i];

          if (!token.empty_token_sort) {
            if (token.lemma.form === null || token.lemma.form === '')
              return false;
          }
        }

        return true;
      } else
        return false;
    }
  },

  methods: {
    submit: function() {
      this.$parent.save();
    },

    makeRegExp: function(field) {
      var fieldDisplayOrder = ['inflection', 'mood', 'tense', 'voice', 'degree', 'case', 'person', 'number', 'gender', 'strength'];
      var s = {
        person     : ".",
        number     : ".",
        tense      : ".",
        mood       : ".",
        voice      : ".",
        gender     : ".",
        case       : ".",
        degree     : ".",
        strength   : ".",
        inflection : "."
      }

      for (var i = 0; i < fieldDisplayOrder.length; i++) {
        var f = fieldDisplayOrder[i];

        if (field == f)
          break;

        s[f] = this.selectedToken.msd[f];
      }

      return [
        s.person    ,
        s.number    ,
        s.tense     ,
        s.mood      ,
        s.voice     ,
        s.gender    ,
        s.case      ,
        s.degree    ,
        s.strength  ,
        s.inflection
      ].join('');
    },

    extractLegalFieldValues: function(field) {
      var pos = this.selectedToken.lemma.part_of_speech_tag;
      var r = new RegExp("^" + this.makeRegExp(field));
      var position = this.schema.positions[field];
      var fields = new Array;
      var space = this.schema.tag_space[pos];

      if (space) {
        for (var i = 0; i < space.length; i++) {
          if (space[i].match(r))
            fields.push(space[i][position]);
        }
      }

      var tags = _.uniq(fields);
      var a = [];

      for (var i = 0; i < tags.length; i++) {
        var tag = tags[i];

        if (tag != '-')
          a.push({
            tag: tag,
            text: this.schema.explanations.msd_tags[field][tag].long
          });
      }

      return a;
    },

    present_pos_tag: function(pos) {
      return pos ? this.schema.explanations.part_of_speech_tags[pos].short : '';
    },

    present_morphology: function(msd) {
      var s = new Array;

      for (var i = 0; i < this.schema.field_sequence.length; i++) {
        var tag = this.schema.field_sequence[i];
        value = msd[tag];
        if (value && value != '-')
          s.push(this.schema.explanations.msd_tags[tag][value].short);
      }

      return s.join(', ');
    },

    formatSuggestion: function(suggestion) {
      return this.present_pos_tag(suggestion.lemma.part_of_speech_tag) + ", " + this.present_morphology(suggestion.msd) + " (" +  suggestion.lemma.form + ")";
    },

    select: function(id) {
      /* Unselect when user clicks already selected token */
      this.selected = this.selected == id ? null : id;
    },

    guess: function(suggestion) {
      this.selectedToken.lemma.form = suggestion.lemma.form;
      this.selectedToken.lemma.part_of_speech_tag = suggestion.lemma.part_of_speech_tag;
      this.selectedToken.msd = suggestion.msd;
    }
  }
});

Vue.component('morphology-editor', MorphologyEditor);
