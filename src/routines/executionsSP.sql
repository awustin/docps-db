-- EXECUTIONS STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `GetExecutionsForTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetExecutionsForTestcase` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT
		CONCAT(e.idgrupo,'.',e.idproyecto,'.',e.idplan,'.',e.idcaso,'.',idejecucion) AS id,
        CASE WHEN e.idestadoejecucion IS NULL THEN
			'Not executed'
		ELSE
			s.nombre
		END AS `status`,
        e.comentario AS commentary,
        DATE_FORMAT(e.fecha_ejecucion, '%Y-%m-%d') AS createdOn
	FROM ejecuciones e
    LEFT JOIN estado_ejecuciones s ON e.idestadoejecucion = s.idestadoejecucion
    WHERE e.idgrupo = idg
    AND e.idproyecto = idp
    AND e.idplan = idpp
    AND e.idcaso = idc
    ORDER BY e.fecha_ejecucion DESC;
END$$
DELIMITER ;

USE `docps-dev`;
DROP procedure IF EXISTS `InsertExecution`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertExecution` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER,
    IN idu INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
        INSERT INTO `docps-dev`.`ejecuciones`(`idcaso`,`idplan`,`idproyecto`,`idgrupo`,`idusuario`,`fecha_ejecucion`)
		VALUES(idc,idpp,idp,idg,idu,SYSDATE());

	COMMIT;		
        SELECT 'EXECUTION CREATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateExecutionById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateExecutionById` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER,
    IN ide INTEGER,
    IN comm VARCHAR(512),
    IN idestado INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;        
		IF idestado = 0 THEN
			UPDATE `docps-dev`.`ejecuciones`
			SET `comentario` = comm,`fecha_ejecucion` = SYSDATE(),`idestadoejecucion` = NULL
			WHERE `idejecucion` = ide
			AND `idcaso` = idc
			AND `idplan` = idpp
			AND `idproyecto` = idp
			AND `idgrupo` = idg;
		ELSE        
			UPDATE `docps-dev`.`ejecuciones`
			SET `comentario` = comm,`fecha_ejecucion` = SYSDATE(),`idestadoejecucion` = idestado
			WHERE `idejecucion` = ide
			AND `idcaso` = idc
			AND `idplan` = idpp
			AND `idproyecto` = idp
			AND `idgrupo` = idg;        
        END IF;
	COMMIT;		
        SELECT 'EXECUTION UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteExecutionById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteExecutionById` (
	IN `idg` INTEGER,
    IN `idp` INTEGER,
    IN `idpp` INTEGER,
    IN `idc` INTEGER,
    IN `ide` INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
	
	START TRANSACTION;
		DELETE FROM `docps-dev`.`ejecuciones` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp AND idcaso = idc AND idejecucion = ide;		
	COMMIT;
		SELECT 'EXECUTION DELETED' AS message, 1 AS success;
END$$
DELIMITER ;