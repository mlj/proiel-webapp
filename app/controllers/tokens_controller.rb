class TokensController < ResourceController::Base # ApplicationController
  before_filter :is_reviewer?
  before_filter :is_administrator?, :only => [ :edit, :update ]
  actions :all, :except => [ :new, :create, :destroy ]

  private

  def collection
    @tokens = Token.search(params.slice(:source, :form, :exact), params[:page])
  end

  update.before do
    if params[:token]
      if params[:token][:presentation_form] == ''
        params[:token][:presentation_form] = nil
      else
        params[:token][:presentation_form] = params[:token][:presentation_form].chars.normalize(UNICODE_NORMALIZATION_FORM)
      end
      params[:token][:morphtag] = nil if params[:token][:morphtag] == ''
      params[:token][:lemma_id] = nil if params[:token][:lemma_id] == ''
      params[:token][:form] = params[:token][:form].chars.normalize(UNICODE_NORMALIZATION_FORM)
    end
  end
end
