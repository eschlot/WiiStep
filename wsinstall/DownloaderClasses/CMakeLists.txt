cmake_minimum_required(VERSION 2.8)
project(wsinstall)

add_definitions(-fobjc-arc)

add_library(WSInstallDownloaders
SFDownloader.m)
