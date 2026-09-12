fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'FT Scripts'
description 'FT Weather & Time Sync System with Admin Dashboard'
version '1.0.0'

ui_page 'web/dist/index.html'

shared_scripts {
    'locales/*.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'web/dist/*'
}
