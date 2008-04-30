function onNumberingChange(ev) {
  switch (ev.element().identify()) {
  case 'chapter-numbers':
    $$('.chapter-number').invoke('toggle');
    break;
  case 'verse-numbers':
    $$('.verse-number').invoke('toggle');
    break;
  case 'sentence-numbers':
    $$('.sentence-number').invoke('toggle');
    break;
  case 'token-numbers':
    $$('.token-number').invoke('toggle');
    break;
  }
}

document.observe('dom:loaded', function() {
  // Connect observers  
  $('chapter-numbers').observe('change', onNumberingChange);
  $('verse-numbers').observe('change', onNumberingChange);
  $('sentence-numbers').observe('change', onNumberingChange);
  $('token-numbers').observe('change', onNumberingChange);

  // Set defaults
  $('chapter-numbers').checked = true;
  $('verse-numbers').checked = true;
  $('sentence-numbers').checked = true;
  $$('.chapter-number', '.verse-number', '.sentence-numbers').invoke('show');

  $('token-numbers').checked = false;
  $$('.token-number').invoke('hide');
});
