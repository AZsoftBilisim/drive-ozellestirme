///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns:
//  FixedStructure:
//    * NoSectionsAndObjects - Boolean
//    * AllSectionsWithoutObjects - Boolean
//    * ImportRestrictionDatesImplemented - Boolean
//    * SingleSection - ChartOfCharacteristicTypesRef.PeriodClosingDatesSections
//    * UseExternalUsers - Boolean
//    * ShowSections - Boolean
//    * EmptyExchangePlansNodesRefs - FixedArray
//    * Sections - FixedMap of KeyAndValue:
//        ** Key - String
//        ** Value - FixedStructure:
//             *** Name - String
//             *** Presentation - String
//             *** Ref - ChartOfCharacteristicTypesRef.PeriodClosingDatesSections
//             *** ObjectsTypes - FixedArray
//    * SectionsWithoutObjects - FixedArray
//
Function SectionsProperties() Export
	
	Return SessionParameters.ValidPeriodClosingDates.SectionsProperties;
	
EndFunction

// Shows that it is required to update a version of period-end closing dates after changing data
// in the import mode or updates the version (import upon the infobase update).
//
// Called from the OnWrite event of PeriodClosingDates and UserGroupCompositions registers.
//
// Parameters:
//  Object - InformationRegisterRecordSet.PeriodClosingDates
//         - InformationRegisterRecordSet.UserGroupCompositions
// 
Procedure UpdatePeriodClosingDatesVersionOnDataImport(Object) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(Object.DataExchange.Sender) Then
		SessionParameters.UpdatePeriodClosingDatesVersionAfterImportData = True;
	Else
		UpdatePeriodClosingDatesVersion();
	EndIf;
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("SkipPeriodClosingCheck",
		"PeriodClosingDatesInternal.SessionParametersSetting");
	
	Handlers.Insert("ValidPeriodClosingDates",
		"PeriodClosingDatesInternal.SessionParametersSetting");
	
	Handlers.Insert("UpdatePeriodClosingDatesVersionAfterImportData",
		"PeriodClosingDatesInternal.SessionParametersSetting");
	
	Handlers.Insert("AccessRightsToRestrictionDates",
		"PeriodClosingDatesInternal.SessionParametersSetting");
		
	Handlers.Insert("UserToCheckPeriodClosingDates",
		"PeriodClosingDatesInternal.SessionParametersSetting");
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.Version = "*";
	Handler.Procedure = "PeriodClosingDatesInternal.UpdatePeriodClosingDatesSections";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "PeriodClosingDatesInternal.SetInitialPeriodEndClosingDate";
	
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "PeriodClosingDatesInternal.ClearPredefinedItemsInClosingDatesSections";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "PeriodClosingDatesInternal.ReplaceClosingDatesSectionsWithNewOnes";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.75";
	Handler.Procedure = "PeriodClosingDatesInternal.AppendSettingsForGivenAddressees";
	
EndProcedure

// See StandardSubsystemsServer.
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If RecordSetOnlyWithImportRestrictionDates(DataElement) Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	If RecordSetOnlyWithImportRestrictionDates(DataElement) Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	// Standard data processor cannot be overridden.
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	If RecordSetOnlyWithImportRestrictionDates(DataElement) Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	// Standard data processor cannot be overridden.
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	If RecordSetOnlyWithImportRestrictionDates(DataElement) Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// Event handlers of the "ReportsOptions" subsystem.

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ImportRestrictionDates);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.PeriodClosingDates);
	
EndProcedure

// Event handlers of the "Users" subsystem.

// See SSLSubsystemsIntegration.AfterUserGroupsUpdate.
Procedure AfterUserGroupsUpdate(ItemsToChange, ModifiedGroups) Export
	
	UpdatePeriodClosingDatesVersion();
	
EndProcedure

// Event handlers of the "Access management" subsystem.

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.InformationRegisters.PeriodClosingDates, True);
	
EndProcedure

