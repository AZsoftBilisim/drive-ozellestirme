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
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		SelfServiceServer.SelfServiceFormsWhenCreatedOnServer(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;
		
		Object.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
		Object.Priority = SettingsValueCached.GetDefaultPriority(Object.Priority);
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Returned_);
		SetDocumentTitle(True);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	FillInListOfWarehouseSelectionsInTabularPartOfForm();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	SetDocumentTitle(False);
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintDocumentRequestForRefund(Object.Ref);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	SetVisibilityOfSeriesElements();
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	SetDocumentTitle(False);
	
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
	
	If ChoiceSource.FormName = "CommonForm.SelectGoodsBySalesAndTransfers" Then
		
		ProcessingSelectionSelectionByImplementationServer(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheInscriptionTheTitleOfTheImplementationClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			SalesList,
			NStr("vi = 'Chứng từ bán hàng (%DocumentsCount%)';
				|ru = 'Документы продаж (%DocumentsCount%)';
				|en = 'Sales documents (%DocumentsCount%)'; fa = 'Sales documents (%DocumentsCount%)';
				|it = 'Documenti delle vendite (%DocumentsCount%)';
				|pl = 'Dokumenty sprzedaży (%DocumentsCount%)';
				|tr = 'Satış belgeleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectionResult = Undefined;

	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
	                                       New Structure("Partner,Terms",Object.Partner,Object.Terms),
	                                       ThisForm,,,, New CallbackDescription("TermsStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(Result, AdditionalParameters) Export
	
	SelectionResult = Result;
	
	If SelectionResult <> Undefined And SelectionResult.Terms <> Object.Terms Then
		
		If Object.ReturnedGoods.Count() > 0 Then
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("SelectionResult", SelectionResult);
			QueryText = NStr("vi = 'Đã thay đổi thỏa thuận, sẽ xóa phần bảng Hàng hóa bị trả lại. Tiếp tục?';
							|ru = 'Соглашение было изменено, табличная часть Возвращаемые товары будет очищена. Продолжить?';
							|en = 'The terms were changed. The Goods pending return table will be cleared. Continue?'; fa = 'The terms were changed. The Goods pending return table will be cleared. Continue?';
							|it = 'The terms were changed. The Goods pending return table will be cleared. Continue?';
							|pl = 'The terms were changed. The Goods pending return table will be cleared. Continue?';
							|tr = 'Anlaşma değiştirildi, İade Edilen Ürünler tablosu temizlenecek. Devam edilsin mi?'");
			ShowQueryBox(
				New CallbackDescription("AgreementStartOfSelectionIssueReturnedItemsWillBeClearedCompletion", ThisObject, AdditionalParameters),
				QueryText,
				QuestionDialogMode.YesNo);
			Return;
		EndIf;
		
		Object.Terms = SelectionResult.Terms;
		TermsOnChangeServer(SelectionResult);
		
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure AgreementStartOfSelectionIssueReturnedItemsWillBeClearedCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.ReturnedGoods.Clear();
		Object.ReturnedBatch.Clear();
	EndIf;
	
	Object.Terms = AdditionalParameters.SelectionResult.Terms;
	TermsOnChangeServer(AdditionalParameters.SelectionResult);
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected <> CurrentCounterpartyValue Then
		If Object.ReturnedGoods.Count() > 0 Then
			QueryText = NStr("vi = 'Đã thay đổi đối tác, sẽ xóa phần bảng Hàng hóa bị trả lại. Tiếp tục?';
							|ru = 'Контрагент был изменен, табличная часть Возвращаемые товары будет очищена. Продолжить?';
							|en = 'The counterparty was changed. The Goods pending return table will be cleared. Continue?'; fa = 'The counterparty was changed. The Goods pending return table will be cleared. Continue?';
							|it = 'The counterparty was changed. The Goods pending return table will be cleared. Continue?';
							|pl = 'The counterparty was changed. The Goods pending return table will be cleared. Continue?';
							|tr = 'Cari hesap değiştirildi, İade Edilen Ürünler tablosu temizlenecek. Devam edilsin mi?'");

			ShowQueryBox(New CallbackDescription("CounterpartyChoiceProcessingCompletion", ThisObject, New Structure("ValueSelected", ValueSelected)), QueryText,QuestionDialogMode.YesNo);
            Return;
		EndIf;
	EndIf;
	
	CounterpartyFragmentSelectionProcessing(ValueSelected);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReturnedGoods

&AtClient
Procedure ReturnedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ReturnedGoodsBatchesIndicationStatus
		Or Field = Items.ReturnedGoodsSeries Then
		
		OpenSelectionOfSeries();
		
	ElsIf Field = Items.ReturnedGoodsSKU Or Field = Items.ReturnedGoodsItemsType 
		Or Field = Items.ReturnedGoodsProducts Or Field = Items.ReturnedGoodsCharacteristic Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.Returned_));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisObject);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
			Item,CachedValues,SeriesSpecificationParameters.Returned_,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues,"Returned_");
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,CachedValues,SeriesSpecificationParameters.Returned_);
		
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisObject);

