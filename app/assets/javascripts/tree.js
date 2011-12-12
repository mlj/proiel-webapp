var ie = false;

function toggle(ev)
{
  var elm = ev.Element();
  var newDisplay = "none";
  var e = elm.nextSibling; 
  while (e != null) {
    if (e.tagName == "UL" || e.tagName == "ul") {
    if (e.style.display == "none") newDisplay = "block";
    break;
   }
   e = e.nextSibling;
  }
  while (e != null) {
   if (e.tagName == "UL" || e.tagName == "ul") e.style.display = newDisplay;
   e = e.nextSibling;
  }
}

function collapseAll() {
  var lists = document.getElementsByTagName('UL');
  for (var j = 0; j < lists.length; j++) 
    lists[j].style.display = "none";
  lists = document.getElementsByTagName('ul');
  for (var j = 0; j < lists.length; j++) 
    lists[j].style.display = "none";
  var e = document.getElementById("structure");
  e.style.display = "block";
}

function _getSubtree(lst) {
  var subtree = new Hash(); 

  var list_elements = lst.childElements();
  for (var j = 0; j < list_elements.length; j++) {
    var i = list_elements[j];
    if (i.tagName == 'LI' || i.tagName == 'li') {
      var value = new Hash();
      var id = i.identify();
      id = id.sub('rel-', '');
      var dependents = i.down("ul");
      value.set('relation', i.down("tt").innerHTML.toLowerCase());
      value.set('dependents', _getSubtree(dependents));
      subtree.set(id, value);
    }
  }

  return subtree;
}

function updateTreeLast() {
  if (ie) {
    var tree = $('relations');
    tree.descendants().each(function(e) { e.removeClassName("last-child"); });

    var lists = [ tree ]; 
    for (var i = 0; i < tree.getElementsByTagName("ul").length; i++) 
      lists[lists.length] = tree.getElementsByTagName("ul")[i];
    for (var i = 0; i < lists.length; i++) { 
      var item = lists[i].lastChild; 
      while (item && (!item.tagName || item.tagName.toLowerCase() != "li")) 
        item = item.previousSibling; 
      if (item)
        item.className += " last-child"; 
    }
  }
}

Event.observe(window, 'load', function() {
});