// Events handlers of the CloudTechnology library.

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	// Shared data use only references with UUIDs specified in the procedure
	// "OnFillPeriodClosingDatesSections" of the common module "PeriodClosingDatesOverridable".
	// 
	Types.Add(Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region MainProceduresAndFunctions

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "ValidPeriodClosingDates" Then
		Value = SessionParameterValueEffectivePeriodClosingDates();
		SessionParameters.ValidPeriodClosingDates = Value;
		SpecifiedParameters.Add("ValidPeriodClosingDates");
		LastCheck = PeriodClosingDatesInternalCached.LastCheckOfEffectiveClosingDatesVersion();
		LastCheck.Date = CurrentSessionDate();
		
	ElsIf ParameterName = "SkipPeriodClosingCheck" Then
		SessionParameters.SkipPeriodClosingCheck = False;
		SpecifiedParameters.Add("SkipPeriodClosingCheck");
		
	ElsIf ParameterName = "UpdatePeriodClosingDatesVersionAfterImportData" Then
		SessionParameters.UpdatePeriodClosingDatesVersionAfterImportData = False;
		SpecifiedParameters.Add("UpdatePeriodClosingDatesVersionAfterImportData");
		
	ElsIf ParameterName = "AccessRightsToRestrictionDates" Then
		Rights = New Array;
		// ACC:515-off - No. 737.4 Role check (as the right is always granted).
		If Users.RolesAvailable("ReadPeriodEndClosingDates, AddEditPeriodClosingDates",, False) Then
			Rights.Add("ReadPeriodEndClosingDates");
		EndIf;
		If Users.RolesAvailable("AddEditPeriodClosingDates",, False) Then
			Rights.Add("ChangeOfPeriodEndClosingDates");
		EndIf;
		If Users.RolesAvailable("ReadDataImportRestrictionDates, AddEditDataImportRestrictionDates",, False) Then
			Rights.Add("ReadDataImportRestrictionDates");
		EndIf;
		If Users.RolesAvailable("AddEditDataImportRestrictionDates",, False) Then
			Rights.Add("ChangeDataImportRestrictionDates");
		EndIf;
		// ACC:515-on
		If ValueIsFilled(Rights) Then
			AccessRightsToRestrictionDates = "," + StrConcat(Rights, "," + Chars.LF + ",") + ",";
		Else
			AccessRightsToRestrictionDates = "";
		EndIf;
		SessionParameters.AccessRightsToRestrictionDates = AccessRightsToRestrictionDates;
		SpecifiedParameters.Add("AccessRightsToRestrictionDates");
	ElsIf ParameterName = "UserToCheckPeriodClosingDates" Then
		SessionParameters.UserToCheckPeriodClosingDates = Undefined;
		SpecifiedParameters.Add("UserToCheckPeriodClosingDates");
	EndIf;
	
EndProcedure

// Handler of the PeriodClosingDatesVersionUpdateAfterDataImport subscription
// to the OnWrite event of any exchange plan.
//
Procedure PeriodClosingDatesVersionUpdateAfterDataImportOnWrite(Source, Cancel) Export
	
	// For "DataExchange.Load", update the UUID in the constant "PeriodClosingDatesVersion",
	// which notifies the sessions that the period-end closing dates cache needs to be updated.
	
	SetPrivilegedMode(True);
	
	If SessionParameters.UpdatePeriodClosingDatesVersionAfterImportData Then
		UpdatePeriodClosingDatesVersion();
		SessionParameters.UpdatePeriodClosingDatesVersionAfterImportData = False;
	EndIf;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

// Updates a version of period-end closing dates after change.
Procedure UpdatePeriodClosingDatesVersion() Export
	
	SetPrivilegedMode(True);
	Constants.PeriodClosingDatesVersion.Set(New UUID);
	
	LastCheck = PeriodClosingDatesInternalCached.LastCheckOfEffectiveClosingDatesVersion();
	LastCheck.Date = '00010101';
	
EndProcedure

// Returns:
//   Structure:
//    * PeriodClosingCheck    - Boolean - if you set it to False, period-end closing check for users 
//                                    will be skipped. Default value is True.
//    * ImportRestrictionCheckNode - Undefined - (initial value) check data change.
//                                  - ExchangePlanRef - check data import for the specified node.
//    * ErrorDescription              - Null      - if returning detected period-end closing details is not required (default).
//                                  - String    - if returning text details is required.
//                                  - Structure - if it is required to return a structural description of available period-end closing dates.
//                                                See the PeriodClosingDates.PeriodEndClosingFound function.
//
Function PeriodEndClosingDatesCheckParameters() Export
	
	Result = New Structure;
	Result.Insert("PeriodClosingCheck",    False);
	Result.Insert("ImportRestrictionCheckNode", Undefined);
	Result.Insert("ErrorDescription",              Null);
	Return Result;

EndFunction

// Checks period-end closing dates or data import restriction dates for the object.
// If data changing/import is impossible, sets the Cancel parameter to True.
//
// Parameters:
//  Source        - CatalogObject
//                  - ChartOfCharacteristicTypesObject
//                  - ChartOfAccountsObject
//                  - ChartOfCalculationTypesObject
//                  - BusinessProcessObject
//                  - TaskObject
//                  - ExchangePlanObject
//                  - DocumentObject - a data object.
//                  - InformationRegisterRecordSet
//                  - AccumulationRegisterRecordSet
//                  - AccountingRegisterRecordSet
//                  - CalculationRegisterRecordSet - record set.
//                  - ObjectDeletion - object deletion upon importing.
//
//  SourceRegister - Boolean - False - a source is a register, otherwise, an object.
//
//  Replacing       - ReplacementMode, Boolean - Record replacement mode (only for registers).
//
//  Delete        - Boolean - if a source is an object and an object is being deleted,
//                    specify True.
//
//  AdditionalParameters - Undefined - the parameters have initial values.
//                          - See PeriodEndClosingDatesCheckParameters
//
// Returns:
//   Structure:
//    * DataChangesDenied - Boolean - True if the object fails period-end closing date check.
//    * ErrorDescription     - Null
//                         - String
//                         - Structure - the result depends on AdditionalParameters.ErrorDescription.
//
Function CheckDataImportRestrictionDates1(Source, SourceRegister, Replacing, Delete, 
	AdditionalParameters = Undefined) Export
	
	Result = New Structure;
	Result.Insert("DataChangesDenied", False);
	Result.Insert("ErrorDescription", "");
	
	PeriodClosingCheck    = True;
	ImportRestrictionCheckNode = Undefined;
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		AdditionalParameters.Property("PeriodClosingCheck",    PeriodClosingCheck);
		AdditionalParameters.Property("ImportRestrictionCheckNode", ImportRestrictionCheckNode);
		AdditionalParameters.Property("ErrorDescription",              Result.ErrorDescription);
	EndIf;
	
	ObjectVersion = "";
	If SkipClosingDatesCheck(Source, PeriodClosingCheck,
			ImportRestrictionCheckNode, ObjectVersion) Then
		Return Result;
	EndIf;
	
	If Not SourceRegister And Not Delete And Not Source.IsNew() Then
	
		If DataChangesDenied(
				?(ObjectVersion <> "OldVersion", Source, Source.Metadata().FullName()),
				?(ObjectVersion <> "NewVersion",  Source.Ref, Undefined),
				Result.ErrorDescription,
				ImportRestrictionCheckNode) Then
			
			Result.DataChangesDenied = True;
		EndIf;
		
	ElsIf SourceRegister
	        And (Replacing = True
	           Or Common.IsRecordSetReplacement(Replacing)
	           Or Common.IsRecordSetUpdate(Replacing)
	           Or Common.IsRecordSetMerge(Replacing)
	           Or Common.IsRecordSetDeletion(Replacing)) Then
		
		FullName = Source.Metadata().FullName();
		RefinedSource = ?(Common.IsRecordSetDeletion(Replacing),
			FullName, Source);
		RefinedDataID = ?(Replacing = True, Source.Filter, Source);
		
		If DataChangesDenied(
				?(ObjectVersion <> "OldVersion", RefinedSource, FullName),
				?(ObjectVersion <> "NewVersion",  RefinedDataID, Undefined),
				Result.ErrorDescription,
				ImportRestrictionCheckNode) Then
			
			Result.DataChangesDenied = True;
		EndIf;
		
	ElsIf TypeOf(Source) = Type("ObjectDeletion") Then
		
		If ObjectVersion <> "NewVersion"
		   And DataChangesDenied(Source.Ref.Metadata().FullName(), Source.Ref,
				Result.ErrorDescription, ImportRestrictionCheckNode) Then
			
			Result.DataChangesDenied = True;
		EndIf;
		
	Else
		// Executed when the condition is met:
		//     NOT SourceRegister AND Source.IsNew
		// OR SourceRegister AND (Replacing = False or Common.IsRecordSetAddition(Replacing))
		// OR NOT SourceRegister AND Delete.
		If ObjectVersion <> "OldVersion"
		   And DataChangesDenied(Source, Undefined,	Result.ErrorDescription, ImportRestrictionCheckNode) Then
			
			Result.DataChangesDenied = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether period-end closing or data import restriction need to be checked.
//
// Returns:
//  Boolean - True if check is not required.
//
Function SkipClosingDatesCheck(Object, PeriodClosingCheck, ImportRestrictionCheckNode, 
	ObjectVersion) Export
	
	If TypeOf(Object) <> Type("ObjectDeletion")
	   And Object.AdditionalProperties.Property("SkipPeriodClosingCheck") Then
		
		Return True;
	EndIf;
	
	If PeriodEndClosingDatesCheckDisabled(PeriodClosingCheck, ImportRestrictionCheckNode) Then
		Return True;
	EndIf;
	
	PeriodClosingDatesOverridable.BeforeCheckPeriodClosing(
		Object, PeriodClosingCheck, ImportRestrictionCheckNode, ObjectVersion);
	
	Return PeriodClosingCheck    = False          // DO NOT check period-end closing.
	      And ImportRestrictionCheckNode = Undefined; // DO NOT check import restriction.
	
EndFunction

Function PeriodEndClosingDatesCheckDisabled(PeriodClosingCheck, ImportRestrictionCheckNode) Export
	
	SetPrivilegedMode(True);
	If SessionParameters.SkipPeriodClosingCheck Then
		Return True;
	EndIf;
	SetPrivilegedMode(False);
	
	If PeriodEndClosingNotUsed(PeriodClosingCheck, ImportRestrictionCheckNode) Then
		Return True;
	EndIf;
	
	If InfobaseUpdate.InfobaseUpdateInProgress()
	 Or InfobaseUpdate.IsCallFromUpdateHandler() Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// See PeriodClosingDates.DataChangesDenied.
Function DataChangesDenied(Data, DataID, ErrorDescription, ImportRestrictionCheckNode) Export
	
	SetPrivilegedMode(True);
	
	PeriodEndFound = False;
	EffectiveDates = EffectiveClosingDates();
	
	// Check an old object version or a record set.
	If DataID <> Undefined Then
		PeriodEndMessageParameters = PeriodClosingDates.PeriodEndMessageParameters();
		PeriodEndMessageParameters.NewVersion = False;
		
		// "Data" is the table name required for the property "DataID" of the "Filter" type
		// and in cases where data has the "ObjectDeletion" type.
		
		If TypeOf(DataID) = Type("Filter") Then
			FilterStructure = New Structure;
			FilterStructure.Insert("Register", Data);
			FilterStructure.Insert("Filter", DataID);
			PeriodEndMessageParameters.Data = FilterStructure;
		Else
			PeriodEndMessageParameters.Data = DataID;
		EndIf;
		
		DataToCheck = DataToCheckFromDatabase(Data,
			DataID, EffectiveDates, ImportRestrictionCheckNode);
		
		If ValueIsFilled(DataToCheck) Then
			PeriodEndFound = PeriodEndClosingFound(DataToCheck,
				PeriodEndMessageParameters, ErrorDescription, ImportRestrictionCheckNode, EffectiveDates);
		Else
			PeriodEndFound = False;
		EndIf;
	EndIf;
	
	// Check a new object version or a record set.
	If Not PeriodEndFound And TypeOf(Data) <> Type("String") Then
		
		PeriodEndMessageParameters = PeriodClosingDates.PeriodEndMessageParameters();
		PeriodEndMessageParameters.NewVersion = True;
		PeriodEndMessageParameters.Data = Data;
		
		DataToCheck = DataForCheckFromObject(Data, EffectiveDates, ImportRestrictionCheckNode);
		
		If ValueIsFilled(DataToCheck) Then
			PeriodEndFound = PeriodEndClosingFound(DataToCheck,
				PeriodEndMessageParameters, ErrorDescription, ImportRestrictionCheckNode, EffectiveDates);
		EndIf;
	EndIf;
	
	Return PeriodEndFound;
	
EndFunction

// Finds period-end closing dates by data to be checked for a specified user or exchange plan node.
// See PeriodClosingDates.PeriodEndClosingFound.
//
// Parameters:
//  DataToCheck           - See PeriodClosingDates.DataToCheckTemplate
//  PeriodEndMessageParameters  - See PeriodClosingDates.PeriodEndMessageParameters
//  ErrorDescription              - See PeriodClosingDates.PeriodEndClosingFound.ErrorDescription
//  ImportRestrictionCheckNode - See PeriodClosingDates.PeriodEndClosingFound.ImportRestrictionCheckNode
//
//  EffectiveDates - See PeriodClosingDatesInternal.SessionParameterValueEffectivePeriodClosingDates
//
// Returns:
//  Boolean - True if at least one period-end closing is detected.
//
Function PeriodEndClosingFound(Val DataToCheck, PeriodEndMessageParameters,
			ErrorDescription, ImportRestrictionCheckNode, EffectiveDates = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If EffectiveDates = Undefined Then
		EffectiveDates = EffectiveClosingDates();
	EndIf;
	
	RestrictionUsed = ?(ImportRestrictionCheckNode = Undefined,
		EffectiveDates.PeriodClosingUsed,
		EffectiveDates.ImportRestrictionUsed);
	
	If Not RestrictionUsed Then
		Return False;
	EndIf;
	
	SectionsProperties = EffectiveDates.SectionsProperties;
	BlankSection = EmptyRef(Type("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong hàm %1 mô-đun chung %2.';
			|ru = 'Ошибка в функции %1 общего модуля %2.';
			|en = 'Error in function ""%1"" of common module ""%2"".'; fa = 'Error in function ""%1"" of common module ""%2"".';
			|it = 'Errore nella funzione %1 del modulo generale %2.';
			|pl = 'Błąd w funkcji %1 wspólnego modułu %2.';
			|tr = '%2 genel modülün %1 işlevinde hata oluştu.'"),
		"PeriodEndClosingFound",
		"PeriodClosingDates")
		+ Chars.LF
		+ Chars.LF;
	
	// Adjusting data to match the embedding option.
	For Each TableRow In DataToCheck Do
		
		If TableRow.Section = Undefined Then
			TableRow.Section = BlankSection;
		EndIf;
		
		SectionProperties = SectionsProperties.Sections.Get(TableRow.Section); // See ChartsOfCharacteristicTypes.PeriodClosingDatesSections.SectionProperties
		If SectionProperties = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong tham số %1 đã chỉ ra phân hệ không tồn tại ""%2"".';
					|ru = 'В параметре %1 указан несуществующий раздел ""%2"".';
					|en = '%1 parameter contains non-existent section: ""%2"".'; fa = '%1 parameter contains non-existent section: ""%2"".';
					|it = 'Nel parametro %1 è indicata una sezione inesistente ""%2"".';
					|pl = 'W parametrze %1 jest wskazany nieistniejący rozdział ""%2"".';
					|tr = '%1 parametresinde mevcut olmayan ""%2"" bölüm belirtilmiştir.'"),
				"DataToCheck",
				TableRow.Section);
			Raise ErrorText;
		EndIf;
		
		If SectionsProperties.NoSectionsAndObjects Then
			TableRow.Section = BlankSection;
			TableRow.Object = BlankSection;
		Else
			If ValueIsFilled(SectionsProperties.SingleSection) Then
				TableRow.Section = SectionsProperties.SingleSection;
			Else
				TableRow.Section = SectionProperties.Ref;
			EndIf;
			
			If SectionsProperties.AllSectionsWithoutObjects
			 Or Not ValueIsFilled(TableRow.Object) Then
				
				TableRow.Object = TableRow.Section;
			EndIf;
		EndIf;
		
	EndDo;
	
	// Collapse unnecessary rows to reduce the number of checks and messages.
	SectionsAndObjects = DataToCheck.Copy(, "Section, Object");
	SectionsAndObjects.GroupBy("Section, Object");
	Filter = New Structure("Section, Object");
	SectionsAndObjects.Columns.Add("Date",
		New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	
	For Each SectionAndObject In SectionsAndObjects Do
		FillPropertyValues(Filter, SectionAndObject);
		MinDate = Undefined;
		For Each TableRow In DataToCheck.FindRows(Filter) Do
			CurrentDate = BegOfDay(TableRow.Date);
			If MinDate = Undefined Then
				MinDate = CurrentDate;
			EndIf;
			If CurrentDate < MinDate Then
				MinDate = CurrentDate;
			EndIf;
		EndDo;
		SectionAndObject.Date = MinDate;
	EndDo;
	DataToCheck = SectionsAndObjects;
	
	// Period-end closing date:
	// 1. Use the user setting (if present) and ignore the user group settings and general user getting.
	//    2. Use the setting of the last user's group (if present and the user setting is missing)
	// and ignore other group settings and the general setting.
	//    3. Use the general user setting if the user setting is missing
	//    and the settings in the user's groups are missing.
	//    
	// 
	//    
	
	// The priority of data import restriction dates:
	// 1. Use the infobase node setting (if present)
	//    and ignore the general exchange plan setting and this exchange plan setting.
	// 2. Use the exchange plan setting (if present and the node setting is missing)
	//    and ignore the general exchange plan setting.
	// 3. Use the overall exchange plan setting (if the node setting and exchange plan setting are missing).
	//    
	
	// Priorities by section and object are applied to the extent of the above priorities
	// and are the same for the period-end closing dates and data import restriction dates.
	// 1. For this section, this object.
	// 2. For this section, for any object (the object is a section).
	// 3. For any object (an empty section), for any object (the object is a section).
	
	PeriodEndClosing = DataToCheck.Copy(New Array);
	PeriodEndClosing.Columns.Add("Addressee");
	PeriodEndClosing.Columns.Add("Data");
	
	// Search for period-end closing.
	If ImportRestrictionCheckNode = Undefined Then
		Recipients = EffectiveDates.ForUsers.Recipients;
		If SessionParameters.UserToCheckPeriodClosingDates <> Undefined Then
			Addressee = SessionParameters.UserToCheckPeriodClosingDates;
		Else
			Addressee = Users.AuthorizedUser();
		EndIf;
		Sections = Recipients.Get(Addressee);
		If Sections = Undefined Then
			OpenUserGroups = EffectiveDates.UserGroups.Get(Addressee);
			If OpenUserGroups <> Undefined Then
				For Each Group In OpenUserGroups Do
					PeriodEndAddressee = Group;
					Sections = Recipients.Get(PeriodEndAddressee);
					Break;
				EndDo;
			EndIf;
			If Sections = Undefined Then
				PeriodEndAddressee = Enums.PeriodClosingDatesPurposeTypes.ForAllUsers;
				Sections = Recipients.Get(PeriodEndAddressee);
			EndIf;
		EndIf;
	Else
		Recipients = EffectiveDates.ForInfobases.Recipients;
		Addressee = ImportRestrictionCheckNode;
		Sections = Recipients.Get(Addressee);
		If Sections = Undefined Then
			PeriodEndAddressee = Common.ObjectManagerByRef(ImportRestrictionCheckNode).EmptyRef();
			Sections = Recipients.Get(PeriodEndAddressee);
			If Sections = Undefined Then
				PeriodEndAddressee = Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases;
				Sections = Recipients.Get(PeriodEndAddressee);
			EndIf;
		EndIf;
	EndIf;
	
	If Sections = Undefined Then
		Return False;
	EndIf;
	
	For Each Data In DataToCheck Do
		SearchResult = FindPeriodEndClosingDate(Sections, Data, BlankSection);
		If SearchResult = Undefined Then
			Continue;
		EndIf;
		
		If SearchResult.PeriodEndClosingDate < Data.Date Then
			Continue;
		EndIf;
		
		String = PeriodEndClosing.Add();
		String.Data  = Data;
		String.Section  = SearchResult.RestrictionSection;
		String.Object  = SearchResult.RestrictionObject;
		String.Addressee = Addressee;
		String.Date    = SearchResult.PeriodEndClosingDate;
	EndDo;
	
	If TypeOf(PeriodEndMessageParameters) = Type("Structure")
	   And TypeOf(ErrorDescription) <> Type("Null")
	   And PeriodEndClosing.Count() > 0 Then
		
		ErrorDescription = PeriodEndMessages(PeriodEndClosing, PeriodEndMessageParameters, SectionsProperties,
			ImportRestrictionCheckNode <> Undefined, TypeOf(ErrorDescription) = Type("Structure"));
	EndIf;
	
	Return PeriodEndClosing.Count() > 0;
	
EndFunction

// Returns effective period-end closing dates considering the version after changes.
//
// Returns:
//   See PeriodClosingDatesInternal.SessionParameterValueEffectivePeriodClosingDates
//
Function EffectiveClosingDates() Export
	
	LastCheck = PeriodClosingDatesInternalCached.LastCheckOfEffectiveClosingDatesVersion();
	
	EffectiveDates = SessionParameters.ValidPeriodClosingDates;
	
	If CurrentSessionDate() > (LastCheck.Date + 5) Then
		If EffectiveDates.BegOfDay <> BegOfDay(CurrentSessionDate())
		 Or EffectiveDates.Version <> Constants.PeriodClosingDatesVersion.Get() Then
			
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			
			ParametersToClear = New Array;
			ParametersToClear.Add("ValidPeriodClosingDates");
			SessionParameters.Clear(ParametersToClear);
			
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
			
			EffectiveDates = SessionParameters.ValidPeriodClosingDates;
		EndIf;
		LastCheck.Date = CurrentSessionDate();
	EndIf;
	
	Return EffectiveDates;
	
EndFunction

// Returns data sources populated 
// in the PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck procedure.
//
// Returns:
//   FixedMap
//
Function DataSourcesForPeriodClosingCheck() Export
	
	Return SessionParameters.ValidPeriodClosingDates.DataSources;
	
EndFunction

// Returns an empty reference of the specified type.
Function EmptyRef(RefType)
	
	Types = New Array;
	Types.Add(RefType);
	TypeDescription = New TypeDescription(Types);
	
	Return TypeDescription.AdjustValue(Undefined);
	
EndFunction

Function ErrorTextImportRestrictionDatesNotImplemented() Export
	
	Return NStr("vi = 'Ngày cấm kết nhập dữ liệu của các kỳ trước từ các ứng dụng khác
	                   |không được cung cấp cho bất kỳ gói trao đổi nào.';
	                   |ru = 'Даты запрета загрузки данных прошлых периодов из других приложений
	                   |не предусмотрены ни для одного плана обмена.';
	                   |en = 'No exchange plan is subject to data import restrictions
	                   |from other apps for the past period.'; fa = 'No exchange plan is subject to data import restrictions
	                   |from other apps for the past period.';
	                   |it = 'Даты запрета загрузки данных прошлых периодов из других приложений
	                   |не предусмотрены ни для одного плана обмена.';
	                   |pl = 'No exchange plan is subject to data import restrictions
	                   |from other apps for the past period.';
	                   |tr = 'Herhangi bir değişim planı için diğer uygulamalardan
	                   |geçmiş verilerinin indirilmesine ilişkin herhangi bir yasak tarihi yoktur.'");
	
EndFunction

Function IsPeriodClosingAddressee(PeriodEndAddressee) Export
	
	Return TypeOf(PeriodEndAddressee) = Type("CatalogRef.Users")
	    Or TypeOf(PeriodEndAddressee) = Type("CatalogRef.UserGroups")
	    Or TypeOf(PeriodEndAddressee) = Type("CatalogRef.ExternalUsers")
	    Or TypeOf(PeriodEndAddressee) = Type("CatalogRef.ExternalUsersGroups")
	    Or PeriodEndAddressee = Enums.PeriodClosingDatesPurposeTypes.ForAllUsers;
	
EndFunction

Function CalculatedPeriodClosingDates() Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PeriodClosingDates.Section AS Section,
	|	PeriodClosingDates.Object AS Object,
	|	PeriodClosingDates.User AS User,
	|	PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate,
	|	PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails,
	|	PeriodClosingDates.Comment AS Comment
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates";
	Table = Query.Execute().Unload();
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	For Each TableRow In Table Do
		TableRow.PeriodEndClosingDate = PeriodEndClosingDateByDetails(TableRow.PeriodEndClosingDateDetails,
			TableRow.PeriodEndClosingDate , BegOfDay);
	EndDo;
	
	Return Table;
	
EndFunction

// Updates chart of characteristic types PeriodClosingDatesSections according to the details in metadata.
Procedure UpdatePeriodClosingDatesSections() Export
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SectionsProperties = SectionsProperties();
	BlankSection = ChartsOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef();
	
	UpdatedSections = New Array;
	
	For Each SectionDetails In SectionsProperties.Sections Do
		If TypeOf(SectionDetails.Key) = Type("String")
		 Or Not ValueIsFilled(SectionDetails.Key) Then
			Continue;
		EndIf;
		SectionProperties = SectionDetails.Value; // See ChartsOfCharacteristicTypes.PeriodClosingDatesSections.SectionProperties
		UpdatedSections.Add(SectionProperties.Ref);
		
		BeginTransaction();
		Try
			DataLock = New DataLock;
			LockItem = DataLock.Add("ChartOfCharacteristicTypes.PeriodClosingDatesSections");
			LockItem.SetValue("Ref", SectionProperties.Ref);
			DataLock.Lock();
			
			Object = SectionProperties.Ref.GetObject();
			Write = False;
			
			If Object = Undefined Then
				Object = ChartsOfCharacteristicTypes.PeriodClosingDatesSections.CreateItem();
				Object.SetNewObjectRef(SectionProperties.Ref);
				Write = True;
			EndIf;
			
			If Object.Description <> SectionProperties.Presentation Then
				Object.Description = SectionProperties.Presentation;
				Write = True;
			EndIf;
			
			If Object.DeletionMark Then
				Object.DeletionMark = False;
				Write = True;
			EndIf;
			
			If ValueIsFilled(Object.DeleteNewRef) Then
				Object.DeleteNewRef = BlankSection;
				Write = True;
			EndIf;
			
			ObjectsTypes = New Array;
			If SectionProperties.ObjectsTypes.Count() = 0 Then
				ObjectsTypes.Add(TypeOf(BlankSection));
			Else
				For Each TypeProperties In SectionProperties.ObjectsTypes Do
					ObjectsTypes.Add(TypeOf(TypeProperties.EmptyRef));
				EndDo;
			EndIf;
			If Object.ValueType.Types().Count() <> ObjectsTypes.Count() Then
				Object.ValueType = New TypeDescription(ObjectsTypes);
				Write = True;
			Else
				For Each Type In ObjectsTypes Do
					If Not Object.ValueType.ContainsType(Type) Then
						Object.ValueType = New TypeDescription(ObjectsTypes);
						Write = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Write Then
				InfobaseUpdate.WriteObject(Object, False);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	// Mark not predefined obsolete sections for deletion.
	BeginTransaction();
	Try
		DataLock = New DataLock;
		LockItem = DataLock.Add("ChartOfCharacteristicTypes.PeriodClosingDatesSections");
		LockItem.Mode = DataLockMode.Shared;
		DataLock.Lock();

		Query = New Query;
		Query.SetParameter("Sections", UpdatedSections);
		Query.Text =
		"SELECT
		|	Sections.Ref AS Ref,
		|	Sections.PredefinedDataName AS PredefinedDataName,
		|	Sections.DeleteNewRef AS DeleteNewRef
		|FROM
		|	ChartOfCharacteristicTypes.PeriodClosingDatesSections AS Sections
		|WHERE
		|	NOT Sections.DeletionMark
		|	AND NOT Sections.Ref IN (&Sections)
		|	AND Sections.PredefinedDataName = """"";
		
		DeprecatedSections = Query.Execute().Unload();
		
		LockItem = DataLock.Add("ChartOfCharacteristicTypes.PeriodClosingDatesSections");
		LockItem.DataSource = DeprecatedSections;
		LockItem.UseFromDataSource("Ref", "Ref");  
		DataLock.Lock();
		
		For Each DeprecatedSection In DeprecatedSections Do
			If ValueIsFilled(DeprecatedSection.DeleteNewRef)
			   And Common.DataSeparationEnabled() Then
				Continue;
			EndIf;
			Object = DeprecatedSection.Ref.GetObject();
			Object.DeletionMark = True;
			InfobaseUpdate.WriteData(Object, False);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Filling handler of the common initial period-end closing date before 1980.
Procedure SetInitialPeriodEndClosingDate() Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	RecordSet.Read();
	
	If RecordSet.Count() <> 0 Then
		Return;
	EndIf;
	
	BlankSection = EmptyRef(Type("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	
	Record = RecordSet.Add();
	Record.User = Enums.PeriodClosingDatesPurposeTypes.ForAllUsers;
	Record.Section       = BlankSection;
	Record.Object       = BlankSection;
	Record.PeriodEndClosingDate  = '19791231';
	
	InfobaseUpdate.WriteData(RecordSet);
	
EndProcedure

// Handler converts a chart of characteristic types to period-end closing date sections.
Procedure ClearPredefinedItemsInClosingDatesSections() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	ChartOfCharacteristicTypes.PeriodClosingDatesSections AS Sections
	|WHERE
	|	Sections.PredefinedDataName <> """"";
	
	If Query.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	SectionsProperties = SectionsProperties();
	PredefinedItemsNames =
		Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.GetPredefinedNames();
	
	Block = New DataLock;
	Block.Add("ChartOfCharacteristicTypes.PeriodClosingDatesSections");
	
	Query.Text =
	"SELECT
	|	Sections.Ref AS Ref,
	|	Sections.PredefinedDataName AS PredefinedDataName
	|FROM
	|	ChartOfCharacteristicTypes.PeriodClosingDatesSections AS Sections
	|WHERE
	|	Sections.PredefinedDataName <> """"";
	
	BeginTransaction();
	Try
		Block.Lock();
		UpdatePeriodClosingDatesSections();
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Object = Selection.Ref.GetObject();
			If PredefinedItemsNames.Find(Selection.PredefinedDataName) <> Undefined Then
				ObjectNamePrefix = "Delete";
				If Not StrStartsWith(Selection.PredefinedDataName, ObjectNamePrefix) Then
					Object.DeletionMark = True;
				Else
					SoughtName = Mid(Selection.PredefinedDataName, StrLen(ObjectNamePrefix) + 1);
					SectionProperties = SectionsProperties.Sections.Get(SoughtName); // See ChartsOfCharacteristicTypes.PeriodClosingDatesSections.SectionProperties
					
					If SectionProperties = Undefined Then
						Object.DeletionMark = True;
						
					ElsIf Selection.Ref <> SectionProperties.Ref Then
						Object.DeleteNewRef = SectionProperties.Ref;
						Object.Description = "(" + NStr("vi = 'không sử dụng';
														|ru = 'не используется';
														|en = 'not applicable'; fa = 'not applicable';
														|it = 'non viene utilizzato';
														|pl = 'nie używane';
														|tr = 'kullanılmıyor'") + ") " + SectionProperties.Presentation;
					EndIf;
				EndIf;
			ElsIf SectionsProperties.Sections.Get(Selection.Ref) = Undefined Then
				Object.DeletionMark = True;
			EndIf;
			Object.PredefinedDataName = "";
			InfobaseUpdate.WriteData(Object, False);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Handler replaces sections of period-end closing dates in the register with the new ones.
Procedure ReplaceClosingDatesSectionsWithNewOnes() Export
	
	Block = New DataLock;
	Block.Add("InformationRegister.PeriodClosingDates");
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Sections.Ref AS Ref,
	|	Sections.DeleteNewRef AS DeleteNewRef
	|FROM
	|	ChartOfCharacteristicTypes.PeriodClosingDatesSections AS Sections
	|		INNER JOIN InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|		ON (PeriodClosingDates.Section = Sections.Ref)
	|			AND (Sections.DeleteNewRef <> VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef))";
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			OldRecords = InformationRegisters.PeriodClosingDates.CreateRecordSet();
			OldRecords.Filter.Section.Set(Selection.Ref);
			OldRecords.Read();
			NewRecords = InformationRegisters.PeriodClosingDates.CreateRecordSet();
			NewRecords.Filter.Section.Set(Selection.DeleteNewRef);
			NewRecords.Read();
			If NewRecords.Count() > 0 Then
				OldRecords.Clear();
				InfobaseUpdate.WriteData(OldRecords, False);
			Else
				For Each OldRecord In OldRecords Do
					NewRecord = NewRecords.Add();
					FillPropertyValues(NewRecord, OldRecord);
					NewRecord.Section = Selection.DeleteNewRef;
					If OldRecord.Section = OldRecord.Object Then
						NewRecord.Object = Selection.DeleteNewRef;
					EndIf;
				EndDo;
				OldRecords.Clear();
				InfobaseUpdate.WriteData(OldRecords, False);
				InfobaseUpdate.WriteData(NewRecords, False);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Supplements settings for users, groups, nodes, and exchange plans.
Procedure AppendSettingsForGivenAddressees() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PeriodClosingDates.User,
	|	MAX(PeriodClosingDates.Comment) AS Comment
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|
	|GROUP BY
	|	PeriodClosingDates.User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserGroupCompositions.User AS User,
	|	UserGroupCompositions.UsersGroup AS UsersGroup
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		INNER JOIN InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|		ON UserGroupCompositions.UsersGroup = PeriodClosingDates.User
	|			AND (UserGroupCompositions.UsersGroup <> UserGroupCompositions.User)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodClosingDates.User AS User,
	|	PeriodClosingDates.Section AS Section,
	|	PeriodClosingDates.Object AS Object,
	|	PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate,
	|	PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates";
	
	Block = New DataLock;
	Block.Add("InformationRegister.PeriodClosingDates");
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResults = Query.ExecuteBatch();
		SettingsAddressees    = QueryResults[0].Unload();
		UserGroups = QueryResults[1].Unload();
		Settings           = QueryResults[2].Unload();
		RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
		AddSettings(RecordSet, Settings, SettingsAddressees, UserGroups, True);
		AddSettings(RecordSet, Settings, SettingsAddressees, UserGroups, False);
		InfobaseUpdate.WriteRecordSet(RecordSet, False);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// For the PeriodEndClosingDatesCheckDisabled function.
Function PeriodEndClosingNotUsed(PeriodClosingCheck, ImportRestrictionCheckNode)
	
	If InfobaseUpdate.InfobaseUpdateRequired() Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	
	EffectiveClosingDates = EffectiveClosingDates();
	
	If (Not EffectiveClosingDates.PeriodClosingUsed
	      Or PeriodClosingCheck = False)
	   And (Not EffectiveClosingDates.ImportRestrictionUsed
	      Or ImportRestrictionCheckNode = Undefined) Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For the ChangeOrImportRestricted function.
Function DataToCheckFromDatabase(Data, DataID, EffectiveDates, ImportRestrictionCheckNode)
	
	If TypeOf(DataID) = Type("Filter") Then
		If TypeOf(Data) = Type("String") Then
			MetadataObject = Common.MetadataObjectByFullName(Data);
		Else
			MetadataObject = Data.Metadata();
		EndIf;
	Else
		MetadataObject = DataID.Metadata();
	EndIf;
	
	Table = MetadataObject.FullName();
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	PeriodClosingDatesOverridable.BeforeCheckOldDataVersion(MetadataObject, DataID,
		ImportRestrictionCheckNode, DataToCheck);
		
	If DataToCheck.Count() > 0 Then
		Return DataToCheck;
	EndIf;
	
	NoObject = ?(ImportRestrictionCheckNode = Undefined,
		EffectiveDates.ForUsers.ClosingDatesByObjectsNotSpecified,
		EffectiveDates.ForInfobases.ClosingDatesByObjectsNotSpecified);
		
	DataSources = ReceiveDataSources(EffectiveDates, Table);
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	Query = New Query;
	If NoObject Then
		Query.Text = DataSources.QueryTextDatesOnly;
	Else
		Query.Text = DataSources.QueryText;
	EndIf;
	If DataSources.IsRegister Then
		Common.FilterSetRecordsFromDatabase(DataID,, Query);
	Else
		Query.SetParameter("Ref", DataID);
	EndIf;
	QueryResults = Query.ExecuteBatch();
	For Each DataSource In DataSources.Content Do
		Selection = QueryResults[DataSources.Content.Find(DataSource)].Select();
		While Selection.Next() Do
			// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
			AddDataStringFromDatabase(Selection, DataSource, DataToCheck, NoObject);
		EndDo;
	EndDo;
	
	Return DataToCheck;
	
EndFunction

// For the ChangeOrImportRestricted function.
Function DataForCheckFromObject(Data, EffectiveDates, ImportRestrictionCheckNode)
	
	FieldValues = New Structure;
	MetadataObject = Data.Metadata();
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	PeriodClosingDatesOverridable.BeforeCheckNewDataVersion(MetadataObject, Data,
		ImportRestrictionCheckNode, DataToCheck);
	
	If DataToCheck.Count() > 0 Then
		Return DataToCheck;
	EndIf;
	
	NoObject = ?(ImportRestrictionCheckNode = Undefined,
		EffectiveDates.ForUsers.ClosingDatesByObjectsNotSpecified,
		EffectiveDates.ForInfobases.ClosingDatesByObjectsNotSpecified);
	
	Table = MetadataObject.FullName();
	DataSources = ReceiveDataSources(EffectiveDates, Table);
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	
	If DataSources.IsRegister Then
		FieldValues = Data.Unload(, DataSources.RegisterFields); //  ValueTable
		FieldValues.GroupBy(DataSources.RegisterFields);
		If FieldValues.Columns.Find("Recorder") <> Undefined
		   And Data.Filter.Find("Recorder") <> Undefined
		   And Data.Filter.Recorder.Use
		   And Common.IsInformationRegister(MetadataObject) Then
			FieldValues.FillValues(Data.Filter.Recorder.Value, "Recorder");
		EndIf;
		For Each TableRow In FieldValues Do
			For Each DataSource In DataSources.Content Do
				// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
				AddDataString(TableRow, TableRow, DataSource, DataToCheck, NoObject);
			EndDo;
		EndDo;
	Else
		For Each DataSource In DataSources.Content Do
			
			If Not ValueIsFilled(DataSource.DateField.TabularSection)
			   And Not ValueIsFilled(DataSource.ObjectField.TabularSection) Then
				// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
				AddDataString(Data, Data, DataSource, DataToCheck, NoObject);
				
			ElsIf Not ValueIsFilled(DataSource.DateField.TabularSection) Then
				
				If NoObject Then
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					AddDataString(Data, Undefined, DataSource, DataToCheck, NoObject);
				Else
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					DateString = New Structure("Value", Simple(Data, DataSource.DateField));
					Field = DataSource.ObjectField.Name;
					ObjectValues = Data[DataSource.ObjectField.TabularSection].Unload(, Field); // ValueTable
					ObjectValues.GroupBy(Field);
					For Each ObjectString In ObjectValues Do
						// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
						AddDataString(DateString, ObjectString, DataSource, DataToCheck);
					EndDo;
				EndIf;
				
			ElsIf Not ValueIsFilled(DataSource.ObjectField.TabularSection) Then
				
				If Not NoObject Then
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					ObjectString = New Structure("Value", Simple(Data, DataSource.ObjectField));
				EndIf;
				Field = DataSource.DateField.Name;
				DateValues = Data[DataSource.DateField.TabularSection].Unload(, Field); // ValueTable
				DateValues.GroupBy(Field);
				For Each DateString In DateValues Do
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					AddDataString(DateString, ObjectString, DataSource, DataToCheck, NoObject);
				EndDo;
			
			ElsIf DataSource.DateField.TabularSection = DataSource.ObjectField.TabularSection Then
				
				If NoObject Then
					Fields = DataSource.DateField.Name;
				Else
					Fields = DataSource.DateField.Name + "," + DataSource.ObjectField.Name;
				EndIf;
				Values = Data[DataSource.DateField.TabularSection].Unload(, Fields); // ValueTable
				Values.GroupBy(Fields);
				For Each TableRow In Values Do
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					AddDataString(TableRow, TableRow, DataSource, DataToCheck, NoObject);
				EndDo;
			Else
				Field = DataSource.DateField.Name;
				DateValues = Data[DataSource.DateField.TabularSection].Unload(, Field); // ValueTable
				DateValues.GroupBy(Field);
				
				If Not NoObject Then
					Field = DataSource.ObjectField.Name;
					ObjectValues = Data[DataSource.ObjectField.TabularSection].Unload(, Field); // ValueTable
					ObjectValues.GroupBy(Field);
				EndIf;
				
				For Each DateString In DateValues Do
					// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
					DateString = New Structure("Value", Simple(DateString, DataSource.DateField));
					If NoObject Then
						// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
						AddDataString(DateString, Undefined, DataSource, DataToCheck, NoObject);
					Else
						For Each ObjectString In ObjectValues Do
							// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
							AddDataString(DateString, ObjectString, DataSource, DataToCheck);
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	Return DataToCheck;
	
EndFunction

// For procedures DataToCheckFromDatabase, DataForCheckFromObject.
// 
// Parameters:
//  EffectiveDates - FixedStructure
//  Table - String
// Returns:
//  FixedStructure:
//    * Content - FixedArray of See DataSourceDescription
//    * QueryText - String
//    * QueryTextDatesOnly - String
//    * IsRegister - Boolean
// 
Function ReceiveDataSources(EffectiveDates, Table)
	
	DataSources = EffectiveDates.DataSources.Get(Table);
	
	If DataSources = Undefined
	 Or DataSources.Count() = 0 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với bảng ""%1""
			           |trong thủ tục %2
			           |của mô-đun chung %3
			           |chưa chỉ ra nguồn dữ liệu cần thiết để kiểm tra ngày cấm.';
			           |ru = 'Для таблицы ""%1""
			           |в процедуре %2
			           |общего модуля %3
			           |не указаны источники данных, необходимые для проверки дат запрета.';
			           |en = 'In procedure ""%2""
			           |of common module ""%3"",
			           |table ""%1"" is missing the data source
			           |required for checking restriction dates.'; fa = 'In procedure ""%2""
			           |of common module ""%3"",
			           |table ""%1"" is missing the data source
			           |required for checking restriction dates.';
			           |it = 'Per la tabella ""%1 ""
			           | nella procedura %2
			           |del modulo comune %3
			           | non sono indicate le fonti dati necessarie per la verifica delle date di divieto.';
			           |pl = 'W tabeli „%1”
			           |w procedurze %2
			           |ogólnego modułu %3
			           |nie określa źródeł danych niezbędnych do sprawdzenia dat zakazu.';
			           |tr = '%3
			           |genel modülün %2
			           | prosedüründeki ""%1""
			           | iki tablo için kapanış tarihlerin kontrolünde gereken veri kaynakları belirtilmedi.'"),
			Table,
			"FillDataSourcesForPeriodClosingCheck",
			"PeriodClosingDatesOverridable");
		Raise ErrorText;
	EndIf;
	
	Return DataSources;
	
EndFunction

// For the DataToCheckFromDatabase function.
Procedure AddDataStringFromDatabase(String, DataSource, DataToCheck, NoObject)
	
	NewRow = DataToCheck.Add();
	NewRow.Section = DataSource.Section;
	DateField = New Structure("Name, Path", "Date", DataSource.DateField.Path);
	NewRow.Date = Simple(String, DateField);
	
	If NoObject Or Not ValueIsFilled(DataSource.ObjectField.Name) Then
		Return;
	EndIf;
	
	ObjectField = New Structure("Name, Path", "Object", DataSource.ObjectField.Path);
	NewRow.Object = Simple(String, ObjectField);
	
EndProcedure

// For the DataForCheckFromObject procedure.
Procedure AddDataString(DateString, ObjectString, DataSource, DataToCheck, NoObject = False)
	
	NewRow = DataToCheck.Add();
	NewRow.Section = DataSource.Section;
	NewRow.Date = Simple(DateString, DataSource.DateField);
	
	If NoObject Or Not ValueIsFilled(DataSource.ObjectField.Name) Then
		Return;
	EndIf;
	
	NewRow.Object = Simple(ObjectString, DataSource.ObjectField);
	
EndProcedure

// For the AddDataString procedure.
Function Simple(FieldValues, Field)
	
	If TypeOf(FieldValues) = Type("Structure") Then
		Return FieldValues.Value;
	EndIf;
	
	If Not ValueIsFilled(Field.Path) Then
		Return FieldValues[Field.Name];
	EndIf;
	
	QueryText =
	"SELECT
	|	CurrentTable.PathsField AS Value
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	CurrentTable.Ref = &CurrentRef";
	
	PathFields = StrSplit(Field.Path, ".", False);
	CurrentRef = FieldValues[Field.Name];
	
	For Each PathsField In PathFields Do
		RefMetadata = Metadata.FindByType(TypeOf(CurrentRef));
		If RefMetadata = Undefined Then
			Return Undefined;
		EndIf;
		Table = RefMetadata.FullName();
		HeaderFields = PeriodClosingDatesInternalCached.HeaderFields(Table);
		If Not HeaderFields.Property(PathsField) Then
			Return Undefined;
		EndIf;
		Query = New Query;
		Query.Text = StrReplace(QueryText, "PathsField", PathsField);
		Query.Text = StrReplace(Query.Text, "&CurrentTable", Table);
		Query.SetParameter("CurrentRef", CurrentRef);
		// @skip-check query-in-loop - A loop to exclude dereference of a composite type (Standard 654)
		Selection = Query.Execute().Select();
		If Not Selection.Next() Then
			Return Undefined;
		EndIf;
		CurrentRef = Selection.Value;
	EndDo;
	
	Return Selection.Value;
	
EndFunction

// For the SessionParametersSetting procedure.
// 
// Returns:
//  FixedStructure:
//    * Version - UUID
//    * UserGroups - FixedMap
//    * ForInfobases - See SetDates
//    * ForUsers - See SetDates
//    * ImportRestrictionUsed - Boolean
//    * PeriodClosingUsed - Boolean
//    * DataSources - FixedMap
//    * BegOfDay - Date
//    * SectionsProperties - See SectionsProperties
// 
Function SessionParameterValueEffectivePeriodClosingDates() Export
	
	// See the priority of period-end closing dates and data import restriction dates
	// in the function "PeriodEndClosingFound".
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	EffectiveDates = New Structure;
	EffectiveDates.Insert("BegOfDay", BegOfDay);
	
	AddresseesTypes = Metadata.DefinedTypes.PeriodClosingTarget.Type.Types();
	NodesAddresseesTypes = New Array;
	UsersAddresseesTypes = New Array;
	For Each AddresseesType In AddresseesTypes Do
		MetadataObject = Metadata.FindByType(AddresseesType);
		If Metadata.ExchangePlans.Contains(MetadataObject) Then
			NodesAddresseesTypes.Add(AddresseesType);
		ElsIf AddresseesType <> Type("EnumRef.PeriodClosingDatesPurposeTypes") Then
			UsersAddresseesTypes.Add(AddresseesType);
		EndIf;
	EndDo;
	
	EffectiveDates.Insert("SectionsProperties", CurrentSectionsProperties(NodesAddresseesTypes));
	
	If Common.SeparatedDataUsageAvailable() Then
		QueryResults = PeriodClosingDatesRequest().ExecuteBatch();
		
		ConstantValues = QueryResults[0].Unload()[0];
		EffectiveDates.Insert("Version",                      ConstantValues.PeriodClosingDatesVersion);
		EffectiveDates.Insert("PeriodClosingUsed", ConstantValues.UsePeriodClosingDates);
		EffectiveDates.Insert("ImportRestrictionUsed",  ConstantValues.UseImportForbidDates);
		
		Upload0 = QueryResults[1].Unload(QueryResultIteration.ByGroups);
		UserGroups = New Map;
		For Each TableRow In Upload0.Rows Do
			UserGroups.Insert(TableRow.User,
				New FixedArray(TableRow.Rows.UnloadColumn("UsersGroup")));
		EndDo;
		EffectiveDates.Insert("UserGroups", New FixedMap(UserGroups));
		
		EffectiveDates.Insert("ForUsers",     SetDates(QueryResults[2], BegOfDay));
		EffectiveDates.Insert("ForInfobases", SetDates(QueryResults[3], BegOfDay));
	Else
		EffectiveDates.Insert("Version", CommonClientServer.BlankUUID());
		EffectiveDates.Insert("PeriodClosingUsed", False);
		EffectiveDates.Insert("ImportRestrictionUsed",  False);
		EffectiveDates.Insert("UserGroups", New FixedMap(New Map));
		SetDates = New Structure;
		SetDates.Insert("Recipients", New FixedMap(New Map));
		SetDates.Insert("ClosingDatesByObjectsNotSpecified", True);
		EffectiveDates.Insert("ForUsers",     New FixedStructure(SetDates));
		EffectiveDates.Insert("ForInfobases", New FixedStructure(SetDates));
	EndIf;
	
	If EffectiveDates.ForUsers.Recipients.Count() = 0 Then
		EffectiveDates.PeriodClosingUsed = False;
	EndIf;
	
	If EffectiveDates.ForInfobases.Recipients.Count() = 0
	 Or NodesAddresseesTypes.Count() = 0 Then
		
		EffectiveDates.ImportRestrictionUsed = False;
	EndIf;
	
	EffectiveDates.Insert("DataSources", 
		CurrentDataSourceForPeriodClosingCheck(EffectiveDates.SectionsProperties));
	
	Return New FixedStructure(EffectiveDates);
	
EndFunction

// Intended for "PeriodEndClosingFound" function.

Function FindPeriodEndClosingDate(Sections, Data, BlankSection)
	
	RestrictionSection = Data.Section;
	RestrictionObject = Data.Object;
	PeriodEndClosingDate = Undefined;
	
	Objects = Sections.Get(RestrictionSection);
	If Objects <> Undefined Then
		// Search for a section and object.
		PeriodEndClosingDate = Objects.Get(RestrictionObject);
		If PeriodEndClosingDate = Undefined Then
			RestrictionObject = RestrictionSection;
			// Search for a section and any object.
			PeriodEndClosingDate = Objects.Get(RestrictionObject);
		EndIf;
	EndIf;
	
	If PeriodEndClosingDate = Undefined Then
		RestrictionSection = BlankSection;
		RestrictionObject = BlankSection;
		Objects = Sections.Get(RestrictionSection);
		If Objects <> Undefined Then
			// Search for any section and any object (common date).
			PeriodEndClosingDate = Objects.Get(RestrictionObject);
		EndIf;
	EndIf;
	
	If PeriodEndClosingDate = Undefined Then
		Return Undefined;
	EndIf;
	
	SearchResult = New Structure;
	SearchResult.Insert("RestrictionSection", RestrictionSection);
	SearchResult.Insert("RestrictionObject", RestrictionObject);
	SearchResult.Insert("PeriodEndClosingDate", PeriodEndClosingDate);
	
	Return SearchResult;
	
EndFunction

Function PeriodEndMessages(PeriodEnds, PeriodEndMessageParameters, SectionsProperties, SearchImportRestrictions, StructuralDetails)
	
	NewVersion = PeriodEndMessageParameters.NewVersion;
	IsRegister = False;
	Text = DataPresentation(PeriodEndMessageParameters.Data, IsRegister);
	
	If StructuralDetails Then
		ErrorDescription = New Structure;
		ErrorDescription.Insert("DataPresentation", Text);
		ErrorDescription.Insert("PeriodEnds", New ValueTable);
		Columns = ErrorDescription.PeriodEnds.Columns;
		Columns.Add("Date",            New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date)));
		Columns.Add("Section",          New TypeDescription("String",,,,New StringQualifiers(100, AllowedLength.Variable)));
		Columns.Add("Object",          Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.Type);
		Columns.Add("PeriodEndClosingDate",     New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date)));
		Columns.Add("SingleDate",       New TypeDescription("Boolean"));
		Columns.Add("ForAllObjects", New TypeDescription("Boolean"));
		Columns.Add("Addressee",         Metadata.DefinedTypes.PeriodClosingTarget.Type);
		Columns.Add("LongDesc",        New TypeDescription("String",,,,New StringQualifiers(1000,AllowedLength.Variable)));
	EndIf;
	
	If ValueIsFilled(Text) Then
		If SearchImportRestrictions Then
			If NewVersion Then
				Template = NStr("vi = '%1 không thể tải trong khoảng thời gian bị cấm.';
								|ru = '%1 невозможно загрузить в запрещенный период.';
								|en = 'Cannot import %1 after period-end closing date.'; fa = 'Cannot import %1 after period-end closing date.';
								|it = '%1Impossibile scaricare durante il periodo di divieto';
								|pl = '%1 niemożliwe jest pobranie w niedozwolony okres.';
								|tr = '%1 yasaklanmış dönemde yüklenemez.'");
			Else
				Template = NStr("vi = '%1 trong khoảng thời gian bị cấm, nó không thể được thay thế bằng dữ liệu có thể tải xuống.';
								|ru = '%1 в запрещенном периоде невозможно заменить загружаемыми данными.';
								|en = 'Imported data cannot replace %1 after period-end closing date.'; fa = 'Imported data cannot replace %1 after period-end closing date.';
								|it = '%1 Durante il periodo di divieto è impossibile sostituire i dati scaricati.';
								|pl = '%1 w zakazanym okresie jest niemożliwa zmiana pobieranymi danymi.';
								|tr = '%1 yasaklanmış dönemde yüklenen veriler ile doldurulamaz.'");
			EndIf;
		Else
			If NewVersion Then
				Template = NStr("vi = '%1 không thể đặt trong khoảng thời gian bị cấm.';
								|ru = '%1 невозможно поместить в запрещенный период.';
								|en = 'Cannot store %1 after period-end closing date.'; fa = 'Cannot store %1 after period-end closing date.';
								|it = '%1 Impossibile inserire nel periodo di divieto.';
								|pl = '%1 jest niemożliwe umieścić w niedozwolonym okresie.';
								|tr = '%1 yasaklanmış dönemde yerleştirilemez.'");
			ElsIf IsRegister And IsDataSetDeletion(PeriodEndMessageParameters.Data) Then
				Template = NStr("vi = '%1 không thể xóa trong khoảng thời gian bị cấm.';
								|ru = '%1 невозможно удалить в запрещенном периоде.';
								|en = 'Cannot delete %1 after period-end closing date.'; fa = 'Cannot delete %1 after period-end closing date.';
								|it = '%1 impossibile cancellare nel periodo non consentito.';
								|pl = '%1 jest niemożliwe usunąć w niedozwolonym okresie.';
								|tr = '%1 yasaklanmış dönemde silinemez.'");
			Else
				Template = NStr("vi = '%1 không thể thay đổi trong khoảng thời gian bị cấm.';
								|ru = '%1 невозможно изменить в запрещенном периоде.';
								|en = 'Cannot change %1 after period-end closing date.'; fa = 'Cannot change %1 after period-end closing date.';
								|it = '%1 impossibile modificare nel periodo non consentito.';
								|pl = '%1 jest niemożliwe zmienić w niedozwolonym okresie.';
								|tr = '%1 yasaklanmış dönemde değiştirilemez.'");
			EndIf;
		EndIf;
		Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Text) + Chars.LF;
		If Not StructuralDetails Then
			Text = Text + "[HeaderSeparator]";
		EndIf;
		
	EndIf;
	
	BlankSection = EmptyRef(Type("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	
	If StructuralDetails Then
		ErrorDescription.Insert("ErrorTitle", TrimAll(Text));
	Else
		ErrorText = Text;
	EndIf;
	
	AddedTexts = New Map;
	For Each Prohibition In PeriodEnds Do
		Text = PeriodEndMessage(Prohibition, SearchImportRestrictions, SectionsProperties, BlankSection);
		
		If StructuralDetails Then
			Text = StrReplace(Text, "[SeparatorReadMore]", "");
			
			Validation = Prohibition.Data;
			SectionProperties = SectionsProperties.Sections.Get(Validation.Section); // See ChartsOfCharacteristicTypes.PeriodClosingDatesSections.SectionProperties
			
			ErrorDescriptionString = ErrorDescription.PeriodEnds.Add();
			ErrorDescriptionString.Date        = Validation.Date;
			ErrorDescriptionString.Section      = SectionProperties.Name;
			ErrorDescriptionString.Object      = ?(Validation.Object = Validation.Section, Undefined, Validation.Object);
			ErrorDescriptionString.PeriodEndClosingDate = Prohibition.Date;
			ErrorDescriptionString.SingleDate   = ?(ValueIsFilled(Prohibition.Section), False, True);
			ErrorDescriptionString.ForAllObjects = (Prohibition.Section = Prohibition.Object);
			ErrorDescriptionString.Addressee  = Prohibition.Addressee;
			ErrorDescriptionString.LongDesc = Text;
		ElsIf AddedTexts.Get(Text) = Undefined Then
			AddedTexts.Insert(Text, True);
			ErrorText = ErrorText + Text + "[MessageSeparator]";
		EndIf;
	EndDo;
	
	If Not StructuralDetails Then
		
		HeaderSeparator     = "";
		SeparatorReadMore = "";
		MessageSeparator  = "";
		
		If AddedTexts.Count() > 1 Then
			HeaderSeparator    = Chars.LF;
			MessageSeparator = Chars.LF + Chars.LF;
		Else
			SeparatorReadMore = Chars.LF;
		EndIf;
		
		ErrorText = StrReplace(ErrorText, "[HeaderSeparator]",     HeaderSeparator);
		ErrorText = StrReplace(ErrorText, "[SeparatorReadMore]", SeparatorReadMore);
		ErrorText = StrReplace(ErrorText, "[MessageSeparator]",  MessageSeparator);
		
		ErrorDescription = TrimR(ErrorText);
	EndIf;
	
	Return ErrorDescription;
	
EndFunction

Function PeriodEndMessage(Val Prohibition, Val SearchImportRestrictions, Val SectionsProperties, Val BlankSection)
	
	If Prohibition.Section = Prohibition.Object Then
		ByObject = False;
		BySection = Prohibition.Section <> BlankSection;
	Else
		ByObject = True;
		BySection = Not ValueIsFilled(SectionsProperties.SingleSection);
	EndIf;
	
	ForUnspecifiedOne = False;
	ForUser = False;
	ForUsersGroup = False;
	ForAllUsers = False;
	ForInfobase = False;
	ForAllPlanIBs = False;
	ForAllIBs = False;
	
	If Prohibition.Addressee = Enums.PeriodClosingDatesPurposeTypes.ForAllUsers Then
		ForAllUsers = True;
		
	ElsIf Prohibition.Addressee = Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases Then
		ForAllIBs = True;
		
	ElsIf TypeOf(Prohibition.Addressee) = Type("CatalogRef.UserGroups")
		Or TypeOf(Prohibition.Addressee) = Type("CatalogRef.ExternalUsersGroups") Then
		
		ForUsersGroup = True;
		
	ElsIf TypeOf(Prohibition.Addressee) = Type("CatalogRef.Users") Then
		
		If Prohibition.Addressee = Users.UnspecifiedUserRef() Then
			ForUnspecifiedOne = True;
		Else
			ForUser = True;
		EndIf;
		
	ElsIf TypeOf(Prohibition.Addressee) = Type("CatalogRef.ExternalUsers") Then
		ForUser = True;
		
	ElsIf ValueIsFilled(Prohibition.Addressee) Then
		ForInfobase = True;
	Else
		ForAllPlanIBs = True;
	EndIf;
	
	If Not SearchImportRestrictions Then
		If      Not BySection And Not ByObject And ForUnspecifiedOne Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Không thể thay đổi, vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Изменение недоступно, поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica non è disponibile perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Zmiana jest niedostępna, ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Değişiklik yapılamaz, çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForUnspecifiedOne Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Không thể thay đổi theo phân hệ ""%2"" 
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Изменение по разделу ""%2"" недоступно 
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per sezione ""%2"" non è disponibile 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Zmiana według rozdziału ""%2"" jest niedostępna,
			| ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%2"" bölümünde değişiklik yapılamaz
			|, çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForUnspecifiedOne Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Không thể thay đổi theo đối tượng ""%3"" 
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Изменение по объекту ""%3"" недоступно,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%3"" object
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%3"" object
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" non è disponibile 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Zmiana według obiektu ""%3"" jest niedostępna, 
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%3"" nesnede değişiklik yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForUnspecifiedOne Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Không thể thay đổi theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Изменение по объекту ""%3"" раздела ""%2"" недоступно,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" della sezione ""%2"" non è disponibile 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Zmiana według obiektu ""%3"" rozdziału ""%2"" jest niedostępna, 
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%2""bölümün ""%3"" nesnesinde değişiklik yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
		
		ElsIf Not BySection And Not ByObject And ForUser Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Người sử dụng ""%4"" không thể thay đổi,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Пользователю ""%4"" недоступно изменение,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%4"" user
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%4"" user
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica non è disponibile per l''utente ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla użytkownika ""%4"" jest niedostępna zmiana,
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı için değişiklik yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForUser Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Người sử dụng ""%4"" không thể thay đổi theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Пользователю ""%4"" недоступно изменение по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per sezione ""%2"" non è disponibile per l''utente ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla użytkownika ""%4"" jest niedostępna zmiana według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı için ""%2"" bölüm değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForUser Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Người sử dụng ""%4"" không thể thay đổi theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Пользователю ""%4"" недоступно изменение по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" non è disponibile per l''utente ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla użytkownika ""%4"" jest niedostępna zmiana według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı için ""%3"" nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForUser Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Người sử dụng ""%4"" không thể thay đổi theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Пользователю ""%4"" недоступно изменение по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" della sezione ""%2"" non è disponibile per l''utente ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla użytkownika ""%4"" jest niedostępna zmiana według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı için ""%3"" bölümün ""%2""nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
		
		ElsIf Not BySection And Not ByObject And ForUsersGroup Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Nhóm người sử dụng ""%4"" không thể thay đổi,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для группы пользователей ""%4"" недоступно изменение,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%4"" user group
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for the ""%4"" user group
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica non è disponibile per il gruppo di utenti ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla grupy użytkowników ""%4"" jest niedostępna zmiana,
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı grubu için değişiklik yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForUsersGroup Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Nhóm người sử dụng ""%4"" không thể thay đổi theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для группы пользователей ""%4"" недоступно изменение по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per sezione ""%2"" non è disponibile per il gruppo di utenti ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla grupy użytkowników ""%4"" jest niedostępna zmiana według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı grubu için ""%2"" bölüm değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForUsersGroup Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Nhóm người sử dụng ""%4"" không thể thay đổi theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для группы пользователей ""%4"" недоступно изменение по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" non è disponibile per il gruppo di utenti ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla grupy użytkowników ""%4"" jest niedostępna zmiana według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı grubu için ""%3"" nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForUsersGroup Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Nhóm người sử dụng ""%4"" không thể thay đổi theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для группы пользователей ""%4"" недоступно изменение по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|The ""%4"" user group cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" della sezione ""%2"" non è disponibile per il gruppo di utenti ""%4"" 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla grupy użytkowników ""%4"" jest niedostępna zmiana według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" kullanıcı grubu için ""%2"" bölümün ""%3"" nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And Not ByObject And ForAllUsers Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Tất cả người sử dụng không thể thay đổi,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех пользователей недоступно изменение,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for all users
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Change is not available for all users
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica non è disponibile per nessun utente
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich użytkowników jest niedostępna zmiana,
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm kullanıcılar için değişiklik yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForAllUsers Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Tất cả người sử dụng không thể thay đổi theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех пользователей недоступно изменение по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per sezione ""%2"" non è disponibile per nessun utente 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich użytkowników jest niedostępna zmiana według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm kullanıcılar için ""%2"" bölüm değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForAllUsers Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Tất cả người sử dụng không thể thay đổi theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех пользователей недоступно изменение по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%3"" object
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" non è disponibile per nessun utente 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich użytkowników jest niedostępna zmiana według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| tüm kullanıcılar için ""%3"" nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForAllUsers Then
			
			Text = NStr("vi = 'Cấm thay đổi dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Tất cả người sử dụng không thể thay đổi theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено изменять данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех пользователей недоступно изменение по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5'; fa = 'Cannot change data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|All users cannot change the ""%3"" object of the ""%2"" section
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere modificati.
			|[SeparatorReadMore]Dettagli:
			|La modifica per oggetto ""%3"" della sezione ""%2"" non è disponibile per nessun utente 
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabroniona jest zmiana danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich użytkowników jest niedostępna zmiana według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler değiştirilemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| tüm kullanıcılar için ""%2"" bölümün ""%3"" nesne değişikliği yapılamaz,
			| çünkü %1 tarihi %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		EndIf;
	Else
		If      Not BySection And Not ByObject And ForInfobase Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với cơ sở thông tin ""%4"" đã cấm kết nhập dữ liệu,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для информационной базы ""%4"" запрещена загрузка данных,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per l''infobase ""%4"" non è consentita l''importazione di dati
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla bazy informacyjnej ""%4"" zabronione jest pobieranie danych,
			| ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%4"" Infobase için veri yüklemesi yasak,
			| çünkü %1 tarih%5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForInfobase Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với cơ sở thông tin ""%4"" đã cấm kết nhập dữ liệu theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для информационной базы ""%4"" запрещена загрузка данных по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per l''infobase ""%4"" non è consentita l''importazione di dati per sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla bazy informacyjnej ""%4"" zabronione jest pobieranie danych według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%4"" Infobase için ""%2"" bölümünde veri yüklemesi yasak,
			| çünkü %1 tarih%5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForInfobase Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với cơ sở thông tin ""%4"" đã cấm kết nhập dữ liệu theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для информационной базы ""%4"" запрещена загрузка данных по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per l''infobase ""%4"" non è consentita l''importazione di dati per oggetto ""%3""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla bazy informacyjnej ""%4"" zabronione jest pobieranie danych według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%4"" Infobase için ""%3"" nesnede veri yüklemesi yasak,
			| çünkü %1 tarih%5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForInfobase Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với cơ sở thông tin ""%4"" đã cấm kết nhập dữ liệu theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для информационной базы ""%4"" запрещена загрузка данных по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for the ""%4"" infobase
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per l''infobase ""%4"" non è consentita l''importazione di dati per oggetto ""%3"" della sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla bazy informacyjnej ""%4"" zabronione jest pobieranie danych według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%4"" Infobase için ""%2"" bölümünde ""%3"" nesnede veri yüklemesi yasak,
			| çünkü %1 tarih %5 tarihine kadarki yasaklanmış döneme girmektedir'");
		
		ElsIf Not BySection And Not ByObject And ForAllPlanIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin ""%6"" đã cấm kết nhập dữ liệu,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз ""%6"" запрещена загрузка данных,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase ""%6"" non è consentita l''importazione di dati
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych ""%6"" zabronione jest pobieranie danych,
			| ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|""%6"" Tüm Infobase''ler için veri yüklemesi yasak,
			| çünkü %1 tarih %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForAllPlanIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin ""%6"" đã cấm kết nhập dữ liệu theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз ""%6"" запрещена загрузка данных по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase ""%6"" non è consentita l''importazione di dati per sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych ""%6"" zabronione jest pobieranie danych według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%6"" Tüm Infobase''ler için ""%2"" bölümünde veri yüklemesi yasak,
			| çünkü %1 tarih%5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForAllPlanIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin ""%6"" đã cấm kết nhập dữ liệu theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз ""%6"" запрещена загрузка данных по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase ""%6"" non è consentita l''importazione di dati per oggetto ""%3""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych ""%6"" zabronione jest pobieranie danych według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| ""%6"" Tüm Infobase''ler için ""%3"" nesnede veri yüklemesi yasak,
			| çünkü %1 tarih %5tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForAllPlanIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin ""%6"" đã cấm kết nhập dữ liệu theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз ""%6"" запрещена загрузка данных по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for all ""%6"" infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase ""%6"" non è consentita l''importazione di dati per oggetto ""%3"" della sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych ""%6"" zabronione jest pobieranie danych według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm ""%6"" Infobase''ler için ""%2"" bölümünde ""%3"" nesnede veri yüklemesi yasak,
			|çünkü %1 tarih %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		
		ElsIf Not BySection And Not ByObject And ForAllIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin đã cấm kết nhập dữ liệu,
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз запрещена загрузка данных,
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for all infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Data import is not allowed for all infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase non è consentita l''importazione di dati
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych zabronione jest pobieranie danych,
			| ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			| Tüm Infobase''ler için veri yüklemesi yasak,
			| çünkü %1 tarih %5tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And Not ByObject And ForAllIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin đã cấm kết nhập dữ liệu theo phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз запрещена загрузка данных по разделу ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for all infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%2"" section is not allowed for all infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase non è consentita l''importazione di dati per sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych zabronione jest pobieranie danych według rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm Infobase''ler için ""%2"" bölümünde veri yüklemesi yasak,
			| çünkü %1 tarih%5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf Not BySection And    ByObject And ForAllIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin đã cấm kết nhập dữ liệu theo đối tượng ""%3"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз запрещена загрузка данных по объекту ""%3"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for all infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object is not allowed for all infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase non è consentita l''importazione di dati per oggetto ""%3""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych zabronione jest pobieranie danych według obiektu ""%3"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm Infobase''ler için ""%3"" nesnede veri yüklemesi yasak,
			| çünkü %1 tarih %5tarihine kadarki yasaklanmış döneme girmektedir'");
			
		ElsIf    BySection And    ByObject And ForAllIBs Then
			
			Text = NStr("vi = 'Cấm kết nhập dữ liệu có ngày trước %5 (bao gồm).
			|[SeparatorReadMore]Chi tiết:
			|Đối với tất cả cơ sở thông tin đã cấm kết nhập dữ liệu theo đối tượng ""%3"" của phân hệ ""%2"",
			|vì ngày %1 nằm trong kỳ bị cấm theo %5';
			|ru = 'Запрещено загружать данные с датой ранее %5 (включительно).
			|[SeparatorReadMore]Подробнее:
			|Для всех информационных баз запрещена загрузка данных по объекту ""%3"" раздела ""%2"",
			|поскольку дата %1 входит в запрещенный период по %5';
			|en = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for all infobases
			|since date %1 falls within the closed period for %5'; fa = 'Cannot import data with a date earlier than %5 (inclusive).
			|[SeparatorReadMore]Details:
			|Importing data on the ""%3"" object of the ""%2"" section is not allowed for all infobases
			|since date %1 falls within the closed period for %5';
			|it = 'I dati con la data precedente al %5 (incluso) non possono essere importati.
			|[SeparatorReadMore]Dettagli:
			|Per tutti gli infobase non è consentita l''importazione di dati per oggetto ""%3"" della sezione ""%2""
			|perché la data %1 rientra nel periodo proibito fino al %5';
			|pl = 'Zabronione jest pobieranie danych z datą wcześniejszą niż %5 (włącznie).
			|[SeparatorReadMore]Szczegóły:
			|Dla wszystkich baz informacyjnych zabronione jest pobieranie danych według obiektu ""%3"" rozdziału ""%2"",
			|ponieważ data %1 jest częścią zabronionego okresu według %5';
			|tr = '%5 (dahil) tarihinden erken veriler yüklenemez.
			|[SeparatorReadMore]Daha fazla bilgi:
			|Tüm Infobase''ler için ""%2"" bölümünde  ""%3"" nesnede veri yüklemesi yasak,
			|çünkü %1 tarih %5 tarihine kadarki yasaklanmış döneme girmektedir'");
			
		EndIf;
	EndIf;
	
	If Not SectionsProperties.NoSectionsAndObjects Then
		If ValueIsFilled(Prohibition.Section) Then
			If Prohibition.Object = Prohibition.Section Then
				Text = Text + " " + NStr("vi = '(lệnh cấm được đặt trên phân hệ ""%2"")';
										|ru = '(запрет установлен на раздел ""%2"")';
										|en = 'The restriction is applied to section %2.'; fa = 'The restriction is applied to section %2.';
										|it = '(divieto impostato nel reparto ""%2"")';
										|pl = '(zakaz ustawiony na rozdział ""%2"")';
										|tr = '(""%2"" bölümü kısıtlı)'");
			ElsIf ValueIsFilled(SectionsProperties.SingleSection) Then
				Text = Text + " " + NStr("vi = '(lệnh cấm được đặt trên đối tượng ""%3"")';
										|ru = '(запрет установлен на объект ""%3"")';
										|en = 'The restriction is applied to object %3.'; fa = 'The restriction is applied to object %3.';
										|it = '(divieto impostato nell''oggetto ""%3"")';
										|pl = '(zakaz ustawiony na obiekt ""%3"")';
										|tr = '(""%3"" nesnesi kısıtlı)'");
			Else
				Text = Text + " " + NStr("vi = '(lệnh cấm được đặt trên đối tượng ""%3"" phân hệ ""%2"")';
										|ru = '(запрет установлен на объект ""%3"" раздела ""%2"")';
										|en = 'The restriction is applied to object %3 of section %2.'; fa = 'The restriction is applied to object %3 of section %2.';
										|it = '(divieto impostato nell''oggetto ""%3"" del reparto ""%2"")';
										|pl = '(zakaz ustawiony na obiekt ""%3"" rozdziału ""%2"")';
										|tr = '(""%2"" bölümünün ""%3"" nesnesi kısıtlı)'");
			EndIf;
		Else
			Text = Text + " " + NStr("vi = '(ngày cấm chung được đặt)';
									|ru = '(установлена общая дата запрета)';
									|en = 'Single-date restriction is applied.'; fa = 'Single-date restriction is applied.';
									|it = '(data generale di divieto impostata)';
									|pl = '(ustawiona ogólna data zakazu)';
									|tr = '(ortak dönem sonu kapanış tarihi belirlendi)'");
		EndIf;
	EndIf;
	
	Validation = Prohibition.Data;
	Text = StrReplace(Text, "%1", Format(Validation.Date, "DLF=D"));
	Text = StrReplace(Text, "%2", Validation.Section);
	Text = StrReplace(Text, "%3", Validation.Object);
	Text = StrReplace(Text, "%4", Prohibition.Addressee);
	Text = StrReplace(Text, "%5", Format(Prohibition.Date, "DLF=D"));
	Text = StrReplace(Text, "%6", Prohibition.Addressee.Metadata().Presentation());
	Return Text;

EndFunction

// For the PeriodEndMessage function.
Function DataPresentation(Data, IsRegister)
	
	If TypeOf(Data) = Type("String") Then
		Return TrimAll(Data);
	EndIf;
	
	If TypeOf(Data) = Type("Structure") Then
		IsRegister = True;
		If TypeOf(Data.Register) = Type("String") Then
			MetadataObject = Common.MetadataObjectByFullName(Data.Register);
		Else
			MetadataObject = Metadata.FindByType(TypeOf(Data.Register));
		EndIf;
	Else
		MetadataObject = Metadata.FindByType(TypeOf(Data));
		IsRegister = Common.IsRegister(MetadataObject);
	EndIf;
	
	If MetadataObject = Undefined Then
		Return "";
	EndIf;
	
	If IsRegister Then
		DataPresentation = MetadataObject.Presentation();
		
		FieldsCount = 0;
		For Each FilterElement In Data.Filter Do
			If FilterElement.Use Then
				FieldsCount = FieldsCount + 1;
			EndIf;
		EndDo;
		
		If FieldsCount = 1 Then
			DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 với trường %2';
					|ru = '%1 с полем %2';
					|en = '%1 with field %2'; fa = '%1 with field %2';
					|it = '%1 con il campo %2';
					|pl = '%1 z polem %2';
					|tr = '%2 alan ile %1'"),
				DataPresentation, String(Data.Filter));
			
		ElsIf FieldsCount > 1 Then
			DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 với trường %2';
					|ru = '%1 с полями %2';
					|en = '%1 with fields %2'; fa = '%1 with fields %2';
					|it = '%1 con i campi %2';
					|pl = '%1 z polami %2';
					|tr = '%2 alanlar ile %1'"),
				DataPresentation, String(Data.Filter));
		EndIf;
	Else
		DataPresentation = Common.SubjectString(Data);
	EndIf;
		
	Return DataPresentation;
	
EndFunction

// For the PeriodEndMessage function.
Function IsDataSetDeletion(Data)
	
	If TypeOf(Data) = Type("Structure") And TypeOf(Data.Register) <> Type("String") Then
		Return Data.Register.Count() = 0; // The register dataset being written has no records.
	Else
		Replacing = Data.AdditionalProperties.Replacing;
		If Common.IsRecordSetReplacement(Replacing) Then
			Return Data.Count() = 0;
		ElsIf Common.IsRecordSetDeletion(Replacing) Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Intended for "SessionParameterValueEffectivePeriodClosingDates" procedure.

Function PeriodClosingDatesRequest()
	
	// ACC-1377-off - No.654.2.1. Two comma-delimited types are acceptable especially
	// since the dataset is small (from units to hundreds).
	Query = New Query;
	Query.Text =
	"SELECT
	|	ConstantValues.PeriodClosingDatesVersion AS PeriodClosingDatesVersion,
	|	ConstantValues.UseImportForbidDates AS UseImportForbidDates,
	|	ConstantValues.UsePeriodClosingDates AS UsePeriodClosingDates
	|FROM
	|	Constants AS ConstantValues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserGroupCompositions.User AS User,
	|	UserGroupCompositions.UsersGroup AS UsersGroup,
	|	PeriodClosingDates.Comment AS Comment,
	|	ISNULL(UserGroupCompositions.UsersGroup.Description, """") AS GroupDescription
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		INNER JOIN InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|		ON UserGroupCompositions.UsersGroup = PeriodClosingDates.User
	|			AND (UserGroupCompositions.UsersGroup <> UserGroupCompositions.User)
	|
	|ORDER BY
	|	User,
	|	Comment DESC,
	|	GroupDescription DESC
	|TOTALS BY
	|	User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodClosingDates.User AS User,
	|	PeriodClosingDates.Section AS Section,
	|	PeriodClosingDates.Object AS Object,
	|	PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails,
	|	PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|WHERE
	|	(PeriodClosingDates.User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
	|			OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
	|			OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
	|			OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
	|			OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups))
	|TOTALS BY
	|	User,
	|	Section
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodClosingDates.User AS User,
	|	PeriodClosingDates.Section AS Section,
	|	PeriodClosingDates.Object AS Object,
	|	PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails,
	|	PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|WHERE
	|	PeriodClosingDates.User <> UNDEFINED
	|	AND PeriodClosingDates.User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.EmptyRef)
	|	AND PeriodClosingDates.User <> VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
	|	AND VALUETYPE(PeriodClosingDates.User) <> TYPE(Catalog.Users)
	|	AND VALUETYPE(PeriodClosingDates.User) <> TYPE(Catalog.UserGroups)
	|	AND VALUETYPE(PeriodClosingDates.User) <> TYPE(Catalog.ExternalUsers)
	|	AND VALUETYPE(PeriodClosingDates.User) <> TYPE(Catalog.ExternalUsersGroups)
	|TOTALS BY
	|	User,
	|	Section";
	// ACC:1377-on
	
	Return Query;
	
EndFunction

// Returns:
//  FixedStructure:
//   * ClosingDatesByObjectsNotSpecified - Boolean
//   * Recipients - FixedMap of KeyAndValue:
//      ** Key     - DefinedType.PeriodClosingTarget - Recipient.
//      ** Value - FixedMap of KeyAndValue:
//          *** Key     - String - Section name.
//          *** Value - FixedMap of KeyAndValue:
//               **** Key     - Characteristic.PeriodClosingDatesSections - Object.
//               **** Value - Date - Calculated period-end closing date.
//  
Function SetDates(QueryResult, BegOfDay)
	
	Upload0 = QueryResult.Unload(QueryResultIteration.ByGroups);
	
	Recipients = New Map;
	ClosingDatesByObjectsNotSpecified = True;
	
	For Each Addressee In Upload0.Rows Do
		Sections = New Map;
		For Each Section In Addressee.Rows Do
			Objects = New Map;
			For Each Object In Section.Rows Do
				If Section.Section <> Object.Object Then
					ClosingDatesByObjectsNotSpecified = False;
				EndIf;
				Objects.Insert(Object.Object, PeriodEndClosingDateByDetails(
					Object.PeriodEndClosingDateDetails, Object.PeriodEndClosingDate, BegOfDay));
			EndDo;
			Sections.Insert(Section.Section, New FixedMap(Objects));
		EndDo;
		Recipients.Insert(Addressee.User, New FixedMap(Sections));
	EndDo;
	
	SetDates = New Structure;
	SetDates.Insert("Recipients", New FixedMap(Recipients));
	SetDates.Insert("ClosingDatesByObjectsNotSpecified", ClosingDatesByObjectsNotSpecified);
	
	Return New FixedStructure(SetDates);
	
EndFunction

Function CurrentSectionsProperties(NodesAddresseesTypes)
	
	Properties = New Structure;
	Properties.Insert("UseExternalUsers", False);
	
	PeriodClosingDatesOverridable.InterfaceSetup(Properties);
	
	Properties.Insert("ImportRestrictionDatesImplemented", NodesAddresseesTypes.Count() > 0);
	
	EmptyNodesRefs = New Array;
	
	For Each NodesAddresseesType In NodesAddresseesTypes Do
		EmptyNodeRef = EmptyRef(NodesAddresseesType);
		EmptyNodesRefs.Add(EmptyNodeRef);
	EndDo;
	
	Properties.Insert("EmptyExchangePlansNodesRefs", New FixedArray(EmptyNodesRefs));
	
	SectionsProperties = ChartsOfCharacteristicTypes.PeriodClosingDatesSections.ClosingDatesSectionsProperties();
	
	For Each KeyAndValue In SectionsProperties Do
		Properties.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return New FixedStructure(Properties);
	
EndFunction

// Parameters:
//  SectionsProperties - See SectionsProperties
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String - Table name
//   * Value - See ReceiveDataSources
//
Function CurrentDataSourceForPeriodClosingCheck(SectionsProperties)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return New FixedMap(New Map);
	EndIf;
	
	DataSources = New ValueTable;
	DataSources.Columns.Add("Table",     New TypeDescription("String"));
	DataSources.Columns.Add("DateField",    New TypeDescription("String"));
	DataSources.Columns.Add("Section",      New TypeDescription("String"));
	DataSources.Columns.Add("ObjectField", New TypeDescription("String"));
	DataSources.Indexes.Add("Table");
	
	SSLSubsystemsIntegration.OnFillDataSourcesForPeriodClosingCheck(DataSources);
	PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck(DataSources);
	
	Sources = New Map;
	Tables = DataSources.Copy(, "Table");
	Tables.GroupBy("Table");
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong thủ tục %1
		           |của mô-đun chung %2.';
		           |ru = 'Ошибка в процедуре %1
		           |общего модуля %2.';
		           |en = 'Error in procedure %1
		           |of common module %2.'; fa = 'Error in procedure %1
		           |of common module %2.';
		           |it = 'Errore nella procedura %1
		           |del modulo generale%2.';
		           |pl = 'Błąd w procedurze %1
		           |do wspólnego modułu %2.';
		           |tr = '%2 genel modülün %1
		           | prosedüründe hata oluştu.'"),
		"FillDataSourcesForPeriodClosingCheck",
		"PeriodClosingDatesOverridable")
		+ Chars.LF
		+ Chars.LF;
	
	For Each TableRow In Tables Do
		TableSources = New Structure;
		MetadataObject = Common.MetadataObjectByFullName(TableRow.Table);
		If MetadataObject = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi trong nguồn dữ liệu đã chỉ ra sai bảng
				           |""%1"".';
				           |ru = 'Для проверки запрета изменения в источнике данных неверно указана таблица
				           |""%1"".';
				           |en = 'Period-end closing date check error. Data source contains invalid table:
				           |%1.'; fa = 'Period-end closing date check error. Data source contains invalid table:
				           |%1.';
				           |it = 'Per la verifica del divieto di modifica nella fonte dei dati, la tabella 
				           | ""%1"" è stata indicata in modo errato.';
				           |pl = 'Nieprawidłowo jest wskazana tabela dla weryfikacji zakazu zmiany w źródle danych
				           |""%1"".';
				           |tr = 'Değişiklik yasağı kontrolü için veri kaynağında 
				           |""%1"" tablosu yanlış belirtilmiştir.'"),
				TableRow.Table);
			Raise ErrorText;
		EndIf;
		IsRegister = StandardSubsystemsServer.IsRegisterTable(TableRow.Table);
		TableSources.Insert("IsRegister", IsRegister);
		
		TableDataSources = DataSources.FindRows(New Structure("Table", TableRow.Table));
		SourcesContent = New Array;
		RegisterFields = New Map;
		QueryText = "";
		QueryTextDatesOnly = "";
		Table = MetadataObject.FullName();
		
		For Each TableDataSource In TableDataSources Do
			SectionProperties = SectionsProperties.Sections.Get(TableDataSource.Section);
			If SectionProperties = Undefined Then
				ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Để kiểm tra việc cấm thay đổi trong nguồn dữ liệu, đã chỉ ra phân hệ
					           |không tồn tại ""%1"" đối với bảng ""%2""
					           |(xem %3).';
					           |ru = 'Для проверки запрета изменения в источнике данных указан несуществующий
					           |раздел ""%1"" для таблицы ""%2""
					           |(см. %3).';
					           |en = 'Non-existent section ""%1"" for table ""%2"" is specified
					           |for checking period-end closing dates in data source.
					           | See %3.'; fa = 'Non-existent section ""%1"" for table ""%2"" is specified
					           |for checking period-end closing dates in data source.
					           | See %3.';
					           |it = 'Per la verifica del divieto di modifica nella fonte dati è indicata la sezione
					           |inesistente ""%1"" per la tabella ""%2 ""
					           | (vedi %3).';
					           |pl = 'Dla weryfikacji zakazu zmiany w źródle danych jest wskazany nie istniejący 
					           |rozdział ""%1"" dla tabeli ""%2"" 
					           |(patrz %3).';
					           |tr = 'Dönem sonu kapanış kontrolü için ""%2""
					           | tablosunun veri kaynağında
					           |var olmayan ""%1"" bölümü belirtildi (bkz. %3).'"),
					TableDataSource.Section,
					TableDataSource.Table,
					"PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck");
				Raise ErrorText;
			EndIf;
			
			Source = DataSourceDescription();
			Source.Section = TableDataSource.Section;
			Source.DateField    = TableField(TableDataSource, "DateField",    MetadataObject, IsRegister);
			Source.ObjectField = TableField(TableDataSource, "ObjectField", MetadataObject, IsRegister);
			
			If IsRegister Then
				RegisterFields.Insert(Source.DateField.Name, True);
				If ValueIsFilled(Source.ObjectField.Name) Then
					AddQueryTextForRegister(QueryText, Table, Source);
					RegisterFields.Insert(Source.ObjectField.Name, True);
				Else
					AddQueryTextDatesOnlyForRegister(QueryText, Table, Source);
				EndIf;
				AddQueryTextDatesOnlyForRegister(QueryTextDatesOnly, Table, Source);
			Else
				If ValueIsFilled(Source.ObjectField.Name) Then
					AddQueryText(QueryText, Table, Source);
				Else
					AddQueryTextDatesOnly(QueryText, Table, Source);
				EndIf;
				AddQueryTextDatesOnly(QueryTextDatesOnly, Table, Source);
			EndIf;
			SourcesContent.Add(New FixedStructure(Source));
		EndDo;
		TableSources.Insert("Content", New FixedArray(SourcesContent));
		TableSources.Insert("QueryText", QueryText);
		TableSources.Insert("QueryTextDatesOnly", QueryTextDatesOnly);
		If IsRegister Then
			Fields = "";
			For Each KeyAndValue In RegisterFields Do
				Fields = Fields + "," + KeyAndValue.Key;
			EndDo;
			TableSources.Insert("RegisterFields", Mid(Fields, 2));
		EndIf;
		Sources.Insert(Table, New FixedStructure(TableSources));
	EndDo;
	
	Return New FixedMap(Sources);
	
