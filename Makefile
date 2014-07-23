all:
	@echo "Please chose which documentation to build:"
	@echo ""
	@echo " 'pdf' will build all guide using the PDF format"
	@echo " 'doc-admin-pdf' will build the Administration guide in PDF"
	@echo " 'doc-developers-pdf' will build the Develoeprs guide in PDF"
	@echo " 'doc-networkdevices-pdf' will build the Network Devices Configuration guide in PDF"

pdf: doc-admin-pdf doc-developers-pdf doc-networkdevices-pdf

doc-admin-pdf:
	asciidoc -a docinfo2 -b docbook -d book -d book -o docs/docbook/PacketFence_Administration_Guide.docbook docs/PacketFence_Administration_Guide.asciidoc; fop -c docs/fonts/fop-config.xml   -xsl docs/docbook/xsl/packetfence-fo.xsl -xml docs/docbook/PacketFence_Administration_Guide.docbook  -pdf docs/PacketFence_Administration_Guide.pdf

doc-developers-pdf:
	asciidoc -a docinfo2 -b docbook -d book -d book -o docs/docbook/PacketFence_Developers_Guide.docbook docs/PacketFence_Developers_Guide.asciidoc; fop -c docs/fonts/fop-config.xml   -xsl docs/docbook/xsl/packetfence-fo.xsl -xml docs/docbook/PacketFence_Developers_Guide.docbook  -pdf docs/PacketFence_Developers_Guide.pdf

doc-networkdevices-pdf:
	asciidoc -a docinfo2 -b docbook -d book -d book -o docs/docbook/PacketFence_Network_Devices_Configuration.docbook docs/PacketFence_Network_Devices_Configuration_Guide.asciidoc; fop -c docs/fonts/fop-config.xml   -xsl docs/docbook/xsl/packetfence-fo.xsl -xml docs/docbook/PacketFence_Network_Devices_Configuration.docbook -pdf docs/PacketFence_Network_Devices_Configuration.pdf

.PHONY: configurations

configurations:
	find -type f -name '*.example' -print0 | while read -d $$'\0' file; do cp -n $$file "$$(dirname $$file)/$$(basename $$file .example)"; done

.PHONY: ssl-certs

conf/ssl/server.crt:
	openssl req -x509 -new -nodes -days 365 -batch\
    	-out /usr/local/pf/conf/ssl/server.crt\
    	-keyout /usr/local/pf/conf/ssl/server.key\
    	-nodes -config /usr/local/pf/conf/openssl.cnf

bin/pfcmd: src/pfcmd
	cp src/pfcmd bin/pfcmd

bin/ntlm_auth_wrapper: src/ntlm_auth_wrap.c
	cc  -std=c99  -Wall  src/ntlm_auth_wrap.c -o bin/ntlm_auth_wrapper

.PHONY:sudo

sudo:
	if (grep "^Defaults.*requiretty" /etc/sudoers > /dev/null  ) ;\
		then sed -i 's/^Defaults.*requiretty/#Defaults requiretty/g' /etc/sudoers;\
	fi
	if (grep "^pf ALL=NOPASSWD:.*/sbin/iptables.*/usr/sbin/ipset" /etc/sudoers > /dev/null  ) ;\
		then sed -i 's/^\(pf ALL=NOPASSWD:.*\/sbin\/iptables.*\/usr\/sbin\/ipset\)/#\1/g' /etc/sudoers;\
	fi
	if ! (grep "^pf ALL=NOPASSWD:.*/sbin/iptables.*/usr/sbin/ipset.*/sbin/ip.*/sbin/vconfig.*/sbin/route.*/sbin/service.*/usr/bin/tee.*/usr/local/pf/sbin/pfdhcplistener.*/bin/kill.*/usr/sbin/dhcpd.*/usr/sbin/radiusd.*/usr/sbin/snort.*/usr/sbin/suricata" /etc/sudoers > /dev/null  ) ; then\
		echo "pf ALL=NOPASSWD: /sbin/iptables, /usr/sbin/ipset, /sbin/ip, /sbin/vconfig, /sbin/route, /sbin/service, /usr/bin/tee, /usr/local/pf/sbin/pfdhcplistener, /bin/kill, /usr/sbin/dhcpd, /usr/sbin/radiusd, /usr/sbin/snort, /usr/bin/suricata" >> /etc/sudoers;\
	fi
	if ! ( grep '^Defaults:pf.*!requiretty' /etc/sudoers > /dev/null ) ; then\
		echo 'Defaults:pf !requiretty' >> /etc/sudoers;\
	fi

.PHONY:permissions

permissions:
	./bin/pfcmd fixpermissions
	
raddb/certs/dh:
	cd raddb/certs; make dh

lib/pf/pfcmd/pfcmd_pregrammar.pm:
	/usr/bin/perl -Ilib -MParse::RecDescent -Mpf::pfcmd::pfcmd -w -e 'Parse::RecDescent->Precompile($$grammar, "pfcmd_pregrammar");'
	mv pfcmd_pregrammar.pm lib/pf/pfcmd/

.PHONY: raddb-sites-enabled

raddb/sites-enabled:
	mkdir raddb/sites-enabled
	cd raddb/sites-enabled;\
	for f in control-socket default inner-tunnel packetfence packetfence-soh packetfence-tunnel dynamic-clients;\
		do ln -s ../sites-available/$$f $$f;\
	done

.PHONY: translation

translation:
	for TRANSLATION in de en es fr he_IL it nl pl_PL pt_BR; do\
		/usr/bin/msgfmt conf/locale/$$TRANSLATION/LC_MESSAGES/packetfence.po\
		  --output-file conf/locale/$$TRANSLATION/LC_MESSAGES/packetfence.mo;\
	done

.PHONY: mysql-schema

mysql-schema:
	if [ ! -f "/usr/local/pf/db/pf-schema.sql" ]; then\
		cd /usr/local/pf/db;\
		VERSIONSQL=$$(ls pf-schema-* |sort -r | head -1);\
		ln -s $$VERSIONSQL ./pf-schema.sql;\
	fi

.PHONY: chown_pf

chown_pf:
	chown -R pf:pf *

devel: configurations conf/ssl/server.crt bin/pfcmd raddb/certs/dh sudo lib/pf/pfcmd/pfcmd_pregrammar.pm translation mysql-schema raddb/sites-enabled chown_pf permissions
