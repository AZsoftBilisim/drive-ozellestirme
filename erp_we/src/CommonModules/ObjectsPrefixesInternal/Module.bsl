///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Adds "Number.WithPrefix" to the calculated field of the given data composition schema.
//
// Parameters:
//    DataCompositionSchema - DataCompositionSchema
//
Procedure AddFieldExtensionNum(DataCompositionSchema) Export
	IsNumberFieldFound = False;
	For Each DataSet In DataCompositionSchema.DataSets Do
		If Not DataSet.Fields.Count() Then
			QuerySchema = New QuerySchema;
			QuerySchema.SetQueryText(DataSet.Query);
			QueryFields = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count()-1].Columns;
			If QueryFields.Find("Number") <> Undefined Then
				IsNumberFieldFound = True;
				Break;
			EndIf;
		ElsIf DataSet.Fields.Find("Number") <> Undefined Then
			IsNumberFieldFound = True;
			Break;
		EndIf;
	EndDo;
	
	If IsNumberFieldFound And DataCompositionSchema.CalculatedFields.Find("Number.WithPrefix") = Undefined Then
		NewField = DataCompositionSchema.CalculatedFields.Add();
		NewField.Expression = "Number";
		NewField.Title = NStr("vi = 'Số có tiền tố';
								|ru = 'Номер.С префиксом';
								|en = 'Number.With prefix'; fa = 'Number.With prefix';
								|it = 'Номер.С префиксом';
								|pl = 'Number.With prefix';
								|tr = 'Numara.Önek ile'");
		NewField.DataPath = "Number.WithPrefix";
		NewField.ValueType = New TypeDescription("String");
	EndIf;
	
EndProcedure

// Changes an infobase prefix.
// Additionally, allows to process data to continue numbering.
//
// Parameters:
//  Parameters - Structure - procedure parameters:
//   * NewIBPrefix - String - a new infobase prefix.
//   * ContinueNumbering - Boolean - shows whether it is required to continue numbering.
//  ResultAddress - String - the address of the temporary storage where the procedure
//                                puts its result.
//
Procedure ChangeIBPrefix(Parameters, ResultAddress = "") Export
	
	// The constant that stores the prefix belongs to the "DataExchange" subsystem.
	// Without it, the procedure cannot function properly.
	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		Return;
	EndIf;
	
	NewIBPrefix = Parameters.NewIBPrefix;
	ContinueNumbering = Parameters.ContinueNumbering;
	
	BeginTransaction();
	
	Try
		
		If ContinueNumbering Then
			ProcessDataToContinueNumbering(NewIBPrefix);
		EndIf;
		
		// Set the constant last to have an access to its previous value.
		PrefixConstantName = "DistributedInfobaseNodePrefix";
		Constants[PrefixConstantName].Set(NewIBPrefix);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(EventLogEventReassignObjectsPrefixes(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Raise NStr("vi = 'Không thể thay đổi tiền tố.';
					|ru = 'Не удалось изменить префикс.';
					|en = 'Cannot change prefix.'; fa = 'Cannot change prefix.';
					|it = 'Impossibile cambiare il prefisso.';
					|pl = 'Nie udało się zmienić prefiksu.';
					|tr = 'Önek değiştirilemedi.'");
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

#Region ExportServiceProceduresAndFunctions

// Returns the flag that shows whether the object's company or date is changed.
//
// Parameters:
//  Ref - a reference to an infobase object.
//  DateAfterChange - an object date after change.
//  CompanyAfterChange - an object company after change.
//
//  Returns:
//    Boolean - True - the object's company was changed, or a new object date
//            was set in a different periodicity interval than the previous date.
//   False - the company and the document date were not changed.
//
Function ObjectDateOrCompanyChanged(Ref, Val DateAfterChange, Val CompanyAfterChange) Export
	
	FullTableName = Ref.Metadata().FullName();
	QueryText = "
	|SELECT
	|	ObjectHeader.Date AS Date,
	|	ISNULL(ObjectHeader.CompanyAttributeName.Prefix, """") AS CompanyPrefixBeforeChange
	|FROM
	|	&TableName AS ObjectHeader
	|WHERE
	|	ObjectHeader.Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", FullTableName);
	QueryText = StrReplace(QueryText, "CompanyAttributeName", ObjectsPrefixesEvents.CompanyAttributeName(FullTableName));
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	CompanyPrefixAfterChange = Undefined;
	ObjectsPrefixesEvents.OnDetermineCompanyPrefix(CompanyAfterChange, CompanyPrefixAfterChange);
	
	// If an empty reference to a company is specified.
	CompanyPrefixAfterChange = ?(CompanyPrefixAfterChange = False, "", CompanyPrefixAfterChange);
	
	Return Selection.CompanyPrefixBeforeChange <> CompanyPrefixAfterChange
		Or Not ObjectDatesOfSamePeriod(Selection.Date, DateAfterChange, Ref);
	//
EndFunction

// Returns whether the object company is changed.
//
// Parameters:
//  Ref - a reference to an infobase object.
//  CompanyAfterChange - an object company after change.
//
//  Returns:
//    Boolean - True - the object's company was changed. False - the company was not changed.
//
Function ObjectCompanyChanged(Ref, Val CompanyAfterChange) Export
	
	FullTableName = Ref.Metadata().FullName();
	QueryText = "
	|SELECT
	|	ISNULL(ObjectHeader.CompanyAttributeName.Prefix, """") AS CompanyPrefixBeforeChange
	|FROM
	|	&TableName AS ObjectHeader
	|WHERE
	|	ObjectHeader.Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", FullTableName);
	QueryText = StrReplace(QueryText, "CompanyAttributeName", ObjectsPrefixesEvents.CompanyAttributeName(FullTableName));
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	CompanyPrefixAfterChange = Undefined;
	ObjectsPrefixesEvents.OnDetermineCompanyPrefix(CompanyAfterChange, CompanyPrefixAfterChange);
	
	// If an empty reference to a company is specified.
	CompanyPrefixAfterChange = ?(CompanyPrefixAfterChange = False, "", CompanyPrefixAfterChange);
	
	Return Selection.CompanyPrefixBeforeChange <> CompanyPrefixAfterChange;
	
EndFunction

// False - the company and the document date were not changed.
// Dates are considered to be equal if they belong to the same period of time: Year, Month, Day, and etc.
//
// Parameters:
//   Date1 - the first date for comparison.
//   Date2 - the second date for comparison.
//   ObjectMetadata - metadata of an object for which a function value is to be got.
//
//  Returns:
//    Boolean - True - the object dates belong to the same period; False - the object dates belong to different periods.
//
Function ObjectDatesOfSamePeriod(Val Date1, Val Date2, Ref) Export
	
	ObjectMetadata = Ref.Metadata();
	
	If DocumentNumberPeriodicityYear(ObjectMetadata) Then
		
		DateDiff = BegOfYear(Date1) - BegOfYear(Date2);
		
	ElsIf DocumentNumberPeriodicityQuarter(ObjectMetadata) Then
		
		DateDiff = BegOfQuarter(Date1) - BegOfQuarter(Date2);
		
	ElsIf DocumentNumberPeriodicityMonth(ObjectMetadata) Then
		
		DateDiff = BegOfMonth(Date1) - BegOfMonth(Date2);
		
	ElsIf DocumentNumberPeriodicityDay(ObjectMetadata) Then
		
		DateDiff = BegOfDay(Date1) - BegOfDay(Date2);
		
	Else // DocumentNumberPeriodicityUndefined
		
		DateDiff = 0;
		
	EndIf;
	
	Return DateDiff = 0;
	
EndFunction

Function MetadataUsingPrefixesDetails(DiagnosticsMode = False) Export
	
	Result = NewMetadataUsingPrefixesDetails();
	
	ModuleSaaSOperations = Undefined;
	IsSAASSubsystem = Common.SubsystemExists("CloudTechnology.Core");
	If IsSAASSubsystem Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	EndIf;

	// Populate a metadata table.
	DataSeparationEnabled = Common.DataSeparationEnabled();
	For Each Subscription In Metadata.EventSubscriptions Do
		
		IBPrefixUsed = False;
		CompanyPrefixIsUsed = False;
		If Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetInfobaseAndCompanyPrefix") Then
			IBPrefixUsed = True;
			CompanyPrefixIsUsed = True;
		ElsIf Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetInfobasePrefix") Then
			IBPrefixUsed = True;
		ElsIf Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetCompanyPrefix") Then
			CompanyPrefixIsUsed = True;
		Else
			// Skipping subscriptions not related to prefixation.
			Continue;
		EndIf;
		
		For Each SourceType In Subscription.Source.Types() Do
			
			SourceMetadata = Metadata.FindByType(SourceType);
			FullObjectName = SourceMetadata.FullName();
			
			IsSeparatedMetadataObject = False;
			If IsSAASSubsystem Then
				IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(FullObjectName);
			EndIf;
			
			// Skip objects that were added (in case multiple subscriptions had been attached by mistake).
			// Also, for the separated mode, skip objects that relate to shared data.
			If Not DiagnosticsMode Then
				
				If Result.Find(FullObjectName, "FullName") <> Undefined Then
					Continue;
				ElsIf DataSeparationEnabled Then
					
					If Not IsSeparatedMetadataObject Then
						Continue;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			ObjectDetails = Result.Add();
			ObjectDetails.Name = SourceMetadata.Name;
			ObjectDetails.FullName = FullObjectName;
			ObjectDetails.IBPrefixUsed = IBPrefixUsed;
			ObjectDetails.CompanyPrefixIsUsed = CompanyPrefixIsUsed;
		
			// Possible data types with a code or number.
			ObjectDetails.IsCatalog             = Common.IsCatalog(SourceMetadata);
			ObjectDetails.IsChartOfCharacteristicTypes = Common.IsChartOfCharacteristicTypes(SourceMetadata);
			ObjectDetails.IsDocument               = Common.IsDocument(SourceMetadata);
			ObjectDetails.IsBusinessProcess          = Common.IsBusinessProcess(SourceMetadata);
			ObjectDetails.IsTask                 = Common.IsTask(SourceMetadata);
			
			ObjectDetails.SubscriptionName = Subscription.Name;
			
			ObjectDetails.IsSeparatedMetadataObject = IsSeparatedMetadataObject;
			
			Characteristics = New Structure("CodeLength, NumberLength", 0, 0);
			FillPropertyValues(Characteristics, SourceMetadata);
			
			If Characteristics.CodeLength = 0 And Characteristics.NumberLength = 0 Then
				
				If Not DiagnosticsMode Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Lỗi triển khai phân hệ ""%1"" đối với đối tượng metadata ""%2"".';
							|ru = 'Ошибка внедрения подсистемы ""%1"" для объекта метаданных ""%2"".';
							|en = 'An error occurred while integrating subsystem %1 for metadata object %2.'; fa = 'An error occurred while integrating subsystem %1 for metadata object %2.';
							|it = 'Errore di implementazione del sottosistema ""%1"" per l''oggetto metadati ""%2"".';
							|pl = 'Błąd implementacji podsystemu ""%1"" dla obiektu metadanych ""%2"".';
							|tr = '%2Meta veri nesnesi için %1alt sistemi uygulama hatası.'"),
						Metadata.Subsystems.StandardSubsystems.Subsystems.ObjectsPrefixes, FullObjectName);
					Raise(MessageText, ErrorCategory.ConfigurationError);
						
				EndIf;
				
			ElsIf ObjectDetails.IsCatalog Or ObjectDetails.IsChartOfCharacteristicTypes Then
				ObjectDetails.HasCode = True;
			Else
				ObjectDetails.HasNumber = True;
			EndIf;
			
			// Defining a number periodicity for a document and business process.
			NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Nonperiodical;
			If ObjectDetails.IsDocument Then
				NumberPeriodicity = SourceMetadata.NumberPeriodicity;
			ElsIf ObjectDetails.IsBusinessProcess Then
				If SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Year Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Year;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Day Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Day;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Quarter Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Quarter;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Month Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Month;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Nonperiodical Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Nonperiodical;
				EndIf;
			EndIf;
			ObjectDetails.NumberPeriodicity = NumberPeriodicity;
			
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction


#EndRegion

#Region LocalUtilityProceduresAndFunctions

// Determines whether the AfterDataImport event handler is to be executed upon exchange in DIB.
//
// Parameters:
//  NewIBPrefix - String - it is intended for computing new item codes (numbers) after the prefix is changed.
//  DataAnalysisMode - Boolean - if True, data is not changed, the function defines
//                                which data is changed and how. If False - object changes
//                                are recorded to the infobase.
//
// Returns:
//   See ObjectsPrefixesInternal.MetadataUsingPrefixesDetails
//
Function ProcessDataToContinueNumbering(Val NewIBPrefix = "", DataAnalysisMode = False)
	
	MetadataUsingPrefixesDetails = MetadataUsingPrefixesDetails();
	
	SupplementStringWithZerosOnLeft(NewIBPrefix, 2);
	
	Result = NewMetadataUsingPrefixesDetails();
	Result.Columns.Add("Ref");
	Result.Columns.Add("Number");
	Result.Columns.Add("NewNumber");
	
	CurrentIBPrefix = "";
	ObjectsPrefixesEvents.OnDetermineInfobasePrefix(CurrentIBPrefix);
	SupplementStringWithZerosOnLeft(CurrentIBPrefix, 2);
	
	For Each ObjectDetails In MetadataUsingPrefixesDetails Do
		
		If Not DataAnalysisMode Then
			DataLock = New DataLock;
			DataLock.Add(ObjectDetails.FullName);
			DataLock.Lock();
		EndIf;
		
		// @skip-check query-in-loop - Batch processing of a large amount of data.
		ObjectDataForLastItemRenumbering = OneKindObjectDataForLastItemsRenumbering(
			ObjectDetails, CurrentIBPrefix);
		If ObjectDataForLastItemRenumbering.IsEmpty() Then
			Continue;
		EndIf;
		
		ObjectSelection = ObjectDataForLastItemRenumbering.Select();
		While ObjectSelection.Next() Do
			
			NewResultString = Result.Add();
			FillPropertyValues(NewResultString, ObjectDetails);
			FillPropertyValues(NewResultString, ObjectSelection);
			NewResultString.NewNumber = StrReplace(NewResultString.Number, CurrentIBPrefix + "-", NewIBPrefix + "-");
			
			If Not DataAnalysisMode Then
				RenumberingObject = NewResultString.Ref.GetObject();
				RenumberingObject[?(NewResultString.HasNumber, "Number", "Code")] = NewResultString.NewNumber;
				InfobaseUpdate.WriteData(RenumberingObject, True, False);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function DocumentNumberPeriodicityYear(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Year;
	
EndFunction

Function DocumentNumberPeriodicityQuarter(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Quarter;
	
EndFunction

Function DocumentNumberPeriodicityMonth(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Month;
	
EndFunction

Function DocumentNumberPeriodicityDay(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Day;
	
EndFunction

Function OneKindObjectDataForLastItemsRenumbering(Val ObjectDetails, Val PreviousPrefix = "")
	
	FullObjectName = ObjectDetails.FullName;
	HasNumber = ObjectDetails.HasNumber;
	CompanyPrefixIsUsed = ObjectDetails.CompanyPrefixIsUsed;
	
	Query = New Query;
	
	BatchQueryText = New Array;
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";

	QueryText =
	"SELECT
	|	SelectionByDateNumber.Ref AS Ref,
	|	&CompanyFieldName1 AS Organization,
	|	&CodeNumberFieldName AS Number
	|INTO SelectionByDateNumber
	|FROM
	|	&TableName AS SelectionByDateNumber
	|WHERE
	|	&ConditionByDate AND &CodeNumberFieldName LIKE &Prefix ESCAPE ""~""
	|
	|INDEX BY
	|	Number,
	|	Organization";
	
	QueryText = StrReplace(QueryText, "&ConditionByDate", ?(HasNumber, "SelectionByDateNumber.Date >= &Date", "TRUE"));
	QueryText = StrReplace(QueryText, "&CodeNumberFieldName", "SelectionByDateNumber." + ?(HasNumber, "Number", "Code"));
	QueryText = StrReplace(QueryText, "&TableName", FullObjectName);
	
	CompanyFieldName1 = ?(CompanyPrefixIsUsed,
		"SelectionByDateNumber." + ObjectsPrefixesEvents.CompanyAttributeName(FullObjectName), "Undefined");
	QueryText = StrReplace(QueryText, "&CompanyFieldName1", CompanyFieldName1);
	
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	MaxCodes.Organization AS Organization,
	|	MAX(MaxCodes.Number) AS Number
	|INTO MaxCodes
	|FROM
	|	SelectionByDateNumber AS MaxCodes
	|
	|GROUP BY
	|	MaxCodes.Organization
	|
	|INDEX BY
	|	Number,
	|	Organization";
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	SelectionByDateNumber.Organization AS Organization,
	|	SelectionByDateNumber.Number AS Number,
	|	MAX(SelectionByDateNumber.Ref) AS Ref
	|FROM
	|	SelectionByDateNumber AS SelectionByDateNumber
	|		INNER JOIN MaxCodes AS MaxCodes
	|		ON (MaxCodes.Number = SelectionByDateNumber.Number
	|				AND MaxCodes.Organization = SelectionByDateNumber.Organization)
	|
	|GROUP BY
	|	SelectionByDateNumber.Organization,
	|	SelectionByDateNumber.Number";
	BatchQueryText.Add(QueryText);
	
	Query.Text = StrConcat(BatchQueryText, Separator);
	
	If HasNumber Then
		// Selecting data from the beginning of the current year.
		FromDate = BegOfDay(BegOfYear(CurrentSessionDate()));
		Query.SetParameter("Date", BegOfDay(FromDate));
	EndIf;
	
	// Processing objects created only in the current infobase.
	Query.SetParameter("Prefix", 
		"%" + Common.GenerateSearchQueryString(PreviousPrefix) + "-%");
	
	Return Query.Execute();
	
EndFunction

Function NewMetadataUsingPrefixesDetails()
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Result = New ValueTable;
	Result.Columns.Add("Name",                            TypesDetailsString);
	Result.Columns.Add("FullName",                      TypesDetailsString);
	
	Result.Columns.Add("HasCode",                        TypesDetailsBoolean);
	Result.Columns.Add("HasNumber",                      TypesDetailsBoolean);
	Result.Columns.Add("IsCatalog",                  TypesDetailsBoolean);
	Result.Columns.Add("IsChartOfCharacteristicTypes",      TypesDetailsBoolean);
	Result.Columns.Add("IsDocument",                    TypesDetailsBoolean);
	Result.Columns.Add("IsBusinessProcess",               TypesDetailsBoolean);
	Result.Columns.Add("IsTask",                      TypesDetailsBoolean);
	Result.Columns.Add("IBPrefixUsed",          TypesDetailsBoolean);
	Result.Columns.Add("CompanyPrefixIsUsed", TypesDetailsBoolean);
	
	Result.Columns.Add("NumberPeriodicity");
	
	Result.Columns.Add("SubscriptionName", TypesDetailsString);
	
	Result.Columns.Add("IsSeparatedMetadataObject", TypesDetailsBoolean);
	
	Return Result;
	
EndFunction

Procedure SupplementStringWithZerosOnLeft(String, StringLength)
	
	String = StringFunctionsClientServer.SupplementString(String, StringLength, "0", "Left");
	
EndProcedure

Function EventLogEventReassignObjectsPrefixes()
	
	Return NStr("vi = 'Đặt tiền tố đối tượng.Thay đổi tiền tố cơ sở thông tin';
				|ru = 'Префиксация объектов.Изменение префикса информационной базы';
				|en = 'Object prefixes. Infobase prefix changed.'; fa = 'Object prefixes. Infobase prefix changed.';
				|it = 'Impostazione di prefissi degli oggetti.Modifica del prefisso del database informatico';
				|pl = 'Prefiksowanie obiektów.Zmiana przedrostka bazy informacyjnej';
				|tr = 'Nesne öneki. Infobase öneki değişikliği'",
		Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion