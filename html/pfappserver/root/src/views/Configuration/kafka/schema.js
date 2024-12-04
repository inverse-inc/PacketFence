import i18n from '@/utils/locale'
import yup from '@/utils/yup'

const schemaAuth = yup.object({
  user: yup.string().nullable().required().label(i18n.t('Username')),
  pass: yup.string().nullable().required().label(i18n.t('Password')),
})

const schemaAuths = yup.array().ensure().unique(i18n.t('Duplicate username'), ({ name }) => name).of(schemaAuth)

const schemaCluster = yup.object({
  name: yup.string().nullable().required().label(i18n.t('Name')),
  value: yup.string().nullable().required().label(i18n.t('Value')),
})

const schemaClusters = yup.array().ensure().unique(i18n.t('Duplicate key'), ({ name }) => name).of(schemaCluster)

const schemaHostConfigConfigItem = yup.object({
  name: yup.string().nullable().required().label(i18n.t('Key')),
  value: yup.string().nullable().required().label(i18n.t('Value'))
})

const schemaHostConfigConfig = yup.array().ensure().of(schemaHostConfigConfigItem)

const schemaHostConfig = yup.object({
  host: yup.string().nullable().required().label(i18n.t('Host'))
    .isCommonNameOrFQDN(i18n.t('Invalid Hostname.')),
  config: yup.array().ensure().of(schemaHostConfigConfig)
})

const schemaHostConfigs = yup.array().ensure().of(schemaHostConfig)

const schemaIpv4 = yup.string().nullable().required().label(i18n.t('IPv4'))
  .isIpv4()

const schemaIpv4s = yup.array().ensure().of(schemaIpv4)

const schemaIptables = yup.object({
  clients: schemaIpv4s,
  cluster_ips: schemaIpv4s,
})

export const schema = () => yup.object({
  admin: schemaAuth,
  auths: schemaAuths,
  cluster: schemaClusters,
  host_configs: schemaHostConfigs,
  iptables: schemaIptables,
})

export default schema

