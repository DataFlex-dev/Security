BEGIN TRANSACTION;
BEGIN TRY;

-- create Settings table

CREATE TABLE [dbo].[Settings] (
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Group] [varchar](50) NOT NULL DEFAULT (''),
	[Name] [varchar](50) NOT NULL DEFAULT (''),
	[Value] [varchar](4000) NOT NULL DEFAULT (''),
	[Description] [varchar](4000) NOT NULL DEFAULT (''),
	CONSTRAINT [Settings001_PK] PRIMARY KEY CLUSTERED (
		[ID] ASC
	)
);
CREATE UNIQUE NONCLUSTERED INDEX [Settings002] ON [dbo].[Settings] (
	[Group] ASC,
	[Name] ASC
);

INSERT INTO [dbo].[Settings] ([GROUP], [NAME], [VALUE], [Description]) VALUES 
	('DBUpdate', 'DatabaseVersion', '0', 'The current version of the database structure. DO NOT CHANGE!');

-- done

	COMMIT;
END TRY
BEGIN CATCH;
	ROLLBACK;
	THROW;
END CATCH
