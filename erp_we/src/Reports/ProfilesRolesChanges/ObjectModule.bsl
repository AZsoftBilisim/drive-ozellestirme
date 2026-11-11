///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Configure report form.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before importing new settings. Used for modifying DCS reports.
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey <> "1" Then
		SchemaKey = "1";
		
		If TypeOf(Context) = Type("ClientApplicationForm")
		   And NewDCSettings <> Undefined
		   And Context.Parameters.Property("CommandParameter")
		   And ValueIsFilled(Context.Parameters.CommandParameter)
		   And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			
			ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
			ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
			
			Values = Context.Parameters.CommandParameter;
			If TypeOf(Values[0]) = Type("CatalogRef.Users")
			 Or TypeOf(Values[0]) = Type("CatalogRef.UserGroups")
			 Or TypeOf(Values[0]) = Type("CatalogRef.ExternalUsers")
			 Or TypeOf(Values[0]) = Type("CatalogRef.ExternalUsersGroups") Then
				ParameterName = "Member";
			ElsIf TypeOf(Values[0]) = ParametersForReports.TypeCatalogRefAccessGroups Then
				ParameterName = "AccessGroup";
			ElsIf TypeOf(Values[0]) = ParametersForReports.TypeCatalogRefAccessGroupsProfiles Then
				ParameterName = "Profile";
			EndIf;
			
			ValueList = New ValueList;
			ValueList.LoadValues(Values);
			UsersInternal.SetFilterOnParameter(ParameterName,
				ValueList, NewDCSettings, NewDCUserSettings);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ResultDocument.Clear();
	
	If Common.DataSeparationEnabled() Then
		VerifyAccessRights("DataAdministration", Metadata);
	Else
		VerifyAccessRights("Administration", Metadata);
	EndIf;
	SetPrivilegedMode(True);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Settings = SettingsComposer.GetSettings();
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("Changes", ChangesInComposition(Settings));
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.BeginOutput();
	ResultItem = CompositionProcessor.Next();
	While ResultItem <> Undefined Do
		OutputProcessor.OutputItem(ResultItem);
		ResultItem = CompositionProcessor.Next();
	EndDo;
	OutputProcessor.EndOutput();
	
EndProcedure

#EndRegion

#Region Private

