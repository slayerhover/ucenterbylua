local APP_ROOT = Registry['APP_ROOT']
local Appconf={}
Appconf.sysconf = {
    'v_resource',
    'cache'
}
Appconf.page_cache = {}
Appconf.page_cache.cache_on = false
-- Appconf.page_cache.cache_handle = 'lru'
Appconf.page_cache.no_cache_cookie = 'va-no-cache'
Appconf.page_cache.no_cache_uris = {
    'uris'
}
Appconf.page_cache.build_cache_key_without_args = {'rd'}
Appconf.vanilla_root = '/opt/nginx/vanilla/framework'
Appconf.vanilla_version = '0_1_0_rc7'
Appconf.name = 'vanilla'

Appconf.route='vanilla.v.routes.restful'
Appconf.bootstrap='application.bootstrap'

Appconf.cacheexpire=86400

Appconf.app={}
Appconf.app.root=APP_ROOT

Appconf.controller={}
Appconf.controller.path=Appconf.app.root .. '/application/controllers/'

Appconf.uploads=Appconf.app.root .. '/public/uploads/'

Appconf.view={}
Appconf.view.path=Appconf.app.root .. '/application/views/'
Appconf.view.suffix='.html'
Appconf.view.auto_render=false

return Appconf
