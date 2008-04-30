module BrowseHelper
  def generalised_pagination(collection, current_object, title_generator, url_generator, options = {})
    s = []
    s << link_to_unless(current_object == collection.first, 
      '&laquo; Previous', url_generator[collection.first]) unless options[:no_prev]

    collection.each do |o|
      s << link_to_unless(current_object == o, title_generator[o], url_generator[o])
    end

    s << link_to_if(current_object != collection.last, 
      'Next &raquo;', url_generator[collection.last]) unless options[:no_next]

    "<div class='pagination'>#{s.join(' ')}</div>"
  end

  def source_paginate(sources, current_source, current_book, current_chapter)
    generalised_pagination(sources, current_source, 
                         lambda { |o| o.presentation_form },
                         lambda { |o| { :source => o, :book => current_book, :chapter => current_chapter } },
                          :no_prev => true, :no_next => true)
  end

  def book_paginate(source, current_book, current_chapter)
    books = source.books
    generalised_pagination(source.books, current_book, 
                         lambda { |o| o.presentation_form },
                         lambda { |o| { :source => source, :book => o, :chapter => current_chapter } },
                          :no_prev => true, :no_next => true)
  end

  def chapter_paginate(source, book, chapter, chapter_min, chapter_max)
    s = '<div class="pagination">'
    s << ' '
    s << link_to_if(chapter > chapter_min, '&laquo; Previous', { :source => source, :book => book, :chapter => chapter - 1})
    s << ' '
    (chapter_min..chapter_max).each do |i|
      s << link_to_if(chapter != i, i.to_s, { :source => source, :book => book, :chapter => i })
      s << ' '
    end
    s << link_to_if(chapter < chapter_max, 'Next &raquo;', { :source => source, :book => book, :chapter => chapter + 1 })
    s << '</div>'
  end

end
