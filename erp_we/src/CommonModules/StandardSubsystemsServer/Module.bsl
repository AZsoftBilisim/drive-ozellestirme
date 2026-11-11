///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The call of this procedure should be placed in session module in the SessionParametersSetting
// procedure according to the documentation.
//
// Parameters:
//  SessionParametersNames - Array of String
//                        - Undefined - the session parameter names for initialization.
//                                         An array of the set IDs of session parameters
//                                         that should be initialized if the handler is called
//                                         before using uninitialized session parameters.
//                                         Undefined if event handler is called by the system on session start.
//
// Returns:
//  Array of String - session parameters names whose values were successfully set.
//
Function SessionParametersSetting(SessionParametersNames) Export
	
	// Session parameters that access the same data for initialization should be initialized as a batch.
	// To avoid re-initialization, the names of the initialized session parameters
	// are saved to the array "InitializedParameters".
	SpecifiedParameters = New Array;
	
#If Not MobileStandaloneServer Then
	
	If SessionParametersNames <> Undefined
	   And SessionParametersNames.Find("ClientParametersAtServer") <> Undefined Then
		
		SessionParameters.ClientParametersAtServer = New FixedMap(New Map);
		SpecifiedParameters.Add("ClientParametersAtServer");
		If SessionParametersNames.Count() = 1 Then
			Return SpecifiedParameters;
		EndIf;
	EndIf;
	
	If SessionParametersNames = Undefined Then
		If SessionParameters.ClientParametersAtServer.Count() = 0 Then
			BlankTheClientSettings = New Map;
			BlankTheClientSettings.Insert("TheFirstServerCallIsMade",
				?(CurrentRunMode() = Undefined, Undefined, False));
			BlankTheClientSettings.Insert("StateBeforeCallAuthenticateCurrentUser", True);
			SessionParameters.ClientParametersAtServer = New FixedMap(BlankTheClientSettings);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ModuleNationalLanguageSupportServer.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
		EndIf;
		
		Catalogs.ExtensionsVersions.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
		
		// When establishing the connections with the infobase before calling all other handlers.
		BeforeStartApplication();
		Return SpecifiedParameters;
	EndIf;
	
	Catalogs.MetadataObjectIDs.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
	
	If SessionParametersNames.Find("CachedDataKey") <> Undefined Then
		SessionParameters.CachedDataKey = New UUID;
		SpecifiedParameters.Add("CachedDataKey");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
	EndIf;
	
	Catalogs.ExtensionsVersions.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
	
	If SessionParametersNames.Find("Clipboard") <> Undefined Then
		SessionParameters.Clipboard = New FixedStructure(New Structure("Source, Data"));
		SpecifiedParameters.Add("Clipboard");
	EndIf;
	
	If AllSessionParametersAreSet(SessionParametersNames, SpecifiedParameters) Then
		Return SpecifiedParameters;
	EndIf;
	
	Handlers = New Map;
	SSLSubsystemsIntegration.OnAddSessionParameterSettingHandlers(Handlers);
	
	CustomHandlers = New Map;
	CommonOverridable.OnAddSessionParameterSettingHandlers(CustomHandlers);
	For Each Record In CustomHandlers Do
		Handlers.Insert(Record.Key, Record.Value);
	EndDo;
	
	ExecuteSessionParameterSettingHandlers(SessionParametersNames, Handlers, SpecifiedParameters);
	
	SSLSubsystemsIntegration.OnSetSessionParameters(SessionParametersNames);
	
#EndIf
	
	Return SpecifiedParameters;
	
EndFunction

#If Not MobileStandaloneServer Then

// Returns a flag that shows whether this is the basic configuration.
// The basic configuration versions may have application restrictions that
// can be enforced using this function.
// The configuration is considered basic if its name contains the term "Basic",
// for example, "TradeManagementBasic".
//
// Returns:
//   Boolean - True if this is the basic configuration.
//
Function IsBaseConfigurationVersion() Export
	
	IsBaseConfigurationVersion = StrFind(Upper(Metadata.Name), "BASIC") > 0;
	CommonOverridable.WhenDefiningAFeatureThisIsTheBasicVersionOfTheConfiguration(IsBaseConfigurationVersion);
	
	Return IsBaseConfigurationVersion;
	
EndFunction

// Returns the flag indicating whether this is the training version of 1C:Enterprise.
// Intended for the functions and procedures whose functionality
// is affected by the training version limitations.
//
// Returns:
//   Boolean - True if the code is executed on the training version of 1C:Enterprise.
//
Function IsTrainingPlatform() Export
	
	SetPrivilegedMode(True);
	CurrentUser = InfoBaseUsers.CurrentUser();

	Try
		OSUser = CurrentUser.OSUser;
	Except
		// The training version of 1C:Enterprise does not support obtaining the properties of OSUser.
		Return True;
	EndTry;
	Return False;
	
EndFunction

// Updates metadata property caches, which speed up
// session startup and infobase update, especially in the SaaS mode.
// They are updated before the infobase update.
//
// To be used in other libraries and configurations.
//
Procedure UpdateAllApplicationParameters() Export
	
	InformationRegisters.ApplicationRuntimeParameters.UpdateAllApplicationParameters();
	
EndProcedure

// Returns the Standard Subsystems Library version number (SSL)
// built in the configuration.
//
// Returns:
//  String - an SSL version, for example, "1.0.1.1".
//
Function LibraryVersion() Export
	
	Return StandardSubsystemsCached.SubsystemsDetails().ByNames["StandardSubsystems"].Version;
	
EndFunction

// Gets an infobase UUID
// that allows you to distinguish different instances of infobases,
// for example, when collecting statistics or in the mechanisms of the external management of databases.
// If the ID is not filled in, its value is set and returned automatically.
//
// The ID is stored in the InfobaseID constant.
// The InfobaseID constant cannot be included in the exchange plan contents in order to have
// the same value in each infobase (in DIB node).
//
// Returns:
//  String - infobase ID.
//
Function InfoBaseID() Export
	
	InfoBaseID = Constants.InfoBaseID.Get();
	
	If IsBlankString(InfoBaseID) Then
		InfoBaseID = String(New UUID());
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		Constants.InfoBaseID.Set(InfoBaseID);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	Return InfoBaseID;
	
EndFunction

// Returns the name of the security profile that should be set before executing
// the "Execute" or "Evaluate" methods, while preserving the current privileged mode
// and allowing privileged mode to be enabled in configuration code if necessary.
// If the executing code does not require privileged mode,
// it is recommended to use either Common.ExecuteInSafeMode or Common.CalculateInSafeMode, or
// to enable safe mode using the 1C:Enterprise method SetSafeMode(True).
// This is required to support security profile functionality (in CORP solutions).
//
// 
//
// Returns:
//  String - If empty, don't set the safe mode.
//
// Example:
//
//  Option 1. In the body of a routine.
//	…
//	
//	
//		InfobaseSecurityProfile = StandardSubsystemsServer.SecurityProfileForExecuteEvaluate();
//	If ValueIsFilled(InfobaseSecurityProfile) Then
//	SetSafeMode(InfobaseSecurityProfile);
//	EndIf;
//		Evaluate(
//	…)
//	If ValueIsFilled(InfobaseSecurityProfile) Then
//
//  SetSafeMode(False);
//	EndIf;
//	...
//	Option 2. Following the body of a routine.
//		...
//	InfobaseSecurityProfile = StandardSubsystemsServer.SecurityProfileForExecuteEvaluate();
//	If ValueIsFilled(InfobaseSecurityProfile) 
//	SetSafeMode(InfobaseSecurityProfile);
//  EndIf;
//  Evaluate(...)
//  EndProcedure
//
Function SecurityProfileForRunCalculate() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Return "";
	EndIf;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles()
	 Or ModuleSafeModeManager.SafeModeSet() Then
		Return "";
	EndIf;
	
	InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
	If ValueIsFilled(InfobaseProfile) Then
		SetSafeMode(InfobaseProfile);
		If SafeMode() = True Then
			Return "";
		EndIf;
	EndIf;
	
	Return InfobaseProfile;
	
EndFunction

// Returns the administration parameter saved in the infobase.
// Designed for using in the mechanisms that require
// the input of infobase and server cluster administration parameters.
// For example, infobase connection lock.
// See also: SetAdministrationParameters.
//
// Returns:
//  Structure - contains the properties of two structures
//              ClusterAdministrationClientServer.ClusterAdministrationParameters 
//              and ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//              In this case, fields containing passwords are returned empty. If administration parameters
//              were not saved using the SetAdministrationParameters function,
//              the automatically calculated administration parameters will be returned by default.
//
Function AdministrationParameters() Export
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
						|ru = 'Недостаточно прав для выполнения операции.';
						|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
						|it = 'Diritti insufficienti per eseguire l''operazione.';
						|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
						|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
		EndIf;
	Else
		If Not Users.IsFullUser(, True) Then
			Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
						|ru = 'Недостаточно прав для выполнения операции.';
						|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
						|it = 'Diritti insufficienti per eseguire l''operazione.';
						|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
						|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	IBAdministrationParameters = Constants.IBAdministrationParameters.Get().Get();
	DefaultAdministrationParameters = DefaultAdministrationParameters();
	
	If TypeOf(IBAdministrationParameters) = Type("Structure") Then
		FillPropertyValues(DefaultAdministrationParameters, IBAdministrationParameters);
	EndIf;
	IBAdministrationParameters = DefaultAdministrationParameters;
	
	If Not Common.FileInfobase() Then
		ReadParametersFromConnectionString(IBAdministrationParameters);
	EndIf;
	
	Return IBAdministrationParameters;
	
EndFunction

// Saves the infobase and server cluster administration parameters.
// When saving, the fields that contain passwords will be cleared for security reasons.
//
// Parameters:
//  IBAdministrationParameters - See AdministrationParameters
//
// Example:
//  AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
//  // Showing the administration parameters to the administrator to validate them and enter passwords.
//  // Next, executing actions related to connecting to the server cluster.
//  StandardSubsystemsServer.AdministrationParameters(AdministrationParameters);
//
Procedure SetAdministrationParameters(IBAdministrationParameters) Export
	
	UsersInternal.CheckIfSafeModeOff(
		"StandardSubsystemsServer.SetAdministrationParameters");
	
	IBAdministrationParameters.ClusterAdministratorPassword = "";
	IBAdministrationParameters.InfobaseAdministratorPassword = "";
	Constants.IBAdministrationParameters.Set(New ValueStorage(IBAdministrationParameters, New Deflation(9)));
	
EndProcedure

// Sets presentation of the Date field in the lists containing attribute with the Date and time date content.
// For more information, see the "The "Date" field in the lists" standard.
//
// Parameters:
//   Form - ClientApplicationForm - a form with a list.
//   FullAttributeName - String - a full path to the attribute of the Date type in the format: "<ListName>.<FieldName>".
//   TagName - String - a name of the form item associated with a list attribute of the Date type.
//
// Example:
//
//	Procedure OnCreateAtServer(Cancel, StandardProcessing)
//		StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
//
Procedure SetDateFieldConditionalAppearance(Form, 
	FullAttributeName = "List.Date", TagName = "Date") Export
	
	CommonClientServer.CheckParameter(
		"StandardSubsystemsServer.SetDateFieldConditionalAppearance",
		"ThisObject", 
		Form, 
		Type("ClientApplicationForm"));
	
	FullNameParts1 = StrSplit(FullAttributeName, ".");
	
	If FullNameParts1.Count() <> 2 Then 
		// Invalid name of "FullAttributeName" parameter.
		// Valid attribute name format is ""<ListName>.<FieldName>""'");
		Return;
	EndIf;
	
	ListName = FullNameParts1[0];
	AttributeList = Form[ListName];
	
	If TypeOf(AttributeList) = Type("DynamicList") Then 
		// "DynamicList" allows the setting of a conditional appearance using the built-in composer.
		// The "TagName" parameter is ignored as the dynamic list 
		// composer cannot know how the list attributes will be displayed. 
		// Therefore, the attribute path, filter value, and appearance value are the attribute name.
		ConditionalAppearance = AttributeList.ConditionalAppearance;
		AttributePath1 = FullNameParts1[1];
		FormattedFieldName = AttributePath1;
	Else 
		// The other lists (for example, "FormDataTree") don't have built-in composers.
		// Instead, they use the form's composer.
		ConditionalAppearance = Form.ConditionalAppearance;
		AttributePath1 = FullAttributeName;
		FormattedFieldName = TagName;
	EndIf;
	
	If Not ValueIsFilled(ConditionalAppearance.UserSettingID) Then
		ConditionalAppearance.UserSettingID = "MainAppearance";
	EndIf;
	
	// Date presentation.
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", "DLF=D");
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	// Today presentation of today.
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", NStr("vi = 'DF=HH:mm';
																|ru = 'ДФ=ЧЧ:мм';
																|en = 'DF=HH:mm'; fa = 'DF=HH:mm';
																|it = 'DF=HH:mm';
																|pl = 'DF=HH:mm';
																|tr = 'DF=HH:mm'"));
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.GreaterOrEqual;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.Less;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
EndProcedure

// Gets the setting to display a confirmation on application exit
// for the current user. Designed for using in the form of personal user
// settings.
// 
// Returns:
//   Boolean - if True, show the session closing confirmation
//            window upon application exit to the user.
// 
Function AskConfirmationOnExit() Export
	
	Result = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"AskConfirmationOnExit");
	
	If Result = Undefined Then
		Result = Common.CommonCoreParameters().AskConfirmationOnExit;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns details of tabular document saving formats.
//
// Returns:
//  ValueTable:
//   * SpreadsheetDocumentFileType - SpreadsheetDocumentFileType - a value that corresponds to the format;
//   * Ref - EnumRef.ReportSaveFormats      - a reference to metadata, where the presentation is stored;
//   * Presentation - String - a file type presentation (filled in from enumeration);
//   * Extension    - String - a file type for the operating system;
//   * Picture      - Picture - a picture of the format.
//
Function SpreadsheetDocumentSaveFormatsSettings() Export
	
	FormatsTable = New ValueTable;
	
	FormatsTable.Columns.Add("SpreadsheetDocumentFileType", New TypeDescription("SpreadsheetDocumentFileType"));
	FormatsTable.Columns.Add("Ref", New TypeDescription("EnumRef.ReportSaveFormats"));
	FormatsTable.Columns.Add("Presentation", New TypeDescription("String"));
	FormatsTable.Columns.Add("Extension", New TypeDescription("String"));
	FormatsTable.Columns.Add("Picture", New TypeDescription("Picture"));

	// PDF document (.pdf)
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = TableDocumentFileTypePDF();
	NewFormat.Ref = Enums.ReportSaveFormats.PDF;
	NewFormat.Extension = "pdf";
	NewFormat.Picture = PictureLib.PDFFormat;
	NewFormat.Presentation = FileTypeRepresentationOfATabularPDFDocument();
	
	StandardSubsystemsServerLocalization.OnSetupSpreadsheetSaveFormats(FormatsTable);
	
	// Spreadsheet document (.mxl)
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.MXL;
	NewFormat.Ref = Enums.ReportSaveFormats.MXL;
	NewFormat.Extension = "mxl";
	NewFormat.Picture = PictureLib.MXLFormat;
	
	// Microsoft Excel 2007 worksheet (.xlsx)
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.XLSX;
	NewFormat.Ref = Enums.ReportSaveFormats.XLSX;
	NewFormat.Extension = "xlsx";
	NewFormat.Picture = PictureLib.ExcelFormat2007;

	// Microsoft Excel 97-2003 worksheet (.xls)
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.XLS;
	NewFormat.Ref = Enums.ReportSaveFormats.XLS;
	NewFormat.Extension = "xls";
	NewFormat.Picture = PictureLib.ExcelFormat;

	// OpenDocument spreadsheet (.ods).
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.ODS;
	NewFormat.Ref = Enums.ReportSaveFormats.ODS;
	NewFormat.Extension = "ods";
	NewFormat.Picture = PictureLib.OpenOfficeCalcFormat;
	
	// Word 2007 document (.docx)
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.DOCX;
	NewFormat.Ref = Enums.ReportSaveFormats.DOCX;
	NewFormat.Extension = "docx";
	NewFormat.Picture = PictureLib.WordFormat2007;
	
	// Web page (.html).
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.HTML5;
	NewFormat.Ref = Enums.ReportSaveFormats.HTML;
	NewFormat.Extension = "html";
	NewFormat.Picture = PictureLib.HTMLFormat;
	
	// Text document, UTF-8 (.txt).
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.TXT;
	NewFormat.Ref = Enums.ReportSaveFormats.TXT;
	NewFormat.Extension = "txt";
	NewFormat.Picture = PictureLib.TXTFormat;
	
	// Text document, ANSI (.txt).
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.ANSITXT;
	NewFormat.Ref = Enums.ReportSaveFormats.ANSITXT;
	NewFormat.Extension = "txt";
	NewFormat.Picture = PictureLib.TXTFormat;
	
	For Each SaveFormat In FormatsTable Do
		If Not ValueIsFilled(SaveFormat.Presentation) Then
			SaveFormat.Presentation = String(SaveFormat.Ref);
		EndIf;
	EndDo;
		
	Return FormatsTable;
	
EndFunction

// Returns the compatibility mode version in the <Major>.<Minor>.<Revision>.<Build> format. For example: 8.3.15.0.
//
// Returns:
//   String - The compatibility mode version in the <Major>.<Minor>.<Revision>.<Build> format.
//
Function CompatibilityModeVersion() Export 
	
	If Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse Then 
		
		Information = New SystemInfo;
		Return Information.AppVersion;
		
	EndIf;
	
	CompatibilityModeDescription = StrSplit(Metadata.CompatibilityMode, "_");
	Symbols = StrLen(CompatibilityModeDescription[0]);
	
	EditionNumber = "";
	
	For CharacterNumber = 1 To Symbols Do 
		
		CurrentChar = Mid(CompatibilityModeDescription[0], CharacterNumber, 1);
		
		If StrFind("0123456789", CurrentChar) > 0 Then 
			EditionNumber = EditionNumber + CurrentChar;
		EndIf;
		
	EndDo;
	
	CompatibilityModeDescription.Set(0, EditionNumber);
	
	For IndexOf = CompatibilityModeDescription.Count() To 3 Do 
		CompatibilityModeDescription.Add("0");
	EndDo;
	
	Return StrConcat(CompatibilityModeDescription, ".");
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Web client does not support configurations that use interface v.8.2 anymore.
// When working in the web client, the ability to switch 
// between the interface of version 8.2 and the Taxi interface is disabled.
//
// Sets the bold font for form group titles so they are correctly displayed in the 8.2 interface.2.
// In the Taxi interface, group titles with standard highlight and without one are displayed in large font.
// In the 8.2 interface such titles are displayed as regular labels and are not associated with titles.
// This function is designed for visually highlighting (in bold) group titles in the interface v.8.2 mode.
//
// Parameters:
//  Form - ClientApplicationForm - a form where group title fonts are changed;
//  GroupNames - String - a list of the form group names separated with commas. If the group names are not specified,
//                        the appearance will be applied to all groups on the form.
//
// Example:
//  Procedure OnCreateAtServer(Cancel, StandardProcessing)
//    StandardSubsystemsServer.SetGroupsTitlesRepresentation(ThisObject);
//
Procedure SetGroupTitleRepresentation(Form, GroupNames = "") Export
	
	// Nothing is running.
	
EndProcedure

#EndRegion

// Returns the flag indicating whether toast notifications about installed
// application updates (dynamic update of the application, patches, and extensions) are shown.
//
// Returns:
//  Boolean - if True, toast notifications are enabled.
//
Function ShowInstalledApplicationUpdatesWarning() Export
	
	Return ShowWarningAboutInstalledUpdatesForUser();
	
EndFunction

#Region InterfaceImplementation

// Returns settings used during the static search for procedure and function names
// that are passed as parameters to procedures and functions described in the comments
// to the procedure OnDefineMethodsAllowedToBeCalledAsArbitraryCode.
// Used in the SSLImplementationsCheck.erf report to cover cases when
// subsystems allow passing full handler names as parameters,
// for example, session parameter setting handlers,
// infobase update handlers and others
// See also: OnSetUpValidationOfMethodsCalledAsArbitraryCode.
//
// Returns:
//  See CommonOverridable.OnSetUpValidationOfMethodsCalledAsArbitraryCode.Settings
//
Function CheckSettingsForMethodsCalledAsArbitraryCode() Export
	
	HandlersDetails = New ValueTable;
	HandlersDetails.Columns.Add("ProceduresNames",   New TypeDescription("Map"));
	HandlersDetails.Columns.Add("ErrorTitle", New TypeDescription("String"));
	
	CheckExceptions = New ValueTable;
	CheckExceptions.Columns.Add("FullObjectName",   New TypeDescription("String"));
	CheckExceptions.Columns.Add("ProcedureName",       New TypeDescription("String"));
	CheckExceptions.Columns.Add("ContentFragment", New TypeDescription("String"));
	
	Settings = New Structure;
	Settings.Insert("HandlersDetails", HandlersDetails);
	Settings.Insert("CheckExceptions",   CheckExceptions);
	Settings.Insert("SpecifiedMethodNotCalledError", True);
	Settings.Insert("ExclusionsWhenSpecifiedMethodNotCalled", New Map);
	
	SSLSubsystemsIntegration.OnSetUpValidationOfMethodsCalledAsArbitraryCode(Settings);
	Try
		CommonOverridable.OnSetUpValidationOfMethodsCalledAsArbitraryCode(Settings);
	Except
		ErrorInfo = ErrorInfo();
		IsProcedureSpecified = StrFind(ErrorProcessing.BriefErrorDescription(ErrorInfo),
			"(" + "OnSetUpValidationOfMethodsCalledAsArbitraryCode" + ")") = 0;
		If IsProcedureSpecified Then
			Raise;
		EndIf;
	EndTry;
	
	Return Settings;
	
EndFunction

// Populates the names of module procedures and functions that can be called by name
// as arbitrary code, or run in the background.
// Procedures and functions can be called by name as arbitrary code from:
// • Common.ExecuteConfigurationMethod,
// • Common.ExecuteObjectMethod.
// Procedures and functions can be run in the background from:
// • TimeConsumingOperations.ExecuteInBackground,
// • TimeConsumingOperations.ExecuteFunction,
// • TimeConsumingOperations.ExecuteProcedure,
// • TimeConsumingOperations.ExecuteFunctionInMultipleThreads,
// • TimeConsumingOperations.ExecuteProcedureInMultipleThreads
// • BackgroundJobs.Execute,
// • ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions,
// • ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions.
//
// Parameters:
//  Methods - Map of KeyAndValue:
//   * Key - String - The name of a procedure or function in the module.
//   * Value - Undefined, Boolean - if True, can be started in the background.
//
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("EnableConstantToDeliverServerAlertsWithoutInteractionSystem");
	Methods.Insert("MarkVersionCacheRecordsObsolete");
	Methods.Insert("SetIntegrationServicesLaunchSchedule");
	Methods.Insert("EnableConstantAllowAccessToInternetServices");
	Methods.Insert("SetConstantDoNotUseSeparationByDataAreas");
	Methods.Insert("CompareTables", True);
	
EndProcedure

