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
		   And Context.Parameters.Property("CommandParameter") Then
			
			ValueList = New ValueList;
			ValueList.LoadValues(Context.Parameters.CommandParameter);
			UsersInternal.SetFilterOnParameter("User",
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
	ExternalDataSets.Insert("Changes", ChangeOfUserAccounts(Settings));
	
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

Function ChangeOfUserAccounts(Settings)
	
	ConnectionColumnName = UserMonitoringInternal.ConnectionColumnName();
	Filter = New Structure;
	
	TransStatuses = New Array;
	TransStatuses.Add(EventLogEntryTransactionStatus.Committed);
	TransStatuses.Add(EventLogEntryTransactionStatus.NotApplicable);
	Filter.Insert("TransactionStatus", TransStatuses);
	
	FilterUsers = FilterUsers(ParameterValue(Settings, "User", Undefined));
	
	Period = ParameterValue(Settings, "Period", New StandardPeriod);
	If ValueIsFilled(Period.StartDate) Then
		Filter.Insert("StartDate", Period.StartDate);
	EndIf;
	If ValueIsFilled(Period.EndDate) Then
		Filter.Insert("EndDate", Period.EndDate);
	EndIf;
	
	EventFilter = New Array;
	EventFilter.Add("_$User$_.New");
	EventFilter.Add("_$User$_.Update");
	EventFilter.Add("_$User$_.Delete");
	EventFilter.Add(UsersInternal.EventNameChangeAdditionalForLogging());
	Filter.Insert("Event", EventFilter);
	
	Author = ParameterValue(Settings, "Author", Null);
	If Author <> Null Then
		Filter.Insert("User", String(Author));
	EndIf;
	
	LogColumns = "Date,User,UserName,Computer,
	|ApplicationName,Event,EventPresentation,Data,Session," + ConnectionColumnName;
	
	BooleanType     = New TypeDescription("Boolean");
	DateType       = New TypeDescription("Date");
	NumberType      = New TypeDescription("Number");
	StringType     = New TypeDescription("String");
	StringType20   = New TypeDescription("String", , New StringQualifiers(20));
	StringType36   = New TypeDescription("String", , New StringQualifiers(36));
	StringType100  = New TypeDescription("String", , New StringQualifiers(100));
	StringType255  = New TypeDescription("String", , New StringQualifiers(255));
	StringType1024 = New TypeDescription("String", , New StringQualifiers(1024));
	TypeUser = New TypeDescription("CatalogRef.Users,
		|CatalogRef.ExternalUsers");
	TypePresentation = New TypeDescription(StringType1024, TypeUser.Types());
	
	Properties = New Structure;
	Properties.Insert("Id",                                 StringType36);
	Properties.Insert("Presentation",                                 TypePresentation);
	Properties.Insert("Ref",                                        TypeUser);
	Properties.Insert("Invalid",                                BooleanType);
	Properties.Insert("DeletionMark",                               BooleanType);
	Properties.Insert("Name",                                           StringType100);
	Properties.Insert("FullName",                                     StringType255);
	Properties.Insert("CanSignIn",                        BooleanType);
	Properties.Insert("StandardAuthentication",                     BooleanType);
	Properties.Insert("OpenIDAuthentication",                          BooleanType);
	Properties.Insert("OpenIDConnectAuthentication",                   BooleanType);
	Properties.Insert("AccessTokenAuthentication",                  BooleanType);
	Properties.Insert("OSAuthentication",                              BooleanType);
	Properties.Insert("CannotChangePassword",                       BooleanType);
	Properties.Insert("CannotRecoveryPassword",                BooleanType);
	Properties.Insert("UnsafeActionProtection",                       BooleanType);
	Properties.Insert("ShowInList",                       BooleanType);
	Properties.Insert("PasswordChanged",                                 BooleanType);
	Properties.Insert("PasswordIsSet",                              BooleanType);
	Properties.Insert("PasswordSettingDate",                           DateType);
	Properties.Insert("UserMustChangePasswordOnAuthorization",                BooleanType);
	Properties.Insert("UnlimitedValidityPeriod",                       BooleanType);
	Properties.Insert("ValidityPeriod",                                  DateType);
	Properties.Insert("InactivityPeriodBeforeDenyingAuthorization",    NumberType);
	Properties.Insert("SecondAuthenticationFactorSettings",         StringType);
	Properties.Insert("SecondAuthenticationFactorSettingsProcessing", StringType);
	Properties.Insert("OSUser",                                StringType1024);
	Properties.Insert("PasswordPolicyName",                            StringType100);
	Properties.Insert("Email",                         StringType255);
	Properties.Insert("RunMode",                                  StringType100);
	Properties.Insert("Language",                                          StringType100);
	Properties.Insert("Roles",                                          StringType);
	
	UserProperties = Properties;
	
	Changes = New ValueTable;
	Columns = Changes.Columns;
	Columns.Add("Date",                DateType);
	Columns.Add("EventKind",          StringType);
	Columns.Add("Author",               StringType100);
	Columns.Add("AuthorID", StringType36);
	Columns.Add("Application",          StringType20);
	Columns.Add("Computer",           StringType);
	Columns.Add("SessionStarted",        DateType);
	Columns.Add("Session",               NumberType);
	Columns.Add(ConnectionColumnName,  NumberType);
	
	TypeChanged = New TypeDescription("Number",,, New NumberQualifiers(1, 0, AllowedSign.Nonnegative));
	For Each KeyAndValue In UserProperties Do
		FieldName = KeyAndValue.Key;
		Columns.Add(FieldName, KeyAndValue.Value);
		If FieldName = "Id" Or FieldName = "Presentation" Then
			Continue;
		EndIf;
		FieldName_Changed = FieldName + "_" + "IsChanged";
		Columns.Add(FieldName_Changed, TypeChanged);
		UserProperties[FieldName] = FieldName_Changed;
	EndDo;
	
	Columns.Add("RolesUpdatesOnly", StringType);
	Columns.Add("RolesNames");
	Columns.Add("PreviousEvent");
	
	StartupModesPresentations = New Map;
	For Each RunMode In ClientRunMode Do
		ValueFullName = GetPredefinedValueFullName(RunMode);
		EnumValueName = Mid(ValueFullName, StrFind(ValueFullName, ".") + 1);
		StartupModesPresentations.Insert(Upper(EnumValueName), String(RunMode));
	EndDo;
	
	LangsPresentation = New Map;
	For Each Language In Metadata.Languages Do
		LangsPresentation.Insert(Upper(Language.FullName()), Language.Presentation());
	EndDo;
	
	RolesPresentation = New Map;
	For Each Role In Metadata.Roles Do
		RolesPresentation.Insert(Upper(Role.FullName()), Role.Presentation());
	EndDo;
	
	EventPresentationAdd = NStr("vi = 'Thêm';
								|ru = 'Добавление';
								|en = 'Insert'; fa = 'درج';
								|it = 'Добавление';
								|pl = 'Insert';
								|tr = 'Ekle'");
	EventPresentationUpdate  = NStr("vi = 'Thay đổi';
									|ru = 'Изменение';
									|en = 'Update'; fa = 'به‌روزرسانی';
									|it = 'Изменение';
									|pl = 'Update';
									|tr = 'Değişim'");
	EventDeletePresentation   = NStr("vi = 'Xóa bỏ';
									|ru = 'Удаление';
									|en = 'Delete'; fa = 'حذف';
									|it = 'Удаление';
									|pl = 'Delete';
									|tr = 'Sil'");
	PresentationDoNotUse    = NStr("vi = 'Không sử dụng';
									|ru = 'Не использовать';
									|en = 'Do not use.'; fa = 'Do not use.';
									|it = 'Non utilizzare';
									|pl = 'Nie używaj';
									|tr = 'İşlemde kullanma'");
	PresentationUse      = NStr("vi = 'Sử dụng tài khoản tiếp theo khi lỗi';
								|ru = 'Использовать следующую при ошибке';
								|en = 'On error, use next role'; fa = 'On error, use next role';
								|it = 'Использовать следующую при ошибке';
								|pl = 'On error, use next role';
								|tr = 'Hata durumunda bir sonrakisini kullan'");
	
	SetPrivilegedMode(True);
	Events = New ValueTable;
	UnloadEventLog(Events, Filter, LogColumns);
	
	LastEvents = New Map;
	IDs = New Map;
	HasEventsWithoutID = False;
	
	For Each Event In Events Do
		
		EventName = Event.Event;
		
		If StrStartsWith(EventName, "_$User$_.") Then
			Data = Event.Data;
			If Data = Undefined Then
				Continue;
			EndIf;
			If EventName = "_$User$_.New" Then
				EventKind = EventPresentationAdd;
			ElsIf EventName = "_$User$_.Update" Then
				EventKind = EventPresentationUpdate;
			Else // "_$User$_.Delete"
				EventKind = EventDeletePresentation;
			EndIf;
			If Data.Property("StandardAuthentication") Then
				Data.Insert("CanSignIn", Users.CanSignIn(Data));
			EndIf;
			If Data.Property("UUID") Then
				LastEvent = LastEvents.Get(Lower(Data.UUID));
			Else
				HasEventsWithoutID = True;
				LastEvent = LastEvents.Get(Upper(Data.Name));
			EndIf;
			If Data.Property("RunMode") Then
				Presentation = StartupModesPresentations.Get(Upper(Data.RunMode));
				If Presentation <> Undefined Then
					Data.RunMode = Presentation;
				EndIf;
			EndIf;
			If Data.Property("Language") Then
				Presentation = LangsPresentation.Get(Upper(Data.Language));
				If Presentation <> Undefined Then
					Data.Language = Presentation;
				EndIf;
			EndIf;
			If Data.Property("Roles") Then
				RolesNames = New Map;
				RolesList = New ValueList;
				For Each FullNameOfTheRole In Data.Roles Do
					RolesNames.Insert(Upper(FullNameOfTheRole), FullNameOfTheRole);
					Presentation = RolesPresentation.Get(Upper(FullNameOfTheRole));
					If Presentation = Undefined Then
						NameParts = StrSplit(FullNameOfTheRole, ".", False);
						Presentation = ?(NameParts.Count() = 2, NameParts[1], FullNameOfTheRole);
					EndIf;
					RolesList.Add(Presentation);
				EndDo;
				RolesList.SortByValue();
				Data.Roles = StrConcat(RolesList.UnloadValues(), Chars.LF);
				Data.Insert("RolesNames", RolesNames);
			EndIf;
			If Data.Property("SecondAuthenticationFactorSettingsProcessing") Then
				SettingsProcessing = Data.SecondAuthenticationFactorSettingsProcessing;
				If SettingsProcessing = "DontUse" Then
					Presentation = PresentationDoNotUse;
				ElsIf SettingsProcessing = "UseNextIfFailed" Then
					Presentation = PresentationUse;
				Else
					Presentation = "";
				EndIf;
				Data.SecondAuthenticationFactorSettingsProcessing = Presentation;
			EndIf;
			If Data.Property("SecondAuthenticationFactorSettings") Then
				If TypeOf(Data.SecondAuthenticationFactorSettings) = Type("Array") Then
					SettingsList = New Array;
					For Each Setting In Data.SecondAuthenticationFactorSettings Do
						SettingsList.Add(String(Setting));
					EndDo;
					Data.SecondAuthenticationFactorSettings = StrConcat(SettingsList, Chars.LF);
				Else
					Data.SecondAuthenticationFactorSettings = String(Data.SecondAuthenticationFactorSettings);
				EndIf;
			EndIf;
			If Data.Property("PasswordPolicyName")
			   And TypeOf(Data.PasswordPolicyName) = Type("Array") Then
				
				Data.PasswordPolicyName = StrConcat(Data.PasswordPolicyName, ", ");
			EndIf;
			
		Else // EventNameChangeAdditional
			EventKind = EventPresentationUpdate;
			Data = ExtendedChangeData(Event.Data);
			If Data = Undefined Then
				Continue;
			EndIf;
			If Not HasEventsWithoutID Then
				LastEvent = LastEvents.Get(Data.UUID);
			ElsIf ValueIsFilled(Data.Name) Then
				LastEvent = LastEvents.Get(Upper(Data.Name));
			Else
				Continue;
			EndIf;
			If LastEvent <> Undefined Then
				If LastEvent.Session = Event.Session
				   And Event.Date - LastEvent.Date >= -1
				   And Event.Date - LastEvent.Date <= 3 Then
					
					PropertiesNames = "Invalid, DeletionMark, UserMustChangePasswordOnAuthorization,
					|UnlimitedValidityPeriod, ValidityPeriod, InactivityPeriodBeforeDenyingAuthorization";
					
					FillPropertyValues(LastEvent, Data, PropertiesNames);
					CurrentProperties = New Structure(PropertiesNames);
					PreviousEvent = LastEvent.PreviousEvent;
					For Each KeyAndValue In CurrentProperties Do
						FieldName = KeyAndValue.Key;
						FieldName_Changed = FieldName + "_" + "IsChanged";
						LastEvent[FieldName_Changed] =
							?(PreviousEvent = Undefined Or PreviousEvent[FieldName_Changed] = 2,
								0, Number(PreviousEvent[FieldName] <> LastEvent[FieldName]));
					EndDo;
					
					Continue;
					
				EndIf;
			EndIf;
		EndIf;
		
		If FilterUsers <> Undefined
		   And FilterUsers.Get(Upper(Data.Name)) = Undefined Then
			Continue;
		EndIf;
		
		NewRow = Changes.Add();
		NewRow.PreviousEvent = LastEvent;
		
		FillPropertyValues(NewRow, Data);
		
		For Each KeyAndValue In UserProperties Do
			FieldName = KeyAndValue.Key;
			FieldName_Changed = KeyAndValue.Value;
			If TypeOf(FieldName_Changed) <> Type("String") Then
				Continue;
			EndIf;
			If Not Data.Property(FieldName) Then
				If LastEvent = Undefined
				 Or LastEvent[FieldName_Changed] = 2 Then
					NewRow[FieldName_Changed] = 2;
				Else
					NewRow[FieldName] = LastEvent[FieldName];
					NewRow[FieldName_Changed] = 0;
					If FieldName = "Roles" Then
						NewRow.RolesNames = LastEvent.RolesNames;
					EndIf;
				EndIf;
			ElsIf LastEvent = Undefined
				 Or LastEvent[FieldName_Changed] = 2 Then
				NewRow[FieldName_Changed] = 0;
			Else
				NewRow[FieldName_Changed] = Number(Data[FieldName] <> LastEvent[FieldName]);
				If NewRow[FieldName_Changed] And FieldName = "Roles" Then
					NewRow.RolesUpdatesOnly = ModifiedRoles(Data, LastEvent, RolesPresentation);
				EndIf;
			EndIf;
		EndDo;
		If Data.Property("UUID") Then
			NewRow.Id = Lower(Data.UUID);
			LastEvents.Insert(NewRow.Id, NewRow);
		EndIf;
		LastEvents.Insert(Upper(NewRow.Name), NewRow);
		
		NewRow.Date                  = Event.Date;
		NewRow.EventKind            = EventKind;
		NewRow.Author                 = Event.UserName;
		NewRow.AuthorID   = Event.User;
		NewRow.Application            = Event.ApplicationName;
		NewRow.Computer             = Event.Computer;
		NewRow.Session                 = Event.Session;
		NewRow[ConnectionColumnName] = Event[ConnectionColumnName];
	EndDo;
	
	Filter = New Structure("Id", "");
	Rows = Changes.FindRows(Filter);
	NameTable = Changes.Copy(Rows, "Name");
	NameTable.GroupBy("Name");
	Filter = New Structure("Name", "");
	For Each NameDescription In NameTable Do
		IBUser = InfoBaseUsers.FindByName(NameDescription.Name);
		If IBUser = Undefined Then
			Continue;
		EndIf;
		Id = Lower(IBUser.UUID);
		Filter.Name = NameDescription.Name;
		Rows = Changes.FindRows(Filter);
		For Each String In Rows Do
			String.Id = Id;
		EndDo;
	EndDo;
	
	IDsTable = Changes.Copy(, "Id");
	IDsTable.GroupBy("Id");
	IDs = New Array;
	For Each String In IDsTable Do
		If ValueIsFilled(String.Id) Then
			IDs.Add(New UUID(String.Id));
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("IDs", IDs);
	Query.Text =
	"SELECT
	|	Users.IBUserID AS Id,
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID IN(&IDs)
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.IBUserID,
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID IN(&IDs)";
	
	UsersProperties = Query.Execute().Unload();
	UsersProperties.Indexes.Add("Id");
	
	For Each String In Changes Do
		If ValueIsFilled(String.Id) Then
			UUID = New UUID(String.Id);
			Properties = UsersProperties.Find(UUID, "Id");
			If Properties = Undefined Then
				IBUser = InfoBaseUsers.FindByUUID(UUID);
				If IBUser = Undefined Then
					IBUser = InfoBaseUsers.FindByName(String.Name);
				EndIf;
				If IBUser <> Undefined Then
					String.Presentation = IBUser.FullName;
					Continue;
				EndIf;
			Else
				String.Presentation = Properties.Ref;
				If ValueIsFilled(String.Ref) Then
					String.Ref = Properties.Ref;
					String.Ref_IsChanged =
						?(String.PreviousEvent = Undefined Or String.PreviousEvent.Ref_IsChanged = 2,
							0, Number(String.PreviousEvent.Ref <> String.Ref));
				EndIf;
				Continue;
			EndIf;
		Else
			String.Id = String.Name;
		EndIf;
		If ValueIsFilled(String.FullName) Then
			String.Presentation = String.FullName;
		Else
			String.Presentation = String.Name;
		EndIf;
	EndDo;
	
	Changes.Columns.Delete("RolesNames");
	Changes.Columns.Delete("PreviousEvent");
	
	Return Changes;
	
EndFunction

Function ParameterValue(Settings, ParameterName, DefaultValue)
	
	Field = Settings.DataParameters.Items.Find(ParameterName);
	
	If Field <> Undefined And Field.Use Then
		Return Field.Value;
	EndIf;
	
	Return DefaultValue;
	
EndFunction

Function FilterUsers(SelectedValues)
	
	If SelectedValues = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(SelectedValues) = Type("ValueList") Then
		Values = SelectedValues.UnloadValues();
	Else
		Values = CommonClientServer.ValueInArray(SelectedValues);
	EndIf;
	
	TypeDescription = New TypeDescription("CatalogRef.Users,
		|CatalogRef.UserGroups,
		|CatalogRef.ExternalUsers,
		|CatalogRef.ExternalUsersGroups");
	
	Result = New Map;
	List = New Array;
	
	For Each Value In Values Do
		ValueType = TypeOf(Value);
		If TypeDescription.ContainsType(ValueType) Then
			List.Add(Value);
		ElsIf ValueType = Type("String") Then
			If StringFunctionsClientServer.IsUUID(Value) Then
				Result.Insert(Lower(Value), True);
				Id = New UUID(Value);
				IBUser = InfoBaseUsers.FindByUUID(Id);
				If IBUser = Undefined Then
					Continue;
				EndIf;
				Result.Insert(Upper(IBUser.Name), True);
			Else
				Result.Insert(Upper(Value), True);
			EndIf;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(List) Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("List", List);
	Query.Text =
	"SELECT
	|	UserGroupCompositions.User.IBUserID AS IBUserID
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.UsersGroup IN (&List)";
	
	Upload0 = Query.Execute().Unload();
	IBUsersIDs = Upload0.UnloadColumn("IBUserID");
	
	For Each Id In IBUsersIDs Do
		Result.Insert(Lower(Id), True);
		IBUser = InfoBaseUsers.FindByUUID(Id);
		If IBUser = Undefined Then
			Continue;
		EndIf;
		Result.Insert(Upper(IBUser.Name), True);
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  EventData - String
//
// Returns:
//  Structure:
//   * Ref - CatalogRef.Users
//            - CatalogRef.ExternalUsers
//   * Name    - String
//   * UUID - String - UUID in the lower case.
//   * Invalid - Boolean
//   * DeletionMark - Boolean
//   * UserMustChangePasswordOnAuthorization - Boolean
//   * UnlimitedValidityPeriod - Boolean
//   * ValidityPeriod - Date
//   * InactivityPeriodBeforeDenyingAuthorization - Number
//
Function ExtendedChangeData(EventData)
	
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
	
	VersionStorage = New Structure;
	VersionStorage.Insert("DataStructureVersion");
	FillPropertyValues(VersionStorage, Data);
	If VersionStorage.DataStructureVersion <> 1
	   And VersionStorage.DataStructureVersion <> 2 Then
		Return Undefined;
	EndIf;
	
	Location = New Structure;
	Location.Insert("RefType", "");
	Location.Insert("LinkID", "");
	Location.Insert("Name", "");
	Location.Insert("IBUserID", "");
	Location.Insert("Invalid", False);
	Location.Insert("DeletionMark", False);
	Location.Insert("UserMustChangePasswordOnAuthorization", False);
	Location.Insert("UnlimitedValidityPeriod", False);
	Location.Insert("ValidityPeriod", '00010101');
	Location.Insert("InactivityPeriodBeforeDenyingAuthorization", 0);
	
	For Each KeyAndValue In Location Do
		If Not Data.Property(KeyAndValue.Key)
		 Or TypeOf(Data[KeyAndValue.Key]) <> TypeOf(KeyAndValue.Value)
		   And Not (KeyAndValue.Key = "Name" And Data[KeyAndValue.Key] = Undefined)
		   And Not (KeyAndValue.Key = "IBUserID" And Data[KeyAndValue.Key] = Undefined)
		   And Not (KeyAndValue.Key = "Invalid" And Data[KeyAndValue.Key] = Undefined)
		   And Not (KeyAndValue.Key = "DeletionMark" And Data[KeyAndValue.Key] = Undefined) Then
			Return Undefined;
		EndIf;
	EndDo;
	
	If ValueIsFilled(Data.IBUserID)
	   And Not StringFunctionsClientServer.IsUUID(Data.IBUserID) Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Ref", Undefined);
	Result.Insert("Name", "");
	Result.Insert("UUID", "");
	Result.Insert("Invalid", False);
	Result.Insert("DeletionMark", False);
	Result.Insert("UserMustChangePasswordOnAuthorization", False);
	Result.Insert("UnlimitedValidityPeriod", False);
	Result.Insert("ValidityPeriod", '00010101');
	Result.Insert("InactivityPeriodBeforeDenyingAuthorization", 0);
	
	FillPropertyValues(Result, Data);
	Result.UUID = Lower(Data.IBUserID);
	
	If ValueIsFilled(Data.LinkID) Then
		If Not StringFunctionsClientServer.IsUUID(Data.LinkID) Then
			Return Undefined;
		EndIf;
		Id = New UUID(Data.LinkID);
		
		If Data.RefType = "Catalog.Users" Then
			Result.Ref = Catalogs.Users.GetRef(Id);
			
		ElsIf Data.RefType = "Catalog.ExternalUsers" Then
			Result.Ref = Catalogs.ExternalUsers.GetRef(Id);
		Else
			Return Undefined;
		EndIf;
	Else
		Result.Ref = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Function ModifiedRoles(Data, LastEvent, RolesPresentation)
	
	ModifiedRoles = New ValueList;
	
	For Each KeyAndValue In Data.RolesNames Do
		If LastEvent.RolesNames.Get(KeyAndValue.Key) = Undefined Then
			ModifiedRoles.Add("+", KeyAndValue.Value);
		EndIf;
	EndDo;
	
	For Each KeyAndValue In LastEvent.RolesNames Do
		If Data.RolesNames.Get(KeyAndValue.Key) = Undefined Then
			ModifiedRoles.Add("-", KeyAndValue.Value);
		EndIf;
	EndDo;
	
	For Each ListItem In ModifiedRoles Do
		FullNameOfTheRole = ListItem.Presentation;
		Presentation = RolesPresentation.Get(Upper(FullNameOfTheRole));
		If Presentation = Undefined Then
			NameParts = StrSplit(FullNameOfTheRole, ".", False);
			Presentation = ?(NameParts.Count() = 2, NameParts[1], FullNameOfTheRole);
		EndIf;
		ListItem.Value = ListItem.Value + Presentation;
		ListItem.Presentation = Presentation;
	EndDo;
	ModifiedRoles.SortByPresentation();
	
	Return StrConcat(ModifiedRoles.UnloadValues(), Chars.LF);
	
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