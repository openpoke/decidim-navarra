# frozen_string_literal: true

require "rails_helper"

describe "CollaborativeTexts" do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
  end

  it "renders the collaborative texts page" do
    visit decidim.collaborative_texts_path
    expect(page).to have_content("Collaborative Texts")
  end
end
