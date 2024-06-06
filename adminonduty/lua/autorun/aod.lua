if SERVER then 
    include("serve.lua")
else
    include("client_serve.lua")
end