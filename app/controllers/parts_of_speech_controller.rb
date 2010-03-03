class PartsOfSpeechController < InheritedResources::Base
  actions :index, :show

  def show
    @part_of_speech = PartOfSpeech.find(params[:id])
    @lemmata = @part_of_speech.lemmata.search(params[:query], :page => params[:page])

    show!
  end

  private

  def collection
    @parts_of_speech = PartOfSpeech.search(params[:query], :page => params[:page])
  end
end
