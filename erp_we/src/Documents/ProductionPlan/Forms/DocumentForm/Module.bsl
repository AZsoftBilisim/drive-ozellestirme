#Region Variables

&AtClient
Var CachedValues;
&AtClient
Var IdleHandlerParameters;
&AtClient
Var NotificationAfterRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Planning.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Parameters.Property("CurrentRow", CurrentRowWhenOpening);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		UpdateRule = Object.FillingRule.Count() = 0;
		PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, UpdateRule, FillingRuleAddress, CustomSettingsAddress);
		FillPropertyValues(ThisForm, PlanViewParameters);
		FillPropertyValues(Object, PlanViewParameters,"FillInUsingFormula,Substitutional,FillInByShortage");
		
		ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario,
			"Periodicity, BudgetingScenario");
		FillPropertyValues(Object, ScriptParameters_);
		
		If NumberOfPeriods > 0 And Not ValueIsFilled(Parameters.CopyingValue) Then
			PlanningClientServer.SetStartEndOfPlanPeriod(
				Object.Periodicity, 
				Object.BeginOfPeriod,  
				Object.PeriodEnding,
				CurrentSessionDate(),
				NumberOfPeriods);
			If Object.Substitutional Then
				Object.SubstitutionPeriodStart = Object.BeginOfPeriod;
			EndIf;
		EndIf;
		
		OnReadCreateAtServer();
		
		If PlanViewParameters.FillInByShortage = True Then
			Object.CrossTable = False;
			SwitchPeriodsToRowsOnServer(Undefined);
		EndIf;
		
		RefreshSemiFinishedProductsPage(True);
		
		SetVisibility1();
		
	EndIf;
	
	CurrentUser = Users.CurrentUser();
	
	FillInBOMByPeriods = Common.ObjectAttributeValue(Object.PlanProfile, "FillInBOMByPeriods");
	SaveNewPeriodServer();
	
	If ValueIsFilled(Object.FillingRule) Then
		For Each Rule In Object.FillingRule Do
			If Rule.FilterFromHeaderIsSet Then
				FilterIs_Specified = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	SetConditionalAppearanceOfCrossTable();
	
	Items.GroupProducts_2.Title = TitleOfTablePart(Object.ProductionProcessType);
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		Items.ManufacturedProductSelectGoods.Title = NStr("vi = 'Lựa chọn công việc';
															|ru = 'Подобрать работы';
															|en = 'Pick works'; fa = 'Pick works';
															|it = 'Pick works';
															|pl = 'Pick works';
															|tr = 'İşleri seç'");
		Items.ProductsByDateSelectGoods.Title = NStr("vi = 'Lựa chọn công việc';
													|ru = 'Подобрать работы';
													|en = 'Pick works'; fa = 'Pick works';
													|it = 'Pick works';
													|pl = 'Pick works';
													|tr = 'İşleri seç'");
	Else
		Items.ManufacturedProductSelectGoods.Title = NStr("vi = 'Chọn mặt hàng';
															|ru = 'Подобрать товары';
															|en = 'Pick goods'; fa = 'انتخاب کالاها';
															|it = 'Selezionare la merce';
															|pl = 'Dobierz wiersze pozycji';
															|tr = 'Malları seç'");
		Items.ProductsByDateSelectGoods.Title = NStr("vi = 'Chọn mặt hàng';
													|ru = 'Подобрать товары';
													|en = 'Pick goods'; fa = 'انتخاب کالاها';
													|it = 'Selezionare la merce';
													|pl = 'Dobierz wiersze pozycji';
													|tr = 'Malları seç'");
	EndIf;
	
	AdditionalColumnName = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	ControlOfCalculationOfProductionPlan();
	
	If Object.Substitutional And PlanReplacementControlOnServer(Object.Ref) Then
		SkipPeriodClosingCheck = True;
		ThisObject.Write();
		ThisObject.Read();
		SkipPeriodClosingCheck = False;
	EndIf;
	
	UpdateDisplayOfFillInDeficitAlertGroupOnClient();
	
	PlanningClient.PositionByLine(ThisForm, "GroupProducts_2", "ManufacturedProduct", "ProductsByDate");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected);
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	Planning.OnReadAtServer(ThisForm, CurrentObject);
	
	PlanningClientServer.SaveValuesOfVerifiedDetails(Object, ThisForm, "DetailsBeforeChange");
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, False, FillingRuleAddress, CustomSettingsAddress);
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	OnReadCreateAtServer();
	
	If PlanViewParameters.FillInByShortage Then
		Object.CrossTable = False;
		SwitchPeriodsToRowsOnServer(Undefined);
	EndIf;
	
	SaveNewPeriodServer();
	
	SetVisibility1();
	
	RefreshSemiFinishedProductsPage(True);
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionPlan.DocumentForm.Event.BeforeWrite");
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	If Object.Substitutional Then
		UpdateBeginningOfReplacementPeriod();
	EndIf;
	
	WriteParameters.Insert("CachedValues", CachedValues);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CopyFromCrossTable(WriteParameters["CachedValues"], CurrentObject);
	
	Planning.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	If RunAFullRecalculation Then
		CurrentObject.AdditionalProperties.Insert("CompleteRecalculation", True);
	EndIf;
	
	If Object.FillInUsingFormula Then
		RecordAdditionalParameters(CurrentObject);
	EndIf;
	
	If SkipPeriodClosingCheck Then
		CurrentObject.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	EndIf;
	
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

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetails();
	
	If Object.FillInUsingFormula Then
		ReadMoreParameters(CurrentObject);
	EndIf;
	
	SetVisibility1();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "ProductionPlan");

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	ElsIf EventName = "WorkingWithExcelClient_DownloadFromExcel"
		And Parameter.FormUniqueID = UUID Then
		
		LoadFromExcelOnClient(Parameter.DownloadData);
		
	ElsIf EventName = "Write_AdjustmentOfPlannedDemand" Then
		
		If Parameter.Property("Plan")
			And Parameter.Plan = Object.Ref Then
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
													|ru = 'Перезаполнить';
													|en = 'Refill'; fa = 'پرکردن مجدد';
													|it = 'Ricompilare';
													|pl = 'Refill';
													|tr = 'Yeniden doldur'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
			QueryText = NStr("vi = 'Nhu cầu về sản phẩm đã thay đổi, điền lại phần bảng?';
							|ru = 'Потребность в продукции изменилась, перезаполнить табличную часть?';
							|en = 'Demand for products has changed, refill the table?'; fa = 'Demand for products has changed, refill the table?';
							|it = 'Il fabbisogno di prodotti è cambiato, ricompilare la tabella?';
							|pl = 'Zapotrzebowanie na produkcję zmieniło się, wypełnić ponownie część tabelaryczną?';
							|tr = 'İmal edilen ürünlere olan gereksinim değişti, tablo yeniden doldurulsun mu?'");
			Notification = New CallbackDescription("AdjustDemandCompletion", ThisObject, Parameter);
			ShowQueryBox(Notification, QueryText, Buttons);
			
		EndIf;
	ElsIf EventName = "CancelProductionPlanAdjustingEntries"
		And Source = UUID Then
		
		CheckIfThereAreUndoneAdjustments();
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ProductionPlan", , Object.Ref);
	
	ShortageRecalculationControlTimer = 1;
	UpdateDisplayOfFillInDeficitAlertGroupOnClient();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	If NotificationAfterRecording <> Undefined Then
	
		RunCallback(NotificationAfterRecording, True);
		NotificationAfterRecording = Undefined;
	
	EndIf;
	
	ControlOfCalculationOfProductionPlan();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	
	If ThisForm.Modified Then
		If PlanReplacementControlOnServer(Object.Ref) Then
			ThisObject.Read();
			ThisObject.Write();
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If Object.Substitutional 
		And (Object.CrossTable And ProductsByDate.Count() = 0
		Or Not Object.CrossTable And Object.ManufacturedProduct.Count() = 0)
		And Items.GroupPages.CurrentPage = Items.GroupProducts_2 Then
		FillInDataForReplacement();
	EndIf;
	
EndProcedure

&AtClient
Procedure ScenarioOnChange(Item)
	
	Notification = New CallbackDescription("ScenarioOnChangeCompletion", ThisObject);
	
	PlanningClient.ShowQuestionWhenScriptChanges(ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure ScenarioOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ScenarioOnChangeServer();
	
EndProcedure

&AtClient
Procedure PlanProfileOnChange(Item)
	
	Notification = New CallbackDescription("PlanProfileOnChangeCompletion", ThisObject);
	
	PlanningClient.ShowQuestionWhenChangingPlanView(ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure PlanProfileOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	PlanProfileOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.FillInByShortage Then
		Object.PeriodEnding = Object.BeginOfPeriod;
	EndIf;
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductsByDate", Notification);
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.FillInByShortage Then
		Object.BeginOfPeriod = Object.PeriodEnding;
	EndIf;
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductsByDate", Notification);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	AssignmentWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	If Not ValueIsFilled(Object.Status) Then
		Object.Status = PredefinedValue("Enum.PlanStatuses.RolledBack_");
	EndIf;
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure CellIsCanceledOnChange(Item)
	
	SetCancelAndCommentCells();
	
EndProcedure

&AtClient
Procedure CellCommentOnChange(Item)
	
	SetCancelAndCommentCells();
	
EndProcedure

&AtClient
Procedure CellCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("CellCommentStartChoiceCompletion", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(
		Notification, 
		Item.EditText, 
		NStr("vi = 'Ghi chú ô hàng kế hoạch';
			|ru = 'Комментарий ячейки плана';
			|en = 'Plan cell comment'; fa = 'Plan cell comment';
			|it = 'Commento della cella di piano';
			|pl = 'Komentarze na temat komórek planu';
			|tr = 'Hücre planı yorumu'"));
	
EndProcedure

&AtClient
Procedure TheProductionPlanIsNotCalculatedThereAreErrorsProcessingTheNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "GoToCalculationErrors" Then
		
		FormParameters = ParametersForTransitionToProductionPlanCalculationErrors(Object.Ref);
		OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
		
	ElsIf FormattedStringURL = "RepeatCalculation_" Then
		
		RunFullRecalculationOfProductionPlan();
		ControlOfCalculationOfProductionPlan();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = HyperlinkValueDisableSelectionForSemiFinishedProductOccurrences() Then
		
		DisableSelectionForSemiFinishedProductOccurrences();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheLabelThereAreCanceledAdjustmentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#ShowManualAdjustments" Then
		
		FormParameters = New Structure;
		
		FormParameters.Insert("ProductionPlan", Object.Ref);
		FormParameters.Insert("ShowAssignment", Items.ListOfSemiFinishedProductsPurpose.Visible);
		FormParameters.Insert("Filter", New Structure("ProductionPlan", Object.Ref));
		
		OpenForm(
			"InformationRegister.CancelProductionPlanAdjustingEntries.Form.ListFormAccordingToPlan",
			FormParameters,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("ProductsByDate");
	
	If Object.CrossTable Then
		
		CheckSpecification = FillInTheSpecification And Object.Status = Enums.PlanStatuses.Upholded;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("TablePresentation", TitleOfTablePart(Object.ProductionProcessType));
		StructureOfActions.Insert("TablePath","ProductsByDate");
		StructureOfActions.Insert("FillInProducts_1");
		StructureOfActions.Insert("FillInTheSpecification", CheckSpecification);
		StructureOfActions.Insert("FillInWHCharacteristic");
		
		CheckParameters = New Structure;
		CheckParameters.Insert("TimeIntervals", ThisObject["TimeIntervals"].Unload(New Structure("Active_", True)));
		CheckParameters.Insert("FieldPrefix", "Count_");
		CheckParameters.Insert("FieldName", "NumberOfPackages");
		StructureOfActions.Insert("CheckingQuantityByPeriod", CheckParameters);
		
		StructureOfActions.Insert("GroupFields", "Products, Characteristic, Purpose, Package, BillOfMaterials, SemiFinishedProduct");
		
		Planning.ProcessingFormFillVerification(ProductsByDate, StructureOfActions, Cancel, CheckedAttributes, Object.CrossTable); 
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DemandForMaterialsOnChange(Item)
	
	If Not Object.CrossTable Then
		
		FillInProductLaunchDates();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProduct

&AtClient
Procedure ManufacturedProductOnChange(Item)
	
	Object.FilledAutomatically = False;
	
	GoodsLineQuantity = Object.ManufacturedProduct.Count();
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnEditEnd(Item, NewRow, CancelEdit)
	
	GoodsLineQuantity = Object.ManufacturedProduct.Count();
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRow(Item, Cancel)
	
	If Object.FillInByShortage Then
		
		Cancel = True;
		DescriptionOfTheAlert = New CallbackDescription("ManufacturedProductBeforeDeleteRowCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Số tiền được bảo đảm sẽ được điều chỉnh. Tiếp tục?';
				|ru = 'Количество к обеспечению будет скорректировано. Продолжить?';
				|en = 'Quantity to supply will be adjusted. Continue?'; fa = 'Quantity to supply will be adjusted. Continue?';
				|it = 'La quantità da approvvigionare sarà rettificata. Continuare?';
				|pl = 'Ilość do zapewnienia będzie skorygowana. Kontynuować?';
				|tr = 'Tedarik miktarı ayarlanacaktır. Devam edilsin mi?'"), 
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.Yes);
		
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	For Each RowID In SelectedRows Do
		SelectedRow = Object.ManufacturedProduct.FindByID(RowID);
		
		SelectedRow.Count = 0;
		SelectedRow.NumberOfPackages = 0;
		SelectedRow.DemandRangeIsSpecified = True;
		SelectedRow.RangeOfDemandFrom = 0;
		SelectedRow.RangeOfDemandTo = 0;
	EndDo
	
EndProcedure

&AtClient
Procedure ManufacturedProductAfterDeleteRow(Item)
	
	CalculateTotals_(ThisForm, False);
	ThereAreSemiFinishedProducts = Object.ManufacturedProduct.FindRows(New Structure("SemiFinishedProduct", True)).Count() > 0;
	
EndProcedure

&AtClient
Procedure ManufacturedProductDateOfProductionOnChange(Item)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	ProductsReleaseDateWhenChangedOnServer(Items.ManufacturedProduct.CurrentRow, CachedValues);
	
	If Object.Substitutional
		And Object.Posted
		And SubstitutedPeriods.Count() > 0 Then
		
		If CurrentData.SemiFinishedProduct Then
			ReleaseDateStartOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(CurrentData.ReleaseDateOfProductsOrSemiFinishedProduct, Object.Periodicity);
		Else
			ReleaseDateStartOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(CurrentData.DateOfProduction, Object.Periodicity);
		EndIf;
		Filter = New Structure("SubstitutedPeriod", ReleaseDateStartOfPeriod);
		SubstitutedStringPeriod = SubstitutedPeriods.FindRows(Filter);
		If SubstitutedStringPeriod.Count() > 0 Then
			CurrentData.Substituted = SubstitutedStringPeriod[0].Substituted;
			CurrentData.SubstitutedToOrder = SubstitutedStringPeriod[0].SubstitutedToOrder;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.ProductionPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnActivateRow(Item)
	If Not Object.FillInUsingFormula And Items.ManufacturedProduct.SelectedRows.Count() > 0 Then
		UBound = Items.ManufacturedProduct.SelectedRows.UBound();
		Details = PlanningClient.GenerateDecryption(Object.ManufacturedProduct.FindByID(Items.ManufacturedProduct.SelectedRows[UBound]));
	Else
		Details = "";
	EndIf;
EndProcedure

&AtClient
Procedure ManufacturedProductProductsOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	ProductsProductListWhenChangedOnServer(Items.ManufacturedProduct.CurrentRow, CachedValues);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductCharacteristicOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	OutputCharacteristicWhenChangedOnServer(Items.ManufacturedProduct.CurrentRow, CachedValues);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.Property("Deviation") And ValueIsFilled(CurrentRow.Formula) Then
		CalculationResult = PlanningClient.CalculateByFormula(CurrentRow.Formula, CurrentRow, Undefined, Undefined);
		CurrentRow.Deviation = CalculationResult.Result - CurrentRow.NumberOfPackages;
	EndIf;
	
	CurrentRow.Details = String(CurrentRow.NumberOfPackages);
	Details = PlanningClient.GenerateDecryption(CurrentRow);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf; 
	
EndProcedure

&AtClient
Procedure ManufacturedProductCommentOnChange(Item)
	
	Items.ManufacturedProduct.CurrentData.PictureComment = ValueIsFilled(Items.ManufacturedProduct.CurrentData.Comment);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalParameters = New Structure("CurrentRow", Items.ManufacturedProduct.CurrentRow);
	Notification = New CallbackDescription("ManufacturedProductCommentStartChoiceCompletion", ThisObject, AdditionalParameters);
	CommonClient.ShowMultilineTextEditingForm(
		Notification, 
		Item.EditText, 
		NStr("vi = 'Ghi chú ô hàng kế hoạch';
			|ru = 'Комментарий ячейки плана';
			|en = 'Plan cell comment'; fa = 'Plan cell comment';
			|it = 'Commento della cella di piano';
			|pl = 'Komentarze na temat komórek planu';
			|tr = 'Hücre planı yorumu'"));
		
EndProcedure

// Parameters:
// 	EnteredText - String - 
// 	AdditionalParameters - Structure - From:
//		* CurrentRow - Number - 
&AtClient
Procedure ManufacturedProductCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ManufacturedProduct.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.Comment = EnteredText;
	CurrentData.PictureComment = ValueIsFilled(EnteredText);
	Modified = True;
	
EndProcedure

&AtClient
Procedure ManufacturedProductCanceledOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBillOfMaterialsOnChange(Item)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If Not CurrentData.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
	CalculateProductLaunchDate(ThisObject, CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPurposeOnChange(Item)
	
	OutputDestinationWhenChangedOnServer(Items.ManufacturedProduct.CurrentRow, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsByDate

&AtClient
Procedure ProductsByDateOnChange(Item)
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductsByDate");
	
	Object.FilledAutomatically = False;
	
	GoodsLineQuantity = ProductsByDate.Count();
	
EndProcedure

&AtClient
Procedure ProductsByDateOnEditEnd(Item, NewRow, CancelEdit)
	
	GoodsLineQuantity = ProductsByDate.Count();
	
EndProcedure

&AtClient
Procedure ProductsByDateBeforeDeleteRow(Item, Cancel)
	
	SelectedRows = Items.ProductsByDate.SelectedRows;
	For Each SelectedRow In SelectedRows Do
		
		TSRow = ProductsByDate.FindByID(SelectedRow);
		
		If TSRow.SemiFinishedProduct Then
			Filter = New Structure("Products, Characteristic, Purpose, BillOfMaterials");
			FillPropertyValues(Filter, TSRow);
			
			LinesToDelete = AllSemiFinishedProductsByDate.FindRows(Filter);
			For Each RowToDelete In LinesToDelete Do
				AllSemiFinishedProductsByDate.Delete(RowToDelete);
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProductsByDateAfterDeleteRow(Item)
	
	CalculateTotals_(ThisForm, False);
	ThereAreSemiFinishedProducts = ProductsByDate.FindRows(New Structure("SemiFinishedProduct", True)).Count() > 0;
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductsByDate");
	
EndProcedure

&AtClient
Procedure ProductsByDateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.ProductionPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.ProductsByDate.CurrentData.SemiFinishedProduct 
		And Field.Name <> "ProductsByDateBillOfMaterials" Then
		Filter = New Structure("Products, Characteristic, Purpose, BillOfMaterials");
		FillPropertyValues(Filter, Items.ProductsByDate.CurrentData);
	
		OutputByDateSelectionOnServer(Filter);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy And Item.CurrentData.SemiFinishedProduct Then
		NewRow = AllSemiFinishedProductsByDate.Add();
		FillPropertyValues(NewRow, Item.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateBeforeRowChange(Item, Cancel)
	
	If Items.ProductsByDate.CurrentData.SemiFinishedProduct
		And Item.CurrentItem.Name <> "ProductsByDateBillOfMaterials" Then
		Filter = New Structure("Products, Characteristic, Purpose, BillOfMaterials");
		FillPropertyValues(Filter, Items.ProductsByDate.CurrentData);
	
		OutputByDateSelectionOnServer(Filter);
		Cancel = True;
	Else
		SemiFinishedProductSpecificationBeforeModification = Items.ProductsByDate.CurrentData.BillOfMaterials;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateProductsOnChange(Item)
	
	CurrentRow = Items.ProductsByDate.CurrentData;
	
	ProductsProductListWhenChangedOnServer(Items.ProductsByDate.CurrentRow, CachedValues);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateCharacteristicOnChange(Item)
	
	CurrentRow = Items.ProductsByDate.CurrentData;
	
	OutputCharacteristicWhenChangedOnServer(Items.ProductsByDate.CurrentRow, CachedValues);
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDatePackageOnChange(Item)
	
	CurrentRow = Items.ProductsByDate.CurrentData;
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDateBillOfMaterialsOnChange(Item)
	
	CurrentRow = Items.ProductsByDate.CurrentData;
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	Else
		Filter = New Structure("Products, Characteristic, Purpose, BillOfMaterials");
		FillPropertyValues(Filter, CurrentRow);
		RowsOfSemiFinishedProducts = ProductsByDate.FindRows(Filter);
		
		If RowsOfSemiFinishedProducts.Count() > 1 Then
			StringSemiFinishedProduct = RowsOfSemiFinishedProducts[0];
			If StringSemiFinishedProduct = CurrentRow Then
				StringSemiFinishedProduct =  RowsOfSemiFinishedProducts[1];
			EndIf;
			
			For Each PeriodString_ In ThisForm.TimeIntervals Do
				If Not PeriodString_.Active_ Then
					Continue;
				EndIf;
				
				StringSemiFinishedProduct["Count_" + PeriodString_.ColumnName] = StringSemiFinishedProduct["Count_" + PeriodString_.ColumnName] + 
																				CurrentRow["Count_" + PeriodString_.ColumnName];
				StringSemiFinishedProduct.Count = StringSemiFinishedProduct.Count + CurrentRow["Count_" + PeriodString_.ColumnName];
					
			EndDo;
			
			StringSemiFinishedProduct.NumberOfPackages = StringSemiFinishedProduct.Count;
			
			ProductsByDate.Delete(CurrentRow);
		EndIf;
		
		Filter.Insert("BillOfMaterials", SemiFinishedProductSpecificationBeforeModification);
		
		RowsOfSemiFinishedProducts = AllSemiFinishedProductsByDate.FindRows(Filter);
		For Each StringOfSemiFinishedProducts In RowsOfSemiFinishedProducts Do
			StringOfSemiFinishedProducts.BillOfMaterials = CurrentRow.BillOfMaterials;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByDatePurposeOnChange(Item)
	
	OutputDestinationWhenChangedOnServer(Items.ProductsByDate.CurrentRow, CachedValues);
	
EndProcedure

// Attachable when the quantity changes.
// 
// Parameters:
//  Item - FormField
&AtClient
Procedure Attachable_WhenChangingQuantity(Item)
	
	If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
		RowOfGoods = Items.SemiFinishedProductsByDate.CurrentData;
	Else
		RowOfGoods = Items.ProductsByDate.CurrentData;
	EndIf;
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
	
	If Object.FillInUsingFormula Then
		WhenChangingQuantityDeviation(RowOfGoods);
	EndIf;
	
	If Not RowOfGoods.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
		
		If Not Object.FillInUsingFormula Then
			TheCurrentNameOfTheColumn = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Item.Name, "ProductsByDate" + "Count_")[1];
			
			RowOfGoods["Details_" + TheCurrentNameOfTheColumn] = String(RowOfGoods["Count_" + TheCurrentNameOfTheColumn]);
			Details = PlanningClient.GenerateDecryption(RowOfGoods, "Details_" + TheCurrentNameOfTheColumn);
		EndIf;
		
	EndIf; 
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeCanceled(Item)
	
	CurrentRow = Items.ProductsByDate.CurrentData;
	
	If Not CurrentRow.SemiFinishedProduct Then
		SetSemiFinishedProductAlert(ThisObject, True);
	EndIf;
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingComment(Item)
	
	CurrentData = Items.ProductsByDate.CurrentData;
	
	If CurrentData <> Undefined And Items.ProductsByDate.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.ProductsByDate.CurrentItem.Name = "ProductsByDate" + "Comment_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				CurrentData["PictureComment_"+ Period.ColumnName] = ValueIsFilled(CellComment);
				Break;
			EndIf;
		EndDo;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_StartOfCommentSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.ProductsByDate.CurrentData;
	StandardProcessing = False;
	
	If CurrentData <> Undefined And Items.ProductsByDate.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.ProductsByDate.CurrentItem.Name = "ProductsByDate" + "Comment_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				
				AdditionalParameters = New Structure("CurrentRow, ColumnName", 
					Items.ProductsByDate.CurrentRow,
					Period.ColumnName);
				Notification = New CallbackDescription("Attachable_StartOfCommentSelectionCompletion", 
					ThisObject, 
					AdditionalParameters);
				CommonClient.ShowMultilineTextEditingForm(
					Notification, 
					CellComment, 
					NStr("vi = 'Ghi chú ô hàng kế hoạch';
						|ru = 'Комментарий ячейки плана';
						|en = 'Plan cell comment'; fa = 'Plan cell comment';
						|it = 'Commento della cella di piano';
						|pl = 'Komentarze na temat komórek planu';
						|tr = 'Hücre planı yorumu'"));
				Break;
			EndIf;
		EndDo;
	
	EndIf; 
	
EndProcedure

// Parameters:
// 	EnteredText - String - 
// 	AdditionalParameters - Structure - From:
//		* CurrentRow - Number -
&AtClient
Procedure Attachable_StartOfCommentSelectionCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
		CurrentData = SemiFinishedProductsByDate.FindByID(AdditionalParameters.CurrentRow);
	Else
		CurrentData = ProductsByDate.FindByID(AdditionalParameters.CurrentRow);
	EndIf;
		
	CurrentData["Comment_"+ AdditionalParameters.ColumnName] = EnteredText;
	CurrentData["PictureComment_"+ AdditionalParameters.ColumnName] = ValueIsFilled(CurrentData["Comment_"+ AdditionalParameters.ColumnName]);
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSemiFinishedProducts

&AtClient
Procedure ListOfSemiFinishedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.ListOfSemiFinishedProducts.CurrentData;
	
	If Field.Name = "ListOfSemiFinishedProductsProducts"
		Or Field.Name = "ListOfSemiFinishedProductsCharacteristic"
		Or Field.Name = "ListOfSemiFinishedProductsPurpose"
		Or Field.Name = "ListOfSemiFinishedProductsBillOfMaterials" Then
		
		ShowValue(, CurrentData[StrReplace(Field.Name, Item.Name, "")]);
		
	ElsIf Field.Name = "ListOfSemiFinishedProductsManualAdjustment" Then
		
		StartChangingListOfSemiFinishedProducts(Items.ListOfSemiFinishedProducts.CurrentRow);
		
	EndIf;
EndProcedure

&AtClient
Procedure ListOfSemiFinishedProductsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	StartChangingListOfSemiFinishedProducts(Items.ListOfSemiFinishedProducts.CurrentRow);
EndProcedure

&AtClient
Procedure UpdateTheListOfSemiFinishedProducts(Command)
	
	RefreshSemiFinishedProductsPage();
	
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionPlan.DocumentForm.Command.SelectGoods");
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("AllWarehouseBalance",                      True);
	 
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("HideManualDiscounts",                      True);
	
	If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		FormParameters.Insert("FilterByProductType",
			CommonClientServer.ValueInArray(PredefinedValue("Enum.ItemsTypes.Work_5")));
	Else
		FormParameters.Insert("FilterByProductType",
			ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	EndIf;

	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	AddProductsBySelectionOnClient();
	
EndProcedure

&AtClient
Procedure ConfigureAndPopulateAccordingToTheFillingRule(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;

	FormParameters = New Structure;
	
	FormParameters.Insert("UpdateAdd",      			Object.UpdateAdd);
	FormParameters.Insert("FillingRuleAddress", 			FillingRuleAddress);
	FormParameters.Insert("ChangeResultTo",    			Object.ChangeResultTo);
	FormParameters.Insert("RoundingPrecision",     			Object.RoundingPrecision);
	FormParameters.Insert("Periodicity",            		Object.Periodicity);
	FormParameters.Insert("PlanProfile",                         Object.PlanProfile);
	FormParameters.Insert("CustomSettingsAddress", 	CustomSettingsAddress);
	FormParameters.Insert("ReadOnly",                   ThisForm.ReadOnly);
	FormParameters.Insert("NumberOfPeriods",               NumberOfPeriods);
	FormParameters.Insert("Filter", PlanningClientServer.SelectionForSampling(FilterParameters(ThisObject), PlanViewParameters(ThisObject)));
	FormParameters.Insert("BeginOfPeriod",                    Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEnding",                 Object.PeriodEnding);
	
	Notification = New CallbackDescription("ConfigureAndPopulateAccordingToTheFillingRuleCompletion", ThisObject);
	
	OpenForm("Catalog.PlanningDataSources.Form.FormFilling", 
		FormParameters, 
		ThisForm, 
		UUID,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheFillingRule(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillInRule", True);
	
	FillInDocument(Settings);
	
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
	
	FormTable  = Items.ManufacturedProduct;
	TableData = Object.ManufacturedProduct;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CurrentRow.Details = "";
		NewRow.Details = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	If Object.CrossTable Then
		
		DescriptionOfTheAlert = New CallbackDescription("SwitchPeriodsToRowsCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Có thể sao chép và dán các dòng trong chế độ ""Kỳ trong dòng"". Chuyển chế độ?';
				|ru = 'Копирование и вставка строк возможны в режиме ""Периоды в строках"". Переключить режим?';
				|en = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?'; fa = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?';
				|it = 'È possibile copiare e incollare le righe in modalità ""Periodi nelle righe"". Cambiare la modalità?';
				|pl = 'Kopiowanie i wklejanie wierszy są możliwe w trybie ""Okresy w wierszach"". Przełączyć tryb?';
				|tr = 'Satırın kopyalanması ve yapıştırılması işlemi ""Satırlardaki dönemler"" modunda gerçekleştirilebilir. Bu mod açılsın mı?'"), 
			QuestionDialogMode.YesNo);
		
		Return;
		
	Else
		
		NumberOfProductsBeforeInsertion = Object.ManufacturedProduct.Count();
		
		GetLinesFromClipboard();
		
		NumberOfInserted = Object.ManufacturedProduct.Count()-NumberOfProductsBeforeInsertion;
		ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	EndIf;
		
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If Object.CrossTable Then
		
		DescriptionOfTheAlert = New CallbackDescription("SwitchPeriodsToRowsCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Có thể sao chép và dán các hàng trong chế độ ""Chu kỳ trong hàng"". Chuyển chế độ?';
				|ru = 'Копирование и вставка строк возможны в режиме ""Периоды в строках"". Переключить режим?';
				|en = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?'; fa = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?';
				|it = 'È possibile copiare e incollare le righe in modalità ""Periodi nelle righe"". Cambiare la modalità?';
				|pl = 'Kopiowanie i wklejanie wierszy są możliwe w trybie ""Okresy w wierszach"". Przełączyć tryb?';
				|tr = 'Satırın kopyalanması ve yapıştırılması işlemi ""Satırlardaki dönemler"" modunda gerçekleştirilebilir. Bu mod açılsın mı?'"), 
			QuestionDialogMode.YesNo);
		
		Return;
		
	Else
		FormTable = Items.ManufacturedProduct;
	EndIf;
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(FormTable.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding"),
		Notification);
	
EndProcedure

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	AdditionalParameters = PlanningClient.AdditionalParametersForDownloadingFromFile();
	AdditionalParameters.PlanType                 = "ProductionPlan";
	AdditionalParameters.AssignmentsAreUsed   = FillInAssignmentInTabularForm;
	AdditionalParameters.ReleaseDatesAreUsed  = Not ThisIsDisassembly;
	AdditionalParameters.SpecificationsAreUsed = FillInTheSpecification;
	AdditionalParameters.AvailableProductTypes = ProductDataManagementClientServer.TypesOfItemsByTypeOfProductionProcess(Object.ProductionProcessType);
	
	AdditionalParameters.ReleaseDatesOfSemiFinishedProductAreUsed = FillInTheSpecification
		And Not PlanSemiFinishedProductsAutomatically
		And EnterpriseManagement
		And Not ThisIsDisassembly;
	
	If Object.CrossTable Then
		AdditionalParameters.CrossTable = True;
		AdditionalParameters.TimeIntervals = ThisObject["TimeIntervals"];
	EndIf;
	
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure ExportToExcel(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	ProcessingWithExcelClient.ExportToExcel(ThisForm);
	
EndProcedure

&AtClient
Procedure ImportFromExcel(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	ProcessingWithExcelClient.SelectAttachedExcelFile(ThisForm, ?(Object.CrossTable, "ProductsByDate", "ManufacturedProduct"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToColumns(Command)
	
	If Not Object.CrossTable Then
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "ManufacturedProduct");
		CheckParameters.Insert("PresentationOfTS",          TitleOfTablePart(Object.ProductionProcessType));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       ?(ThisIsDisassembly, "StartDate2", "DateOfProduction"));
		CheckParameters.Insert("PresentationOfPeriodDate", ?(ThisIsDisassembly, NStr("vi = 'Ngày vận hành';
																					|ru = 'Дата запуска';
																					|en = 'Launch date'; fa = 'تاریخ شروع';
																					|it = 'Data di avvio';
																					|pl = 'Data uruchomienia';
																					|tr = 'Başlangıç tarihi'"), NStr("vi = 'Ngày xuất xưởng';
																												|ru = 'Дата выпуска';
																												|en = 'Release date'; fa = 'تاریخ انتشار';
																												|it = 'Data di produzione';
																												|pl = 'Data wydania';
																												|tr = 'Çıkış tarihi'")));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		If Cancel Then
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa bỏ dòng';
													|ru = 'Удалить строки';
													|en = 'Remove lines'; fa = 'Remove lines';
													|it = 'Cancellare le righe';
													|pl = 'Usuń wiersze';
													|tr = 'Satırları sil'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
			QueryText = StrTemplate(
				NStr("vi = 'Các dòng của danh sách ""%1"" cho biết ngày vượt ra ngoài ranh giới lập kế hoạch - các dòng sẽ bị xóa. Xóa dòng?';
					|ru = 'В строках списка ""%1"" указаны даты за границами планирования - строки будут удалены. Удалить строки?';
					|en = 'The %1 list lines contain dates with planning fences - lines will be removed. Remove the lines?'; fa = 'The %1 list lines contain dates with planning fences - lines will be removed. Remove the lines?';
					|it = 'Nelle righe dell''elenco ""%1"" le date vanno oltre i limiti della pianificazione - le righe verranno eliminate. Eliminare le righe?';
					|pl = 'W wierszach ""%1"" listy daty wykraczają poza granice planowania - wiersze zostaną usunięte. Usunąć wiersze?';
					|tr = '""%1"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silinecek. Silinsin mi?'"),
				TitleOfTablePart(Object.ProductionProcessType));
			Notification = New CallbackDescription("SwitchPeriodsToColumnsCompletion", ThisObject);
			ShowQueryBox(Notification, QueryText, Buttons);
			Return;
			
		EndIf; 
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
		
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToRows(Command)
	
	SwitchPeriodsToRowsOnServer(CachedValues);
	
EndProcedure

&AtServer
Procedure SwitchPeriodsToRowsOnServer(CachedValues)
	
	If Object.CrossTable Then
		CopyFromCrossTable(CachedValues, Object);
		Object.CrossTable = False;
		FillInServiceDetails();
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
	ReadSetSpecificationSelectionParameters();
	
EndProcedure

&AtClient
Procedure FillInProducts_(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	If DisableEditingOfPopulationSettings Then
		SetUpFormulaAndFillIn(SettingsStructure, Undefined);
		Return;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("PlanType", 						PlanType);
	FormParameters.Insert("PeriodStartPlan", 				Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEndPlan",				Object.PeriodEnding);
	FormParameters.Insert("Periodicity", 					Object.Periodicity);
	FormParameters.Insert("OperatorsTreeStorageAddress", 	OperatorsTreeStorageAddress);
	FormParameters.Insert("AdditionalFields", 				AdditionalFields);
	FormParameters.Insert("SettingsStructure", 				AdditionalSettings(SettingsStructure));
	FormParameters.Insert("Owner", 						Object.Ref);
	FormParameters.Insert("Filter",							FilterIndicators);
	
	CallbackDescription = New CallbackDescription("SetUpFormulaAndFillIn",ThisObject);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("Catalog.PlanProfiles.Form.SettingsForm", New Structure("SettingsStructure",FormParameters), ThisForm,,,,CallbackDescription,Mode);
	
EndProcedure

&AtClient
Procedure FillInByShortages(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	FillInDeficitPlansOnServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TheLabelRescheduleForDeficitURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Modified = True;
	FillInByShortages(Undefined);
EndProcedure

&AtClient
Procedure FillInIndicators(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	If FillInByShortage Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("PeriodStartPlan", Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEndPlan",	Object.PeriodEnding);
	FormParameters.Insert("Periodicity", 		Object.Periodicity);
	FormParameters.Insert("SettingsStructure", 	AdditionalSettings(SettingsStructure));
	FormParameters.Insert("Owner", 			Object.Ref);
	
	If StrFind(FormParameters.SettingsStructure.Formula , "PlannedStartBalance")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalBalances")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalDeficit")<>0 Then
		AdjustOffsetAndFill(FormParameters.SettingsStructure, Undefined);
	Else
		CallbackDescription = New CallbackDescription("AdjustOffsetAndFill", ThisObject);
		Mode = FormWindowOpeningMode.LockOwnerWindow;
		
		OpenForm("Catalog.PlanProfiles.Form.SettingsFormOfTimeShift", New Structure("SettingsStructure",FormParameters), ThisForm,,,,CallbackDescription,Mode);
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateProductionPlanRequirements(Command)
	
	If Not FillInTheSpecification Then
	
		ShowMessageBox(,NStr("vi = 'Để sử dụng tính toán nhu cầu về nguyên vật liệu, dạng nguồn lực sản xuất và nguồn lực lao động, cần bật sử dụng tùy chỉnh tương ứng trong ""Kịch bản"".';
							|ru = 'Для использования расчета потребностей в материалах, видах РЦ и трудовых ресурсах необходимо включить соответствующую настройку в ""Сценарии"".';
							|en = 'To use calculation of demand for materials, work center types, and labor resources, enable the corresponding setting in ""Scenarios"".'; fa = 'To use calculation of demand for materials, work center types, and labor resources, enable the corresponding setting in ""Scenarios"".';
							|it = 'Per utilizzare il calcolo dei fabbisogni di materiali, dei tipi dei centri di lavoro e delle risorse di manodopera, è necessario abilitare l''impostazione corrispondente nei ""Scenari"".';
							|pl = 'Aby użyć obliczenia wymagań dla materiałów, rodzajów zasobów RC i zasobów pracy, należy włączyć odpowiednie ustawienie w ""Scenariuszu"".';
							|tr = 'Malzemelerde, İM türlerinde ve işçi kaynaklarında gereksinimlerin hesaplanmasını kullanmak için ilgili ayar ""Senaryolar""da etkinleştirilmelidir.'"));
		Return;
	
	EndIf;
	
	If Object.Posted And Not Modified Then
		RunFullRecalculationOfProductionPlan();
		ControlOfCalculationOfProductionPlan();
	Else
		
		Notification = New CallbackDescription("ConductAndRecalculateNeedsOfCompletion", ThisObject);
		Buttons = New ValueList();
		QueryText = NStr("vi = 'Để tính lại nhu cầu, chứng từ phải được kết chuyển! Kết chuyển?';
						|ru = 'Для пересчета потребностей документ должен быть проведен! Провести?';
						|en = 'To recalculate demands, post the document. Post?'; fa = 'To recalculate demands, post the document. Post?';
						|it = 'Per ricalcolare i fabbisogni il documento deve essere registrato! Registrare?';
						|pl = 'Aby przeliczyć potrzeby, dokument należy zatwierdzić! Zatwierdzić?';
						|tr = 'Gereksinimlerin yeniden hesaplanması için belgenin kaydedilmesi gerekmektedir! Kaydedilsin mi?'");
		Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Registrare';
												|pl = 'Post';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
		
		ShowQueryBox(Notification, QueryText, Buttons, , DialogReturnCode.Yes);
		
	EndIf;

EndProcedure

&AtClient
Procedure AllocateQuantity(Command)
	
	StorageAddressDistribution = PlaceManufacturedProductsInVault();
	
	FormParameters = New Structure;
	FormParameters.Insert("StorageAddressDistribution", StorageAddressDistribution);
	FormParameters.Insert("NumberOfPeriods",          NumberOfPeriods);
	
	CallbackDescription = New CallbackDescription("QuantityDistributionCompletion", ThisObject);
	
	OpenForm("Document.ProductionPlan.Form.QuantityDistribution", FormParameters, ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ChangeByPercentage(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ChangeByPercentageCompletion", ThisObject);
	
	PlanningClient.ChangeFormulaToPercentage(
		ThisForm, 
		?(Object.CrossTable, ProductsByDate, Object.ManufacturedProduct), 
		?(Object.CrossTable, "ProductsByDate", "ManufacturedProduct"),
		Notification);
	
EndProcedure

&AtClient
Procedure RoundOffQuantity(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("RoundOffQuantityCompletion", ThisObject);
	
	PlanningClient.RoundUpFormula(
		ThisForm, 
		?(Object.CrossTable, ProductsByDate, Object.ManufacturedProduct), 
		?(Object.CrossTable, "ProductsByDate", "ManufacturedProduct"),
		Notification);
	
EndProcedure

&AtClient
Procedure SpecifyArbitraryFormula(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
	ActivePeriods = TablePeriods.FindRows(New Structure("Active_", True));
	
	For Each Period In ActivePeriods Do
		
		AdditionalParameters = New Structure("ColumnName",Period.ColumnName);
		
		If Object.CrossTable And ActivePeriods.Count() > 1 Then
			
			If Items.ProductsByDate.CurrentData = Undefined Then
				Return;
			EndIf;
			
			CurElementName = Items.ProductsByDate.CurrentItem.Name;
			
			If StrFind(CurElementName, "ProductsByDate" + "Count_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'"));
				Return;
			EndIf;
			
			If CurElementName = "ProductsByDate" + "Count_"+Period.ColumnName Then
				
				QueryText = NStr("vi = 'Đặt công thức đối với tất cả các kỳ?';
								|ru = 'Установить формулу для всех периодов?';
								|en = 'Set the formula for all periods?'; fa = 'Set the formula for all periods?';
								|it = 'Impostare la formula per tutti i periodi?';
								|pl = 'Ustawić ""ТаблицаПериодов"" dla wszystkich okresów?';
								|tr = 'Formül tüm dönemler için kurulsun mu?'");
				
				ButtonsList = New ValueList;
				ButtonsList.Add(DialogReturnCode.Yes, 		NStr("vi = 'Có, đối với tất cả';
																	|ru = 'Да, для всех';
																	|en = 'Yes, for all'; fa = 'Yes, for all';
																	|it = 'Si, per tutti';
																	|pl = 'Tak, dla wszystkich';
																	|tr = 'Evet, tümü için'"));
				ButtonsList.Add(DialogReturnCode.No, 		NStr("vi = 'Chỉ';
																	|ru = 'Только';
																	|en = 'Only'; fa = 'Only';
																	|it = 'Solo';
																	|pl = 'Only';
																	|tr = 'Sadece'") + " " + Period.Title);
				ButtonsList.Add(DialogReturnCode.Cancel,	NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annulla';
																|pl = 'Anuluj';
																|tr = 'İptal'"));
				
				CallbackDescription = New CallbackDescription("AfterQuestionSetArbitraryFormula", 
					ThisObject, 
					AdditionalParameters);
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
				
			EndIf;
			
		Else
			
			If (Object.CrossTable And Items.ProductsByDate.CurrentData = Undefined) 
				Or (Not Object.CrossTable And Items.ManufacturedProduct.CurrentData = Undefined) Then
				Return;
			EndIf;
			
			AfterQuestionSetArbitraryFormula(DialogReturnCode.No, AdditionalParameters);
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CancelPlanLines(Command)
	
	Notification = New CallbackDescription("CancelPlanLinesCompletion", ThisObject);
	If Object.CrossTable Then
		
		If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
			PlanningClient.CancelPlanLines(ThisForm, SemiFinishedProductsByDate, "SemiFinishedProductsByDate", Notification);
		Else
			PlanningClient.CancelPlanLines(ThisForm, ProductsByDate, "ProductsByDate", Notification);
		EndIf;
		
	Else
		PlanningClient.CancelPlanLines(ThisForm, Object.ManufacturedProduct, "ManufacturedProduct", Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PlanSemiFinishedProducts_3(Command)
	
	If ThereAreSemiFinishedProducts Then
	
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Kontynuuj';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Notification = New CallbackDescription("PlanSemiFinishedProducts_3Completion", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Tất cả các sản phẩm bán thành phẩm sẽ được lập kế hoạch lại. Tiếp tục?';
										|ru = 'Все полуфабрикаты будут перепланированы. Продолжить?';
										|en = 'All semi-finished products will be replanned. Continue?'; fa = 'All semi-finished products will be replanned. Continue?';
										|it = 'Tutti i prodotti semilavorati saranno ripianificati. Continuare?';
										|pl = 'Wszystkie półprodukty zostaną ponownie zaplanowane. Kontynuować?';
										|tr = 'Tüm yarı mamul ürünler yeniden planlanacaktır. Devam edilsin mi?'"), Buttons);
		Return;
		
	EndIf; 
	
	ScheduleSemiFinishedProductsOnClient();
	
EndProcedure

&AtClient
Procedure RemoveSemiFinishedProducts(Command)
	
	DeleteSemiFinishedProductsOnServer();
	
EndProcedure

&AtClient
Procedure DeleteEmptyLines(Command)
	
	DeleteBlankLinesOnServer();
	
EndProcedure

&AtClient
Procedure EditTheListOfSemiFinishedProducts(Command)
	
	Cancel = True;
	StartChangingListOfSemiFinishedProducts(Items.ListOfSemiFinishedProducts.SelectedRows);
EndProcedure

&AtClient
Procedure ListOfSemiFinishedProductsShowOccurrences(Command)
	CurrentData = Items.ListOfSemiFinishedProducts.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ClearMessages();
		
		SemiFinishedProductsSelection = New Structure;
		
		SemiFinishedProductsSelection.Insert("ProductionPlan");
		SemiFinishedProductsSelection.Insert("Products");
		SemiFinishedProductsSelection.Insert("Characteristic");
		SemiFinishedProductsSelection.Insert("Purpose");
		SemiFinishedProductsSelection.Insert("ProductionIssueDateOfIntermediateProducts");
		SemiFinishedProductsSelection.Insert("BillOfMaterials"); // information field
		
		FillPropertyValues(SemiFinishedProductsSelection, CurrentData);
		
		SetSelectionByOccurrencesOfSemiFinishedProduct();
		
	Else
		
		WarningText = NStr("vi = 'Để thực hiện một hành động, chọn dòng';
							|ru = 'Для выполнения действия необходимо выбрать строку';
							|en = 'To perform the action, select a line'; fa = 'To perform the action, select a line';
							|it = 'Per eseguire l''azione, è necessario selezionare una riga';
							|pl = 'Aby wykonać akcję, musisz wybrać wiersz';
							|tr = 'Eylemin gerçekleştirilmesi için satırın seçilmesi şart'");
		ShowMessageBox(, WarningText);
		
	EndIf;
	Return; // no additional actions are provided in this configuration
	
EndProcedure

&AtClient
Procedure BackToProduction(Command)
	
	BackToProductionOnServer();
	
EndProcedure

#Region Substitutes

&AtClient
Procedure SelectSubstitutes(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionPlan.Form.DocumentForm.Command.SelectSubstitutes");

	If Object.CrossTable Then
		
		DescriptionOfTheAlert = New CallbackDescription("SwitchPeriodsToRowsCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Có thể lựa chọn các mặt hàng tương tự trong chế độ ""Kỳ trong dòng"". Chuyển chế độ?';
				|ru = 'Подбор аналогов возможно в режиме ""Периоды в строках"". Переключить режим?';
				|en = 'Alternative products can only be picked in the ""Periods in lines"" mode. Enable this mode?'; fa = 'Alternative products can only be picked in the ""Periods in lines"" mode. Enable this mode?';
				|it = 'È possibile selezionare gli analoghi in modalità ""Periodi nelle righe"". Cambiare modalità?';
				|pl = 'Dobór odpowiedników jest możliwy w trybie ""Okresy w wierszach"". Przełącz tryb?';
				|tr = 'İkamelerin seçilme işlemi ""Satırlardaki dönemler"" modunda gerçekleştirilebilir. Bu mod açılsın mı?'"), 
			QuestionDialogMode.YesNo, 
			45, 
			DialogReturnCode.No, 
			NStr("vi = 'Lựa chọn các mặt hàng tương tự';
				|ru = 'Подбор аналогов';
				|en = 'Pick alternative products'; fa = 'انتخاب محصولات جایگزین';
				|it = 'Selezione degli analoghi';
				|pl = 'Dobór odpowiedników';
				|tr = 'İkamelerin seçimi'"), 
			DialogReturnCode.No
		);
		
	Else
		
		SelectedDestinations = New Map;
		
		SelectedRows = Items.ManufacturedProduct.SelectedRows;
		For Each RowID In SelectedRows Do
			
			CurrentRow = Object.ManufacturedProduct.FindByID(RowID);
			
			SelectedDestinations.Insert(CurrentRow.Purpose);
			If SelectedDestinations.Count() > 1 Then
				Break;
			EndIf;	
			
		EndDo;	
		
		If SelectedDestinations.Count() > 1 Then
			ShowMessageBox(, NStr("vi = 'Bạn phải chọn các hàng có cùng mục đích.';
									|ru = 'Необходимо выбрать строки с одинаковым назначением.';
									|en = 'Select lines with the same purpose.'; fa = 'Select lines with the same purpose.';
									|it = 'È necessario selezionare le righe con lo stesso valore.';
									|pl = 'Należy wybrać wiersze z takim samym przeznaczeniem.';
									|tr = 'Aynı değere sahip satırları seçmek şart.'"), 45);
		Else	
			OpenSelectionOfAnalogues();
		EndIf;	
		
	EndIf;
	Return;
	
EndProcedure

#EndRegion

&AtClient
Procedure FillInBOR(Command)
	
	TableDetails = ProductionTableDescription(ThisForm);
	
	SelectedRows = Items[TableDetails.TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Không có dòng được chọn trong bảng. Chọn các dòng để điền vào thuộc tính ""Bảng kê chi tiết các nguồn lực sản xuất""';
								|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения реквизита ""Спецификация""';
								|en = 'No lines are selected in the table. Select lines to fill in the BOM attribute'; fa = 'No lines are selected in the table. Select lines to fill in the BOM attribute';
								|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per compilare il requisito ""Specifica""';
								|pl = 'Brak wydzielonych wierszy w tabeli. Zaznacz wiersze do wypełnienia atrybutu ""Спецификация""';
								|tr = 'Belirtilen satırlar tabloda bulunmamaktadır. ""Ürün Reçetesi"" özniteliklerinin doldurulması için satırları belirtin'"));
		Return;
		
	EndIf;
	
	FillInSpecificationInProductLines(SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInAssignmentByValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.ProductsByDate.SelectedRows,Items.ManufacturedProduct.SelectedRows);
	GoodsTable = ?(Object.CrossTable, ProductsByDate, Object.ManufacturedProduct);
	
	FilterStructure1 = New Structure("IsFolder", False);
	ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", FilterStructure1, FoldersAndItemsUse.Items);
	
	OpenForm(
		"Catalog.Assignments.ChoiceForm", 
		ParametersStructure, 
		ThisForm,
		UUID,
		,
		,
		New CallbackDescription("FillInByCompletionValue",
				PlanningClient,
				New Structure("SelectedRows, GoodsTable, Column", SelectedRows, GoodsTable, "Purpose")), 
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

#Region ProceduresForDynamicFormationOfFormStructure

&AtClient
Procedure WhenChangingPeriodsOnClient(Result, AdditionalParameters) Export 
	
	WhenChangingPeriodsOnServer(,True);
	
EndProcedure

&AtClient
Procedure ConductAndRecalculateNeedsOfCompletion(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		RunAFullRecalculation = True;
		
		TMCommonUseClient.Post(ThisForm);
		
		RunAFullRecalculation = False;
		
		ControlOfCalculationOfProductionPlan();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RunFullRecalculationOfProductionPlan()
	
	Documents.ProductionPlan.RecalculateProductionPlan(Object.Ref, True);
	ThisForm.Read();
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToColumnsCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
		
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToRowsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SwitchPeriodsToRows(Undefined);
	
EndProcedure

&AtServer
Procedure SwitchPeriodsToColumnsOnServer(CachedValues)
	
	Object.CrossTable = True;
	WhenChangingPeriodsOnServer();
	CopyToCrossTable(CachedValues);
	
	ReadSetSpecificationSelectionParameters();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCrossTableTag(Form)

	If Form.Object.CrossTable Then
	
		Form.Items.FormSwitchPeriodsToColumns.Check = True;
		Form.Items.FormSwitchPeriodsToRows.Check = False;
		
		Form.Items.GroupPerformanceProducts.CurrentPage = Form.Items.GroupProductsCrossTable;
	
	Else
	
		Form.Items.FormSwitchPeriodsToColumns.Check = False;
		Form.Items.FormSwitchPeriodsToRows.Check = True;
		
		Form.Items.GroupPerformanceProducts.CurrentPage = Form.Items.GroupProductsTable_3;
	
	EndIf; 

EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure AssignmentWhenChangingOnServer()
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	LineOfBusiness = Common.ObjectAttributeValue(Object.Purpose, "LineOfBusiness");

	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
EndProcedure

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected)
	
	If Not IsTempStorageURL(ValueSelected.GoodsAddressInStorage) Then
		Return;
	EndIf;
	
	GetUploadedProductsFromStorage(ValueSelected.GoodsAddressInStorage, CachedValues);
	
EndProcedure

#EndRegion

&AtServer
Procedure ProductsProductListWhenChangedOnServer(RowID, CachedValues)
	
	TableDetails = ProductionTableDescription(ThisForm);
	
	CurrentRow = TableDetails.TS.FindByID(RowID);
	
	SpecificationBeforeChange = CurrentRow.BillOfMaterials;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",         CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner",      CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, TableDetails.TSName));
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentRow, BOMSelectionParameters, ThisForm, New Structure("KeyOfDataPaths", TableDetails.DataPath));
	
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	PlanningClientServer.SetFormulaPresentation(ThisObject,CurrentRow);
	
	If SpecificationBeforeChange <> CurrentRow.BillOfMaterials
			And Not Object.CrossTable Then
		CalculateProductLaunchDate(ThisObject, CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputCharacteristicWhenChangedOnServer(RowID, CachedValues)
	
	TableDetails = ProductionTableDescription(ThisForm);
	
	CurrentRow = TableDetails.TS.FindByID(RowID);
	
	SpecificationBeforeChange = CurrentRow.BillOfMaterials;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, TableDetails.TSName));
		
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentRow, BOMSelectionParameters, ThisForm, New Structure("KeyOfDataPaths", TableDetails.DataPath));
		
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If SpecificationBeforeChange <> CurrentRow.BillOfMaterials
			And Not Object.CrossTable Then
		CalculateProductLaunchDate(ThisObject, CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputDestinationWhenChangedOnServer(RowID, CachedValues)
	
	TableDetails = ProductionTableDescription(ThisForm);
	
	CurrentRow = TableDetails.TS.FindByID(RowID);
	
	FillInDirectionOfActivity(CommonClientServer.ValueInArray(CurrentRow));
	
EndProcedure

&AtServer
Procedure ProductsReleaseDateWhenChangedOnServer(RowID, CachedValues)
	
	CurrentData = Object.ManufacturedProduct.FindByID(RowID);
	
	StructureOfActions = New Structure;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentData, BOMSelectionParameters, ThisForm, New Structure("KeyOfDataPaths", "Object.ManufacturedProduct"));
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateProductLaunchDate(ThisObject, CurrentData);
	
EndProcedure

#EndRegion

#Region ProcessingWithExcel

&AtServer
Function LoadFromExcelOnServer(ArrayOfDataStructures)
	
	If Object.CrossTable Then
		ProductsByDate.Clear();
	Else
		Object.ManufacturedProduct.Clear();
	EndIf; 
	
	// ID Processing
	For Each ProductStructure_1 In ArrayOfDataStructures Do
		
		If Not ValueIsFilled(ProductStructure_1.ProductID_) Then
			Continue;
		EndIf;
		
		ProductStructure_1.Insert("Products",   Catalogs.Products.GetRef(New UUID(ProductStructure_1.ProductID_)));
		ProductStructure_1.Insert("Characteristic", Catalogs.ItemsCharacteristics.GetRef(New UUID(ProductStructure_1.IdentifierCharacteristic)));
		ProductStructure_1.Insert("Package",       Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.PackageIdentifier)));
		ProductStructure_1.Insert("BillOfMaterials",   Catalogs.BillsOfMaterials.GetRef(New UUID(ProductStructure_1.IDSpecification)));
		ProductStructure_1.Insert("Purpose",     Catalogs.Assignments.GetRef(New UUID(ProductStructure_1.DestinationID_)));
		
	EndDo;
	
	AddProducts_2(ArrayOfDataStructures);
	
	If Not Object.CrossTable Then
		UpdateReplacementAttribute();
	EndIf;
	
EndFunction

&AtClient
Function DownloadFromExcelOnClient(AttachedFile)
	
	ExcelActionStructure = StructureOfActionsWhenLoadingFromExcel();
	
	ProcessingWithExcelClient.ImportFromExcel(ThisForm, AttachedFile, ExcelActionStructure);
	
EndFunction

&AtClient
Function LoadFromExcelOnClient(DownloadData)
	
	ThereAreLinesAdded = False;
	
	For Each LoadingString In DownloadData Do
	
		If Not ValueIsFilled(LoadingString.ProductID_) Then
			
			ThereAreLinesAdded = True;
			Break;
			
		EndIf; 
	
	EndDo; 
	
	If ThereAreLinesAdded Then
		
		ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParametersForPlans();
		ImportParameters.PlanProfile     = Object.PlanProfile;
		ImportParameters.CrossTable = Object.CrossTable;
		ImportParameters.AddressOfThePeriodTable = GetAddressOfPeriodTable();
		ImportParameters.GoodsTableAddress  = PutToTempStorage(DownloadData, UUID);
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		ImportParameters.FilterParameters.ItemsType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ImportParameters.ProductionProcessType = Object.ProductionProcessType;
		
		AddlParameters = New Structure("UpdateAdd", 0); //Always update the plan when downloading from Excel
		Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, AddlParameters);
		ProcessingOfTabularFormsClient.ShowProductUploadFormForPlans(ImportParameters, Notification);
		
	Else
		
		LoadFromExcelOnServer(DownloadData);
		
	EndIf;
	
EndFunction

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		If AdditionalParameters.UpdateAdd = 0 Then
			ProductsByDate.Clear();
			Object.ManufacturedProduct.Clear();
		EndIf;
		GetUploadedProductsFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Function StructureOfActionsWhenLoadingFromExcel()

	ExcelActionStructure = New Structure;
	
	// Defining columns by their headers
	SearchColumns = New ValueList;
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Mặt hàng)';
							|ru = 'Уникальный идентификатор (Номенклатура)';
							|en = 'UUID (Items)'; fa = 'UUID (اقلام)';
							|it = 'Identificatore unico (Articolo)';
							|pl = 'Indywidualny identyfikator (Produkty)';
							|tr = 'Benzersiz kimlik (Ürün)'"),"ProductID_");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Đặc tính)';
							|ru = 'Уникальный идентификатор (Характеристика)';
							|en = 'Unique ID (Variant)'; fa = 'شناسه یکتا (گونه)';
							|it = 'Identificatore unico (Caratteristica)';
							|pl = 'Indywidualny identyfikator (Charakterystyka)';
							|tr = 'Benzersiz kimlik (Varyant)'"),"IdentifierCharacteristic");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Bao bì)';
							|ru = 'Уникальный идентификатор (Упаковка)';
							|en = 'Unique ID (Packaging unit)'; fa = 'شناسه یکتا (واحد بسته‌بندی)';
							|it = 'Identificatore unico (Imballaggio)';
							|pl = 'Indywidualny identyfikator (Opakowanie)';
							|tr = 'Benzersiz kimlik (Paketleme ünitesi)'"),"PackageIdentifier");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Đặc tính)';
							|ru = 'Уникальный идентификатор (Спецификация)';
							|en = 'UUID (Bill of materials)'; fa = 'UUID (فهرست مواد)';
							|it = 'Id unico (Specifica)';
							|pl = 'Unikalny identyfikator (Specyfikacja)';
							|tr = 'Benzersiz tanımlayıcı (Ürün reçetesi)'"),"IDSpecification");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Mục đích)';
							|ru = 'Уникальный идентификатор (Назначение)';
							|en = 'Unique ID (Assignment)'; fa = 'شناسه یکتا (تخصیص)';
							|it = 'Identificatore unico (Assegnazione)';
							|pl = 'Indywidualny identyfikator (Przeznaczenie)';
							|tr = 'Benzersiz tanımlayıcı (Atama)'"),"DestinationID_");
	
	If ValueIsFilled(AdditionalColumnName) Then
		SearchColumns.Add(AdditionalColumnName,"DownloadableArticleNumber");
	EndIf; 
	SearchColumns.Add(NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Articolo';
							|pl = 'Produkt';
							|tr = 'Ürün'"),"ImportedProducts");
	SearchColumns.Add(NStr("vi = 'Đặc tính';
							|ru = 'Характеристика';
							|en = 'Variant'; fa = 'گونه';
							|it = 'Caratteristica';
							|pl = 'Charakterystyka';
							|tr = 'Varyant'"),"ImportedCharacteristic");
	If FillInTheSpecification Then
		SearchColumns.Add(NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Спецификация';
								|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
								|it = 'Specifica';
								|pl = 'Specafikacja';
								|tr = 'Ürün reçetesi'"),"ImportedSpecification");
	EndIf; 
	If FillInAssignmentInTabularForm Then
		SearchColumns.Add(NStr("vi = 'Mục đích';
								|ru = 'Назначение';
								|en = 'Assignment'; fa = 'تخصیص';
								|it = 'Destinazione';
								|pl = 'Przeznaczenie';
								|tr = 'Atama'"),"DownloadableDestination");
	EndIf;
	
	If Object.CrossTable Then
		
		SearchColumns.Add(NStr("vi = 'Đơn vị tính';
								|ru = 'Ед. изм.';
								|en = 'Unit'; fa = 'واحد';
								|it = 'Unità di misura';
								|pl = 'J. m.';
								|tr = 'Ölçü birimi'"),"ImportedPackaging");
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		
		For Each Period In TablePeriods Do
			
			If Not Period.Active_ Or Period.ColumnNumber <=0 Then
				Continue;
			EndIf; 
			SearchColumns.Add(Period.Title,"Period_"+Period.ColumnName);
			If Object.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
				SearchColumns.Add(TrimAll(StrReplace(Period.Title, NStr("vi = 'năm';
																		|ru = 'г.';
																		|en = 'year'; fa = 'سال';
																		|it = 'anno';
																		|pl = 'year';
																		|tr = 'y.'"), "")),"Period_"+Period.ColumnName);
			EndIf;
			SearchColumns.Add(
				PlanningClientServer.GeneratePeriodHeader(
					Object.Periodicity, Period.StartDate, Period.EndDate, Not ShowNumberOfPeriod), 
				"Period_"+Period.ColumnName);
			
		EndDo; 
		PeriodAttributes = New Array;
		PeriodAttributes.Add("Count_");
		
		ExcelActionStructure.Insert("PeriodAttributes", PeriodAttributes);
		ExcelActionStructure.Insert("TimeIntervals", ThisForm.TimeIntervals);
	Else
		
		SearchColumns.Add(NStr("vi = 'Ngày xuất xưởng';
								|ru = 'Дата выпуска';
								|en = 'Release date'; fa = 'تاریخ انتشار';
								|it = 'Data di produzione';
								|pl = 'Data wydania';
								|tr = 'Çıkış tarihi'"),"DateOfProduction");
		SearchColumns.Add(NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'"),"NumberOfPackages");
		SearchColumns.Add(NStr("vi = 'Đơn vị tính';
								|ru = 'Ед. изм.';
								|en = 'Unit'; fa = 'واحد';
								|it = 'Unità di misura';
								|pl = 'J. m.';
								|tr = 'Ölçü birimi'"),"ImportedPackaging");

		
	EndIf; 
	
	ExcelActionStructure.Insert("SearchColumns", SearchColumns);
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("ProductID_",0);
	TheStructureOfTheSearch.Insert("IdentifierCharacteristic",0);
	TheStructureOfTheSearch.Insert("PackageIdentifier",0);
	TheStructureOfTheSearch.Insert("IDSpecification",0);
	TheStructureOfTheSearch.Insert("DestinationID_",0);
	
	ExcelActionStructure.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
	
	ExcelActionStructure.Insert("DataStartLineNumber", 3);
	
	Return ExcelActionStructure;

EndFunction 

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	If Object.CrossTable Then
		ProcessingOfTabularForms.CopyRowsToClipboard(ProductsByDate, Items.ProductsByDate.SelectedRows);
	Else
		ProcessingOfTabularForms.CopyRowsToClipboard(Object.ManufacturedProduct, Items.ManufacturedProduct.SelectedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", AvailableProductTypes.UnloadValues());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,BillOfMaterials,
		|StartDate2,DateOfProduction,ReleaseDateOfProductsOrSemiFinishedProduct,SemiFinishedProduct";
	
	ProductTable = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If ValueIsFilled(ProductTable) Then
		AddProducts_2(ProductTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	ItemArray.Add("ProductsByDateInsertRows");
	ItemArray.Add("ProductsByDateContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	ItemArray.Add("ProductsByDateInsertRows");
	ItemArray.Add("ProductsByDateContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region SimpleFilling

&AtServer
Procedure InitializeSettingsWhenReadingOnServer(DocumentObject)

	If Not ValueIsFilled(Object.Scenario) Or Not ValueIsFilled(Object.PlanProfile) Then
		Return;
	EndIf;
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("Form", ThisObject);
	InitializationParameters.Insert("AttributePath1", "Object.ManufacturedProduct");
	InitializationParameters.Insert("TableFormElement_", "ManufacturedProduct");
	InitializationParameters.Insert("PeriodTableFormElement", "ProductsByDate");
	InitializationParameters.Insert("ProductionProcessType", Object.ProductionProcessType);
	
	Planning.InitializeAdditionalParameters(AdditionalGoodsParameters, AdditionalParametersGoodsByPeriods, InitializationParameters);
	
	InitializeOperatorTrees();
	
	InitializeFormulaOperands();
	
	InitializeSettingsStructure(DocumentObject);

	UpdateOutputStructureOfAdditionalParameters();
	
	ReadMoreParameters(DocumentObject);
	
EndProcedure

&AtServer
Procedure InitializeSettingsStructure(DocumentObject)
	
	If ValueIsFilled(DocumentObject.Ref) Then
		SettingsStructure = DocumentObject.SettingsStructure.Get();
		If SettingsStructure = Undefined Then
			SetSettingValue("SettingsStructure", SettingsStructure);
		EndIf;
	EndIf;
	
	AdditionalSettings(SettingsStructure, AdditionalFields);
	
EndProcedure

&AtServer
Procedure SetSettingValue(SettingName, Setting)
	
	SettingValueFromStorage = Common.CommonSettingsStorageLoad("UserSettings_" + PlanType, "SettingsStructure", Setting);
	If SettingValueFromStorage <> Undefined Then
		Setting = SettingValueFromStorage;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormulaOperands()
	
	ArrayOfOperands = GetOperands(ThisObject);
	
	AdditionalFields.Clear();
	
	For Each Item In ArrayOfOperands Do
		NewRow = AdditionalFields.Add();
		NewRow.Id 	= Item.Name;
		NewRow.DeletionMark = False;
		NewRow.Presentation 	= Item.OperandHeader;
		Item.Property("IncludedInOperand", NewRow.IncludedInOperand);
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeOperatorTrees()
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	
	Planning.InitializeOperatorTrees(Tree);
	
	GroupPresentation = NStr("vi = 'Ví dụ công thức';
							|ru = 'Примеры формул';
							|en = 'Formula examples'; fa = 'Formula examples';
							|it = 'Esempi di formula';
							|pl = 'Przykłady wzorów';
							|tr = 'Formül örnekleri'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "FormulaExamples", GroupPresentation);
	AddTemplatesForFormulasForCalculatingPlannedQuantity(Tree, OperatorsGroup);
	
	OperatorsTreeStorageAddress = PutToTempStorage(Tree, UUID);
	
EndProcedure

&AtClient
Procedure ChangeByPercentageCompletion(Result, AdditionalParameters) Export 

	If Result = Undefined
		Or Result = 0 
		Or Result = DialogReturnCode.Cancel Then
	
		Return;
	EndIf;
	
	If Not Object.CrossTable Then
		SelectedRows = Items.ManufacturedProduct.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.ManufacturedProduct.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
		EndIf;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure RoundOffQuantityCompletion(Result, AdditionalParameters) Export 

	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
	
		Return;
	EndIf;
	
	If Not Object.CrossTable Then
		SelectedRows = Items.ManufacturedProduct.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.ManufacturedProduct.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
		EndIf;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterQuestionSetArbitraryFormula(QuestionResult, AdditionalParameters) Export
	
	StructureOfData = New Structure("Formula,FormulaPresentation,Title,EnableValue,RowsArray,PeriodOfChange");
	
	If Object.CrossTable Then
		
		SelectedRows = Items.ProductsByDate.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = ProductsByDate.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				Operand.Value = ThisObject[Operand.Id];
			EndDo;
			
			StructureOfData.Formula 			= ThisObject.Formula;
			StructureOfData.FormulaPresentation= ThisObject.FormulaPresentation;
			StructureOfData.Title 			= "" + CurrentData.Products + 
														?(ValueIsFilled(CurrentData.Characteristic)," (" + CurrentData.Characteristic + ")","");
			StructureOfData.EnableValue 	= True;
		Else
			StructureOfData.Formula   			 = "";
			StructureOfData.FormulaPresentation = "";
			StructureOfData.Title	 		 = "";
			StructureOfData.EnableValue 	 = False;
		EndIf;
		
		If QuestionResult = DialogReturnCode.Yes Then
			StructureOfData.PeriodOfChange = "AllPeriods";
		ElsIf QuestionResult = DialogReturnCode.No Then
			StructureOfData.PeriodOfChange = AdditionalParameters.ColumnName;
		Else
			Return;
		EndIf;
		
	Else
		
		SelectedRows = Items.ManufacturedProduct.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = Object.ManufacturedProduct.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				If CurrentData.Property(Operand.Id) Then
					Operand.Value = CurrentData[Operand.Id];
				EndIf;
			EndDo;
			
			StructureOfData.Formula 			= CurrentData.Formula;
			StructureOfData.FormulaPresentation= CurrentData.FormulaPresentation;
			StructureOfData.Title 			= "" + CurrentData.Products + 
														?(ValueIsFilled(CurrentData.Characteristic)," (" + CurrentData.Characteristic + ")","");
			StructureOfData.EnableValue 	= True;
		Else
			StructureOfData.Formula   			 = "";
			StructureOfData.FormulaPresentation = "";
			StructureOfData.Title	 		 = "";
			StructureOfData.EnableValue 	 = False;
		EndIf;
		
	EndIf;
	
	StructureOfData.RowsArray = SelectedRows;
	
	SetDecryptionParameters(StructureOfData);
	
	SetArbitraryFormula(StructureOfData);
	
EndProcedure

&AtClient
Procedure SetArbitraryFormula(StructureOfData)
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("Advanced",		True);
	FormParameters.Insert("EnableValue",	StructureOfData.EnableValue);
	FormParameters.Insert("ValueHeader", ""+StructureOfData.DetailsParameters.Filter.Products + 
		?(ValueIsFilled(StructureOfData.DetailsParameters.Filter.Characteristic)," (" + StructureOfData.DetailsParameters.Filter.Characteristic + ")",""));
	FormParameters.Insert("OperationalPlanningExplanationParameters", StructureOfData.DetailsParameters);
	FormParameters.Insert("Formula",			?(StructureOfData.Formula = PlanningClientServer.TextForSettingNewFormula(),"", StructureOfData.Formula));
	FormParameters.Insert("Presentation",	?(StructureOfData.FormulaPresentation = PlanningClientServer.TextForSettingNewFormula(), "", StructureOfData.FormulaPresentation));
	FormParameters.Insert("UsesOperandTree", True);
	FormParameters.Insert("SelectPlanOperand", True);
	FormParameters.Insert("OperandsTree",	PlaceAdditionalFieldsInStorage());
	FormParameters.Insert("Operators",		OperatorsTreeStorageAddress);
	FormParameters.Insert("SavedSettingsObjectKey", "UserSettings_" + PlanType);
	FormParameters.Insert("Filter", 			FilterIndicators);
	FormParameters.Insert("ResultType", New TypeDescription("Number"));
	FormParameters.Insert("FunctionsFromCommonModule", PlanningClient.FunctionsFromCommonModule());
	
	CallbackDescription = New CallbackDescription("AfterOpeningConstructorSetArbitraryFormula",ThisObject, StructureOfData);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.FormulasConstructor", FormParameters, ThisForm,,,,CallbackDescription,Mode);
	
EndProcedure

&AtClient
Procedure Attachable_SetArbitraryFormula(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StructureOfData 		= New Structure("Formula,FormulaPresentation,DetailsParameters,EnableValue,RowsArray,PeriodOfChange");
	RowsArray 			= New Array();
	
	If Object.CrossTable Then
		
		CurrentData = Items.ProductsByDate.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			Operand.Value = ThisObject[Operand.Id];
		EndDo;
		
		CurElementName = Items.ProductsByDate.CurrentItem.Name;
		ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
		
		If ActivePeriods.Count() > 1 Then
			
			If StrFind(CurElementName, "ProductsByDate" + "Count_") = 0
				And StrFind(CurElementName, "ProductsByDate" + "PictureComment_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'")); 
				Return;
			Else
				For Each Period In ActivePeriods Do
					If CurElementName = "ProductsByDate" + "Count_" + Period.ColumnName 
						Or CurElementName = "ProductsByDate" + "PictureComment_" + Period.ColumnName Then
						StructureOfData.Formula 				= CurrentData["Formula_" + Period.ColumnName];
						StructureOfData.FormulaPresentation 	= CurrentData["FormulaPresentation_" + Period.ColumnName];
						StructureOfData.PeriodOfChange 		= Period.ColumnName;
					EndIf;
				EndDo;
			EndIf;
			
		Else
			
			For Each Period In ActivePeriods Do
				StructureOfData.Formula 				= CurrentData["Formula_" + Period.ColumnName];
				StructureOfData.FormulaPresentation 	= CurrentData["FormulaPresentation_" + Period.ColumnName];
				StructureOfData.PeriodOfChange 		= Period.ColumnName;
			EndDo;
			
		EndIf;
		
	Else
		
		CurrentData = Items.ManufacturedProduct.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			If CurrentData.Property(Operand.Id) Then
				Operand.Value = CurrentData[Operand.Id];
			EndIf;
		EndDo;
		
		StructureOfData.Formula 				= CurrentData.Formula;
		StructureOfData.FormulaPresentation 	= CurrentData.FormulaPresentation;
		StructureOfData.PeriodOfChange 		= "AllPeriods";
		
	EndIf;
	
	StructureOfData.EnableValue 		= True;
	StructureOfData.RowsArray 			= RowsArray;
	
	SetDecryptionParameters(StructureOfData);
	
	SetArbitraryFormula(StructureOfData);
	
EndProcedure

&AtClient
Procedure AfterOpeningConstructorSetArbitraryFormula(Result, StructureOfData) Export
	
	RowsArray = StructureOfData.RowsArray;
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If Object.CrossTable Then
		
		If StructureOfData.Property("PeriodOfChange") Then
			PeriodName = StructureOfData.PeriodOfChange;
		Else
			PeriodName = "AllPeriods";
		EndIf;
		
		For Each LineID In RowsArray Do
			
			For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
				
				If PeriodName <> "AllPeriods" Then
					
					RowOfGoods = ProductsByDate.FindByID(LineID);
					
					If RowOfGoods.SemiFinishedProduct Then
						Continue;
					EndIf;
				
					If PeriodName = Period.ColumnName Then
						CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						RowOfGoods["Deviation_" + Period.ColumnName] = 0;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
						PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
					ElsIf ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) And RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
						CalculationResult = PlanningClient.CalculateByFormula(RowOfGoods["Formula_" + Period.ColumnName], RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
					EndIf; 
					
				ElsIf PeriodName = "AllPeriods" Then
					
					RowOfGoods = ProductsByDate.FindByID(LineID);
					
					If RowOfGoods.SemiFinishedProduct Then
						Continue;
					EndIf;
					
					CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period,Result.Presentation);
					RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
					RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
					RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
					RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
					RowOfGoods["Deviation_" + Period.ColumnName] = 0;
					
					WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
					
					PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CalculateTotals_(ThisForm, False);
		
	Else
		
		For Each LineID In RowsArray Do
			
			RowOfGoods = Object.ManufacturedProduct.FindByID(LineID);
			CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, Undefined, Undefined, Result.Presentation);
			RowOfGoods.Formula = Result.Formula;
			RowOfGoods.FormulaPresentation = CalculationResult.Presentation;
			RowOfGoods.FormulaCalculation = CalculationResult.Calculation;
			RowOfGoods.NumberOfPackages = CalculationResult.Result;
			RowOfGoods.Deviation = 0;
			
			RecalculateNumberOfPackagesAndAmountPerLine(RowOfGoods, CachedValues);
			
		EndDo;
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
	Modified = True;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - LongDesc
// Returns:
// 	Array of See Planning.FieldStructure - 
&AtClientAtServerNoContext
Function GetAdditionalBankingDetails(Form)

	AddAttributes = New Array();
	
	If Form.AdditionalParametersGoodsByPeriods = Undefined Then
		Return AddAttributes;
	EndIf;

	For Each Field In Form.AdditionalParametersGoodsByPeriods Do
		If Field.Value.CreateProps Then
			AddAttributes.Add(Field.Value);
		EndIf;
	EndDo;
	
	Return AddAttributes;

EndFunction

// Parameters:
// 	Form - ClientApplicationForm - LongDesc
// Returns:
// 	Array of See Planning.FieldStructure - 
&AtClientAtServerNoContext
Function GetOperands(Form)

	ArrayOfOperands = New Array();
	
	If Form.AdditionalParametersGoodsByPeriods = Undefined Then
		Return ArrayOfOperands;
	EndIf;

	For Each Field In Form.AdditionalParametersGoodsByPeriods Do
		If Field.Value.CreateOperand Then
			ArrayOfOperands.Add(Field.Value);
		EndIf;
	EndDo;
	
	Return ArrayOfOperands;

EndFunction

&AtServer
Function PlaceAdditionalFieldsInStorage()
	
	Return Planning.PlaceAdditionalFieldsInStorage(ThisForm, SettingsStructure.PeriodOffset);
	
EndFunction

&AtServer
Procedure AddTemplatesForFormulasForCalculatingPlannedQuantity(Tree, OperatorsGroup)
	
	Scenario = Planning.ScriptParameters_(Object.Scenario);
	
	UseSalesPlans_ 				= GetFunctionalOption("UseSalesPlans")
		And Scenario.UseInSalesPlanning;
	UseProductionPlanning 	= GetFunctionalOption("UseProductionPlanning")
		And Scenario.UseInProductionPlanning;
	UseForMaterialsPlanning	= GetFunctionalOption("UseProductionPlanning")
		And Scenario.UseForMaterialsPlanning;
	UseProcurementPlans 				= GetFunctionalOption("UsePurchasePlanning")
		And Scenario.UseInPurchasePlanning;
	UseBuildPlans					= GetFunctionalOption("UseAssemblyDisassemblyPlanning")
		And Scenario.UseInAssemblyDisassemblyPlanning;
	UseRemainderPlans 				= GetFunctionalOption("UsePlanningOfGoodsStock")
		And Scenario.UseInBalancePlanning;
	UseInternalConsumptionPlans 	= GetFunctionalOption("UsePlanningOfInventoryConsumption")
		And Scenario.UseInPlanningOfInternalConsumption;
	
	Id = "[ProductionPlans] * 1.15";
	StructureToInsert = "[ProductionPlans] * 1.15";
	Presentation = NStr("vi = 'Kế hoạch sản xuất +15%';
						|ru = 'План производства +15%';
						|en = 'Production plan +15%'; fa = 'Production plan +15%';
						|it = 'Piano di produzione + 15%';
						|pl = 'Plan produkcji +15%';
						|tr = 'Üretim planı +15%'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseSalesPlans_, "[SalesPlans]", "[SalesFacts] / [ShareOfStockAvailabilityDays]")
		+ ?(UseRemainderPlans, " - [PlanOfGoodsStock]" ,
				?(PlanningByAssignments, " - [ActualStartBalance]", " - [AvailableStock]"));
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Đảm bảo doanh số bán hàng tối thiểu';
						|ru = 'Минимальное обеспечение продаж';
						|en = 'Min sales provision'; fa = 'Min sales provision';
						|it = 'Approvvigionamento minimo delle vendite';
						|pl = 'Minimalne zabezpieczenie sprzedaży';
						|tr = 'Minimal satış karşılama'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = "(Max([ProductionPlans], "
			+ ?(UseSalesPlans_,"[SalesPlans])","[SalesFacts] / [ShareOfStockAvailabilityDays])")
			+ ?(UseRemainderPlans," - [PlanOfGoodsStock]) * 1.1",
				?(PlanningByAssignments," - [ActualStartBalance]) * 1.1"," - [AvailableStock]) * 1.1"));
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch sản xuất tối đa có điều chỉnh bán hàng +10%';
						|ru = 'Максимальный план производства с учетом корректировки продаж +10%';
						|en = 'Max production plan considering sales adjustment +10%'; fa = 'Max production plan considering sales adjustment +10%';
						|it = 'Piano di produzione massimo, tenendo conto della rettifica di vendite + 10%';
						|pl = 'Maksymalny plan produkcji, uwzględniając korekty sprzedaży +10%';
						|tr = 'Maksimum üretim planına dair satışların +10% düzenlemesi'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseSalesPlans_, "[SalesPlans]", "0")
		+ ?(UseBuildPlans, " + [BuildPlansComponents]", "")
		+ ?(UseBuildPlans, " + [DisassemblyPlansKits]", "")
		+ ?(UseInternalConsumptionPlans, " + [InventoryConsumptionPlans]","")
		+ ?(UseForMaterialsPlanning, " + [ProductionPlansMaterials]","");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch nhu cầu';
						|ru = 'Планы потребностей';
						|en = 'Demand plans'; fa = 'برنامه‌های نیاز';
						|it = 'Piani dei fabbisogni';
						|pl = 'Plany zapotrzebowania';
						|tr = 'Gereksinimlerin planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseProcurementPlans, "[PurchasePlans]", "0")
		+ ?(UseBuildPlans, " + [AssemblyPlansKits]", "")
		+ ?(UseBuildPlans, " + [DisassemblyPlansComponents]", "")
		+ ?(UseProductionPlanning, " + [ProductionPlans]", "");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch đảm bảo';
						|ru = 'Планы обеспечения';
						|en = 'Supply plans'; fa = 'برنامه‌های تأمین';
						|it = 'Piani di approvvigionamento';
						|pl = 'Plany zaspokojenia';
						|tr = 'Teminat planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseProcurementPlans, "[PurchasePlans]", "0")
		+ ?(UseBuildPlans, " + [AssemblyPlansKits]", "")
		+ ?(UseBuildPlans, " + [DisassemblyPlansComponents]", "")
		+ ?(UseProductionPlanning, " + [ProductionPlans]", "")
		+ ?(UseSalesPlans_, " - [SalesPlans]", "")
		+ ?(UseBuildPlans, " - [BuildPlansComponents]", "")
		+ ?(UseBuildPlans, " - [DisassemblyPlansKits]", "")
		+ ?(UseInternalConsumptionPlans," - [InventoryConsumptionPlans]","")
		+ ?(UseForMaterialsPlanning, " - [ProductionPlansMaterials]", "");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Chênh lệch giữa các kế hoạch';
						|ru = 'Отклонение планов';
						|en = 'Plan variance'; fa = 'Plan variance';
						|it = 'Scostamento dei piani';
						|pl = 'Odrzucenie planów';
						|tr = 'Fark planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = "ColumnValue(CurrentColumnNumber() - 1)";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Giá trị cột trước';
						|ru = 'Значение предыдущей колонки';
						|en = 'Previous column value'; fa = 'Previous column value';
						|it = 'Valore della colonna precedente';
						|pl = 'Poprzednia wartość kolumny';
						|tr = 'Önceki sütunun anlamı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
EndProcedure

&AtClient
Procedure SetUpFormulaAndFillIn(Settings, AdditionalParameters) Export

	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	SettingsStructure = Settings;
	
	If SettingsStructure.ContentFillingVariant = "Filter" Then
		
		ProductsByDate.Clear();
		Object.ManufacturedProduct.Clear();
		GoodsLineQuantity = 0;
		
		Notification = New CallbackDescription("SetUpFormulaAndFillInCompletion", ThisObject, Settings);
		AddProductsBySelectionOnClient(Notification);
		Return;
		
	ElsIf SettingsStructure.ContentFillingVariant = "DoNotChange" Then
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		If Settings.Property("FillingComposition") Then
			Settings.Delete("FillingComposition");
		EndIf; 
		
		FillInDocument(Settings);
		
	Else
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		Settings.Insert("FillingComposition", True);
		
		FillInDocument(Settings);
		
	EndIf;
	
	If Object.CrossTable And Items.ProductsByDate.CurrentData = Undefined Then
		PlanningClientServer.ClearFormulaValue(ThisObject);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure SetUpFormulaAndFillInCompletion(Result, Settings) Export
	
	If ValueIsFilled(Result) Then
		
		If Not Object.CrossTable Then
			FillInProductCompositionBySelection(CachedValues);
		EndIf;
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		If Settings.Property("FillingComposition") Then
			Settings.Delete("FillingComposition");
		EndIf; 
		
		FillInDocument(Settings);
		
	EndIf;
	
	If Object.CrossTable And Items.ProductsByDate.CurrentData = Undefined Then
		PlanningClientServer.ClearFormulaValue(ThisObject);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure AdjustOffsetAndFill(Settings, AdditionalParameters) Export
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	SettingsStructure = Settings;
	
	Settings.Insert("FillInUsingFormula", True);
	Settings.Insert("PopulateOperands", True);
	If Settings.Property("FillingComposition") Then
		Settings.Delete("FillingComposition");
	EndIf; 
	
	FillInDocument(Settings);

EndProcedure

&AtClient
Procedure AddProductsBySelectionOnClient(NotificationOfAddition = Undefined)
	
	FormParameters = New Structure();
	FormParameters.Insert("Title",               NStr("vi = 'Chọn sản phẩm';
														|ru = 'Подбор продукции';
														|en = 'Product picking'; fa = 'Product picking';
														|it = 'Selezione dei prodotti';
														|pl = 'Wybór produkcji';
														|tr = 'İmal edilen ürünlerin seçimi'"));
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	FormParameters.FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5")); 
	If SettingsStructure.Property("SelectionOfProductsSettings") Then
		FormParameters.Insert("SelectionOfProductsSettings", SettingsStructure.SelectionOfProductsSettings);
	Else
		FormParameters.Insert("SelectionOfProductsSettings", Undefined)
	EndIf;
	
	AdditionalParameters = New Structure("NotificationOfAddition", NotificationOfAddition);
	Notification = New CallbackDescription("AddGoodsByPickingCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"DataProcessor.GoodsSelectionByPicking.Form",
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, New Structure("GoodsAddressInStorage", Result));
		
		NotifyUserAboutFillingInData();
		
	EndIf;
	
	If AdditionalParameters.NotificationOfAddition <> Undefined Then
	
		RunCallback(AdditionalParameters.NotificationOfAddition, Result);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProductCompositionBySelection(CachedValues)
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	ActivePeriods = TablePeriods.FindRows(New Structure("Active_", True));
	
	ProductByFilter = Object.ManufacturedProduct.Unload();
	
	Object.ManufacturedProduct.Clear();
	
	For Each Period In ActivePeriods Do
	
		For Each RowOfProduct In ProductByFilter Do
		
			CurrentRow = Object.ManufacturedProduct.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")] = Period.StartDate;
			CurrentRow.Formula = SettingsStructure.Formula;
			CurrentRow.FormulaPresentation = SettingsStructure.FormulaPresentation;
			CurrentRow.FormulaCalculation = SettingsStructure.Formula;
		
		EndDo; 
	
	EndDo;
	
	If FillInBOMByPeriods And Not Object.CrossTable Then
		FillInSpecificationInProductLines();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDecryptionParameters(StructureOfData)
	
	If Object.CrossTable Then
		CurrentData = Items.ProductsByDate.CurrentData;
	Else
		CurrentData = Items.ManufacturedProduct.CurrentData;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	FilterIndicators.Insert("Products", 			CurrentData.Products);
	FilterIndicators.Insert("Characteristic", 			CurrentData.Characteristic);
	
	QueryOptions = New Structure();
	QueryOptions.Insert("Ref", 				Object.Ref);
	QueryOptions.Insert("Periodicity", 			Object.Periodicity);
	QueryOptions.Insert("PeriodOffset", 		AdditionalSettings(SettingsStructure).PeriodOffset);
	QueryOptions.Insert("Scenario", 				Object.Scenario);
	QueryOptions.Insert("FilterByProductSegmentIsUsed",False);
	QueryOptions.Insert("Fields", 					AdditionalParametersGoodsByPeriods);
	QueryOptions.Insert("Filter", 					FilterIndicators);
	
	SetRequestPeriod(QueryOptions);
	
	StructureOfData.Insert("DetailsParameters", QueryOptions);
	
EndProcedure

&AtClient
Procedure SetRequestPeriod(QueryOptions)

	If Object.CrossTable Then
		
		CurElementName = Items.ProductsByDate.CurrentItem.Name;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		For Each Period In TablePeriods.FindRows(New Structure("Active_", True)) Do
			If CurElementName = "ProductsByDate" + "Count_" + Period.ColumnName  Then
				QueryOptions.Insert("OffsetPeriodStart", 	Period.StartDate);
				QueryOptions.Insert("OffsetPeriodEnd", 	Period.EndDate);
			EndIf;
		EndDo;

	Else
		
		CurrentData = Items.ManufacturedProduct.CurrentData;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("StartDate", CurrentData[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")]);
		TheStructureOfTheSearch.Insert("Active_", True);
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		RowsArray = TablePeriods.FindRows(TheStructureOfTheSearch);
		
		If RowsArray.Count() > 0 Then
			QueryOptions.Insert("OffsetPeriodStart", 	RowsArray[0].StartDate);
			QueryOptions.Insert("OffsetPeriodEnd", 	RowsArray[0].EndDate);
		EndIf;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function AdditionalSettings(SettingsStructure, AdditionalFields = Undefined)
	
	If Not TypeOf(SettingsStructure) = Type("Structure") Then
		
		SettingsStructure = New Structure();
		SettingsStructure.Insert("ContentFillingVariant", "Filter");
		
		SettingsStructure.Insert("OffsetOption", "PreviousPeriod_");
		SettingsStructure.Insert("PeriodOffset", -1);
		
		SettingsStructure.Insert("PricePopulationOption", "PriceKind");
		SettingsStructure.Insert("PriceKind",);
		SettingsStructure.Insert("UsePriceType", False);
		
		SettingsStructure.Insert("Formula","[ProductionPlans] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng 15% trong kế hoạch sản xuất trước đây';
															|ru = 'Увеличение планов производства прошлых периодов на 15%';
															|en = 'Increase the production plans of the previous periods by 15%'; fa = 'Increase the production plans of the previous periods by 15%';
															|it = 'Aumento del 15% dei piani di produzione dei periodi precedenti';
															|pl = '15% wzrost w poprzednich planach produkcyjnych';
															|tr = 'Önceki dönemlerin üretim planlarının yüzde 15 artırılması'"));
		
		SettingsStructure.Insert("FilterEmptyLines", False);
		
	Else
		If SettingsStructure.Property("Offset") Then
		
			SettingsStructure.Insert("PeriodOffset", -1 * SettingsStructure.Offset);
			SettingsStructure.Delete("Offset");
		
		EndIf;
		
		AdditionalParameters = New Structure("NotOutputMessages", True);
		
		If AdditionalFields <>  Undefined Then
			ArrayOfOperands = New Array;
			For Each CurRow In AdditionalFields Do
				
				ArrayOfOperands.Add(CurRow.Id);
				
			EndDo;
			
			ResultType = New TypeDescription("Number");
			#If Client Then
				CheckParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
				CheckParameters.NotOutputMessages = True;
				WorkingWithFormulasCheckFormula = ProcessingOfFormulasClient.CheckFormula(SettingsStructure.Formula,
					ArrayOfOperands, ResultType, CheckParameters);
			#Else
				CheckParameters = ProcessingOfFormulas.FormulaValidationParameters();
				CheckParameters.NotOutputMessages = True;
				WorkingWithFormulasCheckFormula = ProcessingOfFormulas.CheckFormula(SettingsStructure.Formula,
					ArrayOfOperands, ResultType, CheckParameters);
			#EndIf
			
			If Not WorkingWithFormulasCheckFormula Then
				
				SettingsStructure.Insert("Formula","[ProductionPlans] * 1.15");
				SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng 15% trong kế hoạch sản xuất trước đây';
																	|ru = 'Увеличение планов производства прошлых периодов на 15%';
																	|en = 'Increase the production plans of the previous periods by 15%'; fa = 'Increase the production plans of the previous periods by 15%';
																	|it = 'Aumento del 15% dei piani di produzione dei periodi precedenti';
																	|pl = '15% wzrost w poprzednich planach produkcyjnych';
																	|tr = 'Önceki dönemlerin üretim planlarının yüzde 15 artırılması'"));
				SettingsStructure.Insert("FilterEmptyLines", False);
				
			EndIf;
		EndIf;
	EndIf;
	
	If Not SettingsStructure.Property("FilterEmptyLines") Then
		SettingsStructure.Insert("FilterEmptyLines", False);
	EndIf;
	
	If Not SettingsStructure.Property("FilterByAvailabilityOfBOM") Then
		SettingsStructure.Insert("FilterByAvailabilityOfBOM", False);
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Procedure RecordAdditionalParameters(DocumentObject)

	AddlAttributesArray = GetAdditionalBankingDetails(ThisObject);
	
	For Each CurrentRow In DocumentObject.ManufacturedProduct Do
		
		CollectionItem = Object.ManufacturedProduct.Get(CurrentRow.LineNumber-1);
		If CollectionItem = Undefined Then
			Continue;
		EndIf;
		
		AddnlParameter_ = CurrentRow.AdditionalParameters.Get();
		
		If TypeOf(AddnlParameter_) <> Type("Structure") Then
			AddnlParameter_ = New Structure();
		EndIf;
		
		For Each AdditionalAttribute5 In AddlAttributesArray Do
			
			Id 	 = AdditionalAttribute5.Name;
			
			If CollectionItem.Property(Id) Then
			
				AddnlParameter_.Insert(Id,CollectionItem[Id]);
			
			EndIf;
			
		EndDo;
		
		CurrentRow.AdditionalParameters = New ValueStorage(AddnlParameter_);
	
	EndDo;

EndProcedure

&AtServer
Procedure ReadMoreParameters(DocumentObject)
	
	For Each CurrentRow In DocumentObject.ManufacturedProduct Do
		
		If CurrentRow.SemiFinishedProduct Then
			Continue;
		EndIf;
		
		CollectionItem = Object.ManufacturedProduct.Get(CurrentRow.LineNumber-1);
		If CollectionItem = Undefined Then
			Continue;
		EndIf;
		
		AddAttributes = CurrentRow.AdditionalParameters.Get();
		
		If TypeOf(AddAttributes) <> Type("Structure") Then
			Continue;
		EndIf;
		
		For Each AdditionalAttribute5 In AddAttributes Do
		
			Id 	 = AdditionalAttribute5.Key;
			
			If CollectionItem.Property(Id) Then
				CollectionItem[Id] = AdditionalAttribute5.Value;
			EndIf;
		
		EndDo; 
		
	EndDo; 

EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateNumberOfPackagesAndAmountPerLine(CurrentRow, CachedValues)

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	#If Client Then
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	#Else
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	#EndIf
	
EndProcedure

&AtClient
Procedure WhenChangingQuantityDeviation(RowOfGoods)
	
	For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
		
		If Not ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) Then
			Continue;
		EndIf;
		
		CalculationResult = PlanningClient.CalculateByFormula(RowOfGoods["Formula_" + Period.ColumnName], RowOfGoods, ThisForm.TimeIntervals, Period);
		
		If Items.ProductsByDate.CurrentItem.Name = "ProductsByDate" + "Count_" + Period.ColumnName Then
			RowOfGoods["Deviation_" + Period.ColumnName] = CalculationResult.Result - RowOfGoods["Count_" + Period.ColumnName];
		ElsIf RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
			RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
		EndIf;
		
	EndDo;
	
	PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
	
EndProcedure

&AtServer
Procedure UpdateOutputStructureOfAdditionalParameters()

	TableOutputParameters = New Structure("Fields", AdditionalGoodsParameters);
	Planning.UpdateTableOutputStructure(ThisObject, TableOutputParameters);
	
	CrossTableOutputParameters = New Structure("Fields", AdditionalParametersGoodsByPeriods);
	Planning.UpdateTableOutputStructure(ThisObject, CrossTableOutputParameters);

EndProcedure

&AtServer
Procedure AddFieldsFromAdditionalParameters(OutputParameters)

	AddAttributes = GetAdditionalBankingDetails(ThisObject);
	
	For Each AdditionalAttribute5 In AddAttributes Do
		FieldStructure = New Structure;
		FieldStructure.Insert("ColumnAttributePrefix", AdditionalAttribute5.Name + "_");
		FieldStructure.Insert("DeleteTableDetails", AdditionalAttribute5.DeleteTableDetails);
		FieldStructure.Insert("CreateElement_", False);
		FieldStructure.Insert("ElementType", AdditionalAttribute5.Type);
		FieldStructure.Insert("CreateSummaryDetails", False);
		
		OutputParameters.Fields.Add(FieldStructure);
	EndDo;	

EndProcedure

&AtServer
Procedure AddBankingDetailsFromAdditionalParameters(AttributesStructure1)

	AddAttributes = GetAdditionalBankingDetails(ThisObject);
	
	For Each AdditionalAttribute5 In AddAttributes Do
		AttributesStructure1.Insert(AdditionalAttribute5.Name + "_", AdditionalAttribute5.Name);
	EndDo; 

EndProcedure

&AtClient
Procedure ProductsByDateOnActivateCell(Item)
	
	AttachIdleHandler("OutputByDateWhenActivatingCellOnClient", 0.5, True);
	
EndProcedure

#EndRegion

#Region ProceduresForExchangingDataBetweenTablePartAndFormTable

&AtServer
Procedure CopyFromCrossTable(CachedValues, Var_ThisObject)
	
	If Var_ThisObject.CrossTable 
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
			BackToProductionOnServer();
		EndIf;
		
		Planning.FillInTableFromCrossTable(Var_ThisObject.ManufacturedProduct, Object.ManufacturedProduct, ProductsByDate, ConversionParameters, 
			StructureOfActions, CachedValues, AllSemiFinishedProductsByDate);
		
		FillInProductLaunchDates(Var_ThisObject);
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtServer
Procedure CopyToCrossTable(CachedValues)
	
	If Object.CrossTable
		Or PlannedBalanceIsUsed Then 
		
		ConversionParameters = CrossTableConversionParameters();
		
		For Each TSRow In Object.ManufacturedProduct Do
			If Not ValueIsFilled(TSRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")]) Then
				TSRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")] = Object.BeginOfPeriod;
			EndIf;
		EndDo; 
		
		PlanningClientServer.FillInCrossTableFromTable(ProductsByDate, Object.ManufacturedProduct, ConversionParameters, AllSemiFinishedProductsByDate);
		
		CalculateTotals_(ThisForm);
		
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductsByDate");
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	FillInServiceDetails();
	
EndProcedure

&AtServer
Function CrossTableConversionParameters()

	TablePeriods 	= FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("StartDate", ?(ThisIsDisassembly, "StartDate2", "DateOfProduction"));
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Count_","NumberOfPackages");
	AttributesStructure1.Insert("Canceled_","Canceled");
	AttributesStructure1.Insert("Substituted_","Substituted");
	AttributesStructure1.Insert("SubstitutedToOrder_","SubstitutedToOrder");
	AttributesStructure1.Insert("Comment_","Comment");
	
	If Object.FillInUsingFormula Then
		AddBankingDetailsFromAdditionalParameters(AttributesStructure1);
	Else
		AttributesStructure1.Insert("Details_","Details");
	EndIf;
	
	GroupFields = "Products, Characteristic, Package, BillOfMaterials, SemiFinishedProduct";
	
	If FillInAssignmentInTabularForm Then
		GroupFields = GroupFields + ", Purpose";
	EndIf;
	
	StructureOfFinalDetails = New Structure;
	StructureOfFinalDetails.Insert("NumberOfPackages", "NumberOfPackages");
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("Periodicity",               Object.Periodicity);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	ConversionParameters.Insert("StructureOfFinalDetails", StructureOfFinalDetails);
	
	Return ConversionParameters;

EndFunction

&AtClientAtServerNoContext
Procedure CalculateNumberOfRows(Form)

	If Form.Object.CrossTable Then
	
		Form.GoodsLineQuantity = Form.ProductsByDate.Count();
	
	Else
	
		Form.GoodsLineQuantity = Form.Object.ManufacturedProduct.Count();
	
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function PlanViewParameters(Form)

	PlanViewParameters = New Structure("FillInBusinessUnit, PlanningByAssignments, FillInAssignmentInTabularForm");
	FillPropertyValues(PlanViewParameters, Form);
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Function FilterParameters(Form)
	
	FilterParameters = New Structure("Department, Purpose, ProductionProcessType");
	FillPropertyValues(FilterParameters, Form.Object);
	
	Return FilterParameters;
	
EndFunction

&AtClient
Function CheckHeaderFilling()
	
	ClearMessages();
	FilledIn_Correctly = True;
	
	If Not ValueIsFilled(Object.Scenario) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kịch bản""';
				|ru = 'Поле ""Сценарий"" не заполнено';
				|en = '""Scenario"" is required'; fa = '""Scenario"" is required';
				|it = 'Il campo ""Scenario"" non è compilato';
				|pl = 'Pole ""Scenariusz"" nie wypełnione';
				|tr = '""Senaryo"" alanı doldurulmadı.'"),
			Object.Ref,
			"Object.Scenario");
		FilledIn_Correctly = False;
	EndIf;
	
	If Not ValueIsFilled(Object.PlanProfile) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Dạng thanh toán""';
				|ru = 'Поле ""Вид плана"" не заполнено';
				|en = '""Plan profile"" is required'; fa = '""Plan profile"" is required';
				|it = 'Il campo ""Tipo di piano"" non è compilato';
				|pl = 'Pole ""Rodzaj planu"" nie wypełnione';
				|tr = '""Plan profili"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.PlanProfile");
		FilledIn_Correctly = False;
	EndIf;
	
	If FillInBusinessUnit And Not ValueIsFilled(Object.Department) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường "" Bộ phận-điều phối""';
				|ru = 'Поле ""Подразделение-диспетчер"" не заполнено';
				|en = '""Dispatching unit"" is required'; fa = '""Dispatching unit"" is required';
				|it = 'Il campo ""Reparto di controllo"" non è compilato';
				|pl = 'Pole ""Dział-dyspozytor"" nie jest wypełnione';
				|tr = '""Üretim planlama departmanı"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.Department");
		FilledIn_Correctly = False;
	EndIf;
	
	If ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)).Count() = 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đã đặt tham số kỳ không đúng. Không thể điền';
				|ru = 'Параметры периода заданы неверно. Заполнение невозможно';
				|en = 'Period parameters are specified incorrectly. Cannot populate the header'; fa = 'Period parameters are specified incorrectly. Cannot populate the header';
				|it = 'I parametri del periodo sono impostati in modo errato. La compilazione non è possibile';
				|pl = 'Ustawienia okresu nieprawidłowe. Wypełnienie jest niemożliwe';
				|tr = 'Dönem parametreleri yanlış ayarlanmış. Doldurma işlemi gerçekleştirilemez'"),
			Object.Ref);
		FilledIn_Correctly = False;
	EndIf;
	
	Return FilledIn_Correctly;
	
EndFunction

#Region FillingInBackground

&AtClient
Procedure FillInDocument(Settings)
	
	FillInDocumentCompletion(Settings);
	
EndProcedure


&AtServerNoContext
Procedure ProcessFillingResultUsingFormula(Form)
	
	LastPeriod = Form.TimeIntervals[Form.TimeIntervals.Count()-1];
	LinesToDelete = New Array;
	PreviousPeriod_ = Undefined;
	AdjustmentSign = Planning.GetAdjustmentSign(Form);
	If Form.Object.Substitutional Then
		MainOperandOfPlan = Planning.MainOperandOfPlan(Form);
		MainOperandOfPlanWithSelection = Planning.MainOperandOfPlan(Form, True);
	Else
		MainOperandOfPlan = "";
		MainOperandOfPlanWithSelection = "";
	EndIf;
	
	TablePeriods = Form.TimeIntervals; // See Planning.TablePeriods
	For Each Period In TablePeriods Do
		For Each RowOfGoods In Form.ProductsByDate Do
			
			If RowOfGoods.SemiFinishedProduct Then 
				Continue;
			EndIf;
			
			If Form.PlannedBalanceIsUsed Then
				NewPlanOfRemnants = Form.BalancePlansPeriods.FindByValue(Period.StartDate) <> Undefined;
				NewResiduePlanWithSelection = Form.BalancePlanPeriodsWithSelection.FindByValue(Period.StartDate) <> Undefined;
				
				Planning.CalculateCalculatedOperands(RowOfGoods, Period, PreviousPeriod_, NewPlanOfRemnants, "_", MainOperandOfPlan, AdjustmentSign);
				Planning.CalculateCalculatedOperands(RowOfGoods, Period, PreviousPeriod_, NewResiduePlanWithSelection, "WithSelection_", MainOperandOfPlanWithSelection, AdjustmentSign);
			EndIf;
			
			If Period.Active_ Then
				
				CalculationResult = Planning.CalculateByFormula(Form.SettingsStructure.Formula, RowOfGoods, Form.TimeIntervals, Period, Form.SettingsStructure.FormulaPresentation);
				
				If Form.PlannedBalanceIsUsed Then
					RowOfGoods["AccumulatedPlannedClosingShortage_"+Period.ColumnName] = RowOfGoods["AccumulatedPlannedClosingShortage_"+Period.ColumnName]
					+ AdjustmentSign * CalculationResult.Result;
					
					If RowOfGoods.Property("AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName) Then
						RowOfGoods["AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName] = RowOfGoods["AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName]
						+ AdjustmentSign * CalculationResult.Result;
					EndIf;
				EndIf;
				
				RowOfGoods["Formula_" + Period.ColumnName] = Form.SettingsStructure.Formula;
				RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
				RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
				RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
				RowOfGoods["Deviation_" + Period.ColumnName] = 0;
				
				WhenChangingAmountOfRowSum(Form.Object, Form, RowOfGoods);
				
			EndIf;
		
			If Period = LastPeriod
				And RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
				
		EndDo;
		
		PreviousPeriod_ = Period;
		
	EndDo;
	
	If Form.SettingsStructure.ContentFillingVariant = "Formula" 
		Or Form.SettingsStructure.FilterEmptyLines Then
		For Each RowToDelete In LinesToDelete Do
			Form.ProductsByDate.Delete(RowToDelete);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function FillInDocumentOnServer(Val JobParameters, CachedValues)
	
	If JobParameters.Property("FillInUsingFormula") Then
		
		PrepareParametersForFillingInDocumentUsingFormula(JobParameters, CachedValues);
		
	ElsIf JobParameters.Property("FillInRule") Then
		
		PrepareParametersForFillingInDocumentAccordingToFillingRule(JobParameters, CachedValues);
		
	ElsIf JobParameters.Property("FillInForReplacement") Then
		
		PrepareParametersForFillingInReplacementDocument(JobParameters, CachedValues);
		
	EndIf; 
	
	If JobParameters.Property("PlanningSemiFinishedProducts") Then
	
		PrepareParametersForFillingDocumentWithSemiFinishedProducts(JobParameters, CachedValues);
		
	EndIf;
	
	JobDescription = NStr("vi = 'Điền chứng từ kế hoạch:';
							|ru = 'Заполнение документа плана:';
							|en = 'Fill in document of payment schedule:'; fa = 'Fill in document of payment schedule:';
							|it = 'Compilazione del documento di piano:';
							|pl = 'Wypełnianie dokumentu planu:';
							|tr = 'Belge doldurma planı:'") + " " + String(Object.Ref);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.AdditionalResult = JobParameters.Property("FillInUsingFormula");
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	Result = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionPlan.FillInDocument",
		JobParameters,
		ExecutionParameters);
	
	StorageAddress = Result.ResultAddress;
	If JobParameters.Property("FillInUsingFormula") Then
		StorageAddressAdditional = Result.AdditionalResultAddress;
	Else 
		StorageAddressAdditional = "";
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure PrepareParametersForFillingInDocumentUsingFormula(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.ProductionPlan;
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("ActivePeriodStart",  Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodStart",   Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodEnd",    Object.PeriodEnding);
	JobParameters.Insert("NotOverridden",        True); // To redefine the text of the request skd_dolyadnalichiatovaranostatkah
	
	JobParameters.Insert("PlanType",                PlanType);
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("LineOfBusiness", LineOfBusiness);
	
	JobParameters.Insert("FillInUsingFormula",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.ProductionPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	JobParameters.Insert("FillInAssignmentInTabularForm",  FillInAssignmentInTabularForm);
	JobParameters.Insert("FillInBOMByPeriods", FillInBOMByPeriods);
	JobParameters.Insert("ProductionProcessType", Object.ProductionProcessType);
	JobParameters.Insert("BOMSelectionParameters", BOMSelectionParameters);
	
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	
	JobParameters.Insert("Filter",                   FilterIndicators);
	
	Array_SetNames = New Array();
	If JobParameters.Property("PopulateOperands") Then
		
		ArrayOfOperators = GetOperands(ThisObject);
		
		For Each Item In ArrayOfOperators Do
			Array_SetNames.Add(Item.Name);
		EndDo;
	
	EndIf; 
	JobParameters.Insert("Array_SetNames",       Array_SetNames);
	
	PopulatedTS = Object.ManufacturedProduct.Unload(New Structure("SemiFinishedProduct", False));
	If JobParameters.Property("FillingComposition") Then
		PopulatedTS.Clear();
		Array_SetNames = New Array();
		If JobParameters.ContentFillingVariant = "Formula" Then
			Array_SetNames = PlanningClientServer.OperandsOfTextFormula(JobParameters.Formula);
		Else
			Array_SetNames.Add(JobParameters.ContentFillingVariant);
		EndIf;
		JobParameters.Insert("ArrayOfFillsetNames", Array_SetNames);
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(
		JobParameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+JobParameters.UUID, 
		Settings);
	
EndProcedure 
	
&AtServer
Function PrepareParametersForFillingInReplacementDocument(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.ProductionPlan;
	FillingStatuses = Planning.GetFillInStatuses(Object.Scenario);
	
	JobParameters.Insert("Statuses",                 FillingStatuses);
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("OffsetPeriodStart",   Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodEnd",    Object.PeriodEnding);
	
	JobParameters.Insert("PlanType",                PlanType);
	JobParameters.Insert("Department",           Object.Department);
	
	JobParameters.Insert("FillInAssignmentInTabularForm", 
		Common.ObjectAttributeValue(Object.PlanProfile,"FillInAssignmentInTabularForm"));
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInForReplacement",   True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.ProductionPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	PopulatedTS = Object.ManufacturedProduct.Unload(New Structure("SemiFinishedProduct", False));
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndFunction

&AtServer
Procedure PrepareParametersForFillingInDocumentAccordingToFillingRule(JobParameters, CachedValues)

	If Object.UpdateAdd <> 0 Then
		CopyFromCrossTable(CachedValues, Object);
	EndIf;
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("ChangeResultTo",     Object.ChangeResultTo);
	JobParameters.Insert("RoundingPrecision",      Object.RoundingPrecision);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("BeginOfPeriod",           Object.BeginOfPeriod);
	JobParameters.Insert("PeriodEnding",        Object.PeriodEnding);
	
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInRule",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.ProductionPlan");
	
	JobParameters.Insert("FillInBOMByPeriods", FillInBOMByPeriods);
	JobParameters.Insert("ProductionProcessType", Object.ProductionProcessType);
	JobParameters.Insert("BOMSelectionParameters", BOMSelectionParameters);
	
	PopulatedTS = Object.ManufacturedProduct.Unload(New Structure("SemiFinishedProduct", False));
	If Object.UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	If Not FilterIs_Specified Then
		FilterParameters = FilterParameters(ThisForm);
		PlanViewParameters = PlanViewParameters(ThisForm);	
		FilterValues = PlanningClientServer.SelectionForSampling(FilterParameters, PlanViewParameters);
		JobParameters.Insert("Filter", FilterValues);
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillingRule", GetFromTempStorage(FillingRuleAddress));
	Settings.Insert("UserSettings", GetFromTempStorage(CustomSettingsAddress));
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(
		JobParameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+JobParameters.UUID, 
		Settings);
	
EndProcedure 

&AtServer
Function GetResultOfFillingOnServer(CachedValues, FillingSemiFinishedProducts = False)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.ProductionPlan.Forms.DocumentForm.GetResultOfFillingOnServer");
	
	Table = GetFromTempStorage(StorageAddress);
	
	ProcessedRowsCount = Table.Count();
	
	Object.ManufacturedProduct.Load(Table);
	
	NewBeginningOfPeriod = Object.BeginOfPeriod;
	OperationsCount = 0;
		
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.ManufacturedProduct,
		StructureOfActions,
		CachedValues);
		
	For Each RowOfProduct In Object.ManufacturedProduct Do
		
		OperationsCount = OperationsCount + 1;
		
		If RowOfProduct.SemiFinishedProduct // There are no PF during disassembly
			And ValueIsFilled(RowOfProduct.DateOfProduction) 
			And RowOfProduct.DateOfProduction < Object.BeginOfPeriod Then
			
			NewBeginningOfPeriod = Min(NewBeginningOfPeriod, RowOfProduct.DateOfProduction);
			
		EndIf; 
		
	EndDo; 
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement,
		OperationsCount/10,
		"ProcessingTSStrings");
	
	If FillInTheSpecification And NewBeginningOfPeriod < Object.BeginOfPeriod Then
		
		Object.BeginOfPeriod = NewBeginningOfPeriod;
		WhenChangingPeriodsOnServer(True);
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đầu kỳ kế hoạch được điều chỉnh tự động cho các giai đoạn bán thành phẩm.';
				|ru = 'Начало периода плана скорректировано автоматически по периодам полуфабрикатов.';
				|en = 'Plan period start is corrected automatically by semi-finished product periods.'; fa = 'Plan period start is corrected automatically by semi-finished product periods.';
				|it = 'L''inizio del periodo del piano è stato rettificato automaticamente per i periodi dei prodotti semilavorati.';
				|pl = 'Początek okresu skorygowanego planu jest automatycznie dostosowywany do okresów półproduktu.';
				|tr = 'Dönem başlangıç planı yarı mamul ürünlerin dönemine göre otomatik olarak düzeltildi'"),
			Object.Ref,
			"Obkt.BeginOfPeriod");
		
	EndIf;
	
	FillInProductLaunchDates();
	
	// Formation of an array of periods in which the remainder plans were introduced
	PlannedBalanceIsUsed = Table.Columns.Find("PlannedStartBalance") <> Undefined
		And Not FillingSemiFinishedProducts;
	PlannedBalancesWithSelectionAreUsed = Table.Columns.Find("PlannedStartBalanceWithSelection") <> Undefined
		And Not FillingSemiFinishedProducts;
		
	If PlannedBalanceIsUsed Then
		
		BalancePlansPeriods.Clear();
		BalancePlanPeriodsWithSelection.Clear();
		
		For Each String In Table Do
			If String.PlannedStartBalance<>0 Then
				If BalancePlansPeriods.FindByValue(String.DateOfProduction) = Undefined Then
					BalancePlansPeriods.Add(String.DateOfProduction);
				EndIf;
			EndIf;
			
			If PlannedBalancesWithSelectionAreUsed
				And String.PlannedStartBalanceWithSelection<>0 Then
				If BalancePlanPeriodsWithSelection.FindByValue(String.DateOfProduction) = Undefined Then
					BalancePlanPeriodsWithSelection.Add(String.DateOfProduction);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the period table to calculate planned balances
	If ValueIsFilled(StorageAddressAdditional)
		And GetFromTempStorage(StorageAddressAdditional) <> Undefined Then
		TablePeriods = GetFromTempStorage(StorageAddressAdditional);
	Else
		TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	EndIf;
	
	UpdateCrossTableStructure(TablePeriods, False);
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement,
		ThisForm.GetAttributes("ProductsByDate").Count()/10,
		"UpdateCrossTableStructure");
	
	CopyToCrossTable(CachedValues);
	
	Object.FilledAutomatically = True;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	FillInSpecificationInProductLines(,True,FillingSemiFinishedProducts);
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(Enums.ItemsTypes.Work_5);
	If Object.CrossTable Or PlannedBalanceIsUsed  Then
		ManufacturedProduct = ProductsByDate;
	Else
		ManufacturedProduct = Object.ManufacturedProduct;
	EndIf; 
	
	IndexOf = ManufacturedProduct.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf -1;
		TSRow = ManufacturedProduct[IndexOf];
		If FilterByProductType.Find(TSRow.ItemsType) = Undefined
			Or (SettingsStructure.FilterByAvailabilityOfBOM And TSRow.BillOfMaterials.IsEmpty()) Then
			ManufacturedProduct.Delete(IndexOf);
		EndIf; 
	EndDo;
	
	ThereAreSemiFinishedProducts = ManufacturedProduct.FindRows(New Structure("SemiFinishedProduct", True)).Count() > 0;
	
	ValuesHaveBeenRecalculated = False;
	If Object.FillInUsingFormula
		And SettingsStructure <> Undefined
		And (PlannedBalanceIsUsed
		Or (Object.CrossTable 
		And (StrFind(SettingsStructure.Formula,"CurrentColumnNumber") <> 0
		Or StrFind(SettingsStructure.Formula,"ColumnValue") <> 0))) Then
		
		ValuesHaveBeenRecalculated = True;
		ProcessFillingResultUsingFormula(ThisForm);
		
	ElsIf SettingsStructure.FilterEmptyLines Then
		
		LinesToDelete = New Array;
		
		For Each RowOfGoods In ManufacturedProduct Do
			If RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
		EndDo;

		For Each RowToDelete In LinesToDelete Do
			ManufacturedProduct.Delete(RowToDelete);
		EndDo;
		
	EndIf;
	
	If Not Object.CrossTable And PlannedBalanceIsUsed Then
		CopyFromCrossTable(CachedValues, Object);
	EndIf;
	
	If Not Object.CrossTable Or ValuesHaveBeenRecalculated Then
		CalculateTotals_(ThisForm);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	PlannedBalanceIsUsed = False;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedRowsCount/10);
	
EndFunction

&AtClient
Procedure FillInDocumentAnswerToQuestion(Result, Settings) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		Settings.Insert("PlanningSemiFinishedProducts", True);
		
		FillInDocumentCompletion(Settings);
	
	ElsIf Result = DialogReturnCode.No Then
	
		If Settings.Property("PlanningSemiFinishedProducts") Then
			Settings.Delete("PlanningSemiFinishedProducts")
		EndIf; 
		
		FillInDocumentCompletion(Settings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDocumentCompletion(Settings)
	
	NotifyUserAboutStartOfFillingInData(); 
	
	SemiFinishedProductsWerePlanned = ThereAreSemiFinishedProducts;
	
	Result = FillInDocumentOnServer(Settings, CachedValues);
	
	If Not Result.Status = "Completed2" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("FillInNotificationDocument", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	Else
		GetResultOfFillingOnServer(CachedValues);
		If Object.FillInUsingFormula
			And Object.CrossTable Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(
				ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
		EndIf;
		
		NotifyUserAboutFillingInData();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInNotificationDocument(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		Try
			GetResultOfFillingOnServer(CachedValues);
			If Object.FillInUsingFormula
				And Object.CrossTable Then
				PlanningClientServer.DisplayValueOfAdditionalParameters(
					ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
			EndIf;
			
			SetSemiFinishedProductAlert(ThisObject, False);
			NotifyUserAboutFillingInData();
		Except
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareParametersForFillingDocumentWithSemiFinishedProducts(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("BeginOfPeriod",           Object.BeginOfPeriod);
	
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	
	JobParameters.Insert("PlanningSemiFinishedProducts", True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.ProductionPlan");
	
	JobParameters.Insert("FillInBOMByPeriods", FillInBOMByPeriods);
	JobParameters.Insert("ProductionProcessType", Object.ProductionProcessType);
	JobParameters.Insert("BOMSelectionParameters", BOMSelectionParameters);
	
	JobParameters.Insert("ProductionManagement2_2", Object.ProductionManagement2_2);
	
	JobParameters.Insert("Scenario",                             Object.Scenario);
	JobParameters.Insert("DemandForMaterials", Object.DemandForMaterials);
	JobParameters.Insert("TransferDemandOfBusinesUnitsThroughTransfers", Common.ObjectAttributeValue(Object.PlanProfile, "TransferDemandOfBusinesUnitsThroughTransfers"));
	
	PopulatedTS = Object.ManufacturedProduct.Unload(New Structure("SemiFinishedProduct", False));
	
	Settings = New Structure;
	If JobParameters.Property("FillInRule") Then
		Settings.Insert("FillingRule", GetFromTempStorage(FillingRuleAddress));
		Settings.Insert("UserSettings", GetFromTempStorage(CustomSettingsAddress));
	EndIf;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(
		JobParameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+JobParameters.UUID, 
		Settings);
	
EndProcedure 

&AtClient
Procedure PlanSemiFinishedProducts_3Completion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		ScheduleSemiFinishedProductsOnClient();
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure ScheduleSemiFinishedProductsOnClient()
	
	NotifyUserAboutStartOfFillingInData(); 
	
	Settings = New Structure;
	Settings.Insert("PlanningSemiFinishedProducts", True);
	
	Result = FillInDocumentOnServer(Settings, CachedValues);
	
	If Not Result.Status = "Completed2" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("ScheduleSemiFinishedProductsNotification", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	Else
		GetResultOfFillingSemiFinishedProductsCompletion();
		NotifyUserAboutFillingInData();
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduleSemiFinishedProductsNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		Try
			GetResultOfFillingOnServer(CachedValues, True);
			If Object.FillInUsingFormula
				And Object.CrossTable Then
				PlanningClientServer.DisplayValueOfAdditionalParameters(
					ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
			EndIf;
			NotifyUserAboutFillingInData();
		Except
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtClient
Procedure GetResultOfFillingSemiFinishedProductsCompletion()
	
	NewBeginningOfPeriod = Undefined;
		
	If ThereIsPeriodChangeWhenFillingSemiFinishedProducts(NewBeginningOfPeriod, CachedValues) Then
	
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Thay đổi kỳ và thêm bán thành phẩm';
												|ru = 'Изменить периоды и добавить полуфабрикаты';
												|en = 'Change periods and add semi-finished products'; fa = 'Change periods and add semi-finished products';
												|it = 'Modificare i periodi e aggiungere prodotti semilavorati';
												|pl = 'Zmień okresy i dodaj półprodukty';
												|tr = 'Dönemleri değiştir ve yarı mamul ürünleri ekle'"));
		Buttons.Add(DialogReturnCode.Cancel);
		QueryText = NStr("vi = 'Để thêm các hàng hóa bán thành phẩm, bạn phải thay đổi thời gian lập kế hoạch từ %BeginOfPeriod% đến %PeriodEnding%. Thay đổi thời gian?';
						|ru = 'Для добавления полуфабрикатов необходимо изменить период планирования с %BeginOfPeriod% по %PeriodEnding%. Изменить период?';
						|en = 'To add semi-finished products, change the planning period from %BeginOfPeriod% to %PeriodEnding%. Change the period?'; fa = 'To add semi-finished products, change the planning period from %BeginOfPeriod% to %PeriodEnding%. Change the period?';
						|it = 'Per aggiungere i prodotti semilavorati, è necessario modificare il periodo di pianificazione da %BeginOfPeriod% a %PeriodEnding%. Modificare periodo?';
						|pl = 'Aby dodać półprodukty, należy zmienić okres planowania od %BeginOfPeriod% do %PeriodEnding%. Zmień okres?';
						|tr = 'Yarı mamul ürünlerin eklenmesi için planlama dönemini %BeginOfPeriod%''dan %PeriodEnding%''a değiştirmek şart. Dönem değiştirilsin mi?'");
		QueryText = StrReplace(QueryText, "%BeginOfPeriod%", Format(NewBeginningOfPeriod, "DLF=D"));
		QueryText = StrReplace(QueryText, "%PeriodEnding%", Format(Object.PeriodEnding, "DLF=D"));
		
		AdditionalParameters = New Structure("NewBeginningOfPeriod", NewBeginningOfPeriod);
		Notification = New CallbackDescription("GetResultOfFillingSemiFinishedProductsCompletionCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
	Else
		GetResultOfFillingOnServer(CachedValues, True);	
	EndIf;
	
	SetSemiFinishedProductAlert(ThisObject, False);
	
EndProcedure

&AtServer
Function ThereIsPeriodChangeWhenFillingSemiFinishedProducts(NewBeginningOfPeriod, CachedValues)

	Table = GetFromTempStorage(StorageAddress);
	
	FoundRows = Table.FindRows(New Structure("SemiFinishedProduct", True));
	
	If FoundRows.Count() = 0 Then
	
		Return False;
	
	Else
		
		NewBeginningOfPeriod = Object.BeginOfPeriod;
		
		For Each FoundRow In FoundRows Do
		
			If ValueIsFilled(FoundRow.DateOfProduction) And FoundRow.DateOfProduction < Object.BeginOfPeriod Then
			
				NewBeginningOfPeriod = Min(NewBeginningOfPeriod, FoundRow.DateOfProduction);
			
			EndIf; 
			
		EndDo; 
		
		If NewBeginningOfPeriod < Object.BeginOfPeriod Then
			
			NewBeginningOfPeriod = PlanningClientServer.CalculateStartDateOfPeriod(NewBeginningOfPeriod, Object.Periodicity);
			Return True;
		
		EndIf; 
	
	EndIf;
	
	GetResultOfFillingOnServer(CachedValues, True);
	
	Return False;

EndFunction
 
&AtClient
Procedure GetResultOfFillingSemiFinishedProductsCompletionCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		GetResultOfFillingSemiFinishedProductsOnServer(AdditionalParameters.NewBeginningOfPeriod, CachedValues);
		SetSemiFinishedProductAlert(ThisObject, False);
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure GetResultOfFillingSemiFinishedProductsOnServer(NewBeginningOfPeriod, CachedValues)
	
	Object.BeginOfPeriod = PlanningClientServer.CalculateStartDateOfPeriod(NewBeginningOfPeriod, Object.Periodicity);
	WhenChangingPeriodsOnServer();
	GetResultOfFillingOnServer(CachedValues, True);
	
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Procedure SetSemiFinishedProductAlert(Form, NeedToReschedule)
	
	Form.Items.SemiFinishedProductsNotificationGroup.Visible = NeedToReschedule
		And Form.FillInTheSpecification
		And Form.ThereAreSemiFinishedProducts
		And Not Form.PlanSemiFinishedProductsAutomatically;
	
EndProcedure

&AtServer
Procedure DeleteSemiFinishedProductsOnServer()
	
	If Object.CrossTable Then
		ManufacturedProduct = ProductsByDate;
	Else
		ManufacturedProduct = Object.ManufacturedProduct;
	EndIf; 
	
	FoundRows = ManufacturedProduct.FindRows(New Structure("SemiFinishedProduct", True));
	
	For Each TSRow In FoundRows Do
	
		ManufacturedProduct.Delete(TSRow);
	
	EndDo;
	
	SemiFinishedProductsByDate.Clear();
	AllSemiFinishedProductsByDate.Clear();
	
	ThereAreSemiFinishedProducts = ManufacturedProduct.FindRows(New Structure("SemiFinishedProduct", True)).Count() > 0;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtServer
Procedure DeleteBlankLinesOnServer()
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	
	ItIsNecessaryToRecalculateResults = False;
	
	IndexOf =  ProductsByDate.Count() -1;
	
	While IndexOf >= 0 Do
	
		TSRow = ProductsByDate[IndexOf];
		
		If TSRow.NumberOfPackages <> 0 Then
			IndexOf = IndexOf - 1;
			Continue;
		EndIf; 
		
		IsBlankRow = True;
		
		For Each Period In ActivePeriods Do
		
			If TSRow["Count_"+Period.ColumnName] <> 0 Then
			
				IsBlankRow = False;
				Break;
			
			EndIf; 
		
		EndDo; 
		
		If IsBlankRow Then
		
			ProductsByDate.Delete(IndexOf);
			ItIsNecessaryToRecalculateResults = True;
		
		EndIf; 
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	If ItIsNecessaryToRecalculateResults Then
	
		CalculateTotals_(ThisForm, False);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure OutputByDateWhenActivatingCellOnClient()
	
	If Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductsByDate");
	EndIf;
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	CurrentData = Items.ProductsByDate.CurrentData;
	
	If ActivePeriods.Count() = 1 Then
		If Not Object.FillInUsingFormula And CurrentData <> Undefined Then
			Details = PlanningClient.GenerateDecryption(CurrentData, "Details_" + ActivePeriods[0].ColumnName);
		EndIf;
		Return;
	EndIf;
	
	CellIsCanceled = False;
	CellComment = "";
	CellFound = False;
	
	If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
		Item = Items.SemiFinishedProductsByDate;
		ElementsCellCanceled = Items.CellIsCanceled1;
		CellCommentElements = Items.CellComment1;
		ProductionField = "SemiFinishedProductsByDateQuantity_";
	Else
		Item = Items.ProductsByDate;
		ElementsCellCanceled = Items.CellIsCanceled;
		CellCommentElements = Items.CellComment;
		ProductionField = "ProductsByDate" + "Count_";
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined 
		Or (CurrentData.SemiFinishedProduct
		And Items.GroupPerformanceProducts.CurrentPage <> Items.GroupSemiFinishedProductsCrossTable) Then
		ElementsCellCanceled.Enabled = CellFound;
		CellCommentElements.Enabled = CellFound;
		Return;
	EndIf; 
	
	If Item.CurrentItem <> Undefined Then
		For Each Period In ActivePeriods Do
			If Item.CurrentItem.Name = ProductionField+Period.ColumnName Then
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				If Not Object.FillInUsingFormula And CurrentData["Count_"+ Period.ColumnName] <> 0 Then
					Details = PlanningClient.GenerateDecryption(CurrentData, "Details_"+ Period.ColumnName);
				Else
					Details = "";
				EndIf;
				CellFound = True;
				Break;
			Else
				Details = "";
			EndIf;
		EndDo;
	EndIf;
	
	ElementsCellCanceled.Enabled = CellFound;
	CellCommentElements.Enabled = CellFound;

EndProcedure

&AtServer
Procedure BackToProductionOnServer()
	
	Filter = New Structure("Products, Characteristic, Purpose, BillOfMaterials");
	FillPropertyValues(Filter, SemiFinishedProductsByDate[0]);
	
	LinesToDelete = AllSemiFinishedProductsByDate.FindRows(Filter);
	For Each RowToDelete In LinesToDelete Do
		AllSemiFinishedProductsByDate.Delete(RowToDelete);
	EndDo;
	
	For Each String In SemiFinishedProductsByDate Do
		NewRow = AllSemiFinishedProductsByDate.Add();
		FillPropertyValues(NewRow, String);
	EndDo;

	Filter.Insert("SemiFinishedProduct", True);
	StringSemiFinishedProduct = ProductsByDate.FindRows(Filter)[0];
	
	StringSemiFinishedProduct.Count = 0;
	For Each PeriodString_ In ThisForm.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		StringSemiFinishedProduct["Count_" + PeriodString_.ColumnName] = 0;
		For Each String In SemiFinishedProductsByDate Do
			
			If String["Canceled_" + PeriodString_.ColumnName] Then
				Continue;
			EndIf;
			
			StringSemiFinishedProduct["Count_" + PeriodString_.ColumnName] = StringSemiFinishedProduct["Count_" + PeriodString_.ColumnName] + String["Count_" + PeriodString_.ColumnName];
			StringSemiFinishedProduct.Count = StringSemiFinishedProduct.Count + String["Count_" + PeriodString_.ColumnName];
			
		EndDo;
		
	EndDo;
	StringSemiFinishedProduct.NumberOfPackages = StringSemiFinishedProduct.Count;
	
	Items.GroupPerformanceProducts.CurrentPage = Items.GroupProductsCrossTable;

EndProcedure

&AtServer
Procedure OutputByDateSelectionOnServer(Filter)
	
	SemiFinishedProductsByDate.Load(AllSemiFinishedProductsByDate.Unload(Filter));
	
	Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable;
	
EndProcedure

&AtServer
Procedure FillInDeficitPlansOnServer(CachedValues)
	
	FlowingObject = FormAttributeToValue("Object");
	Planning.FillOutDeficitPlans(Object.Scenario,
		Object.PlanProfile,
		Object.BeginOfPeriod,
		Object.PeriodEnding,
		FlowingObject);
	ValueToFormData(FlowingObject, Object);
	
	OperationsCount = 0;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.ManufacturedProduct,
		StructureOfActions,
		CachedValues);
		
	For Each RowOfProduct In Object.ManufacturedProduct Do
		
		OperationsCount = OperationsCount + 1;
		
		If RowOfProduct.SemiFinishedProduct // There are no PF during disassembly
			And ValueIsFilled(RowOfProduct.DateOfProduction) 
			And RowOfProduct.DateOfProduction < Object.BeginOfPeriod Then
			
			NewBeginningOfPeriod = Min(NewBeginningOfPeriod, RowOfProduct.DateOfProduction);
			
		EndIf; 
		
	EndDo; 
	
	FillInSpecificationInProductLines(,True);
	
	FillInProductLaunchDates();
	
	FillInServiceDetails();
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(Enums.ItemsTypes.Work_5);
	
	ManufacturedProduct = Object.ManufacturedProduct;
	IndexOf = ManufacturedProduct.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf -1;
		TSRow = ManufacturedProduct[IndexOf];
		If FilterByProductType.Find(TSRow.ItemsType) = Undefined Then
			ManufacturedProduct.Delete(IndexOf);
		EndIf; 
	EndDo;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

#EndRegion

#Region PlanSubstitution

&AtClientAtServerNoContext
Function ReplaceParameters(Val Object)

	ReplaceParameters = New Structure;
	
	ReplaceParameters.Insert("Ref", Object.Ref);
	ReplaceParameters.Insert("PlanProfile", Object.PlanProfile);
	ReplaceParameters.Insert("Status", Object.Status);
	ReplaceParameters.Insert("Date", Object.Date);
	ReplaceParameters.Insert("SubstitutionPeriodStart", Object.SubstitutionPeriodStart);
	ReplaceParameters.Insert("PeriodEnding", Object.PeriodEnding);
	ReplaceParameters.Insert("Periodicity", Object.Periodicity);
	
	ReplaceParameters.Insert("Department", Object.Department);
	ReplaceParameters.Insert("Purpose", Object.Purpose);
	
	Return ReplaceParameters
	
EndFunction

&AtServer
Procedure UpdateReplacementAttribute()
	
	For Each String In Object.ManufacturedProduct Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	If Not Object.Substitutional Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	SubstitutedPeriods.SubstitutedPeriod AS SubstitutedPeriod,
	|	SubstitutedPeriods.SubstitutedToOrder AS SubstitutedToOrder,
	|	SubstitutedPeriods.Substituted AS Substituted
	|INTO SubstitutedPeriods
	|FROM
	|	&SubstitutedPeriods AS SubstitutedPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&DateOfOrderReleaseAndProductionIssue AS Date,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, YEAR)
	|		ELSE &DateOfOrderReleaseAndProductionIssue
	|	END AS Period,
	|	ManufacturedProduct.SemiFinishedProduct AS SemiFinishedProduct,
	|	ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct AS ReleaseDateOfProductsOrSemiFinishedProduct,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, YEAR)
	|		ELSE ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct
	|	END AS SemiFinishedProductProductionPeriod
	|INTO ManufacturedProduct
	|FROM
	|	&ManufacturedProduct AS ManufacturedProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManufacturedProduct.Date AS Date,
	|	ManufacturedProduct.Period AS Period,
	|	ManufacturedProduct.SemiFinishedProduct AS SemiFinishedProduct
	|INTO ProductsAssociation
	|FROM
	|	ManufacturedProduct AS ManufacturedProduct
	|WHERE
	|	NOT ManufacturedProduct.SemiFinishedProduct
	|
	|UNION ALL
	|
	|SELECT
	|	ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct,
	|	ManufacturedProduct.SemiFinishedProductProductionPeriod,
	|	ManufacturedProduct.SemiFinishedProduct
	|FROM
	|	ManufacturedProduct AS ManufacturedProduct
	|WHERE
	|	ManufacturedProduct.SemiFinishedProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductsAssociation.Date AS Date,
	|	MAX(SubstitutedPeriods.SubstitutedToOrder) AS SubstitutedToOrder,
	|	MAX(SubstitutedPeriods.Substituted) AS Substituted,
	|	ProductsAssociation.SemiFinishedProduct AS SemiFinishedProduct
	|FROM
	|	SubstitutedPeriods AS SubstitutedPeriods
	|		INNER JOIN ProductsAssociation AS ProductsAssociation
	|		ON SubstitutedPeriods.SubstitutedPeriod = ProductsAssociation.Period
	|
	|GROUP BY
	|	ProductsAssociation.Date,
	|	ProductsAssociation.SemiFinishedProduct";
	
	QueryText = StrReplace(QueryText,
		"&DateOfOrderReleaseAndProductionIssue",
		?(ThisIsDisassembly, "ManufacturedProduct.StartDate2", "ManufacturedProduct.DateOfProduction"));
	
	Query = New Query(QueryText);
	
	Query.SetParameter("SubstitutedPeriods", SubstitutedPeriods.Unload());
	Query.SetParameter("ManufacturedProduct", Object.ManufacturedProduct.Unload());
	Query.SetParameter("Periodicity", Object.Periodicity);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("SemiFinishedProduct", Selection.SemiFinishedProduct);
		
		If Selection.SemiFinishedProduct Then
			TheStructureOfTheSearch.Insert("ReleaseDateOfProductsOrSemiFinishedProduct", Selection.Date);
		Else
			TheStructureOfTheSearch.Insert(?(ThisIsDisassembly, "StartDate2", "DateOfProduction"), Selection.Date);
		EndIf;
		
		ReplacementLines = Object.ManufacturedProduct.FindRows(TheStructureOfTheSearch);
		For Each String In ReplacementLines Do
			String.Substituted = Selection.Substituted;
			String.SubstitutedToOrder = Selection.SubstitutedToOrder;;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function FillInSubstitutedPeriods()
	
	ReplaceParameters = ReplaceParameters(Object);
	Result = Planning.GetSubstitutedPeriods(ReplaceParameters, "ProductionPlan", "SubstitutionPeriodStart");
	
	SubstitutedPeriods.Load(Result);
	
EndFunction

&AtClient
Procedure SubstitutionFormattedLineURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	FormParameters = ReplaceParameters(Object);
	FormParameters.Insert("FormattedStringURL", FormattedStringURL);
	
	OpenForm("InformationRegister.PlanSubstitution.Form.PlanSubstitution", FormParameters);
EndProcedure

&AtServerNoContext
Function PlanReplacementControlOnServer(Ref)
	
	Return Planning.PlanReplacementControl(Ref);
	
EndFunction

&AtServer
Procedure UpdateBeginningOfReplacementPeriod()
	
	QueryText = 
		"SELECT
		|	ManufacturedProduct.SemiFinishedProduct AS SemiFinishedProduct,
		|	&DateOfOrderReleaseAndProductionIssue AS Date,
		|	ManufacturedProduct.Count AS Count
		|INTO ManufacturedProduct
		|FROM
		|	&ManufacturedProduct AS ManufacturedProduct
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	ManufacturedProduct.Date AS Date
		|FROM
		|	ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	NOT ManufacturedProduct.SemiFinishedProduct
		|	AND ManufacturedProduct.Date >= &BeginOfPeriod
		|
		|ORDER BY
		|	Date";
	
	QueryText = StrReplace(QueryText,
		"&DateOfOrderReleaseAndProductionIssue",
		?(ThisIsDisassembly, "ManufacturedProduct.StartDate2", "ManufacturedProduct.DateOfProduction"));
	
	Query = New Query(QueryText);
	
	Query.SetParameter("ManufacturedProduct", Object.ManufacturedProduct.Unload());
	Query.SetParameter("BeginOfPeriod",Object.BeginOfPeriod);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Object.SubstitutionPeriodStart = Selection.Date;
	Else
		Object.SubstitutionPeriodStart = Object.BeginOfPeriod;
	EndIf;
	
	Object.SubstitutionPeriodStart = PlanningClientServerCached.CalculateStartDateOfPeriod(Object.SubstitutionPeriodStart, Object.Periodicity);
	
EndProcedure

#EndRegion

#Region AdjustmentsToPlannedDemands

&AtClient
Procedure DecorationCanceledNeedsAdjustmentsClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("ShowAssignment", Items.ManufacturedProductPurpose.Visible);
	FormParameters.Insert("Filter", New Structure("Plan", Object.Ref));
	
	OpenForm(
		"Document.AdjustmentOfPlannedDemand.Form.ListForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure DecorationCanceledAdjustmentsNeedsToBeCheckedClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("ShowAssignment", Items.ManufacturedProductPurpose.Visible);
	FormParameters.Insert("Filter", New Structure("Plan", Object.Ref));
	FormParameters.Insert("Status", PredefinedValue("Enum.StatusesOfPlanAdjustments.ForChecking"));
	
	OpenForm(
		"Document.AdjustmentOfPlannedDemand.Form.ListForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustDemand(Command)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	
	FillingData.Insert("Plan", Object.Ref);
	FillingData.Insert("Scenario", Object.Scenario);
	FillingData.Insert("PlanProfile", Object.PlanProfile);
	FillingData.Insert("Period", Object.BeginOfPeriod);
	FillingData.Insert("Products", CurrentRow.Products);
	FillingData.Insert("Characteristic", CurrentRow.Characteristic);
	FillingData.Insert("Purpose", CurrentRow.Purpose);
	FillingData.Insert("Count", CurrentRow.Count);
	
	FormParameters = New Structure("FillingData", FillingData);
	OpenForm("Document.AdjustmentOfPlannedDemand.Form.DocumentForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure AdjustDemandCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Modified = True;
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	CurrentRow.Count = AdditionalParameters.ToSupply;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, New Structure("RecalculateNumberOfPackages"), CachedValues);
	
	Items.ManufacturedProduct.RowInputMode = TableRowInputMode.AfterCurrentRow;
	
	If ValueIsFilled(AdditionalParameters.NomenclatureAdjustment)
		And AdditionalParameters.ToEnsureTheAdjustment > 0 Then
		FilterParameters = New Structure();
		FilterParameters.Insert("Products", AdditionalParameters.NomenclatureAdjustment);
		FilterParameters.Insert("Characteristic", AdditionalParameters.FeatureAdjustment);
		FilterParameters.Insert("Purpose", AdditionalParameters.PurposeAdjustment);
		
		AdjustmentLines = Object.ManufacturedProduct.FindRows(FilterParameters);
		
		If AdjustmentLines.Count()>0 Then
			AdjustmentLines[0].Count = AdditionalParameters.ToEnsureTheAdjustment;
			BatchProcessingOfTablePartClient.ProcessTSString(AdjustmentLines[0], New Structure("RecalculateNumberOfPackages"), CachedValues);
		Else
			NewRow = Object.ManufacturedProduct.Add();
			NewRow.Products = AdditionalParameters.NomenclatureAdjustment;
			NewRow.Characteristic = AdditionalParameters.FeatureAdjustment;
			NewRow.Purpose = AdditionalParameters.PurposeAdjustment;
			NewRow.Count = AdditionalParameters.ToEnsureTheAdjustment;
			NewRow.NumberOfPackages = NewRow.Count;
			NewRow.DateOfProduction = AdditionalParameters.Period;
			ProductsProductListWhenChangedOnServer(NewRow.GetID(), CachedValues);	
		EndIf;
	EndIf;
	
	Items.ManufacturedProduct.RowInputMode = TableRowInputMode.EndOfList;
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

#EndRegion
#Region Substitutes

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TableName = "ManufacturedProduct";
	
	If Items[TableName].SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn (các) dòng';
								|ru = 'Необходимо выделить строку(и)';
								|en = 'Highlight the line(s)'; fa = 'Highlight the line(s)';
								|it = 'È necessario evidenziare la riga (le righe)';
								|pl = 'Należy zaznaczyć wiersz(e)';
								|tr = 'Satır(lar) vurgulanmalıdır'"));
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TableName, 1), ThisForm);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(AddressInStorage)
	
	AdditionalFields_ = "Purpose, DateOfProduction";
	
	Result = AlternativeMaterials.PerformReplacementForAnalogues(
		?(Object.CrossTable, ProductsByDate, Object.ManufacturedProduct), AddressInStorage, AdditionalFields_);
		
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;

	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count();
	MessageText  = StrTemplate(NStr("vi = 'Dòng được thay đổi: %1';
									|ru = 'Измененных строк: %1';
									|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
									|it = 'Измененных строк: %1';
									|pl = 'Changed lines: %1';
									|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
	Common.MessageToUser(MessageText);

	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;
		
	NewlineIDs_ = New Array;
	For Each RowIndex In IndexesOfNewRows Do
		NewlineIDs_.Add(Object.ManufacturedProduct[RowIndex].GetID());
	EndDo;
	FillInSpecificationInProductLines(NewlineIDs_);
	
	If Object.Posted Then
		GenerateAdjustmentsToPlannedNeeds(AddressInStorage, IndexesOfNewRows);
	EndIf;
	
	Modified = True;
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductsByDate");
		GoodsLineQuantity = ProductsByDate.Count();
	Else
		GoodsLineQuantity = Object.ManufacturedProduct.Count();
	EndIf;
	
	FillInServiceDetails();
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
		
EndProcedure

// Generates parameters for selecting analogs
//
// Parameters:
//	TableName - String - Name of the table to be processed
//	Mode      - Number  - 0-show analogs
//                        1 - choose the analogues
//                        2-replace with analogs
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters(TableName, Mode)

	SourceType = New TypeDescription("DocumentRef.ProductionPlan");
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", New TypeDescription("DocumentRef.ProductionPlan"));
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	FieldsStructure.DefaultValues.Insert("Warehouse");
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", New Array);
	RowFilter.Canceled.Add(False);
	
	DocumentTable = Object[TableName]; // FormDataCollection
	
	ObjectTable = DocumentTable.Unload();
	ObjectTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	
	ObjectName = "Object";
	
	FormData1 = New Structure;
	FormData1.Insert("Items", Items);
	FormData1.Insert("UUID", UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TableName, ObjectTable.CopyColumns());
	
	For Each TableRow In ObjectTable Do
		
		TableRow.WithAssignment = ValueIsFilled(TableRow.Purpose);
		
		RowID = Object[TableName][TableRow.LineNumber - 1].GetID();
		
		If Items[TableName].SelectedRows.Find(RowID) = Undefined Then
			Continue;
		EndIf;
		
		DataTable = FormData1[ObjectName][TableName]; // ValueTable
		FillPropertyValues(DataTable.Add(), TableRow);
		
	EndDo;	
	
	AddlParameters = AlternativeMaterials.AdditionalParameters();
	AddlParameters.RowFilter     = RowFilter;
	AddlParameters.SourceOfResults = ObjectTable;
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, ObjectName, TableName, Mode, False, FieldsStructure, AddlParameters);
	
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);
	
	// SubstitutesParameters
	SubstitutesParameters = FormParameters.SubstitutesParameters; // See AlternativeMaterials.AnalogSelectionParameters
	ParametersTable = SubstitutesParameters.ParametersTable; 
	
	SelectedRows = Items[TableName].SelectedRows;
	CurrentRow = Object[TableName].FindByID(SelectedRows[0]);
	
	TableRow = ParametersTable.Add();
	TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
	TableRow.Ref = Object.Ref;
	TableRow.LineOfBusiness = 
		Common.ObjectAttributeValue(CurrentRow.Purpose, "LineOfBusiness", True);
			
	FormParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, UUID);
		
	FormParameters.SubstitutesParameters.Warehouse = Catalogs.Warehouses.EmptyRef();	
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure GenerateAdjustmentsToPlannedNeeds(AddressInStorage, IndexesOfNewRows)
	
	AdjustmentParameters = New Structure("EmployeeResponsible, Comment, Status, Scenario, PlanProfile, Plan, Period, AssigningAdjustment");
	FillPropertyValues(AdjustmentParameters, Object);
	
	AdjustmentParameters.Plan = Object.Ref;
	ReplacementString = Object.ManufacturedProduct.Get(IndexesOfNewRows[0]);
	AdjustmentParameters.AssigningAdjustment = ReplacementString.Purpose;
	AdjustmentParameters.Period = ReplacementString.DateOfProduction;
	If Not ValueIsFilled(AdjustmentParameters.Period) Then
		AdjustmentParameters.Period = Object.BeginOfPeriod;
	EndIf;
	
	Planning.GenerateAdjustmentsToPlannedNeeds(AddressInStorage, AdjustmentParameters);
	
EndProcedure

#EndRegion
#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ProductionPlan.ManufacturedProduct";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ""Thành phẩm"" từ tệp';
												|ru = 'Загрузка таблицы ""Продукция"" из файла';
												|en = 'Import the Manufactured products table from the file'; fa = 'Import the Manufactured products table from the file';
												|it = 'Scaricamento della tabella ""Prodotti"" dal file';
												|pl = 'Wczytywanie tabeli ""Produkcja"" z pliku';
												|tr = 'Dosyadan ""İmal edilen ürünler"" tablosunun indirilmesi'");
	ImportParameters.AdditionalParameters = AdditionalParameters;
	
	ImportParameters.TemplateColumns = PlanningClient.DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters);
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject, AdditionalParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Object.CrossTable Then
		CopyFromCrossTable(CachedValues, Object);
	EndIf;
	
	AddProducts_2(ImportedData, CachedValues, True);
	
	If Object.CrossTable Then
		
		ProductsByDate.Clear();
		
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "ManufacturedProduct");
		CheckParameters.Insert("PresentationOfTS",          TitleOfTablePart(Object.ProductionProcessType));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       ?(ThisIsDisassembly, "StartDate2", "DateOfProduction"));
		CheckParameters.Insert("PresentationOfPeriodDate", ?(ThisIsDisassembly, NStr("vi = 'Ngày vận hành';
																					|ru = 'Дата запуска';
																					|en = 'Launch date'; fa = 'تاریخ شروع';
																					|it = 'Data di avvio';
																					|pl = 'Data uruchomienia';
																					|tr = 'Başlangıç tarihi'"), NStr("vi = 'Ngày xuất xưởng';
																												|ru = 'Дата выпуска';
																												|en = 'Release date'; fa = 'تاریخ انتشار';
																												|it = 'Data di produzione';
																												|pl = 'Data wydania';
																												|tr = 'Çıkış tarihi'")));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		If Cancel Then
			Common.MessageToUser(StrTemplate(
				NStr("vi = 'Trong các dòng danh sách ""%1"" đã chỉ ra ngày ngoài biên lập kế hoạch - đã xóa các dòng.';
					|ru = 'В строках списка ""%1"" указаны даты за границами планирования - строки были удалены.';
					|en = 'Dates outside the planning fences are specified in lines of the %1 list. The lines were removed.'; fa = 'Dates outside the planning fences are specified in lines of the %1 list. The lines were removed.';
					|it = 'Nelle righe dell''elenco ""%1"" le date vanno oltre i limiti della pianificazione - le righe sono state eliminate.';
					|pl = 'W wierszach listy ""%1"" są podane daty poza granicami planowania - wiersze zostały usunięte.';
					|tr = '""%1"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silindi.'"),
				TitleOfTablePart(Object.ProductionProcessType)));
		EndIf; 
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
		
	EndIf;
	
	FillInSpecificationInProductLines(Undefined, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ProductsByDateProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "ProductsByDate.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SemiFinishedProductsByDateProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "SemiFinishedProductsByDate.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProduct.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "ProductsByDateCharacteristic",
																		     "ProductsByDate.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "SemiFinishedProductsByDateCharacteristic",
																		     "SemiFinishedProductsByDate.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "ManufacturedProductCharacteristic",
																		     "Object.ManufacturedProduct.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "ListOfSemiFinishedProductsCharacteristic",
																		     "ListOfSemiFinishedProducts.ItemVariantsAreUsed");
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"ProductsByDatePurpose",
																			"ProductsByDate.ItemsType",
																			False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"SemiFinishedProductsByDatePurpose",
																			"SemiFinishedProductsByDate.ItemsType",
																			False);
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"ManufacturedProductPurpose",
																			"ManufacturedProduct.ItemsType",
																			False);
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"ListOfSemiFinishedProductsPurpose",
																			"ListOfSemiFinishedProducts.ItemsType",
																			False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProduct.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProduct.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Substituted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProduct.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.SemiFinishedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsByDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.SemiFinishedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsByDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsByDate.SemiFinishedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductBillOfMaterials.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PlanStatuses.Upholded;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất không phù hợp';
													|ru = 'Спецификация не подобрана';
													|en = 'Bill of materials is not picked'; fa = 'Bill of materials is not picked';
													|it = 'Specifica non selezionata';
													|pl = 'Specyfikacja nie została dobrana';
													|tr = 'Ürün reçetesi seçilmedi'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsByDateBillOfMaterials.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PlanStatuses.Upholded;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất không phù hợp';
													|ru = 'Спецификация не подобрана';
													|en = 'Bill of materials is not picked'; fa = 'Bill of materials is not picked';
													|it = 'Specifica non selezionata';
													|pl = 'Specyfikacja nie została dobrana';
													|tr = 'Ürün reçetesi seçilmedi'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfSemiFinishedProductsToOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PlanStatuses.Upholded;

	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfCrossTable()
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	CurrentFont = Items.ProductsByDate.Font;
	StrikethroughFont = New Font(CurrentFont,,,,,,True);
	TextColorOfCanceledRowOfDocument = StyleColors.TextColorOfCanceledRowOfDocument;
	
	ActivePeriods = ThisObject["TimeIntervals"].FindRows(New Structure("Active_", True));
	ThisIsOnePeriod = ActivePeriods.Count() = 1;
	For Each Period In ActivePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf;
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("ProductsByDate" + "Count_"+Period.ColumnName);
		
		FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.Canceled_"+Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.SemiFinishedProduct");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("Font", StrikethroughFont);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("ProductsByDate" + "Count_"+Period.ColumnName);
		
		FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.Substituted_"+ Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductsByDate.SemiFinishedProduct");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", TextColorOfCanceledRowOfDocument);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("SemiFinishedProductsByDateQuantity_"+Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsByDate.Canceled_"+Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("Font", StrikethroughFont);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("SemiFinishedProductsByDateQuantity_"+Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsByDate.Substituted_"+ Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", TextColorOfCanceledRowOfDocument);
		
	EndDo;

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
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export 
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductsByDate", Notification);
	
EndProcedure

&AtServer
Procedure SaveNewPeriodServer()
	
	PlanningClientServer.SaveValuesOfVerifiedDetails(Object, ThisForm, "DetailsBeforeChange");
	
	CaptionFrequencyCurrency = NStr("vi = 'Định kỳ: %Periodicity%';
									|ru = 'Периодичность: %Periodicity%';
									|en = 'Time fence: %Periodicity%'; fa = 'Time fence: %Periodicity%';
									|it = 'Periodicità: %Periodicity%';
									|pl = 'Częstotliwość: %Periodicity%';
									|tr = 'Sıklık: %Periodicity%'");
	
	CaptionFrequencyCurrency = StrReplace(CaptionFrequencyCurrency,"%Periodicity%",String(Object.Periodicity));
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingAmountOfRowSum(Object, Form, RowOfGoods)

	Count = 0;
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Or RowOfGoods["Canceled_" + PeriodString_.ColumnName] Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.NumberOfPackages 	= Count;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form, CountLines = True, UpdateAllSemiFinishedProducts = False)

	Object = Form.Object;
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	If UpdateAllSemiFinishedProducts Then
		ManufacturedProduct = Form.AllSemiFinishedProductsByDate;
	ElsIf Form.Items.GroupPerformanceProducts.CurrentPage = Form.Items.GroupSemiFinishedProductsCrossTable Then
		ManufacturedProduct = Form.SemiFinishedProductsByDate;
	Else
		ManufacturedProduct = Form.ProductsByDate;
	EndIf;
	
	Form["NumberOfPackages"] = 0;
	
	PrefixOfQuantityColumn = "ProductsByDate" + "Count_";
	
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = 0;
		
	EndDo;
	
	For Each TSRow In ManufacturedProduct Do
		If CountLines Then
			TSRow.NumberOfPackages = 0;
		EndIf;
		
		PeriodReplaced_ = False;
		If Form.Items.GroupPerformanceProducts.CurrentPage = Form.Items.GroupSemiFinishedProductsCrossTable
			Or UpdateAllSemiFinishedProducts Then
			Filter = New Structure("StartDate", TSRow.ReleaseDateOfProductsOrSemiFinishedProduct);
			TimeIntervals = Form.TimeIntervals.FindRows(Filter);
			If TimeIntervals.Count()>0 Then
				PeriodReplaced_ = TimeIntervals[0].Substituted;
			EndIf;
		EndIf;
		
		For Each PeriodString_ In Form.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			
			If TSRow.SemiFinishedProduct Then
				TSRow["Substituted_"+ PeriodString_.ColumnName] = PeriodReplaced_;
			Else
				TSRow["Substituted_"+ PeriodString_.ColumnName] = PeriodString_.Substituted;
				TSRow["SubstitutedToOrder_"+ PeriodString_.ColumnName] = PeriodString_.SubstitutedToOrder;
			EndIf;
			
			If TSRow["Canceled_" + PeriodString_.ColumnName] Then
				Continue;
			EndIf;
			
			If CountLines Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + TSRow["Count_" + PeriodString_.ColumnName];
				
			EndIf;
			
			Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = Form[PrefixOfQuantityColumn 
				+ PeriodString_.ColumnName] 
				+ TSRow["Count_" + PeriodString_.ColumnName];
			
		EndDo;
		
		Form["NumberOfPackages"] = Form["NumberOfPackages"] + TSRow["NumberOfPackages"];
		
		PlanningClientServer.SetFormulaPresentation(Form, TSRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	EnterpriseManagement = GetFunctionalOption("EnterpriseManagement");
	
	If Object.FillInUsingFormula Then
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
	Else
		InitializeSettingsStructure(FormAttributeToValue("Object"));
	EndIf;
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	ProductionPlanCalculationStatusCodes = Documents.ProductionPlan.ProductionPlanCalculationStatusCodes();
	
	ScriptParameters_ = Common.ObjectAttributesValues(
		Object.Scenario,
		"ShowNumberOfPeriod, UseForMaterialsPlanning, PlanningByAssignments");
	FillPropertyValues(ThisForm, ScriptParameters_, "ShowNumberOfPeriod, PlanningByAssignments");
	
	FillInTheSpecification = ScriptParameters_.UseForMaterialsPlanning;
	ThisIsDisassembly = (Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly);
	
	WhenChangingPeriodsOnServer();
	
	CopyToCrossTable(Undefined);
	
	ThereAreSemiFinishedProducts = Object.ManufacturedProduct.FindRows(New Structure("SemiFinishedProduct", True)).Count() > 0;
	
	SetCrossTableTag(ThisForm);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProduct);
	
	ReadSetSpecificationSelectionParameters();
	AvailableProductTypes.LoadValues(ProductDataManagementClientServer.TypesOfItemsByTypeOfProductionProcess(Object.ProductionProcessType));
	ProductDataManagementClientServer.SetSelectionByItemType(Items.ManufacturedProductProducts, AvailableProductTypes.UnloadValues());
	ProductDataManagementClientServer.SetSelectionByItemType(Items.ProductsByDateProducts, AvailableProductTypes.UnloadValues());
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
				New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
				New Structure("Products", "SKU"));
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			ProductsByDate,
			StructureOfActions);
				
		ProductsServer.FillInServiceDetailsForProductInCollection(
			AllSemiFinishedProductsByDate,
			StructureOfActions);
				
		For Each TSRow In ProductsByDate Do
			For Each Period In ThisObject["TimeIntervals"] Do
				If Not Period.Active_ Then
					Continue;
				EndIf;
				TSRow["PictureComment_"+ Period.ColumnName] = ValueIsFilled(TSRow["Comment_"+ Period.ColumnName]);
			EndDo; 
		EndDo;
		
		For Each TSRow In AllSemiFinishedProductsByDate Do
			For Each Period In ThisObject["TimeIntervals"] Do
				If Not Period.Active_ Then
					Continue;
				EndIf;
				TSRow["PictureComment_"+ Period.ColumnName] = ValueIsFilled(TSRow["Comment_"+ Period.ColumnName]);
			EndDo; 
		EndDo;
		
		FillInDirectionOfActivity(ProductsByDate);
		
	Else
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.ManufacturedProduct,
			StructureOfActions);
		
		For Each TSRow In Object.ManufacturedProduct Do
			TSRow.PictureComment = ValueIsFilled(TSRow.Comment);
		EndDo;
		
		FillInDirectionOfActivity(New Array);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDirectionOfActivity(Rows)

	AssignmentsArray = New Array;
	
	AssignmentsArray.Add(Object.Purpose);
	For Each String In Rows Do
		AssignmentsArray.Add(String.Purpose);
	EndDo;
	
	AttributesValues = Common.ObjectsAttributeValue(AssignmentsArray, "LineOfBusiness");
	
	LineOfBusiness = AttributesValues[Object.Purpose];
	For Each String In Rows Do
		String.LineOfBusiness = AttributesValues[String.Purpose];
	EndDo;
	
EndProcedure

// The procedure fills the period table with dates to get the order and forms the fields of the cross-table.
&AtServer
Procedure WhenChangingPeriodsOnServer(AdjustStartEndOfPeriod = False, UpdateBeginningOfReplacementPeriod = False)
	
	If AdjustStartEndOfPeriod Then
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod,  Object.PeriodEnding, CurrentSessionDate());
	EndIf; 
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	If Object.Substitutional
		And ValueIsFilled(Object.Periodicity) Then
		
		If UpdateBeginningOfReplacementPeriod Then
			Object.SubstitutionPeriodStart = Object.BeginOfPeriod;
		EndIf;
		
		FillInSubstitutedPeriods();
		Planning.UpdateReplacementHyperlink(ThisForm);
	Else
		SubstitutedPeriods.Clear();
		SubstitutionFormattedLine = New FormattedString(New Array);
	EndIf;
	
	Planning.FillInPeriodTable(TablePeriods, Object.Periodicity, Object.BeginOfPeriod, Object.PeriodEnding, ShowNumberOfPeriod, SubstitutedPeriods);
	
	UpdateCrossTableStructure(TablePeriods, True);
	
	If Object.CrossTable Then
		
		SaveNewPeriodServer();
		
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "ProductionPlan");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	TablePeriods See Planning.TablePeriods
// 	RecalculateTotals_ - Boolean - LongDesc
&AtServer
Procedure UpdateCrossTableStructure(TablePeriods, RecalculateTotals_ = True)
	
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	ThisIsOnePeriod = NumberOfPeriods = 1;
	
	DateField_ = ?(ThisIsDisassembly, "ManufacturedProductStartDate2", "ManufacturedProductDateOfProduction");
	Items[DateField_].ChoiceList.Clear();
	For Each Period In TablePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf; 
		Items[DateField_].ChoiceList.Add(BegOfDay(Period.StartDate), Period.Title);
	EndDo;
	
	Items.ProductsByDateNumberOfPackages.Visible = Not ThisIsOnePeriod;
	
	Items.CellComment.Visible = Object.CrossTable And Not ThisIsOnePeriod;
	Items.CellIsCanceled.Visible = Object.CrossTable And Not ThisIsOnePeriod;
	
	If Not Object.CrossTable 
		And Not PlannedBalanceIsUsed Then
		Items.GroupPerformanceProducts.CurrentPage = Items.GroupProductsTable_3;
		ValueToFormAttribute(TablePeriods,"TimeIntervals");
		SaveNewPeriodServer();
		UpdateReplacementAttribute();
		Return;
	EndIf; 
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "ProductsByDate");
	OutputParameters.Insert("CrossTableFormElement", "ProductsByDate");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Object.Periodicity);
	OutputParameters.Insert("Fields", New Array());
	
	If Not ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_WhenChangingQuantity");
	Planning.AddQuantityCrossTableField(
		OutputParameters, 
		True, 
		Not ThisIsOnePeriod, 
		ThisIsOnePeriod, 
		StructureOfActions);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_OnChangeCanceled");
	Planning.AddCrossTableFieldCanceled(OutputParameters, ThisIsOnePeriod, StructureOfActions);
	
	StructureOfActions = New Structure;
	Planning.AddReplacedCrossTableField(OutputParameters, ThisIsOnePeriod And Object.Substitutional, StructureOfActions);
	Planning.AddReplacedToOrderCrossTableField(OutputParameters,False, StructureOfActions);
	
	If ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_WhenChangingComment");
	StructureOfActions.Insert("StartChoice", "Attachable_StartOfCommentSelection");
	Planning.AddCrossTableCommentField(OutputParameters, ThisIsOnePeriod, StructureOfActions);
	
	If Object.FillInUsingFormula Then
		AddFieldsFromAdditionalParameters(OutputParameters);
	Else
		Planning.AddTranscriptCrossTableField(OutputParameters);
	EndIf;
	
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	OutputParameters.Insert("NameOfCrossTableProps", "SemiFinishedProductsByDate");
	OutputParameters.Insert("CrossTableFormElement", "SemiFinishedProductsByDate");
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	OutputParameters.Insert("NameOfCrossTableProps", "AllSemiFinishedProductsByDate");
	OutputParameters.Insert("CrossTableFormElement", "");
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	
	SetConditionalAppearance();
	SetConditionalAppearanceOfCrossTable();
	
	If RecalculateTotals_ Then
		CalculateTotals_(ThisForm);
		CalculateTotals_(ThisForm,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ScenarioOnChangeServer()

	If Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile
		Or (Object.Scenario <> ThisForm["DetailsBeforeChange"].Scenario 
			And Not ValueIsFilled(Object.PlanProfile)) Then
		UpdatePlanView = True;
	Else
		UpdatePlanView = False;
	EndIf;
	
	ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario,
		"Periodicity,
		|ShowNumberOfPeriod,
		|UseForMaterialsPlanning,
		|PlanningByAssignments,
		|BudgetingScenario,
		|DemandForMaterials");
	
	FillPropertyValues(Object, ScriptParameters_);
	FillPropertyValues(ThisForm, ScriptParameters_);
	
	FillInTheSpecification = ScriptParameters_.UseForMaterialsPlanning;
	
	If UpdatePlanView Then
		
		Object.PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.ProductionPlan, Object.Scenario);
		
	EndIf;
	
	If PlanningClientServer.YouNeedToUpdateInterface(Object, ThisForm, "DetailsBeforeChange") Then
		WhenChangingPeriodsOnServer(True);
	EndIf;
	
	If UpdatePlanView Then
		PlanProfileOnChangeServer(True);
		Object.FilledAutomatically = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure PlanProfileOnChangeServer(UpdateRule = False)
	
	UpdateRule = UpdateRule Or Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile;
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, UpdateRule, FillingRuleAddress, CustomSettingsAddress);
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	If PlanViewParameters.FillInByShortage = True Then
		Object.CrossTable = False;
		SwitchPeriodsToRowsOnServer(Undefined);
	EndIf;
	
	If PlanSemiFinishedProductsAutomatically Then
		DeleteSemiFinishedProductsOnServer();
	EndIf;
	
	If UpdateRule Then
		
		FillPropertyValues(ThisForm, PlanViewParameters, "NumberOfPeriods");
		
		If NumberOfPeriods > 0 Then
			Object.PeriodEnding = Undefined;
			PlanningClientServer.SetStartEndOfPlanPeriod(
				Object.Periodicity, 
				Object.BeginOfPeriod, 
				Object.PeriodEnding,
				CurrentSessionDate(),
				PlanViewParameters.NumberOfPeriods);
		EndIf;
		
		FillPropertyValues(Object, PlanViewParameters);
		
		If Object.Substitutional Then
			Object.SubstitutionPeriodStart = Object.BeginOfPeriod;
		EndIf;
			
		Object.FillingRule.Load(GetFromTempStorage(FillingRuleAddress));
		Object.FilledAutomatically = False;
		
		ThisIsDisassembly = (Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly);
		
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "ProductionPlan");
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
		If PlanViewParameters.Property("SettingsStructure")
			And PlanViewParameters.SettingsStructure <> Undefined Then
			SettingsStructure = PlanViewParameters.SettingsStructure;
		EndIf;
		WhenChangingPeriodsOnServer();
		ReadSetSpecificationSelectionParameters();
		FillInSpecificationInProductLines(,True);
		AvailableProductTypes.LoadValues(ProductDataManagementClientServer.TypesOfItemsByTypeOfProductionProcess(Object.ProductionProcessType));
		ProductDataManagementClientServer.SetSelectionByItemType(Items.ManufacturedProductProducts, AvailableProductTypes.UnloadValues());
		ProductDataManagementClientServer.SetSelectionByItemType(Items.ProductsByDateProducts, AvailableProductTypes.UnloadValues());
	EndIf;
	
	FillInBOMByPeriods = PlanViewParameters.FillInBOMByPeriods;
	
	SaveNewPeriodServer();
	
	If UpdateRule And ValueIsFilled(Object.PlanProfile) Then
		UpdateRelatedItemDetails(Object, ThisForm);
	EndIf;
	
	SetVisibility1();
	
	Items.GroupProducts_2.Title = TitleOfTablePart(Object.ProductionProcessType);
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		Items.ManufacturedProductSelectGoods.Title = NStr("vi = 'Chọn công việc';
															|ru = 'Подобрать работы';
															|en = 'Pick works'; fa = 'Pick works';
															|it = 'Pick works';
															|pl = 'Pick works';
															|tr = 'İşleri seç'");
		Items.ProductsByDateSelectGoods.Title = NStr("vi = 'Chọn công việc';
													|ru = 'Подобрать работы';
													|en = 'Pick works'; fa = 'Pick works';
													|it = 'Pick works';
													|pl = 'Pick works';
													|tr = 'İş seç'");
	Else
		Items.ManufacturedProductSelectGoods.Title = NStr("vi = 'Chọn mặt hàng';
															|ru = 'Подобрать товары';
															|en = 'Pick goods'; fa = 'انتخاب کالاها';
															|it = 'Selezionare la merce';
															|pl = 'Dobierz wiersze pozycji';
															|tr = 'Malları seç'");
		Items.ProductsByDateSelectGoods.Title = NStr("vi = 'Chọn mặt hàng';
													|ru = 'Подобрать товары';
													|en = 'Pick goods'; fa = 'انتخاب کالاها';
													|it = 'Selezionare la merce';
													|pl = 'Dobierz wiersze pozycji';
													|tr = 'Malları seç'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	Items.PlanProfile.Enabled = ValueIsFilled(Object.Scenario);
	
	Items.Department.Visible = FillInBusinessUnit Or ValueIsFilled(Object.Department);
	
	Items.ManufacturedProductConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	Items.ProductsByDateConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	Items.ProductsFillIn.Visible = Not Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ManufacturedProductSplitRow.Visible = Not Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsByDateFillIn_3.Visible = Not Object.FillInUsingFormula;
	Items.ManufacturedProductFillInProducts_.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsByDateFillInProducts_.Visible = Object.FillInUsingFormula;
	Items.ManufacturedProductFillInIndicators.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsByDateFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.ProductsGroupChangeQuantity.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsGroupByDateChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.GoodsAdditionalParametersFormula.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsAdditionalParametersDeviation.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("ProductsByDate" + "Deviation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["ProductsByDate" + "Deviation"].Visible = Object.FillInUsingFormula;
	EndIf;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("ProductsByDate" + "FormulaCalculation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["ProductsByDate" + "FormulaCalculation"].Visible = Object.FillInUsingFormula;
	EndIf;
	Items.GoodsAdditionalParameters.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	
	Items.ManufacturedProductFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	Items.ProductsByDateFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	
	Items.ManufacturedProductBillOfMaterials.Visible = FillInTheSpecification;
	Items.ProductsByDateBillOfMaterials.Visible = FillInTheSpecification;
	Items.StateOfProductionPlanCalculation.Visible = FillInTheSpecification;
	Items.RecalculateMaterialConsumptionPlanForm.Visible = FillInTheSpecification;
	Items.DemandForMaterials.Visible = FillInTheSpecification
		And ProductDataManagement.AvailableDescriptionOfProbabilityOfApplicationOfMaterials();
	
	PlanSemiFinishedProductsManually = FillInTheSpecification
		And Not PlanSemiFinishedProductsAutomatically
		And EnterpriseManagement
		And Not ThisIsDisassembly
		And Not Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM;
		
	Items.ManufacturedProductPlanSemiFinishedProducts_3.Visible =        PlanSemiFinishedProductsManually And Not Object.FillInByShortage;
	Items.ProductsByDatePlanSemiFinishedProducts_3.Visible = PlanSemiFinishedProductsManually;
	Items.ManufacturedProductRemoveSemiFinishedProducts.Visible =              PlanSemiFinishedProductsManually;
	Items.ProductsByDateRemoveSemiFinishedProducts.Visible =       PlanSemiFinishedProductsManually;
	Items.ManufacturedProductReleaseDateOfProductsOrSemiFinishedProduct.Visible = PlanSemiFinishedProductsManually;
	
	Items.ManufacturedProductDateOfProduction.Visible = Not ThisIsDisassembly;
	
	If Not GetFunctionalOption("EnterpriseManagement") Then
		
		Items.NeedCalculatedDUCK.Visible = True;
		Items.TheNeedIsWaitingForTheDUCKCalculation.Visible = True;
		Items.TheNeedIsCalculatedByTheDUCK.Visible = True;
		Items.TheNeedIsCanceledDUCK.Visible = True;
		Items.TheNeedIsNotCalculatedThereAreErrorsDUCK.Visible = True;
		
		Items.DemandCalculated.Visible = False;
		Items.NeedAwaitingCalculation.Visible = False;
		Items.TheDemandIsCalculated.Visible = False;
		Items.TheNeedIsCanceled.Visible = False;
		Items.TheNeedIsNotCalculatedThereAreErrors.Visible = False;
		
	EndIf;
	
	Items.Details.Visible = Not Object.FillInUsingFormula;
	Items.ProductsByDatesContextMenuGroupUsingFormula.Visible = Object.FillInUsingFormula;
	Items.ProductsContextMenuGroupByFormula.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	
	ShowDestinations = PlanningByAssignments And UseOrderSupplyWithAssignment;
	
	Items.Purpose.Visible = ShowDestinations And Not FillInAssignmentInTabularForm;
	Items.ManufacturedProductPurpose.Visible = ShowDestinations And FillInAssignmentInTabularForm;
	Items.ProductsByDatePurpose.Visible = ShowDestinations And FillInAssignmentInTabularForm;
	Items.SemiFinishedProductsByDatePurpose.Visible = ShowDestinations And FillInAssignmentInTabularForm;
	Items.ListOfSemiFinishedProductsPurpose.Visible = ShowDestinations And FillInAssignmentInTabularForm;
	
	Items.GroupSemiFinishedProducts.Visible = AutoSupplementalPlanningOfSemiFinishedProducts(ThisObject) And Not ThisIsDisassembly;
	
	SetSemiFinishedProductAlert(ThisObject, False);
	
	Items.ManufacturedProductSubstituted.Visible = Object.Substitutional;
	
	DescriptionOfManufacturingProcessTypeIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	Items.ProductionProcessType.Visible = DescriptionOfManufacturingProcessTypeIsAvailable;
	Items.ManufacturedProductSelectSubstitutes.Visible = RightToReadSubstitutes;
	Items.ProductsByDateSelectSubstitutes.Visible = RightToReadSubstitutes;
	If Not Object.FillInByShortage Then
		Items.TheCaptionThereAreCanceledSecurityAdjustments.Visible = False;
	EndIf;
	
	Items.ManufacturedProductFillInByShortages.Visible = Object.FillInByShortage;
	Items.AutoFill.Visible = Object.FillInByShortage;
	If ValueIsFilled(Object.Ref) Then
		Items.BeginningEndOfPeriod.Enabled = Not Object.FillInByShortage;
	EndIf;
	Items.ProductsSecurityAdjustment.Visible = Object.FillInByShortage;
	
	Items.FormGroupPeriods.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductInsertRows.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductContextMenuSplitRow.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductSelectGoods.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductImportFromExcel.Visible = Not Object.FillInByShortage;
	Items.ExcelProducts.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductCancelPlanLines.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductContextMenuCancelPlanLines.Visible = Not Object.FillInByShortage;
	Items.ManufacturedProductCanceled.Visible = Not Object.FillInByShortage;
	
	UpdateDisplayOfAdjustments();
	UpdateDisplayOfShortageAlertGroupFillIn();
	ReadThereAreCanceledSecurityAdjustments();
	
EndProcedure

&AtClient
Procedure UpdateDisplayOfFillInDeficitAlertGroupOnClient()
	
	If Not Object.FillInByShortage Then
		
		Items.GroupNotificationsFillingByShortages.Visible = False;
		DetachIdleHandler("UpdateDisplayOfFillInDeficitAlertGroupOnClient");
		
	Else
		
		UpdateDisplayOfShortageAlertGroupFillIn();
	
		If ShortageRecalculationControlTimer = 0 Then
			ShortageRecalculationControlTimer = 2;
		Else
			ShortageRecalculationControlTimer = Min(ShortageRecalculationControlTimer*1.5, 60);
		EndIf;
		
		AttachIdleHandler("UpdateDisplayOfFillInDeficitAlertGroupOnClient", ShortageRecalculationControlTimer, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDisplayOfShortageAlertGroupFillIn()
	
	If Not Object.FillInByShortage Then
		
		Items.GroupNotificationsFillingByShortages.Visible = False;
		
	Else
		
		Query = New Query();
		Query.Text = 
		"SELECT TOP 1
		|	CalculationOfPlanShortagesByStages.Scenario AS Scenario
		|FROM
		|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
		|WHERE
		|	CalculationOfPlanShortagesByStages.ShouldRecalculate
		|	AND CalculationOfPlanShortagesByStages.Scenario = &Scenario
		|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
		|	AND CalculationOfPlanShortagesByStages.PlanningPeriod = &PlanningPeriod";
		
		Query.SetParameter("Scenario", Object.Scenario);
		Query.SetParameter("PlanProfile", Object.PlanProfile);
		Query.SetParameter("PlanningPeriod", Object.BeginOfPeriod);
		
		Selection = Query.Execute().Select();
		Visible = Selection.Next();
		
		CommonClientServer.SetFormItemProperty(Items,"GroupNotificationsFillingByShortages","Visible", Visible);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDisplayOfAdjustments()
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	AdjustmentOfPlannedDemand.Ref AS Ref,
	|	SUM(CASE
	|			WHEN AdjustmentOfPlannedDemand.Status = VALUE(Enum.StatusesOfPlanAdjustments.ForChecking)
	|				THEN 1
	|			ELSE 0
	|		END) AS QuantityToCheck
	|FROM
	|	Document.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand
	|WHERE
	|	AdjustmentOfPlannedDemand.Plan = &Plan
	|	AND AdjustmentOfPlannedDemand.Status IN (VALUE(Enum.StatusesOfPlanAdjustments.ForChecking), VALUE(Enum.StatusesOfPlanAdjustments.Upholded_))
	|
	|GROUP BY
	|	AdjustmentOfPlannedDemand.Ref";
	Query.SetParameter("Plan", Object.Ref);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Items.TheLabelHasCanceledAdjustmentsNeeds.Visible = True;
		If Selection.QuantityToCheck = 0 Then
			Items.LabelForAdjustingPlannedRequirements.Title = NStr("vi = 'Cần điều chỉnh nhu cầu';
																	|ru = 'Имеются корректировки потребностей';
																	|en = 'There are demand adjustments there'; fa = 'There are demand adjustments there';
																	|it = 'Esistono rettifiche di fabbisogni';
																	|pl = 'Są korekty zapotrzebowania';
																	|tr = 'Gereksinim düzeltmeleri mevcut'");
			Items.DecorationCanceledAdjustmentsNeedsToBeChecked.Visible = False;
			Items.DecorationCanceledNeedsAdjustments.Visible = True;
		Else
			Items.LabelForAdjustingPlannedRequirements.Title = NStr("vi = 'Có các điều chỉnh yêu cầu xác minh bị hủy';
																	|ru = 'Имеются отмененные корректировки потребностей к проверке';
																	|en = 'There are canceled demand adjustments to check'; fa = 'There are canceled demand adjustments to check';
																	|it = 'Esistono rettifiche di fabbisogni annullate da verificare';
																	|pl = 'Są anulowane korekty zapotrzebowania do weryfikacji';
																	|tr = 'Kontrole gereksinim düzeltmeleri içerir'");
			Items.DecorationCanceledAdjustmentsNeedsToBeChecked.Visible = True;
			Items.DecorationCanceledNeedsAdjustments.Visible = False;
		EndIf;
	Else
		Items.TheLabelHasCanceledAdjustmentsNeeds.Visible = False;
	EndIf;
	Items.TheLabelHasCanceledAdjustmentsNeeds.Visible = Not Query.Execute().IsEmpty();
	
	Items.AutoFill.Visible = Object.FillInByShortage;
	
EndProcedure

&AtServerNoContext
Function GetPlanViewParameters(Val PlanProfile, Val UpdateRule, FillingRuleAddress, CustomSettingsAddress)
	
	Attributes = "NumberOfPeriods,
		|FillInBusinessUnit,
		|Substitutional,
		|DisableEditingOfRule,
		|DisableEditingOfPopulationSettings,
		|FillInUsingFormula,
		|FillInAssignmentInTabularForm,
		|PlanSemiFinishedProductsAutomatically,
		|ProductionProcessType,
		|FillInBOMByPeriods,
		|FillInByShortage,
		|Parent,
		|AutoFill";
	
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
	
	If UpdateRule Then
		FillingRuleAddress = Planning.GetAddressOfDefaultFillInRule(Enums.TypesOfPlans.ProductionPlan, PlanProfile, FillingRuleAddress);
		CustomSettingsAddress = Planning.GetAddressOfUserDefaultSettings(Enums.TypesOfPlans.ProductionPlan, PlanProfile, CustomSettingsAddress);
		SettingsStructure = Planning.GetDefaultSettings(Enums.TypesOfPlans.ProductionPlan, PlanProfile);
		If SettingsStructure.Property("Formula") Then
			PlanViewParameters.Insert("SettingsStructure", SettingsStructure);
		EndIf;
		For Each Item In SettingsStructure Do
			PlanViewParameters.Insert(Item.Key, Item.Value);
		EndDo; 
	EndIf;

	Return PlanViewParameters;

EndFunction

&AtClientAtServerNoContext
Procedure UpdateRelatedItemDetails(Object, Form)
	
	If Object.CrossTable
		Or Form.PlannedBalanceIsUsed Then
		Goods = Form.ProductsByDate;
	Else
		Goods = Object.ManufacturedProduct;
	EndIf;
	
	If Not Form.FillInBusinessUnit Then
		Object.Department = Undefined;
	EndIf;
	
	If Not Form.PlanningByAssignments Then
		Object.Purpose = Undefined;
	EndIf;
	
	For Each TSRow In Goods Do
		
		If Not Form.FillInTheSpecification Then
			TSRow.BillOfMaterials = Undefined;
		EndIf;
		
		If Not Form.PlanningByAssignments 
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			TSRow.Purpose = Undefined;
		ElsIf Not Form.FillInAssignmentInTabularForm Then
			If TSRow.SemiFinishedProduct 
				And Not ValueIsFilled(TSRow.Purpose) Then
				Continue;
			EndIf;
			TSRow.Purpose = Object.Purpose;
			TSRow.LineOfBusiness = Form.LineOfBusiness;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure NotifyUserAboutFillingInData()

	ShowUserNotification(
		NStr("vi = 'Hoàn thành việc điền dữ liệu vào chứng từ';
			|ru = 'Заполнение данных в документ завершено';
			|en = 'Data population to the document is completed'; fa = 'Data population to the document is completed';
			|it = 'La compilazione dei dati nel documento è completata';
			|pl = 'Wypełnianie danych dokumentu jest zakończone';
			|tr = 'Belgede verileri doldurma bitti'"),
		,
		,
		PictureLib.Information32);

	If SemiFinishedProductsWerePlanned Then
		
		SemiFinishedProductsWerePlanned = False;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Kontynuuj';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Notification = New CallbackDescription("PlanSemiFinishedProducts_3Completion", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Tất cả các sản phẩm bán thành phẩm sẽ được lập kế hoạch lại. Tiếp tục?';
										|ru = 'Все полуфабрикаты будут перепланированы. Продолжить?';
										|en = 'All semi-finished products will be replanned. Continue?'; fa = 'All semi-finished products will be replanned. Continue?';
										|it = 'Tutti i prodotti semilavorati saranno ripianificati. Continuare?';
										|pl = 'Wszystkie półprodukty zostaną ponownie zaplanowane. Kontynuować?';
										|tr = 'Tüm yarı mamul ürünler yeniden planlanacaktır. Devam edilsin mi?'"), Buttons);
		Return;
		
	EndIf
	
EndProcedure

&AtClient
Procedure NotifyUserAboutStartOfFillingInData()
	
	Status(NStr("vi = 'Đang tiến hành điền dữ liệu vào chứng từ';
				|ru = 'Выполняется заполнение данных в документ';
				|en = 'Populating the document with data'; fa = 'Populating the document with data';
				|it = 'La compilazione dei dati nel documento è in esecuzione';
				|pl = 'Wypełnianie danych w dokumencie';
				|tr = 'Belgede verileri doldurma gerçekleştiriliyor'"));
	
EndProcedure

&AtServer
Function GetAddressOfPeriodTable()

	Return PutToTempStorage(ThisForm.TimeIntervals.Unload(), UUID);

EndFunction

&AtServer
Procedure AddProducts_2(TableOfGoods, CachedValues = Undefined, LoadingFromFile = False)
	
	Modified = True;
	
	StructureOfActions   = New Structure;
	RowsIDs = New Array;
	
	If Not Object.CrossTable Then
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	EndIf;
	
	CachedValuesStringProcessing = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		Object.FilledAutomatically = False;
		
		If Object.CrossTable And Not LoadingFromFile Then
			CurrentRow = ProductsByDate.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			CurrentPeriod_ = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True))[0];
			
			If CurrentRow["Count_" + CurrentPeriod_.ColumnName] = 0 
				And CurrentRow.Count <> 0 Then
				CurrentRow["Count_" + CurrentPeriod_.ColumnName] = CurrentRow.NumberOfPackages;
			EndIf;
			If Not Object.FillInUsingFormula And CurrentRow["Details_" + CurrentPeriod_.ColumnName] = ""
				And CurrentRow.Details <> "" Then
				CurrentRow["Details_" + CurrentPeriod_.ColumnName] = CurrentRow.Details;
			EndIf;
		Else
			CurrentRow = Object.ManufacturedProduct.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			If Not ValueIsFilled(CurrentRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")]) Then
				CurrentRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")] = Object.BeginOfPeriod;
			EndIf;
			
			RowsToProcess.Add(CurrentRow);
			
		EndIf;
		
		RowsIDs.Add(CurrentRow.GetID());
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValuesStringProcessing);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductsByDate");
		GoodsLineQuantity = ProductsByDate.Count();
	Else
		GoodsLineQuantity = Object.ManufacturedProduct.Count();
	EndIf;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	FillInServiceDetails();
	
	If Not LoadingFromFile Then
		FillInSpecificationInProductLines(RowsIDs, True);
	EndIf;
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues = Undefined)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	AddProducts_2(ItemsFromStorage, CachedValues);
	
EndProcedure

&AtClient
Procedure FillInDataForReplacement()
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillInForReplacement");
	
	FillInDocument(Settings);
	
EndProcedure

&AtClient
Procedure ControlOfCalculationOfProductionPlan()
	
	If Object.Ref.IsEmpty() Or Not FillInTheSpecification Then
		Return;
	EndIf;
	
	CalculationState = StateOfProductionPlanCalculation(Object.Ref);
	
	If WaitForTheAdjustmentToBeCompleted
		And CalculationState.Code = ProductionPlanCalculationStatusCodes.Calculating Then
		
		WaitForTheAdjustmentToBeCompleted = False;
		AttachIdleHandler("ControlOfCalculationOfProductionPlan", 1, True);
		
		Return;
	EndIf;
	
	Items.PageNotCalculated.Visible           = (CalculationState.Code = ProductionPlanCalculationStatusCodes.NotCalculated);
	Items.PageCalculated.Visible             = (CalculationState.Code = ProductionPlanCalculationStatusCodes.Calculated);
	Items.ThePageIsWaitingForTheCalculation.Visible        = (CalculationState.Code = ProductionPlanCalculationStatusCodes.AwaitingCalculation);
	Items.CalculatingPage.Visible        = (CalculationState.Code = ProductionPlanCalculationStatusCodes.Calculating);
	Items.ThePageIsCanceled.Visible            = (CalculationState.Code = ProductionPlanCalculationStatusCodes.IsCancelled);
	Items.ThePageIsNotCalculatedThereAreErrors.Visible = (CalculationState.Code = ProductionPlanCalculationStatusCodes.NotCalculatedHasErrors);
	
	BlockListOfSemiFinishedProducts = CalculationState.Code = ProductionPlanCalculationStatusCodes.AwaitingCalculation
									Or CalculationState.Code = ProductionPlanCalculationStatusCodes.Calculating
									Or CalculationState.Code = ProductionPlanCalculationStatusCodes.IsCancelled;
	
	If BlockListOfSemiFinishedProducts Then
		
		SemiFinishedProductsCalculationStatus = NStr("vi = 'được tính toán';
													|ru = 'рассчитываются';
													|en = 'calculated'; fa = 'برآوردشده';
													|it = 'calcolo in corso';
													|pl = 'obliczają się';
													|tr = 'hesaplanıyor'");
		
		BlockListOfSemiFinishedProducts();
		
		AttachIdleHandler("ControlOfCalculationOfProductionPlan", 2, True);
		
	Else
		
		SemiFinishedProductsCalculationStatus = "";
		
		UnblockRefreshSemiFinishedProductsPage();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BlockListOfSemiFinishedProducts()
	
	Items.SemiFinishedProductsManagement.Enabled = False;
	Items.InformationText.ReadOnly = True;
	Items.ListOfSemiFinishedProducts.ReadOnly = True;
	
	CommonClientServer.SetDynamicListFilterItem(ListOfSemiFinishedProducts, "Recorder", Undefined, DataCompositionComparisonType.Equal,, True);
	
EndProcedure

&AtServer
Procedure UnlockListOfSemiFinishedProducts()
	
	Items.SemiFinishedProductsManagement.Enabled = True;
	Items.InformationText.ReadOnly = False;
	Items.ListOfSemiFinishedProducts.ReadOnly = False;
	
	CommonClientServer.SetDynamicListFilterItem(ListOfSemiFinishedProducts, "Recorder", Undefined, DataCompositionComparisonType.Equal,, False);
	
EndProcedure

&AtServer
Procedure UnblockRefreshSemiFinishedProductsPage()
	
	UnlockListOfSemiFinishedProducts();
	
	RefreshSemiFinishedProductsPage();
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListOfSemiFinishedProducts(ThereIsSelectionForOccurrencesOfSemiFinishedProducts = False)
	
	FiltersList = New Structure();
	FiltersList.Insert("ThereIsSelectionForOccurrencesOfSemiFinishedProducts", ThereIsSelectionForOccurrencesOfSemiFinishedProducts);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = AccumulationRegisters.ProductionPlans.RequestTextForDynamicListOfSemiFinishedProducts(FiltersList);
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = ListOfSemiFinishedProducts.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.ListOfSemiFinishedProducts, ListProperties);
	
	TheDynamicListOfSemiFinishedProductsIsInitialized                    = True;
	TheDynamicListOfSemiFinishedProductsIsASelectionBasedOnTheOccurrencesOfTheSemiFinishedProduct = ThereIsSelectionForOccurrencesOfSemiFinishedProducts;
	
EndProcedure

&AtServer
Procedure SetSelectionByOccurrencesOfSemiFinishedProduct()
	
	ProductsOfOccurrence = AccumulationRegisters.ProductionPlans.SemiFinishedProductsAreIncludedInProducts(SemiFinishedProductsSelection.ProductionPlan,
																							SemiFinishedProductsSelection.ProductionIssueDateOfIntermediateProducts,
																							SemiFinishedProductsSelection.Purpose,
																							SemiFinishedProductsSelection.Products,
																							SemiFinishedProductsSelection.Characteristic);
	
	If ProductsOfOccurrence.Count() > 0 Then
		
		Template = NStr("vi = 'Bán thành phẩm %1 được bao gồm trong hàng hóa %2, bảng kê chi tiết các nguồn lực sản xuất %3';
						|ru = 'Полуфабрикат %1 входит в продукцию %2, спецификация %3';
						|en = 'Semi-finished product %1 is included in products %2, BOM %3'; fa = 'Semi-finished product %1 is included in products %2, BOM %3';
						|it = 'Il prodotto semilavorato %1 fa parte dei prodotti %2, specifica %3';
						|pl = 'Półprodukt %1 jest zawarty w produkcji %2, specyfikacji %3';
						|tr = 'Yarı mamul ürün %1 üretime giriyor%2, ürün reçetesi%3'");
		
		For Each Entry In ProductsOfOccurrence Do
			
			MessageText = StrTemplate(Template,
				ProductsClientServer.ProductPresentation(SemiFinishedProductsSelection.Products, SemiFinishedProductsSelection.Characteristic,,, SemiFinishedProductsSelection.Purpose),
				ProductsClientServer.ProductPresentation(Entry.Products, Entry.Characteristic,,, Entry.Purpose),
				String(Entry.BillOfMaterials));
			
			CommonClientServer.MessageToUser(MessageText, Object.Ref);
			
		EndDo;
		
	EndIf;
	
	If Not TheDynamicListOfSemiFinishedProductsIsASelectionBasedOnTheOccurrencesOfTheSemiFinishedProduct Then
		SetPropertiesOfDynamicListOfSemiFinishedProducts(True);
	EndIf;
	
	ListOfSemiFinishedProducts.Parameters.SetParameterValue("ProductionPlan", SemiFinishedProductsSelection.ProductionPlan);
	ListOfSemiFinishedProducts.Parameters.SetParameterValue("ProductionIssueDateOfIntermediateProducts", SemiFinishedProductsSelection.ProductionIssueDateOfIntermediateProducts);
	ListOfSemiFinishedProducts.Parameters.SetParameterValue("Purpose", SemiFinishedProductsSelection.Purpose);
	ListOfSemiFinishedProducts.Parameters.SetParameterValue("Products", SemiFinishedProductsSelection.Products);
	ListOfSemiFinishedProducts.Parameters.SetParameterValue("Characteristic", SemiFinishedProductsSelection.Characteristic);
	
	ShowInformationText();
	
EndProcedure

&AtServer
Procedure DisableSelectionForSemiFinishedProductOccurrences()
	
	SemiFinishedProductsSelection = Undefined;
	SetPropertiesOfDynamicListOfSemiFinishedProducts();
	ShowInformationText();
	
EndProcedure

&AtServer
Procedure ShowInformationText()
	
	If SemiFinishedProductsSelection <> Undefined Then
		
		RowsArray = New Array;
		
		Template = NStr("vi = 'Đặt lọc theo các mục bán thành phẩm %1, bảng kê chi tiết các nguồn lực sản xuất %2';
						|ru = 'Установлен отбор по вхождениям полуфабриката %1, спецификация %2';
						|en = 'Filter by occurrences of a semi-finished product is set %1, BOM %2'; fa = 'Filter by occurrences of a semi-finished product is set %1, BOM %2';
						|it = 'La selezione è impostata per arrivi di semilavorati %1, specifica %2';
						|pl = 'Został ustawiony dobór według wystąpienia półproduktu %1, specyfikacja %2';
						|tr = '%1 yarı mamul ürününün oluşumlarına göre filtre kuruldu, %2 ürün reçetesi'");
		
		LabelText = StrTemplate(Template,
			ProductsClientServer.ProductPresentation(SemiFinishedProductsSelection.Products, SemiFinishedProductsSelection.Characteristic,,, SemiFinishedProductsSelection.Purpose),
			SemiFinishedProductsSelection.BillOfMaterials);
		RowsArray.Add(LabelText);
		
		RowsArray.Add(" (");
		
		DisableCommand = New FormattedString(
			NStr("vi = 'ngắt kết nối';
				|ru = 'отключить';
				|en = 'disable'; fa = 'disable';
				|it = 'disattivare';
				|pl = 'odłącz';
				|tr = 'devre dışı bırak'"),
			,
			,
			, 
			HyperlinkValueDisableSelectionForSemiFinishedProductOccurrences());
		RowsArray.Add(DisableCommand);
		
		RowsArray.Add(")");
		
		InformationText = New FormattedString(RowsArray);
		Items.InformationText.Visible = True;
		
	Else
		
		InformationText = New FormattedString("");
		Items.InformationText.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StateOfProductionPlanCalculation(Ref)
	
	Array = New Array;
	Array.Add(Ref);
	Return Documents.ProductionPlan.StatesOfProductionPlanCalculation(Array).Get(Ref);
	
EndFunction

&AtClient
Procedure SetCancelAndCommentCells()
	
	CellFound = False;
	
	If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
		ProductElementsByDate = Items.SemiFinishedProductsByDate;
		ElementsCellCanceled = Items.CellIsCanceled1;
		CellCommentElements = Items.CellComment1;
		ProductionField = "SemiFinishedProductsByDateQuantity_";
	Else
		ProductElementsByDate = Items.ProductsByDate;
		ElementsCellCanceled = Items.CellIsCanceled;
		CellCommentElements = Items.CellComment;
		ProductionField = "ProductsByDate" + "Count_";
	EndIf;
	
	CurrentData = ProductElementsByDate.CurrentData;
	If CurrentData = Undefined 
		Or (CurrentData.SemiFinishedProduct
		And Items.GroupPerformanceProducts.CurrentPage <> Items.GroupSemiFinishedProductsCrossTable) Then
		CellIsCanceled = False;
		CellComment = "";
		ElementsCellCanceled.Enabled = CellFound;
		CellCommentElements.Enabled = CellFound;
		Return;
	EndIf;
	
	If ProductElementsByDate.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If ProductElementsByDate.CurrentItem.Name = ProductionField+Period.ColumnName Then
				
				CurrentData["Canceled_"+ Period.ColumnName] = CellIsCanceled;
				CurrentData["Comment_"+ Period.ColumnName] = CellComment;
				CurrentData["PictureComment_"+ Period.ColumnName] = ValueIsFilled(CellComment);
				CellFound = True;
				CalculateTotals_(ThisForm, False);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not CellFound Then
		CellIsCanceled = False;
		CellComment = "";
	EndIf;
	
	ElementsCellCanceled.Enabled = CellFound;
	CellCommentElements.Enabled = CellFound;
	
EndProcedure

&AtClient
Procedure CellCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CellComment = EnteredText;
	Modified = True;
	CellCommentOnChange(Items.CellComment);
	
EndProcedure

&AtClient
Procedure CancelPlanLinesCompletion(Result, AdditionalParameters) Export 
	
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return
	EndIf;
	
	If Object.CrossTable Then
		If Items.GroupPerformanceProducts.CurrentPage = Items.GroupSemiFinishedProductsCrossTable Then
			SelectedRows = Items.SemiFinishedProductsByDate.SelectedRows;	
		Else
			SelectedRows = Items.ProductsByDate.SelectedRows;
		EndIf;
	Else
		SelectedRows = Items.ManufacturedProduct.SelectedRows;
	EndIf; 
	
	If SelectedRows.Count() > 0 Then
		CalculateTotals_(ThisForm);
	EndIf; 
	
EndProcedure

&AtClient
Procedure ConfigureAndPopulateAccordingToTheFillingRuleCompletion(Settings, AdditionalParameters) Export 
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	Modified = True;
	
	FilterIs_Specified = Settings.FilterIs_Specified;
	
	Settings.Insert("FillInRule", True);
	
	FillPropertyValues(Object, Settings, "UpdateAdd, ChangeResultTo, RoundingPrecision");
	
	FillInDocument(Settings);
	
EndProcedure

&AtServer
Procedure RefreshSemiFinishedProductsPage(Initialize = False)
	
	If Not AutoSupplementalPlanningOfSemiFinishedProducts(ThisForm) Then
		Return;
	EndIf;
	
	RowsCount = AccumulationRegisters.ProductionPlans.CalculateNumberOfSemiFinishedProducts(Object.Ref);
	SemiFinishedProductsCalculationStatus = Format(RowsCount, "NZ=");
	
	CheckIfThereAreUndoneAdjustments();
	
	RefreshEnabled = (Not Initialize And Not YouNeedToSetDynamicListParameters());
	
	If RefreshEnabled Then
		
		Items.ListOfSemiFinishedProducts.Refresh();
		
	Else
		
		If Not TheDynamicListOfSemiFinishedProductsIsInitialized Then
			SetPropertiesOfDynamicListOfSemiFinishedProducts();
		EndIf;
		
		ListOfSemiFinishedProducts.Parameters.SetParameterValue("ProductionPlan", Object.Ref);
		
	EndIf;
	
EndProcedure

&AtServer
Function YouNeedToSetDynamicListParameters()
	
	If Not TheDynamicListOfSemiFinishedProductsIsInitialized Then
		Return True;
	EndIf;
	
	Parameter = New DataCompositionParameter("ProductionPlan");
	ParameterValue = ListOfSemiFinishedProducts.Parameters.FindParameterValue(Parameter);
	Return ( ParameterValue = Undefined Or ParameterValue.Value <> Object.Ref );
	
EndFunction

&AtServer
Procedure ReadSetSpecificationSelectionParameters()
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.ProductionPlan);
	
	ItemArray = New Array;
	ItemArray.Add(Items.ManufacturedProductBillOfMaterials);
	ItemArray.Add(Items.ProductsByDateBillOfMaterials);
	
	ProductDataManagement.SetSpecificationSelectionParameters(ItemArray, BOMSelectionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function AutoSupplementalPlanningOfSemiFinishedProducts(Form)
	
	Return Form.FillInTheSpecification
		And Form.PlanSemiFinishedProductsAutomatically
		And Form.EnterpriseManagement;
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkValueDisableSelectionForSemiFinishedProductOccurrences()
	
	Return "#DisableSelectionForSemiFinishedProductOccurrences";
	
EndFunction

&AtServer
Procedure CheckIfThereAreUndoneAdjustments()
	If ValueIsFilled(Object.Ref) Then
		Visible = InformationRegisters.CancelProductionPlanAdjustingEntries.ThereAreUndoneAdjustments(Object.Ref);
	Else
		Visible = False;
	EndIf;
	
	Items.TheLabelThereAreCanceledAdjustments.Visible = Visible;
	Return; // in UT and KA empty handler
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateProductLaunchDate(Form, CurrentData)
	
	Object = Form.Object;
	
	If ValueIsFilled(Object.Scenario)
		And ValueIsFilled(CurrentData.DateOfProduction)
		And ValueIsFilled(CurrentData.BillOfMaterials)
		And Not Form.ThisIsDisassembly Then
		
		CurrentData.StartDate2 = CalculateLaunchDateServer(
			Object.Scenario,
			CurrentData.BillOfMaterials,
			CurrentData.DateOfProduction,
			CurrentData.StartDate2,
			ProcessingOfTabularFormsClientServer.LineCache(Form.Items.ManufacturedProduct, Form),
			New Structure("DateOfProduction, StartDate2", "DateOfProduction", "StartDate2"),
			Object.DemandForMaterials);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculateLaunchDateServer(Scenario, BillOfMaterials, DateOfProduction, StartDate2, DataBeforeChange, FieldsNames, MethodOfCalculationOfMaterials)
	
	If ValueIsFilled(DataBeforeChange[FieldsNames.StartDate2])
		And ValueIsFilled(DataBeforeChange[FieldsNames.DateOfProduction])
		And ValueIsFilled(DataBeforeChange.BillOfMaterials) Then
		
		RegulatoryLaunchDateBeforeChange = Planning.CalculateLaunchDate(
			Scenario,
			DataBeforeChange[FieldsNames.DateOfProduction],
			DataBeforeChange.BillOfMaterials,
			MethodOfCalculationOfMaterials);
			
		If RegulatoryLaunchDateBeforeChange <> DataBeforeChange[FieldsNames.StartDate2] Then
			
			Return StartDate2;
			
		EndIf;
		
	EndIf;
			
	Return Planning.CalculateLaunchDate(Scenario, DateOfProduction, BillOfMaterials, MethodOfCalculationOfMaterials);
	
EndFunction

&AtServer
Procedure FillInProductLaunchDates(Var_ThisObject = Undefined)
	
	If Var_ThisObject = Undefined Then
		Var_ThisObject = Object;
	EndIf;
	
	If Var_ThisObject.ManufacturedProduct.Count() = 0 Or ThisIsDisassembly Then
		Return;
	EndIf;
	
	Planning.GetDurationSpecificationsAndFillDatesOnSchedule(
		Var_ThisObject.ManufacturedProduct,
		"DateOfProduction",
		"StartDate2",
		Var_ThisObject.Scenario,
		False,
		Var_ThisObject.DemandForMaterials);
	
EndProcedure

&AtClientAtServerNoContext
Function TitleOfTablePart(ProductionProcessType)
	
	ProcessType = ?(ProductionProcessType.IsEmpty(),
		PredefinedValue("Enum.ProductionProcessTypes.Assembly"),
		ProductionProcessType);
	
	Return ProductionClientServer.TitleOfTablePartByProcessType(ProcessType);
	
EndFunction

&AtServer
Procedure FillInSpecificationInProductLines(Val IDs = Undefined, CheckFillMode = False, OnlyEmpty = False)
	
	Modified = True;
	RowsArray = New Array;
	
	TableDetails = ProductionTableDescription(ThisForm);
	
	If IDs <> Undefined Then
		For Each Id In IDs Do
			String = TableDetails.TS.FindByID(Id);
			If OnlyEmpty And ValueIsFilled(String.BillOfMaterials) Then
				Continue;
			EndIf;
			RowsArray.Add(String);
		EndDo;
	Else
		For Each String In TableDetails.TS Do
			If OnlyEmpty And ValueIsFilled(String.BillOfMaterials) Then
				Continue;
			EndIf;
			RowsArray.Add(String);
		EndDo;
	EndIf;
	
	ProductData_2 = New Array;
	
	For Each String In RowsArray Do
		
		ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
			Object, String, BOMSelectionParameters, ThisForm, New Structure("KeyOfDataPaths", TableDetails.DataPath));
		
		If CheckFillMode Then
			ProductData.Insert("CurrentSpecification", String.BillOfMaterials);
		EndIf;
		
		ProductData_2.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(RowsArray, ProductData_2, BOMSelectionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionTableDescription(Form)
	
	Object = Form.Object;
	
	Result = New Structure("TS, TSName, DataPath");
	
	If Object.CrossTable Or Form.PlannedBalanceIsUsed Then
		Result.DataPath = "ProductsByDate";
		Result.TS          = Form.ProductsByDate;
		Result.TSName       = "ProductsByDate";
	Else
		Result.DataPath = "Object.ManufacturedProduct";
		Result.TS          = Object.ManufacturedProduct;
		Result.TSName       = "ManufacturedProduct";
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ParametersForTransitionToProductionPlanCalculationErrors(Ref)
	
	FormParameters = New Structure;
	
	//selection by metadata is not supported, we will limit ourselves to selection by event and data
	FormParameters.Insert("Data", Ref);
	FormParameters.Insert("EventLogEvent", ProductionServer.TaskQueueProcessingEvent());
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	
	FormParameters.Insert("Level", FilterByLevel);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure StartChangingListOfSemiFinishedProducts(SelectedRows)
	
	If Not ValueIsFilled(SelectedRows) Then
		
		ShowMessageBox(, NStr("vi = 'Không có hàng nào được chọn cho các hành động';
								|ru = 'Не выбрана строка (-и) для выполнения действий';
								|en = 'No line (s) selected to perform actions.'; fa = 'No line (s) selected to perform actions.';
								|it = 'Non è stata selezionata nessuna riga (righe) per l''esecuzione dell''azione';
								|pl = 'Nie wybrano wiersz (-e) dla wykonywania czynności';
								|tr = 'Eylemin gerçekleştirilmesi için seçilmeyen satır (-lar)'"));
		Return;
		
	EndIf;
	
	If Not Object.Posted Or Modified Then
		
		Notification = New CallbackDescription("HoldBeforeStartingChangesToListOfSemiFinishedProducts", ThisObject);
		Buttons = New ValueList();
		QueryText = NStr("vi = 'Trước khi bạn bắt đầu thay đổi, bạn phải kết chuyển chứng từ. Kết chuyển?';
						|ru = 'Перед началом ввода изменений необходимо провести документ. Провести?';
						|en = 'Before you begin making changes, you need to post the document. Continue?'; fa = 'Before you begin making changes, you need to post the document. Continue?';
						|it = 'Prima di inserire le modifiche è necessario registrare il documento. Registrare?';
						|pl = 'Przed rozpoczęciem wprowadzania zmian należy zatwierdzić dokument. Zatwierdzić?';
						|tr = 'Değişiklikleri girmeye başlamadan önce belgenin kaydedilmesi gerekmektedir. Kaydedilsin mi?'");
		Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Registrare';
												|pl = 'Post';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
		
		ShowQueryBox(Notification, QueryText, Buttons, , DialogReturnCode.Yes);
		Return;
		
	EndIf;
	
	IDs = New Array;
	
	If TypeOf(SelectedRows) = Type("Array") Then
		
		For Each Id In SelectedRows Do
			
			If TypeOf(Id) <> Type("AccumulationRegisterRecordKey.ProductionPlans") Then
				Continue;
			EndIf;
			
			IDs.Add(Id);
			
		EndDo;
		
	Else
		
		If TypeOf(SelectedRows) = Type("AccumulationRegisterRecordKey.ProductionPlans") Then
			IDs.Add(SelectedRows);
		EndIf;
	
	EndIf;
	
	OpenFormEditingSemiFinishedProduct(IDs);
	
EndProcedure

&AtClient
Procedure HoldBeforeStartingChangesToListOfSemiFinishedProducts(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		TMCommonUseClient.Post(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFormEditingSemiFinishedProduct(IDs)
	
	CallbackDescription = New CallbackDescription("OpenFormEditingSemiFinishedProductCompletion", ThisObject);
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ProductionPlan", Object.Ref);
	FormParameters.Insert("Scenario", Object.Scenario);
	FormParameters.Insert("DemandForMaterials", Object.DemandForMaterials);
	FormParameters.Insert("IDs", IDs);
	
	OpenForm("AccumulationRegister.ProductionPlans.Form.EditFormIntermediateProduct", FormParameters, ThisForm,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure OpenFormEditingSemiFinishedProductCompletion(AdjustmentMade, AdditionalParameters) Export
	
	If ( AdjustmentMade = True ) Then
		
		WaitForTheAdjustmentToBeCompleted = True;
		
		AttachIdleHandler("ControlOfCalculationOfProductionPlan", 0.2, True);
		
	EndIf;
	
EndProcedure

&AtServer
Function PlaceManufacturedProductsInVault()
	
	If Object.CrossTable Then
		ManufacturedProductsForDistribution = ProductsByDate.Unload(, "Products, Characteristic");
	Else
		ManufacturedProductsForDistribution = Object.ManufacturedProduct.Unload(, "Products, Characteristic");
	EndIf;
	
	Return PutToTempStorage(ManufacturedProductsForDistribution);
	
EndFunction

&AtClient
Procedure QuantityDistributionCompletion(DistributionParameters, AdditionalParameters) Export
	
	If DistributionParameters = Undefined Then
		Return;
	EndIf;
	
	If DistributionParameters.Operation = "AccordingToRateOfRelease"
		And DistributionParameters.OptionOfDistributionAccordingToRateOfRelease = "MultiplicityOfProducts" Then
		DistributeQuantityByProductsOnServer(DistributionParameters.StorageAddressMultiplicity);
		Return;
	EndIf;
	
	// Distribution of quantity in tabular parts
	SelectedRows = ?(Object.CrossTable, Items.ProductsByDate.SelectedRows,
												Items.ManufacturedProduct.SelectedRows);
	NewNumberOfPeriods = NumberOfPeriods;
	
	If DistributionParameters.Operation = "ByPeriods" Then
		NewNumberOfPeriods = DistributionParameters.NumberOfPeriods;
	ElsIf DistributionParameters.Operation = "AccordingToRateOfRelease" Then 
		For Each LineNumber In SelectedRows Do
			String = ?(Object.CrossTable, ProductsByDate.FindByID(LineNumber),
										Object.ManufacturedProduct.FindByID(LineNumber));
			
			ArrayNewQuantity = CalculateNewQuantity(String.NumberOfPackages, DistributionParameters);
			
			If ArrayNewQuantity.Count() > NewNumberOfPeriods Then
				NewNumberOfPeriods = ArrayNewQuantity.Count();
			EndIf;
			
		EndDo;
	EndIf;
	
	If NewNumberOfPeriods > NumberOfPeriods Then
		NumberOfPeriods = NewNumberOfPeriods;
		
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod,
														Object.PeriodEnding, , NewNumberOfPeriods, True);
		WhenChangingPeriodsOnServer();
	EndIf;
	
	TablePeriods = ThisObject["TimeIntervals"]; //FormDataCollection
	
	LinesForRecalculatingLaunchDate = New Array;
	RowsForDeletion = New Array;
	
	For Each LineNumber In SelectedRows Do
		
		String = ?(Object.CrossTable, ProductsByDate.FindByID(LineNumber),
										Object.ManufacturedProduct.FindByID(LineNumber));
		
		ArrayNewQuantity = CalculateNewQuantity(String.NumberOfPackages, DistributionParameters);
		
		IndexOf = 0;
		For Each Period In TablePeriods Do
			
			If IndexOf > ArrayNewQuantity.UBound() Then
				Break;
			EndIf;
			
			If Not Period.Active_ Or Period.ColumnNumber <= 0 Then
				Continue;
			EndIf;
			
			If Object.CrossTable Then
				String["Count_" + Period.ColumnName] = ArrayNewQuantity[IndexOf];
			Else
				
				NewRow = Object.ManufacturedProduct.Add();
				FillPropertyValues(NewRow, String);
				
				NewRow.NumberOfPackages = ArrayNewQuantity[IndexOf];
				NewRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")] = Period.StartDate;
				
				LinesForRecalculatingLaunchDate.Add(NewRow.GetID());
				
				RecalculateNumberOfPackagesAndAmountPerLine(NewRow, CachedValues);
			EndIf;
			
			IndexOf = IndexOf + 1;
			
		EndDo;
		
		If Not Object.CrossTable Then
			RowsForDeletion.Add(String);
		EndIf;
		
	EndDo;
	
	If Not Object.CrossTable Then
		
		StartDatesOfAddedLines(LinesForRecalculatingLaunchDate);
		
		For Each String In RowsForDeletion Do
			Object.ManufacturedProduct.Delete(String);
		EndDo;
		
	EndIf;
	
	Modified = True;
	CalculateTotals_(ThisObject);
	CalculateNumberOfRows(ThisObject);
	
EndProcedure

&AtClient
Function CalculateNewQuantity(NumberOfProducts, DistributionParameters)
	
	ArrayNewQuantity = New Array;
	
	If DistributionParameters.Operation = "AccordingToRateOfRelease" Then
		
		ArrayNewQuantity = MultipleDistributionOfProducts(NumberOfProducts, DistributionParameters.Repetition);
		
	ElsIf DistributionParameters.Operation = "ByPeriods" Then
		
		NewNumberOfPeriods = DistributionParameters.NumberOfPeriods;
		
		If DistributionParameters.OptionOfDistributionByPeriod = "Proportionally" Then
			
			NewCount = Round(NumberOfProducts / NewNumberOfPeriods, DistributionParameters.RoundingPrecision + 3);
			
			QuantityToDistribution = NumberOfProducts;
			For IndexOf = 0 To NewNumberOfPeriods - 1 Do
				
				If QuantityToDistribution <= NewCount Or NewCount = 0 Then
					ArrayNewQuantity.Add(QuantityToDistribution);
					QuantityToDistribution = 0;
				Else
					ArrayNewQuantity.Add(NewCount);
					QuantityToDistribution = QuantityToDistribution - NewCount;
				EndIf;
				
			EndDo;
		Else
			
			ResultOfShares = 0;
			For Each Share In DistributionParameters.Shares Do
				ResultOfShares = ResultOfShares + Share;
			EndDo;
			
			ShareValue = NumberOfProducts / ResultOfShares;
			ArrayNewQuantity = New Array;
			For Each Share In DistributionParameters.Shares Do
				ArrayNewQuantity.Add(Round(ShareValue * Share, DistributionParameters.RoundingPrecision + 3));
			EndDo;
			
		EndIf;
	EndIf;
	
	Return ArrayNewQuantity;
	
EndFunction

&AtServer
Procedure StartDatesOfAddedLines(LinesForRecalculatingLaunchDate)
	For Each Item In LinesForRecalculatingLaunchDate Do
		CalculateProductLaunchDate(ThisObject, Object.ManufacturedProduct.FindByID(Item));
	EndDo;
EndProcedure

&AtServer
Procedure DistributeQuantityByProductsOnServer(StorageAddressMultiplicity)
	
	FilterParameters = New Structure("Products, Characteristic");
	ProductsMultiplicity = GetFromTempStorage(StorageAddressMultiplicity);
	
	//Additional formation of periods
	
	NewNumberOfPeriods = NumberOfPeriods;
	For Each Product In ProductsMultiplicity Do
		
		If Product.Repetition = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(FilterParameters, Product);
		TSStrings = ?(Object.CrossTable, ProductsByDate.FindRows(FilterParameters),
										Object.ManufacturedProduct.FindRows(FilterParameters));
		
		For Each TSRow In TSStrings Do
				
				ArrayNewQuantity = MultipleDistributionOfProducts(TSRow.NumberOfPackages, Product.Repetition);
				
				If ArrayNewQuantity.Count() > NewNumberOfPeriods Then
					NewNumberOfPeriods = ArrayNewQuantity.Count();
				EndIf;
				
		EndDo;
		
	EndDo;
	
	If NewNumberOfPeriods > NumberOfPeriods Then
		NumberOfPeriods = NewNumberOfPeriods;
		
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod,
														Object.PeriodEnding, , NewNumberOfPeriods, True);
		WhenChangingPeriodsOnServer();
	EndIf;
	
	TablePeriods = ThisObject["TimeIntervals"]; //FormDataCollection
	
	For Each Product In ProductsMultiplicity Do
		
		If Product.Repetition = 0 Then
			Continue;
		EndIf;
		
		RowsForDeletion = New Array;
		
		FillPropertyValues(FilterParameters, Product);
		TSStrings = ?(Object.CrossTable, ProductsByDate.FindRows(FilterParameters),
										Object.ManufacturedProduct.FindRows(FilterParameters));
		
		For Each TSRow In TSStrings Do
			
			ArrayNewQuantity = MultipleDistributionOfProducts(TSRow.NumberOfPackages, Product.Repetition);
			
			MaxIndex = ArrayNewQuantity.UBound();
			IndexOf = 0;
			For Each Period In TablePeriods Do
				
				If Not Object.CrossTable And IndexOf > MaxIndex Then
					Break;
				EndIf;
				
				If Not Period.Active_ Or Period.ColumnNumber <= 0 Then
					Continue;
				EndIf;
				
				If Object.CrossTable Then
					
					If IndexOf > MaxIndex Then
						TSRow["Count_" + Period.ColumnName] = 0;
						Continue;
					EndIf;
					
					TSRow["Count_" + Period.ColumnName] = ArrayNewQuantity[IndexOf];
					
				Else
					
					NewRow = Object.ManufacturedProduct.Add();
					FillPropertyValues(NewRow, TSRow);
					
					NewRow.NumberOfPackages = ArrayNewQuantity[IndexOf];
					NewRow[?(ThisIsDisassembly, "StartDate2", "DateOfProduction")] = Period.StartDate;
					CalculateProductLaunchDate(ThisObject, NewRow);
					
				EndIf;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
			If Not Object.CrossTable Then
				RowsForDeletion.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If Not Object.CrossTable Then
			
			For Each String In RowsForDeletion Do
				Object.ManufacturedProduct.Delete(String);
			EndDo;
			
		EndIf;
	EndDo;
	
	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Function MultipleDistributionOfProducts(NumberOfProducts, Repetition)
	
	ArrayNewQuantity = New Array;
	
	NewNumberOfPeriods     = Int(NumberOfProducts / Repetition);
	NumberOfLastPeriod = NumberOfProducts - NewNumberOfPeriods * Repetition;
	
	While NewNumberOfPeriods > 0 Do
		ArrayNewQuantity.Add(Repetition);
		NewNumberOfPeriods = NewNumberOfPeriods - 1;
	EndDo;
	
	If NumberOfLastPeriod > 0 Then
		ArrayNewQuantity.Add(NumberOfLastPeriod);
	EndIf;
	
	Return ArrayNewQuantity;
	
EndFunction

#Region SecurityAdjustments

&AtServer
Procedure ReadThereAreCanceledSecurityAdjustments()
	
	If FillInByShortage And ValueIsFilled(Object.Ref) Then
		Visible = InformationRegisters.CancelAdjustmentsOfSupplyPlans.ThereAreUndoneAdjustments(Object.Ref);
	Else
		Visible = False;
	EndIf;
	
	Items.TheCaptionThereAreCanceledSecurityAdjustments.Visible = Visible;
		
EndProcedure

&AtClient
Procedure AdjustSecurity()
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("Scenario", Object.Scenario);
	FormParameters.Insert("PlanProfile", Object.PlanProfile);
	FormParameters.Insert("Period", Object.BeginOfPeriod);
	FormParameters.Insert("Products", CurrentRow.Products);
	FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	FormParameters.Insert("Purpose", CurrentRow.Purpose);
	FormParameters.Insert("ToSupply_", CurrentRow.Count);
	FormParameters.Insert("RangeOfDemandFrom", CurrentRow.RangeOfDemandFrom);
	FormParameters.Insert("RangeOfDemandTo", CurrentRow.RangeOfDemandTo);
	FormParameters.Insert("DemandRangeIsSpecified", CurrentRow.DemandRangeIsSpecified);
	FormParameters.Insert("Comment", CurrentRow.Comment);
	
	CallbackDescription = New CallbackDescription("AdjustSecurityCompletion",ThisObject);
	
	OpenForm("InformationRegister.CancelAdjustmentsOfSupplyPlans.Form.SupplyEditForm", FormParameters, ThisForm,,,,CallbackDescription);

EndProcedure

&AtClient
Procedure AdjustSecurityCompletion(Settings, AdditionalParameters) Export 
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	Modified = True;
	
	If Settings.SetAdjustment Then
		SetSecurityAdjustment(Settings)
	Else
		CancelProvisionAdjustmentOnClient(Items.ManufacturedProduct.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeRowChange(Item, Cancel)
	If FillInByShortage 
		And Item.CurrentItem.Name = "ManufacturedProductNumberOfPackages" Then
		
		AdjustSecurity();
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	If FillInByShortage  Then
		StandardProcessing = False;
		AdjustSecurity();
	EndIf;
EndProcedure

&AtClient
Procedure SetAdjustment(Command)
	AdjustSecurity();
EndProcedure

&AtClient
Procedure SetSecurityAdjustment(Settings)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	CurrentRow.Count = Settings.ToSupply_;
	CurrentRow.RangeOfDemandFrom = Settings.RangeOfDemandFrom;
	CurrentRow.RangeOfDemandTo = Settings.RangeOfDemandTo;
	CurrentRow.DemandRangeIsSpecified = True;
	CurrentRow.Comment = Settings.Comment;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, New Structure("RecalculateNumberOfPackages"), CachedValues);
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure CancelTheSecurityAdjustment(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	For Each RowID In SelectedRows Do
		SelectedRow = Object.ManufacturedProduct.FindByID(RowID);
			
		If SelectedRow.DemandRangeIsSpecified Then
			CancelProvisionAdjustmentOnClient(SelectedRow);
		EndIf;
	EndDo
	
EndProcedure

&AtClient
Procedure CancelAllAdjustments(Command)
	For Each String In Object.ManufacturedProduct Do
		If String.DemandRangeIsSpecified Then
			CancelProvisionAdjustmentOnClient(String);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure CancelProvisionAdjustmentOnClient(CurrentRow)
	
	RecordStructure = New Structure();
	RecordStructure.Insert("Plan",Object.Ref);
	RecordStructure.Insert("Products",CurrentRow.Products);
	RecordStructure.Insert("Characteristic",CurrentRow.Characteristic);
	RecordStructure.Insert("Purpose",CurrentRow.Purpose);
	RecordStructure.Insert("PlanningPeriod",Object.BeginOfPeriod);
	RecordStructure.Insert("ToSupply_",CurrentRow.Count);
	RecordStructure.Insert("RangeOfDemandFrom",CurrentRow.RangeOfDemandFrom);
	RecordStructure.Insert("RangeOfDemandTo",CurrentRow.RangeOfDemandTo);
	
	CancelProvisionAdjustmentOnServer(RecordStructure);
	
	CurrentRow.RangeOfDemandFrom = 0;
	CurrentRow.RangeOfDemandTo = 0;
	CurrentRow.DemandRangeIsSpecified = False;
	
EndProcedure

&AtServer
Procedure CancelProvisionAdjustmentOnServer(RecordStructure)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	RecordStructure.Insert("AdjustmentDate", CurrentSessionDate());
	RecordSet = InformationRegisters.CancelAdjustmentsOfSupplyPlans.CreateRecordSet();
	RecordSet.Filter.Plan.Set(RecordStructure.Plan);
	NewRecord = RecordSet.Add();
	FillPropertyValues(NewRecord, RecordStructure);
	RecordSet.Write();
	
	Items.TheCaptionThereAreCanceledSecurityAdjustments.Visible = True;
EndProcedure

&AtClient
Procedure ShowAdjustmentLines(Command)
	
	Items.ManufacturedProduct.RowFilter = New FixedStructure("DemandRangeIsSpecified", True);
	
EndProcedure

&AtClient
Procedure ShowAllItems(Command)
	
	Items.ManufacturedProduct.RowFilter = Undefined;
	
EndProcedure

&AtClient
Procedure DecorationCanceledSecurityAdjustmentsClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("ShowAssignment", Items.ManufacturedProductPurpose.Visible);
	FormParameters.Insert("Filter", New Structure("Plan", Object.Ref));
	
	OpenForm(
		"InformationRegister.CancelAdjustmentsOfSupplyPlans.Form.ListFormAccordingToPlan",
		FormParameters,
		ThisObject);
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
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
