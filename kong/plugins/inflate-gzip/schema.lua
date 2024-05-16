local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "inflate-gzip"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { deflate_response = {
              type = "boolean",
              required = true,
              default = false } },
        },
      },
    },
  },
}


return schema