// Adds a performance indicator to the handlers of the
// OnAddClientParametersOnStart and OnAddClientParameters events.
//
// Parameters:
//  Parameters - See CommonOverridable.OnAddClientParametersOnStart.Parameters
//            - See CommonOverridable.OnAddClientParameters.Parameters
//  StartMoment - Number - CurrentUniversalDateInMilliseconds before the procedure will be called.
//  ProcedureName - String - Full name of the called procedure
//
// Example:
//	StartMoment = CurrentUniversalDateInMilliseconds();
//	If Common.SubsystemExists("StandardSubsystems.InformationOnStart") Then
//		ModuleInformationOnStart = Common.CommonModule("InformationOnStart");
//		ModuleInformationOnStart.OnAddClientParametersOnStart(Parameters);
//	EndIf;
//	StandardSubsystemsClient.AddIndicator(Results, StartMoment,
//		"InformationOnStart.OnAddClientParametersOnStart");
//
Procedure AddIndicator(Parameters, StartMoment, ProcedureName) Export
	
	If TypeOf(Parameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Not Parameters.Property(PerformanceIndicatorsPropertyName()) Then
		Parameters.Insert(PerformanceIndicatorsPropertyName(), New Array);
	EndIf;
	
	Indicators = Parameters[PerformanceIndicatorsPropertyName()];
	AddMainIndicator(Indicators, StartMoment, ProcedureName);
	
EndProcedure

// Called from a scheduled job in order to send a server notification to client sessions.
// See also: StandardSubsystemsClient.OnReceiptServerNotification.
//
// It is called in the privileged mode considering the given period of the notification.
// See CommonOverridable.OnAddServerNotifications.
//
// Parameters:
//  NameOfAlert - String - See ServerNotifications.NewServerNotification.Name
//  ParametersVariants - Array of Structure:
//   * Parameters - Arbitrary - See ServerNotifications.NewServerNotification.Parameters
//   * Recipients - Map of KeyAndValue:
//      ** Key - UUID - Infobase user ID
//      ** Value - Array of See ServerNotifications.SessionKey
//
// Example:
//	If NotificationName <> "StandardSubsystems.UsersSessions.SessionsLock" Then
//		Return;
//	EndIf;
//	SessionLockParameters = SessionLockParameters(True);
//	If SessionLockParameters.Use Then
//		ServerNotifications.SendServerNotification(NotificationName,
//			SessionLockParameters, Undefined);
//	EndIf;
//
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	If NameOfAlert = "StandardSubsystems.Core.FunctionalOptionsModified" Then
		OnSendServerNotificationFunctionalOptionsModified(NameOfAlert, ParametersVariants);
	EndIf;
	
EndProcedure

// Returns True if the Disable Logic parameter is specified at startup to start the system's work.
//
// Returns:
//  Boolean
//
Function ApplicationStartupLogicDisabled() Export
	
	ApplicationStartupParameter = ClientParametersAtServer(False).Get("LaunchParameter");
	
	Return StrFind(ApplicationStartupParameter, "DisableSystemStartupLogic") > 0;
	
EndFunction

#EndRegion

#EndIf

#EndRegion

#If Not MobileStandaloneServer Then

#Region Internal

// Notifies all sessions that the cached values are outdated.
// 
// Parameters:
//  SendImmediately - See ServerNotifications.SendServerNotification.SendImmediately
//
Procedure NotifyAllSessionsAboutOutdatedCache(SendImmediately = False) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ServerNotifications.SendServerNotification(
		"StandardSubsystems.Core.CachedValuesOutdated",
		"",
		Undefined,
		SendImmediately);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Returns the versions supported by the "InterfaceName" API as specified in
// the procedures "OnDefineSupportedInterfaceVersions".
//
// Parameters:
//   InterfaceName - String - API name.
//
// Returns:
//  Array of String - List of versions.
//
Function SupportedVersionsOfAPI(InterfaceName) Export
	
	InterfaceVersions = Undefined;
	
	SupportedVersions = Common.InterfacesVersions();
	SupportedVersions.Property(InterfaceName, InterfaceVersions);
	
	If InterfaceVersions = Undefined Then
		InterfaceVersions = New Array();
	EndIf;
	
	Return InterfaceVersions;
	
EndFunction

#Region TechnicalSupport

// Returns main, system, and additional information for online support.
//
// The system information includes the server computer details.
// Client method: See StandardSubsystemsClient.SupportInformation.
//
// Example:
//  Demo configuration, version X.X, X.X.XX.XX
//   1C:Enterprise: X.X.XX.XXXX
//  Standart Subsystem Library: X.X.XX.XX
//
//  System info
//  OS: XXX
//  CPU: XXX
//  RAM: XXX
//  Application: XXX
//
//  Additional info
//  COM connector: XXX
//  Base configuration: No
//  Full-access user: No
//  Sandbox: No
//  Modified configuration: No
//
// Returns:
//  String - Information for technical support.
//
Function SupportInformation() Export
	
	SupportInformation = StandardSubsystemsClientServer.NewInfoForSupport();
	
	SystemInfo = New SystemInfo;
	FillPropertyValues(SupportInformation, SystemInfo);
	
	SupportInformation.ApplicationName1 = Metadata.DetailedInformation;
	SupportInformation.ApplicationVersion = Metadata.Version;
	SupportInformation.SSLVersion = LibraryVersion();
	SupportInformation.COMConnectorName = CommonClientServer.COMConnectorName();
	SupportInformation.IsBaseConfiguration = IsBaseConfigurationVersion();
	SupportInformation.IsFullUser = Users.IsFullUser();
	SupportInformation.IsTrainingPlatform = IsTrainingPlatform();
	SupportInformation.ConfigurationChanged = ConfigurationChanged();
	
	Return StandardSubsystemsClientServer.SupportInformationText(SupportInformation);
	
EndFunction

#EndRegion

#Region AdditionalBasicFunctionalityForAnalysingClientParametersAtServer

// Parameters:
//  RaiseException1 - Boolean - Call an exception if the parameters are not initialized.
//
// Returns a fixed map if CurrentRunMode() is "Undefined".
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String - LaunchParameter, InfobaseConnectionString
//   * Value - String
//
Function ClientParametersAtServer(RaiseException1 = True) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ClientParameters = SessionParameters.ClientParametersAtServer;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Not RaiseException1
	 Or CurrentRunMode() = Undefined
	   And ClientParameters.Get("TheFirstServerCallIsMade") = Undefined
	 Or ClientParameters.Get("TheFirstServerCallIsMade") = True Then
		
		Return ClientParameters;
	EndIf;
	
	If CurrentRunMode() <> Undefined Then
		// Reset the client caches used when accessing the client operating parameters
		// to repopulate the client parameters on the server side.
		RefreshReusableValues();
	EndIf;
	
	OnStart = ClientParameters.Get("TheFirstServerCallIsMade") = False;
	
	If OnStart Then
		CommentForTheLogWithoutACallStack = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Truy cập không hợp lệ đến các tham số chưa khởi tạo của client trên máy chủ.
			           |Có thể là, đã gọi ra trước khi hoàn thành khởi tạo trong %1.';
			           |ru = 'Недопустимое обращение к неинициализированным параметрам клиента на сервере.
			           |Вероятно, вызов выполнен преждевременно до завершения инициализации в %1.';
			           |en = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed before initialization was completed in %1.'; fa = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed before initialization was completed in %1.';
			           |it = 'Contatto non disponibile ai parametri non inizializzati del client su server.
			           |PRobabilmente, la chiamata è stata eseguita prima del completamento dell''inizializzazione in %1';
			           |pl = 'Niedopuszczalny zwrot do niezainicjowanych parametrów klienta na serwerze.
			           |Możliwe, że zostało wykonane przedwczesne wywołanie przed zakończeniem inicjacji w %1.';
			           |tr = 'Sunucudaki başlatılmamış istemci seçeneklerine geçersiz erişim.
			           |Muhtemelen, çağrı %1 içinde başlatma sonlandırılmadan gerçekleştirilmiştir.'",
			     Common.DefaultLanguageCode()),
			     "StandardSubsystemsClient.BeforeStart");
	Else
		CommentForTheLogWithoutACallStack = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Truy cập không hợp lệ đến các tham số chưa khởi tạo của client trên máy chủ.
			           |Có thể là đã gọi ra sau khi xóa không chính xác các tham số của phiên làm việc mà không sử dụng %2.';
			           |ru = 'Недопустимое обращение к неинициализированным параметрам клиента на сервере.
			           |Вероятно, вызван выполнен после некорректной очистки параметров сеанса без использования %2.';
			           |en = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed after session parameters were cleared incorrectly without using %2.'; fa = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed after session parameters were cleared incorrectly without using %2.';
			           |it = 'Contatto non disponibile ai parametri non inizializzati del client su server.
			           |Probabilmente, la chiamata è stata eseguita dopo la pulizia errata dei parametri di sessione senza utilizzo %2.';
			           |pl = 'Niedopuszczalny zwrot do niezainicjowanych parametrów klienta na serwerze.
			           |Możliwe, wywołanie zostało wykonane po niepoprawnym wyczyszczeniu parametrów sesji bez użycia %2.';
			           |tr = 'Sunucudaki başlatılmamış istemci seçeneklerine geçersiz erişim.
			           |Muhtemelen, çağrı %2 kullanılmadan oturum parametrelerinin yanlış temizlenmesinden sonra gerçekleştirilmiştir.'",
			     Common.DefaultLanguageCode()),
			     "Common.ClearSessionParameters");
	EndIf;
	
	Try
		Raise CommentForTheLogWithoutACallStack;
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	CommentWithCallStack = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	EventName = NStr("vi = 'Chưa điền tham số client trên máy chủ';
					|ru = 'Не заполнены параметры клиента на сервере';
					|en = 'The client parameters on the server are blank'; fa = 'The client parameters on the server are blank';
					|it = 'Non sono compilati i parametri del client sul server';
					|pl = 'Nie zostały wypełnione ustawienia klienta na serwerze';
					|tr = 'Sunucudaki istemci parametreleri girilmedi.'",
		Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName, EventLogLevel.Error,,, CommentWithCallStack);
	
	If Not OnStart Then
		ErrorText =
			NStr("vi = 'Chưa khởi tạo tham số client trên máy chủ.
			           |Để khởi tạo các tham số đó, hãy lặp lại thao tác hoặc khởi động lại phiên làm việc.';
			           |ru = 'Не инициализированы параметры клиента на сервере.
			           |Для их инициализации повторите действие или перезапустите сеанс.';
			           |en = 'Client parameters on the server are not initialized.
			           |To initialize them, retry the action or restart the session.'; fa = 'Client parameters on the server are not initialized.
			           |To initialize them, retry the action or restart the session.';
			           |it = 'Parametri client nel server non inizializzati. 
			           |Per l''inizializzazione, ripetere l''operazione o riavviare la sessione.';
			           |pl = 'Parametry klienta na serwerze nie są inicjalizowane.
			           |W celu ich inicjalizacji powtórz działanie lub uruchom ponownie sesję.';
			           |tr = 'Sunucudaki istemci parametreleri başlatılmadı.
			           |Başlatılmaları için işlemi tekrarlayın ya da oturumu yeniden başlatın.'");
		Raise ErrorText;
	EndIf;
	
	Return ClientParameters;
	
EndFunction

#EndRegion

#Region ProceduresToSetUpdateGetCacheAppOperationParameters

// Checks whether the latest version of the application is available
// in the current session, otherwise raises an exception with the requirement to restart the session.
//
// You cannot update the parameters of the application operation in previous sessions and also
// cannot change some data, so as not to overwrite
// the new version of the data (received using the new version of the application)
// with the previous version of the data (received using the previous version of the application).
//
Procedure CheckApplicationVersionDynamicUpdate() Export
	
	If ApplicationVersionUpdatedDynamically() Then
		RequireRestartDueToApplicationVersionDynamicUpdate();
	EndIf;
	
EndProcedure

// Checks whether there is the dynamic change of base configuration in the current session and
// there is no infobase update mode.
//
// Returns:
//  Boolean - True if the application version is updated.
//
Function ApplicationVersionUpdatedDynamically() Export
	
	If Not DataBaseConfigurationChangedDynamically() Then
		Return False;
	EndIf;
	
	// If the database configuration is changed dynamically while an
	// infobase update is running, keep updating despite the change.
	// 
	
	If Common.DataSeparationEnabled() Then
		// App operation parameters are always shared.
		// Therefore, they are updated if all shared data is updated.
		Return Not InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired();
	EndIf;
	
	Return Not InfobaseUpdate.InfobaseUpdateRequired();
	
EndFunction

// Raises an exception with a recommendation to restart a session due to an update of the application version.
Procedure RequireRestartDueToApplicationVersionDynamicUpdate() Export
	
	ErrorText = NStr("vi = 'Đã cập nhật phiên bản ứng dụng, cần khởi động lại phiên làm việc.';
					|ru = 'Версия приложения обновлена, требуется перезапустить сеанс.';
					|en = 'The app is updated. Restart the app.'; fa = 'The app is updated. Restart the app.';
					|it = 'Версия приложения обновлена, требуется перезапустить сеанс.';
					|pl = 'The app is updated. Restart the app.';
					|tr = 'Uygulamanın sürümü güncellendi. Oturum tekrar başlatılmalıdır.'");
	InstallRequiresSessionRestart(ErrorText);
	Raise ErrorText;
	
EndProcedure

// Raises an exception with a recommendation to restart a session due to an update of the application extension.
Procedure RequireSessionRestartDueToDynamicUpdateOfProgramExtensions() Export
	
	If StandardSubsystemsCached.IsSeparatedModeWithoutDataAreaExtensions() Then
		ErrorText =
			NStr("vi = 'Để thực hiện các thao tác cần thiết, cần
			           |khởi động phiên làm việc với các phần chia tách đã thiết lập.
			           |
			           |Phần mở rộng vùng dữ liệu không được kết nối khi đăng nhập
			           |trong vùng dữ liệu trong phiên làm việc đã khởi động mà không có phần chia tách.';
			           |ru = 'Для выполнения требуемых действий следует
			           |запустить сеанс с установленными разделителями.
			           |
			           |Расширения области данных не подключаются при входе
			           |в область данных в сеансе, запущенном без разделителей.';
			           |en = 'To perform the required actions,
			           |start a session with the specified separators.
			           |
			           |Data area extensions are not applied when you sign in to a data area in a session
			           |that is started without separators.'; fa = 'To perform the required actions,
			           |start a session with the specified separators.
			           |
			           |Data area extensions are not applied when you sign in to a data area in a session
			           |that is started without separators.';
			           |it = 'Per eseguire le azioni richieste è necessario
			           |avviare la sessione con i divisori impostati.
			           |
			           |Le estensioni dell''area dati non vengono collegate all''accesso
			           |nell''area dati nella sessione avviata senza divisori.';
			           |pl = 'Aby wykonać wymagane czynności należy
			           |uruchomić sesję z ustawionymi separatorami.
			           |
			           |Rozszerzenia obszaru danych nie są podłączane podczas wejścia
			           |do obszaru danych w sesji, uruchomionej bez separatorów.';
			           |tr = 'Gerekli işlemleri yürütmek için
			           |ayırıcıları ayarlı olan bir oturum başlatın.
			           |
			           |Ayırıcılar olmadan başlatılan bir oturumda bir veri alanına
			           |giriş yaparken veri alanı uzantıları bağlı değildir.'");
	Else
		ErrorText = NStr("vi = 'Đã cập nhật phần mở rộng ứng dụng, cần khởi động lại phiên làm việc.';
						|ru = 'Расширения приложения обновлены, требуется перезапустить сеанс.';
						|en = 'Extensions are updated. Restart the app.'; fa = 'Extensions are updated. Restart the app.';
						|it = 'Расширения приложения обновлены, требуется перезапустить сеанс.';
						|pl = 'Extensions are updated. Restart the app.';
						|tr = 'Uygulama uzantıları güncellendi, oturumu yeniden başlatın.'");
	EndIf;
	
	InstallRequiresSessionRestart(ErrorText);
	Raise ErrorText;
	
EndProcedure

// Returns:
//  Boolean
//
Function ThisIsSplitSessionModeWithNoDelimiters() Export
	
	If Not Common.DataSeparationEnabled()
	 Or Not Common.SeparatedDataUsageAvailable()
	 Or Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return False;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.SessionWithoutSeparators();
	
EndFunction

// Sets a session flag.
// The flag indicates whether to restart the session with the brief error details to check the attempt exception.
//
// Parameters:
//  BriefErrorDescription - String - Brief details of an error occurred when one of the procedures is called:
//   - RequireRestartDueToApplicationVersionDynamicUpdate
//   - RequireRestartDueToApplicationExtensionsDynamicUpdate
//
Procedure InstallRequiresSessionRestart(BriefErrorDescription) Export
	
	If CurrentRunMode() <> Undefined Then
		Return;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	If CurrentSession.ApplicationName <> "BackgroundJob" Then
		Return;
	EndIf;
	
	If SessionRestartRequired() Then
		Return;
	EndIf;
	
	CurrentParameters = New Structure(SessionParameters.InstalledExtensions);
	CurrentParameters.Insert("SessionRestartRequired", BriefErrorDescription);
	SessionParameters.InstalledExtensions = New FixedStructure(CurrentParameters);
	
EndProcedure

// Returns whether the SetSessionRestartRequired procedure was called. Returns brief error details specified at the procedure call.
// 
//
// Parameters:
//  BriefErrorDescription - String - Returnable value.
//    Set upon start of procedure SetSessionRestartRequired.
//
// Returns:
//  Boolean
//
Function SessionRestartRequired(BriefErrorDescription = "") Export
	
	If Not SessionParameters.InstalledExtensions.Property("SessionRestartRequired") Then
		Return False;
	EndIf;
	
	BriefErrorDescription = SessionParameters.InstalledExtensions.SessionRestartRequired;
	
	Return True;
	
EndFunction

// Checks if the caught exception is an error whose brief details start with
// the text specified during a call of procedure SetSessionRestartRequired.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Returns:
//  Boolean
//
Function ThisErrorRequirementRestartSession(ErrorInfo) Export
	
	ErrorText = "";
	If Not SessionRestartRequired(ErrorText) Then
		Return False;
	EndIf;
	
	Return TypeOf(ErrorInfo) = Type("ErrorInfo")
	      And ValueIsFilled(ErrorText)
	      And StrStartsWith(ErrorProcessing.BriefErrorDescription(ErrorInfo), ErrorText);
	
EndFunction

// Returns the value of the application parameter.
//
// In the previous session (when the application version is updated dynamically),
// if the parameter does not exist, an exception is thrown with a recommendation to restart,
// otherwise, the value is returned ignoring the version.
//
// In the separated SaaS mode, if the parameter does not exist
// or the parameter version is not equal to the configuration version, an exception is thrown
// as the shared data cannot be updated.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
// Returns:
//  Arbitrary - Undefined is returned when the parameter does not exist
//                 or when in the new session, the parameter version is not equal to the configuration version.
//
Function ApplicationParameter(ParameterName) Export
	
	Return InformationRegisters.ApplicationRuntimeParameters.ApplicationParameter(ParameterName);
	
EndFunction

// Sets the value of the application operation parameter.
// You have to set the privileged mode before the procedure call.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  Value     - Arbitrary - a value that can be put in a value storage.
//
Procedure SetApplicationParameter(ParameterName, Value) Export
	
	InformationRegisters.ApplicationRuntimeParameters.SetApplicationParameter(ParameterName, Value);
	
EndProcedure

// Updates the value of the application operation parameter, if it has changed.
// You have to set the privileged mode before the procedure call.
//
// Parameters:
//  ParameterName   - String - must not exceed 128 characters. For example,
//                   StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  Value       - Arbitrary - a value that can be put in a value storage.
//
//  HasChanges  - Boolean - a return value. It is set to True
//                   if a previous and a new parameter values do not match.
//
//  PreviousValue2 - Arbitrary - a return value. Before an update.
//
Procedure UpdateApplicationParameter(ParameterName, Value, HasChanges = False, PreviousValue2 = Undefined) Export
	
	InformationRegisters.ApplicationRuntimeParameters.UpdateApplicationParameter(ParameterName,
		Value, HasChanges, PreviousValue2);
	
EndProcedure

// Deletes the row containing the parameter.
// Set the privileged mode before the procedure call.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  HasChanges  - Boolean - a return value. It is set to True
//                   if a previous and a new parameter values do not match.
//
Procedure DeleteApplicationOperationParameter(ParameterName, HasChanges = False) Export
	
	InformationRegisters.ApplicationRuntimeParameters.DeleteApplicationOperationParameter(ParameterName, HasChanges);
	
EndProcedure

// Returns application parameter changes according to the current configuration
// version and the current infobase version.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
// Returns:
//  Undefined - means everything changed. Is returned
//                 in case of initial infobase or data area filling.
//  Array - contains values of changes. If the array is empty, there are no changes.
//                 Can contain several changes, for example, when data area has not been updated for a long time.
//
Function ApplicationParameterChanges(ParameterName) Export
	
	Return InformationRegisters.ApplicationRuntimeParameters.ApplicationParameterChanges(ParameterName);
	
EndFunction

// Add the changes of the application operation parameter during update to the current version of configuration metadata.
// Later changes are used for conditional adding of mandatory update handlers.
// In case of initial infobase or shared data filling, changes are not added.
// 
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  Changes    - Arbitrary - fixed data that is registered as changes.
//                 Changes are not added if the value of ParameterChange is not filled.
//
Procedure AddApplicationParameterChanges(ParameterName, Changes) Export
	
	InformationRegisters.ApplicationRuntimeParameters.AddApplicationParameterChanges(ParameterName, Changes);
	
EndProcedure

// For internal use only.
Procedure RegisterPriorityDataChangeForSubordinateDIBNodes() Export
	
	If Common.IsSubordinateDIBNode()
	 Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
		Catalogs.MetadataObjectIDs.RegisterTotalChangeForSubordinateDIBNodes();
	EndIf;
	
	DIBExchangePlansNodes = New Map;
	For Each ExchangePlan In Metadata.ExchangePlans Do
		If Not ExchangePlan.DistributedInfoBase Then
			Continue;
		EndIf;
		DIBNodes = New Array;
		DIBExchangePlansNodes.Insert(ExchangePlan.Content, DIBNodes);
		ExchangePlanManager = Common.ObjectManagerByFullName(ExchangePlan.FullName());
		Selection = ExchangePlanManager.Select();
		While Selection.Next() Do
			If Selection.Ref <> ExchangePlanManager.ThisNode() Then
				DIBNodes.Add(Selection.Ref);
			EndIf;
		EndDo;
	EndDo;
	
	If DIBExchangePlansNodes.Count() > 0 Then
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.Catalogs);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfCharacteristicTypes);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfAccounts);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfCalculationTypes);
	EndIf;
	
EndProcedure

// Creates the missing predefined items with new references (UUID) in all lists.
// For a call after disconnecting a subordinate node of the DIB from the main one, or for automatic recovery of 
// missing predefined items.
//
Procedure RestorePredefinedItems() Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Raise 
			NStr("vi = 'Chỉ cần khôi phục các phần tử định trước trong nút chính của CSTTPT.
			           |Sau đó thực hiện đồng bộ với các nút phụ.';
			           |ru = 'Восстановление предопределенных элементов следует выполнять только в главном узле РИБ.
			           |Затем выполнить синхронизацию с подчиненными узлами.';
			           |en = 'Restore the predefined items in the master node of the distributed infobase.
			           |Then synchronize the other nodes with the master node.'; fa = 'Restore the predefined items in the master node of the distributed infobase.
			           |Then synchronize the other nodes with the master node.';
			           |it = 'Il ripristino degli elementi di default dovrebbe essere effettuato solo nel nodo principale del database informatico distribuito.
			           |Dopo di chè effettuare una sincronizzazione con i nodi subordinati.';
			           |pl = 'Przywracanie predefiniowanych elementów należy wykonywać tylko w głównym węźle RBI.
			           |Następnie zsynchronizować z podrzędnymi węzłami.';
			           |tr = 'Önceden tanımlanmış öğeler sadece RIB ana ünitesinde yenilenmelidir. 
			           | Sonra alt üniteler ile senkronizasyon yapılmalıdır.'");
	EndIf;
	
	MetadataObjects = MetadataObjectsOfAllPredefinedData();
	Block = New DataLock;
	For Each MetadataObject In MetadataObjects Do
		Block.Add(MetadataObject.FullName());
	EndDo;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		SetAllPredefinedDataInitialization(MetadataObjects);
		CreateMissingPredefinedData(MetadataObjects);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function PredefinedDataAttributes() Export
	Result = New Structure;
	Result.Insert("PredefinedDataName",  "");
	Result.Insert("PredefinedSetName", "");
	Result.Insert("PredefinedKindName",   "");
	Result.Insert("PredefinedFolderType",   Undefined);
	Return Result;
EndFunction

Function ThisIsPredefinedData(Val Item, AttributeName = "", AttributeValue = "") Export // ACC:581 - An export function for auto-testing purposes.
	
	// For the subsystems "Properties", "ContactInformation", and "Interactions", to define predefined items,
	// read the following attributes: "PredefinedSetName", "PredefinedKindName", "PredefinedFolderType".
	AttributesValues = PredefinedDataAttributes();
	FillPropertyValues(AttributesValues, Item);
	If AttributesValues.PredefinedDataName = ""
		And AttributesValues.PredefinedSetName = ""
		And AttributesValues.PredefinedKindName = ""
		And Not ValueIsFilled(AttributesValues.PredefinedFolderType) Then
		Return False;
	EndIf;

	AttributeName = "";
	If AttributesValues.PredefinedSetName <> "" Then
		AttributeName = "PredefinedSetName";
	ElsIf AttributesValues.PredefinedKindName <> "" Then
		AttributeName = "PredefinedKindName";
	ElsIf ValueIsFilled(AttributesValues.PredefinedFolderType) Then
		AttributeName = "PredefinedFolderType";
	Else
		AttributeName = "PredefinedDataName";
	EndIf;
	AttributeValue = AttributesValues[AttributeName];
	
	Return True;
	
EndFunction

// Parameters:
//  References - Array of AnyRef
//         - FixedArray of AnyRef - References to objects.
//           If the array is blank, a blank map is returned.
//  Attributes - Array of String
//            - FixedArray of String - Attribute names formatted according to structure property requirements.
//            - String - Comma-delimited attribute names
//
// Returns:
//  Map of KeyAndValue - List of objects and their attribute values:
//   * Key - AnyRef - object reference;
//   * Value - Structure:
//    ** Key - String - an attribute name;
//    ** Value - Arbitrary - Attribute value. "Undefined" if the object does not have this attribute.
// 
Function ObjectAttributeValuesIfExist(References, Val Attributes) Export
	
	AttributesValues = New Map;
	If References.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	If TypeOf(Attributes) = Type("String") Then
		Attributes = StrSplit(Attributes, ",");
	EndIf;
	
	TypesAttributes = New Map;
	RefsByTypes = New Map;
	For Each Ref In References Do
		Type = TypeOf(Ref);
		If Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		
		If RefsByTypes[Type] = Undefined Then
			RefsByTypes[Type] = New Array;
		EndIf;
		ItemByType = RefsByTypes[Type]; // Array
		ItemByType.Add(Ref);
		
		If TypesAttributes[Type] = Undefined Then
			
			MetadataObject = Metadata.FindByType(Type); // MetadataObjectCatalog
			If MetadataObject = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sai tham số đầu tiên %1 trong hàm %2: 
						|Giá trị mảng phải là tham chiếu.';
						|ru = 'Неверный первый параметр %1 в функции %2: 
						|Значения массива должны быть ссылками.';
						|en = 'Invalid value of the %1 parameter, function %2:
						|The array values must be references.'; fa = 'Invalid value of the %1 parameter, function %2:
						|The array values must be references.';
						|it = 'Tipo errato di primo parametro %1 nella funzione %2: 
						|I valori della matrice devono essere collegamenti.';
						|pl = 'Nieprawidłowy pierwszy parametr %1 w funkcji %2: 
						|Wartości masywu powinny być odnośnikami.';
						|tr = '%2 işlevinde geçersiz ilk %1parametre: 
						|Dizin değerleri bağlantı olmalıdır.'"), 
					"References", "Common.ObjectAttributeValuesIfExist");
			EndIf;
			AttributesOfType = New Array;
			StandardAttributes = New Map;
			For Each StandardAttribute In MetadataObject.StandardAttributes Do
				StandardAttributes[StandardAttribute.Name] = True;	
			EndDo;
			StandardAttributes["DataVersion"] = True;

			For Each AttributeName In Attributes Do
				If StandardAttributes[AttributeName] <> Undefined 
					Or MetadataObject.Attributes.Find(AttributeName) <> Undefined Then
					AttributesOfType.Add(AttributeName);
				Else
					AttributesOfType.Add("UNDEFINED AS" + " " + AttributeName); // @query-part
				EndIf;
			EndDo;
			TypesAttributes[Type] = AttributesOfType;
			
		EndIf;
	EndDo;
	
	
	If RefsByTypes.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	QueriesTexts = New Array;
	Query = New Query;
	
	For Each RefsByType In RefsByTypes Do
		Type = RefsByType.Key;
		MetadataObject = Metadata.FindByType(Type);
		FullMetadataObjectName = MetadataObject.FullName();

		QueryText =
			"SELECT ALLOWED
			|	Ref,
			|	&Attributes
			|FROM
			|	&FullMetadataObjectName AS SpecifiedTableAlias
			|WHERE
			|	SpecifiedTableAlias.Ref IN (&References)";
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "ALLOWED", ""); // @query-part-1
		EndIf;
		AttributesQueryText = StrConcat(TypesAttributes[Type], ",");
		QueryText = StrReplace(QueryText, "&Attributes", AttributesQueryText);
		QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
		ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
		QueryText = StrReplace(QueryText, "&References", "&" + ParameterName); // @query-part-1
		Query.SetParameter(ParameterName, RefsByType.Value);

		QueriesTexts.Add(QueryText);
	EndDo;
	
	AttributesNames = StrConcat(Attributes, ",");
	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF); // @query-part
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result = New Structure(AttributesNames);
		FillPropertyValues(Result, Selection);
		AttributesValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributesValues;
	
EndFunction

#EndRegion

#Region ProceduresToSetGetCacheExtensionsParameters

// Returns the parameter values for the current extension version.
// Returns Undefined if no storage is set.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//  
//  IgnoreExtensionsVersion - Boolean
//  
//  IsAlreadyModified - Boolean - Return value. It is set to True, if IgnoreExtensionsVersion is True,
//                 the value in the value storage is not "Undefined", and
//                 the value was set by an earlier session.
//                 
//             - Undefined - No need to set a value.
//
// Returns:
//  Arbitrary - Undefined is returned if the parameter is not filled
//                 for current the extension version.
//
Function ExtensionParameter(ParameterName, IgnoreExtensionsVersion = False, IsAlreadyModified = Undefined) Export
	
	Return InformationRegisters.ExtensionVersionParameters.ExtensionParameter(ParameterName,
		IgnoreExtensionsVersion, IsAlreadyModified);
	
EndFunction

// Sets parameter value storage for the current extension version.
// Used to fill parameter values.
// You have to set the privileged mode before the procedure call.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  Value     - Arbitrary - a parameter value.
//  IgnoreExtensionsVersion - Boolean
//
Procedure SetExtensionParameter(ParameterName, Value, IgnoreExtensionsVersion = False) Export
	
	InformationRegisters.ExtensionVersionParameters.SetExtensionParameter(ParameterName,
		Value, IgnoreExtensionsVersion);
	
EndProcedure

// Deletes the row containing the parameter for the current extension version.
// Set the privileged mode before the procedure call.
//
// Parameters:
//  ParameterName - String - must not exceed 128 characters. For example,
//                 StandardSubsystems.ReportsOptions.ReportsWithSettings.
//
//  IgnoreExtensionsVersion - Boolean
//                           - Undefined - Delete all rows containing the parameter name.
//
//  HasChanges  - Boolean - a return value. It is set to True
//                   if a previous and a new parameter values do not match.
//
Procedure DeleteExtensionParameter(ParameterName, IgnoreExtensionsVersion = False, HasChanges = False) Export
	
	InformationRegisters.ExtensionVersionParameters.DeleteExtensionParameter(ParameterName,
		IgnoreExtensionsVersion, HasChanges);
	
EndProcedure

// DeleteObsoleteExtensionsVersionsParameters scheduled job handler.
Procedure DeleteObsoleteExtensionsVersionsParametersJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters);
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.DeleteObsoleteParametersVersions();
	
EndProcedure

// The handler of the FillExtensionsOperationParameters scheduled job.
//
// The job must be started right after it is enabled.
// The job is auto-disabled after a successful execution.
//
Procedure FillExtensionsOperationParameters() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.FillExtensionsOperationParameters);
	
	SetPrivilegedMode(True);
	InformationRegisters.ExtensionVersionParameters.FillinAllJobParametersLatestVersionExtensions();
	InformationRegisters.ExtensionProperties.DeletePropertiesOfDeletedExtensions();
	
EndProcedure

// Intended for internal usage only (a background job procedure).
Procedure FillAllExtensionParametersBackgroundJob(Parameters) Export
	
	InformationRegisters.ExtensionVersionParameters.FillAllExtensionParametersBackgroundJob(Parameters);
	
EndProcedure

// Intended for internal usage only (a background job procedure).
Procedure AddNewExtensionVersion(ExtensionsDetails) Export
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.AddNewExtensionVersion(ExtensionsDetails);
	
EndProcedure

// Intended for internal usage only (a background job procedure).
Procedure UpdateExtensionsVersionLastUsedDate(ExtensionsVersion) Export
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.UpdateExtensionsVersionLastUsedDate(ExtensionsVersion);
	
EndProcedure

// Intended for internal usage only (a background job procedure).
Procedure InstallLatestExtensionVersions(ExtensionsVersion) Export
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.InstallLatestExtensionVersions(ExtensionsVersion);
	
EndProcedure

#EndRegion

#Region AdditionalBasicFunctionalityForDataExchange

