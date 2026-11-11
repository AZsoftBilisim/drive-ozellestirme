#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		// The foundation document with the receipt order warehouse must have the status "Accepted".
		ArrayOfFoundationDocuments = BasisDocuments.Unload(, "DocumentBasis").UnloadColumn("DocumentBasis");
		
		If ArrayOfFoundationDocuments.Count() > 0 Then
			DocumentBasis = ArrayOfFoundationDocuments[0];
			FoundationDocumentIsAllowed = FoundationDocumentIsAvailableForEnteringAct(DocumentBasis);
			If Not FoundationDocumentIsAllowed Then
				ExceptionText = NStr("vi = 'Để tạo chứng từ ""Biên bản chênh lệch sau khi điều chuyển"", cần kết chuyển chứng từ ""Điều chuyển hàng hóa nội bộ""
					|với trạng thái ""Đã tiếp nhận"", bởi vì trong kho nhận có tiến hành kế toán theo sê-ri.';
					|ru = 'Для создания документа ""Акт о расхождениях после перемещения"", документ ""Перемещение товаров"" 
					|должен быть проведен в статусе ""Принято"", поскольку на складе-получателе ведется учет по сериям.';
					|en = 'To create document ""Stock transfer discrepancy report"", document ""Goods transfer""
					|should be posted in status ""Received"" as accounting by batch is kept in the destination warehouse.'; fa = 'To create document ""Stock transfer discrepancy report"", document ""Goods transfer""
					|should be posted in status ""Received"" as accounting by batch is kept in the destination warehouse.';
					|it = 'Per creare il documento ""Atto sulle discrepanze dopo il trasferimento"", il documento ""Trasferimento delle merci"" 
					| deve essere registrato nello stato ""Accettato"", poiché la contabilità nel magazzino-destinatario è tenuta per serie.';
					|pl = 'W celu utworzenia dokumentu ""protokół o odchyleniu po przemieszczeniu"", dokument ""Przemieszczenie towarów"" 
					|powinien być zatwierdzony w statusie ""Przyjęty"", ponieważ w magazynie odbiorczym jest prowadzona ewidencja według serii.';
					|tr = '""Transfer sonrası tutarsızlıklar raporu"" belgesini oluşturmak için, ""Mal transferi"" 
					|belgesinin ""Alındı"" durumunda gerçekleştirilmesi gerekir, çünkü hedef ambar kayıtlarını partilere göre tutar.'");
				Raise ExceptionText;
				Return;
			EndIf;
		EndIf;
		
		Object.Author = Users.CurrentUser();
		
	EndIf;
	
	GetRecipientSWarehouseOrder();
	
	SetVisibilityAvailability();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	ClearMarkIncomplete();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Document.InventoryTransfer.Form.ChoiceForm" Then
		
		ProcessSelectionOfDocuments(ValueSelected, "Variant1");
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.DiscrepancyReportFollowingTransfer.Form.BaseDocumentChoiceForm" Then
		
		ProcessSelectionOfDocuments(ValueSelected, ChoiceSource.TransferOption);

	EndIf;

	ClearMarkIncomplete();

	If Window <> Undefined Then
		Window.Activate();
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyAboutDocument(WriteParameters);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	
	StructureOfActions = DiscrepanciesClientServer.StructureOfActionsFillInDependentDetailsOfGoods();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInBasedOnOrdersAttribute();
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	
EndProcedure

&AtClient
Procedure SourceWarehouseOnChange(Item)
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure DestinationWarehouseOnChange(Item)
	DestinationWarehouseOnChangeServer();
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure DocumentsBasisSubmissionClick(Item, StandardProcessing)

	StandardProcessing = False;
	If BasisDocuments.Count() = 1 Then
		ShowValue(, BasisDocuments[0].DocumentBasis);
	ElsIf BasisDocuments.Count() > 1 Then
		
		DocumentsList = New ValueList;
		For Each TableRow In BasisDocuments Do
			DocumentsList.Add(TableRow.DocumentBasis);
		EndDo;
		
		TitleOfViewForm = NStr("vi = 'Điều chuyển hàng hóa (%DocumentsCount%)';
								|ru = 'Перемещения товаров (%DocumentsCount%)';
								|en = 'Transfer of goods (%DocumentsCount%)'; fa = 'Transfer of goods (%DocumentsCount%)';
								|it = 'Trasferimenti merce (%DocumentsCount%)';
								|pl = 'Przemieszczenia towarów (%DocumentsCount%)';
								|tr = 'Malların transferi (%DocumentsCount%)'");
		
		OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
		                DocumentsList,
		                TitleOfViewForm),
		ThisForm);
	EndIf;

EndProcedure

&AtClient
Procedure DocumentsToBeProcessed(Item)
	
	DiscrepanciesClient.IssueDocumentsClick(ThisObject);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)

	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If Items.GroupPages.CurrentPage = Items.MainGroup3 Then
		
		FormWayToReflectDiscrepancy();
		DiscrepanciesClientServer.AvailabilityControl(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);

EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	If ValueIsFilled(Object.Manager) Then
		Object.Department = ManagerSDivision(Object.Manager);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	RecalculateFormRowAndMetrics(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	RecalculateFormRowAndMetrics(CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsManagerSCommentBasementOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.ThereIsAManagerComment = Not IsBlankString(CurrentData.ManagerComment);
	
EndProcedure

&AtClient
Procedure ProductsManagerSCommentBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	ManagerSCommentStartOfSelection();
	
EndProcedure

&AtClient
Procedure ProductsRecipientSCommentBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	RecipientSCommentStartOfSelection();
	
EndProcedure

&AtClient
Procedure ProductsRecipientSCommentBasementOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.ThereIsACommentFromRecipient = Not IsBlankString(CurrentData.RecipientComment);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("RecalculateDiscrepancies");

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.DocumentBasis) Then
		DiscrepanciesClientServer.FillInDocumentBaseInLine(CurrentRow, BasisDocuments);
	EndIf;
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
EndProcedure

&AtClient
Procedure GoodsDocumentBasisOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	DiscrepanciesClient.GoodsDocumentGroundsForChange(CurrentRow, ThisForm.BasisDocuments);
	
	StructureOfActions = New Structure;
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOrderDocumentOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOrderDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.FilledUsingBaseDocument Then
		Return;
	EndIf;

	Item.ChoiceList.Clear();
	If Not ValueIsFilled(CurrentData.DocumentBasis) Then
		Return;
	EndIf;

	FoundRows = BasisDocuments.FindRows(New Structure("DocumentBasis", CurrentData.DocumentBasis));
	If FoundRows.Count() > 0 Then
		Item.ChoiceList.LoadValues(
		FoundRows[0].BasisOrders.UnloadValues());
	EndIf;

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentRow = Items.Goods.CurrentData;
	DiscrepanciesClient.GoodsBeforeDeleteRow(CurrentRow, Cancel, False);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Copy And CurrentData.FilledUsingBaseDocument Then
		
		Cancel = True;
		
		NewRow = Object.Goods.Add();
		StringOfExcludedProperties = "FilledUsingBaseDocument, CountByDocument, NumberOfPackagesByDocument, RowCode, Purpose, AssignmentSender";
		FillPropertyValues(NewRow, CurrentData, , StringOfExcludedProperties);
		
		Items.Goods.CurrentRow = NewRow.GetID();
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Items.Goods, CachedValues, SeriesSpecificationParameters, True);
		
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Items.Goods,CachedValues,SeriesSpecificationParameters) Then
			
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
			
		EndIf;
		
		RecalculateFormRowAndMetrics(NewRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentRow = Items.Goods.CurrentRow;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item,CachedValues,SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(CurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;

	If Field = Items.GoodsOrderDocument Then
		
		If ValueIsFilled(CurrentRow.OrderDocument) And CurrentRow.FilledUsingBaseDocument Then
			ShowValue(Undefined, CurrentRow.OrderDocument);
		EndIf;
		
	ElsIf Field = Items.GoodsDocumentBasis Then
		
		If ValueIsFilled(CurrentRow.DocumentBasis) And CurrentRow.FilledUsingBaseDocument Then
			ShowValue(Undefined, CurrentRow.DocumentBasis);
		EndIf;
		
	ElsIf Field = Items.GoodsBatchesIndicationStatus
		Or Field = Items.GoodsSeries
		Or (Field = Items.GoodsNumberOfPackages
			And ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentRow.BatchesIndicationStatus, SeriesSpecificationParameters))
			And EditingRights_3 Then
		
		OpenSelectionOfSeries();
		
	ElsIf Field = Items.GoodsThereIsAManagerComment And EditingRights_3 Then
		
		ManagerSCommentStartOfSelection();
		
	ElsIf Field = Items.GoodsThereIsACommentFromRecipient And EditingRights_3 Then
		
		RecipientSCommentStartOfSelection();
		
	ElsIf Field = Items.GoodsAction And EditingRights_3 Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
				Items.Goods, CachedValues, SeriesSpecificationParameters);
		DiscrepanciesClient.ProductsActionStartSelection(
			Items.Goods.CurrentData,
			Object,
			ThisForm,
			"Move");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure RefillByReceipt(Command) 
	
	If Object.Ref.IsEmpty() Then
		
		QueryText = NStr("vi = 'Để điền nhận, trước tiên phải ghi lại chứng từ. Ghi lại chứng từ và tiếp tục?';
						|ru = 'Для заполнения по приемке необходимо предварительно записать документ. Выполнить запись документа и продолжить?';
						|en = 'To fill in by receipt, you should save the document first. Save the document and continue?'; fa = 'To fill in by receipt, you should save the document first. Save the document and continue?';
						|it = 'Prima di compilare per accettazione è necessario registrare il documento. Effettuare la registrazione del documento e continuare?';
						|pl = 'W celu wypełnienia według przyjęcia należy wstępnie zapisać dokument. Wykonać zapisywanie dokumentu i kontynuować?';
						|tr = 'Belgenin teslim alındığında doldurulabilmesi için önceden kaydedilmiş olması gerekir. Belge kaydı gerçekleştirilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("ResubmitUserSResponseUponReceipt", ThisObject), 
				QueryText, QuestionDialogMode.YesNo);

	Else
		FillInServerAcceptanceForm();
		
		ShowUserNotification(
		NStr("vi = 'Số lượng điền lại';
			|ru = 'Количество перезаполнено';
			|en = 'Refilled quantity'; fa = 'Refilled quantity';
			|it = 'La quantità è ricompilata';
			|pl = 'Ponowne wypełnienie ilości.';
			|tr = 'Miktar yeniden dolduruldu'"),
		,
		NStr("vi = 'Trong các dòng điền lại số lượng.';
			|ru = 'В строках перезаполнено количество.';
			|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
			|it = 'La quantità nelle righe è stata ricompilata.';
			|pl = 'W wierszach jest ponownie wypełnona ilość.';
			|tr = 'Satırlarda miktar yeniden dolduruldu.'"),
		PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResubmitUserSResponseUponReceipt(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		Write(New Structure("WriteMode", DocumentWriteMode.Write));
	EndIf;
	
	If Object.Posted Then
		FillInServerAcceptanceForm();
		
		ShowUserNotification(
		NStr("vi = 'Số lượng điền lại';
			|ru = 'Количество перезаполнено';
			|en = 'Refilled quantity'; fa = 'Refilled quantity';
			|it = 'La quantità è ricompilata';
			|pl = 'Ponowne wypełnienie ilości.';
			|tr = 'Miktar yeniden dolduruldu'"),
		,
		NStr("vi = 'Trong các dòng điền lại số lượng.';
			|ru = 'В строках перезаполнено количество.';
			|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
			|it = 'La quantità nelle righe è stata ricompilata.';
			|pl = 'W wierszach jest ponownie wypełnona ilość.';
			|tr = 'Satırlarda miktar yeniden dolduruldu.'"),
		PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	UpdateSenderDestination();
EndProcedure

&AtClient
Procedure GoodsPurposeClearing(Item, StandardProcessing)
	UpdateSenderDestination();
EndProcedure

&AtClient
Procedure GoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInByBasisExecute(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	Notification = New CallbackDescription("MoveInstructionsCompleteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure MoveInstructionsCompleteCompletion(Result, AdditionalParameters) Export 
	
	FillInByBasis();
	
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
	
	ProcessingOfTabularFormsClient.SplitRow(TableData,FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject));
	
EndProcedure

// Parameters:
//   NewRow - FormDataCollectionItem - A new row added as a result of splitting the rows.
//   AdditionalParameters - Undefined - Required parameter of the notification handler, not used.
&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		NewRow.CountByDocument         = 0;
		NewRow.NumberOfPackagesByDocument = 0;
		NewRow.NumberOfDiscrepancyPackaging = 0;
		NewRow.Action                      = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		NewRow.ThereIsAManagerComment      = False;
		NewRow.ThereIsACommentFromRecipient     = False;
		NewRow.RecipientComment         = "";
		NewRow.ManagerComment          = "";
		NewRow.FilledUsingBaseDocument          = False;
		NewRow.AssignmentSender = NewRow.Purpose;
		RecalculateFormRowAndMetrics(CurrentRow);
		RecalculateFormRowAndMetrics(NewRow);
		
	EndIf;

EndProcedure

&AtClient
Procedure OnlyDiscrepanciesExecute(Command)
	
	OnlyDiscrepancies = Not OnlyDiscrepancies;
	Items.GoodsOnlyDiscrepancies.Check = OnlyDiscrepancies;
	
	If OnlyDiscrepancies Then
		Items.Goods.RowFilter = New FixedStructure("ThereAreDiscrepancies", True);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeBaseDocuments(Command)

	FormParameters = DiscrepanciesClient.StructureOfParametersOfDocumentSelectionFormForMovements();

	FillPropertyValues(FormParameters, Object);

	ListOfFoundationDocuments = New ValueList;
	For Each TableRow In BasisDocuments Do
		ListOfFoundationDocuments.Add(TableRow.DocumentBasis);
	EndDo;
	
	FormParameters.BasisDocuments = ListOfFoundationDocuments;
	
	FormParameters.TabularSectionIsNotEmpty = Object.Goods.Count() > 0;

	OpenForm("Document.DiscrepancyReportFollowingTransfer.Form.BaseDocumentChoiceForm",
	             FormParameters,
	             ThisForm);

EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.Title = DiscrepanciesClient.DownloadHeaderTextFromExternalFiles();
	ImportParameters.AdditionalExplanationWhenUploading = DiscrepanciesClient.AdditionalExplanationTextWhenDownloadingFromExternalFiles();
	ImportParameters.AmountsRecalculate = False;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa trong %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'biên bản chênh lệch sau khi điều chuyển';
																			|ru = 'акт о расхождениях после перемещения';
																			|en = 'stock transfer discrepancy report'; fa = 'stock transfer discrepancy report';
																			|it = 'atto di discrepanze dopo il trasferimento';
																			|pl = 'Protokół o odchyleniu po przemieszczeniu';
																			|tr = 'stok transferi tutarsızlık raporu'"));
	EndIf;
	
	FormParameters = New Structure;

	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("Title",                                 HeaderParameter_);
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("Warehouse",                                     Object.SourceWarehouse);
	FormParameters.Insert("SeriesSpecificationParameters",                    SeriesSpecificationParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure ChangeAction(Command)
	
	DiscrepanciesClient.ChangeActionOfSelectedLines(
		Object,
		ThisForm,
		"Move");
	
EndProcedure

&AtClient
Procedure ChangeActionOfSelectedLinesCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return; // Nothing is selected
	EndIf;
	
	InstallResult = DiscrepanciesClient.SetActionOptionForSelectedLines(
		ThisObject,
		Result.ActionWithShortageDocument,
		Result.ActionWithSurplusDocument);
	
	If InstallResult.NeedServerCall Then
		NumberOfModifiedRowsMatching = InstallResult.NumberOfModifiedRowsMatching;
		SetActionOptionInLinesServer(Result, NumberOfModifiedRowsMatching);
		DiscrepanciesClient.NotifyAboutActionInstallation(NumberOfModifiedRowsMatching);
	EndIf;
	
	Modified = True;

EndProcedure

&AtServer
Procedure SetActionOptionInLinesServer(Result, NumberOfModifiedRowsMatching)
	
	DiscrepanciesServer.SetActionOptionInLines(
		ThisObject,
		NumberOfModifiedRowsMatching,
		Result.ActionWithShortageDocument,
		Result.ActionWithSurplusDocument);
	
EndProcedure

&AtClient
Procedure ActionChoiceCompletion(Result, AdditionalParameters) Export

	If ValueIsFilled(Result) Then
		Items.Goods.CurrentData.Action = Result.ActionWithDocument;
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Items.Goods,CachedValues,SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		EndIf;
		
		Modified = True;
	EndIf;

EndProcedure

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

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
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Package
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
	// Product Text Description Blank mark

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDescriptionText.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Product Text Description View only
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDescriptionText.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<điền vào cơ sở>';
													|ru = '<заполнено по основанию>';
													|en = '<filled in using base document>'; fa = '<filled in using base document>';
													|it = '<compilato in base alla causale>';
													|pl = '<wypełniono na podstawie>';
													|tr = '<temel belgeye göre doldur>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The use of the characteristics
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	// Product Action No discrepancies
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThereAreDiscrepancies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Commodity action The document is not agreed
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Product Action Presentation

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Lập chứng từ của hàng hóa giao lại';
													|ru = 'Оформление перепоставленного';
													|en = 'Create overdelivered'; fa = 'Create overdelivered';
													|it = 'Formalizzazione del consegnato in eccesso';
													|pl = 'Rejestracja ponownie dostawionego';
													|tr = 'Fazla tedarik düzenlemesi'"));

	// Customer order line code blank mark

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product line of the overorder visibility

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderDocument.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ThereIsBasisForOrders");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The goods are ordered in excess of the order

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<phần nhiều hơn của đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	
	// Product Order hyperlink

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderDocument.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// Product Documentation hyperlink

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DocumentBasis");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// Product Order availability

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderDocument.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DocumentBasis");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The goods are ordered not by orders

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderDocument.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DocumentBasis");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.BasisByOrders");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<điều chuyển không theo đơn hàng>';
													|ru = '<перемещение не по заказу>';
													|en = '<transfer is not against order>'; fa = '<transfer is not against order>';
													|it = '<trasferimento fuori ordine>';
													|pl = '<przemieszczenie nie według zamówienia>';
													|tr = '<sipariş dışı transfer>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// Implementation mark blank

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// Item series
	
	DiscrepanciesServer.SetConditionalAppearanceOfSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	
	// Unavailability of items in the products table by implementations
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBatchesIndicationStatus.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Discrepancy quantity

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfDiscrepancyPackaging.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfDiscrepancyPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Unavailability of foundation documents

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsBasisSubmission.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfBaseDocuments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// The product number of the customer's packages mark blank
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	EmptyBatch = Catalogs.ControlledLots.EmptyRef();
	NotEqual = DataCompositionComparisonType.NotEqual;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ControlledLotOfTheSender", EmptyBatch, NotEqual);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ControlledLotOfTheSender");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToControlQuality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ dành cho các lô hàng cần được mở khóa>';
													|ru = '<только для партий подлежащих разблокировке>';
													|en = '<only for lots to be unlocked>'; fa = '<only for lots to be unlocked>';
													|it = '<only for lots to be unlocked>';
													|pl = '<only for lots to be unlocked>';
													|tr = '<yalnızca kilidi kaldırılacak lotlar için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingTransfer));
	EditingRights_3  = AccessRight("Update", Object.Ref.Metadata());

	If Object.BusinessOperation.IsEmpty() Then
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.InventoryTransfer");
	EndIf;
	
	FillInFoundationDocuments();
	FillInProductsSelectionListForAllReasons();
	
	ThisForm.DocumentsBasisSubmission = DiscrepanciesServer.FormationOfInscriptionDocumentsBaseMovement(
		Items.DocumentsBasisSubmission,
		ThisForm.NumberOfBaseDocuments,
		Object.Goods.Count(),
		?(ThisForm.NumberOfBaseDocuments > 0, ThisForm.BasisDocuments[0].DocumentBasis, ""));
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	
	StructureOfActions = DiscrepanciesClientServer.StructureOfActionsFillInDependentDetailsOfGoods();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	FormWayToReflectDiscrepancy();
	
	SetVisibilityAvailability();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode", WriteParameters.WriteMode);
	
	NotificationParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	
	Notify("Write_DiscrepancyReportFollowingTransfer", NotificationParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
		
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData) Then
		
		If CurrentData = Undefined Then
			CurrentData = Items.Goods.CurrentData;
			CurDataId = CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		If CurrentData.FilledUsingBaseDocument
				And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(CurrentData.BatchesIndicationStatus,
					SeriesSpecificationParameters) Then
			ShowMessageBox(,NStr("vi = 'Sê-ri trong dòng từ chứng từ cơ sở không thể được chỉnh sửa, thêm một dòng mới.';
								|ru = 'Серия в строке из документа-основания не редактируется, добавьте новую строку.';
								|en = 'Batch cannot be edited in a line of the base document, add a new line.'; fa = 'Batch cannot be edited in a line of the base document, add a new line.';
								|it = 'Le serie nella riga del documento-causale non è modificabile, aggiungere una nuova riga.';
								|pl = 'Seria w wierszu z dokumentu podstawy nie jest edytowana, dodaj nowy wiersz.';
								|tr = 'Temel belgedeki satırdaki seri düzenlenemez, yeni bir satır ekleyin.'"));
			Return;
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;
		SeriesSelectionNotification = New CallbackDescription("OpenSelectionOfSeriesCompletion",
		                                                  ThisObject,
		                                                  New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
		            ParametersOfSeriesIndicationForm,
		            ThisForm,
		            ,
		            ,
		            , 
		            SeriesSelectionNotification,
	                FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	OpenSelectionOfSeriesCompletionServer(Result, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure OpenSelectionOfSeriesCompletionServer(Result, AdditionalParameters)

	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	
	DistributeNumberOfDeletedSeriesInDocumentToAddedOnes();
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

// Two lines of PM Products with the same item can correspond to one or more lines of PM Series.
// When you specify the series discrepancies, they are no longer shared by both rows, and they are uniquely linked to the row
// PM Products. The user manually moves the series between these rows in this way:
//  1. deletes the series linked to a single row (the number is cleared in these series).
//  2. specifies the same series in the next line (new series lines are entered).
// Thus, "moving series"is performed. It is important to remove the "document quantity" from the lines of action 1,
// and specify this quantity in the lines of action 2.
//
&AtServer
Procedure DistributeNumberOfDeletedSeriesInDocumentToAddedOnes()
	
	If Object.SetOfSeries.Count() = 0 Then
		Return;
	EndIf;
	
	SeriesTable = Object.SetOfSeries.Unload();
	SeriesTable.Columns.Add("DocumentQuantityToBeFilledIn", New TypeDescription("Number"));
	For Each String In SeriesTable Do
		String.DocumentQuantityToBeFilledIn = String.CountByDocument;
	EndDo;
	
	Query = New Query();
	Query.SetParameter("SeriesTable", SeriesTable);
	Query.Text = 
	"SELECT
	|	SeriesTable.LineNumber,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.AssignmentSender,
	|	SeriesTable.FilledUsingBaseDocument,
	|	SeriesTable.DocumentBasis,
	|	SeriesTable.Action,
	|	SeriesTable.CountByDocument
	|INTO TTSeriesTable
	|FROM
	|	&SeriesTable AS SeriesTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SeriesTable.LineNumber,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.AssignmentSender,
	|	SeriesTable.FilledUsingBaseDocument,
	|	SeriesTable.DocumentBasis,
	|	SeriesTable.Action,
	|	SeriesTable.CountByDocument - SeriesTable.Count AS DocumentQuantityToBeFilledIn
	|FROM
	|	TTSeriesTable AS SeriesTable
	|WHERE
	|	SeriesTable.CountByDocument > SeriesTable.Count";
	
	TableMovedSeries = Query.Execute().Unload();
	
	Var_Key = "DocumentBasis, Products, Characteristic, Series, Purpose, AssignmentSender";
	
	Condition = "NOT [CountByDocument]";
	InvoicesServer.AllocateQuantity(TableMovedSeries, SeriesTable, "DocumentQuantityToBeFilledIn", Var_Key, Condition, True);
	
	SeriesTable.Columns.CountByDocument.Name            = "Delete";
	SeriesTable.Columns.DocumentQuantityToBeFilledIn.Name = "CountByDocument";
	
	For Each String In TableMovedSeries Do
		If String.DocumentQuantityToBeFilledIn = 0 Then
			RowToReduce = SeriesTable.Find(String.LineNumber, "LineNumber");
			// The document quantity is reduced by the amount of excess calculated in the request
			// , with the exception of the unallocated part of this surplus.
			RowToReduce.CountByDocument = 
				RowToReduce.CountByDocument
				- (RowToReduce.CountByDocument - RowToReduce.Count + String.DocumentQuantityToBeFilledIn);
			If RowToReduce.Count = 0 
				And RowToReduce.CountByDocument = 0 Then
				SeriesTable.Delete(RowToReduce);
			EndIf;
		EndIf;
	EndDo;
	
	Object.SetOfSeries.Load(SeriesTable);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateDiscrepancies");
	DiscrepanciesServer.ProcessSeriesIndication_(ThisForm, ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

&AtClient
Procedure ManagerSCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject,
	                                          "ManagerComment",
	                                          "ThereIsAManagerComment",
	                                          "ProductsManagerSCommentBasement");

EndProcedure

&AtClient
Procedure RecipientSCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject,
	                                          "RecipientComment",
	                                          "ThereIsACommentFromRecipient",
	                                          "ProductsRecipientSCommentBasement");

EndProcedure

&AtClient
Procedure UpdateSenderDestination()
	
	LineProducts_ = Items.Goods.CurrentData;
	
	If LineProducts_.RowCode = 0 Then
		LineProducts_.AssignmentSender = LineProducts_.Purpose;
	EndIf;
	
	RecalculateFormRowAndMetrics(LineProducts_);
	
EndProcedure

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	ParametersOfSeriesIndicationForm = ProductsServer.ParametersOfSeriesIndicationForm(Object,
		SeriesSpecificationParameters, CurDataId, ThisForm);
	CurrentData = Object.Goods.FindByID(CurDataId);
	If CurrentData.FilledUsingBaseDocument Then
		ParametersOfSeriesIndicationForm.OnlyQuantityEditing = True;
	EndIf;
	
	Return ParametersOfSeriesIndicationForm;
	
EndFunction

&AtServer
Procedure FillSetVisibilityAndReFillAvailabilityByShipment()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingTransfer));
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
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

#EndRegion

#Region Other

&AtServer
Function FoundationDocumentIsAvailableForEnteringAct(DocumentBasis)
	
	StatusOfFoundationDocument = Common.ObjectAttributeValue(DocumentBasis, "Status");
	
	UsedSeriesInStock = WarehousesServer.UseOfSeriesInStock(Object.DestinationWarehouse, False);
	
	If UsedSeriesInStock.UseItemsBatch 
		And StatusOfFoundationDocument <> Enums.GoodsTransferStatuses.Accepted Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure RecalculateFormRowAndMetrics(CurrentRow)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateDiscrepancies");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	SetVisibilityAvailability();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	SetVisibility1();
	SetAvailability();
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure SetAvailability()

	InfluencingPropsAreAvailable = ThisForm.BasisDocuments.Count() = 0;
	
	SelectionOfDocumentsIsNotAvailable = (ValueIsFilled(Object.Organization)
	                                    And ValueIsFilled(Object.SourceWarehouse)
	                                    And ValueIsFilled(Object.DestinationWarehouse)
	                                    And ValueIsFilled(Object.BusinessOperation));
	
	ProductSelectionIsAvailable = SelectionOfDocumentsIsNotAvailable And (ThisForm.BasisDocuments.Count() > 0);
	
	Items.Organization.ReadOnly			= Not InfluencingPropsAreAvailable;
	Items.CompanyRecipient.ReadOnly	= Not InfluencingPropsAreAvailable;
	Items.SourceWarehouse.ReadOnly		= Not InfluencingPropsAreAvailable;
	Items.DestinationWarehouse.ReadOnly		= Not InfluencingPropsAreAvailable;
	Items.BusinessOperation.ReadOnly	= Not InfluencingPropsAreAvailable;
	
	Items.ChangeBaseDocuments.Enabled		= SelectionOfDocumentsIsNotAvailable;
	Items.GoodsFillInByBasis.Enabled	= ProductSelectionIsAvailable;
	Items.GoodsImportFromExternalFile.Enabled	= ProductSelectionIsAvailable;
	Items.GoodsOpenSelection.Enabled			= ProductSelectionIsAvailable;
	Items.GoodsAdd.Enabled					= ProductSelectionIsAvailable;
	Items.Goods.Enabled							= ProductSelectionIsAvailable;
	
	Items.GoodsChangeAction.Enabled = (Surpluses > 0 Or Shortages > 0);
	
EndProcedure

&AtServer
Procedure SetVisibility1()

	Items.CompanyRecipient.Visible = 
		?(Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices,
		True, False);

		Items.GoodsDocumentBasis.Visible = ThisForm.BasisDocuments.Count() > 1;

	// Visibility of series elements
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
	Items.GoodsRefillByReceipt.Visible = UseAdvancedWarehousingWarehouseRecipient;

EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	ThisIsTransferOfGoodsBetweenSeparateUnits = (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
	
	Items.Organization.Title =
		?(ThisIsTransferOfGoodsBetweenSeparateUnits, NStr("vi = 'Doanh nghiệp-người gửi';
															|ru = 'Организация-отправитель';
															|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
															|it = 'Azienda-mittente';
															|pl = 'Shipping company';
															|tr = 'Gönderici iş yeri'"),
		                                                       NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Company';
																	|tr = 'İş yeri'"));
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfDocuments(ArrayOfDocuments, FillingVariant)
	
	// Initial filling in of the Document base table from the resulting array of bases.
	FillInFoundationDocuments(ArrayOfDocuments);
	FillInProductsSelectionListForAllReasons();
	
	FillInByBasis(FillingVariant);
	
EndProcedure

&AtServer
Procedure FillInByBasis(FillingVariant = "Variant1")
	
	Query = New Query;
	
	Query.Text = Documents.DiscrepancyReportFollowingTransfer.RequestTextBasedOnMove();
	
	Query.SetParameter("Basis1", BasisDocuments.Unload().UnloadColumn("DocumentBasis"));
	QueryResult = Query.ExecuteBatch();
	
	If FillingVariant = "Variant1" Then
		If QueryResult[1].IsEmpty() Then
			Object.Goods.Clear();
			Object.SetOfSeries.Clear();
		Else
			Object.Goods.Load(QueryResult[1].Unload());
			Object.SetOfSeries.Load(QueryResult[2].Unload());
		EndIf;
	ElsIf FillingVariant = "Variant2" Then
		//To the sub-document from the foundation, we calculate the fact	
		TheStructureOfTheSearch = New Structure("Products,Characteristic,Package");
		DocumentGoods = Object.Goods;
		BaseGoodsTable = QueryResult[1].Unload();
		For Each RowOfTables In BaseGoodsTable Do
			FillPropertyValues(TheStructureOfTheSearch, RowOfTables);
			FoundDocumentLines = DocumentGoods.FindRows(TheStructureOfTheSearch);
			If FoundDocumentLines.Count() > 0 Then
				For Each RowTS In FoundDocumentLines Do
					RowTS.NumberOfPackagesByDocument = RowOfTables.NumberOfPackagesByDocument;
					RowTS.NumberOfPackages = RowTS.NumberOfPackagesByDocument + RowTS.NumberOfDiscrepancyPackaging;
					
					If ValueIsFilled(RowTS.Package) Then;
						PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(RowTS.Package, RowTS.Products); 
					Else
						PackingDetails = New Structure("ZoomRatio", 1);
					EndIf;					
					RowTS.Count = RowTS.NumberOfPackages * PackingDetails.ZoomRatio;
					RowTS.CountByDocument = RowTS.NumberOfPackagesByDocument * PackingDetails.ZoomRatio; 
					RowTS.DocumentBasis = RowOfTables.DocumentBasis;
				EndDo;
			Else
				NewRow = DocumentGoods.Add();
				FillPropertyValues(NewRow, RowOfTables);
			EndIf;
		EndDo;
		Object.SetOfSeries.Load(QueryResult[2].Unload());
	ElsIf FillingVariant = "Variant3" Then
		//To the sub-document from the base, we calculate the discrepancies	
		TheStructureOfTheSearch = New Structure("Products,Characteristic,Package");
		DocumentGoods = Object.Goods;
		BaseGoodsTable = QueryResult[1].Unload();
		For Each RowOfTables In BaseGoodsTable Do
			FillPropertyValues(TheStructureOfTheSearch, RowOfTables);
			FoundDocumentLines = DocumentGoods.FindRows(TheStructureOfTheSearch);
			If FoundDocumentLines.Count() > 0 Then
				For Each RowTS In FoundDocumentLines Do
					If ValueIsFilled(RowTS.Package) Then;
						PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(RowTS.Package, RowTS.Products); 
					Else
						PackingDetails = New Structure("ZoomRatio", 1);
					EndIf;					
					RowTS.NumberOfPackagesByDocument = RowOfTables.NumberOfPackagesByDocument;
					RowTS.CountByDocument = RowTS.NumberOfPackagesByDocument * PackingDetails.ZoomRatio;		
					RowTS.DocumentBasis = RowOfTables.DocumentBasis;
				EndDo;
			Else
				NewRow = DocumentGoods.Add();
				FillPropertyValues(NewRow, RowOfTables);
			EndIf;
		EndDo;		
		Object.SetOfSeries.Load(QueryResult[2].Unload());
	EndIf;

	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	
	FillInFoundationDocuments(); // Refilling of the already filled table of the document basis with orders based on the results of the current request
	FillInProductsSelectionListForAllReasons(); // Refilling based on the results of the current request
	
	ThisForm.DocumentsBasisSubmission = DiscrepanciesServer.FormationOfInscriptionDocumentsBaseMovement(
		Items.DocumentsBasisSubmission,
		ThisForm.NumberOfBaseDocuments,
		Object.Goods.Count(),
		?(ThisForm.NumberOfBaseDocuments > 0, ThisForm.BasisDocuments[0].DocumentBasis, ""));
	
	StructureOfActions = DiscrepanciesClientServer.StructureOfActionsFillInDependentDetailsOfGoods();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingTransfer));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.InventoryTransfer") Then
		Object.CompanyRecipient = PredefinedValue("Catalog.Companies.EmptyRef");
	EndIf;
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingTransfer));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure FillInFoundationDocuments(ArrayOfDocuments = Undefined)

	ThisForm.NumberOfBaseDocuments = 0;
	
	ThereIsBasisForOrders = False;
	
	ThisForm.BasisDocuments.Clear();
	
	If ArrayOfDocuments = Undefined Then
		ArrayOfDocuments = Object.Goods.Unload(,"DocumentBasis").UnloadColumn("DocumentBasis");
	EndIf;
	
	TableOfFoundationDocuments = DiscrepanciesServer.GenerateTableOfDocumentsForMoving(ArrayOfDocuments);
	ThisForm.BasisDocuments.Load(TableOfFoundationDocuments);

	ThisForm.NumberOfBaseDocuments = ThisForm.BasisDocuments.Count();
	
	FillInBasedOnOrdersAttribute();

EndProcedure

&AtServer
Procedure FillInBasedOnOrdersAttribute()
	
	For Each StringFoundationDocuments In ThisForm.BasisDocuments Do
		If StringFoundationDocuments.BasisOrders.Count() > 0 Then
			FoundRows = Object.Goods.FindRows(New Structure("DocumentBasis", StringFoundationDocuments.DocumentBasis));
			For Each FoundRow In FoundRows Do
				FoundRow.BasisByOrders = True;
				ThereIsBasisForOrders = True;
			EndDo
		EndIf;
	EndDo

EndProcedure

&AtServer
Procedure FillInProductsSelectionListForAllReasons()

	Items.GoodsDocumentBasis.ChoiceList.Clear();
	ArrayOfDocuments = ThisForm.BasisDocuments.Unload(, "DocumentBasis").UnloadColumn("DocumentBasis");
	Items.GoodsDocumentBasis.ChoiceList.LoadValues(ArrayOfDocuments);

EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)

	RowsToProcess = DiscrepanciesServer.GetUploadedProductsFromStorage(
		Object.Goods,
		BasisDocuments,
		GoodsAddressInStorage);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);

	FillInStatusesForSpecifyingSeriesServer();

EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)

	ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);

EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)

	TemporaryTableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = DiscrepanciesClientServer.StructureOfActionsWhenChangingNumberOfPackages();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TemporaryTableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		DiscrepanciesClientServer.FillInDocumentBaseInLine(CurrentRow, BasisDocuments);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisObject, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);

	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure FormWayToReflectDiscrepancy()
	
	DiscrepanciesServer.FormInscriptionToReflectDiscrepancies(ThisObject,
	                                                                 Object.Goods,
	                                                                 Items.DiscrepancyLabel,
	                                                                 Items.IssueDocuments,
	                                                                 TypeOf(Object.Ref));
	
EndProcedure

&AtServer
Procedure FillInServerAcceptanceForm()
	
	FactOfAcceptance = Documents.DiscrepancyReportFollowingTransfer.FillActual(
		Object,
		Object.DestinationWarehouse,
		AccumulationRegisters.GoodsToReceive,
		Undefined);
	
	Object.Goods.Load(FactOfAcceptance.ResultingTable);
	Object.SetOfSeries.Load(FactOfAcceptance.ResultingSeriesTable);
	
	// Updating the series indication statuses.
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters);
	
	FillParameters = Documents.DiscrepancyReportFollowingTransfer.DocumentFillingParameters();
	Documents.DiscrepancyReportFollowingTransfer.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);

	// Post-processing is individual for the document
	StructureOfResults = DiscrepanciesClientServer.CalculateFinalQuantitativeIndicatorsOfForm(Object.Goods);
	FillPropertyValues(ThisForm, StructureOfResults);
	CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies);
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
	FillInBasedOnOrdersAttribute();
	
