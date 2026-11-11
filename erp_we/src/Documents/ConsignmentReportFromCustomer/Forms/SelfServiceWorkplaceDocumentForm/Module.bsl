#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

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
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	If Object.Ref.IsEmpty() Then
		
		SelfServiceServer.SelfServiceFormsWhenCreatedOnServer(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;

		OnReadCreateAtServer();
		SetDocumentTitle(True);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.TeamGroupStandard);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintDocumentCommissionAgentSReport(Object.Ref);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If CurrentObject.Posted Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	OnReadCreateAtServer();
	SetDocumentTitle(False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "CommonForm.SelectByGoodsTransferredToCommissionAgent" Then
		
		GetProductsFromStorage(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	SetDocumentTitle(False);
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not CheckFilling() Then
	
		Cancel = True;
	Else
		ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.Terms.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra thỏa thuận';
												|ru = 'Не указано соглашение';
												|en = 'Agreement is not specified'; fa = 'Agreement is not specified';
												|it = 'L''accordo non è specificato';
												|pl = 'Nie określono żadnej umowy';
												|tr = 'Anlaşma belirtilmedi'"),
		                                                  ,
		                                                  "Object.Terms",
		                                                  ,
		                                                  Cancel);
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		BeforeWriteAtClientServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("Partner",Object.Partner);
	FormParameters.Insert("Terms",Object.Terms);
	FormParameters.Insert("BusinessOperation",PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	
	SelectionResult = Undefined;

	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
	                                       FormParameters,
	                                       ThisForm,,,, New CallbackDescription("ConventionStartOfSelectionAfterSelection", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConventionStartOfSelectionAfterSelection(Result, AdditionalParameters) Export
    
    SelectionResult = Result;
    If SelectionResult <> Undefined And SelectionResult.Terms <> Object.Terms Then
        
        If Object.Goods.Count() > 0 Then
            QueryText = NStr("vi = 'Đã thay đổi thỏa thuận, phần bảng Hàng hóa sẽ bị xóa. Tiếp tục?';
							|ru = 'Соглашение было изменено, табличная часть Товары будет очищена. Продолжить?';
							|en = 'The terms were changed. The Goods table will be cleared. Continue?'; fa = 'The terms were changed. The Goods table will be cleared. Continue?';
							|it = 'The terms were changed. The Goods table will be cleared. Continue?';
							|pl = 'The terms were changed. The Goods table will be cleared. Continue?';
							|tr = 'Anlaşma değiştirildi, Ürünler tablosu temizlenecek. Devam edilsin mi?'");
            Response = Undefined;
            
            ShowQueryBox(New CallbackDescription("TermsStartChoiceCompletion", ThisObject, New Structure("SelectionResult", SelectionResult)), QueryText,QuestionDialogMode.YesNo);
            Return;
        EndIf;
        
        AgreementStartSelectionFragment(SelectionResult);
        
        
    EndIf;

EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectionResult = AdditionalParameters.SelectionResult;
    
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    Else
        Object.Goods.Clear();
    EndIf;
    
    AgreementStartSelectionFragment(SelectionResult);

EndProcedure

&AtClient
Procedure AgreementStartSelectionFragment(Val SelectionResult)
    
    Object.Terms = SelectionResult.Terms;
    TermsOnChangeServer(SelectionResult);

EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer()
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "GoodsProducts" 
		Or Field.Name = "GoodsCharacteristic"
		Or Field.Name = "GoodsSKU" Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	ConsignmentSalesClient.CommissionAgentSReportGoodsPackagingWhenChanged(Object, CurrentRow, 
		ToUseTermsOfSales, CachedValues);
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	ConsignmentSalesClient.CommissionAgentSReportGoodsNumberOfPackagesWhenChanged(Object, CurrentRow, CachedValues);

	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsSellingPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ConsignmentSalesClient.CommissionAgentSReportProductsSalePriceWhenChanged(CurrentRow, CachedValues);

	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));

EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	AddressOfPaymentsInTheStorage = PutProductsInStorage(
		Object.Goods,
		UUID);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("Date", Object.EndOfPeriod);
	PickingParameters.Insert("ByPhysicalCountResults", Object.ByPhysicalCountResults);
	PickingParameters.Insert("HideSelection", True);
	
	OpenForm(
		"CommonForm.SelectByGoodsTransferredToCommissionAgent",
		PickingParameters, 
	ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	Cancel = False;
	
	If Object.Terms.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra thỏa thuận';
												|ru = 'Не указано соглашение';
												|en = 'Agreement is not specified'; fa = 'Agreement is not specified';
												|it = 'L''accordo non è specificato';
												|pl = 'Nie określono żadnej umowy';
												|tr = 'Anlaşma belirtilmedi'"),
		                                                  ,
		                                                  "Object.Terms",
		                                                  ,
		                                                  Cancel);
		Return;
	EndIf;
	
	Write();
	Close();
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
		
	EndIf;
	
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

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

EndProcedure

#Region WhenChangingBankingDetailsOnServer

&AtServer
Procedure TermsOnChangeServer(Data)
	
	Object.Organization = Data.Organization;
		
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInTermsOfSalesUnderAgreement();
	ValueToFormAttribute(DocumentObject, "Object");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Terms");
	
	AvailabilityManagementChangeOfAgreement(Data);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	DocumentCurrency = Object.Currency;
	
	SelfServiceClientServer.CalculateRewardAmount(Object);
	FormItemsManagement();
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm, False);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract, ContractsAreUsed);
	
EndProcedure

#EndRegion

#Region ManagingAvailabilityOfFormDetails

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ConsignmentReportFromCustomer.FillInNamesOfBusinessTransactionDetails(
		Object.CommissionFeeCalculationMethod,
		ArrayOfAllProps, 
		ArrayOfOperationDetails,
		True);
	CashServer.SetAvailabilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
