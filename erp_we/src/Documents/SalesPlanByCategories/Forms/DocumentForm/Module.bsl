#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details
&AtClient
Var RepeatCallBeforeRecording; // Used for non-modal questions before recording
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
	
	PlanningByAssignments = Common.ObjectAttributeValue(Object.Scenario,"PlanningByAssignments");
	
	Planning.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		UpdateRule = Object.FillingRule.Count() = 0;
		PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, UpdateRule, FillingRuleAddress, CustomSettingsAddress);
		FillPropertyValues(ThisForm, PlanViewParameters);
		FillPropertyValues(Object, PlanViewParameters,"FillInUsingFormula,Substitutional");
		
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
	
	SetAvailabilityOfClipboardCommands();
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
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
		"Document.SalesPlanByCategories.DocumentForm.Event.BeforeWrite");
	
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
	
	FillInServiceDetailsInCollection();
	
	
	
	If Object.FillInUsingFormula Then
		ReadMoreParameters(CurrentObject);
	EndIf;
	
	SetVisibility1();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "SalesPlanByCategories");

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	ElsIf EventName = "WorkingWithExcelClient_DownloadFromExcel"
		And Parameter.FormUniqueID = ThisForm.UUID Then

		LoadFromExcelOnClient(Parameter.DownloadData);
		
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
		StructureOfActions.Insert("TablePresentation",NStr("vi = 'Thể loại hàng hóa';
															|ru = 'Товарные категории';
															|en = 'Product categories'; fa = 'دسته‌های محصول';
															|it = 'Categorie di merci';
															|pl = 'Kategorie towarowe';
															|tr = 'Ürün kategorileri'"));
		StructureOfActions.Insert("TablePath","ProductCategoriesByPeriods");
		StructureOfActions.Insert("FillInProductCategory");
		If FillInWarehouseInTabularForm And Not FillInByServiceData Then
			StructureOfActions.Insert("FillInWarehouseInTabularForm");
		EndIf; 
		
		CheckParameters = New Structure;
		CheckParameters.Insert("TimeIntervals", ThisObject["TimeIntervals"].Unload(New Structure("Active_", True)));
		CheckParameters.Insert("FieldPrefix", "Count_");
		CheckParameters.Insert("FieldName", "Count");
		StructureOfActions.Insert("CheckingQuantityByPeriod", CheckParameters);
		
		StructureOfActions.Insert("GroupFields", "ProductCategory, SalesRank, Warehouse, Purpose");
		
		Planning.ProcessingFormFillVerification(ProductCategoriesByPeriods, StructureOfActions, Cancel, CheckedAttributes, Object.CrossTable); 
		
	Else
		
		NotCheckedAttributeArray.Add("ProductCategoriesByPeriods");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_SalesPlanByCategories", , Object.Ref);
	
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
		And (Object.CrossTable And ProductCategoriesByPeriods.Count() = 0
		Or Not Object.CrossTable And Object.ProductCategories.Count() = 0)
		And Items.GroupPages.CurrentPage = Items.GroupProductCategories Then
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
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductCategoriesByPeriods", Notification);
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductCategoriesByPeriods", Notification);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure StoreFormatOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
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

#Region FormTableItemsEventHandlersProductCategories

&AtClient
Procedure ProductCategoriesOnChange(Item)
	
	Object.FilledAutomatically = False;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductCategoriesOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductCategoriesAfterDeleteRow(Item)
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure ProductCategoriesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.SalesPlanByCategoriesAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductCategoriesOnActivateRow(Item)
	If Not Object.FillInUsingFormula And Items.ProductCategories.SelectedRows.Count() > 0 Then
		UBound = Items.ProductCategories.SelectedRows.UBound();
		Details = PlanningClient.GenerateDecryption(Object.ProductCategories.FindByID(Items.ProductCategories.SelectedRows[UBound]));
	Else
		Details = "";
	EndIf;
EndProcedure

&AtClient
Procedure ProductCategoriesCountOnChange(Item)
	
	CurrentRow = Items.ProductCategories.CurrentData;

	CalculateTotals_(ThisForm);
	
	CurrentRow.Details = String(CurrentRow.Count);
	Details = PlanningClient.GenerateDecryption(CurrentRow);
	
	If CurrentRow.Property("Deviation") And ValueIsFilled(CurrentRow.Formula) Then
		CalculationResult = PlanningClient.CalculateByFormula(CurrentRow.Formula, CurrentRow, Undefined, Undefined);
		CurrentRow.Deviation = CalculationResult.Result - CurrentRow.Count;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductCategoriesCommentOnChange(Item)
	
	Items.ProductCategories.CurrentData.PictureComment = ValueIsFilled(Items.ProductCategories.CurrentData.Comment);
	
EndProcedure

&AtClient
Procedure ProductCategoriesCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalParameters = New Structure("CurrentRow", Items.ProductCategories.CurrentRow);
	Notification = New CallbackDescription("ProductCategoriesCommentStartChoiceCompletion", ThisObject, AdditionalParameters);
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
Procedure ProductCategoriesCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ProductCategories.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.Comment = EnteredText;
	CurrentData.PictureComment = ValueIsFilled(EnteredText);
	Modified = True;
	
EndProcedure

&AtClient
Procedure ProductCategoriesCanceledOnChange(Item)
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure ProductCategoriesDateOfShipmentOnChange(Item)
	If Object.Substitutional
		And Object.Posted
		And SubstitutedPeriods.Count() > 0 Then
		CurrentData = Items.ProductCategories.CurrentData;
		DateOfReceiptBeginningOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(CurrentData.DateOfShipment, Object.Periodicity);
		Filter = New Structure("SubstitutedPeriod", DateOfReceiptBeginningOfPeriod);
		CurrentData.Substituted = SubstitutedPeriods.FindRows(Filter).Count() > 0;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductCategoriesByPeriods

&AtClient
Procedure ProductCategoriesByPeriodsOnChange(Item)
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductCategoriesByPeriods");
	
	Object.FilledAutomatically = False;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductCategoriesByPeriodsOnActivateCell(Item)
	
	AttachIdleHandler("ProductCategoriesByPeriodWhenActivatingCellOnClient", 0.5, True);
	
EndProcedure

&AtClient
Procedure ProductCategoriesByPeriodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf; 
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductCategoriesByPeriodsAfterDeleteRow(Item)
	
	CalculateTotals_(ThisForm, False);
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductCategoriesByPeriods");
	
EndProcedure

&AtClient
Procedure ProductCategoriesByPeriodsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.SalesPlanByCategoriesAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

// Attachable when the quantity changes.
// 
// Parameters:
//  Item - FormField
&AtClient
Procedure Attachable_WhenChangingQuantity(Item)
	
	RowOfGoods = Items.ProductCategoriesByPeriods.CurrentData;
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
	
	If Not Object.FillInUsingFormula Then
		TheCurrentNameOfTheColumn = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Item.Name,
			"ProductCategoriesByPeriods" + "Count_")[1];
		
		RowOfGoods["Details_" + TheCurrentNameOfTheColumn] = String(RowOfGoods["Count_" + TheCurrentNameOfTheColumn]);
		Details = PlanningClient.GenerateDecryption(RowOfGoods, "Details_" + TheCurrentNameOfTheColumn);
	EndIf;
	
	If Object.FillInUsingFormula Then
		WhenChangingQuantityDeviation(RowOfGoods);
	EndIf;
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeCanceled(Item)
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingComment(Item)
	
	CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	
	If CurrentData <> Undefined And Items.ProductCategoriesByPeriods.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.ProductCategoriesByPeriods.CurrentItem.Name = "ProductCategoriesByCommentPeriod_"+Period.ColumnName Then
				
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
	
	CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	StandardProcessing = False;
	
	If CurrentData <> Undefined And Items.ProductCategoriesByPeriods.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.ProductCategoriesByPeriods.CurrentItem.Name = "ProductCategoriesByCommentPeriod_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				
				AdditionalParameters = New Structure("CurrentRow, ColumnName", 
					Items.ProductCategoriesByPeriods.CurrentRow,
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
	
	CurrentData = ProductCategoriesByPeriods.FindByID(AdditionalParameters.CurrentRow);
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInProductCategories(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	If DisableEditingOfPopulationSettings Then
		SetUpFormulaAndFillIn(SettingsStructure, Undefined);
		Return;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories");
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
	
	Notification = New CallbackDescription("SetUpFormulaAndFillIn",ThisObject);
	
	OpenForm("Catalog.PlanProfiles.Form.SettingsForm", 
		New Structure("SettingsStructure",FormParameters), 
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInIndicators(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("PeriodStartPlan",    Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEndPlan", Object.PeriodEnding);
	FormParameters.Insert("Periodicity",        Object.Periodicity);
	FormParameters.Insert("SettingsStructure",    AdditionalSettings(SettingsStructure));
	FormParameters.Insert("Owner",             Object.Ref);
	
	If StrFind(FormParameters.SettingsStructure.Formula , "PlannedStartBalance")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalBalances")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalDeficit")<>0 Then
		AdjustOffsetAndFill(FormParameters.SettingsStructure, Undefined);
	Else
		Notification = New CallbackDescription("AdjustOffsetAndFill", ThisObject);
		OpenForm("Catalog.PlanProfiles.Form.SettingsFormOfTimeShift", 
			New Structure("SettingsStructure",FormParameters), 
			ThisForm,
			UUID,
			,
			,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureAndPopulateAccordingToTheFillingRule(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("UpdateAdd",                Object.UpdateAdd);
	FormParameters.Insert("FillingRuleAddress",           FillingRuleAddress);
	FormParameters.Insert("ChangeResultTo",              Object.ChangeResultTo);
	FormParameters.Insert("RoundingPrecision",               Object.RoundingPrecision);
	FormParameters.Insert("Periodicity",                    Object.Periodicity);
	FormParameters.Insert("PlanProfile",                         Object.PlanProfile);
	FormParameters.Insert("CustomSettingsAddress",    CustomSettingsAddress);
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
Procedure InsertRows(Command)
	
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
		
		NumberOfProductsBeforeInsertion = Object.ProductCategories.Count();
		
		GetLinesFromClipboard();
		
		NumberOfInserted = Object.ProductCategories.Count()-NumberOfProductsBeforeInsertion;
		ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
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
		FormTable = Items.ProductCategories;
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
	AdditionalParameters.PlanType               = "SalesPlanByCategories";
	AdditionalParameters.AssignmentsAreUsed = FillInAssignmentInTabularForm;
	AdditionalParameters.WarehousesAreUsed     = FillInWarehouseInTabularForm;
	
	AdditionalParameters.CalculationOfSalesRateIsUsed = UseCalculationBySalesSpeed;
	
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
	
	ProcessingWithExcelClient.SelectAttachedExcelFile(ThisForm, ?(Object.CrossTable, "ProductCategoriesByPeriods", "ProductCategories"));
	
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
		CheckParameters.Insert("TSName",                    "ProductCategories");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Thể loại hàng hóa';
																|ru = 'Товарные категории';
																|en = 'Product categories'; fa = 'دسته‌های محصول';
																|it = 'Categorie di merci';
																|pl = 'Kategorie towarowe';
																|tr = 'Ürün kategorileri'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
																|ru = 'Дата отгрузки';
																|en = 'Shipment date'; fa = 'تاریخ ارسال';
																|it = 'Data di spedizione';
																|pl = 'Data wysyłki';
																|tr = 'Sevkiyat tarihi'"));
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
			QueryText = NStr("vi = 'Tại các dòng của danh sách ""Thể loại hàng hóa"" đã chỉ ra ngày ngoài biên lập kế hoạch - các dòng sẽ bị xóa. Xóa dòng?';
							|ru = 'В строках списка ""Товарные категории"" указаны даты за границами планирования - строки будут удалены. Удалить строки?';
							|en = 'Dates outside the planning fences are specified in lines of the ""Product categories"" list. Lines will be deleted. Delete the lines?'; fa = 'Dates outside the planning fences are specified in lines of the ""Product categories"" list. Lines will be deleted. Delete the lines?';
							|it = 'Nelle righe dell''elenco ""Categorie merceologiche"" le date indicate sono oltre i limiti di pianificazione - le righe verranno eliminate. Eliminare le righe?';
							|pl = 'W wierszach listy ""Kategorie towarów"" znajdują się daty wykraczające poza granice planowania - wiersze zostaną usunięte. Usunąć linie?';
							|tr = '""Ürün kategorileri"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silinecek. Silinsin mi?'");
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
		FillInServiceDetailsInCollection();
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
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
			
			If Items.ProductCategoriesByPeriods.CurrentData = Undefined Then
				Return;
			EndIf;
			
			CurElementName = Items.ProductCategoriesByPeriods.CurrentItem.Name;
			
			If StrFind(CurElementName, "ProductCategoriesByPeriodsCount_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'"));
				Return;
			EndIf;

			If CurElementName = "ProductCategoriesByPeriodsCount_"+Period.ColumnName Then
				
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
			
			If (Object.CrossTable And Items.ProductCategoriesByPeriods.CurrentData = Undefined) 
					Or (Not Object.CrossTable And Items.ProductCategories.CurrentData = Undefined) Then
				Return;
			EndIf;

			AfterQuestionSetArbitraryFormula(DialogReturnCode.No, AdditionalParameters);
			
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeByPercentage(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ChangeByPercentageCompletion", ThisObject);
	
	PlanningClient.ChangeFormulaToPercentage(
		ThisForm, 
		?(Object.CrossTable, ProductCategoriesByPeriods, Object.ProductCategories), 
		?(Object.CrossTable, "ProductCategoriesByPeriods", "ProductCategories"),
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
		?(Object.CrossTable, ProductCategoriesByPeriods, Object.ProductCategories), 
		?(Object.CrossTable, "ProductCategoriesByPeriods", "ProductCategories"),
		Notification);
	
EndProcedure

&AtClient
Procedure AddProductCategoriesByFilter(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	AddProductCategoriesBySelectionOnClient();
	
EndProcedure

&AtClient
Procedure CancelPlanLines(Command)
	
	Notification = New CallbackDescription("CancelPlanLinesCompletion", ThisObject);
	If Object.CrossTable Then
		PlanningClient.CancelPlanLines(ThisForm, ProductCategoriesByPeriods, "ProductCategoriesByPeriods", Notification);
	Else
		PlanningClient.CancelPlanLines(ThisForm, Object.ProductCategories, "ProductCategories", Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteEmptyLines(Command)
	
	DeleteBlankLinesOnServer();
	
EndProcedure

&AtClient
Procedure FillInAWarehouseByTheValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.ProductCategoriesByPeriods.SelectedRows,Items.ProductCategories.SelectedRows);
	GoodsTable = ?(Object.CrossTable, ProductCategoriesByPeriods, Object.ProductCategories);
	
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
	
	SelectedRows = ?(Object.CrossTable, Items.ProductCategoriesByPeriods.SelectedRows,Items.ProductCategories.SelectedRows);
	GoodsTable = ?(Object.CrossTable, ProductCategoriesByPeriods, Object.ProductCategories);
	
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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductCategories.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductCategories.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductCategories.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductCategories.Substituted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	If GetFunctionalOption("UseSalesRanks") Then
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ProductCategoriesSalesRank.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ProductCategories.SalesRank");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không đánh giá kết quả bán hàng>';
														|ru = '<без рейтинга продаж>';
														|en = '<without sales rank>'; fa = '<without sales rank>';
														|it = '<senza il ranking delle vendite>';
														|pl = '<bez rankingu sprzedaży>';
														|tr = '<satış sıralaması olmadan>'"));
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ProductCategoriesByPeriodsSalesRank.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductCategoriesByPeriods.SalesRank");
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

&AtServer
Procedure SetConditionalAppearanceOfCrossTable()
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	CurrentFont = Items.ProductCategoriesByPeriods.Font;
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
		ItemField.Field = New DataCompositionField("ProductCategoriesByPeriodsCount_"+Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductCategoriesByPeriods.Canceled_"+Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("Font", StrikethroughFont);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("ProductCategoriesByPeriodsCount_"+Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductCategoriesByPeriods.Substituted_"+ Period.ColumnName);
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
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "ProductCategoriesByPeriods", Notification);
	
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

#Region ProceduresForDynamicFormationOfFormStructure

&AtClient
Procedure WhenChangingPeriodsOnClient(Result, AdditionalParameters) Export 
	
	WhenChangingPeriodsOnServer();
	
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
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCrossTableTag(Form)

	If Form.Object.CrossTable Then
	
		Form.Items.FormSwitchPeriodsToColumns.Check = True;
		Form.Items.FormSwitchPeriodsToRows.Check = False;
		
		Form.Items.GroupProductCategoriesViews.CurrentPage = Form.Items.GroupProductCategoriesCrossTable;
		
	Else
	
		Form.Items.FormSwitchPeriodsToColumns.Check = False;
		Form.Items.FormSwitchPeriodsToRows.Check = True;
		
		Form.Items.GroupProductCategoriesViews.CurrentPage = Form.Items.GroupProductCategoriesTable;
	
	EndIf; 

EndProcedure

#EndRegion

#Region ProceduresForExchangingDataBetweenTablePartAndFormTable

&AtServer
Procedure CopyFromCrossTable(CachedValues, Var_ThisObject)
	
	If Var_ThisObject.CrossTable 
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		Planning.FillInTableFromCrossTable(Var_ThisObject.ProductCategories, Object.ProductCategories, ProductCategoriesByPeriods, ConversionParameters);
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtServer
Procedure CopyToCrossTable(CachedValues)
	
	If Object.CrossTable
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		For Each TSRow In Object.ProductCategories Do
			If Not ValueIsFilled(TSRow.DateOfShipment) Then
				TSRow.DateOfShipment = Object.BeginOfPeriod;
			EndIf;
		EndDo; 
		
		PlanningClientServer.FillInCrossTableFromTable(ProductCategoriesByPeriods, Object.ProductCategories, ConversionParameters);
		
		CalculateTotals_(ThisForm);
		
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductCategoriesByPeriods");
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	FillInServiceDetailsInCollection();
	
EndProcedure

&AtServer
Function CrossTableConversionParameters()

	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("StartDate","DateOfShipment");
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Count_", "Count");
	AttributesStructure1.Insert("Canceled_","Canceled");
	AttributesStructure1.Insert("Substituted_","Substituted");
	AttributesStructure1.Insert("Comment_","Comment");
	
	If Object.FillInUsingFormula Then
		AddBankingDetailsFromAdditionalParameters(AttributesStructure1);
	Else
		AttributesStructure1.Insert("Details_","Details");
	EndIf;
	
	GroupFields = "ProductCategory, SalesRank";
	
	If FillInWarehouseInTabularForm Then
		GroupFields = GroupFields + ", Warehouse";
	EndIf;
	
	If FillInAssignmentInTabularForm Then
		GroupFields = GroupFields + ", Purpose";
	EndIf;
	
	StructureOfFinalDetails = New Structure;
	StructureOfFinalDetails.Insert("Count", "Count");
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("Periodicity",               Object.Periodicity);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	If Not UseCalculationBySalesSpeed Then
		ConversionParameters.Insert("StructureOfFinalDetails", StructureOfFinalDetails);
	EndIf;
	
	Return ConversionParameters;

EndFunction
 
#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected)
	
	If Not IsTempStorageURL(ValueSelected.AddressOfProductCategoriesInStorage) Then
		Return;
	EndIf;
	
	GetDownloadedProductCategoriesFromStorage(ValueSelected.AddressOfProductCategoriesInStorage, CachedValues);
	
EndProcedure

#EndRegion

&AtClient
Procedure SetCancelAndCommentCells()
	
	CellFound = False;
	
	CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	If CurrentData = Undefined Then
		CellIsCanceled = False;
		CellComment = "";
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf; 
	
	If Items.ProductCategoriesByPeriods.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.ProductCategoriesByPeriods.CurrentItem.Name = "ProductCategoriesByPeriodsCount_"+Period.ColumnName Then
				
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
		SelectedRows = Items.ProductCategoriesByPeriods.SelectedRows;
	Else
		SelectedRows = Items.ProductCategories.SelectedRows;
	EndIf; 
	
	If SelectedRows.Count() > 0 Then
		CalculateTotals_(ThisForm);
	EndIf; 
	
EndProcedure

#Region ProcessingWithExcel

&AtServer
Function LoadFromExcelOnServer(ArrayOfDataStructures)
	
	If Object.CrossTable Then
		ProductCategoriesByPeriods.Clear();
	Else
		Object.ProductCategories.Clear();
	EndIf; 
	
	// ID Processing
	For Each ProductStructure_1 In ArrayOfDataStructures Do
		
		If Not ValueIsFilled(ProductStructure_1.IdProductCategory) Then
			Continue;
		EndIf;
		
		ProductStructure_1.Insert("ProductCategory", Catalogs.ProductCategories.GetRef(New UUID(ProductStructure_1.IdProductCategory)));
		ProductStructure_1.Insert("SalesRank",     Catalogs.SalesRanks.GetRef(New UUID(ProductStructure_1.IDSalesRating)));
		ProductStructure_1.Insert("Warehouse",             Catalogs.Warehouses.GetRef(New UUID(ProductStructure_1.WarehouseID_)));
		ProductStructure_1.Insert("Purpose",        Catalogs.Assignments.GetRef(New UUID(ProductStructure_1.DestinationID_)));
		
	EndDo;
	
	AddProductCategories(ArrayOfDataStructures);
	
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
	
		If Not ValueIsFilled(LoadingString.IdProductCategory) Then
			
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
			ProductCategoriesByPeriods.Clear();
			Object.ProductCategories.Clear();
		EndIf;
		GetDownloadedProductCategoriesFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Function StructureOfActionsWhenLoadingFromExcel()

	ExcelActionStructure = New Structure;
	
	// Defining columns by their headers
	SearchColumns = New ValueList;
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Thể loại hàng hóa)';
							|ru = 'Уникальный идентификатор (Товарная категория)';
							|en = 'UUID (Product category)'; fa = 'UUID (طبقه محصول)';
							|it = 'ID unico (Categoria di prodotto)';
							|pl = 'Unikalny identyfikator (Kategoria towarowa)';
							|tr = 'Benzersiz tanımlayıcı (Ürün kategorisi)'"),"IdProductCategory");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Kết quả bán hàng)';
							|ru = 'Уникальный идентификатор (Рейтинг продаж)';
							|en = 'UUID (Sales rating)'; fa = 'UUID (رتبه فروش)';
							|it = 'ID unico (rating vendita)';
							|pl = 'Unikalny identyfikator (Ranking sprzedaży)';
							|tr = 'Benzersiz tanımlayıcı (Satış sıralaması)'"),"IDSalesRating");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Kho)';
							|ru = 'Уникальный идентификатор (Склад)';
							|en = 'Unique ID (Warehouse)'; fa = 'شناسه یکتا (انبار)';
							|it = 'Identificatore unico (Magazzino)';
							|pl = 'Indywidualny identyfikator (Magazyn)';
							|tr = 'Benzersiz tanımlayıcı (Ambar)'"),"WarehouseID_");
	
	SearchColumns.Add(NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Articolo';
							|pl = 'Items';
							|tr = 'Ürün'"),"ImportedProductCategory");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Mục đích)';
							|ru = 'Уникальный идентификатор (Назначение)';
							|en = 'Unique ID (Assignment)'; fa = 'شناسه یکتا (تخصیص)';
							|it = 'Identificatore unico (Assegnazione)';
							|pl = 'Indywidualny identyfikator (Przeznaczenie)';
							|tr = 'Benzersiz tanımlayıcı (Atama)'"),"DestinationID_");
	
	If UseCalculationBySalesSpeed Then
		SearchColumns.Add(NStr("vi = 'Đánh giá bán hàng';
								|ru = 'Рейтинг продаж';
								|en = 'Sales rank'; fa = 'رتبه فروش';
								|it = 'Ranking delle vendite';
								|pl = 'Ranking sprzedaży';
								|tr = 'Satış sıralaması'"),"ImportedSalesRank");
	EndIf; 
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
		
		SearchColumns.Add(NStr("vi = 'Ngày giao hàng';
								|ru = 'Дата отгрузки';
								|en = 'Shipment date'; fa = 'تاریخ ارسال';
								|it = 'Data di spedizione';
								|pl = 'Data wysyłki';
								|tr = 'Sevkiyat tarihi'"),"DateOfShipment");
		SearchColumns.Add(NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'"),"Count");
		
	EndIf; 
	
	ExcelActionStructure.Insert("SearchColumns", SearchColumns);
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("IdProductCategory",0);
	TheStructureOfTheSearch.Insert("IDSalesRating",0);
	TheStructureOfTheSearch.Insert("WarehouseID_",0);
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
		ProcessingOfTabularForms.CopyRowsToClipboard(ProductCategoriesByPeriods, Items.ProductCategoriesByPeriods.SelectedRows);
	Else
		ProcessingOfTabularForms.CopyRowsToClipboard(Object.ProductCategories, Items.ProductCategories.SelectedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Columns = "Products,ProductCategory,SalesRank,Count,DateOfShipment,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ProcessClipboardGoodsTable(TableOfGoods);
	
	AddProductCategories(TableOfGoods);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ProductCategoriesInsertRows");
	ItemArray.Add("ProductCategoriesContextMenuInsertRows");
	ItemArray.Add("ProductCategoriesByPeriodsInsertRows");
	ItemArray.Add("ProductCategoriesByPeriodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ProductCategoriesInsertRows");
	ItemArray.Add("ProductCategoriesContextMenuInsertRows");
	ItemArray.Add("ProductCategoriesByPeriodsInsertRows");
	ItemArray.Add("ProductCategoriesByPeriodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
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
	InitializationParameters.Insert("AttributePath1", "Object.ProductCategories");
	InitializationParameters.Insert("TableFormElement_", "ProductCategories");
	InitializationParameters.Insert("PeriodTableFormElement", "ProductCategoriesByPeriods");
	
	Planning.InitializeAdditionalParameters(AdditionalParametersProductCategories, AdditionalParametersProductCategoriesByPeriods, InitializationParameters);
	
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
	
	If Object.CrossTable And Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure RoundOffQuantityCompletion(Result, AdditionalParameters) Export 

	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
	
		Return;
	EndIf;
	
	If Object.CrossTable And Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterQuestionSetArbitraryFormula(QuestionResult, AdditionalParameters) Export
	
	StructureOfData = New Structure("Formula,FormulaPresentation,Title,EnableValue,RowsArray,PeriodOfChange");
	
	If Object.CrossTable Then
		
		SelectedRows = Items.ProductCategoriesByPeriods.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = ProductCategoriesByPeriods.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				Operand.Value = ThisObject[Operand.Id];
			EndDo;
			
			StructureOfData.Formula 			= ThisObject.Formula;
			StructureOfData.FormulaPresentation= ThisObject.FormulaPresentation;
			StructureOfData.Title 			= "" + CurrentData.ProductCategory;
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
		
		SelectedRows = Items.ProductCategories.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = Object.ProductCategories.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				If CurrentData.Property(Operand.Id) Then
					Operand.Value = CurrentData[Operand.Id];
				EndIf;
			EndDo;
			
			StructureOfData.Formula 			= CurrentData.Formula;
			StructureOfData.FormulaPresentation= CurrentData.FormulaPresentation;
			StructureOfData.Title 			= "" + CurrentData.ProductCategory;
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
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("Advanced",		True);
	FormParameters.Insert("EnableValue",	StructureOfData.EnableValue);
	FormParameters.Insert("ValueHeader", String(StructureOfData.DetailsParameters.Filter.ProductCategory));
	FormParameters.Insert("OperationalPlanningExplanationParameters", StructureOfData.DetailsParameters);
	FormParameters.Insert("Formula",			?(StructureOfData.Formula = PlanningClientServer.TextForSettingNewFormula(),"", StructureOfData.Formula));
	FormParameters.Insert("Presentation",	?(StructureOfData.FormulaPresentation = PlanningClientServer.TextForSettingNewFormula(), "", StructureOfData.FormulaPresentation));
	FormParameters.Insert("UsesOperandTree", True);
	FormParameters.Insert("SelectPlanOperand", True);
	FormParameters.Insert("OperandsTree",	PlaceAdditionalFieldsInStorage());
	FormParameters.Insert("Operators",		OperatorsTreeStorageAddress);
	FormParameters.Insert("SavedSettingsObjectKey", "UserSettings_"
		 + PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories"));
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
		
		CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			Operand.Value = ThisObject[Operand.Id];
		EndDo;
		
		CurElementName = Items.ProductCategoriesByPeriods.CurrentItem.Name;
		ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
		
		If ActivePeriods.Count() > 1 Then
			
			If StrFind(CurElementName, "ProductCategoriesByPeriodsCount_") = 0
				And StrFind(CurElementName, "ProductCategoriesByPeriodPictureComment_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'")); 
				Return;
			Else
				For Each Period In ActivePeriods Do
					If CurElementName = "ProductCategoriesByPeriodsCount_" + Period.ColumnName 
						Or CurElementName = "ProductCategoriesByPeriodPictureComment_" + Period.ColumnName Then
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
		
		CurrentData = Items.ProductCategories.CurrentData;
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
					
					RowOfGoods = ProductCategoriesByPeriods.FindByID(LineID);
					
					If PeriodName = Period.ColumnName Then
						CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						RowOfGoods["Deviation_" + Period.ColumnName] = 0;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
						PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
					ElsIf ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) And RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
						CalculationResult = PlanningClient.CalculateByFormula(RowOfGoods["Formula_" + Period.ColumnName], RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
					EndIf;
					
				ElsIf PeriodName = "AllPeriods" Then
					
					RowOfGoods = ProductCategoriesByPeriods.FindByID(LineID);
					CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
					RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
					RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
					RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
					RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
					RowOfGoods["Deviation_" + Period.ColumnName] = 0;
					
					WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
					
					PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CalculateTotals_(ThisForm, False);
		
	Else
		
		For Each LineID In RowsArray Do
			
			RowOfGoods = Object.ProductCategories.FindByID(LineID);
			CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, Undefined, Undefined, Result.Presentation);
			RowOfGoods.Formula = Result.Formula;
			RowOfGoods.FormulaPresentation = CalculationResult.Presentation;
			RowOfGoods.FormulaCalculation = CalculationResult.Calculation;
			RowOfGoods.Count = CalculationResult.Result;
			RowOfGoods.Deviation = 0;
			
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
	
	If Form.AdditionalParametersProductCategoriesByPeriods = Undefined Then
		Return AddAttributes;
	EndIf;

	For Each Field In Form.AdditionalParametersProductCategoriesByPeriods Do
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
	
	If Form.AdditionalParametersProductCategoriesByPeriods = Undefined Then
		Return ArrayOfOperands;
	EndIf;

	For Each Field In Form.AdditionalParametersProductCategoriesByPeriods Do
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
	UseInternalConsumptionPlans	= GetFunctionalOption("UsePlanningOfInventoryConsumption")
		And Scenario.UseInPlanningOfInternalConsumption;

	If Scenario.UseCalculationBySalesSpeed Then
		StructureToInsert = "[SalesPlansByCategoriesBySalesSpeed] * 1.15";
		Id = StructureToInsert;
		Presentation = NStr("vi = 'Kế hoạch bán hàng +15%';
							|ru = 'План продаж +15%';
							|en = 'Sales forecast +15%'; fa = 'Sales forecast +15%';
							|it = 'Piano vendite +15%';
							|pl = 'Plan sprzedaży +15%';
							|tr = 'Satış planı+15%'");
		ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
		
		StructureToInsert = "Max([FactOfSalesByCategories], [SalesPlansByCategoriesBySalesSpeed])"
			+ ?(UseRemainderPlans, " - [PlanOfGoodsStock]",
				?(PlanningByAssignments, " - [ActualStartBalance]", " - [AvailableStock]"));
		Id = StructureToInsert;
		Presentation = NStr("vi = 'Kế hoạch bán hàng có tính đến điều chỉnh theo sự kiện bán hàng';
							|ru = 'План продаж с учетом корректировки по факту продаж';
							|en = 'Sales forecast considering adjustment according to actual sales'; fa = 'Sales forecast considering adjustment according to actual sales';
							|it = 'Piano vendite considerando la correzione secondo le vendite effettive';
							|pl = 'Plan sprzedaży z korektami na faktach sprzedaży';
							|tr = 'Satış bilgisine göre satış tahminine dair düzeltmeler'");
		ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	Else
		StructureToInsert = "[SalesPlansByCategories] * 1.15";
		Id = StructureToInsert;
		Presentation = NStr("vi = 'Kế hoạch bán hàng +15%';
							|ru = 'План продаж +15%';
							|en = 'Sales forecast +15%'; fa = 'Sales forecast +15%';
							|it = 'Piano vendite +15%';
							|pl = 'Plan sprzedaży +15%';
							|tr = 'Satış planı+15%'");
		ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
		
		StructureToInsert = "Max([FactOfSalesByCategories], [SalesPlansByCategories])"
			+ ?(UseRemainderPlans, " - [PlanOfGoodsStock]",
				?(PlanningByAssignments, " - [ActualStartBalance]", " - [AvailableStock]"));
		Id = StructureToInsert;
		Presentation = NStr("vi = 'Kế hoạch bán hàng có tính đến điều chỉnh theo sự kiện bán hàng';
							|ru = 'План продаж с учетом корректировки по факту продаж';
							|en = 'Sales forecast considering adjustment according to actual sales'; fa = 'Sales forecast considering adjustment according to actual sales';
							|it = 'Piano vendite considerando la correzione secondo le vendite effettive';
							|pl = 'Plan sprzedaży z korektami na faktach sprzedaży';
							|tr = 'Satış bilgisine göre satış tahminine dair düzeltmeler'");
		ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	EndIf; 
	
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
		
		ProductCategoriesByPeriods.Clear();
		Object.ProductCategories.Clear();
		CalculateNumberOfRows(ThisForm);
		
		Notification = New CallbackDescription("SetUpFormulaAndFillInCompletion", ThisObject, Settings);
		AddProductCategoriesBySelectionOnClient(Notification);
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
	
	If Object.CrossTable And Items.ProductCategoriesByPeriods.CurrentData = Undefined Then
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
	
	If Object.CrossTable And Items.ProductCategoriesByPeriods.CurrentData = Undefined Then
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
Procedure AddProductCategoriesBySelectionOnClient(NotificationOfAddition = Undefined)
	
	FormParameters = New Structure();
	FormParameters.Insert("Title",               NStr("vi = 'Chọn thể loại hàng hóa';
														|ru = 'Подбор товарных категорий';
														|en = 'Pick product categories'; fa = 'Pick product categories';
														|it = 'Selezione delle categorie merceologiche';
														|pl = 'Wybór kategorii towarów';
														|tr = 'Ürün kategorisi seçimi'"));
	FormParameters.Insert("UUID", UUID);
	If SettingsStructure.Property("SelectionOfProductsSettings") Then
		FormParameters.Insert("SelectionOfProductsSettings", SettingsStructure.SelectionOfProductsSettings);
	EndIf;
	
	AdditionalParameters = New Structure("NotificationOfAddition", NotificationOfAddition);
	Notification = New CallbackDescription("AddProductCategoriesByFilterCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"DataProcessor.SelectProductCategoriesByFilter.Form",
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure AddProductCategoriesByFilterCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, New Structure("AddressOfProductCategoriesInStorage", Result));
		
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
	
	ProductByFilter = Object.ProductCategories.Unload();
	
	Object.ProductCategories.Clear();
	
	For Each Period In ActivePeriods Do
	
		For Each RowOfProduct In ProductByFilter Do
		
			CurrentRow = Object.ProductCategories.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.DateOfShipment = Period.StartDate;
			CurrentRow.Formula = SettingsStructure.Formula;
			CurrentRow.FormulaPresentation = SettingsStructure.FormulaPresentation;
			CurrentRow.FormulaCalculation = SettingsStructure.Formula;
		
		EndDo; 
	
	EndDo; 
	
EndProcedure

&AtClient
Procedure SetDecryptionParameters(StructureOfData)
	
	If Object.CrossTable Then
		CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	Else
		CurrentData = Items.ProductCategories.CurrentData;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	FilterIndicators.Insert("ProductCategory", CurrentData.ProductCategory);
	If UseCalculationBySalesSpeed Then
		FilterIndicators.Insert("SalesRank", CurrentData.SalesRank);
	EndIf; 
	
	QueryOptions = New Structure();
	QueryOptions.Insert("Ref", 				Object.Ref);
	QueryOptions.Insert("Periodicity", 			Object.Periodicity);
	QueryOptions.Insert("PeriodOffset", 		AdditionalSettings(SettingsStructure).PeriodOffset);
	QueryOptions.Insert("Scenario", 				Object.Scenario);
	QueryOptions.Insert("FilterByProductSegmentIsUsed",False);
	QueryOptions.Insert("Fields", 					AdditionalParametersProductCategoriesByPeriods);
	QueryOptions.Insert("Filter", 					FilterIndicators);
	QueryOptions.Insert("UseCalculationBySalesSpeed", UseCalculationBySalesSpeed);
	
	SetRequestPeriod(QueryOptions);
	
	StructureOfData.Insert("DetailsParameters", QueryOptions);
	
EndProcedure

&AtClient
Procedure SetRequestPeriod(QueryOptions)

	If Object.CrossTable Then
		
		CurElementName = Items.ProductCategoriesByPeriods.CurrentItem.Name;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		For Each Period In TablePeriods.FindRows(New Structure("Active_", True)) Do
			If CurElementName = "ProductCategoriesByPeriodsCount_" + Period.ColumnName  Then
				QueryOptions.Insert("OffsetPeriodStart", 	Period.StartDate);
				QueryOptions.Insert("OffsetPeriodEnd", 	Period.EndDate);
			EndIf;
		EndDo;

	Else
		
		CurrentData = Items.ProductCategories.CurrentData;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		RowsArray = TablePeriods.FindRows(New Structure("StartDate, Active_", CurrentData.DateOfShipment, True));
		
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
		
		SettingsStructure.Insert("Formula","[SalesPlansByCategories] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch bán hàng của kỳ trước lên 15%';
															|ru = 'Увеличение планов продаж прошлых периодов на 15%';
															|en = 'Increase of sales forecasts of previous periods by 15%'; fa = 'Increase of sales forecasts of previous periods by 15%';
															|it = 'Aumento del 15% dei piani vendita nei periodi precedenti';
															|pl = 'Zwiększenie planów sprzedaży z poprzednich okresów o 15%';
															|tr = 'Önceki dönemlerin satış planlarının yüzde 15 artırılması'"));
		
		SettingsStructure.Insert("FilterEmptyLines", False);
		
	Else
		If SettingsStructure.Property("Offset") Then
		
			SettingsStructure.Insert("PeriodOffset", -1 * SettingsStructure.Offset);
			SettingsStructure.Delete("Offset");
		
		EndIf;
		
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
			
				SettingsStructure.Insert("Formula","[SalesPlansByCategories] * 1.15");
				SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch bán hàng của kỳ trước lên 15%';
																	|ru = 'Увеличение планов продаж прошлых периодов на 15%';
																	|en = 'Increase of sales forecasts of previous periods by 15%'; fa = 'Increase of sales forecasts of previous periods by 15%';
																	|it = 'Aumento del 15% dei piani vendita nei periodi precedenti';
																	|pl = 'Zwiększenie planów sprzedaży z poprzednich okresów o 15%';
																	|tr = 'Önceki dönemlerin satış planlarının yüzde 15 artırılması'"));
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
	
	For Each CurrentRow In DocumentObject.ProductCategories Do
		
		CollectionItem = Object.ProductCategories.Get(CurrentRow.LineNumber-1);
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

	For Each CurrentRow In DocumentObject.ProductCategories Do
		
		CollectionItem = Object.ProductCategories.Get(CurrentRow.LineNumber-1);
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

&AtClient
Procedure WhenChangingQuantityDeviation(RowOfGoods)
	
	For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
		
		If Not ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) Then
			Continue;
		EndIf;
		
		CalculationResult = PlanningClient.CalculateByFormula(RowOfGoods["Formula_" + Period.ColumnName], RowOfGoods, ThisForm.TimeIntervals, Period);
		
		If Items.ProductCategoriesByPeriods.CurrentItem.Name = "ProductCategoriesByPeriodsCount_" + Period.ColumnName Then
			RowOfGoods["Deviation_" + Period.ColumnName] = CalculationResult.Result - RowOfGoods["Count_" + Period.ColumnName];
		ElsIf RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
			RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
		EndIf;
		
	EndDo;
	
	PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
	
EndProcedure

&AtServer
Procedure UpdateOutputStructureOfAdditionalParameters()

	TableOutputParameters = New Structure("Fields", AdditionalParametersProductCategories);
	Planning.UpdateTableOutputStructure(ThisObject, TableOutputParameters);
	
	CrossTableOutputParameters = New Structure("Fields", AdditionalParametersProductCategoriesByPeriods);
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

&AtClientAtServerNoContext
Procedure WhenChangingAmountOfRowSum(Object, Form, RowOfGoods)

	Count = 0;
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Or RowOfGoods["Canceled_" + PeriodString_.ColumnName] Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.Count = Count;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form, CountLines = True)

	Object = Form.Object;
	
	If Not Object.CrossTable Then
	 
		Return;
	
	EndIf;
	
	ProductCategories = Form.ProductCategoriesByPeriods;
	
	Form["Count"] = 0;
	
	PrefixOfQuantityColumn = "ProductCategoriesByPeriods" + "Count_";
	
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = 0;
		
	EndDo;
	
	For Each TSRow In ProductCategories Do
		If CountLines Then
			TSRow.Count = 0;
		EndIf;
		
		For Each PeriodString_ In Form.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			
			TSRow["Substituted_"+ PeriodString_.ColumnName] = PeriodString_.Substituted;
			
			If TSRow["Canceled_" + PeriodString_.ColumnName] Then
				Continue;
			EndIf;
			
			If CountLines Then
				
				TSRow.Count = TSRow.Count + TSRow["Count_" + PeriodString_.ColumnName];
				
			EndIf;
			
			Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] + TSRow["Count_" + PeriodString_.ColumnName];
			
		EndDo;
		
		Form["Count"] = Form["Count"] + TSRow["Count"];
		
		PlanningClientServer.SetFormulaPresentation(Form, TSRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Object.FillInUsingFormula Then
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
	Else
		InitializeSettingsStructure(FormAttributeToValue("Object"));
	EndIf;
	
	ScriptParameters_ = ScriptParameters_(Object.Scenario);
	FillPropertyValues(ThisForm, ScriptParameters_);
	
	WhenChangingPeriodsOnServer();
	
	CopyToCrossTable(Undefined);
	
	SetCrossTableTag(ThisForm);
	
EndProcedure
 
&AtServer
Procedure FillInServiceDetailsInCollection()
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
	
		For Each TSRow In ProductCategoriesByPeriods Do
			For Each Period In ThisObject["TimeIntervals"] Do
				If Not Period.Active_ Then
					Continue;
				EndIf;
				TSRow["PictureComment_"+ Period.ColumnName] = ValueIsFilled(TSRow["Comment_"+ Period.ColumnName]);
			EndDo; 
		EndDo; 
		
	Else
		For Each TSRow In Object.ProductCategories Do
			TSRow.PictureComment = ValueIsFilled(TSRow.Comment);
		EndDo; 
	
	EndIf;
	
EndProcedure
 
// The procedure fills the period table with dates to get the order and forms the fields of the cross-table.
&AtServer
Procedure WhenChangingPeriodsOnServer(AdjustStartEndOfPeriod = False)
	
	If AdjustStartEndOfPeriod Then
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod, Object.PeriodEnding, CurrentSessionDate());
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
		
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "SalesPlanByCategories");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	TablePeriods See Planning.TablePeriods
// 	RecalculateTotals_ - Boolean - LongDesc
&AtServer
Procedure UpdateCrossTableStructure(TablePeriods, RecalculateTotals_ = True)
	
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	ThisIsOnePeriod = NumberOfPeriods = 1;
	
	Items.ProductCategoriesDateOfShipment.ChoiceList.Clear();
	For Each Period In TablePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf; 
		Items.ProductCategoriesDateOfShipment.ChoiceList.Add(BegOfDay(Period.StartDate), Period.Title);
	EndDo; 
	
	Items.ProductCategoriesByPeriodsCount.Visible = Not UseCalculationBySalesSpeed And Not ThisIsOnePeriod;
	
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
	OutputParameters.Insert("NameOfCrossTableProps", "ProductCategoriesByPeriods");
	OutputParameters.Insert("CrossTableFormElement", "ProductCategoriesByPeriods");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Object.Periodicity);
	
	OutputParameters.Insert("Fields", New Array());
	
	If Not ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf; 
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Count_");
	FieldStructure.Insert("DeleteTableDetails", False);
	If Not ThisIsOnePeriod Then
		FieldStructure.Insert("GroupPrefix", "GroupComment_");
	EndIf; 
	FieldStructure.Insert("CreateElement_", True);
	FieldStructure.Insert("ElementType", "Number");
	If ThisIsOnePeriod Then
		If UseCalculationBySalesSpeed Then
			FieldStructure.Insert("Title", NStr("vi = 'Tốc độ bán hàng';
												|ru = 'Скорость продажи';
												|en = 'Sale speed'; fa = 'Sale speed';
												|it = 'Velocità delle vendite';
												|pl = 'Szybkość sprzedaży';
												|tr = 'Satış hızı'"));
		Else
			FieldStructure.Insert("Title", NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Quantity';
												|tr = 'Miktar'"));
		EndIf;
	EndIf;
	FieldStructure.Insert("CreateSummaryDetails", True);
	FieldStructure.Insert("ItemWidth", 6);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("MarkNegatives", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_WhenChangingQuantity");
	FieldStructure.Insert("StructureOfActions", StructureOfActions);
	
	OutputParameters.Fields.Add(FieldStructure);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_OnChangeCanceled");
	Planning.AddCrossTableFieldCanceled(OutputParameters, ThisIsOnePeriod, StructureOfActions);
	
	StructureOfActions = New Structure;
	Planning.AddReplacedCrossTableField(OutputParameters, ThisIsOnePeriod And Object.Substitutional, StructureOfActions);
	
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
		
		Object.PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.SalesPlanByCategories, Object.Scenario);
		
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

	UpdateRule = UpdateRule Or Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile;
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, UpdateRule, FillingRuleAddress, CustomSettingsAddress);
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
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
		Object.FillInUsingFormula = PlanViewParameters.FillInUsingFormula;
		Object.Substitutional = PlanViewParameters.Substitutional;
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "SalesPlanByCategories");
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
	
	Items.Department.Visible = FillInBusinessUnit Or ValueIsFilled(Object.Department);
	Items.StoreFormat.Visible = FillInStoreFormat Or ValueIsFilled(Object.StoreFormat);
	
	Items.Warehouse.Visible = FillInWarehouse Or ValueIsFilled(Object.Warehouse);
	Items.ProductCategoriesWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.ProductCategoriesByPeriodsWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.ProductCategoriesFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	Items.ProductCategoriesByPeriodsFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	
	Items.ProductCategoriesFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	Items.ProductCategoriesByPeriodsFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	
	Items.ProductCategoriesFillInColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	Items.ProductCategoriesByPeriodFillInColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	
	Items.ProductCategoriesSalesRank.Visible = UseCalculationBySalesSpeed;
	Items.ProductCategoriesByPeriodsSalesRank.Visible = UseCalculationBySalesSpeed;
	If UseCalculationBySalesSpeed Then
		Items.ProductCategoriesCount.Title = NStr("vi = 'Tốc độ bán hàng';
													|ru = 'Скорость продажи';
													|en = 'Sale speed'; fa = 'Sale speed';
													|it = 'Velocità delle vendite';
													|pl = 'Szybkość sprzedaży';
													|tr = 'Satış hızı'");
		Items.ProductCategoriesByPeriodsCount.Visible = False;
		// Renaming command headers...
	Else
		Items.ProductCategoriesCount.Title = NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Quantità';
													|pl = 'Quantity';
													|tr = 'Miktar'");
	EndIf; 
	
	Items.ProductCategoriesConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	Items.ProductCategoriesByPeriodsConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	Items.ProductCategoriesFillIn.Visible = Not Object.FillInUsingFormula;
	Items.ProductCategoriesByPeriodFillIn.Visible = Not Object.FillInUsingFormula;
	Items.ProductCategoriesFillInCategories.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesByPeriodsFillInCategories.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesByPeriodsFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesGroupChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesByPeriodGroupChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.GoodsAdditionalParametersFormula.Visible = Object.FillInUsingFormula;
	Items.ProductsAdditionalParametersDeviation.Visible = Object.FillInUsingFormula;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("ProductCategoriesByPeriodDeviation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["ProductCategoriesByPeriodDeviation"].Visible = Object.FillInUsingFormula;
	EndIf;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("ProductCategoriesByPeriodFormulaCalculation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["ProductCategoriesByPeriodFormulaCalculation"].Visible = Object.FillInUsingFormula;
	EndIf;
	Items.GoodsAdditionalParameters.Visible = Object.FillInUsingFormula;
	Items.Details.Visible = Not Object.FillInUsingFormula;
	Items.ProductCategoriesByPeriodsContextMenuGroupByFormula.Visible = Object.FillInUsingFormula;
	Items.ProductCategoriesContextMenuGroupByFormula.Visible = Object.FillInUsingFormula;
	
	Items.Purpose.Visible = PlanningByAssignments And Not FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	Items.ProductCategoriesPurpose.Visible = PlanningByAssignments And FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	Items.ProductCategoriesByPeriodsPurpose.Visible = PlanningByAssignments And FillInAssignmentInTabularForm And UseOrderSupplyWithAssignment;
	
	Items.ProductCategoriesSubstituted.Visible = Object.Substitutional;
	
EndProcedure
 
&AtServerNoContext
Function GetPlanViewParameters(Val PlanProfile, Val UpdateRule, FillingRuleAddress, CustomSettingsAddress)
	
	Attributes = "NumberOfPeriods, FillInBusinessUnit, FillInWarehouse, FillInWarehouseInTabularForm, 
		|DisableEditingOfRule, FillInUsingFormula, FillInByServiceData, Substitutional, FillInStoreFormat,
		|FillInAssignmentInTabularForm, DisableEditingOfPopulationSettings";
	
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
	If UpdateRule Then
		FillingRuleAddress = Planning.GetAddressOfDefaultFillInRule(Enums.TypesOfPlans.SalesPlanByCategories, 
			PlanProfile, FillingRuleAddress);
		CustomSettingsAddress = Planning.GetAddressOfUserDefaultSettings(Enums.TypesOfPlans.SalesPlanByCategories, 
			PlanProfile, CustomSettingsAddress);
		SettingsStructure = Planning.GetDefaultSettings(Enums.TypesOfPlans.SalesPlanByCategories, PlanProfile);
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
		ProductCategories = Form.ProductCategoriesByPeriods;
	Else
		ProductCategories = Object.ProductCategories;
	EndIf;
	
	If Not Form.FillInBusinessUnit Then
		Object.Department = Undefined;
	EndIf; 
	
	If Not Form.FillInStoreFormat Then
		Object.StoreFormat = Undefined;
	EndIf;
	
	If Not Form.FillInWarehouse Then
		Object.Warehouse = Undefined;
	EndIf;
	
	If Not Form.PlanningByAssignments Then
		Object.Purpose = Undefined;
	EndIf;
	
	For Each TSRow In ProductCategories Do
		
		If Form.FillInWarehouse Then
			TSRow.Warehouse = Object.Warehouse;
		ElsIf Not Form.FillInWarehouseInTabularForm Then
			TSRow.Warehouse = Undefined;
		EndIf;
		
		If Not Form.PlanningByAssignments Then
			TSRow.Purpose = Undefined;
		ElsIf Not Form.FillInAssignmentInTabularForm Then
			TSRow.Purpose = Object.Purpose;
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
Procedure AddProductCategories(TableOfGoods, CachedValues = Undefined, LoadingFromFile = False)
	
	Modified = True;
	
	For Each RowOfProduct In TableOfGoods Do
		
		Object.FilledAutomatically = False;
		
		If Object.CrossTable And Not LoadingFromFile Then
			CurrentRow = ProductCategoriesByPeriods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		Else
			CurrentRow = Object.ProductCategories.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
		EndIf;
		
	EndDo;
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "ProductCategoriesByPeriods");
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtServer
Procedure ProcessClipboardGoodsTable(TableOfGoods)
	
	If TableOfGoods.Columns.Find("ProductCategory") = Undefined Then
		TableOfGoods.Columns.Add("ProductCategory", New TypeDescription("CatalogRef.ProductCategories"));
	EndIf;
	If TableOfGoods.Columns.Find("SalesRank") = Undefined Then
		TableOfGoods.Columns.Add("SalesRank", New TypeDescription("CatalogRef.SalesRanks"));
	EndIf;
	
	NewProductTable = TableOfGoods.CopyColumns();
	
	If TableOfGoods.Columns.Find("Products") = Undefined Then
		TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	EndIf;
	
	TMCommonUse.NumberValueTable(TableOfGoods, "LineNumber");
	
	Query = New Query;
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.Text =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CAST(Goods.Products AS Catalog.Products)                AS Products,
	|	CAST(Goods.ProductCategory AS Catalog.ProductCategories)      AS ProductCategory,
	|	CAST(Goods.SalesRank AS Catalog.SalesRanks) AS SalesRank
	|INTO Goods
	|FROM
	|	&TableOfGoods AS Goods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber       AS LineNumber,
	|	Goods.ProductCategory AS ProductCategory,
	|	Goods.SalesRank     AS SalesRank
	|FROM
	|	(SELECT
	|		Goods.LineNumber,
	|		CASE
	|			WHEN Goods.Products <> VALUE(Catalog.Products.EmptyRef)
	|				THEN Goods.Products.ProductCategory
	|			ELSE Goods.ProductCategory
	|		END AS ProductCategory,
	|		CASE
	|			WHEN Goods.Products <> VALUE(Catalog.Products.EmptyRef)
	|				THEN Goods.Products.SalesRank
	|			ELSE Goods.SalesRank
	|		END AS SalesRank
	|	FROM
	|		Goods AS Goods) AS Goods
	|WHERE
	|	Goods.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
	|	OR Goods.SalesRank <> VALUE(Catalog.SalesRanks.EmptyRef)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = NewProductTable.Add();
		FillPropertyValues(NewRow, TableOfGoods[Selection.LineNumber]);
		NewRow.ProductCategory = Selection.ProductCategory;
		NewRow.SalesRank = Selection.SalesRank;
	EndDo;
	
	TableOfGoods = NewProductTable;
	
EndProcedure

&AtServer
Procedure GetDownloadedProductCategoriesFromStorage(GoodsAddressInStorage, CachedValues = Undefined)
	
	ProductCategoriesFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	AddProductCategories(ProductCategoriesFromStorage, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateNumberOfRows(Form)

	If Form.Object.CrossTable Then
	
		Form.ProductCategoriesNumberOfLines = Form.ProductCategoriesByPeriods.Count();
	
	Else
	
		Form.ProductCategoriesNumberOfLines = Form.Object.ProductCategories.Count();
	
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function PlanViewParameters(Form)

	PlanViewParameters = New Structure("FillInBusinessUnit, FillInWarehouse, FillInStoreFormat, 
		|PlanningByAssignments, FillInAssignmentInTabularForm, FillInWarehouseInTabularForm");
	
	FillPropertyValues(PlanViewParameters, Form);
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Function FilterParameters(Form)

	FilterParameters = New Structure("Warehouse, Department, StoreFormat, Purpose");
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
			NStr("vi = 'Chưa điền trường ""Bộ phận""';
				|ru = 'Поле ""Подразделение"" не заполнено';
				|en = '""Business unit"" is required'; fa = '""Business unit"" is required';
				|it = 'Il campo ""Reparto"" non è compilato';
				|pl = 'Nie wypełniono pola ""Dział""';
				|tr = '""Departman"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.Department");
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
	
	If FillInStoreFormat And Not ValueIsFilled(Object.StoreFormat) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Khuôn dạng cửa hàng""';
				|ru = 'Поле ""Формат магазина"" не заполнено';
				|en = '""Store format"" is required'; fa = '""Store format"" is required';
				|it = 'Il campo ""Formato di negozio"" non è stato compilato';
				|pl = 'Nie wypełniono pola ""Формат магазина""';
				|tr = '""Mağaza Formatı"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.StoreFormat");
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
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("FillInNotificationDocument", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure FillInNotificationDocument(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		GetResultOfFillingOnServer(CachedValues);
		If Object.FillInUsingFormula
			And Object.CrossTable Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(
				ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
		EndIf;
		
		NotifyUserAboutFillingInData();
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
		For Each RowOfGoods In Form.ProductCategoriesByPeriods Do
			
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
				And RowOfGoods.Count = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
				
		EndDo;
		
		PreviousPeriod_ = Period;
		
	EndDo;
	
	If Form.SettingsStructure.ContentFillingVariant =	"Formula" 
		Or Form.SettingsStructure.FilterEmptyLines Then
		For Each RowToDelete In LinesToDelete Do
			Form.ProductCategoriesByPeriods.Delete(RowToDelete);
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
		"Documents.SalesPlanByCategories.FillInDocument",
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
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	JobParameters.Insert("StoreFormat",          Object.StoreFormat);
	
	JobParameters.Insert("FillInAssignmentInTabularForm", 
		Common.ObjectAttributeValue(Object.PlanProfile,"FillInAssignmentInTabularForm"));
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("UseCalculationBySalesSpeed", UseCalculationBySalesSpeed);
	
	JobParameters.Insert("FillInForReplacement",   True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.SalesPlanByCategories");
	JobParameters.Insert("NameOfResultColumn",    "Count");
	
	PopulatedTS = Object.ProductCategories.Unload();
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndFunction

&AtServer
Procedure PrepareParametersForFillingInDocumentUsingFormula(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	
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
	JobParameters.Insert("SalesDivision",    Object.Department);
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	
	JobParameters.Insert("UseCalculationBySalesSpeed", UseCalculationBySalesSpeed);
	
	JobParameters.Insert("FillInUsingFormula",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.SalesPlanByCategories");
	JobParameters.Insert("NameOfResultColumn",    "Count");
	
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, FilterParameters, PlanViewParameters);
	
	JobParameters.Insert("Filter",                   FilterIndicators);
	
	Array_SetNames = New Array();
	ArrayOfOperators = GetOperands(ThisObject);
	
	For Each Item In ArrayOfOperators Do
		Array_SetNames.Add(Item.Name);
	EndDo;
	JobParameters.Insert("Array_SetNames",       Array_SetNames);
	
	PopulatedTS = Object.ProductCategories.Unload();
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
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
	
EndProcedure 

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
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInRule",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.SalesPlanByCategories");
	
	PopulatedTS = Object.ProductCategories.Unload();
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
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure 

&AtServer
Function GetResultOfFillingOnServer(CachedValues)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.SalesPlanByCategories.Forms.DocumentForm.GetResultOfFillingOnServer");
	
	Table = GetFromTempStorage(StorageAddress);
	
	ProcessedRowsCount = Table.Count();
	
	Object.ProductCategories.Load(Table);
	
	// Formation of an array of periods in which the remainder plans were introduced
	PlannedBalanceIsUsed = Table.Columns.Find("PlannedStartBalance") <> Undefined;
	PlannedBalancesWithSelectionAreUsed = Table.Columns.Find("PlannedStartBalanceWithSelection") <> Undefined;
	If PlannedBalanceIsUsed Then
		
		BalancePlansPeriods.Clear();
		BalancePlanPeriodsWithSelection.Clear();
		
		For Each String In Table Do
			If String.PlannedStartBalance<>0 Then
				If BalancePlansPeriods.FindByValue(String.DateOfShipment) = Undefined Then
					BalancePlansPeriods.Add(String.DateOfShipment);
				EndIf;
			EndIf;
			
			If PlannedBalancesWithSelectionAreUsed
				And String.PlannedStartBalanceWithSelection<>0 Then
				If BalancePlanPeriodsWithSelection.FindByValue(String.DateOfShipment) = Undefined Then
					BalancePlanPeriodsWithSelection.Add(String.DateOfShipment);
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
		ThisForm.GetAttributes("ProductCategoriesByPeriods").Count()/10,
		"UpdateCrossTableStructure");
	
	CopyToCrossTable(CachedValues);
	
	Object.FilledAutomatically = True;
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
		ProductCategories = ProductCategoriesByPeriods;
	Else
		ProductCategories = Object.ProductCategories;
	EndIf;
	
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
		
		For Each RowOfGoods In ProductCategories Do
			If RowOfGoods.Count = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
		EndDo;

		For Each RowToDelete In LinesToDelete Do
			ProductCategories.Delete(RowToDelete);
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

#EndRegion

&AtServerNoContext
Function ScriptParameters_(Scenario)

	Attributes = "Periodicity, ShowNumberOfPeriod, UseCalculationBySalesSpeed, PlanningByAssignments";
	Attributes = Attributes + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, Attributes);
	
	Return ScriptParameters_;

EndFunction 

&AtServer
Procedure DeleteBlankLinesOnServer()
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	
	ItIsNecessaryToRecalculateResults = False;
	
	IndexOf =  ProductCategoriesByPeriods.Count() -1;
	
	While IndexOf >= 0 Do
	
		TSRow = ProductCategoriesByPeriods[IndexOf];
		
		If TSRow.Count <> 0 Then
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
		
			ProductCategoriesByPeriods.Delete(IndexOf);
			ItIsNecessaryToRecalculateResults = True;
		
		EndIf; 
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	If ItIsNecessaryToRecalculateResults Then
	
		CalculateTotals_(ThisForm, False);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductCategoriesByPeriodWhenActivatingCellOnClient()
	
	If Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, GetAdditionalBankingDetails(ThisObject), "ProductCategoriesByPeriods");
	EndIf;
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	
	If ActivePeriods.Count() = 1 Then
		If Not Object.FillInUsingFormula And CurrentData <> Undefined Then
			Details = PlanningClient.GenerateDecryption(CurrentData, "Details_" + ActivePeriods[0].ColumnName);
		EndIf;
		Return;
	EndIf;
	
	CellIsCanceled = False;
	CellComment = "";
	CellFound = False;
	
	Item = Items.ProductCategoriesByPeriods;
	
	CurrentData = Items.ProductCategoriesByPeriods.CurrentData;
	If CurrentData = Undefined Then
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf; 
	
	If Item.CurrentItem <> Undefined Then
		For Each Period In ActivePeriods Do
			If Item.CurrentItem.Name = "ProductCategoriesByPeriodsCount_"+Period.ColumnName Then
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
	
	ReplaceParameters.Insert("Department", Object.Department);
	ReplaceParameters.Insert("Warehouse", Object.Warehouse);
	ReplaceParameters.Insert("StoreFormat", Object.StoreFormat);
	ReplaceParameters.Insert("Purpose", Object.Purpose);
	
	Return ReplaceParameters
	
EndFunction

&AtServer
Procedure UpdateReplacementAttribute()

	For Each String In Object.ProductCategories Do
		String.Substituted = False;
	EndDo;
	
	If Not Object.Substitutional Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SubstitutedPeriods.SubstitutedPeriod
	|INTO SubstitutedPeriods
	|FROM
	|	&SubstitutedPeriods AS SubstitutedPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanByProductCategory.DateOfShipment,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, YEAR)
	|		ELSE SalesPlanByProductCategory.DateOfShipment
	|	END AS Period
	|INTO SalesPlanByProductCategory
	|FROM
	|	&SalesPlanByProductCategory AS SalesPlanByProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanByProductCategory.DateOfShipment
	|FROM
	|	SubstitutedPeriods AS SubstitutedPeriods
	|		INNER JOIN SalesPlanByProductCategory AS SalesPlanByProductCategory
	|		ON SubstitutedPeriods.SubstitutedPeriod = SalesPlanByProductCategory.Period";
	
	Query.SetParameter("SubstitutedPeriods", SubstitutedPeriods.Unload());
	
	Query.SetParameter("SalesPlanByProductCategory", Object.ProductCategories.Unload());
	Query.SetParameter("Periodicity", Object.Periodicity);
	
	RequestPackage = Query.ExecuteBatch(); 
	Selection = RequestPackage[2].Select();
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfShipment", Selection.DateOfShipment);
		ReplacementLines = Object.ProductCategories.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = True;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function FillInSubstitutedPeriods()
	
	ReplaceParameters = ReplaceParameters(Object);
	Result = Planning.GetSubstitutedPeriods(ReplaceParameters, "SalesPlanByCategories");
	
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

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "SalesPlanByCategories.ProductCategories";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ""Thể loại hàng hóa"" từ tệp';
												|ru = 'Загрузка таблицы ""Товарные категории"" из файла';
												|en = 'Import the Product categories table from the file'; fa = 'Import the Product categories table from the file';
												|it = 'Caricamento da file della tabella ""Categorie merceologiche""';
												|pl = 'Wczytywanie tabeli ""Kategorie towarowe"" z pliku';
												|tr = 'Dosyadan ""Ürün kategorileri"" tablosunun indirilmesi'");
	ImportParameters.AdditionalParameters = AdditionalParameters;
	
	ImportParameters.TemplateColumns = PlanningClient.DescriptionOfTemplateColumnsForLoadingProductCategories(AdditionalParameters);
	
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
	
	AddProductCategories(ImportedData, CachedValues, True);
	
	If Object.CrossTable Then
		
		ProductCategoriesByPeriods.Clear();
		
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "ProductCategories");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Thể loại hàng hóa';
																|ru = 'Товарные категории';
																|en = 'Product categories'; fa = 'دسته‌های محصول';
																|it = 'Categorie di merci';
																|pl = 'Kategorie towarowe';
																|tr = 'Ürün kategorileri'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
																|ru = 'Дата отгрузки';
																|en = 'Shipment date'; fa = 'تاریخ ارسال';
																|it = 'Data di spedizione';
																|pl = 'Data wysyłki';
																|tr = 'Sevkiyat tarihi'"));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		If Cancel Then
			Common.MessageToUser(NStr("vi = 'Trong các dòng danh sách ""Thể loại hàng hóa"" đã chỉ ra ngày ngoài biên lập kế hoạch - đã xóa các dòng.';
										|ru = 'В строках списка ""Товарные категории"" указаны даты за границами планирования - строки были удалены.';
										|en = 'Dates outside the planning fences are specified in lines of the Product categories list. The lines were removed.'; fa = 'Dates outside the planning fences are specified in lines of the Product categories list. The lines were removed.';
										|it = 'Nelle righe dell''elenco ""Categorie merceologiche"" le date vanno oltre i limiti della pianificazione - le righe sono state eliminate.';
										|pl = 'W wierszach listy ""Kategorie towarowe"" są podane daty poza granicami planowania - wiersze zostały usunięte.';
										|tr = '""Ürün kategorileri"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silindi.'"));
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
