import apiCall from '@/utils/api';
import {intsToStrings} from '@/utils/convert';

export const ldapFormsSupported = ['LDAP', 'AD', 'EDIR']

export const parseLdapStringToArray = (ldapString) => {
  const ldapArrayRegex = new RegExp('^[[(]')
  if (ldapArrayRegex.test(ldapString)) {
    return ldapString.split(' ')
      .filter((item) => !['[', ']', '(', ')'].includes(item))
  } else {
    return [ldapString]
  }
}

export const sendLdapSearchRequest = (server,
                                      filter = null,
                                      scope = null,
                                      attributes = null,
                                      base_dn = null) => {
  server = intsToStrings(server)
  return apiCall.postQuiet('ldap/search',
    {
      server: server,
      search_query: {
        filter: filter,
        scope: scope,
        attributes: attributes,
        base_dn: base_dn,
      }
    }
  ).then(response => {
    delete response.data.quiet;
    return response
  })
}
