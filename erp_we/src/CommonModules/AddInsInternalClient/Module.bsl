///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure CheckTheLocationOfTheComponent(Id, Location) Export
	
	If StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternalClient = CommonClient.CommonModule("AddInsSaaSInternalClient");
		If ModuleAddInsSaaSInternalClient.IsComponentFromStorage(Location) Then
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trong ứng dụng Client
		           |do nguyên nhân:
		           |đã chỉ ra sai vị trí cấu phần ngoài
		           |%2';
		           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" в клиентском приложении
		           |по причине:
		           |указано некорректное местоположение внешней компоненты
		           |%2';
		           |en = 'Cannot attach the %1 add-in in the client application
		           |due to:
		           |Add-in
		           |%2 location is incorrect'; fa = 'Cannot attach the %1 add-in in the client application
		           |due to:
		           |Add-in
		           |%2 location is incorrect';
		           |it = 'Impossibile connettere la componente esterna ""%1"" nell''app client
		           |a causa di:
		           |è indicata una posizione errata della componente esterna
		           |%2';
		           |pl = 'Nie udało się podłączyć komponentu zewnętrznego ""%1"" w aplikacji klienckiej
		           |z powodu:
		           |podano niepoprawną lokację komponentu zewnętrznego
		           |%2';
		           |tr = 'Harici bileşen ""%1"" istemci uygulamasında
		           |şu sebeple bağlanamadı:
		           |harici bileşenin 
		           |%2konumu yanlış belirtildi'"),
		Id, Location);

EndProcedure

