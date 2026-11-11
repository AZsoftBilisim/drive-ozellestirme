///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ApplicationsCheckPerformed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CertificatesAreAvailable = AccessRight("Read", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
	Items.DecorationOpenMRLOAs.Visible = False;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
		ModuleMachineReadableLettersOfAuthorityFTSInternal.OnCreateAtServer(ThisObject);
	EndIf;
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	DigitalSignatureInternal.SetVisibilityOfRefToAppsTroubleshootingGuide(Items.Instruction);
	
	SetConditionalAppearance();
	DigitalSignatureInternal.SetCertificateListConditionalAppearance(Certificates, True);
	
	URL = "e1cib/app/CommonForm.DigitalSignatureAndEncryptionSettings";
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Items.SettingsPage.Visible = False;
		NoRightToSaveUserData = True;
	EndIf;
	
	If Parameters.ShowPage = "Certificates" And CertificatesAreAvailable Then
		Items.Pages.CurrentPage = Items.CertificatesPage;
	ElsIf Parameters.ShowPage = "Settings" Then
		Items.Pages.CurrentPage = Items.SettingsPage;
	ElsIf Parameters.ShowPage = "Programs" Then
		Items.Pages.CurrentPage = Items.ApplicationPage;
	EndIf;
	
	// App page
	If Not AccessRight("Update", Metadata.Catalogs.DigitalSignatureAndEncryptionApplications) Then
		Items.Programs.ChangeRowSet = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsAdd", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsChange", "Visible", False);
		
		Items.ApplicationsMarkForDeletion.Visible = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"ProgramsContextMenuAdd", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ProgramsContextMenuChange", "Visible", False);
		
		Items.ProgramsContextMenuApplicationsMarkForDeletion.Visible = False;
		Items.Programs.Title =
			NStr("vi = 'Có thể sử dụng ứng dụng trong máy tính do người quản trị cho phép';
				|ru = 'Приложения, предусмотренные администратором, которые можно использовать на компьютере';
				|en = 'A list of apps the administrator authorized for your computer.'; fa = 'A list of apps the administrator authorized for your computer.';
				|it = 'Приложения, предусмотренные администратором, которые можно использовать на компьютере';
				|pl = 'A list of apps the administrator authorized for your computer.';
				|tr = 'Bilgisayarda kullanılabilecek yönetici tarafından sağlanan uygulamaların listesi'");
	Else
		SetPrivilegedMode(True);
		IsMultiUserInfobase = InfoBaseUsers.GetUsers().Count() > 1;
		SetPrivilegedMode(False);
		If Not IsMultiUserInfobase Then
			Items.Programs.Title = NStr("vi = 'Tùy chỉnh ứng dụng của chữ ký điện tử và mã hóa mà được cài đặt trên máy tính';
										|ru = 'Настройки приложений электронной подписи и шифрования, установленных на компьютере';
										|en = 'Digital signing and encryption app settings'; fa = 'Digital signing and encryption app settings';
										|it = 'Настройки приложений электронной подписи и шифрования, установленных на компьютере';
										|pl = 'Digital signing and encryption app settings';
										|tr = 'Bilgisayarınızda yüklü elektronik imza ve şifreleme uygulamalarına ilişkin ayarlar'");
		EndIf;
	EndIf;
	
	// Certificates page
	If CertificatesAreAvailable Then
	
		IsFullUser = Users.IsFullUser();
		
		If ValueIsFilled(Parameters.CertificatesShow) Then
			CertificatesShow = Parameters.CertificatesShow;
		ElsIf IsFullUser Then
			CertificatesShow = "AllCertificates";
		Else
			CertificatesShow = "MyCertificates";
		EndIf;
			
		If Not IsFullUser Or CertificatesShow <> "AllCertificates" Then
			UserSelect = Users.CurrentUser();
		EndIf;
		
		QueryText = Certificates.QueryText;
		CertificateIssueRequestAvailable = DigitalSignature.CommonSettings().CertificateIssueRequestAvailable;
		
		If CertificateIssueRequestAvailable Then
			
			ModuleApplicationForIssuingANewQualifiedCertificate = Common.CommonModule("DataProcessors.ApplicationForNewQualifiedCertificateIssue");
			ModuleApplicationForIssuingANewQualifiedCertificate.FillInApplicationStateSelectionList(Items.CertificatesShowRequests.ChoiceList);
			ModuleApplicationForIssuingANewQualifiedCertificate.AddStateInListOfCertificatesToRequest(QueryText);
			ModuleApplicationForIssuingANewQualifiedCertificate.AddLegend(ThisObject, Items.LegendGroup);
			Items.CertificatesShow.ChoiceList.Add("MyStatementsInProgress", NStr("vi = 'Các yêu cầu của tôi đang được xử lý';
																				|ru = 'Мои заявления в работе';
																				|en = 'My submitted applications'; fa = 'My submitted applications';
																				|it = 'Le mie dichiarazioni a lavoro';
																				|pl = 'Moje oświadczenia w pracy';
																				|tr = 'Başvurularım devam ediyor'"));
			StatusApplicationIsNotInOperation = ModuleApplicationForIssuingANewQualifiedCertificate.StatusApplicationIsNotInOperation();
			Items.AddCertificateIssueRequest.Visible = True;
			
		Else
			QueryText = StrReplace(QueryText, "&AdditionalField", "UNDEFINED");
			QueryText = StrReplace(QueryText, "AND &OptionalConnection", "");
			QueryText = StrReplace(QueryText, "&IsRequest", "False");
			
			CommonClientServer.SetFormItemProperty(Items,
					"ReissueCertificate", "Visible", False);
			
			Items.CertificatesShowRequests.Visible  = False;
			Items.CertificatesRequestStatus.Visible = False;
			Items.AddCertificateIssueRequest.Visible = False;
		EndIf;
		
		HasRightToAddCertificates = DigitalSignatureInternal.HasRightToAddCertificatesToCatalog();
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = QueryText;
		Common.SetDynamicListProperties(Items.Certificates, ListProperties);
		
		CertificatesInPersonalStorage = New ValueList;
		SetParametersInCertificateListOnServer();
		CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation);
		
	EndIf;
	
	If Common.IsSubordinateDIBNode() Then
		// Cannot change the list of configured apps and their settings.
		// Can only change the app paths on Linux servers.
		Items.Programs.ChangeRowSet = False;
		Items.ApplicationsMarkForDeletion.Enabled = False;
		Items.ProgramsContextMenuApplicationsMarkForDeletion.Enabled = False;
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsChange", "OnlyInAllActions", False);
	Else
		Items.SettingInCentralNodeLabel.Visible = False;
	EndIf;
	
	If Not DigitalSignatureInternal.RequiresThePathToTheProgram(True) Then
		Items.ApplicationsLinuxPathToApplicationGroup.Visible = False;
	EndIf;
	
	Items.GroupCryptoProvidersHint.Visible = Common.IsWebClient();
	Items.FormInstallExtension.Visible = Common.IsWebClient();
	
	Items.FormSupportTicket.Visible = 
		Common.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService");
	
	FillApplicationsAndSettings();
	UpdateCurrentItemsVisibility();
	
	If DigitalSignature.UseMobileSignatureService() Then
		CommonClientServer.SetFormItemProperty(Items,
			"MobileSignatureServiceSignatories", "Visible", True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		PlacementParameters = ModuleAttachableCommands.PlacementParameters();
		PlacementParameters.CommandBar = Items.CertificatesListCommandBar;
		PlacementParameters.Sources = New TypeDescription("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates");
		PlacementParameters.CommandsOwner = Items.Certificates;
		
		ModuleAttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DefineInstalledApplications();
	If CertificatesAreAvailable Then
		AttachIdleHandler("AddCertificatesInPersonalVaultDynamicListParameter", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	DefineInstalledApplications();
	If CertificatesAreAvailable And ValueIsFilled(Parameters.CertificatesShow) Then
		CertificatesShow = Parameters.CertificatesShow;
		CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeysCertificates") And CertificatesAreAvailable Then
		If Not ValueIsFilled(Parameter) Then
			Items.Certificates.Refresh();
		ElsIf Parameter.Is_Specified Then
			AttachIdleHandler("UpdateCertificatesList", 0.1, True);
		ElsIf Parameter.IsNew Then
			Items.Certificates.Refresh();
			Items.Certificates.CurrentRow = Source;
		Else
			Items.Certificates.Refresh();
		EndIf;
		Return;
	EndIf;
	
	ProgramsSettingsChangesEvents = New Array;
	ProgramsSettingsChangesEvents.Add(Upper("Write_DigitalSignatureAndEncryptionApplications"));
	ProgramsSettingsChangesEvents.Add(Upper("Write_PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers"));
	ProgramsSettingsChangesEvents.Add(Upper("WritePersonalSettingsForDigitalSignatureAndEncryption"));
	
	DigitalSignatureClientLocalization.OnGetProgramsSettingsChangeEvents(ProgramsSettingsChangesEvents);
			
	// When changing application components or settings.
	If ProgramsSettingsChangesEvents.Find(Upper(EventName)) <> Undefined Then
		AttachIdleHandler("OnChangeApplicationsCompositionOrSettings", 0.1, True);
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("InstallCryptoExtension")
		Or Upper(EventName) = Upper("Installation_AddInExtraCryptoAPI") Then
		DefineInstalledApplications();
		If CertificatesAreAvailable Then
			AttachIdleHandler("AddCertificatesInPersonalVaultDynamicListParameter", 0.1, True);
		EndIf;
		Return;
	EndIf;
	
	// When changing usage settings.
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption") Then
		AttachIdleHandler("SigningOrEncryptionUsageOnChange", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If ApplicationsCheckPerformed <> True Then
		DefineInstalledApplications();
	EndIf;
	
	If CurrentPage = Items.SettingsPage Then

		PersonalSettings = DigitalSignatureClient.PersonalSettings();
		SystemInfo = New SystemInfo;
		ClientID = SystemInfo.ClientID;
		PathToAddInLogOnClient = PersonalSettings.PathToDiagnosticsDirectory.Get(ClientID);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure CertificatesShowOnChange(Item)
	
	CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation, UsersClient.CurrentUser());
	
EndProcedure

&AtClient
Procedure CertificatesShowRequestsOnChange(Item)
	
	CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation);
	
EndProcedure

&AtClient
Procedure CertificatesOnlyValidOnChange(Item)

	CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation);

EndProcedure

&AtClient
Procedure UserSelectOnChange(Item)
	
	CertificatesUpdateFilter(ThisObject, StatusApplicationIsNotInOperation);
	
EndProcedure

&AtClient
Procedure EncryptedFilesExtensionOnChange(Item)
	
	If IsBlankString(EncryptedFilesExtension) Then
		EncryptedFilesExtension = "p7m";
	EndIf;
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure SignatureFilesExtensionOnChange(Item)
	
	If IsBlankString(SignatureFilesExtension) Then
		SignatureFilesExtension = "p7s";
	EndIf;
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure ActionsOnSaveSignedDataOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure SaveCertificateWithSignatureOnChange(Item)
	ShouldSaveSettings();
EndProcedure

&AtClient
Procedure ApplicationsLinuxPathToApplicationOnChange(Item)
	
	CurrentData = Items.Programs.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SaveApplicationPath();
	
EndProcedure

&AtClient
Procedure ApplicationsLinuxPathToApplicationStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.Programs.CurrentData;
	If CurrentData = Undefined Then
		ChoiceData = Undefined;
		StandardProcessing = False;
		Return;
	EndIf;
	
	Filter = New Structure("Application", CurrentData.Ref);
	Rows = DefaultApplicationsPaths.FindRows(Filter);
	If Rows.Count() = 0 Then
		ChoiceData = Undefined;
		StandardProcessing = False;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsLinuxPathToApplicationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Programs.CurrentData;
	If Not ValueIsFilled(ValueSelected)
		Or CurrentData = Undefined Then
		
		Return;
	EndIf;
	
	Filter = New Structure("Application", CurrentData.Ref);
	Rows = DefaultApplicationsPaths.FindRows(Filter);
	CurrentData.LinuxApplicationPath = ?(Rows.Count() = 0, "", Rows[0].Path);
	
	SaveApplicationPath();
	
EndProcedure

&AtClient
Procedure DecorationCheckCryptoProviderInstallationURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("OnlyTokenInstallation", True);
	If FormattedStringURL = DigitalSignatureInternalClientServer.ActionInstallLibrariesForTokens() Then
		DigitalSignatureInternalClient.OpenCryptoProviderAppsInstallationForm(OpeningParameters, ThisObject,
				New CallbackDescription("AfterPerformActionsDetails", ThisObject));
	Else

		CheckParameters = New Structure;
		CheckParameters.Insert("ShouldInstallExtension", True);
		CheckParameters.Insert("SetComponent", True);
		CheckParameters.Insert("ShouldPromptToInstallApp", True);
		CheckParameters.Insert("ExtendedDescription", True);

		NotificationAfterAppsCheckCompleted = New CallbackDescription("DetectInstalledAppsAfterCryptoAppsChecked",
			ThisObject);
		DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
			New CallbackDescription("AfterCryptographyAppsChecked", ThisObject, NotificationAfterAppsCheckCompleted));

	EndIf;

EndProcedure

&AtClient
Procedure DecorationOpenMRLOAsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		Return;
	EndIf;
	
	ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule("MachineReadableLettersOfAuthorityFTSInternalClient");
	ModuleMachineReadableLettersOfAuthorityFTSInternalClient.OpenMRLOAList(FormattedStringURL);
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
EndProcedure

&AtClient
Procedure PathToAddInLogOnClientStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Notification = New CallbackDescription("SelectDirectoryAfterSelection",
		ThisObject);
	FileSystemClient.SelectDirectory(Notification, NStr("vi = 'Hãy chọn thư mục tệp chẩn đoán';
														|ru = 'Выберите каталог файлов диагностики';
														|en = 'Select a directory containing diagnostics files'; fa = 'Select a directory containing diagnostics files';
														|it = 'Select a directory containing diagnostics files';
														|pl = 'Select a directory containing diagnostics files';
														|tr = 'Sorun giderme dosyalarının dizinlerini seçin'"), PathToAddInLogOnClient);
	
EndProcedure

&AtClient
Procedure PathToAddInLogOnClientOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCertificates

&AtClient
Procedure CertificatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	
	If Copy And CertificateIssueRequestAvailable Then
		If Items.Certificates.CurrentRow = Undefined Then
			Return;
		EndIf;
		CurrentData = CertificatesCurrentData(Items.Certificates);
		CreationParameters.CreateRequest = True;
		CreationParameters.CertificateBasis = CurrentData.Ref;
	Else
		CreationParameters.HideApplication = Not CertificateIssueRequestAvailable;
	EndIf;
	
	DigitalSignatureInternalClient.ToAddCertificate(CreationParameters);
	
EndProcedure

&AtServerNoContext
Procedure CertificatesOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each ListLine In Rows Do
		If Not ListLine.Value.Data.Property("User") Then
			Return;
		EndIf;
		Break;
	EndDo;
	
	Query = Undefined;
	For Each ListLine In Rows Do
		If ValueIsFilled(ListLine.Value.Data.User) Then
			Continue;
		EndIf;
		If Query = Undefined Then
			Query = New Query;
			Query.Text =
			"SELECT ALLOWED
			|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref AS Ref,
			|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.User AS User,
			|	PRESENTATION(ElectronicSignatureAndEncryptionKeyCertificatesUsers.User) AS UserPresentation
			|FROM
			|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS
			|		ElectronicSignatureAndEncryptionKeyCertificatesUsers
			|WHERE
			|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref IN (&References)
			|TOTALS
			|	COUNT(User)
			|BY
			|	Ref";
			Query.SetParameter("References", Rows.GetKeys());
			QueryResult = Query.Execute(); // @skip-check query-in-loop - The request is executed once
			If QueryResult.IsEmpty() Then
				Return;
			EndIf;
			FetchLink = QueryResult.Select(QueryResultIteration.ByGroups);
		EndIf;
		If FetchLink.FindNext(ListLine.Value.Data["Ref"], "Ref") Then
			UsersCount = FetchLink.User;
			SampleUser = FetchLink.Select();
			SampleUser.Next();
			If UsersCount = 1 Then
				ListLine.Value.Data.User = SampleUser.UserPresentation;
				Continue;
			EndIf;
			User1 = SampleUser.UserPresentation;
			SampleUser.Next();
			User2 = SampleUser.UserPresentation;
			ListLine.Value.Data.User = DigitalSignatureInternalClientServer.UsersCertificateString(
				User1, User2, UsersCount);
		EndIf;
	EndDo;
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrograms

&AtClient
Procedure ProgramsOnActivateRow(Item)
	
	Items.ApplicationsMarkForDeletion.Enabled =
		Items.Programs.CurrentData <> Undefined;
	
	If Items.Programs.CurrentData <> Undefined Then
		LinuxPathToCurrentApplication = Items.Programs.CurrentData.LinuxApplicationPath;
	EndIf;
	
	UpdateLinuxProgramPath();
	
EndProcedure

&AtClient
Procedure ProgramsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Items.Programs.ChangeRowSet Then
		
		StandardProcessing = True;
		DigitalSignatureClientLocalization.OnAddDigitalSignatureApp(StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
		
		DigitalSignatureInternalClient.OpenAppForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProgramsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	If Items.Find("ApplicationsChange") <> Undefined
	   And Items.ApplicationsChange.Visible
	   And ValueIsFilled(Items.Programs.CurrentData.Ref) Then
		ExtendedApplicationDetails = DigitalSignatureInternalClientServer.NewExtendedApplicationDetails();
		FillPropertyValues(ExtendedApplicationDetails, Items.Programs.CurrentData);
		ExtendedApplicationDetails.Presentation = Items.Programs.CurrentData.Description;
		ExtendedApplicationDetails.UsageMode = PredefinedValue("Enum.DigitalSignatureAppUsageModes.Configured");
		DigitalSignatureInternalClient.OpenAppForm(ExtendedApplicationDetails, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProgramsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Items.Find("ApplicationsChange") <> Undefined
	   And Items.ApplicationsChange.Visible Then
		
		ApplicationsMarkForDeletion(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

&AtClient
Procedure ProgramsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Programs.CurrentData;
	If Field = Items.ProgramsMoreDetails
		And Not IsBlankString(CurrentData.MoreDetails) Then
		
		StandardProcessing = False;

		If CurrentData.Action = "InstallLibrariesForTokens" Then
			OpeningParameters = New Structure("TokenKind, OnlyTokenInstallation");
			FillPropertyValues(OpeningParameters, CurrentData.Parameters);
			OpeningParameters.OnlyTokenInstallation = True;
			DigitalSignatureInternalClient.OpenCryptoProviderAppsInstallationForm(OpeningParameters, ThisObject,
				New CallbackDescription("AfterPerformActionsDetails", ThisObject));
		Else

			FormParameters = New Structure;
			FormParameters.Insert("WarningTitle", NStr("vi = 'Kết quả kiểm tra ứng dụng';
														|ru = 'Результат проверки приложения';
														|en = 'App check result'; fa = 'App check result';
														|it = 'Результат проверки приложения';
														|pl = 'App check result';
														|tr = 'Uygulama doğrulama sonucu'"));
			If CurrentData.IsToken And StrFind(CurrentData.CheckResult,
				DigitalSignatureInternalClient.TokenNotFoundError()) <> 0 Then
				FormParameters.Insert("ErrorTextClient", CurrentData.CheckResult + Chars.LF
					+ DigitalSignatureInternalClient.TokenRecommendations());
			Else
				FormParameters.Insert("ErrorTextClient", CurrentData.CheckResult);
			EndIf;

			FormParameters.Insert("ErrorTextServer", CurrentData.CheckResultAtServer);
			FormParameters.Insert("ShowNeedHelp", True);
			FormParameters.Insert("ShowInstruction", True);

			DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
		EndIf;
		
	ElsIf Not ValueIsFilled(CurrentData.Ref) Then
		
		StandardProcessing = False;
		
		If CurrentData.IsToken Then
			If ValueIsFilled(CurrentData.Slot) Then
				TokenDetails = DigitalSignatureInternalClient.TokenNewProperties();
				TokenDetails.Presentation = CurrentData.Description;
				TokenDetails.SerialNumber = CurrentData.ApplicationName;
				TokenDetails.Slot = CurrentData.Slot;
				DigitalSignatureInternalClient.OpenToken(TokenDetails, ThisObject);
			EndIf;
		Else
			ApplicationDetails = DigitalSignatureInternalClientServer.NewExtendedApplicationDetails();
			FillPropertyValues(ApplicationDetails, CurrentData);
			ApplicationDetails.Presentation = CurrentData.Description;

			DigitalSignatureInternalClient.OpenAppForm(ApplicationDetails, ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	DigitalSignatureInternalClient.ClearInstalledCryptoProvidersCache();
	FillApplicationsAndSettings(True);
	DefineInstalledApplications();
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure AddCertificateIssueRequest(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	CreationParameters.CreateRequest = True;
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("CertificateIssueRequest", 
		CreationParameters);
	
EndProcedure

&AtClient
Procedure AddToSignAndEncrypt(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice(PurposeToSignAndEncrypt,
		CreationParameters);
	
EndProcedure

&AtClient
Procedure AddForSigningAndEncryptionFromFiles(Command)
	
	DigitalSignatureClient.InstallExtension(False, 
		New CallbackDescription("AddForSigningAndEncryptingFromFilesAfterInstallingExtension", ThisObject));
	
EndProcedure

&AtClient
Procedure AddFromFiles(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("OnlyForEncryptionFromFiles",
		CreationParameters);
	
EndProcedure

&AtClient
Procedure AddFromDirectory(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("OnlyForEncryptionFromDirectory",
		CreationParameters);
	
EndProcedure

&AtClient
Procedure AddToEncryptOnly(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("ToEncryptOnly",
		CreationParameters);
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	
EndProcedure

&AtClient
Procedure ShowVersionComponentsExtraCryptoAPI(Command)
	
	InstallConnectReportVersionComponents(False);
		
EndProcedure

&AtClient
Procedure SetComponentExtraCryptoAPI(Command)
	
	InstallConnectReportVersionComponents(True);

EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	MessageParameters = New Structure("Subject, Message",
		NStr("vi = 'Vấn đề khi tùy chỉnh chữ ký điện tử và mã hóa';
			|ru = 'Проблема при настройке электронной подписи и шифрования';
			|en = 'An issue occurred when configuring digital signing and encryption.'; fa = 'An issue occurred when configuring digital signing and encryption.';
			|it = 'An issue occurred when configuring digital signing and encryption.';
			|pl = 'An issue occurred when configuring digital signing and encryption.';
			|tr = 'Dijital imzayı ve şifrelemeyi ayarlarken sorun yaşandı'"), New Array);
	
	DigitalSignatureInternalClient.GenerateTechnicalInformation(NStr("vi = 'Tùy chỉnh chữ ký điện tử và mã hóa';
																	|ru = 'Настройки электронной подписи и шифрования';
																	|en = 'Digital signing and encryption settings'; fa = 'Digital signing and encryption settings';
																	|it = 'Impostazioni di firma elettronica e crittografia';
																	|pl = 'Ustawienia podpisu elektronicznego i szyfrowania';
																	|tr = 'Dijital imza ve şifreleme ayarları'"), MessageParameters);
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	DigitalSignatureInternalClient.GenerateTechnicalInformation(NStr("vi = 'Tùy chỉnh chữ ký điện tử và mã hóa';
																	|ru = 'Настройки электронной подписи и шифрования';
																	|en = 'Digital signature and encryption settings'; fa = 'تنظیمات امضای دیجیتال و رمزگذاری';
																	|it = 'Impostazioni di firma elettronica e crittografia';
																	|pl = 'Ustawienia podpisu elektronicznego i szyfrowania';
																	|tr = 'Dijital imza ve şifreleme ayarları'"));
	
EndProcedure

&AtClient
Procedure ApplicationsMarkForDeletion(Command)
	
	CurrentData = Items.Programs.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	If CurrentData.DeletionMark Then
		QueryText = NStr("vi = 'Bỏ dấu xóa ""%1""?';
						|ru = 'Снять с ""%1"" пометку на удаление?';
						|en = 'Do you want to clear a deletion mark for ""%1""?'; fa = 'Do you want to clear a deletion mark for ""%1""?';
						|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
						|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
						|tr = '""%1"" için silme işareti kaldırılsın mı?'");
	Else
		QueryText = NStr("vi = 'Đặt dấu xóa ""%1""?';
						|ru = 'Пометить ""%1"" на удаление?';
						|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
						|it = 'Contrassegnare ""%1"" per cancellazione?';
						|pl = 'Zaznaczyć ""%1"" do usunięcia?';
						|tr = '""%1"" silinmek üzere işaretlensin mi?'");
	EndIf;
	
	QuestionContent = New Array;
	QuestionContent.Add(StringFunctionsClientServer.SubstituteParametersToString(QueryText, CurrentData.Description));
	
	ShowQueryBox(
		New CallbackDescription("ApplicationsSetDeletionMarkContinue", ThisObject, CurrentData.Ref),
		New FormattedString(QuestionContent),
		QuestionDialogMode.YesNo);
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure AddForSigningAndEncryptingFromFilesAfterInstallingExtension(Result, Context) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("ForSigningEncryptionAndDecryptionFromFiles",
		CreationParameters);
		
EndProcedure

&AtClient
Procedure SelectDirectoryAfterSelection(SelectedDirectory, Context) Export
	
	If Not ValueIsFilled(SelectedDirectory) Then
		PathToAddInLogOnClient = "";
	Else
		PathToAddInLogOnClient = SelectedDirectory;
	EndIf;
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure AfterPerformActionsDetails(Result, Context) Export
	DigitalSignatureInternalClient.ClearInstalledCryptoProvidersCache();
	DefineInstalledApplications();
EndProcedure

&AtClient
Procedure UpdateCertificatesList()

	CertificatesInPersonalStorage = New ValueList;
	CallbackDescription = New CallbackDescription(
		"UpdateCertificateListAfterGettingCertificatePropertiesOnClient",
		ThisObject, "UpdateAtServer");
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(CallbackDescription, True, True, True);

EndProcedure

&AtClient
Procedure AddCertificatesInPersonalVaultDynamicListParameter()
	
	Items.GroupRefreshCertificateList.Visible = True;
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(
		New CallbackDescription("UpdateCertificateListAfterGettingCertificatePropertiesOnClient", ThisObject),
		True, True, True);

EndProcedure

&AtClient
Procedure UpdateCertificateListAfterGettingCertificatePropertiesOnClient(Result, Var_Parameters) Export
	
	Items.GroupRefreshCertificateList.Visible = False;
	
	For Each KeyAndValue In Result.CertificatesPropertiesAtClient Do
		CertificatesInPersonalStorage.Add(KeyAndValue.Key); 
	EndDo;
	
	If Var_Parameters = "UpdateAtServer" Then
		SetParametersInCertificateListOnServer()
	Else	
		CurrentDate = CommonClient.UniversalDate();
		SetParametersInCertificateList(ThisObject, CertificatesInPersonalStorage, CurrentDate);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetParametersInCertificateList(Form, CertificatesList, CurrentDate)
	
	CommonClientServer.SetDynamicListParameter(
		Form.Certificates, "CertificatesInPersonalStorage", CertificatesList, True);
	CommonClientServer.SetDynamicListParameter(
		Form.Certificates, "CurrentDate", CurrentDate, True);

EndProcedure

&AtServer
Procedure SetParametersInCertificateListOnServer()

	DigitalSignatureInternal.AddListofCertificatesInPersonalStorageOnServer(CertificatesInPersonalStorage);
	SetParametersInCertificateList(ThisObject, CertificatesInPersonalStorage, CurrentUniversalDate());
	
EndProcedure	

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Programs.Use");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("ProgramsCheckResult");
	AppearanceFieldItem.Use = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("ProgramsDescription");
	AppearanceFieldItem.Use = True;
	
	If Items.ProgramsCheckResultAtServer.Visible Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
		AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
		AppearanceColorItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("Programs.IsInstalledOnServer");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = False;
		DataFilterItem.Use  = True;
		
		AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceFieldItem.Field = New DataCompositionField("ProgramsCheckResultAtServer");
		AppearanceFieldItem.Use = True;

	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Certificates.Revoked");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Certificates");
	AppearanceFieldItem.Use = True;
		
EndProcedure

&AtClientAtServerNoContext
Procedure CertificatesUpdateFilter(Form, StatusApplicationIsNotInOperation, CurrentUser = Undefined)
	
	Items = Form.Items;
	
	// Filtering certificates All/My.
	ShowOwnCertificates = Form.CertificatesShow <> "AllCertificates";
	If CurrentUser <> Undefined Then
		If ShowOwnCertificates Then
			Form.UserSelect = CurrentUser;
		Else
			Form.UserSelect = Undefined;
		EndIf;
	EndIf;
	
	// Filter by user.
	Items.CertificatesUser.Visible = Not ShowOwnCertificates;
	Items.UserSelect.Visible = Not ShowOwnCertificates;
	Form.Certificates.Parameters.SetParameterValue("CertificateUser", ?(ValueIsFilled(
		Form.UserSelect), Form.UserSelect, Undefined));
	
	// Filter by valid certificates.
	SelectionByOperating = Not Form.CertificatesShow = "MyCertificatesWithexpiringValidity" 
						And Not Form.CertificatesShow = "MyStatementsInProgress";
							
	Items.CertificatesOnlyValid.Visible = SelectionByOperating;
	CommonClientServer.SetDynamicListFilterItem(Form.Certificates,
		"Valid", True, , , SelectionByOperating And Form.CertificatesOnlyValid);
	
	CommonClientServer.SetDynamicListFilterItem(Form.Certificates,
		"DeadlineEndsSoon", True, , ,Form.CertificatesShow = "MyCertificatesWithexpiringValidity");
		
	If Form.CertificatesShow = "MyStatementsInProgress" Then
		
		Form.CertificatesShowRequests = Undefined;
		Form.Items.CertificatesShowRequests.Visible = False;
		
		FilterByApplicationState = Undefined;
		CommonClientServer.SetDynamicListFilterItem(Form.Certificates,
			"RequestStatus", StatusApplicationIsNotInOperation, DataCompositionComparisonType.NotInList, , True);
	Else
		
		Form.Items.CertificatesShowRequests.Visible = Form.CertificateIssueRequestAvailable
			And Not Form.CertificatesShow = "MyCertificatesWithexpiringValidity";
		
		If Items.CertificatesShowRequests.Visible Then
			// Filter certificates by the application status.
			FilterByApplicationState = ValueIsFilled(Form.CertificatesShowRequests);
			CommonClientServer.SetDynamicListFilterItem(Form.Certificates,
				"RequestStatus", Form.CertificatesShowRequests, , , FilterByApplicationState);
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//  FormTable - FormDataCollection
// 
// Returns:
//  Structure:
//    * Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
&AtClient
Function CertificatesCurrentData(FormTable)
	
	Return FormTable.CurrentData;
	
EndFunction

&AtClient
Procedure ApplicationsSetDeletionMarkContinue(Response, CurrentApplication) Export
	
	If Response = DialogReturnCode.Yes Then
		ChangeApplicationDeletionMark(CurrentApplication);
		NotifyChanged(CurrentApplication);
		Notify("Write_DigitalSignatureAndEncryptionApplications", New Structure, CurrentApplication);
		DefineInstalledApplications();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeApplicationDeletionMark(Application)
	
	StandardProcessing = True;
	DigitalSignatureLocalization.OnChangeAppDeletionMark(Application, UUID, StandardProcessing);
	If StandardProcessing = False Then
		FillApplicationsAndSettings(True);
		Return;
	EndIf;
		
	LockDataForEdit(Application,, UUID);

	Block = New DataLock;
	LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	LockItem.SetValue("Ref", Application);

	BeginTransaction();
	Try

		Block.Lock();

		Object = Application.GetObject();
		Object.DeletionMark = Not Object.DeletionMark;
		If Object.DeletionMark Then
			Object.UsageMode = Enums.DigitalSignatureAppUsageModes.NotUsed;
		Else
			Object.UsageMode = Enums.DigitalSignatureAppUsageModes.Configured;
		EndIf;
		Object.Write();

		CommitTransaction();

	Except
		RollbackTransaction();
		UnlockDataForEdit(Application, UUID);
		Raise;
	EndTry;

	UnlockDataForEdit(Application, UUID);
		
	FillApplicationsAndSettings(True);
	
EndProcedure

&AtClient
Procedure SigningOrEncryptionUsageOnChange()
	
	UpdateCurrentItemsVisibility();
	
EndProcedure

&AtServer
Procedure UpdateCurrentItemsVisibility()
	
	If DigitalSignature.UseDigitalSignature() Then
		Items.SignatureFilesExtension.Visible = True;
		Items.ActionsOnSaveSignedData.Visible = True;
	Else
		Items.SignatureFilesExtension.Visible = False;
		Items.ActionsOnSaveSignedData.Visible = False;
	EndIf;
	
	Items.EncryptedFilesExtension.Visible = DigitalSignature.UseEncryption();
	
	// Certificates page
	Items.CertificatesPage.Visible = CertificatesAreAvailable;
	If CertificatesAreAvailable Then
		If Not HasRightToAddCertificates Then
			
			Items.GroupAddCertificates.Visible = False;
			Items.AddCertificateIssueRequest.Visible = False;
			CommonClientServer.SetFormItemProperty(
				Items, "ReissueCertificate", "Visible", False);
			Return;
		EndIf;
		
		Items.AddCertificateIssueRequest.Visible = CertificateIssueRequestAvailable;
		
		CertificateAdditionCommandProperties = DigitalSignatureInternal.CertificateAdditionCommandProperties();
		Items.AddToSignAndEncrypt.Title = CertificateAdditionCommandProperties.Title;
		Items.AddToSignAndEncrypt.ExtendedTooltip.Title = CertificateAdditionCommandProperties.ExtendedTooltipTitle;
		PurposeToSignAndEncrypt = CertificateAdditionCommandProperties.Purpose;
		
		CertificateAdditionCommandProperties = DigitalSignatureInternal.CertificateAdditionCommandProperties(True);
		Items.AddForSigningAndEncryptionFromFiles.Title = CertificateAdditionCommandProperties.Title;
		Items.AddForSigningAndEncryptionFromFiles.ExtendedTooltip.Title = CertificateAdditionCommandProperties.ExtendedTooltipTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure DefineInstalledApplications()
	
	If Items.Pages.CurrentPage = Items.ApplicationPage Then
		ApplicationsCheckPerformed = True;
		BeginAttachingCryptoExtension(New CallbackDescription(
			"DetermineApplicationsInstalledAfterAttachExtension", ThisObject));
	Else
		ApplicationsCheckPerformed = Undefined;
	EndIf;
	
EndProcedure

// Continues the DefineInstalledApplications procedure.
&AtClient
Procedure DetermineApplicationsInstalledAfterAttachExtension(Attached, Context) Export
	
	If Attached Then
		Items.GroupApplicationsRefresh.Visible = True;
	EndIf;
	
#If WebClient Then
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 0.3, True);
#Else
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 0.1, True);
#EndIf
	
EndProcedure

&AtClient
Procedure IdleHandlerDefineInstalledApplications()
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"DefineInstalledApplicationsOnAttachExtension", ThisObject));
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Async Procedure DefineInstalledApplicationsOnAttachExtension(Attached, Context) Export
	
	If Not Attached Then
#If WebClient Then
		Components = DigitalSignatureInternalClient.NewCryptoManagementAddIns();
		Components.IsCryptographicExtensionInstalled = False;
		
		IsAdditionalAddInsInstallationRequired =
			Await DigitalSignatureInternalClient.IsAdditionalAddInsInstallationRequired(Components);
		
		If IsAdditionalAddInsInstallationRequired Then
			FormParameters = New Structure;
			FormParameters.Insert("Components", Components);
			FormParameters.Insert("RequiredAddInName", "CryptographicExtension");
			FollowUpHandler = New CallbackDescription("DetermineApplicationsInstalledAfterAttachExtension", ThisObject, Context);
			OpenForm("CommonForm.StartWorkWithDigitalSignature", FormParameters, ,
				UUID, , , FollowUpHandler, FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
#Else
		ShowTitleForExtensionInstallation();
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 3, True);
		Return;
#EndIf
	EndIf;
	
	DefaultApplicationsPaths.Clear();
	
	CheckParameters = New Structure;
	CheckParameters.Insert("ShouldInstallExtension", False);
	CheckParameters.Insert("SetComponent", False);
	CheckParameters.Insert("ShouldPromptToInstallApp", False);
	CheckParameters.Insert("CheckAtServer1", False);
	CheckParameters.Insert("ExtendedDescription", True);
	
	NotificationAfterAppsCheckCompleted = New CallbackDescription(
		"DetectInstalledAppsAfterCryptoAppsChecked", ThisObject, Context);
	
	DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
		New CallbackDescription("AfterCryptographyAppsChecked", ThisObject, NotificationAfterAppsCheckCompleted));

EndProcedure

&AtClient
Async Procedure DetectInstalledAppsAfterCryptoAppsChecked(Result, Context) Export
	
	Attached = Await AttachCryptoExtensionAsync();
	
	If Not Attached Then
		ShowTitleForExtensionInstallation();
	EndIf;
	
	Context = New Structure;
	Context.Insert("IndexOf", -1);
	Context.Insert("ExtensionAttached", Attached);
	
	IdleHandlerDefineInstalledApplicationsLoopStart(Context);
	
EndProcedure

&AtClient
Procedure ShowTitleForExtensionInstallation()
	Items.GroupCryptoProvidersHint.Visible = True;
	Items.DecorationCheckCryptoProviderInstallation.Title = StringFunctionsClient.FormattedString(
			NStr("vi = '<a href = ""%1"">Hãy nhấn ở đây</a> để cài đặt phần mở rộng để làm việc với 1C:Enterprise và với chữ ký điện tử.';
				|ru = '<a href = ""%1"">Нажмите здесь</a> для установки расширения для работы с 1С:Предприятием, чтобы работать с электронной подписью.';
				|en = '<a href = ""%1"">Install 1C:Enterprise Extension</a> to manage digital signatures.'; fa = '<a href = ""%1"">Install 1C:Enterprise Extension</a> to manage digital signatures.';
				|it = '<a href = ""%1"">Нажмите здесь</a> для установки расширения для работы с 1С:Предприятием, чтобы работать с электронной подписью.';
				|pl = '<a href = ""%1"">Install 1C:Enterprise Extension</a> to manage digital signatures.';
				|tr = '1C:Enterprise ile elektronik imzalarla çalışmaya yönelik uzantıyı yüklemek için </a>buraya tıklayın <a href = ""%1"">.'"),
			"CheckCryptographyAppsInstallation");
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure IdleHandlerDefineInstalledApplicationsLoopStart(Context)
	
	If Programs.Count() <= Context.IndexOf + 1 Then
		// After loop.
		Items.GroupApplicationsRefresh.Visible = False;
		CurrentItem = Items.Programs;
		UpdateLinuxProgramPath();
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Programs.Get(Context.IndexOf);

	Context.Insert("ApplicationDetails", ApplicationDetails);
	
	If ApplicationDetails.AutoDetect Then
		TheHandlerIsWaitingToDetermineTheCurrentlyInstalledProgramsCycleAfterObtainingTheProgramPath(Undefined, Context);
	Else
		DigitalSignatureInternalClient.GetTheDefaultProgramPath(New CallbackDescription(
			"TheHandlerIsWaitingToDetermineTheCurrentlyInstalledProgramsCycleAfterObtainingTheProgramPath", ThisObject, Context),
			ApplicationDetails.Ref);
	EndIf;
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure TheHandlerIsWaitingToDetermineTheCurrentlyInstalledProgramsCycleAfterObtainingTheProgramPath(DescriptionOfWay, Context) Export
	
	ApplicationDetails = Context.ApplicationDetails;
	
	If ValueIsFilled(DescriptionOfWay) And ValueIsFilled(DescriptionOfWay.ApplicationPath) Then
		NewRow = DefaultApplicationsPaths.Add();
		NewRow.Application = ApplicationDetails.Ref;
		NewRow.Path = DescriptionOfWay.ApplicationPath;
	EndIf;
	
	If ApplicationDetails.DeletionMark Then
		UpdateValue(ApplicationDetails.CheckResult, "");
		UpdateValue(ApplicationDetails.MoreDetails, "");
		UpdateValue(ApplicationDetails.Use, "");
		UpdateValue(ApplicationDetails.IsInstalledOnServer, "");
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	ElsIf ApplicationDetails.IsBuiltInCryptoProvider
		Or DigitalSignatureInternalClientServer.PlacementOfTheCertificate(ApplicationDetails.LocationType) = "CloudSignature"
		Or ApplicationDetails.ApplicationName = "GosKey" Then
		UpdateValue(ApplicationDetails.CheckResult, NStr("vi = 'Cho phép.';
														|ru = 'Доступен.';
														|en = 'Available.'; fa = 'Available.';
														|it = 'Accessibile.';
														|pl = 'Available.';
														|tr = 'Erişilebilir.'"));
		UpdateValue(ApplicationDetails.Use, True);
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	ElsIf ApplicationDetails.IsToken Then
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	If Not Context.ExtensionAttached Then
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	ApplicationsDetailsCollection = New Array;
	ApplicationsDetailsCollection.Add(Context.ApplicationDetails);
	
	ErrorsDescription = DigitalSignatureInternalClientServer.NewErrorsDescription();
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	ExecutionParameters.Insert("IndexOf",            -1);
	ExecutionParameters.Insert("ShowError",    Undefined);
	ExecutionParameters.Insert("ErrorsDescription",    ErrorsDescription);
	ExecutionParameters.Insert("SignAlgorithm",   "");
	ExecutionParameters.Insert("InteractiveMode", False);
	ExecutionParameters.Insert("IsLinux",   DigitalSignatureInternalClient.RequiresThePathToTheProgram());
	ExecutionParameters.Insert("Manager",   Undefined);
	ExecutionParameters.Insert("Notification", New CallbackDescription(
		"IdleHandlerDefineInstalledApplicationsLoopFollowUp", ThisObject, Context));
	
	Context.Insert("ExecutionParameters", New Structure("ErrorsDescription", ErrorsDescription));
	
	DigitalSignatureInternalClient.CreateCryptoManagerLoopStart(ExecutionParameters);
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure IdleHandlerDefineInstalledApplicationsLoopFollowUp(Manager, Context) Export
	
	ApplicationDetails = Context.ApplicationDetails;
	Errors = Context.ExecutionParameters.ErrorsDescription.Errors; // Array of See DigitalSignatureInternalClientServer.NewErrorProperties
	
	If Manager <> Undefined Then
		UpdateValue(ApplicationDetails.CheckResult, NStr("vi = 'Đã cài đặt trên máy tính.';
														|ru = 'Установлено на компьютере.';
														|en = 'Installed on the computer.'; fa = 'Installed on the computer.';
														|it = 'Installed on the computer.';
														|pl = 'Installed on the computer.';
														|tr = 'Bilgisayara kuruldu.'"));
		If ValueIsFilled(ApplicationDetails.CheckResultAtServer)
			And ApplicationDetails.IsInstalledOnServer <> True Then
			UpdateValue(ApplicationDetails.MoreDetails, NStr("vi = 'Chi tiết';
															|ru = 'Подробнее';
															|en = 'Details'; fa = 'جزئیات';
															|it = 'Dettagliatamente';
															|pl = 'Details';
															|tr = 'Ayrıntılar'") + "...");
		Else
			UpdateValue(ApplicationDetails.MoreDetails, "");
		EndIf;
		UpdateValue(ApplicationDetails.Use, True);
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	For Each Error In Errors Do
		Break;
	EndDo;
	
	If Error.PathNotSpecified Then
		UpdateValue(ApplicationDetails.CheckResult, Error.LongDesc);
		UpdateValue(ApplicationDetails.MoreDetails, NStr("vi = 'Chi tiết';
														|ru = 'Подробнее';
														|en = 'Details'; fa = 'جزئیات';
														|it = 'Dettagliatamente';
														|pl = 'Details';
														|tr = 'Ayrıntılar'") + "...");
		UpdateValue(ApplicationDetails.Use, "");
	Else
		ErrorText = NStr("vi = 'Chưa cài đặt trên máy tính.';
						|ru = 'Не установлено на компьютере.';
						|en = 'Not installed on the computer.'; fa = 'Not installed on the computer.';
						|it = 'Not installed on the computer.';
						|pl = 'Not installed on the computer.';
						|tr = 'Bilgisayara kurulmadı.'") + " " + Error.LongDesc;
		If Error.ToAdministrator And Not IsFullUser Then
			ErrorText = ErrorText + " " + NStr("vi = 'Hãy liên hệ với người quản trị.';
												|ru = 'Обратитесь к администратору.';
												|en = 'Please contact the application administrator.'; fa = 'Please contact the application administrator.';
												|it = 'Contattate l''amministratore.';
												|pl = 'Skontaktuj się z administratorem.';
												|tr = 'Yöneticiye başvurun.'");
		EndIf;
		UpdateValue(ApplicationDetails.CheckResult, ErrorText);
		UpdateValue(ApplicationDetails.MoreDetails, NStr("vi = 'Chi tiết';
														|ru = 'Подробнее';
														|en = 'Details'; fa = 'جزئیات';
														|it = 'Dettagliatamente';
														|pl = 'Details';
														|tr = 'Ayrıntılar'") + "...");
		UpdateValue(ApplicationDetails.Use, False);
	EndIf;
	
	IdleHandlerDefineInstalledApplicationsLoopStart(Context);
	
EndProcedure

&AtClient
Procedure UpdateLinuxProgramPath()
	
	CurrentData = Items.Programs.CurrentData;
	
	DefaultPath = "";
	If CurrentData <> Undefined Then
		If CurrentData.AutoDetect Then
			Items.ApplicationsLinuxPathToApplication.DropListButton = False;
			Items.ApplicationsLinuxPathToApplication.ReadOnly = True;
			Items.ApplicationsLinuxPathToApplication.InputHint = NStr("vi = 'Xác định tự động';
																		|ru = 'Определяется автоматически';
																		|en = 'Determined automatically'; fa = 'به‌طور خودکار تعیین می‌شود';
																		|it = 'Rilevato automaticamente';
																		|pl = 'Jest określany automatycznie';
																		|tr = 'Otomatik olarak tanımlanır'");
			Return;
		EndIf;
		
		Filter = New Structure("Application", CurrentData.Ref);
		Rows = DefaultApplicationsPaths.FindRows(Filter);
		If Rows.Count() > 0 Then
			DefaultPath = Rows[0].Path;
		EndIf;
	EndIf;
	
	Items.ApplicationsLinuxPathToApplication.DropListButton = ValueIsFilled(DefaultPath);
	Items.ApplicationsLinuxPathToApplication.InputHint = DefaultPath;
	Items.ApplicationsLinuxPathToApplication.ReadOnly = False;
	
	TheListOfChoices = Items.ApplicationsLinuxPathToApplication.ChoiceList;
	TheListOfChoices.Clear();
	If ValueIsFilled(DefaultPath) Then
		If CommonClient.IsLinuxClient() Then
			TheListOfChoices.Add("LinuxPath", NStr("vi = 'Đường dẫn chuẩn cho Linux';
													|ru = 'Стандартный путь для Linux';
													|en = 'Standard path for Linux'; fa = 'Standard path for Linux';
													|it = 'Percorso standard per Linux';
													|pl = 'Standardowa ścieżka dla Linux';
													|tr = 'Linux için standart yol'"));
		Else
			TheListOfChoices.Add("MacPath", NStr("vi = 'Đường dẫn chuẩn cho Mac OS';
												|ru = 'Стандартный путь для Mac OS';
												|en = 'Standard path for macOS'; fa = 'Standard path for macOS';
												|it = 'Percorso standard per Mac OS';
												|pl = 'Standardowa ścieżka dla Mac OS';
												|tr = 'Mac OS için standart yol'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeApplicationsCompositionOrSettings()
	
	FillApplicationsAndSettings();
	
	DefineInstalledApplications();
	
EndProcedure

&AtClient
Procedure AfterCryptographyAppsChecked(Result, Notification) Export
	
	If Not Result.CheckCompleted Then
#If MobileClient Or MobileAppClient Then
		StandardProcessing = True;
		DigitalSignatureClientLocalization.OnGettingTokens(
			New CallbackDescription("AfterGettingTokensInMobileClient", ThisObject, Notification), False, StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
#Else
		Items.GroupCryptoProvidersHint.Visible = True;
		Items.DecorationCheckCryptoProviderInstallation.Title = StringFunctionsClient.FormattedString(
			NStr("vi = '<a href = ""%1"">Hãy nhấn ở đây</a>, để xem tất cả các ứng dụng dành cho làm việc với chữ ký điện tử mà được cài đặt trên máy tính.';
				|ru = '<a href = ""%1"">Нажмите здесь</a>, чтобы увидеть все приложения для работы с электронной подписью, установленные на компьютере.';
				|en = '<a href = ""%1"">Click here</a> to view all installed digital signing apps.'; fa = '<a href = ""%1"">Click here</a> to view all installed digital signing apps.';
				|it = '<a href = ""%1"">Нажмите здесь</a>, чтобы увидеть все приложения для работы с электронной подписью, установленные на компьютере.';
				|pl = '<a href = ""%1"">Click here</a> to view all installed digital signing apps.';
				|tr = 'Bilgisayarınızda yüklü tüm elektronik imza uygulamalarını görmek için buraya </a>tıklayın <a href = ""%1"">.'"),
			"CheckCryptographyAppsInstallation");
#EndIf
	ElsIf Result.IsConflictPossible Then
		DigitalSignatureClientLocalization.OnCheckCryptoAppsConflict(ThisObject, Result);
	Else
		Items.GroupCryptoProvidersHint.Visible = False;
	EndIf;
		
	If Result.CheckCompleted Then
		
		For Each Cryptoprovider In Result.Programs Do
			
			If ValueIsFilled(Cryptoprovider.Application) And Not HasAppsToCheck Then
				HasAppsToCheck = True;
			EndIf;
			
			Found4 = Programs.FindRows(New Structure("ApplicationName, ApplicationType",
				Cryptoprovider.ApplicationName, Cryptoprovider.ApplicationType));
			
			If Found4.Count() = 0
				Or DigitalSignatureInternalClientServer.AreAutomaticSettingsUsed(Found4[0].UsageMode) Then
				
				If Found4.Count() = 0 Then 
					NewRow = Programs.Add();
				Else
					NewRow = Found4[0];
				EndIf;
				
				FillPropertyValues(NewRow, Cryptoprovider,, "Ref, AppPathAtServerAuto");
				NewRow.LinuxApplicationPath = NewRow.PathToAppAuto;
				NewRow.LocationType = 1;
				NewRow.AutoDetect = True;
				NewRow.PictureUsageMode = -1;
				NewRow.Description = Cryptoprovider.Presentation;
			EndIf;
			
		EndDo;
		FillTokensList(Result.Tokens);
		DigitalSignatureClientLocalization.OnCheckInstalledCryptoApps(ThisObject, Result, HasAppsToCheck);
	EndIf;
	
	If Notification <> Undefined Then
		RunCallback(Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGettingTokensInMobileClient(Tokens, Notification) Export
	If ValueIsFilled(Tokens) Then
		FillTokensList(Tokens);
	EndIf;
	If Notification <> Undefined Then
		RunCallback(Notification);
	EndIf;
EndProcedure

&AtClient
Procedure FillTokensList(Tokens)
	For Each Token In Tokens Do
		
		Found4 = Programs.FindRows(New Structure("Description",Token.Presentation));
		
		If Found4.Count() = 0 Then 
			NewRow = Programs.Add();
		Else
			NewRow = Found4[0];
		EndIf;
		
		NewRow.LocationType = 1;
		NewRow.AutoDetect = True;
		NewRow.PictureUsageMode = -1;
		NewRow.Description = Token.Presentation;
		NewRow.IsToken = True;
		NewRow.ApplicationName = Token.SerialNumber;
		NewRow.Slot = Token.Slot;
		NewRow.Action = "";
		NewRow.Parameters = Undefined;
		NewRow.MoreDetails = "";
		NewRow.CheckResult = ?(ValueIsFilled(Token.Error), Token.Error, NStr("vi = 'Cho phép.';
																			|ru = 'Доступен.';
																			|en = 'Available.'; fa = 'Available.';
																			|it = 'Доступен.';
																			|pl = 'Available.';
																			|tr = 'Erişilebilir.'"));
		
		If ValueIsFilled(Token.Error) Then
			If DigitalSignatureInternalClientServer.TokenLibraryLoadingError(Token.Error) Then
				NewRow.MoreDetails = NStr("vi = 'Cài đặt';
											|ru = 'Установить';
											|en = 'Install'; fa = 'نصب';
											|it = 'Install';
											|pl = 'Install';
											|tr = 'Ayarla'") + "...";
				NewRow.Action = DigitalSignatureInternalClientServer.ActionInstallLibrariesForTokens();
				NewRow.Parameters = New Structure("TokenKind", Token.Token);
			Else
				NewRow.MoreDetails = NStr("vi = 'Chi tiết';
											|ru = 'Подробнее';
											|en = 'Details'; fa = 'جزئیات';
											|it = 'Подробнее';
											|pl = 'Details';
											|tr = 'Dana fazla'") + "...";
			EndIf;
		EndIf;
		
	EndDo;
EndProcedure

&AtServer
Procedure FillApplicationsAndSettings(RefreshCached = False)
	
	If RefreshCached Then
		RefreshReusableValues();
	EndIf;
	
	PersonalSettings = DigitalSignature.PersonalSettings();

	ActionsOnSavingWithDS                   = PersonalSettings.ActionsOnSavingWithDS;
	EncryptedFilesExtension           = PersonalSettings.EncryptedFilesExtension;
	SignatureFilesExtension                 = PersonalSettings.SignatureFilesExtension;
	ApplicationsPaths                            = PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications;
	SaveCertificateWithSignature         = PersonalSettings.SaveCertificateWithSignature;

	HasApplicationsAtServer                     = False;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Programs.Ref,
	|	Programs.Description AS Description,
	|	Programs.ApplicationName,
	|	Programs.ApplicationType,
	|	Programs.SignAlgorithm,
	|	Programs.HashAlgorithm,
	|	Programs.EncryptAlgorithm,
	|	Programs.DeletionMark AS DeletionMark,
	|	Programs.IsBuiltInCryptoProvider,
	|	Programs.UsageMode,
	|	1 AS LocationType
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs
	|WHERE
	|	NOT Programs.IsBuiltInCryptoProvider
	|
	|UNION ALL
	|
	|SELECT
	|	Programs.Ref,
	|	Programs.Description,
	|	Programs.ApplicationName,
	|	Programs.ApplicationType,
	|	Programs.SignAlgorithm,
	|	Programs.HashAlgorithm,
	|	Programs.EncryptAlgorithm,
	|	Programs.DeletionMark,
	|	Programs.IsBuiltInCryptoProvider,
	|	VALUE(Enum.DigitalSignatureAppUsageModes.Configured),
	|	4
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs
	|WHERE
	|	Programs.IsBuiltInCryptoProvider
	|	AND &UseDigitalSignatureSaaS
	|
	|ORDER BY
	|	Description";
	
	Query.SetParameter("UseDigitalSignatureSaaS", 
		DigitalSignatureInternal.UseDigitalSignatureSaaS());
	
	TheSampleTable = Query.Execute().Unload();
	
	DigitalSignatureLocalization.OnFillDigitalSignatureApps(TheSampleTable);
	
	TheSampleTable.Columns.Add("AppPathAtServerAuto", New TypeDescription("String"));
	TheSampleTable.Columns.Add("CheckResultAtServer", New TypeDescription("String"));
	TheSampleTable.Columns.Add("AutoDetect", New TypeDescription("Boolean"));
	
	Settings = DigitalSignature.CommonSettings();
	If Settings.VerifyDigitalSignaturesOnTheServer Or Settings.GenerateDigitalSignaturesAtServer Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ExtendedDescription", True);
		ResultCryptoProviders = DigitalSignature.CheckCryptographyAppsInstallation(CheckParameters);
		
		If ResultCryptoProviders.CheckCompleted Then
			
			For Each Cryptoprovider In ResultCryptoProviders.Programs Do
				
				If ValueIsFilled(Cryptoprovider.Application) And Not HasAppsToCheck Then
					HasAppsToCheck = True;
				EndIf;
				
				Found4 = TheSampleTable.FindRows(New Structure("ApplicationName, ApplicationType",
					Cryptoprovider.ApplicationName, Cryptoprovider.ApplicationType));
				
				If Found4.Count() = 0
					Or DigitalSignatureInternalClientServer.AreAutomaticSettingsUsed(Found4[0].UsageMode) Then
					If Found4.Count() = 0 Then 
						SelectionString = TheSampleTable.Add();
					Else
						SelectionString = Found4[0];
					EndIf;
					FillPropertyValues(SelectionString, Cryptoprovider,,"Ref");
					SelectionString.LocationType = 1;
					SelectionString.DeletionMark = False;
					SelectionString.AppPathAtServerAuto = Cryptoprovider.AppPathAtServerAuto;
					SelectionString.Description = Cryptoprovider.Presentation;
					SelectionString.AutoDetect = True;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		Items.ProgramsCheckResultAtServer.Visible = IsFullUser;
	Else
		Items.ProgramsCheckResultAtServer.Visible = False;
	EndIf;
	
	ProcessedRows = New Map;
	IndexOf = 0;
	
	For Each SelectionString In TheSampleTable Do
		
		ApplicationNotUsed = DigitalSignatureInternalClientServer.ApplicationNotUsed(SelectionString.UsageMode);
		
		If Not Users.IsFullUser() 
			And (ApplicationNotUsed Or SelectionString.DeletionMark) Then
			Continue;
		EndIf;
		
		If ValueIsFilled(SelectionString.Ref) Then
			Rows = Programs.FindRows(New Structure("Ref", SelectionString.Ref));
		Else
			Rows = Programs.FindRows(New Structure("ApplicationName, ApplicationType",
				SelectionString.ApplicationName, SelectionString.ApplicationType));
		EndIf;
		
		If Rows.Count() = 0 Then
			If Programs.Count()-1 < IndexOf Then
				String = Programs.Add();
			Else
				String = Programs.Insert(IndexOf);
			EndIf;
		Else
			String = Rows[0];
			RowIndex = Programs.IndexOf(String);
			If RowIndex <> IndexOf Then
				Programs.Move(RowIndex, IndexOf - RowIndex);
			EndIf;
		EndIf;
		// Updating only changed values not to update the form table once again.
		UpdateValue(String.Ref,                       SelectionString.Ref);
		UpdateValue(String.DeletionMark,              SelectionString.DeletionMark);
		UpdateValue(String.Description,                 SelectionString.Description);
		UpdateValue(String.ApplicationName,                 SelectionString.ApplicationName);
		UpdateValue(String.ApplicationType,                 SelectionString.ApplicationType);
		UpdateValue(String.SignAlgorithm,              SelectionString.SignAlgorithm);
		UpdateValue(String.HashAlgorithm,          SelectionString.HashAlgorithm);
		UpdateValue(String.EncryptAlgorithm,           SelectionString.EncryptAlgorithm);
		UpdateValue(String.AutoDetect,              SelectionString.AutoDetect);
		UpdateValue(String.UsageMode,           SelectionString.UsageMode);
		UpdateValue(String.AppPathAtServerAuto,  SelectionString.AppPathAtServerAuto);
		UpdateValue(String.IsBuiltInCryptoProvider, SelectionString.IsBuiltInCryptoProvider);
		
		If ApplicationNotUsed And Not SelectionString.DeletionMark Then
			UpdateValue(String.LocationType, 9);
		Else
			UpdateValue(String.LocationType, SelectionString.LocationType + ?(SelectionString.DeletionMark, 4, 0));
		EndIf;
		
		If SelectionString.AutoDetect Then // The installed cryptographic service provider.
			UpdateValue(String.LinuxApplicationPath, SelectionString.AppPathAtServerAuto);
			UpdateValue(String.PictureUsageMode, -1);
		Else
			UpdateValue(String.LinuxApplicationPath, ApplicationsPaths.Get(SelectionString.Ref));
			UpdateValue(String.PictureUsageMode, 0);
		EndIf;
		
		Structure = New Structure;
		DigitalSignatureClientServerLocalization.OnDefineAppAvailability(SelectionString, Structure);
		If ValueIsFilled(Structure) Then
			For Each KeyAndValue In Structure Do
				UpdateValue(String[KeyAndValue.Key], KeyAndValue.Value);
			EndDo;
		ElsIf String.IsBuiltInCryptoProvider And Not String.DeletionMark Then
			UpdateValue(String.CheckResult, NStr("vi = 'Cho phép.';
												|ru = 'Доступен.';
												|en = 'Available.'; fa = 'Available.';
												|it = 'Disponibile.';
												|pl = 'Available.';
												|tr = 'Erişilebilir.'"));
			UpdateValue(String.Use, True);
		ElsIf String.LocationType = 1 And (Settings.VerifyDigitalSignaturesOnTheServer Or Settings.GenerateDigitalSignaturesAtServer) Then
			CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
			CreationParameters.AutoDetect = False;
			ApplicationDetails = DigitalSignatureInternalClientServer.NewExtendedApplicationDetails();
			FillPropertyValues(ApplicationDetails, String);
			ApplicationDetails.Presentation = String.Description;
			CreationParameters.Application = ApplicationDetails;
			CreationParameters.ErrorDescription = New Structure;
			CryptoManager = DigitalSignatureInternal.CryptoManager("", CreationParameters);
			If CryptoManager = Undefined Then
				UpdateValue(String.CheckResultAtServer, CreationParameters.ErrorDescription.ErrorDescription);
				UpdateValue(String.IsInstalledOnServer, False);
			Else
				UpdateValue(String.CheckResultAtServer, NStr("vi = 'Đã cài đặt trên máy chủ.';
															|ru = 'Установлена на сервере.';
															|en = 'Installed on the server.'; fa = 'Installed on the server.';
															|it = 'Установлена на сервере.';
															|pl = 'Installed on the server.';
															|tr = 'Sunucuda kuruldu.'"));
				UpdateValue(String.IsInstalledOnServer, True);
			EndIf;
		EndIf;
		
		ProcessedRows.Insert(String, True);
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = Programs.Count()-1;
	While IndexOf >=0 Do
		String = Programs.Get(IndexOf);
		If ProcessedRows.Get(String) = Undefined Then
			Programs.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateValue(PreviousValue2, NewValue)
	
	If PreviousValue2 <> NewValue Then
		PreviousValue2 = NewValue;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings()
	
	SavingSettings = New Structure;
	SavingSettings.Insert("ActionsOnSavingWithDS",                   ActionsOnSavingWithDS);
	SavingSettings.Insert("EncryptedFilesExtension",           EncryptedFilesExtension);
	SavingSettings.Insert("SignatureFilesExtension",                 SignatureFilesExtension);
	SavingSettings.Insert("SaveCertificateWithSignature",         SaveCertificateWithSignature);
		
	SystemInfo = New SystemInfo;
	ClientID = SystemInfo.ClientID;
	
	SavingSettings.Insert("PathToAddInLogOnClient", PathToAddInLogOnClient);
	
	SaveSettingsAtServer(SavingSettings, ClientID);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(SavingSettings, ClientID)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	PathToDiagnosticsDirectory = PersonalSettings.PathToDiagnosticsDirectory;
	FillPropertyValues(PersonalSettings, SavingSettings);
	PersonalSettings.PathToDiagnosticsDirectory.Insert(ClientID,
		SavingSettings.PathToAddInLogOnClient);
	DigitalSignatureInternal.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on the client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SaveLinuxPathAtServer(Application, LinuxPath)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications.Insert(Application, LinuxPath);
	DigitalSignatureInternal.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on the client.
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure SaveApplicationPath()
	
	CurrentData = Items.Programs.CurrentData;
	If NoRightToSaveUserData Then
		CurrentData.LinuxApplicationPath = LinuxPathToCurrentApplication;
		ShowMessageBox(,
			NStr("vi = 'Không thể lưu đường dẫn đến ứng dụng. Không có quyền lưu dữ liệu, hãy liên hệ với người quản trị.';
				|ru = 'Невозможно сохранить путь к приложению. Отсутствует право сохранения данных, обратитесь к администратору.';
				|en = 'Couldn''t save the path: Insufficient rights to save data. Contact your administrator.'; fa = 'Couldn''t save the path: Insufficient rights to save data. Contact your administrator.';
				|it = 'Невозможно сохранить путь к приложению. Отсутствует право сохранения данных, обратитесь к администратору.';
				|pl = 'Couldn''t save the path: Insufficient rights to save data. Contact your administrator.';
				|tr = 'Uygulama yolu kaydedilemiyor. Veri kaydetme hakkı yok, yöneticiye başvurun.'"));
	Else
		SaveLinuxPathAtServer(CurrentData.Ref, CurrentData.LinuxApplicationPath);
		DefineInstalledApplications();
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallConnectReportVersionComponents(SuggestToImport)
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Cần cài đặt cấu phần %1';
			|ru = 'Требуется установка компоненты %1';
			|en = 'Add-in is required: %1'; fa = 'Add-in is required: %1';
			|it = 'È richiesta l''impostazione della componente %1';
			|pl = 'Potrzebna jest instalacja komponentu %1';
			|tr = 'Bileşen kurulumu gerekli%1'"), "ExtraCryptoAPI");
	ConnectionParameters.SuggestToImport = SuggestToImport;
	ConnectionParameters.SuggestInstall = True;
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	
	CommonClient.AttachAddInFromTemplate(
		New CallbackDescription("ReportResultConnectionsComponents", ThisObject),
		ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName,
		ConnectionParameters);
		
EndProcedure

&AtClient
Procedure ReportResultConnectionsComponents(Result, AdditionalParameters) Export
	
	If Result.Attached Then
		Try 
			NotificationAfterReceivingTheVersion = New CallbackDescription("ReportComponentVersionAfterConnecting", ThisObject);
			Result.Attachable_Module.BeginCallingGetVersion(NotificationAfterReceivingTheVersion);
			Return;
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định phiên bản cấu phần.
				|%1';
				|ru = 'Не удалось определить версию компоненты.
				| %1';
				|en = 'Couldn''t determine the add-in version.
				|%1'; fa = 'Couldn''t determine the add-in version.
				|%1';
				|it = 'Non è stato possibile definire la versione della componente.
				|%1';
				|pl = 'Nie udało się określić wersji komponentu.
				| %1';
				|tr = 'Bileşen sürümü belirlenemedi.
				|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, ErrorText);
		EndTry;
	Else
		If IsBlankString(Result.ErrorDescription) Then 
			// A user canceled the installation.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa cài đặt cấu phần %1.';
					|ru = 'Компонента %1 не установлена.';
					|en = 'Add-in %1 is not installed.'; fa = 'Add-in %1 is not installed.';
					|it = 'Componente %1 non impostata.';
					|pl = 'Komponent %1 nie jest zainstalowany.';
					|tr = '%1bileşeni kurulmadı.'"), "ExtraCryptoAPI");
			ShowMessageBox(, ErrorText);
		Else 
			// Installation failed. The error description is in Result.ErrorDetails.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa cài đặt cấu phần %1 (%2).';
					|ru = 'Компонента %1 не установлена (%2).';
					|en = 'Add-in %1 is not installed (%2).'; fa = 'Add-in %1 is not installed (%2).';
					|it = 'Componente %1 non impostata (%2).';
					|pl = 'Komponent %1 nie jest zainstalowany (%2).';
					|tr = '%1bileşeni kurulmadı (%2).'"), "ExtraCryptoAPI", Result.ErrorDescription);
			ShowMessageBox(, ErrorText);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ReportComponentVersionAfterConnecting(Result, Var_Parameters, AdditionalParameters) Export
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã cài đặt cấu phần %1 phiên bản %2.';
			|ru = 'Установлена компонента %1 версии %2.';
			|en = 'Add-in %1 version is %2.'; fa = 'Add-in %1 version is %2.';
			|it = 'Impostata componente %1della versione %2.';
			|pl = 'Zainstalowano komponent %1 wersji %2.';
			|tr = '%2sürümünün %1bileşeni kuruldu.'"), "ExtraCryptoAPI", Result);
	ShowMessageBox(, MessageText);
	RefreshReusableValues();
	DigitalSignatureInternalClient.ClearInstalledCryptoProvidersCache();
	Notify("Installation_AddInExtraCryptoAPI");
	
EndProcedure

#EndRegion
