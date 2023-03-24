### VERIFY : MCF migration, Softwares migration

class PonctualScripts::MergeOrganizations < PonctualScripts::PonctualScript
  def self.execute(options={})
    new(options).run
  end

  def self.rollback(options={})
    new(options).rollback
  end

  private

  def execute
    #[IMPORTANT] : account number rules must be migrate before customer migration
    # migrate_accounts_rules  unless @options[:rules_only]
    # migrate_collaborators   unless @options[:collaborators_only]
    migrate_customers       unless @options[:customers_only]

    # migrate_mcf             unless @options[:mcf_only]
  end

  def backup
    # migrate_accounts_rules(true)  unless @options[:rules_only]
    # migrate_collaborators(true)   unless @options[:collaborators_only]
    migrate_customers(true)       unless @options[:customers_only]

    # migrate_mcf(true)             unless @options[:mcf_only]
  end

  def new_organization
    return @new_organization if @new_organization.present?

    @new_organization = Organization.find_by_code 'LER'
  end

  def organizations_hash
    return @organizations_hash if @organizations_hash.present?

    @organizations_hash = {
                            'BIN' => Organization.find_by_code('BIN').id,
                            # 'LER' => Organization.find_by_code('LER').id,
                          }
  end

  def ancient_organizations
    organizations_hash.map{|k, v| k}
  end

  def organizations_ids
    organizations_hash.map{|k, v| v}
  end

  def models
    [
      TempDocument, TempPack, Pack, Pack::Piece, Pack::Report, Pack::Report::Preseizure, Pack::Report::Expense, Operation, AccountBookType, CedricomReception, CsvDescriptor,
      PaperProcess, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, Order
    ]
  end

  def previous_org_of(user)
    org_code  = user.my_code.split('%')[0]
    organizations_hash[org_code.strip.to_s].to_i
  end

  def migrate_customers(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    #[IMPORTANT] : suspend organization after customers migration OR re-save organizations groups after customers migration (from plateforme website)
    did_rollback = false

    ancient_organizations.each do |code|
      next if did_rollback

      organization = Organization.find_by_code code
      curr_org_id  = rollback ? new_organization.id : organization.id

      customers = User.unscoped.where(organization_id: curr_org_id, is_prescriber: false)
      next_id   = new_organization.id

      customers.each do |user|
        current_org  = user.organization_id
        next_id      = previous_org_of(user) if rollback

        logger_infos("Can't rollback user : #{user.id} - #{user.my_code}") if rollback && next_id <= 0

        if(!rollback || (rollback && next_id > 0))
          logger_infos("======================= START - #{user.my_code} - org: #{current_org} ======================")

          models.each do |mod|
            _last = mod.unscoped.last
            next if not _last

            _respond_to_org  = _last.respond_to?(:organization_id)
            _respond_to_user = _last.respond_to?(:user_id) || _last.respond_to?(:owner_id)

            if _respond_to_user && _respond_to_org && next_id > 0
              if mod.to_s == 'Pack'
                datas = mod.unscoped.where(owner_id: user.id)
              else
                datas = mod.unscoped.where(user_id: user.id)
              end

              logger_infos("Migration #{mod.to_s} : #{datas.size.to_s} : #{user.id.to_s} - #{user.my_code.to_s} from => #{current_org.to_s} to => #{next_id.to_s}")

              datas.each do |data|
                data.update(organization_id: next_id) if data.organization_id.present?
              end
            end
          end

          logger_infos("======================= END - #{user.my_code} - to : #{next_id} ======================")
          user.organization_id = next_id if next_id > 0
          user.save

          #ASSIGN ALL MIGRATED CUSTOMERS TO NEW SPECIFIC GROUP
          ## Re-Save group from platform if rollback is needed after rollbacking customers
          assign_to_group(user) if not rollback
        end
      end

      new_group.try(:save) if not rollback
      did_rollback = true if rollback
    end
  end

  def migrate_collaborators(rollback = false)
    if rollback
      members = Member.where(organization_id: new_organization.id)
      members.each(&:destroy)
    else
      members = Member.where(organization_id: organizations_ids).select(:user_id).distinct

      collaborators = User.where(id: members.collect(&:user_id))

      collaborators.each do |user|
        next if user.memberships.where(organization_id: new_organization.id).first

        member = user.memberships.first

        if !member
          logger_infos("======================= NO MEMBER - #{user.id} - #{user.email} ======================")
          next
        end

        logger_infos("======================= START - #{user.id} - #{member.code} ======================")

        user_code = member.code.split('%')[1].strip

        clone_member                  = member.dup
        clone_member.code             = "#{new_organization.code}%#{user_code.to_s}"
        clone_member.organization_id  = new_organization.id

        clone_member.save

        logger_infos("======================= END - #{user.id} - #{clone_member.code} ======================")
      end
    end
  end

  def migrate_accounts_rules(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    if rollback
      organization         = Organization.find new_organization.id
      account_number_rules = organization.account_number_rules
      account_number_rules.each(&:destroy)
    else
      ancient_organizations.each do |org|
        organization  = Organization.find_by_code org
        account_rules = organization.account_number_rules

        logger_infos("======================= START - Org - #{organization.code} - rules : #{account_rules.size} ======================")
        account_rules.each do |rule|
          new_rule                 = rule.dup
          new_rule.organization_id = new_organization.id
          if rule.users.any?
            new_rule.users = rule.users
          # else
          #   new_rule.users = organization.customers.active
          end

          new_rule.save
        end
        logger_infos("======================= END - Org - #{organization.code} ======================")
      end
    end
  end

  def new_group
    return @new_group if @new_group

    @new_group = new_organization.groups.where(name: 'BINERGY').first
  end

  def assign_to_group(user)
    return false if not new_group

    c_group = user.groups.where(id: new_group.id).first
    return false if c_group

    new_group.customers << user
  end

  # def migrate_mcf(rollback = false)
  #   if rollback
  #     mcf = Organization.find_by_code('EXT').mcf_settings
  #     mcf.organization_id = organizations_hash['FIDA'] if mcf
  #   else
  #     mcf = Organization.find_by_code('FIDA').mcf_settings
  #     mcf.organization_id = new_organization.id if mcf
  #   end

  #   mcf.save
  # end
end