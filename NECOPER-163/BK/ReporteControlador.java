package com.edenor.GELEC.controladores;

import java.io.IOException;
import java.security.Principal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.mail.MessagingException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.edenor.GELEC.dto.MailInternoDTO;
import com.edenor.GELEC.dto.reportes.CuentasIdDetalleDTO;
import com.edenor.GELEC.dto.reportes.DatosReporteRegionDTO;
import com.edenor.GELEC.dto.reportes.ReporteDetalleClienteDTO;
import com.edenor.GELEC.dto.reportes.ReporteMultipleClienteDTO;
import com.edenor.GELEC.dto.reportes.ReporteRegionDTO;
import com.edenor.GELEC.servicios.implementaciones.ServicioReporte;

import freemarker.template.TemplateException;

@RestController
@CrossOrigin(allowCredentials = "true")
@RequestMapping("/api/reporte")
public class ReporteControlador {

	@Autowired
	ServicioReporte servicioReporte;

	@GetMapping("/detalleCliente/{idDocumento}/{cuenta}/{idDetalleCliente}")
	public ResponseEntity<?> detalleCliente(@PathVariable String idDocumento, @PathVariable String cuenta, @PathVariable String idDetalleCliente) {

		ReporteDetalleClienteDTO res = servicioReporte.reporteDetalleCliente(idDocumento, cuenta, idDetalleCliente);
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@PostMapping("/multipleCliente/{idDocumento}")
	public ResponseEntity<?> multipleCliente(@PathVariable String idDocumento, @RequestBody CuentasIdDetalleDTO dto) {

		ReporteMultipleClienteDTO res = servicioReporte.reporteMultipleCliente(idDocumento, dto.getCuentas(), dto.getIdsDetalleCliente());
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@GetMapping("/region/{region}")
	public ResponseEntity<?> region(@PathVariable String region) {

		List<DatosReporteRegionDTO> res = servicioReporte.reporteRegion(region);
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@PostMapping("/enviarReporteRegion")
	public ResponseEntity<?> enviarReporteRegion(@RequestBody ReporteRegionDTO dto)
			throws MessagingException, IOException, TemplateException {

		String res = servicioReporte.enviarReporteRegion(dto);
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@PostMapping("/enviarReporteMultiple")
	public ResponseEntity<?> enviarReporteMultiple(@RequestBody ReporteMultipleClienteDTO dto)
			throws MessagingException, IOException, TemplateException {

		String res = servicioReporte.enviarReporteMultiple(dto);
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@PostMapping("/enviarReporteUnico")
	public ResponseEntity<?> enviarReporteUnico(@RequestBody ReporteDetalleClienteDTO dto, Principal principal)
			throws MessagingException, IOException, TemplateException {

		String res = servicioReporte.enviarReporteUnico(dto, principal.getName());
		return new ResponseEntity<>(res, HttpStatus.OK);
	}

	@GetMapping("/getEmailsRegion/{region}")
	public ResponseEntity<?> getEmailsRegion(@PathVariable String region)
			throws MessagingException, IOException, TemplateException {

		List<MailInternoDTO> res = servicioReporte.getListaMailsInternos(region);
		return new ResponseEntity<>(res, HttpStatus.OK);
	}
	
	@GetMapping("/monitoreo")
  public ResponseEntity<?> exportarReporte(@RequestParam Map<String,String> dto) throws IOException {
		byte[] res = null;
		switch (dto.get("tipoReporte").toLowerCase()) {
		case "documentos":
			res = servicioReporte.reporteDocumento(dto);
			break;
		case "afectados":
			res = servicioReporte.reporteAfectados(dto);
			break;
		case "electrodependientes":
			res = servicioReporte.reporteElectrodependiente(dto);
			break;
		case "objetivo_llamadas":
			res = servicioReporte.reporteObjetivoLlamadas(dto);
			break;			
		case "reclamos":
			res = servicioReporte.reporteReclamos(dto);
			break;
		case "marcas":
			res = servicioReporte.reporteMarcas(dto);
			break;
		case "alertas":
			res = servicioReporte.reporteAlertas(dto);
			break;
		case "detalle_ge":
			res = servicioReporte.reporteGE(dto);
			break;
		case "llamadas":
			res = servicioReporte.reporteLlamadas(dto);
			break;
		case "Clientes Sin Tel":
			// 19/08/2022 rsleiva se agrega el reporte Clientes Sin Tel
			res = servicioReporte.reporteCliSinTel(dto);
		default:
			break;
		}
		
		if(res.length > 0) {
			HttpHeaders http = new HttpHeaders();
			http.add("Content-Type", "application/vnd.ms-excel");
			http.add("Content-Disposition", "attachment; filename=\"excel.xlsx\"");
			return new ResponseEntity<byte[]>(res, http, HttpStatus.OK);
		} else {
			return new ResponseEntity<>(null, HttpStatus.NOT_FOUND);
		}
		
	}
	
	@GetMapping("/getUsuariosOrigen")
  public ResponseEntity<?> getUsuariosNota() throws IOException {
		
	Map<String, Object> res = new HashMap<>();
	List<String> usuarios = servicioReporte.getUsuariosNota();
	res.put("usuarios", usuarios);
	List<String> origen = servicioReporte.getOrigenNota();
	res.put("origen", origen);
	return new ResponseEntity<>(res, HttpStatus.OK);
		
	}
	
	@GetMapping("/dashboard")
  public ResponseEntity<?> getDashboard() throws IOException {
		
	List<Map<String, Object>>	res = servicioReporte.getDashboard();
	return new ResponseEntity<>(res, HttpStatus.OK);
		
	}
}
