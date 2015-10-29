# rcd -- IP Address Obfuscator

[![Build Status](https://travis-ci.org/wkoszek/rcd.svg)](https://travis-ci.org/wkoszek/rcd)

The idea was that the .log file can be released to 3rd person without
actually disclossing what real IPs were. The same IP gets replaced with
other made-up IP, so that the overall structure of the log file is preserved
for the analysis.

# How to build?

Just run:

	make

# How to test

Sample test data is in test/. To run tests, run:

	make tests
	make check

# Author

- Wojciech Adam Koszek, [wojciech@koszek.com](mailto:wojciech@koszek.com)
- [http://www.koszek.com](http://www.koszek.com)