// Records changes of the object for all exchange plan nodes.
// The separated configurations must meet the following conditions:
//  - Exchange plan should be separated,
//  - Object to be registered should be shared.
//
//  Parameters:
//    Object         - CatalogObject
//                   - DocumentObject
//                   - BusinessProcessObject
//                   - TaskObject
//                   - ChartOfCalculationTypesObject
//                   - ChartOfCharacteristicTypesObject
//                   - ChartOfAccountsObject
//                   - ExchangePlanObject
//
//    ExchangePlanName - String - a name of the exchange plan where the object is registered in all nodes.
//                              The exchange plan must be shared, otherwise an exception is raised.
//
//    IncludeMasterNode - Boolean - If False, registration of the master node
//                         will not be performed in the subordinate node.
// 
//
Procedure RecordObjectChangesInAllNodes(Val Object, Val ExchangePlanName, Val IncludeMasterNode = True) Export
	
	If Metadata.ExchangePlans[ExchangePlanName].Content.Find(Object.Metadata()) = Undefined Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SeparatedDataUsageAvailable() Then
			Raise NStr("vi = 'Ghi nhận các thay đổi của dữ liệu chưa chia tách ở chế độ chia tách.';
						|ru = 'Регистрация изменений неразделенных данных в разделенном режиме.';
						|en = 'Registering changes of shared data in separated mode.'; fa = 'Registering changes of shared data in separated mode.';
						|it = 'Registrazione delle modifiche dei dati non condivisi in modalità condivisa.';
						|pl = 'Rejestracja zmian niepodzielonych danych w trybie rozdzielonym.';
						|tr = 'Bölünmüş modda paylaşılan verilerin kayıtlarını değiştirir.'");
		EndIf;
		
		ModuleSaaSOperations = Undefined;
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		EndIf;
		
		If ModuleSaaSOperations <> Undefined Then
			IsSeparatedExchangePlan = ModuleSaaSOperations.IsSeparatedMetadataObject(
				"ExchangePlan." + ExchangePlanName, ModuleSaaSOperations.MainDataSeparator());
		Else
			IsSeparatedExchangePlan = False;
		EndIf;
		
		If Not IsSeparatedExchangePlan Then
			Raise NStr("vi = 'Không hỗ trợ ghi nhận thay đổi cho các sơ đồ trao đổi không chia tách.';
						|ru = 'Регистрация изменений для неразделенных планов обмена не поддерживается.';
						|en = 'Shared exchange plans don''t support registration of changes.'; fa = 'Shared exchange plans don''t support registration of changes.';
						|it = 'La registrazione delle modifiche per i piani di scambio non condivisi non è supportata.';
						|pl = 'Rejestracja zmian dla niepodzielonych planów wymiany nie jest obsługiwana.';
						|tr = 'Bölünmemiş değişim planları için değişiklik kaydı desteklenmemektedir.'");
		EndIf;
		
		If ModuleSaaSOperations <> Undefined Then
			IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(
				Object.Metadata().FullName(), ModuleSaaSOperations.MainDataSeparator());
		Else
			IsSeparatedMetadataObject = False;
		EndIf;
		
		If IsSeparatedMetadataObject Then
				Raise NStr("vi = 'Không hỗ trợ ghi nhận thay đổi đối với đối tượng chia tách.';
							|ru = 'Регистрация изменений для разделенных объектов не поддерживается.';
							|en = 'Separated objects don''t support change registration.'; fa = 'Separated objects don''t support change registration.';
							|it = 'La registrazione delle modifiche per gli oggetti separati non è supportata.';
							|pl = 'Rejestracja zmian dla rozdzielonych elementów nie jest obsługiwana.';
							|tr = 'Bölünmemiş nesneler için değişiklik kaydı desteklenmemektedir.'");
		EndIf;
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	#ExchangePlanTable AS ExchangePlan
		|WHERE
		|	ExchangePlan.RegisterChanges
		|	AND NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		For Each Recipient In Recipients Do
			
			Object.DataExchange.Recipients.Add(Recipient);
			
		EndDo;
		
	Else
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	#ExchangePlanTable AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		MasterNode = ExchangePlans.MasterNode();
		
		For Each Recipient In Recipients Do
			If Not IncludeMasterNode And Recipient = MasterNode Then
				Continue;
			EndIf;
			Object.DataExchange.Recipients.Add(Recipient);
		EndDo;
		
	EndIf;
	
EndProcedure

// Saves the reference to master node in the MasterNode constant for recovery opportunity.
Procedure SaveMasterNode() Export
	
	MasterNodeManager = Constants.MasterNode.CreateValueManager();
	MasterNodeManager.Value = ExchangePlans.MasterNode();
	InfobaseUpdate.WriteData(MasterNodeManager);
	
EndProcedure

#EndRegion

#Region DataSendAndReceiveHandlersForExchangeInDIB

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// For parameters, see the OnSendDataToSlave event handler in Syntax Assistant.
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  InitialImageCreating - Boolean
//  Recipient - ExchangePlanObject
// 
Procedure OnSendDataToSlave(DataElement, ItemSend, Val InitialImageCreating, Val Recipient) Export
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Metadata object IDs are sent in another exchange message section.
	IgnoreSendingMetadataObjectIDs(DataElement, ItemSend, InitialImageCreating);
	IgnoreSendingDataProcessedOnMasterDIBNodeOnInfobaseUpdate(DataElement, InitialImageCreating, Recipient);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// Adding data exchange subsystem script first.
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnSendDataToRecipient(DataElement, ItemSend, InitialImageCreating, Recipient, False);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
	If TypeOf(DataElement) = Type("ConstantValueManager.AllowAccessToInternetServices") Then
		If Not InitialImageCreating Then
			ItemSend = DataItemSend.Ignore;
		EndIf;
	EndIf;
	
	SSLSubsystemsIntegration.OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// The insertion of the Data exchange SaaS subsystem code should be the last to affect the sending logic.
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataExportPercentage(Recipient, InitialImageCreating);
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// For parameters, see the OnReceiveDataFromSlave event handler in Syntax Assistant.
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//  Sender - ExchangePlanObject
// 
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Val Sender) Export
	
	// Metadata object IDs can be changes only in the master node.
	IgnoreGettingMetadataObjectIDs(DataElement, ItemReceive);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	SSLSubsystemsIntegration.OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender);
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// Calling an overridden handler to execute the applied logic of DIB exchange.
	CommonOverridable.OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender);
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// The insertion of the Data exchange subsystem code should be the last to affect the receiving logic.
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromSlaveInEnd(DataElement, ItemReceive, Sender);
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataImportPercentage(Sender);
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// See the OnReceiveDataFromMaster event handler in Syntax Assistant.
// "Sender" can be empty. For example, when getting the initial image message in a SWS.
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//  Sender - ExchangePlanObject
//
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender = Undefined) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// Adding data exchange subsystem script first.
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromMasterInBeginning(DataElement, ItemReceive, SendBack, Sender);
		
		If ItemReceive = DataItemReceive.Ignore Then
			Return;
		EndIf;
		
	EndIf;
	
	SSLSubsystemsIntegration.OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender);
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// Calling an overridden handler to execute the applied logic of DIB exchange.
	CommonOverridable.OnReceiveDataFromMaster(Sender, DataElement, ItemReceive, SendBack);
	
	// The insertion of the Data exchange subsystem code should be the last to affect the receiving logic.
	If DataExchangeSubsystemExists1
		And Not InitialImageCreating(DataElement) Then
		
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromMasterInEnd(DataElement, ItemReceive, Sender);
		
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataImportPercentage(Sender);
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalFunctionsForTypeManagement

// Returns the reference type or the record key type of the specified metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - A register or reference object.
//
//  Returns:
//   Type
//
Function MetadataObjectReferenceOrMetadataObjectRecordKeyType(MetadataObject) Export
	
	If Common.IsRegister(MetadataObject) Then
		
		If Common.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf Common.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf Common.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf Common.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordKey." + MetadataObject.Name);
	Else
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Type = TypeOf(Manager.EmptyRef());
	EndIf;
	
	Return Type;
	
EndFunction

// Returns the object type or the record set type of the specified metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - A register or reference object.
//
//  Returns:
//   Type
//
Function MetadataObjectOrMetadataObjectRecordSetType(MetadataObject) Export
	
	If Common.IsRegister(MetadataObject) Then
		
		If Common.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf Common.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf Common.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf Common.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordSet." + MetadataObject.Name);
	Else
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		ObjectKind = Common.ObjectKindByType(TypeOf(Manager.EmptyRef()));
		Type = Type(ObjectKind + "Object." + MetadataObject.Name);
	EndIf;
	
	Return Type;
	
EndFunction

// Checks whether the passed object has the CatalogObject.MetadataObjectIDs type.
//
// Parameters:
//  Object - Arbitrary
// 
// Returns:
//  Boolean
//
Function IsMetadataObjectID(Object) Export
	
	Return TypeOf(Object) = Type("CatalogObject.MetadataObjectIDs");
	
EndFunction

// Returns the details of key fields and record set row fields
// used in the "RefreshEnabled", "Join", and "Delete" modes.
//
// Parameters:
//  FullRegisterName - String - a full register name.
//
// Returns:
//  FixedStructure:
//   * FieldList - String - List of comma-delimited fields belonging to the record key.
//   * ListOfUpdateFields - String - List of comma-delimited fields belonging to the record set row
//       (RefreshEnabled, Join, Delete).
//   * FieldsDetails - FixedArray of FixedStructure:
//      ** Name - String - Name of the record key field.
//      ** Type - TypeDescription
//      ** Presentation - String
//   * DetailsOfUpdateFields - FixedArray of FixedStructure:
//      ** Name - String - Name of the key field belonging to the record set row.
//      ** Type - TypeDescription
//      ** Presentation - String
//
Function RecordKeyDetails(FullRegisterName) Export
	
	Return StandardSubsystemsCached.RecordKeyDetails(FullRegisterName);
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithForms

// Sets the form purpose key (the purpose use key and
// the window options key). If necessary, it copies the current form settings
// if they were not recorded for the new associated key.
//
// Parameters:
//  Form - ClientApplicationForm - the OnCreateAtServer form for which a key is set.
//  Var_Key  - String - a new form assignment key.
//  LocationKey - String
//  SetSettings - Boolean - set settings saved for the current key to the new one.
//
Procedure SetFormAssignmentKey(Form, Var_Key, LocationKey = "", SetSettings = True) Export
	
	SetFormAssignmentUsageKey(Form, Var_Key, SetSettings);
	SetFormWindowOptionsSaveKey(Form, ?(LocationKey = "", Var_Key, LocationKey), SetSettings);
	
EndProcedure

