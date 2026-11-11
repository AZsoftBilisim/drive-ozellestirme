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

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, Metadata.Reports.ExternalResourcesInUse, "");
	OptionSettings.Description = NStr("vi = 'Nguồn ngoài do ứng dụng và các mô-đun bổ sung sử dụng';
										|ru = 'Внешние ресурсы, используемые приложением и дополнительными модулями';
										|en = 'External resources that the app and additional modules use'; fa = 'منابع خارجی مورد استفاده برنامه و ماژول‌های تکمیلی';
										|it = 'Внешние ресурсы, используемые приложением и дополнительными модулями';
										|pl = 'External resources that the app and additional modules use';
										|tr = 'Uygulamanın ve ek modüllerin kullandığı dış kaynaklar'");
	OptionSettings.LongDesc = 
		NStr("vi = 'Tài nguyên Internet, thành phần bên ngoài, lớp COM...
		           |Cài đặt môi trường sẽ giúp quản trị viên
		           |tùy chỉnh máy tính và tiến hành kiểm tra bảo mật.';
		           |ru = 'Интернет-ресурсы, внешние компоненты, COM-классы и прочее.
		           |Параметры окружения, которые помогут администратору
		           |выполнить настройку компьютера и провести аудит безопасности.';
		           |en = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.'; fa = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.';
		           |it = 'Risorse Internet, componenti esterni, classi COM e altro.
		           |Parametri ambientali che aiutano l''amministratore
		           | a configurare il computer e effettuare un controllo di sicurezza.';
		           |pl = 'Zasoby internetowe, komponenty zewnętrzne, klasy COM oraz in.
		           |Ustawienia środowiska, które pomogą administratorowi
		           |skonfigurować komputer i przeprowadzić audyt bezpieczeństwa.';
		           |tr = 'İnternet kaynakları, harici bileşenler, COM sınıfları ve daha fazlası.
		           | Bir yöneticinin bilgisayarı yapılandırmasına ve bir güvenlik denetimi 
		           |gerçekleştirmesine yardımcı olacak çevre parametreleri.'");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("vi = 'Tên và tên định danh lớp COM
		           |Tên máy tính
		           |Địa chỉ
		           |Đọc dữ liệu
		           |Ghi lại dữ liệu
		           |Tên khuôn in hoặc tệp cấu phần
		           |Số tiền kiểm tra
		           |Mẫu dòng lệnh
		           |Giao thức
		           |Địa chỉ tài nguyên Internet
		           |Cổng';
		           |ru = 'Имя и идентификатор COM-класса
		           |Имя компьютера
		           |Адрес
		           |Чтение данных
		           |Запись данных
		           |Имя макета или файла компоненты
		           |Контрольная сумма
		           |Шаблон командной строки
		           |Протокол
		           |Адрес Интернет-ресурса
		           |Порт';
		           |en = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Save data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port'; fa = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Save data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port';
		           |it = 'Nome e identificativo della classe COM
		           |Nome del computer
		           |Indirizzo
		           |Lettura dei dati
		           |Record di dati
		           |Nome del modello o file del componente
		           |Checksum
		           |Modello della riga di comando
		           |Protocollo
		           |Indirizzo della risorsa Internet
		           |Porta';
		           |pl = 'Nazwa i identyfikator klasy COM
		           |Nazwa komputera
		           |Adres
		           |Dane odczytane
		           |Zapis danych
		           |Nazwa układu lub pliku komponenty
		           |Suma kontrolna
		           |Schemat paska poleceń
		           |Protokół
		           |Adres zasobu internetowego
		           |Port';
		           |tr = 'COM sınıfı adı ve tanımlayıcı
		           | Bilgisayar adı
		           | Adres 
		           |Veri oku
		           | Veri kaydı
		           | Şablon adı veya dosya bileşen adı
		           | Sağlama toplamı
		           | Komut satırı şablonu
		           | Protokol
		           | İnternet kaynağı adresi 
		           |Bağlantı noktası'");
	
	// Filters and parameters are not available for the report.
	OptionSettings.SearchSettings.FilterParameterDescriptions = "#";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// For internal use only.
//
Function RequestsForPermissionsToUseExternalResoursesPresentation(Val AdministrationOperations, Val PermissionsToAddDetails, Val PermissionsToDeleteDetails, Val AsRequired = False) Export
	
	Template = GetTemplate("PermissionsPresentations");
	OffsetArea = Template.GetArea("Indent");
	SpreadsheetDocument = New SpreadsheetDocument();
	
	AllProgramModules = New Map();
	
	For Each LongDesc In AdministrationOperations Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each LongDesc In PermissionsToAddDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each LongDesc In PermissionsToDeleteDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	ModulesTable = New ValueTable();
	ModulesTable.Columns.Add("ProgramModule", Common.AllRefsTypeDetails());
	ModulesTable.Columns.Add("IsConfiguration", New TypeDescription("Boolean"));
	
	For Each KeyAndValue In AllProgramModules Do
		String = ModulesTable.Add();
		String.ProgramModule = KeyAndValue.Key;
		String.IsConfiguration = (KeyAndValue.Key = Catalogs.MetadataObjectIDs.EmptyRef());
	EndDo;
	
	ModulesTable.Sort("IsConfiguration DESC");
	
	For Each ModulesTableRow In ModulesTable Do
		
		SpreadsheetDocument.Put(OffsetArea);
		
		Properties = SafeModeManagerInternal.PropertiesForPermissionRegister(
			ModulesTableRow.ProgramModule);
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", Properties.Type);
		Filter.Insert("ModuleID", Properties.Id);
		
		GenerateOperationsPresentation(SpreadsheetDocument, Template, AdministrationOperations.FindRows(Filter));
		
		IsConfigurationProfile = (Properties.Type= Catalogs.MetadataObjectIDs.EmptyRef());
		
		If IsConfigurationProfile Then
			
			Dictionary = ConfigurationModuleDictionary();
			ModuleDescription = Metadata.Synonym;
			
		Else
			
			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Properties.Type, Properties.Id);
			
			ExternalModuleManager = SafeModeManagerInternal.ExternalModuleManager(ProgramModule);
			
			Dictionary = ExternalModuleManager.ExternalModuleContainerDictionary();
			Pictogram = ExternalModuleManager.ExternalModuleIcon(ProgramModule);
			ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
			
		EndIf;
		
		ItemsToAdd = PermissionsToAddDetails.Copy(Filter);
		If ItemsToAdd.Count() > 0 Then
			
			If AsRequired Then
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với %1 ""%2"" cần sử dụng các nguồn ngoài sau:';
						|ru = 'Для %1 ""%2"" требуется использование следующих внешних ресурсов:';
						|en = '%2 %1 requires the following external resources:'; fa = '%2 %1 requires the following external resources:';
						|it = 'Per %1 ""%2"" è richiesto l''utilizzo delle seguenti risorse esterne:';
						|pl = 'Do %1 ""%2"" wymaga się użycia następujących zasobów zewnętrznych:';
						|tr = '%1""%2"", aşağıdaki dış kaynakların kullanılmasını gerektirir:'"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
				
			Else
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với %1 ""%2"" sẽ có quyền được phép sử dụng nguồn ngoài như sau:';
						|ru = 'Для %1 ""%2"" будут предоставлены следующие разрешения на использование внешних ресурсов:';
						|en = 'The following permissions to use external resources will be granted for %2 %1:'; fa = 'The following permissions to use external resources will be granted for %2 %1:';
						|it = 'Per %1 ""%2"" verranno concesse le seguenti autorizzazioni per l''utilizzo delle risorse esterne:';
						|pl = 'Dla %1 ""%2"" zostaną podane następujące uprawnienia do korzystania z zasobów zewnętrznych:';
						|tr = '%1""%2"", harici kaynakları kullanmak için aşağıdaki izinlere sahip olacaktır:'"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
				
			EndIf;
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Pictogram"] = Pictogram;
				
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			SpreadsheetDocument.Put(OffsetArea);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, ItemsToAdd, AsRequired);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		ItemsToDelete = PermissionsToDeleteDetails.Copy(Filter);
		If ItemsToDelete.Count() > 0 Then
			
			If AsRequired Then
				Raise NStr("vi = 'Sai truy vấn cho phép';
							|ru = 'Некорректный запрос разрешений';
							|en = 'Incorrect permission request'; fa = 'Incorrect permission request';
							|it = 'Richiesta di autorizzazione non valida';
							|pl = 'Nieprawidłowe żądanie uprawnień';
							|tr = 'Yanlış izin isteği'");
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sẽ xóa các quyền được phép sử dụng nguồn ngoài đối với %1 ""%2"" sau đây:';
						|ru = 'Будут удалены следующие ранее предоставленные для %1 ""%2"" разрешения на использование внешних ресурсов:';
						|en = 'The following granted permissions to use external resources will be removed for %2 %1:'; fa = 'The following granted permissions to use external resources will be removed for %2 %1:';
						|it = 'Verranno eliminate le seguenti autorizzazioni concesse per %1 ""%2"" per l''utilizzo delle risorse esterne:';
						|pl = 'Zostaną usunięte wcześniej podane dla %1 ""%2"" uprawnienia do korzystania z zasobów zewnętrznych:';
						|tr = 'Daha önce %1""%2"" kullanıcısına harici kaynakları kullanması için verilen aşağıdaki izinler kaldırılacaktır:'"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Pictogram"] = Pictogram;
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, ItemsToDelete, False);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		If ItemsToAdd.Count() > 0 Or ItemsToDelete.Count() > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Generates a presentation of external resource permission administration operations.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - in which an operation presentation will be displayed,
//  Template - SpreadsheetDocument - received from the PermissionsPresentations report template,
//  AdministrationOperations - ValueTable - See
//                              DataProcessors.ExternalResourcePermissionSetup.AdministrationOperationsInRequests().
//
Procedure GenerateOperationsPresentation(SpreadsheetDocument, Val Template, Val AdministrationOperations)
	
	PictureToRemove = PictureLib.Delete;
	For Each LongDesc In AdministrationOperations Do
		
		If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			
			IsConfigurationProfile = (LongDesc.ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
			
			If IsConfigurationProfile Then
				
				Dictionary = ConfigurationModuleDictionary();
				ModuleDescription = Metadata.Synonym;
				
			Else
				
				ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
					LongDesc.ProgramModuleType, LongDesc.ModuleID);
				Dictionary = SafeModeManagerInternal.ExternalModuleManager(ProgramModule).ExternalModuleContainerDictionary();
				ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
				
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sẽ xóa hồ sơ bảo mật đối với %1 ""%2"".';
						|ru = 'Будет удален профиль безопасности для %1 ""%2"".';
						|en = 'Security profile will be deleted for %2 %1.'; fa = 'Security profile will be deleted for %2 %1.';
						|it = 'Il profilo di sicurezza per %1 ""%2"" verrà eliminato.';
						|pl = 'Profil bezpieczeństwa dla %1 ""%2"" zostanie usunięty.';
						|tr = 'Güvenlik profili silinecek%1 ""%2"".'"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
			EndIf;
			Area.Parameters["Pictogram"] = PictureToRemove;
			SpreadsheetDocument.Put(Area);
			SpreadsheetDocument.PutHorizontalPageBreak();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates a permission presentation.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a document, in which an operation presentation will be displayed.
