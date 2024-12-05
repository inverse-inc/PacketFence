import { BaseFormGroupArray, BaseFormGroupArrayProps } from '@/components/new'
import BaseHostConfigConfig from './BaseHostConfigConfig'
import i18n from '@/utils/locale'

export const props = {
  ...BaseFormGroupArrayProps,

  buttonLabel: {
    type: String,
    default: i18n.t('Add Config')
  },
  // overload :showIndex
  showIndex: false,

  // overload :childComponent
  childComponent: {
    type: Object,
    default: () => BaseHostConfigConfig
  },

  // overload :defaultItem
  defaultItem: {
    type: Object,
    default: () => ({
      name: null,
      value: null
    })
  }
}

export default {
  name: 'base-form-group-host-config',
  extends: BaseFormGroupArray,
  props
}
