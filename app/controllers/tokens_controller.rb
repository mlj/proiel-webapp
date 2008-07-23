class TokensController < ResourceController::Base # ApplicationController
  before_filter :is_reviewer?
  before_filter :is_administrator?, :only => [ :edit, :update ]
  actions :all, :except => [ :new, :create, :destroy ]

  private

  def collection
    @tokens = Token.search(params.slice(:source, :form, :exact, :major, :minor, :person, :number, :tense, :mood, :voice, :gender, :case, :degree, :extra), params[:page])
  end

  update.before do
    if params[:token]
      params[:token][:presentation_form] = nil if params[:token][:presentation_form] == ''
      params[:token][:morphtag] = nil if params[:token][:morphtag] == ''
      params[:token][:lemma_id] = nil if params[:token][:lemma_id] == ''
    end
  end
end
