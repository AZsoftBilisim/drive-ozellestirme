///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// 1C-supplied add-ins.
// 
// Returns:
//  Array - IDs of 1C-supplied add-ins
//
Function SuppliedAddIns() Export

	UsedAddIns = UsedAddIns();
	Return UsedAddIns.UnloadColumn("Id");
		
EndFunction

// Add-in presentation for the event log
//
Function AddInPresentation(Id, Version) Export

	If ValueIsFilled(Version) Then
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (phiên bản %2)';
				|ru = '%1 (версии %2)';
				|en = '%1(version %2)'; fa = '%1(version %2)';
				|it = '%1 (versione %2)';
				|pl = '%1 (wersji %2)';
				|tr = '%1 (sürüm %2)'"), Id, Version);
	Else
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (phiên bản gần nhất)';
				|ru = '%1 (последней версии)';
				|en = '%1 (latest version)'; fa = '%1 (latest version)';
				|it = '%1(ultima versione)';
				|pl = '%1 (ostatniej wersji)';
				|tr = '%1 (son versiyon)'"), Id);
	EndIf;

	Return AddInPresentation;

EndFunction

// Checks whether the add-ins import from the portal is allowed.
//
// Returns:
//  Boolean
//
Function CanImportFromPortal() Export

	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		Return ModuleGetAddIns.LoadingExternalComponentsIsAvailable();
	EndIf;

	Return False;

EndFunction

