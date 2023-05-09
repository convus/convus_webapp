class UpdateCitationMetadataFromRatingsJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(id)
    citation = Citation.find(id)
    citation_metadata_attributes = ordered_ratings(citation)
      .map(&:citation_metadata_attributes)

    skipped_attributes = citation.manually_updated_attributes.map(&:to_sym)

    new_attributes = (MetadataAttributer::ATTR_KEYS - [:keywords]).map do |attrib|
      next if skipped_attributes.include?(attrib)

      # returns first value that matches, only process the first that's required
      val = citation_metadata_attributes.lazy.filter_map { |cma| cma[attrib] }.first
      val.present? ? [attrib, val] : nil
    end.compact.to_h

    if new_attributes[:published_updated_at].present? && new_attributes[:published_at].present?
      new_attributes[:published_updated_at] = nil if new_attributes[:published_updated_at] <= new_attributes[:published_at]
    end
    citation.update(new_attributes.except(:publisher_name, :topic_names))

    if new_attributes[:publisher_name].present? && !citation.publisher.name_assigned?
      citation.publisher.update(name: new_attributes[:publisher_name])
    end
    citation
  end

  # TODO: Order by version, then submission
  def ordered_ratings(citation)
    citation.ratings.metadata_present.order(version_integer: :desc, metadata_at: :desc)
  end
end