EndProcedure

&AtClient
Procedure ReturnedGoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.ReturnedGoods.CurrentData.RowCode = 0;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.Returned_, Copy);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.Returned_) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues,"Returned_");
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.Returned_);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.Returned_);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries();
EndProcedure

&AtClient
Procedure ReturnedGoodsSeriesAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		OpenSelectionOfSeries(Text);
	EndIf;
EndProcedure

&AtClient
Procedure ReturnedGoodsSeriesTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = New ValueList;
		ChoiceData.Add(Items.ReturnedGoods.CurrentData.Series);
		OpenSelectionOfSeries(Text);
	Else
		ValueSelected = ProductsClientServer.SelectedSeries();
		
		ValueSelected.Value            		 = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
		ValueSelected.CurrentRowID = Items.ReturnedGoods.CurrentData.GetID();
		
		ProductsClient.ProcessSeriesIndication(ThisForm,
													SeriesSpecificationParameters.Returned_,
													ValueSelected);
	EndIf;
EndProcedure

&AtClient
Procedure ReturnedGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfActions = New Structure;
	SelfServiceClientServer.AddReturnItemsToActionStructureWhenChangingNumberOfPackagesMain(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SpecifyReturnedSeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
EndProcedure

&AtClient
Procedure ToPickUpTheGoodsInImplementations(Command)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Partner",Object.Partner);
	PickingParameters.Insert("DocumentReturnPolicy",Object.Ref);
	PickingParameters.Insert("Currency", Object.Currency);
	PickingParameters.Insert("Date",?(ValueIsFilled(Object.Date), Object.Date, CommonClient.SessionDate()));
	PickingParameters.Insert("VATTaxation", Object.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT",Object.PriceIncludesVAT);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	PickingParameters.Insert("ReturnFromRetailCustomer", False);
	PickingParameters.Insert("CashRegisterReceipt", PredefinedValue("Document.CashRegisterReceipt.EmptyRef"));
	PickingParameters.Insert("ShowProducts_",True);
	PickingParameters.Insert("ShowContainers",False);
	
	OpenForm("CommonForm.SelectGoodsBySalesAndTransfers", PickingParameters, ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "ReturnedGoodsWarehouse");
	

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ReturnedGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ReturnedGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
	                                                                         "ReturnedGoodsCharacteristic",
	                                                                         "Object.ReturnedGoods.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, 
	                                                                 "ReturnedGoodsSeries", 
	                                                                 "Object.ReturnedGoods.BatchesIndicationStatus",
	                                                                 "Object.ReturnedGoods.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, 
	                                                                     "ReturnedGoodsBatchesIndicationStatus",
	                                                                     "Object.ReturnedGoods.BatchesIndicationStatus");

	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.ReturnedGoodsToControlQuality,
		Items.ReturnedGoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	Statuses = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers;
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.ItemsType", ItemsTypes.OperationService);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.NotAgreedUpon);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.IsRejected);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);

EndProcedure

#Region WhenChangingBankingDetailsOnServer

&AtServer
Procedure TermsOnChangeServer(SelectionResult)

	Object.Currency                 = SelectionResult.Currency;
	Object.Organization            = SelectionResult.Organization;
	ContractBusinessTransaction = SelectionResult.BusinessOperation;
	Object.BusinessOperation  = SalesServer.GetRefundTransactionForSale(SelectionResult.BusinessOperation);
	Object.PriceIncludesVAT        = SelectionResult.PriceIncludesVAT;

	FillInSalesVATTaxation();
	
	AvailabilityManagementChangeOfAgreement(SelectionResult);

	CalculateTotalsOfRefundRequest(ThisForm);
	CurrentCounterpartyValue = Object.Counterparty;
	SupplyOptions = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		,
		Not Object.ThisIsOrderAsInvoice);
		
	QualityControl.UpdateActionParameters(
		Documents.RequestForReturnOfGoodsFromCustomer,
		Object,
		CacheQualityControl);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract,
	                                                       ContractsAreUsed, ContractBusinessTransaction);
	
	QualityControl.UpdateActionParameters(
		Documents.RequestForReturnOfGoodsFromCustomer,
		Object,
		CacheQualityControl);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

