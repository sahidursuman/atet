require 'rails_helper'

RSpec.describe AccessDetailsMailer, type: :service do
  include ActiveJob::TestHelper
  include ActiveJobPerformHelper

  describe '.deliver_later' do
    context 'when the claim has an email address' do

      let(:claim) { Claim.create email_address: "funky@emailaddress.com" }

      it 'delivers access details via email' do
        described_class.deliver_later(claim)

        expect { perform_active_jobs(ActionMailer::DeliveryJob) }.
          to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context 'when the claim has no email address' do

      let(:claim) { Claim.new }

      it 'doesnt deliver access details via email' do
        described_class.deliver_later(claim)
        expect(ActionMailer::DeliveryJob).not_to have_been_enqueued
      end
    end
  end
end
