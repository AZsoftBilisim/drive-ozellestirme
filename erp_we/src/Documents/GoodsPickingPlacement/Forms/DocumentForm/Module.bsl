#Region Variables

&AtClient
Var SkipQuestionBeforeRecording; // To work out the recording after the question

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseBinLocationWarehousing = True;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Location);
		
		Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	Else	
		If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
			Items.Pages.CurrentPage = Items.GroupProductsPlacement;
		Else
			Items.Pages.CurrentPage = Items.GroupProductsSelection;
		EndIf;
		
	EndIf;
	
	Items.OperationKind.ReadOnly = ValueIsFilled(Object.Ref)
										  Or ValueIsFilled(Object.ReferenceOrder);
	// You can only select "Placement" or "Move" from the list and only in new documents.
	Items.OperationKind.ListChoiceMode = Not Items.OperationKind.ReadOnly;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsPlacement,ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsFilter,ParametersForFillingInBankingDetails);
	
	RecalculateWeightVolumeInTSLines();
	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	CompletedFactInSelection = Object.GoodsFilter.Count() = 0
		Or Object.GoodsFilter.Total("NumberOfPackagesPicked") <> 0;
	FactFilledInInPlacement = Object.GoodsPlacement.Count() = 0
		Or Object.GoodsPlacement.Total("NumberOfPackagesPlaced") <> 0;
	
	If SkipQuestionBeforeRecording = True
		Or Cancel
		Or Object.Status <> PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors")
		Or CompletedFactInSelection And FactFilledInInPlacement
		Or WriteParameters.WriteMode = DocumentWriteMode.UndoPosting
		Or Not Object.Posted
		Or (Object.OperationKind = PredefinedValue("Enum.OperationKindsOfGoodsPlacementPicking.Move")
			And (CompletedFactInSelection Or FactFilledInInPlacement)) Then
		SkipQuestionBeforeRecording = False;
		Return;
	EndIf;
	
	Cancel = True;
	
	If Not CompletedFactInSelection And Not FactFilledInInPlacement Then
		QueryText = NStr("vi = 'Tại tất cả các dòng của phần bảng ""Hàng hóa (lọc)"" chưa điền số lượng ""Đã lấy ra"", phần bảng hàng hóa ""Hàng hóa (xếp vào)"" - số lượng ""Đã xếp vào"". Vẫn ghi lại chứng từ?';
						|ru = 'Во всех строках табличной части ""Товары (отбор)"" не заполнено количество ""Отобрано"", табличной части ""Товары (размещение)"" - количество ""Размещено"". Все равно записать документ?';
						|en = 'The item quantity in the Picking list and Put-away list tables is not specified. Save anyway?'; fa = 'The item quantity in the Picking list and Put-away list tables is not specified. Save anyway?';
						|it = 'In tutte le righe della parte tabulare ""Merci (selezione)"" non è compilata la quantità ""Selezionato"", della parte tabulare ""Merci (collocamento)"" - la quantità ""Collocato"". Registrare comunque il documento?';
						|pl = 'We wszystkich wierszach części tabelarycznej ""Товары (отбор)"" nie wypełniono ilości ""Отобрано"", części tabelarycznej ""Товары (размещение)"" - ilość ""Размещено"". Mimo wszystko zapisać dokument?';
						|tr = '""Toplama listesi"" tablo bölümünün tüm satırlarında ""Toplanan"" miktarı doldurulmadı, ""Ürünler (yerleştirme)"" tablo bölümü - ""Yerleştirilen"" miktar. Yine de belge kaydedilsin mi?'");
	ElsIf Not CompletedFactInSelection Then
		QueryText = NStr("vi = 'Tại tất cả các dòng của phần bảng ""Hàng hóa (lọc)"" chưa điền số lượng ""Đã lấy ra"". Vẫn ghi lại chứng từ?';
						|ru = 'Во всех строках табличной части ""Товары (отбор)"" не заполнено количество ""Отобрано"". Все равно записать документ?';
						|en = 'The item quantity in the Picking list table is not specified. Save anyway?'; fa = 'The item quantity in the Picking list table is not specified. Save anyway?';
						|it = 'In tutte le righe della parte tabulare ""Merci (selezione)"" non è compilata la quantità ""Selezionato"". Registrare comunque il documento?';
						|pl = 'We wszystkich wierszach części tabelarycznej ""Товары (отбор)"" nie wypełniono ilości ""Отобрано"". Mimo wszystko zapisać dokument?';
						|tr = '""Toplama listesi"" tablo bölümünün tüm satırlarında ""Toplanan"" miktar doldurulmadı. Yine de belge kaydedilsin mi?'");
	ElsIf Not FactFilledInInPlacement Then
		QueryText = NStr("vi = 'Tại tất cả các dòng của phần bảng ""Hàng hóa (xếp vào)"" chưa điền số lượng ""Đã xếp vào"". Vẫn ghi lại chứng từ?';
						|ru = 'Во всех строках табличной части ""Товары (размещение)"" не заполнено количество ""Размещено"". Все равно записать документ?';
						|en = 'The item quantity in the Put-away list table is not specified. Save anyway?'; fa = 'The item quantity in the Put-away list table is not specified. Save anyway?';
						|it = 'In tutte le righe della parte tabulare ""Merci (collocamento)"" non è compilata la quantità ""Collocato"". Registrare comunque il documento?';
						|pl = 'We wszystkich wierszach części tabelarycznej ""Товары (размещение)"" nie wypełniono ilości ""Размещено"". Mimo wszystko zapisać dokument?';
						|tr = '""Ürünler (yerleştirme)"" tablo bölümünün tüm satırlarında ""Yerleştirilen"" miktar doldurulmadı. Yine de  belge kaydedilsin mi?'");
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Write", NStr("vi = 'Ghi lại';
								|ru = 'Записать';
								|en = 'Save'; fa = 'ذخیره';
								|it = 'Salvare';
								|pl = 'Save';
								|tr = 'Kaydet'"));
	Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	ShowQueryBox(New CallbackDescription("BeforeWriteCompletion", ThisObject), QueryText, Buttons);
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(Result, AdditionalParameters) Export
	
	If Result = "Write" Then
		SkipQuestionBeforeRecording = True;
		Write();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_GoodsPickingPlacement", WriteParameters, Object.Ref);
	Items.OperationKind.ReadOnly = True;

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		If Items.Pages.CurrentPage = Items.GroupProductsSelection Then
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Filter, ValueSelected);
		ElsIf Items.Pages.CurrentPage = Items.GroupProductsPlacement Then
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Location, ValueSelected);
		Else
			MessageText = NStr("vi = 'Hãy kích hoạt phần bảng';
								|ru = 'Активируйте табличную часть';
								|en = 'Select a table'; fa = 'Select a table';
								|it = 'Attivare la parte tabulare';
								|pl = 'Aktywuj część tabelaryczną';
								|tr = 'Tablo bölümünü etkinleştir'");
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		If Items.Pages.CurrentPage = Items.GroupProductsSelection Then
			Items.GoodsFilter.CurrentData.Purpose = ValueSelected;
		ElsIf Items.Pages.CurrentPage = Items.GroupProductsPlacement Then
			Items.GoodsPlacement.CurrentData.Purpose = ValueSelected;
	EndIf;

	EndIf;	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationKindOnChange(Item)
	
	SetVisibilityByTypeOfOperation();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseOnChangeServer();
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	PremiseOnChangeServer();
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	StatusOnChangeServer();
EndProcedure

&AtClient
Procedure ExecutionStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.ExecutionStartDate > Object.ExecutionEndDate Then
		Object.ExecutionEndDate = Object.ExecutionStartDate + 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.ExecutionStartDate > Object.ExecutionEndDate Then
		Object.ExecutionStartDate = Object.ExecutionEndDate - 1;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsFilter

&AtClient
Procedure PackageOnChange(Item)
	
	CurrentRow = Items.GoodsFilter.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks","Picked");
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)

	CurrentRow = Items.GoodsFilter.CurrentData;
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure TheNumberOfPackagesCompletedWhenChanging(Item)

	CurrentRow = Items.GoodsFilter.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Picked");
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	Var CurrentRow;
	Var StructureOfActions;

	CurrentRow = Items.GoodsFilter.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
 	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Picked");
	StructureOfActions.Insert("CheckFillAssignment");
 	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.Filter));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsFilterSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("Filter",Item.EditText);
