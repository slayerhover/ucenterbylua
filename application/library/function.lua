local LibFunction = Class("function")
local cjson	= require "cjson"
local http	= require "resty.http"
local codec = require "codec"

function LibFunction.empty(t)
	if type(t) == 'table' and _G.next(t) == nil then
		return true
	elseif t == nil or t == "" or t == 0 or t == false then
        return true	
    else
        return false
    end
end

function LibFunction.dump(t)	
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

-- 删除table中的元素
function LibFunction.unset(tbl, key)  
    local tmp ={}   
    for i in pairs(tbl) do  
        table.insert(tmp,i)  
    end  
  
    local newTbl = {}  
    local i = 1  
    while i <= #tmp do  
        local val = tmp [i]  
        if val == key then  
            table.remove(tmp,i)  
         else  
            newTbl[val] = tbl[val]  
            i = i + 1  
         end  
    end  
    return newTbl  
end  

function LibFunction.sort(tab)
	local key_tmp ={}
	for i in pairs(tab) do
	   table.insert(key_test,i)   --提取test1中的键值插入到key_test表中
	end

	table.sort(key_tmp)
	return key_tmp
end

function LibFunction.getIp()
    local headers=ngx.req.get_headers()
    local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
    return ip
end

function LibFunction.curl(url, params, method)
	local httpc	=	http.new()
	httpc:set_timeout(2000) --2秒超时
	local resp, err = httpc:request_uri(url, {  
		method	= method or 'GET',
		body 	= params,
		ssl_verify = false, --兼容https
		headers = {  
			["User-Agent"]  = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36",
			["Content-Type"]= "application/x-www-form-urlencoded"
			
		}  
	})
	if not resp then  		
		return false
	end  
	  	
	httpc:close()
	return resp.body
end

function LibFunction.sizeof(t)
	local count = 0
	for _, v in pairs(t) do
		count = count + 1
	end			
	return count;
end
function LibFunction.count(t)
	local count = 0
	for _, v in pairs(t) do
		count = count + 1
	end			
	return count;
end

function LibFunction.json_encode(t)
	cjson.encode_empty_table_as_object(true)
	local str = cjson.encode(t)
	return str
end

function LibFunction.json_decode(str)
	local json = false
	pcall(function(str) json = cjson.decode(str) end, str)
	return json
end

