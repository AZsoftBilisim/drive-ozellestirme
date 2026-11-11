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
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsAdd1", "Visible", False);
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();

	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AutoTitle = False;
		
		GenerateHeadersThatDependOnBaseType(True);
		
		Object.Author = Users.CurrentUser();
		
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		SalesServer.SetBlankContractMark(Items, "Contract", Not Handler.CustomerAgreementsAreApplicable());
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		SalesServer.SetBlankContractMark(Items, "Contract", True);
	ElsIf Not DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		SalesServer.SetBlankContractMark(Items, "Contract");
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		ConsignmentSales25 = True;
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
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

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 

	SetVisibilityOfCommandAndFillInVATRate();

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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.PrintDetails" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected,,"GoodsReceipt");
			Object.GoodsReceipt.Clear();
			CommonClientServer.SupplementTable(ValueSelected.GoodsReceipt, Object.GoodsReceipt);
		EndIf;
		
		Modified = True;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form"
		Or ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.BaseDocumentChoiceForm" Then
		
		SetVisibilityForReflection();
		ProcessSelectionOfDocuments(ValueSelected, ChoiceSource.TransferOption);
		
	EndIf;
	
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
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
	
	If EventName = "Write_TermsOfPurchaseFromVendors" 
		And Not (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
			Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
			Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)) Then
		
		DiscrepanciesClient.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
		
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ClearMessages();
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	DiscrepanciesServer.ManagingAutoHeaderAfterRecording(ThisObject);
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisForm);
	
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Object);
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	
	
	UnlockFormDataForEdit();
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_DiscrepancyReportFollowingShipment", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ClientOnChange(Item)
	
	ClientWhenChangingOnServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	ContactPersonOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
		
		AgreementSelectionParameters.Item                     = Item;
		AgreementSelectionParameters.Partner                     = Object.Partner;
		AgreementSelectionParameters.Document                    = Object.Terms;
		AgreementSelectionParameters.DocumentDate               = Object.Date;
		AgreementSelectionParameters.FormDataStructure        = Object;
		
		If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			AgreementSelectionParameters.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			AgreementSelectionParameters.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
			AgreementSelectionParameters.ConsignmentSales25 = True;
		EndIf;
		
		SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
		
	Else
		
		StructureOfAdditionalSelection = New Structure;
		
		If DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			StructureOfAdditionalSelection.Insert("BusinessOperation",
				PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
		EndIf;
		
		PurchasesClient.StartSelectingSupplierAgreement(Item, StandardProcessing, Object.Partner, Object.Terms,
			Object.Date, StructureOfAdditionalSelection);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled (Object.Terms) Then
		Return;
	EndIf;
	
	WhenChangingAgreementAtServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure DocumentsBasisSubmissionClick(Item, StandardProcessing)
	
	DiscrepanciesClient.DocumentsBasisSubmissionClick(ThisObject, Item, StandardProcessing);
	
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

&AtServer
Procedure FormWayToReflectDiscrepancy()

	DiscrepanciesServer.FormInscriptionToReflectDiscrepancies(ThisObject,
	                                                                 Object.Goods,
	                                                                 Items.DiscrepancyLabel,
	                                                                 Items.IssueDocuments,
	                                                                 TypeOf(Object.Ref));
	FormEvents.WhenChangingFormPages(ThisObject, "GroupPages");
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	DocumentCurrency = Object.Currency;
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure HowToReflectDiscrepanciesDocumentChangesOnChange(Item)
	
	If CleaningOfVHFActionIsRequired() Then
		AskQuestionAboutClearingActionColumn();
	Else
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodForReflectingDiscrepanciesCorrectionCorrectionOnChange(Item)
	
	If CleaningOfVHFActionIsRequired() Then
		AskQuestionAboutClearingActionColumn();
	Else
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfReflectingDiscrepanciesAdjustmentByAgreementOnChange(Item)
	
	If CleaningOfVHFActionIsRequired() Then
		AskQuestionAboutClearingActionColumn();
	Else
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodForReflectingDiscrepanciesAdjustmentNewOnChange(Item)
	
	DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	If ValueIsFilled(Object.Manager) Then
		Object.Department = ManagerSDivision(Object.Manager);
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInVATTaxationATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

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
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
			Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
		
	EndIf;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.SaleOfGoodsAndServices) Then
		SelfServiceClientServer.FillInDocumentBaseInLine(CurrentRow, BasisDocuments, True);
	EndIf;
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		
		If CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered") Then
			CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		EndIf;
		
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
			Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
		
	EndIf;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	DiscrepanciesClient.GoodsNumberOfPackagesOnChange(ThisForm, CachedValues);
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	DiscrepanciesClient.GoodsPackageOnChange(ThisForm, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	DiscrepanciesClient.GoodsPriceOnChange(ThisObject, Item, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	DiscrepanciesClient.GoodsSumOnChange(ThisObject, Item, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	DiscrepanciesClient.GoodsVATAmountOnChange(ThisObject, Item, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	DiscrepanciesClient.GoodsVATRateOnChange(ThisObject, Item, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderOnChange(Item)
	If Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider") Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If Not ValueIsFilled(CurrentData.SalesOrder) And ValueIsFilled(CurrentData.Purpose) Then
			
			CurrentData.Purpose            = Undefined;
			CurrentData.AssignmentSender = Undefined;
			
		ElsIf ValueIsFilled(CurrentData.SalesOrder) Then
			
			CurAssignment =
				GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentData.SalesOrder, "Purpose");
			
			CurrentData.Purpose            = CurAssignment;
			CurrentData.AssignmentSender = CurAssignment;
			
		EndIf;
		
	EndIf;
	Return; // The TMAR handler is empty
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	If Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
	 Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
		
		CurrentData = Items.Goods.CurrentData;
		
		CurrentData.AssignmentSender = CurrentData.Purpose;
		
	EndIf;
	Return; // The TMAR handler is empty
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then 
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
		
	EndIf;

	DiscrepanciesClient.GoodsBeforeAddRow(ThisObject, Item, Cancel, Copy, CachedValues);
	
	If Copy Then
		
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Item,CachedValues,SeriesSpecificationParameters) Then
		
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
		EndIf;
		
	EndIf
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);

	If NewRow And Not Copy Then
		CurrentRow.Department = Object.Department;
		If Not ValueIsFilled(CurrentRow.SaleOfGoodsAndServices) Then
			SelfServiceClientServer.FillInDocumentBaseInLine(CurrentRow, BasisDocuments, True);
		EndIf;
		If Not ValueIsFilled(CurrentRow.VATRate) Then
			CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item,CachedValues,SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	DiscrepanciesClient.GoodsBeforeDeleteRow(CurrentData, Cancel, True);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	DiscrepanciesClient.GoodsAfterDeleteRow(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FormEventsClient.WhenSelectingItem(ThisObject, Item, CurrentRow, Field, StandardProcessing);
	
	If StandardProcessing
		And EditingRights_3
		And CurrentRow.FilledInBySale
		And CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesByDocument
		And (Field <> Items.GoodsNumberOfPackages And Field <> Items.GoodsAction
		And Field <> Items.GoodsPassportNumber
		And Field <> Items.GoodsWarehouse) Then
		
		If Not (CurrentRow.ThereAreDiscrepancies And CurrentRow.Count <> 0)
			Or (Field <> Items.GoodsSum And Field <> Items.GoodsVATAmount) Then
			DiscrepanciesClient.ShowWarningForFilledBasedOnRows();
			Return;
		EndIf;
		
	EndIf;
	
	If Field = Items.GoodsPrice And EditingRights_3 Then
		
		If ValueIsFilled(CurrentRow.PriceKind) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PriceKind"),);
		EndIf;
	
	ElsIf Field = Items.GoodsAmountIncludingVAT And EditingRights_3 Then
		
		If ValueIsFilled(CurrentRow.PriceKind) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn số tiền gồm thuế GTGT, hãy xóa dạng giá';
					|ru = 'Для редактирования суммы с НДС очистите вид цены';
					|en = 'To edit the amount including VAT, clear the price type'; fa = 'To edit the amount including VAT, clear the price type';
					|it = 'Для редактирования суммы с НДС очистите вид цены';
					|pl = 'To edit the amount including VAT, clear the price type';
					|tr = 'KDV''li tutarın düzenlenmesi için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PriceKind"),);
		EndIf;

	ElsIf Field = Items.GoodsSalesOrder Then
		
		If ValueIsFilled(CurrentRow.SalesOrder) And CurrentRow.FilledInBySale Then
			ShowValue(Undefined, CurrentRow.SalesOrder);
		EndIf;
		
	ElsIf Field = Items.GoodsDocumentBasis Then
		
		If ValueIsFilled(CurrentRow.SaleOfGoodsAndServices) And CurrentRow.FilledInBySale Then
			ShowValue(Undefined, CurrentRow.SaleOfGoodsAndServices);
		EndIf;
		
	ElsIf Field = Items.GoodsBatchesIndicationStatus
		Or Field = Items.GoodsSeries
		Or (Field = Items.GoodsNumberOfPackages
			And ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentRow.BatchesIndicationStatus, SeriesSpecificationParameters))
			And EditingRights_3 Then
		
		OpenSelectionOfSeries();
		
	ElsIf Field = Items.GoodsThereIsAManagerComment And EditingRights_3 Then
		
		ManagerSCommentStartOfSelection();
		
	ElsIf Field = Items.GoodsThereIsACustomerComment And EditingRights_3 Then
		
		CustomerCommentStartOfSelection();
		
	ElsIf Field = Items.GoodsAction And EditingRights_3 Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
				Items.Goods, CachedValues, SeriesSpecificationParameters);
		DiscrepanciesClient.ProductsActionStartSelection(
			Items.Goods.CurrentData,
			Object,
			ThisObject,
			Object.TypeOfBaseDocumentForNonConformanceCertificate,
			ShowExplanation);
		
	ElsIf Field = Items.GoodsWarehouse
		And EditingRights_3
		And Not ValueIsFilled(CurrentRow.Warehouse)
		And CurrentRow.RowCode = 0
		And Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		OpenWarehouseSelectionForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	FormEventsClient.OnActivateRow(ThisObject, Item);
	
EndProcedure


&AtClient
Procedure ProductsImplementationWhenChanged(Item)
	
	Var FoundRow;
	
	SelfServiceClient.ProductsImplementationWhenChanged(ThisForm, FoundRow);
	CurrentRow = Items.Goods.CurrentData;
	
	DiscrepanciesClientServer.FillInMultiTurnContainerDetailsInLine(CurrentRow, FoundRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	If Not Item.CurrentItem.Name = "GoodsPassportNumber" Then
		Items.GoodsPassportNumber.ReadOnly = True;
	EndIf;
	
	If Item.CurrentItem.Name = "GoodsSalesOrder" Then
		
		If CurrentData.FilledInBySale Then
			Return;
		EndIf;
		
		Items.GoodsSalesOrder.ChoiceList.Clear();
		If Not ValueIsFilled(CurrentData.SaleOfGoodsAndServices) Then
			Return;
		EndIf;
		
		FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.SaleOfGoodsAndServices));
		If FoundRows.Count() > 0 Then
			Items.GoodsSalesOrder.ChoiceList.LoadValues(
			FoundRows[0].BasisOrders.UnloadValues());
		EndIf;
		
	ElsIf Item.CurrentItem.Name = "GoodsWarehouse" Then
		
		If CurrentData.FilledInBySale Then
			Return;
		EndIf;
		
		Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
		If Not ValueIsFilled(CurrentData.SaleOfGoodsAndServices) Then
			Return;
		EndIf;
		
		FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.SaleOfGoodsAndServices));
		If FoundRows.Count() > 0 Then
			Items.GoodsWarehouse.ChoiceList.LoadValues(FoundRows[0].BasisWarehouses.UnloadValues());
		EndIf;
		
	ElsIf Item.CurrentItem.Name = "GoodsSum" Then
		
		Items.GoodsSum.ReadOnly = Not CurrentData.ThereAreDiscrepancies;
		
	ElsIf Item.CurrentItem.Name = "GoodsVATAmount" Then
		
		Items.GoodsVATAmount.ReadOnly = Not CurrentData.ThereAreDiscrepancies;
		
	ElsIf Item.CurrentItem.Name = "GoodsPassportNumber" Then
		
		Items.GoodsPassportNumber.ReadOnly = False;
		
	EndIf;
	
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
Procedure ProductsCustomerCommentBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	CustomerCommentStartOfSelection();
	
