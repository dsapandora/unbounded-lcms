class Resource < ActiveRecord::Base
  extend OrderAsSpecified
  include Search::ResourcesSearch

  enum resource_type: { podcast: 2, resource: 1, video: 3 }

  acts_as_taggable_on :content_sources,
    :download_types,
    :grades,
    :resource_types,
    :tags,
    :topics

  # Additional resources
  has_many :resource_additional_resources, dependent: :destroy
  has_many :additional_resources, through: :resource_additional_resources

  # Standards.
  has_many :resource_standards, dependent: :destroy
  has_many :standards, through: :resource_standards
  has_many :common_core_standards, ->{ where(type: 'CommonCoreStandard') }, source: :standard, through: :resource_standards
  has_many :unbounded_standards, ->{ where(type: 'UnboundedStandard') }, source: :standard, through: :resource_standards

  # Downloads.
  has_many :resource_downloads, dependent: :destroy
  has_many :downloads, through: :resource_downloads

  # Curriculums.
  has_many :curriculums, as: :item

  # Reading assignments.
  has_many :resource_reading_assignments, dependent: :destroy
  alias_attribute :reading_assignments, :resource_reading_assignments

  # Related resources.
  has_many :resource_related_resources, dependent: :destroy
  has_many :related_resources, through: :resource_related_resources

  # Requirements
  has_many :resource_requirements, dependent: :destroy
  has_many :requirements, through: :resource_requirements

  # Slugs
  has_many :resource_slugs, dependent: :destroy
  alias_attribute :slugs, :resource_slugs

  has_many :content_guides, through: :unbounded_standards

  validates :title, presence: true
  validates :url, presence: true, url: true, unless: :resource?

  accepts_nested_attributes_for :resource_downloads, allow_destroy: true

  scope :lessons, -> {
    joins(:curriculums)
    .where(curriculums: { curriculum_type: CurriculumType.lesson })
    .where.not(curriculums: { seed_id: nil })
  }

  scope :where_subject, ->(subjects) {
    subjects = Array.wrap(subjects)
    return where(nil) unless subjects.any?

    where(subject: subjects)
  }

  scope :where_tag, ->(context, value) {
    value = Array.wrap(value)
    return where(nil) unless value.any?

    joins(taggings: [:tag])
    .where(taggings: { context: context })
    .where(tags: { name: value })
  }

  scope :where_grade, ->(grades) {
    where_tag('grades', grades)
  }

  scope :asc, -> { order(created_at: :asc) }
  scope :desc, -> { order(created_at: :desc) }

  scope :videos, -> { where(resource_type: self.resource_types[:video]) }
  scope :podcasts, -> { where(resource_type: self.resource_types[:podcast]) }
  scope :media, -> { where(resource_type: [self.resource_types[:video], self.resource_types[:podcast]])}

  class << self
    def by_title(title)
      where(title: title)
    end

    def bulk_edit(sample, resources)
      before = init_for_bulk_edit(resources)
      after  = sample

      transaction do
        resources.each do |resource|
          # Standards
          resource.resource_standards.where(standard_id: before.standard_ids).where.not(standard_id: after.standard_ids).destroy_all
          (after.standard_ids - before.standard_ids).each do |standard_id|
            resource.resource_standards.find_or_create_by!(standard_id: standard_id)
          end

          resource.grades_list = sample.grades_list
          resource.tags_list = sample.tags_list
          resource.resource_types_list = sample.resource_types_list

          resource.save!
          resource
        end
      end
    end

    def init_for_bulk_edit(resources)
      resource = new
      resource.standard_ids = resources.map(&:standard_ids).inject { |memo, ids| memo &= ids }
      resource
    end
  end

  def text_description
    # doc = Nokogiri::HTML(description)
    # doc.xpath('//p/text()').text
    Nokogiri::HTML(description).text
  rescue
    nil
  end

  def related_resources
    @related_resources ||= resource_related_resources
      .includes(:related_resource)
      .order(:position)
      .map(&:related_resource)
  end

  def downloads_by_category
    by_category = {}
    resource_downloads.group_by { |d| d.download_category.try(:name) }.each do |key, dl_group|
      by_category[key] = dl_group.map(&:download)
      yield key, by_category[key] if block_given?
    end
    by_category
  end

  def first_tree
    curriculums.trees.first
  end

  def ela?
    subject == 'ela'
  end

  def math?
    subject == 'math'
  end

  def video?
    resource_types.pluck(:name).include?(:video)
  end

  def generate_content_sources
    unless self.content_source_list.any?
      content_source = engageny_url.present? ? 'engageny' : 'unbounded'
      self.content_source_list.add(content_source)
    end
    self.content_source_list
  end

  # Tags

  def update_download_types
    self.download_type_list = resource_downloads.map do |resource_download|
      download = resource_download.download
      case download.content_type
      when 'application/zip'
        'zip'
      when 'application/pdf'
        'pdf'
      when 'application/vnd.ms-excel',
           'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        'excel'
      when 'application/vnd.ms-powerpoint',
           'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        'powerpoint'
      when 'application/msword',
           'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        'doc'
      end
    end.uniq.compact
  end

end
