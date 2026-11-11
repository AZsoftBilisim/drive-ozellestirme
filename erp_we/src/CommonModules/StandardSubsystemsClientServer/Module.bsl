///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the metadata object selection parameters for 
// the StandardSubsystemsClient.ChooseMetadataObjects procedure.
// 
// Returns:
//  Structure:
//    * MetadataObjectsToSelectCollection - ValueList - Filter by the types of metadata objects that can be selected. 
//				For example, to select only Catalogs and Documents:
//					MetadataObjectsToSelectCollection = New ValueList;
//					MetadataObjectsToSelectCollection.Add("Catalogs");
//					MetadataObjectsToSelectCollection.Add("Documents");
//
//    * FilterByMetadataObjects - ValueList - Filter by selectable metadata objects. 
//				For example:
//					FilterByMetadataObjects = New ValueList;
//					FilterByMetadataObjects.Add("Catalog.Goods");
//					FilterByMetadataObjects.Add("Document.ProformaInvoice");
//    * SelectedMetadataObjects - ValueList - Full names of the metadata objects that should be marked 
//    			in the metadata tree.
//    * ChoiceInitialValue - String - The full name of the metadata object where the pointer is positioned by default
//              when the form opens. For example, "Catalog.Partners".
//    * SelectSingle - Boolean - Set to "True" to select a single metadata object. In this case, the user cannot select multiple rows,
//              only double-click one row. By default, it is set to "False".
//    * ChooseRefs - Boolean - Set to "True" to return references to metadata object IDs
//    			instead of their names. By default, it is set to "False".
//    			See "Common.MetadataObjectIDs".
//    * SelectCollectionsWhenAllObjectsSelected - Boolean - By default, "False". When grouping objects by kind, set the parameter to "True"
//    			to make sure that the return value includes metadata object types 
//    			(Configuration, Catalogs, Documents, etc.) in case all their child rows are selected.
//    * ShouldSelectExternalDataSourceTables - Boolean - By default, it is set to "False" for compatibility. 
//    * Title - String - If not specified, the form opens with the default title: "Select metadata objects".
//    * ObjectsGroupMethod - String - Set to "BySections" to display the metadata object tree by API sections
//    			(that is, subsystems that are part of the API) instead of type-wise grouping (Catalogs, Documents, etc.).
//    			By default, it is set to "ByKinds". Also, you can set it to "BySections,ByKinds" or "ByKinds,BySections".
//    			In this case, the form has radio buttons for switching the grouping option. 
//    			
//    * ParentSubsystems - ValueList - Specify a list of child subsystems that should be displayed 
//				on the form. 
//    * SubsystemsWithCIOnly - Boolean - Set to "True" to keep only API subsystems (API sections) in the list. 
//				By default, "False".
//    * UUIDSource - UUID - (Optional) The form's UID to be passed to the notification "SelectMetadataObjects"
//				as the "Source" parameter.
//				 
// 
Function MetadataObjectsSelectionParameters() Export
	
	FormParameters = New Structure;
	FormParameters.Insert("MetadataObjectsToSelectCollection", New ValueList);
	FormParameters.Insert("FilterByMetadataObjects", New ValueList);
	FormParameters.Insert("SelectedMetadataObjects", New ValueList);
	FormParameters.Insert("ChoiceInitialValue", "");
	FormParameters.Insert("SelectSingle", False);
	FormParameters.Insert("ChooseRefs", False);
	FormParameters.Insert("SelectCollectionsWhenAllObjectsSelected", False);
	FormParameters.Insert("ShouldSelectExternalDataSourceTables", False);
	FormParameters.Insert("Title", "");
	FormParameters.Insert("ObjectsGroupMethod", "ByKinds");
	FormParameters.Insert("ParentSubsystems", New ValueList);
	FormParameters.Insert("SubsystemsWithCIOnly", False);
	FormParameters.Insert("UUIDSource", Undefined);
	Return FormParameters;	
	
EndFunction

#EndRegion

#Region Private

Function ShouldRegisterPerformanceIndicators() Export
	Return False;
EndFunction

#Region TechnicalSupport

// Constructor of information for online support.
// See StandardSubsystemsServer.SupportInformation, "StandardSubsystemsClient.SupportInformation".
//
// Returns:
//  Structure:
//    * ApplicationName1 - Undefined
//    * ApplicationVersion - Undefined
//    * AppVersion - Undefined
//    * PlatformType - Undefined
//    * SSLVersion - Undefined
//    * OSVersion - Undefined
//    * Processor - Undefined
//    * RAM - Undefined
//    * UserAgentInformation - Undefined
//    * COMConnectorName - Undefined
//    * IsBaseConfiguration - Undefined
//    * IsFullUser - Undefined
//    * IsTrainingPlatform - Undefined
//    * ConfigurationChanged - Undefined
//
Function NewInfoForSupport() Export
	
	Result = New Structure;
	
	Result.Insert("ApplicationName1", Undefined);
	Result.Insert("ApplicationVersion", Undefined);
	Result.Insert("AppVersion", Undefined);
	Result.Insert("PlatformType", Undefined);
	Result.Insert("SSLVersion", Undefined);
	
	Result.Insert("OSVersion", Undefined);
	Result.Insert("Processor", Undefined);
	Result.Insert("RAM", Undefined);
	Result.Insert("UserAgentInformation", Undefined);
	
	Result.Insert("COMConnectorName", Undefined);
	Result.Insert("IsBaseConfiguration", Undefined);
	Result.Insert("IsFullUser", Undefined);
	Result.Insert("IsTrainingPlatform", Undefined);
	Result.Insert("ConfigurationChanged", Undefined);
	
	Return Result;
	
