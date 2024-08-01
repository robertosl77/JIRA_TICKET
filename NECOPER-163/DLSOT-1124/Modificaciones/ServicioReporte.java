package com.edenor.GELEC.servicios.implementaciones;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.mail.MessagingException;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;

import com.edenor.GELEC.Queries;
import com.edenor.GELEC.dao.AuditoriaDao;
import com.edenor.GELEC.dao.ClienteDocDao;
import com.edenor.GELEC.dao.DocumentoDao;
import com.edenor.GELEC.dao.ReclamoDao;
import com.edenor.GELEC.dto.MailInternoDTO;
import com.edenor.GELEC.dto.ReporteGeDTO;
import com.edenor.GELEC.dto.ReporteLlamadaDTO;
import com.edenor.GELEC.dto.clientes.ContactoDTO;
import com.edenor.GELEC.dto.clientes.HistorialContactosDTO;
import com.edenor.GELEC.dto.clientes.ReporteAfectadosDTO;
import com.edenor.GELEC.dto.documentos.ReporteDocumentoDTO;
import com.edenor.GELEC.dto.documentos.ReporteObjetivoLlamadasDTO;
import com.edenor.GELEC.dto.reportes.DashboardTablaDTO;
import com.edenor.GELEC.dto.reportes.DatosClienteDTO;
import com.edenor.GELEC.dto.reportes.DatosCorteDTO;
import com.edenor.GELEC.dto.reportes.DatosReporteRegionDTO;
import com.edenor.GELEC.dto.reportes.ReporteDetalleClienteDTO;
import com.edenor.GELEC.dto.reportes.ReporteMultipleClienteDTO;
import com.edenor.GELEC.dto.reportes.ReporteReclamoDTO;
import com.edenor.GELEC.dto.reportes.ReporteRegionDTO;
import com.edenor.GELEC.entidades.Mail;
import com.edenor.GELEC.servicios.interfaces.IServicioReporte;
import com.edenor.GELEC.utils.MethodUtilities;

import freemarker.template.TemplateException;
import freemarker.template.utility.StringUtil;

@Qualifier("servicioReporte")
@Service
public class ServicioReporte implements IServicioReporte {

	@PersistenceContext
	private EntityManager em;

	@Autowired
	ServicioCliente servicioCliente;

	@Autowired
	ServicioDocumento servicioDocumento;

	@Autowired
	ServicioMails servicioMails;

	@Autowired
	DocumentoDao documentoDao;

	@Autowired
	ClienteDocDao clienteDocDao;

	@Autowired
	ReclamoDao reclamoDao;

	@Autowired
	AuditoriaDao auditoriaDao;

	@Override
	public ReporteDetalleClienteDTO reporteDetalleCliente(String idDocumento, String cuenta, String idDetalleCliente) {

		ReporteDetalleClienteDTO res = new ReporteDetalleClienteDTO();

		res.setDatosCorte(this.mapearDatosCorteDTO(idDocumento));
		res.setDatosCliente(this.mapearDatosClienteDTO(idDocumento, cuenta, idDetalleCliente));
		res.setNotas(this.mapearHistorialContactoDTO(idDocumento, cuenta));
		res.setHistorialDocumentos(servicioDocumento.buscarHistorialPorCuenta(cuenta));
		return res;
	}

	@Override
	public ReporteMultipleClienteDTO reporteMultipleCliente(String idDocumento, List<String> cuentas,
			List<String> idDetalleClientes) {

		ReporteMultipleClienteDTO res = new ReporteMultipleClienteDTO();

		res.setDatosCorte(this.mapearDatosCorteDTO(idDocumento));

		List<DatosClienteDTO> clienteDTO = new ArrayList<>();
		for (int i = 0; i < cuentas.size(); i++) {
			DatosClienteDTO cliente = this.mapearDatosClienteDTO(idDocumento, cuentas.get(i), idDetalleClientes.get(i));
			clienteDTO.add(cliente);
		}
		res.setDatosClientes(clienteDTO);

		return res;
	}

	private DatosCorteDTO mapearDatosCorteDTO(String idDocumento) {

		String query = Queries.DATOS_CORTE_DTO(idDocumento);
		Object[] resDb = (Object[]) em.createNativeQuery(query).getSingleResult();

		DatosCorteDTO res = new DatosCorteDTO();

		res.setDocumento((String) resDb[0]);
		res.setTipoCorte((String) resDb[1]);
		res.setEstado((String) resDb[2]);
		res.setInicio(MethodUtilities.convertirTimestampAString((Timestamp) resDb[3]));
		res.setFin(MethodUtilities.convertirTimestampAString((Timestamp) resDb[4]));
		res.setZona((String) resDb[5]);
		res.setRegion(MethodUtilities.bigDecimalToString(resDb[6]));

		return res;
	}

