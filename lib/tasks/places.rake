namespace :places do
  desc "Import all NPS parks, campgrounds, and visitor centers into canonical places"
  task import_nps_phase1: :environment do
    result = Sources::Nps::CanonicalImporter.new.call

    puts "Fetched NPS records: #{result.fetched.inspect}"
    puts "Processed source records: #{result.source_records.inspect}"
    puts "Created canonical places: #{result.places.inspect}"
    puts "Created source links: #{result.links}"
    puts "Created containments: #{result.containments}"
    puts "Skipped child records: #{result.skipped.count}"

    result.skipped.each do |skip|
      puts "  #{skip.fetch(:record_type)} #{skip.fetch(:source_id)} #{skip.fetch(:name)} skipped: #{skip.fetch(:reason)} park_code=#{skip.fetch(:park_code)}"
    end
  end

  desc "Import NPS park boundary geometry into canonical park places"
  task import_nps_boundaries: :environment do
    result = Sources::Nps::BoundaryImporter.new.call

    puts "Checked NPS park units: #{result.checked}"
    puts "Updated park geometries: #{result.updated}"
    puts "Missing park boundaries: #{result.missing.count}"
    puts "Failed park boundaries: #{result.failed.count}"

    result.missing.each do |missing|
      puts "  #{missing.fetch(:park_code)} place_id=#{missing.fetch(:place_id)} missing: #{missing.fetch(:reason)}"
    end

    result.failed.each do |failure|
      puts "  #{failure.fetch(:park_code)} place_id=#{failure.fetch(:place_id)} failed: #{failure.fetch(:reason)}"
    end
  end

  desc "Promote stored NPS park source records into canonical places"
  task promote_nps_parks: :environment do
    promoted = 0
    SourceRecord.where(provider: "nps", record_type: "park").find_each do |source_record|
      Places::SourceRecordPromotion.new(source_record).call
      promoted += 1
    end

    puts "Promoted #{promoted} NPS park source records"
  end
end
