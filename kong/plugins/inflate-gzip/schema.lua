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
          { deflate_response = typedefs.header_name {
              required = true,
              description = "If set true, will also deflate (compress) the response from the backend",
              default = false } },
        },
      },
    },
  },
}


return schema
