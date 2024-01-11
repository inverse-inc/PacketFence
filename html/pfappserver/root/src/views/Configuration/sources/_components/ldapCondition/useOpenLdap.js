import _ from 'lodash';
import {
  parseLdapStringToArray, sendLdapSearchRequest
} from '@/views/Configuration/sources/_components/ldapCondition/common';


function useOpenLdap(form) {

  const performSearch = (filter, scope, attributes, base_dn) => {
    return sendLdapSearchRequest({...form.value}, filter, scope, attributes, base_dn)
  }

  const getSubSchemaDN = () => {
    return performSearch(null, 'base', ['subSchemaSubEntry'], form.value.basedn)
      .then((response) => {
        let firstAttribute = response.data[Object.keys(response.data)[0]]
        return firstAttribute['subschemaSubentry']
      })
  }

  const fetchAttributeTypes = (subSchemaDN) => {
    return performSearch('(objectclass=subschema)',
      'base',
      ['attributeTypes'],
      subSchemaDN)
      .then((response) => {
        return response.data[Object.keys(response.data)[0]]['attributeTypes']
      })
  }

  const getAttributes = () => {
    return getSubSchemaDN()
      .then((subSchemaDN) => {
        return fetchAttributeTypes(subSchemaDN)
      })
      .then((attributeTypes) => {
        return extractAttributeNames(attributeTypes)
      })
  }

  const checkConnection = () => {
    return getSubSchemaDN().then(() => true).catch(() => false)
  }

  return {
    getAttributes: getAttributes,
    checkConnection: checkConnection,
    performSearch: performSearch
  }
}

function extractAttributeNames(attributes) {
  let attributeNames = []
  attributes.forEach((attribute) => {
    const properties = attribute.split(' ')
    const attributeName = properties[properties.indexOf('NAME') + 1]
    if (attributeName === '(') {
      attributeNames.push(...extractAttributeNameAliases(properties))
    } else {
      attributeNames.push(_.trim(attributeName, '\''))
    }
  })
  return attributeNames
}

function extractAttributeNameAliases(attributeProperties) {
  const attributeStartIndex = attributeProperties.indexOf('NAME') + 1
  attributeProperties = attributeProperties.slice(attributeStartIndex)
  attributeProperties = attributeProperties.slice(0, attributeProperties.indexOf(')') + 1)
  const attributeString = attributeProperties.join(' ')

  return parseLdapStringToArray(attributeString).map((item) => _.trim(item, '\''))
}

export default useOpenLdap
