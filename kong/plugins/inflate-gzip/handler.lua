local string_find = string.find

local plugin = {
  PRIORITY = 2000,
  VERSION = "1.0",
}

function plugin:header_filter(conf)
  local c_encoding = kong.request.get_header("Content-Encoding")

  if conf.deflate_response and (not c_encoding or (not string_find(c_encoding, "gzip"))) then
    kong.log.debug("will deflate response body - clearing headers")

    kong.response.set_header("Content-Encoding", "gzip")
    kong.response.clear_header("Content-Length")  -- chunk it instead
  end
end


function plugin:body_filter(conf)
  -- check that it isn't already gzip'd
  local c_encoding = kong.request.get_header("Content-Encoding")
  if conf.deflate_response and (not c_encoding or (not string_find(c_encoding, "gzip"))) then
    kong.log.debug("deflating response")

    local is_36, utils = pcall(require, "kong.tools.gzip")
    if not is_36 then
      kong.log.debug("Kong <=3.5 detected, kong.tools.utils is loaded instead")
      utils = require("kong.tools.utils")
    end

    local response_body = kong.response.get_raw_body()

    if response_body then
      kong.response.set_raw_body(utils.deflate_gzip(response_body))

      kong.log.debug("plaintext response body deflated and replaced")
    else
      kong.log.debug("request body is empty or nil")
    end
  else
    kong.log.debug("response is empty or nil, cannot deflate")
  end
end


function plugin:access(conf)
  local c_encoding = kong.request.get_header("Content-Encoding")

  if c_encoding and string_find(c_encoding, "gzip") then
    kong.log.debug("body is gzip'd")

    local is_36, utils = pcall(require, "kong.tools.gzip")
    if not is_36 then
      kong.log.debug("Kong <=3.5 detected, kong.tools.utils is loaded instead")
      utils = require("kong.tools.utils")
    end

    local request_body = kong.request.get_raw_body()

    if request_body then
      kong.service.request.set_raw_body(utils.inflate_gzip(request_body))
      kong.service.request.clear_header("Content-Encoding")

      kong.log.debug("gzip'd request body inflated and replaced")
    else
      kong.log.debug("request body is empty or nil")
    end
  else
    kong.log.debug("request has no Content-Encoding so I can't tell if it's gzip'd")
  end
end


return plugin
