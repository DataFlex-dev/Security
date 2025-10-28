BEGIN TRANSACTION;
BEGIN TRY;

-- insert required basic settings

INSERT INTO [dbo].[Settings] ([GROUP], [NAME], [VALUE], [Description]) VALUES
	('Core', 'DomainName', 'securitymatters.test', 'The domain name where the WebApp is deployed.'),
	('Security', 'MinPasscodeLen', '8', 'Minimum length of a user''s passcode.'),
	('Security', 'MaxPasscodeLen', '120', 'Maximum length of a user''s passcode. Do not set this too low.');

-- create CodeType table

CREATE TABLE [dbo].[CodeType] (
	[Type] [char](10) NOT NULL DEFAULT (''),
	[Description] [varchar](30) NOT NULL DEFAULT (''),
	[Comment] [varchar](max) NOT NULL DEFAULT (''),
	CONSTRAINT [CodeType001_PK] PRIMARY KEY CLUSTERED (
		[Type] ASC
	)
);

-- create CodeMast table

CREATE TABLE [dbo].[CodeMast] (
	[Type] [char](10) NOT NULL DEFAULT (''),
	[Code] [char](10) NOT NULL DEFAULT (''),
	[Description] [varchar](30) NOT NULL DEFAULT (''),
	CONSTRAINT [CodeMast001_PK] PRIMARY KEY CLUSTERED (
		[Type] ASC,
		[Code] ASC
	)
);

-- create WebAppUser table

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables WHERE TABLE_SCHEMA='dbo' and TABLE_NAME='WebAppUser')
	DROP TABLE [dbo].[WebAppUser];

CREATE TABLE [dbo].[WebAppUser](
	[LoginName] [char](20) NOT NULL DEFAULT (''),
	[Password] [varchar](250) NOT NULL DEFAULT (''),
	[Rights] [smallint] NOT NULL DEFAULT ((0)),
	[FullName] [char](30) NOT NULL DEFAULT (''),
	[LastLogin] [date] NOT NULL DEFAULT ('0001-01-01'),
	[PersonalInfo] [varchar](max) NOT NULL DEFAULT (''),
	CONSTRAINT [WebAppUser001_PK] PRIMARY KEY CLUSTERED (
		[LoginName] ASC
	)
);

INSERT INTO [dbo].[WebAppUser] ([LoginName],[Password],[Rights],[FullName]) VALUES
    ('Admin', 'admin', 1, 'Administrator')
    ,('Guest', 'guest', 0, 'Guest user');

-- create WebAppSession table

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables WHERE TABLE_SCHEMA='dbo' and TABLE_NAME='WebAppSession')
	DROP TABLE [dbo].[WebAppSession];

CREATE TABLE [dbo].[WebAppSession](
	[SessionKey] [char](36) NOT NULL DEFAULT (''),
	[CreateDate] [date] NOT NULL DEFAULT ('0001-01-01'),
	[CreateTime] [char](8) NOT NULL DEFAULT (''),
	[LastAccessDate] [date] NOT NULL DEFAULT ('0001-01-01'),
	[LastAccessTime] [char](8) NOT NULL DEFAULT (''),
	[UseCount] [int] NOT NULL DEFAULT ((0)),
	[RemoteAddress] [char](57) NOT NULL DEFAULT (''),
	[LoginName] [char](20) NOT NULL DEFAULT (''),
	[Active] [char](1) NOT NULL DEFAULT (''),
	CONSTRAINT [WebAppSession001_PK] PRIMARY KEY CLUSTERED (
		[SessionKey] ASC
	)
);
CREATE UNIQUE NONCLUSTERED INDEX [WebAppSession002] ON [dbo].[WebAppSession] (
	[CreateDate] ASC,
	[CreateTime] ASC,
	[SessionKey] ASC
);
CREATE UNIQUE NONCLUSTERED INDEX [WebAppSession003] ON [dbo].[WebAppSession]
(
	[LastAccessDate] ASC,
	[LastAccessTime] ASC,
	[SessionKey] ASC
);

