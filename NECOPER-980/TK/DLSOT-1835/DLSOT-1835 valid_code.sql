/*
S6.914PI                      
S8.1059MO                     
S18-1178                      
S19-0571                      
S7.681MO                      
S18-1179                      
S34-312                       
S16-0410                      
S18-1176                      
S02-54                        
S04-504                       
*/
SET SERVEROUTPUT ON
DECLARE
      p_code                VARCHAR2 (50):='S6-9-1-4PI    ';
      v_return              VARCHAR2 (30);
      v_cont                NUMBER (5);
      v_aux                 VARCHAR2 (30);
      v_pos                 NUMBER (5);
      v_codigo_resultante   VARCHAR2 (30);
   BEGIN
        --dbms_output.put_line('Prueba');
      v_return := '';
      v_aux := p_code;
      v_cont := 0;
      v_pos := 1;

      v_return := v_aux;

      WHILE v_cont <= 3 AND v_pos <> 0
      LOOP
         v_pos := INSTR (v_aux, '-');

         IF v_pos != 0
         THEN
            v_aux := SUBSTR (v_aux, v_pos + 1);
            --dbms_output.put_line(v_aux);
            v_cont := v_cont + 1;
         END IF;
      END LOOP;
        --dbms_output.put_line(v_codigo_resultante);
        --dbms_output.put_line(v_cont);
      IF v_cont = 1
      THEN
        --dbms_output.put_line(v_aux);
         v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);

         IF UPPER (v_codigo_resultante) != 'NULL'
         THEN
            v_return := TRIM (v_codigo_resultante);
         END IF;
      ELSE
         IF v_cont = 3
         THEN
            v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);
            v_codigo_resultante :=
               SUBSTR (v_codigo_resultante,
                       INSTR (v_codigo_resultante, '-') + 1
                      );

            IF UPPER (v_codigo_resultante) != 'NULL'
            THEN
               v_return := TRIM (v_codigo_resultante);
            END IF;
         END IF;
      END IF;
        --dbms_output.put_line('1 ' || v_codigo_resultante);
        DBMS_OUTPUT.PUT_LINE('Recibe: '||p_code||' -> Devuele: '||v_return);
--      RETURN v_return;
   END;