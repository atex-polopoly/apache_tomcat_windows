def dig(hash, *path)
  path.inject hash do |location, key|
    location.respond_to?(:keys) ? location[key] : nil
  end
end

def get_attr(customer, *path)
  dig = dig(node, customer, *path)
  dig.nil? ? dig(node, 'default', *path) : dig
end
