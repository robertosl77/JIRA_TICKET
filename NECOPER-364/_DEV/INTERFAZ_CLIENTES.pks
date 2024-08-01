CREATE OR REPLACE PACKAGE NEXUS_GIS.INTERFAZ_CLIENTES IS
--  /******************************************************************************************
--  INTERFAZ DE DATOS DE CLIENTES PROVENIENTES DEL SISTEMA COMERCIAL
--  FINALIDAD: Actualizar los datos de clientes en el GIS con informacion del sistema comercial
--  VERSION: 1.0.6
--  VERSION: 1.0.9 (FROM EDENOR)
--  ******************************************************************************************/

   -- Codigos de error
   k_error_calleinvalida   CONSTANT NUMBER (10) := 200000;

   /*
   ----------------------------------------------------------------------------------
   Este proceso realiza el poblado de la tabla sprClientInterface a partir de las
   novedades del sistema comercial de Edenor (UTC_Novedades)
   ----------------------------------------------------------------------------------
   Valores retornados en p_retval:
   0: ejecucion exitosa, sin errores
   mayor a 0: cantidad de novedades de UTC_Novedades con error
   -1: No se puede ejecutar porque existen novedades pendientes en sprClientInterface
   ----------------------------------------------------------------------------------
   Tracking de cambios:
     XX-Xxx-2006 - Gustavo Villada y Marcelo Belnicoff, version inicial
     23-Ene-2007 - AH, verificacion del codigo y agregado de comentarios.
     26-Ene-2007 - AH, cambio de la logica para clientes sensibles (custatt20 y 21)
     04-Feb-2007 - AH, correccion de issues detectados en primer ciclo de prueba Edenor
     06-Feb-2007 - AH, correccion de bugs, mensajes para trace y mejora de performance.
     14-Feb-2007 - AH, incorporacion de inserciones automaticas en sprgCodes
     08-Mar-2007 - AH, issues y mejoras del segundo ciclo de prueba Edenor
     20-Mar-2007 - GM, correcciones en las pruebas internas del segundo ciclo de prueba Edenor
     19-Abr-2007 - AH, cambio en el poblado de streetOther (NC30).
                       custatt27 se completa con el dato 'sistema', Control de cambio nro.1.
                       bug: smStreets puede varios registros con el mismo streetId (NC31)
     25-Abr-2007 - AH, Se logea el nombre de la tabla UTC que no pudo accederse (NC7)
                       Rechazar novedades que no tengan fecha_alta (NC28).
                       Los campos varchar que no se modifican ahora se completan con "[N/C]" (NC32)
                       Cambios de numero de cuenta por cambio de potencia (NC29).
                       Se coloco todo el codigo fuente de interfaz de clientes en un package
                       Se incluyo en el package el proceso de actualizaciones geograficas
     07-Jun-2007 - AH, Se quito la obligatoriedad del campo custAtt2 (ID suministro)
                       NC33: Se quito la obligatoriedad a los campos CMED_ID y PLAN_ID
                       NC37: manejo de las excepciones no contempladas
                       NC37: se descartan de Tca_Bgns4dl los registros que fueron anulados
                       Se optimizo la funcion para determinar si el cliente es pre-pago
     17-Ago-2007 - GP, Se agrego control de excepciones al obtener el nombre de la calle.
     30-Oct-2007 - PD, Se agrego la validacion de existencia de ID's de servicio vivos antes de
                     dar de baja un suministro potencial en el proceso de depuracion.
                     Al dar de baja suministros potenciales, se corrigio el join entre dos tablas.
     22-Nov-2007 - PD, Se incorporo la excepcion CASE_NOT_FOUND con codigo de error 2000000 en el
                       de insercion de "poblarclientinterface". En caso de salir por OTHERS deja
                       el error de oracle en UTC_NOVEDADES.(NC44).
     30-Jan-2007 - PD, Se incorporo el CC 148: debe soportar recibir nulos en el campo StreetNumber de UTC.
             Se soluciono el issue 154. Anular servicios con Historia.
     24-Abr-2008 - PB, Se cambio el modo de actualizar graficamente los clientes. Ahora todo se realiza en transacciones
             atomicas.
     01-Ago-2008 - PD. Se incorporo mayor nivel de logueo en el proceso de actualizacion grafica.
     04-Ago-2008 - PD. Se corrigio el incidente 1133. "[Produccion] Error en proceso interfaz_clientes unique constraint".
                Existia un error en el manejo de secuencias del proceso actualizacion_grafica
     30-Ene-2009- PD. Se adapto la interfaz para que utilice el paquete NETWORK_UPDATER
     18-May-2009- PD. Se incorporo el control de tarifas.
     02-May-2011- Se adecuo para no usar Cuentas_T3 y usar CLIENTES.
     01-Oct-2012- Se adecuo para no usar Clientes_T12 y usar CLIENTES.
    04-Oct-2013-  Se hicieron las siguientes modificaciones
    *  v_client.streetnumber se actualiza de solo_numeros(v_tca_4dl.nro_cons).
    *  v_client.streetother se actualiza de  v_tca_4dl.piso_cons||v_tca_4dl.dpto_cons.
    *  v_client.custatt24 se actualiza utilizando streetname guardados en variables v_calle1, v_calle2, donde streetid = v_client.streetid1
         y para la otra variable streetid = v_client.streetid2, par localidad se tomo de amareas donde areaid = v_client.fsareacode.
           * se comenta el codigo relacionado con Cambios de potencia que implican un nuevo numero de cuenta.
   */
   PROCEDURE poblar_clientinterface (
      p_nroproceso   IN       NUMBER,
      p_userid       IN       NUMBER,
      p_retval       IN OUT   NUMBER
   );

   /*
   ----------------------------------------------------------------------------------
   Este proceso realiza las siguientes tareas:
   1-Relacionar cuentas a entidades graficas suministros que hayan sido de alta a traves
     del circuito de recupero de energia "a no pedido de clientes"

   2-Baja logica en GIS de los clientes dados de baja por el sistema comercial,
     de tal manera que no sean visualizados en el GIS como clientes activos.

   3-Depuracion de NNSS y suministros potenciales anulados.
   ----------------------------------------------------------------------------------
   Valores retornados en p_retval:
   0: ejecucion exitosa, sin errores
   mayor a 0: cantidad de actualizaciones con error
   -1: No se puede ejecutar porque existen novedades pendientes en sprClientInterface
   ----------------------------------------------------------------------------------
   Tracking de cambios:
     XX-Xxx-2006 - Gustavo Villada y Marcelo Belnicoff, version inicial
     25-Abr-2007 - AH, verificacion general del codigo, agregado de comentarios.
                   Ahora los cambios al modelo se hacen con el package edenor_rutinascomunes
     14-May-2007 - AH. correccion de bug en el join de depuracion de NNSS (NC36)
     03-Sep-2007 - GP. Separacion del proceso en 2, por inconvenientes tecnicos con el DBlink con DB2.
     30-Ene-2009- PD. Se adapto la interfaz para que utilice el paquete NETWORK_UPDATER

   */
   PROCEDURE actualizacion_grafica (
      p_nroproceso   IN       NUMBER,
      p_userid       IN       NUMBER,
      p_retval       OUT      NUMBER
   );

   PROCEDURE depuracion_suministros (
      p_nroproceso   IN       NUMBER,
      p_userid       IN       NUMBER,
      p_retval       OUT      NUMBER
   );

   FUNCTION verificar_tarifa_valida (
      p_objectid   nexus_gis.sprobjects.objectid%TYPE,
      p_linkid     nexus_gis.links.linkid%TYPE,
      p_client     nexus_gis.sprclients.fsclientid%TYPE
   )
      RETURN VARCHAR2;


   -- Imprime en el DBMB_OUTPUT los mensajes de logs asociados
   -- a un numero de proceso en particular
   PROCEDURE imprime_logs_en_dbms_output (v_proc NUMBER);

END INTERFAZ_CLIENTES;
/