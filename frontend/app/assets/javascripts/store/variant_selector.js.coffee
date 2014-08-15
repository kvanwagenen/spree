
# jQuery Plugin definition
$.fn.spreeVariantSelector = (options) ->
  if this.length > 0
    this.data = new Spree.VariantSelector($(this), options)

Spree.VariantSelector = (() ->
  VariantSelector = (@$productEl, options) ->
    @productId = @$productEl.data('product')

    @settings = $.extend({
        updateUrl: true,
        prefetch: false
      }, 
      options
    )

    this.registerEventHandlers()

  VariantSelector.prototype.registerEventHandlers = ->
    $selects = this.variantOptionSelects()
    $selects.change _.bind(this.onSelectChange, this)
    
    # Request product JSON after page has loaded
    if @settings.prefetch
      this.getProduct ->
    else
      $(window).load (e) =>
        this.getProduct ->

  VariantSelector.prototype.onSelectChange = (e) ->
    $selects = this.variantOptionSelects()
    selectedOptions = {}
    $selects.each (index, el) ->
      $select = ($ el)
      option_type = ($ el).data('type')
      if $select.val() isnt ""
        selectedOptions[option_type] = $select.val()
    lastOptionType = $(e.currentTarget).data('type')  
    this.showVariant(selectedOptions, lastOptionType)

  VariantSelector.prototype.showVariant = (selectedOptions, lastOptionType) ->
    this.getProduct (err, product) =>

      # Look for matching variant
      variants = product.variants
      match = null
      $.each variants, (index, variant) ->

        # Skip the master variant
        if variant.is_master
          return true

        isMatch = true
        optionValues = variant.option_values
        $.each optionValues, (index, optionValue) ->
          type = optionValue.option_type_name
          name = optionValue.name
          if selectedOptions[type] isnt name and selectedOptions[type] isnt undefined and selectedOptions[type] isnt ""
            isMatch = false
            return false
        if isMatch is true
          match = variant
          return false
        else
          return true
      variant = null
      if match isnt null
        variant = match

      # Set variant id in form
      if variant isnt null
        @$productEl.find('#variant_id').val(variant.id)
        @$productEl.find('.qty').prop("name", "variants[#{variant.id}]")
      else
        @$productEl.find('#variant_id').val("")
        @$productEl.find('.qty').prop("name", "")

      # Set sku
      if variant isnt null
        @$productEl.find('#product-sku .property-value').html(" #{variant.sku}")
        @$productEl.find('#product-sku').show()
      else
        @$productEl.find('#product-sku').hide()

      # Set stock available
      stockAvailable = 0
      backorderable = false
      if variant isnt null
        $.each variant.stock_items, (index, stockItem) ->
          stockAvailable += stockItem.count_on_hand
          backorderable = backorderable || stockItem.backorderable
      $stock = @$productEl.find('.stock-available')
      $stock.html("")
      if stockAvailable > 0 || backorderable
        if stockAvailable > 0 && stockAvailable < 24
          $stock.html("Only #{stockAvailable} left in stock.")

      # Set price
      $price = @$productEl.find('.price.selling')
      if variant isnt null
        $price.html("$#{variant.price}")
        $('#product-price').show()

      # Update add to cart button status
      if variant isnt null and stockAvailable > 0 or backorderable
        @$productEl.find('#add-to-cart').show()
        @$productEl.find('#out-of-stock-button').hide()
      else
        @$productEl.find('#add-to-cart').hide()
        @$productEl.find('#out-of-stock-button').show()

      # Update quantity limits
      $quantity = @$productEl.find('#quantity')
      $quantity.prop("max", stockAvailable)
      if $quantity.val() > stockAvailable
        $quantity.val(Math.max(stockAvailable, 1))

      # Update options based on current selection
      $selects = this.variantOptionSelects()
      $selectsToUpdate = $selects.filter ->
        return $(this).data('type') isnt lastOptionType

      # Update url
      if @settings.updateUrl and history.replaceState and variant isnt null
        path = window.location.pathname.split('/').slice(0, 3).join("/")
        variant.option_values.sort (a,b) ->
          if a.option_type_name < b.option_type_name
            return -1
          else if a.option_type_name > b.option_type_name
            return 1
          else
            return 0
        $.each variant.option_values, (index, optionValue) ->
          path += "/#{optionValue.option_type_name}/#{optionValue.name}"
        history.replaceState('','',window.location.origin + path)

  VariantSelector.prototype.variantOptionSelects = ->
    @$productEl.find('#product-variants select')

  VariantSelector.prototype.getProduct = (cb) ->

    # Check for cached product
    if @product isnt undefined
      cb(null, @product)
    else

      # Request product
      $.get "/api/products/#{@productId}", (product) =>
        @product = product
        cb(null, @product)

  VariantSelector
)()

$ ->
  $('#product-show').spreeVariantSelector()