Function ChangesInComposition(Settings)
	
	ConnectionColumnName = UserMonitoringInternal.ConnectionColumnName();
	
	Filter = New Structure;
	
	TransStatuses = New Array;
	TransStatuses.Add(EventLogEntryTransactionStatus.Committed);
	TransStatuses.Add(EventLogEntryTransactionStatus.NotApplicable);
	Filter.Insert("TransactionStatus", TransStatuses);
	
	Period = ParameterValue(Settings, "Period", New StandardPeriod);
	If ValueIsFilled(Period.StartDate) Then
		Filter.Insert("StartDate", Period.StartDate);
	EndIf;
	If ValueIsFilled(Period.EndDate) Then
		Filter.Insert("EndDate", Period.EndDate);
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	Filter.Insert("Event",
		ModuleAccessManagementInternal.NameOfLogEventProfilesRolesChanged());
	
	Author = ParameterValue(Settings, "Author", Null);
	If Author <> Null Then
		Filter.Insert("User", String(Author));
	EndIf;
	
	BooleanType     = New TypeDescription("Boolean");
	DateType       = New TypeDescription("Date");
	NumberType      = New TypeDescription("Number");
	StringType     = New TypeDescription("String");
	StringType1    = New TypeDescription("String", , New StringQualifiers(1));
	StringType20   = New TypeDescription("String", , New StringQualifiers(20));
	StringType36   = New TypeDescription("String", , New StringQualifiers(36));
	StringType100  = New TypeDescription("String", , New StringQualifiers(100));
	StringType1000 = New TypeDescription("String", , New StringQualifiers(1000));
	
	TypeProfile = New TypeDescription(StringType100, "CatalogRef.AccessGroupProfiles");
	TypeRole    = New TypeDescription(StringType100, "CatalogRef.MetadataObjectIDs,
		|CatalogRef.ExtensionObjectIDs");
	
	Changes = New ValueTable;
	Columns = Changes.Columns;
	Columns.Add("Profile",                      TypeProfile);
	Columns.Add("ProfilePresentation",         StringType1000);
	Columns.Add("ProfileDeletionMark",       BooleanType);
	Columns.Add("EventNumber",                 NumberType);
	Columns.Add("Date",                         DateType);
	Columns.Add("Author",                        StringType100);
	Columns.Add("AuthorID",          StringType36);
	Columns.Add("Application",                   StringType20);
	Columns.Add("Computer",                    StringType);
	Columns.Add("Session",                        NumberType);
	Columns.Add(ConnectionColumnName,           NumberType);
	Columns.Add("Role",                         TypeRole);
	Columns.Add("NameOfRole",                      StringType1000);
	Columns.Add("RolePresentation",            StringType1000);
	Columns.Add("RoleDeletionMark",          BooleanType);
	Columns.Add("IsRolePresentInMetadata",          BooleanType);
	Columns.Add("ChangeType",                 StringType1);
	Columns.Add("PreviousProfileDeletionMark",   BooleanType);
	Columns.Add("PreviousRoleName",                  StringType1000);
	Columns.Add("PreviousRolePresentation",        StringType1000);
	Columns.Add("PreviousRoleDeletionMark",      BooleanType);
	
	LogColumns = "Event,Date,User,UserName,
	|ApplicationName,Computer,Session,Data," + ConnectionColumnName;
	
	SetPrivilegedMode(True);
	Events = New ValueTable;
	UnloadEventLog(Events, Filter, LogColumns);
	
	EventNumber = 0;
	Filterdata_ = New Structure;
	Filterdata_.Insert("Profiles", ValueIDs(
		ParameterValue(Settings, "Profile", Undefined)));
	Filterdata_.Insert("Roles", ValueIDs(
		ParameterValue(Settings, "Role", Undefined)));
	
	For Each Event In Events Do
		Data = ProfilesRolesChangesExtendedData(Event.Data, Filterdata_);
		If Data = Undefined Then
			Continue;
		EndIf;
		
		EventNumber = EventNumber + 1;
		
		EventProperties = New Structure;
		EventProperties.Insert("EventNumber",        EventNumber);
		EventProperties.Insert("Date",                Event.Date);
		EventProperties.Insert("Author",               Event.UserName);
		EventProperties.Insert("AuthorID", Event.User);
		EventProperties.Insert("Application",          Event.ApplicationName);
		EventProperties.Insert("Computer",           Event.Computer);
		EventProperties.Insert("Session",               Event.Session);
		EventProperties.Insert(ConnectionColumnName,  Event.Join);
		
		For Each ChangeDescription In Data.ChangeOfRoles Do
			ProfileProperties = Data.ProfilesPresentation.Find(ChangeDescription.Profile, "Profile");
			If ProfileProperties = Undefined Then
				Continue;
			EndIf;
			RoleProperties = Data.RolesPresentation.Find(ChangeDescription.Role, "Role");
			If RoleProperties = Undefined Then
				Continue;
			EndIf;
			
			NewRow = Changes.Add();
			FillPropertyValues(NewRow, EventProperties);
			NewRow.Profile                = DeserializedRef(ChangeDescription.Profile);
			NewRow.ProfilePresentation   = ProfileProperties.Presentation;
			NewRow.ProfileDeletionMark = ProfileProperties.DeletionMark;
			NewRow.Role                   = DeserializedRef(ChangeDescription.Role);
			NewRow.NameOfRole                = RoleProperties.Name;
			NewRow.RolePresentation      = ?(ValueIsFilled(RoleProperties.Synonym),
				RoleProperties.Synonym, RoleProperties.Name);
			NewRow.RoleDeletionMark    = RoleProperties.DeletionMark;
			NewRow.IsRolePresentInMetadata    = RoleProperties.IsPresentInMetadata;
			NewRow.ChangeType           = ?(ChangeDescription.ChangeType = "Deleted", "-",
				?(ChangeDescription.ChangeType = "Added2", "+",
				?(ChangeDescription.ChangeType = "IsChanged", "*", "")));
			
			PreviousValues1 = ProfileProperties.OldPropertyValues;
			NewRow.PreviousProfileDeletionMark = ?(PreviousValues1.Property("DeletionMark"),
				PreviousValues1.DeletionMark, NewRow.ProfileDeletionMark);
			
			PreviousValues1 = RoleProperties.OldPropertyValues;
			NewRow.PreviousRoleName = ?(PreviousValues1.Property("Name"),
				PreviousValues1.Name, NewRow.NameOfRole);
			NewRow.PreviousRolePresentation = ?(PreviousValues1.Property("Synonym"),
				?(ValueIsFilled(PreviousValues1.Synonym), PreviousValues1.Synonym, NewRow.PreviousRoleName),
				NewRow.RolePresentation);
			NewRow.PreviousRoleDeletionMark = ?(PreviousValues1.Property("DeletionMark"),
				PreviousValues1.DeletionMark, NewRow.RoleDeletionMark);
		EndDo;
	EndDo;
	
	Return Changes;
	
EndFunction

Function ParameterValue(Settings, ParameterName, DefaultValue)
	
	Field = Settings.DataParameters.Items.Find(ParameterName);
	
	If Field <> Undefined And Field.Use Then
		Return Field.Value;
	EndIf;
	
	Return DefaultValue;
	
EndFunction

Function ValueIDs(SelectedValues)
	
	If SelectedValues = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(SelectedValues) = Type("ValueList") Then
		Values = SelectedValues.UnloadValues();
	Else
		Values = CommonClientServer.ValueInArray(SelectedValues);
	EndIf;
	
	Result = New Map;
	
	For Each Value In Values Do
		If Not ValueIsFilled(Value) Then
			Continue;
		EndIf;
		Result.Insert(UsersInternal.SerializedRef(Value), True);
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  EventData - String
//
// Returns:
//  Structure
//
Function ProfilesRolesChangesExtendedData(EventData, Filterdata_)
	
	If Not ValueIsFilled(EventData) Then
		Return Undefined;
	EndIf;
	
	Try
		Data = Common.ValueFromXMLString(EventData);
	Except
		Return Undefined;
	EndTry;
	
	If TypeOf(Data) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	Location = New Structure;
	Location.Insert("DataStructureVersion");
	Location.Insert("ChangeOfRoles");
	Location.Insert("RolesPresentation");
	Location.Insert("ProfilesPresentation");
	FillPropertyValues(Location, Data);
	If Location.DataStructureVersion <> 1 Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("Profile", "");
	Properties.Insert("Role", "");
	Properties.Insert("ChangeType", "");
	
	ChangeOfRoles = StoredTable(Location.ChangeOfRoles, Properties);
	If Not ValueIsFilled(ChangeOfRoles) Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("Role", "");
	Properties.Insert("DeletionMark", False);
	Properties.Insert("IsPresentInMetadata", False);
	Properties.Insert("Name", "");
	Properties.Insert("Synonym", "");
	Properties.Insert("OldPropertyValues", New Structure);
	
	RolesPresentation = StoredTable(Location.RolesPresentation, Properties);
	If Not ValueIsFilled(RolesPresentation) Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("Profile", "");
	Properties.Insert("DeletionMark", False);
	Properties.Insert("Presentation", "");
	Properties.Insert("OldPropertyValues", New Structure);
	
	ProfilesPresentation = StoredTable(Location.ProfilesPresentation, Properties);
	If Not ValueIsFilled(ProfilesPresentation) Then
		Return Undefined;
	EndIf;
	
	RolesPresentation.Indexes.Add("Role");
	ProfilesPresentation.Indexes.Add("Profile");
	
	Result = New Structure;
	Result.Insert("ChangeOfRoles", ChangeOfRoles);
	Result.Insert("RolesPresentation", RolesPresentation);
	Result.Insert("ProfilesPresentation", ProfilesPresentation);
	
	If Filterdata_.Profiles = Undefined
	   And Filterdata_.Roles = Undefined Then
		
		Return Result;
	EndIf;
	
	IndexOf = ChangeOfRoles.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = ChangeOfRoles.Get(IndexOf);
		If Filterdata_.Profiles <> Undefined
		   And Filterdata_.Profiles.Get(String.Profile) = Undefined
		 Or Filterdata_.Roles <> Undefined
		   And Filterdata_.Roles.Get(String.Role) = Undefined Then
			ChangeOfRoles.Delete(IndexOf);
			Continue;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(ChangeOfRoles) Then
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Function StoredTable(Rows, Properties)
	
	If TypeOf(Rows) <> Type("Array") Then
		Return Undefined;
	EndIf;
	
	Result = New ValueTable;
	For Each KeyAndValue In Properties Do
		Types = CommonClientServer.ValueInArray(TypeOf(KeyAndValue.Value));
		Result.Columns.Add(KeyAndValue.Key, New TypeDescription(Types));
	EndDo;
	
	For Each String In Rows Do
		If TypeOf(String) <> Type("Structure") Then
			Return Undefined;
		EndIf;
		NewRow = Result.Add();
		For Each KeyAndValue In Properties Do
			If Not String.Property(KeyAndValue.Key)
			 Or TypeOf(String[KeyAndValue.Key]) <> TypeOf(KeyAndValue.Value) Then
				Return Undefined;
			EndIf;
			NewRow[KeyAndValue.Key] = String[KeyAndValue.Key];
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function DeserializedRef(SerializedRef)
	
	If SerializedRef = Undefined Then
		Return Undefined;
	EndIf;
	
	Try
		Result = ValueFromStringInternal(SerializedRef);
	Except
		Result = Undefined;
	EndTry;
	
	If Result = Undefined Then
		Return SerializedRef;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Недопустимый вызов объекта на клиенте.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf