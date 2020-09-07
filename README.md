# OWLGrEd.webapp
OWLGrEd for webAppOS

## Installation

To install OWLGrEd/webAppOS, just clone its git repository into the "apps" subdirectory.

```bash
cd webAppOS/dist/apps
git clone https://github.com/LUMII-Syslab/OWLGrEd.webapp.git
```

Do not forget to restart webAppOS afterwards.

## Sample projects

To try our sample projects, just copy them from the "apps/OWLGrEd.webapp/sample projects" directory
into your user's home directory within webAppOS (e.g., into "home/webappos" for the
default user "webappos").

```bash
cd webAppOS/dist
mkdir -p home/webappos
cp apps/OWLGrEd.webapp/sample\ projects/* home/webappos/
```

Then after launching the OWLGrEd app (e.g., from the webAppOS desktop),
click "Browse" and choose the desired .owlgred project.
