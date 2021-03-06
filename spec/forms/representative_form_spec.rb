require 'rails_helper'

RSpec.describe RepresentativeForm, type: :form do
  let(:representative) { Representative.new }
  let(:resource)       { Claim.new representative: representative }

  let(:representative_form) { described_class.new resource }

  describe '#has_representative' do
    context 'when the representative has not been persisted' do
      it 'is false' do
        expect(representative_form.has_representative).to be false
      end
    end

    context 'when the representative has been persisted' do
      before { allow(representative).to receive_messages persisted?: true }

      it 'is true' do
        expect(representative_form.has_representative).to be true
      end
    end
  end

  describe '#save' do
    context 'when has_representative? == false' do
      before do
        representative_form.has_representative = 'false'
      end

      it 'destroys the representative relation' do
        expect(representative).to receive :destroy

        representative_form.save
      end
    end
  end

  describe 'validations' do
    context 'when has_representative? == true' do
      before { representative_form.has_representative = 'true' }

      [:type, :name, :address_building, :address_street, :address_locality, :address_post_code].each do |attr|
        it { expect(representative_form).to validate_presence_of(attr) }
      end

      it do
        expect(representative_form).to validate_inclusion_of(:type).in_array \
          ['citizen_advice_bureau', 'free_representation_unit', 'law_centre', 'trade_union',
           'solicitor', 'private_individual', 'trade_association', 'other']
      end

      it { expect(representative_form).to ensure_length_of(:name).is_at_most(100) }
      it { expect(representative_form).to ensure_length_of(:organisation_name).is_at_most(100) }

      it { expect(representative_form).to ensure_length_of(:address_building).is_at_most(75) }
      it { expect(representative_form).to ensure_length_of(:address_street).is_at_most(75) }
      it { expect(representative_form).to ensure_length_of(:address_locality).is_at_most(25) }
      it { expect(representative_form).to ensure_length_of(:address_county).is_at_most(25) }
      it { expect(representative_form).to ensure_length_of(:address_post_code).is_at_most(8) }

      it { expect(representative_form).to ensure_length_of(:address_telephone_number).is_at_most(21) }
      it { expect(representative_form).to ensure_length_of(:mobile_number).is_at_most(21) }
      it { expect(representative_form).to ensure_length_of(:dx_number).is_at_most(40) }

    end

    context 'when has_representative? == false' do
      before { representative_form.has_representative = 'false' }

      it 'is valid' do
        expect(representative_form).to be_valid
      end
    end
  end

  describe 'form' do
    subject { representative_form }

    it_behaves_like "a Form",
      name: 'Saul Goodman',
      organisation_name: 'Better Call Saul',
      type: 'citizen_advice_bureau', dx_number: '1',
      address_building: '1', address_street: 'High Street',
      address_locality: 'Anytown', address_county: 'Anyfordshire',
      address_post_code: 'AT1 0AA', email_address: 'lol@example.com',
      has_representative: true

    describe 'postcode validation' do
      before { representative_form.has_representative = 'true' }

      include_examples "Postcode validation",
        attribute_prefix: 'address',
        error_message: 'Enter a valid postcode. If your representative lives abroad, enter SW55 9QT'
      include_examples "Email validation",
        error_message: 'You have entered an invalid email address'
    end

  end

end