Procedure ResetWindowLocationAndSize(Form) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	FormName = Form.FormName;
	NewKeyForSavingTheWindowPosition = StrReplace(String(New UUID), "-", "_");
	StorageObjectKey = FormName + "/TemporaryKeysForSavingTheWindowPosition";
	UserName = UserName();
	BegOfDay = BegOfDay(CurrentUniversalDate());
	TheBoundaryOfObsolescence = BegOfDay - 2*24*60*60;
	
	Keys = SystemSettingsStorage.Load(StorageObjectKey);
	
	If TypeOf(Keys) = Type("Map") Then
		SettingsNames = New Array;
		SettingsNames.Add("/ThinClientWindowSettings");
		SettingsNames.Add("/Taxi/ThinClientWindowSettings");
		SettingsNames.Add("/WebClientWindowSettings");
		SettingsNames.Add("/MobileClientWindowSettings");
		SettingsNames.Add("/Taxi/WebClientWindowSettings");
		SettingsNames.Add("/Taxi/MobileClientWindowSettings");
		CurrentKeys = New Map(New FixedMap(Keys));
		For Each KeyAndValue In CurrentKeys Do
			CurrentDay = KeyAndValue.Key;
			If TypeOf(CurrentDay) <> Type("Date") Then
				Keys = Undefined;
				Break;
			EndIf;
			If CurrentDay > TheBoundaryOfObsolescence Then
				Continue;
			EndIf;
			KeysOfTheCurrentDay = KeyAndValue.Value;
			If TypeOf(KeysOfTheCurrentDay) <> Type("Array") Then
				Keys = Undefined;
				Break;
			EndIf;
			For Each CurrentKey In KeysOfTheCurrentDay Do
				TheBeginningOfTheObjectKey = FormName + "/" + CurrentKey;
				For Each SettingName In SettingsNames Do
					SystemSettingsStorage.Delete(TheBeginningOfTheObjectKey + SettingName, "", UserName);
				EndDo;
			EndDo;
			Keys.Delete(CurrentDay);
		EndDo;
	EndIf;
	
	ClearOldKeys = TypeOf(Keys) <> Type("Map");
	If ClearOldKeys Then
		Keys = New Map;
	EndIf;
	
	KeysOfTheDay = Keys.Get(BegOfDay);
	If TypeOf(KeysOfTheDay) <> Type("Array") Then
		KeysOfTheDay = New Array;
		Keys.Insert(BegOfDay, KeysOfTheDay);
	EndIf;
	KeysOfTheDay.Add(NewKeyForSavingTheWindowPosition);
	SystemSettingsStorage.Save(StorageObjectKey,, Keys);
	
	Form.WindowOptionsKey = NewKeyForSavingTheWindowPosition;
	
	If Not ClearOldKeys Then
		Return;
	EndIf;
	
	Filter = New Structure("User", UserName);
	Selection = SystemSettingsStorage.Select(Filter);
	KeySearchRussian = "НастройкиОкнаТонкогоКлиента"; // @Non-NLS
	SearchKeyEnglish = "ThinClientWindowSettings";
	While True Do
		Try
			ThereIsAnotherOne = Selection.Next();
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(
				NStr("vi = 'Lỗi thực hiện';
					|ru = 'Ошибка выполнения';
					|en = 'Runtime error'; fa = 'خطای زمان اجرا';
					|it = 'Errore nell''esecuzione';
					|pl = 'Błąd wykonania';
					|tr = 'Uygulama hatası'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			Break;
		EndTry;
		If Not ThereIsAnotherOne Then
			Break;
		EndIf;
		If Not StrStartsWith(Selection.ObjectKey, FormName)
		 Or Selection.SettingsKey <> ""
		 Or Selection.ObjectKey = StorageObjectKey Then
			Continue;
		EndIf;
		ObjectKeyParts1 = StrSplit(Selection.ObjectKey, "/");
		If ObjectKeyParts1.Count() < 2 Then
			Continue;
		EndIf;
		TheLastPartOfTheKey = ObjectKeyParts1[ObjectKeyParts1.UBound()];
		If StrFind(TheLastPartOfTheKey, KeySearchRussian) > 0
		 Or StrFind(TheLastPartOfTheKey, SearchKeyEnglish) > 0 Then
			SystemSettingsStorage.Delete(Selection.ObjectKey, "", UserName);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions_

// Returns additional details when application parameter problem occurs.
// 
// Returns:
//  String
//
Function ApplicationRunParameterErrorClarificationForDeveloper() Export
	
	Return Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString( 
		NStr("vi = 'Đối với người phát triển: có thể, cần cập nhật dữ liệu bổ trợ,
			|ảnh hưởng đến hoạt động của ứng dụng. Để thực hiện cập nhật, có thể:
			|- sử dụng bộ xử lý ngoài
			|  ""Công cụ của người phát triển: Cập nhật dữ liệu bổ trợ"",
			|- hoặc khởi động chương trình với tham số dòng lệnh 1C:Enterprise
			|  ""/С %1"",
			|- hoặc tăng số phiên bản cấu hình để khi khởi động lần sau
			|  thực hiện thủ tục cập nhật dữ liệu cơ sở thông tin.';
			|ru = 'Для разработчика: возможно требуется обновить вспомогательные данные,
			|которые влияют на работу приложения. Для выполнения обновления можно:
			|- воспользоваться внешней обработкой
			|  ""Инструменты разработчика: Обновление вспомогательных данных"",
			|- либо запустить приложение с параметром командной строки 1С:Предприятия 8
			|  ""/С %1"",
			|- либо увеличить номер версии приложения, чтобы при очередном запуске
			|  выполнились процедуры обновления данных информационной базы.';
			|en = 'Perhaps, some service data requires an update.
			|Do one of the following:
			| • Run external data processor
			|""Development tools: Service data update.""
			| • Run the app with command-line option:
			|/C %1.
			| • Update the app to a later version.
			|The data update procedures will start automatically at launch.'; fa = 'Perhaps, some service data requires an update.
			|Do one of the following:
			| • Run external data processor
			|""Development tools: Service data update.""
			| • Run the app with command-line option:
			|/C %1.
			| • Update the app to a later version.
			|The data update procedures will start automatically at launch.';
			|it = 'Для разработчика: возможно требуется обновить вспомогательные данные,
			|которые влияют на работу приложения. Для выполнения обновления можно:
			|- воспользоваться внешней обработкой
			|  ""Инструменты разработчика: Обновление вспомогательных данных"",
			|- либо запустить приложение с параметром командной строки 1С:Предприятия 8
			|  ""/С %1"",
			|- либо увеличить номер версии приложения, чтобы при очередном запуске
			|  выполнились процедуры обновления данных информационной базы.';
			|pl = 'Perhaps, some service data requires an update.
			|Do one of the following:
			| • Run external data processor
			|""Development tools: Service data update.""
			| • Run the app with command-line option:
			|/C %1.
			| • Update the app to a later version.
			|The data update procedures will start automatically at launch.';
			|tr = 'Geliştirici için: uygulamanın çalışmasını etkileyen 
			|yardımcı verileri güncelleştirmeniz gerekebilir. Güncelleme yapmak için şunları yapabilirsiniz:
			|- ""Geliştirici Araçları: yardımcı verileri güncelle"" dış işleme
			| kullanın,
			| - ya da uygulamayı 1C:Enterprise 8
			| ""/C %1""parametresiyle çalıştırın, 
			|- ya da bir sonraki başlatmada infobase veri 
			|güncelleme prosedürü çalıştırmak için konfigürasyon sürüm numarasını arttırın.'"),
		"StartInfobaseUpdate");
	
EndFunction

// Returns the current infobase user.
// 
// Returns:
//  InfoBaseUser
//
Function CurrentUser() Export
	
	// Calculate the up-to-date username even if it was changed in the current session.
	// (For example, when the infobase is accessed via an external session.)
	// In other cases, get "InfobaseUsers.CurrentUser".
	CurrentUser = InfoBaseUsers.FindByUUID(
		InfoBaseUsers.CurrentUser().UUID);
	
	If CurrentUser = Undefined Then
		CurrentUser = InfoBaseUsers.CurrentUser();
	EndIf;
	
	Return CurrentUser;
	
EndFunction

// Returns True if the current session is a background job session.
//
// Returns:
//  Boolean
//
Function ThisBackgroundJobSession() Export
	
	If CurrentRunMode() <> Undefined Then
		Return False;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	Return CurrentSession.ApplicationName = "BackgroundJob";
	
EndFunction

// Transforming a string to a valid description of a value table column values replacing invalid
// characters with the character code escaped with the underscore character.
//
// Parameters:
//  String - String - Source string.
// 
// Returns:
//  String - a string containing only admissible characters for the description of values table columns.
//
Function TransformStringToValidColumnDescription(String) Export
	
	InvalidChars = "№:;!@#$%^&-~`'.,?{}[]+=*/|\ ()_""";
	Result = "";
	For IndexOf = 1 To StrLen(String) Do
		Char =  Mid(String, IndexOf, 1);
		If StrFind(InvalidChars, Char) > 0 Or (CharCode(Char) > 126 And CharCode(Char) < 256) Then
			Result = Result + "_" + Format(CharCode(Char), "NG=;" ) + "_";
		Else
			Result = Result + Char;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Transforms adapted column description with prohibited
// characters replaced by the character code escaped with the underscore character (_) into a usual string.
//
// Parameters:
//  ColumnDescription - String - an adapted description of a column.
// 
// Returns:
//  String - a converted string.
//
Function TransformAdaptedColumnDescriptionToString(ColumnDescription) Export
	
	Result = "";
	For IndexOf = 1 To StrLen(ColumnDescription) Do
		Char = Mid(ColumnDescription, IndexOf, 1);
		If Char = "_" Then
			ClosingCharacterPosition = StrFind(ColumnDescription, "_", SearchDirection.FromBegin, IndexOf + 1);
			CharCode = Mid(ColumnDescription, IndexOf + 1, ClosingCharacterPosition - IndexOf - 1);
			Result = Result + Char(CharCode);
			IndexOf = ClosingCharacterPosition;
		Else
			Result = Result + Char;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Generates data required to notify open forms and dynamic lists
// on client on bunch object changes made on a server.
//
// Parameters:
//   ModifiedObjects - AnyRef
//                     - Type
//                     - Array - contains info about the changed objects.
//                       You can pass a reference or an array of references
//                       or specify a type or an array of types for changed objects.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - Type - for example, DocumentRef.SalesOrder.
//     * Value - Structure:
//        ** EventName - String - for example, Record_SalesOrder.
//        ** EmptyRef - AnyRef
// 
Function PrepareFormChangeNotification(ModifiedObjects) Export
	
	Result = New Map;
	If ModifiedObjects = Undefined Then
		Return Result;
	EndIf;
	
	TypesArray = New Array;
	RefOrTypeOrArrayType = TypeOf(ModifiedObjects);
	If RefOrTypeOrArrayType = Type("Array") Then
		For Each Item In ModifiedObjects Do
			ElementType = TypeOf(Item);
			If ElementType = Type("Type") Then
				ElementType = Item;
			EndIf;
			If TypesArray.Find(ElementType) = Undefined Then
				TypesArray.Add(ElementType);
			EndIf;
		EndDo;
	Else
		TypesArray.Add(ModifiedObjects);
	EndIf;
	
	For Each ElementType In TypesArray Do
		MetadataObject = Metadata.FindByType(ElementType);
		If TypeOf(MetadataObject) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		EventName = "Record_" + MetadataObject.Name;
		Try
			EmptyRef = PredefinedValue(MetadataObject.FullName() + ".EmptyRef");
		Except
			EmptyRef = Undefined;
		EndTry;
		Result.Insert(ElementType, New Structure("EventName,EmptyRef", EventName, EmptyRef));
	EndDo;
	Return Result;
	
EndFunction

// Sets the BlankHomePage common form for a desktop with empty form content.
//
// The separated desktop in web client
// requires the shared desktop form content to be filled, and vice versa.
//
Procedure SetBlankFormOnBlankHomePage() Export
	
	ObjectKey = "Common/HomePageSettings";
	
	CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	If CurrentSettings = Undefined Then
		CurrentSettings = New HomePageSettings;
	EndIf;
	
	CurrentFormComposition = CurrentSettings.GetForms();
	
	If CurrentFormComposition.LeftColumn.Count() = 0
	   And CurrentFormComposition.RightColumn.Count() = 0 Then
		
		CurrentFormComposition.LeftColumn.Add("CommonForm.BlankHomePage");
		CurrentSettings.SetForms(CurrentFormComposition);
		SystemSettingsStorage.Save(ObjectKey, "", CurrentSettings);
	EndIf;
	
EndProcedure

// Checks if the current user is allowed to post a list of documents.
//
// Parameters:
//  DocumentsList - Array - document for checking.
//
// Returns:
//  Boolean - True if the user has the right to post at least one document.
//
Function HasRightToPost(DocumentsList) Export
	DocumentTypes = New Array;
	For Each Document In DocumentsList Do
		DocumentType = TypeOf(Document);
		If DocumentTypes.Find(DocumentType) <> Undefined Then
			Continue;
		Else
			DocumentTypes.Add(DocumentType);
		EndIf;
		If AccessRight("Posting", Metadata.FindByType(DocumentType)) Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

// Checks if the passed table is a register.
// 
// Parameters:
//  TableName - String - a full table name.
// 
// Returns:
//  Boolean 
//
Function IsRegisterTable(TableName) Export
	InRegTableName = Upper(TableName);
	If StrStartsWith(InRegTableName, Upper("InformationRegister"))
		Or StrStartsWith(InRegTableName, Upper("AccumulationRegister"))
		Or StrStartsWith(InRegTableName, Upper("AccountingRegister"))
		Or StrStartsWith(InRegTableName, Upper("CalculationRegister")) Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

// Returns a home page presentation.
//
// Returns:
//   String
//
Function HomePagePresentation() Export 
	
	Return NStr("vi = 'Chính';
				|ru = 'Главное';
				|en = 'Main'; fa = 'اصلی';
				|it = 'Principale';
				|pl = 'Main';
				|tr = 'Genel'");
	
EndFunction

// Intended for the "WriteToBusinessProcessesList" event subscription.
//
Procedure CheckSafeModeBeforeWrite(Source, Cancel) Export
	// ACC:75-off - The DataExchange.Load check is excessive,
	// as this check should be performed anyway.
	
	// ACC:1371-off - This check is applicable to all metadata objects, including the ones being deleted.
	
	If GetSafeModeDisabled() Then
		SetSafeModeDisabled(False);
	EndIf;
	
	If SafeMode() = False Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If PrivilegedMode()
	 Or TypeOf(Source) = Type("CatalogObject.Users")
	   And Not Catalogs.Users.HasProhibitedChanges(Source)
	 Or TypeOf(Source) = Type("CatalogObject.ExternalUsers")
	   And Not Catalogs.ExternalUsers.HasProhibitedChanges(Source) Then
		
		Return;
	EndIf;
	
	Raise NStr("vi = 'Thao tác không được phép ở chế độ an toàn.';
				|ru = 'Действие недоступно в безопасном режиме.';
				|en = 'The action is unavailable in safe mode.'; fa = 'The action is unavailable in safe mode.';
				|it = 'Действие недоступно в безопасном режиме.';
				|pl = 'The action is unavailable in safe mode.';
				|tr = 'Eylem güvenli modda geçerli değil.'");
	
EndProcedure

Procedure CheckSafeModeBeforeWritingRecordSet(Source, Cancel, Replacing,
				WriteOnly = Undefined,
				WriteActualActionPeriod = Undefined,
				WriteRecalculations = Undefined) Export
	
	// ACC:75-off - The DataExchange.Load check is excessive,
	// as this check should be performed anyway.
	
	// ACC:1371-off - This check is applicable to all metadata objects, including the ones being deleted.
	
	If GetSafeModeDisabled() Then
		SetSafeModeDisabled(False);
	EndIf;
	
	If SafeMode() = False Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not PrivilegedMode() Then
		Raise NStr("vi = 'Thao tác không được phép ở chế độ an toàn.';
					|ru = 'Действие недоступно в безопасном режиме.';
					|en = 'The action is unavailable in safe mode.'; fa = 'The action is unavailable in safe mode.';
					|it = 'Действие недоступно в безопасном режиме.';
					|pl = 'The action is unavailable in safe mode.';
					|tr = 'Eylem güvenli modda geçerli değil.'");
	EndIf;
	
EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the MetadataObjectIDs.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.MetadataObjectIDs.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// Cannot import to the ExtensionObjectIDs catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.ExtensionObjectIDs.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.MetadataObjectIDs.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExtensionObjectIDs.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.SafeDataStorage.Dimensions.Owner);
	RefSearchExclusions.Add(Metadata.InformationRegisters.SafeDataAreaDataStorage.Dimensions.Owner);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	AddClientRunParameters(Parameters);
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	// FunctionalOptionsModified
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.Core.FunctionalOptionsModified");
	
	Notification.NotificationSendModuleName  = "StandardSubsystemsServer";
	Notification.NotificationReceiptModuleName = "StandardSubsystemsClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
	// CachedValuesOutdated
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.Core.CachedValuesOutdated");
	
	Notification.NotificationReceiptModuleName = "StandardSubsystemsClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.MetadataObjectIDs);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.InfobasePublicationURL);
	Types.Add(Metadata.Constants.LocalInfobasePublishingURL);
	Types.Add(Metadata.Constants.InfoBaseID);
	Types.Add(Metadata.Constants.DeliverServerNotificationsWithoutCollaborationSystem);
	Types.Add(Metadata.Constants.RegisterServerNotificationsIndicators);
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.ExtensionsVersions,
		ModuleExportImportData.ActionWithLinksDoNotChange());
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.ExtensionObjectIDs,
		ModuleExportImportData.ActionWithLinksDoNotChange());
	Types.Add(Metadata.InformationRegisters.SafeDataAreaDataStorage);
	Types.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs);
	Types.Add(Metadata.InformationRegisters.ExtensionVersionParameters);
	Types.Add(Metadata.InformationRegisters.ObsoleteSafeDataAreaDataStorage);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array();
	
	Permissions.Add(ModuleSafeModeManager.PermissionToUseTempDirectory(True, True,
		NStr("vi = 'Để có thể làm việc với ứng dụng.';
			|ru = 'Для возможности работы приложения.';
			|en = 'Basic permissions required to run the app.'; fa = 'Basic permissions required to run the app.';
			|it = 'Для возможности работы приложения.';
			|pl = 'Basic permissions required to run the app.';
			|tr = 'Uygulamanın çalışması için.'")));
	Permissions.Add(ModuleSafeModeManager.PermissionToUsePrivilegedMode());
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
	AddRequestForPermissionToUseExtensions(PermissionsRequests);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	Id = "DynamicApplicationUpdateControl";
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = Id;
	ToDoItem.HasToDoItems      = DataBaseConfigurationChangedDynamically()
	                     Or Catalogs.ExtensionsVersions.ExtensionsChangedDynamically();
	ToDoItem.Important        = False;
	ToDoItem.Presentation = NStr("vi = 'Đã cài đặt bản cập nhật ứng dụng';
								|ru = 'Установлено обновление приложения';
								|en = 'Application update installed'; fa = 'به‌روزرسانی برنامه نصب شد';
								|it = 'Установлено обновление приложения';
								|pl = 'Application update installed';
								|tr = 'Uygulama güncellemesi kuruldu'");
	ToDoItem.Form         = "CommonForm.DynamicUpdateControl";
	ToDoItem.Owner      = NStr("vi = 'Hoạt động của ứng dụng';
								|ru = 'Работа приложения';
								|en = 'Application performance'; fa = 'عملکرد برنامه';
								|it = 'Работа приложения';
								|pl = 'Application performance';
								|tr = 'Uygulamanın işleyişi'");
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled("SpeedupRecommendation") Then
		Return;
	EndIf;
	
	Id = "SpeedupRecommendation";
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = Id;
	ToDoItem.HasToDoItems      = MustShowRAMSizeRecommendations();
	ToDoItem.Important        = True;
	ToDoItem.Presentation = NStr("vi = 'Giảm tốc độ làm việc';
								|ru = 'Скорость работы снижена';
								|en = 'Application performance degraded'; fa = 'Application performance degraded';
								|it = 'Velocità di lavoro abbassata';
								|pl = 'Szybkość pracy została zmniejszona';
								|tr = 'Çalışma hızı düştü'");
	ToDoItem.Form         = "DataProcessor.SpeedupRecommendation.Form";
	ToDoItem.Owner      = NStr("vi = 'Hoạt động của ứng dụng';
								|ru = 'Работа приложения';
								|en = 'Application performance'; fa = 'عملکرد برنامه';
								|it = 'Работа приложения';
								|pl = 'Application performance';
								|tr = 'Uygulamanın işleyişi'");
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForSystemAdministratorsOnly.
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.SystemAdministrator.Name);
	
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.Administration.Name);
	
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.UpdateDataBaseConfiguration.Name);
	
	// ForSystemUsersOnly.
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartThickClient.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartExternalConnection.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartAutomation.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.TechnicianMode.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors.Name);
	
	// ForExternalUsersOnly.
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles.BasicAccessExternalUserSSL.Name);
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartThinClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartWebClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartMobileClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.OutputToPrinterFileClipboard.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.SaveUserData.Name);
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.FillExtensionsOperationParameters.Name);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	// Update the built-in profiles and add-in run parameters in the background.
	InformationRegisters.ExtensionVersionParameters.EnableFillingExtensionsWorkParameters(False, True);
	If Common.DataSeparationEnabled() Then
		InformationRegisters.ExtensionVersionParameters.StartFillingWorkParametersExtensions(
			NStr("vi = 'Khởi động có đợi sau khi kết nhập dữ liệu vùng';
				|ru = 'Запуск с ожиданием после загрузки данных области';
				|en = 'Start and wait after importing area data'; fa = 'Start and wait after importing area data';
				|it = 'Запуск с ожиданием после загрузки данных области';
				|pl = 'Start and wait after importing area data';
				|tr = 'Alan verilerinin indirilmesinden sonra beklenenle başlatma'"),
			True);
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.SetConstantDoNotUseSeparationByDataAreas";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExclusiveMode = True;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.MarkVersionCacheRecordsObsolete";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "InfobaseUpdateInternal.InitialFillingOfPredefinedData";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.7.149";
	Handler.Procedure = "StandardSubsystemsServer.EnableConstantToDeliverServerAlertsWithoutInteractionSystem";
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.11.61";
	Handler.Procedure = "StandardSubsystemsServer.EnableConstantAllowAccessToInternetServices";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	
	If Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version = "3.1.11.65";
		Handler.Procedure = "StandardSubsystemsServer.MoveSafeDataAreaDataStorage";
		Handler.SharedData = False;
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version = "3.1.12.95";
		Handler.Procedure = "StandardSubsystemsServer.SetIntegrationServicesLaunchSchedule";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export

	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.IntegrationServicesProcessing;
	Dependence.UseExternalResources = True;
	
EndProcedure

// See SSLSubsystemsIntegration.OnDefineObjectsToExcludeFromCheck
Procedure OnDefineObjectsToExcludeFromCheck(Objects) Export
	Objects.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs);
EndProcedure

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	CheckParameters = Parameters.Get(ParameterName);
	If CheckParameters = Undefined Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	UserMessage = Undefined;
	ConfigurationOrExtensionModifiedDuringRepeatedCheck(UserMessage);
	If UserMessage = Undefined Then
		Return;
	EndIf;
	
	Results.Insert(ParameterName, UserMessage);
	
EndProcedure

// See UsersOverridable.OnGetOtherSettings.
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	CurrentSchedule = Common.SystemSettingsStorageLoad("DynamicUpdateControl",
		"PatchCheckSchedule",,,
		UserInfo.InfoBaseUserName);
	If CurrentSchedule <> Undefined Then
		SettingProperties = New Structure;
		SettingProperties.Insert("SettingName1", NStr("vi = 'Lịch biểu kiểm tra bản vá lỗi mới';
														|ru = 'Расписание проверки новых патчей';
														|en = 'Schedule to check for new patches'; fa = 'Schedule to check for new patches';
														|it = 'Расписание проверки новых патчей';
														|pl = 'Schedule to check for new patches';
														|tr = 'Yeni yamaların kontrol programı'"));
		SettingProperties.Insert("PictureSettings", PictureLib.Calendar);
		SettingProperties.Insert("SettingsList", New ValueList);
		SettingProperties.SettingsList.Add(CurrentSchedule);
		Settings.Insert("PatchCheckSchedule", SettingProperties);
	EndIf;
	
EndProcedure

// See UsersOverridable.OnSaveOtherSetings.
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	If Settings.SettingID = "PatchCheckSchedule" Then
		If Settings.SettingValue.Count() = 1 Then
			Schedule = Settings.SettingValue[0].Value;
			
			Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule",
				Schedule,,
				UserInfo.InfoBaseUserName);
		EndIf;
	EndIf;
	
EndProcedure

// See UsersOverridable.OnDeleteOtherSettings.
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	If Settings.SettingID = "PatchCheckSchedule" Then
		Common.SystemSettingsStorageDelete("DynamicUpdateControl",
			"PatchCheckSchedule",
			UserInfo.InfoBaseUserName);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnSetUpValidationOfMethodsCalledAsArbitraryCode.
Procedure OnSetUpValidationOfMethodsCalledAsArbitraryCode(Settings) Export
	
	// Session parameter setting handlers.
	ProceduresNames = New Map;
	
	Handlers = New Map;
	SSLSubsystemsIntegration.OnAddSessionParameterSettingHandlers(Handlers);
	For Each KeyAndValue In Handlers Do
		ProceduresNames.Insert(KeyAndValue.Value);
	EndDo;
	
	Handlers = New Map;
	CommonOverridable.OnAddSessionParameterSettingHandlers(Handlers);
	For Each KeyAndValue In Handlers Do
		ProceduresNames.Insert(KeyAndValue.Value);
	EndDo;
	
	HandlerDetails = Settings.HandlersDetails.Add();
	HandlerDetails.ProceduresNames = ProceduresNames;
	HandlerDetails.ErrorTitle = NStr("vi = 'Hàm sự kiện thiết lập tham số phiên ""%1"".';
									|ru = 'Обработчик установки параметров сеанса ""%1"".';
									|en = 'Session parameter setting handler ""%1"".'; fa = 'Session parameter setting handler ""%1"".';
									|it = 'Session parameter setting handler ""%1"".';
									|pl = 'Session parameter setting handler ""%1"".';
									|tr = '""%1"" oturum parametresi ayarlama işleyicisi.'");
	
	// Exceptions.
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.Common";
	CheckException.ProcedureName       = "RunBackgroundJob";
	CheckException.ContentFragment =
		"BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(MethodName,
		|			ExecutionParameters.Parameters, ExecutionParameters.Key, ExecutionParameters.Description)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.Common";
	CheckException.ProcedureName       = "RunBackgroundJob";
	CheckException.ContentFragment =
		"BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(MethodName,
		|			ExecutionParameters.Parameters, ExecutionParameters.Key, ExecutionParameters.Description)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.Common";
	CheckException.ProcedureName       = "RunBackgroundJob";
	CheckException.ContentFragment =
		"BackgroundJob = BackgroundJobs.Execute(MethodName,
		|			ExecutionParameters.Parameters, ExecutionParameters.Key, ExecutionParameters.Description)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.Common";
	CheckException.ProcedureName       = "CallConfigurationFunction";
	CheckException.ContentFragment = "Return ExecuteConfigurationMethod(MethodName, Parameters, True)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.Common";
	CheckException.ProcedureName       = "CallObjectFunction";
	CheckException.ContentFragment = "Return ExecuteObjectMethod(Object, MethodName, Parameters, True)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.StandardSubsystemsServer";
	CheckException.ProcedureName       = "ExecuteSessionParameterSettingHandlers";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(Handler, HandlerParameters)";
	
	Methods = New Map;
	Methods.Insert("RefsToObjectFound", True);
	Settings.ExclusionsWhenSpecifiedMethodNotCalled.Insert("CommonModule.Common", Methods);
	
EndProcedure

// Generates the text to be displayed to the user if dynamic update is needed.
// 
// Parameters:
//  DynamicConfigurationChanges - See Catalogs.ExtensionsVersions.DynamicallyChangedExtensions
//  
// Returns:
//  String 
//
Function MessageTextOnDynamicUpdate(DynamicConfigurationChanges) Export
	
	Messages = New Array;
	
	If DynamicConfigurationChanges.DataBaseConfigurationChangedDynamically Then
		MessageTextConfiguration = NStr("vi = 'Đã cập nhật phiên bản chương trình (đã đưa các thay đổi vào cấu hình cơ sở thông tin).';
										|ru = 'Версия приложения обновлена (внесены изменения в конфигурацию информационной базы).';
										|en = 'The application is updated (the infobase configuration is modified).'; fa = 'The application is updated (the infobase configuration is modified).';
										|it = 'Версия приложения обновлена (внесены изменения в конфигурацию информационной базы).';
										|pl = 'The application is updated (the infobase configuration is modified).';
										|tr = 'Uygulamanın sürümü güncellendi (infobase konfigürasyonda değişiklikler yapıldı).'");
		Messages.Add(MessageTextConfiguration);
	EndIf;
	
	If DynamicConfigurationChanges.Corrections <> Undefined Then
		If DynamicConfigurationChanges.Corrections.Added2 > 0
			And DynamicConfigurationChanges.Corrections.Deleted > 0 Then
			MessageTextPatches = NStr("vi = 'Các bản sửa lỗi (bản vá) mới: %1, đã gỡ bỏ: %2.';
										|ru = 'Новые исправления (патчи): %1, удалены: %2.';
										|en = 'New patches: %1, deleted: %2.'; fa = 'New patches: %1, deleted: %2.';
										|it = 'Новые исправления (патчи): %1, удалены: %2.';
										|pl = 'New patches: %1, deleted: %2.';
										|tr = 'Yeni düzeltmeler (yamalar): %1, silinenler: %2.'");
		ElsIf DynamicConfigurationChanges.Corrections.Added2 = 1 Then
			MessageTextPatches = NStr("vi = 'Các bản sửa lỗi (bản vá) mới.';
										|ru = 'Новое исправление (патч).';
										|en = 'New patch.'; fa = 'New patch.';
										|it = 'Новое исправление (патч).';
										|pl = 'New patch.';
										|tr = 'Yeni düzeltme (yama).'");
		ElsIf DynamicConfigurationChanges.Corrections.Added2 > 0 Then
			MessageTextPatches = NStr("vi = 'Bản chỉnh sửa (bản vá lỗi) mới: %1.';
										|ru = 'Новые исправления (патчи): %1.';
										|en = 'New patches: %1.'; fa = 'New patches: %1.';
										|it = 'Новые исправления (патчи): %1.';
										|pl = 'New patches: %1.';
										|tr = 'Yeni düzeltmeler (yamalar): %1.'");
		ElsIf DynamicConfigurationChanges.Corrections.Deleted > 0 Then
			MessageTextPatches = NStr("vi = 'Đã xóa bản sửa lỗi (vá lỗi): %2.';
										|ru = 'Удалены исправления (патчи): %2.';
										|en = 'Patches deleted: %2.'; fa = 'Patches deleted: %2.';
										|it = 'Correzioni eliminate (patch):%2.';
										|pl = 'Usunięto korekty (łaty): %2.';
										|tr = 'Düzeltmeler (yamalar) silindi: %2.'");
		EndIf;
		MessageTextPatches = StringFunctionsClientServer.SubstituteParametersToString(MessageTextPatches,
			DynamicConfigurationChanges.Corrections.Added2,
			DynamicConfigurationChanges.Corrections.Deleted);
		Messages.Add(MessageTextPatches);
	EndIf;
	
	If DynamicConfigurationChanges.Extensions <> Undefined Then
		If DynamicConfigurationChanges.Extensions.Added2 > 0 Then
			MessageTextExtensions = NStr("vi = 'Phần mở rộng mới: %1.';
										|ru = 'Новые расширения: %1.';
										|en = 'New extensions: %1.'; fa = 'New extensions: %1.';
										|it = 'Новые расширения: %1.';
										|pl = 'New extensions: %1.';
										|tr = 'Yeni uzantılar: %1.'");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.Added2);
			Messages.Add(MessageTextExtensions);
		EndIf;
		
		If DynamicConfigurationChanges.Extensions.Deleted > 0 Then
			MessageTextExtensions = NStr("vi = 'Đã xóa phần mở rộng: %1.';
										|ru = 'Удалены расширения: %1.';
										|en = 'Extensions deleted: %1.'; fa = 'Extensions deleted: %1.';
										|it = 'Estensioni eliminate: %1.';
										|pl = 'Usunięto rozszerzenia: %1.';
										|tr = 'Uzantılar silindi: %1.'");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.Deleted);
			Messages.Add(MessageTextExtensions);
		EndIf;
		
		If DynamicConfigurationChanges.Extensions.IsChanged > 0 Then
			MessageTextExtensions = NStr("vi = 'Đã thay đổi phần mở rộng: %1.';
										|ru = 'Изменены расширения: %1.';
										|en = 'Extensions modified: %1.'; fa = 'Extensions modified: %1.';
										|it = 'Estensioni modificate: %1.';
										|pl = 'Zmieniono rozszerzenia: %1.';
										|tr = 'Uzantılar değiştirildi: %1.'");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.IsChanged);
			Messages.Add(MessageTextExtensions);
		EndIf;
	EndIf;
		
	Return StrConcat(Messages, Chars.LF);
	
EndFunction

// Determines a PDF save format depending on the platform.
// 
// Returns:
//  SpreadsheetDocumentFileType
//
Function TableDocumentFileTypePDF() Export
	
	Return SpreadsheetDocumentFileType["PDF_A_3"];
	
EndFunction

// Determines a user presentation of the PDF save format depending on the platform.
// 
// Returns:
//  String
//
Function FileTypeRepresentationOfATabularPDFDocument() Export
	
	Return NStr("vi = 'Văn bản Adobe PDF/A (.pdf)';
				|ru = 'Документ PDF/A (.pdf)';
				|en = 'PDF/A document (.pdf)'; fa = 'PDF/A document (.pdf)';
				|it = 'Documento Adobe PDF/A (.pdf)';
				|pl = 'Dokument Adobe PDF/A (.pdf)';
				|tr = 'PDF/A (.pdf) belgesi'");
	
EndFunction

Function ConfigurationLanguages() Export
	
	Languages = New Array;
	For Each Language In Metadata.Languages Do
		Languages.Add(Language.LanguageCode);
	EndDo;
	
	Return Languages;
	
EndFunction

// Parameters:
//  Headers - Map - See the "Headers" parameter of the "HTTPResponse" object in Syntax Assistant.
// 
// Returns:
//  Map
//
Function HTTPHeadersInLowercase(Headers) Export
	
	Result = New Map;
	For Each Title In Headers Do
		Result.Insert(Lower(Title.Key), Title.Value);
	EndDo;
	Return Result;
	
EndFunction

// Parameters:
//  Id - String - an add-in ID.
//  Location - String - an add-in template location (without the version specified).
//  AddIn - Undefined
//                    - Structure - Add-in data:
//                       * Id - String - an add-in ID in the catalog.
//                       * Version - String - version.
//                       * Location - String - location.
//                       * Available - Boolean - flag of availability.
//
// Returns:
//  Structure:
//   * Id - String - an add-in ID in the catalog.
//   * Location - String - an add-in template, a reference address in the catalog.
//   * Version - String - version.
//
Function TheComponentOfTheLatestVersion(Id, Location, AddIn = Undefined) Export
		
	TheComponentOfTheLatestVersion = New Structure;
	TheComponentOfTheLatestVersion.Insert("Id", Id);
	TheComponentOfTheLatestVersion.Insert("Location", "");
	TheComponentOfTheLatestVersion.Insert("Version", "");
	
	// Information about add-in.
	If AddIn <> Undefined And AddIn.Available Then
		TheLatestVersionOfTheExternalComponent = New Structure("Version, Location", 
			AddIn.Version, AddIn.Location);
	Else
		TheLatestVersionOfTheExternalComponent = Undefined;
	EndIf;
	
	// Information about a template add-in.
	If ValueIsFilled(Location) Then
		TheLatestVersionOfComponentsFromTheLayout = StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout(
			Location);
	Else
		TheLatestVersionOfComponentsFromTheLayout = Undefined;
	EndIf;
	
	If TheLatestVersionOfTheExternalComponent <> Undefined And TheLatestVersionOfComponentsFromTheLayout <> Undefined Then
		
		If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(TheLatestVersionOfTheExternalComponent.Version, ".",
			"")) Then
			VersionParts = StrSplit(TheLatestVersionOfTheExternalComponent.Version, ".");
			If VersionParts.Count() = 4 And CommonClientServer.CompareVersions(
				TheLatestVersionOfTheExternalComponent.Version, TheLatestVersionOfComponentsFromTheLayout.Version) <= 0 Then
				FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfComponentsFromTheLayout);
				Return TheComponentOfTheLatestVersion;
			EndIf;
		EndIf;
		
		// If the add-in version mismatches the template or exceeds the template's version, take an add-in from the catalog.
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfTheExternalComponent);
		Return TheComponentOfTheLatestVersion;
		
	ElsIf TheLatestVersionOfComponentsFromTheLayout <> Undefined Then
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfComponentsFromTheLayout);
		Return TheComponentOfTheLatestVersion;
	ElsIf TheLatestVersionOfTheExternalComponent <> Undefined Then
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfTheExternalComponent);
		Return TheComponentOfTheLatestVersion;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không tồn tại cấu phần ngoài có tên định danh %1';
			|ru = 'Не существует внешняя компонента с идентификатором %1';
			|en = 'Add-in with ID %1 does not exist'; fa = 'Add-in with ID %1 does not exist';
			|it = 'Non esiste una componente esterna con ID %1';
			|pl = 'Nie istnieje komponentu zewnętrznego z identyfikatorem %1';
			|tr = '%1 kimlikli dış bileşen mevcut değil'"), Id);
	
EndFunction

// Returns:
//  String -  Technical information about the subsystem versions and extensions.
//
Function TechnicalInfoOnExtensionsAndSubsystemsVersions() Export
	
	SubsystemsDetails = Common.SubsystemsDetails();
	
	TechnicalInfoOnExtensionsAndSubsystemsVersions = NStr("vi = 'Phiên bản phân hệ';
															|ru = 'Версии подсистем';
															|en = 'Subsystem versions'; fa = 'نسخه‌های زیرسیستم';
															|it = 'Versioni dei sottosistemi';
															|pl = 'Wersję podsystemów';
															|tr = 'Alt sistem sürümleri'") + ":" + Chars.LF;
	For Each SubsystemDetails In SubsystemsDetails Do
		TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions
			+ SubsystemDetails.Name + " - "
			+ SubsystemDetails.Version + Chars.LF;
	EndDo;
		
	TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions + Chars.LF;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Extensions = ConfigurationExtensions.Get();
	For Each Extension In Extensions Do
		
		TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions
			+ Extension.Name + " - " + Extension.Synonym + " - "
			+ Format(Extension.Active, NStr("vi = 'БЛ=Tắt; БИ=Bật';
											|ru = 'БЛ=Отключено; БИ=Включено';
											|en = 'BF=Disabled; BT=Enabled'; fa = 'BF=Disabled; BT=Enabled';
											|it = 'БЛ=Disattivato; BV=Attivato';
											|pl = 'BF=Wyłączono; BT=Włączono';
											|tr = 'BF=Kapalı; BT=Açık'")) + Chars.LF;
		
	EndDo;
	
	Return TechnicalInfoOnExtensionsAndSubsystemsVersions;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
//
// Parameters:
//   See the OnSendDataToMaster event handler in Syntax Assistant.
// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Val Recipient)
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Metadata object IDs are sent in another exchange message section.
	IgnoreSendingMetadataObjectIDs(DataElement, ItemSend);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	If TypeOf(DataElement) = Type("ConstantValueManager.AllowAccessToInternetServices") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
	SSLSubsystemsIntegration.OnSendDataToMaster(DataElement, ItemSend, Recipient);
	
	// Calling an overridden handler to execute the applied logic of DIB exchange.
	CommonOverridable.OnSendDataToMaster(DataElement, ItemSend, Recipient);
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataExportPercentage(Recipient, False);
	EndIf;
	
EndProcedure

// Returns a parameter structure required for this subsystem
// client script execution when the application starts, that is in following event handlers.
// - BeforeStart,
// - OnStart.
//
// Important: when starting the application, do not use cache
// reset commands of modules that reuse return values as this can lead to
// unpredictable errors and unnecessary service calls.
//
// Parameters:
//   Parameters   - Structure - a parameter structure.
//
// Returns:
//   Boolean   - False if further parameters filling should be aborted.
//
Function AddClientParametersOnStart(Parameters) Export
	
	IsCallBeforeStart = Parameters.RetrievedClientParameters <> Undefined;
	
	If IsCallBeforeStart Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		CheckIfCanStart();
		AddIndicator(Parameters, StartMoment,
			"StandardSubsystemsServer.CheckIfCanStart");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
	Else
		IsSeparatedConfiguration = False;
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"ModuleSaaSOperations.IsSeparatedConfiguration");
	
	// Mandatory parameters to continue application running.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());
	AddIndicator(Parameters, StartMoment,
		"Common.DataSeparationEnabled");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("SeparatedDataUsageAvailable", 
		Common.SeparatedDataUsageAvailable());
	AddIndicator(Parameters, StartMoment,
		"Common.SeparatedDataUsageAvailable");
	
	Parameters.Insert("IsSeparatedConfiguration", IsSeparatedConfiguration);
	
	// Obsolete. Kept for backward compatibility. Use UsersClient.IsFullUser instead.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("HasAccessForUpdatingPlatformVersion", Users.IsFullUser(,True));
	AddIndicator(Parameters, StartMoment,
		"Users.IsFullUser");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("SubsystemsNames", StandardSubsystemsCached.SubsystemsNames());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsCached.SubsystemsNames");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsBaseConfigurationVersion", IsBaseConfigurationVersion());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.IsBaseConfigurationVersion");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsTrainingPlatform", IsTrainingPlatform());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.IsTrainingPlatform");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("UserCurrentName", CurrentUser().Name);
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.CurrentUser");
	
	// Obsolete. Kept for backward compatibility. Use CommonClientServer.COMConnectorName instead.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("COMConnectorName", CommonClientServer.COMConnectorName());
	AddIndicator(Parameters, StartMoment,
		"CommonClientServer.COMConnectorName");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("DefaultLanguageCode", Common.DefaultLanguageCode());
	AddIndicator(Parameters, StartMoment,
		"Common.DefaultLanguageCode");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		AdditionalLanguagesCount = ModuleNationalLanguageSupportServer.AdditionalLanguagesCount();
	Else
		AdditionalLanguagesCount = 0;
	EndIf;
	Parameters.Insert("AdditionalLanguagesCount", AdditionalLanguagesCount);
	AddIndicator(Parameters, StartMoment,
		"NationalLanguageSupportServer.AdditionalLanguagesCount");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	UserSettings = ErrorProcessing.GetUserSettings();
	Parameters.Insert("ErrorInfoSendingSettings",
		New Structure("SendOutMode, SendOutAddress",
			UserSettings.SendReportOnClient,
			UserSettings.ErrorProcessingServiceAddress));
	AddIndicator(Parameters, StartMoment,
		"ErrorProcessing.GetUserSettings");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("AskConfirmationOnExit", AskConfirmationOnExit());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.AskConfirmationOnExit");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	CommonParameters = Common.CommonCoreParameters();
	Parameters.Insert("MinPlatformVersion",   CommonParameters.MinPlatformVersion);
	Parameters.Insert("RecommendedPlatformVersion", CommonParameters.RecommendedPlatformVersion);
	// Obsolete. Kept for backward compatibility. Use the two previous parameters instead.
	Parameters.Insert("MinPlatformVersion1", CommonParameters.MinPlatformVersion1);
	Parameters.Insert("MustExit",            CommonParameters.MustExit);
	Parameters.Insert("RecommendedRAM", CommonParameters.RecommendedRAM);
	AddIndicator(Parameters, StartMoment,
		"Common.CommonCoreParameters");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("MustShowRAMSizeRecommendations",
		MustShowRAMSizeRecommendations()
		And Not Common.SubsystemExists("StandardSubsystems.ToDoList"));
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.MustShowRAMSizeRecommendations");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsExternalUserSession", Users.IsExternalUserSession());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.MustShowRAMSizeRecommendations");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsFullUser", Users.IsFullUser());
	AddIndicator(Parameters, StartMoment,
		"Users.IsFullUser");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsSystemAdministrator", Users.IsFullUser(, True));
	AddIndicator(Parameters, StartMoment,
		"Users.IsSystemAdministrator");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("FileInfobase", Common.FileInfobase());
	AddIndicator(Parameters, StartMoment,
		"Common.FileInfobase");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If InvalidPlatformVersionUsed() Then
		Parameters.Insert("InvalidPlatformVersionUsed");
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.InvalidPlatformVersionUsed");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If IsCallBeforeStart Then
		Parameters.Insert("StyleItems", StyleElementsSet());
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.StyleElementsSet");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("InterfaceOptions") Then
		Parameters.Insert("InterfaceOptions", StandardSubsystemsCached.InterfaceOptions());
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.StyleElementsSet");
	
	If IsCallBeforeStart Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		ErrorInsufficientRightsForAuthorization = UsersInternal.ErrorInsufficientRightsForAuthorization(
			Not Parameters.RetrievedClientParameters.Property("ErrorInsufficientRightsForAuthorization"));
		AddIndicator(Parameters, StartMoment,
			"UsersInternal.ErrorInsufficientRightsForAuthorization");
		
		If ValueIsFilled(ErrorInsufficientRightsForAuthorization) Then
			Parameters.Insert("ErrorInsufficientRightsForAuthorization", ErrorInsufficientRightsForAuthorization);
			Return False;
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.OnAddClientParametersOnStart(
			Parameters, IsCallBeforeStart);
		AddIndicator(Parameters, StartMoment,
			"ExternalResourcesOperationsLock.OnAddClientParametersOnStart");
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
			Parameters.Insert("OperationsWithExternalResourcesLocked");
		EndIf;
		AddIndicator(Parameters, StartMoment,
			"ScheduledJobsServer.OperationsWithExternalResourcesLocked");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	IsParametersAdded = InfobaseUpdateInternal.AddClientParametersOnStart(Parameters);
	AddIndicator(Parameters, StartMoment,
		"InfobaseUpdateInternal.AddClientParametersOnStart");
	
	If Not IsParametersAdded And IsCallBeforeStart Then
		Return False;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ShowDeprecatedPlatformVersion") Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Show = ShowDeprecatedPlatformVersion(Parameters);
		AddIndicator(Parameters, StartMoment,
			"StandardSubsystemsServer.ShowDeprecatedPlatformVersion");
		If Show Then
			Parameters.Insert("ShowDeprecatedPlatformVersion");
			StartMoment = CurrentUniversalDateInMilliseconds();
			StandardSubsystemsServerCall.HideDesktopOnStart();
			AddIndicator(Parameters, StartMoment,
				"StandardSubsystemsServerCall.HideDesktopOnStart");
			Return False;
		EndIf;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ReconnectMasterNode")
	   And Not Common.DataSeparationEnabled() Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		SetPrivilegedMode(True);
		ReconnectMasterNode = ExchangePlans.MasterNode() = Undefined
			And ValueIsFilled(Constants.MasterNode.Get());
		SetPrivilegedMode(False);
		AddIndicator(Parameters, StartMoment,
			"StandardSubsystemsServer.ReconnectMasterNode");
		
		If ReconnectMasterNode Then 
			StartMoment = CurrentUniversalDateInMilliseconds();
			Parameters.Insert("ReconnectMasterNode", Users.IsFullUser(, True));
			AddIndicator(Parameters, StartMoment,
				"Users.IsFullUser");
			
			StartMoment = CurrentUniversalDateInMilliseconds();
			StandardSubsystemsServerCall.HideDesktopOnStart();
			AddIndicator(Parameters, StartMoment,
				"StandardSubsystemsServerCall.HideDesktopOnStart");
			Return False;
		EndIf;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ServerNotifications") Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		ServerNotifications.OnAddClientParametersOnStart(Parameters);
		AddIndicator(Parameters, StartMoment,
			"ServerNotifications.OnAddClientParametersOnStart");
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("SelectInitialRegionalIBSettings") Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Required2 = RegionalInfobaseSettingsRequired();
		AddIndicator(Parameters, StartMoment,
			"StandardSubsystemsServer.RegionalInfobaseSettingsRequired");
		
		If Required2 Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			Parameters.Insert("SelectInitialRegionalIBSettings",
				Users.IsFullUser(, True, False));
			AddIndicator(Parameters, StartMoment,
				"Users.IsFullUser");
			
			StartMoment = CurrentUniversalDateInMilliseconds();
			StandardSubsystemsServerCall.HideDesktopOnStart();
			AddIndicator(Parameters, StartMoment,
				"StandardSubsystemsServerCall.HideDesktopOnStart");
			Return False;
		EndIf;
	EndIf;
	
	If IsCallBeforeStart
	   And Common.SubsystemExists("CloudTechnology") Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		ErrorDescription = "";
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.OnCheckDataAreaLockOnStart(ErrorDescription);
		AddIndicator(Parameters, StartMoment,
			"SaaSOperations.OnCheckDataAreaLockOnStart");
		
		If Not IsBlankString(ErrorDescription) Then
			Parameters.Insert("DataAreaLocked", ErrorDescription);
			// Application will be closed.
			Return False;
		EndIf;
	EndIf;
	
	// Mandatory initialization of the session parameters.
	StartMoment = CurrentUniversalDateInMilliseconds();
	IBUpdateInProgress = SessionParameters.IBUpdateInProgress;
	AddIndicator(Parameters, StartMoment,
		"SessionParameters.IBUpdateInProgress");
	
	If IBUpdateInProgress <> Undefined
	   And Not Parameters.DataSeparationEnabled Then
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		UpdateRequired1 = InfobaseUpdate.InfobaseUpdateRequired();
		AddIndicator(Parameters, StartMoment,
			"InfobaseUpdate.InfobaseUpdateRequired");
		
		If UpdateRequired1 Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			UncompletedStatus = InfobaseUpdateInternal.UncompletedHandlersStatus(True) = "UncompletedStatus";
			AddIndicator(Parameters, StartMoment,
				"InfobaseUpdateInternal.UncompletedHandlersStatus");
			
			If UncompletedStatus Then
				Parameters.Insert("MustRunDeferredUpdateHandlers");
			EndIf;
		EndIf;
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		ModuleSafeModeManagerInternal.OnAddClientParametersOnStart(Parameters, True);
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"SafeModeManagerInternal.OnAddClientParametersOnStart");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("RetryDataExchangeMessageImportBeforeStart")
	   And Common.IsSubordinateDIBNode()
	   And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ModuleDataExchangeInternal = Common.CommonModule("DataExchangeInternal");
		If ModuleDataExchangeInternal.RetryDataExchangeMessageImportBeforeStart() Then
			Parameters.Insert("RetryDataExchangeMessageImportBeforeStart");
			Return False;
		EndIf;
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"DataExchangeInternal.RetryDataExchangeMessageImportBeforeStart");
	
	// Checking whether preliminary application parameter update is required.
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ApplicationParametersUpdateRequired")
	   And Not Parameters.Property("SimplifiedInfobaseUpdateForm") Then
		
		SubordinateDIBNodeSetup = False;
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		UpdateRequired1 = InformationRegisters.ApplicationRuntimeParameters.UpdateRequired1(SubordinateDIBNodeSetup);
		AddIndicator(Parameters, StartMoment,
			"InformationRegisters.ApplicationRuntimeParameters.UpdateRequired1");
		
		If UpdateRequired1 Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			// Preliminary update will be executed.
			Parameters.Insert("ApplicationParametersUpdateRequired");
			
			If SubordinateDIBNodeSetup
			   And Common.FileInfobase() Then
				
				ErrorTemplate =
					NStr("vi = 'Không thể đặt chế độ độc quyền để tùy chỉnh nút CSTTPT do nguyên nhân:
					           |%1';
					           |ru = 'Не удалось установить монопольный режим для настройки узла РИБ по причине:
					           |%1';
					           |en = 'Cannot enable the exclusive mode to set up the distributed infobase node due to:
					           |%1'; fa = 'Cannot enable the exclusive mode to set up the distributed infobase node due to:
					           |%1';
					           |it = 'Не удалось установить монопольный режим для настройки узла РИБ по причине:
					           |%1';
					           |pl = 'Cannot enable the exclusive mode to set up the distributed infobase node due to:
					           |%1';
					           |tr = 'DBT düğüm ayarı için monopoli modu şu nedenle kurulamadı:
					           |%1'");
				EnableExclusiveModeAtStartup(True, ErrorTemplate);
			EndIf;
			AddIndicator(Parameters, StartMoment,
				"StandardSubsystemsServer.EnableExclusiveModeAtStartup");
			Return False;
		EndIf;
	EndIf;
	
	// Mandatory parameters for all modes.
	Parameters.Insert("DetailedInformation", Metadata.DetailedInformation);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired() Then
		Parameters.Insert("SharedInfobaseDataUpdateRequired");
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		ModuleSafeModeManagerInternal.OnAddClientParametersOnStart(Parameters);
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"SafeModeManagerInternal.OnAddClientParametersOnStart");
	
	If Not Parameters.SeparatedDataUsageAvailable Then
		Return True;
	EndIf;
	
	// Parameters for the hosted mode and
	// for sessions in the SaaS mode with separators.
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	UpdateRequired1 = InfobaseUpdate.InfobaseUpdateRequired();
	AddIndicator(Parameters, StartMoment,
		"InfobaseUpdate.InfobaseUpdateRequired");
	
	If UpdateRequired1 Then
		Parameters.Insert("InfobaseUpdateRequired");
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		StandardSubsystemsServerCall.HideDesktopOnStart();
		AddIndicator(Parameters, StartMoment,
			"StandardSubsystemsServerCall.HideDesktopOnStart");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Not Parameters.DataSeparationEnabled
		And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		If ModuleDataExchangeServer.LoadDataExchangeMessage() Then
			Parameters.Insert("LoadDataExchangeMessage");
		EndIf;
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"DataExchangeServer.LoadDataExchangeMessage");
	
	Cancel = False;
	StartMoment = CurrentUniversalDateInMilliseconds();
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		If ModuleStandaloneMode.ContinueStandaloneWorkstationSetup(Parameters) Then
			Cancel = True;
		EndIf;
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"StandaloneMode.ContinueStandaloneWorkstationSetup");
	If Cancel Then
		Return False;
	EndIf;
	
	Cancel = False;
	If IsCallBeforeStart Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		UsersInternal.OnAddClientParametersOnStart(Parameters, Cancel, True);
		AddIndicator(Parameters, StartMoment,
			"UsersInternal.OnAddClientParametersOnStart(,,True)");
	EndIf;
	If Cancel Then
		Return False;
	EndIf;
	
	AddCommonClientParameters(Parameters);
	
	If IsCallBeforeStart Then
		// Do not add the other parameters until the update is completed
		// as those parameters may assume that the infobase is updated.
		If Parameters.Property("InfobaseUpdateRequired") Then
			Return False;
		EndIf;
		StartMoment = CurrentUniversalDateInMilliseconds();
		IsUpdateRunning = InfobaseUpdate.InfobaseUpdateInProgress();
		AddIndicator(Parameters, StartMoment,
			"InfobaseUpdate.InfobaseUpdateInProgress");
		If IsUpdateRunning Then
			Return False;
		EndIf;
	EndIf;
	
	EnableExclusiveModeAtStartup(False);
	
	Return True;
	
