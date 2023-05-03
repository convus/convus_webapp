class UpdateCitationMetadataFromRatingsJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(id, override = false)
    citation = Citation.find(id)
    citation_metadata_attributes = ordered_ratings(citation)
      .map(&:citation_metadata_attributes)

    new_attributes = MetadataAttributer::ATTR_KEYS.map do |attrib|
      unless attrib == :publisher_name # Always get publisher_name
        next if citation.send(attrib).present? && !override
      end
      # returns first value that matches, only process the first that's required
      val = citation_metadata_attributes.lazy.filter_map { |cma| cma[attrib] }.first
      val.present? ? [attrib, val] : nil
    end.compact.to_h

    if new_attributes[:published_updated_at].present? && new_attributes[:published_updated_at] <= new_attributes[:published_at]
      new_attributes[:published_updated_at] = nil
    end
    citation.update(new_attributes.except(:publisher_name))

    if new_attributes[:publisher_name].present? && !citation.publisher.name_assigned?
      citation.publisher.update(name: new_attributes[:publisher_name])
    end
    citation
  end

  # TODO: Order by version, then submission
  def ordered_ratings(citation)
    citation.ratings.with_metadata.order(metadata_at: :desc)
  end
end
