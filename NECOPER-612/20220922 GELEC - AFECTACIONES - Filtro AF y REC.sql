SELECT 
  DC.ORIGEN,
		dc.ID_DOCUMENTO as idDocumento, 
		d.tipo_corte as tipoDocumento,
		d.NRO_DOCUMENTO as nroDocumento,
		dc.CUENTA,
		dc.CT_CLIE as CT,
		d.REGION, 
		d.ZONA,
		d.PARTIDO,
		d.LOCALIDAD,
		dc.ESTADO_CLIE as estado,
		dc.SOLUCION_PROVISORIA as provisorio,
		dc.FECHA_INICIO_CORTE as fechaInicio,
		dc.FECHA_FIN_CORTE as fechaFin,
		dc.FECHA_FIN_EDITABLE as fechaFinEditable,
		(SELECT COUNT (*) FROM GELEC.ED_CLIENTE_NOTA cn INNER JOIN gelec.ed_notas n ON cn.ID_NOTA = n.ID_NOTA WHERE cn.cuenta = dc.cuenta AND cn.ID_DOCUMENTO = dc.id_documento AND n.ID_TIPO_NOTA = 4) AS cantLlamados, 
		(SELECT COUNT (*) FROM GELEC.ED_CLIENTE_NOTA cn INNER JOIN gelec.ed_notas n ON cn.ID_NOTA = n.ID_NOTA WHERE cn.cuenta = dc.cuenta AND cn.ID_DOCUMENTO = dc.id_documento AND n.ID_TIPO_NOTA = 4 AND n.EFECTIVO = 1) AS cantEfectivos, 
		(SELECT COUNT (*) FROM GELEC.ED_RECLAMOS r WHERE r.ID_DOCUMENTO = dc.id_documento AND r.CUENTA = dc.cuenta) AS cantReclamos,
		(SELECT COUNT (*) FROM GELEC.ED_AUDITORIA a WHERE a.CUENTA = dc.cuenta AND a.ID_DOCUMENTO = dc.id_documento AND a.VALOR IN ('GE Puntual','GE CT','FAE','GE Propio')) AS asistido, 
		(select nvl(trunc(sum(trunc((fecha_fin_corte - fecha_inicio_corte) * 24 * 60, 0)),0),0) 
			from (select dc.cuenta,dc.ID_DOCUMENTO,dc.FECHA_INICIO_CORTE, CASE when dc.fecha_fin_corte is null then dc.FECHA_FIN_EDITABLE else dc.fecha_fin_corte END as fecha_fin_corte from GELEC.ED_DET_DOCUMENTOS_CLIENTES dc where dc.ORIGEN = 'AF' and (dc.FECHA_FIN_CORTE is not null or dc.FECHA_FIN_EDITABLE is not null))
			where id_documento = d.id_documento and cuenta = dc.cuenta) as sumatoria, 
		(select count(*) from GELEC.ED_DET_DOCUMENTOS_CLIENTES where cuenta = dc.cuenta and id_documento = dc.id_documento and origen = 'AF') as afectaciones 
From 
		GELEC.ED_DET_DOCUMENTOS_CLIENTES dc inner join GELEC.ED_DOCUMENTOS d on d.ID_DOCUMENTO = dc.ID_DOCUMENTO 
WHERE 
    1=1
--		and dc.FECHA_INICIO_CORTE BETWEEN TO_DATE (:fechaInicio, 'DD/MM/YYYY') AND TO_DATE (:fechaFin, 'DD/MM/YYYY') 
		and dc.FECHA_INICIO_CORTE = (select max(fecha_inicio_corte) from GELEC.ED_DET_DOCUMENTOS_CLIENTES dc2 where dc2.CUENTA = dc.CUENTA and dc2.ID_DOCUMENTO = dc.ID_DOCUMENTO) 
--		AND DC.ORIGEN = 'AF' 
    and d.nro_documento='D-22-08-002727'
ORDER BY 
		DC.FECHA_INICIO_CORTE DESC
