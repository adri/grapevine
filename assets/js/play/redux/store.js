import {combineReducers, createStore} from 'redux';

import {modalReducer} from "./modalReducer";
import {promptReducer} from "./promptReducer";
import {settingsReducer} from "./settingsReducer";
import {socketReducer} from "./socketReducer";

// Selectors

export const getModals = (state) => {
  return state.modal.modals;
};

export const getPromptState = (state) => {
  return state.prompt;
};

export const getPromptDisplayText = (state) => {
  return getPromptState(state).displayText;
};

export const getSettingsState = (state) => {
  return state.settings;
};

export const getSettingsFont = (state) => {
  return getSettingsState(state).font;
};

export const getSettingsFontSize = (state) => {
  return getSettingsState(state).fontSize;
};

export const getSettingsOpen = (state) => {
  return getSettingsState(state).open;
};

export const getSocketState = (state) => {
  return state.socket;
};

export const getSocketConnectionState = (state) => {
  return getSocketState(state).connected;
}

export const getSocketConnection = (state) => {
  return getSocketState(state).connection;
}

export const getSocketPromptType = (state) => {
  return getSocketState(state).options.promptType;
};

export const getSocketLines = (state) => {
  return getSocketState(state).lines;
};

export const getSocketGMCP = (state) => {
  return getSocketState(state).gmcp;
};

export const getSocketOAuth = (state) => {
  return getSocketState(state).oauth;
};

// Reducers

let rootReducer = combineReducers({
  modal: modalReducer,
  prompt: promptReducer,
  settings: settingsReducer,
  socket: socketReducer
});

export const store = createStore(
  rootReducer,
  window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
);
