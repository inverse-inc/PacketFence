import {BaseViewCollectionItem} from '../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenOne,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupSwitch,
  BaseFormGroupTextarea,
} from '@/components/new/'
import {BaseFormGroupIntervalUnit} from '@/views/Configuration/_components/new/'
import TheForm from './TheForm'
import TheView from './TheView'
import ToggleStatus from './ToggleStatus'

export {
  BaseViewCollectionItem              as BaseView,
  BaseFormButtonBar                   as FormButtonBar,

  BaseFormGroupInputNumber            as FormGroupBatch,
  BaseFormGroupTextarea               as FormGroupCertificates,
  BaseFormGroupIntervalUnit           as FormGroupDelay,
  BaseFormGroupIntervalUnit           as FormGroupDeleteWindow,
  BaseFormGroupInput                  as FormGroupDescription,
  BaseFormGroupInputNumber            as FormGroupHistoryBatch,
  BaseFormGroupIntervalUnit           as FormGroupHistoryTimeout,
  BaseFormGroupIntervalUnit           as FormGroupHistoryWindow,
  BaseFormGroupInput                  as FormGroupIdentifier,
  BaseFormGroupChosenOne              as FormGroupSchedule,
  BaseFormGroupSwitch                 as FormGroupProcessSwitchranges,
  BaseFormGroupSwitch                 as FormGroupRotate,
  BaseFormGroupInputNumber            as FormGroupRotateBatch,
  BaseFormGroupIntervalUnit           as FormGroupRotateTimeout,
  BaseFormGroupIntervalUnit           as FormGroupRotateWindow,
  BaseFormGroupInputNumber            as FormGroupSessionBatch,
  BaseFormGroupIntervalUnit           as FormGroupSessionTimeout,
  BaseFormGroupIntervalUnit           as FormGroupSessionWindow,
  BaseFormGroupSwitch                 as FormGroupStatus,
  BaseFormGroupIntervalUnit           as FormGroupTimeout,
  BaseFormGroupIntervalUnit           as FormGroupUnregWindow,
  BaseFormGroupSwitch                 as FormGroupVoip,
  BaseFormGroupIntervalUnit           as FormGroupWindow,

  TheForm,
  TheView,
  ToggleStatus
}
