import { computed, toRefs } from '@vue/composition-api'
import i18n from '@/utils/locale'

export const useItemProps = {
  id: {
    type: String
  },
  ca_id: {
    type: String
  }
}

export const useItemDefaults = (meta, props) => {
  const {
    ca_id
  } = toRefs(props)
  return {
    ca_id: ca_id.value,
    scep_days_before_renewal: '0',
    renewal_mail: '1',
    days_before_renewal: '14',
    days_before_renewal_mail: '14',
    renewal_mail_subject: 'Certificate expiration',
    revoked_valid_until: '14'
  }
}

export const useItemTitle = (props) => {
  const {
    id,
    isClone,
    isNew
  } = toRefs(props)
  return computed(() => {
    switch (true) {
      case !isNew.value && !isClone.value:
        return i18n.t('Template <code>{id}</code>', { id: id.value })
      case isClone.value:
        return i18n.t('Clone Template <code>{id}</code>', { id: id.value })
      default:
        return i18n.t('New Template')
    }
  })
}

export { useServices } from '../../config'

export { useRouter } from '../_router'

export { useStore } from '../_store'

import { pfSearchConditionType as conditionType } from '@/globals/pfSearch'
import makeSearch from '@/store/factory/search'
import api from '../_api'
export const useSearch = makeSearch('pkiProfiles', {
  api,
  columns: [
    {
      key: 'selected',
      thStyle: 'width: 40px;', tdClass: 'text-center',
      locked: true
    },
    {
      key: 'id',
      label: 'Identifier', // i18n defer
      required: true,
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'ca_id',
      required: true
    },
    {
      key: 'ca_name',
      label: 'Certificate Authority', // i18n defer
      sortable: true,
      visible: true
    },
    {
      key: 'name',
      label: 'Name', // i18n defer
      searchable: true,
      sortable: true,
      visible: true
    },
    {
      key: 'buttons',
      class: 'text-right p-0',
      locked: true
    }
  ],
  fields: [
    {
      value: 'id',
      text: i18n.t('Identifier'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'ca_name',
      text: i18n.t('Certificate Authority'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'name',
      text: i18n.t('Name'),
      types: [conditionType.SUBSTRING]
    }
  ],
  sortBy: 'id'
})
