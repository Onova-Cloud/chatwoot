import { mount } from '@vue/test-utils';
import { getContrast } from 'color2k';
import AgentMessageBubble from '../AgentMessageBubble.vue';

const mountComponent = props =>
  mount(AgentMessageBubble, {
    props,
    global: {
      directives: {
        dompurifyHtml: (element, binding) => {
          element.innerHTML = binding.value;
        },
      },
      stubs: {
        ChatArticle: true,
        ChatCard: true,
        ChatForm: true,
        ChatOptions: true,
        CustomerSatisfaction: true,
        EmailInput: true,
        IntegrationCard: true,
      },
    },
  });

describe('AgentMessageBubble', () => {
  it('renders plain image URLs as clickable images', () => {
    const imageUrl =
      'https://cdn.shopify.com/s/files/1/0602/1473/9150/files/product.webp?v=1720509579';
    const wrapper = mountComponent({
      message: `Immagine prodotto ${imageUrl}`,
    });

    const image = wrapper.find('.message-content img');
    const link = wrapper.find('.message-content a');

    expect(image.exists()).toBe(true);
    expect(image.attributes('src')).toBe(imageUrl);
    expect(link.attributes('href')).toBe(imageUrl);
    expect(link.classes()).not.toContain('link-button');
  });

  it('renders raw links as buttons with a default label', () => {
    const wrapper = mountComponent({
      message:
        'Link diretto per acquistare tg 45: https://lescarpedirita.myshopify.com/cart/42736865870030:1',
      widgetColor: '#f8f8f8',
    });

    const link = wrapper.find('.message-content a');

    expect(link.classes()).toContain('link-button');
    expect(link.text()).toBe('Apri link');
    expect(link.attributes('href')).toBe(
      'https://lescarpedirita.myshopify.com/cart/42736865870030:1'
    );
    expect(link.attributes('title')).toBe(
      'https://lescarpedirita.myshopify.com/cart/42736865870030:1'
    );
    expect(link.attributes('aria-label')).toBe(
      'Apri link: https://lescarpedirita.myshopify.com/cart/42736865870030:1'
    );
  });

  it('preserves markdown link labels when rendering links as buttons', () => {
    const wrapper = mountComponent({
      message: '[Acquista la scarpa](https://example.com/cart)',
      widgetColor: '#1f93ff',
    });

    const link = wrapper.find('.message-content a');

    expect(link.classes()).toContain('link-button');
    expect(link.text()).toBe('Acquista la scarpa');
    expect(link.attributes('href')).toBe('https://example.com/cart');
  });

  it('preserves domain-only markdown link labels', () => {
    const wrapper = mountComponent({
      message: '[example.com](https://example.com)',
      widgetColor: '#1f93ff',
    });

    const link = wrapper.find('.message-content a');

    expect(link.classes()).toContain('link-button');
    expect(link.text()).toBe('example.com');
    expect(link.attributes('href')).toBe('https://example.com');
  });

  it('sets readable link button colors from the widget color', () => {
    const wrapper = mountComponent({
      message: 'https://example.com/cart',
      widgetColor: '#ffffff',
    });

    const messageContent = wrapper.find('.message-content');

    expect(messageContent.attributes('style')).toContain(
      '--cw-link-button-bg:'
    );
    expect(messageContent.attributes('style')).toContain(
      '--cw-link-button-text:'
    );
  });

  it('adjusts button color for contrast against the dark agent bubble', () => {
    const wrapper = mountComponent({
      message: 'https://example.com/cart',
      widgetColor: '#5a5ad6',
      darkMode: 'dark',
    });
    const style = wrapper.find('.message-content').attributes('style');
    const buttonColor = style.match(/--cw-link-button-bg:\s*([^;]+)/)[1];

    expect(getContrast(buttonColor, '#2c2d36')).toBeGreaterThanOrEqual(3.1);
  });
});
