///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtServer
Var SubordinateCatalogs;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	SelectCollectionsWhenAllObjectsSelected = Parameters.SelectCollectionsWhenAllObjectsSelected;
	RememberSelectedObjectsSections      = Parameters.RememberSelectedObjectsSections;
	MetadataObjectsToSelectCollection   = Parameters.MetadataObjectsToSelectCollection;
	ParentSubsystems                  = Parameters.ParentSubsystems;
	FilterByMetadataObjects              = Parameters.FilterByMetadataObjects;
	UUIDSource         = Parameters.UUIDSource;
	ObjectsGroupMethod               = Parameters.ObjectsGroupMethod;
	ShouldSelectExternalDataSourceTables  = Parameters.ShouldSelectExternalDataSourceTables;
	SelectedMetadataObjects              = Common.CopyRecursive(Parameters.SelectedMetadataObjects);
	
	ChooseRefs          = Parameters.ChooseRefs;
	SubsystemsWithCIOnly     = Parameters.SubsystemsWithCIOnly;
	SelectSingle      = Parameters.SelectSingle;
	ChoiceInitialValue = Parameters.ChoiceInitialValue;
	
	FillSelectedMetadataObjects();
	
	If FilterByMetadataObjects.Count() > 0 Then
		MetadataObjectsToSelectCollection.Clear();
		For Each MetadataObjectFullName In FilterByMetadataObjects Do
			BaseTypeName = Common.BaseTypeNameByMetadataObject(
				Common.MetadataObjectByFullName(MetadataObjectFullName.Value));
			If MetadataObjectsToSelectCollection.FindByValue(BaseTypeName) = Undefined Then
				MetadataObjectsToSelectCollection.Add(BaseTypeName);
			EndIf;
		EndDo;
	ElsIf ChooseRefs Then
		ModuleMetadataObjectIds = Common.CommonModule(
			"Catalogs.MetadataObjectIDs");
		ValidCollections = ModuleMetadataObjectIds.ValidCollections();
		If Not ValueIsFilled(MetadataObjectsToSelectCollection) Then
			For Each ValidCollection In ValidCollections Do
				MetadataObjectsToSelectCollection.Add(ValidCollection);
			EndDo;
		Else
			SuitableCollections = New ValueList;
			For Each ListItem In MetadataObjectsToSelectCollection Do
				If ValidCollections.Find(ListItem.Value) <> Undefined Then
					SuitableCollections.Add().Value = ListItem.Value;
				EndIf;
			EndDo;
			If SuitableCollections.Count() = 0 Then
				SuitableCollections.Add().Value = ValidCollections[0];
			EndIf;
			MetadataObjectsToSelectCollection = SuitableCollections;
		EndIf;
	EndIf;
	
	If SubsystemsWithCIOnly Then
		SubsystemsList = Metadata.Subsystems;
		FillSubsystemList(SubsystemsList);
	EndIf;
	
	If SelectSingle Then
		Items.Check.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	
	If Not ValueIsFilled(ChoiceInitialValue)
		And SelectSingle
		And Parameters.SelectedMetadataObjects.Count() = 1 Then
		ChoiceInitialValue = Parameters.SelectedMetadataObjects[0].Value;
	EndIf;
	
	If Not ValueIsFilled(ObjectsGroupMethod) Then
		ObjectsGroupMethod = "BySections";
		
	ElsIf ObjectsGroupMethod = "ByKinds"
	      Or ObjectsGroupMethod = "BySections" Then
		
		Items.ObjectsGroupMethod.Visible = False;
	Else
		GroupingMethods = StrSplit(Parameters.ObjectsGroupMethod, ",", False);
		If GroupingMethods[0] = "ByKinds" Then
			ObjectsGroupMethod = "ByKinds";
		Else
			ObjectsGroupMethod = "BySections";
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillObjectsTree(True);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not Items.ObjectsGroupMethod.Visible
	 Or Settings["ObjectsGroupMethod"] <> "ByKinds"
	   And Settings["ObjectsGroupMethod"] <> "BySections" Then
		
		Settings.Insert("ObjectsGroupMethod", ObjectsGroupMethod);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Form tree "Mark" field click event handler procedure.
&AtClient
Procedure CheckOnChange(Item)
	
	FlagDone = True;
	OnMarkTreeItem(CurrentItem.CurrentData);
	
EndProcedure

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	If FlagDone Then
		SelectedObjectsAddresses.Clear();
		UpdateSelectedMetadataObjectsCollection();
	EndIf;
	
	FillObjectsTree();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMetadataObjectsTree

&AtClient
Procedure MetadataObjectsTreeSelection(Item, RowSelected, Field, StandardProcessing)

	If SelectSingle Then
		
		SelectExecute();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectExecute()
	
	If SelectSingle Then
		
		curData = Items.MetadataObjectsTree.CurrentData;
		If curData <> Undefined
			And curData.IsMetadataObject Then
			
			SelectedMetadataObjects.Clear();
			SelectedMetadataObjects.Add(curData.FullName, curData.Presentation);
			
		Else
			Return;
		EndIf;
	Else
		UpdateSelectedMetadataObjectsCollection();
	EndIf;
	
	If ChooseRefs Then
		SelectRefs(SelectedMetadataObjects);
	EndIf;
	
	If CallbackDescriptionOnClose = Undefined Then
		Notify("SelectMetadataObjects", SelectedMetadataObjects, UUIDSource);
	EndIf;
	
	Close(SelectedMetadataObjects);
	
EndProcedure

&AtClient
Procedure CloseExecute()
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSelectedMetadataObjects()
	
	MetadataObjects = SelectedMetadataObjects.UnloadValues();
	
	If RememberSelectedObjectsSections
		And SelectedMetadataObjects.Count() > 0 And StrStartsWith(SelectedMetadataObjects[0].Presentation, "./") Then
		For Each Item In SelectedMetadataObjects Do
			SelectedObjectsAddresses.Add(Item.Presentation, Item.Value);
		EndDo;
	EndIf;
	
	If Not ChooseRefs Then
		Return;
	EndIf;
	
	References = New Array;
	
	For Each MetadataObject In MetadataObjects Do 
		If TypeOf(MetadataObject) = Type("CatalogRef.MetadataObjectIDs")
			Or TypeOf(MetadataObject) = Type("CatalogRef.ExtensionObjectIDs") Then 
			
			References.Add(MetadataObject);
		EndIf;
	EndDo;
	
	If References.Count() = 0 Then 
		Return;
	EndIf;
	
	MetadataObjects = Common.MetadataObjectsByIDs(References, False);
	For Each ListItem In SelectedMetadataObjects Do 
		MetadataObject = MetadataObjects[ListItem.Value];
		If MetadataObject <> Undefined And MetadataObject <> Null Then 
			ListItem.Value = MetadataObject.FullName();
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillSubsystemList(SubsystemsList) 
	For Each Subsystem In SubsystemsList Do
		If Subsystem.IncludeInCommandInterface Then
			ItemsOfSubsystemsWithCommandInterface.Add(Subsystem.FullName());
		EndIf;
		
		If Subsystem.Subsystems.Count() > 0 Then
			FillSubsystemList(Subsystem.Subsystems);
		EndIf;
	EndDo;
EndProcedure

// Populates the tree of configuration object values.
// If value list MetadataObjectsToSelectCollection is not empty, pass a metadata object collection list.
// If metadata objects from the tree are found in the "SelectedMetadataObjects", they are marked as selected.
//  
// 
//
&AtServer
Procedure MetadataObjectTreeFill()
	
	MetadataObjectsTree.GetItems().Clear();
	
	MetadataObjects = New ValueTable;
	MetadataObjects.Columns.Add("Name");
	MetadataObjects.Columns.Add("Synonym");
	MetadataObjects.Columns.Add("Picture");
	MetadataObjects.Columns.Add("IsCommonCollection");
	MetadataObjects.Columns.Add("FullName");
	MetadataObjects.Columns.Add("Parent");
	
	CollectionNewRow("Subsystems",                   NStr("vi = 'Phân hệ';
															|ru = 'Подсистемы';
															|en = 'Subsystems'; fa = 'Subsystems';
															|it = 'Sottosistemi';
															|pl = 'Subsystems';
															|tr = 'Alt sistemler'"),                     PictureLib.MetadataSubsystems,                   True, MetadataObjects);
	CollectionNewRow("CommonModules",                  NStr("vi = 'Mô-đun chung';
															|ru = 'Общие модули';
															|en = 'Common modules'; fa = 'Common modules';
															|it = 'Moduli comuni';
															|pl = 'Wspólne moduły';
															|tr = 'Ortak modüller'"),                   PictureLib.MetadataCommonModules,                  True, MetadataObjects);
	CollectionNewRow("SessionParameters",              NStr("vi = 'Tham số phiên làm việc';
															|ru = 'Параметры сеанса';
															|en = 'Session parameters'; fa = 'Session parameters';
															|it = 'Parametri della sessione';
															|pl = 'Parametry sesji';
															|tr = 'Oturum parametreleri'"),               PictureLib.MetadataSessionParameters,              True, MetadataObjects);
	CollectionNewRow("Roles",                         NStr("vi = 'Vai trò';
															|ru = 'Роли';
															|en = 'Roles'; fa = 'نقش‌ها';
															|it = 'Funzioni';
															|pl = 'Roles';
															|tr = 'Roller'"),                           PictureLib.RoleMetadata,                         True, MetadataObjects);
	CollectionNewRow("CommonAttributes",               NStr("vi = 'Mục tin chung';
															|ru = 'Общие реквизиты';
															|en = 'Common attributes'; fa = 'Common attributes';
															|it = 'Requisiti generali';
															|pl = 'Informacje ogólne';
															|tr = 'Ortak öznitelikler'"),                PictureLib.MetadataCommonAttributes,               True, MetadataObjects);
	CollectionNewRow("ExchangePlans",                  NStr("vi = 'Sơ đồ trao đổi';
															|ru = 'Планы обмена';
															|en = 'Exchange plans'; fa = 'Exchange plans';
															|it = 'Piani di scambio';
															|pl = 'Plany wymiany';
															|tr = 'Değiştirme planları'"),                   PictureLib.MetadataExchangePlans,                  True, MetadataObjects);
	CollectionNewRow("FilterCriteria",               NStr("vi = 'Tiêu chí lọc';
															|ru = 'Критерии отбора';
															|en = 'Filter criteria'; fa = 'معیارهای فیلتر';
															|it = 'Criteri di selezione';
															|pl = 'Kryteria wyboru';
															|tr = 'Filtre kriteri'"),                PictureLib.MetadataFilterCriteria,               True, MetadataObjects);
	CollectionNewRow("EventSubscriptions",            NStr("vi = 'Đăng ký sự kiện';
															|ru = 'Подписки на события';
															|en = 'Event subscriptions'; fa = 'Event subscriptions';
															|it = 'Notifiche degli eventi';
															|pl = 'Subskrypcje zdarzeń';
															|tr = 'Etkinlik abonelikleri'"),            PictureLib.MetadataEventSubscriptions,            True, MetadataObjects);
	CollectionNewRow("ScheduledJobs",          NStr("vi = 'Nhiệm vụ thường kỳ';
													|ru = 'Регламентные задания';
													|en = 'Scheduled jobs'; fa = 'کارهای زمان‌بندی‌شده';
													|it = 'Task pianificati';
													|pl = 'Planowe zadania';
													|tr = 'Zamanlanmış görevler'"),           PictureLib.MetadataScheduledJobs,          True, MetadataObjects);
	CollectionNewRow("FunctionalOptions",          NStr("vi = 'Tùy chọn chức năng';
														|ru = 'Функциональные опции';
														|en = 'Functional options'; fa = 'گزینه‌های کاربردی';
														|it = 'Opzioni funzionali';
														|pl = 'Opcje funkcjonalne';
														|tr = 'İşlevsel opsiyonlar'"),           PictureLib.MetadataFunctionalOptions,          True, MetadataObjects);
	CollectionNewRow("FunctionalOptionsParameters", NStr("vi = 'Tham số tùy chọn chức năng';
														|ru = 'Параметры функциональных опций';
														|en = 'Functional option parameters'; fa = 'Functional option parameters';
														|it = 'Parametri delle opzioni funzionali';
														|pl = 'Parametry opcji funkcjonalnych';
														|tr = 'İşlevsel opsiyon parametreleri'"), PictureLib.MetadataFunctionalOptionsParameters, True, MetadataObjects);
	CollectionNewRow("SettingsStorages",            NStr("vi = 'Kho chứa tùy chỉnh';
														|ru = 'Хранилища настроек';
														|en = 'Settings storages'; fa = 'Settings storages';
														|it = 'Repository delle impostazioni';
														|pl = 'Miejsca przechowywania ustawień';
														|tr = 'Depolama alanı ayarı'"),             PictureLib.MetadataSettingsStorage,            True, MetadataObjects);
	CollectionNewRow("CommonForms",                   NStr("vi = 'Biểu mẫu chung';
															|ru = 'Общие формы';
															|en = 'Common forms'; fa = 'Common forms';
															|it = 'Form comuni';
															|pl = 'Wspólne formularze';
															|tr = 'Ortak formlar'"),                    PictureLib.MetadataCommonForms,                   True, MetadataObjects);
	CollectionNewRow("CommonCommands",                 NStr("vi = 'Lệnh chung';
															|ru = 'Общие команды';
															|en = 'Common commands'; fa = 'فرمان‌های مشترک';
															|it = 'Comandi comuni';
															|pl = 'Polecenia wspólne';
															|tr = 'Ortak komutlar'"),                  PictureLib.MetadataCommonCommands,                 True, MetadataObjects);
	CollectionNewRow("CommandGroups",                 NStr("vi = 'Nhóm lệnh';
															|ru = 'Группы команд';
															|en = 'Command groups'; fa = 'Command groups';
															|it = 'I gruppi di comandi';
															|pl = 'Grupy poleceń';
															|tr = 'Komut gruplar'"),                  PictureLib.MetadataCommandGroups,                 True, MetadataObjects);
	CollectionNewRow("Interfaces",                   NStr("vi = 'Giao diện';
															|ru = 'Интерфейсы';
															|en = 'Interfaces'; fa = 'Interfaces';
															|it = 'Interfacce';
															|pl = 'Interfaces';
															|tr = 'Arayüzler'"),                     Undefined,                                              True, MetadataObjects);
	CollectionNewRow("CommonTemplates",                  NStr("vi = 'Khuôn in chung';
																|ru = 'Общие макеты';
																|en = 'Common templates'; fa = 'Common templates';
																|it = 'Layout comuni';
																|pl = 'Wspólne szblony';
																|tr = 'Ortak şablonlar'"),                   PictureLib.MetadataCommonTemplates,                  True, MetadataObjects);
	CollectionNewRow("CommonPictures",                NStr("vi = 'Hình vẽ chung';
															|ru = 'Общие картинки';
															|en = 'Common pictures'; fa = 'Common pictures';
															|it = 'Immagini comuni';
															|pl = 'Wspólne obrazy';
															|tr = 'Ortak resimler'"),                 PictureLib.MetadataCommonPictures,                True, MetadataObjects);
	CollectionNewRow("XDTOPackages",                   NStr("vi = 'Gói XDTO';
															|ru = 'XDTO-пакеты';
															|en = 'XDTO packages'; fa = 'XDTO packages';
															|it = 'Pacchetti XDTO';
															|pl = 'XDTO packages';
															|tr = 'XDTO-paketleri'"),                    PictureLib.MetadataXDTOPackages,                   True, MetadataObjects);
	CollectionNewRow("WebServices",                   NStr("vi = 'Web-service';
															|ru = 'Web-сервисы';
															|en = 'Web services'; fa = 'Web services';
															|it = 'Servizi web';
															|pl = 'Web services';
															|tr = 'Web servisleri'"),                    PictureLib.MetadataWebServices,                   True, MetadataObjects);
	CollectionNewRow("HTTPServices",                  NStr("vi = 'Dịch vụ HTTP';
															|ru = 'HTTP-сервисы';
															|en = 'HTTP services'; fa = 'HTTP services';
															|it = 'Servizi HTTP';
															|pl = 'HTTP services';
															|tr = 'HTTP-servisler'"),                   PictureLib.MetadataHTTPServices,                  True, MetadataObjects);
	CollectionNewRow("WSReferences",                     NStr("vi = 'Tham chiếu WS';
																|ru = 'WS-ссылки';
																|en = 'WS references'; fa = 'WS references';
																|it = 'Link WS';
																|pl = 'WS references';
																|tr = 'WS bağlantıları'"),                      PictureLib.MetadataWSReferences,                     True, MetadataObjects);
	CollectionNewRow("Styles",                        NStr("vi = 'Kiểu cách';
															|ru = 'Стили';
															|en = 'Styles'; fa = 'Styles';
															|it = 'Stili';
															|pl = 'Styles';
															|tr = 'Stiller'"),                          PictureLib.MetadataStyles,                        True, MetadataObjects);
	CollectionNewRow("Languages",                        NStr("vi = 'Ngôn ngữ';
																|ru = 'Языки';
																|en = 'Languages'; fa = 'زبان‌ها';
																|it = 'Lingue';
																|pl = 'Languages';
																|tr = 'Diller'"),                          PictureLib.MetadataLanguages,                        True, MetadataObjects);
	
	CollectionNewRow("Constants",                    NStr("vi = 'Hằng';
															|ru = 'Константы';
															|en = 'Constants'; fa = 'ثابت‌ها';
															|it = 'Costanti';
															|pl = 'Constants';
															|tr = 'Sabitler'"),                      PictureLib.MetadataConstants,               False, MetadataObjects);
	CollectionNewRow("Catalogs",                  NStr("vi = 'Danh mục';
														|ru = 'Справочники';
														|en = 'Catalogs'; fa = 'فهرست‌ها';
														|it = 'Directory';
														|pl = 'Kartoteki';
														|tr = 'Kataloglar'"),                    PictureLib.MetadataCatalogs,             False, MetadataObjects);
	CollectionNewRow("Documents",                    NStr("vi = 'Chứng từ';
															|ru = 'Документы';
															|en = 'Documents'; fa = 'اسناد';
															|it = 'Documenti';
															|pl = 'Documents';
															|tr = 'Belgeler'"),                      PictureLib.MetadataDocuments,               False, MetadataObjects);
	CollectionNewRow("DocumentJournals",            NStr("vi = 'Nhật ký văn bản';
														|ru = 'Журналы документов';
														|en = 'Document journals'; fa = 'Document journals';
														|it = 'Registri dei documenti';
														|pl = 'Dzienniki dokumentów';
														|tr = 'Belge günlükleri'"),             PictureLib.MetadataDocumentJournals,       False, MetadataObjects);
	CollectionNewRow("Enums",                 NStr("vi = 'Chuyển khoản';
													|ru = 'Перечисления';
													|en = 'Enumerations'; fa = 'Enumerations';
													|it = 'Enumerazioni';
													|pl = 'Enumerations';
													|tr = 'Transferler'"),                   PictureLib.EnumerationMetadata,            False, MetadataObjects);
	CollectionNewRow("Reports",                       NStr("vi = 'Báo cáo';
															|ru = 'Отчеты';
															|en = 'Reports'; fa = 'گزارش‌ها';
															|it = 'Report';
															|pl = 'Reports';
															|tr = 'Raporlar'"),                         PictureLib.MetadataReports,                  False, MetadataObjects);
	CollectionNewRow("DataProcessors",                    NStr("vi = 'Bộ xử lý';
																|ru = 'Обработки';
																|en = 'Data processors'; fa = 'Data processors';
																|it = 'Elaborazioni';
																|pl = 'Data processors';
																|tr = 'Veri işlemcileri'"),                      PictureLib.MetadataDataProcessors,               False, MetadataObjects);
	CollectionNewRow("ChartsOfCharacteristicTypes",      NStr("vi = 'Hệ thống dạng đặc tính';
																|ru = 'Планы видов характеристик';
																|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
																|it = 'Piani dei tipi di caratteristiche';
																|pl = 'Plany rodzajów charakterystyk';
																|tr = 'Özellik türü listeleri'"),      PictureLib.MetadataChartsOfCharacteristicTypes, False, MetadataObjects);
	CollectionNewRow("ChartsOfAccounts",                  NStr("vi = 'Hệ thống tài khoản';
																|ru = 'Планы счетов';
																|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
																|it = 'Piani dei conti';
																|pl = 'Plany rachunków';
																|tr = 'Hesap planları'"),                   PictureLib.MetadataChartsOfAccounts,             False, MetadataObjects);
	CollectionNewRow("ChartsOfCalculationTypes",            NStr("vi = 'Hệ thống dạng tính toán';
																|ru = 'Планы видов расчета';
																|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
																|it = 'Piani dei tipi di calcolo';
																|pl = 'Plany rodzajów obliczeń';
																|tr = 'Hesaplama türü planları'"),            PictureLib.MetadataChartsOfCalculationTypes,       False, MetadataObjects);
	CollectionNewRow("InformationRegisters",             NStr("vi = 'Biểu ghi thông tin';
																|ru = 'Регистры сведений';
																|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
																|it = 'Registri delle informazioni';
																|pl = 'Rejestry informacji';
																|tr = 'Bilgi kayıtları'"),              PictureLib.MetadataInformationRegisters,        False, MetadataObjects);
	CollectionNewRow("AccumulationRegisters",           NStr("vi = 'Biểu ghi tích lũy';
															|ru = 'Регистры накопления';
															|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
															|it = 'Registri di accumulo';
															|pl = 'Rejestry kumulacji';
															|tr = 'Birikim kayıtları'"),            PictureLib.MetadataAccumulationRegisters,      False, MetadataObjects);
	CollectionNewRow("AccountingRegisters",          NStr("vi = 'Biểu ghi kế toán';
															|ru = 'Регистры бухгалтерии';
															|en = 'Accounting registers'; fa = 'Accounting registers';
															|it = 'Registri contabilità';
															|pl = 'Rejestry księgowości';
															|tr = 'Muhasebe kayıtları'"),           PictureLib.MetadataAccountingRegisters,     False, MetadataObjects);
	CollectionNewRow("CalculationRegisters",              NStr("vi = 'Biểu ghi tính toán';
																|ru = 'Регистры расчета';
																|en = 'Calculation registers'; fa = 'Calculation registers';
																|it = 'Registri di calcolo';
																|pl = 'Rejestry rozliczenia';
																|tr = 'Mutabakat işlemleri kayıtları'"),               PictureLib.MetadataCalculationRegisters,         False, MetadataObjects);
	CollectionNewRow("BusinessProcesses",               NStr("vi = 'Quy trình nghiệp vụ';
															|ru = 'Бизнес-процессы';
															|en = 'Business processes'; fa = 'فرایندهای تجاری';
															|it = 'Processi aziendali';
															|pl = 'Business processes';
															|tr = 'İş süreçleri'"),                PictureLib.MetadataBusinessProcesses,          False, MetadataObjects);
	CollectionNewRow("Tasks",                       NStr("vi = 'Nhiệm vụ';
														|ru = 'Задачи';
														|en = 'Tasks'; fa = 'وظایف';
														|it = 'Obiettivi';
														|pl = 'Tasks';
														|tr = 'Görevler'"),                         PictureLib.MetadataTasks,                  False, MetadataObjects);
	CollectionNewRow("ExternalDataSources",       NStr("vi = 'Nguồn dữ liệu ngoài';
														|ru = 'Внешние источники данных';
														|en = 'External data sources'; fa = 'External data sources';
														|it = 'Fonti dati esterne';
														|pl = 'Zewnętrzne źródła danych';
														|tr = 'Harici veri kaynakları'"),       PictureLib.MetadataExternalDataSources,  False, MetadataObjects);
	
	// Create predefined items.
	ItemParameters = MetadataObjectTreeItemParameters();
	ItemParameters.Name = Metadata.Name;
	ItemParameters.Synonym = Metadata.Synonym;
	ItemParameters.Picture = PictureLib.MetadataConfiguration;
	ItemParameters.Parent = MetadataObjectsTree;
	ConfigurationItem = NewTreeRow(ItemParameters);
	
	ItemParameters = MetadataObjectTreeItemParameters();
	ItemParameters.Name = "Overall";
	ItemParameters.Synonym = NStr("vi = 'Chung';
									|ru = 'Общие';
									|en = 'Common'; fa = 'مشترک';
									|it = 'Generali';
									|pl = 'Common';
									|tr = 'Ortak'");
	ItemParameters.Picture = PictureLib.MetadataCommon;
	ItemParameters.Parent = ConfigurationItem;
	ItemCommon = NewTreeRow(ItemParameters);
	
	For Each MetadataObject In MetadataObjects Do
		If MetadataObjectsToSelectCollection.Count() = 0
			Or MetadataObjectsToSelectCollection.FindByValue(MetadataObject.Name) <> Undefined Then
			MetadataObject.Parent = ?(MetadataObject.IsCommonCollection, ItemCommon, ConfigurationItem);
			AddMetadataObjectTreeItem(MetadataObject, ?(MetadataObject.Name = "Subsystems", Metadata.Subsystems, Undefined));
		EndIf;
	EndDo;
	
	If ItemCommon.GetItems().Count() = 0 Then
		ConfigurationItem.GetItems().Delete(ItemCommon);
	EndIf;
	
EndProcedure

// Returns a metadata object tree item parameter structure.
//
// Returns:
//   Structure:
//     * Name           - String - Parent item name.
//     * FullName     - String
//     * Synonym       - String - Parent item synonym.
//     * Check       - Number - Initial mark of a collection or metadata object.
//     * Picture      - Picture - Parent item picture.
//     * Parent      - ValueTreeRow
//
&AtServer
Function MetadataObjectTreeItemParameters()
	
	Result = New Structure;
	Result.Insert("Name", "");
	Result.Insert("FullName", "");
	Result.Insert("Synonym", "");
	Result.Insert("Check", 0);
	Result.Insert("Picture", Undefined);
	Result.Insert("Parent", Undefined);
	
	Return Result;
	
EndFunction

// Adds a new row to the form value tree
// and fills the full row set from metadata by the passed parameter.
//
// If the Subsystems parameter is filled, the function is called recursively for all child subsystems.
//
// Parameters:
//   ItemParameters - See MetadataObjectTreeItemParameters
//   Subsystems - MetadataObjectCollection - If filled, it contains Metadata.Subsystems value (an item collection).
//   Check       - Boolean - Flag indicating whether a check for subordination to parent subsystems is required.
// 
// Returns:
//  FormDataTreeItem
//
&AtServer
Function AddMetadataObjectTreeItem(ItemParameters, Subsystems = Undefined, Check = True,
			ExternalDataSourceTableCollection = Undefined)
	
	// Checking whether command interface is available in tree leaves only.
	If Subsystems <> Undefined And SubsystemsWithCIOnly 
		And Not IsBlankString(ItemParameters.FullName) 
		And ItemsOfSubsystemsWithCommandInterface.FindByValue(ItemParameters.FullName) = Undefined Then
		Return Undefined;
	EndIf;
	
	If Subsystems = Undefined Then
		If ExternalDataSourceTableCollection = Undefined Then
			MetadataCollection = Metadata[ItemParameters.Name];
		Else
			MetadataCollection = ExternalDataSourceTableCollection;
		EndIf;
		
		If MetadataCollection.Count() = 0 Then
			
			// In case there's no metadata object from the given branch. 
			// For example, if no accounting register is present,
			// the "Accounting registers" should be skipped.
			Return Undefined;
			
		EndIf;
		
		NewRow = NewTreeRow(ItemParameters, Subsystems <> Undefined And Subsystems <> Metadata.Subsystems);
		NewRow.ThisCollectionObjects = True;
		
		AddExternalDataSourceTables = ShouldSelectExternalDataSourceTables
			And ItemParameters.Name = "ExternalDataSources";
		
		For Each MetadataCollectionItem In MetadataCollection Do
			
			If FilterByMetadataObjects.Count() > 0
				And FilterByMetadataObjects.FindByValue(MetadataCollectionItem.FullName()) = Undefined Then
				Continue;
			EndIf;
			
			ItemParameters = MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.Parent = NewRow;
			If ExternalDataSourceTableCollection <> Undefined Then
				ItemParameters.Picture = PictureLib.ExternalDataSourceTable;
			Else
				ItemParameters.Picture = ?(ItemParameters.Parent.Picture <> Undefined,
					ItemParameters.Parent.Picture, PictureInDesigner(MetadataCollectionItem));
			EndIf;
			
			If AddExternalDataSourceTables Then
				AddMetadataObjectTreeItem(ItemParameters,,, MetadataCollectionItem.Tables);
			Else
				NewTreeRow(ItemParameters, True);
			EndIf;
		EndDo;
		
		Return NewRow;
		
	EndIf;
		
	If Subsystems.Count() = 0 And ItemParameters.Name = "Subsystems" Then
		// If no subsystems are found, the Subsystems root should not be added.
		Return Undefined;
	EndIf;
	
	NewRow = NewTreeRow(ItemParameters, Subsystems <> Undefined And Subsystems <> Metadata.Subsystems);
	NewRow.ThisCollectionObjects = (Subsystems = Metadata.Subsystems);
	
	For Each MetadataCollectionItem In Subsystems Do
		
		If Not Check
			Or ParentSubsystems.Count() = 0
			Or ParentSubsystems.FindByValue(MetadataCollectionItem.Name) <> Undefined Then
			
			ItemParameters = MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.Parent = NewRow;
			ItemParameters.Picture = PictureInDesigner(MetadataCollectionItem);
			AddMetadataObjectTreeItem(ItemParameters, MetadataCollectionItem.Subsystems, False);
		EndIf;
	EndDo;
	
	Return NewRow;
	
EndFunction

&AtServer
Function NewTreeRow(RowParameters, IsMetadataObject = False)
	
	Collection = RowParameters.Parent.GetItems();
	NewRow = Collection.Add();
	NewRow.Name                 = RowParameters.Name;
	NewRow.Presentation       = ?(ValueIsFilled(RowParameters.Synonym), RowParameters.Synonym, RowParameters.Name);
	NewRow.Picture            = RowParameters.Picture;
	NewRow.FullName           = RowParameters.FullName;
	NewRow.IsMetadataObject = IsMetadataObject;
	NewRow.Check = ?(SelectedMetadataObjects.FindByValue(RowParameters.FullName) <> Undefined
		Or IsMetadataObject And SelectedMetadataObjects.FindByValue(RowParameters.Parent.Name) <> Undefined, 1, 0);
	
	If NewRow.Check
	   And NewRow.IsMetadataObject
	   And Not ValueIsFilled(RowIdoftheFirstSelectedObject) Then
	
		RowIdoftheFirstSelectedObject = NewRow.GetID();
		If Not ValueIsFilled(CurrentLineIDOnOpen) Then
			CurrentLineIDOnOpen = RowIdoftheFirstSelectedObject;
		EndIf;
	EndIf;
	
	If NewRow.IsMetadataObject 
		And NewRow.FullName = ChoiceInitialValue Then
		CurrentLineIDOnOpen = NewRow.GetID();
	EndIf;
	
	Return NewRow;
	
EndFunction

// Adds a new row to configuration metadata object type
// value table.
//
// Parameters:
//   Name  - String - a metadata object name, or a metadata object kind name.
//   Synonym - String - a metadata object synonym.
//   Picture - Number - picture referring to the metadata object
//                      or to the metadata object type.
//   IsCommonCollection - Boolean - Flag indicating whether the current item has subitems.
//   Table - ValueTable
//
&AtServer
Procedure CollectionNewRow(Name, Synonym, Picture, IsCommonCollection, Table)
	
	NewRow = Table.Add();
	NewRow.Name               = Name;
	NewRow.Synonym           = Synonym;
	NewRow.Picture          = Picture;
	NewRow.IsCommonCollection = IsCommonCollection;
	
EndProcedure

&AtClient
Function ItemMarkValues(ParentItems1)
	
	HasMarkedItems    = False;
	HasUnmarkedItems = False;
	
	For Each ParentItem1 In ParentItems1 Do
		
		If ParentItem1.Check = 2 Or (HasMarkedItems And HasUnmarkedItems) Then
			HasMarkedItems    = True;
			HasUnmarkedItems = True;
			Break;
		ElsIf ParentItem1.IsMetadataObject Then
			HasMarkedItems    = HasMarkedItems    Or    ParentItem1.Check;
			HasUnmarkedItems = HasUnmarkedItems Or Not ParentItem1.Check;
		Else
			NestedItems = ParentItem1.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValues(NestedItems);
			HasMarkedItems    = HasMarkedItems    Or    ParentItem1.Check Or    NestedItemMarkValue;
			HasUnmarkedItems = HasUnmarkedItems Or Not ParentItem1.Check Or Not NestedItemMarkValue;
		EndIf;
	EndDo;
	
	If HasMarkedItems Then
		If HasUnmarkedItems Then
			Return 2;
		Else
			Return ?(SubsystemsWithCIOnly, 2, 1);
		EndIf;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Procedure MarkParentItemsAtServer(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ParentItems1 = Parent.GetItems();
	If ParentItems1.Count() = 0 Then
		Parent.Check = 0;
	ElsIf Item.Check = 2 Then
		Parent.Check = 2;
	Else
		Parent.Check = ItemMarkValuesAtServer(ParentItems1);
	EndIf;
	
	MarkParentItemsAtServer(Parent);

EndProcedure

&AtServer
Function ItemMarkValuesAtServer(ParentItems1)
	
	HasMarkedItems    = False;
	HasUnmarkedItems = False;
	
	For Each ParentItem1 In ParentItems1 Do
		
		If ParentItem1.Check = 2 Or (HasMarkedItems And HasUnmarkedItems) Then
			HasMarkedItems    = True;
			HasUnmarkedItems = True;
			Break;
		ElsIf ParentItem1.IsMetadataObject Then
			HasMarkedItems    = HasMarkedItems    Or    ParentItem1.Check;
			HasUnmarkedItems = HasUnmarkedItems Or Not ParentItem1.Check;
		Else
			NestedItems = ParentItem1.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValuesAtServer(NestedItems);
			HasMarkedItems    = HasMarkedItems    Or    ParentItem1.Check Or    NestedItemMarkValue;
			HasUnmarkedItems = HasUnmarkedItems Or Not ParentItem1.Check Or Not NestedItemMarkValue;
		EndIf;
	EndDo;
	
	Return ?(HasMarkedItems And HasUnmarkedItems, 2, ?(HasMarkedItems, 1, 0));
	
EndFunction

// Selects a mark of the metadata object
// collections that does not have metadata objects 
// or whose metadata object marks are selected.
//
// Parameters:
//   Element      - FormDataTreeItemCollection.
//
&AtServer
Procedure SetInitialCollectionMark(Parent)
	
	NestedItems = Parent.GetItems();
	
	For Each NestedItem In NestedItems Do
		If NestedItem.Check Then
			MarkParentItemsAtServer(NestedItem);
		EndIf;
		SetInitialCollectionMark(NestedItem);
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure SelectRefs(SelectedMetadataObjects)
	
	If SelectedMetadataObjects.Count() = 0 Then 
		Return;
	EndIf;
	
	MetadataObjectsDetails = SelectedMetadataObjects.UnloadValues();
	References = Common.MetadataObjectIDs(MetadataObjectsDetails, False);
	
	CurrentIndex = SelectedMetadataObjects.Count() - 1;
	While CurrentIndex >= 0 Do
		ListItem = SelectedMetadataObjects[CurrentIndex];
		Ref = References[ListItem.Value];
		If Ref <> Undefined Then 
			ListItem.Value = Ref;
		Else
			SelectedMetadataObjects.Delete(ListItem);
		EndIf;
		CurrentIndex = CurrentIndex - 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure MetadataObjectsTreeFillBySections()
	
	MetadataObjectsTree.GetItems().Clear();
	
	Branch1 = MetadataObjectsTree.GetItems().Add();
	Branch1.Name = Metadata.Name;
	Branch1.Presentation = Metadata.Synonym;
	Branch1.Address = ".";
	
	OutputCollection(Branch1, Metadata.Subsystems);
	
EndProcedure

&AtServer
Procedure OutputCollection(Val Branch1, Val MetadataObjectCollection)
	
	For Each MetadataObject In MetadataObjectCollection Do
		If TypeOf(Branch1) = Type("FormDataTreeItem") And MetadataObject.FullName() = Branch1.FullName Then
			Continue;
		EndIf;
		
		If Not MetadataObjectAvailable(MetadataObject) Then
			Continue;
		EndIf;
		
		NewBranch = Branch1.GetItems().Add();
		NewBranch.Name = MetadataObject.Name;
		NewBranch.FullName = MetadataObject.FullName();
		NewBranch.Presentation = MetadataObject.Presentation();
		NewBranch.Picture = PictureInInterface(MetadataObject);
		NewBranch.Address = ?(TypeOf(Branch1) = Type("FormDataTreeItem"), Branch1.Address + "/", "") + NewBranch.Presentation;
		
		If ValueIsFilled(SelectedObjectsAddresses) Then
			NewBranch.Check = ?(SelectedObjectsAddresses.FindByValue(NewBranch.Address) = Undefined, 0, 1);
		Else
			NewBranch.Check = ?(SelectedMetadataObjects.FindByValue(NewBranch.FullName) = Undefined, 0, 1);
		EndIf;
		
		If IsSubsystem(MetadataObject) Then
			OutputCollection(NewBranch, MetadataObject.Content);
			OutputCollection(NewBranch, MetadataObject.Subsystems);
			NewBranch.IsSubsection = MetadataObjectCollection <> Metadata.Subsystems;
		Else
			NewBranch.IsMetadataObject = True;
			
			If Common.IsDocumentJournal(MetadataObject) Then
				OutputCollection(NewBranch, MetadataObject.RegisteredDocuments);
			ElsIf Common.IsCatalog(MetadataObject) Then 
				OutputCollection(NewBranch, SubordinateCatalogs(MetadataObject));
			EndIf;
		EndIf;
		
		If IsSubsystem(MetadataObject) And NewBranch.GetItems().Count() = 0 Then
			IndexOf = Branch1.GetItems().IndexOf(NewBranch);
			Branch1.GetItems().Delete(IndexOf);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function PictureInInterface(MetadataObject)
	
	ObjectProperties = New Structure("Picture");
	FillPropertyValues(ObjectProperties, MetadataObject);
	If ValueIsFilled(ObjectProperties.Picture) Then
		Return ObjectProperties.Picture;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function PictureInDesigner(MetadataObject)
	
	ObjectKind = StrSplit(MetadataObject.FullName(), ".")[0];
	Images = New Structure(ObjectKind);
	FillPropertyValues(Images, PictureLib);
	
	Return Images[ObjectKind];
	
EndFunction

&AtServerNoContext
Function IsSubsystem(MetadataObject)
	Return StrStartsWith(MetadataObject.FullName(), "Subsystem");
EndFunction

&AtServer
Function MetadataObjectAvailable(MetadataObject)
	
	IsSubsystem = IsSubsystem(MetadataObject);
	IsDocumentJournal = Common.IsDocumentJournal(MetadataObject);
	
	If Not IsSubsystem Then
		IsObjectToSelect = Not ValueIsFilled(MetadataObjectsToSelectCollection);
		For Each ObjectKind In MetadataObjectsToSelectCollection.UnloadValues() Do
			If Metadata[ObjectKind].Contains(MetadataObject) Then
				IsObjectToSelect = True;
				Break;
			EndIf;
		EndDo;
		
		If Not IsObjectToSelect Then
			Return False;
		EndIf;
	EndIf;
	
	If Not Common.IsCatalog(MetadataObject)
		And Not Common.IsDocument(MetadataObject)
		And Not IsDocumentJournal
		And Not Common.IsChartOfCharacteristicTypes(MetadataObject)
		And Not Common.IsInformationRegister(MetadataObject)
		And Not Common.IsAccountingRegister(MetadataObject)
		And Not Common.IsAccumulationRegister(MetadataObject)
		And Not Common.IsCalculationRegister(MetadataObject)
		And Not Common.IsChartOfCharacteristicTypes(MetadataObject)
		And Not Common.IsChartOfAccounts(MetadataObject)
		And Not Common.IsChartOfCalculationTypes(MetadataObject)
		And Not Common.IsBusinessProcess(MetadataObject)
		And Not Common.IsTask(MetadataObject)
		And Not IsSubsystem Then
		Return False;
	EndIf;
	
	If ValueIsFilled(FilterByMetadataObjects)
		And Not IsSubsystem
		And Not IsDocumentJournal
		And FilterByMetadataObjects.FindByValue(MetadataObject.FullName()) = Undefined Then
		Return False;
	EndIf;
	
	AvailableByRights = AccessRight("View", MetadataObject);
	AvailableByFunctionalOptions = Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject);
	
	MetadataProperties = New Structure("FullTextSearch, IncludeInCommandInterface");
	FillPropertyValues(MetadataProperties, MetadataObject);
	
	If MetadataProperties.FullTextSearch = Undefined Then 
		FullTextSearchUsing = True; // Ignore if the property is missing.
	Else 
		FullTextSearchUsing = (MetadataProperties.FullTextSearch = 
			Metadata.ObjectProperties.FullTextSearchUsing.Use);
	EndIf;
	
	If MetadataProperties.IncludeInCommandInterface = Undefined Then 
		IncludeInCommandInterface = True; // Ignore if the property is missing.
	Else 
		IncludeInCommandInterface = MetadataProperties.IncludeInCommandInterface;
	EndIf;
	
	Return AvailableByRights And AvailableByFunctionalOptions 
		And FullTextSearchUsing And IncludeInCommandInterface;
	
EndFunction

&AtServer
Function SubordinateCatalogs(MetadataObject)
	
	If SubordinateCatalogs = Undefined Then
		SubordinateCatalogs = New Map;
		
		For Each Catalog In Metadata.Catalogs Do
			If SubordinateCatalogs[Catalog] = Undefined Then
				SubordinateCatalogs[Catalog] = New Array;
			EndIf;
			For Each OwnerOfTheDirectory In Catalog.Owners Do
				If SubordinateCatalogs[OwnerOfTheDirectory] = Undefined Then
					SubordinateCatalogs[OwnerOfTheDirectory] = New Array;
				EndIf;
				ListOfReferenceBooks = SubordinateCatalogs[OwnerOfTheDirectory]; // Array
				ListOfReferenceBooks.Add(Catalog);
			EndDo;
		EndDo;
	EndIf;
	
	Return SubordinateCatalogs[MetadataObject];
	
EndFunction

&AtClient
Procedure FillObjectsTree(OnOpen = False)
	
	ExpandableRowIds = New Array;
	PopulateObjectTreeOnServer(OnOpen, ExpandableRowIds);
	
	If OnOpen
	   And (ParentSubsystems.Count() > 0
	      Or MetadataObjectsToSelectCollection.Count() = 1) Then
		
		Items.MetadataObjectsTree.Expand(ExpandableRowIds[0], True);
		Return;
	EndIf;
	
	For Each RowID In ExpandableRowIds Do
		Items.MetadataObjectsTree.Expand(RowID);
	EndDo;
	
EndProcedure

&AtServer
Procedure PopulateObjectTreeOnServer(OnOpen, ExpandableRowIds)
	
	CurrentLineIDOnOpen = 0;
	RowIdoftheFirstSelectedObject = 0;
	
	If ObjectsGroupMethod = "BySections" Then
		MetadataObjectsTreeFillBySections();
	Else
		MetadataObjectTreeFill();
	EndIf;
	
	SetInitialCollectionMark(MetadataObjectsTree);
	
	If MetadataObjectsTree.GetItems().Count() < 1 Then
		Return;
	EndIf;
	
	If ValueIsFilled(RowIdoftheFirstSelectedObject) Then
		String = MetadataObjectsTree.FindByID(RowIdoftheFirstSelectedObject);
		While String <> Undefined Do
			ExpandableRowIds.Insert(0, String.GetID());
			String = String.GetParent();
		EndDo;
	Else
		RootId = MetadataObjectsTree.GetItems()[0].GetID();
		ExpandableRowIds.Add(RootId);
	EndIf;
	
	// Settings the initial selection value.
	If (OnOpen Or Not FlagDone)
	   And CurrentLineIDOnOpen > 0 Then
		
		Items.MetadataObjectsTree.CurrentRow = CurrentLineIDOnOpen;
		
	ElsIf ValueIsFilled(RowIdoftheFirstSelectedObject) Then
		
		Items.MetadataObjectsTree.CurrentRow = RowIdoftheFirstSelectedObject;
	EndIf;
	
EndProcedure

#Region ItemsMark

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Procedure OnMarkTreeItem(TreeItem)
	
	TreeItem.Check = NextItemCheckMarkValue(TreeItem);
	
	If RequiredToMarkNestedItems(TreeItem) Then 
		MarkNestedItemsRecursively(TreeItem);
	EndIf;
	
	If TreeItem.Check = MarkCheckBoxIsNotSelected() Then 
		TreeItem.Check = CheckMarkValueRelativeToNestedItems(TreeItem);
	EndIf;
	
	MarkParentsItemsRecursively(TreeItem);
	
EndProcedure

&AtClientAtServerNoContext
Function MarkCheckBoxIsNotSelected()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function MarkCheckBoxIsSelected()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function MarkSquare()
	
	Return 2;
	
EndFunction

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Function NextItemCheckMarkValue(TreeItem)
	
	// 0 - Cleared Flag.
	// 1 - Raised Flag.
	// 2 - Raised Square.
	//
	// Override the graph of a finite-state machine.
	//
	// 1C:Enterprise runs a closed cycle when a mark is changed.
	// That is, it has a strong connectivity component:
	// 0-1-2-0-1-2-0-1...
	//
	//    0
	//   / \
	//  2 - 1
	//
	// Cycle: Cleared Flag - Raised Flag - Raised Square - Cleared Flag.
	//
	// The required behavior is a nondeterministic finite automaton with a strong connectivity component:
	// 0-1-0-1-0...
	//
	// That is, a Cleared Flag should transit into a Raised Flag, which transits into a Cleared Flag.
	//
	// Also:
	//
	// Cycles for sections:
	// a) 1-0-1-0-1...
	// b) 2-0-1-0-1-0-...
	//
	//      /\
	// 2 - 0 -1
	//
	// That is a Raised Square transits into a Cleared Flag.
	//
	// Cycles for metadata objects:
	// a) 1-0-1-0-1-0...
	// b) 2-1-0-1-0-1-0...
	//
	//      /\
	// 2 - 1 -0
	//
	// That is, a Raised Square transits into a Raised Flag.
	
	// At the time of checking, the platform has already changed the check box value.
	
	If TreeItem.IsMetadataObject Then
		// Previous check box value = 2: Square is selected.
		If TreeItem.Check = 0 Then
			Return MarkCheckBoxIsSelected();
		EndIf;
	EndIf;
	
	// Previous check box value = 1: Check box is selected.
	If TreeItem.Check = 2 Then 
		Return MarkCheckBoxIsNotSelected();
	EndIf;
	
	// In all other cases, the platform sets a value.
	Return TreeItem.Check;
	
EndFunction

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Procedure MarkParentsItemsRecursively(TreeItem)
	
	Parent = TreeItem.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ParentItems1 = Parent.GetItems();
	If ParentItems1.Count() = 0 Then
		Parent.Check = MarkCheckBoxIsSelected();
	ElsIf TreeItem.Check = MarkSquare() Then
		Parent.Check = MarkSquare();
	Else
		Parent.Check = CheckMarkValueRelativeToNestedItems(Parent);
	EndIf;
	
	MarkParentsItemsRecursively(Parent);
	
EndProcedure

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Function CheckMarkValueRelativeToNestedItems(TreeItem)
	
	NestedItemsState = NestedItemsState(TreeItem);
	
	HasMarkedItems   = NestedItemsState.HasMarkedItems;
	HasUnmarkedItems = NestedItemsState.HasUnmarkedItems;
	
	If TreeItem.IsMetadataObject Then 
		
		// Since the object should be returned, its status matters.
		// Do not reset the current flag.
		// 
		
		If TreeItem.Check = MarkCheckBoxIsSelected() Then 
			// Leave the check box selected, regardless of nested items.
			Return MarkCheckBoxIsSelected();
		EndIf;
		
		If TreeItem.Check = MarkCheckBoxIsNotSelected()
			Or TreeItem.Check = MarkSquare() Then 
			
			If HasMarkedItems Then
				Return MarkSquare();
			Else 
				Return MarkCheckBoxIsNotSelected();
			EndIf;
		EndIf;
		
	Else 
		
		// Sections' status is ignored as they depend on their children. 
		// 
		
		If HasMarkedItems Then
			
			If HasUnmarkedItems Then
				Return MarkSquare();
			Else
				Return MarkCheckBoxIsSelected();
			EndIf;
			
		EndIf;
		
		Return MarkCheckBoxIsNotSelected();
		
	EndIf;
	
EndFunction

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Function NestedItemsState(TreeItem)
	
	NestedItems = TreeItem.GetItems();
	
	HasMarkedItems   = False;
	HasUnmarkedItems = False;
	
	For Each NestedItem In NestedItems Do
		
		If NestedItem.Check = MarkCheckBoxIsNotSelected() Then 
			HasUnmarkedItems = True;
			Continue;
		EndIf;
		
		If NestedItem.Check = MarkCheckBoxIsSelected() Then 
			HasMarkedItems = True;
			
			If NestedItem.IsMetadataObject Then 
				
				// Metadata objects marked for deletion can have
				// child items that are not marked for deletion.
				// To deal with this, elevate the child items to the parent's level.
				
				State = NestedItemsState(NestedItem);
				HasMarkedItems   = HasMarkedItems   Or State.HasMarkedItems;
				HasUnmarkedItems = HasUnmarkedItems Or State.HasUnmarkedItems;
			EndIf;
			
			Continue;
		EndIf;
		
		If NestedItem.Check = MarkSquare() Then 
			HasMarkedItems   = True;
			HasUnmarkedItems = True;
			Continue;
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("HasMarkedItems",   HasMarkedItems);
	Result.Insert("HasUnmarkedItems", HasUnmarkedItems);
	
	Return Result;
	
EndFunction

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Function RequiredToMarkNestedItems(TreeItem)
	
	If TreeItem.IsMetadataObject Then 
		
		// If not all of the object's child items are selected, that indicates a user's choice.
		// Skip these items to avoid affecting the user's choice.
		
		NestedItemsState = NestedItemsState(TreeItem);
		
		HasMarkedItems   = NestedItemsState.HasMarkedItems;
		HasUnmarkedItems = NestedItemsState.HasUnmarkedItems;
		
		If HasMarkedItems And HasUnmarkedItems Then 
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Parameters:
//  TreeItem - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//
&AtClientAtServerNoContext
Procedure MarkNestedItemsRecursively(TreeItem)
	
	NestedItems = TreeItem.GetItems();
	
	For Each NestedItem In NestedItems Do
		
		NestedItem.Check = TreeItem.Check;
		MarkNestedItemsRecursively(NestedItem);
		
	EndDo;
	
EndProcedure

// Parameters:
//  ItemSearchSectionsTree - FormDataTreeItem:
//      * Check             - Number  - a required tree attribute.
//      * IsMetadataObject - Boolean - a required tree attribute.
//  CheckMarkValue - Number - a value being set.
//
&AtClientAtServerNoContext
Procedure MarkAllTreeItemsRecursively(ItemSearchSectionsTree, CheckMarkValue)
	
	TreeItemsCollection = ItemSearchSectionsTree.GetItems();
	
	For Each TreeItem In TreeItemsCollection Do
		TreeItem.Check = CheckMarkValue;
		MarkAllTreeItemsRecursively(TreeItem, CheckMarkValue);
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsTree");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("MetadataObjectsTree.IsSubsection");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.FunctionsPanelSectionColor);
	
EndProcedure

&AtClient
Procedure UpdateSelectedMetadataObjectsCollection(Branch1 = Undefined)
	
	If Branch1 = Undefined Then
		SelectedMetadataObjects.Clear();
		Branch1 = MetadataObjectsTree;
	EndIf;
	
	For Each Item In Branch1.GetItems() Do
		If ObjectsGroupMethod = "ByKinds"
		   And SelectCollectionsWhenAllObjectsSelected
		   And Item.Check = 1
		   And (Item.ThisCollectionObjects
		      Or Branch1 = MetadataObjectsTree) Then
			
			If Item.ThisCollectionObjects Then
				SelectedMetadataObjects.Add(Item.Name, Item.Presentation, True);
			Else
				SelectedMetadataObjects.Add("Configuration", NStr("vi = 'Cấu hình';
																	|ru = 'Конфигурация';
																	|en = 'Configuration'; fa = 'پیکربندی';
																	|it = 'Конфигурация';
																	|pl = 'Configuration';
																	|tr = 'Yapılandırma'"), True);
			EndIf;
			Continue;
		EndIf;
		If Item.Check = 1 And Not IsBlankString(Item.FullName) And Item.IsMetadataObject Then
			SelectedMetadataObjects.Add(Item.FullName, ?(RememberSelectedObjectsSections
				And ObjectsGroupMethod = "BySections", Item.Address, Item.Presentation), True);
		EndIf;
		UpdateSelectedMetadataObjectsCollection(Item)
	EndDo;
	
EndProcedure

#EndRegion
