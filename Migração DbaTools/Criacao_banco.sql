--- VMMigracaoDataT\DESTINO
--- VMMigracaoDataT\ORIGEM

/* Cria banco e tabelas */
USE [master]
GO
CREATE DATABASE [db_DbaTools]
USE [db_DbaTools]
GO
CREATE TABLE [dbo].[tb_Categoria](
	[idcategoria] [int] IDENTITY(1,1) NOT NULL,
	[dscategoria] [varchar](100) NULL,
 CONSTRAINT [PK_tb_Categoria_1] PRIMARY KEY CLUSTERED 
(
	[idcategoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tb_Pessoas](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nome] [varchar](100) NULL,
	[endereco] [varchar](200) NULL,
	[nrtelefone] [varchar](15) NULL,
	[idcategoria] [int] NULL,
	[idTipo] [int] NULL,
 CONSTRAINT [PK_tb_cliente] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tb_Tipo](
	[idtipo] [int] IDENTITY(1,1) NOT NULL,
	[dstipo] [varchar](100) NULL,
 CONSTRAINT [PK_tb_categoria] PRIMARY KEY CLUSTERED 
(
	[idtipo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Pessoas]  WITH CHECK ADD  CONSTRAINT [FK_tb_Pessoas_tb_categoria] FOREIGN KEY([idcategoria])
REFERENCES [dbo].[tb_Categoria] ([idcategoria])
GO
ALTER TABLE [dbo].[tb_Pessoas] CHECK CONSTRAINT [FK_tb_Pessoas_tb_categoria]
GO
ALTER TABLE [dbo].[tb_Pessoas]  WITH CHECK ADD  CONSTRAINT [FK_tb_Pessoas_tb_tipo] FOREIGN KEY([idTipo])
REFERENCES [dbo].[tb_Tipo] ([idtipo])
GO
ALTER TABLE [dbo].[tb_Pessoas] CHECK CONSTRAINT [FK_tb_Pessoas_tb_tipo]
GO
USE [master]
GO
ALTER DATABASE [db_DbaTools] SET  READ_WRITE 
GO

/* Preenche tabelas */
USE [db_DbaTools]
GO

INSERT INTO [dbo].[tb_tipo]
           ([dstipo])
     VALUES
           ('Fisica'),
		   ('Juridica')
GO

INSERT INTO [dbo].[tb_Categoria]
           ([dscategoria])
     VALUES
           ('Cliente'),
		   ('Fornecedor')
GO

INSERT INTO [dbo].[tb_Pessoas]
           ([nome] ,[endereco] ,[nrtelefone] ,[idcategoria] ,[idTipo])
     VALUES
           ('CDBDataSolutions','Rua A, 1648','(54) 99999-9999',2,2),
		   ('Tiago Crespi','Rua B, 25','(54) 99997-9998',1,1),
           ('Tiago MEI','Rua A, 1648','(54) 99599-9959',1,2),
		   ('Tiago LTDA','Rua C, 398','(54) 92997-9298',1,2)
GO


/* Jobs */
USE [msdb]
GO

/****** Object:  Job [JB_backupfull]    Script Date: 11/2/2022 2:17:23 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/2/2022 2:17:24 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'JB_backupfull', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'VMMigracaoDataT\AdmUser', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [JS_backupfull]    Script Date: 11/2/2022 2:17:24 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'JS_backupfull', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [db_NMigra] TO  DISK = N''H:\Compartilhado\Backup1\db_NMigrar.bak'' WITH  COPY_ONLY, NOFORMAT, INIT,  NAME = N''db_NMigra-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N''db_NMigra'' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N''db_NMigra'' )
if @backupSetId is null begin raiserror(N''Verify failed. Backup information for database ''''db_NMigra'''' not found.'', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N''H:\Compartilhado\Backup1\db_NMigrar.bak'' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'JS_Backupfull', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20221102, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'87a25896-bf0e-4304-8a39-4aa9225a71e5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/* Linked Server */
USE [master]
GO

/****** Object:  LinkedServer [vmdatatools]    Script Date: 11/2/2022 2:41:52 PM ******/
EXEC master.dbo.sp_addlinkedserver @server = N'vmdatatools', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'vmdatatools',@useself=N'True',@locallogin=NULL,@rmtuser='UserSQLADM',@rmtpassword='Pegadinha123.'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'vmdatatools', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO


/* Alertas */
USE [msdb]
GO

/****** Object:  Alert [RecursosInsuficientes]    Script Date: 11/2/2022 3:23:50 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'RecursosInsuficientes', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@database_name=N'db_DbaTools', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO


USE [msdb]
GO

/* Operador */
/****** Object:  Operator [DBA]    Script Date: 11/2/2022 3:25:05 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'Dba@companhia.com.br', 
		@category_name=N'[Uncategorized]'
GO


