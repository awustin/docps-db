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