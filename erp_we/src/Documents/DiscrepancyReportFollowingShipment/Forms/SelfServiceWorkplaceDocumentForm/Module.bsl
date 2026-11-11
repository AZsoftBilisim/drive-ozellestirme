#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.Status <> Enums.StatusesOfDiscrepancyReport.NotApproved Then
		ReadOnly = True;
	EndIf;
	
	SetConditionalAppearance();
	
	ToUseTermsOfSales  = GetFunctionalOption("ToUseTermsOfSales");

	If Not ValueIsFilled(Object.Ref) Then
		
		SelfServiceServer.SelfServiceFormsWhenCreatedOnServer(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;
		
		SetDocumentFormTitle(True);
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClearMarkIncomplete();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	SetDocumentFormTitle(False);
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.PrintDetails" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected,,"GoodsReceipt");
			Object.GoodsReceipt.Clear();
			CommonClientServer.SupplementTable(ValueSelected.GoodsReceipt, Object.GoodsReceipt);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.BaseDocumentChoiceForm" Then
		
		ProcessSelectionOfDocuments(ValueSelected, ChoiceSource.TransferOption);
		
	EndIf;
	
	ClearMarkIncomplete();
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;

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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingShipment));
	SetVisibilityOfSeriesElements();
	
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisForm);
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Object);
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	SetDocumentFormTitle(False);
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.Counterparty = ValueSelected;
	
	CounterpartyOnChangeServer();
	
	AvailabilityControlClientServer(ThisForm);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
	             New Structure("Partner,Terms",Object.Partner,Object.Terms),
	             ThisForm,,,, New CallbackDescription("AgreementOpeningSelectionFormCompletion", ThisObject),
	             FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DocumentsBasisSubmissionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If BasisDocuments.Count() = 1 Then
		ShowValue(, BasisDocuments[0].SaleOfGoodsAndServices);
	ElsIf BasisDocuments.Count() > 1 Then
		
		DocumentsList = New ValueList;
		For Each TableRow In BasisDocuments Do
			DocumentsList.Add(TableRow.SaleOfGoodsAndServices); 
		EndDo;
		
		OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
		DocumentsList,
		NStr("vi = 'Giao hàng và cung cấp dịch vụ (%DocumentsCount%)';
			|ru = 'Реализации товаров и услуг (%DocumentsCount%)';
			|en = 'Customer invoice (%DocumentsCount%)'; fa = 'Customer invoice (%DocumentsCount%)';
			|it = 'Vendita di merci e servizi (%DocumentsCount%)';
			|pl = 'Sprzedaż towarów i usług (%DocumentsCount%)';
			|tr = 'Mal ve hizmet faturası (%DocumentsCount%)'")
		),
		ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	 WhenChangingAgreementServer();
	 
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
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	DiscrepanciesClient.GoodsNumberOfPackagesOnChange(ThisForm, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	DiscrepanciesClient.GoodsPackageOnChange(ThisForm, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	CurrentData = Items.Goods.CurrentData;
	If Copy And CurrentData.FilledInBySale Then
		WarningText =  NStr("vi = 'Cấm sao chép dòng đã điền trên cơ sở chứng từ bán hàng';
							|ru = 'Запрещено копировать строки заполненные на основании реализации';
							|en = 'You cannot copy the lines filled in from the sales order'; fa = 'You cannot copy the lines filled in from the sales order';
							|it = 'È vietato copiare le righe compilate in base al realizzo';
							|pl = 'Zabronione jest kopiowanie wierszy wypełnionych na podstawie sprzedaży';
							|tr = 'Satışa dayalı olarak doldurulan satırların kopyalanması yasaktır'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	NewRow = Object.Goods.Add();
	NewRow.ForFillingInDescriptionText = True;
	SelfServiceClientServer.FillInDocumentBaseInLine(NewRow, BasisDocuments, True);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	DiscrepanciesClient.GoodsBeforeDeleteRow(CurrentData, Cancel, True);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Not ReadOnly
		And (Field = Items.GoodsBatchesIndicationStatus
			Or Field = Items.GoodsSeries
			Or (Field = Items.GoodsNumberOfPackages
				And ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentRow.BatchesIndicationStatus, SeriesSpecificationParameters))) Then
	
		OpenSelectionOfSeries();
		
	ElsIf Field = Items.GoodsDocumentBasis Then
		
		If ValueIsFilled(CurrentRow.SaleOfGoodsAndServices) And CurrentRow.FilledInBySale Then
			ShowValue(Undefined, CurrentRow.SaleOfGoodsAndServices);
		EndIf;
		
	ElsIf Field = Items.GoodsProductsSKU Or Field = Items.GoodsItemsType 
		Or Field = Items.GoodsProductsSKU Or Field = Items.GoodsCharacteristic 
		Or Field = Items.GoodsProducts Then
		
		OpenProductItemCard();
		
	ElsIf Field = Items.GoodsThereIsACustomerComment And Not ReadOnly Then
		
		CustomerCommentStartOfSelection();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsImplementationWhenChanged(Item)
	
	Var FoundRow;
	
	CurrentRow = Items.Goods.CurrentData;
	
	SelfServiceClient.ProductsImplementationWhenChanged(ThisForm, FoundRow);
	DiscrepanciesClientServer.FillInMultiTurnContainerDetailsInLine(CurrentRow, FoundRow);
	
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
	
	If Item.CurrentItem.Name = "GoodsAction" Then
		
		Items.GoodsAction.ChoiceList.Clear();
		If Not CurrentData.ThereAreDiscrepancies Then
			Return;
		EndIf;
		
		SelfServiceClient.FillInListOfSelectedActionsInCaseOfDivergence(
		                  Items.GoodsAction.ChoiceList,
		                  CurrentData.NumberOfDiscrepancyPackaging,
		                  Object.DiscrepanciesPostingMethod);
	
	ElsIf Item.CurrentItem.Name = "GoodsPassportNumber" Then
		Items.GoodsPassportNumber.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsCustomerCommentBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	CustomerCommentStartOfSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInBySalesExecute(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection            = Object.Goods;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInBySalesExecuteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInBySalesExecuteCompletion(Result, AdditionalParameters) Export 
	
	FillInBySales();
	
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
	
	FormParameters = SelfServiceClient.StructureOfBaseSelectionFormParameters();
	FillPropertyValues(FormParameters, Object);
	FormParameters.ContractIsNotRequired = Not Items.Contract.Visible;
	ListOfFoundationDocuments = New ValueList;
	For Each TableRow In BasisDocuments Do
		ListOfFoundationDocuments.Add(TableRow.SaleOfGoodsAndServices);
	EndDo;
	FormParameters.BasisDocuments = ListOfFoundationDocuments;
	FormParameters.TabularSectionIsNotEmpty = Object.Goods.Count() > 0;
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.BaseDocumentChoiceForm",
	             FormParameters, 
	             ThisForm);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.AdditionalExplanationWhenUploading = DiscrepanciesClient.AdditionalExplanationTextWhenDownloadingFromExternalFiles();
	ImportParameters.ImportPrices = True;
	ImportParameters.AmountsRecalculate = False;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
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
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa trong %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'biên bản tiếp nhận';
																			|ru = 'акт приемки';
																			|en = 'receiving note'; fa = 'receiving note';
																			|it = 'verbale di accettazione';
																			|pl = 'akt odbioru';
																			|tr = 'kabul raporu'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("ProductSegment", ProductSegment);
	FormParameters.Insert("TransferHeader", NStr("vi = 'Chuyển vào chứng từ';
												|ru = 'Перенести в документ';
												|en = 'Add to document'; fa = 'افزودن به سند';
												|it = 'Trasferire nel documento';
												|pl = 'Przenieś do dokumentu';
												|tr = 'Belgeye taşı'"));
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
	             SelfServiceClient.StructureOfParametersForSelection(FormParameters),
	             ThisForm,
	             UUID);
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
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
Procedure PurchasingOverdelivery(Command)
	
	SelfServiceClient.SetActionOption(ThisForm, 
	    PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery"));
	
EndProcedure

&AtClient
Procedure ReturnOverdelivered(Command)
	
	SelfServiceClient.SetActionOption(ThisForm, 
	    PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered"));
	
EndProcedure

&AtClient
Procedure CreatingGoodsReceiptsByOrderAreNotMoreRequired(Command)
	
	SelfServiceClient.SetActionOption(ThisForm, 
	    PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired"));
	
EndProcedure

&AtClient
Procedure AdditionalSupplyRequired(Command)
	
	SelfServiceClient.SetActionOption(ThisForm, 
	    PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired"))
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum, VATAmount, AmountIncludingVAT",
		"NumberOfPackages");
		
	If FormTable.CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
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
		NewRow["Action"]                   = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		NewRow.ThereIsAManagerComment      = False;
		NewRow.ThereIsACustomerComment        = False;
		NewRow.CustomerComment            = "";
		NewRow.ManagerComment          = "";
		NewRow.FilledInBySale         = False;
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");

		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		SelfServiceClientServer.FillInOrderAndWarehouseInLine(NewRow, BasisDocuments, True);
		
		DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
		
	EndIf;

EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

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
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đã điền theo chứng từ bán hàng>';
													|ru = '<заполнено по реализации>';
													|en = '<filled in by sale>'; fa = '<filled in by sale>';
													|it = '<compilato per realizzo>';
													|pl = '<wypełniono według sprzedaży>';
													|tr = '<satışlara göre dolduruldu>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Registration of the price when working with a multi-turn container

	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.PathToSelectionFieldIsToReturnReusableContainer	= "Object.Goods.ToReturnReusablePackage";
	InstallationParameters.PathToSelectionFieldRequiresDepositForContainer		= "Object.Goods.PackageDepositIsRequired";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	// Product Nomenclature, Product price, Product Showcands blank mark

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.ForFillingInDescriptionText");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
	
	// Tovaryrealization hyperlink

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
	
	// Item series

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);
	
	// Do not display the status of the series indication

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

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
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledInBySale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	If ValueIsFilled(Object.Terms) Then
		Query = New Query;
		Query.Text = "
		|SELECT ALLOWED
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
		
	Else
		
		Selection = SelfServiceServer.GetDefaultPartnerAgreement(
		                         Object.Partner,
		                         Enums.BusinessTransactions.EmptyRef());
		If Selection <> Undefined Then
			Object.Terms = Selection.Ref;
			WhenChangingAgreementAtServer(Selection);
		EndIf;
		
	EndIf;
	
	FillingVariant = "Variant1";
	
	AvailabilityManagementChangeOfAgreement(Selection);
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Object);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingShipment));
	SetVisibilityOfSeriesElements();
	
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisForm);
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	AvailabilityControlClientServer(ThisForm);

EndProcedure

&AtClient
Procedure CustomerCommentStartOfSelection()
	
	SelfServiceClient.CustomerCommentStartOfSelection(ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
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
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);

EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	DiscrepanciesServer.ProcessingSelectionOfSelectionOnServer(ThisForm, CachedValues, ValueSelected, True, True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControlClientServer(Form)
	
	InfluencingPropsAreAvailable = Form.BasisDocuments.Count() = 0;
	SelectionOfDocumentsIsNotAvailable = ValueIsFilled(Form.Object.Terms)
	                                    And ValueIsFilled(Form.Object.Partner)
	                                    And ValueIsFilled(Form.Object.Counterparty)
	                                    And ValueIsFilled(Form.Object.Organization)
	                                    And ?(Form.Items.Contract.Visible, ValueIsFilled(Form.Object.Contract), True)
	                                    And ValueIsFilled(Form.Object.Currency)
	                                    And ValueIsFilled(Form.Object.PriceIncludesVAT)
	                                    And ValueIsFilled(Form.Object.VATTaxation)
	                                    And ValueIsFilled(Form.Object.BusinessOperation);
	
	ProductSelectionIsAvailable = SelectionOfDocumentsIsNotAvailable And (Form.BasisDocuments.Count() > 0);
	
	Form.Items.Terms.Enabled = InfluencingPropsAreAvailable;
	Form.Items.Counterparty.Enabled = InfluencingPropsAreAvailable 
	                                        And (Not Form.CounterpartyIsFilledInFromTheAgreement)
	                                        And ValueIsFilled(Form.Object.Terms);
	Form.Items.Contract.Enabled    = InfluencingPropsAreAvailable And ValueIsFilled(Form.Object.Terms);
	
	Form.Items.ChangeBaseDocuments.Enabled             = SelectionOfDocumentsIsNotAvailable;
	Form.Items.ProductsToFillInAccordingToTheRealizationsOfTheGrounds.Enabled = ProductSelectionIsAvailable;
	Form.Items.GoodsImportFromExternalFile.Enabled         = ProductSelectionIsAvailable;
	Form.Items.GoodsOpenSelection.Enabled                    = ProductSelectionIsAvailable;
	Form.Items.GoodsAdd.Enabled                         = ProductSelectionIsAvailable;
	Form.Items.Goods.Enabled                                 = ProductSelectionIsAvailable;
	
	Form.Items.GoodsOpenGoodsProfile.Enabled = Form.Object.Goods.Count() > 0;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If ContractsAreUsed Then
		SelfServiceServer.ManagingContractFormElement(Object, Items.Contract,
	                                                       ContractsAreUsed, Object.BusinessOperation);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(SelectionResult)
	
	Object.Currency                 = SelectionResult.Currency;
	Object.Organization            = SelectionResult.Organization;
	Object.BusinessOperation  = SelectionResult.BusinessOperation;
	Object.PriceIncludesVAT        = SelectionResult.PriceIncludesVAT;
	AvailabilityManagementChangeOfAgreement(SelectionResult);
	FillInSalesVATTaxation();
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInBySales()
	
	DiscrepanciesServer.FillInByBasis(ThisForm, False);
	DiscrepanciesClientServer.FillInDetailsOfMultiTurnContainer(Object, BasisDocuments);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	SelfServiceServer.GetUploadedProductsFromStorage(ThisForm,
	                                                            CachedValues,
	                                                            GoodsAddressInStorage,
	                                                            True,
	                                                            False);
	
	AvailabilityControlClientServer(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfDocuments(ArrayOfDocuments, FillOptionParameter)

	FillingVariant = FillOptionParameter;
	DiscrepanciesServer.GenerateTableOfDocumentsOfBases(ThisForm, ArrayOfDocuments);
	FillInBySales();
	AvailabilityControlClientServer(ThisForm);

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

&AtServer
Procedure SetDocumentFormTitle(IsNewObject)
	
	If IsNewObject Then
		
		Title = NStr("vi = 'Biên bản tiếp nhận (tạo mới)';
					|ru = 'Акт приемки (создание)';
					|en = 'Receiving note (Create)'; fa = 'Receiving note (Create)';
					|it = 'Verbale di accettazione (creazione)';
					|pl = 'Akt odbioru (utworzenie)';
					|tr = 'Kabul raporu (oluştur)'");
		
	Else
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Biên bản tiếp nhận %1 ngày %2';
																				|ru = 'Акт приемки %1 от %2';
																				|en = 'Receiving note %1 from %2'; fa = 'Receiving note %1 from %2';
																				|it = 'Verbale di accettazione %1 del %2';
																				|pl = 'Akt odbioru %1 z dn. %2';
																				|tr = '%2 tarihli %1 kabul raporu'"),
		                                                                    Object.Number, Object.Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.Products) Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

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
	
	SelfServiceServer.ManagingCounterpartyFormElement(Object, Data, Items.Counterparty, CounterpartyIsFilledInFromTheAgreement);
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract,
	                                                       ContractsAreUsed, Object.BusinessOperation);
	DiscrepanciesServer.VATVisibilityManagement(ThisForm);
	DiscrepanciesClientServer.CalculateFormTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductsCustomerCommentBasementOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.ThereIsACustomerComment = Not IsBlankString(CurrentData.CustomerComment);
	
EndProcedure

&AtClient
Procedure AgreementOpeningSelectionFormCompletion(Result, AdditionalParameters) Export
	
	SelectionResult = Result;
	
	If SelectionResult <> Undefined And SelectionResult.Terms <> Object.Terms Then
		
		If Object.Goods.Count() > 0 Then
			
			AdditionalParameters.Insert("SelectionResult", SelectionResult);
			DescriptionOfNotificationQuestion = New CallbackDescription("QuestionAfterChoosingAgreement", ThisObject, AdditionalParameters);
			QueryText = NStr("vi = 'Đã thay đổi thỏa thuận, phần bảng Hàng hóa sẽ bị xóa. Tiếp tục?';
							|ru = 'Соглашение было изменено, табличная часть Товары будет очищена. Продолжить?';
							|en = 'The terms were changed. The Goods table will be cleared. Continue?'; fa = 'The terms were changed. The Goods table will be cleared. Continue?';
							|it = 'The terms were changed. The Goods table will be cleared. Continue?';
							|pl = 'The terms were changed. The Goods table will be cleared. Continue?';
							|tr = 'Anlaşma değiştirildi, Ürünler tablosu temizlenecek. Devam edilsin mi?'");
			ShowQueryBox(DescriptionOfNotificationQuestion, QueryText, QuestionDialogMode.YesNo);
			
		Else
			
			ProcessAgreementSelection(SelectionResult);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionAfterChoosingAgreement(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Object.Goods.Clear();
		Object.SetOfSeries.Clear();
		ProcessAgreementSelection(AdditionalParameters.SelectionResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAgreementSelection(SelectionResult)
	
	Object.Terms = SelectionResult.Terms;
	WhenChangingAgreementAtServer(SelectionResult);
	AvailabilityControlClientServer(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer()
	
	FillInSalesVATTaxation();
	AvailabilityControlClientServer(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
		
	EndIf;
	
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
