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
