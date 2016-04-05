// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.

//= require vendor/underscore-min
//= require vendor/jquery.min
//= require vendor/jquery-ui.min
//= require vendor/jquery_ujs
//= require noconflict
//= require vendor/prototype
//= require vendor/scriptaculous
//= require utils
//= require vendor/effects
//= require vendor/dragdrop
//= require vendor/controls
//= require vendor/wz_jsgraphics
//= require anaphora
//= require prodrop
//= require info_statuses
//= require alignment
//= require dependency_alignment

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
}

if (document.readyState != 'loading') {
  setup();
} else {
  document.addEventListener('DOMContentLoaded', setup);
}
