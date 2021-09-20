USE `docps-dev`;
DROP procedure IF EXISTS `GetTestcaseById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestcaseById` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
	IN idcaso INTEGER
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
		CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS id
        ,cp.nombre AS testcaseName
        ,cp.descripcion AS description
        ,cp.precondiciones AS preconditions
        ,pr.nombre AS priority
        ,DATE_FORMAT(cp.fecha_ultima_modificacion, '%Y-%m-%d') AS modifiedOn
        ,CAST(cp.exportado AS UNSIGNED) AS isExported
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan) AS testplanId
        ,pp.nombre AS testplanName
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto) AS projectId
        ,p.nombre AS projectName
        ,cp.idgrupo AS groupId
        ,g.nombre AS groupName
        ,pa.accion AS stAction
        ,pa.resultado AS stResult
        ,pa.datos AS stData
        ,pa.orden AS stOrder
        ,tv.nombre AS vType
        ,v.nombre AS vName
        ,v.valor AS vValues
	FROM casos_prueba cp
    JOIN planes pp ON pp.idgrupo = cp.idgrupo AND pp.idproyecto = cp.idproyecto AND pp.idplan = cp.idplan
    JOIN proyectos p ON cp.idgrupo = p.idgrupo AND cp.idproyecto = p.idproyecto 
    JOIN grupos g ON cp.idgrupo = g.idgrupo
    LEFT JOIN pasos pa ON pa.idgrupo = cp.idgrupo AND pa.idproyecto = cp.idproyecto AND pa.idplan = cp.idplan AND pa.idcaso = cp.idcaso
    LEFT JOIN variables v ON v.idgrupo = cp.idgrupo AND v.idproyecto = cp.idproyecto AND v.idplan = cp.idplan AND v.idcaso = cp.idcaso AND pa.idpaso = v.idpaso
    LEFT JOIN tipovariable tv ON tv.idtipov = v.idtipov
    LEFT JOIN prioridades pr ON cp.idprioridad = pr.idprioridad
    WHERE cp.idgrupo = idgrupo
    AND cp.idproyecto = idproyecto
    AND cp.idplan = idplan
    AND cp.idcaso = idcaso
    ORDER BY cp.idcaso, pa.idpaso, pa.orden    
    ;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertTestcase` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN nombre VARCHAR(255),
    IN precondiciones VARCHAR(512),
    IN prioridad INTEGER,
    IN descripcion VARCHAR(512)
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
        INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`)
		VALUES (nombre,descripcion,precondiciones,idplan,idproyecto,idgrupo,SYSDATE(),SYSDATE(),prioridad);

	COMMIT;
		SELECT  
			CONCAT(idgrupo,'.',idproyecto,'.',idplan,'.',idcaso) 
        INTO @id
        FROM casos_prueba c WHERE c.idgrupo = idgrupo AND c.idproyecto = idproyecto AND c.idplan = idplan AND c.idcaso = last_insert_id();
		
        SELECT 'TESTCASE CREATED' AS message, 1 AS success, @id AS id;
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `UpdateTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateTestcase` (
	IN `idgrupo` INTEGER,
    IN `idproyecto` INTEGER,
    IN `idplan` INTEGER,
    IN `idcaso` INTEGER,
	IN `nombre` VARCHAR(255),
	IN `descripcion` VARCHAR(255),
	IN `precondiciones` VARCHAR(255),
	IN `idprioridad` INTEGER
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
		UPDATE `docps-dev`.`casos_prueba` SET
		`nombre` = nombre,
		`descripcion` = descripcion,
		`precondiciones` = precondiciones,
		`idprioridad` = idprioridad,
		`fecha_ultima_modificacion` = SYSDATE(),
		`exportado` = 0
		WHERE `casos_prueba`.`idcaso` = idcaso 
		AND `casos_prueba`.`idplan` = idplan
		AND `casos_prueba`.`idproyecto` = idproyecto 
		AND `casos_prueba`.`idgrupo` = idgrupo;
	COMMIT;
		SELECT 'TESTCASE UPDATED' AS message
        , 1 AS success
        , nombre AS testcaseName
        , descripcion AS description
        , precondiciones AS preconditions
        , (SELECT p.nombre FROM prioridades p WHERE p.idprioridad = idprioridad) AS priority;
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `InsertStepWithVariables`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertStepWithVariables` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN idcaso INTEGER,
    IN acc VARCHAR(255),
    IN acc_var_n VARCHAR(255),
    IN acc_var_v VARCHAR(255),
    IN dat VARCHAR(255),
    IN dat_var_n VARCHAR(255),
    IN dat_var_v VARCHAR(255),
    IN res VARCHAR(255),
    IN res_var_n VARCHAR(255),
    IN res_var_v VARCHAR(255),
    IN ord INTEGER
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
        INSERT INTO `docps-dev`.`pasos`(`idcaso`,`idplan`,`idproyecto`,`idgrupo`,`accion`,`datos`,`resultado`,`orden`)
		VALUES(idcaso,idplan,idproyecto,idgrupo,acc,dat,res,ord);
        
        SET @nuevo_paso = last_insert_id();
		
        IF acc_var_n != '' AND acc_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(1,acc_var_n,acc_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
        END IF;

        IF dat_var_n != '' AND dat_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(3,dat_var_n,dat_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
		END IF;
        
        IF res_var_n != '' AND res_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(2,res_var_n,res_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
		END IF;
    COMMIT;		
        SELECT 'STEP CREATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteStepsAndVariables`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteStepsAndVariables` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN idcaso INTEGER
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
		DELETE FROM `docps-dev`.`variables` 
					WHERE `variables`.`idcaso`=idcaso
					AND `variables`.`idplan`=idplan
					AND `variables`.`idproyecto`=idproyecto
			AND  `variables`.`idgrupo`=idgrupo;
					
			DELETE FROM `docps-dev`.`pasos` 
					WHERE `pasos`.`idcaso`=idcaso
					AND `pasos`.`idplan`=idplan
					AND `pasos`.`idproyecto`=idproyecto
			AND  `pasos`.`idgrupo`=idgrupo;
	COMMIT;
		SELECT 'STEPS DELETED' AS message, 1 AS success;
END$$
DELIMITER ;