function LibFunction.explode(split, str)
	local str_split_tab = {}
	while true do
		local idx = string.find(str,split,1,true);
		if nil~=idx then
			local insert_str = '';
			if 1==idx then
				insert_str = string.sub(str, 1,idx + #split - 1);
			else
				insert_str = string.sub(str, 1,idx - 1);
			end

			if (insert_str ~= split) and (nil ~= insert_str or '' ~= insert_str) then
				table.insert(str_split_tab,insert_str);
			end
			str = string.sub(str,idx + #split,-1);
		else
			if nil ~= str or '' ~= str then
				table.insert(str_split_tab,str);
			end
			break;
		end
	end
	return str_split_tab;
end

function LibFunction.implode(split, t)
	local tab = {}
	for _, v in pairs(t) do
		table.insert(tab, v)
	end			
	return table.concat(tab, split);
end

function LibFunction.str_replace(find, replace, str)
	local res,res_count = string.gsub(str,find,replace);
	return res,res_count
end

function LibFunction.substr(str, from, to)
	return string.sub(str, from, to)
end

function LibFunction.time()
	return ngx.time()
end

function LibFunction.rand(from, to)
	math.randomseed(os.clock()*math.random(1000000,90000000)+math.random(1000000,9000000))
	return math.random(from, to)
end

--随机字符串mode 0：大小字母数字 1：大字母 2：小字母 3：数字
function LibFunction.randstr(length, mode)
	if not length or length<1 then return '' end
	local bc ="ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	local sc ="abcdefghijklmnopqrstuvwxyz";
	local no ="0123456789";
	local template = "";
	local maxlen = 0;
	if mode==nil then
		template = bc..sc..no;
		maxlen	 = 62;
	elseif mode==1 then
		template = bc;
		maxlen	 = 26;
	elseif mode==2 then
		template = sc;
		maxlen	 = 26;
	elseif mode==3 then
		template = no;
		maxlen	 = 10;
	else
		template = bc..sc..no;
		maxlen	 = 62;
	end	
	local result = {}			
    for i=1,length do
		local index= LibFunction.rand(1, maxlen)
		result[i]= string.sub(template, index, index)
    end
	return table.concat(result, '');
end

function LibFunction.strpos(str, find)
	local res,res_end = string.find(str, find)
	if ''==res or nil==res then
		return false;
	end	
	return res;
end

function LibFunction.stripos(str, find)
	local str = string.lower(str);
	local find= string.lower(find);
	
	local res,res_end = string.find(str, find)
	if ''==res or nil==res then
		return false;
	end	
	return res;
end

function LibFunction.preg_match(regex, str)
	local res,err = ngx.re.match(str, regex, "io")
	if res then
		return res;
	else
		ngx.log(ngx.ERR, "error: "..err)
		return false;
	end
end

function LibFunction.preg_match_all(regex, str)
	local it,err = ngx.re.gmatch(str, regex, "io")
    if not it then
        ngx.log(ngx.ERR, "error: ", err)
        return false;
    end
	local res = {};	
    while true do
        local m, err = it()
        if err then
            ngx.log(ngx.ERR, "error: ", err)
            return false;
        end 
        if not m then
            break
        end
		table.insert(res, m);
    end			
	return res;
end

function LibFunction.preg_replace(regex, replacement, str, option)
	local newstr, n, err = ngx.re.gsub(str, regex, replacement, option)
    if newstr then
		return newstr;		
        -- newstr == "[hello,h], [world,w]"
        -- n == 2
    else
        ngx.log(ngx.ERR, "error: ", err)
        return false;
    end
end

function LibFunction.trim(str)
	str = LibFunction:ltrim( str );
	str = LibFunction:rtrim( str );
	return str;
end

function LibFunction.ltrim( str )
	if ''==str or nil==str then
		return str;
	end
	local len = string.len( str );
	
	local substart = 1;
	local  lenadd = 1;
	while ( string.find ( str," ",lenadd) == lenadd ) do
		substart = substart + 1;
		lenadd= lenadd + 1;
	end
	
	str=string.sub ( str ,substart ,len);
	
	local substart1 = 1;
	local lenadd1 = 1;
	len=string.len(str);
	while(string.find(str,"%s",lenadd1 )==lenadd1) do
        		substart1 = substart1 +1
        		lenadd1 = lenadd1 +1
	end
	
	str=string.sub(str,substart1,len);
	
	return str;
end

function LibFunction.rtrim( str )
	if ''==str or nil==str then
		return str;
	end
	local len = string.len(str);
	
	local substart = len;
	local  lenadd = len;
	while ( string.find ( str,"%s",lenadd) == lenadd ) do
		substart = substart - 1;
		lenadd= lenadd - 1;
	end
	str =string.sub(str , 1,substart );
	len=string.len(str);

	local substart1 = len;
	local lenadd1 = len;
	while(string.find(str," ",lenadd1 )==lenadd1) do
        		substart1 = substart1 -1
        		lenadd1 = lenadd1 -1
	end
	
	str=string.sub(str,1,substart);

	return str;

end

function LibFunction.upper(str)
	if ''==str or nil==str then
		return str;
	end
	return string.upper(str);
end

function LibFunction.lower(str)
	if ''==str or nil==str then
		return str;
	end
	return string.lower(str);
end

function LibFunction.startWith(str, substr)
    if str == nil or substr == nil then
        return false
    end
    if string.find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

function LibFunction.endWith(str, substr)
    if str == nil or substr == nil then
        return false
    end
    local str_tmp, substr_tmp = string.reverse(str), string.reverse(substr)
    if string.find(str_tmp, substr_tmp) ~= 1 then
        return false
    else
        return true
    end
end

function LibFunction.base64_encode(str)
    return ngx.encode_base64(str)
end

-- decode base64  
function LibFunction.base64_decode(str)
    return ngx.decode_base64(str)
end

-- md5 
function LibFunction.md5(str)
    return ngx.md5(str)
end

function LibFunction.sign(str)
	local privpem = [[-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCsxjKD2lnmkmELoo5QphM/VdREJKym26R0T+19JDa3MVZFDbwg
UGT8XM8bElrKgxexhTVRt07btyIejdbiPx7sCbWcVP8peZI+QZEVVzaE2Ci5n0lP
9v9GUSl0QfZU94uIwl++BVq0VFvbHax/R/q4oTRD1u73ASM27QW42+cJFwIDAQAB
AoGALHoNMQI52HBgSSV8q2hFVi2bKjuisoWibUrSIT/8UeaChd5GSq9Hf+vIaPit
pKpgpBNdqX6d71PSlbj/01hadg5IxrGWQZWzT/3IzuhTxAu4TkztUJelGRcM6ykZ
5AxijiIxTLWSY/ygtEaM2QShhl8dCReNT+oIDGf/iMSTVykCQQDl07WZR9ATReVc
vM7/v9iiz/g1Tj9/8AOuyYOZ5kp5a8IAr48dXixzuTZY66RwPj/J5vrzLuHc7Uc0
RAi4hgmTAkEAwHMxP0KVOzDH49SsiUjfOycqrBl68QCXUWQj2mi7Bb1pLryoYDFv
FTuk6pxKyfr5O8M2s8thTz6f3EO7hFqk7QJAdX8Ly2ZkYUYNoaDBbwzEk1AhhBcR
7bVmHJjXV/ndP0Aw+arHTutTbIJW35TxB5U7hVw6FdN1Ez6XdYgGsVeNUwJAEjlW
SoVFmGtQInT7Oaza5sEYu19WUwgZTC3Nb1tHio2bLj/TOfi0ajBRt53BP0sy2sPr
pC74MgbeIH+RfEERKQJBAIpPkQztkbpZwD9gDiK86U+HHYZrhglxgfDIXYwTH3z/
KCrfyNxiH2im9ZhwuhLs7LDD7wDPHUC5BItx2tYN10s=
-----END RSA PRIVATE KEY-----]]
	local bs = codec.rsa_private_sign(str, privpem)
	local sign = codec.base64_encode(bs)
	return sign;
end

function LibFunction.verify(str, sign)
	local pubpem = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCsxjKD2lnmkmELoo5QphM/VdRE
JKym26R0T+19JDa3MVZFDbwgUGT8XM8bElrKgxexhTVRt07btyIejdbiPx7sCbWc
VP8peZI+QZEVVzaE2Ci5n0lP9v9GUSl0QfZU94uIwl++BVq0VFvbHax/R/q4oTRD
1u73ASM27QW42+cJFwIDAQAB
-----END PUBLIC KEY-----]]
	local dbs = codec.base64_decode(sign)
	local typ = 2	
	local ok = codec.rsa_public_verify(str, dbs, pubpem, typ)
	return ok;