// Parameters:
//  Notification - CallbackDescription
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckAddInAvailability(Notification, Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	If Not ValueIsFilled(Context.Version) Then
		Context.Version = Information.Attributes.Version;
	EndIf;
	Context.Location = Information.Location;
	
	// Information.State:
	// * IsNotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("vi = 'Đã ngắt bởi người quản trị.';
										|ru = 'Отключена администратором.';
										|en = 'Disabled by administrator.'; fa = 'Disabled by administrator.';
										|it = 'Disattivato dall''amministratore.';
										|pl = 'Odłączona przez administratora.';
										|tr = 'Yönetici tarafından devre dışı bırakıldı.'");
		RunCallback(Notification, Result);
		
	ElsIf Information.State = "NotFound1" Then 
		
		If Information.CanImportFromPortal 
			And Context.SuggestToImport Then 
			
			SearchContext = New Structure;
			SearchContext.Insert("Notification", Notification);
			SearchContext.Insert("Context", Context);
			
			NotificationForms = New CallbackDescription(
				"CheckAddInAvailabilityAfterSearchingAddInOnPortal",
				ThisObject, 
				SearchContext);
				
			Notification = New CallbackDescription("AddInSearchOnPortalOnGenerateResult", ThisObject, NotificationForms);
			AddInsClientLocalization.OnSearchAddInsOnPortal(Notification, Context);
			
		Else 
			Result.ErrorDescription = NStr("vi = 'Thành phần này không có trong danh sách các thành phần bên ngoài được phép.';
											|ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
											|en = 'The add-in is missing from the list of allowed add-ins.'; fa = 'The add-in is missing from the list of allowed add-ins.';
											|it = 'Il componente non è nell''elenco di componenti esterni consentiti.';
											|pl = 'Brak komponentu na liście dozwolonych komponentów zewnętrznych.';
											|tr = 'Bileşen izin verilen harici bileşen listesinde bulunmuyor.'");
			RunCallback(Notification, Result);
		EndIf;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			RunCallback(Notification, Result);
			
		Else 
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Notification", Notification);
			NotificationParameters.Insert("Result", Result);
			
			NotificationForms = New CallbackDescription(
				"CheckAddInAvailabilityAfterDisplayingAvailableClientTypes",
				ThisObject,
				NotificationParameters);
				
			If Not Context.SuggestInstall Then
				RunCallback(NotificationForms, False);
				Return;
			EndIf;
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", Context.ExplanationText);
			FormParameters.Insert("SupportedClients", Information.Attributes.TargetPlatforms);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, NotificationForms);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AddInAvailabilityCheckResult(Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	
	Context.Location = Information.Location;
	Context.Version = Information.Attributes.Version;
	
	// Information.State:
	// * IsNotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("vi = 'Đã ngắt bởi người quản trị.';
										|ru = 'Отключена администратором.';
										|en = 'Disabled by the administrator.'; fa = 'Disabled by the administrator.';
										|it = 'Disattivato dall''amministratore.';
										|pl = 'Odłączona przez administratora.';
										|tr = 'Yönetici tarafından devre dışı bırakıldı.'");
		Return Result;
		
	ElsIf Information.State = "NotFound1" Then 
		
		Result.ErrorDescription = NStr("vi = 'Cấu phần không có trong danh sách cấu phần ngoài được phép.';
										|ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
										|en = 'The add-in is missing from the list of allowed add-ins.'; fa = 'The add-in is missing from the list of allowed add-ins.';
										|it = 'Il componente non è nell''elenco di componenti esterni consentiti.';
										|pl = 'Brak komponentu na liście dozwolonych komponentów zewnętrznych.';
										|tr = 'Bileşen izin verilen harici bileşen listesinde bulunmuyor.'");
		
		Return Result;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
			
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			Return Result;
		
		Else
			
			ErrorDescription = StringFunctionsClient.FormattedString(
				NStr("vi = 'Không xem xét công việc của cấu phần ngoài 
					 |trong ứng dụng client<b>%1</b>.
					 |Hãy liên hệ với nhà phát triển cấu phần ngoài.';
					 |ru = 'Не предусмотрена работа внешней компоненты 
					 |в клиентском приложении <b>%1</b>.
					 |Обратитесь к разработчику внешней компоненты.';
					 |en = 'Client application <b>%1</b>
					 |does not support the add-in.
					 |Contact the add-in developer.'; fa = 'Client application <b>%1</b>
					 |does not support the add-in.
					 |Contact the add-in developer.';
					 |it = 'Не предусмотрена работа внешней компоненты 
					 |в клиентском приложении <b>%1</b>.
					 |Обратитесь к разработчику внешней компоненты.';
					 |pl = 'Client application <b>%1</b>
					 |does not support the add-in.
					 |Contact the add-in developer.';
					 |tr = '<b>%1</b> istemci uygulamasında harici bileşenin çalışması 
					 |mümkün değildir.
					 |Harici bileşen geliştiricisiyle iletişime geçin.'"), PresentationOfCurrentClient());

			If Not Context.SuggestInstall Then
				Result.Available = False;
				Result.ErrorDescription = ErrorDescription;
			Else
				QuestionButtons = New ValueList;
				QuestionButtons.Add("Close", NStr("vi = 'Đóng';
													|ru = 'Закрыть';
													|en = 'Close'; fa = 'بستن';
													|it = 'Закрыть';
													|pl = 'Close';
													|tr = 'Kapat'"));
				QuestionButtons.Add("ResumeInstallationAttempt", NStr("vi = 'Tiếp tục thử cài đặt';
																		|ru = 'Продолжить попытку установки';
																		|en = 'Install anyway'; fa = 'نصب به هر حال';
																		|it = 'Продолжить попытку установки';
																		|pl = 'Install anyway';
																		|tr = 'Kurulumu denemeye devam et'"));

				QuestionTitle = Context.ExplanationText;
				If IsBlankString(QuestionTitle) Then
					QuestionTitle = NStr("vi = 'Không thể cài đặt cấu phần ngoài.';
										|ru = 'Установка внешней компоненты невозможна.';
										|en = 'Cannot install the add-in.'; fa = 'Cannot install the add-in.';
										|it = 'Impossibile installare il componente esterno.';
										|pl = 'Instalacja zewnętrznej komponenty nie jest możliwa.';
										|tr = 'Harici bileşen ayarlanamaz.'");
				EndIf;

				Response = Await DoQueryBoxAsync(ErrorDescription, QuestionButtons,, "Close", QuestionTitle);

				If Response = "ResumeInstallationAttempt" Then
					Result.Available = True;
				Else
					Result.Available = False;
					Result.ErrorDescription = ErrorDescription;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> "StandardSubsystems.AddIns" Then
		Return;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.SymbolicNames",
		New FixedMap(New Map));
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.Objects",
		New FixedMap(New Map));
	
EndProcedure

// Compatibility error with add-in from template.
// 
// Parameters:
//  Location - String - Template that contains the add-in.
// 
// Returns:
//  String - Compatibility error with add-in from template
//
Function TemplateAddInCompatibilityError(Location) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(Location);
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
			Return AddInCompatibilityErrorDetails();
	EndIf;
	
	Return "";
	
EndFunction

// Check if the add-in from template is compatible.
// 
// Parameters:
//  Notification - CallbackDescription - Notify on the compatibility check and show a warning.
//  AddInAttachmentContext - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckTemplateAddInForCompatibility(Notification, AddInAttachmentContext) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(
		AddInAttachmentContext.Location);
		
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorDescription", "");
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
		
		Context.ErrorDescription = AddInCompatibilityErrorDetails();
		
		If AddInAttachmentContext.SuggestInstall Then
			CallbackDescription = New CallbackDescription("AfterCompatibilityInfoDisplayed", ThisObject, Context);
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", AddInAttachmentContext.ExplanationText);
			FormParameters.Insert("SupportedClients", AddInInfo.Attributes.TargetPlatforms);
			FormParameters.Insert("AfterConnectionErrorOccurred", True);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, CallbackDescription);
			Return;
		EndIf;
	EndIf;
	
	AfterCompatibilityInfoDisplayed(Undefined, Context);
	
EndProcedure

#EndRegion

#Region Private

#Region CheckAddInAvailability

Procedure AfterCompatibilityInfoDisplayed(Result, Context) Export
	
	RunCallback(Context.Notification, Context.ErrorDescription);
	
EndProcedure

Function AddInCompatibilityErrorDetails()
	Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không xem xét công việc của cấu phần ngoài trong ứng dụng client %1.Hãy liên hệ với nhà phát triển cấu phần ngoài';
				|ru = 'Не предусмотрена работа внешней компоненты в клиентском приложении %1. Обратитесь к разработчику внешней компоненты';
				|en = 'Client application %1 does not support the add-in. Contact the add-in developer.'; fa = 'Client application %1 does not support the add-in. Contact the add-in developer.';
				|it = 'Не предусмотрена работа внешней компоненты в клиентском приложении %1. Обратитесь к разработчику внешней компоненты';
				|pl = 'Client application %1 does not support the add-in. Contact the add-in developer.';
				|tr = '%1 istemci uygulamasında harici bileşenin çalışması mümkün değildir. Harici bileşen geliştiricisiyle iletişime geçin.'"),
			CommonInternalClient.ApplicationKind());
EndFunction

Procedure CheckAddInAvailabilityAfterSearchingAddInOnPortal(Imported1, SearchContext) Export
	
	Notification = SearchContext.Notification;
	Context   = SearchContext.Context;
	
	If Imported1 Then
		Context.SuggestToImport = False;
		CheckAddInAvailability(Notification, Context);
	Else 
		RunCallback(Notification, AddInAvailabilityResult());
	EndIf;
	
EndProcedure

Procedure CheckAddInAvailabilityAfterDisplayingAvailableClientTypes(Result, Context) Export
	
	AddInAvailabilityResult = Context.Result;
	AddInAvailabilityResult.Available = Result = True;
	RunCallback(Context.Notification, AddInAvailabilityResult);
	
EndProcedure

// Returns:
//  Structure:
//   * Available - Boolean
//   * Version - String
//   * TheComponentOfTheLatestVersion - See StandardSubsystemsServer.TheComponentOfTheLatestVersion
//   * ErrorDescription - String
//   * Location - String
//
Function AddInAvailabilityResult() Export
	
	Result = New Structure;
	Result.Insert("Available", False);
	Result.Insert("Version", "");
	Result.Insert("TheComponentOfTheLatestVersion", Undefined);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Location", "");
	
	Return Result;
	
EndFunction

Procedure ReplaceWithCurrentComponentFromCatalog(Result, Id, Location, ShouldAttachAddInFromTemplate)
	
	If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(Result.Version, ".", "")) Then
		VersionParts = StrSplit(Result.Version, ".");
		If VersionParts.Count() = 4 And CommonClientServer.CompareVersions(Result.Version,
			Result.TheComponentOfTheLatestVersion.Version) <= 0 Then
				ShouldAttachAddInFromTemplate = True;
			Return;
		EndIf;
	EndIf;
		
	// Use the add-in from the catalog if the add-in version is greater than the template version or it mismatches the template.
	Result.TheComponentOfTheLatestVersion = New Structure("Id, Version, Location", Id,
		Result.Version, Location);
		
EndProcedure

// The add-in supports the client.
// 
// Parameters:
//  Attributes - See AddInsInternal.
// 
// Returns:
//  Boolean - Flag indicating whether the add-in supports the client.
//
Function CurrentClientIsSupportedByAddIn(Attributes)
	
	SystemInfo = New SystemInfo;
	Browser = Undefined;
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = "YandexBrowser";
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = "Chrome";
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = "MSIE";
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = "Safari";
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = "Firefox";
	EndIf;
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	
	If NameOfThePlatformType = "Linux_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.MacOS_x86_64;
		EndIf;
		
		If Browser = "Safari" Then
			Return Attributes.MacOS_x86_64_Safari;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Windows_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_64_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		// Browsers may misdefine the OS.
	
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_E2K;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_E2K_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_E2K_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_E2K_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
	
		If Browser = Undefined Then
			Return Attributes.Linux_ARM64;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_ARM64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_ARM64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_ARM64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
	
		Return Attributes.iOS_ARM;
	
	ElsIf NameOfThePlatformType = "iOS_ARM64" Then
	
		Return Attributes.iOS_ARM64;
	
	ElsIf NameOfThePlatformType = "Android_ARM" Then
	
		Return Attributes.Android_ARM;
	
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
	
		Return Attributes.Android_ARM64;
		
	ElsIf NameOfThePlatformType = "Android_x86" Then
	
		Return Attributes.Android_x86;
		
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
	
		Return Attributes.Android_x86_64;
		
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
	
		Return Attributes.WindowsRT_ARM;
		
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
	
		Return Attributes.WindowsRT_x86;
		
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
	
		Return Attributes.WindowsRT_x86_64;
	
	EndIf;
	
	Return False;
	
EndFunction

Function TextCannotInstallAddIn(Val ExplanationText) Export

	If IsBlankString(ExplanationText) Then
		ExplanationText = NStr("vi = 'Không thể cài đặt cấu phần ngoài.';
								|ru = 'Установка внешней компоненты невозможна.';
								|en = 'Cannot install the add-in.'; fa = 'Cannot install the add-in.';
								|it = 'Impossibile installare il componente esterno.';
								|pl = 'Instalacja zewnętrznej komponenty nie jest możliwa.';
								|tr = 'Harici bileşen ayarlanamaz.'");
	EndIf;

	Return StringFunctionsClient.FormattedString(NStr("vi = '%1
			  |
			  |Không hỗ trợ hoạt động của cấu phần ngoài 
			  |trong ứng dụng client <b>%2</b>.
			  |Hãy sử dụng <a href = about:blank>ứng dụng client được hỗ trợ</a> hoặc liên hệ với nhà phát triển cấu phần ngoài.';
			  |ru = '%1
			  |
			  |Не предусмотрена работа внешней компоненты 
			  |в клиентском приложении <b>%2</b>.
			  |Используйте <a href = about:blank>поддерживаемое клиентское приложение</a> или обратитесь к разработчику внешней компоненты.';
			  |en = '%1
			  |
			  |The add-in is not supported 
			  |in the client application <b>%2</b>.
			  |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.'; fa = '%1
			  |
			  |The add-in is not supported 
			  |in the client application <b>%2</b>.
			  |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';
			  |it = '%1
			  |
			  |Не предусмотрена работа внешней компоненты 
			  |в клиентском приложении <b>%2</b>.
			  |Используйте <a href = about:blank>поддерживаемое клиентское приложение</a> или обратитесь к разработчику внешней компоненты.';
			  |pl = '%1
			  |
			  |The add-in is not supported 
			  |in the client application <b>%2</b>.
			  |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';
			  |tr = '%1
			  |
			  |Dış bileşenin
			  | <b>%2</b>istemci uygulamasında çalışması ön görülmemiştir.
			  |Lütfen <a href = about:blank>destekli istemci </a>uygulamasını kullanın ya da dış bileşenin geliştiricisine başvurun.'"),
		ExplanationText, PresentationOfCurrentClient());
		
EndFunction

Function PresentationOfCurrentClient() 
	
	SystemInfo = New SystemInfo;
	
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = NStr("vi = 'Trình duyệt Yandex';
						|ru = 'Яндекс Браузер';
						|en = 'Yandex Browser'; fa = 'Yandex Browser';
						|it = 'Яндекс Браузер';
						|pl = 'Yandex Browser';
						|tr = 'Yandex Browser'");
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = NStr("vi = 'Chrome';
						|ru = 'Chrome';
						|en = 'Chrome'; fa = 'Chrome';
						|it = 'Chrome';
						|pl = 'Chrome';
						|tr = 'Chrome'");
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = NStr("vi = 'Internet Explorer';
						|ru = 'Internet Explorer';
						|en = 'Internet Explorer'; fa = 'Internet Explorer';
						|it = 'Internet Explorer';
						|pl = 'Internet Explorer';
						|tr = 'Internet Explorer'");
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = NStr("vi = 'Safari';
						|ru = 'Safari';
						|en = 'Safari'; fa = 'Safari';
						|it = 'Safari';
						|pl = 'Safari';
						|tr = 'Safari'");
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = NStr("vi = 'Firefox';
						|ru = 'Firefox';
						|en = 'Firefox'; fa = 'Firefox';
						|it = 'Firefox';
						|pl = 'Firefox';
						|tr = 'Firefox'");
	EndIf;
	
	Application = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'web-client %1';
																				|ru = 'веб-клиент %1';
																				|en = 'web client %1'; fa = 'web client %1';
																				|it = 'web-client %1';
																				|pl = 'klient sieci web %1';
																				|tr = '%1 web istemcisi'"), Browser);
#ElsIf MobileAppClient Then
	Application = NStr("vi = 'ứng dụng di động';
						|ru = 'мобильное приложение';
						|en = 'mobile application'; fa = 'mobile application';
						|it = 'applicazione mobile';
						|pl = 'aplikacja mobilna';
						|tr = 'mobil uygulama'");
#ElsIf MobileClient Then
	Application = NStr("vi = 'mobile client';
						|ru = 'мобильный клиент';
						|en = 'mobile client'; fa = 'mobile client';
						|it = 'client mobile';
						|pl = 'mobilny klient';
						|tr = 'mobil istemci'");
#ElsIf ThinClient Then
	Application = NStr("vi = 'thin client';
						|ru = 'тонкий клиент';
						|en = 'thin client'; fa = 'thin client';
						|it = 'thin client';
						|pl = 'cienki klient';
						|tr = 'ince istemci'");
#ElsIf ThickClientOrdinaryApplication Then
	Application = NStr("vi = 'thick client (ứng dụng thường)';
						|ru = 'толстый клиент (обычное приложение)';
						|en = 'thick client (standard application)'; fa = 'thick client (standard application)';
						|it = 'thick client (applicazione normale)';
						|pl = 'gruby klient (zwykła aplikacja)';
						|tr = 'donatımlı istemci (standart uygulama)'");
#ElsIf ThickClientManagedApplication Then
	Application = NStr("vi = 'thick client';
						|ru = 'толстый клиент';
						|en = 'thick client'; fa = 'thick client';
						|it = 'thick client';
						|pl = 'gruby klient';
						|tr = 'donatımlı istemci'");
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	If NameOfThePlatformType = "Windows_x86" Then
		Platform = NStr("vi = 'Windows x86';
						|ru = 'Windows x86';
						|en = 'Windows x86'; fa = 'Windows x86';
						|it = 'Windows x86';
						|pl = 'Windows x86';
						|tr = 'Windows x86'");
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		Platform = NStr("vi = 'Windows x86-64';
						|ru = 'Windows x86-64';
						|en = 'Windows x86-64'; fa = 'Windows x86-64';
						|it = 'Windows x86-64';
						|pl = 'Windows x86-64';
						|tr = 'Windows x86-64'");
	ElsIf NameOfThePlatformType = "Linux_x86" Then
		Platform = NStr("vi = 'Linux x86';
						|ru = 'Linux x86';
						|en = 'Linux x86'; fa = 'Linux x86';
						|it = 'Linux x86';
						|pl = 'Linux x86';
						|tr = 'Linux x86'");
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		Platform = NStr("vi = 'Linux x86-64';
						|ru = 'Linux x86-64';
						|en = 'Linux x86-64'; fa = 'Linux x86-64';
						|it = 'Linux x86-64';
						|pl = 'Linux x86-64';
						|tr = 'Linux x86-64'");
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		Platform = NStr("vi = 'macOS x86';
						|ru = 'macOS x86';
						|en = 'macOS x86'; fa = 'macOS x86';
						|it = 'macOS x86';
						|pl = 'macOS x86';
						|tr = 'macOS x86'");
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		Platform = NStr("vi = 'macOS x86-64';
						|ru = 'macOS x86-64';
						|en = 'macOS x86-64'; fa = 'macOS x86-64';
						|it = 'macOS x86-64';
						|pl = 'macOS x86-64';
						|tr = 'macOS x86-64'");
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
		Platform = NStr("vi = 'Linux ARM64';
						|ru = 'Linux ARM64';
						|en = 'Linux ARM64'; fa = 'Linux ARM64';
						|it = 'Linux ARM64';
						|pl = 'Linux ARM64';
						|tr = 'Linux ARM64'");
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		Platform = NStr("vi = 'Linux E2K';
						|ru = 'Linux E2K';
						|en = 'Linux E2K'; fa = 'Linux E2K';
						|it = 'Linux E2K';
						|pl = 'Linux E2K';
						|tr = 'Linux E2K'");
	ElsIf NameOfThePlatformType = "Android_ARM" Then
		Platform = NStr("vi = 'Android ARM';
						|ru = 'Android ARM';
						|en = 'Android ARM'; fa = 'Android ARM';
						|it = 'Android ARM';
						|pl = 'Android ARM';
						|tr = 'Android ARM'");
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
		Platform = NStr("vi = 'Android_ARM64';
						|ru = 'Android_ARM64';
						|en = 'Android_ARM64'; fa = 'Android_ARM64';
						|it = 'Android_ARM64';
						|pl = 'Android_ARM64';
						|tr = 'Android_ARM64'");
	ElsIf NameOfThePlatformType = "Android_x86" Then
		Platform = NStr("vi = 'Android x86';
						|ru = 'Android x86';
						|en = 'Android x86'; fa = 'Android x86';
						|it = 'Android x86';
						|pl = 'Android x86';
						|tr = 'Android x86'");
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
		Platform = NStr("vi = 'Android x86-64';
						|ru = 'Android x86-64';
						|en = 'Android x86-64'; fa = 'Android x86-64';
						|it = 'Android x86-64';
						|pl = 'Android x86-64';
						|tr = 'Android x86-64'");
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
		Platform = NStr("vi = 'iOS ARM';
						|ru = 'iOS ARM';
						|en = 'iOS ARM'; fa = 'iOS ARM';
						|it = 'iOS ARM';
						|pl = 'iOS ARM';
						|tr = 'iOS ARM'");
	ElsIf NameOfThePlatformType = "iOS_ARM_64" Then
		Platform = NStr("vi = 'iOS ARM64';
						|ru = 'iOS ARM64';
						|en = 'iOS ARM64'; fa = 'iOS ARM64';
						|it = 'iOS ARM64';
						|pl = 'iOS ARM64';
						|tr = 'iOS ARM64'");
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
		Platform = NStr("vi = 'WinRT ARM';
						|ru = 'WinRT ARM';
						|en = 'WinRT ARM'; fa = 'WinRT ARM';
						|it = 'WinRT ARM';
						|pl = 'WinRT ARM';
						|tr = 'WinRT ARM'");
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
		Platform = NStr("vi = 'WinRT x86';
						|ru = 'WinRT x86';
						|en = 'WinRT x86'; fa = 'WinRT x86';
						|it = 'WinRT x86';
						|pl = 'WinRT x86';
						|tr = 'WinRT x86'");
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
		Platform = NStr("vi = 'WinRT x86-64';
						|ru = 'WinRT x86-64';
						|en = 'WinRT x86-64'; fa = 'WinRT x86-64';
						|it = 'WinRT x86-64';
						|pl = 'WinRT x86-64';
						|tr = 'WinRT x86-64'");
	EndIf;
	
	// Example:
	// Firefox Windows x86 web client
	// Windows x86-64 thin client
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 %2';
																		|ru = '%1 %2';
																		|en = '%1 %2'; fa = '%1 %2';
																		|it = '%1 %2';
																		|pl = '%1 %2';
																		|tr = '%1 %2'"), Application, Platform);
	
EndFunction

#EndRegion

#Region AttachAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AttachAddInSSLAsync(Context) Export 
	
	Result = Await AddInAvailabilityCheckResult(Context);
	
	If Result.Available Then 
		Return Await CommonInternalClient.AttachAddInSSLAsync(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
				           |từ kho chứa cấu phần ngoài
				           |do nguyên nhân:
				           |%2';
				           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2';
				           |en = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2'; fa = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';
				           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
				           | dall''archivio dei componenti esterni 
				           |a causa di: 
				           |%2';
				           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
				           |z pamięci zewnętrznych komponentów 
				           |z powodu: 
				           |%2';
				           |tr = '
				           |istemcide 
				           |harici bileşen deposundan harici bileşen ""%1"" şu sebeple bağlanamadı:
				           |%2'"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

Procedure AttachAddInSSL(Context) Export 
	
	Notification = New CallbackDescription(
		"AttachAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - add-in attachment result:
//    * Attached - Boolean - attachment flag.
//    * Attachable_Module - AddInObject - an instance of the add-in.
//    * ErrorDescription - String - brief error message. Empty string on cancel by user
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.AttachAddInSSL(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không kết nối được thành phần bên ngoài ""%1"" trên khách hàng
				           |từ kho chứa cấu phần bên ngoài
				           |vì lý do:
				           |%2';
				           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2';
				           |en = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2'; fa = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';
				           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
				           | dall''archivio dei componenti esterni 
				           |a causa di: 
				           |%2';
				           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
				           |z pamięci zewnętrznych komponentów 
				           |z powodu: 
				           |%2';
				           |tr = '
				           |istemcide 
				           |harici bileşen deposundan harici bileşen ""%1"" şu sebeple bağlanamadı:
				           |%2'"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachAddInFromWindowsRegistry

// Returns:
//  Structure:
//   * Notification - CallbackDescription
//   * Id - String
//   * ObjectCreationID - String
//
Function ConnectionContextComponentsFromTheWindowsRegistry() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("ObjectCreationID", "");
	Return Context;
		
EndFunction

// Intended to be called from AddInClient.AttachAddInFromWindowsRegisterAsync.
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Async Function AttachAddInFromWindowsRegistryAsync(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Try
			
			Attached = Await AttachAddInAsync("AddIn." + Context.Id);
			
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể kết nối thành phần ngoài ""%1"" trên client
					 |từ Registry Windows
					 |do nguyên nhân:
					 |%2';
					 |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
					 |из реестра Windows
					 |по причине:
					 |%2';
					 |en = 'Cannot attach the ""%1"" add-in on the client
					 |from Windows registry.
					 |Reason:
					 |%2'; fa = 'Cannot attach the ""%1"" add-in on the client
					 |from Windows registry.
					 |Reason:
					 |%2';
					 |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
					 | dal registro Windows 
					 | a causa di: 
					 |%2';
					 |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
					 |z rejestru Windows 
					 |z powodu: 
					 |%2';
					 |tr = 'Windows
					 | konumlayıcısından 
					 |istemcide ""%1"" harici bileşenin nesnesi bağlanamadı, nedeni:
					 |%2'"), Context.Id, ErrorProcessing.BriefErrorDescription(ErrorInfo()));

			Return CommonInternalClient.AddInAttachmentError(ErrorText);
		EndTry;
		
		If Attached Then

			ObjectCreationID = Context.ObjectCreationID;

			If ObjectCreationID = Undefined Then
				ObjectCreationID = Context.Id;
			EndIf;

			Try
				Attachable_Module = New ("AddIn." + ObjectCreationID);
				If Attachable_Module = Undefined Then
					Raise NStr("vi = 'Toán tử Mới trả lại Không xác định';
								|ru = 'Оператор Новый вернул Неопределено';
								|en = 'The New operator returned Undefined.'; fa = 'The New operator returned Undefined.';
								|it = 'L''operatore Nuovo ha ritornato Indefinito';
								|pl = 'Operator Nowy zwrócił Nieokreślono';
								|tr = 'Operatör Yeni iade etti Belirsiz'");
				EndIf;
			Except
				Attachable_Module = Undefined;
				ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;

			If Attachable_Module = Undefined Then

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tạo đối tượng cấu phần ngoài""%1"", được kết nối trên client
					 |từ Registry Windows,
					 |do nguyên nhân:
					 |%2';
					 |ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
					 |из реестра Windows,
					 |по причине:
					 |%2';
					 |en = 'Cannot create object of the ""%1"" add-in attached on the client
					 |from Windows registry.
					 |Reason:
					 |%2'; fa = 'Cannot create object of the ""%1"" add-in attached on the client
					 |from Windows registry.
					 |Reason:
					 |%2';
					 |it = 'Non è stato possibile creare l''oggetto del componente esterno ""%1"", collegato al client 
					 | dal registro Windows
					 | a causa di: 
					 |%2';
					 |pl = 'Nie udało się utworzyć obiekt zewnętrznego komponentu ""%1"", podłączonego na kliencie 
					 |z rejesru Windows,
					 |z powodu:
					 |%2';
					 |tr = 'Windows konumlayıcısından 
					 |istemcide bağlanan ""%1"" harici bileşenin nesnesi oluşturulamadı, 
					 | nedeni: 
					 |%2'"), Context.Id, ErrorText);

				Return CommonInternalClient.AddInAttachmentError(ErrorText);

			Else
				
				Result = CommonInternalClient.AddInAttachmentResult();
				Result.Attached = True;
				Result.Attachable_Module = Attachable_Module;
				Return Result;
				
			EndIf;

		Else

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
				 |từ Windows
				 |do nguyên nhân:
				 |Phương thức %2 trả lại %3.';
				 |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				 |из реестра Windows
				 |по причине:
				 |Метод %2 вернул %3.';
				 |en = 'Couldn''t attach add-in ""%1"" on the client
				 |from Windows registry.
				 |Reason:
				 |Method ""%2"" returned ""%3"".'; fa = 'Couldn''t attach add-in ""%1"" on the client
				 |from Windows registry.
				 |Reason:
				 |Method ""%2"" returned ""%3"".';
				 |it = 'Impossibile collegare la componente esterna ""%1"" al client
				 |dal registro Windows
				 |a causa di:
				 |Metodo%2 ha restituito %3.';
				 |pl = 'Nie udało się podłączyć komponentu zewnętrznego ""%1"" na kliencie 
				 |z rejestru Windows
				 |z powodu: 
				 |Metoda %2zwróciła %3.';
				 |tr = 'Windows
				 | konumlayıcısından 
				 |istemcide ""%1"" harici bileşenin nesnesi bağlanamadı, nedeni:
				 |Yöntem%2iade etti %3.'"), Context.Id, "AttachAddInAsync", "False");

			Return CommonInternalClient.AddInAttachmentError(ErrorText);

		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối thành phần bên ngoài ""%1"" trên máy khách
			           |từ sổ đăng ký Windows
			           | vì lý do:
			           | Chỉ có thể kết nối thành phần từ sổ đăng ký Windows trong các máy khách Windows mỏng hoặc dày.';
			           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.';
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.'; fa = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';
			           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
			           | dal registro Windows
			           | a causa di: 
			           | è possibil collegare il componente al registro Windows solamente al thin o fat client di Windows.';
			           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
			           |z rejestru Windows
			           |z powodu:
			           |Podłączenie komponentu z rejestru Windows jest możliwe tylko w cienkim lub grubym klientach Windows.';
			           |tr = '
			           |istemcide 
			           |Windows kayıt defterinden harici bileşen ""%1"" şu sebeple bağlanamadı:
			           |Windows kayıt defterindeki bir bileşeni yalnızca ince veya donatımlı Windows istemcilerinde bağlayabilirsiniz.'"),
			Context.Id);
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

// For calls from See AddInsClient.AttachAddInFromWindowsRegistry.
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Procedure AttachAddInFromWindowsRegistry(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Notification = New CallbackDescription(
		"AttachAddInFromWindowsRegistryAfterAttachmentAttempt", ThisObject, Context,
		"AttachAddInFromWIndowsRegisterOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, "AddIn." + Context.Id);
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối thành phần bên ngoài ""%1"" trên máy khách
			           |từ sổ đăng ký Windows
			           | vì lý do:
			           | Chỉ có thể kết nối thành phần từ sổ đăng ký Windows trong các máy khách Windows mỏng hoặc dày.';
			           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.';
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.'; fa = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';
			           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
			           | dal registro Windows
			           | a causa di: 
			           | è possibil collegare il componente al registro Windows solamente al thin o fat client di Windows.';
			           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
			           |z rejestru Windows
			           |z powodu:
			           |Podłączenie komponentu z rejestru Windows jest możliwe tylko w cienkim lub grubym klientach Windows.';
			           |tr = '
			           |istemcide 
			           |Windows kayıt defterinden harici bileşen ""%1"" şu sebeple bağlanamadı:
			           |Windows kayıt defterindeki bir bileşeni yalnızca ince veya donatımlı Windows istemcilerinde bağlayabilirsiniz.'"),
		Context.Id);
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
//
// Parameters:
//  Attached - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWindowsRegistryAfterAttachmentAttempt(Attached, Context) Export
	
	If Attached Then 
		
		ObjectCreationID = Context.ObjectCreationID;
			
		If ObjectCreationID = Undefined Then 
			ObjectCreationID = Context.Id;
		EndIf;
		
		Try
			Attachable_Module = New("AddIn." + ObjectCreationID);
			If Attachable_Module = Undefined Then 
				Raise NStr("vi = 'Toán tử Mới trả lại Không xác định';
							|ru = 'Оператор Новый вернул Неопределено';
							|en = 'The New operator returned Undefined'; fa = 'The New operator returned Undefined';
							|it = 'L''operatore Nuovo ha ritornato Indefinito';
							|pl = 'Operator Nowy zwrócił Nieokreślono';
							|tr = 'Operatör Yeni iade etti Belirsiz'");
			EndIf;
		Except
			Attachable_Module = Undefined;
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If Attachable_Module = Undefined Then 
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tạo đối tượng cấu phần ngoài""%1"", được kết nối trên client
				           |từ Registry Windows,
				           |do nguyên nhân:
				           |%2';
				           |ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
				           |из реестра Windows,
				           |по причине:
				           |%2';
				           |en = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2'; fa = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2';
				           |it = 'Non è stato possibile creare l''oggetto del componente esterno ""%1"", collegato al client 
				           | dal registro Windows
				           | a causa di: 
				           |%2';
				           |pl = 'Nie udało się utworzyć obiekt zewnętrznego komponentu ""%1"", podłączonego na kliencie 
				           |z rejesru Windows,
				           |z powodu:
				           |%2';
				           |tr = 'Windows konumlayıcısından 
				           |istemcide bağlanan ""%1"" harici bileşenin nesnesi oluşturulamadı, 
				           | nedeni: 
				           |%2'"),
				Context.Id,
				ErrorText);
				
			CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
			
		Else 
			CommonInternalClient.AttachAddInSSLNotifyOnAttachment(Attachable_Module, Context);
		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
			           |từ Windows
			           |do nguyên nhân:
			           |Phương thức %2 trả lại %3.';
			           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Метод %2 вернул %3.';
			           |en = 'Couldn''t attach add-in ""%1"" on the client
			           |from Windows registry.
			           |Reason:
			           |Method ""%2"" returned ""%3"".'; fa = 'Couldn''t attach add-in ""%1"" on the client
			           |from Windows registry.
			           |Reason:
			           |Method ""%2"" returned ""%3"".';
			           |it = 'Impossibile collegare la componente esterna ""%1"" al client
			           |dal registro Windows
			           |a causa di:
			           |Metodo%2 ha restituito %3.';
			           |pl = 'Nie udało się podłączyć komponentu zewnętrznego ""%1"" na kliencie 
			           |z rejestru Windows
			           |z powodu: 
			           |Metoda %2zwróciła %3.';
			           |tr = 'Windows
			           | konumlayıcısından 
			           |istemcide ""%1"" harici bileşenin nesnesi bağlanamadı, nedeni:
			           |Yöntem%2iade etti %3.'"),
			Context.Id, "BeginAttachingAddIn", "False");
			
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWIndowsRegisterOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không kết nối được thành phần bên ngoài ""%1"" trên máy khách
		           |từ biểu ghi Windows
		           |vì lý do:
		           |%2';
		           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		           |из реестра Windows
		           |по причине:
		           |%2';
		           |en = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2'; fa = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2';
		           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
		           | dal registro Windows 
		           | a causa di: 
		           |%2';
		           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
		           |z rejestru Windows 
		           |z powodu: 
		           |%2';
		           |tr = 'Windows
		           | konumlayıcısından 
		           |istemcide ""%1"" harici bileşenin nesnesi bağlanamadı, nedeni:
		           |%2'"),
		Context.Id,
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
	CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
Function AttachAddInFromWindowsRegistryAttachmentAvailable()
	
#If WebClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

#EndRegion

#Region InstallAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function InstallAddInSSLAsync(Context) Export
	
	CheckResult = Await AddInAvailabilityCheckResult(Context);
	
	If CheckResult.Available Then 
		Return Await CommonInternalClient.InstallAddInSSLAsync(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
			           |từ kho chứa cấu phần ngoài
			           |do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2';
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2'; fa = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';
			           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
			           | dall''archivio dei componenti esterni 
			           |a causa di: 
			           |%2';
			           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
			           |z pamięci zewnętrznych komponentów 
			           |z powodu: 
			           |%2';
			           |tr = '
			           |istemcide 
			           |harici bileşen deposundan harici bileşen ""%1"" şu sebeple bağlanamadı:
			           |%2'"),
			Context.Id,
			CheckResult.ErrorDescription);
			
		Return CommonInternalClient.AddInInstallationError(ErrorText);
	EndIf;
	
EndFunction

Procedure InstallAddInSSL(Context) Export
	
	Notification = New CallbackDescription(
		"InstallAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - add-in attachment result:
//    * Attached - Boolean - attachment flag.
//    * Attachable_Module - AddInObject - an instance of the add-in.
//    * ErrorDescription - String - brief error message. Empty string on cancel by user.
//  Context - See CommonInternalClient.AddInAttachmentContext 
//
Procedure InstallAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.InstallAddInSSL(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không kết nối được thành phần bên ngoài ""%1"" trên khách hàng
			           |từ kho chứa cấu phần bên ngoài
			           |vì lý do:
			           |%2';
			           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2';
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2'; fa = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';
			           |it = 'Non è stato possibile collegare il componente esterno ""%1"" al client 
			           | dall''archivio dei componenti esterni 
			           |a causa di: 
			           |%2';
			           |pl = 'Nie udało się podłączyć zewnętrzny komponent ""%1"" na kliencie 
			           |z pamięci zewnętrznych komponentów 
			           |z powodu: 
			           |%2';
			           |tr = '
			           |istemcide 
			           |harici bileşen deposundan harici bileşen ""%1"" şu sebeple bağlanamadı:
			           |%2'"),
			Context.Id,
			Result.ErrorDescription);
			
		CommonInternalClient.InstallAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportAddInFromFile

// Returns:
//  Structure:
//   * Notification - CallbackDescription
//   * Id - String
//   * Version - String
//   * AdditionalInformationSearchParameters - Map
//
Function ContextForLoadingComponentsFromAFile() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("Version", "");
	Context.Insert("AdditionalInformationSearchParameters", New Map);
	Return Context;
	
EndFunction
	
// To be called from AddInClient.ImportAddInFromFile.
// 
// Parameters:
//  Context - See ContextForLoadingComponentsFromAFile.
//
Procedure ImportAddInFromFile(Context) Export 
	
	Information = AddInsInternalServerCall.SavedAddInInformation(Context.Id, Context.Version);
	
	If Information.ImportFromFileIsAvailable Then
		
		AdditionalInformationSearchParameters = Context.AdditionalInformationSearchParameters;
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
		FormParameters.Insert("ReturnImportResultFromFile", True);
		FormParameters.Insert("AdditionalInformationSearchParameters", AdditionalInformationSearchParameters);
		
		If Information.State = "FoundInStorage"
			Or Information.State = "DisabledByAdministrator" Then
			
			FormParameters.Insert("ShowImportFromFileDialogOnOpen", False);
			FormParameters.Insert("Key", Information.Ref);
		EndIf;
		
		Notification = New CallbackDescription("ImportAddInFromFileAfterImport", ThisObject, Context);
		OpenForm("Catalog.AddIns.ObjectForm", FormParameters,,,,, Notification);
		
	Else 
		
		Notification = New CallbackDescription("ImportAddInFromFileAfterAvailabilityWarnings", ThisObject, Context);
		ShowMessageBox(Notification, 
			NStr("vi = 'Tải xuống thành phần bên ngoài đã bị hủy bỏ
			           |vì lý do:
			           |Yêu cầu quyền quản trị viên';
			           |ru = 'Загрузка внешней компоненты прервана
			           |по причине:
			           |Требуются права администратора';
			           |en = 'Add-in import is canceled
			           |due to:
			           |You must have administrative rights'; fa = 'Add-in import is canceled
			           |due to:
			           |You must have administrative rights';
			           |it = 'Il download del componente esterno è stato interrotto
			           | a causa di:
			           | Richiesti diritti amministratore';
			           |pl = 'Pobieranie zewnętrznego komponentu jest zatrzymano 
			           |z powodu:
			           | Są wymagane prawa administratora';
			           |tr = 'Harici bileşenin yüklenmesi şu sebeple iptal edildi
			           |:
			           | Yönetici yetkileri gerekmektedir'"));
		
	EndIf;
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Procedure ImportAddInFromFileAfterAvailabilityWarnings(Context) Export
	
	Result = AddInImportResult();
	Result.Imported1 = False;
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Procedure ImportAddInFromFileAfterImport(Result, Context) Export
	
	// Result: 
	// - Structure - Add-in attached.
	// - Undefined - Close the dialog. 
	
	UserClosedDialogBox = (Result = Undefined);
	
	Notification = Context.Notification;
	
	If UserClosedDialogBox Then 
		Result = AddInImportResult();
		Result.Imported1 = False;
	EndIf;
	
	RunCallback(Notification, Result);
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
Function AddInImportResult() Export
	
	Result = New Structure;
	Result.Insert("Imported1", False);
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ComponentSearchOnPortal

Procedure AddInSearchOnPortalOnGenerateResult(Result, Notification) Export
	
	Imported1 = (Result = True); // When the form is closed, it is set to "Undefined".
	RunCallback(Notification, Imported1);
	
EndProcedure

#EndRegion

#Region UpdateAddInsFromPortal

// Parameters:
//  Notification - CallbackDescription
//  AddInsToUpdate - Array of CatalogRef.AddIns
//
Procedure UpdateAddInsFromPortal(Notification, AddInsToUpdate) Export
	
	NotificationForms = New CallbackDescription("UpdateAddInFromPortalOnGenerateResult", ThisObject, Notification);
	AddInsClientLocalization.OnUpdateAddInsFromPortal(NotificationForms, AddInsToUpdate);
	
EndProcedure

Procedure UpdateAddInFromPortalOnGenerateResult(Result, Notification) Export
	
	RunCallback(Notification, Undefined);
	
EndProcedure

#EndRegion

#Region SaveAddInToFile

// Parameters:
//  AddInRef - CatalogRef.AddIns
//                          - Array of CatalogRef.AddIns
//
Procedure SaveAddInToFile(AddInRef) Export
	
	If TypeOf(AddInRef) = Type("Array") Then
		References = AddInRef;
	Else
		References = CommonClientServer.ValueInArray(AddInRef);
	EndIf;
	FilesDetails = AddInsInternalServerCall.AddInsFilesDetails(References);

	If References.Count() = 1 Then
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu cấu phần ngoài';
											|ru = 'Выберите файл для сохранения внешней компоненты';
											|en = 'Select a file to save the add-in to'; fa = 'Select a file to save the add-in to';
											|it = 'Selezionare file per il salvataggio del componente esterno';
											|pl = 'Wybierz plik do zapisu komponentu zewnętrznego';
											|tr = 'Harici bileşenin kaydedilmesi için dosya seçin'");
		SavingParameters.Dialog.Filter    = NStr("vi = 'Tệp cấu phần ngoài (*.zip)|*.zip ';
												|ru = 'Файлы внешних компонент (*.zip)|*.zip';
												|en = 'Add-in files (*.zip)|*.zip'; fa = 'Add-in files (*.zip)|*.zip';
												|it = 'Файлы внешних компонент (*.zip)|*.zip';
												|pl = 'Add-in files (*.zip)|*.zip';
												|tr = 'Harici bileşen dosyaları (*.zip)|*.zip'") + "|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), 
				GetAllFilesMask());
		
		Notification = New CallbackDescription("SaveAddInToFileAfterReceivingFiles", ThisObject);
		FileSystemClient.SaveFile(Notification, FilesDetails[0].Location, FilesDetails[0].Name, SavingParameters);
		
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SaveAddInsToFileAfterDirectorySelected", ThisObject, FilesDetails);
	FileSystemClient.SelectDirectory(Notification, NStr("vi = 'Hãy chọn thư mục để lưu cấu phần ngoài';
														|ru = 'Выберите каталог для сохранения внешних компонент';
														|en = 'Select a directory to save the add-ins'; fa = 'Select a directory to save the add-ins';
														|it = 'Выберите каталог для сохранения внешних компонент';
														|pl = 'Select a directory to save the add-ins';
														|tr = 'Harici bileşenlerin kaydedilmesi için dizin seçin'"));
	
EndProcedure

// Continuation of the SaveAddInToFile procedure.
Procedure SaveAddInsToFileAfterDirectorySelected(Directory, FilesDetails) Export
	
	If IsBlankString(Directory) Then
		Return;
	EndIf;
	
	FilesToSave = New Array;
	For Each FileDetails In FilesDetails Do
		FilesToSave.Add(New TransferableFileDescription(FileDetails.Name, FileDetails.Location));
	EndDo;
	
	SavingParameters = FileSystemClient.FilesSavingParameters();
	SavingParameters.Interactively = False;
	SavingParameters.Dialog.Directory = Directory;
	FileSystemClient.SaveFiles(New CallbackDescription(
		"SaveAddInToFileAfterReceivingFiles", ThisObject), 
		FilesToSave, SavingParameters);

EndProcedure

// Continuation of the SaveAddInToFile procedure.
Procedure SaveAddInToFileAfterReceivingFiles(ObtainedFiles, Context) Export
	
	If ObtainedFiles <> Undefined 
		And ObtainedFiles.Count() > 0 Then
		
		MessageText = ?(ObtainedFiles.Count() = 1, 
			NStr("vi = 'Đã lưu thành công cấu phần ngoài vào tệp.';
				|ru = 'Внешняя компонента успешно сохранена в файл.';
				|en = 'The add-in is saved to the file.'; fa = 'The add-in is saved to the file.';
				|it = 'Componente esterno salvato nel file con successo.';
				|pl = 'Komponent zewnętrzny pomyślnie jest zapisany do pliku.';
				|tr = 'Harici bileşen başarıyla dosyaya kaydedildi.'"),
			NStr("vi = 'Đã lưu thành công cấu phần ngoài vào tệp.';
				|ru = 'Внешние компоненты успешно сохранены в файлы.';
				|en = 'The add-ins are saved to the files.'; fa = 'The add-ins are saved to the files.';
				|it = 'Внешние компоненты успешно сохранены в файлы.';
				|pl = 'The add-ins are saved to the files.';
				|tr = 'Harici bileşenler başarıyla dosyalara kaydedildi.'"));
		
		ShowUserNotification(NStr("vi = 'Lưu vào tệp';
									|ru = 'Сохранение в файл';
									|en = 'Save to file'; fa = 'ذخیره در فایل';
									|it = 'Salvare nel file';
									|pl = 'Zapis do pliku';
									|tr = 'Dosyaya kaydedilmesi'"),,
			MessageText, PictureLib.Success32);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

