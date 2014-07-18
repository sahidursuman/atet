RSpec.describe ClaimFeeCalculator, type: :service do
  let(:claim) { Claim.new }
  let(:calculation) { ClaimFeeCalculator.calculate claim: claim }

  describe '.calculate' do
    describe 'calculating the application fee' do
      context 'when the claim pertains to discrimination or unfair dismissal' do
        before do
          allow(claim).
            to receive(:alleges_discrimination_or_unfair_dismissal?).
            and_return true
        end

        context 'with a single claimant' do
          before { allow(claim).to receive(:claimant_count).and_return 1 }

          it 'is £250' do
            expect(calculation.application_fee).to eq '£250'
          end
        end

        context "with 2..10 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(2..10) }

          it "is £500" do
            (2..10).each { expect(calculation.application_fee).to eq '£500' }
          end
        end

        context "with 11..200 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(11..200) }

          it "is £1000" do
            (11..200).each { expect(calculation.application_fee).to eq '£1000' }
          end
        end

        context 'with 201 or more claimants' do
          before { allow(claim).to receive(:claimant_count).and_return Float::INFINITY }

          it "is £1500" do
            expect(calculation.application_fee).to eq '£1500'
          end
        end
      end

      context 'when the claim does not pertain to discrimination or unfair dismissal' do
        before do
          allow(claim).
            to receive(:alleges_discrimination_or_unfair_dismissal?).
            and_return false
        end

        context 'with a single claimant' do
          before { allow(claim).to receive(:claimant_count).and_return 1 }

          it 'is £160' do
            expect(calculation.application_fee).to eq '£160'
          end
        end

        context "with 2..10 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(2..10) }

          it "is £320" do
            (2..10).each { expect(calculation.application_fee).to eq '£320' }
          end
        end

        context "with 11..200 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(11..200) }

          it "is £640" do
            (11..200).each { expect(calculation.application_fee).to eq '£640' }
          end
        end

        context 'with 201 or more claimants' do
          before { allow(claim).to receive(:claimant_count).and_return Float::INFINITY }

          it "is £960" do
            expect(calculation.application_fee).to eq '£960'
          end
        end
      end
    end

    describe 'calculating the hearing fee' do
      context 'when the claim pertains to discrimination or unfair dismissal' do
        before do
          allow(claim).
            to receive(:alleges_discrimination_or_unfair_dismissal?).
            and_return true
        end

        context 'with a single claimant' do
          before { allow(claim).to receive(:claimant_count).and_return 1 }

          it 'is £950' do
            expect(calculation.hearing_fee).to eq '£950'
          end
        end

        context "with 2..10 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(2..10) }

          it "is £1900" do
            (2..10).each { expect(calculation.hearing_fee).to eq '£1900' }
          end
        end

        context "with 11..200 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(11..200) }

          it "is £3800" do
            (11..200).each { expect(calculation.hearing_fee).to eq '£3800' }
          end
        end

        context 'with 201 or more claimants' do
          before { allow(claim).to receive(:claimant_count).and_return Float::INFINITY }

          it "is £5700" do
            expect(calculation.hearing_fee).to eq '£5700'
          end
        end
      end

      context 'when the claim does not pertain to discrimination or unfair dismissal' do
        before do
          allow(claim).
            to receive(:alleges_discrimination_or_unfair_dismissal?).
            and_return false
        end

        context 'with a single claimant' do
          before { allow(claim).to receive(:claimant_count).and_return 1 }

          it 'is £230' do
            expect(calculation.hearing_fee).to eq '£230'
          end
        end

        context "with 2..10 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(2..10) }

          it "is £460" do
            (2..10).each { expect(calculation.hearing_fee).to eq '£460' }
          end
        end

        context "with 11..200 claimants" do
          before { allow(claim).to receive(:claimant_count).and_return *(11..200) }

          it "is £920" do
            (11..200).each { expect(calculation.hearing_fee).to eq '£920' }
          end
        end

        context 'with 201 or more claimants' do
          before { allow(claim).to receive(:claimant_count).and_return Float::INFINITY }

          it "is £1380" do
            expect(calculation.hearing_fee).to eq '£1380'
          end
        end
      end
    end
  end
end