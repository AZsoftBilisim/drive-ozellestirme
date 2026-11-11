#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	FillInServiceDetailsOfTSGoods();
	PackingListsServer.RenumberLines(ThisForm, Object.Goods);
	PackingListsServer.CreateNavigationLabel(ThisForm,
		EntryLevelTitle(Object.Ref, Object.Code));
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CurrentData = Items.Goods.CurrentData;
	If ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		CurrentData.Products = ValueSelected;
		ProductsPackingListWhenChanged("GoodsProducts", CachedValues);
		Items.Goods.CurrentItem = Items.GoodsNumberOfPackages;
		Items.Goods.CurrentItem = Items.GoodsProducts;
		
	ElsIf ChoiceSource.FormName = "Document.PackingList.Form.ChoiceForm" Then
		
		CurrentData.PackingList = ValueSelected;
		ProductsPackingListWhenChanged("GoodsPackingList", CachedValues);
		Items.Goods.EndEditRow(False);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Not Object.GoodsViewMode Then
		
		DocumentObject = FormAttributeToValue("Object");
		
		If Not DocumentObject.CheckFilling() Then
			Object.GoodsViewMode = True;
			DisplayModeOnChangeServer();
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KindOnChange(Item)
	
	KindOnChangeServer();
	
EndProcedure

&AtClient
Procedure NavigationTextURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	WhenMovingToAnotherLevelServer(Var_URL);
	
EndProcedure

&AtClient
Procedure DisplayModeOnChange(Item)
	DisplayModeOnChangeServer();
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.Goods, CachedValues);
EndProcedure

#EndRegion

