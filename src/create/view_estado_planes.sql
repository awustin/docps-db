CREATE VIEW `estado_planes` AS
    SELECT 
    pp.idgrupo,
    pp.idproyecto,
    pp.idplan,
    pp.nombre
    , count(idejecucion) AS numEjecuciones
    , group_concat(e.estado) AS estados
    , CASE WHEN count(idejecucion) = 0
		THEN 'Not executed'
        ELSE (
			CASE WHEN 1 IN (
			SELECT e2.estado FROM ejecuciones e2
			RIGHT JOIN planes pp2 ON e2.idgrupo = pp2.idgrupo AND e2.idproyecto = pp2.idproyecto AND e2.idplan = pp2.idplan
            WHERE pp.idgrupo = pp2.idgrupo AND pp.idproyecto = pp2.idproyecto AND pp.idplan = pp2.idplan
            ) 
				THEN 'In progress'
				ELSE 
                (
					CASE WHEN 2 = ALL ( SELECT e2.estado FROM ejecuciones e2
					RIGHT JOIN planes pp2 ON e2.idgrupo = pp2.idgrupo AND e2.idproyecto = pp2.idproyecto AND e2.idplan = pp2.idplan
					WHERE pp.idgrupo = pp2.idgrupo AND pp.idproyecto = pp2.idproyecto AND pp.idplan = pp2.idplan 
					) 
						THEN 'Passed'
						ELSE 'Failed'
					END
				)
                END
        )
	END AS status
    FROM ejecuciones e
    RIGHT JOIN planes pp ON e.idgrupo = pp.idgrupo AND e.idproyecto = pp.idproyecto AND e.idplan = pp.idplan 
    GROUP BY pp.idgrupo,pp.idproyecto,pp.idplan;
		
-- VIEW ESTADO CASOS
SELECT 
	CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS caso
    ,cp.nombre
    ,MAX(e.fecha_ejecucion) fecha_ultima_ejecucion
    ,MAX(e.idejecucion) id_ultima_ejecucion
    ,CASE WHEN e.estado IS NULL THEN
		'Not executed'
	ELSE
		CASE WHEN 1 IN ( SELECT e2.estado FROM ejecuciones e2
						RIGHT JOIN casos_prueba cp2 ON e2.idgrupo = cp2.idgrupo AND e2.idproyecto = cp2.idproyecto AND e2.idplan = cp2.idplan AND e2.idcaso = cp2.idcaso
						WHERE cp.idgrupo = cp2.idgrupo AND cp.idproyecto = cp2.idproyecto AND cp.idplan = cp2.idplan AND cp.idcaso = cp2.idcaso
                        ) THEN
			'In progress'
		ELSE
			CASE WHEN 2 = ( SELECT e2.estado FROM ejecuciones e2
						RIGHT JOIN casos_prueba cp2 ON e2.idgrupo = cp2.idgrupo AND e2.idproyecto = cp2.idproyecto AND e2.idplan = cp2.idplan AND e2.idcaso = cp2.idcaso
						WHERE cp.idgrupo = cp2.idgrupo AND cp.idproyecto = cp2.idproyecto AND cp.idplan = cp2.idplan AND cp.idcaso = cp2.idcaso
                        ORDER BY e2.fecha_ejecucion DESC LIMIT 1
                        ) THEN
				'Passed'
			ELSE
				'Failed'
			END
		END
	END AS estado_del_caso
FROM casos_prueba cp
LEFT JOIN ejecuciones e ON (e.idgrupo = cp.idgrupo AND e.idproyecto = cp.idproyecto AND cp.idplan = e.idplan AND cp.idcaso = e.idcaso)
GROUP BY caso
ORDER BY caso ASC, e.fecha_ejecucion DESC
;