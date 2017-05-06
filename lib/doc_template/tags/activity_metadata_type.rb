module DocTemplate
  class ActivityMetadataTypeTag < Tag
    TAG_NAME = 'activity-metadata-type'.freeze
    TEMPLATE = 'activity.html.erb'.freeze

    def parse(node, opts = {})
      activity = opts[:activity].activity_by_tag(opts[:value])
      activity_src =
        [].tap do |result|
          while (sibling = node.next_sibling) do
            break if sibling.content =~ /\[\s*(#{ActivityMetadataSectionTag::TAG_NAME}|#{ActivityMetadataTypeTag::TAG_NAME}|#{MaterialsTag::TAG_NAME})/
            result << sibling.to_html
            sibling.remove
          end
        end.join
      activity_src = parse_nested(activity_src)
      @result = node.replace(parse_template({ source: activity_src, activity: activity }, TEMPLATE))
      self
    end
  end

  Template.register_tag(ActivityMetadataTypeTag::TAG_NAME, ActivityMetadataTypeTag)
end