end

function LibFunction.encrypt(str)
	local pubpem = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCsxjKD2lnmkmELoo5QphM/VdRE
JKym26R0T+19JDa3MVZFDbwgUGT8XM8bElrKgxexhTVRt07btyIejdbiPx7sCbWc
VP8peZI+QZEVVzaE2Ci5n0lP9v9GUSl0QfZU94uIwl++BVq0VFvbHax/R/q4oTRD
1u73ASM27QW42+cJFwIDAQAB
-----END PUBLIC KEY-----]]
	local typ = 2
	local bs = codec.rsa_public_encrypt(str, pubpem, typ)
	local dst = codec.base64_encode(bs)
	return dst;
end

function LibFunction.decrypt(str)
	local privpem = [[-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCsxjKD2lnmkmELoo5QphM/VdREJKym26R0T+19JDa3MVZFDbwg
UGT8XM8bElrKgxexhTVRt07btyIejdbiPx7sCbWcVP8peZI+QZEVVzaE2Ci5n0lP
9v9GUSl0QfZU94uIwl++BVq0VFvbHax/R/q4oTRD1u73ASM27QW42+cJFwIDAQAB
AoGALHoNMQI52HBgSSV8q2hFVi2bKjuisoWibUrSIT/8UeaChd5GSq9Hf+vIaPit
pKpgpBNdqX6d71PSlbj/01hadg5IxrGWQZWzT/3IzuhTxAu4TkztUJelGRcM6ykZ
5AxijiIxTLWSY/ygtEaM2QShhl8dCReNT+oIDGf/iMSTVykCQQDl07WZR9ATReVc
vM7/v9iiz/g1Tj9/8AOuyYOZ5kp5a8IAr48dXixzuTZY66RwPj/J5vrzLuHc7Uc0
RAi4hgmTAkEAwHMxP0KVOzDH49SsiUjfOycqrBl68QCXUWQj2mi7Bb1pLryoYDFv
FTuk6pxKyfr5O8M2s8thTz6f3EO7hFqk7QJAdX8Ly2ZkYUYNoaDBbwzEk1AhhBcR
7bVmHJjXV/ndP0Aw+arHTutTbIJW35TxB5U7hVw6FdN1Ez6XdYgGsVeNUwJAEjlW
SoVFmGtQInT7Oaza5sEYu19WUwgZTC3Nb1tHio2bLj/TOfi0ajBRt53BP0sy2sPr
pC74MgbeIH+RfEERKQJBAIpPkQztkbpZwD9gDiK86U+HHYZrhglxgfDIXYwTH3z/
KCrfyNxiH2im9ZhwuhLs7LDD7wDPHUC5BItx2tYN10s=
-----END RSA PRIVATE KEY-----]]
	local dbs = codec.base64_decode(str)
	local dsrc = codec.rsa_private_decrypt(dbs, privpem)
	return dsrc;
end

function LibFunction.file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

--[[
 输出图片
--]]
function LibFunction.image(imgPath)
    local file = io.open(imgPath, "rb")
    local file_content = file:read("*a")
    file:close()
    --[[
        application/octet-stream 二进制流，不知道下载文件类型
    --]]
    response:set_header("Content-Type","image/jpeg")
    response:set_header("Cache-Control","no-store, no-cache, must-revalidate")
    response:set_header("Pragma","no-cache")
    response:write(file_content)
end


return LibFunction
