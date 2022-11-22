<!-- markdownlint-disable MD041 -->
<div align="center">

<h1>wbhdoc</h1>

![example workflow](https://github.com/wbh-community/wbhdoc/actions/workflows/build.yml/badge.svg)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
![Lines](https://img.shields.io/tokei/lines/github/wbh-community/wbhdoc?label=lines%20of%20code)

</div>

---
Der wbhdoc Container dient zur einfachen Erstellung von Hausarbeiten und Abschlussarbeiten mit einem vorgefertigten Template welches den Leitlinien entspricht. 
Dabei bringt der Container alle notwendigen abhängigkeiten mit um aus einem Markdown File ein PDF zu erzeugen. Die Anwendung beschränkt sich dabei auf zwei einfache
Parameter, welche beim Aufruf des Containers mitgegeben werden. 

## Nutzung

Um den Container nutzen zu können ist eine [Docker](https://docs.docker.com/desktop/) oder [Podman](https://podman.io/getting-started/installation) (empfohlen) installation notwendig.
Soweit nicht anders beschrieben, können alle Kommandos mit `docker` durch `podman` ausgetauscht werden.

1. Image Download: `docker pull quay.io/wbh-community/wbhdoc:latest`
2. Aufruf des Container
   - Docker: `docker run -it --rm --volume $(pwd):/data:Z --user $(id -u):$(id -g) quay.io/wbh-community/wbhdoc:latest <option>`
   - Podman: `podman run -it --rm --volume $(pwd):/data:Z quay.io/wbh-community/wbhdoc:latest <option>`

**Tip:** Richte dir ein alias für den Containeraufrum ein, dann beschränkt sich der Aufruf auf den Alias + die übergabe der Option:

```bash
# Bash: folgende Zeile zur bash.rc henzufügen
alias wbhdoc=`<containeraufruf>`

# Fish
alias --save wbhdoc `<containeraufruf>`

# Nutzung:
wbhdoc -i # zum initialisieren
wbhdoc -b # zum bauen des Dokuments
```

### Dokumente Initialisieren

Durch die Übergabe der Option `-i` beim Aufruf des Containers wird ein neues Dokument Initialisiert. Dieser Befehl lässt sich nur auf leere Ordner anwenden und legt einige Beispieldateien und Ordner an
welche im weiteren Verlauf beschrieben werden.

**metadata.yaml:** Hier werden die Metadaten wie der Author, Title der Arbeit, Typ der Arbeit und vieles weiter, zum vorliegenden Dokument abgelegt. 
Es ist Sinnvoll die vorliegenden Beispielinformationen vor dem eigentlichen Schreibprozess an zu passen. 

**default.yaml:** In der `default.yaml` befindet sich die Anweisungen zur erstellung des Dokuments. Es ist möglich weitere `default.yaml` Dateien an zu geben um beispielsweise ein pdf und eine tex Datei in 
einem Rutsch zu erzeugen. Weitere Infomationen zur Verwendung dieser Datei finden sich in der [Pandoc Dokumentation](https://pandoc.org/MANUAL.html#defaults-files).

**README.yaml:** In dieser Datei wir das eigentliche Dokument angelegt. Wie ein Dokument in Markdown verfasst wird entnimmst du am besten der Dokumentation (TBD). 

**acronyms.yaml:** Hier kannst du Abkürzungen anlegen, welche du für deine Arbeit benötigst. Die Reihenfolge der Acronyme in der Datei stellt die Reihenfolge im Abkürzungsverzeichnis dar.

**literatur.bib:** Hier finden sich die gesammelten Werke die in der Arbeit zitiert werden. Wir empfehlen für die Verwaltung [Jabref](https://www.jabref.org/)

### Dokument erstellen

Durch die Übergabe der Option `-b` beim Aufruf des Cotnainers wird das Dokument, wie in der `defaults.yaml` Datei beschrieben, erstellt.


