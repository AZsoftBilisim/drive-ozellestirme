///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks whether changing data is denied when a user edits it interactively or when data is imported from 
// the ImportRestrictionCheckNode exchange plan node programmatically.
//
// Parameters:
//  DataOrFullName  - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject - data object being checked.
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - Record set being checked with the optional property
//                          "Replacing" (Boolean, ReplacementMode) in the "AdditionalProperties" structure.
//                          If "Replacing" is undefined, it is set to "True".
//                      - String - Full name of a metadata object whose data is to be checked in the database.
//                                 Example: "Document.PurchaseInvoice".
//                                 To specify the data to read and check, use the DataID parameter.
//                                 
//
//  DataID - CatalogRef
//                      - DocumentRef
//                      - ChartOfCharacteristicTypesRef
//                      - ChartOfAccountsRef
//                      - ChartOfCalculationTypesRef
//                      - BusinessProcessRef
//                      - TaskRef
//                      - ExchangePlanRef
//                      - Filter - Reference to a data item or a record set filter to be checked.
//                                The value to be checked will be received from the database.
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - Record set with the optional property "Replacing" (Boolean, ReplacementMode)
//                          in the "AdditionalProperties" structure and defined "Filter" property in the record replacement option
//                          as in the "BeforeWrite" handler to retrieve the records being replaced from the database.
//                      - Undefined - do not get data from the database  
//                                       and check object data in DataOrFullName instead.
//
//  ErrorDescription    - Null      - the default value. Period-end closing data is not required.
//                    - String    - a return value. Return a text description of available period-end closing dates.
//                    - Structure - a return value. return a structural description of available period-end closing dates.
//                                  See the PeriodClosingDates.PeriodEndClosingFound function.
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef - if Undefined, check period-end closing; 
//                                otherwise check data import from the exchange plan node.
//
// Returns:
//  Boolean - True if changing data is denied.
//
// Call options:
//   DataChangesDenied(CatalogObject…)        - checks data in a passed object or record set.
//   DataChangesDenied(String, CatalogRef…) - checks data retrieved from the database by the full 
//      metadata object name and reference or by a record set filter.
//   DataChangesDenied(CatalogObject…, CatalogRef…) - simultaneously checks 
//      data in a passed object and data in the database (in other words, before and after writing to the infobase if the check is performed before
//      writing the object).
//
Function DataChangesDenied(DataOrFullName, DataID = Undefined,
	ErrorDescription = Null, ImportRestrictionCheckNode = Undefined) Export
	
	If TypeOf(DataOrFullName) = Type("String") Then
		MetadataObject = Common.MetadataObjectByFullName(DataOrFullName);
	Else
		MetadataObject = DataOrFullName.Metadata();
	EndIf;
	
	TablesDataSources = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
	DataSources = TablesDataSources.Get(MetadataObject.FullName());
	If DataSources = Undefined Then
		Return False; // Restrictions by dates are not defined for this object type.
	EndIf;
	IsRegister = DataSources.IsRegister;
	
	PeriodClosingCheck = ImportRestrictionCheckNode = Undefined;
	
	If TypeOf(DataOrFullName) = Type("String") Then
		If TypeOf(DataID) = Type("Filter") Then
			DataManager = Common.ObjectManagerByFullName(DataOrFullName);
			Source = DataManager.CreateRecordSet();
			For Each FilterElement In DataID Do
				Source.Filter[FilterElement.Name].Set(FilterElement.Value, FilterElement.Use);
			EndDo;
			Source.Read();
		ElsIf Not ValueIsFilled(DataID) Then
			Return False;
		ElsIf IsRegister Then
			Source = DataID; // A set of new records for obtaining existing records.
			Replacing = DataID.AdditionalProperties.Replacing;
			If Replacing = False
			 Or Common.IsRecordSetAddition(Replacing) Then
				Return False;
			EndIf;
		Else
			Source = DataID.GetObject();
		EndIf;
		
		If PeriodClosingDatesInternal.SkipClosingDatesCheck(Source,
				PeriodClosingCheck, ImportRestrictionCheckNode, "") Then
			Return False;
		EndIf;
		
		Return PeriodClosingDatesInternal.DataChangesDenied(DataOrFullName,
			DataID, ErrorDescription, ImportRestrictionCheckNode);
	EndIf;
	
	If IsRegister Then
		Mode = New Structure("Replacing", True);
		FillPropertyValues(Mode, DataOrFullName.AdditionalProperties);
	EndIf;
	
	ObjectVersion = "";
	If PeriodClosingDatesInternal.SkipClosingDatesCheck(DataOrFullName,
			 PeriodClosingCheck, ImportRestrictionCheckNode, ObjectVersion) Then
		Return False;
	EndIf;
	
	Source      = DataOrFullName;
	Id = DataID;
	
	If ObjectVersion = "OldVersion" Then
		Source = MetadataObject.FullName();
		
	ElsIf ObjectVersion = "NewVersion" Then
		Id = Undefined;
		If IsRegister And Common.IsRecordSetDeletion(Mode.Replacing) Then
			Return False;
		EndIf;
	EndIf;
	
	Return PeriodClosingDatesInternal.DataChangesDenied(Source,
		Id, ErrorDescription, ImportRestrictionCheckNode);
	
