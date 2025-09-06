RGBLINK = rgblink
RGBFIX  = rgbfix
RGBASM  = rgbasm
RGBGFX  = rgbgfx

TITLE = THELATEDEMO
VER = 2.0
TARGET = latedemo_$(VER).gbc
SYM = latedemo_$(VER).sym

RGBLINKFLAGS = -n $(SYM)
RGBFIXFLAGS  = -v -p 0xFF -m MBC1 -t $(TITLE) -c --sgb-compatible --old-licensee 0x33
RGBASMFLAGS  = -I inc -I art -I art/intro

OBJS = \
	src/intro/intro.o \
	src/intro/intro_drop.o \
	src/intro/intro_lut.o \
	src/compo.o \
	src/oamdma.o \
	src/sgb.o \
	src/hUGEDriver.o \
	src/song_ending.o \

INC = \
	inc/hardware.inc \
	inc/sgb.inc \
	inc/common.inc \

INTRO_INC = \
	inc/intro.inc \

INTRO_1BPP = \
	art/intro/intro_not.1bpp \
	art/intro/intro_top.1bpp \
	art/intro/intro_by.1bpp \
	art/intro/intro_reg.1bpp \
	art/intro/intro_n0.1bpp \
	art/intro/intro_i.1bpp \
	art/intro/intro_n.1bpp \
	art/intro/intro_t.1bpp \
	art/intro/intro_e.1bpp \
	art/intro/intro_d.1bpp \
	art/intro/intro_o.1bpp \

COMPO_2BPP = \
	art/compo/compo_logo.2bpp \
	art/compo/compo_logo_gbc.2bpp \
	art/compo/compo_logo_sgb.2bpp \
	art/compo/compo_text.2bpp \
	art/compo/compo_obj.2bpp \
	art/compo/compo_obj_sgb.2bpp \
	art/compo/compo_button.2bpp \

COMPO_EXTRAS = \
	art/compo/compo_logo.tilemap \
	art/compo/compo_text.tilemap \
	art/compo/compo_obj.tilemap \
	art/compo/compo_obj.pal \
	art/compo/compo_button.pal \
	art/compo/compo_logo_gbc.tilemap \
	art/compo/compo_logo.pal \

COMPO_BORDER = \
	art/compo/border/compo_border.4bpp \
	art/compo/border/compo_border.tilemap \
	art/compo/border/compo_border.pal \

all: $(TARGET)

clean:
	rm -f $(TARGET) $(SYM) $(OBJS) $(INTRO_1BPP) $(COMPO_2BPP) $(COMPO_EXTRAS)

$(TARGET): $(OBJS)
	$(RGBLINK) $(RGBLINKFLAGS) $^ -o $@
	$(RGBFIX) $(RGBFIXFLAGS) $@

src/intro/intro.o: src/intro/intro.asm $(INC) $(INTRO_1BPP)

src/intro/%.o: src/intro/%.asm $(INC) $(INTRO_INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

src/compo.o: src/compo.asm $(INC) $(INTRO_INC) $(COMPO_2BPP) $(COMPO_BORDER)
	$(RGBASM) $(RGBASMFLAGS) -I art/compo -I art/compo/border $< -o $@

%.o: %.asm $(INC)
	$(RGBASM) $(RGBASMFLAGS) $< -o $@

art/intro/%.1bpp: art/intro/%.png
	$(RGBGFX) -Z -d1 $< -o $@

art/compo/compo_logo.2bpp: art/compo/compo_logo.png
	$(RGBGFX) -u $< -o $@ -T

art/compo/compo_logo_gbc.2bpp: art/compo/compo_logo_gbc.png
	$(RGBGFX) -u $< -o $@ -T -p art/compo/compo_logo.pal

art/compo/compo_button.2bpp: art/compo/compo_button.png
	$(RGBGFX) -u $< -o $@ -P

art/compo/compo_text.2bpp: art/compo/compo_text.png
	$(RGBGFX) -u $< -o $@ -T -b 0x40

art/compo/compo_obj.2bpp: art/compo/compo_obj.png
	$(RGBGFX) -u $< -o $@ -T -P -b 0xB0

art/compo/%.2bpp: art/compo/%.png
	$(RGBGFX) -u $< -o $@
