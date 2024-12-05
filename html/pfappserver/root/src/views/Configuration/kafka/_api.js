import apiCall from '@/utils/api'

export default {
  item: () => {
    return apiCall.get(['config', 'kafka']).then(response => {
      return response.data.item
    })
  },
  itemOptions: () => {
    return apiCall.options(['config', 'kafka']).then(response => {
      return response.data
    })
  },
  update: data => {
    const patch = data.quiet ? 'patchQuiet' : 'patch'
    return apiCall[patch](['config', 'kafka'], data).then(response => {
      return response.data
    })
  }
}
