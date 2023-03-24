# -*- encoding : UTF-8 -*-
class Order::PaperSet
  def initialize(user, order, is_an_update = false)
    @user         = user
    @order        = order
    # @period       = user.subscription.current_period
    @is_an_update = is_an_update
  end

  def execute
    @order.user ||= @user
    @order.organization ||= @user.organization
    @order.period_duration = 1
    @order.price_in_cents_wo_vat = price_in_cents_wo_vat
    @order.address.is_for_paper_set_shipping = true if @order.address

    # return false if @order.period_duration == 3

    if @order.save
      unless @is_an_update
        # @period.orders << @order

        if @order.normal_paper_set_order?
          Order::Confirm.delay_for(24.hours, queue: :high).execute(@order.id)
        else
          if @order.pending?
            @order.period_v2 = CustomUtils.period_of(Time.now)
            @order.confirm

            @order.save
          end
        end
      end

      auto_ajust_number_of_journals_authorized

      # Billing::UpdatePeriod.new(@period).execute

      true
    else
      false
    end
  end

  def self.paper_set_prices
    [
      [
        [28, 38, 47, 56, 65, 74, 83, 92, 101, 110, 119, 128, 140, 149, 158, 167, 176, 185, 194, 204, 213, 222, 231, 240],
        [29, 38, 47, 56, 65, 74, 83, 93, 102, 111, 123, 132, 141, 150, 159, 169, 178, 187, 196, 205, 214, 223, 233, 242],
        [29, 38, 47, 56, 66, 75, 84, 93, 102, 115, 124, 133, 142, 151, 161, 170, 179, 188, 198, 207, 216, 225, 234, 244],
        [29, 38, 47, 57, 66, 75, 85, 94, 106, 115, 125, 134, 143, 153, 162, 171, 181, 190, 199, 208, 218, 227, 236, 246],
        [29, 38, 48, 57, 66, 76, 85, 97, 107, 116, 126, 135, 144, 154, 163, 172, 182, 191, 201, 210, 219, 229, 238, 248],
        [29, 38, 48, 57, 67, 76, 89, 98, 108, 117, 126, 136, 145, 155, 164, 174, 183, 193, 202, 212, 221, 231, 240, 249]
      ],
      [
        [33, 46, 58, 70, 82, 95, 107, 119, 131, 144, 156, 168, 184, 196, 208, 220, 233, 245, 257, 269, 281, 294, 306, 318],
        [33, 46, 58, 70, 83, 95, 107, 120, 132, 144, 160, 172, 185, 197, 209, 222, 234, 246, 259, 271, 283, 296, 308, 320],
        [34, 46, 58, 71, 83, 96, 108, 121, 133, 149, 161, 173, 186, 198, 211, 223, 236, 248, 260, 273, 285, 298, 310, 322],
        [34, 46, 59, 71, 84, 96, 109, 121, 137, 149, 162, 174, 187, 199, 212, 224, 237, 250, 262, 275, 287, 300, 312, 325],
        [34, 46, 59, 72, 84, 97, 109, 125, 138, 150, 163, 176, 188, 201, 213, 226, 238, 251, 264, 276, 289, 301, 314, 327],
        [34, 47, 59, 72, 85, 97, 113, 126, 139, 151, 164, 177, 189, 202, 215, 227, 240, 253, 265, 278, 291, 303, 316, 329]
      ],
      [
        [35, 49, 64, 79, 94, 108, 123, 138, 152, 167, 182, 196, 214, 229, 243, 258, 273, 288, 302, 317, 332, 346, 361, 376],
        [35, 50, 64, 79, 94, 109, 124, 138, 153, 168, 186, 200, 215, 230, 245, 259, 274, 289, 304, 319, 333, 348, 363, 378],
        [35, 50, 65, 80, 94, 109, 124, 139, 154, 172, 187, 201, 216, 231, 246, 261, 276, 291, 305, 320, 335, 350, 365, 380],
        [35, 50, 65, 80, 95, 110, 125, 140, 158, 173, 187, 202, 217, 232, 247, 262, 277, 292, 307, 322, 337, 352, 367, 382],
        [35, 50, 65, 80, 95, 110, 125, 143, 158, 173, 188, 203, 218, 233, 248, 264, 279, 294, 309, 324, 339, 354, 369, 384],
        [35, 50, 65, 81, 96, 111, 129, 144, 159, 174, 189, 204, 220, 235, 250, 265, 280, 295, 310, 325, 340, 355, 371, 386]
      ]
    ]
  end

  private

  def price_in_cents_wo_vat
    discount_price * 100
  end


  def periods_count
    count = 0

    date = @order.paper_set_start_date

    while date <= @order.paper_set_end_date
      count += 1

      date += @order.period_duration.month
    end

    count
  end


  def casing_size_index
    return 0 # TODO...

    case @order.paper_set_casing_size
    when 500
      0
    when 1000
      1
    when 3000
      2
    end
  end


  def folder_count_index
    @order.paper_set_folder_count - 5
  end


  def price_of_periods
    Order::PaperSet.paper_set_prices[casing_size_index][folder_count_index][periods_count - 1]
  end


  def discount_price
    unit_price = 0
    selected_casing_count = @order.paper_set_casing_count
    max_casing_count = periods_count

    case casing_size_index
      when 0
        unit_price = 6
      when 1
        unit_price = 9
      when 2
        unit_price = 12
      else
        unit_price = 0
    end

    if @order.normal_paper_set_order?
      if selected_casing_count && selected_casing_count > 0 && max_casing_count > 0
        discount_price = unit_price * (max_casing_count - selected_casing_count)
        price_of_periods - discount_price
      else
        price_of_periods
      end
    else # When organization applied manuel paper set order
      (@order.paper_set_folder_count * periods_count) * 0 #No price for manual kit generation
    end
  end

  def auto_ajust_number_of_journals_authorized
    my_package = @user.my_package

    if @order.paper_set_folder_count != my_package.journal_size && @order.paper_set_folder_count >= @user.account_book_types.count
      my_package.journal_size = @order.paper_set_folder_count
      my_package.save
    end
  end
end
