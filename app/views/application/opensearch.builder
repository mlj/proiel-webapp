xml.instruct!
xml.OpenSearchDescription(:xmlns => 'http://a9.com/-/spec/opensearch/1.1/', 'xmlns:moz' => 'http://www.mozilla.org/2006/browser/search/') do
  xml.ShortName(t(:short_title))
  xml.InputEncoding('UTF-8')
  xml.Description(t(:opensearch_description))
  xml.Image(File.join(root_url, asset_path('icon.png')), height: 16, width: 16, type: 'image/png')
  xml.Url(type: 'text/html', method: 'get', template: CGI::unescape(quick_search_url(q: '{searchTerms}' )))
  xml.Url(type: 'application/x-suggestions+json', method: 'get', template: CGI::unescape(quick_search_url(format: :js, q: '{searchTerms}' )))
  xml.moz(:SearchForm, root_url)
end
