#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var OldProducts; // It is used in the mechanisms of event handlers of the tabular part of the Goods

&AtClient
Var OldCharacteristic; // It is used in the mechanisms of event handlers of the tabular part of the Goods

&AtClient
Var Changed_Price; // It is used in the mechanisms of event handlers of the tabular part of the Goods

&AtClient
Var RowAdded;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	FlagOfOpeningAForm = True;
	FormCode = "PriceSetup";
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ValueIsFilled(Object.Ref) Then
		RoomWithinADay = Object.Date - BegOfDay(Object.Date) + 1;
	ElsIf Not ValueIsFilled(Object.Date) Then
		RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(CurrentSessionDate(), Object.Ref);
		Object.Date = SettingPricesClientServer.CalculateDocumentDate(CurrentSessionDate(), RoomWithinADay);
	Else
		RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(Object.Date, Object.Ref);
		Object.Date = SettingPricesClientServer.CalculateDocumentDate(Object.Date, RoomWithinADay);
	EndIf;
	CurrentDate = CurrentSessionDate();
	
	Items.RoomWithinADay.Visible = RoomWithinADay <> 1;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Object.Date);
	If ValueIsFilled(Object.Ref) Then
		If Object.Goods.Count() = 0 And Object.Goods2_5.Count() <> 0 Then
			UsePriceManagementSystem25 = True;
		ElsIf Object.Goods.Count() <> 0 And Object.Goods2_5.Count() = 0 Then 
			UsePriceManagementSystem25 = False;
		EndIf;
	EndIf;
	
	UsePriceGroups              = GetFunctionalOption("UsePriceGroups");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = True;
	UseSeveralPriceTypes          = GetFunctionalOption("UseSeveralPriceTypes");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	
	GroupingOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	FillInDocument();
	
	If Not ValueIsFilled(Object.Ref) Then
		SetAvailabilityOfItemsByStatusServer();
	EndIf;
	
	SavedSettings = Common.CommonSettingsStorageLoad("Document.PriceSetup", "Document.PriceSetup");
	If SavedSettings <> Undefined Then
		SavedSettings.Property("ShowMarkupPercent", 				ShowMarkupPercent);
		SavedSettings.Property("ShowPriceChange", 				ShowPriceChange);
		SavedSettings.Property("ShowEffectivePrices", 				ShowEffectivePrices);
		SavedSettings.Property("ShowCurrency", 						ShowCurrency);
		SavedSettings.Property("ShowUnitsOfMeasurement", 			ShowUnitsOfMeasurement);
		SavedSettings.Property("ShowFormulas", 						ShowFormulas);
		SavedSettings.Property("UseOneColumnForThePriceKey", 	UseOneColumnForThePriceKey);
		SavedSettings.Property("FixTheItemColumn", 		FixTheItemColumn);
		SavedSettings.Property("ShowInfluencingPrices", 				ShowInfluencingPrices);
		SavedSettings.Property("CalculateAutomatically", 				CalculateAutomatically);
		SavedSettings.Property("ShowVATRate", 					ShowVATRate);
	EndIf;

	ShowCurrency = ShowCurrency And GetFunctionalOption("UseMultipleCurrencies");
	
	FixTheItemColumn(FixTheItemColumn);
	ConfigurePriceKeyColumns();
	
	SetVisibilityOfEditColumns();
	
	SetState();
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		Items.Basis.Visible = False;
	EndIf;
	
	If Not ValueIsFilled(Object.MarketingActivity) Then
		Items.MarketingActivity.Visible = False;
	EndIf;
	
	If SelectedPrices.Count() = 1 Then
		Items.TypesOfPricesCommandNext.Visible = False;
		Items.TypesOfPricesTeamBack.Visible = False;
		Items.PriceTypesGroup.Visible       = False;
	EndIf;
	
	AdditionalColumnName = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	Items.PriceTreeChangePrices.Visible = AccessRight("Update",Metadata.Documents.PriceSetup);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	CheckPricingVersion(Object.Ref, Object.Goods.Count(), Object.Goods2_5.Count());

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
		
	If Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	If EventName = "ImportFromExcel"
		And Parameter.OwnerForm = UUID Then
		ImportResult1 = LoadFromExcelOnServer(Parameter);
		If Not ImportResult1.Completed2 Then
			ShowMessageBox(,ImportResult1.ErrorDescription);
		EndIf;
	EndIf;
	
	If EventName = "ChangingTypeOfPrices"
		And Source = ThisObject Then
		UpdateSettingsForPriceTypesFragment(DialogReturnCode.Yes);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	If FlagOfOpeningAForm = True Then
		If ValueIsFilled(Object.Ref) Then
			RoomWithinADay = Object.Date - BegOfDay(Object.Date) + 1;
		Else
			RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(Object.Date, Object.Ref);
			Object.Date = SettingPricesClientServer.CalculateDocumentDate(Object.Date, RoomWithinADay);
		EndIf;
		
		AddressOfDataCacheStorage = "";
		SettingPricesServer.InitializeSelectedPrices(ThisObject);
		
		FillInDocument();
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	SetVisibilityOfEditColumns();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If SelectedPricesWereChanged And PriceTree.GetItems().Count() > 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Thành phần giá đã thay đổi. Cần chuyển sang đặt bảng giá.';
										|ru = 'Состав цен изменился. Необходимо перейти к установке цен.';
										|en = 'Price content has changed. Go to pricing.'; fa = 'Price content has changed. Go to pricing.';
										|it = 'La composizione dei prezzi è stata modificata. È necessario passare all''impostazione dei prezzi.';
										|pl = 'Zmieniła się struktura cen. Konieczne jest przystąpienie do ustalania cen.';
										|tr = 'Fiyatların içeriği değişti. Fiyat yapılandırmasına gitmeniz gerekmektedir.'"));
		Cancel = True;
	EndIf;
	
	If	UsePriceManagementSystem25
			And WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		SettingPricesClientServer.CheckFillingInVATRateOfPriceTree(ThisObject, Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Write
		Or WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		SettingPricesServer.CheckCorrectnessOfDocument(ThisObject, Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	If Modified Or Not ValueIsFilled(Object.Ref) Then
		
		SettingPricesServer.PutPriceTypesInTablePart(ThisObject, CurrentObject.TypesOfPrices, True);
		
		Data = New Structure;
		Data.Insert("Form", ThisObject);
		Data.Insert("Documents", New Array);
		Data.Insert("SaveBasic", False);
		Data.Documents.Add(CurrentObject);
		SettingPricesServer.PutPricesInTablePart(Data);
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	SetState();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

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
			SettingPricesServer.CheckCorrectnessOfDocument(ThisObject, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If Settings.Get("DisplayPriceTable") <> Undefined Then
		DisplayPriceTable = String(Items.PriceTree.Representation);
		Settings["DisplayPriceTable"] = DisplayPriceTable;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
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
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(Object.Date, Object.Ref);
	Object.Date = SettingPricesClientServer.CalculateDocumentDate(Object.Date, RoomWithinADay);
	
	Items.RoomWithinADay.Visible = RoomWithinADay <> 1;
	
	UpdateOldProductPricesOnServer();
	
	If PriceTree.GetItems().Count() = 0 Then
		Return;
	EndIf;
	
	NeedToRecalculate = False;
	
	// To find out if recalculation is necessary, let's check that the selected prices
	// have influencing prices with a currency other than the currency of the selected price.
	
	For Each CurRow In SelectedPrices Do
		
		If CurRow.Selected_5 And
			CurRow.PricingMethod <> PredefinedValue("Enum.PriceSettingMethods.Manually") Then
			
			For Each InfluencingPrice In CurRow.InfluencingPrices Do
				
				FoundRow = Undefined;
				For Each SelectedPrice In SelectedPrices Do
					If SelectedPrice.Ref = InfluencingPrice.Value Then
						FoundRow = SelectedPrice;
					EndIf;
				EndDo;
					
				If FoundRow = Undefined Then
					Continue;
				EndIf;
				
				If CurRow.Currency <> FoundRow.Currency Then
					NeedToRecalculate = True;
					Break;
				EndIf;
				
			EndDo;
			
			If NeedToRecalculate Then
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not NeedToRecalculate Then
		Return;
	EndIf;
	
	UserAnswer = Undefined;

	
	ShowQueryBox(New CallbackDescription("DateOnChangeCompletion", ThisObject), 
		NStr("vi = 'Trong chứng từ đã chọn dạng giá có tiền tệ khác với dạng giá ảnh hưởng. Tính lại đơn giá?';
			|ru = 'В документе выбраны виды цены с валютой, отличной от влияющих видов цен. Пересчитать цены?';
			|en = 'Price types with the currency different from the influencing price types are selected in the document. Recalculate the prices?'; fa = 'Price types with the currency different from the influencing price types are selected in the document. Recalculate the prices?';
			|it = 'Nel documento sono stati selezionati i tipi di prezzi con valuta diversa dai tipi di prezzi influenzanti. Ricalcolare i prezzi?';
			|pl = 'W dokumencie wybrano rodzaje cen z walutą, inną niż wpływających rodzajów cen. Przeliczyć ponownie?';
			|tr = 'Belgede, etkileyen fiyat türleri dışında bir para birimine sahip fiyat türleri seçildi. Fiyatlar hesaplansın mı?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ReformatPriceTable(True);

EndProcedure

&AtClient
Procedure RoomWithinADayOnChange(Item)
	
	Object.Date = SettingPricesClientServer.CalculateDocumentDate(Object.Date, RoomWithinADay);
	
	UpdateOldProductPricesOnServer();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PriceSettingGroup Then
		
		WhenSwitchingToSettingPrices();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedPrices

&AtClient
Procedure SelectedPricesSelected_5OnChange(Item)
	
	CurrentData = Items.SelectedPrices.CurrentData;
	If CurrentData.ProhibitedPriceType Then
		CurrentData.Selected_5 = False;
		AttachIdleHandler("InformAboutImpossibilityOfSelection", 0.2, True);
		Return;
	EndIf;
	
	SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(ThisObject);
	SelectedPricesWereChanged = True;
	
	CurrentData.Edit	= CurrentData.Selected_5;
	
EndProcedure

&AtClient
Procedure SelectedPricesRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedPricesEditOnChange(Item)
	
	CurrentData = Items.SelectedPrices.CurrentData;

	If CurrentData.ProhibitedPriceType Then
		CurrentData.Edit = False;
		AttachIdleHandler("InformAboutImpossibilityOfSelection", 0.2, True);
		Return;
	EndIf;
	
	SelectedPricesWereChanged = True;
	
	If CurrentData.Edit And Not CurrentData.Selected_5 = CurrentData.Edit Then
		
		CurrentData.Selected_5	= CurrentData.Edit;
		
		SelectedPricesSelected_5OnChange(Item);
		
	EndIf;
	
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
		
		If Field = Items.SelectedPricesInfluencingPrices Then
			If CurrentData.InfluencingPrices.Count() > 0 Then
				ShowValue(Undefined, CurrentData.InfluencingPrices);
			EndIf;
		ElsIf Field = Items.SelectedPricesDependentPrices Then
			If CurrentData.DependentPrices.Count() > 0 Then
				ShowValue(Undefined, CurrentData.DependentPrices);
			EndIf;
		ElsIf Field = Items.SelectedPricesParameters Then
			
			EditSettings(Commands["EditSettings"]);
			
		Else
			
			FormOpenParameters = New Structure("Key", CurrentData.Ref);
			OpenForm("Catalog.TypesOfPrices.Form.ItemForm", FormOpenParameters, ThisObject)
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceTree

&AtClient
Procedure PriceTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	If Not Copy Then
		AddProducts(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreeBeforeDeleteRow(Item, Cancel)
	If Item.CurrentData = Undefined Then
		Cancel = True;
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure PriceTreeAfterDeleteRow(Item)
	PriceTreeAfterDeletionOnServer();
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
	EndIf;
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants);
	
EndProcedure

&AtClient
Procedure PriceTreeOnEditEnd(Item, NewRow, CancelEdit)
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants);
	
EndProcedure

&AtClient
Procedure PriceTreePackagingWhenChangingClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "Package" + "PriceKind", "NoEditingAllowed" + "PriceKind");

	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	If CurrentRow[NameOfEditBanColumn] Then
		Return;
	EndIf;
	
	If CurrentRow.GetParent() = Undefined Then
		
		FeatureElements = CurrentRow.GetItems();
		CurrentValue   = CurrentData[CurColumnName];
		
		For Each ElementCharacteristic In FeatureElements Do
			If ElementCharacteristic[NameOfEditBanColumn] Then
				Continue;
			EndIf;
			If ElementCharacteristic[CurColumnName] <> CurrentValue Then
				ElementCharacteristic[CurColumnName] = CurrentValue;
			EndIf;
		EndDo;
		
	EndIf;
	
	PriceTreePackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants);
	
EndProcedure

&AtServer
Procedure PriceTreePackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName);
EndProcedure

&AtClient
Procedure PriceTreeCurrencyWhenChangedClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "Currency" + "PriceKind", "NoEditingAllowed" + "PriceKind");

	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	If CurrentRow[NameOfEditBanColumn] Then
		Return;
	EndIf;
	
	If CurrentRow.GetParent() = Undefined Then
		
		FeatureElements = CurrentRow.GetItems();
		CurrentValue   = CurrentData[CurColumnName];
		
		For Each ElementCharacteristic In FeatureElements Do
			If ElementCharacteristic[NameOfEditBanColumn] Then
				Continue;
			EndIf;
			If ElementCharacteristic[CurColumnName] <> CurrentValue Then
				ElementCharacteristic[CurColumnName] = CurrentValue;
			EndIf;
		EndDo;
		
	EndIf;
	
	PriceTreeCurrencyWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants);
	
EndProcedure

&AtServer
Procedure PriceTreeCurrencyWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName, "Currency");
EndProcedure

&AtClient
Procedure PriceTreeProductsOnChange(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ProductPriceTreeWhenChangedOnServer(CurrentData.GetID());
	
EndProcedure

&AtServer
Procedure ProductPriceTreeWhenChangedOnServer(RowID)
	
	CurrentRow = PriceTree.FindByID(RowID);
	If ValueIsFilled(CurrentRow.Products) Then
		CurrentRow.PriceGroup = Common.ObjectAttributeValue(CurrentRow.Products, "PriceGroup");
	EndIf;
	
	SetCurrenciesOfPriceTypes(CurrentRow, True);
	
EndProcedure

&AtClient
Procedure PriceTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormTableElementEventHandlersAreBoundDynamically

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
Procedure Attachable_PriceTreeCurrencyWhenChanged(Item)

	PriceTreeCurrencyWhenChangedClient(Item);

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
	
	If CurrentData.Products <> OldProducts Then
		
		ProductItems_ = PriceTree.GetItems();
		For Each ProductItem In ProductItems_ Do
			If ProductItem.Products = CurrentData.Products Then
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
		
		PriceTreeProductsOnChangeServer(
			Items.PriceTree.CurrentData.GetID(),
			Not Changed_Price);
		
		OldProducts = CurrentData.Products;
		
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Products) Then
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
						CurrentData.Products = OldProducts;
						CurrentData.Characteristic = OldCharacteristic;
					EndIf;
					Return;
				EndIf;
			EndIf;
		EndDo;
		
		PriceTreeCharacteristicOnChangeServer(
			Items.PriceTree.CurrentData.GetID(),
			Not Changed_Price);
		
	EndIf;
	
	If Items.PriceTree.CurrentItem.Name = Items.PriceTreeProducts.Name Then
		MarkModifiedFormulasServer();
	EndIf;
	
	RowAdded = False;
	