	@SuppressWarnings("unchecked")
	private DatosClienteDTO mapearDatosClienteDTO(String idDocumento, String cuenta, String idDetalleCliente) {
		DatosClienteDTO res = new DatosClienteDTO();

		// DATOS PRINCIPALES
		String query = Queries.DATOS_CLIENTE_DTO(idDetalleCliente);
		Object[] resDb = (Object[]) em.createNativeQuery(query).getSingleResult();

		res.setCuenta((String) resDb[0]);
		res.setNombre((String) resDb[1]);
		String direccion = String.format("%s %s (%s)", (String) resDb[2], MethodUtilities.bigDecimalToString(resDb[3]),
				resDb[4].toString().trim());
		res.setDireccion(direccion);
		res.setPartido((String) resDb[5]);
		res.setCt((String) resDb[6]);
		res.setAfectadoDesde(MethodUtilities.convertirTimestampAString((Timestamp) resDb[7]));
		res.setEstado((String) resDb[8]);
		res.setSolucionProvisoria((String) resDb[9]);
		res.setOrigen((String) resDb[10]);

		// TELEFONOS
		List<ContactoDTO> telefonos = servicioCliente.buscarListaDeContactosPorCuenta(cuenta);
		res.setTelefonos(telefonos);
		if (telefonos.size() > 0) {
			res.setTelefonoEfectivo(telefonos.get(0).getTelefono());
		} else {
			res.setTelefonoEfectivo("");
		}

		// MARCAS
		query = Queries.MARCAS_CLIENTE(cuenta);
		List<Object[]> resDb2 = (List<Object[]>) em.createNativeQuery(query).getResultList();

		for (Object[] marca : resDb2) {
			String aux = (String) marca[0];
			switch (aux.toLowerCase()) {
			case "baja potencial":
				res.setBajaPotencial("Si");
				break;
			case "calidad de producto":
				res.setCalidadProd("Si");
				break;
			case "calidad de servicio":
				res.setCalidadServ("Si");
				break;
			case "revision de red":
				res.setRevisionRed("Si");
				break;
			case "fae":
				String fae = (String) marca[1];
				if (fae.equalsIgnoreCase("posee fae")) {
					res.setPoseeFae("Si");
				} else {
					res.setPoseeFae("No");
					res.setRequiereFae("Si");
				}
				break;

			default:
				break;
			}

		}

		// RECLAMOS
		query = Queries.RECLAMOS_CLIENTE(cuenta, idDocumento);
		List<Object> resDb3 = (List<Object>) em.createNativeQuery(query).getResultList();
		List<String> reclamos = new ArrayList<>();

		for (Object reclamo : resDb3) {
			reclamos.add((String) reclamo);
		}
		res.setReclamos(reclamos);

		return res;
	}

	@SuppressWarnings("unchecked")
	private List<HistorialContactosDTO> mapearHistorialContactoDTO(String idDocumento, String cuenta) {
		String query = Queries.NOTAS_CLIENTE(cuenta, idDocumento);
		List<Object[]> resDb = (List<Object[]>) em.createNativeQuery(query).getResultList();
		List<HistorialContactosDTO> res = new ArrayList<>();

		for (Object[] nota : resDb) {
			HistorialContactosDTO dto = new HistorialContactosDTO();

			dto.setUsuario((String) nota[0]);
			dto.setTipo((String) nota[1]);
			dto.setTelefono((String) nota[2]);
			dto.setFecha(MethodUtilities.convertirTimestampAString((Timestamp) nota[3]));
			dto.setDescripcion((String) nota[4]);
			dto.setEfectivo(MethodUtilities.bigDecimalToString(nota[5]));
			dto.setId(MethodUtilities.bigDecimalToString(nota[6]));

			res.add(dto);
		}

		return res;
	}

	@Override
	public List<DatosReporteRegionDTO> reporteRegion(String region) {
		List<DatosReporteRegionDTO> res = this.mapearReporteRegionDTO(region);

		return res;
	}

	@SuppressWarnings("unchecked")
	private List<DatosReporteRegionDTO> mapearReporteRegionDTO(String region) {
		String query = Queries.DATOS_REGION_DTO(region);
		List<Object[]> resDb = (List<Object[]>) em.createNativeQuery(query).getResultList();

		List<DatosReporteRegionDTO> res = new ArrayList<>();

		for (Object[] db : resDb) {

			DatosReporteRegionDTO dto = new DatosReporteRegionDTO();
			dto.setDocumento((String) db[0]);
			dto.setCuenta((String) db[1]);
			dto.setReclamo((String) db[2]);
			dto.setCt((String) db[3]);
			dto.setTipo((String) db[4]);
			dto.setEstado((String) db[5]);
			dto.setZona((String) db[6]);
			dto.setNombre((String) db[7]);
			String direccion = String.format("%s %s (%s)", (String) db[8], MethodUtilities.bigDecimalToString(db[9]),
					(String) db[10].toString().trim());
			dto.setDireccion(direccion);

			List<ContactoDTO> listaContactos = servicioCliente.buscarListaDeContactosPorCuenta(dto.getCuenta());
			String telefono = listaContactos.size() > 0 ? listaContactos.get(0).getTelefono() : "";
			dto.setTelefono(telefono);
			dto.setOrigen((String) db[11]);
			dto.setId(MethodUtilities.bigDecimalToString(db[12]));

			res.add(dto);
		}
		return res;
	}

	@Override
	public String enviarReporteRegion(ReporteRegionDTO dto) throws MessagingException, IOException, TemplateException {

		Mail mail = new Mail();
		mail.setFrom("Centro_De_Diagnostico@edenor.com");
		mail.setTo(dto.getTo());
		mail.setSubject(String.format("Reporte de región #%s", dto.getRegion()));

		// Armo modelo
		Map<String, Object> model = new HashMap<>();

		model.put("region", dto.getRegion());
		model.put("mensajeUsuario", dto.getMensajeUsuario());
		model.put("clientes", dto.getClientes());

		mail.setModel(model);

		servicioMails.enviarMailTemplate(mail, "ReporteRegion.ftl");
		return null;
	}

	@Override
	public String enviarReporteMultiple(ReporteMultipleClienteDTO dto)
			throws MessagingException, IOException, TemplateException {

		Mail mail = new Mail();
		mail.setFrom("Centro_De_Diagnostico@edenor.com");
		mail.setTo(dto.getTo());
		mail.setSubject("Clientes EDP");

		// Armo modelo
		Map<String, Object> model = new HashMap<>();

		model.put("mensajeUsuario", dto.getMensajeUsuario());
		model.put("documento", dto.getDatosCorte());
		model.put("clientes", dto.getDatosClientes());

		mail.setModel(model);

		servicioMails.enviarMailTemplate(mail, "ReporteMultipleCliente.ftl");
		return null;
	}

