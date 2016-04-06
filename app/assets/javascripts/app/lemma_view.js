var LemmaView = Vue.extend({
  template: '#lemma-view-template',

  name: 'lemma-view',

  components: {
    pagination: Pagination
  },

  route: {
    data: function(transition) {
      this.fetchData();
    }
  },

  data: function() {
    return {
      pagination: {
        pages: 0,
        page: 0
      },

      lemma: {
        id: null,
        form: null,
        gloss: null,
        part_of_speech_tag: null,
        language_tag: null,
        foreign_ids: null
      },

      tokens: [],

      // TODO
      language_tags: {
        "grc": "Ancient Greek (to 1453)",
        "chu": "Church Slavic",
        "xcl": "Classical Armenian",
        "got": "Gothic",
        "lat": "Latin",
        "ang": "Old English (ca. 450-1100)",
        "fro": "Old French (842-ca. 1400)",
        "non": "Old Norse",
        "orv": "Old Russian",
        "por": "Portuguese",
        "san": "Sanskrit",
        "spa": "Spanish"
      },
      part_of_speech_tags: {
        // TODO
        "A-": {
          "long": "adjective",
          "short": "adj."
        }, "C-": {
          "long": "conjunction",
          "short": "conj."
        }, "Df": {
          "long": "adverb","short":"adv."},"Dq":{"long":"relative adverb","short":"rel. adv."},"Du":{"long":"interrogative adverb","short":"interrog. adv."},"F-":{"long":"foreign word","short":"foreign word"},"G-":{"long":"subjunction","short":"subj."},"I-":{"long":"interjection","short":"interj."},"Ma":{"long":"cardinal numeral","short":"card. num."},"Mo":{"long":"ordinal numeral","short":"ord. num."},"N-":{"long":"infinitive marker","short":"inf. marker"},"Nb":{"long":"common noun","short":"common noun"},"Ne":{"long":"proper noun","short":"proper noun"},"Pc":{"long":"reciprocal pronoun","short":"recipr. pron."},"Pd":{"long":"demonstrative pronoun","short":"dem. pron."},"Pi":{"long":"interrogative pronoun","short":"interrog. pron."},"Pk":{"long":"personal reflexive pronoun","short":"pers. refl. pron."},"Pp":{"long":"personal pronoun","short":"pers. pron."},"Pr":{"long":"relative pronoun","short":"rel. pron."},"Ps":{"long":"possessive pronoun","short":"poss. pron."},"Pt":{"long":"possessive reflexive pronoun","short":"poss. refl. pron."},"Px":{"long":"indefinite pronoun","short":"indef. pron."},"Py":{"long":"quantifier","short":"quant."},"R-":{"long":"preposition","short":"prep."},"S-":{"long":"article","short":"art."},"V-":{"long":"verb","short":"verb"},"X-":{"long":"unassigned","short":"unass."}}
    }
  },

  computed: {
    language: function() {
      return this.lemma.language_tag ? this.language_tags[this.lemma.language_tag] : null;
    },

    part_of_speech: function() {
      return this.lemma.part_of_speech_tag ? this.part_of_speech_tags[this.lemma.part_of_speech_tag].long : null;
    }
  },

  methods: {
    editable: function(e, field) {
      var self = this;

      this.$editable(e, function(value) {
        Vue.http.headers.common['X-CSRF-Token'] = authenticity_token;

        var resource = self.$resource('/lemmata{/id}');

        var data = {};
        data[field] = value;

        resource.update({ id: self.lemma.id }, { lemma: data }).then(function(response) {
          self.fetchData();
        });
      });
    },

    fetchData: function() {
      var lemmaResource = this.$resource('/lemmata{/id}');
      var tokenResource = this.$resource('/tokens{/id}');
      var lemma_id = this.$route.params.params.id; //FIXME: what?

      lemmaResource.get({ id: lemma_id }).then(function(response) {
        this.$set('lemma', response.data);
      }, function(response) {
          // error callback
      });

      tokenResource.get({ lemma_id: lemma_id }).then(function(response) {
        this.$set('tokens', response.data);
      }, function(response) {
      });
    }
  },

  created: function() {
    this.fetchData();
  },

  watch: {
  }
});
