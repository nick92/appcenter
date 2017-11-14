configure_file (
    input: meson.project_name() + '.service.in',
    output: meson.project_name() + '.service',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    configuration: conf
)

desktop_in = configure_file (
    input: meson.project_name() + '.desktop.in.in',
    output: meson.project_name() + '.desktop.in',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    configuration: conf
)

configure_file (
    input: meson.project_name() + '-daemon.desktop.in',
    output: meson.project_name() + '-daemon.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    configuration: conf
)

appdata_in = configure_file (
    input: meson.project_name() + '.appdata.xml.in.in',
    output: meson.project_name() + '.appdata.xml.in',
    install: false,
    configuration: conf
)

i18n.merge_file (
    'desktop',
    input: desktop_in,
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: appdata_in,
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root (), 'po', 'extra')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)

test (
    'Validate appdata file',
    find_program('appstreamcli'),
    args: ['validate', join_paths(meson.current_build_dir (), meson.project_name() + '.appdata.xml')]
)
