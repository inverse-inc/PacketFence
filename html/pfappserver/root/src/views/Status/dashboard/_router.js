import store from '@/store'
import acl from '@/utils/acl'
import StoreModule from '../_store/'

const TheView = () => import(/* webpackChunkName: "Status" */ './_components/TheView')

export const beforeEnter = (to, from, next = () => {}) => {
  if (!store.state.$_status)
    store.registerModule('$_status', StoreModule)
  if (acl.$can('read', 'users_sources'))
    store.dispatch('config/getSources')
  if (acl.$can('read', 'system')) {
    store.dispatch('system/getHostname').then(() => {
      store.dispatch('cluster/getConfig').then(() => {
        store.dispatch('$_status/allCharts').finally(() => next())
      }).catch(() => next())
    })
  }
  else
    next()
}

const can = () => !store.getters['system/isSaas']

export default [
  {
    path: 'dashboard',
    name: 'statusDashboard',
    component: TheView,
    beforeEnter,
    meta: {
      can
    }
  }
]

