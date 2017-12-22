init_vanilla()
--+--------------------------------------------------------------------------------+--


-- if Registry['VA_ENV'] == nil then
	function dump(t)	
		local function parse_array(tab)
			local str = ''
			for _, v in pairs(tab) do
				str	=	str .. '\t\t' .. _ .. ' => ' .. tostring(v) .. '\n'
			end			
			return str
		end
		
		local str = type(t);		
		if str=='table' then		
			str = str .. '(' .. #t .. ')' .. '\n{\n' 
			for k,v in pairs(t) do
				if type(v)=="table" then
					str = str .. '\t' .. k .. ' = > {\n' .. parse_array(v) .. '\t}' .. '\n'
				else
					str = str .. '\t' .. k .. ' => ' .. (v) ..  '\n'
				end
			end
		else
			str = str .. '\n{\n' .. tostring(t) .. '\n'
		end		
		str = str .. '}'
		
		ngx.say('\n' .. str .. '\n')
	end
	
	function html(t)
		ngx.header.content_type = "text/html"
		ngx.header.content_type = "application/json;charset=utf8"
		return t
	end
	
	function json(t)
		ngx.header.content_type = "text/html"
		ngx.header.content_type = "application/json;charset=utf8"
		local cjson = require('cjson')
		cjson.encode_empty_table_as_object(true)
		local str = cjson.encode(t)
		return str
	end

    function err_log(msg)
        ngx.log(ngx.ERR, "===zjdebug" .. msg .. "===")
    end
-- end
--+--------------------------------------------------------------------------------+--


Registry['VANILLA_APPLICATION']:new(ngx, Registry['APP_CONF']):bootstrap(Registry['APP_BOOTS']):run()
