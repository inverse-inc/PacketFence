import datetime
import re
import constants
import dns.resolver
import pytz
import log


# simplified IPv4 validator.
def is_ipv4(address):
    ipv4_pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
    return bool(ipv4_pattern.match(address))


def nt_time_to_datetime(nt_time):
    if nt_time == 0:
        return 0
    if nt_time == constants.NT_TIME_INF:
        return constants.MAX_INT32
    d = datetime.datetime(1601, 1, 1) + datetime.timedelta(microseconds=nt_time / 10)
    d = pytz.timezone('GMT').localize(d)
    return int(d.timestamp())


def to_ymd_hms(unix_timestamp):
    dt_object = datetime.datetime.fromtimestamp(unix_timestamp)
    formatted_time = dt_object.strftime('%Y-%m-%d %H:%M:%S')
    return formatted_time


def mask_password(password):
    try:
        if len(password) < 4:
            return '*' * len(password)
        else:
            return password[:2] + '*' * (len(password) - 4) + password[-2:]
    except (TypeError, AttributeError):
        return '*'


def dns_lookup(hostname, dns_server):
    if dns_server != "":
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = dns_server.split(",")
    else:
        resolver = dns.resolver.Resolver()

    try:
        answers = resolver.query(hostname, 'A')
        for answer in answers:
            return answer.address, ""
    except dns.resolver.NXDOMAIN:
        return "", "NXDOMAIN"
    except dns.exception.DNSException as e:
        return "", str(e)


def find_ldap_servers(domain, dns_server):
    query_name = f'_ldap._tcp.dc._msdcs.{domain}'

    if dns_server != "":
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = dns_server.split(",")
    else:
        resolver = dns.resolver.Resolver()

    try:
        ldap_servers = []

        answers = resolver.query(query_name, 'SRV')
        for srv in answers:
            priority = srv.priority
            weight = srv.weight
            port = srv.port
            target = srv.target.to_text()
            ldap_servers.append({
                'priority': priority,
                'weight': weight,
                'port': port,
                'target': target
            })

        return ldap_servers

    except dns.resolver.NoAnswer:
        log.debug(f'No SRV records found for {query_name}')
        return []
    except dns.resolver.NXDOMAIN:
        log.debug(f'Domain {domain} does not exist')
        return []
    except Exception as e:
        log.debug(f'An error occurred: {e}')
        return []


def expires(in_second):
    ts = datetime.datetime.now().timestamp() + in_second
    return int(ts)


def now():
    ts= datetime.datetime.now().timestamp()
    return int(ts)


def extract_event_timestamp(s):
    match = re.search(r'\d+', s)

    if match:
        number = float(match.group())
        number = number / 1000
        return int(number)
    else:
        return 0
