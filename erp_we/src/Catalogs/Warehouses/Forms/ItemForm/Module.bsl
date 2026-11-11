
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Parameters.Property("FillingValues") And Parameters.FillingValues.Property("WarehouseStore") Then
		WarehouseTypeWhenChangingServer();
	EndIf;

	// StandardSubsystems.ContactInformation
	AdditionalCIParameters = ContactsManager.ContactInformationParameters();
	AdditionalCIParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	AdditionalCIParameters.Insert("DeferredInitialization", True);
	ContactsManager.OnCreateAtServer(ThisForm, Object, AdditionalCIParameters);
	// End StandardSubsystems.ContactInformation
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Ref, Catalogs.Warerooms.EmptyRef()));
	
	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	ItIsAllowedToCreatePriceTypes                       = UseSeveralPriceTypes
	                                                And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);
	
	SetVisibilityByFO();
	ConfigureFormElementsByAccessRights();
	
	If Not ValueIsFilled(Object.Ref) Then
		AvailableStockControl  = True;
		OnReadCreateAtServer();
	EndIf;
	
	// Price Type Settings
	UsePriceManagementSystem25                   = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UpdateIndividualPriceViewPresentation();
	RefreshUseRetailPriceViewCheckbox();	
	UpdateUseCustomPriceViewCheckbox();
	UpdateViewsAndVisibilityOfPriceTypesByStoreFormat();
	// End of Setting Up Price types
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	RefreshFormTitle(ThisForm);
	CustomizeFormLocalization();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	WhenReadingWithRestrictedRights(CurrentObject);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not Object.ShopFloorStockroom Then
		NotCheckedAttributeArray.Add("Shop");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisForm, Object, Cancel);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	BeforeRecordingWithRestrictedRights(CurrentObject);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;

	If Not Cancel Then
		CurrentObject.AdditionalProperties.Insert("SkipUpdatingOperationalBalancesControlFlag");
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ContactInformation
	ContactsManager.AfterWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Ref));
	SetFieldAvailability();
	
	If Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
		And Not GetFunctionalOption("UseItemPackages") Then
		NotifyOfDisabledPackaging = True;
	EndIf;

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	RefreshFormTitle(ThisForm);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Warehouses",WriteParameters,Object.Ref);
	
	InterfaceUpdateIsRequired = False;
	
	For Each RowStructure In BankAccountDetailsCache Do
		If Object[RowStructure.Key] <> RowStructure.Value Then
			InterfaceUpdateIsRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If InterfaceUpdateIsRequired Then
		RefreshInterface();
		
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("UseWarerooms",Object.UseWarerooms);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsIssue",Object.UseWarehouseManagemantSystemForGoodsIssue);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages",Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsReceipt",Object.UseWarehouseManagemantSystemForGoodsReceipt);
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Object.CustomizeBinLocationWarehousing);
		DetailsCacheStructure.Insert("WarehouseZoneUsage",Object.WarehouseZoneUsage);
		
		BankAccountDetailsCache = New FixedStructure(DetailsCacheStructure);
		
	EndIf;
	
	If NotifyOfDisabledPackaging Then
		MessageText = NStr("vi = 'Trong tùy chỉnh kế toán đã ngắt sử dụng bộ đóng gói mặt hàng. Không thể ghi tăng hàng hóa trong kho
		|có cất giữ số dư theo từng ô mà không chỉ ra bộ đóng gói.';
		|ru = 'В настройках учета отключено использование упаковок номенклатуры. Оприходовать товар на склад
		|с хранением остатков в разрезе ячеек без указания упаковок невозможно.';
		|en = 'Item packaging units are disabled in the accounting settings. Specify the units in the goods receipt 
		|because bins management is enabled in the warehouse.'; fa = 'Item packaging units are disabled in the accounting settings. Specify the units in the goods receipt 
		|because bins management is enabled in the warehouse.';
		|it = 'Nelle impostazioni di contabilità, l''uso delle confezioni dell''articolo è disabilitato. È impossibile depositare le merci nel magazzino
		|immagazzinando i residui nelle celle senza specificare le confezioni.';
		|pl = 'W ustawieniach ewidencji wyłączono używanie opakowań towarów. Zarejestrować towar w magazynie
		|z przechowywaniem ostatków w  komórkach bez określenia opakowań nie jest możliwe.';
		|tr = 'Muhasebe ayarlarında ürün paketleme ünitelerinin kullanımı devre dışı bırakıldı. Depo konum takibini kullanan ambara ürün girişi,
		|paketleme ünitesi belirtilmeden mümkün değildir.'");
		ShowMessageBox(, MessageText);
	EndIf;

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Warehouses_FilledRoomInCatalogsAndRegisters" Then
		Items.WareroomsInCatalogsFilling.Visible = False;
	EndIf;
	
	If EventName = "RecordingSoftwareControlSettings" And Parameter = Object.Ref Then
		UpdateNumberOfExceptions();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.Warehouses.Form.SpecifyCustodyConditions" Then
		FillPropertyValues(Object, ValueSelected);
		SetHeaderOfResponsibleStorageItems(ThisForm);
	ElsIf ChoiceSource.FormName = "DataProcessor.OrdersAssemblyAndCourierDeliverySettings.Form.Settings" Then
		Modified = True;
		FillPropertyValues(Object, ValueSelected);
		SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseWarehouseManagemantSystemForGoodsReceiptOnChange(Item)
	
	UseWarehouseManagemantSystemForGoodsReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure UseWarehouseManagemantSystemForGoodsIssueOnChange(Item)
	
	UseWarehouseManagemantSystemForGoodsIssueOnChangeServer();
	
EndProcedure

&AtClient
Procedure UseWarehouseManagemantSystemForGoodsSurplusesShortagesOnChange(Item)
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortagesOnChangeServer();
	
EndProcedure

&AtClient
Procedure UseWareroomsOnChange(Item)
	
	UseWareroomsOnChangeServer();
	
EndProcedure

&AtClient
Procedure CustomizeBinLocationWarehousingClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure CustomizeBinLocationWarehousingStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse"));
	ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.BinsReferenceAddress"));
	If Object.UseWarehouseManagemantSystemForGoodsIssue
		And Object.UseWarehouseManagemantSystemForGoodsReceipt
		And Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		And Object.WarehouseStore <> PredefinedValue("Enum.TypesOfWarehouses.RetailStore") Then
		ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance"));
	EndIf;

EndProcedure

&AtClient
Procedure WarehouseZoneUsageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	ChoiceData.Add(PredefinedValue("Enum.UseIsDeterminedInWarerooms.DontUse"));
	ChoiceData.Add(PredefinedValue("Enum.UseIsDeterminedInWarerooms.Use"));
	
EndProcedure

&AtClient
Procedure WarehouseZoneUsageClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure WarehouseTypeWhenChanging(Item)
	
	WarehouseTypeWhenChangingServer();
	
	UpdateViewsAndVisibilityOfPriceTypesByStoreFormat();
	
	RefreshFormTitle(ThisForm);
	
EndProcedure

&AtClient
Procedure CustomizeBinLocationWarehousingOnChange(Item)
	
	CustomizeBinLocationWarehousingOnChangeServer();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	If CurrentPage.Name = ContactInformationParameters.ContactInformationGroup.GroupForPlacement
		And Not ContactInformationParameters.ContactInformationGroup.DeferredInitializationExecuted Then
		
		ContactInformationWhenChangingPages();
		
	EndIf;
	// End StandardSubsystems.ContactInformation
	
	If CurrentPage = Items.ContactInformationGroup Then
		
		CommandName = Commands.OpenListOfDeliveryPoints.Name;
		
		If Items.Find(CommandName) = Undefined Then
			
			DeliveryOfGoodsWhenChangingPage(CommandName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HowToSpecifyATransportTaskWhenChanging(Item)
	If ProcedureOfTransportationJobIndication = "AssembleGoodsAccordingToDeliveryProcedure" Then
		Object.StartShipmentOnceDeliveryOrderIsCreated = True; 
	Else
		Object.StartShipmentOnceDeliveryOrderIsCreated = False; 
	EndIf;
EndProcedure

&AtClient
Procedure ShopFloorStockroomOnChange(Item)
	ShopFloorStockroomOnChangeServer();
EndProcedure

&AtServer
Procedure ShopFloorStockroomOnChangeServer()
	
	If Object.ShopFloorStockroom
		And ValueIsFilled(Object.Department) Then
		If Common.ObjectAttributeValue(Object.Department, "ProductionBusinessUnit") Then
			Shop = Object.Department;
		Else
			Object.Department = Undefined;
		EndIf;
	Else
		Shop = Undefined;
	EndIf;
	
	WarehousesClientServer.AgreeOnFeatureValues(Object);
	SetFieldAvailability();
	
EndProcedure

&AtClient
Procedure ShopOnChange(Item)
	
	Object.Department = Shop;
	
EndProcedure

&AtClient
Procedure UseIndividualViewOfPriceWhenChangingOnClient()

	If UseAnIndividualViewOfThePrice Then
	
		If Not ValueIsFilled(Object.Ref) Then
			
			Return;
			
		EndIf;

		ShutdownResult = FindIndividualViewOfPrices();
	
	Else
		
		If Object.SpecialPriceType.IsEmpty() Then
			
			Return;
			
		EndIf;
		
//		Display the user's notification ("Disabling the individual type of price", , , , the status of the user's notification.Information );
		
		ShutdownResult = DisableIndividualPriceViewServer();
		
		If Not ShutdownResult.Result Then
			
			UseAnIndividualViewOfThePrice = True;
			
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Đã xảy ra lỗi khi ngắt bảng giá riêng';
					|ru = 'Возникла ошибка при отключении индивидуального прайс листа';
					|en = 'An error occurred while disabling the individual price list'; fa = 'An error occurred while disabling the individual price list';
					|it = 'Si è verificato un errore durante la disabilitazione del listino prezzi individuale';
					|pl = 'Wystąpił błąd podczas wyłączenia indywidualnego cennika';
					|tr = 'Özelleştirilmiş fiyat listesi devre dışı bırakılırken hata oluştu'") + ShutdownResult.ErrorDescription,
				Object.Ref,
				);
			
		EndIf;
		
	EndIf;
		
EndProcedure

&AtServer
Function DisableIndividualPriceViewServer()
	
	ShutdownResult = Catalogs.TypesOfPrices.DisableIndividualPriceView(Object.SpecialPriceType);

	If ShutdownResult.Result Then
		
		Object.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
		UpdateIndividualPriceViewPresentation();
		
	EndIf;
		
	Return ShutdownResult;
	
EndFunction

&AtServer
Function FindIndividualViewOfPrices()
	
	SearchResult = Catalogs.TypesOfPrices.FindIndividualViewOfPrices(Object.Ref);
	
	If SearchResult.Result Then
		Object.SpecialPriceType = SearchResult.Ref;
		UpdateIndividualPriceViewPresentation();
	EndIf;
			
	Return SearchResult;
	
EndFunction

&AtClient
Procedure UseAnIndividualViewOfThePriceOnChange(Item)
	
	UseIndividualViewOfPriceWhenChangingOnClient();
	AdjustVisibilityAvailabilityOfIndividualPriceViewSettings_(ThisForm);
	
EndProcedure

&AtClient
Function HyperlinkClickParameters(TagName, Hyperlink = "")
	
	If TagName = "HyperlinkGoToPriceList" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.AccountingPriceType);
		TypesOfPrices.Add(Object.RetailPriceType);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		HyperlinkClickParameters.Insert("FormName", "DataProcessor.PriceList.Form.Form");
		HyperlinkClickParameters.Insert("FormParameters",FormParameters);
		
	ElsIf TagName = "HyperlinkGoPriceChangeHistory" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.AccountingPriceType);
		TypesOfPrices.Add(Object.RetailPriceType);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		If UsePriceManagementSystem25 Then
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices25.Form.ListForm");
		Else	
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices.Form.ListForm");
		EndIf;
		HyperlinkClickParameters.Insert("FormParameters", FormParameters);
			
	EndIf;
	
	If Not HyperlinkClickParameters.Property("FormWindowOpeningMode") Then
		HyperlinkClickParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.Independent);
	EndIf;
	HyperlinkClickParameters.Insert("TagName", TagName);
	HyperlinkClickParameters.Insert("Hyperlink", Hyperlink);
	
	Return HyperlinkClickParameters
