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

