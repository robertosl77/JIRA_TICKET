import React from "react";
import { withRouter } from "react-router-dom";
import { axiosGet, axiosGetParamsExcel } from "../Utilities/AxiosCalls";
import {
  GET_LISTA_LOCALIDADES,
  GET_REPORTES_MONITOREO,
  GET_USUARIOS_ORIGEN_NOTA,
} from "../Utilities/Constants";
import swal from "@sweetalert/with-react";
import { Button, Col, Form, FormGroup, Input, Label, Row, Spinner } from "reactstrap";
import download from "downloadjs";

class VistaReporteMonitoreo extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      tipoReporte: "Documentos",
      fechaInicio: "",
      fechaFin: "",
      duracion: 0,
      loading: false,
      cuenta: "",
      region: "",
      zona: "",
      partido: "",
      localidad: "",
      motivo: "",
      submotivo: "",
      listaLocalidades: [],
      estado: "",
      listaUsuarios: [],
      usuario: "",
      origen: "",
      listaOrigen: [],
    };
  }

  async componentDidMount() {
    let res = await axiosGet(GET_USUARIOS_ORIGEN_NOTA);
    if (res.status === 200) {
      this.setState({
        listaUsuarios: res.data.usuarios.map((u) => <option key={u}>{u}</option>),
        listaOrigen: res.data.origen.map((o) => <option key={o}>{o}</option>),
      });
    }
  }

  reformatDate(dateStr) {
    let dArr = dateStr.split("-"); // ex input "2010-01-18"
    return dArr[2] + "/" + dArr[1] + "/" + dArr[0]; //ex out: "18/01/10"
  }

  async procesarReporte() {
    const dto = {
      tipoReporte: this.state.tipoReporte,
      fechaInicio: this.reformatDate(this.state.fechaInicio),
      fechaFin: this.reformatDate(this.state.fechaFin),
      duracion: this.state.duracion,
      cuenta: this.state.cuenta,
      region: this.state.region,
      partido: this.state.partido,
      zona: this.state.zona,
      localidad: this.state.localidad,
      motivo: this.state.motivo,
      submotivo: this.state.submotivo,
      estado: this.state.estado,
      usuario: this.state.usuario,
      origen: this.state.origen,
    };
    await this.setState({ loading: true });
    const res = await axiosGetParamsExcel(GET_REPORTES_MONITOREO, dto);
    if (res.status !== 200) {
      swal("Error", "Ha ocurrido un error", "error");
      await this.setState({ loading: false });
      return;
    }
    const nombre =
      "GELEC_" +
      this.state.tipoReporte.toUpperCase() +
      "_" +
      this.state.fechaInicio +
      "_" +
      this.state.fechaFin +
      ".xlsx";
    download(
      new Blob([res.data], { type: "application/vnd.ms-excel" }),
      nombre,
      "application/vnd.ms-excel"
    );
    await this.setState({ loading: false });
  }

  changePartido(e) {
    const id = e.target.id;
    const value = e.target.value;

    if (value !== "") {
      axiosGet(GET_LISTA_LOCALIDADES + e.target.value).then((res) => {
        if (res.status === 200) {
          this.setState({
            listaLocalidades: res.data,
            [id]: value,
            localidad: "",
          });
        }
      });
    } else {
      this.setState({
        listaLocalidades: [],
        [id]: value,
        localidad: "",
      });
    }
  }

  render() {
    let listaLocalidades = this.state.listaLocalidades.map((entry) => {
      return <option>{entry}</option>;
    });
    return (
      <div className="col-6 mx-auto">
        <div className="d-flex flex-column rounded shadow-sm bg-white p-3">
          <h4>Reportes de monitoreo</h4>
          <Form className="pl-3 pt-4 bg-white">
            <Row form>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Tipo de reporte:</Label>
                  <Input
                    value={this.state.tipoReporte}
                    onChange={(e) => this.setState({ tipoReporte: e.target.value })}
                    type="select"
                    // this.state.fechaInicio.disabled=false
                  >
                    <option>Documentos</option>
                    <option>Clientes Sin Tel</option>
                    <option>Afectados</option>
                    <option>Electrodependientes</option>
                    <option>Llamadas</option>
                    <option>Objetivo_llamadas</option>
                    <option>Reclamos</option>
                    <option>Detalle_GE</option>
                    <option>Marcas</option>
                    <option>Alertas</option>

                  </Input>
                </FormGroup>
              </Col>
              {/* 19/08/2022 rsleiva oculto fecha de inicio en Clientes sin tel */}
              <Col sm={4} hidden={this.state.tipoReporte === "Marcas" || this.state.tipoReporte === "Clientes Sin Tel"}>
                <FormGroup>
                  <Label>
                    Fecha inicio:<span className="campo-requerido">*</span>
                  </Label>
                  <Input
                    value={this.state.fechaInicio}
                    onChange={(e) => this.setState({ fechaInicio: e.target.value })}
                    type="date"
                  />
                </FormGroup>
              </Col>
              {/* 19/08/2022 rsleiva oculto fecha de fin en Clientes sin tel */}
              <Col sm={4} hidden={this.state.tipoReporte === "Marcas" || this.state.tipoReporte === "Clientes Sin Tel"}>
                <FormGroup>
                  <Label>
                    Fecha fin:<span className="campo-requerido">*</span>
                  </Label>
                  <Input
                    value={this.state.fechaFin}
                    onChange={(e) => this.setState({ fechaFin: e.target.value })}
                    type="date"
                  />
                </FormGroup>
              </Col>
            </Row>
         
            <Row form hidden={this.state.tipoReporte !== "Documentos"}>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Duración:</Label>
                  <Input
                    value={this.state.duracion}
                    onChange={(e) => this.setState({ duracion: e.target.value })}
                    type="number"
                  />
                </FormGroup>
              </Col>
            </Row>
            <Row form hidden={this.state.tipoReporte !== "Electrodependientes"}>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">
                    Cuenta:<span className="campo-requerido">*</span>
                  </Label>
                  <Input
                    value={this.state.cuenta}
                    onChange={(e) => this.setState({ cuenta: e.target.value })}
                    type="text"
                  />
                </FormGroup>
              </Col>
            </Row>
            <Row
              form
              hidden={this.state.tipoReporte !== "Marcas" && this.state.tipoReporte !== "Llamadas"}
            >
              <Col
                sm={4}
                hidden={
                  this.state.tipoReporte !== "Marcas" && this.state.tipoReporte !== "Llamadas" 
                }
              >
                <FormGroup className="">
                  <Label className="">Región:</Label>
                  <Input
                    value={this.state.region}
                    onChange={(e) => this.setState({ region: e.target.value })}
                    type="text"
                  />
                </FormGroup>
              </Col>
              <Col sm={4} hidden={this.state.tipoReporte !== "Marcas"}>
                <FormGroup className="">
                  <Label className="">Partido:</Label>
                  <Input
                    id="partido"
                    value={this.state.partido}
                    onChange={(e) => this.changePartido(e)}
                    type="select"
                  >
                    <option></option>
                    <option>3 De Febrero</option>
                    <option>Capital Federal</option>
                    <option>Escobar</option>
                    <option>Gral Las Heras</option>
                    <option>Gral Rodriguez</option>
                    <option>Gral San Martin</option>
                    <option>Hurlingham</option>
                    <option>Ituzaingo</option>
                    <option>Jose C Paz</option>
                    <option>La Matanza</option>
                    <option>Malvinas Argentinas</option>
                    <option>Marcos Paz</option>
                    <option>Merlo</option>
                    <option>Moreno</option>
                    <option>Moron</option>
                    <option>Pilar</option>
                    <option>San Fernando</option>
                    <option>San Isidro</option>
                    <option>San Miguel</option>
                    <option>Tigre</option>
                    <option>Vicente Lopez</option>
                  </Input>
                </FormGroup>
              </Col>
              <Col sm={4} hidden={this.state.tipoReporte !== "Marcas"}>
                <FormGroup className="">
                  <Label className="">Localidad:</Label>
                  <Input
                    value={this.state.localidad}
                    onChange={(e) => this.setState({ localidad: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    {listaLocalidades}
                  </Input>
                </FormGroup>
              </Col>
              <Col sm={4} hidden={this.state.tipoReporte !== "Llamadas"}>
                <FormGroup className="">
                  <Label className="">Zona:</Label>
                  <Input
                    value={this.state.zona}
                    onChange={(e) => this.setState({ zona: e.target.value })}
                    type="text"
                  />
                </FormGroup>
              </Col>
            </Row>
            <Row form hidden={this.state.tipoReporte !== "Marcas"}>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Motivo:</Label>
                  <Input
                    value={this.state.motivo}
                    onChange={(e) => this.setState({ motivo: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    <option>BAJA POTENCIAL</option>
                    <option>CALIDAD DE PRODUCTO</option>
                    <option>CALIDAD DE SERVICIO</option>
                    <option>CLIENTE</option>
                    <option>CLIENTE MULTIPLE</option>
                    <option>FAE</option>
                    <option>INMUEBLE</option>
                    <option>MEDIDOR AMI</option>
                    <option>REVISION DE RED</option>
                  </Input>
                </FormGroup>
              </Col>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Submotivo:</Label>
                  <Input
                    value={this.state.submotivo}
                    onChange={(e) => this.setState({ submotivo: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    <option>ADECUAR ACOMETIDA</option>
                    <option>BAJA TENSION</option>
                    <option>CASA</option>
                    <option>CENSO</option>
                    <option>CLIENTE MULTIPLE</option>
                    <option>CRITICO</option>
                    <option>EDIFICIO</option>
                    <option>FALLECIDO</option>
                    <option>FUERA AREA CONCESION</option>
                    <option>MUDANZA</option>
                    <option>NO EDP</option>
                    <option>OSCILACIONES</option>
                    <option>POSEE FAE</option>
                    <option>POSEE MEDIDOR AMI</option>
                    <option>RECENSAR</option>
                    <option>REQUIERE FAE</option>
                    <option>REQUIERE MEDIDOR AMI</option>
                    <option>SALIDORES</option>
                    <option>SOBRE TENSION</option>
                    <option>TERMINADO</option>
                    <option>VERIFICAR CT</option>
                  </Input>
                </FormGroup>
              </Col>
            </Row>
            <Row form hidden={this.state.tipoReporte !== "Alertas"}>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Estado:</Label>
                  <Input
                    value={this.state.estado}
                    onChange={(e) => this.setState({ estado: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    <option>Activa</option>
                    <option>Inactiva</option>
                  </Input>
                </FormGroup>
              </Col>
            </Row>
            <Row form hidden={this.state.tipoReporte !== "Llamadas"}>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Usuario:</Label>
                  <Input
                    value={this.state.usuario}
                    onChange={(e) => this.setState({ usuario: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    {this.state.listaUsuarios}
                  </Input>
                </FormGroup>
              </Col>
              <Col sm={4}>
                <FormGroup className="">
                  <Label className="">Origen:</Label>
                  <Input
                    value={this.state.origen}
                    onChange={(e) => this.setState({ origen: e.target.value })}
                    type="select"
                  >
                    <option></option>
                    {this.state.listaOrigen}
                  </Input>
                </FormGroup>
              </Col>
            </Row>
          </Form>
          <div className="d-flex flex-row-reverse">
            <Button
              // 19/08/2022 rsleiva si selecciono clientes sin tel habilito el boton reporte
              disabled={
                (this.state.tipoReporte !== "Marcas") &&
                (this.state.tipoReporte !== "Clientes Sin Tel") &&
                (this.state.loading ||
                  this.state.fechaInicio === "" ||
                  this.state.fechaFin === "" ||
                  (this.state.tipoReporte === "Electrodependientes" && this.state.cuenta === "")
                )
              }
              onClick={() => this.procesarReporte()}
              color="primary"
            >
              {this.state.loading ? <Spinner color="dark" size="sm" /> : "Procesar"}
            </Button>
          </div>
        </div>
      </div>
    );
  }
}

export default withRouter(VistaReporteMonitoreo);
