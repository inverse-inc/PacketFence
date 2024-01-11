import { BaseViewCollectionItem } from '../../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenCountry,
  BaseFormGroupInput
} from '@/components/new/'
import {
  BaseFormGroupChosenOneProfile
} from '../../_components/'
import ButtonCertificateCopy from './ButtonCertificateCopy'
import ButtonCertificateDownload from './ButtonCertificateDownload'
import ButtonCertificateEmail from './ButtonCertificateEmail'
import ButtonCertificateRevoke from './ButtonCertificateRevoke'
import ButtonCertificateResign from './ButtonCertificateResign'
import TheForm from './TheForm'
import TheView from './TheView'

export {
  BaseViewCollectionItem          as BaseView,
  BaseFormButtonBar               as FormButtonBar,

  BaseFormGroupInput              as FormGroupIdentifier,
  BaseFormGroupChosenOneProfile   as FormGroupProfileIdentifier,
  BaseFormGroupInput              as FormGroupCn,
  BaseFormGroupInput              as FormGroupMail,
  BaseFormGroupInput              as FormGroupDnsNames,
  BaseFormGroupInput              as FormGroupIpAddresses,
  BaseFormGroupInput              as FormGroupOrganisationalUnit,
  BaseFormGroupInput              as FormGroupOrganisation,
  BaseFormGroupChosenCountry      as FormGroupCountry,
  BaseFormGroupInput              as FormGroupState,
  BaseFormGroupInput              as FormGroupLocality,
  BaseFormGroupInput              as FormGroupStreetAddress,
  BaseFormGroupInput              as FormGroupPostalCode,

  ButtonCertificateCopy,
  ButtonCertificateDownload,
  ButtonCertificateEmail,
  ButtonCertificateRevoke,
  ButtonCertificateResign,
  TheForm,
  TheView
}
