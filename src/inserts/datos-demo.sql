-- EXISTE GRUPO DesarrolladoresTucuman
-- EXISTE PROYECTO RES - RedSocial
START TRANSACTION;

SELECT idgrupo INTO @idg FROM grupos WHERE nombre = 'DesarrolladoresTucuman';
SELECT idproyecto INTO @idp FROM proyectos WHERE nombre = 'RES - RedSocial';
SELECT @idg, @idp;

-- Planes de prueba del 1/03/2022 al 4/03/2022
INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-01 17:00:00','RES-001 Formulario de login','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1-Usuario existente','testing','',@idpp,@idp,@idg,'2022-03-01 17:00:00','2022-03-01 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('2-Usuario no existente','testing','',@idpp,@idp,@idg,'2022-03-01 17:00:00','2022-03-01 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('3-Campo de clave','testing','',@idpp,@idp,@idg,'2022-03-01 17:00:00','2022-03-01 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('4-Clave incorrecta','testing','',@idpp,@idp,@idg,'2022-03-01 17:00:00','2022-03-01 17:00:00',1);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-01 16:00:00','RES-050 Error de login','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Usuario existente','testing','',@idpp,@idp,@idg,'2022-03-01 16:00:00','2022-03-01 16:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Usuario no existente','testing','',@idpp,@idp,@idg,'2022-03-01 16:00:00','2022-03-01 16:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Campo de clave','testing','',@idpp,@idp,@idg,'2022-03-01 16:00:00','2022-03-01 16:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Clave incorrecta','testing','',@idpp,@idp,@idg,'2022-03-01 16:00:00','2022-03-01 16:00:00',1);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-02 16:00:00','RES-100 Vincular cuenta de Google','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Boton de Google Auth','testing','',@idpp,@idp,@idg,'2022-03-02 16:00:00','2022-03-02 16:00:00',3);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Registro existoso','testing','',@idpp,@idp,@idg,'2022-03-02 16:00:00','2022-03-02 16:00:00',3);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Registro sin mail valido','testing','',@idpp,@idp,@idg,'2022-03-02 16:00:00','2022-03-02 16:00:00',3);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-03 17:30:00','RES-120 Funcionalidad cambiar clave','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1-Redireccion','testing','',@idpp,@idp,@idg,'2022-03-03 17:30:00','2022-03-03 17:30:00',2);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('2-Clave valida','testing','',@idpp,@idp,@idg,'2022-03-03 17:30:00','2022-03-03 17:30:00',2);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('3-Clave invalida','testing','',@idpp,@idp,@idg,'2022-03-03 17:30:00','2022-03-03 17:30:00',2);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('4-Mail invalido','testing','',@idpp,@idp,@idg,'2022-03-03 17:30:00','2022-03-03 17:30:00',2);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-03 18:00:00','RES-150 Cambiar diseño login','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1-Nuevo diseño','testing','',@idpp,@idp,@idg,'2022-03-03 18:00:00','2022-03-03 18:00:00',3);

INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-03 18:30:00','RES-170 Corregir errores I','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'LOGIN');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1-Error 400','testing','',@idpp,@idp,@idg,'2022-03-03 18:30:00','2022-03-03 18:30:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('2-Error de timeout','testing','',@idpp,@idp,@idg,'2022-03-03 18:30:00','2022-03-03 18:30:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('3-Error 403','testing','',@idpp,@idp,@idg,'2022-03-03 18:30:00','2022-03-03 18:30:00',1);


-- Planes de prueba del 14/03/2022 al 18/03/2022
INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-14 17:00:00','RES-350 Menu lateral','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'NAVEGACION');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Responsiveness','testing','',@idpp,@idp,@idg,'2022-03-14 17:00:00','2022-03-14 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Opciones 1','testing','',@idpp,@idp,@idg,'2022-03-14 17:00:00','2022-03-14 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Opciones 2','testing','',@idpp,@idp,@idg,'2022-03-14 17:00:00','2022-03-14 17:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Opciones 3','testing','',@idpp,@idp,@idg,'2022-03-14 17:00:00','2022-03-14 17:00:00',1);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-15 16:00:00','RES-353 Navegabilidad menu','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'NAVEGACION');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Responsiveness','testing','',@idpp,@idp,@idg,'2022-03-15 16:00:00','2022-03-15 16:00:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('Opciones 1','testing','',@idpp,@idp,@idg,'2022-03-15 16:00:00','2022-03-15 16:00:00',1);

INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-16 17:30:00','RES-400 Opciones de usuario','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'NAVEGACION');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1- Ir a usuario','testing','',@idpp,@idp,@idg,'2022-03-16 17:30:00','2022-03-16 17:30:00',1);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('2- Roles','testing','',@idpp,@idp,@idg,'2022-03-16 17:30:00','2022-03-16 17:30:00',1);


INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`) VALUES('2022-03-18 18:00:00','RES-420 Corregir errores menu','Testing',@idg,@idp);
SELECT LAST_INSERT_ID() INTO @idpp;
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'REDSOCIAL');
CALL `AddTagToTestplan`(@idg, @idp, @idpp, 'NAVEGACION');
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('1-Responsiveness','testing','',@idpp,@idp,@idg,'2022-03-18 18:00:00','2022-03-18 18:00:00',3);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('2-Tamaño de fuente','testing','',@idpp,@idp,@idg,'2022-03-18 18:00:00','2022-03-18 18:00:00',3);
INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`) VALUES ('3-Componentes','testing','',@idpp,@idp,@idg,'2022-03-18 18:00:00','2022-03-18 18:00:00',3);

COMMIT;