#Region ProductsFormTableHandlers

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If PackingListsClient.CheckPrepareTransitionToPackingListWhenSelecting(Items.Goods, Field.Name) Then
		WhenMovingToAnotherLevelServer(Items.Goods.CurrentData.PackingList);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	PackingListsClient.AtBeginningOfEditingPMWithPackingLists(ThisForm, CachedValues, NewRow)
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	PackingListsClient.AtEndOfEditingPMWithPackingLists(ThisForm, NewRow, CancelEdit);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	PackingListsClient.BeforeYouStartAddingVTCHSPackingLists(Items.Goods, Cancel, Copy, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	PackingListsClient.BeforeDeletingPMLinesWithPackingSheets(Items.Goods, CachedValues, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	GoodsAfterDeleteRowServer(CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("SeriesSpecificationParameters, Warehouse", SeriesSpecificationParameters, Undefined));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ProductsNomenclaturePackingListIfChanged(Item)
	
	ProductsPackingListWhenChanged(Item.Name, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If Not ValueIsFilled(CurrentRow.PackingListParent) Then
		RecalculateNumberOfSeats();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PackingListsClient.StartOfProductPlaceSelection(ThisForm, Item, StandardProcessing, Object.GoodsViewMode);
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(CachedValues)
	
	PackingListsServer.AfterRemovalOfVTCHSPackingSheets(ThisForm, Object.Goods, Object.GoodsViewMode);
	
EndProcedure

&AtClient
Procedure ProductsPackingListParentOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Items.Goods.CurrentData.PackingListParent);
EndProcedure

&AtClient
Procedure ProductsPackingListParentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportPackingLists = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure UpLevel(Command)
	
	UpLevelServer();
	
EndProcedure

&AtClient
Procedure Unpack(Command)
	
	PackingListsClient.UnpackPackingList(ThisForm);
	
EndProcedure

&AtClient
Procedure Pack(Command)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chọn dòng để hợp nhất.';
							|ru = 'Выберите строки для объединения.';
							|en = 'Select lines to merge.'; fa = 'Select lines to merge.';
							|it = 'Selezionate le righe da unire.';
							|pl = 'Wybierz wiersze do połączenia';
							|tr = 'Birleştirilecek satırları seçin.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	NewPackingList = PackServer();
	
	If ValueIsFilled(NewPackingList) Then
		NotificationText1 = NStr("vi = 'Tạo:';
								|ru = 'Создание:';
								|en = 'Created:'; fa = 'ایجادشده:';
								|it = 'Creazione:';
								|pl = 'Utworzenie:';
								|tr = 'Oluşturuldu:'");
		ShowUserNotification(NotificationText1,
			GetURL(NewPackingList),
			NewPackingList,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();

	ClearMessages();

	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	PackingListsClient.BreakUpPMStringWithPackingLists(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure SortAsc(Command)
	CurrentColumn = Items.Goods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "ASC");
	EndIf;
EndProcedure

&AtClient
Procedure SortDesc(Command)
	CurrentColumn = Items.Goods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "DESC");
	EndIf;
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region StandardSubsystems_Print

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

&AtServer
Procedure OnReadCreateAtServer()
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.PackingList);
	
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisForm, Object.Goods,
		EntryLevelTitle(Object.Ref, Object.Code));
	FillInServiceDetailsOfTSGoods();
	
	KindOnChangeServer();
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	LinesToSupplement = New Array;
	For Each RowOfGoods In ItemsFromStorage Do
		If ValueIsFilled(RowOfGoods.PackingList)
			And RowOfGoods.PackingList = Object.Ref Then
			MessageText = NStr("vi = 'Không thể đưa %PackingList% vào chính nó.';
								|ru = 'Нельзя включить %PackingList% в состав самого себя.';
								|en = '%PackingList% cannot be included in itself.'; fa = '%PackingList% cannot be included in itself.';
								|it = 'Non includere %PackingList% nella composizione del medesimo.';
								|pl = 'Nie można włączyć %PackingList% do składu samego siebie.';
								|tr = '%PackingList%''ni kendi başına bir parça olarak eklemek mümkün değildir.'");
			MessageText = StrReplace(MessageText, "%PackingList%", RowOfGoods.PackingList);
			CommonClientServer.MessageToUser(MessageText);
			Continue;
		EndIf;
		If ValueIsFilled(RowOfGoods.PackingList)
			And PackingLists.FindRows(New Structure("PackingList",RowOfGoods.PackingList)).Count() > 0 Then
			MessageText = NStr("vi = '%PackingList% đã được thêm vào phần bảng.';
								|ru = '%PackingList% уже был добавлен в табличную часть.';
								|en = '%PackingList% has already been added to the table.'; fa = '%PackingList% has already been added to the table.';
								|it = '%PackingList% è stato già aggiunto alla parte tabulare.';
								|pl = '%PackingList% już został dodany do części tabelarycznej';
								|tr = '%PackingList% zaten tablo kısmına eklenmiş.'");
			MessageText = StrReplace(MessageText, "%PackingList%", RowOfGoods.PackingList);
			CommonClientServer.MessageToUser(MessageText);
			Continue;
		EndIf;
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		If ValueIsFilled(RowOfGoods.PackingList) Then
			LinesToSupplement.Add(StringTSGoods);
			StringTSGoods.ThisIsAPackingList = True;
			StringTSGoods.Count = 1;
			StringTSGoods.NumberOfPackages = 1;
		EndIf;
	EndDo;
	
	PackingListsServer.AddLinesOnPackingLists(ThisForm, Object.Goods, LinesToSupplement);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	PackingListsServer.FillInServiceDetails(ThisForm, Object.Goods, StructureOfActions);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	// The download goes to the upper level, you need to go
	If Not Object.GoodsViewMode Then
		PackingListsServer.WhenMovingToAnotherLevel(ThisForm,
			Object.Goods, "0", EntryLevelTitle(Object.Ref,Object.Code));
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																		"GoodsPurpose",
																		"Object.Goods.ItemsType");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng mặt hàng nhà cung cấp>';
													|ru = '<номенклатура поставщика не используется>';
													|en = '<vendor part numbers are not used>'; fa = '<vendor part numbers are not used>';
													|it = '<nomenclatura del fornitore non utilizzata>';
													|pl = '<nie jest używany wykaz towarów dostawcy>';
													|tr = '<satıcı parça numaraları kullanılmıyor>'"));
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	//
	
	PackingListsServer.EstablishConditionalAppearanceTakingIntoAccountPackingLists(ThisForm);
	
EndProcedure

// The handler that will be called after closing a question about unpacking
//
&AtClient
Procedure AfterClosingUnboxingQuestion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		UnpackServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsPackingListWhenChanged(FieldName, CachedValues)
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If ValueIsFilled(Object.Ref)
		And CurrentRow.PackingList = Object.Ref Then
		
		ErrorText = NStr("vi = 'Không thể đưa %PackingList% vào chính nó.';
						|ru = 'Нельзя включить %PackingList% в состав самого себя.';
						|en = '%PackingList% cannot be included in itself.'; fa = '%PackingList% cannot be included in itself.';
						|it = 'Non includere %PackingList% nella composizione del medesimo.';
						|pl = 'Nie można włączyć %PackingList% do składu samego siebie.';
						|tr = '%PackingList%''ni kendi başına bir parça olarak eklemek mümkün değildir.'");
		ErrorText = StrReplace(ErrorText, "%PackingList%", CurrentRow.PackingList);
		Field = CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PackingList");
		CommonClientServer.MessageToUser(ErrorText,,Field);
		CurrentRow.PackingList = CachedValues.PackingList;
		
	EndIf;
	
	StructureOfActionsWithCurLine = New Structure;
	StructureOfActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActionsWithCurLine.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithCurLine.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	StructureOfActionsWithCurLine.Insert("CheckSeriesCalculateStatus",
		New Structure("SeriesSpecificationParameters, Warehouse", SeriesSpecificationParameters, Undefined));
	
	If FieldName = "GoodsPackingList" Then
		StructureOfActionsWithAddedStrings_ = New Structure;
		StructureOfActionsWithAddedStrings_.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActionsWithAddedStrings_.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActionsWithAddedStrings_.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	Else
		StructureOfActionsWithAddedStrings_ = Undefined;
	EndIf;
	
	PackingListsServer.ProductsPackingListWhenChanged(ThisForm, Object.Goods,
		FieldName, CachedValues, StructureOfActionsWithCurLine, StructureOfActionsWithAddedStrings_);
	
EndProcedure

&AtServer
Procedure DisplayModeOnChangeServer()
	
	PackingListsServer.DisplayModeOnChange(ThisForm, Object.Goods, EntryLevelTitle(Object.Ref, Object.Code));
	
EndProcedure

&AtServer
Procedure WhenMovingToAnotherLevelServer(Var_URL)
	
	PackingListsServer.WhenMovingToAnotherLevel(ThisForm,
		Object.Goods, Var_URL, EntryLevelTitle(Object.Ref,Object.Code));
	
EndProcedure

#Region WorkingWithClipboard

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

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,PackingList";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ProcessClipboardGoodsTable(TableOfGoods);
	
	LinesToSupplement = New Array;
	
	For Each RowOfGoods In TableOfGoods Do
		
		If ValueIsFilled(RowOfGoods.PackingList)
			And RowOfGoods.PackingList = Object.Ref Then
			
			MessageText = NStr("vi = 'Không thể đưa %PackingList% vào chính nó.';
								|ru = 'Нельзя включить %PackingList% в состав самого себя.';
								|en = '%PackingList% cannot be included in itself.'; fa = '%PackingList% cannot be included in itself.';
								|it = 'Non includere %PackingList% nella composizione del medesimo.';
								|pl = 'Nie można włączyć %PackingList% do składu samego siebie.';
								|tr = '%PackingList%''ni kendi başına bir parça olarak eklemek mümkün değildir.'");
			MessageText = StrReplace(MessageText, "%PackingList%", RowOfGoods.PackingList);
			
			CommonClientServer.MessageToUser(MessageText);
			Continue;
			
		EndIf;
		
		SelectionByPackingList = New Structure("PackingList", RowOfGoods.PackingList);
		
		If ValueIsFilled(RowOfGoods.PackingList)
			And PackingLists.FindRows(SelectionByPackingList).Count() > 0 Then
			
			MessageText = NStr("vi = '%PackingList% đã được thêm vào phần bảng.';
								|ru = '%PackingList% уже был добавлен в табличную часть.';
								|en = '%PackingList% has already been added to the table.'; fa = '%PackingList% has already been added to the table.';
								|it = '%PackingList% è stato già aggiunto alla parte tabulare.';
								|pl = '%PackingList% już został dodany do części tabelarycznej';
								|tr = '%PackingList% zaten tablo kısmına eklenmiş.'");
			MessageText = StrReplace(MessageText, "%PackingList%", RowOfGoods.PackingList);
			
			CommonClientServer.MessageToUser(MessageText);
			Continue;
			
		EndIf;
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfGoods);
		
		If ValueIsFilled(RowOfGoods.PackingList) Then
			LinesToSupplement.Add(CurrentRow);
			
			CurrentRow.ThisIsAPackingList = True;
			CurrentRow.Count         = 1;
			CurrentRow.NumberOfPackages = 1;
		EndIf;
		
	EndDo;
	
	PackingListsServer.AddLinesOnPackingLists(ThisForm, Object.Goods, LinesToSupplement);
	
	ArticleAttribute                    = New Structure("Products", "SKU");
	ProductTypeAttribute            = New Structure("Products", "ItemsType");
	AttributeCharacteristicsAreUsed = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",                    ArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",            ProductTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", AttributeCharacteristicsAreUsed);
	
	PackingListsServer.FillInServiceDetails(ThisForm, Object.Goods, StructureOfActions);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	// The download goes to the upper level, you need to make the transition.
	If Not Object.GoodsViewMode Then
		
		PackingListsServer.WhenMovingToAnotherLevel(ThisForm, Object.Goods, "0",
			EntryLevelTitle(Object.Ref, Object.Code));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessClipboardGoodsTable(TableOfGoods)
	
	If TableOfGoods.Columns.Find("Products") = Undefined Then
		TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	EndIf;
	If TableOfGoods.Columns.Find("PackingList") = Undefined Then
		TableOfGoods.Columns.Add("PackingList", New TypeDescription("DocumentRef.PackingList"));
	EndIf;
	
	NewProductTable = TableOfGoods.CopyColumns();
	
	TMCommonUse.NumberValueTable(TableOfGoods, "LineNumber");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CAST(Goods.Products AS Catalog.Products)     AS Products,
	|	CAST(Goods.PackingList AS Document.PackingList) AS PackingList
	|INTO Goods
	|FROM
	|	&TableOfGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber
	|FROM
	|	Goods AS Goods
	|WHERE
	|	(Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|		AND Goods.PackingList <> VALUE(Document.PackingList.EmptyRef))
	|	OR Goods.Products.ItemsType IN (&FilterByProductType)";
	
	FilterParameters = New Array;
	FilterParameters.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterParameters.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	Query.SetParameter("TableOfGoods",          TableOfGoods);
	Query.SetParameter("FilterByProductType", FilterParameters);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FillPropertyValues(NewProductTable.Add(), TableOfGoods[Selection.LineNumber]);
	EndDo;
	
	TableOfGoods = NewProductTable;
	
EndProcedure

#EndRegion

&AtServer
Function PackServer()
	
	Return PackingListsServer.PackServer(ThisForm);
	
EndFunction

&AtServer
Procedure UnpackServer()
	
	PackingListsServer.UnpackPackingList(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTSGoods()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	PackingListsServer.FillInServiceDetails(ThisForm, Object.Goods, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Function EntryLevelTitle(Ref, Code)
	
	ObjectPresentation = Ref.Metadata().ObjectPresentation;
	
	If ValueIsFilled(Ref) Then
		Return ObjectPresentation + " " + Code;
	Else
		Return ObjectPresentation + " " + NStr("vi = '(tạo)';
												|ru = '(создание)';
												|en = '(Create)'; fa = '(Create)';
												|it = '(creazione)';
												|pl = '(Create)';
												|tr = '(oluştur)'");
	EndIf;
	
EndFunction

&AtServer
Procedure UpLevelServer()
	
	FoundRows = PackingLists.FindRows(New Structure("PackingList",PackingListParent));
	WhenMovingToAnotherLevelServer(FoundRows[0].PackingListParent);
	
EndProcedure

&AtServer
Procedure KindOnChangeServer()
	
	If Object.Kind = Enums.PackingListKinds.Incoming Then
		Items.Code.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
		Items.Code.AutoMarkIncomplete = True;
	Else
		Items.Code.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
		Items.Code.AutoMarkIncomplete = False;
		Items.Code.MarkIncomplete = False;
	EndIf;
	Items.FooterGroup.Visible = (Object.Kind = Enums.PackingListKinds.Outgoing);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfSeats()
	
	PackingListsServer.RecalculateNumberOfSeats(ThisForm, Object.Goods)
	
EndProcedure

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		CurrentData = Items.Goods.CurrentData;
		If CurrentData = Undefined Then
			MessageText = NStr("vi = 'Chọn dòng sản phẩm mà bạn muốn chỉ định seri.';
								|ru = 'Выберите строку товаров, для которой необходимо указать серии.';
								|en = 'Select a goods line for which the batch shall be specified.'; fa = 'Select a goods line for which the batch shall be specified.';
								|it = 'Selezionare la riga dei prodotti per la quale è necessario specificare le serie.';
								|pl = 'Wybierz wiersz towarów, dla których chcesz określić serie.';
								|tr = 'Partisini belirtmek istediğin ürün satırını seç.'");
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
	EndIf;
	CurDataId = CurrentData.GetID();
	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
	
	ReturnValue_1 = Undefined;

	
	OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CachedValues);
    EndIf;

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtServer
Procedure ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CachedValues)
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,,CachedValues);
	FillInServiceDetailsOfTSGoods();
	
EndProcedure

#EndRegion

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

&AtServer
Procedure SortRows(ColumnName, Direction)
	ColumnNameDirection = StrReplace(Items[ColumnName].DataPath, "Object.Goods.","") + " " + Direction; 
	
	Object.Goods.Sort(ColumnNameDirection);
	If UsePackingLists Then
		PackingListsServer.RenumberLines(ThisObject, Object.Goods);
	EndIf;
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
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
