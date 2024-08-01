CREATE OR REPLACE PACKAGE NEXUS_GIS.edenor_cartografia
AS
-----------------------------------------------------------------------------------------------------
-- VERSION 1.2
-- Version Cartografia: 4_5.35
-- Autor: Pablo Dobrila
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Registro de Moficaciones. Fecha/Autor/Descripcion.
-- 05092007 - pdobrila - Version Inicial
-- 14112007 - pdobrila - Incorporacion de las Funciones "get_objectid_localizacion" y "getdatosgeouni_localizacion"
-- 07042008- pdobrila - Incorporacion de funcion para formatear el codigo de los elementos de maniobra
-----------------------------------------------------------------------------------------------------
--Funcion que obtiene los datos geograficos de un elemento del Unifilar
   FUNCTION getdatosgeouni (p_objeto NUMBER)
      RETURN VARCHAR2;

--Funcion que obtiene los datos geograficos de un elemento del Unifilar a partir de la localizacion
   FUNCTION getdatosgeouni_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN VARCHAR2;

--Funcion que obtiene a partir de un elemento del unifilar, el objectid de la localizacion.
--No existe: 0
--Duplicado: -2
--Error generico: -1
   FUNCTION get_objectid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER;

--Funcion que obtiene los datos geograficos de un elemento del Geografico
   FUNCTION getdatosgeograficos (p_objeto NUMBER)
      RETURN VARCHAR2;

--Funcion que obtiene el areaid de su elemento de potencia correspondiente
   FUNCTION get_areaid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER;

--Funcion que obtiene la cantidad de clientes de un suministro
   FUNCTION getcantidadclientessuministro (p_objeto NUMBER)
      RETURN NUMBER;

--Funcion que obtiene la potencia instalad de un suministro
   FUNCTION getpotenciasuministro (p_objeto NUMBER)
      RETURN FLOAT;

--Funcion que recibe el codigo de un elemento de maniobra y lo formatea si es valido, sino devuelve nulo
   FUNCTION em_valid_code (p_code VARCHAR2)
      RETURN VARCHAR2;

--Funcion que recibe el codigo de CT y devuelve la fecha de alta del ultimo trafo
   FUNCTION get_date_trafo (p_ct VARCHAR2)
      RETURN VARCHAR2;
END edenor_cartografia;
/