EndFunction

// Fills a parameter structure required for this subsystem
// client script execution. 
//
// Parameters:
//   Parameters - Structure
//
Procedure AddClientRunParameters(Parameters)
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("SubsystemsNames", StandardSubsystemsCached.SubsystemsNames());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsCached.SubsystemsNames");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("SeparatedDataUsageAvailable",
		Common.SeparatedDataUsageAvailable());
	AddIndicator(Parameters, StartMoment,
		"Common.SeparatedDataUsageAvailable");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());
	AddIndicator(Parameters, StartMoment,
		"Common.DataSeparationEnabled");
	
	// Outdated. Use StandardSubsystemsClient.IsBaseConfigurationVersion instead.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsBaseConfigurationVersion", IsBaseConfigurationVersion());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.IsBaseConfigurationVersion");
	
	// Outdated. Use StandardSubsystemsClient.IsTrainingPlatform instead.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsTrainingPlatform", IsTrainingPlatform());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.IsTrainingPlatform");
	
	// Obsolete. Use UsersClientServer.COMConnectorName instead.
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("COMConnectorName", CommonClientServer.COMConnectorName());
	AddIndicator(Parameters, StartMoment,
		"CommonClientServer.COMConnectorName");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("StyleItems", StyleElementsSet());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.StyleElementsSet");
	
	AddCommonClientParameters(Parameters);
	
	Parameters.Insert("ConfigurationName",     Metadata.Name);
	Parameters.Insert("ConfigurationSynonym", Metadata.Synonym);
	Parameters.Insert("ConfigurationVersion",  Metadata.Version);
	Parameters.Insert("DetailedInformation", Metadata.DetailedInformation);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("DefaultLanguageCode",   Common.DefaultLanguageCode());
	AddIndicator(Parameters, StartMoment,
		"Common.DefaultLanguageCode");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("AskConfirmationOnExit",
		AskConfirmationOnExit());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.AskConfirmationOnExit");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("FileInfobase", Common.FileInfobase());
	AddIndicator(Parameters, StartMoment,
		"Common.FileInfobase");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
		Parameters.Insert("OperationsWithExternalResourcesLocked");
	EndIf;
	AddIndicator(Parameters, StartMoment,
		"ScheduledJobsServer.OperationsWithExternalResourcesLocked");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("CompatibilityModeVersion", CompatibilityModeVersion());
	AddIndicator(Parameters, StartMoment,
		"StandardSubsystemsServer.CompatibilityModeVersion");
	
EndProcedure

// Fills a structure parameters required for client script execution when
// starting the application and later. 
//
// Parameters:
//   Parameters   - Structure - a parameter structure.
//
Procedure AddCommonClientParameters(Parameters)
	
	If Not Parameters.DataSeparationEnabled Or Parameters.SeparatedDataUsageAvailable Then
		
		SetPrivilegedMode(True);
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Parameters.Insert("AuthorizedUser", Users.AuthorizedUser());
		AddIndicator(Parameters, StartMoment,
			"Users.AuthorizedUser");
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Parameters.Insert("ApplicationCaption", TrimAll(Constants.SystemTitle.Get()));
		AddIndicator(Parameters, StartMoment,
			"Constants.SystemTitle.Get");
		
		SetPrivilegedMode(False);
		
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("IsMasterNode1", Not Common.IsSubordinateDIBNode());
	AddIndicator(Parameters, StartMoment,
		"Common.IsSubordinateDIBNode");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Parameters.Insert("DIBNodeConfigurationUpdateRequired",
		Common.SubordinateDIBNodeConfigurationUpdateRequired());
	AddIndicator(Parameters, StartMoment,
		"Common.SubordinateDIBNodeConfigurationUpdateRequired");
	
EndProcedure

// Intended to be called from "Common.GetInterfaceVersionsViaExternalConnection".
//
// Parameters:
//   InterfaceName - See "SupportedAPIVersions.InterfaceName"
//
// Returns:
//  String - "ValueToXMLString" from the outcome of the SupportedAPIVersions function.
//
Function SupportedVersions(InterfaceName) Export
	
	VersionsArray = SupportedVersionsOfAPI(InterfaceName);
	Return Common.ValueToXMLString(VersionsArray);
	
EndFunction

// Parameters:
//  Indicators - Undefined
//             - Array of String
//  StartMoment - Date
//  ProcedureName - String
//  Parameters - Undefined
//            - Structure
//  Shared - Boolean
//
Procedure AddMainIndicator(Indicators, StartMoment, ProcedureName,
			Parameters = Undefined, Shared = False) Export
	
	If Indicators = Undefined Then
		Return;
	EndIf;
	
	NestedIndicators = Undefined;
	If TypeOf(Parameters) = Type("Structure")
	   And Parameters.Property(PerformanceIndicatorsPropertyName()) Then
	
		NestedIndicators = Parameters[PerformanceIndicatorsPropertyName()];
	EndIf;
	
	Duration = CurrentUniversalDateInMilliseconds() - StartMoment;
	If Not Shared And Not ValueIsFilled(Duration) Then
		Return;
	EndIf;
	
	Text = Format(Duration / 1000, "ND=6; NFD=3; NZ=000,000; NLZ=") + " " + ProcedureName;
	
	If Shared Then
		Indicators.Insert(0, "    " + Text);
		NestedIndicators = Undefined;
	Else
		Indicators.Add("      " + Text);
	EndIf;
	
	If TypeOf(NestedIndicators) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each NestedIndicator In NestedIndicators Do
		Indicators.Add("  " + NestedIndicator);
	EndDo;
	NestedIndicators.Clear();
	
EndProcedure

Function PerformanceIndicatorsPropertyName()
	Return "PerformanceIndicators_";
EndFunction

// Sets the BlankHomePage common form on the desktop.
Procedure SetBlankFormOnHomePage() Export
	
	ObjectKey = "Common/HomePageSettings";
	CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	
	If TypeOf(CurrentSettings) = Type("HomePageSettings") Then
		CurrentFormComposition = CurrentSettings.GetForms();
		If CurrentFormComposition.RightColumn.Count() = 0
		   And CurrentFormComposition.LeftColumn.Count() = 1
		   And CurrentFormComposition.LeftColumn[0] = "CommonForm.BlankHomePage" Then
			Return;
		EndIf;
	EndIf;
	
	FormContent = New HomePageForms;
	FormContent.LeftColumn.Add("CommonForm.BlankHomePage");
	Settings = New HomePageSettings;
	Settings.SetForms(FormContent);
	SystemSettingsStorage.Save(ObjectKey, "", Settings);
	
EndProcedure

// Parameters:
//  Set - Boolean
//  ErrorTemplate - String
//
Procedure EnableExclusiveModeAtStartup(Set, ErrorTemplate = "")
	
	If Set And ExclusiveMode() Then
		Return;
	EndIf;
	
	ParameterName = "IsExclusiveModeEnabledAtStartup";
	
	SetPrivilegedMode(True);
	If Set Then
		Try
			SetExclusiveMode(True);
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
		
		CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
		CurrentParameters.Insert(ParameterName, True);
		SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
		
	ElsIf SessionParameters.ClientParametersAtServer.Get(ParameterName) <> Undefined Then
		
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
		
		CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
		CurrentParameters.Insert(ParameterName, True);
		SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

// The handler of the scheduled job with the same name.
//
Procedure IntegrationServicesProcessing() Export
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.IntegrationServicesProcessing);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	IntegrationServices.ExecuteProcessing();
EndProcedure

// Parameters:
//  UserName - String
//
// Returns:
//  Boolean
//
Function ShowWarningAboutInstalledUpdatesForUser(UserName = Undefined)
	
	Result = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"ShowInstalledApplicationUpdatesWarning",,,
		UserName);
	
	If Result = Undefined Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

#Region InfobaseUpdate

// Sets constants DoNotUseSeparationByDataAreas and StandardSubsystemsStandaloneMode.
// The constant values depend on the value of UseSeparationByDataAreas. 
//
Procedure SetConstantDoNotUseSeparationByDataAreas(Parameters) Export
	
	NewValues = New Map;
	If Constants.UseSeparationByDataAreas.Get() Then
		NewValues.Insert("DoNotUseSeparationByDataAreas", False);
		NewValues.Insert("StandardSubsystemsStandaloneMode", False);
	ElsIf Common.IsStandaloneWorkplace() Then
		NewValues.Insert("DoNotUseSeparationByDataAreas", False);
		NewValues.Insert("StandardSubsystemsStandaloneMode", True);
	Else
		NewValues.Insert("DoNotUseSeparationByDataAreas", True);
		NewValues.Insert("StandardSubsystemsStandaloneMode", False);
	EndIf;
	
	ThisDataExchangeInServiceModel = Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS");
	For Each NewValue In NewValues Do
		
		If ThisDataExchangeInServiceModel 
			And NewValue.Key = "StandardSubsystemsStandaloneMode" Then
			PreviousValue = Common.IsStandaloneWorkplace();
			// Always sync constant StandardSubsystemsStandaloneMode with IsStandaloneWorkplace. 
			Constants[NewValue.Key].Set(NewValue.Value); 
		Else
			PreviousValue = Constants[NewValue.Key].Get();
		EndIf;
		
		If PreviousValue <> NewValue.Value Then
				
			If Not Parameters.ExclusiveMode Then
				Parameters.ExclusiveMode = True;
				Return; // Set the exclusive mode to change the value.
			EndIf;
				
			Constants[NewValue.Key].Set(NewValue.Value);
			
			If ThisDataExchangeInServiceModel
				And NewValue.Key = "StandardSubsystemsStandaloneMode" 
				And PreviousValue Then
				ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
				ModuleStandaloneMode.DisablePropertyIB();
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Clears update date for each version cache record, so
// all version cache records become out-of-date.
//
Procedure MarkVersionCacheRecordsObsolete() Export
	
	BeginTransaction();
	Try
		RecordSet = InformationRegisters.ProgramInterfaceCache.CreateRecordSet();
		
		Block = New DataLock;
		Block.Add("InformationRegister.ProgramInterfaceCache");
		Block.Lock();
		
		RecordSet.Read();
		For Each Record In RecordSet Do
			Record.UpdateDate = Undefined;
		EndDo;
		
		InfobaseUpdate.WriteData(RecordSet);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure EnableConstantToDeliverServerAlertsWithoutInteractionSystem() Export
	
	Constants.DeliverServerNotificationsWithoutCollaborationSystem.Set(True);
	
EndProcedure

Procedure EnableConstantAllowAccessToInternetServices() Export
	
	Constants.AllowAccessToInternetServices.Set(True);
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Renamings) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.BasicAccess";
	NewName  = "Role.BasicAccessSSL";
	Common.AddRenaming(Renamings, "3.0.1.19", OldName, NewName, Library);
	
	OldName = "Role.ExternalUserBasicRights";
	NewName  = "Role.BasicAccessExternalUserSSL";
	Common.AddRenaming(Renamings, "3.0.1.19", OldName, NewName, Library);
	
	OldName = "Role.AllFunctionsMode";
	NewName  = "Role.TechnicianMode";
	Common.AddRenaming(Renamings, "3.1.5.153", OldName, NewName, Library);
	
EndProcedure

// Migrate data from the register "DeleteSafeDataAreaDataStorage"
// into the register "SafeDataAreaDataStorage".
//
Procedure MoveSafeDataAreaDataStorage() Export
	
	// SaaS mode is not supported.
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		DataArea = ModuleSaaSOperations.SessionSeparatorValue();
		
		RecordSet = InformationRegisters.SafeDataAreaDataStorage.CreateRecordSet();
		RecordSet.Filter.DataAreaAuxiliaryData.Set(DataArea);
		RecordSetDelete = InformationRegisters.ObsoleteSafeDataAreaDataStorage.CreateRecordSet();
		
		Block = New DataLock;
		Block.Add("InformationRegister.ObsoleteSafeDataAreaDataStorage");
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	ObsoleteSafeDataAreaDataStorage.Owner,
			|	ObsoleteSafeDataAreaDataStorage.Data
			|FROM
			|	InformationRegister.ObsoleteSafeDataAreaDataStorage AS ObsoleteSafeDataAreaDataStorage";
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			Record = RecordSet.Add();
			FillPropertyValues(
				Record,
				SelectionDetailRecords);
			Record.DataAreaAuxiliaryData = DataArea;
		EndDo;
		
		InfobaseUpdate.WriteData(RecordSet);
		InfobaseUpdate.WriteData(RecordSetDelete);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure SetIntegrationServicesLaunchSchedule() Export
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.WeeksPeriod = 1;
	Schedule.RepeatPeriodInDay = 60;
	
	JobParameters = New Structure;
	JobParameters.Insert("Schedule", Schedule);
	
	ScheduledJobsServer.SetScheduledJobParameters(
		Metadata.ScheduledJobs.IntegrationServicesProcessing, JobParameters);
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers

// Event Handler See EventSubscription.ProcessPredefinedItemsBeforeWrite
Procedure ProcessPredefinedItemsBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ThisIsPredefinedData(Source) Then
		Return;
	EndIf;
	
	DenySettingDeletionMarksToPredefinedItemsBeforeWrite(Source);
	
	InfobaseUpdateInternal.DetermineModifiedAttributesInPredefinedItems(Source);
	
EndProcedure

Procedure DenySettingDeletionMarksToPredefinedItemsBeforeWrite(Source)
	
	If Source.DeletionMark <> True Then
		Return;
	EndIf;
	
	AttributeName = "";
	AttributeValue = "";
	If Not ThisIsPredefinedData(Source, AttributeName, AttributeValue) Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Raise
			NStr("vi = 'Không cho phép tạo phần tử định trước đã đặt dấu xóa.';
				|ru = 'Недопустимо создавать предопределенный элемент, помеченный на удаление.';
				|en = 'Cannot create a predefined item that is marked for deletion.'; fa = 'Cannot create a predefined item that is marked for deletion.';
				|it = 'Non è consentito creare un elemento predefinito contrassegnato per la cancellazione.';
				|pl = 'Niedopuszczalne jest tworzenie predefiniowanego elementu zaznaczonego do usunięcia.';
				|tr = 'Silinmek üzere işaretlenmiş önceden tanımlanmış bir öğe oluşturulamıyor.'");
	EndIf;
	
	PreviousProperties = Common.ObjectAttributesValues(Source.Ref, 
		"DeletionMark, PredefinedDataName" 
			+ ?(AttributeName <> "PredefinedDataName", ", " + AttributeName, ""));
	
	If OwnerFilledOut(Source) Then
		ThisIsAPredefinedItem = ValueIsFilled(PreviousProperties.PredefinedDataName)
			Or (ValueIsFilled(AttributeName) And ValueIsFilled(PreviousProperties[AttributeName]));

		Disable = ThisIsAPredefinedItem 
			And PreviousProperties.DeletionMark <> True 
			And DeletionMarkValue(Source.Owner) <> True;
		If Disable Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cho phép đặt dấu xóa phần tử định trước:
				           |""%1"".';
				           |ru = 'Недопустимо помечать на удаление предопределенный элемент:
				           |""%1"".';
				           |en = 'Cannot mark the predefined item for deletion:
				           |""%1.""'; fa = 'Cannot mark the predefined item for deletion:
				           |""%1.""';
				           |it = 'Non è consentito contrassegnare un elemento predefinito per la cancellazione:
				           |""%1"".';
				           |pl = 'Niedopuszczalne jest oznaczanie na usuwanie predefiniowanego elementu:
				           |""%1"".';
				           |tr = 'Silinmek üzere önceden tanımlanmış 
				           |öğe işaretlenemez: %1'"),
				String(Source.Ref));
		EndIf;
	EndIf;

	IsSetPredefinedItemName = ValueIsFilled(AttributeValue) And Not ValueIsFilled(PreviousProperties[AttributeName])
		Or Not ValueIsFilled(PreviousProperties.PredefinedDataName);
	IsSetPredefinedItemNameInMarkedItem = IsSetPredefinedItemName And PreviousProperties.DeletionMark = True;
	If IsSetPredefinedItemNameInMarkedItem Then	
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cho phép liên kết với tên phần tử định trước đã đặt dấu xóa:
			           |""%1"".';
			           |ru = 'Недопустимо связывать с именем предопределенного элемент, помеченный на удаление:
			           |""%1"".';
			           |en = 'Cannot map a predefined item name to an item marked for deletion:
			           |""%1.""'; fa = 'Cannot map a predefined item name to an item marked for deletion:
			           |""%1.""';
			           |it = 'Non è consentito associare il nome di un elemento predefinito, contrassegnato per la cancellazione:
			           |""%1"".';
			           |pl = 'Niedopuszczalne jest powiązywać z nazwą predefiniowany element, zaznaczony na usunięcie:
			           |""%1"".';
			           |tr = 'Silinmek üzere işaretlenmiş olan öğeyi 
			           |önceden tanımlanmış isimle bağlamak kabul edilemez:%1.'"),
			String(Source.Ref));
	EndIf;

EndProcedure

// Event Handler See EventSubscription.DenyDeletingPredefinedItems
Procedure DenyPredefinedItemDeletionBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ThisIsPredefinedData(Source) Then
		Return;
	EndIf;
	
	If OwnerFilledOut(Source) Then
		If DeletionMarkValue(Source.Owner) <> False Then
			Return;
		EndIf;
	EndIf;

	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không được phép xóa phần tử định trước
			|""%1"".';
			|ru = 'Недопустимо удалять предопределенный элемент
			|""%1"".';
			|en = 'Cannot delete the predefined item 
			|""%1.""'; fa = 'Cannot delete the predefined item 
			|""%1.""';
			|it = 'Non è permesso cancellare l''elemento predefinito
			|""%1"".';
			|pl = 'Niedopuszczalne jest usuwać predefiniowany element
			|""%1"".';
			|tr = 'Önceden tanımlanmış öğe silinemez 
			|""%1"".'"),
		String(Source.Ref));
	
EndProcedure

#EndRegion

#Region DIBExchangePlanEventSubscriptionsHandling

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// For parameters, see the OnSendDataToSlave in Syntax Assistant.
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  InitialImageCreating - Boolean
// 
Procedure OnSendDataToSubordinateEvent(Source, DataElement, ItemSend, InitialImageCreating) Export
	
	OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Source);
	
	If ItemSend <> DataItemSend.Ignore Then
		// Calling an overridden handler to execute the applied logic of DIB exchange.
		CommonOverridable.OnSendDataToSlave(Source, DataElement, ItemSend, InitialImageCreating);
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// For parameters, see the OnSendDataToMaster event handler in Syntax Assistant.
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  
Procedure OnSendDataToMasterEvent(Source, DataElement, ItemSend) Export
	
	OnSendDataToMaster(DataElement, ItemSend, Source);
	
	If ItemSend <> DataItemSend.Ignore Then
		// Calling an overridden handler to execute the applied logic of DIB exchange.
		CommonOverridable.OnSendDataToMaster(Source, DataElement, ItemSend);
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// For parameters, see the OnReceiveDataFromSlave event handler in Syntax Assistant.
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
// 
Procedure OnReceiveDataFromSubordinateEvent(Source, DataElement, ItemReceive, SendBack) Export
	
	OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Source);
	
	If ItemReceive <> DataItemReceive.Ignore Then
		// Calling an overridden handler to execute the applied logic of DIB exchange.
		CommonOverridable.OnReceiveDataFromSlave(Source, DataElement, ItemReceive, SendBack);
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
// See the OnReceiveDataFromMaster event handler in Syntax Assistant.
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//
Procedure OnReceiveDataFromMasterEvent(Source, DataElement, ItemReceive, SendBack) Export
	
	OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Source);
	
	If ItemReceive <> DataItemReceive.Ignore Then
		// Calling an overridden handler to execute the applied logic of DIB exchange.
		CommonOverridable.OnReceiveDataFromMaster(Source, DataElement, ItemReceive, SendBack);
	EndIf;
	
EndProcedure

// WriteBefore event subscription handler for ExchangePlanObject.
// Is used for calling the AfterReceiveData event handler when exchanging in DIB.
// 
// Parameters:
//  Source - ExchangePlanObject
//  Cancel - Boolean
//
Procedure AfterGetData(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Source.Metadata().DistributedInfoBase Then
		Return;
	EndIf;
	
	If Source.IsNew()
		Or Source.ReceivedNo = Common.ObjectAttributeValue(Source.Ref, "ReceivedNo") Then
		Return;
	EndIf;
	
	GetFromMasterNode = (ExchangePlans.MasterNode() = Source.Ref);
	SSLSubsystemsIntegration.AfterGetData(Source, Cancel, GetFromMasterNode);
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Returns:
//  Array of MetadataObject
//
Function MetadataObjectsOfAllPredefinedData()
	
	DataSeparationEnabled  = Common.DataSeparationEnabled();
	IsSeparatedSession = Common.SeparatedDataUsageAvailable();
	
	MetadataCollections = New Array;
	MetadataCollections.Add(Metadata.Catalogs);
	MetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollections.Add(Metadata.ChartsOfAccounts);
	MetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
	MetadataObjects = New Array;
	
	For Each Collection In MetadataCollections Do
		For Each MetadataObject In Collection Do
			
			If DataSeparationEnabled Then 
				
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
				
				If (   IsSeparatedSession And Not IsSeparatedMetadataObject)
				 Or (Not IsSeparatedSession And    IsSeparatedMetadataObject) Then 
					Continue;
				EndIf;
				
			EndIf;
			
			MetadataObjects.Add(MetadataObject);
		EndDo;
	EndDo;
	
	Return MetadataObjects;
	
EndFunction

Procedure SetAllPredefinedDataInitialization(MetadataObjects)
	
	DataSeparationEnabled  = Common.DataSeparationEnabled();
	IsSeparatedSession = Common.SeparatedDataUsageAvailable();
	
	For Each MetadataObject In MetadataObjects Do
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Manager.SetPredefinedDataInitialization(True);
	EndDo;
	
	If Not DataSeparationEnabled Or Not IsSeparatedSession Then 
		SetInfoBasePredefinedDataUpdate(PredefinedDataUpdate.Auto);
	EndIf;
	
EndProcedure

Procedure CreateMissingPredefinedData(MetadataObjects)
	
	Query = New Query;
	QueryText =
		"SELECT
		|	SpecifiedTableAlias.Ref AS Ref,
		|	SpecifiedTableAlias.DataVersion AS DataVersion,
		|	ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """") AS ParentName,
		|	SpecifiedTableAlias.PredefinedDataName AS Name
		|FROM
		|	&CurrentTable AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Predefined";
	
	SavedItemsDescriptions = New Array;
	TablesWithoutSavedData = New Array;
	For Each MetadataObject In MetadataObjects Do
		
		If MetadataObject.PredefinedDataUpdate
				= Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		Query.Text = StrReplace(QueryText, "&CurrentTable", FullName);
		
		If Metadata.ChartsOfAccounts.Contains(MetadataObject)
		 Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
		 Or Not MetadataObject.Hierarchical Then
			
			Query.Text = StrReplace(Query.Text,
				"ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """")", """""");
		EndIf;
		
		// ACC:1328-off - No.648.1.1. An exclusive lock is set in the calling procedure.
		// @skip-check query-in-loop - Batch data processing
		NameTable = Query.Execute().Unload();
		// ACC:1328-on.
		NameTable.Indexes.Add("Name");
		Names = MetadataObject.GetPredefinedNames();
		SaveExistingPredefinedObjectsBeforeCreateMissingOnes(MetadataObject,
			FullName, NameTable, Names, Query, SavedItemsDescriptions, TablesWithoutSavedData);
	EndDo;
	
	// Restoring predefined items that were before the initialization.
	For Each SavedItemsDescription In SavedItemsDescriptions Do
		Manager = Common.ObjectManagerByFullName(SavedItemsDescription.FullName);
		Manager.SetPredefinedDataInitialization(False);
		InitializePredefinedData();
		
		Query.Text = SavedItemsDescription.QueryText;
		// ACC:1328-off - No.648.1.1. An exclusive lock is set in the calling procedure.
		// @skip-check query-in-loop - Batch data processing
		NameTable = Query.Execute().Unload();
		// ACC:1328-on.
		NameTable.Indexes.Add("Name");
		For Each SavedItemDescription In SavedItemsDescription.NameTable Do
			If Not SavedItemDescription.ObjectExist Then
				Continue;
			EndIf;
			String = NameTable.Find(SavedItemDescription.Name, "Name");
			If String <> Undefined Then
				NewObject = String.Ref.GetObject();
				If SavedItemsDescription.IsChartOfAccounts Then
					If SavedItemDescription.Object.DataVersion <> String.DataVersion Then
						UpdateTheInvoiceObject(SavedItemDescription.Object);
					EndIf;
					AddNewExtraAccountDimensionTypes(SavedItemDescription.Object, NewObject);
				EndIf;
				// ACC:1327-off - #648.1.1. An exclusive lock is set in the caller procedure.
				InfobaseUpdate.DeleteData(NewObject);
				// ACC:1327-off.
				String.Name = "";
			EndIf;
			// ACC:1327-off - #648.1.1. An exclusive lock is set in the caller procedure.
			InfobaseUpdate.WriteData(SavedItemDescription.Object);
			// ACC:1327-off.
		EndDo;
		For Each TableRow In NameTable Do
			If Not ValueIsFilled(TableRow.Name)
			 Or Not ValueIsFilled(TableRow.ParentName) Then
				Continue;
			EndIf;
			ParentLevelRow = DetailsOfSavedObject(SavedItemsDescription.NameTable, TableRow.ParentName);
			If ParentLevelRow <> Undefined Then
				NewObject = TableRow.Ref.GetObject();
				NewObject.Parent = ParentLevelRow.Ref;
				// ACC:1327-off - #648.1.1. An exclusive lock is set in the caller procedure.
				InfobaseUpdate.WriteData(NewObject);
				// ACC:1327-off.
			EndIf;
		EndDo;
	EndDo;
	
	For Each FullName In TablesWithoutSavedData Do
		Manager = Common.ObjectManagerByFullName(FullName);
		Manager.SetPredefinedDataInitialization(False);
	EndDo;
	
	InitializePredefinedData();
	
EndProcedure

// Parameters:
//  NameTable - ValueTable
//  ParentName - String
// 
// Returns:
//  ValueTableRow:
//   * Ref - CatalogRef
//   * Name - String
//   * DataVersion - String 
//   * ParentName - String
//   * Object - CatalogObject 
//   * ObjectExist - Boolean
//
Function DetailsOfSavedObject(NameTable, ParentName)
	Return NameTable.Find(ParentName, "Name");
EndFunction

