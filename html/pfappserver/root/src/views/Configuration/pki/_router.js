import store from '@/store'
import StoreModule from './_store'

const TheTabs = () => import(/* webpackChunkName: "Configuration" */ '../_components/TheTabsPkis')
import CasRoutes from './cas/_router'
import CertsRoutes from './certs/_router'
import ProfilesRoutes from './profiles/_router'
import RevokedCertsRoutes from './revokedCerts/_router'
import ScepServersRoutes from './scepServers/_router'

export const beforeEnter = (to, from, next = () => { }) => {
  if (!store.state.$_pkis)
    store.registerModule('$_pkis', StoreModule)
  next()
}

export default [
  {
    path: 'pki',
    name: 'pki',
    component: TheTabs,
    props: () => ({ tab: 'pkiCas' }),
    beforeEnter
  },
  ...CasRoutes,
  ...CertsRoutes,
  ...ProfilesRoutes,
  ...RevokedCertsRoutes,
  ...ScepServersRoutes
]
