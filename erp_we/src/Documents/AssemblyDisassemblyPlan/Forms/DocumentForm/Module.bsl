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
		FillPropertyValues(Object, PlanViewParameters,"FillInUsingFormula,Substitutional,FillInByShortage,BusinessOperation");
		
		ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario,
			"Periodicity, BudgetingScenario, DemandForMaterials");
		FillPropertyValues(Object, ScriptParameters_);
		
		If NumberOfPeriods > 0 And Not ValueIsFilled(Parameters.CopyingValue) Then
			PlanningClientServer.SetStartEndOfPlanPeriod(
				Object.Periodicity, 
				Object.BeginOfPeriod,  
				Object.PeriodEnding,
				CurrentSessionDate(),
				NumberOfPeriods);
		EndIf; 
		OnReadCreateAtServer();
		
		If PlanViewParameters.FillInByShortage = True Then
			Object.CrossTable = False;
			SwitchPeriodsToRowsOnServer(Undefined);
		EndIf;
		
		SetVisibility1();
		
	EndIf;
	
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
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
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
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Object.Substitutional And PlanReplacementControlOnServer(Object.Ref) Then
		SkipPeriodClosingCheck = True;
		ThisObject.Write();
		ThisObject.Read();
		SkipPeriodClosingCheck = False;
	EndIf;
	
	UpdateDisplayOfFillInDeficitAlertGroupOnClient();
	
	PlanningClient.PositionByLine(ThisForm, "GroupGoods", "Goods", "GoodsByDates");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	Planning.OnReadAtServer(ThisForm, CurrentObject);
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, False, FillingRuleAddress, CustomSettingsAddress);
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	OnReadCreateAtServer();
	
	If PlanViewParameters.FillInByShortage Then
		Object.CrossTable = False;
		SwitchPeriodsToRowsOnServer(Undefined);
	EndIf;
	
	SaveNewPeriodServer();
	
	SetVisibility1();
	
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
		"Document.AssemblyDisassemblyPlan.DocumentForm.Event.BeforeWrite");
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	WriteParameters.Insert("CachedValues", CachedValues);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CopyFromCrossTable(WriteParameters["CachedValues"], CurrentObject);
	
	Planning.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
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
	
	FillInServiceDetailsForProductInCollection();
	
	If Object.FillInUsingFormula Then
		ReadMoreParameters(CurrentObject);
	EndIf;
	
	SetVisibility1();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "AssemblyDisassemblyPlan");

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	ElsIf EventName = "WorkingWithExcelClient_DownloadFromExcel"
		And Parameter.FormUniqueID = ThisForm.UUID Then

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
			QueryText = NStr("vi = 'Nhu cầu về hàng hóa đã thay đổi, điền lại phần bảng?';
							|ru = 'Потребность в товарах изменилась, перезаполнить табличную часть?';
							|en = 'Demand for goods has changed, refill the table?'; fa = 'Demand for goods has changed, refill the table?';
							|it = 'Il fabbisogno di merci è cambiato, ricompilare la tabella?';
							|pl = 'Zapotrzebowanie na towary zmieniło się, wypełnić ponownie część tabelaryczną?';
							|tr = 'Ürünlere olan gereksinim değişti, tablo yeniden doldurulsun mu?'");
			Notification = New CallbackDescription("AdjustDemandCompletion", ThisObject, Parameter);
			ShowQueryBox(Notification, QueryText, Buttons);
			
		EndIf;
		
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Object.CrossTable Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("TablePresentation",NStr("vi = 'Hàng hóa';
															|ru = 'Товары';
															|en = 'Goods'; fa = 'کالاها';
															|it = 'Merci';
															|pl = 'Goods';
															|tr = 'Ürünler'"));
		StructureOfActions.Insert("TablePath","GoodsByDates");
		StructureOfActions.Insert("FillInProducts_1");
		StructureOfActions.Insert("FillInConfigurationOption");
		StructureOfActions.Insert("FillInWHCharacteristic");
		If FillInWarehouseInTabularForm Then
			StructureOfActions.Insert("FillInWarehouseInTabularForm");
		EndIf; 
		
		CheckParameters = New Structure;
		CheckParameters.Insert("TimeIntervals", ThisObject["TimeIntervals"].Unload(New Structure("Active_", True)));
		CheckParameters.Insert("FieldPrefix", "Count_");
		CheckParameters.Insert("FieldName", "NumberOfPackages");
		StructureOfActions.Insert("CheckingQuantityByPeriod", CheckParameters);
		
		StructureOfActions.Insert("GroupFields", "Products,Characteristic,Purpose,Package,Warehouse,ProductKit,RowCodeGoods");
		
		Planning.ProcessingFormFillVerification(GoodsByDates, StructureOfActions, Cancel, CheckedAttributes, Object.CrossTable); 
		
	Else
		
		NotCheckedAttributeArray.Add("GoodsByDates");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AssemblyDisassemblyPlan", , Object.Ref);
	
	ShortageRecalculationControlTimer = 1;
	UpdateDisplayOfFillInDeficitAlertGroupOnClient();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	If NotificationAfterRecording <> Undefined Then
	
		RunCallback(NotificationAfterRecording, True);
		NotificationAfterRecording = Undefined;
	
	EndIf;
	
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
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If Object.Substitutional 
		And (Object.CrossTable And GoodsByDates.Count() = 0
		Or Not Object.CrossTable And Object.Goods.Count() = 0)
		And Items.GroupPages.CurrentPage = Items.GroupGoods Then
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
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByDates", Notification);
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.FillInByShortage Then
		Object.BeginOfPeriod = Object.PeriodEnding;
	EndIf;
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByDates", Notification);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	WarehouseWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	
	OperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
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

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow Then
		SourceLineCode = CurrentData.RowCode;
		CurrentData.RowCode = NewProductLineCode(Object);
		CurrentData.Subassembly = False;
		CurrentData.RowCodeGoods = 0;
		CurrentData.ProductsKit = Undefined;
		CurrentData.CharacteristicSet = Undefined;
		If CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.Completed2") Then
			CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.ToPlan");
		EndIf; 
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	Object.FilledAutomatically = False;
	
	GoodsLineQuantity = Object.Goods.Count();
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf;
	
	GoodsLineQuantity = Object.Goods.Count();
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	KeyArray = New Array;
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		RowData = Items.Goods.RowData(SelectedRow);
		KeyArray.Add(RowData.RowCode);
		
	EndDo;
	
	GoodsLinesBeingDeletedKeyArray = New FixedArray(KeyArray);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ProductsAfterDeletionOnServer();
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",         CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner",      CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	PlanningClientServer.SetFormulaPresentation(ThisObject,CurrentRow);
	
	WhenChangingProductsOnServer();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	WhenChangingCharacteristicsOnServer();
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateQuantityForSubassembliesWhenItemChanges();
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateQuantityForSubCollections(
		CurrentRow.RowCode, 
		CurrentRow.ProductKit, 
		CurrentRow.DateOfAssemblyDisassembly, 
		CurrentRow.Count,
		CurrentRow.Canceled);
	
	CurrentRow.Details = String(CurrentRow.NumberOfPackages);
	Details = PlanningClient.GenerateDecryption(CurrentRow);
	
	If CurrentRow.Property("Deviation") And ValueIsFilled(CurrentRow.Formula) Then
		CalculationResult = PlanningClient.CalculateByFormula(CurrentRow.Formula, CurrentRow, Undefined, Undefined);
		CurrentRow.Deviation = CalculationResult.Result - CurrentRow.NumberOfPackages;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductKitOnChange(Item)
	
	ConfigurationOptionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	ProductsWarehouseWhenChangedOnServer();
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Field.Name = "GoodsProductsKit"
		Or Field.Name = "GoodsCharacteristicSet" Then
		GoToKit(StandardProcessing);
	ElsIf Field.Name = "GoodsPlanningASubassembly" Then
		ScheduleSubassembly(StandardProcessing);
	ElsIf Field.Name = "GoodsByDatesProducts" And CurrentData <> Undefined And CurrentData.Subassembly Then
		ShowValue(, CurrentData.Products);
	ElsIf Field.Name = "GoodsByDatesCharacteristic" And CurrentData <> Undefined And CurrentData.Subassembly Then
		ShowValue(, CurrentData.Characteristic);
	EndIf; 
	
EndProcedure

&AtClient
Procedure GoodsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.AssemblyDisassemblyPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCommentOnChange(Item)
	
	Items.Goods.CurrentData.PictureComment = ValueIsFilled(Items.Goods.CurrentData.Comment);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	If Not Object.FillInUsingFormula And Items.Goods.SelectedRows.Count() > 0 Then
		UBound = Items.Goods.SelectedRows.UBound();
		Details = PlanningClient.GenerateDecryption(Object.Goods.FindByID(Items.Goods.SelectedRows[UBound]));
	Else
		Details = "";
	EndIf;
EndProcedure

&AtClient
Procedure GoodsCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalParameters = New Structure("CurrentRow", Items.Goods.CurrentRow);
	Notification = New CallbackDescription("GoodsCommentStartChoiceCompletion", ThisObject, AdditionalParameters);
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
Procedure GoodsCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.Comment = EnteredText;
	CurrentData.PictureComment = ValueIsFilled(EnteredText);
	Modified = True;
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure GoodsDateOfAssemblyDisassemblyOnChange(Item)
	If Object.Substitutional
		And Object.Posted
		And SubstitutedPeriods.Count() > 0 Then
		CurrentData = Items.Goods.CurrentData;
		DateOfReceiptBeginningOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(CurrentData.DateOfAssemblyDisassembly, Object.Periodicity);
		Filter = New Structure("SubstitutedPeriod", DateOfReceiptBeginningOfPeriod);
		SubstitutedStringPeriod = SubstitutedPeriods.FindRows(Filter);
		If SubstitutedStringPeriod.Count() > 0 Then
			CurrentData.Substituted = SubstitutedStringPeriod[0].Substituted;
			CurrentData.SubstitutedToOrder = SubstitutedStringPeriod[0].SubstitutedToOrder;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsByDates

&AtClient
Procedure GoodsByDatesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.GoodsByDates.CurrentData;
	
	If NewRow Then
		SourceLineCode = CurrentData.RowCode;
		CurrentData.RowCode = NewProductLineCode(Object);
		CurrentData.Subassembly = False;
		CurrentData.RowCodeGoods = 0;
		CurrentData.ProductsKit = Undefined;
		CurrentData.CharacteristicSet = Undefined;
		If CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.Completed2") Then
			CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.ToPlan");
		EndIf; 
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsByDatesOnChange(Item)
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
	
	Object.FilledAutomatically = False;
	
	GoodsLineQuantity = GoodsByDates.Count();
	
EndProcedure

&AtClient
Procedure GoodsByDatesOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf;
	
	GoodsLineQuantity = GoodsByDates.Count();
	
EndProcedure

&AtClient
Procedure GoodsByDatesBeforeDeleteRow(Item, Cancel)
	
	If Object.FillInByShortage Then
		
		Cancel = True;
		DescriptionOfTheAlert = New CallbackDescription("GoodsBeforeDeleteRowCompletion", ThisObject);
		
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
	
	KeyArray = New Array;
	
	For Each SelectedRow In Items.GoodsByDates.SelectedRows Do
		
		RowData = Items.GoodsByDates.RowData(SelectedRow);
		KeyArray.Add(RowData.RowCode);
		
	EndDo;
	
	GoodsLinesBeingDeletedKeyArray = New FixedArray(KeyArray);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = Items.Goods.SelectedRows;
	For Each RowID In SelectedRows Do
		SelectedRow = Object.Goods.FindByID(RowID);
		
		SelectedRow.Count = 0;
		SelectedRow.NumberOfPackages = 0;
		SelectedRow.DemandRangeIsSpecified = True;
		SelectedRow.RangeOfDemandFrom = 0;
		SelectedRow.RangeOfDemandTo = 0;
	EndDo
	
EndProcedure

&AtClient
Procedure GoodsByDatesAfterDeleteRow(Item)
	
	ProductsAfterDeletionOnServer();
	
EndProcedure

&AtClient
Procedure GoodsByDatesProductsOnChange(Item)
	
	CurrentRow = Items.GoodsByDates.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",         CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner",      CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "GoodsByDates"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	PlanningClientServer.SetFormulaPresentation(ThisObject,CurrentRow);
	
	WhenChangingProductsOnServer();
	
EndProcedure

&AtClient
Procedure GoodsByDatesCharacteristicOnChange(Item)
	
	WhenChangingCharacteristicsOnServer();
	
EndProcedure

&AtClient
Procedure GoodsByDatesPackageOnChange(Item)
	
	CalculateQuantityForSubassembliesWhenItemChanges();
	
EndProcedure

&AtClient
Procedure GoodsByDatesProductKitOnChange(Item)
	
	ConfigurationOptionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure GoodsByDatesWarehouseOnChange(Item)
	
	ProductsWarehouseWhenChangedOnServer();
	
EndProcedure

// Parameters:
// 	Item - FormField -
&AtClient
Procedure Attachable_WhenChangingQuantity(Item)
	
	RowOfGoods = Items.GoodsByDates.CurrentData;
	
	WhenChangingAmountOfRowSum(ThisForm, RowOfGoods);
	
	ColumnName = Mid(Item.Name, StrLen("GoodsByDates" + "Count_") + 1);
	ColumnNameQuantity = "Count_" + ColumnName;
	ColumnNameCanceled = "Canceled_" + ColumnName;
	CalculateQuantityForSubCollections(
			RowOfGoods.RowCode, 
			RowOfGoods.ProductKit, 
			ColumnName, 
			RowOfGoods[ColumnNameQuantity], 
			RowOfGoods[ColumnNameCanceled], 
			RowOfGoods.Package,
			RowOfGoods.Products);
			
	If Not Object.FillInUsingFormula Then
		RowOfGoods["Details_" + ColumnName] = String(RowOfGoods["Count_" + ColumnName]);
		Details = PlanningClient.GenerateDecryption(RowOfGoods, "Details_" + ColumnName);
	EndIf;
	
	If Object.FillInUsingFormula Then
		WhenChangingQuantityDeviation(RowOfGoods);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsByDatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.GoodsByDates.CurrentData;				
	
	If Field.Name = "GoodsByDatesProductsKit"
		Or Field.Name = "GoodsByDatesCharacteristicSet" Then
		GoToKit(StandardProcessing);
	ElsIf Field.Name = "GoodsByDatesPlanningASubassembly" Then
		ScheduleSubassembly(StandardProcessing);
	ElsIf Field.Name = "GoodsByDatesProducts" And CurrentData <> Undefined And CurrentData.Subassembly Then
		ShowValue(, CurrentData.Products);
	ElsIf Field.Name = "GoodsByDatesCharacteristic" And CurrentData <> Undefined And CurrentData.Subassembly Then
		ShowValue(, CurrentData.Characteristic);
	EndIf; 
	
EndProcedure

&AtClient
Procedure GoodsByDatesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.AssemblyDisassemblyPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField -
&AtClient
Procedure Attachable_OnChangeCanceled(Item)
	
	RowOfGoods = Items.GoodsByDates.CurrentData;
	
	WhenChangingAmountOfRowSum(ThisForm, RowOfGoods);
	
	ColumnName = Mid(Item.Name, StrLen("GoodsByDates" + "Canceled_") + 1);
	ColumnNameQuantity = "Count_" + ColumnName;
	ColumnNameCanceled = "Canceled_" + ColumnName;
	CalculateQuantityForSubCollections(
			RowOfGoods.RowCode, 
			RowOfGoods.ProductKit, 
			ColumnName, 
			RowOfGoods[ColumnNameQuantity], 
			RowOfGoods[ColumnNameCanceled], 
			RowOfGoods.Package,
			RowOfGoods.Products);
			
	If Object.FillInUsingFormula Then
		WhenChangingQuantityDeviation(RowOfGoods);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingComment(Item)
	
	CurrentData = Items.GoodsByDates.CurrentData;
	
	If CurrentData <> Undefined And Items.GoodsByDates.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByDates.CurrentItem.Name = "GoodsByDates" + "Comment_"+Period.ColumnName Then
				
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
	
	CurrentData = Items.GoodsByDates.CurrentData;
	StandardProcessing = False;
	
	If CurrentData <> Undefined And Items.GoodsByDates.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByDates.CurrentItem.Name = "GoodsByDates" + "Comment_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				
				AdditionalParameters = New Structure("CurrentRow, ColumnName", 
					Items.GoodsByDates.CurrentRow,
					Period.ColumnName);
				Notification = New CallbackDescription("Attachable_StartOfCommentSelectionCompletion", ThisObject, AdditionalParameters);
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
	
	CurrentData = GoodsByDates.FindByID(AdditionalParameters.CurrentRow);
	CurrentData["Comment_"+ AdditionalParameters.ColumnName] = EnteredText;
	CurrentData["PictureComment_"+ AdditionalParameters.ColumnName] = ValueIsFilled(CurrentData["Comment_"+ AdditionalParameters.ColumnName]);
	Modified = True;
	
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
		"Document.AssemblyDisassemblyPlan.DocumentForm.Command.SelectGoods");
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);

	If FillInWarehouse Then
		FormParameters.Insert("Warehouse",                                   Object.Warehouse);
	EndIf; 
	If FillInWarehouseInTabularForm Then
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("AllWarehouseBalance",                      True);
	EndIf; 
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	FormParameters.Insert("HideManualDiscounts", True);

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
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CurrentRow.Details = "";
		NewRow.Details = "";
		
		UpdateRelatedItemDetails(Object, ThisForm);
		
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
		
		NumberOfProductsBeforeInsertion = Object.Goods.Count();
		
		GetLinesFromClipboard();
		
		NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
		ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	EndIf;
		
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
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
		FormTable = Items.Goods;
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

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure ScheduleSubassembliesCommand(Command)
	
	If Not ScheduleSubassembliesOnServer(CachedValues) Then
		ShowMessageBox(, NStr("vi = 'Không cần lập kế hoạch đóng bộ.';
								|ru = 'Планирование подсборки не требуется.';
								|en = 'Subassembly scheduling is not required.'; fa = 'Subassembly scheduling is not required.';
								|it = 'La pianificazione di sottolivello di assemblaggio non è richiesta.';
								|pl = 'Planowanie podzespołów nie jest wymagane.';
								|tr = 'Alt montajların planlaması gerekli değil.'"));
	EndIf; 
	
EndProcedure

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	AdditionalParameters = PlanningClient.AdditionalParametersForDownloadingFromFile();
	AdditionalParameters.PlanType               = "AssemblyDisassemblyPlan";
	AdditionalParameters.AssignmentsAreUsed = FillInAssignmentInTabularForm;
	AdditionalParameters.WarehousesAreUsed     = FillInWarehouseInTabularForm;
	
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
	
	ProcessingWithExcelClient.SelectAttachedExcelFile(ThisForm, ?(Object.CrossTable, "GoodsByDates", "Goods"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToColumns(Command)
	
	If Not Object.CrossTable Then
		// To the cross-table
		
		ErrorCheckingDateOfTSPeriod = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "Goods");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Bộ đóng gói';
																|ru = 'Комплекты';
																|en = 'Kits'; fa = 'کیت‌ها';
																|it = 'Kit';
																|pl = 'Kits';
																|tr = 'Ürün setleri'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfAssemblyDisassembly");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày đóng bộ (tách bộ)';
																|ru = 'Дата сборки (разборки)';
																|en = 'Date of kitting'; fa = 'تاریخ کیت‌سازی';
																|it = 'Data di assemblaggio (disassemblaggio)';
																|pl = 'Data montażu (demontażu)';
																|tr = 'Montaj (demontaj) tarihi'"));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, ErrorCheckingDateOfTSPeriod, CheckParameters);
		
		TheStructureOfTheSearch = New Structure("Subassembly", True);
		ListOfSubassemblies = Object.Goods.FindRows(TheStructureOfTheSearch);
		
		If ErrorCheckingDateOfTSPeriod Or ListOfSubassemblies.Count() <> 0 Then
			
			QueryText = NStr("vi = 'Khi chuyển đổi, sẽ xóa dữ liệu sau:';
							|ru = 'При переключении будут удалены следующие данные:';
							|en = 'The following data will be removed while switching:'; fa = 'The following data will be removed while switching:';
							|it = 'Durante il passaggio i seguenti dati verranno eliminati:';
							|pl = 'Podczas przełączania następujące dane zostaną usunięte:';
							|tr = 'Değiştirmede sıradaki veriler silinecek:'");
			If ErrorCheckingDateOfTSPeriod Then
				QueryText = QueryText + Chars.LF + NStr("vi = '- bộ đóng gói mà có ngày đóng bộ (tách bộ) trong khoảng thời gian lập kế hoạch.';
														|ru = '- комплекты, для которых дата сборки (разборки) за границами планирования.';
														|en = '- kits for which a date of kitting is outside the planning fences.'; fa = '- kits for which a date of kitting is outside the planning fences.';
														|it = '- i kit per i quali la data di assemblaggio (disassemblaggio) è oltre i limiti di pianificazione.';
														|pl = '- zestawy, dla których data montażu (demontażu) wykracza poza granice planowania.';
														|tr = '- planlama sınırlarının montajları (demontajları) için setler.'");
			EndIf;
			If ListOfSubassemblies.Count() <> 0 Then
				QueryText = QueryText + Chars.LF + NStr("vi = '- tất cả giao dịch đóng bộ dự tính.';
														|ru = '- все запланированные подсборки.';
														|en = '- all planned subassemblies.'; fa = '- all planned subassemblies.';
														|it = '- tutti i sottolivelli di assemblaggio pianificati.';
														|pl = '- wszystkie zaplanowane podzespoły.';
														|tr = '-planlanan tüm alt montajlar.'");
			EndIf;
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam et'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
			
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
		SwitchFromCrossTable(CachedValues);
		Object.CrossTable = False;
		FillInServiceDetailsForProductInCollection();
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheProducts(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;

	If DisableEditingOfPopulationSettings Then
		SetUpFormulaAndFillIn(SettingsStructure, Undefined);
		Return;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan");
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
	FormParameters.Insert("PlanByAmount",				False);
	
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
Procedure ChangeByPercentage(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ChangeByPercentageCompletion", ThisObject);
	
	PlanningClient.ChangeFormulaToPercentage(
		ThisForm, 
		?(Object.CrossTable, GoodsByDates, Object.Goods), 
		?(Object.CrossTable, "GoodsByDates", "Goods"),
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
		?(Object.CrossTable, GoodsByDates, Object.Goods), 
		?(Object.CrossTable, "GoodsByDates", "Goods"),
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
			
			If Items.GoodsByDates.CurrentData = Undefined Then
				Return;
			EndIf;
			
			CurElementName = Items.GoodsByDates.CurrentItem.Name;
			
			If StrFind(CurElementName, "GoodsByDates" + "Count_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'"));
				Return;
			EndIf;
			
			If CurElementName = "GoodsByDates" + "Count_" + Period.ColumnName Then
				
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
				
				CallbackDescription = New CallbackDescription("AfterQuestionSetArbitraryFormula", ThisObject, AdditionalParameters);
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
				
			EndIf;
			
		Else
			
			If (Object.CrossTable And Items.GoodsByDates.CurrentData = Undefined) 
				Or (Not Object.CrossTable And Items.Goods.CurrentData = Undefined) Then
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
		PlanningClient.CancelPlanLines(ThisForm, GoodsByDates, "GoodsByDates", Notification);
	Else
		PlanningClient.CancelPlanLines(ThisForm, Object.Goods, "Goods", Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAWarehouseByTheValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.GoodsByDates.SelectedRows,Items.Goods.SelectedRows);
	GoodsTable = ?(Object.CrossTable, GoodsByDates, Object.Goods);
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, GoodsTable, NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Articoli';
																								|pl = 'Goods';
																								|tr = 'Ürünler'"), SelectedRows) Then
		FilterStructure1 = New Structure("IsFolder", False);
		ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", FilterStructure1, FoldersAndItemsUse.Items);
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm", 
			ParametersStructure, 
			ThisForm,
			UUID,
			,
			,
			New CallbackDescription("FillInByCompletionValue",
				PlanningClient,
				New Structure("SelectedRows, GoodsTable, Column", SelectedRows, GoodsTable, "Warehouse")), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAssignmentByValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.GoodsByDates.SelectedRows,Items.Goods.SelectedRows);
	GoodsTable = ?(Object.CrossTable, GoodsByDates, Object.Goods);
	
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

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsByDatesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "GoodsByDates.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "GoodsByDatesCharacteristic",
																		     "GoodsByDates.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"GoodsByDatesPurpose",
																			"GoodsByDates.ItemsType",
																			False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,,False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Substituted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Highlighting the subassembly with color

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Subassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);

	// Highlighting the subassembly with color

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDates.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.Subassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);

	// You cannot change a row with a subassembly

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDateOfAssemblyDisassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Subassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// You cannot change a row with a subassembly

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDatesProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDatesCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.Subassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Subassembly "Not required"

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.NotRequired;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// The "Completed" subassembly

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.Completed2;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveTaskCompletionFlag);
		
	// The "Plan" subassembly

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.ToPlan;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);

	// The subassembly of the goods is "Not required"

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDatesPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.NotRequired;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không cần';
													|ru = 'Не требуется';
													|en = 'Not required'; fa = 'لازم نیست';
													|it = 'Non è richiesto';
													|pl = 'Nie jest wymagane';
													|tr = 'Gerekli değil'"));
		
	// Subassembly of the goods to the "Completed" certificates

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDatesPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.Completed2;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveTaskCompletionFlag);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã thực hiện';
													|ru = 'Выполнено';
													|en = 'Completed'; fa = 'تکمیل‌شده';
													|it = 'Completato';
													|pl = 'Wykonano';
													|tr = 'Tamamlandı'"));
		
	// Subassembly of the goods to the "Plan" recipients

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByDatesPlanningASubassembly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.PlanningASubassembly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SubassemblySchedulingStatuses.ToPlan;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dự định';
													|ru = 'Запланировать';
													|en = 'To plan'; fa = 'برای برنامه‌ریزی';
													|it = 'Programmare';
													|pl = 'Zaplanuj';
													|tr = 'Planla'"));

EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfCrossTable()
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	CurrentFont = Items.GoodsByDates.Font;
	StrikethroughFont = New Font(CurrentFont,,,,,,True);
	
	ActivePeriods = ThisObject["TimeIntervals"].FindRows(New Structure("Active_", True));
	ThisIsOnePeriod = ActivePeriods.Count() = 1;
	For Each Period In ActivePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf;
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("GoodsByDates" + "Count_" + Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.Canceled_"+Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("Font", StrikethroughFont);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("GoodsByDates" + "Count_" + Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("GoodsByDates.Substituted_"+ Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
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
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByDates", Notification);
	
EndProcedure

&AtServer
Procedure SwitchFromCrossTable(CachedValues)

	CopyFromCrossTable(CachedValues, Object);
	
	ProcessProductsAfterSwitchingFromCrossTable();
	
EndProcedure

&AtClient
Procedure WhenChangingPeriodsOnClient(Result, AdditionalParameters) Export 
	
	WhenChangingPeriodsOnServer();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductInCollection()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
				New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
				New Structure("Products", "SKU"));
				
	ProductsServer.FillInServiceDetailsForProductInCollection(
		?(Object.CrossTable Or PlannedBalanceIsUsed, GoodsByDates, Object.Goods),
		StructureOfActions);
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
	
		For Each TSRow In GoodsByDates Do
			For Each Period In ThisObject["TimeIntervals"] Do
				If Not Period.Active_ Then
					Continue;
				EndIf;
				TSRow["PictureComment_"+ Period.ColumnName] = ValueIsFilled(TSRow["Comment_"+ Period.ColumnName]);
			EndDo; 
		EndDo; 
		
	Else
		For Each TSRow In Object.Goods Do
			TSRow.PictureComment = ValueIsFilled(TSRow.Comment);
		EndDo; 
	
	EndIf;
	
	NotIncluded();
	DefineSubassemblyPlanning();
	
EndProcedure

// The procedure fills the period table with dates to get the order and forms the fields of the cross-table.
&AtServer
Procedure WhenChangingPeriodsOnServer(AdjustStartEndOfPeriod = False)
	
	If AdjustStartEndOfPeriod Then
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod,  Object.PeriodEnding, CurrentSessionDate());
	EndIf; 
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	If Object.Substitutional
		And ValueIsFilled(Object.Periodicity) Then
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
		
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "AssemblyDisassemblyPlan");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	TablePeriods See Planning.TablePeriods
// 	RecalculateTotals_ - Boolean - LongDesc
&AtServer
Procedure UpdateCrossTableStructure(TablePeriods, RecalculateTotals_ = True)
	
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	ThisIsOnePeriod = NumberOfPeriods = 1;
	
	Items.GoodsDateOfAssemblyDisassembly.ChoiceList.Clear();
	For Each Period In TablePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf; 
		Items.GoodsDateOfAssemblyDisassembly.ChoiceList.Add(BegOfDay(Period.StartDate), Period.Title);
	EndDo; 
	
	Items.GoodsByDatesNumberOfPackages.Visible = Not ThisIsOnePeriod;
	
	Items.CellComment.Visible = Object.CrossTable And Not ThisIsOnePeriod;
	Items.CellIsCanceled.Visible = Object.CrossTable And Not ThisIsOnePeriod;
	
	If Not Object.CrossTable 
		And Not PlannedBalanceIsUsed Then
		ValueToFormAttribute(TablePeriods,"TimeIntervals");
		SaveNewPeriodServer();
		UpdateReplacementAttribute();
		Return;
	EndIf;
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "GoodsByDates");
	OutputParameters.Insert("CrossTableFormElement", "GoodsByDates");
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
	Planning.AddReplacedToOrderCrossTableField(OutputParameters, False, StructureOfActions);

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
	
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	
	SetConditionalAppearance();
	SetConditionalAppearanceOfCrossTable();
	
	If RecalculateTotals_ Then
		CalculateTotals_(ThisForm);
	EndIf;
	
EndProcedure

// Performs the processing of the document after switching of the cross-table
// - eliminates duplicate line code in PM Products
// - updates the Association of subassemblies with kits.
//
&AtServer
Procedure ProcessProductsAfterSwitchingFromCrossTable()

	For Each ProductLineByDate In GoodsByDates Do
		
		TheStructureOfTheSearch = New Structure("RowCode", ProductLineByDate.RowCode);
  		ListOfProductLines = Object.Goods.FindRows(TheStructureOfTheSearch);
		
		For Cnt = 1 To ListOfProductLines.Count() - 1 Do
			LineProducts_ = ListOfProductLines[Cnt];
			LineProducts_.RowCode = NewProductLineCode(Object);
			
			// If there are subassemblies for the kit, then we will update the connection
			TheStructureOfTheSearch = New Structure("RowCodeGoods,DateOfAssemblyDisassembly", 
											ListOfProductLines[0].RowCode, LineProducts_.DateOfAssemblyDisassembly);
			ListOfSubassemblyRows_ = Object.Goods.FindRows(TheStructureOfTheSearch);
			For Each RowSubassembly In ListOfSubassemblyRows_ Do
				RowSubassembly.RowCodeGoods = LineProducts_.RowCode;
			EndDo; 
		EndDo; 
		
	EndDo;	