-- create WebAppServerProps table

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.tables WHERE TABLE_SCHEMA='dbo' and TABLE_NAME='WebAppServerProps')
	DROP TABLE [dbo].[WebAppServerProps];

CREATE TABLE [dbo].[WebAppServerProps](
	[Key] [char](64) NOT NULL DEFAULT (''),
	[CreateDate] [date] NOT NULL DEFAULT ('0001-01-01'),
	[CreateTime] [char](12) NOT NULL DEFAULT (''),
	[ExpiresDate] [date] NOT NULL DEFAULT ('0001-01-01'),
	[ExpiresTime] [char](12) NOT NULL DEFAULT (''),
	[Locked] [smallint] NOT NULL DEFAULT ((0)),
	[LockedDate] [date] NOT NULL DEFAULT ('0001-01-01'),
	[LockedTime] [char](12) NOT NULL DEFAULT (''),
	[Page] [smallint] NOT NULL DEFAULT ((0)),
	[Pages] [smallint] NOT NULL DEFAULT ((0)),
	[Data] [varchar](max) NOT NULL DEFAULT (''),
	CONSTRAINT [WebAppServerProps001_PK] PRIMARY KEY CLUSTERED (
		[Key] ASC,
		[Page] ASC
	)
);
CREATE UNIQUE NONCLUSTERED INDEX [WebAppServerProps002] ON [dbo].[WebAppServerProps] (
	[ExpiresDate] DESC,
	[ExpiresTime] DESC,
	[Key] ASC,
	[Page] ASC
);

-- create Squeaks table

CREATE TABLE [dbo].[Squeaks](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [char](20) NOT NULL DEFAULT (''),
	[Content] [varchar](200) NOT NULL DEFAULT (''),
	[Status] [tinyint] NOT NULL DEFAULT ((0)),
	[Published] [datetime2](0) NOT NULL DEFAULT ('0001-01-01'),
	CONSTRAINT [Squeaks001_PK] PRIMARY KEY CLUSTERED (
		[ID] ASC
	)
);
CREATE UNIQUE NONCLUSTERED INDEX [Squeaks002] ON [dbo].[Squeaks] (
	[Published] DESC,
	[ID] DESC
);

INSERT [dbo].[Squeaks] ([UserId], [Content], [Status], [Published]) VALUES 
	(N'Guest', N'Public test message from Guest', 1, getdate())
	,(N'Guest', N'Private message from Guest', 0, CAST(N'0001-01-01T00:00:00.0000000' AS DateTime2))
	,(N'Admin', N'Public message from Admin', 1, getdate())
	,(N'Admin', N'Private message from Admin', 0, CAST(N'0001-01-01T00:00:00.0000000' AS DateTime2));

-- create PwnedPasswords table

CREATE TABLE [dbo].[PwnedPasswords](
	[PasscodeSha1] [binary](20) NOT NULL DEFAULT (0x00),
	[Frequency] [bigint] NOT NULL DEFAULT ((0)),
	CONSTRAINT [PwnedPasswords001_PK] PRIMARY KEY CLUSTERED (
		[PasscodeSha1] ASC
	)
);

-- create 2FA table

CREATE TABLE [dbo].[WebAppUser2FA](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[WebAppUser_ID] [char](20) NOT NULL DEFAULT (''),
	[Description] [varchar](50) NOT NULL DEFAULT (''),
	[Created] [datetime2](0) NOT NULL DEFAULT ('0001-01-01'),
	[Data] [varchar](4000) NOT NULL DEFAULT (''),
	[IsOath] [bit] NOT NULL DEFAULT ((0)),
	[IsU2f] [bit] NOT NULL DEFAULT ((0)),
	CONSTRAINT [WebAppUser2FA001_PK] PRIMARY KEY CLUSTERED (
		[ID] ASC
	)
);
CREATE UNIQUE NONCLUSTERED INDEX [WebAppUser2FA002] ON [dbo].[WebAppUser2FA] (
	[WebAppUser_ID] ASC,
	[Created] ASC,
	[ID] ASC
);

-- done

	COMMIT;
END TRY
BEGIN CATCH;
	ROLLBACK;
	THROW;
END CATCH
