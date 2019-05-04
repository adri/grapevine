import _ from "underscore";
import Anser from "anser";
import {createReducer} from "reduxsauce";

import {Types} from "./actions";

const INITIAL_STATE = {
  modals: [],
}

class Modal {
  constructor(attrs) {
    this.key = attrs.key;
    this.title = attrs.title;
    this.segments = Anser.ansiToJson(attrs.body);
  }
}

export const modalOpen = (state, action) => {
  let modal = new Modal(action.data);
  return {...state, modals: [...state.modals, modal]};
}

export const modalReceiveGMCP = (state, action) => {
  switch (action.message) {
    case "Client.Modals.Open":
      return modalOpen(state, action);

    default:
      return state;
  }
};

export const HANDLERS = {
  [Types.SOCKET_RECEIVE_GMCP]: modalReceiveGMCP,
}

export const modalReducer = createReducer(INITIAL_STATE, HANDLERS);
