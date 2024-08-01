import React from "react";
import { Modal, ModalBody, ModalHeader } from "reactstrap";

const ModalNotasVersion = (props) => {
  return (
    <>
      <Modal
        backdrop="static"
        isOpen={props.isOpen}
        toggle={() => props.toggle(false)}
        className={props.className}
        size="lg"
      >
        <ModalHeader toggle={() => props.toggle(false)}>GELEC {props.version}:</ModalHeader>
        <ModalBody>
          <div>
          <h5>1.30.0:</h5>
          <br />
          - Modificaciones en las fechas y horas del Fin Manual: se adecuo interfases permitiendo la carga de fecha de fin manual.
          <br />
          - Se habilito la carga de documentos Modulos FAE de GELEC. 
          <br />
          - Error fecha hora fin manual: Se actualizo el uso horario de la aplicación. 
          <br />
          - Modulo FAE: se nivelo los datos de marcas “Posee FAE”. 
          <br />
          - Modulo FAE, se adecuo proceso sobre el alta o baja de la marca “Posee FAE”. 
          <br />
          -  No guarda la fecha y hora de documentos ya cerrados: se nivelo datos.
          <br />
          <br />
          <h5>1.29.6:</h5>
          <br />
          - Se corrige error que no permite continuar en el formulario al ingresar un nuevo equipo FAE
          <br />
          - Se bloquean los botones Calculadora y Ordenes en registros FAE-Cliente nuevos
          <br />
          - Se corrige error al seleccionar un historial vacío en la informacion FAE-Cliente
          <br />
          - Se agrega la tabla de canceladas y retiradas al buscador por nro de cuenta en Gestión FAE
          <br />
          - Ya no se permite crear una orden si la orden anterior no fue cerrada (por ejemplo: dos ordenes de instalación)
          <br />
          - Se corrige formato de direcciones de mail en copia al momento de enviar un email de ordenes
          <br />
          - Se corrige ruta IOX copiada en la vista "Lista de ordenes"
          <br />
          - Se corrige error de teléfonos en la vista "Próximas ordenes"
          <br />
          - Se cambia el tamaño de paginado en el Home a 50 por default
          <br />
          - Se agrega columna F y A en el Home, para mostrar si el cliente tiene FAE o AMI (S = "Si", N = "No")
          <br />
          - Ahora se refresca la pantalla del cliente cuando se agrega un archivo de documentación
          <br />
          - Se corrige ordenamiento historial de documentos del cliente
          <br />
          - Se agrega la posibilidad de editar Region y Zona de un documento
          <br />
          - Se agrega link para visualizar las afectaciones de los clientes en la aplicacion GI (Calculadora)
          <br />
          <br />
          <h5>1.29.5:</h5>
          <br />
          - Se corrige error de IOX cuando se intenta subir un documento y el usuario no pasó por el equipamiento del cliente primero
          <br />
          - Se corrige error cuando se intenta modificar un equipo FAE sin cambiar su capacidad
          <br />
          - Calculadora: Si la sumatoria de potencia supera los 800W ahora se oculta la fila de 1kVA
          <br />
          - La carga de lote ENRE siempre que exista la cuenta intentara dar de alta la aparatología que encuentre
          <br />
          <br />
          <h5>1.29.4:</h5>
            {"- Reactivar una orden ahora regresa a un estado anterior (Abonada -> Finalizada -> Pendiente)"}
            <br />
            - Se elimina el boton "Editar fecha", ahora las fechas se eligen al momento de crear una orden y de finalizarla
            <br />
            - Se eliminan las ordenes tipo "Trámites/Consultas" y "Vencimiento RECS"
            <br />
            - Se agrega la opcion para modificar un equipo FAE en stock
            <br />
            - Al finalizar una orden de tipo "Actualización" se puede modificar la capacidad de un equipo FAE
            <br />
            - Se agrega modelo a los equipos FAE (Alta y Modificación)
            <br />
            - Se elimina el valor "Consumo" de la aparatología
            <br />
            - Se cambia la funcionalidad "Calculadora FAE", ahora permite seleccionar la autonomía deseada y muestra las FAE en stock
            <br />
            - El lote ENRE ahora toma aparatología
            <br />
            <br />
          <h5>1.29.3:</h5>
            - Se corrige el campo "Búsqueda" en el módulo Gestión FAE
            <br />
            - Se corrige redireccionamiento a la aparatología y documentación del cliente
            <br />
            - Se corrigen errores de IOX
            <br />
            - Se cambia la estructura de carpetas en IOX (ahora las ordenes estan dentro de las carpetas de cliente)
            <br />
            - Se corrige cambio de estado de ordenes (no cambiaba el estado de la FAE)
            <br />
            - Se agregan validaciones en la carga de documentación al cambiar de estado una orden
            <br />
            - La carga de documentacion al confirmar o cancelar una orden es obligatoria
            <br />
            - Se agrega opción para poner fecha de fin a una orden
            <br />
            - Se agrega campo historial de FAE a la ventana Información del cliente (permite navegar entre las distintas FAE del cliente)
            <br />
            - Se agrega ruta IOX al reporte detalle de ordenes
            <br />
            - Se colorea el estado de las ordenes en base a su valor
            <br />
            - Se corrige el boton editar fecha
            <br />
            - Se agrega advertencia al ingresar una fecha de fin anterior a la fecha de inicio de una orden
            <br />
            - Se agrega filtro de estado y tipo en el reporte detalle de ordenes
            <br />
            - Se agrega la posibilidad de navegar a la informacion del cliente desde el reporte detalle de ordenes (Hacer doble click en nro de serie!)
            <br />
            - Se agrega la posibilidad de ingresar a las ordenes desde un registro FAE retirado
            <br />
            <br />
            <h5>1.29.0:</h5>
            - Se agrega el módulo Gestión FAE
            <br />
            - Se agrega potencia y capacidad a la aparatología de los pacientes
            <br />
            - Se agrega visor de notas de versión (para volver a verlas borrar LocalStorage en
            chrome)
            <br />
          </div>
        </ModalBody>
      </Modal>
    </>
  );
};
export default ModalNotasVersion;
