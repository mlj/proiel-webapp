//= require vendor/jquery.min
//= require vendor/jquery-ui.min
//= require vendor/jquery_ujs
//= require noconflict
//= require vendor/prototype
//= require vendor/scriptaculous
//= require vendor/effects
//= require vendor/dragdrop
//= require vendor/controls
//= require vendor/wz_jsgraphics
//= require anaphora
//= require prodrop
//= require info_statuses
//= require alignment
//= require dependency_alignment
//= require underscore
//= require vue
//= require vue-resource
//= require vue-router
//= require app/store
//= require app/typeahead
//= require app/morphology_editor
//= require app/tree
//= require app/syntax_editor
//= require app/editable
//= require app/app

var authenticity_param;
var authenticity_token;

function setup() {
  authenticity_param = document.querySelector('meta[name="csrf-param"]').content;
  authenticity_token = document.querySelector('meta[name="csrf-token"]').content;

  var nl = document.querySelectorAll('.formatted-text .reviewed, .formatted-text .annotated, .formatted-text .unannotated');

  for (var i = 0; i < nl.length; i++) {
    nl[i].style.display = 'none';
  }

  var el = document.querySelector('#toggle-sentence-status');

  if (el) {
    el.addEventListener('click', function(e) {
      for (var i = 0; i < nl.length; i++) {
        var d = nl[i].style.display;

        if (d === 'none')
          nl[i].style.display = '';
        else
          nl[i].style.display = 'none';
      }
      return false;
    });
  }

  // Hook up legacy information structure editor
  if (document.querySelector('#server-message')) {
    Prodrop.init();
    InfoStatus.init();
  }

  if (document.querySelector('#info-status')) {
    document.observe('dom:loaded', function() {
      AnaphoraAndContrast.init();
      AnaphoraAndContrast.showAntecedentsForAllAnaphors();
    });
  }

  // Hook up legacy alignment editors
  if (document.querySelector('#button-commit') && document.querySelector('#alignment-view'))
    alignmentSetup();

  if (document.querySelector('#dependency-alignment-editor'))
    dependencyAlignmentSetup();

  // Hook up progressive enhancment Vue apps
  if (document.querySelector('#app-graph')) {
    new Vue({
      el: '#app-graph',
      data: {
        current: null,
        modes: ["unsorted", "linearized", "packed", "full"],
        graph: ''
      },
      ready: function() {
        this.current = this.$el.dataset.method
      },
      watch: {
        current: function(n) {
          var self = this;
          var xhr = new XMLHttpRequest();
          var url = this.$el.dataset.graphUrl;
          xhr.open('GET', url + '?method=' + this.current);
          xhr.onload = function () {
            if (xhr.status === 200) {
              self.graph = xhr.responseText;
            } else {
              alert("Sorry, something went wrong! We've logged the error and will look into it.");
            }
          }
          xhr.send();
        }
      }
    })
  }
}

if (document.readyState != 'loading') {
  setup();
} else {
  document.addEventListener('DOMContentLoaded', setup);
}
