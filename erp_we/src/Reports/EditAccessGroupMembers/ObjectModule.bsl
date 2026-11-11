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
	NameOfEventAccessGroupsMembersChanged =
		ModuleAccessManagementInternal.NameOfLogEventAccessGroupsMembersChanged();
	EventsForFilter = New Array;
	EventsForFilter.Add(
		UsersInternal.NameOfLogEventUserGroupsMembersChanged());
	EventsForFilter.Add(
		UsersInternal.NameOfLogEventExternalUserGroupsMembersChanged());
	EventsForFilter.Add(NameOfEventAccessGroupsMembersChanged);
	Filter.Insert("Event", EventsForFilter);
	
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
	
	TypeProfile       = New TypeDescription(StringType100, "CatalogRef.AccessGroupProfiles");
	TypeAccessGroup = New TypeDescription(StringType100, "CatalogRef.AccessGroups");
	TypeMember      = New TypeDescription(StringType100, "CatalogRef.Users,
		|CatalogRef.UserGroups,
		|CatalogRef.ExternalUsers,
		|CatalogRef.ExternalUsersGroups");
	TypeUser  = New TypeDescription(StringType100, "CatalogRef.Users,
		|CatalogRef.ExternalUsers");
	
	Changes = New ValueTable;
	Columns = Changes.Columns;
	Columns.Add("Profile",                      TypeProfile);
	Columns.Add("ProfilePresentation",         StringType1000);
	Columns.Add("ProfileDeletionMark",       BooleanType);
	Columns.Add("AccessGroup",                TypeAccessGroup);
	Columns.Add("PresentationAccessGroups",   StringType1000);
	Columns.Add("AccessGroupDeletionMark", BooleanType);
	Columns.Add("EventNumber",                 NumberType);
	Columns.Add("Date",                         DateType);
	Columns.Add("Author",                        StringType100);
	Columns.Add("AuthorID",          StringType36);
	Columns.Add("Application",                   StringType20);
	Columns.Add("Computer",                    StringType);
	Columns.Add("Session",                        NumberType);
	Columns.Add(ConnectionColumnName,           NumberType);
	Columns.Add("Member",                     TypeMember);
	Columns.Add("IsMemberUser",      BooleanType);
	Columns.Add("ParticipantPresentation",       StringType1000);
	Columns.Add("MemberTill",                  DateType);
	Columns.Add("IsMemberUsed",         BooleanType);
	Columns.Add("User",                 TypeUser);
	Columns.Add("UserPresentation2",    StringType1000);
	Columns.Add("IsUserUsed",     BooleanType);
	Columns.Add("IsBelongToLowerLevelGroup",          BooleanType);
	Columns.Add("ChangeType",                 StringType1);
	Columns.Add("PreviousProfile",                  TypeProfile);
	Columns.Add("PreviousProfilePresentation",     StringType1000);
	Columns.Add("PreviousProfileDeletionMark",   BooleanType);
	Columns.Add("PreviousAccessGroupDeletionMark", BooleanType);
	Columns.Add("PreviousMemberTill",              DateType);
	
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
	Filterdata_.Insert("Attendees", ValueIDs(
		ParameterValue(Settings, "Member", Undefined)));
	
	For Each Event In Events Do
		If Event.Event = NameOfEventAccessGroupsMembersChanged Then
			Data = AccessGroupsMembersChangesExtendedData(Event.Data, Filterdata_);
		Else
			Data = UserGroupsMembersChangesExtendedData(Event.Data, Filterdata_);
		EndIf;
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
		
		If Event.Event = NameOfEventAccessGroupsMembersChanged Then
			For Each DescriptionOfTheParticipant In Data.ChangesInMembers Do
				AccessGroupProperties = Data.AccessGroupsPresentation.Find(
					DescriptionOfTheParticipant.AccessGroup, "AccessGroup");
				If AccessGroupProperties = Undefined Then
					Continue;
				EndIf;
				RowProperties = New Structure;
				RowProperties.Insert("Profile",                      DeserializedRef(AccessGroupProperties.Profile));
				RowProperties.Insert("ProfilePresentation",         AccessGroupProperties.ProfilePresentation);
				RowProperties.Insert("ProfileDeletionMark",       AccessGroupProperties.ProfileDeletionMark);
				RowProperties.Insert("AccessGroup",                DeserializedRef(AccessGroupProperties.AccessGroup));
				RowProperties.Insert("PresentationAccessGroups",   AccessGroupProperties.Presentation);
				RowProperties.Insert("AccessGroupDeletionMark", AccessGroupProperties.DeletionMark);
				RowProperties.Insert("Member",                     DeserializedRef(DescriptionOfTheParticipant.Member));
				RowProperties.Insert("ParticipantPresentation",       DescriptionOfTheParticipant.ParticipantPresentation);
				RowProperties.Insert("MemberTill",                  DescriptionOfTheParticipant.ValidityPeriod);
				RowProperties.Insert("IsMemberUsed",         DescriptionOfTheParticipant.IsMemberUsed);
				RowProperties.Insert("ChangeType",                 ?(DescriptionOfTheParticipant.ChangeType = "Deleted", "-",
					?(DescriptionOfTheParticipant.ChangeType = "Added2", "+",
					?(DescriptionOfTheParticipant.ChangeType = "IsChanged", "*", "?"))));
				
				PreviousValues1 = AccessGroupProperties.OldPropertyValues;
				RowProperties.Insert("PreviousProfile", ?(PreviousValues1.Property("Profile"),
					DeserializedRef(PreviousValues1.Profile), RowProperties.Profile));
				RowProperties.Insert("PreviousProfilePresentation", ?(PreviousValues1.Property("ProfilePresentation"),
					PreviousValues1.ProfilePresentation, RowProperties.ProfilePresentation));
				RowProperties.Insert("PreviousProfileDeletionMark", ?(PreviousValues1.Property("ProfileDeletionMark"),
					PreviousValues1.ProfileDeletionMark, RowProperties.ProfileDeletionMark));
				RowProperties.Insert("PreviousAccessGroupDeletionMark", ?(PreviousValues1.Property("DeletionMark"),
					PreviousValues1.DeletionMark, RowProperties.AccessGroupDeletionMark));
				PreviousValues1 = DescriptionOfTheParticipant.OldPropertyValues;
				RowProperties.Insert("PreviousMemberTill", ?(PreviousValues1.Property("ValidityPeriod"),
					PreviousValues1.ValidityPeriod, RowProperties.MemberTill));
				
				Filter = New Structure("UsersGroup", DescriptionOfTheParticipant.Member);
				GroupComposition1 = Data.UserGroupCompositions.FindRows(Filter);
				If GroupComposition1.Count() = 0 Then
					NewRow = Changes.Add();
					FillPropertyValues(NewRow, EventProperties);
					FillPropertyValues(NewRow, RowProperties);
					NewRow.User              = DescriptionOfTheParticipant.Member;
					NewRow.IsMemberUser   = True;
					NewRow.UserPresentation2 = DescriptionOfTheParticipant.ParticipantPresentation;
					NewRow.IsUserUsed  = DescriptionOfTheParticipant.IsMemberUsed;
				Else
					For Each UserDetails In GroupComposition1 Do
						NewRow = Changes.Add();
						FillPropertyValues(NewRow, EventProperties);
						FillPropertyValues(NewRow, RowProperties);
						NewRow.User              = UserDetails.User;
						NewRow.UserPresentation2 = UserDetails.UserPresentation2;
						NewRow.IsUserUsed  = UserDetails.Used;
						NewRow.IsBelongToLowerLevelGroup       = UserDetails.IsBelongToLowerLevelGroup;
					EndDo;
				EndIf;
			EndDo;
		Else
			FilterUser = New Structure("UsersGroup, User",
				UsersInternal.SerializedRef(Users.AllUsersGroup()));
			ExternalUserFilter = New Structure("UsersGroup, User",
				UsersInternal.SerializedRef(ExternalUsers.AllExternalUsersGroup()));
			
			For Each DescriptionOfTheParticipant In Data.AccessGroupsMembers Do
				AccessGroupProperties = Data.AccessGroupsPresentation.Find(
					DescriptionOfTheParticipant.AccessGroup, "AccessGroup");
				If AccessGroupProperties = Undefined Then
					Continue;
				EndIf;
				Filter = New Structure("UsersGroup", DescriptionOfTheParticipant.Member);
				FoundRows = Data.ChangesInComposition.FindRows(Filter);
				ThisIsTheUser = False;
				If Not ValueIsFilled(FoundRows) Then
					ThisIsTheUser = True;
					FilterUser.User = DescriptionOfTheParticipant.Member;
					FoundRows = Data.ChangesInComposition.FindRows(FilterUser);
					If Not ValueIsFilled(FoundRows) Then
						ExternalUserFilter.User = DescriptionOfTheParticipant.Member;
						FoundRows = Data.ChangesInComposition.FindRows(ExternalUserFilter);
						If Not ValueIsFilled(FoundRows) Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
				CurrentProfile = DeserializedRef(AccessGroupProperties.Profile);
				CurrentAccessGroup = DeserializedRef(AccessGroupProperties.AccessGroup);
				For Each FoundRow In FoundRows Do
					NewRow = Changes.Add();
					FillPropertyValues(NewRow, EventProperties);
					NewRow.Profile                      = CurrentProfile;
					NewRow.ProfilePresentation         = AccessGroupProperties.ProfilePresentation;
					NewRow.ProfileDeletionMark       = AccessGroupProperties.ProfileDeletionMark;
					NewRow.AccessGroup                = CurrentAccessGroup;
					NewRow.PresentationAccessGroups   = AccessGroupProperties.Presentation;
					NewRow.AccessGroupDeletionMark = AccessGroupProperties.DeletionMark;
					If ThisIsTheUser Then
						NewRow.Member                  = DeserializedRef(FoundRow.User);
						NewRow.IsMemberUser   = True;
						NewRow.ParticipantPresentation    = FoundRow.UserPresentation2;
						NewRow.User              = NewRow.Member;
						NewRow.UserPresentation2 = NewRow.ParticipantPresentation;
					Else
						NewRow.Member                  = DeserializedRef(FoundRow.UsersGroup);
						NewRow.ParticipantPresentation    = FoundRow.GroupPresentation;
						NewRow.User              = DeserializedRef(FoundRow.User);
						NewRow.UserPresentation2 = FoundRow.UserPresentation2;
					EndIf;
					NewRow.MemberTill                  = DescriptionOfTheParticipant.ValidityPeriod;
					NewRow.IsMemberUsed         = FoundRow.Used;
					NewRow.IsUserUsed     = FoundRow.Used;
					NewRow.IsBelongToLowerLevelGroup          = FoundRow.IsBelongToLowerLevelGroup;
					NewRow.ChangeType                 = ?(FoundRow.ChangeType = "Deleted", "-",
						?(FoundRow.ChangeType = "Added2", "+",
						?(FoundRow.ChangeType = "IsChanged", "*", "?")));
				
					NewRow.PreviousProfile                      = NewRow.Profile;
					NewRow.PreviousProfilePresentation         = NewRow.ProfilePresentation;
					NewRow.PreviousProfileDeletionMark       = NewRow.ProfileDeletionMark;
					NewRow.PreviousAccessGroupDeletionMark = NewRow.AccessGroupDeletionMark;
					NewRow.PreviousMemberTill                  = NewRow.MemberTill;
				EndDo;
			EndDo;
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
Function UserGroupsMembersChangesExtendedData(EventData, Filterdata_)
	
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
	Location.Insert("AccessGroupsMembers");
	Location.Insert("AccessGroupsPresentation");
	FillPropertyValues(Location, Data);
	If Location.DataStructureVersion <> 2 Then
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
	
	Properties = New Structure;
	Properties.Insert("ParentID", "");
	Properties.Insert("GroupID", "");
	Properties.Insert("GroupPresentation", "");
	Properties.Insert("GroupReference", "");
	
	GroupsPresentation = StoredTable(Location.GroupsPresentation, Properties);
	If GroupsPresentation = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("UserIdentificator", "");
	Properties.Insert("UserPresentation2", "");
	Properties.Insert("RefToUser", "");
	
	PresentationUsers = StoredTable(Location.PresentationUsers, Properties);
	If PresentationUsers = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroup", "");
	Properties.Insert("Member", "");
	Properties.Insert("ValidityPeriod", '00010101');
	
	AccessGroupsMembers = StoredTable(Location.AccessGroupsMembers, Properties);
	If AccessGroupsMembers = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroup", "");
	Properties.Insert("DeletionMark", False);
	Properties.Insert("Presentation", "");
	Properties.Insert("Profile", "");
	Properties.Insert("ProfileDeletionMark", False);
	Properties.Insert("ProfilePresentation", "");
	
	AccessGroupsPresentation = StoredTable(Location.AccessGroupsPresentation, Properties);
	If AccessGroupsPresentation = Undefined Then
		Return Undefined;
	EndIf;
	
	GroupsPresentation.Indexes.Add("GroupID");
	PresentationUsers.Indexes.Add("UserIdentificator");
	
	ChangesInComposition.Columns.Add("GroupPresentation");
	ChangesInComposition.Columns.Add("UsersGroup");
	ChangesInComposition.Columns.Add("UserPresentation2");
	ChangesInComposition.Columns.Add("User");
	
	IndexOf = ChangesInComposition.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = ChangesInComposition.Get(IndexOf);
		GroupProperties = GroupsPresentation.Find(
			String.GroupID, "GroupID");
		UserProperties = PresentationUsers.Find(
			String.UserIdentificator, "UserIdentificator");
		
		If UserProperties = Undefined
		 Or GroupProperties = Undefined
		 Or Filterdata_.Attendees <> Undefined
		   And Filterdata_.Attendees.Get(String.GroupID) = Undefined
		   And Filterdata_.Attendees.Get(String.UserIdentificator) = Undefined Then
			
			ChangesInComposition.Delete(IndexOf);
			Continue;
		EndIf;
		String.GroupPresentation = GroupProperties.GroupPresentation;
		String.UsersGroup = GroupProperties.GroupReference;
		String.UserPresentation2 = UserProperties.UserPresentation2;
		String.User              = UserProperties.RefToUser;
	EndDo;
	
	If Not ValueIsFilled(ChangesInComposition) Then
		Return Undefined;
	EndIf;
	
	AccessGroupsPresentation.Indexes.Add("AccessGroup");
	ChangesInComposition.Indexes.Add("UsersGroup, User");
	
	Result = New Structure;
	Result.Insert("ChangesInComposition", ChangesInComposition);
	Result.Insert("AccessGroupsMembers", AccessGroupsMembers);
	Result.Insert("AccessGroupsPresentation", AccessGroupsPresentation);
	
	If Filterdata_.Profiles = Undefined
	   And Filterdata_.AccessGroups = Undefined Then
		
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
			Continue;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccessGroupsPresentation) Then
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  EventData - String
//
// Returns:
//  Structure
//
Function AccessGroupsMembersChangesExtendedData(EventData, Filterdata_)
	
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
	Location.Insert("ChangesInMembers");
	Location.Insert("AccessGroupsPresentation");
	Location.Insert("UserGroupCompositions");
	FillPropertyValues(Location, Data);
	If Location.DataStructureVersion <> 1 Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AccessGroup", "");
	Properties.Insert("Member", "");
	Properties.Insert("ParticipantPresentation", "");
	Properties.Insert("IsMemberUsed", False);
	Properties.Insert("ValidityPeriod", '00010101');
	Properties.Insert("OldPropertyValues", New Structure);
	Properties.Insert("ChangeType", "");
	
	ChangesInMembers = StoredTable(Location.ChangesInMembers, Properties);
	If Not ValueIsFilled(ChangesInMembers) Then
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
	If AccessGroupsPresentation = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("UsersGroup", "");
	Properties.Insert("User", "");
	Properties.Insert("Used", False);
	Properties.Insert("UserPresentation2", "");
	Properties.Insert("IsBelongToLowerLevelGroup", False);
	
	UserGroupCompositions = StoredTable(Location.UserGroupCompositions, Properties);
	If UserGroupCompositions = Undefined Then
		Return Undefined;
	EndIf;
	
	AccessGroupsPresentation.Indexes.Add("AccessGroup");
	UserGroupCompositions.Indexes.Add("UsersGroup");
	
	Result = New Structure;
	Result.Insert("ChangesInMembers", ChangesInMembers);
	Result.Insert("AccessGroupsPresentation", AccessGroupsPresentation);
	Result.Insert("UserGroupCompositions", UserGroupCompositions);
	
	If Filterdata_.Profiles = Undefined
	   And Filterdata_.AccessGroups = Undefined
	   And Filterdata_.Attendees = Undefined Then
		
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
			Continue;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccessGroupsPresentation) Then
		Return Undefined;
	EndIf;
	
	AllUserGroups = New Map;
	IndexOf = UserGroupCompositions.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = UserGroupCompositions.Get(IndexOf);
		AllUserGroups.Insert(String.UsersGroup, True);
		If Filterdata_.Attendees <> Undefined
		   And Filterdata_.Attendees.Get(String.User) = Undefined
		   And Filterdata_.Attendees.Get(String.UsersGroup) = Undefined Then
			UserGroupCompositions.Delete(IndexOf);
			Continue;
		EndIf;
	EndDo;
	
	IndexOf = ChangesInMembers.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		String = ChangesInMembers.Get(IndexOf);
		ThisIsTheUser = AllUserGroups.Get(String.Member) = Undefined;
		If ThisIsTheUser
		   And Filterdata_.Attendees <> Undefined
		   And Filterdata_.Attendees.Get(String.Member) = Undefined
		 Or Not ThisIsTheUser
		   And UserGroupCompositions.Find(String.Member, "UsersGroup") = Undefined Then
			ChangesInMembers.Delete(IndexOf);
			Continue;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(ChangesInMembers) Then
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