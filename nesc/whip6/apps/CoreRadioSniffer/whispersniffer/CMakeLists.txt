cmake_minimum_required(VERSION 2.6)
project(whispersniffer)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")

add_subdirectory(../../../../../libiomux "${PROJECT_BINARY_DIR}/libiomux")
include_directories("${PROJECT_SOURCE_DIR}/../../../../../libiomux")

find_package(PCAP REQUIRED)
include_directories(AFTER ${PCAP_INCLUDE_DIRS})

include_directories("${PROJECT_SOURCE_DIR}/..")

add_executable(whispersniffer main.c)
target_link_libraries(whispersniffer ${PCAP_LIBRARIES} iomux)

add_definitions(-DPROJECT_NAME="${PROJECT_NAME}")