EndProcedure

&AtClient
Procedure ProductsCustomerCommentBasementOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.ThereIsACustomerComment = Not IsBlankString(CurrentData.CustomerComment);
	
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
	Notification = New CallbackDescription("FillInBySalesExecuteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInBySalesExecuteCompletion(Result, AdditionalParameters) Export 
	
	FillInByBasis();
	
EndProcedure

&AtClient
Procedure PrintDetails(Command)
	
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.PrintDetails",
	             New Structure("DocumentObject", Object),
	             ThisForm);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure ChangeBaseDocuments(Command)
	
	DiscrepanciesClient.ChangeBaseDocuments(ThisObject);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.Title = DiscrepanciesClient.DownloadHeaderTextFromExternalFiles();
	ImportParameters.AdditionalExplanationWhenUploading = DiscrepanciesClient.AdditionalExplanationTextWhenDownloadingFromExternalFiles();
	ImportParameters.ImportPrices = True;
	ImportParameters.AmountsRecalculate = False;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer());
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale")
		Or Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5")
		Or Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
		Or Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5")
		Or Not DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
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
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.DiscrepancyReportFollowingShipment.DocumentForm.Command.OpenSelection");
	
	DiscrepanciesClient.OpenSelection(ThisObject, True);
	
EndProcedure

&AtClient
Procedure OnlyDiscrepanciesExecute(Command)
	
	DiscrepanciesClient.OnlyDiscrepanciesExecute(ThisObject);
	
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
	CurrentData = FormTable.CurrentData;
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Chọn dòng hàng hóa cần chia tách.';
							|ru = 'Выберите строку товаров, которую необходимо разбить.';
							|en = 'Select the goods line to split.'; fa = 'Select the goods line to split.';
							|it = 'Selezionare riga degli articoli da dividere.';
							|pl = 'Wybierz wiersz towarów, który należy podzielić.';
							|tr = 'Bölmek istediğiniz mal satırını seçin.'");
		ShowMessageBox(,MessageText);
	Else
		ListOfActions = New ValueList;
		ListOfActions.Add("ActualQuantity", NStr("vi = 'Chia nhỏ số lượng thực tế';
												|ru = 'С разбиением фактического количества';
												|en = 'By actual quantity'; fa = 'By actual quantity';
												|it = 'Con divisione della quantità effettiva';
												|pl = 'Z podziałem faktycznej ilości';
												|tr = 'Gerçek sayıların dökümü ile'"));
		ListOfActions.Add("CountByDocument", NStr("vi = 'Chia nhỏ số lượng theo chứng từ';
													|ru = 'С разбиением количества по документу';
													|en = 'By quantity in document'; fa = 'By quantity in document';
													|it = 'Con divisione della quantità per documento';
													|pl = 'Z podziałem ilości wg dokumentu';
													|tr = 'Belge bazında miktar dökümü ile'"));
		
		AfterSelectingPartitionOption = New CallbackDescription("AfterSelectingStringSplittingOption", ThisObject);
		ShowChooseFromMenu(AfterSelectingPartitionOption, ListOfActions, Items.GoodsSplitRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingStringSplittingOption(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	CurrentData = FormTable.CurrentData;
	
	Attributes = ?(DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate),
					"Count, Sum",
					"Count, Sum, VATAmount, AmountIncludingVAT");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
	Attributes,
	"NumberOfPackages");
	
	If CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	AdditionalParameters.Insert("TypeOfPartition", Result.Value);
	
	PartitioningParameters = Undefined;
	
	If Result.Value = "CountByDocument" Then
		PartitioningParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
		PartitioningParameters.FieldNameQuantity          = "NumberOfPackagesByDocument";
		PartitioningParameters.AllowZeroCount = False;
		PartitioningParameters.Count                 = CurrentData.NumberOfPackagesByDocument - 1;
	ElsIf Result.Value = "ActualQuantity" And CurrentData.NumberOfPackagesByDocument <> 0
		And ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentData.BatchesIndicationStatus, SeriesSpecificationParameters) Then
		Delta = CurrentData.NumberOfPackages - CurrentData.NumberOfPackagesByDocument;
		Delta = ?(Delta < 0, 0, Delta);
		If Delta = 0 Then 
			MessageText = NStr("vi = 'Có thể chia số lượng thực tế trong các dòng có dư thừa.';
								|ru = 'Фактическое количество можно разбивать в строках с излишками.';
								|en = 'You can split the actual quantity in lines with surpluses.'; fa = 'You can split the actual quantity in lines with surpluses.';
								|it = 'Фактическое количество можно разбивать в строках с излишками.';
								|pl = 'You can split the actual quantity in lines with surpluses.';
								|tr = 'Fiilî miktar fazlalık satırlarına ayrılabilir.'");
			ShowMessageBox(, MessageText);
			Return;
		EndIf;
		PartitioningParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
		PartitioningParameters.AllowZeroCount    = False;
		PartitioningParameters.Count                    = Delta;
		PartitioningParameters.MaximumAllowedValue = Delta;
	EndIf;
	
	ProcessingOfTabularFormsClient.SplitRow(TableData,
	                                             FormTable,
	                                             New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters),
	                                             PartitioningParameters);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);

	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If LineOfATabularSection.FilledInBySale Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		SelectedRows.Delete(SelectedRows.Find(LineToDelete));
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);

EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		If AdditionalParameters.TypeOfPartition = "ActualQuantity" Then
		
			NewRow.RowCode = 0;
			NewRow.CountByDocument         = 0;
			NewRow.NumberOfPackagesByDocument = 0;
			NewRow.NumberOfDiscrepancyPackaging = 0;
			NewRow.VATAmountByDocument           = 0;
			NewRow.PersonalIncomeTaxExpense           = 0;
			NewRow.SumByDocument              = 0;
			NewRow.DiscrepancyAmount              = 0;
			NewRow.AmountIncludingVATByDocument          = 0;
			NewRow.TheAmountOfTheSNDSRansmission          = 0;
			NewRow.ThereIsAManagerComment      = False;
			NewRow.ThereIsACustomerComment        = False;
			NewRow.CustomerComment            = "";
			NewRow.ManagerComment          = "";
			NewRow.FilledInBySale         = False;
			
			If Object.TypeOfBaseDocumentForNonConformanceCertificate <> PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor")
				And Not (DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate)
					And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal")) Then
				NewRow.Purpose                = PredefinedValue("Catalog.Assignments.EmptyRef");
			EndIf;
			NewRow.AssignmentSender     = PredefinedValue("Catalog.Assignments.EmptyRef");
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits");
			
			If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
				StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			EndIf;
			
			StructureOfActions.Insert("RecalculateAmountOfDiscrepancy");
			StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
			StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
			
			Action = CurrentRow.Action;
			CurrentRow.Action = NewRow.Action;
			
			BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
			
			DiscrepanciesClient.ProcessSeriesWhenSplittingGoodsLine(ThisObject, CurrentRow , NewRow);
			
			CurrentRow.Action = Action;
			
			If CurrentRow.CountByDocument = CurrentRow.Count + NewRow.Count Then
			
				If CurrentRow.VATAmountByDocument <> (CurrentRow.VATAmount + NewRow.VATAmount) Then
					NewRow.VATAmount = NewRow.VATAmount + (CurrentRow.VATAmountByDocument - (CurrentRow.VATAmount + NewRow.VATAmount));
				EndIf;
				
				If CurrentRow.SumByDocument <> (CurrentRow.Sum + NewRow.Sum) Then
					NewRow.Sum = NewRow.Sum + (CurrentRow.SumByDocument - (CurrentRow.Sum + NewRow.Sum));
				EndIf;
				
				If CurrentRow.AmountIncludingVATByDocument <> (CurrentRow.AmountIncludingVAT + NewRow.AmountIncludingVAT) Then
					NewRow.AmountIncludingVAT = NewRow.AmountIncludingVAT + (CurrentRow.AmountIncludingVATByDocument - (CurrentRow.AmountIncludingVAT + NewRow.AmountIncludingVAT));
				EndIf;
				
			EndIf;
			
			SelfServiceClientServer.FillInOrderAndWarehouseInLine(NewRow, BasisDocuments, True);
		
		Else
			
			If (CurrentRow.Count > CurrentRow.CountByDocument
				And CurrentRow.NumberOfPackages <= CurrentRow.NumberOfPackagesByDocument) 
				Or (CurrentRow.Count < CurrentRow.CountByDocument
				And CurrentRow.NumberOfPackages >= CurrentRow.NumberOfPackagesByDocument) Then
				
				CurrentRow["Action"] = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
				
			EndIf;
			
			NewRow.RowCode                     = 0;
			NewRow.Count                    = 0;
			NewRow.NumberOfPackages            = 0;
			NewRow.NumberOfPackages            = 0;
			NewRow.VATAmount                      = 0;
			NewRow.PersonalIncomeTaxExpense           = 0;
			NewRow.Sum                         = 0;
			NewRow.DiscrepancyAmount              = 0;
			NewRow.AmountIncludingVAT                     = 0;
			NewRow.TheAmountOfTheSNDSRansmission          = 0;
			NewRow["Action"]                   = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
			NewRow.ThereIsAManagerComment      = False;
			NewRow.ThereIsACustomerComment        = False;
			NewRow.CustomerComment            = "";
			NewRow.ManagerComment          = "";
			NewRow.FilledInBySale         = True;
		
			ParametersForCalculatingNumberOfUnits = New Structure;
			ParametersForCalculatingNumberOfUnits.Insert("Suffix", "ByDocument");
			
			ParametersForCalculatingAmount = New Structure;
			ParametersForCalculatingAmount.Insert("Suffix", "ByDocument");
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "ByDocument");
			StructureOfActions.Insert("RecalculateSuffixAmount",            "ByDocument");
			
			If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
				StructureOfRecalculationOfAmount.Insert("Suffix", "ByDocument");
				StructureOfActions.Insert("RecalculateVATAmountSuffix",  StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
			EndIf;
			
			StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
			StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");

			BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
			BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
			
		EndIf;
		
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);

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

// End StandardSubsystems.Properties

&AtClient
Procedure ManagerSCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject, 
	                                         "ManagerComment",
	                                         "ThereIsAManagerComment",
	                                         "ProductsManagerSCommentBasement");

EndProcedure

