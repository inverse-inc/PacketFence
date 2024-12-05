import { BaseFormGroupArray, BaseFormGroupArrayProps } from '@/components/new'
import { BaseInput }  from '@/components/new/'
import i18n from '@/utils/locale'

export const props = {
  ...BaseFormGroupArrayProps,

  buttonLabel: {
    type: String,
    default: i18n.t('Add IPv4')
  },
  // overload :childComponent
  childComponent: {
    type: Object,
    default: () => BaseInput
  },
  // overload :defaultItem
  defaultItem: {
    type: String,
    default: () => (null)
  }
}

export default {
  name: 'base-form-group-iptables',
  extends: BaseFormGroupArray,
  props
}
