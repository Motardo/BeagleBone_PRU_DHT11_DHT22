CROSS_COMPILE?=arm-linux-gnueabi-
PASM=/usr/bin/pasm
LIBDIR_APP_LOADER?=/usr/lib
INCDIR_APP_LOADER?=/usr/include
BINDIR=bin
NAME=BeagleBone_PRU_DHT11_DHT22

CFLAGS+= -Wall -I$(INCDIR_APP_LOADER) -D__DEBUG -O2 -mtune=cortex-a8 -march=armv7-a
LDFLAGS+=-L$(LIBDIR_APP_LOADER) -lprussdrv -lpthread
OBJDIR=obj
TARGET=$(BINDIR)/$(NAME)
CFILE = $(NAME).c
_DEPS = 
DEPS = $(patsubst %,$(INCDIR_APP_LOADER)/%,$(_DEPS))

OBJ = $(OBJDIR)/$(NAME).o
BIN = $(BINDIR)/$(NAME).bin

$(TARGET): $(OBJ) $(BIN)
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $(TARGET) $(OBJ) $(LDFLAGS)

$(BIN): $(NAME).p $(NAME).hp
	$(PASM) -V3 -b $(NAME).p
	mkdir -p $(BINDIR)
	scp *.bin root@beaglebone.local:/tmp
	mv *.bin $(BINDIR)

$(OBJ): $(NAME).c $(DEPS)
	mkdir -p obj
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $(OBJ) $(CFILE)

.PHONY: clean

clean:
	rm -rf $(OBJDIR) $(BINDIR)
