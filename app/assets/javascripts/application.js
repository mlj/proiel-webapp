// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//= require jquery.min
//= require jquery-ui.min
//= require jquery_ujs

$(function() {
  $(".formatted-text .reviewed, .formatted-text .annotated, .formatted-text .unannotated").hide();
  $(".table-of-source-divisions .reviewed, .table-of-source-divisions .annotated, .table-of-source-divisions .unannotated").hide();

  if ($('#toggle-sentence-status')) {
    $('#toggle-sentence-status').click(function() {
      $(".formatted-text .reviewed, .formatted-text .annotated, .formatted-text .unannotated").toggle();
      $(".table-of-source-divisions .reviewed, .table-of-source-divisions .annotated, .table-of-source-divisions .unannotated").toggle();
      return false;
    });
  }

  $(".toggle-hidden").each(function(i, el) {
    $(el).hide();
    $('<a href="#">Show ' + $(el).attr('title') + ' </a>').insertBefore(el).click(function() {
      $(el).toggle();
      return false;
    });
  });
});