EndFunction

// Information for online support.
// See StandardSubsystemsServer.SupportInformation, "StandardSubsystemsClient.SupportInformation".
//
// Parameters:
//  SupportInformation - See StandardSubsystemsClientServer.NewInfoForSupport.
//
// Returns:
//  String - Information for technical support.
//
Function SupportInformationText(SupportInformation) Export
	
	Result = New Array;
	
	MainInformationTemplate = NStr(
		"vi = '%1, %2
		|Nền tảng 1C:Enterprise: %3 %4
		|Thư viện phân hệ chuẩn: %5';
		|ru = '%1, %2
		|Платформа 1С:Предприятие: %3 %4
		|Библиотека стандартных подсистем: %5';
		|en = '%1, %2
		|1C:Enterprise: %3 %4
		|Standard Subsystem Library: %5'; fa = '%1, %2
		|1C:Enterprise: %3 %4
		|Standard Subsystem Library: %5';
		|it = '%1, %2
		|1C:Enterprise: %3 %4
		|Standard Subsystem Library: %5';
		|pl = '%1, %2
		|1C:Enterprise: %3 %4
		|Standard Subsystem Library: %5';
		|tr = '%1, %2
		|1C:Enterprise Platformu: %3 %4
		|Standart alt sistemler kitaplığı: %5'");
	
	MainInformation = StringFunctionsClientServer.SubstituteParametersToString(
		MainInformationTemplate,
		SupportInformation.ApplicationName1,
		SupportInformation.ApplicationVersion,
		SupportInformation.AppVersion,
		SupportInformation.PlatformType,
		SupportInformation.SSLVersion);
	
	Result.Add(MainInformation);
	Result.Add("");
	
	SystemInformationTemplate = NStr(
		"vi = 'Thông tin hệ thống
		|Phiên bản TSCĐ hữu hình: %1
		|Lõi xử lý: %2
		|RAM: %3';
		|ru = 'Системная информация
		|Версия ОС: %1
		|Процессор: %2
		|Оперативная память: %3';
		|en = 'System info
		|OS: %1
		|CPU: %2
		|RAM: %3'; fa = 'System info
		|OS: %1
		|CPU: %2
		|RAM: %3';
		|it = 'System info
		|OS: %1
		|CPU: %2
		|RAM: %3';
		|pl = 'System info
		|OS: %1
		|CPU: %2
		|RAM: %3';
		|tr = 'Sistem bilgisi
		|İşletim sistemi sürümü: %1
		|İşlemci: %2
		|RAM belleği: %3'");
	
	SystemInfo = StringFunctionsClientServer.SubstituteParametersToString(
		SystemInformationTemplate,
		SupportInformation.OSVersion,
		SupportInformation.Processor,
		SupportInformation.RAM);
	
	Result.Add(SystemInfo);
	
	If ValueIsFilled(SupportInformation.UserAgentInformation) Then
		
		UserAgentInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ứng dụng: %1';
				|ru = 'Приложение: %1';
				|en = 'Application: %1'; fa = 'Application: %1';
				|it = 'Application: %1';
				|pl = 'Application: %1';
				|tr = 'Uygulama: %1'"), SupportInformation.UserAgentInformation);
		
		Result.Add(UserAgentInformation);
		
	EndIf;
	
	Result.Add("");
	
	AdditionalInformationTemplate = NStr(
		"vi = 'Thông tin bổ sung
		|Tên bộ kết nối COM: %1
		|Cấu hình căn bản: %2
		|Người sử dụng toàn quyền: %3
		|Nền tảng đào tạo: %4
		|Đã thay đổi cấu hình: %5';
		|ru = 'Дополнительная информация
		|Имя COM-соединителя: %1
		|Базовая конфигурация: %2
		|Полноправный пользователь: %3
		|Учебная платформа: %4
		|Конфигурация изменена: %5';
		|en = 'Additional info
		|COM connector: %1
		|Base configuration: %2
		|Full-access user: %3
		|Sandbox: %4
		|Modified configuration: %5'; fa = 'Additional info
		|COM connector: %1
		|Base configuration: %2
		|Full-access user: %3
		|Sandbox: %4
		|Modified configuration: %5';
		|it = 'Additional info
		|COM connector: %1
		|Base configuration: %2
		|Full-access user: %3
		|Sandbox: %4
		|Modified configuration: %5';
		|pl = 'Additional info
		|COM connector: %1
		|Base configuration: %2
		|Full-access user: %3
		|Sandbox: %4
		|Modified configuration: %5';
		|tr = 'Ek bilgiler
		|COM bağlantı noktasının adı: %1
		|Temel yapılandırma: %2
		|Tam yetkili kullanıcı: %3
		|Eğitim platformu: %4
		|Konfigürasyon değiştirildi: %5'");
	
	AdditionalInformation = StringFunctionsClientServer.SubstituteParametersToString(
		AdditionalInformationTemplate,
		SupportInformation.COMConnectorName,
		SupportInformation.IsBaseConfiguration,
		SupportInformation.IsFullUser,
		SupportInformation.IsTrainingPlatform,
		SupportInformation.ConfigurationChanged);
	
	Result.Add(AdditionalInformation);
	Result.Add("");
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

#EndRegion

#EndRegion
