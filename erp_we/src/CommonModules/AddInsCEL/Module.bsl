///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Connects on the 1C server:Create an external component from the external component store
// using the Native API or COM technology.
// The service model only allows connecting shared external components that are approved by the service administrator.
//
// Parameters:
//  ObjectName - String - ID of the external component object.
//  FullTemplateName - String - the name of the Template where the component is contained.
//
// Returns:
//  AddInObject - instance of an external component object;
//
Function AttachAddInSSL(Val ObjectName, Val FullTemplateName) Export
	
	AddIn = Undefined;
	
	Isolated = IsolatedConnectionOfExternalComponentsOnServer();
	
#If Not MobileAppServer Then
	SetSafeModeDisabled(True);
	
		// Calling BSP
	If CommonCEL.SeparatedDataUsageAvailable() 
		And CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
			
		ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
		ConnectionParameters = ExternalComponentsServerModule.ConnectionParameters();
		ConnectionParameters.Isolated = Isolated;
		
		ConnectionResult = ExternalComponentsServerModule.AttachAddInSSL(ObjectName, , ConnectionParameters);
		If ConnectionResult.Attached Then
			AddIn = ConnectionResult.Attachable_Module;
		EndIf;
			
	EndIf;
	// The end of the BSP Challenge
#EndIf
	
	If AddIn = Undefined Then 
		AddIn = AttachAddInFromTemplate(ObjectName, FullTemplateName, Isolated);
	EndIf;
	
	Return AddIn;
	
EndFunction

