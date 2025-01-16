--Berechnung Streckenlänge
-- Die Route wird durch Klicks auf der Karte definiert und als GeoJSON an die Datenbank gesendet.
--Das Ergebnis wird zurück an die HTML/JavaScript-Anwendung gesendet um es anzuzeigen
--linestring wird übergeben
CREATE OR REPLACE FUNCTION calculate_route_length(route GEOMETRY)
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN ST_Length(route::geography);
END;
$$ LANGUAGE plpgsql;


--nur gebiet konstanz berücksichtigen

CREATE OR REPLACE FUNCTION get_traffic_signals_along_route(p_route GEOMETRY, search_radius DOUBLE PRECISION)
RETURNS TABLE(signal_geom GEOMETRY, signal_id BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ST_Transform(way, 4326) AS signal_geom,
        osm_id AS signal_id
    FROM
        osm.planet_osm_point
    WHERE
        highway = 'traffic_signals'
        AND ST_DWithin(
            way,
            ST_Transform(p_route, 3857),
            search_radius
        )
        AND ST_Within(
            way,
            ST_MakeEnvelope(9.1221, 47.6450, 9.2250, 47.7100, 4326) -- Gebiet von Konstanz
        );
END;
$$ LANGUAGE plpgsql;











SELECT osm_id, ST_AsGeoJSON(way) AS geom
FROM osm.planet_osm_point
WHERE highway = 'traffic_signals'
  AND ST_Within(
      way,
      ST_MakeEnvelope(9.1221, 47.6450, 9.2250, 47.7100, 4326) -- Bounding Box für Konstanz
  );






CREATE OR REPLACE FUNCTION get_traffic_signals_along_route(p_route GEOMETRY)
RETURNS TABLE(signal_geom GEOMETRY, signal_id BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT ST_AsGeoJSON(way) AS signal_geom, osm_id AS signal_id
    FROM osm.planet_osm_point
    WHERE highway = 'traffic_signals'
      AND ST_DWithin(
          way,
          ST_Transform(p_route, 3857),
          100 -- Hier wird der Radius festgelegt, z. B. 100 Meter
      );
END;
$$ LANGUAGE plpgsql;
-- Beispiel: Linie als Route definieren


SELECT *
FROM get_traffic_signals_along_route(
    ST_GeomFromText('LINESTRING(9.17659 47.65774, 9.17979 47.66778)', 4326) -- Route im WGS84-Format
);








SELECT osm_id, ST_AsGeoJSON(way) AS geom
FROM osm.planet_osm_point
WHERE highway = 'traffic_signals'
  AND ST_DWithin(
      way,
      ST_Transform(
          ST_SetSRID(
              ST_GeomFromText('LINESTRING(9.17659 47.65774, 9.17979 47.66778)'), 4326
          ), 3857
      ),
50
);


SELECT COUNT(*) AS traffic_signal_count
FROM osm.planet_osm_point
WHERE highway = 'traffic_signals'
  AND ST_DWithin(
      way,
      ST_Transform(
          ST_SetSRID(
              ST_GeomFromText('LINESTRING(9.17659 47.65774, 9.17979 47.66778)'), 4326
          ), 3857
      ),
      50
  );


CREATE OR REPLACE FUNCTION count_traffic_signals_along_route(
    p_route GEOMETRY,
    search_radius DOUBLE PRECISION
)
RETURNS INTEGER AS $$
DECLARE
    traffic_signal_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO traffic_signal_count
    FROM osm.planet_osm_point
    WHERE highway = 'traffic_signals'
      AND ST_DWithin(
          way,
          ST_Transform(p_route, 3857),
          search_radius
      );

    RETURN traffic_signal_count;
END;
$$ LANGUAGE plpgsql;


SELECT count_traffic_signals_along_route(
    ST_GeomFromText('LINESTRING(9.17659 47.65774, 9.17979 47.66778)', 4326),
    50
);






CREATE OR REPLACE FUNCTION get_nearby_traffic_signals(
    line_geometry TEXT,
    buffer_distance DOUBLE PRECISION,
    highway_type TEXT
)
RETURNS TABLE (
    osm_id BIGINT,
    geom JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        osm_id,
        ST_AsGeoJSON(way) AS geom
    FROM
        osm.planet_osm_point
    WHERE
        highway = highway_type
        AND ST_DWithin(
            way,
            ST_Transform(
                ST_SetSRID(
                    ST_GeomFromText(line_geometry), 4326
                ),
                3857
            ),
            buffer_distance
        );
END;
$$ LANGUAGE plpgsql;


SELECT *
FROM get_nearby_traffic_signals(
    'LINESTRING(9.17659 47.65774, 9.17979 47.66778)',
    50,
    'traffic_signals'
);

