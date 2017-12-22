local LibMysql = Class("mysql")
local resty_mysql = require("resty.mysql")
local str_util= LoadLibrary('function')
local db_monitor= LoadLibrary('monitor')

local datasource = {
	host = "127.0.0.1",
	port = "3306",
	database = "ucenter",
	user = "ucenter",
	password = "VryuAya9JwVWyBzG",
	timeout = 30000,
	max_idle_timeout = 60000,
	pool_size = 50,
	charset = "utf8"
}

function LibMysql:connect()
	local db, err = resty_mysql:new()
	if not db then
		ngx.log(ngx.ERR, "[Mysql:initConnect] failed to create mysql : ", err)
		return nil
	end
	db:set_timeout(datasource.timeout)
	local ok, err, errno, sqlstate = db:connect(datasource)
	if not ok then
		ngx.log(ngx.ERR, "[Mysql:getConnect] failed to connect mysql : ", err)
		return nil
	end
	-- set charset
	local res, err, errno, sqlstate = db:query("SET NAMES " .. datasource.charset)
	if not res then
		ngx.log(ngx.ERR, "[Mysql:getConnect] set charset fail : ", err)
	end
	-- db_monitor.add("mysql_connect")
	return db
end

function LibMysql:query(sql, nrows)
	local connect = self:connect()
	if not connect then
		ngx.log(ngx.ERR, "[Mysql:query] failed to get mysql connect.")
		return nil, "failed to get mysql connect."
	end
	-- exec sql
	local res, err, errno, sqlstate = connect:query(sql, nrows)
	self:close(connect)
	return res, err, errno, sqlstate
end

function LibMysql:queryTransaction(sqlArray)
	if not _.isArray(sqlArray) then
		ngx.log(ngx.ERR, "[Mysql:queryTransaction] sqlArray must be an array.")
		return nil, "sqlArray must be an array."
	end
	local connect = self:getConnect()
	if not connect then
		ngx.log(ngx.ERR, "[Mysql:query] failed to get mysql connect.")
		return nil, "failed to get mysql connect."
	end
	-- start transaction
	local res_start_transaction, err_start_transaction, errno_start_transaction, sqlstate_start_transaction = connect:query("START TRANSACTION;")
	if _.isEmpty(res_start_transaction) then
		ngx.log(ngx.ERR, "[Mysql:queryTransaction] start transaction error.")
		self:close(connect)
		return nil, "start transaction error."
	end
	-- exec sql
	local result = {}
	for index, sql in ipairs(sqlArray) do
		-- 多条sql以分号结尾
		if not str_util.endWith(sql, ";") then sql = sql .. ";" end
		-- 逐条执行sql
		local res, err, errno, sqlstate = connect:query(sql)
		table.insert(result, { res = res, err = err, errno = errno, sqlstate = sqlstate })
		-- 执行有异常，回滚
		if _.isEmpty(res) then
			local res_rollback, err_rollback, errno_rollback, sqlstate_rollback = connect:query("ROLLBACK;")
			if _.isEmpty(res_rollback) then
				ngx.log(ngx.ERR, "[Mysql:queryTransaction] rollback error.")
			else
				ngx.log(ngx.INFO, "[Mysql:queryTransaction] transaction rollback.")
			end
			self:close(connect)
			return result
		end
	end
	-- commit
	local res_commit, err_commit, errno_commit, sqlstate_commit = connect:query("COMMIT;")
	if _.isEmpty(res_commit) then
		ngx.log(ngx.ERR, "[Mysql:queryTransaction] commit error.")
	end
	self:close(connect)
	return result
end

function LibMysql:close(connect)
	db_monitor.sub("mysql_connect")
	if connect == nil then
		return
	end
	if datasource.pool_size <= 0 then
		connect:close()
		return
	end
	-- put it into the connection pool of size 100,
	-- with 10 seconds max idle timeout
	local ok, err = connect:set_keepalive(datasource.max_idle_timeout,	datasource.pool_size)
	if not ok then
		ngx.log(ngx.ERR, "[Mysql:close] set keepalive failed : ", err)
	else
		ngx.log(ngx.DEBUG, "[Mysql:close] set keepalive ok.")
	end
end

return LibMysql