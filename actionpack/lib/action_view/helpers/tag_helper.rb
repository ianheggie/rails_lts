require 'active_support/multibyte'
require 'active_support/core_ext/string/output_safety'
require 'set'

module ActionView
  module Helpers #:nodoc:
    # Provides methods to generate HTML tags programmatically when you can't use
    # a Builder. By default, they output XHTML compliant tags.
    module TagHelper
      include ERB::Util

      BOOLEAN_ATTRIBUTES = %w(disabled readonly multiple checked).to_set
      BOOLEAN_ATTRIBUTES.merge(BOOLEAN_ATTRIBUTES.map(&:to_sym))

      # Returns an empty HTML tag of type +name+ which by default is XHTML
      # compliant. Set +open+ to true to create an open tag compatible
      # with HTML 4.0 and below. Add HTML attributes by passing an attributes
      # hash to +options+. Set +escape+ to false to disable attribute value
      # escaping.
      #
      # ==== Options
      # The +options+ hash is used with attributes with no value like (<tt>disabled</tt> and
      # <tt>readonly</tt>), which you can give a value of true in the +options+ hash. You can use
      # symbols or strings for the attribute names.
      #
      # ==== Examples
      #   tag("br")
      #   # => <br />
      #
      #   tag("br", nil, true)
      #   # => <br>
      #
      #   tag("input", { :type => 'text', :disabled => true })
      #   # => <input type="text" disabled="disabled" />
      #
      #   tag("img", { :src => "open & shut.png" })
      #   # => <img src="open &amp; shut.png" />
      #
      #   tag("img", { :src => "open &amp; shut.png" }, false, false)
      #   # => <img src="open &amp; shut.png" />
      def tag(name, options = nil, open = false, escape = true)
        if escape
          # Applying XML name escaping because it is less restrictive than the
          # HTML spec (but still prevents XSS)
          name = ERB::Util.xml_name_escape(name)
        end
        "<#{name}#{tag_options(options, escape) if options}#{open ? ">" : " />"}".html_safe
      end

      # Returns an HTML block tag of type +name+ surrounding the +content+. Add
      # HTML attributes by passing an attributes hash to +options+.
      # Instead of passing the content as an argument, you can also use a block
      # in which case, you pass your +options+ as the second parameter.
      # Set escape to false to disable attribute value escaping.
      #
      # ==== Options
      # The +options+ hash is used with attributes with no value like (<tt>disabled</tt> and
      # <tt>readonly</tt>), which you can give a value of true in the +options+ hash. You can use
      # symbols or strings for the attribute names.
      #
      # ==== Examples
      #   content_tag(:p, "Hello world!")
      #    # => <p>Hello world!</p>
      #   content_tag(:div, content_tag(:p, "Hello world!"), :class => "strong")
      #    # => <div class="strong"><p>Hello world!</p></div>
      #   content_tag("select", options, :multiple => true)
      #    # => <select multiple="multiple">...options...</select>
      #
      #   <% content_tag :div, :class => "strong" do -%>
      #     Hello world!
      #   <% end -%>
      #    # => <div class="strong">Hello world!</div>
      def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
        if block_given?
          options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
          content_tag = content_tag_string(name, capture(&block), options, escape)

          if block_called_from_erb?(block)
            concat(content_tag)
          else
            content_tag
          end
        else
          content_tag_string(name, content_or_options_with_block, options, escape)
        end
      end

      # Returns a CDATA section with the given +content+.  CDATA sections
      # are used to escape blocks of text containing characters which would
      # otherwise be recognized as markup. CDATA sections begin with the string
      # <tt><![CDATA[</tt> and end with (and may not contain) the string <tt>]]></tt>.
      #
      # ==== Examples
      #   cdata_section("<hello world>")
      #   # => <![CDATA[<hello world>]]>
      #
      #   cdata_section(File.read("hello_world.txt"))
      #   # => <![CDATA[<hello from a text file]]>
      def cdata_section(content)
        "<![CDATA[#{content}]]>".html_safe
      end

      # Returns an escaped version of +html+ without affecting existing escaped entities.
      #
      # ==== Examples
      #   escape_once("1 < 2 &amp; 3")
      #   # => "1 &lt; 2 &amp; 3"
      #
      #   escape_once("&lt;&lt; Accept & Checkout")
      #   # => "&lt;&lt; Accept &amp; Checkout"
      def escape_once(html)
        ActiveSupport::Multibyte.clean(html.to_s).gsub(/[\"><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| ERB::Util::HTML_ESCAPE[special] }
      end

      private
        BLOCK_CALLED_FROM_ERB = 'defined? __in_erb_template'

        if RUBY_VERSION < '1.9.0'
          # Check whether we're called from an erb template.
          # We'd return a string in any other case, but erb <%= ... %>
          # can't take an <% end %> later on, so we have to use <% ... %>
          # and implicitly concat.
          def block_called_from_erb?(block)
            block && eval(BLOCK_CALLED_FROM_ERB, block)
          end
        else
          def block_called_from_erb?(block)
            block && eval(BLOCK_CALLED_FROM_ERB, block.binding)
          end
        end

        def content_tag_string(name, content, options, escape = true)
          tag_options = tag_options(options, escape) if options
          if escape
            # Applying XML name escaping because it is less restrictive than the
            # HTML spec (but still prevents XSS)
            name = ERB::Util.xml_name_escape(name)
          end
          "<#{name}#{tag_options}>#{content}</#{name}>".html_safe
        end

        def tag_options(options, escape = true)
          unless options.blank?
            attrs = []
            if escape
              options.each_pair do |key, value|
                if BOOLEAN_ATTRIBUTES.include?(key)
                  attrs << %(#{key}="#{key}") if value
                else
                  # Applying the HTML spec because it is less restrictive on
                  # attribute names than the XML spec (but still prevents XSS)
                  escaped_key = ERB::Util.html_attribute_name_escape(key)
                  attrs << %(#{escaped_key}="#{escape_once(value)}") if !value.nil?
                end
              end
            else
              attrs = options.map { |key, value| %(#{key}="#{value.to_s.gsub(/"/, '&quot;')}") }
            end
            " #{attrs.sort * ' '}".html_safe unless attrs.empty?
          end
        end
    end
  end
end