EndProcedure

&AtClient
Procedure GoodsFilterSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.GoodsFilter.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.GoodsFilter.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Filter, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsFilterOnEditEnd(Item, NewRow, CancelEdit)

	AdditionalParameters = New Structure;
	If Item.CurrentItem.Name = "GoodsFilterNumberOfPackages" Then
		AdditionalParameters.Insert("ServerCallRequired__");
	EndIf;
	FormEventsClient.WhenChangingElement(ThisObject, Items.GoodsFilter, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("ProductsAreSelectedAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsPlacement

&AtClient
Procedure GoodsPlacementProductsOnChange(Item)
	Var CurrentRow;
	Var StructureOfActions;
	
	CurrentRow = Items.GoodsPlacement.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
 	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Placed");
	StructureOfActions.Insert("CheckFillAssignment");
	
 	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.Location));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "GoodsPlacement"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPlacementPackageOnChange(Item)
	
	CurrentRow = Items.GoodsPlacement.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks","Placed");
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPlacementNumberOfPackagesOnChange(Item)
	CurrentRow = Items.GoodsPlacement.CurrentData;
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPlacementNumberOfPackagesPlacedOnChange(Item)
	CurrentRow = Items.GoodsPlacement.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Placed");
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPlacementSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("Location",Item.EditText);
EndProcedure

