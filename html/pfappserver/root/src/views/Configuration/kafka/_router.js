import store from '@/store'
import BasesStoreModule from './_store'

const TheView = () => import(/* webpackChunkName: "Configuration" */ './_components/TheView')

export const beforeEnter = (to, from, next = () => {}) => {
  if (!store.state.$_kafka) {
    store.registerModule('$_kafka', BasesStoreModule)
  }
  next()
}

const can = () => !store.getters['system/isSaas']

export default [
  {
    path: 'kafka',
    name: 'kafka',
    component: TheView,
    meta: {
      can
    },
    beforeEnter
  }
]
