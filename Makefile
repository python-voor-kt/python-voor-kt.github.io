# Instructiefilmpjes bouwen uit editlists.
#
#   make          bouwt alle filmpjes die niet bij zijn
#   make list     toont de gevonden editlists
#   make clean    verwijdert alles wat gebouwd is
#
# Per editlist posts/<post>/media/<naam>.yaml ontstaan twee bestanden in
# dezelfde map:
#
#   <naam>.mp4       de montage volgens de editlist
#   <naam>-web.mp4   idem, met de index vooraan; dit zet je in de post
#
# De `output:` in de yaml moet dus <naam>.mp4 heten, gelijk aan de yaml zelf.

EDITLISTS := $(shell find posts -type f -name '*.yaml')
CUTS      := $(EDITLISTS:.yaml=.mp4)
WEB       := $(EDITLISTS:.yaml=-web.mp4)
TMPDIRS   := $(addsuffix tmp,$(sort $(dir $(EDITLISTS))))

.PHONY: all list clean
all: $(WEB)

# Zonder dit ruimt make de montage op als 'tussenbestand', waardoor de
# volgende run onnodig opnieuw hercodeert.
.SECONDARY: $(CUTS)

# Editlists in dezelfde map delen de werkmap tmp/, die na afloop wordt
# opgeruimd. Parallel bouwen zou de een die van de ander laten weggooien.
.NOTPARALLEL:

# Knippen en plakken. --reencode is nodig omdat knippen met stream copy
# naar het dichtstbijzijnde keyframe schuift.
%.mp4: %.yaml
	uv run ffmpeg-editlist $< $(@D) -o $(@D) -f --reencode
	@rm -rf $(@D)/tmp

# Webversie: `+faststart` zet de index vooraan, zodat afspelen begint
# voordat het downloaden klaar is.
%-web.mp4: %.mp4
	ffmpeg -v error -i $< -c copy -movflags +faststart -y $@

list:
	@printf '%s\n' $(EDITLISTS)

clean:
	@rm -f $(CUTS) $(WEB)
	@rm -rf $(TMPDIRS)
