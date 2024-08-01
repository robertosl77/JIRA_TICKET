import React from "react";
import { Col, Button, Form, FormGroup, Label, Input, Row } from "reactstrap";
import { changeHandler } from "../Utilities/UtilityFunctions";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEdit } from "@fortawesome/free-solid-svg-icons";

export default class EditForm extends React.Component {
  constructor(props) {
    super(props);

    this.changeHandler = changeHandler.bind(this);

    this.state = {
      status: "",
      solution: "",
      note: "",
      noteType: "Nota",
      efectivo: "1",
      fechaFinEditable: "",
    };
  }

  componentWillReceiveProps(props) {
    if (this.state.noteType === "Cliente" && props.selectedClientsLenght === 0) {
      this.setState({
        noteType: "Nota",
      });
    }
  }

  noteTypeClickHandler(e) {
    this.changeHandler(e);
    this.props.listenNoteTypeChanges(e.target.value);
  }

  editarRegistros(e, state) {
    this.props.onSubmitMethod(e, state);
    this.setState({
      status: "",
      solution: "",
      note: "",
      noteType: "Nota",
      efectivo: "1",
      fechaFinEditable: "",
    });
  }

  render() {
    let hasData = false;

    let notaContacto = false;
    switch (this.state.noteType) {
      case "Cliente":
      case "Zona":
      case "Despacho BT":
      case "Despacho MT":
        notaContacto = true;
        break;
      default:
        break;
    }
    if (
      this.props.selectedClientsLenght !== 0 &&
      (this.state.status !== "" ||
      this.state.solution !== "" ||
      this.state.note !== "" ||
      this.state.fechaFinEditable !== "") &&
      ((notaContacto && this.props.selectedContact.telefono !== undefined) || !notaContacto)
    ) {
      hasData = true;
    }

    let showClientContactOption = null;
    if (this.props.selectedClientsLenght === 1) {
      showClientContactOption = <option>Cliente</option>;
    }
    return (
      <>
        <Form>
          <Row form>
            <Col md={3}>
              <FormGroup>
                <Label className="" for="status">
                  Estado
                </Label>
                <Input
                  value={this.state.status}
                  tabIndex={1}
                  type="select"
                  name="select"
                  id="status"
                  onChange={(e) => this.changeHandler(e)}
                >
                  <option></option>
                  <option>Pendiente</option>
                  <option>Anomalia</option>
                  <option>Atendido</option>
                  <option>Provisorio</option>
                  <option>Seguimiento</option>
                  <option>Con Suministro</option>
                  <option>Cancelado</option>
                  <option>Normalizado</option>
                </Input>
              </FormGroup>
            </Col>
            <Col sm={3}>
              <FormGroup>
                <Label for="solution" className="">
                  Solución Provisoria
                </Label>
                <Input
                  value={this.state.solution}
                  tabIndex={2}
                  type="select"
                  name="select"
                  id="solution"
                  className=""
                  onChange={(e) => this.changeHandler(e)}
                >
                  <option></option>
                  <option>Autonomía</option>
                  <option>Desafectado</option>
                  <option>En Proceso</option>
                  <option>FAE</option>
                  <option>GE CT</option>
                  <option>GE Propio</option>
                  <option>GE Puntual</option>
                  <option>No Requerido</option>
                  <option>Rellamar</option>
                  <option>Traslado</option>
                </Input>
              </FormGroup>
            </Col>
            <Col sm={4}>
              <FormGroup>
                <Label for="fin" className="">
                  Fecha Fin
                </Label>
                <Input
                  value={this.state.fechaFinEditable}
                  tabIndex={3}
                  type="datetime-local"
                  name="select"
                  id="fechaFinEditable"
                  className=""
                  // onDoubleClick={
                  //   () => {
                  //     this.setState({
                  //       fechaFinEditable:
                  //         new Date().toISOString().substr(0, 11) +
                  //         new Date().toLocaleTimeString().padStart(8, "0"),
                  //     });
                  //   }
                  // }
                  //         //08/08/2022 rsleiva cambio propuesto para SOT-14023
                  onDoubleClick={
                    () => {
                      this.setState({
                        fechaFinEditable: 
                          new Date().toISOString().toLocaleString('es-AR', {timeZone: 'America/Argentina/Buenos_Aires'}).substring(0,11)
                          + new Date().toLocaleTimeString().padStart(8, "0")
                      });
                    }
                  }
                  onChange={(e) => this.changeHandler(e)}
                />
              </FormGroup>
            </Col>
          </Row>
          <Row form>
            <Col sm={3}>
              <FormGroup>
                <Label for="note">Tipo de nota</Label>
                <Input
                  value={this.state.noteType}
                  tabIndex={4}
                  type="select"
                  name="text"
                  id="noteType"
                  onChange={(e) => {
                    this.noteTypeClickHandler(e);
                  }}
                >
                  <option>Nota</option>
                  {showClientContactOption}
                  <option>Zona</option>
                  <option>Despacho BT</option>
                  <option>Despacho MT</option>
                  <option>Documentacion tecnica</option>
                  <option>Movil</option>
                </Input>
              </FormGroup>
            </Col>
            <Col sm={9}>
              <FormGroup>
                <Label for="note">Nota</Label>
                <Row form>
                  <Col sm={6}>
                    <Input
                      value={this.state.note}
                      tabIndex={5}
                      type="textarea"
                      style={{ height: "110px" }}
                      maxLength="250"
                      name="text"
                      id="note"
                      onChange={(e) => this.changeHandler(e)}
                      placeholder="Ingrese nota"
                    />
                  </Col>
                  <Col sm={6}>
                    <FormGroup
                      check
                      inline
                      hidden={this.state.noteType === "Cliente" ? false : true}
                    >
                      {/* DEJAR MISMO ID */}
                      <Input
                        className="ml-3"
                        type="radio"
                        id="efectivo"
                        checked={this.state.efectivo === "1"}
                        value="1"
                        onClick={(e) => this.changeHandler(e)}
                      />
                      Efectivo
                      <Input
                        className="ml-3"
                        type="radio"
                        id="efectivo"
                        checked={this.state.efectivo === "0"}
                        value="0"
                        onClick={(e) => this.changeHandler(e)}
                      />
                      No
                    </FormGroup>
                  </Col>
                </Row>
              </FormGroup>
              <Button
                color="warning"
                size="sm"
                tabIndex={7}
                className="no-outline float-right"
                onClick={(e) => this.editarRegistros(e, this.state)}
                disabled={!hasData}
              >
                <FontAwesomeIcon icon={faEdit} size="lg" /> Editar
              </Button>
              <Button
                color="info"
                size="sm"
                tabIndex={6}
                className="float-right mr-2"
                onClick={() => {
                  this.setState({
                    status: "",
                    solution: "",
                    note: "",
                    noteType: "Nota",
                    efectivo: "1",
                    fechaFinEditable: "",
                  });
                  this.props.listenNoteTypeChanges("Nota");
                }}
              >
                Limpiar
              </Button>
            </Col>
          </Row>
        </Form>
      </>
    );
  }
}
