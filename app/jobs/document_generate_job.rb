# frozen_string_literal: true

class DocumentGenerateJob < ActiveJob::Base
  extend ResqueJob

  queue_as :default

  WAIT_FOR_JOBS = %w(MaterialGenerateJob MaterialGeneratePDFJob MaterialGenerateGdocJob).freeze

  def perform(document, check_queue: false)
    @document = document

    # Queue all materials at the first time
    return queue_materials unless check_queue

    # Exit if any material is still generating
    return if check_queue && materials_generating?

    # Got here: all materials have been re-generated
    document.document_parts.default.each { |p| p.update!(content: EmbedEquations.call(p.content)) }

    queue_documents
  end

  private

  attr_accessor :document

  def create_gdoc_folders
    drive = GoogleApi::DriveService.build(Google::Apis::DriveV3::DriveService, document)

    id = drive.create_folder("#{document.id}_v#{document.version}")
    drive.create_folder(DocumentExporter::Gdoc::TeacherMaterial::FOLDER_NAME, id)
    drive.create_folder(DocumentExporter::Gdoc::StudentMaterial::FOLDER_NAME, id)
  end

  #
  # Checks if there are jobs queued or running for current document
  # and any of its materials
  #
  def materials_generating?
    document.materials.each do |material|
      queued = Resque.peek(queue_name, 0, 0)
                 .map { |job| job['args'].first }
                 .detect { |job| same_material?(job, material.id) }

      queued ||=
        Resque::Worker.working.map(&:job).detect do |job|
          next unless job.is_a?(Hash) && (args = job.dig 'payload', 'args').is_a?(Array)
          args.detect { |x| same_material?(x, material.id) }
        end

      return true if queued
    end
    false
  end

  def same_document?(job, type, klass)
    job['job_class'] == klass &&
      job['arguments'].first['_aj_globalid'].index("gid://content/Document/#{document.id}") &&
      job['arguments'].second['content_type'] == type
  end

  def same_material?(job, id)
    WAIT_FOR_JOBS.include?(job['job_class']) &&
      job['arguments'].first['_aj_globalid'].index("gid://content/Material/#{id}") &&
      job['arguments'].second['_aj_globalid'].index("gid://content/Document/#{document.id}")
  end

  def queue_documents
    DocumentGenerator::CONTENT_TYPES.each do |type|
      %w(DocumentGenerateGdocJob DocumentGeneratePdfJob).each do |klass|
        next if queued_or_running?(type, klass)
        klass.constantize.perform_later document, content_type: type
      end
    end
  end

  def queue_materials
    create_gdoc_folders
    document.materials.each { |material| MaterialGenerateJob.perform_later(material, document) }
  end

  def queued_or_running?(type, klass)
    queued = Resque.peek(queue_name, 0, 0)
               .map { |job| job['args'].first }
               .detect { |job| same_document?(job, type, klass) }

    queued ||
      Resque::Worker.working.map(&:job).detect do |job|
        next unless job.is_a?(Hash) && (args = job.dig 'payload', 'args').is_a?(Array)
        args.detect { |x| same_document?(x, type, klass) }
      end
  end
end
