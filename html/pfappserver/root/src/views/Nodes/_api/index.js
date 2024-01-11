import apiCall from '@/utils/api'

export default {
  all: params => {
    if (params.sort) {
      params.sort = params.sort.join(',')
    } else {
      params.sort = 'mac'
    }
    if (params.fields) {
      params.fields = params.fields.join(',')
    }
    return apiCall.get('nodes', { params }).then(response => {
      return response.data
    })
  },
  search: body => {
    return apiCall.post('nodes/search', body).then(response => {
      return response.data
    })
  },
  fingerbankCommunications: params => {
    return apiCall.post('nodes/fingerbank_communications', params).then(response => {
      return response.data.items
    })
  },
  node: body => {
    const get = body.quiet ? 'getQuiet' : 'get'
    return apiCall[get](['node', body.mac]).then(response => {
      return response.data.item
    })
  },
  fingerbankInfo: mac => {
    return apiCall.getQuiet(['node', mac, 'fingerbank_info']).then(response => {
      return response.data.item
    })
  },
  rapid7Info: mac => {
    return apiCall.getQuiet(['node', mac, 'rapid7']).then(response => {
      return response.data.item
    })
  },
  ip4logOpen: mac => {
    return apiCall.getQuiet(['ip4logs', 'open', mac]).then(response => {
      return response.data.item
    })
  },
  ip4logHistory: mac => {
    return apiCall.getQuiet(['ip4logs', 'history', mac]).then(response => {
      return response.data.items
    })
  },
  ip6logOpen: mac => {
    return apiCall.getQuiet(['ip6logs', 'open', mac]).then(response => {
      return response.data.item
    })
  },
  ip6logHistory: mac => {
    return apiCall.getQuiet(['ip6logs', 'history', mac]).then(response => {
      return response.data.items
    })
  },
  locationlogs: mac => {
    const search = {
      query: { op: 'and', values: [ { field: 'mac', op: 'equals', value: mac } ] },
      limit: 1000,
      cursor: '0'
    }
    return apiCall.post('locationlogs/search', search).then(response => {
      return response.data.items
    })
  },
  security_events: mac => {
    const search = {
      query: { op: 'and', values: [ { field: 'mac', op: 'equals', value: mac } ] },
      limit: 1000,
      cursor: '0',
      sortBy: 'start_date',
      sortDesc: false
    }
    return apiCall.post('security_events/search', search).then(response => {
      return response.data.items
    })
  },
  dhcpoption82: mac => {
    const search = {
      query: { op: 'and', values: [ { field: 'mac', op: 'equals', value: mac } ] },
      limit: 100,
      cursor: '0'
    }
    return apiCall.post('dhcp_option82s/search', search).then(response => {
      return response.data.items
    })
  },
  createNode: body => {
    const post = body.quiet ? 'postQuiet' : 'post'
    return apiCall[post]('nodes', body).then(response => {
      return response.data
    })
  },
  updateNode: body => {
    const patch = body.quiet ? 'patchQuiet' : 'patch'
    return apiCall[patch](['node', body.mac], body).then(response => {
      return response.data
    })
  },
  deleteNode: mac => {
    return apiCall.delete(['node', mac])
  },
  applySecurityEventNode: data => {
    return apiCall.put(['node', data.mac, 'apply_security_event'], data).then(response => {
      return response.data
    })
  },
  clearSecurityEventNode: data => {
    return apiCall.put(['node', data.mac, 'close_security_event'], data).then(response => {
      return response.data
    })
  },
  reevaluateAccessNode: mac => {
    return apiCall.putQuiet(['node', mac, 'reevaluate_access']).then(response => {
      return response.data
    })
  },
  refreshFingerbankNode: mac => {
    return apiCall.putQuiet(['node', mac, 'fingerbank_refresh']).then(response => {
      return response.data
    })
  },
  restartSwitchportNode: mac => {
    return apiCall.putQuiet(['node', mac, 'restart_switchport']).then(response => {
      return response.data
    })
  },
  bulkRegisterNodes: body => {
    return apiCall.put(['nodes', 'bulk_register'], body).then(response => {
      return response.data.items
    })
  },
  bulkDeregisterNodes: body => {
    return apiCall.put(['nodes', 'bulk_deregister'], body).then(response => {
      return response.data.items
    })
  },
  bulkApplySecurityEvent: body => {
    return apiCall.put(['nodes', 'bulk_apply_security_event'], body).then(response => {
      return response.data.items
    })
  },
  bulkCloseSecurityEvents: body => {
    return apiCall.put(['nodes', 'bulk_close_security_events'], body).then(response => {
      return response.data.items
    })
  },
  bulkApplyBypassAcls: body => {
    return apiCall.put(['nodes', 'bulk_apply_bypass_acls'], body).then(response => {
      return response.data.items
    })
  },
  bulkApplyBypassRole: body => {
    return apiCall.put(['nodes', 'bulk_apply_bypass_role'], body).then(response => {
      return response.data.items
    })
  },
  bulkApplyBypassVlan: body => {
    return apiCall.put(['nodes', 'bulk_apply_bypass_vlan'], body).then(response => {
      return response.data.items
    })
  },
  bulkApplyRole: body => {
    return apiCall.put(['nodes', 'bulk_apply_role'], body).then(response => {
      return response.data.items
    })
  },
  bulkReevaluateAccess: body => {
    return apiCall.put(['nodes', 'bulk_reevaluate_access'], body).then(response => {
      return response.data.items
    })
  },
  bulkRefreshFingerbank: body => {
    return apiCall.put(['nodes', 'bulk_fingerbank_refresh'], body).then(response => {
      return response.data.items
    })
  },
  bulkRestartSwitchport: body => {
    return apiCall.put(['nodes', 'bulk_restart_switchport'], body).then(response => {
      return response.data.items
    })
  },
  bulkImport: body => {
    return apiCall.put(['nodes', 'bulk_import'], body).then(response => {
      return response.data.items
    })
  },
  perDeviceClass: () => {
    return apiCall.get('nodes/per_device_class').then(response => {
      return response.data
    })
  }
}
