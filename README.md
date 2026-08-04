# python-voor-kt

Bron van <https://python-voor-kt.github.io>, een Quarto-website met
instructiemateriaal over Python en `uv` voor de opleiding Klinische Technologie.

**Deze repository is niet openbaar.** De gepubliceerde site staat in een aparte
publieke repository, die alleen het bouwresultaat bevat. Issues van studenten
komen dáár binnen, niet hier.

## Lokaal werken

```
uv sync
quarto preview
```

## Structuur

| Pad | Wat |
| --- | --- |
| `posts/` | De handleidingen, elk in een eigen map met bijbehorende afbeeldingen en video's. |
| `_deploy/` | Alles wat naar de publieke repo moet maar niet op de site hoort. |
| `_quarto.yml` | Sitebrede configuratie: navigatie, thema, `site-url`. |
| `.build-commit.toml` | Hoe de site gebouwd en gepubliceerd wordt. |

Quarto negeert mappen die met `_` of `.` beginnen, dus `_deploy/` komt nooit
per ongeluk als pagina op de site terecht. Ook `README.md` wordt door Quarto
overgeslagen — dit bestand blijft dus intern.

In `_deploy/` staat:

| Pad | Waarvoor |
| --- | --- |
| `README.md` | Wat bezoekers van de publieke repo te zien krijgen. |
| `.github/ISSUE_TEMPLATE/` | De sjablonen voor issues. |
| `.nojekyll` | Zet Jekyll uit op GitHub Pages, zodat de site precies zo geserveerd wordt als Quarto hem bouwt. |

## Publiceren

```
git build-commit push
```

Dat draait `quarto render`, kopieert `_deploy/` erbij, zet het resultaat als
losse commit op de branch `build` en pusht die naar de remote `pages`.

Twee dingen moeten in de publieke repo goed staan, anders werkt het stil niet:

- **Default branch moet `build` zijn.** GitHub leest issue-templates alleen uit
  de default branch. Staat die op `main`, dan krijgen studenten een leeg
  formulier zonder foutmelding.
- **De repo moet publiek zijn.** Nodig voor de issues, en GitHub Pages werkt op
  een private repo alleen met een betaald plan.

De labels `fout`, `onduidelijk` en `verzoek` moeten in die repo bestaan. Bestaan
ze niet, dan worden ze zonder waarschuwing niet toegekend.

## Issue-templates

Staan in `_deploy/.github/ISSUE_TEMPLATE/`. Ze horen bij de publieke repo, want
daar melden studenten dingen. Aanpassen doe je hier; ze gaan bij de volgende
publicatie mee.

Issues staan dus los van de broncode. Je kunt ze niet sluiten met `Fixes #12`
vanuit een commit — dat werkt alleen binnen dezelfde repository. Sluiten gaat
met de hand.

## Instructiefilmpjes

### Opnemen

OBS op macOS, met Windows in een VM. Gebruik de **hardware-encoder**: de VM wil
de CPU hebben, en software-encoding levert dropped frames op die je achteraf
niet meer repareert. Dat de compressie daarvan minder goed is maakt niet uit,
want de opname is een wegwerpbestand.

| Instelling | Waarde |
| --- | --- |
| Encoder | Hardware (Apple VT **H264**) |
| Recording Format | hybrid MP4 |
| Recording Quality | Indistinguishable Quality, Large File Size |
| Base én Output resolutie | 1920×1080, gelijk aan elkaar |
| FPS | 30 |

Niet schalen in OBS: downscaling is wat schermtekst het hardst kapotmaakt.
Neem Windows op met 150% scaling. Dat helpt niet alleen de leesbaarheid — H.264
slaat kleur op kwart resolutie op (`yuv420p`), wat normaal gesproken gekleurde
tekst uitsmeert, en door die schaling valt die schade grotendeels weg.

Kies **H264**, niet HEVC: in de Apple VT HEVC-encoder werkt CRF omgekeerd.