// Parameters:
//  OldObject - ChartOfAccountsObject
//
Procedure UpdateTheInvoiceObject(OldObject)
	
	NewObject = OldObject.Ref.GetObject();
	NewObject.PredefinedDataName = OldObject.PredefinedDataName;
	For Each ExtraDimensionKindRow In OldObject.ExtDimensionTypes Do
		If ExtraDimensionKindRow.Predefined Then
			NewLineIExtDimensionType = NewObject.ExtDimensionTypes.Find(
				ExtraDimensionKindRow.ExtDimensionType, "ExtDimensionType");
			If NewLineIExtDimensionType <> Undefined Then
				NewLineIExtDimensionType.Predefined = True;
			EndIf;
		EndIf;
	EndDo;
	
	OldObject = NewObject;
	
EndProcedure

// Parameters:
//  Account - ChartOfAccountsObject
//  SampleAccount - ChartOfAccountsObject
// 
Procedure AddNewExtraAccountDimensionTypes(Account, SampleAccount)
	
	For Each ExtDimensionType In SampleAccount.ExtDimensionTypes Do
		IndexOf = SampleAccount.ExtDimensionTypes.IndexOf(ExtDimensionType);
		If Account.ExtDimensionTypes.Count() > IndexOf Then
			If Account.ExtDimensionTypes[IndexOf].ExtDimensionType <> ExtDimensionType.ExtDimensionType Then
				WriteLogEvent(
					NStr("vi = 'Trao đổi dữ liệu.Ngắt liên kết với nút chính';
						|ru = 'Обмен данными.Отключение связи с главным узлом';
						|en = 'Data exchange.Disconnection from the master node'; fa = 'Data exchange.Disconnection from the master node';
						|it = 'Scambio dati.Disabilitazione della comunicazione con il nodo principale';
						|pl = 'Wymiana danych.Wyłączenie połączenia z węzłem głównym';
						|tr = 'Veri alışverişi. Ana ünite ile bağlantının kesilmesi'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Account.Metadata(),
					Account,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong tài khoản ""%1"" khoản mục số %2 ""%3"" không trùng với khoản mục định trước ""%4"".';
							|ru = 'У счета ""%1"" субконто №%2 ""%3"" не совпадает с предопределенным субконто ""%4"".';
							|en = 'The extra dimension #%2 ""%3"" in chart of accounts ""%1"" does not match the predefined extra dimension ""%4.""'; fa = 'The extra dimension #%2 ""%3"" in chart of accounts ""%1"" does not match the predefined extra dimension ""%4.""';
							|it = 'Al conto ""%1"" sottoconto №%2 ""%3"" non corrisponde al sottoconto predefinito ""%4"".';
							|pl = 'Dla rachunku ""%1"" subkonto nr%2 ""%3"" nie zgadza się z subkontem predefiniowanym ""%4"".';
							|tr = '""%1"" hesabın %2 sayılı alt hesabı ""%3"" önceden tanımlanmış alt hesap ""%4"" ile aynı değildir.'"),
						String(Account),
						IndexOf + 1,
						String(Account.ExtDimensionTypes[IndexOf].ExtDimensionType),
						String(ExtDimensionType.ExtDimensionType)),
					EventLogEntryTransactionMode.Transactional);
			ElsIf Not Account.ExtDimensionTypes[IndexOf].Predefined Then
				Account.ExtDimensionTypes[IndexOf].Predefined = True;
			EndIf;
		Else
			FillPropertyValues(Account.ExtDimensionTypes.Add(), ExtDimensionType);
		EndIf;
	EndDo;
	
EndProcedure

Procedure SaveExistingPredefinedObjectsBeforeCreateMissingOnes(
		MetadataObject, FullName, NameTable, Names, Query, SavedItemsDescriptions, TablesWithoutSavedData)
	
	InitializationRequired = False;
	PredefinedItemsExist = False;
	NameTable.Columns.Add("ObjectExist", New TypeDescription("Boolean"));
	
	For Each Name In Names Do
		TableRows = NameTable.FindRows(New Structure("Name", Name));
		If TableRows.Count() = 0 Then
			InitializationRequired = True;
		Else
			For Each TableRow In TableRows Do
				TableRow.ObjectExist = True;
			EndDo;
			PredefinedItemsExist = True;
		EndIf;
	EndDo;
	
	If Not InitializationRequired Then
		Return;
	EndIf;
	
	If PredefinedItemsExist Then
		IsChartOfAccounts = Metadata.ChartsOfAccounts.Contains(MetadataObject);
		SavedItemsDescription = New Structure;
		SavedItemsDescription.Insert("FullName",     FullName);
		SavedItemsDescription.Insert("QueryText",  Query.Text);
		SavedItemsDescription.Insert("NameTable",   NameTable);
		SavedItemsDescription.Insert("IsChartOfAccounts", IsChartOfAccounts);
		SavedItemsDescriptions.Add(SavedItemsDescription);
		
		NameTable.Columns.Add("Object");
		For Each TableRow In NameTable Do
			Object = TableRow.Ref.GetObject();
			Object.PredefinedDataName = "";
			If IsChartOfAccounts Then
				PredefinedExtraDimensionKindRows = New Array;
				For Each ExtraDimensionKindRow In Object.ExtDimensionTypes Do
					If ExtraDimensionKindRow.Predefined Then
						ExtraDimensionKindRow.Predefined = False;
						PredefinedExtraDimensionKindRows.Add(ExtraDimensionKindRow);
					EndIf;
				EndDo;
			EndIf;
			// ACC:1327-off - #648.1.1. An exclusive lock is set in the caller procedure.
			InfobaseUpdate.WriteData(Object);
			// ACC:1327-off.
			If IsChartOfAccounts Then
				For Each ExtraDimensionKindRow In PredefinedExtraDimensionKindRows Do
					ExtraDimensionKindRow.Predefined = True;
				EndDo;
			EndIf;
			If TableRow.ObjectExist Then
				Object.PredefinedDataName = TableRow.Name;
			EndIf;
			TableRow.Object = Object;
		EndDo;
	Else
		TablesWithoutSavedData.Add(FullName);
	EndIf;
	
EndProcedure

// Intended for "SetSessionParameters" function.
Function AllSessionParametersAreSet(SessionParametersNames, SpecifiedParameters)
	
	If SessionParametersNames.Count() <> SpecifiedParameters.Count() Then
		Return False;
	EndIf;
	
	For Each ParameterName In SessionParametersNames Do
		If SpecifiedParameters.Find(ParameterName) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Procedure BeforeStartApplication()
	
	// Privileged mode (set by the 1C:Enterprise).
	
	If TimeConsumingOperations.ShouldSkipHandlerBeforeAppStartup() Then
		Return;
	EndIf;
	
	// Checking the default programming language set in the configuration.
	CurrentLanguageOf1CEnterpriseLanguage = Metadata.ObjectProperties.ScriptVariant["English"];
	If Metadata.ScriptVariant <> CurrentLanguageOf1CEnterpriseLanguage Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không hỗ trợ phương án ngôn ngữ hệ thống của cấu hình ""%1"".
			           |Hãy sử dụng phương án ngôn ngữ ""%2"".';
			           |ru = 'Вариант встроенного языка конфигурации ""%1"" не поддерживается.
			           |Используйте вариант языка ""%2"".';
			           |en = 'The built-in configuration language option ""%1"" is not supported.
			           |Use language option ""%2"" instead.'; fa = 'The built-in configuration language option ""%1"" is not supported.
			           |Use language option ""%2"" instead.';
			           |it = 'La variante del linguaggio incorporato di configurazione ""%1"" non è supportata.
			           |Utilizzare la variante del linguaggio ""%2"".';
			           |pl = 'Wariant wbudowanego języka konfiguracji ""%1"", nie jest obsługiwana.
			           |Używaj wariantu języka ""%2"".';
			           |tr = '""%1"" Konfigürasyonun 1C:Enterprise dil seçeneği desteklenmiyor.
			           |""%2"" dil seçeneğini kullanın.'"),
			Metadata.ScriptVariant,
			Metadata.ObjectProperties.ScriptVariant["English"]);
	EndIf;
	
	// Check for the minimum 1C:Enterprise version that does not support the app.
	SystemInfo = New SystemInfo;
	CurrentPlatformVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	MinPlatformVersion = Min1CEnterpriseVersionForStart();
	
	AssemblyNumbers = StrSplit(MinPlatformVersion, "; ", False);
	MinBuildNumberForCurrent1CEnterpriseVersion = AssemblyNumbers[AssemblyNumbers.UBound()];
	
	For Each BuildNumber In AssemblyNumbers Do
		If StrStartsWith(BuildNumber, CurrentPlatformVersion + ".") Then
			MinBuildNumberForCurrent1CEnterpriseVersion = BuildNumber;
			Break;
		EndIf;
	EndDo;
	
	If CommonClientServer.CompareVersions(SystemInfo.AppVersion, 
		MinBuildNumberForCurrent1CEnterpriseVersion) < 0 Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để khởi động, cần có phiên bản nền tảng 1C:Enterprise %1 hoặc cao hơn.';
				|ru = 'Для запуска необходима версия платформы 1С:Предприятие %1 или выше.';
				|en = 'The application requires 1C:Enterprise version %1 or later.'; fa = 'The application requires 1C:Enterprise version %1 or later.';
				|it = 'Per l''avvio è necessaria la versione della piattaforma 1C:Enterprise %1 o superiore.';
				|pl = 'Do uruchomienia wymagana jest wersja platformy 1C:Enterprise %1 lub wyżej.';
				|tr = '1C:Enterprise platformunun %1 veya daha yeni sürümü gerekiyor.'"), 
			MinBuildNumberForCurrent1CEnterpriseVersion);
	EndIf;
	
	// Check for supported compatibility modes.
	MinPlatformVersions = Min1CEnterpriseVersionForUse();
	MinPlatformVersion = MinPlatformVersions[MinPlatformVersions.Count() - 1].Value;
	CompatibilityModeVersion = Common.CompatibilityModeVersion();
	
	If MinPlatformVersions.FindByValue(CompatibilityModeVersion) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không hỗ trợ chế độ tương thích cấu hình với 1C:Enterprise phiên bản %1.
			           |Để khởi động, hãy đặt chế độ tương thích cấu hình ""Không sử dụng"" khi phát triển trên phiên bản %2
			           |(hoặc ""Phiên bản %2"" khi phát triển trên các phiên bản cũ hơn).';
			           |ru = 'Режим совместимости конфигурации с 1С:Предприятием версии %1 не поддерживается.
			           |Для запуска установите в конфигурации режим совместимости ""Не использовать"" при разработке на версии %2
			           |(или ""Версия %2"" при разработке на более старших версиях).';
			           |en = 'Configuration compatibility mode ""Version %1"" is not supported. 
			           |To start the application, set the compatibility mode to ""None"" (on 1C:Enterprise version %2)
			           | or to ""Version %2"" (on a later 1C:Enterprise version).'; fa = 'Configuration compatibility mode ""Version %1"" is not supported. 
			           |To start the application, set the compatibility mode to ""None"" (on 1C:Enterprise version %2)
			           | or to ""Version %2"" (on a later 1C:Enterprise version).';
			           |it = 'Il regime di compatibilità della configurazione con 1C:Enterprise versione %1 non è supportato.
			           |Per l''avvio, impostate nella configurazione il regime di compatibilità ""Non usare"" durante lo sviluppo sulla versione %2
			           |(o ""Versione %2"" durante lo sviluppo su versioni precedenti).';
			           |pl = 'Tryb zgodności konfiguracji z 1C:Przedsiębiorstwo wersji %1 nie jest obsługiwany.
			           |W celu uruchomienia należy ustawić w konfiguracji tryb zgodności ""Nie używać"" przy opracowywaniu wersji %2
			           |(lub ""Wersja %2"" w opracowaniu na starszych wersjach).';
			           |tr = 'Konfigürasyonun 1C:Enterprise %1sürümü ile eşleşme modu desteklenmiyor.
			           |Başlatmak için geliştirme sırasında %2
			           |sürümde (ya da ""Sürüm %2"" daha yeni sürümlerde geliştirme yaparken) konfigürasyonda ""Uygulanmasın"" eşleşme modunu ayarlayın.'"),
			CompatibilityModeVersion, MinPlatformVersion);
	EndIf;
	
	// Checking whether the configuration version is filled.
	If IsBlankString(Metadata.Version) Then
		Raise NStr("vi = 'Chưa điền thuộc tính của cấu hình Phiên bản.';
					|ru = 'Не заполнено свойство конфигурации Версия.';
					|en = 'The Version configuration property is blank.'; fa = 'The Version configuration property is blank.';
					|it = 'Il parametro della configurazione Versione non è compilato.';
					|pl = 'Nie wypełniona właściwość konfiguracji Wersja.';
					|tr = 'Yapılandırmanın Özellik Sürümü girilmemiş.'");
	EndIf;

	Try
		ZeroVersion = CommonClientServer.CompareVersions(Metadata.Version, "0.0.0.0") = 0;
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã điền sai thuộc tính cấu hình Phiên bản: ""%1"".
						|Ví dụ định dạng đúng là: ""1.2.3.45"".';
						|ru = 'Неправильно заполнено свойство конфигурации Версия: ""%1"".
						|Правильный формат, например: ""1.2.3.45"".';
						|en = 'The Version configuration property has invalid value: %1.
						|Use the following format: 1.2.3.45.'; fa = 'The Version configuration property has invalid value: %1.
						|Use the following format: 1.2.3.45.';
						|it = 'Неправильно заполнено свойство конфигурации Версия: ""%1"".
						|Правильный формат, например: ""1.2.3.45"".';
						|pl = 'The Version configuration property has invalid value: %1.
						|Use the following format: 1.2.3.45.';
						|tr = 'Sürüm konfigürasyon özelliği yanlış dolduruldu: ""%1"".
						|Doğru format örneği: ""1.2.3.45"".'"),
			Metadata.Version);
	EndTry;
	If ZeroVersion Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã điền sai thuộc tính cấu hình Phiên bản: ""%1"".
						|Phiên bản không thể bằng 0.';
						|ru = 'Неправильно заполнено свойство конфигурации Версия: ""%1"".
						|Версия не может быть нулевой.';
						|en = 'The Version configuration property has invalid value: %1.
						|The version cannot be zero.'; fa = 'The Version configuration property has invalid value: %1.
						|The version cannot be zero.';
						|it = 'Неправильно заполнено свойство конфигурации Версия: ""%1"".
						|Версия не может быть нулевой.';
						|pl = 'The Version configuration property has invalid value: %1.
						|The version cannot be zero.';
						|tr = 'Sürüm konfigürasyon özelliği yanlış dolduruldu: ""%1"".
						|Sürüm sıfır olamaz.'"),
			Metadata.Version);
	EndIf;
	
	If Not Metadata.DefaultRoles.Contains(Metadata.Roles.SystemAdministrator)
		Or Not Metadata.DefaultRoles.Contains(Metadata.Roles.FullAccess) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong cấu hình thuộc tính %1 chưa chỉ ra vai trò chuẩn %2 và %3.';
				|ru = 'В конфигурации в свойстве %1 не указаны стандартные роли %2 и %3.';
				|en = 'Standard roles %2 and %3 are not specified in property %1 in the configuration.'; fa = 'Standard roles %2 and %3 are not specified in property %1 in the configuration.';
				|it = 'Nella configurazione nella proprietà %1 non sono indicati i ruoli standard %2 e %3.';
				|pl = 'W konfiguracji we właściwości %1 nie są podane role standardowe %2 i %3.';
				|tr = '%1özelliğinin konfigürasyonunda %2 ve %3 standart roller belirtilmedi. '"),
			"DefaultRoles", Metadata.Roles.SystemAdministrator.Name, Metadata.Roles.FullAccess.Name);
	EndIf;
	
	// Checking whether the session parameter setting handlers for the application start can run.
	CheckIfCanStart();
	
	If Not ValueIsFilled(InfoBaseUsers.CurrentUser().Name)
	   And (Not Common.DataSeparationEnabled()
	      Or Not Common.SeparatedDataUsageAvailable())
	   And InfobaseUpdateInternal.IBVersion("StandardSubsystems",
	       Common.DataSeparationEnabled()) = "0.0.0.0" Then
		
		UsersInternal.SetInitialSettings("");
	EndIf;
	
	SSLSubsystemsIntegration.BeforeStartApplication();
	CommonOverridable.BeforeStartApplication();
	
	CorrectSharedUserHomePage();
	HandleCopiedSettingsQueue();
	
EndProcedure

// Configurations that are launched on earlier versions are blocked as the initialization code cannot be executed.
// A message is displayed prompting informing the user that 1C:Enterprise requires an update.
// This value must not be overridden unless a configuration supports only earlier versions of 1C:Enterprise.
// In this case, choose the version closest to the one returned by the function.
// 
// Returns:
//  String - Comma-delimited numbers of 1C:Enterprise builds.
//
Function Min1CEnterpriseVersionForStart() Export
	
	Return "8.3.24.1477"; // Must not be modified by patches.
	
EndFunction

// Returns supported compatibility modes and their related minimum 1C:Enterprise versions. See ReadMe.txt. 
// Configurations that are launched on earlier versions are blocked as the initialization code cannot be executed.
// (Such versions may lack some functionality, leading to errors and failures.)
// 
// 
//
// Returns:
//  ValueList:
//   * Value      - String - Supported compatibility mode.
//   * Presentation - String - Comma-delimited numbers of 1C:Enterprise builds.
//
Function Min1CEnterpriseVersionForUse() Export
	
	// It is not recommended to be modified by patches.
	Versions = New ValueList;
	Versions.Add("8.3.24", "8.3.24.1548; 8.3.25.1286; 8.3.26.1498; 8.3.27.1244");
	Versions.Add("8.3.25", "8.3.25.1286; 8.3.26.1498; 8.3.27.1244");
	Versions.Add("8.3.26", "8.3.26.1498; 8.3.27.1244");
	Versions.Add("8.3.27", "8.3.27.1688");
	
	Return Versions;
	
EndFunction

// Intended for procedure "ClarifyPlatformVersion".
// It contains revoked 1C:Enterprise versions and their replacements.
//
Function ReplacementVersionForRevoked1CEnterprise(CurrentBuild) Export
	
	Return "";
	
EndFunction

// This method is required by BeforeStartApplication procedure.
Procedure CorrectSharedUserHomePage()
	
	If CurrentRunMode() = Undefined
	 Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = False;
	EndIf;
	
	If Not SessionWithoutSeparators Then
		Return;
	EndIf;
	
	ObjectKey  = "Core";
	SettingsKey = "MetadataHomePageFormComposition";
	
	PreviousFormCompositionInMetadata = CommonSettingsStorage.Load(ObjectKey, SettingsKey);
	If PreviousFormCompositionInMetadata = Undefined Then
		// Clear the home page on the first login.
		SetBlankFormOnHomePage();
	Else
		SetBlankFormOnBlankHomePage();
	EndIf;
	
	// Compensation of form content change in the metadata of the home page.
	NewSettings1 = New HomePageSettings;
	FormCompositionInMetadata = NewSettings1.GetForms();
	
	If TypeOf(PreviousFormCompositionInMetadata) <> Type("Structure")
	 Or Not PreviousFormCompositionInMetadata.Property("LeftColumn")
	 Or TypeOf(PreviousFormCompositionInMetadata.LeftColumn) <> Type("Array")
	 Or Not PreviousFormCompositionInMetadata.Property("RightColumn")
	 Or TypeOf(PreviousFormCompositionInMetadata.RightColumn) <> Type("Array") Then
		
		PreviousFormCompositionInMetadata = New HomePageForms;
		
	ElsIf FormCompositionMatches(PreviousFormCompositionInMetadata.LeftColumn,  FormCompositionInMetadata.LeftColumn)
	        And FormCompositionMatches(PreviousFormCompositionInMetadata.RightColumn, FormCompositionInMetadata.RightColumn) Then
		
		// Form content in the metadata of the home page is not changed.
		Return;
	EndIf;
	
	CompensateChangesOfFormCompositionInHomePageMetadata(PreviousFormCompositionInMetadata);
	
	SavedFormCompositionInMetadata = New Structure("LeftColumn, RightColumn");
	FillPropertyValues(SavedFormCompositionInMetadata, FormCompositionInMetadata);
	
	CommonSettingsStorage.Save(ObjectKey, SettingsKey, SavedFormCompositionInMetadata);
	
EndProcedure

// This method is required by CorrectSharedUserHomePage procedure.
Function FormCompositionMatches(PreviousFormsInMetadata, FormsInMetadata)
	
	If PreviousFormsInMetadata.Count() <> FormsInMetadata.Count() Then
		Return False;
	EndIf;
	
	For Each FormName In FormsInMetadata Do
		If PreviousFormsInMetadata.Find(FormName) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// This method is required by CorrectSharedUserHomePage procedure.
Procedure CompensateChangesOfFormCompositionInHomePageMetadata(PreviousFormCompositionInMetadata)
	
	// The compensation takes into account that the home page settings
	// might have been saved when hiding the desktop.
	
	ObjectKey         = "Common/HomePageSettings";
	StorageObjectKey = "Common/HomePageSettingsBeforeClear";
	SavedSettings = SystemSettingsStorage.Load(StorageObjectKey, "");
	SettingsSaved   = TypeOf(SavedSettings) = Type("ValueStorage");
	
	If SettingsSaved Then
		CurrentSettings = SavedSettings.Get();
	Else
		CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	EndIf;
	If TypeOf(CurrentSettings) = Type("HomePageSettings") Then
		FormContent = CurrentSettings.GetForms();
	Else
		FormContent = New HomePageForms;
	EndIf;
	
	NewSettings1 = New HomePageSettings;
	FormCompositionInMetadata = NewSettings1.GetForms();
	
	DeleteNewHomePageForms(FormContent.LeftColumn,
		PreviousFormCompositionInMetadata.LeftColumn, FormCompositionInMetadata.LeftColumn);
	
	DeleteNewHomePageForms(FormContent.RightColumn,
		PreviousFormCompositionInMetadata.RightColumn, FormCompositionInMetadata.RightColumn);
	
	CurrentSettings = New HomePageSettings;
	CurrentSettings.SetForms(FormContent);
	
	If SettingsSaved Then
		SavingSettings = New ValueStorage(CurrentSettings, New Deflation(9));
		SystemSettingsStorage.Save(StorageObjectKey, "", SavingSettings);
		SetBlankFormOnHomePage();
	Else
		SystemSettingsStorage.Save(ObjectKey, "", CurrentSettings);
	EndIf;
	
EndProcedure

// This method is required by CompensateChangesOfFormContentInHomePageMetadata procedure.
Procedure DeleteNewHomePageForms(CurrentForms, PreviousFormsInMetadata, FormsInMetadata)
	
	For Each FormName In FormsInMetadata Do
		If PreviousFormsInMetadata.Find(FormName) <> Undefined Then
			Continue;
		EndIf;
		IndexOf = CurrentForms.Find(FormName);
		If IndexOf <> Undefined Then
			CurrentForms.Delete(IndexOf);
		EndIf;
	EndDo;
	
EndProcedure

Procedure HandleCopiedSettingsQueue()
	
	If CurrentRunMode() = Undefined Then
		Return;
	EndIf;
	
	SettingsQueue = CommonSettingsStorage.Load("SettingsQueue", "NotAppliedSettings");
	If TypeOf(SettingsQueue) <> Type("ValueStorage") Then
		Return;
	EndIf;
	SettingsQueue = SettingsQueue.Get();
	If TypeOf(SettingsQueue) <> Type("Map") Then
		Return;
	EndIf;
	
	For Each QueueItem In SettingsQueue Do
		Try
			Setting = SystemSettingsStorage.Load(QueueItem.Key, QueueItem.Value);
		Except
			Continue;
		EndTry;
		SystemSettingsStorage.Save(QueueItem.Key, QueueItem.Value, Setting);
	EndDo;
	
	CommonSettingsStorage.Save("SettingsQueue", "NotAppliedSettings", Undefined);
	
EndProcedure

Procedure ExecuteSessionParameterSettingHandlers(SessionParametersNames, Handlers, SpecifiedParameters)
	
	// An array with session parameter keys, which are set with the
	// parameter name start word followed by the asterisk ( * ).
	SessionParameterKeys = New Array;
	
	For Each Record In Handlers Do
		If StrFind(Record.Key, "*") > 0 Then
			ParameterKey = TrimAll(Record.Key);
			SessionParameterKeys.Add(Left(ParameterKey, StrLen(ParameterKey)-1));
		EndIf;
	EndDo;
	
	For Each ParameterName In SessionParametersNames Do
		If SpecifiedParameters.Find(ParameterName) <> Undefined Then
			Continue;
		EndIf;
		
		Handler = Handlers.Get(ParameterName);
		If Handler <> Undefined Then
			HandlerParameters = New Array();
			HandlerParameters.Add(ParameterName);
			HandlerParameters.Add(SpecifiedParameters);
			Common.ExecuteConfigurationMethod(Handler, HandlerParameters);
			Continue;
		EndIf;
		
		For Each ParameterKeyName In SessionParameterKeys Do
			If StrStartsWith(ParameterName, ParameterKeyName) Then
				Handler = Handlers.Get(ParameterKeyName + "*");
				HandlerParameters = New Array();
				HandlerParameters.Add(ParameterName);
				HandlerParameters.Add(SpecifiedParameters);
				Common.ExecuteConfigurationMethod(Handler, HandlerParameters);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure IgnoreSendingMetadataObjectIDs(DataElement, ItemSend, Val InitialImageCreating = False)
	
	If Not InitialImageCreating
		And MetadataObject(DataElement) = Metadata.Catalogs.MetadataObjectIDs Then
		
		ItemSend = DataItemSend.Ignore;
		
	EndIf;
	
EndProcedure

Procedure IgnoreGettingMetadataObjectIDs(DataElement, ItemReceive)
	
	If MetadataObject(DataElement) = Metadata.Catalogs.MetadataObjectIDs Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

Function MetadataObject(Val DataElement)
	
	Return ?(TypeOf(DataElement) = Type("ObjectDeletion"), DataElement.Ref.Metadata(), DataElement.Metadata());
	
EndFunction

Function InitialImageCreating(Val DataElement)
	
	Return ?(TypeOf(DataElement) = Type("ObjectDeletion"), False, DataElement.AdditionalProperties.Property("InitialImageCreating"));
	
EndFunction

Function ShowDeprecatedPlatformVersion(Parameters)
	
	If Parameters.DataSeparationEnabled Then
		Return False;
	EndIf;
	
	// Checking whether the user is not an external one.
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("IBUserID",
		InfoBaseUsers.CurrentUser().UUID);
	
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID = &IBUserID";
	
	If Not Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Current       = SystemInfo.AppVersion;
	Min   = Parameters.MinPlatformVersion;
	Recommended = Parameters.RecommendedPlatformVersion;
	
	Return CommonClientServer.CompareVersions(Current, Min) < 0
		Or CommonClientServer.CompareVersions(Current, Recommended) < 0;
	
EndFunction

Function DefaultAdministrationParameters()
	
	ClusterAdministrationParameters = ClusterAdministration.ClusterAdministrationParameters();
	IBAdministrationParameters = ClusterAdministration.ClusterInfobaseAdministrationParameters();
	
	// Join parameter structures.
	AdministrationParameterStructure = ClusterAdministrationParameters;
	For Each Item In IBAdministrationParameters Do
		AdministrationParameterStructure.Insert(Item.Key, Item.Value);
	EndDo;
	
	AdministrationParameterStructure.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", False);
	
	Return AdministrationParameterStructure;
	
EndFunction

Procedure ReadParametersFromConnectionString(AdministrationParameterStructure)
	
	ConnectionStringSubstrings = StrSplit(InfoBaseConnectionString(), ";");
	
	ServerNameString = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[0], 7));
	AdministrationParameterStructure.NameInCluster = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[1], 6));
	
	ClusterServerList = StrSplit(ServerNameString, ",");
	If ClusterServerList.Count() = 1 Then 
		ClusterServerList = StrSplit(ServerNameString, ";");
	EndIf;
	
	ServerName = ClusterServerList[0];
	
	// The only valid protocol is TCP. Skip it.
	If StrStartsWith(Upper(ServerName), "TCP://") Then
		ServerName = Mid(ServerName, 7);
	EndIf;
	
	// If an IPv6 address is passed as the server name, the port can go after the closing bracket (]) only.
	StartPosition = StrFind(ServerName, "]");
	If StartPosition <> 0 Then
		PortSeparator = StrFind(ServerName, ":",, StartPosition);
	Else
		PortSeparator = StrFind(ServerName, ":");
	EndIf;
	
	If PortSeparator > 0 Then
		ServerAgentAddress = Mid(ServerName, 1, PortSeparator - 1);
		ClusterPort = Number(Mid(ServerName, PortSeparator + 1));
		If AdministrationParameterStructure.ClusterPort = 1541 Then
			AdministrationParameterStructure.ClusterPort = ClusterPort;
		EndIf;
	Else
		ServerAgentAddress = ServerName;
	EndIf;
	
	AdministrationParameterStructure.ServerAgentAddress = ServerAgentAddress;
	
EndProcedure

