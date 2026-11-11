///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns descriptions of all configuration libraries, including
// the configuration itself.
// 
// Returns:
//  FixedStructure:
//   * Order - Array of String
//   * ByNames - Map of KeyAndValue:
//     ** Key - String
//     ** Value - See NewSubsystemDescription
//
Function SubsystemsDetails() Export
	
	SubsystemsModules = New Array;
	SubsystemsModules.Add("InfobaseUpdateSSL");
	
	SSLSubsystemsIntegration.OnAddSubsystems(SubsystemsModules);
	ConfigurationSubsystemsOverridable.OnAddSubsystems(SubsystemsModules);
	
	ConfigurationDetailsFound = False;
	SubsystemsDetails = New Structure;
	SubsystemsDetails.Insert("Order",  New Array);
	SubsystemsDetails.Insert("ByNames", New Map);
	
	AllRequiredSubsystems = New Map;
	
	For Each ModuleName In SubsystemsModules Do
		
		LongDesc = NewSubsystemDescription();
		Module = Common.CommonModule(ModuleName);
		Module.OnAddSubsystem(LongDesc);
		
		If SubsystemsDetails.ByNames.Get(LongDesc.Name) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi chuẩn bị mô tả phân hệ:
				           |trong mô tả phân hệ (xem thủ tục %1%2)
				           |đã chỉ ra tên phân hệ ""%3"", mà đã ghi nhận từ trước.';
				           |ru = 'Ошибка при подготовке описаний подсистем:
				           |в описании подсистемы (см. процедуру %1%2)
				           |указано имя подсистемы ""%3"", которое уже зарегистрировано ранее.';
				           |en = 'An error occurred when preparing subsystem details:
				           |subsystem details (see the procedure %1.%2)
				           |contain subsystem name ""%3"", which already exists.'; fa = 'An error occurred when preparing subsystem details:
				           |subsystem details (see the procedure %1.%2)
				           |contain subsystem name ""%3"", which already exists.';
				           |it = 'Ошибка при подготовке описаний подсистем:
				           |в описании подсистемы (см. процедуру %1%2)
				           |указано имя подсистемы ""%3"", которое уже зарегистрировано ранее.';
				           |pl = 'An error occurred when preparing subsystem details:
				           |subsystem details (see the procedure %1.%2)
				           |contain subsystem name ""%3"", which already exists.';
				           |tr = 'Alt sistemlerin açıklamalarını hazırlama sırasında bir hata oluştu:
				           |alt sistem tanımında (bkz. %1%2 prosedürü) 
				           |daha önce kaydedilen ""%2"" alt sistem adı belirtilmiştir.'"),
				ModuleName, "OnAddSubsystem", LongDesc.Name);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		
		If LongDesc.Name = Metadata.Name Then
			ConfigurationDetailsFound = True;
			LongDesc.Insert("IsConfiguration", True);
		Else
			LongDesc.Insert("IsConfiguration", False);
		EndIf;
		
		LongDesc.Insert("MainServerModule", ModuleName);
		
		SubsystemsDetails.ByNames.Insert(LongDesc.Name, LongDesc);
		// Setting up the subsystem order according to the adding order of main modules.
		SubsystemsDetails.Order.Add(LongDesc.Name);
		// Collecting all required subsystems.
		For Each RequiredSubsystem In LongDesc.RequiredSubsystems1 Do
			If AllRequiredSubsystems.Get(RequiredSubsystem) = Undefined Then
				AllRequiredSubsystems.Insert(RequiredSubsystem, New Array);
			EndIf;
			AllRequiredSubsystems[RequiredSubsystem].Add(LongDesc.Name);
		EndDo;
	EndDo;
	
	// Verifying the main configuration description.
	If ConfigurationDetailsFound Then
		LongDesc = SubsystemsDetails.ByNames[Metadata.Name];
		
		If LongDesc.Version <> Metadata.Version Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi soạn mô tả phân hệ:
				           |phiên bản ""%2"" cấu hình ""%1"" (xem thủ tục %3%4)
				           |không trùng với phiên bản cấu hình trong metadata ""%5"".';
				           |ru = 'Ошибка при подготовке описаний подсистем:
				           |версия ""%2"" конфигурации ""%1"" (см. процедуру %3%4)
				           |не совпадает с версией конфигурации в метаданных ""%5"".';
				           |en = 'Error when preparing subsystem details:
				           |version ""%2"" of configuration ""%1""(see procedure %3.%4)
				           |does not match the configuration version in the metadata: ""%5"".'; fa = 'Error when preparing subsystem details:
				           |version ""%2"" of configuration ""%1""(see procedure %3.%4)
				           |does not match the configuration version in the metadata: ""%5"".';
				           |it = 'Si è verificato un errore durante la preparazione delle descrizioni dei sottosistemi:
				           |versione ""%2"" della configurazione ""%1"" (vedere la procedura %3%4)
				           |non corrisponde alla versione di configurazione nei metadati ""%5"".';
				           |pl = 'Błąd podczas przygotowania opisów podsystemów:
				           |wersja ""%2"" konfiguracji ""%1"" (patrz procedurę%3%4)
				           |nie pokrywa się z wersją konfiguracji w metadanych ""%5"".';
				           |tr = 'Alt sistem açıklamaları hazırlanırken bir hata oluştu:
				           | ""%1"" konfigürasyonunun""%2"" sürümü (bkz. %3%4 prosedürü), meta veriler ""%5"" içindeki 
				           | konfigürasyon sürümü ile eşleşmiyor.'"),
				LongDesc.Name,
				LongDesc.Version,
				LongDesc.MainServerModule,
				"OnAddSubsystem",
				Metadata.Version);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	ElsIf Metadata.Name = "StandardSubsystemsLibrary" Then
		ErrorText = NStr("vi = 'Tệp cài đặt 1C:Thư viện các phân hệ chuẩn không được dùng để tạo cơ sở thông tin theo mẫu.
			|Trước khi sử dụng, cần tham khảo tài liệu trên ITS (https://its.1c.eu/db/bspdoc)';
			|ru = 'Файл поставки 1С:Библиотека стандартных подсистем не предназначен для создания информационных баз по шаблону. 
			|Перед использованием необходимо ознакомиться с документацией на ИТС (https://its.1c.eu/db/bspdoc)';
			|en = 'The 1C:Standard Subsystems Library distribution file is not intended for template-based infobase creation.
			|Before you start using it, read the documentation available on ITS (http://its.1c.eu/db/bspdoc, in Russian).'; fa = 'The 1C:Standard Subsystems Library distribution file is not intended for template-based infobase creation.
			|Before you start using it, read the documentation available on ITS (http://its.1c.eu/db/bspdoc, in Russian).';
			|it = 'Файл поставки 1С:Библиотека стандартных подсистем не предназначен для создания информационных баз по шаблону. 
			|Перед использованием необходимо ознакомиться с документацией на ИТС (https://its.1c.eu/db/bspdoc)';
			|pl = 'The 1C:Standard Subsystems Library distribution file is not intended for template-based infobase creation.
			|Before you start using it, read the documentation available on ITS (http://its.1c.eu/db/bspdoc, in Russian).';
			|tr = '1C:Standart alt sistemler kitaplığı teslimat dosyası, veri tabanlarını şablondan oluşturmak üzere tasarlanmamıştır.
			|Kullanmadan önce, ITS belgeleri incelenmelidir (https://its.1c.eu/db/bspdoc)'");
		Raise ErrorText;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi khi soạn mô tả phân hệ:
			           |trong mô-đun chung đã chỉ ra trong thủ tục %1,
			           |không tồn tại mô tả phân hệ trùng với tên cấu hình ""%2"".';
			           |ru = 'Ошибка при подготовке описаний подсистем:
			           |в общих модулях, указанных в процедуре %1,
			           |не существует описание подсистемы, совпадающей с именем конфигурации ""%2"".';
			           |en = 'An error occurred when preparing subsystem details:
			           |subsystem details matching configuration name ""%2"" 
			           |do not exist in common modules specified in procedure %1.'; fa = 'An error occurred when preparing subsystem details:
			           |subsystem details matching configuration name ""%2"" 
			           |do not exist in common modules specified in procedure %1.';
			           |it = 'Errore durante la preparazione delle descrizioni dei sottosistemi:
			           | nei moduli comuni indicati nella procedura %1.
			           | non esiste una descrizione del sottosistema che corrisponda al nome della configurazione ""%2"".';
			           |pl = 'Błąd podczas przygotowania opisów podsystemów:
			           |w ogólnych modułach, podanych w procedurze %1,
			           |nie istnieje opisu podsystemu, odpowiadającego nazwie konfiguracji ""%2"".';
			           |tr = 'Alt sistem açıklamalarının hazırlanması sırasında hata oluştu:
			           |%1 prosedüründe belirtilen genel modüllerde,
			           |""%2"" konfigürasyon adı ile uyumlu alt sistem açıklaması bulunamadı.'"),
			"ConfigurationSubsystemsOverridable.OnAddSubsystem", Metadata.Name);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	// Checking whether all required subsystems are presented.
	For Each KeyAndValue In AllRequiredSubsystems Do
		If SubsystemsDetails.ByNames.Get(KeyAndValue.Key) = Undefined Then
			DependentSubsystems = "";
			For Each DependentSubsystem In KeyAndValue.Value Do
				DependentSubsystems = Chars.LF + DependentSubsystem;
			EndDo;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi chuẩn bị mô tả phân hệ:
				           |không tồn tại phân hệ ""%1"" cần thiết đối với phân hệ: %2.';
				           |ru = 'Ошибка при подготовке описаний подсистем:
				           |не существует подсистема ""%1"" требуемая для подсистем: %2.';
				           |en = 'Cannot prepare subsystem descriptions.
				           |Subsystem ""%1"" does not exist. It is required for the following subsystems:%2.'; fa = 'Cannot prepare subsystem descriptions.
				           |Subsystem ""%1"" does not exist. It is required for the following subsystems:%2.';
				           |it = 'Errore durante la preparazione delle descrizioni dei sottosistemi:
				           | non esiste un sottosistema ""%1"" richiesto per i sottosistemi: %2.';
				           |pl = 'Błąd podczas przygotowania opisów podsystemów:
				           |nie istnieje podsystemu ""%1"" wymaganego dla podsystemów: %2.';
				           |tr = 'Alt sistem açıklamaları hazırlanırken bir hata oluştu:
				           |alt sistemler için gerekli ""%1"" alt sistem mevcut değil:%2.'"),
				KeyAndValue.Key,
				DependentSubsystems);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	EndDo;
	
	// Setting up the subsystem order according to dependencies.
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		Name = KeyAndValue.Key;
		Order = SubsystemsDetails.Order.Find(Name);
		For Each RequiredSubsystem In KeyAndValue.Value.RequiredSubsystems1 Do
			RequiredSubsystemOrder = SubsystemsDetails.Order.Find(RequiredSubsystem);
			If Order < RequiredSubsystemOrder Then
				Interdependency = SubsystemsDetails.ByNames[RequiredSubsystem
					].RequiredSubsystems1.Find(Name) <> Undefined;
				If Interdependency Then
					NewOrder = RequiredSubsystemOrder;
				Else
					NewOrder = RequiredSubsystemOrder + 1;
				EndIf;
				If Order <> NewOrder Then
					SubsystemsDetails.Order.Insert(NewOrder, Name);
					SubsystemsDetails.Order.Delete(Order);
					Order = NewOrder - 1;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// Moving the configuration description to the end of the array.
	IndexOf = SubsystemsDetails.Order.Find(Metadata.Name);
	If SubsystemsDetails.Order.Count() > IndexOf + 1 Then
		SubsystemsDetails.Order.Delete(IndexOf);
		SubsystemsDetails.Order.Add(Metadata.Name);
	EndIf;
	
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		KeyAndValue.Value.RequiredSubsystems1 =
			New FixedArray(KeyAndValue.Value.RequiredSubsystems1);
		
		SubsystemsDetails.ByNames[KeyAndValue.Key] =
			New FixedStructure(KeyAndValue.Value);
	EndDo;
	
	Return Common.FixedData(SubsystemsDetails);
	
EndFunction

// Returns True if the privileged mode has been set
// using the UsePrivilegedMode start parameter.
//
// Supported client applications only
// (external connections are not supported).
// 
// Returns:
//  Boolean
// 
Function PrivilegedModeSetOnStart() Export
	
	Return StandardSubsystemsServer.ClientParametersAtServer(False).Get(
		"PrivilegedModeSetOnStart") = True;
	
EndFunction

#Region MetadataObjectsIDsUsageInConfigurationAndExtensions

// For internal use only.
// 
// Returns:
//  Boolean
//
Function DisableMetadataObjectsIDs() Export
	
	CommonParameters = Common.CommonCoreParameters();	
	If Not CommonParameters.DisableMetadataObjectsIDs Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors")
	 Or Common.SubsystemExists("StandardSubsystems.ReportMailing")
	 Or Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể vô hiệu hóa danh mục tên định danh đối tượng metadata,
			           |nếu sử dụng phân hệ bất kỳ sau đây:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';
			           |ru = 'Невозможно отключить справочник идентификаторов объектов метаданных,
			           |если используется любая из следующих подсистем:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';
			           |en = 'Cannot disable the catalog of metadata object IDs
			           |if any of the following subsystems is used:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.'; fa = 'Cannot disable the catalog of metadata object IDs
			           |if any of the following subsystems is used:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';
			           |it = 'Impossibile disattivare la directory degli ID degli oggetti di metadati
			           |se si utilizza uno qualsiasi di questi sottosistemi:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';
			           |pl = 'Nie można wyłączyć katalogu Identyfikatorów obiektów metadanych,
			           |jeśli jest używany którykolwiek z następujących podsystemów:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';
			           |tr = 'Aşağıdaki alt sistemlerden herhangi biri kullanılıyorsa ,
			           |Meta Veri Nesne Tanımlayıcı Dizini devre dışı bırakılamaz:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.'"),
			"ReportsOptions", "AdditionalReportsAndDataProcessors", "ReportMailing", "AccessManagement");
		Raise(ExceptionText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  CheckForUpdates  - Boolean
//  ExtensionsObjects    - Boolean
//
// Returns:
//  Boolean
//
Function MetadataObjectIDsUsageCheck(CheckForUpdates = False, ExtensionsObjects = False) Export
	
	Catalogs.MetadataObjectIDs.CheckForUsage(ExtensionsObjects);
	
	If CheckForUpdates Then
		Catalogs.MetadataObjectIDs.IsDataUpdated(True, ExtensionsObjects);
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region DataExchangeProceduresAndFunctions

// Returns a flag that shows whether the full DIB is used in the infobase (without filters).
// Checking with more accurately algorithm if the "Data exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - clarifies which DIB is checked:
//                                Empty string - any DIB;
//                                WithFilter - DIB with the;
//                                Full filter - DIB without filters.
//
// Returns:
//   Boolean
//
Function DIBUsed(FilterByPurpose = "") Export
	
	Return DIBNodes(FilterByPurpose).Count() > 0;
	
EndFunction

// Returns a list of the DIB nodes used in the infobase (without filters).
// Checking with more accurately algorithm if the "Data exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - specifies the purposes of DIB exchange plan nodes to be returned:
//                                Empty string - all DIB nodes;
//                                WithFilter will be returned - DIB nodes with the;
//                                Full filter will be returned - DIB nodes without filters will be returned.
//
// Returns:
//   ValueList
//
Function DIBNodes(FilterByPurpose = "") Export
	
	FilterByPurpose = Upper(FilterByPurpose);
	
	NodesList = New ValueList;
	
	DIBExchangePlans = DIBExchangePlans();
	Query = New Query();
	For Each ExchangePlanName In DIBExchangePlans Do
		
		If ValueIsFilled(FilterByPurpose)
			And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			DIBPurpose = Upper(ModuleDataExchangeServer.ExchangePlanPurpose(ExchangePlanName));
			
			If FilterByPurpose = "WITHFILTER" And DIBPurpose <> "DIBWITHFILTER"
				Or FilterByPurpose = "FULL" And DIBPurpose <> "DIB" Then
				Continue;
			EndIf;
		EndIf;
		
		Query.Text =
		"SELECT
		|	ExchangePlan.Ref AS Ref
		|FROM
		|	&ExchangePlanName AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		Query.Text = StrReplace(Query.Text, "&ExchangePlanName", "ExchangePlan" + "." + ExchangePlanName);
		// @skip-check query-in-loop - selection of links from different tables.
		NodesSelection = Query.Execute().Select();
		While NodesSelection.Next() Do
			NodesList.Add(NodesSelection.Ref);
		EndDo;
	EndDo;
	
	Return NodesList;
	
EndFunction

// Returns a list of DIB exchange plans.
// For SaaS mode,
// returns the list of a separated DIB exchange plans.
// 
// Returns:
//  Array of String
// 
Function DIBExchangePlans() Export
	
	Result = New Array;
	
	If Common.DataSeparationEnabled() Then
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If StrStartsWith(ExchangePlan.Name, "Delete") Then
				Continue;
			EndIf;
			
			If Common.SubsystemExists("CloudTechnology.Core") Then
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				IsSeparatedData = ModuleSaaSOperations.IsSeparatedMetadataObject(
					ExchangePlan.FullName(), ModuleSaaSOperations.MainDataSeparator());
			Else
				IsSeparatedData = False;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase
				And IsSeparatedData Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If StrStartsWith(ExchangePlan.Name, "Delete") Then
				Continue;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Determines the data registration mode on exchange plan nodes.
// 
// Parameters:
//  FullObjectName - String - the full name of a metadata object to check.
//  ExchangePlanName - String - exchange plan to check.
//
// Returns:
//  Undefined - Object not included in the exchange plan,
//  "AutoRecordEnabled" - Object included in the exchange plan, autoregistration enabled,
//  "AutoRecordDisabled" - Object included in the exchange plan, autoregistration disabled,
//                               object processed during the creation of the initial DIB image.
//  "ProgramRegistration" - Object included in the exchange plan, autoregistration disabled,
//                               object registered programmatically using event subscriptions,
//                               object processed during the creation of the initial DIB image.
//
Function ExchangePlanDataRegistrationMode(FullObjectName, ExchangePlanName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(MetadataObject);
	If ExchangePlanContentItem = Undefined Then
		Return Undefined;
	ElsIf ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Allow Then
		Return "AutoRecordEnabled";
	EndIf;
	
	// Analyze event subscriptions for more complex use cases when
	// the 1C:Enterprise auto-registration is disabled for the metadata object.
	For Each Subscription In Metadata.EventSubscriptions Do
		SubscriptionTitleBeginning = ExchangePlanName + "Registration";
		If Upper(Left(Subscription.Name, StrLen(SubscriptionTitleBeginning))) = Upper(SubscriptionTitleBeginning) Then
			For Each Type In Subscription.Source.Types() Do
				If MetadataObject = Metadata.FindByType(Type) Then
					Return "ProgramRegistration";
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return "AutoRecordDisabled";
	
EndFunction

#EndRegion

#Region Other

// Metadata object availability by functional options.
// 
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Function ObjectsEnabledByOption() Export
	
	Parameters = New Structure(StandardSubsystemsCached.InterfaceOptions());
	
	ObjectsEnabled = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		Value = -1;
		For Each Item In FunctionalOption.Content Do
			If Item.Object = Undefined Then
				Continue;
			EndIf;
			If Value = -1 Then
				Value = GetFunctionalOption(FunctionalOption.Name, Parameters);
			EndIf;
			FullName = Item.Object.FullName();
			If Value = True Then
				ObjectsEnabled.Insert(FullName, True);
			Else
				If ObjectsEnabled[FullName] = Undefined Then
					ObjectsEnabled.Insert(FullName, False);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	Return New FixedMap(ObjectsEnabled);
	
EndFunction

// The latest version of the template add-in.
// 
// Parameters:
//  Location - String - full name of the metadata template
// 
// Returns:
//  FixedStructure - Latest version of the template add-in:
//   * Version - String
//   * Location - String
//
Function TheLatestVersionOfComponentsFromTheLayout(Location) Export
	
	LayoutLocationSplit = StrSplit(Location, ".");
	TheBeginningOfTheLayoutName = LayoutLocationSplit.Get(LayoutLocationSplit.UBound());
	
	If LayoutLocationSplit.Count() = 2 Then
		PathToLayouts = Metadata.CommonTemplates;
	Else
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		MetadataByFullName = Metadata.FindByFullName(StrConcat(LayoutLocationSplit, "."));
		
		If MetadataByFullName = Undefined Then 
			Parameters = New Structure;
			Parameters.Insert("Version", "0.0.0.0");
			Parameters.Insert("Location", Location);
			Return New FixedStructure(Parameters);
		EndIf;
		
		PathToLayouts = MetadataByFullName.Templates;
	EndIf;
	
	VersionTable = New ValueTable;
	VersionTable.Columns.Add("FullTemplateName");
	VersionTable.Columns.Add("Version");
	VersionTable.Columns.Add("ExtendedVersion", Common.StringTypeDetails(23));
	
	For Each Template In PathToLayouts Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.AddIn
			And Template.TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData Then
			Continue;
		EndIf;
		
		TemplateName = Template.Name;
				
		If StrStartsWith(Upper(TemplateName), Upper(TheBeginningOfTheLayoutName)) Then
			
			If Upper(TemplateName) = Upper(TheBeginningOfTheLayoutName) Then
				VersionTableRow = VersionTable.Add();
				VersionTableRow.FullTemplateName = Template.FullName();
				VersionTableRow.ExtendedVersion = "00000_00000_00000_00000";
				VersionTableRow.Version = "0.0.0.0";
			Else
				If Mid(TemplateName, StrLen(TheBeginningOfTheLayoutName) + 1, 1) <> "_" Then
					Continue;
				EndIf;
				
				Version = Mid(TemplateName, StrLen(TheBeginningOfTheLayoutName) + 1);
				VersionParts = StrSplit(Version, "_", False);
				If VersionParts.Count() <> 4 Then
					Continue;
				EndIf;
				
				ExtendedPartsOfTheVersion = New Array;
				For Each VersionPart In VersionParts Do
					ExtendedPartsOfTheVersion.Add(Upper(Right("0000" + VersionPart, 5)));
				EndDo;
				VersionTableRow = VersionTable.Add();
				VersionTableRow.FullTemplateName = Template.FullName();
				VersionTableRow.ExtendedVersion = StrConcat(ExtendedPartsOfTheVersion, "_");
				VersionTableRow.Version = StrConcat(VersionParts, ".");
			EndIf;
			
		EndIf;
	EndDo;
	
	If VersionTable.Count() = 0 Then
		
		Parameters = New Structure;
		Parameters.Insert("Version", "0.0.0.0");
		Parameters.Insert("Location", Location);
		
		Return New FixedStructure(Parameters);
		
	EndIf;
	
	VersionTable.Sort("ExtendedVersion Desc");
	
	Parameters = New Structure;
	Parameters.Insert("Version", VersionTable[0].Version);
	Parameters.Insert("Location", VersionTable[0].FullTemplateName);

	Return New FixedStructure(Parameters);
	
EndFunction

// See Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties
Function MetadataObjectCollectionProperties(ExtensionsObjects = False) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties(ExtensionsObjects);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function IsSeparatedModeWithoutDataAreaExtensions() Export
	
	ThisIsSplitSessionModeWithNoDelimiters = StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters();
	
	If Not ThisIsSplitSessionModeWithNoDelimiters Then
		Return False;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If BackgroundJob <> Undefined
	   And BackgroundJob.DataSeparation.Count() > 0 Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Caches the common operating parameters between server calls.
//
// Returns:
//   See CommonOverridable.OnDetermineCommonCoreParameters.CommonParameters
//
Function CommonCoreParameters() Export
	
	Return Common.CommonCoreParameters(False);

EndFunction

// Parameters applied to command interface items associated with parametric functional options.
// 
// Returns:
//  FixedStructure:
//   * Key - String
//   * Value - Arbitrary
//
Function InterfaceOptions() Export 
	
	InterfaceOptions = New Structure;
	CommonOverridable.OnDetermineInterfaceFunctionalOptionsParameters(InterfaceOptions);
	Return New FixedStructure(InterfaceOptions);
	
EndFunction

// Returns a map of the "functional" subsystem names and the True value.
// A subsystem is considered functional if its "Include in command interface" check box is cleared.
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Function SubsystemsNames() Export
	
	DisabledSubsystems = New Map;
	CommonOverridable.OnDetermineDisabledSubsystems(DisabledSubsystems);
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata, DisabledSubsystems);
	
	Return New FixedMap(Names);
	
EndFunction

Function AllRefsTypeDetails() Export
	
	Return New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
		New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
			Catalogs.AllRefsType(),
			Documents.AllRefsType().Types()),
			ExchangePlans.AllRefsType().Types()),
			Enums.AllRefsType().Types()),
			ChartsOfCharacteristicTypes.AllRefsType().Types()),
			ChartsOfAccounts.AllRefsType().Types()),
			ChartsOfCalculationTypes.AllRefsType().Types()),
			BusinessProcesses.AllRefsType().Types()),
			BusinessProcesses.RoutePointsAllRefsType().Types()),
			Tasks.AllRefsType().Types());
	
