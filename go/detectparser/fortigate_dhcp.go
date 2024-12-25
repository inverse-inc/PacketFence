package detectparser

import (
	"regexp"

	"github.com/inverse-inc/go-utils/sharedutils"
)

var fortiGateDhcpRegexPattern1 = regexp.MustCompile(`\s+`)
var fortiGateDhcpRegexPattern2 = regexp.MustCompile(`\=`)

type FortiGateDhcpParser struct {
	Pattern1, Pattern2 *regexp.Regexp
	parser
}

func (s *FortiGateDhcpParser) Parse(line string) ([]ApiCall, error) {
	matches := s.Pattern1.Split(line, -1)
	var mac, ip, lease, hostname, ack string
	var err error
	for _, str := range matches {
		args := s.Pattern2.Split(str, 2)
		if len(args) <= 1 {
			continue
		}

		if args[0] == "mac" {
			mac = args[1]
		} else if args[0] == "ip" {
			ip = args[1]
		} else if args[0] == "lease" {
			lease = args[1]
		} else if args[0] == "hostname" {
			hostname = args[1]
		} else if args[0] == "dhcp_msg" {
			ack = args[1]
		}
	}

	if ack == "" || ack != "Ack" {
		return nil, nil
	}

	if ip, err = sharedutils.CleanIP(ip); err != nil {
		return nil, nil
	}

	if err := s.NotRateLimited(mac + ":" + ip); err != nil {
		return nil, err
	}

	return []ApiCall{
		&PfqueueApiCall{
			Method: "update_ip4log",
			Params: []interface{}{
				"mac", mac,
				"ip", ip,
				"lease_length", lease,
			},
		},
		&PfqueueApiCall{
			Method: "modify_node",
			Params: []interface{}{
				"mac", mac,
				"computername", hostname,
			},
		},
	}, nil

}

func NewFortiGateDhcpParser(config *PfdetectConfig) (Parser, error) {
	return &FortiGateDhcpParser{
		Pattern1: fortiGateDhcpRegexPattern1,
		Pattern2: fortiGateDhcpRegexPattern2,
		parser:   setupParser(config),
	}, nil
}
