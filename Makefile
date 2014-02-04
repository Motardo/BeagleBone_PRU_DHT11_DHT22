CROSS_COMPILE?=arm-linux-gnueabi-
PASM=/usr/bin/pasm
LIBDIR_APP_LOADER?=/usr/lib
INCDIR_APP_LOADER?=/usr/include
BINDIR=bin
NAME=BeagleBone_PRU_DHT11_DHT22
EXECUTABLE_NAME=dht11

CFLAGS+= -Wall -I$(INCDIR_APP_LOADER) -D__DEBUG -O2 -mtune=cortex-a8 -march=armv7-a
LDFLAGS+=-L$(LIBDIR_APP_LOADER) -lprussdrv -lpthread
OBJDIR=obj
TARGET=$(BINDIR)/$(EXECUTABLE_NAME)
CFILE = $(NAME).c
_DEPS = 
DEPS = $(patsubst %,$(INCDIR_APP_LOADER)/%,$(_DEPS))

OBJ = $(OBJDIR)/$(EXECUTABLE_NAME).o
BIN = $(BINDIR)/$(EXECUTABLE_NAME).bin

$(TARGET): $(OBJ) $(BIN)
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $(TARGET) $(OBJ) $(LDFLAGS)

$(BIN): $(NAME).p $(NAME).hp
	$(PASM) -V3 -b $(NAME).p
	mkdir -p $(BINDIR)
	mv *.bin $(BINDIR)/$(EXECUTABLE_NAME).bin
	scp $(BINDIR)/$(EXECUTABLE_NAME).bin root@beaglebone.local:/tmp

$(OBJ): $(NAME).c $(DEPS)
	mkdir -p obj
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $(OBJ) $(CFILE)

.PHONY: clean

clean:
	rm -rf $(OBJDIR) $(BINDIR)
