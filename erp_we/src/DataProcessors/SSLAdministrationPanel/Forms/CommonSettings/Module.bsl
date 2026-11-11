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
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		
		Items.ConfigureSecurityProfilesUsageGroup.Visible =
			  Users.IsFullUser(, True)
			And ModuleSafeModeManagerInternal.CanSetUpSecurityProfiles();
	Else
		Items.ConfigureSecurityProfilesUsageGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Items.OpenProxyServerParametersGroup.Visible =
			  Users.IsFullUser(, True)
			And Not Common.FileInfobase();
	Else
		Items.OpenProxyServerParametersGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		
		If Common.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
			Items.MobileSignatureGroup.Visible = True;
		Else
			Items.MobileSignatureGroup.Visible = False;
		EndIf;

		Items.GenerateDigitalSignaturesAtServer.Visible = Not Common.DataSeparationEnabled();
		
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		
		If Common.FileInfobase()
			And Not Common.ClientConnectedOverWebServer() Then
			Items.GroupAutomaticProcessingSignatures.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	Else
		Items.DigitalSignatureAndEncryptionGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Items.PropertiesGroup.Visible = False;
	Else
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		If Not ModulePropertyManager.HasLabelsOwners() Then
			Items.GroupLabels.Visible = False;
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		ThisIsTheAdministrator = Users.IsFullUser(, True);
		Items.UseCloudSignatureService.Visible = ThisIsTheAdministrator;
		Items.UseCloudSignatureService.Enabled = ThisIsTheAdministrator And ModuleDigitalSignature.AccessToInternetServicesAllowed();
		Items.UseCloudSignatureService.ExtendedTooltip.Title = StringFunctions.FormattedString(
					"Allows use for signings services signatures DSS. Use ofservice for formations ofqualified ofelectronic signatures requires <a href = ""DSSSettings"">additional_3 ofsettings</a>.")
	Else	
		Items.CloudSignatureGroup.Visible = False;
	EndIf;
		
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		Items.VersioningGroup.Visible = False;
	EndIf;
	
	Items.InfobasePublishingGroup.Visible = Not (Common.DataSeparationEnabled() 
		Or Common.IsStandaloneWorkplace());
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		StoreChangeHistory = ModuleObjectsVersioning.StoreHistoryCheckBoxValue();
	Else 
		Items.VersioningGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") 
		And Users.IsFullUser(, True) Then
		
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		UseFullTextSearch = ModuleFullTextSearchServer.UseSearchFlagValue();
	Else
		Items.FullTextSearchManagementGroup.Visible = False;
	EndIf;
	
	If (Common.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") )
		And Users.IsFullUser(, True) Then
		
		ModuleMarkedObjectsDeletion = Common.CommonModule("MarkedObjectsDeletion");
		ScheduledJobMode = ModuleMarkedObjectsDeletion.ModeDeleteOnSchedule();
		DeleteMarkedObjectsUsage = ScheduledJobMode.Use;
		Items.SetUpSchedule.Enabled = DeleteMarkedObjectsUsage;
		Items.ScheduledMarkedObjectsDeletionGroup.Visible = Not Common.DataSeparationEnabled();
		
	Else
		Items.MarkedObjectsDeletionGroup.Visible = False;
	EndIf;
	
	FillInTimeZones();
	
	If Common.SeparatedDataUsageAvailable() Then
		AppTimeZone = GetInfoBaseTimeZone();
		If IsBlankString(AppTimeZone) Then
			AppTimeZone = TimeZone();
		EndIf;
	Else
		AppTimeZone = SessionTimeZone();
	EndIf;
	
	Items.AccountingLanguages.Visible = 
		Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport")
		And Metadata.Languages.Count() > 1;
	
	SettingsSectionPerformance();
	
	SetAvailability();
	
	ApplicationSettingsOverridable.CommonSettingsOnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("SetVisibilityWaitHandler", 1, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.StoreHistoryCheckBoxChangeNotificationProcessing(
			EventName, 
			StoreChangeHistory);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
			EventName, 
			UseFullTextSearch);
	EndIf;
		
	If EventName = "Write_ConstantsSet" And Source = "AllowAccessToInternetServices" Then
		SetAvailability("AllowAccessToInternetServices");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationTitleOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
EndProcedure

&AtClient
Procedure UsePropertiesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure InfobasePublicationURLOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure WindowsTemporaryFilesDerectoryOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure LinuxTemporaryFilesDerectoryOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);

