# frozen_string_literal: true

# An example implementation of an AuthorizationHandler to be used in tests.
class ProcessesParser
  attr_reader :raw_content, :organization, :locale

  MONTH_NAMES = {
    "Enero" => 1,
    "Febrero" => 2,
    "Marzo" => 3,
    "Abril" => 4,
    "Mayo" => 5,
    "Junio" => 6,
    "Julio" => 7,
    "Agosto" => 8,
    "Septiembre" => 9,
    "Octubre" => 10,
    "Noviembre" => 11,
    "Diciembre" => 12
  }.freeze

  TRANSLATIONS = {
    es: {
      detail: "Contenido relacionado",
      documentation: "Documentación",
      links: "Enlaces",
      participation_steps: "Periodos de participación"
    },
    eu: {
      detail: "Lotutako edukia",
      documentation: "Dokumentazioa",
      links: "Estekak",
      participation_steps: "Parte hartzeko aldiak"
    }
  }.with_indifferent_access.freeze

  FILES_BASE_URL = "https://gobiernoabierto.navarra.es/sites/default/files/"
  DEFAULT_IMAGE_FILENAME = "participacion_proceso_base.png"

  def initialize(row, organization)
    @raw_content = row
    @organization = organization
    @locale = %w(Euskara Euskera).include?(raw_content["Idioma"]) ? "eu" : "es"
  end

  def transformed_data
    {
      "title": localized_attribute("Título"),
      "subtitle": has_value?("Subtítulo") ? localized_attribute("Subtítulo") : localized_attribute("Departamento"),
      "slug": slug_value,
      "hashtag": nil,
      "short_description": localized(short_description),
      "description": localized(description_html),
      "announcement": nil,
      "start_date": start_date,
      "end_date": end_date,
      "remote_hero_image_url": image_url,
      "remote_banner_image_url": image_url,
      "developer_group": localized_attribute("Unidad responsable"),
      "local_area": localized_attribute("Departamento"),
      "meta_scope": nil,
      "participatory_scope": nil,
      "participatory_structure": nil,
      "target": nil,
      "area": area_data,
      "participatory_process_group": nil,
      "scope": scope_data,
      "attachments": { "files": nil },
      "components": nil,
      "scopes_enabled": true,
      "external_es_id": external_es_id,
      "original_id": { locale => external_id },
      "locale": locale
    }
  end

  def metadata
    start_date_string = start_date.to_date.to_s
    end_date_string = end_date&.to_date&.to_s
    {
      original_id: external_id,
      description_paragraphs_count: splitted_description.count,
      raw_description: raw_content["Descripcion HTML"],
      first_paragraph_description: short_description,
      original_url: raw_content["Ruta"],
      locale: locale,
      original_language: raw_content["Idioma"],
      es_node_id: raw_content["Nodo castellano"],
      proposal_status: proposal_status,
      participation_status: participation_status,
      start_and_end_date_coincident: start_date_string == end_date_string,
      start_date: start_date.to_date.to_s,
      end_date: end_date&.to_date&.to_s,
      original_slug: slug_value,
      final_slug: nil
    }
  end

  private

  def image_url
    @image_url ||= URI.join(FILES_BASE_URL, image_filename)
  end

  def image_filename
    return DEFAULT_IMAGE_FILENAME if raw_content["Imagen"].blank?

    # GIFs are not accepted for hero images
    return DEFAULT_IMAGE_FILENAME if /\.gif\z/i =~ raw_content["Imagen"]

    raw_content["Imagen"].gsub(/\s/, "")
  end

  def external_es_id
    @external_es_id ||= raw_content["Nodo castellano"].strip.presence
  end

  def external_id
    @external_id ||= raw_content["NID"].strip.presence
  end

  def description_first_present_element_index
    @description_first_present_element_index ||= splitted_description.find_index { |element| element.text.strip.present? }
  end

  def short_description
    splitted_description.slice(description_first_present_element_index).to_html
  end

  def remaining_description
    splitted_description.slice((description_first_present_element_index + 1)..).to_html
  end

  def participation_steps
    return unless raw_content["Participacion fases"].present?

    list = raw_content["Participacion fases"].gsub(/,\s*([A-Z])/,"||||\\1").split("||||")

    html_list = list.map do |step|
      "<li>#{step}</li>"
    end.join("\n")

    <<-HTML
    <div>
      <p>
        <h3>#{translate(:participation_steps)}</h3>
        <ul>
          #{html_list}
        </ul>
      </p>
    </div>
    HTML
  end

  def splitted_description
    @splitted_description ||= Nokogiri::HTML.parse(raw_content["Descripcion HTML"]).xpath("//body").children
  end

  def split_description_by_tags(*tags)
    html = raw_content["Descripcion HTML"]
    tags.each do |tag|
      next if (elements = Nokogiri::HTML.parse(html).css(tag)).blank?

      return elements
    end

    nil
  end

  def description_html
    <<-HTML
    #{remaining_description}

    #{list_of_links_from("Enlaces", :links)}

    #{list_of_links_from("Documentacion", :documentation)}

    #{list_of_links_from("Contenidos subespacio", :detail)}

    #{participation_steps}
    HTML
  end

  def slug_value
    value = slug(raw_content["Ruta"].split("/").last)

    return value if value.present?

    slug(raw_content["Título"])
  end

  def list_of_links_from(raw_attribute_name, title_key)
    return unless has_value?(raw_attribute_name)

    list = urls_list(raw_content[raw_attribute_name])

    links_list = list.map do |link|
      "<li><a href=\"#{link[:url]}\">#{link[:text].presence || link[:url]}</a></li>"
    end.join("\n")

    <<-HTML
    <div>
      <p>
        <h3>#{translate(title_key)}</h3>
        <ul>
           #{links_list}
        </ul>
      </p>
    </div>
    HTML
  end

  def urls_list(text)
    splitted_texts = text.split("@@").map do |fragment|
      fragment.partition(URI.regexp(%w(http https)))
    end

    extractions = splitted_texts.map do |partition|
      partition = partition.reject(&:blank?)
      url = partition.find { |fragment| URI.regexp(%w(http https)) =~ fragment }
      description = (partition - [url]).first

      { text: description&.strip, url: url&.gsub(/,\z/, "") }
    end

    (0..(extractions.count - 2)).map do |index|
      { text: extractions[index][:text], url: extractions[index + 1][:url] }
    end
  end

  def title
    localized_attribute("Título")
  end

  def translate(key)
    TRANSLATIONS[locale][key]
  end

  def localized(text)
    { locale => text }
  end

  def start_date
    ActiveSupport::TimeZone["Europe/Madrid"].parse(raw_content["Fecha del envío"])
  end

  def end_date
    participation_closed? ? extract_date(raw_content["Fecha actualización"]) : default_open_end_date
  end

  def default_open_end_date; end

  def participation_closed?
    proposal_status == "Cerrado"
  end

  def proposal_status
    raw_content["Estado de la propuesta de gobierno"]
  end

  def participation_status
    raw_content["Estado del proceso de participacion"]
  end

  def extract_date(text)
    day_month, year = text.split(", ")[1, 2]
    day, month_name = day_month.split(" ")
    Date.new(year.to_i, MONTH_NAMES[month_name], day.to_i)
  end

  def area_data
    area.attributes.slice("id", "name")
  end

  def area
    @area ||= area_type.areas.find_or_create_by(name: translatable_hash(raw_content["Tipo de propuesta"]), organization: organization)
  end

  def area_type
    @area_type ||= organization.area_types.find_or_create_by(
      name: { es: "Tipo de propuesta", eu: "Proposamen mota" },
      plural: { es: "Tipos de propuesta", eu: "Proposamen motak" }
    )
  end

  def scope_data
    scope.attributes.slice("id", "name")
  end

  def scope
    @scope ||= begin
                 legislature_id = if raw_content["Legislatura"].present?
                                    legislature_scope_type.scopes.find_or_create_by(
                                      name: translatable_hash(raw_content["Legislatura"]),
                                      organization: organization,
                                      code: raw_content["Legislatura"]
                                    ).id
                                  end
                 department_scope_type.scopes.find_or_create_by(
                   name: translatable_hash(raw_content["Departamento"]),
                   parent_id: legislature_id,
                   organization: organization,
                   code: "#{raw_content["Legislatura"]}-#{raw_content["Departamento"]}"
                 )
               end
  end

  def legislature_scope_type
    @legislature_scope_type ||= organization.scope_types.find_or_create_by(
      name: { es: "Legislatura", eu: "Legebiltzarra" },
      plural: { es: "Legislaturas", eu: "Legebiltzarrak" }
    )
  end

  def department_scope_type
    @department_scope_type ||= organization.scope_types.find_or_create_by(
      name: { es: "Departamento", eu: "Sail" },
      plural: { es: "Departamentos", eu: "Sailak" }
    )
  end

  def localized_attribute(attribute)
    localized(raw_content[attribute])
  end

  def translatable_hash(text)
    available_locales.map do |locale|
      [locale, text]
    end.to_h
  end

  def has_value?(attribute)
    raw_content[attribute].present?
  end

  def slug(attribute)
    attribute.gsub(/\A[^a-zA-Z]+/, "").tr("_", " ").parameterize
  end

  def available_locales
    @available_locales ||= organization.available_locales
  end
end
