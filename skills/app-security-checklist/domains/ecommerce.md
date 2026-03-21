# E-commerce Security Profile

## Compliance Framework
- PCI DSS v4.0 (card processing)
- GDPR (EU customers)
- CCPA (California customers)
- Consumer protection regulations

## Detection Signals
Keywords that trigger auto-detection: `cart`, `checkout`, `product`, `order`,
`inventory`, `shipping`, `catalog`, `storefront`

## Severity Elevations

| Item | Standard Severity | E-commerce Severity | Reason |
|------|-------------------|---------------------|--------|
| AC-01 (IDOR) | High | Critical | Order/payment data exposure |
| DP-02 (Secrets in code) | Critical | Critical | Payment gateway keys |
| CS-01 (HTTPS) | High | Critical | PCI DSS requirement |
| SM-02 (Cookie flags) | High | Critical | Session hijacking = payment access |

## Additional Checks

### EC-01: Price Tampering
- **What to check:** Prices validated server-side, not trusted from client
- **Detection patterns:**
  - Search: `price` in params accepted by order/cart creation
  - Search: `params\[:price\]|params\[:amount\]` in order controllers
  - Search: client-side price calculation without server verification
  - Files: `app/controllers/**/*order*`, `app/controllers/**/*cart*`, `app/controllers/**/*checkout*`
- **Secure pattern:**
  ```ruby
  def create_order
    @order = Order.new(order_params)
    @order.line_items.each do |item|
      item.price = item.product.current_price  # Server-side price, ignore client
    end
    @order.total = @order.calculate_total  # Recalculate server-side
  end
  ```
- **Severity:** Critical

### EC-02: Inventory Race Conditions
- **What to check:** Inventory decremented atomically to prevent overselling
- **Detection patterns:**
  - Search: `decrement|update.*stock|update.*inventory` without locking
  - Search: `product\.stock -= 1` without database lock
  - Search: inventory check and decrement as separate operations
  - Files: `app/models/**/*product*`, `app/services/**/*order*`, `app/services/**/*checkout*`
- **Secure pattern:**
  ```ruby
  # Atomic decrement with lock
  Product.where(id: product_id).where('stock >= ?', quantity)
         .update_all(['stock = stock - ?', quantity])
  # Or pessimistic lock
  product.with_lock { product.update!(stock: product.stock - quantity) }
  ```
- **Severity:** High

### EC-03: Coupon/Discount Abuse
- **What to check:** Coupons validated server-side, single-use enforced
- **Detection patterns:**
  - Search: coupon application logic, discount calculation from params
  - Search: `coupon|discount|promo` in order/checkout controllers
  - Search: coupon stacking without limits
  - Search: `params\[:discount\]|params\[:coupon_code\]` applied without server validation
  - Files: `app/controllers/**/*cart*`, `app/controllers/**/*order*`, `app/models/**/*coupon*`
- **Secure pattern:**
  ```ruby
  def apply_coupon
    coupon = Coupon.find_by(code: params[:code])
    return render_error("Invalid coupon") unless coupon&.valid_for?(@order)
    return render_error("Already used") if coupon.used_by?(current_user)
    @order.apply_coupon(coupon)
  end
  ```
- **Severity:** High

### EC-04: Cart Manipulation
- **What to check:** Cart items validated against current prices at checkout
- **Detection patterns:**
  - Search: cart-to-order conversion logic
  - Search: `cart.*checkout|finalize.*cart` without price revalidation
  - Search: stale price in cart persisted to order
  - Files: `app/services/**/*checkout*`, `app/models/**/*cart*`
- **Secure pattern:**
  ```ruby
  def checkout
    @cart.items.each do |item|
      current_price = item.product.current_price
      if item.unit_price != current_price
        item.update!(unit_price: current_price)
        flash[:warning] = "Some prices have changed"
      end
    end
  end
  ```
- **Severity:** High

### EC-05: Payment Flow Integrity
- **What to check:** Payment amount matches order total, verified server-side
- **Detection patterns:**
  - Search: payment creation with amount from params vs calculated total
  - Search: `Stripe::Charge\.create.*amount.*params` (amount from client)
  - Search: payment amount != order total without reconciliation
  - Files: `app/services/**/*payment*`, `app/controllers/**/*checkout*`
- **Secure pattern:**
  ```ruby
  def create_payment
    order = current_user.orders.find(params[:order_id])
    # Always use server-calculated amount
    charge = Stripe::Charge.create(
      amount: order.total_cents,  # NOT params[:amount]
      currency: 'usd',
      source: params[:token]
    )
  end
  ```
- **Severity:** Critical
