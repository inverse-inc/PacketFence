import { reset as resetVuexStore } from '@/store'
import TheView from '../'

const route = {
  path: '/login',
  alias: ['/logout', '/expire'],
  name: 'login',
  component: TheView,
  beforeEnter: (to, from, next) => {
    if (from.path && !['/', '/login', '/logout', '/expire'].includes(from.path)) {
      localStorage.setItem('last_uri', from.path)
    }
    resetVuexStore()
    next()
  }
}

export default route
