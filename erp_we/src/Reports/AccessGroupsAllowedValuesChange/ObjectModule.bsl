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
			If TypeOf(Values[0]) = ParametersForReports.TypeCatalogRefAccessGroups Then
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
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	// Set access value types.
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	AccessKindsProperties = ModuleAccessManagementInternal.AllAccessKindsProperties();
	
	Types = New Array;
	Types.Add(Type("CatalogRef.Users"));
	Types.Add(Type("CatalogRef.UserGroups"));
	Types.Add(Type("CatalogRef.ExternalUsers"));
	Types.Add(Type("CatalogRef.ExternalUsersGroups"));
	
	For Each KeyAndValue In AccessKindsProperties.ByGroupsAndValuesTypes Do
		AccessKindProperties = KeyAndValue.Value; // See AccessManagementInternal.AccessKindProperties
		If AccessKindProperties.Name = "Users"
		 Or AccessKindProperties.Name = "ExternalUsers" Then
			Continue;
		EndIf;
		Types.Add(KeyAndValue.Key);
	EndDo;
	
	DataCompositionSchema.Parameters.AccessValue.ValueType = New TypeDescription(Types);
	
	// Set access kinds.
	ModuleAccessManagementInternalCached = Common.CommonModule("AccessManagementInternalCached");
	AccessKindsPresentation = ModuleAccessManagementInternalCached.AccessKindsPresentation();
	
	AccessKinds = New ValueList;
	For Each KeyAndValue In AccessKindsPresentation Do
		AccessKindProperties = AccessKindsProperties.ByValuesTypes.Get(KeyAndValue.Key); // See AccessManagementInternal.AccessKindProperties
		AccessKinds.Add(AccessKindProperties.Name, KeyAndValue.Value);
	EndDo;
	
	DataCompositionSchema.Parameters.AccessKind.SetAvailableValues(AccessKinds);
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		ModuleReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
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
	ExternalDataSets.Insert("Changes", ValuesChanges(Settings));
	
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

