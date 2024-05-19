# frozen_string_literal: true

require "csv"

class ProcessesTypeUpdater
  AVAILABLE_PROCESSES = {
    "Consulta pública previa" => { title: { "es" => "Consulta pública previa", "eu" => "Aurretiazko kontsulta publikoa" } },
    "Normativa en elaboración" => { title: { "es" => "Normativa en elaboración", "eu" => "Garatzen ari diren araudia" } }
  }.freeze

  attr_accessor :file, :organization, :transformed_data

  def initialize(path, organization)
    @file = CSV.read(path, col_sep: ",", headers: true)
    @organization = organization
    @transformed_data = []
    @slugs = {}
    @metadata = []
  end

  def processes_search
    @processes_search ||= file.map do |row|
      [
        row,
        Decidim::ParticipatoryProcess.where(organization: organization).find { |process| process.title["es"] == row["Nombre del proceso"] }
      ]
    end
  end

  def processes_found
    @processes_found ||= processes_search.select { |item| item[1].present? }
  end

  def transform_processes
    processes_found.each do |row, process|
      process_type = Decidim::ParticipatoryProcessType.find_or_create_by(AVAILABLE_PROCESSES[row["Tipo de proceso"]].merge(organization: organization))
      process.update_attribute(:decidim_participatory_process_type_id, process_type.id)

      @transformed_data << process
    end
  end

  def metadata
    missing_processes = processes_search - processes_found
    {
      missing_processes_count: missing_processes.count,
      transformed_processes_count: transformed_data.count,
      transformed_processes_ids: transformed_data.map(&:id).join(", ")
    }
  end
end
