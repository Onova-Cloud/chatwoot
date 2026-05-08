<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import integrationAPI from 'dashboard/api/integrations';

import Integration from './Integration.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();
const store = useStore();

const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const isTesting = ref(false);
const shopDomain = ref('');
const accessToken = ref('');
const storefrontPassword = ref('');
const apiVersion = ref('2026-04');
const enabledForCaptain = ref(true);
const updateCartEnabled = ref(false);
const integration = ref({});

const integrationAction = computed(() =>
  integration.value.enabled ? 'disconnect' : 'connect'
);

const formPayload = computed(() => {
  const payload = {
    shop_domain: shopDomain.value,
    api_version: apiVersion.value,
    enabled_for_captain: enabledForCaptain.value,
    update_cart_enabled: updateCartEnabled.value,
  };

  if (accessToken.value) {
    payload.access_token = accessToken.value;
  }

  if (storefrontPassword.value) {
    payload.storefront_password = storefrontPassword.value;
  }

  return payload;
});

const hasSavedToken = computed(() => integration.value.enabled);
const hasSavedStorefrontPassword = computed(
  () => integration.value.hooks?.[0]?.settings?.storefront_password_configured
);
const storefrontSnippet = computed(
  () => `window.$chatwoot.setConversationCustomAttributes({
  shopify_next: {
    current_url: window.location.href,
    product_handle: window.ShopifyAnalytics?.meta?.product?.handle,
    product_id: window.ShopifyAnalytics?.meta?.product?.gid,
    cart_id: window.localStorage.getItem('shopify_cart_id')
  }
});`
);

const syncIntegration = async () => {
  await store.dispatch('integrations/get');
  integration.value = store.getters['integrations/getIntegration'](
    'shopify_next',
    {}
  );

  const hook = integration.value.hooks?.[0];
  if (hook) {
    shopDomain.value = hook.reference_id || '';
    apiVersion.value = hook.settings?.api_version || '2026-04';
    enabledForCaptain.value = hook.settings?.enabled_for_captain !== false;
    updateCartEnabled.value = hook.settings?.update_cart_enabled === true;
  }
};

const save = async () => {
  try {
    isSubmitting.value = true;
    const { data } = await integrationAPI.saveShopifyNext(formPayload.value);
    integration.value = { ...integration.value, enabled: true, hooks: [data] };
    accessToken.value = '';
    storefrontPassword.value = '';
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.SAVE_SUCCESS'));
    await syncIntegration();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.SAVE_ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};

const testConnection = async () => {
  try {
    isTesting.value = true;
    const { data } = await integrationAPI.testShopifyNext(formPayload.value);
    useAlert(
      t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.TEST_SUCCESS', {
        shopName: data.shop?.name || shopDomain.value,
      })
    );
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.TEST_ERROR')
    );
  } finally {
    isTesting.value = false;
  }
};

const disconnect = async () => {
  try {
    await integrationAPI.deleteShopifyNext();
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.DELETE_SUCCESS'));
    shopDomain.value = '';
    accessToken.value = '';
    storefrontPassword.value = '';
    await syncIntegration();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.API.DELETE_ERROR')
    );
  }
};

onMounted(async () => {
  await syncIntegration();
  integrationLoaded.value = true;
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || isSubmitting">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.HEADER')"
        description=""
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
        feature-name="integrations"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          :integration-id="integration.id"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="integration.enabled"
          :integration-action="integrationAction"
          :action-button-text="t('INTEGRATION_SETTINGS.DISCONNECT.BUTTON_TEXT')"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.DELETE.MESSAGE'),
          }"
        >
          <template #action>
            <Button
              :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
              teal
              @click="save"
            />
          </template>
        </Integration>

        <div
          class="grid grid-cols-1 gap-4 p-6 outline outline-n-container outline-1 bg-n-card rounded-xl"
        >
          <Input
            v-model="shopDomain"
            :label="t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.SHOP_DOMAIN')"
            placeholder="your-store.myshopify.com"
          />
          <Input
            v-model="accessToken"
            :label="t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.ACCESS_TOKEN')"
            :placeholder="
              hasSavedToken
                ? t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.TOKEN_SAVED')
                : 'shpat_...'
            "
            type="password"
          />
          <Input
            v-model="storefrontPassword"
            :label="
              t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.STOREFRONT_PASSWORD')
            "
            :placeholder="
              hasSavedStorefrontPassword
                ? t(
                    'INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.STOREFRONT_PASSWORD_SAVED'
                  )
                : t(
                    'INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.STOREFRONT_PASSWORD_PLACEHOLDER'
                  )
            "
            type="password"
          />
          <Input
            v-model="apiVersion"
            :label="t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.API_VERSION')"
            placeholder="2026-04"
          />
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="enabledForCaptain" />
            <span>
              {{
                t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.ENABLED_FOR_CAPTAIN')
              }}
            </span>
          </label>
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="updateCartEnabled" />
            <span>
              {{
                t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.UPDATE_CART_ENABLED')
              }}
            </span>
          </label>
          <div class="grid gap-2">
            <p class="text-sm font-medium text-n-slate-12">
              {{
                t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.STOREFRONT_SNIPPET')
              }}
            </p>
            <pre
              class="overflow-auto rounded-md bg-n-alpha-2 p-3 text-xs text-n-slate-12"
            ><code>{{ storefrontSnippet }}</code></pre>
          </div>
          <div class="flex flex-wrap gap-3">
            <Button
              :label="t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.TEST')"
              faded
              blue
              :is-loading="isTesting"
              @click="testConnection"
            />
            <Button
              :label="t('INTEGRATION_SETTINGS.SHOPIFY_NEXT.FORM.SAVE')"
              teal
              :is-loading="isSubmitting"
              @click="save"
            />
            <Button
              v-if="integration.enabled"
              :label="t('INTEGRATION_SETTINGS.DISCONNECT.BUTTON_TEXT')"
              faded
              ruby
              @click="disconnect"
            />
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