EndFunction

// Checks the import restriction for an object or the Data record set.
// It check both old and new data versions. 
//
// Parameters:
//  Data              - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - ObjectDeletion
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - a data item or a record set.
//
//  ImportRestrictionCheckNode  - ExchangePlanRef - a node to be checked.
//
//  Cancel               - Boolean - the return value. True if import is restricted.
//
//  ErrorDescription      - Null      - the default value. Period-end closing data is not required.
//                      - String    - a return value. Return a text description of available period-end closing dates.
//                      - Structure - a return value. Return a structural description of available period-end closing dates.
//                                    See the PeriodClosingDates.PeriodEndClosingFound function.
//
Procedure CheckDataImportRestrictionDates(Data, ImportRestrictionCheckNode, Cancel, ErrorDescription = Null) Export
	
	If TypeOf(Data) = Type("ObjectDeletion") Then
		MetadataObject = Data.Ref.Metadata();
	Else
		MetadataObject = Data.Metadata();
	EndIf;
	
	DataSources = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
	If DataSources.Get(MetadataObject.FullName()) = Undefined Then
		Return; // Restrictions by dates are not defined for this object type.
	EndIf;
	
	AdditionalParameters = PeriodClosingDatesInternal.PeriodEndClosingDatesCheckParameters();
	AdditionalParameters.ImportRestrictionCheckNode = ImportRestrictionCheckNode;
	AdditionalParameters.ErrorDescription = ErrorDescription;
	IsRegister = Common.IsRegister(MetadataObject);
	
	Result = PeriodClosingDatesInternal.CheckDataImportRestrictionDates1(Data,
		IsRegister, IsRegister, TypeOf(Data) = Type("ObjectDeletion"), AdditionalParameters);
	
	ErrorDescription = Result.ErrorDescription;
	If Result.DataChangesDenied Then
		Cancel = True;
	EndIf;
		
EndProcedure

// The OnReadAtServer form event handler, which is embedded into item forms of catalogs, documents, register records,
// and other objects to lock the form if data changes are denied.
//
// Parameters:
//  Form               - ClientApplicationForm - an item form of an object or a register record form.
//
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - InformationRegisterRecordManager - a record manager.
//
// Returns:
//  Boolean - True if programmatic period-end closing check was skipped.
//
Function ObjectOnReadAtServer(Form, CurrentObject) Export
	
	MetadataObject = Metadata.FindByType(TypeOf(CurrentObject));
	FullName = MetadataObject.FullName();
	
	EffectiveDates = PeriodClosingDatesInternal.EffectiveClosingDates();
	DataSources = EffectiveDates.DataSources.Get(FullName);
	If DataSources = Undefined Then
		Return False;
	EndIf;
	
	If Common.IsRegister(MetadataObject) Then
		// Converting a record manager to a record set with a single record.
		DataManager = Common.ObjectManagerByFullName(FullName);
		Source = DataManager.CreateRecordSet();
		For Each FilterElement In Source.Filter Do
			FilterElement.Set(CurrentObject[FilterElement.Name], True);
		EndDo;
		FillPropertyValues(Source.Add(), CurrentObject);
	Else
		Source = CurrentObject;
	EndIf;
	
	If PeriodClosingDatesInternal.SkipClosingDatesCheck(Source,
			True, Undefined, "") Then
		Return True;
	EndIf;
	
	If DataChangesDenied(Source) Then
		Form.ReadOnly = True;
	EndIf;
	
	Return False;
	
EndFunction

