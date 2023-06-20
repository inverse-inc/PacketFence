import i18n from '@/utils/locale'
import { parse, format, formatDistanceToNow } from 'date-fns'

const filters = {
  longDateTime (value) {
    if (!value || value === '0000-00-00 00:00:00') {
      return i18n.t('Never')
    } else {
      let localeObject, localeFormat
      if (i18n.locale === 'fr') {
        localeObject = require('date-fns/locale/fr-CA')
        localeFormat = 'dddd, D MMMM, YYYY, HH:mm:ss'
      } else {
        localeObject = require('date-fns/locale/en-US')
        localeFormat = 'dddd, MMMM D, YYYY, hh:mm:ss a'
      }
      return format(parse(value), localeFormat, { locale: localeObject })
    }
  },
  shortDateTime (value) {
    if (!value || value === '0000-00-00 00:00:00') {
      return i18n.t('Never')
    } else {
      let localeObject, localeFormat
      if (i18n.locale === 'fr') {
        localeObject = require('date-fns/locale/fr-CA')
        localeFormat = 'DD/MM/YY HH:mm'
      } else {
        localeObject = require('date-fns/locale/en-US')
        localeFormat = 'MM/DD/YY hh:mm a'
      }
      return format(parse(value), localeFormat, { locale: localeObject })
    }
  },
  relativeDate (value) {
    if (!value) {
      return ''
    } else if (value === '0000-00-00 00:00:00') {
      return i18n.t('Never')
    } else {
      let localeObject
      if (i18n.locale === 'fr') {
        localeObject = require('date-fns/locale/fr-CA')
      } else {
        localeObject = require('date-fns/locale/en-US')
      }
      return formatDistanceToNow(parse(value), { locale: localeObject })
    }
  }
}

export default filters
