package com.edenor.GELEC;

public final class Queries {

	/*
	 * 
	 */
	public static final String GET_EDP_DOCUMENTS_MAIN_VIEW = "SELECT Id_Documento,\r\n" + 
			"       Nro_Documento,\r\n" + 
			"       Tipo_Corte,\r\n" + 
			"       Estado_Doc,\r\n" + 
			"       Fecha_Inicio_Doc,\r\n" + 
			"       Fecha_Fin_Doc,\r\n" + 
			"       Region,\r\n" + 
			"       Zona,\r\n" + 
			"       Partido,\r\n" + 
			"       Localidad,\r\n" + 
			"       NVL (\r\n" + 
			"          (SELECT TRUNC (MIN (SYSDATE - Dc.Fecha_Inicio_Corte) * 24)\r\n" + 
			"             FROM Gelec.Ed_Det_Documentos_Clientes Dc\r\n" + 
			"            WHERE     G.Id_Documento = Dc.Id_Documento\r\n" + 
			"                  AND Dc.Log_Hasta IS NULL\r\n" + 
			"                  AND Dc.Fecha_Fin_Corte IS NULL),\r\n" + 
			"          0)\r\n" + 
			"          Horas,\r\n" + 
			"       Id_Estado\r\n" + 
			"  FROM Gelec.Ed_Documentos G\r\n" + 
			" WHERE Log_Hasta IS NULL";

	/*
	 * Clients that belong to the document Add documentid at the end | query +
	 * getDocumentId
	 */
	public static final String GET_ASSOCIATED_CLIENTS_BY_DOCUMENT_NUMBER_MAIN_VIEW(String idDocumento) {
		return "/* Formatted on 21/9/2021 12:22:43 (QP5 v5.294) */\r\n"
				+ "SELECT DISTINCT\r\n"
				+ "       Dc.Ct_Clie,\r\n"
				+ "       Dc.Estado_Clie,\r\n"
				+ "       Dc.Solucion_Provisoria,\r\n"
				+ "       (SELECT Rr.Nombre\r\n"
				+ "          FROM Gelec.Ed_Reclamos Rr\r\n"
				+ "         WHERE     Rr.Cuenta = Dc.Cuenta\r\n"
				+ "               AND Rr.Id_Documento = Dc.Id_Documento\r\n"
				+ "               AND Rr.Fecha_Creacion_Cliente =\r\n"
				+ "                      NVL (\r\n"
				+ "                         (SELECT MIN (Rr.Fecha_Creacion_Cliente)\r\n"
				+ "                            FROM Gelec.Ed_Reclamos Rr\r\n"
				+ "                           WHERE     Rr.Cuenta = Dc.Cuenta\r\n"
				+ "                                 AND Rr.Id_Documento = Dc.Id_Documento\r\n"
				+ "                                 AND Rr.Fecha_Cierre IS NULL),\r\n"
				+ "                         (SELECT MAX (Rr.Fecha_Creacion_Cliente)\r\n"
				+ "                            FROM Gelec.Ed_Reclamos Rr\r\n"
				+ "                           WHERE     Rr.Cuenta = Dc.Cuenta\r\n"
				+ "                                 AND Rr.Id_Documento = Dc.Id_Documento))\r\n"
				+ "               AND ROWNUM = 1)\r\n"
				+ "          Reclamo_Nombre,\r\n"
				+ "       (SELECT MIN (Rr.Fecha_Creacion_Cliente)\r\n"
				+ "          FROM Gelec.Ed_Reclamos Rr\r\n"
				+ "         WHERE     Rr.Cuenta = Dc.Cuenta\r\n"
				+ "               AND Rr.Id_Documento = Dc.Id_Documento\r\n"
				+ "               AND Rr.Fecha_Cierre IS NULL)\r\n"
				+ "          Reclamo_Fecha_Creacion_Cliente,\r\n"
				+ "       C.Cuenta,\r\n"
				+ "       C.En_Tramite,\r\n"
				+ "       Dc.Fecha_Inicio_Corte,\r\n"
				+ "       (SELECT COUNT (*)\r\n"
				+ "          FROM Gelec.Ed_Contactos_Clientes Cc\r\n"
				+ "         WHERE Cc.Cuenta = C.Cuenta)\r\n"
				+ "          Tiene_Telefono,\r\n"
				+ "       Dc.Fecha_Fin_Corte,\r\n"
				+ "       (SELECT COUNT (*)\r\n"
				+ "          FROM GELEC.ED_FAE_CLIENTE fc\r\n"
				+ "         WHERE     fc.CUENTA = C.cuenta\r\n"
				+ "               AND fc.instalacion IS NOT NULL\r\n"
				+ "               AND fc.RETIRO IS NULL)\r\n"
				+ "          poseeFAE,\r\n"
				+ "       (SELECT COUNT (*)\r\n"
				+ "          FROM GELEC.ED_MARCA_CLIENTE mc\r\n"
				+ "         WHERE     mc.CUENTA = C.cuenta\r\n"
				+ "               AND mc.ID_SUBMARCA = 17\r\n"
				+ "               AND mc.LOG_HASTA IS NULL)\r\n"
				+ "          poseeAMI\r\n"
				+ "  FROM Gelec.Ed_Documentos              D,\r\n"
				+ "       Gelec.Ed_Det_Documentos_Clientes Dc,\r\n"
				+ "       Gelec.Ed_Clientes                C\r\n"
				+ " WHERE     D.Id_Documento = Dc.Id_Documento\r\n"
				+ "       AND C.Cuenta = Dc.Cuenta\r\n"
				+ "       AND D.Log_Hasta IS NULL\r\n"
				+ "       AND Dc.Log_Hasta IS NULL\r\n"
				+ "       AND C.Log_Hasta IS NULL\r\n"
				+ "       AND D.Id_Documento = " + idDocumento;
	}

