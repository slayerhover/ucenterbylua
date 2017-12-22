local func = LoadLibrary('function')
local mysql= LoadLibrary('mysql')
local redis= LoadLibrary('redis')
local cache= redis:new();
local UserModel = {}

function UserModel:checksign(data, sign)
	local data= func.sort(data)
    do return func.verify(func.implode('', data), sign) end
end

function UserModel.get(phone)
	local fields="uid,phone,email,salt,password,token,userstatus,type,up,cityid,idcard,gender,avatar,lockuntil,lastlogintime,lastloginip,created,updated,is_delete";
	local sql = string.format([[select %s from uc_user where phone=%s limit 1]], fields, ndk.set_var.set_quote_sql_str(phone))
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return false;
	end
	return res[1];
end

function UserModel.checkphoneExists(phone)	
	local sql = string.format([[select count(*) as counter from uc_user where phone=%s]], ndk.set_var.set_quote_sql_str(phone))
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res or tonumber(res[1].counter)<1 then
		return false;
	end
	return true;
end

function UserModel.getUserByToken(token)
	local fields="uid,phone,email,token,userstatus,type,up,cityid,idcard,gender,avatar,lockuntil,lastlogintime,lastloginip,created,updated,is_delete";
	local sql = string.format([[select %s from uc_user where token=%s limit 1]], fields, ndk.set_var.set_quote_sql_str(token))
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return false;
	end
	return res[1];
end

function UserModel.sendNotice(data)	
	local sql = string.format([[insert into uc_notice set uid=%s,content=%s,created=%d]], ndk.set_var.set_quote_sql_str(data.uid), ndk.set_var.set_quote_sql_str(data.content), ngx.time())
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return false;
	end
	return true;
end

function UserModel.getNoticeAll(uid, page, pagesize)
	if func.empty(page) then
		page = 1;
	end
	if func.empty(pagesize) then
		pagesize = 10;
	end
	local startnum = (page-1)*pagesize;
	local sql = string.format([[select * from uc_notice where uid=%s limit %d,%d]], ndk.set_var.set_quote_sql_str(uid), startnum, pagesize)
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return false;
	end
	return res;
end

function UserModel.getNotice(nid)
	local sql = string.format([[select * from uc_notice where nid=%s limit 1]], ndk.set_var.set_quote_sql_str(nid))
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return false;
	end
	return res[1];
end

function UserModel.checktokenValid(token)
	if func.empty(token) then
		return false
	end
	local rows= func.json_decode(cache:get(token));
    if not rows then
		rows = UserModel.getUserByToken(token)
		if not rows then
			return false
		end
		cache:setex(token, Registry['APP_CONF'].cacheexpire, json(rows));	
	end	
	return rows
end

function UserModel.checklogin(user, password)
	if ngx.md5(password..user.salt)~=user.password then
		local failedTimes, err= cache:incr(user.phone)
		local failedTimeslast = 20*60;
		cache:expire(user.phone, failedTimeslast)
		if failedTimes>=5 then
			local locktime = ngx.time()+failedTimeslast;
			local sql = string.format([[update uc_user set lockuntil=%d where phone=%s limit 1]], locktime, ndk.set_var.set_quote_sql_str(user.phone))		
			local res, err, errno, sqlstate = mysql:query(sql)
		end
		return {ret=200, msg="密码错误", data={phone=user.phone,failedTimes=failedTimes}};
	end
	if cache:exists(user.phone) then
		cache:del(user.phone)
	end
	
	local token= user.token;
	if func.empty(token) then
		token	= 'auth_' .. ngx.md5(user.phone..ngx.time()..func.getIp()..user.salt);		
	end
	local sql = string.format([[update uc_user set token=%s,lastlogintime=%d,lastloginip=%s,updated=%d where phone=%s limit 1]], token, ngx.time(), func.getIp(), ngx.time(), ndk.set_var.set_quote_sql_str(user.phone))
	local res, err, errno, sqlstate = mysql:query(sql)
		
	user = func.unset(user, 'salt');
	user = func.unset(user, 'password');
	cache:setex(token, Registry['APP_CONF'].cacheexpire, json(user));
	return {ret=0, msg="登陆成功", data=user};