EndProcedure

&AtServer
Procedure AvailabilityManagementChangeOfAgreement(Data)
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsSelectionByStock",
	                                                               "Enabled", ValueIsFilled(Object.Terms));
	SelfServiceServer.GenerateTextPresentationsOfDocumentFormFields(ThisForm);
	
	If Data = Undefined Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", 
		                                                               "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Counterparty",
		                                                               "Enabled", False);
		Return;
	EndIf;
	
	ContractsAreUsed = Data.ContractsAreUsed;
	
	SelfServiceServer.ManagingCounterpartyFormElement(Object, Data, Items.Counterparty);
	SelfServiceServer.ManagingContractFormElement(Object, 
	                                                       Items.Contract,
	                                                       ContractsAreUsed, 
	                                                       Enums.BusinessTransactions.TransferToCommissionAgent);
	
EndProcedure

#EndRegion

#Region GeneratingAndDisplayingInformationOnForm

&AtServer
Procedure SetDocumentTitle(IsNewObject)
	
	If IsNewObject Then
		
		Title = NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi (tạo mới)';
					|ru = 'Отчет комиссионера (создание)';
					|en = 'Consignment issue notification (Create)'; fa = 'Consignment issue notification (Create)';
					|it = 'Report del commissionario (creazione)';
					|pl = 'Raport komisanta (utworzenie)';
					|tr = 'Konsinye raporu (oluştur)'");
		
	Else
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi %1 ngày %2';
																				|ru = 'Отчет комиссионера %1 от %2';
																				|en = 'Consignment issue notification %1 dated %2'; fa = 'Consignment issue notification %1 dated %2';
																				|it = 'Report del commissionario %1 del %2';
																				|pl = 'Raport komisanta %1 z dn. %2';
																				|tr = '%2tarihli %1konsinye raporu'"), Object.Number, Object.Date);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfCommissionAgentSReport(Form, CalculateDocumentData = True)
	
	If CalculateDocumentData Then
		SelfServiceClientServer.CalculateRewardAmount(Form.Object);
	EndIf;
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
	If Form.Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Form.Items.CommissionAmount.Visible      = False;
		Form.Items.RemunerationPercentage.Visible    = False;
		Form.Items.CaptionWithholdReward.Visible = False;
	Else
		Form.Items.CommissionAmount.Visible      = True;
		Form.Items.RemunerationPercentage.Visible    = True;
		Form.Items.CaptionWithholdReward.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, CCDNumber, Count, QuantityByGBRN"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Procedure GetProductsFromStorage(GoodsAddressInStorage)
	
	Var CachedValues;
	
	SelectedGoods = GetFromTempStorage(GoodsAddressInStorage);
	AddedRows = New Array;
	
	// Delete the lines that have been unchecked in the selection
	LinesToDelete = New Array;
	For Each RowGoods In Object.Goods Do
		
		FilterParameters = New Structure("Products, Characteristic", RowGoods.Products, RowGoods.Characteristic);
		FoundRows = SelectedGoods.FindRows(FilterParameters);
		If FoundRows.Count() = 0 Then
			LinesToDelete.Add(RowGoods);
		EndIf;
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		Object.Goods.Delete(RowToDelete);
	EndDo;
	
	For Each SelectedProductLine In SelectedGoods Do
		FilterParameters = New Structure("Products, Characteristic",
		                                  SelectedProductLine.Products,
		                                  SelectedProductLine.Characteristic);
		FoundRows = Object.Goods.FindRows(FilterParameters);
		If FoundRows.Count() = 0 Then
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, SelectedProductLine);
			AddedRows.Add(NewRow);
		EndIf;
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	
	EnterprisePricesFillingServer.FillInPrices(
	Object.Goods, // Table part
	, // Array of rows or selection structure
	FillParameters ,
	New Structure( // The structure of the action with the changed strings
		"RecalculateAmount, RecalculateAmountWithVAT, RecalculateVATAmount",
		"NumberOfPackages", StructureOfRecalculationOfAmount, StructureOfRecalculationOfAmount));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateSaleAmountByAmountWithVAT");
	StructureOfActions.Insert("RecalculateSalePriceBySaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
			
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	ToUseTermsOfSales  = GetFunctionalOption("ToUseTermsOfSales");
	UsePaymentSchedules         = GetFunctionalOption("UsePaymentSchedules");
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	
	If Not Object.Terms.IsEmpty() Then
		Query = New Query;
		Query.Text = "
		|SELECT
		|	TermsOfSale.ContractsAreUsed,
		|	TermsOfSale.PaymentMethod,
		|	TermsOfSale.Counterparty,
		|	&Partner,
		|	TermsOfSale.ARAPObjectSettings,
		|	TermsOfSale.ProductSegment,
		|	TermsOfSale.BusinessOperation
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|WHERE
		|	TermsOfSale.Ref = &Terms";
		
		Query.SetParameter("Terms", Object.Terms);
		Query.SetParameter("Partner", Object.Partner);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
	Else
		
		Selection = SelfServiceServer.GetDefaultPartnerAgreement(Object.Partner, Enums.BusinessTransactions.TransferToCommissionAgent);
		If Selection <> Undefined Then
			Object.Terms = Selection.Ref;
			TermsOnChangeServer(Selection);
			Return;
		EndIf;
		
	EndIf;
	
	AvailabilityManagementChangeOfAgreement(Selection);
	
	DocumentCurrency = Object.Currency;
	FormItemsManagement();
	VATPercentage = PriceManagementSystemClientServer.GetVATRateAsNumber(Object.VATRateOfRemuneration);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm, False);

EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
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
