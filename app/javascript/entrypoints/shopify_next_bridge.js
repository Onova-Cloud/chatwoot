/* eslint-disable func-names, no-console, no-var, prefer-rest-params, prefer-spread, vars-on-top */
(function () {
  var BRIDGE_KEY = '__omniShopifyNextBridge';
  var CART_PATH_PATTERN = /\/cart\/(add|change|update|clear)(\.js)?/;
  var DEFAULT_RETRY_DELAYS = [0, 500, 1500, 3000];

  var state = window[BRIDGE_KEY] || {
    started: false,
    fetchPatched: false,
    xhrPatched: false,
    lastCompleteCartToken: null,
    options: { debug: false },
  };

  window[BRIDGE_KEY] = state;

  function log() {
    if (!state.options.debug || !window.console) return;
    window.console.log.apply(
      window.console,
      ['[shopify_next]'].concat(Array.prototype.slice.call(arguments))
    );
  }

  function normalizeUrl(url) {
    if (!url) return '';
    if (typeof url === 'string') return url;
    return url.url || '';
  }

  function isCartMutation(url) {
    return CART_PATH_PATTERN.test(normalizeUrl(url));
  }

  function buildCartId(token) {
    return token && token.indexOf('?key=') > -1
      ? 'gid://shopify/Cart/' + token
      : null;
  }

  function rememberCompleteToken(token) {
    if (token && token.indexOf('?key=') > -1) {
      state.lastCompleteCartToken = token;
    }
  }

  function bestToken(cart) {
    var token = cart && cart.token;
    rememberCompleteToken(token);

    if (!cart || cart.item_count === 0) return token;
    return token && token.indexOf('?key=') > -1
      ? token
      : state.lastCompleteCartToken || token;
  }

  function productContext() {
    var product =
      window.ShopifyAnalytics &&
      window.ShopifyAnalytics.meta &&
      window.ShopifyAnalytics.meta.product;

    return {
      product_handle: product && product.handle,
      product_id: product && product.gid,
    };
  }

  function compactCart(cart, token) {
    var items = cart && Array.isArray(cart.items) ? cart.items : [];

    return {
      token: token,
      item_count: (cart && cart.item_count) || 0,
      total_price: (cart && cart.total_price) || 0,
      currency: cart && cart.currency,
      items: items.slice(0, 10).map(function (item) {
        return {
          key: item.key,
          product_id: item.product_id,
          variant_id: item.variant_id,
          title: item.title,
          product_title: item.product_title,
          variant_title: item.variant_title,
          quantity: item.quantity,
          price: item.final_price || item.price,
          line_price: item.final_line_price || item.line_price,
          url: item.url,
          handle: item.handle,
        };
      }),
    };
  }

  function canSync() {
    return (
      window.$omni &&
      typeof window.$omni.setConversationAdditionalAttributes === 'function'
    );
  }

  function sync() {
    if (!canSync()) {
      log('waiting for widget API');
      return Promise.resolve(false);
    }

    return window
      .fetch('/cart.js', { credentials: 'same-origin' })
      .then(function (response) {
        return response.json();
      })
      .then(function (cart) {
        var token = bestToken(cart);
        var product = productContext();
        var payload = {
          shopify_next: {
            current_url: window.location.href,
            product_handle: product.product_handle,
            product_id: product.product_id,
            cart_token: token,
            cart_id: buildCartId(token),
            cart: compactCart(cart, token),
          },
        };

        window.$omni.setConversationAdditionalAttributes(payload);
        log('synced', payload);
        return payload;
      })
      .catch(function (error) {
        log('sync failed', error);
        return false;
      });
  }

  function scheduleSync(delays) {
    (delays || DEFAULT_RETRY_DELAYS).forEach(function (delay) {
      window.setTimeout(sync, delay);
    });
  }

  function patchFetch() {
    if (state.fetchPatched || !window.fetch) return;

    var originalFetch = window.fetch;
    window.fetch = function () {
      var url = normalizeUrl(arguments[0]);
      var response = originalFetch.apply(this, arguments);

      if (
        isCartMutation(url) &&
        response &&
        typeof response.finally === 'function'
      ) {
        response.finally(function () {
          scheduleSync([250, 1000]);
        });
      }

      return response;
    };

    state.fetchPatched = true;
  }

  function patchXhr() {
    if (state.xhrPatched || !window.XMLHttpRequest) return;

    var originalOpen = window.XMLHttpRequest.prototype.open;
    window.XMLHttpRequest.prototype.open = function (method, url) {
      this.addEventListener('loadend', function () {
        if (isCartMutation(url)) {
          scheduleSync([250, 1000]);
        }
      });

      return originalOpen.apply(this, arguments);
    };

    state.xhrPatched = true;
  }

  function bindWidgetOpenSync() {
    document.addEventListener(
      'click',
      function (event) {
        if (
          event.target.closest(
            '[aria-label="Open chat window"], .woot-widget-bubble, .woot--bubble-holder, .woot-widget-holder'
          )
        ) {
          scheduleSync([0, 500]);
        }
      },
      true
    );
  }

  function numericVariantId(variantId) {
    var value = String(variantId || '');
    var matches = value.match(/ProductVariant\/(\d+)/);
    return matches ? matches[1] : value;
  }

  function addToCart(options) {
    var variantId =
      options &&
      (options.product_variant_id || options.variant_id || options.id);
    var quantity = options && options.quantity ? options.quantity : 1;

    return window
      .fetch('/cart/add.js', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: numericVariantId(variantId),
          quantity: quantity,
        }),
      })
      .then(function (response) {
        if (!response.ok) throw new Error('Shopify cart add failed');
        scheduleSync([0, 250, 1000]);
        return response.json();
      });
  }

  function run(options) {
    state.options = Object.assign({ debug: false }, options || {});

    if (state.started) {
      scheduleSync();
      return;
    }

    state.started = true;
    patchFetch();
    patchXhr();
    bindWidgetOpenSync();
    scheduleSync();
  }

  window.omniShopifyNextBridge = {
    run: run,
    sync: sync,
    addToCart: addToCart,
  };
})();
