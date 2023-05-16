class UpdateCitationMetadataFromRatingsJob < ApplicationJob
  sidekiq_options retry: 1

  def self.ordered_ratings(citation, skip_reprocess: false)
    unless skip_reprocess
      # Process any unprocessed ratings. This is where processing happens normally
      citation.ratings.metadata_unprocessed.each { |r| r.set_metadata_attributes! }
      citation.reload
    end
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
      next nil if val.blank?
      # Convert time into time
      val = Time.at(val) if MetadataAttributer::TIME_KEYS.include?(attrib)
      [attrib, val]
    end.compact.to_h

    citation.update(new_attributes.except(:publisher_name))

    if new_attributes[:publisher_name].present? && !citation.publisher.name_assigned?
      citation.publisher.update(name: new_attributes[:publisher_name])
    end
    citation
  end
end
