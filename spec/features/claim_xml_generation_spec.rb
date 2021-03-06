require 'rails_helper'

feature 'Generating XML for a claim', type: :feature do
  let(:claim_xml)     { JaduXml::ClaimPresenter.new(claim).to_xml }
  let(:doc)           { Nokogiri::XML(claim_xml).remove_namespaces! }

  around { |example| travel_to(Date.new(2014, 9, 29)) { example.run } }

  def xpath(path)
    doc.xpath(path).text
  end

  def xpath_collection(path)
    doc.xpath(path).children.map(&:to_s)
  end

  RSpec.shared_examples "validates against the JADU XSD" do
    it do
      xsd = Nokogiri::XML::Schema(File.read(Rails.root + 'spec/support/ETFees_schema.xsd'))
      doc = Nokogiri::XML(claim_xml)

      expect(xsd.validate(doc)).to be_empty
    end
  end

  shared_context 'assign claim' do |claim_options = {}|
    let(:claim) { create :claim, claim_options }

    it_behaves_like "validates against the JADU XSD"
  end

  describe 'ETFeesEntry XML' do
    include_context 'assign claim'

    describe 'DocumentId node elements' do
      it 'has a DocumentName' do
        expect(xpath('//DocumentId/DocumentName')).to eq 'ETFeesEntry'
      end

      it 'has a UniqueId equal to the current time in seconds' do
        expect(xpath('//DocumentId/UniqueId')).to eq '20140929000000'
      end

      it 'has a DocumentType' do
        expect(xpath('//DocumentId/DocumentType')).to eq 'ETFeesEntry'
      end

      it 'has a TimeStamp equal to the current time' do
        expect(xpath('//DocumentId/TimeStamp')).to eq '2014-09-29T00:00:00+01:00'
      end

      it 'has a Version' do
        expect(xpath('//DocumentId/Version')).to eq '1'
      end
    end

    describe 'FeeGroupReference' do
      context 'fgr request failed' do
        include_context 'assign claim', :no_fee_group_reference
        specify { expect(xpath('//FeeGroupReference')).to be_empty }
      end

      context 'fgr request was successful' do
        specify { expect(xpath('//FeeGroupReference')).to eq claim.fee_group_reference }
      end
    end

    it 'has a SubmissionUrn equal to the unique application reference' do
      expect(xpath('//SubmissionUrn')).to eq claim.reference
    end

    it 'has a CurrentQuanityOfCliamants' do
      expect(xpath('//CurrentQuantityOfClaimants')).to eq '6'
    end

    it 'has a SubmissionChannel equal to Web' do
      expect(xpath('//SubmissionChannel')).to eq 'Web'
    end

    describe 'CaseType element' do
      subject { xpath('//CaseType') }

      context 'Claim with multiple claimants' do
        specify { is_expected.to eq 'Multiple' }
      end

      context 'Claim with a single claimant' do
        include_context 'assign claim', :single_claimant
        specify { is_expected.to eq 'Single' }
      end
    end

    describe 'Jurisdiction element' do
      subject { xpath('//Jurisdiction') }

      context 'Claim with unfair dismissal' do
        include_context 'assign claim', is_unfair_dismissal: true, discrimination_claims: nil
        specify { is_expected.to eq '2' }
      end

      context 'Claim with alleged discrimination' do
        include_context 'assign claim', is_unfair_dismissal: false, discrimination_claims: [:disability]
        specify { is_expected.to eq '2' }
      end

      context 'Claim with protective award' do
        include_context 'assign claim', is_protective_award: true, discrimination_claims: nil
        specify { is_expected.to eq '2' }
      end

      context 'Claim with neither alleged discrimination or unfair dismissal' do
        include_context 'assign claim', is_unfair_dismissal: false, discrimination_claims: nil
        specify { is_expected.to eq '1' }
      end
    end

    it 'has a OfficeCode' do
      expect(xpath('//OfficeCode')).to eq '11'
    end

    it 'has a DateOfReceiptEt' do
      expect(xpath('//DateOfReceiptEt')).to eq '2014-09-29T00:00:00+01:00'
    end

    describe 'RemissionIndicated element' do
      subject { xpath('//RemissionIndicated') }

      context 'Claim opted for remission' do
        include_context 'assign claim', :remission_only
        specify { is_expected.to eq 'Indicated' }
      end

      context 'Claim did not opt for remission' do
        specify { is_expected.to eq 'NotRequested' }
      end
    end

    it 'has an Administrator' do
      expect(xpath('//Administrator')).to eq '-1'
    end

    describe 'Claimants' do
      context 'renders nil elements' do
        include_context 'assign claim', :null_primary_claimant
      end

      it 'conatins information regarding the primary claimant' do
        expect(xpath('//Claimant[1]/GroupContact')).to eq 'true'
        expect(xpath('//Claimant[1]/Forename')).to eq 'Barrington'
        expect(xpath('//Claimant[1]/Surname')).to eq 'Wrigglesworth'
        expect(xpath('//Claimant[1]/Address/Line')).to eq '102'
        expect(xpath('//Claimant[1]/Address/Street')).to eq 'Petty France'
        expect(xpath('//Claimant[1]/Address/Town')).to eq 'London'
        expect(xpath('//Claimant[1]/Address/County')).to eq 'Greater London'
        expect(xpath('//Claimant[1]/Address/Postcode')).to eq 'SW1A 1AH'
        expect(xpath('//Claimant[1]/OfficeNumber')).to eq '020 7123 4567'
        expect(xpath('//Claimant[1]/AltPhoneNumber')).to eq '07956273434'
        expect(xpath('//Claimant[1]/Email')).to eq 'Barrington.Wrigglesworth@example.com'
        expect(xpath('//Claimant[1]/PreferredContactMethod')).to eq 'Email'
        expect(xpath('//Claimant[1]/Sex')).to eq 'Male'
        expect(xpath('//Claimant[1]/DateOfBirth')).to eq '06/06/1960'
      end

      it 'contains information regarding secondary claimants' do
        expect(xpath_collection("//Claimant[not(GroupContact='true')]/Forename")).
          to match_array ['dodge', 'horsey', 'jakub', 'michael', 'shergar']
      end
    end

    describe 'Respondents' do
      it 'contains a Respondents details' do
        expect(xpath('//Respondent/GroupContact')).to eq 'true'
        expect(xpath('//Respondent/Name')).to eq 'Ministry of Justice'
        expect(xpath('//Respondent/Address/Street')).to eq 'Petty France'
        expect(xpath('//Respondent/OfficeNumber')).to eq '020 7123 4567'
        expect(xpath('//Respondent/PhoneNumber')).to eq '020 7123 4567'
        expect(xpath('//Respondent/AltPhoneNumber')).to eq '020 7123 4567'
        expect(xpath('//Respondent/AltAddress/Street')).to eq 'Petty France'
      end

      context 'renders nil elements' do
        let(:claim) { create :claim, primary_respondent: respondent }
        let(:respondent) do
          FactoryGirl.create :respondent,
            :without_work_address,
            work_address_telephone_number: nil,
            address_telephone_number: nil
        end

        it_behaves_like "validates against the JADU XSD"

        it 'has an AltAddress with empty nodes' do
          expect(doc.xpath('//Respondent/AltAddress/Line').text).to be_empty
          expect(doc.xpath('//Respondent/AltAddress/Street').text).to be_empty
          expect(doc.xpath('//Respondent/AltAddress/Town').text).to be_empty
          expect(doc.xpath('//Respondent/AltAddress/County').text).to be_empty
          expect(doc.xpath('//Respondent/AltAddress/Postcode').text).to be_empty
        end

        it 'has an empty AltPhoneNumber' do
          expect(doc.xpath('//Respondent/AltPhoneNumber').text).to be_empty
        end
      end

      describe 'Acas element' do
        context 'with an acas number' do
          include_context 'assign claim', :respondent_with_acas_number

          it 'contains a Number' do
            expect(xpath('//Respondent/Acas/Number')).to eq 'SOMEACASNUMBER'
            expect(doc.xpath('//Respondent/Acas/ExemptionCode')).to be_empty
          end
        end

        context 'with no acas number' do
          it 'contains an ExemptionCode' do
            expect(xpath('//Respondent/Acas/ExemptionCode')).to eq 'employer_contacted_acas'
            expect(doc.xpath('//Respondent/Acas/Number')).to be_empty
          end
        end
      end
    end

    describe 'Representatives' do
      context 'Claim without a representative' do
        include_context 'assign claim', :without_representative

        it 'still renders a node' do
          expect(doc.xpath('//Representatives')).not_to be_empty
        end
      end

      context 'renders nil elements' do
        include_context 'assign claim', :null_representative
      end

      context 'Claim with a representative' do
        it 'contains a Representatives details' do
          expect(xpath('//Representative/Name')).to eq 'Saul Goodman'
          expect(xpath('//Representative/Address/Street')).to eq 'Petty France'
          expect(xpath('//Representative/OfficeNumber')).to eq '020 7123 4567'
          expect(xpath('//Representative/ClaimantOrRespondent')).to eq 'C'
          expect(xpath('//Representative/Type')).to eq 'Law Centre'
          expect(xpath('//Representative/DXNumber')).to eq '1234'
        end
      end
    end

    describe 'Payment' do
      describe 'Fee' do
        it 'has an Amount(in pounds)' do
          expect(xpath('//Payment/Fee/Amount')).to eq "0"
        end

        describe 'PRN(alias for fee group reference)' do
          context 'fgr request failed' do
            let(:claim) { create :claim, :no_fee_group_reference }

            specify { expect(xpath('//Payment/Fee/PRN')).to be_empty }
          end

          context 'fgr request was successful' do
            specify { expect(xpath('//Payment/Fee/PRN')).to eq claim.fee_group_reference }
          end
        end

        it 'has a Date' do
          expect(xpath('//Payment/Fee/Date')).to eq '2014-09-29T00:00:00+01:00'
        end
      end

      describe 'Receipt' do
        context 'a successful payment was made by the claimant' do
          it 'has a PSP(Payment Service Provider)' do
            expect(xpath('//Payment/Receipt/PSP')).to eq 'Barclaycard'
          end
          it 'has a PayId' do
            expect(xpath('//Payment/Receipt/PayId')).to match(/^[0-9]{1,8}$/)
          end
          it 'has an Amount' do
            expect(xpath('//Payment/Receipt/Amount')).to eq '250'
          end
          it 'has a Date' do
            expect(xpath('//Payment/Receipt/Date')).to eq '2014-09-29T00:00:00+01:00'
          end
        end

        context 'no payment was made' do
          include_context 'assign claim', :payment_failed

          it 'does not contain a Receipt' do
            expect(xpath('//Payment/Receipt')).to be_empty
          end
        end
      end
    end

    describe 'Files' do
      include_context 'assign claim', :with_pdf

      it 'has upto 3 filenames' do
        expect(xpath_collection('//Files/File/Filename')).
          to match_array ['file.csv', 'file.rtf', 'et1_barrington_wrigglesworth.pdf']
      end

      it 'has upto 3 file checksums' do
        md5_checksum = /^[a-f0-9]{32}$/
        expect(xpath_collection('//Files/File/Checksum')).to match Array.new(3, md5_checksum)
      end
    end
  end
end
