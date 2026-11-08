object pdepfoni {
    var clientes = []
}

class Cliente {
    var telefono
    var packs = []
    var consumos = []
    var dinero
    var cuenta
    var deuda

    method costoPromedioEnRango(inicio, fin) {
        const consumosEnRango = self.consumosEnRango(inicio, fin)
        const cantidadConsumos = consumosEnRango.size()
        return consumosEnRango.sum({consumo => consumo.costo()}).div(cantidadConsumos)
    }

    method consumosEnRango(inicio, fin) {
        return consumos.filter({consumo => consumo.fecha().between(inicio, fin)})
    }

    method consumoTotalUltimoMes() {
        const fechaHace30Dias = new Date().minusDays(30)
        const fechaActual = new Date()
        return self.consumosEnRango(fechaHace30Dias, fechaActual).sum({consumo => consumo.costo()})
    }

    method comprarPack(pack) {
        if(dinero < pack.precio()){
            throw new Exception(message = "No alcanza el dinero del cliente para comprar el pack")
        }
        dinero -= pack.precio()
        packs.add(pack)
    }

    method puedeHacerConsumo(consumo) {
        return packs.any({pack => pack.puedeSatisfacerConsumo(consumo)})
    }

    method realizarConsumo(consumo) {
        cuenta.realizarConsumo(consumo, self)
    }

    method ultimoPackQueSatisface(consumo) {
        return packs.filter({pack => pack.puedeSatisfacerConsumo(consumo)}).last()
    }

    method limpiezaPacks() {
        packs.removeAll({pack => pack.estaAcabado() || pack.estaVencido()})
    }

    method cambiarCuenta(nuevaCuenta) {
        cuenta = nuevaCuenta
    }

    method deuda() {
        return deuda
    }

    method consumos() {
        return consumos
    }

    method aumentarDeuda(montoAAgregar) {
        deuda += montoAAgregar
    }
}

object cuentaComun {
    method realizarConsumo(consumo, cliente) {
        if(!cliente.puedeHacerConsumo(consumo)){
            throw new Exception(message = "No se puede realizar el consumo")
        }
        const ultimoPackUtil = cliente.ultimoPackQueSatisface(consumo)
        cliente.consumos().add(consumo)
        ultimoPackUtil.gastarPack(consumo)
    }
}

object cuentaBlack {
    method realizarConsumo(consumo, cliente) {
        if(!cliente.puedeHacerConsumo(consumo)){
            cliente.aumentarDeuda(consumo.costo())
        }
        cliente.consumos().add(consumo)
    }
}

object cuentaPlatinum {
    method realizarConsumo(consumo, cliente) {
        cliente.consumos().add(consumo)
    }
}

class Consumo {
    var fecha = new Date()

    method fecha() {
        return fecha
    }

    method costo()

    method esInternet() = false
    method esLlamada() = false
}

class ConsumoInternet inherits Consumo {
    var cantidadMB

    method cantidadMB() {
        return cantidadMB
    }

    override method costo() {
        return 2 * cantidadMB
    }

    override method esInternet() = true
}

class ConsumoLlamada inherits Consumo {
    var cantidadSegundos

    override method costo() {
        return 100 + 10 * (cantidadSegundos - 30).max(0)
    }

    override method esLlamada() = true
}

class Pack {
    var precio
    var fechaVencimiento = new Date()

    method precio() {
        return precio
    }

    method puedeSatisfacerConsumo(consumo)

    method gastarPack(consumo) {
    }

    method estaVencido() {
        return fechaVencimiento < new Date()
    }

    method estaAcabado() = false
}

class PackCredito inherits Pack {
    var creditoDisponible

    override method puedeSatisfacerConsumo(consumo) {
        return creditoDisponible >= consumo.costo() && !self.estaVencido()
    }

    override method gastarPack(consumo) {
        creditoDisponible -= consumo.costo()
    }

    override method estaAcabado() {
        return creditoDisponible == 0
    }
}

class PackMBLibres inherits Pack {
    var MBLibres

    override method puedeSatisfacerConsumo(consumo) {
        return consumo.esInternet() && MBLibres >= consumo.cantidadMB() && !self.estaVencido()
    }

    override method gastarPack(consumo) {
        MBLibres -= consumo.cantidadMB()
    }

    override method estaAcabado() {
        return MBLibres == 0
    }
}

class PackMBLibresPlus inherits PackMBLibres {
    override method puedeSatisfacerConsumo(consumo) {
        if(MBLibres != 0){
            return super(consumo)
        }
        else{
            return super(consumo) && consumo.cantidadMB() <= 0.1
        }
    }
}

class PackLlamadasGratis inherits Pack {
    override method puedeSatisfacerConsumo(consumo) {
        return consumo.esLlamada() && !self.estaVencido()
    }
}

class PackInternetIlimitadoFindes inherits Pack {
    override method puedeSatisfacerConsumo(consumo) {
        return consumo.esInternet() && consumo.fecha().isWeekendDay() && !self.estaVencido()
    }
}