EndFunction

// Returns:
//   Structure:
//     * Section - Arbitrary
//     * DateField - Structure:
//         ** Name - String
//         ** Path - String
//         ** TabularSection - String
//     * ObjectField - Structure:
//         ** Name - String
//         ** Path - String
//         ** TabularSection - String
// 
Function DataSourceDescription()
	
	DateField    = New Structure("Name, Path, TabularSection");
	ObjectField = New Structure("Name, Path, TabularSection");
	
	Source = New Structure;
	Source.Insert("Section",      Undefined);
	Source.Insert("DateField",    DateField);
	Source.Insert("ObjectField", ObjectField);
	
	Return Source;
	
EndFunction

// Intended for "CurrentDataSourcesForPeriodClosingCheck" function.

Function TableField(Source, FieldKind, MetadataObject, IsRegister)
	
	Properties = New Structure("Name, Path, TabularSection");
	
	Field = Source[FieldKind];
	Fields = StrSplit(Field, ".", False);
	
	If Fields.Count() = 0 Then
		If FieldKind = "DateField" Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |chưa đặt trường ngày.';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |не задано поле даты.';
				           |en = 'Period-end closing date check error.
				           |Data source contains table with empty Date field:
				           |%1.'; fa = 'Period-end closing date check error.
				           |Data source contains table with empty Date field:
				           |%1.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | non è indicato il campo della data.';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           |nie jest określono pole daty.';
				           |tr = 'Dönem sonu kapanışının kontrolü için
				           |""%1"" tablosunun veri kaynağında
				           |tarih alanı belirtilmemiş.'"),
				Source.Table);
			Raise ErrorText;
		Else
			Return New FixedStructure(Properties);
		EndIf;
		
	ElsIf Not ValueIsFilled(Fields[0]) Then
		If FieldKind = "DateField" Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã chỉ ra sai trường ngày: ""%2""';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле даты: ""%2""';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo della data è indicato in maniera errata: ""%2""';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           |nieprawidłowo określono pole daty: ""%2""';
				           |tr = '""%1"" tablosu için veri kaynağında
				           |dönem sonu kapanışını kontrol etmek için
				           |veri alanı yanlış belirtilmiş: ""%2""'"),
				Source.Table, Field);
			Raise ErrorText;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã đặt sai trường đối tượng: ""%2""';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле объекта: ""%2""';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo dell''oggetto è indicato in maniera errata: ""%2""';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           | jest nieprawidłowo określono pole obiektu ""%2"".';
				           |tr = '""%1"" tablosu için veri kaynağında
				           |değişiklik yasağını kontrol etmek için
				           |veri alanı yanlış belirtilmiştir: ""%2""'"),
				Source.Table, Field);
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If IsRegister
	 Or MetadataObject.TabularSections.Find(Fields[0]) = Undefined Then
		
		Properties.Name = Fields[0];
		PointPosition = StrFind(Field, ".");
		If PointPosition > 0 Then
			Properties.Path = Mid(Field, PointPosition + 1);
		EndIf;
		Return New FixedStructure(Properties);
	EndIf;
	
	If Fields.Count() = 1 Then
		If FieldKind = "DateField" Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã đặt sai trường ngày:
				           |chưa đặt trường phần bảng đã đặt ""%2"".';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле даты:
				           |не задано поле заданной табличной части ""%2"".';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |No field specified for tabular section:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |No field specified for tabular section:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo della data è indicato in maniera errata:
				           | non è indicato il campo della parte tabulare indicata ""%2"".';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           |nieprawidłowo określono pole daty: 
				           | nie określono pole określonej części tabelarycznej""%2""';
				           |tr = '""%1"" tablosunun
				           |veri kaynağında dönem sonu kapanış kontrolü için
				           |tarih alanı yanlış:
				           |Belirtilen ""%2"" tablo bölümünün alanı belirtilmemiş.'"),
				Source.Table, Fields[0]);
			Raise ErrorText;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã đặt sai trường đối tượng:
				           |chưa đặt trường của phần bảng đã đặt ""%2"".';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле объекта:
				           |не задано поле заданной табличной части ""%2"".';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |No field specified for tabular section:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |No field specified for tabular section:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo dell''oggetto è indicato in maniera errata:
				           | non è indicato il campo della parte tabulare indicata ""%2"".';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           | jest nieprawidłowo określono pole obiektu:
				           | nie określono pole określonej części tabelarycznej ""%2"".';
				           |tr = '""%1"" tablosunun
				           |veri kaynağında dönem sonu kapanış kontrolü için
				           |nesne alanı yanlış:
				           |Belirtilen ""%2"" tablo bölümünün alanı belirtilmemiş.'"),
				Source.Table, Fields[0]);
			Raise ErrorText;
		EndIf;
	ElsIf Not ValueIsFilled(Fields[1]) Then
		If FieldKind = "DateField" Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã đặt sau trường ngày:
				           |đã đặt sai trường của phần bảng được đặt ""%2"".';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле даты:
				           |неверно задано поле заданной табличной части ""%2"".';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |Tabular section contains invalid field:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Date field:
				           |Tabular section contains invalid field:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo della data è indicato in maniera errata:
				           | il campo della parte tabulare indicata ""%2"" è indicato in maniera errata.';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           |nieprawidłowo określono pole daty: 
				           | nieprawidłowo określono pole określonej części tabelarycznej""%2""';
				           |tr = '""%1"" tablosunun
				           |veri kaynağında dönem sonu kapanış kontrolü için
				           |tarih alanı yanlış:
				           |Belirtilen ""%2"" tablo bölümünün alanı yanlış.'"),
				Source.Table, Fields[0]);
			Raise ErrorText;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để kiểm tra việc cấm thay đổi 
				           |trong nguồn dữ liệu đối với bảng ""%1""
				           |đã đặt sai trường đối tượng:
				           |đã đặt sai trường phần bảng được đặt ""%2"".';
				           |ru = 'Для проверки запрета изменения 
				           |в источнике данных для таблицы ""%1""
				           |неверно задано поле объекта:
				           |неверно задано поле заданной табличной части ""%2"".';
				           |en = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |Tabular section contains invalid field:
				           |%2.'; fa = 'Period-end closing date check error.
				           |Data source contains table %1 with invalid Object field:
				           |Tabular section contains invalid field:
				           |%2.';
				           |it = 'Per la verifica del divieto di modifica 
				           | nella fonte dei dati per la tabella ""%1""
				           | il campo dell''oggetto è indicato in maniera errata:
				           | il campo della parte tabulare indicata ""%2"" è indicato in maniera errata.';
				           |pl = 'Dla weryfikacji zakazu zmiany 
				           |w źródle danych dla tabeli ""%1""
				           | jest nieprawidłowo określono pole obiektu:
				           | nie prawidłowo określono pole określonej części tabelarycznej ""%2"".';
				           |tr = '""%1"" tablosunun
				           |veri kaynağında dönem sonu kapanış kontrolü için
				           |nesne alanı yanlış:
				           |Belirtilen ""%2"" tablo bölümünün alanı yanlış.'"),
				Source.Table, Fields[0]);
			Raise ErrorText;
		EndIf;
	EndIf;
	
	Properties.TabularSection = Fields[0];
	Properties.Name = Fields[1];
	
	PointPosition = StrFind(Field, ".");
	NameAndPath = Mid(Field, PointPosition + 1);
	
	PointPosition = StrFind(NameAndPath, ".");
	If PointPosition > 0 Then
		Properties.Path = Mid(NameAndPath, PointPosition + 1);
	EndIf;
	
	Return New FixedStructure(Properties);
	
