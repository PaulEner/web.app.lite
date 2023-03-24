class PonctualScripts::CustomersToBill < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    @period         = 202205
    @current_period = 202206
    deactevated     = []

    users.each do |user|
      @user          = user
      @total_billing = 0

      logger_infos "Calculate : #{@user.code}"

      return false if not @user.can_be_billed?
      return false if @user.is_prescriber

      @package = @user.package_of(@period)

      return false if not @package

      BillingMod::FetchFlow.new(@period).execute(@user)
      @data_flow = @user.data_flows.of_period(@period).first

      return false if not @data_flow

      create_package_billing
      create_options_billing

      create_bank_excess_billing
      create_journals_excess_billing

      if @total_billing > 0
        extra_order = create_extra_order
        BillingMod::PrepareUserBilling.new(@user.reload, @current_period).execute
        next_billing = @user.reload.total_billing_of(@current_period)

        logger_infos "Creating extra order: #{@user.code} - #{@total_billing * 100} € - #{next_billing - (@total_billing * 100)} € - #{next_billing} €"
        deactevated << @user.code if next_billing == 0
      end
    end

    logger_infos "Deactevated : #{deactevated}"
  end

  def 

  def backup
    @current_period = 202206

    users.each do |user|
      extra_orders = user.extra_orders.of_period(@current_period)
      extra_orders.each{ |eo| eo.destroy }
    end
  end

  def users
    user_ids = [937, 2002, 2038, 2153, 2171, 2284, 3088, 3361, 3489, 4072, 4222, 4340, 4473, 4593, 4771, 4786, 5020, 5036, 5212, 5228, 5269, 5443, 5499, 5545, 5633, 5671, 5720, 5729, 5837, 5849, 5871, 5878, 5887, 5915, 5949, 5958, 5959, 5983, 5991, 5995, 6000, 6002, 6003, 6004, 6012, 6031, 6034, 6077, 6079, 6080, 6345, 6351, 6354, 6357, 6360, 6363, 6366, 6369, 6372, 6375, 6378, 6381, 6384, 6387, 6390, 6432, 6642, 6645, 6648, 6651, 6885, 6903, 7122, 7317, 7341, 7365, 7383, 7386, 7389, 7392, 7398, 7410, 7413, 7428, 7434, 7440, 7461, 7464, 7470, 7473, 7476, 7491, 7497, 7506, 7518, 7560, 7611, 7614, 7626, 7641, 7656, 7659, 7662, 7677, 7692, 7740, 7767, 7788, 7791, 7794, 7797, 7803, 7806, 7809, 7818, 7821, 7824, 7827, 7830, 7860, 7866, 7869, 7878, 7881, 7890, 7923, 7926, 7941, 7953, 7956, 7959, 8022, 8046, 8070, 8271, 8274, 8277, 8280, 8283, 8316, 8346, 8439, 8880, 8928, 8964, 9000, 9018, 9106, 9124, 9127, 9148, 9196, 9211, 9223, 9247, 9256, 9298, 9385, 9406, 9409, 9478, 9493, 9499, 9502, 9520, 9523, 9637, 9649, 9661, 9742, 9751, 9754, 9760, 9766, 9772, 9799, 9805, 9811, 9826, 9838, 9841, 9844]
    User.where(id: user_ids)
  end

  def create_package_billing
    return true if @package.name == 'ido_premium'

    create_billing({ name: @package.name, title: BillingMod::Configuration::LISTS[@package.name.to_sym][:label], price: @package.base_price })
  end

  def create_options_billing
    @package.options.each do |opt, val|
      next if val != 'optional'

      if opt.to_s == 'bank' && @package.bank_active
        create_billing({ name: 'bank_option', title: 'Option automate / Récupération bancaire', price: BillingMod::Configuration.price_of(:ido_retriever, @user) })
      elsif opt.to_s == 'mail' && @package.mail_active
        create_billing({ name: 'mail_option', title: 'Envoi par courrier A/R', price: BillingMod::Configuration.price_of(:mail) })
      elsif opt.to_s == 'preassignment' && !@package.preassignment_active
        create_billing({ name: 'preassignment_option', title: 'Remise sur pré-affectation', kind: 'discount', price: (BillingMod::Configuration.price_of(:preassignment) * -1) })
      end
    end
  end

  def create_bank_excess_billing
    if @data_flow.bank_excess > 0
      price   = BillingMod::Configuration.price_of(:bank_excess)
      create_billing({ name: 'bank_excess', title: "#{@data_flow.bank_excess} compte(s) bancaire(s) supplémentaire(s)", kind: 'excess', price: (price * @data_flow.bank_excess), associated_hash: { excess: @data_flow.bank_excess, price: price } })
    end
  end

  def create_journals_excess_billing
    if @data_flow.journal_excess > 0
      price   = BillingMod::Configuration.price_of(:journal_excess)

      create_billing({ name: 'journal_excess', title: "#{@data_flow.journal_excess} journal(aux) comptable(s) supplémentaire(s)", kind: 'excess', price: (price * @data_flow.journal_excess), associated_hash: { excess: @data_flow.journal_excess, price: price } })
    end
  end

  def create_billing(opt={})
    @total_billing += opt[:price]
  end

  def create_extra_order
    extra_order = @user.extra_orders.where(name: 'Rattrapage sur facturation : Mai').first || BillingMod::ExtraOrder.new

    extra_order.owner  = @user
    extra_order.period = @current_period
    extra_order.name   = 'Rattrapage sur facturation : Mai'
    extra_order.price  = @total_billing

    extra_order.save
  end
end