//  Template - SpreadsheetDocument - a document received from the PermissionsPresentations report template.
//  PermissionsSets - See DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow
//  AsRequired - Boolean - indicates whether terms of "the following resources are required" kind are used in the presentation instead of
//                          "the following resources will be granted."
//
Procedure GeneratePermissionsPresentation(Val SpreadsheetDocument, Val Template, Val PermissionsSets, Val AsRequired = False)
	
	OffsetArea = Template.GetArea("Indent");
	
	Types = PermissionsSets.Copy(); // ValueTable
	Types.GroupBy("Type");
	Types.Columns.Add("Order", New TypeDescription("Number"));
	
	SortingOrder = PermissionsTypesSortingOrder();
	For Each TypeRow In Types Do
		TypeRow.Order = SortingOrder[TypeRow.Type];
	EndDo;
	
	Types.Sort("Order ASC");
	
	For Each TypeRow In Types Do
		
		PermissionType = TypeRow.Type;
		
		Filter = New Structure();
		Filter.Insert("Type", TypeRow.Type);
		PermissionsRows = PermissionsSets.FindRows(Filter);
		
		Count = 0;
		For Each PermissionsRow In PermissionsRows Do
			Count = Count + PermissionsRow.Permissions.Count();
		EndDo;
		
		If Count > 0 Then
			
			GroupArea = Template.GetArea("Group" + PermissionType);
			FillPropertyValues(GroupArea.Parameters, New Structure("Count", Count));
			SpreadsheetDocument.Put(GroupArea);
			
			SpreadsheetDocument.StartRowGroup(PermissionType, True);
			
			HeaderArea = Template.GetArea("Header" + PermissionType);
			SpreadsheetDocument.Put(HeaderArea);
			
			RowArea = Template.GetArea("Row" + PermissionType);
			
			For Each PermissionsRow In PermissionsRows Do
				
				For Each KeyAndValue In PermissionsRow.Permissions Do
					
					Resolution = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
					
					If PermissionType = "AttachAddin" Then
						
						FillPropertyValues(RowArea.Parameters, Resolution);
						SpreadsheetDocument.Put(RowArea);
						
						SpreadsheetDocument.StartRowGroup(Resolution.TemplateName);
						
						PermissionAddition = PermissionsRow.PermissionsAdditions.Get(KeyAndValue.Key);
						If PermissionAddition = Undefined Then
							PermissionAddition = New Structure();
						Else
							PermissionAddition = Common.ValueFromXMLString(PermissionAddition);
						EndIf;
						
						For Each AdditionKeyAndValue In PermissionAddition Do
							
							FileRowArea = Template.GetArea("AttachAddinRowAdditional");
							
							FillPropertyValues(FileRowArea.Parameters, AdditionKeyAndValue);
							SpreadsheetDocument.Put(FileRowArea);
							
						EndDo;
						
						SpreadsheetDocument.EndRowGroup();
						
					Else
						
						PermissionAddition = New Structure();
						
						If PermissionType = "FileSystemAccess" Then
							
							If Resolution.Path = "/temp" Then
								PermissionAddition.Insert("Path", NStr("vi = 'Thư mục tệp tạm thời';
																		|ru = 'Папка временных файлов';
																		|en = 'Temporary files folder'; fa = 'Temporary files folder';
																		|it = 'Cartella dei file temporanei';
																		|pl = 'Folder plików czasowych';
																		|tr = 'Geçici dosyalar klasörü'"));
							EndIf;
							
							If Resolution.Path = "/bin" Then
								PermissionAddition.Insert("Path", NStr("vi = 'Thư mục có cài đặt máy chủ 1C:Enterprise';
																		|ru = 'Папка, в которой установлен сервер 1С:Предприятия';
																		|en = 'Folder where 1C:Enterprise server is installed'; fa = 'Folder where 1C:Enterprise server is installed';
																		|it = 'Cartella dove è installato il server 1C:Enterprise';
																		|pl = 'Folder, w którym jest zainstalowany serwer 1С:Enterprise';
																		|tr = '1C:Enterprise sunucusunun kurulu olduğu klasör'"));
							EndIf;
							
						EndIf;
						
						FillPropertyValues(RowArea.Parameters, Resolution);
						FillPropertyValues(RowArea.Parameters, PermissionAddition);
						
						SpreadsheetDocument.Put(RowArea);
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			SpreadsheetDocument.EndRowGroup();
			
			SpreadsheetDocument.Put(OffsetArea);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
//
Function PermissionsTypesSortingOrder()
	
	Result = New Structure();
	
	Result.Insert("InternetResourceAccess", 1);
	Result.Insert("FileSystemAccess", 2);
	Result.Insert("AttachAddin", 3);
	Result.Insert("CreateComObject", 4);
	Result.Insert("RunApplication", 5);
	Result.Insert("ExternalModule", 6);
	Result.Insert("ExternalModulePrivilegedModeAllowed", 7);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a dictionary of configuration properties.
//
// Returns:
//   Structure:
//                         * Nominative - a module kind synonym in the nominative case.
//                         * Genitive - a module kind synonym in the genitive case.
//
Function ConfigurationModuleDictionary()
	
	Result = New Structure();
	
	Result.Insert("Nominative", NStr("vi = 'Ứng dụng';
									|ru = 'Приложение';
									|en = 'App'; fa = 'برنامه';
									|it = 'Приложение';
									|pl = 'App';
									|tr = 'Uygulama'"));
	Result.Insert("Genitive", NStr("vi = 'Ứng dụng';
									|ru = 'Приложения';
									|en = 'Apps'; fa = 'Apps';
									|it = 'Приложения';
									|pl = 'Apps';
									|tr = 'Uygulamalar'"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf