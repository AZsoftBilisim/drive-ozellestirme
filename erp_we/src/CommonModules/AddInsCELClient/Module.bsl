///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region AddInsAttachment

// Parameters for calling the external component Client procedure.Connect a component.
//
// Returns:
//  Structure:
//      * Cached - Boolean - (default is True) use the component caching mechanism on the client.
//      * SuggestInstall - Boolean - (default is True) suggest installing the component.
//      * SuggestToImport - Boolean - (True by default) offer to download the component from ITS website.
//      * ExplanationText - String - what the component is needed for and what won't work if you don't install it.
//      * ObjectsCreationIDs - Array of String - array of object module instance creation ID strings,
//                used only for components that have multiple object creation IDs
//                . when setting the ID parameter, It will only be used to define the component.
//      * Isolated - Boolean, Undefined - (Undefined by default) if True, the component will be connected
//                in isolation, in which case the external component is loaded into a separate operating system process;
//                False - in this case, the external component will be executed in the same operating system process
//                that executes the embedded language code; Undefined - the default behavior of the platform is supported:
//                in isolation - if the component supports only this mode, not isolated - in other cases.
//                See https://its.1c.ru/db/v83doc#bookmark:dev:TI000001866
//
// Example:
//
//  Connection parameters = External Component Client.Connection Parameters();
//  Connection parameters.Explanation text = 
//      NStr ("ru = 'To use a barcode scanner, you need
//                 |external component ""1C:Barcode Scanners (NativeAPI)"".'");
//
Function ConnectionParameters() Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Parameters = ModuleAddInsClient.ConnectionParameters();
		// The end of the BSP Challenge
		
	Else
		Parameters = BPOConnectionParameters();
	EndIf;
	Return Parameters;
	
EndFunction

// Connects a component executed using the Native API or COM technology on the client computer.
// The web client offers a dialog that prompts the user for installation actions.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Id - String - ID of the external component object.
//  Version        - String - version of the component.
//  ConnectionParameters - See ConnectionParameters.
//
// Returns:
//  Structure - See ConnectionResult.
//
Async Function AttachAddInSSLAsync(Id, Version = Undefined, ConnectionParameters = Undefined) Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Return Await ModuleAddInsClient.AttachAddInSSLAsync(Id, Version, ConnectionParameters);
		// The end of the BSP Challenge
		
	Else
		ExecutionResult = New Structure();
		ExecutionResult.Insert("Attached", False);
		ExecutionResult.Insert("ErrorDescription",  NStr("vi = 'Chức năng này chỉ được phép khi sử dụng phân hệ Thư viện phân hệ chuẩn.';
														|ru = 'Функциональность доступна только при использовании подсистемы БСП.';
														|en = 'The functionality is available only when the SSL subsystem is used.'; fa = 'The functionality is available only when the SSL subsystem is used.';
														|it = 'Функциональность доступна только при использовании подсистемы БСП.';
														|pl = 'The functionality is available only when the SSL subsystem is used.';
														|tr = 'Bu işlevsellik sadece SSL alt sistemi kullanıldığında mevcuttur.'"));
		Return ExecutionResult;
	EndIf;
	
EndFunction

// Connects a component executed using the Native API or COM technology on the client computer.
// The web client offers a dialog that prompts the user for installation actions.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Notification - CallbackDescription - description of the activation notification with the following parameters:
//      * Result - See ConnectionResult.
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  Id - String - ID of the external component object.
//  Version        - String - version of the component.
//  ConnectionParameters - See AddInsCELClient.ConnectionParameters.
//
Procedure AttachAddInSSL(Notification, Id, Version = Undefined, ConnectionParameters = Undefined) Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		ModuleAddInsClient.AttachAddInSSL(Notification, Id, Version, ConnectionParameters);
		// The end of the BSP Challenge
		
	Else
		ExecutionResult = New Structure();
		ExecutionResult.Insert("Attached", False);
		ExecutionResult.Insert("ErrorDescription",  NStr("vi = 'Chức năng này chỉ được phép khi sử dụng phân hệ Thư viện phân hệ chuẩn.';
														|ru = 'Функциональность доступна только при использовании подсистемы БСП.';
														|en = 'The functionality is available only when the SSL subsystem is used.'; fa = 'The functionality is available only when the SSL subsystem is used.';
														|it = 'Функциональность доступна только при использовании подсистемы БСП.';
														|pl = 'The functionality is available only when the SSL subsystem is used.';
														|tr = 'Bu işlevsellik sadece SSL alt sistemi kullanıldığında mevcuttur.'"));
		If Notification<>Undefined Then
			RunCallback(Notification, ExecutionResult)
		EndIf;
	EndIf;
	
EndProcedure

// Connects a COM component from the Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C 7.7 components). 
//
// Parameters:
//  Id - String - ID of the external component object.
//  ObjectCreationID - String - id of the object module instance creation
//          (only for components whose object creation ID differs from the ProgID).
//
// Returns:
//  See ConnectionResult.
//
Async Function AttachAddInFromWindowsRegistryAsync(Id, ObjectCreationID = Undefined) Export 
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Return ModuleAddInsClient.AttachAddInFromWindowsRegistryAsync(Id, ObjectCreationID);
		// The end of the BSP Challenge
		
	Else
		ConnectionResult = ConnectionResult();
		Try
			ConnectionResult.Attached = Await AttachAddInAsync("AddIn." + Id);
		Except
			ConnectionResult.Attached = False;
		EndTry;
		
		If ConnectionResult.Attached Then 
			
			If ObjectCreationID = Undefined Then 
				ObjectCreationID = Id;
			EndIf;
			
			Try
				Attachable_Module = New("AddIn." + ObjectCreationID);
				If Attachable_Module = Undefined Then 
					Raise NStr("vi = 'Toán tử Mới trả lại Không xác định';
								|ru = 'Оператор Новый вернул Неопределено';
								|en = 'The New operator returned Undefined.'; fa = 'The New operator returned Undefined.';
								|it = 'L''operatore Nuovo ha ritornato Indefinito';
								|pl = 'Operator Nowy zwrócił Nieokreślono';
								|tr = 'Operatör Yeni iade etti Belirsiz'");
				EndIf;
				ConnectionResult.Attachable_Module = Attachable_Module;
			Except
				ConnectionResult.Attached = False;
			EndTry;
		EndIf;
		
		If Not ConnectionResult.Attached Then
			ConnectionResult.ErrorDescription = StrTemplate(
				NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
				           |do nguyên nhân:
				           |%2';
				           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |по причине:
				           |%2';
				           |en = 'Cannot attach the ""%1"" add-in on the client
				           |due to:
				           |%2'; fa = 'Cannot attach the ""%1"" add-in on the client
				           |due to:
				           |%2';
				           |it = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |по причине:
				           |%2';
				           |pl = 'Cannot attach the ""%1"" add-in on the client
				           |due to:
				           |%2';
				           |tr = 'İstemcide ""%1"" harici bileşeni şu nedenden dolayı
				           |bağlanamadı:
				           |%2'"),
				Id,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndIf;
		
		Return ConnectionResult;
		
	EndIf;
	
EndFunction

// Connects a COM component from the Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C 7.7 components). 
//
// Parameters:
//  Notification - CallbackDescription - description of the activation notification with the following parameters:
//      * Result - See ConnectionResult
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  Id - String - ID of the external component object.
//  ObjectCreationID - String - id of the object module instance creation
//          (only for components whose object creation ID differs from the ProgID).
//
Procedure AttachAddInFromWindowsRegistry(Notification, Id, ObjectCreationID = Undefined) Export 
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		ModuleAddInsClient.AttachAddInFromWindowsRegistry(Notification, Id, ObjectCreationID);
		// The end of the BSP Challenge
		
	Else
		
		Context = New Structure;
		Context.Insert("Notification"                  , Notification);
		Context.Insert("Id"               , Id);
		Context.Insert("ObjectCreationID", ObjectCreationID);
		
		Notification = New CallbackDescription("ConnectComponentFromWindowsRegistryEnd", ThisObject, Context);
		BeginAttachingAddIn(Notification, "AddIn." + Id);
		
	EndIf;
	
EndProcedure

// Connects a component made using Native API and COM technology in asynchronous mode, via the waiting mechanism.
// The component should be stored in the configuration Template as a ZIP archive.
//
// Parameters:
//  Id        - String - ID of the external component object.
//  FullTemplateName      - String - the full name of the layout used as the component location.
//  ConnectionParameters - Structure
//                       - Undefined - see the Connection Parameter function.
// 
// Returns:
//  See ConnectionResult.
//
Async Function AttachAddInFromTemplateAsync(Id, FullTemplateName, ConnectionParameters = Undefined) Export
	
	If Not CommonCELClientServer.IsMobileClient() And CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonCELClient.CommonModule("CommonClient");
		Return Await ModuleCommonClient.AttachAddInFromTemplateAsync(Id, FullTemplateName, ConnectionParameters);
		// The end of the BSP Challenge
		
	Else
		If ConnectionParameters = Undefined Then
			ConnectionParameters = BPOConnectionParameters();
		EndIf;
		ConnectionResult = ConnectionResult();
		
		If IsBlankString(Id) Then
			ConnectionResult.ErrorDescription = NStr("vi = 'Chưa chỉ ra tên định danh cấu phần.';
													|ru = 'Идентификатор компоненты не указан.';
													|en = 'Add-in ID is not specified.'; fa = 'Add-in ID is not specified.';
													|it = 'Идентификатор компоненты не указан.';
													|pl = 'Add-in ID is not specified.';
													|tr = 'Bileşen kimliği belirtilmedi.'");
		Else                                                             
			
			If ConnectionParameters <> Undefined And Not ConnectionParameters.Cached Then
				SymbolicName = "From1" + StrReplace(String(New UUID), "-", "");
			Else    
				SymbolicName = StrReplace(Id, ".", "_");
			EndIf;
			
			Try
				#If MobileAppClient Or MobileClient Then
				ConnectionResult.Attached = Await AttachAddInAsync(FullTemplateName, SymbolicName);
				#Else
				ConnectionResult.Attached = Await AttachAddInAsync(FullTemplateName, SymbolicName,,
					AddInAttachType(ConnectionParameters.Isolated));
				#EndIf
			Except
				ConnectionResult.Attached = False;
			EndTry;
			
			If ConnectionResult.Attached Then
				Try
					ProgID = "AddIn." + SymbolicName + "." + Id;
					#If MobileAppClient Or MobileClient Then
						ConnectionResult.Attachable_Module = New (ProgID);
					#Else
						ConnectionResult.Attachable_Module = Await CreateAddInObjectAsync(ProgID); 
					#EndIf
				Except
					ConnectionResult.Attached = False;
				EndTry;
			EndIf;
			
			If Not ConnectionResult.Attached Then
				ConnectionResult.ErrorDescription = StrTemplate(
					NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client
					           |%2
					           | do nguyên nhân:
					           |%3';
					           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
					           |%2
					           |по причине:
					           |%3';
					           |en = 'Cannot attach add-in ""%1"" on the client
					           |%2
					           |Reason:
					           |%3'; fa = 'Cannot attach add-in ""%1"" on the client
					           |%2
					           |Reason:
					           |%3';
					           |it = 'Impossibile connettere la componente esterna ""%1"" sul client
					           |%2
					           |a causa di:
					           |%3';
					           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" dla klienta
					           |%2
					           |z powodu:
					           |%3';
					           |tr = '
					           | istemcinin ""%1"" harici bileşeni ""%2""
					           | nedenle bağlanamadı: 
					           |%3'"),
					Id,
					FullTemplateName,
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndIf;
				
			Return ConnectionResult;
			
		EndIf;
	EndIf;
	
EndFunction

// Connects a component made using Native API and COM technology in asynchronous mode.
// the component should be stored in the configuration Template as a zip archive.
//
// Parameters:
//  NotificationWhenConnecting - CallbackDescription - description of the activation notification with the following parameters:
//      * Result - See ConnectionResult.
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  Id        - String - ID of the external component object.
//  FullTemplateName      - String - the full name of the layout used as the component location.
//  ConnectionParameters - Structure
//                       - Undefined - see the Connection Parameter function.
Procedure AttachAddInFromTemplate(NotificationWhenConnecting, Id, FullTemplateName, ConnectionParameters = Undefined) Export
	
	If  Not CommonCELClientServer.IsMobileClient() And CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonCELClient.CommonModule("CommonClient");
		ModuleCommonClient.AttachAddInFromTemplate(NotificationWhenConnecting, Id, FullTemplateName, ConnectionParameters);
		// The end of the BSP Challenge
		
	Else
		Result = ConnectionResult();
	
		If IsBlankString(Id) Then
			Result.ErrorDescription = NStr("vi = 'Chưa chỉ ra tên định danh cấu phần.';
											|ru = 'Идентификатор компоненты не указан.';
											|en = 'Add-in ID is not specified.'; fa = 'Add-in ID is not specified.';
											|it = 'Идентификатор компоненты не указан.';
											|pl = 'Add-in ID is not specified.';
											|tr = 'Bileşen kimliği belirtilmedi.'");
			RunCallback(NotificationWhenConnecting, Result);
		Else
			Context = New Structure();
			Context.Insert("Id", Id);
			Context.Insert("Notification", NotificationWhenConnecting);
			Notification = New CallbackDescription("AttachAddInFromTemplateCompletion", ThisObject, Context);
			BeginAttachingAddIn(Notification, FullTemplateName, StrReplace(Id, ".", "_"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region InstallingExternalComponents

// The structure of parameters for the External Component Client procedure.Install the component.
//
// Returns:
//  Structure:
//      * ExplanationText - String - what the component is needed for and what won't work if you don't install it.
//      * SuggestToImport - Boolean - offer to download the component from ITS website
//      * SuggestInstall - Boolean - (False by default) suggest installing the component.
//
// Example:
//
//  Installation parameters = External Component Client.Installation Parameters();
//  Installation parameters.Explanation text = 
//      NStr ("ru = 'To use a barcode scanner, you need
//                 |external component ""1C:Barcode Scanners (NativeAPI)"".'");
//
Function InstallationParameters() Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Parameters = ModuleAddInsClient.InstallationParameters();
		// The end of the BSP Challenge
		
	Else
		Parameters = BPOInstallationParameters();
	EndIf;
	
	Return Parameters;
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Id - String - ID of the external component object.
//  Version - String - version of the component.
//  InstallationParameters - See InstallationParameters.
//
// Returns:
//  See InstallResult.
//
Async Function InstallAddInSSLAsync(Id, Version = Undefined, InstallationParameters = Undefined) Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		InstallResult = Await ModuleAddInsClient.InstallAddInSSLAsync(Id, Version, 
			InstallationParameters);
		// The end of the BSP Challenge
		
	Else
		InstallResult = InstallResult();
		InstallResult.IsSet    = False;
		InstallResult.ErrorDescription = NStr("vi = 'Chức năng chỉ được phép khi sử dụng phân hệ Thư viện phân hệ chuẩn.';
												|ru = 'Функциональность доступна только при использовании подсистемы БСП.';
												|en = 'The functionality is available only when the SSL subsystem is used.'; fa = 'The functionality is available only when the SSL subsystem is used.';
												|it = 'Функциональность доступна только при использовании подсистемы БСП.';
												|pl = 'The functionality is available only when the SSL subsystem is used.';
												|tr = 'Bu işlevsellik sadece SSL alt sistemi kullanıldığında mevcuttur.'");
	EndIf;
	Return InstallResult;
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Notification - CallbackDescription - description of the notification about the installation of an external component:
//      * Result - See InstallResult.
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  Id - String - ID of the external component object.
//  Version - String - version of the component.
//  InstallationParameters - See InstallationParameters.
//
Procedure InstallAddInSSL(Notification, Id, Version = Undefined, InstallationParameters = Undefined) Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		ModuleAddInsClient.InstallAddInSSL(Notification, Id, Version, InstallationParameters);
		// The end of the BSP Challenge
		
	Else
		InstallResult = InstallResult();
		InstallResult.IsSet    = False;
		InstallResult.ErrorDescription = NStr("vi = 'Chức năng được phép chỉ khi sử dụng phân hệ Thư viện phân hệ chuẩn.';
												|ru = 'Функциональность доступна только при использовании подсистемы БСП.';
												|en = 'The functionality is available only when the SSL subsystem is used.'; fa = 'The functionality is available only when the SSL subsystem is used.';
												|it = 'Функциональность доступна только при использовании подсистемы БСП.';
												|pl = 'The functionality is available only when the SSL subsystem is used.';
												|tr = 'Bu işlevsellik sadece SSL alt sistemi kullanıldığında mevcuttur.'");
		If Notification <> Undefined Then
			RunCallback(Notification, InstallResult);
		EndIf;
	EndIf;
	
EndProcedure

// Sets a component executed using the Native API technology and in asynchronous mode.
// The component must be stored in the configuration layout as a ZIP archive.
//
// Parameters:
//  FullTemplateName    - String                  - the full name of the layout used as the component location.
//  InstallationParameters - Structure
//                     - Undefined - see the Setting Parameters function.
//
// Returns:
//  See InstallResult.
//
Async Function InstallAddInFromTemplateAsync(FullTemplateName, InstallationParameters = Undefined) Export
	
	If Not CommonCELClientServer.IsMobileClient() And CommonCELClient.BSPIsUsed() Then
		// Calling BSP
		ModuleCommonClient = CommonCELClient.CommonModule("CommonClient");
		InstallResult = Await ModuleCommonClient.InstallAddInFromTemplateAsync(FullTemplateName, InstallationParameters);
		// The end of the BSP Challenge
	Else
		If InstallationParameters <> Undefined Then
			Await DoMessageBoxAsync(InstallationParameters.ExplanationText);
		EndIf;
		
		InstallResult = InstallResult();
		Try
			Await InstallAddInAsync(FullTemplateName);
			InstallResult.IsSet = True;
		Except
			InstallResult.IsSet = False;
			InstallResult.ErrorDescription = StrTemplate(
					NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên client 
					           |do nguyên nhân:
					           |%2';
					           |ru = 'Не удалось установить внешнюю компоненту ""%1"" на клиенте 
					           |по причине:
					           |%2';
					           |en = 'Cannot install the ""%1"" add-in on the client 
					           |due to:
					           |%2'; fa = 'Cannot install the ""%1"" add-in on the client 
					           |due to:
					           |%2';
					           |it = 'Не удалось установить внешнюю компоненту ""%1"" на клиенте 
					           |по причине:
					           |%2';
					           |pl = 'Cannot install the ""%1"" add-in on the client 
					           |due to:
					           |%2';
					           |tr = 'İstemcide ""%1"" harici bileşeni şu nedenden dolayı
					           |yapılandırılamadı:
					           |%2'"),
					FullTemplateName,
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	Return InstallResult;
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// The component must be stored in the configuration layout as a ZIP archive.
//
// Parameters:
//  CompletionNotification - CallbackDescription - description of the notification about the installation of an external component:
//      * Result - See InstallResult.
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  FullTemplateName    - String                  - the full name of the layout used as the component location.
//  InstallationParameters - Structure
//                     - Undefined - see the Setting Parameters function.
//
Procedure InstallAddInFromTemplate(CompletionNotification, FullTemplateName, InstallationParameters = Undefined) Export
	
	If Not CommonCELClientServer.IsMobileClient() And CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonCELClient.CommonModule("CommonClient");
		ModuleCommonClient.InstallAddInFromTemplate(CompletionNotification, FullTemplateName, InstallationParameters);
		// The end of the BSP Challenge
		
	Else
		
		Context = New Structure();
		Context.Insert("FullTemplateName", FullTemplateName);
		Context.Insert("Notification", CompletionNotification);
		Context.Insert("InstallationParameters", InstallationParameters);
		
		Notification = New CallbackDescription("InstallAddInFromTemplateCompletion", ThisObject, Context);
		BeginInstallAddIn(Notification, FullTemplateName);
	EndIf;
	
EndProcedure

#EndRegion

#Region LoadingExternalComponents

// Returns the structure of parameters for describing the rules for searching for additional information in an external component
// . See the procedure for loading a file component.
//
// Returns:
//  Structure:
//      * XMLFileName - String - (optional) name of the file in the component to extract information from.
//      * XPathExpression - String - (optional) XPath path to the information in the file.
//
// Example:
//
//  Loading parameters = External Component Client.Additional Information Search parametersreferences();
//  Loading parameters.Filenames are xml = "INFO.XML ";
//  Loading parameters.expressionxpath = "//drivers/component/@type";
//
Function AdditionalInformationSearchParameters() Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Parameters = ModuleAddInsClient.AdditionalInformationSearchParameters();
		// The end of the BSP Challenge
		
	Else
		Parameters = New Structure;
		Parameters.Insert("XMLFileName", "");
		Parameters.Insert("XPathExpression", "");
	EndIf;
	
	Return Parameters;
	
EndFunction

// The structure of parameters for the external component client procedure.Upload a component of the file.
//
// Returns:
//  Structure:
//      * Id - String -(optional) ID of the external component object.
//      * Version - String - (optional) version of the component.
//      * AdditionalInformationSearchParameters - Map of KeyAndValue - (optional) parameters:
//          ** Key - String - the identifier of the additional requested information.
//          ** Value - See AdditionalInformationSearchParameters.
// Example:
//
//  Loading parameters = External Component Client.Loading Parameters();
//  Loading parameters.ID = "InputDevice";
//  Loading parameters.Version = "8.1.7.10";
//
Function ImportParameters() Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		Parameters = ModuleAddInsClient.ImportParameters();
		// The end of the BSP Challenge
		
	Else
		Parameters = New Structure;
		Parameters.Insert("Id", "");
		Parameters.Insert("Version", "");
		Parameters.Insert("AdditionalInformationSearchParameters", New Map);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Loads the components file to the external components directory in asynchronous mode. 
//
// Parameters:
//  Notification - CallbackDescription - description of the notification about the installation of an external component:
//      * Result - Structure - result of component loading:
//          ** Imported1 - Boolean - indicates whether it is loading.
//          ** Id  - String - ID of the external component object.
//          ** Version - String - version of the downloaded component.
//          ** Description - String - name of the loaded component.
//          ** AdditionalInformation - Map of KeyAndValue - additional information about the component,
//                     if not requested, an empty match:
//               *** Key - See AdditionalInformationSearchParameters.
//               *** Value - See AdditionalInformationSearchParameters.
//      * AdditionalParameters - Structure - the value that was specified when creating the message Description object.
//  ImportParameters - See ImportParameters.
//
// Example:
//
//  Loading parameters = External Component Client.Loading Parameters();
//  Loading parameters.ID = "InputDevice";
//  Loading parameters.Version = "8.1.7.10";
//
//  Notification = A new description of the announcement("Upload a component from the file after loading the components", this is an object);
//
//  External component Client.Upload a File component (Notification, Upload parameters);
//
//  &NaKliente
//  Procedure to load the component from the file after loading the components (Result, additional parameters) Export
//
//      If The Result.Uploaded Then 
//          ID = Result.ID;
//          Version = Result.Version;
//      The end if;
//
//  End of the procedure
//
Procedure ImportAddInFromFile(Notification, ImportParameters = Undefined) Export
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		ModuleAddInsClient = CommonCELClient.CommonModule("AddInsClient");
		ModuleAddInsClient.ImportAddInFromFile(Notification, ImportParameters);
		// The end of the BSP Challenge
		
	Else
		ExecutionResult = New Structure();
		ExecutionResult.Insert("Imported1", False);
		ExecutionResult.Insert("ErrorDescription",  NStr("vi = 'Chức năng chỉ được phép khi sử dụng phân hệ Thư viện phân hệ chuẩn.';
														|ru = 'Функциональность доступна только при использовании подсистемы БСП.';
														|en = 'The functionality is available only when the SSL subsystem is used.'; fa = 'The functionality is available only when the SSL subsystem is used.';
														|it = 'Функциональность доступна только при использовании подсистемы БСП.';
														|pl = 'The functionality is available only when the SSL subsystem is used.';
														|tr = 'Bu işlevsellik sadece SSL alt sistemi kullanıldığında mevcuttur.'"));
		RunCallback(Notification, ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Continue with the connect component of the Windows Registry.
//
// Parameters:
//  Attached - Boolean
//  Context - Structure:
//    * Notification - CallbackDescription
//    * Id - String
//    * IdOfObjectCreation - String
Procedure ConnectComponentFromWindowsRegistryEnd(Attached, Context) Export
	
	Result = ConnectionResult();
	
	ObjectCreationID = ?(
		Context.ObjectCreationID = Undefined, 
		Context.Id, 
		Context.ObjectCreationID);
	
	If Attached Then 
		Try
			Attachable_Module = New("AddIn." + ObjectCreationID);
			If Attachable_Module = Undefined Then 
				Raise NStr("vi = 'Toán tử Mới trả lại Không xác định';
							|ru = 'Оператор Новый вернул Неопределено';
							|en = 'The New operator returned Undefined.'; fa = 'The New operator returned Undefined.';
							|it = 'L''operatore Nuovo ha ritornato Indefinito';
							|pl = 'Operator Nowy zwrócił Nieokreślono';
							|tr = 'Operatör Yeni iade etti Belirsiz'");
			EndIf;
			Result.Attached         = True;
			Result.Attachable_Module = Attachable_Module;
		Except
			Result.ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	Else 
		Result.ErrorDescription = StrTemplate(
			NStr("vi = 'Không thể kết nối cấu phần ngoài %1trên client';
				|ru = 'Не удалось подключить внешнюю компоненту %1 на клиенте';
				|en = 'Cannot attach the %1 add-in on the client'; fa = 'Cannot attach the %1 add-in on the client';
				|it = 'Не удалось подключить внешнюю компоненту %1 на клиенте';
				|pl = 'Cannot attach the %1 add-in on the client';
				|tr = 'İstemcide %1 harici bileşeni bağlanamadı'"),
			ObjectCreationID);
	EndIf;
	
	If Context.Notification<>Undefined Then
		RunCallback(Context.Notification, Result);
	EndIf;
	
EndProcedure

// Continuation of the procedure to connect the component of the package.
//
// Parameters:
//  Attached - Boolean
//  Context - Structure:
//    * Notification - CallbackDescription
//    * Id - String
//    * IdOfObjectCreation - String
Procedure AttachAddInFromTemplateCompletion(Attached, Context) Export
	
	Result = ConnectionResult();
	If Attached Then         
		Try
			ProgID = "AddIn." + StrReplace(Context.Id, ".", "_") + "." + Context.Id;
			Result.Attachable_Module = New (ProgID);
			Result.Attached = True;
		Except
			Result.ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
	If Context.Notification<>Undefined Then
		RunCallback(Context.Notification, Result);
	EndIf;
	
EndProcedure

Procedure InstallAddInFromTemplateCompletion(Context) Export
	
	Result = InstallResult();
	Result.IsSet = True;
	
	InstallationParameters = Context.InstallationParameters;
	If InstallationParameters <> Undefined Then
		CommonCELClient.MessageToUser(InstallationParameters.ExplanationText);
	EndIf;
	
	If Context.Notification <> Undefined Then
		RunCallback(Context.Notification, Result);
	EndIf;
	
EndProcedure

#If Not WebClient Then

// Reinstalls the component from the passed array of Templates recursively
// 
// Parameters:
//   EquipmentForReinstalling - Array of Structure
//
Procedure ReinstallComponents(EquipmentForReinstalling) Export

	Context = New Structure();
	Context.Insert("EquipmentForReinstalling", New Array);
	For Each DescriptionOfEquipmentForReinstalling In EquipmentForReinstalling Do
		Context.EquipmentForReinstalling.Add(DescriptionOfEquipmentForReinstalling);
	EndDo;
	
	// start recursively installing components from Templates
	Result = InstallResult();
	Result.IsSet = True;
	NotificationFromInstallation   = New CallbackDescription("InstallComponentFromTemplateRecursively", ThisObject, Context);
	RunCallback(NotificationFromInstallation, Result)
	
EndProcedure    

// Performs the installation of the component recursively
// 
// Parameters:
//  Result - Structure - Result Of Component Installation:
//   * IsSet    - Boolean - indicates the installation.
//   * ErrorDescription - String - brief description of the error. When canceled by the user, an empty string.
//  Context - Structure:
//    * EquipmentForReinstalling - Array of Structure
//
Procedure InstallComponentFromTemplateRecursively(Result, Context) Export
	
	If Not Result.IsSet Then
		CommonCELClient.MessageToUser(StrTemplate(NStr("vi = 'Lỗi cài đặt cấu phần: %1';
														|ru = 'Ошибка установки компоненты: %1';
														|en = 'An error occurred when installing the add-in: %1'; fa = 'An error occurred when installing the add-in: %1';
														|it = 'Ошибка установки компоненты: %1';
														|pl = 'An error occurred when installing the add-in: %1';
														|tr = 'Add-in kurulumu başarısız oldu: %1'"), Result.ErrorDescription));
	EndIf;
	
	EquipmentForReinstalling = Context.EquipmentForReinstalling;
	If EquipmentForReinstalling.Count()=0 Then
		Return;
	EndIf;
	LastIndex = EquipmentForReinstalling.UBound();
	DescriptionOfEquipmentForReinstalling = EquipmentForReinstalling[LastIndex];
	EquipmentForReinstalling.Delete(LastIndex);

	InstallationParameters = InstallationParameters();
	InstallationParameters.ExplanationText = StrTemplate(NStr("vi = 'Phiên bản mới của cấu phần:
		|%1. 
		|Phiên bản: %2';
		|ru = 'Новая версия компоненты:
		|%1. 
		|Версия: %2';
		|en = 'New add-in version:
		|%1. 
		|Version: %2'; fa = 'New add-in version:
		|%1. 
		|Version: %2';
		|it = 'Новая версия компоненты:
		|%1. 
		|Версия: %2';
		|pl = 'New add-in version:
		|%1. 
		|Version: %2';
		|tr = 'Bileşenin yeni sürümü:
		|%1. 
		|Sürüm: %2'"), 
		DescriptionOfEquipmentForReinstalling.Description,
		DescriptionOfEquipmentForReinstalling.Version);
	
	NotificationFromInstallation = New CallbackDescription("InstallComponentFromTemplateRecursively", ThisObject, Context);
	InstallAddInFromTemplate(NotificationFromInstallation, DescriptionOfEquipmentForReinstalling.DriverTemplateName, InstallationParameters);
	
EndProcedure

#EndIf

#EndRegion

#Region Private

// Parameters for calling the external component Client procedure.Connect a component.
//
// Returns:
//  Structure:
//      * Cached - Boolean - (default is True) use the component caching mechanism on the client.
//      * SuggestInstall - Boolean - (default is True) suggest installing the component.
//      * SuggestToImport - Boolean - (True by default) offer to download the component from ITS website.
//      * ExplanationText - String - what the component is needed for and what won't work if you don't install it.
//      * ObjectsCreationIDs - Array of String - array of object module instance creation ID strings,
//                used only for components that have multiple object creation IDs
//                . when setting the ID parameter, It will only be used to define the component.
//      * Isolated - Boolean, Undefined - (Undefined by default) if True, the component will be connected
//                in isolation, in which case the external component is loaded into a separate operating system process;
//                False - in this case, the external component will be executed in the same operating system process
//                that executes the embedded language code; Undefined - the default behavior of the platform is supported:
//                in isolation - if the component supports only this mode, not isolated - in other cases.
//                See https://its.1c.ru/db/v83doc#bookmark:dev:TI000001866
//
// Example:
//
//  Connection parameters = External Component Client.Connection Parameters();
//  Connection parameters.Explanation text = 
//      NStr ("ru = 'To use a barcode scanner, you need
//                 |external component ""1C:Barcode Scanners (NativeAPI)"".'");
//
Function BPOConnectionParameters()
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", Undefined);
	Parameters.Insert("AutoUpdate", True);
	
	Return Parameters;
	
EndFunction                  

// The structure of parameters for the External Component Client procedure.Install the component.
//
// Returns:
//  Structure:
//      * ExplanationText - String - what the component is needed for and what won't work if you don't install it.
//      * SuggestToImport - Boolean - offer to download the component from ITS website
//      * SuggestInstall - Boolean - (False by default) suggest installing the component.
//
Function BPOInstallationParameters()
	
	Parameters = New Structure;
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("SuggestInstall", False);
	
	Return Parameters;
	
EndFunction

// The result of the component connection.
// 
// Returns:
//  Structure:
//    * Attached         - Boolean - indicates whether the connection is enabled.
//    * Attachable_Module - Undefined, AddInObject  - instance of an external component object;
//                         - FixedMap of KeyAndValue - instances of objects of the external component 
//                           specified in the connection parametersreferences.Object designationidentifiers:
//                            ** Key - String - id of the external component;
//                            ** Value - AddInObject - an instance of the object.
//    * ErrorDescription     - String - brief description of the error. When canceled by the user, an empty string.
//
Function ConnectionResult() Export
	
	Result = New Structure;
	Result.Insert("Attached", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Attachable_Module", Undefined);
	Return Result;
	
EndFunction

// The result of the component installation.
//
// Returns:
//   Structure:
//     * IsSet - Boolean
//     * ErrorDescription - String
//
Function InstallResult() Export
	
	Result = New Structure;
	Result.Insert("IsSet", False);
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

Function AddInAttachType(Isolated) Export
	
	If Isolated = Undefined Then
		Return Undefined;
	EndIf;
	
	#If Not WebClient And Not MobileClient And Not MobileAppClient Then
		
	If Isolated Then
		Return AddInAttachmentType.Isolated;
	EndIf;
	
	Return AddInAttachmentType.NotIsolated;
	
	#Else
	
	Return Undefined;
	
	#EndIf
	
EndFunction

#EndRegion
