
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

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
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Fill in the details of the form associated with the details of the object.
	If Not Object.AmountInManAccountingCurrency Then
		MethodOfSpecifyingTheCost = 0;
	ElsIf Not Object.AmountIncludesVAT Then
		MethodOfSpecifyingTheCost = 1;
	Else
		MethodOfSpecifyingTheCost = 2;
	EndIf;
	
	If Object.QuantityFromOM Then
		SourceOfQuantityData = 0;
	Else
		SourceOfQuantityData = 1;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.ReconcileOpeningBalancesByWarehouses);
	
	FillInServiceDetails("ExternalSystemData");
	FillInServiceDetails("ReconciliationResults");
	
	UpdateFormElements();
	UpdateTextGeneratedDocuments();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "ReconciliationResultsCCDNumber");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
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

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetails("ExternalSystemData");
	FillInServiceDetails("ReconciliationResults");
	
	FillInParametersForSpecifyingSeries();
	SetVisibilityOfSeriesElements();
	
	UpdateFormElements();
	UpdateTextGeneratedDocuments();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
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
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		CurrentData = Items.ExternalSystemData.RowData(ValueSelected.CurrentRowID);
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected, CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SourceOfQuantityDataOnChange(Item)
	
	If SourceOfQuantityData = 0 Then
		Object.QuantityFromOM = True;
	Else
		Object.QuantityFromOM = False;
	EndIf;
	
	Object.RefillResults = True;
	
EndProcedure

&AtClient
Procedure MethodOfSpecifyingTheCostOnChange(Item)
	
	If MethodOfSpecifyingTheCost = 0 Then
		
		Object.AmountInManAccountingCurrency  = False;
		Object.AmountIncludesVAT = False;
		
	ElsIf MethodOfSpecifyingTheCost = 1 Then
		
		Object.AmountInManAccountingCurrency  = True;
		Object.AmountIncludesVAT = False;
		
	Else // 2
		
		Object.AmountInManAccountingCurrency  = True;
		Object.AmountIncludesVAT = True;
		
	EndIf;
	
	Object.RefillResults = True;
	
	UpdateFormElements();
	
EndProcedure

&AtClient
Procedure SpecifyTargetsOnChange(Item)
	
	Object.RefillResults = True;
	
	UpdateFormElements();
	
EndProcedure

&AtClient
Procedure TextDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If StrFind(FormattedStringURL, "e1cib") <> 0 Then
		// The navigation link will be opened as standard.
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		
		Notification = New CallbackDescription(
			"URLProcessingCompletion",
			ThisObject,
			New Structure("Command", FormattedStringURL));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Cần lưu lại chứng từ để thực hiện giao dịch. Lưu chứng từ?';
				|ru = 'Необходимо сохранить документ для выполнения операции. Сохранить документ?';
				|en = 'Save the document to perform the operation. Save the document?'; fa = 'Save the document to perform the operation. Save the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Musisz zapisać dokument, aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemi tamamlamak için belgenin kaydedilmesi gerekir. Belgeyi kaydet?'"),
			QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReconcileOpeningBalancesByWarehouses.Form.DocumentForm.PerformNavigationLinkAction");
	// End StandardSubsystems.PerformanceMeasurement
	
	PerformNavigationLinkAction(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupGeneratedDocuments Then
		
		UpdateTextGeneratedDocuments();
		
		// StandardSubsystems.Properties
		If Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
			
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
			
		EndIf;
		// End StandardSubsystems.Properties
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExternalSystemData

&AtClient
Procedure ExternalSystemDataSelection(Item, RowSelected, Field, StandardProcessing)
	
	If (Field = Items["ExternalSystemDataSeries"]
	 Or Field = Items["ExternalSystemDataBatchesIndicationStatus"]) Then
		
		CurrentData = Items.ExternalSystemData.CurrentData;
		
		If CurrentData.BatchesIndicationStatus > 0
		 And CurrentData.BatchesIndicationStatus <= 11 Then
			StandardProcessing = False;
			OpenSelectionOfSeries(Field.EditText);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalSystemDataOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ExternalSystemData, ThisObject);
	UpdateCachedValuesToAccountForSeries(Item, CachedValues, Copy);
	
EndProcedure

&AtClient
Procedure ExternalSystemDataOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.ExternalSystemData.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
			Item, CachedValues, SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			SeriesSpecificationParameters,
			IDCurrentRow,
			CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters);
		
	EndIf;
	
	Object.RefillResults = True;
	
EndProcedure

&AtClient
Procedure ExternalSystemDataOnChange(Item)
	
	Object.RefillResults = True;
	
EndProcedure

&AtClient
Procedure ExternalSystemDataBeforeDeleteRow(Item, Cancel)
	
	UpdateCachedValuesToAccountForSeries(Item, CachedValues, False);
	
	Object.RefillResults = True;
	
EndProcedure

