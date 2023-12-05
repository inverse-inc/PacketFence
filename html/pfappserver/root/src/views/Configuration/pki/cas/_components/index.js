import { BaseViewCollectionItem } from '../../../_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenCountry,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupTextareaUpload,
  BaseInputGroupTextarea
} from '@/components/new/'
import {
  BaseFormGroupKeyType,
  BaseFormGroupKeySize,
  BaseFormGroupDigest,
  BaseFormGroupKeyUsage,
  BaseFormGroupExtendedKeyUsage,
} from '../../_components/'
import ButtonCaResign from './ButtonCaResign'
import ButtonCaGenerateCsr from './ButtonCaGenerateCsr'
import TheForm from './TheForm'
import TheView from './TheView'

export {
  BaseViewCollectionItem        as BaseView,
  BaseFormButtonBar             as FormButtonBar,

  BaseFormGroupInput            as FormGroupIdentifier,
  BaseFormGroupInput            as FormGroupCn,
  BaseFormGroupInput            as FormGroupMail,
  BaseFormGroupInput            as FormGroupOrganisationalUnit,
  BaseFormGroupInput            as FormGroupOrganisation,
  BaseFormGroupChosenCountry    as FormGroupCountry,
  BaseFormGroupInput            as FormGroupState,
  BaseFormGroupInput            as FormGroupLocality,
  BaseFormGroupInput            as FormGroupStreetAddress,
  BaseFormGroupInput            as FormGroupPostalCode,
  BaseFormGroupInput            as FormGroupOcspUrl,
  BaseFormGroupKeyType          as FormGroupKeyType,
  BaseFormGroupKeySize          as FormGroupKeySize,
  BaseFormGroupDigest           as FormGroupDigest,
  BaseFormGroupKeyUsage         as FormGroupKeyUsage,
  BaseFormGroupExtendedKeyUsage as FormGroupExtendedKeyUsage,
  BaseFormGroupInputNumber      as FormGroupDays,
  BaseFormGroupTextareaUpload   as FormGroupCert,

  BaseInputGroupTextarea        as InputGroupCert,
  BaseInputGroupTextarea        as InputGroupCsr,

  ButtonCaResign,
  ButtonCaGenerateCsr,
  TheForm,
  TheView
}
