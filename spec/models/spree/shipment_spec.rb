require 'rails_helper'

describe Spree::Shipment, :type => :model do
  # ActiveRecord::Base.logger = Logger.new(STDOUT) if defined?(ActiveRecord::Base)

  context "between" do
    before do
      Spree::Order.record_timestamps    = false
      Spree::Shipment.record_timestamps = false

      @active = []

      create_shipment({ updated_at: 1.day.ago }, { updated_at: 1.day.ago })
      create_shipment({ updated_at: 1.day.from_now }, { updated_at: 1.day.from_now })

      # Old shipment thats order was recently updated..
      @active << create_shipment({ updated_at: 1.year.ago }, { updated_at: Time.now })

      @active << create_shipment(updated_at: Time.now)
      @active << create_shipment(updated_at: Time.now)

      Spree::Order.record_timestamps    = true
      Spree::Shipment.record_timestamps = true
    end

    subject { Spree::Shipment.between((Time.now - 1.hour), (Time.now + 1.hour)) }

    it 'has 3 shipment' do
      expect(subject.size).to eq(3)
    end

    it { is_expected.to eq(@active) }
  end

  context "exportable" do
    let!(:pending) { create_shipment(state: 'pending') }
    let!(:ready) { create_shipment(state: 'ready') }
    let!(:shipped) { create_shipment(state: 'shipped') }

    subject { Spree::Shipment.exportable }

    it 'has 2 shipments' do
      expect(subject.size).to eq(2)
    end

    it { is_expected.to include(ready) }
    it { is_expected.to include(shipped) }
    it { is_expected.not_to include(pending) }
  end

  context "shipped_email" do
    let(:shipment) { create_shipment(state: 'ready') }

    context "enabled" do
      it "sends email" do
        Spree::Config.send_shipped_email = true
        mail_message                     = double "Mail::Message"
        expect(Spree::ShipmentMailer).to receive(:shipped_email).with(shipment).and_return mail_message
        expect(mail_message).to receive :deliver
        shipment.ship!
      end
    end

    context "disabled" do
      it "doesnt send email" do
        Spree::Config.send_shipped_email = false
        expect(Spree::ShipmentMailer).not_to receive(:shipped_email)
        shipment.ship!
      end
    end
  end

  def create_shipment(options={}, order_options={})
    FactoryGirl.create(:shipment, options).tap do |shipment|
      shipment.update_column(:updated_at, options[:updated_at]) if options[:updated_at]
      shipment.update_column(:created_at, options[:created_at]) if options[:created_at]
      shipment.update_column(:state, options[:state]) if options[:state]

      shipment.order.update_column(:updated_at, order_options[:updated_at]) if order_options[:updated_at]
      shipment.order.update_column(:created_at, order_options[:created_at]) if order_options[:created_at]
    end
  end
end
