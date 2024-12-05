import { BaseFormGroupArray, BaseFormGroupArrayProps } from '@/components/new'
import BaseClusterConfig from './BaseClusterConfig'
import i18n from '@/utils/locale'

export const props = {
  ...BaseFormGroupArrayProps,

  buttonLabel: {
    type: String,
    default: i18n.t('Add Cluster Config')
  },
  // overload :showIndex
  showIndex: false,

  // overload :childComponent
  childComponent: {
    type: Object,
    default: () => BaseClusterConfig
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
  name: 'base-form-group-cluster-config',
  extends: BaseFormGroupArray,
  props
}
