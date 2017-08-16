class Autoloader
  # All files ever loaded.
  def self.history=(a)
    @@history = a
  end
  def self.history
    @@history
  end
  self.history = Set.new

  def self.loaded=(a)
    @@loaded = a
  end
  def self.loaded
    @@loaded
  end
  self.loaded = Set.new

  def self.loading=(a)
    @@loading = a
  end
  def self.loading
    @@loading
  end
  self.loading = []

  # def runtime_compile_and_run(load_path, ruby_code)
  # Pseudocode
  #   compiler = Opal::Compiler.new(ruby_code)
  #   compiler.compile
  #   @@autoloader_loaded_paths ||= []
  #   @@autoloader_loaded_paths << load_path
  #   Opal.modules[load_path] = compiler.result
  #   Opal.require(load_path)
  # end

  def self.autoload_module!(into, const_name, qualified_name, path_suffix)
    # use this method for loading from server
    puts 'autoloader: loading from server not implemented yet'
    return nil # unless base_path = autoloadable_module?(path_suffix)
    # mod = Module.new
    # into.const_set const_name, mod
    # autoloaded_constants << qualified_name unless autoload_once_paths.include?(base_path)
    # mod
  end

  def self.const_missing(const_name, mod)
    puts "autoloader: const_missing(const_name: #{const_name}, module: #{mod.name})"
    # name.nil? is testing for anonymous
    from_mod = mod.name.nil? ? guess_for_anonymous(const_name) : mod
    puts "autoloader: const_missing: from_mod: #{from_mod}"
    load_missing_constant(from_mod, const_name)
  end

  def self.guess_for_anonymous(const_name)
    if Object.const_defined?(const_name)
      raise NameError.new "#{const_name} cannot be autoloaded from an anonymous class or module", const_name
    else
      Object
    end
  end

  def self.load?
    false # true for reloading/loading instead of require
  end

  def self.load_missing_constant(from_mod, const_name)
    # see active_support/dependencies.rb in case of reloading on how to handle
    puts "autoloader: load_missing_constant(from_mod: #{from_mod}, const_name: #{const_name})"
    qualified_name = qualified_name_for(from_mod, const_name)
    qualified_path = underscore(qualified_name)

    module_path = search_for_module(qualified_path)
    puts "autoloader: load_missing_constant: q_name: #{qualified_name}, q_path: #{qualified_path}, module_path: #{module_path}"
    if module_path
      if loading.include?(module_path)
        raise "Circular dependency detected while autoloading constant #{qualified_name}"
      else
        require_or_load(module_path)
        raise LoadError, "Unable to autoload constant #{qualified_name}, expected #{module_path} to define it" unless from_mod.const_defined?(const_name, false)
        return from_mod.const_get(const_name)
      end
    elsif mod = autoload_module!(from_mod, const_name, qualified_name, qualified_path)
      return mod
    elsif (parent = from_mod.parent) && parent != from_mod &&
          ! from_mod.parents.any? { |p| p.const_defined?(const_name, false) }
      begin
        return parent.const_missing(const_name)
      rescue NameError => e
        raise unless e.missing_name?(qualified_name_for(parent, const_name))
      end
    end
  end

  # Returns the constant path for the provided parent and constant name.
  def self.qualified_name_for(mod, name)
    puts "autoloader: qualified_name_for(mod: #{mod}, name: #{name}"
    mod_name = to_constant_name(mod)
    mod_name == 'Object' ? name.to_s : "#{mod_name}::#{name}"
  end

  def self.require_or_load(module_path, const_path = nil)
    return if loaded.include?(module_path)

    # omit locking for now, introduces twice the code
    #Dependencies.load_interlock do
    #  Maybe it got loaded while we were waiting for our lock:
    #  return if loaded.include?(module_path)

    # Record that we've seen this file *before* loading it to avoid an
    # infinite loop with mutual dependencies.
    loaded << module_path
    loading << module_path

    begin
      if load?
        # use this code path for reloading
      else
        puts "autoloader: require_or_load: require '#{module_path}'"
        result = require module_path
      end
    rescue Exception
      puts "autoloader: require_or_load: loading #{module_path} failed"
      loaded.delete module_path
      raise
    ensure
      loading.pop
    end

    # Record history *after* loading so first load gets warnings.
    history << module_path
    result
    # end
  end

  def self.search_for_module(path)
    puts "autoloader: search_for_module(path: #{path})"
    # just for debugging
    opcheck = `Opal.modules['#{path}']`
    puts "autoloader: search_for_module: Opal internal check: #{opcheck ? true : false}"
    return path if `Opal.modules['#{path}']`
    nil # Gee, I sure wish we had first_match ;-)
  end

  # Convert the provided const desc to a qualified constant name (as a string).
  # A module, class, symbol, or string may be provided.
  def self.to_constant_name(desc) #:nodoc:
    case desc
    when String then desc.sub(/^::/, '')
    when Symbol then desc.to_s
    when Module
      desc.name ||
        raise(ArgumentError, 'Anonymous modules have no name to be referenced by')
    else raise TypeError, "Not a valid constant descriptor: #{desc.inspect}"
    end
  end

  def self.underscore(string)
    string.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end

class Object
  class << self
    alias _autoloader_original_const_missing const_missing

    def const_missing(const_name)
      # need to call original code because some things are set up there
      # original code may also be overloaded by reactrb, for example
      _autoloader_original_const_missing(const_name)
    rescue StandardError => e
      Autoloader.const_missing(const_name, self) || raise(e)
    end
  end
end