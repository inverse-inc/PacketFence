import store from '@/store'
import ConfigurationView from '../'
import AuthenticationSourcesStore from '../_store/sources'
import BasesStore from '../_store/bases'
import BillingTiersStore from '../_store/billingTiers'
import CertificatesStore from '../_store/certificates'
import ConnectionProfilesStore from '../_store/connectionProfiles'
import DomainsStore from '../_store/domains'
import FirewallsStore from '../_store/firewalls'
import FloatingDevicesStore from '../_store/floatingDevices'
import PortalModulesStore from '../_store/portalModules'
import ProfilingStore from '../_store/profiling'
import ProvisioningsStore from '../_store/provisionings'
import RealmsStore from '../_store/realms'
import RolesStore from '../_store/roles'
import ScansStore from '../_store/scans'
import SyslogForwardersStore from '../_store/syslogForwarders'
import SyslogParsersStore from '../_store/syslogParsers'
import SwitchesStore from '../_store/switches'
import SwitchGroupsStore from '../_store/switchGroups'
import WrixLocationsStore from '../_store/wrixLocations'

/* Policies Access Control */
const PoliciesAccessControlSection = () => import(/* webpackChunkName: "Configuration" */ '../_components/PoliciesAccessControlSection')
const RolesList = () => import(/* webpackChunkName: "Configuration" */ '../_components/RolesList')
const RoleView = () => import(/* webpackChunkName: "Configuration" */ '../_components/RoleView')
const DomainsTabs = () => import(/* webpackChunkName: "Configuration" */ '../_components/DomainsTabs')
const DomainView = () => import(/* webpackChunkName: "Configuration" */ '../_components/DomainView')
const RealmView = () => import(/* webpackChunkName: "Configuration" */ '../_components/RealmView')
const AuthenticationSourcesList = () => import(/* webpackChunkName: "Configuration" */ '../_components/AuthenticationSourcesList')
const AuthenticationSourceView = () => import(/* webpackChunkName: "Configuration" */ '../_components/AuthenticationSourceView')
const NetworkDevicesTabs = () => import(/* webpackChunkName: "Configuration" */ '../_components/NetworkDevicesTabs')
const SwitchView = () => import(/* webpackChunkName: "Configuration" */ '../_components/SwitchView')
const SwitchGroupView = () => import(/* webpackChunkName: "Configuration" */ '../_components/SwitchGroupView')
const ConnectionProfilesList = () => import(/* webpackChunkName: "Configuration" */ '../_components/ConnectionProfilesList')
const ConnectionProfileView = () => import(/* webpackChunkName: "Configuration" */ '../_components/ConnectionProfileView')
const ConnectionProfileFileView = () => import(/* webpackChunkName: "Configuration" */ '../_components/ConnectionProfileFileView')

/* Compliance */
const ComplianceSection = () => import(/* webpackChunkName: "Configuration" */ '../_components/ComplianceSection')
const ProfilingTabs = () => import(/* webpackChunkName: "Configuration" */ '../_components/ProfilingTabs')
const ProfilingCombinationView = () => import(/* webpackChunkName: "Configuration" */ '../_components/ProfilingCombinationView')
const ScansTabs = () => import(/* webpackChunkName: "Configuration" */ '../_components/ScansTabs')
const ScansScanEngineView = () => import(/* webpackChunkName: "Configuration" */ '../_components/ScansScanEngineView')

/* Integration */
const IntegrationSection = () => import(/* webpackChunkName: "Configuration" */ '../_components/IntegrationSection')
const FirewallsList = () => import(/* webpackChunkName: "Configuration" */ '../_components/FirewallsList')
const FirewallView = () => import(/* webpackChunkName: "Configuration" */ '../_components/FirewallView')
const CiscoMobilityServicesEngineView = () => import(/* webpackChunkName: "Configuration" */ '../_components/CiscoMobilityServicesEngineView')
const WebServicesView = () => import(/* webpackChunkName: "Configuration" */ '../_components/WebServicesView')
const SyslogParsersList = () => import(/* webpackChunkName: "Configuration" */ '../_components/SyslogParsersList')
const SyslogParserView = () => import(/* webpackChunkName: "Configuration" */ '../_components/SyslogParserView')
const SyslogForwardersList = () => import(/* webpackChunkName: "Configuration" */ '../_components/SyslogForwardersList')
const SyslogForwarderView = () => import(/* webpackChunkName: "Configuration" */ '../_components/SyslogForwarderView')
const WrixLocationsList = () => import(/* webpackChunkName: "Configuration" */ '../_components/WrixLocationsList')
const WrixLocationView = () => import(/* webpackChunkName: "Configuration" */ '../_components/WrixLocationView')

