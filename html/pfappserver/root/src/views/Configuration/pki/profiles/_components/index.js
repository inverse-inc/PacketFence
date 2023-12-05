import {BaseViewCollectionItem} from '../../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenCountry,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupSwitch,
  BaseFormGroupTextarea,
} from '@/components/new/'
import {
  BaseFormGroupChosenOneCa,
  BaseFormGroupChosenOneScepServer,
  BaseFormGroupDigest,
  BaseFormGroupExtendedKeyUsage,
  BaseFormGroupKeySize,
  BaseFormGroupKeyType,
  BaseFormGroupKeyUsage,
} from '../../_components/'
import { BaseFormGroupChosenOneCloud } from '@/views/Configuration/clouds/_components/'
import TheForm from './TheForm'
import TheView from './TheView'

export {
  BaseViewCollectionItem                  as BaseView,
  BaseFormButtonBar                       as FormButtonBar,

  BaseFormGroupInput                      as FormGroupIdentifier,
  BaseFormGroupChosenOneCa                as FormGroupCaId,
  BaseFormGroupInput                      as FormGroupName,
  BaseFormGroupInputNumber                as FormGroupValidity,
  BaseFormGroupInput                      as FormGroupMail,
  BaseFormGroupInput                      as FormGroupOrganisationalUnit,
  BaseFormGroupInput                      as FormGroupOrganisation,
  BaseFormGroupChosenCountry              as FormGroupCountry,
  BaseFormGroupInput                      as FormGroupState,
  BaseFormGroupInput                      as FormGroupLocality,
  BaseFormGroupInput                      as FormGroupStreetAddress,
  BaseFormGroupKeyType                    as FormGroupKeyType,
  BaseFormGroupKeySize                    as FormGroupKeySize,
  BaseFormGroupDigest                     as FormGroupDigest,
  BaseFormGroupKeyUsage                   as FormGroupKeyUsage,
  BaseFormGroupExtendedKeyUsage           as FormGroupExtendedKeyUsage,
  BaseFormGroupInput                      as FormGroupOcspUrl,
  BaseFormGroupSwitch                     as FormGroupP12MailPassword,
  BaseFormGroupInput                      as FormGroupP12MailSubject,
  BaseFormGroupInput                      as FormGroupP12MailFrom,
  BaseFormGroupTextarea                   as FormGroupP12MailHeader,
  BaseFormGroupTextarea                   as FormGroupP12MailFooter,
  BaseFormGroupSwitch                     as FormGroupScepEnabled,
  BaseFormGroupInput                      as FormGroupScepChallengePassword,
  BaseFormGroupInputNumber                as FormGroupScepDaysBeforeRenewal,
  BaseFormGroupSwitch                     as FormGroupCloudEnabled,
  BaseFormGroupChosenOneCloud             as FormGroupCloudService,
  BaseFormGroupInputNumber                as FormGroupDaysBeforeRenewal,
  BaseFormGroupSwitch                     as FormGroupRenewalMail,
  BaseFormGroupInputNumber                as FormGroupDaysBeforeRenewalMail,
  BaseFormGroupInput                      as FormGroupRenewalMailSubject,
  BaseFormGroupInput                      as FormGroupRenewalMailFrom,
  BaseFormGroupTextarea                   as FormGroupRenewalMailHeader,
  BaseFormGroupTextarea                   as FormGroupRenewalMailFooter,
  BaseFormGroupInputNumber                as FormGroupRevokedValidUntil,
  BaseFormGroupSwitch                     as FormGroupScepServerEnabled,
  BaseFormGroupChosenOneScepServer        as FormGroupScepServerId,
  TheForm,
  TheView,

  BaseFormGroupTextarea                   as FormGroupCsr,
}
