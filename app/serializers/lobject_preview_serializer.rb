class LobjectPreviewSerializer < ActiveModel::Serializer
  include TruncateHtmlHelper
  include Unbounded::LobjectHelper
  
  attributes :id, :title, :description, :curriculum_subject, :resource_kind, :slug

  def description
    truncate_html(object.description, length: 300) if object.description
  end

  def resource_kind
    object.unbounded_curriculum.try(:resource_kind)
  end

  def title
    full_title(object.title, object.subtitle)
  end
end
