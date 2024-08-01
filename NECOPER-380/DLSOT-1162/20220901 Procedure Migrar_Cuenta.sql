   PROCEDURE MIGRAR_CUENTA (P_ORIGEN      IN     VARCHAR2,
                            P_DESTINO     IN     VARCHAR2,
                            P_USUARIO     IN     VARCHAR2,
                            P_RESULTADO      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      
      V_LOG   NUMBER;
      V_CANT NUMBER;
   BEGIN
      --Inserta en GELEC.ED_LOG para obtener el ID_LOG
      V_LOG :=
         GELEC.INSERT_LOG (
               'Muda cuenta origen: '
            || P_ORIGEN
            || ' a cuenta destino: '
            || P_DESTINO,
            P_USUARIO);

      -- Migro los numeros de telefono que tengan llamadas efectivas o menos de 3 llamadas no efectivas
      -- 01/09/2022 rsleiva: se cambio este punto, ahora solo migra nros celulares efectivos (al menos 1) y que no se duplique en destino
          BEGIN
              FOR TEL IN ( 
                          SELECT DISTINCT UPPER(NVL(CC.NOMBRE,'MIGRADO')) NOMBRE, CC.TELEFONO, CC.TIPO_CONTACTO
                          FROM GELEC.ED_CONTACTOS_CLIENTES CC
                          WHERE 
                              CUENTA=P_ORIGEN
                              AND NVL(CC.LOG_HASTA,0)=0
                              AND CC.TIPO_CONTACTO='Celular'
                              AND (SELECT COUNT(1) FROM GELEC.ED_NOTAS WHERE CUENTA=CC.CUENTA AND IDDESTINO=CC.ID_TEL AND EFECTIVO>0)>0   --Filtra los que no tengan efectividad
                              AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA=P_DESTINO AND TELEFONO=CC.TELEFONO)=0    --Filtra los que ya esten cargados en destino
              ) LOOP
              
                    GELEC.PKG_OTROS.INSERTA_TELEFONO (  
                                                  'DA DE ALTA EL CONTACTO DE UNA CUENTA',
                                                  'Migracion',
                                                  P_DESTINO,
                                                  TEL.NOMBRE,
                                                  TEL.TELEFONO,
                                                  TEL.TIPO_CONTACTO,
                                                  P_RESULTADO);    
              END LOOP;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:= 'Sin Telefono para migrar';
          END;

      -- Migro las notas de hace 6 meses
      -- 01/09/2022 rsleiva: se agrega a las notas migradas, en el campo observaciones, la leyenda [MIGRADO]
          BEGIN
              FOR NOTA IN ( 
                      SELECT 
                          CN.ID_NOTA, 
                          (SELECT OBSERVACIONES FROM GELEC.ED_NOTAS WHERE ID_NOTA=CN.ID_NOTA) OBSERVACIONES
                      FROM 
                          GELEC.ED_CLIENTE_NOTA CN
                      WHERE
                          CN.CUENTA = P_ORIGEN
                          AND (SELECT ADD_MONTHS (L.FECHA, 6) FROM GELEC.ED_LOG L WHERE L.LOG_ID = CN.LOG_DESDE) >= SYSDATE
              
              ) LOOP
                    -- QUITO LEYENDA DE OTRA POSIBLE MIGRACION ANTERIOR PARA NO INCREMENTAR EL LARGO DEL CAMPO
                    NOTA.OBSERVACIONES:= REPLACE(NOTA.OBSERVACIONES,'[MIGRADO] ',NULL);
                    -- SI EL LARGO DE LA NOTA Y LO QUE SE ESTIMA QUE SE VA A AGREGAR SUPERA EL LIMITE NO INGRESA LEYENDA
                    IF 500-LENGTH(NOTA.OBSERVACIONES)>=35 THEN 
                        NOTA.OBSERVACIONES:= '[MIGRADO] '||NOTA.OBSERVACIONES;
                    END IF;
                    --ACTUALIZO CAMPO OBSERVACIONES EN GELEC.ED_NOTAS
                    UPDATE GELEC.ED_NOTAS SET OBSERVACIONES=NOTA.OBSERVACIONES WHERE ID_NOTA=NOTA.ID_NOTA;
                    UPDATE GELEC.ED_CLIENTE_NOTA SET CUENTA=P_DESTINO WHERE ID_NOTA=NOTA.ID_NOTA;
                    
              END LOOP;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:='Error al migrar notas';
          END;

      -- Migro marcas / verifico para no duplicar
      -- 26/05/2021 : Ahora me fijo solamente ID marca, para no tener 2 submarcas activas en una misma marca
      -- 01/09/2022 rsleiva: se corrige la baja potencial en origen, y se agrega la migracion unicamente del cliente multiple
          BEGIN
              --BAJA POTENCIAL
              SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
              WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=1;
              --
              IF V_CANT=0 THEN
                  GELEC.PKG_OTROS.INSERTAR_MARCA (
                      P_USUARIO, 1, 4,
                      P_ORIGEN,
                      '[Marca: Baja Potencial | Submarca: MIGRACION]',
                      P_RESULTADO);  
              END IF;
              --CLIENTE MULTIPLE EN ORIGEN
              SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
              WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;
              --
              IF V_CANT=1 THEN
                  --CLIENTE MULTIPLE EN DESTINO
                  SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
                  WHERE CUENTA=P_DESTINO AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;    
                  --
                  IF V_CANT=0 THEN
                      GELEC.PKG_OTROS.INSERTAR_MARCA (
                          P_USUARIO, 9, 21,
                          P_DESTINO,
                          '[Marca: Baja Potencial | Submarca: MIGRACION]',
                          P_RESULTADO);  
                  END IF;
              END IF;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:='Error al migrar Marcas';
          END;

      -- Migro aparatologia / verifico cuenta destino para no duplicar registros
      UPDATE GELEC.ED_CLIENTE_ARTEFACTO a
         SET a.CUENTA = P_DESTINO
       WHERE     a.cuenta = P_ORIGEN
             AND (SELECT COUNT (*)
                    FROM GELEC.ED_CLIENTE_ARTEFACTO aa
                   WHERE     aa.CUENTA = P_DESTINO
                         AND aa.ID_APARATO = a.ID_APARATO
                         AND aa.log_hasta IS NULL) = 0
             AND a.LOG_HASTA IS NULL;

      -- Migro paciente / verifico que no este el paciente ya ingresado en la cuenta destino
      BEGIN
          FOR P IN (
                  SELECT DISTINCT DNI FROM GELEC.ED_PACIENTE_CLIENTE
                  WHERE 
                      CUENTA= P_ORIGEN
                      AND LOG_HASTA IS NULL
          ) LOOP
              
              GELEC.PKG_PACIENTES.B_PACIENTE (
                                      P_ORIGEN,
                                      P.DNI,
                                      V_LOG,
                                      P_RESULTADO) ;  
          END LOOP;          
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              P_RESULTADO:='Sin Telefono para migrar';
      END;


      COMMIT;

      P_RESULTADO := 'Migracion finalizada';
   END;