	public static final String GET_ASSOCIATED_CLIENTS_MULTIPLE_VIEW(String idDocumento) {
		return "SELECT Dc.Ct_Clie,\r\n" + 
				"       Dc.Estado_Clie,\r\n" + 
				"       Dc.Solucion_Provisoria,\r\n" + 
				"       C.Cuenta,\r\n" + 
				"       Dc.Id_Doc_Cliente,\r\n" + 
				"       Dc.Fecha_Fin_Corte,\r\n" + 
				"       Dc.FECHA_FIN_EDITABLE,\r\n" + 
				"       C.RAZON_SOCIAL\r\n" + 
				"  FROM Gelec.Ed_Det_Documentos_Clientes Dc,\r\n" + 
				"       Gelec.Ed_Clientes                C,\r\n" + 
				"       Gelec.Ed_Documentos              D\r\n" + 
				" WHERE     D.Id_Documento = Dc.Id_Documento\r\n" + 
				"       AND C.Cuenta = Dc.Cuenta\r\n" + 
				"       AND Dc.Log_Hasta IS NULL\r\n" + 
				"       AND D.Id_Documento = " + idDocumento;
	}

	public static final String GET_ALERTS = "SELECT N.Id_Nota,\r\n" + 
			"       N.Observaciones,\r\n" + 
			"       N.Fechaalerta,\r\n" + 
			"       Cn.Cuenta,\r\n" + 
			"       Tp.Descripcion\r\n" + 
			"  FROM Gelec.Ed_Notas N, Gelec.Ed_Cliente_Nota Cn, Gelec.Ed_Tipo_Nota Tp\r\n" + 
			" WHERE     N.Log_Hasta IS NULL\r\n" + 
			"       AND Cn.Log_Hasta IS NULL\r\n" + 
			"       AND N.Fechaalerta IS NOT NULL\r\n" + 
			"       AND N.Fechaalerta < SYSDATE\r\n" + 
			"       AND N.Id_Tipo_Nota IN (3, 6)\r\n" + 
			"       AND N.Id_Tipo_Nota = Tp.Id_Tipo_Nota\r\n" + 
			"       AND N.Id_Nota = Cn.Id_Nota(+)";

	public static final String VERIFY_NOTE_EXISTS(String idNota) {
		return "SELECT COUNT(*)\r\n" + "FROM GELEC.ED_NOTAS N\r\n" + "WHERE N.LOG_HASTA IS NULL\r\n" + "AND N.ID_NOTA = "
				+ "'" + idNota + "'";
	}

	public static final String GET_LISTA_LOCALIDADES(String partido) {
		return "SELECT AM.AREANAME\r\n" + "  FROM GELEC.ED_PARTIDO_ZONA PZ, GELEC.ED_AMAREAS AM\r\n"
				+ " WHERE AM.SUPERAREA = PZ.AREAID AND upper(PZ.PARTIDO) = '" + partido + "'";
	}

	public static final String GET_ZONA_FROM_PARTIDO(String partido) {
		return "SELECT ZONA\r\n" + "  FROM GELEC.ED_PARTIDO_ZONA\r\n" + " WHERE upper(PARTIDO) = upper('" + partido + "')";
	}
	public static final String GET_LISTA_DOCUMENTOS_ACTIVOS_MIGRACION(String nroDocumento) {
		return "SELECT D.ID_DOCUMENTO, D.NRO_DOCUMENTO\r\n" + 
				"FROM GELEC.ED_DOCUMENTOS D\r\n" + 
				"WHERE D.LOG_HASTA IS NULL\r\n" + 
				"AND D.NRO_DOCUMENTO != '" + nroDocumento + "'";
	}

	public static final String GET_ALERT_LIST = "SELECT N.OBSERVACIONES,\r\n" + 
			"         N.FECHAALERTA,\r\n" + 
			"         CN.CUENTA,\r\n" + 
			"         D.NRO_DOCUMENTO,\r\n" + 
			"         L.FECHA      AS FECHA_GESTION,\r\n" + 
			"         N.ID_NOTA,\r\n" + 
			"         TN.DESCRIPCION AS TIPO,\r\n" + 
			"         SN.DESCRIPCION AS SUBTIPO,\r\n" + 
			"         N.USUARIO,\r\n" + 
			"         NULL\r\n" + 
			"    FROM GELEC.ED_NOTAS      N,\r\n" + 
			"         GELEC.ED_CLIENTE_NOTA CN,\r\n" + 
			"         GELEC.ED_DOCUMENTOS D,\r\n" + 
			"         GELEC.ED_LOG        L,\r\n" + 
			"         GELEC.ED_TIPO_NOTA  TN,\r\n" + 
			"         GELEC.ED_SUBTIPO_NOTA SN\r\n" + 
			"   WHERE     N.FECHAALERTA IS NOT NULL\r\n" + 
			"         AND N.ID_NOTA = CN.ID_NOTA(+)\r\n" + 
			"         AND CN.ID_DOCUMENTO = D.ID_DOCUMENTO(+)\r\n" + 
			"         AND N.LOG_HASTA = L.LOG_ID(+)\r\n" + 
			"         AND N.ID_TIPO_NOTA = TN.ID_TIPO_NOTA\r\n" + 
			"         AND N.ID_SUBTIPO_NOTA = SN.ID(+)\r\n" + 
			"         AND CN.LOG_HASTA IS NULL\r\n" + 
			"ORDER BY N.ID_NOTA DESC";