	@Override
	public String enviarReporteUnico(ReporteDetalleClienteDTO dto, String username)
			throws MessagingException, IOException, TemplateException {

		Mail mail = new Mail();
		mail.setFrom("Centro_De_Diagnostico@edenor.com");
		mail.setTo(dto.getTo());
		mail.setSubject("Cliente EDP");

		// Armo modelo
		Map<String, Object> model = new HashMap<>();

		model.put("mensajeUsuario", dto.getMensajeUsuario());
		model.put("documento", dto.getDatosCorte());
		model.put("cliente", dto.getDatosCliente());
		model.put("mostrarMarcas", dto.getMostrarMarcas());
		model.put("historialDoc", dto.getHistorialDocumentos());
		model.put("notas", dto.getNotas());

		mail.setModel(model);

		servicioMails.enviarMailTemplate(mail, "ReporteUnicoCliente.ftl");
		return null;
	}

	@SuppressWarnings("unchecked")
	@Override
	public List<MailInternoDTO> getListaMailsInternos(String region) {
		List<MailInternoDTO> response = new ArrayList<MailInternoDTO>();
		List<Object[]> dbMails = (List<Object[]>) em.createNativeQuery(Queries.EMAILS_INTERNOS(region)).getResultList();

		for (Object[] mail : dbMails) {
			MailInternoDTO dto = new MailInternoDTO();
			dto.setEmail((String) mail[0]);
			dto.setNombre((String) mail[1]);
			dto.setCargo((String) mail[2]);
			dto.setPartido((String) mail[3]);

			response.add(dto);
		}
		return response;
	}

