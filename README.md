# hsts_checker

Check HSTS crude script

To generate a list of domain names from pcap use:

tshark -r capture.pcap -Y "tls.handshake.type == 1" -T fields -e tls.handshake.extensions_server_name > dns_names.txt
