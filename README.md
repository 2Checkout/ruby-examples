2Checkout Payment API Ruby Tutorial
=========================

In this tutorial we will walk through integrating the 2Checkout Payment API to securely tokenize and charge a credit card using the [2Checkout Ruby Gem](https://www.2checkout.com/documentation/libraries/ruby). You will need a 2Checkout sandbox account to complete the tutorial so if you have not already, [signup for an account](https://sandbox.2checkout.com/sandbox/signup) and [generate your Payment API keys](https://www.2checkout.com/documentation/sandbox/payment-api-testing).

----

### Application Setup

For our example application, we will be using ruby 2.1.0 and the sinatra framework.

```
gem install sinatra
```

We will also need to install the twocheckout gem which provides us with a simple bindings to the API, INS and Checkout process so that we can integrate each feature with only a few lines of code. In this example, we will only be using the Payment API functionality of the library, but for an example of the other features you can view this tutorial: [https://github.com/2Checkout/2checkout-ruby-tutorial](https://github.com/2Checkout/2checkout-ruby-tutorial)

```
gem install twocheckout
```

To start off, lets setup the file structure for our example application.

```
└── payment-api
    ├── app.rb
    └── public
        └── index.html
```

Here we created a new directory for our application named 'payment-api' with a new file 'app.rb' for our ruby script. We also created a sub-directory 'public' with an 'index.html' file to display our credit card form.

----

# Create a Token

Open the 'index.html' file under the public directory and create a basic HTML skeleton.

```
<!DOCTYPE html>
<html>
    <head>
        <title>Ruby Example</title>
    </head>
    <body>

    </body>
</html>
```

Next add a basic credit card form that allows our buyer to enter in their card number, expiration month and year and CVC.

```
<form id="myCCForm" action="/order" method="post">
    <input id="token" name="token" type="hidden" value="">
    <div>
        <label>
            <span>Card Number</span>
        </label>
        <input id="ccNo" type="text" size="20" value="" autocomplete="off" required />
    </div>
    <div>
        <label>
            <span>Expiration Date (MM/YYYY)</span>
        </label>
        <input type="text" size="2" id="expMonth" required />
        <span> / </span>
        <input type="text" size="2" id="expYear" required />
    </div>
    <div>
        <label>
            <span>CVC</span>
        </label>
        <input id="cvv" size="4" type="text" value="" autocomplete="off" required />
    </div>
    <input type="submit" value="Submit Payment">
</form>
```

Notice that we have a no 'name' attributes on the input elements that collect the credit card information. This will insure that no sensitive card data touches your server when the form is submitted. Also, we include a hidden input element for the token which we will submit to our server to make the authorization request.

Now we can add our JavaScript to make the token request call. Replace 'sandbox-seller-id' and 'sandbox-publishable-key' with your credentials.

```
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
<script src="https://www.2checkout.com/checkout/api/2co.min.js"></script>

<script>
    // Called when token created successfully.
    var successCallback = function(data) {
        var myForm = document.getElementById('myCCForm');

        // Set the token as the value for the token input
        myForm.token.value = data.response.token.token;

        // IMPORTANT: Here we call `submit()` on the form element directly instead of using jQuery to prevent and infinite token request loop.
        myForm.submit();
    };

    // Called when token creation fails.
    var errorCallback = function(data) {
        if (data.errorCode === 200) {
            tokenRequest();
        } else {
            alert(data.errorMsg);
        }
    };

    var tokenRequest = function() {
        // Setup token request arguments
        var args = {
            sellerId: "sandbox-seller-id",
            publishableKey: "sandbox-publishable-key",
            ccNo: $("#ccNo").val(),
            cvv: $("#cvv").val(),
            expMonth: $("#expMonth").val(),
            expYear: $("#expYear").val()
        };

        // Make the token request
        TCO.requestToken(successCallback, errorCallback, args);
    };

    $(function() {
        // Pull in the public encryption key for our environment
        TCO.loadPubKey('sandbox');

        $("#myCCForm").submit(function(e) {
            // Call our token request function
            tokenRequest();

            // Prevent form from submitting
            return false;
        });
    });
</script>
```

Let's take a second to look at what we did here. First we pulled in a jQuery library to help us with manipulating the document.
(The 2co.js library does NOT require jQuery.)

Next we pulled in the 2co.js library so that we can make our token request with the card details.

```
<script src="https://www.2checkout.com/checkout/api/2co.min.js"></script>
```

This library provides us with 2 functions, one to load the public encryption key, and one to make the token request.

The `TCO.loadPubKey(String environment, Function callback)` function must be used to asynchronously load the public encryption key for the 'production' or 'sandbox' environment. In this example, we are going to call this as soon as the document is ready so it is not necessary to provide a callback.

```
TCO.loadPubKey('sandbox');
```

The the 'TCO.requestToken(Function callback, Function callback, Object arguments)' function is used to make the token request. This function takes 3 arguments:

* Your success callback function which accepts one argument and will be called when the request is successful.
* Your error callback function which accepts one argument and will be called when the request results in an error.
* An object containing the credit card details and your credentials.
    * **sellerId** : 2Checkout account number
    * **publishableKey** : Payment API publishable key
    * **ccNo** : Credit Card Number
    * **expMonth** : Card Expiration Month
    * **expYear** : Card Expiration Year
    * **cvv** : Card Verification Code

```
TCO.requestToken(successCallback, errorCallback, args);
```




In our example we created 'tokenRequest' function to setup our arguments by pulling the values entered on the credit card form and we make the token request.

```
var tokenRequest = function() {
    // Setup token request arguments
    var args = {
        sellerId: "sandbox-seller-id",
        publishableKey: "sandbox-publishable-key",
        ccNo: $("#ccNo").val(),
        cvv: $("#cvv").val(),
        expMonth: $("#expMonth").val(),
        expYear: $("#expYear").val()
    };

    // Make the token request
    TCO.requestToken(successCallback, errorCallback, args);
};
```

We then call this function from a submit handler function that we setup on the form.

```
$("#myCCForm").submit(function(e) {
    // Call our token request function
    tokenRequest();

    // Prevent form from submitting
    return false;
});
```

The 'successCallback' function is called if the token request is successful. In this function we set the token as the value for our 'token' hidden input element and we submit the form to our server.

```
var successCallback = function(data) {
    var myForm = document.getElementById('myCCForm');

    // Set the token as the value for the token input
    myForm.token.value = data.response.token.token;

    // IMPORTANT: Here we call `submit()` on the form element directly instead of using jQuery to prevent and infinite token request loop.
    myForm.submit();
};
```

The 'errorCallback' function is called if the token request fails. In our example function, we check for error code 200, which indicates that the ajax call has failed. If the error code was 200, we automatically re-attempt the tokenization, otherwise, we alert with the error message.

```
var errorCallback = function(data) {
    if (data.errorCode === 200) {
        tokenRequest();
    } else {
        alert(data.errorMsg);
    }
};
```

----

# Create the Sale

Open 'app.rb' and require the sinatra and twocheckout gems.

```
require 'sinatra'
require 'twocheckout'
```

Next lets create routes for '/' and '/order'.

```
get '/' do

end

get '/order' do

end
```

In the '/' route, we will redirect to 'index.html' and display it to the buyer.

```
get '/' do
  redirect '/index.html'
end
```

In the order route, we will use the token passed from our credit card form to submit the authorization request and display the response.
Replace 'sandbox-seller-id' and 'sandbox-private-key' with your credentials.


```
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
```

Lets break down this method a bit and explain what were doing here.

First we setup our credentials and the environment using the 'Twocheckout::API.credentials(hash)' function. This function accepts a hash as the argument containing the following keys.
* private_key: Your Payment API private key
* seller_id: 2Checkout account number
* sandbox: Set to 1 to use sandbox (optional)

Next we create a hash with our authorization attributes. In our example we are using hard coded strings for each required attribute except for the token which is passed in from the credit card form.

**Important Note: A token can only be used for one authorization call, and will expire after 30 minutes if not used.**

```
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
        :email => 'cchristenson@2co.com',
        :phoneNumber => '555-555-5555'
      }
  }
```

Finally we submit the charge using the 'Twocheckout::Checkout.authorize(hash)' function and display the result to the buyer. It is important to wrap this in a begin/rescue block so that you can handle the response and rescue the 'Twocheckout::TwocheckoutError' exception that will be thrown if the card fails to authorize.

```
begin
  result = Twocheckout::Checkout.authorize(@args)
    "Order Complete: #{result['responseMsg']}"
  rescue Twocheckout::TwocheckoutError => e
    "Order Failed: #{e.message}"
end
```

----

# Run the example application

In your console, navigate to the 'payment-api' directory and startup the application.

```
ruby app.rb
```

In your browser, navigate to 'http://localhost:4567', and you should see a payment form where you can enter credit card information.

For your testing, you can use these values for a successful authorization
>Credit Card Number: 4000000000000002

>Expiration date: 10/2020

>cvv: 123

And these values for a failed authorization:

>Credit Card Number: 4333433343334333

>Expiration date: 10/2020

>cvv:123

If you have any questions, feel free to send them to techsupport@2co.com
