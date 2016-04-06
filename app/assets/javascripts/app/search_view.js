var SearchView = Vue.extend({
  template: '#search-view-template',

  name: 'search-view',

  //components: {
  //  pagination: Pagination
  //},

  data: function() {
    return {
      query: {
        language_tag: null,
        part_of_speech_tag: null,
        status_tag: null,
        form: null,
        lemma: null,
        part_of_speech_tag: null,
        relation_tag: null,
        information_status_tag: null
      },

      tokens: []
    };
  },

  methods: {
    fetchData: function() {
      var tokenResource = this.$resource('/tokens{/id}');
      var definedQuery = _.pick(this.query, _.identity);

      tokenResource.get(definedQuery).then(function(response) {
        this.$set('tokens', response.data);
      }, function(response) {
      });
    }
  },

  created: function() {
    this.fetchData();
  },

  watch: {
    'query.language_tag': 'fetchData',
    'query.part_of_speech_tag': 'fetchData',
    'query.status_tag': 'fetchData',
    'query.form': 'fetchData',
    'query.lemma': 'fetchData',
    'query.part_of_speech_tag': 'fetchData',
    'query.relation_tag': 'fetchData',
    'query.information_status_tag': null
  }
});
