require 'rails_helper'

describe ClaimSubmissionJob, type: :job do
  let(:claim) { instance_double Claim }

  describe '#perform' do
    it 'submits the claim' do
      expect(claim).to receive(:generate_pdf!)
      expect(Jadu::Claim).to receive(:create).with claim
      subject.perform(claim)
    end
  end
end