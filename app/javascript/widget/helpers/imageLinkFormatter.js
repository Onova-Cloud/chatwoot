const URL_REGEX = /https?:\/\/[^\s<>"']+/gi;
const MARKDOWN_LINK_OR_IMAGE_REGEX = /!?\[[^\]\n]*\]\([^)]+\)/g;
const IMAGE_EXTENSION_REGEX = /\.(?:jpe?g|png|webp|gif|avif|svg)$/i;
const TRAILING_PUNCTUATION_REGEX = /[.,!?;:]+$/;
const TRAILING_BRACKET_PAIRS = [
  ['(', ')'],
  ['[', ']'],
  ['{', '}'],
];

const getMarkdownRanges = message => {
  const ranges = [];
  let match = MARKDOWN_LINK_OR_IMAGE_REGEX.exec(message);

  while (match !== null) {
    ranges.push({
      start: match.index,
      end: match.index + match[0].length,
    });
    match = MARKDOWN_LINK_OR_IMAGE_REGEX.exec(message);
  }

  return ranges;
};

const isInsideRange = (index, ranges) =>
  ranges.some(range => index >= range.start && index < range.end);

const countCharacter = (text, character) => text.split(character).length - 1;

const getUnbalancedTrailingBracket = url =>
  TRAILING_BRACKET_PAIRS.find(
    ([openBracket, closeBracket]) =>
      url.endsWith(closeBracket) &&
      countCharacter(url, closeBracket) > countCharacter(url, openBracket)
  );

const trimTrailingUrlPunctuation = value => {
  let url = value;
  let trailing = '';

  const trimMatch = url.match(TRAILING_PUNCTUATION_REGEX);
  if (trimMatch) {
    trailing = trimMatch[0];
    url = url.slice(0, -trailing.length);
  }

  let didTrimBracket = true;
  while (didTrimBracket) {
    const trailingBracket = getUnbalancedTrailingBracket(url);
    didTrimBracket = !!trailingBracket;

    if (trailingBracket) {
      const closeBracket = trailingBracket[1];
      url = url.slice(0, -1);
      trailing = `${closeBracket}${trailing}`;
    }
  }

  return { url, trailing };
};

const isImageUrl = value => {
  try {
    const url = new URL(value);
    return (
      ['http:', 'https:'].includes(url.protocol) &&
      IMAGE_EXTENSION_REGEX.test(url.pathname)
    );
  } catch {
    return false;
  }
};

export const formatImageLinksForWidget = (message = '') => {
  const markdownRanges = getMarkdownRanges(message);

  return message.replace(URL_REGEX, (match, offset) => {
    if (isInsideRange(offset, markdownRanges)) {
      return match;
    }

    const { url, trailing } = trimTrailingUrlPunctuation(match);
    if (!isImageUrl(url)) {
      return match;
    }

    return `[![Image](${url})](${url})${trailing}`;
  });
};
