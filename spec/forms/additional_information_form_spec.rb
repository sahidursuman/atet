require 'rails_helper'

RSpec.describe AdditionalInformationForm, :type => :form do
  subject { described_class.new(resource) }

  let(:resource) { Claim.new }

  describe 'validations' do
    describe 'on #miscellaneous information' do
      context 'when has_miscellaneous_information is true' do
        before { subject.has_miscellaneous_information = 'true' }
        it     { is_expected.to ensure_length_of(:miscellaneous_information).is_at_most(5000) }
      end
    end

    describe 'on #additional_information_rtf' do
      let(:path) { Pathname.new(Rails.root) + 'spec/support/files' }

      before do
        subject.additional_information_rtf = file
        subject.valid?
      end

      context 'when its value is a rtf document' do
        let(:file) { File.open(path + 'file.rtf') }

        it 'does nothing' do
          expect(subject.errors[:additional_information_rtf]).to be_empty
        end
      end

      context 'when its value is a plain text document' do
        let(:file) { File.open(path + 'lel.txt') }

        it 'adds an error message to the attribute' do
          expect(subject.errors[:additional_information_rtf]).to include(I18n.t 'errors.messages.rtf')
        end
      end

      context 'when its value is not a rtf document' do
        let(:file) { File.open(path + 'phil.jpg') }

        it 'adds an error message to the attribute' do
          expect(subject.errors[:additional_information_rtf]).to include(I18n.t 'errors.messages.rtf')
        end
      end
    end

    describe 'on #miscellaneous_information' do
      before do
        subject.miscellaneous_information = 'such miscellany'
      end

      context 'when #has_miscellaneous_information? is true' do
        before { subject.has_miscellaneous_information = 'true' }

        it 'saves #miscellaneous_information to the underlying resource' do
          subject.valid?

          expect(subject.miscellaneous_information).to eq('such miscellany')
        end
      end

      context 'when #has_miscellaneous_information? is false' do
        before { subject.has_miscellaneous_information = 'false' }

        it 'sets #miscellaneous_information to nil on the underlying resource' do
          subject.valid?

          expect(subject.miscellaneous_information).to be nil
        end
      end
    end
  end

  describe '#has_miscellaneous_information?' do
    context 'when the underlying resource' do
      context 'does have miscellaneous information' do
        before do
          resource.miscellaneous_information = 'such miscellany'
        end

        it 'returns true' do
          expect(subject.has_miscellaneous_information).to be true
        end

        it 'sets self.has_miscellaneous_information= with true' do
          expect(subject).to receive(:has_miscellaneous_information=).
            with(true)

          subject.has_miscellaneous_information
        end
      end

      context 'does not have miscellaneous information' do
        before do
          resource.miscellaneous_information = ''
        end

        it 'returns false' do
          expect(subject.has_miscellaneous_information).to be false
        end

        it 'sets self.has_miscellaneous_information= with false' do
          expect(subject).to receive(:has_miscellaneous_information=).
            with(false)

          subject.has_miscellaneous_information
        end
      end
    end
  end
end
