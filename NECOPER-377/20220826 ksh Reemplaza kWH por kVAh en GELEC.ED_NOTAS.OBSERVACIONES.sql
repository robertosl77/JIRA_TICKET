--[Calculo] Se requiere instalar un equipo de 1 kVA y 3.6 kWH | Aspirador de secreciones, Concentrador de oxigeno, Respirador, Saturador
SET SERVEROUTPUT ON
DECLARE
    V_NOTA GELEC.ED_NOTAS.OBSERVACIONES%TYPE;
BEGIN

    FOR NOTA IN (
              SELECT ID_NOTA, OBSERVACIONES, REPLACE(OBSERVACIONES,'kWH','kVAh') CORREGIDO, INSTR(OBSERVACIONES,'kWH') POSICION FROM  GELEC.ED_NOTAS 
              WHERE 
                ID_TIPO_NOTA=2
                AND OBSERVACIONES LIKE '%kWH%'
                AND ROWNUM<4
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------');
        -- MUESTRO ANTES
        DBMS_OUTPUT.PUT_LINE(NOTA.ID_NOTA||','||NOTA.POSICION||','||NOTA.OBSERVACIONES||','||NOTA.CORREGIDO);      
        -- APLICO UPDATE
        UPDATE GELEC.ED_NOTAS SET OBSERVACIONES=REPLACE(OBSERVACIONES,'kWH','kVAh') WHERE ID_NOTA=NOTA.ID_NOTA;
        --COMMIT;
        SELECT OBSERVACIONES INTO V_NOTA FROM GELEC.ED_NOTAS WHERE ID_NOTA=NOTA.ID_NOTA;
        DBMS_OUTPUT.PUT_LINE('CORREGIDO>>>'||V_NOTA);
        
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Se detecto un error...');
        
END;

/*
RESULTADO DE EJEMPLO EN GISDEV01
bloque anónimo terminado
-------------------------------------------------------------------------------------------------------
15952,43,[Calculo] potencia: 0 kVA, capacidad: 0.6 kWH | CPAP,[Calculo] potencia: 0 kVA, capacidad: 0.6 kVAh | CPAP
CORREGIDO>>>[Calculo] potencia: 0 kVA, capacidad: 0.6 kVAh | CPAP
-------------------------------------------------------------------------------------------------------
15986,47,[Calculo] potencia: 0.115 kVA, capacidad: 1.2 kWH | BPAP, Bomba infusion,[Calculo] potencia: 0.115 kVA, capacidad: 1.2 kVAh | BPAP, Bomba infusion
CORREGIDO>>>[Calculo] potencia: 0.115 kVA, capacidad: 1.2 kVAh | BPAP, Bomba infusion
-------------------------------------------------------------------------------------------------------
16082,60,[Actualización] | Se modifica la capacidad de BBP0002 a 12 kWH,[Actualización] | Se modifica la capacidad de BBP0002 a 12 kVAh
CORREGIDO>>>[Actualización] | Se modifica la capacidad de BBP0002 a 12 kVAh
-------------------------------------------------------------------------------------------------------

*/