#EndRegion

#Region ManagingAvailabilityOfFormDetails

&AtServer
Procedure AvailabilityManagementChangeOfAgreement(Data)
	
	SelfServiceServer.GenerateTextPresentationsOfDocumentFormFields(ThisForm);
	
	If Data = Undefined Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Counterparty", "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "PaymentMethod", "Enabled", False);
		Return;
	EndIf;
	
	ContractsAreUsed = Data.ContractsAreUsed;
	
	SelfServiceServer.ManagingCounterpartyFormElement(Object, Data, Items.Counterparty);
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract,
	                                                       ContractsAreUsed, ContractBusinessTransaction);
	SelfServiceServer.ManagingWarehouseFormElement(Object, Data, Items.Warehouse);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	Form.Items.ReturnedGoodsToPickUpTheGoodsInImplementations.Enabled = ValueIsFilled(Form.Object.Terms)
	                                                                          And ValueIsFilled(Form.Object.Counterparty);
	
	Form.Items.ReturnedGoodsOpenGoodsProfile.Enabled = Form.Object.ReturnedGoods.Count() > 0;

EndProcedure

#EndRegion

#Region GeneratingAndDisplayingInformationOnForm

&AtClientAtServerNoContext
Procedure CalculateTotalsOfRefundRequest(Form)
	
	CollectionOfReturnedProducts = Form.Object.ReturnedGoods;
	
	Form.AmountOfNonRefundableGoods = CollectionOfReturnedProducts.Total("VATAmount");
	Form.AmountOfReturnedItems = CollectionOfReturnedProducts.Total("AmountIncludingVAT");
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);

	If DisplayTotalAmountOfVAT Then
		
		Form.Items.GroupOfTheNDSPageNonRefundableProducts.CurrentPage   = Form.Items.PageChasozvonyaProducts;
		Form.Items.PageGroupTotalReturnedItems.CurrentPage = Form.Items.PageTotalChasozvonyaProducts;
		
	Else
		
		Form.Items.GroupOfTheNDSPageNonRefundableProducts.CurrentPage   = Form.Items.PageNoNasosnayaProducts;
		Form.Items.PageGroupTotalReturnedItems.CurrentPage = Form.Items.PageWithoutNasosnayaProducts;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInformationOnImplementations()
	
	SalesServer.UpdateInformationOnImplementationsInForm(
		SalesList,
		Object.DocumentSalesOfGoodsAndServices,
		TheInscriptionTheTitleOfTheImplementation,
		Items,
		Items.ReturnedGoodsDocumentSalesOfGoodsAndServices,
		Object.ReturnedGoods,
		"DocumentSalesOfGoodsAndServices");
	
EndProcedure

&AtServer
Procedure SetDocumentTitle(IsNewObject)
	
	If IsNewObject Then
		
		Title = NStr("vi = 'Giấy đề nghị trả hàng (tạo mới)';
					|ru = 'Заявка на возврат (создание)';
					|en = 'Return request (Create)'; fa = 'Return request (Create)';
					|it = 'Domanda di reso (creazione)';
					|pl = 'Wniosek o zwrot (utworzenie)';
					|tr = 'İade talebi (oluştur)'");
		
	Else
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giấy đề nghị trả hàng %1 ngày %2';
																				|ru = 'Заявка на возврат %1 от %2';
																				|en = 'Return request %1 from %2'; fa = 'Return request %1 from %2';
																				|it = 'Domanda di reso %1 del %2';
																				|pl = 'Wniosek o zwrot %1 z dn. %2';
																				|tr = '%2 tarihli %1 iadesi talebi'"),
		                                                                    Object.Number, Object.Date);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.ReturnedGoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.Returned_.UseItemsBatch;
	Items.ReturnItemsSpecifyTheSeries.Visible        = SeriesSpecificationParameters.Returned_.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "")
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters.Returned_,Text) Then
		CurDataId = Items.ReturnedGoods.CurrentData.GetID();
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;


		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters.Returned_, CurDataId, ThisForm);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object);
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters.Returned_,ParametersOfSeriesIndicationForm,StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues, TSName)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
		SeriesSpecificationParameters.Returned_, IDCurrentRow, CachedValues);
	
