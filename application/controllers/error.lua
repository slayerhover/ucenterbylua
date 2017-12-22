local ErrorController = {}

function ErrorController:error()    
    ngx.log(ngx.ERR, json(self.err))
    
    return json(self.err)    
end

return ErrorController
