data:
	# Get sample input file with some IP addresses
	lynx --dump https://www.freebsd.org/doc/handbook/firewalls-ipfw.html > _raw

	# Skip unprintable characters.
	-iconv -c -t UTF8 _raw > data.i || true

	rm -rf _raw
