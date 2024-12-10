import { libraries } from '../_components/Chart'

export default [
  {
    name: 'RADIUS', // i18n defer
    groups: [
      {
        name: 'RADIUS Latency', // i18n defer
        items: [
          {
            title: 'Auth Rest', // i18n defer
            metric: 'statsd_timer_pf__api__radius_rest_authorize.timing',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'average'
            },
            cols: 6
          },
          {
            title: 'Acct Rest', // i18n defer
            metric: 'statsd_timer_pf__api__radius_rest_accounting.timing',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'average'
            },
            cols: 6
          }
        ]
      },
      {
        name: 'RADIUS Requests', // i18n defer
        items: [
          {
            title: 'Load balancer auth', // i18n defer
            metric: 'freeradius_Freeradius_LoadBalancer.proxy-auth',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'Load balancer acct', // i18n defer
            metric: 'freeradius_Freeradius_LoadBalancer.proxy-acct',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'RADIUS auth', // i18n defer
            metric: 'freeradius_Freeradius_Auth.authentication',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'RADIUS acct', // i18n defer
            metric: 'freeradius_Freeradius_Acct.accounting',
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: 'RADIUS pfacct', // i18n defer
            metric: 'statsd_timer_pfacct.handleaccountingrequest',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'events',
              units: 'packets/s'
            },
            cols: 6
          }
        ]
      },
      {
        name: 'NTLM', // i18n defer
        items: [
          {
            title: 'NTLM latency', // i18n defer
            metric: 'statsd_timer_ntlm_auth.time',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'average'
            },
            cols: 6
          },
          {
            title: 'NTLM failures', // i18n defer
            metric: 'statsd_counter_ntlm_auth.failures',
            library: libraries.DYGRAPH,
            params: {
              filter_graph: 'counter'
            },
            cols: 6
          }
        ]
      }
    ]
  }
]