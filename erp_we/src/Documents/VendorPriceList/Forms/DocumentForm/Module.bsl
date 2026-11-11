#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var OldProducts; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var OldPartnerProducts; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var OldCharacteristic; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var Changed_Price; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var RowAdded;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	FlagOfOpeningAForm = True;

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	UsePriceManagementSystem25 = False;
	
	SetFillInAutomaticallyFeaturePricesByProductRange(True);
	SetToAutomaticallyAddCharacteristics(True);
	CurrentDate = CurrentSessionDate();
	
	OnReadCreateAtServer();
	
	SavedSettings = Common.CommonSettingsStorageLoad("Document.VendorPriceList", "Document.VendorPriceList");
	If SavedSettings <> Undefined Then
		ShowMarkupPercent   = SavedSettings.ShowMarkupPercent;
		ShowPriceChange    = SavedSettings.ShowPriceChange;
		ShowEffectivePrices  = SavedSettings.ShowEffectivePrices;
	EndIf;
	
	SetVisibilityOfEditColumns(ThisObject, True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RowAdded = False;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If FlagOfOpeningAForm = True Then
		AddressOfDataCacheStorage = "";
		OnReadCreateAtServer();
	EndIf;
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If PriceTree.GetItems().Count() = 0 Then
	
		ErrorText = NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Hàng hóa"".';
						|ru = 'Не введено ни одной строки в список ""Товары"".';
						|en = 'No line entered into the Item list.'; fa = 'No line entered into the Item list.';
						|it = 'Non è stata inserita alcuna riga nell''elenco ""Merci"".';
						|pl = 'Nie wprowadzono żadnego wiersza do listy ""Wiersze pozycji""';
						|tr = '""Ürünler"" listesine herhangi bir satır girilmedi.'");
		
		Common.MessageToUser(
			ErrorText,
			Object.Ref,
			"PriceTree",
			,
			Cancel);
		
	Else
		
		If Object.Posted Then
			SettingPricesServer.CheckCorrectnessOfDocument(ThisForm, Cancel);
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Write
	     Or WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		SettingPricesServer.CheckCorrectnessOfDocument(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	If Modified Or Not ValueIsFilled(Object.Ref) Then

		Data = New Structure;
		Data.Insert("Form", ThisForm);
		Data.Insert("Documents", New Array);
		Data.Insert("SaveBasic", False);
		Data.Documents.Add(CurrentObject);
		
		SettingPricesServer.PutPricesInTablePart(Data);
	
	EndIf;
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

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

	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInArticleAttribute = New Structure("Products", "SKU");
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		New Structure("FillInFeatureAttribute, FillInArticleAttribute",
			FillInFeatureAttribute,
			FillInArticleAttribute));

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	
	UnlockFormDataForEdit();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If SelectedPricesWereChanged And PriceTree.GetItems().Count() > 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Thành phần giá đã thay đổi. Cần chuyển sang đặt bảng giá.';
										|ru = 'Состав цен изменился. Необходимо перейти к установке цен.';
										|en = 'Price content has changed. Go to pricing.'; fa = 'Price content has changed. Go to pricing.';
										|it = 'La composizione dei prezzi è stata modificata. È necessario passare all''impostazione dei prezzi.';
										|pl = 'Zmieniła się struktura cen. Konieczne jest przystąpienie do ustalania cen.';
										|tr = 'Fiyatların içeriği değişti. Fiyat yapılandırmasına gitmeniz gerekmektedir.'"));
		Cancel = True;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
		
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DoNotCheckMappedSupplierProducts = Settings.Get("DoNotCheckMappedSupplierProducts");
	
	If DoNotCheckMappedSupplierProducts Then
		Items.FormDoNotCheckMappedSupplierProducts.Check = True;
	EndIf;
	
	DisplayPriceTable = Settings.Get("DisplayPriceTable");
	
	If ValueIsFilled(DisplayPriceTable) Then
		If DisplayPriceTable = "Tree" Then
			Items.PriceTree.Representation = TableRepresentation.Tree;
		ElsIf DisplayPriceTable = "HierarchicalList" Then
			Items.PriceTree.Representation = TableRepresentation.HierarchicalList;
		ElsIf DisplayPriceTable = "List" Then
			Items.PriceTree.Representation = TableRepresentation.List;
		EndIf;
	EndIf;
	
	FillInCharacteristicPricesByProductsAutomatically = Settings.Get("FillInCharacteristicPricesByProductsAutomatically");
	SetFillInAutomaticallyFeaturePricesByProductRange(FillInCharacteristicPricesByProductsAutomatically);
	
	AutomaticallyAddCharacteristics = Settings.Get("AutomaticallyAddCharacteristics");
	SetToAutomaticallyAddCharacteristics(AutomaticallyAddCharacteristics);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		FillInProductsFromSelectionFromTemporaryStorageServer(ValueSelected.GoodsAddressInStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_VendorPriceTypes"
		And Parameter.Partner = Object.Partner Then
		
		ReReadVendorPriceTypesOnServer();

	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		ThisForm.Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	EndIf;
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
		

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
		
	If Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
		
	UpdateOldProductPricesOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	WhenChangingPartnerServer();
	
	GoToEditingPriceTypesList(Undefined);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceTree

&AtClient
Procedure PriceTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Vendor';
																									|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure PriceTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	CurrentRow = Items.PriceTree.CurrentData;
	
	If Not Copy Then
		If Not CurrentRow = Undefined And ValueIsFilled(CurrentRow.Characteristic) Then
			AddACharacteristic(Undefined);
		Else
			AddProducts(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreeAfterDeleteRow(Item)
	PriceTreeAfterDeletionOnServer();
EndProcedure

&AtClient
Procedure PriceTreeProductsOnChange(Item)

	CurrentRow = Items.PriceTree.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(Object, DoNotCheckMappedSupplierProducts));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure PriceTreeCharacteristicOnChange(Item)
	
	CurrentRow = Items.PriceTree.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(Object, DoNotCheckMappedSupplierProducts));

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PriceTreePartnerProductsOnChange(Item)
	
	CurrentRow = Items.PriceTree.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(Object, DoNotCheckMappedSupplierProducts));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PriceTreeOnActivateCell(Item)
	
	If Item.CurrentData = Undefined
		Or Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "PriceTree" + "Characteristic" Then
		If Item.CurrentData.GetParent() = Undefined Then
			Item.CurrentItem.ReadOnly = True;
		Else
			Item.CurrentItem.ReadOnly = False;
		EndIf;
	ElsIf Item.CurrentItem.Name = "PriceTree" + "Products" Then
		If Item.CurrentData.GetParent() <> Undefined Then
			Item.CurrentItem.ReadOnly = True;
		Else
			Item.CurrentItem.ReadOnly = False;
		EndIf;
	ElsIf Item.CurrentItem.Name = "PriceTree" + "PartnerProducts" Then
		ThisIsTopLevel = Item.CurrentData.GetParent() = Undefined;
		ItemVariantsAreUsed = Item.CurrentData.ItemVariantsAreUsed;
		
		If ThisIsTopLevel And ItemVariantsAreUsed Then
			Item.CurrentItem.ReadOnly = True;
		Else
			Item.CurrentItem.ReadOnly = False;
			
			If Item.CurrentItem.Name = "PriceTree" + "PartnerProducts" Then
				CurrentData = Items.PriceTree.CurrentData;

				PartnersProductsClient.FillInPartnerProductSelectionList(
					Object.Partner, CurrentData, Items.PriceTreePartnerProducts.ChoiceList);

				PartnersProductsClient.SetFormElementSelectionParameters(
					Items.PriceTreePartnerProducts.ChoiceParameters, Object.Partner, CurrentData);
			EndIf;
			
		EndIf;
	EndIf;
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

&AtClient
Procedure PriceTreeOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PriceTree.CurrentData;
	OldPartnerProducts = CurrentData.PartnerProducts;
	OldProducts = CurrentData.Products;
	OldCharacteristic = CurrentData.Characteristic;
	Changed_Price = False;
	
EndProcedure

&AtClient
Procedure PriceTreeBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	// The new line was added programmatically.
	// If you cancel editing, you need to delete it.
	If RowAdded And CancelEdit Then
		PriceTree.GetItems().Delete(CurrentData);
		RowAdded = False;
		Return;
	EndIf;
	
	If CurrentData.Products <> OldProducts Or Not ValueIsFilled(CurrentData.Products) Then
		
		ProductItems_ = PriceTree.GetItems();
		For Each ProductItem In ProductItems_ Do
			If ProductItem.Products = CurrentData.Products
				Or (Not ValueIsFilled(ProductItem.Products)
				And ProductItem.PartnerProducts = CurrentData.PartnerProducts) Then
				If CurrentData.GetID() <> ProductItem.GetID() Then
					
					If Not CancelEdit Then
						Cancel = True;
						ClearMessages();
						CommonClient.MessageToUser(
							NStr("vi = 'Đã nhập mặt hàng này.';
								|ru = 'Такая номенклатура уже введена.';
								|en = 'These products already exist.'; fa = 'These products already exist.';
								|it = 'Questo articolo è già stato inserito.';
								|pl = 'Ten wykaz towarów jest już wprowadzony.';
								|tr = 'Böyle bir öğe zaten girildi.'"),
							Object.Ref,
							"PriceTree");
					Else
						CurrentData.Products = OldProducts;
						CurrentData.Characteristic = OldCharacteristic;
					EndIf;
					Return;
				EndIf;
			EndIf;
		EndDo;
		
		ClearPriceValues = ValueIsFilled(OldProducts);
		PriceTreeProductsOnChangeServer(Items.PriceTree.CurrentData.GetID(), ClearPriceValues);
		
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Products)
		And Not ValueIsFilled(CurrentData.PartnerProducts) Then
		If Not CancelEdit Then
			Cancel = True;
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa chọn mặt hàng.';
					|ru = 'Номенклатура не выбрана.';
					|en = 'Items are not selected.'; fa = 'Items are not selected.';
					|it = 'Articolo non selezionato.';
					|pl = 'Nie wybrano wykazu towarów.';
					|tr = 'Öğe seçilmedi.'"),
				Object.Ref,
				"PriceTree");
		Else
			CurrentData.PartnerProducts = OldPartnerProducts;
			CurrentData.Products = OldProducts;
			CurrentData.Characteristic = OldCharacteristic;
		EndIf;
	EndIf;
	
	If CurrentData.Characteristic <> OldCharacteristic Then
		
		FeatureElements = PriceTree.FindByID(Items.PriceTree.CurrentRow);
		
		If FeatureElements.GetParent() = Undefined Then
			FeatureElements = FeatureElements.GetItems();
		Else
			FeatureElements = FeatureElements.GetParent().GetItems();
		EndIf;
		For Each ElementCharacteristic In FeatureElements Do
			If ElementCharacteristic.Characteristic = CurrentData.Characteristic Then
				If CurrentData.GetID() <> ElementCharacteristic.GetID() Then
					If Not CancelEdit Then
						Cancel = True;
						ClearMessages();
						CommonClient.MessageToUser(
							NStr("vi = 'Đã nhập mặt hàng này.';
								|ru = 'Такая номенклатура уже введена.';
								|en = 'These products already exist.'; fa = 'These products already exist.';
								|it = 'Questo articolo è già stato inserito.';
								|pl = 'Ten wykaz towarów jest już wprowadzony.';
								|tr = 'Böyle bir öğe zaten girildi.'"),
							Object.Ref,
							"PriceTree");
					Else
						CurrentData.PartnerProducts = OldPartnerProducts;
						CurrentData.Products = OldProducts;
						CurrentData.Characteristic = OldCharacteristic;
					EndIf;
					Return;
				EndIf;
			EndIf;
		EndDo;
		
		PriceTreeCharacteristicOnChangeServer(Items.PriceTree.CurrentData.GetID());
		
	EndIf;
	
	RowAdded = False;

EndProcedure

&AtClient
Procedure Attachable_PriceTreePriceWhenChanged(Item)
	
	Changed_Price = True;
	PriceTreePriceWhenCustomerChanges(Item);
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreePackagingWhenChanging(Item)

	PriceTreePackagingWhenChangingClient(Item);

EndProcedure

&AtClient
Procedure Attachable_PriceTreeOrderPackagingWhenChanged(Item)
	
	PriceTreeOrderPackagingWhenChangedClient(Item);
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreeMinimumBatchWhenModified(Item)
	
	PriceTreeMinimumBatchWhenModifiedClient(Item);
	
EndProcedure

&AtClient
Procedure PriceTreePartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CurrentRow = Items.PriceTree.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification,, False);

