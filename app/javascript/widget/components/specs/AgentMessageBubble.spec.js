import { mount } from '@vue/test-utils';
import AgentMessageBubble from '../AgentMessageBubble.vue';

describe('AgentMessageBubble', () => {
  it('renders plain image URLs as clickable images', () => {
    const imageUrl =
      'https://cdn.shopify.com/s/files/1/0602/1473/9150/files/product.webp?v=1720509579';
    const wrapper = mount(AgentMessageBubble, {
      props: {
        message: `Immagine prodotto ${imageUrl}`,
      },
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

    const image = wrapper.find('.message-content img');
    const link = wrapper.find('.message-content a');

    expect(image.exists()).toBe(true);
    expect(image.attributes('src')).toBe(imageUrl);
    expect(link.attributes('href')).toBe(imageUrl);
  });
});
