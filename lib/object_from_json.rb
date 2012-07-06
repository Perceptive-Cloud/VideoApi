require 'rubygems'
require 'object_from_hash'

module VideoApi

# Takes a JSON string and returns a ruby object tree created by parsing the JSON.
class ObjectFromJson < ObjectFromHash

  def ObjectFromJson.from_json(json)
    ObjectFromHash.from_object(JSON.parse(json))
  end

end

end # VideoApi module
