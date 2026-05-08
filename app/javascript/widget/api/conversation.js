import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  return API.post(urlData.url, urlData.params);
};

const sendMessageAPI = async (
  content,
  replyTo = null,
  { customAttributes, additionalAttributes, labels } = {}
) => {
  const urlData = endPoints.sendMessage(content, replyTo, {
    customAttributes,
    additionalAttributes,
    labels,
  });
  return API.post(urlData.url, urlData.params);
};

const sendAttachmentAPI = async (
  attachment,
  { customAttributes, additionalAttributes, labels } = {}
) => {
  const urlData = endPoints.sendAttachment(attachment, {
    customAttributes,
    additionalAttributes,
    labels,
  });
  return API.post(urlData.url, urlData.params);
};

const getMessagesAPI = async ({ before, after }) => {
  const urlData = endPoints.getConversation({ before, after });
  return API.get(urlData.url, { params: urlData.params });
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${window.location.search}`);
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async () => {
  return API.post(
    `/api/v1/widget/conversations/transcript${window.location.search}`
  );
};
const toggleStatus = async () => {
  return API.get(
    `/api/v1/widget/conversations/toggle_status${window.location.search}`
  );
};

const setCustomAttributes = async customAttributes => {
  return API.post(
    `/api/v1/widget/conversations/set_custom_attributes${window.location.search}`,
    {
      custom_attributes: customAttributes,
    }
  );
};

const setAdditionalAttributes = async additionalAttributes => {
  return API.post(
    `/api/v1/widget/conversations/set_additional_attributes${window.location.search}`,
    {
      additional_attributes: additionalAttributes,
    }
  );
};

const deleteCustomAttribute = async customAttribute => {
  return API.post(
    `/api/v1/widget/conversations/destroy_custom_attributes${window.location.search}`,
    {
      custom_attribute: [customAttribute],
    }
  );
};

export {
  createConversationAPI,
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  sendEmailTranscript,
  toggleStatus,
  setCustomAttributes,
  setAdditionalAttributes,
  deleteCustomAttribute,
};
