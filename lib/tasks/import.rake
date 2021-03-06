namespace :civic do
  desc 'if the current data dump is newer than the contents of the database, this loads the newer data dump'
  task :load, [] => :environment do |_, args|
    Database::Upgrade.upgrade_if_needed
    if Rails.env.production?
      Dir.chdir(Rails.root) do
        system('bin/delayed_job', '-n 2', 'restart')
      end
    end
  end

  desc 'dump the contents of your current CIViC database'
  task :dump, [] => :environment do |_, args|
    Database::Dump.run
  end

  desc 'import TSV spreadsheets of raw data for civic'
  task :import, [:gene_summaries_file, :variant_summaries_file, :clinical_action_evidence_file, 'variant_group_summaries_file'] => :environment do |_, args|
    import_files = [
      [:gene_summaries_file, Importer::GeneSummariesAdaptor],
      [:variant_summaries_file, Importer::VariantSummariesAdaptor],
      [:clinical_action_evidence_file, Importer::ClinicalActionEvidenceAdaptor],
      [:variant_group_summaries_file, Importer::VariantGroupSummariesAdaptor],
    ]

    import_files.each do |(arg_name, adaptor_type)|
      file_path = args[arg_name]
      raise "File #{file_path} not found!" unless File.exists? file_path
      Importer::TsvReader.new(file_path, adaptor_type.new).import!
      puts "Finished #{arg_name}"
    end

    puts "Scraping PubMed for citation information"
    Scrapers::PubMed.run
    puts "Scraping the disease ontology for disease names"
    Scrapers::DiseaseOntology.run
    puts "Import Complete"
  end
end
