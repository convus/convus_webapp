class UpdateCitationMetadataFromRatingsJob < ApplicationJob
  sidekiq_options retry: 1

  def self.ordered_ratings(citation)
    # Process any unprocessed ratings. This is where processing happens normally
    citation.ratings.metadata_unprocessed.each { |r| r.set_metadata_attributes! }
    citation.reload
    # Then, return in order
    Rating.metadata_present.where(citation_id: citation.id)
      .order(version_integer: :desc, metadata_at: :desc)
  end

  def perform(id)
    citation = Citation.find(id)
    metadata_attributes = self.class.ordered_ratings(citation).map(&:metadata_attributes)

    skipped_attributes = citation.manually_updated_attributes.map(&:to_sym)
    new_attributes = (MetadataAttributer::ATTR_KEYS - [:keywords]).map do |attrib|
      next if skipped_attributes.include?(attrib)

      # returns first value that matches, only loading the first that matches
      val = metadata_attributes.lazy.filter_map { |cma| cma[attrib].presence }.first
      val.present? ? [attrib, val] : nil
    end.compact.to_h

    if new_attributes[:published_updated_at].present? && new_attributes[:published_at].present?
      if new_attributes[:published_updated_at] <= new_attributes[:published_at]
        new_attributes[:published_updated_at] = nil
      end
    end
    citation.update(new_attributes.except(:publisher_name))

    if new_attributes[:publisher_name].present? && !citation.publisher.name_assigned?
      citation.publisher.update(name: new_attributes[:publisher_name])
    end
    citation
  end
end