EndFunction

Function IsLongRunningOperationSession() Export
	
	ParentSessionKey = StandardSubsystemsServer.ClientParametersAtServer(False).Get("ParentSessionKey");
	
	Return ValueIsFilled(ParentSessionKey);
	
EndFunction

Function FileInfobase() Export
	
	InfoBaseConnectionString = InfoBaseConnectionString();
	
	Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction 


Function DataSeparationEnabled() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.DataSeparationEnabled();
	Else
		Return False;
	EndIf;
	
EndFunction

Function SeparatedDataUsageAvailable() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.SeparatedDataUsageAvailable();
	Else
		Return True;
	EndIf;
	
EndFunction

Function CollectionNamesByBaseTypeNames() Export
	
	CollectionsNames = New Map;
	CollectionsNames.Insert(Upper("Subsystem"), "Subsystems");
	CollectionsNames.Insert(Upper("CommonModule"), "CommonModules");
	CollectionsNames.Insert(Upper("SessionParameter"), "SessionParameters");
	CollectionsNames.Insert(Upper("Role"), "Roles");
	CollectionsNames.Insert(Upper("CommonAttribute"), "CommonAttributes");
	CollectionsNames.Insert(Upper("ExchangePlan"), "ExchangePlans");
	CollectionsNames.Insert(Upper("FilterCriterion"), "FilterCriteria");
	CollectionsNames.Insert(Upper("EventSubscription"), "EventSubscriptions");
	CollectionsNames.Insert(Upper("ScheduledJob"), "ScheduledJobs");
	CollectionsNames.Insert(Upper("FunctionalOption"), "FunctionalOptions");
	CollectionsNames.Insert(Upper("FunctionalOptionsParameter"), "FunctionalOptionsParameters");
	CollectionsNames.Insert(Upper("DefinedType"), "DefinedTypes");
	CollectionsNames.Insert(Upper("SettingsStorage"), "SettingsStorages");
	CollectionsNames.Insert(Upper("CommonForm"), "CommonForms");
	CollectionsNames.Insert(Upper("CommonCommand"), "CommonCommands");
	CollectionsNames.Insert(Upper("CommandGroup"), "CommandGroups");
	CollectionsNames.Insert(Upper("CommonTemplate"), "CommonTemplates");
	CollectionsNames.Insert(Upper("CommonPicture"), "CommonPictures");
	CollectionsNames.Insert(Upper("XDTOPackage"), "XDTOPackages");
	CollectionsNames.Insert(Upper("WebService"), "WebServices");
	CollectionsNames.Insert(Upper("HTTPService"), "HTTPServices");
	CollectionsNames.Insert(Upper("WSReference"), "WSReferences");
	CollectionsNames.Insert(Upper("IntegrationService"), "IntegrationServices");
	CollectionsNames.Insert(Upper("StyleItem"), "StyleItems");
	CollectionsNames.Insert(Upper("Style"), "Styles");
	CollectionsNames.Insert(Upper("Language"), "Languages");
	CollectionsNames.Insert(Upper("Constant"), "Constants");
	CollectionsNames.Insert(Upper("Catalog"), "Catalogs");
	CollectionsNames.Insert(Upper("Document"), "Documents");
	CollectionsNames.Insert(Upper("Sequence"), "Sequences");
	CollectionsNames.Insert(Upper("DocumentJournal"), "DocumentJournals");
	CollectionsNames.Insert(Upper("Enum"), "Enums");
	CollectionsNames.Insert(Upper("Report"), "Reports");
	CollectionsNames.Insert(Upper("DataProcessor"), "DataProcessors");
	CollectionsNames.Insert(Upper("ChartOfCharacteristicTypes"), "ChartsOfCharacteristicTypes");
	CollectionsNames.Insert(Upper("ChartOfAccounts"), "ChartsOfAccounts");
	CollectionsNames.Insert(Upper("ChartOfCalculationTypes"), "ChartsOfCalculationTypes");
	CollectionsNames.Insert(Upper("InformationRegister"), "InformationRegisters");
	CollectionsNames.Insert(Upper("AccumulationRegister"), "AccumulationRegisters");
	CollectionsNames.Insert(Upper("AccountingRegister"), "AccountingRegisters");
	CollectionsNames.Insert(Upper("CalculationRegister"), "CalculationRegisters");
	CollectionsNames.Insert(Upper("BusinessProcess"), "BusinessProcesses");
	CollectionsNames.Insert(Upper("Task"), "Tasks");
	CollectionsNames.Insert(Upper("ExternalDataSources"), "ExternalDataSource");
	
	Return New FixedMap(CollectionsNames);
	
