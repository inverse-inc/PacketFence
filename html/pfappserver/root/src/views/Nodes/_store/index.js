/**
* "$_nodes" store module
*/
import Vue from 'vue'
import { computed } from '@vue/composition-api'
import api from '../_api'
import store from '@/store'
import i18n from '@/utils/locale'
import {
  normalizeMac,
  recomposeNode
} from '../_config/'

export const useStore = $store => {
  return {
    isLoading: computed(() => $store.getters['$_nodes/isLoading']),
    sortedSecurityEvents: computed(() => $store.getters['config/sortedSecurityEvents']),
    reloadItem: params => $store.dispatch('$_nodes/refreshNode', params.id),
    deleteItem: params => $store.dispatch('$_nodes/deleteNode', params.id),
    getItem: params => $store.dispatch('$_nodes/getNode', normalizeMac(params.id)),
    createItem: params => $store.dispatch('$_nodes/createNode', recomposeNode(params)),
    updateItem: params => $store.dispatch('$_nodes/updateNode', recomposeNode(params)),
    reevaluateAccess: params => $store.dispatch('$_nodes/reevaluateAccessNode', params.id),
    refreshFingerbank: params => $store.dispatch('$_nodes/refreshFingerbankNode', params.id),
    restartSwitchport: params => $store.dispatch('$_nodes/restartSwitchportNode', params.id),
    applySecurityEvent: params => $store.dispatch('$_nodes/applySecurityEventNode', params)
  }
}

// Default values
const state = () => {
  return {
    nodes: {}, // nodes details
    nodeExists: {}, // node exists true|false
    nodePerDeviceClass: [],
    message: '',
    nodeStatus: ''
  }
}

const getters = {
  isLoading: state => state.nodeStatus === 'loading',
  perDeviceClass: state => state.nodePerDeviceClass.reduce((assoc, item) => {
    return { ...assoc, [item.device_class]: item.count }
  }, {}),
  perDeviceClassLowerCase: state => state.nodePerDeviceClass.reduce((assoc, item) => {
    return { ...assoc, [item.device_class.toLowerCase()]: item.count }
  }, {}),
}