	public static final String GET_ALERTS_FOR_EMAIL = "  SELECT N.Observaciones,\r\n" + 
			"         N.Fechaalerta,\r\n" + 
			"         Cn.Cuenta,\r\n" + 
			"         D.Nro_Documento,\r\n" + 
			"         NULL         AS Fecha_Gestion,\r\n" + 
			"         N.Id_Nota,\r\n" + 
			"         Tn.Descripcion AS Tipo,\r\n" + 
			"         Sn.Descripcion AS Subtipo,\r\n" + 
			"         N.Usuario,\r\n" + 
			"         NULL\r\n" + 
			"    FROM Gelec.Ed_Notas      N,\r\n" + 
			"         Gelec.Ed_Cliente_Nota Cn,\r\n" + 
			"         Gelec.Ed_Documentos D,\r\n" + 
			"         Gelec.Ed_Tipo_Nota  Tn,\r\n" + 
			"         Gelec.Ed_Subtipo_Nota Sn\r\n" + 
			"   WHERE     N.Fechaalerta IS NOT NULL\r\n" + 
			"         AND N.Id_Nota = Cn.Id_Nota(+)\r\n" + 
			"         AND Cn.Id_Documento = D.Id_Documento(+)\r\n" + 
			"         AND Tn.Id_Tipo_Nota = N.Id_Tipo_Nota\r\n" + 
			"         AND Sn.Id = N.Id_Subtipo_Nota\r\n" + 
			"         AND N.Id_Tipo_Nota IN (2, 5)\r\n" + 
			"         AND N.Log_Hasta IS NULL\r\n" + 
			"         AND N.Fechaalerta < SYSDATE\r\n" + 
			"ORDER BY N.Id_Nota DESC";

	public static final String GET_ALERTS_FOR_SUPERVISOR_EMAIL = "SELECT N.OBSERVACIONES,\r\n" + 
			"         N.FECHAALERTA,\r\n" + 
			"         CN.CUENTA,\r\n" + 
			"         D.NRO_DOCUMENTO,\r\n" + 
			"         NULL,\r\n" +
			"         N.ID_NOTA,\r\n" + 
			"         TN.DESCRIPCION AS TIPO,\r\n" + 
			"         SN.DESCRIPCION AS SUBTIPO,\r\n" + 
			"         N.USUARIO,\r\n" + 
			"         N.REITERACIONES_EMAIL\r\n" + 
			"    FROM GELEC.ED_NOTAS      N,\r\n" + 
			"         GELEC.ED_CLIENTE_NOTA CN,\r\n" + 
			"         GELEC.ED_DOCUMENTOS D,\r\n" + 
			"         GELEC.ED_TIPO_NOTA  TN,\r\n" + 
			"         GELEC.ED_SUBTIPO_NOTA SN\r\n" + 
			"   WHERE     N.FECHAALERTA IS NOT NULL\r\n" + 
			"         AND N.ID_NOTA = CN.ID_NOTA(+)\r\n" + 
			"         AND CN.ID_DOCUMENTO = D.ID_DOCUMENTO(+)\r\n" + 
			"         AND TN.ID_TIPO_NOTA = N.ID_TIPO_NOTA\r\n" + 
			"         AND SN.ID = N.ID_SUBTIPO_NOTA\r\n" + 
			"         AND N.ID_TIPO_NOTA IN (2, 5)\r\n" + 
			"         AND N.LOG_HASTA IS NULL\r\n" + 
			"         AND N.FECHAALERTA > SYSDATE\r\n" + 
			"ORDER BY N.REITERACIONES_EMAIL ASC, N.FECHAALERTA ASC";

	/*
	 * Add documentid at the end | query + getDocumentId
	 */
	public static final String GET_EDP_DOCUMENT_BY_ID(String idDocumento) {
		return "SELECT G.ID_DOCUMENTO,\r\n" + 
				"       G.NRO_DOCUMENTO,\r\n" + 
				"       G.TIPO_CORTE,\r\n" + 
				"       G.FECHA_INICIO_DOC,\r\n" + 
				"       G.FECHA_FIN_DOC,\r\n" + 
				"       G.LOG_HASTA,\r\n" + 
				"       G.REGION,\r\n" + 
				"       G.PARTIDO,\r\n" + 
				"       G.ESTADO_DOC,\r\n" + 
				"       G.ID_ESTADO,\r\n" + 
				"       G.ZONA\r\n" + 
				"  FROM GELEC.ED_DOCUMENTOS G\r\n" + 
				" WHERE G.ID_DOCUMENTO = " + idDocumento;
	}

	public static final String GET_EDP_DOCUMENT_BY_NAME(String idDocumento) {
		return "SELECT ID_DOCUMENTO\r\n" + 
				"  FROM GELEC.ED_DOCUMENTOS g\r\n" + 
				" WHERE g.NRO_DOCUMENTO = '" + idDocumento + "'";
	}

	public static final String GET_EDP_DOCUMENT_BY_NAME_FROM_GELEC(String nroDocumento) {
		return "SELECT d.ID_DOCUMENTO,\r\n" + "       d.NRO_DOCUMENTO,\r\n" + "       d.TIPO_CORTE,\r\n"
				+ "       d.FECHA_INICIO_DOC,\r\n" + "       d.FECHA_FIN_DOC,\r\n" + "       d.ANOMALIA,\r\n"
				+ "       d.AVISO_ANOMALIA,\r\n" + "       d.LOG_HASTA\r\n" + "  FROM GELEC.ED_DOCUMENTOS d\r\n"
				+ " WHERE d.NRO_DOCUMENTO = " + "'" + nroDocumento + "'";
	}