EndFunction

// Returns:
//  Structure:
//   * SessionNumber - Number
//   * SessionStarted - Date
//   * ComputerKey - String
//
Function CurrentSessionProperties() Export
	
	Session = GetCurrentInfoBaseSession();
	Hashing = New DataHashing(HashFunction.SHA256);
	Hashing.Append(Session.ComputerName);
	StringHashSum = Base64String(Hashing.HashSum);
	
	Result = New Structure;
	Result.Insert("SessionNumber",    Session.SessionNumber);
	Result.Insert("SessionStarted",   Session.SessionStarted);
	Result.Insert("ComputerKey", StringHashSum);
	
	Return Result;
	
EndFunction

// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - Name of the predefined shared scheduled job that is used
//                      as a templated for the job queue.
//    * Value - Boolean - the True value.
//  
Function QueueJobTemplates() Export
	
	Templates = New Map;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		QueueJobTemplates = ModuleJobsQueue.QueueJobTemplates();
		For Each Template In QueueJobTemplates Do
			Templates.Insert(Template, True);
		EndDo;
	EndIf;
	
	Return New FixedMap(Templates);
	
EndFunction

// See StandardSubsystemsServer.RecordKeyDetails
Function RecordKeyDetails(FullRegisterName) Export
	
	Manager = Common.ObjectManagerByFullName(FullRegisterName);
	
	AllFields = New Array;
	RecordSet = Manager.CreateRecordSet();
	Columns = RecordSet.Unload().Columns;
	For Each Column In Columns Do
		AllFields.Add(Column.Name);
	EndDo;
	
	KeyFields = New Array;
	FieldsOfUpdate = New Array;
	FieldsDetails = New Array;
	DetailsOfUpdateFields = New Array;
	
	AllFieldsList = StrConcat(AllFields, ",");
	EmptyRecordKey = Manager.CreateRecordKey(New Structure(AllFieldsList));
	RegisterMetadata = RecordSet.Metadata();
	IsInformationRegisterWithRecorder = Common.IsInformationRegister(RegisterMetadata)
		And RegisterMetadata.WriteMode
			= Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate;
	
	For Each Column In Columns Do
		Field = Column.Name;
		OneField = New Structure(Field, Null);
		FillPropertyValues(OneField, EmptyRecordKey);
		If OneField[Field] = Null And Field <> "LineNumber" Then
			Continue;
		EndIf;
		IsSeparator = False;
		FieldPresentation = RegisterFieldPresentation(RegisterMetadata, Field, IsSeparator);
		FieldDetails = New FixedStructure(New Structure("Name, Type, Presentation",
			Field, Column.ValueType, FieldPresentation));
		If OneField[Field] <> Null Then
			KeyFields.Add(Field);
			FieldsDetails.Add(FieldDetails);
		EndIf;
		If Not IsInformationRegisterWithRecorder
		 Or Not IsSeparator
		   And Field <> "Recorder"
		   And Field <> "LineNumber" Then
			Continue;
		EndIf;
		FieldsOfUpdate.Add(Field);
		DetailsOfUpdateFields.Add(FieldDetails);
	EndDo;
	
	If Not IsInformationRegisterWithRecorder Then
		FieldsOfUpdate = KeyFields;
		DetailsOfUpdateFields = FieldsDetails;
	EndIf;
	
	KeyDetails = New Structure;
	KeyDetails.Insert("FieldsDetails", New FixedArray(FieldsDetails));
	KeyDetails.Insert("FieldList",   StrConcat(KeyFields, ","));
	KeyDetails.Insert("DetailsOfUpdateFields", New FixedArray(DetailsOfUpdateFields));
	KeyDetails.Insert("ListOfUpdateFields",   StrConcat(FieldsOfUpdate, ","));
	
	Return New FixedStructure(KeyDetails);
	