EndFunction

Procedure AddQueryText(QueryText, Table, Source)
	
	If Not ValueIsFilled(Source.DateField.TabularSection)
	   And Not ValueIsFilled(Source.ObjectField.TabularSection)
	 Or Source.DateField.TabularSection = Source.ObjectField.TabularSection Then
		
		If Source.DateField.TabularSection = Source.ObjectField.TabularSection Then
			CurrentTable = Table + "." + Source.DateField.TabularSection;
		Else
			CurrentTable = Table;
		EndIf;
		
		Text =
		"SELECT DISTINCT
		|	&DateField AS Date,
		|	&ObjectField AS Object
		|FROM
		|	&Table AS CurrentTable
		|WHERE
		|	CurrentTable.Ref = &Ref";
		Text = StrReplace(Text, "&Table",     CurrentTable);
		Text = StrReplace(Text, "&DateField",    "CurrentTable." + Source.DateField.Name);
		Text = StrReplace(Text, "&ObjectField", "CurrentTable." + Source.ObjectField.Name);
	Else
		If ValueIsFilled(Source.DateField.TabularSection) Then
			DateFieldsTable = Table + "." + Source.DateField.TabularSection;
		Else
			DateFieldsTable = Table;
		EndIf;
		
		If ValueIsFilled(Source.ObjectField.TabularSection) Then
			ObjectFieldsTable = Table + "." + Source.ObjectField.TabularSection;
		Else
			ObjectFieldsTable = Table;
		EndIf;
		
		Text =
		"SELECT DISTINCT
		|	&DateField AS Date,
		|	&ObjectField AS Object
		|FROM
		|	DateTable AS DateFieldsTable
		|		INNER JOIN ObjectTable AS ObjectFieldsTable
		|		ON (DateFieldsTable.Ref = &Ref)
		|			AND (ObjectFieldsTable.Ref = &Ref)";
		Text = StrReplace(Text, "DateTable",    DateFieldsTable);
		Text = StrReplace(Text, "ObjectTable", ObjectFieldsTable);
		Text = StrReplace(Text, "&DateField",    "DateFieldsTable."    + Source.DateField.Name);
		Text = StrReplace(Text, "&ObjectField", "ObjectFieldsTable." + Source.ObjectField.Name);
	EndIf;
	
	AddQueryTextToPackage(QueryText, Text);
	
