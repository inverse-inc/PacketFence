import { BaseViewCollectionItem } from '../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenOne,
  BaseFormGroupInput,
  BaseFormGroupInputTest,
  BaseFormGroupSwitch,
} from '@/components/new/'
import TheForm from './TheForm'
import TheView from './TheView'

export {
  BaseViewCollectionItem              as BaseView,
  BaseFormButtonBar                   as FormButtonBar,

  BaseFormGroupInput                  as FormGroupIdentifier,
  BaseFormGroupInput                  as FormGroupWorkgroup,
  BaseFormGroupInput                  as FormGroupDnsName,
  BaseFormGroupInput                  as FormGroupServerName,
  BaseFormGroupInput                  as FormGroupStickyDc,
  BaseFormGroupInput                  as FormGroupAdServer,
  BaseFormGroupInput                  as FormGroupDnsServers,
  BaseFormGroupInput                  as FormGroupOu,
  BaseFormGroupInput                  as FormGroupMachineAccount,
  BaseFormGroupInputTest              as FormGroupMachineAccountPassword,
  BaseFormGroupSwitch                 as FormGroupNtlmv2Only,
  BaseFormGroupSwitch                 as FormGroupRegistration,

  BaseFormGroupSwitch                 as FormGroupNtlmCache,
  BaseFormGroupChosenOne              as FormGroupNtlmCacheSource,
  BaseFormGroupInput                  as FormGroupNtlmCacheExpiry,

  TheForm,
  TheView
}
