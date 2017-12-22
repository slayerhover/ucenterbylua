local BaseController = Class('controllers.base')

function BaseController:__construct()
    self.get = self:getRequest():getParams();	
end

return BaseController