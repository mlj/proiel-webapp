var form_language;
var morphtag_selection = new ExclusiveSelectionClass('selected', false);
var palette;

var PaletteWidget = Class.create({
  initialize: function(id, id_guesses) {
    this.widget = $(id);
    this.guesses = $(id_guesses);
  },

  activate: function() { this.widget.show(); },

  deactivate: function() { this.widget.hide(); },

  clearSuggestions: function() { 
    removeAllChildren(this.guesses); 
    this.guesses.insert("<label>Suggestions:</label> ");
  },

  addSuggestion: function(text, suggestion) {
    this.guesses.insert("<input type='button' value='" + text +
      "' onclick='onGuessClick(" + '"' + suggestion + '"' + ")'/> ");
  },

  showSuggestions: function() { this.guesses.show(); },

  hideSuggestions: function() { this.guesses.hide(); },

  setLemma: function(lemma) { $('morphtags_lemma').value = lemma; },

  setMorphtags: function(fields) {
    // Clear out all the old values to avoid contamination from existing selections.
    field_sequence.each(function(field) { $(field + '_field').options.length = 0; });

    cascadedFieldUpdate(form_language, 'pos', fields);
  }
});

function onTokenSelect(token_id)
{
  morphtag_selection.onSelection($('item-' + token_id), onActivate, onDeactivate);
}

// Updates the activated token with guess values.
function onGuessClick(morph_features) {
  var current_lemma = decodeMorphFeaturesLemma(morph_features);
  var current_pos = decodeMorphFeaturesPOS(morph_features);
  var current_morphology = decodeMorphFeaturesMorphology(morph_features);

  var fields = current_morphology;
  fields['pos'] = current_pos;
  palette.setMorphtags(fields);
  palette.setLemma(current_lemma);

  onPaletteUpdate();
}

// Updates the guess/tag palette for the activated token.
function onActivate(element)
{
  palette.activate();

  var id = element.identify();
  id = id.sub('item-', '');

  // Handle precomputed guesses, if any
  var suggestions = $F('suggestions-' + id).evalJSON();

  if (suggestions) {
    palette.clearSuggestions();

    suggestions.each(function(suggestion) {
      palette.addSuggestion(present_pos_tag(decodeMorphFeaturesPOS(suggestion)) + ', ' +
        present_morphology(decodeMorphFeaturesMorphology(suggestion)) +
        ' (' + decodeMorphFeaturesLemma(suggestion) + ')', suggestion);
    });

    palette.showSuggestions();
  } else
    palette.hideSuggestions();

  // Set the information from the activated token.
  var current_features = $F('morph-features-' + id);
  var n = current_features.split(',');
  var current_lemma = decodeMorphFeaturesLemma(current_features);
  var current_pos = decodeMorphFeaturesPOS(current_features);
  var current_morphology = decodeMorphFeaturesMorphology(current_features);

  var fields = current_morphology;
  fields['pos'] = current_pos;
  palette.setMorphtags(fields);
  palette.setLemma(current_lemma);
}

function onDeactivate(element)
{
  palette.deactivate();
}

// Updates the current item's morphtag and lemma based on the palette's current
// settings.
function onPaletteUpdate()
{
  var tags = new Hash();

  field_sequence.each(function(t) {
    tags[t] = getSelectSelection($(t + '_field'));
  });

  var element = morphtag_selection.getSelection();
  var id = element.identify();
  id = id.sub('item-', '');

  $('morph-features-' + id).value = encodeMorphFeatures(form_language, $F('morphtags_lemma'), tags['pos'], tags);

  onUpdateTokenPresentation(element);
}

// Updates the presentation fields for a token.
function onUpdateTokenPresentation(element) {
  var id = element.identify().sub('item-', '');
  var mf = $F('morph-features-' + id);
  var current_lemma = decodeMorphFeaturesLemma(mf);
  var current_pos = decodeMorphFeaturesPOS(mf);
  var current_morphology = decodeMorphFeaturesMorphology(mf);

  // Update human readable display
  var pos = element.down('.pos');
  pos.innerHTML = present_pos_tag(current_pos);

  var morphology = element.down('.morphology');
  morphology.innerHTML = present_morphology(current_morphology);

  var lemma = element.down('.lemma');
  lemma.innerHTML = present_lemma(current_lemma);

  element.removeClassName('validation-error');
}

function getTokenIDs() {
  return $F('token-ids').evalJSON();
}

function validateToken() {
  var errors = new Array();
  var ids = getTokenIDs();

  ids.each(function(id) {
    if (!$F("morph-features-" + id)) {
      errors.push(id);
      validated = false;
    }
  });

  return errors;
}

function validate(ev) {
  var errors = validateToken().uniq();

  if (errors.length > 0) {
    alert("Annotation is incomplete. Please correct the indicated errors before saving.");

    errors.each(function(id) {
      new Effect.Highlight($("item-" + id), { startcolor: '#ff9999', endcolor: '#ffffff' });
      $("item-" + id).addClassName("validation-error");
    });
    Event.stop(ev) // stop event propagation
  }
}

function fieldSelected(ev) {
  var element = Event.element(ev);
  var updated_field = element.id.sub('_field', '');

  cascadedFieldUpdate(form_language, updated_field, null);
}

document.observe('dom:loaded', function() {
  palette = new PaletteWidget('palette', 'guesses');

  $('morphtag-form').observe('submit', validate, false);

  $$('div.item').each(function(el) { onUpdateTokenPresentation(el); });

  palette.deactivate();

  field_sequence.each(function(field) {
    $(field + '_field').observe('change', fieldSelected);
  });

  form_language = $F('form-language');
});
