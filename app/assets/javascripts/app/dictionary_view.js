var Pagination = Vue.extend({
  template: '<nav class="pagination"><ul>' +
            '<li v-for="p in pages">' +
            '<a href="#" @click.prevent="changePage(p)" :class="{ \'is-active\': p == pagination.page }">{{ p + 1 }}</a>' + 
            '</li>' +
            '</ul></nav>',
  props: {
    pagination: {
      type: Object,
      required: true
    },
    callback: {
      type: Function,
      required: true
    },
    offset: {
      type: Number,
      default: 0
    }
  },

  computed: {
    pages: function () {
      var arr = [];

      for (var i = 0; i < this.pagination.pages; i++) {
        if (i == 0 || i == this.pagination.pages - 1)
          arr.push(i);
      }

      return arr;
    }
  },

  watch: {
    'pagination.page': function () {
      this.callback();
    },
  },

  methods: {
    changePage: function(page) {
      this.$set('pagination.page', page);
    }
  }
});

var DictionaryView = Vue.extend({
  template: '#dictionary-view-template',

  components: {
    pagination: Pagination
  },

  data: function() {
    return {
      pagination: {
        pages: 0,
        page: 0
      },
      query_language: null,
      query_form: null,
      query_part_of_speech: null,
      lemmata: [],
      count: null,

      // TODO
      languages: {
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
      parts_of_speech: {
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
  },

  methods: {
    fetchData: function() {
      var url = makeParams({
        language: this.query_language,
        form: this.query_form,
        part_of_speech: this.query_part_of_speech,
        page: this.pagination.page
      }, '/lemmata.json');

      var xhr = new XMLHttpRequest();
      var self = this;
      xhr.open('GET', url);
      xhr.onload = function () {
        var response = JSON.parse(xhr.responseText);
        self.lemmata = response.lemmata;
        self.count = response.count;
        self.pagination.page = response.page;
        self.pagination.pages = response.pages;
      }
      xhr.send();
    }
  },

  created: function() {
    this.fetchData();
  },

  watch: {
    query_language: 'fetchData',
    query_form: 'fetchData',
    query_part_of_speech: 'fetchData'
  }
});

Vue.component('dictionary-view', DictionaryView);
