
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	CurrentSessionDate = CurrentSessionDate();
	
	If ValueIsFilled(Object.Ref) Then
		RoomWithinADay = DocumentDate(Object.Date, CurrentSessionDate) - BegOfDay(DocumentDate(Object.Date, CurrentSessionDate)) + 1;
	Else
		RoomWithinADay = CalculateNumberWithinDay(DocumentDate(Object.Date, CurrentSessionDate), Object.Ref);
		Object.Date = CalculateDocumentDate(DocumentDate(Object.Date, CurrentSessionDate), RoomWithinADay);
		If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
			Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
		Else
			Object.ValidityStartDate = Object.Date;
		EndIf; 
		SetVisibilityByOperationServer();
	EndIf;
	
	Items.RoomWithinADay.Visible = RoomWithinADay <> 1;
	
	UseCollectionManagement = GetFunctionalOption("UseCollectionManagement");
	If UseCollectionManagement Then
		NewLink = New ChoiceParameterLink("Filter.ItemsCollection", "Object.ItemsCollection");
		NewArray = New Array();
		NewArray.Add(NewLink);
		NewLinks = New FixedArray(NewArray);
		Items.GoodsProducts.ChoiceParameterLinks = NewLinks;
	EndIf; 
	
	If GetFunctionalOption("UseStoreFormats") Then
		Items.PlanningObject.TypeRestriction = New TypeDescription("CatalogRef.StoreFormats");
		Items.PlanningObject.ChooseType = False;
		If Not ValueIsFilled(Object.PlanningObject) Then
			Object.PlanningObject = Catalogs.StoreFormats.EmptyRef();
		EndIf; 
	Else
		Items.PlanningObject.Title = NStr("vi = 'Cửa hàng/kho bãi';
											|ru = 'Магазин/склад';
											|en = 'Store/warehouse'; fa = 'Store/warehouse';
											|it = 'Magazzino/deposito';
											|pl = 'Store/warehouse';
											|tr = 'Mağaza/ambar'");
		If Not ValueIsFilled(Object.PlanningObject) Then
			Object.PlanningObject = Catalogs.Warehouses.DefaultWarehouse();
		EndIf;
	EndIf; 
	
	SetAvailabilityOfClipboardCommands();
	
	Items.GoodsImportGoodsFromFile.Enabled = Not ThisForm.ReadOnly;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If ValueIsFilled(Object.Ref) Then
		RoomWithinADay = DocumentDate(Object.Date, CurrentSessionDate) - BegOfDay(DocumentDate(Object.Date, CurrentSessionDate)) + 1;
	Else
		RoomWithinADay = CalculateNumberWithinDay(DocumentDate(Object.Date, CurrentSessionDate), Object.Ref);
		Object.Date = CalculateDocumentDate(DocumentDate(Object.Date, CurrentSessionDate), RoomWithinADay);
		Object.ValidityStartDate = Object.Date;
	EndIf;
	
	SetVisibilityByOperationServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then	
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectByProductCategories.Form.SelectByCategories" Then	
		ProcessingSelectionBySubCategoriesOnServer(ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	RoomWithinADay = CalculateNumberWithinDay(DocumentDate(Object.Date, CurrentSessionDate), Object.Ref);
	Object.Date = CalculateDocumentDate(DocumentDate(Object.Date, CurrentSessionDate), RoomWithinADay);
	Items.RoomWithinADay.Visible = RoomWithinADay <> 1;
	If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
		Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
	Else
		Object.ValidityStartDate = Object.Date;
	EndIf; 
	
EndProcedure

&AtClient
Procedure RoomWithinADayOnChange(Item)
	
	Object.Date = CalculateDocumentDate(DocumentDate(Object.Date, CurrentSessionDate), RoomWithinADay);
	If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
		Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
	Else
		Object.ValidityStartDate = Object.Date;
	EndIf; 
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	
	Object.Goods.Clear();
	
	OperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure StageOnChange(Item)
	StepWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurchaseStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.PurchaseStartDate > Object.SalesStartDate Then
		Object.SalesStartDate = Object.PurchaseStartDate;
	EndIf; 
	
	If Object.PurchaseStartDate > Object.PurchaseRestrictionDate Then
		Object.PurchaseRestrictionDate = EndOfDay(Object.PurchaseStartDate)+1;
	EndIf;
	
	If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
		Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
	Else
		Object.ValidityStartDate = Object.Date;
	EndIf; 
	
EndProcedure

&AtClient
Procedure PurchaseRestrictionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.PurchaseStartDate > Object.PurchaseRestrictionDate Then
		Object.PurchaseRestrictionDate = EndOfDay(Object.PurchaseStartDate)+1;
	EndIf;  
	
EndProcedure

&AtClient
Procedure SalesStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.PurchaseStartDate > Object.SalesStartDate Then
		Object.SalesStartDate = Object.PurchaseStartDate;
	EndIf; 
	
	If Object.SalesStartDate > Object.SalesRestrictionDate Then
		Object.SalesRestrictionDate = EndOfDay(Object.SalesStartDate)+1;
	EndIf;
	
	If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
		Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
	Else
		Object.ValidityStartDate = Object.Date;
	EndIf; 
	
EndProcedure

&AtClient
Procedure SalesRestrictionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.SalesStartDate > Object.SalesRestrictionDate Then
		Object.SalesRestrictionDate = EndOfDay(Object.SalesStartDate)+1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ItemsCollectionOnChange(Item)
	
	Object.Goods.Clear();
	
	If ValueIsFilled(Object.ItemsCollection) Then
	
		Settings = ProductCollectionSettingsOnServer(Object.ItemsCollection);
		FillPropertyValues(Object, Settings);
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	IDOfCurLine = Items.Goods.CurrentData.GetID();
	If ProductsAlreadyAdded(IDOfCurLine) Then
		Return;
	EndIf;
	GoodsProductsOnChangeServer(IDOfCurLine);
EndProcedure

&AtClient
Procedure ProductsTypeOfPricesOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	If Not KindOfPricesCanBeUsed(CurrentRow.PriceKind) Then
		CurrentRow.PriceKind = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If Copy Then
		Item.CurrentData.Products = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// The main selection option in the document
&AtClient
Procedure OpenSelectionByCategories(Command)
	
	If Not CheckForMatching() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("HomePage", "ProductSelectionPage");
	FormParameters.Insert("PlanningObject", Object.PlanningObject);
	If Object.Operation = PredefinedValue("Enum.ProductRangeChangeTransactions.ChangeInProductRange") Then
	
		FormParameters.Insert("Stage", Object.Stage);
		FormParameters.Insert("Phase", Object.Phase);
	
	Else
	
		FormParameters.Insert("Stage", PredefinedValue("Enum.ProductRangeChangeSteps.AddToProductRange"));
		FormParameters.Insert("Phase", PredefinedValue("Enum.ProductRangePhases.PurchasesAndSalesArePermitted"));
	
	EndIf; 
	
	FormParameters.Insert("ItemsCollection", Object.ItemsCollection);
	FormParameters.Insert("ValidityStartDate", Object.ValidityStartDate);
	FormParameters.Insert("FormATreeWhenOpened", True);
	FormParameters.Insert("PickMode", True);
	FormParameters.Insert("GoodsAddressInStorage", PlaceGoodsInTemporaryStorage());
	
	OpenForm("DataProcessor.SelectByProductCategories.Form.SelectByCategories", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	If Not CheckForMatching() Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'thay đổi danh điểm mặt hàng';
																			|ru = 'изменение ассортимента';
																			|en = 'product range change'; fa = 'product range change';
																			|it = 'cambio di gamma';
																			|pl = 'zmiana asortymentu';
																			|tr = 'ürün gamı değişimi'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     True);
	FormParameters.Insert("Document ",                               Object.Ref);
	FormParameters.Insert("Title",                               HeaderParameter_);
	FormParameters.Insert("Date",                                    ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate));
	FormParameters.Insert("DoNotSplitSetsByComponents",        True);
	If UseCollectionManagement Then
		FormParameters.Insert("ItemsCollection",               Object.ItemsCollection);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	If Not CheckForMatching() Then
		Return;
	EndIf;
	
	FormParameters = New Structure("UUID", UUID);
	FormParameters.Insert("DisableCharacteristics", True);
	If UseCollectionManagement 
		And Object.Operation = PredefinedValue("Enum.ProductRangeChangeTransactions.CollectionManagement") Then
		FormParameters.Insert("ItemsCollection", Object.ItemsCollection);
	EndIf;
	CallbackDescriptionOnClose = New CallbackDescription("AddGoodsByPickingCompletion", ThisObject);
	
	OpenForm("DataProcessor.GoodsSelectionByPicking.Form", FormParameters, ThisForm,,,,CallbackDescriptionOnClose);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheAssortmentFormat(Command)
	
	FillParameters=New Structure;
	FillParameters.Insert("CommandName","FillInTheAssortmentFormat");
	FillInProductsOnRequestOnClient(FillParameters);
	
EndProcedure

&AtClient
Procedure FillInTheInventoryBalanceAndTurnover(Command)
	FillParameters=New Structure;
	FillParameters.Insert("CommandName","FillInTheInventoryBalanceAndTurnover");
	FillInProductsOnRequestOnClient(FillParameters);
EndProcedure

&AtClient
Procedure SetARoleForAllGoods(Command)
	If Object.Goods.Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền bảng %TabularSectionPresentation%. Không thể điền vai trò';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Роль не может быть заполнена';
							|en = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the role'; fa = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the role';
							|it = 'All''interno del documento la tabella %TabularSectionPresentation% non è compilata. Il ruolo non può essere compilato.';
							|pl = 'W dokumencie nie wypełniono tabeli %TabularSectionPresentation%. Rola nie może być wypełniona';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. Rol doldurulamaz'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", "Goods");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	SelectedRole = Undefined;

	OpenForm("Enum.ProductRangeRoles.ChoiceForm", , ThisForm,,,, New CallbackDescription("SetARoleForAllGoodsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetARoleForAllGoodsCompletion(Result, AdditionalParameters) Export
    
    SelectedRole = Result;
    If SelectedRole = Undefined Then
        Return;
    EndIf;
    SetPropsValueToAllLines("ProductRangeRole", SelectedRole);

EndProcedure

&AtClient
Procedure SetAPriceTypeForAllGoods(Command)
	
	If Object.Goods.Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền bảng %TabularSectionPresentation%. Không thể điền dạng giá';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Вид цен не может быть заполнен';
							|en = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the price type'; fa = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the price type';
							|it = 'All''interno del documento la tabella %TabularSectionPresentation% non è compilata. La tipologia di prezzo non può essere compilata';
							|pl = 'W dokumencie nie wypełniono tabeli %TabularSectionPresentation%. Rodzaj ceny nie może być wypełniony';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. Tür doldurulamaz'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", "Goods");
		ShowMessageBox(,WarningText);
		Return;
		
	EndIf;
	
	FormParameters = New Structure();
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("UseWhileSellingToCustomers", True);
	FilterStructure1.Insert("Status", PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid"));
	
	FormParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.TypesOfPrices.ChoiceForm", 
		FormParameters, 
		ThisForm,
		,
		,
		, 
		New CallbackDescription("SetAPriceTypeForAllGoodsCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetAPriceTypeForAllGoodsCompletion(Result, AdditionalParameters) Export
	
	SelectedPriceType = Result;
	If SelectedPriceType = Undefined Then
		Return;
	EndIf;
	If KindOfPricesCanBeUsed(SelectedPriceType) Then
		SetPropsValueToAllLines("PriceKind", SelectedPriceType);
	EndIf;

EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure FillInGoodsByCollection(Command)
	
	If Not ValueIsFilled(Object.ItemsCollection) Then
		Return;
	EndIf; 
	
	FillInProductsByProductCollectionOnServer();
	
EndProcedure

&AtClient
Procedure ImportGoodsFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ProductRangeChange.Goods";
	ImportParameters.Title = NStr("vi = 'Kết nhập danh sách hàng hóa từ tệp';
									|ru = 'Загрузка списка товаров из файла';
									|en = 'Import Item list from file'; fa = 'Import Item list from file';
									|it = 'Caricamento dell''elenco merci dal file';
									|pl = 'Poberanie listy towarów z pliku';
									|tr = 'Dosyadan ürün listesini yükleme'");
	ImportParameters.AdditionalParameters =  New Structure;
	ImportParameters.AdditionalParameters.Insert("ItemsCollection", Object.ItemsCollection);
	
	Notification = New CallbackDescription("ImportGoodsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdditionalProductsColumns");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.AdditionalColumnOfDocumentPrintForms.Code;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsSKU.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdditionalProductsColumns");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.AdditionalColumnOfDocumentPrintForms.SKU;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	If GetFunctionalOption("UseSalesRanks") Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsSalesRank.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesRank");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không đánh giá kết quả bán hàng>';
														|ru = '<без рейтинга продаж>';
														|en = '<without sales rank>'; fa = '<without sales rank>';
														|it = '<senza il ranking delle vendite>';
														|pl = '<bez rankingu sprzedaży>';
														|tr = '<satış sıralaması olmadan>'"));
		
	EndIf;
	

EndProcedure

&AtClient
Procedure FillInProductsOnRequestOnClient(FillParameters)
	
	FillMode=0;
	If Object.Goods.Count()=0 Then
		FillMode=1;
	Else
		QueryText = NStr("vi = 'Phần bảng chứa xâu ký tự.
			|Xóa phần bảng?';
			|ru = 'Табличная часть содержит строки.
			|Очистить табличную часть?';
			|en = 'Table contains rows.
			|Clear the table?'; fa = 'Table contains rows.
			|Clear the table?';
			|it = 'La parte tabulare contiene delle righe. 
			| Cancellare la parte tabulare?';
			|pl = 'Sekcja tabelaryczna zawiera wiersze. 
			|Oczyścić sekcję tabelaryczną?';
			|tr = 'Tablo bölümü satırları içermektedir.
			|Tablo bölümü temizlensin mi?'");
		
		ShowQueryBox(
		New CallbackDescription(
		"FillGoodsOnRequestOnCustomerAfterTSCleaningIssue", 
		ThisObject, 
		New Structure("FillParameters", FillParameters)), 
		QueryText, 
		QuestionDialogMode.YesNoCancel);
		Return;
	EndIf;
	FillInProductsOnRequestOnClientByAssortmentFormat(FillParameters, FillMode);
	
EndProcedure

&AtClient
Procedure FillGoodsOnRequestOnCustomerAfterTSCleaningIssue(QuestionResult, AdditionalParameters) Export
	
	FillParameters = AdditionalParameters.FillParameters;
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillMode=1;
	ElsIf QuestionResult = DialogReturnCode.No Then
		FillMode=2;
	ElsIf QuestionResult = DialogReturnCode.Cancel Then
		FillMode=0;
	EndIf;
	
	FillInProductsOnRequestOnClientByAssortmentFormat(FillParameters, FillMode);

EndProcedure

&AtClient
Procedure FillInProductsOnRequestOnClientByAssortmentFormat(Val FillParameters, FillMode)
	
	Var SelectedPlanningObject, PeriodDate_, PeriodDialog;
	
	If FillMode=0 Then
		Return;
	EndIf;
	
	If FillParameters.CommandName="FillInTheAssortmentFormat" Then
		SelectedPlanningObject = Undefined;
		
		OpenForm("Catalog.StoreFormats.ChoiceForm", , ThisForm,,,, New CallbackDescription("FillInProductsOnRequestOnCustomerAfterSelection", ThisObject, New Structure("FillParameters, FillMode", FillParameters, FillMode)), FormWindowOpeningMode.LockOwnerWindow);
		Return;
		
	ElsIf FillParameters.CommandName="FillInTheInventoryBalanceAndTurnover" Then
		PeriodDialog = New StandardPeriodEditDialog();
		PeriodDate_ = Object.Date;
		PeriodDialog.Period = New StandardPeriod(BegOfMonth(PeriodDate_), PeriodDate_);
		PeriodDialog.Show(New CallbackDescription("FillInProductsOnRequestOnClientCompletion", ThisObject, New Structure("FillParameters, FillMode", FillParameters, FillMode)));
		Return;
	EndIf;
	FillInProductsOnRequestOnFragmentClient(FillParameters, FillMode);

EndProcedure

&AtClient
Procedure FillInProductsOnRequestOnCustomerAfterSelection(Result, AdditionalParameters) Export
    
    FillParameters = AdditionalParameters.FillParameters;
    FillMode = AdditionalParameters.FillMode;
    
    SelectedPlanningObject = Result;
    If SelectedPlanningObject = Undefined Then
        Return;
    EndIf;
    FillParameters.Insert("PlanningObject",SelectedPlanningObject);
    FillParameters.Insert("Period",BegOfDay(Object.ValidityStartDate));
    
    
    FillInProductsOnRequestOnFragmentClient(FillParameters, FillMode);

EndProcedure


// Fills in the table part of the document for the assortment / balances
// 
// Parameters:
// 	Period - StandardPeriod - the period to fill in
// 	AdditionalParameters - Structure - structure of additional parameters
&AtClient
Procedure FillInProductsOnRequestOnClientCompletion(Period, AdditionalParameters) Export
	
	FillParameters = AdditionalParameters.FillParameters;
	FillMode = AdditionalParameters.FillMode;
	
	If Period <> Undefined Then 
		FillParameters.Insert("StartDate",BegOfDay(Period.StartDate));
		FillParameters.Insert("EndDate",EndOfDay(Period.EndDate));
	Else
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.PlanningObject) Then
		If TypeOf(Object.PlanningObject) = Type("CatalogRef.Warehouses") Then
			
			OpenForm("Catalog.Warehouses.ChoiceForm",
				, 
				ThisForm,
				,
				,
				,
				New CallbackDescription("FillInGoodsOnRequestOnClientAfterSelectingPlanningObject", 
				ThisObject, AdditionalParameters),
				FormWindowOpeningMode.LockOwnerWindow);
			
		Else
			OpenForm("Catalog.StoreFormats.ChoiceForm",
				, 
				ThisForm,
				,
				,
				,
				New CallbackDescription("FillInGoodsOnRequestOnClientAfterSelectingPlanningObject", 
				ThisObject, AdditionalParameters),
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf; 
		
		Return;
	EndIf;
	FillParameters.Insert("PlanningObject",Object.PlanningObject);
	
	FillInProductsOnRequestOnFragmentClient(FillParameters, FillMode);

EndProcedure

// Fill in the products on request on the client after selecting the planning object.
// 
// Parameters:
//  Result - CatalogRef.Warehouses,CatalogRef.StoreFormats
//  AdditionalParameters - Structure - structure of additional parameters:
//  *FillParameters - Structure - structure of parameters for executing the command
//  *FillMode - Number
&AtClient
Procedure FillInGoodsOnRequestOnClientAfterSelectingPlanningObject(Result, AdditionalParameters) Export
	
	SelectedPlanningObject = Result;
	If SelectedPlanningObject = Undefined Then
		Return;
	EndIf;
	
	FillParameters = AdditionalParameters.FillParameters;
	FillMode = AdditionalParameters.FillMode;
	
	Object.PlanningObject = SelectedPlanningObject;
	
	FillParameters.Insert("PlanningObject",Object.PlanningObject);
	
	FillInProductsOnRequestOnFragmentClient(FillParameters, FillMode);
	
EndProcedure

&AtClient
Procedure FillInProductsOnRequestOnFragmentClient(Val FillParameters, FillMode)
    
    FillParameters.Insert("FillMode",FillMode);
    
    FillInProductsOnRequestOnServer(FillParameters);

EndProcedure

// The procedure fills in the goods based on the request data
// , the request is formed depending on the name of the filling team.
&AtServer
Procedure FillInProductsOnRequestOnServer(FillParameters)
	
	If FillParameters.FillMode=1 Then
		Object.Goods.Clear();
	Else
		FillParameters.Insert("ArrayOfProducts_2",Object.Goods.Unload().UnloadColumn("Products"));
	EndIf;
	//
	Query=New Query;
	QueryText=GenerateTextForCommand(FillParameters.CommandName,FillParameters.FillMode);
	Query.Text=QueryText;
	//
	For Each Parameter In FillParameters Do
		If Parameter.Key="FillMode" Or Parameter.Key="CommandName" Then
			Continue;
		EndIf;
		Query.SetParameter(Parameter.Key,Parameter.Value);
	EndDo;
	If FillParameters.CommandName="FillInTheInventoryBalanceAndTurnover" Then
		Query.SetParameter("TypeOfPricesInFormat", Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType"));
	EndIf;
	Query.SetParameter("UseCollectionManagement", UseCollectionManagement);
	Query.SetParameter("ItemsCollection", Object.ItemsCollection);
	//
	Result=Query.Execute();
	Selection=Result.Select();
	While Selection.Next() Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection, "Products, SalesRank, ProductRangeRole, PriceKind");
	EndDo;
	
EndProcedure

// The procedure generates the text of the request used for filling in products
&AtServer
Function GenerateTextForCommand(NameOfFillCommand,FillMode)
	
	QueryText="";
	
	If NameOfFillCommand="FillInTheInventoryBalanceAndTurnover" Then
		QueryText=
		"SELECT ALLOWED DISTINCT
		|	NestedQuery.Warehouse AS Warehouse
		|INTO Warehouses
		|FROM
		|	(SELECT
		|		HistoryOfChangesToStoreFormatsCrossSection.Warehouse AS Warehouse
		|	FROM
		|		InformationRegister.HistoryOfStoreFormatChange.SliceLast(&StartDate, ) AS HistoryOfChangesToStoreFormatsCrossSection
		|	WHERE
		|		HistoryOfChangesToStoreFormatsCrossSection.StoreFormat = &PlanningObject
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		HistoryOfStoreFormatChange.Warehouse
		|	FROM
		|		InformationRegister.HistoryOfStoreFormatChange AS HistoryOfStoreFormatChange
		|	WHERE
		|		HistoryOfStoreFormatChange.Period > &StartDate
		|		AND HistoryOfStoreFormatChange.Period <= &EndDate
		|		AND HistoryOfStoreFormatChange.StoreFormat = &PlanningObject
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Warehouses.Ref
		|	FROM
		|		Catalog.Warehouses AS Warehouses
		|	WHERE
		|		Warehouses.Ref = &PlanningObject) AS NestedQuery
		|
		|INDEX BY
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsInWarehousesBalancesAndTurnover.Products AS Products,
		|	VALUE(Enum.ProductRangeRoles.AdditionalProductRange) AS ProductRangeRole,
		|	GoodsInWarehousesBalancesAndTurnover.Products.SalesRank AS SalesRank,
		|	&TypeOfPricesInFormat AS PriceKind
		|FROM
		|	AccumulationRegister.ProductStock.BalanceAndTurnovers(
		|			&StartDate,
		|			&EndDate,
		|			,
		|			,
		|			Warehouse IN
		|				(SELECT
		|					Warehouses.Warehouse
		|				FROM
		|					Warehouses AS Warehouses)
		|			AND &RequestTextProductSelectionCriteria) AS GoodsInWarehousesBalancesAndTurnover
		|WHERE
		|	CASE
		|			WHEN NOT &UseCollectionManagement
		|				THEN TRUE
		|			WHEN &UseCollectionManagement
		|					AND GoodsInWarehousesBalancesAndTurnover.Products.ItemsCollection = &ItemsCollection
		|				THEN TRUE
		|			ELSE FALSE
		|		END
		|
		|GROUP BY
		|	GoodsInWarehousesBalancesAndTurnover.Products
		|
		|ORDER BY
		|	GoodsInWarehousesBalancesAndTurnover.Products.Description";
		
		QueryText = StrReplace(
			QueryText, 
			"AND &RequestTextProductSelectionCriteria", 
			?(FillMode=2,"AND NOT Products IN (&ArrayOfProducts_2)",""));
		
	ElsIf NameOfFillCommand="FillInTheAssortmentFormat" Then
		
		QueryText=
		"SELECT ALLOWED
		|	ProductRange.Products AS Products,
		|	ProductRange.ProductRangeRole AS ProductRangeRole,
		|	ProductRange.SalesRank AS SalesRank,
		|	ProductRange.PriceKind AS PriceKind
		|FROM
		|	InformationRegister.ProductRange.SliceLast(
		|			ENDOFPERIOD(&Period, DAY),
		|			PlanningObject = &PlanningObject
		|AND &RequestTextProductSelectionCriteria
		|				) AS ProductRange
		|WHERE
		|	ProductRange.PurchasesAreAllowed
		|	AND CASE
		|			WHEN NOT &UseCollectionManagement
		|				THEN TRUE
		|			WHEN &UseCollectionManagement
		|					AND ProductRange.Products.ItemsCollection = &ItemsCollection
		|				THEN TRUE
		|			ELSE FALSE
		|		END
		|
		|ORDER BY
		|	ProductRange.Products.Description";
		
		QueryText = StrReplace(
			QueryText, 
			"AND &RequestTextProductSelectionCriteria", 
			?(FillMode=2,"			AND NOT Products IN (&ArrayOfProducts_2)",""));
		
	Else //such a command is not provided - it is necessary to raise an exception
		ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Phương án điền không xác định: %1';
										|ru = 'Неизвестный вариант заполнения: %1';
										|en = 'Unknown filling variant: %1'; fa = 'Unknown filling variant: %1';
										|it = 'Variante di compilazione sconosciuta: %1';
										|pl = 'Nieznany wariant wypełnienia: %1';
										|tr = 'Bilinmeyen doldurma seçeneği: %1'"),
									NameOfFillCommand);
		Raise(ErrorMessageText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// The procedure fills in products from the selection
// Parameters: 
//  	ValueSelected - Structure
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	If ValueIsFilled(ValueSelected.GoodsAddressInStorage) Then
		AddProductsFromTemporaryStorageOnServer(ValueSelected.GoodsAddressInStorage, True);
	EndIf;
	
EndProcedure

// The procedure fills in products from the selection by category
// Parameters: 
//  	ValueSelected - Structure
&AtServer
Procedure ProcessingSelectionBySubCategoriesOnServer(ValueSelected)
	
	If ValueIsFilled(ValueSelected.GoodsAddressInStorage) Then
		Object.Goods.Clear();
		AddProductsFromTemporaryStorageOnServer(ValueSelected.GoodsAddressInStorage, False);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProductsFromTemporaryStorageOnServer(AddressInTempStorage, AddProductsToTable_)
	
	If AddProductsToTable_ Then
		TableOfGoods = GetFromTempStorage(AddressInTempStorage);
		TableOfGoodsSupplemented = TableOfGoodsSupplementedWithObjectSAssortment(TableOfGoods);
	Else
		TableOfGoodsSupplemented = GetFromTempStorage(AddressInTempStorage);
	EndIf;
	
	For Each RowOfProduct In TableOfGoodsSupplemented Do
		FilterParameters = New Structure("Products", RowOfProduct.Products);
		FoundRows = Object.Goods.FindRows(FilterParameters);
		If FoundRows.Count() = 0 Then
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, RowOfProduct, "Products, ProductRangeRole, PriceKind, SalesRank");
			If Not ValueIsFilled(NewRow.ProductRangeRole) Then
				NewRow.ProductRangeRole = Enums.ProductRangeRoles.AdditionalProductRange;
			EndIf;
			If Not ValueIsFilled(NewRow.PriceKind) Then
				NewRow.PriceKind = Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// This function supplements the product table with the data in the Assortment register for the current store format
// set for the start date
// Parameters: 
//  	TableOfGoods - ValueTable
&AtServer
Function TableOfGoodsSupplementedWithObjectSAssortment(TableOfGoods)
	Query = New Query;
	Query.Text = "SELECT
	|	TableOfGoods.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Goods.Products AS Products,
	|	ISNULL(ProductRange.ProductRangeRole, VALUE(Enum.ProductRangeRoles.AdditionalProductRange)) AS ProductRangeRole,
	|	ISNULL(ProductRange.SalesRank, Goods.Products.SalesRank) AS SalesRank,
	|	ISNULL(ProductRange.PriceKind, &TypeOfPricesInFormat) AS PriceKind
	|FROM
	|	TTProducts_1 AS Goods
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(
	|				ENDOFPERIOD(&OnDate, DAY),
	|				PlanningObject = &PlanningObject
	|					AND Products IN
	|						(SELECT
	|							T.Products
	|						FROM
	|							TTProducts_1 AS T)) AS ProductRange
	|		ON (ProductRange.Products = Goods.Products)";
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("OnDate", Object.ValidityStartDate);
	Query.SetParameter("PlanningObject", Object.PlanningObject);
	RetailPriceType = Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType");
	Query.SetParameter("TypeOfPricesInFormat", RetailPriceType);
	TableOfGoodsSupplemented = Query.Execute().Unload();
	Return TableOfGoodsSupplemented;
EndFunction

&AtServer
Procedure OperationOnChangeServer()
	
	If Object.Operation = Enums.ProductRangeChangeTransactions.ChangeInProductRange Then
		
		Object.ItemsCollection = Catalogs.ItemsCollections.EmptyRef();
		Object.PurchaseStartDate = Undefined;
		Object.SalesStartDate = Undefined;
		
	Else
		
		Object.Stage = Enums.ProductRangeChangeSteps.EmptyRef();
	EndIf; 
	
	If ValueIsFilled(Object.PurchaseStartDate) And ValueIsFilled(Object.SalesStartDate) Then
		Object.ValidityStartDate = Min(Object.PurchaseStartDate, Object.SalesStartDate);
	Else
		Object.ValidityStartDate = Object.Date;
	EndIf; 
	
	SetVisibilityByOperationServer();
	
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer(IDOfCurLine)
	
	CurrentRow=Object.Goods.FindByID(IDOfCurLine);
	AssortmentStructure=ProductRangeServer.StructureOfStateOfProductRangeInFormat(CurrentRow.Products,
		Object.PlanningObject,
		Object.ValidityStartDate);
	
	CurrentRow.ProductRangeRole = ?(ValueIsFilled(AssortmentStructure.ProductRangeRole),
		AssortmentStructure.ProductRangeRole,
		Enums.ProductRangeRoles.AdditionalProductRange);
	If ValueIsFilled(AssortmentStructure.PriceKind) Then
		CurrentRow.PriceKind = AssortmentStructure.PriceKind;
	Else
		CurrentRow.PriceKind = Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType");
	EndIf;
	
	If Not ValueIsFilled(AssortmentStructure.SalesRank) 
		And GetFunctionalOption("UseSalesRanks") Then
		CurrentRow.SalesRank = Common.ObjectAttributeValue(CurrentRow.Products, "SalesRank");
	Else
		CurrentRow.SalesRank = AssortmentStructure.SalesRank;
	EndIf;
	
EndProcedure

&AtServer
Function KindOfPricesCanBeUsed(PriceKind)
	
	Result = True;
	
	If Not ValueIsFilled(PriceKind) Then
		Return Result;
	EndIf;
	
	PriceTypeParameters = Common.ObjectAttributesValues(PriceKind, "UseWhileSellingToCustomers,PriceIncludesVAT");
	
	If ValueIsFilled(PriceKind) And Not PriceTypeParameters.UseWhileSellingToCustomers Then
		MessageText = NStr("vi = 'Chỉ có thể ấn định các dạng giá sử dụng khi bán hàng.';
							|ru = 'Можно назначить только виды цен, используемые при продаже.';
							|en = 'Only price types used on sale can be assigned.'; fa = 'Only price types used on sale can be assigned.';
							|it = 'Posso essere impostate soltanto le tipologie di prezzi utilizzatte nella vendita.';
							|pl = 'Można przydzielić tylko rodzaje ceny, używane podczas sprzedaży.';
							|tr = 'Sadece satışta kullanılan fiyat türlerini atayabilirsiniz.'");
		Object.Phase=Enums.ProductRangePhases.EmptyRef();
		CommonClientServer.MessageToUser(
			MessageText,
			Object.Ref,
			,
			,
			True);
		Result = False;
	EndIf;
	
	If Not ValueIsFilled(Object.PlanningObject) Then
		Return Result;
	EndIf;
	
	If TypeOf(Object.PlanningObject) = Type("CatalogRef.Warehouses") Then
		ParametersOfPlaniroavniaObject = Common.ObjectAttributesValues(Object.PlanningObject, "RetailPriceType.PriceIncludesVAT, WarehouseStore");
	Else
		ParametersOfPlaniroavniaObject = Common.ObjectAttributesValues(Object.PlanningObject, "RetailPriceType.PriceIncludesVAT");
	EndIf; 
	
	If (TypeOf(Object.PlanningObject) = Type("CatalogRef.Warehouses")
			And ParametersOfPlaniroavniaObject.WarehouseStore = Enums.TypesOfWarehouses.RetailStore
			And PriceTypeParameters.PriceIncludesVAT <> ParametersOfPlaniroavniaObject.RetailPriceTypePriceIncludesVAT)
		Or (TypeOf(Object.PlanningObject) <> Type("CatalogRef.Warehouses")
			And PriceTypeParameters.PriceIncludesVAT <> ParametersOfPlaniroavniaObject.RetailPriceTypePriceIncludesVAT)
		 Then
		MessageText = NStr("vi = 'Phương pháp kế toán thuế GTGT của dạng giá đã chọn cần tương ứng với phương pháp kế toán thuế GTGT của dạng giá chuẩn.';
							|ru = 'Метод учета НДС выбранного вида цен должен соответствовать методу учета НДС вида цен формата.';
							|en = 'VAT accounting method of the selected price type should correspond to the VAT accounting method of the price format kind.'; fa = 'VAT accounting method of the selected price type should correspond to the VAT accounting method of the price format kind.';
							|it = 'Il sistema di contabilizzazione dell''IVA per tipologia di prezzo selezionato deve corrispondere al sistema di contabilizzazione dell''IVA per tipologia di prezzo del formato.';
							|pl = 'Metoda ewidencji VAT wybranego rodzaju ceny powinna odpowiadać metodzie ewidencji VAT rodzaju ceny formatu';
							|tr = 'Seçilen fiyat türünün KDV muhasebesi metodu, format fiyat türünün KDV muhasebesi metoduna uygun olmalıdır.'");
		CommonClientServer.MessageToUser(
			MessageText,
			Object.Ref,
			,
			,
			True);
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetPropsValueToAllLines(Var_AttributeName, ValueToSet)
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods[Var_AttributeName] = ValueToSet;
	EndDo;
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Columns = "Products,ProductRangeRole,PriceKind,SalesRank";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Or TableOfGoods.Columns.Find("Products") = Undefined Then
		Return;
	EndIf;
	
	For Each RowOfProduct In TableOfGoods Do
		
		FilterParameters = New Structure("Products", RowOfProduct.Products);
		FoundRows = Object.Goods.FindRows(FilterParameters);
		If FoundRows.Count() = 0 Then
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			If Not ValueIsFilled(CurrentRow.ProductRangeRole) Then
				CurrentRow.ProductRangeRole = Enums.ProductRangeRoles.AdditionalProductRange;
			EndIf;
			If Not ValueIsFilled(CurrentRow.PriceKind) Then
				CurrentRow.PriceKind = Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType");
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtServer
Function ProductsAlreadyAdded(IDOfCurLine)
	Found4 = False;
	CurrentRow = Object.Goods.FindByID(IDOfCurLine);
	If CurrentRow <> Undefined Then
		TheStructureOfTheSearch = New Structure("Products", CurrentRow.Products);
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		LineNumber = CurrentRow.LineNumber;
		If FoundRows.Count() > 1 Then
			Found4 = True;
			For Each FoundRow In FoundRows Do
				If FoundRow.LineNumber <> CurrentRow.LineNumber Then
					LineNumber = FoundRow.LineNumber;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If Found4 Then
			MessageText = NStr("vi = 'Hàng hóa ""%1"" đã có trong dòng %2';
								|ru = 'Товар ""%1"" уже содержится в строке %2';
								|en = 'Line %2 already contains goods ""%1""'; fa = 'Line %2 already contains goods ""%1""';
								|it = 'La merce ""%1"" è già presente all''interno della riga %2';
								|pl = 'Towar ""%1"" jest już w wierszu %2';
								|tr = '""%1"" ürünü zaten %2 satırında bulunmaktadır'");
			ItemName = Common.ObjectAttributeValue(CurrentRow.Products, "Description");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, ItemName, LineNumber);
			CommonClientServer.MessageToUser(
				MessageText,
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", LineNumber, "Products"),
				"",
				True);
			CurrentRow.Products = Catalogs.Products.EmptyRef();
		EndIf;
	EndIf;
	Return Found4;
EndFunction

&AtClientAtServerNoContext
Function CalculateDocumentDate(DocumentDate, RoomWithinADay)
	
	Return BegOfDay(DocumentDate) + RoomWithinADay - 1;
	
EndFunction

&AtClientAtServerNoContext
Function DocumentDate(Date, CurrentSessionDate)
	
	Return ?(ValueIsFilled(Date), Date, BegOfDay(CurrentSessionDate));
	
EndFunction

&AtServerNoContext
Function CalculateNumberWithinDay(DocumentDate, Ref)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	MAX(ProductRangeChange.Date) AS Date
	|FROM
	|	Document.ProductRangeChange AS ProductRangeChange
	|WHERE
	|	ProductRangeChange.Ref <> &Ref
	|	AND ProductRangeChange.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod");
	
	Query.SetParameter("BeginOfPeriod", BegOfDay(DocumentDate));
	Query.SetParameter("EndOfPeriod", EndOfDay(DocumentDate));
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() And Selection.Date <> Null Then
		// The beginning of the day is 0 seconds. Since at least one document already exists,
		// you need to add 1 (0 second corresponds to the document number 1).
		// We will also add one, since we need the number of the corresponding document.
		Return Selection.Date - BegOfDay(DocumentDate) + 2;
	Else
		Return 1;
	EndIf;
	
EndFunction

// Notifies about the need to fill in the document details when calling the selection
//
&AtClient
Function CheckForMatching()
	
	HasErrors = False;
	
	ClearMessages();
	If Not ValueIsFilled(Object.ValidityStartDate) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Có hiệu lực từ""';
							|ru = 'Поле ""Действует с"" не заполнено';
							|en = '""Valid from"" is required'; fa = '""Valid from"" is required';
							|it = 'Il campo ""Valido da"" non è compilato';
							|pl = 'Nie wypełniono pola ""Действует с""';
							|tr = '""Geçerlilik başlangıcı"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.ValidityStartDate",, HasErrors);
	EndIf;
	If Object.Operation = PredefinedValue("Enum.ProductRangeChangeTransactions.ChangeInProductRange") 
		And Not ValueIsFilled(Object.Stage) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Giai đoạn""';
							|ru = 'Поле ""Этап"" не заполнено';
							|en = '""Stage"" is required'; fa = '""Stage"" is required';
							|it = 'Il campo ""Fase"" non è compilato';
							|pl = 'Nie wypłeniono pola ""Этап""';
							|tr = '""Aşama"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.Stage",, HasErrors);
	EndIf;
	If Object.Operation = PredefinedValue("Enum.ProductRangeChangeTransactions.CollectionManagement") 
		And Not ValueIsFilled(Object.ItemsCollection) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Bộ sưu tập mặt hàng""';
							|ru = 'Поле ""Коллекция номенклатуры"" не заполнено';
							|en = '""Items collection"" is required'; fa = '""Items collection"" is required';
							|it = 'Campo ""Collezione articoli"" non è compilato';
							|pl = 'Pole ""Zbiór nomenklatury"" nie wypełniono';
							|tr = '""Öğe Koleksiyonu"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.ItemsCollection",, HasErrors);
	EndIf;
	If Not ValueIsFilled(Object.PlanningObject) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Khuôn dạng cửa hàng""';
							|ru = 'Поле ""Формат магазина"" не заполнено';
							|en = '""Store format"" is required'; fa = '""Store format"" is required';
							|it = 'Il campo ""Formato di negozio"" non è stato compilato';
							|pl = 'Nie wypełniono pola ""Формат магазина""';
							|tr = '""Mağaza Formatı"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.PlanningObject",, HasErrors);
	EndIf;
	
	Return Not HasErrors; 
	
EndFunction

&AtServer
Function PlaceGoodsInTemporaryStorage()

	Table = Object.Goods.Unload();
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChangingProductRange.Products,
	|	ChangingProductRange.ProductRangeRole,
	|	ChangingProductRange.SalesRank,
	|	ChangingProductRange.PriceKind
	|INTO Goods
	|FROM
	|	&Goods AS ChangingProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products.ProductCategory AS ProductCategory,
	|	ISNULL(CategoryPlan.Brand, VALUE(Catalog.Brands.EmptyRef)) AS Brand,
	|	Goods.Products,
	|	Goods.ProductRangeRole,
	|	ISNULL(ProductRange.SalesRank, Goods.Products.SalesRank) AS SalesRank,
	|	Goods.PriceKind,
	|	CASE
	|		WHEN ProductRange.PurchasesAreAllowed AND ProductRange.SalesAreAllowed
	|			THEN VALUE(Enum.ProductRangePhases.PurchasesAndSalesArePermitted)
	|		WHEN ProductRange.PurchasesAreAllowed AND NOT ProductRange.SalesAreAllowed
	|			THEN VALUE(Enum.ProductRangePhases.OnlyPurchasesAreAllowed)
	|		WHEN NOT ProductRange.PurchasesAreAllowed AND ProductRange.SalesAreAllowed
	|			THEN VALUE(Enum.ProductRangePhases.OnlySalesAreAllowed)
	|		WHEN NOT ProductRange.PurchasesAreAllowed AND NOT ProductRange.SalesAreAllowed
	|			THEN VALUE(Enum.ProductRangePhases.SalesAndPurchasesAreProhibited)
	|		ELSE VALUE(Enum.ProductRangePhases.EmptyRef)
	|	END AS ProductRangePhase
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(&ValidityStartDate, PlanningObject = &PlanningObject) AS ProductRange
	|		ON Goods.Products = ProductRange.Products
	|		LEFT JOIN InformationRegister.ProductMixQuotas.SliceLast(&ValidityStartDate, PlanningObject = &PlanningObject) AS CategoryPlan
	|		ON Goods.Products.ProductCategory = CategoryPlan.ProductCategory
	|			AND Goods.Products.Brand = CategoryPlan.Brand
	|			AND (CategoryPlan.Period IN
	|				(SELECT
	|					MAX(K.Period)
	|				FROM
	|					InformationRegister.ProductMixQuotas AS K
	|				WHERE
	|					K.Period <= &ValidityStartDate
	|					AND K.PlanningObject = &PlanningObject))
	|";
	
	Query.SetParameter("Goods", Table);
	Query.SetParameter("ValidityStartDate", Object.Date);
	Query.SetParameter("PlanningObject", Object.PlanningObject);

	QueryResult = Query.Execute();

	TableOfGoods = QueryResult.Unload();
	
	Return PutToTempStorage(TableOfGoods, UUID);

EndFunction

&AtServer
Procedure SetVisibilityByOperationServer()
	
	If Object.Operation = Enums.ProductRangeChangeTransactions.ChangeInProductRange Then
		
		Items.Stage.Visible = True;
		Items.ItemsCollection.Visible = False;
		Items.CollectionManagementGroup.Visible = False;
		Items.GoodsFillInGoodsByCollection.Visible = False;
	
	Else
		
		Items.ItemsCollection.Visible = True;
		Items.Stage.Visible = False;
		Items.CollectionManagementGroup.Visible = True;
		Items.GoodsFillInGoodsByCollection.Visible = True;
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure StepWhenChangingOnServer()
	
	If Object.Stage = Enums.ProductRangeChangeSteps.AddToProductRange
		Or Object.Stage = Enums.ProductRangeChangeSteps.ChangeOfProductRangeStatus Then
		Object.Phase = Enums.ProductRangePhases.PurchasesAndSalesArePermitted;
	ElsIf Object.Stage = Enums.ProductRangeChangeSteps.AddToProductRangeWithDelayedSalesStart Then
		Object.Phase = Enums.ProductRangePhases.OnlyPurchasesAreAllowed;
	ElsIf Object.Stage = Enums.ProductRangeChangeSteps.RemoveFromProductRange Then
		Object.Phase = Enums.ProductRangePhases.OnlySalesAreAllowed;
	ElsIf Object.Stage = Enums.ProductRangeChangeSteps.TransferToArchiveRevoke Then
		Object.Phase = Enums.ProductRangePhases.SalesAndPurchasesAreProhibited;
	Else
		Object.Phase = Enums.ProductRangePhases.EmptyRef();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Giai đoạn không chính xác';
				|ru = 'Некорректный этап';
				|en = 'Incorrect stage'; fa = 'Incorrect stage';
				|it = 'Fase non corretta';
				|pl = 'Nieprawidłowy etap';
				|tr = 'Yanlış aşama'"),
			Object.Ref,
			"Object.Stage",
			,
			True);
	EndIf;
EndProcedure

&AtServerNoContext
Function ProductCollectionSettingsOnServer(ItemsCollection)
	
	Return Common.ObjectAttributesValues(ItemsCollection, "PurchaseStartDate, PurchaseRestrictionDate, SalesStartDate, SalesRestrictionDate");
	
EndFunction

&AtServer
Procedure FillInProductsByProductCollectionOnServer()
	
	Query=New Query;
	Query.Text=
	"SELECT ALLOWED
	|	CatProducts.Ref AS Products,
	|	ISNULL(ProductRangeSliceLast.ProductRangeRole, VALUE(Enum.ProductRangeRoles.AdditionalProductRange)) AS ProductRangeRole,
	|	ISNULL(ProductRangeSliceLast.SalesRank, CatProducts.SalesRank) AS SalesRank,
	|	ISNULL(ProductRangeSliceLast.PriceKind, &TypeOfPricesInFormat) AS PriceKind
	|FROM
	|	Catalog.Products AS CatProducts
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(&OnDate, PlanningObject = &PlanningObject) AS ProductRangeSliceLast
	|		ON CatProducts.Ref = ProductRangeSliceLast.Products
	|WHERE
	|	CatProducts.ItemsCollection = &ItemsCollection
	|	AND NOT CatProducts.DeletionMark";
	
	Query.SetParameter("TypeOfPricesInFormat", Common.ObjectAttributeValue(Object.PlanningObject, "RetailPriceType"));
	Query.SetParameter("PlanningObject", Object.PlanningObject);
	Query.SetParameter("ItemsCollection", Object.ItemsCollection);
	Query.SetParameter("OnDate", ?(ValueIsFilled(Object.PurchaseStartDate), Object.PurchaseStartDate, Object.Date));
	
	Result=Query.Execute();
	
	Object.Goods.Clear();
	
	Selection=Result.Select();
	
	While Selection.Next() Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection, "Products, ProductRangeRole, PriceKind");
	EndDo;
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export 

	If Not IsTempStorageURL(Result) Then
		Return;
	EndIf; 
	
	If ValueIsFilled(Result) Then
		AddProductsFromTemporaryStorageOnServer(Result, True);
	EndIf;

EndProcedure

&AtClient
Procedure SetSalesRank(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
	
		ShowMessageBox(, NStr("vi = 'Cần tách chọn dòng trong danh sách';
								|ru = 'Необходимо выделить строки в списке';
								|en = 'Select lines in the list'; fa = 'Select lines in the list';
								|it = 'È necessario inserire delle righe nell''elenco';
								|pl = 'Należy wybrać wiersze w liście';
								|tr = 'Listedeki satırları belirtmeniz gerekmektedir'"));
		Return;
	
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.SelectedRows[0]).SalesRank;
	
	Notification = New CallbackDescription("SetSalesRankCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", CurrentRow);
	FormParameters.Insert("CloseOnChoice", True);
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnOwnerClose", True);
	FormParameters.Insert("AllowRootChoice", False);
	
	OpenForm("Catalog.SalesRanks.ChoiceForm", 
		FormParameters, 
		ThisObject, 
		UUID,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetSalesRankCompletion(SelectionResult, AdditionalParameters) Export

	If SelectionResult = Undefined Then
		Return;
	EndIf; 
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
	
		TSRow = Object.Goods.FindByID(SelectedRow);
		TSRow.SalesRank = SelectionResult;
	
	EndDo;
	
EndProcedure

&AtClient
Procedure ImportGoodsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	UploadProductsFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure UploadProductsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	PriceKind = Undefined;
	PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind, New Structure("UseWhileSellingToCustomers", True));
	UseSalesRanks = GetFunctionalOption("UseSalesRanks");
	
	ProductsAdded_ = False;
	For Each TableRow In ImportedData Do 
		
		If Not ValueIsFilled(TableRow.Products) Then 
			Continue;
		EndIf;
		
		NewLineProducts = Object.Goods.Add();
		NewLineProducts.Products = TableRow.Products;
		NewLineProducts.ProductRangeRole = TableRow.ProductRangeRole;
		If UseSeveralPriceTypes Then
			NewLineProducts.PriceKind = TableRow.PriceKind;
		Else
			NewLineProducts.PriceKind = PriceKind;
		EndIf; 
		If UseSalesRanks Then
			NewLineProducts.SalesRank = TableRow.SalesRank;
		EndIf; 
		ProductsAdded_ = True;

	EndDo;
	
	If ProductsAdded_ Then
		Modified = True;
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_PurchaseStartDate" Then
		PurchaseStartDateOnChange(Items.PurchaseStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_PurchaseRestrictionDate" Then
		PurchaseRestrictionDateOnChange(Items.PurchaseRestrictionDate);
	ElsIf Item.Name = "sh_ShamsiInput_SalesStartDate" Then
		SalesStartDateOnChange(Items.SalesStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_SalesRestrictionDate" Then
		SalesRestrictionDateOnChange(Items.SalesRestrictionDate);
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