EndFunction

// Intended for function "RecordKeyDetails".
Function RegisterFieldPresentation(RegisterMetadata, Field, IsSeparator)
	
	FieldMetadata = RegisterMetadata.Dimensions.Find(Field);
	If FieldMetadata = Undefined Then
		FieldMetadata = RegisterMetadata.Resources.Find(Field);
		If FieldMetadata = Undefined Then
			FieldMetadata = RegisterMetadata.Attributes.Find(Field);
			If FieldMetadata = Undefined Then
				For Each StandardAttribute In RegisterMetadata.StandardAttributes Do
					If StandardAttribute.Name <> Field Then
						Continue;
					EndIf;
					FieldMetadata = StandardAttribute;
				EndDo;
				If FieldMetadata = Undefined Then
					SeparationDontUse = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse;
					For Each CommonAttribute In Metadata.CommonAttributes Do
						If CommonAttribute.DataSeparation = SeparationDontUse
						 Or CommonAttribute.Name <> Field Then
						 	Continue;
						EndIf;
						FieldMetadata = CommonAttribute;
						IsSeparator = True;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return FieldMetadata.Presentation();
	
EndFunction

Function RecordSetAdditionMode() Export
	
	If Not AreReplacementModesAvailable() Then
		Return Undefined;
	EndIf;
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise types (the executable code is safe)
	Return Eval("ReplacementMode.Append");
	// ACC:488-on
	