EndProcedure

Procedure AddQueryTextDatesOnly(QueryText, Table, Source)
	
	If Not ValueIsFilled(Source.DateField.TabularSection) Then
		Text =
		"SELECT
		|	&DateField AS Date
		|FROM
		|	&Table AS CurrentTable
		|WHERE
		|	CurrentTable.Ref = &Ref";
		Text = StrReplace(Text, "&Table", Table);
		Text = StrReplace(Text, "&DateField", "CurrentTable." + Source.DateField.Name);
	Else
		If ValueIsFilled(Source.DateField.Path) Then
			Text =
			"SELECT DISTINCT
			|	&DateField AS Date
			|FROM
			|	&Table AS CurrentTable
			|WHERE
			|	CurrentTable.Ref = &Ref";
		Else
			Text =
			"SELECT TOP 1
			|	CAST(&DateField AS DATE) AS Date
			|FROM
			|	&Table AS CurrentTable
			|WHERE
			|	CurrentTable.Ref = &Ref
			|
			|ORDER BY
			|	Date";
		EndIf;
		Text = StrReplace(Text, "&Table", Table + "." + Source.DateField.TabularSection);
		Text = StrReplace(Text, "&DateField", "CurrentTable." + Source.DateField.Name);
	EndIf;
	
	AddQueryTextToPackage(QueryText, Text);
	