EndProcedure

&AtClient
Procedure PriceTreePartnerProductsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	StandardProcessing = False;
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(Object.Partner)
		Or Not ValueIsFilled(Text)
		Or StrLen(Text) < 3 Then
		Return;
	EndIf;
	
	Package = Undefined;
	If CurrentData.Property("Package") Then
		Package = CurrentData.Package;
	ElsIf CurrentData.Property("UnitOfMeasure") Then
		Package = CurrentData.UnitOfMeasure;
	EndIf;
	
	ChoiceData = New ValueList();
	
	ArrayOfCounterpartyItems = PartnerItemAutoSelectionGetArrayByText(
		Text,
		Object.Partner,
		CurrentData.Products,
		CurrentData.Characteristic,
		Package,
		CurrentData.GetParent() = Undefined);
	
	ChoiceData.LoadValues(ArrayOfCounterpartyItems);

EndProcedure

&AtClient
Procedure PriceTreePartnerProductsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedPrices

&AtClient
Procedure SelectedPricesOnChange(Item)
	
	SelectedPricesWereChanged = True;
	
EndProcedure

&AtClient
Procedure SelectedPricesSelected_5OnChange(Item)
	
	CurrentData = Items.SelectedPrices.CurrentData;
	If CurrentData.ProhibitedPriceType Then
		CurrentData.Selected_5 = False;
		AttachIdleHandler("InformAboutImpossibilityOfSelection", 0.2, True);
		Return;
	EndIf;
	
	SelectedPricesWereChanged = True;
	
EndProcedure

&AtClient
Procedure SelectedPricesRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedPricesRefClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedPricesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		ShowValue(Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedPricesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	Filter = New Structure;
	Filter.Insert("Owner", Object.Partner);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", Filter);
	
	OpenForm("Catalog.VendorPriceTypes.Form.ItemForm", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure AddProducts(Command)
	
	CurrentItem = Items.PriceTreeProducts;
	
	NewRow = PriceTree.GetItems().Add();
	Items.PriceTree.CurrentRow = NewRow.GetID();
	
	SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(NewRow);
	Items.PriceTree.ChangeRow();
	
	RowAdded = True;
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentData - Undefined, FormDataTreeItem - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentData", Undefined);
	
	Return Result;
	
EndFunction

&AtClient
Procedure AddACharacteristic(Command)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Products) Then
		ShowMessageBox(Undefined, NStr("vi = 'Để chọn đặc tính, Bạn cần chọn trước mặt hàng.';
										|ru = 'Для того, чтобы выбрать характеристику Вам необходимо предварительно выбрать номенклатуру.';
										|en = 'To choose variant, select product first.'; fa = 'To choose variant, select product first.';
										|it = 'Per selezionare la caratteristica si deve selezionare prima l''articolo.';
										|pl = 'Aby wybrać charakterystykę, należy najpierw wybrać nomenklaturę.';
										|tr = 'Varyant seçmek için önce bir öğe seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	TechnicalCharacteristics = Undefined;
	
	SetPriceCalculationOptions = New Array;
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"));
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("CurrentItem"  , CurrentData.Characteristic);
	ChoiceFormParameters.Insert("SettingTheOwner", TechnicalCharacteristics);
	ChoiceFormParameters.Insert("Products"    , CurrentData.Products);
	ChoiceFormParameters.Insert("SetPriceCalculationOptions", SetPriceCalculationOptions);
	
	CurrentItem = Items.PriceTreeCharacteristic;
	
	Characteristic = Undefined;

	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentData = CurrentData;
	
	OpenForm("Catalog.ItemsCharacteristics.ChoiceForm", ChoiceFormParameters,,,,, 
		New CallbackDescription("AddACharacteristicCompletion", ThisObject, AdditionalParameters), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
// 	Result - CatalogRef.ItemsCharacteristics - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure AddACharacteristicCompletion(Result, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	
	Characteristic = Result;
	If Characteristic = Undefined Then
		Return;
	EndIf;
	
	FeatureElements = PriceTree.FindByID(Items.PriceTree.CurrentRow);
	If FeatureElements.GetParent() = Undefined Then
		FeatureElements = FeatureElements.GetItems();
	Else
		FeatureElements = FeatureElements.GetParent().GetItems();
	EndIf;
	For Each ElementCharacteristic In FeatureElements Do
		If ElementCharacteristic.Characteristic = Characteristic Then
			Items.PriceTree.CurrentRow = ElementCharacteristic.GetID();
			ShowMessageBox(Undefined, NStr("vi = 'Đã nhập đặc tính này.';
											|ru = 'Такая характеристика уже введена.';
											|en = 'This variant already exists.'; fa = 'This variant already exists.';
											|it = 'Questa caratteristica è già stata inserita.';
											|pl = 'Ta charakterystyka jest już wprowadzona.';
											|tr = 'Böyle bir varyant zaten girildi.'"));
			Return;
		EndIf;
	EndDo;
	
	CurrentParent = CurrentData.GetParent();
	If CurrentParent = Undefined Then
		CurrentParent = CurrentData;
	EndIf;
	NewRow = CurrentParent.GetItems().Add();
	Items.PriceTree.CurrentRow = NewRow.GetID();
	
	FillPropertyValues(NewRow, CurrentParent, "Products, ItemVariantsAreUsed, UnitOfMeasure");
	NewRow.Characteristic = Characteristic;
	
	SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(NewRow);

	CurrentRow = Items.PriceTree.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(Object, DoNotCheckMappedSupplierProducts));

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	PriceTreeCharacteristicOnChangeServer(Items.PriceTree.CurrentRow);

EndProcedure

&AtClient
Procedure DoNotCheckMappedSupplierProducts(Command)
	
	DoNotCheckMappedSupplierProducts = Not DoNotCheckMappedSupplierProducts;
	Items.FormDoNotCheckMappedSupplierProducts.Check = DoNotCheckMappedSupplierProducts;
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.VendorPriceList.DocumentForm.Command.SelectGoods",,True);
	
	FormParameters = New Structure;

	FormParameters.Insert("Document",   Object.Ref);
	FormParameters.Insert("Partner",    Object.Partner);
	Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	
	FormParameters.Insert("Currency",                                  Currency);
	FormParameters.Insert("Date",                                    Object.Date);
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     True);
	FormParameters.Insert("HideManualDiscounts", True);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("SelectThePartnerSNomenclature", True);
	FormParameters.Insert("Partner", Object.Partner);
	
	AddressInTempStorage = Undefined;

	
	OpenForm("DataProcessor.GoodsSelectionByPicking.Form.Form", FormParameters, ThisForm,,,, New CallbackDescription("AddGoodsByPickingCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export

	AddressInTempStorage = Result;
	If ValueIsFilled(AddressInTempStorage) Then
		FillInProductsFromSelectionFromTemporaryStorageServer(AddressInTempStorage);
	EndIf;
	FillInSupplierProducts();

EndProcedure

&AtClient
Procedure SalesDynamicsReport(Command)
	
	PurchasesClient.OpenSupplierPriceDynamicsReport(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure GoToPricing(Command)
	
	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PriceSettingGroup;
	WhenSwitchingToSettingPrices();
	
EndProcedure

&AtClient
Procedure GoToEditingPriceTypesList(Command)
	
	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PriceTypesGroup;
	
EndProcedure

&AtClient
Procedure SwitchToAutomaticallyAddCharacteristics(Command)
	
	SetToAutomaticallyAddCharacteristicsOnClient(Not AutomaticallyAddCharacteristics);
	
EndProcedure

&AtClient
Procedure SwitchToAutomaticallyFillInFeaturePricesByItem(Command)
	
	SetPopulatingAutomaticallyFeaturePricesByProductOnClient(Not FillInCharacteristicPricesByProductsAutomatically);
	
EndProcedure

&AtClient
Procedure SelectAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			SelectedPricesWereChanged = True;
			TableRow.Selected_5 = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure ClearAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			SelectedPricesWereChanged = True;
			TableRow.Selected_5 = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetUpDisplayedInformation(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ShowPriceChange",   ShowPriceChange);
	FormParameters.Insert("ShowMarkupPercent",  ShowMarkupPercent);
	FormParameters.Insert("ShowEffectivePrices", ShowEffectivePrices);
	FormParameters.Insert("ValidPriceDate",        Undefined);
	FormParameters.Insert("ShowDate",            False);
	
	OpenForm(
		"DataProcessor.PriceList.Form.SettingsFormOfDisplayedInformation",
		FormParameters,
		ThisObject,,,, New CallbackDescription("SetUpDisplayedInformationCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetUpDisplayedInformationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ShowPriceChange   = Result.ShowPriceChange;
	ShowMarkupPercent  = Result.ShowMarkupPercent;
	ShowEffectivePrices = Result.ShowEffectivePrices;
	
	SetVisibilityOfEditColumns(ThisObject, True);
	
EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "PriceTree" + "Characteristic",
																			 "PriceTree.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FormCode = "VendorPriceList";
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	UsePartnersProducts      = GetFunctionalOption("UsePartnersProducts");
	
	SettingPricesServer.InitializeSelectedPrices(ThisForm);
	FillInDocument();
	
	SetVisibilityOfEditColumns(ThisObject, True);

EndProcedure

#Region Other

&AtServer
Procedure PriceTreeAfterDeletionOnServer()
	AddressOfDataCacheStorage = "";
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

// Sets the AutoFill feature for feature prices by item
//
// Parameters:
// NewValue - Boolean
//
&AtClient
Procedure SetPopulatingAutomaticallyFeaturePricesByProductOnClient(NewValue)
	
	FillInCharacteristicPricesByProductsAutomatically = NewValue;
	Items.PriceTreeSwitchToAutomaticallyFillInFeaturePricesByItem.Check = NewValue;
	
EndProcedure

// Sets the AutoFill feature for feature prices by item
//
// Parameters:
// NewValue - Boolean
//
&AtClient
Procedure SetToAutomaticallyAddCharacteristicsOnClient(NewValue)
	
	AutomaticallyAddCharacteristics = NewValue;
	Items.PriceTreeSwitchToAutomaticallyAddCharacteristics.Check = NewValue;
	
EndProcedure

// Sets the AutoFill feature for feature prices by item
//
// Parameters:
// NewValue - Boolean
//
&AtServer
Procedure SetFillInAutomaticallyFeaturePricesByProductRange(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	FillInCharacteristicPricesByProductsAutomatically = NewValue;
	Items.PriceTreeSwitchToAutomaticallyFillInFeaturePricesByItem.Check = NewValue;
	
EndProcedure

// Sets the AutoFill feature for feature prices by item
//
// Parameters:
// NewValue - Boolean
//
&AtServer
Procedure SetToAutomaticallyAddCharacteristics(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	AutomaticallyAddCharacteristics = NewValue;
	Items.PriceTreeSwitchToAutomaticallyAddCharacteristics.Check = NewValue;
	
EndProcedure

&AtServer
Procedure FillInProductsFromSelectionFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage);
	
	SettingPricesServer.AddGoodsByPicking(ThisForm, "", TableOfGoods);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInSupplierProducts()

	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Object.Goods, Object.Partner);

EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	SettingPricesServer.InitializeSelectedPrices(ThisForm);
	SettingPricesServer.BuildPriceTree(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenSwitchingToSettingPricesServer()
	
	SettingPricesServer.ReformatPriceTable(ThisForm);
	
EndProcedure

&AtClient
Procedure WhenSwitchingToSettingPrices()
	
	If SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisForm).Count() = 0 Then
		
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Để chuyển đến đặt bảng giá, cần chọn một hoặc nhiều dạng giá';
										|ru = 'Для перехода к установке цен, необходимо выбрать один или несколько видов цен';
										|en = 'To go to the pricing, select one price type or more'; fa = 'To go to the pricing, select one price type or more';
										|it = 'Per procedere all''impostazione dei prezzi, è necessario selezionare uno o più tipi di prezzi';
										|pl = 'Aby przejść do ustalania cen, należy wybrać jeden lub więcej rodzajów cen.';
										|tr = 'Fiyat yapılandırmaya geçiş için bir veya daha fazla fiyat türü seçmeniz gerekmektedir'"),,"SelectedPrices");
		Items.GroupPages.CurrentPage = Items.PriceTypesGroup;
		
	Else
		
		If SelectedPricesWereChanged Then
			
			WhenSwitchingToSettingPricesServer();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOldProductPricesOnServer()
	
	DataCache = Undefined;
	ValueTable = SettingPricesServer.GoodsTable(ThisForm, DataCache);
	SettingPricesServer.LoadOldPricesOfSupplierProducts(ThisForm, ValueTable, DataCache);
	
EndProcedure

// Parameters:
//	Item - FormField - Form element
&AtClient
Procedure PriceTreePriceWhenCustomerChanges(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ColumnNamePackaging = StrReplace(Item.Name, "PriceTree"+  "PriceKind", "Package" + "PriceKind");
	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	
	If StrFind(CurColumnName, "ChangePercentage" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "ChangePercentage" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = Round(
			CurrentData["OldPrice" + CurColumnName] * ((CurrentData["ChangePercentage"+CurColumnName] / 100) + 1),
			15,
			2);
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "PercentageChangeTypeOfPrice", "PriceKind"), "PriceTree" + "PriceKind", "Package" + "PriceKind");
	EndIf;
	If StrFind(CurColumnName, "AmountOfChange" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "AmountOfChange" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = CurrentData["OldPrice" + CurColumnName] + CurrentData["AmountOfChange" + CurColumnName];
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), "PriceTree" + "PriceKind", "Package" + "PriceKind");
	EndIf;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	CurrentData["ChangedManually"+CurColumnName] = True;
	
	If CurrentData["OldPrice"+CurColumnName] <> 0 Then
		CurrentData["ChangePercentage"+CurColumnName] = Round(
			100 * (CurrentData[CurColumnName] - CurrentData["OldPrice"+CurColumnName]) / CurrentData["OldPrice" + CurColumnName],
			5,
			2);
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];
	Else
		CurrentData["ChangePercentage"+CurColumnName] = 0;
	EndIf;
	
	If FillInCharacteristicPricesByProductsAutomatically Then
		
		ArrayOfProductPackagingStructures = New Array;
		ComplianceOfFactorsOfPackagesOfProductRange = Undefined;
		If UseItemPackages Then
			
			CurPackingValue = CurrentData[ColumnNamePackaging];
			If ValueIsFilled(CurPackingValue) Then
				Structure = SettingPricesClientServer.InitializeProductPackagingDescription();
				Structure.Products = CurrentData.Products;
				Structure.Package = CurPackingValue;
				ArrayOfProductPackagingStructures.Add(Structure);
			EndIf;
			
			FeatureElements = CurrentRow.GetItems();
			For Each ElementCharacteristic In FeatureElements Do
				
				ColumnValuePackaging = ElementCharacteristic[ColumnNamePackaging];
				If ValueIsFilled(ColumnValuePackaging) 
					And SettingPricesClientServer.FindProductPackingStructureInArray(ArrayOfProductPackagingStructures, 
																							ElementCharacteristic.Products, 
																							ColumnValuePackaging) = Undefined Then
					
					Structure = SettingPricesClientServer.InitializeProductPackagingDescription();
					Structure.Products = ElementCharacteristic.Products;
					Structure.Package = ColumnValuePackaging;
					ArrayOfProductPackagingStructures.Add(Structure);
					
				EndIf;
				
			EndDo;
		
			If ArrayOfProductPackagingStructures.Count() > 0 Then
				ComplianceOfFactorsOfPackagesOfProductRange = CoefficientsOfProductPackages(ArrayOfProductPackagingStructures);
			EndIf;
			
		EndIf;
		
		// Let's determine the packing coefficient of the current price
		SourcePricePackingRatio = 1;
		If UseItemPackages Then
			If ValueIsFilled(CurPackingValue) And ComplianceOfFactorsOfPackagesOfProductRange <> Undefined Then				
				SearchResult = SettingPricesClientServer.GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																									CurrentData.Products, 
																									CurPackingValue);
				If SearchResult <> Undefined Then
					SourcePricePackingRatio = SearchResult;																										
				EndIf;																												
			EndIf;
		EndIf;
		
		CurrentValue = CurrentData[CurColumnName];
		FeatureElements = CurrentRow.GetItems();
		For Each ElementCharacteristic In FeatureElements Do
			
			If UseItemPackages Then
				
				ColumnValuePackaging = ElementCharacteristic[ColumnNamePackaging];
				If CurPackingValue = ColumnValuePackaging And
					
					ElementCharacteristic[CurColumnName] <> CurrentValue Then
					ElementCharacteristic[CurColumnName] = CurrentValue;
					ElementCharacteristic["ChangedManually"+CurColumnName] = True;
					
					If ElementCharacteristic["OldPrice"+CurColumnName] <> 0 Then
						ElementCharacteristic["ChangePercentage"+CurColumnName] = Round(100*(ElementCharacteristic[CurColumnName] - ElementCharacteristic["OldPrice"+CurColumnName])/ElementCharacteristic["OldPrice"+CurColumnName],5,2);
					Else
						ElementCharacteristic["ChangePercentage"+CurColumnName] = 0;
					EndIf;
					
				Else
					
					// Let's determine the packing coefficient of the influencing price
					DestinationPricePackingRatio = 1;
					
					If ValueIsFilled(ColumnValuePackaging) And ComplianceOfFactorsOfPackagesOfProductRange <> Undefined Then
						SearchResult = SettingPricesClientServer.GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																												CurrentData.Products, 
																												ColumnValuePackaging);
						If SearchResult <> Undefined Then
							DestinationPricePackingRatio = SearchResult;
						EndIf;
					EndIf;
					
					If SourcePricePackingRatio = DestinationPricePackingRatio Then
						NewPrice = CurrentValue;
					Else
						NewPrice = CurrentValue / SourcePricePackingRatio * DestinationPricePackingRatio;
					EndIf;
					
					If ElementCharacteristic[CurColumnName] <> NewPrice Then
						
						ElementCharacteristic[CurColumnName] = NewPrice;
						ElementCharacteristic["ChangedManually"+CurColumnName] = True;
						
						If ElementCharacteristic["OldPrice"+CurColumnName] <> 0 Then
							ElementCharacteristic["ChangePercentage"+CurColumnName] = Round(100*(ElementCharacteristic[CurColumnName] - ElementCharacteristic["OldPrice"+CurColumnName])/ElementCharacteristic["OldPrice"+CurColumnName],5,2);
						Else
							ElementCharacteristic["ChangePercentage"+CurColumnName] = 0;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			Else
				
				NewPrice = CurrentValue;
				
				If ElementCharacteristic[CurColumnName] <> NewPrice Then
					
					ElementCharacteristic[CurColumnName] = NewPrice;
					ElementCharacteristic["ChangedManually"+CurColumnName] = True;
					
					If ElementCharacteristic["OldPrice"+CurColumnName] <> 0 Then
						ElementCharacteristic["ChangePercentage"+CurColumnName] = Round(100*(ElementCharacteristic[CurColumnName] - ElementCharacteristic["OldPrice"+CurColumnName])/ElementCharacteristic["OldPrice"+CurColumnName],5,2);
					Else
						ElementCharacteristic["ChangePercentage"+CurColumnName] = 0;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormField - Form element
&AtClient
Procedure PriceTreePackagingWhenChangingClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	PriceTreePackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

// Parameters:
//	Item - FormField - Form element
&AtClient
Procedure PriceTreeOrderPackagingWhenChangedClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	PriceTreeOrderPackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

// Parameters:
//	Item - FormField - Form element
&AtClient
Procedure PriceTreeMinimumBatchWhenModifiedClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	PriceTreeMinimumBatchWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

&AtServer
Procedure PriceTreePackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisForm, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeOrderPackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreeOrderPackagingWhenChanged(ThisObject, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeMinimumBatchWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreeMinimumBatchWhenModified(ThisObject, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeCharacteristicOnChangeServer(RowID, CalculatePrices = True)
	
	SettingPricesServer.PriceTreeCharacteristicOnChange(ThisForm, RowID);
	
EndProcedure

&AtServer
Function PriceTreeProductsOnChangeServer(RowID, ClearPriceValues)
	
	DataForCalculatingCalculatedPricesOnClient = Undefined;
	
	CurrentRow = PriceTree.FindByID(RowID);
	
	If ClearPriceValues Then
		TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisForm);
		For Each PriceKind In TypesOfPrices Do
			
			ColumnName         = PriceKind.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			
			If ValueIsFilled(CurrentRow[ColumnName]) Then
				CurrentRow[ColumnName] = 0;
			EndIf;
			
			If UseItemPackages And ValueIsFilled(CurrentRow[ColumnNamePackaging]) Then
				CurrentRow[ColumnNamePackaging] = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			EndIf;
			
		EndDo;
	EndIf;
	
	AddressOfDataCacheStorage = "";
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
		|	CatalogProducts.SKU AS SKU,
		|	CASE
		|		WHEN CatalogProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed
		|FROM
		|	Catalog.Products AS CatalogProducts
		|WHERE
		|	CatalogProducts.Ref = &Products";
		
		If UseItemPackages Then
			
			Query.Text = Query.Text + "
			|;
			|SELECT
			|	ItemsPrices.Characteristic    AS Characteristic,
			|	ItemsPrices.VendorPriceKind AS PriceKind,
			|	ItemsPrices.Package          AS Package
			|FROM
			|	InformationRegister.ItemsPricesOfVendor.SliceLast(&DocumentDate,
			|													Products = &Products
			|													AND VendorPriceKind IN (&TypesOfPrices)) AS ItemsPrices
			|";
			
			Query.Text = Query.Text + "
			|;
			|SELECT
			|	PurchaseConditions.Characteristic            AS Characteristic,
			|	PurchaseConditions.OrderPackage            AS OrderPackage,
			|	PurchaseConditions.VendorPriceKind         AS PriceKind,
			|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot
			|FROM
			|	InformationRegister.PurchaseConditions.SliceLast(&DocumentDate,
			|													Products = &Products
			|													AND VendorPriceKind IN (&TypesOfPrices)) AS PurchaseConditions
			|";
			
			Query.SetParameter("TypesOfPrices",       SettingPricesClientServer.SelectedTypesOfPrices(ThisForm));
			Query.SetParameter("DocumentDate", Object.Date - 1);
			
		EndIf;
		
		Query.SetParameter("Products", CurrentRow.Products);
		ResultsArray = Query.ExecuteBatch();
		ResultProductRange = ResultsArray[0]; // QueryResult
		SelectionOfProducts = ResultProductRange.Select();
		
		If SelectionOfProducts.Next() Then
			FillPropertyValues(CurrentRow, SelectionOfProducts);
		EndIf;
		
		If UseItemPackages Then
				PackingResult = ResultsArray[1]; // QueryResult
				PackageSelection = PackingResult.Select();
			While PackageSelection.Next() Do
				CurrentRow["Package" + SettingPricesServer.ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
			EndDo;
			
			ResultOfProcurementCondition = ResultsArray[2]; // QueryResult
			SampleTermsOfPurchase = ResultOfProcurementCondition.Select();
			While SampleTermsOfPurchase.Next() Do
				CurrentRow["OrderPackage" + SettingPricesServer.ColumnNameByPriceType(SampleTermsOfPurchase.PriceKind, DataCache)] = SampleTermsOfPurchase.OrderPackage;
				CurrentRow["MinimumDeliveryLot" + SettingPricesServer.ColumnNameByPriceType(SampleTermsOfPurchase.PriceKind, DataCache)] = SampleTermsOfPurchase.MinimumDeliveryLot;
			EndDo;
			
		EndIf;
		
		If AutomaticallyAddCharacteristics And UseItemVariants Then
			SettingPricesServer.FillInProductCharacteristics(ThisForm, CurrentRow, FillInCharacteristicPricesByProductsAutomatically);
		EndIf;
		
	Else
		
		CurrentRow.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		
	EndIf;
	
	// Loading old prices and percentage changes
	ValueTable = SettingPricesServer.CreateProductsTable(True);
	For Each PriceTypeLine In SelectedPrices Do
		
		If PriceTypeLine.Selected_5 Or PriceTypeLine.Influences Then
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			
			NewRow = ValueTable.Add();
			FillPropertyValues(NewRow, CurrentRow);
			NewRow.PriceKind                = PriceTypeLine.Ref;
			NewRow.Price                   = CurrentRow[ColumnName];
			If UseItemPackages Then
				NewRow.Package = CurrentRow[ColumnNamePackaging];
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SettingPricesServer.LoadOldPricesOfProducts(ThisForm, ValueTable, DataCache);
	
	Return DataForCalculatingCalculatedPricesOnClient;
	
EndFunction

&AtServerNoContext
Function CoefficientsOfProductPackages(ArrayOfProductPackagingStructures)
	
	Return SettingPricesServer.ComplianceOfCoefficientsOfCollectionOfPackagesOfProductRange(ArrayOfProductPackagingStructures);
		
EndFunction

&AtClient
Procedure InformAboutImpossibilityOfSelection()
	ClearMessages();
	CurrentData = Items.SelectedPrices.CurrentData;
	CommonClient.MessageToUser(NStr("vi = 'Không có quyền đặt bảng giá theo dạng giá này';
									|ru = 'Нет прав на установку цен по данному виду цены';
									|en = 'No rights for pricing by this price type'; fa = 'No rights for pricing by this price type';
									|it = 'Nessun diritto di impostare i prezzi per questo tipo di prezzo';
									|pl = 'Brak uprawnień do ustalania cen dla tego rodzaju cen.';
									|tr = 'Bu fiyat türüne göre fiyat belirleme yetkisi yoktur'"), Object.Ref, "SelectedPrices[" + SelectedPrices.IndexOf(CurrentData) + "].Ref");
EndProcedure

&AtServer
Procedure ReReadVendorPriceTypesOnServer()
	
	SettingPricesServer.ReReadSelectedPrices(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInDocument()
	
	AddressOfDataCacheStorage = "";
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	If SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisForm).Count() > 0 Then
		
		SettingPricesServer.BuildPriceTree(ThisForm);
		SettingPricesServer.LoadTablePart(ThisForm, DataCache);
		
		If Object.Goods.Count() > 0 Then
			Items.GroupPages.CurrentPage = Items.PriceSettingGroup;
		Else
			Items.GroupPages.CurrentPage = Items.PriceTypesGroup;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfEditColumns(Form, UseTheEditMode)
	
	For Each CurItem In Form.Items.PriceTree.ChildItems Do
		If StrFind(CurItem.Name, "GroupPrices" + "PriceKind") Then
			For Each NestedItem In CurItem.ChildItems Do
				If StrFind(NestedItem.Name, "TechnicalGroup") Then
					For Each NestedElementByTechnicalGroup In NestedItem.ChildItems Do
						If StrFind(NestedElementByTechnicalGroup.Name, "OldPrice") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowEffectivePrices;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "ChangePercentage") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowMarkupPercent;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "AmountOfChange") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowPriceChange;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ShowEffectivePrices",  ShowEffectivePrices);
	StructureOfData.Insert("ShowPriceChange",    ShowPriceChange);
	StructureOfData.Insert("ShowMarkupPercent",   ShowMarkupPercent);
	
	Common.CommonSettingsStorageSave("Document.VendorPriceList", "Document.VendorPriceList",StructureOfData);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
	
	PriceTreePartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServerNoContext
Function PartnerItemAutoSelectionGetArrayByText(Text,
	Partner,
	Products,
	Characteristic,
	Package,
	ThisIsTopLevelLine)
	
	Query = New Query;
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Text", Text + "%");
	Query.Text =
	"SELECT
	|	ProductsTable.Ref AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS ProductsTable
	|WHERE
	|	NOT ProductsTable.DeletionMark
	|	AND NOT ProductsTable.Invalid
	|	AND ProductsTable.ItemOwner = &Partner
	|	AND ProductsTable.Description LIKE &Text
	|	AND &FilterConditions";
	
	FilterConditions = New Array;
	If ValueIsFilled(Products) Then
		
		FilterConditions.Add("ProductsTable.Products = &Products"); // @query-part
		Query.SetParameter("Products", Products);
		
	EndIf;
	
	If ValueIsFilled(Characteristic) Then
		
		FilterConditions.Add("ProductsTable.Characteristic = &Characteristic"); // @query-part
		Query.SetParameter("Characteristic", Characteristic);
		
	EndIf;
	
	If ValueIsFilled(Package) Then
		
		FilterConditions.Add("ProductsTable.Package = &Package"); // @query-part
		Query.SetParameter("Package", Package);
		
	EndIf;
	
	If ThisIsTopLevelLine Then
		FilterConditions.Add("NOT ProductsTable.UseCharacteristics"); // @query-part
	EndIf;
	
	If FilterConditions.Count() Then
		
		Query.Text = StrReplace(Query.Text, "&FilterConditions",
			StrConcat(FilterConditions, Chars.LF + "And "));
		
	EndIf;
	
	ArrayOfCounterpartyItems = Query.Execute().Unload().UnloadColumn("Ref");
	Return ArrayOfCounterpartyItems; 
	
EndFunction

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