EndFunction

Function RecordSetReplacementMode() Export
	
	If Not AreReplacementModesAvailable() Then
		Return Undefined;
	EndIf;
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise types (the executable code is safe)
	Return Eval("ReplacementMode.Replace");
	// ACC:488-on
	
EndFunction

Function RecordSetUpdateMode() Export
	
	If Not AreReplacementModesAvailable(True) Then
		Return Undefined;
	EndIf;
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise types (the executable code is safe)
	Return Eval("ReplacementMode.Update");
	// ACC:488-on
	
EndFunction

Function RecordSetMergeMode() Export
	
	If Not AreReplacementModesAvailable() Then
		Return Undefined;
	EndIf;
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise types (the executable code is safe)
	Return Eval("ReplacementMode.Merge");
	// ACC:488-on
	
EndFunction

Function RecordSetDeletionMode() Export
	
	If Not AreReplacementModesAvailable() Then
		Return Undefined;
	EndIf;
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise types (the executable code is safe)
	Return Eval("ReplacementMode.Delete");
	// ACC:488-on
	
EndFunction

Function AreReplacementModesAvailable(IsIncludingUpdate = False)
	
	SystemInfo = New SystemInfo;
	Version = SystemInfo.AppVersion;
	
	If CommonClientServer.CompareVersions(Version, "8.3.26.1398") < 0 Then
		Return False;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	If CommonClientServer.CompareVersions(Version, "8.3.27.1719") < 0
	 Or CommonClientServer.CompareVersions(Version, "8.5.1.0") > 0
	   And CommonClientServer.CompareVersions(Version, "8.5.1.980") < 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function TypeSubstitutionMode() Export
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise methods (the executable code is safe)
	Return Eval("Type(""ReplacementMode"")");
	// ACC:488-on
	