&AtClient
Procedure ExternalSystemDataProductsOnChange(Item)
	
	CurrentData = Items.ExternalSystemData.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(CurrentData, ThisObject, StructureOfActions, SeriesSpecificationParameters);
	AddSeriesActionsToStructure(StructureOfActions, Object.Warehouse, SeriesSpecificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ExternalSystemDataCharacteristicOnChange(Item)
	
	CurrentRow = Items.ExternalSystemData.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName", ThisObject.FormName));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ExternalSystemDataSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value						= Items.ExternalSystemData.CurrentData.Series;
	ValueSelected.CurrentRowID	= Items.ExternalSystemData.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure ExternalSystemDataSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText, Items.ExternalSystemData.CurrentData);
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsReconciliationResults

&AtClient
Procedure ReconciliationResultsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Field.ReadOnly Then
		Return;
	EndIf;
	
	CurrentData = Items.ReconciliationResults.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttributeName = Mid(Field.Name, StrLen("ReconciliationResults") + 1);
	AttributeValue = CurrentData[AttributeName];
	
	If TypeOf(AttributeValue) <> Type("Boolean")
	 And TypeOf(AttributeValue) <> Type("Date")
	 And TypeOf(AttributeValue) <> Type("Number")
	 And TypeOf(AttributeValue) <> Type("String")
	 And ValueIsFilled(AttributeValue) Then
		
		ShowValue(, AttributeValue);
		
	EndIf;
	
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


#Region ObjectCommands_

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

#EndRegion

&AtClient
Procedure CompareProducts(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReconcileOpeningBalancesByWarehouses.Form.DocumentForm.CompareProducts");
	// End StandardSubsystems.PerformanceMeasurement
	
	MatchProductsOnServer();
	
	Object.RefillResults = True;
	
EndProcedure

&AtClient
Procedure FillInResults(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReconcileOpeningBalancesByWarehouses.Form.DocumentForm.FillInResults");
	// End StandardSubsystems.PerformanceMeasurement
	
	FillInResultsOnServer();
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
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

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	
	If Not Object.ExternalSystemData.Count() = 0 Then
		
		QueryText = NStr("vi = 'Sẽ điền lại phần bảng. Tiếp tục?';
						|ru = 'Табличная часть будет перезаполнена. Продолжить?';
						|en = 'Table will be refilled. Continue?'; fa = 'Table will be refilled. Continue?';
						|it = 'La parte tabulare verrà precompilata. Continuare?';
						|pl = 'Część tabelaryczna zostanie uzupełniona ponownie. Kontynuować?';
						|tr = 'Tablo bölümü tekrar doldurulacak. Devam eti?'");
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisForm);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile();
	
EndProcedure

#EndRegion

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region FormEvents

&AtServer
Procedure OnReadCreateAtServer()
	
	// Fill in the details of the form associated with the details of the object.
	If Not Object.AmountInManAccountingCurrency Then
		MethodOfSpecifyingTheCost = 0;
	ElsIf Not Object.AmountIncludesVAT Then
		MethodOfSpecifyingTheCost = 1;
	Else
		MethodOfSpecifyingTheCost = 2;
	EndIf;
	
	If Object.QuantityFromOM Then
		SourceOfQuantityData = 0;
	Else
		SourceOfQuantityData = 1;
	EndIf;
	
	FillInServiceDetails("ExternalSystemData");
	FillInServiceDetails("ReconciliationResults");
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.ReconcileOpeningBalancesByWarehouses);
	
	FillInParametersForSpecifyingSeries();
	FillInStatusesForSpecifyingSeriesServer();
	SetVisibilityOfSeriesElements();
	
	UpdateFormElements();
	UpdateTextGeneratedDocuments();
	
EndProcedure

#EndRegion

#Region FormControl

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"ExternalSystemDataCharacteristic",
		"Object.ExternalSystemData.ItemVariantsAreUsed");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"ReconciliationResultsCharacteristic",
		"Object.ReconciliationResults.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"ExternalSystemDataSeries",
		"Object.ExternalSystemData.BatchesIndicationStatus",
		"Object.ExternalSystemData.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisObject,
		False,
		"ExternalSystemDataBatchesIndicationStatus",
		"Object.ExternalSystemData.BatchesIndicationStatus");
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "ExternalSystemDataProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ExternalSystemData.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber		= "ReconciliationResultsCCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD	= "Object.ReconciliationResults.TheRecordsAreKeptByCCD";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
		"ExternalSystemDataPurpose",
		"Object.ExternalSystemData.ItemsType");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
		"ReconciliationResultsPurpose",
		"Object.ReconciliationResults.ItemsType");
	
EndProcedure

