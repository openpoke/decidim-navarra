# frozen_string_literal: true

require "csv"

class AssembliesImporter
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
        parser = AssembliesParser.new(row, @organization)
        @transformed_data << parser.transformed_data
        @metadata << parser.metadata
      end

      @metadata.map! do |meta_assembly|
        assembly = @transformed_data.find { |p| p[:original_id] == meta_assembly[:original_id] } || {}
        meta_assembly.merge!(final_slug: assembly[:slug])
      end
    end
    @transformed_data.to_json
  end

  def import_assemblies
    temp_file = Tempfile.new(["import_data", ".json"])

    begin
      temp_file.write(json_data)
      temp_file.rewind
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        original_filename: "assemblies_import.json"
      )
      uploaded_file.content_type = "application/json"

      form = Decidim::Assemblies::Admin::AssemblyImportForm.from_params(
        slug: "import",
        title: @organization.available_locales.index_with { |_locale| "Import" },
        document: uploaded_file
      ).with_context(current_organization: @organization, current_user: @admin)

      Decidim::Assemblies::Admin::CustomImportAssembly.call(form)

      save_metadata
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def save_metadata
    CSV.open("assemblies_metadata.csv", "wb") do |csv|
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