	public byte[] reporteDocumento(Map<String, String> dto) throws IOException {

		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("ID_DOCUMENTO");
		headerRow.createCell(1).setCellValue("DOCUMENTO");
		headerRow.createCell(2).setCellValue("TIPO");
		headerRow.createCell(3).setCellValue("ESTADO");
		headerRow.createCell(4).setCellValue("FECHA_INICIO");
		headerRow.createCell(5).setCellValue("FECHA_FIN");
		headerRow.createCell(6).setCellValue("FECHA_FIN_MANUAL");
		headerRow.createCell(7).setCellValue("REGION");
		headerRow.createCell(8).setCellValue("ZONA");
		headerRow.createCell(9).setCellValue("PARTIDO");
		headerRow.createCell(10).setCellValue("LOCALIDAD");
		headerRow.createCell(11).setCellValue("NOTAS");
		headerRow.createCell(12).setCellValue("RECLAMOS");
		headerRow.createCell(13).setCellValue("AFECTACIONES");
		headerRow.createCell(14).setCellValue("EDP");
		headerRow.createCell(15).setCellValue("GE");
		headerRow.createCell(16).setCellValue("FAE");
		headerRow.createCell(17).setCellValue("GE_PROPIO");
		headerRow.createCell(18).setCellValue("SUMATORIA DURACION AFECTACIONES (Min.)");
		headerRow.createCell(19).setCellValue("PROMEDIO DURACION AFECTACIONES (Min.");

		Integer conteo = 0;
		Boolean isLast = false;
		Integer i = 1;

		while (!isLast) {
			Page<ReporteDocumentoDTO> res = documentoDao.findForReporteDocumento(PageRequest.of(conteo, 5000),
					dto.get("fechaInicio"), dto.get("fechaFin"), Integer.parseInt(dto.get("duracion")));

			for (ReporteDocumentoDTO d : res.getContent()) {
				Row rows = sheet.createRow(i);
				rows.createCell(0).setCellValue(d.getIdDocumento());
				rows.createCell(1).setCellValue(d.getNroDocumento());
				rows.createCell(2).setCellValue(d.getTipoCorte());
				rows.createCell(3).setCellValue(d.getEstadoDoc());
				rows.createCell(4).setCellValue(d.getFechaInicioDoc());
				rows.createCell(5).setCellValue(d.getFechaFinDoc());
				rows.createCell(6).setCellValue(d.getFechaFinManual());
				rows.createCell(7).setCellValue(d.getRegion());
				rows.createCell(8).setCellValue(d.getZona());
				rows.createCell(9).setCellValue(d.getPartido());
				rows.createCell(10).setCellValue(nvl(d.getLocalidad()).trim());
				rows.createCell(11).setCellValue(nvl(d.getNotas()).trim());
				rows.createCell(12).setCellValue(d.getReclamos());
				rows.createCell(13).setCellValue(d.getAfectaciones());
				rows.createCell(14).setCellValue(d.getEdp());
				rows.createCell(15).setCellValue(d.getGe());
				rows.createCell(16).setCellValue(d.getFae());
				rows.createCell(17).setCellValue(nvl(d.getGePropio()));
				rows.createCell(18).setCellValue(d.getSumaAfectaciones());
				rows.createCell(19)
						.setCellValue(d.getAfectaciones() != 0 ? d.getSumaAfectaciones() / d.getAfectaciones() : new Double("0"));
				i++;
			}

			if (!res.isLast()) {
				conteo++;
			} else {
				isLast = true;
			}
		}

		for (int j = 0; j < 20; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();

		return file;
	}

	public byte[] reporteElectrodependiente(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("ID_DOCUMENTO");
		headerRow.createCell(1).setCellValue("DOCUMENTO");
		headerRow.createCell(2).setCellValue("CUENTA");
		headerRow.createCell(3).setCellValue("CT_CLIE");
		headerRow.createCell(4).setCellValue("REGION");
		headerRow.createCell(5).setCellValue("ZONA");
		headerRow.createCell(6).setCellValue("PARTIDO");
		headerRow.createCell(7).setCellValue("LOCALIDAD");
		headerRow.createCell(8).setCellValue("ESTADO");
		headerRow.createCell(9).setCellValue("PROVISORIO");
		headerRow.createCell(10).setCellValue("INICIO");
		headerRow.createCell(11).setCellValue("FIN");
		headerRow.createCell(12).setCellValue("FIN_MANUAL");
		headerRow.createCell(13).setCellValue("CANT_LLAMADOS");
		headerRow.createCell(14).setCellValue("CANT_EFECTIVOS");
		headerRow.createCell(15).setCellValue("RECLAMOS");
		headerRow.createCell(16).setCellValue("ASISTIDO");

		Integer conteo = 0;
		Boolean isLast = false;
		Integer i = 1;

		while (!isLast) {

			Page<ReporteAfectadosDTO> res;
			res = clienteDocDao.findForReporteElectrodependientes(PageRequest.of(conteo, 5000), dto.get("fechaInicio"),
					dto.get("fechaFin"), dto.get("cuenta"));

			for (ReporteAfectadosDTO d : res.getContent()) {
				Row rows = sheet.createRow(i);
				try {
					rows.createCell(0).setCellValue(d.getIdDocumento());
					rows.createCell(1).setCellValue(d.getNroDocumento());
					rows.createCell(2).setCellValue(d.getCuenta());
					rows.createCell(3).setCellValue(d.getCt());
					rows.createCell(4).setCellValue(d.getRegion());
					rows.createCell(5).setCellValue(d.getZona());
					rows.createCell(6).setCellValue(d.getPartido());
					rows.createCell(7).setCellValue(d.getLocalidad());
					rows.createCell(8).setCellValue(d.getEstado());
					rows.createCell(9).setCellValue(d.getProvisorio());
					rows.createCell(10).setCellValue(d.getFechaInicio());
					rows.createCell(11).setCellValue(d.getFechaFin());
					rows.createCell(12).setCellValue(d.getFechaFinEditable());
					rows.createCell(13).setCellValue(d.getCantLlamados());
					rows.createCell(14).setCellValue(d.getCantEfectivos());
					rows.createCell(15).setCellValue(d.getCantReclamos());
					rows.createCell(16).setCellValue(d.getAsistido());
					i++;
				} catch (Exception e) {
					e.printStackTrace();
				}
			}

			if (!res.isLast()) {
				conteo++;
			} else {
				isLast = true;
			}
		}

		for (int j = 0; j < 17; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteAfectados(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("ID_DOCUMENTO");
		headerRow.createCell(1).setCellValue("TIPO");
		headerRow.createCell(2).setCellValue("DOCUMENTO");
		headerRow.createCell(3).setCellValue("CUENTA");
		headerRow.createCell(4).setCellValue("CT_CLIE");
		headerRow.createCell(5).setCellValue("REGION");
		headerRow.createCell(6).setCellValue("ZONA");
		headerRow.createCell(7).setCellValue("PARTIDO");
		headerRow.createCell(8).setCellValue("LOCALIDAD");
		headerRow.createCell(9).setCellValue("ESTADO");
		headerRow.createCell(10).setCellValue("PROVISORIO");
		headerRow.createCell(11).setCellValue("INICIO");
		headerRow.createCell(12).setCellValue("FIN");
		headerRow.createCell(13).setCellValue("FIN_MANUAL");
		headerRow.createCell(14).setCellValue("CANT_LLAMADOS");
		headerRow.createCell(15).setCellValue("CANT_EFECTIVOS");
		headerRow.createCell(16).setCellValue("RECLAMOS");
		headerRow.createCell(17).setCellValue("ASISTIDO");
		headerRow.createCell(18).setCellValue("AFECTACIONES");
		headerRow.createCell(19).setCellValue("PROMEDIO_DURACION");

		Integer conteo = 0;
		Boolean isLast = false;

		Integer i = 1;
		while (!isLast) {

			Page<ReporteAfectadosDTO> res;
			res = clienteDocDao.findForReporteAfectaciones(PageRequest.of(conteo, 5000), dto.get("fechaInicio"),
					dto.get("fechaFin"));

			for (ReporteAfectadosDTO d : res.getContent()) {
				Row rows = sheet.createRow(i);
				try {
					rows.createCell(0).setCellValue(d.getIdDocumento());
					rows.createCell(1).setCellValue(d.getTipoDocumento());
					rows.createCell(2).setCellValue(d.getNroDocumento());
					rows.createCell(3).setCellValue(d.getCuenta());
					rows.createCell(4).setCellValue(d.getCt());
					rows.createCell(5).setCellValue(d.getRegion());
					rows.createCell(6).setCellValue(d.getZona());
					rows.createCell(7).setCellValue(d.getPartido());
					rows.createCell(8).setCellValue(d.getLocalidad());
					rows.createCell(9).setCellValue(d.getEstado());
					rows.createCell(10).setCellValue(d.getProvisorio());
					rows.createCell(11).setCellValue(d.getFechaInicio());
					rows.createCell(12).setCellValue(d.getFechaFin());
					rows.createCell(13).setCellValue(d.getFechaFinEditable());
					rows.createCell(14).setCellValue(d.getCantLlamados());
					rows.createCell(15).setCellValue(d.getCantEfectivos());
					rows.createCell(16).setCellValue(d.getCantReclamos());
					rows.createCell(17).setCellValue(d.getAsistido());
					rows.createCell(18).setCellValue(d.getAfectaciones());
					rows.createCell(19).setCellValue(d.getSumatoria() / d.getAfectaciones());
					i++;
				} catch (Exception e) {
					e.printStackTrace();
				}
			}

			if (!res.isLast()) {
				conteo++;
			} else {
				isLast = true;
			}
			em.clear();
		}

		for (int j = 0; j < 20; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteObjetivoLlamadas(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		CellStyle cs = wb.createCellStyle();
		cs.setWrapText(true);

		Cell c;
		headerRow.createCell(0).setCellValue("FECHA");
		headerRow.createCell(1).setCellValue("TIPO_DOCUMENTO");
		c = headerRow.createCell(2);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nCUENTA\nC\nREC");
		c = headerRow.createCell(3);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nLLAM\nCUENTA\nC\nREC");
		c = headerRow.createCell(4);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nLLAM\nEFE\nCUENTA\nC\nREC");
		c = headerRow.createCell(5);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nCUENTA\nSIN\nREC");
		c = headerRow.createCell(6);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nLLAM\nCUENTA\nSIN\nREC");
		c = headerRow.createCell(7);
		c.setCellStyle(cs);
		c.setCellValue("CANT\nLLAM\nEFE\nCUENTA\nSIN\nREC");
		headerRow.createCell(8).setCellValue("INDICE");

		List<ReporteObjetivoLlamadasDTO> res = documentoDao.findForReporteObjetivosLlamadas(dto.get("fechaInicio"),
				dto.get("fechaFin"));

		Integer i = 1;
		for (ReporteObjetivoLlamadasDTO d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue(d.getFecha());
				rows.createCell(1).setCellValue(d.getTipoCorte());
				rows.createCell(2).setCellValue(d.getClientesRec());
				rows.createCell(3).setCellValue(d.getLlamadasRec());
				rows.createCell(4).setCellValue(d.getLlamadasRecEfectivas());
				rows.createCell(5).setCellValue(d.getClientes());
				rows.createCell(6).setCellValue(d.getLlamadas());
				rows.createCell(7).setCellValue(d.getLlamadasEfectivas());

				Integer divisor = d.getClientesRec() + d.getClientes();
				Integer indice = 0;
				if (divisor != 0) {
					indice = (d.getLlamadasRecEfectivas() + d.getLlamadasEfectivas()) / divisor;
				}
				rows.createCell(8).setCellValue(indice);
				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j < 8; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteReclamos(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("DOCUMENTO");
		headerRow.createCell(1).setCellValue("CUENTA");
		headerRow.createCell(2).setCellValue("RECLAMO");
		headerRow.createCell(3).setCellValue("FECHA");
		headerRow.createCell(4).setCellValue("REITERACIONES");
		headerRow.createCell(5).setCellValue("ULTIMA_REITERACION");
		headerRow.createCell(6).setCellValue("REGION");
		headerRow.createCell(7).setCellValue("ZONA");
		headerRow.createCell(8).setCellValue("PARTIDO");
		headerRow.createCell(9).setCellValue("LOCALIDAD");
		headerRow.createCell(10).setCellValue("LLAMADAS");
		headerRow.createCell(11).setCellValue("LLAM. EFECTIVAS");

		Integer conteo = 0;
		Boolean isLast = false;
		Integer i = 1;

		while (!isLast) {
			Page<ReporteReclamoDTO> res = reclamoDao.findForReporteReclamos(PageRequest.of(conteo, 5000),
					dto.get("fechaInicio"), dto.get("fechaFin"));

			for (ReporteReclamoDTO d : res.getContent()) {
				Row rows = sheet.createRow(i);
				try {
					rows.createCell(0).setCellValue(d.getNroDocumento());
					rows.createCell(1).setCellValue(d.getCuenta());
					rows.createCell(2).setCellValue(d.getNombre());
					rows.createCell(3).setCellValue(d.getFecha());
					rows.createCell(4).setCellValue(d.getReiteraciones());
					rows.createCell(5).setCellValue(d.getUltimaReiteracion());
					rows.createCell(6).setCellValue(d.getRegion());
					rows.createCell(7).setCellValue(d.getZona());
					rows.createCell(8).setCellValue(d.getPartido());
					rows.createCell(9).setCellValue(d.getLocalidad());
					rows.createCell(10).setCellValue(d.getLlamadas());
					rows.createCell(11).setCellValue(d.getLlamadasEfectivas());
					i++;
				} catch (Exception e) {
					e.printStackTrace();
				}
			}

			if (!res.isLast()) {
				conteo++;
			} else {
				isLast = true;
			}
		}

		for (int j = 0; j < 12; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteCliSinTel(Map<String, String> dto) throws IOException {
		// 19/08/2022 rsleiva se agrega el reporte Clientes Sin Tel
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("CUENTA");
		headerRow.createCell(1).setCellValue("RAZON_SOCIAL");
		headerRow.createCell(2).setCellValue("BAJA_POTENCIAL");

		String sql= Queries.GET_REPO_CLIENTESINTELEFONOS();

		// Creo el objeto query
		Query q = em.createNativeQuery(sql);

		// Ejecuto
		@SuppressWarnings("unchecked")
		List<Object[]> res = (List<Object[]>) q.getResultList();

		Integer i = 1;
		for (Object[] d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue((String) d[0].toString());
				rows.createCell(1).setCellValue((String) d[1].toString());
				rows.createCell(2).setCellValue((String) d[2].toString());

				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j <=2; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteCliSinContacto(Map<String, String> dto) throws IOException {
		// 23/08/2022 rsleiva se agrega el reporte Clientes Sin Tel
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("CUENTA");
		headerRow.createCell(1).setCellValue("LLAMADAS");
		headerRow.createCell(2).setCellValue("EFECTIVAS");
		headerRow.createCell(3).setCellValue("TIPO");
		headerRow.createCell(4).setCellValue("BAJA_POTENCIAL");

		String sql= Queries.GET_REPO_CLIENTESINCONTACTOS();

		// Creo el objeto query
		Query q = em.createNativeQuery(sql);

		// Ejecuto
		@SuppressWarnings("unchecked")
		List<Object[]> res = (List<Object[]>) q.getResultList();

		Integer i = 1;
		for (Object[] d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue((String) d[0].toString());
				rows.createCell(1).setCellValue((Integer) Integer.valueOf(d[1].toString()));
				rows.createCell(2).setCellValue((Integer) Integer.valueOf(d[2].toString()));				
				rows.createCell(3).setCellValue((String) d[3].toString());
				rows.createCell(4).setCellValue((String) d[4].toString());

				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j <=3; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteMarcas(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("REGION");
		headerRow.createCell(1).setCellValue("PARTIDO");
		headerRow.createCell(2).setCellValue("LOCALIDAD");
		headerRow.createCell(3).setCellValue("MOTIVO");
		headerRow.createCell(4).setCellValue("SUBMOTIVO");
		headerRow.createCell(5).setCellValue("CUENTA");
		headerRow.createCell(6).setCellValue("CT");
		headerRow.createCell(7).setCellValue("FECHA INI");
		headerRow.createCell(8).setCellValue("FECHA FIN");
		headerRow.createCell(9).setCellValue("USUARIO");
		headerRow.createCell(10).setCellValue("ESTADO");

		String sql = "select c.REGION, c.PARTIDO, c.LOCALIDAD, m.DESCRIPCION marca, s.DESCRIPCION submarca, c.cuenta, c.CT, TO_CHAR(l1.FECHA,'DD/MM/YYYY HH24:MI') inicio, TO_CHAR(l2.FECHA,'DD/MM/YYYY HH24:MI') fin, l1.USUARIO\r\n"
				+ "from GELEC.ED_MARCA_CLIENTE mc\r\n" + "inner join GELEC.ED_MARCAS m on m.ID = mc.ID_MARCA\r\n"
				+ "inner join GELEC.ED_SUBMARCAS s on s.ID_SUBMARCA = mc.ID_SUBMARCA\r\n"
				+ "inner join GELEC.ED_CLIENTES c on c.CUENTA = mc.CUENTA\r\n"
				+ "inner join GELEC.ED_LOG l1 on l1.LOG_ID = mc.LOG_DESDE\r\n"
				+ "left join GELEC.ED_LOG l2 on l2.LOG_ID = mc.LOG_HASTA\r\n";

		// Construyo dinamicamente
		List<String> filtros = new ArrayList<>();
		if (dto.get("region") != "") {
			filtros.add("c.region = :region\r\n");
		}
		if (dto.get("partido") != "") {
			filtros.add("TRIM(c.partido) = UPPER(:partido)\r\n");
		}
		if (dto.get("localidad") != "") {
			filtros.add("TRIM(c.localidad) = :localidad\r\n");
		}
		if (dto.get("motivo") != "") {
			filtros.add("m.descripcion = :motivo\r\n");
		}
		if (dto.get("submotivo") != "") {
			filtros.add("s.descripcion = :submotivo\r\n");
		}

		Integer f = 0;
		for (String filtro : filtros) {
			if (f == 0)
				sql += "where " + filtro;
			else
				sql += "and " + filtro;
			f++;
		}

		sql += "order by cuenta, marca";

		// Creo el objeto query
		Query q = em.createNativeQuery(sql);

		// Seteo parametros dinamicamente
		Set<String> keys = dto.keySet();
		for (String key : keys) {
			if (key.matches("^(region|partido|localidad|motivo|submotivo)")) {
				if (dto.get(key) != "")
					q.setParameter(key, dto.get(key));
			}
		}

		// Ejecuto
		@SuppressWarnings("unchecked")
		List<Object[]> res = (List<Object[]>) q.getResultList();

		Integer i = 1;
		for (Object[] d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue((String) d[0]);
				rows.createCell(1).setCellValue((String) d[1]);
				rows.createCell(2).setCellValue((String) d[2]);
				rows.createCell(3).setCellValue((String) d[3]);
				rows.createCell(4).setCellValue((String) d[4]);
				rows.createCell(5).setCellValue((String) d[5]);
				rows.createCell(6).setCellValue((String) d[6]);
				rows.createCell(7).setCellValue((String) d[7]);
				rows.createCell(8).setCellValue((String) d[8]);
				rows.createCell(9).setCellValue((String) d[9]);
				rows.createCell(10).setCellValue((String) d[8] != null ? "Activa" : "Inactiva");
				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j < 11; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteAlertas(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		CellStyle amarillo = wb.createCellStyle();
		CellStyle rojo = wb.createCellStyle();

		amarillo.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		amarillo.setFillForegroundColor(IndexedColors.LIGHT_YELLOW.getIndex());
		rojo.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		rojo.setFillForegroundColor(IndexedColors.RED.getIndex());

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("REGION");
		headerRow.createCell(1).setCellValue("ZONA");
		headerRow.createCell(2).setCellValue("CUENTA");
		headerRow.createCell(3).setCellValue("DOCUMENTO");
		headerRow.createCell(4).setCellValue("USUARIO");
		headerRow.createCell(5).setCellValue("TIPO");
		headerRow.createCell(6).setCellValue("SUBMOTIVO");
		headerRow.createCell(7).setCellValue("FECHA INI");
		headerRow.createCell(8).setCellValue("FECHA FIN");
		headerRow.createCell(9).setCellValue("ESTADO");
		headerRow.createCell(10).setCellValue("NOTA");
		headerRow.createCell(11).setCellValue("BC");
		headerRow.createCell(12).setCellValue("BP");

		String sql = "select d.REGION, d.ZONA, cn.cuenta, d.NRO_DOCUMENTO nroDocumento, n.USUARIO, tn.DESCRIPCION tipo, sn.DESCRIPCION submotivo, n.FECHAALERTA, l.FECHA fechacierre,  \r\n"
				+ "case when l.fecha is null then 'Activa' else 'Cerrada' END estado,  n.OBSERVACIONES,\r\n"
				+ "(select count(*) from GELEC.ED_CLIENTES c \r\n" + "where c.cuenta = cn.cuenta\r\n"
				+ "and c.log_hasta is not null) BC,\r\n" + "(select count(*) from GELEC.ED_MARCA_CLIENTE mc\r\n"
				+ "where mc.cuenta = cn.cuenta\r\n" + "and mc.log_hasta is null\r\n" + "and mc.ID_MARCA = 1) BP\r\n"
				+ "from GELEC.ED_NOTAS n  \r\n" + "left join GELEC.ED_CLIENTE_NOTA cn on cn.ID_NOTA = n.ID_NOTA  \r\n"
				+ "left join GELEC.ED_DOCUMENTOS d on d.ID_DOCUMENTO = cn.ID_DOCUMENTO  \r\n"
				+ "inner join GELEC.ED_TIPO_NOTA tn on tn.ID_TIPO_NOTA = n.ID_TIPO_NOTA  \r\n"
				+ "left join GELEC.ED_LOG l on l.LOG_ID = n.LOG_HASTA  \r\n"
				+ "left join GELEC.ED_SUBTIPO_NOTA sn on sn.id = n.ID_SUBTIPO_NOTA\r\n"
				+ "where n.FECHAHORA between TO_DATE (:fechaInicio, 'DD/MM/YYYY')  AND TO_DATE (:fechaFin, 'DD/MM/YYYY')  \r\n"
				+ "and n.FECHAALERTA is not null\r\n";

		switch (dto.get("estado").toLowerCase()) {
		case "activa":
			sql += "and n.log_hasta is null\r\n";
			break;
		case "inactiva":
			sql += "and n.log_hasta is not null\r\n";
			break;

		default:
			break;
		}

		sql += "order by n.fechaalerta desc";

		// Creo el objeto query
		Query q = em.createNativeQuery(sql).setParameter("fechaInicio", dto.get("fechaInicio")).setParameter("fechaFin",
				dto.get("fechaFin"));

		// Ejecuto
		@SuppressWarnings("unchecked")
		List<Object[]> res = (List<Object[]>) q.getResultList();

		Integer i = 1;
		for (Object[] d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue(MethodUtilities.bigDecimalToString((BigDecimal) d[0]));
				rows.createCell(1).setCellValue((String) d[1]);
				rows.createCell(2).setCellValue((String) d[2]);
				rows.createCell(3).setCellValue((String) d[3]);
				rows.createCell(4).setCellValue((String) d[4]);
				rows.createCell(5).setCellValue((String) d[5]);
				rows.createCell(6).setCellValue((String) d[6]);
				rows.createCell(8).setCellValue(MethodUtilities.convertirTimestampAString((Timestamp) d[7]));
				rows.createCell(9).setCellValue(MethodUtilities.convertirTimestampAString((Timestamp) d[8]));
				rows.createCell(7).setCellValue((String) d[9]);
				rows.createCell(10).setCellValue((String) d[10]);

				String bajaConfirmada = MethodUtilities.bigDecimalToString((BigDecimal) d[11]);
				Cell c;
				c = rows.createCell(11);
				if (!bajaConfirmada.equalsIgnoreCase("0"))
					c.setCellStyle(rojo);
				c.setCellValue(bajaConfirmada);

				String bajaPotencial = MethodUtilities.bigDecimalToString((BigDecimal) d[12]);
				c = rows.createCell(12);
				if (!bajaPotencial.equalsIgnoreCase("0"))
					c.setCellStyle(amarillo);
				c.setCellValue(bajaPotencial);

				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j < 13; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public byte[] reporteGE(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);

		headerRow.createCell(0).setCellValue("CUENTA");
		headerRow.createCell(1).setCellValue("DOCUMENTO");
		headerRow.createCell(2).setCellValue("TIPO");
		headerRow.createCell(3).setCellValue("FECHA_INICIO");
		headerRow.createCell(4).setCellValue("FECHA_FIN");
		headerRow.createCell(5).setCellValue("FECHA_FIN MANUAL");
		headerRow.createCell(6).setCellValue("ESTADO");
		headerRow.createCell(7).setCellValue("SOL. PROVISORIA");
		headerRow.createCell(8).setCellValue("REGION");
		headerRow.createCell(9).setCellValue("ZONA");
		headerRow.createCell(10).setCellValue("PARTIDO");
		headerRow.createCell(11).setCellValue("LOCALIDAD");

		List<ReporteGeDTO> res = auditoriaDao.findForReporteGE(dto.get("fechaInicio"), dto.get("fechaFin"));

		Integer i = 1;
		for (ReporteGeDTO d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue(d.getCuenta());
				rows.createCell(1).setCellValue(d.getNroDocumento());
				rows.createCell(2).setCellValue(d.getTipoCorte());
				rows.createCell(3).setCellValue(d.getFechaInicioDoc());
				rows.createCell(4).setCellValue(d.getFechaFinDoc());
				rows.createCell(5).setCellValue(d.getFechaFinManual());
				rows.createCell(6).setCellValue(d.getEstado());
				rows.createCell(7).setCellValue(d.getProvisoria());
				rows.createCell(8).setCellValue(d.getRegion());
				rows.createCell(9).setCellValue(d.getZona());
				rows.createCell(10).setCellValue(d.getPartido());
				rows.createCell(11).setCellValue(d.getLocalidad());
				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j < 11; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	public List<Map<String, Object>> getDashboard() {
		List<DashboardTablaDTO> hoy = documentoDao.findForDashboardHoy();
		List<DashboardTablaDTO> avg = documentoDao.findForDashboardAVG();

		List<Map<String, Object>> res = new ArrayList<>();

		for (DashboardTablaDTO a : avg) {
			Map<String, Object> map = new HashMap<>();
			map.put("categoria", a.getTipoCorte());
			map.put("documentosAvg", a.getDocumentos());
			map.put("reclamosAvg", a.getReclamos());
			map.put("llamadasAvg", a.getLlamadas());
			map.put("llamadasEfectivasAvg", a.getLlamadasEfectivas());
			
			for (DashboardTablaDTO h : hoy) {
				if (a.getTipoCorte().equalsIgnoreCase(h.getTipoCorte())) {
					map.put("documentos", h.getDocumentos());
					map.put("reclamos", h.getReclamos());
					map.put("llamadas", h.getLlamadas());
					map.put("llamadasEfectivas", h.getLlamadasEfectivas());
					break;
				} else {
					map.put("documentos", 0);
					map.put("reclamos", 0);
					map.put("llamadas", 0);
					map.put("llamadasEfectivas", 0);
				}
			}

			res.add(map);
		}

		return res;
	}

	public byte[] reporteLlamadas(Map<String, String> dto) throws IOException {
		Workbook wb = new XSSFWorkbook();
		Sheet sheet = wb.createSheet(dto.get("tipoReporte"));

		Row headerRow = sheet.createRow(0);
		headerRow.createCell(0).setCellValue("TIPO");
		headerRow.createCell(1).setCellValue("USUARIO");
		headerRow.createCell(2).setCellValue("FECHA");
		headerRow.createCell(3).setCellValue("ORIGEN");
		headerRow.createCell(4).setCellValue("EFECTIVO");

		String sql = "Select d.TIPO_CORTE tipoCorte, lower(n.USUARIO) usuario, n.FECHAHORA fecha, n.origen, case when n.efectivo = 0 then 'No' else 'Si' END efectivo\r\n"
				+ "From GELEC.ED_NOTAS n\r\n" + "inner join GELEC.ED_CLIENTE_NOTA cn on cn.ID_NOTA = n.ID_NOTA\r\n"
				+ "left join GELEC.ED_DOCUMENTOS d on d.ID_DOCUMENTO = cn.ID_DOCUMENTO\r\n" + "where n.ID_TIPO_NOTA = 4\r\n"
				+ "and n.FECHAHORA between to_date(:fechaInicio,'dd/mm/yyyy') and to_date(:fechaFin,'dd/mm/yyyy')\r\n";

		// Construyo dinamicamente
		List<String> filtros = new ArrayList<>();
		if (dto.get("usuario") != "") {
			filtros.add("and lower(n.usuario) = :usuario\r\n");
		}
		if (dto.get("region") != "") {
			filtros.add("and d.region = :region\r\n");
		}
		if (dto.get("zona") != "") {
			filtros.add("and lower(d.zona) = lower(:zona)\r\n");
		}
		if (dto.get("origen") != "") {
			filtros.add("and lower(n.origen) = :origen\r\n");
		}
		
		for(String f : filtros) {
			sql += f;
		}
		
		sql += "order by n.FECHAHORA desc";

		// Creo el objeto query
		Query q = em.createNativeQuery(sql);

		q.setParameter("fechaInicio", dto.get("fechaInicio"));
		q.setParameter("fechaFin", dto.get("fechaFin"));

		// Seteo parametros dinamicamente
		Set<String> keys = dto.keySet();
		for (String key : keys) {
			if (key.matches("^(usuario|region|zona|origen)")) {
				if (dto.get(key) != "")
					q.setParameter(key, dto.get(key));
			}
		}

		// Ejecuto
		@SuppressWarnings("unchecked")
		List<Object[]> res = (List<Object[]>) q.getResultList();

		Integer i = 1;
		for (Object[] d : res) {
			Row rows = sheet.createRow(i);
			try {
				rows.createCell(0).setCellValue((String) d[0]);
				rows.createCell(1).setCellValue((String) d[1]);
				rows.createCell(2).setCellValue(MethodUtilities.convertirTimestampAString((Timestamp) d[2]));
				rows.createCell(3).setCellValue((String) d[3]);
				rows.createCell(4).setCellValue((String) d[4]);
				i++;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		for (int j = 0; j < 5; j++) {
			sheet.autoSizeColumn(j);
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		wb.write(baos);
		wb.close();
		byte[] file = baos.toByteArray();
		return file;
	}

	@SuppressWarnings("unchecked")
	public List<String> getUsuariosNota() {
		List<String> usuarios = em
				.createNativeQuery("Select distinct lower(usuario)\r\n" + 
						"From gelec.ed_notas n\r\n" + 
						"inner join gelec.ed_cliente_nota cn on cn.ID_NOTA = n.ID_NOTA\r\n" + 
						"where n.ID_TIPO_NOTA = 4\r\n" + 
						"order by lower(usuario)")
				.getResultList();
		return usuarios;
	}

	@SuppressWarnings("unchecked")
	public List<String> getOrigenNota() {
		List<String> origen = em.createNativeQuery("Select distinct lower(origen)\r\n" + "From gelec.ed_notas\r\n"
				+ "where origen is not null\r\n" + "order by lower(origen)").getResultList();
		return origen;
	}

	private static String nvl(Object value) {
		if (value == null) {
			return "";
		} else {
			return value.toString();
		}
	}
}
