import { formatImageLinksForWidget } from '../imageLinkFormatter';

describe('formatImageLinksForWidget', () => {
  it('converts plain image URLs to clickable markdown images', () => {
    expect(
      formatImageLinksForWidget('Image https://cdn.example.com/product.jpg')
    ).toBe(
      'Image [![Image](https://cdn.example.com/product.jpg)](https://cdn.example.com/product.jpg)'
    );
  });

  it('converts image URLs with query params', () => {
    const imageUrl = 'https://cdn.example.com/product.png?v=123';

    expect(formatImageLinksForWidget(`Image ${imageUrl}`)).toBe(
      `Image [![Image](${imageUrl})](${imageUrl})`
    );
  });

  it('keeps non-image URLs as links', () => {
    const message = 'Open https://example.com/products/123';

    expect(formatImageLinksForWidget(message)).toBe(message);
  });

  it('does not convert existing markdown links or images', () => {
    const message =
      '[Product](https://cdn.example.com/product.jpg) ![Product](https://cdn.example.com/product.png)';

    expect(formatImageLinksForWidget(message)).toBe(message);
  });

  it('converts multiple image URLs in the same message', () => {
    expect(
      formatImageLinksForWidget(
        'Images https://cdn.example.com/one.webp and https://cdn.example.com/two.avif'
      )
    ).toBe(
      'Images [![Image](https://cdn.example.com/one.webp)](https://cdn.example.com/one.webp) and [![Image](https://cdn.example.com/two.avif)](https://cdn.example.com/two.avif)'
    );
  });
});
