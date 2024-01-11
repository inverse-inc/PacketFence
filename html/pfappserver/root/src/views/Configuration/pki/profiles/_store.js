import { computed } from '@vue/composition-api'
import store, { types } from '@/store'
import api from './_api'

export const useStore = $store => {
  return {
    isLoading: computed(() => $store.getters['$_pkis/isProfileLoading']),
    getList: () => $store.dispatch('$_pkis/allProfiles'),
    createItem: params => $store.dispatch('$_pkis/createProfile', params),
    getItem: params => $store.dispatch('$_pkis/getProfile', params.id),
    updateItem: params => $store.dispatch('$_pkis/updateProfile', params),
    signCsr: params => $store.dispatch('$_pkis/signCsr', params),
  }
}

// Default values
export const state = () => {
  return {
    profileListCache: false, // profile list details
    profileItemCache: {}, // profile item details
    profileMessage: '',
    profileStatus: '',
  }
}

export const getters = {
  isProfileWaiting: state => [types.LOADING, types.DELETING].includes(state.profileStatus),
  isProfileLoading: state => state.profileStatus === types.LOADING,
  profiles: state => state.profileListCache
}

export const actions = {
  allProfiles: ({ state, commit }) => {
    if (state.profileListCache) {
      return Promise.resolve(state.profileListCache)
    }
    commit('PROFILE_REQUEST')
    return api.list().then(response => {
      commit('PROFILE_LIST_REPLACED', response.items)
      return state.profileListCache
    }).catch((err) => {
      commit('PROFILE_ERROR', err.response)
      throw err
    })
  },
  getProfile: ({ state, commit }, id) => {
    if (state.profileItemCache[id]) {
      return Promise.resolve(state.profileItemCache[id])
    }
    commit('PROFILE_REQUEST')
    return api.item(id).then(item => {
      commit('PROFILE_ITEM_REPLACED', item)
      return state.profileItemCache[id]
    }).catch((err) => {
      commit('PROFILE_ERROR', err.response)
      throw err
    })
  },
  createProfile: ({ commit, dispatch }, data) => {
    commit('PROFILE_REQUEST')
    return api.create(data).then(item => {
      // reset list
      commit('PROFILE_LIST_RESET')
      dispatch('allProfiles')
      // update item
      commit('PROFILE_ITEM_REPLACED', item)
      return item
    }).catch(err => {
      commit('PROFILE_ERROR', err.response)
      throw err
    })
  },
  updateProfile: ({ commit, dispatch }, data) => {
    commit('PROFILE_REQUEST')
    return api.update(data).then(item => {
      // reset list
      commit('PROFILE_LIST_RESET')
      dispatch('allProfiles')
      // update item
      commit('PROFILE_ITEM_REPLACED', item)
      return item
    }).catch(err => {
      commit('PROFILE_ERROR', err.response)
      throw err
    })
  },
  signCsr: ({ commit, dispatch }, data) => {
    commit('PROFILE_REQUEST')
    return api.signCsr(data).then(item => {
      // reset list
      commit('PROFILE_LIST_RESET')
      dispatch('allProfiles')
      // update item
      commit('PROFILE_CSR_SIGNED', item)
      return item
    }).catch(err => {
      commit('PROFILE_ERROR', err.response)
      throw err
    })
  }
}

export const mutations = {
  PROFILE_REQUEST: (state, type) => {
    state.profileStatus = type || types.LOADING
    state.profileMessage = ''
  },
  PROFILE_LIST_RESET: (state) => {
    state.profileListCache = false
  },
  PROFILE_LIST_REPLACED: (state, items) => {
    state.profileStatus = types.SUCCESS
    state.profileListCache = items
  },
  PROFILE_ITEM_REPLACED: (state, data) => {
    state.profileStatus = types.SUCCESS
    state.profileItemCache[data.id] = data
    store.dispatch('config/resetPkiProfiles')
  },
  PROFILE_ERROR: (state, response) => {
    state.profileStatus = types.ERROR
    if (response && response.data) {
      state.profileMessage = response.data.message
    }
  },
  PROFILE_CSR_SIGNED: (state) => {
    state.profileStatus = types.SUCCESS
  }
}
