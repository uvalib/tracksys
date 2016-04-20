module ActiveAdmin
  module Inputs
    class FilterStringInput < ::Formtastic::Inputs::StringInput
      include FilterBase

      def to_html
        input_wrapping do
          [ label_html,
            select_html,
            " ",
            input_html
          ].join("\n").html_safe
        end
      end

      def input_html
        builder.text_field current_filter, input_html_options
      end

      def input_html_options
        { :size => 10, :id => "#{method}" }
      end

      def select_html
        template.select_tag '', select_options, select_html_options
      end

      def select_options
        template.options_for_select(filters, current_filter)
      end

      def select_html_options
        { :onchange => "document.getElementById('#{method}').name = 'q[' + this.value + ']';" }
      end

      # Returns the scope for which we are currently searching. If no search is available
      # it returns the first scope
      def current_filter
        filters[1..-1].inject(filters.first){|a,b| @object.send(b[1].to_sym) ? b : a }[1]
      end

      def filters
        (options[:filters] || default_filters).collect do |scope|
          [scope[0], [method, scope[1]].join("_")]
        end
      end

      def default_filters
        [ ['Equals', 'equals'],
          ['Contains', 'contains'],
          ['Starts With', 'starts_with'],
          ['Ends With', 'ends_with'],
          ['Empty', 'is_null'] ]
      end
    end
  end
end
