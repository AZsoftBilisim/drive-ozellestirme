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
		   And ValueIsFilled(Context.Parameters.CommandParameter) Then
			
			Values = Context.Parameters.CommandParameter;
			If TypeOf(Values[0]) = Type("CatalogRef.Users") Then
				ParameterName = "User";
			ElsIf TypeOf(Values[0]) = Type("CatalogRef.UserGroups") Then
				ParameterName = "UsersGroup";
			ElsIf TypeOf(Values[0]) = Type("CatalogRef.ExternalUsers") Then
				ParameterName = "ExternalUser";
			ElsIf TypeOf(Values[0]) = Type("CatalogRef.ExternalUsersGroups") Then
				ParameterName = "ExternalUsersGroup";
			EndIf;
			
			ValueList = New ValueList;
			ValueList.LoadValues(Values);
			UsersInternal.SetFilterOnParameter(ParameterName,
				ValueList, NewDCSettings, NewDCUserSettings);
		EndIf;
	EndIf;
	
	If VariantKey = "MembersChangeInExternalUsersGroups" Then
		DataCompositionSchema.Parameters.User.UseRestriction = True;
		DataCompositionSchema.Parameters.UsersGroup.UseRestriction = True;
	Else
		DataCompositionSchema.Parameters.ExternalUser.UseRestriction = True;
		DataCompositionSchema.Parameters.ExternalUsersGroup.UseRestriction = True;
	EndIf;
	
	ModuleReportsServer = Common.CommonModule("ReportsServer");
	ModuleReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	
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

Function IsOptionForExternalUsers()
	
	Properties = New Structure("PredefinedOptionKey");
	FillPropertyValues(Properties, SettingsComposer.Settings.AdditionalProperties);
	
	Return Properties.PredefinedOptionKey = "MembersChangeInExternalUsersGroups";
	
