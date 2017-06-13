module DocTemplate
  module Tags
    class LinkTag < BaseTag
      FORTHCOMING_PATH = '/forthcoming'.freeze

      def parse(node, opts = {})
        # preserve the node content and replace only the tag by the link
        content = node.to_s.gsub(/\[.*#{self.class::TAG_NAME}:\s?.*\]/i, link(opts))
        node.replace content

        @result = node
        self
      end

      private

      def link(opts)
        title, text = opts[:value].split(';').map(&:strip)
        # If we don't have a text, use the fa-book icon
        label = text.present? ? "<b>#{text}</b>" : ''
        href = build_href(title, opts[:metadata])

        "<a href=\"#{href}\" target=\"_blank\" title=\"#{title}\"><i class=\"fa fa-book\"></i> #{label}</a>"
      end

      def build_href(title, metadata)
        # if the first param is a url, then use it directly
        return title if title =~ URI.regexp || title.strip == FORTHCOMING_PATH

        # if we don't have proper metadata info, just use a placeholder
        return '#' unless metadata

        # build the path for unbounded-supplemental-materials on s3
        path = %i(subject grade module unit topic).map do |key|
          if metadata[key].present?
            # if its a number return `key-number` else return the parameterized value
            /^(\d+)$/.match(metadata[key]) { |num| "#{key}-#{num}" } || metadata[key].try(:parameterize)
          end
        end.compact.join('/')
        filename = title.ends_with?('.pdf') ? title : "#{title}.pdf"
        "https://unbounded-supplemental-materials.s3.amazonaws.com/#{path}/#{filename}"
      end
    end

    class QrdTag < LinkTag
      TAG_NAME = 'qrd'.freeze
    end

    class ImTag < LinkTag
      TAG_NAME = 'im'.freeze
    end

    class PosTag < LinkTag
      TAG_NAME = 'pos'.freeze
    end

    class SgimTag < LinkTag
      TAG_NAME = 'sgim'.freeze
    end
  end

  Template.register_tag(Tags::QrdTag::TAG_NAME, Tags::QrdTag)
  Template.register_tag(Tags::ImTag::TAG_NAME, Tags::ImTag)
  Template.register_tag(Tags::PosTag::TAG_NAME, Tags::PosTag)
  Template.register_tag(Tags::SgimTag::TAG_NAME, Tags::SgimTag)
end
