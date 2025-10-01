# frozen_string_literal: true

# An example implementation of an AuthorizationHandler to be used in tests.
class AssembliesParser
  attr_reader :raw_content, :organization

  LOCALE_SUFFIXES = {
    "es" => "es",
    "eus" => "eu"
  }.freeze

  def initialize(row, organization)
    @raw_content = row
    @organization = organization
  end

  def transformed_data
    {
      "title": localized_values("title"),
      "subtitle": localized_values("subtitle"),
      "slug": slug_value,
      "hashtag": nil,
      "short_description": localized_values("short_description"),
      "description": localized_values("description"),
      "weight": raw_content["weight"],
      "attachments": { "files": nil },
      "components": nil,
      "scopes_enabled": true,
      "decidim_scope_id": scope&.id,
      "decidim_area_id": area&.id,
      "decidim_assemblies_type_id": nil,
      "private_space": false,
      "is_transparent": false,
      "original_id": external_id
    }
  end

  def metadata
    {
      original_id: external_id,
      original_slug: slug_value,
      final_slug: nil
    }
  end

  private

  def scope
    @scope ||= begin
      legislature_id = if raw_content["Scope_type_es"].present?
                         legislature_scope_type.scopes.find_or_create_by(
                           name: { "es" => raw_content["Scope_type_es"],
                                   "eu" => raw_content["Scope_type_eus"] },
                           organization:,
                           code: raw_content["Scope_type_es"]
                         ).id
                       end
      department_scope_type.scopes.find_or_create_by(
        name: { "es" => raw_content["scope_es"], "eu" => raw_content["scope_eus"] },
        parent_id: legislature_id,
        organization:,
        code: "#{raw_content["Scope_type_es"]}-#{raw_content["scope_es"]}"
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

  def external_id
    @external_id ||= raw_content["id"].strip.presence
  end

  def slug_value
    value = slug(raw_content["Slug"])

    return value if value.present?

    slug(raw_content["title_es"])
  end

  def slug(attribute)
    return if attribute.blank?

    attribute.gsub(/\A[^a-zA-Z]+/, "").tr("_", " ").parameterize
  end

  def localized_values(prefix)
    LOCALE_SUFFIXES.to_h do |suffix, locale|
      [locale, raw_content["#{prefix}_#{suffix}"]]
    end
  end

  def area
    @area ||= Decidim::Area.find_by(id: raw_content["area_id"])
  end
end
