class PartsOfSpeechController < ReadOnlyController
  show.before do
    @lemmata = @part_of_speech.lemmata.search(params[:query], :page => params[:page])
  end

  private

  def collection
    @parts_of_speech = PartOfSpeech.search(params[:query], :page => params[:page])
  end
end
