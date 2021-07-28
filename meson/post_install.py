#!/usr/bin/env python3

import os
import subprocess
import sys

project_name = sys.argv[1]
prefix = os.environ['MESON_INSTALL_PREFIX']
schemadir = os.path.join(prefix, 'share', 'glib-2.0', 'schemas')
schema_file = os.path.join(schemadir, project_name + '.gschema.xml')
mimedir = os.path.join(prefix, 'share', 'mime')

def fill_schema_placeholders():
    with open(schema_file, 'rt') as file:
        schema_content = file.read()
    for param in os.environ.keys():
        key = '{{' + param + '}}'
        value = os.environ[param]
        schema_content = schema_content.replace(key, value)
    with open(schema_file, 'wt') as file:
        file.write(schema_content)

if not os.environ.get('DESTDIR'):
    print('Replacing gsettings placeholders in ' + schema_file + '...')
    fill_schema_placeholders()
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir])
    print('Registering text/gemini MIME type...')
    subprocess.call(['update-mime-database', mimedir])
