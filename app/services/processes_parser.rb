# frozen_string_literal: true

# An example implementation of an AuthorizationHandler to be used in tests.
class ProcessesParser
  attr_reader :raw_content, :organization

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

  def initialize(row, organization)
    @raw_content = row
    @organization = organization
  end

  def transformed_data
    {
      "title": translated_attribute("Title"),
      "subtitle": has_value?("Subtítulo") ? translated_attribute("Subtítulo") : translated_attribute("Departamento"),
      "slug": slug_value,
      "hashtag": nil,
      "short_description": translated_attribute("Descripción HTML"),
      "description": translatable_hash(description_html),
      "announcement": nil,
      "start_date": start_date,
      "end_date": end_date,
      "remote_hero_image_url": nil,
      "remote_banner_image_url": nil,
      "developer_group": translated_attribute("Unidad responsable"),
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
      "scopes_enabled": true
    }
  end

  private

  def description_html
    <<-HTML
    #{raw_content["Descripción HTML"]}

    <p>
      URL del proceso: <a hfref="https://gobiernoabierto.navarra.es#{raw_content["Ruta"]}">https://gobiernoabierto.navarra.es#{raw_content["Ruta"]}</a>
    </p>

    #{links}

    #{documentation}
    HTML
  end

  def slug_value
    value = slug(raw_content["Ruta"].split("/").last)

    return value if value.present?

    slug(raw_content["Title"])
  end

  def documentation
    return unless has_value?("Documentacion")

    <<-HTML
    <div>
      <p>
        <h3>Documentación</h3>
         #{raw_content["Documentacion"]}
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
        <h3>Enlaces</h3>
        <ul>
         #{links_list}
        </ul>
      </p>
    </div>
    HTML
  end

  def title
    translated_attribute("Title")
  end

  def start_date
    ActiveSupport::TimeZone["Europe/Madrid"].parse(raw_content["Fecha del envío"])
  end

  def end_date
    participation_closed? ? extract_date(raw_content["Fecha actualización"]) : default_open_end_date
  end

  def default_open_end_date; end

  def participation_closed?
    raw_content["Estado del proceso de participacion"] == "Cerrado"
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
      name: translatable_hash("Tipo de propuesta"),
      plural: translatable_hash("Tipos de propuesta")
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
      name: translatable_hash("Legislatura"),
      plural: translatable_hash("Legislaturas")
    )
  end

  def department_scope_type
    @department_scope_type ||= organization.scope_types.find_or_create_by(
      name: translatable_hash("Departamento"),
      plural: translatable_hash("Departamentos")
    )
  end

  def translated_attribute(attribute)
    translatable_hash(raw_content[attribute])
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
    @available_locales ||= %w(en es)
  end
end
