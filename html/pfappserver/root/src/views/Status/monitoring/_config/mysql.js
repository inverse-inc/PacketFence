import { libraries } from '../_components/Chart'

export default [
  {
    name: 'MySQL', // i18n defer
    groups: [
      {
        name: 'Database', // i18n defer
        items: [
          {
            title: 'Table Rows', // i18n defer
            metric: 'packetfence.mysql.table_rows',
            library: libraries.DYGRAPH,
            cols: 8
          }
        ]
      }
    ]
  }
]