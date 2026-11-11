
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Department", Object.Ref));
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject, Items.GroupUnlockAttributes);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	
	SetFormFunctionalOptionParameters(New Structure("Department", Object.Ref));
	
	ConfigureDependentFormElements(ThisForm, "Ref");
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject, Items.GroupUnlockAttributes);
	// End StandardSubsystems.ObjectAttributesLock
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("EnumRef.OptionsOfAssignedAccountingOfGoods") Then
		
		Modified = True;
		Object.OptionOfAssignedAccountingOfGoods = ValueSelected;
		FillInParameterPresentation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_BusinessStructure",, Object.Ref);
	
	DetailsCacheIsNew = CacheOfFormDetails();
	InterfaceUpdateIsRequired = False;
	For Each Item In BankAccountDetailsCache Do
		If Not Item.Value = DetailsCacheIsNew[Item.Key] Then
			InterfaceUpdateIsRequired = True;
			Break;
		EndIf;
	EndDo;
	BankAccountDetailsCache = DetailsCacheIsNew;
	If InterfaceUpdateIsRequired Then
		RefreshInterface();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	//++ WE
	If EventName = "DataWasSavedToRegisterOfReflectionInAccounting" Then
		FillInParameterPresentation();
	EndIf;	
	//-- WE
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UsageInSupplySchemes(Command)
	
	If Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Department", Object.Ref);
	OpenForm("InformationRegister.ProductionSupplySchemes.Form.UsageInSupplySchemes", FormParameters);
					
	Return; // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure ProductionUnitParametersCommand(Command)
	OpenForm(
		"Catalog.BusinessStructure.Form.ProductionBusinessUnitDescription",
		New Structure("Ref, StorageAddressObjectData", Object.Ref, ObjectDataInStorage()),
		ThisObject,,,,
		New CallbackDescription("ProductionBusinessUnitDescriptionCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
	
EndProcedure

&AtClient
Procedure GoodsAssignmentParameters(Command)
	
	FormParameters = New Structure("OptionOfAssignedAccountingOfGoods", Object.OptionOfAssignedAccountingOfGoods);
	OpenForm("Catalog.BusinessStructure.Form.GoodsAssignmentParameters", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ReflectionParametersInHRAccounting(Command)
//++ WE
	If Not ValueIsFilled(Object.Ref) Then
		Write();
	EndIf;	
	
	If CheckFilling() Then
		
		FormParameters = SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.GetDisplayParameters();
		FormParameters.FilterDate = CommonClient.SessionDate();
		FormParameters.Department = Object.Ref;   
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().DivisionLevel;
	
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettings(ThisObject, FormParameters);
		
	EndIf;	
//-- WE	
	Return;
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
	ProcedureParameters.Object = New Structure("Ref", Undefined);
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	ThereIsARightToViewSupplySchemes = AccessRight("View", Metadata.InformationRegisters.ProductionSupplySchemes);
	

	GoToHeaderOptions = ?(AccessRight("Update", Metadata.Catalogs.BusinessStructure),
		NStr("vi = 'Thay đổi';
			|ru = 'Изменить';
			|en = 'Change'; fa = 'تغییر';
			|it = 'Modificare';
			|pl = 'Zmień';
			|tr = 'Değiştir'"),
		NStr("vi = 'Chi tiết';
			|ru = 'Подробно';
			|en = 'More'; fa = 'بیشتر';
			|it = 'Dettagliatamente';
			|pl = 'Dokładniej';
			|tr = 'Ayrıntılı'"));
	
	UseProduction = False;
	If GetFunctionalOption("UseProduction") Then
		UseProduction = True;
		Items.ProductionBusinessUnitDescription.Title = GoToHeaderOptions;
	EndIf;
	Items.ProductionBusinessUnitDescription.Visible = UseProduction;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		Items.GoodsAssignmentParameters.Visible = True;
		Items.GoodsAssignmentParameters.Title = GoToHeaderOptions;
	Else
		Items.GoodsAssignmentParameters.Visible = False;
	EndIf;
	
	FillInParameterPresentation();
	ConfigureDependentFormElements(ThisForm);
	BankAccountDetailsCache = CacheOfFormDetails();
EndProcedure
&AtClient
Procedure ProductionBusinessUnitDescriptionCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		
		LoadObjectDataFromStorage(ClosingResult);
		
		ConfigureDependentFormElements(ThisForm, "ProductionBusinessUnit");
		
		Modified = True;
		
	EndIf;
	
EndProcedure
&AtServer
Procedure LoadObjectDataFromStorage(StorageAddressObjectData)
	
	If Not IsTempStorageURL(StorageAddressObjectData) Then
		Return;
	EndIf;
	
	ObjectData = GetFromTempStorage(StorageAddressObjectData);
	ObjectMetadata = Object.Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		Object[Attribute.Name] = ObjectData[Attribute.Name];
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		Object[TabularSection.Name].Load(ObjectData[TabularSection.Name]);
	EndDo;
	
	MaterialsWarehouse = ObjectData.MaterialsWarehouse;
	
	FillInParameterPresentation();
	
EndProcedure

&AtServer
Procedure FillInParameterPresentation()
	
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	ProductionSettings = ProductionServerCached.SubsystemSettingsProduction();
	Production21 = ProductionSettings.ProductionIsUsed21;
	PresentationOfProductionUnit = "";
	If Object.ProductionDispatcherBusinessUnit
		And Object.ProductionByOrders
		And Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất, sản xuất sản phẩm theo đơn hàng và không có đơn hàng sản xuất.';
				|ru = 'Подразделение диспетчирует заказы на производство, производит продукцию по заказам и без заказов на производство.';
				|en = 'Business unit dispatches production orders, produces goods under and without production orders.'; fa = 'Business unit dispatches production orders, produces goods under and without production orders.';
				|it = 'Il reparto invia ordini di produzione, produce prodotti con e senza ordini di produzione.';
				|pl = 'Dział rozsyła zamówienia produkcyjne, produkuje wyroby na zamówienie i bez zleceń produkcyjnych.';
				|tr = 'Departman, üretim emirlerini sevk eder, emir üzerine ve üretim emri olmadan imal edilen ürünler üretir.'");
			
	ElsIf Object.ProductionDispatcherBusinessUnit
		And Object.ProductionByOrders
		And Not Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất và sản xuất sản phẩm theo đơn hàng.';
				|ru = 'Подразделение диспетчирует заказы на производство и производит продукцию по заказам.';
				|en = 'Business unit dispatches production orders and produces goods under orders.'; fa = 'Business unit dispatches production orders and produces goods under orders.';
				|it = 'Il reparto invia ordini di produzione e produce prodotti su ordinazione.';
				|pl = 'Dział rozsyła zamówienia produkcyjne i produkuje wyroby na zamówienie.';
				|tr = 'Departman, üretim emirlerini sevk eder ve siparişlere göre ürünleri üretir.'");
			
	ElsIf Object.ProductionDispatcherBusinessUnit
		And Not Object.ProductionByOrders
		And Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất và sản xuất sản phẩm không có đơn hàng.';
				|ru = 'Подразделение диспетчирует заказы на производство и производит продукцию без заказов.';
				|en = 'Business unit dispatches production orders and produces goods without orders.'; fa = 'Business unit dispatches production orders and produces goods without orders.';
				|it = 'Il reparto invia ordini di produzione e produce prodotti senza ordinazione.';
				|pl = 'Dział rozsyła zamówienia produkcyjne i produkuje wyroby bez zleceń produkcyjnych.';
				|tr = 'Departman, üretim emirlerini sevk eder ve siparişsiz ürünleri üretir.'");
		
	ElsIf Object.ProductionDispatcherBusinessUnit
		And Not Object.ProductionByOrders
		And Not Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất.';
				|ru = 'Подразделение диспетчирует заказы на производство.';
				|en = 'Business unit dispatches production orders.'; fa = 'Business unit dispatches production orders.';
				|it = 'Il reparto invia ordini di produzione.';
				|pl = 'Dział rozsyła zamówienia produkcyjne.';
				|tr = 'Departman, üretim emirlerini sevk eder.'");
			
	ElsIf Not Object.ProductionDispatcherBusinessUnit
		And Object.ProductionByOrders
		And Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận sản xuất sản phẩm theo đơn hàng và không có đơn hàng sản xuất.';
				|ru = 'Подразделение производит продукцию по заказам и без заказов на производство.';
				|en = 'Business unit produces goods under and without production orders.'; fa = 'Business unit produces goods under and without production orders.';
				|it = 'Il reparto produce prodotti con e senza ordini di produzione.';
				|pl = 'Dział produkuje wyroby na zamówienie i bez zleceń produkcyjnych.';
				|tr = 'Departman, siparişler üzerine ve üretim emirlerini olmadan imal edilen ürünler üretir.'");
			
	ElsIf Not Object.ProductionDispatcherBusinessUnit
		And Object.ProductionByOrders
		And Not Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận sản xuất sản phẩm cho các đơn hàng sản xuất.';
				|ru = 'Подразделение производит продукцию по заказам на производство.';
				|en = 'Business unit produces goods under production orders.'; fa = 'Business unit produces goods under production orders.';
				|it = 'Il reparto produce prodotti su ordinazione.';
				|pl = 'Dział produkuje wyroby w ramach zamówień produkcyjnych.';
				|tr = 'Departman, üretim emirlerine göre imal edilen ürünler üretir.'");
			
	ElsIf Not Object.ProductionDispatcherBusinessUnit
		And Not Object.ProductionByOrders
		And Object.BackflushProduction_
		And Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận sản xuất sản phẩm mà không có đơn hàng sản xuất.';
				|ru = 'Подразделение производит продукцию без заказов на производство.';
				|en = 'Business unit produces goods without production orders.'; fa = 'Business unit produces goods without production orders.';
				|it = 'Il reparto produce prodotti senza ordinazione.';
				|pl = 'Dział produkuje wyroby bez zleceń produkcyjnych.';
				|tr = 'Departman, üretim emirleri olmayan imal edilen ürünler üretmektedir.'");
	ElsIf Object.ProductionDispatcherBusinessUnit
		And Object.ProductionBusinessUnit
		And Not Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất, sản xuất sản phẩm.';
				|ru = 'Подразделение диспетчирует заказы на производство, производит продукцию.';
				|en = 'Business unit dispatches production orders and produces goods.'; fa = 'Business unit dispatches production orders and produces goods.';
				|it = 'Подразделение диспетчирует заказы на производство, производит продукцию.';
				|pl = 'Business unit dispatches production orders and produces goods.';
				|tr = 'Departman, üretim emirlerini sevk eder, ürünleri üretir.'");
			
	ElsIf Object.ProductionDispatcherBusinessUnit
		And Not Object.ProductionBusinessUnit
		And Not Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận điều phối đơn hàng sản xuất.';
				|ru = 'Подразделение диспетчирует заказы на производство.';
				|en = 'Business unit dispatches production orders.'; fa = 'Business unit dispatches production orders.';
				|it = 'Il reparto invia ordini di produzione.';
				|pl = 'Dział rozsyła zamówienia produkcyjne.';
				|tr = 'Departman, üretim emirlerini sevk eder.'");
		
	ElsIf Not Object.ProductionDispatcherBusinessUnit
		And Object.ProductionBusinessUnit
		And Not Production21
		And Not ThisIsCA Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận sản xuất sản phẩm.';
				|ru = 'Подразделение производит продукцию.';
				|en = 'Business unit produces goods.'; fa = 'Business unit produces goods.';
				|it = 'Il reparto produce prodotti.';
				|pl = 'Dział produkuje wyroby.';
				|tr = 'Departman, imal edilen ürünleri üretmektedir.'");
	ElsIf ThisIsCA And Object.ProductionBusinessUnit Then
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận sản xuất sản phẩm.';
				|ru = 'Подразделение производит продукцию.';
				|en = 'Business unit produces goods.'; fa = 'Business unit produces goods.';
				|it = 'Il reparto produce prodotti.';
				|pl = 'Dział produkuje wyroby.';
				|tr = 'Departman, imal edilen ürünleri üretmektedir.'");
		
	Else
		
		PresentationOfProductionUnit =
			NStr("vi = 'Bộ phận không sản xuất.';
				|ru = 'Подразделение не является производственным.';
				|en = 'This is not a production business unit.'; fa = 'This is not a production business unit.';
				|it = 'Il reparto non fa parte della produzione.';
				|pl = 'Dział nie jest producentem.';
				|tr = 'Departman üretim birimi değildir.'");
		
	EndIf;
	Commands["ProductionBusinessUnitDescription"].ToolTip = PresentationOfProductionUnit;
	PresentationOfSeparateAccountingOfGoods = "";
	If Object.OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.NotKept Then
		PresentationOfSeparateAccountingOfGoods = NStr("vi = 'Không tiến hành ghi nhận hàng hóa đặt riêng.';
														|ru = 'Обособленный учет товаров не ведется.';
														|en = 'Goods assignment is not enabled.'; fa = 'Goods assignment is not enabled.';
														|it = 'La contabilità separata delle merci non viene effettuata.';
														|pl = 'Oddzielna ewidencja towarów nie jest prowadzona.';
														|tr = 'Ürün tahsisi uygulanmaz.'");
	ElsIf Object.OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit Then
		PresentationOfSeparateAccountingOfGoods = NStr("vi = 'Quản lý đặt riêng hàng hóa được thực hiện theo bộ phận.';
														|ru = 'Обособленный учет товаров ведется по подразделению.';
														|en = 'Goods assignment is enabled by the business unit.'; fa = 'Goods assignment is enabled by the business unit.';
														|it = 'La contabilità separata delle merci viene effettuata sul reparto.';
														|pl = 'Oddzielna ewidencja towarów jest prowadzona dla działu.';
														|tr = 'Ürün tahsisi departmana göre hesaplanır.'");
	ElsIf Object.OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers Then
		PresentationOfSeparateAccountingOfGoods = NStr("vi = 'Quản lý đặt riêng hàng hóa được thực hiện theo người quản lý bộ phận.';
														|ru = 'Обособленный учет товаров ведется по менеджерам подразделения.';
														|en = 'Goods assignment is enabled by business unit managers.'; fa = 'Goods assignment is enabled by business unit managers.';
														|it = 'La contabilità separata delle merci viene effettuata sui manager del reparto.';
														|pl = 'Oddzielna ewidencja towarów jest prowadzona dla menedżerów działu.';
														|tr = 'Ürün tahsisi departman yöneticilerine göre hesaplanır.'");
	EndIf;
	Commands["GoodsAssignmentParameters"].ToolTip = PresentationOfSeparateAccountingOfGoods;
	//++ WE
	Commands["ReflectionParametersInHRAccounting"].ToolTip = 
		SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.PresentationOfReflectionParametersInAccounting(ThisObject);
	//-- WE
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributesStructure1.Property("ProductionBusinessUnit")
		Or AttributesStructure1.Property("Ref")
		Or Initialize Then
		Items.UsageInSupplySchemes.Visible = 
				Object.ProductionBusinessUnit 
				And Form.ThereIsARightToViewSupplySchemes
				And ValueIsFilled(Object.Ref);
	EndIf;
	
EndProcedure

&AtServer
Function ObjectDataInStorage()
	
	ObjectData = New Structure;
	ObjectMetadata = Object.Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		ObjectData.Insert(Attribute.Name, Object[Attribute.Name]);
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		ObjectData.Insert(TabularSection.Name, Object[TabularSection.Name].Unload());
	EndDo;
	
	ObjectData.Insert("MaterialsWarehouse", MaterialsWarehouse);
	
	Return PutToTempStorage(ObjectData, UUID);
	
EndFunction

&AtServerNoContext
Function CacheOfFormDetails()
	
	AttributesList =
	"UseOperationManagement,
	|UseManufacturingExecutionSystem,
	|UseShiftTasks
	|";
	
	AttributesValues = Constants.CreateSet(AttributesList);
	AttributesValues.Read();
	
	Result = New Structure(AttributesList);
	FillPropertyValues(Result, AttributesValues);
	
	Return Result;
	
EndFunction

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
		
	EndIf;
	
EndProcedure

// End StandardSubsystems.ObjectAttributesLock

#EndRegion
