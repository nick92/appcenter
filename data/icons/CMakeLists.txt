file(GLOB CATEGORY_ICONS "${CMAKE_SOURCE_DIR}/data/icons/*.svg")
file(COPY ${CATEGORY_ICONS} DESTINATION ${CMAKE_BINARY_DIR}/data/icons/)

configure_file(${CMAKE_SOURCE_DIR}/data/application.css.in ${CMAKE_BINARY_DIR}/data/application.css)
configure_file(${CMAKE_SOURCE_DIR}/data/icons/categories.gresource.xml.in ${CMAKE_BINARY_DIR}/data/icons/categories.gresource.xml)
configure_file(${CMAKE_SOURCE_DIR}/data/${CMAKE_PROJECT_NAME}.gresource.xml.in ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.gresource.xml)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_CATEGORIES SOURCE categories.gresource.xml)
#glib_compile_resources (GLIB_RESOURCES_CSS SOURCE ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.gresource.xml)
