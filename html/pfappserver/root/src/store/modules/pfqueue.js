/**
* "pfqueue" store module
*/
import Vue from 'vue'
import { types } from '@/store'
import apiCall from '@/utils/api'
import i18n from '@/utils/locale'

const retries = {} // global retry counter

// number of retries before giving up
const POLL_RETRY_NUM = 20

// delay between retries (seconds)
const POLL_RETRY_INTERVAL = 3

const retry = ({ task_id, headers, expect }) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => { // debounce retries
      pollTaskStatus({ task_id, headers, expect })
        .then(resolve)
        .catch(err => {
          if (err.message) { // AxiosError
            const data = i18n.t('{message}. No response after {timeout} seconds, gave up after {retries} retries.', { message: err.message, timeout: POLL_RETRY_NUM * POLL_RETRY_INTERVAL, retries: POLL_RETRY_NUM })
            reject({ response: { data } })
          }
          else { // recursion
            reject(err)
          }
        })
    }, POLL_RETRY_INTERVAL * 1E3)
  })
}

const pollTaskStatus = ({ task_id, headers, expect }) => {
  return apiCall.getQuiet(`pfqueue/task/${task_id}/status/poll`, { headers }).then(response => {
    if (expect && !expect(response.data)) { // handle unexpected response
      if (!(task_id in retries))
        retries[task_id] = 0
      else
        retries[task_id]++
      if (retries[task_id] >= POLL_RETRY_NUM) // give up after N retries
        throw new Error('Unexpected response')
      return retry({ task_id, headers, expect })
    }
    if (task_id in retries)
      delete retries[task_id]
    return response.data
  }).catch(error => {
    if (error.code == 'ERR_CERT_COMMON_NAME_INVALID') { // server certificate changed, hard reload
      location.reload(true)
    }
    else if (error.response && !['ERR_BAD_RESPONSE', 'ERR_NETWORK'].includes(error.code)) { // The request was made and a response with a status code was received
      throw error
    }
    else {
      if (!(task_id in retries))
        retries[task_id] = 0
      else
        retries[task_id]++
      if (retries[task_id] >= POLL_RETRY_NUM) // give up after N retries
        throw error
      return retry({ task_id, headers, expect })
    }
  })
}

const api = {
  getStats: () => {
    return apiCall.getQuiet(`queues/stats`).then(response => {
      return response.data.items
    })
  },
  pollTaskStatus
}

// Default values
const initialState = () => {
  return {
    stats: false,
    tasks: false,
    message: '',
    requestStatus: ''
  }
}

const getters = {
  isLoading: state => state.requestStatus === types.LOADING,
  stats: state => state.stats || []
}

const actions = {
  getStats: ({ commit, state }) => {
    commit('PFQUEUE_REQUEST')
    return new Promise((resolve, reject) => {
      api.getStats().then(data => {
        commit('PFQUEUE_SUCCESS', data)
        resolve(state.stats)
      }).catch(err => {
        commit('PFQUEUE_ERROR', err.response)
        reject(err)
      })
    })
  },
  pollTaskStatus: ({ dispatch }, { task_id, headers, expect }) => {
    return api.pollTaskStatus({ task_id, headers, expect }).then(data => { // 'poll' returns immediately, or timeout after 15s
      if ('status' in data && data.status.toString() === '202') { // 202: in progress
        return dispatch('pollTaskStatus', { task_id, headers, expect }) // recurse
      }
      if ('error' in data) {
        throw new Error(data.error.message)
      }
      return data.item
    }).catch(error => {
      throw error
    })
  }
}

const mutations = {
  PFQUEUE_REQUEST: (state) => {
    state.requestStatus = types.LOADING
    state.message = ''
  },
  PFQUEUE_SUCCESS: (state, data) => {
    Vue.set(state, 'stats', data)
    state.requestStatus = types.SUCCESS
    state.message = ''
  },
  PFQUEUE_ERROR: (state, data) => {
    state.requestStatus = types.ERROR
    const { response: { data: { message } = {} } = {} } = data
    if (message) {
      state.message = message
    }
  },
  $RESET: (state) => {
    // eslint-disable-next-line no-unused-vars
    state = initialState()
  }
}

export default {
  namespaced: true,
  state: initialState(),
  getters,
  actions,
  mutations
}
