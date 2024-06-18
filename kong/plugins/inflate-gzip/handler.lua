local string_find = string.find


-- resolve version incompatibility between Kong 3.5- and 3.6+
local deflate_gzip, inflate_gzip do
  local ok, utils = pcall(require, "kong.tools.gzip") -- Kong 3.6 and beyond
  if not ok then
    utils = require("kong.tools.utils") -- Kong 3.5 and before
  end

  deflate_gzip = utils.deflate_gzip
  inflate_gzip = utils.inflate_gzip
end


local plugin = {
  PRIORITY = 2000,
  VERSION = "1.0",
}


function plugin:header_filter(conf)
  local c_encoding = kong.request.get_header("Content-Encoding")

  if conf.deflate_response and (not c_encoding or (not string_find(c_encoding, "gzip", 1, true))) then
    kong.log.debug("will deflate response body - clearing headers")
    kong.response.clear_header("Transfer-Encoding")  -- we aren't chunking anymore
    kong.response.set_header("Content-Encoding", "gzip")
  end

  -- check that it isn't already gzip'd
  local c_encoding = kong.request.get_header("Content-Encoding")
  if conf.deflate_response and (not c_encoding or (not string_find(c_encoding, "gzip", 1, true))) then
    kong.log.debug("deflating response")

    local response_body = kong.service.response.get_raw_body()

    if response_body then
      -- stash the body for filter later
      kong.ctx.plugin.compressed_body = deflate_gzip(response_body)
      kong.response.set_header("Content-Length", #kong.ctx.plugin.compressed_body)

      kong.log.debug("plaintext response body deflated and replaced")
    else
      kong.log.debug("request body is empty or nil")
    end
  else
    kong.log.debug("response is empty or nil, cannot deflate")
  end
end


function plugin:body_filter(conf)
  if kong.ctx.plugin.compressed_body then
    kong.response.set_raw_body(kong.ctx.plugin.compressed_body)
  end
end


function plugin:access(conf)
  kong.service.request.enable_buffering()

  local c_encoding = kong.request.get_header("Content-Encoding")

  if c_encoding and string_find(c_encoding, "gzip", 1, true) then
    kong.log.debug("body is gzip'd")

    local request_body = kong.request.get_raw_body()

    if request_body then
      kong.service.request.set_raw_body(inflate_gzip(request_body))
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
