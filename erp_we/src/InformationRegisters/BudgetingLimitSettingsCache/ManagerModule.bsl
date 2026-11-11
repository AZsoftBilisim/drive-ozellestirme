#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Caches limit settings based on budgeting data by writing to the information register
// 
// Parameters:
//  BeginOfPeriod - Date - the beginning of the validity period for setting limits
//  EndOfPeriod - Date - end of the limit setting period
//  DocumentKind - CatalogRef.MetadataObjectIDs - type of document
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//  Value - Structure - structure of cached limit settings:
//   *ConfigureActualDataReceipt - Structure
//   *ConfigureLimitRules - Structure
//
Procedure SetCacheValue(BeginOfPeriod, EndOfPeriod, DocumentKind, BusinessOperation, Value) Export
	
	Record = InformationRegisters.BudgetingLimitSettingsCache.CreateRecordManager();
	
	Record.Period = BeginOfPeriod;
	Record.DocumentKind = DocumentKind;
	Record.BusinessOperation = BusinessOperation;
	For Each KeyAndValue In Value Do
		Record[KeyAndValue.Key] = New ValueStorage(KeyAndValue.Value);
	EndDo;
	Record.ValidTo = EndOfPeriod;
	
	Record.Write();
	
EndProcedure

// Returns cached limit settings based on budgeting data
// 
// Parameters:
//  Date - Date - the date on which you need to get the cache data
//  DocumentKind - CatalogRef.MetadataObjectIDs - type of document
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
//  Undefined
//  Structure - the structure of limit settings based on budgeting data.
//
Function GetCacheValue(Date, DocumentKind, BusinessOperation) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	BudgetingLimitSettingsCache.Period AS ValidOnDate,
	|	BudgetingLimitSettingsCache.ValidTo AS ValidToDate,
	|	BudgetingLimitSettingsCache.ConfigureActualDataReceipt AS ConfigureActualDataReceipt,
	|	BudgetingLimitSettingsCache.ConfigureLimitRules AS ConfigureLimitRules
	|FROM
	|	InformationRegister.BudgetingLimitSettingsCache.SliceLast(&Date, DocumentKind = &DocumentKind AND BusinessOperation = &BusinessOperation) AS BudgetingLimitSettingsCache
	|WHERE
	|	BudgetingLimitSettingsCache.ValidTo >= &Date";
	Query.SetParameter("Date", Date);
	Query.SetParameter("DocumentKind", DocumentKind);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Settings = New Structure;
	Settings.Insert("ValidOnDate", Selection.ValidOnDate);
	Settings.Insert("ValidToDate", Selection.ValidToDate);
	Settings.Insert("ConfigureActualDataReceipt", Selection.ConfigureActualDataReceipt.Get());
	Settings.Insert("ConfigureLimitRules", Selection.ConfigureLimitRules.Get());
	
	Return Settings;
	
EndFunction

#EndRegion

#EndIf