# 1) OK - entiendo que estas agregando metodos. Puedo hacer algo cuando lo agregas
# 2) cambiar el metodo que agregas para que se ejecute lo que yo quiero. Ej. agregas mensaje_1 y yo lo piso con otro mensaje_1
# 3) defino un nuevo metodo que haga:
#     * llamo a todos los before
#     * ejecuto lo que vos querias
#     * llamo a todos los after
#
class BooleanException < StandardError
end

class ConditionError < StandardError
end

class ContractMethod
  attr_accessor :method_name

  def initialize(method, method_name)
    @method = method
    @method_name = method_name
  end

  def exec_on(instance, args, block)
    @method.bind(instance).call(*args,&block)
  end
end

class MethodParameters
  def initialize(instance, list_args, list_val)
    @instance = instance

    list_args.each_with_index do |arg, i|
      unless arg.nil?
        self.class.define_method(arg) {list_val[i]}
      end
    end
  end

  def execBlock(bloque, *ret)

    if bloque.parameters.size == 0
      result = instance_eval(&bloque)
    else
      result = instance_exec ret[0], &bloque
    end
    return result
  end

  def method_missing(method, *args)
    @instance.send(method, *args)
    #super
  end

  def respond_to_missing?(method)
    @instance.respond_to?(method)
  end
end


class Module
  attr_accessor :after_blocks, :before_blocks

  private def before_and_after_each_call(bloque_before, bloque_after)
    @before_blocks ||= []
    @after_blocks ||= []
    @before_blocks << bloque_before
    @after_blocks << bloque_after
  end

  def proc_with_block_condition(bloque, error_message = "Condition is not verified")
    proc do |list_args, list_val, *ret|

      method_parameters = MethodParameters.new(self, list_args, list_val)

      result = method_parameters.execBlock(bloque, *ret)

      raise BooleanException.new "The result isn't boolean" unless result.is_a? TrueClass or result.is_a? FalseClass
      raise ConditionError.new error_message unless result
    end
  end

  def proc_with_typed_condition(dicTypes, retType, error_message = "Condition is not verified")
    proc do | list_args, list_val, *ret|

      result = true

      dicTypes.each do |key, value|
        index_val = list_args.index(key)
        if list_val[index_val].class != value
          result = false
        end
      end

      unless ret.nil?
        result = false if ret[0].class != retType
      end

      raise ConditionError.new error_message unless result
    end
  end

  def proc_for_invariant(bloque, error_message = "Condition is not verified")
    proc do
      result = instance_eval(&bloque)
      raise BooleanException.new "The result isn't boolean" unless result.is_a? TrueClass or result.is_a? FalseClass
      raise ConditionError.new error_message unless result
    end
  end

  private def invariant(&bloque)
    @after_blocks ||= []
    @after_blocks << proc_for_invariant(bloque, "Invariant error")
  end

  private def pre(&bloque)
    @pre = proc_with_block_condition(bloque, "Precondition error")
  end

  private def post(&bloque)
    @post = proc_with_block_condition(bloque, "Postcondition error")
  end

  private def typed(dicTypes, retType)
    @typed = proc_with_typed_condition(dicTypes, retType, "dicType error")
  end


  private def redefine_method(contractMethod, pre, post, typed, list_args)
    self.define_method(contractMethod.method_name) do |*args, &block|
      @external_level_redefine_method = true if @external_level_redefine_method.nil?
      local_external_level_redefine_method = @external_level_redefine_method
      @external_level_redefine_method = false

      if local_external_level_redefine_method
        # instance_eval(&pre) unless pre.nil?
        instance_exec list_args, args, &pre unless pre.nil?
        self.class.before_blocks&.each do |proc|
          # instance_eval(&proc)
          instance_exec list_args, args, &proc
        end
      end
      ret = contractMethod.exec_on(self, args, block)
      if local_external_level_redefine_method
        self.class.after_blocks&.each do |proc|
          # instance_eval(&proc)
          instance_exec list_args, args, &proc
        end
        # instance_eval(&post) unless post.nil?
        instance_exec list_args, args, ret, &post unless post.nil?
        instance_exec list_args, args, ret, &typed unless typed.nil?
      end
      @external_level_redefine_method = local_external_level_redefine_method
      ret
    end
  end

  private def method_added(method_name, *args)
    @external_level_method_added = true if @external_level_method_added.nil?
    local_external_level_method_added = @external_level_method_added
    @external_level_method_added = false

    list_args = self.instance_method(method_name).parameters.map { |(a,b)| b }

    if local_external_level_method_added
      contractMethod = ContractMethod.new(self.instance_method(method_name), method_name)
      self.send(:redefine_method, contractMethod,  @pre, @post, @typed, list_args)
      @typed = nil
      @pre = nil
      @post = nil
    end
    @external_level_method_added = local_external_level_method_added
  end
end



# class Misil
#   attr_accessor :daño
#
#   def initialize
#     @daño = 10
#   end
# end
#
# class FixNum
#   attr_accessor :num
#   def initialize(value)
#     @num = value
#   end
# end
#
# # class Edificio
# #
# #   attr_accessor :vida
# #
# #   def initialize
# #     @vida = 1000
# #   end
# #
# #   def sufriDanio(n)
# #     @vida -= n.num
# #   end
# # end
# #
# # class Tanque
# #
# #   attr_accessor :vida
# #
# #   def initialize
# #     @vida = 100
# #   end
# #
# #
# #   typed({enemigo: Edificio, proyectil: Misil}, FixNum)
# #   def atacarEdificio(enemigo, proyectil)
# #     daño = proyectil.daño
# #     enemigo.sufriDanio(FixNum.new(daño))
# #     FixNum.new(daño)
# #   end
# #
# #   def sufriDanio(n)
# #     @vida = @vida-n.num
# #   end
# # end



# unTanque = Tanque.new
# otroTanque = Tanque.new
# unEdificio = Edificio.new
#
# unTanque.atacarEdificio(unEdificio, Misil.new) # OK
# puts "venimos bien"
# #unTanque.atacarEdificio(otroTanque, Misil.new) # Error!
#
# puts unEdificio.vida