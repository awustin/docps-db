-- USERS STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `UserLogin`;

DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UserLogin` (
	IN username VARCHAR(255), 
  IN clave VARCHAR(255)
    )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT * FROM cuentas c WHERE c.username = username AND c.clave = clave;	
END$$

DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetGroupById`;

DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetGroupById` (
	IN id INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT 101 AS ID, 'Focas' AS NAME;	
END$$

DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetUserInfoById`;

DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetUserInfoById` (
	IN id INTEGER
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
		u.idusuario AS id,
		g.idgrupo AS groupid,
		g.nombre AS groupname,
		c.fecha_creacion AS createdOn,
		u.nombre AS name,
		u.apellido AS lastname,
		c.email AS email,
		CASE WHEN u.estado_alta = 1 THEN 'active' ELSE 'inactive' END AS status,
		c.username AS username,
		u.dni AS dni,
		u.calle AS street,
		u.num_calle AS streetNumber,
		u.direccion_extra AS addressExtra,
		u.puesto AS job,
		a.nombre AS image
	FROM usuarios u
	JOIN usuarios_grupos ug ON u.idusuario = ug.idusuario
	JOIN grupos g ON g.idgrupo = ug.idgrupo
	JOIN cuentas c ON u.idusuario = c.idusuario
	LEFT JOIN archivos a ON a.idarchivo = u.idarchivo_img
	WHERE u.idusuario = id
	;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertUser` (
	IN `email` VARCHAR(255),
	IN `username` VARCHAR(255),
	IN `clave` VARCHAR(255),
	IN `nombre` VARCHAR(255),
	IN `apellido` VARCHAR(255),
	IN `dni` VARCHAR(255),
	IN `calle` VARCHAR(255),
	IN `num_calle` VARCHAR(255),
	IN `direccion_extra` VARCHAR(255),
	IN `puesto` VARCHAR(255)
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
		INSERT INTO `docps-dev`.`usuarios`(`nombre`,`apellido`,`estado_alta`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`)
		VALUES(nombre,apellido,0,dni,calle,num_calle,direccion_extra,puesto);     
		INSERT INTO `docps-dev`.`cuentas`(`username`,`clave`,`email`,`fecha_creacion`,`idusuario`)
		VALUES(username,clave,email,SYSDATE(),1);
	COMMIT;
		SELECT 'USER CREATED' AS message, 1 AS success;
END$$
DELIMITER ;