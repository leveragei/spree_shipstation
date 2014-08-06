require 'rails_helper'

include Spree

describe Spree::ShipmentNotice do
  let(:notice) { ShipmentNotice.new(order_number: 'S12345', tracking_number: '1Z1231234') }

  context "#apply" do
    context "shipment found" do
      let(:shipment) { mock_model(Shipment, :shipped? => false) }

      before do
        Spree::Config.shipstation_number = :shipment
        expect(Shipment).to receive(:find_by_number).with('S12345').and_return(shipment)
        expect(shipment).to receive(:update_attribute).with(:tracking, '1Z1231234')
      end

      context "transition succeeds" do
        before do
          allow(shipment).to receive_message_chain(:reload, :update_attribute).with(:state, 'shipped')
          allow(shipment).to receive_message_chain(:inventory_units, :each)
          expect(shipment).to receive(:touch).with(:shipped_at)
        end

        specify { expect(notice.apply).to be_truthy }
      end

      context "transition fails" do
        before do
          allow(shipment).to receive_message_chain(:reload, :update_attribute)
                             .with(:state, 'shipped')
                             .and_raise('oopsie')
          @result = notice.apply
        end

        specify { expect(@result).to be_falsey }
        specify { expect(notice.error).not_to be_blank }
      end
    end

    context "using order number instead of shipment number" do
      let(:shipment) { mock_model(Shipment, :shipped? => false) }
      let(:order) { mock_model(Order, shipment: shipment) }

      before do
        Spree::Config.shipstation_number = :order
        expect(Order).to receive(:find_by_number).with('S12345').and_return(order)
        expect(shipment).to receive(:update_attribute).with(:tracking, '1Z1231234')
        allow(shipment).to receive_message_chain(:inventory_units, :each)
        expect(shipment).to receive(:touch).with(:shipped_at)
      end

      context "transition succeeds" do
        before { allow(shipment).to receive_message_chain(:reload, :update_attribute).with(:state, 'shipped') }

        specify { expect(notice.apply).to be_truthy }
      end
    end

    context "shipment not found" do
      before do
        Spree::Config.shipstation_number = :shipment
        expect(Shipment).to receive(:find_by_number).with('S12345').and_return(nil)
        @result = notice.apply
      end

      specify { expect(@result).to be_falsey }
      specify { expect(notice.error).not_to be_blank }
    end

    context "shipment already shipped" do
      let(:shipment) { mock_model(Shipment, :shipped? => true) }

      before do
        Spree::Config.shipstation_number = :shipment
        expect(Shipment).to receive(:find_by_number).with('S12345').and_return(shipment)
        expect(shipment).to receive(:update_attribute).with(:tracking, '1Z1231234')
      end

      specify { expect(notice.apply).to be_truthy }
    end
  end
end
