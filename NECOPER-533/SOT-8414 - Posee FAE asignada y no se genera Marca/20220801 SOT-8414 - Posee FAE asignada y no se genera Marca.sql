-- SOT-8414

--OBSERVACIONES

	--No se esta utilizando el log_hasta en GELEC.ED_FAE_CLIENTE

	--hay cuentas que tienen o tuvieron fae pero no tiene fecha de instalacion.
		select * from gelec.ed_fae_cliente where id_fae is not null and instalacion is null and retiro is not null;
		
	--hay registros que quedaron vacios ya que en otro registro se instalo la fae, pero en este vacio quedo como finalizado, deberia ser cancelado.
	--hay registros que fueron cancelados pero sigue seleccionada la fae 
 
		select 
		fc.*, 
		(select descripcion from gelec.ed_estado_fae where id=fc.id_estado) estado
		from gelec.ed_fae_cliente fc
		where 
			1=1
			and id_estado not in (1,2,8)
			and id not in (select id from gelec.ed_fae_cliente where id_fae is not null and instalacion is not null and retiro is null)
			and (fc.id_fae is null or fc.instalacion is null or fc.retiro is null)
		order by fc.cuenta, fc.id_estado
		;
	

	--hay cuentas que jamas estuvieron en el proceso de fae (gelec.ed_fae_cliente) sin embargo tiene marca de posee FAE.
		--clientes nunca fae con marca "posee fae"
		select * from gelec.ed_clientes c 
		where 
		  1=1
		  and cuenta not in (select cuenta from gelec.ed_fae_cliente)
		  and cuenta in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0);
	
	
	-- verificar clientes sin fae con marca posee fae
		--clientes nunca fae con marca posee fae
		select * 
		from gelec.ed_clientes c 
		where 
		  1=1
		  and cuenta not in (select cuenta from gelec.ed_fae_cliente)
		  and cuenta in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0);

		--query clientes ex fae, sin fae activa, con marca posee fae
		select * 
		from gelec.ed_fae_cliente 
		where 
		  1=1
		  and cuenta not in (select cuenta from gelec.ed_fae_cliente where id_fae is not null and instalacion is not null and retiro is null)
		  and cuenta in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0);
		  

	-- verificar clientes con fae sin marca posee fae
		select *
		from gelec.ed_fae_cliente 
		where 
			id_fae is not null 
			and instalacion is not null 
			and retiro is null
			and cuenta not in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0)


--OBSERVACIONES CON LAS ORDENES
	--deja crear la orden preventivo antes de instalar la de instalacion
	--deja crear una orden de instalacion habiendo otra finalizada
	--al crear la orden de instalacion, debe cambiar el estado a "pendiente de visita"
	
	