Vermijd platte `mp4` en `mov` als opnameformaat. Daar staat de index achteraan,
dus bij een crash is de opname onbruikbaar. `hybrid MP4` heeft dat probleem niet.

### Knippen en plakken

Knippen met `-c copy` kan alleen op keyframes; ffmpeg schuift je knippunt dan
stilletjes een paar seconden op. Dus: knippen mét hercodering, plakken zónder.
Zo houd je één generatie kwaliteitsverlies in totaal.

Knip elk fragment, met de tijden zoals QuickTime ze toont:

```
ffmpeg -i deel1.mov -ss 00:00:03 -to 00:00:45 \
  -c:v libx264 -crf 20 -preset slow -g 60 -pix_fmt yuv420p -an deel1-kort.mp4
```

`-ss` en `-to` staan bewust **ná** `-i`. Zet je ze ervóór, dan rekent ffmpeg
vanaf het knippunt en klopt je eindtijd niet meer.

Plak ze daarna aan elkaar:

```
printf "file 'deel1-kort.mp4'\nfile 'deel2-kort.mp4'\n" > lijst.txt
ffmpeg -f concat -safe 0 -i lijst.txt -c copy -movflags +faststart uitleg.mp4
```

Hier mag `-c copy` wel, want beide fragmenten hebben identieke instellingen.

Hoef je alleen kop en staart eraf, dan is het knipcommando genoeg — zet er dan
`-movflags +faststart` bij.

### Waarom die vlaggen

| Vlag | Waarom |
| --- | --- |
| `-g 60` | Elke 2 seconden een keyframe, zodat studenten vlot kunnen terugspoelen. |
| `-movflags +faststart` | Zet de index vooraan; afspelen begint vóór het downloaden klaar is. |
| `-an` | Gooit de lege audiotrack eruit. |
| `-pix_fmt yuv420p` | Nodig, anders spelen sommige browsers het bestand niet af. |

### Als er niet geknipt hoeft te worden

Een opname die al klein en efficiënt gecodeerd is, hoef je niet te hercoderen.
Alleen de container omzetten is verliesvrij en klaar in een seconde:

```
ffmpeg -i opname.mov -c copy -movflags +faststart -an uitleg.mp4
```

### Kwaliteit controleren

```
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate,bit_rate \
  -of default=noprint_wrappers=1 opname.mov
```

Een lage gemiddelde bitrate is bij schermopnames geen alarmsignaal: een
grotendeels stilstaand beeld kost H.264 bijna niets. Wat telt is hoe het eruitziet
als er wél iets gebeurt. Pauzeer op een beeld met code of menutekst en kijk of de
letters scherp zijn, of pak er een frame uit:

```
ffmpeg -i opname.mov -vf "select=eq(n\,300)" -vframes 1 frame.png
```

Vage vegen rond tekst tijdens scrollen krijg je er niet meer uit; dan is opnieuw
opnemen sneller dan erop blijven duwen.

### Waar ze heen gaan

Naast de post waar ze bij horen, bijvoorbeeld
`posts/positron-installeren/uitleg.mp4`. Gewoon in git, zonder LFS.

**Git LFS werkt niet met GitHub Pages** — Pages lost LFS-pointers niet op en
serveert het pointerbestandje in plaats van de video, zonder foutmelding. Bij
bestanden van een paar MB is LFS bovendien nergens voor nodig.

Pages staat 1 GB per site toe en 100 GB verkeer per maand, dus zo'n 300 filmpjes
van 3 MB. Loopt het richting een paar honderd MB, dan is een instellingsplatform
(Brightspace, Kaltura, SURF) de volgende stap — niet LFS.

Inbouwen in een pagina:

```
{{< video uitleg.mp4 >}}
```

Bij meerdere filmpjes op één pagina liever losse HTML met `preload="metadata"`,
anders begint de browser ze allemaal tegelijk te laden.
