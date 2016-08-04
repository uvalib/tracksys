module ActiveAdmin
  module Views
    module Pages
      class Base < Arbre::HTML::Document

      alias_method :original_build_active_admin_head, :build_active_admin_head

      def build_active_admin_head
          original_build_active_admin_head
          within @head do
            meta name: "referrer", content: "origin"
          end
        end
      end
    end
  end
end
