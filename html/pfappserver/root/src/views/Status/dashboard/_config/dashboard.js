import { libraries, palettes } from '../_components/Chart'

export default [
  {
    name: 'Dashboard', // i18n defer
    groups: [
      {
        items: [
          {
            title: 'Connected Devices', // i18n defer
            metric: 'statsd_source.packetfence.devices.connected_gauge',
            library: libraries.DYGRAPH_COUNTER,
            params: {
              decimal_digits: 0,
              dygraph_theme: 'sparkline',
              dygraph_type: 'area',
              dimensions: 'gauge',
              colors: palettes[0]
            },
            cols: 3
          },
          {
            title: 'Registered Devices', // i18n defer
            metric: 'statsd_source.packetfence.devices.registered_gauge',
            library: libraries.DYGRAPH_COUNTER,
            params: {
              decimal_digits: 0,
              dygraph_theme: 'sparkline',
              dygraph_type: 'area',
              dimensions: 'gauge',
              colors: palettes[1]
            },
            cols: 3
          },
          {
            title: 'Open Security Events', // i18n defer
            metric: 'statsd_source.packetfence.security_events_gauge',
            library: libraries.DYGRAPH_COUNTER,
            params: {
              decimal_digits: 0,
              dygraph_theme: 'sparkline',
              dygraph_type: 'area',
              dimensions: 'gauge',
              colors: palettes[0]
            },
            cols: 3
          },
          {
            title: 'Pending Security Events', // i18n defer
            metric: 'statsd_source.packetfence.security_events_pending_gauge',
            library: libraries.DYGRAPH_COUNTER,
            params: {
              decimal_digits: 0,
              dygraph_theme: 'sparkline',
              dygraph_type: 'area',
              dimensions: 'gauge',
              colors: palettes[1]
            },
            cols: 3
          }
        ]
      },
      {
        name: 'Connection Types', // i18n defer
        items: [
          {
            title: 'Connected devices per Connection Type', // i18n defer
            metric: 'packetfence.devices.connected_per_connection_type',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Connection Type', // i18n defer
            metric: 'packetfence.devices.registered_per_connection_type',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Connection Type', // i18n defer
            metric: 'packetfence.devices.registered_per_connection_type',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          }
        ]
      },
      {
        name: 'Fingerbank Classifications', // i18n defer
        items: [
          {
            title: 'Connected devices per Device Class', // i18n defer
            metric: 'packetfence.devices.connected_per_device_class',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Class', // i18n defer
            metric: 'packetfence.devices.registered_per_device_class',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Class', // i18n defer
            metric: 'packetfence.devices.registered_per_device_class',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          },
          {
            title: 'Connected devices per Device Manufacturer', // i18n defer
            metric: 'packetfence.devices.connected_per_device_manufacturer',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Manufacturer', // i18n defer
            metric: 'packetfence.devices.registered_per_device_manufacturer',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Manufacturer', // i18n defer
            metric: 'packetfence.devices.registered_per_device_manufacturer',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          },
          {
            title: 'Connected devices per Device Type', // i18n defer
            metric: 'packetfence.devices.connected_per_device_type',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Type', // i18n defer
            metric: 'packetfence.devices.registered_per_device_type',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Device Type', // i18n defer
            metric: 'packetfence.devices.registered_per_device_type',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          },
        ]
      },
      {
        name: 'Roles', // i18n defer
        items: [
          {
            title: 'Connected devices per Role', // i18n defer
            metric: 'packetfence.devices.connected_per_role',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Role', // i18n defer
            metric: 'packetfence.devices.registered_per_role',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Role', // i18n defer
            metric: 'packetfence.devices.registered_per_role',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          }
        ]
      },
      {
        name: 'SSIDs', // i18n defer
        items: [
          {
            title: 'Connected devices per SSID', // i18n defer
            metric: 'packetfence.devices.connected_per_ssid',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per SSID', // i18n defer
            metric: 'packetfence.devices.registered_per_ssid',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per SSID', // i18n defer
            metric: 'packetfence.devices.registered_per_ssid',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          }
        ]
      },
      {
        name: 'Switches', // i18n defer
        items: [
          {
            title: 'Connected devices per Switch', // i18n defer
            metric: 'packetfence.devices.connected_per_switch',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Switch', // i18n defer
            metric: 'packetfence.devices.registered_per_switch',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per Switch', // i18n defer
            metric: 'packetfence.devices.registered_per_switch',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          }
        ]
      },
      {
        name: 'VLANs', // i18n defer
        items: [
          {
            title: 'Connected devices per VLAN', // i18n defer
            metric: 'packetfence.devices.connected_per_vlan',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[0]
            },
            cols: 2
          },
          {
            title: 'Registered devices per VLAN', // i18n defer
            metric: 'packetfence.devices.registered_per_vlan',
            library: libraries.D3PIE,
            params: {
              d3pie_smallsegmentgrouping_value: 0.5,
              d3pie_smallsegmentgrouping_enabled: 'true',
              decimal_digits: 0,
              colors: palettes[1]
            },
            cols: 2
          },
          {
            title: 'Registered devices per VLAN', // i18n defer
            metric: 'packetfence.devices.registered_per_vlan',
            library: libraries.DYGRAPH,
            cols: 8,
            params: {
              colors: palettes[1]
            }
          }
        ]
      },
      {
        name: 'Registered & Unregistered Devices', // i18n defer
        items: [
          {
            title: 'Registration status of online devices', // i18n defer
            metric: 'packetfence.devices.registered_unregistered',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Devices currently registered', // i18n defer
            metric: 'statsd_source.packetfence.devices.registered_gauge',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'gauge'
            },
            cols: 6
          }
        ]
      },
      {
        name: 'Registered Devices Per Timeframe', // i18n defer
        items: ['hour', 'day', 'week', 'month', 'year'].map(scope => {
          return {
            title: `New registered devices during the past ${scope}`, // i18n defer
            metric: `statsd_source.packetfence.devices.registered_last_${scope}_gauge`,
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'gauge'
            },
            cols: scope === 'year' ? 12 : 6
          }
        })
      },
      {
        name: 'Device Security Events', // i18n defer
        items: [
          {
            title: 'Currently open security events', // i18n defer
            metric: 'statsd_gauge_source.packetfence.security_events',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'gauge'
            },
            cols: 12
          }
        ]
      }
    ]
  }
]