&AtClient
Procedure CustomerCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject, 
	                                          "CustomerComment", 
	                                          "ThereIsACustomerComment", 
	                                          "ProductsCustomerCommentBasement");

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	DiscrepanciesServer.ActOfDiscrepanciesEstablishConditionalAppearanceOfFormOfDocument(ThisObject);
	
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
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
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
	
	// Agreement, type of basis for return of goods to the supplier or shipment of goods of storage
	TypesOfGroundsForActOfDivergence = New ValueList;
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor);
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Terms.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfGroundsForActOfDivergence;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Contract, type of basis for returning goods to the supplier
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Customer order line code blank mark

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product line of the overorder visibility

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter =  Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.OrderSales");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The product is ordered by the customer in excess of the order

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	
	// The product document is available for viewing only

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentInflow.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	// The product of the customer's order is a hyperlink

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// Product Name hyperlink

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SaleOfGoodsAndServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// The product is the customer's availability

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.SaleOfGoodsAndServices");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The product of the customer's order is not sold on orders

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.SaleOfGoodsAndServices");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.OrderSales");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bán hàng không theo đơn>';
													|ru = '<реализация не по заказу>';
													|en = '<sale is not against order>'; fa = '<sale is not against order>';
													|it = '<realizzo fuori ordine>';
													|pl = '<realizacja nie według zamówienia>';
													|tr = '<sipariş dışı satış>'"));
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
	
	// Setting the mark of an unfilled division, if the Work

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Department");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = SalesServer.TypesOfNomenclatureWithUnitAnalytics();

		Item.Appearance.SetParameterValue("MarkIncomplete", True);

	// disabling the visibility of the division if the product or container or commission operation

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = SalesServer.TypesOfNomenclatureWithUnitAnalytics();

	Item.Appearance.SetParameterValue("Visible", False);

	// explanatory inscription for the division, if the warehouses are not in the tabular part

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = SalesServer.TypesOfNomenclatureWithUnitAnalytics();

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho công việc>';
													|ru = '<для работ>';
													|en = '<for works>'; fa = '<for works>';
													|it = '<per i lavori>';
													|pl = '<dla robót>';
													|tr = '<iş için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Warehouse mark blank

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Type of price

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	// Item series
	
	DiscrepanciesServer.SetConditionalAppearanceOfSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");

	// Sum

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
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
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.OrderSales");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = New ValueList;
	ItemFilter.RightValue.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider);
	ItemFilter.RightValue.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider);	
	SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor;
	
	SelectionGroupAnd3 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage;
	
	ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.OrderSales");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = New ValueList;
	ItemFilter.RightValue.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider);
	ItemFilter.RightValue.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	// Registration of the price when working with a multi-turn container

	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.PathToSelectionFieldIsToReturnReusableContainer	= "Object.Goods.ToReturnReusablePackage";
	InstallationParameters.PathToSelectionFieldRequiresDepositForContainer		= "Object.Goods.PackageDepositIsRequired";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	// Unavailability of the price, if the type of price is not an arbitrary quantity
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Removing the blank mark from the price if the goods are returned to the committee
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = 0;
	
	TransactionList = New ValueList();
	TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	TransactionList.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	TransactionList.Add(Enums.BusinessTransactions.TransferToToller2_5);
	TransactionList.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	TransactionList.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.InList;
	ItemFilter.RightValue  = TransactionList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// Discrepancy quantity

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsQuantityDiscrepancies.Name);

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
	
	// Discrepancy amount

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDiscrepancyAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DiscrepancyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Discrepancy amount of VAT

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPersonalIncomeTaxExpense.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PersonalIncomeTaxExpense");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Discrepancy amount with VAT

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTheAmountOfTheSNDSRansmission.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheAmountOfTheSNDSRansmission");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	// The goods are the number of packages according to the customer's document, the mark is blank
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesByDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product number of the customer's packages mark blank
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product of the customer's sum is a blank mark
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	TransactionList = New ValueList();
	TransactionList.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	TransactionList.Add(Enums.BusinessTransactions.TransferToToller2_5);
	TransactionList.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	TransactionList.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.InList;
	ItemFilter.RightValue  = TransactionList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// TovarySummaNDS view only
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.NumberOfPackagesByDocument");

	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// The product is a preview only
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter =  ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.NumberOfPackagesByDocument");
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Presentation of the Goods field.Action depending on the business transaction
	SetPresentationOfItemsAction();
	
EndProcedure