EndProcedure

&AtClient
Procedure PriceTreeOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PriceTree.CurrentData;
	OldProducts = CurrentData.Products;
	OldCharacteristic = CurrentData.Characteristic;
	Changed_Price = False;
	
EndProcedure

&AtClient
Procedure PriceTreeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.PriceSetupAttachedFiles") Then
		
		SettingPricesClient.ImportFromExcel(ThisObject, ValueSelected);
		
	EndIf;
	
EndProcedure


// "Initial Selection" handler for the "Formula" field"
// 
// Parameters:
// 	Item - FormField
// 	ChoiceData - ValueList
// 	StandardProcessing - Boolean
//@skip-warning
&AtClient
Procedure Attachable_PriceTreeFormulaBeginningOfChoice(Item, ChoiceData, StandardProcessing)

	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	AdditionalParameters = New Structure("NameOfReturnElement", CurColumnName);
	
	OpenForm("CommonForm.FormulasConstructor", GetParametersOfPriceEditingForm(Item.Name), Item,,,, New CallbackDescription("FormulasConstructorCompletion", ThisObject,AdditionalParameters), FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

&AtClient
Procedure FormulasConstructorCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If Result <> Undefined Then
		ChangeValueString = Result;
		CurrentData[AdditionalParameters.NameOfReturnElement]	= Result;
		Attachable_PriceTreeFormulaWhenChanging(Items["PriceTree" + AdditionalParameters.NameOfReturnElement]);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_PriceTreeFormulaWhenChanging(Item)
	
	ClearMessages();
	
	ColumnNameFormula = StrReplace(Item.Name, "PriceTree", "");
	
	FormulaText = Items.PriceTree.CurrentData[ColumnNameFormula];
	Operands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(FormulaText);
	ResultType = New TypeDescription("Number");
	FormulaValidationParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
	
	If ProcessingOfFormulasClient.CheckFormula(FormulaText,
		Operands,
		ResultType,
		FormulaValidationParameters) Then
		
		Changed_Price = True;
		
		PriceTreePriceWhenCustomerChanges(Item);
		
		// current column + dependent
		ArrayOfPriceTypes = New Array();
		PriceKind = GetPriceViewByColumnName(Item.Name);
		If PriceKind <> Undefined Then
			
			ArrayOfPriceTypes.Add(PriceKind.Ref);
			
			CalculationParameters = New Structure();
			CalculationParameters.Insert("ImportOldPrices", False);
			CalculationParameters.Insert("RoundingUpManualPrices", False);
			CalculationParameters.Insert("TypesOfPrices", ArrayOfPriceTypes);
			CalculationParameters.Insert("SelectedLinesOnly", True);
			CalculationParameters.Insert("OnlyEmpty", False);
			CalculationParameters.Insert("CalculationByFormulas", True);
			
			CalculatePricesOnServer(CalculationParameters);
			
		EndIf;
		
		SetVisibilityOfEditColumns();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreeVATRateONChange(Item)

	PriceTreeVATRateONChangeCustomer(Item);
	
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

&AtClient
Procedure ChangePricesByPercentageOnTheClientCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		ChangePricesToPercentageOnServer(CalculationParameters);
	
		InfoString = SettingPricesClient.CurLineInformation(
			Items,
			SelectedPrices,
			Object.Date,
			CurrentDate,
			UseItemVariants);
		
	EndIf;

EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangePricesNewOption(Command)
	
	ChangePricesOnClientByCallType();
	
EndProcedure

&AtClient
Procedure ChangePricesOnClientByCallType(PriceKind = Undefined)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices", False);
	FillParameters.Insert("RoundingUpManualPrices", True);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas", False);
	FillParameters.Insert("ConsiderCurrencyDifferences",True);
	
	ArrayOfCurrenciesByPriceType = FillInArrayOfCurrenciesByPriceType();
	If ArrayOfCurrenciesByPriceType.Count()>0 Then
		FillParameters.Insert("ArrayOfCurrenciesByPriceType",ArrayOfCurrenciesByPriceType);
	EndIf;
	
	OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
	OpenForm(
	"Document.PriceSetup.Form.FormOfChangePricesNewVariant",
	OpeningParameters, ThisObject,,,, New CallbackDescription("ChangePricesNewOptionOnClientEnds",
	ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangePricesOnClientEnd(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		ChangePricesOnServer(CalculationParameters);
	
		InfoString = SettingPricesClient.CurLineInformation(
			Items,
			SelectedPrices,
			Object.Date,
			CurrentDate,
			UseItemVariants);
		
	EndIf;

EndProcedure

&AtClient
Procedure AddGoodsByPriceGroup(Command)
	
	ValueSelected = Undefined;

	
	OpenForm(
		"Catalog.PriceGroups.ChoiceForm",
		New Structure("MultipleChoice", True),
		ThisObject,,,, New CallbackDescription("AddGoodsByPriceGroupCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPriceGroupCompletion(Result, AdditionalParameters) Export
	
	ValueSelected = Result;
	If ValueSelected <> Undefined Then
		AddPriceGroupProductsOnServer(ValueSelected);
	EndIf;

EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	SetPriceCalculationOptions = New Array;
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"));
	
	FormParameters = New Structure("UUID", UUID);
	FormParameters.Insert("SetPriceCalculationOptions", 		SetPriceCalculationOptions);
	FormParameters.Insert("UsePriceManagementSystem25", 	UsePriceManagementSystem25);
	
	AddressInTempStorage = Undefined;
	
	OpenForm(
		"DataProcessor.GoodsSelectionByPicking.Form.Form",
		FormParameters, ThisObject,,,,
		New CallbackDescription("AddGoodsByPickingCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export
	
	AddressInTempStorage = Result;
	If ValueIsFilled(AddressInTempStorage) Then
		AddProductsBySelectionOnServer(AddressInTempStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteProductsWithoutChangedPrices(Command)
	
	DeleteProductsWithoutChangedPricesOnServer();
	
EndProcedure

&AtServer
Procedure DeleteProductsWithoutChangedPricesOnServer()
	SettingPricesServer.DeleteProductsWithoutChangedPrices(ThisObject, True);
EndProcedure

&AtClient
Procedure ImportValidPrices(Command)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices", True);
	FillParameters.Insert("RoundingUpManualPrices",False);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",False);
	
	OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
	If OpeningParameters.ManualPriceViews.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dạng giá được ấn định thủ công.';
										|ru = 'Не выбраны виды цен, назначаемые вручную.';
										|en = 'Price types assigned manually are not selected.'; fa = 'Price types assigned manually are not selected.';
										|it = 'Non sono stati selezionati i prezzi inseriti manualmente.';
										|pl = 'Nie wybrano rodzajów cen, ustalanych ręcznie.';
										|tr = 'Manuel olarak atanan fiyat türleri seçilmedi.'"));
		Return;
	EndIf;
	
	OpenForm(
		"Document.PriceSetup.Form.SelectPriceCalculationParameters",
		OpeningParameters,
		ThisObject,,,, New CallbackDescription("ImportValidPricesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportValidPricesCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		CalculatePricesOnServer(CalculationParameters);
		
	EndIf;
	
	InfoString = SettingPricesClient.CurLineInformation(
		Items,
		SelectedPrices,
		Object.Date,
		CurrentDate,
		UseItemVariants);
	
EndProcedure

&AtClient
Procedure RoundManualPricesCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		CalculatePricesOnServer(CalculationParameters);
		
		InfoString = SettingPricesClient.CurLineInformation(
			Items,
			SelectedPrices,
			Object.Date,
			CurrentDate,
			UseItemVariants);
		
	EndIf;

EndProcedure

&AtClient
Procedure GoToEditingPriceTypesList(Command)
	
	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PriceTypesGroup;
	
EndProcedure

&AtClient
Procedure GoToPricing(Command)
	
	ClearMessages();
	
	If Not ThisObject.ReadOnly 
		And SettingPricesClientServer.DependentPricesNotSelected(ThisObject) Then
		
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("GoToPricingCompletion", ThisObject), NStr("vi = 'Đã tìm thấy các dạng giá phụ thuộc vào các dạng giá đã chọn. Chọn tất cả các dạng giá phụ thuộc?';
																						|ru = 'Найдены зависимые от выбранных виды цен. Выбрать все зависимые цены?';
																						|en = 'Price types that depend on the selected ones are found. Select all the dependent prices?'; fa = 'Price types that depend on the selected ones are found. Select all the dependent prices?';
																						|it = 'Trovati i tipi di prezzi subordinati a quelli selezionati. Selezionare tutti i prezzi subordinati?';
																						|pl = 'Znaleziono w zależności od wybranych typów cen. Wybrac wszystkie ceny zależne?';
																						|tr = 'Seçilen fiyat türlerine bağlı olarak fiyat türleri bulundu. Tüm bağlı fiyatlar seçilsin mi?'"), QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoToSettingPricesFragment();
	
EndProcedure

&AtClient
Procedure GoToPricingCompletion(QuestionResult, AdditionalParameters) Export

	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		SettingPricesClientServer.SelectAllDependentPrices_(ThisObject);
		SettingPricesClientServer.SelectAllInfluencingPrices_(ThisObject);
	EndIf;
	
	GoToSettingPricesFragment();

EndProcedure

&AtClient
Procedure GoToSettingPricesFragment()
	
	If Not ThisObject.ReadOnly 
		And Not SettingPricesClient.RequiredDataLayoutSchemaParametersFilledIn(ThisObject) Then
		Return;
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.PriceSettingGroup;
	WhenSwitchingToSettingPrices();

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure Calculate(Command)
	
	If Not SettingPricesClient.RequiredDataLayoutSchemaParametersFilledIn(ThisObject) Then
		Return;
	EndIf;
	
	CalculationParameters = Undefined;
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",False);
	FillParameters.Insert("CalculationOfInformationSecurity", True);
	FillParameters.Insert("CalculationByFormulas",True);
	
	OpenForm(
		"Document.PriceSetup.Form.SelectPriceCalculationParameters",
		ParametersForOpeningCalculationParametersSelectionForm(FillParameters),
		ThisObject,,,, New CallbackDescription("CalculateCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculateCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		CalculatePricesOnServer(CalculationParameters);
		
		InfoString = SettingPricesClient.CurLineInformation(
			Items,
			SelectedPrices,
			Object.Date,
			CurrentDate,
			UseItemVariants);
		
	EndIf;

EndProcedure

&AtClient
Procedure SelectAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			TableRow.Selected_5 = True;
			TableRow.Edit = True;
		EndIf;
	EndDo;
	
	SelectedPricesWereChanged = True;
	
EndProcedure

&AtClient
Procedure ClearAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			TableRow.Selected_5 = False;
			TableRow.Edit = False;
		EndIf;
	EndDo;
	
	SelectedPricesWereChanged = True;

EndProcedure

&AtClient
Procedure SelectAllDependentPrices(Command)
	
	SettingPricesClientServer.SelectAllDependentPrices_(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectAllInfluencingPrices(Command)
	
	SettingPricesClientServer.SelectAllInfluencingPrices_(ThisObject);
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// 	* CurrentData - FormDataTreeItem, FormDataCollectionItem - contains including:
//		** Ref - CatalogRef.TypesOfPrices - 
//		** Parameters - String - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentData");
	Return Result;
	
EndFunction

&AtClient
Procedure AddProducts(Command)
	
	Items.PriceTree.CurrentItem = Items.PriceTreeProducts;
	
	NewRow = PriceTree.GetItems().Add();
	Items.PriceTree.CurrentRow = NewRow.GetID();
	
	If Not Items.PriceTree.RowData(Items.PriceTree.CurrentRow) = Items.PriceTree.CurrentData Then
		
		PriceTree.GetItems().Delete(PriceTree.GetItems().IndexOf(NewRow));
		
		ClearMessages();
		CurrentData = Items.SelectedPrices.CurrentData;
		CommonClient.MessageToUser(NStr("vi = 'Trước khi thêm dòng, cần hủy tìm kiếm.';
										|ru = 'Перед добавлением строки необходимо отменить поиск.';
										|en = 'Before adding a line, cancel the search.'; fa = 'Before adding a line, cancel the search.';
										|it = 'Перед добавлением строки необходимо отменить поиск.';
										|pl = 'Before adding a line, cancel the search.';
										|tr = 'Satır eklemeden önce aramayı iptal etmeniz gerekmektedir.'"), 
				Object.Ref, 
				"PriceTreeAddProducts");
		
		Return;
		
	EndIf;
	
	SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(NewRow);
	Items.PriceTree.ChangeRow();
	
	RowAdded = True;
	
EndProcedure

&AtClient
Procedure ExportToExcel(Command)
	
#If WebClient Then
	ShowMessageBox(Undefined, NStr("vi = 'Không cho phép kết xuất ra Excel trong Web-client.';
									|ru = 'Выгрузка в Excel недоступна в Web-клиенте.';
									|en = 'Export to Excel is not available in the Web client.'; fa = 'Export to Excel is not available in the Web client.';
									|it = 'L''importazione in Excel non è disponibile in Web-client.';
									|pl = 'Eksportowanie do Excelu nie jest dostępne w kliencie webowym.';
									|tr = 'Excel''e aktarmak, Web istemcisinde kullanılamaz.'"));
#Else
	Notification = New CallbackDescription("UploadExtensionCompletionToExcel", ThisObject);
	MessageText = NStr("vi = 'Để kết xuất ra Excel, cần cài đặt phần mở rộng làm việc với tệp.';
						|ru = 'Для выгрузки в Excel необходимо установить расширение работы с файлами.';
						|en = 'To export data to Excel, install 1C:Enterprise Extension.'; fa = 'To export data to Excel, install 1C:Enterprise Extension.';
						|it = 'Per l''importazione in Excel è necessario installare l''estensione di lavoro con i file.';
						|pl = 'W celu eksportowanie do Excelu należy zainstalować rozszerzenie do pracy z plikami.';
						|tr = 'Excel''e aktarmak için dosya yönetimi uzantısı yapılandırmanız gerekmektedir.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
#EndIf

EndProcedure

&AtClient
Procedure UploadExtensionCompletionToExcel(Result, AdditionalParameters) Export
	
	If Modified Then
		ShowQueryBox(
			New CallbackDescription("UploadToExcelAfterQuestion", ThisObject), 
			NStr("vi = 'Trước khi kết xuất, cần ghi lại chứng từ. Ghi lại chứng từ và tiếp tục?';
				|ru = 'Перед выгрузкой документ необходимо записать. Выполнить запись документа и продолжить?';
				|en = 'Save the document before exporting it. Save the document and continue?'; fa = 'Save the document before exporting it. Save the document and continue?';
				|it = 'Prima del download è necessario salvare il documento. Salvare il documento e continuare?';
				|pl = 'Przed eksportowaniem dokument należy zapisać. Zapisać dokument i kontynuować?';
				|tr = 'Belgeyi aktarmadan önce kaydetmeniz gerekmektedir. Belge kaydı gerçekleştirilsin ve devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	UploadFragmentToExcel();
	
EndProcedure

&AtClient
Procedure UploadToExcelAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		Write();
	Else
		Return;
	EndIf;
	
	UploadFragmentToExcel();

EndProcedure

&AtClient
Procedure UploadFragmentToExcel()
	
	DocumentsArray = New Array;
	DocumentsArray.Add(Object.Ref);
	
	FormParameters = New Structure("DocumentsArray, UUID", DocumentsArray, UUID);
	PrintParameters = Undefined;
	
	OpenForm(
	"Document.PriceSetup.Form.SelectItemsPrices",
	FormParameters,,,,, New CallbackDescription("UploadToExcelEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure UploadToExcelEnd(Result, AdditionalParameters) Export
	
	PrintParameters = Result;
	If PrintParameters <> Undefined Then
		If PrintParameters.NumberOfSelectdPriceTypes = 0 Then
			ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dạng giá để kết xuất vào Excel.';
											|ru = 'Не выбраны виды цен для выгрузки в Excel.';
											|en = 'Price types to export to Excel are not selected.'; fa = 'Price types to export to Excel are not selected.';
											|it = 'Не выбраны виды цен для выгрузки в Excel.';
											|pl = 'Price types to export to Excel are not selected.';
											|tr = 'Excel''e yüklemek için fiyat türü seçilmedi.'"));
			Return;
		EndIf;
		PrintParameters.DisplayHeader = False;
		SettingPricesClient.ExportToExcel(ThisObject, PrintParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ImportFromExcel(Command)
	
#If WebClient Then
	ShowMessageBox(Undefined, NStr("vi = 'Không thể kết nhập từ Excel trong Web-client.';
									|ru = 'Загрузка из Excel недоступна в Web-клиенте.';
									|en = 'Import from Excel is not available in Web client.'; fa = 'Import from Excel is not available in Web client.';
									|it = 'Il download da Excel non è disponibile nel client-Web.';
									|pl = 'Importowanie z Excelu nie jest dostępne w kliencie webowym.';
									|tr = 'Excel''e yüklemek, Web istemcisinde kullanılamaz.'"));
#Else
	Notification = New CallbackDescription("DownloadFromExcelCompletionOfExtensionConnection", ThisObject);
	MessageText = NStr("vi = 'Để kết nhập từ Excel, cần cài đặt phần mở rộng làm việc với tệp.';
						|ru = 'Для загрузки из Excel необходимо установить расширение работы с файлами.';
						|en = 'To import data from Excel, install 1C:Enterprise Extension.'; fa = 'To import data from Excel, install 1C:Enterprise Extension.';
						|it = 'Per il download da Excel è necessario installare l''estensione di lavoro con i file.';
						|pl = 'W celu importowania z Excelu należy zainstalować rozszerzenie do pracy z plikami.';
						|tr = 'Excel''e yüklemek için dosya yönetimi uzantısı yapılandırmanız gerekmektedir.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
#EndIf

EndProcedure

&AtClient
Procedure DownloadFromExcelCompletionOfExtensionConnection(Result, AdditionalParameters) Export
	
	FilesOperationsClient.OpenFileChoiceForm(Object.Ref, Items.PriceTree);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.PriceSetup.DocumentForm.Command.SelectGoods"
	,
	True);
	
	SetPriceCalculationOptions = New Array;
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"));
	
	FormParameters = New Structure;
	FormParameters.Insert("TheModeOfSelectionForDocumentsPricing", True);
	FormParameters.Insert("UsePriceManagementSystem25",            UsePriceManagementSystem25);
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters",  True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",        True);
	FormParameters.Insert("HideTheViewPriceColumn",                   True);
	FormParameters.Insert("HideTheItemPricesCommand",          True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",          True);
	FormParameters.Insert("HideTheRequestQuantityButton",      True);
	FormParameters.Insert("Document",                                 Object.Ref);
	FormParameters.Insert("Title",                                NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                     Object.Date);
	FormParameters.Insert("DoNotSplitSetsByComponents",         True);
	FormParameters.Insert("SelectionByTheOptionOfCalculatingThePricesOfSets",         SetPriceCalculationOptions);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);

EndProcedure

&AtClient
Procedure SalesDynamicsReport(Command)
	If UsePriceManagementSystem25 Then
		ItemList  	= New ValueList;
		ListOfTSOCharacteristics	= New ValueList;
		ListOfTSOSeries 			= New ValueList;
		ListOfTSOPackages 		= New ValueList;
		
		For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
			
			TSRow = PriceTree.FindByID(IDOfPriceTreeRow);
			ItemList.Add(TSRow.Products);
			
			If ValueIsFilled(TSRow.PricingVariant) Then
				If ListOfTSOCharacteristics.FindByValue(TSRow.PricingVariant) = Undefined Then
					ListOfTSOCharacteristics.Add(TSRow.PricingVariant);				
				EndIf;
			EndIf;
			
			If ValueIsFilled(TSRow.PricingBatch) Then
				If ListOfTSOSeries.FindByValue(TSRow.PricingBatch) = Undefined Then
					ListOfTSOSeries.Add(TSRow.PricingBatch);				
				EndIf;
			EndIf;
			
			If ValueIsFilled(TSRow.PricingPackage) Then
				If ListOfTSOSeries.FindByValue(TSRow.PricingPackage) = Undefined Then
					ListOfTSOPackages.Add(TSRow.PricingPackage);				
				EndIf;
			EndIf;
			
		EndDo;
		
		ListOfPriceTypes = New ValueList;
		For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			ListOfPriceTypes.Add(PriceTypeLine.Ref, PriceTypeLine.Description);
		EndDo;
		
		Filter = New Structure;
		Filter.Insert("Products", ItemList);
		If ListOfTSOCharacteristics.Count() Then
			Filter.Insert("PricingVariant", ListOfTSOCharacteristics);
		EndIf;	
		If ListOfTSOSeries.Count() Then
			Filter.Insert("PricingBatch", ListOfTSOSeries);
		EndIf;	
		If ListOfTSOPackages.Count() Then
			Filter.Insert("PricingPackage", ListOfTSOPackages);
		EndIf;	
		Filter.Insert("PriceKind", ListOfPriceTypes);
		
		FormParameters = New Structure();
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.TrendsOfItemPrices2_5.Form",
			FormParameters,
			ThisObject,
			New UUID);
	Else	
		ItemList  = New ValueList;
		ListOfCharacteristics = New ValueList;
		For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
			TSRow = PriceTree.FindByID(IDOfPriceTreeRow);
			ItemList.Add(TSRow.Products);
			If TSRow.ItemVariantsAreUsed Then
				If TSRow.GetParent() = Undefined Then
					For Each StringCharacteristic In TSRow.GetItems() Do
						If ListOfCharacteristics.FindByValue(StringCharacteristic.Characteristic) = Undefined Then
							ListOfCharacteristics.Add(StringCharacteristic.Characteristic);
						EndIf;
					EndDo;
				Else
					If ListOfCharacteristics.FindByValue(TSRow.Characteristic) = Undefined Then
						ListOfCharacteristics.Add(TSRow.Characteristic);
					EndIf;
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
		Filter.Insert("PriceKind", ListOfPriceTypes);
		
		FormParameters = New Structure();
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.TrendsOfItemPrices.Form",
			FormParameters,
			ThisObject,
			New UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditSettings(Command)
	
	CurrentData = Items.SelectedPrices.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể soạn tùy chỉnh. Chưa chọn dạng giá';
										|ru = 'Редактировать настройки невозможно. Не выбран вид цены';
										|en = 'Cannot edit settings. Price type is not selected'; fa = 'Cannot edit settings. Price type is not selected';
										|it = 'Non è possibile modificare le impostazioni. Nessun tipo di prezzo selezionato';
										|pl = 'Nie można edytować ustawień. Nie wybrano rodzaj ceny';
										|tr = 'Ayarları düzenleyemezsiniz. Fiyat türü seçilmedi'"));
		Return;
	EndIf;
	
	If Object.Approved Then
		Return;
	EndIf;
	
	If Not CurrentData.Selected_5 Then
			ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể soạn tùy chỉnh sơ đồ dàn dựng đối với các dạng giá đã chọn';
											|ru = 'Редактировать настройки схемы компоновки можно только для выбранных видов цен';
											|en = 'You can edit composition schema settings only for the selected price types'; fa = 'You can edit composition schema settings only for the selected price types';
											|it = 'È possibile modificare le impostazioni dello schema di configurazione solo per i tipi di prezzi selezionati';
											|pl = 'Można edytować ustawienia schematu układu tylko dla wybranych rodzajów cen.';
											|tr = 'Sadece seçilen fiyat türleri için inşa şeması ayarlarını düzenleyebilirsiniz'"));
		Return;
	EndIf;
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh tham số đối với dạng giá ""%1""';
													|ru = 'Настройка параметров для вида цены ""%1""';
													|en = 'Setting of parameters for kind of price ""%1""'; fa = 'Setting of parameters for kind of price ""%1""';
													|it = 'Impostazione dei parametri per il tipo di prezzo ""%1""';
													|pl = 'Ustawienie parametrów dla rodzaju ceny ""%1""';
													|tr = '""%1"" fiyat türü parametrelerinin ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", CurrentData.Description);
	
	AddressOfDataCompositionSchemaSettings = PriceSetupServerCall.AddressOfDataLayoutSettingsForPriceView(
		CurrentData.Ref,
		StorageAddressDataLayoutSettings,
		UUID);
	
	AddressOfComposerConfigurationStore = Undefined;
	AddressOfDataCompositionSchemaSettings = ?(AddressOfDataCompositionSchemaSettings <> Undefined,
	                                       AddressOfDataCompositionSchemaSettings,
	                                       CurrentData.AddressOfDataCompositionSchemaSettings);

	FormParameters = New Structure();
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema",      True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting",           True);
	FormParameters.Insert("DoNotConfigureTheSelection",                        True);
	FormParameters.Insert("DonTAdjustTheOrder",                      True);
	FormParameters.Insert("AddressOfDataCompositionSchema",                CurrentData.AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings",             AddressOfDataCompositionSchemaSettings);
	FormParameters.Insert("UUID",                   UUID);
	FormParameters.Insert("Title",                                 HeaderOfDataLayoutSchemaConfigurationForm);

	FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", "PriceManagementSystem.CheckingCorrectnessOfPriceTypeScheme");
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentData = CurrentData;
	
	Notification = New CallbackDescription("EditSettingsCompletion", ThisObject, AdditionalParameters);
	OpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema", FormParameters,,,,, Notification, OpeningMode);
	
EndProcedure

// Parameters:
// 	Result - UUID, String - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure EditSettingsCompletion(Result, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	
	
	AddressOfComposerConfigurationStore = Result;
	
	If AddressOfComposerConfigurationStore <> Undefined Then
		
		SelectedPricesWereChanged = True;
		StructureOfData = PriceSetupServerCall.SetDataLayoutSettingsForPriceView(
		CurrentData.Ref,
		AddressOfComposerConfigurationStore,
		StorageAddressDataLayoutSettings,
		AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
		CurrentData.Parameters = StructureOfData.ParametersDetails;
		Modified = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure RestoreDefaultSettings(Command)
	
	CurrentData = Items.SelectedPrices.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể soạn tùy chỉnh. Chưa chọn dạng giá';
										|ru = 'Редактировать настройки невозможно. Не выбран вид цены';
										|en = 'Cannot edit settings. Price type is not selected'; fa = 'Cannot edit settings. Price type is not selected';
										|it = 'Non è possibile modificare le impostazioni. Nessun tipo di prezzo selezionato';
										|pl = 'Nie można edytować ustawień. Nie wybrano rodzaj ceny';
										|tr = 'Ayarları düzenleyemezsiniz. Fiyat türü seçilmedi'"));
		Return;
	EndIf;
	
	If Object.Approved Then
		Return;
	EndIf;
	
	If Not CurrentData.Selected_5 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể soạn tùy chỉnh sơ đồ dàn dựng đối với các dạng giá đã chọn.';
										|ru = 'Редактировать настройки схемы компоновки можно только для выбранных видов цен.';
										|en = 'You can edit composition schema settings only for the selected price types.'; fa = 'You can edit composition schema settings only for the selected price types.';
										|it = 'È possibile modificare le impostazioni dello schema di configurazione solo per i tipi di prezzi selezionati.';
										|pl = 'Można edytować ustawienia schematu układu tylko dla wybranych rodzajów cen.';
										|tr = 'Sadece seçilen fiyat türleri için inşa şeması ayarlarını düzenleyebilirsiniz.'"));
		Return;
	EndIf;
	
	AddressOfComposerConfigurationStore = PriceSetupServerCall.DefaultDataLayoutSchemeSettings(
		CurrentData.Ref, CurrentData.AddressOfDataCompositionSchema, UUID);
	
	If AddressOfComposerConfigurationStore <> Undefined Then
		
		SelectedPricesWereChanged = True;
		StructureOfData = PriceSetupServerCall.SetDataLayoutSettingsForPriceView(
			CurrentData.Ref,
			AddressOfComposerConfigurationStore,
			StorageAddressDataLayoutSettings,
			AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
		CurrentData.Parameters = StructureOfData.ParametersDetails;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheProductsForTheSelectionOfPriceTypes(Command)
	
	AddProductsByDCSSelectionOnServer();
	
EndProcedure

&AtClient
Procedure SortByProductName(Command)
	
	SortOnServer();
	
EndProcedure

&AtClient
Procedure SortByProductNameUsingTypeHierarchy(Command)
	SortOnServer("ByProductNameHierarchyOfProductTypes");
EndProcedure

&AtClient
Procedure SortByProductNameUsingGroupHierarchy(Command)
	SortOnServer("HierarchyOfGroupsByProductName");
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = GetNumberOfRowsOfPriceTree();
	
	TypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(ThisObject);
	
	If TypesOfPrices.Count() > 1 Then
		FormOpenParameters = New Structure("TypesOfPrices", TypesOfPrices);
		PriceTypeToFillIn_ = Undefined;

		OpenForm("Document.PriceSetup.Form.PriceTypeChoiceForm",
			FormOpenParameters, ThisObject,,,,
			New CallbackDescription("InsertRowsCompletion", ThisObject, New Structure("TypesOfPrices, NumberOfProductsBeforeInsertion", TypesOfPrices, NumberOfProductsBeforeInsertion)),
			FormWindowOpeningMode.LockOwnerWindow);
		Return;
	Else
		PriceTypeToFillIn_ = TypesOfPrices.Get(0);
	EndIf;
	
	InsertStringSnippet(PriceTypeToFillIn_, NumberOfProductsBeforeInsertion);
EndProcedure

&AtClient
Procedure InsertRowsCompletion(Result, AdditionalParameters) Export
	
	TypesOfPrices = AdditionalParameters.TypesOfPrices;
	NumberOfProductsBeforeInsertion = AdditionalParameters.NumberOfProductsBeforeInsertion;
	
	PriceTypeToFillIn_ = Result;
	
	InsertStringSnippet(PriceTypeToFillIn_, NumberOfProductsBeforeInsertion);

EndProcedure

&AtClient
Procedure InsertStringSnippet(PriceTypeToFillIn_, Val NumberOfProductsBeforeInsertion)
	
	GetLinesFromClipboard(PriceTypeToFillIn_);
	
	NumberOfInserted = GetNumberOfRowsOfPriceTree() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);

EndProcedure

&AtClient
Procedure SetUpDisplayedInformation(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ShowPriceChange",   ShowPriceChange);
	FormParameters.Insert("ShowMarkupPercent",  ShowMarkupPercent);
	FormParameters.Insert("ShowEffectivePrices", ShowEffectivePrices);
	FormParameters.Insert("ValidPriceDate",        Undefined);
	FormParameters.Insert("ShowFormulas", 		 ShowFormulas);
	FormParameters.Insert("ShowCurrency", 		 ShowCurrency);
	FormParameters.Insert("ShowUnitsOfMeasurement",ShowUnitsOfMeasurement);
	FormParameters.Insert("CalculateAutomatically", CalculateAutomatically);
	FormParameters.Insert("ShowInfluencingPrices",    ShowInfluencingPrices);
	FormParameters.Insert("FixTheItemColumn", 	FixTheItemColumn);
	FormParameters.Insert("UseOneColumnForThePriceKey", 	UseOneColumnForThePriceKey);
	FormParameters.Insert("ShowDate",            False);
	If UsePriceManagementSystem25 Then
		FormParameters.Insert("ShowVATRate", 	ShowVATRate);
	EndIf;

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
	ShowFormulas 		  = Result.ShowFormulas;
	ShowCurrency 		  = Result.ShowCurrency;
	ShowUnitsOfMeasurement= Result.ShowUnitsOfMeasurement;
	CalculateAutomatically = Result.CalculateAutomatically;
	FixTheItemColumn = Result.FixTheItemColumn;
	ShowVATRate			= Result.ShowVATRate;

	SetCountAutomaticallyOnClient(CalculateAutomatically);
	FixTheItemColumn(FixTheItemColumn);

	If UseOneColumnForThePriceKey <> Result.UseOneColumnForThePriceKey Then
		UseOneColumnForThePriceKey = Result.UseOneColumnForThePriceKey;
		ConfigurePriceKeyColumns();
	EndIf;

	If ShowInfluencingPrices <> Result.ShowInfluencingPrices Then		
		ShowInfluencingPrices = Result.ShowInfluencingPrices;
		DisplayInfluencingPricesOnClient(ShowInfluencingPrices);	
	EndIf;

	SetVisibilityOfEditColumns();
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.PriceTree) Then
		
		TypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(ThisObject);
		
		If TypesOfPrices.Count() > 1 Then
			FormOpenParameters = New Structure("TypesOfPrices", TypesOfPrices);
			PriceTypeToFillIn_ = Undefined;

			OpenForm("Document.PriceSetup.Form.PriceTypeChoiceForm",
				FormOpenParameters, ThisObject,,,,
				New CallbackDescription("CopyRowsCompletion", ThisObject, New Structure("TypesOfPrices", TypesOfPrices)),
				FormWindowOpeningMode.LockOwnerWindow);
		    Return;
		Else
			CopiedPriceView = TypesOfPrices.Get(0);
		EndIf;
		
		CopyLinesFragment(CopiedPriceView);
	EndIf;
EndProcedure

&AtClient
Procedure CopyRowsCompletion(Result, AdditionalParameters) Export
	
    TypesOfPrices = AdditionalParameters.TypesOfPrices;    
	If ValueIsFilled(Result) Then
		
	    CopiedPriceView = Result;
		CopyLinesFragment(CopiedPriceView);
	
	EndIf;

EndProcedure // ()

&AtClient
Procedure CopyLinesFragment(Val CopiedPriceView)
	
	CopyLinesOnServer(CopiedPriceView);
	ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.PriceTree.SelectedRows.Count());

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure PriceTreeAfterDeletionOnServer()
	MarkModifiedFormulasServer();
	AddressOfDataCacheStorage = "";
EndProcedure

&AtClient
Procedure FillInVATRate(Command)
	
	SettingPricesClient.OpenVATRatesForm(ThisObject, Object.Date);
	
EndProcedure

#Region Other

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	ProductsTable = SettingPricesServer.CreateProductTable(ThisObject);
	
	Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
	
	FilterValues = New Structure();
	FilterValues.Insert("ByArrayOfProducts", TableOfGoods.UnloadColumn("Products"));

	Filter_Settings.Insert("FilterValues", FilterValues);
	Filter_Settings.Insert("Date", Object.Date);
	Filter_Settings.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
	Filter_Settings.Insert("UseItemVariants", UseItemVariants);
	Filter_Settings.Insert("UseItemsBatch", UseItemsBatch);
	Filter_Settings.Insert("UseItemPackages", UseItemPackages);
	
	SettingPricesServer.GetDataOnProducts(Filter_Settings, ProductsTable);
		
	SettingPricesServer.AddGoodsByPicking(ThisObject, ValueSelected.GoodsAddressInStorage, ProductsTable);

	UpdateOldProductPricesOnServer();

EndProcedure

// Sets the flag for fixing the "Nomenclature" and "Characteristic" columns on the left
//
// Parameters:
// NewValue - Boolean
//
&AtServer
Procedure FixTheItemColumn(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	FixTheItemColumn = NewValue;
	
	Items.PriceTreeGroupItem.FixingInTable = ?(FixTheItemColumn,FixingInTable.Left,FixingInTable.None);
	
EndProcedure

// Performs the necessary actions when going to the price setting page
//
&AtClient
Procedure WhenSwitchingToSettingPrices()
	
	If Not SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject).Count() > 0 Then
		
		CommonClient.MessageToUser(NStr("vi = 'Để chuyển đến đặt bảng giá, cần chọn một hoặc nhiều dạng giá';
										|ru = 'Для перехода к установке цен, необходимо выбрать один или несколько видов цен';
										|en = 'To go to the pricing, select one price type or more'; fa = 'To go to the pricing, select one price type or more';
										|it = 'Per procedere all''impostazione dei prezzi, è necessario selezionare uno o più tipi di prezzi';
										|pl = 'Aby przejść do ustalania cen, należy wybrać jeden lub więcej rodzajów cen.';
										|tr = 'Fiyat yapılandırmaya geçiş için bir veya daha fazla fiyat türü seçmeniz gerekmektedir'"),,"SelectedPrices");
		Items.GroupPages.CurrentPage = Items.PriceTypesGroup;
		
	Else
		
		If SelectedPricesWereChanged Then
			
			SelectedPricesWereChanged = False;
			
			CallbackDescription = New CallbackDescription("WhenSwitchingToSettingPricesCompletion", ThisObject);
			If PriceTree.GetItems().Count() > 0 Then
				ShowQueryBox(
					CallbackDescription,
					NStr("vi = 'Đã thay đổi thành phần giá hoặc tham số tính toán. Tính lại giá?';
						|ru = 'Состав цен или параметры расчета изменились. Пересчитать цены?';
						|en = 'Price content or calculation parameters have changed. Recalculate the prices?'; fa = 'Price content or calculation parameters have changed. Recalculate the prices?';
						|it = 'Composizione dei prezzi o parametri del calcolo sono cambiati. Ricalcolare i prezzi?';
						|pl = 'Zmienił się skład cen lub parametry obliczeń. Przeliczyć ceny ponownie?';
						|tr = 'Fiyatların içeriği veya hesaplama parametreleri değişti. Fiyatlar yeniden hesaplansın mı?'"),
					QuestionDialogMode.YesNo);
			Else
				RunCallback(CallbackDescription, DialogReturnCode.No);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSwitchingToSettingPricesCompletion(QuestionResult, AdditionalParameters) Export
	
	RecalculatePrices_ = ?(PriceTree.GetItems().Count() > 0, QuestionResult = DialogReturnCode.Yes, True);
	
	ReformatPriceTable(RecalculatePrices_);
	SetVisibilityOfEditColumns();

EndProcedure

// Procedure-handler of the event " when Changing "of the" woodcut " field.
//
&AtServer
Procedure PriceTreeProductsOnChangeServer(RowID, CalculatePrices = True)
	
	CurrentRow = PriceTree.FindByID(RowID);
	
	If CurrentRow.GetParent() = Undefined Then
		Characteristics = CurrentRow.GetItems();
		If Characteristics.Count() > 0 Then
			If Characteristics[0].Products <> CurrentRow.Products Then
				CurrentRow.GetItems().Clear();
			EndIf;
		EndIf;
	EndIf;
	
	SetCurrenciesOfPriceTypes(CurrentRow, CalculatePrices);
	
	AddressOfDataCacheStorage = "";
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		ProductsTable = SettingPricesServer.CreateProductTable(ThisObject);
		
		Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
		
		FilterValues = New Structure();
		FilterValues.Insert("RemainingGoodsByShelfLives", CurrentRow.Products);
		
		Filter_Settings.Insert("FilterValues", FilterValues);
		Filter_Settings.Insert("Date", Object.Date);
		Filter_Settings.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
		Filter_Settings.Insert("UseItemVariants", UseItemVariants);
		Filter_Settings.Insert("UseItemsBatch", UseItemsBatch);
		Filter_Settings.Insert("UseItemPackages", UseItemPackages);
		
		SettingPricesServer.GetDataOnProducts(Filter_Settings, ProductsTable);
		
		ProductsTable = SettingPricesServer.AddProducts_2(ThisObject, ProductsTable, DataCache);
		
	Else
		
		CurrentRow.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		CurrentRow.PriceGroup    = Catalogs.PriceGroups.EmptyRef();
		
	EndIf;
	
	// Loading old prices and percentage changes
	ValueTable = SettingPricesServer.CreateProductsTable(False, UsePriceManagementSystem25);
	
	If ValueIsFilled(ProductsTable) And ProductsTable.Count() > 0 Then
		GetDataForLoadingPricesFromProductTable(ValueTable, ProductsTable);
	Else
		GetDataForLoadingSoftwarePricesByPriceTree(ValueTable, CurrentRow);
	EndIf;
	
	SettingPricesServer.LoadOldPricesOfProducts(ThisObject, ValueTable, DataCache);
	
	If CalculatePrices Then
		If UsePriceManagementSystem25 Then
			SettingPricesServer.CalculatePricesByRowId2_5(ThisObject, RowID, True,,DataCache);
		Else
			SettingPricesServer.CalculatePricesByRowId(ThisObject, RowID, True,,DataCache);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDataForLoadingSoftwarePricesByPriceTree(ValueTable, CurrentRow)
	
	TSOBatchPredefined = Common.ObjectAttributeValue(CurrentRow.PricingBatch, "Predefined");
	
	For Each PriceTypeLine In SelectedPrices Do
	
		If PriceTypeLine.Selected_5 Or PriceTypeLine.Influences Then
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			ColumnNameFormula = "Formula" + ColumnName;
			ColumnNameCurrency = "Currency" + ColumnName;
			
			NewRow = ValueTable.Add();
			FillPropertyValues(NewRow, CurrentRow);
			If UsePriceManagementSystem25 Then
				NewRow.TsoPackagingForCommunication   = ?(CurrentRow.PricingPackage = CurrentRow.UnitOfMeasure, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), CurrentRow.PricingPackage);
				NewRow.TSOSeriesForCommunication   = ?((ValueIsFilled(TSOBatchPredefined) And TSOBatchPredefined), Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), CurrentRow.PricingBatch);
			EndIf;
			NewRow.PriceKind        = PriceTypeLine.Ref;
			NewRow.Price           = CurrentRow[ColumnName];
			If UseItemPackages Then
				NewRow.Package   = CurrentRow[ColumnNamePackaging];
			EndIf;
			NewRow.Formula   = CurrentRow[ColumnNameFormula];
			NewRow.Currency    = CurrentRow[ColumnNameCurrency];
			
			For Each SubordinateRow In CurrentRow.GetItems() Do
				GetDataForLoadingSoftwarePricesByPriceTree(ValueTable, SubordinateRow);
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure
	
&AtServer
Procedure GetDataForLoadingPricesFromProductTable(ValueTable, ProductsTable)
	
	For Each PriceTypeLine In SelectedPrices Do
	
		If PriceTypeLine.Selected_5
			Or PriceTypeLine.Influences Then
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			ColumnNameFormula = "Formula" + ColumnName;
			
			For Each RowOfProductTable In ProductsTable Do
				
				NewRow = ValueTable.Add();
				FillPropertyValues(NewRow, RowOfProductTable);
				
				NewRow.PriceKind = PriceTypeLine.Ref;
				NewRow.Currency = PriceTypeLine.Currency;
				NewRow.Price = RowOfProductTable.PriceTreeString[ColumnName];
				NewRow.Formula = RowOfProductTable.PriceTreeString[ColumnNameFormula];
				
				If UseItemPackages Then
					NewRow.Package = RowOfProductTable.PriceTreeString[ColumnNamePackaging];
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Procedure - the event handler for the "Primenenie" fields "Derevozaschitnoe".
//
&AtServer
Procedure PriceTreeCharacteristicOnChangeServer(RowID, CalculatePrices = True)
	
	SettingPricesServer.PriceTreeCharacteristicOnChange(ThisObject, RowID, CalculatePrices);
	
EndProcedure

// Adds products from the price group to the price table
//
// Parameters:
// PriceGroups - Array
//
&AtServer
Procedure AddPriceGroupProductsOnServer(PriceGroups)
	
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	ProductsTable = SettingPricesServer.CreateProductTable(ThisObject);
	
	Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
	
	FilterValues = New Structure();
	FilterValues.Insert("ByPriceGroups", PriceGroups);

	Filter_Settings.Insert("FilterValues", FilterValues);
	Filter_Settings.Insert("Date", Object.Date);
	Filter_Settings.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
	Filter_Settings.Insert("UseItemVariants", UseItemVariants);
	Filter_Settings.Insert("UseItemsBatch", UseItemsBatch);
	Filter_Settings.Insert("UseItemPackages", UseItemPackages);
	
	SettingPricesServer.GetDataOnProducts(Filter_Settings, ProductsTable);
	
	GoodsTable = SettingPricesServer.AddProducts_2(ThisObject, ProductsTable, DataCache);	

	SettingPricesServer.UpdateOldProductPrices(ThisObject, DataCache, GoodsTable);
	
	// Automatic price calculation
	UploadPricesFromIB = True;
	If CalculateAutomatically Then
		
		If UploadPricesFromIB Then
			SettingPricesServer.LoadBasePriceValues(ThisObject, GoodsTable, DataCache);
			SettingPricesServer.CalculatePricesBasedOnInformationSecurityData(ThisObject, GoodsTable,,,DataCache);
		EndIf;
		
		SettingPricesServer.CalculateCalculatedPrices(
			ThisObject, GoodsTable, DataCache);
		
	EndIf;
	
	// Let's set the last added line to the current one
	If DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Count() > 0 Then
		Items.PriceTree.CurrentRow = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree[
			DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Count()-1].PriceTreeString.GetID();
	EndIf;
	
	SettingPricesServer.MarkModifiedFormulas(ThisObject);
	
EndProcedure

// Sets the automatic price recalculation flag
//
// Parameters:
// NewValue - Boolean
//
&AtClient
Procedure SetCountAutomaticallyOnClient(NewValue)
	
	CalculateAutomatically = NewValue;
	
EndProcedure

&AtClient
Procedure DisplayInfluencingPricesOnClient(NewValue)
	
	ShowInfluencingPrices = NewValue;	
	
	ReformatPriceTable = False;
	For Each PriceKind In SelectedPrices Do
		If Not PriceKind.Selected_5 And PriceKind.Influences And Not PriceKind.ProhibitedPriceType Then
			ReformatPriceTable = True;
		EndIf;
	EndDo;
	
	If ReformatPriceTable Then
		ReformatPriceTable(False);
	EndIf;
EndProcedure

// Returns the structure of parameters required for calculating prices
//
// Parameters:
// Loading old prices-Boolean-Indicates the need to load old values of manual prices
// Rounding the unit price-Boolean-Indicates the need for rounding manual prices.
//
// Returns:
// Structure
// Structure Keys:
// Loading the Old Price - Boolean
// Rounding up the individual price is Boolean
// View Price Array
//
&AtClient
Function ParametersForOpeningCalculationParametersSelectionForm(FillParameters)
	
	TypesOfPrices = New Array();
	
	For Each LineTypesOfPrice In SelectedPrices Do
		If Not (LineTypesOfPrice.Selected_5 And LineTypesOfPrice.Edit) Then
			Continue;
		EndIf;
		If FillParameters.CalculationOfInformationSecurity 
			And (LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseData")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataOnReceipt")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost")) Then
					
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		ElsIf FillParameters.CalculationByFormulas 
				And (LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes")) Then
					
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		Else
			TypesOfPrices.Add(LineTypesOfPrice.Ref);
		EndIf;
	EndDo;                                
	
	OnlySelectedItems = Items.PriceTree.SelectedRows.Count() > 1;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ImportOldPrices", FillParameters.ImportOldPrices);
	ReturnStructure.Insert("RoundingUpManualPrices", FillParameters.RoundingUpManualPrices);
	ReturnStructure.Insert("ManualPriceViews", TypesOfPrices);
	ReturnStructure.Insert("DocumentDate", Object.Date);
	ReturnStructure.Insert("OnlySelectedItems", OnlySelectedItems);
	ReturnStructure.Insert("AllKindsOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject, True));
	If FillParameters.Property("CalculationByFormulas") Then
		ReturnStructure.Insert("CalculationByFormulas", FillParameters.CalculationByFormulas);
	EndIf;
	ReturnStructure.Insert("OnlyEmpty",False);
	If FillParameters.Property("ArrayOfCurrenciesByPriceType") Then
		ReturnStructure.Insert("ArrayOfCurrenciesByPriceType", FillParameters.ArrayOfCurrenciesByPriceType);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function DateForRequestingProductPrices()
	
	Return Object.Date - 1;
	
EndFunction

&AtServer
Procedure FillInDocument()
	
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	If Object.TypesOfPrices.Count() > 0 
		Or Object.Goods.Count() > 0 
		Or Object.Goods2_5.Count() > 0 
		Or Not UseSeveralPriceTypes 
		Or SelectedPrices.Count() = 1 Then
		
		If SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject).Count() > 0 Then
			
			SettingPricesServer.BuildPriceTree(ThisObject);
			SettingPricesServer.LoadTablePart(ThisObject, DataCache);
			SettingPricesServer.DownloadBasePrices(ThisObject, DataCache);
			Items.GroupPages.CurrentPage = Items.PriceSettingGroup;
			
		Else
			
			If Not UseSeveralPriceTypes Or SelectedPrices.Count() = 1 Then
				For Each CurRow In SelectedPrices Do
					CurRow.Selected_5 = True;
					CurRow.Edit = True;
				EndDo;
			EndIf;

			// The document is entered on the basis of the Purchase of goods and services.
			// It is necessary to select the prices calculated according to the receipt document and reformulate the price table.
			If ValueIsFilled(Object.DocumentBasis)
				And Not ValueIsFilled(Object.Ref) Then
				
				For Each CurRow In SelectedPrices Do
					If CurRow.SetPriceDuringGeneration
						And Not CurRow.ProhibitedPriceType Then
						CurRow.Selected_5 = True;
						CurRow.Edit = True;
						NewRow = Object.TypesOfPrices.Add();
						NewRow.PriceKind = CurRow.Ref;
					EndIf;
				EndDo;
				
				SettingPricesClientServer.SelectAllDependentPrices_(ThisObject);
				SettingPricesClientServer.SelectAllInfluencingPrices_(ThisObject);
				SelectedPricesWereChanged = False;
				
				If SettingPricesClientServer.SelectedTypesOfPrices(ThisObject).Count() > 0 Then
					
					TypesOfDownloadedOldPrices = New Array();
					For Each CurRow In SelectedPrices Do
						If CurRow.Selected_5 And (CurRow.PricingMethod = Enums.PriceSettingMethods.Manually) Then
							TypesOfDownloadedOldPrices.Add(CurRow);
						EndIf;
					EndDo;
					
					SettingPricesServer.BuildPriceTree(ThisObject);
					SettingPricesServer.LoadTablePart(ThisObject, DataCache);
					
					SettingPricesServer.PutPriceTypesInTablePart(ThisObject, Object.TypesOfPrices);
					
					Data = New Structure;
					Data.Insert("Form", ThisObject);
					Data.Insert("Documents", New Array);
					Data.Insert("SaveBasic", False);
					Data.Documents.Add(Object);
					SettingPricesServer.PutPricesInTablePart(Data);
					
					SettingPricesServer.UpdateOldProductPrices(ThisObject, DataCache);
					
					ProductsTable = SettingPricesServer.CreateTableOfProductsOnPriceTree(ThisObject, False);
					
					SettingPricesServer.FillInNDSBidInItemTable(ThisObject, ProductsTable);
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("ArrayOfPriceTypeStrings", TypesOfDownloadedOldPrices);
					ParametersStructure.Insert("ApplyRounding", False);
					
					SettingPricesServer.LoadBasePriceValues(
						ThisObject,
						ProductsTable,
						DataCache,
						ParametersStructure);
					
					If SettingPricesServer.RequiredDataLayoutSchemaParametersFilledIn(ThisObject, False) Then
						
						SettingPricesServer.CalculatePricesBasedOnInformationSecurityData(ThisObject, ProductsTable,,,DataCache);
						
						SettingPricesServer.CalculateCalculatedPrices(ThisObject, ProductsTable, DataCache);
						
						Items.GroupPages.CurrentPage = Items.PriceSettingGroup;
					
					EndIf;
					
				EndIf;
				
			Else
				
				SettingPricesServer.BuildPriceTree(ThisObject);
				SettingPricesServer.LoadTablePart(ThisObject, DataCache);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetState()
	
	If Object.Posted And Object.Status = Enums.ProductPricingStatuses.Approved Then
		State = Enums.ProductPricingStates.Valid;
	ElsIf Object.Posted And Object.Status = Enums.ProductPricingStatuses.NotApproved Then
		State = Enums.ProductPricingStates.PendingApproval;
	Else
		State = Enums.ProductPricingStates.EmptyRef();
	EndIf;
	
	Overdue = Object.Status = Enums.ProductPricingStatuses.NotApproved And BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate());
	
EndProcedure

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
Procedure AddProductsByDCSSelectionOnServer()
	
	SettingPricesServer.AddProductsByDCSSelection(ThisObject);

EndProcedure

&AtServer
Procedure SortOnServer(Mode = "ByProductsName")
	
	SetPrivilegedMode(True);
	
	AddressOfDataCacheStorage = "";
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	Data = New Structure;
	Data.Insert("Form", ThisObject);
	Data.Insert("Documents", New Array);
	Data.Insert("SaveBasic", False);
	Data.Documents.Add(Object);
	SettingPricesServer.PutPricesInTablePart(Data);

	If UsePriceManagementSystem25 Then
		
		Query = New Query(
		"SELECT
		|	TemporaryTableOfGoods_.IndexOf AS IndexOf,
		|	CAST(TemporaryTableOfGoods_.Products AS Catalog.Products) AS Products,
		|	CAST(TemporaryTableOfGoods_.PricingVariant AS Catalog.ItemsCharacteristicsForPricing) AS PricingVariant,
		|	CAST(TemporaryTableOfGoods_.PricingBatch AS Catalog.ItemsBatchesForPricing) AS PricingBatch,
		|	CAST(TemporaryTableOfGoods_.PricingPackage AS Catalog.PackagesAndUnitsOfMeasure) AS PricingPackage
		|INTO TemporaryTableOfGoods_
		|FROM
		|	&Goods AS TemporaryTableOfGoods_
		|
		|INDEX BY
		|	Products,
		|	PricingVariant
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&ProductKind,
		|	TemporaryTableOfGoods_.Products AS Products,
		|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
		|	TemporaryTableOfGoods_.PricingBatch AS PricingBatch,
		|	TemporaryTableOfGoods_.PricingPackage AS PricingPackage,
		|	TemporaryTableOfGoods_.IndexOf
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|");
		
		If Mode = "ByProductNameHierarchyOfProductTypes" Then
			Query.Text = StrReplace(Query.Text, "&ProductKind,", "ItemKinds.Ref AS ProductKind,");
			
			Query.Text = Query.Text + "
			|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
			|		ON TemporaryTableOfGoods_.Products.ProductKind = ItemKinds.Ref
			|ORDER BY
			|	ItemKinds.Description,
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.PricingVariant.Description,
			|	TemporaryTableOfGoods_.PricingBatch.Description,
			|	TemporaryTableOfGoods_.PricingPackage.Description
			|TOTALS
			|	VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) AS PricingVariant,
			|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
			|	MIN(ProductKind),
			|	MIN(IndexOf)
			|BY
			|	Products";
		ElsIf Mode = "HierarchyOfGroupsByProductName" Then

			Query.Text = StrReplace(Query.Text, "&ProductKind,", "");

			Query.Text = Query.Text +
			"ORDER BY
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.PricingVariant.Description,
			|	TemporaryTableOfGoods_.PricingBatch.Description,
			|	TemporaryTableOfGoods_.PricingPackage.Description
			|TOTALS
			|	VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) AS PricingVariant,
			|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
			|	MIN(IndexOf)
			|BY
			|	Products HIERARCHY";
		Else

			Query.Text = StrReplace(Query.Text, "&ProductKind,", "");

			Query.Text = Query.Text +
			"ORDER BY
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.PricingVariant.Description,
			|	TemporaryTableOfGoods_.PricingBatch.Description,
			|	TemporaryTableOfGoods_.PricingPackage.Description
			|TOTALS
			|	VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) AS PricingVariant,
			|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
			|	MIN(IndexOf)
			|BY
			|	Products";
		EndIf;
	
		TableOfGoods = Object.Goods2_5.Unload();
		
	Else
		
		Query = New Query(
		"SELECT
		|	TemporaryTableOfGoods_.IndexOf AS IndexOf,
		|	CAST(TemporaryTableOfGoods_.Products AS Catalog.Products) AS Products,
		|	CAST(TemporaryTableOfGoods_.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic
		|INTO TemporaryTableOfGoods_
		|FROM
		|	&Goods AS TemporaryTableOfGoods_
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&ProductKind,
		|	TemporaryTableOfGoods_.Products AS Products,
		|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
		|	TemporaryTableOfGoods_.IndexOf
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|");
		
		If Mode = "ByProductNameHierarchyOfProductTypes" Then
			Query.Text = StrReplace(Query.Text, "&ProductKind,", "ItemKinds.Ref AS ProductKind,");
			
			Query.Text = Query.Text + "
			|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
			|		ON TemporaryTableOfGoods_.Products.ProductKind = ItemKinds.Ref
			|ORDER BY
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.Characteristic.Description
			|TOTALS 
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|	MIN(ProductKind),
			|	MIN(IndexOf)
			|BY
			|	Products";
		ElsIf Mode = "HierarchyOfGroupsByProductName" Then

			Query.Text = StrReplace(Query.Text, "&ProductKind,", "");

			Query.Text = Query.Text +
			"ORDER BY
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.Characteristic.Description
			|TOTALS 
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|	MIN(IndexOf)
			|BY
			|	Products HIERARCHY";
		Else

			Query.Text = StrReplace(Query.Text, "&ProductKind,", "");

			Query.Text = Query.Text +
			"ORDER BY
			|	TemporaryTableOfGoods_.Products.Description,
			|	TemporaryTableOfGoods_.Characteristic.Description
			|TOTALS 
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|	MIN(IndexOf)
			|BY
			|	Products";
		EndIf;
		
		TableOfGoods = Object.Goods.Unload();
		
	EndIf;
	TMCommonUse.NumberValueTable(TableOfGoods, "IndexOf");
	
	Query.SetParameter("Goods", TableOfGoods);
	Query.SetParameter("Date",   DateForRequestingProductPrices());
	
	IndexOf = 1;
	QueryResult = Query.Execute().Unload();
	For Each TSRow In QueryResult Do
		If Not TSRow["Products"] = Null And Not TSRow["Products"].IsFolder Then
			TreeRow = SettingPricesServer.FindPriceTreeString(ThisObject, TSRow, DataCache);
			TreeRow.SortingAttribute = IndexOf;
			IndexOf = IndexOf + 1;
		EndIf;
	EndDo;
	
	PriceTreeValue = FormAttributeToValue("PriceTree");
	PriceTreeValue.Rows.Sort("SortingAttribute Asc", True);
	ValueToFormAttribute(PriceTreeValue, "PriceTree");
	SettingPricesServer.MarkModifiedFormulas(ThisObject, PriceTreeValue);
	
EndProcedure

&AtClient
Function GetNumberOfRowsOfPriceTree()
	
	ProductItems_ = PriceTree.GetItems();
	Count = ProductItems_.Count();
	
	For Each CurElementProducts In ProductItems_ Do
		
		FeatureElements = CurElementProducts.GetItems();
		NumberOfCharacteristics = FeatureElements.Count();
		Count = Count + NumberOfCharacteristics;
		
	EndDo;

	Return Count

EndFunction // ()

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "RoomWithinADay" Then
		RoomWithinADayOnChange(Item);
	ElsIf Item.Name = "SelectedPricesSelected_5" Then
		SelectedPricesSelected_5OnChange(Item);
	ElsIf Item.Name = "SelectedPricesEdit" Then
		SelectedPricesEditOnChange(Item);
	Else
		If StrFind(Item.Name, "PriceTree" + "PriceKind") > 0
			Or StrFind(Item.Name, "PriceTree" + "ChangePercentage" + "PriceKind") > 0 
			Or StrFind(Item.Name, "PriceTree" + "AmountOfChange" + "PriceKind") > 0 Then
			Attachable_PriceTreePriceWhenChanged(Item);
		ElsIf StrFind(Item.Name, "PriceTree" + "Package" + "PriceKind") > 0 Then
			Attachable_PriceTreePackagingWhenChanging(Item);
		ElsIf StrFind(Item.Name, "PriceTree" + "Products") > 0 Then
			PriceTreeProductsOnChange(Item);
		ElsIf StrFind(Item.Name, "PriceTree" + "Formula" + "PriceKind") > 0 Then
			Attachable_PriceTreeFormulaWhenChanging(Item);
		ElsIf StrFind(Item.Name, "PriceTree" + "Currency" + "PriceKind") > 0 Then
			Attachable_PriceTreeCurrencyWhenChanged(Item);
		ElsIf StrFind(Item.Name, "PriceTree" + "VATRate" + "PriceKind") > 0 Then
			Attachable_PriceTreeVATRateONChange(Item);
		Else
			TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
		EndIf;
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SelectGoods" Then
		SelectGoods(Command);
	ElsIf Command.Name = "AddGoodsByPriceGroup" Then
		AddGoodsByPriceGroup(Command);
	ElsIf Command.Name = "AddGoodsByPicking" Then
		AddGoodsByPicking(Command);
	ElsIf Command.Name = "AddProducts" Then
		AddProducts(Command);
	ElsIf Command.Name = "ImportValidPrices" Then
		ImportValidPrices(Command);
	ElsIf Command.Name = "Calculate" Then
		Calculate(Command);
	ElsIf Command.Name = "ChangePrices" Then
		ChangePricesNewOption(Command);
	ElsIf Command.Name = "ClearAllPriceTypes" Then
		ClearAllPriceTypes(Command);
	ElsIf Command.Name = "SelectAllPriceTypes" Then
		SelectAllPriceTypes(Command);
	ElsIf Command.Name = "SelectAllInfluencingPrices" Then
		SelectAllInfluencingPrices(Command);
	ElsIf Command.Name = "SelectAllDependentPrices" Then
		SelectAllDependentPrices(Command);
	ElsIf Command.Name = "EditSettings" Then
		EditSettings(Command);
	ElsIf Command.Name = "RestoreDefaultSettings" Then
		RestoreDefaultSettings(Command);
	ElsIf Command.Name = "SortByProductNameUsingGroupHierarchy" Then
		SortByProductNameUsingGroupHierarchy(Command);
	ElsIf Command.Name = "SortByProductNameUsingTypeHierarchy" Then
		SortByProductNameUsingTypeHierarchy(Command);
	ElsIf Command.Name = "SortByProductName" Then
		SortByProductName(Command);
	ElsIf Command.Name = "AddGoodsByPriceTypeFilter" Then
		FillInTheProductsForTheSelectionOfPriceTypes(Command);
	ElsIf Command.Name = "ExportToExcel" Then
		ExportToExcel(Command);
	ElsIf Command.Name = "ImportFromExcel" Then
		ImportFromExcel(Command);
	ElsIf Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "ImportDataFromPDT" Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = "DeleteProductsWithoutChangedPrices" Then
		DeleteProductsWithoutChangedPrices(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "PriceTree" Then
		PriceTreeBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	If Item.Name = "PriceTree" Then
		PriceTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(CopiedPriceView)
	
	DescriptionOfMoneyFieldTypes = TMCommonUse.MoneyFieldTypeDescription();
	
	CopiedGoods = New ValueTable;
	CopiedGoods.Columns.Add("Products",           New TypeDescription("CatalogRef.Products"));
	
	If UsePriceManagementSystem25 Then
		CopiedGoods.Columns.Add("PricingVariant",         New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		CopiedGoods.Columns.Add("PricingBatch",                  New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		CopiedGoods.Columns.Add("PricingPackage",               New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		CopiedGoods.Columns.Add("Price",                     DescriptionOfMoneyFieldTypes);
		CopiedGoods.Columns.Add("Package",                 New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Else
		CopiedGoods.Columns.Add("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
		CopiedGoods.Columns.Add("Price",                    DescriptionOfMoneyFieldTypes);
		CopiedGoods.Columns.Add("Package",                New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	EndIf;
	
	For Each CurRow In Items.PriceTree.SelectedRows Do
		
		CurElementProducts = PriceTree.FindByID(CurRow);
		
		PutRowInTablePart(CopiedGoods, CurElementProducts, CopiedPriceView);
		
	EndDo;
	
	ProcessingOfTabularForms.PlaceValueTableOnClipboard(CopiedGoods);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(ToBeFilledInPriceType)
	
	If UsePriceManagementSystem25 Then
		Columns = "Products,Characteristic,PricingVariant,PricingPackage,PricingBatch,Package,Price";
	Else
		Columns = "Products,Characteristic,Package,Price";
	EndIf;
		
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Or TableOfGoods.Columns.Find("Products") = Undefined Then
		Return;
	EndIf;

	If UsePriceManagementSystem25 Then

		ItIsNecessaryToFillInDataBefore = False;
		
		If TableOfGoods.Columns.Find("PricingVariant") = Undefined Then
			ItIsNecessaryToFillInDataBefore = True;
			TableOfGoods.Columns.Add("PricingVariant",   New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));		
		EndIf;

		If TableOfGoods.Columns.Find("PricingBatch") = Undefined Then
			ItIsNecessaryToFillInDataBefore = True;
			TableOfGoods.Columns.Add("PricingBatch",            New TypeDescription("CatalogRef.ItemsBatchesForPricing"));		
		EndIf;

		If TableOfGoods.Columns.Find("PricingPackage") = Undefined Then
			ItIsNecessaryToFillInDataBefore = True;
			TableOfGoods.Columns.Add("PricingPackage",         New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		EndIf;

		If ItIsNecessaryToFillInDataBefore Then
			
			Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
			
			FilterValues = New Structure();
			FilterValues.Insert("ByArrayOfProducts", TableOfGoods.UnloadColumn("Products"));
			If Not TableOfGoods.Columns.Find("Characteristic") = Undefined Then
				FilterValues.Insert("ByArrayOfCharacteristics", TableOfGoods.UnloadColumn("Characteristic"));
			EndIf;
			If Not TableOfGoods.Columns.Find("Series") = Undefined Then
				FilterValues.Insert("BySeriesArray", TableOfGoods.UnloadColumn("Series"));
			EndIf;
		
			Filter_Settings.Insert("FilterValues", FilterValues);
			Filter_Settings.Insert("Date", Object.Date);
			Filter_Settings.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
			Filter_Settings.Insert("UseItemVariants", UseItemVariants);
			Filter_Settings.Insert("UseItemsBatch", UseItemsBatch);
			Filter_Settings.Insert("UseItemPackages", UseItemPackages);
			
			TableOfGoods.Clear();
			SettingPricesServer.GetDataOnProducts(Filter_Settings, TableOfGoods);
				
		EndIf;

	Else
			
		If TableOfGoods.Columns.Find("Characteristic") = Undefined Then
			TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		EndIf;
		
	EndIf;

	If TableOfGoods.Columns.Find("Price") = Undefined Then
		TableOfGoods.Columns.Add("Price", New TypeDescription("Number"));
	EndIf;

	SettingPricesServer.AddGoodsByPicking(ThisObject, Undefined, TableOfGoods, ToBeFilledInPriceType);
	
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

&AtServer
Procedure PutRowInTablePart(PlacedGoods, PriceString, PriceKind)
	
	NewRow                = PlacedGoods.Add();
	NewRow.Products   = PriceString.Products;
	If UsePriceManagementSystem25 Then
		NewRow.PricingVariant 	= PriceString.PricingVariant;
		NewRow.PricingBatch 			= PriceString.PricingBatch;
		NewRow.PricingPackage 			= PriceString.PricingPackage;
	Else
		NewRow.Characteristic 		= PriceString.Characteristic;
	EndIf;
	
	//Column Name = View prices.Column Name;
	ColumnName = "PriceKind" + StrReplace(PriceKind.UUID(), "-", "");

	If PriceString.Property(ColumnName) Then
		NewRow.Price = PriceString[ColumnName];
	EndIf;
	
	If UseItemPackages Then
		
		ColumnNamePackaging = "Package" + ColumnName;
		If PriceString.Property(ColumnName) Then
			NewRow.Package = PriceString[ColumnNamePackaging];
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure UpdateSettingsForPriceTypes(Command)

	If ValueIsFilled(Object.Ref)
		And Not Modified Then

		Notification = New CallbackDescription("UpdateSettingsForPriceTypesFragment", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Sẽ điền lại tùy chỉnh dạng giá! Tiếp tục?';
				|ru = 'Настройки видов цен будут перезаполнены! Продолжить?';
				|en = 'The price type settings will be refilled. Continue?'; fa = 'The price type settings will be refilled. Continue?';
				|it = 'Настройки видов цен будут перезаполнены! Продолжить?';
				|pl = 'The price type settings will be refilled. Continue?';
				|tr = 'Fiyat türü ayarları yeniden doldurulacaktır! Devam edilsin mi?'"),
			QuestionDialogMode.YesNo,,
			DialogReturnCode.No,
			NStr("vi = 'Cập nhật dạng giá';
				|ru = 'Обновление видов цен';
				|en = 'Update price types'; fa = 'Update price types';
				|it = 'Обновление видов цен';
				|pl = 'Update price types';
				|tr = 'Fiyat türlerinin güncellenmesi'"),
		);
	
	Else
		
		UpdateSettingsForPriceTypesFragment(DialogReturnCode.Yes);
		
	EndIf;

EndProcedure

&AtClient
Procedure UpdateSettingsForPriceTypesFragment(Value, AdditionalParameters = Undefined) Export
	
	If Value <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	If Items.SelectedPrices.CurrentData <> Undefined Then
		CurViewPrices = Items.SelectedPrices.CurrentData.Ref;
	Else
		CurViewPrices = Undefined;
	EndIf;

	UpdateSettingsForPriceTypesOnServer();
	SelectedPricesWereChanged = (PriceTree.GetItems().Count() > 0);
	
	If CurViewPrices <> Undefined Then
		
		SearchForCurrentLine = SelectedPrices.FindRows(New Structure("Ref", CurViewPrices));
		If SearchForCurrentLine.Count() > 0 Then
			Items.SelectedPrices.CurrentRow = SearchForCurrentLine.Get(0).GetID();
		EndIf;
		
	EndIf;
	
	Modified = True;
	
	ShowUserNotification(NStr("vi = 'Đã cập nhật tùy chỉnh';
								|ru = 'Настройки обновлены';
								|en = 'Settings are updated'; fa = 'Settings are updated';
								|it = 'Настройки обновлены';
								|pl = 'Settings are updated';
								|tr = 'Ayarlar güncellendi'"),, NStr("vi = 'Đã thực hiện thao tác';
																	|ru = 'Действие выполнено';
																	|en = 'Operation completed.'; fa = 'عملیات تکمیل شد.';
																	|it = 'Operazione effettuata';
																	|pl = 'Działanie zostało wykonane';
																	|tr = 'Eylem tamamlandı'"), PictureLib.Success32);
	
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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Basis.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentBasis");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedPricesPricingMethod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentBasis");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedPrices.SetPriceDuringGeneration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điền theo chứng từ cơ sở';
													|ru = 'Заполнять по документу основанию';
													|en = 'Fill in by the base document'; fa = 'Fill in by the base document';
													|it = 'Compilare in base al documento causale';
													|pl = 'Wypełnić wg dokumentu-podstawy';
													|tr = 'Belge temelinde doldur'"));

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
	                                                                         "PriceTreeCharacteristic",
	                                                                         "PriceTree.ItemVariantsAreUsed");

	//
	// do not show measurements when output when 1 column is used for the price key
	// for the item
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;		
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingVariant");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);
	
	// For the characteristic
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePricingVariant.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);	
	
	// For the Series
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePricingBatch.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedPrices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedPrices.DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedPrices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedPrices.ProhibitedPriceType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'hạn chế truy cập';
													|ru = 'ограничение доступа';
													|en = 'access restriction'; fa = 'access restriction';
													|it = 'limitazione di accesso';
													|pl = 'ograniczenie dostępu';
													|tr = 'erişim kısıtlaması'"));

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	ItemArray.Add("EmployeeResponsible");
	ItemArray.Add("Number");
	ItemArray.Add("Date");
	ItemArray.Add("RoomWithinADay");
	ItemArray.Add("SelectedPrices");
	
	ItemArray.Add("PriceTree;BeforeAddRow,BeforeDeleteRow");
	
	ItemArray.Add("PriceTreeSelectGoods");
	ItemArray.Add("PriceTreeAddGoodsByPriceGroup");
	ItemArray.Add("PriceTreeAddGoodsByPicking");
	ItemArray.Add("PriceTreeAddProducts");
	ItemArray.Add("PriceTreeDownloadOldPrices");
	ItemArray.Add("PriceTreeCalculate");
	ItemArray.Add("PriceTreeRoundUpManualPrices");
	ItemArray.Add("PriceTreeChangePricesByPercentage");
	
	ItemArray.Add("SelectedPricesClearAllPriceTypes");
	ItemArray.Add("SelectedPricesSelectAllPriceTypes");
	ItemArray.Add("SelectedPricesSelectAllInfluencingPrices");
	ItemArray.Add("SelectedPricesSelectAllDependentPrices");
	ItemArray.Add("SelectedPricesEditSettings");
	ItemArray.Add("SelectedPricesRestoreDefaultSettings");
	
	ItemArray.Add("PriceTreeSortByProductNameUsingGroupHierarchy");
	ItemArray.Add("PriceTreeSortByProductNameUsingTypeHierarchy");
	ItemArray.Add("PriceTreeSortByProductName");
	ItemArray.Add("PriceTreeAddGoodsByPriceTypeFilter");
	
	ItemArray.Add("PriceTreeImportFromExcel");
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("PriceTreeDeleteProductsWithoutChangedPrices");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure ReformatPriceTable(RecalculatePrices_)
	SettingPricesServer.ReformatPriceTable(ThisObject, RecalculatePrices_);
EndProcedure

&AtClient
Procedure PriceTreePriceWhenCustomerChanges(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ColumnNamePackaging = StrReplace(Item.Name, "PriceTree" + "PriceKind", "Package" + "PriceKind");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "PriceKind", "NoEditingAllowed" + "PriceKind");
	
	ChangedPercentage = False;
	AmountChanged_ = False;
	ChangePercentage = 0;
	AmountOfChange = 0;
	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	
	If StrFind(CurColumnName, "ChangePercentage" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "ChangePercentage" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = Round(
			CurrentData["OldPrice" + CurColumnName] * ((CurrentData["ChangePercentage"+CurColumnName] / 100) + 1),
			15,
			2);
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];
		ChangedPercentage = True;
		ChangePercentage = CurrentData["ChangePercentage"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind", 
										"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind", 
										"NoEditingAllowed" + "PriceKind");
	EndIf;
	If StrFind(CurColumnName, "AmountOfChange" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "AmountOfChange" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = CurrentData["OldPrice" + CurColumnName] + CurrentData["AmountOfChange" + CurColumnName];
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		AmountChanged_ = True;
		AmountOfChange = CurrentData["AmountOfChange"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind", 
										"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind", 
										"NoEditingAllowed" + "PriceKind");
	EndIf;
	If StrFind(CurColumnName, "Formula" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "Formula" + "PriceKind", "PriceKind");
		
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];		
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		NewFormula = CurrentData["Formula"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "Formula" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind",
										"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "Formula" + "PriceKind", "PriceKind"), 
										"PriceTree" + "PriceKind", 
										"NoEditingAllowed" + "PriceKind");
	EndIf;
	
	If CurrentData[NameOfEditBanColumn] Then
		Return;
	EndIf;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	CurrentData["ChangedManually"       + CurColumnName] = 
							(CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName] <> 0);
	CurrentData["ChangedAutomatically" + CurColumnName] = False;
	
	CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] 
															- CurrentData["OldPrice" + CurColumnName];
	If CurrentData["OldPrice"+CurColumnName] <> 0 Then
		CurrentData["ChangePercentage"+CurColumnName] = Round(
			100 * (CurrentData[CurColumnName] - CurrentData["OldPrice"+CurColumnName]) 
			/ CurrentData["OldPrice" + CurColumnName], 5, 2);
	Else
		CurrentData["ChangePercentage"+CurColumnName] = 0;
	EndIf;
	
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
		
		CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("FillOutProductPackaging");
		CallParameters.ColumnNamePackaging 					= ColumnNamePackaging;
		CallParameters.NameOfEditBanColumn		= NameOfEditBanColumn;
		CallParameters.ArrayOfProductPackagingStructures 	= ArrayOfProductPackagingStructures;
		
		SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
		
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
	
	CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangeDataInPriceTreeRow");
	CallParameters.ColumnNamePackaging 								= ColumnNamePackaging;
	CallParameters.NameOfEditBanColumn 				= NameOfEditBanColumn;
	CallParameters.ComplianceOfFactorsOfPackagesOfProductRange	= ComplianceOfFactorsOfPackagesOfProductRange;
	CallParameters.CurPackingValue							= CurPackingValue;
	CallParameters.CurrentValue 								= CurrentValue;
	CallParameters.SourcePricePackingRatio				= SourcePricePackingRatio;
	CallParameters.CurColumnName								= CurColumnName;
	CallParameters.NewFormula									= NewFormula;
	CallParameters.ChangePercentage								= ChangePercentage;
	CallParameters.AmountOfChange									= AmountOfChange;
	CallParameters.ChangedPercentage									= ChangedPercentage;
	CallParameters.AmountChanged_									= AmountChanged_;
	CallParameters.ChangedFormula									= False;
	CallParameters.Products									= CurrentData.Products;
	CallParameters.UseItemPackages				= UseItemPackages;
	
	SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);

	CalculatePricesByRowIDOnServer(CurrentData.GetID(),CurColumnName);
	
EndProcedure

&AtServer
Procedure UpdateOldProductPricesOnServer()
	SettingPricesServer.UpdateOldProductPrices(ThisObject);
EndProcedure

&AtServerNoContext
Function CoefficientsOfProductPackages(ArrayOfProductPackagingStructures)
	
	Return SettingPricesServer.ComplianceOfCoefficientsOfCollectionOfPackagesOfProductRange(ArrayOfProductPackagingStructures);
		
EndFunction

&AtServer
Procedure ChangePricesToPercentageOnServer(CalculationParameters)
	SettingPricesServer.ChangePricesByPercentage_2(ThisObject, CalculationParameters);
EndProcedure

&AtServer
Procedure AddProductsBySelectionOnServer(AddressInTempStorage)
	
	SettingPricesServer.AddGoodsByPicking(ThisObject, AddressInTempStorage); 
	
EndProcedure

&AtServer
Procedure CalculatePricesOnServer(CalculationParameters)
	SettingPricesServer.CalculatePrices(ThisObject, CalculationParameters);
EndProcedure

&AtServer
Procedure CalculatePricesByRowIDOnServer(RowID, ModifiedField)
	If UsePriceManagementSystem25 Then
		SettingPricesServer.CalculatePricesByRowId2_5(ThisObject, RowID,,ModifiedField);
	Else	
		SettingPricesServer.CalculatePricesByRowId(ThisObject, RowID,,ModifiedField);
	EndIf;	
EndProcedure

&AtServer
Function LoadFromExcelOnServer(Parameter)
	
	Return SettingPricesServer.ImportFromExcel(ThisObject, Parameter.TypesOfPrices, Parameter.Goods);
	
EndFunction

&AtServer
Procedure ChangePricesOnServer(CalculationParameters)
	SettingPricesServer.ChangePrices(ThisObject, CalculationParameters);
EndProcedure

&AtServer
Procedure SetVisibilityOfEditColumns()
	
	For Each CurItem In Items.PriceTree.ChildItems Do
		If StrFind(CurItem.Name, "GroupPrices" + "PriceKind") Then

			For Each NestedItem In CurItem.ChildItems Do
				If StrFind(NestedItem.Name, "TechnicalGroup") Then
					For Each NestedElementByTechnicalGroup In NestedItem.ChildItems Do
						If StrFind(NestedElementByTechnicalGroup.Name, "OldPrice") Then
							NestedElementByTechnicalGroup.Visible = ShowEffectivePrices;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "Formula") Then
							NestedElementByTechnicalGroup.Visible = ShowFormulas;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "ChangePercentage") Then
							NestedElementByTechnicalGroup.Visible = ShowMarkupPercent;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "AmountOfChange") Then
							NestedElementByTechnicalGroup.Visible = ShowPriceChange;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "Currency") Then
							NestedElementByTechnicalGroup.Visible = ShowCurrency;
						EndIf;
					EndDo;
				EndIf;
				
				If StrFind(NestedItem.Name, "PackingGroup") Then
					NestedItem.Visible = ShowUnitsOfMeasurement;
				EndIf;
				
				If StrFind(NestedItem.Name, "VATRate") Then
					NestedItem.Visible = ShowVATRate;
				EndIf;

			EndDo;
		EndIf;
	EndDo;
	
	Items.PriceTreeCharacteristic.Visible 	= Not UsePriceManagementSystem25;
	Items.PriceTreePricingVariant.Visible	= UsePriceManagementSystem25;
	Items.PriceTreePricingBatch.Visible 			= UsePriceManagementSystem25;
	Items.PriceTreePricingPackage.Visible 		= UsePriceManagementSystem25;
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ShowEffectivePrices", 			ShowEffectivePrices);
	StructureOfData.Insert("ShowPriceChange", 			ShowPriceChange);
	StructureOfData.Insert("ShowMarkupPercent", 			ShowMarkupPercent);
	StructureOfData.Insert("ShowFormulas", 					ShowFormulas);
	StructureOfData.Insert("ShowCurrency", 					ShowCurrency);
	StructureOfData.Insert("ShowUnitsOfMeasurement", 			ShowUnitsOfMeasurement);
	StructureOfData.Insert("ShowInfluencingPrices", 				ShowInfluencingPrices);
	StructureOfData.Insert("UseOneColumnForThePriceKey", 	UseOneColumnForThePriceKey);
	StructureOfData.Insert("FixTheItemColumn", 	FixTheItemColumn);
	StructureOfData.Insert("CalculateAutomatically", 			CalculateAutomatically);
	StructureOfData.Insert("ShowVATRate", 				ShowVATRate);
	
	Common.CommonSettingsStorageSave("Document.PriceSetup", "Document.PriceSetup",StructureOfData);
	
EndProcedure

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
Procedure ConfigurePriceKeyColumns()

	If (UseOneColumnForThePriceKey) Then
		Items.PriceTreeGroupItem.Group = ColumnsGroup.InCell;
	Else
		Items.PriceTreeGroupItem.Group = ColumnsGroup.Horizontal;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckPricingVersion(Ref, QuantityOfGoods, QuantityOfGoods25)

	If Not ValueIsFilled(Ref) Then
		Return;
	EndIf;

	PricingIsUsed25Document = Undefined;
	If QuantityOfGoods = 0 And QuantityOfGoods25 <> 0 Then
		PricingIsUsed25Document = True;
	ElsIf QuantityOfGoods <> 0 And QuantityOfGoods25 = 0 Then 
		PricingIsUsed25Document = False;
	EndIf;
	If PricingIsUsed25Document <> Undefined Then
		_25IBPricingIsUsed = PriceManagementSystemServerCall.UsePriceManagementSystem25(CurrentSessionDate());
		If _25IBPricingIsUsed <> PricingIsUsed25Document Then
			MessageText = NStr("vi = 'Phiên bản thiết lập giá của chứng từ khác với phiên bản thiết lập giá trong cơ sở thông tin.
			|Không nên thay đổi chứng từ này, thực hiện sao chép/chèn dòng và dạng giao tiếp khác với các chứng từ khác.';
			|ru = 'Версия ценообразования документа отличается от версии ценообразования, используемой в информационной базе.
			|Не рекомендуется изменять этот документ, выполнять копирование/вставку строк и иные виды взаимодействия с другими документами.';
			|en = 'The pricing version of the document differs from the pricing version used in the infobase.
			|We do not recommend that you edit this document, copy/paste rows, or interact with other documents.'; fa = 'The pricing version of the document differs from the pricing version used in the infobase.
			|We do not recommend that you edit this document, copy/paste rows, or interact with other documents.';
			|it = 'Версия ценообразования документа отличается от версии ценообразования, используемой в информационной базе.
			|Не рекомендуется изменять этот документ, выполнять копирование/вставку строк и иные виды взаимодействия с другими документами.';
			|pl = 'The pricing version of the document differs from the pricing version used in the infobase.
			|We do not recommend that you edit this document, copy/paste rows, or interact with other documents.';
			|tr = 'Belgenin fiyatlandırma versiyonu, infobase''de kullanılan fiyatlandırma versiyonundan farklıdır.
			|Bu belgenin değiştirilmesi, satır kopyalama/yapıştırma ve diğer belgelerle başka etkileşim türlerinin gerçekleştirilmesi önerilmemektedir.'");
			Common.MessageToUser(MessageText, Ref);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Function GetParametersOfPriceEditingForm(TagName)
	
	CurColumnName  = StrReplace(TagName, "PriceTree", "");
	PriceViewFormula	= GetFormulaOfPriceType(TagName);
	
	PriceKind = GetPriceViewByColumnName(CurColumnName);
	
	If PriceKind <> Undefined Then
		InfluencingPrices = PriceKind.InfluencingPrices;
	Else
		InfluencingPrices = New ValueList; 
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("NameOfReturnElement", CurColumnName);
	ReturnStructure.Insert("Formula", 	PriceViewFormula);
	ReturnStructure.Insert("OperandsTree", PutInfluencingKindsOfPricesInStorage(InfluencingPrices));
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá được phép';
												|ru = 'Доступные виды цен';
												|en = 'Available price types'; fa = 'Available price types';
												|it = 'Tipi di prezzi disponibili';
												|pl = 'Dostępne rodzaje cen';
												|tr = 'Mevcut fiyat türleri'"));
	ReturnStructure.Insert("Operators", OperatorsTreeStorageAddress);
	ReturnStructure.Insert("ResultType", New TypeDescription("Number"));
	ReturnStructure.Insert("ThisIsPriceCalculation", True);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function PutInfluencingKindsOfPricesInStorage(InfluencingPrices)
//	 attention upload only selected and not all prices
	Tree = ProcessingOfFormulas.GetEmptyOperandTree();

	For Each Item In InfluencingPrices Do	
		FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("Ref", Item.Value));
		If FoundTypesOfPrices.Count() = 1 Then
			LineTypesOfPrice = FoundTypesOfPrices[0];
			OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
			OperandString_.Id = LineTypesOfPrice.Id;
			OperandString_.Presentation = String(LineTypesOfPrice.Ref);
			OperandString_.DeletionMark = LineTypesOfPrice.DeletionMark;
			OperandString_.ValueType = New TypeDescription("Number");
		EndIf;
	EndDo;
	
	AddressInStorage = PutToTempStorage(Tree, UUID);
	
	Return AddressInStorage;
	
EndFunction

&AtClient
Function GetFormulaOfPriceType(TagName, PriceKind = Undefined)

	PriceViewFormula = "";	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return "";
	EndIf;

	SubstringPosition = StrFind(TagName, "PriceKind");
	ColumnName = Right(TagName, StrLen(TagName) - SubstringPosition + 1);
	
	PriceViewFormula = CurrentData["Formula" + ColumnName];
	StructurePriceGroup = New Structure("PriceGroup", CurrentData.PriceGroup);
	
	If Not ValueIsFilled(PriceViewFormula) Then
		
		If PriceKind = Undefined Then
			
			PriceKind = GetPriceViewByColumnName(TagName);
			
		EndIf;
		
		If Not PriceKind = Undefined Then
			If PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
			
				PriceViewFormula = PriceKind.Formula;
				PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
								
				If PriceGroupsOfAlgorithms.Count() > 0 Then
					PriceViewFormula = PriceGroupsOfAlgorithms[0].Formula;
				EndIf;
						
			ElsIf PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
				
				PriceViewFormula = "[" + PriceKind.BasicPriceType + "]*" + Format(((PriceKind.Markup/100)+1),"NDS=.; NG=0");
				PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
								
				If PriceGroupsOfAlgorithms.Count() > 0 Then
					
					PriceViewFormula = "[" + PriceGroupsOfAlgorithms[0].BasicPriceType + "]*" + Format(((PriceGroupsOfAlgorithms[0].Markup/100)+1),"NDS=.; NG=0");
					
				EndIf;		

			ElsIf PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
			 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice") 
			 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors") 
			 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
			 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost") Then
				
				PriceViewFormula = "[" + PriceKind.Ref + "]*" + Format(((PriceKind.Markup/100)+1),"NDS=.; NG=0");
				PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
								
				If PriceGroupsOfAlgorithms.Count() > 0 Then
					
					PriceViewFormula = "[" + PriceKind.Ref + "]*" + Format(((PriceGroupsOfAlgorithms[0].Markup/100)+1),"NDS=.; NG=0");
					
				EndIf;		

			EndIf;
		EndIf;
		
	EndIf;	
	
	Return PriceViewFormula;
EndFunction

&AtClient
Function GetPriceViewByColumnName(TagName)

	PriceKind = Undefined;	
	
	SubstringPosition = StrFind(TagName, "PriceKind");
	ColumnName = Right(TagName, StrLen(TagName) - SubstringPosition + 1);
	FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
	If FoundTypesOfPrices.Count() = 1 Then
		PriceKind = FoundTypesOfPrices[0];
	EndIf;
	
	Return PriceKind;
	
EndFunction

&AtServer
Procedure MarkModifiedFormulasServer()
	SettingPricesServer.MarkModifiedFormulas(ThisObject);
EndProcedure

&AtServer
Procedure UpdateSettingsForPriceTypesOnServer()
	
	RowsSelected = New Map;
	For Each StringOfPriceTypes In SelectedPrices Do
		
		If StringOfPriceTypes.Selected_5
			Or StringOfPriceTypes.Edit Then
			
			RowsSelected.Insert(StringOfPriceTypes.Ref,
				New Structure("Selected_5, Edit",
				StringOfPriceTypes.Selected_5, StringOfPriceTypes.Edit)
			);
			
		EndIf;
			
	EndDo;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	For Each StringOfPriceTypes In SelectedPrices Do
		
		ColumnValues = RowsSelected.Get(StringOfPriceTypes.Ref);
		If ColumnValues <> Undefined Then
			FillPropertyValues(StringOfPriceTypes, ColumnValues);
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the currency in the price type columns. If necessary, clears prices in columns of price types 
// 
// Parameters:
//  CurrentRow - FormDataTreeItem - Price Tree String
//  ClearingPrice - Boolean - Clearing The Price
&AtServer
Procedure SetCurrenciesOfPriceTypes(CurrentRow, ClearingPrice)
	
	TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
	For Each PriceKind In TypesOfPrices Do
		
		ColumnName         = PriceKind.ColumnName;
		ColumnNamePackaging = "Package" + ColumnName;
		ColumnNameCurrency   = "Currency" + ColumnName;
		
		CurrencyPriceGroups = PriceKind.Currencies.FindRows(New Structure("PriceGroup", CurrentRow.PriceGroup));
		If CurrencyPriceGroups.Count() > 0 Then
			CurrentRow[ColumnNameCurrency] = CurrencyPriceGroups[0].Currency;
		Else
			CurrentRow[ColumnNameCurrency] = PriceKind.Currency;
		EndIf;
		
		If ValueIsFilled(CurrentRow[ColumnName]) And ClearingPrice Then
			CurrentRow[ColumnName] = 0;
		EndIf;
		
		If UseItemPackages And ValueIsFilled(CurrentRow[ColumnNamePackaging]) Then
			CurrentRow[ColumnNamePackaging] = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
		
	EndDo;
EndProcedure

// The price tree VAT rate on changes by the client.
// 
// Parameters:
//  Item - FormItems
&AtClient
Procedure PriceTreeVATRateONChangeCustomer(Item)

	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "VATRate", "NoEditingAllowed");

	CurrentData["ChangedManually" + CurColumnName] = 
			CurrentData[CurColumnName] <> CurrentData["Original" + CurColumnName];
	CurrentData["ChangedAutomatically" + CurColumnName] = False;
	
	CurrentValue   = CurrentData[CurColumnName];
	CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangePersonalIncomeTaxRateInLineOfPriceTree");
	CallParameters.CurrentValue 					= CurrentValue;
	CallParameters.CurColumnName					= CurColumnName;
	CallParameters.NameOfEditBanColumn		= NameOfEditBanColumn;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
	
EndProcedure

#Region FillingInVATRates

&AtClient
Procedure SettingsForFillingInVATRatesEnd(Result, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	If Not ValueIsFilled(Result.SelectedTypesOfPrices) Then
		MessageText = NStr("vi = 'Không có dạng giá được chọn để thay đổi.';
							|ru = 'Нет выбранных видов цен для изменения.';
							|en = 'There are no selected price types to change.'; fa = 'There are no selected price types to change.';
							|it = 'There are no selected price types to change.';
							|pl = 'There are no selected price types to change.';
							|tr = 'Değiştirilecek seçili fiyat türü bulunmamaktadır.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	ChangeVATRatesATServer(Result);
	
EndProcedure

&AtServer
Procedure ChangeVATRatesATServer(CalculationParameters)
	
	SettingPricesServer.ChangeVATRates(ThisObject, CalculationParameters);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Object.Approved Then
		Return;
	EndIf;
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	UnknownBarcodes = AddProductsByBarcodeToPriceTree(ArrayOfBarcodes, CachedValues);
	
	StructureOfActionParameters = New Structure;
	StructureOfActionParameters.Insert("UnknownBarcodes", UnknownBarcodes);
	StructureOfActionParameters.Insert("TransferSpecifiedGoodsToDocument", True);
	
	If StructureOfActionParameters.UnknownBarcodes.Count() > 0 Then
		BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActionParameters, Undefined, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Function AddProductsByBarcodeToPriceTree(BarcodeData_5, CachedValues)
	
	LockFormDataForEdit();
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	WeightBarCodePrefixes		= SettingsValueCached.GetWeightBarCodePrefixes();
	GetBarcodeData		= Not (BarcodeData_5.Count() > 0
										And BarcodeData_5[0].Property("Products"));
	ItemsBarcodes			= New Array;
	PreviouslyUnencashedBarcodes	= New Array;
	UnknownBarcodes			= New Array;
	NonCacheableBarcodes			= New Array;
	BatchBarcodes					= New Array;
	
	For Each CurBarcode In BarcodeData_5 Do
		CurBarcode.Barcode = Upper(TrimAll(CurBarcode.Barcode));
		InformationRegisters.ItemsBarcodes.ConvertWeightBarcode(CurBarcode, WeightBarCodePrefixes);
		
		If GetBarcodeData Then
			If Not ValueIsFilled(CachedValues.Barcodes[CurBarcode.Barcode])
				Or CachedValues.Barcodes[CurBarcode.Barcode].UnknownBarcode Then
				
				PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
				
			EndIf;
		Else
			ItemsBarcodes.Add(CurBarcode);
			PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
		EndIf;
	EndDo;
	
	If PreviouslyUnencashedBarcodes.Count() > 0 Then
		If GetBarcodeData Then
			InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(CachedValues,
																						PreviouslyUnencashedBarcodes);
		Else
			InformationRegisters.ItemsBarcodes.GetDataOnItemBarcodes(CachedValues,
																							ItemsBarcodes);
		EndIf;
	EndIf;
	
	TableOfProducts = SettingPricesServer.CreateProductTable(ThisObject);
	TableOfProducts.Columns.Add("Series",		New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfProducts.Columns.Add("Package",	New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	For Each CurBarcode In BarcodeData_5 Do
		AddedData = CachedValues.Barcodes[CurBarcode.Barcode];
		
		If Not GetBarcodeData
			And (AddedData.NonUniqueBarcode
				Or Not AddedData.ReceivedAccordingToInfobaseData) Then
			
			NonCacheableBarcodes.Add(CurBarcode.Barcode);
			
		EndIf;
		
		If Not AddedData.ItemsBarcode
			And AddedData.ItemsType <> Enums.ItemsTypes.Set Then
			
			BatchBarcodes.Add(CurBarcode.Barcode);
			
		EndIf;
		
		If AddedData.UnknownBarcode Then
			UnknownBarcodes.Add(CurBarcode);
		Else
			NewRow = TableOfProducts.Add();
			FillPropertyValues(NewRow, AddedData);
		EndIf;
	EndDo;
	
	For Each Barcode In NonCacheableBarcodes Do
		CachedValues.Barcodes.Delete(Barcode);
	EndDo;
	
	If BatchBarcodes.Count() > 0 Then
		InformationRegisters.ItemsBarcodes.RegisterBarcodesOfLabelsOfBatchesOfItems(
			BatchBarcodes,
			CachedValues);
	EndIf;
	
	If TableOfProducts.Count() > 0 Then
		If UsePriceManagementSystem25 Then
			Query = New Query;
			Query.Text =
			"SELECT
			|	ProductsTable.Products	AS Products,
			|	ProductsTable.Characteristic	AS Characteristic,
			|	ProductsTable.Series			AS Series,
			|	ProductsTable.Package		AS Package
			|INTO ProductsTable
			|FROM
			|	&ProductsTable AS ProductsTable
			|
			|INDEX BY
			|	Products
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	ProductsTable.Products	AS Products,
			|	ProductsTable.Characteristic	AS Characteristic,
			|	ProductsTable.Series			AS Series,
			|	ProductsTable.Package		AS Package,
			|	CASE
			|		WHEN ProductTypeData.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
			|		ELSE ISNULL(CharacteristicsData.ItemsCharacteristicForPricing, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
			|	END								AS PricingVariant,
			|	CASE
			|		WHEN ProductTypeData.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
			|		ELSE ISNULL(SeriesData_.ItemsBatchForPricing, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef))
			|	END								AS PricingBatch,
			|	CASE
			|		WHEN ProductTypeData.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|				OR ProductData_1.UnitOfMeasure = ProductsTable.Package
			|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|		ELSE ProductsTable.Package
			|	END								AS PricingPackage
			|FROM
			|	ProductsTable AS ProductsTable
			|		INNER JOIN Catalog.Products AS ProductData_1
			|		ON ProductsTable.Products = ProductData_1.Ref
			|		
			|		INNER JOIN Catalog.ItemKinds AS ProductTypeData
			|		ON ProductData_1.ProductKind = ProductTypeData.Ref
			|		
			|		LEFT JOIN Catalog.ItemsCharacteristics AS CharacteristicsData
			|		ON ProductsTable.Characteristic = CharacteristicsData.Ref
			|		
			|		LEFT JOIN Catalog.ItemsBatches AS SeriesData_
			|		ON ProductsTable.Series = SeriesData_.Ref";
			
			Query.SetParameter("ProductsTable", TableOfProducts);
			
			SetPrivilegedMode(True);
			TableForSelection = Query.Execute().Unload();
			SetPrivilegedMode(False);
			
			TableOfProducts = SettingPricesServer.CreateProductTable(ThisObject);
			
			For Each FIlterRow In TableForSelection Do
				NewRow = TableOfProducts.Add();
				FillPropertyValues(NewRow, FIlterRow);
			EndDo;
		EndIf;
		
		SettingPricesServer.AddGoodsByPicking(ThisObject, Undefined, TableOfProducts);
	EndIf;
	
	Return UnknownBarcodes;
	
EndFunction

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangePricesNewOptionOnClientEnds(Result, AdditionalParameters = Undefined) Export
	
	If Result <> Undefined Then
	
		If Result.OptionToChangeThePrice = 1 Then
			ChangePricesByPercentageOnTheClientCompletion(Result, AdditionalParameters);
		ElsIf Result.OptionToChangeThePrice = 2 Or Result.OptionToChangeThePrice = 3 Then
			ChangePricesOnClientEnd(Result, AdditionalParameters) ;
		ElsIf Result.OptionToChangeThePrice = 4 Then
			RoundManualPricesCompletion(Result, AdditionalParameters);
		ElsIf Result.OptionToChangeThePrice = 5 Then
			CalculatePricesOnClientCompletion(Result, AdditionalParameters);
		EndIf;
 	
 	EndIf;
 	
EndProcedure

&AtClient
Procedure CalculatePricesOnClientCompletion(Result, AdditionalParameters = Undefined) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns();
		
		CalculatePricesOnServer(CalculationParameters);
		InfoString = SettingPricesClient.CurLineInformation(
			Items,
			SelectedPrices,
			Object.Date,
			CurrentDate,
			UseItemVariants);
		
	EndIf;

EndProcedure

&AtServer
Function FillInArrayOfCurrenciesByPriceType()
	
	Tree = FormAttributeToValue("PriceTree");
	TableOfCurrenciesByTypeOfPrices = New ValueTable;
	TableOfCurrenciesByTypeOfPrices.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfCurrenciesByTypeOfPrices.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	TableOfCurrenciesByTypeOfPrices = FillTableByTraversingTree(Tree);
	ArrayOfCurrenciesByPriceType = GetArrayOfRowsFromValueTable(TableOfCurrenciesByTypeOfPrices);
	
	Return ArrayOfCurrenciesByPriceType;
EndFunction

&AtServer
Procedure FillArrayByTraversingTree(Tree, CurrencyColumnName, ArrayOfCurrencies)
	
	For Each Page1 In Tree.Rows Do
		If Page1.Rows.Count()>0 Then
			FillArrayByTraversingTree(Page1 ,CurrencyColumnName, ArrayOfCurrencies);
		Else
			LineCurrency = Page1[CurrencyColumnName];
			If ArrayOfCurrencies.Find(LineCurrency)= Undefined Then
				ArrayOfCurrencies.Add(LineCurrency);	
			EndIf;
		EndIf;
	EndDo;
		
EndProcedure

 &AtServer
Function GetArrayOfRowsFromValueTable(ValueTable)
	RowsArray = New Array;
	For Each Page1 In ValueTable Do
		RowsArray.Add(New Structure("PriceKind, Currency",Page1.PriceKind,Page1.Currency));
	EndDo;
	
	Return RowsArray;
	
EndFunction
 
&AtServer
Function FillTableByTraversingTree(Tree)
	
	TableOfCurrenciesByTypeOfPrices = New ValueTable();
	TableOfCurrenciesByTypeOfPrices.Columns.Add("PriceKind");
	TableOfCurrenciesByTypeOfPrices.Columns.Add("Currency");
	
	For Each Column In Tree.Columns Do	
		
		PriceViewCurrencyTable = New ValueTable();
		
		If StrFind(Column.Name, "PriceKind")>0 Then
			SubstringPosition  = StrFind(Column.Name, "PriceKind");	
			If SubstringPosition <> 0 Then
				ColumnName = Right(Column.Name, StrLen(Column.Name) - SubstringPosition + 1);			
			EndIf;
			If ColumnName = Column.Name Then //we remove unnecessary prododes according to formulas and so on
				
				FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
				If FoundTypesOfPrices.Count() > 0 Then
					PriceKind = FoundTypesOfPrices[0].Ref;
					NameOfCurrencyColumnOfPriceType = "Currency" + ColumnName;                       
					ColumnCurrencyArray = Tree.Rows.UnloadColumn(NameOfCurrencyColumnOfPriceType);
					PriceViewCurrencyTable.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
					PriceViewCurrencyTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
					For Indus=1 To ColumnCurrencyArray.Count() Do
						PriceViewCurrencyTable.Add();	
					EndDo;
					PriceViewCurrencyTable.FillValues(PriceKind,"PriceKind");
					PriceViewCurrencyTable.LoadColumn(ColumnCurrencyArray,"Currency");
					PriceViewCurrencyTable.GroupBy("PriceKind,Currency",);
				EndIf;  
				
				For Each Page1 In PriceViewCurrencyTable Do
					RowNew_ = TableOfCurrenciesByTypeOfPrices.Add();
					FillPropertyValues(RowNew_,Page1);
				EndDo;	
			EndIf;	
		EndIf;
		
	EndDo;

	Return TableOfCurrenciesByTypeOfPrices; 
	
EndFunction

#EndRegion

RowAdded = False;

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