EndProcedure

&AtClient
Procedure LongRunningOperationsThreadCountOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure InfobasePublicationURLStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("InfobasePublicationURLStartChoiceContinued", 0.1, True);
	
EndProcedure

&AtClient
Procedure LocalInfobasePublishingURLStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("LocalInfobasePublishingURLStartChoiceContinued", 0.1, True);
	
EndProcedure

&AtClient
Procedure StoreChangeHistoryOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OnStoreHistoryCheckBoxChange(StoreChangeHistory);
	EndIf;
	
	SetAvailability("StoreChangeHistory");
	
EndProcedure

&AtClient
Procedure UseFullTextSearchOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
	EndIf;
	
	SetAvailability("UseFullTextSearch");
	
EndProcedure

&AtClient
Procedure DeleteMarkedObjectsUsageOnChange(Item)
	ChangeNotification1 = New CallbackDescription("DeleteMarkedObjectsUsageOnChangeCompletion", ThisObject);
	
	If (CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion")) Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.OnChangeCheckBoxDeleteOnSchedule(DeleteMarkedObjectsUsage, ChangeNotification1);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteMarkedObjectsUsageOnChangeCompletion(Update, AdditionalParameters) Export
	If (Update = Undefined) Then
		Return;
	EndIf;
	
	DeleteMarkedObjectsUsage = Update.Use;
	Items.SetUpSchedule.Enabled = DeleteMarkedObjectsUsage;
EndProcedure

&AtClient
Procedure SignatureTypeOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure TimestampServersAddressesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);

EndProcedure

