// Based on https://github.com/pespantelis/vue-typeahead
Vue.component('typeahead', {
  template: '#typeahead-template',

  props: {
    store: Object,
    query: String
  },

  data: function() {
    return {
      items: [],
      current: -1,
      loading: false,
      limit: 5,
      src: '/lemmata/autocomplete.json'
    };
  },

  computed: {
    hasItems: function() {
      return this.items.length > 0;
    },

    isEmpty: function() {
      return !this.query;
    },

    isDirty: function() {
      return !!this.query;
    }
  },

  methods: {
    update: function() {
      if (!this.query) {
        this.reset();
        return;
      }

      this.loading = true;

      var self = this;
      var xhr = new XMLHttpRequest();
      var url = this.src;
      xhr.open('GET', url + '?form=' + this.query + '&language=' + this.store.language);
      xhr.onload = function () {
        if (xhr.status === 200) {
          var data = JSON.parse(xhr.responseText);
          self.items = !!self.limit ? data.slice(0, self.limit) : data;
          self.current = -1;
          self.loading = false;
        } else {
          console.error("Status " + xhr.status);
          alert("Sorry, something went wrong! We've logged the error and will look into it.");
        }
      }
      xhr.send();
    },

    reset: function() {
      this.items = [];
      this.query = '';
      this.loading = false;
    },

    setActive: function(index) {
      this.current = index;
    },

    activeClass: function(index) {
      return {
        active: this.current == index
      };
    },

    hit: function() {
      if (this.current === -1)
        return;

      this.query = this.items[this.current].form;
    },

    up: function() {
      if (this.current > 0)
        this.current--;
      else if (this.current == -1)
        this.current = this.items.length - 1;
      else
        this.current = -1;
    },

    down: function() {
      if (this.current < this.items.length-1)
        this.current++;
      else
        this.current = -1;
    }
  }
});
