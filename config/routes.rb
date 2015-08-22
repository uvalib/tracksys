Tracksys::Application.routes.draw do
  root :to => 'requests#index'

  match '/request' => redirect('/')

  resources :requests do
    collection do
      get 'agree_to_copyright'
      get 'details'
      get 'public'
      get 'thank_you'
      get 'uva'
    end
  end
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
#== Route Map
# Generated on 21 Aug 2015 21:00
#
#                                                        request            /request(.:format)                                                        :controller#:action
#                                    agree_to_copyright_requests GET        /requests/agree_to_copyright(.:format)                                    requests#agree_to_copyright
#                                               details_requests GET        /requests/details(.:format)                                               requests#details
#                                                public_requests GET        /requests/public(.:format)                                                requests#public
#                                             thank_you_requests GET        /requests/thank_you(.:format)                                             requests#thank_you
#                                                   uva_requests GET        /requests/uva(.:format)                                                   requests#uva
#                                                       requests GET        /requests(.:format)                                                       requests#index
#                                                                POST       /requests(.:format)                                                       requests#create
#                                                    new_request GET        /requests/new(.:format)                                                   requests#new
#                                                   edit_request GET        /requests/:id/edit(.:format)                                              requests#edit
#                                                                GET        /requests/:id(.:format)                                                   requests#show
#                                                                PUT        /requests/:id(.:format)                                                   requests#update
#                                                                DELETE     /requests/:id(.:format)                                                   requests#destroy
#                                                     admin_root            /admin(.:format)                                                          admin/dashboard#index
#                                                    patron_root            /patron(.:format)                                                         patron/dashboard#index
#                                                           root            /                                                                         dashboard#index
#                           batch_action_admin_academic_statuses POST       /admin/academic_statuses/batch_action(.:format)                           admin/academic_statuses#batch_action
#                                        admin_academic_statuses GET        /admin/academic_statuses(.:format)                                        admin/academic_statuses#index
#                                                                POST       /admin/academic_statuses(.:format)                                        admin/academic_statuses#create
#                                      new_admin_academic_status GET        /admin/academic_statuses/new(.:format)                                    admin/academic_statuses#new
#                                     edit_admin_academic_status GET        /admin/academic_statuses/:id/edit(.:format)                               admin/academic_statuses#edit
#                                          admin_academic_status GET        /admin/academic_statuses/:id(.:format)                                    admin/academic_statuses#show
#                                                                PUT        /admin/academic_statuses/:id(.:format)                                    admin/academic_statuses#update
#                                    batch_action_admin_agencies POST       /admin/agencies/batch_action(.:format)                                    admin/agencies#batch_action
#                                                 admin_agencies GET        /admin/agencies(.:format)                                                 admin/agencies#index
#                                                                POST       /admin/agencies(.:format)                                                 admin/agencies#create
#                                               new_admin_agency GET        /admin/agencies/new(.:format)                                             admin/agencies#new
#                                              edit_admin_agency GET        /admin/agencies/:id/edit(.:format)                                        admin/agencies#edit
#                                                   admin_agency GET        /admin/agencies/:id(.:format)                                             admin/agencies#show
#                                                                PUT        /admin/agencies/:id(.:format)                                             admin/agencies#update
#                                    batch_action_admin_archives POST       /admin/archives/batch_action(.:format)                                    admin/archives#batch_action
#                                                 admin_archives GET        /admin/archives(.:format)                                                 admin/archives#index
#                                                                POST       /admin/archives(.:format)                                                 admin/archives#create
#                                              new_admin_archive GET        /admin/archives/new(.:format)                                             admin/archives#new
#                                             edit_admin_archive GET        /admin/archives/:id/edit(.:format)                                        admin/archives#edit
#                                                  admin_archive GET        /admin/archives/:id(.:format)                                             admin/archives#show
#                                                                PUT        /admin/archives/:id(.:format)                                             admin/archives#update
#                         batch_action_admin_automation_messages POST       /admin/automation_messages/batch_action(.:format)                         admin/automation_messages#batch_action
#                                      admin_automation_messages GET        /admin/automation_messages(.:format)                                      admin/automation_messages#index
#                                                                POST       /admin/automation_messages(.:format)                                      admin/automation_messages#create
#                                  edit_admin_automation_message GET        /admin/automation_messages/:id/edit(.:format)                             admin/automation_messages#edit
#                                       admin_automation_message GET        /admin/automation_messages/:id(.:format)                                  admin/automation_messages#show
#                                                                PUT        /admin/automation_messages/:id(.:format)                                  admin/automation_messages#update
#                                                                DELETE     /admin/automation_messages/:id(.:format)                                  admin/automation_messages#destroy
#                       batch_action_admin_availability_policies POST       /admin/availability_policies/batch_action(.:format)                       admin/availability_policies#batch_action
#                                    admin_availability_policies GET        /admin/availability_policies(.:format)                                    admin/availability_policies#index
#                                                                POST       /admin/availability_policies(.:format)                                    admin/availability_policies#create
#                                  new_admin_availability_policy GET        /admin/availability_policies/new(.:format)                                admin/availability_policies#new
#                                 edit_admin_availability_policy GET        /admin/availability_policies/:id/edit(.:format)                           admin/availability_policies#edit
#                                      admin_availability_policy GET        /admin/availability_policies/:id(.:format)                                admin/availability_policies#show
#                                                                PUT        /admin/availability_policies/:id(.:format)                                admin/availability_policies#update
#                                     update_metadata_admin_bibl PUT        /admin/bibls/:id/update_metadata(.:format)                                admin/bibls#update_metadata
#                                update_all_solr_docs_admin_bibl GET        /admin/bibls/:id/update_all_solr_docs(.:format)                           admin/bibls#update_all_solr_docs
#                                    external_lookup_admin_bibls GET        /admin/bibls/external_lookup(.:format)                                    admin/bibls#external_lookup
#                                 create_dl_manifest_admin_bibls GET        /admin/bibls/create_dl_manifest(.:format)                                 admin/bibls#create_dl_manifest
#                                       batch_action_admin_bibls POST       /admin/bibls/batch_action(.:format)                                       admin/bibls#batch_action
#                                                    admin_bibls GET        /admin/bibls(.:format)                                                    admin/bibls#index
#                                                                POST       /admin/bibls(.:format)                                                    admin/bibls#create
#                                                 new_admin_bibl GET        /admin/bibls/new(.:format)                                                admin/bibls#new
#                                                edit_admin_bibl GET        /admin/bibls/:id/edit(.:format)                                           admin/bibls#edit
#                                                     admin_bibl GET        /admin/bibls/:id(.:format)                                                admin/bibls#show
#                                                                PUT        /admin/bibls/:id(.:format)                                                admin/bibls#update
#                                                                DELETE     /admin/bibls/:id(.:format)                                                admin/bibls#destroy
#                                   export_iview_admin_component PUT        /admin/components/:id/export_iview(.:format)                              admin/components#export_iview
#                                update_metadata_admin_component PUT        /admin/components/:id/update_metadata(.:format)                           admin/components#update_metadata
#                           update_all_solr_docs_admin_component GET        /admin/components/:id/update_all_solr_docs(.:format)                      admin/components#update_all_solr_docs
#                                           tree_admin_component GET        /admin/components/:id/tree(.:format)                                      admin/components#tree
#                                  batch_action_admin_components POST       /admin/components/batch_action(.:format)                                  admin/components#batch_action
#                                               admin_components GET        /admin/components(.:format)                                               admin/components#index
#                                                                POST       /admin/components(.:format)                                               admin/components#create
#                                            new_admin_component GET        /admin/components/new(.:format)                                           admin/components#new
#                                           edit_admin_component GET        /admin/components/:id/edit(.:format)                                      admin/components#edit
#                                                admin_component GET        /admin/components/:id(.:format)                                           admin/components#show
#                                                                PUT        /admin/components/:id(.:format)                                           admin/components#update
#                                   batch_action_admin_customers POST       /admin/customers/batch_action(.:format)                                   admin/customers#batch_action
#                                                admin_customers GET        /admin/customers(.:format)                                                admin/customers#index
#                                                                POST       /admin/customers(.:format)                                                admin/customers#create
#                                             new_admin_customer GET        /admin/customers/new(.:format)                                            admin/customers#new
#                                            edit_admin_customer GET        /admin/customers/:id/edit(.:format)                                       admin/customers#edit
#                                                 admin_customer GET        /admin/customers/:id(.:format)                                            admin/customers#show
#                                                                PUT        /admin/customers/:id(.:format)                                            admin/customers#update
#                                                admin_dashboard            /admin/dashboard(.:format)                                                admin/dashboard#index
#                               admin_dashboard_get_yearly_stats GET        /admin/dashboard/get_yearly_stats(.:format)                               admin/dashboard#get_yearly_stats
#                     admin_dashboard_push_staging_to_production GET        /admin/dashboard/push_staging_to_production(.:format)                     admin/dashboard#push_staging_to_production
#                  admin_dashboard_start_finalization_production GET        /admin/dashboard/start_finalization_production(.:format)                  admin/dashboard#start_finalization_production
#                   admin_dashboard_start_finalization_migration GET        /admin/dashboard/start_finalization_migration(.:format)                   admin/dashboard#start_finalization_migration
# admin_dashboard_start_manual_upload_to_archive_batch_migration GET        /admin/dashboard/start_manual_upload_to_archive_batch_migration(.:format) admin/dashboard#start_manual_upload_to_archive_batch_migration
#      admin_dashboard_start_manual_upload_to_archive_production GET        /admin/dashboard/start_manual_upload_to_archive_production(.:format)      admin/dashboard#start_manual_upload_to_archive_production
#       admin_dashboard_start_manual_upload_to_archive_migration GET        /admin/dashboard/start_manual_upload_to_archive_migration(.:format)       admin/dashboard#start_manual_upload_to_archive_migration
#                           admin_dashboard_update_all_solr_docs GET        /admin/dashboard/update_all_solr_docs(.:format)                           admin/dashboard#update_all_solr_docs
#                                 batch_action_admin_departments POST       /admin/departments/batch_action(.:format)                                 admin/departments#batch_action
#                                              admin_departments GET        /admin/departments(.:format)                                              admin/departments#index
#                                                                POST       /admin/departments(.:format)                                              admin/departments#create
#                                           new_admin_department GET        /admin/departments/new(.:format)                                          admin/departments#new
#                                          edit_admin_department GET        /admin/departments/:id/edit(.:format)                                     admin/departments#edit
#                                               admin_department GET        /admin/departments/:id(.:format)                                          admin/departments#show
#                                                                PUT        /admin/departments/:id(.:format)                                          admin/departments#update
#                      batch_action_admin_dvd_delivery_locations POST       /admin/dvd_delivery_locations/batch_action(.:format)                      admin/dvd_delivery_locations#batch_action
#                                   admin_dvd_delivery_locations GET        /admin/dvd_delivery_locations(.:format)                                   admin/dvd_delivery_locations#index
#                                                                POST       /admin/dvd_delivery_locations(.:format)                                   admin/dvd_delivery_locations#create
#                                new_admin_dvd_delivery_location GET        /admin/dvd_delivery_locations/new(.:format)                               admin/dvd_delivery_locations#new
#                               edit_admin_dvd_delivery_location GET        /admin/dvd_delivery_locations/:id/edit(.:format)                          admin/dvd_delivery_locations#edit
#                                    admin_dvd_delivery_location GET        /admin/dvd_delivery_locations/:id(.:format)                               admin/dvd_delivery_locations#show
#                                                                PUT        /admin/dvd_delivery_locations/:id(.:format)                               admin/dvd_delivery_locations#update
#                                                                DELETE     /admin/dvd_delivery_locations/:id(.:format)                               admin/dvd_delivery_locations#destroy
#                       batch_action_admin_heard_about_resources POST       /admin/heard_about_resources/batch_action(.:format)                       admin/heard_about_resources#batch_action
#                                    admin_heard_about_resources GET        /admin/heard_about_resources(.:format)                                    admin/heard_about_resources#index
#                                                                POST       /admin/heard_about_resources(.:format)                                    admin/heard_about_resources#create
#                                 new_admin_heard_about_resource GET        /admin/heard_about_resources/new(.:format)                                admin/heard_about_resources#new
#                                edit_admin_heard_about_resource GET        /admin/heard_about_resources/:id/edit(.:format)                           admin/heard_about_resources#edit
#                                     admin_heard_about_resource GET        /admin/heard_about_resources/:id(.:format)                                admin/heard_about_resources#show
#                                                                PUT        /admin/heard_about_resources/:id(.:format)                                admin/heard_about_resources#update
#                        batch_action_admin_heard_about_services POST       /admin/heard_about_services/batch_action(.:format)                        admin/heard_about_services#batch_action
#                                     admin_heard_about_services GET        /admin/heard_about_services(.:format)                                     admin/heard_about_services#index
#                                                                POST       /admin/heard_about_services(.:format)                                     admin/heard_about_services#create
#                                  new_admin_heard_about_service GET        /admin/heard_about_services/new(.:format)                                 admin/heard_about_services#new
#                                 edit_admin_heard_about_service GET        /admin/heard_about_services/:id/edit(.:format)                            admin/heard_about_services#edit
#                                      admin_heard_about_service GET        /admin/heard_about_services/:id(.:format)                                 admin/heard_about_services#show
#                                                                PUT        /admin/heard_about_services/:id(.:format)                                 admin/heard_about_services#update
#                          batch_action_admin_index_destinations POST       /admin/index_destinations/batch_action(.:format)                          admin/index_destinations#batch_action
#                                       admin_index_destinations GET        /admin/index_destinations(.:format)                                       admin/index_destinations#index
#                                                                POST       /admin/index_destinations(.:format)                                       admin/index_destinations#create
#                                    new_admin_index_destination GET        /admin/index_destinations/new(.:format)                                   admin/index_destinations#new
#                                   edit_admin_index_destination GET        /admin/index_destinations/:id/edit(.:format)                              admin/index_destinations#edit
#                                        admin_index_destination GET        /admin/index_destinations/:id(.:format)                                   admin/index_destinations#show
#                                                                PUT        /admin/index_destinations/:id(.:format)                                   admin/index_destinations#update
#                          batch_action_admin_indexing_scenarios POST       /admin/indexing_scenarios/batch_action(.:format)                          admin/indexing_scenarios#batch_action
#                                       admin_indexing_scenarios GET        /admin/indexing_scenarios(.:format)                                       admin/indexing_scenarios#index
#                                                                POST       /admin/indexing_scenarios(.:format)                                       admin/indexing_scenarios#create
#                                    new_admin_indexing_scenario GET        /admin/indexing_scenarios/new(.:format)                                   admin/indexing_scenarios#new
#                                   edit_admin_indexing_scenario GET        /admin/indexing_scenarios/:id/edit(.:format)                              admin/indexing_scenarios#edit
#                                        admin_indexing_scenario GET        /admin/indexing_scenarios/:id(.:format)                                   admin/indexing_scenarios#show
#                                                                PUT        /admin/indexing_scenarios/:id(.:format)                                   admin/indexing_scenarios#update
#                               batch_action_admin_intended_uses POST       /admin/intended_uses/batch_action(.:format)                               admin/intended_uses#batch_action
#                                            admin_intended_uses GET        /admin/intended_uses(.:format)                                            admin/intended_uses#index
#                                                                POST       /admin/intended_uses(.:format)                                            admin/intended_uses#create
#                                         new_admin_intended_use GET        /admin/intended_uses/new(.:format)                                        admin/intended_uses#new
#                                        edit_admin_intended_use GET        /admin/intended_uses/:id/edit(.:format)                                   admin/intended_uses#edit
#                                             admin_intended_use GET        /admin/intended_uses/:id(.:format)                                        admin/intended_uses#show
#                                                                PUT        /admin/intended_uses/:id(.:format)                                        admin/intended_uses#update
#                                          get_pdf_admin_invoice GET        /admin/invoices/:id/get_pdf(.:format)                                     admin/invoices#get_pdf
#                                    batch_action_admin_invoices POST       /admin/invoices/batch_action(.:format)                                    admin/invoices#batch_action
#                                                 admin_invoices GET        /admin/invoices(.:format)                                                 admin/invoices#index
#                                                                POST       /admin/invoices(.:format)                                                 admin/invoices#create
#                                              new_admin_invoice GET        /admin/invoices/new(.:format)                                             admin/invoices#new
#                                             edit_admin_invoice GET        /admin/invoices/:id/edit(.:format)                                        admin/invoices#edit
#                                                  admin_invoice GET        /admin/invoices/:id(.:format)                                             admin/invoices#show
#                                                                PUT        /admin/invoices/:id(.:format)                                             admin/invoices#update
#                                                                DELETE     /admin/invoices/:id(.:format)                                             admin/invoices#destroy
#                          batch_action_admin_legacy_identifiers POST       /admin/legacy_identifiers/batch_action(.:format)                          admin/legacy_identifiers#batch_action
#                                       admin_legacy_identifiers GET        /admin/legacy_identifiers(.:format)                                       admin/legacy_identifiers#index
#                                                                POST       /admin/legacy_identifiers(.:format)                                       admin/legacy_identifiers#create
#                                   edit_admin_legacy_identifier GET        /admin/legacy_identifiers/:id/edit(.:format)                              admin/legacy_identifiers#edit
#                                        admin_legacy_identifier GET        /admin/legacy_identifiers/:id(.:format)                                   admin/legacy_identifiers#show
#                                                                PUT        /admin/legacy_identifiers/:id(.:format)                                   admin/legacy_identifiers#update
#                            copy_from_archive_admin_master_file PUT        /admin/master_files/:id/copy_from_archive(.:format)                       admin/master_files#copy_from_archive
#                                  print_image_admin_master_file PUT        /admin/master_files/:id/print_image(.:format)                             admin/master_files#print_image
#                              update_metadata_admin_master_file PUT        /admin/master_files/:id/update_metadata(.:format)                         admin/master_files#update_metadata
#                                         mods_admin_master_file GET        /admin/master_files/:id/mods(.:format)                                    admin/master_files#mods
#                                         solr_admin_master_file GET        /admin/master_files/:id/solr(.:format)                                    admin/master_files#solr
#                                batch_action_admin_master_files POST       /admin/master_files/batch_action(.:format)                                admin/master_files#batch_action
#                                             admin_master_files GET        /admin/master_files(.:format)                                             admin/master_files#index
#                                                                POST       /admin/master_files(.:format)                                             admin/master_files#create
#                                         edit_admin_master_file GET        /admin/master_files/:id/edit(.:format)                                    admin/master_files#edit
#                                              admin_master_file GET        /admin/master_files/:id(.:format)                                         admin/master_files#show
#                                                                PUT        /admin/master_files/:id(.:format)                                         admin/master_files#update
#                                      approve_order_admin_order PUT        /admin/orders/:id/approve_order(.:format)                                 admin/orders#approve_order
#                                       cancel_order_admin_order PUT        /admin/orders/:id/cancel_order(.:format)                                  admin/orders#cancel_order
#                      send_fee_estimate_to_customer_admin_order PUT        /admin/orders/:id/send_fee_estimate_to_customer(.:format)                 admin/orders#send_fee_estimate_to_customer
#                     check_order_ready_for_delivery_admin_order PUT        /admin/orders/:id/check_order_ready_for_delivery(.:format)                admin/orders#check_order_ready_for_delivery
#                                   send_order_email_admin_order PUT        /admin/orders/:id/send_order_email(.:format)                              admin/orders#send_order_email
#                                generate_pdf_notice_admin_order PUT        /admin/orders/:id/generate_pdf_notice(.:format)                           admin/orders#generate_pdf_notice
#                                      batch_action_admin_orders POST       /admin/orders/batch_action(.:format)                                      admin/orders#batch_action
#                                                   admin_orders GET        /admin/orders(.:format)                                                   admin/orders#index
#                                                                POST       /admin/orders(.:format)                                                   admin/orders#create
#                                                new_admin_order GET        /admin/orders/new(.:format)                                               admin/orders#new
#                                               edit_admin_order GET        /admin/orders/:id/edit(.:format)                                          admin/orders#edit
#                                                    admin_order GET        /admin/orders/:id(.:format)                                               admin/orders#show
#                                                                PUT        /admin/orders/:id(.:format)                                               admin/orders#update
#                                 batch_action_admin_sql_reports POST       /admin/sql_reports/batch_action(.:format)                                 admin/sql_reports#batch_action
#                                              admin_sql_reports GET        /admin/sql_reports(.:format)                                              admin/sql_reports#index
#                                                                POST       /admin/sql_reports(.:format)                                              admin/sql_reports#create
#                                           new_admin_sql_report GET        /admin/sql_reports/new(.:format)                                          admin/sql_reports#new
#                                          edit_admin_sql_report GET        /admin/sql_reports/:id/edit(.:format)                                     admin/sql_reports#edit
#                                               admin_sql_report GET        /admin/sql_reports/:id(.:format)                                          admin/sql_reports#show
#                                                                PUT        /admin/sql_reports/:id(.:format)                                          admin/sql_reports#update
#                                                                DELETE     /admin/sql_reports/:id(.:format)                                          admin/sql_reports#destroy
#                               batch_action_admin_staff_members POST       /admin/staff_members/batch_action(.:format)                               admin/staff_members#batch_action
#                                            admin_staff_members GET        /admin/staff_members(.:format)                                            admin/staff_members#index
#                                                                POST       /admin/staff_members(.:format)                                            admin/staff_members#create
#                                         new_admin_staff_member GET        /admin/staff_members/new(.:format)                                        admin/staff_members#new
#                                        edit_admin_staff_member GET        /admin/staff_members/:id/edit(.:format)                                   admin/staff_members#edit
#                                             admin_staff_member GET        /admin/staff_members/:id(.:format)                                        admin/staff_members#show
#                                                                PUT        /admin/staff_members/:id(.:format)                                        admin/staff_members#update
#                                                                DELETE     /admin/staff_members/:id(.:format)                                        admin/staff_members#destroy
#                         batch_action_admin_unit_import_sources POST       /admin/unit_import_sources/batch_action(.:format)                         admin/unit_import_sources#batch_action
#                                      admin_unit_import_sources GET        /admin/unit_import_sources(.:format)                                      admin/unit_import_sources#index
#                                                                POST       /admin/unit_import_sources(.:format)                                      admin/unit_import_sources#create
#                                   new_admin_unit_import_source GET        /admin/unit_import_sources/new(.:format)                                  admin/unit_import_sources#new
#                                  edit_admin_unit_import_source GET        /admin/unit_import_sources/:id/edit(.:format)                             admin/unit_import_sources#edit
#                                       admin_unit_import_source GET        /admin/unit_import_sources/:id(.:format)                                  admin/unit_import_sources#show
#                                                                PUT        /admin/unit_import_sources/:id(.:format)                                  admin/unit_import_sources#update
#                                                                DELETE     /admin/unit_import_sources/:id(.:format)                                  admin/unit_import_sources#destroy
#                                  print_routing_slip_admin_unit PUT        /admin/units/:id/print_routing_slip(.:format)                             admin/units#print_routing_slip
#                            check_unit_delivery_mode_admin_unit PUT        /admin/units/:id/check_unit_delivery_mode(.:format)                       admin/units#check_unit_delivery_mode
#                                   copy_from_archive_admin_unit PUT        /admin/units/:id/copy_from_archive(.:format)                              admin/units#copy_from_archive
#                               import_unit_iview_xml_admin_unit PUT        /admin/units/:id/import_unit_iview_xml(.:format)                          admin/units#import_unit_iview_xml
#                         qa_filesystem_and_iview_xml_admin_unit PUT        /admin/units/:id/qa_filesystem_and_iview_xml(.:format)                    admin/units#qa_filesystem_and_iview_xml
#                                        qa_unit_data_admin_unit PUT        /admin/units/:id/qa_unit_data(.:format)                                   admin/units#qa_unit_data
#                                send_unit_to_archive_admin_unit PUT        /admin/units/:id/send_unit_to_archive(.:format)                           admin/units#send_unit_to_archive
#                           start_ingest_from_archive_admin_unit PUT        /admin/units/:id/start_ingest_from_archive(.:format)                      admin/units#start_ingest_from_archive
#                                     update_metadata_admin_unit PUT        /admin/units/:id/update_metadata(.:format)                                admin/units#update_metadata
#                                update_all_solr_docs_admin_unit GET        /admin/units/:id/update_all_solr_docs(.:format)                           admin/units#update_all_solr_docs
#                                       batch_action_admin_units POST       /admin/units/batch_action(.:format)                                       admin/units#batch_action
#                                                    admin_units GET        /admin/units(.:format)                                                    admin/units#index
#                                                                POST       /admin/units(.:format)                                                    admin/units#create
#                                                 new_admin_unit GET        /admin/units/new(.:format)                                                admin/units#new
#                                                edit_admin_unit GET        /admin/units/:id/edit(.:format)                                           admin/units#edit
#                                                     admin_unit GET        /admin/units/:id(.:format)                                                admin/units#show
#                                                                PUT        /admin/units/:id(.:format)                                                admin/units#update
#                                  batch_action_admin_use_rights POST       /admin/use_rights/batch_action(.:format)                                  admin/use_rights#batch_action
#                                               admin_use_rights GET        /admin/use_rights(.:format)                                               admin/use_rights#index
#                                                                POST       /admin/use_rights(.:format)                                               admin/use_rights#create
#                                            new_admin_use_right GET        /admin/use_rights/new(.:format)                                           admin/use_rights#new
#                                           edit_admin_use_right GET        /admin/use_rights/:id/edit(.:format)                                      admin/use_rights#edit
#                                                admin_use_right GET        /admin/use_rights/:id(.:format)                                           admin/use_rights#show
#                                                                PUT        /admin/use_rights/:id(.:format)                                           admin/use_rights#update
#                                    batch_action_admin_comments POST       /admin/comments/batch_action(.:format)                                    admin/comments#batch_action
#                                                 admin_comments GET        /admin/comments(.:format)                                                 admin/comments#index
#                                                                POST       /admin/comments(.:format)                                                 admin/comments#create
#                                                  admin_comment GET        /admin/comments/:id(.:format)                                             admin/comments#show
#                        batch_action_patron_automation_messages POST       /patron/automation_messages/batch_action(.:format)                        patron/automation_messages#batch_action
#                                     patron_automation_messages GET        /patron/automation_messages(.:format)                                     patron/automation_messages#index
#                                                                POST       /patron/automation_messages(.:format)                                     patron/automation_messages#create
#                                 edit_patron_automation_message GET        /patron/automation_messages/:id/edit(.:format)                            patron/automation_messages#edit
#                                      patron_automation_message GET        /patron/automation_messages/:id(.:format)                                 patron/automation_messages#show
#                                                                PUT        /patron/automation_messages/:id(.:format)                                 patron/automation_messages#update
#                                   external_lookup_patron_bibls GET        /patron/bibls/external_lookup(.:format)                                   patron/bibls#external_lookup
#                                      batch_action_patron_bibls POST       /patron/bibls/batch_action(.:format)                                      patron/bibls#batch_action
#                                                   patron_bibls GET        /patron/bibls(.:format)                                                   patron/bibls#index
#                                                                POST       /patron/bibls(.:format)                                                   patron/bibls#create
#                                                new_patron_bibl GET        /patron/bibls/new(.:format)                                               patron/bibls#new
#                                               edit_patron_bibl GET        /patron/bibls/:id/edit(.:format)                                          patron/bibls#edit
#                                                    patron_bibl GET        /patron/bibls/:id(.:format)                                               patron/bibls#show
#                                                                PUT        /patron/bibls/:id(.:format)                                               patron/bibls#update
#                                 batch_action_patron_components POST       /patron/components/batch_action(.:format)                                 patron/components#batch_action
#                                              patron_components GET        /patron/components(.:format)                                              patron/components#index
#                                                                POST       /patron/components(.:format)                                              patron/components#create
#                                           new_patron_component GET        /patron/components/new(.:format)                                          patron/components#new
#                                          edit_patron_component GET        /patron/components/:id/edit(.:format)                                     patron/components#edit
#                                               patron_component GET        /patron/components/:id(.:format)                                          patron/components#show
#                                                                PUT        /patron/components/:id(.:format)                                          patron/components#update
#                                  batch_action_patron_customers POST       /patron/customers/batch_action(.:format)                                  patron/customers#batch_action
#                                               patron_customers GET        /patron/customers(.:format)                                               patron/customers#index
#                                                                POST       /patron/customers(.:format)                                               patron/customers#create
#                                            new_patron_customer GET        /patron/customers/new(.:format)                                           patron/customers#new
#                                           edit_patron_customer GET        /patron/customers/:id/edit(.:format)                                      patron/customers#edit
#                                                patron_customer GET        /patron/customers/:id(.:format)                                           patron/customers#show
#                                                                PUT        /patron/customers/:id(.:format)                                           patron/customers#update
#                                               patron_dashboard            /patron/dashboard(.:format)                                               patron/dashboard#index
#                           copy_from_archive_patron_master_file PUT        /patron/master_files/:id/copy_from_archive(.:format)                      patron/master_files#copy_from_archive
#                               batch_action_patron_master_files POST       /patron/master_files/batch_action(.:format)                               patron/master_files#batch_action
#                                            patron_master_files GET        /patron/master_files(.:format)                                            patron/master_files#index
#                                                                POST       /patron/master_files(.:format)                                            patron/master_files#create
#                                        edit_patron_master_file GET        /patron/master_files/:id/edit(.:format)                                   patron/master_files#edit
#                                             patron_master_file GET        /patron/master_files/:id(.:format)                                        patron/master_files#show
#                                                                PUT        /patron/master_files/:id(.:format)                                        patron/master_files#update
#                                     approve_order_patron_order PUT        /patron/orders/:id/approve_order(.:format)                                patron/orders#approve_order
#                                      cancel_order_patron_order PUT        /patron/orders/:id/cancel_order(.:format)                                 patron/orders#cancel_order
#                     send_fee_estimate_to_customer_patron_order PUT        /patron/orders/:id/send_fee_estimate_to_customer(.:format)                patron/orders#send_fee_estimate_to_customer
#                                     batch_action_patron_orders POST       /patron/orders/batch_action(.:format)                                     patron/orders#batch_action
#                                                  patron_orders GET        /patron/orders(.:format)                                                  patron/orders#index
#                                                                POST       /patron/orders(.:format)                                                  patron/orders#create
#                                               new_patron_order GET        /patron/orders/new(.:format)                                              patron/orders#new
#                                              edit_patron_order GET        /patron/orders/:id/edit(.:format)                                         patron/orders#edit
#                                                   patron_order GET        /patron/orders/:id(.:format)                                              patron/orders#show
#                                                                PUT        /patron/orders/:id(.:format)                                              patron/orders#update
#                                  copy_from_archive_patron_unit PUT        /patron/units/:id/copy_from_archive(.:format)                             patron/units#copy_from_archive
#                                 print_routing_slip_patron_unit PUT        /patron/units/:id/print_routing_slip(.:format)                            patron/units#print_routing_slip
#                                      change_status_patron_unit GET        /patron/units/:id/change_status(.:format)                                 patron/units#change_status
#                               checkout_to_digiserv_patron_unit PUT        /patron/units/:id/checkout_to_digiserv(.:format)                          patron/units#checkout_to_digiserv
#                              checkin_from_digiserv_patron_unit PUT        /patron/units/:id/checkin_from_digiserv(.:format)                         patron/units#checkin_from_digiserv
#                                      batch_action_patron_units POST       /patron/units/batch_action(.:format)                                      patron/units#batch_action
#                                                   patron_units GET        /patron/units(.:format)                                                   patron/units#index
#                                                                POST       /patron/units(.:format)                                                   patron/units#create
#                                                new_patron_unit GET        /patron/units/new(.:format)                                               patron/units#new
#                                               edit_patron_unit GET        /patron/units/:id/edit(.:format)                                          patron/units#edit
#                                                    patron_unit GET        /patron/units/:id(.:format)                                               patron/units#show
#                                                                PUT        /patron/units/:id(.:format)                                               patron/units#update
#                                   batch_action_patron_comments POST       /patron/comments/batch_action(.:format)                                   patron/comments#batch_action
#                                                patron_comments GET        /patron/comments(.:format)                                                patron/comments#index
#                                                                POST       /patron/comments(.:format)                                                patron/comments#create
#                                                 patron_comment GET        /patron/comments/:id(.:format)                                            patron/comments#show
#                                          batch_action_comments POST       /comments/batch_action(.:format)                                          comments#batch_action
#                                                       comments GET        /comments(.:format)                                                       comments#index
#                                                                POST       /comments(.:format)                                                       comments#create
#                                                        comment GET        /comments/:id(.:format)                                                   comments#show
#                                         new_admin_user_session GET        /admin/login(.:format)                                                    active_admin/devise/sessions#new
#                                             admin_user_session POST       /admin/login(.:format)                                                    active_admin/devise/sessions#create
#                                     destroy_admin_user_session DELETE|GET /admin/logout(.:format)                                                   active_admin/devise/sessions#destroy
#                                            admin_user_password POST       /admin/password(.:format)                                                 active_admin/devise/passwords#create
#                                        new_admin_user_password GET        /admin/password/new(.:format)                                             active_admin/devise/passwords#new
#                                       edit_admin_user_password GET        /admin/password/edit(.:format)                                            active_admin/devise/passwords#edit
#                                                                PUT        /admin/password(.:format)                                                 active_admin/devise/passwords#update