EndProcedure

#EndRegion

#Region ChangingCounterparty

&AtClient
Procedure CounterpartyChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
    
    ValueSelected = AdditionalParameters.ValueSelected;
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    Else
        Object.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
        Object.ReturnedGoods.Clear();
        Object.ReturnedBatch.Clear();
    EndIf;
    
    CounterpartyFragmentSelectionProcessing(ValueSelected);

EndProcedure

&AtClient
Procedure CounterpartyFragmentSelectionProcessing(Val ValueSelected)
    
    Object.Counterparty = ValueSelected;
    CurrentCounterpartyValue = Object.Counterparty;
    
    If ContractsAreUsed Then
        CounterpartyOnChangeServer();
    EndIf;
    AvailabilityControl(ThisObject);

EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.ReturnedGoods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not Object.Terms.IsEmpty() Then
		Query = New Query;
		Query.Text = "
		|SELECT
		|	TermsOfSale.ContractsAreUsed,
		|	TermsOfSale.Warehouse,
		|	TermsOfSale.PaymentMethod,
		|	TermsOfSale.Counterparty,
		|	&Partner,
		|	ISNULL(Warehouses.IsFolder, FALSE) AS ThisIsWarehouseGroup,
		|	TermsOfSale.ARAPObjectSettings,
		|	TermsOfSale.ProductSegment
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON TermsOfSale.Warehouse = Warehouses.Ref
		|WHERE
		|	TermsOfSale.Ref = &Terms";
		
		Query.SetParameter("Terms", Object.Terms);
		Query.SetParameter("Partner", Object.Partner);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(Object.BusinessOperation);
		
	Else
		
		Selection = SelfServiceServer.GetDefaultPartnerAgreement(
		                         Object.Partner,
		                         Enums.BusinessTransactions.EmptyRef());
		If Selection <> Undefined Then
			Object.Terms = Selection.Ref;
			TermsOnChangeServer(Selection);
			
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, Undefined);
			
		EndIf;
		
	EndIf;
	
	AvailabilityManagementChangeOfAgreement(Selection);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	DocumentCurrency = Object.Currency;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	SetVisibilityOfSeriesElements();
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);

	UpdateInformationOnImplementations();
	CalculateTotalsOfRefundRequest(ThisObject);
	AvailabilityControl(ThisObject);
	CurrentCounterpartyValue = Object.Counterparty;
	SupplyOptions = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		,
		Not Object.ThisIsOrderAsInvoice);

EndProcedure

&AtServer
Procedure ProcessingSelectionSelectionByImplementationServer(ValueSelected)
	
	ReturnValueStructure = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	TableOfGoods = ReturnValueStructure.Goods;
	
	AddedRows = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.ReturnedGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		CurrentRow.DocumentSalesOfGoodsAndServices = RowOfProduct.SaleTransferDocument;
		CurrentRow.Price               = CurrentRow.Sum / CurrentRow.NumberOfPackages;
		
		If ValueIsFilled(Object.Warehouse)
			And Not (ValueIsFilled(RowOfProduct.Warehouse) And WarehouseGroup_) Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		AddedRows.Add(CurrentRow);
		
	EndDo;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.ReturnedGoods);
	
	UpdateInformationOnImplementations();
	CalculateTotalsOfRefundRequest(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object)
	
	SelfServiceClientServer.AddReturnItemsToActionStructureWhenChangingNumberOfPackagesMain(StructureOfActions, Object);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	FillInSalesVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, Undefined);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	FillInSalesVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.ReturnedGoods, True);
	FillInListOfWarehouseSelectionsInTabularPartOfForm();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, Undefined);
	
	PrepareFillSetSeriesVisibility();
	
EndProcedure

&AtServer
Procedure FillInListOfWarehouseSelectionsInTabularPartOfForm()  
	If Not WarehouseGroup_ Then
		Return;
	EndIf;	
	
	Data = New Structure("Warehouse,ThisIsWarehouseGroup", Warehouse, WarehouseGroup_);
	SelfServiceServer.FillInWarehouseSelectionList(Data, Items.ReturnedGoodsWarehouse, True);
	
EndProcedure	

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction 

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
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