// Checks whether handlers that set session parameters, 
// update handlers, and other basic mechanisms of configuration 
// that execute configuration code on the full procedure name can be executed.
//
// If the current settings of the security profiles (in the server cluster and in the infobase) 
// do not allow the handlers execution, an exception is generated
// that contains reason details and the list of actions to solve this problem.
//
Procedure CheckIfCanStart()
	
	If Common.FileInfobase(InfoBaseConnectionString()) Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
	Else
		InfobaseProfile = "";
	EndIf;
	
	Recommendation = NStr("vi = 'Để khôi phục hoạt động của ứng dụng, hãy xóa thuộc tính ""Hồ sơ bảo mật"" của cơ sở thông tin thông qua bảng điều khiển cluster server 1C:Enterprise, sau đó tùy chỉnh lại hồ sơ bảo mật trong bảng điều khiển: Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin Server - Sử dụng hồ sơ bảo mật.';
							|ru = 'Для восстановления работоспособности приложения, очистите свойство ""Профиль безопасности"" у информационной базы через консоль кластера серверов 1С:Предприятия и заново настройте профили безопасности в панели Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности.';
							|en = 'To fix the issue, clear the ""Security profile"" property using the 1C:Enterprise server cluster console. Then, reconfigure the security profiles in Administration > General settings > Server infobase parameters > Security profiles.'; fa = 'To fix the issue, clear the ""Security profile"" property using the 1C:Enterprise server cluster console. Then, reconfigure the security profiles in Administration > General settings > Server infobase parameters > Security profiles.';
							|it = 'To fix the issue, clear the ""Security profile"" property using the 1C:Enterprise server cluster console. Then, reconfigure the security profiles in Administration > General settings > Server infobase parameters > Security profiles.';
							|pl = 'To fix the issue, clear the ""Security profile"" property using the 1C:Enterprise server cluster console. Then, reconfigure the security profiles in Administration > General settings > Server infobase parameters > Security profiles.';
							|tr = 'Uygulamanın işlevselliğini geri kazandırmak için, 1C:Enterprise sunucu kümesi konsolu aracılığıyla infobase''teki ""Güvenlik profili"" özelliğini temizleyin ve Yönetim - Genel ayarlar - Sunucu bilgi tabanı parametreleri - Güvenlik profillerinin kullanımı panelinde güvenlik profillerini yeniden konfigüre edin.'");
	
	If ValueIsFilled(InfobaseProfile) Then
		
		// The infobase is configured so that the security profile
		// prohibits unlimited access to external modules.
		
		SetSafeMode(InfobaseProfile);
		If SafeMode() <> InfobaseProfile Then
			
			// The infobase profile is unavailable for running the handlers.
			
			SetSafeMode(False);
			
			Try
				PrivilegedModeAvailable = CanExecuteHandlersWithoutSafeMode();
			Except
				PrivilegedModeAvailable = False;
			EndTry;
			
			If Not PrivilegedModeAvailable Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong cơ sở thông tin có chỉ định tên hồ sơ bảo mật ""%1"" (Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin Server - Sử dụng hồ sơ bảo mật - Hồ sơ bảo mật cơ sở thông tin).
					           |
					           |Tuy nhiên, không thể đặt tham số phiên làm việc do nguyên nhân:
					           |Không có hồ sơ bảo mật ""%1"" trong cluster server 1C:Enterprise hoặc trong đó đã bỏ dấu hộp kiểm ""Có thể sử dụng làm hồ sơ bảo mật cho chế độ an toàn"".
					           |
					           |Có thể là, hồ sơ bảo mật đã được điều chỉnh thông qua bảng điều khiển cluster server 1C:Enterprise.';
					           |ru = 'В информационной базе указано имя профиля безопасности ""%1"" (Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности - Профиль безопасности информационной базы).
					           |
					           |Однако невозможно установить параметры сеанса по причине:
					           |Профиль безопасности ""%1"" отсутствует в кластере серверов 1С:Предприятия или у него отключен флажок ""Может использоваться, как профиль безопасности безопасного режима"".
					           |
					           |Возможно, профиль безопасности был отредактирован через консоль кластера серверов 1С:Предприятия.';
					           |en = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set because the profile ""%1"" is either missing from
					           |the 1C:Enterprise server cluster or its ""Use in safe mode"" option is disabled.
					           |
					           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.'; fa = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set because the profile ""%1"" is either missing from
					           |the 1C:Enterprise server cluster or its ""Use in safe mode"" option is disabled.
					           |
					           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
					           |it = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set because the profile ""%1"" is either missing from
					           |the 1C:Enterprise server cluster or its ""Use in safe mode"" option is disabled.
					           |
					           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
					           |pl = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set because the profile ""%1"" is either missing from
					           |the 1C:Enterprise server cluster or its ""Use in safe mode"" option is disabled.
					           |
					           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
					           |tr = 'Infobase''te güvenlik profili adı ""%1"" olarak belirtilmiş (Yönetim - Genel ayarlar - Sunucu bilgi tabanı parametreleri - Güvenlik profillerinin kullanımı - Bilgi tabanı güvenlik profili).
					           |
					           |Fakat oturum parametreleri, şu nedenlerden dolayı ayarlanamamaktadır:
					           |Güvenlik profili ""%1"" 1C:Enterprise sunucu kümesinde mevcut değil veya ""Güvenli mod güvenlik profili olarak kullanılabilir"" onay kutusu devre dışı bırakılmış.
					           |
					           |Güvenlik profili, 1C:Enterprise sunucu kümesinin konsolu üzerinden düzenlenmiş olabilir.'"),
					InfobaseProfile);
				
				Raise(ErrorText + Chars.LF + Chars.LF + Recommendation);
			EndIf;
			
		EndIf;
		
		If Not SwichingToPrivilegedModeAvailable() Then
			
			// Infobase profile allows the handler execution but the privileged mode cannot be set.
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong cơ sở thông tin có chỉ định tên hồ sơ bảo mật ""%1"" (Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin Server - Sử dụng hồ sơ bảo mật - Hồ sơ bảo mật cơ sở thông tin).
				           |
				           |Tuy nhiên, không thể đặt tham số phiên làm việc do nguyên nhân:
				           |Trong hồ sơ bảo mật ""%1"" đã bỏ dấu hộp kiểm ""Được phép truy cập đầy đủ vào chế độ đặc quyền"".
				           |
				           |Có thể là, hồ sơ bảo mật đã được điều chỉnh thông qua bảng điều khiển cluster server 1C:Enterprise.';
				           |ru = 'В информационной базе указано имя профиля безопасности ""%1"" (Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности - Профиль безопасности информационной базы).
				           |
				           |Однако невозможно установить параметры сеанса по причине:
				           |В профиле безопасности ""%1"" отключен флажок ""Разрешен полный доступ к привилегированному режиму"".
				           |
				           |Возможно, профиль безопасности был отредактирован через консоль кластера серверов 1С:Предприятия.';
				           |en = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
				           |
				           |However, session parameters cannot be set because the ""Full access to privileged mode"" option is disabled for the profile ""%1"".
				           |
				           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.'; fa = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
				           |
				           |However, session parameters cannot be set because the ""Full access to privileged mode"" option is disabled for the profile ""%1"".
				           |
				           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
				           |it = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
				           |
				           |However, session parameters cannot be set because the ""Full access to privileged mode"" option is disabled for the profile ""%1"".
				           |
				           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
				           |pl = 'The infobase specifies the security profile ""%1"" (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
				           |
				           |However, session parameters cannot be set because the ""Full access to privileged mode"" option is disabled for the profile ""%1"".
				           |
				           |Perhaps, the profile was modified via the 1C:Enterprise server cluster console.';
				           |tr = 'Infobase''te güvenlik profili adı ""%1"" olarak belirtilmiş (Yönetim - Genel ayarlar - Sunucu infobase parametreleri - Güvenlik profillerinin kullanımı - Infobase güvenlik profili).
				           |
				           |Ancak, ""%1"" güvenlik profili için 
				           |""Ayrıcalıklı moda tam erişim"" seçeneği devre dışı bırakıldığından oturum parametreleri ayarlanamaz.
				           |
				           |Belki güvenlik profili, 1C:Enterprise sunucu kümesi konsolu aracılığıyla değiştirilmiş olabilir.'"),
				InfobaseProfile);
			
			Raise(ErrorText + Chars.LF + Chars.LF + Recommendation);
		EndIf;
		
	Else
		
		// The infobase is configured so that the security profile
		// cannot prohibit unlimited access to external modules.
		
		Try
			PrivilegedModeAvailable = CanExecuteHandlersWithoutSafeMode();
		Except
			If ModuleSafeModeManager <> Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong cơ sở thông tin chưa chỉ định tên hồ sơ bảo mật (Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin server - Sử dụng hồ sơ bảo mật - Hồ sơ bảo mật của cơ sở thông tin).
					           |
					           |Tuy nhiên, không thể thiết lập các tham số phiên làm việc, do:
					           |%1.
					           |
					           |Có thể là trong cluster 1C:Enterprise, thuộc tính ""Hồ sơ bảo mật"" của cơ sở thông tin đã được chỉ định tên hồ sơ, nhưng tên này lại không được chỉ định trong chính cơ sở thông tin (Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin server - Sử dụng hồ sơ bảo mật - Hồ sơ bảo mật của cơ sở thông tin).';
					           |ru = 'В информационной базе не указано имя профиля безопасности (Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности - Профиль безопасности информационной базы).
					           |
					           |Однако невозможно установить параметры сеанса по причине:
					           |%1.
					           |
					           |Вероятно, в кластере серверов 1С:Предприятия у информационной базы в свойстве ""Профиль безопасности"" указано имя профиля, но это имя не указано в самой информационной базе (Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности - Профиль безопасности информационной базы).';
					           |en = 'The infobase does not specify a security profile (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.'; fa = 'The infobase does not specify a security profile (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.';
					           |it = 'The infobase does not specify a security profile (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.';
					           |pl = 'The infobase does not specify a security profile (Administration > General settings > Server infobase parameters > Security profiles > Infobase security profile).
					           |
					           |However, session parameters cannot be set due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.';
					           |tr = 'Infobase''te güvenlik profilinin adı belirtilmemiş (Yönetim - Genel ayarlar - Sunucu infobase''i parametreleri - Güvenlik profillerinin kullanımı - Infobase güvenlik profili).
					           |
					           |Fakat oturum parametreleri, şu sebeple ayarlanamamaktadır:
					           |%1 .
					           |
					           |Muhtemelen, 1C: Enterprise sunucu kümesinde infobase''in ""Güvenlik profili"" özelliğinde profil adı belirtilmiş, fakat bu ad infobase''te belirtilmemiştir (Yönetim - Genel ayarlar - Sunucu infobase parametreleri - Güvenlik profillerinin kullanımı - Infobase güvenlik profili) .'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				
				Raise(ErrorText + Chars.LF + Chars.LF + Recommendation);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể thiết lập tham số phiên làm việc do:
					           |%1.
					           |
					           |Rất có thể trong cluster server 1C:Enterprise, ở phần thuộc tính ""Hồ sơ bảo mật"" của cơ sở thông tin đang được chỉ định một hồ sơ bảo mật, trong đó bỏ chọn hộp kiểm ""Cho phép truy cập đầy đủ đến các mô-đun bên ngoài"".
					           |Hộp kiểm ""Cho phép truy cập đầy đủ đến các mô-đun bên ngoài"" là cần thiết, vì trong ứng dụng không có phân hệ ""Hồ sơ bảo mật"" (Quản trị - Tùy chỉnh chung - Tham số cơ sở thông tin server - Sử dụng hồ sơ bảo mật).
					           |
					           |Để khôi phục hoạt động bình thường của ứng dụng, hãy xóa thuộc tính ""Hồ sơ bảo mật"" của cơ sở thông tin thông qua bảng điều khiển cluster server 1C:Enterprise, hoặc đặt dấu dấu hộp kiểm ""Cho phép truy cập đầy đủ đến các mô-đun bên ngoài"" trong hồ sơ bảo mật.';
					           |ru = 'Невозможно установить параметры сеанса по причине:
					           |%1.
					           |
					           |Вероятно, в кластере серверов 1С:Предприятия у информационной базы в свойстве ""Профиль безопасности"" указан профиль безопасности, в котором отключен флажок ""Разрешен полный доступ к внешним модулям"".
					           |Флажок ""Разрешен полный доступ к внешним модулям"" требуется, так как в приложении нет подсистемы ""Профили безопасности"" (Администрирование - Общие настройки - Параметры серверной информационной базы - Использование профилей безопасности).
					           |
					           |Для восстановления работоспособности приложения, очистите свойство ""Профиль безопасности"" у информационной базы через консоль кластера серверов 1С:Предприятия, либо включите у профиля безопасности флажок ""Разрешен полный доступ к внешним модулям"".';
					           |en = 'Cannot set session parameters due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.
					           |This option is required because the the ""Security profiles"" subsystem is not integrated into the application.
					           |
					           |To fix the issue, either clear the ""Security profile"" property for the infobase via the 1C:Enterprise server cluster console, or enable the ""Full access to external modules"" option for the assigned profile.'; fa = 'Cannot set session parameters due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.
					           |This option is required because the the ""Security profiles"" subsystem is not integrated into the application.
					           |
					           |To fix the issue, either clear the ""Security profile"" property for the infobase via the 1C:Enterprise server cluster console, or enable the ""Full access to external modules"" option for the assigned profile.';
					           |it = 'Cannot set session parameters due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.
					           |This option is required because the the ""Security profiles"" subsystem is not integrated into the application.
					           |
					           |To fix the issue, either clear the ""Security profile"" property for the infobase via the 1C:Enterprise server cluster console, or enable the ""Full access to external modules"" option for the assigned profile.';
					           |pl = 'Cannot set session parameters due to:
					           |%1.
					           |
					           |Perhaps, the server cluster configuration specifies a security profile for the infobase, but this profile is not set in the infobase.
					           |This option is required because the the ""Security profiles"" subsystem is not integrated into the application.
					           |
					           |To fix the issue, either clear the ""Security profile"" property for the infobase via the 1C:Enterprise server cluster console, or enable the ""Full access to external modules"" option for the assigned profile.';
					           |tr = 'Oturum parametreleri, şu sebeple ayarlanamamaktadır:
					           |%1 .
					           |
					           |Muhtemelen, 1C: Enterprise sunucu kümesinde infobase''in ""Güvenlik profili"" özelliğinde profil adı belirtilmiş, fakat bu ad infobase''te belirtilmemiştir (Yönetim - Genel ayarlar - Sunucu infobase parametreleri - Güvenlik profillerinin kullanımı - Infobase güvenlik profili).
					           |Büyük ihtimalle 1C:Enterprise sunucu kümesinde infobase''in ""Güvenlik profili"" özelliğinde, ""Harici modüllere tam erişim izin verildi"" onay kutusunun işaretli olmadığı bir güvenlik profili belirtilmiş olabilir. ""Harici modüllere tam erişim izni verildi"" seçeneği zorunludur, çünkü uygulamada ""Güvenlik profilleri"" alt sistemi mevcut değildir (Yönetim - Genel ayarlar - Sunucu infobase''i parametreleri - Güvenlik profillerinin kullanımı).
					           |
					           |Uygulamanın bu fonksiyonunu geri yüklebilmek için, 1C:Enterprise sunucu kümesi konsolu aracılığıyla infobase''indeki ""Güvenlik profili"" özelliğini temizleyin veya güvenlik profilinde “Harici modüllere tam erişim izin verilir"" seçeneğini etkinleştirin.'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				
				Raise(ErrorText);
			EndIf;
		EndTry;
		
	EndIf;
	
EndProcedure

// Checks whether the handlers can be executed without safe mode.
//
// Returns:
//   Boolean
//
Function CanExecuteHandlersWithoutSafeMode()
	
	// Do not call "Common.CalculateInSafeMode" since the privileged
	// mode usage in the "Evaluate" function is checked in unsafe mode.
	Return Eval("SwichingToPrivilegedModeAvailable()"); // ACC:488
		
EndFunction

// Checks whether the privileged mode can be set from the current safe mode.
//
// Returns:
//   Boolean
//
Function SwichingToPrivilegedModeAvailable()
	
	SetPrivilegedMode(True);
	Return PrivilegedMode();
	
EndFunction

// This method is required by RegisterPriorityDataChangeForSubordinateDIBNode procedure.
Procedure RegisterPredefinedItemChanges(DIBExchangePlansNodes, MetadataCollection)
	
	Query = New Query;
	
	For Each MetadataObject In MetadataCollection Do
		DIBNodes = New Array;
		
		For Each ExchangePlanNodes In DIBExchangePlansNodes Do
			If Not ExchangePlanNodes.Key.Contains(MetadataObject) Then
				Continue;
			EndIf;
			For Each DIBNode In ExchangePlanNodes.Value Do
				DIBNodes.Add(DIBNode);
			EndDo;
		EndDo;
		
		If DIBNodes.Count() = 0 Then
			Continue;
		EndIf;
		
		Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
		Query.Text = StrReplace(Query.Text, "&CurrentTable", MetadataObject.FullName());
		// @skip-check query-in-loop - Batch data processing
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			ExchangePlans.RecordChanges(DIBNodes, Selection.Ref);
		EndDo;
	EndDo;
	
EndProcedure

// This method is required by SetFormAssignmentKey procedure.
Procedure SetFormAssignmentUsageKey(Form, Var_Key, SetSettings)
	
	If Not ValueIsFilled(Var_Key)
	 Or Form.PurposeUseKey = Var_Key Then
		
		Return;
	EndIf;
	
	If Not SetSettings Then
		Form.PurposeUseKey = Var_Key;
		Return;
	EndIf;
	
	SettingsTypes1 = New Array;
	// Translated English variant.
	SettingsTypes1.Add("/CurrentVariantKey");
	SettingsTypes1.Add("/CurrentUserSettingsKey");
	SettingsTypes1.Add("/CurrentUserSettings");
	SettingsTypes1.Add("/CurrentDataSettingsKey");
	SettingsTypes1.Add("/CurrentData");
	SettingsTypes1.Add("/FormSettings");
	// Original English variant.
	SettingsTypes1.Add("/CurrentVariantKey");
	SettingsTypes1.Add("/CurrentUserSettingsKey");
	SettingsTypes1.Add("/CurrentUserSettings");
	SettingsTypes1.Add("/CurrentDataSettingsKey");
	SettingsTypes1.Add("/CurrentData");
	SettingsTypes1.Add("/FormSettings");
	If SystemSettingsStorage.Load(Var_Key, "FormAssignmentRuleKey") <> True 
		 And AccessRight("SaveUserData", Metadata) Then
		SetSettingsForKey(Var_Key, SettingsTypes1, Form.FormName, Form.PurposeUseKey);
		SystemSettingsStorage.Save(Var_Key, "FormAssignmentRuleKey", True);
	EndIf;
	
	Form.PurposeUseKey = Var_Key;
	
EndProcedure

// This method is required by SetFormAssignmentKey procedure.
Procedure SetFormWindowOptionsSaveKey(Form, Var_Key, SetSettings)
	
	If Not ValueIsFilled(Var_Key)
	 Or Form.WindowOptionsKey = Var_Key Then
		
		Return;
	EndIf;
	
	If Not SetSettings Then
		Form.WindowOptionsKey = Var_Key;
		Return;
	EndIf;
	
	SettingsTypes1 = New Array;
	// Translated English variant.
	SettingsTypes1.Add("/НастройкиОкнаТонкогоКлиента"); // @Non-NLS
	SettingsTypes1.Add("/Такси/НастройкиОкнаТонкогоКлиента"); // @Non-NLS
	SettingsTypes1.Add("/НастройкиОкнаВебКлиента"); // @Non-NLS
	SettingsTypes1.Add("/Такси/НастройкиОкнаВебКлиента"); // @Non-NLS
	// @Non-NLS
// The English version.
	SettingsTypes1.Add("/ThinClientWindowSettings");
	SettingsTypes1.Add("/Taxi/ThinClientWindowSettings");
	SettingsTypes1.Add("/WebClientWindowSettings");
	SettingsTypes1.Add("/Taxi/WebClientWindowSettings");
	
	If SystemSettingsStorage.Load(Var_Key, "FormWindowOptionsKey") <> True 
		And AccessRight("SaveUserData", Metadata) Then
		SetSettingsForKey(Var_Key, SettingsTypes1, Form.FormName, Form.WindowOptionsKey);
		SystemSettingsStorage.Save(Var_Key, "FormWindowOptionsKey", True);
	EndIf;
	
	Form.WindowOptionsKey = Var_Key;
	
EndProcedure

// This method is required by SetFormAssignmentUseKey and SetFormWindowOptionsSaveKey procedures.
Procedure SetSettingsForKey(Var_Key, SettingsTypes1, FormName, CurrentKey)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	NewKey = "/" + Var_Key;
	Filter = New Structure;
	Filter.Insert("User", InfoBaseUsers.CurrentUser().Name);
	
	For Each SettingsType1 In SettingsTypes1 Do
		Filter.Insert("ObjectKey", FormName + NewKey + SettingsType1);
		Selection = SystemSettingsStorage.Select(Filter);
		If Selection.Next() Then
			Return; // Key settings are already set.
		EndIf;
	EndDo;
	
	If ValueIsFilled(CurrentKey) Then
		CurrentKey = "/" + CurrentKey;
	EndIf;
	
	// Setting the initial settings key by copying them from the current key.
	For Each SettingsType1 In SettingsTypes1 Do
		Filter.Insert("ObjectKey", FormName + CurrentKey + SettingsType1);
		Selection = SystemSettingsStorage.Select(Filter);
		ObjectKey = FormName + NewKey + SettingsType1;
		While Selection.Next() Do
			SettingsDescription = New SettingsDescription;
			SettingsDescription.Presentation = Selection.Presentation;
			SystemSettingsStorage.Save(ObjectKey, Selection.SettingsKey,
				Selection.Settings, SettingsDescription);
		EndDo;
	EndDo;
	
EndProcedure

// Check server notifications and send them to client.