EndProcedure

// Performs document processing after switching to the crosstab
// - deletes subassemblies
// - collapses products.
//
&AtServer
Procedure ProcessProductsBeforeSwitchingToCrossTable()

	// Delete the subassemblies
	TheStructureOfTheSearch = New Structure("Subassembly", True);
	ListOfSubassemblies = Object.Goods.FindRows(TheStructureOfTheSearch);
	For Each RowSubassembly In ListOfSubassemblies Do
		Object.Goods.Delete(RowSubassembly);
	EndDo; 
	
	// Collapse the goods
	GroupFields = "Products,Characteristic,Package,Warehouse,ProductKit";
	GoodsTable = Object.Goods.Unload(, GroupFields);
	GoodsTable.GroupBy(GroupFields);
	For Each LineProducts_ In GoodsTable Do
		TheStructureOfTheSearch = New Structure(GroupFields);
		FillPropertyValues(TheStructureOfTheSearch, LineProducts_);
		ListOfProductLines = Object.Goods.FindRows(TheStructureOfTheSearch);
		For Cnt = 1 To ListOfProductLines.Count() - 1 Do
			LineProductsCurrent = ListOfProductLines[Cnt];
			LineProductsCurrent.RowCode = ListOfProductLines[0].RowCode;
		EndDo;
	EndDo; 
	
EndProcedure

