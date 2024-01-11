import { BaseViewCollectionItem } from '../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenMultiple,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupSwitch,
} from '@/components/new/'
import {
  BaseFormGroupIntervalUnit
} from '@/views/Configuration/_components/new/'
import BaseFormGroupActions from './BaseFormGroupActions'
import BaseFormGroupTriggers from './BaseFormGroupTriggers'
import BaseFormGroupTriggersHeader from './BaseFormGroupTriggersHeader'
import TheForm from './TheForm'
import TheView from './TheView'
import ToggleStatus from './ToggleStatus'

export {
  BaseViewCollectionItem      as BaseView,
  BaseFormButtonBar           as FormButtonBar,

  BaseFormGroupActions        as FormGroupActions,
  BaseFormGroupIntervalUnit   as FormGroupDelayBy,
  BaseFormGroupInput          as FormGroupDescription,
  BaseFormGroupSwitch         as FormGroupEnabled,
  BaseFormGroupIntervalUnit   as FormGroupGrace,
  BaseFormGroupInput          as FormGroupIdentifier,
  BaseFormGroupInputNumber    as FormGroupPriority,
  BaseFormGroupTriggers       as FormGroupTriggers,
  BaseFormGroupTriggersHeader as FormGroupTriggersHeader,
  BaseFormGroupChosenMultiple as FormGroupWhitelistedRoles,
  BaseFormGroupIntervalUnit   as FormGroupWindow,
  BaseFormGroupSwitch         as FormGroupWindowDynamic,

  TheForm,
  TheView,
  ToggleStatus
}