// Returns information about an add-in from its file.
//
// Parameters:
//  BinaryData - BinaryData - add-in binary data.
//  ParseInfoFile - Boolean - whether INFO.XML file data is required
//          to analyze additionally.
//  AdditionalInformationSearchParameters - See AddInsClient.ImportParameters.
//
// Returns:
//  Structure:
//      * Disassembled - Boolean - True if information about an add-in is successfully extracted.
//      * Attributes - See AddInAttributes
//      * BinaryData - BinaryData - add-in file export.
//      * AdditionalInformation - Map - information received by passed search parameters.
//      * ErrorDescription - String - an error text if Disassembled = False.
//      * ErrorInfo - ErrorInfo, Undefined - In case of exception if Disassembled = False.
//      * IsFileOfService - Boolean - Flag indicating whether the add-in file was downloaded from the 1C:ITS Portal interactively.
//
Function InformationOnAddInFromFile(BinaryData, ParseInfoFile = True,
	Val AdditionalInformationSearchParameters = Undefined) Export

	Result = New Structure;
	Result.Insert("Disassembled", False);
	Result.Insert("Attributes", New Structure);
	Result.Insert("BinaryData", Undefined);
	Result.Insert("AdditionalInformation", New Map);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("IsFileOfService", False);
	
	Attributes = AddInAttributes();
	If AdditionalInformationSearchParameters = Undefined Then
		AdditionalInformationSearchParameters = New Map;
	EndIf;
	AdditionalInformation = New Map;
	ManifestIsFound = False;

	Try
		Stream = BinaryData.OpenStreamForRead();
		ReadingArchive = New ZipFileReader(Stream);
	Except
		Result.ErrorDescription = NStr("vi = 'Trong tệp thiếu thông tin về thành phần.';
										|ru = 'В файле отсутствует информация о компоненте.';
										|en = 'Add-in information is missing in the file.'; fa = 'Add-in information is missing in the file.';
										|it = 'Nel file mancano informazioni circa il componente.';
										|pl = 'Brak informacji o komponencie w pliku.';
										|tr = 'Dosyada bileşenin bilgisi mevcut değil.'");
		Return Result;
	EndTry;

	TempDirectory = FileSystem.CreateTemporaryDirectory("ExtComp");
	For Each ArchiveItem In ReadingArchive.Items Do

		If ArchiveItem.Encrypted Then

			// Clear temporary files and memory.
			FileSystem.DeleteTemporaryDirectory(TempDirectory);
			ReadingArchive.Close();
			Stream.Close();

			Result.ErrorDescription = NStr("vi = 'ZIP-kho lưu trữ không được mã hóa.';
											|ru = 'ZIP-архив не должен быть зашифрован.';
											|en = 'ZIP archive must not be encrypted.'; fa = 'ZIP archive must not be encrypted.';
											|it = 'L''archivio ZIP non deve essere crttografato.';
											|pl = 'Archiwum ZIP nie powinien być zaszyfrowany.';
											|tr = 'ZIP-arşivi şifrelenmemelidir.'");
			Return Result;

		EndIf;

		Try
			
			OriginalFullName = Lower(ArchiveItem.OriginalFullName);

			If OriginalFullName = "external-components.json" Then
				Result.IsFileOfService = True;
				Result.ErrorDescription = NStr("vi = 'Đây là tệp để kết nhập cấu phần từ Cổng 1C:ITS.';
												|ru = 'Это файл для загрузки компонент с Портала 1С:ИТС.';
												|en = 'This is a file to import add-ins from 1C:ITS Portal.'; fa = 'This is a file to import add-ins from 1C:ITS Portal.';
												|it = 'Это файл для загрузки компонент с Портала 1С:ИТС.';
												|pl = 'This is a file to import add-ins from 1C:ITS Portal.';
												|tr = 'Bu, 1C:ITS Portalından bileşenlerin yüklenmesine yönelik bir dosyadır.'");
				Return Result;
			EndIf;
			
			// Manifest search and parsing.
			If OriginalFullName = "manifest.xml" Then

				Attributes.VersionDate = ArchiveItem.Modified;

				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				ManifestXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				FillAttributesByManifestXML(ManifestXMLFile, Attributes.TargetPlatforms);

				ManifestIsFound = True;

			EndIf;

			If OriginalFullName = "info.xml" And ParseInfoFile Then

				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				InfoXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				FillAttributesByInfoXML(InfoXMLFile, Attributes);

			EndIf;

			For Each SearchParameter In AdditionalInformationSearchParameters Do

				XMLFileName = SearchParameter.Value.XMLFileName;

				If OriginalFullName = Lower(XMLFileName) Then

					AdditionalInformationKey = SearchParameter.Key;
					XPathExpression = SearchParameter.Value.XPathExpression;

					ReadingArchive.Extract(ArchiveItem, TempDirectory);
					ManifestXMLFile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;

					DOMDocument = DOMDocument(ManifestXMLFile);
					XPathValue = EvaluateXPathExpression(XPathExpression, DOMDocument);

					AdditionalInformation.Insert(AdditionalInformationKey, XPathValue);

				EndIf;

			EndDo;

		Except
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tệp %1';
					|ru = 'Некорректный файл %1';
					|en = 'Incorrect file %1'; fa = 'Incorrect file %1';
					|it = 'Некорректный файл %1';
					|pl = 'Incorrect file %1';
					|tr = 'Geçersiz %1 dosyası'"), ArchiveItem.OriginalFullName);
			Result.ErrorInfo = ErrorInfo();
			Return Result;
		EndTry;
	EndDo;

	// Clear temporary files and memory.
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	ReadingArchive.Close();
	Stream.Close();

	// Add-in compatibility control.
	If Not ManifestIsFound Then
		ErrorText = NStr("vi = 'Trong phần lưu trữ của cấu phần thiết tệp bắt buộc MANIFEST.XML.';
						|ru = 'В архиве компоненты отсутствует обязательный файл MANIFEST.XML.';
						|en = 'The required file MANIFEST.XML is missing from the archive.'; fa = 'The required file MANIFEST.XML is missing from the archive.';
						|it = 'Nell''archivio del componente manca il file obbligatorio MANIFEST.XML.';
						|pl = 'Brak obowiązkowego pliku MANIFEST.XML w archiwum komponentu.';
						|tr = 'Bileşenler arşivinde MANIFEST.XML zorunlu dosyası bulunmuyor.'");

		Result.ErrorDescription = ErrorText;
		Return Result;
	EndIf;

	Result.Disassembled = True;
	Result.Attributes = Attributes;
	Result.BinaryData = BinaryData;
	Result.AdditionalInformation = AdditionalInformation;

	Return Result;

EndFunction

Procedure CheckTheLocationOfTheComponent(Id, Location) Export

	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		If ModuleAddInsSaaSInternal.IsComponentFromStorage(Location) Then
			Return;
		EndIf;
	EndIf;

	// In the SaaS mode, it's unsafe to attach add-ins on the 1C:Enterprise server from the "Add-ins" catalog. 
	// It's acceptable to attach add-ins only from the "Common add-ins" catalog.
	If Not (Common.DataSeparationEnabled()
			And Common.SeparatedDataUsageAvailable()) Then
		If Not StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
			If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể kết nối cấu phần ""%1"" do nguyên nhân:
					|Cấm truy cập. Hãy liên hệ với người quản trị dịch vụ để chuyển cấu phần ngoài vào danh mục ""Cấu phần ngoài chung"".';
					|ru = 'Не удалось подключить компоненту ""%1"" по причине:
					|Доступ запрещен. Обратитесь к администратору сервиса, чтобы разместить внешнюю компоненту в справочник ""Общие внешние компоненты"".';
					|en = 'Cannot attach the %1 add-in due to:
					|Access forbidden. Contact the service administrator to place the add-in in the ""Common add-ins"" catalog.'; fa = 'Cannot attach the %1 add-in due to:
					|Access forbidden. Contact the service administrator to place the add-in in the ""Common add-ins"" catalog.';
					|it = 'Impossibile connettere la componente ""%1"" a causa di:
					|Accesso non consentito. Rivolgersi all''amministratore di servizio per spostare la componente esterna nella directory ""Componenti esterne generali"".';
					|pl = 'Nie udało się podłączyć komponentu ""%1"" z powodu:
					|Dostęp jest zabroniony. Zwróć się do administratora usługi, aby rozmieścić komponent zewnętrzny komponent w katalogu ""Wspólne komponenty zewnętrzne"".';
					|tr = '""%1"" bileşeni şu sebeple bağlanamadı:
					|Erişim yasak. Harici bileşeni ""Ortak harici bileşenler"" kataloğuna konumlandırmak için hizmetin yöneticisine başvurun.'"), 
					Id);
			Else
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể kết nối cấu phần ""%1"" do nguyên nhân:
					|Cấm truy cập.';
					|ru = 'Не удалось подключить компоненту ""%1"" по причине:
					|Доступ запрещен.';
					|en = 'Cannot attach the %1 add-in due to:
					|Access forbidden.'; fa = 'Cannot attach the %1 add-in due to:
					|Access forbidden.';
					|it = 'Impossibile connettere la componente ""%1"" a causa di:
					|Accesso non consentito.';
					|pl = 'Nie udało się podłączyć komponentu ""%1"" z powodu:
					|Dostęp jest zabroniony.';
					|tr = '""%1"" bileşeni şu sebeple bağlanamadı:
					|Erişim yasak.'"), 
					Id);
				EndIf;
			Raise ExceptionText;
		EndIf;
	EndIf;

	If StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
		Return;
	EndIf;

	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể kết nối cấu phần ""%1"" do nguyên nhân:
		|Vị trí cấu phần không hợp lệ ""%2"".';
		|ru = 'Не удалось подключить компоненту ""%1"" по причине:
		|Недопустимое местоположение компоненты ""%2"".';
		|en = 'Cannot attach the %1 add-in due to:
		|Invalid %2 add-in location.'; fa = 'Cannot attach the %1 add-in due to:
		|Invalid %2 add-in location.';
		|it = 'Impossibile connettere la componente ""%1"" a causa di:
		|Posizione non accessibile della componente ""%2"".';
		|pl = 'Nie udało się podłączyć komponentu ""%1"" z powodu:
		|Niedopuszczalna lokacja komponentu ""%2"".';
		|tr = '""%1"" bileşeni şu sebeple bağlanamadı:
		| ""%2"" bileşeninin geçersiz konumu.'"), 
		Id, Location);

EndProcedure

Function TemplateAddInCompatibilityError(Location) Export
	
	AddInInfo = TemplateAddInInfo(Location);
		 
	If AddInInfo <> Undefined 
		And Not OperatingSystemSupportedByAddInn(AddInInfo.Attributes.TargetPlatforms) Then
		Return CompatibilityErrorDetails();
	EndIf;
	
	Return "";
	
EndFunction

// Import parameters.
// 
// Returns:
//  Structure:
//   * Id - String
//   * Description - String
//   * Version - String
//   * FileName - String
//   * ErrorDescription - String - Information about add-in import.
//   * UpdateFrom1CITSPortal - Boolean
//   * Data - String - Binary data address in the temporary storage.
//            - BinaryData
//
Function ImportParameters() Export
	
	Result = New Structure;
	Result.Insert("Id", "");
	Result.Insert("Description", "");
	Result.Insert("Version", "");
	Result.Insert("FileName", "");
	Result.Insert("ErrorDescription", "");
	Result.Insert("UpdateFrom1CITSPortal", True);
	Result.Insert("Data", "");
	
	Return Result;
	
EndFunction

// Adds a binary data add-in to a catalog.
// 
// Parameters:
//  Parameters - See ImportParameters
//  ParseInfoFile - Boolean - Indicates whether INFO.XML file data is required
//                                      to analyze additionally.
//  UsedAddIns - See UsedAddIns
//
Procedure LoadAComponentFromBinaryData(Parameters, ParseInfoFile = True, 
	UsedAddIns = Undefined) Export
	
	If TypeOf(Parameters.Data) = Type("String") Then
		If IsBlankString(Parameters.Data) Or Not IsTempStorageURL(Parameters.Data) Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa chỉ ra địa chỉ kho chứa tạm thời trong tham số %1 khi gọi %2.';
					|ru = 'Не указан адрес временного хранилища в параметре %1 при вызове %2.';
					|en = 'Temporary storage address is not specified in the %1 parameter in %2.'; fa = 'Temporary storage address is not specified in the %1 parameter in %2.';
					|it = 'Temporary storage address is not specified in the %1 parameter in %2.';
					|pl = 'Temporary storage address is not specified in the %1 parameter in %2.';
					|tr = '%2 çağrısında %1 parametresinde zaman aşımı adresi belirtilmemiş.'"),
				"Parameters.Data", "LoadAComponentFromBinaryData");
			Raise(ExceptionText, ErrorCategory.ConfigurationError);
		EndIf;
		BinaryData = GetFromTempStorage(Parameters.Data);
	Else
		BinaryData = Parameters.Data;
	EndIf;
	
	If TypeOf(BinaryData) <> Type("BinaryData") Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Dữ liệu trong kho chứa tạm thời trong tham số %1 không phải là dữ liệu nhị phân khi gọi %2.';
				|ru = 'Данные во временном хранилище в параметре %1 не являются двоичными данными при вызове %2.';
				|en = 'Data in the temporary storage in the parameter %1 is not binary data in %2.'; fa = 'Data in the temporary storage in the parameter %1 is not binary data in %2.';
				|it = 'Data in the temporary storage in the parameter %1 is not binary data in %2.';
				|pl = 'Data in the temporary storage in the parameter %1 is not binary data in %2.';
				|tr = '%1 parametresindeki bu zaman aşımı, %2 çağrısındaki çifte verilerden değildir.'"),
			"Parameters.Data", "LoadAComponentFromBinaryData");
		Raise(ExceptionText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Information = InformationOnAddInFromFile(BinaryData, ParseInfoFile);
	If Not Information.Disassembled Then
		
		ExceptionText = Information.ErrorDescription + ?(Information.ErrorInfo = Undefined, "",
			 ": " + ErrorProcessing.BriefErrorDescription(Information.ErrorInfo));
		
		WriteLogEvent(NStr("vi = 'Thêm cấu phần ngoài';
							|ru = 'Добавление внешней компоненты';
							|en = 'Add add-in'; fa = 'Add add-in';
							|it = 'Aggiunta componente esterna';
							|pl = 'Dodawanie komponentu zewnętrznego';
							|tr = 'Harici bileşenin eklenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ExceptionText);
		Raise ExceptionText;
	EndIf;
	
	Id = ?(ValueIsFilled(Parameters.Id), Parameters.Id, Information.Attributes.Id);
	If Not ValueIsFilled(Id) Then
		ExceptionText = NStr("vi = 'Chưa chỉ ra ID cấu phần, cần nhập thủ công nó.';
							|ru = 'Не указан идентификатор компоненты, необходимо ввести его вручную.';
							|en = 'Enter the add-in ID.'; fa = 'Enter the add-in ID.';
							|it = 'Enter the add-in ID.';
							|pl = 'Enter the add-in ID.';
							|tr = 'Eklenti kimliği belirtilmemiş, bunu manuel girmeniz gerekmektedir.'");
		Raise ExceptionText;
	EndIf;
	
	BeginTransaction();
	Try

		Block = New DataLock;
		Block.Add("Catalog.AddIns");
		Block.Lock();

		Component = Catalogs.AddIns.FindByID(Id);
		If ValueIsFilled(Component) Then
			Object = Component.GetObject();
			Try
				TheResultOfComparingVersions = CommonClientServer.CompareVersions(Object.Version, Parameters.Version);
			Except
				// Overwrite the add-in if version comparison has failed.
				TheResultOfComparingVersions = -1;
			EndTry;
			If TheResultOfComparingVersions >= 0 Then
				RollbackTransaction();
				Return;
			EndIf;
		Else
			Object = Catalogs.AddIns.CreateItem();
			Object.Fill(Undefined);
		EndIf;
		
		// According to manifest data.
		FillPropertyValues(Object, Information.Attributes, , "Description, Version, FileName");
		
		Object.Id = Id;
		// If parameters Description, Version, and FileName are not assigned values, get the values from the information records.
		Object.Description = ?(ValueIsFilled(Parameters.Description), Parameters.Description, 
			Information.Attributes.Description);
		Object.Version = ?(ValueIsFilled(Parameters.Version), Parameters.Version, Information.Attributes.Version);
		Object.FileName = ?(ValueIsFilled(Parameters.FileName), Parameters.FileName, Information.Attributes.FileName);
		Object.ErrorDescription = Parameters.ErrorDescription;
		Object.UpdateFrom1CITSPortal = Parameters.UpdateFrom1CITSPortal;
		Object.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms, New Deflation(9));
		
		If UsedAddIns <> Undefined Then
			RowOfAddIn = UsedAddIns.Find(Id, "Id");
			If RowOfAddIn <> Undefined Then
				Object.UpdateFrom1CITSPortal = RowOfAddIn.AutoUpdate;
			EndIf;
		EndIf;
		
		Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Thêm cấu phần ngoài';
							|ru = 'Добавление внешней компоненты';
							|en = 'Add add-in'; fa = 'Add add-in';
							|it = 'Aggiunta componente esterna';
							|pl = 'Dodawanie komponentu zewnętrznego';
							|tr = 'Harici bileşenin eklenmesi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure


#Region ConfigurationSubsystemsEventHandlers

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export

	Objects.Insert(Metadata.Catalogs.AddIns.FullName(), "AttributesToEditInBatchProcessing");

EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export

	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.AddIns,
		ModuleExportImportData.ActionWithClearLinks());

EndProcedure

// See StandardSubsystemsServer.
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export

	If TypeOf(DataElement) = Type("CatalogObject.AddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;

EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.AddIns");
	Notification.NotificationSendModuleName  = "AddInsInternal";
	Notification.NotificationReceiptModuleName = "AddInsInternalClient";
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

#Region ToDoListSubsystemEventHandlers

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Users.IsExternalUserSession() Or Not Users.IsFullUser() Then
		Return;
	EndIf;

	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.AddIns.FullName());

	UnusedAddInsCount = UnusedAddInsCount();
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add ();
		ToDoItem.Id  = "DeleteUnusedAddIns";
		ToDoItem.HasToDoItems       = UnusedAddInsCount > 0;
		ToDoItem.Presentation  = NStr("vi = 'Xóa cấu phần không sử dụng';
										|ru = 'Удалить неиспользуемые компоненты';
										|en = 'Delete unused add-ins'; fa = 'حذف افزونه‌های استفاده‌نشده';
										|it = 'Удалить неиспользуемые компоненты';
										|pl = 'Delete unused add-ins';
										|tr = 'Kullanılmayan bileşenleri sil'");
		ToDoItem.Count     = UnusedAddInsCount;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "Catalog.AddIns.ListForm";
		ToDoItem.FormParameters = New Structure("UseFilter", 3);
		ToDoItem.Owner       = Section;
	EndDo;

EndProcedure

#EndRegion

#EndRegion

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.10.107";
	Handler.Id = New UUID("25e8efe8-37d5-47b4-a3c6-7e5277161b95");
	Handler.Procedure = "Catalogs.AddIns.ProcessDataForMigrationToNewVersion";
	Handler.InitialFilling = True;
	Handler.Comment = NStr("vi = 'Điền mục tin tương thích của cấu phần và thêm cấu phần chuẩn vào danh mục Cấu phần ngoài.';
							|ru = 'Заполнение реквизитов совместимости компонент и добавление стандартных компонент в справочник Внешние компоненты.';
							|en = 'Fill in the add-in compatibility attributes and add standard add-ins to the Add-ins catalog.'; fa = 'Fill in the add-in compatibility attributes and add standard add-ins to the Add-ins catalog.';
							|it = 'Заполнение реквизитов совместимости компонент и добавление стандартных компонент в справочник Внешние компоненты.';
							|pl = 'Fill in the add-in compatibility attributes and add standard add-ins to the Add-ins catalog.';
							|tr = 'Bileşen uyumluluk özniteliklerinin doldurulması ve standart bileşenlerin Harici Bileşenler kataloğuna eklenmesi.'");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.AddIns.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.AddIns";
	Handler.ObjectsToChange    = "Catalog.AddIns";
	
EndProcedure

#EndRegion

#Region Private

// Returns add-ins used in the configuration.
// 
// Returns:
//  ValueTable:
//   * Id - String
//   * AutoUpdate - Boolean 
//
Function UsedAddIns() Export
	
	UsedAddIns = New ValueTable;
	UsedAddIns.Columns.Add("Id",          Common.StringTypeDetails(50));
	UsedAddIns.Columns.Add("AutoUpdate", New TypeDescription("Boolean"));
	
	SSLSubsystemsIntegration.OnDefineUsedAddIns(UsedAddIns);
	Return UsedAddIns;
	
EndFunction

// Checks whether add-ins can be imported from the portal interactively.
//
// Returns:
//  Boolean
//
Function CanImportFromPortalInteractively() Export


	Return False;

EndFunction

// Returns a table of add-in details.
//
// Parameters:
//  Variant - String - Valid values:
//    ForUpdate - Add-ins from a catalog with the internet update flag set.
//    ForImport - Add-ins used in the configuration.
//
// Returns:
//   ValueTable:
//    * Id - String
//    * Version - String
//    * Description - String
//    * VersionDate - Date
//    * AutoUpdate - Boolean
//
Function AddInsData(Variant = "ForUpdate") Export
	
	Query = New Query;
	
	If Variant = "ForUpdate" Then
		Query.Text = 
			"SELECT
			|	AddIns.Id AS Id,
			|	AddIns.Version AS Version,
			|	AddIns.Description AS Description,
			|	AddIns.VersionDate AS VersionDate,
			|	AddIns.UpdateFrom1CITSPortal AS AutoUpdate
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.UpdateFrom1CITSPortal";
			
	ElsIf Variant = "ForImport" Then
		
		Query.Text =
			"SELECT
			|	UsedAddIns.Id,
			|	UsedAddIns.AutoUpdate
			|INTO UsedAddIns
			|FROM
			|	&UsedAddIns AS UsedAddIns
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(AddIns.Id, UsedAddIns.Id) AS Id,
			|	ISNULL(AddIns.Version, """") AS Version,
			|	ISNULL(AddIns.Description, """") AS Description,
			|	ISNULL(AddIns.VersionDate, DATETIME(1, 1, 1)) AS VersionDate,
			|	ISNULL(AddIns.UpdateFrom1CITSPortal, UsedAddIns.AutoUpdate) AS
			|		AutoUpdate
			|FROM
			|	Catalog.AddIns AS AddIns
			|		FULL JOIN UsedAddIns AS UsedAddIns
			|		ON AddIns.Id = UsedAddIns.Id";
			
			Query.SetParameter("UsedAddIns", UsedAddIns());
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị tham số không được phép %1 (%2) khi gọi %3. ';
				|ru = 'Недопустимое значение параметра %1 (%2) при вызове %3.';
				|en = 'Invalid value of parameter %1 (%2) when calling %3.'; fa = 'Invalid value of parameter %1 (%2) when calling %3.';
				|it = 'Invalid value of parameter %1 (%2) when calling %3.';
				|pl = 'Invalid value of parameter %1 (%2) when calling %3.';
				|tr = '%3 çağırılırken parametre %1 (%2) geçersiz değeri.'"), 
			"Variant", Variant, "AddInsInternal.AddInsData");
	EndIf;
	
	Return Query.Execute().Unload();

EndFunction

Procedure DeleteUnusedAddIns() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AddIns.Ref AS Ref
	|FROM
	|	Catalog.AddIns AS AddIns
	|WHERE
	|	NOT AddIns.DeletionMark
	|	AND NOT AddIns.Id IN (&IDs)";

	Query.SetParameter("IDs", SuppliedAddIns());

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();

			Object = Selection.Ref.GetObject();
			Object.DeletionMark = True;
			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Xóa cấu phần ngoài';
								|ru = 'Удаление внешней компоненты';
								|en = 'Delete the add-in'; fa = 'Delete the add-in';
								|it = 'Удаление внешней компоненты';
								|pl = 'Delete the add-in';
								|tr = 'Harici bileşenin silinmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
			Raise;
		EndTry;
		
	EndDo;
	
	NotifyAllSessionsAboutAddInChange();
	
EndProcedure

Function UnusedAddInsCount()
	
	Query = New Query;
	Query.Text = 
			"SELECT
			|	COUNT(AddIns.Ref) AS UnusedAddInsCount
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	NOT AddIns.DeletionMark
			|	AND NOT AddIns.Id IN (&IDs)";
	
	Query.SetParameter("IDs", SuppliedAddIns());
		
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.UnusedAddInsCount;
	EndIf;
	
	Return 0;
	
EndFunction

Procedure NotifyAllSessionsAboutAddInChange() Export
	
	ServerNotifications.SendServerNotification(
		"StandardSubsystems.AddIns", "", Undefined, True);
	
EndProcedure

// See StandardSubsystemsServer.OnSendServerNotification
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	If NameOfAlert <> "StandardSubsystems.AddIns" Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.AddIns.Versions";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	NewValue = AddInsVersionsChecksum();
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	ServerNotifications.SendServerNotification(NameOfAlert, "", Undefined);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
		If PreviousValue2 <> NewValue Then
			StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function AddInsVersionsChecksum()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AddIns.Ref AS Ref,
	|	AddIns.DataVersion AS DataVersion
	|FROM
	|	Catalog.AddIns AS AddIns";
	
	Selection = Query.Execute().Select();
	
	VersionsList = New ValueList;
	AddAddInVersions(VersionsList, Selection);
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		Selection = ModuleAddInsSaaSInternal.SharedAddInVersions();
		AddAddInVersions(VersionsList, Selection);
	EndIf;
	
	VersionsList.SortByValue();
	Versions = StrConcat(VersionsList.UnloadValues(), Chars.LF);
	Hashing = New DataHashing(HashFunction.SHA256);
	Hashing.Append(Versions);
	
	Return Base64String(Hashing.HashSum);
	
EndFunction

// Parameters:
//  VersionsList - ValueList
//  Selection - DataSelection:
//   * Ref - CatalogRef
//   * DataVersion - String
//
Procedure AddAddInVersions(VersionsList, Selection)
	
	While Selection.Next() Do
		VersionsList.Add(Lower(Selection.Ref.UUID()) + " " + Selection.DataVersion);
	EndDo;
	
EndProcedure

// Checks whether an add-in from the add-in storage 
// based on Native API or COM technologies can be attached on 1C:Enterprise server.
//
// Parameters:
//   Id - String - the add-in identification code.
//   Version        - String - an add-in version.
//   ConnectionParameters - See AddInsServer.ConnectionParameters.
//
// Returns:
//   String - brief error message. 
//
Function CheckAddInAttachmentAbility(Val Id, Val Version = Undefined,
	Val ConnectionParameters = Undefined) Export

	If ConnectionParameters = Undefined Then
		ConnectionParameters = AddInsServer.ConnectionParameters();
	EndIf;

	If IsBlankString(Id) Then
		AddInContainsOneObjectClass = (ConnectionParameters.ObjectsCreationIDs.Count() = 0);
		If AddInContainsOneObjectClass Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cho phép đồng thời không chỉ ra %1 và %2 khi kết nối cấu phần ngoài.';
					|ru = 'Недопустимо одновременно не указывать %1 и %2 при подключении внешней компоненты.';
					|en = 'When attaching an external add-in, ""%1"" and ""%2"" cannot be empty at the same time.'; fa = 'When attaching an external add-in, ""%1"" and ""%2"" cannot be empty at the same time.';
					|it = 'Impossibile indicare contemporaneamente %1 e %2 alla connessione della componente esterna.';
					|pl = 'Nie można jednocześnie nie podawać %1 i %2 przy podłączeniu komponentu zewnętrznego.';
					|tr = 'Harici bileşenin bağlanması sırasında %1 ile %2 belirtilmemesi kabul edilemez.'"),
				"Id", "ObjectsCreationIDs");
			Raise(ExceptionText, ErrorCategory.ConfigurationError);
		EndIf;
		Id = StrConcat(ConnectionParameters.ObjectsCreationIDs, ", ");
	EndIf;

	Result = New Structure;
	Result.Insert("Location", "");
	Result.Insert("Id", Id);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Version", "");

	Information = AddInsInternalServerCall.SavedAddInInformation(Id, Version, 
		ConnectionParameters.FullTemplateName);
	Result.Insert("Version", Information.Attributes.Version);
	If Information.State = "DisabledByAdministrator" Then
		Result.ErrorDescription = NStr("vi = 'Các thành phần đã bị vô hiệu hóa bởi các quản trị viên.';
										|ru = 'Компонента отключена администратором.';
										|en = 'The add-in is disabled by the administrator.'; fa = 'The add-in is disabled by the administrator.';
										|it = 'Il componente disattivato dall''amministratore.';
										|pl = 'Komponent jest odłączony przez administratora.';
										|tr = 'Bileşen yönetici tarafından devre dışı bırakıldı.'");
		Return Result;
	ElsIf Information.State = "NotFound1" Then
		Result.ErrorDescription = NStr("vi = 'Thành phần này không có trong danh sách các thành phần bên ngoài được phép.';
										|ru = 'Компонента отсутствует в списке разрешенных внешних компонент.';
										|en = 'The add-in is missing from the list of allowed add-ins.'; fa = 'The add-in is missing from the list of allowed add-ins.';
										|it = 'Il componente non è nell''elenco di componenti esterni consentiti.';
										|pl = 'Brak komponentu na liście dozwolonych komponentów zewnętrznych.';
										|tr = 'Bileşen izin verilen harici bileşen listesinde bulunmuyor.'");
		Return Result;
	ElsIf Information.IsTargetPlatformsFilled 
		And Not OperatingSystemSupportedByAddInn(Information.Attributes.TargetPlatforms) Then
		Result.ErrorDescription = CompatibilityErrorDetails();
		Return Result;
	EndIf;
	
	CheckTheLocationOfTheComponent(Id, Information.Location);
	Result.Location = Information.Location;
	Return Result;

EndFunction

Function CompatibilityErrorDetails()
	
	SystemInfo = New SystemInfo;
	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không xem xết hoạt động của cấu phần này trong hệ điều hành %1.';
			|ru = 'Не предусмотрена работа компоненты в операционной системе %1.';
			|en = 'The add-in does not work in the %1 operating system.'; fa = 'The add-in does not work in the %1 operating system.';
			|it = 'Non è previsto il funzionamento del componente nel sistema operativo %1.';
			|pl = 'Nie przewidziano pracy komponentu w systemie operacyjnym %1.';
			|tr = 'Bileşenin %1 işletim sisteminde çalışması ön görülmemiştir.'"), NameOfThePlatformType);
	
EndFunction

Function TemplateAddInInfo(Location) Export
	
	If Not Common.TemplateExists(Location) Then
		Return Undefined;
	EndIf;
	
	LayoutLocationSplit = StrSplit(Location, ".");
	TemplateName = LayoutLocationSplit.Get(LayoutLocationSplit.UBound());
	
	If LayoutLocationSplit.Count() = 2 Then
		ComponentBinaryData = GetCommonTemplate(TemplateName);
	Else
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		ObjectManagerByFullName =  Common.ObjectManagerByFullName(
			StrConcat(LayoutLocationSplit, "."));
		ComponentBinaryData = ObjectManagerByFullName.GetTemplate(TemplateName);
	EndIf;
	
	InformationOnAddInFromFile = InformationOnAddInFromFile(ComponentBinaryData);
	If Not InformationOnAddInFromFile.Disassembled Then
		Return Undefined;
	EndIf;
	
	Return InformationOnAddInFromFile;
	
EndFunction

#Region SavedAddInInformation

Function OperatingSystemSupportedByAddInn(AddInAttributes)

	SystemInfo = New SystemInfo;
	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	If NameOfThePlatformType = "Linux_x86" Then
		Return AddInAttributes.Linux_x86;
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		Return AddInAttributes.Linux_x86_64;
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		Return AddInAttributes.MacOS_x86;
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		Return AddInAttributes.MacOS_x86_64;
	ElsIf NameOfThePlatformType = "Windows_x86" Then
		Return AddInAttributes.Windows_x86;
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		Return AddInAttributes.Windows_x86_64;
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
		Return AddInAttributes.Linux_ARM64;
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		Return AddInAttributes.Linux_e2k;
	ElsIf NameOfThePlatformType = "Android_ARM" Then
		Return AddInAttributes.Android_ARM;
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
		Return AddInAttributes.Android_ARM64;
	ElsIf NameOfThePlatformType = "Android_x86" Then
		Return AddInAttributes.Android_x86;
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
		Return AddInAttributes.Android_x86_64;
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
		Return AddInAttributes.iOS_ARM;
	ElsIf NameOfThePlatformType = "iOS_ARM_64" Then
		Return AddInAttributes.iOS_ARM64;
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
		Return AddInAttributes.WindowsRT_ARM;
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
		Return AddInAttributes.WindowsRT_x86;
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
		Return AddInAttributes.WindowsRT_x86_64;
	EndIf;

	Return False;

EndFunction

Function ImportFromFileIsAvailable()

	Return Users.IsFullUser(, , False);

EndFunction

// Parameters:
//   Id - String - the add-in identification code.
//   Version        - String - Add-in version.
//   ThePathToTheLayoutToSearchForTheLatestVersion - String
//
// Returns:
//  Structure:
//    * CanImportFromPortal - Boolean
//    * ImportFromFileIsAvailable - Boolean
//    * State - String - "NotFound", "FoundInStorage", "FoundInSharedStorage", "DisabledByAdministrator" 
//    * Location - String
//    * Ref - AnyRef
//    * Attributes - See AddInAttributes
//    * IsTargetPlatformsFilled - Boolean
//    * TheLatestVersionOfComponentsFromTheLayout - See StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout
//
Function SavedAddInInformation(Id, Version = Undefined, 
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined) Export

	Result = New Structure;
	Result.Insert("Ref");
	Result.Insert("Attributes", AddInAttributes());
	Result.Insert("Location");
	Result.Insert("State");
	Result.Insert("ImportFromFileIsAvailable", ImportFromFileIsAvailable());
	Result.Insert("CanImportFromPortal", CanImportFromPortal());
	Result.Insert("TheLatestVersionOfComponentsFromTheLayout");
	Result.Insert("IsTargetPlatformsFilled", False);

	If Common.DataSeparationEnabled()
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
	
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.FillAddInInformation(Result, Version, Id);
	Else	
		ReferenceFromStorage = Catalogs.AddIns.FindByID(Id, Version);
		If ReferenceFromStorage.IsEmpty() Then
			Result.State = "NotFound1";
		Else
			Result.State = "FoundInStorage";
			Result.Ref = ReferenceFromStorage;
		EndIf
	EndIf;
	
	If ThePathToTheLayoutToSearchForTheLatestVersion <> Undefined Then
		Result.TheLatestVersionOfComponentsFromTheLayout = StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout(
			ThePathToTheLayoutToSearchForTheLatestVersion);
	EndIf;

	If Result.State = "NotFound1" Then
		Return Result;
	EndIf;

	Attributes = AddInAttributes();
	If Result.State = "FoundInStorage" Then
		Attributes.Insert("Use");
	EndIf;
	If Result.State = "FoundInSharedStorage" Then
		Attributes.Delete("FileName");
	EndIf;
	Attributes.TargetPlatforms = Undefined;
	
	ObjectAttributes = Common.ObjectAttributesValues(Result.Ref, Attributes);
	
	ObjectAttributes.TargetPlatforms = ObjectAttributes.TargetPlatforms.Get();
	If ObjectAttributes.TargetPlatforms = Undefined Then
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không điền thông tin về tương thích cấu phần %1.';
				|ru = 'Не заполнена информация о совместимости компоненты %1.';
				|en = 'Compatibility information for the %1 add-in is not filled in.'; fa = 'Compatibility information for the %1 add-in is not filled in.';
				|it = 'Не заполнена информация о совместимости компоненты %1.';
				|pl = 'Compatibility information for the %1 add-in is not filled in.';
				|tr = '%1 bileşeni için uyumluluk bilgileri doldurulmadı.'"), Id);
		WriteLogEvent(NStr("vi = 'Kiểm tra tương thích cấu phần';
							|ru = 'Проверка совместимости компоненты';
							|en = 'Add-in compatibility check'; fa = 'Add-in compatibility check';
							|it = 'Проверка совместимости компоненты';
							|pl = 'Add-in compatibility check';
							|tr = 'Bileşen uyumluluk kontrolü'",
			Common.DefaultLanguageCode()), EventLogLevel.Warning, , Result.Ref, 
			WarningText);
		
		ObjectAttributes.TargetPlatforms = TargetPlatforms();
	Else
		Result.IsTargetPlatformsFilled = True;
	EndIf;

	FillPropertyValues(Result.Attributes, ObjectAttributes);
	Result.Location = GetURL(Result.Ref, "AddInStorage");

	If Result.State = "FoundInStorage" Then
		If ObjectAttributes.Use <> Enums.AddInUsageOptions.Used Then
			Result.State = "DisabledByAdministrator";
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

// Returns:
//  Structure:
//    * TargetPlatforms - See TargetPlatforms
//    * Id - String
//    * Description - String
//    * Version - String
//    * VersionDate - Date
//    * FileName - String
//
Function AddInAttributes()

	Attributes = New Structure;
	Attributes.Insert("Id");
	Attributes.Insert("Description");
	Attributes.Insert("Version");
	Attributes.Insert("VersionDate");
	Attributes.Insert("FileName");
	Attributes.Insert("TargetPlatforms", TargetPlatforms());

	Return Attributes;

EndFunction

// Returns:
//  Structure:
//    * Windows_x86 - Boolean
//    * Windows_x86_64 - Boolean
//    * Linux_x86 - Boolean
//    * Linux_x86_64 - Boolean
//    * Windows_x86_Firefox - Boolean
//    * Linux_x86_Firefox - Boolean
//    * Linux_x86_64_Firefox - Boolean
//    * Windows_x86_MSIE - Boolean
//    * Windows_x86_64_MSIE - Boolean
//    * Windows_x86_Chrome - Boolean
//    * Linux_x86_Chrome - Boolean
//    * Linux_x86_64_Chrome - Boolean
//    * MacOS_x86_64_Safari - Boolean
//    * MacOS_x86_64_Chrome - Boolean
//    * MacOS_x86_64_Firefox - Boolean
//    * Windows_x86_YandexBrowser - Boolean
//    * Windows_x86_64_YandexBrowser - Boolean
//    * Linux_x86_YandexBrowser - Boolean
//    * Linux_x86_64_YandexBrowser - Boolean
//    * MacOS_x86_64_YandexBrowser - Boolean
//    * Linux_E2K - Boolean
//    * Linux_E2K_Firefox - Boolean
//    * Linux_E2K_YandexBrowser - Boolean
//    * Linux_E2K_Chrome - Boolean
//    * Linux_ARM64 - Boolean
//    * iOS_ARM - Boolean
//    * iOS_ARM64 - Boolean
//    * Android_ARM - Boolean
//    * Android_x86_64 - Boolean
//    * Android_x86 - Boolean
//    * Android_ARM64 - Boolean
//    * WindowsRT_ARM - Boolean
//    * WindowsRT_x86 - Boolean
//    * WindowsRT_x86_64 - Boolean
//
Function TargetPlatforms()

	Attributes = New Structure;
	Attributes.Insert("Windows_x86",                  False);
	Attributes.Insert("Windows_x86_64",               False);
	Attributes.Insert("Linux_x86",                    False);
	Attributes.Insert("Linux_x86_64",                 False);
	Attributes.Insert("Windows_x86_Firefox",          False);
	Attributes.Insert("Linux_x86_Firefox",            False);
	Attributes.Insert("Linux_x86_64_Firefox",         False);
	Attributes.Insert("Windows_x86_MSIE",             False);
	Attributes.Insert("Windows_x86_64_MSIE",          False);
	Attributes.Insert("Windows_x86_Chrome",           False);
	Attributes.Insert("Linux_x86_Chrome",             False);
	Attributes.Insert("Linux_x86_64_Chrome",          False);
	Attributes.Insert("MacOS_x86_64",                 False);
	Attributes.Insert("MacOS_x86_64_Safari",          False);
	Attributes.Insert("MacOS_x86_64_Chrome",          False);
	Attributes.Insert("MacOS_x86_64_Firefox",         False);
	Attributes.Insert("Windows_x86_YandexBrowser",    False);
	Attributes.Insert("Windows_x86_64_YandexBrowser", False);
	Attributes.Insert("Linux_x86_YandexBrowser",      False);
	Attributes.Insert("Linux_x86_64_YandexBrowser",   False);
	Attributes.Insert("MacOS_x86_64_YandexBrowser",   False);
	Attributes.Insert("Linux_E2K",                    False);
	Attributes.Insert("Linux_E2K_Firefox",            False);
	Attributes.Insert("Linux_E2K_YandexBrowser",      False);
	Attributes.Insert("Linux_E2K_Chrome",             False);
	Attributes.Insert("Linux_ARM64",                  False);
	Attributes.Insert("Linux_ARM64_Firefox",          False);
	Attributes.Insert("Linux_ARM64_YandexBrowser",    False);
	Attributes.Insert("Linux_ARM64_Chrome",           False);
	Attributes.Insert("iOS_ARM",                      False);
	Attributes.Insert("iOS_ARM64",                    False);
	Attributes.Insert("Android_ARM",                  False);
	Attributes.Insert("Android_x86_64",               False);
	Attributes.Insert("Android_x86",                  False);
	Attributes.Insert("Android_ARM64",                False);
	Attributes.Insert("WindowsRT_ARM",                False);
	Attributes.Insert("WindowsRT_x86",                False);
	Attributes.Insert("WindowsRT_x86_64",             False);
	
	Return Attributes;

EndFunction

#EndRegion

#Region GetInformationFromComponentFile

Procedure FillAttributesByManifestXML(ManifestXMLFileName, Attributes)

	XMLReader = New XMLReader;
	XMLReader.OpenFile(ManifestXMLFileName);

	XMLReader.MoveToContent();
	If XMLReader.Name <> "bundle" Or XMLReader.NodeType <> XMLNodeType.StartElement Then
		XMLReader.Close();
		Return;
	EndIf;
	
	While XMLReader.Read() Do
		If XMLReader.Name <> "component" Or XMLReader.NodeType <> XMLNodeType.StartElement Then
			Continue;
		EndIf;

		OperatingSystem = Lower(XMLReader.AttributeValue("os"));
		ComponentType = Lower(XMLReader.AttributeValue("type"));
		PlatformArchitecture = Lower(XMLReader.AttributeValue("arch"));
		Viewer = Lower(XMLReader.AttributeValue("client"));

		If OperatingSystem = "windows" And (ComponentType = "native" Or ComponentType = "com") Then

			If PlatformArchitecture = "i386" Then
				Attributes.Windows_x86 = True;
				Continue;
			EndIf;

			If PlatformArchitecture = "x86_64" Then
				Attributes.Windows_x86_64 = True;
				Continue;
			EndIf;
			
			Continue;
		EndIf;
		
		If OperatingSystem = "linux" And ComponentType = "native" Then
		
			If PlatformArchitecture = "i386" Then
				Attributes.Linux_x86 = True;
				Continue;
			EndIf;

			If PlatformArchitecture = "x86_64" Then
				Attributes.Linux_x86_64 = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "arm64" Then
				Attributes.Linux_ARM64 = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "e2k" Then
				Attributes.Linux_E2K = True;
				Continue;
			EndIf;
			
			Continue;
		EndIf;
		
		If OperatingSystem = "macos" And ComponentType = "native" And (PlatformArchitecture = "x86_64"
				Or PlatformArchitecture = "universal") Then
			Attributes.MacOS_x86_64 = True;
			Continue;
		EndIf;
		
		If OperatingSystem = "windowsruntime" Then

			If PlatformArchitecture = "arm" Then
				Attributes.WindowsRT_ARM = True;
			ElsIf PlatformArchitecture = "x86_64" Then
				Attributes.WindowsRT_x86_64 = True;
			ElsIf PlatformArchitecture = "x86" Then
				Attributes.WindowsRT_x86 = True;
			EndIf;
			
			Continue;
			
		EndIf;
		
		If OperatingSystem = "android" Then

			If PlatformArchitecture = "arm" Then
				Attributes.Android_ARM = True;
			ElsIf PlatformArchitecture = "arm64" Then
				Attributes.Android_ARM64 = True;
			ElsIf PlatformArchitecture = "x86_64" Then
				Attributes.Android_x86_64 = True;
			ElsIf PlatformArchitecture = "i386" Then
				Attributes.Android_x86 = True;
			EndIf;
			
			Continue;
			
		EndIf;
		
		If OperatingSystem = "ios" Then

			If PlatformArchitecture = "arm" Or PlatformArchitecture = "universal" Then
				Attributes.iOS_ARM = True;
			EndIf;
			
			If PlatformArchitecture = "arm64" Or PlatformArchitecture = "universal" Then
				Attributes.iOS_ARM64 = True;
			EndIf;
			
			Continue;
			
		EndIf;
		
		If OperatingSystem = "linux" And ComponentType = "plugin" Then

			If PlatformArchitecture = "i386" And Viewer = "firefox" Then
				Attributes.Linux_x86_Firefox = True;
				Continue;
			EndIf;

			If PlatformArchitecture = "x86_64" And Viewer = "firefox" Then
				Attributes.Linux_x86_64_Firefox = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "arm64" And Viewer = "firefox" Then
				Attributes.Linux_ARM64_Firefox = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "e2k" And Viewer = "firefox" Then
				Attributes.Linux_E2K_Firefox = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "i386" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_x86_YandexBrowser = True;
			EndIf;
			
			If PlatformArchitecture = "i386" And (Viewer = "chrome" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_x86_Chrome = True;
			EndIf;

			If PlatformArchitecture = "x86_64" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_x86_64_YandexBrowser = True;
			EndIf;

			If PlatformArchitecture = "x86_64" And (Viewer = "chrome" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_x86_64_Chrome = True;
			EndIf;
			
			If PlatformArchitecture = "arm64" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_ARM64_YandexBrowser = True;
			EndIf;

			If PlatformArchitecture = "arm64" And (Viewer = "chrome" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_ARM64_Chrome = True;
			EndIf;
			
			If PlatformArchitecture = "e2k" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_E2K_YandexBrowser = True;
			EndIf;

			If PlatformArchitecture = "e2k" And (Viewer = "chrome" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Linux_E2K_Chrome = True;
			EndIf;
			
			Continue;
		EndIf;
		
		If OperatingSystem = "windows" And ComponentType = "plugin" Then
			
			If PlatformArchitecture = "i386" And Viewer = "msie" Then
				Attributes.Windows_x86_MSIE = True;
				Continue;
			EndIf;

			If PlatformArchitecture = "x86_64" And Viewer = "msie" Then
				Attributes.Windows_x86_64_MSIE = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "i386" And Viewer = "firefox" Then
				Attributes.Windows_x86_Firefox = True;
				Continue;
			EndIf;
			
			If PlatformArchitecture = "i386" And (Viewer = "chrome" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Windows_x86_Chrome = True;
			EndIf;
			
			If PlatformArchitecture = "i386" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Windows_x86_YandexBrowser = True;
			EndIf;
			
			If PlatformArchitecture = "x86_64" And (Viewer = "yandexbrowser" 
				Or Viewer = "anychromiumbased") Then
				Attributes.Windows_x86_64_YandexBrowser = True;
			EndIf;

			Continue;
			
		EndIf;
		
		If OperatingSystem = "macos" And ComponentType = "plugin" Then

			If  (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") 
				And Viewer = "safari" Then
				Attributes.MacOS_x86_64_Safari = True;
				Continue;
			EndIf;
						
			If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") 
				And Viewer = "firefox" Then
				Attributes.MacOS_x86_64_Firefox = True;
				Continue;
			EndIf;
			
			If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") 
				And (Viewer = "chrome" Or Viewer = "anychromiumbased") Then
				Attributes.MacOS_x86_64_Chrome = True;
			EndIf;
			
			If (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal") 
				And (Viewer = "yandexbrowser" Or Viewer = "anychromiumbased") Then
				Attributes.MacOS_x86_64_YandexBrowser = True;
			EndIf;
		
			Continue;
			
		EndIf;
	EndDo;

	XMLReader.Close();

EndProcedure

Procedure FillAttributesByInfoXML(InfoXMLFileName, Attributes)

	FileRead = False;

	// TryingToParseByPLFormat
	XMLReader = New XMLReader;
	XMLReader.OpenFile(InfoXMLFileName);

	XMLReader.MoveToContent();
	If XMLReader.Name = "drivers" And XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do
			If XMLReader.Name <> "component" Or XMLReader.NodeType <> XMLNodeType.StartElement Then
				Continue;
			EndIf;

			Id = XMLReader.AttributeValue("progid");
			
			Attributes.Id = Mid(Id, StrFind(Id, ".") + 1);
			Attributes.Description = XMLReader.AttributeValue("name");
			Attributes.Version = XMLReader.AttributeValue("version");

			FileRead = True;
		EndDo;
	EndIf;
	XMLReader.Close();

	If FileRead Then
		Return;
	EndIf;

	// Trying to parse by EDL format.
	XMLReader = New XMLReader;
	XMLReader.OpenFile(InfoXMLFileName);

	InformationOfAddIn = XDTOFactory.ReadXML(XMLReader);
	Attributes.Id = InformationOfAddIn.progid;
	Attributes.Description = InformationOfAddIn.name;
	Attributes.Version = InformationOfAddIn.version;

	XMLReader.Close();

EndProcedure

Function EvaluateXPathExpression(Expression, DOMDocument)

	XPathValue = Undefined;

	Dereferencer = DOMDocument.CreateNSResolver();
	XPathResult = DOMDocument.EvaluateXPathExpression(Expression, DOMDocument, Dereferencer);

	ResultNode = XPathResult.IterateNext();
	If TypeOf(ResultNode) = Type("DOMAttribute") Then
		XPathValue = ResultNode.Value;
	EndIf;

	Return XPathValue
EndFunction

Function DOMDocument(PathToFile)

	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();

	Return DOMDocument;

EndFunction

#EndRegion


// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("NewAddInsFromPortal", True);
	Methods.Insert("UpdateAddInsFromPortal", True);
	
EndProcedure

#EndRegion