import { libraries } from '../_components/Chart'

export default [
  {
    name: 'MySQL', // i18n defer
    groups: [
      {
        name: 'MySQL', // i18n defer
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
          },
          {
            title: 'Table Rows', // i18n defer
            metric: 'packetfence.mysql.table_rows',
            library: libraries.DYGRAPH,
            cols: 12
          }
        ]
      },
      {
        name: 'InnoDB', // i18n defer
        items: [
          {
            title: 'InnoDB Pages', // i18n defer
            metric: 'packetfence.mysql.innodb_buffer_pool_pages',
            library: libraries.DYGRAPH,
            cols: 12
          },
          {
            title: 'InnoDB Bytes', // i18n defer
            metric: 'packetfence.mysql.innodb_buffer_pool_bytes',
            library: libraries.DYGRAPH,
            cols: 12
          },
          {
            title: 'InnoDB R/W', // i18n defer
            metric: 'packetfence.mysql.innodb_buffer_pool_read_write',
            library: libraries.DYGRAPH,
            cols: 12
          }
        ]
      }
    ]
  }
]