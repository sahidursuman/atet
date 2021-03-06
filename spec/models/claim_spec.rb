require 'rails_helper'

RSpec.describe Claim, type: :claim do
  it { is_expected.to have_secure_password }

  it { is_expected.to have_many(:claimants).dependent(:destroy) }
  it { is_expected.to have_many(:secondary_claimants).conditions primary_claimant: false }

  it { is_expected.to have_many(:respondents).dependent(:destroy).order(created_at: :asc) }
  it { is_expected.to have_many(:secondary_respondents).conditions primary_respondent: false }

  it { is_expected.to have_one(:representative).dependent(:destroy) }
  it { is_expected.to have_one(:employment).dependent(:destroy) }
  it { is_expected.to have_one(:office).dependent(:destroy) }
  it { is_expected.to have_one(:primary_claimant).conditions primary_claimant: true }
  it { is_expected.to have_one(:primary_respondent).conditions primary_respondent: true }
  it { is_expected.to have_one(:payment) }

  before do
    allow(ClaimSubmissionJob).to receive :perform_later
  end

  include_context 'block pdf generation'

  let(:claim) { described_class.create }
  let(:claim_enqueued) { create :claim }
  let(:pdf) { Tempfile.new 'such' }

  describe 'callbacks' do
    describe 'after_create' do
      it 'creates a "created" event' do
        expect(claim.events.first[:event]).to eq 'created'
      end
    end

    describe 'after_update' do
      context 'when additional_claimants_csv changed' do
        before do
          allow(claim).
            to receive(:additional_claimants_csv_changed?).and_return(true)
        end

        # rubocop:disable RSpec/AnyInstance
        # target.addresses always returns a new proxy so we have to do expect_any_instance
        it 'destroys all secondary_claimants' do
          expect_any_instance_of(claim.secondary_claimants.class).to receive(:destroy_all)
          claim.save
        end
        # rubocop:enable RSpec/AnyInstance
      end

      context 'when additional_claimants_csv did not change' do
        before do
          allow(claim).
            to receive(:additional_claimants_csv_changed?).and_return(false)
        end

        it 'does not destroy secondary_claimants' do
          expect(claim.secondary_claimants).not_to receive(:destroy_all)
          claim.save
        end
      end
    end

    describe 'after_update when adding secondary_claimants' do
      before do
        claim.secondary_claimants.build
        claim.save
      end

      it 'resets additional claimants counter' do
        expect(claim.additional_claimants_csv_record_count).to be_zero
      end

      it 'deletes additional_claimants_csv' do
        expect(claim.additional_claimants_csv.url).to be_blank
      end
    end
  end

  [:created_at, :amount, :reference].each do |meth|
    describe "#payment_#{meth}" do
      context 'when #payment is nil' do
        it { expect(claim.send("payment_#{meth}")).to be nil }
      end

      context 'when #payment is not nil' do
        let(:payment) { instance_double(Payment) }

        before { allow(claim).to receive(:payment).and_return payment }

        it 'delegates to #payment' do
          allow(payment).to receive(meth).and_return 'lol'
          expect(claim.send("payment_#{meth}")).to eq 'lol'
        end
      end
    end
  end

  describe '#reference' do
    it 'returns a token generated by ApplicationReference' do
      allow(ApplicationReference).to receive(:generate).and_return 'ABCD-1234'
      expect(claim.reference).to eq('ABCD-1234')
    end

    it 'checks for collisions when generating' do
      allow(ApplicationReference).to receive(:generate).
        and_return('AAAA-1111', 'BBBB-2222', 'CCCC-3333')
      described_class.create!(application_reference: 'AAAA-1111')
      described_class.create!(application_reference: 'BBBB-2222')
      expect(claim.application_reference).to eq('CCCC-3333')
    end
  end

  # rubocop:disable DynamicFindBy
  describe '.find_by_reference' do
    it 'returns the claim with the corresponding reference' do
      claim = described_class.create!(application_reference: 'ABCD-1234')
      expect(described_class.find_by_reference('ABCD-1234')).to eql(claim)
    end

    it 'normalises the reference before looking up' do
      claim = described_class.create!(application_reference: 'ABCD-1234')
      expect(described_class.find_by_reference('abcd-l234')).to eql(claim)
    end

    context "no record is found" do
      it "returns nil" do
        described_class.destroy_all
        expect(described_class.find_by_reference('ABCD-1234')).to be_nil
      end
    end
  end
  # rubocop:enable DynamicFindBy

  describe '#claimant_count' do
    # rubocop:disable RSpec/AnyInstance
    # target.addresses always returns a new proxy so we have to do expect_any_instance
    it 'delegates to the claimant association proxy' do
      expect_any_instance_of(claim.claimants.class).to receive(:count).and_return(0)
      claim.claimant_count
    end
    # rubocop:enable RSpec/AnyInstance

    it 'adds the cached additonal claimants csv count' do
      claim.additional_claimants_csv_record_count = 1

      allow(claim.claimants).to receive(:count).and_return(0)
      expect(claim.claimant_count).to eq 1
    end
  end

  describe '#multiple_claimants?' do
    context 'claim with multiple claimants' do
      specify { expect(claim_enqueued.multiple_claimants?).to be_truthy }
    end

    context 'claim with a single claimant' do
      let(:claim) { create :claim, :single_claimant }

      specify { expect(claim.multiple_claimants?).to be_falsey }
    end
  end

  describe 'bitmasked attributes' do
    [:discrimination_claims, :pay_claims, :desired_outcomes].each do |attr|
      specify { expect(claim.send(attr)).to be_an(Array) }
    end
  end

  describe '#attracts_higher_fee?' do
    context 'when there are no claims of discrimination or unfair dismissal' do
      it { expect(claim.attracts_higher_fee?).to be_falsey }
    end

    context 'when there is a claim of discrimination' do
      before { claim.discrimination_claims << :race }
      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there is a claim of unfair dismissal' do
      before { claim.is_unfair_dismissal = true }
      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there is a protective award claim' do
      before { claim_enqueued.is_protective_award = true }
      it { expect(claim_enqueued.attracts_higher_fee?).to be true }
    end

    context 'when claim is whistleblowing' do
      before { claim.is_whistleblowing = true }
      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there are claims of both discrimination and unfair dismissal' do
      before do
        claim.discrimination_claims << :race
        claim.is_unfair_dismissal = true
      end

      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there are claims of both discrimination and whistleblowing' do
      before do
        claim.discrimination_claims << :race
        claim.is_whistleblowing = true
      end

      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there are claims of both unfair dismissal and whistleblowing' do
      before do
        claim.is_unfair_dismissal = true
        claim.is_whistleblowing = true
      end

      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there are claims of both unfair dismissal and protective award' do
      before do
        claim.is_unfair_dismissal = true
        claim.is_protective_award = true
      end

      it { expect(claim.attracts_higher_fee?).to be true }
    end

    context 'when there are claims of discrimination, unfair dismissal, whistleblowing' do
      before do
        claim.discrimination_claims << :race
        claim.is_unfair_dismissal = true
        claim.is_whistleblowing = true
      end

      it { expect(claim.attracts_higher_fee?).to be true }
    end
  end

  describe '#submittable?' do
    let(:attributes) do
      {
        primary_claimant:   Claimant.new,
        primary_respondent: Respondent.new
      }
    end

    context 'when the minimum information is incomplete' do
      it 'returns false' do
        expect(attributes.none? { |key, _| described_class.new(attributes.except(key)).submittable? }).to be true
      end
    end

    context 'when the minimum information is complete' do
      let(:claim) { described_class.new attributes }

      it { expect(claim.submittable?).to be true }
    end
  end

  describe '#fee_calculation' do
    it 'delegates to ClaimFeeCalculator.calculate' do
      expect(ClaimFeeCalculator).to receive(:calculate).with claim: claim
      claim.fee_calculation
    end
  end

  describe '#payment_applicable?' do
    before do
      allow(PaymentGateway).to receive(:available?).and_return true
      allow(claim).to receive(:fee_group_reference?).and_return true
      allow(ClaimFeeCalculator).to receive(:calculate).with(claim: claim).
        and_return instance_double(ClaimFeeCalculator::Calculation, fee_to_pay?: true)
    end

    context 'is set to default false' do
      it { expect(claim.payment_applicable?).to be_falsey }
    end
  end

  describe '#state' do
    describe 'for a new record' do
      it { expect(claim.state).to eq 'created' }
    end
  end

  describe '#unpaid?' do
    context 'with a payment assosciated with the claim' do
      let(:claim) { create :claim, payment: Payment.new }

      it { expect(claim.unpaid?).to be_falsey }
    end

    context 'with no payment assosciated with the claim' do
      let(:claim) { create :claim, payment: nil }

      it { expect(claim.unpaid?).to be_truthy }
    end
  end

  describe "#attachments" do
    let(:claim) { create :claim, :with_pdf }

    it "returns a list of attachment uplaoders on the claim" do
      expect(claim.attachments).to all(be_kind_of CarrierWave::Uploader::Base)
    end

    specify { expect(claim.attachments.size).to eq 3 }

    it "only returns attachments that exist" do
      expect { claim.remove_claim_details_rtf! }.
        to change { claim.attachments.size }.
        from(3).to(2)
    end
  end

  describe '#remove_pdf!' do
    before { claim.pdf = pdf }

    it 'removes the pdf' do
      expect { claim.remove_pdf! }.
        to change { claim.pdf_present? }.
        from(true).to(false)
    end
  end

  describe '#remove_claim_details_rtf!' do
    before { claim.claim_details_rtf = Tempfile.new('suchclaimdetails') }

    it 'removes the rtf file' do
      expect { claim.remove_claim_details_rtf! }.
        to change { claim.claim_details_rtf.present? }.
        from(true).to(false)
    end
  end

  describe "#generate_pdf!" do
    before { allow(claim_enqueued).to receive(:create_event) }

    context 'claim without a pdf assigned' do

      it "assigns a pdf to the model" do
        claim_enqueued.generate_pdf!
        expect(claim_enqueued[:pdf]).to eq "et1_barrington_wrigglesworth.pdf"
      end

      it "pdf file is present" do
        claim_enqueued.generate_pdf!
        expect(claim_enqueued.pdf.file).not_to be_nil
      end

      it 'generates a log event' do
        expect(claim_enqueued).to receive(:create_event).with 'pdf_generated'
        claim_enqueued.generate_pdf!
      end
    end

    context 'claim with a pdf already assigned' do
      before { claim.pdf = pdf }

      it 'removes the existing pdf before creating another' do
        expect(claim).to receive(:remove_pdf!)
        claim.generate_pdf!
      end

      it 'builds new pdf' do
        expect(PdfFormBuilder).to receive(:build)
        claim.generate_pdf!
      end
    end
  end

  describe '#submit!' do
    context 'transitioning state from "created"' do
      context 'when the claim is in a submittable state' do
        before { allow(claim).to receive_messages submittable?: true, save!: true }

        context 'and payment is required' do
          before { allow(claim).to receive(:payment_applicable?).and_return true }

          it 'transitions state to "payment_required"' do
            claim.submit!
            expect(claim.state).to eq('payment_required')
          end

          it 'creates a pdf generation job' do
            expect(PdfGenerationJob).to receive(:perform_later).with claim
            claim.submit!
          end
        end

        context 'and payment is not required' do
          before { allow(claim).to receive(:payment_applicable?).and_return false }

          it 'transitions state to "enqueued_for_submission"' do
            claim.submit!
            expect(claim.state).to eq('enqueued_for_submission')
          end

          it 'creates a claim submission job' do
            expect(ClaimSubmissionJob).to receive(:perform_later).with claim
            claim.submit!
          end

          it 'saves the claim' do
            expect(claim).to receive(:save!)
            claim.submit!
          end

          it 'creates a log event' do
            expect(claim).to receive(:create_event).with 'enqueued'
            claim.submit!
          end
        end
      end

      context 'when the claim is not in a submittable state' do
        before { allow(claim).to receive(:submittable?).and_return false }

        it 'raises "StateMachine::InvalidTransition"' do
          expect { claim.submit! }.to raise_error StateMachine::InvalidTransition
        end
      end
    end
  end

  describe '#enqueue' do
    context 'transitioning state from "payment_required"' do
      before do
        allow(claim).to receive_messages save!: true
        claim.state = 'payment_required'
      end

      it 'transitions state to "enqueued_for_submission"' do
        claim.enqueue!
        expect(claim.state).to eq('enqueued_for_submission')
      end

      it 'creates a claim submission job' do
        expect(ClaimSubmissionJob).to receive(:perform_later).with claim
        claim.enqueue!
      end

      it 'saves the claim' do
        expect(claim).to receive(:save!)
        claim.enqueue!
      end

      it 'creates a log event' do
        expect(claim).to receive(:create_event).with 'enqueued'
        claim.enqueue!
      end
    end
  end

  describe '#finalize!' do
    context 'transitioning state from "enqueued_for_submission"' do
      before do
        allow(claim).to receive_messages save!: true
        claim.state = 'enqueued_for_submission'
      end

      it 'transitions state to "submitted"' do
        claim.finalize!
        expect(claim.state).to eq('submitted')
      end

      it 'saves the claim' do
        expect(claim).to receive(:save!)
        claim.finalize!
      end
    end
  end

  describe '#build_primary_claimant' do
    let(:claimant) { claim.build_primary_claimant }

    it 'sets primary_claimant as true' do
      expect(claimant.primary_claimant).to be true
    end
  end

  describe '#payment_fee_group_reference' do
    context 'when payment_attempts is 0' do
      it 'is the same as the fee group reference' do
        expect(claim.payment_fee_group_reference).
          to eq claim.fee_group_reference
      end
    end

    context 'when payment_attempts is > 0' do
      before { claim.payment_attempts = 100 }

      it 'equals "#{fee_group_reference}-#{payment_attempts}"' do
        expect(claim.payment_fee_group_reference).
          to eq "#{claim.fee_group_reference}-#{claim.payment_attempts}"
      end
    end
  end

  describe '#immutable?' do
    context 'when `state` is' do
      context 'created' do
        before { claim.state = 'created' }

        it 'is false' do
          expect(claim).not_to be_immutable
        end
      end

      context 'payment_required' do
        before { claim.state = 'payment_required' }

        it 'is false' do
          expect(claim).not_to be_immutable
        end
      end

      context 'submitted' do
        before { claim.state = 'submitted' }

        it 'is true' do
          expect(claim).to be_immutable
        end
      end

      context 'enqueued_for_submission' do
        before { claim.state = 'enqueued_for_submission' }

        it 'is true' do
          expect(claim).to be_immutable
        end
      end
    end
  end

  describe '#create_event' do
    let(:claim) { create(:claim, :not_submitted) }
    let(:event) { claim.events.where(event: 'lel').first }

    it 'creates an event on the claim with the current state of the claim' do
      claim.create_event 'lel', message: 'funny'
      { event: 'lel', actor: 'app', message: 'funny', claim_state: 'created' }.each do |k, v|
        expect(event[k]).to eq v
      end
    end

    it 'can override the actor' do
      claim.create_event 'lel', actor: 'user'
      expect(event[:actor]).to eq 'user'
    end
  end

  describe 'secondary respondent count' do
    let(:max) { Rails.application.config.additional_respondents_limit }

    context "max secondary respondents" do
      before do
        max.times { claim.secondary_respondents << create(:respondent) }
      end

      it 'Is valid' do
        expect(claim).to be_valid
      end
    end

    context "over max secondary respondents" do
      before do
        (max + 1).times { claim.secondary_respondents << create(:respondent) }
      end

      it 'Is invalid' do
        expect(claim).to be_invalid
      end

      it 'Has correct message' do
        claim.valid?
        expect(claim.errors[:secondary_respondents].first).to eq("You may have no more than #{max} additional respondents")
      end
    end
  end
end
