import makeSearch from '@/store/factory/search'
import { pfSearchConditionType as conditionType } from '@/globals/pfSearch'
import store from '@/store'
import i18n from '@/utils/locale'
import api from './_api'

export const useSearchFactory = (meta) => {
  const { id, columns = [], default_limit = 100, query_fields = [] } = meta.value
  const cursor_fields = columns
    .filter(column => column.is_cursor)
    .map(column => column.name)
  const { list, ...rest } = api // omit list

  return makeSearch(`reports::${id}`, {
    api: { ...rest },
    limit: +default_limit,
    requestInterceptor: request => {
      const { has_date_range, start_date = '0000-00-00 00:00:00', end_date = '9999-12-31 23:59:59' } = meta.value
      if (request.query) {
        // reduce query by slicing empty objects (strip placeholders from defaultCondition)
        //  walk backwards to prevent Array slice from changing future indexes
        for (let o = request.query.values.length - 1; o >= 0; o--) {
          for (let i = request.query.values[o].values.length - 1; i >= 0; i--) {
            if (Object.keys(request.query.values[o].values[i]).length === 0)
              request.query.values[o].values = [...request.query.values[o].values.slice(0, i), ...request.query.values[o].values.slice(i + 1, request.query.values[o].values.length)]
          }
          if (request.query.values[o].values.length === 0)
            request.query.values = [...request.query.values.slice(0, o), ...request.query.values.slice(o + 1, request.query.values[o].values.length)]
        }
      }
      if (has_date_range) {
        // append id, start_date and end_date to api request(s)
        return { ...request, id, start_date, end_date }
      }
      // append id to api request(s)
      return { ...request, id }
    },
    responseInterceptor: response => {
      let { items = [] } = response
      const { timezone } = meta.value
      const dateFields = columns
        .filter(column => column.is_date)
        .map(column => column.name)
      return { items: items.map(item => {
        return Object.entries(item).reduce((item, [k, date]) => {
          if (dateFields.includes(k)) {
            // server => utc => timezone
            item[k] = store.getters['$_bases/serverDateToTimezoneFormat'](date, timezone)
          }
          else {
            item[k] = date
          }
          return item
        }, {})
      }) }
    },
    // build search string from query_fields
    useString: searchString => {
      return {
        op: 'and',
        values: [{
          op: 'or',
          values: query_fields.map(field => ({
            field: field.name,
            op: 'contains',
            value: searchString.trim()
          }))
        }]
      }
    },
    columns: [
      {
        key: 'selected',
        thStyle: 'text-align: center; width: 40px;', tdClass: 'text-center',
        locked: true
      },
      ...columns.map(column => {
        const { name: key, text: label } = column
        return {
          key,
          label,
          required: cursor_fields.includes(key),
          searchable: query_fields.filter(({ name, text }) => (name === key || text === label)).length > 0,
          visible: true,
          thClass: 'text-nowrap'
        }
      }),
      {
        key: 'buttons',
        class: 'text-right p-0',
        thStyle: 'width: 40px;',
        locked: true
      }
    ],
    fields: query_fields.map(field => {
      const { name: value, text, type } = field
      switch (type) {
        case 'string':
        default:
          return {
            value,
            text: i18n.t(text),
            types: [conditionType.SUBSTRING]
          }
          // break
      }
    })
  })
}