EndProcedure

Procedure AddQueryTextForRegister(QueryText, Table, Source)
	
	Text =
	"SELECT DISTINCT
	|	&DateField AS Date,
	|	&ObjectField AS Object
	|FROM
	|	&Table AS CurrentTable
	|WHERE
	|	&FilterCriterion";
	
	Text = StrReplace(Text, "&Table", Table);
	Text = StrReplace(Text, "&DateField",    "CurrentTable." + Source.DateField.Name);
	Text = StrReplace(Text, "&ObjectField", "CurrentTable." + Source.ObjectField.Name);
	
	AddQueryTextToPackage(QueryText, Text);
	
EndProcedure

Procedure AddQueryTextDatesOnlyForRegister(QueryText, Table, Source)
	
	If ValueIsFilled(Source.DateField.Path) Then
		Text =
		"SELECT DISTINCT
		|	&DateField AS Date
		|FROM
		|	&Table AS CurrentTable
		|WHERE
		|	&FilterCriterion";
	Else
		Text =
		"SELECT TOP 1
		|	CAST(&DateField AS DATE) AS Date
		|FROM
		|	&Table AS CurrentTable
		|WHERE
		|	&FilterCriterion
		|
		|ORDER BY
		|	Date";
	EndIf;
	
	Text = StrReplace(Text, "&Table", Table);
	Text = StrReplace(Text, "&DateField", "CurrentTable." + Source.DateField.Name);
	
	AddQueryTextToPackage(QueryText, Text);
	
