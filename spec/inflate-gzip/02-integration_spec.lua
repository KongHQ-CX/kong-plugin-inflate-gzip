local helpers = require "spec.helpers"
local cjson = require "cjson"


local PLUGIN_NAME = "inflate-gzip"


for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

      -- this route-set DOES NOT deflate the response body
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          deflate_response = false,
        },
      }

      -- this route-set DOES deflate the response body
      local route2 = bp.routes:insert({
        hosts = { "test2.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = {
          deflate_response = true,
        },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)


    describe("request", function()
      it("inflates gzip during the plugin execution", function()
        local utils
        local is_36, utils = pcall(require, "kong.tools.gzip")
        if not is_36 then
          utils = require("kong.tools.utils")
        end

        local body = utils.deflate_gzip("Hello World")
        
        local r = client:get("/request", {
          headers = {
            host = "test1.com",
            ["Content-Encoding"] = "gzip",
          },
          body = body,
        })

        -- validate that the request succeeded, response status 200
        local response_body = assert.response(r).has.status(200)
        response_body = cjson.decode(response_body)

        assert.same(response_body.post_data.text, "Hello World")
        assert.response(r).not_has.header("Content-Encoding")
      end)
    end)


    describe("response", function()
      it("re-deflates the response to gzip if enabled", function()
        local utils
        local is_36, utils = pcall(require, "kong.tools.gzip")
        if not is_36 then
          utils = require("kong.tools.utils")
        end

        local body = utils.deflate_gzip("Hello World")
        
        local r = client:get("/request", {
          headers = {
            host = "test2.com",
            ["Content-Encoding"] = "gzip",
          },
          body = body,
        })

        -- validate that the request succeeded, response status 200
        local response_body = assert.response(r).has.status(200)
        response_body = cjson.decode(utils.inflate_gzip(response_body))

        assert.same(response_body.post_data.text, "Hello World")
      end)
    end)

  end)

end end
