import { BaseViewCollectionItem } from '../../_components/new/'
import {
  BaseFormButtonBar,

  BaseFormGroupChosenMultiple,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupToggleDisabledEnabled,
} from '@/components/new/'
import {
  BaseFormGroupIntervalUnit
} from '@/views/Configuration/_components/new/'
import AlertServices from './AlertServices'
import BaseFormGroupDeviceAttributesDiffThresholdOverrides from './BaseFormGroupDeviceAttributesDiffThresholdOverrides'
import BaseFormGroupDevices from './BaseFormGroupDevices'
import TheForm from './TheForm'
import TheView from './TheView'
import ToggleStatus from './ToggleStatus'

export {
  BaseViewCollectionItem                              as BaseView,
  BaseFormButtonBar                                   as FormButtonBar,

  BaseFormGroupInputNumber                            as FormGroupBlacklistedDomainNamesThreshold,
  BaseFormGroupIntervalUnit                           as FormGroupBlacklistedDomainNamesWindow,
  BaseFormGroupInputNumber                            as FormGroupBlacklistedIpHostsThreshold,
  BaseFormGroupIntervalUnit                           as FormGroupBlacklistedIpHostsWindow,
  BaseFormGroupInput                                  as FormGroupBlacklistedPorts,
  BaseFormGroupIntervalUnit                           as FormGroupBlacklistedPortsWindow,
  BaseFormGroupInput                                  as FormGroupDescription,
  BaseFormGroupDeviceAttributesDiffThresholdOverrides as FormGroupDeviceAttributesDiffThresholdOverrides,
  BaseFormGroupInputNumber                            as FormGroupDeviceAttributesDiffScore,
  BaseFormGroupDevices                                as FormGroupDevicesExcluded,
  BaseFormGroupDevices                                as FormGroupDevicesIncluded,
  BaseFormGroupInput                                  as FormGroupIdentifier,
  BaseFormGroupToggleDisabledEnabled                  as FormGroupStatus,
  BaseFormGroupToggleDisabledEnabled                  as FormGroupWatchBlacklistedDomainNames,
  BaseFormGroupToggleDisabledEnabled                  as FormGroupWatchBlacklistedIps,
  BaseFormGroupChosenMultiple                         as FormGroupWatchedDeviceAttributes,
  BaseFormGroupInput                                  as FormGroupWhitelistedDomainNames,
  BaseFormGroupInput                                  as FormGroupWhitelistedIps,


  AlertServices,
  TheForm,
  TheView,
  ToggleStatus
}