	public static final String GET_CLIENT_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT\r\n" + 
				"        CUENTA,\r\n" + 
				"        CT,\r\n" + 
				"        CALLE,\r\n" + 
				"        NRO,\r\n" + 
				"        LOCALIDAD,\r\n" + 
				"        PARTIDO,\r\n" + 
				"        REGION,\r\n" + 
				"        RAZON_SOCIAL, \r\n" + 
				"        PISO_DPTO\r\n" + 
				"    FROM\r\n" + 
				"        GELEC.ED_CLIENTES   \r\n" + 
				"    WHERE\r\n" + 
				"        CUENTA = '" + cuenta + "'";
	}

	public static final String GET_HISTORIC_DOCUMENTS_BY_ACCOUNT_NUMBER(String cuenta) {
		return "Select D.Nro_Documento,\r\n" + 
				"       Dc.Log_Desde,\r\n" + 
				"       Dc.Log_Hasta,\r\n" + 
				"       D.Tipo_Corte,\r\n" + 
				"       Dc.Fecha_Inicio_Corte As Fecha_Inicio,\r\n" + 
				"       Dc.Fecha_Fin_Corte    As Fecha_Fin,\r\n" + 
				"       D.Estado_Doc, \r\n" + 
				"       Dc.Origen\r\n" + 
				"  From Gelec.Ed_Det_Documentos_Clientes Dc, Gelec.Ed_Documentos D\r\n" + 
				" Where Dc.Id_Documento = D.Id_Documento And Dc.Cuenta = '" + cuenta + "'\r\n"
						+ "order by fecha_inicio desc";
	}

	public static final String SEARCH_ANOMALIES_BY_DOCUMENT_ID(String idDocumento) {
		return "SELECT DA.ID, DA.NOTA\r\n" + 
				"  FROM GELEC.ED_DOCUMENTO_ANOMALIA DA\r\n" + 
				" WHERE DA.ID_DOCUMENTO = " + idDocumento;
	}

	public static final String GET_CLIENT_CONTACT_LIST_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT CC.ID_TEL, CC.TELEFONO, CC.TIPO_CONTACTO, CC.NOMBRE\r\n" + 
				"FROM GELEC.ED_CONTACTOS_CLIENTES CC\r\n" + 
				"WHERE CC.CUENTA = '" + cuenta + "'\r\n" + 
				"AND CC.LOG_HASTA IS NULL";
	}

	public static final String GET_CLIENT_NUMBER_LIST_BY_ACCOUNT_NUMBER(String cuenta) {
		return "select cc.TELEFONO\r\n" + "from GELEC.ED_CONTACTOS_CLIENTES cc\r\n" + "where cc.CUENTA = " + "'" + cuenta
				+ "'";
	}

	public static final String GET_NOTES_BY_CONTACT_ID(String idDestino) {
		return "SELECT N.EFECTIVO\r\n" + "FROM GELEC.ED_NOTAS N\r\n" + "WHERE N.EFECTIVO IS NOT NULL\r\n"
				+ "AND N.IDDESTINO = " + "'" + idDestino + "'";
	}

	public static final String VERIFY_ACCOUNT_EXISTS(String cuenta) {
		return "SELECT COUNT(*) \r\n" + "FROM GELEC.ED_CLIENTES C\r\n" + "WHERE C.LOG_HASTA IS NULL   \r\n"
				+ "AND C.CUENTA = '" + cuenta + "'";
	}

	public static final String VERIFY_DOCUMENT_NUMBER_EXISTS(String nroDocumento) {
		return "SELECT COUNT(*)\r\n" + "FROM GELEC.ED_DOCUMENTOS D\r\n" + "WHERE D.LOG_HASTA IS NULL \r\n"
				+ "AND D.NRO_DOCUMENTO = " + "'" + nroDocumento + "'";
	}

	public static final String GET_DOCUMENT_ID_FROM_NUMBER(String nroDocumento) {
		return "select d.ID_DOCUMENTO\r\n" + "from GELEC.ED_DOCUMENTOS d\r\n" + "where rownum = 1 \r\n"
				+ "and d.NRO_DOCUMENTO = '" + nroDocumento + "'";
	}

	public static final String GET_DOCUMENT_ID_FROM_NOTE_ID(String idNota) {
		return "SELECT CN.ID_DOCUMENTO\r\n" + "FROM GELEC.ED_CLIENTE_NOTA CN\r\n" + "WHERE ROWNUM = 1 \r\n"
				+ "AND CN.ID_NOTA = " + "'" + idNota + "'";
	}

	public static final String GET_MARK_REVISION_RED(String cuenta) {
		return "SELECT MC.ID_MARCA, MC.ID_SUBMARCA \r\n" + "FROM GELEC.ED_MARCA_CLIENTE MC\r\n"
				+ "WHERE MC.ID_MARCA = '5'\r\n" + "AND MC.LOG_HASTA IS NULL\r\n" + "AND MC.CUENTA = " + "'" + cuenta + "'";
	}

	public static final String GET_MARK_CLIENTE(String cuenta) {
		return "SELECT MC.ID_MARCA, MC.ID_SUBMARCA \r\n" + "FROM GELEC.ED_MARCA_CLIENTE MC\r\n"
				+ "WHERE MC.ID_MARCA = '4'\r\n" + "AND MC.LOG_HASTA IS NULL\r\n" + "AND MC.CUENTA = " + "'" + cuenta + "'";
	}

	public static final String GET_NOTES_QUANTITY_BY_ACCOUNT_NUMBER(String cuenta, String documentId) {
		return "SELECT COUNT (*)\r\n" + "  FROM GELEC.ED_NOTAS N, GELEC.ED_CLIENTE_NOTA CN\r\n"
				+ " WHERE     N.EFECTIVO IS NOT NULL\r\n" + "       AND CN.ID_NOTA = N.ID_NOTA\r\n" + "       AND CN.CUENTA = "
				+ "'" + cuenta + "'" + "\r\n" + "       AND CN.ID_DOCUMENTO = " + "'" + documentId + "'";
	}

	public static String GET_MARKS_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT ID_MARCA, ID_SUBMARCA\r\n" + "  FROM GELEC.ED_MARCA_CLIENTE\r\n"
				+ " WHERE LOG_HASTA IS NULL AND ID_MARCA != 5 AND ID_MARCA != 4 AND CUENTA = " + "'" + cuenta + "'" + "\r\n"
				+ " order by 1";
	}

	public static String GET_ALL_CONTACTS_BY_CLIENT_ACCOUNT_NUMBER(String cuenta) {

		return "SELECT DISTINCT N.ID_NOTA,\r\n" + 
				"                  CN.CUENTA,\r\n" + 
				"                  N.USUARIO,\r\n" + 
				"                  TN.DESCRIPCION,\r\n" + 
				"                  N.FECHAHORA,\r\n" + 
				"                  N.EFECTIVO,\r\n" + 
				"                  N.OBSERVACIONES,\r\n" + 
				"                  (select cc.telefono \r\n" + 
				"                  from GELEC.ED_CONTACTOS_CLIENTES cc\r\n" + 
				"                  where tn.descripcion = 'Cliente'\r\n" + 
				"                  and cc.ID_TEL = n.IDDESTINO) as telefono,\r\n" + 
				"                  D.NRO_DOCUMENTO,\r\n"
				+ "        (select a.TELEFONO\r\n" + 
				"        from GELEC.ED_AGENDA a\r\n" + 
				"        where a.ID_AGENDA = n.IDDESTINO) telefono_interno " + 
				"    FROM GELEC.ED_NOTAS            N,\r\n" + 
				"         GELEC.ED_CLIENTE_NOTA     CN,\r\n" + 
				"         GELEC.ED_TIPO_NOTA        TN,\r\n" + 
				"         GELEC.ED_DOCUMENTOS       D\r\n" + 
				"   WHERE     N.ID_TIPO_NOTA = TN.ID_TIPO_NOTA\r\n" + 
				"         AND N.ID_NOTA = CN.ID_NOTA\r\n" + 
				"         AND CN.CUENTA = '" + cuenta + "'\r\n" + 
				"         AND CN.ID_DOCUMENTO = D.ID_DOCUMENTO(+)\r\n" + 
				"         AND CN.LOG_HASTA IS NULL\r\n" + 
				"ORDER BY N.ID_NOTA DESC";
	}

	public static String GET_ALL_CURRENT_CONTACTS_BY_CLIENT_ACCOUNT_NUMBER(String cuenta) {

		return "SELECT DISTINCT N.ID_NOTA,\r\n" + 
				"                  CN.CUENTA,\r\n" + 
				"                  N.USUARIO,\r\n" + 
				"                  TN.DESCRIPCION,\r\n" + 
				"                  N.FECHAHORA,\r\n" + 
				"                  N.EFECTIVO,\r\n" + 
				"                  N.OBSERVACIONES,\r\n" + 
				"                  (select cc.telefono \r\n" + 
				"                  from GELEC.ED_CONTACTOS_CLIENTES cc\r\n" + 
				"                  where tn.descripcion = 'Cliente'\r\n" + 
				"                  and cc.ID_TEL = n.IDDESTINO) as telefono,\r\n" + 
				"                  D.NRO_DOCUMENTO,\r\n"
				+ "        (select a.TELEFONO\r\n" + 
				"        from GELEC.ED_AGENDA a\r\n" + 
				"        where a.ID_AGENDA = n.IDDESTINO) telefono_interno " + 
				"    FROM GELEC.ED_NOTAS            N,\r\n" + 
				"         GELEC.ED_CLIENTE_NOTA     CN,\r\n" + 
				"         GELEC.ED_TIPO_NOTA        TN,\r\n" + 
				"         GELEC.ED_DOCUMENTOS       D\r\n" + 
				"   WHERE     N.ID_TIPO_NOTA = TN.ID_TIPO_NOTA\r\n" + 
				"         AND N.ID_NOTA = CN.ID_NOTA\r\n" + 
				"         AND CN.CUENTA = '" + cuenta + "'\r\n" + 
				"         AND CN.ID_DOCUMENTO = D.ID_DOCUMENTO(+)\r\n" + 
				"         AND CN.LOG_HASTA IS NULL\r\n" + 
				"ORDER BY N.ID_NOTA DESC";
	}

	public static String GET_ALL_CLAIMS_BY_CLIENT_ACCOUNT_NUMBER(String cuenta) {
		return "Select R.Nombre, R.Fecha_Creacion_Cliente, R.Fecha_Cierre, Tr.Description\r\n" + 
				"    From Gelec.Ed_Reclamos R, Gelec.Ed_Tipo_Reclamo Tr\r\n" + 
				"   Where R.Cuenta = '" + cuenta + "'\r\n" + 
				"   And R.Id_Tipo_Reclamo = Tr.Id\r\n" + 
				"Order By 2 desc";
	}

	public static String GET_REITERACIONES_BY_CLIENT_ACCOUNT_NUMBER_AND_DOCUMENT_ID(String cuenta, String documentId) {
		return "SELECT SUM(nvl(r.reiteraciones,0)) + COUNT(r.NOMBRE) as total\r\n" + "      from GELEC.ED_RECLAMOS r\r\n"
				+ "      where r.ID_DOCUMENTO = " + "'" + documentId + "'" + "\r\n" + "      and r.CUENTA = " + "'" + cuenta + "'";
	}

	public static String GET_EDENOR_CONTACTS_BY_REGION_PARTIDO(String region, String partido) {
		return "SELECT Id_Agenda,\r\n" + 
				"       Cargo,\r\n" + 
				"       Telefono,\r\n" + 
				"       Partido\r\n" + 
				"  FROM Gelec.Ed_Agenda A\r\n" + 
				" WHERE Region = '" + region + "' AND UPPER (Partido) = UPPER ('" + partido + "')\r\n" + 
				"UNION\r\n" + 
				"SELECT Id_Agenda,\r\n" + 
				"       Cargo,\r\n" + 
				"       Telefono,\r\n" + 
				"       Partido\r\n" + 
				"  FROM Gelec.Ed_Agenda A\r\n" + 
				" WHERE Region = '" + region + "' AND Cargo LIKE 'RYCA%'";
	}

	public static final String GET_EDENOR_CONTACTS = "SELECT *\r\n" + "FROM GELEC.ED_AGENDA\r\n"
			+ "WHERE LOG_HASTA IS NULL";

	public static String GET_LAST_CONTACT_DATE_AND_USERNAME(String cuenta, String documentId) {
		return "SELECT n.USUARIO, n.FECHAHORA, n.EFECTIVO\r\n" + "  FROM GELEC.ED_NOTAS n, GELEC.ED_CLIENTE_NOTA cn\r\n"
				+ " WHERE     n.ID_NOTA = cn.ID_NOTA\r\n" + "       AND cn.ID_NOTA =\r\n"
				+ "              (SELECT MAX (cnn.id_nota)\r\n"
				+ "                 FROM GELEC.ED_NOTAS nn, GELEC.ED_CLIENTE_NOTA cnn\r\n"
				+ "                WHERE     cnn.CUENTA = '" + cuenta + "'" + "\r\n"
				+ "                      AND cnn.ID_NOTA = nn.ID_NOTA\r\n" + "                      AND cnn.ID_DOCUMENTO = '"
				+ documentId + "'" + "\r\n" + "                      AND nn.ID_TIPO_NOTA = 4\r\n"
				+ "                      AND nn.EFECTIVO = 1)";
	}

	public static String GET_LAST_CLAIM_REITERATION(String cuenta, String documentId) {
		return "select max(r.ULTIMA_REITERACION)\r\n" + "from GELEC.ED_RECLAMOS r\r\n" + "where r.CUENTA = " + cuenta
				+ "\r\n" + "and r.ID_DOCUMENTO = '" + documentId + "'" + "\r\n";
	}

	public static String GET_PACIENTE_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT pc.NOMBRE, pc.APELLIDO, pc.DNI, pc.DIAGNOSTICO_PRINCIPAL, pc.ESTADIO_ENFERMEDAD, pc.RIESGO_CORTE, pc.INICIO_RECS, pc.FIN_RECS\r\n"
				+ "from GELEC.ED_PACIENTE_CLIENTE pc\r\n" + "where pc.LOG_HASTA IS NULL \r\n" + "AND pc.CUENTA = '" + cuenta + "'";
	}

	public static String GET_ARTEFACTOS_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT A.DESCRIPCION, TA.VALOR, A.ID_APARATO, A.POT_PROM, A.POT_MAX\r\n" + "  FROM GELEC.ED_CLIENTE_ARTEFACTO CA,\r\n"
				+ "       GELEC.ED_ARTEFACTOS        A,\r\n" + "       GELEC.ED_TIEMPO_ARTEFACTOS TA\r\n"
				+ " WHERE     CA.ID_APARATO = A.ID_APARATO\r\n" + "       AND CA.ID_TIEMPO = TA.ID\r\n"
				+ "       AND A.ID_TIPO = 1\r\n" + "       AND CA.LOG_HASTA IS NULL\r\n" + "       AND CA.CUENTA = '" + cuenta + "'\r\n"
				+ "ORDER BY A.DESCRIPCION";
	}

	public static String GET_ACCESORIOS_BY_ACCOUNT_NUMBER(String cuenta) {
		return "SELECT A.DESCRIPCION, TA.VALOR, A.ID_APARATO, a.pot_prom, a.pot_max\r\n" + "  FROM GELEC.ED_CLIENTE_ARTEFACTO CA,\r\n"
				+ "       GELEC.ED_ARTEFACTOS        A,\r\n" + "       GELEC.ED_TIEMPO_ARTEFACTOS TA\r\n"
				+ " WHERE     CA.ID_APARATO = A.ID_APARATO\r\n" + "       AND CA.ID_TIEMPO = TA.ID\r\n"
				+ "       AND A.ID_TIPO = 2\r\n" + "       AND CA.LOG_HASTA IS NULL\r\n" + "       AND CA.CUENTA = '" + cuenta + "'\r\n"
				+ "ORDER BY A.DESCRIPCION";
	}

	public static final String GET_APARATOLOGIA_LIST_FROM_DB = "SELECT A.ID_APARATO, A.DESCRIPCION, A.ID_TIPO, a.pot_prom, a.pot_max\r\n"
			+ "  FROM GELEC.ED_ARTEFACTOS A\r\n" + "  WHERE A.LOG_HASTA IS NULL\r\n" + "ORDER BY 1";

	public static final String GET_ARTIFACT_LIST_FROM_DB = "SELECT A.ID_APARATO, A.DESCRIPCION, A.POT_PROM, A.POT_MAX\r\n"
			+ "  FROM GELEC.ED_ARTEFACTOS A\r\n" + " WHERE A.ID_TIPO = 1\r\n" + " AND A.LOG_HASTA IS NULL ORDER BY A.DESCRIPCION";

	public static final String GET_ACCESORY_LIST_FROM_DB = "SELECT A.ID_APARATO, A.DESCRIPCION\r\n"
			+ "  FROM GELEC.ED_ARTEFACTOS A\r\n" + " WHERE A.ID_TIPO = 2\r\n" + " AND A.LOG_HASTA IS NULL ORDER BY A.DESCRIPCION";
	
	public static final String GET_DOCUMENT_LIST_FROM_DB = "SELECT A.ID_APARATO, A.DESCRIPCION, A.POT_PROM, A.POT_MAX\r\n"
			+ "  FROM GELEC.ED_ARTEFACTOS A\r\n" + " WHERE A.ID_TIPO = 3\r\n" + " AND A.LOG_HASTA IS NULL ORDER BY A.DESCRIPCION";

	public static final String GET_TIME_LIST_FROM_DB = "SELECT TA.ID, TA.VALOR\r\n"
			+ "  FROM GELEC.ED_TIEMPO_ARTEFACTOS TA";

	public static final String GET_DICTIONARY = "SELECT DA.ID AS ID_PALABRA, A.ID_APARATO, A.DESCRIPCION AS ARTEFACTO, DA.DESCRIPCION AS PALABRA\r\n"
			+ "FROM GELEC.ED_DICCIONARIO_APARATOLOGIA DA, GELEC.ED_ARTEFACTOS A\r\n"
			+ "WHERE DA.ID_APARATOLOGIA = A.ID_APARATO\r\n" + "AND DA.LOG_HASTA IS NULL\r\n" + "AND A.LOG_HASTA IS NULL\r\n"
			+ "ORDER BY 1";

	public static String COUNT_PACIENTE(String cuenta, String dni) {
		return "SELECT COUNT(*)\r\n" + "FROM GELEC.ED_PACIENTE_CLIENTE PC\r\n" + "WHERE PC.LOG_HASTA IS NULL\r\n"
				+ "AND PC.CUENTA = '" + cuenta + "'\r\n" + "AND PC.DNI = '" + dni + "'";
	}

	public static String SEARCH_DNI_OTHER_ACCOUNTS(String cuenta, String dni) {
		return "SELECT COUNT(*)\r\n" + "FROM GELEC.ED_PACIENTE_CLIENTE PC\r\n" + "WHERE PC.LOG_HASTA IS NULL\r\n"
				+ "AND PC.CUENTA != '" + cuenta + "'\r\n" + "AND PC.DNI = '" + dni + "'";
	}

	public static final String COUNT_PACIENTES_BY_ACCOUNT(String cuenta) {return "SELECT COUNT(*)\r\n"
			+ "FROM GELEC.ED_PACIENTE_CLIENTE PC\r\n" + "WHERE PC.LOG_HASTA IS NULL\r\n" + "AND PC.CUENTA = '" + cuenta + "'";
}

	public static String GET_ORIGEN_FECHA_PACIENTE(String cuenta, String dni) {
		return "SELECT PC.ORIGEN, PC.FECHA_CENSADO, PC.LOTE\r\n" + "FROM GELEC.ED_PACIENTE_CLIENTE PC\r\n"
				+ "WHERE PC.LOG_HASTA IS NULL \r\n" + "AND PC.DNI = '" + dni + "'\r\n" + "AND PC.CUENTA = '" + cuenta + "'";
	}
	
	public static String GET_COUNT_MULTIPLE_CLIENTE(String cuenta) {
		return "SELECT COUNT(*)\r\n" + 
				"FROM GELEC.ED_MARCA_CLIENTE MC\r\n" + 
				"WHERE MC.CUENTA = '" + cuenta + "'\r\n" + 
				"AND MC.ID_SUBMARCA = '21'\r\n" +
				"AND MC.LOG_HASTA IS NULL";
	}
	
	public static String GET_COUNT_DISPOSICION(String cuenta, String disposicion) {
		return "SELECT COUNT(*)\r\n" + 
				"FROM GELEC.ED_PACIENTE_CLIENTE PC\r\n" + 
				"WHERE PC.CUENTA = '" + cuenta + "'\r\n" + 
				"AND PC.DISPOSICION = '" + disposicion + "'";
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// REPORTES
	public static String DATOS_REGION_DTO(String region) {
		return "Select\r\n" + 
				"        D.Nro_Documento,\r\n" + 
				"        Dc.Cuenta,\r\n" + 
				"        R.Nombre,\r\n" + 
				"        C.Ct,\r\n" + 
				"        D.Tipo_Corte,\r\n" + 
				"        Dc.Estado_Clie,\r\n" + 
				"        D.Zona,\r\n" + 
				"        C.Razon_Social,\r\n" + 
				"        C.Calle,\r\n" + 
				"        C.Nro,\r\n" + 
				"        C.Localidad,\r\n" + 
				"        Dc.Origen,\r\n" + 
				"        Dc.ID_DOC_CLIENTE    \r\n" + 
				"    From\r\n" + 
				"        Gelec.Ed_Det_Documentos_Clientes Dc,\r\n" + 
				"        Gelec.Ed_Documentos              D,\r\n" + 
				"        Gelec.Ed_Reclamos                R,\r\n" + 
				"        Gelec.Ed_Clientes                C   \r\n" + 
				"    Where\r\n" + 
				"        Dc.Id_Documento = D.Id_Documento         \r\n" + 
				"        And Dc.Cuenta = C.Cuenta         \r\n" + 
				"        And Dc.Cuenta = R.Cuenta(+)         \r\n" + 
				"        And Dc.Id_Documento = R.Id_Documento(+)         \r\n" + 
				"        And D.Region = " + region + "\r\n" + 
				"        And D.Log_Hasta Is Null\r\n" +
				"        And UPPER(Dc.Estado_Clie) != 'NORMALIZADO'";
	}
	
	public static String DATOS_CORTE_DTO(String idDocumento) {
		return "SELECT D.NRO_DOCUMENTO,\r\n" + 
				"       D.TIPO_CORTE,\r\n" + 
				"       D.ESTADO_DOC,\r\n" + 
				"       D.FECHA_INICIO_DOC,\r\n" + 
				"       D.FECHA_FIN_DOC,\r\n" +
				"       D.ZONA,\r\n" +
				"       D.REGION\r\n" +
				"  FROM GELEC.ED_DOCUMENTOS D\r\n" + 
				" WHERE D.ID_DOCUMENTO = '" + idDocumento + "'";
	}
	
	public static String DATOS_CLIENTE_DTO(String idDetalleCliente) {
		return "Select Dc.Cuenta,\r\n" + 
				"       C.Razon_Social,\r\n" + 
				"       C.Calle,\r\n" + 
				"       C.Nro,\r\n" + 
				"       C.Localidad,\r\n" + 
				"       C.Partido,\r\n" + 
				"       C.Ct,\r\n" + 
				"       Dc.Fecha_Inicio_Corte,\r\n" + 
				"       Dc.Estado_Clie,\r\n" + 
				"       Dc.Solucion_Provisoria,\r\n" + 
				"       Dc.Origen\r\n" + 
				"  From Gelec.Ed_Det_Documentos_Clientes Dc, Gelec.Ed_Clientes C\r\n" + 
				" Where     Dc.Cuenta = C.Cuenta\r\n" + 
				"       And Dc.Id_Doc_Cliente = " + idDetalleCliente + "\r\n" + 
				"       And Dc.Log_Hasta Is Null";
	}
	
	public static String MARCAS_CLIENTE(String cuenta) {
		return "SELECT M.DESCRIPCION as MARCA, S.DESCRIPCION as SUBMARCA\r\n" + 
				"FROM GELEC.ED_MARCA_CLIENTE MC, GELEC.ED_SUBMARCAS S, GELEC.ED_MARCAS M  \r\n" + 
				"WHERE MC.ID_SUBMARCA = S.ID_SUBMARCA  \r\n" + 
				"AND MC.ID_MARCA = M.ID\r\n" + 
				"AND MC.LOG_HASTA IS NULL  \r\n" + 
				"AND MC.CUENTA = '" + cuenta + "'";
	}
	
	public static String RECLAMOS_CLIENTE(String cuenta, String idDocumento) {
		return "SELECT R.NOMBRE\r\n" + 
				"  FROM GELEC.ED_RECLAMOS R\r\n" + 
				" WHERE R.ID_DOCUMENTO = '" + idDocumento + "'\r\n" + 
				" AND R.CUENTA = '" + cuenta + "'";
	}
	
	public static String NOTAS_CLIENTE(String cuenta, String idDocumento) {
		return "SELECT N.USUARIO,\r\n" + 
				"         TP.DESCRIPCION,\r\n" + 
				"         CC.TELEFONO,\r\n" + 
				"         N.FECHAHORA,\r\n" + 
				"         N.OBSERVACIONES,\r\n" + 
				"         N.EFECTIVO,\r\n" + 
				"         N.ID_NOTA\r\n" + 
				"    FROM GELEC.ED_CLIENTE_NOTA     CN,\r\n" + 
				"         GELEC.ED_NOTAS            N,\r\n" + 
				"         GELEC.ED_TIPO_NOTA        TP,\r\n" + 
				"         GELEC.ED_CONTACTOS_CLIENTES CC\r\n" + 
				"   WHERE     CN.ID_NOTA = N.ID_NOTA\r\n" + 
				"         AND N.ID_TIPO_NOTA = TP.ID_TIPO_NOTA\r\n" + 
				"         AND N.IDDESTINO = CC.ID_TEL(+)\r\n" + 
				"         AND CN.CUENTA = '" + cuenta + "'\r\n" + 
				"         AND CN.ID_DOCUMENTO = " + idDocumento + "\r\n" + 
				"ORDER BY N.ID_NOTA DESC";
	}
	
	public static String EMAILS_INTERNOS(String region) {
		return "SELECT A.EMAIL,\r\n" + 
				"       A.NOMBRE,\r\n" + 
				"       A.CARGO,\r\n" + 
				"       A.PARTIDO\r\n" + 
				"  FROM GELEC.ED_AGENDA A\r\n" + 
				" WHERE A.REGION = '" + region + "' AND A.EMAIL IS NOT NULL AND A.LOG_HASTA IS NULL";
	}
	
	public static final String GET_LAST_UPDATED_DATE = "Select Max(L.Fecha) From Gelec.Ed_Log L \r\n" + 
			"Where L.Usuario = 'GELEC_BATCH'\r\n" + 
			"And L.Detalle = 'INSERTA DOCUMENTOS CON ELECTRODEPENDIENTES AFECTADOS'\r\n" + 
			"Order By L.Fecha Desc";
	
	public static String GET_REPO_CLIENTESTEL(){
		return 
			"SELECT T.*, \r\n"
			+ "(SELECT MAX(FECHAHORA) FROM GELEC.ED_NOTAS WHERE IDDESTINO=T.ID_TEL AND NVL(EFECTIVAS,0)>0) ULTIMO_CONTACTO_EFECTIVO, \r\n"
			+ "(CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE ID_TEL=T.ID_TEL AND NVL(LOG_HASTA,0)=0)>0 THEN 'ACTIVO' ELSE 'BAJA' END) ESTADO_TELEFONO, \r\n"
			+ "(CASE WHEN (SELECT COUNT(1) FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=T.CUENTA AND CUSTATT21='12521') = 1 THEN 'EDP' ELSE 'BC' END) ESTADO_CLIENTE \r\n"
			+ "FROM (\r\n"
				+ "SELECT C.CUENTA,CC.ID_TEL, CC.TELEFONO, \r\n"
				+ "SUM(CASE WHEN NVL(N.EFECTIVO,-1)>=0 THEN 1 ELSE 0 END) LLAMADAS, \r\n"
				+ "SUM(CASE WHEN NVL(N.EFECTIVO,0)>0 THEN 1 ELSE 0 END) EFECTIVAS \r\n"
				+ "FROM GELEC.ED_CLIENTES C,GELEC.ED_CONTACTOS_CLIENTES CC,GELEC.ED_NOTAS N \r\n"
				+ "WHERE C.CUENTA=CC.CUENTA(+) AND CC.ID_TEL=N.IDDESTINO(+) \r\n"
				+ "GROUP BY C.CUENTA, CC.ID_TEL, CC.TELEFONO \r\n"
				+ "ORDER BY C.CUENTA, CC.ID_TEL DESC) T";		
	}
	
	public static String GET_REPO_CLIENTESINTELEFONOS() {
		//23/8/2022 rsleiva: se agrego el reporte clientes edp sin telefonos. 
		return "SELECT C.CUENTA, C.RAZON_SOCIAL, CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=1 THEN 'Si' ELSE 'No' END BAJA_POTENCIAL FROM GELEC.ED_CLIENTES C WHERE NVL(C.LOG_HASTA,0)=0 AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0 AND CUENTA=C.CUENTA)=0";
	}	
	
	public static String GET_REPO_CLIENTESINCONTACTOS() {
		//23/8/2022 rsleiva: se agrego el reporte clientes edp sin telefonos. 
		return "SELECT \r\n"
					+ "C.CUENTA,\r\n"
					+ "COUNT(N.ID_NOTA) LLAMADAS, \r\n"
					+ "SUM(NVL(N.EFECTIVO,0)) EFECTIVAS,\r\n"
					+ "CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=1 THEN 'Si' ELSE 'No' END BAJA_POTENCIAL\r\n"
				+ "FROM \r\n"
					+ "GELEC.ED_CLIENTES C, \r\n"
					+ "GELEC.ED_CONTACTOS_CLIENTES CC, \r\n"
					+ "GELEC.ED_NOTAS N \r\n"
				+ "WHERE \r\n"
					+ "NVL(C.LOG_HASTA,0)=0 \r\n"
					+ "AND NVL(CC.LOG_HASTA,0)=0 \r\n"
					+ "AND C.CUENTA=CC.CUENTA \r\n"
					+ "AND CC.ID_TEL=N.IDDESTINO(+) \r\n"
				+ "GROUP BY \r\n"
					+ "C.CUENTA \r\n"
				+ "HAVING \r\n"
					+ "SUM(NVL(N.EFECTIVO,0))=0";
	}		
	
	
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