// Adds a string of data source details required for the period-end closing check.
// This procedure is used in the FillDataSourcesForPeriodClosingCheck procedure
// of the PeriodClosingDatesOverridable common module.
// 
// Parameters:
//  Data      - ValueTable - this parameter is passed to the FillDataSourcesForPeriodClosingCheck procedure.
//  Table     - String - a full metadata object name, for example, "Document.PurchaseInvoice".
//  DateField    - String - an attribute name of an object or a tabular section, for example: "Date", "Goods.ShipmentDate".
//  Section      - String - a name of a predefined item of ChartOfCharacteristicTypesRef.PeriodClosingDatesSections.
//  ObjectField - String - an attribute name of an object or a tabular section, for example: "Company", "Goods.Warehouse".
//
Procedure AddRow(Data, Table, DateField, Section = "", ObjectField = "") Export
	
	NewRow = Data.Add();
	NewRow.Table     = Table;
	NewRow.DateField    = DateField;
	NewRow.Section      = Section;
	NewRow.ObjectField = ObjectField;
	
EndProcedure

// Finds period-end closing dates by data to be checked for a specified user or exchange plan node.
//
// Parameters:
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate
//
//  PeriodEndMessageParameters - See PeriodClosingDates.PeriodEndMessageParameters
//                             - Undefined - It is not required to form the text of the ban message.
//
//  ErrorDescription    - Null      - the default value. Period-end closing data is not required.
//                    - String    - a return value. Return a text description of available period-end closing dates.
//                    - Structure - Return value. Return structural details of the detected period-end closing:
//                        * DataPresentation - String - a data presentation used in the error title.
//                        * ErrorTitle     - String - a string similar to the following one:
//                                                "Order 10 dated 01/01/2017 cannot be changed in the closed period."
//                        * PeriodEnds - ValueTable - detected period-end closing as a table with columns:
//                          ** Date            - Date         - a checked date.
//                          ** Section          - String       - a name of the section where period-end closing is searched,
//                                                 if a string is blank, a date valid for all sections is searched.
//                          ** Object          - AnyRef  - a reference to the object, in which period-end closing date was searched.
//                                             - Undefined - searching for a date valid for all objects.
//                          ** PeriodEndClosingDate     - Date         - a detected period-end closing date.
//                          ** SingleDate       - Boolean       - if True, the detected period-end closing date is valid for all
//                                                 sections, not only for the searched section.
//                          ** ForAllObjects - Boolean       - if True, the detected period-end closing date is valid for all
//                                                 objects, not only for the searched object.
//                          ** Addressee         - DefinedType.PeriodClosingTarget - a user or an exchange
//                                                 plan node, for which the detected period-end closing date is specified.
//                          ** LongDesc        - String - a string similar to the following one:
//                            "Date 01/01/2017 of the "Application warehouse" object of the "Warehouse accounting" section
//                            is within the range of period-end closing for all users (common period-end closing date is set)".
//
//  ImportRestrictionCheckNode - Undefined - check data change.
//                              - ExchangePlanRef - check data import for the specified node.
//
// Returns:
//  Boolean - if True, at least one period-end closing is detected.
//
Function PeriodEndClosingFound(Val DataToCheck,
                                    PeriodEndMessageParameters = Undefined,
                                    ErrorDescription = Null,
                                    ImportRestrictionCheckNode = Undefined) Export
	
	If PeriodClosingDatesInternal.PeriodEndClosingDatesCheckDisabled(
			ImportRestrictionCheckNode = Undefined, ImportRestrictionCheckNode) Then
		Return False;
	EndIf;
	
	Return PeriodClosingDatesInternal.PeriodEndClosingFound(DataToCheck,
		PeriodEndMessageParameters, ErrorDescription, ImportRestrictionCheckNode);
	
EndFunction

// Returns parameters for generating a period-end closing message that restricts data saving or import. 
// Used in the PeriodClosingDates.PeriodEndClosingFound function.
//
// Returns:
//   Structure:
//    * NewVersion - Boolean - if True, generate a period-end closing message
//                     for a new version, otherwise generate it for an old version.
//    * Data - AnyRef
//             - CatalogObject
//             - DocumentObject
//             - InformationRegisterRecordSet
//             - AccumulationRegisterRecordSet
//             - AccountingRegisterRecordSet 
//             - CalculationRegisterRecordSet - a reference, a data object
//                  or a register record set whose presentation will be displayed in the period-end closing message.
//             - Structure:
//                 ** Register - String - a full register name.
//                            - InformationRegisterRecordSet
//                            - AccumulationRegisterRecordSet
//                            - AccountingRegisterRecordSet 
//                            - CalculationRegisterRecordSet - register record set.
//                 ** Filter   - Filter - a record set filter.
//             - String - a prepared data presentation,
//                        which will be used in a period-end closing message.
//				 
Function PeriodEndMessageParameters() Export
	
	Result = New Structure;
	Result.Insert("Data", "");
	Result.Insert("NewVersion", False);
	Return Result;
	
