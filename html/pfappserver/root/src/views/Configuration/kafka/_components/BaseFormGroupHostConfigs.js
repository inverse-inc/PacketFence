import { BaseFormGroupArray, BaseFormGroupArrayProps } from '@/components/new'
import BaseHostConfig from './BaseHostConfig'
import i18n from '@/utils/locale'

export const props = {
  ...BaseFormGroupArrayProps,

  buttonLabel: {
    type: String,
    default: i18n.t('Add Host Config')
  },
  // overload :showIndex
  showIndex: false,

  // overload :childComponent
  childComponent: {
    type: Object,
    default: () => BaseHostConfig
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
  name: 'base-form-group-host-configs',
  extends: BaseFormGroupArray,
  props
}
