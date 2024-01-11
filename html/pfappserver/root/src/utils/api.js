import axios from 'axios'
import store from '@/store'
import i18n from '@/utils/locale'
import { v4 as uuidv4 } from 'uuid'

export const baseURL = (process.env.VUE_APP_API_BASEURL)
  ? process.env.VUE_APP_API_BASEURL
  : '/api/v1/'

const apiCall = axios.create({
  baseURL
})

/**
 * Remap some aliases to accept an array as the URL.
 * When the URL is an array, each segment will be URL-encoded before building the final URL.
 */

function _encodeURL (url) {
  if (Array.isArray(url)) {
    return url.map(segment => encodeURIComponent(`${segment}`)).join('/')
  }
  return url
}

const methodsWithoutData = ['get', 'head', 'options']
methodsWithoutData.forEach((method) => {
  apiCall[method] = (url, config = {}) => {
    url = _encodeURL(url)
    if (config.nocache) {
      url += `?nocache=${uuidv4()}`
    }
    return apiCall.request({ ...config, method, url })
  }
})

const methodsWithData = ['post', 'put', 'patch', 'delete']
methodsWithData.forEach((method) => {
  apiCall[method] = (url, data, config = {}) => {
    return apiCall.request({ ...config, method, url: _encodeURL(url), data })
  }
})

/**
 * Add new "quiet" methods that won't trigger any message in the notification center.
 */

Object.assign(apiCall, {
  deleteQuiet (url) {
    return this.request({
      method: 'delete',
      url: _encodeURL(url),
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          jsonData = {}
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  },
  getArrayBuffer (url) {
    return this.request({
      responseType: 'arraybuffer',
      method: 'get',
      url: _encodeURL(url)
    })
  },
  getQuiet (url, config) {
    return this.request({
      method: 'get',
      url: _encodeURL(url),
      ...config,
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          // response likely a non-JSON error
          jsonData = { message: data }
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  },
  optionsQuiet (url) {
    return this.request({
      method: 'options',
      url: _encodeURL(url),
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          jsonData = {}
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  },
  patchQuiet (url, data) {
    return this.request({
      method: 'patch',
      url: _encodeURL(url),
      data,
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          jsonData = {}
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  },
  postQuiet(url, data, config) {
    return this.request({
      method: 'post',
      url: _encodeURL(url),
      data,
      ...config,
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          jsonData = {}
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  },
  putQuiet (url, data) {
    return this.request({
      method: 'put',
      url: _encodeURL(url),
      data,
      transformResponse: [data => {
        let jsonData
        try {
          jsonData = JSON.parse(data)
        } catch (e) {
          jsonData = {}
        }
        return Object.assign({ quiet: true }, jsonData)
      }]
    })
  }
})

/**
 * Intercept requests
 */

apiCall.interceptors.request.use(request => {
  const apiServer = localStorage.getItem('X-PacketFence-Server') || null
  if (apiServer && !('X-PacketFence-Server' in request.headers)) {
    request.headers['X-PacketFence-Server'] = apiServer
  }
  return request
})

/**
 * Intercept responses to
 *
 * - detect messages in payload and display them in the notification center;
 * - detect if the token has expired;
 * - detect errors assigned to specific form fields.
 */

apiCall.interceptors.response.use((response) => {
  /* Intercept successful API call */
  const { config: { url } = {}, data: { message, warnings, quiet } = {} } = response
  if (message && !quiet) {

    store.dispatch('notification/info', { message, url: decodeURIComponent(url) })
  }
  if (warnings && !quiet) {
    warnings.forEach(warning => {
      const { message } = warning
      store.dispatch('notification/warning', { message, url: decodeURIComponent(url) })
    })
  }
  store.commit('session/API_OK')
  return response
}, (error) => {
  /* Intercept failed API call */
  const { config = {} } = error
  let icon = 'exclamation-triangle'
  if (error.response) {
    if (error.response.status === 401 || // unauthorized
      (error.response.status === 404 && /token_info/.test(config.url))) {
      // Token has expired
      if (!error.response.data.quiet) {
        store.commit('session/EXPIRED')
        // Reply request once the session is restored
        return store.dispatch('session/resolveLogin').then(() => {
          const { method, url, params, data } = config
          return apiCall.request({ method, baseURL: '', url, params, data, headers: { 'X-Replay': 'true' } })
        })
      }
    } else if (config.method === 'delete' && error.response.status === 417) { // foreign-key constraint failure
      const message = i18n.t('A database foreign key constraint prevented the deletion of this resource. See <code>packetfence.log</code> for more information about the specific constraint(s). Use the MySQL CLI to resolve these constraints manually before trying again.')
      store.dispatch('notification/danger', { icon: 'lock', url: decodeURIComponent(config.url), message })
    } else if (error.response.data) {
      switch (error.response.status) {
        case 401:
          icon = 'ban'
          break
        case 404:
          icon = 'unlink'
          break
        case 503:
          store.commit('session/API_ERROR')
          break
      }
      if (!error.response.data.quiet) {
        // eslint-disable-next-line
        console.group('API error')
        // eslint-disable-next-line
        console.warn(error.response.data)
        if (error.response.data.errors) {
          error.response.data.errors.forEach(error => {
            let message = `${error['field']}: ${error['message']}`
            // eslint-disable-next-line
            console.warn(message)
            store.dispatch('notification/danger', { icon, url: decodeURIComponent(config.url), message })
          })
        }
        // eslint-disable-next-line
        console.groupEnd()
      }
      if (['patch', 'post', 'put', 'delete'].includes(config.method) && error.response.data.errors) {
        let apiErrors = {}
        error.response.data.errors.forEach((err) => {
          apiErrors[err['field']] = err['message']
        })
        if (Object.keys(apiErrors).length > 0) {
          store.commit('session/API_ERRORS', apiErrors)
        }
      }
      if (typeof error.response.data === 'string') {
        store.dispatch('notification/danger', { icon, url: decodeURIComponent(config.url), message: error.message })
      } else if (error.response.data.message && !error.response.data.quiet) {
        store.dispatch('notification/danger', { icon, url: decodeURIComponent(config.url), message: error.response.data.message })
      }
    }
  } else if (error.request) {
    const { transformResponse: [firstTransform] = [] } = error.config
    let quiet = false
    if (firstTransform) {
      quiet = firstTransform().quiet
    }
    if (!quiet) {
      store.commit('session/API_ERROR')
      store.dispatch('notification/danger', { url: decodeURIComponent(config.url), message: 'API server seems down' })
    }
  }
  return Promise.reject(error)
})

/**
 * Axios instance to access documentation guides
 */
export const documentationCall = axios.create({
  baseURL: '/static/doc/'
})

/**
 * File Upload response filter,
 *  input a JSON response object
 *  returns a filtered JSON object, includes only keys matching /(.*)_path$/
 */
export const fileUploadPaths = response => {
  const filtered = {}
  Object.entries(response).forEach(([k, v]) => {
    if (/([a-zA-Z0-9_])_path$/i.test(k) && v) { // path is defined
      filtered[k] = v // forward path
      filtered[`${k}_upload`] = undefined // delete upload
    }
  })
  return filtered
}

export default apiCall
