project('hr.from.josipantolis.starfish', 'vala', 'c')

# Include required modules
gnome = import('gnome')
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Common build
dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('gtk+-3.0'),
    dependency('granite'),
    dependency('libhandy-1'),
]

gresource = gnome.compile_resources(
    'gresource',
    join_paths('data', 'gresource.xml'),
    source_dir: 'data'
)

sources = gresource + files(
    'src/UI/Application.vala',
    'src/UI/Window.vala',
    'src/UI/HeaderBar.vala',
    'src/UI/PreferencesDialog.vala',
    'src/UI/ContentStack.vala',
    'src/UI/InputView.vala',
    'src/UI/ResponseView.vala',
    'src/UI/PageErrorView.vala',
    'src/UI/PageImageView.vala',
    'src/UI/PageTextView.vala',
    'src/UI/PageDownloadView.vala',
    'src/UI/LinkEventType.vala',
    'src/UI/LinkEvent.vala',
    'src/Core/Client.vala',
    'src/Core/Uri.vala',
    'src/Core/Mime.vala',
    'src/Core/Response.vala',
    'src/Core/Line.vala',
    'src/Core/LineType.vala',
    'src/Core/TextBody.vala',
    'src/Core/GeminiBody.vala',
    'src/Core/SessionStorage.vala',
    'src/Core/SettingsBackedSessionStorage.vala',
    'src/Core/SessionManager.vala',
    'src/Core/Session.vala',
    'src/Core/Theme.vala'
)

# Test build
test_sources = files(
    'test/TestMain.vala',
    'test/TestBase.vala',
    'test/Core/MimeTest.vala',
    'test/Core/ResponseTest.vala',
    'test/Core/LineTest.vala',
    'test/Core/BodyTestBase.vala',
    'test/Core/TextBodyTest.vala',
    'test/Core/GeminiBodyTest.vala',
    'test/Core/UriTest.vala'
)

test_executeable = executable(
    meson.project_name() + '-tests',
    sources + test_sources,
    dependencies: dependencies
)

test('tests', test_executeable)

# Productin build
executable(
    meson.project_name(),
    sources + files('src/Main.vala'),
    dependencies: dependencies,
    install: true
)

# Install gschema and register gemini MIME type
install_data(
    join_paths('data', 'gschema.xml'),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'),
    rename: meson.project_name () + '.gschema.xml'
)
install_data(
    join_paths('data', 'gemini-mime-type.xml'),
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages'),
    rename: meson.project_name () + '.xml'
)
meson.add_install_script('meson/post_install.py')

# Translate and install our .desktop file
i18n.merge_file(
    input: join_paths('data', 'starfish.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Translate and install our .appdata file
i18n.merge_file(
    input: join_paths('data', 'starfish.appdata.xml.in'),
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Install icons
icon_sizes = ['16', '32', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('data', 'icons', i + '.png'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.png'
    )
    install_data(
        join_paths('data', 'icons', i + '.png'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.png'
    )
endforeach

# Install docs
doc_files = ['index.gmi', 'discover.gmi', 'tools.gmi', 'terminology.gmi']

foreach doc_file : doc_files
    install_data(
        join_paths('data', 'static', doc_file),
        install_dir: join_paths(get_option('datadir'), 'doc', 'starfish')
    )
endforeach

subdir('po')

