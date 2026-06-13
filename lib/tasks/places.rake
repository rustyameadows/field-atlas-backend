namespace :places do
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
