project('io.elementary.appcenter', 'vala', 'c',
        version : '0.2.7',
        license : 'GPLv3+',
        default_options: [
                'bindir=/usr/bin',
                'datadir=/usr/share',
                'prefix=/usr',
                'sysconfdir=/etc'
        ],
)

meson.add_install_script('meson/post_install.py')

BLACKLIST = 'appcenter.blacklist'
DESKTOP_FILE = meson.project_name() + '.desktop'
EXEC_NAME = meson.project_name()
GETTEXT_PACKAGE = meson.project_name()

conf = configuration_data()
conf.set('APP_NAME', 'AppCenter')
conf.set('BINDIR', get_option('bindir'))
conf.set('BLACKLIST', BLACKLIST)
conf.set('CONFIGDIR', join_paths(get_option('sysconfdir'), meson.project_name()))
conf.set('DATADIR', get_option('datadir'))
conf.set('DESKTOP_FILE', DESKTOP_FILE)
conf.set('DESKTOP_ICON', 'system-software-install')
conf.set('EXEC_NAME', EXEC_NAME)
conf.set('GETTEXT_PACKAGE', GETTEXT_PACKAGE)
conf.set('PKGDATADIR', join_paths(get_option('datadir'), meson.project_name()))
conf.set('PROJECT_NAME', meson.project_name())
conf.set('RELEASE_NAME', 'Browse and manage apps')
conf.set('URI_ROOT', '/io/elementary/appcenter')
conf.set('VERSION', meson.project_version())
conf.set('VERSION_INFO', 'Alpha')

config_vala = configure_file (
    input: join_paths('config.vala.in'),
    output: join_paths('config.vala'),
    configuration: conf
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="' + GETTEXT_PACKAGE + '"', language:'c')

add_global_arguments('-DI_KNOW_THE_PACKAGEKIT_GLIB2_API_IS_SUBJECT_TO_CHANGE', language:'c')

add_global_arguments('-DCURATED', language:'c')

dependencies = [
    dependency('appstream', version: '>= 0.10'),
    dependency('gee-0.8'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
    dependency('packagekit-glib2'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : true)
]

subdir('data')
subdir('po')
subdir('schemas')
subdir('src')
