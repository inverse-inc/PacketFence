package detectparser

import (
	"testing"
)

func TestFortiGateDhcpParse(t *testing.T) {
	parser, _ := NewFortiGateDhcpParser(nil)
	var parseTests = []ParseTest{
		{
			Line: `date=2024-12-24 time=11:56:25 devname="FGT50E3U16014289" devid="FGT50E3U16014289" logid="0100026001" type="event" subtype="system" level="information" vd="root" eventtime=1735059387564643583 tz="-0500" logdesc="DHCP Ack log" interface="VLAN_41" dhcp_msg="Ack" mac="B0:2A:43:C1:97:DC" ip=192.168.41.249 lease=300 hostname="N/A" msg="DHCP server sends a DHCPACK"`,
			Calls: []ApiCall{
				&PfqueueApiCall{
					Method: "event_add",
					Params: []interface{}{
						"srcip", "172.21.5.11",
						"events", map[string]interface{}{
							"detect": "0316013057",
						},
					},
				},
			},
		},
		{
			Line:  `date=2024-12-24 time=11:56:25 devname="FGT50E3U16014289" devid="FGT50E3U16014289" logid="0100026001" type="event" subtype="system" level="information" vd="root" eventtime=1735059387564643583 tz="-0500" logdesc="DHCP Ack log" interface="VLAN_41" dhcp_msg="Ack" mac="B0:2A:43:C1:97:DC" ip=192.168.41.249 lease=300 hostname="N/A" msg="DHCP server sends a DHCPACK"`,
			Calls: nil,
		},
	}
	RunParseTests(parser, parseTests, t)
}