&AtClient
Procedure GoodsPlacementSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.GoodsPlacement.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.GoodsPlacement.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Location, ValueSelected);

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
Procedure GoodsCopyGoodsToPick(Command)
	ClearMessages();
	
	If Object.GoodsFilter.Count() = 0 Then
		MessageText = NStr("vi = 'Chỉ ra hàng hóa để lấy ra';
							|ru = 'Укажите товары к отбору.';
							|en = 'Please specify items to pick.'; fa = 'Please specify items to pick.';
							|it = 'Selezionare le merci da selezionare.';
							|pl = 'Wskaż wiersze pozycji do doboru.';
							|tr = 'Filtre için ürünleri belirt.'");
		
		ShowMessageBox(Undefined, MessageText);
		Return;
		
	EndIf;
	
	If DocumentNotPosted(New CallbackDescription("GoodsCopyGoodsToSelectionAfterInspectionIsCarriedOut", ThisObject)) Then
		GoodsCopyGoodsToSelectionAfterInspectionIsCarriedOut(DialogReturnCode.Yes, New Structure);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCopyGoodsToSelectionAfterInspectionIsCarriedOut(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If CanceledPosting() Then
		If Object.GoodsPlacement.Count() = 0 Then
			CopyProducts("GoodsFilter");
		Else
			QueryText = NStr("vi = 'Trước khi điền, phần bảng ""Hàng hóa (xếp vào)"" sẽ bị xóa. Tiếp tục?';
							|ru = 'Перед заполнением табличная часть ""Товары (размещение)"" будет очищена. Продолжить?';
							|en = 'The Put-away list table will be refilled. Do you want to continue?'; fa = 'The Put-away list table will be refilled. Do you want to continue?';
							|it = 'Prima della compilazione, la parte tabulare ""Merci (collocamento)"" sarà cancellata. Continuare?';
							|pl = 'Przed wypełnieniem części tabelarycznej ""Товары (размещение)"" będzie oczyszczona. Kontynuować?';
							|tr = 'Tablo bölümünü doldurmadan önce ""Ürünler (yerleştirme)"" temizlenecektir. Devam edilsin mi?'");		
		    ShowQueryBox(New CallbackDescription("GoodsCopyGoodsToPickCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCopyGoodsToPickCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		CopyProducts("GoodsFilter");
	EndIf;

EndProcedure

&AtClient
Procedure GoodsSelectStorageBinsForPlacement(Command)
	
	ClearMessages();
	
	If Object.GoodsPlacement.Count() > 0 Then
		If DocumentNotPosted(New CallbackDescription("GoodsToPickUpPlacementCellsAfterCheckIsCarriedOut", ThisObject)) Then
			GoodsToPickUpPlacementCellsAfterCheckIsCarriedOut(DialogReturnCode.Yes, New Structure);
		EndIf;
	Else
		MessageText = NStr("vi = 'Chỉ ra hàng hóa cần phân bổ';
							|ru = 'Укажите товары к размещению.';
							|en = 'Please specify items to put away.'; fa = 'Please specify items to put away.';
							|it = 'Selezionare le merci per il collocamento.';
							|pl = 'Wskaż wiersze pozycji do rozmieszczenia.';
							|tr = 'Yerleştirilecek ürünleri belirt.'");
		ShowMessageBox(Undefined, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToPickUpPlacementCellsAfterCheckIsCarriedOut(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If CanceledPosting() Then
		QueryText = NStr("vi = 'Trong tiến trình chọn, dữ liệu về ô hàng trong phần bảng ""Hàng hóa (xếp vào)"" sẽ được điền lại. Tiếp tục?';
						|ru = 'В ходе подбора данные о ячейках в табличной части ""Товары (размещение)"" будут перезаполнены. Продолжить?';
						|en = 'The storage bin data in the Put-away list table will be updated. Continue?'; fa = 'The storage bin data in the Put-away list table will be updated. Continue?';
						|it = 'Durante la selezione, i dati sulle celle nella parte tabulare ""Merci (collocamento)"" saranno ricompilati. Continuare?';
						|pl = 'W trakcie doboru danych o komórkach w części tabelarycznej ""Товары (размещение)"" będą wypełnione ponownie. Kontynuować?';
						|tr = 'Seçim sırasında, ""Ürünler (yerleştirme)"" tablo bölümündeki hücrelerdeki veriler yeniden doldurulacaktır. Devam edilsin mi?'"); 
		ShowQueryBox(New CallbackDescription("GoodsSelectStorageBinsForPlacementCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelectStorageBinsForPlacementCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		PlaceProductsServer("GoodsPlacement");
	EndIf;

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
Procedure GoodsSelectFilterStorageBins(Command)
	ClearMessages();
	
	If Object.GoodsFilter.Count() > 0 Then
		
		If DocumentNotPosted(New CallbackDescription("GoodsToPickUpSelectionCellsAfterInspectionIsCarriedOut", ThisObject)) Then
			GoodsToPickUpSelectionCellsAfterInspectionIsCarriedOut(DialogReturnCode.Yes, New Structure);
		EndIf;
	Else
		MessageText = NStr("vi = 'Chỉ ra hàng hóa để lấy ra';
							|ru = 'Укажите товары к отбору.';
							|en = 'Please specify items to pick.'; fa = 'Please specify items to pick.';
							|it = 'Selezionare le merci da selezionare.';
							|pl = 'Wskaż wiersze pozycji do doboru.';
							|tr = 'Filtre için ürünleri belirt.'");
		ShowMessageBox(Undefined, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToPickUpSelectionCellsAfterInspectionIsCarriedOut(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If CanceledPosting() Then
		QueryText = NStr("vi = 'Trong tiến trình chọn, dữ liệu về ô hàng trong phần bảng ""Hàng hóa (xếp vào)"" sẽ được điền lại. Tiếp tục?';
						|ru = 'В ходе подбора данные о ячейках в табличной части ""Товары (размещение)"" будут перезаполнены. Продолжить?';
						|en = 'The storage bin data in the Put-away list table will be updated. Continue?'; fa = 'The storage bin data in the Put-away list table will be updated. Continue?';
						|it = 'Durante la selezione, i dati sulle celle nella parte tabulare ""Merci (collocamento)"" saranno ricompilati. Continuare?';
						|pl = 'W trakcie doboru danych o komórkach w części tabelarycznej ""Товары (размещение)"" będą wypełnione ponownie. Kontynuować?';
						|tr = 'Seçim sırasında, ""Ürünler (yerleştirme)"" tablo bölümündeki hücrelerdeki veriler yeniden doldurulacaktır. Devam edilsin mi?'"); 
		ShowQueryBox(New CallbackDescription("GoodsSelectFilterStorageBinsCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelectFilterStorageBinsCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.Yes Then
		PickUpProductsServer("GoodsFilter");
	EndIf;

EndProcedure

&AtClient
Procedure FillInQuantityPlaced(Command)
	
	ClearMessages();
	QueryText = NStr("vi = 'Điền số lượng phân bổ theo số lượng cần xếp vào trong toàn bổ phần bảng ""Hàng hóa (xếp vào)""?';
					|ru = 'Заполнить размещенное количество по количеству к размещению во всей табличной части ""Товары (размещение)""?';
					|en = 'Do you want to autofill the items put away proportionally to the items in the Put-away list table?'; fa = 'Do you want to autofill the items put away proportionally to the items in the Put-away list table?';
					|it = 'Compilare la quantità collocata in base alla quantità al collocamento nell''intera parte tabulare ""Merci (collocamento)""?';
					|pl = 'Wypenić rozmieszczoną ilość według ilości do rozmieszczenia w całej części tabelarycznej ""Товары (размещение)""?';
					|tr = '""Ürünler (yerleştirme)"" tablo bölümünün tamamına yerleştirilecek miktara göre yerleştirilen miktarı doldur?'");
	ShowQueryBox(New CallbackDescription("FillInQuantityPlacedCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure FillInQuantityPlacedCompletion(Result, AdditionalParameters) Export
    
    Response = Result;
    If Response <> DialogReturnCode.Yes Then
        Return;	
    EndIf;
    FillQuantityCompletedClient("GoodsPlacement");

EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInQuantityPicked(Command)
	
	ClearMessages();
	QueryText = NStr("vi = 'Điền số lượng lấy ra theo số lượng cần lấy trong toàn bộ phần bảng ""Hàng hóa (lấy ra)""?';
					|ru = 'Заполнить отобранное количество по количеству к отбору во всей табличной части ""Товары (отбор)""?';
					|en = 'Fill in placed quantity by the quantity to be placed in the entire table ""Picking list""?'; fa = 'Fill in placed quantity by the quantity to be placed in the entire table ""Picking list""?';
					|it = 'Compilare la quantità selezionata in base alla quantità alla selezione nell''intera parte tabulare ""Merci (selezione)""?';
					|pl = 'Wypełnij wybraną ilość według ilości do doboru w całej części tabelarycznej ""Товары (отбор)""?';
					|tr = 'Seçilen miktar, ""Toplama listesi"" tablo bölümünün tamamında seçilecek miktara göre doldur?'");
	Response = Undefined;
	ShowQueryBox(New CallbackDescription("FillInQuantityPickedCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure FillInQuantityPickedCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response <> DialogReturnCode.Yes Then
		Return;	
	EndIf;
	FillQuantityCompletedClient("GoodsFilter");
	
EndProcedure

&AtClient
Procedure FillInStorageBinInAllLinesFilter(Command)
	FormParameters = New Structure("Warehouse,Premise", Object.Warehouse, Object.Premise);
	Cell = Undefined;

	OpenForm("Document.GoodsPickingPlacement.Form.FormToSpecifyStorageBin",FormParameters,ThisForm,,,, New CallbackDescription("FillInStorageBinInAllLinesFilterCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure FillInStorageBinInAllLinesFilterCompletion(Result, AdditionalParameters) Export
    
    Cell = Result;
    
    If ValueIsFilled(Cell) Then
        FillInWHCell("GoodsFilter", Cell);	
    EndIf;

EndProcedure

&AtClient
Procedure FillInTheCellInAllRowsPlacement(Command)
	FormParameters = New Structure("Warehouse,Premise", Object.Warehouse, Object.Premise);
	Cell = Undefined;

	OpenForm("Document.GoodsPickingPlacement.Form.FormToSpecifyStorageBin",FormParameters,ThisForm,,,, New CallbackDescription("FillInTheCellInAllRowsPlacementCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure FillInTheCellInAllRowsPlacementCompletion(Result, AdditionalParameters) Export
    
    Cell = Result;
    
    If ValueIsFilled(Cell) Then
        FillInWHCell("GoodsPlacement", Cell);	
    EndIf;

EndProcedure

&AtClient
Procedure FillInWithStockBalanceInBins(Command)
	
	If DocumentNotPosted(New CallbackDescription("FillInRemainingItemsInCellsAfterVerification", ThisObject)) Then
		FillInRemainingItemsInCellsAfterVerification(DialogReturnCode.Yes, New Structure);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInRemainingItemsInCellsAfterVerification(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.GoodsPlacement.Count() = 0 Then
		FillInRemainingItemsInCellsOpenSelectionForm(DialogReturnCode.Yes, New Structure);
	Else
		QueryText = NStr("vi = 'Trước khi điền, phần bảng ""Hàng hóa (xếp vào)"" sẽ bị xóa. Tiếp tục?';
						|ru = 'Перед заполнением табличная часть ""Товары (размещение)"" будет очищена. Продолжить?';
						|en = 'The Put-away list table will be refilled. Do you want to continue?'; fa = 'The Put-away list table will be refilled. Do you want to continue?';
						|it = 'Prima della compilazione, la parte tabulare ""Merci (collocamento)"" sarà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem części tabelarycznej ""Товары (размещение)"" będzie oczyszczona. Kontynuować?';
						|tr = 'Tablo bölümünü doldurmadan önce ""Ürünler (yerleştirme)"" temizlenecektir. Devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("FillInRemainingItemsInCellsOpenSelectionForm", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInRemainingItemsInCellsOpenSelectionForm(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FormParameters = New Structure("Warehouse,Premise", Object.Warehouse, Object.Premise);
		AddressOfCells = Undefined;
		OpenForm("Document.GoodsPickingPlacement.Form.StorageBinChoiceForm",FormParameters, ThisForm,,,, New CallbackDescription("FillInWithStockBalanceInBinsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure FillInWithStockBalanceInBinsCompletion(Result, AdditionalParameters) Export
    
    AddressOfCells  = Result;
    
    If ValueIsFilled(AddressOfCells) Then
        FillInTSGoodsSelectionByRemainingGoods(AddressOfCells);
    EndIf;

EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "GoodsFilterCharacteristic",
																		     "Object.GoodsFilter.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "GoodsPlacementCharacteristic",
																		     "Object.GoodsPlacement.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods", 
																     "GoodsFilterSeries", 
																     "Object.GoodsFilter.BatchesIndicationStatus",
																	 "Object.GoodsFilter.ItemsType");

	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterSeries.Name);
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 3;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.NumberOfPackagesPicked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods", 
																     "GoodsPlacementSeries", 
																     "Object.GoodsPlacement.BatchesIndicationStatus",
																	 "Object.GoodsPlacement.ItemsType");

	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementSeries.Name);
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 3;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.NumberOfPackagesPlaced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementWeight.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementVolumeM3.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlacementUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsPlacement.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterWeight.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterVolumeM3.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFilterUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsFilter.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsFilterProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.GoodsFilter.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsPlacementProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.GoodsPlacement.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm, 
		"GoodsPlacementPurpose",
		"Object.GoodsPlacement.ItemsType");
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm, 
		"GoodsFilterPurpose",
		"Object.GoodsFilter.ItemsType");
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsPickingPlacement);
	
	SetVisibilityByTypeOfOperation();
	ConfigureByStatus();

	StructureOfSetParameters = New Structure;
	StructureOfSetParameters.Insert("Warehouse",Object.Warehouse);
	
	SetFormFunctionalOptionParameters(StructureOfSetParameters);
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsFilter, ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsPlacement, ParametersForFillingInBankingDetails);
	
	RecalculateWeightVolumeInTSLines();
	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.GoodsFilter);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PremiseOnChangeServer()
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	
	If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
		Object.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Object.Warehouse, Object.Premise);
	ElsIf Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise);
	EndIf;
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsPickingPlacement);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Filter);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Location);
	
	// The start date is filled in when transferring to the status "In progress" (or any subsequent one, if this status was skipped)
	// The end date is filled in when transferring to the status "Completed ...".
	If ValueIsFilled(Object.Status)
		And Object.Status <> Enums.StatusesOfGoodsPickingPlacement.Prepared2 Then
		
		If Not ValueIsFilled(Object.ExecutionStartDate) Then
			Object.ExecutionStartDate = CurrentSessionDate();
		EndIf;
		
		If Object.Status <> Enums.StatusesOfGoodsPickingPlacement.InProgress Then
			
			Object.ExecutionEndDate = CurrentSessionDate();
			
			If Object.ExecutionStartDate > Object.ExecutionEndDate Then
				Object.ExecutionStartDate = Object.ExecutionEndDate - 1;
			EndIf;
			
		ElsIf ValueIsFilled(Object.ExecutionEndDate)
			And Object.ExecutionStartDate > Object.ExecutionEndDate Then
			
			Object.ExecutionEndDate = Object.ExecutionStartDate + 1;
			
		EndIf;
		
	EndIf;
	
	RecalculateWeightVolumeInTSLines();
	
	ConfigureByStatus();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	
	UseWarerooms = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	If Not UseWarerooms Then
		
		If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
			Object.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Object.Warehouse, Object.Premise);
		ElsIf Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
			Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise);
		EndIf;
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsPickingPlacement);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Location);
	
	Items.Premise.Visible = UseWarerooms;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeriesWhenScanningBarcodeOfProductSelection()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.GoodsFilter.FindByID(CurDataId);
	OpenSelectionOfSeries("Filter",,CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesWhenScanningBarcodeOfProduct()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.GoodsPlacement.FindByID(CurDataId);
	OpenSelectionOfSeries("Location",,CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters[TSName],Text, CurrentData) Then
		If CurrentData = Undefined Then
			CurDataId = Items[TSName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, TSName);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
														ThisObject,
														New Structure("TSName,ParametersOfSeriesIndicationForm", TSName,ParametersOfSeriesIndicationForm));

		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisForm,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
		
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
     
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm,AdditionalParameters.TSName, CachedValues);
    EndIf;

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, TSName, CachedValues)
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
																				Object.Warehouse, SeriesSpecificationParameters[TSName]));
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters[TSName],ParametersOfSeriesIndicationForm,Actions,CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters[TSName], CurDataId, ThisForm);
	
EndFunction

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If Items.Pages.CurrentPage = Items.GroupProductsSelection Then
		TSName             = "Filter";
		TabularSectionName = "GoodsFilter";
	ElsIf Items.Pages.CurrentPage = Items.GroupProductsPlacement Then
		TSName             = "Location";
		TabularSectionName = "GoodsPlacement";
	Else
		Return;
	EndIf;

	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		If TSName = "Filter" Then
			Suffix = "Picked";
		Else
			Suffix = "Placed";
		EndIf;
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Suffix);
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithAddedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters[TSName]));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Suffix);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters[TSName];
	StructureOfActions.TSName                                  = TabularSectionName;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		If Lower(TSName) = Lower("Filter") Then
			AttachIdleHandler("OpenSelectionOfSeriesWhenScanningBarcodeOfProductSelection", 0.1, True);
		ElsIf Lower(TSName) = Lower("Location") Then
			AttachIdleHandler("OpenSelectionOfSeriesWhenScanningBarcodeOfProduct", 0.1, True);
		EndIf;
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		ProductFormTable_ = Items[TabularSectionName]; // FormTable
		ProductFormTable_.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActions, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure PlaceProductsServer(SourceName)
	
	CurObject = FormAttributeToValue("Object");
	CurObject.PlaceProducts(SourceName);
	
	ValueToFormAttribute(CurObject, "Object");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsFilter, ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsPlacement, ParametersForFillingInBankingDetails);
	
	RecalculateWeightVolumeInTSLines();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Location);
	
EndProcedure

&AtServer
Procedure PickUpProductsServer(SourceName)
	
	CurObject = FormAttributeToValue("Object");
	CurObject.PickUpProducts(SourceName);
	
	ValueToFormAttribute(CurObject, "Object");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsFilter, ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsPlacement, ParametersForFillingInBankingDetails);
	
	RecalculateWeightVolumeInTSLines();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Location);
	