EndFunction	

// Returns a new value table with the Date, Section, and Object columns
// to populate and pass to the PeriodClosingDates.PeriodEndClosingFound function.
//
// Returns:
//  ValueTable:
//   * Date   - Date   - a date without time to be checked for subordination to the specified period-end closing.
//   * Section - String - one of the section names specified in the
//                       PeriodClosingDatesOverridable.OnFillPeriodClosingDatesSections procedure
//   * Object - AnyRef - one of the object types specified for the section in the 
//                       PeriodClosingDatesOverridable.OnFillPeriodClosingDatesSections procedure.
//
Function DataToCheckTemplate() Export
	
	DataToCheck = New ValueTable;
	
	DataToCheck.Columns.Add(
		"Date", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	
	DataToCheck.Columns.Add(
		"Section", New TypeDescription("String,ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	
	DataToCheck.Columns.Add(
		"Object", Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.Type);
	
	Return DataToCheck;
	
EndFunction

// In the current session, disables and enables the check of period-end closing and data import restriction dates.
// It is required for implementing special logic and accelerating data batch processing
// upon recording an object or a record set when the DataExchange.Load flag is not set.
// 
// You need full rights or the privileged mode to use it.
//
// Recommended:
// - During bulk import of data from file (if data does not appear after the period-end closing date).
// -During bulk import of data when exchanging data (if data does not appear after the period-end closing date).
// - when disabling the period-end closing date check is required not for one object
//   by inserting the SkipPeriodClosingCheck property in the object's AdditionalProperties
//    but for several objects that will be saved under this object record.
//
// Parameters:
//  Disconnect - Boolean - If True, disables the check of period-end closing and data import restriction dates.
//                       If False, enables the check of period-end closing and data import restriction dates.
//
// Example:
//
//  Option 1. Recording an object set out of a transaction (TransactionActive() = False).
//
//	PeriodEndClosingDatesCheckDisabled = PeriodClosingDates.PeriodEndClosingDatesCheckDisabled();
//	PeriodClosingDates.DisablePeriodEndClosingDatesCheck(True);
//	Try
//		// Recording a set of objects.
//		// …
//	Except
//		PeriodClosingDates.DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
//		//…
//		Raise;
//	EndTry;
//	PeriodClosingDates.DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
//
//  Option 2. Recording an object set in the transaction (TransactionActive() = True).
//
//	PeriodEndClosingDatesCheckDisabled = PeriodClosingDates.PeriodEndClosingDatesCheckDisabled();
//	PeriodClosingDates.DisablePeriodEndClosingDatesCheck(True);
//	BeginTransaction();
//	Try
//		DataLock.Lock();
//		// …
//		// Recording a set of objects.
//		// …
//		CommitTransaction();
//	Except
//		RollbackTransaction();
//		PeriodClosingDates.DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
//		//…
//		Raise;
//	EndTry;
//	PeriodClosingDates.DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
//
Procedure DisablePeriodEndClosingDatesCheck(Disconnect) Export
	
	SessionParameters.SkipPeriodClosingCheck = Disconnect;
	
EndProcedure

// Returns the state of the period-end closing date disabling
// which is executed by the DisablePeriodEndClosingDatesCheck procedure.
//
// Returns:
//  Boolean
//
Function PeriodEndClosingDatesCheckDisabled() Export
	
	SetPrivilegedMode(True);
	PeriodEndClosingDatesCheckDisabled = SessionParameters.SkipPeriodClosingCheck;
	SetPrivilegedMode(False);
	
	Return PeriodEndClosingDatesCheckDisabled;
	
EndFunction

// In the current session, it sets the user on whose behalf the data change ban dates will be checked.
// Full rights or privileged mode are required for use.
//
// Parameters:
//  User - Undefined, CatalogRef.Users, CatalogRef.ExternalUsers - The user on whose behalf the data modification ban dates will be checked.
Procedure SetUserToCheckDatesOfBan(User = Undefined) Export
	
	SessionParameters.UserToCheckPeriodClosingDates = User;
	
EndProcedure

#Region EventsSubscriptionsHandlers

// BeforeWrite event subscription handler for checking period-end closing.
//
// Parameters:
//  Source   - CatalogObject
//             - ChartOfCharacteristicTypesObject
//             - ChartOfAccountsObject
//             - ChartOfCalculationTypesObject
//             - BusinessProcessObject
//             - TaskObject
//             - ExchangePlanObject - a data object passed to the BeforeWrite event subscription.
//
//  Cancel      - Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel);
	
EndProcedure

// BeforeWrite event subscription handler for checking period-end closing.
//
// Parameters:
//  Source        - DocumentObject - a data object passed to the BeforeWrite event subscription.
//  Cancel           - Boolean - a parameter passed to the BeforeWrite event subscription.
//  WriteMode     - Boolean - a parameter passed to the BeforeWrite event subscription.
//  PostingMode - Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeWriteDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Source.AdditionalProperties.Insert("WriteMode", WriteMode);
	
	CheckPeriodClosingDates(Source, Cancel);
	
EndProcedure

// BeforeWrite event subscription handler for checking period-end closing.
//
// Parameters:
//  Source   - InformationRegisterRecordSet
//             - AccumulationRegisterRecordSet - a record set passed to the BeforeWrite event subscription.
//  Cancel      - Boolean - a parameter passed to the BeforeWrite event subscription.
//  Replacing  - ReplacementMode, Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeWriteRecordSet(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Source.AdditionalProperties.Insert("Replacing", Replacing);
	
	CheckPeriodClosingDates(Source, Cancel, True, Replacing);
	
EndProcedure

// BeforeWrite event subscription handler for checking period-end closing.
//
// Parameters:
//  Source    - AccountingRegisterRecordSet - a record set passed to
//                the BeforeWrite event subscription.
//  Cancel       - Boolean - a parameter passed to the BeforeWrite event subscription.
//  Replacing   - ReplacementMode, Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeWriteAccountingRegisterRecordSet(
		Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Source.AdditionalProperties.Insert("Replacing", Replacing);
	
	CheckPeriodClosingDates(Source, Cancel, True);
	
EndProcedure

// BeforeWrite event subscription handler for checking period-end closing.
//
// Parameters:
//  Source     - CalculationRegisterRecordSet - a record set passed to
//                 the BeforeWrite event subscription.
//  Cancel        - Boolean - a parameter passed to the BeforeWrite event subscription.
//  Replacing    - ReplacementMode, Boolean - a parameter passed to the BeforeWrite event subscription.
//  WriteOnly - Boolean - a parameter passed to the BeforeWrite event subscription.
//  WriteActualActionPeriod - Boolean - a parameter passed to the BeforeWrite event subscription.
//  WriteRecalculations - Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeWriteCalculationRegisterRecordSet(
		Source,
		Cancel,
		Replacing,
		WriteOnly,
		WriteActualActionPeriod,
		WriteRecalculations) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Source.AdditionalProperties.Insert("Replacing", Replacing);
	
	CheckPeriodClosingDates(Source, Cancel, True, Replacing);
	
EndProcedure

// BeforeDelete event subscription handler for checking period-end closing.
//
// Parameters:
//  Source   - CatalogObject
//             - DocumentObject
//             - ChartOfCharacteristicTypesObject
//             - ChartOfAccountsObject
//             - ChartOfCalculationTypesObject
//             - BusinessProcessObject
//             - TaskObject
//             - ExchangePlanObject - a data object passed to the BeforeWrite event subscription.
//
//  Cancel      - Boolean - a parameter passed to the BeforeWrite event subscription.
//
Procedure CheckPeriodEndClosingDateBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.DeletionMark Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel, , , True);
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Calling is not required as it is updated automatically.
Procedure UpdatePeriodClosingDatesSections() Export
	
	PeriodClosingDatesInternal.UpdatePeriodClosingDatesSections();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// For procedures CheckPeriodEndClosingDate*.
Procedure CheckPeriodClosingDates(
		Source, Cancel, SourceRegister = False, Replacing = True, Delete = False)
	
	Result = PeriodClosingDatesInternal.CheckDataImportRestrictionDates1(
		Source, SourceRegister, Replacing, Delete);
	If Result.DataChangesDenied Then
		Raise Result.ErrorDescription;
	EndIf;		
	
EndProcedure

#EndRegion