EndFunction

#Region ForMetadataObjectIDsCatalog

// See Catalogs.MetadataObjectIDs.MetadataObjectIDCache
Function MetadataObjectIDCache(CachedDataKey) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectIDCache(
		CachedDataKey);
	
EndFunction

// See Catalogs.MetadataObjectIDs.RenamingTableForCurrentVersion
Function RenamingTableForCurrentVersion() Export
	
	Return Catalogs.MetadataObjectIDs.RenamingTableForCurrentVersion();
	
EndFunction

// See Catalogs.MetadataObjectIDs.IDPresentation
Function MetadataObjectIDPresentation(Ref) Export
	
	Return Catalogs.MetadataObjectIDs.IDPresentation(Ref);
	
EndFunction

// See Catalogs.MetadataObjectIDs.RolesByKeysMetadataObjects
Function RolesByKeysMetadataObjects() Export
	
	Return Catalogs.MetadataObjectIDs.RolesByKeysMetadataObjects();
	
EndFunction

#EndRegion

#Region PredefinedDataManagement

// Returns the map of predefined value names and their references.
//
// Parameters:
//  FullMetadataObjectName - String - For example, "Catalog.ProductAndServiceTypes".
//                               Only tables
//                               with the following predefined items are supported:
//                               > Catalogs,
//                               > Charts of characteristic types,
//                               > Charts of accounts,
//                               > Charts of calculation types.
//
// Returns:
//  FixedMap of KeyAndValue:
//      * Key     - String - a name of the predefined item,
//      * Value - CatalogRef
//                 - ChartOfCharacteristicTypesRef
//                 - ChartOfAccountsRef
//                 - ChartOfCalculationTypesRef
//                 - Null - a reference of the redefined item or Null if the object is not in infobase.
//
//  If there is an error in the metadata name or an inappropriate metadata type, Undefined is returned.
//  If metadata has no predefined items, empty fixed map is returned.
//  If the predefined item is defined in metadata, but it is not created in infobase, Null is returned for it in the map.
//
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	PredefinedValues = New Map;
	
	ObjectMetadata = Common.MetadataObjectByFullName(FullMetadataObjectName);
	
	// If metadata does not exist.
	If ObjectMetadata = Undefined Then 
		Return Undefined;
	EndIf;
	
	// If inappropriate type of metadata.
	If Not Metadata.Catalogs.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfAccounts.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then 
		
		Return Undefined;
	EndIf;
	
	PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
	
	// If metadata has no predefined items.
	If PredefinedItemsNames.Count() = 0 Then 
		Return New FixedMap(PredefinedValues);
	EndIf;
	
	// Default filling by the absence flag in the infobase (the present ones will be redefined).
	For Each PredefinedItemName In PredefinedItemsNames Do 
		PredefinedValues.Insert(PredefinedItemName, Null);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref,
		|	CurrentTable.PredefinedDataName AS PredefinedDataName
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", FullMetadataObjectName);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	// Filling the present items in the infobase.
	While Selection.Next() Do
		PredefinedValues.Insert(Selection.PredefinedDataName, Selection.Ref);
	EndDo;
	
	Return New FixedMap(PredefinedValues);
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Returns:
//   Structure:
//   * ParallelDeferredUpdateFromVersion - String
//   * DeferredHandlersExecutionMode - String
//   * MainServerModule - String
//   * IsConfiguration - Boolean
//   * OnlineSupportID - String
//   * RequiredSubsystems1 - Array
//   * Version - String
//   * Name - String
//   * FillDataNewSubsystemsWhenSwitchingFromAnotherProgram - Boolean
//
Function NewSubsystemDescription() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Name",    "");
	LongDesc.Insert("Version", "");
	LongDesc.Insert("RequiredSubsystems1", New Array);
	LongDesc.Insert("OnlineSupportID", "");
	
	// The property is set automatically.
	LongDesc.Insert("IsConfiguration", False);
	
	// The name of the library's main module.
	// Can be empty for applied configurations.
	LongDesc.Insert("MainServerModule", "");
	
	// The operation mode for deferred update handlers.
	// By default, "Sequentially".
	LongDesc.Insert("DeferredHandlersExecutionMode", "Sequentially");
	LongDesc.Insert("ParallelDeferredUpdateFromVersion", "");
	
	// The operation mode for initial population handlers when migrating from another app.
	// 
	LongDesc.Insert("FillDataNewSubsystemsWhenSwitchingFromAnotherProgram", False);
	
	Return LongDesc;
	
EndFunction

Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, DisabledSubsystems, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		If DisabledSubsystems.Get(CurrentSubsystemName) = True Then
			Continue;
		Else
			Names.Insert(CurrentSubsystemName, True);
		EndIf;
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, DisabledSubsystems, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

#EndRegion

// Parameters:
//  ModuleName - String
//
// Returns:
//  FixedMap, Undefined
//
Function MethodsAllowedForCallAsArbitraryCode(ModuleName) Export
	
	Module = Common.CommonModule(ModuleName);
	
	Return StandardSubsystemsServer.MethodsAllowedForCallAsArbitraryCode(Module);
	
EndFunction

#EndRegion