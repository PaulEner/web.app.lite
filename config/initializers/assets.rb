# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
# Dir[Rails.root.join("app/templates/front/*/assets")].each do |f|
#   Rails.application.config.assets.paths << f
# end

Rails.application.config.assets.paths << Rails.root.join("app/templates")
Rails.application.config.assets.paths << Rails.root.join('node_modules')

Rails.application.config.assets.precompile += %w( ckeditor/* )
Rails.application.config.assets.precompile += %w( front/main.css front/organization_lefter_orial.css front/main_orial.css front/main_axelium.css front/organization_lefter.css front/organization_lefter_axelium.css back/main.css front/organization_lefter_dk_partners.css front/main_dk_partners.css front/main_censial.css front/organization_lefter_censial.css )
Rails.application.config.assets.precompile += %w( front/router.js front/main.js front/organization_lefter.js back/main.js )

Dir[Rails.root.join("app/templates/front/*/assets/javascripts/*")].each do |f|
  Rails.application.config.assets.precompile += [f]
end

Dir[Rails.root.join("app/templates/front/*/assets/stylesheets/*")].each do |f|
  Rails.application.config.assets.precompile += [f]
end

Dir[Rails.root.join("app/templates/back/*/assets/javascripts/*")].each do |f|
  Rails.application.config.assets.precompile += [f]
end

Dir[Rails.root.join("app/templates/back/*/assets/stylesheets/*")].each do |f|
  Rails.application.config.assets.precompile += [f]
end

###================== TO DELETE ===============
Rails.application.config.assets.precompile += %w( admin.css admin/events.css admin/groups.css admin/invoices.css admin/journals.css admin/mobile_reponring.css
                                                  admin/notification_settings.css admin/pre_assignment_blocked_duplicates.css admin/pre_assignment_delivery.css
                                                  admin/process_reporting.css admin/retrievers.css admin/retriever_services.css admin/reporting.css admin/scanning_providers.css admin/subscriptions.css admin/budgea_retriever.css)

Rails.application.config.assets.precompile += %w( ppp/base.css ppp/kits.css ppp/paper_process.css ppp/receipts.css ppp/returns.css ppp/scans.css)

Rails.application.config.assets.precompile += %w( admin.js admin/admin.js admin/events.js admin/group_organizations.js admin/invoices.js admin/mobile_reporting.js admin/news.js admin/pre_assignment_blocked_duplicates.js
                                                  admin/reporting.js admin/scanning_providers.js admin/subscriptions.js admin/user.js admin/retriever_services.js admin/job_processing.js admin/budgea_retriever.js admin/counter_error_script_mailer.js admin/process_reporting.js admin/archives.js )


Rails.application.config.assets.precompile += %w( ppp/paper_process.js inner.js welcome.js )
###================== TO DELETE ===============             

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
