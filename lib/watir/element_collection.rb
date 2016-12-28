module Watir

  #
  # Base class for element collections.
  #

  class ElementCollection
    include Enumerable

    def initialize(query_scope, selector)
      @query_scope = query_scope
      @selector = selector
    end

    #
    # Yields each element in collection.
    #
    # @example
    #   divs = browser.divs(class: 'kls')
    #   divs.each do |div|
    #     puts div.text
    #   end
    #
    # @yieldparam [Watir::Element] element Iterate through the elements in this collection.
    #

    def each(&blk)
      to_a.each(&blk)
    end

    #
    # Returns number of elements in collection.
    #
    # @return [Integer]
    #

    def length
      elements.length
    end
    alias_method :size, :length

    #
    # Get the element at the given index.
    #
    # Also note that because of Watir's lazy loading, this will return an Element
    # instance even if the index is out of bounds.
    #
    # @param [Integer] idx Index of wanted element, 0-indexed
    # @return [Watir::Element] Returns an instance of a Watir::Element subclass
    #

    def [](idx)
      to_a[idx] || element_class.new(@query_scope, @selector.merge(index: idx))
    end

    #
    # First element of this collection
    #
    # @return [Watir::Element] Returns an instance of a Watir::Element subclass
    #

    def first
      self[0]
    end

    #
    # Last element of the collection
    #
    # @return [Watir::Element] Returns an instance of a Watir::Element subclass
    #

    def last
      self[-1]
    end

    #
    # This collection as an Array.
    #
    # @return [Array<Watir::Element>]
    #

    def to_a
      # TODO: optimize - lazy element_class instance?
      @to_a ||= elements.map.with_index do |e, idx|
        element_class.new(@query_scope, @selector.merge(element: e, index: idx))
      end
    end

    private

    def elements
      @query_scope.is_a?(IFrame) ? @query_scope.switch_to! : @query_scope.send(:assert_exists)

      element_validator = element_validator_class.new
      selector_builder = selector_builder_class.new(@query_scope, @selector, element_class.attribute_list)
      locator = locator_class.new(@query_scope, @selector, selector_builder, element_validator)

      @elements ||= locator.locate_all
    end

    def locator_class
      Kernel.const_get("#{Watir.locator_namespace}::#{element_class_name}::Locator")
    rescue NameError
      Kernel.const_get("#{Watir.locator_namespace}::Element::Locator")
    end

    def element_validator_class
      Kernel.const_get("#{Watir.locator_namespace}::#{element_class_name}::Validator")
    rescue NameError
      Kernel.const_get("#{Watir.locator_namespace}::Element::Validator")
    end

    def selector_builder_class
      Kernel.const_get("#{Watir.locator_namespace}::#{element_class_name}::SelectorBuilder")
    rescue NameError
      Kernel.const_get("#{Watir.locator_namespace}::Element::SelectorBuilder")
    end

    def element_class_name
      element_class.to_s.split('::').last
    end

    def element_class
      Kernel.const_get(self.class.name.sub(/Collection$/, ''))
    end

  end # ElementCollection
end # Watir
