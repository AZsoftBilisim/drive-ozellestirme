#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var Changed_Price; // It is used in the mechanisms of event handlers of the tabular part of the Goods

&AtClient
Var QuestionIsDisplayed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	Date = EndOfDay(CurrentSessionDate());
	FormCode = "Processing_SupplierSPriceList_Form";
	
	SettingPricesServer.LoadDefaultSelectionSettings(ThisObject);
	
	FlagOfOpeningAForm = True;
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	UsePartnersProducts      = GetFunctionalOption("UsePartnersProducts");
	UsePriceManagementSystem25          = False;
	
	CurrentDate = CurrentSessionDate();
	
	If ValueIsFilled(Parameters.PartnerProducts) Then
		Object.Partner = Common.ObjectAttributeValue(Parameters.PartnerProducts, "Owner");
		BlockTheChangeOfFilterBySupplier = True;
		PartnerProducts = Parameters.PartnerProducts;
	EndIf;
	If ValueIsFilled(Parameters.Partner) Then
		Object.Partner = Parameters.Partner;
		BlockTheChangeOfFilterBySupplier = True;
	EndIf;
	
	Items.Partner.ReadOnly = BlockTheChangeOfFilterBySupplier;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	If Not LoadSavedSettings() Then
	
		If SelectedPrices.Count() = 1 Then
			For Each CurRow In SelectedPrices Do
				CurRow.Selected_5 = True;
			EndDo;
		Else
			For Each TableRow In SelectedPrices Do
				If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
					TableRow.Selected_5 = True;
				EndIf;
			EndDo;
		EndIf;
		
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		
	EndIf;
	
	SetFillInAutomaticallyFeaturePricesByProductRange(True);
	LockColumnProducts(False);
	
	If ValueIsFilled(Parameters.PartnerProducts) Then
		
		UseTheSavedSettings = False;
		
		SettingsComposerFilter.Settings.Filter.Items.Clear();
		
		ItemList = New ValueList;
		ItemList.Add(Parameters.PartnerProducts);
		
		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"PartnerProducts",
			DataCompositionComparisonType.InList,
			ItemList,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
			
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		ApplySettings();
		
	ElsIf ValueIsFilled(Parameters.Products) Then
		
		FilterProducts = Parameters.Products;
		UseTheSavedSettings = False;
		
		SettingsComposerFilter.Settings.Filter.Items.Clear();
		
		ItemList = New ValueList;
		ItemList.Add(Parameters.Products);
		
		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Products",
			DataCompositionComparisonType.InList,
			ItemList,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
			
		FindProductPartner(Parameters.Products);
		
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		If ValueIsFilled(Object.Partner) Then
			ApplySettings();
		EndIf;
		
	Else
		UseTheSavedSettings = True;
	EndIf;
	
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Not AllowClose And QuestionIsDisplayed <> True And Not Exit Then
		
		QuestionIsDisplayed = True;
		
		CallbackDescription = New CallbackDescription("ProcessingIssueResultBeforeClosing", ThisObject);
		Buttons = New ValueList;
		Buttons.Add("WriteAndClose", NStr("vi = 'Áp dụng';
											|ru = 'Применить';
											|en = 'Apply'; fa = 'اعمال';
											|it = 'Applica';
											|pl = 'Apply';
											|tr = 'Uygula'"));
		Buttons.Add("CloseWithoutSaving", NStr("vi = 'Hủy thay đổi đơn giá';
												|ru = 'Отменить изменения цен';
												|en = 'Undo changes in prices'; fa = 'Undo changes in prices';
												|it = 'Annullare le variazioni di prezzi';
												|pl = 'Anulować zmiany cen';
												|tr = 'Fiyat değişikliklerini iptal et'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		QueryText = NStr("vi = 'Áp dụng đơn giá thay đổi?';
						|ru = 'Применить измененные цены?';
						|en = 'Apply changed prices?'; fa = 'Apply changed prices?';
						|it = 'Applicare i prezzi modificati?';
						|pl = 'Zastosować zmienione ceny?';
						|tr = 'Değiştirilen fiyatları uygula?'");
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
		StandardProcessing = False;
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If UseTheSavedSettings And Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.VendorPriceLists.Form.FormSettings" Then
		PriceChangeSessionIsActive = False;
		ClearSavedDocumentsAndApplySettings(ValueSelected);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If PriceTree.GetItems().Count() = 0 Then
		Return;
	EndIf;
	
	Date = EndOfDay(Date);
	
	If Items.CommandBarPages.CurrentPage = Items.CommandBarPages.ChildItems.ViewPage Then
		ApplySettings();
		Return;
	EndIf;
	
	UpdateOldProductPricesOnServer();
	
EndProcedure

&AtClient
Procedure HyperlinkFilterIsSetClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenPriceListSettingsForm(False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceTree

&AtClient
Procedure PriceTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PriceTree" + "Products" Then
		StandardProcessing = False;
		ShowValue(Undefined, Items.PriceTree.CurrentData.Products);
	ElsIf Field.Name = "PriceTree" + "PartnerProducts" Then
		StandardProcessing = False;
		ShowValue(Undefined, Items.PriceTree.CurrentData.PartnerProducts);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreeOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PriceTree.CurrentData;
	Changed_Price = False;
	
EndProcedure

&AtServer
Procedure PriceTreePackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeOrderPackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreeOrderPackagingWhenChanged(ThisObject, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeMinimumBatchWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreeMinimumBatchWhenModified(ThisObject, Id, CurColumnName);
EndProcedure

&AtClient
Procedure PriceTreeOnActivateCell(Item)
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		ValidPriceDate,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

// Procedure-handler of the event" when Changing "of the" wood Packaging " field.
// Parameters:
// 	Item - FormField - 
&AtClient
Procedure PriceTreePackagingWhenChangingClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	If FillInCharacteristicPricesByProductsAutomatically Then
		
		CurrentRow = PriceTree.FindByID(CurrentData.GetID());
		
		If CurrentRow.GetParent() = Undefined Then
			
			FeatureElements = CurrentRow.GetItems();
			CurrentValue   = CurrentData[CurColumnName];
			
			For Each ElementCharacteristic In FeatureElements Do
				If ElementCharacteristic[CurColumnName] <> CurrentValue Then
					ElementCharacteristic[CurColumnName] = CurrentValue;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	PriceTreePackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		ValidPriceDate,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

// Procedure-handler for the event" when Changing "the" wood Price " field.
// Parameters:
// 	Item - FormField - 
&AtClient
Function PriceTreePriceWhenCustomerChanges(Item)
	
	DataForCalculatingCalculatedPricesOnClient = Undefined;
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return DataForCalculatingCalculatedPricesOnClient;
	EndIf;
	
	ColumnNamePackaging = StrReplace(Item.Name, "PriceTree" + "PriceKind", "Package" + "PriceKind");
	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	
	If StrFind(CurColumnName, "ChangePercentage" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "ChangePercentage" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = Round(
			CurrentData["OldPrice" + CurColumnName] * ((CurrentData["ChangePercentage"+CurColumnName] / 100) + 1),
			15,
			2);
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), "PriceTree" + "PriceKind", "Package" + "PriceKind");
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
	
	CurrentData["ChangedManually"       + CurColumnName] = True;
	CurrentData["ChangedAutomatically" + CurColumnName] = False;
	
	If CurrentData["OldPrice"+CurColumnName] <> 0 Then
		CurrentData["ChangePercentage"+CurColumnName] = Round(
			100 * (CurrentData[CurColumnName] - CurrentData["OldPrice"+CurColumnName]) / CurrentData["OldPrice" + CurColumnName],
			5,
			2);
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];
	Else
		CurrentData["ChangePercentage"+CurColumnName] = 0;
		CurrentData["AmountOfChange"+CurColumnName] = 0;
	EndIf;
	
	Return DataForCalculatingCalculatedPricesOnClient;
	
EndFunction

#EndRegion

#Region FormTableElementEventHandlersAreBoundDynamically

&AtClient
Procedure Attachable_PriceTreePriceWhenChanged(Item)
	
	Changed_Price = True;
	PriceTreePriceWhenCustomerChanges(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreePackagingWhenChanging(Item)

	PriceTreePackagingWhenChangingClient(Item);

EndProcedure

&AtClient
Procedure Attachable_PriceTreeOrderPackagingWhenChanged(Item)
	
	Changed_Price = True;
	PriceTreeOrderPackagingWhenChangedClient(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreeMinimumBatchWhenModified(Item)
	
	Changed_Price = True;
	PriceTreeMinimumBatchWhenModifiedClient(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;
	
EndProcedure

// Procedure - the event handler "primeneniy the fields of Derivativeoperations".
//
&AtClient
Procedure PriceTreeOrderPackagingWhenChangedClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	If FillInCharacteristicPricesByProductsAutomatically Then
		
		CurrentRow = PriceTree.FindByID(CurrentData.GetID());
		
		If CurrentRow.GetParent() = Undefined Then
			
			FeatureElements = CurrentRow.GetItems();
			CurrentValue   = CurrentData[CurColumnName];
			
			For Each ElementCharacteristic In FeatureElements Do
				If ElementCharacteristic[CurColumnName] <> CurrentValue Then
					ElementCharacteristic[CurColumnName] = CurrentValue;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	PriceTreeOrderPackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		ValidPriceDate,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

// Procedure - the event handler for the "Primenenie" fields "Derivationally".
//
&AtClient
Procedure PriceTreeMinimumBatchWhenModifiedClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	If FillInCharacteristicPricesByProductsAutomatically Then
		
		CurrentRow = PriceTree.FindByID(CurrentData.GetID());
		
		If CurrentRow.GetParent() = Undefined Then
			
			FeatureElements = CurrentRow.GetItems();
			CurrentValue   = CurrentData[CurColumnName];
			
			For Each ElementCharacteristic In FeatureElements Do
				If ElementCharacteristic[CurColumnName] <> CurrentValue Then
					ElementCharacteristic[CurColumnName] = CurrentValue;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	PriceTreeMinimumBatchWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		ValidPriceDate,
		CurrentDate,
		UseItemVariants,
		True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SalesDynamicsReport(Command)
	
	ItemList  = New ValueList;
	ListOfCharacteristics = New ValueList;
	For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
		TSRow = PriceTree.FindByID(IDOfPriceTreeRow);
		ItemList.Add(TSRow.Products);
		If TSRow.ItemVariantsAreUsed Then
			If ListOfCharacteristics.FindByValue(TSRow.Characteristic) = Undefined Then
				ListOfCharacteristics.Add(TSRow.Characteristic);
			EndIf;
		Else
			If ListOfCharacteristics.FindByValue(
					PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef")) = Undefined Then
				ListOfCharacteristics.Add(PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
			EndIf;
		EndIf;
	EndDo;
	
	ListOfPriceTypes = New ValueList;
	For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
		ListOfPriceTypes.Add(PriceTypeLine.Ref, PriceTypeLine.Description);
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("Products", ItemList);
	Filter.Insert("Characteristic", ListOfCharacteristics);
	Filter.Insert("VendorPriceKind", ListOfPriceTypes);
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", Filter);
	
	FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
	FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.PriceChangeTrendsOfVendorPartNumbers.Form",
	        FormParameters, ThisObject, New UUID);
	
EndProcedure

&AtClient
Procedure PriceChangeHistoryContext(Command)
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Key",           CurrentData.Products);
	FormOpenParameters.Insert("Characteristic", CurrentData.Characteristic);
	
	OpenForm("Catalog.Products.Form.PricesHistoryOfItemsAndService", FormOpenParameters);
	
EndProcedure

&AtClient
Procedure ToCompleteThePriceChange(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		RecordPriceChanges();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Generate(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		OpenPriceListSettingsForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsWithSimilarProperties(Command)
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	GoodsWithSimilarProperties = New Structure;
	GoodsWithSimilarProperties.Insert("Products", CurrentData.Products);
	GoodsWithSimilarProperties.Insert("Characteristic", CurrentData.Characteristic);
	OpenPriceListSettingsForm(False, GoodsWithSimilarProperties);
	
EndProcedure

&AtClient
Procedure CancelPriceChange(Command)
	
	CancelPriceChangesOnServer();
	
EndProcedure

&AtClient
Procedure PriceChangeHistory(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner", Object.Partner);
	
	OpenForm("Document.VendorPriceList.ListForm", FormParameters);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Partner", Object.Partner);
	FormOpenParameters.Insert("TypesOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	FormOpenParameters.Insert("BlockTheChangeOfFilterBySupplier", BlockTheChangeOfFilterBySupplier);
	
	OpenForm("DataProcessor.ImportVendorPricesFromFile.Form.Form", FormOpenParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure


&AtClient
Procedure SetUpDisplayedInformation(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ShowPriceChange",   ShowPriceChange);
	FormParameters.Insert("ShowMarkupPercent",  ShowMarkupPercent);
	FormParameters.Insert("ShowEffectivePrices", ShowEffectivePrices);
	FormParameters.Insert("ValidPriceDate",        ValidPriceDate);
	FormParameters.Insert("ShowDate",            True);
	
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
	ValidPriceDate        = Result.ValidPriceDate;
	
	SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
	SaveFormSettingsOnServer();
	
EndProcedure

#EndRegion

#Region Private

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

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			 "PriceTreeCharacteristic",
																			 "PriceTree.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	If ValueIsFilled(PartnerProducts) Then
		Return;
	EndIf;
	
	ComposerSettings = SettingsComposerFilter.GetSettings();
	
	ArrayOfSelectedPrices = SettingPricesClientServer.SelectedTypesOfPrices(ThisObject);
	
	StructureOfData = SettingPricesClientServer.NewFormSettingsStructure();
	StructureOfData.ComposerSettings 			= ComposerSettings;
	StructureOfData.SelectedPrices 					= ArrayOfSelectedPrices;
	StructureOfData.FilterParametersTable 		= FilterParametersTable.Unload();
	StructureOfData.SettingKind 					= SettingKind;
	StructureOfData.NavigationOption 				= NavigationOption;
	StructureOfData.ProductKind 				= ProductKind;
	StructureOfData.FilterSettingsAreSet 		= FilterSettingsAreSet;
	StructureOfData.ShowEffectivePrices 		= ShowEffectivePrices;
	StructureOfData.ShowPriceChange 		= ShowPriceChange;
	StructureOfData.ShowMarkupPercent 		= ShowMarkupPercent;
	StructureOfData.ValidPriceDate 				= ValidPriceDate;	
	
	Common.CommonSettingsStorageSave("DataProcessor.VendorPriceLists", 
				String(Object.Partner.UUID()), StructureOfData);
	
EndProcedure

&AtServer
Procedure CancelPriceChangesOnServer(ClosingForm = False)
	
	SetPrivilegedMode(True);
	SettingPricesServer.ClearSavedDocuments(SavedDocuments, UUID, True);
	
	If Not ClosingForm Then
		
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		ApplySettings();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ApplySettings(AddressInTempStorage = Undefined)
	
	If AddressInTempStorage <> Undefined Then
		
		StructureOfData = GetFromTempStorage(AddressInTempStorage); // See SettingPricesClientServer.NewFormSettingsStructure
		
		SettingsComposerFilter.LoadSettings(StructureOfData.ComposerSettings);
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		Object.Partner = StructureOfData.Partner;
		
		SettingPricesServer.InitializeSelectedPrices(ThisObject);
		SettingPricesServer.BuildPriceTree(ThisObject);
		
		For Each TSRow In SelectedPrices Do
			TSRow.Selected_5 = StructureOfData.SelectedPrices.Find(TSRow.Ref) <> Undefined;
		EndDo;
		
		Date = StructureOfData.Date;
		
		SettingKind = StructureOfData.SettingKind;
		FilterParametersTable.Load(StructureOfData.FilterParametersTable);
		
		NavigationOption = StructureOfData.NavigationOption;
		ProductKind = StructureOfData.ProductKind;
		
		FilterSettingsAreSet = SettingsComposerFilter.Settings.Filter.Items.Count() > 0;
		
	EndIf;
	
	Object.Goods.Clear();
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields", New Array);
	SettingsStructure.Insert("DataParameters", New Structure);
	SettingsStructure.Insert("SettingsComposer", Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate", Undefined);
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates", False);
	SettingsStructure.Insert("PricesAsOfDate", EndOfDay(Date));
	SettingsStructure.Insert("DateOfReceiptOfBalances", Date);
	SettingsStructure.Insert("Vendor", Object.Partner);
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UsePartnersProducts = GetFunctionalOption("UsePartnersProducts");
	
	SettingsStructure.RequiredFields.Add("Products");
	If UsePartnersProducts Then
		SettingsStructure.RequiredFields.Add("PartnerProducts");
	EndIf;
	If UseItemVariants Then
		SettingsStructure.RequiredFields.Add("Characteristic");
	EndIf;
	
	SettingsStructure.SettingsComposer = SettingsComposerFilter;
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplatePartnerSProducts";
	
	SettingPricesServer.BuildPriceTree(ThisObject);
	SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
	
	ProductsTable = SettingPricesServer.CreateProductTable(ThisObject);
	
	// Loading the generated list of products.
	ResultStructure1 = DataProcessors.GoodsSelectionByPicking.PrepareDataStructure(SettingsStructure);
	For Each TSRow In ResultStructure1.TableOfGoods Do
		
		NewRow = ProductsTable.Add();
		NewRow.Products           = TSRow.Products;
		If UsePartnersProducts Then
			NewRow.PartnerProducts = TSRow.PartnerProducts;
		EndIf;
		If UseItemVariants Then
			NewRow.Characteristic = TSRow.Characteristic;
		EndIf;
	EndDo;
	
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	ProductsTable = SettingPricesServer.AddSupplierProducts(ThisObject, ProductsTable, DataCache);
	
	ValueTable = SettingPricesServer.GoodsTable(ThisObject, DataCache,,ProductsTable);
	SettingPricesServer.LoadOldPricesOfSupplierProductsPriceList(ThisObject, ValueTable, DataCache);
	
EndProcedure

&AtServer
Function RecordPriceChangesOnServer(Comment = "", PriceApplicationOption = 0)
	
	DetailsOfNewDocuments = New Structure;
	DetailsOfNewDocuments.Insert("EmployeeResponsible", Users.CurrentUser());
	DetailsOfNewDocuments.Insert("Partner", Object.Partner);
	DetailsOfNewDocuments.Insert("Comment", Comment);
	DetailsOfNewDocuments.Insert("Date", Date);
	
	Data = New Structure;
	Data.Insert("Form",                    ThisObject);
	Data.Insert("Documents",                New Array);
	Data.Insert("SaveBasic",         False);
	Data.Insert("DetailsOfNewDocuments", DetailsOfNewDocuments);
	Data.Insert("OnlyChangedItems",         True);
	
	For Each TSRow In SavedDocuments Do
		DocumentObject = TSRow.Ref.GetObject();
		Data.Documents.Add(DocumentObject);
	EndDo;
	
	SettingPricesServer.PutPricesInTablePart(Data);
	
	ArrayDocuments = New Array;
	
	BeginTransaction();
	Try
		For Each DocumentObject In Data.Documents Do
			If DocumentObject.Goods.Count() > 0 Then
				
				DocumentObject.Date = Date;
				
				DocumentObject.Write(?(PriceApplicationOption = 0, DocumentWriteMode.Write,
				DocumentWriteMode.Posting), DocumentPostingMode.Regular);
				
				StructureOfDocuments = New Structure;
				StructureOfDocuments.Insert("VendorPriceList", DocumentObject.Ref);
				ArrayDocuments.Add(StructureOfDocuments);
				
			Else
				If ValueIsFilled(DocumentObject.Ref) Then
					DocumentObject.Read();
					DocumentObject.Delete();
				EndIf;
			EndIf;
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		CommonClientServer.MessageToUser(ErrorInfo().Description);
		Return Undefined;
		
	EndTry;
	
	SettingPricesServer.ClearSavedDocuments(SavedDocuments, UUID);
	
	For Each TSRow In ArrayDocuments Do
		NewRow = SavedDocuments.Add();
		NewRow.Ref = TSRow.VendorPriceList;
		LockDataForEdit(TSRow.VendorPriceList,,UUID);
	EndDo;
	
	SetVisibilityOfEditColumns(ThisObject, False);
	
	Modified = False;
	
	Return ArrayDocuments;
	
EndFunction

&AtClient
Procedure RecordPriceChanges()
	
	PriceChangeSessionIsActive = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("Date", Date);
	
	OpenForm(
		"DataProcessor.VendorPriceLists.Form.PriceApplicationForm",
		FormParameters,
		ThisObject,,,, New CallbackDescription("RecordPriceChangesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RecordPriceChangesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Data = RecordPriceChangesOnServer(Result.Comment, Result.PriceApplicationOption);
	If Data <> Undefined Then
		
		For Each TSRow In Data Do
			NotificationText1 = NStr("vi = 'Đã tạo chứng từ mới';
									|ru = 'Создан новый документ';
									|en = 'New document is created'; fa = 'سند جدید ایجاد شد';
									|it = 'Il nuovo documento è stato creato';
									|pl = 'Utwórz nowy dokument';
									|tr = 'Yeni belge oluşturuldu'");
			NotificationParameters = Undefined;
			Notify("Write_VendorPriceList", NotificationParameters, TSRow.VendorPriceList);
			ShowUserNotification(NotificationText1,
				GetURL(TSRow.VendorPriceList),
				String(TSRow.VendorPriceList),
				PictureLib.Information32);
		EndDo;
		
	EndIf;

EndProcedure

&AtClient
Procedure ProcessingIssueResultBeforeClosing(Result, Var_Parameters) Export
	
	QuestionIsDisplayed = False;
	
	If Result = "CloseWithoutSaving" Then
		
		CancelPriceChangesOnServer(True);
		AllowClose = True;
		If IsOpen() Then
			Close(Undefined);
		EndIf;
		
	EndIf;
	
	If Result = "WriteAndClose" Then
		
		RecordPriceChanges();
		
		AllowClose = True;
		If IsOpen() Then
			Close(Undefined);
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
	
	If UseTheEditMode Then
		Form.Items.CommandBarPages.CurrentPage = Form.Items.CommandBarPages.ChildItems.EditingPage;
		Form.Items.ToCompleteThePriceChange.DefaultButton = True;
	Else
		Form.Items.CommandBarPages.CurrentPage = Form.Items.CommandBarPages.ChildItems.ViewPage;
		Form.Items.Generate.DefaultButton = True;
		Form.Modified = False;
	EndIf;

	Form.UseTheEditMode = UseTheEditMode;
	
EndProcedure

&AtServer
Function AddressOfPriceListSettingsInTemporaryStorage()
	
	ComposerSettings = SettingsComposerFilter.GetSettings();
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ComposerSettings", ComposerSettings);
	StructureOfData.Insert("SelectedPrices", SelectedPrices.Unload());
	StructureOfData.Insert("Date", Date);
	StructureOfData.Insert("FilterParametersTable", FilterParametersTable.Unload());
	StructureOfData.Insert("SettingKind", SettingKind);
	StructureOfData.Insert("NavigationOption", NavigationOption);
	StructureOfData.Insert("Partner", Object.Partner);
	StructureOfData.Insert("ProductKind", ProductKind);
	
	Return PutToTempStorage(StructureOfData, UUID);
	
EndFunction

&AtClient
Procedure OpenPriceListSettingsForm(SelectionOnly = False, GoodsWithSimilarProperties = Undefined)
	
	AddressInTempStorage = AddressOfPriceListSettingsInTemporaryStorage();
	
	FormParameters = New Structure;
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("PriceListSettings", AddressInTempStorage);
	FormParameters.Insert("Date", Date);
	FormParameters.Insert("SelectionOnly", SelectionOnly);
	FormParameters.Insert("GoodsWithSimilarProperties", GoodsWithSimilarProperties);
	FormParameters.Insert("BlockTheChangeOfFilterBySupplier", BlockTheChangeOfFilterBySupplier);
	
	OpenForm("DataProcessor.VendorPriceLists.Form.FormSettings", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateOldProductPricesOnServer()
	SettingPricesServer.UpdateOldProductPrices(ThisObject);
EndProcedure

#Region Other

// Sets the AutoFill feature for feature prices by item
//
// Parameters:
// 	Boolean-New Value
//
&AtServer
Procedure SetFillInAutomaticallyFeaturePricesByProductRange(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	FillInCharacteristicPricesByProductsAutomatically = NewValue;
	
EndProcedure

// Sets the flag for fixing the "Nomenclature" and "Characteristic" columns on the left
//
// Parameters:
// 	Boolean-New Value
//
&AtServer
Procedure LockColumnProducts(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	LockColumnProducts = NewValue;
	
	Items.PriceTreeProducts.FixingInTable   = ?(LockColumnProducts,FixingInTable.Left,FixingInTable.None);
	Items.PriceTreeCharacteristic.FixingInTable = ?(LockColumnProducts,FixingInTable.Left,FixingInTable.None);
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	If Not ValueIsFilled(FilterProducts) Then
		If Not LoadSavedSettings() Then
			SettingPricesServer.BuildPriceTree(ThisObject);
			SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
		EndIf;
	Else
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
	EndIf;
	
EndProcedure

&AtServer
Function LoadSavedSettings()
	
	Result = False;
	
	SavedSettings = Common.CommonSettingsStorageLoad("DataProcessor.VendorPriceLists", String(Object.Partner.UUID()));
	If SavedSettings <> Undefined Then
		
		If Not ValueIsFilled(PartnerProducts) Then
			
			SettingsComposerFilter.LoadSettings(SavedSettings.ComposerSettings);
			SettingPricesServer.ConfigureSelectionHeader(ThisObject);
			
			FilterParametersTable.Load(SavedSettings.FilterParametersTable);
			SettingKind               = SavedSettings.SettingKind;
			NavigationOption           = SavedSettings.NavigationOption;
			ProductKind            = SavedSettings.ProductKind;
			FilterSettingsAreSet = SavedSettings.FilterSettingsAreSet;
			
			If SavedSettings.Property("ShowMarkupPercent") Then
				ShowMarkupPercent = SavedSettings.ShowMarkupPercent;
			EndIf;
			
			If SavedSettings.Property("ShowPriceChange") Then
				ShowPriceChange = SavedSettings.ShowPriceChange;
			EndIf;
			
			If SavedSettings.Property("ShowEffectivePrices") Then
				ShowEffectivePrices  = SavedSettings.ShowEffectivePrices;
			EndIf;
			
			If SavedSettings.Property("ValidPriceDate") Then
				ValidPriceDate = SavedSettings.ValidPriceDate;
			EndIf;
			
		EndIf;
		
		For Each TSRow In SelectedPrices Do
			TSRow.Selected_5 = SavedSettings.SelectedPrices.Find(TSRow.Ref) <> Undefined
			                   And Not TSRow.ProhibitedPriceType;
		EndDo;

		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		
		Result = True;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FindProductPartner(Products)
	
	Query = New Query(
	"SELECT DISTINCT
	|	ProductCrossReferences.Owner AS Partner
	|INTO Partners
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.Products = &Products
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ItemsPrices.Partner
	|FROM
	|	InformationRegister.ItemsPricesOfVendor AS ItemsPrices
	|WHERE
	|	ItemsPrices.Products = &Products
	|;
	|
	|////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Partner
	|FROM
	|	Partners AS T
	|");
	
	Query.SetParameter("Products", Products);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Count() >= 1 Then
		
		Items.Partner.ListChoiceMode = True;
		
		While Selection.Next() Do
			Items.Partner.ChoiceList.Add(Selection.Partner);
			Object.Partner = Selection.Partner;
		EndDo;
		
		If ValueIsFilled(Object.Partner) Then
			SettingPricesServer.InitializeSelectedPrices(ThisObject);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearSavedDocumentsAndApplySettings(Val ValueSelected)
	
	SettingPricesServer.ClearSavedDocuments(SavedDocuments, UUID);
	
	ApplySettings(ValueSelected);
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
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
