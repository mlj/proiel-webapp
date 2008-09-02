class BrowseController < ApplicationController
  def view 
    source, book, chapter, verse = params.values_at(:source, :book, :chapter, :verse).collect { |i| i.to_i }
    @sentence_numbers = params[:sentence_numbers] || false
    @verse_numbers = params[:verse_numbers] || true

    # Grab hold of the actual objects and watch the range constraints.
    @source = Source.find(source)

    book_min = Sentence.minimum(:book_id, :conditions => { :source_id => @source })
    book_max = Sentence.maximum(:book_id, :conditions => { :source_id => @source })
    @book = Book.find(clamp(book, book_min, book_max))

    @chapter_min = Sentence.minimum(:chapter, :conditions => { :source_id => @source, :book_id => @book })
    @chapter_max = Sentence.maximum(:chapter, :conditions => { :source_id => @source, :book_id => @book })
    @chapter = clamp(chapter, @chapter_min, @chapter_max)

    #FIXME: watch the ranges
    @verse = verse

    # Set navigational information
    @title = @book.title
    @subsection = @source.title
    @subsubsection = @book.title

    @tokens = @source.tokens.find(:all,
                                  :conditions => [ "sentences.book_id = ? AND sentences.chapter = ?", @book,  @chapter ],
                                  :include => [:sentence, :lemma])

    render :layout => false if request.xhr?
  end
end
