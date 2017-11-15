categories_in = configure_file (
    input: 'categories.gresource.xml.in',
    output: 'categories.gresource.xml',
    install: false,
    configuration: conf
)

categories_resources = gnome.compile_resources(
    'as-resources-categories', categories_in,
    source_dir: 'data',
    c_name: 'as',
)
