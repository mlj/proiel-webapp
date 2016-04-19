var Tree = Vue.extend({
  template: '#tree-template',

  props: {
    us: Object,
    model: Object
  },

  data: function() {
    return {
      store: store
    };
  },

  computed: {
    form: function() {
      return this.us.form || this.us.empty_token_sort;
    },

    children: function() {
      var self = this;
      var dependentIDs = this.store.dependentIndex[this.us.id];
      return _.map(dependentIDs, function(id) { return self.store.tokenIndex[id]; });
    },

    hasChildren: function () {
      return this.children.length > 0;
    },

    isSelected: function() {
      return this.model.selected == this.us.id.toString();
    }
  },

  methods: {
    select: function() {
      this.model.selected = this.us.id.toString();
    }
  }
});

Vue.component('tree', Tree);
