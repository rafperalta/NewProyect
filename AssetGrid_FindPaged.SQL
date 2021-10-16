-- 7.2.1.273
ALTER Procedure [dbo].[AssetGrid_FindPagedResultsBySmartRuleId]     
       @SmartRuleId int,
       @PageSize int, 
       @PageFrom                  int, /* Required -1 == ALL pages */
       @PageCount                 int, /* Required -1 == ALL pages */
       @orderBy nvarchar(max),
       @whereClause nvarchar(max) = null,
       @IncludeCounts bit /* If 1 row count will be returned as a column (slow), if 0 then -1 will be returned for row count (fast) */
AS
As 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

IF @PageCount < 1
  SET @PageCount = 1

-- ---------------------------------------------------------------------------
-- Calculate the start and end row based on the page and page size. We need 
-- row numbers for the common table expression 
-- ---------------------------------------------------------------------------
DECLARE @startRow int,
       @endRow int

SELECT @startRow = (@PageFrom -1) * @PageSize + 1,
          @endRow = (@PageFrom + @PageCount -1) * @PageSize

IF @whereClause IS NOT NULL
BEGIN
	SET @whereClause = [dbo].[fnc_CleanseWhereClauseParam](@whereClause)
END

IF (object_id('tempdb..##tmpAsset_IP_Filtered') IS NULL) 
BEGIN

	begin transaction
	DECLARE @ResourceName varchar(2000);
	SET @ResourceName = 'create_tmpAsset_IP_Filtered' + cast(@SmartRuleID as varchar(200))
	-- create a lock as these are global temp tables and we need to make sure they can run concurrently
	exec sp_getapplock @Resource=@ResourceName,@Lockmode='EXCLUSIVE'
	-- make sure the table was not just created
	IF (object_id('tempdb..##tmpAsset_IP_Filtered') IS NULL) 
	BEGIN

		CREATE TABLE ##tmpAsset_IP_Filtered  (AssetID int, AssetIPID int,  IPID int, LastUpdateDate DateTime
		,IPAddress nvarchar(4000),MacAddress nvarchar(4000),OsCSV nvarchar(4000),
		CacheDate DATETIME,
			SmartRuleId INT
		) 

		CREATE NONCLUSTERED INDEX [IX_tmpAsset_IP_Filtered] ON [dbo].[##tmpAsset_IP_Filtered] ([AssetID])
		INCLUDE ([IPAddress],MacAddress,[OsCSV])
	
	END
	exec sp_releaseapplock @Resource=@ResourceName
	commit transaction
END
