module ActivitiesHelper
  # One "Kapazität: 100 → 80" line per changed field of a concert.
  def activity_detail_lines(activity)
    activity.details.map do |attribute, values|
      "#{Concert.human_attribute_name(attribute)}: " \
        "#{activity_detail_value(attribute, values["old"])} → #{activity_detail_value(attribute, values["new"])}"
    end
  end

  # Details are stored raw, which keeps localization out of the model — and turns timestamps into
  # JSON strings. The column type is what says how to read them back.
  def activity_detail_value(attribute, value)
    return t("activities.blank") if value.blank?

    type = Concert.type_for_attribute(attribute)

    type.type == :datetime ? l(type.cast(value), format: :short) : type.cast(value).to_s
  end
end
