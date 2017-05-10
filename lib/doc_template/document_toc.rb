module DocTemplate
  class DocumentTOC
    REGISTERED_SUBJECTS = {
      'ela'  => :agenda,
      'math' => :activity
    }.freeze

    def self.parse(opts = {})
      subject = opts[:metadata].subject.try(:downcase)
      return Objects::TOCMetadata.new unless REGISTERED_SUBJECTS.key?(subject)
      Objects::TOCMetadata.new(opts[REGISTERED_SUBJECTS[subject]])
    end
  end
end
