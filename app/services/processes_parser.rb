# frozen_string_literal: true

# An example implementation of an AuthorizationHandler to be used in tests.
class ProcessesParser
  attr_reader :raw_content, :organization, :locale, :files_base_url

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
  REGULATORY_PARTICIPATION_GROUP_VALUES = ["Consulta pública previa", "Norma"]
  PROCESS_GROUPS_ATTRIBUTES = [
    {
      id: 1,
      title: { "es" => "Procesos de participación", "eu" => "Partaidetza prozesuak" },
      description: { "es" => "<p>[Texto para confirmar]</p>", "eu" => "<p>[Texto para confirmar]</p>" },
      hashtag: "procesos-de-participacion"
    },
    {
      id: 2,
      title: { "es" => "Participación en normativa", "eu" => "Araudietan parte hartzea" },
      description: { "es" => "<p>[Texto para confirmar]</p>", "eu" => "<p>[Texto para confirmar]</p>" },
      hashtag: "participacion-en-normativa"
    }
  ].freeze

  DEPARTMENTS_TRANSLATIONS = {
    "Gobierno de Navarra" => "Nafarroako Gobernua",
    "Departamento de Presidencia, Igualdad, Función Pública e Interior" => "Lehendakaritzako, Berdintasuneko, Funtzio Publikoko eta Barneko Departamentua",
    "Departamento de Ordenación del Territorio, Vivienda, Paisaje y Proyectos Estratégicos" => "Lurralde Antolamenduko, Etxebizitzako, Paisaiako eta Proiektu Estrategikoetako Departamentua",
    "Departamento de Cohesión Territorial" => "Lurralde Kohesiorako Departamentua",
    "Departamento de Economía y Hacienda" => "Ekonomia eta Ogasun Departamentua",
    "Departamento de Desarrollo Económico y Empresarial" => "Garapen Ekonomiko eta Enpresarialeko Departamentua",
    "Departamento de Políticas Migratorias y Justicia" => "Migrazio Politiketako eta Justiziako Departamentua",
    "Departamento de Educación" => "Hezkuntza Departamentua",
    "Departamento de Derechos Sociales" => "Eskubide Sozialetako Departamentua",
    "Departamento de Salud" => "Osasun Departamentua",
    "Departamento de Relaciones Ciudadanas" => "Herritarrekiko Harremanetako Departamentua",
    "Departamento de Universidad, Innovación y Transformación Digital" => "Unibertsitateko, Berrikuntzako eta Eraldaketa Digitaleko Departamentua",
    "Departamento de Desarrollo Rural y Medio Ambiente" => "Landa Garapeneko eta Ingurumeneko Departamentua",
    "Departamento de Cultura y Deporte" => "Kultura eta Kirol Departamentua",
    "----------------- Otras legislaturas ----------------------------------------------------" => "----------------- Beste legealdi batzuk ----------------------------------------------------",
    "Otros órganos" => "Beste organo batzuk",
    "Departamento de Desarrollo Económico" => "Garapen Ekonomikorako Departamentua",
    "Departamento de Hacienda y Política Financiera" => "Ogasuneko eta Finantza Politikako Departamentua",
    "Departamento de Presidencia, Función Pública, Interior y Justicia" => "Lehendakaritzako, Funtzio Publikoko, Barneko eta Justiziako Departamentua",
    "Departamento de Relaciones Ciudadanas e Institucionales" => "Herritarrekiko eta Erakundeekiko Harremanetako Departamentua",
    "Departamento de Cultura, Deporte y Juventud" => "Kultura, Kirol eta Gazteriako Departamentua",
    "Departamento de Desarrollo Rural, Medio Ambiente y Administración Local" => "Landa Garapeneko, Toki Administrazioko eta Ingurumeneko Departamentua",
    "Departamento de Presidencia, Justicia e Interior" => "Lehendakaritza, Justizia eta Barnea Departamentua",
    "Departamento de Relaciones Institucionales y Portavoz del Gobierno" => "Erakundeekiko Harremanetarako eta Eleduna Departamentua",
    "Departamento de Administración Local" => "Toki Administrazioa Departamentua",
    "Departamento de Asuntos Sociales, Familia, Juventud y Deporte" => "Familia, Gazteria, Kirol eta Gizarte Gaiak Departamentua",
    "Departamento de Cultura y Turismo / Institución Príncipe de Viana" => "Vianako Printzea Erakundea-Kultura eta Turismo Departamentua",
    "Departamento de Obras Públicas, Transportes y Comunicaciones" => "Herri Lan, Garraio eta Komunikazioak Departamentua",
    "Departamento de Vivienda y Ordenación del Territorio" => "Lurraldearen Antolamendu eta Etxebizitza Departamentua",
    "Departamento de Innovación, Empresa y Empleo" => "Berrikuntza, Enpresa eta Enplegu Departamentua",
    "Departamento de Presidencia, Administraciones Públicas e Interior" => "Lehendakaritza, Administrazio Publikoak eta Barnea Departamentua",
    "Departamento de Cultura, Turismo y Relaciones Institucionales" => "Kultura, Turismoa eta Erakunde Harremanak Departamentua",
    "Departamento de Política Social, Igualdad, Deporte y Juventud" => "Gizarte Politika, Berdintasuna, Kirola eta Gazteria Departamentua",
    "Departamento de Desarrollo Rural, Industria, Empleo y Medio Ambiente" => "Landa Garapena, Industria, Enplegua eta Ingurumena Departamentua",
    "Departamento de Fomento y Vivienda" => "Sustapena eta Etxebizitza Departamentua",
    "Departamento de Economía, Hacienda, industria y Empleo" => "Ekonomia, Ogasun, Industria eta Enplegua Departamentua",
    "Departamento de Políticas Sociales" => "Gizarte Politikak Departamentua",
    "Departamento de Fomento" => "Sustapena Departamentua"
  }

  AREAS_ATTRIBUTES = [
    { id: 1, name: { es: "Acción Exterior", eu: "Kanpo Ekintza" } },
    { id: 2, name: { es: "Agricultura, Ganadería", eu: "Nekazaritza, Abeltzaintza" } },
    { id: 3, name: { es: "Asociacionismo, Participación, Voluntariado", eu: "Elkarteak, Partaidetza, Boluntariotza" } },
    { id: 4, name: { es: "Asuntos Sociales", eu: "Gizarte gaiak" } },
    { id: 5, name: { es: "Caza, Pesca", eu: "Ehiza, Arrantza" } },
    { id: 6, name: { es: "Ciencia, Tecnología, Investigación", eu: "Zientzia, Teknologia, Ikerketa" } },
    { id: 7, name: { es: "Comercio, Consumo", eu: "Merkataritza, Kontsumoa" } },
    { id: 8, name: { es: "Comunicación y redes sociales", eu: "Komunikazioa eta sare sozialak" } },
    { id: 9, name: { es: "Convivencia, Memoria Histórica", eu: "Bizikidetza, Memoria Historikoa" } },
    { id: 10, name: { es: "Cultura, Arte", eu: "Kultura, Artea" } },
    { id: 11, name: { es: "Deporte, Ocio", eu: "Kirola, Aisia" } },
    { id: 12, name: { es: "Economía", eu: "Ekonomia" } },
    { id: 13, name: { es: "Educación, Formación", eu: "Hezkuntza, Prestakuntza" } },
    { id: 14, name: { es: "Empleo", eu: "Lana" } },
    { id: 15, name: { es: "Empresa, Industria, Energía", eu: "Enpresa, Industria, Energia" } },
    { id: 16, name: { es: "Estadística", eu: "Estatistika" } },
    { id: 17, name: { es: "Igualdad", eu: "Berdintasuna" } },
    { id: 18, name: { es: "Infraestructuras, Obras Públicas", eu: "Azpiegiturak, Herri Lanak" } },
    { id: 19, name: { es: "Legislación, Justicia, Seguridad", eu: "Legedia, Justizia, Segurtasuna" } },
    { id: 20, name: { es: "Medio Ambiente, Espacios Naturales", eu: "Ingurumena, Naturguneak" } },
    { id: 21, name: { es: "Migración", eu: "Migrazioa" } },
    { id: 22, name: { es: "Movilidad, Transportes", eu: "Mugikortasuna, Garraioa" } },
    { id: 23, name: { es: "Salud", eu: "Osasuna" } },
    { id: 24, name: { es: "Sector Público", eu: "Sektore publikoa" } },
    { id: 25, name: { es: "Territorio, Paisaje, Urbanismo", eu: "Lurraldea, Paisaia, Hirigintza" } },
    { id: 26, name: { es: "Transparencia", eu: "Gardentasuna" } },
    { id: 27, name: { es: "Turismo", eu: "Turismoa" } },
    { id: 28, name: { es: "Vivienda", eu: "Etxebizitza" } }
  ].freeze

  def initialize(row, organization, opts = {})
    @raw_content = row
    @organization = organization
    @locale = %w(Euskara Euskera).include?(raw_content["Idioma"]) ? "eu" : "es"
    @files_base_url = opts[:files_base_url] || FILES_BASE_URL
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
      "participatory_process_group": group_attributes,
      "decidim_participatory_process_type_id": process_type_id,
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
      raw_description: raw_content["Descripcion_html"],
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
    # return nil
    return if locale == "eu"

    @image_url ||= URI.join(files_base_url, image_filename)
  end

  def image_filename
    return DEFAULT_IMAGE_FILENAME if raw_content["Imagen"].blank?

    # GIFs are not accepted for hero images
    return DEFAULT_IMAGE_FILENAME if /\.gif\z/i =~ raw_content["Imagen"]

    raw_content["Imagen"].gsub(/\s/, "").gsub(/\Ahttps:\/gobiernoabierto\.navarra\.es\/sites\/default\/files\//, "").gsub(/\Apublic:\/\//, "")
  end

  def external_es_id
    @external_es_id ||= raw_content["Nodo castellano"]&.strip&.presence
  end

  def external_id
    @external_id ||= raw_content["NID"]&.strip&.presence
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
    @splitted_description ||= Nokogiri::HTML.parse(raw_content["Descripcion_html"]).xpath("//body").children
  end

  def split_description_by_tags(*tags)
    html = raw_content["Descripcion_html"]
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

    #{list_of_links_from("Contenidos relacionados", :detail)}

    #{list_of_links_from("Documentacion", :documentation)}

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

  def process_type
    @process_type ||= Decidim::ParticipatoryProcessType.find_or_create_by(
      title: translatable_hash(raw_content["Tipo de propuesta"].strip),
      organization: organization
    )
  end

  def process_type_id
    process_type.id
  end

  def extract_date(text)
    day_month, year = text.split(", ")[1, 2]
    day, month_name = day_month.split(" ")
    Date.new(year.to_i, MONTH_NAMES[month_name.titleize], day.to_i)
  end

  def area_data
    return { "id" => nil, "name" => nil } if area.blank?

    area.attributes.slice("id", "name")
  end

  def area
    @area ||= Decidim::Area.find_by(id: raw_content["area_id"])
  end

  def proposal_type
    @proposal_type ||= raw_content["Tipo de propuesta"].strip
  end

  def group_hashtag
    REGULATORY_PARTICIPATION_GROUP_VALUES.include?(proposal_type) ? "participacion-en-normativa" : "procesos-de-participacion"
  end

  def group_attributes
    @group_attributes ||= PROCESS_GROUPS_ATTRIBUTES.find do |attributes|
      attributes[:hashtag] == group_hashtag
    end
  end

  def scope_data
    scope&.attributes&.slice("id", "name")
  end

  def scope
    return if locale == "eu"

    @scope ||= begin
                 legislature_id = if raw_content["Legislatura"].present?
                                    legislature_scope_type.scopes.find_or_create_by(
                                      name: translatable_hash(raw_content["Legislatura"]),
                                      organization: organization,
                                      code: raw_content["Legislatura"]
                                    ).id
                                  end
                 department_scope_type.scopes.find_or_create_by(
                   name: translated_department_name(raw_content["Departamento"].strip),
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

  def translated_department_name(text)
    if locale == "es" && DEPARTMENTS_TRANSLATIONS.has_key?(text)
      { "es" => text, "eu" => DEPARTMENTS_TRANSLATIONS[text] }
    elsif locale == "eu" && DEPARTMENTS_TRANSLATIONS.has_value?(text)
      translation_values = DEPARTMENTS_TRANSLATIONS.find { |_, v| v == text }
      { "es" => translation_values[0], "eu" => text }
    end
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
