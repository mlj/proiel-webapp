var change = 0;
var max = 0;
var min = 0;

function shortenAfter()
{
  if (change > min) {
    change--;
    updateSelections();
  }
}

function expandAfter() 
{
  if (change < max) {
    change++;
    updateSelections();
  }
}

function updateSelections()
{
  for (var i = min; i <= max; i++) {
    var e = $('change' + i);

    if (e) { // There may be fewer than max tokens available, so test if it is there first
      if (change >= i)
        e.addClassName('covered');
      else
        e.removeClassName('covered');
    }
  }
}

function onSubmit()
{
  $('change').value = change;
}

document.observe('dom:loaded', function() {
  // Figure out what the limits are by looking for adjustable elements.
  for (var i = -3; i <= 0; i++) {
    if ($('change' + i)) {
      min = i - 1;
      break
    }
  }

  for (var i = 3; i >= 0; i--) {
    if ($('change' + i)) {
      max = i;
      break
    }
  }

  $('submit').observe('click', onSubmit);
});
