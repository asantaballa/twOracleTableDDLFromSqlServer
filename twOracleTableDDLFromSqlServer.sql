
Drop Table #ColDefs
Go

Drop Table #StatementsDDL
Go

Create Table #StatementsDDL
(
  Seq	Int				Identity
, Stm	VarChar(256)
)
Go

Select 
  so.name		TableName
, sc.name		ColumnName
, sc.xusertype	TypeId
, st.name		TypeName
, sc.length		Length
, sc.isnullable	IsNullable  
Into #ColDefs
From SysObjects so
Inner Join SysColumns sc On sc.id = so.id  
Left Outer Join SysTypes st on st.xusertype = sc.xusertype
Where 1 = 1
  And so.Xtype = 'U' 
  And so.id >= 0
Order by 
  so.name 
, sc.colorder

Declare
  @LastTableName		Varchar (256) = ''
, @ColSeparator			Varchar(16)
, @OracleColumnName		Varchar(64)
, @OracleTypeName		Varchar(16)
, @OracleDefString		Varchar(128)
, @OracleLengthString	VarChar(16)

Declare
  @TableName			Varchar (256)
, @ColumnName			Varchar(256)
, @TypeName				Varchar(16)
, @Length				Varchar(16)
, @IsNullable			Bit

Declare c1 Cursor For Select TableName, ColumnName, TypeName, IsNull(Length, ' '), IsNullable From #ColDefs
Open c1
Fetch c1 into @TableName, @ColumnName, @TypeName, @Length, @IsNullable
While @@FETCH_STATUS = 0
Begin

	If @TableName <> @LastTableName 
	Begin
		Select @ColSeparator = ' '
	End

	If @TableName <> @LastTableName And @LastTableName <> ''
	Begin
		Insert Into #StatementsDDL (Stm) Values('); ')
	End

	If @TableName <> @LastTableName
	Begin
		Insert Into #StatementsDDL (Stm) Values(' ')
		--Insert Into #StatementsDDL (Stm) Values('-- ')
		Insert Into #StatementsDDL (Stm) Values(' ')
		Insert Into #StatementsDDL (Stm) Values('Create Table ' + @TableName + ' ')
		Insert Into #StatementsDDL (Stm) Values('( ')
	End

	Select @OracleColumnName = SUBSTRING(@ColumnName + REPLICATE(' ', 64), 1, 64)

	Select @OracleTypeName = 
	Case @TypeName
		When 'bigint'			Then 'Number(19)'
		When 'bit'				Then 'Number(3)'
		When 'char'				Then 'Char'
		When 'date'				Then 'Date'
		When 'datetime'			Then 'Date'
		When 'decimal'			Then 'Number'
		When 'float'			Then 'Float(49'
		When 'int'				Then 'Int'
		When 'money'			Then 'Number(19,4)'
		When 'smalldatetime'	Then 'Date'
		When 'tinyint'			Then 'Number(3)'
		When 'varchar'			Then 'Varchar'
		When 'varbinary'		Then 'Raw'
		When 'xml'				Then 'XmlType'			-- ????
		--When 'sysname'			Then 'sysname??'
		Else @TypeName
	End

	Select @OracleDefString = @OracleTypeName

	If @OracleTypeName In ('Char' ,'Varchar')
	Begin
		Select @OracleLengthString = Case @Length When -1 Then 'MAX' Else Convert(Varchar(16), @Length) End 
		Select @OracleDefString = @OracleDefString + '(' + @OracleLengthString + ')'
	End

	Select @OracleDefString = SUBSTRING(@OracleDefString + REPLICATE(' ', 15), 1, 15)

	If @IsNullable = 1
	Begin
		Select @OracleDefString = @OracleDefString + ' Null'
	End

	--If @TypeName In ('decimal')
	--Begin
	--	??
	--End

	Insert Into #StatementsDDL (Stm) Values(@ColSeparator + ' ' + @OracleColumnName + ' ' + @OracleDefString + ' ')
	Select @LastTableName = @TableName
	Select @ColSeparator = ','
	Fetch c1 into @TableName, @ColumnName, @TypeName, @Length, @IsNullable
End
Close c1
Deallocate c1

Insert Into #StatementsDDL (Stm) Values('); ')

Select stm From #StatementsDDL Order by Seq

