require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  test "buying a product" do
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)

    get "/"
    assert_response :success
    assert_template "index", "Loaded index page "

    xml_http_request :post, '/line_items', product_id: ruby_book.id
    assert_response :success, "Create line item ajax call successful"
    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product, "Cart item is Ruby Book"
    
    get "/orders/new"
    assert_response :success
    assert_template "new"

    post_via_redirect "/orders",
                      order: { name: "Dave Thomas",
                               address: "123 Letsbe Avenue",
                               email: "dave@example.com",
                               pay_type: "Check" }
    assert_response :success
    assert_template "index", "User returned to index after confirming order"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size, "Confirm cart is now empty"

    orders = Order.all
    assert_equal 1, orders.size, "Check there is 1 order"
    order = orders[0]

    assert_equal "Dave Thomas", order.name
    assert_equal "123 Letsbe Avenue", order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check", order.pay_type

    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product, "Check we have the right item"

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'Chris <depot@example.com>', mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject

  end
end