end

function UserModel.register(user)
	local token	= 'auth_' .. ngx.md5(func.implode('',user));	
	local password = ngx.md5(user.password .. user.salt);
	local sql = string.format([[insert into uc_user set phone=%s,password=%s,salt=%s,token=%s,lastlogintime=%d,lastloginip=%s,created=%d]], ndk.set_var.set_quote_sql_str(user.phone), ndk.set_var.set_quote_sql_str(password), ndk.set_var.set_quote_sql_str(user.salt), ndk.set_var.set_quote_sql_str(token), user.regtime, ndk.set_var.set_quote_sql_str(user.ip), user.regtime)	
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return {ret=100, msg="注册用户失败", data={phone=user.phone,password=user.password}};
	end	
	local rows = UserModel.get(user.phone)
	rows = func.unset(rows, 'salt');
	rows = func.unset(rows, 'password');
	cache:setex(token, Registry['APP_CONF'].cacheexpire, json(rows));
	return {ret=0, msg="注册成功", data=rows};
end

function UserModel.resetpwd(data)	
	local sql = string.format([[update uc_user set password=%s where phone=%s limit 1]], ndk.set_var.set_quote_sql_str(data.newpassword), ndk.set_var.set_quote_sql_str(data.phone))	
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return {ret=200, msg="更新密码失败"};
	end		
	return {ret=0, msg="更新密码成功"};
end

function UserModel.updateinfo(data, condition)
	if func.empty(data) then
		return {ret=100, msg="更新数据为空"};
	end	
	local sql = [[update uc_user set ]]
	for k, v in pairs(data) do
		sql	=	sql .. string.format(k..[[=%s,]], ndk.set_var.set_quote_sql_str(v))
	end
	sql = func.substr(sql, 1, -2)
	sql = sql..[[ where ]]..condition..[[ limit 1 ]]
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return {ret=200, msg="更新用户信息失败"};
	end		
	return {ret=0, msg="更新用户信息成功", data=data};
end

function UserModel.uploadlogo(data, condition)
	if func.empty(data.avatar) then
		return {ret=100, msg="图片数据为空"};
	end		
	local imgcode = func.preg_match([[(data\:image\/(\w+);base64,)]], data.avatar)
	local filetype = ""
	if imgcode[2]=="jpeg" then
		filetype = ".jpg"
	else
		filetype = "."..imgcode[2]
	end	
	local today  = ngx.today();
	local filepath= Registry['APP_CONF'].uploads..today;
	if not func.file_exists(filepath) then
		os.execute("mkdir -p "..filepath) 
	end	
	local filename=func.randstr(12)..filetype;
	local newfile= filepath..'/'..filename;
	local webpath= '/public/uploads/'..today..'/'..filename
	local file = io.open(newfile, "w+")	
	io.output(file)	
	io.write(func.base64_decode(func.str_replace(' ', '+', func.str_replace(imgcode[0], '', data.avatar))))
	io.close(file)	
	local sql = string.format([[update uc_user set avatar=%s where %s limit 1]], ndk.set_var.set_quote_sql_str(webpath), condition)	
	local res, err, errno, sqlstate = mysql:query(sql)
	if not res then
		return {ret=200, msg="更新用户头像信息失败"};
	end		
	return {ret=0, msg="更新用户头像信息成功", data={avatar=webpath}};
end

function UserModel.flushcache(token)
	rows = UserModel.getUserByToken(token)
	if not rows then
		return false
	end
	cache:setex(token, Registry['APP_CONF'].cacheexpire, json(rows));
end

return UserModel
