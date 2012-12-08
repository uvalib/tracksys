module ActiveAdmin
  module Inputs
    class FilterNumericInput < ::Formtastic::Inputs::NumberInput

      def default_filters
        [ [I18n.t('active_admin.equal_to'), 'eq'],
          [I18n.t('active_admin.greater_than'), 'gt'],
          [I18n.t('active_admin.less_than'), 'lt'],
          ['Is Empty', 'is_null'],
          ['Is Not Empty', 'is_not_null'] ]
      end
    end
  end
end