Function ValuesChanges(Settings)
	
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
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	Filter.Insert("Event",
		ModuleAccessManagementInternal.NameOfLogEventAllowedValuesChanged());
	
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
	
	TypeProfile         = New TypeDescription(StringType100, CommonClientServer.ValueInArray(
		ParametersForReports.TypeCatalogRefAccessGroupsProfiles));
	TypeAccessGroup   = New TypeDescription(StringType100, CommonClientServer.ValueInArray(
		ParametersForReports.TypeCatalogRefAccessGroups));
	TypeAccessValue = New TypeDescription(StringType100,  ParametersForReports.AccessValuesTypes);
	TypeSourceObject        = New TypeDescription(StringType1000, ParametersForReports.AccessValuesTypes);
	TypeSourceObject        = New TypeDescription(TypeSourceObject, CommonClientServer.ValueInArray(
		ParametersForReports.TypeCatalogRefAccessGroupsProfiles));
	TypeSourceObject        = New TypeDescription(TypeSourceObject, CommonClientServer.ValueInArray(
		ParametersForReports.TypeCatalogRefAccessGroups));
	
	Changes = New ValueTable;
	Columns = Changes.Columns;
	Columns.Add("Profile",                          TypeProfile);
	Columns.Add("ProfilePresentation",             StringType1000);
	Columns.Add("ProfileDeletionMark",           BooleanType);
	Columns.Add("AccessGroup",                    TypeAccessGroup);
	Columns.Add("PresentationAccessGroups",       StringType1000);
	Columns.Add("AccessGroupDeletionMark",     BooleanType);
	Columns.Add("EventNumber",                     NumberType);
	Columns.Add("Date",                             DateType);
	Columns.Add("Author",                            StringType100);
	Columns.Add("AuthorID",              StringType36);
	Columns.Add("Application",                       StringType20);
	Columns.Add("Computer",                        StringType);
	Columns.Add("Session",                            NumberType);
	Columns.Add(ConnectionColumnName,               NumberType);
	Columns.Add("Source",                         TypeSourceObject);
	Columns.Add("SourcePresentation",           StringType1000);
	Columns.Add("AccessKind",                       TypeAccessValue);
	Columns.Add("AccessKindName",                   StringType1000);
	Columns.Add("AccessKindPresentation",         StringType1000);
	Columns.Add("AccessKindUsed",           BooleanType);
	Columns.Add("Predefined",                BooleanType);
	Columns.Add("AllAllowed",                     BooleanType);
	Columns.Add("AccessKindChangeKind",          StringType1);
	Columns.Add("ValueOrGroup",                TypeAccessValue);
	Columns.Add("ValueOrGroupPresentation",   StringType1000);
	Columns.Add("IsValuesGroup",                BooleanType);
	Columns.Add("IncludeSubordinateAccessValues",               BooleanType);
	Columns.Add("AccessValue",                  TypeAccessValue);
	Columns.Add("AccessValuePresentation",     StringType1000);
	Columns.Add("AccessValueChangeKind",      StringType1);
	Columns.Add("PreviousProfile",                      TypeProfile);
	Columns.Add("PreviousProfilePresentation",         StringType1000);
	Columns.Add("PreviousProfileDeletionMark",       BooleanType);
	Columns.Add("PreviousAccessGroupDeletionMark", BooleanType);
	Columns.Add("PreviousPredefined",            BooleanType);
	Columns.Add("PreviousAllAllowed",                 BooleanType);
	Columns.Add("PreviousIncludeSubordinateAccessValues",           BooleanType);
	
	LogColumns = "Event,Date,User,UserName,
	|ApplicationName,Computer,Session,Data," + ConnectionColumnName;
	
	SetPrivilegedMode(True);
	Events = New ValueTable;
	UnloadEventLog(Events, Filter, LogColumns);
	
	EventNumber = 0;
	Filterdata_ = New Structure;
	Filterdata_.Insert("Profiles", ValueIDs(
		ParameterValue(Settings, "Profile", Undefined)));
	Filterdata_.Insert("AccessGroups", ValueIDs(
		ParameterValue(Settings, "AccessGroup", Undefined)));
	Filterdata_.Insert("AccessKinds", ValueIDs(RefsFromAccessKindsNames(
		ParameterValue(Settings, "AccessKind", Undefined)), True));
	Filterdata_.Insert("AccessValues", ValueIDs(
		ParameterValue(Settings, "AccessValue", Undefined), True));
	
	For Each Event In Events Do
		Data = ValuesChangesExtendedData(Event.Data, Filterdata_);
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
		
		If TypeOf(Data.Source) = Type("ValueTable") Then
			EventProperties.Insert("Source", Data.URLToSource);
			IsAccessKindsUsageChange = ValueIsFilled(Data.Source);
			EventProperties.Insert("SourcePresentation", ?(IsAccessKindsUsageChange,
				NStr("vi = '<Thay đổi sử dụng dạng truy cập>';
					|ru = '<Изменение использования видов доступа>';
					|en = '<Toggle access kind usage>'; fa = '<Toggle access kind usage>';
					|it = '<Изменение использования видов доступа>';
					|pl = '<Toggle access kind usage>';
					|tr = '<Erişim türlerinin kullanımını değiştirme>'"),
				NStr("vi = '<Thay đổi thành phần nhóm người sử dụng>';
					|ru = '<Изменение составов групп пользователей>';
					|en = '<Change user group membership>'; fa = '<Change user group membership>';
					|it = '<Изменение составов групп пользователей>';
					|pl = '<Change user group membership>';
					|tr = '<Erişim grubu üyelerini düzenle>'")));
		Else
			IsAccessKindsUsageChange = False;
			EventProperties.Insert("Source", DeserializedRef(Data.Source));
			EventProperties.Insert("SourcePresentation", Data.SourcePresentation);
		EndIf;
		
		Caches = New Map;
		Data.AccessKindsChange.Columns.Add("Processed", New TypeDescription("Boolean"));
		
		AddValuesChange(Changes, EventProperties, Data, Caches);
		
		AccessValuesChange = Data.AccessValuesChange.Copy(New Array);
		For Each ChangeDescription In Data.AccessKindsChange Do
			If ChangeDescription.Processed Then
				Continue;
			EndIf;
			PreviousValues1 = ChangeDescription.OldPropertyValues;
			If ChangeDescription.ChangeType = "IsChanged"
			   And Not ValueIsFilled(PreviousValues1)
			   And Not IsAccessKindsUsageChange Then
				Continue;
			EndIf;
			NewRow = AccessValuesChange.Add();
			NewRow.AccessGroupOrProfile = ChangeDescription.AccessGroupOrProfile;
			NewRow.AccessKind = ChangeDescription.AccessKind;
			NewRow.AccessValue = "*";
			NewRow.ChangeType = "IsChanged";
		EndDo;
	
		If ValueIsFilled(AccessValuesChange) Then
			Data.AccessValuesChange = AccessValuesChange;
			AddValuesChange(Changes, EventProperties, Data, Caches);
		EndIf;
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

Function RefsFromAccessKindsNames(SelectedValues)
	
	If SelectedValues = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(SelectedValues) = Type("ValueList") Then
		Values = SelectedValues.UnloadValues();
	Else
		Values = CommonClientServer.ValueInArray(SelectedValues);
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	ByNames = ModuleAccessManagementInternal.AllAccessKindsProperties().ByNames;
	
	Result = New ValueList;
	For Each Value In Values Do
		AccessKindProperties = ByNames.Get(Value); // See AccessManagementInternal.AccessKindProperties
		If AccessKindProperties = Undefined Then
			Continue;
		EndIf;
		Result.Add(AccessKindProperties.Ref);
	EndDo;
	
	Return Result;
	
EndFunction

Function ValueIDs(SelectedValues, IsEmptyRefsConsidered = False)
	
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
		If Not ValueIsFilled(Value) And Not IsEmptyRefsConsidered Then
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
Function ValuesChangesExtendedData(EventData, Filterdata_)
	
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
	Location.Insert("Source");
	Location.Insert("URLToSource");
	Location.Insert("SourcePresentation");
	Location.Insert("AccessKindsChange");
	Location.Insert("AccessKindsPresentation");
	Location.Insert("AccessValuesChange");
	Location.Insert("ChangeInAccessValuesGroups");
	Location.Insert("AccessGroupsPresentation");
	Location.Insert("AccessValuesPresentation");
	FillPropertyValues(Location, Data);
	If Location.DataStructureVersion <> 1 Then
		Return Undefined;
	EndIf;
	
	If TypeOf(Location.Source) = Type("Array") Then
		If Not ValueIsFilled(Location.Source) Then
			Source = New ValueTable;
		Else
			Properties = New Structure;
			Properties.Insert("AccessKind", "");
			Properties.Insert("Used", False);
			Properties.Insert("ChangeType", "");
			Source = StoredTable(Location.Source, Properties);
			If Not ValueIsFilled(Source) Then
				Return Undefined;
			EndIf;
		EndIf;
	Else
		Source = Location.Source;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroupOrProfile", "");
	Properties.Insert("AccessKind", "");
	Properties.Insert("AllAllowed", False);
	Properties.Insert("Predefined", False);
	Properties.Insert("OldPropertyValues", New Structure);
	Properties.Insert("ChangeType", "");
	
	AccessKindsChange = StoredTable(Location.AccessKindsChange, Properties);
	If Not ValueIsFilled(AccessKindsChange) Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessKind", "");
	Properties.Insert("Used", False);
	Properties.Insert("Name", "");
	Properties.Insert("Presentation", "");
	
	AccessKindsPresentation = StoredTable(Location.AccessKindsPresentation, Properties);
	If Not ValueIsFilled(AccessKindsPresentation) Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroupOrProfile", "");
	Properties.Insert("AccessKind", "");
	Properties.Insert("AccessValue", "");
	Properties.Insert("IsValuesGroup", False);
	Properties.Insert("IncludeSubordinateAccessValues", False);
	Properties.Insert("OldPropertyValues", New Structure);
	Properties.Insert("ChangeType", "");
	
	AccessValuesChange = StoredTable(Location.AccessValuesChange, Properties);
	If AccessValuesChange = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("ValuesGroup", "");
	Properties.Insert("AccessValue", "");
	Properties.Insert("ChangeType", "");
	
	ChangeInAccessValuesGroups = StoredTable(Location.ChangeInAccessValuesGroups, Properties);
	If ChangeInAccessValuesGroups = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroup", "");
	Properties.Insert("Presentation", "");
	Properties.Insert("DeletionMark", False);
	Properties.Insert("Profile", "");
	Properties.Insert("ProfilePresentation", "");
	Properties.Insert("ProfileDeletionMark", False);
	Properties.Insert("OldPropertyValues", New Structure);
	
	AccessGroupsPresentation = StoredTable(Location.AccessGroupsPresentation, Properties);
	If Not ValueIsFilled(AccessGroupsPresentation) Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("Value", "");
	Properties.Insert("Presentation", "");
	Properties.Insert("URL", "");
	
	AccessValuesPresentation = StoredTable(Location.AccessValuesPresentation, Properties);
	If AccessValuesPresentation = Undefined Then
		Return Undefined;
	EndIf;
	
	AccessKindsChange.Indexes.Add("AccessGroupOrProfile, AccessKind");
	ChangeInAccessValuesGroups.Indexes.Add("ValuesGroup");
	AccessGroupsPresentation.Indexes.Add("AccessGroup");
	AccessGroupsPresentation.Indexes.Add("Profile");
	AccessValuesPresentation.Indexes.Add("Value");
	
	Filter = New Structure("ChangeType", "");
	FoundRows = AccessValuesChange.FindRows(Filter);
	UnmodifiedValues = AccessValuesChange.Copy(FoundRows);
	UnmodifiedValues.Columns.Add("ValueOfGroup");
	Filter = New Structure("ValuesGroup");
	For Each FoundRow In FoundRows Do
		Filter.ValuesGroup = FoundRow.AccessValue;
		ValuesOfGroup = ChangeInAccessValuesGroups.FindRows(Filter);
		For Each ValueOfGroup In ValuesOfGroup Do
			NewRow = UnmodifiedValues.Add();
			FillPropertyValues(NewRow, FoundRow);
			NewRow.ValueOfGroup = ValueOfGroup.AccessValue;
		EndDo;
		AccessValuesChange.Delete(FoundRow);
	EndDo;
	UnmodifiedValues.Indexes.Add("AccessGroupOrProfile,AccessKind,AccessValue");
	UnmodifiedValues.Indexes.Add("AccessGroupOrProfile,AccessKind,ValueOfGroup");
	
	Result = New Structure;
	Result.Insert("Source",                      Source);
	Result.Insert("URLToSource",  Location.URLToSource);
	Result.Insert("SourcePresentation",        Location.SourcePresentation);
	Result.Insert("AccessKindsChange",         AccessKindsChange);
	Result.Insert("AccessKindsPresentation",     AccessKindsPresentation);
	Result.Insert("AccessValuesChange",      AccessValuesChange);
	Result.Insert("ChangeInAccessValuesGroups", ChangeInAccessValuesGroups);
	Result.Insert("AccessGroupsPresentation",     AccessGroupsPresentation);
	Result.Insert("AccessValuesPresentation",  AccessValuesPresentation);
	Result.Insert("UnmodifiedValues",          UnmodifiedValues);
	
	If Filterdata_.Profiles = Undefined
	   And Filterdata_.AccessGroups = Undefined
	   And Filterdata_.AccessKinds = Undefined
	   And Filterdata_.AccessValues = Undefined Then
		
		Return Result;
	EndIf;
	
	IndexOf = AccessGroupsPresentation.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = AccessGroupsPresentation.Get(IndexOf);
		If Filterdata_.Profiles <> Undefined
		   And Filterdata_.Profiles.Get(String.Profile) = Undefined
		 Or Filterdata_.AccessGroups <> Undefined
		   And Filterdata_.AccessGroups.Get(String.AccessGroup) = Undefined Then
			AccessGroupsPresentation.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccessGroupsPresentation) Then
		Return Undefined;
	EndIf;
	
	IndexOf = AccessKindsChange.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = AccessKindsChange.Get(IndexOf);
		If Filterdata_.AccessKinds <> Undefined
		   And Filterdata_.AccessKinds.Get(String.AccessKind) = Undefined Then
			AccessKindsChange.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccessKindsChange) Then
		Return Undefined;
	EndIf;
	
	If Filterdata_.AccessValues = Undefined Then
		Return Result;
	EndIf;
	
	IndexOf = ChangeInAccessValuesGroups.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = ChangeInAccessValuesGroups.Get(IndexOf);
		If Filterdata_.AccessValues.Get(String.ValuesGroup) <> Undefined
		 Or Filterdata_.AccessValues.Get(String.AccessValue) <> Undefined Then
			Continue;
		EndIf;
		ChangeInAccessValuesGroups.Delete(IndexOf);
	EndDo;
	
	IndexOf = AccessValuesChange.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = AccessValuesChange.Get(IndexOf);
		If String.ChangeType = ""
		 Or Filterdata_.AccessValues.Get(String.AccessValue) <> Undefined Then
			Continue;
		EndIf;
		Filter = New Structure("ValuesGroup", String.AccessValue);
		FoundRows = ChangeInAccessValuesGroups.FindRows(Filter);
		If ValueIsFilled(FoundRows) Then
			Continue;
		EndIf;
		AccessValuesChange.Delete(IndexOf);
	EndDo;
	
	If Not ValueIsFilled(AccessValuesChange) Then
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

Procedure AddValuesChange(Changes, EventProperties, Data, Caches)
	
	For Each ChangeDescription In Data.AccessValuesChange Do
		FoundRow = Data.AccessGroupsPresentation.Find(
			ChangeDescription.AccessGroupOrProfile, "AccessGroup");
		If FoundRow = Undefined Then
			IsAccessGroup = False;
			Filter = New Structure("Profile", ChangeDescription.AccessGroupOrProfile);
			AccessGroupsProperties = Data.AccessGroupsPresentation.FindRows(Filter);
		Else
			AccessGroupsProperties = CommonClientServer.ValueInArray(FoundRow);
			IsAccessGroup = True;
		EndIf;
		If Not ValueIsFilled(AccessGroupsProperties) Then
			Continue;
		EndIf;
		AccessKindProperties = CurrentAccessKindProperties(ChangeDescription,
			IsAccessGroup, Data, Caches);
		If AccessKindProperties = Undefined Then
			Continue;
		EndIf;
		ValueProperties = CurrentValueProperties(ChangeDescription.AccessValue, Data, Caches);
		RowProperties = New Structure;
		RowProperties.Insert("Profile",                          DeserializedRef(AccessGroupsProperties[0].Profile));
		RowProperties.Insert("ProfilePresentation",             AccessGroupsProperties[0].ProfilePresentation);
		RowProperties.Insert("ProfileDeletionMark",           AccessGroupsProperties[0].ProfileDeletionMark);
		RowProperties.Insert("ValueOrGroup",                ValueProperties.AccessValue);
		RowProperties.Insert("ValueOrGroupPresentation",   ValueProperties.AccessValuePresentation);
		RowProperties.Insert("IsValuesGroup",                ChangeDescription.IsValuesGroup);
		RowProperties.Insert("IncludeSubordinateAccessValues",               ChangeDescription.IncludeSubordinateAccessValues);
		PreviousValues1 = AccessGroupsProperties[0].OldPropertyValues;
		RowProperties.Insert("PreviousProfile", ?(PreviousValues1.Property("Profile"),
			DeserializedRef(PreviousValues1.Profile), RowProperties.Profile));
		RowProperties.Insert("PreviousProfilePresentation", ?(PreviousValues1.Property("ProfilePresentation"),
			PreviousValues1.ProfilePresentation, RowProperties.ProfilePresentation));
		RowProperties.Insert("PreviousProfileDeletionMark", ?(PreviousValues1.Property("ProfileDeletionMark"),
			PreviousValues1.ProfileDeletionMark, RowProperties.ProfileDeletionMark));
		PreviousValues1 = ChangeDescription.OldPropertyValues;
		RowProperties.Insert("PreviousIncludeSubordinateAccessValues", ?(PreviousValues1.Property("IncludeSubordinateAccessValues"),
			PreviousValues1.IncludeSubordinateAccessValues, RowProperties.IncludeSubordinateAccessValues));
		If TypeOf(Data.Source) = Type("ValueTable")
		 Or AccessKindProperties.AccessKindChangeKind <> "*" Then
			Variants = CommonClientServer.ValueInArray("");
		Else
			Variants = New Array;
			Variants.Add("-");
			Variants.Add("+");
		EndIf;
		For Each AccessGroupProperties In AccessGroupsProperties Do
			RowProperties.Insert("AccessGroup",                    DeserializedRef(AccessGroupProperties.AccessGroup));
			RowProperties.Insert("PresentationAccessGroups",       AccessGroupProperties.Presentation);
			RowProperties.Insert("AccessGroupDeletionMark",     AccessGroupProperties.DeletionMark);
			PreviousValues1 = AccessGroupProperties.OldPropertyValues;
			RowProperties.Insert("PreviousAccessGroupDeletionMark", ?(PreviousValues1.Property("DeletionMark"),
				PreviousValues1.DeletionMark, RowProperties.AccessGroupDeletionMark));
			For Each Variant In Variants Do
				If Variant <> "" Then
					If ChangeDescription.ChangeType = "Added2" And Variant = "-"
					 Or ChangeDescription.ChangeType = "Deleted"   And Variant = "+" Then
						Continue;
					EndIf;
					AccessKindProperties.AccessKindChangeKind = Variant;
				EndIf;
				AllAllowed = ?(AccessKindProperties.AccessKindChangeKind = "+",
					AccessKindProperties.AllAllowed, AccessKindProperties.PreviousAllAllowed);
				IncludeSubordinateAccessValues = ?(Variant = "+", RowProperties.IncludeSubordinateAccessValues,
					?(Variant = "-", RowProperties.PreviousIncludeSubordinateAccessValues,
						RowProperties.IncludeSubordinateAccessValues Or RowProperties.PreviousIncludeSubordinateAccessValues));
				AccessKindProperties.AccessKindPresentation =
					AccessKindProperties.AccessKindPresentationWithoutClarification
					+ " (" + ?(AllAllowed, NStr("vi = 'Cấm';
												|ru = 'Запрещенные';
												|en = 'Denied'; fa = 'رد شده';
												|it = 'Запрещенные';
												|pl = 'Denied';
												|tr = 'Yasak'"), NStr("vi = 'Được phép';
																		|ru = 'Разрешенные';
																		|en = 'Allowed'; fa = 'مجاز';
																		|it = 'Разрешенные';
																		|pl = 'Allowed';
																		|tr = 'İzin verilen'")) + ")";
				ValuesOfGroup = Undefined;
				AccessValueChangeKind = ?(ChangeDescription.ChangeType = "Added2", "+",
					?(ChangeDescription.ChangeType = "Deleted", "-", Variant));
				If ChangeDescription.IsValuesGroup Or IncludeSubordinateAccessValues Then
					Filter = New Structure("ValuesGroup", ChangeDescription.AccessValue);
					ValuesOfGroup = Data.ChangeInAccessValuesGroups.FindRows(Filter);
					For Each ValueOfGroup In ValuesOfGroup Do
						If IsValueBelongsToUnmodified(ValueOfGroup, ChangeDescription, Data) Then
							Continue;
						EndIf;
						IsValueOfGroup = ValueOfGroup.AccessValue <> ChangeDescription.AccessValue;
						If Not IsValueOfGroup And AccessValueChangeKind = "" Then
							Continue;
						EndIf;
						NewRow = Changes.Add();
						FillPropertyValues(NewRow, EventProperties);
						FillPropertyValues(NewRow, RowProperties);
						FillPropertyValues(NewRow, AccessKindProperties);
						FillPropertyValues(NewRow,
							CurrentValueProperties(ValueOfGroup.AccessValue, Data, Caches));
						NewRow.AccessValueChangeKind = ?(Variant <> "", AccessValueChangeKind,
							?(ValueOfGroup.ChangeType = "Added2", "+",
								?(ValueOfGroup.ChangeType = "Deleted", "-",
									?(IsValueOfGroup And RowProperties.IncludeSubordinateAccessValues And Not RowProperties.PreviousIncludeSubordinateAccessValues, "+",
										?(IsValueOfGroup And Not RowProperties.IncludeSubordinateAccessValues And RowProperties.PreviousIncludeSubordinateAccessValues, "-",
											AccessValueChangeKind)))));
					EndDo;
				EndIf;
				If Not ValueIsFilled(ValuesOfGroup)
				   And Not IsValueBelongsToUnmodified(ChangeDescription, ChangeDescription, Data) Then
					NewRow = Changes.Add();
					FillPropertyValues(NewRow, EventProperties);
					FillPropertyValues(NewRow, RowProperties);
					FillPropertyValues(NewRow, AccessKindProperties);
					FillPropertyValues(NewRow, ValueProperties);
					NewRow.AccessValueChangeKind = AccessValueChangeKind;
					If ValueProperties.AccessValue = "*" Then
						ValuePresentation = "<" + ?(AllAllowed,
							NStr("vi = 'Cho phép tất cả';
								|ru = 'Все разрешены';
								|en = 'All allowed'; fa = 'همه مجاز';
								|it = 'Все разрешены';
								|pl = 'Wszystkie są dozwolone';
								|tr = 'Hepsine izin verildi'"), NStr("vi = 'Cấm tất cả';
															|ru = 'Все запрещены';
															|en = 'All denied'; fa = 'All denied';
															|it = 'Все запрещены';
															|pl = 'Wszystkie są zabronione';
															|tr = 'Hepsi yasak'")) + ">";
						NewRow.ValueOrGroupPresentation = ValuePresentation;
						NewRow.AccessValuePresentation   = ValuePresentation;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

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

Function CurrentAccessKindProperties(ChangeDescription, IsAccessGroup, Data, Caches)
	
	Filter = New Structure("AccessGroupOrProfile, AccessKind",
		ChangeDescription.AccessGroupOrProfile, ChangeDescription.AccessKind);
	FoundRows = Data.AccessKindsChange.FindRows(Filter);
	
	If Not ValueIsFilled(FoundRows) Then
		Return Undefined;
	EndIf;
	AccessKindChange = FoundRows[0];
	
	OldPropertyValues = AccessKindChange.OldPropertyValues;
	PreviousPredefined = ?(OldPropertyValues.Property("Predefined"),
			OldPropertyValues.Predefined, AccessKindChange.Predefined);
	
	If IsAccessGroup
	   And AccessKindChange.Predefined <> False
	   And Not (PreviousPredefined = False
	         And ChangeDescription.ChangeType <> "Added2")
	 Or Not IsAccessGroup
	   And AccessKindChange.Predefined <> True
	   And Not (PreviousPredefined = True
	         And ChangeDescription.ChangeType <> "Added2") Then
		Return Undefined;
	EndIf;
	
	Cache = Caches.Get("AccessKindsProperties");
	If Cache = Undefined Then
		Cache = New Map;
		Caches.Insert("AccessKindsProperties", Cache);
	EndIf;
	
	Properties = Cache.Get(ChangeDescription.AccessKind);
	If Properties = Undefined Then
		FoundRow = Data.AccessKindsPresentation.Find(ChangeDescription.AccessKind, "AccessKind");
		Properties = New Structure;
		Properties.Insert("AccessKind", DeserializedRef(ChangeDescription.AccessKind));
		Properties.Insert("AccessKindName", "");
		Properties.Insert("AccessKindUsed", False);
		Properties.Insert("AccessKindPresentation", "");
		Properties.Insert("AccessKindPresentationWithoutClarification", "");
		If FoundRow <> Undefined Then
			Properties.AccessKindName                       = FoundRow.Name;
			Properties.AccessKindUsed               = FoundRow.Used;
			Properties.AccessKindPresentationWithoutClarification = FoundRow.Presentation;
		EndIf;
		ModuleAccessManagementInternalCached = Common.CommonModule("AccessManagementInternalCached");
		AccessKindsPresentation = ModuleAccessManagementInternalCached.AccessKindsPresentation();
		Presentation = AccessKindsPresentation.Get(TypeOf(Properties.AccessKind));
		If Presentation <> Undefined Then
			Properties.AccessKindPresentationWithoutClarification = Presentation;
		EndIf;
		Cache.Insert(ChangeDescription.AccessKind, Properties);
	EndIf;
	
	Properties.Insert("AllAllowed",      AccessKindChange.AllAllowed);
	Properties.Insert("Predefined", AccessKindChange.Predefined);
	
	Properties.Insert("PreviousAllAllowed", ?(OldPropertyValues.Property("AllAllowed"),
			OldPropertyValues.AllAllowed, Properties.AllAllowed));
	
	Properties.Insert("PreviousPredefined", PreviousPredefined);
	
	If TypeOf(Data.Source) = Type("ValueTable") Then
		AccessKindChangeKind = "*";
		
	ElsIf AccessKindChange.ChangeType = "Added2"
	      Or Not IsAccessGroup
	        And Properties.Predefined
	        And Not Properties.PreviousPredefined Then
		
		AccessKindChangeKind = "+";
		
	ElsIf AccessKindChange.ChangeType = "Deleted"
	      Or Not IsAccessGroup
	        And Not Properties.Predefined
	        And Properties.PreviousPredefined Then
		
		AccessKindChangeKind = "-";
		
	ElsIf Properties.AllAllowed <> Properties.PreviousAllAllowed Then
		AccessKindChangeKind = "*";
	EndIf;
	
	Properties.Insert("AccessKindChangeKind", AccessKindChangeKind);
	AccessKindChange.Processed = True;
	
	Return Properties;
	
EndFunction

Function CurrentValueProperties(Value, Data, Caches)
	
	Cache = Caches.Get("ValuesAndValueGroupsProperties");
	If Cache = Undefined Then
		Cache = New Map;
		Caches.Insert("ValuesAndValueGroupsProperties", Cache);
	EndIf;
	
	Properties = Cache.Get(Value);
	If Properties = Undefined Then
		FoundRow = Data.AccessValuesPresentation.Find(Value, "Value");
		Properties = New Structure;
		Properties.Insert("AccessValue", ?(Value = "*", "*", DeserializedRef(Value)));
		Properties.Insert("AccessValuePresentation", "");
		If FoundRow <> Undefined Then
			Properties.AccessValuePresentation = FoundRow.Presentation;
		EndIf;
		Cache.Insert(Value, Properties);
	EndIf;
	
	Return Properties;
	
EndFunction

Function IsValueBelongsToUnmodified(ValueWithChange, ChangeDescription, Data)
	
	Value = ValueWithChange.AccessValue;
	
	Filter = New Structure("AccessGroupOrProfile,AccessKind,AccessValue",
		ChangeDescription.AccessGroupOrProfile, ChangeDescription.AccessKind, Value);
	
	If ValueIsFilled(Data.UnmodifiedValues.FindRows(Filter)) Then
		Return True;
	EndIf;
	
	Filter = New Structure("AccessGroupOrProfile,AccessKind,ValueOfGroup",
		ChangeDescription.AccessGroupOrProfile, ChangeDescription.AccessKind, Value);
	
	If ValueIsFilled(Data.UnmodifiedValues.FindRows(Filter)) Then
		Return True;
	EndIf;
	
	Return False;
	
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