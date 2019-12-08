--- Parametros ------
declare @pEdicao nvarchar(100) = cast(SERVERPROPERTY('EngineEdition') as nvarchar)
declare @pLimiteRebuild int = 30
declare @pLimiteReorg int = 5
declare @pLimiteNrPagina int = 100
declare @pFillFactor int = 100
declare @pNucleosParalelizar int = 5

--- Tabelas temporárias
declare @fragmentacaoIndice as table(
	[cdhistoricofragmentacaoindice] [int] IDENTITY(1,1) NOT NULL,
	[idSeparacao] [int] null,
	[dtreferencia] [datetime] NULL,	[nmservidor] [nvarchar](50) NULL,
	[nmdatabase] [nvarchar](50) NULL, [nmschema] [nvarchar](200) NULL,
	[nmtabela] [nvarchar](200) NULL, [nmindice] [nvarchar](200) NULL,
	[nrfragmentacaopercentual] [float] NULL, [nrpagecount] [bigint] NULL,
	[nrfillfactor] [int] NULL, [command] [nvarchar](1000));

declare @Rebuild as table(
	[cdhistoricofragmentacaoindice] [int],
	[idSeparacao] [int] null,[dtreferencia] [datetime] NULL,
	[nmservidor] [nvarchar](50) NULL, [nmdatabase] [nvarchar](50) NULL,
	[nmschema] [nvarchar](200) NULL, [nmtabela] [nvarchar](200) NULL, 
	[nmindice] [nvarchar](200) NULL, [nrfragmentacaopercentual] [float] NULL, 
	[nrpagecount] [bigint] NULL, [nrfillfactor] [int] NULL, 
	[command] [nvarchar](1000) null) ;

declare @Reorg as table(
	[cdhistoricofragmentacaoindice] [int],
	[idSeparacao] [int] null,[dtreferencia] [datetime] NULL,
	[nmservidor] [nvarchar](50) NULL, [nmdatabase] [nvarchar](50) NULL,
	[nmschema] [nvarchar](200) NULL, [nmtabela] [nvarchar](200) NULL, 
	[nmindice] [nvarchar](200) NULL, [nrfragmentacaopercentual] [float] NULL, 
	[nrpagecount] [bigint] NULL, [nrfillfactor] [int] NULL, 
	[command] [nvarchar](1000) null);

--- Coleta todos os indcies
insert @fragmentacaoIndice ( idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor)
select 	ntile(IIF ( @pNucleosParalelizar > 0, @pNucleosParalelizar, 1 )) over(order by OBJECT_NAME(b.object_id), OBJECT_NAME(b.object_id) desc) as idseparacao, 
	getdate() as dtreferencia, 	@@SERVERNAME as nmservidor, 
	db_name(db_id()) as nmdatabase, s.name as nmschema,	OBJECT_NAME(b.object_id) as nmtabela, 
	b.name as nmindice, avg_fragmentation_in_percent as nrfragmentacaopercentual, 
	page_count as nrpagecount, 	fill_factor as nrfillfactor 
from sys.dm_db_index_physical_stats( db_id(), null, null, null,null) a
	inner join sys.indexes b WITH (NOLOCK) on a.object_id = b.object_id and a.index_id = b.index_id
	inner join sys.tables t WITH (NOLOCK) on t.object_id = b.object_id
	inner join sys.schemas s WITH (NOLOCK) on t.schema_id = s.schema_id

---- Separação dos rebuils e reorgs conforme o valor do parametro -----
--- Rebuild ---
insert @Rebuild (cdhistoricofragmentacaoindice, idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor, command)
select 	idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor,
	'ALTER INDEX [' + nmindice + '] on [' + nmdatabase + '].[' + nmschema + '].['+ nmtabela + '] REBUILD PATITION = all WITH (FILLFACTOR = ' + cast(@pFillFactor as varchar(5))  + 
		', STATISTICS_NORECOMPUTE = OFF, ONLINE = ' + IIF ( @pEdicao = 3, 'ON', 'OFF' ) + ', ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)' as command
from @fragmentacaoIndice
where nrpagecount > @pLimiteNrPagina 
	and  nrfragmentacaopercentual > @pLimiteRebuild 

--- Reorganize ---
insert @Reorg (cdhistoricofragmentacaoindice, idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor, command)
select 	idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor, 
	'ALTER INDEX [' + nmindice + '] ON [' + nmdatabase + '].[' + nmschema + '].['+ nmtabela + '] REORGANIZE WITH (LOB_COMPATCTION = ON)' as command
from @fragmentacaoIndice
where nrpagecount > @pLimiteNrPagina 
	and  nrfragmentacaopercentual > @pLimiteReorg
	and nrfragmentacaopercentual < @pLimiteRebuild 

-- Reaproveita a tabela para o loop para não precisar fazer dois loops --
delete @fragmentacaoIndice;

insert @fragmentacaoIndice (cdhistoricofragmentacaoindice, idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor, command)
select * from @Rebuild
insert @fragmentacaoIndice (cdhistoricofragmentacaoindice, idseparacao, dtreferencia, nmservidor, nmdatabase, nmschema, nmtabela, nmindice, nrfragmentacaopercentual,nrpagecount, nrfillfactor, command)
select * from @Reorg

----------------------------------------------------------------------------------------------------------
--- Executa os Rebuilds ---
Declare @Contador int =1 
Declare @Max int 
set @Max = (select count(1) from @fragmentacaoIndice)
declare @nmIndex nvarchar(500)
declare @sqlUpdate nvarchar(2000) = '', @sqlDelete nvarchar(2000) = '', @sqlInsert nvarchar(2000) = '', @tSQL nvarchar(2000) = ''

While @Contador <= @Max
begin
	set @tSQL = (select command from @fragmentacaoIndice where cdhistoricofragmentacaoindice = @contador)
	-- Insere o registro atual na tabela fisica de log --
	set @sqlInsert = '
		INSERT INTO [CrespiDB].[dbo].[LogManutencoes] ([idSeparacao], [nmDatabase], [nmSchema], [nmTabela], [nmIndice], [nrFragmentacaoIndice], 
			[nrQtdPaginasIndice],[nrFillFactorIndice], [Command], [CommandType], [dtInicio])
		SELECT [idSeparacao], [nmDatabase], [nmSchema], [nmTabela], [nmIndice], [nrFragmentacaoIndice], [nrQtdPaginasIndice], [nrFillFactorIndice], 
			[Command], [CommandType], ''' +   cast(getdate() as varchar(50)) + '''
		FROM @fragmentacaoIndice WHERE cdhistoricofragmentacaoindice = ' + cast(@Contador as varchar(100)) + ''
	exec(@sqlInsert )

	-- Executa o rebuild\reorg --
	exec(@tsql)

	-- Atualiza a data do termino do 
	set @sqlUpdate = 'UPDATE [dbo].[LogManutencoes] SET ,[dtFim] = ''' + cast(getdate() as varchar(50)) + ''' WHERE cdhistoricofragmentacaoindice = ' + cast(@Contador as varchar(100)) + ''
	exec(@sqlUpdate)

	-- Remove o regsitro da tabela temporária --
	set @sqlDelete = 'DELETE FROM @fragmentacaoIndice WHERE cdhistoricofragmentacaoindice = ' + cast(@Contador as varchar(100)) + ''
	exec(@sqlDelete)

	set @contador = @contador + 1
end

