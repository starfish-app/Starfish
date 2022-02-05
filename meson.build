# Project name, programming language and version
project (
    'hr.from.josipantolis.starfish',
    'c', 'vala',
    version: '1.3.1'
)

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# GNOME module
gnome = import ('gnome')

# Compiling resources
gresource = gnome.compile_resources (
    'gresource',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gobject-2.0'),
    dependency ('gee-0.8'),
    dependency ('gtk+-3.0'),
    dependency ('granite'),
    dependency ('libhandy-1'),
    dependency ('gnutls'),
    dependency ('gtkspell3-3.0'),
    meson.get_compiler ('vala').find_library ('posix')
]

subdir ('src')

# Defining executable
executable (
    meson.project_name (),
    sources,
    gresource,
    dependencies: dependencies,
    install: true
)

subdir ('test')

# Defning tests executable
test('tests', executable (
    meson.project_name () + '-tests',
    common_sources + test_sources,
    dependencies: dependencies
))

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py', meson.project_name ())
