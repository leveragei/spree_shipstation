require 'rails_helper'

describe Spree::ShipstationController, :type => :controller do
  # stub_authorization!
  # spree_current_user: FactoryGirl.create(:user)
  # allow(Spree::CheckoutController).to receive_messages(try_spree_current_user: FactoryGirl.create(:user))
  before do
    # allow(Spree::CheckoutController).to receive_messages(check_authorization: false)
    # allow_any_instance_of(Spree::CheckoutController).to receive_messages(:try_spree_current_user => FactoryGirl.create(:user))
    @request.accept = 'application/xml'
  end

  context "logged in" do
    before { login }

    context "export" do
      let(:shipments) { double }

      before do
        allow(Spree::Shipment).to receive_message_chain(:exportable, :between).with(Time.new(2013, 12, 31, 8, 0, 0, "+00:00"),
                                                                                    Time.new(2014, 1, 13, 23, 0, 0, "+00:00"))
                                                                              .and_return(shipments)

        allow(shipments).to receive_message_chain(:page, :per).and_return(:some_shipments)
        get :export, start_date: '12/31/2013 8:00', end_date: '1/13/2014 23:00', use_route: :spree
      end

      specify { expect(response).to be_success }
      specify { expect(assigns(:shipments)).to eq(:some_shipments) }
    end

    context "shipnotify" do
      let(:notice) { double(:notice) }

      before do
        expect(Spree::ShipmentNotice).to receive(:new)
                                         .with(hash_including(order_number: 'S12345'))
                                         .and_return(notice)
      end

      context "shipment found" do
        before do
          expect(notice).to receive(:apply).and_return(true)

          post :shipnotify, order_number: 'S12345', use_route: :spree
        end

        specify { expect(response).to be_success }
        specify { expect(response.body).to match(/success/) }
      end

      context "shipment not found" do
        before do
          expect(notice).to receive(:apply).and_return(false)
          expect(notice).to receive(:error).and_return("failed")

          post :shipnotify, order_number: 'S12345', use_route: :spree
        end

        specify { expect(response.code).to eq('400') }
        specify { expect(response.body).to match(/failed/) }
      end
    end

    it "doesnt know unknown" do
      expect { post :unknown, use_route: :spree }.to raise_error(AbstractController::ActionNotFound)
    end
  end

  context "not logged in" do
    it "returns error" do
      get :export, use_route: :spree

      expect(response.code).to eq('401')
    end
  end

  def login
    config(username: "mario", password: 'lemieux')
    user, pw  = 'mario', 'lemieux'
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pw)
  end

  def config(options = {})
    options.each do |k, v|
      Spree::Config.send("shipstation_#{k}=", v)
    end
  end
end
