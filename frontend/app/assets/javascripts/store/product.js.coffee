$ ->
  Spree.addImageHandlers = ->
    thumbnails = ($ '#product-images ul.thumbnails')
    ($ '#main-image').data 'selectedThumb', ($ '#main-image img').attr('src')
    thumbnails.find('li').eq(0).addClass 'selected'
    thumbnails.find('a').on 'click', (event) ->
      ($ '#main-image').data 'selectedThumb', ($ event.currentTarget).attr('href')
      ($ '#main-image').data 'selectedThumbId', ($ event.currentTarget).parent().attr('id')
      ($ this).mouseout ->
        thumbnails.find('li').removeClass 'selected'
        ($ event.currentTarget).parent('li').addClass 'selected'
      false

    thumbnails.find('li').on 'mouseenter', (event) ->
      ($ '#main-image img').attr 'src', ($ event.currentTarget).find('a').attr('href')

    thumbnails.find('li').on 'mouseleave', (event) ->
      ($ '#main-image img').attr 'src', ($ '#main-image').data('selectedThumb')

  Spree.showVariantImages = (variantId) ->
    ($ 'li.vtmb').hide()
    ($ 'li.tmb-' + variantId).show()
    currentThumb = ($ '#' + ($ '#main-image').data('selectedThumbId'))
    if not currentThumb.hasClass('vtmb-' + variantId)
      thumb = ($ ($ '#product-images ul.thumbnails li:visible.vtmb').eq(0))
      thumb = ($ ($ '#product-images ul.thumbnails li:visible').eq(0)) unless thumb.length > 0
      newImg = thumb.find('a').attr('href')
      ($ '#product-images ul.thumbnails li').removeClass 'selected'
      thumb.addClass 'selected'
      ($ '#main-image img').attr 'src', newImg
      ($ '#main-image').data 'selectedThumb', newImg
      ($ '#main-image').data 'selectedThumbId', thumb.attr('id')

  Spree.updateVariantPrice = (variant) ->
    variantPrice = variant.data('price')
    ($ '.price.selling').text(variantPrice) if variantPrice
  radios = ($ '#product-variants input[type="radio"]')

  if radios.length > 0
    Spree.showVariantImages ($ '#product-variants input[type="radio"]').eq(0).attr('value')
    Spree.updateVariantPrice radios.first()

  Spree.addImageHandlers()

  radios.click (event) ->
    Spree.showVariantImages @value
    Spree.updateVariantPrice ($ this)

  Spree.currentProduct = (cb) ->

    # Check for cached product
    if @product isnt undefined
      cb(null, @product)
    else

      # Determine product by retrieving permalink from location
      permalink = window.location.pathname.split('/')[2]

      # Request product
      $.get "/api/products/#{permalink}", (product) =>
        @product = product
        cb(null, @product)

  Spree.variantOptionSelects = ->
    ($ '#product-variants select')

  Spree.showVariant = (product, selectedOptions, lastOptionType) ->
          
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
      ($ '#variant_id').val(variant.id)
      ($ '.qty').prop("name", "variants[#{variant.id}]")
    else
      ($ '#variant_id').val("")
      ($ '.qty').prop("name", "")

    # Set stock available
    stockAvailable = 0
    backorderable = false
    if variant isnt null
      $.each variant.stock_items, (index, stockItem) ->
        stockAvailable += stockItem.count_on_hand
        backorderable = backorderable || stockItem.backorderable
    $stock = ($ '.stock-available')
    $stock.html("")
    if stockAvailable > 0 || backorderable
      if stockAvailable > 0 && stockAvailable < 24
        $stock.html("Only #{stockAvailable} left in stock.")

    # Set price
    $price = ($ '.price.selling')
    if variant isnt null
      $price.html("$#{variant.price}")
      $('#product-price').show()

    # Update add to cart button status
    if variant isnt null and stockAvailable > 0 or backorderable
      ($ '#add-to-cart').show()
      ($ '#out-of-stock-button').hide()
    else
      ($ '#add-to-cart').hide()
      ($ '#out-of-stock-button').show()

    # Update quantity limits
    $quantity = ($ '#quantity')
    $quantity.prop("max", stockAvailable)
    if $quantity.val() > stockAvailable
      $quantity.val(stockAvailable)

    # Update options based on current selection
    $selects = Spree.variantOptionSelects()
    $selectsToUpdate = $selects.filter ->
      return $(this).data('type') isnt lastOptionType

    # Update url
    if history.pushState and variant isnt null
      path = window.location.pathname.split('/').slice(0, 3).join("/")
      $.each variant.option_values, (index, optionValue) ->
        path += "/#{optionValue.option_type_name}/#{optionValue.name}"
      history.pushState('','',window.location.origin + path)

    # TODO Set images



  # Listen for change event on option selects to update displayed variant
  $selects = Spree.variantOptionSelects()
  $selects.change (e) ->
    selectedOptions = {}
    $selects.each (index, el) ->
      $select = ($ el)
      option_type = ($ el).data('type')
      if $select.val() isnt ""
        selectedOptions[option_type] = $select.val()
    lastOptionType = $(e.currentTarget).data('type')
    Spree.currentProduct (err, product) ->  
      Spree.showVariant(product, selectedOptions, lastOptionType)

  # Request product JSON after page has loaded
  pathParts = window.location.pathname.split('/')
  if pathParts[1] is "products" and pathParts[2].length > 0
    $(window).load (e) ->
      Spree.currentProduct ->