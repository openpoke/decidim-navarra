# frozen_string_literal: true

require "csv"

class ProcessesImporter
  def initialize(path, organization, admin)
    @file = CSV.read(path, col_sep: ";", headers: true)
    @organization = organization
    @admin = admin
    @transformed_data = []
    @slugs = {}
  end

  def json_data
    if @transformed_data.blank?
      @file.each do |row|
        processed_row = ProcessesParser.new(row, @organization).transformed_data
        processed_row.merge!(slug: check_slug(processed_row[:slug]))
        @transformed_data << processed_row
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
        title: { en: "Import" },
        document: uploaded_file
      ).with_context(current_organization: @organization, current_user: @admin)

      Decidim::ParticipatoryProcesses::Admin::CustomImportParticipatoryProcess.call(form)
    ensure
      temp_file.close
      temp_file.unlink
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
