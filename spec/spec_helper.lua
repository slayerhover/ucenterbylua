package.path = package.path .. ";/?.lua;/?/init.lua;/opt/nginx/vanilla/framework/0_1_0_rc7/?.lua;/opt/nginx/vanilla/framework/0_1_0_rc7/?/init.lua;;";
package.cpath = package.cpath .. ";/?.so;/opt/nginx/vanilla/framework/0_1_0_rc7/?.so;;";

Registry={}
Registry['APP_ROOT'] = '/home/webroot/vanilla'
Registry['APP_NAME'] = 'vanilla'

LoadV = function ( ... )
    return require(...)
end

LoadApp = function ( ... )
    return require(Registry['APP_ROOT'] .. '/' .. ...)
end

LoadV 'vanilla.spec.runner'
