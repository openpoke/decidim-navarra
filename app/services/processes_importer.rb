# frozen_string_literal: true

require "csv"

class ProcessesImporter
  def initialize(path, organization, admin)
    @file = CSV.read(path, col_sep: ",", headers: true)
    @organization = organization
    @admin = admin
    @transformed_data = []
    @slugs = {}
    @metadata = []
  end

  def json_data
    if @transformed_data.blank?
      @file.each do |row|
        parser = ProcessesParser.new(row, @organization)
        @transformed_data << parser.transformed_data
        @metadata << parser.metadata
      end

      @es_data = @transformed_data.select { |process| process[:locale] == "es" }

      @transformed_data = @es_data.map do |es_process|
        es_process.merge!(slug: check_slug(es_process[:slug]))
        eu_process = @transformed_data.find { |p| p[:locale] == "eu" && p[:external_es_id].present? && p[:external_es_id] == es_process[:external_es_id] } || {}
        eu_process.deep_merge(es_process)
      end

      @metadata.map! do |meta_process|
        process = @transformed_data.find { |p| p[:original_id][meta_process[:locale]] == meta_process[:original_id] } || {}
        meta_process.merge!(final_slug: process[:slug])
      end
    end
    @transformed_data.to_json
  end

  def import_processes
    temp_file = Tempfile.new(["import_data", ".json"])

    begin
      temp_file.write(json_data)
      temp_file.rewind
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        original_filename: "processes_import.json"
      )
      uploaded_file.content_type = "application/json"

      form = Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessImportForm.from_params(
        slug: "import",
        title: @organization.available_locales.map { |locale| [locale, "Import"] }.to_h,
        document: uploaded_file
      ).with_context(current_organization: @organization, current_user: @admin)

      Decidim::ParticipatoryProcesses::Admin::CustomImportParticipatoryProcess.call(form)

      save_metadata
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def save_metadata
    CSV.open("metadata.csv", "wb") do |csv|
      csv << @metadata.first.keys
      @metadata.each do |hash|
        csv << hash.values
      end
    end
  end

  def check_slug(slug)
    if @slugs.has_key?(slug)
      @slugs[slug] += 1
      "#{slug}-#{@slugs[slug]}"
    else
      @slugs[slug] = 0
      slug
    end
  end
end
