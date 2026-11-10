# frozen_string_literal: true

require "rails_helper"

describe "CollaborativeTextsDocumentsNaturalOrdering" do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:collaborative_text_component, participatory_space: participatory_process) }

  describe "Document ordering by SQL" do
    before do
      create(:collaborative_text_document, component: component, title: "1. First")
      create(:collaborative_text_document, component: component, title: "2. Second")
      create(:collaborative_text_document, component: component, title: "9. Ninth")
      create(:collaborative_text_document, component: component, title: "10. Tenth")
      create(:collaborative_text_document, component: component, title: "20. Twentieth")
      create(:collaborative_text_document, component: component, title: "Apple")
      create(:collaborative_text_document, component: component, title: "Banana")
      create(:collaborative_text_document, component: component, title: "Zebra")
    end

    it "orders documents with leading numbers numerically before non-numeric titles" do
      documents = Decidim::CollaborativeTexts::Document.where(decidim_component_id: component.id).order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
      titles = documents.map(&:title)

      expect(titles).to eq([
                             "1. First",
                             "2. Second",
                             "9. Ninth",
                             "10. Tenth",
                             "20. Twentieth",
                             "Apple",
                             "Banana",
                             "Zebra"
                           ])
    end

    # rubocop:disable Naming/VariableNumber
    it "ensures 9 comes before 10 with natural numeric sorting" do
      documents = Decidim::CollaborativeTexts::Document.where(decidim_component_id: component.id).order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
      titles = documents.map(&:title)

      index_9 = titles.index("9. Ninth")
      index_10 = titles.index("10. Tenth")

      expect(index_9).to be < index_10
    end
    # rubocop:enable Naming/VariableNumber

    it "sorts non-numeric titles alphabetically" do
      documents = Decidim::CollaborativeTexts::Document.where(decidim_component_id: component.id).order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
      non_numeric_titles = documents.reject { |d| d.title =~ /^\d/ }.map(&:title)

      expect(non_numeric_titles).to eq(%w(Apple Banana Zebra))
    end
  end

  describe "Document ordering with leading zeros" do
    before do
      create(:collaborative_text_document, component: component, title: "01. Leading Zero")
      create(:collaborative_text_document, component: component, title: "1. No Leading Zero")
      create(:collaborative_text_document, component: component, title: "100. Hundred")
    end

    it "handles leading zeros correctly in numeric sort" do
      documents = Decidim::CollaborativeTexts::Document.where(decidim_component_id: component.id).order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
      titles = documents.map(&:title)

      expect(titles).to include("01. Leading Zero", "1. No Leading Zero", "100. Hundred")
      expect(titles.index("100. Hundred")).to be > titles.index("1. No Leading Zero")
    end
  end

  describe "Document ordering with special characters" do
    before do
      create(:collaborative_text_document, component: component, title: "1. Special @#$%")
      create(:collaborative_text_document, component: component, title: "2. More @#$%")
      create(:collaborative_text_document, component: component, title: "First @#$% Item")
    end

    it "sorts correctly with special characters" do
      documents = Decidim::CollaborativeTexts::Document.where(decidim_component_id: component.id).order(
        Arel.sql("COALESCE((substring(title from '^\\d+'))::integer, 999999), title")
      )
      titles = documents.map(&:title)

      numeric_count = titles.count { |t| t =~ /^\d/ }
      expect(numeric_count).to eq(2)
      expect(titles[0..1]).to eq(["1. Special @#$%", "2. More @#$%"])
    end
  end
end