EndFunction

&AtClient
Procedure HyperlinkGoToPriceListURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoPriceChangeHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến thông tin bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к дополнительной информации возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?';
		|it = 'I dati non sono ancora stati registrati.
		|Il passaggio all''informazione aggiuntiva è possibile solo dopo la registrazione dell''elemento.
		|Registrare l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do informacji dodatkowej jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ek bilgilere geçiş sadece öğenin kaydından sonra mümkündür.
		|Öğe kaydedilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("HyperlinkGoQuestionCompletion", ThisObject, HyperlinkClickParameters), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoQuestionCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	HyperlinkClickParameters = HyperlinkClickParameters(AdditionalParameters.TagName,
																		AdditionalParameters.Hyperlink);
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure GoHyperlink(HyperlinkClickParameters)
	
	If HyperlinkClickParameters.Property("FormName") Then
		OpenForm(HyperlinkClickParameters.FormName,
			HyperlinkClickParameters.FormParameters, , ThisForm.UUID, , , ,
			HyperlinkClickParameters.FormWindowOpeningMode);
	Else
		ExceptionText = NStr("vi = 'Chưa xác định thao tác theo đường dẫn.';
							|ru = 'Не определено действие по гиперссылке.';
							|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
							|it = 'Azione ipertestuale non definita.';
							|pl = 'Nie określono działania hiperłącza.';
							|tr = 'Köprü eylemi tanımlanmadı.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#Region SubsystemProceduresContactInformation

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ContactsManagerClient.StartURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure

&AtServer
Procedure ContactInformationWhenChangingPages()
	
	ContactsManager.ExecuteDeferredInitialization(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.ContactInformation

#EndRegion

&AtClient
Procedure AvailableStockControlOnChange(Item)
	UpdateNumberOfExceptions();
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.Warehouses.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        SetFieldAvailability();
        
    EndIf;

EndProcedure

&AtClient
Procedure RechargeSettings(Command)
	FormParameters = New Structure("Key",KeyForRecordingFuelSettings());
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.RecordForm", FormParameters, ThisForm,,);
EndProcedure

&AtClient
Procedure SettingOfProcurementStrategies(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Catalog.Warehouses.Form.ItemForm.Command.SettingOfProcurementStrategies");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để tùy chỉnh tham số đảm bảo, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для настройки параметров обеспечения необходимо записать объект. Записать?';
						|en = 'To configure the supply parameters, save the object. Do you want to save it?'; fa = 'To configure the supply parameters, save the object. Do you want to save it?';
						|it = 'Per impostare i parametri di approvvigionamento è necessario registrare l''oggetto. Registralo?';
						|pl = 'Aby ustawić parametry zaspokojenia, należy zapisać obiekt. Zapisać?';
						|tr = 'Tedarik parametrelerini ayarları için nesneyi kaydetmeniz gerekmektedir. Kaydedilsin mi?'");
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("SettingOfProcurementStrategiesCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	SettingUpWaysToEnsureFragmentNeeds();
	
EndProcedure

&AtClient
Procedure SettingOfProcurementStrategiesCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		Write();
	EndIf;
	
	
	SettingUpWaysToEnsureFragmentNeeds();
	
EndProcedure

&AtClient
Procedure SettingUpWaysToEnsureFragmentNeeds()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return
	EndIf;
	
	Filter = New Structure("Warehouse", Object.Ref);
	FormParameters = New Structure("Filter, Source", Filter, "Warehouse");
	
	OpenForm("DataProcessor.SettingOfProcurementStrategies.Form.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SetUpStockReplenishment(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để tùy chỉnh tham số đảm bảo, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для настройки параметров обеспечения необходимо записать объект. Записать?';
						|en = 'To configure the supply parameters, save the object. Do you want to save it?'; fa = 'To configure the supply parameters, save the object. Do you want to save it?';
						|it = 'Per impostare i parametri di approvvigionamento è necessario registrare l''oggetto. Registralo?';
						|pl = 'Aby ustawić parametry zaspokojenia, należy zapisać obiekt. Zapisać?';
						|tr = 'Tedarik parametrelerini ayarları için nesneyi kaydetmeniz gerekmektedir. Kaydedilsin mi?'");
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("SetUpStockReplenishmentCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	ConfiguringStockMaintenanceFragment();
EndProcedure

&AtClient
Procedure SetUpStockReplenishmentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		Write();
	EndIf;
	
	
	ConfiguringStockMaintenanceFragment();
	
EndProcedure

&AtClient
Procedure ConfiguringStockMaintenanceFragment()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return
	EndIf;
	
	Filter = New Structure("Warehouse", Object.Ref);
	FormParameters = New Structure("Filter, Source", Filter, "Warehouse");
	OpenForm("DataProcessor.SetUpStockReplenishment.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure WareroomsInCatalogsFilling(Command)
	
	If Modified Then
		QueryText = NStr("vi = 'Để điền mục tin ""Nhà kho"" trong danh mục, cần lưu lại thay đổi. Tiếp tục?';
						|ru = 'Чтобы приступить к заполнению реквизита ""Помещение"" в справочниках, необходимо сохранить изменения. Продолжить?';
						|en = 'To go to attribute Wareroom attribute populating in catalogs, save changes.'; fa = 'To go to attribute Wareroom attribute populating in catalogs, save changes.';
						|it = 'Per iniziare a riempire il requisito ""Stanza"" negli elenchi, è necessario salvare le modifiche. Continuare?';
						|pl = 'Aby rozpocząć wypełnianie atrybutu ""Pomieszczenie"" w katalogach, należy zapisać zmiany. Kontynuować?';
						|tr = 'Kataloglardaki ""Depolama alanı"" özniteliğini doldurmaya başlamak için değişiklikleri kaydetmeniz gerekmektedir. Devam edilsin mi?'");
		Mode = New ValueList;
		Mode.Add(DialogReturnCode.Yes,NStr("vi = 'Lưu lại và tiếp tục';
											|ru = 'Сохранить и продолжить';
											|en = 'Save and continue'; fa = 'Save and continue';
											|it = 'Salvare e proseguire';
											|pl = 'Zapisz i kontynuuj';
											|tr = 'Kaydet ve devam et'"));
		Mode.Add(DialogReturnCode.No,NStr("vi = 'Không tiếp tục';
											|ru = 'Не продолжать';
											|en = 'Do not continue'; fa = 'Do not continue';
											|it = 'Non proseguire';
											|pl = 'Nie kontynuuj';
											|tr = 'Devam etme'"));

		ShowQueryBox(New CallbackDescription("WareroomsInCatalogsFillingCompletion", ThisObject), QueryText,Mode);
        Return;
	EndIf;
	
	FillingInRoomInCatalogFragment();
EndProcedure

&AtClient
Procedure WareroomsInCatalogsFillingCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    Write();
    
    FillingInRoomInCatalogFragment();

EndProcedure

&AtClient
Procedure FillingInRoomInCatalogFragment()
    
    ProcessingParameters = New Structure;
    ProcessingParameters.Insert("Warehouse", Object.Ref);
    OpenForm("Catalog.Warehouses.Form.WareroomsInCatalogsFilling",ProcessingParameters, ThisForm);

EndProcedure

&AtClient
Procedure ControlExceptionsClick(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến loại bỏ kiểm soát đảm bảo sau khi ghi lại dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Данные еще не записаны.
		|Переход к исключениям контроля обеспечения доступен только после записи данных.
		|Данные будут записаны.';
		|en = 'Data is not saved yet.
		|Going to exceptions of the supply control is available only after the data is saved.
		|Data will be saved.'; fa = 'Data is not saved yet.
		|Going to exceptions of the supply control is available only after the data is saved.
		|Data will be saved.';
		|it = 'I dati non sono stati ancora registrati.
		|Il passaggio alle eccezioni del controllo di approvvigionamento è disponibile solo dopo la registrazione dei dati.
		|I dati verranno registrati.';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do wyjątków kontroli zaspokojenia jest możliwe tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Veriler henüz kaydedilmedi.
		|Tedarik kontrolü istisnalarına geçiş sadece verilerin kaydından sonra mümkündür.
		|Veriler kaydedilecektir.'");
		
		ShowQueryBox(New CallbackDescription("ControlExceptionsClickCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel);
        Return;
		
	EndIf;
	
	ControlExceptionsClickFragment();
EndProcedure

&AtClient
Procedure ControlExceptionsClickCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Cancel Then
        Return;
    EndIf;
    
    Try
        ItemRecorded = Write();
    Except
        Return;
    EndTry;
    
    If Not ItemRecorded Then
        Return;
    EndIf;
    
    
    ControlExceptionsClickFragment();

EndProcedure

&AtClient
Procedure ControlExceptionsClickFragment()
    
    FormParameters = New Structure("Warehouse, AvailableStockControl", Object.Ref, AvailableStockControl);
    OpenForm("InformationRegister.SetUpSupplyControl.Form.ExceptionsByWarehouse", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure SetUpSafekeeping(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("GoodsStorageConditions", Object.GoodsStorageConditions);
	FormParameters.Insert("SpecialNotes", Object.SpecialNotes);
	FormParameters.Insert("CustodyWarehouse", Object.CustodyWarehouse);
	FormParameters.Insert("DepositoryKind", Object.DepositoryKind);
	FormParameters.Insert("Depository", Object.Depository);
	FormParameters.Insert("CustodyPeriod", Object.CustodyPeriod);
	FormParameters.Insert("CustodyUntilCalledFor", Object.CustodyUntilCalledFor);
	
	OpenForm("Catalog.Warehouses.Form.SpecifyCustodyConditions", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SetUpOrderCollectionAndCourierDelivery(Command)
	
	If ValueIsFilled(StoreFormat)
		And TypeOf(StoreFormat) = Type("CatalogRef.StoreFormats") Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Key", StoreFormat);
		
		OpenForm("Catalog.StoreFormats.Form.ItemForm", FormParameters, ThisForm);
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("StoreSupportsOrderAssembly", Object.StoreSupportsOrderAssembly);
		FormParameters.Insert("StoreSupportsDeliveryByOwnCouriers", Object.StoreSupportsDeliveryByOwnCouriers);
		FormParameters.Insert("MethodOfSalesCreatingWhenAssemblingOrders", Object.MethodOfSalesCreatingWhenAssemblingOrders);
		FormParameters.Insert("MethodOfFiscalizationUponDelivery", Object.MethodOfFiscalizationUponDelivery);
		FormParameters.Insert("AssemblyAndDeliveryIsDoneBySameEmployee", Object.AssemblyAndDeliveryIsDoneBySameEmployee);
		FormParameters.Insert("CouriersCanAssignOrdersToThemselves", Object.CouriersCanAssignOrdersToThemselves);
		FormParameters.Insert("PickersCanAssignJobsToThemselves", Object.PickersCanAssignJobsToThemselves);
		FormParameters.Insert("StandardOrderDeliveryTime", Object.StandardOrderDeliveryTime);
		FormParameters.Insert("CouriersUsePOSTerminals", Object.CouriersUsePOSTerminals);
		FormParameters.Insert("CouriersUseAutonomousCREs", Object.CouriersUseAutonomousCREs);
		FormParameters.Insert("OrderAssemblyStartDate", Object.OrderAssemblyStartDate);
		FormParameters.Insert("StartDateOfDeliveryByOwnCouriers", Object.StartDateOfDeliveryByOwnCouriers);
		FormParameters.Insert("FormMode", 2);
		FormParameters.Insert("Object", Object);
		FormParameters.Insert("GroupingOfGoods", Object.GroupingOfGoods);
		
		OpenForm("DataProcessor.OrdersAssemblyAndCourierDeliverySettings.Form.Settings", FormParameters, ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure OpenListOfDeliveryPoints(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref)
	 Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu chưa được ghi lại.
		|Chỉ có thể chuyển đến các điểm giao hàng sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к точкам доставки возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|it = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|pl = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Teslimat noktalarına geçiş yalnızca öğe kaydedildikten sonra mümkündür.
		| Öğe kaydedilsin mi?'");
		
		CallbackOnCompletion = New CallbackDescription("OpenDeliveryPointsEndForm", ThisObject);
		
		ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenListOfSubordinateDeliveryPoints();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WarehouseTypeWhenChangingServer()
	
	If Not UseSeveralPriceTypes Then
		If Object.WarehouseStore = PredefinedValue("Enum.TypesOfWarehouses.RetailStore") Then
			Object.RetailPriceType = PriceManagementSystem.PriceTypePriceList_();
		EndIf;
	EndIf;
	WarehousesClientServer.AgreeOnFeatureValues(Object);
	SetFieldAvailability();
	
	RefreshUseRetailPriceViewCheckbox();
EndProcedure

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	If ValueIsFilled(Object.Ref) Then
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("UseWarerooms",Object.UseWarerooms);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsIssue",Object.UseWarehouseManagemantSystemForGoodsIssue);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages",Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsReceipt",Object.UseWarehouseManagemantSystemForGoodsReceipt);
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Object.CustomizeBinLocationWarehousing);
		DetailsCacheStructure.Insert("WarehouseZoneUsage",Object.WarehouseZoneUsage);
	Else
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("UseWarerooms",False);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsIssue",False);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages",False);
		DetailsCacheStructure.Insert("UseWarehouseManagemantSystemForGoodsReceipt",False);
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Enums.SettingsOfBinLocationWarehousing.DontUse);
		DetailsCacheStructure.Insert("WarehouseZoneUsage",Enums.UseIsDeterminedInWarerooms.DontUse);
	EndIf;
	
	If Object.StartShipmentOnceDeliveryOrderIsCreated Then
		ProcedureOfTransportationJobIndication = "AssembleGoodsAccordingToDeliveryProcedure";
	Else
		ProcedureOfTransportationJobIndication = "GoodsPickingProcedureDoesNotDependOnDeliveryProcedure";
	EndIf;
		
	BankAccountDetailsCache = New FixedStructure(DetailsCacheStructure);
	
	UpdateInformationAboutStoreFormat();
	
	If Object.ShopFloorStockroom Then
		Shop = Object.Department;
	EndIf;
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	RegistrationOfInvoicesInSystem = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	ChangingBuildOrderIsAvailable = Not GoodsDeliveryClientServer.UsedDelivery25()
		Or (RegistrationOfInvoicesInSystem <> Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst);
	
	Items.WareroomsInCatalogsFilling.Visible = AccessRight("Update", Metadata.Catalogs.StorageBins)
		And Object.UseWarerooms
		And (Catalogs.Warehouses.NamesOfObjectsWithEmptySpace(Object.Ref).Count() <> 0);
	SetFieldAvailability();
	UpdateNumberOfExceptions();
	SetHeaderOfResponsibleStorageItems(ThisForm);
	
	GoodsDelivery.SetWarehouseFormElementSettings(ThisObject);
 	
	// Assembly and delivery
	SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	// End Assembly and Delivery
	
EndProcedure

&AtServer
Procedure SetFieldAvailability()
	
	Items.StartDateOfWarehouseManagemantSystemForGoodsReceipt.Enabled = Object.UseWarehouseManagemantSystemForGoodsReceipt;
	Items.StartDateOfWarehouseManagemantSystemForGoodsIssue.Enabled = Object.UseWarehouseManagemantSystemForGoodsIssue;
	
	Items.UseGoodsReceiptNoteStatuses.Enabled = Object.UseWarehouseManagemantSystemForGoodsReceipt;
	Items.UseGoodsIssueNoteStatuses.Enabled = Object.UseWarehouseManagemantSystemForGoodsIssue
		And Not Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
		And Not Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings
		And Not Object.UseItemsBatch
		And Not Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically;
	
	Items.DeliveryGroup.Enabled = Object.UseWarehouseManagemantSystemForGoodsIssue
		And ChangingBuildOrderIsAvailable;
	Items.DeliveryGroup.ReadOnly = Items.UseWarehouseManagemantSystemForGoodsIssue.ReadOnly;
	
	Items.GroupComment.Visible = Not ChangingBuildOrderIsAvailable;
	
	Items.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages.Enabled = 
		Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
	
	Items.UseInventoryRecountStatuses.Enabled = 
		Not Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
	Items.UseInventoryRecountStatuses.ReadOnly = 
		Not Items.UseInventoryRecountStatuses.Enabled;
	
	Items.UseWarerooms.Enabled = Object.UseWarehouseManagemantSystemForGoodsIssue
		And Object.UseWarehouseManagemantSystemForGoodsReceipt
		And Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
	Items.StartDateOfWareroomUse.Enabled = Object.UseWarerooms;
	
	Items.CustomizeBinLocationWarehousing.ReadOnly = Object.UseWarerooms
		Or Items.UseWarehouseManagemantSystemForGoodsIssue.ReadOnly;
	
	If Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance Then
		Items.RechargeSettingsPages.CurrentPage = Items.RechargeSettingsPageHyperlink;
		Items.PagesStartDateOfBinLocationWarehousingOfRemainingGoods.CurrentPage = 
			Items.PageStartDateOfBinLocationWarehousingOfRemainingGoodsDate;
	Else
		Items.RechargeSettingsPages.CurrentPage = Items.TheRechargeSettingsPageIsEmpty;
		Items.PagesStartDateOfBinLocationWarehousingOfRemainingGoods.CurrentPage = 
			Items.TheAddressStorageStartDatePageIsEmpty;
	EndIf;
		
	Items.WarehouseZoneUsage.ReadOnly = 
		Not Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
		And Not Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress;
	
	Items.CellDecoration.Visible = (Object.WarehouseStore = Enums.TypesOfWarehouses.WholesaleWarehouse)
		And GetFunctionalOption("UseWarehouseManagementSystem");
	
	Items.Shop.Enabled               = Object.ShopFloorStockroom;
	Items.Shop.AutoMarkIncomplete = Object.ShopFloorStockroom;
	
	Items.Department.Enabled               = Not Object.ShopFloorStockroom;
	Items.Department.AutoMarkIncomplete = False;
	
	Items.UseWarehouseManagemantSystemForGoodsReceipt.Enabled = Not Object.ShopFloorStockroom;
	Items.UseWarehouseManagemantSystemForGoodsIssue.Enabled    = Not Object.ShopFloorStockroom;
	
	SetAvailabilityOfRetailTypeOfPricesAndFormat();
	
EndProcedure

&AtServer
Procedure AgreeOnValuesAndSetAvailability()
	
	WarehousesClientServer.AgreeOnFeatureValues(Object);
	SetFieldAvailability();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfRetailTypeOfPricesAndFormat()
	
	ThisIsRetailWarehouse = (Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	
	RetailViewPricesAreAvailable = ThisIsRetailWarehouse;
	
	Items.ControlProductRange.Visible = GetFunctionalOption("UseRetailSales") 
													And ThisIsRetailWarehouse;
	ThereAreAssortmentSettings = GetFunctionalOption("UseStoreFormats")
								Or GetFunctionalOption("UseProductRange") 
								And GetFunctionalOption("UseRetailSales")
								And ThisIsRetailWarehouse;
	Items.ProductRangeGroup.Visible = ThereAreAssortmentSettings;
	
	Items.SetANewFormat.Visible = ThereAreAssortmentSettings And 
		AccessRight("Edit", Metadata.InformationRegisters.HistoryOfStoreFormatChange);
	Items.OpenTheFormatChangeHistory.Visible = ThereAreAssortmentSettings 
		And AccessRight("Read", Metadata.InformationRegisters.HistoryOfStoreFormatChange);
	
	If ThisIsRetailWarehouse Then
	
		Items.StoreFormat.Title = NStr("vi = 'Khuôn dạng cửa hàng';
										|ru = 'Формат магазина';
										|en = 'Store format'; fa = 'قالب فروشگاه';
										|it = 'Formato del negozio';
										|pl = 'Format sklepu';
										|tr = 'Mağaza formatı'");
	
	Else
	
		Items.StoreFormat.Title = NStr("vi = 'Khuôn dạng kho bãi';
										|ru = 'Формат склада';
										|en = 'Warehouse format'; fa = 'Warehouse format';
										|it = 'Formato del magazzino';
										|pl = 'Format magazynu';
										|tr = 'Ambar formatı'");
	
	EndIf; 
	
	If ControlProductRange Then
		RetailViewPricesAreAvailable = False;
	EndIf;
	
	Items.GroupRetailPriceType.Enabled 	= RetailViewPricesAreAvailable;
	
	AdjustVisibilityAvailabilityOfIndividualPriceViewSettings_(ThisForm);
	
EndProcedure


&AtServer
Procedure SetVisibilityByFO()
	
	Items.GroupWarehouseType.Visible                              = GetFunctionalOption("UseRetailSales");
	Items.GroupRetailPriceType.Visible                    	= GetFunctionalOption("UseRetailSales");
	Items.ProductRangeGroup.Visible                            = GetFunctionalOption("UseStoreFormats")
																		Or GetFunctionalOption("UseProductRange") 
																		And GetFunctionalOption("UseRetailSales")
																		And Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore;
	Items.ControlProductRange.Visible                    = GetFunctionalOption("UseRetailSales")
																		And Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore;
	Items.AdvancedWarehousing.Visible 								= GetFunctionalOption("UseWarehouseManagementSystem");
	Items.DeliveryGroup.Visible                               = GetFunctionalOption("UseDeliveryManagement");
	
	Items.Parent.Visible                                     = GetFunctionalOption("UseSeveralWarehouses");
	
	UseAdvancedDemandFulfillment = GetFunctionalOption("UseAdvancedDemandFulfillment");
	Items.SetUpStockReplenishment.Visible                  = UseAdvancedDemandFulfillment;
	Items.SettingOfProcurementStrategies.Visible     = UseAdvancedDemandFulfillment;
	
	If GetFunctionalOption("TradeManagement") Then
		Items.GroupShopStoreroom.Visible = False;
	EndIf; 
	
	If GetFunctionalOption("UseSeveralPriceTypes") Then
		Items.PageGroupTypesOfPrices.CurrentPage = Items.PageGroupTypesOfPrices.ChildItems.TheGroupCanUseSeveralTypesOfPrices;
	Else
		Items.PageGroupTypesOfPrices.CurrentPage = Items.PageGroupTypesOfPrices.ChildItems.GroupUseOneTypeOfPrice;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByAccessRights()

	// Elements of the group "Balance control and provision".
	ReadingConfiguringSoftwareControl = AccessRight("Read", Metadata.InformationRegisters.SetUpSupplyControl);
	ChangingSoftwareControlSettings = AccessRight("Update", Metadata.InformationRegisters.SetUpSupplyControl);
	Items.AvailableStockControl.Visible = ReadingConfiguringSoftwareControl;
	Items.AvailableStockControl.Enabled = ChangingSoftwareControlSettings;
	Items.ControlExceptions.Visible = ReadingConfiguringSoftwareControl;

	// The elements could be disabled by FO.

	If Items.SetUpStockReplenishment.Visible Then
		
		ViewInventoryMaintenanceSettings = AccessRight("View", Metadata.DataProcessors.SetUpStockReplenishment);
		Items.SetUpStockReplenishment.Visible = ViewInventoryMaintenanceSettings;
		
	EndIf;
	
	If Items.SettingOfProcurementStrategies.Visible Then
		
		ViewCustomizingWaysToProvideForNeeds = AccessRight("View",
			Metadata.DataProcessors.SettingOfProcurementStrategies);
		Items.SettingOfProcurementStrategies.Visible = ViewCustomizingWaysToProvideForNeeds;
		
	EndIf;

	RightToEditWarehouse = AccessRight("Update", Metadata.Catalogs.Warehouses);
	
	Items.ProcedureOfTransportationJobIndication1.Enabled = RightToEditWarehouse;
	Items.ProcedureOfTransportationJobIndication2.Enabled = RightToEditWarehouse;
	
EndProcedure

&AtServer
Procedure WhenReadingWithRestrictedRights(CurrentObject)

	// Details of the group "Balance control and collateral".
	SetPrivilegedMode(True);
	SetUpSupplyControl = Undefined;
	SetUpSupplyControl = InformationRegisters.SetUpSupplyControl.SettingUpWarehouse_(Object.Ref);

	If ValueIsFilled(SetUpSupplyControl.AvailableStockControl) Then
		AvailableStockControl = SetUpSupplyControl.AvailableStockControl;
	Else
		AvailableStockControl = CurrentObject.AvailableStockControl;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeRecordingWithRestrictedRights(CurrentObject)

	// Saving data in the details.
	If AccessRight("Update", Metadata.InformationRegisters.SetUpSupplyControl) Then
		CurrentObject.AvailableStockControl  = AvailableStockControl;
	EndIf;

EndProcedure

&AtServer
Function KeyForRecordingFuelSettings()
	DimensionStructure = New Structure;
	DimensionStructure.Insert("Warehouse", Object.Ref);
	DimensionStructure.Insert("Premise", Catalogs.Warerooms.EmptyRef());
	
	Return InformationRegisters.SettingsOfBinLocationWarehouses.CreateRecordKey(DimensionStructure);
EndFunction

&AtServer
Procedure UseWarehouseManagemantSystemForGoodsReceiptOnChangeServer()
	
	AgreeOnValuesAndSetAvailability();
	If Not Object.UseWarehouseManagemantSystemForGoodsReceipt
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Ref);
	Query.Text = Catalogs.Warehouses.TextOfRequestForDocumentsThatDependOnOrderSchemeUponReceipt();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfWarehouseManagemantSystemForGoodsReceipt = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfWarehouseManagemantSystemForGoodsReceipt.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UseWarehouseManagemantSystemForGoodsIssueOnChangeServer()
	
	AgreeOnValuesAndSetAvailability();
	Object.RealTimeStockControl    = Object.UseWarehouseManagemantSystemForGoodsIssue;
	Object.UseGoodsIssueNoteStatuses = Object.UseWarehouseManagemantSystemForGoodsIssue;
	
	If Not Object.UseWarehouseManagemantSystemForGoodsIssue
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Ref);
	Query.Text = Catalogs.Warehouses.RequestTextForDocumentsThatDependOnShippingOrderScheme();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfWarehouseManagemantSystemForGoodsIssue = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfWarehouseManagemantSystemForGoodsIssue.ReadOnly = False;
	EndIf;
	
	SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	
EndProcedure

&AtServer
Procedure UseWarehouseManagemantSystemForGoodsSurplusesShortagesOnChangeServer()
	
	AgreeOnValuesAndSetAvailability();
	If Not Object.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Ref);
	Query.Text = Catalogs.Warehouses.TextOfRequestForDocumentsThatDependOnOrderSchemeWhenReflectingSurplusesShortages();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UseWareroomsOnChangeServer()
	
	AgreeOnValuesAndSetAvailability();
	
	Items.WareroomsInCatalogsFilling.Visible = AccessRight("Update", Metadata.Catalogs.StorageBins)
		And Object.UseWarerooms
		And (Catalogs.Warehouses.NamesOfObjectsWithEmptySpace(Object.Ref).Count() <> 0);
	
	If Not Object.UseWarerooms
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Ref);
	Query.Text = Catalogs.Warehouses.RequestTextForDocumentsThatDependOnUseOfStorageFacilities();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfWareroomUse = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfWareroomUse.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeBinLocationWarehousingOnChangeServer()
	
	AgreeOnValuesAndSetAvailability();
	
	If Not (Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance)
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Ref);
	Query.Text = Catalogs.Warehouses.RequestTextForDocumentsThatDependOnUseOfAddressStorage();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfUsingWarehouseBinSystem = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfUsingWarehouseBinSystem.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateNumberOfExceptions()
	
	If Not AccessRight("Read", Metadata.InformationRegisters.SetUpSupplyControl) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	COUNT(DISTINCT SetUpSupplyControl.Products) AS NumberOfExceptions
		|FROM
		|	InformationRegister.SetUpSupplyControl AS SetUpSupplyControl
		|WHERE
		|	SetUpSupplyControl.Warehouse = &Warehouse
		|	AND SetUpSupplyControl.AvailableStockControl = &AvailableStockControl
		|	AND SetUpSupplyControl.Products <> VALUE(Catalog.Products.EmptyRef)";
		
	Query.SetParameter("AvailableStockControl",  Not AvailableStockControl);
	Query.SetParameter("Warehouse", Object.Ref);

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();

	NumberOfExceptions = 0;
	If Selection.Next() Then
		NumberOfExceptions = Selection.NumberOfExceptions;
	EndIf;
	
	HeaderNumberOfExceptions = NStr("vi = 'Ngoại trừ (%NumberOfExceptions%)';
									|ru = 'Исключения (%NumberOfExceptions%)';
									|en = 'Exceptions (%NumberOfExceptions%)'; fa = 'Exceptions (%NumberOfExceptions%)';
									|it = 'Eccezioni (%NumberOfExceptions%)';
									|pl = 'Wyjątki (%NumberOfExceptions%)';
									|tr = 'İstisnalar (%NumberOfExceptions%)'");
	HeaderNumberOfExceptions = StrReplace(HeaderNumberOfExceptions, "%NumberOfExceptions%", NumberOfExceptions);
	
	Items.ControlExceptions.Title = HeaderNumberOfExceptions;
	
EndProcedure

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

&AtClient
Procedure OpenTheFormatChangeHistory(Command)
	
	If Object.Ref.IsEmpty() Then
	
		QueryText = NStr("vi = 'Để mở lịch sử thay đổi tùy chỉnh cửa hàng, cần ghi lại phần tử. Ghi lại?';
						|ru = 'Для открытия истории изменения настроек магазина, необходимо записать элемент. Записать?';
						|en = 'To open change history of the shop settings, it is required to save the item. Save it?'; fa = 'To open change history of the shop settings, it is required to save the item. Save it?';
						|it = 'Per aprire la cronologia delle modifiche del negozio è necessario registrare l''elemento. Registrarlo?';
						|pl = 'Aby otworzyć historię zmian ustawień sklepu, należy zapisać element. Zapisać?';
						|tr = 'Mağaza ayarlarının değişiklik geçmişini açmak için öğeyi kaydetmeniz gerekmektedir. Kaydedilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại';
												|ru = 'Записать';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel);
		Notification = New CallbackDescription("OpenTheFormatChangeHistoryCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
	
	EndIf;
	
	OpenFormatChangeHistoryOpenForm();
	
EndProcedure

&AtClient
Procedure SetNewSettings(Command)
	
	If Object.Ref.IsEmpty() Then
	
		QueryText = NStr("vi = 'Để thiết lập tùy chỉnh cửa hàng, cần ghi lại phần tử. Ghi lại?';
						|ru = 'Для установки настроек магазина, необходимо записать элемент. Записать?';
						|en = 'To install the store settings, save the item. Do you want to save it?'; fa = 'To install the store settings, save the item. Do you want to save it?';
						|it = 'Per modificare le impostazioni del negozio, è necessario registrare l''elemento. Registrarlo?';
						|pl = 'Aby skonfigurować ustawienia sklepu, należy zapisać element. Zapisać?';
						|tr = 'Mağaza ayarlarının yapılandırılması için öğeyi kaydetmeniz gerekmektedir. Kaydedilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại';
												|ru = 'Записать';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel);
		Notification = New CallbackDescription("SetANewFormatCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
	
	EndIf; 
	
	SetNewFormatOpenForm();
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure SetANewFormatCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		
		If Write() Then
			SetNewFormatOpenForm();
		EndIf;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure OpenTheFormatChangeHistoryCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		
		If Write() Then
			OpenFormatChangeHistoryOpenForm();
		EndIf;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure SetNewFormatOpenForm()

	FillingValues = New Structure;
	FillingValues.Insert("Warehouse", Object.Ref);
	FillingValues.Insert("StoreFormat", StoreFormat);
	FillingValues.Insert("ControlProductRange", ControlProductRange);
	FillingValues.Insert("RetailPricesFromStoreFormat", RetailPricesFromStoreFormat);
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	Notification = New CallbackDescription("FormFormatChangeHistoryCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.RecordForm", FormParameters, ThisForm,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpenFormatChangeHistoryOpenForm()
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Object.Ref);
	
	Notification = New CallbackDescription("FormFormatChangeHistoryCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.Form.EditForm", FormParameters, ThisForm,,,,Notification);
	
EndProcedure

&AtClient
Procedure FormFormatChangeHistoryCompletion(Result, AdditionalParameters) Export 

	UpdateInformationAboutStoreFormat();

EndProcedure

&AtServer
Procedure UpdateInformationAboutStoreFormat()

	ProductRangeSettings = InformationRegisters.HistoryOfStoreFormatChange.CurAssortmentSettings(Object.Ref);
	FillPropertyValues(ThisForm, ProductRangeSettings);
	If Not ValueIsFilled(StoreFormat) Then
		StoreFormat = NStr("vi = '<không thiết lập>';
							|ru = '<не установлен>';
							|en = '<not set>'; fa = '<تنظیم نشده>';
							|it = '<non impostato>';
							|pl = '<nie ustawiony>';
							|tr = '<ayarlanmadı>'");
		Items.StoreFormat.Hyperlink = False;
	Else
		Items.StoreFormat.Hyperlink = True;
	EndIf; 
	
	SetAvailabilityOfRetailTypeOfPricesAndFormat();
	SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	UpdateViewsAndVisibilityOfPriceTypesByStoreFormat();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetHeaderOfResponsibleStorageItems(Form)
	
	CustodyWarehouse = Form.Object.CustodyWarehouse;
	
	Form.Items.SetUpSafekeeping.Title = ?(CustodyWarehouse, 
		NStr("vi = 'Hàng hóa đang bảo quản riêng';
			|ru = 'Товары находятся на ответственном хранении';
			|en = 'Available VMI '; fa = 'Available VMI ';
			|it = 'Le merci sono in custodia';
			|pl = 'Wiersze pozycji znajdują się w depozycie';
			|tr = 'Ürünler sorumlu depolamada bulunmaktadır'"),
		NStr("vi = 'Tùy chỉnh bảo quản riêng';
			|ru = 'Настроить ответственное хранение';
			|en = 'Set up VMI'; fa = 'تنظیم VMI';
			|it = 'Imposta la custodia';
			|pl = 'Ustaw depozyt';
			|tr = 'Satıcı tarafından yönetilen stoku ayarla'"));
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(Form)
	
	TitleText = NStr("vi = 'Tùy chỉnh đóng gói đơn hàng và giao hàng bởi bộ phận giao hàng của doanh nghiệp';
					|ru = 'Настроить сборку заказов и доставку своими курьерами';
					|en = 'Configure order picking and delivery by in-house couriers'; fa = 'پیکربندی جمع‌آوری سفارش و تحویل توسط پیک‌های داخلی';
					|it = 'Impostare assemblaggio degli ordini e consegna tramite propri corrieri';
					|pl = 'Skonfiguruj kompletację zamówień i dostawę przez swoich kurierów';
					|tr = 'Sipariş alımını ve kendi kurye teslimatınızı ayarlayın'");
	Object = Form.Object;
	
	If Object.WarehouseStore = PredefinedValue("Enum.TypesOfWarehouses.WholesaleWarehouse") Then
		Form.Items.SetUpOrderCollectionAndCourierDelivery.Enabled = False;
	ElsIf ValueIsFilled(Form.StoreFormat)
		And TypeOf(Form.StoreFormat) = Type("CatalogRef.StoreFormats") Then
		TitleText = NStr("vi = 'Xem tùy chỉnh đóng bộ đơn hàng và giao hàng bởi các bộ phận vận chuyển của doanh nghiệp theo khuôn dạng cửa hàng';
						|ru = 'Посмотреть настройки сборки заказов и доставки своими курьерами формата магазина';
						|en = 'View settings of order picking and delivery by own couriers of the store format'; fa = 'View settings of order picking and delivery by own couriers of the store format';
						|it = 'Visualizzare impostazioni di assemblaggio degli ordini e consegna tramite propri corrieri del formato dle punto vendita';
						|pl = 'Przejrzyj ustawienia kompletacji zamówień i dostawy przez swoich kurierów formatu sklepu';
						|tr = 'Mağaza formatındaki kendi kuryeleriniz tarafından sipariş alımı ve teslimat ayarlarını görüntüleyin'");
	ElsIf Object.StoreSupportsOrderAssembly
		Or Object.StoreSupportsDeliveryByOwnCouriers Then
		TitleText = NStr("vi = 'Thay đổi tùy chỉnh đóng gói đơn hàng và giao hàng bởi các bộ phận vận chuyển của doanh nghiệp';
						|ru = 'Изменить настройки сборки заказов и доставки своими курьерами';
						|en = 'Edit settings for order picking and delivery by own couriers'; fa = 'Edit settings for order picking and delivery by own couriers';
						|it = 'Modificare le impostazioni di assemblaggio degli ordini e di consegna tramite propri corrieri';
						|pl = 'Zmień ustawienia kompletacji zamówień i dostawy przez swoich kurierów';
						|tr = 'Kendi kuryeleriniz tarafından sipariş alımı ve teslimat ayarlarını değiştirin'");
	EndIf;
	
	Form.Items.SetUpOrderCollectionAndCourierDelivery.Title = TitleText;
		
EndProcedure

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure
// End StandardSubsystems.Properties

&AtClientAtServerNoContext
Procedure RefreshFormTitle(Form)

	Form.AutoTitle = False;
		
	If Form.Object.WarehouseStore = PredefinedValue("Enum.TypesOfWarehouses.RetailStore") Then
		CaptionPresentation = NStr("vi = 'Cửa hàng';
									|ru = 'Магазин';
									|en = 'Store'; fa = 'فروشگاه';
									|it = 'Negozio';
									|pl = 'Sklep';
									|tr = 'Mağaza'");
	Else
		CaptionPresentation = NStr("vi = 'Kho bãi';
									|ru = 'Склад';
									|en = 'Warehouse'; fa = 'Warehouse';
									|it = 'Magazzino';
									|pl = 'Magazyn';
									|tr = 'Ambar'");
	EndIf;
	
	If Not ValueIsFilled(Form.Object.Ref) Then
		Form.Title = CaptionPresentation + " (" + NStr("vi = 'tạo mới';
														|ru = 'создание';
														|en = 'create'; fa = 'ایجاد';
														|it = 'creazione';
														|pl = 'create';
														|tr = 'oluşturma'") + ")";
	Else
		Form.Title = Form.Object.Description + " (" + CaptionPresentation + ")";
	EndIf;

EndProcedure

&AtServer
Procedure CustomizeFormLocalization()
	
	Items.DepartmentGroup.ExtendedTooltip.Title = NStr("vi = 'Sử dụng khi đồng bộ dữ liệu lưu chuyển hàng hóa.';
														|ru = 'Используется при синхронизации данных о товародвижении.';
														|en = 'It is used when synchronizing data on inventory transfers.'; fa = 'It is used when synchronizing data on inventory transfers.';
														|it = 'Si usa alla sincronizzazione dei dati sul movimento delle merci';
														|pl = 'Używa się podczas synchronizacji danych o ruchu towarów.';
														|tr = 'Ürün hareketi verileri senkronize edilirken kullanılmaktadır.'");
	Items.DepartmentGroup.ExtendedTooltip.Title = NStr("vi = 'Sử dụng trong các bút toán về hàng hóa và khi đồng bộ dữ liệu về lưu chuyển hàng hóa.';
														|ru = 'Используется в бухгалтерских проводках по номенклатуре и при синхронизации данных о товародвижении.';
														|en = 'It is used in the accounting entries for products and when synchronizing data on inventory transfers.'; fa = 'It is used in the accounting entries for products and when synchronizing data on inventory transfers.';
														|it = 'Si usa nelle registrazioni contabili di articoli e nella sincronizzazione dei dati sul movimento delle merci.';
														|pl = 'Używa się w księgowych zatwierdzeniach w nomenklaturze i przy synchronizacji danych o ruchu towarów.';
														|tr = 'Öğeye göre muhasebe girişi hareketlerinde ve ürün hareket verilerinin eşitlenmesinde kullanılmaktadır.'");
	Return;
	
EndProcedure

&AtServer
Procedure RefreshUseRetailPriceViewCheckbox()

	UseTheRetailPriceView = (Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	
EndProcedure

&AtServer
Procedure UpdateUseCustomPriceViewCheckbox()

	UseAnIndividualViewOfThePrice = ValueIsFilled(Object.SpecialPriceType) And (Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfIndividualPriceViewSettings_(Form)
	
	Form.Items.SpecialPriceTypePresentation.Enabled	= (Form.UseAnIndividualViewOfThePrice 
												And Not Form.Items.UseAnIndividualViewOfThePrice.ReadOnly)
												And Form.ItIsAllowedToCreatePriceTypes;
	Form.Items.UseAnIndividualViewOfThePrice.Enabled = Form.ItIsAllowedToCreatePriceTypes;

	Form.Items.DecorationIndividualViewOfPrices.Visible = Form.UsePriceManagementSystem25;

EndProcedure


&AtServer
Procedure UpdateIndividualPriceViewPresentation()
	If ValueIsFilled(Object.SpecialPriceType) Then
		ArrayOfTexts = New Array;

		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng';
													|ru = 'Индивидуальный вид цен';
													|en = 'Special price type'; fa = 'نوع قیمت ویژه';
													|it = 'Tipo di prezzo individuale';
													|pl = 'Indywidualny rodzaj cen';
													|tr = 'Özelleştirilmiş fiyat türü'")));
		
		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"OpenIVC"));
		ArrayOfTexts.Add(")");
		
	Else
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng (chưa tùy chỉnh)';
													|ru = 'Индивидуальный вид цен (не настроен)';
													|en = 'Special price type (not configured)'; fa = 'Special price type (not configured)';
													|it = 'Tipo di prezzo individuale (non impostato)';
													|pl = 'Indywidualny rodzaj cen (nie ustawiono)';
													|tr = 'Özelleştirilmiş fiyat türü (ayarlanmadı)'")));

		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"CreateIVC"));
		ArrayOfTexts.Add(")");
	EndIf;
	
	SpecialPriceTypePresentation = New FormattedString(ArrayOfTexts);
EndProcedure

&AtClient
Procedure SpecialPriceTypePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "CreateIVC" Then
		
		If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
			QueryText = NStr("vi = 'Dữ liệu đã chỉnh sửa.
			|Chỉ có thể tùy chỉnh bảng giá riêng sau khi ghi lại phần tử.
			|Ghi lại phần tử?';
			|ru = 'Данные модифицированы.
			|Настройка индивидуального прайс-листа возможна только после записи элемента.
			|Записать элемент?';
			|en = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?'; fa = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?';
			|it = 'Dati modificati. 
			|L''impostazione del listino prezzi individuale è possibile solamente dopo la registrazione dell''elemento. 
			|Registrare elemento?';
			|pl = 'Dane zostały zmodyfikowane.
			|Ustawienie indywidualnego cennika jest możliwe tylko po zapisywaniu elementu.
			|Zapisać element?';
			|tr = 'Veriler değiştirildi.
			|Özelleştirilmiş fiyat listesi ayarı sadece öğenin kaydından sonra mümkündür.
			|Öğe kaydedilsin mi?'");
			
			ShowQueryBox(New CallbackDescription("CreateIVCQuestionCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
	
		CreateIVCCompletion();
		
	ElsIf FormattedStringURL = "OpenIVC" Then
			 	
		ShowValue(Undefined, Object.SpecialPriceType);
		
	EndIf;
EndProcedure

&AtClient
Procedure CreateIVCQuestionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;

	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	CreateIVCCompletion();
	
EndProcedure

&AtClient
Procedure CreateIVCCompletion()
	
	TransferResult = CreateIPLServer();
	
	If TransferResult.Result Then
		
		Read();
		UpdateIndividualPriceViewPresentation();
		ShowValue(Undefined, Object.SpecialPriceType);
		
	Else
		
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đã xảy ra lỗi khi tạo bảng giá riêng';
				|ru = 'Возникла ошибка при создании индивидуального прайс листа.';
				|en = 'An error occurred while generating the individual price list.'; fa = 'An error occurred while generating the individual price list.';
				|it = 'Возникла ошибка при создании индивидуального прайс листа.';
				|pl = 'An error occurred while generating the individual price list.';
				|tr = 'Özelleştirilmiş fiyat listesi oluşturulurken hata oluştu.'") + " " + TransferResult.ErrorDescription,
			Object.Ref,
			);
			
	EndIf;
	
EndProcedure

&AtServer
Function CreateIPLServer()
	
	TransferResult = SettingPricesServer.CreateIPL(Object.Ref, CurrentSessionDate());
	
	Return TransferResult;
	
EndFunction

&AtServer
Procedure UpdateViewsAndVisibilityOfPriceTypesByStoreFormat()
	If Object.WarehouseStore = Enums.TypesOfWarehouses.RetailStore And RetailPricesFromStoreFormat Then
		
		Items.GroupRetailPriceTypeStoreFormat.Visible = True;
		Items.GroupRetailPriceViewWarehouse.Visible 			= False;
		
		TypesOfPrices = Common.ObjectAttributesValues(StoreFormat, "RetailPriceType, SpecialPriceType");
		
		If ValueIsFilled(TypesOfPrices.RetailPriceType) Then
			RetailPriceViewView = TypesOfPrices.RetailPriceType;
		Else	 
			RetailPriceViewView = "<not specified>";
		EndIf;
		
		If ValueIsFilled(TypesOfPrices.SpecialPriceType) Then
			IndividualTypeOfPricesPresentation = "<used>";
		Else	 
			IndividualTypeOfPricesPresentation = "<not used>";
		EndIf;
	Else
		Items.GroupRetailPriceTypeStoreFormat.Visible = False;
		Items.GroupRetailPriceViewWarehouse.Visible 			= True;
		
		RetailPriceViewView = "";
		IndividualTypeOfPricesPresentation = "";
	EndIf;	
EndProcedure

#EndRegion

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	
EndProcedure

&AtServer
Procedure DeliveryOfGoodsWhenChangingPage(CommandName)
	
	GoodsDelivery.AddCommandToNavigateToListOfDeliveryPoints(
		ThisObject,
		Items.ContactInformationGroup.Name,
		CommandName);
	
EndProcedure

&AtClient
Procedure OpenListOfSubordinateDeliveryPoints()
	
	Filter = New Structure;
	Filter.Insert("Owner", Object.Ref);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	
	OpenForm("Catalog.DeliveryPoints.Form.OwnerDeliveryPoints", OpeningParameters);
	
EndProcedure

&AtClient
Procedure OpenDeliveryPointsEndForm(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Try
			
			ItemRecorded = Write();
			
		Except
			
			ItemRecorded = False;
			
			Information = ErrorInfo();
			MessageText = NStr("vi = 'Không thể ghi lại phần tử';
								|ru = 'Не удалось записать элемент';
								|en = 'Cannot save the item'; fa = 'Cannot save the item';
								|it = 'Cannot save the item';
								|pl = 'Cannot save the item';
								|tr = 'Öğe kaydedilemedi'");
			Refinement = CommonClientServer.ExceptionClarification(Information, MessageText);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Raise(Refinement.Text, Refinement.Category,, ErrorPresentation, Information);
			
		EndTry;
		
		If ItemRecorded Then
			
			OpenListOfSubordinateDeliveryPoints();
			
		EndIf;
		
	EndIf;
	
EndProcedure

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
