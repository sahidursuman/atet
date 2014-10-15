require 'rails_helper'

RSpec.describe AdditionalInformationForm, :type => :form do
  let(:resource) { double 'resource' }
  subject { described_class.new { |f| f.resource = resource } }

  describe 'validations' do
    it { is_expected.to ensure_length_of(:miscellaneous_information).is_at_most(5000) }

    describe 'on #attachment' do
      let(:path) { Pathname.new(Rails.root) + 'spec/support/files' }
      before do
        subject.attachment = file
        subject.valid?
      end

      context 'when its value is a plain text file' do
        let(:file) { File.open(path + 'file.rtf') }

        it 'does nothing' do
          expect(subject.errors[:attachment]).to be_empty
        end
      end

      context 'when its value is not a plain text file' do
        let(:file) { File.open(path + 'phil.jpg') }

        it 'adds an error message to the attribute' do
          expect(subject.errors[:attachment]).to include(I18n.t 'errors.messages.rtf')
        end
      end
    end
  end

  describe '#save' do
    before do
      allow(resource).to receive :save
      subject.miscellaneous_information = 'such miscellany'
    end

    context 'when #has_miscellaneous_information? is true' do
      before { subject.has_miscellaneous_information = true }

      it 'saves #miscellaneous_information to the underlying resource' do
        expect(resource).to receive(:update_attributes).
            with miscellaneous_information: 'such miscellany'

        subject.save
      end
    end

    context 'when #has_miscellaneous_information? is true' do
      before { subject.has_miscellaneous_information = false }

      it 'sets #miscellaneous_information to nil on the underlying resource' do
        expect(resource).to receive(:update_attributes).
          with miscellaneous_information: nil

        subject.save
      end
    end
  end

  describe '#has_miscellaneous_information' do
    context 'when the underlying resource' do
      context 'does have miscellaneous information' do
        before do
          allow(resource).to receive(:miscellaneous_information).
            and_return 'such miscellany'
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
          allow(resource).to receive(:miscellaneous_information).
            and_return ''
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