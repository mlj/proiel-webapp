var Store = function() {
  this.id = null,
  this.schema = {
    relations: {}
  };
  this.sentence = {};
  this.tokenIndex = {
    'ROOT': {
      id: 'ROOT',
      relation_tag: 'ROOT',
      form: null,
      empty_token_sort: '-',
      token_number: null,
      slashes: []
    }
  };
  this.dependentIndex = {};
  this.language = null;
};

Store.prototype.buildIndexes = function(data) {
  // Build token index. Use strings since we're going to have to make
  // up some additional IDs. We've already initialised it with a root node.
  var i = {
    'ROOT': {
      id: 'ROOT',
      relation_tag: 'ROOT',
      form: null,
      empty_token_sort: '-',
      token_number: null,
      slashes: []
    }
  };

  _.each(data.tokens, function(t) { i[t.id.toString()] = t });

  // Build dependent index. Use strings here too.
  j = {};

  _.each(data.tokens, function(t) {
    var d = t.id.toString();
    var h = t.head_id ? t.head_id.toString() : 'ROOT';

    if (!j[h])
      j[h] = [];

    j[h].push(d);

    // Ensure that all tokens exist in the hash. This is to
    // preserve reactivity later: If the structure is cleared and
    // rebuilt in a different way, we can only track updates in the
    // tree view if all tokens already had arrays in the hash.
    if (!j[d])
      j[d] = [];
  });

  this.tokenIndex = i;
  this.dependentIndex = j;
};

Store.prototype._xhr = function(method, url, cb) {
  var self = this;
  var xhr = new XMLHttpRequest();

  xhr.onload = function() {
    if (xhr.status === 200)
      cb(JSON.parse(xhr.responseText));
    else {
      console.error("Remote call status " + xhr.status);
      alert("Sorry, something went wrong! We've logged the error and will look into it.");
    }
  }

  xhr.open(method, url);
  xhr.send();
}

Store.prototype.fetch = function(id, cb) {
  var self = this;

  this._xhr('GET', '/sentences/' + id + '.json', function(sentence) {
    var language = sentence.source_division.source.language_tag;

    self._xhr('GET', '/schemas/' + language + '.json', function(schema) {
      self.id = id;
      self.schema = schema;
      self.language = language;
      self.sentence = sentence;
      self.buildIndexes(sentence);
      cb();
    });
  });
};

Store.prototype.submit = function(cb) {
  // Subset the data that could potentially have been updated
  data = {
    tokens: []
  }

  for (var i = 0; i < this.sentence.tokens.length; i++) {
    var token = this.sentence.tokens[i];
    data.tokens.push({ id: token.id, msd: token.msd, lemma: token.lemma })
  }

  var url = '/sentences/' + this.id + '.json';

  var self = this;
  var xhr = new XMLHttpRequest();
  xhr.open('PUT', url);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.setRequestHeader('X-CSRF-Token', authenticity_token);
  xhr.onload = function() {
    if (xhr.status === 200) {
      console.info("Response was " + xhr.responseText);
      cb();
    } else {
      console.error("Status " + xhr.status);
      alert("Sorry, something went wrong! We've logged the error and will look into it.");
      cb();
    }
  };

  xhr.send(JSON.stringify(data));
};
