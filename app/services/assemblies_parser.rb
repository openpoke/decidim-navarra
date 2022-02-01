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
      "decidim_scope_id": raw_content["scope_id"],
      "decidim_area_id": area_data["id"],
      "decidim_assemblies_type_id": assembly_type_data["id"],
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
    LOCALE_SUFFIXES.map do |suffix, locale|
      [locale, raw_content["#{prefix}_#{suffix}"]]
    end.to_h
  end

  def area_data
    area.attributes.slice("id", "name")
  end

  def area
    @area ||= Decidim::Area.find_by(id: raw_content["area_id"])
  end

  def assembly_type_data
    assembly_type.attributes.slice("id", "name")
  end

  def assembly_type
    @assembly_type ||= Decidim::AssembliesType.find_or_create_by(
      organization: organization,
      title: localized_values("decidim_assemblies_type")
    )
  end
end