/* Advanced Access Configuration */
const CaptivePortalView = () => import(/* webpackChunkName: "Configuration" */ '../_components/CaptivePortalView')
const BillingTiersList = () => import(/* webpackChunkName: "Configuration" */ '../_components/BillingTiersList')
const BillingTierView = () => import(/* webpackChunkName: "Configuration" */ '../_components/BillingTierView')
const PortalModulesList = () => import(/* webpackChunkName: "Configuration" */ '../_components/PortalModulesList')
const PortalModuleView = () => import(/* webpackChunkName: "Configuration" */ '../_components/PortalModuleView')
const AccessDurationView = () => import(/* webpackChunkName: "Configuration" */ '../_components/AccessDurationView')

/* Network Configuration */
const NetworkConfigurationSection = () => import(/* webpackChunkName: "Configuration" */ '../_components/NetworkConfigurationSection')
const FloatingDevicesList = () => import(/* webpackChunkName: "Configuration" */ '../_components/FloatingDevicesList')
const FloatingDeviceView = () => import(/* webpackChunkName: "Configuration" */ '../_components/FloatingDeviceView')
const CertificatesView = () => import(/* webpackChunkName: "Configuration" */ '../_components/CertificatesView')

const route = {
  path: '/configuration',
  name: 'configuration',
  redirect: '/configuration/policesaccesscontrol',
  component: ConfigurationView,
  meta: { transitionDelay: 300 * 2 }, // See _transitions.scss => $slide-bottom-duration
  beforeEnter: (to, from, next) => {
    /**
     * Register Vuex stores
     */
    if (!store.state.$_bases) {
      store.registerModule('$_bases', BasesStore)
      // preload config/bases (all sections)
      store.dispatch('$_bases/all')
    }
    if (!store.state.$_billing_tiers) {
      store.registerModule('$_billing_tiers', BillingTiersStore)
    }
    if (!store.state.$_domains) {
      store.registerModule('$_domains', DomainsStore)
    }
    if (!store.state.$_certificates) {
      store.registerModule('$_certificates', CertificatesStore)
    }
    if (!store.state.$_connection_profiles) {
      store.registerModule('$_connection_profiles', ConnectionProfilesStore)
    }
    if (!store.state.$_firewalls) {
      store.registerModule('$_firewalls', FirewallsStore)
    }
    if (!store.state.$_floatingdevices) {
      store.registerModule('$_floatingdevices', FloatingDevicesStore)
    }
    if (!store.state.$_portalmodules) {
      store.registerModule('$_portalmodules', PortalModulesStore)
    }
    if (!store.state.$_profiling) {
      store.registerModule('$_profiling', ProfilingStore)
    }
    if (!store.state.$_provisionings) {
      store.registerModule('$_provisionings', ProvisioningsStore)
    }
    if (!store.state.$_realms) {
      store.registerModule('$_realms', RealmsStore)
    }
    if (!store.state.$_roles) {
      store.registerModule('$_roles', RolesStore)
    }
    if (!store.state.$_scans) {
      store.registerModule('$_scans', ScansStore)
    }
    if (!store.state.$_sources) {
      store.registerModule('$_sources', AuthenticationSourcesStore)
    }
    if (!store.state.$_syslog_parsers) {
      store.registerModule('$_syslog_parsers', SyslogParsersStore)
    }
    if (!store.state.$_syslog_forwarders) {
      store.registerModule('$_syslog_forwarders', SyslogForwardersStore)
    }
    if (!store.state.$_switches) {
      store.registerModule('$_switches', SwitchesStore)
    }
    if (!store.state.$_switch_groups) {
      store.registerModule('$_switch_groups', SwitchGroupsStore)
    }
    if (!store.state.$_wrix_locations) {
      store.registerModule('$_wrix_locations', WrixLocationsStore)
    }
    next()
  },
  children: [
    /**
     * Policies Access Control
     */
    {
      path: 'policesaccesscontrol',
      component: PoliciesAccessControlSection
    },
    {
      path: 'roles',
      name: 'roles',
      component: RolesList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'roles/new',
      name: 'newRole',
      component: RoleView,
      props: (route) => ({ storeName: '$_roles', isNew: true })
    },
    {
      path: 'role/:id',
      name: 'role',
      component: RoleView,
      props: (route) => ({ storeName: '$_roles', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_roles/getRole', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'role/:id/clone',
      name: 'cloneRole',
      component: RoleView,
      props: (route) => ({ storeName: '$_roles', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_roles/getRole', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'domains',
      name: 'domains',
      component: DomainsTabs,
      props: (route) => ({ tab: 'domains', query: route.query.query })
    },
    {
      path: 'domains/new',
      name: 'newDomain',
      component: DomainView,
      props: (route) => ({ storeName: '$_domains', isNew: true })
    },
    {
      path: 'domain/:id',
      name: 'domain',
      component: DomainView,
      props: (route) => ({ storeName: '$_domains', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_domains/getDomain', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'domain/:id/clone',
      name: 'cloneDomain',
      component: DomainView,
      props: (route) => ({ storeName: '$_domains', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_domains/getDomain', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'realms',
      name: 'realms',
      component: DomainsTabs,
      props: (route) => ({ tab: 'realms', query: route.query.query })
    },
    {
      path: 'realms/new',
      name: 'newRealm',
      component: RealmView,
      props: (route) => ({ storeName: '$_realms', isNew: true })
    },
    {
      path: 'realm/:id',
      name: 'realm',
      component: RealmView,
      props: (route) => ({ storeName: '$_realms', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_realms/getRealm', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'realm/:id/clone',
      name: 'cloneRealm',
      component: RealmView,
      props: (route) => ({ storeName: '$_realms', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_realms/getRealm', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'sources',
      name: 'sources',
      component: AuthenticationSourcesList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'sources/new/:sourceType',
      name: 'newAuthenticationSource',
      component: AuthenticationSourceView,
      props: (route) => ({ storeName: '$_sources', isNew: true, sourceType: route.params.sourceType })
    },
    {
      path: 'source/:id',
      name: 'source',
      component: AuthenticationSourceView,
      props: (route) => ({ storeName: '$_sources', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_sources/getAuthenticationSource', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'source/:id/clone',
      name: 'cloneAuthenticationSource',
      component: AuthenticationSourceView,
      props: (route) => ({ storeName: '$_sources', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_sources/getAuthenticationSource', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'switches',
      name: 'switches',
      component: NetworkDevicesTabs,
      props: (route) => ({ tab: 'switches', query: route.query.query })
    },
    {
      path: 'switches/new/:switchGroup',
      name: 'newSwitch',
      component: SwitchView,
      props: (route) => ({ storeName: '$_switches', isNew: true, switchGroup: route.params.switchGroup })
    },
    {
      path: 'switch/:id',
      name: 'switch',
      component: SwitchView,
      props: (route) => ({ storeName: '$_switches', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_switches/getSwitch', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'switch/:id/clone',
      name: 'cloneSwitch',
      component: SwitchView,
      props: (route) => ({ storeName: '$_switches', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_switches/getSwitch', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'switch_groups',
      name: 'switch_groups',
      component: NetworkDevicesTabs,
      props: (route) => ({ tab: 'switch_groups', query: route.query.query })
    },
    {
      path: 'switch_groups/new',
      name: 'newSwitchGroup',
      component: SwitchGroupView,
      props: (route) => ({ storeName: '$_switch_groups', isNew: true })
    },
    {
      path: 'switch_group/:id',
      name: 'switch_group',
      component: SwitchGroupView,
      props: (route) => ({ storeName: '$_switch_groups', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_switch_groups/getSwitchGroup', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'switch_group/:id/clone',
      name: 'cloneSwitchGroup',
      component: SwitchGroupView,
      props: (route) => ({ storeName: '$_switch_groups', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_switch_groups/getSwitchGroup', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'connection_profiles',
      name: 'connection_profiles',
      component: ConnectionProfilesList,
      props: (route) => ({ tab: 'connection_profiles', query: route.query.query })
    },
    {
      path: 'connection_profiles/new',
      name: 'newConnectionProfile',
      component: ConnectionProfileView,
      props: (route) => ({ storeName: '$_connection_profiles', isNew: true })
    },
    {
      path: 'connection_profile/:id',
      name: 'connection_profile',
      component: ConnectionProfileView,
      props: (route) => ({ storeName: '$_connection_profiles', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_connection_profiles/getConnectionProfile', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'connection_profile/:id/clone',
      name: 'cloneConnectionProfile',
      component: ConnectionProfileView,
      props: (route) => ({ storeName: '$_connection_profiles', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_connection_profiles/getConnectionProfile', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'connection_profile/:id/files',
      name: 'connectionProfileFiles',
      component: ConnectionProfileView,
      props: (route) => ({ storeName: '$_connection_profiles', id: route.params.id, tabIndex: 2 }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_connection_profiles/getConnectionProfile', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'connection_profile/:id/files/:path/new',
      name: 'newConnectionProfileFile',
      component: ConnectionProfileFileView,
      props: (route) => ({ storeName: '$_connection_profiles', id: route.params.id, filename: route.params.path, isNew: true })
    },
    {
      path: 'connection_profile/:id/files/:filename',
      name: 'connectionProfileFile',
      component: ConnectionProfileFileView,
      props: (route) => ({ storeName: '$_connection_profiles', id: route.params.id, filename: route.params.filename })
    },
    /**
     * Compliance
     */
    {
      path: 'compliance',
      component: ComplianceSection
    },
    {
      path: 'profiling',
      redirect: 'profiling/general_settings'
    },
    {
      path: 'profiling/general_settings',
      name: 'profilingGeneralSettings',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'general_settings', query: route.query.query })
    },
    {
      path: 'profiling/device_change_detection',
      name: 'profilingDeviceChangeDetection',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'device_change_detection', query: route.query.query })
    },
    {
      path: 'profiling/combinations',
      name: 'profilingCombinations',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'combinations', query: route.query.query })
    },
    {
      path: 'profiling/combinations/new',
      name: 'newCombination',
      component: ProfilingCombinationView,
      props: (route) => ({ storeName: '$_TODO', isNew: true })
    },
    {
      path: 'profiling/combination/:id',
      name: 'combination',
      component: ProfilingCombinationView,
      props: (route) => ({ storeName: '$_TODO', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_TODO/getTODO', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'profiling/combination/:id/clone',
      name: 'cloneCombination',
      component: ProfilingCombinationView,
      props: (route) => ({ storeName: '$_TODO', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_TODO/getTODO', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'profiling/devices',
      name: 'profilingDevices',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'devices', query: route.query.query })
    },
    {
      path: 'profiling/dhcp_fingerprints',
      name: 'profilingDhcpFingerprints',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'dhcp_fingerprints', query: route.query.query })
    },
    {
      path: 'profiling/dhcp_vendors',
      name: 'profilingDhcpVendors',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'dhcp_vendors', query: route.query.query })
    },
    {
      path: 'profiling/dhcpv6_fingerprints',
      name: 'profilingDhcpv6Fingerprints',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'dhcpv6_fingerprints', query: route.query.query })
    },
    {
      path: 'profiling/dhcpv6_enterprises',
      name: 'profilingDhcpv6Enterprises',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'dhcpv6_enterprises', query: route.query.query })
    },
    {
      path: 'profiling/mac_vendors',
      name: 'profilingMacVendors',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'mac_vendors', query: route.query.query })
    },
    {
      path: 'profiling/user_agents',
      name: 'profilingUserAgents',
      component: ProfilingTabs,
      props: (route) => ({ tab: 'user_agents', query: route.query.query })
    },
    {
      path: 'scans',
      redirect: 'scans/scan_engines'
    },
    {
      path: 'scans/scan_engines',
      name: 'scanEngines',
      component: ScansTabs,
      props: (route) => ({ tab: 'scan_engines', query: route.query.query })
    },
    {
      path: 'scans/scan_engines/new/:scanType',
      name: 'newScanEngine',
      component: ScansScanEngineView,
      props: (route) => ({ storeName: '$_scans', isNew: true, scanType: route.params.scanType })
    },
    {
      path: 'scans/scan_engine/:id',
      name: 'scanEngine',
      component: ScansScanEngineView,
      props: (route) => ({ storeName: '$_scans', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_scans/getScanEngine', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'scans/scan_engine/:id/clone',
      name: 'cloneScanEngine',
      component: ScansScanEngineView,
      props: (route) => ({ storeName: '$_scans', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_scans/getScanEngine', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'scans/wmi_rules',
      name: 'wmiRules',
      component: ScansTabs,
      props: (route) => ({ tab: 'wmi_rules', query: route.query.query })
    },
    /**
     * Integration
     */
    {
      path: 'integration',
      component: IntegrationSection
    },
    {
      path: 'firewalls',
      name: 'firewalls',
      component: FirewallsList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'firewalls/new/:firewallType',
      name: 'newFirewall',
      component: FirewallView,
      props: (route) => ({ storeName: '$_firewalls', isNew: true, firewallType: route.params.firewallType })
    },
    {
      path: 'firewall/:id',
      name: 'firewall',
      component: FirewallView,
      props: (route) => ({ storeName: '$_firewalls', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_firewalls/getFirewall', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'firewall/:id/clone',
      name: 'cloneFirewall',
      component: FirewallView,
      props: (route) => ({ storeName: '$_firewalls', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_firewalls/getFirewall', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'mse',
      name: 'mse',
      component: CiscoMobilityServicesEngineView,
      props: (route) => ({ storeName: '$_bases', query: route.query.query })
    },
    {
      path: 'webservices',
      name: 'webservices',
      component: WebServicesView,
      props: (route) => ({ storeName: '$_bases', query: route.query.query })
    },
    {
      path: 'pfdetect',
      name: 'syslogParsers',
      component: SyslogParsersList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'pfdetect/new/:syslogParserType',
      name: 'newSyslogParser',
      component: SyslogParserView,
      props: (route) => ({ storeName: '$_syslog_parsers', isNew: true, syslogParserType: route.params.syslogParserType })
    },
    {
      path: 'pfdetect/:id',
      name: 'syslogParser',
      component: SyslogParserView,
      props: (route) => ({ storeName: '$_syslog_parsers', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_syslog_parsers/getSyslogParser', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'pfdetect/:id/clone',
      name: 'cloneSyslogParser',
      component: SyslogParserView,
      props: (route) => ({ storeName: '$_syslog_parsers', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_syslog_parsers/getSyslogParser', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'syslog',
      name: 'syslogForwarders',
      component: SyslogForwardersList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'syslog/new',
      name: 'newSyslogForwarder',
      component: SyslogForwarderView,
      props: (route) => ({ storeName: '$_syslog_forwarders', isNew: true })
    },
    {
      path: 'syslog/:id',
      name: 'syslogForwarder',
      component: SyslogForwarderView,
      props: (route) => ({ storeName: '$_syslog_forwarders', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_syslog_forwarders/getSyslogForwarder', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'syslog/:id/clone',
      name: 'cloneSyslogForwarder',
      component: SyslogForwarderView,
      props: (route) => ({ storeName: '$_syslog_forwarders', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_syslog_forwarders/getSyslogForwarder', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'wrix',
      name: 'wrixLocations',
      component: WrixLocationsList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'wrix/new',
      name: 'newWrixLocation',
      component: WrixLocationView,
      props: (route) => ({ storeName: '$_wrix_locations', isNew: true })
    },
    {
      path: 'wrix/:id',
      name: 'wrixLocation',
      component: WrixLocationView,
      props: (route) => ({ storeName: '$_wrix_locations', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_wrix_locations/getWrixLocation', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'wrix/:id/clone',
      name: 'cloneWrixLocation',
      component: WrixLocationView,
      props: (route) => ({ storeName: '$_wrix_locations', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_wrix_locations/getWrixLocation', to.params.id).then(object => {
          next()
        })
      }
    },
    /**
     * Network Configuration
     */
    {
      path: 'networkconfiguration',
      component: NetworkConfigurationSection
    },
    {
      path: 'floating_devices',
      name: 'floating_devices',
      component: FloatingDevicesList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'floating_devices/new',
      name: 'newFloatingDevice',
      component: FloatingDeviceView,
      props: (route) => ({ storeName: '$_floatingdevices', isNew: true })
    },
    {
      path: 'floating_device/:id',
      name: 'floating_device',
      component: FloatingDeviceView,
      props: (route) => ({ storeName: '$_floatingdevices', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_floatingdevices/getFloatingDevice', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'floating_device/:id/clone',
      name: 'cloneFloatingDevice',
      component: FloatingDeviceView,
      props: (route) => ({ storeName: '$_floatingdevices', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_floatingdevices/getFloatingDevice', to.params.id).then(object => {
          next()
        })
      }
    },
    /**
     *  Advanced Access Configuration
     */
    {
      path: 'captive_portal',
      name: 'captive_portal',
      component: CaptivePortalView,
      props: (route) => ({ storeName: '$_bases', query: route.query.query })
    },
    {
      path: 'portal_modules',
      name: 'portal_modules',
      component: PortalModulesList,
      props: (route) => ({ storeName: '$_portalmodules', query: route.query.query })
    },
    {
      path: 'portal_modules/new/:type',
      name: 'newPortalModule',
      component: PortalModuleView,
      props: (route) => ({ storeName: '$_portalmodules', isNew: true, moduleType: route.params.type }),
      beforeEnter: (to, from, next) => {
        store.dispatch('config/getSources').then(object => {
          next()
        })
      }
    },
    {
      path: 'portal_module/:id',
      name: 'portal_module',
      component: PortalModuleView,
      props: (route) => ({ storeName: '$_portalmodules', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_portalmodules/getPortalModule', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'portal_module/:id/clone',
      name: 'clonePortalModule',
      component: PortalModuleView,
      props: (route) => ({ storeName: '$_portalmodules', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_portalmodules/getPortalModule', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'billing_tiers',
      name: 'billing_tiers',
      component: BillingTiersList,
      props: (route) => ({ query: route.query.query })
    },
    {
      path: 'billing_tiers/new',
      name: 'newBillingTier',
      component: BillingTierView,
      props: (route) => ({ storeName: '$_billing_tiers', isNew: true })
    },
    {
      path: 'billing_tier/:id',
      name: 'billing_tier',
      component: BillingTierView,
      props: (route) => ({ storeName: '$_billing_tiers', id: route.params.id }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_billing_tiers/getBillingTier', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'billing_tier/:id/clone',
      name: 'cloneBillingTier',
      component: BillingTierView,
      props: (route) => ({ storeName: '$_billing_tiers', id: route.params.id, isClone: true }),
      beforeEnter: (to, from, next) => {
        store.dispatch('$_billing_tiers/getBillingTier', to.params.id).then(object => {
          next()
        })
      }
    },
    {
      path: 'access_duration',
      name: 'access_duration',
      component: AccessDurationView,
      props: (route) => ({ storeName: '$_bases', query: route.query.query })
    },
    /**
     *  Network Configuration
     */
    {
      path: 'certificates',
      redirect: 'certificate/http'
    },
    {
      path: 'certificate/:id',
      name: 'certificate',
      component: CertificatesView,
      props: (route) => ({ storeName: '$_certificates', id: route.params.id })
    }
  ]
}

export default route
