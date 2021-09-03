-- PROJECTS STORED PROCEDURES


USE `docps-dev`;
DROP procedure IF EXISTS `GetGroupsDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetGroupsDropdown` (
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
		g.idgrupo AS `key`,
        g.nombre AS name
	FROM grupos g
    JOIN usuarios_grupos ug ON ug.idgrupo = g.idgrupo
    WHERE ug.idusuario = id;
END$$
DELIMITER ;