&AtClient
Procedure AddTimestampsAutomaticallyOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure RefineSignaturesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure RefineSignaturesDatesOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure VerifyDigitalSignaturesOnTheServerOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure GenerateDigitalSignaturesAtServerOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure GroupAutomaticProcessingSignaturesExtendedTooltipURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	ProcessingNavigationLinkOpeningSettingsES(
		Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure DecorationCheckCryptoProviderInstallationURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	ProcessingNavigationLinkOpeningSettingsES(
		Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure VerifyDigitalSignaturesOnTheServerExtendedTooltipURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	ProcessingNavigationLinkOpeningSettingsES(
		Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure GenerateDigitalSignaturesAtServerExtendedTooltipURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	ProcessingNavigationLinkOpeningSettingsES(
		Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure CryptoSignatureTypeDefaultExtendedTooltipURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	ProcessingNavigationLinkOpeningSettingsES(
		Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure RefineSignaturesAutomaticallyExtendedTooltipURLProcessing(
	Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.OpenReportExtendValidityofElectronicSignatures("RequireImprovementSignatures")
	EndIf;
	
EndProcedure

&AtClient
Procedure UseCloudSignatureServiceExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "DSSSettings" Then
		FileSystemClient.OpenURL(AddressOfArticleAboutDSSService());
	EndIf;
	
EndProcedure

&AtClient
Procedure UseCloudSignatureServiceOnChange(Item)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		Return;
	EndIf;
	
	If ConstantsSet.UseDSSService Then
		
		CycleParameters = New Structure;
		CycleParameters.Insert("Item", Item);
		
		TheNotificationIsAsFollows = New CallbackDescription("CheckIfDSSUsageEnabled", ThisObject, CycleParameters);
		ListOfCommands = New ValueList;
		ListOfCommands.Add("OK", NStr("vi = 'Xác nhận';
										|ru = 'Подтвердить';
										|en = 'Confirm'; fa = 'تأیید';
										|it = 'Подтвердить';
										|pl = 'Confirm';
										|tr = 'Onayla'"));
		ListOfCommands.Add("None", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Отмена';
										|pl = 'Cancel';
										|tr = 'İptal'"), True);
		QueryText = NStr("vi = 'Chú ý, nếu dịch vụ chữ ký DSS được dùng để tạo chữ ký điện tử đủ điều kiện thì cần tự tùy chỉnh để thực hiện <a href = ""%1"">yêu cầu</a>, đối với chữ ký này.';
						|ru = 'Внимание, если сервис подписи DSS будет использоваться для формирования квалифицированной электронной подписи, то нужно самостоятельно произвести настройки для выполнения <a href = ""%1"">требований</a>, предъявляемых к такой подписи.';
						|en = 'Attention. If you plan to use the DSS signature service to generate a qualified digital signature, set it up on your own to meet the <a href = ""%1"">requirements</a> for such signature.'; fa = 'Attention. If you plan to use the DSS signature service to generate a qualified digital signature, set it up on your own to meet the <a href = ""%1"">requirements</a> for such signature.';
						|it = 'Внимание, если сервис подписи DSS будет использоваться для формирования квалифицированной электронной подписи, то нужно самостоятельно произвести настройки для выполнения <a href = ""%1"">требований</a>, предъявляемых к такой подписи.';
						|pl = 'Attention. If you plan to use the DSS signature service to generate a qualified digital signature, set it up on your own to meet the <a href = ""%1"">requirements</a> for such signature.';
						|tr = 'Dikkat! DSS imza hizmeti elektronik imza kalifikasyonunun oluşturulmasında kullanılacaksa, bu durumda böyle bir imza için gereken <a href = ""%1"">gereksinim</a> işleminin gerçekleşmesi için kendi ayarlarınızı yapmanız gerekmektedir.'") 
			+ Chars.LF + Chars.LF
			+ NStr("vi = 'Bạn xác nhận sử dụng dịch vụ?';
					|ru = 'Подтверждаете использование сервиса?';
					|en = 'Do you confirm the service use?'; fa = 'Do you confirm the service use?';
					|it = 'Подтверждаете использование сервиса?';
					|pl = 'Do you confirm the service use?';
					|tr = 'Hizmetin kullanımının onaylanması'");
			
		QueryText = StringFunctionsClient.FormattedString(QueryText, AddressOfArticleAboutDSSService());
		
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClient.OutputQuestion(
			TheNotificationIsAsFollows,
			QueryText,
			ListOfCommands,
			,
			NStr("vi = 'Cần tùy chỉnh bổ sung';
				|ru = 'Требуются дополнительные настройки';
				|en = 'Additional settings are required'; fa = 'Additional settings are required';
				|it = 'Требуются дополнительные настройки';
				|pl = 'Additional settings are required';
				|tr = 'Ek ayarlar gerekmektedir'"));
			
	Else
		Attachable_OnChangeAttribute(Item);
		
	EndIf;

EndProcedure

&AtClient
Procedure AppTimeZoneOnChange(Item)
	
	AppTimeZoneOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure TimestampServersAddressesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("TimestampServersAddressesStartChoiceContinued", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SecurityProfilesUsage(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenSecurityProfileSetupDialog();
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalAttributes(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.OpenPropertiesList(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalInfo(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.OpenPropertiesList(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure Labels(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.OpenPropertiesList(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureChangesHistoryStorage(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.ShowSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureFullTextSearch(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.ShowSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure RegionalSettings(Command)
	
	FormParameters = New Structure("Source", "SSLAdministrationPanel");
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClient = CommonClient.CommonModule("NationalLanguageSupportClient");
		ModuleNationalLanguageSupportClient.OpenTheRegionalSettingsForm(, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewObjectsMarkedForDeletion(Command)
	If (CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion")) Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.GoToMarkedForDeletionItems(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	If (CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion")) Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.StartChangeJobSchedule();
	EndIf;
EndProcedure

&AtClient
Procedure TimestampServersDiagnostics(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureInternalClient = CommonClient.CommonModule("DigitalSignatureInternalClient");
	ModuleDigitalSignatureInternalClient.TimestampServersDiagnostics();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibilityWaitHandler()
	
	SetVisibilityAtClient("");
	
EndProcedure

&AtClient
Procedure TimestampServersAddressesStartChoiceContinued()
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		TimestampServerAddressesSetDefault();
	EndIf;
	
EndProcedure

&AtClient
Procedure InfobasePublicationURLStartChoiceContinued()
	
	InfobasePublicationURLStartChoiceCompletion("InfobasePublicationURL");
	
EndProcedure

&AtClient
Procedure LocalInfobasePublishingURLStartChoiceContinued()
	
	InfobasePublicationURLStartChoiceCompletion("LocalInfobasePublishingURL");
	
EndProcedure

&AtClient
Procedure InfobasePublicationURLStartChoiceCompletion(Var_AttributeName)
	
	If CommonClient.ClientConnectedOverWebServer() Then
		InfobasePublicationURLStartChoiceAtServer(Var_AttributeName, InfoBaseConnectionString());
		Attachable_OnChangeAttribute(Items[Var_AttributeName]);
	Else
		ShowMessageBox(, NStr("vi = 'Không thể tự động điền trường, bởi vì chưa kết nối ứng dụng Client qua Web-server.';
								|ru = 'Не удалось автоматически заполнить поле, т.к. клиентское приложение не подключено через веб-сервер.';
								|en = 'Cannot populate the field. The client application is not connected over the web server.'; fa = 'Cannot populate the field. The client application is not connected over the web server.';
								|it = 'Impossibile compilare automaticamente il campo, perché applicazione client non è connessa tramite web server.';
								|pl = 'Nie można automatycznie wypełnić pola, ponieważ aplikacja kliencka nie jest podłączona przez serwer internetowy.';
								|tr = 'İstemci uygulaması Web sunucusu üzerinden bağlı olmadığından alan otomatik olarak doldurulamadı.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure InfobasePublicationURLStartChoiceAtServer(Var_AttributeName, ConnectionString)
	
	ConnectionParameters = StringFunctionsClientServer.ParametersFromString(ConnectionString);
	If ConnectionParameters.Property("WS") Then
		ConstantsSet[Var_AttributeName] = ConnectionParameters.WS;
	EndIf;
	
EndProcedure

&AtServer
Function TimestampServerAddressesSetDefault()
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
		ConstantTimestampServersAddresses = ModuleDigitalSignatureInternal.TimestampServerAddressesByDefault();
		OnChangeAttributeServer("TimestampServersAddresses");
	EndIf;
	
	Return "";
	
EndFunction

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	SetVisibilityAtClient(ConstantName);
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingNavigationLinkOpeningSettingsES(Item, FormattedStringURL, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If FormattedStringURL = "Programs" Then
		ModuleDigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Programs");
	ElsIf FormattedStringURL = "CheckCryptographyAppsInstallation" Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ShouldInstallExtension", True);
		CheckParameters.Insert("SetComponent", True);
		CheckParameters.Insert("ShouldPromptToInstallApp", True);
		ModuleDigitalSignatureClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
			New CallbackDescription("AfterCryptographyAppsChecked", ThisObject));
		
	Else
		ModuleDigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Certificates");
	EndIf;
	
EndProcedure

&AtClient
Function AddressOfArticleAboutDSSService()
	
	Return "https://its.1c.ru/bmk/bsp_dss_reqs";
	
EndFunction

&AtClient
Procedure CheckIfDSSUsageEnabled(SelectionResult, CycleParameters) Export

	If SelectionResult.Completed2 And SelectionResult.Result = "OK" Then
		Attachable_OnChangeAttribute(CycleParameters.Item);
	Else
		ConstantsSet.UseDSSService = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServerCall

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	// Saving values of attributes not directly related to constants (in ratio one to one).
	
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	ConstantTerm = "Constant";
	NameParts      = StrSplit(DataPathAttribute, ".");
	
	If NameParts.Count() = 2 Then
		ConstantName = NameParts[1];
		ConstantValue = ConstantsSet[ConstantName];
	ElsIf NameParts.Count() = 1
			And StrCompare(Left(DataPathAttribute, StrLen(ConstantTerm)), ConstantTerm) = 0 Then
				ConstantName = Mid(DataPathAttribute, StrLen(ConstantTerm) + 1);
				ConstantValue = ThisObject[DataPathAttribute];
	Else
		Return "";
	EndIf;
	
	If Constants[ConstantName].Get() <> ConstantValue Then
		Constants[ConstantName].Set(ConstantValue);
	EndIf;
	
	If ConstantName = "UseAdditionalAttributesAndInfo" And ConstantValue = False Then
		Read();
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseAdditionalAttributesAndInfo" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.Properties") Then
		Items.AdditionalDataGroup.Enabled =
			ConstantsSet.UseAdditionalAttributesAndInfo;
		Items.GroupPropertiesRight.Enabled =
			ConstantsSet.UseAdditionalAttributesAndInfo;
	EndIf;
	
	If (DataPathAttribute = "StoreChangeHistory" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Items.ConfigureChangesHistoryStorage.Enabled = StoreChangeHistory;
	EndIf;
	
	If (DataPathAttribute = "UseFullTextSearch" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		
		Items.ConfigureFullTextSearch.Enabled = UseFullTextSearch;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
		ModuleDigitalSignatureInternal.ConfigureCommonSettingsForm(ThisObject, DataPathAttribute);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If DataPathAttribute = "" Then
		ProxySettingAvailabilityAtServer = Not UseSecurityProfiles;
		
		CommonClientServer.SetFormItemProperty(
			Items, "OpenProxyServerParametersGroup",
			"Enabled", ProxySettingAvailabilityAtServer);
		CommonClientServer.SetFormItemProperty(
			Items, "ConfigureProxyServerAtServerGroupUnavailableWhenUsingSecurityProfiles",
			"Visible", Not ProxySettingAvailabilityAtServer);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityAtClient(ConstantName)
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		If ConstantName = "UseDigitalSignature"
			Or ConstantName = "UseEncryption"
			Or ConstantName = "GenerateDigitalSignaturesAtServer"
			Or ConstantName = "VerifyDigitalSignaturesOnTheServer"
			Or ConstantName = "" Then
				
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			
			If Not ModuleDigitalSignatureClient.GenerateDigitalSignaturesAtServer()
				And Not ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
				And (ModuleDigitalSignatureClient.UseDigitalSignature()
					Or ModuleDigitalSignatureClient.UseEncryption()) Then
				
				CheckParameters = New Structure;
				CheckParameters.Insert("ShouldInstallExtension", False);
				CheckParameters.Insert("SetComponent", False);
				CheckParameters.Insert("ShouldPromptToInstallApp", False);
				
				ModuleDigitalSignatureClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
					New CallbackDescription("AfterCryptographyAppsChecked", ThisObject));
			Else
				Items.GroupCryptoProvidersHint.Visible = False;
			EndIf;
		EndIf;
		SetAvailability(ConstantName);
	Else
		Items.GroupCryptoProvidersHint.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCryptographyAppsChecked(Result, AdditionalParameters) Export
	
	If Result.Programs.Count() = 0 And Result.ServerApplications.Count() = 0 Then
		Items.GroupCryptoProvidersHint.Visible = True;
	Else
		Items.GroupCryptoProvidersHint.Visible = False;
	EndIf;
	 
EndProcedure

&AtServer
Procedure SettingsSectionPerformance()
	
	MultithreadedOperationsAvailable = Not (Common.FileInfobase() Or Common.DataSeparationEnabled());
	
	Items.GroupPerformance.Visible = MultithreadedOperationsAvailable;
	Items.TemporaryServerClusterDirectoriesGroup.Visible = MultithreadedOperationsAvailable;
	
	If MultithreadedOperationsAvailable Then
		If ConstantsSet.LongRunningOperationsThreadCount < 1 Or ConstantsSet.LongRunningOperationsThreadCount > 99 Then
			ConstantsSet.LongRunningOperationsThreadCount = 4;
		EndIf;
	EndIf;
	
EndProcedure


// Time zone

&AtServer
Procedure FillInTimeZones()

	For Each DescriptionOfTheTimeZone In GetAvailableTimeZones() Do
	
		OffsetByDate = Date(1, 1, 1) + StandardTimeOffset(DescriptionOfTheTimeZone); 
		OffsetPresentation = StringFunctionsClientServer.SubstituteParametersToString("(UTC+%1)",
			Format(OffsetByDate, "DF=HH:mm; DE=00:00;"));

		TimeZonePresentation = OffsetPresentation + " " + DescriptionOfTheTimeZone;
		Items.AppTimeZone.ChoiceList.Add(DescriptionOfTheTimeZone, TimeZonePresentation);
			
	EndDo;
	
EndProcedure

&AtServer
Procedure AppTimeZoneOnChangeAtServer()
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If AppTimeZone <> GetInfoBaseTimeZone() Then
			SetPrivilegedMode(True);
			Try
				SetExclusiveMode(True);
				SetInfoBaseTimeZone(AppTimeZone);
				SetExclusiveMode(False);
			Except
				SetExclusiveMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(False);
			SetSessionTimeZone(AppTimeZone);
		EndIf;
		
	Else
		SetSessionTimeZone(AppTimeZone);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_ConstantRefineSignaturesDates" Then
		RefineSignaturesDatesOnChange(Items.RefineSignaturesDates);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