EndProcedure

&AtClient
Function DocumentNotPosted(CallbackDescription)
	
	If Not Object.Posted Then
		Return True;
	EndIf;
	
	QueryText = NStr("vi = 'Chỉ có thể điền trong chứng từ chưa kết chuyển, hủy bỏ kết chuyển?';
					|ru = 'Заполнение возможно только в непроведенном документе, отменить проведение?';
					|en = 'You can fill in only unposted documents. Undo posting?'; fa = 'You can fill in only unposted documents. Undo posting?';
					|it = 'La compilazione è possibile solo nel documento non registrato, annullare la registrazione?';
					|pl = 'Wypełnienie jest możliwe tylko w niezatwierdzonym dokumencie, anulować zatwierdzenie?';
					|tr = 'Doldurma yalnızca kaydedilmemiş bir belgede mümkündür, kaydetme iptal edilsin mi?'"); 
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	Return False;
	
EndFunction

&AtClient
Function CanceledPosting()
	
	If Not Object.Posted Then
		Return True;
	EndIf;
	
	If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting)) Then
		ShowMessageBox(,NStr("vi = 'Không thể hủy bỏ kết chuyển chứng từ';
							|ru = 'Не удалось отменить проведение документа';
							|en = 'Cannot undo document posting'; fa = 'Cannot undo document posting';
							|it = 'Impossibile annullare la registrazione del documento';
							|pl = 'Nie udało się anulować zatwierdzenie dokumentu';
							|tr = 'Belge kaydetme iptal edilemedi'"));
		Return False;
	EndIf;
	
	Return True;
	
EndFunction
&AtServer
Procedure SetVisibilityByTypeOfOperation()
	If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
		Items.ReceivingArea.Visible 	= False;
		Items.ShippingZone.Visible = True;
		Items.ReferenceOrder.Visible = True;
		
		Items.Pages.CurrentPage         = Items.Pages.ChildItems.GroupProductsSelection;
		Items.GroupProductsSelection.Visible      = True;
		Items.GroupProductsPlacement.Visible = False;
		
		Items.ProductsSelectionProductsGroup.Visible = False;
		
		OrderStatus_ = Common.ObjectAttributeValue(Object.ReferenceOrder, "Status");
		
		If OrderStatus_ <> Enums.GoodsIssueNoteStatuses.ForPicking
			And OrderStatus_ <> Enums.TransferNoteStatuses.ForPicking Then
			Items.ProductsSelectionSelectCells.Enabled = False;
		Else
			Items.ProductsSelectionSelectCells.Enabled = True;
		EndIf;
		
	ElsIf Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		Items.ShippingZone.Visible = False;
		Items.ReceivingArea.Visible 	= True;
		Items.ReferenceOrder.Visible = False;
		
		Items.Pages.CurrentPage         = Items.Pages.ChildItems.GroupProductsPlacement;
		Items.GroupProductsSelection.Visible      = False;
		Items.GroupProductsPlacement.Visible = True;
		
		Items.ProductsPlacementGroupProducts.Visible = False;

	ElsIf Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
		Items.ShippingZone.Visible = False;
		Items.ReceivingArea.Visible 	= False;
		Items.ReferenceOrder.Visible = False;
		
		Items.GroupProductsSelection.Visible      = True;
		Items.GroupProductsPlacement.Visible = True;
		
		Items.ProductsSelectionProductsGroup.Visible      = True;
		Items.ProductsPlacementGroupProducts.Visible = True;
		
	EndIf;
EndProcedure

&AtClient
Procedure FillQuantityCompletedClient(TSName)
	
	If StrFind(TSName,"Filter") <> 0 Then
		NameQuantity 			= "CountPicked";
		NameNumberOfPackages 	= "NumberOfPackagesPicked";
	Else
		NameQuantity 			= "CountPlaced";
		NameNumberOfPackages 	= "NumberOfPackagesPlaced";
	EndIf;
	
	For Each RowOfTables In Object[TSName] Do
		
		RowOfTables[NameQuantity] 			= RowOfTables.Count;
		RowOfTables[NameNumberOfPackages] 	= RowOfTables.NumberOfPackages;
		RowOfTables.Weight						= RowOfTables.NumberOfPackages * RowOfTables.PackageWeight;
		RowOfTables.VolumeM3					= RowOfTables.NumberOfPackages * RowOfTables.PackageVolume;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CopyProducts(SourceName)
	
	ObjectTablePart = Object[SourceName]; // DocumentTabularSection.GoodsPickingPlacement.GoodsFilter, DocumentTabularSection.GoodsPickingPlacement.GoodsPlacement
	TableOfGoods = ObjectTablePart.Unload();
		
	TableOfGoods.GroupBy("Products,Characteristic,Purpose,Package,Series,PackageVolume,
							|PackageWeight,BatchesIndicationStatus,ItemVariantsAreUsed,ItemsType,SKU,
							|Weight,VolumeM3,MeasuredValueType,UnitOfMeasureForVolume,UnitOfMeasureForWeight",
							"Count,NumberOfPackages");
	
	If SourceName = "GoodsPlacement" Then
		Object.GoodsFilter.Load(TableOfGoods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);

	Else
		Object.GoodsPlacement.Load(TableOfGoods);	
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Location);

	EndIf;	
	
EndProcedure

&AtServer
Procedure FillInWHCell(TSName, Cell)
	For Each RowOfTables In Object[TSName] Do
		RowOfTables.Cell = Cell;		
	EndDo;
EndProcedure

&AtServer
Procedure FillInTSGoodsSelectionByRemainingGoods(AddressOfCells)
	CellTable = GetFromTempStorage(AddressOfCells);
	
	QueryText = 
	"SELECT
	|	CellTable.Cell
	|INTO CellTable
	|FROM
	|	&CellTable AS CellTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsInStorageBinsBalance.Products,
	|	GoodsInStorageBinsBalance.Characteristic,
	|	GoodsInStorageBinsBalance.Series,
	|	GoodsInStorageBinsBalance.Cell,
	|	GoodsInStorageBinsBalance.Package,
	|	GoodsInStorageBinsBalance.Purpose AS Purpose,
	|	GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance AS NumberOfPackages,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance
	|		ELSE (GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance) * &QueryTextPackagingFactor
	|	END AS Count
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			,
	|			Cell IN
	|				(SELECT
	|					CellTable.Cell
	|				FROM
	|					CellTable)) AS GoodsInStorageBinsBalance
	|WHERE
	|	GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance > 0
	|
	|ORDER BY
	|	GoodsInStorageBinsBalance.Cell.TabIndex,
	|	GoodsInStorageBinsBalance.Cell.Code,
	|	GoodsInStorageBinsBalance.Products.Description,
	|	GoodsInStorageBinsBalance.Characteristic.Description,
	|	GoodsInStorageBinsBalance.Series.Description,
	|	&QueryTextPackagingFactor DESC,
	|	Purpose";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsInStorageBinsBalance.Package",
		"GoodsInStorageBinsBalance.Products"));
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CellTable", CellTable);
	
	Object.GoodsFilter.Load(Query.Execute().Unload());
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Filter);
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsFilter, ParametersForFillingInBankingDetails);

	RecalculateWeightVolumeInTSLines();
	
