import { BaseFormGroupArray, BaseFormGroupArrayProps } from '@/components/new'
import BaseAuth from './BaseAuth'
import i18n from '@/utils/locale'

export const props = {
  ...BaseFormGroupArrayProps,

  buttonLabel: {
    type: String,
    default: i18n.t('Add Auth')
  },
  // overload :showIndex
  showIndex: false,

  // overload :childComponent
  childComponent: {
    type: Object,
    default: () => BaseAuth
  },

  // overload :defaultItem
  defaultItem: {
    type: Object,
    default: () => ({
      user: null,
      pass: null
    })
  }
}

export default {
  name: 'base-form-group-auths',
  extends: BaseFormGroupArray,
  props
}
