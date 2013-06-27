require 'spec_helper'

describe TokensController do
  login_user

  describe 'GET #opensearch' do
    it "responds successfully with an HTTP 200 status code" do
      get :opensearch, format: :xml
      expect(response).to be_success
      expect(response.status).to eq(200)
    end

    it "renders the opensearch template" do
      get :opensearch, format: :xml
      expect(response).to render_template('application/opensearch')
    end

    it "has application/opensearchdescription+xml mime type" do
      get :opensearch, format: :xml
      expect(response.header['Content-Type']).to eq('application/opensearchdescription+xml; charset=utf-8')
    end 
  end
end
