#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InitializeSettingsComposer();
	
	FiltersStructure = Undefined;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("Products", FilterRemainingGoodsByShelfLives) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Products", FilterRemainingGoodsByShelfLives);
		EndIf;
		
		If FiltersStructure.Property("BillOfMaterials", FilterByBillOfMaterials) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "BillOfMaterials", FilterByBillOfMaterials);
		EndIf;
		
		If FiltersStructure.Property("ProductionOrder", FilterByOrder) Then
			ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductionOrder", FilterByOrder);
		EndIf;
		
		SelectionStructureIsFilledInAccordingToPassedParameters = True;
		
	EndIf;
	
	RestoreSettings();
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	UseAlternativeMaterials = GetFunctionalOption("UseAlternativeMaterials");
	UsePlanningIntervalHour = Constants.UsePlanningIntervalHour.Get();
	
	DataOfActiveLine = New Structure;
	DataOfActiveLine.Insert("MinimumReleaseLot", 0);
	DataOfActiveLine.Insert("EconomicReleaseLot", 0);
	DataOfActiveLine.Insert("ThereIsSideIssue", False);
	DataOfActiveLine.Insert("SideIssueNumberOfProducts", 0);
	DataOfActiveLine.Insert("SideIssueProductPresentation", "");
	
	SelectedModeColor = StyleColors.GrayTextColor1;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	SemiFinishedProductsAreProducedSeparately = GetFunctionalOption("ManufactureSemiFinishedProductsIncludedInOrderSeparately");
	
	If SemiFinishedProductsAreProducedSeparately Then
		SeparateProductionOfSemiFinishedProducts = True; // semi-finished products within the order are always produced separately
		DocumentCreationOptions.SeparateProductionOfSemiFinishedProducts = True;
	EndIf;
	
	CustomizeFormElements();
	
	AddressPlanStorage = PutToTempStorage(Undefined, UUID);
	AddressCustomSelections = PutToTempStorage(Undefined, UUID);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		
		Items.SelectionPages.CurrentPage = Items.PageSimpleFilters;
		
	Else
		
		Items.SelectionPages.CurrentPage = Items.PageRandomFilters;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Mark", True);
	TheStructureOfTheSearch.Insert("Launch", 0);
	
	For Each String In Object.PlanResults.FindRows(TheStructureOfTheSearch) Do
		
		MessageText = CommonClientServer.FillingErrorText(
			"Column", "FillType", NStr("vi = 'Cần khởi động';
										|ru = 'К запуску';
										|en = 'Launch'; fa = 'راه‌اندازی';
										|it = 'In avvio';
										|pl = 'Do uruchomienia';
										|tr = 'Başlatılacak'"), String.LineNumber, NStr("vi = 'Sản phẩm';
																				|ru = 'Изделия';
																				|en = 'Products'; fa = 'کالاها';
																				|it = 'Produzione';
																				|pl = 'Wyroby';
																				|tr = 'Nihai ürünler'"));
		
		Field = CommonClientServer.PathToTabularSection(
			"Object.PlanResults", String.LineNumber, "Launch");
		
		Common.MessageToUser(MessageText,, Field,, Cancel);
		
	EndDo;
	
	//
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Mark", True);
	TheStructureOfTheSearch.Insert("BillOfMaterials", Catalogs.BillsOfMaterials.EmptyRef());
	
	For Each String In Object.PlanResults.FindRows(TheStructureOfTheSearch) Do
		
		MessageText = CommonClientServer.FillingErrorText(
			"Column", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
										|ru = 'Спецификация';
										|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
										|it = 'Спецификация';
										|pl = 'Bill of materials';
										|tr = 'Ürün reçetesi'"), String.LineNumber, NStr("vi = 'Sản phẩm';
																							|ru = 'Изделия';
																							|en = 'Products'; fa = 'کالاها';
																							|it = 'Produzione';
																							|pl = 'Wyroby';
																							|tr = 'Nihai ürünler'"));
		
		Field = CommonClientServer.PathToTabularSection(
			"Object.PlanResults", String.LineNumber, "BillOfMaterials");
		
		Common.MessageToUser(MessageText,, Field,, Cancel);
		
	EndDo;
	
	//
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("EarliestStartDate", '00010101');
	
	ProductTreeForPreview = FormAttributeToValue("ProductsToPreview");
	FoundRows = ProductTreeForPreview.Rows.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		MessageText = NStr("vi = 'Chưa điền cột ""Bắt đầu không sớm hơn"" trong dòng danh sách ""Xem trước""';
							|ru = 'Не заполнена колонка ""Начать не ранее"" в строке списка ""Предварительный просмотр""';
							|en = 'The ""Earliest start date"" column is not populated in the ""Preview"" list line.'; fa = 'The ""Earliest start date"" column is not populated in the ""Preview"" list line.';
							|it = 'Не заполнена колонка ""Начать не ранее"" в строке списка ""Предварительный просмотр""';
							|pl = 'The ""Earliest start date"" column is not populated in the ""Preview"" list line.';
							|tr = '""Önizleme"" listesi satırında ""En erken başlangıç tarihi"" sütunu doldurulmamış'");
		Common.MessageToUser(MessageText,, "ProductsToPreview",, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	If FormattedStringURL = "FillInNomenclaturePlan" Then
		
		StandardProcessing = False;
		
		FillInNomenclaturePlanOnServer();
		If StartAwaitingLongAction Then
			StartAwaitingLongAction();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region StepSelection

&AtClient
Procedure ToUseARandomSelectionClick(Item)
	
	Items.SelectionPages.CurrentPage = Items.PageRandomFilters;
	
EndProcedure

&AtClient
Procedure TheUseOfSimpleSelectionsClick(Item)

	If ReflectLayoutSelectionInSimpleSelections() Then
		
		Items.SelectionPages.CurrentPage = Items.PageSimpleFilters;
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể chuyển bộ lọc đã đặt sang dạng lọc đơn giản.';
										|ru = 'Установленные отборы невозможно преобразовать к виду простых отборов.';
										|en = 'Cannot convert the set filters into simple filters.'; fa = 'Cannot convert the set filters into simple filters.';
										|it = 'Le selezioni impostate non possono essere convertite nel tipo di selezioni semplici.';
										|pl = 'Zainstalowanych wyborów nie można konwertować do postaci prostych wyborów.';
										|tr = 'Yapılandırılan filtreler, basit filtrelere dönüştürülemez.'"));
	EndIf;

EndProcedure

&AtClient
Procedure SettingsComposerUserSettingsOnEditEnd(Item, NewRow, CancelEdit)

	ShouldSaveSettings = True;
	
EndProcedure

&AtClient
Procedure SelectionByDivisionDispatcherOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductionDispatcherBusinessUnit", SelectionByDivisionDispatcher);

EndProcedure

&AtClient
Procedure FilterByLineOfBusinessOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "LineOfBusiness", FilterByLineOfBusiness);

EndProcedure

&AtClient
Procedure FilterByOrderOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ProductionOrder", FilterByOrder);

EndProcedure

&AtClient
Procedure FilterByAssignmentOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Purpose", FilterByAssignment);

EndProcedure

&AtClient
Procedure FilterByWarehouseOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Warehouse", FilterByWarehouse);

EndProcedure

&AtClient
Procedure FilterRemainingGoodsByShelfLivesOnChange(Item)

	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "Products", FilterRemainingGoodsByShelfLives);

EndProcedure

&AtClient
Procedure FilterByBillOfMaterialsOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "BillOfMaterials", FilterByBillOfMaterials);
	
EndProcedure

&AtClient
Procedure SelectionByResponsibleDivisionOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(SettingsComposer, "ResponsibleBusinessUnit", SelectionByResponsibleDivision);
	
EndProcedure

&AtClient
Procedure PeriodVariantOnChange(Item)
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(
		SettingsComposer,
		"StartDate2",
		?(PeriodVariant = 0 And ValueIsFilled(SelectionByDate_1), EndOfDay(SelectionByDate_1), Undefined));
	
	ReflectSimpleSelectionInLayoutSelections(
		SettingsComposer,
		"DateOfProduction",
		?(PeriodVariant = 1 And ValueIsFilled(SelectionByDate_1), EndOfDay(SelectionByDate_1), Undefined));
	
EndProcedure

&AtClient
Procedure SelectionByDate_1OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShouldSaveSettings = True;
	
	ReflectSimpleSelectionInLayoutSelections(
		SettingsComposer,
		?(PeriodVariant = 0, "StartDate2", "DateOfProduction"),
		?(ValueIsFilled(SelectionByDate_1), EndOfDay(SelectionByDate_1), Undefined));
	
EndProcedure

#EndRegion

#Region StepPlan

&AtClient
Procedure PlanSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name, "Plan", "");
	
	If StrFind("Recipient,Purpose", FieldName) > 0 Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData[FieldName]);
	ElsIf FieldName = "ProductionOrderPresentation" Or FieldName = "ProductionOrder" Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData.ProductionOrder);
	ElsIf FieldName = "AvailableReleaseFromAssignedmMaterials" Then
		StandardProcessing = False;
		ShowMessageBox(, TextOfWarningFreeReleaseFromSeparateMaterials());
	ElsIf FieldName = "UnderRepairProduct"
		And Not Item.CurrentData.UnderRepairProduct.IsEmpty() Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData.UnderRepairProduct);
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanOnActivateRow(Item)
	
	Items.PlanContextMenuShowProductInOrderStructure.Enabled =
		Items.Plan.CurrentData <> Undefined;
	
EndProcedure

&AtClient
Procedure Show_DetailsClick(Item)
	
	Show_Details = Not Show_Details;
	UpdatePlanWhenLineIsActivated();
	ConfigureDependentFormElements(ThisForm, "Show_Details");
	
EndProcedure

&AtClient
Procedure PlanResultsSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name, "PlanResults", "");
	
	If StrFind("Products,Characteristic,Organization,Partner,Contract,LineOfBusiness", FieldName) > 0 Then
		
		StandardProcessing = False;
		
		ShowValue(, Item.CurrentData[FieldName]);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanResultsOnActivateRow(Item)
	
	AttachIdleHandler("PlanTotalsWhenActivatingDelayedLine", 0.1, True);
	
EndProcedure

&AtClient
Procedure PlanResultsMarkFormOnChange(Item)
	
	If Items.PlanResults.CurrentData.MarkForm = 2 Then
		Items.PlanResults.CurrentData.MarkForm = 0;
	EndIf;
	Items.PlanResults.CurrentData.Mark = Boolean(Items.PlanResults.CurrentData.MarkForm);
	Items.PlanResults.CurrentData.AutoRecalculation = False;
	
	PlanResultsWhenChanging();
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure PlanResultsLaunchOnChange(Item)
	
	Items.PlanResults.CurrentData.Mark = Items.PlanResults.CurrentData.Launch > 0;
	Items.PlanResults.CurrentData.MarkForm = ?(Items.PlanResults.CurrentData.Mark, 1, 0);
	Items.PlanResults.CurrentData.AutoRecalculation = False;
	
	PlanResultsWhenChanging();
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure PlanResultsLaunchOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductAddress = UnloadProductsOnCurLine(
		LinePlanTotalsInStructure(Items.PlanResults.CurrentData),
		AddressPlanStorage,
		AddressCustomSelections,
		SeparateProductionOfSemiFinishedProducts);
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductAddress", ProductAddress);
	FormParameters.Insert("Products", Items.PlanResults.CurrentData.Products);
	FormParameters.Insert("Characteristic", Items.PlanResults.CurrentData.Characteristic);
	FormParameters.Insert("Route", Items.PlanResults.CurrentData.Route);
	FormParameters.Insert("IssueIsSeparatedByDefault", SeparateProductionOfSemiFinishedProducts);
	
	OpenForm("DataProcessor.GeneratingProductionStages.Form.SelectProductsToLaunch",
		FormParameters,
		ThisForm,,,,
		New CallbackDescription("SelectProductsToLaunchCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PlanResultsBillOfMaterialsOnChange(Item)
	
	CurrentData = Items.PlanResults.CurrentData;
	CurrentData.BillOfMaterialsHasBeenChanged = (CurrentData.BillOfMaterials <> CurrentData.BillOfMaterialsPlan);
	
	RowData = LinePlanTotalsInStructure(CurrentData);
	
	If CurrentData.MultipleLaunch Then
		InformationRecords = PlanResultsBillOfMaterialsWhenContextChangesOnServer(RowData);
	Else
		InformationRecords = PlanResultsBillOfMaterialsWhenChangedOnServer(
			RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, Show_Details);
	EndIf;
	
	If Show_Details Then
		Object.Plan.Clear();
		For IndexOf = 0 To InformationRecords.DetailedRecords.UBound() Do
			FillPropertyValues(Object.Plan.Add(), InformationRecords.DetailedRecords[IndexOf]);
		EndDo;
	EndIf;
	
	FillPropertyValues(DataOfActiveLine, InformationRecords,
		"MinimumReleaseLot, EconomicReleaseLot, ThereIsSideIssue, SideIssueNumberOfProducts, SideIssueProductPresentation");
	
	FillPropertyValues(CurrentData, RowData,
		"PlanIsInVault, QuantityPerBatch, MainProduct");
	
	CurrentData.ThereIsOptimalLotReference = InformationRecords.EconomicReleaseLot <> 0;
	
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure InformationBarURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	DecipherPositionOfNomenclaturePlan(Undefined);
	
EndProcedure

#EndRegion

#Region StageGenerationSettings

&AtClient
Procedure ParametersForCreatingDocumentsHyperlink(Item)

	CallbackDescription = New CallbackDescription("AfterSelectingDocumentCreationOptionsInSelectionEndStep", ThisObject); 
	
	FormOpenParameters = New Structure();
	FormOpenParameters.Insert("DocumentCreationOptions", DocumentCreationOptions); 
	FormOpenParameters.Insert("SemiFinishedProductsAreProducedSeparately", SemiFinishedProductsAreProducedSeparately);
	FormOpenParameters.Insert("UseAlternativeMaterials", UseAlternativeMaterials);
	
	OpenForm(
		"DataProcessor.GeneratingProductionStages.Form.DocumentCreationOptions",
		FormOpenParameters,
		ThisForm,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure AfterSelectingDocumentCreationOptionsInSelectionEndStep(Result, AdditionalParameters) Export
	
	If Result = Undefined Then 
		Return;
	EndIf;

	FillPropertyValues(DocumentCreationOptions, Result);
	SeparateProductionOfSemiFinishedProducts = Result.SeparateProductionOfSemiFinishedProducts;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersProductsToPreview

&AtClient
Procedure ProductsToPreviewEarliestStartDateOnChange(Item)
	
	CurrentData = Items.ProductsToPreview.CurrentData;
	CurrentData.LineChanged = True;
	FinishedProductsForPreviewHaveBeenChanged = True;
	
EndProcedure

&AtClient
Procedure ProductsToPreviewSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name, "ProductsToPreview", "");
	
	If FieldName = "AvailableReleaseFromAssignedmMaterials" Then
		StandardProcessing = False;
		ShowMessageBox(, TextOfWarningFreeReleaseFromSeparateMaterials());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersResultOfFormation

&AtClient
Procedure ResultOfFormationSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.ResultOfFormation.CurrentData;
	
	If ValueIsFilled(CurrentData.Ref) Then
		ShowValue(, CurrentData.Ref);
	Else
		ProductionManagementClient.OpenStageChainEditingForm(
			CurrentData.ReferenceOrder,
			CurrentData.Lot);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Filters

&AtClient
Procedure RestoreDefaultSettings(Command)
	
	LoadDefaultSelectionSettings();
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		
		Items.SelectionPages.CurrentPage = Items.PageSimpleFilters;
		
	Else
		
		Items.SelectionPages.CurrentPage = Items.PageRandomFilters;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ItemPlan

&AtClient
Procedure SelectItemPlanCheckBoxes(Command)
	
	ChangeMarksInSelectedLines(True, Items.PlanResults.SelectedRows);
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure UncheckItemPlanCheckboxes(Command)
	
	ChangeMarksInSelectedLines(False, Items.PlanResults.SelectedRows);
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure FillInForLaunchAccordingToProvidedQuantity(Command)
	
	FillInForLaunchInSelectedLines("Supplied", Items.PlanResults.SelectedRows);
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure FillInForLaunchAsNeeded(Command)
	
	FillInForLaunchInSelectedLines("Required2", Items.PlanResults.SelectedRows);
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure OnlyCheckedOnChange(Item)
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);

EndProcedure

&AtClient
Procedure HyperlinkAllProductsClick(Item)
	
	FilterProvidesCurValue = SoftwareFilterIsDisabled();
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "FilterSoftware");
	
EndProcedure

&AtClient
Procedure HyperlinkProvidedClick(Item)
	
	FilterProvidesCurValue = FilterSecurityIsProvided();
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "FilterSoftware");
	
EndProcedure

&AtClient
Procedure HyperlinkNotProvidedClick(Item)
	
	FilterProvidesCurValue = NoSoftwareIsProvided();
	
	SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "FilterSoftware");
	
EndProcedure