// See OnReceiptRecurringClientDataOnServer
Procedure ConfigurationOrExtensionModifiedDuringRepeatedCheck(UserMessage)
	
	
	SetPrivilegedMode(True);
	
	UserName = InfoBaseUsers.CurrentUser().Name;
	
	YouCanNotify = ShowWarningAboutInstalledUpdatesForUser(UserName);
	If Not YouCanNotify Then
		Return;
	EndIf;
	
	DateRemindTomorrow = Common.SystemSettingsStorageLoad(
		"DynamicUpdateControl", "DateRemindTomorrow",,, UserName);
	
	If TypeOf(DateRemindTomorrow) = Type("Date")
	   And CurrentSessionDate() < DateRemindTomorrow Then
		Return;
	EndIf;
	
	DataBaseConfigurationChangedDynamically = DataBaseConfigurationChangedDynamically();
	DynamicChanges = Catalogs.ExtensionsVersions.DynamicallyChangedExtensions(
		Catalogs.ExtensionsVersions.InstalledExtensionsOnStartup(), True);
	
	If Not DataBaseConfigurationChangedDynamically
	   And Not ValueIsFilled(DynamicChanges.Extensions)
	   And Not ValueIsFilled(DynamicChanges.Corrections) Then
		Return;
	EndIf;
	
	If DynamicChanges.Corrections <> Undefined
		And DynamicChanges.Extensions = Undefined
		And Not DataBaseConfigurationChangedDynamically
		// Only the list of patches is changed. Check that notifications can be displayed.
		And DynamicChanges.Corrections.Added2 <> 0
		And DynamicChanges.Corrections.Deleted = 0 Then
	
		NotificationSchedule = Common.SystemSettingsStorageLoad(
			"DynamicUpdateControl", "PatchCheckSchedule",,, UserName);
		
		If TypeOf(NotificationSchedule) = Type("Structure")
			And NotificationSchedule.Property("Schedule")
			And TypeOf(NotificationSchedule.Schedule) = Type("JobSchedule") Then
			
			CurrentSessionDate = CurrentSessionDate();
			YouCanNotify = NotificationSchedule.Schedule.ExecutionRequired(CurrentSessionDate,
				NotificationSchedule.LastAlert);
			
			If YouCanNotify Then
				NotificationSchedule.LastAlert = CurrentSessionDate;
				Common.SystemSettingsStorageSave("DynamicUpdateControl",
					"PatchCheckSchedule", NotificationSchedule,, UserName);
			EndIf;
		Else
			OnceADay = New JobSchedule;
			OnceADay.DaysRepeatPeriod = 1;
			
			PatchCheckSchedule = New Structure;
			PatchCheckSchedule.Insert("Id", "Once");
			PatchCheckSchedule.Insert("Presentation", NStr("vi = 'một lần một ngày';
															|ru = 'один раз в день';
															|en = 'Once a day'; fa = 'Once a day';
															|it = 'una volta al giorno';
															|pl = 'raz dziennie';
															|tr = 'günde bir defa'"));
			PatchCheckSchedule.Insert("Schedule", OnceADay);
			PatchCheckSchedule.Insert("LastAlert", CurrentSessionDate());

			Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule", PatchCheckSchedule);
		EndIf;
	EndIf;
	
	If Not YouCanNotify Then
		Return;
	EndIf;
	
	DynamicChanges.Insert("DataBaseConfigurationChangedDynamically",
		DataBaseConfigurationChangedDynamically);
		
	Messages = New Array;
	Messages.Add(MessageTextOnDynamicUpdate(DynamicChanges));
	Messages.Add(NStr("vi = 'Hãy nhấn ở đây để áp dụng hoặc hoãn áp dụng chỉnh sửa.';
						|ru = 'Нажмите здесь, чтобы применить или отложить применение исправлений.';
						|en = 'Click here to start or postpone patch application.'; fa = 'Click here to start or postpone patch application.';
						|it = 'Нажмите здесь, чтобы применить или отложить применение исправлений.';
						|pl = 'Click here to start or postpone patch application.';
						|tr = 'Yamaları uygulamak veya uygulamayı ertelemek için buraya tıklayın.'"));
	UserMessage = StrConcat(Messages, Chars.LF);
	
EndProcedure

// See OnSendServerNotification
Procedure OnSendServerNotificationFunctionalOptionsModified(NameOfAlert, ParametersVariants)
	
	ParameterName = "StandardSubsystems.Core.EnabledFunctionalOptions";
	PreviousValue2 = ExtensionParameter(ParameterName, True);
	
	NewTypeCollection = New Array;
	FunctionalOptionsByTypes = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		StorageObject = FunctionalOption.Location;
		If Not Metadata.Constants.Contains(StorageObject) Then
			Continue;
		EndIf;
		Type = Type("ConstantManager." + StorageObject.Name);
		FunctionalOptionsByTypes.Insert(Type, FunctionalOption);
		If GetFunctionalOption(FunctionalOption.Name) = True Then
			NewTypeCollection.Add(Type);
		EndIf;
	EndDo;
	NewValue = New TypeDescription(NewTypeCollection);
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	If TypeOf(PreviousValue2) = Type("TypeDescription") Then
		TypesChangeList = New Map;
		For Each Type In NewValue.Types() Do
			TypesChangeList.Insert(Type, True);
		EndDo;
		For Each Type In PreviousValue2.Types() Do
			If TypesChangeList.Get(Type) = Undefined Then
				TypesChangeList.Insert(Type, True);
			Else
				TypesChangeList.Delete(Type);
			EndIf;
		EndDo;
		
		Objects = New Map;
		For Each KeyAndValue In TypesChangeList Do
			FunctionalOption = FunctionalOptionsByTypes.Get(KeyAndValue.Key);
			If FunctionalOption = Undefined Then
				Continue;
			EndIf;
			AddFunctionalOptionObjects(Objects, FunctionalOption);
		EndDo;
		
		Recipients = New Map;
		For Each ParametersVariant In ParametersVariants Do
			For Each Addressee In ParametersVariant.Recipients Do
				IBUser = InfoBaseUsers.FindByUUID(Addressee.Key);
				If IBUser = Undefined Then
					Continue;
				EndIf;
				For Each KeyAndValue In Objects Do
					If AccessRight(KeyAndValue.Value, KeyAndValue.Key, IBUser) Then
						Recipients.Insert(Addressee.Key, Addressee.Value);
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		If ValueIsFilled(Recipients) Then
			ServerNotifications.SendServerNotification(NameOfAlert, "", Recipients);
		EndIf;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		PreviousValue2 = ExtensionParameter(ParameterName, True);
		If PreviousValue2 <> NewValue Then
			SetExtensionParameter(ParameterName, NewValue, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure AddFunctionalOptionObjects(Objects, FunctionalOption)
	
	BaseTypesNames =
	"
	|Subsystem
	|CommonAttribute
	|ExchangePlan
	|FilterCriterion
	|CommonForm
	|CommonCommand
	|Constant
	|Catalog
	|Document
	|DocumentJournal
	|Report
	|DataProcessor
	|ChartOfCharacteristicTypes
	|ChartOfAccounts
	|ChartOfCalculationTypes
	|InformationRegister
	|AccumulationRegister
	|AccountingRegister
	|CalculationRegister
	|BusinessProcess
	|Task
	|";
	
	For Each CompositionItem In FunctionalOption.Content Do
		Object = CompositionItem.Object;
		If Objects.Get(Object) <> Undefined
		 Or TypeOf(Object) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		Try
			FullName = Object.FullName();
		Except
			FullName = "";
		EndTry;
		NameParts = StrSplit(FullName, ".", False);
		If NameParts.Count() < 2 Then
			Continue;
		EndIf;
		BaseTypeName = NameParts[0];
		If StrFind(BaseTypesNames, Chars.LF + BaseTypeName + Chars.LF) = 0 Then
			Continue;
		EndIf;
		If NameParts.Count() > 2 Then
			If BaseTypeName <> "Subsystem" Then
				Object = Common.MetadataObjectByFullName(NameParts[0] + "." + NameParts[1]);
				If Object = Undefined
				 Or Objects.Get(Object) <> Undefined Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		Objects.Insert(Object, "View");
	EndDo;
	
EndProcedure

// Multilingual configurations

Function RegionalInfobaseSettingsRequired() Export
		
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		Return ModuleNationalLanguageSupportServer.RegionalInfobaseSettingsRequired();
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

Function StyleItems() Export
	
	StyleElementsSet = New Structure;
	For Each StyleItem In Metadata.StyleItems Do
		StyleElementsSet.Insert(StyleItem.Name, StyleItem.Value);
	EndDo;
	
	Return New FixedStructure(StyleElementsSet);
	
EndFunction

// Returns a set of style elements to be serialized.
// 
// Returns:
//  Structure:
//   * Key - String - style item name.
//   * Value - String
//              - MetadataObjectStyleItem - a style item. For a regular application thick client,
//                           the style item is converted to the system string presentation of the passed value.
//
Function StyleElementsSet()
	
	StyleElementsSet = New Structure;
	For Each StyleItem In Metadata.StyleItems Do
		
		If CurrentRunMode() = ClientRunMode.OrdinaryApplication Then
			StyleElementsSet.Insert(StyleItem.Name, New ValueStorage(StyleItem.Value));
		Else
			StyleElementsSet.Insert(StyleItem.Name, StyleItem.Value);
		EndIf;
		
	EndDo;
	
	Return New FixedStructure(StyleElementsSet);
	
EndFunction

// This method is required by OnFillPermissionsToAccessExternalResources procedure.
Procedure AddRequestForPermissionToUseExtensions(PermissionsRequests)
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		
		Return;
	EndIf;
	
	Permissions = New Array;
	AllExtensions = ConfigurationExtensions.Get();
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	For Each Extension In AllExtensions Do
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			Extension.Name, Base64String(Extension.HashSum)));
	EndDo;
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters")));

EndProcedure

Function MustShowRAMSizeRecommendations()
	
	If Common.IsWebClient()
	 Or Not Common.FileInfobase() Then
		Return False;
	EndIf;
	
	RAM = ClientParametersAtServer().Get("RAM");
	If TypeOf(RAM) <> Type("Number") Then
		Return False; // The client parameter on the server is not filled (there is no client application).
	EndIf;
	
	RecommendedSize = Common.CommonCoreParameters().RecommendedRAM;
	SavedRecommendation = Common.CommonSettingsStorageLoad("UserCommonSettings",
		"RAMRecommendation");
	
	Recommendation = New Structure;
	Recommendation.Insert("Show", True);
	Recommendation.Insert("PreviousShowDate", Date(1, 1, 1));
	
	If TypeOf(SavedRecommendation) = Type("Structure") Then
		FillPropertyValues(Recommendation, SavedRecommendation);
	EndIf;
	
	Return RAM < RecommendedSize
		And (Recommendation.Show
		   Or (CurrentSessionDate() - Recommendation.PreviousShowDate) > 60*60*24*60)
	
EndFunction

Procedure IgnoreSendingDataProcessedOnMasterDIBNodeOnInfobaseUpdate(DataElement, InitialImageCreating, Recipient)
	
	If Recipient <> Undefined
		And Not InitialImageCreating
		And TypeOf(DataElement) = Type("InformationRegisterRecordSet.DataProcessedInMasterDIBNode") Then
		
		IndexOf = DataElement.Count() - 1;
		While IndexOf >= 0 Do
			SetRow = DataElement[IndexOf];
			If SetRow.ExchangePlanNode <> Recipient Then
				DataElement.Delete(SetRow);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		
	EndIf;

EndProcedure

Function InvalidPlatformVersionUsed()
	
	SystemInfo = New SystemInfo;
	DeprecatedPlatformVersions = Common.InvalidPlatformVersions();
	
	Return StrFind(DeprecatedPlatformVersions, SystemInfo.AppVersion);
	
EndFunction

Function OwnerFilledOut(Source)
	AttributesValues = New Structure("Owner");
	FillPropertyValues(AttributesValues, Source);
	Result = ValueIsFilled(AttributesValues.Owner);
	Return Result;	
EndFunction

Function DeletionMarkValue(CustomRef)
	Result = Common.ObjectAttributeValue(CustomRef, "DeletionMark");
	Return Result;
EndFunction

#Region TablesComparison

Function CompareTables(Table1, Table2) Export
	
	Result = New Structure;
	
	// Comparing the spreadsheet documents by lines and selecting the matching lines.
	Result.Insert("RowMappings", GenerateMatches(Table1, Table2, True));
	
	// Comparing the spreadsheet documents by columns and selecting the matching columns.
	Result.Insert("ColumnMappings", GenerateMatches(Table1, Table2, False));
	
	Return Result; 
	
EndFunction

Function GenerateMatches(LeftTable, TableRight, ByRows)
	
	DataFromLeftTable = GetDataForComparison(LeftTable, ByRows);
	
	DataFromRightTable = GetDataForComparison(TableRight, ByRows);
	
	If ByRows Then
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(TableRight.Count()+1));		
		
	Else
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Columns.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(TableRight.Columns.Count()+1));
		
	EndIf;
	
	QueryText =
	"SELECT
	|	DataFromLeftTable.Number AS Number,
	|	DataFromLeftTable.Value AS Value,
	|	DataFromLeftTable.Count AS Count
	|INTO LeftTable
	|FROM
	|	&DataFromLeftTable AS DataFromLeftTable
	|
	|INDEX BY
	|	Value
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataFromRightTable.Number AS Number,
	|	DataFromRightTable.Value AS Value,
	|	DataFromRightTable.Count AS Count
	|INTO TableRight
	|FROM
	|	&DataFromRightTable AS DataFromRightTable
	|
	|INDEX BY
	|	Value
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeftTable.Number AS ItemNumberLeft,
	|	TableRight.Number AS ItemNumberRight,
	|	CASE
	|		WHEN TableRight.Number - LeftTable.Number < 0
	|			THEN LeftTable.Number - TableRight.Number
	|		ELSE TableRight.Number - LeftTable.Number
	|	END AS DistanceFromBeginning,
	|	CASE
	|		WHEN &RowCountRight - TableRight.Number - (&RowCountLeft - LeftTable.Number) < 0
	|			THEN &RowCountLeft - LeftTable.Number - (&RowCountRight - TableRight.Number)
	|		ELSE &RowCountRight - TableRight.Number - (&RowCountLeft - LeftTable.Number)
	|	END AS DistanceFromEnd,
	|	SUM(CASE
	|		WHEN LeftTable.Value <> """"
	|			THEN CASE
	|				WHEN LeftTable.Count < TableRight.Count
	|					THEN LeftTable.Count
	|				ELSE TableRight.Count
	|			END
	|		ELSE 0
	|	END) AS ValueMatchesCount,
	|	SUM(CASE
	|		WHEN LeftTable.Count < TableRight.Count
	|			THEN LeftTable.Count
	|		ELSE TableRight.Count
	|	END) AS TotalMatchesCount
	|INTO DataCollapsed
	|FROM
	|	LeftTable AS LeftTable
	|		INNER JOIN TableRight AS TableRight
	|		ON LeftTable.Value = TableRight.Value
	|GROUP BY
	|	LeftTable.Number,
	|	TableRight.Number
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataCollapsed.ItemNumberLeft AS ItemNumberLeft,
	|	DataCollapsed.ItemNumberRight AS ItemNumberRight,
	|	DataCollapsed.ValueMatchesCount AS ValueMatchesCount,
	|	DataCollapsed.TotalMatchesCount AS TotalMatchesCount,
	|	CASE
	|		WHEN DataCollapsed.DistanceFromBeginning < DataCollapsed.DistanceFromEnd
	|			THEN DataCollapsed.DistanceFromBeginning
	|		ELSE DataCollapsed.DistanceFromEnd
	|	END AS MinDistance
	|INTO DataWithDistances
	|FROM
	|	DataCollapsed AS DataCollapsed
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DataCollapsed
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataWithDistances.ItemNumberLeft AS ItemNumberLeft,
	|	DataWithDistances.ItemNumberRight AS ItemNumberRight,
	|	DataWithDistances.ValueMatchesCount * ParametersMaximums.TotalMatchesCount *
	|		ParametersMaximums.MinDistance + DataWithDistances.TotalMatchesCount *
	|		ParametersMaximums.MinDistance + (ParametersMaximums.MinDistance -
	|		DataWithDistances.MinDistance) AS Weight
	|INTO WeightedMatches
	|FROM
	|	DataWithDistances AS DataWithDistances,
	|	(SELECT
	|		MAX(DataWithDistances.TotalMatchesCount) AS TotalMatchesCount,
	|		MAX(DataWithDistances.MinDistance) AS MinDistance
	|	FROM
	|		DataWithDistances AS DataWithDistances) AS ParametersMaximums
	|INDEX BY
	|	ItemNumberLeft,
	|	Weight
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DataWithDistances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BestMatch.ItemNumberLeft AS ItemNumberLeft,
	|	WeightedMatches.ItemNumberRight AS ItemNumberRight,
	|	WeightedMatches.Weight AS Weight
	|INTO Maps1
	|FROM
	|	(SELECT
	|		WeightedMatches.ItemNumberLeft AS ItemNumberLeft,
	|		MAX(WeightedMatches.Weight) AS Weight
	|	FROM
	|		WeightedMatches AS WeightedMatches
	|	GROUP BY
	|		WeightedMatches.ItemNumberLeft) AS BestMatch
	|		LEFT JOIN WeightedMatches AS WeightedMatches
	|		ON BestMatch.ItemNumberLeft = WeightedMatches.ItemNumberLeft
	|		AND BestMatch.Weight = WeightedMatches.Weight
	|INDEX BY
	|	ItemNumberLeft";

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("DataFromLeftTable", DataFromLeftTable);
	Query.SetParameter("DataFromRightTable", DataFromRightTable);
	Query.SetParameter("RowCountLeft", LeftTable.Count());
	Query.SetParameter("RowCountRight", TableRight.Count());
	Query.Execute();

	ConflictsLevel = 2;
	
	While ConflictsLevel > 0 Do
		Query.Text = 
		"SELECT
		|	AllConflicts.ItemNumberLeft AS ItemNumberLeft,
		|	AllConflicts.ItemNumberRight AS ItemNumberRight,
		|	SUM(AllConflicts.NumberOfConflicts) AS NumberOfConflicts
		|INTO FoundConflicts
		|FROM
		|	(SELECT
		|		Maps1.ItemNumberLeft AS ItemNumberLeft,
		|		Maps1.ItemNumberRight AS ItemNumberRight,
		|		1 AS NumberOfConflicts
		|	FROM
		|		Maps1 AS Maps1
		|			INNER JOIN Maps1 AS Maps11
		|			ON Maps1.ItemNumberRight < Maps11.ItemNumberRight
		|			AND Maps1.ItemNumberLeft > Maps11.ItemNumberLeft
		|
		|	UNION ALL
		|
		|	SELECT
		|		Maps1.ItemNumberLeft,
		|		Maps1.ItemNumberRight,
		|		1
		|	FROM
		|		Maps1 AS Maps1
		|			INNER JOIN Maps1 AS Maps11
		|			ON Maps1.ItemNumberRight > Maps11.ItemNumberRight
		|			AND Maps1.ItemNumberLeft < Maps11.ItemNumberLeft
		|
		|	UNION ALL
		|
		|	SELECT
		|		Maps1.ItemNumberLeft,
		|		Maps1.ItemNumberRight,
		|		1
		|	FROM
		|		(SELECT
		|			Maps1.ItemNumberRight AS ItemNumberRight,
		|			MAX(Maps1.Weight) AS Weight
		|		FROM
		|			Maps1 AS Maps1
		|		GROUP BY
		|			Maps1.ItemNumberRight
		|		HAVING
		|			COUNT(DISTINCT Maps1.ItemNumberLeft) > 1) AS Duplicates
		|			LEFT JOIN Maps1 AS Maps1
		|			ON Duplicates.ItemNumberRight = Maps1.ItemNumberRight
		|			AND Duplicates.Weight > Maps1.Weight) AS AllConflicts
		|GROUP BY
		|	AllConflicts.ItemNumberLeft,
		|	AllConflicts.ItemNumberRight
		|
		|INDEX BY
		|	ItemNumberLeft,
		|	ItemNumberRight
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Maps1.ItemNumberLeft AS ItemNumberLeft,
		|	Maps1.ItemNumberRight AS ItemNumberRight,
		|	Maps1.Weight AS Weight,
		|	ISNULL(FoundConflicts.NumberOfConflicts, 0) AS NumberOfConflicts
		|INTO MapsWithConflict
		|FROM
		|	Maps1 AS Maps1
		|		LEFT JOIN FoundConflicts AS FoundConflicts
		|		ON Maps1.ItemNumberLeft = FoundConflicts.ItemNumberLeft
		|		AND Maps1.ItemNumberRight = FoundConflicts.ItemNumberRight
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Maps1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsWithConflict.ItemNumberLeft AS ItemNumberLeft,
		|	MapsWithConflict.ItemNumberRight AS ItemNumberRight,
		|	MapsWithConflict.Weight AS Weight,
		|	MapsWithConflict.NumberOfConflicts AS NumberOfConflicts
		|INTO ReplaceableMaps
		|FROM
		|	(SELECT
		|		MAX(MapsWithConflict.NumberOfConflicts) AS NumberOfConflicts
		|	FROM
		|		MapsWithConflict AS MapsWithConflict) AS ConflictsMaxNumber
		|		LEFT JOIN MapsWithConflict AS MapsWithConflict
		|		ON ConflictsMaxNumber.NumberOfConflicts <> 0
		|		AND MapsWithConflict.NumberOfConflicts = ConflictsMaxNumber.NumberOfConflicts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsWithConflict.ItemNumberLeft AS ItemNumberLeft,
		|	MapsWithConflict.ItemNumberRight AS KeyItemNumberRight,
		|	MapsWithConflict.NumberOfConflicts AS NumberOfConflicts,
		|	ReplacementOptions.ItemNumberRight AS ItemNumberRight,
		|	ReplacementOptions.Weight AS Weight
		|INTO MapsOptionsForReplacement
		|FROM
		|	ReplaceableMaps AS MapsWithConflict
		|		LEFT JOIN WeightedMatches AS ReplacementOptions
		|		ON MapsWithConflict.ItemNumberLeft = ReplacementOptions.ItemNumberLeft
		|		AND MapsWithConflict.Weight > ReplacementOptions.Weight
		|INDEX BY
		|	ItemNumberLeft
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsOptionsForReplacement.ItemNumberLeft AS ItemNumberLeft,
		|	MapsOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
		|	1 AS NumberOfConflicts
		|INTO FoundOptionsConflicts
		|FROM
		|	MapsOptionsForReplacement AS MapsOptionsForReplacement
		|		INNER JOIN MapsWithConflict AS MapsWithConflict
		|		ON MapsOptionsForReplacement.ItemNumberRight < MapsWithConflict.ItemNumberRight
		|		AND MapsOptionsForReplacement.ItemNumberLeft > MapsWithConflict.ItemNumberLeft
		|
		|UNION ALL
		|
		|SELECT
		|	MapsOptionsForReplacement.ItemNumberLeft,
		|	MapsOptionsForReplacement.ItemNumberRight,
		|	1
		|FROM
		|	MapsOptionsForReplacement AS MapsOptionsForReplacement
		|		INNER JOIN MapsWithConflict AS MapsWithConflict
		|		ON MapsOptionsForReplacement.ItemNumberRight > MapsWithConflict.ItemNumberRight
		|		AND MapsOptionsForReplacement.ItemNumberLeft < MapsWithConflict.ItemNumberLeft
		|
		|UNION ALL
		|
		|SELECT
		|	MapsWithConflict.ItemNumberLeft,
		|	MapsWithConflict.ItemNumberRight,
		|	1
		|FROM
		|	(SELECT
		|		MapsOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
		|		MAX(MapsWithConflict.Weight) AS Weight
		|	FROM
		|		MapsOptionsForReplacement AS MapsOptionsForReplacement
		|			LEFT JOIN MapsWithConflict AS MapsWithConflict
		|			ON MapsOptionsForReplacement.ItemNumberRight = MapsWithConflict.ItemNumberRight
		|	GROUP BY
		|		MapsOptionsForReplacement.ItemNumberRight) AS Duplicates
		|		LEFT JOIN MapsWithConflict AS MapsWithConflict
		|		ON Duplicates.ItemNumberRight = MapsWithConflict.ItemNumberRight
		|		AND Duplicates.Weight > MapsWithConflict.Weight
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsOptionsForReplacement.ItemNumberLeft AS ItemNumberLeft,
		|	MapsOptionsForReplacement.KeyItemNumberRight AS KeyItemNumberRight,
		|	MapsOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
		|	MapsOptionsForReplacement.Weight AS Weight,
		|	ISNULL(SUM(Conflicts1.NumberOfConflicts), 0) AS NumberOfConflicts
		|INTO MapsVariantsForReplacingConflicts
		|FROM
		|	MapsOptionsForReplacement AS MapsOptionsForReplacement
		|		LEFT JOIN FoundOptionsConflicts AS Conflicts1
		|		ON MapsOptionsForReplacement.ItemNumberLeft = Conflicts1.ItemNumberLeft
		|		AND MapsOptionsForReplacement.ItemNumberRight = Conflicts1.ItemNumberRight
		|GROUP BY
		|	MapsOptionsForReplacement.ItemNumberLeft,
		|	MapsOptionsForReplacement.KeyItemNumberRight,
		|	MapsOptionsForReplacement.ItemNumberRight,
		|	MapsOptionsForReplacement.Weight,
		|	MapsOptionsForReplacement.NumberOfConflicts
		|HAVING
		|	MapsOptionsForReplacement.NumberOfConflicts > ISNULL(SUM(Conflicts1.NumberOfConflicts), 0)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsVariantsForReplacingConflicts.ItemNumberLeft AS ItemNumberLeft,
		|	MAX(MapsVariantsForReplacingConflicts.Weight) AS Weight
		|INTO ReplacementMaxWeight
		|FROM
		|	MapsVariantsForReplacingConflicts AS MapsVariantsForReplacingConflicts
		|GROUP BY
		|	MapsVariantsForReplacingConflicts.ItemNumberLeft
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReplaceableMaps.ItemNumberLeft AS ItemNumberLeft,
		|	ReplaceableMaps.ItemNumberRight AS KeyItemNumberRight,
		|	ISNULL(MapsVariantsForReplacingConflicts.ItemNumberRight, UNDEFINED) AS ItemNumberRight,
		|	MapsVariantsForReplacingConflicts.Weight AS Weight
		|INTO MapsForReplacement
		|FROM
		|	ReplaceableMaps AS ReplaceableMaps
		|		LEFT JOIN ReplacementMaxWeight AS ReplacementMaxWeight
		|		ON ReplaceableMaps.ItemNumberLeft = ReplacementMaxWeight.ItemNumberLeft
		|		LEFT JOIN MapsVariantsForReplacingConflicts AS MapsVariantsForReplacingConflicts
		|		ON MapsVariantsForReplacingConflicts.Weight = ReplacementMaxWeight.Weight
		|		AND MapsVariantsForReplacingConflicts.ItemNumberLeft = ReplacementMaxWeight.ItemNumberLeft
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MapsWithConflict.ItemNumberLeft AS ItemNumberLeft,
		|	ISNULL(MapsForReplacement.ItemNumberRight, MapsWithConflict.ItemNumberRight) AS ItemNumberRight,
		|	ISNULL(MapsForReplacement.Weight, MapsWithConflict.Weight) AS Weight,
		|	MapsWithConflict.NumberOfConflicts AS NumberOfConflicts
		|INTO Maps1
		|FROM
		|	MapsWithConflict AS MapsWithConflict
		|		LEFT JOIN MapsForReplacement AS MapsForReplacement
		|		ON MapsWithConflict.ItemNumberLeft = MapsForReplacement.ItemNumberLeft
		|			AND MapsWithConflict.ItemNumberRight = MapsForReplacement.KeyItemNumberRight
		|WHERE
		|	(MapsForReplacement.ItemNumberRight IS NULL
		|			OR MapsForReplacement.ItemNumberRight <> UNDEFINED)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(MAX(MapsWithConflict.NumberOfConflicts), 0) AS NumberOfConflicts
		|FROM
		|	MapsWithConflict AS MapsWithConflict";
			
		Selection = Query.Execute().Select(); //@skip-check query-in-loop - Iterative processing of the table
		Selection.Next();
		ConflictsLevel = Selection.NumberOfConflicts;
		
		TempTablesToDelete = New Array;
		TempTablesToDelete.Add("MapsForReplacement");
		TempTablesToDelete.Add("MapsVariantsForReplacingConflicts");
		TempTablesToDelete.Add("MapsOptionsForReplacement");
		TempTablesToDelete.Add("MapsWithConflict");
		TempTablesToDelete.Add("ReplaceableMaps");
		TempTablesToDelete.Add("FoundConflicts");
		TempTablesToDelete.Add("ReplacementMaxWeight");
		TempTablesToDelete.Add("FoundOptionsConflicts");
		
		DeleteTemporaryTables(Query, TempTablesToDelete); //@skip-check query-in-loop - Iterative processing of the table
		
	EndDo;
	
	Query.Text = "SELECT
	               |	Maps1.ItemNumberLeft AS ItemNumberLeft,
	               |	Maps1.ItemNumberRight AS ItemNumberRight
	               |FROM
	               |	Maps1 AS Maps1";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If MatchResultLeft[Selection.ItemNumberLeft].Value = Undefined
			And MatchResultRight[Selection.ItemNumberRight].Value = Undefined Then
				MatchResultLeft[Selection.ItemNumberLeft].Value = Selection.ItemNumberRight;
				MatchResultRight[Selection.ItemNumberRight].Value = Selection.ItemNumberLeft;
		EndIf;
	EndDo;
	
	Result = New Array;
	Result.Add(MatchResultLeft);
	Result.Add(MatchResultRight);
	
	Return Result;

EndFunction

Function GetDataForComparison(SourceValueTable, ByRows)
	
	MaxRowSize = New StringQualifiers(100);
	
	Result = New ValueTable;
	Result.Columns.Add("Number",		New TypeDescription("Number"));
	Result.Columns.Add("Value",	New TypeDescription("String", , MaxRowSize));
	
	Boundary1 = ?(ByRows, SourceValueTable.Count(),
							SourceValueTable.Columns.Count()) - 1;
		
	Boundary2 = ?(ByRows, SourceValueTable.Columns.Count(),
							SourceValueTable.Count()) - 1;
		
	For Index1 = 0 To Boundary1 Do
		
		For IndexOf2 = 0 To Boundary2 Do
			
			NewRow = Result.Add();
			NewRow.Number = Index1+1;
			NewRow.Value = ?(ByRows, SourceValueTable[Index1][IndexOf2],
												SourceValueTable[IndexOf2][Index1]);
			
		EndDo;
		
	EndDo;
	
	Result.Columns.Add("Count", New TypeDescription("Number"));
	Result.FillValues(1, "Count");
	
	Result.GroupBy("Number, Value", "Count");
	
	Return Result;
	
EndFunction

Procedure DeleteTemporaryTables(Query, Tables)
	Query.Text = "DROP " + StrConcat(Tables, "; DROP ");
	Query.Execute();
EndProcedure

#EndRegion

// Parameters:
//  FullMethodName - String
//  InBackground - Boolean
//  Object - Arbitrary
//  Text - Arbitrary - if not Null, set error text and don't call an exception.
//
Procedure CheckMethodForCallAsArbitraryCode(FullMethodName, InBackground = False, Object = Undefined, Text = Null) Export
	
	If Not ShouldCheckMethodsCallsAsArbitraryCode() And Text = Null Then
		Return;
	EndIf;
	
	If Object <> Undefined Then
		Result = MethodsAllowedForCallAsArbitraryCode(Object);
		MethodName = FullMethodName;
	Else
		NameParts = StrSplit(FullMethodName, ".", True);
		
		If NameParts.Count() = 3 Then
			ModuleName = NameParts[0] + "." + NameParts[1];
			MethodName = NameParts[2];
		Else
			ModuleName = NameParts[0];
			MethodName = NameParts[1];
		EndIf;
		
		Try
			Result = StandardSubsystemsCached.MethodsAllowedForCallAsArbitraryCode(ModuleName);
		Except
			If Text <> Null And CommonClientServer.IsExceptionWithErrorCode(ErrorInfo(),
					"StandardSubsystems.Core.IsGettingCommonModuleByNameError
					|StandardSubsystems.Core.IsGettingManagerModuleByNameError") Then
				Return;
			EndIf;
			Raise;
		EndTry;
	EndIf;
	
	If TypeOf(Result) = Type("FixedMap") Then
		MethodUse = Result.Get(MethodName);
		If InBackground And MethodUse = True
		 Or Not InBackground And MethodUse <> Undefined Then
			Return;
		EndIf;
		IsProcedureDefined = True;
	Else
		IsProcedureDefined = False;
	EndIf;
	
	IsCallForbidden = Text <> Null Or IsAnyMethodsCallForbiddenAsArbitraryCode(IsProcedureDefined);
	
	If Not IsCallForbidden And Not IsProcedureDefined Then
		LogLevel = CallsRegistrationLevelForUnspecifiedMethodsAsArbitraryCode();
		If LogLevel = Undefined Then
			Return;
		EndIf;
	Else
		LogLevel = EventLogLevel.Error;
	EndIf;
	
	If Object <> Undefined Then
		ModuleName = Object.Metadata().FullName() + "." + "ObjectModule";
	EndIf;
	
	If InBackground And IsProcedureDefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phương thức ""%1"" không được phép chạy ngầm trong thủ tục ""%2"" của mô-đun ""%3"".';
				|ru = 'Метод ""%1"" не разрешен для запуска в фоне в процедуре ""%2"" модуля ""%3"".';
				|en = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module.'; fa = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module.';
				|it = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module.';
				|pl = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module.';
				|tr = '""%1"" yöntemi, ""%3"" modülünün ""%2"" prosedüründe arka planda çalıştırılmasına izin verilmiyor.'"),
			MethodName, "OnDefineMethodsAllowedForCallAsArbitraryCode", ModuleName);
	ElsIf Not InBackground And IsProcedureDefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phương thức ""%1"" không được phép để hiển thị như mã tùy ý trong thủ tục ""%2"" của mô-đun ""%3"".';
				|ru = 'Метод ""%1"" не разрешен для вызова, как произвольный код, в процедуре ""%2"" модуля ""%3"".';
				|en = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module.'; fa = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module.';
				|it = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module.';
				|pl = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module.';
				|tr = '""%1"" yöntemi, ""%3"" modülünün ""%2"" prosedüründe serbest kod olarak çağrılmasına izin verilmiyor.'"),
			MethodName, "OnDefineMethodsAllowedForCallAsArbitraryCode", ModuleName);
	ElsIf InBackground And Not IsProcedureDefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phương thức ""%1"" không được phép chạy ngầm trong thủ tục ""%2"" của mô-đun ""%3"" (chưa xác định thủ tục).';
				|ru = 'Метод ""%1"" не разрешен для запуска в фоне в процедуре ""%2"" модуля ""%3"" (процедура не определена).';
				|en = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).'; fa = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|it = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|pl = 'The ""%1"" method cannot run in the background in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|tr = '""%1"" yöntemi, """"%3 modülünün ""%2"" prosedüründe (prosedür tanımlı değil) arka planda çalıştırılmasına izin verilmiyor.'"),
			MethodName, "OnDefineMethodsAllowedForCallAsArbitraryCode", ModuleName);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phương thức ""%1"" không được phép để hiển thị như mã tùy ý trong thủ tục ""%2"" của mô-đun ""%3"" (chưa xác định thủ tục).';
				|ru = 'Метод ""%1"" не разрешен для вызова, как произвольный код, в процедуре ""%2"" модуля ""%3"" (процедура не определена).';
				|en = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).'; fa = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|it = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|pl = 'The ""%1"" method cannot be called as arbitrary code in the ""%2""  procedure of the ""%3"" module (the procedure is not defined).';
				|tr = '""%1"" metodu, ""%2"" prosedüründe, ""%3"" modülünde (prosedür tanımlı değil) serbest kod olarak çağrılmasına izin verilmiyor.'"),
			MethodName, "OnDefineMethodsAllowedForCallAsArbitraryCode", ModuleName);
	EndIf;
	
	If Text <> Null Then
		Text = ErrorText;
		Return;
	EndIf;
	
	If IsCallForbidden Then
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Try
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	
	EventName = NStr("vi = 'An toàn.Phương thức không được phép để hiển thị như mã tùy ý';
					|ru = 'Безопасность.Метод не разрешен для вызова, как произвольный код';
					|en = 'Security.The method cannot be called as arbitrary code'; fa = 'Security.The method cannot be called as arbitrary code';
					|it = 'Security.The method cannot be called as arbitrary code';
					|pl = 'Security.The method cannot be called as arbitrary code';
					|tr = 'Güvenlik.Metot, serbest kod olarak çağrılmasına izin verilmiyor'",
		Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName, LogLevel,, ModuleName + "." + MethodName,
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

// Parameters:
//  Module - Arbitrary - reference to a common module, manager module, or object.
//
// Returns:
//  FixedMap, Undefined
//
Function MethodsAllowedForCallAsArbitraryCode(Module) Export
	
	Methods = New Map;
	Try
		Module.OnDefineMethodsAllowedForCallAsArbitraryCode(Methods);
	Except
		ErrorInfo = ErrorInfo();
		IsProcedureNotSpecified = StrFind(ErrorProcessing.BriefErrorDescription(ErrorInfo),
			"(" + "OnDefineMethodsAllowedForCallAsArbitraryCode" + ")") > 0;
		If IsProcedureNotSpecified Then
			Return Undefined;
		EndIf;
		Raise;
	EndTry;
	
	Result = New Map;
	For Each KeyAndValue In Methods Do
		Result.Insert(KeyAndValue.Key, KeyAndValue.Value = True);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Enables validation of method calls in 1C:Enterprise mode and in the SSLImplementationCheck report.
// Can be overridden using an extension to identify locations that require customization.
//
// Returns:
//  Boolean
//
Function ShouldCheckMethodsCallsAsArbitraryCode() Export
	Return False;
EndFunction

// Allows blocking of method calls that are not permitted to be executed as arbitrary code.
// Pass True to the CheckMethodCallsAsArbitraryCode function.
//
// Parameters:
//  IsProcedureDefined - Boolean - if False, then the OnDefineMethodsAllowedToBeCalledAsArbitraryCode
//    procedure is not defined, which allows enabling a restriction
//    only when the procedure is defined in the module, and not unconditionally.
//
// Returns:
//  Boolean
//
Function IsAnyMethodsCallForbiddenAsArbitraryCode(IsProcedureDefined)
	Return False;
EndFunction

// Returns the event log level if the registration of called methods is required,
// when the OnDefineMethodsAllowedToBeCalledAsArbitraryCode procedure is not defined.
// Can be overridden using an extension to detect cases (through automated
// testing) that cannot be identified by static code analysis using
// the SSLImplementationCheck.erf report (see CheckMethodCallsAsArbitraryCode).
//
// Returns:
//  EventLogLevel, Undefined
//
Function CallsRegistrationLevelForUnspecifiedMethodsAsArbitraryCode()
	Return EventLogLevel.Error;
EndFunction

#EndRegion

#EndRegion

#EndIf