EndFunction

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
	
	If IsOptionForExternalUsers() Then
		ParameterNameUser = "ExternalUser";
		ParameterNameUsersGroup = "ExternalUsersGroup";
		Filter.Insert("Event",
			UsersInternal.NameOfLogEventExternalUserGroupsMembersChanged());
	Else
		ParameterNameUser = "User";
		ParameterNameUsersGroup = "UsersGroup";
		Filter.Insert("Event",
			UsersInternal.NameOfLogEventUserGroupsMembersChanged());
	EndIf;
	
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
	StringType73   = New TypeDescription("String", , New StringQualifiers(73));
	StringType100  = New TypeDescription("String", , New StringQualifiers(100));
	StringType1024 = New TypeDescription("String", , New StringQualifiers(1024));
	
	Changes = New ValueTable;
	Columns = Changes.Columns;
	Columns.Add("ParentID",     StringType73);
	Columns.Add("RowID",       StringType73);
	Columns.Add("LinePresentation",       StringType);
	Columns.Add("IsEvent",                BooleanType);
	Columns.Add("IsFolder",                 BooleanType);
	Columns.Add("ThisIsTheUser",           BooleanType);
	Columns.Add("EventNumber",              NumberType);
	Columns.Add("Date",                      DateType);
	Columns.Add("Author",                     StringType100);
	Columns.Add("AuthorID",       StringType36);
	Columns.Add("Application",                StringType20);
	Columns.Add("Computer",                 StringType);
	Columns.Add("Session",                     NumberType);
	Columns.Add(ConnectionColumnName,        NumberType);
	Columns.Add("GroupID",       StringType36);
	Columns.Add("UserIdentificator", StringType36);
	Columns.Add("IsBelongToLowerLevelGroup",       BooleanType);
	Columns.Add("Used",              BooleanType);
	Columns.Add("ChangeType",              StringType1);
	Columns.Add("GroupPresentation",       StringType1024);
	Columns.Add("UserPresentation2", StringType1024);
	
	LogColumns = "Date,User,UserName,
	|ApplicationName,Computer,Session,Data," + ConnectionColumnName;
	
	SetPrivilegedMode(True);
	Events = New ValueTable;
	UnloadEventLog(Events, Filter, LogColumns);
	
	EventNumber = 0;
	Filterdata_ = New Structure;
	Filterdata_.Insert("Users", ValueIDs(
		ParameterValue(Settings, ParameterNameUser, Undefined)));
	Filterdata_.Insert("UserGroups", ValueIDs(
		ParameterValue(Settings, ParameterNameUsersGroup, Undefined)));
	Filterdata_.Insert("ShouldHideUsersThatBelongToLowerLevelGroups",
		ParameterValue(Settings, "ShouldHideUsersThatBelongToLowerLevelGroups", False));
	
	For Each Event In Events Do
		Data = ExtendedChangeData(Event.Data, Filterdata_);
		If Data = Undefined Then
			Continue;
		EndIf;
		
		EventIdentifier = Lower(New UUID);
		EventNumber = EventNumber + 1;
		LinePresentation = New Array;
		LinePresentation.Add(Event.Date);
		LinePresentation.Add(Event.UserName);
		LinePresentation.Add(Event.ApplicationName);
		LinePresentation.Add(Event.Computer);
		LinePresentation.Add(Event.Session);
		
		NewRow = Changes.Add();
		NewRow.EventNumber          = EventNumber;
		NewRow.IsEvent            = True;
		NewRow.RowID   = EventIdentifier;
		NewRow.LinePresentation   = StrConcat(LinePresentation,  ", ");
		NewRow.Date                  = Event.Date;
		NewRow.Author                 = Event.UserName;
		NewRow.AuthorID   = Event.User;
		NewRow.Application            = Event.ApplicationName;
		NewRow.Computer             = Event.Computer;
		NewRow.Session                 = Event.Session;
		NewRow[ConnectionColumnName] = Event[ConnectionColumnName];
		
		Prefix = EventIdentifier + "_";
		
		For Each String In Data.GroupsPresentation Do
			NewRow = Changes.Add();
			NewRow.EventNumber          = EventNumber;
			NewRow.IsFolder             = True;
			NewRow.RowID   = Prefix + String.GroupID;
			NewRow.ParentID = ?(ValueIsFilled(String.ParentID),
				Prefix + String.ParentID, EventIdentifier);
			NewRow.LinePresentation   = String.GroupPresentation;
			
			NewRow.GroupID = String.GroupID;
			NewRow.GroupPresentation = String.GroupPresentation;
		EndDo;
		
		For Each String In Data.ChangesInComposition Do
			NewRow = Changes.Add();
			NewRow.EventNumber          = EventNumber;
			NewRow.ThisIsTheUser       = True;
			NewRow.RowID   = Prefix + String.UserIdentificator;
			NewRow.ParentID = Prefix + String.GroupID;
			
			NewRow.UserIdentificator = String.UserIdentificator;
			NewRow.IsBelongToLowerLevelGroup       = String.IsBelongToLowerLevelGroup;
			NewRow.Used              = String.Used;
			NewRow.ChangeType = ?(String.ChangeType = "Deleted", "-",
				?(String.ChangeType = "Added2", "+", ?(String.ChangeType = "IsChanged", "*", "?")));
			
			FoundRow = Data.PresentationUsers.Find(
				String.UserIdentificator, "UserIdentificator");
			NewRow.UserPresentation2 = ?(FoundRow <> Undefined,
				FoundRow.UserPresentation2, String.UserIdentificator);
			
			NewRow.LinePresentation = NewRow.ChangeType + " "
				+ NewRow.UserPresentation2;
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
		Result.Insert(Lower(Value.UUID()), True);
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  EventData - String
//
// Returns:
//  Structure
//
Function ExtendedChangeData(EventData, Filterdata_)
	
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
	Location.Insert("ChangesInComposition");
	Location.Insert("GroupsPresentation");
	Location.Insert("PresentationUsers");
	FillPropertyValues(Location, Data);
	If Location.DataStructureVersion <> 1
	   And Location.DataStructureVersion <> 2 Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("GroupID", "");
	Properties.Insert("UserIdentificator", "");
	Properties.Insert("IsBelongToLowerLevelGroup", False);
	Properties.Insert("Used", False);
	Properties.Insert("ChangeType", "");
	
	ChangesInComposition = StoredTable(Location.ChangesInComposition, Properties);
	If Not ValueIsFilled(ChangesInComposition) Then
		Return Undefined;
	EndIf;
	If Location.DataStructureVersion = 1 Then
		For Each String In ChangesInComposition Do
			If String.ChangeType = "Removed" Then
				String.ChangeType = "Deleted";
			ElsIf String.ChangeType = "Added" Then
				String.ChangeType = "Added2";
			ElsIf String.ChangeType = "UsageChanged" Then
				String.ChangeType = "IsChanged";
			EndIf;
		EndDo;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("ParentID", "");
	Properties.Insert("GroupID", "");
	Properties.Insert("GroupPresentation", "");
	
	GroupsPresentation = StoredTable(Location.GroupsPresentation, Properties);
	If GroupsPresentation = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("UserIdentificator", "");
	Properties.Insert("UserPresentation2", "");
	
	PresentationUsers = StoredTable(Location.PresentationUsers, Properties);
	If PresentationUsers = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ChangesInComposition", ChangesInComposition);
	Result.Insert("GroupsPresentation", GroupsPresentation);
	Result.Insert("PresentationUsers", PresentationUsers);
	
	If Filterdata_.Users = Undefined
	   And Filterdata_.UserGroups = Undefined
	   And Filterdata_.ShouldHideUsersThatBelongToLowerLevelGroups <> True Then
		
		Return Result;
	EndIf;
	
	UsedGroups = New Map;
	ParentsOfGroups = New Map;
	IndexOf = ChangesInComposition.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = ChangesInComposition.Get(IndexOf);
		If Filterdata_.Users <> Undefined
		   And Filterdata_.Users.Get(String.UserIdentificator) = Undefined
		 Or Filterdata_.ShouldHideUsersThatBelongToLowerLevelGroups = True
		   And String.IsBelongToLowerLevelGroup Then
			ChangesInComposition.Delete(IndexOf);
			Continue;
		EndIf;
		ParentsOfGroup = ParentsOfGroups.Get(String.GroupID);
		If ParentsOfGroup = Undefined Then
			ParentsOfGroup = New Map;
			CurrentGroup = String.GroupID;
			While True Do
				FoundRow = GroupsPresentation.Find(CurrentGroup, "GroupID");
				If FoundRow = Undefined Then
					Break;
				EndIf;
				If ParentsOfGroup.Get(FoundRow.GroupID) <> Undefined Then
					Break;
				EndIf;
				ParentsOfGroup.Insert(CurrentGroup, True);
				If Not ValueIsFilled(FoundRow.ParentID) Then
					Break;
				EndIf;
				CurrentGroup = FoundRow.ParentID;
			EndDo;
		EndIf;
		If Filterdata_.UserGroups <> Undefined Then
			IsGroupFound = False;
			For Each KeyAndValue In ParentsOfGroup Do
				If Filterdata_.UserGroups.Get(KeyAndValue.Key) <> Undefined Then
					IsGroupFound = True;
				EndIf;
			EndDo;
			If Not IsGroupFound Then
				ChangesInComposition.Delete(IndexOf);
				Continue;
			EndIf;
		EndIf;
		For Each KeyAndValue In ParentsOfGroup Do
			UsedGroups.Insert(KeyAndValue.Key, True);
		EndDo;
	EndDo;
	
	If Not ValueIsFilled(ChangesInComposition) Then
		Return Undefined;
	EndIf;
	
	IndexOf = GroupsPresentation.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = GroupsPresentation.Get(IndexOf);
		If UsedGroups.Get(String.GroupID) = Undefined Then
			GroupsPresentation.Delete(IndexOf);
		EndIf;
	EndDo;
	
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

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf