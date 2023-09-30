name "legends_tax"
author "LEGENDS - CODE101"
description "Legends Companies tax"

fx_version "adamant"

games {"rdr3"}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

server_scripts {
    'config.lua',
    'server.lua'
}

version '0.0.1s'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'