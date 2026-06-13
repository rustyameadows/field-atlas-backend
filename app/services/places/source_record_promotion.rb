module Places
  class SourceRecordPromotion
    def initialize(source_record)
      @source_record = source_record
    end

    def call
      case source_record.provider
      when "nps"
        Sources::Nps::PlacePromotion.new(source_record).call
      else
        raise ArgumentError, "Unsupported source provider: #{source_record.provider}"
      end
    end

    private

    attr_reader :source_record
  end
end
