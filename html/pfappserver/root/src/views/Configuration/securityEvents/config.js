import { pfFieldType as fieldType } from '@/globals/pfField'
import bytes from '@/utils/bytes'
import i18n from '@/utils/locale'

export const triggerCategories = {
  ENDPOINT: 'endpoint',
  PROFILING: 'profiling',
  USAGE: 'usage',
  EVENT: 'event'
}

export const triggerCategoryTitles = {
  [triggerCategories.ENDPOINT]: i18n.t('Endpoint'),
  [triggerCategories.PROFILING]: i18n.t('Device Profiling'),
  [triggerCategories.USAGE]: i18n.t('Usage'),
  [triggerCategories.EVENT]: i18n.t('Event')
}

export const triggerFields = {
  accounting: {
    text: i18n.t('Accounting'),
    category: triggerCategories.USAGE
  },
  custom: {
    text: i18n.t('Custom'),
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  detect: {
    text: i18n.t('Detect'),
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  device: {
    text: i18n.t('Device'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  device_is_not: {
    text: i18n.t('Device is not'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  dhcp_fingerprint: {
    text: i18n.t('DHCP Fingerprint'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  dhcp_vendor: {
    text: i18n.t('DHCP Vendor'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  dhcp6_fingerprint: {
    text: i18n.t('DHCPv6 Fingerprint'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  dhcp6_enterprise: {
    text: i18n.t('DHCPv6 Enterprise'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  internal: {
    text: i18n.t('Internal'),
    category: triggerCategories.EVENT,
    types: [fieldType.OPTIONS]
  },
  mac: {
    text: i18n.t('MAC Address'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.SUBSTRING]
  },
  mac_vendor: {
    text: i18n.t('MAC Vendor'),
    category: triggerCategories.PROFILING,
    types: [fieldType.OPTIONS]
  },
  nessus: {
    text: 'Nessus',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  nessus6: {
    text: 'Nessus v6',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  nexpose_event_contains: {
    text: i18n.t('Nexpose event contains ..'),
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  nexpose_event_starts_with: {
    text: i18n.t('Nexpose event starts with ..'),
    category: triggerCategories.EVENT,
    types: [fieldType.OPTIONS]
  },
  openvas: {
    text: 'OpenVAS',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  provisioner: {
    text: i18n.t('Provisioner'),
    category: triggerCategories.EVENT,
    types: [fieldType.OPTIONS]
  },
  role: {
    text: i18n.t('Role'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.OPTIONS]
  },
  vlan: {
    text: i18n.t('VLAN'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.SUBSTRING]
  },
  network: {
    text: i18n.t('Network'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.SUBSTRING]
  },
  suricata_event: {
    text: i18n.t('Suricata Event'),
    category: triggerCategories.EVENT,
    types: [fieldType.OPTIONS]
  },
  suricata_md5: {
    text: 'Suricata MD5',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  fleetdm_policy: {
    text: 'FleetDM Policy Violation Regex ...',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  fleetdm_cve: {
    text: 'FleetDM Vulnerability CVE Regex ...',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  fleetdm_cve_severity_gte: {
    text: 'FleetDM Vulnerability CVE Severity Gte ...',
    category: triggerCategories.EVENT,
    types: [fieldType.SUBSTRING]
  },
  switch: {
    text: i18n.t('Switch'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.OPTIONS]
  },
  switch_group: {
    text: i18n.t('Switch Group'),
    category: triggerCategories.ENDPOINT,
    types: [fieldType.OPTIONS]
  }
}

export const triggerDirections = {
  TOT: i18n.t('Total'),
  IN: i18n.t('Inbound'),
  OUT: i18n.t('Outbound')
}
export const triggerDirectionOptions = Object.keys(triggerDirections).map(key => ({ value: key, text: triggerDirections[key] }))

export const triggerIntervals = {
  D: i18n.t('Day'),
  W: i18n.t('Week'),
  M: i18n.t('Month'),
  Y: i18n.t('Year')
}
export const triggerIntervalOptions = Object.keys(triggerIntervals).map(key => ({ value: key, text: triggerIntervals[key] }))

export const triggerTypes = {
  bandwidth: i18n.t('Bandwidth Limit'),
  BandwidthExpired: i18n.t('Bandwidth balance has expired'),
  TimeExpired: i18n.t('Time balance has expired')
}
export const triggerTypeOptions = Object.keys(triggerTypes).map(key => ({ value: key, text: triggerTypes[key] }))

export const decomposeTriggers = (triggers) => {
  return (triggers || []).map(trigger => {
    let decomposed = { endpoint: { conditions: [] }, profiling: { conditions: [] }, usage: {}, event: {} }
    for (let type in trigger) {
      const { [type]: value } = trigger
      if (value && value.length) {
        if (type in triggerFields) {
          let { [type]: { category } = {} } = triggerFields
          if ('conditions' in decomposed[category])
            decomposed[category].conditions.push({ type, value }) // 'endpoint' or 'profiling'
          else
            decomposed[category] = { typeValue: { type, value } } // 'usage' or 'event'
          if (category === triggerCategories.USAGE) {
            if (value === 'BandwidthExpired' || value === 'TimeExpired')
              decomposed[category].type = value
            else {
              // Try to decompose data usage
              const { groups = null } = value.match(/(?<direction>TOT|IN|OUT)(?<limit>[0-9]+)(?<multiplier>[KMG]?)B(?<interval>[DWMY])/)
              if (groups) {
                decomposed[category].type = 'bandwidth'
                decomposed[category].direction = groups.direction
                decomposed[category].limit = groups.limit * Math.pow(1024, 'KMG'.indexOf(groups.multiplier) + 1)
                decomposed[category].interval = groups.interval
              }
            }
          }
          else if (category === triggerCategories.EVENT && type === 'internal') {
            // Extract network behavior policy name
            let match = /(fingerbank_diff_score_too_low|fingerbank_blacklisted_ips_threshold_too_high|fingerbank_blacklisted_ports)_(.+)/.exec(value)
            if (match) {
              decomposed[category].typeValue.value = match[1]
              decomposed[category].typeValue.fingerbank_network_behavior_policy = match[2]
            }
            else
              decomposed[category].typeValue.fingerbank_network_behavior_policy = 'all'
          }
        }
        else
          throw new Error(`Uncategorized field type: ${type}`)
      }
    }
    return decomposed
  })
}

export const recomposeTriggers = (triggers = []) => {
  return triggers.map(trigger => {
    let recomposed = Object.keys(triggerFields).reduce((a, v) => ({ ...a, [v]: null }), {})
    for (let category in trigger) {
      if ([triggerCategories.ENDPOINT, triggerCategories.PROFILING].includes(category)) { // 'endpoint' or 'profiling'
        const { [category]: { conditions = [] } = {} } = trigger
        for (let condition of conditions) {
          const { type, value } = condition || {}
          if (type && value) {
            const { value: nestedValue } = value || {}
            if (nestedValue)
              recomposed[type] = nestedValue
            else
              recomposed[type] = value
          }
        }
      }
      if ([triggerCategories.USAGE, triggerCategories.EVENT].includes(category)) { // 'usage' or 'event'
        if (category === triggerCategories.USAGE) { // normalize 'usage'
          const { [category]: { direction, limit, interval, type } = {} } = trigger
          trigger[triggerCategories.USAGE]['typeValue'] = {
            type: 'accounting',
            value: (direction && limit && interval)
              ? `${direction}${bytes.toHuman(limit, 0, true).replace(/ /, '').toUpperCase()}B${interval}`
              : type
          }
        }
        else if (category === triggerCategories.EVENT) {
          // Append network behavior policy name
          const { [category]: { typeValue: { type, value, fingerbank_network_behavior_policy } = {} } = {} } = trigger
          if (type === 'internal' && fingerbank_network_behavior_policy !== 'all' && fingerbankNetworkBehaviorPolicyTypes.includes(value))
            trigger[category].typeValue.value += `_${fingerbank_network_behavior_policy}`
        }
        const { [category]: { typeValue: { type, value } = {} } = {} } = trigger
        if (type && value)
          recomposed[type] = value
      }
    }
    return recomposed
  })
}

export const fingerbankNetworkBehaviorPolicyTypes = [
  'fingerbank_diff_score_too_low',
  'fingerbank_blacklisted_ips_threshold_too_high',
  'fingerbank_blacklisted_ports'
]

export const analytics = {
  track: ['id']
}