EndProcedure

&AtServer
Procedure DestinationWarehouseOnChangeServer()
	
	GetRecipientSWarehouseOrder();
	SetVisibilityAvailability();
	If QualityControl.UpdateActionParameters(
			Documents.DiscrepancyReportFollowingTransfer, Object, CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetRecipientSWarehouseOrder()
	
	SetPrivilegedMode(True);
	
	UseAdvancedWarehousingWarehouseRecipient = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.DestinationWarehouse, Object.Date, False);
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTextDiscrepancies(TextDiscrepancyPresence, LinesWithDiscrepancies_)
	
	If LinesWithDiscrepancies_ = 0 Then
		
		TextDiscrepancyPresence = NStr("vi = 'Không có sự khác biệt';
										|ru = 'Нет расхождений';
										|en = 'No discrepancies'; fa = 'No discrepancies';
										|it = 'Nessuna discrepanza';
										|pl = 'Brak odchylenia';
										|tr = 'Tutarsızlık yok'");
		
	Else
		
		TemplateTextPresenceOfDiscrepancies = NStr("vi = 'Có sự chênh lệch theo %1 %2';
													|ru = 'Имеются расхождения по %1 %2';
													|en = 'There are discrepancies by %1 %2'; fa = 'There are discrepancies by %1 %2';
													|it = 'Ci sono discrepanze per %1 %2';
													|pl = 'Istnieje odchylenie dla %1 %2';
													|tr = '%2%1 ilişkin tutarsızlıklar var'");
		
		StringText_ = TMCommonUseClientServer.DeclensionOfWord(LinesWithDiscrepancies_, 
			NStr("vi = 'mục, mục, mục, d';
				|ru = 'позиции, позициям, позициям, ж';
				|en = 'item, items'; fa = 'item, items';
				|it = 'позиции, позициям, позициям, ж';
				|pl = 'item, items';
				|tr = 'pozisyon, pozisyonlar, pozisyonlar, j'"));
		
		TemplateTextPresenceOfDiscrepancies = StrTemplate(TemplateTextPresenceOfDiscrepancies, LinesWithDiscrepancies_, StringText_);
		
		TextDiscrepancyPresence = TemplateTextPresenceOfDiscrepancies;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ManagerSDivision(Manager)
	
	Return SettingsValueCached.UserDivision(Manager);
	
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
