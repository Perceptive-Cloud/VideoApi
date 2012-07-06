
module VideoApi

# Lets you create a ruby object from a hash, turning the hash keys into instance variables with getters and setters.
class ObjectFromHash

  # Adds instance variables with getters and setters to this object, corresponding to the keys and values in the given hash. 
  def initialize(hash)    
    hash.each do |k,v|

      key = clean_key k

      self.instance_variable_set("@#{key}", ObjectFromHash.from_object(v))
      
      # reader
      self.class.send :define_method, key,  proc{
        self.instance_variable_get("@#{key}")
      }

      # writer
      self.class.send :define_method, "#{key}=", proc{|v| 
        self.instance_variable_set("@#{key}", v)
      }
    end
  end  

  # turns a string into a valid ruby property name, turning any non-alphanumeric characters into underscores.
  def clean_key(key)
    key.sub(/[^a-zA-Z0-9_]/, "_")
  end

  # Call with a ruby object if you don't know if it's a hash, Array or primitive value.  Will return a ruby object other than a Hash in response, by converting Hashes into ObjectFromHashes.
  def ObjectFromHash.from_object(object)        
    if object.class.eql?(Array)
      object.map {|x| ObjectFromHash.from_object(x)} 
    elsif object.class.eql?(Hash)
      ObjectFromHash.new(object)
    else
      object
    end
  end
end

end # VideoApi module
