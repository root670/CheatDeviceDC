#
# Cheat Device for Dreamcast
# by Wes Castro
#

ELF_NAME=cheatdevice.elf

all: clean $(ELF_NAME)

include $(KOS_BASE)/Makefile.rules

OBJS += src/main.o

RELEASE_TEMP_FILES = stripped-$(ELF_NAME) cheatdevice.bin ip.txt IP.TMPL IP.BIN

clean:
	-rm -f $(ELF_NAME) src/*.o
	set -x
	rm -rf iso
	rm -f *.iso *.cdi $(RELEASE_TEMP_FILES)
	set +x

version:
	./resources/version.sh > src/version.h

$(ELF_NAME): version $(OBJS) 
	$(KOS_CC) $(KOS_CFLAGS) $(KOS_LDFLAGS) -o $(ELF_NAME) $(KOS_START) $(OBJS) $(DATAOBJS) $(OBJEXTRA) $(KOS_LIBS)

run: $(ELF_NAME)
	$(KOS_LOADER) $(ELF_NAME)

release: all
	$(KOS_STRIP) $(ELF_NAME) -o stripped-$(ELF_NAME)
	sh-elf-objcopy -R .stack -O binary stripped-$(ELF_NAME) cheatdevice.bin

	# Scramble bin file for self-booting
	mkdir iso &>/dev/null
	scramble cheatdevice.bin iso/1ST_READ.BIN

	# Generate IP.BIN
	cp resources/ip.txt resources/IP.TMPL .
	makeip ip.txt IP.BIN
	
	# Generate ISO and CDI images
	genisoimage -V CheatDeviceDC -G IP.BIN -joliet -rock -l -o CheatDeviceDC.iso iso
	cdi4dc CheatDeviceDC.iso CheatDeviceDC.cdi -d
	rm -rf iso
	rm -f $(RELEASE_TEMP_FILES) src/*.o