&AtClient
Procedure SetCancelAndCommentCells()
	
	CellFound = False;
	
	CurrentData = Items.GoodsByDates.CurrentData;
	If CurrentData = Undefined Then
		CellIsCanceled = False;
		CellComment = "";
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf; 
	
	If Items.GoodsByDates.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByDates.CurrentItem.Name = "GoodsByDates" + "Count_" + Period.ColumnName Then
				
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
	
	Items.CellIsCanceled.Enabled = CellFound;
	Items.CellComment.Enabled = CellFound;
	
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
		SelectedRows = Items.GoodsByDates.SelectedRows;
	Else
		SelectedRows = Items.Goods.SelectedRows;
	EndIf; 
	
	If SelectedRows.Count() > 0 Then
		CalculateTotals_(ThisForm);
	EndIf; 
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	If Object.CrossTable Then
		ProcessingOfTabularForms.CopyRowsToClipboard(GoodsByDates, Items.GoodsByDates.SelectedRows);
	Else
		ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,
		|DateOfAssemblyDisassembly,ProductKit,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfGoods In TableOfGoods Do
		
		If Object.CrossTable Then
			CurrentRow = GoodsByDates.Add();
			FillPropertyValues(CurrentRow, RowOfGoods);
			CurrentRow.RowCode = NewProductLineCode(Object);
		Else
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfGoods);
			CurrentRow.RowCode = NewProductLineCode(Object);
			
			RowsToProcess.Add(CurrentRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
		GoodsLineQuantity = GoodsByDates.Count();
	Else
		GoodsLineQuantity = Object.Goods.Count();
	EndIf;
	
	FillInServiceDetailsForProductInCollection();
	
	If Object.CrossTable Then
		CalculateTotals_(ThisForm);
	EndIf;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	ItemArray.Add("GoodsByDatesInsertRows");
	ItemArray.Add("GoodsByDatesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	ItemArray.Add("GoodsByDatesInsertRows");
	ItemArray.Add("GoodsByDatesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region ProcessingWithExcel

&AtServer
Function LoadFromExcelOnServer(ArrayOfDataStructures)
	
	Object.MaximumRowCodeGoods = 0;
	If Object.CrossTable Then
		GoodsByDates.Clear();
	Else
		Object.Goods.Clear();
	EndIf; 
	
	Object.FilledAutomatically = False;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	// Loading Plan data
	For Each ProductStructure_1 In ArrayOfDataStructures Do
		
		If Not ValueIsFilled(ProductStructure_1.ProductID_) Then
			Continue;
		EndIf;
		
		ProductStructure_1.Insert("Products",   Catalogs.Products.GetRef(New UUID(ProductStructure_1.ProductID_)));
		
		If Not ValueIsFilled(ProductStructure_1.Products) Then
			Continue;
		EndIf;
		
		ProductStructure_1.Insert("Characteristic",      Catalogs.ItemsCharacteristics.GetRef(New UUID(ProductStructure_1.IdentifierCharacteristic)));
		ProductStructure_1.Insert("Package",            Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.PackageIdentifier)));
		ProductStructure_1.Insert("Warehouse",               Catalogs.Warehouses.GetRef(New UUID(ProductStructure_1.WarehouseID_)));
		ProductStructure_1.Insert("ProductKit", Catalogs.ProductKitConfigurations.GetRef(New UUID(ProductStructure_1.IdConfigurationOption)));
		ProductStructure_1.Insert("Purpose",          Catalogs.Assignments.GetRef(New UUID(ProductStructure_1.DestinationID_)));
		
		If Object.CrossTable Then
			CurrentRow = GoodsByDates.Add();
			FillPropertyValues(CurrentRow, ProductStructure_1);
		Else
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, ProductStructure_1);
			
			RowsToProcess.Add(CurrentRow);
		EndIf;
		CurrentRow.RowCode = NewProductLineCode(Object);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
		GoodsLineQuantity = GoodsByDates.Count();
	Else
		GoodsLineQuantity = Object.Goods.Count();
	EndIf;
	
	FillInServiceDetailsForProductInCollection();
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
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
		ImportParameters.PlanProfile           = Object.PlanProfile;
		ImportParameters.CrossTable       = Object.CrossTable;
		ImportParameters.AddressOfThePeriodTable = GetAddressOfPeriodTable();
		ImportParameters.GoodsTableAddress  = PutToTempStorage(DownloadData, UUID);
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		
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
			Object.MaximumRowCodeGoods = 0;
			GoodsByDates.Clear();
			Object.Goods.Clear();
		EndIf;
		GetUploadedProductsFromStorage(ImportedDataAddress);
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
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Tùy chọn)';
							|ru = 'Уникальный идентификатор (Комплектация)';
							|en = 'Unique ID (Product kit)'; fa = 'شناسه یکتا (کیت محصول)';
							|it = 'Identificatore univoco (Componenti)';
							|pl = 'Indywidualny identyfikator (Kompletacja)';
							|tr = 'Benzersiz tanımlayıcı (Ürün seti)'"),"IdConfigurationOption");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Kho)';
							|ru = 'Уникальный идентификатор (Склад)';
							|en = 'Unique ID (Warehouse)'; fa = 'شناسه یکتا (انبار)';
							|it = 'Identificatore unico (Magazzino)';
							|pl = 'Indywidualny identyfikator (Magazyn)';
							|tr = 'Benzersiz tanımlayıcı (Ambar)'"),"WarehouseID_");
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
							|en = 'Item'; fa = 'قلم';
							|it = 'Articolo';
							|pl = 'Produkt';
							|tr = 'Ürün'"),"ImportedProducts");
	SearchColumns.Add(NStr("vi = 'Đặc tính';
							|ru = 'Характеристика';
							|en = 'Variant'; fa = 'گونه';
							|it = 'Caratteristica';
							|pl = 'Charakterystyka';
							|tr = 'Varyant'"),"ImportedCharacteristic");
	SearchColumns.Add(NStr("vi = 'Đóng bộ';
							|ru = 'Комплектация';
							|en = 'Product kit'; fa = 'کیت کالا';
							|it = 'Componenti';
							|pl = 'Kompletacja';
							|tr = 'Ürün seti'"),"ImportedProductKit");
	If FillInWarehouseInTabularForm Then
		SearchColumns.Add(NStr("vi = 'Kho bãi';
								|ru = 'Склад';
								|en = 'Warehouse'; fa = 'Warehouse';
								|it = 'Magazzino';
								|pl = 'Magazyn';
								|tr = 'Ambar'"),"ImportedWarehouse");
	EndIf; 
	If FillInAssignmentInTabularForm Then
		SearchColumns.Add(NStr("vi = 'Ấn định';
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
		
		SearchColumns.Add(NStr("vi = 'Ngày đóng bộ (tách bộ)';
								|ru = 'Дата сборки (разборки)';
								|en = 'Date of kitting'; fa = 'تاریخ کیت‌سازی';
								|it = 'Data di assemblaggio (disassemblaggio)';
								|pl = 'Data montażu (demontażu)';
								|tr = 'Montaj (demontaj) tarihi'"),"DateOfAssemblyDisassembly");
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
	TheStructureOfTheSearch.Insert("IdConfigurationOption",0);
	TheStructureOfTheSearch.Insert("WarehouseID_",0);
	TheStructureOfTheSearch.Insert("DestinationID_",0);
	
	ExcelActionStructure.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
	
	ExcelActionStructure.Insert("DataStartLineNumber", 3);
	
	Return ExcelActionStructure;

EndFunction 

#EndRegion

#Region WorkingWithEquipment

&AtServer
Procedure ConfigurationOptionWhenChangingOnServer()
	
	If Object.CrossTable Then
		CurrentRow = Items.GoodsByDates.CurrentRow;
		CurrentData = GoodsByDates.FindByID(CurrentRow);
	Else
		CurrentRow = Items.Goods.CurrentRow;
		CurrentData = Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	KeyArray = New Array;
	KeyArray.Add(CurrentData.RowCode);
	RemoveSubassemblies(KeyArray);
	
	If ValueIsFilled(CurrentData.ProductKit) Then
		DefineSubassemblyPlanning(CurrentData.RowCode);
	Else
		CurrentData.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired;
	EndIf;
	
EndProcedure

&AtServer
Procedure DetermineConfigurationOption(ListOfProductLines = Undefined)

	If Object.CrossTable Then
		GoodsTable = GoodsByDates.Unload(ListOfProductLines, "Products,Characteristic, ProductKit");
	Else
		GoodsTable = Object.Goods.Unload(ListOfProductLines, "Products,Characteristic, ProductKit");
	EndIf;
	
	If ListOfProductLines <> Undefined Then
		ListOfRowsReadyForProcessing = ListOfProductLines;
	Else
		If Object.CrossTable Then
			ListOfRowsReadyForProcessing = GoodsByDates;
		Else
			ListOfRowsReadyForProcessing = Object.Goods;
		EndIf;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	CAST(GoodsTable.ProductKit AS Catalog.ProductKitConfigurations) AS ProductKit
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	GoodsTable.Products                           AS Products,
	|	GoodsTable.Characteristic                         AS Characteristic,
	|	ProductKitConfigurations.Ref              AS ProductKit,
	|	ProductKitConfigurations.Main            AS Main
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON GoodsTable.Products = ProductKitConfigurations.Owner
	|			AND GoodsTable.Characteristic = ProductKitConfigurations.Characteristic
	|			AND (GoodsTable.ProductKit = ProductKitConfigurations.Ref
	|				OR GoodsTable.ProductKit = VALUE(Catalog.ProductKitConfigurations.EmptyRef)
	|				OR GoodsTable.ProductKit.Owner <> GoodsTable.Products)
	|			AND (NOT ProductKitConfigurations.DeletionMark)";
	
	Query.SetParameter("GoodsTable", GoodsTable);
	
	TableConfigurationOptions = Query.Execute().Unload();
	TableConfigurationOptions.Indexes.Add("Products,Characteristic");
	
	DetailsToFillIn = "ProductKit,PackagingEquipment,QuantityEquipment,NumberOfPackagesCompleteSet";
	
	For Each RowGoods In ListOfRowsReadyForProcessing Do
		TheStructureOfTheSearch = New Structure("Products,Characteristic", RowGoods.Products, RowGoods.Characteristic);
  		ListOfConfigurationOptions = TableConfigurationOptions.FindRows(TheStructureOfTheSearch);
		KitConfigurations = New Array;
		For Each StringConfigurationOption In ListOfConfigurationOptions Do
			If StringConfigurationOption.Main Then
				KitConfigurations.Clear();
				KitConfigurations.Add(StringConfigurationOption);
				Break;
			Else
				KitConfigurations.Add(StringConfigurationOption);
			EndIf;
		EndDo;
		
		If KitConfigurations.Count() = 1 Then
			// The configuration option should be the main or the only one
			RowGoods.ProductKit = KitConfigurations[0].ProductKit;
		Else
			RowGoods.ProductKit = Catalogs.ProductKitConfigurations.EmptyRef();
		EndIf; 
	EndDo;
	
EndProcedure

&AtServer
Function ScheduleSubassembliesOnServer(CachedValues, ProcessStringCode = 0)
	
	ThereAreSubassemblies = False;
	
	// Let's remember the current line so that we can restore it later
	If Object.CrossTable Then
		CurLineCode_ = Undefined;
		CurrentRow = Items.GoodsByDates.CurrentRow;
		If CurrentRow <> Undefined Then
			CurItemLine = GoodsByDates.FindByID(CurrentRow);
		EndIf; 
		If CurItemLine <> Undefined Then
			CurLineCode_ = CurItemLine.RowCode;
		EndIf; 
	EndIf; 
	
	Initial_Quantity = Object.Goods.Count();
	
	// Moving the data from the cross-table to the Products table
	CopyFromCrossTable(CachedValues, Object);

	MatchingCode = New Map();
	For Each String In Object.Goods Do
		
		MatchingProducts = New Map();
		MatchingProducts.Insert(String.Products, String.Characteristic);
		
		MatchingCode.Insert(String.RowCode, MatchingProducts);
	EndDo;
	TableSourceComponents = ComponentsOfUnplannedSubassemblies(ProcessStringCode);
	
	While TableSourceComponents.Count() <> 0 Do
		
		PodsobrkiAndAccessories = PodsobrkiAndAccessories(TableSourceComponents);
		
		TableSourceComponents.Clear();
		
		TableConfigurationOptions = PodsobrkiAndAccessories.TableConfigurationOptions;
		TableConfigurationOptions.Indexes.Add("Products,Characteristic");
		
		TableComponents = PodsobrkiAndAccessories.TableComponents;
		TableComponents.Indexes.Add("ProductKit");
		
		SubassemblyTable = PodsobrkiAndAccessories.SubassemblyTable;
		
		PreviousString = Undefined;
		// Adding subassemblies to Products
		For Each RowSubassembly In SubassemblyTable Do
			LineProducts_ = Object.Goods.Add();
			FillPropertyValues(LineProducts_, RowSubassembly);
			LineProducts_.RowCodeGoods = RowSubassembly.RowCodeGoods;
			LineProducts_.Subassembly       = True;
			
			DefineLineCodeAndFillItIn = True;
			If Object.CrossTable Then
				// In the cross-table mode, the code strings and the options are the same
				TheStructureOfTheSearch = New Structure();
				TheStructureOfTheSearch.Insert("RowCodeGoods",RowSubassembly.RowCodeGoods);
				TheStructureOfTheSearch.Insert("Products",RowSubassembly.Products);
				TheStructureOfTheSearch.Insert("Characteristic",RowSubassembly.Characteristic);
				TheStructureOfTheSearch.Insert("Purpose",RowSubassembly.Purpose);
				
				StringsList = Object.Goods.FindRows(TheStructureOfTheSearch);
				For Each ProductsLineIsOriginal In StringsList Do
					If ProductsLineIsOriginal.RowCode <> 0 Then
						LineProducts_.RowCode           = ProductsLineIsOriginal.RowCode;
						LineProducts_.ProductKit = ProductsLineIsOriginal.ProductKit;
						
						DefineLineCodeAndFillItIn = False;
						Break;
					EndIf; 
				EndDo; 
			EndIf;
			
			If DefineLineCodeAndFillItIn Then
				
				LineProducts_.RowCode = NewProductLineCode(Object);
				
				// We will find the configuration option and add the components
				TheStructureOfTheSearch = New Structure("Products,Characteristic", 
												RowSubassembly.Products, RowSubassembly.Characteristic);
				ListOfConfigurationOptions_1 = TableConfigurationOptions.FindRows(TheStructureOfTheSearch);
				KitConfigurations = New Array;
				For Each StringConfigurationOption In ListOfConfigurationOptions_1 Do
					If StringConfigurationOption.Main Then
						KitConfigurations.Clear();
						KitConfigurations.Add(StringConfigurationOption);
						Break;
					Else
						KitConfigurations.Add(StringConfigurationOption);
					EndIf;
				EndDo;
				
				If KitConfigurations.Count() = 1 Then
					// The configuration option should be the main or the only one
					
					StringConfigurationOption = KitConfigurations[0];
					
					LineProducts_.ProductKit = StringConfigurationOption.ProductKit;
					
				EndIf;
				
			EndIf;
			
			MatchingProducts = MatchingCode.Get(LineProducts_.RowCodeGoods);
			If LineProducts_.Characteristic = MatchingProducts.Get(LineProducts_.Products)
				And Not (PreviousString <> Undefined And PreviousString.Products = LineProducts_.Products
				And PreviousString.Characteristic = LineProducts_.Characteristic
				And PreviousString.DateOfAssemblyDisassembly <> LineProducts_.DateOfAssemblyDisassembly) Then
				ErrorText = NStr("vi = 'Trong quá trình lập kế hoạch bảng kê chi tiết, đã tìm thấy vòng lặp phương án bảng kê chi tiết của mặt hàng ""%1, %2"". Lỗi trong thành phần bộ đóng gói ""%3"".
				|Đã dừng thực hiện.';
				|ru = 'В процессе планирования подсборок обнаружено зацикливание варианта комплектации номенклатуры ""%1, %2"". Ошибка в составе комплекта ""%3"".
				|Выполнение прервано.';
				|en = 'Looping of item kit configuration ""%1,%2"" is detected upon subassembly planning. There is an error in the kit ""%3"".
				|Execution is terminated.'; fa = 'Looping of item kit configuration ""%1,%2"" is detected upon subassembly planning. There is an error in the kit ""%3"".
				|Execution is terminated.';
				|it = 'Nel processo di pianificazione dei sottolivelli di assemblaggio è stato rilevato un loop nelle varianti di kit dell''articolo ""%1,%2"". Errore nella composizione del kit ""%3"".
				|Esecuzione interrotta.';
				|pl = 'Podczas planowania podzespołów wykryto zapętlenie wariantu kompletacji produktu ""%1, %2"". Błąd w zestawie kompletu ""%3"".
				|Wykonanie zostało przerwane.';
				|tr = 'Alt montaj planlama sürecindeki ""%1, %2"" ürünlerinde döngüsel set konfigürasyonu tespit edildi. ""%3"" set içeriğinde hata mevcut.
				|Gerçekleştirme işlemi kesintiye uğradı.'");
				
				SearchResult = Object.Goods.FindRows(New Structure("RowCode", LineProducts_.RowCodeGoods));
				ParentKit = "";
				If SearchResult.Count() <> 0 Then
					ParentKit = SearchResult[0].ProductKit;
				EndIf;
				
				If Not Object.CrossTable Then
					DeleteResultOfFillingIn(Object.Goods, Initial_Quantity);
				EndIf;
				
				Raise StrTemplate(ErrorText, LineProducts_.Products, LineProducts_.Characteristic, ParentKit);
			EndIf;
			
			If ValueIsFilled(MatchingProducts) Then
				NewMatchingProductRange = Common.CopyRecursive(MatchingProducts)
			Else
				NewMatchingProductRange = New Map();
			EndIf;
			
			NewMatchingProductRange.Insert(LineProducts_.Products, LineProducts_.Characteristic);
			
			MatchingCode.Insert(LineProducts_.RowCode, NewMatchingProductRange);
			
			// We will add components for re-planning the subassembly
			TheStructureOfTheSearch = New Structure("ProductKit", LineProducts_.ProductKit);
			ListOfSubassemblyComponents = TableComponents.FindRows(TheStructureOfTheSearch);
			For Each StringComponents In ListOfSubassemblyComponents Do
				
				LineNewSourceComponent = TableSourceComponents.Add();
				FillPropertyValues(LineNewSourceComponent, StringComponents);
				LineNewSourceComponent.DateOfAssemblyDisassembly = LineProducts_.DateOfAssemblyDisassembly;
				LineNewSourceComponent.RowCodeGoods = LineProducts_.RowCode;
				If FillInWarehouse And Not FillInWarehouseInTabularForm Then
					LineNewSourceComponent.Warehouse = Object.Warehouse;
				Else
					LineNewSourceComponent.Warehouse = LineProducts_.Warehouse;
				EndIf;
				If FillInAssignmentInTabularForm Then
					LineNewSourceComponent.Purpose = LineProducts_.Purpose;
				Else
					LineNewSourceComponent.Purpose = Object.Purpose;
				EndIf;
				
				LineNewSourceComponent.Count = LineNewSourceComponent.Count 
																* LineProducts_.Count
																/ StringConfigurationOption.QuantityEquipment;
																
				LineNewSourceComponent.NumberOfPackages = LineNewSourceComponent.NumberOfPackages 
																		* LineProducts_.Count 
																		/ StringConfigurationOption.QuantityEquipment;
				
			EndDo; 
			
			ThereAreSubassemblies = True;
			
			PreviousString = LineProducts_;
			
		EndDo;
		
	EndDo;
	
	// Fill in the cross-table if it is used
	CopyToCrossTable(Undefined);
	
	// Restore the current line
	If Object.CrossTable And CurLineCode_ <> Undefined Then
		TheStructureOfTheSearch = New Structure("RowCode", CurLineCode_);
  		StringsList = GoodsByDates.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Items.GoodsByDates.CurrentRow = StringsList[0].GetID();
		EndIf;
	EndIf;
	
	FillInServiceDetailsForProductInCollection();
	
	Items.TheGroupNeedsToBeFilledInWithSets.Visible = False;
	
	Return ThereAreSubassemblies;
	
EndFunction


// LongDesc
// 
// Parameters:
// 	TableComponents - ValueTable - LongDesc
// Returns:
// 	Structure - LongDesc:
// * SubassemblyTable - ValueTable -
// * TableConfigurationOptions - ValueTable -
// * TableComponents - ValueTable -
&AtServer
Function PodsobrkiAndAccessories(TableComponents)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableComponents.Products          AS Products,
	|	TableComponents.Characteristic        AS Characteristic,
	|	TableComponents.Purpose        AS Purpose,
	|	TableComponents.Package              AS Package,
	|	TableComponents.Count            AS Count,
	|	TableComponents.NumberOfPackages    AS NumberOfPackages,
	|	TableComponents.RowCodeGoods       AS RowCodeGoods,
	|	TableComponents.Warehouse                 AS Warehouse,
	|	TableComponents.DateOfAssemblyDisassembly    AS DateOfAssemblyDisassembly
	|INTO TableComponents
	|FROM
	|	&TableComponents AS TableComponents
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1,2
	|" + StrReplace(
			InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE"),
			"TTProducts_1",
			"TableComponents") + "
	|;
	|
	|////////////////////////////////////
	// 3
	|SELECT ALLOWED
	|	TableComponents.Products                    AS Products,
	|	TableComponents.Characteristic                  AS Characteristic,
	|	TableComponents.Purpose                      AS Purpose,
	|	TableComponents.Package                        AS Package,
	|	TableComponents.Count                      AS Count,
	|	TableComponents.NumberOfPackages              AS NumberOfPackages,
	|	TableComponents.RowCodeGoods                 AS RowCodeGoods,
	|	TableComponents.Warehouse                           AS Warehouse,
	|	TableComponents.DateOfAssemblyDisassembly              AS DateOfAssemblyDisassembly
	|INTO Subassemblies_
	|FROM
	|	TableComponents AS TableComponents
	|		
	|		LEFT JOIN TTWaysToEnsure AS TableWaysToEnsure
	|		ON TableComponents.Warehouse = TableWaysToEnsure.Warehouse
	|			AND TableComponents.Products = TableWaysToEnsure.Products
	|			AND TableComponents.Characteristic = TableWaysToEnsure.Characteristic
	|		
	|		LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
	|		ON CatSupplyMethod.Ref = TableWaysToEnsure.ProcurementStrategy
	|
	|WHERE
	|	ISNULL(CatSupplyMethod.SupplyType, 
	|		VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.AssemblyDisassembly)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 4
	|SELECT ALLOWED
	|	ProductKitConfigurations.Owner            AS Products,
	|	ProductKitConfigurations.Characteristic      AS Characteristic,
	|	ProductKitConfigurations.Ref              AS ProductKit,
	|	ProductKitConfigurations.Main            AS Main,
	|	ProductKitConfigurations.Package            AS Package,
	|	ProductKitConfigurations.NumberOfPackages  AS NumberOfPackages,
	|	ProductKitConfigurations.Count          AS Count
	|INTO ProductKitConfigurations
	|FROM
	|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|WHERE
	|	NOT ProductKitConfigurations.DeletionMark
	|	AND (ProductKitConfigurations.Owner, ProductKitConfigurations.Characteristic) IN
	|			(SELECT
	|				Subassemblies_.Products,
	|				Subassemblies_.Characteristic
	|			FROM
	|				Subassemblies_ AS Subassemblies_)
	|INDEX BY
	|	ProductKit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 5
	|SELECT
	|	Subassemblies_.Products                               AS Products,
	|	Subassemblies_.Characteristic                             AS Characteristic,
	|	Subassemblies_.Purpose                                 AS Purpose,
	|	Subassemblies_.Warehouse                                      AS Warehouse,
	|	Subassemblies_.Package                                   AS Package,
	|	Subassemblies_.Count                                 AS Count,
	|	Subassemblies_.NumberOfPackages                         AS NumberOfPackages,
	|	Subassemblies_.RowCodeGoods                            AS RowCodeGoods,
	|	Subassemblies_.DateOfAssemblyDisassembly                         AS DateOfAssemblyDisassembly
	|FROM
	|	Subassemblies_ AS Subassemblies_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 6
	|SELECT
	|	ProductKitConfigurations.Products        AS Products,
	|	ProductKitConfigurations.Characteristic      AS Characteristic,
	|	ProductKitConfigurations.ProductKit AS ProductKit,
	|	ProductKitConfigurations.Main            AS Main,
	|	ProductKitConfigurations.Package            AS PackagingEquipment,
	|	ProductKitConfigurations.NumberOfPackages  AS NumberOfPackagesCompleteSet,
	|	ProductKitConfigurations.Count          AS QuantityEquipment
	|FROM
	|	ProductKitConfigurations AS ProductKitConfigurations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 7
	|SELECT ALLOWED
	|	TableComponents.Ref                          AS ProductKit,
	|	TableComponents.Products                    AS Products,
	|	TableComponents.Characteristic                  AS Characteristic,
	|	TableComponents.Package                        AS Package,
	|	TableComponents.Count                      AS Count,
	|	TableComponents.NumberOfPackages              AS NumberOfPackages
	|FROM
	|	ProductKitConfigurations AS ProductKitConfigurations
	|		INNER JOIN Catalog.ProductKitConfigurations.Goods AS TableComponents
	|		ON (TableComponents.Ref = ProductKitConfigurations.ProductKit)";
	
	Query.SetParameter("TableComponents", TableComponents);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Return New Structure("SubassemblyTable, TableConfigurationOptions, TableComponents", 
							Result[5].Unload(), Result[6].Unload(), Result[7].Unload());
	
EndFunction
 
&AtServer
Function ComponentsOfUnplannedSubassemblies(ProcessStringCode = 0)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.RowCode            AS RowCode,
	|	GoodsTable.RowCodeGoods      AS RowCodeGoods,
	|	GoodsTable.Products         AS Products,
	|	GoodsTable.Characteristic       AS Characteristic,
	|	GoodsTable.Purpose           AS Purpose,
	|	GoodsTable.Warehouse                AS Warehouse,
	|	GoodsTable.DateOfAssemblyDisassembly   AS DateOfAssemblyDisassembly,
	|	GoodsTable.ProductKit  AS ProductKit,
	|	GoodsTable.Count  AS Count
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	RowCodeGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableComponents.Ref            AS ProductKit,
	|	TableComponents.Products      AS Products,
	|	TableComponents.Characteristic    AS Characteristic,
	|	SUM(TableComponents.Count) AS Count
	|INTO TableComponents
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS TableComponents
	|
	|WHERE
	|	TableComponents.Ref IN
	|			(SELECT
	|				GoodsTable.ProductKit
	|			FROM
	|				GoodsTable)
	|	AND NOT TableComponents.Ref.DeletionMark
	|
	|GROUP BY
	|	TableComponents.Ref,
	|	TableComponents.Products,
	|	TableComponents.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableComponents.Products                       AS Products,
	|	TableComponents.Characteristic                     AS Characteristic,
	|	GoodsTable.Purpose                                AS Purpose,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)  AS Package,
	|	TableComponents.Count 
	|		* GoodsTable.Count                          AS Count,
	|	TableComponents.Count 
	|		* GoodsTable.Count                          AS NumberOfPackages,
	|	GoodsTable.RowCode                                 AS RowCodeGoods,
	|	GoodsTable.Warehouse                                     AS Warehouse,
	|	GoodsTable.DateOfAssemblyDisassembly                        AS DateOfAssemblyDisassembly
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN TableComponents AS TableComponents
	|		ON (TableComponents.ProductKit = GoodsTable.ProductKit)
	|		LEFT JOIN GoodsTable AS TableOfProductsUnderAssembly
	|		ON (TableOfProductsUnderAssembly.RowCodeGoods = GoodsTable.RowCode)
	|			AND (TableOfProductsUnderAssembly.Products = TableComponents.Products)
	|			AND (TableOfProductsUnderAssembly.Characteristic = TableComponents.Characteristic)
	|WHERE
	|	TableOfProductsUnderAssembly.RowCodeGoods IS NULL";
	
	TheStructureOfTheSearch = Undefined;
	If ProcessStringCode <> 0 Then
		TheStructureOfTheSearch = New Structure("PlanningASubassembly", Enums.SubassemblySchedulingStatuses.ToPlan);
		TheStructureOfTheSearch.Insert("RowCode", ProcessStringCode);
	EndIf;
	UnloadedColumns = "RowCode,RowCodeGoods,Products,Characteristic,Purpose,Warehouse,ProductKit,DateOfAssemblyDisassembly,Count";
	TableProductsCopy = Object.Goods.Unload(TheStructureOfTheSearch, UnloadedColumns);
	If FillInWarehouse And Not FillInWarehouseInTabularForm Then
		TableProductsCopy.FillValues(Object.Warehouse, "Warehouse");
	EndIf;
	If ValueIsFilled(Object.Purpose) And Not FillInAssignmentInTabularForm Then
		TableProductsCopy.FillValues(Object.Purpose, "Purpose");
	EndIf;
	
	Query.SetParameter("GoodsTable", TableProductsCopy);
	
	SubassemblyTable = Query.Execute().Unload();
	
	Return SubassemblyTable;

EndFunction

&AtServer
Procedure DefineSubassemblyPlanning(ProcessStringCode = 0)

	If Not (Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
		And (FillInWarehouse Or FillInWarehouseInTabularForm)) Then
		Items.TheGroupNeedsToBeFilledInWithSets.Visible = False;
		Return;
	EndIf;
	
	If Object.CrossTable Then
		GoodsTable = GoodsByDates;
	Else
		GoodsTable = Object.Goods;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
	+"SELECT
	|	GoodsTable.RowCode            AS RowCode,
	|	GoodsTable.RowCodeGoods      AS RowCodeGoods,
	|	GoodsTable.Products         AS Products,
	|	GoodsTable.Characteristic       AS Characteristic,
	|	GoodsTable.Warehouse                AS Warehouse,
	|	GoodsTable.ProductKit  AS ProductKit
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	RowCodeGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableComponents.Ref            AS ProductKit,
	|	TableComponents.Products      AS Products,
	|	TableComponents.Characteristic    AS Characteristic
	|INTO TableComponents
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS TableComponents
	|
	|WHERE
	|	TableComponents.Ref IN
	|			(SELECT
	|				GoodsTable.ProductKit
	|			FROM
	|				GoodsTable)
	|	AND NOT TableComponents.Ref.DeletionMark
	|
	|GROUP BY
	|	TableComponents.Ref,
	|	TableComponents.Products,
	|	TableComponents.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsTable.RowCode AS RowCode,
	|	MAX(CASE
	|		WHEN TableOfProductsUnderAssembly.RowCode IS NULL 
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS ToPlan
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN TableComponents AS TableComponents
	|		ON (TableComponents.ProductKit = GoodsTable.ProductKit)
	|		LEFT JOIN GoodsTable AS TableOfProductsUnderAssembly
	|		ON (TableOfProductsUnderAssembly.RowCodeGoods = GoodsTable.RowCode)
	|			AND (TableOfProductsUnderAssembly.Products = TableComponents.Products)
	|			AND (TableOfProductsUnderAssembly.Characteristic = TableComponents.Characteristic)
	|		
	|		LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
	|		ON &MainSupplyMethodSubstitution
	|
	|WHERE
	|	ISNULL(CatSupplyMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.AssemblyDisassembly)
	|	AND (&ProcessStringCode = 0 
	|		OR GoodsTable.RowCode = &ProcessStringCode)
	|	
	|
	|GROUP BY
	|	GoodsTable.RowCode";
	
	Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
		Query.Text,
		"MainSupplyMethodSubstitution",
		"TableComponents.Products,TableComponents.Characteristic,GoodsTable.Warehouse");

	UnloadedColumns = "RowCode,RowCodeGoods,Products,Characteristic,Warehouse,ProductKit";
	TableProductsCopy = GoodsTable.Unload(, UnloadedColumns);
	If FillInWarehouse And Not FillInWarehouseInTabularForm Then
		TableProductsCopy.FillValues(Object.Warehouse, "Warehouse");
	EndIf;
	Query.SetParameter("GoodsTable",       TableProductsCopy);
	Query.SetParameter("ProcessStringCode", ProcessStringCode);
	
	SetPrivilegedMode(True);
	ResultSubassemblyPlanning = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	RequiredToFillInWithKits = False;
	
	If ProcessStringCode <> 0 Then
		TheStructureOfTheSearch = New Structure("RowCode", ProcessStringCode);
		DataToProcess = GoodsTable.FindRows(TheStructureOfTheSearch);
	Else
		DataToProcess = GoodsTable;
	EndIf;
	
	For Each RowGoods In DataToProcess Do
		TheStructureOfTheSearch = New Structure("RowCode", RowGoods.RowCode);
  		StringsList = ResultSubassemblyPlanning.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			If StringsList[0].ToPlan Then
				RequiredToFillInWithKits = True;
				RowGoods.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.ToPlan;
			Else
				RowGoods.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.Completed2;
			EndIf; 
		Else
			RowGoods.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired;
		EndIf; 
	EndDo;
	
	Items.TheGroupNeedsToBeFilledInWithSets.Visible = RequiredToFillInWithKits;

EndProcedure

&AtClientAtServerNoContext
Function NewProductLineCode(Object)

	Object.MaximumRowCodeGoods = Object.MaximumRowCodeGoods + 1;
	Return Object.MaximumRowCodeGoods;

EndFunction

&AtServer
Procedure DeleteResultOfFillingIn(GoodsTable, Initial_Quantity)
	
	For IndexOf = -GoodsTable.Count() + 1 To -Initial_Quantity Do
		GoodsTable.Delete(GoodsTable[-IndexOf]);
	EndDo;
	
EndProcedure
&AtServer
Procedure NotIncluded()

	If Object.CrossTable Then
		GoodsTable = GoodsByDates;
	Else
		GoodsTable = Object.Goods;
	EndIf; 
	
	TheStructureOfTheSearch = New Structure("Subassembly", True);
 	ListOfSubassemblyRows = GoodsTable.FindRows(TheStructureOfTheSearch);
	For Each RowSubassembly In ListOfSubassemblyRows Do
		TheStructureOfTheSearch = New Structure("RowCode", RowSubassembly.RowCodeGoods);
  		StringsList = GoodsTable.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			RowGoods = StringsList[0];
			RowSubassembly.ProductsKit   = RowGoods.Products;
			RowSubassembly.CharacteristicSet = RowGoods.Characteristic;
		EndIf; 
	EndDo; 

EndProcedure

&AtClient
Procedure GoToKit(StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.CrossTable Then
		GoodsTable = GoodsByDates;
		Item_Products = Items.GoodsByDates;
	Else
		GoodsTable = Object.Goods;
		Item_Products = Items.Goods;
	EndIf; 
	
	CurrentData = Item_Products.CurrentData;
	
	TheStructureOfTheSearch = New Structure("RowCode", CurrentData.RowCodeGoods);
 	StringsList = GoodsTable.FindRows(TheStructureOfTheSearch);
	If StringsList.Count() <> 0 Then
		Item_Products.CurrentRow = StringsList[0].GetID();
	EndIf;

EndProcedure

&AtClient
Procedure ScheduleSubassembly(StandardProcessing)

	StandardProcessing = False;
	
	If Object.CrossTable Then
		CurrentData = Items.GoodsByDates.CurrentData;
	Else
		CurrentData = Items.Goods.CurrentData;
	EndIf; 
	
	If CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.Completed2") Then
		ListOfSubassemblies = GetSetSubassemblies(CurrentData.RowCode);
		If ListOfSubassemblies.Count() <> 0 Then
			
			Notification = New CallbackDescription("ScheduleSubassemblyCompletion", ThisObject);
			ListOfSubassemblies.ShowChooseItem(Notification, NStr("vi = 'Hãy chọn chứng từ đóng bộ để chuyển';
																	|ru = 'Выберите подсборку, чтобы перейти к ней';
																	|en = 'Select an subassembly to go to it'; fa = 'Select an subassembly to go to it';
																	|it = 'Selezionate il sottolivello di assemblaggio per potervi passare';
																	|pl = 'Wybierz podzespół, aby do niego przejść';
																	|tr = 'Alt montajı seçin,ona geçmek için'"));
			
		EndIf; 
	ElsIf CurrentData.PlanningASubassembly = PredefinedValue("Enum.SubassemblySchedulingStatuses.ToPlan") Then
		ScheduleSubassembliesOnServer(CachedValues, CurrentData.RowCode);
	EndIf; 

EndProcedure

&AtClient
Procedure ScheduleSubassemblyCompletion(SelectedElement, AdditionalParameters) Export 
	
	If SelectedElement <> Undefined Then
		If Object.CrossTable Then
			Items.GoodsByDates.CurrentRow = SelectedElement.Value;
		Else
			Items.Goods.CurrentRow = SelectedElement.Value;
		EndIf; 
	EndIf; 
	
EndProcedure

&AtServer
Function GetSetSubassemblies(RowCodeGoods)

	If Object.CrossTable Then
		GoodsTable = GoodsByDates;
	Else
		GoodsTable = Object.Goods;
	EndIf; 
	
	TheStructureOfTheSearch = New Structure("RowCodeGoods,Subassembly", RowCodeGoods, True);
 	StringsList = GoodsTable.FindRows(TheStructureOfTheSearch);	
	
	ListOfSubassemblies = New ValueList;
	For Each CollectionItem In StringsList Do
		GoodsRow = ProductsClientServer.ProductPresentation(CollectionItem.Products, CollectionItem.Characteristic);
		ListOfSubassemblies.Add(CollectionItem.GetID(), GoodsRow);
	EndDo; 
	
	Return ListOfSubassemblies;
	
EndFunction

&AtServer
Procedure CalculateQuantityForSubCollections(Val RowCodeGoods, Val ProductKit, Val DateOfAssemblyDisassembly, Val ProductQuantity_, Val Canceled, Val Package = Undefined, Products = Undefined)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	PackagingFactor = 1;
	If ValueIsFilled(Package) Then
		// Passed the package, so you need to recalculate the quantity
		PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	EndIf; 
	
	ListOfSourceProducts = New Array;
	ProductStructure_2 = New Structure();
	ProductStructure_2.Insert("RowCodeGoods", RowCodeGoods);
	ProductStructure_2.Insert("ProductKit", ProductKit);
	ProductStructure_2.Insert("ProductQuantity_", ProductQuantity_ * PackagingFactor);
	ProductStructure_2.Insert("Canceled", Canceled);
	
	ListOfSourceProducts.Add(ProductStructure_2);
	
	While ListOfSourceProducts.Count() <> 0 Do
		
		ListOfLineCodeItemsToProcess = New FixedArray(ListOfSourceProducts);
		ListOfSourceProducts.Clear();
		
		// Find the subassemblies
		ListOfSubassemblies = New Array;
		ListOfConfigurationOptions_ = New Array;
		For Each SourceProductData In ListOfLineCodeItemsToProcess Do
			
			CurrentCodeOfGoodsLine = SourceProductData.RowCodeGoods;
			If Object.CrossTable Then
				TheStructureOfTheSearch = New Structure("RowCodeGoods", CurrentCodeOfGoodsLine);
		  		StringsList = GoodsByDates.FindRows(TheStructureOfTheSearch);
			Else
				TheStructureOfTheSearch = New Structure("RowCodeGoods,DateOfAssemblyDisassembly", CurrentCodeOfGoodsLine, DateOfAssemblyDisassembly);
		  		StringsList = Object.Goods.FindRows(TheStructureOfTheSearch);
			EndIf;
	
			For Each CollectionItem In StringsList Do
				SubassemblyData = New Structure("RowSubassembly,ProductKit", 
											CollectionItem, SourceProductData.ProductKit);
				ListOfSubassemblies.Add(SubassemblyData);
			EndDo; 
			
			ListOfConfigurationOptions_.Add(SourceProductData.ProductKit);
			
		EndDo;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	TableComponents.Ref            AS ProductKit,
		|	TableComponents.Products      AS Products,
		|	TableComponents.Characteristic    AS Characteristic,
		|	TableComponents.Ref.Count AS QuantityEquipment,
		|	SUM(TableComponents.Count) AS Count
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS TableComponents
		|
		|WHERE
		|	TableComponents.Ref IN (&ListOfConfigurationOptions_)
		|	AND NOT TableComponents.Ref.DeletionMark
		|
		|GROUP BY
		|	TableComponents.Ref,
		|	TableComponents.Products,
		|	TableComponents.Characteristic";
		
		Query.SetParameter("ListOfConfigurationOptions_", ListOfConfigurationOptions_);
		TableComponents = Query.Execute().Unload();
		TableComponents.Indexes.Add("Products,Characteristic,ProductKit");
		
		RowsToProcess = New Array();
		
		For Each SubassemblyData In ListOfSubassemblies Do
			
			RowSubassembly = SubassemblyData.RowSubassembly;
			
			// We will find the component for which this subassembly is planned
			TheStructureOfTheSearch = New Structure("Products,Characteristic,ProductKit", 
										RowSubassembly.Products, RowSubassembly.Characteristic, SubassemblyData.ProductKit);
			ListOfComponents = TableComponents.FindRows(TheStructureOfTheSearch);
			If ListOfComponents.Count() <> 0 Then
				QuantityEquipment  = ListOfComponents[0].QuantityEquipment;
				NumberOfComponents = ListOfComponents[0].Count;
			Else
				QuantityEquipment  = 1;
				NumberOfComponents = 0;
			EndIf;
			
			If Object.CrossTable Then
				
				PackagingFactor = 1;
				If ValueIsFilled(RowSubassembly.Package) Then
					PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(RowSubassembly.Package, RowSubassembly.Products);
				EndIf;
				
				NumberOfSubassembly = SourceProductData.ProductQuantity_ 
										* NumberOfComponents 
										/ QuantityEquipment 
										/ PackagingFactor;
										
				RowSubassembly["Count_"+DateOfAssemblyDisassembly] = NumberOfSubassembly;
				RowSubassembly["Canceled_"+DateOfAssemblyDisassembly] = Canceled;
				
				WhenChangingAmountOfRowSum(ThisForm, RowSubassembly);
				
				ProductStructure_2 = New Structure();
				ProductStructure_2.Insert("RowCodeGoods", RowSubassembly.RowCode);
				ProductStructure_2.Insert("ProductKit", RowSubassembly.ProductKit);
				ProductStructure_2.Insert("ProductQuantity_", NumberOfSubassembly * PackagingFactor);
				ProductStructure_2.Insert("Canceled", Canceled);
				
				ListOfSourceProducts.Add(ProductStructure_2);
			Else
				
				NumberOfSubassembly = SourceProductData.ProductQuantity_ 
										* NumberOfComponents 
										/ QuantityEquipment;
				
				RowSubassembly.Count = NumberOfSubassembly;
				RowSubassembly.Canceled = Canceled;
				
				RowsToProcess.Add(RowSubassembly);
				
				ProductStructure_2 = New Structure();
				ProductStructure_2.Insert("RowCodeGoods", RowSubassembly.RowCode);
				ProductStructure_2.Insert("ProductKit", RowSubassembly.ProductKit);
				ProductStructure_2.Insert("ProductQuantity_", NumberOfSubassembly);
				ProductStructure_2.Insert("Canceled", Canceled);
				
				ListOfSourceProducts.Add(ProductStructure_2);
			EndIf;
			
		EndDo;
		
		If Not Object.CrossTable Then
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				Object.Goods,
				CachedValues);
		EndIf;
		
	EndDo;
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtServer
Procedure RemoveSubassemblies(ArrayOfCodesForDeletedLines = Undefined)
	
	If Object.CrossTable Then
		GoodsTable = GoodsByDates;
	Else
		GoodsTable = Object.Goods;
	EndIf; 
	
	If ArrayOfCodesForDeletedLines = Undefined Then
		ArrayOfCodesForDeletedLines = New Array(GoodsLinesBeingDeletedKeyArray);
	EndIf;
	
	While ArrayOfCodesForDeletedLines.Count() <> 0 Do
		ArrayOfCodesToDelete = New FixedArray(ArrayOfCodesForDeletedLines);
		ArrayOfCodesForDeletedLines.Clear();
		
		For Each RowCodeGoods In ArrayOfCodesToDelete Do
			TheStructureOfTheSearch = New Structure("RowCodeGoods", RowCodeGoods);
			StringsList = GoodsTable.FindRows(TheStructureOfTheSearch);
			For Each RowToDelete In StringsList Do
				ArrayOfCodesForDeletedLines.Add(RowToDelete.RowCode);
				GoodsTable.Delete(RowToDelete);
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

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

&AtServer
Procedure OnReadCreateAtServer()
	
	If Object.FillInUsingFormula Then
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
	Else
		InitializeSettingsStructure(FormAttributeToValue("Object"));
	EndIf;
	
	PlanningByAssignments = Common.ObjectAttributeValue(Object.Scenario,"PlanningByAssignments");
	
	WhenChangingPeriodsOnServer();
	
	CopyToCrossTable(Undefined);
	
	SetCrossTableTag(ThisForm);
	
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
	
	ScriptParameters_ = ScriptParameters_(Object.Scenario);
	FillPropertyValues(Object, ScriptParameters_);
	FillPropertyValues(ThisForm, ScriptParameters_);
	
	If UpdatePlanView Then
		
		Object.PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.AssemblyDisassemblyPlan, Object.Scenario);
		
	EndIf;
	
	If PlanningClientServer.YouNeedToUpdateInterface(Object, ThisForm, "DetailsBeforeChange") Then
		WhenChangingPeriodsOnServer(True);
	EndIf;
	
	If UpdatePlanView Then
		PlanProfileOnChangeServer(UpdatePlanView);
		Object.FilledAutomatically = False;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure PlanProfileOnChangeServer(UpdateRule = False)

	UpdateRule = (UpdateRule Or Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile);
	
	PlanViewParameters = GetPlanViewParameters(
		Object.PlanProfile, 
		UpdateRule, 
		FillingRuleAddress, 
		CustomSettingsAddress);
	
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	If PlanViewParameters.FillInByShortage = True Then
		Object.CrossTable = False;
		SwitchPeriodsToRowsOnServer(Undefined);
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
		Object.FillingRule.Load(GetFromTempStorage(FillingRuleAddress));
		Object.FilledAutomatically = False;
		
		DetermineConfigurationOption();
		DefineSubassemblyPlanning();
		
		Object.FillInUsingFormula = PlanViewParameters.FillInUsingFormula;
		Object.Substitutional = PlanViewParameters.Substitutional;
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "AssemblyDisassemblyPlan");
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
		If PlanViewParameters.Property("SettingsStructure")
			And PlanViewParameters.SettingsStructure <> Undefined Then
			SettingsStructure = PlanViewParameters.SettingsStructure;
		EndIf;
		WhenChangingPeriodsOnServer();
		
	EndIf;
	
	SaveNewPeriodServer();
	
	If UpdateRule And ValueIsFilled(Object.PlanProfile) Then
		
		UpdateRelatedItemDetails(Object, ThisForm);
		
	EndIf; 
	
	SetVisibility1();
	
EndProcedure 

&AtServer
Procedure SetVisibility1()
	
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	Items.PlanProfile.Enabled = ValueIsFilled(Object.Scenario);
	
	UseSubassemblies = (Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents)
							And (FillInWarehouse Or FillInWarehouseInTabularForm);
	
	Items.GoodsConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	Items.GoodsByDatesConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	// Warehouse
	Items.Warehouse.Visible = FillInWarehouse Or ValueIsFilled(Object.Warehouse);
	Items.GoodsWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.GoodsByDatesWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.GoodsFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	Items.GoodsByDatesFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	
	Items.GoodsFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	Items.GoodsByDatesFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	
	Items.ProductsFillColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	Items.ProductsByDateFillInColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	
	// PlanSubassemblies
	Items.GoodsPlanSubassemblies.Visible = UseSubassemblies;
	Items.GoodsByDatesPlanSubassemblies.Visible = UseSubassemblies;
	
	// PlanningASubassembly
	Items.GoodsPlanningASubassembly.Visible = UseSubassemblies;
	Items.GoodsByDatesPlanningASubassembly.Visible = UseSubassemblies;
	
	// Included in the package
	Items.GoodsProductsKit.Visible = UseSubassemblies;
	Items.GoodsCharacteristicSet.Visible = UseSubassemblies;
	Items.GoodsByDatesProductsKit.Visible = UseSubassemblies;
	Items.GoodsByDatesCharacteristicSet.Visible = UseSubassemblies;
	
	Items.GoodsFill.Visible = Not Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.GoodsSplitRow.Visible = Not Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsByDateFillIn.Visible = Not Object.FillInUsingFormula;
	Items.GoodsFillInTheProducts.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.GoodsByDatesFillInTheProducts.Visible = Object.FillInUsingFormula;
	Items.GoodsFillInIndicators.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.GoodsByDatesFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.GoodsGroupChangeQuantity.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsByDateGroupChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.GoodsAdditionalParametersFormula.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.ProductsAdditionalParametersDeviation.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("GoodsByDates" + "Deviation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["GoodsByDates" + "Deviation"].Visible = Object.FillInUsingFormula;
	EndIf;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("GoodsByDates" + "FormulaCalculation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["GoodsByDates" + "FormulaCalculation"].Visible = Object.FillInUsingFormula;
	EndIf;
	Items.GoodsAdditionalParameters.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	Items.Details.Visible = Not Object.FillInUsingFormula;
	Items.GoodsByDatesContextMenuGroupByFormula.Visible = Object.FillInUsingFormula;
	Items.GoodsContextMenuGroupUsingFormula.Visible = Object.FillInUsingFormula And Not Object.FillInByShortage;
	
	Items.Purpose.Visible = PlanningByAssignments And Not FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	Items.GoodsPurpose.Visible = PlanningByAssignments And FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	Items.GoodsByDatesPurpose.Visible = PlanningByAssignments And FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	
	Items.GoodsSubstituted.Visible = Object.Substitutional;
	
	If Not Object.FillInByShortage Then
		Items.TheCaptionThereAreCanceledSecurityAdjustments.Visible = False;
	EndIf;
	
	Items.GoodsFillInByShortages.Visible = Object.FillInByShortage;
	Items.AutoFill.Visible = Object.FillInByShortage;
	If ValueIsFilled(Object.Ref) Then
		Items.BeginningEndOfPeriod.Enabled = Not Object.FillInByShortage;
	EndIf;
	Items.GoodsSecurityAdjustment.Visible = Object.FillInByShortage;
	
	Items.FormGroupPeriods.Visible = Not Object.FillInByShortage;
	Items.GoodsInsertRows.Visible = Not Object.FillInByShortage;
	Items.GoodsContextMenuSplitRow.Visible = Not Object.FillInByShortage;
	Items.GoodsSelectGoods.Visible = Not Object.FillInByShortage;
	Items.GoodsImportFromExcel.Visible = Not Object.FillInByShortage;
	Items.ExcelGoods.Visible = Not Object.FillInByShortage;
	Items.GoodsCancelPlanLines.Visible = Not Object.FillInByShortage;
	Items.GoodsContextMenuCancelPlanLines.Visible = Not Object.FillInByShortage;
	Items.GoodsCanceled.Visible = Not Object.FillInByShortage;
	
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
	
	Attributes = "NumberOfPeriods, FillInWarehouse, FillInWarehouseInTabularForm, DisableEditingOfRule,
		|Substitutional, FillInUsingFormula, FillInAssignmentInTabularForm, BusinessOperation,
		|FillInByShortage, Parent, AutoFill, DisableEditingOfPopulationSettings";
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
	
	If UpdateRule Then
		FillingRuleAddress = Planning.GetAddressOfDefaultFillInRule(
			Enums.TypesOfPlans.AssemblyDisassemblyPlan, 
			PlanProfile, 
			FillingRuleAddress);
		
		CustomSettingsAddress = Planning.GetAddressOfUserDefaultSettings(
			Enums.TypesOfPlans.AssemblyDisassemblyPlan, 
			PlanProfile, 
			CustomSettingsAddress);
		
		SettingsStructure = Planning.GetDefaultSettings(Enums.TypesOfPlans.AssemblyDisassemblyPlan, PlanProfile);
		If SettingsStructure.Property("Formula") Then
			PlanViewParameters.Insert("SettingsStructure", SettingsStructure);
		EndIf;
		For Each Item In SettingsStructure Do
			PlanViewParameters.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	Return PlanViewParameters;

EndFunction

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
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	AddProducts_2(TableOfGoods, CachedValues)
	
EndProcedure

#EndRegion

&AtServer
Procedure AddProducts_2(TableOfGoods, CachedValues = Undefined, LoadingFromFile = False)
	
	Modified = True;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each RowOfGoods In TableOfGoods Do
		
		If Object.CrossTable And Not LoadingFromFile Then
			CurrentRow = GoodsByDates.Add();
			FillPropertyValues(CurrentRow, RowOfGoods);
			CurrentRow.RowCode = NewProductLineCode(Object);
		Else
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfGoods);
			CurrentRow.RowCode = NewProductLineCode(Object);
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
		KeyArray = New Array;
		KeyArray.Add(CurrentRow.RowCode);
		RemoveSubassemblies(KeyArray);
		
		If ValueIsFilled(CurrentRow.ProductKit) Then
			DefineSubassemblyPlanning(CurrentRow.RowCode);
		Else
			CurrentRow.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired;
		EndIf;
	
		UpdateRelatedItemDetails(Object, ThisForm);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
	EndIf;
	
	FillInServiceDetailsForProductInCollection();
	
EndProcedure
&AtClientAtServerNoContext
Procedure UpdateRelatedItemDetails(Object, Form)

	If Object.CrossTable 
		Or Form.PlannedBalanceIsUsed Then
		Goods = Form.GoodsByDates;
	Else
		Goods = Object.Goods;
	EndIf;
	
	If Not Form.FillInWarehouse Then
		Object.Warehouse = Undefined;
	EndIf;
	
	If Not Form.PlanningByAssignments Then
		Object.Purpose = Undefined;
	EndIf;
	
	For Each TSRow In Goods Do
		
		If Form.FillInWarehouse Then
			TSRow.Warehouse = Object.Warehouse;
		ElsIf Not Form.FillInWarehouseInTabularForm Then
			TSRow.Warehouse = Undefined;
		EndIf;
		
		If Not Form.PlanningByAssignments 
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			TSRow.Purpose = Undefined;
		ElsIf Not Form.FillInAssignmentInTabularForm Then
			TSRow.Purpose = Object.Purpose;
		EndIf;
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingAmountOfRowSum(ThisForm, RowOfGoods)

	Count = 0;
	For Each PeriodString_ In ThisForm.TimeIntervals Do
		If Not PeriodString_.Active_ Or RowOfGoods["Canceled_" + PeriodString_.ColumnName]  Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.NumberOfPackages = Count;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form, CountLines = True)

	Object = Form.Object;
	
	If Not Object.CrossTable Then
	
		Return;
	
	EndIf; 
	
	Goods = Form.GoodsByDates;
	
	Form["NumberOfPackages"] = 0;
	PrefixOfQuantityColumn = "GoodsByDates" + "Count_";
	
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = 0;
		
	EndDo;
	
	For Each TSRow In Goods Do
		If CountLines Then
			TSRow.NumberOfPackages = 0;
		EndIf;
		
		For Each PeriodString_ In Form.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			
			TSRow["Substituted_"+ PeriodString_.ColumnName] = PeriodString_.Substituted;
			TSRow["SubstitutedToOrder_"+ PeriodString_.ColumnName] = PeriodString_.SubstitutedToOrder;
			
			If TSRow["Canceled_" + PeriodString_.ColumnName] Then
				Continue;
			EndIf;
			
			If CountLines Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + TSRow["Count_" + PeriodString_.ColumnName];
			EndIf;
			
			Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] + TSRow["Count_" + PeriodString_.ColumnName];
			
		EndDo;
		
		Form["NumberOfPackages"] = Form["NumberOfPackages"] + TSRow["NumberOfPackages"];
		
		PlanningClientServer.SetFormulaPresentation(Form, TSRow);
		
	EndDo; 
	
EndProcedure

&AtServer
Procedure ProductsAfterDeletionOnServer()

	CalculateTotals_(ThisForm, False);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
	EndIf; 

	RemoveSubassemblies();
	
	DefineSubassemblyPlanning();
	
EndProcedure

&AtServer
Procedure ProductsWarehouseWhenChangedOnServer()
	
	If Object.CrossTable Then
		CurrentRow = Items.GoodsByDates.CurrentRow;
		CurrentData = GoodsByDates.FindByID(CurrentRow);
	Else
		CurrentRow = Items.Goods.CurrentRow;
		CurrentData = Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	DefineSubassemblyPlanning(CurrentData.RowCode);
	If CurrentData.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired Then
		KeyArray = New Array;
		KeyArray.Add(CurrentData.RowCode);
		RemoveSubassemblies(KeyArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()

	UpdateRelatedItemDetails(Object, ThisForm);
	DefineSubassemblyPlanning();

EndProcedure
 
&AtServer
Procedure WhenChangingProductsOnServer()

	If Object.CrossTable Then
		CurrentRow = Items.GoodsByDates.CurrentRow;
		CurrentData = GoodsByDates.FindByID(CurrentRow);
	Else
		CurrentRow = Items.Goods.CurrentRow;
		CurrentData = Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	ListOfProductLines = New Array;
	ListOfProductLines.Add(CurrentData);
	DetermineConfigurationOption(ListOfProductLines);
	DefineSubassemblyPlanning(CurrentData.RowCode);
	If CurrentData.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired Then
		KeyArray = New Array;
		KeyArray.Add(CurrentData.RowCode);
		RemoveSubassemblies(KeyArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingCharacteristicsOnServer()

	If Object.CrossTable Then
		CurrentRow = Items.GoodsByDates.CurrentRow;
		CurrentData = GoodsByDates.FindByID(CurrentRow);
	Else
		CurrentRow = Items.Goods.CurrentRow;
		CurrentData = Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	ListOfProductLines = New Array;
	ListOfProductLines.Add(CurrentData);
	DetermineConfigurationOption(ListOfProductLines);
	DefineSubassemblyPlanning(CurrentData.RowCode);
	If CurrentData.PlanningASubassembly = Enums.SubassemblySchedulingStatuses.NotRequired Then
		KeyArray = New Array;
		KeyArray.Add(CurrentData.RowCode);
		RemoveSubassemblies(KeyArray);
	EndIf;

EndProcedure

&AtServer
Procedure OperationWhenChangingOnServer()
	
	If Object.FillInUsingFormula Then
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
	EndIf;
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure CalculateQuantityForSubassembliesWhenItemChanges()

	If Object.CrossTable Then
		
		RowOfGoods = Items.GoodsByDates.CurrentRow;
		CurrentData = GoodsByDates.FindByID(RowOfGoods);
		
		For Each PeriodData In ThisForm.TimeIntervals Do
			If Not PeriodData.Active_ Then
				Continue;
			EndIf;
			
			ColumnNameQuantity = "Count_" + PeriodData.ColumnName; 
			ColumnNameCanceled = "Canceled_" + PeriodData.ColumnName; 
			CalculateQuantityForSubCollections(
					CurrentData.RowCode, 
					CurrentData.ProductKit, 
					PeriodData.ColumnName, 
					CurrentData[ColumnNameQuantity], 
					CurrentData[ColumnNameCanceled], 
					CurrentData.Package,
					CurrentData.Products);
					
		EndDo; 		

	Else
		
		RowOfGoods = Items.Goods.CurrentData;
		CurrentData = Object.Goods.FindByID(RowOfGoods);
		
		CalculateQuantityForSubCollections(
				CurrentData.RowCode, 
				CurrentData.ProductKit, 
				CurrentData.DateOfAssemblyDisassembly, 
				CurrentData.Count,
				CurrentData.Canceled);
				
	EndIf; 
	
EndProcedure

&AtServer
Function GetAddressOfPeriodTable()

	Return PutToTempStorage(ThisForm.TimeIntervals.Unload(), UUID);

EndFunction

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	For Each RowOfProduct In ItemsFromStorage Do
		
		Object.FilledAutomatically = False;
		
		If Object.CrossTable Then
			CurrentRow = GoodsByDates.Add();
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
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			If Not ValueIsFilled(CurrentRow.DateOfAssemblyDisassembly) Then
				CurrentRow.DateOfAssemblyDisassembly = Object.BeginOfPeriod;
			EndIf;
			
			RowsToProcess.Add(CurrentRow);
			
		EndIf;
		
		CurrentRow.RowCode = NewProductLineCode(Object);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
		GoodsLineQuantity = GoodsByDates.Count();
	Else
		GoodsLineQuantity = Object.Goods.Count();
	EndIf;
	
	DetermineConfigurationOption();
	
	FillInServiceDetailsForProductInCollection();
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
EndProcedure

#EndRegion

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

#Region SimpleFilling

&AtServer
Procedure InitializeSettingsWhenReadingOnServer(DocumentObject)

	If Not ValueIsFilled(Object.Scenario) Or Not ValueIsFilled(Object.PlanProfile) Then
		Return;
	EndIf;
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("Form", ThisObject);
	InitializationParameters.Insert("AttributePath1", "Object.Goods");
	InitializationParameters.Insert("TableFormElement_", "Goods");
	InitializationParameters.Insert("PeriodTableFormElement", "GoodsByDates");
	InitializationParameters.Insert("BusinessOperation", Object.BusinessOperation);

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
		SelectedRows = Items.Goods.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.Goods.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
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
		SelectedRows = Items.Goods.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.Goods.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
		EndIf;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterQuestionSetArbitraryFormula(QuestionResult, AdditionalParameters) Export
	
	StructureOfData = New Structure("Formula,FormulaPresentation,Title,EnableValue,RowsArray,PeriodOfChange");
	
	If Object.CrossTable Then
		
		SelectedRows = Items.GoodsByDates.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = GoodsByDates.FindByID(SelectedRows[0]);
			
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
		
		SelectedRows = Items.Goods.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = Object.Goods.FindByID(SelectedRows[0]);
			
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
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan");
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
		
		CurrentData = Items.GoodsByDates.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			Operand.Value = ThisObject[Operand.Id];
		EndDo;
		
		CurElementName = Items.GoodsByDates.CurrentItem.Name;
		ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
		
		If ActivePeriods.Count() > 1 Then
			
			If StrFind(CurElementName, "GoodsByDates" + "Count_") = 0
				And StrFind(CurElementName, "GoodsByDates" + "PictureComment_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'")); 
				Return;
			Else
				For Each Period In ActivePeriods Do
					If CurElementName = "GoodsByDates" + "Count_" + Period.ColumnName 
						Or CurElementName = "GoodsByDates" + "PictureComment_" + Period.ColumnName Then
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
		
		CurrentData = Items.Goods.CurrentData;
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
						
					RowOfGoods = GoodsByDates.FindByID(LineID);
					
					If PeriodName = Period.ColumnName  Then
						CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						RowOfGoods["Deviation_" + Period.ColumnName] = 0;
						
						WhenChangingAmountOfRowSum(ThisObject, RowOfGoods);
						
						PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
						
					ElsIf ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) And RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
						CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						
						WhenChangingAmountOfRowSum(ThisObject, RowOfGoods);
						
					EndIf;
					
				ElsIf PeriodName = "AllPeriods" Then
					
					RowOfGoods = GoodsByDates.FindByID(LineID);
					CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
					RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
					RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
					RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
					RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
					RowOfGoods["Deviation_" + Period.ColumnName] = 0;
					
					WhenChangingAmountOfRowSum(ThisObject, RowOfGoods);
					
					PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CalculateTotals_(ThisForm, False);
		
	Else
		
		For Each LineID In RowsArray Do
			
			RowOfGoods = Object.Goods.FindByID(LineID);
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
	UseProduction 				= GetFunctionalOption("UseProduction");
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
	UseInternalConsumptionPlans	= GetFunctionalOption("UsePlanningOfInventoryConsumption")
		And Scenario.UseInPlanningOfInternalConsumption;

	StructureToInsert = "[AssemblyPlansKits] * 1.15";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch đóng bộ +15%';
						|ru = 'План сборки +15%';
						|en = 'Kitting plan +15%'; fa = 'Kitting plan +15%';
						|it = 'Piano di assemblaggio +15%';
						|pl = 'Plan montażu +15%';
						|tr = 'Montaj planı +15%'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseSalesPlans_, "[SalesPlans]", "[SalesFacts] / [ShareOfStockAvailabilityDays]")
		+ ?(UseRemainderPlans, " - [PlanOfGoodsStock]",
			?(PlanningByAssignments, " - [ActualStartBalance]", " - [AvailableStock]"));
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Đảm bảo doanh số bán hàng tối thiểu';
						|ru = 'Минимальное обеспечение продаж';
						|en = 'Min sales provision'; fa = 'Min sales provision';
						|it = 'Approvvigionamento minimo delle vendite';
						|pl = 'Minimalne zabezpieczenie sprzedaży';
						|tr = 'Minimal satış karşılama'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = "Max("
		+ ?(UseSalesPlans_, "[SalesPlans]", "[SalesFacts] / [ShareOfStockAvailabilityDays]")
		+ ", Max([AssemblyPlansKits], [FactsOfAssemblySets]))";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Đóng bộ tối đa';
						|ru = 'Максимальные сборки';
						|en = 'Max kittings'; fa = 'Max kittings';
						|it = 'Assemblaggi massimi';
						|pl = 'Maksymalne montaże';
						|tr = 'Maksimum montajlar'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseSalesPlans_, "[SalesPlans]", "0")
		+ ?(UseProduction And UseForMaterialsPlanning, " + [ProductionPlansMaterials]", "")
		+ ?(UseBuildPlans, " + [BuildPlansComponents]", "")
		+ ?(UseBuildPlans, " + [DisassemblyPlansKits]", "")
		+ ?(UseInternalConsumptionPlans," + [InventoryConsumptionPlans]","");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch nhu cầu';
						|ru = 'Планы потребностей';
						|en = 'Demand plans'; fa = 'برنامه‌های نیاز';
						|it = 'Piani dei fabbisogni';
						|pl = 'Plany zapotrzebowania';
						|tr = 'Gereksinimlerin planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseProcurementPlans, "[PurchasePlans]", "0")
		+ ?(UseProduction And UseProductionPlanning, " + [ProductionPlans]", "")
		+ ?(UseBuildPlans, " + [AssemblyPlansKits]", "")
		+ ?(UseBuildPlans, " + [DisassemblyPlansComponents]", "");
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
		+ ?(UseProduction And UseProductionPlanning, " + [ProductionPlans]", "")
		+ ?(UseProduction And UseForMaterialsPlanning, " - [ProductionPlansMaterials]", "")
		+ ?(UseSalesPlans_, " - [SalesPlans]", "")
		+ ?(UseBuildPlans, " - [BuildPlansComponents]", "")
		+ ?(UseBuildPlans, " - [DisassemblyPlansKits]", "")
		+ ?(UseInternalConsumptionPlans," - [InventoryConsumptionPlans]","");
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
	Presentation = NStr("vi = 'Giá trị cột trước đó';
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
		
		GoodsByDates.Clear();
		Object.Goods.Clear();
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
	
	If Object.CrossTable And Items.GoodsByDates.CurrentData = Undefined Then
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
	
	If Object.CrossTable And Items.GoodsByDates.CurrentData = Undefined Then
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
	FormParameters.Insert("Title",               NStr("vi = 'Chọn hàng hóa';
														|ru = 'Подбор товаров';
														|en = 'Pick goods'; fa = 'انتخاب کالاها';
														|it = 'Selezione delle merci';
														|pl = 'Wybór towarów';
														|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
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
	
	ProductByFilter = Object.Goods.Unload();
	
	Object.Goods.Clear();
	
	For Each Period In ActivePeriods Do
	
		For Each RowOfProduct In ProductByFilter Do
		
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.DateOfAssemblyDisassembly = Period.StartDate;
			CurrentRow.Formula = SettingsStructure.Formula;
			CurrentRow.FormulaPresentation = SettingsStructure.FormulaPresentation;
			CurrentRow.FormulaCalculation = SettingsStructure.Formula;
		
		EndDo; 
	
	EndDo; 
	
EndProcedure

&AtClient
Procedure SetDecryptionParameters(StructureOfData)
	
	If Object.CrossTable Then
		CurrentData = Items.GoodsByDates.CurrentData;
	Else
		CurrentData = Items.Goods.CurrentData;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan");
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
		
		CurElementName = Items.GoodsByDates.CurrentItem.Name;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		For Each Period In TablePeriods.FindRows(New Structure("Active_", True)) Do
			If CurElementName = "GoodsByDates" + "Count_" + Period.ColumnName  Then
				QueryOptions.Insert("OffsetPeriodStart", 	Period.StartDate);
				QueryOptions.Insert("OffsetPeriodEnd", 	Period.EndDate);
			EndIf;
		EndDo;

	Else
		
		CurrentData = Items.Goods.CurrentData;
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		RowsArray = TablePeriods.FindRows(New Structure("StartDate, Active_", CurrentData.DateOfAssemblyDisassembly, True));
		
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
		
		SettingsStructure.Insert("Formula","[AssemblyPlansKits] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch đóng bộ của kỳ trước lên 15%';
															|ru = 'Увеличение планов сборки прошлых периодов на 15%';
															|en = 'Previous period kitting plan increase by 15%'; fa = 'Previous period kitting plan increase by 15%';
															|it = 'Aumento del 15% dei piani di assemblaggio nei periodi precedenti';
															|pl = 'Zwiększenie wcześniejszych planów montażu o 15%';
															|tr = 'Önceki dönemlerin montaj planlarının yüzde 15 artırılması'"));
		
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
				
				SettingsStructure.Insert("Formula","[AssemblyPlansKits] * 1.15");
				SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch đóng bộ của kỳ trước lên 15%';
																	|ru = 'Увеличение планов сборки прошлых периодов на 15%';
																	|en = 'Previous period kitting plan increase by 15%'; fa = 'Previous period kitting plan increase by 15%';
																	|it = 'Aumento del 15% dei piani di assemblaggio nei periodi precedenti';
																	|pl = 'Zwiększenie wcześniejszych planów montażu o 15%';
																	|tr = 'Önceki dönemlerin montaj planlarının yüzde 15 artırılması'"));
				SettingsStructure.Insert("FilterEmptyLines", False);
				
			EndIf;
		EndIf;
	EndIf;
	
	If Not SettingsStructure.Property("FilterEmptyLines") Then
		SettingsStructure.Insert("FilterEmptyLines", False);
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Procedure RecordAdditionalParameters(DocumentObject)

	AddlAttributesArray = GetAdditionalBankingDetails(ThisObject);
	
	For Each CurrentRow In DocumentObject.Goods Do
		
		CollectionItem = Object.Goods.Get(CurrentRow.LineNumber-1);
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

	For Each CurrentRow In DocumentObject.Goods Do
		
		CollectionItem = Object.Goods.Get(CurrentRow.LineNumber-1);
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

#EndRegion

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
		
		If Items.GoodsByDates.CurrentItem.Name = "GoodsByDates" + "Count_" + Period.ColumnName Then
			RowOfGoods["Deviation_" + Period.ColumnName] = CalculationResult.Result - RowOfGoods["Count_" + Period.ColumnName];
		ElsIf RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
			RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
		EndIf;
		
	EndDo;
	
	PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
	
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
Procedure GoodsByDatesOnActivateCell(Item)
	
	AttachIdleHandler("ProductsByDateWhenActivatingCellOnClient", 0.5, True);
	
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
	
	ProcessProductsBeforeSwitchingToCrossTable();
	
	Object.CrossTable = True;
	
	WhenChangingPeriodsOnServer();
	CopyToCrossTable(CachedValues);
	
	DefineSubassemblyPlanning();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCrossTableTag(Form)

	If Form.Object.CrossTable Then
	
		Form.Items.FormSwitchPeriodsToColumns.Check = True;
		Form.Items.FormSwitchPeriodsToRows.Check = False;
		
		Form.Items.ProductsGroupViews.CurrentPage = Form.Items.ProductsGroupCrossTable;
	
	Else
	
		Form.Items.FormSwitchPeriodsToColumns.Check = False;
		Form.Items.FormSwitchPeriodsToRows.Check = True;
		
		Form.Items.ProductsGroupViews.CurrentPage = Form.Items.GroupProductsTable;
	
	EndIf; 

EndProcedure

#Region _dynamic_forming_structure_formingProcedures

&AtServer
Procedure CopyFromCrossTable(CachedValues, Var_ThisObject)
	
	If Var_ThisObject.CrossTable 
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		Planning.FillInTableFromCrossTable(Var_ThisObject.Goods, Object.Goods, GoodsByDates, ConversionParameters, 
			StructureOfActions, CachedValues);
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtServer
Procedure CopyToCrossTable(CachedValues)
	
	If Object.CrossTable
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		For Each TSRow In Object.Goods Do
			If Not ValueIsFilled(TSRow.DateOfAssemblyDisassembly) Then
				TSRow.DateOfAssemblyDisassembly = Object.BeginOfPeriod;
			EndIf;
		EndDo; 
		
		PlanningClientServer.FillInCrossTableFromTable(GoodsByDates, Object.Goods, ConversionParameters);
		
		CalculateTotals_(ThisForm);
		
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByDates");
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	FillInServiceDetailsForProductInCollection();
	
EndProcedure

&AtServer
Function CrossTableConversionParameters()

	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("StartDate","DateOfAssemblyDisassembly");
	
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
	
	GroupFields = "Products,Characteristic,Package,ProductKit,
						|RowCode,Subassembly,RowCodeGoods";
	
	If FillInWarehouseInTabularForm Then
		GroupFields = GroupFields + ", Warehouse";
	EndIf;
	
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
	
		Form.GoodsLineQuantity = Form.GoodsByDates.Count();
	
	Else
	
		Form.GoodsLineQuantity = Form.Object.Goods.Count();
	
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function PlanViewParameters(Form)

	PlanViewParameters = New Structure("FillInWarehouse, PlanningByAssignments, FillInAssignmentInTabularForm, FillInWarehouseInTabularForm");
	FillPropertyValues(PlanViewParameters, Form);
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Function FilterParameters(Form)

	FilterParameters = New Structure("Warehouse, Purpose");
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
	
	If FillInWarehouse And Not ValueIsFilled(Object.Warehouse) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Поле ""Склад"" не заполнено';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie wypełniono pola ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmamış'"),
			Object.Ref,
			"Object.Warehouse");
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

#EndRegion

#Region FillingInBackground

&AtClient
Procedure FillInDocument(Settings)
	
	NotifyUserAboutStartOfFillingInData(); 
	
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
				ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
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
					ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
			EndIf;
			
			NotifyUserAboutFillingInData();
		Except
			Raise;
		EndTry;
	EndIf;
	
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
		For Each RowOfGoods In Form.GoodsByDates Do
			
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
				
				WhenChangingAmountOfRowSum(Form, RowOfGoods);
			
			EndIf;
			
			If Period = LastPeriod
				And RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
				
		EndDo;
		
		PreviousPeriod_ = Period;
		
	EndDo;
	
	If Form.SettingsStructure.ContentFillingVariant =	"Formula" 
		Or Form.SettingsStructure.FilterEmptyLines Then
		For Each RowToDelete In LinesToDelete Do
			Form.GoodsByDates.Delete(RowToDelete);
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
		"Documents.AssemblyDisassemblyPlan.FillInDocument",
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
	
	PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	
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
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	
	JobParameters.Insert("FillInUsingFormula",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.AssemblyDisassemblyPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	FilterIndicators.Insert("FilterBusinessOperation", Object.BusinessOperation);
	
	JobParameters.Insert("Filter",                   FilterIndicators);
	
	Array_SetNames = New Array();
	If JobParameters.Property("PopulateOperands") Then
		
		ArrayOfOperators = GetOperands(ThisObject);
		
		For Each Item In ArrayOfOperators Do
			Array_SetNames.Add(Item.Name);
		EndDo;
	
	EndIf; 
	JobParameters.Insert("Array_SetNames",       Array_SetNames);
	
	PopulatedTS = Object.Goods.Unload();
	If JobParameters.Property("FillingComposition") Then
		PopulatedTS.Clear();
		Array_SetNames = New Array();
		If JobParameters.ContentFillingVariant = "Formula" Then         //OperandsOfTextFormula
			Array_SetNames = PlanningClientServer.OperandsOfTextFormula(JobParameters.Formula);
		Else
			Array_SetNames.Add(JobParameters.ContentFillingVariant);
		EndIf;
		JobParameters.Insert("ArrayOfFillsetNames", Array_SetNames);
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure 

&AtServer
Function PrepareParametersForFillingInReplacementDocument(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.SalesPlan;
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
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	JobParameters.Insert("BusinessOperation",   Object.BusinessOperation);
	
	JobParameters.Insert("FillInAssignmentInTabularForm", 
		Common.ObjectAttributeValue(Object.PlanProfile,"FillInAssignmentInTabularForm"));
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInForReplacement",   True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.AssemblyDisassemblyPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	PopulatedTS = Object.Goods.Unload();
	
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
	
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInRule",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.AssemblyDisassemblyPlan");
	
	PopulatedTS = Object.Goods.Unload();
	If Object.UpdateAdd = 0 Then
		PopulatedTS.Clear();
		Object.MaximumRowCodeGoods = 0;
	EndIf;
	
	JobParameters.Insert("MaximumRowCodeGoods", Object.MaximumRowCodeGoods);
	
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
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure 

&AtServer
Function GetResultOfFillingOnServer(CachedValues)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.AssemblyDisassemblyPlan.Forms.DocumentForm.GetResultOfFillingOnServer");
	
	Table = GetFromTempStorage(StorageAddress);
	
	ProcessedRowsCount = Table.Count();
	
	Object.Goods.Load(Table);
	
	// Formation of an array of periods in which the remainder plans were introduced
	PlannedBalanceIsUsed = Table.Columns.Find("PlannedStartBalance") <> Undefined;
	PlannedBalancesWithSelectionAreUsed = Table.Columns.Find("PlannedStartBalanceWithSelection") <> Undefined;
	If PlannedBalanceIsUsed Then
		
		BalancePlansPeriods.Clear();
		BalancePlanPeriodsWithSelection.Clear();
		
		For Each String In Table Do
			If String.PlannedStartBalance<>0 Then
				If BalancePlansPeriods.FindByValue(String.DateOfAssemblyDisassembly) = Undefined Then
					BalancePlansPeriods.Add(String.DateOfAssemblyDisassembly);
				EndIf;
			EndIf;
			
			If PlannedBalancesWithSelectionAreUsed
				And String.PlannedStartBalanceWithSelection<>0 Then
				If BalancePlanPeriodsWithSelection.FindByValue(String.DateOfAssemblyDisassembly) = Undefined Then
					BalancePlanPeriodsWithSelection.Add(String.DateOfAssemblyDisassembly);
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
		ThisForm.GetAttributes("GoodsByDates").Count()/10,
		"UpdateCrossTableStructure");
	
	For Each LineProducts_ In Object.Goods Do
	
		LineProducts_.RowCode = NewProductLineCode(Object);
	
	EndDo; 
	
	If Object.CrossTable Then
		Object.CrossTable = False;
		DetermineConfigurationOption();
		Object.CrossTable = True;
	Else
		DetermineConfigurationOption();
	EndIf;
	
	ProcessProductsBeforeSwitchingToCrossTable();
	
	CopyToCrossTable(CachedValues);
	
	Object.FilledAutomatically = True;
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	If Object.CrossTable Or PlannedBalanceIsUsed Then
		Goods = GoodsByDates;
	Else
		Goods = Object.Goods;
	EndIf; 
	
	IndexOf = Goods.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf -1;
		TSRow = Goods[IndexOf];
		If FilterByProductType.Find(TSRow.ItemsType) = Undefined Then
			Goods.Delete(IndexOf);
		EndIf; 
	EndDo;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
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
		
		For Each RowOfGoods In Goods Do
			If RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
		EndDo;

		For Each RowToDelete In LinesToDelete Do
			Goods.Delete(RowToDelete);
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
Procedure FillInDataForReplacement()
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillInForReplacement");
	
	FillInDocument(Settings);
	
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
	
	For Each LineProducts_ In Object.Goods Do
		
		LineProducts_.RowCode = NewProductLineCode(Object);
		
	EndDo;
	
	FillInServiceDetailsForProductInCollection();
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(Enums.ItemsTypes.Work_5);
	
	Goods = Object.Goods;
	IndexOf = Goods.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf -1;
		TSRow = Goods[IndexOf];
		If FilterByProductType.Find(TSRow.ItemsType) = Undefined Then
			Goods.Delete(IndexOf);
		EndIf; 
	EndDo;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

#EndRegion

&AtServerNoContext
Function ScriptParameters_(Scenario)

	Attributes = "Periodicity, ShowNumberOfPeriod, PlanningByAssignments";
	Attributes = Attributes + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, Attributes);
	
	Return ScriptParameters_;

EndFunction 

&AtClient
Procedure DeleteEmptyLines(Command)
	
	DeleteBlankLinesOnServer();
	
EndProcedure

&AtServer
Procedure DeleteBlankLinesOnServer()
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	
	ItIsNecessaryToRecalculateResults = False;
	
	IndexOf =  GoodsByDates.Count() -1;
	
	While IndexOf >= 0 Do
	
		TSRow = GoodsByDates[IndexOf];
		
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
		
			GoodsByDates.Delete(IndexOf);
			ItIsNecessaryToRecalculateResults = True;
		
		EndIf; 
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	If ItIsNecessaryToRecalculateResults Then
	
		CalculateTotals_(ThisForm, False);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductsByDateWhenActivatingCellOnClient()
	
	If Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "GoodsByDates");
	EndIf;
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	CurrentData = Items.GoodsByDates.CurrentData;
	
	If ActivePeriods.Count() = 1 Then
		If Not Object.FillInUsingFormula And CurrentData <> Undefined Then
			Details = PlanningClient.GenerateDecryption(CurrentData, "Details_" + ActivePeriods[0].ColumnName);
		EndIf;
		Return;
	EndIf;
	
	CellIsCanceled = False;
	CellComment = "";
	CellFound = False;
	
	Item = Items.GoodsByDates;
	
	CurrentData = Items.GoodsByDates.CurrentData;
	If CurrentData = Undefined Then
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf; 
	
	If Item.CurrentItem <> Undefined Then
		For Each Period In ActivePeriods Do
			If Item.CurrentItem.Name = "GoodsByDates" + "Count_"+Period.ColumnName Then
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
	
	Items.CellIsCanceled.Enabled = CellFound;
	Items.CellComment.Enabled = CellFound;

EndProcedure

#Region PlanSubstitution

&AtClientAtServerNoContext
Function ReplaceParameters(Val Object)

	ReplaceParameters = New Structure;
	
	ReplaceParameters.Insert("Ref", Object.Ref);
	ReplaceParameters.Insert("PlanProfile", Object.PlanProfile);
	ReplaceParameters.Insert("Status", Object.Status);
	ReplaceParameters.Insert("Date", Object.Date);
	ReplaceParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	ReplaceParameters.Insert("PeriodEnding", Object.PeriodEnding);
	ReplaceParameters.Insert("Periodicity", Object.Periodicity);
	
	ReplaceParameters.Insert("Warehouse", Object.Warehouse);
	ReplaceParameters.Insert("BusinessOperation", Object.BusinessOperation);
	ReplaceParameters.Insert("Purpose", Object.Purpose);
	
	Return ReplaceParameters
	
EndFunction

&AtServer
Procedure UpdateReplacementAttribute()

	For Each String In Object.Goods Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	If Not Object.Substitutional Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
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
	|SELECT DISTINCT
	|	AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, YEAR)
	|		ELSE AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly
	|	END AS Period
	|INTO AssemblyDisassemblyPlanProducts
	|FROM
	|	&AssemblyDisassemblyPlanProducts AS AssemblyDisassemblyPlanProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly
	|FROM
	|	SubstitutedPeriods AS SubstitutedPeriods
	|		INNER JOIN AssemblyDisassemblyPlanProducts AS AssemblyDisassemblyPlanProducts
	|		ON SubstitutedPeriods.SubstitutedPeriod = AssemblyDisassemblyPlanProducts.Period";
	
	Query.SetParameter("SubstitutedPeriods", SubstitutedPeriods.Unload());
	Query.SetParameter("AssemblyDisassemblyPlanProducts", Object.Goods.Unload());
	
	Query.SetParameter("Periodicity", Object.Periodicity);
	
	RequestPackage = Query.ExecuteBatch(); 
	Selection = RequestPackage[2].Select();
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfAssemblyDisassembly", Selection.DateOfAssemblyDisassembly);
		ReplacementLines = Object.Goods.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = Selection.Substituted;
			String.SubstitutedToOrder = Selection.SubstitutedToOrder;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function FillInSubstitutedPeriods()
	
	ReplaceParameters = ReplaceParameters(Object);
	Result = Planning.GetSubstitutedPeriods(ReplaceParameters, "AssemblyDisassemblyPlan");
	
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

#EndRegion

#Region AdjustmentsToPlannedDemands

&AtClient
Procedure DecorationCanceledNeedsAdjustmentsClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("ShowAssignment", Items.GoodsPurpose.Visible);
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
	FormParameters.Insert("ShowAssignment", Items.GoodsPurpose.Visible);
	FormParameters.Insert("Filter", New Structure("Plan", Object.Ref));
	FormParameters.Insert("Status", PredefinedValue("Enum.StatusesOfPlanAdjustments.ForChecking"));
	
	OpenForm(
		"Document.AdjustmentOfPlannedDemand.Form.ListForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustDemand(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	
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
	
	CurrentRow = Items.Goods.CurrentData;
	
	CurrentRow.Count = AdditionalParameters.ToSupply;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, New Structure("RecalculateNumberOfPackages"), CachedValues);
	
	Items.Goods.RowInputMode = TableRowInputMode.AfterCurrentRow;
	
	If ValueIsFilled(AdditionalParameters.NomenclatureAdjustment)
		And AdditionalParameters.ToEnsureTheAdjustment > 0 Then
		FilterParameters = New Structure();
		FilterParameters.Insert("Products", AdditionalParameters.NomenclatureAdjustment);
		FilterParameters.Insert("Characteristic", AdditionalParameters.FeatureAdjustment);
		FilterParameters.Insert("Purpose", AdditionalParameters.PurposeAdjustment);
		
		AdjustmentLines = Object.Goods.FindRows(FilterParameters);
		
		If AdjustmentLines.Count()>0 Then
			AdjustmentLines[0].Count = AdditionalParameters.ToTheAdjustmentOfTheAdjustment;
			BatchProcessingOfTablePartClient.ProcessTSString(AdjustmentLines[0], New Structure("RecalculateNumberOfPackages"), CachedValues);
		Else
			NewRow = Object.Goods.Add();
			NewRow.Products = AdditionalParameters.NomenclatureAdjustment;
			NewRow.Characteristic = AdditionalParameters.FeatureAdjustment;
			NewRow.Purpose = AdditionalParameters.PurposeAdjustment;
			NewRow.Count = NewRow.Count - AdditionalParameters.ToTheAdjustmentOfTheAdjustment;
			NewRow.NumberOfPackages = NewRow.Count;
			NewRow.DateOfAssemblyDisassembly = AdditionalParameters.Period;
			GoodsProductsOnChange(Undefined);
		EndIf;
	EndIf;
	
	Items.Goods.RowInputMode = TableRowInputMode.EndOfList;
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

#EndRegion

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
	
	CurrentRow = Items.Goods.CurrentData;
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
		CancelProvisionAdjustmentOnClient(Items.Goods.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	If FillInByShortage 
		And Item.CurrentItem.Name = "GoodsNumberOfPackages" Then
		
		AdjustSecurity();
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
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
	
	CurrentRow = Items.Goods.CurrentData;
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
	
	SelectedRows = Items.Goods.SelectedRows;
	For Each RowID In SelectedRows Do
		SelectedRow = Object.Goods.FindByID(RowID);
			
		If SelectedRow.DemandRangeIsSpecified Then
			CancelProvisionAdjustmentOnClient(SelectedRow);
		EndIf;
	EndDo
	
EndProcedure

&AtClient
Procedure CancelAllAdjustments(Command)
	For Each String In Object.Goods Do
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
	
	Items.Goods.RowFilter = New FixedStructure("DemandRangeIsSpecified", True);
	
EndProcedure

&AtClient
Procedure ShowAllItems(Command)
	
	Items.Goods.RowFilter = Undefined;
	
EndProcedure

&AtClient
Procedure DecorationCanceledSecurityAdjustmentsClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Plan", Object.Ref);
	FormParameters.Insert("ShowAssignment", Items.GoodsPurpose.Visible);
	FormParameters.Insert("Filter", New Structure("Plan", Object.Ref));
	
	OpenForm(
		"InformationRegister.CancelAdjustmentsOfSupplyPlans.Form.ListFormAccordingToPlan",
		FormParameters,
		ThisObject);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "AssemblyDisassemblyPlan.Goods";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ""Bộ"" từ tệp';
												|ru = 'Загрузка таблицы ""Комплекты"" из файла';
												|en = 'Import the Kits table from the file'; fa = 'Import the Kits table from the file';
												|it = 'Scaricamento della tabella ""Kit"" dal file';
												|pl = 'Wczytywanie tabeli ""Zestawy"" z pliku';
												|tr = 'Dosyadan ""Ürün setleri"" tablosunun indirilmesi'");
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
		
		GoodsByDates.Clear();
		
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "Goods");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Bộ đóng gói';
																|ru = 'Комплекты';
																|en = 'Kits'; fa = 'کیت‌ها';
																|it = 'Kit';
																|pl = 'Kits';
																|tr = 'Ürün setleri'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfAssemblyDisassembly");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày đóng bộ (tách bộ)';
																|ru = 'Дата сборки (разборки)';
																|en = 'Date of kitting'; fa = 'تاریخ کیت‌سازی';
																|it = 'Data di assemblaggio (disassemblaggio)';
																|pl = 'Data montażu (demontażu)';
																|tr = 'Montaj (demontaj) tarihi'"));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		TheStructureOfTheSearch = New Structure("Subassembly", True);
		ListOfSubassemblies = Object.Goods.FindRows(TheStructureOfTheSearch);
		
		If Cancel Or ListOfSubassemblies.Count() <> 0 Then
			
			If Cancel Then
				Common.MessageToUser(NStr("vi = 'Trong dòng danh sách ""Bộ"" đã chỉ ra ngày ngoài biên lập kế hoạch - đã xóa dòng.';
											|ru = 'В строках списка ""Комплекты"" указаны даты за границами планирования - строки были удалены.';
											|en = 'Dates outside the planning fences are specified in lines of the Kits list. The lines were removed.'; fa = 'Dates outside the planning fences are specified in lines of the Kits list. The lines were removed.';
											|it = 'Nelle righe dell''elenco ""Kit"" le date vanno oltre i limiti della pianificazione - le righe sono state eliminate.';
											|pl = 'W wierszach listy ""Zestawy"" są podane daty poza granicami planowania - wiersze zostały usunięte.';
											|tr = '""Setler"" listesinin satırlarında planlama sınırı için belirtilen tarihler. Satırlar silindi.'"));
			EndIf;
			If ListOfSubassemblies.Count() <> 0 Then
				Common.MessageToUser(NStr("vi = 'Trong danh sách ""Bộ"" đã xóa tất cả đóng bộ được lập kế hoạch.';
											|ru = 'В списке ""Комплекты"" были удалены все запланированные подсборки.';
											|en = 'All scheduled subassemblies in the Kits list were deleted.'; fa = 'All scheduled subassemblies in the Kits list were deleted.';
											|it = 'Nell''elenco ""Kit"" sono state eliminate tutte le sottounità di assemblaggio programmati.';
											|pl = 'Na liście ""Zestawy"" zostały usunięte wszystkie zaplanowane podzespoły.';
											|tr = '""Setler"" listesinde planlanan tüm alt montajlar silindi.'"));
			EndIf;
			
		EndIf;
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
	EndIf;
	
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
