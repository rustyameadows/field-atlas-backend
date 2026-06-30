module Places
  class SourceRecordPromotion
    def initialize(source_record)
      @source_record = source_record
    end

    def call
      case source_record.provider
      when "nps"
        case source_record.record_type
        when "park"
          Sources::Nps::PlacePromotion.new(source_record).call
        when "campground", "visitor_center"
          Sources::Nps::ChildPlacePromotion.new(source_record).call
        else
          raise ArgumentError, "Unsupported NPS source record type: #{source_record.record_type}"
        end
      else
        raise ArgumentError, "Unsupported source provider: #{source_record.provider}"
      end
    end

    private

    attr_reader :source_record
  end
end
