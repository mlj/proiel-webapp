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

var authenticity_param;
var authenticity_token;

function setup() {
  authenticity_param = document.querySelector('meta[name="csrf-param"]').content;
  authenticity_token = document.querySelector('meta[name="csrf-token"]').content;

  jQuery(".formatted-text .reviewed, .formatted-text .annotated, .formatted-text .unannotated").hide();
  jQuery(".table-of-source-divisions .reviewed, .table-of-source-divisions .annotated, .table-of-source-divisions .unannotated").hide();

  if (jQuery('#toggle-sentence-status')) {
    jQuery('#toggle-sentence-status').click(function() {
      jQuery(".formatted-text .reviewed, .formatted-text .annotated, .formatted-text .unannotated").toggle();
      jQuery(".table-of-source-divisions .reviewed, .table-of-source-divisions .annotated, .table-of-source-divisions .unannotated").toggle();
      return false;
    });
  }

  jQuery(".toggle-hidden").each(function(i, el) {
    jQuery(el).hide();
    jQuery('<a href="#">Show ' + jQuery(el).attr('title') + ' </a>').insertBefore(el).click(function() {
      jQuery(el).toggle();
      return false;
    });
  });
}

if (document.readyState != 'loading') {
  setup();
} else {
  document.addEventListener('DOMContentLoaded', setup);
}
