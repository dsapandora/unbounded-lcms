# frozen_string_literal: true

namespace :standards do
  desc 'Import all CCSS standards from Common Standards Project'
  task import: [:environment] do
    import_standards
    puts 'Imported all CCSS standards from Common Standards Project.'
  end

  desc 'Update alt_names for all CCSS standards'
  task update_alt_names: [:environment] do
    qset = CommonCoreStandard.where(nil)
    pbar = ProgressBar.create title: 'Alt Names', total: qset.count

    qset.find_in_batches do |group|
      group.each do |std|
        std.generate_alt_names
        std.save
        pbar.increment
      end
    end
    pbar.finish
  end

  def import_standards
    api_url = "#{ENV['COMMON_STANDARDS_PROJECT_API_URL']}/api/v1"
    auth_header = { 'Api-Key' => ENV['COMMON_STANDARDS_PROJECT_API_KEY'] }

    jurisdiction_id = ENV['COMMON_STANDARDS_PROJECT_JURISDICTION_ID']
    jurisdiction = JSON(RestClient.get("#{api_url}/jurisdictions/#{jurisdiction_id}", auth_header))

    Standard.transaction do
      jurisdiction['data']['standardSets'].each do |standard_set|
        create_based_on standard_set
      end
    end
  end

  def create_based_on(standard_set)
    standard_set_id = standard_set['id']
    standard_set_data = JSON(RestClient.get("#{api_url}/standard_sets/#{standard_set_id}", auth_header))['data']

    grade = standard_set_data['title'].downcase
    subject = standard_set_data['subject'] == 'Common Core English/Language Arts' ? 'ela' : 'math'

    standard_set_data['standards'].each do |data|
      asn_identifier = data['asnIdentifier'].downcase
      name = data['statementNotation'].try(:downcase)

      std_params = name.present? ? { name: name } : { asn_identifier: asn_identifier }
      standard = find_or_initialize_by(**std_params)

      standard.generate_alt_names

      if (alt_name = data['altStatementNotation']&.downcase)
        standard.alt_names << alt_name unless standard.alt_names.include?(alt_name)
      end

      standard.asn_identifier = asn_identifier
      standard.description = data['description']
      standard.grades << grade unless standard.grades.include?(grade)
      standard.label = data['statementLabel']&.downcase
      standard.name = name if name.present?
      standard.subject = subject

      standard.save!
    end
  end
end
