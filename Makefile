PREFIX?=/usr/local

install: $(PREFIX)/bin/wink

$(PREFIX)/bin:
	mkdir -p $@

$(PREFIX)/bin/wink: $(PREFIX)/bin
	cp bin/wink $@
	@chmod +x $@

