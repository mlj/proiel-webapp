var App = Vue.extend({
  data: function() {
    return {
      loading: false,
      id: null,
      store: store
    }
  },

  ready: function() {
    //this.id = this.$el.dataset.sentenceId;
    this.id = window.location.pathname.sub('/sentences/', '').sub('/annotation', '');
    this.reset();
  },

  methods: {
    save: function() {
      this.loading = true;
      var self = this;

      this.store.submit(function() {
        console.log("Saved sentence " + self.id);
        self.loading = false;
      });
    },

    reset: function() {
      this.loading = true;
      var self = this;

      this.store.fetch(this.id, function() {
        console.log("Loaded sentence " + self.id);
        self.loading = false;
      });
    }
  }
});
