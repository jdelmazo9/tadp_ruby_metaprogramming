describe 'GuerreroTests' do

  guerrero = Class.new do
    attr_accessor :fuerza, :vida

    def initialize(vida, fuerza)
      @vida = vida
      @fuerza = fuerza
    end

    invariant { fuerza > 0 && fuerza < 100 }
    invariant { vida > 0 && vida < 100 }

  end

  it 'testPinchaPorVida' do

    un_guerrero = guerrero.new(50,50)

    expect { un_guerrero.vida = 0 }.to raise_error(ConditionError)

  end

  it 'testVidaPositiva' do
    un_guerrero = guerrero.new(50,50)
    un_guerrero.vida = 50

    expect(un_guerrero.vida).to be 50
  end

end


describe 'PilaTests' do

  pila = Class.new do

    attr_accessor :current_node, :capacity

    invariant { capacity >= 0 }

    post { empty? }
    def initialize(capacity)
      @capacity = capacity
      @current_node = nil
    end

    pre { !full? }
    post { height > 0 }
    def push(element)
      @current_node = Node.new(element, current_node)
    end

    pre { !empty? }
    def pop
      element = top
      @current_node = @current_node.next_node
      element
    end

    pre { !empty? }
    def top
      current_node.element
    end

    def height
      empty? ? 0 : current_node.size
    end

    def empty?
      current_node.nil?
    end

    def full?
      height == capacity
    end

    Node = Struct.new(:element, :next_node) do
      def size
        next_node.nil? ? 1 : 1 + next_node.size
      end
    end

  end

  it 'testJugandoConLaPila' do
    unaPila = pila.new(10)
    unaPila.push("AEEEEEEEEEEEA")
    unaPila.push("¡Dale negro!")
    unaPila.push("Que todo el mundo grite")
    unaPila.push("Sabalé")
    unaPila.push("Sabalé")
    unaPila.push("Sabalero")
    unaPila.push("La culpa es de este pueblo")
    unaPila.push("Sabalé")
    unaPila.push("Sabalé")


    expect(unaPila.full?).not_to be true

    puts("....................................")
    puts("Los Palmeras - Soy Sabalero (Chorus)")
    puts("....................................")
    for i in 0..8
      puts(unaPila.pop)
    end
  end

  it 'pilaTieneAlgo' do

    unaPila = pila.new(5)
    unaPila.push(1)

    expect(unaPila.height).to be 1

  end

  it 'testPushNoCumplePrecondicion' do

    unaPila = pila.new(5)

    expect {
      for i in 0..5
        unaPila.push(i)
      end
    }.to raise_error(ConditionError)

  end

  it 'testPopNoCumplePrecondicion' do

    unaPila = pila.new(5)

    expect {
      unaPila.pop
    }.to raise_error(ConditionError)

  end

  it 'testTopNoCumplePrecondicion' do
    unaPila = pila.new(5)

    expect {
      unaPila.top
    }.to raise_error(ConditionError)
  end

  it 'testRompePorInvariant' do
    expect {
      unaPila = pila.new(-1)
    }.to raise_error(ConditionError)

  end


end

describe 'OperacionesTest' do
  operaciones = Class.new do
    #precondición de dividir
    pre { divisor != 0 }
    #postcondición de dividir
    post { |result| result * divisor == dividendo }
    def dividir(dividendo, divisor)
      dividendo / divisor
    end

    pre { divisor != 0 }
    #postcondición de dividir
    post { |result| result * divisor == dividendo + 1 }
    def dividir_con_post_falopa(dividendo, divisor)
      dividendo / divisor
    end

    # este método no se ve afectado por ninguna pre/post condición
    def restar(minuendo, sustraendo)
      minuendo - sustraendo
    end
  end

  # > Operaciones.new.dividir(4, 2)
  # => 2
  it 'se puede dividir por 2' do
    expect(operaciones.new().dividir(4, 2)).to be 2
  end

  # > Operaciones.new.dividir(4, 0)
  it 'no se puede dividir por 0' do
    expect{operaciones.new().dividir(4, 0)}.to raise_error(ConditionError)
  end

  # > Operaciones.new.dividir(4, 2)
  it 'la post condicion no se cumple, rompe' do
    expect{operaciones.new().dividir_con_post_falopa(4, 2)}.to raise_error(ConditionError)
  end
end


# CREO LOS TEST CON LAS CLASES DIRECTAMENTE A DIFERENCIA DE LOS OTROS TEST YA QUE PARA EVALUAR NECESITO LAS CLASES NOMBRADAS
describe 'EdificiosYTanquesTest' do
  class Misil
    attr_accessor :daño

    def initialize
      @daño = 10
    end
  end

  class FixNum
    attr_accessor :num
    def initialize(value)
      @num = value
    end
  end

  class Edificio

    attr_accessor :vida

    def initialize
      @vida = 1000
    end

    def sufriDanio(n)
      @vida -= n.num
    end
  end

  class Tanque

    attr_accessor :vida

    def initialize
      @vida = 100
    end


    typed({enemigo: Edificio, proyectil: Misil}, FixNum)
    def atacarEdificio(enemigo, proyectil)
      daño = proyectil.daño
      enemigo.sufriDanio(FixNum.new(daño))
      FixNum.new(daño)
    end

    typed({enemigo: Edificio, proyectil: Misil}, FixNum)
    def atacarEdificio2(enemigo, proyectil)
      daño = proyectil.daño
      enemigo.sufriDanio(FixNum.new(daño))
      daño
    end

    def sufriDanio(n)
      @vida = @vida-n.num
    end
  end

  it 'se puede atacar a un edificio con un tanque' do
    unEdificio = Edificio.new
    Tanque.new.atacarEdificio(unEdificio, Misil.new)
    expect( unEdificio.vida ).to be 990
  end

  it 'NO se puede atacar a un tanque con un tanque' do
    expect { Tanque.new.atacarEdificio(Tanque.new, Misil.new) }.to raise_error(ConditionError)
  end

  it 'NO devuelve un tipo FixNum el retorno de atacarEdificio' do
    expect { Tanque.new.atacarEdificio2(Edificio.new, Misil.new) }.to raise_error(ConditionError)
  end

end