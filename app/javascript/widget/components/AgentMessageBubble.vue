<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ChatCard from 'shared/components/ChatCard.vue';
import ChatForm from 'shared/components/ChatForm.vue';
import ChatOptions from 'shared/components/ChatOptions.vue';
import ChatArticle from './template/Article.vue';
import EmailInput from './template/EmailInput.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import IntegrationCard from './template/IntegrationCard.vue';
import { formatImageLinksForWidget } from 'widget/helpers/imageLinkFormatter';
import { getContrastingTextColor } from '@chatwoot/utils';
import { adjustColorForContrast } from 'shared/helpers/colorHelper';

const DEFAULT_LINK_BUTTON_LABEL = 'Apri link';
const DEFAULT_WIDGET_COLOR = '#1f93ff';
const LIGHT_AGENT_BUBBLE_BACKGROUND = '#fdfdfd';
const DARK_AGENT_BUBBLE_BACKGROUND = '#2c2d36';
const URL_LABEL_PATTERN = /^https?:\/\//;

const isRawUrlLabel = (label, href) => {
  const normalizedLabel = label.trim().replace(/\/$/, '');
  const normalizedHref = href.trim().replace(/\/$/, '');
  return (
    URL_LABEL_PATTERN.test(normalizedLabel) &&
    normalizedHref.includes(normalizedLabel)
  );
};

export default {
  name: 'AgentMessageBubble',
  components: {
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
    CustomerSatisfaction,
    IntegrationCard,
  },
  props: {
    message: { type: String, default: null },
    contentType: { type: String, default: null },
    messageType: { type: Number, default: null },
    messageId: { type: Number, default: null },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    widgetColor: {
      type: String,
      default: '',
    },
    darkMode: {
      type: String,
      default: 'light',
    },
  },
  setup() {
    const { formatMessage, getPlainText, truncateMessage, highlightContent } =
      useMessageFormatter();
    return {
      formatMessage,
      getPlainText,
      truncateMessage,
      highlightContent,
    };
  },
  computed: {
    formattedMessage() {
      const message = this.formatMessage(
        formatImageLinksForWidget(this.message),
        false
      );
      return this.formatLinksAsButtons(message);
    },
    linkButtonStyle() {
      return {
        '--cw-link-button-bg': this.linkButtonColor,
        '--cw-link-button-text': getContrastingTextColor(this.linkButtonColor),
      };
    },
    linkButtonColor() {
      return adjustColorForContrast(
        this.widgetColor || DEFAULT_WIDGET_COLOR,
        this.agentBubbleBackground
      );
    },
    agentBubbleBackground() {
      return this.prefersDarkMode
        ? DARK_AGENT_BUBBLE_BACKGROUND
        : LIGHT_AGENT_BUBBLE_BACKGROUND;
    },
    prefersDarkMode() {
      if (this.darkMode === 'dark') return true;
      if (this.darkMode === 'auto') {
        return window.matchMedia?.('(prefers-color-scheme: dark)').matches;
      }
      return false;
    },
    isTemplate() {
      return this.messageType === 3;
    },
    isTemplateEmail() {
      return this.contentType === 'input_email';
    },
    isCards() {
      return this.contentType === 'cards';
    },
    isOptions() {
      return this.contentType === 'input_select';
    },
    isForm() {
      return this.contentType === 'form';
    },
    isArticle() {
      return this.contentType === 'article';
    },
    isCSAT() {
      return this.contentType === 'input_csat';
    },
    isIntegrations() {
      return this.contentType === 'integrations';
    },
  },
  methods: {
    formatLinksAsButtons(message) {
      const document = new DOMParser().parseFromString(message, 'text/html');
      document.querySelectorAll('a.link').forEach(link => {
        if (link.querySelector('img')) return;

        const label = link.textContent || '';
        const href = link.getAttribute('href') || '';
        link.classList.add('link-button');
        link.setAttribute('title', href);
        link.setAttribute(
          'aria-label',
          `${DEFAULT_LINK_BUTTON_LABEL}: ${href}`
        );

        if (isRawUrlLabel(label, href)) {
          link.textContent = DEFAULT_LINK_BUTTON_LABEL;
        }
      });

      return document.body.innerHTML;
    },
    onResponse(messageResponse) {
      this.$store.dispatch('message/update', messageResponse);
    },
    onOptionSelect(selectedOption) {
      this.onResponse({
        submittedValues: [selectedOption],
        messageId: this.messageId,
      });
    },
    onFormSubmit(formValues) {
      const formValuesAsArray = Object.keys(formValues).map(key => ({
        name: key,
        value: formValues[key],
      }));
      this.onResponse({
        submittedValues: formValuesAsArray,
        messageId: this.messageId,
      });
    },
  },
};
</script>

<template>
  <div class="chat-bubble-wrap">
    <div
      v-if="
        !isCards && !isOptions && !isForm && !isArticle && !isCards && !isCSAT
      "
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12"
    >
      <div
        v-dompurify-html="formattedMessage"
        class="message-content text-n-slate-12"
        :style="linkButtonStyle"
      />
      <EmailInput
        v-if="isTemplateEmail"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />

      <IntegrationCard
        v-if="isIntegrations"
        :message-id="messageId"
        :meeting-data="messageContentAttributes.data"
      />
    </div>
    <div v-if="isOptions">
      <ChatOptions
        :title="message"
        :options="messageContentAttributes.items"
        :hide-fields="!!messageContentAttributes.submitted_values"
        @option-select="onOptionSelect"
      />
    </div>
    <ChatForm
      v-if="isForm && !messageContentAttributes.submitted_values"
      :items="messageContentAttributes.items"
      :button-label="messageContentAttributes.button_label"
      :submitted-values="messageContentAttributes.submitted_values"
      @submit="onFormSubmit"
    />
    <div v-if="isCards">
      <ChatCard
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.media_url"
        :title="item.title"
        :description="item.description"
        :actions="item.actions"
      />
    </div>
    <div v-if="isArticle">
      <ChatArticle :items="messageContentAttributes.items" />
    </div>
    <CustomerSatisfaction
      v-if="isCSAT"
      :message-content-attributes="messageContentAttributes.submitted_values"
      :display-type="messageContentAttributes.display_type"
      :message="message"
      :message-id="messageId"
    />
  </div>
</template>

<style scoped lang="scss">
.message-content::v-deep(.link-button) {
  @apply inline-flex items-center justify-center no-underline rounded-lg font-semibold px-3 py-1.5 my-1 shadow-sm transition-opacity;

  background: var(--cw-link-button-bg);
  color: var(--cw-link-button-text);
  word-break: break-word;

  &:hover {
    opacity: 0.9;
  }
}
</style>
