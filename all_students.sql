	SELECT DISTINCT
	[STU].[LN], 
	[STU].[FN], 
	[STU].[ID],
	[STU].[GR],
	CASE [STU].[SC] when '34' then '1' else STU.SC end as 'SC' /*Converting ELA SC 34 to Paradise High SC 1*/
	FROM   [DST14000PUSD].[DBO].[STU] 
	WHERE  
	( 
		NOT STU.tg > ' ' 
	) 
	
	AND 
	(
		( [STU].del = 0 )
		OR [STU].del IS NULL 
	)

	AND (STU.SP NOT IN ('5','n','m','8','r'))
	AND STU.SC in ('1','2','3','4','6','8','9','10','11','12','34','77')
	ORDER BY
	STU.LN ASC,
	STU.ID DESC,
	STU.FN
