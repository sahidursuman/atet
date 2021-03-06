require 'rails_helper'

RSpec.describe EmploymentForm, type: :form do
  let(:employment_form) { described_class.new resource }

  let(:resource)   { Claim.new employment: employment }
  let(:employment) { Employment.new }

  it_behaves_like 'it parses dates',
    :start_date, :end_date, :notice_period_end_date, :new_job_start_date

  describe 'validations' do
    [:gross_pay, :net_pay, :new_job_gross_pay].each do |attribute|
      it { expect(employment_form).to validate_numericality_of(attribute).allow_nil }
    end

    { new_job_gross_pay_frequency: :new_job_gross_pay, notice_pay_period_type: :notice_pay_period_count,
      gross_pay_period_type: :gross_pay, net_pay_period_type: :net_pay }.
      each do |type, pay|
        describe type.to_s do
          context "when #{pay} is true" do
            before { employment_form.send "#{pay}=", "100" }

            it { expect(employment_form).to validate_presence_of type }
          end

          context "when #{pay} is false" do
            it { expect(employment_form).not_to validate_presence_of type }
          end
        end
      end
  end

  [:gross_pay, :net_pay, :new_job_gross_pay].each do |attr|
    describe "#{attr}=" do
      before { employment_form.send "#{attr}=", '10,000' }

      it 'strips commas entered by the user' do
        expect(employment_form.send(attr)).to eq 10000
      end
    end
  end

  describe '#was_employed' do
    context 'when the employment model has not been persisted' do
      before { allow(employment).to receive_messages persisted?: false }

      it 'is false' do
        expect(employment_form.was_employed).to be false
      end
    end

    context 'when the employment model has been persisted' do
      before { allow(employment).to receive_messages persisted?: true }

      it 'is true' do
        expect(employment_form.was_employed).to be true
      end
    end
  end

  describe 'callbacks' do
    context 'was not employed' do
      before { employment_form.was_employed = 'false' }

      it 'destroys the representative relation' do
        expect(employment).to receive :destroy
        employment_form.save
      end
    end

    context 'was employed' do
      before do
        employment_form.assign_attributes worked_notice_period_or_paid_in_lieu: true,
                                          notice_period_end_date: 1.week.ago.to_date, end_date: Time.zone.today,
                                          notice_pay_period_count: '1', notice_pay_period_type: 'weeks',
                                          found_new_job: 'true', new_job_start_date: 1.week.from_now.to_date,
                                          new_job_gross_pay: '100', new_job_gross_pay_frequency: 'monthly',
                                          was_employed: 'true'
      end

      context 'when still employed' do
        before do
          employment_form.current_situation = 'still_employed'
          employment_form.valid?
        end

        context 'previously entered other information clears other fields' do
          it { expect(employment_form.worked_notice_period_or_paid_in_lieu).to be nil }
          it { expect(employment_form.notice_period_end_date).to be nil }
          it { expect(employment_form.end_date).to be nil }
          it { expect(employment_form.notice_pay_period_count).to be nil }
          it { expect(employment_form.new_job_start_date).to be nil }
        end
      end

      context 'when in notice period clears other fields but keeps notice period end dat' do
        before do
          employment_form.current_situation = 'notice_period'
          employment_form.valid?
        end

        it { expect(employment_form.notice_period_end_date).not_to be nil }
        it { expect(employment_form.end_date).to be nil }
        it { expect(employment_form.worked_notice_period_or_paid_in_lieu).to be nil }
        it { expect(employment_form.notice_pay_period_count).to be nil }
        it { expect(employment_form.new_job_start_date).to be nil }
      end

      context 'when employment terminated' do
        before { employment_form.current_situation = 'employment_terminated' }

        context 'when previously entered new job details' do
          context 'when selecting no new job clears new job details' do
            before do
              employment_form.found_new_job = false
              employment_form.valid?
            end

            it { expect(employment_form.new_job_start_date).to be nil }
            it { expect(employment_form.new_job_gross_pay).to be nil }
            it { expect(employment_form.new_job_gross_pay_frequency).to be nil }
          end

          context 'when selecting new job details are not removed' do
            before do
              employment_form.found_new_job = 'true'
              employment_form.valid?
            end

            it { expect(employment_form.new_job_start_date).not_to be nil }
            it { expect(employment_form.new_job_gross_pay).not_to be nil }
            it { expect(employment_form.new_job_gross_pay_frequency).not_to be nil }
          end
        end

        context 'when previously entered notice period details' do
          context 'when selecting no notice period clears notice period details' do
            before do
              employment_form.worked_notice_period_or_paid_in_lieu = 'false'
              employment_form.valid?
            end

            it { expect(employment_form.notice_pay_period_count).to be nil }
            it { expect(employment_form.notice_pay_period_type).to be nil }
          end
        end
      end
    end
  end
end
