#!/usr/bin/env python3

from os import path, environ
import subprocess
import sys

project_name = sys.argv[1]
prefix = environ.get('MESON_INSTALL_PREFIX', '/usr/local')
datadir = path.join(prefix, 'share')
schemadir = path.join(datadir, 'glib-2.0', 'schemas')
schema_file = path.join(schemadir, project_name + '.gschema.xml')
desktop_database_dir = path.join(datadir, 'applications')
mimedir = path.join(datadir, 'mime')

def fill_schema_placeholders():
    with open(schema_file, 'rt') as file:
        schema_content = file.read()
    for param in environ.keys():
        key = '{{' + param + '}}'
        value = environ[param]
        schema_content = schema_content.replace(key, value)
    with open(schema_file, 'wt') as file:
        file.write(schema_content)

if not environ.get('DESTDIR'):
    print('Replacing gsettings placeholders in ' + schema_file + '…')
    fill_schema_placeholders()
    print('Compiling gsettings schemas…')
    subprocess.call(['glib-compile-schemas', schemadir])
    print('Updating desktop database…')
    subprocess.call(['update-desktop-database', '-q', desktop_database_dir])
    print('Updating icon cache…')
    subprocess.call(['gtk-update-icon-cache', '-qtf', path.join(datadir, 'icons', 'hicolor')])
    print('Registering text/gemini MIME type…')
    subprocess.call(['update-mime-database', mimedir])
