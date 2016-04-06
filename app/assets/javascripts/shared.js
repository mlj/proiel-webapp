function makeParams(data, baseURL)
{
  var q = [];

  for (var d in data)
    if (data.hasOwnProperty(d) && data[d] && data[d] != '')
      q.push(encodeURIComponent(d) + "=" + encodeURIComponent(data[d]));

  return baseURL + "?" + q.join("&");
}