EndProcedure

Procedure AddQueryTextToPackage(QueriesPackageText, QueryText)
	
	If Not ValueIsFilled(QueriesPackageText) Then
		QueriesPackageText = QueryText;
		Return;
	EndIf;
	
	QueriesPackageText = QueriesPackageText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + QueryText;
	
EndProcedure

// For procedures OnSendDataToMaster, OnSendDataToMaster.
// OnReceiveDataFromMaster, OnReceiveDataFromSlave.
//
Function RecordSetOnlyWithImportRestrictionDates(DataElement)
	
	If TypeOf(DataElement) <> Type("InformationRegisterRecordSet.PeriodClosingDates") Then
		Return False;
	EndIf;
	
	If Not DataElement.Filter.User.Use Then
		ErrorText =
			NStr("vi = 'Kết xuất hoặc kết nhập các bản ghi của biểu ghi thông tin ""Ngày cấm thay đổi""
			           |chỉ cho phép trong từng chiều đo Người sử dụng.';
			           |ru = 'Выгрузка или загрузка записей регистра сведений ""Даты запрета изменения""
			           |допускается только в разрезе измерения Пользователь.';
			           |en = 'Period-end closing dates information register supports
			           |record import and export only by User dimension.'; fa = 'Period-end closing dates information register supports
			           |record import and export only by User dimension.';
			           |it = 'L''upload o download delle informazioni di registro ""date di divieto di modifica""
			           | è consentito solo nella sezione di misura Utente.';
			           |pl = 'Eksportowanie lub pobieranie wpisów rejestru danych ""Daty zakazu zmiany ""
			           |jest dopuszczalne tylko w przekroju pomiaru Użytkownik.';
			           |tr = '""Değişiklik yasaklanma tarihi"" 
			           |kayıt bilgilerini dışa aktarma veya yükleme yalnızca Kullanıcı boyut bölümünde izin verilir.'");
		Raise ErrorText;
	EndIf;
	
	Return Not IsPeriodClosingAddressee(DataElement.Filter.User.Value);
	
EndFunction

// Intended for the AppendSettingsForGivenAddressees procedure.
Procedure AddSettings(RecordSet, Settings, SettingsAddressees, UserGroups, GroupsSettings)
	
	For Each SettingsAddressee In SettingsAddressees Do
		Addressee = SettingsAddressee.User;
		DestinationType = TypeOf(Addressee);
		AddresseeMetadataObject = Metadata.FindByType(DestinationType);
		IsExchangePlan = TypeOf(AddresseeMetadataObject) = Type("MetadataObject")
			And Metadata.ExchangePlans.Contains(AddresseeMetadataObject);
		If DestinationType = Type("EnumRef.PeriodClosingDatesPurposeTypes")
		 Or Not ValueIsFilled(Addressee)
		   And Not IsExchangePlan
		 Or GroupsSettings
		   And Not (    TypeOf(Addressee) = Type("CatalogRef.Users")
		         Or TypeOf(Addressee) = Type("CatalogRef.ExternalUsers")
		         Or IsExchangePlan
		           And ValueIsFilled(Addressee)) Then
			Continue;
		EndIf;
		
		If Not GroupsSettings Then
			Filter = New Structure("User", ?(IsExchangePlan,
				Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases,
				Enums.PeriodClosingDatesPurposeTypes.ForAllUsers));
			AdditionalSettings = Settings.FindRows(Filter);
			
		ElsIf TypeOf(Addressee) <> Type("CatalogRef.Users")
		        And TypeOf(Addressee) <> Type("CatalogRef.ExternalUsers") Then
			
			Types = CommonClientServer.ValueInArray(DestinationType);
			TypeDescription = New TypeDescription(Types);
			EmptyNode = TypeDescription.AdjustValue(Undefined);
			Filter = New Structure("User", EmptyNode);
			AdditionalSettings = Settings.FindRows(Filter);
		Else
			Filter = New Structure("User", Addressee);
			AdditionalSettings = Settings.Copy(New Array);
			For Each TableRow In UserGroups.FindRows(Filter) Do
				Filter = New Structure("User", TableRow.UsersGroup);
				SettingsOfGroup = Settings.FindRows(Filter);
				For Each GroupSetting In SettingsOfGroup Do
					Filter = New Structure("Section, Object", GroupSetting.Section, GroupSetting.Object);
					ExistingSettings1 = AdditionalSettings.FindRows(Filter);
					If ExistingSettings1.Count() > 0 Then
						ExistingSetting = ExistingSettings1[0];
						If IsRestrictionDateEarlier(GroupSetting, ExistingSetting) Then
							Continue;
						Else
							AdditionalSettings.Delete(ExistingSetting);
						EndIf;
					EndIf;
					FillPropertyValues(AdditionalSettings.Add(), GroupSetting);
				EndDo;
			EndDo;
		EndIf;
		
		For Each AdditionalSetting In AdditionalSettings Do
			Filter = New Structure("User, Section, Object",
				SettingsAddressee.User, AdditionalSetting.Section, AdditionalSetting.Object);
			If Settings.FindRows(Filter).Count() > 0 Then
				Continue;
			EndIf;
			NewRow = RecordSet.Add();
			FillPropertyValues(NewRow, AdditionalSetting);
			FillPropertyValues(NewRow, SettingsAddressee);
			FillPropertyValues(Settings.Add(), NewRow);
		EndDo;
	EndDo;
	
EndProcedure

// Intended for the AddSettings procedure.
Function IsRestrictionDateEarlier(FirstSetting, SecondSetting)
	
	If ValueIsFilled(FirstSetting.PeriodEndClosingDateDetails)
	   And ValueIsFilled(SecondSetting.PeriodEndClosingDateDetails) Then
		
		Return IntervalOfRelativeClosingDate(FirstSetting.PeriodEndClosingDateDetails)
		      > IntervalOfRelativeClosingDate(SecondSetting.PeriodEndClosingDateDetails);
	EndIf;
	
	Return PeriodEndClosingDateByDetails(FirstSetting.PeriodEndClosingDateDetails, FirstSetting.PeriodEndClosingDate)
	      < PeriodEndClosingDateByDetails(SecondSetting.PeriodEndClosingDateDetails, SecondSetting.PeriodEndClosingDate);
	
EndFunction

// Intended for the IsRestrictionDateEarlier function.
Function IntervalOfRelativeClosingDate(PeriodEndClosingDateDetails)
	
	PeriodEndClosingDateOption    = StrGetLine(PeriodEndClosingDateDetails, 1);
	DaysCountAsString = StrGetLine(PeriodEndClosingDateDetails, 2);
	
	If ValueIsFilled(DaysCountAsString) Then
		TypeDetails = New TypeDescription("Number");
		PermissionDaysCount = TypeDetails.AdjustValue(DaysCountAsString);
	Else
		PermissionDaysCount = 0;
	EndIf;
	
	Interval = 10;
	
	If PeriodEndClosingDateOption = "EndOfLastYear" Then
		Interval = 5;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastQuarter" Then
		Interval = 4;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastMonth" Then
		Interval = 3;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastWeek" Then
		Interval = 2;
		
	ElsIf PeriodEndClosingDateOption = "PreviousDay" Then
		Interval = 1;
	EndIf;
	
	Return Interval * 1000 + PermissionDaysCount;
	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("SessionParametersSetting");
	Methods.Insert("UpdatePeriodClosingDatesSections");
	Methods.Insert("AppendSettingsForGivenAddressees");
	Methods.Insert("ReplaceClosingDatesSectionsWithNewOnes");
	Methods.Insert("ClearPredefinedItemsInClosingDatesSections");
	Methods.Insert("SetInitialPeriodEndClosingDate");
	Methods.Insert("SessionParametersSetting");
	
EndProcedure

// Returns a period-end closing date calculated according to the details of a relative period-end closing date.
//
// Parameters:
//  PeriodEndClosingDateDetails - String - contains details of a relative period-end closing date.
//  PeriodEndClosingDate         - Date - an absolute date received from the register.
//  BegOfDay           - Date - a current session date as of the beginning of the day.
//                      - Undefined - calculate automatically.
//
// Returns:
//  Date
//
Function PeriodEndClosingDateByDetails(PeriodEndClosingDateDetails, PeriodEndClosingDate, BegOfDay = '00010101') Export
	
	If Not ValueIsFilled(PeriodEndClosingDateDetails) Then
		Return PeriodEndClosingDate;
	EndIf;
	
	If Not ValueIsFilled(BegOfDay) Then
		BegOfDay = BegOfDay(CurrentSessionDate());
	EndIf;
	
	Days1 = 60*60*24;
	PermissionDaysCount = 0;
	
	PeriodEndClosingDateOption    = StrGetLine(PeriodEndClosingDateDetails, 1);
	DaysCountAsString = StrGetLine(PeriodEndClosingDateDetails, 2);
	
	If ValueIsFilled(DaysCountAsString) Then
		TypeDetails = New TypeDescription("Number");
		PermissionDaysCount = TypeDetails.AdjustValue(DaysCountAsString);
	EndIf;
	
	NextBanDate = Undefined;
	BanDateWithDaysOfLead = Undefined;
	
	If PeriodEndClosingDateOption = "EndOfLastYear" Then
		CurrentPeriodEndClosingDate    = BegOfYear(BegOfDay)          - Days1;
		PreviousPeriodEndClosingDate = BegOfYear(CurrentPeriodEndClosingDate) - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastQuarter" Then
		CurrentPeriodEndClosingDate    = BegOfQuarter(BegOfDay)          - Days1;
		PreviousPeriodEndClosingDate = BegOfQuarter(CurrentPeriodEndClosingDate) - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastMonth" Then
		CurrentPeriodEndClosingDate    = BegOfMonth(BegOfDay)          - Days1;
		PreviousPeriodEndClosingDate = BegOfMonth(CurrentPeriodEndClosingDate) - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastWeek" Then
		CurrentPeriodEndClosingDate    = BegOfWeek(BegOfDay)          - Days1;
		PreviousPeriodEndClosingDate = BegOfWeek(CurrentPeriodEndClosingDate) - Days1;
		
	ElsIf PeriodEndClosingDateOption = "PreviousDay" Then
		CurrentPeriodEndClosingDate    = BegOfDay(BegOfDay)          - Days1;
		PreviousPeriodEndClosingDate = BegOfDay(CurrentPeriodEndClosingDate) - Days1;
		
	ElsIf PeriodEndClosingDateOption = "CurrentDay" Then
		CurrentPeriodEndClosingDate    = EndOfDay(BegOfDay);
		NextBanDate  = EndOfDay(EndOfDay(BegOfDay) + 1);
		BanDateWithDaysOfLead = EndOfDay(BegOfDay + PermissionDaysCount * Days1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentWeek" Then
		CurrentPeriodEndClosingDate    = EndOfWeek(BegOfDay);
		NextBanDate  = BegOfWeek(BegOfWeek(BegOfDay) + 1);
		BanDateWithDaysOfLead = EndOfWeek(BegOfDay + PermissionDaysCount * Days1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentMonth" Then
		CurrentPeriodEndClosingDate    = EndOfMonth(BegOfDay);
		NextBanDate  = EndOfMonth(EndOfMonth(BegOfDay) + 1);
		BanDateWithDaysOfLead = EndOfMonth(BegOfDay + PermissionDaysCount * Days1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentQuarter" Then
		CurrentPeriodEndClosingDate    = EndOfQuarter(BegOfDay);
		NextBanDate  = EndOfQuarter(EndOfQuarter(BegOfDay) + 1);
		BanDateWithDaysOfLead = EndOfQuarter(BegOfDay + PermissionDaysCount * Days1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentYear" Then		
		CurrentPeriodEndClosingDate    = EndOfYear(BegOfDay);
		NextBanDate  = EndOfYear(EndOfYear(BegOfDay) + 1);
		BanDateWithDaysOfLead = EndOfYear(BegOfDay + PermissionDaysCount * Days1);
		
	Else
		Return '39990303'; // Unknown format.
	EndIf;
	
	If ValueIsFilled(CurrentPeriodEndClosingDate) Then
		If NextBanDate = Undefined Then
			PermissionPeriod = CurrentPeriodEndClosingDate + PermissionDaysCount * Days1;
			If Not BegOfDay > PermissionPeriod  Then
				CurrentPeriodEndClosingDate = PreviousPeriodEndClosingDate;
			EndIf;
		Else
			If BanDateWithDaysOfLead > CurrentPeriodEndClosingDate Then 
				CurrentPeriodEndClosingDate = NextBanDate;
			EndIf;
		EndIf;
	EndIf;
	
	Return CurrentPeriodEndClosingDate;
	
EndFunction

#EndRegion