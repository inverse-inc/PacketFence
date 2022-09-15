/**
* "$_switch_groups" store module
*/
import Vue from 'vue'
import { computed } from '@vue/composition-api'
import store, { types } from '@/store'
import api from './_api'

export const useStore = $store => {
  return {
    isLoading: computed(() => $store.getters['$_switch_groups/isLoading']),
    getList: () => $store.dispatch('$_switch_groups/all'),
    getListOptions: () => $store.dispatch('$_switch_groups/options'),
    createItem: params => $store.dispatch('$_switch_groups/createSwitchGroup', params),
    getItem: params => $store.dispatch('$_switch_groups/getSwitchGroup', params.id),
    getItemOptions: params => $store.dispatch('$_switch_groups/options', params.id),
    updateItem: params => $store.dispatch('$_switch_groups/updateSwitchGroup', params),
    deleteItem: params => $store.dispatch('$_switch_groups/deleteSwitchGroup', params.id),
  }
}

// Default values
const state = () => {
  return {
    cache: {}, // items details
    message: '',
    itemStatus: ''
  }
}

const getters = {
  isWaiting: state => [types.LOADING, types.DELETING].includes(state.itemStatus),
  isLoading: state => state.itemStatus === types.LOADING
}

const actions = {
  all: () => {
    const params = {
      sort: 'id',
      fields: ['id', 'description'].join(','),
      limit: 1000
    }
    return api.list(params).then(response => {
      return response.items
    })
  },
  options: ({ commit }, id) => {
    commit('ITEM_REQUEST')
    if (id) {
      return api.itemOptions(id).then(response => {
        commit('ITEM_SUCCESS')
        return response
      }).catch((err) => {
        commit('ITEM_ERROR', err.response)
        throw err
      })
    } else {
      return api.listOptions().then(response => {
        commit('ITEM_SUCCESS')
        return response
      }).catch((err) => {
        commit('ITEM_ERROR', err.response)
        throw err
      })
    }
  },
  getSwitchGroup: ({ state, commit }, id) => {
    commit('ITEM_REQUEST')
    if (state.cache[id]) {
      api.itemMembers(id).then(members => { // Always fetch members
        commit('ITEM_UPDATED', { id, prop: 'members', data: members })
      })
      return Promise.resolve(state.cache[id]).then(cache => JSON.parse(JSON.stringify(cache)))
    }
    return api.item(id).then(item => {
      commit('ITEM_REPLACED', item)
      api.itemMembers(id).then(members => { // Fetch members
        commit('ITEM_UPDATED', { id, prop: 'members', data: members })
      })
      return JSON.parse(JSON.stringify(state.cache[id]))
    }).catch((err) => {
      commit('ITEM_ERROR', err.response)
      throw err
    })
  },
  getSwitchGroupMembers: ({ state, commit }, id) => {
    commit('ITEM_REQUEST')
    return api.itemMembers(id).then(members => {
      commit('ITEM_UPDATED', { id, prop: 'members', data: members })
      return state.cache[id].members
    }).catch(err => {
      commit('ITEM_ERROR', err.response)
      throw err
    })
  },
  createSwitchGroup: ({ commit }, data) => {
    commit('ITEM_REQUEST')
    return api.create(data).then(response => {
      commit('ITEM_REPLACED', data)
      return response
    }).catch(err => {
      commit('ITEM_ERROR', err.response)
      throw err
    })
  },
  updateSwitchGroup: ({ commit }, data) => {
    commit('ITEM_REQUEST')
    return api.update(data).then(response => {
      commit('ITEM_REPLACED', data)
      return response
    }).catch(err => {
      commit('ITEM_ERROR', err.response)
      throw err
    })
  },
  deleteSwitchGroup: ({ commit }, id) => {
    commit('ITEM_REQUEST', types.DELETING)
    return api.delete(id).then(response => {
      commit('ITEM_DESTROYED', id)
      return response
    }).catch(err => {
      commit('ITEM_ERROR', err.response)
      throw err
    })
  },
  bulkImportAsync: ({ commit }, data) => {
    commit('ITEM_REQUEST')
    return api.bulkImportAsync(data).then(response => {
      const { data: { task_id } = {} } = response
      return store.dispatch('pfqueue/pollTaskStatus', { task_id }).then(response => {
        commit('ITEM_BULK_SUCCESS', response.items)
        return response
      })
    }).catch(err => {
      commit('ITEM_ERROR', err.response)
    })
  }
}

const mutations = {
  ITEM_REQUEST: (state, type) => {
    state.itemStatus = type || types.LOADING
    state.message = ''
  },
  ITEM_REPLACED: (state, data) => {
    state.itemStatus = types.SUCCESS
    Vue.set(state.cache, data.id, JSON.parse(JSON.stringify(data)))
  },
  ITEM_BULK_SUCCESS: (state, response) => {
    state.itemStatus = 'success'
    response.forEach(item => {
      if (item.status === 200 && item.item.id in state.cache) {
        Vue.set(state.cache, item.item.id, null)
      }
    })
  },
  ITEM_UPDATED: (state, params) => {
    state.itemStatus = types.SUCCESS
    if (params.id in state.cache) {
      Vue.set(state.cache[params.id], params.prop, params.data)
    }
  },
  ITEM_DESTROYED: (state, id) => {
    state.itemStatus = types.SUCCESS
    Vue.set(state.cache, id, null)
  },
  ITEM_ERROR: (state, response) => {
    state.itemStatus = types.ERROR
    if (response && response.data) {
      state.message = response.data.message
    }
  },
  ITEM_SUCCESS: (state) => {
    state.itemStatus = types.SUCCESS
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
