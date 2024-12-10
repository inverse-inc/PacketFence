import { libraries } from '../_components/Chart'

export default [
  {
    name: 'System', // i18n defer
    groups: [
      {
        name: 'System', // i18n defer
        items: [
          {
            title: 'CPU usage', // i18n defer
            metric: 'system.cpu',
            library: libraries.DYGRAPH,
            params: {
              dimensions: 'user,system',
              dygraph_valuerange: '[0, 100]'
            },
            cols: 6
          },
          {
            title: 'IO Wait/Soft IRQ', // i18n defer
            metric: 'system.cpu',
            library: libraries.DYGRAPH,
            params: {
              dimensions: 'iowait,softirq',
              dygraph_valuerange: '[0, 100]'
            },
            cols: 6
          },
          {
            title: 'System Load Average', // i18n defer
            metric: 'system.load',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Disk I/O', // i18n defer
            metric: 'system.io',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Disk Space Usage for /', // i18n defer
            metric: 'disk_space._',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'System RAM', // i18n defer
            metric: 'system.ram',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'System Swap Used', // i18n defer
            metric: 'mem.swap',
            library: libraries.DYGRAPH,
            params: {
              dimensions: 'used'
            },
            cols: 6
          },
          {
            title: 'Swap IO', // i18n defer
            metric: 'mem.swapio',
            library: libraries.DYGRAPH,
            cols: 6
          }
        ]
      },
      {
        name: 'Physical Network Interfaces', // i18n defer
        items: [
          {
            title: 'Aggregated Bandwidth', // i18n defer
            metric: 'system.net',
            library: libraries.DYGRAPH,
            cols: 12
          }
        ]
      },
      {
        name: 'IPv4 Networking', // i18n defer
        items: [
          {
            title: 'Bandwidth', // i18n defer
            metric: 'system.ip',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Packets', // i18n defer
            metric: 'ipv4.packets',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Errors', // i18n defer
            metric: 'ipv4.errors',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'TCP Sockets', // i18n defer
            metric: 'ipv4.sockstat_tcp_sockets',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'UDP Sockets', // i18n defer
            metric: 'ipv4.sockstat_udp_sockets',
            library: libraries.DYGRAPH,
            cols: 4
          }
        ]
      },
      {
        name: 'IPv6 Networking', // i18n defer
        items: [
          {
            title: 'Bandwidth', // i18n defer
            metric: 'system.ipv6',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Packets', // i18n defer
            metric: 'ipv6.packets',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Errors', // i18n defer
            metric: 'ipv6.errors',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'TCP Sockets', // i18n defer
            metric: 'ipv6.sockstat6_tcp_sockets',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'UDP Sockets', // i18n defer
            metric: 'ipv6.sockstat6_udp_sockets',
            library: libraries.DYGRAPH,
            cols: 4
          }
        ]
      },
      {
        name: 'Database', // i18n defer
        items: [
          {
            title: 'Database queries', // i18n defer
            metric: 'mysql_PacketFence_Database.queries',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Database handlers', // i18n defer
            metric: 'mysql_PacketFence_Database.handlers',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Database threads', // i18n defer
            metric: 'mysql_PacketFence_Database.threads',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Database connections', // i18n defer
            metric: 'mysql_PacketFence_Database.connections',
            library: libraries.DYGRAPH,
            cols: 6
          }
        ]
      }
    ]
  }
]