&AtServer
Procedure UpdateFormElements()
	
	MetaDocument = Metadata.Documents.ReconcileOpeningBalancesByWarehouses;
	
	If Object.QuantityFromOM Then
		Items.ReconciliationResultsNumberOfPackages.Title = NStr("vi = 'Số lượng ban đầu';
																|ru = 'Начальное количество';
																|en = 'Initial quantity'; fa = 'Initial quantity';
																|it = 'Quantità iniziale';
																|pl = 'Ilość początkowa';
																|tr = 'Başlangıç tutarı'");
		Items.ReconciliationResultsQuantityExternal.Title  = MetaDocument.TabularSections.ReconciliationResults.Attributes.QuantityExternal.Synonym;
	Else
		Items.ReconciliationResultsQuantityExternal.Title  = NStr("vi = 'Số lượng ban đầu';
																	|ru = 'Начальное количество';
																	|en = 'Initial quantity'; fa = 'Initial quantity';
																	|it = 'Quantità iniziale';
																	|pl = 'Ilość początkowa';
																	|tr = 'Başlangıç tutarı'");
		Items.ReconciliationResultsNumberOfPackages.Title = MetaDocument.TabularSections.ReconciliationResults.Attributes.NumberOfPackages.Synonym;
	EndIf;
	
	Items.ExternalSystemDataExternalCostMan.Visible  = Object.AmountInManAccountingCurrency;
	Items.ExternalSystemDataExternalCostLocal.Visible = Not Object.AmountInManAccountingCurrency;
	Items.ExternalSystemDataExternalCostTA.Visible   = Not Object.AmountInManAccountingCurrency;
	Items.ExternalSystemDataExternalCostPD.Visible   = Not Object.AmountInManAccountingCurrency;
	Items.ExternalSystemDataExternalCostTD.Visible   = Not Object.AmountInManAccountingCurrency;
	
	Items.ReconciliationResultsCostMan.Visible  = Object.AmountInManAccountingCurrency;
	Items.ReconciliationResultsLocalCost.Visible = Not Object.AmountInManAccountingCurrency;
	Items.ReconciliationResultsCostInTaxAccounting.Visible   = Not Object.AmountInManAccountingCurrency;
	Items.ReconciliationResultsCostPermanentDifference.Visible   = Not Object.AmountInManAccountingCurrency;
	Items.ReconciliationResultsCostTemporaryDifference.Visible   = Not Object.AmountInManAccountingCurrency;
	
	Items.ExternalSystemDataExternalAssignment.Visible = Object.SpecifyTargets;
	Items.ExternalSystemDataPurpose.Visible 		 = Object.SpecifyTargets;
	Items.ReconciliationResultsPurpose.Visible 			 = Object.SpecifyTargets;
	
EndProcedure

#EndRegion

#Region ServiceDetailsOfTableParts

&AtServer
Procedure FillInServiceDetails(TSName)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert(
		"FillInMeasuredValueTypeAttribute",
		New Structure("Products", "MeasuredValueType"));
	
	If TSName = "ReconciliationResults" Then
		ParametersForFillingInBankingDetails.Insert(
			"FillInCCDTrackingAttribute",
			New Structure("Products", "TheRecordsAreKeptByCCD"));
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object[TSName], ParametersForFillingInBankingDetails);
	
	ProcessingOfTabularForms.InitializeRowCache(Items[TSName]);
	
EndProcedure

#EndRegion

#Region TextGenerationGeneratedDocuments

&AtServer
Procedure UpdateTextGeneratedDocuments()
	
	If Not Object.Posted Then
		TextDocuments = New FormattedString(NStr("vi = 'Để phản ánh kết quả đối chiếu trong kế toán, cần kết chuyển chứng từ đối chiếu.';
												|ru = 'Для отражения результатов сверки в учете документ сверки должен быть проведен.';
												|en = 'To record reconciliation results in accounting, the reconciliation document must be posted.'; fa = 'To record reconciliation results in accounting, the reconciliation document must be posted.';
												|it = 'Per rilevare i risultati della riconciliazione nella contabilità, il documento di riconcillazione deve essere registrato.';
												|pl = 'Aby odzwierciedlić wyniki uzgodnienia w dokumencie ewidencji, należy go zaksięgować.';
												|tr = 'Mutabakat sonuçlarının muhasebeye yansıtılabilmesi için mutabakat belgesinin kaydedilmesi gerekir.'"));
		Return;
	EndIf;
	
	RowsArray = New Array;
	
	If Object.RefillResults Then
		StructureDocuments = Undefined;
	Else
		StructureDocuments = CheckNeedToGenerateSubordinateDocuments();
	EndIf;
	
	If Object.RefillResults Then
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Cần cập nhật kết quả đối chiếu và tạo (cập nhật) chứng từ điều chỉnh số dư';
				|ru = 'Необходимо обновить результаты сверки и сформировать (обновить) документы корректировки остатков';
				|en = 'Update reconciliation results and generate (update) balance adjustment documents'; fa = 'Update reconciliation results and generate (update) balance adjustment documents';
				|it = 'È necessario aggiornare i risultati della riconciliazione e generare (aggiornare) i documenti per la correzione dei saldi';
				|pl = 'Konieczne jest zaktualizowanie wyników uzgodnienia i utworzenie (aktualizacja) dokumentów w celu korekty pozostałości';
				|tr = 'Mutabakat sonuçlarının güncellenmesi ve stok düzeltmesi belgelerinin oluşturulması (güncellenmesi) gereklidir.'"),
			"UpdateResultsAndGenerateDocuments");
		
	ElsIf Not StructureDocuments.EnteringCostBalances.DocumentRequired
	 And Not StructureDocuments.EnteringQuantityBalances.DocumentRequired
	 And Not StructureDocuments.PostRegistration.DocumentRequired
	 And Not StructureDocuments.WriteOffAfter.DocumentRequired Then
		
		AddTextInformationGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Không có dữ liệu để tạo chứng từ';
				|ru = 'Нет данных для формирования документов';
				|en = 'No data to generate documents'; fa = 'No data to generate documents';
				|it = 'Non ci sono dati della generazione dei documenti';
				|pl = 'Brak danych do generowania dokumentów';
				|tr = 'Belge oluşturmak için veri mevcut değil'"));
	
	// EnteringCostBalances
	ElsIf (StructureDocuments.EnteringCostBalances.DocumentRequired And StructureDocuments.EnteringCostBalances.DocumentsCount = 0)
	 Or (Not StructureDocuments.EnteringCostBalances.DocumentRequired And StructureDocuments.EnteringCostBalances.DocumentsCount > 0)
	 // EnteringQuantityBalances
	 Or (StructureDocuments.EnteringQuantityBalances.DocumentRequired And StructureDocuments.EnteringQuantityBalances.DocumentsCount = 0)
	 Or (Not StructureDocuments.EnteringQuantityBalances.DocumentRequired And StructureDocuments.EnteringQuantityBalances.DocumentsCount <> 0)
	 // PostRegistration
	 Or (StructureDocuments.PostRegistration.DocumentRequired And StructureDocuments.PostRegistration.DocumentsCount = 0)
	 Or (Not StructureDocuments.PostRegistration.DocumentRequired And StructureDocuments.PostRegistration.DocumentsCount <> 0)
	 // WriteOffAfter
	 Or (StructureDocuments.WriteOffAfter.DocumentRequired And StructureDocuments.WriteOffAfter.DocumentsCount = 0)
	 Or (Not StructureDocuments.WriteOffAfter.DocumentRequired And StructureDocuments.WriteOffAfter.DocumentsCount <> 0) Then
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Cần lập (cập nhật) chứng từ điều chỉnh số dư';
				|ru = 'Необходимо сформировать (обновить) документы корректировки остатков';
				|en = 'Generate (update) balance adjustment documents'; fa = 'Generate (update) balance adjustment documents';
				|it = 'È necessario generare (aggiornare) i documenti della correzione dei saldi';
				|pl = 'Konieczne jest wygenerowanie (aktualizacja) dokumentów korekcji pozostałości';
				|tr = 'Stok düzeltmesi belgelerinin oluşturulması (güncellenmesi) gereklidir'"),
			"PackageDocumentGeneration");
		
	Else
		
		AddTextHeaderGeneratedDocuments(RowsArray, NStr("vi = 'Chứng từ nhập số dư';
														|ru = 'Документ ввода остатков';
														|en = 'Balance entry document'; fa = 'Balance entry document';
														|it = 'Documento di inserimento dei saldi';
														|pl = 'Dokument wprowadzania pozostałości';
														|tr = 'Bakiye giriş belgesi'"));
		
		If Not StructureDocuments.EnteringCostBalances.DocumentRequired
		 And Not StructureDocuments.EnteringQuantityBalances.DocumentRequired Then
			
			AddTextInformationGeneratedDocuments(
				RowsArray,
				NStr("vi = 'Không bắt buộc';
					|ru = 'Не требуются';
					|en = 'Not required'; fa = 'لازم نیست';
					|it = 'Non è richiesto';
					|pl = 'Nie wymagane';
					|tr = 'Gerekli değil'"));
			
		Else
			
			AddSectionOfTextGeneratedDocuments(
				RowsArray,
				StructureDocuments,
				"EnteringCostBalances",
				NStr("vi = 'chứng từ nhập số dư theo giá vốn';
					|ru = 'документ ввода остатков по себестоимости';
					|en = 'balance entry document by cost'; fa = 'balance entry document by cost';
					|it = 'documento di inserimento dei saldi per costo di produzione';
					|pl = 'dokument wprowadzania pozostałości wg wartości własnej';
					|tr = 'maliye göre bakiye giriş belgesi'"),
				True);
			
			AddSectionOfTextGeneratedDocuments(
				RowsArray,
				StructureDocuments,
				"EnteringQuantityBalances",
				NStr("vi = 'chứng từ điều chỉnh số dư theo số lượng';
					|ru = 'документ корректировки остатков по количеству';
					|en = 'balance adjustment document by quantity'; fa = 'balance adjustment document by quantity';
					|it = 'documento di correzione dei saldi per quantità';
					|pl = 'dokument korekcji pozostałości wg ilości';
					|tr = 'miktara göre stok düzeltmesi belgesi'"));
			
		EndIf;
		
		AddTextHeaderGeneratedDocuments(RowsArray, NStr("vi = 'Chứng từ ghi tăng hàng thừa';
														|ru = 'Документы оприходования излишков товаров';
														|en = 'Stock surplus recognition documents'; fa = 'Stock surplus recognition documents';
														|it = 'I documenti di registrazione della merce in eccesso';
														|pl = 'Dokumenty zużycia pozostałości towarów';
														|tr = 'Stok fazlası tahakkuku belgeleri'"));
		
	 	If Not StructureDocuments.PostRegistration.DocumentRequired Then
			
			AddTextInformationGeneratedDocuments(
				RowsArray,
				NStr("vi = 'Không bắt buộc';
					|ru = 'Не требуются';
					|en = 'Not required'; fa = 'لازم نیست';
					|it = 'Non è richiesto';
					|pl = 'Nie wymagane';
					|tr = 'Gerekli değil'"));
			
	 	Else
			
			AddSectionOfTextGeneratedDocuments(
				RowsArray,
				StructureDocuments,
				"PostRegistration",
				NStr("vi = 'chứng từ ghi tăng';
					|ru = 'документ оприходования';
					|en = 'recording document'; fa = 'recording document';
					|it = 'documento di registrazione nella contabilità';
					|pl = 'dokument zużycia';
					|tr = 'tahakkuk belgesi'"));
			
	 	EndIf;
		
		AddTextHeaderGeneratedDocuments(RowsArray, NStr("vi = 'Chứng từ ghi giảm hàng thiếu';
														|ru = 'Документы списания недостач товаров';
														|en = 'Inventory shortage write-off documents'; fa = 'Inventory shortage write-off documents';
														|it = 'I documenti di storno degli ammanchi delle merci';
														|pl = 'Dokumenty zużycia niedoborów towarów';
														|tr = 'Stok eksiği tahakkuku belgeleri'"));
		
	 	If Not StructureDocuments.WriteOffAfter.DocumentRequired Then
			
			AddTextInformationGeneratedDocuments(
				RowsArray,
				NStr("vi = 'Không bắt buộc';
					|ru = 'Не требуются';
					|en = 'Not required'; fa = 'لازم نیست';
					|it = 'Non è richiesto';
					|pl = 'Nie wymagane';
					|tr = 'Gerekli değil'"));
			
	 	Else
			
			AddSectionOfTextGeneratedDocuments(
				RowsArray,
				StructureDocuments,
				"WriteOffAfter",
				NStr("vi = 'chứng từ ghi giảm';
					|ru = 'документ списания';
					|en = 'disposal document'; fa = 'disposal document';
					|it = 'documento di storno';
					|pl = 'dokument zużycia';
					|tr = 'gider yazma belgesi'"));
			
		EndIf;
		
		// General actions on documents.
		RowsArray.Add(Chars.LF);
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Cập nhật danh sách các chứng từ đã tạo';
				|ru = 'Обновить список сформированных документов';
				|en = 'Update the list of generated documents'; fa = 'Update the list of generated documents';
				|it = 'Aggiornare l''elenco dei documenti generati';
				|pl = 'Zaktualizuj listę wygenerowanych dokumentów';
				|tr = 'Oluşturulan belgelerin listesini güncelle'"),
			"UpdateInformation2");
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Điền lại tất cả các chứng từ đã tạo';
				|ru = 'Перезаполнить все сформированные документы';
				|en = 'Refill all generated documents'; fa = 'Refill all generated documents';
				|it = 'Precompilare tutti i docuemnti generati';
				|pl = 'Uzupełnij  ponownie wszystkie wygenerowane dokumenty';
				|tr = 'Oluşturulan tüm belgeleri yeniden doldur'"),
			"PackageDocumentGeneration");
			
	EndIf;
	
	TextDocuments = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Function CheckNeedToGenerateSubordinateDocuments()
	
	StructureDocuments = New Structure;
	StructureDocuments.Insert("EnteringCostBalances", DescriptionOfSubordinateDocument());
	StructureDocuments.Insert("EnteringQuantityBalances",    DescriptionOfSubordinateDocument());
	StructureDocuments.Insert("PostRegistration", 		 DescriptionOfSubordinateDocument());
	StructureDocuments.Insert("WriteOffAfter", 	  		 DescriptionOfSubordinateDocument());
	
	// Fill in the "Required Document" property.
	StructureDocuments.EnteringCostBalances.DocumentRequired = (Object.ReconciliationResults.Count() > 0);
	
	For Each CurrRow In Object.ReconciliationResults Do
		
		If CurrRow.DeviationInStorageUnits <> 0 Then
			StructureDocuments.EnteringQuantityBalances.DocumentRequired = True;
		EndIf;
		
		If Object.QuantityFromOM Then
			
			If CurrRow.DeviationInStorageUnits > 0 Then
				StructureDocuments.PostRegistration.DocumentRequired = True;
			ElsIf CurrRow.DeviationInStorageUnits < 0 Then
				StructureDocuments.WriteOffAfter.DocumentRequired = True;
			EndIf;
			
		EndIf;
			
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	""EnteringCostBalances"" AS DocumentType,
	|	T.Ref AS Ref
	|FROM
	|	Document.OBEntryGoods AS T
	|WHERE
	|	T.Basis = &Ref
	|	AND T.Posted
	|	AND NOT T.RecordInOperationalAccounting
	|	AND T.PostInCostAccounting
	|	AND BEGINOFPERIOD(T.Date, MONTH) = &PeriodBefore
	|
	|UNION ALL
	|
	|SELECT
	|	""EnteringQuantityBalances"",
	|	T.Ref
	|FROM
	|	Document.OBEntryGoods AS T
	|WHERE
	|	T.Basis = &Ref
	|	AND T.Posted
	|	AND T.RecordInOperationalAccounting
	|	AND NOT T.PostInCostAccounting
	|	AND BEGINOFPERIOD(T.Date, MONTH) = &PeriodBefore
	|
	|UNION ALL
	|
	|SELECT
	|	""PostRegistration"",
	|	T.Ref
	|FROM
	|	Document.InventorySurplusRecognition AS T
	|WHERE
	|	T.Basis = &Ref
	|	AND T.Posted
	|	AND BEGINOFPERIOD(T.Date, MONTH) = &PeriodAfter
	|
	|UNION ALL
	|
	|SELECT
	|	""WriteOffAfter"",
	|	T.Ref
	|FROM
	|	Document.WriteOffOfGoodsShortages AS T
	|WHERE
	|	T.Basis = &Ref
	|	AND T.Posted
	|	AND BEGINOFPERIOD(T.Date, MONTH) = &PeriodAfter
	|
	|ORDER BY
	|	DocumentType,
	|	Ref";
	
	Query.SetParameter("Ref", 	 Object.Ref);
	Query.SetParameter("PeriodBefore", 	 BegOfMonth(Object.Date));
	Query.SetParameter("PeriodAfter", EndOfMonth(Object.Date) + 1);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		DocumentsArray = StructureDocuments[Selection.DocumentType].DocumentsArray; // Array
		DocumentsArray.Add(Selection.Ref);
		StructureDocuments[Selection.DocumentType].DocumentsCount = StructureDocuments[Selection.DocumentType].DocumentsCount + 1;
	EndDo;
	
	Return StructureDocuments;
	
EndFunction

&AtServer
Function DescriptionOfSubordinateDocument()
	
	LongDesc = New Structure;
	LongDesc.Insert("DocumentRequired", False);
	LongDesc.Insert("DocumentsArray", New Array);
	LongDesc.Insert("DocumentsCount", 0);
	
	Return LongDesc;
	
EndFunction


&AtServer
Procedure AddSectionOfTextGeneratedDocuments(RowsArray, StructureDocuments, DocumentType, DocumentTitle, NoNeedToAddText = False)
	
	If Not StructureDocuments[DocumentType].DocumentRequired Then
		
		If NoNeedToAddText Then
			NoNeedToAddTextGeneratedDocuments(RowsArray, DocumentTitle);
		EndIf;
		
	ElsIf StructureDocuments[DocumentType].DocumentsCount = 0 Then
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Tạo mới';
				|ru = 'Создать';
				|en = 'Create'; fa = 'ایجاد';
				|it = 'Creare';
				|pl = 'Create';
				|tr = 'Oluştur'") + " " + DocumentTitle,
			"Create" + DocumentType);
		
	ElsIf StructureDocuments[DocumentType].DocumentsCount = 1 Then
		
		AddDocumentHyperlinkToGeneratedDocuments(
			RowsArray,
			StructureDocuments[DocumentType].DocumentsArray[0]);
		
	Else
		
		AddTextToGeneratedDocuments(
			RowsArray,
			NStr("vi = 'Lỗi: đã tìm thấy nhiều chứng từ trực thuộc';
				|ru = 'Ошибка: найдено несколько подчиненных документов';
				|en = 'Error: several subordinate documents are found'; fa = 'Error: several subordinate documents are found';
				|it = 'Errore: rilevati alcuni documenti subordinati';
				|pl = 'Błąd: znaleziono wiele dokumentów podrzędnych';
				|tr = 'Hata: birden çok alt belge bulundu'")
				+ " (" + TrimAll(StructureDocuments[DocumentType].DocumentsCount) + ")");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddTextHeaderGeneratedDocuments(RowsArray, Var_Title)
	
	If RowsArray.Count() > 0 Then
		RowsArray.Add(Chars.LF);
	EndIf;
	
	RowsArray.Add(New FormattedString(Var_Title + ":", New Font(Items.TextDocuments.Font,,, True)));
	RowsArray.Add(Chars.LF);
	
EndProcedure

&AtServer
Procedure AddDocumentHyperlinkToGeneratedDocuments(RowsArray, Var_Title, Command = Undefined)
	
	If Command = Undefined Then
		Command = GetURL(Var_Title);
	EndIf;
	
	RowsArray.Add(New FormattedString(TrimAll(Var_Title),,,, Command));
	RowsArray.Add(Chars.LF);
	
EndProcedure

&AtServer
Procedure AddTextToGeneratedDocuments(RowsArray, Var_Title)
	
	RowsArray.Add(New FormattedString(TrimAll(Var_Title),, WebColors.Red));
	RowsArray.Add(Chars.LF);
	
EndProcedure

&AtServer
Procedure NoNeedToAddTextGeneratedDocuments(RowsArray, DocumentTitle)
	
	RowsArray.Add(New FormattedString(NStr("vi = 'Tạo chứng từ';
											|ru = 'Формировать';
											|en = 'Generate'; fa = 'ایجاد';
											|it = 'Generare';
											|pl = 'Generate';
											|tr = 'Oluştur'") + " " + DocumentTitle + " " + NStr("vi = 'không bắt buộc';
																								|ru = 'не требуется';
																								|en = 'not required'; fa = 'not required';
																								|it = 'non richiesta';
																								|pl = 'nie jest wymagane';
																								|tr = 'gerekli değil'")));
	RowsArray.Add(Chars.LF);
	
EndProcedure

&AtServer
Procedure AddTextInformationGeneratedDocuments(RowsArray, LabelText)
	
	RowsArray.Add(New FormattedString(LabelText));
	RowsArray.Add(Chars.LF);
	
EndProcedure

#EndRegion

#Region ProcessingHyperlinksToTextGeneratedDocuments

&AtClient
Procedure URLProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		If Write() Then
			
			// StandardSubsystems.PerformanceMeasurement
			PerformanceMonitorClient.TimeMeasurement(
				"Document.ReconcileOpeningBalancesByWarehouses.Form.DocumentForm.PerformNavigationLinkAction");
			// End StandardSubsystems.PerformanceMeasurement
			
			PerformNavigationLinkAction(AdditionalParameters.Command);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformNavigationLinkAction(Command)
	
	If Command = "UpdateInformation2" Then
		UpdateTextGeneratedDocuments();
		Return;
	EndIf;
	
	If Command = "UpdateResultsAndGenerateDocuments" Then
		
		FillInResultsOnServer();
		
		If Not Write() Then
			Return;
		EndIf;
		
	EndIf;
	
	UpdateAll = Command = "PackageDocumentGeneration" Or Command = "UpdateResultsAndGenerateDocuments";
	
	StructureDocuments = CheckNeedToGenerateSubordinateDocuments();
	
	OldSetting = SessionParameters.PostWithoutControlOfCompanyStockBalance;
	SessionParameters.PostWithoutControlOfCompanyStockBalance = True;
	
	If Command = "Create" + "EnteringCostBalances" Or UpdateAll Then
		CreateSubordinateDocument(StructureDocuments, "EnteringCostBalances", Documents.OBEntryGoods);
	EndIf;
	
	If Command = "Create" + "EnteringQuantityBalances" Or UpdateAll Then
		CreateSubordinateDocument(StructureDocuments, "EnteringQuantityBalances", Documents.OBEntryGoods);
	EndIf;
	
	If Command = "Create" + "PostRegistration" Or UpdateAll Then
		CreateSubordinateDocument(StructureDocuments, "PostRegistration", Documents.InventorySurplusRecognition);
	EndIf;
	
	If Command = "Create" + "WriteOffAfter" Or UpdateAll Then
		CreateSubordinateDocument(StructureDocuments, "WriteOffAfter", Documents.WriteOffOfGoodsShortages);
	EndIf;
	
	SessionParameters.PostWithoutControlOfCompanyStockBalance = OldSetting;
	
	UpdateTextGeneratedDocuments();
	
EndProcedure

&AtServer
Procedure CreateSubordinateDocument(StructureDocuments, DocumentType, ManagerOfDocument)
	
	DocumentReference = Undefined;
	
	If Not StructureDocuments[DocumentType].DocumentRequired And StructureDocuments[DocumentType].DocumentsCount > 0 Then
		
		For IndexOf = 0 To StructureDocuments[DocumentType].DocumentsCount - 1 Do
			DeleteSubordinateDocument(StructureDocuments[DocumentType].DocumentsArray[IndexOf]);
		EndDo;
		
		Return;
		
	ElsIf StructureDocuments[DocumentType].DocumentRequired Then
		
		For IndexOf = 1 To StructureDocuments[DocumentType].DocumentsCount - 1 Do
			DeleteSubordinateDocument(StructureDocuments[DocumentType].DocumentsArray[IndexOf]);
		EndDo;
		
		If StructureDocuments[DocumentType].DocumentsCount > 0 Then
			DocumentReference = StructureDocuments[DocumentType].DocumentsArray[0];
		EndIf;
		
	Else
		
		Return;
		
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("ReconciliationDocument", 		   Object.Ref);
	FillingData.Insert("NextPeriodDocument", StrEndsWith(DocumentType, "After"));
	FillingData.Insert("EnteringCostBalances", DocumentType = "EnteringCostBalances");
	
	If Not ValueIsFilled(DocumentReference) Then
		SubordinateDocument = ManagerOfDocument.CreateDocument();
	Else
		SubordinateDocument = DocumentReference.GetObject();
	EndIf;
	
	SubordinateDocument.DeletionMark = False;
	SubordinateDocument.Fill(FillingData);
	SubordinateDocument.Write(DocumentWriteMode.Posting);
	
EndProcedure

&AtServer
Procedure DeleteSubordinateDocument(DocumentReference)
	
	SubordinateDocument = DocumentReference.GetObject();
	SubordinateDocument.SetDeletionMark(True);
	
EndProcedure

#EndRegion

#Region ServerSideCommandHandlers

&AtServer
Procedure MatchProductsOnServer()
	
	DocObject = FormAttributeToValue("Object");
	Documents.ReconcileOpeningBalancesByWarehouses.CompareExternalSystemProducts(DocObject);
	
	ValueToFormAttribute(DocObject, "Object");
	
	FillInServiceDetails("ExternalSystemData");
	FillInServiceDetails("ReconciliationResults");
	
EndProcedure

&AtServer
Procedure FillInResultsOnServer()
	
	DocObject = FormAttributeToValue("Object");
	Documents.ReconcileOpeningBalancesByWarehouses.FillInResultsTable(DocObject);
	
	ValueToFormAttribute(DocObject, "Object");
	
	FillInServiceDetails("ExternalSystemData");
	FillInServiceDetails("ReconciliationResults");
	
	UpdateFormElements();
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall =
		ProductsClient.YouNeedServerCallToSpecifySeries(
			ThisObject,
			SeriesSpecificationParameters,
			Text,
			CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.ExternalSystemData.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters =
			New Structure(
				"SeriesSpecificationParameters,ParametersOfSeriesIndicationForm",
				SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		ProcessSeriesIndication_Server(
			AdditionalParameters.SeriesSpecificationParameters,
			AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object,
		SeriesSpecificationParameters,
		CurDataId,
		ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	StructureOfActions = Undefined;
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInParametersForSpecifyingSeries()
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReconcileOpeningBalancesByWarehouses));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.ExternalSystemDataSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.ExternalSystemDataBatchesIndicationStatus.Visible =
		SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure UpdateCachedValuesToAccountForSeries(Item, CachedValues, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(RowsOfProductsToProcess = Undefined,
											SeriesRowsToProcess = Undefined)
	
	ProductsServer.FillInStatusesForSpecifyingSeries(
		Object,
		SeriesSpecificationParameters,
		RowsOfProductsToProcess,
		SeriesRowsToProcess);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Val SeriesSpecificationParameters,
																			IDCurrentRow,
																			CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object,
		SeriesSpecificationParameters,
		IDCurrentRow,
		CachedValues);
	
EndProcedure

#EndRegion

#Region StructureOfActions

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(CurrentRow, Form, StructureOfActions, SeriesSpecificationParameters)

	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("ProductsOnChangeOverridable",
		New Structure("FormName", Form.FormName));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute",
		New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", Form.Object.Warehouse, SeriesSpecificationParameters));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddSeriesActionsToStructure(StructureOfActions, Warehouse, SeriesSpecificationParameters)
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile()
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ReconcileOpeningBalancesByWarehouses.ExternalSystemData";
	ImportParameters.Title = NStr("vi = 'Kết nhập số dư đầu theo kho từ tệp';
									|ru = 'Загрузка начальных остатков по складу из файла';
									|en = 'Download initial balance by a warehouse from the file'; fa = 'Download initial balance by a warehouse from the file';
									|it = 'Il download dei saldi iniziali relativi al magazzino dal file';
									|pl = 'Wczytywanie początkowych stanów magazynowych z pliku';
									|tr = 'İlk stok bakiyelerini dosyadan yükleme'");
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	Object.ExternalSystemData.Load(ImportedData);
	
	FillInStatusesForSpecifyingSeriesServer();
	
	Object.RefillResults = True;
	
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
