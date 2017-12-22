local IndexController = Class('controllers.index', LoadApplication('controllers.base'))
local func = LoadLibrary('function')
local mysql= LoadLibrary('mysql')
local redis= LoadLibrary('redis')
local cache= redis:new();
local user = LoadModel('userModel')	

function IndexController:__construct()
	self.parent:__construct()
	cache:select(2);
end

function IndexController:index()  
	local result = {ret=0, msg="welcome to great user center!", data="ver 1.0"}
    return json(result);
end

function IndexController:userinfo()	
	local result={};
	repeat
		local token = self.get.token
		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end		
		result= {ret=0, msg="获取用户信息", data=rows}
	until(true)
	return json(result);
end

function IndexController:login()
	local result={};
	repeat
		if func.empty(self.get.phone) or func.empty(self.get.password) then
			result = {ret=100, msg="phone或password 为空"}
			break;
		end		
		local rows = user.get(self.get.phone)		
		if not rows then
			result = {ret=200, msg="未找到此用户", data={phone=self.get.phone,err=err}}
			break;
		end
		if rows.lockuntil>ngx.time() then
			result = {ret=300, msg="用户当前处于锁定状态", data={lockuntil=os.date("%Y-%m-%d %H:%M:%S", rows.lockuntil)}}
			break;
		end
		if rows.userstatus==0 then
			result = {ret=400, msg="用户已被冻结"}
			break;
		end		
		result = user.checklogin(rows, self.get.password)
    until(true)	
	return json(result)
end

function IndexController:register()	
    local result={};
	repeat
		if func.empty(self.get.phone) or func.empty(self.get.password) then
			result = {ret=100, msg="phone或password 为空"}
			break;
		end
		if self.get.password~=self.get.repassword then
			result = {ret=200, msg="重复密码不一致"}
			break;
		end
		if user.checkphoneExists(self.get.phone) then
			result = {ret=300, msg="手机号码已存在"}
			break;
		end			
		local rows = {phone=self.get.phone,password=self.get.repassword,regtime=ngx.time(),ip=func.getIp(),salt=func.randstr(16)}
		result = user.register(rows)
    until(true)	
	return json(result)
end

function IndexController:resetpwd()	
    local result={};
	repeat
		local token = self.get.token
		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end
		if func.empty(self.get.oldpassword) or func.empty(self.get.newpassword) then
			result= {ret=300, msg="新旧password 为空"}
			break;
		end
		if self.get.newpassword~=self.get.repassword then
			result= {ret=400, msg="重复密码不一致"}
			break;
		end		
		rows = user.get(rows.phone);
		local oldpassword = ngx.md5(self.get.oldpassword .. rows.salt);
		if rows.password~=oldpassword then
			result= {ret=500, msg="旧密码不正确"}
			break;
		end
		local newpassword = ngx.md5(self.get.newpassword .. rows.salt);
		local rows = {phone=rows.phone,newpassword=newpassword}
		result = user.resetpwd(rows)
    until(true)	
	return json(result)
end

function IndexController:updateinfo()	
    local result={};
	repeat
		local token = self.get.token
		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end		
		local data= {realname=self.get.realname,gender=self.get.gender,email=self.get.email,cityid=self.get.cityid,idcard=self.get.idcard}
		result = user.updateinfo(data, "uid="..rows['uid'])
		user.flushcache(self.get.token);
	until(true)
	return json(result);
end

function IndexController:uploadlogo()	
    local result={};
	repeat
		local token = self.get.token
		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end		
		local data= {avatar=self.get.avatar}
		result = user.uploadlogo(data, "uid="..rows['uid'])
		user.flushcache(self.get.token);
	until(true)
	return json(result);
end

function IndexController:checktoken()	
    local result={};
	repeat
		local token = self.get.token
		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end		
		result= {ret=0, msg="token有效"}
	until(true)
	return json(result);
end

function IndexController:sendnotice()	
    local result={};
	repeat
		local token = self.get.token		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end
		if func.empty(self.get.content) then
			result= {ret=300, msg="发送信息为空"}
			break;
		end
		local data= {uid=rows['uid'],content=self.get.content}
		if user.sendNotice(data)==true then
			result= {ret=0, msg="发送信息成功"} 
		else
			result= {ret=400, msg="发送信息失败"} 
		end
	until(true)
	return json(result);
end

function IndexController:getnotice()	
    local result={};
	repeat
		local token = self.get.token		
		local rows= user.checktokenValid(token)
		if not rows then
			result= {ret=200, msg="token无效"}
			break;
		end
		local data={};
		if func.empty(self.get.nid) then
			data= user.getNoticeAll(rows.uid)
		else
			data= user.getNotice(self.get.nid)
		end		
		result= {ret=0, msg="获取信息成功", data=data} 		
	until(true)
	return json(result);
end

function IndexController:getcity()
	local result={};
	repeat
		if not func.empty(self.get.up) then
			up = self.get.up
		else
			up = 0
		end		
		local fields= "cid,name,up";
		local sql = string.format([[select %s from uc_city where up=%s]], fields, ndk.set_var.set_quote_sql_str(up))
		local res, err, errno, sqlstate = mysql:query(sql)		
		if not res then
			result= {ret=100, msg="无数据被找到"}
			break;
		end		
		result	=	{ret=0, msg="城市列表", data=res}		
	until(true)	
	return json(result);
end

return IndexController