&AtClient
Procedure ReReadNomenclaturePlan(Command)
	
	ReReadNomenclaturePlanOnServer();
	If StartAwaitingLongAction Then
		StartAwaitingLongAction();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecipherPositionOfNomenclaturePlan(Command)
	
	CurrentData = Items.PlanResults.CurrentData;
	If CurrentData = Undefined Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn dòng kế hoạch';
										|ru = 'Не выбрана строка плана';
										|en = 'The plan line is not selected'; fa = 'The plan line is not selected';
										|it = 'Non è stata selezionata la riga del piano';
										|pl = 'Nie wybrano wiersza planu';
										|tr = 'Plan satırı seçilmedi'"));
		Return;
	EndIf;
	
	FormParameters = DetailsParameters(
		LinePlanTotalsInStructure(Items.PlanResults.CurrentData),
		AddressPlanStorage,
		AddressCustomSelections,
		SeparateProductionOfSemiFinishedProducts);
	
	OpenForm(
		"Report.ItemPlanItemDrillDown.Form",
		FormParameters,
		ThisForm,
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ShowProductInOrderStructure(Command)
	
	CurrentData = Items.Plan.CurrentData;
	If CurrentData = Undefined Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn dòng kế hoạch';
										|ru = 'Не выбрана строка плана';
										|en = 'The plan line is not selected'; fa = 'The plan line is not selected';
										|it = 'Non è stata selezionata la riga del piano';
										|pl = 'Nie wybrano wiersza planu';
										|tr = 'Plan satırı seçilmedi'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("OrderDocument", CurrentData.ProductionOrder);
	FormParameters.Insert("Products", CurrentData.Products);
	FormParameters.Insert("KeyProducts", CurrentData.KeyProducts);
	
	OpenForm(
		"Report.ProductionOrderStructureDynamic.Form.ReportForm",
		FormParameters,
		ThisForm,
		UUID);
	
EndProcedure

&AtClient
Procedure ShowSettings(Command)
	
	OpenForm(
		"DataProcessor.GeneratingProductionStages.Form.FormSettings",
		DisplayParameters,
		ThisForm,,,,
		New CallbackDescription("ShowSettingsCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Steps

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If Items.WizardPages.CurrentPage = Items.StepSelection Then
	
		GoToNomenclaturePlanStepOnClient();
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan Then
		
		If DisplayParameters.Preview Then
			GoToPreviewStepOnClient();
		Else
			GoToGenerationResultStepOnClient();
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepPreview Then
		
		GoToGenerationResultStepOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)

	ClearMessages();

	If Items.WizardPages.CurrentPage = Items.StepResultOfFormation Then
		
		CallbackDescription = New CallbackDescription("ConsentToDeletionOfDocumentsEnd", ThisObject);
		QueryText = NStr("vi = 'Khi quay trở lại, các chứng từ được tạo sẽ bị xóa.
			|Tiếp tục?';
			|ru = 'При переходе назад сформированные документы будут удалены.
			|Продолжить?';
			|en = 'When going back, the generated documents will be deleted.
			|Continue?'; fa = 'When going back, the generated documents will be deleted.
			|Continue?';
			|it = 'When going back, the generated documents will be deleted.
			|Continue?';
			|pl = 'When going back, the generated documents will be deleted.
			|Continue?';
			|tr = 'Geri dönüldüğünde oluşturulan belgeler silinecektir. 
			| Devam edilsin mi?'");
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes);
		Buttons.Add(DialogReturnCode.Cancel);
		
		ShowQueryBox(CallbackDescription, QueryText, Buttons,, DialogReturnCode.Cancel);
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepPreview Then
		
		ProductsToPreview.GetItems().Clear();
		GoBackToNomenclaturePlanStepOnClient();
		
	ElsIf Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan Then
		
		GoBackToSelectionsStepOnClient();

	ElsIf Items.WizardPages.CurrentPage = Items.StepSelection Then
	
		Return;
		
	EndIf;

EndProcedure

&AtClient
Procedure ContinueWithOtherFilters(Command)
	
	ClearMessages();
	ContinueWithOtherSelectionsOnServer();

EndProcedure

#EndRegion

#Region GeneratedDocuments

&AtClient
Procedure StageDispatching(Command)
	
	CurrentData = Items.ResultOfFormation.CurrentData;
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn lô hàng (chứng từ)';
										|ru = 'Не выбрана партия (документ)';
										|en = 'The lot (document) is not selected'; fa = 'The lot (document) is not selected';
										|it = 'Non è stato selezionato il lotto (documento)';
										|pl = 'Nie wybrano partii (dokumentu)';
										|tr = 'Lot (belge) seçilmedi'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FiltersStructure", New Structure("ReferenceOrder", CurrentData.ReferenceOrder));
	
	OpenForm(
		"Document.ProductionStage2_2.Form.ProductionStageDispatching",
		FormParameters,,
		CurrentData.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure OrderStructure(Command)
	
	CurrentData = Items.ResultOfFormation.CurrentData;
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn lô hàng (chứng từ)';
										|ru = 'Не выбрана партия (документ)';
										|en = 'The lot (document) is not selected'; fa = 'The lot (document) is not selected';
										|it = 'Non è stato selezionato il latto (documento)';
										|pl = 'Nie wybrano partii (dokumentu)';
										|tr = 'Lot (belge) seçilmedi'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("OrderDocument", CurrentData.ReferenceOrder);
	FormParameters.Insert("Products", CurrentData.Products);
	
	OpenForm(
		"Report.ProductionOrderStructureDynamic.Form.ReportForm",
		FormParameters,,
		CurrentData.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure ProductionBatchMaintenanceSheet(Command)
	
	ArrayOfStages = CreatedStages();
	
	If ArrayOfStages.UBound() = -1 Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Không có dữ liệu để in';
										|ru = 'Отсутствуют данные для печати';
										|en = 'Data to print is missing'; fa = 'Data to print is missing';
										|it = 'Dati di stampa assenti';
										|pl = 'Brak danych do drukowania';
										|tr = 'Yazdırılacak veri bulunmamaktadır'"));
	Else
		CommandDetails = New Structure("PrintObjects, Form", ArrayOfStages, ThisObject);
		PrintManagementERPClient.PrintingProductionBatchSheets(CommandDetails);
	EndIf;
	
EndProcedure

&AtServer
Function CreatedStages()
	
	ArrayOfStages = New Array;
	
	For Each StringBatch In ResultOfFormation.GetItems() Do
		For Each LineDocument In StringBatch.GetItems() Do
			If TypeOf(LineDocument.Ref) = Type("DocumentRef.ProductionStage2_2") Then
				ArrayOfStages.Add(LineDocument.Ref);
			EndIf;
		EndDo;
	EndDo;
	
	Return ArrayOfStages;
	
EndFunction

&AtClient
Procedure DeleteDocuments(Command)
	
	ClearMessages();
	HandleErrors(True);
	
	For Each String In ResultOfFormation.GetItems() Do
		Items.ResultOfFormation.Expand(String.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure SpendInStatusIsBeingFormed(Command)

	ClearMessages();
	HandleErrors();
	
	For Each String In ResultOfFormation.GetItems() Do
		Items.ResultOfFormation.Expand(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region Preview

&AtClient
Procedure ExpandPreview(Command)
	
	For Each String In ProductsToPreview.GetItems() Do
		If Not Items.ProductsToPreview.Expanded(String.GetID()) Then
			Items.ProductsToPreview.Expand(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapsePreview(Command)
	
	For Each String In ProductsToPreview.GetItems() Do
		If Items.ProductsToPreview.Expanded(String.GetID()) Then
			Items.ProductsToPreview.Collapse(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure StartFillingInFormNoEarlierThan(Command)
	
	If Items.ProductsToPreview.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà cần điền ngày.';
							|ru = 'Необходимо выбрать строки, для которых требуется заполнить дату.';
							|en = 'Select the lines for which it is required to populate the date.'; fa = 'Select the lines for which it is required to populate the date.';
							|it = 'Необходимо выбрать строки, для которых требуется заполнить дату.';
							|pl = 'Select the lines for which it is required to populate the date.';
							|tr = 'Tarihini doldurmak istediğiniz satırları seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"ItemsToPreview_FillInStartNoEarlierThanEnd",
		ThisObject,
		Items.ProductsToPreview.SelectedRows);
	
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
		CommonClient.SessionDate(),
		NStr("vi = 'Hãy nhập ngày bắt đầu';
			|ru = 'Введите дату начала';
			|en = 'Enter the start date'; fa = 'Enter the start date';
			|it = 'Введите дату начала';
			|pl = 'Enter the start date';
			|tr = 'Başlangıç tarihini girin'"),
		?(UsePlanningIntervalHour, DateFractions.DateTime, DateFractions.Date),
		Notification);
	
EndProcedure

&AtClient
Procedure ItemsToPreview_FillInStartNoEarlierThanEnd(SelectedDate, ArrayOfSelectedRows) Export
	
	If ValueIsFilled(SelectedDate) Then
		For Each RowID In ArrayOfSelectedRows Do
			TableRow = ProductsToPreview.FindByID(RowID);
			ParentRow = ?(TableRow.ThisIsTotal, TableRow, TableRow.GetParent());
			ParentRow.EarliestStartDate = SelectedDate;
			ParentRow.LineChanged = True;
		EndDo;
		FinishedProductsForPreviewHaveBeenChanged = True;
	EndIf; 
	
EndProcedure

#EndRegion

#Region ResultOfFormation

&AtClient
Procedure ExpandFormationResult(Command)
	
	For Each String In ResultOfFormation.GetItems() Do
		If Not Items.ResultOfFormation.Expanded(String.GetID()) Then
			Items.ResultOfFormation.Expand(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseFormationResult(Command)
	
	For Each String In ResultOfFormation.GetItems() Do
		If Items.ResultOfFormation.Expanded(String.GetID()) Then
			Items.ResultOfFormation.Collapse(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure PostDocuments(Command)
	
	ClearMessages();
	
	DocumentsChanged = HoldDocumentsOnTheServer();
	
	If DocumentsChanged > 0 Then
		ShowUserNotification(
			StrTemplate(NStr("vi = 'Thay đổi (%1)';
							|ru = 'Изменение (%1)';
							|en = 'Change (%1)'; fa = 'Change (%1)';
							|it = 'Modifica (%1)';
							|pl = 'Zmiana (%1)';
							|tr = 'Değişim (%1)'"), DocumentsChanged),,
			NStr("vi = 'Đã kết chuyển';
				|ru = 'Проведение выполнено';
				|en = 'Posted'; fa = 'ثبت‌شده';
				|it = 'Pubblicazione eseguita';
				|pl = 'Zatwierdzenie zostało wykonane';
				|tr = 'Kaydetme gerçekleştirildi'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtServer
Function HoldDocumentsOnTheServer()
	
	DocumentsChanged = 0;
	BatchUpdate = New Map;
	
	For Each Id In Items.ResultOfFormation.SelectedRows Do
		String = ResultOfFormation.FindByID(Id);
		If String.RowType = LineTypeBatch() Then
			Continue;
		EndIf;
		
		DocumentObject = String.Ref.GetObject();
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		
		Try
			DocumentObject.Lock();
		Except
			Common.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 - không thể kết chuyển chứng từ, có thể là người sử dụng khác đang soạn chứng từ.';
						|ru = '%1 - не удалось провести документ, возможно документ редактируется другим пользователем.';
						|en = '%1 - cannot post the document, the document may be edited by another user.'; fa = '%1 - cannot post the document, the document may be edited by another user.';
						|it = '%1 - non è stato possibile pubblicare il documento, forse il documento è in modifica da parte di un altro utente.';
						|pl = '%1 - nie udało się zatwierdzić dokumentu, możliwe że jest edytowany przez innego użytkownika.';
						|tr = '%1 - belge kaydedilemedi, belge başka bir kullanıcı tarafından düzenleniyor olabilir.'"),
					TrimAll(String.Ref)),
				String.Ref);
			Continue;
		EndTry;
		
		If DocumentObject.CheckFilling() Then
			
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
				DocumentsChanged = DocumentsChanged + 1;
			Except
				Common.MessageToUser(
					BriefErrorDescription(ErrorInfo()),
					String.Ref);
				Continue;
			EndTry;
			
			String.PictureNumber = ?(DocumentObject.Posted, 1, 0);
			
			HasErrors = ThereAreErrorsInStage(DocumentObject);
			If HasErrors <> String.HasErrors Then
				String.HasErrors = HasErrors;
				BatchUpdate.Insert(String.Lot, String.GetParent());
			EndIf;
			
		EndIf;
	EndDo;
	
	For Each KeyAndValue In BatchUpdate Do
		StringBatch = KeyAndValue.Value;
		StringBatch.HasErrors = False;
		For Each StageString In StringBatch.GetItems() Do
			If StageString.HasErrors Then
				StringBatch.HasErrors = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	ConfigureDependentFormElements(ThisForm, "ResultOfFormation");
	
	Return DocumentsChanged;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Steps

#Region Filters

&AtClient
Procedure GoBackToSelectionsStepOnClient()
	
	Object.PlanResults.Clear();
	SetHyperlinkTextProvided();
	PutToTempStorage(Undefined, AddressPlanStorage);
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
EndProcedure

#EndRegion

#Region ItemPlan

&AtClient
Procedure GoToNomenclaturePlanStepOnClient() 
	
	FillInNomenclaturePlanOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	Else
		
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoBackToNomenclaturePlanStepOnClient()
	
	AddressFormationData = Undefined;
	
	If CreatedObjects.Count() <> 0 Then
		
		Cancel = False;
		Delete_CreatedObjects(Cancel);
		
		If StartAwaitingLongAction Then
			StartAwaitingLongAction(False);
			SetUpWaitingInForm(True, NStr("vi = 'Đang xóa chứng từ...';
											|ru = 'Документы удаляются...';
											|en = 'Documents are being deleted...'; fa = 'Documents are being deleted...';
											|it = 'Documenti in eliminazione...';
											|pl = 'Trwa usunięcie dokumentów...';
											|tr = 'Belgeler siliniyor...'"));
		Else
			AfterDeletingCreatedObjects(Cancel);
		EndIf;
		
	Else
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInNomenclaturePlanOnServer()
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return;
	EndIf;
	
	SaveDocumentCreationParameters();
	
	If ShouldSaveSettings And Not SelectionStructureIsFilledInAccordingToPassedParameters Then 
		SaveSelectionComposerSettings();
	EndIf;
	
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Settings", SettingsComposer.GetSettings());
	ProcedureParameters.Insert("CrossTable", DisplayParameters.CrossTable);
	ProcedureParameters.Insert("Periodicity", DisplayParameters.Periodicity);
	ProcedureParameters.Insert("NameOfPeriodDateField", DisplayParameters.NameOfPeriodDateField);
	ProcedureParameters.Insert("NumberOfPeriods", DisplayParameters.NumberOfPeriods);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo lô hàng sản xuất: điền kế hoạch theo mặt hàng';
														|ru = 'Формирование партий производства: заполнение номенклатурного плана';
														|en = 'Generate production lots: item plan filling'; fa = 'Generate production lots: item plan filling';
														|it = 'Creazione lotti di produzione: compilazione piano di nomenclatura';
														|pl = 'Tworzenie partii produkcji: wypełnienie planu produktów';
														|tr = 'Üretim lotunun düzenlenmesi: Öğe planının doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GeneratingProductionStages.GetItemPlanOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillOutNomenclaturePlanOnHoldCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillOutNomenclaturePlanOnHold(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutNomenclaturePlanOnHoldCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		FillOutNomenclaturePlanOnHold(Result);
		
		InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutNomenclaturePlanOnHold(Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
#Region CrossTable
		
		ColumnsPeriods = ?(FillingData.ColumnsPeriods <> Undefined,
			FillingData.ColumnsPeriods,
			New Array);
		
		// Changing the form details
		AttributesToBeAdded = New Array;
		PlanResults = FillingData.PlanResults; // ValueTable
		For Each NameColumn In ColumnsPeriods Do
			If AddedColumns.FindByValue(NameColumn) <> Undefined Then
				Continue;
			EndIf;
			NewAttribute = New FormAttribute(
				NameColumn, 
				PlanResults.Columns[NameColumn].ValueType,
				"Object.PlanResults");
			AttributesToBeAdded.Add(NewAttribute);
			AddedColumns.Add(NameColumn);
		EndDo;
		
		AttributesToBeDeleted = New Array;
		For IndexOf = -(AddedColumns.Count()-1) To 0 Do
			NameColumn = AddedColumns[-IndexOf].Value;
			If ColumnsPeriods.Find(NameColumn) <> Undefined Then
				Continue;
			EndIf;
			Items.Delete(Items.Find(NameColumn));
			AttributesToBeDeleted.Add("Object.PlanResults." + NameColumn);
			AddedColumns.Delete(-IndexOf);
		EndDo;
		
		If AttributesToBeAdded.UBound() <> -1
				Or AttributesToBeDeleted.UBound() <> -1 Then
			ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
		EndIf;
		
		// Changing Form elements
		If AttributesToBeAdded.UBound() <> -1 Then
			For IndexOf = -(Items.PlanResultsPeriods.ChildItems.Count()-1) To 0 Do
				Items.Delete(Items.PlanResultsPeriods.ChildItems[-IndexOf]);
			EndDo;
			
			For IndexOf = 0 To ColumnsPeriods.UBound() Do
				NameColumn = ColumnsPeriods[IndexOf];
				NewItem = Items.Add(NameColumn, Type("FormField"), Items.PlanResultsPeriods);
				NewItem.DataPath = "Object.PlanResults." + NameColumn;
				NewItem.Title = PlanResults.Columns[NameColumn].Title;
				NewItem.Type = FormFieldType.LabelField;
				NewItem.Width = 6;
				NewItem.HorizontalStretch = False;
			EndDo;
		EndIf;
		
#EndRegion
		
#Region DataImport
		
		Object.PlanResults.Load(FillingData.PlanResults);
		SetHyperlinkTextProvided();
		SetAdditionalSelectionOfLinesNomenclaturePlan(ThisForm);
		
#EndRegion
		
		// Caching selections
		PutToTempStorage(FillingData.CustomFilters, AddressCustomSelections);
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReReadNomenclaturePlanOnServer()
	
	Object.PlanResults.Clear();
	SetHyperlinkTextProvided();
	PutToTempStorage(Undefined, AddressPlanStorage);
	
	FillInNomenclaturePlanOnServer();
	
EndProcedure

&AtClient
Procedure PlanResultsWhenChanging()
	
	RowData = LinePlanTotalsInStructure(Items.PlanResults.CurrentData);
	
	If Items.PlanResults.CurrentData.MultipleLaunch Then
		PlanRows = PlanResultsWhenContextChangesOnServer(RowData);
	Else
		PlanRows = PlanResultsWhenChangingOnServer(
			RowData,
			AddressPlanStorage,
			AddressCustomSelections,
			SeparateProductionOfSemiFinishedProducts);
	EndIf;
	
	If Show_Details Then
		Object.Plan.Clear();
		For IndexOf = 0 To PlanRows.UBound() Do
			FillPropertyValues(Object.Plan.Add(), PlanRows[IndexOf]);
		EndDo;
	EndIf;
	
	Items.PlanResults.CurrentData.PlanIsInVault = RowData.PlanIsInVault;
	
EndProcedure

&AtServer
Function PlanResultsWhenContextChangesOnServer(RowData)
	
	Table = FillOutLaunchPlan(
		RowData,
		AddressPlanStorage,
		AddressCustomSelections,
		SeparateProductionOfSemiFinishedProducts);
	
	RecalculateMultipleLaunches(RowData);
	
	Return Common.ValueTableToArray(Table);
	
EndFunction

&AtServerNoContext
Function PlanResultsWhenChangingOnServer(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts)
	
	Return Common.ValueTableToArray(
		FillOutLaunchPlan(
			RowData,
			AddressPlanStorage,
			AddressCustomSelections,
			SeparateProductionOfSemiFinishedProducts));
	
EndFunction

&AtServer
Function PlanResultsBillOfMaterialsWhenContextChangesOnServer(RowData)
	
	Result = ProductData_1(RowData);
	FillPropertyValues(RowData, Result, "QuantityPerBatch, MainProduct");
	
	FoundRow = Object.PlanResults.FindByID(RowData.Id);
	If FoundRow <> Undefined Then
		FillPropertyValues(FoundRow, Result, "QuantityPerBatch, MainProduct");
	EndIf;
	
	If RowData.PlanIsInVault Then
		Table = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		Table.FillValues(RowData.BillOfMaterials, "BillOfMaterials");
		Table.FillValues(Result.QuantityPerBatch, "QuantityPerBatch");
		PutPlanInStorage(RowData, Table, AddressPlanStorage);
	EndIf;
	
	RecalculateMultipleLaunches(RowData);
	
	If Show_Details Then
		Table = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		Result.Insert("DetailedRecords", Common.ValueTableToArray(Table));
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PlanResultsBillOfMaterialsWhenChangedOnServer(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, Show_Details)
	
	Result = ProductData_1(RowData);
	FillPropertyValues(RowData, Result, "QuantityPerBatch, MainProduct");
	
	If RowData.PlanIsInVault Or Show_Details Then
		Table = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		Table.FillValues(RowData.BillOfMaterials, "BillOfMaterials");
		Table.FillValues(Result.QuantityPerBatch, "QuantityPerBatch");
		
		If RowData.PlanIsInVault Then
			PutPlanInStorage(RowData, Table, AddressPlanStorage);
		EndIf;
		
		If Show_Details Then
			Result.Insert("DetailedRecords", Common.ValueTableToArray(Table));
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ChangeMarksInSelectedLines(Val Mark, Val RowsIDs)
	
	Table_Selection = NewSelectionDetailedRecords();
	
	For Each RowID In RowsIDs Do
		
		String = Object.PlanResults.FindByID(RowID);
		String.Mark = Mark;
		String.MarkForm = ?(Mark, 1, 0);
		String.AutoRecalculation = False;
		
		FillPropertyValues(Table_Selection.Add(), String);
		
	EndDo;
	
	DetailedRecordsPackage = DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
	
	For Each RowID In RowsIDs Do
		
		String = Object.PlanResults.FindByID(RowID);
		
		Table = FillOutLaunchPlan(
			String,
			AddressPlanStorage,
			AddressCustomSelections,
			SeparateProductionOfSemiFinishedProducts,
			DetailedRecordsPackage);
		
		If Show_Details And RowID = Items.PlanResults.CurrentRow Then
			Object.Plan.Clear();
			For IndexOf = 0 To Table.Count()-1 Do
				FillPropertyValues(Object.Plan.Add(), Table[IndexOf]);
			EndDo;
		EndIf;
		
		RecalculateMultipleLaunches(String);
		
	EndDo;

EndProcedure

&AtServer
Procedure FillInForLaunchInSelectedLines(Val ColumnNameSourceOfQuantity, Val RowsIDs)
	
	Table_Selection = NewSelectionDetailedRecords();
	
	For Each RowID In RowsIDs Do
		
		String = Object.PlanResults.FindByID(RowID);
		
		Launch = 0;
		If ColumnNameSourceOfQuantity = "Supplied" Then
			If String.BillOfMaterials = String.BillOfMaterialsPlan Then
				If String.SupplyIsRequired Then
					Launch = String.Supplied;
				Else
					Launch = String.Required2;
				EndIf;
			EndIf;
		Else
			Launch = String[ColumnNameSourceOfQuantity];
		EndIf;
			
		String.Launch = ?(Launch > 0, Launch, String.Required2);
		String.Mark = Launch > 0;
		String.MarkForm = ?(String.Mark, 1, 0);
		String.AutoRecalculation = False;
		
		FillPropertyValues(Table_Selection.Add(), String);
		
	EndDo;
	
	DetailedRecordsPackage = DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
	
	For Each RowID In RowsIDs Do
		
		String = Object.PlanResults.FindByID(RowID);
		
		Table = FillOutLaunchPlan(
			String,
			AddressPlanStorage,
			AddressCustomSelections,
			SeparateProductionOfSemiFinishedProducts,
			DetailedRecordsPackage);
		
		If Show_Details And RowID = Items.PlanResults.CurrentRow Then
			Object.Plan.Clear();
			For IndexOf = 0 To Table.Count()-1 Do
				FillPropertyValues(Object.Plan.Add(), Table[IndexOf]);
			EndDo;
		EndIf;
		
		RecalculateMultipleLaunches(String);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateMultipleLaunches(RowData)
	
	If Not RowData.MultipleLaunch Then
		Return;
	EndIf;
	
	If RowData.Regroup Then
		
		// Regrouping - several different groups according to the same specification, only for the products of the order
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Regroup", True);
		TheStructureOfTheSearch.Insert("BillOfMaterialsPlan", RowData.BillOfMaterialsPlan);
		TheStructureOfTheSearch.Insert("Organization", RowData.Organization);
		TheStructureOfTheSearch.Insert("Partner", RowData.Partner);
		TheStructureOfTheSearch.Insert("Contract", RowData.Contract);
		TheStructureOfTheSearch.Insert("LineOfBusiness", RowData.LineOfBusiness);
		TheStructureOfTheSearch.Insert("MainProduct", True);
		MainLines = Object.PlanResults.FindRows(TheStructureOfTheSearch);
		
		TheStructureOfTheSearch.MainProduct = False;
		SideLines = Object.PlanResults.FindRows(TheStructureOfTheSearch);
		
		// Batch selection of detailed records
		Table_Selection = NewSelectionDetailedRecords();
		For Each GroupRow In MainLines Do
			String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
			FillPropertyValues(Table_Selection.Add(), String);
		EndDo;
		For Each GroupRow In SideLines Do
			String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
			FillPropertyValues(Table_Selection.Add(), String);
		EndDo;
		DetailedRecordsPackage = DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		
		// Calculation of the number of batches
		QuantityOfBatches = New Map; // Key - order
		MainLinesMark = New Map; // Key - order; lines marked for launch in the number of products
		
		//  For the main products , the number of batches is summed up
		//  The main products are the first line of the PC release with the sign there is a daily main product
		For Each GroupRow In MainLines Do
			If GroupRow.Mark
					And Not GroupRow.AutoRecalculation
					And GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
				String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
				Details_3 = DetailedRecords(String, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					If Not DetailsRow.Mark Or Not DetailsRow.OrderProducts_ Then
						Continue;
					EndIf;
					Count = ?(DetailsRow.QuantityPerBatch <> 0,
						DetailsRow.Launch/DetailsRow.QuantityPerBatch, 0);
					Var_Key = DetailsRow.ProductionOrder;
					If QuantityOfBatches[Var_Key] = Undefined Then
						QuantityOfBatches.Insert(Var_Key, Count);
					Else
						QuantityOfBatches[Var_Key] = QuantityOfBatches[Var_Key] + Count;
					EndIf;
					If MainLinesMark[Var_Key] = Undefined Then
						MainLinesMark.Insert(Var_Key, DetailsRow.Launch);
					Else
						MainLinesMark[Var_Key] = MainLinesMark[Var_Key] + DetailsRow.Launch;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		//  For by-products, the number of batches is taken as a maximum
		NumberOfBatchesOfGroup = New Map;
		For Each GroupRow In SideLines Do
			If GroupRow.Mark
					And Not GroupRow.AutoRecalculation
					And GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
				String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
				Details_3 = DetailedRecords(String, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					If Not DetailsRow.Mark Or Not DetailsRow.OrderProducts_ Then
						Continue;
					EndIf;
					Count = ?(DetailsRow.QuantityPerBatch <> 0,
						DetailsRow.Launch/DetailsRow.QuantityPerBatch, 0);
					Var_Key = DetailsRow.ProductionOrder;
					If NumberOfBatchesOfGroup[Var_Key] = Undefined Then
						NumberOfBatchesOfGroup.Insert(Var_Key, Count);
					Else
						NumberOfBatchesOfGroup[Var_Key] = NumberOfBatchesOfGroup[Var_Key] + Count;
					EndIf;
				EndDo;
				
				For Each KeyAndValue In NumberOfBatchesOfGroup Do
					If QuantityOfBatches[KeyAndValue.Key] = Undefined Then
						QuantityOfBatches.Insert(KeyAndValue.Key, KeyAndValue.Value);
					Else
						QuantityOfBatches[KeyAndValue.Key] = Max(QuantityOfBatches[KeyAndValue.Key], KeyAndValue.Value);
					EndIf;
				EndDo;	
				NumberOfBatchesOfGroup.Clear();
			EndIf;
		EndDo;
		
		// Auto recalculation of by-products (for the calculated number of batches)
		Balance = New Map;
		For Each GroupRow In SideLines Do
			If GroupRow.AutoRecalculation Then
				Launch = 0;
				
				Details_3 = DetailedRecords(GroupRow, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					If Not DetailsRow.OrderProducts_ Then
						Continue;
					EndIf;
					
					Var_Key = DetailsRow.ProductionOrder;
					
					Count = 0;
					If GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
						If Balance[Var_Key] = Undefined Then
							Count = ?(QuantityOfBatches[Var_Key] = Undefined,
								0, DetailsRow.QuantityPerBatch * QuantityOfBatches[Var_Key]);
							Balance.Insert(Var_Key, Count);
						Else
							Count = Balance[Var_Key];
						EndIf;
					EndIf;
					LaunchDetails = Min(DetailsRow.Required2, Count);
					
					DetailsRow.Launch = ?(LaunchDetails > 0, LaunchDetails, DetailsRow.Required2);
					DetailsRow.Mark = ?(LaunchDetails > 0, True, False);
					
					If LaunchDetails <> 0 Then
						Launch = Launch + LaunchDetails;
						Balance[Var_Key] = Balance[Var_Key] - LaunchDetails;
					EndIf;
				EndDo;
				
				If Launch = 0 Then
					GroupRow.Launch = GroupRow.Required2;
					GroupRow.Mark = False;
					GroupRow.MarkForm = 0;
				Else
					GroupRow.Launch = Launch;
					GroupRow.Mark = True;
					GroupRow.MarkForm = 2;
				EndIf;
				PutPlanInStorage(GroupRow, Details_3, AddressPlanStorage);
				
				If GroupRow.LineNumber = RowData.LineNumber Then
					RowData.PlanIsInVault = GroupRow.PlanIsInVault;
				EndIf;
					
				Balance.Clear();
			EndIf;
		EndDo;
		
		// Auto recalculation of the main products (for the calculated number of batches minus the lines marked manually)
		Balance = New Map; // The Balances are not reset to zero - they apply to all lines
		For Each GroupRow In MainLines Do
			If GroupRow.AutoRecalculation Then
				Launch = 0;
				
				Details_3 = DetailedRecords(GroupRow, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					If Not DetailsRow.OrderProducts_ Then
						Continue;
					EndIf;
					
					Var_Key = DetailsRow.ProductionOrder;
					
					Count = 0;
					If GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
						If Balance[Var_Key] = Undefined Then
							Count = ?(QuantityOfBatches[Var_Key] = Undefined,
								0, DetailsRow.QuantityPerBatch * QuantityOfBatches[Var_Key]);
							If MainLinesMark[Var_Key] <> Undefined Then
								Count = ?(Count > MainLinesMark[Var_Key],
									Count - MainLinesMark[Var_Key], 0);
							EndIf;
							Balance.Insert(Var_Key, Count);
						Else
							Count = Balance[Var_Key];
						EndIf;
					EndIf;
					LaunchDetails = Min(DetailsRow.Required2, Count);
					
					DetailsRow.Launch = ?(LaunchDetails > 0, LaunchDetails, DetailsRow.Required2);
					DetailsRow.Mark = ?(LaunchDetails > 0, True, False);
					
					If LaunchDetails <> 0 Then
						Launch = Launch + LaunchDetails;
						Balance[Var_Key] = Balance[Var_Key] - LaunchDetails;
					EndIf;
				EndDo;
				
				If Launch = 0 Then
					GroupRow.Launch = GroupRow.Required2;
					GroupRow.Mark = False;
					GroupRow.MarkForm = 0;
				Else
					GroupRow.Launch = Launch;
					GroupRow.Mark = True;
					GroupRow.MarkForm = 2;
				EndIf;
				PutPlanInStorage(GroupRow, Details_3, AddressPlanStorage);
				
				If GroupRow.LineNumber = RowData.LineNumber Then
					RowData.PlanIsInVault = GroupRow.PlanIsInVault;
				EndIf;
			EndIf;
		EndDo;
		
	Else
		
		// Recalculation of multiple launches - several lines of totals of the same group with different nomenclature
		GroupStrings = Object.PlanResults.FindRows(New Structure("NumberOfGroup", RowData.NumberOfGroup));
		
		// Batch selection of detailed records
		Table_Selection = NewSelectionDetailedRecords();
		For Each GroupRow In GroupStrings Do
			String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
			FillPropertyValues(Table_Selection.Add(), String);
		EndDo;
		DetailedRecordsPackage = DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		
		// Calculation of the number of batches
		QuantityOfBatches = New Map; // Key - order (for order products) / empty link for PF; value - quantity
		NumberOfBatchesOfGroup = New Map;
		
		For Each GroupRow In GroupStrings Do
			If GroupRow.Mark
					And Not GroupRow.AutoRecalculation
					And GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
				String = ?(GroupRow.LineNumber = RowData.LineNumber, RowData, GroupRow); // The row data may not have been transferred to the object yet
				Details_3 = DetailedRecords(String, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					If Not DetailsRow.Mark Then
						Continue;
					EndIf;
					Count = ?(DetailsRow.QuantityPerBatch <> 0,
						DetailsRow.Launch/DetailsRow.QuantityPerBatch, 0);
					Var_Key = ?(DetailsRow.OrderProducts_,
						DetailsRow.ProductionOrder, Documents.ProductionOrder2_2.EmptyRef());
					If NumberOfBatchesOfGroup[Var_Key] = Undefined Then
						NumberOfBatchesOfGroup.Insert(Var_Key, Count);
					Else
						NumberOfBatchesOfGroup[Var_Key] = NumberOfBatchesOfGroup[Var_Key] + Count;
					EndIf;
				EndDo;
				
				For Each KeyAndValue In NumberOfBatchesOfGroup Do
					If QuantityOfBatches[KeyAndValue.Key] = Undefined Then
						QuantityOfBatches.Insert(KeyAndValue.Key, KeyAndValue.Value);
					Else
						QuantityOfBatches[KeyAndValue.Key] = Max(QuantityOfBatches[KeyAndValue.Key], KeyAndValue.Value);
					EndIf;
				EndDo;	
				NumberOfBatchesOfGroup.Clear();
			EndIf;
		EndDo;
		
		// Auto recalculation of the quantity to be launched
		Balance = New Map;
		For Each GroupRow In GroupStrings Do
			If GroupRow.AutoRecalculation Then
				Launch = 0;
				
				Details_3 = DetailedRecords(GroupRow, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
				For IndexOf = 0 To Details_3.Count()-1 Do
					DetailsRow = Details_3[IndexOf];
					
					Var_Key = ?(DetailsRow.OrderProducts_,
						DetailsRow.ProductionOrder, Documents.ProductionOrder2_2.EmptyRef());
					
					Count = 0;
					If GroupRow.BillOfMaterials = GroupRow.BillOfMaterialsPlan Then
						If Balance[Var_Key] = Undefined Then
							Count = ?(QuantityOfBatches[Var_Key] = Undefined,
								0, DetailsRow.QuantityPerBatch * QuantityOfBatches[Var_Key]);
							Balance.Insert(Var_Key, Count);
						Else
							Count = Balance[Var_Key];
						EndIf;
					EndIf;
					LaunchDetails = Min(DetailsRow.Required2, Count);
					
					DetailsRow.Launch = ?(LaunchDetails > 0, LaunchDetails, DetailsRow.Required2);
					DetailsRow.Mark = ?(LaunchDetails > 0, True, False);
					
					If LaunchDetails <> 0 Then
						Launch = Launch + LaunchDetails;
						Balance[Var_Key] = Balance[Var_Key] - LaunchDetails;
					EndIf;
				EndDo;
				
				If Launch = 0 Then
					GroupRow.Launch = GroupRow.Required2;
					GroupRow.Mark = False;
					GroupRow.MarkForm = 0;
				Else
					GroupRow.Launch = Launch;
					GroupRow.Mark = True;
					GroupRow.MarkForm = 2;
				EndIf;
				PutPlanInStorage(GroupRow, Details_3, AddressPlanStorage);
				
				If GroupRow.LineNumber = RowData.LineNumber Then
					RowData.PlanIsInVault = GroupRow.PlanIsInVault;
				EndIf;
				
				Balance.Clear();
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanTotalsWhenActivatingDelayedLine()
	
	UpdatePlanWhenLineIsActivated();
	FillInInformationLine();
	
EndProcedure

&AtClient
Procedure UpdatePlanWhenLineIsActivated()
	
	Object.Plan.Clear();
	ThereAreTasksToCalculate = False;
	
	If Items.PlanResults.CurrentData <> Undefined Then
		RowData = LinePlanTotalsInStructure(Items.PlanResults.CurrentData);
		
		InformationRecords = PlanResultsWhenActivatedOnServer(
			RowData,
			AddressPlanStorage,
			AddressCustomSelections,
			SeparateProductionOfSemiFinishedProducts,
			Show_Details);
			
		If Show_Details Then
			For IndexOf = 0 To InformationRecords.DetailedRecords.UBound() Do
				FillPropertyValues(Object.Plan.Add(), InformationRecords.DetailedRecords[IndexOf]);
			EndDo;
		EndIf;
		
		FillPropertyValues(DataOfActiveLine, InformationRecords,
			"MinimumReleaseLot, EconomicReleaseLot, ThereIsSideIssue, SideIssueNumberOfProducts, SideIssueProductPresentation");
		
		ThereAreTasksToCalculate = InformationRecords.ThereAreTasksToCalculate;
	Else
		DataOfActiveLine.MinimumReleaseLot = 0;
		DataOfActiveLine.EconomicReleaseLot = 0;
		DataOfActiveLine.ThereIsSideIssue = False;
		DataOfActiveLine.SideIssueNumberOfProducts = 0;
		DataOfActiveLine.SideIssueProductPresentation = "";
	EndIf;
	
	Items.WarningGroup.Visible = ThereAreTasksToCalculate;
	
EndProcedure

&AtServerNoContext
Function PlanResultsWhenActivatedOnServer(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, Show_Details)
	
	Result = ProductData_1(RowData);
	
	If Show_Details Then
		DetailedRecords = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		Result.Insert("DetailedRecords", Common.ValueTableToArray(DetailedRecords));
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ProductData_1(RowData)
	
	Result = New Structure;
	
	QueryText =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Jobs
		|WHERE
		|	Jobs.Products = &Products
		|	AND Jobs.Characteristic = &Characteristic
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	COUNT(ProductsBOM.Products) AS NumberOfProducts,
		|	PRESENTATION(MAX(ProductsBOM.Products)) AS Products
		|FROM
		|	InformationRegister.ProductsBOM AS ProductsBOM
		|WHERE
		|	ProductsBOM.BillOfMaterials = &BillOfMaterials
		|	AND ProductsBOM.SideExit
		|
		|HAVING
		|	COUNT(ProductsBOM.Products) > 0
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	ProductsBOM.BillOfMaterials.EconomicReleaseLot    AS EconomicReleaseLot,
		|	ProductsBOM.BillOfMaterials.MinimumReleaseLot    AS MinimumReleaseLot,
		|	ProductsBOM.BillOfMaterials.ProductionIssueByCustomPortions AS ProductionIssueByCustomPortions,
		|	Product.Ref AS Products,
		|	ProductsBOM.Package AS Package,
		|	ProductsBOM.NumberOfPackagesPerStartingLotUnit AS NumberOfPackagesPerUnitOfProductionBatch,
		|	ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1) AS QuantityPerBatch,
		|	ProductsBOM.Order = 1 AS ThisIsMainProduct,
		|	UNDEFINED AS PackageData,
		|	&AttributesOfPackagingUnitItem
		|FROM
		|	Catalog.Products AS Product
		|
		|	INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|	ON ProductsBOM.BillOfMaterials = &BillOfMaterials
		|		AND ProductsBOM.ProductKind = Product.ProductKind
		|		AND ProductsBOM.Products IN (Product.Ref, VALUE(Catalog.Products.EmptyRef))
		|		AND ProductsBOM.Characteristic IN (&Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|WHERE
		|	Product.Ref = &Products
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	MainProductSpecifications.Products AS Products,
		|	MainProductSpecifications.Package AS Package,
		|	MainProductSpecifications.NumberOfPackagesPerStartingLotUnit AS NumberOfPackagesPerUnitOfProductionBatch,
		|	UNDEFINED AS PackageData,
		|	&AttributesOfPackagingUnitMainFinishedProductSpecifications
		|FROM
		|	InformationRegister.ProductsBOM AS MainProductSpecifications
		|WHERE
		|	MainProductSpecifications.BillOfMaterials = &BillOfMaterials
		|	AND MainProductSpecifications.Order = 1";
	
	SubstitutionText = ProductDataManagement.RequestTextPackingDetailsUnitsOfMeasurement(
		"ProductsBOM.Package",
		"Product");
	QueryText = StrReplace(QueryText, "&AttributesOfPackagingUnitItem", SubstitutionText);
	
	SubstitutionText = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductsBOM.Package",
		"Product");
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor", SubstitutionText);
	
	SubstitutionText = ProductDataManagement.RequestTextPackingDetailsUnitsOfMeasurement(
		"MainProductSpecifications.Package",
		"MainProductSpecifications.Products");
	QueryText = StrReplace(QueryText, "&AttributesOfPackagingUnitMainFinishedProductSpecifications", SubstitutionText);
	
	Query = New Query(QueryText);
	Query.SetParameter("Products", RowData.Products);
	Query.SetParameter("Characteristic", RowData.Characteristic);
	Query.SetParameter("BillOfMaterials", RowData.BillOfMaterials);
	QueryResults = Query.ExecuteBatch();
	
	Result.Insert("ThereAreTasksToCalculate", Not QueryResults[0].IsEmpty());
	
	// Side issue
	Selection = QueryResults[1].Select();
	If Selection.Next() Then
		Result.Insert("ThereIsSideIssue", True);
		Result.Insert("SideIssueNumberOfProducts", Selection.NumberOfProducts);
		Result.Insert("SideIssueProductPresentation", Selection.Products);
	Else
		Result.Insert("ThereIsSideIssue", False);
		Result.Insert("SideIssueNumberOfProducts", 0);
		Result.Insert("SideIssueProductPresentation", "");
	EndIf;
	
	// Calculation of min/wholesale of the batch
	EconomicReleaseLot = 0;
	MinimumReleaseLot = 0;
	
	FinishedProductTable = QueryResults[2].Unload();
	TableOfMainFinishedProduct = QueryResults[3].Unload();
	
	If FinishedProductTable.Count() = 1
		And TableOfMainFinishedProduct.Count() = 1 Then
		ProductLine = FinishedProductTable[0];
		ProductDataManagement.FillInPackingDataInDataSetRow(ProductLine, FinishedProductTable);
		
		If ProductLine.ProductionIssueByCustomPortions Then
			ConversionFactorToMainProduct = 1;
			If Not ProductLine.ThisIsMainProduct Then
				MainProduct = Catalogs.BillsOfMaterials.MainProductSpecificationDataStructure();
				FillPropertyValues(MainProduct, ProductLine,
					"Products, Package, PackageData, ThisIsMainProduct, NumberOfPackagesPerUnitOfProductionBatch");
				
				MainProductSpecifications = TableOfMainFinishedProduct[0];
				ProductDataManagement.FillInPackingDataInDataSetRow(
					MainProductSpecifications, TableOfMainFinishedProduct);
				ProductDataManagement.FillInConversionFactorToMainProduct(
					MainProduct, MainProductSpecifications);
				
				ConversionFactorToMainProduct = MainProduct.ConversionFactorToMainProduct;
			EndIf;
			
			EconomicReleaseLot = ProductLine.EconomicReleaseLot
				* ConversionFactorToMainProduct;
			MinimumReleaseLot = ProductLine.MinimumReleaseLot
				* ConversionFactorToMainProduct;
		Else
			EconomicReleaseLot = ProductLine.EconomicReleaseLot
				* ProductLine.NumberOfPackagesPerUnitOfProductionBatch
				* ProductLine.PackageData.Numerator
				/ ProductLine.PackageData.Denominator;
			MinimumReleaseLot = ProductLine.MinimumReleaseLot
				* ProductLine.NumberOfPackagesPerUnitOfProductionBatch
				* ProductLine.PackageData.Numerator
				/ ProductLine.PackageData.Denominator;
		EndIf;
		
	EndIf;
	
	If FinishedProductTable.Count() > 0 Then
		QuantityPerBatch = FinishedProductTable[0].QuantityPerBatch;
		MainProduct = FinishedProductTable[0].ThisIsMainProduct;
	Else
		QuantityPerBatch = 1;
		MainProduct = False;
	EndIf;
	
	Result.Insert("EconomicReleaseLot", Round(EconomicReleaseLot, 3));
	Result.Insert("MinimumReleaseLot", Round(MinimumReleaseLot, 3));
	Result.Insert("QuantityPerBatch", QuantityPerBatch);
	Result.Insert("MainProduct", MainProduct);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function UnloadProductsOnCurLine(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts)
	
	Return PutToTempStorage(
		DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts));
	
EndFunction

&AtClient
Procedure SelectProductsToLaunchCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Items.PlanResults.CurrentData.Launch = Result.Launch;
		Items.PlanResults.CurrentData.Mark = Result.Launch > 0;
		Items.PlanResults.CurrentData.MarkForm = ?(Result.Launch > 0, 1, 0);
		Items.PlanResults.CurrentData.AutoRecalculation = False;
		
		RowData = LinePlanTotalsInStructure(Items.PlanResults.CurrentData);
		
		If Items.PlanResults.CurrentData.MultipleLaunch Then
			PlanRows = SelectingProductsToLaunchEndOnServerContext(Result.ProductAddress, RowData);
		Else
			PlanRows = SelectionOfProductsToLaunchEndOnServer(Result.ProductAddress, RowData, AddressPlanStorage);
		EndIf;
		
		If Show_Details Then
			Object.Plan.Clear();
			For IndexOf = 0 To PlanRows.UBound() Do
				FillPropertyValues(Object.Plan.Add(), PlanRows[IndexOf]);
			EndDo;
		EndIf;
		
		Items.PlanResults.CurrentData.PlanIsInVault = RowData.PlanIsInVault;
		
		FillInInformationLine();
		
	EndIf;
	
EndProcedure

&AtServer
Function SelectingProductsToLaunchEndOnServerContext(TableAddress, RowData)
	
	Table = GetFromTempStorage(TableAddress);
	PutPlanInStorage(RowData, Table, AddressPlanStorage);
	
	RecalculateMultipleLaunches(RowData);
	
	Return Common.ValueTableToArray(Table);
	
EndFunction

&AtServerNoContext
Function SelectionOfProductsToLaunchEndOnServer(TableAddress, RowData, AddressPlanStorage)
	
	Table = GetFromTempStorage(TableAddress);
	PutPlanInStorage(RowData, Table, AddressPlanStorage);
	
	Return Common.ValueTableToArray(Table);
	
EndFunction

&AtServerNoContext
Function DetailsParameters(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts)
	
	Result = New Structure;
	Result.Insert("GenerateOnOpen", True);
	Result.Insert("BillOfMaterials", RowData.BillOfMaterials);
	Result.Insert("Products", RowData.Products);
	Result.Insert("Characteristic", RowData.Characteristic);
	Result.Insert("LineOfBusiness", RowData.LineOfBusiness);
	
	ColumnQuantity = ?(RowData.Mark, "Launch", "Required2");
	Result.Insert("Count", RowData[ColumnQuantity]);
	
	Table = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
	If RowData.Mark Then
		Table = Table.Copy(New Structure("Mark", True));
	EndIf;
	
	Products_1 = Table.Copy(, "Products, Characteristic, ProductionOrder, Recipient, Purpose," + ColumnQuantity);
	Products_1.Columns[ColumnQuantity].Name = "Count";
	
	Assignments = Table.Copy(, "ProductionOrder, AssignmentMaterials, ExceedingOrder," + ColumnQuantity);
	Assignments.Columns[ColumnQuantity].Name = "Count";
	Assignments.Columns.AssignmentMaterials.Name = "Purpose";	
	
	ProductionOrder = Undefined;
	Purpose = Undefined;
	For Each String In Assignments Do
		If String.ExceedingOrder Then
			Continue;
		EndIf;
		
		If ProductionOrder = Undefined Then
			ProductionOrder = String.ProductionOrder;
		ElsIf ProductionOrder <> String.ProductionOrder Then
			ProductionOrder = Documents.ProductionOrder2_2.EmptyRef();
		EndIf;
		
		If Purpose = Undefined Then
			Purpose = String.Purpose;
		ElsIf Purpose <> String.Purpose Then
			Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	If ValueIsFilled(Purpose) Then
		OverOrderLine = Assignments.Find(True, "ExceedingOrder");
		If OverOrderLine <> Undefined Then
			OverOrderLine.Purpose = Purpose;
		EndIf;
	EndIf;
	
	Assignments.GroupBy("Purpose", "Count");
	
	Result.Insert("ProductionOrder", ProductionOrder);
	Result.Insert("ProductAddress", PutToTempStorage(Products_1));
	Result.Insert("DestinationAddress", PutToTempStorage(Assignments));
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillInInformationLine()
	
	String = Items.PlanResults.CurrentData;
	If String = Undefined Then
		InformationBar = Undefined;
	Else
		
		Rows = New Array;
		FontBold = New Font(,,True);
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			String.ProductsPresentation,
			String.CharacteristicPresentation);
		Rows.Add(New FormattedString(ProductPresentation,,,, "Decrypt"));
		
		Rows.Add(" ");
		
		// Required2
		Rows.Add(NStr("vi = 'Cần thiết:';
						|ru = 'Требуется:';
						|en = 'Required:'; fa = 'الزامی:';
						|it = 'Richiesto:';
						|pl = 'Required:';
						|tr = 'Gerekli:'") + " ");
		Rows.Add(New FormattedString(Format(String.Required2, "NZ=0; NG="), FontBold));
		Rows.Add(" ");
		Rows.Add(New FormattedString(String.ProductsUnitOfMeasurePresentation, FontBold));
		
		Rows.Add(" ");
		
		// Ready to launch
		Rows.Add(NStr("vi = 'Cần khởi động:';
						|ru = 'К запуску:';
						|en = 'To launch:'; fa = 'To launch:';
						|it = 'In avvio:';
						|pl = 'Do uruchomienia:';
						|tr = 'Başlatılacak:'") + " ");
		Rows.Add(New FormattedString(Format(?(String.Mark, String.Launch, 0), "NZ=0; NG="), FontBold));
		Rows.Add(" ");
		Rows.Add(New FormattedString(String.ProductsUnitOfMeasurePresentation, FontBold));
		
		// Side issue
		If DataOfActiveLine.ThereIsSideIssue Then
			
			Rows.Add(" ");
			Rows.Add(NStr("vi = 'Xuất xưởng sản phẩm phụ:';
							|ru = 'Побочный выпуск:';
							|en = 'Side release:'; fa = 'Side release:';
							|it = 'Avvio secondario:';
							|pl = 'Produkcja uboczna:';
							|tr = 'Yan ürün çıkışı:'") + " ");
			
			If DataOfActiveLine.SideIssueNumberOfProducts = 1 Then
				Rows.Add(New FormattedString(DataOfActiveLine.SideIssueProductPresentation,,,, "Decrypt"));
			Else
				Rows.Add(New FormattedString(NStr("vi = '<nhiều sản phẩm...>';
													|ru = '<несколько изделий...>';
													|en = '<several finished products...>'; fa = '<several finished products...>';
													|it = '<diverse produzioni...>';
													|pl = '<kilka wyrobów...>';
													|tr = '<birden fazla nihai ürün...>'"),,,, "Decrypt"));
			EndIf;
			
		EndIf;
		
		// Minimum party
		If DataOfActiveLine.MinimumReleaseLot <> 0 Then
			
			Rows.Add(" ");
			
			Rows.Add(NStr("vi = 'Lô hàng tối thiểu :';
							|ru = 'Мин. партия:';
							|en = 'Min. lot:'; fa = 'Min. lot:';
							|it = 'Min. lotto:';
							|pl = 'Min. partia:';
							|tr = 'Min. lot:'") + " ");
			Rows.Add(New FormattedString(Format(DataOfActiveLine.MinimumReleaseLot, "NG="), FontBold));
			Rows.Add(" ");
			Rows.Add(New FormattedString(String.ProductsUnitOfMeasurePresentation, FontBold));
			
		EndIf;
		
		// Optimal batch
		If DataOfActiveLine.EconomicReleaseLot <> 0 Then
			
			Rows.Add(" ");
			
			Rows.Add(NStr("vi = 'Lô hàng bán buôn:';
							|ru = 'Опт. партия:';
							|en = 'Wholesale lot:'; fa = 'Wholesale lot:';
							|it = 'Ott. lotto:';
							|pl = 'Opt. partia:';
							|tr = 'Opt. lot:'") + " ");
			Rows.Add(New FormattedString(Format(DataOfActiveLine.EconomicReleaseLot, "NG="), FontBold));
			Rows.Add(" ");
			Rows.Add(New FormattedString(String.ProductsUnitOfMeasurePresentation, FontBold));
			
		EndIf;
		
		// Provided with components
		If String.SupplyIsRequired
			And String.BillOfMaterials = String.BillOfMaterialsPlan Then
			
			Rows.Add(" ");
			
			Rows.Add(NStr("vi = 'Đã đảm bảo:';
							|ru = 'Обеспечено:';
							|en = 'Supplied:'; fa = 'Supplied:';
							|it = 'Fornito:';
							|pl = 'Supplied:';
							|tr = 'Temin edildi:'") + " ");
			Rows.Add(New FormattedString(Format(String.Supplied, "NZ=0; NG="), FontBold));
			Rows.Add(" ");
			Rows.Add(New FormattedString(String.ProductsUnitOfMeasurePresentation, FontBold));
			
		EndIf;
		
		InformationBar = ?(Rows.UBound() <> -1, New FormattedString(Rows), Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSettingsCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then 
		ChangingParameters = CompareStructuresByKeyFields(DisplayParameters, Result, New Structure("CrossTable,Periodicity,NameOfPeriodDateField,NumberOfPeriods")); 
		FillPropertyValues(DisplayParameters, Result);
		ConfigureDependentFormElements(ThisForm, "DisplayParameters");
		SaveDisplaySettingsAndUpdate(ChangingParameters);
		If StartAwaitingLongAction Then
			StartAwaitingLongAction();
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function CompareStructuresByKeyFields(Structure1, Structure2, FieldsStructure)
		
	For Each KeyAndValue In FieldsStructure Do 
		Value1 = Undefined;	
		Value2 = Undefined;
		If Structure1.Property(KeyAndValue.Key, Value1) And Structure2.Property(KeyAndValue.Key, Value2) 
			And Value1<>Value2 Then 
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure SaveDisplaySettingsAndUpdate(ChangingParameters = True)
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.GeneratingProductionStages",
		"DisplayParameters",
		DisplayParameters);
		
	If Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan And ChangingParameters Then
		ReReadNomenclaturePlanOnServer();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FillOutLaunchPlan(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage = Undefined)
	
	Table = DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage);
	
	// Filling in the quantity
	
	Balance = ?(RowData.Mark, RowData.Launch, 0);
	
	BorderIsNotClosedNeed = -1;
	
	For IndexOf = 0 To Table.Count() - 1 Do
		
		LinePlan = Table[IndexOf];
		
		Launch = Min(LinePlan.Supplied, Balance);
		LinePlan.Launch = ?(Launch = 0, LinePlan.Required2, Launch);
		LinePlan.Mark = Launch <> 0;
		
		Balance = Balance - Launch;
		
		If BorderIsNotClosedNeed = -1 And (LinePlan.Required2 > LinePlan.Launch Or Not LinePlan.Mark) Then
			BorderIsNotClosedNeed = IndexOf;
		EndIf;
		
		If Not LinePlan.Mark And LinePlan.ExceedingOrder Then
			Table.Delete(LinePlan);
		EndIf;
		
	EndDo;
	
	If Balance > 0 And BorderIsNotClosedNeed <> -1 Then
		
		For IndexOf = BorderIsNotClosedNeed To Table.Count() - 1 Do
			
			LinePlan = Table[IndexOf];
			
			Required2 = ?(LinePlan.Mark, LinePlan.Required2 - LinePlan.Launch, LinePlan.Required2);
			
			If Required2 = 0 Then
				Continue;
			EndIf;
			
			Allocated = Min(Required2, Balance);
			LinePlan.Launch = ?(LinePlan.Mark, LinePlan.Launch + Allocated, Allocated);
			LinePlan.Mark = LinePlan.Launch > 0;
			
			Balance = Balance - Allocated;
			
			If Balance = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// Adding a line in excess of the order
	If Balance > 0 Then
		
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Table[0],
			"NumberOfGroup, BillOfMaterials, BillOfMaterialsPlan, LineOfBusiness, ProductionDispatcherBusinessUnit,
			|Products, Characteristic, ItemsType, AssignedPurchaseSale, QuantityPerBatch,
			|ThisIsRMOrReverseKitting, ProductionProcessType");
		
		NewRow.Required2 = 0;
		NewRow.Launch = Balance;
		NewRow.Mark = True;
		NewRow.ExceedingOrder = True;
		NewRow.LineNumber = 100000;
		NewRow.KeyLot = New UUID("00000000-0000-0000-0000-000000000000");
		NewRow.KeyProducts = New UUID("00000000-0000-0000-0000-000000000000");
		NewRow.OrderProducts_ = False;
		NewRow.AvailableReleaseFromAssignedmMaterials = False;
		NewRow.Level = 0;
		NewRow.DurationBeforeProductionIssue = 0;
		NewRow.ProductionLotIDInProductGroup = "";
		NewRow.StartDate2 = '00010101';
		NewRow.DateOfProduction = '00010101';
		NewRow.RequestedCompletionDate = '00010101';
		
		SecurityParameters = ProductionSupply.ProductSupportParameters(
			RowData.Products,
			RowData.Characteristic,
			Table[0].IssuingDivision);
		NewRow.Recipient = ?(ValueIsFilled(SecurityParameters.Warehouse),
			SecurityParameters.Warehouse,
			Table[0].Recipient);
		
		If RowData.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or False Then
			NewRow.Purpose = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(Table[0].ProductionOrder);
		EndIf;
		
	EndIf;
	
	// Updating a table in the repository
	PutPlanInStorage(RowData, Table, AddressPlanStorage);
	
	Return Table;
	
EndFunction

&AtServerNoContext
Procedure PutPlanInStorage(RowData, Table, AddressPlanStorage)
	
	Plan = GetFromTempStorage(AddressPlanStorage);
	If Plan = Undefined Then
		Plan = Table.CopyColumns();
	EndIf;
	
	If RowData.PlanIsInVault Then
		
		TheStructureOfTheSearch = New Structure("NumberOfGroup, Products, Characteristic");
		FillPropertyValues(TheStructureOfTheSearch, RowData);
		
		For Each String In Plan.FindRows(TheStructureOfTheSearch) Do
			Plan.Delete(String);
		EndDo;
		
	EndIf;
	
	If RowData.Mark Then
		
		For Each String In Table Do
			FillPropertyValues(Plan.Add(), String);
		EndDo;
		
	EndIf;
	
	RowData.PlanIsInVault = RowData.Mark;
	PutToTempStorage(Plan, AddressPlanStorage);
	
EndProcedure

&AtClientAtServerNoContext
Function LinePlanTotalsInStructure(String)
	
	Result = New Structure;
	Result.Insert("Id", String.GetID());
	Result.Insert("LineNumber", String.LineNumber);
	Result.Insert("NumberOfGroup", String.NumberOfGroup);
	Result.Insert("Organization", String.Organization);
	Result.Insert("Partner", String.Partner);
	Result.Insert("Contract", String.Contract);
	Result.Insert("LineOfBusiness", String.LineOfBusiness);
	Result.Insert("ProductionDispatcherBusinessUnit", String.ProductionDispatcherBusinessUnit);
	Result.Insert("OrderForActivity", String.OrderForActivity);
	Result.Insert("BusinessOperation", String.BusinessOperation);
	Result.Insert("BillOfMaterials", String.BillOfMaterials);
	Result.Insert("BillOfMaterialsPlan", String.BillOfMaterialsPlan);
	Result.Insert("Products", String.Products);
	Result.Insert("Characteristic", String.Characteristic);
	Result.Insert("MultipleLaunch", String.MultipleLaunch);
	Result.Insert("Mark", String.Mark);
	Result.Insert("Launch", String.Launch);
	Result.Insert("Required2", String.Required2);
	Result.Insert("SupplyIsRequired", String.SupplyIsRequired);
	Result.Insert("Supplied", String.Supplied);
	Result.Insert("Regroup", String.Regroup);
	Result.Insert("MainProduct", String.MainProduct);
	Result.Insert("PlanIsInVault", String.PlanIsInVault);
	Result.Insert("QuantityPerBatch", String.QuantityPerBatch);
	
	Return Result;
	
EndFunction

// Returns products to launch with details up to orders for a given set of analytics.
// It also fills in the security parameters in the received row data.
// 
// Returns:
//  ValueTable - Detail record
&AtServerNoContext
Function DetailedRecords(RowData, AddressPlanStorage, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts, DetailedRecordsPackage = Undefined)
	
	If RowData.PlanIsInVault Then
		
		Plan = GetFromTempStorage(AddressPlanStorage);
		
		TheStructureOfTheSearch = New Structure("NumberOfGroup, Products, Characteristic");
		FillPropertyValues(TheStructureOfTheSearch, RowData);
		
		Table = Plan.Copy(TheStructureOfTheSearch);
		Table.Sort("LineNumber");
		
	ElsIf DetailedRecordsPackage <> Undefined Then
		
		TheStructureOfTheSearch = New Structure("NumberOfGroup, Products, Characteristic");
		FillPropertyValues(TheStructureOfTheSearch, RowData);
		
		Table = DetailedRecordsPackage.Copy(TheStructureOfTheSearch);
		Table.Sort("LineNumber");
		
	Else
		
		Table_Selection = NewSelectionDetailedRecords();
		FillPropertyValues(Table_Selection.Add(), RowData);
		
		Table = DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts);
		
	EndIf;
	
	Return Table;
	
EndFunction

&AtServerNoContext
Function DetailedRecordingsInBatches(Table_Selection, AddressCustomSelections, SeparateProductionOfSemiFinishedProducts)
	
	Query = New Query;
	
	QueryTexts = New Array;
	
	QueryTexts.Add(
		"SELECT
		|	Table_Selection.Products            AS Products,
		|	Table_Selection.Characteristic          AS Characteristic,
		|	Table_Selection.BillOfMaterials            AS BillOfMaterials,
		|	Table_Selection.BillOfMaterialsPlan        AS BillOfMaterialsPlan,
		|	Table_Selection.Organization             AS Organization,
		|	Table_Selection.Partner                 AS Partner,
		|	Table_Selection.Contract                 AS Contract,
		|	Table_Selection.LineOfBusiness AS LineOfBusiness,
		|	Table_Selection.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
		|	Table_Selection.OrderForActivity    AS OrderForActivity,
		|	Table_Selection.BusinessOperation   AS BusinessOperation,
		|	Table_Selection.NumberOfGroup             AS NumberOfGroup,
		|	Table_Selection.QuantityPerBatch      AS QuantityPerBatch
		|INTO Table_Selection
		|FROM
		|	&Table_Selection AS Table_Selection
		|
		|INDEX BY
		|	Products, Characteristic, BillOfMaterialsPlan, Organization, Partner, Contract, LineOfBusiness, ProductionDispatcherBusinessUnit, OrderForActivity, BusinessOperation");
	
	TextNomenclaturePlan = 
		"SELECT
		|	Plan.BillOfMaterials                                  AS BillOfMaterials,
		|	Plan.ProductionOrder                           AS ProductionOrder,
		|	Plan.ProductionOrder.Organization               AS Organization,
		|	Plan.ProductionOrder.Partner                   AS Partner,
		|	Plan.ProductionOrder.Contract                   AS Contract,
		|	Plan.ProductionOrder.LineOfBusiness   AS LineOfBusiness,
		|	Plan.ProductionOrder.Department             AS ProductionDispatcherBusinessUnit,
		|	Plan.ProductionOrder.OrderForActivity      AS OrderForActivity,
		|	Plan.ProductionOrder.BusinessOperation     AS BusinessOperation,
		|	Plan.Products                                  AS Products,
		|	Plan.Characteristic                                AS Characteristic,
		|	Plan.Warehouse                                         AS Warehouse,
		|	Plan.Purpose                                    AS Purpose,  
		|	Plan.KeyProducts                              AS KeyProducts,
		|	Plan.KeyLot                                    AS KeyLot,
		|	ISNULL(Consumption.StructureAssignment, Plan.Purpose) AS AssignmentRecipient,
		|	Plan.Products.ProductKind                  AS ProductKind,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairProduct, VALUE(Catalog.Products.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairProduct
		|	END                                              AS UnderRepairProduct,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairVariant, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairVariant
		|	END                                              AS UnderRepairVariant,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairBatch, VALUE(Catalog.ItemsBatches.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairBatch
		|	END                                              AS UnderRepairBatch,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))          AS StartDate2,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))       AS DateOfProduction,
		|	ISNULL(ConsumptionSchedule.Begin, DATETIME(1,1,1)) AS RequestedCompletionDate,
		|	MAX(Plan.QuantityForLaunchLotUnit)    AS QuantityForLaunchLotUnit,
		|	MAX(Plan.Level)                             AS Level,
		|	MAX(Plan.DurationBeforeProductionIssue)               AS DurationBeforeProductionIssue,
		|	MIN(Plan.ProductionLotIDInProductGroup)          AS ProductionLotIDInProductGroup,
		|	MAX(Plan.Department)                       AS IssuingDivision,
		|	SUM(Plan.Scheduled) + SUM(Plan.ReverseKittingScheduled) AS Required2
		|INTO ItemPlan
		|FROM
		|	InformationRegister.OrderStructure AS Plan
		|	
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Plan.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Plan.KeyLot = Schedule.KeyLot
		|		AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|	
		|	LEFT JOIN InformationRegister.OrderStructure AS Consumption
		|	ON Plan.Products = Consumption.Products
		|		AND Plan.Characteristic = Consumption.Characteristic
		|		AND Plan.Warehouse = Consumption.Warehouse
		|		AND Plan.Purpose = Consumption.Purpose
		|		AND Plan.ProductionOrder = Consumption.ProductionOrder
		|		AND Plan.KeyProducts = Consumption.KeyProducts
		|		AND Consumption.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		AND NOT Consumption.AdditionalRecord
		|	
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ConsumptionSchedule
		|	ON Consumption.ProductionOrder = ConsumptionSchedule.ProductionOrder
		|		AND ConsumptionSchedule.ScheduleStatus = 0
		|		AND Consumption.KeyLot = ConsumptionSchedule.KeyLot
		|		AND Consumption.Stage = ConsumptionSchedule.Stage
		|	
		|	LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS RepairWorkSupply
		|	ON Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|		AND Consumption.Stage = RepairWorkSupply.Ref
		|		AND Consumption.KeyProducts = RepairWorkSupply.KeyProducts
		|
		|	LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
		|	ON Plan.ProductionOrder = OrderProducts_.Ref
		|		AND Plan.Products = OrderProducts_.Products
		|		AND Plan.KeyProducts = OrderProducts_.KeyProducts
		|WHERE
		|	(
		|		Plan.Products,
		|		Plan.Characteristic,
		|		Plan.BillOfMaterials,
		|		Plan.ProductionOrder.Organization,
		|		Plan.ProductionOrder.Partner,
		|		Plan.ProductionOrder.Contract,
		|		Plan.ProductionOrder.LineOfBusiness,
		|		Plan.ProductionOrder.Department,
		|		Plan.ProductionOrder.OrderForActivity,
		|		Plan.ProductionOrder.BusinessOperation
		|	) IN (
		|		SELECT
		|			Table_Selection.Products,
		|			Table_Selection.Characteristic,
		|			Table_Selection.BillOfMaterialsPlan,
		|			Table_Selection.Organization,
		|			Table_Selection.Partner,
		|			Table_Selection.Contract,
		|			Table_Selection.LineOfBusiness,
		|			Table_Selection.ProductionDispatcherBusinessUnit,
		|			Table_Selection.OrderForActivity,
		|			Table_Selection.BusinessOperation
		|		FROM
		|			Table_Selection AS Table_Selection)
		|	AND Plan.LineKind IN (
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
		|	AND &CustomFilters
		|
		|GROUP BY
		|	Plan.BillOfMaterials,
		|	Plan.ProductionOrder.Organization,
		|	Plan.ProductionOrder.Partner,
		|	Plan.ProductionOrder.Contract,
		|	Plan.ProductionOrder.LineOfBusiness,
		|	Plan.ProductionOrder.Department,
		|	Plan.ProductionOrder.OrderForActivity,
		|	Plan.ProductionOrder.BusinessOperation,
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.Warehouse,
		|	Plan.Purpose,
		|	Plan.ProductionOrder,
		|	Plan.KeyProducts,
		|	Plan.KeyLot,
		|	ISNULL(Consumption.StructureAssignment, Plan.Purpose),
		|	Plan.Products.ProductKind,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairProduct, VALUE(Catalog.Products.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairProduct
		|	END,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairVariant, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairVariant
		|	END,
		|	CASE
		|		WHEN OrderProducts_.Ref IS NULL
		|			THEN ISNULL(RepairWorkSupply.UnderRepairBatch, VALUE(Catalog.ItemsBatches.EmptyRef))
		|		ELSE Plan.ProductionOrder.UnderRepairBatch
		|	END,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1)),
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1)),
		|	ISNULL(ConsumptionSchedule.Begin, DATETIME(1,1,1))
		|
		|HAVING
		|	SUM(Plan.Scheduled) <> 0
		|	OR SUM(Plan.ReverseKittingScheduled) <> 0";
	
	CustomFilters = GetFromTempStorage(AddressCustomSelections);
	
	// Substitution of connections and selections with additional Attributes
	If CustomFilters <> Undefined
		And CustomFilters.ConnectionsWithAdditionalAttributes.Count() > 0 Then
		QuerySchema = New QuerySchema;
		QuerySchema.SetQueryText(TextNomenclaturePlan);
		
		Operator = QuerySchema.QueryBatch[0].Operators[0]; // QuerySchemaSelectOperator
		NewSources = New Map;
		
		For Each Source In Operator.Sources Do
			If TypeOf(Source.Source) <> Type("QuerySchemaTable")
				Or Source.Source.TableName <> "InformationRegister.OrderStructure" Then
				Continue;
			EndIf;
			
			ConnectionsWithAdditionalAttributes = CustomFilters.ConnectionsWithAdditionalAttributes; // ValueTable
			For Each String In ConnectionsWithAdditionalAttributes Do
				NewSource = NewSources.Get(String.Alias);
				If NewSource = Undefined Then
					NewSource = Operator.Sources.Add(String.TableName, String.Alias);
					NewSources.Insert(String.Alias, NewSource);
				EndIf;
				NewConnection_ = Source.Joins.Add(NewSource, String.Condition);
			EndDo;
			
			Break;
		EndDo;
		
		TextNomenclaturePlan = QuerySchema.GetQueryText();
		
		ConnectionParametersWithAdditionalAttributes = CustomFilters.ConnectionParametersWithAdditionalAttributes; // Map
		For Each KeyAndValue In ConnectionParametersWithAdditionalAttributes Do
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	// Substitution of simple selections
	If CustomFilters = Undefined
		Or CustomFilters.Filters.Count() = 0 Then
		TextNomenclaturePlan = StrReplace(TextNomenclaturePlan, "AND &CustomFilters", "");
	Else
		SelectionText_ = "";
		For Each Filter In CustomFilters.Filters Do
			SelectionText_ = SelectionText_ + " And " + Filter.Text;
			Query.SetParameter(Filter.Name, Filter.Value);
		EndDo;
		TextNomenclaturePlan = StrReplace(TextNomenclaturePlan, "AND &CustomFilters", SelectionText_);
	EndIf;
	
	QueryTexts.Add(TextNomenclaturePlan);
	
	QueryTexts.Add(
		"SELECT
		|	Plan.BillOfMaterials                                AS BillOfMaterials,
		|	Plan.ProductKind                             AS ProductKind,
		|	Plan.Products                                AS Products,
		|	Plan.Characteristic                              AS Characteristic,
		|	Plan.KeyLot                                  AS KeyLot,
		|	SUM(Plan.Required2)                            AS Required2,
		|	MAX(Plan.QuantityForLaunchLotUnit)  AS QuantityForLaunchLotUnit
		|
		|INTO NomenclaturePlanWithoutDetails
		|FROM
		|	ItemPlan AS Plan
		|
		|GROUP BY
		|	Plan.BillOfMaterials,
		|	Plan.ProductKind,
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.KeyLot
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrderStructure.PermissionToReplace AS PermissionToReplace
		|INTO AppliedPermissionsInBatches
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&UseAlternativeMaterials
		|	AND OrderStructure.KeyLot IN
		|			(SELECT
		|				DD.KeyLot
		|			FROM
		|				NomenclaturePlanWithoutDetails AS DD)
		|
		|INDEX BY
		|	PermissionToReplace
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AlternativeMaterials.Recorder AS Resolution,
		|	AlternativeMaterials.Products AS Products,
		|	AlternativeMaterials.Characteristic AS Characteristic,
		|	AlternativeMaterials.ProductsRole AS ProductsRole,
		|	SUM(AlternativeMaterials.Count) AS Count
		|INTO CoefficientsOfNomenclatureOfReplacementPermits
		|FROM
		|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
		|WHERE
		|	&UseAlternativeMaterials
		|	AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				AppliedPermissionsInBatches AS Table
		|			WHERE
		|				Table.PermissionToReplace = AlternativeMaterials.Recorder)
		|
		|GROUP BY
		|	AlternativeMaterials.Recorder,
		|	AlternativeMaterials.Products,
		|	AlternativeMaterials.Characteristic,
		|	AlternativeMaterials.ProductsRole
		|
		|INDEX BY
		|	Resolution,
		|	Products,
		|	Characteristic,
		|	ProductsRole
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalogCoefficients.Resolution AS Resolution,
		|	AnalogCoefficients.Products AS Products,
		|	AnalogCoefficients.Characteristic AS Characteristic,
		|	AnalogCoefficients.Count AS Denominator,
		|	MIN(MaterialCoefficients.Count) AS Numerator
		|INTO CoefficientOfPermissionsByAnalogy
		|FROM
		|	CoefficientsOfNomenclatureOfReplacementPermits AS AnalogCoefficients
		|		INNER JOIN CoefficientsOfNomenclatureOfReplacementPermits AS MaterialCoefficients
		|		ON (AnalogCoefficients.Resolution = MaterialCoefficients.Resolution)
		|			AND (NOT(AnalogCoefficients.Products = MaterialCoefficients.Products
		|					AND AnalogCoefficients.Characteristic = MaterialCoefficients.Characteristic))
		|			AND (MaterialCoefficients.ProductsRole IN (VALUE(Enum.SubstituteRoles.Material), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)))
		|WHERE
		|	&UseAlternativeMaterials
		|	AND AnalogCoefficients.ProductsRole IN (VALUE(Enum.SubstituteRoles.Substitute), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
		|	AND AnalogCoefficients.Count <> 0
		|
		|GROUP BY
		|	AnalogCoefficients.Resolution,
		|	AnalogCoefficients.Products,
		|	AnalogCoefficients.Characteristic,
		|	AnalogCoefficients.Count
		|
		|INDEX BY
		|	Resolution,
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	MAX(NestedQuery.EatSeparately) AS EatSeparately,
		|	MIN(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit) AS NumberOfPartiesIsProvided,
		|	MIN(NestedQuery.Required2 = NestedQuery.Allocated) AS ThereIsFullProvision,
		|	MIN(NestedQuery.Required2 = NestedQuery.Allocated) = FALSE
		|	AND MAX(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit)
		|		> MIN(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit) AS PartialSupplyIsAvailable
		|INTO TTSoftware
		|FROM
		|	(
		|	SELECT
		|		SupplyWithAnalogues.KeyLot AS KeyLot,
		|		SupplyWithAnalogues.KeyProducts AS KeyProducts,
		|		MAX(SupplyWithAnalogues.EatSeparately) AS EatSeparately,
		|		SUM(SupplyWithAnalogues.Allocated) AS Allocated,
		|		SUM(SupplyWithAnalogues.Required2) AS Required2,
		|		MAX(SupplyWithAnalogues.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit
		|	FROM
		|		(SELECT
		|			OrderStructure.KeyLot AS KeyLot,
		|			OrderStructure.KeyProducts AS KeyProducts,
		|			OrderStructure.ProductionOrder AS ProductionOrder,
		|			OrderStructure.PermissionToReplace AS PermissionToReplace,
		|			SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) > 0
		|					OR MAX(OrderStructure.Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS EatSeparately,
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment
		|					ELSE 0
		|				END) AS Allocated,
		|			SUM(CASE
		|					WHEN OrderStructure.ConnectionKeyTransfer = &EmptyKey
		|						THEN OrderStructure.ToSupply
		|					ELSE 0
		|				END) AS Required2,
		|			MAX(OrderStructure.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|		WHERE
		|			OrderStructure.KeyLot IN
		|					(SELECT
		|						DD.KeyLot
		|					FROM
		|						NomenclaturePlanWithoutDetails AS DD)
		|			AND OrderStructure.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|		
		|		GROUP BY
		|			OrderStructure.KeyLot,
		|			OrderStructure.KeyProducts,
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace
		|		
		|		HAVING
		|			MAX(OrderStructure.QuantityForLaunchLotUnit) > 0 AND
		|			SUM(CASE
		|					WHEN OrderStructure.ConnectionKeyTransfer = &EmptyKey
		|						THEN OrderStructure.ToSupply
		|					ELSE 0
		|				END) > 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			OrderStructure.KeyLot,
		|			MAX(CASE
		|				WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|					AND OrderStructure.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|					THEN OrderStructure.ConnectionKeyTransfer
		|			END),
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace,
		|			SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) > 0
		|					OR MAX(OrderStructure.Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS EatSeparately,
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN (OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) / AlternativeMaterials.Denominator * AlternativeMaterials.Numerator
		|					ELSE 0
		|				END),
		|			0,
		|			0
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|				INNER JOIN CoefficientOfPermissionsByAnalogy AS AlternativeMaterials
		|				ON OrderStructure.Products = AlternativeMaterials.Products
		|					AND OrderStructure.Characteristic = AlternativeMaterials.Characteristic
		|					AND OrderStructure.PermissionToReplace = AlternativeMaterials.Resolution
		|		WHERE
		|			&UseAlternativeMaterials
		|			AND OrderStructure.KeyLot IN
		|					(SELECT
		|						DD.KeyLot
		|					FROM
		|						NomenclaturePlanWithoutDetails AS DD)
		|			AND OrderStructure.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|		
		|		GROUP BY
		|			OrderStructure.KeyLot,
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace
		|		
		|		HAVING
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN (OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) / AlternativeMaterials.Denominator * AlternativeMaterials.Numerator
		|					ELSE 0
		|				END) > 0) AS SupplyWithAnalogues
		|	
		|	GROUP BY
		|		SupplyWithAnalogues.KeyLot,
		|		SupplyWithAnalogues.KeyProducts
		|	
		|	HAVING
		|		MAX(SupplyWithAnalogues.QuantityForLaunchLotUnit) <> 0
		|) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyLot
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|
		|	Plan.KeyLot AS KeyLot,
		|
		|	SUM(CASE
		|		WHEN Supply.NumberOfPartiesIsProvided IS NULL OR Supply.NumberOfPartiesIsProvided = 0
		|			THEN 0
		|		WHEN Supply.ThereIsFullProvision
		|			THEN Plan.Required2
		|		WHEN Plan.BillOfMaterials.ProductionIssueByCustomPortions
		|			THEN CASE
		|				WHEN Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit >= Plan.Required2
		|					THEN Plan.Required2
		|				WHEN Plan.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					THEN CAST(Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit - 0.5 AS NUMBER(15, 0))
		|				ELSE Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit
		|			END
		|		ELSE CASE
		|			WHEN CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit >= Plan.Required2
		|				THEN Plan.Required2
		|			WHEN Plan.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|				THEN CAST(CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit - 0.5 AS NUMBER(15, 0))
		|			ELSE CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit
		|		END
		|	END) AS Supplied,
		|
		|	MAX(Supply.PartialSupplyIsAvailable) AS PartialSupplyIsAvailable
		|
		|FROM
		|	NomenclaturePlanWithoutDetails AS Plan
		|	
		|	INNER JOIN TTSoftware AS Supply
		|	ON Plan.KeyLot = Supply.KeyLot
		|
		|GROUP BY
		|	Plan.KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Plan.BillOfMaterials                               AS BillOfMaterialsPlan,
		|	Plan.LineOfBusiness                    AS LineOfBusiness,
		|	Plan.ProductionDispatcherBusinessUnit                     AS ProductionDispatcherBusinessUnit,
		|
		|	Plan.Products                               AS Products,
		|	Plan.Products.ItemsType               AS ItemsType,
		|	Plan.Products.AssignedPurchaseSale    AS AssignedPurchaseSale,
		|	Plan.Products.ProductKind               AS ProductKind,
		|	Plan.Characteristic                             AS Characteristic,
		|	Plan.Warehouse                                      AS Recipient,
		|
		|	&TextOfMaterialsAssignmentField AS AssignmentMaterials,
		|	Plan.AssignmentRecipient      AS AssignmentRecipient,
		|	CASE
		|		WHEN Plan.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				AND &SeparateProductionOfSemiFinishedProducts
		|				AND OrderProducts_.Ref IS NULL
		|			THEN 
		|				Plan.AssignmentRecipient
		|			ELSE 
		|				Plan.Purpose
		|	END AS Purpose,
		|	CASE
		|		WHEN Plan.ProductionOrder.OptionOfAssignment IN (
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
		|			THEN Plan.ProductionOrder.Purpose
		|		WHEN Plan.ProductionOrder.OptionOfAssignment = VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts)
		|				AND Plan.ProductionOrder.Purpose <> 
		|					CASE
		|						WHEN OrderProducts_.Ref IS NOT NULL
		|								OR Plan.Purpose <> VALUE(Catalog.Assignments.EmptyRef) THEN
		|							Plan.Purpose
		|						ELSE
		|							CASE
		|								WHEN &SeparateProductionOfSemiFinishedProducts 
		|									OR TRUE IN
		|									(SELECT
		|										DD.EatSeparately
		|									FROM
		|										TTSoftware AS DD
		|									WHERE
		|										DD.KeyLot = Plan.KeyLot) THEN
		|									Plan.AssignmentRecipient
		|								ELSE
		|									VALUE(Catalog.Assignments.EmptyRef)
		|							END
		|					END
		|			THEN 
		|					CASE
		|						WHEN OrderProducts_.Ref IS NOT NULL
		|								OR Plan.Purpose <> VALUE(Catalog.Assignments.EmptyRef) THEN
		|							Plan.Purpose
		|						ELSE
		|							CASE
		|								WHEN &SeparateProductionOfSemiFinishedProducts 
		|									OR TRUE IN
		|									(SELECT
		|										DD.EatSeparately
		|									FROM
		|										TTSoftware AS DD
		|									WHERE
		|										DD.KeyLot = Plan.KeyLot) THEN
		|									Plan.AssignmentRecipient
		|								ELSE
		|									VALUE(Catalog.Assignments.EmptyRef)
		|							END
		|					END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS AssignmentProducts,
		|
		|	Plan.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND NOT (&SeparateProductionOfSemiFinishedProducts
		|				AND OrderProducts_.Ref IS NULL)
		|		AND TRUE IN
		|			(SELECT
		|				DD.EatSeparately
		|			FROM
		|				TTSoftware AS DD
		|			WHERE
		|				DD.KeyLot = Plan.KeyLot) AS AvailableReleaseFromAssignedmMaterials,
		|
		|	Plan.ProductionOrder                        AS ProductionOrder,
		|	Plan.ProductionOrder.Priority              AS Priority,
		|	Plan.ProductionOrder.Number                  AS ProductionOrderNumber,
		|	Plan.ProductionOrder.Date                   AS ProductionOrderDate,
		|	Plan.ProductionOrder.ProductionProcessType IN (
		|		VALUE(Enum.ProductionProcessTypes.PerformRM),
		|		VALUE(Enum.ProductionProcessTypes.Disassembly)) AS ThisIsRMOrReverseKitting,
		|	Plan.ProductionOrder.ProductionProcessType              AS ProductionProcessType,
		|
		|	OrderProducts_.Ref IS NOT NULL                              AS OrderProducts_,
		|	ISNULL(OrderProducts_.LineNumber, 10000000)                  AS LineNumberProducts,
		|	ISNULL(OrderProducts_.ToExpenseAs, FALSE)                 AS ToExpenseAs,
		|	ISNULL(OrderProducts_.ExpenseItem, UNDEFINED)           AS ExpenseItem,
		|	ISNULL(OrderProducts_.DimensionOfExpenses, UNDEFINED)        AS DimensionOfExpenses,
		|	ISNULL(OrderProducts_.AssetsLiabilitiesDimension, UNDEFINED) AS AssetsLiabilitiesDimension,
		|	
		|	Plan.BusinessOperation              AS BusinessOperation,
		|	Plan.UnderRepairProduct   AS UnderRepairProduct,
		|	Plan.UnderRepairVariant AS UnderRepairVariant,
		|	Plan.UnderRepairBatch          AS UnderRepairBatch,
		|	
		|	Plan.StartDate2                                AS StartDate2,
		|	Plan.DateOfProduction                                AS DateOfProduction,
		|
		|	ISNULL(OrderProducts_.DemandDate, Plan.RequestedCompletionDate) AS RequestedCompletionDate,
		|
		|	Plan.KeyLot                                 AS KeyLot,
		|	Plan.KeyProducts                           AS KeyProducts,
		|	Plan.Level                                    AS Level,
		|	Plan.DurationBeforeProductionIssue                      AS DurationBeforeProductionIssue,
		|	Plan.ProductionLotIDInProductGroup                AS ProductionLotIDInProductGroup,
		|	Plan.IssuingDivision                   AS IssuingDivision,
		|
		|	Plan.Required2                                  AS Required2,
		|	Plan.Required2                                  AS Launch,
		|
		|	ISNULL(Table_Selection.NumberOfGroup, 0)                  AS NumberOfGroup,
		|	ISNULL(Table_Selection.BillOfMaterials, Plan.BillOfMaterials) AS BillOfMaterials,
		|	ISNULL(Table_Selection.QuantityPerBatch, Plan.QuantityForLaunchLotUnit) AS QuantityPerBatch
		|FROM
		|	ItemPlan AS Plan
		|		
		|		LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
		|		ON Plan.ProductionOrder = OrderProducts_.Ref
		|			AND Plan.Products = OrderProducts_.Products
		|			AND Plan.KeyProducts = OrderProducts_.KeyProducts
		|		
		|		LEFT JOIN Table_Selection AS Table_Selection
		|		ON Plan.Products = Table_Selection.Products
		|			AND Plan.Characteristic = Table_Selection.Characteristic
		|			AND Plan.BillOfMaterials = Table_Selection.BillOfMaterialsPlan
		|			AND Plan.Organization = Table_Selection.Organization
		|			AND Plan.Partner = Table_Selection.Partner
		|			AND Plan.Contract = Table_Selection.Contract
		|			AND Plan.LineOfBusiness = Table_Selection.LineOfBusiness
		|			AND Plan.ProductionDispatcherBusinessUnit = Table_Selection.ProductionDispatcherBusinessUnit
		|			AND Plan.OrderForActivity = Table_Selection.OrderForActivity
		|			AND Plan.BusinessOperation = Table_Selection.BusinessOperation
		|
		|ORDER BY
		|	NumberOfGroup,
		|	Plan.ProductionOrder.Priority.AddlOrderingAttribute,
		|	Plan.ProductionOrder.Department.AddlOrderingAttribute,
		|	Plan.ProductionOrder.Queue,
		|	-Plan.DurationBeforeProductionIssue,
		|	Plan.ProductionLotIDInProductGroup,
		|	Plan.StartDate2,
		|	Plan.Required2 DESC,
		|	Plan.KeyLot,
		|	Plan.KeyProducts");
	
	QueryText = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
	QueryText = StrReplace(QueryText,
		"&TextOfMaterialsAssignmentField",
		OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
			"Plan.ProductionOrder", "Plan.AssignmentRecipient"));
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	Query.Text = QueryText;
	Query.SetParameter("Table_Selection", Table_Selection);
	Query.SetParameter("SeparateProductionOfSemiFinishedProducts", SeparateProductionOfSemiFinishedProducts);
	Query.SetParameter("EmptyKey", CommonClientServer.BlankUUID());
	Query.SetParameter("UseAlternativeMaterials", GetFunctionalOption("UseAlternativeMaterials"));
	
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	ProvisionOfParties = QueryResult[NumberOfPackages_-2].Unload();
	ProvisionOfParties.Indexes.Add("KeyLot");
	
	Table = QueryResult[NumberOfPackages_-1].Unload();
	
	ListDimensionFields = New Array();
	ExceptionFields = "KeyProducts,Level,DurationBeforeProductionIssue,ProductionLotIDInProductGroup,QuantityPerBatch,Required2,Launch,AvailableReleaseFromAssignedmMaterials";
	ListOfExceptionFields = StrSplit(ExceptionFields, ",");
	For Each Column In Table.Columns Do
		If ListOfExceptionFields.Find(Column.Name) = Undefined Then
			ListDimensionFields.Add(Column.Name);
		EndIf;
	EndDo;
	GroupFields = StrConcat(ListDimensionFields,",");
	Table.Indexes.Add(GroupFields);
	FilterStructure1 = New Structure(GroupFields);
	
	Table.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers()));
	Table.Columns.Add("Mark", New TypeDescription("Boolean"));
	Table.Columns.Add("ExceedingOrder", New TypeDescription("Boolean"));
	Table.Columns.Add("ProductionOrderPresentation", New TypeDescription("String"));
	Table.Columns.Add("SupplyIsRequired", New TypeDescription("Boolean"));
	Table.Columns.Add("Supplied", New TypeDescription("Number", New NumberQualifiers()));
	Table.Columns.Add("PartialSupplyIsAvailable", New TypeDescription("Boolean"));
	
	NumberOfGroup = -1;
	LineNumber = 1;
	For IndexOf = 0 To Table.Count()-1 Do
		
		String = Table[IndexOf];
		
		If String.NumberOfGroup <> NumberOfGroup Then
			NumberOfGroup = String.NumberOfGroup;
			LineNumber = 1;
		EndIf;
		
		Supply = ProvisionOfParties.Find(String.KeyLot, "KeyLot");
		If Supply <> Undefined Then
			String.SupplyIsRequired = True;
			String.PartialSupplyIsAvailable = Supply.PartialSupplyIsAvailable;
			String.Supplied = Min(String.Required2, Supply.Supplied);
			Supply.Supplied = Supply.Supplied - String.Supplied;
		EndIf;
		
		TotalString = Undefined;
		FillPropertyValues(FilterStructure1, String);
		FoundRows = Table.FindRows(FilterStructure1);
		If FoundRows.Count() > 1 Then
			For Each FoundRow In FoundRows Do
				If FoundRow.LineNumber > 0 Then // the string is initialized
					TotalString = FoundRow;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If TotalString = Undefined Then
			String.LineNumber = LineNumber;
			String.ProductionOrderPresentation = StrTemplate(NStr("vi = '%1 ngày %2';
																	|ru = '%1 от %2';
																	|en = '%1 from %2'; fa = '%1 from %2';
																	|it = '%1 del %2';
																	|pl = '%1 z dn. %2';
																	|tr = '%2 tarihli %1'"),
				String.ProductionOrderNumber,
				Format(String.ProductionOrderDate, "DLF=D"));
			LineNumber = LineNumber + 1;
		Else
			TotalString.Required2  = TotalString.Required2 + String.Required2;
			TotalString.Supplied = TotalString.Supplied + String.Supplied;
			TotalString.Launch   = TotalString.Launch + String.Launch;
			
			TotalString.SupplyIsRequired = TotalString.SupplyIsRequired
				Or String.SupplyIsRequired;
			TotalString.PartialSupplyIsAvailable = TotalString.PartialSupplyIsAvailable
				Or String.PartialSupplyIsAvailable;
			TotalString.AvailableReleaseFromAssignedmMaterials = TotalString.AvailableReleaseFromAssignedmMaterials
				Or String.AvailableReleaseFromAssignedmMaterials;
		EndIf;
		
	EndDo;
	
	Table.Indexes.Delete(0);
	
	LinesToDelete = Table.FindRows(New Structure("LineNumber", 0));
	For Each String In LinesToDelete Do
		Table.Delete(String);
	EndDo;
	
	Table.Indexes.Add("NumberOfGroup, Products, Characteristic");
	
	Return Table;
	
EndFunction

&AtServerNoContext
Function NewSelectionDetailedRecords()
	
	Table_Selection = New ValueTable;
	
	// Fields for selecting parts
	Table_Selection.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table_Selection.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table_Selection.Columns.Add("BillOfMaterialsPlan", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table_Selection.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	Table_Selection.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	Table_Selection.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
	Table_Selection.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	Table_Selection.Columns.Add("ProductionDispatcherBusinessUnit", New TypeDescription("CatalogRef.BusinessStructure"));
	Table_Selection.Columns.Add("OrderForActivity", New TypeDescription("EnumRef.VATTaxationTypes"));
	Table_Selection.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	
	// Inheritance fields in details
	Table_Selection.Columns.Add("NumberOfGroup", New TypeDescription("Number", New NumberQualifiers()));
	Table_Selection.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table_Selection.Columns.Add("QuantityPerBatch", New TypeDescription("Number", New NumberQualifiers()));
	
	Return Table_Selection;
	
EndFunction

#EndRegion

#Region Preview

&AtClient
Procedure GoToPreviewStepOnClient()
	
	ClearMessages();
	
	Cancel = False;
	FillInItemsForPreview(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	InstallAssistantPages(ThisForm, "StepPreview");
	
EndProcedure

&AtClient
Procedure GoBackToPreviewStepOnClient()
	
	ClearMessages();
	
	If CreatedObjects.Count() <> 0 Then
		
		Cancel = False;
		Delete_CreatedObjects(Cancel);
		
		If StartAwaitingLongAction Then
			StartAwaitingLongAction(False);
			SetUpWaitingInForm(True, NStr("vi = 'Đang xóa chứng từ...';
											|ru = 'Документы удаляются...';
											|en = 'Documents are being deleted...'; fa = 'Documents are being deleted...';
											|it = 'Documenti in eliminazione...';
											|pl = 'Trwa usunięcie dokumentów...';
											|tr = 'Belgeler siliniyor...'"));
		Else
			AfterDeletingCreatedObjects(Cancel);
		EndIf;
		
	Else
		InstallAssistantPages(ThisForm, "StepPreview");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInItemsForPreview(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		Return;
	EndIf;
	
	Data = DataToBeGenerated();
	If Data = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	ProductsToPreview.GetItems().Clear();
	
	Data.Groups.Indexes.Add("NumberOfGroup");
	
	NumberOfGroup = Undefined;
	BatchNumberInGroup = Undefined;
	
	GroupRow = Undefined;
	NewLineSummary = Undefined;
	ReverseKittingOnly = True;
	
	For IndexOf = 0 To Data.Products_1.Count() - 1 Do
		
		RowOfProducts = Data.Products_1[IndexOf];
		
		If NumberOfGroup <> RowOfProducts.NumberOfGroup
			Or BatchNumberInGroup <> RowOfProducts.BatchNumberInGroup Then
			
			If NumberOfGroup <> RowOfProducts.NumberOfGroup Then
				GroupRow = Data.Groups.Find(RowOfProducts.NumberOfGroup, "NumberOfGroup");
			EndIf;
			
			NewLineSummary = ProductsToPreview.GetItems().Add();
			FillPropertyValues(NewLineSummary, GroupRow,
				"BillOfMaterials, Organization, Partner, Contract, LineOfBusiness,
				|ProductionDispatcherBusinessUnit, OrderForActivity, BusinessOperation, ProductionProcessType");
			FillPropertyValues(NewLineSummary, RowOfProducts,
				"Products, Characteristic, NumberOfGroup, BatchNumberInGroup");
			NewLineSummary.ProductionOrder = GroupRow.ReferenceOrder;
			NewLineSummary.EarliestStartDate = RowOfProducts.StartDate2;
			NewLineSummary.DemandDate = RowOfProducts.RequestedCompletionDate;
			If GroupRow.ReferenceOrder.IsEmpty() Then
				NewLineSummary.ProductionOrderPresentation = NStr("vi = '<đơn hàng sản xuất mới>';
																	|ru = '<новый заказ на производство>';
																	|en = '<new production order>'; fa = '<new production order>';
																	|it = '<nuovo ordine di produzione>';
																	|pl = '<nowe zlecenie produkcyjne>';
																	|tr = '<yeni üretim emri>'");
			Else
				NewLineSummary.ProductionOrderPresentation = StrTemplate(NStr("vi = '%1 ngày %2';
																				|ru = '%1 от %2';
																				|en = '%1 from %2'; fa = '%1 from %2';
																				|it = '%1 del %2';
																				|pl = '%1 z dn. %2';
																				|tr = '%2 tarihli %1'"),
					GroupRow.ProductionOrderNumber,
					Format(GroupRow.ProductionOrderDate, "DLF=D"));
			EndIf;
			NewLineSummary.ThisIsTotal = True;
			
			If ReverseKittingOnly
				And NewLineSummary.ProductionProcessType <> Enums.ProductionProcessTypes.Disassembly Then
				ReverseKittingOnly = False;
			EndIf;
			
			NumberOfGroup = RowOfProducts.NumberOfGroup;
			BatchNumberInGroup = RowOfProducts.BatchNumberInGroup;
			
		ElsIf NewLineSummary.Products <> RowOfProducts.Products
			Or NewLineSummary.Characteristic <> RowOfProducts.Characteristic Then
			Continue;
		EndIf;
		
		NewRow = NewLineSummary.GetItems().Add();
		FillPropertyValues(NewRow, RowOfProducts,
			"Products, Characteristic, Purpose, Recipient, Count");
		
		NewLineSummary.Count = NewLineSummary.Count + RowOfProducts.Count;
		
		If RowOfProducts.AvailableReleaseFromAssignedmMaterials
			And Not NewLineSummary.AvailableReleaseFromAssignedmMaterials Then
			NewLineSummary.AvailableReleaseFromAssignedmMaterials = True;
		EndIf;
		
	EndDo;
	
	Items.ProductsToPreviewDemandDate.Visible = Not ReverseKittingOnly;
	
	FinishedProductsForPreviewHaveBeenChanged = False;
	AddressFormationData = PutToTempStorage(Data, UUID);
	
EndProcedure

#EndRegion

#Region ResultOfFormation

&AtClient
Procedure GoToGenerationResultStepOnClient()
	
	ClearMessages();
	
	Cancel = False;
	CreateDocumentsOnServer(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	If StartAwaitingLongAction Then
		StartAwaitingLongAction(False);
		SetUpWaitingInForm(True, NStr("vi = 'Đang lập chứng từ...';
										|ru = 'Документы формируются...';
										|en = 'Documents are being generated...'; fa = 'Documents are being generated...';
										|it = 'Documenti in creazione...';
										|pl = 'Trwa utworzenie dokumentów...';
										|tr = 'Belgeler düzenleniyor...'"));
	Else
		InstallAssistantPages(ThisForm, "StepResultOfFormation");
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDocumentsOnServer(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		Return;
	EndIf;
	
	If IsTempStorageURL(AddressFormationData) Then
		// The data was obtained at the preview step
		Data = GetFromTempStorage(AddressFormationData);
		
		If FinishedProductsForPreviewHaveBeenChanged Then
			Groups = Data.Groups; // ValueTable
			Products_1 = Data.Products_1; // ValueTable
			GroupNumbersToChange = New Array;
			
			Groups.Indexes.Add("NumberOfGroup");
			Products_1.Indexes.Add("NumberOfGroup");
			Products_1.Indexes.Add("NumberOfGroup, BatchNumberInGroup");
			
			TheStructureOfTheSearch1 = New Structure("NumberOfGroup");
			TheStructureOfTheSearch2 = New Structure("NumberOfGroup, BatchNumberInGroup");
			
			ProductTreeForPreview = FormAttributeToValue("ProductsToPreview");
			For Each PreviewString In ProductTreeForPreview.Rows.FindRows(New Structure("LineChanged", True)) Do
				FillPropertyValues(TheStructureOfTheSearch2, PreviewString, "NumberOfGroup, BatchNumberInGroup");
				For Each ProductLine In Products_1.FindRows(TheStructureOfTheSearch2) Do
					ProductLine.StartDate2 = PreviewString.EarliestStartDate;
					If GroupNumbersToChange.Find(ProductLine.NumberOfGroup) = Undefined Then
						GroupNumbersToChange.Add(ProductLine.NumberOfGroup);
					EndIf;
				EndDo;
			EndDo;
			
			For Each NumberOfGroup In GroupNumbersToChange Do
				TheStructureOfTheSearch1.NumberOfGroup = NumberOfGroup;
				ProductLines_ = Products_1.FindRows(TheStructureOfTheSearch1);
				If ProductLines_.Count() = 0 Then
					Continue;
				EndIf;
				EarliestStartDate = ProductLines_[0].StartDate2;
				For IndexOf = 1 To ProductLines_.UBound() Do
					EarliestStartDate = Min(EarliestStartDate, ProductLines_[IndexOf].StartDate2);
				EndDo;
				
				GroupString = Groups.Find(NumberOfGroup, "NumberOfGroup");
				GroupString.EarliestStartDate = EarliestStartDate;
				If GroupString.EarliestStartDate > GroupString.DemandDate Then
					GroupString.DemandDate = GroupString.EarliestStartDate;
				EndIf;
			EndDo;
		EndIf;
	Else
		Data = DataToBeGenerated();
		If Data = Undefined Then
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	// Starting the formation
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Groups", Data.Groups);
	ProcedureParameters.Insert("Products_1", Data.Products_1);
	ProcedureParameters.Insert("PartyKeys", Data.PartyKeys);
	ProcedureParameters.Insert("AssignmentsOfMaterials", Data.AssignmentsOfMaterials);
	
	For Each Parameter In DocumentCreationOptions Do
		ProcedureParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	AddressIsResultOfFormation = PutToTempStorage(
		GeneratingProductionStages.ResultOfFormation(), UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo lô hàng sản xuất: tạo chứng từ';
														|ru = 'Формирование партий производства: создание документов';
														|en = 'Generate production lots: document creation'; fa = 'Generate production lots: document creation';
														|it = 'Creazione lotti di produzione: creazione documenti';
														|pl = 'Rejestracja partii produkcji: utworzenie dokumentów';
														|tr = 'Üretim lotunun düzenlenmesi: Belgelerin oluşturulması'");
	ExecutionParameters.ResultAddress = AddressIsResultOfFormation;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GeneratingProductionStages.CreateDocumentsDeferred",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "CreateDocumentsDeferredCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		CreateDocumentsDeferred(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocumentsDeferredCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(False);
	
	CreateDocumentsDeferred(Result);
	InstallAssistantPages(ThisForm, "StepResultOfFormation");
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDocumentsDeferred(Result)
	
	Items.OutputRestrictionGroup.Visible = False;
	
	If IsTempStorageURL(AddressIsResultOfFormation) Then
		
		MeasurementStartTime = PerformanceMonitor.StartTimeMeasurement();
		
		ResultStructure1 = GetFromTempStorage(AddressIsResultOfFormation);
		AddressIsResultOfFormation = Undefined;
		
		// Output of documents
		Query = New Query(
			"SELECT
			|	ProductionLots.Ref                                      AS Lot,
			|	ProductionLots.MainProductProducts                 AS Products,
			|	ProductionLots.MainProductProducts.Presentation   AS ProductsPresentation,
			|	ProductionLots.MainProductCharacteristic.Presentation AS CharacteristicPresentation,
			|	ProductionLots.LineOfBusiness.Presentation       AS LineOfBusinessPresentation,
			|	ProductionLots.BillOfMaterials.Presentation                  AS BillOfMaterialsPresentation,
			|	CAST(ProductionLots.Document AS Document.ProductionOrder2_2) AS ReferenceOrder
			|FROM
			|	Catalog.ProductionLots AS ProductionLots
			|WHERE
			|	ProductionLots.Ref IN (&Lots)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ProductionStage2_2.Ref                       AS Ref,
			|	ProductionStage2_2.Number                        AS Number,
			|	ProductionStage2_2.StageName            AS StageName,
			|	ProductionStage2_2.Posted                     AS Posted,
			|	ProductionStage2_2.ReferenceOrder                 AS ReferenceOrder,
			|	ProductionStage2_2.Status                       AS Status,
			|	PRESENTATION(ProductionStage2_2.Status)        AS StatusPresentation,
			|	PRESENTATION(ProductionStage2_2.Department) AS DepartmentPresentation,
			|	ProductionStage2_2.ProductionLot           AS Lot,
			|	ProductionStage2_2.ProductionLot.MainProductProducts AS Products
			|FROM
			|	Document.ProductionStage2_2 AS ProductionStage2_2
			|WHERE
			|	ProductionStage2_2.Ref IN(&References)");
		Query.SetParameter("Lots", ResultStructure1.ResultOfFormation.UnloadColumn("Lot"));
		Query.SetParameter("References", ResultStructure1.ResultOfFormation.UnloadColumn("Document"));
		
		ResultsArray = Query.ExecuteBatch();
		Lots = ResultsArray[0].Unload();
		Stages = ResultsArray[1].Unload();
		
		Lots.Indexes.Add("Lot");
		Stages.Indexes.Add("Ref");
		
		ResultOfFormation.GetItems().Clear();
		StringBatch = Undefined;
		
		For IndexOf = 0 To ResultStructure1.ResultOfFormation.Count()-1 Do
			
			If IndexOf = 5000 Then
				Items.LimitationOfOutputRepresentation.Title = NStr("vi = 'Hiển thị 5000 đối tượng đầu tiên';
																	|ru = 'Отображены первые 5000 объектов';
																	|en = 'The first 5,000 objects are displayed'; fa = 'The first 5,000 objects are displayed';
																	|it = 'Sono stati visualizzati i primi 5000 oggetti';
																	|pl = 'Wyświetlono pierwsze 5000 obiektów';
																	|tr = 'İlk 5000 nesne görüntülendi'");
				Items.OutputRestrictionGroup.Visible = True;
				Break;
			EndIf;
			
			String = ResultStructure1.ResultOfFormation[IndexOf];
			
			If Not ValueIsFilled(String.Document) Then
				
				BatchData = Lots.Find(String.Lot, "Lot");
				
				StringBatch = ResultOfFormation.GetItems().Add();
				FillPropertyValues(StringBatch, BatchData, "Lot, ReferenceOrder, Products");
				
				Rows = New Array;
				If Not IsBlankString(BatchData.ProductsPresentation) Then
					Rows.Add(BatchData.ProductsPresentation);
				EndIf;
				If Not IsBlankString(BatchData.CharacteristicPresentation) Then
					Rows.Add(BatchData.CharacteristicPresentation);
				EndIf;
				If Not IsBlankString(BatchData.LineOfBusinessPresentation) Then
					Rows.Add(BatchData.LineOfBusinessPresentation);
				EndIf;
				If Not IsBlankString(BatchData.BillOfMaterialsPresentation) Then
					Rows.Add(BatchData.BillOfMaterialsPresentation);
				EndIf;
				If Not BatchData.ReferenceOrder.IsEmpty() Then
					Rows.Add(Documents.ProductionOrder2_2.OrderPresentation(BatchData.ReferenceOrder));
				EndIf;
				StringBatch.Presentation = StrConcat(Rows, ", ");
				StringBatch.RowType = LineTypeBatch();
				
			Else
				
				If StringBatch = Undefined Then
					Continue;
				EndIf;
				
				Data_Stage = Stages.Find(String.Document, "Ref");
				
				TreeRows = StringBatch.GetItems(); // FormDataTreeItemCollection
				StageString = TreeRows.Add();
				FillPropertyValues(StageString, Data_Stage, "Ref, Lot, ReferenceOrder, Products");
				StageString.Presentation = Documents.ProductionStage2_2.ExtendedStageView(Data_Stage);
				StageString.PictureNumber = ?(Data_Stage.Posted, 1, 0);
				StageString.RowType = StringTypeStage();
				
				If ThereAreErrorsInStage(Data_Stage) Then
					StringBatch.HasErrors = True;
					StageString.HasErrors = True;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		// Error output
		Errors.GetItems().Clear();
		For Each String In ResultStructure1.Errors Do
			
			ParentRow = Errors.GetItems().Add();
			ParentRow.Presentation = "" + String.Products
				+ ?(String.Characteristic.IsEmpty(), "", ", " + String.Characteristic)
				+ ?(String.LineOfBusiness.IsEmpty(), "", ", " + String.LineOfBusiness)
				+ ", " + String.BillOfMaterials;
			
			For Each Message In String.Messages Do
				
				StringError = ParentRow.GetItems().Add();
				StringError.Presentation = Message.Text;
				
			EndDo;
			
		EndDo;
		Items.Errors.Visible = ResultStructure1.Errors.Count() > 0;
		
		CreatedObjects.LoadValues(ResultStructure1.CreatedObjects);
		
		For Each Message In ResultStructure1.Messages Do
			Message.Message();
		EndDo;
		
		PerformanceMonitor.EndTimeMeasurement("Generation1 oflots ofproduction: creating trees documents", MeasurementStartTime);
		
	EndIf;
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("Messages") Then
		For Each Message In Result.Messages Do
			Message.Message();
		EndDo;
	EndIf;
	
	If Result = Undefined
		Or Result.Status <> "Completed2" Then
		Common.MessageToUser(NStr("vi = 'Chứng từ chưa được lập đầy đủ';
									|ru = 'Документы сформированы не полностью';
									|en = 'Documents are not fully generated'; fa = 'Documents are not fully generated';
									|it = 'I documenti non sono stati creati completamente';
									|pl = 'Dokumenty zostały utworzone nie w całości';
									|tr = 'Belgeler tamamen oluşturulmadı'"));
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ResultOfFormation");
	
EndProcedure

&AtServer
Function ThereAreErrorsInStage(Data_Stage)
	
	Return Not Data_Stage.Posted
		Or Data_Stage.Status = Enums.StatusesOfProductionStages2_2.BeingGenerated;
		
EndFunction

&AtServer
Procedure Delete_CreatedObjects(Cancel)
	
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure("References", CreatedObjects.UnloadValues());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Tạo lô hàng sản xuất: xóa các đối tượng đã tạo';
			|ru = 'Формирование партий производства: удаление созданных объектов';
			|en = 'Generate production lots: delete created objects'; fa = 'Generate production lots: delete created objects';
			|it = 'Creazione lotti di produzione: eliminazione degli oggetti creati';
			|pl = 'Tworzenie partii produkcji: usunięcie utworzonych obiektów';
			|tr = 'Üretim lotunun düzenlenmesi: Oluşturulan nesnelerin silinmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.GeneratingProductionStages.DeleteObjectsOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		Cancel = False;
		StartAwaitingLongAction = True;
		TimeConsumingOperationIdleHandler = "DeleteCreatedObjectsDeferredEnd";
		
	Else
		
		If TimeConsumingOperation.Status = "Error" Then
			Raise TimeConsumingOperation.BriefErrorDescription;
		EndIf;
		
		Cancel = TimeConsumingOperation.Status <> "Completed2";
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCreatedObjectsDeferredEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(False);
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
		AfterDeletingCreatedObjects(Result.Status <> "Completed2");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeletingCreatedObjects(Cancel)
	
	If Not Cancel Then
		
		ResultOfFormation.GetItems().Clear();
		Errors.GetItems().Clear();
		CreatedObjects.Clear();
		
		ShowUserNotification(
			NStr("vi = 'Xóa các đối tượng';
				|ru = 'Удаление объектов';
				|en = 'Delete objects'; fa = 'Delete objects';
				|it = 'Eliminazione oggetti';
				|pl = 'Usunięcie obiektów';
				|tr = 'Nesnelerin silinmesi'"),
			,
			NStr("vi = 'Đặt dấu xóa các đối tượng đã tạo.';
				|ru = 'Сформированные объекты помечены на удаление.';
				|en = 'Generated objects are marked for deletion.'; fa = 'Generated objects are marked for deletion.';
				|it = 'Oggetti creati contrassegnati per l''eliminazione.';
				|pl = 'Utworzone obiekty są zaznaczone do usunięcia.';
				|tr = 'Oluşturulan nesneler silinmek üzere işaretlendi.'"));
		
		If DisplayParameters.Preview Then
			InstallAssistantPages(ThisForm, "StepPreview");
		Else
			InstallAssistantPages(ThisForm, "StepNomenclaturePlan");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure HandleErrors(DeleteDocuments = False)
	
	Tree = FormDataToValue(ResultOfFormation,Type("ValueTree"));//ValueTree - 
	
	For PartyIndex = -Tree.Rows.Count() + 1 To 0 Do
		
		Lot = Tree.Rows[-PartyIndex];
		
		If Lot.HasErrors Then
			
			If DeleteDocuments Then
				
				ReferencesArrray = Lot.Rows.UnloadColumn("Ref");
				
				For Each CreatedObject In CreatedObjects Do
					
					If TypeOf(CreatedObject.Value) = Type("DocumentRef.ProductionOrder2_2")
						And Lot.Rows.Find(CreatedObject.Value, "ReferenceOrder") <> Undefined Then
						ReferencesArrray.Add(CreatedObject.Value);
					EndIf;
					
				EndDo;
				
				TMCommonUse.SetMarkForDeletingDocuments(ReferencesArrray);
				
				LotObject = Lot.Lot.GetObject();
				
				Tree.Rows.Delete(Lot);
				
				If LotObject = Undefined Or LotObject.DeletionMark Then
					Continue;
				EndIf;
				
				LotObject.SetDeletionMark(True);
				
			Else
				
				For Each Document In Lot.Rows Do
					
					DocumentObject = Document.Ref.GetObject();
					
					If DocumentObject = Undefined Then
						Continue;
					EndIf;
					
					Try
						DocumentObject.Lock();
					Except
						Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1 - không thể kết chuyển chứng từ, có thể là người sử dụng khác đang soạn chứng từ.';
								|ru = '%1 - не удалось провести документ, возможно документ редактируется другим пользователем.';
								|en = '%1 - cannot post the document, the document may be edited by another user.'; fa = '%1 - cannot post the document, the document may be edited by another user.';
								|it = '%1 - non è stato possibile pubblicare il documento, forse il documento è in modifica da parte di un altro utente.';
								|pl = '%1 - nie udało się zatwierdzić dokumentu, możliwe że jest edytowany przez innego użytkownika.';
								|tr = '%1 - belge kaydedilemedi, belge başka bir kullanıcı tarafından düzenleniyor olabilir.'"),
							TrimAll(Document.Ref)));
						Continue;
					EndTry;
					
					If Not (DocumentObject.DeletionMark Or DocumentObject.Posted) Then
						
						If TypeOf(DocumentObject) = Type("DocumentObject.ProductionStage2_2") Then
							
							DocumentObject.SetStatus("BeingGenerated", Undefined);
							DocumentObject.Write(DocumentWriteMode.Posting);
							
							Document.Presentation = Documents.ProductionStage2_2.ExtendedStageView(DocumentObject.Ref);
							Document.PictureNumber = 1;
							
						Else
							
							Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa kết chuyển %1';
									|ru = 'Проведение не выполнено %1';
									|en = 'Posting is not executed %1'; fa = 'Posting is not executed %1';
									|it = 'Registrazione non completata %1';
									|pl = 'Zatwierdzenie nie zostało wykonane %1';
									|tr = 'Kaydetme gerçekleştirilmedi %1'"),
								TrimAll(Document.Ref)));
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ValueToFormData(Tree, ResultOfFormation);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ContinueWithOtherSelectionsOnServer()
	
	Object.PlanResults.Clear();
	SetHyperlinkTextProvided();
	PutToTempStorage(Undefined, AddressPlanStorage);
	AddressFormationData = Undefined;
	FinishedProductsForPreviewHaveBeenChanged = False;
	
	ProductsToPreview.GetItems().Clear();
	ResultOfFormation.GetItems().Clear();
	Errors.GetItems().Clear();
	CreatedObjects.Clear();
	
	InstallAssistantPages(ThisForm, "StepSelection");
	
EndProcedure

&AtClient
Procedure ConsentToDeletionOfDocumentsEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If DisplayParameters.Preview Then
			GoBackToPreviewStepOnClient();
		Else
			GoBackToNomenclaturePlanStepOnClient();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region DataToBeGenerated

&AtServer
Function DataToBeGenerated()
	
	SearchStructureProduct = New Structure("NumberOfGroup, Products, Characteristic");
	SearchStructureMark = New Structure("Mark", True);
	
	Groups = Object.PlanResults.Unload(SearchStructureMark);
	If Groups.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Chưa chọn sản phẩm cần khởi chạy';
									|ru = 'Не выбраны изделия к запуску';
									|en = 'Finished products to launch are not selected'; fa = 'Finished products to launch are not selected';
									|it = 'Produzioni in avvio non selezionate';
									|pl = 'Nie wybrano wyrobów do uruchomienia';
									|tr = 'Başlatılacak nihai ürünler seçilmedi'"));
		Return Undefined;
	EndIf;
	
	Groups.Indexes.Add("NumberOfGroup, Products, Characteristic");
	
	Products_1 = GetFromTempStorage(AddressPlanStorage).Copy(SearchStructureMark); // ValueTable
	Products_1.Indexes.Add("NumberOfGroup, Products, Characteristic");
	
	// Auxiliary columns
	Groups.Columns.Add("OrderProducts_", New TypeDescription("Boolean"));
	Groups.Columns.Add("ProductionOrderGrouping", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	
	GroupNumberIsAsFollows = 100000000;
	
	// Rearranging lines - lines with the changed specification into separate groups
	ReadyForProcessing_ = Groups.FindRows(New Structure("BillOfMaterialsHasBeenChanged", True));
	If ReadyForProcessing_.UBound() <> -1 Then
		NewGroups = New ValueTable();
		NewGroups.Columns.Add("NumberOfGroup", New TypeDescription("Number", New NumberQualifiers()));
		NewGroups.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
		NewGroups.Columns.Add("GroupNumberIsNew", New TypeDescription("Number", New NumberQualifiers()));
		NewGroups.Indexes.Add("NumberOfGroup, BillOfMaterials");
		SearchStructureNewGroups = New Structure("NumberOfGroup, BillOfMaterials");
		
		For Each String In ReadyForProcessing_ Do
			FillPropertyValues(SearchStructureProduct, String);
			ProductLines_ = Products_1.FindRows(SearchStructureProduct);
			
			FillPropertyValues(SearchStructureNewGroups, String);
			RowsAreNewGroups = NewGroups.FindRows(SearchStructureNewGroups);
			If RowsAreNewGroups.UBound() = -1 Then
				GroupNumberIsNew = GroupNumberIsAsFollows;
				GroupNumberIsAsFollows = GroupNumberIsAsFollows + 1;
				
				NewRow = NewGroups.Add();
				FillPropertyValues(NewRow, String, "NumberOfGroup, BillOfMaterials");
				NewRow.GroupNumberIsNew = GroupNumberIsNew;
			Else
				GroupNumberIsNew = RowsAreNewGroups[0].GroupNumberIsNew;
			EndIf;
			
			String.NumberOfGroup = GroupNumberIsNew;
			For Each Product In ProductLines_ Do
				Product.NumberOfGroup = GroupNumberIsNew;
			EndDo;
		EndDo;
		
	EndIf;
	
	// Rearrangement of lines - R&M and ReverseKitting into separate groups
	ReadyForProcessing_ = Products_1.FindRows(New Structure("ThisIsRMOrReverseKitting", True));
	For Each Product In ReadyForProcessing_ Do
		FillPropertyValues(SearchStructureProduct, Product);
		FoundRows = Groups.FindRows(SearchStructureProduct);
		If FoundRows.Count() = 0
			Or FoundRows[0].Launch = Product.Launch Then
			Continue;
		EndIf;
		
		Var_Group = FoundRows[0];
		
		GroupNumberIsNew = GroupNumberIsAsFollows;
		GroupNumberIsAsFollows = GroupNumberIsAsFollows + 1;
		
		NewFolder = Groups.Add();
		FillPropertyValues(NewFolder, Var_Group,, "NumberOfGroup, Launch");
		NewFolder.NumberOfGroup = GroupNumberIsNew;
		NewFolder.Launch = Product.Launch;
		
		Product.NumberOfGroup = GroupNumberIsNew;
		
		Var_Group.Launch = Var_Group.Launch - Product.Launch;
	EndDo;
	
	// Rearranging rows
	//	Order items in separate groups
	//	PF of various orders in separate groups (conditionally)
	//	PF with different assignments of materials in different groups (conditionally)
	//	PF with free release of separate materials (in different groups if they relate to different orders/product assignments)
	
	Orders = New ValueTable();
	Orders.Columns.Add("NumberOfGroup", New TypeDescription("Number", New NumberQualifiers()));
	Orders.Columns.Add("OrderDocument", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	Orders.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Orders.Columns.Add("AssignmentProducts", New TypeDescription("CatalogRef.Assignments"));
	Orders.Indexes.Add("NumberOfGroup");
	
	NewGroups = New ValueTable();
	NewGroups.Columns.Add("NumberOfGroup", New TypeDescription("Number", New NumberQualifiers()));
	NewGroups.Columns.Add("OrderDocument", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	NewGroups.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	NewGroups.Columns.Add("AssignmentProducts", New TypeDescription("CatalogRef.Assignments"));
	NewGroups.Columns.Add("GroupNumberIsNew", New TypeDescription("Number", New NumberQualifiers()));
	NewGroups.Indexes.Add("NumberOfGroup, OrderDocument, Purpose, AssignmentProducts");
	
	SearchStructureNumber = New Structure("NumberOfGroup");
	SearchStructureNewNumber = New Structure("NumberOfGroup, OrderDocument, Purpose, AssignmentProducts");
	
	For Each Product In Products_1 Do
		
		If Product.ExceedingOrder Then
			// The rows over the order remain in the original group (binding to the ordered row)
			Continue;
		EndIf;
		
		ThereIsRestrictionOnOrder = Product.OrderProducts_
			Or Not DocumentCreationOptions.ConsolidateBatchesBetweenOrders
			Or Product.AvailableReleaseFromAssignedmMaterials;
		OrderDocument = ?(ThereIsRestrictionOnOrder,
			Product.ProductionOrder,
			Documents.ProductionOrder2_2.EmptyRef());
		
		Purpose = ?(Not DocumentCreationOptions.ConsolidatePartiesByAppointment,
			Product.Purpose,
			Catalogs.Assignments.EmptyRef());
		
		AssignmentProducts = ?(Product.AvailableReleaseFromAssignedmMaterials,
			Product.AssignmentProducts,
			Catalogs.Assignments.EmptyRef());
		
		OrdersLine = Orders.Find(Product.NumberOfGroup, "NumberOfGroup");
		If OrdersLine = Undefined Then
			NewRow = Orders.Add();
			NewRow.NumberOfGroup = Product.NumberOfGroup;
			NewRow.OrderDocument = OrderDocument;
			NewRow.Purpose = Purpose;
			NewRow.AssignmentProducts = AssignmentProducts;
		ElsIf OrdersLine.OrderDocument <> OrderDocument
			Or OrdersLine.Purpose <> Purpose
			Or OrdersLine.AssignmentProducts <> AssignmentProducts Then
			
			GroupNumberIsNew = 0;
			
			SearchStructureNewNumber.NumberOfGroup = Product.NumberOfGroup;
			SearchStructureNewNumber.OrderDocument = OrderDocument;
			SearchStructureNewNumber.Purpose = Purpose;
			SearchStructureNewNumber.AssignmentProducts = AssignmentProducts;
			FoundRows = NewGroups.FindRows(SearchStructureNewNumber);
			If FoundRows.Count() = 0 Then
				GroupNumberIsNew = GroupNumberIsAsFollows;
				GroupNumberIsAsFollows = GroupNumberIsAsFollows + 1;
				
				NewRow = NewGroups.Add();
				NewRow.NumberOfGroup = Product.NumberOfGroup;
				NewRow.OrderDocument = OrderDocument;
				NewRow.Purpose = Purpose;
				NewRow.AssignmentProducts = AssignmentProducts;
				NewRow.GroupNumberIsNew = GroupNumberIsNew;
			Else
				GroupNumberIsNew = FoundRows[0].GroupNumberIsNew;
			EndIf;
			
			FillPropertyValues(SearchStructureProduct, Product);
			Var_Group = Groups.FindRows(SearchStructureProduct)[0];
			
			SearchStructureProduct.NumberOfGroup = GroupNumberIsNew;
			FoundRows = Groups.FindRows(SearchStructureProduct);
			If FoundRows.UBound() = -1 Then
				NewFolder = Groups.Add();
				FillPropertyValues(NewFolder, Var_Group,, "NumberOfGroup, Launch");
				NewFolder.NumberOfGroup = GroupNumberIsNew;
			Else
				NewFolder = FoundRows[0];
			EndIf;
			
			// Linking to a new group
			Product.NumberOfGroup = NewFolder.NumberOfGroup;
			NewFolder.Launch = NewFolder.Launch + Product.Launch;
			
			Var_Group.Launch = Var_Group.Launch - Product.Launch;
			If Var_Group.Launch = 0 Then
				Groups.Delete(Var_Group);
			EndIf;
			
		EndIf;
		
		If Product.OrderProducts_ Then
			SearchStructureNumber.NumberOfGroup = Product.NumberOfGroup;
			For Each Var_Group In Groups.FindRows(SearchStructureNumber) Do
				Var_Group.OrderProducts_ = True;
				Var_Group.ProductionOrderGrouping = Product.ProductionOrder;
			EndDo;
		EndIf;
		
	EndDo;
	
	// Rearrangement of lines - by-products are "attached" to the main ones
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Regroup", True);
	TheStructureOfTheSearch.Insert("MainProduct", False);
	TheStructureOfTheSearch.Insert("OrderProducts_", True);
	ReadyForProcessing_ = Groups.FindRows(TheStructureOfTheSearch);
	
	If ReadyForProcessing_.UBound() <> -1 Then
		
		GroupsSearchStructure = New Structure;
		GroupsSearchStructure.Insert("Regroup", True);
		GroupsSearchStructure.Insert("MainProduct", True);
		GroupsSearchStructure.Insert("BillOfMaterials");
		GroupsSearchStructure.Insert("ProductionOrderGrouping");
		Groups.Indexes.Add("Regroup, MainProduct, BillOfMaterials, ProductionOrderGrouping");
		
		For Each String In ReadyForProcessing_ Do
			
			FillPropertyValues(GroupsSearchStructure, String, "BillOfMaterials, ProductionOrderGrouping");
			MainProductLines = Groups.FindRows(GroupsSearchStructure);
			
			FillPropertyValues(SearchStructureProduct, String);
			PlanRows = Products_1.FindRows(SearchStructureProduct);
			
			For IndexOf = 0 To MainProductLines.UBound() Do
				
				LeadingLine = MainProductLines[IndexOf];
				If LeadingLine.QuantityPerBatch = 0 Then
					Continue;
				EndIf;
				
				QuantityOfBatches = LeadingLine.Launch/LeadingLine.QuantityPerBatch;
				Count = Min(String.Launch, String.QuantityPerBatch * QuantityOfBatches);
				
				If IndexOf = MainProductLines.UBound()
					Or Count = String.Launch Then
					
					For Each LinePlan In PlanRows Do
						LinePlan.NumberOfGroup = LeadingLine.NumberOfGroup;
					EndDo;
					Groups.Delete(String);
					Break;
					
				Else
					
					Balance = Count;
					For IndexPlan = -(PlanRows.Count()-1) To 0 Do
						
						LinePlan  = PlanRows[-IndexPlan];
						
						NewRow = Products_1.Add();
						FillPropertyValues(NewRow, LinePlan,, "NumberOfGroup, Launch");
						NewRow.NumberOfGroup = LeadingLine.NumberOfGroup;
						NewRow.Launch = Min(LinePlan.Launch, Balance);
						
						LinePlan.Launch = LinePlan.Launch - NewRow.Launch;
						If LinePlan.Launch = 0 Then
							Products_1.Delete(LinePlan);
							PlanRows.Delete(-IndexPlan);
						EndIf;
						
						Balance = Balance - NewRow.Launch;
						If Balance = 0 Then
							Break;
						EndIf;
						
					EndDo;
					
					String.Launch = String.Launch - Count;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	// Rearrangement of rows - optimal batches into separate groups
	GroupsSearchStructure = New Structure("ThereIsOptimalLotReference", True);
	GroupsToBeProcessed = Groups.Copy(GroupsSearchStructure,
		"NumberOfGroup, ProductKind, Products, Characteristic, BillOfMaterials");
	If GroupsToBeProcessed.Count() > 0 Then
		QueryText = 
			"SELECT
			|	Groups.NumberOfGroup     AS NumberOfGroup,
			|	Groups.ProductKind AS ProductKind,
			|	Groups.Products    AS Products,
			|	Groups.Characteristic  AS Characteristic,
			|	CAST(Groups.BillOfMaterials AS Catalog.BillsOfMaterials) AS BillOfMaterials
			|INTO Groups
			|FROM
			|	&GroupsToBeProcessed AS Groups
			|
			|INDEX BY
			|	ProductKind, Products, Characteristic, BillOfMaterials
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	Groups.NumberOfGroup    AS NumberOfGroup,
			|	Groups.Products   AS Products,
			|	Groups.Characteristic AS Characteristic,
			|	CASE
			|		WHEN Groups.BillOfMaterials.ProductionIssueByCustomPortions
			|			THEN CASE
			|				WHEN ProductsBOM.Order = 1
			|					THEN Groups.BillOfMaterials.EconomicReleaseLot
			|				WHEN ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1) <> 0
			|					THEN Groups.BillOfMaterials.EconomicReleaseLot
			|							* (ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1))
			|							/ (ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1))
			|				ELSE 0
			|			END
			|		ELSE Groups.BillOfMaterials.EconomicReleaseLot * ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1)
			|	END                 AS QuantityOptimalLotReference,
			|	CASE
			|		WHEN Groups.BillOfMaterials.ProductionIssueByCustomPortions
			|			THEN CASE
			|				WHEN ProductsBOM.Order = 1
			|					THEN Groups.BillOfMaterials.EconomicReleaseLot
			|				WHEN ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1) <> 0
			|					THEN Groups.BillOfMaterials.EconomicReleaseLot
			|							* (ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1))
			|							/ (ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1))
			|				ELSE 0
			|			END
			|		ELSE Groups.BillOfMaterials.EconomicReleaseLot * ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1)
			|	END + CASE
			|		WHEN Groups.BillOfMaterials.ProductionIssueByCustomPortions
			|			THEN CASE
			|				WHEN ProductsBOM.Order = 1
			|					THEN Groups.BillOfMaterials.PermissibleExcessOfOptimalReleaseLot
			|				WHEN ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1) <> 0
			|					THEN Groups.BillOfMaterials.PermissibleExcessOfOptimalReleaseLot
			|							* (ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1))
			|							/ (ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit * ISNULL(&QueryTextMainProductPackagingFactor, 1))
			|				ELSE 0
			|			END
			|		ELSE Groups.BillOfMaterials.PermissibleExcessOfOptimalReleaseLot * ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1)
			|	END                 AS QuantityOptimalLotReferenceWithAcceptableExcess
			|FROM
			|	Groups AS Groups
			|
			|	INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
			|	ON Groups.ProductKind = ProductsBOM.ProductKind
			|		AND ProductsBOM.Products IN (Groups.Products, VALUE(Catalog.Products.EmptyRef))
			|		AND ProductsBOM.Characteristic IN (Groups.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|		AND Groups.BillOfMaterials = ProductsBOM.BillOfMaterials
			|
			|	LEFT JOIN InformationRegister.ProductsBOM AS MainProduct
			|	ON Groups.BillOfMaterials = MainProduct.BillOfMaterials
			|		AND MainProduct.Order = 1";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductsBOM.Package", "Groups.Products"));
		
		QueryText = StrReplace(QueryText,
			"&QueryTextMainProductPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductsBOM.MainProductPackagingUnit", "MainProduct.Products"));
		
		Query = New Query(QueryText);
		Query.SetParameter("GroupsToBeProcessed", GroupsToBeProcessed);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			FillPropertyValues(SearchStructureProduct, Selection);
			For Each Product In Products_1.FindRows(SearchStructureProduct) Do
				If Product.Launch >= Selection.QuantityOptimalLotReference
					And Product.Launch <= Selection.QuantityOptimalLotReferenceWithAcceptableExcess Then
					FoundRows = Groups.FindRows(SearchStructureProduct);
					If FoundRows.Count() = 0
						Or FoundRows[0].Launch = Product.Launch Then
						Continue;
					EndIf;
					
					Var_Group = FoundRows[0];
					
					GroupNumberIsNew = GroupNumberIsAsFollows;
					GroupNumberIsAsFollows = GroupNumberIsAsFollows + 1;
					
					NewFolder = Groups.Add();
					FillPropertyValues(NewFolder, Var_Group,, "NumberOfGroup, Launch");
					NewFolder.NumberOfGroup = -GroupNumberIsNew;
					NewFolder.Launch = Product.Launch;
					
					Product.NumberOfGroup = -GroupNumberIsNew;
					
					Var_Group.Launch = Var_Group.Launch - Product.Launch;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	Groups.Columns.Delete("OrderProducts_");
	Groups.Columns.Delete("ProductionOrderGrouping");
	
	// Reading additional data required to generate
	TempTablesManager = New TempTablesManager();
	CurrentDate = CurrentSessionDate();
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Groups", Groups);
	Query.SetParameter("Products_1", Products_1);
	Query.SetParameter("CurrentDate", CurrentDate);
	
	Query.Text = 
		"SELECT DISTINCT
		|	Groups.NumberOfGroup             AS NumberOfGroup,
		|	CAST(Groups.BillOfMaterials AS Catalog.BillsOfMaterials) AS BillOfMaterials,
		|	Groups.Organization             AS Organization,
		|	Groups.Partner                 AS Partner,
		|	Groups.Contract                 AS Contract,
		|	Groups.LineOfBusiness AS LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity    AS OrderForActivity,
		|	Groups.BusinessOperation   AS BusinessOperation,
		|	Groups.ProductionProcessType AS ProductionProcessType
		|INTO Groups
		|FROM
		|	&Groups AS Groups
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup              AS NumberOfGroup,
		|	CAST(Products_1.BillOfMaterials    AS Catalog.BillsOfMaterials) AS BillOfMaterials,
		|	Products_1.LineOfBusiness  AS LineOfBusiness,
		|	Products_1.ProductionDispatcherBusinessUnit   AS ProductionDispatcherBusinessUnit,
		|	CAST(Products_1.Products    AS Catalog.Products) AS Products,
		|	CAST(Products_1.Characteristic  AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	Products_1.Recipient               AS Recipient,
		|	Products_1.Purpose               AS Purpose,
		|	Products_1.AssignmentProducts      AS AssignmentProducts,
		|	CAST(Products_1.ProductionOrder AS Document.ProductionOrder2_2) AS ProductionOrder,
		|	Products_1.ProductKind          AS ProductKind,
		|	CASE
		|		WHEN Products_1.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			THEN Products_1.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                            AS SupplyAssignment,
		|	Products_1.Required2                AS QuantityStandard,
		|	Products_1.Launch                 AS Count,
		|	Products_1.OrderProducts_          AS OrderProducts_, 
		|	Products_1.QuantityPerBatch       AS QuantityPerBatch, 
		|	Products_1.LineNumberProducts     AS LineNumberProducts,
		|	Products_1.ToExpenseAs         AS ToExpenseAs,
		|	Products_1.ExpenseItem           AS ExpenseItem,
		|	Products_1.DimensionOfExpenses        AS DimensionOfExpenses,
		|	Products_1.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	Products_1.UnderRepairProduct   AS UnderRepairProduct,
		|	Products_1.UnderRepairVariant AS UnderRepairVariant,
		|	Products_1.UnderRepairBatch          AS UnderRepairBatch,
		|	Products_1.ExceedingOrder              AS ExceedingOrder,
		|	Products_1.AvailableReleaseFromAssignedmMaterials AS AvailableReleaseFromAssignedmMaterials,
		|	CASE
		|		WHEN Products_1.StartDate2 <> DATETIME(1, 1, 1)
		|			THEN Products_1.StartDate2
		|		WHEN Products_1.RequestedCompletionDate <> DATETIME(1, 1, 1)
		|			AND Products_1.RequestedCompletionDate < &CurrentDate
		|			THEN Products_1.RequestedCompletionDate
		|		ELSE &CurrentDate
		|	END                            AS StartDate2,
		|	Products_1.StartDate2              AS LaunchDateStandard,
		|	CASE
		|		WHEN Products_1.RequestedCompletionDate <> DATETIME(1, 1, 1)
		|			THEN Products_1.RequestedCompletionDate
		|		WHEN Products_1.StartDate2 <> DATETIME(1, 1, 1)
		|			AND Products_1.StartDate2 > &CurrentDate
		|			THEN Products_1.StartDate2
		|		ELSE &CurrentDate
		|	END                               AS RequestedCompletionDate,
		|	Products_1.Level                     AS Level,
		|	Products_1.DurationBeforeProductionIssue       AS DurationBeforeProductionIssue,
		|	Products_1.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
		|	Products_1.KeyLot                  AS KeyLot,
		|	RECORDAUTONUMBER()                   AS Key
		|INTO Products_1
		|FROM
		|	&Products_1 AS Products_1
		|
		|INDEX BY
		|	NumberOfGroup";
	Query.Execute();
	
	QueryTexts = New Array;
	
	CalculateScheduleFromCurrentDate = DocumentCreationOptions.OptionToFillInScheduleOfStages = "CalculateFromCurDate";
	
	If Not TheProductionScheduleIsUsed
		And CalculateScheduleFromCurrentDate Then
		QueryText =
			"SELECT
			|	CASE
			|		WHEN CurrentDate.DayAddedToSchedule
			|			THEN CurrentDate.DaysCountInScheduleSinceBegOfYear
			|		ELSE NextDayInSchedule.DaysCountInScheduleSinceBegOfYear
			|	END AS DaysCountInScheduleSinceBegOfYear
			|INTO TTCurrentDate
			|FROM
			|	InformationRegister.CalendarSchedules AS CurrentDate
			|
			|	LEFT JOIN InformationRegister.CalendarSchedules AS NextDayInSchedule
			|	ON NextDayInSchedule.Calendar = &MainCalendar
			|		AND NextDayInSchedule.Year = &CurrentYear
			|		AND NextDayInSchedule.DaysCountInScheduleSinceBegOfYear = CurrentDate.DaysCountInScheduleSinceBegOfYear + 1
			|		AND NextDayInSchedule.DayAddedToSchedule
			|WHERE
			|	CurrentDate.Calendar = &MainCalendar
			|	AND CurrentDate.Year = &CurrentYear
			|	AND CurrentDate.ScheduleDate = &StartingDate
			|	AND (CurrentDate.DayAddedToSchedule
			|		OR NextDayInSchedule.DaysCountInScheduleSinceBegOfYear IS NOT NULL)
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	T.BillOfMaterials                                                             AS BillOfMaterials,
			|	&StartingDate                                                               AS StartDate2,
			|	ISNULL(CurYearRelease.ScheduleDate, GraduationNextYear.ScheduleDate) AS DateOfProduction
			|INTO RegulatoryLaunchDatesOfIssueFromCurrentDate
			|FROM
			|	InformationRegister.StandardProductionDuration AS T
			|
			|	LEFT JOIN TTCurrentDate AS CurrentDate
			|	ON TRUE
			|
			|	LEFT JOIN InformationRegister.CalendarSchedules AS LastDateOfYear
			|	ON LastDateOfYear.Calendar = &MainCalendar
			|		AND LastDateOfYear.Year = &CurrentYear
			|		AND LastDateOfYear.ScheduleDate = &LastDayOfYear
			|
			|	LEFT JOIN InformationRegister.CalendarSchedules AS CurYearRelease
			|	ON CurrentDate.DaysCountInScheduleSinceBegOfYear IS NOT NULL
			|		AND CurYearRelease.Calendar = &MainCalendar
			|		AND CurYearRelease.Year = &CurrentYear
			|		AND CurYearRelease.DayAddedToSchedule
			|		AND CurYearRelease.DaysCountInScheduleSinceBegOfYear
			|		  = CurrentDate.DaysCountInScheduleSinceBegOfYear
			|			+ T.Duration
			|
			|	LEFT JOIN InformationRegister.CalendarSchedules AS GraduationNextYear
			|	ON CurYearRelease.ScheduleDate IS NULL
			|		AND GraduationNextYear.Calendar = &MainCalendar
			|		AND GraduationNextYear.Year = &NextYear
			|		AND GraduationNextYear.DayAddedToSchedule
			|		AND GraduationNextYear.DaysCountInScheduleSinceBegOfYear
			|		  = T.Duration
			|			- ISNULL(LastDateOfYear.DaysCountInScheduleSinceBegOfYear - CurrentDate.DaysCountInScheduleSinceBegOfYear, -1)
			|WHERE
			|	T.BillOfMaterials IN(SELECT DD.BillOfMaterials FROM Groups AS DD)
			|	AND (CurYearRelease.ScheduleDate IS NOT NULL
			|		OR GraduationNextYear.ScheduleDate IS NOT NULL)
			|
			|INDEX BY
			|	BillOfMaterials";
		QueryTexts.Add(QueryText);
	Else
		QueryText =
			"SELECT TOP 0
			|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
			|	DATETIME(1,1,1)                                        AS StartDate2,
			|	DATETIME(1,1,1)                                        AS DateOfProduction
			|INTO RegulatoryLaunchDatesOfIssueFromCurrentDate";
		QueryTexts.Add(QueryText);
	EndIf;
	
	If TheProductionScheduleIsUsed Then
		ProductionManagement.CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
			TempTablesManager,
			"&TextTableName.KeyLot IN (SELECT T.KeyLot FROM Products_1 AS T)",
			False,
			False);
	Else
		QueryText = 
			"SELECT TOP 0
			|	&EmptyLinkKey                                    AS KeyLot,
			|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
			|	DATETIME(1,1,1)                                    AS AvailabilityDate
			|INTO TTProductionScheduleRestrictionsOnMaterials";
		QueryTexts.Add(QueryText);
	EndIf;
	
	QueryText =
		"SELECT
		|	Products_1.Key AS Key,
		|	CASE
		|		WHEN NOT &TheProductionScheduleIsUsed
		|			THEN ISNULL(RegulatoryLaunchDatesOfIssueFromCurrentDate.StartDate2, Products_1.StartDate2)
		|		WHEN Products_1.StartDate2 <= &CurrentDateIsEndOfDay
		|				OR &CalculateScheduleFromCurrentDate
		|			THEN &CurrentDate
		|		ELSE Products_1.StartDate2
		|	END        AS StartDate2,
		|	ISNULL(RegulatoryLaunchDatesOfIssueFromCurrentDate.DateOfProduction, Products_1.RequestedCompletionDate) AS RequestedCompletionDate
		|INTO ProductDates
		|FROM
		|	Products_1 AS Products_1
		|	
		|	LEFT JOIN RegulatoryLaunchDatesOfIssueFromCurrentDate AS RegulatoryLaunchDatesOfIssueFromCurrentDate
		|	ON Products_1.BillOfMaterials = RegulatoryLaunchDatesOfIssueFromCurrentDate.BillOfMaterials
		|
		|INDEX BY
		|	Key
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup                                    AS NumberOfGroup,
		|	
		|	CASE
		|		WHEN COUNT(DISTINCT Products_1.AssignmentProducts) > 1
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		WHEN COUNT(DISTINCT Products_1.ProductionOrder) > 1 // An order will be created with a separation for the purpose of the products
		|				OR MAX(Products_1.ProductionOrder.OptionOfAssignment = VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts))
		|			THEN MAX(Products_1.AssignmentProducts)
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                                  AS AssignmentProducts,
		|
		|	CASE
		|		WHEN COUNT(DISTINCT Products_1.ProductionOrder) > 1
		|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
		|		ELSE MAX(Products_1.ProductionOrder)
		|	END                                                  AS ReferenceOrder,
		|	
		|	MIN(ProductDates.StartDate2)                       AS StartDate2,
		|	MIN(ProductDates.RequestedCompletionDate)               AS RequestedCompletionDate,
		|	MAX(Products_1.DurationBeforeProductionIssue)                AS DurationBeforeProductionIssue,
		|	MIN(Products_1.ProductionLotIDInProductGroup)           AS ProductionLotIDInProductGroup,
		|	MAX(Products_1.UnderRepairProduct)     AS UnderRepairProduct,
		|	MAX(Products_1.UnderRepairVariant)   AS UnderRepairVariant,
		|	MAX(Products_1.UnderRepairBatch)            AS UnderRepairBatch,
		|	CASE
		|		WHEN COUNT(DISTINCT Products_1.ProductionOrder) > 1
		|			THEN FALSE
		|		ELSE MAX(Products_1.ProductionOrder.ConsolidatedOrderByProductAssignments)
		|	END                                                  AS ConsolidatedOrderByProductAssignments,
		|	CASE
		|		WHEN COUNT(DISTINCT Products_1.ProductionOrder) > 1
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE MAX(Products_1.ProductionOrder.Purpose)
		|	END                                                  AS OrderAppointment
		|INTO StartupParameters
		|FROM
		|	Products_1 AS Products_1
		|	
		|	LEFT JOIN ProductDates AS ProductDates
		|	ON Products_1.Key = ProductDates.Key
		|	
		|WHERE
		|	NOT Products_1.ExceedingOrder
		|
		|GROUP BY
		|	Products_1.NumberOfGroup
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	NestedQuery.NumberOfGroup                AS NumberOfGroup,
		|	MAX(NestedQuery.QuantityOfBatches) AS QuantityOfBatches
		|INTO GroupsToBeDividedIntoOptimalBatches
		|FROM
		|	(
		|		SELECT
		|			Products_1.NumberOfGroup AS NumberOfGroup,
		|			CASE
		|				WHEN MAX(Products_1.QuantityPerBatch) <> 0
		|					THEN SUM(Products_1.Count) / MAX(Products_1.QuantityPerBatch)
		|				ELSE 0
		|			END               AS QuantityOfBatches
		|		FROM
		|			Products_1 AS Products_1
		|		WHERE
		|			Products_1.BillOfMaterials.EconomicReleaseLot <> 0
		|		GROUP BY
		|			Products_1.NumberOfGroup,
		|			Products_1.Products,
		|			Products_1.Characteristic
		|	) AS NestedQuery
		|	
		|GROUP BY
		|	NestedQuery.NumberOfGroup
		|HAVING
		|	MAX(NestedQuery.QuantityOfBatches) <> 0
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	GroupsToDivide.NumberOfGroup      AS NumberOfGroup,
		|
		|	Products_1.BillOfMaterials.EconomicReleaseLot                        AS EconomicReleaseLot,
		|	Products_1.BillOfMaterials.MinimumReleaseLot                        AS MinimumReleaseLot,
		|	Products_1.BillOfMaterials.PermissibleExcessOfOptimalReleaseLot    AS PermissibleExcessOfOptimalReleaseLot,
		|	Products_1.BillOfMaterials.ProductionIssueByCustomPortions                     AS ProductionIssueByCustomPortions,
		|
		|	Products_1.Products AS Products,
		|	ProductsBOM.Package AS Package,
		|	ProductsBOM.NumberOfPackagesPerStartingLotUnit AS NumberOfPackagesPerStartingLotUnit,
		|	ProductsBOM.Order = 1 AS ThisIsMainProduct,
		|	
		|	MainProductSpecifications.Products AS MainFinishedProductSpecificationsItem,
		|	MainProductSpecifications.Package AS MainFinishedProductSpecificationsPackagingUnits,
		|	MainProductSpecifications.NumberOfPackagesPerStartingLotUnit AS MainFinishedProductSpecificationsNumberOfPackagingUnitsPerUnitOfLaunchBatch,
		|	
		|	CAST(GroupsToDivide.QuantityOfBatches * Products_1.QuantityPerBatch AS NUMBER(15, 3)) AS Count
		|INTO FinishedProductsToBeDividedIntoOptimalBatches
		|FROM
		|	GroupsToBeDividedIntoOptimalBatches AS GroupsToDivide
		|
		|	INNER JOIN Products_1 AS Products_1
		|	ON GroupsToDivide.NumberOfGroup = Products_1.NumberOfGroup
		|
		|	INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|	ON ProductsBOM.BillOfMaterials = Products_1.BillOfMaterials
		|		AND ProductsBOM.ProductKind = Products_1.ProductKind
		|		AND ProductsBOM.Products IN (Products_1.Products, VALUE(Catalog.Products.EmptyRef))
		|		AND ProductsBOM.Characteristic IN (Products_1.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|
		|	INNER JOIN InformationRegister.ProductsBOM AS MainProductSpecifications
		|	ON MainProductSpecifications.BillOfMaterials = Products_1.BillOfMaterials
		|		AND MainProductSpecifications.ProductKind = Products_1.ProductKind
		|		AND MainProductSpecifications.Order = 1
		|WHERE
		|	Products_1.Key IN(
		|		SELECT TOP 1
		|			T.Key AS Key
		|		FROM
		|			Products_1 AS T
		|		WHERE
		|			T.NumberOfGroup = GroupsToDivide.NumberOfGroup
		|		ORDER BY
		|			T.Key)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup AS NumberOfGroup
		|INTO GroupsOfMultipleAssignments
		|FROM
		|	Products_1 AS Products_1
		|	
		|	INNER JOIN StartupParameters AS StartupParameters
		|	ON Products_1.NumberOfGroup = StartupParameters.NumberOfGroup
		|
		|GROUP BY
		|	Products_1.NumberOfGroup
		|
		|HAVING
		|	MIN(StartupParameters.ConsolidatedOrderByProductAssignments)
		|	OR MIN(StartupParameters.ReferenceOrder = VALUE(Document.ProductionOrder2_2.EmptyRef))
		|		AND COUNT(DISTINCT Products_1.SupplyAssignment) > 1
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup           AS NumberOfGroup,
		|	Products_1.Products          AS Products,
		|	Products_1.Characteristic        AS Characteristic,
		|	Products_1.SupplyAssignment AS SupplyAssignment,
		|	MIN(Products_1.Key)         AS Order,
		|	SUM(Products_1.Count)     AS Count,
		|	MAX(ProductsBOM.NumberOfPackagesPerStartingLotUnit
		|		* ISNULL(&QueryTextPackagingFactor, 1)) AS QuantityForLaunchLotUnit
		|INTO ProductsForSeveralPurposes
		|FROM
		|	Products_1 AS Products_1
		|	
		|	INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|	ON Products_1.BillOfMaterials = ProductsBOM.BillOfMaterials
		|		AND Products_1.ProductKind = ProductsBOM.ProductKind
		|		AND ProductsBOM.Products IN (Products_1.Products, VALUE(Catalog.Products.EmptyRef))
		|		AND ProductsBOM.Characteristic IN (Products_1.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|WHERE
		|	Products_1.NumberOfGroup IN (
		|		SELECT
		|			T.NumberOfGroup AS NumberOfGroup
		|		FROM
		|			GroupsOfMultipleAssignments AS T)
		|
		|GROUP BY
		|	Products_1.NumberOfGroup,
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.SupplyAssignment
		|
		|INDEX BY
		|	NumberOfGroup,
		|	Products,
		|	Characteristic,
		|	SupplyAssignment
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup AS NumberOfGroup,
		|	SUM(Products_1.Count/Products_1.QuantityForLaunchLotUnit) AS Total
		|INTO ResultsOfSeveralAppointments
		|FROM
		|	ProductsForSeveralPurposes AS Products_1
		|WHERE
		|	Products_1.QuantityForLaunchLotUnit <> 0
		|
		|GROUP BY
		|	Products_1.NumberOfGroup
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup AS NumberOfGroup,
		|	Products_1.KeyLot  AS KeyLot,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1)) AS Begin
		|INTO GroupsKeysStart
		|FROM
		|	Products_1 AS Products_1
		|	
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Products_1.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Products_1.KeyLot = Schedule.KeyLot
		|		AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|WHERE
		|	NOT Products_1.ExceedingOrder
		|
		|INDEX BY
		|	NumberOfGroup, Begin
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	GroupsKeysStart.NumberOfGroup     AS NumberOfGroup,
		|	MIN(GroupsKeysStart.Begin) AS Begin
		|INTO GroupsStart
		|FROM
		|	GroupsKeysStart
		|
		|GROUP BY
		|	GroupsKeysStart.NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT TOP 10000000
		|	Products_1.NumberOfGroup         AS NumberOfGroup,
		|	RECORDAUTONUMBER()           AS Order,
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	Products_1.Key                AS Key
		|INTO ProductQueue
		|FROM
		|	Products_1 AS Products_1
		|
		|	LEFT JOIN GroupsStart AS GroupsStart
		|	ON Products_1.NumberOfGroup = GroupsStart.NumberOfGroup
		|WHERE
		|	Products_1.ProductionOrder <> VALUE(Document.ProductionOrder2_2.EmptyRef)
		|
		|ORDER BY
		|	Products_1.ProductionOrder.Priority.AddlOrderingAttribute,
		|	Products_1.ProductionOrder.Department.AddlOrderingAttribute,
		|	Products_1.ProductionOrder.Queue,
		|	Products_1.LineNumberProducts,
		|	ISNULL(GroupsStart.Begin, DATETIME(3999, 12, 31)),
		|	Products_1.Products.Description,
		|	Products_1.Characteristic.Description,
		|	Products_1.BillOfMaterials.Description,
		|	Products_1.NumberOfGroup
		|
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	ProductQueue.NumberOfGroup         AS NumberOfGroup,
		|	ProductQueue.Order             AS Order,
		|	ProductQueue.ProductionOrder AS ProductionOrder
		|INTO GroupQueue
		|FROM
		|	ProductQueue AS ProductQueue
		|WHERE
		|	ProductQueue.Order IN (
		|		SELECT
		|			MIN(T.Order)
		|		FROM
		|			ProductQueue AS T
		|		WHERE
		|			T.NumberOfGroup = ProductQueue.NumberOfGroup)
		|INDEX BY
		|	NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Groups.NumberOfGroup             AS NumberOfGroup,
		|	Groups.BillOfMaterials            AS BillOfMaterials,
		|	Groups.Organization             AS Organization,
		|	Groups.Partner                 AS Partner,
		|	Groups.Contract                 AS Contract,
		|	Groups.LineOfBusiness AS LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity    AS OrderForActivity,
		|	Groups.BusinessOperation   AS BusinessOperation,
		|	Groups.ProductionProcessType                               AS ProductionProcessType,
		|	ISNULL(StartupParameters.AssignmentProducts,
		|		VALUE(Catalog.Assignments.EmptyRef))                 AS AssignmentProducts,
		|	ISNULL(StartupParameters.ReferenceOrder,
		|		VALUE(Document.ProductionOrder2_2.EmptyRef))       AS ReferenceOrder,
		|	ISNULL(StartupParameters.ReferenceOrder.Number, """")               AS ProductionOrderNumber,
		|	ISNULL(StartupParameters.ReferenceOrder.Date, DATETIME(1,1,1))    AS ProductionOrderDate,
		|	ISNULL(GroupQueue.ProductionOrder.Priority,
		|		VALUE(Catalog.Priorities.EmptyRef))                 AS Priority,
		|	ISNULL(GroupQueue.ProductionOrder,
		|		VALUE(Document.ProductionOrder2_2.EmptyRef))       AS NextOrderInQueue,
		|	ISNULL(StartupParameters.StartDate2, &CurrentDate)                  AS EarliestStartDate,
		|	ISNULL(StartupParameters.RequestedCompletionDate, &CurrentDate)          AS DemandDate,
		|	ISNULL(StartupParameters.ProductionLotIDInProductGroup, """")          AS ProductionLotIDInProductGroup,
		|	ISNULL(StartupParameters.DurationBeforeProductionIssue, 0)                   AS DurationBeforeProductionIssue,
		|	ISNULL(StartupParameters.UnderRepairProduct,
		|		VALUE(Catalog.Products.EmptyRef))               AS UnderRepairProduct,
		|	ISNULL(StartupParameters.UnderRepairVariant,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS UnderRepairVariant,
		|	ISNULL(StartupParameters.UnderRepairBatch,
		|		VALUE(Catalog.ItemsBatches.EmptyRef))          AS UnderRepairBatch,
		|	GroupsOfMultipleAssignments.NumberOfGroup IS NOT NULL                AS MultipleAppointments
		|FROM
		|	Groups AS Groups
		|
		|	LEFT JOIN StartupParameters AS StartupParameters
		|	ON Groups.NumberOfGroup = StartupParameters.NumberOfGroup
		|
		|	LEFT JOIN GroupQueue AS GroupQueue
		|	ON Groups.NumberOfGroup = GroupQueue.NumberOfGroup
		|
		|	LEFT JOIN GroupsOfMultipleAssignments AS GroupsOfMultipleAssignments
		|	ON Groups.NumberOfGroup = GroupsOfMultipleAssignments.NumberOfGroup
		|
		|ORDER BY
		|	ISNULL(GroupQueue.Order, 1000000),
		|	Groups.NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|// The composition of the query fields is closely related to the procedure for dividing into optimal batches
		|
		|SELECT
		|	Products_1.NumberOfGroup              AS NumberOfGroup,
		|	Products_1.BillOfMaterials             AS BillOfMaterials,
		|	Products_1.LineOfBusiness  AS LineOfBusiness,
		|	Products_1.ProductionDispatcherBusinessUnit   AS ProductionDispatcherBusinessUnit,
		|	Products_1.Products             AS Products,
		|	Products_1.Characteristic           AS Characteristic,
		|	Products_1.ToExpenseAs         AS ToExpenseAs,
		|	Products_1.ExpenseItem           AS ExpenseItem,
		|	Products_1.DimensionOfExpenses        AS DimensionOfExpenses,
		|	Products_1.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	Products_1.QuantityPerBatch       AS QuantityPerBatch,
		|	
		|	Products_1.Recipient               AS Recipient,
		|	CASE
		|		WHEN Products_1.Recipient REFS Catalog.Warehouses
		|			THEN Products_1.Recipient
		|		ELSE UNDEFINED
		|	END                            AS Warehouse,
		|	CASE
		|		WHEN Products_1.Recipient REFS Catalog.BusinessStructure
		|			THEN Products_1.Recipient
		|		ELSE UNDEFINED
		|	END                            AS Department,
		|	
		|	Products_1.Purpose               AS Purpose,
		|	
		|	ISNULL(
		|		StartupParameters.ReferenceOrder,
		|		VALUE(Document.ProductionOrder2_2.EmptyRef)) AS ReferenceOrder,
		|	
		|	SUM(Products_1.QuantityStandard) AS QuantityStandard,
		|	
		|	ISNULL(StartupParameters.StartDate2, &CurrentDate)   AS StartDate2,
		|	MIN(Products_1.LaunchDateStandard)                   AS LaunchDateStandard,
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN ProductDates.StartDate2
		|		ELSE DATETIME(1,1,1)
		|	END                                                  AS LaunchDateGrouping,
		|	
		|	ISNULL(StartupParameters.RequestedCompletionDate, &CurrentDate) AS RequestedCompletionDate,
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN ProductDates.RequestedCompletionDate
		|		ELSE DATETIME(1,1,1)
		|	END                                                  AS DesiredReleaseDateGrouping,
		|	
		|	MAX(Products_1.AvailableReleaseFromAssignedmMaterials) AS AvailableReleaseFromAssignedmMaterials,
		|	
		|	COUNT(DISTINCT(Products_1.KeyLot))              AS QuantityOfBatches,
		|	CASE
		|		WHEN COUNT(DISTINCT(Products_1.KeyLot)) = 1
		|			THEN MIN(Products_1.KeyLot)
		|		ELSE &EmptyLinkKey
		|	END                                                  AS KeyLot,
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN Products_1.KeyLot
		|		ELSE &EmptyLinkKey
		|	END                                                  AS KeyLotReferenceGrouping,
		|	
		|	CASE
		|		WHEN Products_1.SupplyAssignment <> VALUE(Catalog.Assignments.EmptyRef)
		|			THEN Products_1.SupplyAssignment
		|		ELSE StartupParameters.OrderAppointment
		|	END AS SupplyAssignment,
		|	MAX(ISNULL(ProductsForSeveralPurposes.QuantityForLaunchLotUnit, 0)) AS QuantityForLaunchLotUnit,
		|	
		|	MAX(Products_1.Level) AS Level,
		|	MAX(Products_1.DurationBeforeProductionIssue) AS DurationBeforeProductionIssue,
		|	MIN(Products_1.ProductionLotIDInProductGroup) AS ProductionLotIDInProductGroup,
		|
		|	SUM(Products_1.Count)               AS Count,
		|	
		|	ISNULL(GroupQueue.Order, 1000000)            AS Order1,
		|	MIN(ISNULL(ProductQueue.Order, 1000000)) AS Order2
		|FROM
		|	Products_1 AS Products_1
		|
		|	LEFT JOIN StartupParameters AS StartupParameters
		|	ON Products_1.NumberOfGroup = StartupParameters.NumberOfGroup
		|
		|	LEFT JOIN GroupQueue AS GroupQueue
		|	ON Products_1.NumberOfGroup = GroupQueue.NumberOfGroup
		|
		|	LEFT JOIN ProductQueue AS ProductQueue
		|	ON Products_1.Key = ProductQueue.Key
		|
		|	LEFT JOIN ProductDates AS ProductDates
		|	ON Products_1.Key = ProductDates.Key
		|
		|	LEFT JOIN GroupsToBeDividedIntoOptimalBatches AS GroupsToBeDividedIntoOptimalBatches
		|	ON Products_1.NumberOfGroup = GroupsToBeDividedIntoOptimalBatches.NumberOfGroup
		|
		|	LEFT JOIN ProductsForSeveralPurposes AS ProductsForSeveralPurposes
		|	ON Products_1.NumberOfGroup = ProductsForSeveralPurposes.NumberOfGroup
		|		AND Products_1.Products = ProductsForSeveralPurposes.Products
		|		AND Products_1.Characteristic = ProductsForSeveralPurposes.Characteristic
		|		AND Products_1.SupplyAssignment = ProductsForSeveralPurposes.SupplyAssignment
		|
		|GROUP BY
		|	Products_1.NumberOfGroup,
		|	Products_1.BillOfMaterials,
		|	Products_1.LineOfBusiness,
		|	Products_1.ProductionDispatcherBusinessUnit,
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.ToExpenseAs,
		|	Products_1.ExpenseItem,
		|	Products_1.DimensionOfExpenses,
		|	Products_1.AssetsLiabilitiesDimension,
		|	Products_1.QuantityPerBatch,
		|	Products_1.Recipient,
		|	CASE
		|		WHEN Products_1.Recipient REFS Catalog.Warehouses
		|			THEN Products_1.Recipient
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN Products_1.Recipient REFS Catalog.BusinessStructure
		|			THEN Products_1.Recipient
		|		ELSE UNDEFINED
		|	END,
		|	Products_1.Purpose,
		|	ISNULL(StartupParameters.ReferenceOrder, VALUE(Document.ProductionOrder2_2.EmptyRef)),
		|	ISNULL(StartupParameters.StartDate2, &CurrentDate),
		|	ISNULL(StartupParameters.RequestedCompletionDate, &CurrentDate),
		|	ISNULL(GroupQueue.Order, 1000000),
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN ProductDates.StartDate2
		|		ELSE DATETIME(1,1,1)
		|	END,
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN ProductDates.RequestedCompletionDate
		|		ELSE DATETIME(1,1,1)
		|	END,
		|	CASE
		|		WHEN GroupsToBeDividedIntoOptimalBatches.NumberOfGroup IS NOT NULL
		|			THEN Products_1.KeyLot
		|		ELSE &EmptyLinkKey
		|	END,
		|	CASE
		|		WHEN Products_1.SupplyAssignment <> VALUE(Catalog.Assignments.EmptyRef)
		|			THEN Products_1.SupplyAssignment
		|		ELSE StartupParameters.OrderAppointment
		|	END
		|
		|ORDER BY
		|	Order1,
		|	Order2,
		|	Products_1.NumberOfGroup
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	FinishedProductsToBeDividedIntoOptimalBatches.NumberOfGroup AS NumberOfGroup,
		|
		|	FinishedProductsToBeDividedIntoOptimalBatches.EconomicReleaseLot AS EconomicReleaseLot,
		|	FinishedProductsToBeDividedIntoOptimalBatches.MinimumReleaseLot AS MinimumReleaseLot,
		|	FinishedProductsToBeDividedIntoOptimalBatches.PermissibleExcessOfOptimalReleaseLot AS PermissibleExcessOfOptimalReleaseLot,
		|	FinishedProductsToBeDividedIntoOptimalBatches.ProductionIssueByCustomPortions AS ProductionIssueByCustomPortions,
		|
		|	FinishedProductsToBeDividedIntoOptimalBatches.Products AS Products,
		|	FinishedProductsToBeDividedIntoOptimalBatches.Package AS Package,
		|	FinishedProductsToBeDividedIntoOptimalBatches.NumberOfPackagesPerStartingLotUnit AS NumberOfPackagesPerUnitOfProductionBatch,
		|	FinishedProductsToBeDividedIntoOptimalBatches.ThisIsMainProduct AS ThisIsMainProduct,
		|	UNDEFINED AS PackageData,
		|	
		|	FinishedProductsToBeDividedIntoOptimalBatches.MainFinishedProductSpecificationsItem AS MainFinishedProductSpecificationsItem,
		|	FinishedProductsToBeDividedIntoOptimalBatches.MainFinishedProductSpecificationsPackagingUnits AS MainFinishedProductSpecificationsPackagingUnits,
		|	FinishedProductsToBeDividedIntoOptimalBatches.MainFinishedProductSpecificationsNumberOfPackagingUnitsPerUnitOfLaunchBatch AS MainFinishedProductSpecificationsNumberOfPackagingUnitsPerBatchUnit,
		|	
		|	FinishedProductsToBeDividedIntoOptimalBatches.Count AS Count
		|FROM
		|	FinishedProductsToBeDividedIntoOptimalBatches AS FinishedProductsToBeDividedIntoOptimalBatches
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Products_1.NumberOfGroup         AS NumberOfGroup,
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	Products_1.KeyLot          AS KeyLot
		|FROM
		|	Products_1 AS Products_1
		|WHERE
		|	NOT Products_1.ExceedingOrder
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Products_1.NumberOfGroup        AS NumberOfGroup,
		|	CASE
		|		WHEN Products_1.SupplyAssignment <> VALUE(Catalog.Assignments.EmptyRef)
		|			THEN Products_1.SupplyAssignment
		|		ELSE StartupParameters.OrderAppointment
		|	END                      AS Purpose,
		|	MIN(Products_1.Order)   AS Order,
		|	SUM(Products_1.Count/Products_1.QuantityForLaunchLotUnit)
		|		/ MAX(Totals.Total) AS ZoomRatio
		|FROM
		|	ProductsForSeveralPurposes AS Products_1
		|
		|	INNER JOIN ResultsOfSeveralAppointments AS Totals
		|	ON Products_1.NumberOfGroup = Totals.NumberOfGroup
		|
		|	INNER JOIN StartupParameters AS StartupParameters
		|	ON Products_1.NumberOfGroup = StartupParameters.NumberOfGroup
		|WHERE
		|	Products_1.QuantityForLaunchLotUnit <> 0
		|
		|GROUP BY
		|	Products_1.NumberOfGroup,
		|	CASE
		|		WHEN Products_1.SupplyAssignment <> VALUE(Catalog.Assignments.EmptyRef)
		|			THEN Products_1.SupplyAssignment
		|		ELSE StartupParameters.OrderAppointment
		|	END
		|
		|ORDER BY
		|	NumberOfGroup,
		|	Order";
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsBOM.Package", "ProductsBOM.Products"));
	
	QueryTexts.Add(QueryText);
	
	DescriptionOfTables = New Array;
	
	TableDetails = ProductDataManagement.DescriptionOfQueryTextTablePackageData();
	TableDetails.TableName = "FinishedProductsToBeDividedIntoOptimalBatches";
	DescriptionOfTables.Add(TableDetails);
	
	TableDetails = ProductDataManagement.DescriptionOfQueryTextTablePackageData();
	TableDetails.TableName = "FinishedProductsToBeDividedIntoOptimalBatches";
	TableDetails.SourceOfProducts = "T.MainFinishedProductSpecificationsItem";
	TableDetails.SourceOfPackaging = "T.MainFinishedProductSpecificationsPackagingUnits";
	DescriptionOfTables.Add(TableDetails);
	
	QueryText = ProductDataManagement.QueryTextPackageData_(DescriptionOfTables);
	QueryTexts.Add(QueryText);
	
	Query.Text = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	Query.SetParameter("CurrentDateIsEndOfDay", EndOfDay(CurrentDate));
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("TheProductionScheduleIsUsed", TheProductionScheduleIsUsed);
	Query.SetParameter("CalculateScheduleFromCurrentDate", CalculateScheduleFromCurrentDate);
	Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
	Query.SetParameter("StartingDate", BegOfDay(CurrentDate));
	Query.SetParameter("CurrentYear", Year(CurrentDate));
	Query.SetParameter("NextYear", Year(CurrentDate)+1);
	Query.SetParameter("LastDayOfYear", BegOfDay(EndOfYear(CurrentDate)));
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	NumberOfPackages_ = QueryResult.Count();
	
	Groups = QueryResult[NumberOfPackages_-6].Unload();
	Products_1 = QueryResult[NumberOfPackages_-5].Unload();
	ParametersOfOptimalBatches = QueryResult[NumberOfPackages_-4].Unload();
	PartyKeys = QueryResult[NumberOfPackages_-3].Unload();
	AssignmentsOfMaterials = QueryResult[NumberOfPackages_-2].Unload();
	PackageData_ = QueryResult[NumberOfPackages_-1].Unload();
	
	// Division into optimal batches
	Products_1.Columns.Add("BatchNumberInGroup", New TypeDescription("Number"));
	AssignmentsOfMaterials.Columns.Add("BatchNumberInGroup", New TypeDescription("Number"));
	If ParametersOfOptimalBatches.Count() <> 0 Then
		SplitIntoOptimalBatches(Products_1, AssignmentsOfMaterials, ParametersOfOptimalBatches, PackageData_);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Groups", Groups);
	Result.Insert("Products_1", Products_1);
	Result.Insert("PartyKeys", PartyKeys);
	Result.Insert("AssignmentsOfMaterials", AssignmentsOfMaterials);
	
	Return Result;
	
EndFunction

// Break it down into optimal Lot references.
// 
// Parameters:
//  Products_1 - ValueTable
//  ParametersOfOptimalBatches - ValueTable
//  PackageData_ - ValueTable
//
&AtServer
Procedure SplitIntoOptimalBatches(Products_1, AssignmentsOfMaterials, ParametersOfOptimalBatches, PackageData_)
	
	ProductDataManagement.FillInPackingDataInDataset(ParametersOfOptimalBatches, PackageData_);
	DefaultPackagingStructure = ProductDataManagementCached.PackingDataStructure();
	
	Products_1.Indexes.Add("NumberOfGroup");
	
	AssignmentsOfMaterials.Indexes.Add("NumberOfGroup");
	PartyAppointments = AssignmentsOfMaterials.CopyColumns("Purpose, ZoomRatio"); // ValueTable
	
	SearchStructureGroupNumber = New Structure("NumberOfGroup");
	SearchStructureProduct = New Structure("Products, Characteristic");
	
	SpecificationData = New Structure;
	SpecificationData.Insert("EconomicReleaseLot");
	SpecificationData.Insert("MinimumReleaseLot");
	SpecificationData.Insert("PermissibleExcessOfOptimalReleaseLot");
	SpecificationData.Insert("ProductionIssueByCustomPortions");
	SpecificationData.Insert("MainProduct");
	
	PartyItems = New Array;
	EmptyKeyLotReference = New UUID("00000000-0000-0000-0000-000000000000");
	
	LaunchDateOfLotReference = Undefined;
	DesiredLotReferenceReleaseDate = Undefined;
	
	LaunchDateStandardLotReference = Undefined;
	OrderOf2LotReferences = Undefined;
	LotReferenceLevel = Undefined;
	DurationUntilReleaseOfLotReference = Undefined;
	IdInProductGroupOfLotReference = Undefined;
	
	For Each Var_Group In ParametersOfOptimalBatches Do
		
		// Simulation of specification data structures
		SpecificationData.EconomicReleaseLot = Var_Group.EconomicReleaseLot;
		SpecificationData.MinimumReleaseLot = Var_Group.MinimumReleaseLot;
		SpecificationData.PermissibleExcessOfOptimalReleaseLot = Var_Group.PermissibleExcessOfOptimalReleaseLot;
		SpecificationData.ProductionIssueByCustomPortions = Var_Group.ProductionIssueByCustomPortions;
		
		MainProduct = Catalogs.BillsOfMaterials.MainProductSpecificationDataStructure();
		FillPropertyValues(MainProduct, Var_Group,
			"Products, Package, PackageData, ThisIsMainProduct, NumberOfPackagesPerUnitOfProductionBatch");
		If Not Var_Group.ThisIsMainProduct Then
			MainProductSpecifications  = New Structure;
			MainProductSpecifications.Insert("Products", Var_Group.MainFinishedProductSpecificationsItem);
			MainProductSpecifications.Insert("Package", Var_Group.MainFinishedProductSpecificationsPackagingUnits);
			MainProductSpecifications.Insert("NumberOfPackagesPerUnitOfProductionBatch", Var_Group.MainFinishedProductSpecificationsNumberOfPackagingUnitsPerBatchUnit);
			MainProductSpecifications.Insert("PackageData", DefaultPackagingStructure);
			If ValueIsFilled(MainProductSpecifications.Package) Then
				ProductDataManagement.FillInPackingDataInDataSetRow(
					MainProductSpecifications, PackageData_);
			EndIf;
			ProductDataManagement.FillInConversionFactorToMainProduct(
				MainProduct, MainProductSpecifications);
		EndIf;
		SpecificationData.MainProduct = MainProduct;
		
		// Receiving batches
		Lots = Catalogs.BillsOfMaterials.BreakIntoOptimalReleaseBatches(
			Var_Group.Count,
			SpecificationData);
		
		// Separation of products into batches
		SearchStructureGroupNumber.NumberOfGroup = Var_Group.NumberOfGroup;
		ProductsOfGroup = Products_1.FindRows(SearchStructureGroupNumber);
		
		FoundRows = AssignmentsOfMaterials.FindRows(SearchStructureGroupNumber);
		ThereAreAssignmentsForMaterials = FoundRows.Count() > 0;
		For Each String In FoundRows Do
			AssignmentsOfMaterials.Delete(String);
		EndDo;
		
		Products_1Balance = Products_1.Copy(ProductsOfGroup, "Products, Characteristic, QuantityPerBatch");
		Products_1Balance.GroupBy("Products, Characteristic, QuantityPerBatch");
		Products_1Balance.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3)));
		
		For IndexOf = 0 To Lots.UBound() Do
			
			For Each String In Products_1Balance Do
				String.Count = String.QuantityPerBatch * Lots[IndexOf].Numerator / Lots[IndexOf].Denominator;
			EndDo;
			
			For Each Product In ProductsOfGroup Do
				If Product.Count = 0 Then
					Continue;
				EndIf;
				
				FillPropertyValues(SearchStructureProduct, Product);
				StringBalance = Products_1Balance.FindRows(SearchStructureProduct)[0];
				If StringBalance.Count = 0 Then
					Continue;
				EndIf;
				
				NewRow = Products_1.Add();
				FillPropertyValues(NewRow, Product,, "Count");
				NewRow.BatchNumberInGroup = IndexOf + 1;
				NewRow.Count = Min(Product.Count, StringBalance.Count);
				
				Product.Count = Product.Count - NewRow.Count;
				StringBalance.Count = StringBalance.Count - NewRow.Count;
				
				PartyItems.Add(NewRow);
				
				If LaunchDateOfLotReference = Undefined Then
					LaunchDateOfLotReference = NewRow.LaunchDateGrouping;
					DesiredLotReferenceReleaseDate = NewRow.DesiredReleaseDateGrouping;
					
					LaunchDateStandardLotReference = NewRow.LaunchDateStandard;
					OrderOf2LotReferences = NewRow.Order2;
					LotReferenceLevel = NewRow.Level;
					DurationUntilReleaseOfLotReference = NewRow.DurationBeforeProductionIssue;
					IdInProductGroupOfLotReference = NewRow.ProductionLotIDInProductGroup;
				Else
					LaunchDateOfLotReference = Min(LaunchDateOfLotReference, NewRow.LaunchDateGrouping);
					DesiredLotReferenceReleaseDate = Min(DesiredLotReferenceReleaseDate, NewRow.DesiredReleaseDateGrouping);
					
					LaunchDateStandardLotReference = Min(LaunchDateStandardLotReference, NewRow.LaunchDateStandard);
					OrderOf2LotReferences = Min(OrderOf2LotReferences, NewRow.Order2);
					LotReferenceLevel = Max(LotReferenceLevel, NewRow.Level);
					DurationUntilReleaseOfLotReference = Max(DurationUntilReleaseOfLotReference, NewRow.DurationBeforeProductionIssue);
					IdInProductGroupOfLotReference = Max(IdInProductGroupOfLotReference, NewRow.ProductionLotIDInProductGroup);
				EndIf;
			EndDo;
			
			For Each Product In PartyItems Do
				Product.StartDate2 = LaunchDateOfLotReference;
				Product.LaunchDateGrouping = '00010101';
				Product.RequestedCompletionDate = DesiredLotReferenceReleaseDate;
				Product.DesiredReleaseDateGrouping = '00010101';
				
				Product.LaunchDateStandard = LaunchDateStandardLotReference;
				Product.Order2 = OrderOf2LotReferences;
				Product.Level = LotReferenceLevel;
				Product.DurationBeforeProductionIssue = DurationUntilReleaseOfLotReference;
				Product.ProductionLotIDInProductGroup = IdInProductGroupOfLotReference;
				
				Product.KeyLot = ?(PartyItems.Count() = 1, Product.KeyLot, EmptyKeyLotReference);
				Product.KeyLotReferenceGrouping = EmptyKeyLotReference;
				
				If ThereAreAssignmentsForMaterials
					And Product.QuantityForLaunchLotUnit <> 0 Then
					NewRow = PartyAppointments.Add();
					NewRow.Purpose = Product.SupplyAssignment;
					NewRow.ZoomRatio = Product.Count / Product.QuantityForLaunchLotUnit;
				EndIf;
			EndDo;
			
			If PartyAppointments.Count() > 0 Then
				PartyAppointments.GroupBy("Purpose", "ZoomRatio");
				
				Total = PartyAppointments.Total("ZoomRatio");
				For Each String In PartyAppointments Do
					NewRow = AssignmentsOfMaterials.Add();
					NewRow.NumberOfGroup = Var_Group.NumberOfGroup;
					NewRow.BatchNumberInGroup = IndexOf + 1;
					NewRow.Purpose = String.Purpose;
					NewRow.ZoomRatio = String.ZoomRatio / Total;
				EndDo;
				
				PartyAppointments.Clear();
			EndIf;
			
			PartyItems.Clear();
			
			LaunchDateOfLotReference = Undefined;
			DesiredLotReferenceReleaseDate = Undefined;
			
			LaunchDateStandardLotReference = Undefined;
			OrderOf2LotReferences = Undefined;
			LotReferenceLevel = Undefined;
			DurationUntilReleaseOfLotReference = Undefined;
			IdInProductGroupOfLotReference = Undefined;
			
		EndDo;
		
		For Each Product In ProductsOfGroup Do
			Products_1.Delete(Product);
		EndDo;
		
	EndDo;
	
	ColumnsNames = New Array;
	For Each Column In Products_1.Columns Do
		If Column.Name <> "QuantityStandard"
			And Column.Name <> "Count"
			And Column.Name <> "QuantityOfBatches" Then
			ColumnsNames.Add(Column.Name);
		EndIf;
	EndDo;
	GroupingColumns = StrConcat(ColumnsNames, ",");
	
	Products_1.GroupBy(GroupingColumns, "QuantityStandard, Count, QuantityOfBatches");
	Products_1.Sort("Order1, Order2, NumberOfGroup");
	
EndProcedure

#EndRegion

#Region Filters

&AtServer
Procedure InitializeSettingsComposer()
	
	DataCompositionSchema = DataProcessors.GeneratingProductionStages.GetTemplate("ItemPlan");
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
 	
	SettingsComposer.Initialize(SettingsSource);
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure

&AtClient
Function ReflectLayoutSelectionInSimpleSelections()
	
	SelectionID_ = SettingsComposer.Settings.Filter.UserSettingID;
	Filter = SettingsComposer.UserSettings.Items.Find(SelectionID_);
	For Each FilterElement In Filter.Items Do
		If FilterElement.Use Then 
			Return False;
		EndIf;
	EndDo;
	
	SimpleSelections = 
		"LineOfBusiness,
		|ProductionDispatcherBusinessUnit,
		|ResponsibleBusinessUnit,
		|Organization,
		|ProductionOrder,
		|BillOfMaterials,
		|Products,
		|Warehouse,
		|Purpose,
		|StartDate2,
		|DateOfProduction";
	
	ThereIsSelectionByLaunchDate = False;
	ThereIsSelectionByReleaseDate = False;
	SelectionByDateValue = '00010101';
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		
		If UserSettingItem <> Undefined
			 And UserSettingItem.Use
			 And TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			 
			 FieldName = String(FilterElement.LeftValue);
			 If Not StrFind(SimpleSelections, FieldName) > 0 Then
				 Return False;
			 ElsIf FieldName = "StartDate2" Then
				 If UserSettingItem.ComparisonType <> DataCompositionComparisonType.LessOrEqual Then
					 Return False;
				 EndIf;
				 ThereIsSelectionByLaunchDate = True;
				 SelectionByDateValue = ?(TypeOf(UserSettingItem.RightValue) = Type("StandardBeginningDate"),
				 	UserSettingItem.RightValue.Date,
					UserSettingItem.RightValue);
			 ElsIf FieldName = "DateOfProduction" Then
				 If UserSettingItem.ComparisonType <> DataCompositionComparisonType.LessOrEqual Then
					 Return False;
				 EndIf;
				 ThereIsSelectionByReleaseDate = True;
				 SelectionByDateValue = ?(TypeOf(UserSettingItem.RightValue) = Type("StandardBeginningDate"),
				 	UserSettingItem.RightValue.Date,
					UserSettingItem.RightValue);
			 ElsIf UserSettingItem.ComparisonType <> DataCompositionComparisonType.Equal Then
				 Return False;
			 EndIf;
			 
		EndIf;
		
		If UserSettingItem <> Undefined
			 And UserSettingItem.Use
			 And TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			Return False;
		EndIf;
		
	EndDo;
	
	If ThereIsSelectionByLaunchDate And ThereIsSelectionByReleaseDate Then
		Return False;
	ElsIf ThereIsSelectionByLaunchDate Then
		PeriodVariant = 0;
	ElsIf ThereIsSelectionByReleaseDate Then
		PeriodVariant = 1;
	EndIf;
	SelectionByDate_1 = SelectionByDateValue;
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		UserSettingItem = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		If UserSettingItem <> Undefined
			And TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			
			FillOutSimpleSelection(FilterByLineOfBusiness,
				"LineOfBusiness", PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(SelectionByDivisionDispatcher,
				"ProductionDispatcherBusinessUnit", PredefinedValue("Catalog.BusinessStructure.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(SelectionByResponsibleDivision,
				"ResponsibleBusinessUnit", PredefinedValue("Catalog.BusinessStructure.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByOrder,
				"ProductionOrder", PredefinedValue("Document.ProductionOrder2_2.EmptyRef"), 
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByBillOfMaterials,
				"BillOfMaterials", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"),
				FilterElement, UserSettingItem);
			
			FillOutSimpleSelection(FilterRemainingGoodsByShelfLives,
				"Products", PredefinedValue("Catalog.Products.EmptyRef"),
				FilterElement, UserSettingItem);
		
			FillOutSimpleSelection(FilterByWarehouse,
				"Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"),
				FilterElement, UserSettingItem);
			
			FillOutSimpleSelection(FilterByAssignment,
				"Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"),
				FilterElement, UserSettingItem);
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure FillOutSimpleSelection(FormAttribute, FieldName, DefaultValue, FilterElement, UserSettingItem)
	
	LayoutField = New DataCompositionField(FieldName);
	
	If LayoutField = FilterElement.LeftValue Then
		
		FormAttribute = ?(UserSettingItem.Use,
			UserSettingItem.RightValue, DefaultValue);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ReflectSimpleSelectionInLayoutSelections(SettingsComposer, FieldName, Value)
	
	SearchValue = New DataCompositionField(FieldName);
	For Each Filter In SettingsComposer.Settings.Filter.Items Do
		If Filter.LeftValue = SearchValue Then
			Setting = SettingsComposer.UserSettings.Items.Find(Filter.UserSettingID);
			If Setting <> Undefined Then
				Setting.Use = ValueIsFilled(Value);
				If Setting.Use Then
					Setting.ComparisonType = ?(FieldName = "StartDate2" Or FieldName = "DateOfProduction",
						DataCompositionComparisonType.LessOrEqual,
						DataCompositionComparisonType.Equal);
					Setting.RightValue = Value;
				EndIf;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
#Region PlanResults
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanResultsProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanResultsLaunch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.Mark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsSupplied.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.SupplyIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.PlanResults.BillOfMaterialsPlan");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsSupplied.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Object.PlanResults.BillOfMaterialsPlan");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsLaunchDateMinimum.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsLaunchDateMinimumByGroup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.LaunchDateMinimumByGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsReleaseDateMinimum.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanResultsReleaseDateMinimumByGroup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.ReleaseDateMinimumByGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
#EndRegion
	
#Region Plan
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProductionOrderPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.ExceedingOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<vượt quá đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanLaunch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Mark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanSupplied.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.SupplyIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Plan.BillOfMaterialsPlan");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanSupplied.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Object.Plan.BillOfMaterialsPlan");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Query = New Query(
		"SELECT
		|	Priorities.Ref AS Priority,
		|	Priorities.Color   AS Color
		|FROM
		|	Catalog.Priorities AS Priorities");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
	 
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PlanPriority.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Priority");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Selection.Priority;
		
		Color = Selection.Color; //ValueStorage
		Item.Appearance.SetParameterValue("TextColor", Color.Get());
		
	EndDo;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanAvailableReleaseFromAssignedmMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.AvailableReleaseFromAssignedmMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreviewAvailableReleaseFromAssignedmMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsToPreview.AvailableReleaseFromAssignedmMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Plan.AssignmentRecipient");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.AssignedPurchaseSale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanStartDate2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.StartDate2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanDateOfProduction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.DateOfProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanRequestedCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.RequestedCompletionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanUnderRepairProduct.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanUnderRepairVariant.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanUnderRepairBatch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.PerformRM;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanRequestedCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanResults.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.Disassembly;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
#EndRegion

#Region ResultOfFormation
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ResultOfFormationPictureNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ResultOfFormation.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
		
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ResultOfFormationPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ResultOfFormation.HasErrors");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	
#EndRegion
	
#Region Preview
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreviewProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreviewCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsToPreview.ThisIsTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreview.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsToPreview.ThisIsTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(, , True));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreviewEarliestStartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsToPreview.ThisIsTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsToPreviewDemandDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsToPreview.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.Disassembly;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
#EndRegion
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.OrderStructure.Visible = AccessRight("View", Metadata.Reports.ProductionOrderStructureDynamic);

	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, DataProcessors.GeneratingProductionStages);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.PlanResultsBillOfMaterials, BOMSelectionParameters); 
	
	ScheduleDateFormat = ProductionManagement.FormatStringForProductionScheduleDate();
	Items.ProductsToPreviewEarliestStartDate.Format = ScheduleDateFormat;
	Items.ProductsToPreviewEarliestStartDate.EditFormat = ScheduleDateFormat;
	Items.ProductsToPreviewDemandDate.Format = ScheduleDateFormat;
	
	If TheProductionScheduleIsUsed Then
		Items.ProductsToPreviewEarliestStartDate.ReadOnly = False;
		Items.ProductsToPreviewEarliestStartDate.HeaderPicture = PictureLib.Change;
		Items.StartFillingInFormNoEarlierThan.Visible = True;
	Else
		Items.ProductsToPreviewEarliestStartDate.ReadOnly = True;
		Items.ProductsToPreviewEarliestStartDate.HeaderPicture = New Picture();
		Items.StartFillingInFormNoEarlierThan.Visible = False;
	EndIf;
	
	Items.FinishedProductsForPreviewFinishedProductGroup.Title = 
		?(GetFunctionalOption("UseItemVariants"),
			NStr("vi = 'Mặt hàng, Đặc tính, Bảng kê chi tiết, Đơn hàng sản xuất, Người nhận, Mục đích';
				|ru = 'Номенклатура, Характеристика, Спецификация, Заказ на производство, Получатель, Назначение';
				|en = 'Item, Variant, Bill of materials, Production order, Recipient, Assignment'; fa = 'Item, Variant, Bill of materials, Production order, Recipient, Assignment';
				|it = 'Item, Variant, Bill of materials, Production order, Recipient, Assignment';
				|pl = 'Item, Variant, Bill of materials, Production order, Recipient, Assignment';
				|tr = 'Öğe, Varyant, Ürün reçetesi, Üretim emri, Alıcı, Atama'"),
			NStr("vi = 'Mặt hàng, Bảng kê chi tiết, Đơn hàng sản xuất, Người nhận, Mục đích';
				|ru = 'Номенклатура, Спецификация, Заказ на производство, Получатель, Назначение';
				|en = 'Item, Bill of materials, Production order, Recipient, Assignment'; fa = 'Item, Bill of materials, Production order, Recipient, Assignment';
				|it = 'Item, Bill of materials, Production order, Recipient, Assignment';
				|pl = 'Item, Bill of materials, Production order, Recipient, Assignment';
				|tr = 'Öğe, Ürün reçetesi, Üretim emri, Alıcı, Atama'"));
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Show_Details") 
		Or Initialize Then
		
		Items.Plan.Visible = Form.Show_Details;
		Items.Show_Details.Title = ?(Form.Show_Details,
			NStr("vi = 'Thông tin chi tiết (ẩn)';
				|ru = 'Детальная информация (скрыть)';
				|en = 'Detailed information (hide)'; fa = 'Detailed information (hide)';
				|it = 'Informazioni dettagliate (nascondere)';
				|pl = 'Szczegółowe informacje (ukryj)';
				|tr = 'Ayrıntılı bilgi (gizle)'"),
			NStr("vi = 'Thông tin chi tiết (hiển thị)';
				|ru = 'Детальная информация (показать)';
				|en = 'Detailed information (show)'; fa = 'Detailed information (show)';
				|it = 'Informazione dettagliata (mostrare)';
				|pl = 'Szczegółowe informacje (pokaż)';
				|tr = 'Ayrıntılı bilgi (göster)'"));
		
	EndIf;
	
	If AttributesStructure1.Property("CurrentPage")
		Or AttributesStructure1.Property("DisplayParameters")
		Or Initialize Then
		
		Preview = Form.DisplayParameters.Preview;
		If Items.WizardPages.CurrentPage = Items.StepSelection Then
			
			Items.TheWritingStep.Title = ?(Preview,
				NStr("vi = 'Bước 1/4. Lọc';
					|ru = 'Шаг 1 из 4. Отбор';
					|en = 'Step 1 of 4. Filter'; fa = 'Step 1 of 4. Filter';
					|it = 'Passo 1 di 4. Filtro';
					|pl = 'Krok 1 z 4. Filtr';
					|tr = 'Adım 1/4. Filtre'"),
				NStr("vi = 'Bước 1/3. Lọc';
					|ru = 'Шаг 1 из 3. Отбор';
					|en = 'Step 1 of 3. Filter'; fa = 'Step 1 of 3. Filter';
					|it = 'Passo 1 di 3. Filtro';
					|pl = 'Krok 1 z 3. Filtr';
					|tr = 'Adım 1/3. Filtre'"));
			
		ElsIf Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan Then
			
			Items.TheWritingStep.Title = ?(Preview,
				NStr("vi = 'Bước 2/4. Xác định thành phần và khối lượng khởi động sản xuất';
					|ru = 'Шаг 2 из 4. Определение состава и объема запуска в производство';
					|en = 'Step 2 of 4. Decide what to launch and how much'; fa = 'Step 2 of 4. Decide what to launch and how much';
					|it = 'Passo 2 di 4. Definizione composizione e volume di avvio in produzione ';
					|pl = 'Krok 2 z 4. Określenie składu i objętości uruchomienia do produkcji';
					|tr = 'Adım 2/4. Üretime başlama içeriğinin ve hacminin tanımlanması'"),
				NStr("vi = 'Bước 2/3. Xác định thành phần và khối tượng khởi động sản xuất';
					|ru = 'Шаг 2 из 3. Определение состава и объема запуска в производство';
					|en = 'Step 2 of 3. Decide what to launch and how much'; fa = 'Step 2 of 3. Decide what to launch and how much';
					|it = 'Passo 2 di 3. Definizione della composizione e volume di avvio in produzione';
					|pl = 'Krok 2 z 3. Określenie składu i objętości uruchomienie do produkcji';
					|tr = 'Adım 2/3. Üretime başlama içeriğinin ve hacminin tanımlanması'"));
			
		ElsIf Items.WizardPages.CurrentPage = Items.StepPreview Then
			
			Items.TheWritingStep.Title = NStr("vi = 'Bước 3/4. Xem trước';
												|ru = 'Шаг 3 из 4. Предварительный просмотр';
												|en = 'Step 3 of 4. Preview'; fa = 'Step 3 of 4. Preview';
												|it = 'Passo 3 di 4. Anteprima';
												|pl = 'Krok 3 z 4. Podgląd';
												|tr = 'Adım 3/4: Önizleme'");
			
		ElsIf Items.WizardPages.CurrentPage = Items.StepResultOfFormation Then
			
			Items.TheWritingStep.Title = ?(Preview,
				NStr("vi = 'Bước 4/4. Làm rõ chứng từ đã lập';
					|ru = 'Шаг 4 из 4. Уточнение сформированных документов';
					|en = 'Step 4 of 4. Specify generated documents'; fa = 'Step 4 of 4. Specify generated documents';
					|it = 'Passo 4 di 4. Definizione dei documenti creati';
					|pl = 'Krok 4 z 4. Uściślenie utworzonych dokumentów';
					|tr = 'Adım 4/4. Oluşturulan belgelerin netleştirilmesi'"),
				NStr("vi = 'Bước 3/3. Làm rõ chứng từ đã lập';
					|ru = 'Шаг 3 из 3. Уточнение сформированных документов';
					|en = 'Step 3 of 3. Specify generated documents'; fa = 'Step 3 of 3. Specify generated documents';
					|it = 'Passo 3 di 3. Definizione dei documenti creati';
					|pl = 'Krok 3 z 3. Uściślenie utworzonych dokumentów';
					|tr = 'Adım 3/3. Oluşturulan belgelerin netleştirilmesi'"));
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("DisplayParameters")
		Or Initialize Then
			
		Items.PlanResultsLaunchDateMinimum.Visible = Not Form.DisplayParameters.CrossTable;
		Items.PlanResultsReleaseDateMinimum.Visible = Not Form.DisplayParameters.CrossTable;
		Items.PlanResultsLaunchDateMinimumByGroup.Visible = Form.DisplayParameters.CrossTable;
		Items.PlanResultsReleaseDateMinimumByGroup.Visible = Form.DisplayParameters.CrossTable;
		
	EndIf;
	
	If AttributesStructure1.Property("FilterSoftware")
		Or Initialize Then
		
		Form.Items.HyperlinkAllProducts.TextColor = ?(Form.FilterProvidesCurValue <> SoftwareFilterIsDisabled(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Form.Items.HyperlinkProvided.TextColor = ?(Form.FilterProvidesCurValue <> FilterSecurityIsProvided(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Form.Items.HyperlinkNotProvided.TextColor = ?(Form.FilterProvidesCurValue <> NoSoftwareIsProvided(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
	EndIf;
	
	If AttributesStructure1.Property("ResultOfFormation")
		Or Initialize Then
		
		HasErrors = False;
		For Each String In Form.ResultOfFormation.GetItems() Do
			If String.HasErrors Then
				HasErrors = True;
				Break;
			EndIf;
		EndDo;
		Items.ErrorActionGroup.Visible = HasErrors;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpWaitingInForm(ShowTimeConsumingOperation, PresentationOperation = "")
	
	Items.FormPages.CurrentPage = ?(ShowTimeConsumingOperation,
		Items.TimeConsumingOperationPage, Items.PageElements);
	Items.Transition.Enabled = Not ShowTimeConsumingOperation;
	
	Items.TimeConsumingOperationPresentation.Title = PresentationOperation;
	
EndProcedure

&AtClientAtServerNoContext
Procedure InstallAssistantPages(Form, StepName)
	
	Items = Form.Items;
	
	If StepName = "StepSelection" Then
		
		Items.WizardPages.CurrentPage = Items.StepSelection;
		
		Items.Next.Visible = True;
		Items.Back.Visible = False;
		Items.ContinueWithOtherFilters.Visible = False;
		Items.Next.DefaultButton = True;
		
	ElsIf StepName = "StepNomenclaturePlan" Then
		
		Items.WizardPages.CurrentPage = Items.StepNomenclaturePlan;
		
		Items.Next.Visible = True;
		Items.Back.Visible = True;
		Items.ContinueWithOtherFilters.Visible = False;
		Items.Next.DefaultButton = True;
		
	ElsIf StepName = "StepPreview" Then
		
		Items.WizardPages.CurrentPage = Items.StepPreview;
		
		Items.Next.Visible = True;
		Items.Back.Visible = True;
		Items.ContinueWithOtherFilters.Visible = False;
		Items.Next.DefaultButton = True;
		
	ElsIf StepName = "StepResultOfFormation" Then
		
		Items.WizardPages.CurrentPage = Items.StepResultOfFormation;
		
		Items.Next.Visible = False;
		Items.Back.Visible = True;
		Items.ContinueWithOtherFilters.Visible = True;
		Items.Close.DefaultButton = True;
		
	EndIf;
	
	ConfigureDependentFormElements(Form, "CurrentPage");
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(OutputIdleWindow = True)
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure SaveSelectionComposerSettings()
	
	Settings = New Structure();
	Settings.Insert("UserSettings", SettingsComposer.UserSettings);
	Common.CommonSettingsStorageSave("DataProcessor.GeneratingProductionStages", "SelectionComposer", Settings);
	
EndProcedure

&AtServer
Procedure SaveDocumentCreationParameters()
	
	Settings = New Structure();
	Settings.Insert("DocumentCreationOptions", DocumentCreationOptions);
	Common.CommonSettingsStorageSave("DataProcessor.GeneratingProductionStages", "DocumentCreationOptions", Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GeneratingProductionStages", "DocumentCreationOptions");

	//

	If TypeOf(SettingsValue) = Type("Structure") Then
		SettingsValue.Property("DocumentCreationOptions", DocumentCreationOptions);
	EndIf; 
	
	If DocumentCreationOptions = Undefined Then
		DocumentCreationOptions = DataProcessors.GeneratingProductionStages.DefaultDocumentCreationOptions();
	Else
		
		DefaultParameters = DataProcessors.GeneratingProductionStages.DefaultDocumentCreationOptions();
		
		For Each KeyAndValue In DefaultParameters Do
			If Not DocumentCreationOptions.Property(KeyAndValue.Key) Then
				DocumentCreationOptions.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndIf;
		EndDo;
		
		If DocumentCreationOptions.ReserveMaterials <> DocumentCreationOptions.ReplaceMaterialsWithAnalogs
		   And GetFunctionalOption("UseAlternativeMaterials") Then
			DocumentCreationOptions.ReplaceMaterialsWithAnalogs = DocumentCreationOptions.ReserveMaterials;
		EndIf;
		
	EndIf;

	SeparateProductionOfSemiFinishedProducts = DocumentCreationOptions.SeparateProductionOfSemiFinishedProducts;
	
	//
	
	If Not SelectionStructureIsFilledInAccordingToPassedParameters Then
	
		SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GeneratingProductionStages", "SelectionComposer");
	
		If TypeOf(SettingsValue) = Type("Structure") Then
			
			SettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			
		EndIf;
		
	EndIf;

	//
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GeneratingProductionStages", "DisplayParameters");
	
	If SettingsValue = Undefined Or Not TMCommonUseClientServer.StructureContainsKeys(SettingsValue, ListOfOutputParameters(), True) Then
		DisplayParameters = DefaultDisplayOptions();
	Else
		DisplayParameters = SettingsValue;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DefaultUserSettings_()
	
	DataCompositionSchema = DataProcessors.GeneratingProductionStages.GetTemplate("ItemPlan");
	
	SettingsSource = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(SettingsSource);
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	Return SettingsComposer.UserSettings;

EndFunction

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	SettingsComposer.LoadUserSettings(DefaultUserSettings_());
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure

&AtClientAtServerNoContext
Function ListOfOutputParameters()
	
	ListOfProperties = "CrossTable,Periodicity,NameOfPeriodDateField,NumberOfPeriods,Preview";
	Return ListOfProperties;
	
EndFunction

&AtClientAtServerNoContext
Function DefaultDisplayOptions()
	
	Result = New Structure();
	
	Result.Insert("CrossTable", False);
	Result.Insert("Periodicity", PredefinedValue("Enum.Periodicity.Month"));
	Result.Insert("NameOfPeriodDateField", "RequestedCompletionDate");
	Result.Insert("NumberOfPeriods", 10);
	Result.Insert("Preview", True);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeBatch()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function StringTypeStage()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetAdditionalSelectionOfLinesNomenclaturePlan(Form)
	
	FilterStructure1 = New Structure();
	
	If Form.OnlyChecked Then
		FilterStructure1.Insert("Mark", True);
	EndIf;
	
	If Not Form.FilterProvidesCurValue = SoftwareFilterIsDisabled() Then
		FilterStructure1.Insert("SupplyIsAvailable", Form.FilterProvidesCurValue = FilterSecurityIsProvided());
	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Form.Items.PlanResults.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Form.Items.PlanResults.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHyperlinkTextProvided()
	
	RowsCount = Object.PlanResults.Count();
	
	If RowsCount > 0 Then
		QuantityIsProvided   = Object.PlanResults.FindRows(New Structure("SupplyIsAvailable", True)).Count();
		QuantityIsNotSupplied = RowsCount - QuantityIsProvided;
	Else
		QuantityIsProvided   = 0;
		QuantityIsNotSupplied = 0;
	EndIf;
	
	Items.HyperlinkAllProducts.Title   = NStr("vi = 'Tất cả sản phẩm';
												|ru = 'Все изделия';
												|en = 'All products'; fa = 'همه محصولات';
												|it = 'Tutte le produzioni';
												|pl = 'Wszystkie wyroby';
												|tr = 'Tüm nihai ürünler'");
	Items.HyperlinkProvided.Title   = StrTemplate(NStr("vi = 'Đã đảm bảo (%1)';
														|ru = 'Обеспечено (%1)';
														|en = 'Supplied (%1)'; fa = 'Supplied (%1)';
														|it = 'Fornito (%1)';
														|pl = 'Zaopatrzono (%1)';
														|tr = 'Temin edildi (%1)'"), Format(QuantityIsProvided, "ND=3; NZ=; NG="));
	Items.HyperlinkNotProvided.Title = StrTemplate(NStr("vi = 'Không đảm bảo (%1)';
														|ru = 'Не обеспечено (%1)';
														|en = 'Not supplied (%1)'; fa = 'Not supplied (%1)';
														|it = 'Non fornito (%1)';
														|pl = 'Nie zaopatrzono (%1)';
														|tr = 'Temin edilmedi (%1)'"), Format(QuantityIsNotSupplied, "ND=3; NZ=; NG="));
	
EndProcedure

&AtClientAtServerNoContext
Function SoftwareFilterIsDisabled()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function FilterSecurityIsProvided()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function NoSoftwareIsProvided()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function TextOfWarningFreeReleaseFromSeparateMaterials()
	
	Return NStr("vi = 'Sản phẩm đầu ra không tách riêng từ nguyên vật liệu đã tách riêng.
		|Sản phẩm không được gộp chung với các dòng của đơn hàng khác
		|và các dòng có mục đích khác.
		|Nên tách riêng bán thành phẩm khi xuất xưởng.';
		|ru = 'Необособленный выпуск из обособленных материалов.
		|Изделие не укрупняется со строками других заказов
		|и строками с другим назначением.
		|Рекомендуется обособить полуфабрикат при выпуске.';
		|en = 'Non-assigned release from assigned materials. 
		|Finished product is not consolidated with lines of other orders
		|and lines with another assignment.
		|It is recommended that you assign the semi-finished product on release.'; fa = 'Non-assigned release from assigned materials. 
		|Finished product is not consolidated with lines of other orders
		|and lines with another assignment.
		|It is recommended that you assign the semi-finished product on release.';
		|it = 'Non-assigned release from assigned materials. 
		|Finished product is not consolidated with lines of other orders
		|and lines with another assignment.
		|It is recommended that you assign the semi-finished product on release.';
		|pl = 'Non-assigned release from assigned materials. 
		|Finished product is not consolidated with lines of other orders
		|and lines with another assignment.
		|It is recommended that you assign the semi-finished product on release.';
		|tr = 'Ayrıştırılmış malzemelerden ayrıştırılmamış ürün çıkışı.
		|Nihai ürün, diğer sipariş satırlarıyla
		|ve farklı bir atamaya sahip satırlarla birleştirilmedi.
		|Yarı mamulün ürün çıkışı sırasında ayrıştırılması önerilmektedir.'");
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_SelectionByDate_1" Then
		SelectionByDate_1OnChange(Items.SelectionByDate_1);
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