// Information about the external component by ID and version.
//
// Parameters:
//  Id - String - ID of the external component object.
//  Version - String - version of the component. 
//
// Returns:
//  Structure:
//      * Exists - Boolean - indicates that the component is missing.
//      * EditingAvailable - Boolean - indicates that the component can be changed by the scope administrator.
//      * ErrorDescription - String - brief description of the error.
//      * Id - String - ID of the external component object.
//      * Version - String - version of the component.
//      * Description - String - name and brief information about the component.
//
Function AddInInformation(Id, Version = Undefined) Export
	
	If CommonCEL.BSPIsUsed() Then
		
		// Calling BSP
		ModuleExternalComponentsCallingServer = CommonCEL.CommonModule("AddInServerCall");
		Result = ModuleExternalComponentsCallingServer.AddInInformation(Id, Version);
		// The end of the BSP Challenge
		
	Else
		Result = ResultInformationOnComponent();
		Result.Id = Id;
		Result.Exists = False;
		Result.ErrorDescription = NStr("vi = 'Chưa tìm thấy cấu phần bên ngoài';
										|ru = 'Внешняя компонента не найдена';
										|en = 'Add-in is not found'; fa = 'Add-in is not found';
										|it = 'Внешняя компонента не найдена';
										|pl = 'Add-in is not found';
										|tr = 'Harici bileşen bulunmadı'");
	EndIf;
	
	Return Result;
	
EndFunction

// Returns information about the component from the external component file.
//
// Parameters:
//  BinaryData - BinaryData - binary data of the components file.
//  ParseInfoFile - Boolean - do I need to further analyze
//          the file data INFO.XML if there is one.
//  AdditionalInformationSearchParameters - See AddInsCELClient.ImportParameters.
//
// Returns:
//  Structure:
//      * Disassembled - Boolean - True if the component information was successfully extracted.
//      * Attributes - see the components details
//      * BinaryData - Undefined, BinaryData - uploading the components file.
//      * AdditionalInformation - Map of KeyAndValue - information obtained from the passed search parameters.
//      * ErrorDescription - String - error text in case it is disassembled = A lie.
//
Function InformationOnAddInFromFile(BinaryData, ParseInfoFile = True,
	Val AdditionalInformationSearchParameters = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Disassembled", False);
	Result.Insert("Attributes", New Structure);
	Result.Insert("BinaryData", Undefined);
	Result.Insert("AdditionalInformation", New Map);
	Result.Insert("ErrorDescription", "");
	
	If CommonCEL.BSPIsUsed() Then
		// Calling BSP
		If CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
			ModuleAddInsInternal = CommonCEL.CommonModule("AddInsInternal");
			Result = ModuleAddInsInternal.InformationOnAddInFromFile(
				BinaryData, ParseInfoFile, AdditionalInformationSearchParameters);
		EndIf;
		// The end of the BSP Challenge
	EndIf;
	
	Return Result;

EndFunction

// Connects a component made using the Native API and COM technology.
// The component should be stored in the configuration Template as a ZIP archive.
//
// Parameters:
//  Id   - String - ID of the external component object.
//  FullTemplateName - String - the full name of the configuration Template that stores the ZIP archive.
//  Isolated - AddInAttachmentType
//
// Returns:
//   Undefined, AddInObject - instance of an external component object;
//
Function AttachAddInFromTemplate(Val Id, Val FullTemplateName, Val Isolated = False) Export

	If CommonCEL.BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonCEL.CommonModule("Common");
		Return GeneralPurposeModule.AttachAddInFromTemplate(Id, FullTemplateName, Isolated);
		// The end of the BSP Challenge
		
	Else
		Attachable_Module = Undefined;
		
		If Not TemplateExists(FullTemplateName) Then 
			Raise StrTemplate(
				NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên server
				           |trong số %2
				           |do nguyên nhân:
				           |Đã cấm kết nối trên server không phải từ khuôn in';
				           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
				           |из %2
				           |по причине:
				           |Подключение на сервере не из макета запрещено';
				           |en = 'Cannot attach the ""%1"" add-in on the server
				           |from %2.
				           |Reason:
				           |Attachment on the server not from the template is not allowed'; fa = 'Cannot attach the ""%1"" add-in on the server
				           |from %2.
				           |Reason:
				           |Attachment on the server not from the template is not allowed';
				           |it = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
				           |из %2
				           |по причине:
				           |Подключение на сервере не из макета запрещено';
				           |pl = 'Cannot attach the ""%1"" add-in on the server
				           |from %2.
				           |Reason:
				           |Attachment on the server not from the template is not allowed';
				           |tr = 'Sunucudaki ""%1"" harici bileşenine %2
				           |üzerinden
				           |şu nedenden dolayı bağlanılamadı:
				           |Sunucuda şablondan olmayan bağlantı yasaklandı'"),
				Id,
				FullTemplateName);
		EndIf;
		
		Location = FullTemplateName;
		SymbolicName = Id + "SymbolicName";
		
		#If Not MobileAppServer Then
		Result = AttachAddIn(Location, SymbolicName, , AddInAttachType(Isolated));
		#Else
		Result = AttachAddIn(Location, SymbolicName);
		#EndIf
	
		If Result Then
			
			Try
				Attachable_Module = New("AddIn." + SymbolicName + "." + Id);
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
				
				ErrorText = StrTemplate(
					NStr("vi = 'Không thể tạo đối tượng cấu phần ngoài ""%1"" mà được kết nối trên server
					           |từ khuôn in ""%2"",
					           |do nguyên nhân:
					           |%3';
					           |ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на сервере
					           |из макета ""%2"",
					           |по причине:
					           |%3';
					           |en = 'Cannot create an object for the ""%1"" add-in attached on the server
					           |from the ""%2"" template.
					           |Reason:
					           |%3'; fa = 'Cannot create an object for the ""%1"" add-in attached on the server
					           |from the ""%2"" template.
					           |Reason:
					           |%3';
					           |it = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на сервере
					           |из макета ""%2"",
					           |по причине:
					           |%3';
					           |pl = 'Cannot create an object for the ""%1"" add-in attached on the server
					           |from the ""%2"" template.
					           |Reason:
					           |%3';
					           |tr = '""%2"" şablonu üzerinden sunucuya bağlanan ""%1"" harici bileşeni nesnesi
					           | şu nedenden
					           |dolayı oluşturulamadı:
					           |%3'"),
					Id,
					Location,
					ErrorText);
				CommonCEL.WriteErrorToEventLog(
					NStr("vi = 'Kết nối cấu phần ngoài trên server';
						|ru = 'Подключение внешней компоненты на сервере';
						|en = 'Attaching add-in on the server'; fa = 'Attaching add-in on the server';
						|it = 'Attivazione della componente esterna sul server';
						|pl = 'Podłączenie komponentów zewnętrznych na serwerze';
						|tr = 'Harici bileşenin sunucuda bağlantı'", CommonCEL.DefaultLanguageCode()),
					ErrorText);
			EndIf;
			
		Else
			
			ErrorText = StrTemplate(
				NStr("vi = 'Không thể kết nối cấu phần ngoài ""%1"" trên server
				           |từ khuôn mẫu ""%2""
				           |theo nguyên nhân:
				           |Nền tảng đã trả lại False khi kết nối cấu phần ngoài.';
				           |ru = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
				           |из макета ""%2""
				           |по причине:
				           |Платформа вернула Ложь при подключении внешней компоненты.';
				           |en = 'Cannot attach the ""%1"" add-in on the server
				           |from the ""%2""
				           | template. Reason:
				           |The platform returned False when attaching an add-in.'; fa = 'Cannot attach the ""%1"" add-in on the server
				           |from the ""%2""
				           | template. Reason:
				           |The platform returned False when attaching an add-in.';
				           |it = 'Не удалось подключить внешнюю компоненту ""%1"" на сервере
				           |из макета ""%2""
				           |по причине:
				           |Платформа вернула Ложь при подключении внешней компоненты.';
				           |pl = 'Cannot attach the ""%1"" add-in on the server
				           |from the ""%2""
				           | template. Reason:
				           |The platform returned False when attaching an add-in.';
				           |tr = 'Sunucudaki ""%1"" harici bileşeni, ""%2"" şablonu üzerinden şu nedenden
				           |dolayı bağlanamadı:
				           |Harici bileşen bağlanırken platform Yanlış değerini getirdi.'"),
				Id,
				Location);
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Kết nối cấu phần ngoài trên server';
					|ru = 'Подключение внешней компоненты на сервере';
					|en = 'Attaching add-in on the server'; fa = 'Attaching add-in on the server';
					|it = 'Attivazione della componente esterna sul server';
					|pl = 'Podłączenie komponentów zewnętrznych na serwerze';
					|tr = 'Harici bileşenin sunucuda bağlantı'", CommonCEL.DefaultLanguageCode()),
				ErrorText);
		EndIf;
		
		Return Attachable_Module;
	EndIf;
	
EndFunction

// Isolated Connection Of External Components On The Server 
// Returns:
//  Boolean - Isolated
//
Function IsolatedConnectionOfExternalComponentsOnServer() Export
	
	Isolated = False;
	StandardProcessing = True;                                                       
	AddInsCELOverridable.IsolatedConnectionOfExternalComponentsOnServer(Isolated, StandardProcessing);
	Result = ?(StandardProcessing, False, Isolated); 
	Return Result;
	
EndFunction

// Isolated Connection Of External Components On The Server 
// Returns:
//  Boolean - Isolated
//
Function IsolatedConnectionOfExternalComponentsOnClient() Export
	
	Isolated = Undefined;
	StandardProcessing = True;                                                       
	AddInsCELOverridable.IsolatedConnectionOfExternalComponentsOnClient(Isolated, StandardProcessing);
	Result = ?(StandardProcessing, Undefined, Isolated); 
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ResultInformationOnComponent()
	
	Result = New Structure;
	Result.Insert("Exists", False);
	Result.Insert("EditingAvailable", False);
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

// Checking the existence of the Template by configuration and extension metadata.
//
// Parameters:
//  FullTemplateName - String - full name of the Template.
//
// Returns:
//  Boolean - indicates that the Template exists.
//
Function TemplateExists(FullTemplateName)
	
	Template = Metadata.FindByFullName(FullTemplateName);
	If TypeOf(Template) = Type("MetadataObject") Then 
		
		Var_25_Template = New Structure("TemplateType");
		FillPropertyValues(Var_25_Template, Template);
		TemplateType = Undefined;
		If Var_25_Template.Property("TemplateType", TemplateType) Then 
			Return TemplateType <> Undefined;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function AddInAttachType(Isolated) Export
	
	If Isolated = Undefined Then
		Return Undefined;
	EndIf;
	
	#If Not MobileAppServer And Not MobileStandaloneServer Then
		
	If Isolated Then
		Return AddInAttachmentType.Isolated;
	EndIf;
	
	Return AddInAttachmentType.NotIsolated;
	
	#Else
	
	Return Undefined;
	
	#EndIf
	
EndFunction

#EndRegion