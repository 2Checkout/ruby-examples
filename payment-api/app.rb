require 'sinatra'
require 'twocheckout'


get '/' do
  redirect '/index.html'
end


post '/order' do
  Twocheckout::API.credentials = {
      :seller_id => 'sandbox-seller-id',
      :private_key => 'sandbox-private-key',
      :sandbox => 1
  }

  @args = {
      :merchantOrderId     => '123',
      :token          => params[:token],
      :currency       => 'USD',
      :total          => '1.00',
      :billingAddr    => {
          :name => 'Testing Tester',
          :addrLine1 => '123 Test St',
          :city => 'Columbus',
          :state => 'OH',
          :zipCode => '43123',
          :country => 'USA',
          :email => 'example@2co.com',
          :phoneNumber => '555-555-5555'
      }
  }

  begin
    result = Twocheckout::Checkout.authorize(@args)
    "Order Complete: #{result['responseMsg']}"
  rescue Twocheckout::TwocheckoutError => e
    "Order Failed: #{e.message}"
  end
end