const actions = {
  exists: ({ state, commit }, mac) => {
    if (mac in state.nodeExists) {
      if (state.nodeExists[mac]) {
        return Promise.resolve(true)
      }
      return Promise.reject(new Error('Unknown MAC'))
    }
    let body = {
      fields: ['mac'],
      limit: 1,
      query: {
        op: 'and',
        values: [{
          field: 'mac', op: 'equals', value: mac
        }]
      }
    }
    return new Promise((resolve, reject) => {
      api.search(body).then(response => {
        if (response.items.length > 0) {
          commit('NODE_EXISTS', mac)
          resolve(true)
        } else {
          commit('NODE_NOT_EXISTS', mac)
          reject(new Error('Unknown MAC'))
        }
      }).catch(err => {
        reject(err)
      })
    })
  },
  getNode: ({ state, commit }, mac) => {
    /* Fix #5334, always fetch a fresh copy
    if (state.nodes[mac]) {
      return Promise.resolve(state.nodes[mac])
    }
    */
    let node = {}
    commit('NODE_REQUEST')
    return api.node({ quiet: true, mac }).then(data => {
      Object.assign(node, data)
      if (node.status === null) {
        node.status = 'unreg'
      }
      commit('NODE_REPLACED', node)

      // search extra columns (eg: 'online')
      const search = {
        fields: ['online'],
        query: { op: 'and', values: [{ field: 'mac', op: 'equals', value: mac }] },
        limit: 1,
        cursor: '0'
      }
      api.search(search).then(response => {
        const { items: { 0: item } } = response
        Object.keys(item).map(prop => {
          commit('NODE_UPDATED', { mac, prop, data: item[prop] })
        })
      })

      // Fetch ip4log history
      let ip4 = {}
      api.ip4logOpen(mac).then(data => {
        Object.assign(ip4, data)
        ip4.active = data.end_time === '0000-00-00 00:00:00'
      }).catch(() => {
        Object.assign(ip4, { active: false })
      }).finally(() => {
        api.ip4logHistory(mac).then(datas => {
          if (datas && datas.length > 0) {
            Object.assign(ip4, { history: datas })
            if (!ip4.active && !ip4.end_time) {
              ip4.end_time = datas[0].end_time
            }
          }
        }).catch(() => {
          // noop
        }).finally(() => {
          commit('NODE_UPDATED', { mac, prop: 'ip4', data: ip4 })
        })
      })

      // Fetch ip6log history
      let ip6 = {}
      api.ip6logOpen(mac).then(data => {
        Object.assign(ip6, data)
        ip6.active = data.end_time === '0000-00-00 00:00:00'
      }).catch(() => {
        Object.assign(ip6, { active: false })
      }).finally(() => {
        api.ip6logHistory(mac).then(datas => {
          if (datas && datas.length > 0) {
            Object.assign(ip6, { history: datas })
            if (!ip6.active && !ip6.end_time) {
              ip6.end_time = datas[0].end_time
            }
          }
        }).catch(() => {
          // noop
        }).finally(() => {
          commit('NODE_UPDATED', { mac, prop: 'ip6', data: ip6 })
        })
      })

      // Fetch locationlogs
      api.locationlogs(mac).then(datas => {
        commit('NODE_UPDATED', { mac, prop: 'locations', data: datas })
      }).catch(() => {
        // noop
      })

      // Fetch security_events
      api.security_events(mac).then(datas => {
        commit('NODE_UPDATED', { mac, prop: 'security_events', data: datas })
      }).catch(() => {
        // noop
      })

      // Fetch fingerbank
      let fingerbank = {}
      api.fingerbankInfo(mac).then(data => {
        Object.assign(fingerbank, data)
      }).catch(() => {
        // noop
      }).finally(() => {
        commit('NODE_UPDATED', { mac, prop: 'fingerbank', data: fingerbank })
      })

      // Fetch dhcpoption82
      api.dhcpoption82(mac).then(items => {
        commit('NODE_UPDATED', { mac, prop: 'dhcpoption82', data: items })
      }).catch(() => {
        // noop
      })

      // Fetch Rapid7
      api.rapid7Info(mac).then(items => {
        commit('NODE_UPDATED', { mac, prop: 'rapid7', data: items })
      }).catch(() => {
        // noop
      })

      return state.nodes[mac]
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  refreshNode: ({ state, commit, dispatch }, mac) => {
    if (state.nodes[mac]) {
      commit('NODE_DESTROYED', mac)
    }
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      dispatch('getNode', mac).then(() => {
        commit('NODE_SUCCESS')
        resolve(state.nodes[mac])
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  createNode: ({ commit }, data) => {
    commit('NODE_REQUEST')
    const { unreg_date, unreg_time } = data
    if (unreg_date && unreg_time) {
      data.unregdate = `${unreg_date} ${unreg_time}`
    }
    return new Promise((resolve, reject) => {
      api.createNode(data).then(response => {
        commit('NODE_REPLACED', data)
        commit('NODE_EXISTS', data.mac)
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  updateNode: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.updateNode(data).then(response => {
        commit('NODE_REPLACED', data)
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  deleteNode: ({ commit }, mac) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.deleteNode(mac).then(response => {
        commit('NODE_DESTROYED', mac)
        commit('NODE_NOT_EXISTS', mac)
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  applySecurityEventNode: ({ commit, dispatch }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.applySecurityEventNode(data).then(response => {
        commit('NODE_DESTROYED', data.mac)
        dispatch('getNode', data.mac)
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  clearSecurityEventNode: ({ commit, dispatch }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.clearSecurityEventNode(data).then(response => {
        commit('NODE_DESTROYED', data.mac)
        dispatch('getNode', data.mac)
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        reject(err)
      })
    })
  },
  reevaluateAccessNode: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.reevaluateAccessNode(data).then(response => {
        if (response.status === 200) {
          commit('NODE_SUCCESS')
          store.dispatch('notification/info', { message: i18n.t('Node access reevaluation initialized') })
        } else {
          commit('NODE_ERROR')
          store.dispatch('notification/danger', { message: i18n.t('Node access reevaluation failed') })
        }
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        store.dispatch('notification/danger', { message: i18n.t('Node access reevaluation failed') })
        reject(err)
      })
    })
  },
  refreshFingerbankNode: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.refreshFingerbankNode(data).then(response => {
        if (response.status === 200) {
          commit('NODE_SUCCESS')
          store.dispatch('notification/info', { message: i18n.t('Node device profiling initialized') })
        } else {
          commit('NODE_ERROR')
          store.dispatch('notification/danger', { message: i18n.t('Node device profiling failed') })
        }
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        store.dispatch('notification/danger', { message: i18n.t('Node device profiling failed') })
        reject(err)
      })
    })
  },
  restartSwitchportNode: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return new Promise((resolve, reject) => {
      api.restartSwitchportNode(data).then(response => {
        if (response.status === 200) {
          commit('NODE_SUCCESS')
          store.dispatch('notification/info', { message: i18n.t('Node switchport restarted') })
        } else {
          commit('NODE_ERROR')
          store.dispatch('notification/danger', { message: i18n.t('Node switchport restart failed') })
        }
        resolve(response)
      }).catch(err => {
        commit('NODE_ERROR', err.response)
        store.dispatch('notification/danger', { message: i18n.t('Node switchport restart failed') })
        reject(err)
      })
    })
  },
  bulkRegisterNodes: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkRegisterNodes(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkDeregisterNodes: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkDeregisterNodes(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkApplySecurityEvent: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkApplySecurityEvent(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkCloseSecurityEvents: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkCloseSecurityEvents(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkApplyBypassAcls: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkApplyBypassAcls(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkApplyBypassRole: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkApplyBypassRole(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkApplyBypassVlan: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkApplyBypassVlan(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkApplyRole: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkApplyRole(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkReevaluateAccess: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkReevaluateAccess(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkRefreshFingerbank: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkRefreshFingerbank(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkRestartSwitchport: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkRestartSwitchport(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  bulkImport: ({ commit }, data) => {
    commit('NODE_REQUEST')
    return api.bulkImport(data).then(response => {
      commit('NODE_BULK_SUCCESS', response)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  },
  getPerDeviceClass: ({ commit }) => {
    commit('NODE_REQUEST')
    return api.perDeviceClass().then(response => {
      commit('NODE_PER_DEVICE_CLASS', response.items)
      return response
    }).catch(err => {
      commit('NODE_ERROR', err.response)
    })
  }
}

const mutations = {
  NODE_REQUEST: (state) => {
    state.nodeStatus = 'loading'
    state.message = ''
  },
  NODE_REPLACED: (state, data) => {
    state.nodeStatus = 'success'
    if (!('fingerbank' in data)) data.fingerbank = {}
    if ('unregdate' in data && data.unregdate === '0000-00-00 00:00:00') data.unregdate = ''
    Vue.set(state.nodes, data.mac, data)
    // TODO: update items if found in it
  },
  NODE_UPDATED: (state, params) => {
    state.nodeStatus = 'success'
    if (params.mac in state.nodes) {
      Vue.set(state.nodes[params.mac], params.prop, params.data)
    }
  },
  NODE_BULK_SUCCESS: (state, response) => {
    state.nodeStatus = 'success'
    response.forEach(item => {
      if (item.status === 'success' && item.mac in state.nodes) {
        Vue.set(state.nodes, item.mac, null)
      }
    })
  },
  NODE_DESTROYED: (state, mac) => {
    state.nodeStatus = 'success'
    Vue.set(state.nodes, mac, null)
  },
  NODE_SUCCESS: (state) => {
    state.nodeStatus = 'success'
  },
  NODE_ERROR: (state, response) => {
    state.nodeStatus = 'error'
    if (response && response.data) {
      state.message = response.data.message
    }
  },
  NODE_EXISTS: (state, mac) => {
    Vue.set(state.nodeExists, mac, true)
  },
  NODE_NOT_EXISTS: (state, mac) => {
    Vue.set(state.nodeExists, mac, false)
  },
  NODE_PER_DEVICE_CLASS: (state, deviceClasses) => {
    state.nodePerDeviceClass = deviceClasses
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
