class FeeGroupReference
  attr_reader :reference, :office_code, :office_name, :office_address, :office_telephone

  class << self
    def create(postcode:)
      new(postcode).tap &:perform
    end
  end

  def initialize(postcode)
    @postcode = postcode
  end

  def perform
    if request.success?
      @reference = request['fgr']
      @office_code = request['ETOfficeCode']
      @office_name = request['ETOfficeName']
      @office_address = request['ETOfficeAddress']
      @office_telephone = request['ETOfficeTelephone']
    else
      raise RuntimeError.new "Error #{request['errorCode']}: #{request['errorDescription']}"
    end
  end

  private def request
    @request ||= HTTParty.post \
      URI.join(ENV['JADU_API'], 'fgr-office'),
      body: { postcode: @postcode },
      headers: { 'Accept' => 'application/json' }
  end
end
