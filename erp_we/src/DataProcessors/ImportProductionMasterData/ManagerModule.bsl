
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region TimeConsumingOperations

Procedure PerformActionInBackground(Parameters, StorageAddress) Export
	
	Result = Create().ExecuteAction(Parameters.ActionName, Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure MetadataObjectsToMatchInBackground(Parameters, StorageAddress) Export
	
	Result = MetadataObjectsToBeMapped(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure NumberOfErrorsByDimensionsInBackground(Parameters, StorageAddress) Export
	
	Result = NumberOfErrorsByDimension(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Actions

// Action "Fill in ids".
// 
// Returns:
//  String
Function ActionFillInIds() Export
	
	Return NStr("vi = 'Điền tên định danh';
				|ru = 'Заполнить идентификаторы';
				|en = 'Fill IDs'; fa = 'Fill IDs';
				|it = 'Заполнить идентификаторы';
				|pl = 'Fill IDs';
				|tr = 'Tanımlayıcıları doldur'");
	
EndFunction

// The "Upload data" action.
// 
// Returns:
//  String
Function UploadDataAction() Export
	
	Return NStr("vi = 'Kết nhập dữ liệu';
				|ru = 'Загрузить данные';
				|en = 'Import data'; fa = 'ورود داده';
				|it = 'Scaricare i dati';
				|pl = 'Pobierz dane';
				|tr = 'Verileri içe aktar'");
	
EndFunction

// Key for routine or background tasks
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
//  ActionName - String
// 
// Returns:
//  String
Function KeyForPerformingActionInBackground(DataSource, ActionName) Export
	
	Return StrTemplate("%1: %2", ActionName, DataSource.UUID());
	
EndFunction

// Name of the background task when performing an action in the background.
// 
// Parameters:
//  ActionName - String
// 
// Returns:
//  String
Function NameOfActionInBackground(ActionName) Export
	
	Return StrTemplate("%1: %2", EventLogEventName(), ActionName);
	
EndFunction

// Determines whether the specified action is already being performed on this source
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
//  ActionName - String
// 
// Returns:
//  Boolean
Function ActionIsAlreadyInProgress(DataSource, ActionName) Export
	
	JobKey = KeyForPerformingActionInBackground(DataSource, ActionName);
	
	PrivilegedModeSet = PrivilegedMode();
	If Not PrivilegedModeSet Then
		SetPrivilegedMode(True);
	EndIf;
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(New Structure("Key, State", JobKey, BackgroundJobState.Active));
	
	If Not PrivilegedModeSet Then
		SetPrivilegedMode(False);
	EndIf;
	
	If ActiveTasks.Count() > 0 Then
		WriteLogEvent(
			LogEventKey(DataSource),
			EventLogLevel.Warning,,,
			StrTemplate(NStr("vi = 'Đang thực hiện thao tác ""%1"" đối với nguồn ""%2"".';
							|ru = 'Действие ""%1"" для источника ""%2"" уже выполняется.';
							|en = 'The ""%1"" action for the ""%2"" source is already being performed.'; fa = 'The ""%1"" action for the ""%2"" source is already being performed.';
							|it = 'Действие ""%1"" для источника ""%2"" уже выполняется.';
							|pl = 'The ""%1"" action for the ""%2"" source is already being performed.';
							|tr = '""%2"" kaynağı için ""%1"" işlemi artık gerçekleştiriliyor.'"), ActionName, DataSource));
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region Other

Function MetadataObjectsToBeMapped(Parameters)
	
	Result = New Map;
	
	QueryText = "
	|SELECT
	|	Table.MetadataObject AS MetadataObject,
	|	COUNT(*) AS QuantityToMatch
	|FROM
	|	InformationRegister.ObjectMappingToImportMasterData AS Table
	|WHERE
	|	Table.DataSource = &DataSource
	|	AND Table.MetadataObject IN (&MetadataObjects)
	|	AND NOT Table.Matched
	|GROUP BY
	|	Table.MetadataObject
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.Products.EmptyRef) AS MetadataObject,
	|	COUNT(*) AS QuantityToMatch
	|FROM
	|	InformationRegister.ItemMappingToImportMasterData AS Table
	|WHERE
	|	Table.DataSource = &DataSource
	|	AND &ThereIsProductRange
	|	AND NOT Table.Matched
	|GROUP BY
	|	VALUE(Catalog.Products.EmptyRef)
	|
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataSource", Parameters.DataSource);
	Query.SetParameter("MetadataObjects", Parameters.MetadataObjects);
	Query.SetParameter("ThereIsProductRange", Parameters.MetadataObjects.Find(Catalogs.Products.EmptyRef()) <> Undefined);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Insert(Selection.MetadataObject, Selection.QuantityToMatch);
	EndDo;
	
	Return Result;
	
EndFunction

Function NumberOfErrorsByDimension(Parameters)
	
	Result = New Map;
	
	QueryText = "
	|SELECT
	|	&GroupField AS GroupingValue,
	|	COUNT(*)    AS ErrorsCount
	|FROM
	|	InformationRegister.ErrorsThatOccurredWhenImportingProductionMasterData AS Table
	|WHERE
	|	Table.DataSource = &DataSource
	|	AND NOT Table.Discussed
	|	AND &Filter
	|GROUP BY
	|	&GroupField
	|
	|";
	
	Query = New Query;
	Query.SetParameter("DataSource", Parameters.DataSource);
	
	QueryText = StrReplace(QueryText, "&GroupField", StrTemplate("Table.%1", Parameters.GroupField));
	If Parameters.Property("GroupingValue") And ValueIsFilled(Parameters.GroupingValue) Then
		QueryText = StrReplace(QueryText, "&Filter", StrTemplate("Table.%1 = &GroupingValue", Parameters.GroupField));
		Query.SetParameter("GroupingValue", Parameters.GroupingValue);
	Else
		QueryText = StrReplace(QueryText, "&Filter", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		GroupingValue = ?(Selection.GroupingValue = Undefined,
			Enums.ImportMasterDataIssueTypes.Other,
			Selection.GroupingValue);
		Result.Insert(GroupingValue, Selection.ErrorsCount);
	EndDo;
	
	Return Result;
	
EndFunction

// The name of the log event.
// 
// Returns:
//  String
Function EventLogEventName() Export
	
	Return NStr("vi = 'Kết nhập thông tin tra cứu';
				|ru = 'Загрузка производственной НСИ';
				|en = 'Import production master data'; fa = 'ورود داده‌های پایه تولید';
				|it = 'Загрузка производственной НСИ';
				|pl = 'Import production master data';
				|tr = 'Üretim master verisinin yüklenmesi'", Common.DefaultLanguageCode());
	
EndFunction

// The log event key.
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
// 
// Returns:
//  String - String
Function LogEventKey(DataSource) Export
	
	Return StrTemplate("%1: %2", EventLogEventName(), DataSource);
	
EndFunction

// Presentation of The event date in The interface.
// 
// Parameters:
//  EventDate - Date
// 
// Returns:
//  String
Function PresentationOfEventDateInInterface(EventDate) Export
	
	DifferenceDaysCount =  Int((BegOfDay(CurrentSessionDate()) - BegOfDay(EventDate)) / 86400);
	
	If DifferenceDaysCount = 0 Then
		
		Result = StrTemplate(NStr("vi = 'Hôm nay, %1';
									|ru = 'Сегодня, %1';
									|en = 'Today, %1'; fa = 'Today, %1';
									|it = 'Oggi, %1';
									|pl = 'Dzisiaj, %1';
									|tr = 'Bugün, %1'"), Format(EventDate, "DLF=T"));
		
	ElsIf DifferenceDaysCount = 1 Then
		
		Result = StrTemplate(NStr("vi = 'Hôm qua, %1';
									|ru = 'Вчера, %1';
									|en = 'Yesterday, %1'; fa = 'Yesterday, %1';
									|it = 'Ieri, %1';
									|pl = 'Wczoraj, %1';
									|tr = 'Dün, %1'"), Format(EventDate, "DLF=T"));
		
	ElsIf DifferenceDaysCount = 2 Then
		
		Result = StrTemplate(NStr("vi = 'Hôm kia, %1';
									|ru = 'Позавчера, %1';
									|en = 'Day before yesterday, %1'; fa = 'Day before yesterday, %1';
									|it = 'L''altro ieri, %1';
									|pl = 'Przedwczoraj, %1';
									|tr = 'Dünden önceki gün, %1'"), Format(EventDate, "DLF=T"));
		
	Else
		
		Result = Format(EventDate, "DLF=DD");
		
	EndIf;
	
	Return Result;
	
EndFunction

// Set the date layout in the list.
// 
// Parameters:
//  Rows - Array of KeyAndValue
//  ColumnName - String
// 
Procedure SetDateLayoutInList(Rows, ColumnName) Export
	
	For Each KeyAndValue In Rows Do
		
		ListLine = KeyAndValue.Value;
		
		If ValueIsFilled(ListLine.Data[ColumnName]) Then
			
			ListLine.Appearance[ColumnName].SetParameterValue(
				"Text", PresentationOfEventDateInInterface(ListLine.Data[ColumnName]));
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
