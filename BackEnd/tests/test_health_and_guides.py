"""Pruebas de salud del servicio y consulta de guías oficiales y glosario."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "pasoclaro-backend"}


def test_list_guides_and_glossary():
    response = client.get("/api/guides")
    assert response.status_code == 200
    data = response.json()

    assert "guides" in data
    assert "glossary" in data
    assert isinstance(data["guides"], list)
    assert isinstance(data["glossary"], list)

    guide_ids = {guide["id"] for guide in data["guides"]}
    expected_ids = {
        "salud_cita_clinica",
        "beca_apoyo_social",
        "educacion_beca_escolar",
        "empleo_servicio_nacional",
    }
    assert expected_ids.issubset(guide_ids)

    for guide in data["guides"]:
        assert guide["titulo"]
        assert guide["etiqueta_oficial"]
        assert isinstance(guide["requisitos"], list) and len(guide["requisitos"]) >= 1
        assert isinstance(guide["pasos"], list) and len(guide["pasos"]) >= 1
        assert isinstance(guide["canal_oficial"], dict)

    assert len(data["glossary"]) >= 15
    glossary_terms = {entry["termino_es"] for entry in data["glossary"]}
    required_base_terms = {
        "Identificación oficial (INE)",
        "CURP impresa",
        "Comprobante de domicilio",
        "Constancia de estudios",
    }
    assert required_base_terms.issubset(glossary_terms)

    for entry in data["glossary"]:
        assert entry["termino_es"]
        assert entry["yua"]
        assert entry["nah"]
        assert entry["explicacion_sencilla"]


def test_get_guide_by_id_success_and_not_found():
    found = client.get("/api/guides/salud_cita_clinica")
    assert found.status_code == 200
    guide = found.json()
    assert guide["id"] == "salud_cita_clinica"
    assert guide["tramite"] == "salud"
    assert isinstance(guide["requisitos"], list) and len(guide["requisitos"]) >= 3
    assert isinstance(guide["canal_oficial"], dict)

    missing = client.get("/api/guides/no_existe")
    assert missing.status_code == 404
