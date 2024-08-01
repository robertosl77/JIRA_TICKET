set serveroutput on 
declare

begin 

    begin
        execute immediate
            'alter table gelec.ed_contratistas modify mail varchar(100 char)';
            
        commit;
        
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (2, 'Empresa 2','CDD2', 'centro_de_diagnostico@edenor.com', null); 
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (3, 'Empresa 3','CDD3', 'centro_de_diagnostico@edenor.com', null);
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (4, 'Empresa 4','CDD4', 'centro_de_diagnostico@edenor.com', null); 
        
        commit;
    exception
        when others then
            dbms_output.put_line('Se detecto error al modificar el proceso');
    end;        
    
end;

--select * from gelec.ed_contratistas;

