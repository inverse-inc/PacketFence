import { pfFieldType as fieldType } from '@/globals/pfField'

export const commonKeys = {
  KAFKA_CONTROLLER_LISTENER_NAMES:        [fieldType.SUBSTRING],
  KAFKA_CONTROLLER_QUORUM_VOTERS:         [fieldType.SUBSTRING],
  KAFKA_INTER_BROKER_LISTENER_NAME:       [fieldType.SUBSTRING],
  KAFKA_LISTENERS:                        [fieldType.SUBSTRING],
  KAFKA_LISTENER_SECURITY_PROTOCOL_MAP:   [fieldType.SUBSTRING],
  KAFKA_LOG_DIRS:                         [fieldType.SUBSTRING],
  KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: [fieldType.SUBSTRING],
  KAFKA_OPTS:                             [fieldType.SUBSTRING],
  KAFKA_PROCESS_ROLES:                    [fieldType.SUBSTRING],
  KAFKA_SASL_ENABLED_MECHANISMS:          [fieldType.SUBSTRING]
}

export const clusterKeys = {
  CLUSTER_ID:                             [fieldType.SUBSTRING],
  ...commonKeys
}

export const clusterFields = Object.entries(clusterKeys).reduce((fields, [key, types]) => {
  return { ...fields, [key]: { value: key, text: key, types } }
}, {})

export const configKeys = {
  KAFKA_NODE_ID:                          [fieldType.INTEGER],
  KAFKA_ADVERTISED_LISTENERS:             [fieldType.SUBSTRING],
  ...commonKeys
}

export const configFields = Object.entries(configKeys).reduce((fields, [key, types]) => {
  return { ...fields, [key]: { value: key, text: key, types } }
}, {})

