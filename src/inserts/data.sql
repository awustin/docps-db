-- INSERT INTO `grupos` (`idgrupo`,`nombre`,`estado_alta`,`fecha_alta`,`fecha_baja`,`idarchivo_img`,`iddefavatar`) VALUES (1,'Panteras',1,'2021-04-13 21:00:00',NULL,NULL,1);
-- INSERT INTO `grupos` (`idgrupo`,`nombre`,`estado_alta`,`fecha_alta`,`fecha_baja`,`idarchivo_img`,`iddefavatar`) VALUES (2,'Lobos',1,'2021-05-10 20:00:00',NULL,NULL,2);
-- INSERT INTO `grupos` (`idgrupo`,`nombre`,`estado_alta`,`fecha_alta`,`fecha_baja`,`idarchivo_img`,`iddefavatar`) VALUES (3, 'Pumas', 1, '2021-05-10 20:00:00', NULL, NULL, 3);
INSERT INTO `grupos` (`idgrupo`,`nombre`,`estado_alta`,`fecha_alta`,`fecha_baja`,`idarchivo_img`,`iddefavatar`) VALUES (4,'Pintores',1,'2021-09-02 21:26:37',NULL,NULL,4);

-- INSERT INTO `usuarios` (`idusuario`,`nombre`,`apellido`,`estado_alta`,`fecha_alta`,`es_admin`,`idarchivo_img`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`) VALUES (1,'Agustin','Juan',1,'2021-04-13 21:00:00',1,NULL,'38900000','Calle1','1812','Barrio1','Software Engineer III');
-- INSERT INTO `usuarios` (`idusuario`,`nombre`,`apellido`,`estado_alta`,`fecha_alta`,`es_admin`,`idarchivo_img`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`) VALUES (2,'Admin','Test',1,'2021-04-13 21:00:00',1,NULL,'38900000','Calle1','1812','Barrio1','Software Engineer III');
INSERT INTO `usuarios` (`idusuario`,`nombre`,`apellido`,`estado_alta`,`fecha_alta`,`es_admin`,`idarchivo_img`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`) VALUES (3,'Gustav','Klimt',1,NULL,0,NULL,'35',NULL,NULL,NULL,NULL);
INSERT INTO `usuarios` (`idusuario`,`nombre`,`apellido`,`estado_alta`,`fecha_alta`,`es_admin`,`idarchivo_img`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`) VALUES (4,'Otto','Dix',1,NULL,0,NULL,'35',NULL,NULL,NULL,NULL);
INSERT INTO `usuarios` (`idusuario`,`nombre`,`apellido`,`estado_alta`,`fecha_alta`,`es_admin`,`idarchivo_img`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`) VALUES (5,'Salvador','Dali',1,NULL,0,NULL,'35',NULL,NULL,NULL,NULL);
-- INSERT INTO `cuentas` (`idcuenta`,`username`,`clave`,`email`,`fecha_creacion`,`idusuario`,`eliminada`) VALUES (1,'agusdev','123','agustingarcia@gmail.com','2021-04-13 21:00:00',1,0);
-- INSERT INTO `cuentas` (`idcuenta`,`username`,`clave`,`email`,`fecha_creacion`,`idusuario`,`eliminada`) VALUES (2,'testadmin','123','test@admin.docps','2021-04-13 21:00:00',2,0);
INSERT INTO `cuentas` (`idcuenta`,`username`,`clave`,`email`,`fecha_creacion`,`idusuario`,`eliminada`) VALUES (3,'gustavklimt','123','gustav@klimt.docps','2021-09-02 21:25:08',3,0);
INSERT INTO `cuentas` (`idcuenta`,`username`,`clave`,`email`,`fecha_creacion`,`idusuario`,`eliminada`) VALUES (4,'ottodix','123','otto@dix.docps','2021-09-02 21:25:30',4,0);
INSERT INTO `cuentas` (`idcuenta`,`username`,`clave`,`email`,`fecha_creacion`,`idusuario`,`eliminada`) VALUES (5,'salvadordali','123','salvador@dali.docps','2021-09-02 21:25:53',5,0);

-- INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (1,1,1,'2021-04-13 21:00:00');
-- INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (2,1,0,'2021-05-20 21:00:00');
-- INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (3,1,0,'2021-09-04 15:02:58');
INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (4,3,1,'2021-09-04 15:02:58');
INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (4,4,0,'2021-09-04 15:02:59');
INSERT INTO `usuarios_grupos` (`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES (4,5,0,'2021-09-04 15:02:59');

INSERT INTO `proyectos` (`idproyecto`,`nombre`,`fecha_creacion`,`idgrupo`) VALUES (1,'DOCPS-0','2021-04-09 00:00:00',1);
INSERT INTO `proyectos` (`idproyecto`,`nombre`,`fecha_creacion`,`idgrupo`) VALUES (2,'DOCPS-150','2021-04-09 00:00:00',1);
INSERT INTO `proyectos` (`idproyecto`,`nombre`,`fecha_creacion`,`idgrupo`) VALUES (3,'DOCPS-154','2021-04-09 00:00:00',1);

INSERT INTO `planes` (`idplan`,`fecha_creacion`,`nombre`,`descripcion`,`idproyecto`,`idgrupo`) VALUES (1,'2021-04-09 00:00:00','Pruebas inciales','Test',1,1);
INSERT INTO `planes` (`idplan`,`fecha_creacion`,`nombre`,`descripcion`,`idproyecto`,`idgrupo`) VALUES (2,'2021-04-09 00:00:00','Pruebas iniciales II','Test',1,1);
INSERT INTO `planes` (`idplan`,`fecha_creacion`,`nombre`,`descripcion`,`idproyecto`,`idgrupo`) VALUES (3,'2021-04-09 00:00:00','Pruebas integración','Test',2,1);
INSERT INTO `planes` (`idplan`,`fecha_creacion`,`nombre`,`descripcion`,`idproyecto`,`idgrupo`) VALUES (4,'2021-04-09 00:00:00','Pruebas integración II','Test',2,1);