&AtServer
Procedure SetPresentationOfItemsAction()
	
	// 1. Issue (Additional delivery is required - shortages)
	
	// 1.1. Write Off
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay, tạo';
													|ru = 'Списать сразу, оформить';
													|en = 'Write off immediately, register'; fa = 'Write off immediately, register';
													|it = 'Write off immediately, register';
													|pl = 'Write off immediately, register';
													|tr = 'Hemen stoktan düş, düzenle'"));
	
	// 1.2. Write off from the path
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay ""hàng đi đường"", tạo';
													|ru = 'Списать сразу ""из пути"", оформить';
													|en = 'Write off goods in transit, register'; fa = 'Write off goods in transit, register';
													|it = 'Write off goods in transit, register';
													|pl = 'Write off goods in transit, register';
													|tr = 'Hemen ""yoldan"" stoktan düş, düzenle'"));
	
	// 1.3. Take into account the inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, tạo';
													|ru = 'Учесть при инвентаризации, оформить';
													|en = 'Take into account during physical inventory count, register'; fa = 'Take into account during physical inventory count, register';
													|it = 'Take into account during physical inventory count, register';
													|pl = 'Take into account during physical inventory count, register';
													|tr = 'Stok sayımında dikkate al, düzenle'"));
	
	// 1.4. Return
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trả lại, tạo';
													|ru = 'Вернуть, оформить';
													|en = 'Return, register'; fa = 'Return, register';
													|it = 'Return, register';
													|pl = 'Return, register';
													|tr = 'İade et, düzenle'"));
	
	// 1.5. Expect
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đợi, tạo';
													|ru = 'Ожидать, оформить';
													|en = 'Wait, register'; fa = 'Wait, register';
													|it = 'Wait, register';
													|pl = 'Wait, register';
													|tr = 'Bekle, düzenle'"));
	
	// 1.6. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Register';
													|pl = 'Register';
													|tr = 'Düzenle'"));
	
	// 2. Issue and deliver (requires delivery - shortages)
	
	// 2.1. Write Off
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay, tạo và giao thêm';
													|ru = 'Списать сразу, оформить и допоставить';
													|en = 'Write off immediately, register and supply additionally'; fa = 'Write off immediately, register and supply additionally';
													|it = 'Write off immediately, register and supply additionally';
													|pl = 'Write off immediately, register and supply additionally';
													|tr = 'Hemen stoktan düş, düzenle ve tamamlama teslimatı yap'"));
	
	// 2.2. Write off from the path
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay ""hàng đi đường"", tạo và giao thêm';
													|ru = 'Списать сразу ""из пути"", оформить и допоставить';
													|en = 'Write off goods in transit, register and supply additionally'; fa = 'Write off goods in transit, register and supply additionally';
													|it = 'Write off goods in transit, register and supply additionally';
													|pl = 'Write off goods in transit, register and supply additionally';
													|tr = 'Hemen ""yoldan"" stoktan düş, düzenle ve tamamlama teslimatı yap'"));
	
	// 2.3. Take into account during inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, tạo và giao thêm';
													|ru = 'Учесть при инвентаризации, оформить и допоставить';
													|en = 'Take into account during physical inventory count, register and supply additionally'; fa = 'Take into account during physical inventory count, register and supply additionally';
													|it = 'Take into account during physical inventory count, register and supply additionally';
													|pl = 'Take into account during physical inventory count, register and supply additionally';
													|tr = 'Stok sayımında dikkate al, düzenle ve tamamlama teslimatı yap'"));
	
	// 2.4. Return
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trả lại, tạo và giao thêm';
													|ru = 'Вернуть, оформить и допоставить';
													|en = 'Return, register and supply additionally'; fa = 'Return, register and supply additionally';
													|it = 'Return, register and supply additionally';
													|pl = 'Return, register and supply additionally';
													|tr = 'İade et, düzenle ve tamamlama teslimatı yap'"));
	
	// 2.5. Expect
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đợi, tạo và giao thêm';
													|ru = 'Ожидать, оформить и допоставить';
													|en = 'Wait, register and supply additionally'; fa = 'Wait, register and supply additionally';
													|it = 'Wait, register and supply additionally';
													|pl = 'Wait, register and supply additionally';
													|tr = 'Bekle, düzenle ve tamamlama teslimatı yap'"));
	
	// 2.6. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Lập chứng từ và giao hàng bổ sung';
													|ru = 'Оформить и допоставить';
													|en = 'Register and supply additionally'; fa = 'ثبت و تأمین تکمیلی';
													|it = 'Formalizzare e consegnare';
													|pl = 'Sporządź i dostarcz dodatkowo';
													|tr = 'İşle ve takviye et'"));
	
	// 3. To deliver without registration (to ship now - shortages)
	
	// 3.1. Write Off
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay, giao thêm mà không tạo';
													|ru = 'Списать сразу, допоставить без оформления';
													|en = 'Write off immediately, supply additionally without registering'; fa = 'Write off immediately, supply additionally without registering';
													|it = 'Write off immediately, supply additionally without registering';
													|pl = 'Write off immediately, supply additionally without registering';
													|tr = 'Hemen stoktan düş, düzenleme yapmadan tamamlama teslimatı yap'"));
	
	// 3.2. Write Off from the path
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm ngay ""hàng đi đường"", giao thêm mà không tạo';
													|ru = 'Списать сразу ""из пути"", допоставить без оформления';
													|en = 'Write off goods in transit, supply additionally without registering'; fa = 'Write off goods in transit, supply additionally without registering';
													|it = 'Write off goods in transit, supply additionally without registering';
													|pl = 'Write off goods in transit, supply additionally without registering';
													|tr = 'Hemen ""yoldan"" stoktan düş, düzenleme yapmadan tamamlama teslimatı yap'"));
	
	// 3.3. Take into account during inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, giao thêm mà không tạo';
													|ru = 'Учесть при инвентаризации, допоставить без оформления';
													|en = 'Take into account during physical inventory count, supply additionally without registering'; fa = 'Take into account during physical inventory count, supply additionally without registering';
													|it = 'Take into account during physical inventory count, supply additionally without registering';
													|pl = 'Take into account during physical inventory count, supply additionally without registering';
													|tr = 'Stok sayımında dikkate al, düzenleme yapmadan tamamlama teslimatı yap'"));
	
	// 3.4. Return
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trả lại, giao thêm mà không tạo';
													|ru = 'Вернуть, допоставить без оформления';
													|en = 'Return, supply additionally without registering'; fa = 'Return, supply additionally without registering';
													|it = 'Return, supply additionally without registering';
													|pl = 'Return, supply additionally without registering';
													|tr = 'İade et, düzenleme yapmadan tamamlama teslimatı yap'"));
	
	// 3.5. Expect
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đợi, giao thêm mà không tạo';
													|ru = 'Ожидать, допоставить без оформления';
													|en = 'Wait, supply additionally without registering'; fa = 'Wait, supply additionally without registering';
													|it = 'Wait, supply additionally without registering';
													|pl = 'Wait, supply additionally without registering';
													|tr = 'Bekle, düzenleme yapmadan tamamlama teslimatı yap'"));
	
	// 3.6. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bổ sung giao hàng mà không lập chứng từ';
													|ru = 'Допоставить без оформления';
													|en = 'Supply additionally without registering'; fa = 'تأمین تکمیلی بدون ثبت';
													|it = 'Effettuare consegna senza formalizzare';
													|pl = 'Zwrócić bez sporządzenia';
													|tr = 'İşlem görmeden takviye'"));
	
	// 4. Issue (Purchase of the oversupplied - surplus)
	
	// 4.1. Sign in on the way
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi tăng ""hàng đi đường"", tạo';
													|ru = 'Оприходовать ""в путь"", оформить';
													|en = 'Receive ""in transit"", register'; fa = 'Receive ""in transit"", register';
													|it = 'Receive ""in transit"", register';
													|pl = 'Receive ""in transit"", register';
													|tr = '""Yolda"" olarak kaydet, düzenle ve iade et'"));
	
	// 4.2. Take into account during inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, tạo';
													|ru = 'Учесть при инвентаризации, оформить';
													|en = 'Take into account during physical inventory count, register'; fa = 'Take into account during physical inventory count, register';
													|it = 'Take into account during physical inventory count, register';
													|pl = 'Take into account during physical inventory count, register';
													|tr = 'Stok sayımında dikkate al, düzenle'"));
	
	// 4.3. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Register';
													|pl = 'Register';
													|tr = 'Düzenle'"));

	// 5. Issue and return (return of the over-delivered - surplus)
	
	// 5.1. Log in on the way
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi tăng ""hàng đi đường"", tạo và trả lại';
													|ru = 'Оприходовать ""в путь"", оформить и вернуть';
													|en = 'Receive ""in transit"", invoice the surplus and create Goods return'; fa = 'Receive ""in transit"", invoice the surplus and create Goods return';
													|it = 'Receive ""in transit"", invoice the surplus and create Goods return';
													|pl = 'Receive ""in transit"", invoice the surplus and create Goods return';
													|tr = '""Yolda"" olarak kaydet, düzenle ve iade et'"));
	
	// 5.2. Take into account the inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, tạo và trả lại';
													|ru = 'Учесть при инвентаризации, оформить и вернуть';
													|en = 'Take into account during physical inventory count, invoice the surplus and create Goods return'; fa = 'Take into account during physical inventory count, invoice the surplus and create Goods return';
													|it = 'Take into account during physical inventory count, invoice the surplus and create Goods return';
													|pl = 'Take into account during physical inventory count, invoice the surplus and create Goods return';
													|tr = 'Stok sayımında dikkate al, düzenle ve iade et'"));
	
	// 5.3. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo và trả lại';
													|ru = 'Оформить и вернуть';
													|en = 'Invoice the surplus and create Goods return'; fa = 'صدور فاکتور برای مازاد و ایجاد مرجوعی کالا';
													|it = 'Formalizzare e ritornare';
													|pl = 'Sporządź i wróć';
													|tr = 'İşle ve iade et'"));
	
	// 6. Return without registration (to register now - surplus)
	
	// 6.1. Sign in on the way
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi tăng ""hàng đi đường"", trả lại mà không tạo';
													|ru = 'Оприходовать ""в путь"", вернуть без оформления';
													|en = 'Receive ""in transit"", return the surplus'; fa = 'Receive ""in transit"", return the surplus';
													|it = 'Receive ""in transit"", return the surplus';
													|pl = 'Receive ""in transit"", return the surplus';
													|tr = 'Yolda"" olarak kaydet, düzenlemeden iade et'"));
	
	// 6.2. Take into account during inventory
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tính toán khi kiểm kê, trả lại mà không tạo';
													|ru = 'Учесть при инвентаризации, вернуть без оформления';
													|en = 'Take into account during physical inventory count, return the surplus'; fa = 'Take into account during physical inventory count, return the surplus';
													|it = 'Take into account during physical inventory count, return the surplus';
													|pl = 'Take into account during physical inventory count, return the surplus';
													|tr = 'Stok sayımında dikkate al, düzenlemeden iade et'"));
	
	// 6.2. Not filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.DiscrepancyTreatment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Quay lại không lập chứng từ';
													|ru = 'Вернуть без оформления';
													|en = 'Return the surplus'; fa = 'بازگرداندن مازاد';
													|it = 'Ritornare senza registrate';
													|pl = 'Zwrócić bez rejestracji';
													|tr = 'İşlemsiz iade'"));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandAndFillInVATRate()

	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GoodsFillInVATRate",
		"Visible",
		ValueIsFilled(Object.VATTaxation)
			And Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
			And Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate));

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	DiscrepanciesServer.SetValuesOfCachedReportFormDetails(ThisObject);
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		ToUseTermsOfSales = ToUseTermsOfSales And Handler.CustomerAgreementsAreApplicable();
		Object.BusinessOperation = Handler.BusinessOperation();
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		ConsignmentSales25 = True;
	EndIf;

	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	UseCreditNotes = GetFunctionalOption("UseCreditNotes");
	UseDocumentCorrection   = GetFunctionalOption("UseDocumentCorrection");
	
	DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
	
	ManagingFormDetailsDependingOnBaseType();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingShipment));
	SetVisibilityOfSeriesElements();
	
	FillOperationSelectionList();
	SetVisibilityForReflection();
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisForm);
	DiscrepanciesServer.DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(ThisObject);
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Object);
	SetVisibilityOfElementsByOperationServer();
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
	DiscrepanciesServer.FormInscriptionToReflectDiscrepancies(ThisObject, Object.Goods, Items.DiscrepancyLabel,
		Items.IssueDocuments, TypeOf(Object.Ref));
	
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms)
		And (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) 
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)) Then
		
		ProductSegment = GeneralPurposeTMServerCall.ObjectAttributeValue(
			Object.Terms,
			"ProductSegment");
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		TypeOfAct = "Transfer_";
	
	ElsIf DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		TypeOfAct = "SaleOfGoodsAndServices";

	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		TypeOfAct = "GoodsShipmentToCustomer";
	
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		TypeOfAct = "Safekeeping";
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
		
		TypeOfAct = "TransferToMaterialProvider";
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		TypeOfAct = "ReturnToMaterialProvider";
	
	Else
		
		TypeOfAct = "Return";
		
	EndIf;
	
	FillingVariant = "Variant1";
	
	ShowExplanation = UseCreditNotes
		And DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInVATTaxationPurchases(Object);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	Else
		
		Items.GoodsProducts.ChoiceParameters = New FixedArray(New Array);
		AvailableTypeList = New Array();
		AvailableTypeList.Add(Enums.ItemsTypes.ReusablePackage);
		AvailableTypeList.Add(Enums.ItemsTypes.OwnGoods);
		TMCommonUseClientServer.AddSelectionParameter(Items.GoodsProducts, "ItemsType", AvailableTypeList);
		
	EndIf;
	
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure ManagingFormDetailsDependingOnBaseType()

	Items.GoodsFillInVATRate.Enabled = True;

	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
		
		//Partner
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		Items.Partner.Title       = NStr("vi = 'Nhà cung cấp';
										|ru = 'Поставщик';
										|en = 'Vendor'; fa = 'تأمین‌کننده';
										|it = 'Fornitore';
										|pl = 'Vendor';
										|tr = 'Tedarikçi'");
		
		Items.ProductsCustomerCommentBasement.Title = NStr("vi = 'Ghi chú của nhà cung cấp về chênh lệch tại dòng';
															|ru = 'Комментарии поставщика по расхождениям в строке';
															|en = 'Vendor''s comments to the line discrepancies'; fa = 'Vendor''s comments to the line discrepancies';
															|it = 'Commenti del fornitore riguardo le discrepanze nella riga';
															|pl = 'Komentarze dostawcy odnośnie odchylenia w wierszu';
															|tr = 'Satırdaki tutarsızlıklara ilişkin tedarikçi yorumları'");
		Items.GoodsThereIsACustomerComment.Title   = NStr("vi = 'từ nhà cung cấp';
															|ru = 'от поставщика';
															|en = 'from vendor'; fa = 'from vendor';
															|it = 'от поставщика';
															|pl = 'od dostawcy';
															|tr = 'sağlayıcıdan'");
		
		//Terms
		AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
		
		If DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			//Terms
			BusinessTransactions = New Array;
			BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
			BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseByImport);
			BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
			BusinessTransactions.Add(Enums.BusinessTransactions.ConsignmentProcurement);
			
			AgreementSelectionParameters = New Array;
			AgreementSelectionParameters.Add(New ChoiceParameter("Filter.BusinessOperation", BusinessTransactions));
			
			Items.Terms.ChoiceParameters = New FixedArray(AgreementSelectionParameters);
			
			//BusinessOperation
			SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
			SelectionListBusinessOperations.Clear();
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnOfGoodsToVendor);
			
			If GetFormFunctionalOption("UsePurchaseCommission") Then
				SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
			EndIf;
			
			//DiscrepanciesPostingMethod
			SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
				NStr("vi = 'Thay đổi trả lại hàng cho nhà cung cấp';
					|ru = 'Изменить возврат товаров поставщику';
					|en = 'Edit the return of goods to vendor'; fa = 'Edit the return of goods to vendor';
					|it = 'Edit the return of goods to vendor';
					|pl = 'Edit the return of goods to vendor';
					|tr = 'Tedarikçi ürün iadesini değiştir'"));
			
			Items.GoodsDocumentInflow.Visible = True;
			
		Else
			
			//BusinessOperation
			SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
			SelectionListBusinessOperations.Clear();
			SelectionListBusinessOperations.Add(
				Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale);
			
			Items.GoodsDocumentInflow.Visible = False;
			
		EndIf;
		
		//Contract
		RelationsOfContractSelectionParameters = New Array;
		For Each Link In Items.Contract.ChoiceParameterLinks Do
			
			RelationshipOfSelectionParameters = Link; // ChoiceParameterLink
			If Not (RelationshipOfSelectionParameters.Name = "Terms"
				Or RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation") Then
				
				RelationsOfContractSelectionParameters.Add(RelationshipOfSelectionParameters);
				
			ElsIf RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
				ChoiceParameter = New ChoiceParameterLink("Filter.BusinessOperation", "ContractBusinessTransaction");
				
				RelationsOfContractSelectionParameters.Add(ChoiceParameter);
			EndIf;
		EndDo;
		
		Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
		
		Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo trả lại';
												|ru = 'По возвратам';
												|en = 'By returns'; fa = 'By returns';
												|it = 'Per i resi';
												|pl = 'Według zwrotów';
												|tr = 'İadeler üzerine'");
		Items.GoodsPriceKind.Visible = False;
		Items.GoodsDocumentBasis.Title = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
												|ru = 'Возврат поставщику';
												|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
												|it = 'Reso al fornitore';
												|pl = 'Zwrot do dostawcy ';
												|tr = 'Tedarikçiye iade'");
		
		//Products: division
		Items.GoodsDepartment.Visible = False;
		
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
		//Totals
		Items.ForSalesWithoutVAT.Title = NStr("vi = 'Theo trả lại';
												|ru = 'По возвратам';
												|en = 'By returns'; fa = 'By returns';
												|it = 'Per i resi';
												|pl = 'Według zwrotów';
												|tr = 'İadeler üzerine'");
		Items.ByImplementationsWithVAT.Title = NStr("vi = 'Theo trả lại';
													|ru = 'По возвратам';
													|en = 'By returns'; fa = 'By returns';
													|it = 'Per i resi';
													|pl = 'Według zwrotów';
													|tr = 'İadeler üzerine'");
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage Then
		
		Items.ProductsCustomerCommentBasement.Title = NStr("vi = 'Ghi chú của bên thuê kho về chênh lệch trong dòng';
															|ru = 'Комментарии поклажедателя по расхождениям в строке';
															|en = 'Vendor comments on discrepancies in the line'; fa = 'Vendor comments on discrepancies in the line';
															|it = 'Commenti del depositante riguardo alle discrepanze nella riga';
															|pl = 'Komentarze depozytariusza odnośnie odchylenia w wierszu:';
															|tr = 'Mevduat sahibinin satırdaki tutarsızlıklara ilişkin yorumları'");
		Items.GoodsThereIsACustomerComment.Title   = NStr("vi = 'từ bên gửi hàng';
															|ru = 'от поклажедателя';
															|en = 'from depositor'; fa = 'from depositor';
															|it = 'от поклажедателя';
															|pl = 'from depositor';
															|tr = 'saklama sorumlusundan'");
		
		If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			
			//Partner
			ChoiceParametersArray = New Array;
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
			Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
			Items.Partner.Title       = NStr("vi = 'Bên gửi hàng';
											|ru = 'Поклажедатель';
											|en = 'Depositor'; fa = 'امانت‌گذار';
											|it = 'Depositante';
											|pl = 'Depositor';
											|tr = 'Mevduat sahibi'");
			
			//Terms
			AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfSale");
			
			//BusinessOperation
			SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
			SelectionListBusinessOperations.Clear();
			SelectionListBusinessOperations.Add(
				Enums.BusinessTransactions.DeliveryForPrincipal);
				
		Else
			
			//Partner
			ChoiceParametersArray = New Array;
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
			Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
			Items.Partner.Title       = NStr("vi = 'Bên gửi hàng';
											|ru = 'Поклажедатель';
											|en = 'Depositor'; fa = 'امانت‌گذار';
											|it = 'Depositante';
											|pl = 'Depositor';
											|tr = 'Mevduat sahibi'");
			
			//Terms
			AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
			
			//BusinessOperation
			SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
			SelectionListBusinessOperations.Clear();
			SelectionListBusinessOperations.Add(
				Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale);
			
			Items.GoodsDocumentInflow.Visible = True;
			
		EndIf;
		
		//Contract
		RelationsOfContractSelectionParameters = New Array;
		ChoiceParameterLinks = Items.Contract.ChoiceParameterLinks; // Array of ChoiceParameterLink
		For Each RelationshipOfSelectionParameters In ChoiceParameterLinks Do

			If Not (RelationshipOfSelectionParameters.Name = "Terms"
				Or RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation") Then
				
				RelationsOfContractSelectionParameters.Add(RelationshipOfSelectionParameters);
				
			ElsIf RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
				ChoiceParameter = New ChoiceParameterLink("Filter.BusinessOperation", "ContractBusinessTransaction");
				
				RelationsOfContractSelectionParameters.Add(ChoiceParameter);
			EndIf;
		EndDo;
		
		Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
			NStr("vi = 'Thay đổi giao hàng từ kho';
				|ru = 'Изменить отгрузку товаров с хранения';
				|en = 'Change the VMI pick-up request from vendor'; fa = 'Change the VMI pick-up request from vendor';
				|it = 'Change the VMI pick-up request from vendor';
				|pl = 'Change the VMI pick-up request from vendor';
				|tr = 'Ürünlerin ambardan sevkiyatını değiştir'"));
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection,
			NStr("vi = 'Lập chứng từ giao hàng từ kho (điều chỉnh)';
				|ru = 'Оформить отгрузку товаров с хранения (исправление)';
				|en = 'Register the VMI pick-up request from vendor (correction)'; fa = 'Register the VMI pick-up request from vendor (correction)';
				|it = 'Register the VMI pick-up request from vendor (correction)';
				|pl = 'Register the VMI pick-up request from vendor (correction)';
				|tr = 'Ürünlerin ambardan sevkiyatını oluştur (yama)'"));
		
		Items.GoodsFillInByBasis.Title = NStr("vi = 'Khi giao hàng';
												|ru = 'По отгрузке с ответственного хранения';
												|en = 'By VMI pick-up request from vendor'; fa = 'By VMI pick-up request from vendor';
												|it = 'Per spedizione di merci dalla custodia';
												|pl = 'Wg wysyłki z depozytu';
												|tr = 'Satıcı tarafından yönetilen stoktan transfere ilişkin'");
		Items.GoodsPriceKind.Visible = False;
		Items.GoodsDocumentBasis.Title = NStr("vi = 'Xuất kho lô hàng từ nơi giữ';
												|ru = 'Отгрузка с ответственного хранения';
												|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
												|it = 'Spedizione di merci dalla custodia';
												|pl = 'Wysyłka z depozytu';
												|tr = 'Satıcı tarafından yönetilen stoktan transfer'");
		
		//Products: division
		Items.GoodsDepartment.Visible = False;
		
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
		//Totals
		Items.ForSalesWithoutVAT.Title = NStr("vi = 'Khi giao hàng';
												|ru = 'По отгрузке с ответственного хранения';
												|en = 'By VMI pick-up request from vendor'; fa = 'By VMI pick-up request from vendor';
												|it = 'Per spedizione di merci dalla custodia';
												|pl = 'Wg wysyłki z depozytu';
												|tr = 'Satıcı tarafından yönetilen stoktan transfere ilişkin'");
		Items.ByImplementationsWithVAT.Title = NStr("vi = 'Khi giao hàng';
													|ru = 'По отгрузке с ответственного хранения';
													|en = 'By VMI pick-up request from vendor'; fa = 'By VMI pick-up request from vendor';
													|it = 'Per spedizione di merci dalla custodia';
													|pl = 'Wg wysyłki z depozytu';
													|tr = 'Satıcı tarafından yönetilen stoktan transfere ilişkin'");
		
		//More
		Items.NumberAccordingToCustomerData.Title = NStr("vi = 'Số biên bản 
														|theo dữ liệu của bên thuê kho';
														|ru = 'Номер акта 
														|по данным поклажедателя';
														|en = 'Dispute number 
														|on vendor''s data'; fa = 'Dispute number 
														|on vendor''s data';
														|it = 'Numero dell''atto 
														| in base ai dati del depositante';
														|pl = 'Numer aktu 
														|wg danych depozytariusza';
														|tr = 'Mal sahibine göre 
														| rapor numarası'");
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
		//Terms
		AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfSale");
		Items.Terms.Visible = ToUseTermsOfSales;
		Items.GoodsDocumentInflow.Visible = False;
		
		//Partner, Counterparty, Contract
		Handler.AdjustItemSelectionSettings(ThisObject, Object);
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Handler.BusinessOperation());
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee Then
				Text_FixMethodCorrection   = NStr("vi = 'Thay đổi chuyển giao hàng hóa cho bên lưu kho';
													|ru = 'Изменить передачу товаров хранителю';
													|en = 'Change the VMI fill-up'; fa = 'Change the VMI fill-up';
													|it = 'Change the VMI fill-up';
													|pl = 'Change the VMI fill-up';
													|tr = 'VMI transferini değiştir'");
				Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ chuyển giao hàng hóa cho bên lưu kho (điều chỉnh)';
														|ru = 'Оформить передачу товаров хранителю (исправление)';
														|en = 'Register the VMI fill-up (correction)'; fa = 'Register the VMI fill-up (correction)';
														|it = 'Register the VMI fill-up (correction)';
														|pl = 'Register the VMI fill-up (correction)';
														|tr = 'VMI transferini oluştur (yama)'");
			ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor Then
				Text_FixMethodCorrection   = NStr("vi = 'Thay đổi chuyển giao nguyên vật liệu cho người nhận gia công';
													|ru = 'Изменить передачу сырья переработчику';
													|en = 'Change the Goods issue — Subcontracting services received'; fa = 'Change the Goods issue — Subcontracting services received';
													|it = 'Change the Goods issue — Subcontracting services received';
													|pl = 'Change the Goods issue — Subcontracting services received';
													|tr = 'Hammaddelerin fason üreticiye aktarımını değiştir'");
				Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ chuyển giao nguyên vật liệu cho người nhận gia công (điều chỉnh)';
														|ru = 'Оформить передачу сырья переработчику (исправление)';
														|en = 'Register the Goods issue — Subcontracting services received (correction)'; fa = 'Register the Goods issue — Subcontracting services received (correction)';
														|it = 'Register the Goods issue — Subcontracting services received (correction)';
														|pl = 'Register the Goods issue — Subcontracting services received (correction)';
														|tr = 'Fason üretici stokunu doldurma transferini oluştur (yama)'");
			EndIf;
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
				Text_FixMethodCorrection);
			SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection,
				Text_ProcessingMethodCorrection);
		Else
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
				NStr("vi = 'Thay đổi chứng từ chuyển giao ký gửi';
					|ru = 'Изменить передачу на комиссию';
					|en = 'Change the consignment sales'; fa = 'Change the consignment sales';
					|it = 'Change the consignment sales';
					|pl = 'Change the consignment sales';
					|tr = 'Komisyon aktarımını değiştir'"));
			SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection,
				NStr("vi = 'Lập chứng từ chuyển giao ký gửi (điều chỉnh)';
					|ru = 'Оформить передачу на комиссию (исправление)';
					|en = 'Register the consignment sales (correction)'; fa = 'Register the consignment sales (correction)';
					|it = 'Register the consignment sales (correction)';
					|pl = 'Register the consignment sales (correction)';
					|tr = 'Konsinye satışı oluştur (yama)'"));
		EndIf;
		
		Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo điều chuyển';
												|ru = 'По передачам';
												|en = 'By transfers'; fa = 'By transfers';
												|it = 'Per consegne';
												|pl = 'Po przekazach';
												|tr = 'Transfere ilişkin'");
		Items.GoodsDocumentBasis.Title = Handler.TitleOfDocumentGroundsOfAct();
		
		//Products: division
		Items.GoodsDepartment.Visible = False;
		
		//Totals
		Items.ForSalesWithoutVAT.Title = NStr("vi = 'Theo điều chuyển';
												|ru = 'По передачам';
												|en = 'By transfers'; fa = 'By transfers';
												|it = 'Per consegne';
												|pl = 'Po przekazach';
												|tr = 'Transfere ilişkin'");
		Items.ByImplementationsWithVAT.Title = NStr("vi = 'Theo điều chuyển';
													|ru = 'По передачам';
													|en = 'By transfers'; fa = 'By transfers';
													|it = 'Per consegne';
													|pl = 'Po przekazach';
													|tr = 'Transfere ilişkin'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		// Partner
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
		//Contract
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
		
		ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
		ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction));
	
		ArrayOfSelectParameterRelationships = New Array;
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
			
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Partner", "Object.Partner", LinkedValueChangeMode.Clear));
		
		Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
		Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
		
		//Terms
		AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
		
		Items.PriceIncludesVAT.Visible       = False;
		Items.GoodsPriceKind.Visible         = False;
		Items.GoodsPrice.Visible            = False;
		Items.GoodsAmountGroup.Visible     = False;
		Items.GoodsVATRate.Visible       = False;
		Items.ProductsVATGroup.Visible       = False;
		Items.ProductsGroupSumSNDS.Visible = False;
		Items.GoodsDepartment.Visible   = False;
		Items.Terms.Visible            = False;
		
		Items.Partner.Title                        = NStr("vi = 'Bên đặt gia công';
															|ru = 'Давалец';
															|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
															|it = 'Fornitore';
															|pl = 'Material provider';
															|tr = 'Malzeme tedarikçisi'");
		Items.ProductsCustomerCommentBasement.Title = NStr("vi = 'Ghi chú của bên đặt gia công về chênh lệch trong dòng';
															|ru = 'Комментарии давальца по расхождениям в строке';
															|en = 'Provider comments on line discrepancies'; fa = 'Provider comments on line discrepancies';
															|it = 'Commenti del fornitore per le discrepanze nella stringa';
															|pl = 'Uwagi właściciela surowców odnośnie odchylenia w wierszu';
															|tr = 'Sağlayıcının satırdaki tutarsızlıklara ilişkin yorumları'");
		Items.GoodsThereIsACustomerComment.Title   = NStr("vi = 'từ người đặt gia công';
															|ru = 'от давальца';
															|en = 'from provider'; fa = 'from provider';
															|it = 'от давальца';
															|pl = 'from provider';
															|tr = 'sağlayıcıdan'");
		Items.NumberAccordingToCustomerData.Title           = NStr("vi = 'Số biên bản 
																		| theo dữ liệu của bên đặt gia công';
																		|ru = 'Номер акта 
																		|по данным давальца';
																		|en = 'Report number 
																		|by provider data'; fa = 'Report number 
																		|by provider data';
																		|it = 'Numero atto
																		|in base ai dati del fornitore';
																		|pl = 'Numer aktu 
																		|wg danych właściciela surowców';
																		|tr = 'Sağlayıcıya ilişkin 
																		| rapor numarası'");
		Items.ExternalDocumentName.Title = NStr("vi = 'Tên gọi 
																		| theo dữ liệu của bên đặt gia công';
																		|ru = 'Наименование 
																		|по данным давальца';
																		|en = 'Description 
																		|by provider data'; fa = 'Description 
																		|by provider data';
																		|it = 'Denominazione 
																		|in base ai dati del fornitore';
																		|pl = 'Nazwa 
																		|według danych właściciela surowców';
																		|tr = 'Sağlayıcıya ilişkin
																		| isimlendirme'");

		Items.GoodsFillInVATRate.Enabled = False;

		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
			
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
			
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
				NStr("vi = 'Thay đổi chứng từ chuyển giao cho bên đặt gia công';
					|ru = 'Изменить передачу давальцу';
					|en = 'Change the Goods issue — Subcontracting services delivered'; fa = 'Change the Goods issue — Subcontracting services delivered';
					|it = 'Change the Goods issue — Subcontracting services delivered';
					|pl = 'Change the Goods issue — Subcontracting services delivered';
					|tr = 'Sağlayıcı aktarımını değiştir'"));
			SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection,
				NStr("vi = 'Lập chứng từ chuyển giao cho bên đặt gia công (điều chỉnh)';
					|ru = 'Оформить передачу давальцу (исправление)';
					|en = 'Register the Goods issue — Subcontracting services delivered (correction)'; fa = 'Register the Goods issue — Subcontracting services delivered (correction)';
					|it = 'Register the Goods issue — Subcontracting services delivered (correction)';
					|pl = 'Register the Goods issue — Subcontracting services delivered (correction)';
					|tr = 'Sağlayıcı aktarımını oluştur (yama)'"));
			
			Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo chuyển giao cho người đặt gia công';
													|ru = 'По передаче давальцу';
													|en = 'By transfer to provider'; fa = 'By transfer to provider';
													|it = 'In base al trasferimento al fornitore';
													|pl = 'Według przekazania właściciela surowców';
													|tr = 'Sağlayıcıya transfere ilişkin'");
			Items.GoodsDocumentBasis.Title     =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
			Items.ForSalesWithoutVAT.Title               = NStr("vi = 'Theo chuyển giao cho người đặt gia công';
																|ru = 'По передаче давальцу';
																|en = 'By transfer to provider'; fa = 'By transfer to provider';
																|it = 'In base al trasferimento al fornitore';
																|pl = 'Według przekazania właściciela surowców';
																|tr = 'Sağlayıcıya transfere ilişkin'");
			Items.ByImplementationsWithVAT.Title                 = NStr("vi = 'Theo chuyển giao cho người đặt gia công';
																		|ru = 'По передаче давальцу';
																		|en = 'By transfer to provider'; fa = 'By transfer to provider';
																		|it = 'In base al trasferimento al fornitore';
																		|pl = 'Według przekazania właściciela surowców';
																		|tr = 'Sağlayıcıya transfere ilişkin'");
			
			Items.GoodsDocumentInflow.Visible = False;
			
		ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
			
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
			
			SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
				NStr("vi = 'Thay đổi chứng từ trả lại cho bên đặt gia công';
					|ru = 'Изменить возврат давальцу';
					|en = 'Change the Goods return — Subcontracting services delivered'; fa = 'Change the Goods return — Subcontracting services delivered';
					|it = 'Change the Goods return — Subcontracting services delivered';
					|pl = 'Change the Goods return — Subcontracting services delivered';
					|tr = 'Sağlayıcı iadesini değiştir'"));
			SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
				Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection,
				NStr("vi = 'Lập chứng từ trả lại cho bên đặt gia công (điều chỉnh)';
					|ru = 'Оформить возврат давальцу (исправление)';
					|en = 'Register the Goods return — Subcontracting services delivered (correction)'; fa = 'Register the Goods return — Subcontracting services delivered (correction)';
					|it = 'Register the Goods return — Subcontracting services delivered (correction)';
					|pl = 'Register the Goods return — Subcontracting services delivered (correction)';
					|tr = 'Sağlayıcıya iade oluştur (yama)'"));
			
			Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo chứng từ trả lại cho bên đặt gia công';
													|ru = 'По возврату давальцу';
													|en = 'By Goods return — Subcontracting services delivered'; fa = 'By Goods return — Subcontracting services delivered';
													|it = 'By Goods return — Subcontracting services delivered';
													|pl = 'By Goods return — Subcontracting services delivered';
													|tr = 'Sağlayıcı iadesine göre'");
			Items.GoodsDocumentBasis.Title     =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
			Items.ForSalesWithoutVAT.Title               = NStr("vi = 'Theo chứng từ trả lại cho bên đặt gia công';
																|ru = 'По возврату давальцу';
																|en = 'By Goods return — Subcontracting services delivered'; fa = 'By Goods return — Subcontracting services delivered';
																|it = 'By Goods return — Subcontracting services delivered';
																|pl = 'By Goods return — Subcontracting services delivered';
																|tr = 'Sağlayıcı iadesine göre'");
			Items.ByImplementationsWithVAT.Title                 = NStr("vi = 'Theo chứng từ trả lại cho bên đặt gia công';
																		|ru = 'По возврату давальцу';
																		|en = 'By Goods return — Subcontracting services delivered'; fa = 'By Goods return — Subcontracting services delivered';
																		|it = 'By Goods return — Subcontracting services delivered';
																		|pl = 'By Goods return — Subcontracting services delivered';
																		|tr = 'Sağlayıcı iadesine göre'");
			
			Items.GoodsDocumentInflow.Visible = True;
			
		EndIf;
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		//Terms
		AgreementTypeRestriction     = New TypeDescription("CatalogRef.TermsOfSale");
		Items.Terms.Visible = ToUseTermsOfSales;
		
		Items.PriceIncludesVAT.Visible = False;
		
		// Goods
		Items.PriceIncludesVAT.Visible       = False;
		Items.GoodsVATRate.Visible       = False;
		Items.ProductsVATGroup.Visible       = False;
		Items.ProductsGroupSumSNDS.Visible = False;
		Items.GoodsDepartment.Visible   = False;
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferOfTitleToGoods);

		Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo giao hàng cho khách';
												|ru = 'По отгрузке товаров клиенту';
												|en = 'By goods shipment to customer'; fa = 'By goods shipment to customer';
												|it = 'By goods shipment to customer';
												|pl = 'By goods shipment to customer';
												|tr = 'Müşteri ürün sevkiyatına göre'");
		Items.GoodsDocumentBasis.Title     = NStr("vi = 'Giao hàng cho khách';
													|ru = 'Отгрузка товаров клиенту';
													|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
													|it = 'Goods shipment to customer';
													|pl = 'Goods shipment to customer';
													|tr = 'Müşteriye ürün sevkiyatı'");
		Items.ForSalesWithoutVAT.Title         = NStr("vi = 'Theo giao hàng cho khách';
														|ru = 'По отгрузке товаров клиенту';
														|en = 'By goods shipment to customer'; fa = 'By goods shipment to customer';
														|it = 'By goods shipment to customer';
														|pl = 'By goods shipment to customer';
														|tr = 'Müşteri ürün sevkiyatına göre'");
		Items.ByImplementationsWithVAT.Title           = NStr("vi = 'Theo giao hàng cho khách';
																|ru = 'По отгрузке товаров клиенту';
																|en = 'By goods shipment to customer'; fa = 'By goods shipment to customer';
																|it = 'By goods shipment to customer';
																|pl = 'By goods shipment to customer';
																|tr = 'Müşteri ürün sevkiyatına göre'");
		
		Items.GoodsDocumentInflow.Visible = False;

	Else
		
		//Terms
		AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfSale");
		Items.Terms.Visible = ToUseTermsOfSales;
		Items.GoodsFillInByBasis.Title = NStr("vi = 'Theo chứng từ bán hàng';
												|ru = 'По реализациям';
												|en = 'By sales'; fa = 'بر اساس فروش';
												|it = 'Per i realizzi';
												|pl = 'Wg sprzedaży';
												|tr = 'Satışlara ilişkin'");
		Items.GoodsDocumentInflow.Visible = False;
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.SaleToCustomer);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.DeliveryForPrincipal);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferOfTitleToGoods);
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
		
		BasisOfCompilation = "";
		
		If Object.BaseDocumentForDrawingUpCertificate = BasisOfCompilation Then
			//Business Operation - Addition to the list of selection of business operations for all types of grounds
			SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnOfGoodsToVendor);
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale);
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferToToller2_5);
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
		EndIf;
	EndIf;
	
	Items.Terms.TypeRestriction = AgreementTypeRestriction;
	
EndProcedure

&AtServer
Procedure FillInVATTaxationATServer()
	
	CompleteVATTaxation(True, False);
	WhenChangingVATTaxationServer();
	
EndProcedure

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	CurrentData               = Object.Goods.FindByID(CurDataId);
	ParametersOfSeriesIndicationForm = ProductsServer.ParametersOfSeriesIndicationForm(Object,
																				SeriesSpecificationParameters,
																				CurDataId,
																				ThisForm);
	
	If CurrentData.FilledInBySale Then
		ParametersOfSeriesIndicationForm.OnlyQuantityEditing = True;
	EndIf;
	
	Return ParametersOfSeriesIndicationForm;
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData) Then
	
		If CurrentData = Undefined Then
			CurrentData = Items.Goods.CurrentData;
			CurDataId = CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		If CurrentData.FilledInBySale
				And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(CurrentData.BatchesIndicationStatus,
					SeriesSpecificationParameters) Then
			ShowMessageBox(,NStr("vi = 'Không thể chỉnh sửa sê-ri trong dòng từ chứng từ cơ sở, hãy thêm dòng mới.';
								|ru = 'Серия в строке из документа-основания не редактируется, добавьте новую строку.';
								|en = 'Batch cannot be edited in a line of the base document, add a new line.'; fa = 'Batch cannot be edited in a line of the base document, add a new line.';
								|it = 'Le serie nella riga del documento-causale non è modificabile, aggiungere una nuova riga.';
								|pl = 'Seria w wierszu z dokumentu podstawy nie jest edytowana, dodaj nowy wiersz.';
								|tr = 'Temel belgedeki satırdaki parti düzenlenemez, yeni bir satır ekleyin.'"));
			Return;
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
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
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	DiscrepanciesServer.ProcessSeriesIndication_(ThisForm, ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	DiscrepanciesServer.ProcessingSelectionOfSelectionOnServer(ThisObject, CachedValues, ValueSelected, True, True);
	
EndProcedure

&AtServer
Procedure ClientWhenChangingOnServer()
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If ToUseTermsOfSales Then
			FillIn_TermsOfSales();
		EndIf;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		If ToUseTermsOfSales Or Not Handler.CustomerAgreementsAreApplicable() Then
			FillIn_TermsOfSales();
		EndIf;
		
	Else
		FillInTermsOfPurchase();
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer()
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		ClientWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	CompleteVATTaxation(False, True);
	WhenChangingVATTaxationServer();
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer()
	
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingVATTaxationServer()
	
	StructureOfActions = New Structure;
	
	CachedValues = Undefined;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);

	SetVisibilityOfCommandAndFillInVATRate();

EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
	If ValueIsFilled(Object.Organization) Then
		
		DiscrepanciesServer.FillInDefaultContract(Object, ContractBusinessTransaction);
		
		CompleteVATTaxation(True, False);
		WhenChangingVATTaxationServer();
		
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	CompleteVATTaxation();
	WhenChangingVATTaxationServer();
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CompleteVATTaxation(True, False);
	WhenChangingVATTaxationServer();
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice;
		TypeOfAct = "SaleOfGoodsAndServices";
		ChangingActType = True;
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice
		And Object.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer Then
		
		Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer;
		TypeOfAct = "GoodsShipmentToCustomer";
		ChangingActType = True;
		
	Else
		ChangingActType = False;
	EndIf;
	
	If ChangingActType Then
		AutoTitle = False;
		GenerateHeadersThatDependOnBaseType(Not ValueIsFilled(Object.Ref));
		ManagingFormDetailsDependingOnBaseType();
		FillOperationSelectionList();
		SetVisibilityForReflection();
		DiscrepanciesServer.DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(ThisObject);
	Else
		ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
		DiscrepanciesServer.FillInDefaultContract(Object, ContractBusinessTransaction);
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		Object.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments;
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		Object.PriceIncludesVAT = False;
		PriceIncludesVATOnChangeServer();
		Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		Object.PriceIncludesVAT = False;
		PriceIncludesVATOnChangeServer();
		Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer Then
		Object.PriceIncludesVAT = True;
		Object.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments;
		Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer;
	EndIf;
	
	CompleteVATTaxation();
	WhenChangingVATTaxationServer();
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	SetVisibilityOfElementsByOperationServer();
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer()
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		DocumentSales = FormAttributeToValue("Object");
		DocumentSales.FillInTermsOfSalesUnderAgreement(ProductSegment);
		ValueToFormAttribute(DocumentSales, "Object");
		
		If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			Object.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer;
		EndIf;
		
	Else
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchaseUnderAgreement();
		ValueToFormAttribute(DocumentPurchases, "Object");
		
	EndIf;
	
	FillOperationSelectionList();
	WhenBusinessTransactionChangesServer();
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
	DocumentCurrency = Object.Currency;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure SetVisibilityForReflection()
	
	BasisOfActIsShipmentOfGoodsFromStorage =
		DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
			Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
			Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
		;
	
	Items.GroupRecordMethod.Visible = 
	    DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
	    Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
	    Or DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Object.TypeOfBaseDocumentForNonConformanceCertificate)
	    Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or BasisOfActIsShipmentOfGoodsFromStorage;
	
	Items.MethodForReflectingDiscrepanciesCorrectionCorrection.Visible =
		UseCreditNotes
			And DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
			And GetFunctionalOption("UseDocumentCorrection")
		Or (UseDocumentCorrection
			And (DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate)))
		Or (UseDocumentCorrection
			And BasisOfActIsShipmentOfGoodsFromStorage);

	Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.Visible =
	    UseCreditNotes
	    And DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate);

	Items.MethodForReflectingDiscrepanciesAdjustmentNew.Visible =
		Object.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments;
	
	Items.GroupInformationAboutAvailabilityOfTheRecordMethod.Visible = 
		Not DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If Items.Find("BusinessOperation") <> Undefined Then
			
			If Not ToUseTermsOfSales Then
				SaleWithDeferredTransferOfTitleIsAllowed = UseShipmentWithDeferredTransferOfTitle;
			ElsIf Not ValueIsFilled(Object.Terms) Then
				SaleWithDeferredTransferOfTitleIsAllowed = True;
			Else
				SaleWithDeferredTransferOfTitleIsAllowed = 
					TMCommonUse.ValueOfBooleanObjectSProps(Object.Terms, "SaleWithDeferredTransferOfTitleIsAllowed");
			EndIf;
			
			LocalImplementationIsPossible = GetFunctionalOption("UseManagementCompany");
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
			
			If Not SaleWithDeferredTransferOfTitleIsAllowed Then
				
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;
				
			Else
				
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
						Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
				EndIf;
				
			EndIf;
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.TransferOfTitleToGoods);
			
			If Not SaleWithDeferredTransferOfTitleIsAllowed Then
				
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;
				
			Else
				
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
						Enums.BusinessTransactions.TransferOfTitleToGoods);
				EndIf;
				
			EndIf;
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.GoodsShipmentToCustomer);
			
			If Not SaleWithDeferredTransferOfTitleIsAllowed Then
				
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;
				
			Else
				
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
						Enums.BusinessTransactions.GoodsShipmentToCustomer);
				EndIf;
				
			EndIf;
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
			
			If Not LocalImplementationIsPossible Then
				
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;
				
			Else
				
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
					Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If Items.Find("BusinessOperation") <> Undefined Then
			
			If Not ToUseTermsOfSales Then
				SaleWithDeferredTransferOfTitleIsAllowed = UseShipmentWithDeferredTransferOfTitle;
			ElsIf Not ValueIsFilled(Object.Terms) Then
				SaleWithDeferredTransferOfTitleIsAllowed = True;
			Else
				SaleWithDeferredTransferOfTitleIsAllowed = 
					TMCommonUse.ValueOfBooleanObjectSProps(Object.Terms, "SaleWithDeferredTransferOfTitleIsAllowed");
			EndIf;
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.TransferOfTitleToGoods);
			
			If Not SaleWithDeferredTransferOfTitleIsAllowed Then
				
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;
				
			Else
				
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
						Enums.BusinessTransactions.TransferOfTitleToGoods);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions(ProductSegment);
	ValueToFormAttribute(DocumentSales, "Object");
	
	FillOperationSelectionList();
	
	WhenBusinessTransactionChangesServer();
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInTermsOfPurchase()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultPurchaseConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInByBasis()
	
	DiscrepanciesServer.FillInByBasis(ThisForm);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()

	ParametersArray = New Array;
	ArrayOfProductTypes = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", ArrayOfProductTypes));
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
	
	PricesWithoutVAT = DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	WithoutChoiceOfTaxation = (PricesWithoutVAT
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate))
		And Not DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
	CommonClientServer.SetFormItemProperty(Items, "VATTaxation", "Visible", Not WithoutChoiceOfTaxation);
	CommonClientServer.SetFormItemProperty(Items, "PriceIncludesVAT", "Visible", Not PricesWithoutVAT);
	
	SetParametersForSelectingPriceType();
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure GenerateHeadersThatDependOnBaseType(NewDocumentCreation)
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			If NewDocumentCreation Then
				Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và chuyển quyền sở hữu (tạo mới)';
							|ru = 'Акт о расхождениях после отгрузки товаров клиенту и перехода права собственности (создание)';
							|en = 'Sales dispute after goods shipment to customer and transfer of title to goods (create)'; fa = 'Sales dispute after goods shipment to customer and transfer of title to goods (create)';
							|it = 'Sales dispute after goods shipment to customer and transfer of title to goods (create)';
							|pl = 'Sales dispute after goods shipment to customer and transfer of title to goods (create)';
							|tr = 'Ürünlerin müşteri tarafında satış uyuşmazlığıyla karşılaşması ve mülkiyet hakkının devri (oluşturma)'");
			Else
				TitleTemplate1 = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và chuyển quyền sở hữu %1 ngày %2';
										|ru = 'Акт о расхождениях после отгрузки товаров клиенту и перехода права собственности %1 от %2';
										|en = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2'; fa = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
										|it = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
										|pl = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
										|tr = 'Ürünlerin müşteriye sevk edilmesinden sonra ve %1 mülkiyetinin %2 öğesine devredilmesinde tutarsızlık beyanı'");
				Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1,
					Object.Number,
					Object.Date);
				TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
					Object, Title, False, "DiscrepancyReportFollowingShipment");
			EndIf;
		Else
			If NewDocumentCreation Then
				Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng (tạo mới)';
							|ru = 'Акт о расхождениях после реализации (создание)';
							|en = 'Customer invoice dispute (create)'; fa = 'Customer invoice dispute (create)';
							|it = 'Atto sulle discrepanze dopo la vendita (creazione)';
							|pl = 'Protokół o odchyleniu po sprzedaży (tworzenie)';
							|tr = 'Satış sonrası tutarsızlık raporu (oluştur)'");
			Else
				TitleTemplate1 = NStr("vi = 'Biên bản chênh lệch sau khi bán hàng %1 ngày %2';
										|ru = 'Акт о расхождениях после реализации %1 от %2';
										|en = 'Customer invoice dispute %1 dated %2'; fa = 'Customer invoice dispute %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la vendita %1 di %2';
										|pl = 'Protokół o odchyleniu po sprzedaży %1 z dn. %2';
										|tr = '%1 Satışı sonrası %2 tarihli tutarsızlık raporu'");
				Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1,
					Object.Number,
					Object.Date);
				TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
					Object, Title, False, "DiscrepancyReportFollowingShipment");
			EndIf;
		EndIf;
		
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng theo đó thực hiện được thực hiện';
										|ru = 'Договор, в рамках которого оформлена реализация';
										|en = 'Contract under which the sale is documented'; fa = 'قراردادی که فروش تحت آن مستند می‌شود';
										|it = 'Contratto in base al quale è stata effettuata la vendita';
										|pl = 'Kontrakt, w ramach którego jest zarejestrowana sprzedaż';
										|tr = 'Satışın gerçekleştirildiği sözleşme'");
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If NewDocumentCreation Then
			Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và chuyển quyền sở hữu (tạo mới)';
						|ru = 'Акт о расхождениях после отгрузки товаров клиенту и до перехода права собственности (создание)';
						|en = 'Sales dispute after goods shipment to customer and before transfer of title to goods (create)'; fa = 'Sales dispute after goods shipment to customer and before transfer of title to goods (create)';
						|it = 'Sales dispute after goods shipment to customer and before transfer of title to goods (create)';
						|pl = 'Sales dispute after goods shipment to customer and before transfer of title to goods (create)';
						|tr = 'Ürünlerin müşteri tarafında satış uyuşmazlığıyla karşılaşması ve mülkiyetin devrinden önce tutarsızlıkların beyanı (oluşturma)'");
		Else
			TitleTemplate1 = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và trước khi chuyển quyền sở hữu %1 ngày %2';
									|ru = 'Акт о расхождениях после отгрузки товаров клиенту и до перехода права собственности %1 от %2';
									|en = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2'; fa = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
									|it = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
									|pl = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
									|tr = 'Ürünlerin müşteriye sevk edilmesinden sonra ve %1 mülkiyetinin %2 öğesine devredilmesinden öncesi tutarsızlık beyanı'");
			Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1,
				Object.Number,
				Object.Date);
			TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
				Object, Title, False, "DiscrepancyReportFollowingShipment");
		EndIf;
		
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà có lập chứng từ giao hàng cho khách';
										|ru = 'Договор, в рамках которого оформлена отгрузка товаров клиенту';
										|en = 'Contract under which the goods shipment to customer is registered'; fa = 'Contract under which the goods shipment to customer is registered';
										|it = 'Contract under which the goods shipment to customer is registered';
										|pl = 'Contract under which the goods shipment to customer is registered';
										|tr = 'Müşteriye ürün sevkiyatı düzenlediği sözleşme'");
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi trả lại hàng cho nhà cung cấp (tạo mới)';
					|ru = 'Акт о расхождениях после возврата товаров поставщику (создание)';
					|en = 'Discrepancy report following return of goods to vendor (create)'; fa = 'Discrepancy report following return of goods to vendor (create)';
					|it = 'L''atto sulle discrepanze dopo il reso delle merci al fornitore (Creazione)';
					|pl = 'Protokół o odchyleniu po zwrocie towarów do dostawcy (tworzenie)';
					|tr = 'Malların tedarikçiye iadesinden sonra tutarsızlık raporu (oluştur)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng theo đó hoàn trả';
										|ru = 'Договор, в рамках которого оформлен возврат';
										|en = 'Contract under which the return is recorded'; fa = 'قراردادی که برگشت تحت آن ثبت می‌شود';
										|it = 'Il contratto in base al quale è stato formalizzato il reso';
										|pl = 'Kontrakt, w ramach którego sporządzony jest zwrot';
										|tr = 'Para iadesinin yapıldığı sözleşme'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng từ kho cất giữ (tạo mới)';
					|ru = 'Акт о расхождениях после отгрузки товаров с хранения (создание)';
					|en = 'VMI pick-up discrepancy report (create)'; fa = 'VMI pick-up discrepancy report (create)';
					|it = 'L''atto sulle discrepanze dopo la spedizione delle merci dal deposito (Creazione)';
					|pl = 'Protokół o odchyleniu po wysyłce towarów z przechowywania (tworzenie)';
					|tr = 'Malların depodan sevkiyatından sonra tutarsızlık raporu (oluştur)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng là cơ sở lập chứng từ giao hàng';
										|ru = 'Договор, в рамках которого оформлена отгрузка';
										|en = 'Contract under which the shipment is documented'; fa = 'Contract under which the shipment is documented';
										|it = 'Contratto in base al quale è stata effettuata la spedizione';
										|pl = 'Kontrakt, w ramach którego jest sporządzona wysyłka';
										|tr = 'Sevkiyatın gerçekleştirildiği sözleşme'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao ký gửi (tạo mới)';
					|ru = 'Акт о расхождениях после передачи на комиссию (создание)';
					|en = 'Discrepancy report after consignment sales (create)'; fa = 'Discrepancy report after consignment sales (create)';
					|it = 'Atto sulle discrepanze dopo il trasferimento in commissione (creazione)';
					|pl = 'Protokół o odchyleniu po przekazaniu do komisu (tworzenie)';
					|tr = 'Konsinye satışlarından sonra tutarsızlık raporu (oluştur)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà có lập chứng từ chuyển giao';
										|ru = 'Договор, в рамках которого оформлена передача';
										|en = 'Contract under which transfer is registered'; fa = 'Contract under which transfer is registered';
										|it = 'Contratto in base al quale è stata effettuata la consegna';
										|pl = 'Umowa, na mocy której wykonywany jest transfer';
										|tr = 'Sevk işleminin gerçekleştirildiği sözleşme'");
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Title                  = Handler.TitleOfReportCreationForm();
		Items.Contract.ToolTip = Handler.ReportAgreementHint();
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
		
		Title = StrTemplate(
						NStr("vi = '%1 (tạo mới)';
							|ru = '%1 (создание)';
							|en = '%1 (create)'; fa = '%1 (create)';
							|it = '%1 (creazione)';
							|pl = '%1 (tworzenie)';
							|tr = '%1 (oluştur)'"),
						TollingSchemeClientServer.SynonymOfDocumentCertificateOfDiscrepanciesTransferToGiver());
		
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà có lập chứng từ chuyển giao';
										|ru = 'Договор, в рамках которого оформлена передача';
										|en = 'Contract under which transfer is registered'; fa = 'Contract under which transfer is registered';
										|it = 'Contratto in base al quale è stata effettuata la consegna';
										|pl = 'Umowa, na mocy której wykonywany jest transfer';
										|tr = 'Sevk işleminin gerçekleştirildiği sözleşme'");
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		Title = StrTemplate(
						NStr("vi = '%1 (tạo mới)';
							|ru = '%1 (создание)';
							|en = '%1 (create)'; fa = '%1 (create)';
							|it = '%1 (creazione)';
							|pl = '%1 (tworzenie)';
							|tr = '%1 (oluştur)'"),
						TollingSchemeClientServer.SynonymOfDocumentCertificateOfDiscrepanciesReturnOfRawMaterialsToGiver());
		
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà có lập chứng từ chuyển giao';
										|ru = 'Договор, в рамках которого оформлена передача';
										|en = 'Contract under which transfer is registered'; fa = 'Contract under which transfer is registered';
										|it = 'Contratto in base al quale è stata effettuata la consegna';
										|pl = 'Umowa, na mocy której wykonywany jest transfer';
										|tr = 'Sevk işleminin gerçekleştirildiği sözleşme'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingPriceType()
	
	If Not (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		) Then
		
		Return;
		
	EndIf;
	
	ParametersArray = New Array();
	ParametersArray.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	ParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
	
	Items.GoodsPriceKind.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	SelfServiceServer.GetUploadedProductsFromStorage(ThisForm, CachedValues ,GoodsAddressInStorage, True);
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfDocuments(ArrayOfDocuments, FillOptionParameter)
	
	FillingVariant = FillOptionParameter;
	DiscrepanciesServer.GenerateTableOfDocumentsOfBases(ThisForm, ArrayOfDocuments);
	FillInByBasis();
	DiscrepanciesClientServer.AvailabilityControl(ThisForm);
	DiscrepanciesServer.DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(ThisObject);
	
EndProcedure 

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation(TaxationOfVATSales = True, TaxationOfVATPurchases = True)
	
	If (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate))
		And TaxationOfVATSales Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Object.TypeOfBaseDocumentForNonConformanceCertificate) And TaxationOfVATPurchases Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInVATTaxationPurchases(Object);
		VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
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


&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtClient
Function CleaningOfVHFActionIsRequired()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		For Each TSRow In Object.Goods Do
			
			// Change the old value, Make an adjustment to the new one
			If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")
				And Object.DiscrepanciesPostingMethod <> PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments") Then
				
				If TSRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
					Or TSRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait")
					Or TSRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
					Return True;
				EndIf;
				
			EndIf;
			
			// Make an adjustment to the old value, Change the new value
			If DiscrepanciesPostingMethod <> PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")
				And Object.DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments") Then
				
				If TSRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off") Then
					Return True;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer") Then
		
		For Each TSRow In Object.Goods Do
			
			// Make an adjustment to the old value, Change the new value
			If DiscrepanciesPostingMethod <> PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")
				And Object.DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments") Then
				
				If TSRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
					Return True;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure AskQuestionAboutClearingActionColumn()
	
	QueryText = NStr("vi = 'Cột ""Cách xử lý chênh lệch"" của danh sách ""Hàng hóa"" bị xóa. Tiếp tục?';
					|ru = 'Колонка ""Как отработать расхождение"" списка ""Товары"" будет очищена. Продолжить?';
					|en = 'The ""Discrepancy treatment"" column of the ""Goods"" list will be cleared. Continue?'; fa = 'The ""Discrepancy treatment"" column of the ""Goods"" list will be cleared. Continue?';
					|it = 'The ""Discrepancy treatment"" column of the ""Goods"" list will be cleared. Continue?';
					|pl = 'The ""Discrepancy treatment"" column of the ""Goods"" list will be cleared. Continue?';
					|tr = 'Ürünler listesindeki ""Tutarsızlık nasıl çözülür"" sütunu temizlenecektir. Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("WayToReflectDiscrepanciesOnChangeEnd", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure WayToReflectDiscrepanciesOnChangeEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		DiscrepanciesPostingMethod = Object.DiscrepanciesPostingMethod;
		
		For Each TSRow In Object.Goods Do
			TSRow.Action = Undefined;
			TSRow.DiscrepancyTreatment = Undefined;
		EndDo;
		
		For Each TSRow In Object.SetOfSeries Do
			TSRow.Action = Undefined;
			TSRow.DiscrepancyTreatment = Undefined;
		EndDo;
		
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		Object.DiscrepanciesPostingMethod = DiscrepanciesPostingMethod;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenWarehouseSelectionForm()
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowID", CurrentRow.GetID());
	
	CallbackDescription = New CallbackDescription("OpenWarehouseSelectionFormCompletion",
														ThisObject,
														AdditionalParameters);
	
	OpenForm(
		"Catalog.Warehouses.ChoiceForm",
		ParametersStructure,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenWarehouseSelectionFormCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then 
		Return;
	EndIf;
	
	TSRow = Object.Goods.FindByID(AdditionalParameters.RowID);
	
	If TSRow = Undefined Then 
		Return;
	EndIf;
	
	TSRow.Warehouse = Result;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse", TSRow.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		TSRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

#EndRegion

&AtClient
Procedure ActionChoiceCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		Items.Goods.CurrentData.Action = Result.ActionWithDocument;
		Items.Goods.CurrentData.DiscrepancyTreatment = Result.DiscrepancyTreatment;
		
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Items.Goods,CachedValues,SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeAction(Command)

	DiscrepanciesClient.ChangeActionOfSelectedLines(
		Object,
		ThisObject,
		Object.TypeOfBaseDocumentForNonConformanceCertificate,
		ShowExplanation);

EndProcedure

&AtClient
Procedure ChangeActionOfSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InstallResult = DiscrepanciesClient.SetActionOptionForSelectedLines(
		ThisObject,
		Result.ActionWithShortageDocument,
		Result.ActionWithSurplusDocument,
		Result.ActionWithShortageGoods,
		Result.ActionWithSurplusGoods);
	
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
		Result.ActionWithSurplusDocument,
		Result.ActionWithShortageGoods,
		Result.ActionWithSurplusGoods);
	
EndProcedure

&AtClient
Procedure IssueDocumentsClick(Item)
	
	DiscrepanciesClient.IssueDocumentsClick(ThisObject);
	
EndProcedure

&AtServerNoContext
Function ManagerSDivision(Manager)
	
	Return SettingsValueCached.UserDivision(Manager);
	
EndFunction

&AtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToVendor") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
		
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToConsignor") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement");
		
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsShipmentToCustomer") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
		
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToToller2_5") Then
		
		Return TransferToToller.ContractBusinessTransaction();
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
		
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		
		Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
		  Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		
		Return TollingSchemeClientServer.ContractBusinessTransaction();
	Else
		
		Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
		
	EndIf;
	
EndFunction

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
EndProcedure
	
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
