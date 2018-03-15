# frozen_string_literal: true

class CommonCoreStandard < Standard
  CCSS_PREFIXES = %w(ccss.ela-literacy. ccss.math.content. ccss.math.practice.).freeze

  belongs_to :standard_strand
  belongs_to :cluster, class_name: 'CommonCoreStandard'
  belongs_to :domain, class_name: 'CommonCoreStandard'

  scope :clusters, -> { where(label: 'cluster') }
  scope :domains, -> { where(label: 'domain') }
  scope :standards, -> { where(label: 'standard') }
  scope :with_alt_name, ->(name) { where('? = ANY(alt_names)', name) }

  def self.find_by_name_or_synonym(name)
    name = name.downcase
    find_by_name(name) || with_alt_name(name).first
  end

  def generate_alt_names(regenerate: false)
    return unless name

    alt_names = Set.new

    # ccss.ela-literacy.1.2 -> 1.2
    short_name = CommonCoreStandard::CCSS_PREFIXES.inject(name) { |memo, x| memo.gsub x, '' }
    base_names = Set.new([short_name, short_name.gsub('ccra', 'ra')])

    # hsn-rn.b.3 -> n-rn.b.3
    base_names << short_name.gsub('hs', '') if short_name.starts_with?('hs')

    base_names.each do |base_name|
      # 6.rp.a.3a -> 6.rp.a.3.a
      letters_expand = base_name.gsub(/\.([1-9])([a-z])$/, '.\1.\2')

      # 6-rp.a.3 -> 6.rp.a.3
      dot_name = base_name.gsub(/[-]/, '.')

      # ccss.ela-literacy.r.1.2 -> ela.r.1.2
      prefixed_dot_name = "#{subject}.#{dot_name}"

      if name.include?('math') && dot_name.count('.') == 3
        # 5.oa.b.3 -> 5.oa.3
        # n.rn.b.3 -> n.rn.3
        without_cluster = dot_name.split('.').values_at(0, 1, 3).join('.')
        alt_names << without_cluster
      end

      alt_names << base_name
      alt_names << letters_expand
      alt_names << dot_name
      alt_names << prefixed_dot_name
    end

    # add "clean" names: ela.r.1.2 -> elar12
    alt_names.merge(alt_names.map { |n| n.gsub(/[\.-]/, '') })

    alt_names.merge(self.alt_names) unless regenerate

    self.alt_names = alt_names.to_a
  end
end
