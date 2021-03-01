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
      documentation: "Documentación",
      links: "Enlaces"
    },
    eu: {
      documentation: "Dokumentazioa",
      links: "Estekak"
    }
  }.with_indifferent_access.freeze

  def initialize(row, organization)
    @raw_content = row
    @organization = organization
    @locale = raw_content["Idioma"] == "Euskera" ? "eu" : "es"
  end

  def transformed_data
    {
      "title": localized_attribute("Titulo"),
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
      "local_area": nil,
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
      raw_description: raw_content["Descripcion - HTML"],
      first_paragraph_description: short_description,
      original_url: "https://gobiernoabierto.navarra.es#{raw_content["Ruta"]}",
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
    @image_url ||= raw_content["Imagen URL"].presence&.gsub(/\s/, "")
  end

  def external_es_id
    @external_es_id ||= raw_content["Nodo castellano"].strip.presence
  end

  def external_id
    @external_id ||= raw_content["NID"].strip.presence
  end

  def short_description
    splitted_description.first.to_s
  end

  def remaining_description
    raw_content["Descripcion - HTML"]
  end

  def splitted_description
    @splitted_description ||= Nokogiri::HTML.parse(raw_content["Descripcion - HTML"]).text.split("\n").select(&:present?)
  end

  def split_description_by_tags(*tags)
    html = raw_content["Descripcion - HTML"]
    tags.each do |tag|
      next if (elements = Nokogiri::HTML.parse(html).css(tag)).blank?

      return elements
    end

    nil
  end

  def description_html
    <<-HTML
    #{remaining_description}

    #{links}

    #{documentation}
    HTML
  end

  def slug_value
    value = slug(raw_content["Ruta"].split("/").last)

    return value if value.present?

    slug(raw_content["Titulo"])
  end

  def documentation
    return unless has_value?("Documentacion URL")

    urls = raw_content["Documentacion URL"].split(",").map(&:strip)

    descriptions = if urls.count > 1
                     raw_content["Documentacion"].split(",").map(&:strip)
                   else
                     [raw_content["Documentacion"].presence&.strip]
                   end.compact

    descriptions = urls if descriptions.count != urls.count

    links_list = descriptions.zip(urls).map do |description, url|
      "<li><a href=\"#{url}\">#{description}</a></li>"
    end.join("\n")

    <<-HTML
    <div>
      <p>
        <h3>#{translate(:documentation)}</h3>
        <ul>
           #{links_list}
        </ul>
      </p>
    </div>
    HTML
  end

  def links
    return unless has_value?("Enlaces")

    splitted_text = raw_content["Enlaces"].split("http").map do |text|
      parts = text.split(", ")
      next parts if parts.count < 3

      [parts.shift, parts.join(", ")]
    end.flatten

    links_list = splitted_text.each_slice(2).map do |link|
      "<li><a href=\"http#{link[1]}\">#{link[0]}</a></li>"
    end.join("\n")

    <<-HTML
    <div>
      <p>
        <h3>#{translate(:links)}</h3>
        <ul>
         #{links_list}
        </ul>
      </p>
    </div>
    HTML
  end

  def title
    localized_attribute("Titulo")
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
    participation_status == "Cerrado"
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