EndProcedure

&AtClientAtServerNoContext
Function AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Suffix)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	
EndFunction

&AtServer
Procedure ConfigureByStatus()
	If Object.Status <> Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		Items.GoodsFilterNumberOfPackagesPicked.Visible       = False;
		Items.GoodsFilterNumberOfPackages.Title               = NStr("vi = 'Số lượng';
																	|ru = 'Количество';
																	|en = 'Quantity'; fa = 'مقدار';
																	|it = 'Quantità';
																	|pl = 'Ilość';
																	|tr = 'Miktar'");
		Items.ProductsPlacementToFillInNumberOfSelected.Visible = False;
		
		Items.GoodsPlacementNumberOfPackagesPlaced.Visible = False;
		Items.GoodsPlacementNumberOfPackages.Title = NStr("vi = 'Số lượng';
															|ru = 'Количество';
															|en = 'Quantity'; fa = 'مقدار';
															|it = 'Quantità';
															|pl = 'Ilość';
															|tr = 'Miktar'");
		Items.GoodsPlacementFillInQuantityPlaced.Visible = False;
	Else
		Items.GoodsFilterNumberOfPackagesPicked.Visible       = True;
		Items.GoodsFilterNumberOfPackages.Title               = NStr("vi = 'Cần lấy ra';
																	|ru = 'К отбору';
																	|en = 'Ready for picking'; fa = 'آماده برداشت';
																	|it = 'Da selezionare';
																	|pl = 'Do doboru';
																	|tr = 'Toplamaya hazır'");
		Items.ProductsPlacementToFillInNumberOfSelected.Visible = True;
		
		Items.GoodsPlacementNumberOfPackagesPlaced.Visible = True;
		Items.GoodsPlacementNumberOfPackages.Title = NStr("vi = 'Đến vị trí';
															|ru = 'К размещению';
															|en = 'Quantity for put-away'; fa = 'Quantity for put-away';
															|it = 'Da collocare';
															|pl = 'Do rozmieszczenia';
															|tr = 'Yerleştirilecek'");
		Items.GoodsPlacementFillInQuantityPlaced.Visible = True;
	EndIf;
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

&AtClient
Procedure GoodsFilterWeightOnChange(Item)

	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight",Suffix);
	
	CurrentRow = Items.GoodsFilter.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsFilterVolumeM3OnChange(Item)

	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume",Suffix);
	
	CurrentRow = Items.GoodsFilter.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPlacementWeightOnChange(Item)
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight",Suffix);
	
	CurrentRow = Items.GoodsPlacement.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPlacementVolumeM3OnChange(Item)
	
	If Object.Status = PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors") Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume", Suffix);
	
	CurrentRow = Items.GoodsPlacement.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtServer
Procedure RecalculateWeightVolumeInTSLines()

	If Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		Suffix = "Picked";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.GoodsFilter, StructureOfActions);
	
	If Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		Suffix = "Placed";
	Else
		Suffix = "";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume", Suffix);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.GoodsPlacement, StructureOfActions);
	
EndProcedure

&AtClient
Procedure ProductsAreSelectedAtEndOfEditingForServerCall()

	ProductsAreSelectedAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure ProductsAreSelectedAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "GoodsFilter");
	
EndProcedure

&AtClient
Procedure GoodsFilterOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.GoodsFilter, ThisObject);
	
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
	If Item.Name = "sh_ShamsiInput_ExecutionStartDate" Then
		ExecutionStartDateOnChange(Items.ExecutionStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_ExecutionEndDate" Then
		ExecutionEndDateOnChange(Items.ExecutionEndDate);
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
