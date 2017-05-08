wink_dir = $(shell pwd)

install: /usr/local/bin/wink

/usr/local/bin/wink: Makefile
	@echo '#!/bin/bash\n\ncd ${wink_dir} && bundle exec ruby wink.rb \x24@' > $@
	@chmod +x $@
	@echo "Wink has been installed to $@"
