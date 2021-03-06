require 'rails_helper'

RSpec.describe PdfForm::ClaimPresenter, type: :presenter do
  let(:pdf_form_claim_presenter) { described_class.new(claim) }

  [:other_outcome, :claim_details, :other_claim_details, :miscellaneous_information].each do |meth|
    describe "##{meth}" do
      let(:claim) { create :claim }

      let(:left_double_quotation)  { "\u{201c}" }
      let(:right_double_quotation) { "\u{201d}" }
      let(:right_single_quotation) { "\u{2019}" }

      before do
        allow(claim).to receive(meth).and_return <<-EOS.strip_heredoc
          I don't know how to do paragraphs





          look


          i am thick

          bai
          #{left_double_quotation}
          #{right_double_quotation}
          #{right_single_quotation}
        EOS
      end

      it 'removes superfluous carriage returns & unknown chars' do
        expect(pdf_form_claim_presenter.send(meth)).to eq <<-EOS.strip_heredoc
          I don't know how to do paragraphs

          look

          i am thick

          bai
          "
          "
          '
        EOS
      end
    end
  end

  describe '#name' do
    let(:claimant) { instance_double 'Claimant', first_name: 'first', last_name: 'last' }
    let(:claim) { instance_double 'Claim', primary_claimant: claimant }

    it 'returns a name' do
      expect(pdf_form_claim_presenter.name).to eq('first last')
    end
  end

  describe '#to_h' do
    let(:hash) { pdf_form_claim_presenter.to_h }

    context 'when owed' do
      [:notice, :holiday, :arrears, :other].each do |type|
        let(:claim) { Claim.new pay_claims: [type] }

        it "returns yes when '#{type}' pay complaint" do
          expect(hash).to include('8.1 owed' => 'yes')
        end
      end
    end

    context 'when redundancy' do
      let(:claim) { Claim.new pay_claims: ['redundancy'] }

      it "returns Off when 'redundancy' pay complaint" do
        expect(hash).to include('8.1 owed' => 'Off')
      end
    end

    context 'when whistleblowing' do
      let(:claim) { Claim.new send_claim_to_whistleblowing_entity: true }

      it 'returns yes when whistleblowing' do
        expect(hash).to include('10.1' => 'yes')
      end
    end

    context 'when claim has a single claimant' do
      let(:claim) { create :claim, :single_claimant }

      it 'checks the single claimant box' do
        expect(hash).to include 'type of claim' => 'a single claim'
      end
      it 'doesnt populate the number of claimants box' do
        expect(hash).to include 'more than one claimant' => nil
      end
    end

    context 'when claim has multiple claimants' do
      let(:claim) { create :claim }

      it 'checks the multiple claimants box' do
        expect(hash).to include 'type of claim' => 'a claimon behalf of more than one person'
      end
      it 'populates the number of claimants box' do
        expect(hash).to include 'more than one claimant' => 6
      end

    end
  end
end
