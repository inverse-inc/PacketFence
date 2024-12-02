import { computed } from '@vue/composition-api'
import i18n from '@/utils/locale'

export const useTitle = () => i18n.t('Kafka')

export const useStore = $store => {
  return {
    isLoading: computed(() => $store.getters['$_kafka/isLoading']),
    getItem: () => $store.dispatch('$_kafka/getKafka'),
    getItemOptions: () => $store.dispatch('$_kafka/optionsKafka'),
    updateItem: params => $store.dispatch('$_kafka/updateKafka', params)
  }
}
