PREFIX?=/usr/local

install: $(PREFIX)/bin/wink

$(PREFIX)/bin/wink:
	cp bin/wink $@
	@chmod +x $@
