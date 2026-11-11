
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetFunctionalOptionsOfForm();

	If Object.Ref.IsEmpty() Then
	
		If ValueIsFilled(Parameters.Organization) Then
			Object.Organization = Parameters.Organization;
		EndIf;
		
		OnReadCreateAtServer();
	
	EndIf; 
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	If Not Object.Ref.IsEmpty() Then
		ExportAttributeStructure = Object.Ref.GetObject().ExportAttributeStructure.Get();
	EndIf;
		
	If ExportAttributeStructure = Undefined Then
		ExportAttributeStructure = Parameters.CopyingValue.ExportAttributeStructure.Get();
		If ExportAttributeStructure = Undefined Then
			StructureOfApplicationDetails = Application_Details();
			ExportAttributeStructure = ImportApplicationLocalization.UpdateDataOfUploadAttributes(StructureOfApplicationDetails);
		EndIf;
	EndIf;
	
	ImportApplicationLocalization.UpdateStructureOfUploadAttributes(ExportAttributeStructure);
	
	If ValueIsFilled(Object.Date)
		And Object.Date < '20221001' Then
		ImportApplicationLocalization.FillInVFTSReports(ThisObject);
	EndIf;
	
	ImportApplicationLocalization.InitializeRegulatedReportForm(ThisObject);
	UsePartnersProducts = GetFunctionalOption("UsePartnersProducts");

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.ExportAttributeStructure = New ValueStorage(ExportAttributeStructure);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	FillInAdditionalProductAttributes();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	VATAccountingERP.SetTitleOfStateOfVATPaymentOnInvoice(
		Object.Ref,
		Items.InvoicePaymentStatus);
		
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	FormControl(ThisObject);
	
	Notify("Write_ApplicationForImportationOfGoods", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

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
	
	NotifyChoice(Object.Ref);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// Notification for the old BRO statform.
	If ValueIsFilled(Object.Date)
		And Object.Date < '20221001' Then
		ImportApplicationClientLocalization.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.ApplicationForImportationOfGoods.Form.FormPrintingAttributes" Then
		ProcessingSelectionOfPrintingAttributesOnServer(ValueSelected);
	ElsIf ChoiceSource.FormName = "Document.ApplicationForImportationOfGoods.Form.BasisChoiceForm" Then
		ProcessingAddLinesSelectionFromBatchDocument(ValueSelected);
	EndIf;
	
	VATAccountingERPClient.ProcessingChangesInStateOfVATPaymentOnInvoice(
		ChoiceSource,
		ValueSelected,
		Items.InvoicePaymentStatus);
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region VFTSStatformSubmission

&AtClient
Procedure CreateVFTSStatformClick(Item)
	
	
	Return; // Not required in UT. The visibility of the button is hidden.
	
EndProcedure

#EndRegion

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
		
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingSelectionOfCounterpartySOrganization("Organization", ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingSelectionOfCounterpartySOrganization("Counterparty", ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ContractChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.CounterpartyContracts") 
		Or TypeOf(ValueSelected) = Type("CatalogRef.LeaseContract")
		Then
		ProcessingSelectionOfCounterpartySOrganization("Contract", ValueSelected, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure DateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ItIsNecessaryToReFillItemsWhenDateChanges() Then
	
		ProcessingSelectionOfCounterpartySOrganization("Date", ValueSelected, StandardProcessing);
	
	EndIf;

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ItIsNecessaryToReFillItemsWhenDateChanges() Then 
		
		DefaultLanguageCode = CommonClient.DefaultLanguageCode();
		AnswersOptions = New ValueList;
		AnswersOptions.Add(True, NStr("vi = 'Điền lại';
										|ru = 'Перезаполнить';
										|en = 'Refill'; fa = 'پرکردن مجدد';
										|it = 'Ricompilare';
										|pl = 'Refill';
										|tr = 'Yeniden doldur'", DefaultLanguageCode));
		AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
										|ru = 'Не перезаполнять';
										|en = 'Do not refill'; fa = 'Do not refill';
										|it = 'Non ricompilare';
										|pl = 'Nie wypełniaj ponownie';
										|tr = 'Yeniden doldurma'", DefaultLanguageCode));
	
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Điền lại hàng hóa?';
										|ru = 'Перезаполнить товары?';
										|en = 'Do you want to refill the goods?'; fa = 'Do you want to refill the goods?';
										|it = 'Ricompilare merci?';
										|pl = 'Wypełnić ponownie towary?';
										|tr = 'Ürünler yeniden doldurulsun mu/değiştirilsin mi?'", DefaultLanguageCode), AnswersOptions);
		Return;
		
	EndIf;
	
	DateOfChangeOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	If Not Object.Patch Then
	
		CurrentData = Items.Goods.CurrentData;
		RowsCount = Object.Goods.Count();
	
		For ReverseIndex = 1 To RowsCount Do
			IndexOf = RowsCount - ReverseIndex;
		
			If Object.Goods[IndexOf].DocumentInflow = CurrentData.DocumentInflow Then
				Object.Goods.Delete(Object.Goods.IndexOf(Object.Goods[IndexOf]));
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsDocumentInflow Then
		
		RowData = Item.RowData(RowSelected);
		OpenDocument(RowData.DocumentInflow, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsVATTaxBaseOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
		CurrentData.VATTaxBase,
		VATAccountingERPClientServer.ValueOfVATRate(CurrentData.VATRate),
		False);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
		CurrentData.VATTaxBase,
		VATAccountingERPClientServer.ValueOfVATRate(CurrentData.VATRate),
		False);
	
EndProcedure

&AtClient
Procedure GoodsTaxBaseExciseTaxesOnChange(Item)

	CurrentData = Items.Goods.CurrentData;
	CalculateAmountOfExciseTaxes(CurrentData);
	
	ObjectData = New Structure(
			"LocalAccountingCurrency, CurrencyUSDollars, Currency",
			LocalAccountingCurrency, CurrencyUSDollars, CurrentData.Currency);
	CalculateAmountsInTabularPart(CurrentData.LineNumber, ObjectData);

EndProcedure

&AtClient
Procedure GoodsFixedExciseTaxRateOnChange(Item)

	CurrentData = Items.Goods.CurrentData;
	CalculateAmountOfExciseTaxes(CurrentData);
	
	ObjectData = New Structure(
			"LocalAccountingCurrency, CurrencyUSDollars, Currency",
			LocalAccountingCurrency, CurrencyUSDollars, CurrentData.Currency);
	CalculateAmountsInTabularPart(CurrentData.LineNumber, ObjectData);

EndProcedure

&AtClient
Procedure GoodsAdValoremExciseRateOnChange(Item)

	CurrentData = Items.Goods.CurrentData;
	CalculateAmountOfExciseTaxes(CurrentData);
	
	ObjectData = New Structure(
			"LocalAccountingCurrency, CurrencyUSDollars, Currency",
			LocalAccountingCurrency, CurrencyUSDollars, CurrentData.Currency);
	CalculateAmountsInTabularPart(CurrentData.LineNumber, ObjectData);

EndProcedure

&AtClient
Procedure GoodsExciseTaxAmountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	ObjectData = New Structure(
			"LocalAccountingCurrency, CurrencyUSDollars, Currency",
			LocalAccountingCurrency, CurrencyUSDollars, CurrentData.Currency);
	CalculateAmountsInTabularPart(CurrentData.LineNumber, ObjectData);
	
EndProcedure

&AtClient
Procedure GoodsFEACNCodeOnChange(Item)
	
	ProductsHSCodeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure GoodsDocumentInflowStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsDocumentInflowClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtServer
Procedure CalculateAmountsInTabularPartOnServer(LineOfATabularSection, ObjectData)
	
	// We will calculate the tax base in rubles based on the invoice value as of the date of registration.
	If ObjectData.Currency <> ObjectData.LocalAccountingCurrency Then
		RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(
			ObjectData.Currency,
			LineOfATabularSection.AccountingRecordDate,
			ObjectData.LocalAccountingCurrency);
		LineOfATabularSection.VATTaxBase = LineOfATabularSection.TaxInvoicedPrice
			* (RateStructure.CourseNumerator/RateStructure.CourseDenominator);
	Else
		LineOfATabularSection.VATTaxBase = LineOfATabularSection.TaxInvoicedPrice;
	EndIf;
	
	If Object.UseExcises Or UseExcisableGoods Then
		LineOfATabularSection.VATTaxBase =
			LineOfATabularSection.VATTaxBase + LineOfATabularSection.ExciseTaxAmount;
	EndIf;
	
	// We will calculate the amount of VAT according to the tax base and the rate
	LineOfATabularSection.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
		LineOfATabularSection.VATTaxBase,
		VATAccountingERPClientServer.ValueOfVATRate(LineOfATabularSection.VATRate),
		False);

	// We will calculate the statistical value in dollars from the tax base in rubles on the date of registration.
	If ObjectData.CurrencyUSDollars <> Catalogs.Currencies.EmptyRef() Then
		RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(ObjectData.CurrencyUSDollars, LineOfATabularSection.AccountingRecordDate, ObjectData.LocalAccountingCurrency);
		LineOfATabularSection.StatValueUSDollars = LineOfATabularSection.VATTaxBase * (RateStructure.CourseDenominator/RateStructure.CourseNumerator);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfPrintingAttributesOnServer(ValueSelected)

	StructureOfPrintingAttributes = GetFromTempStorage(ValueSelected.StorageAddressOfPrintDetails);
	Object.TransactionParties.Load(StructureOfPrintingAttributes.TransactionParties);
	Object.Specifications.Load(StructureOfPrintingAttributes.Specifications);
	Object.DocumentsInformation.Load(StructureOfPrintingAttributes.DocumentsInformation);

EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNetWeightKgOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CurrentData.UnitsVary Then
		CurrentData.QuantityByFEACN = CurrentData.NetWeightKg;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsProductOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not ValueIsFilled(CurrentData.Products) Then 
		CurrentData.Content = CurrentData.OwnGoods;	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure AddLines(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructurePartyDocuments = PartyDocuments();
	If StructurePartyDocuments.AddRowsManually Then 
		ShowInputNumber(New CallbackDescription("AddLineForRecyclingServices", ThisObject, New Structure("CurrentDocument, CurrentRowNumber", ?(CurrentRow = Undefined, Undefined, CurrentRow.DocumentInflow), ?(CurrentRow = Undefined, Undefined, CurrentRow.LineNumber))), 0, NStr("vi = 'Hãy chỉ ra chi phí';
																																																																						|ru = 'Укажите стоимость';
																																																																						|en = 'Specify the cost'; fa = 'Specify the cost';
																																																																						|it = 'Indicare costo';
																																																																						|pl = 'Podaj wartość';
																																																																						|tr = 'Maliyeti belirtin'", CommonClient.DefaultLanguageCode()));
	Else
	
		FormParameters = New Structure;
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Counterparty", Object.Counterparty);
		FormParameters.Insert("Contract", Object.Contract);
		FormParameters.Insert("Ref", Object.Ref);
	
		If CurrentRow <> Undefined Then
			FormParameters.Insert("CurrentDocument", CurrentRow.DocumentInflow);
		EndIf;
	
		FormParameters.Insert("ArrayOfSelectedDocuments", StructurePartyDocuments.PartyDocuments);
		
		PerformanceMonitorClient.TimeMeasurement(
			"Document.ApplicationForImportationOfGoods.Form.BasisChoiceForm.OpeningForm");

		OpenForm("Document.ApplicationForImportationOfGoods.Form.BasisChoiceForm", FormParameters, ThisObject,,,,,
				FormWindowOpeningMode.LockOwnerWindow);
				
	EndIf;
	
EndProcedure

&AtClient
Procedure AddLinesManually(Command)
	
	NewRow = Object.Goods.Add();
	NewRow.Currency = LocalAccountingCurrency;
	NewRow.ComplCurrency = LocalAccountingCurrency;
	NewRow.CurrencyUnitOfExciseTaxRate = LocalAccountingCurrency;

EndProcedure

&AtClient
Procedure UploadImportStatement(Command)
	ClearMessages();
	ImportApplicationClientLocalization.UploadImportStatement(ThisObject);
	Return; // Empty handler for UT
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure InvoicePaymentStatus(Command)
	
	VATAccountingERPClient.OpenInvoiceVATPaymentStateForm(Object.Ref, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseExcisableGoods = Not Object.UseExcises
		And ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	FillInAdditionalProductAttributes();
	SetVisibilityOfExciseTaxes();
	
	SetFunctionalOptionsOfForm();
	
	Update_VATRate();

	FormControl(ThisObject);
	StructureOfApplicationDetails = Application_Details();
	ExportAttributeStructure = ImportApplicationLocalization.UpdateDataOfUploadAttributes(StructureOfApplicationDetails);
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()

	If Object.Contract = Undefined Then 
		ContractDetails_ = New Structure("ARAPCurrency,Number,Date", Catalogs.Currencies.EmptyRef(), "", Date(1,1,1));
	Else
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "ARAPCurrency,Number,Date");
	EndIf;
	
	If ValueIsFilled(ContractDetails_.Number) Then
		Object.ContractNumber = ContractDetails_.Number;
	EndIf;
	
	If ValueIsFilled(ContractDetails_.Date) Then
		Object.ContractDate_ = ContractDetails_.Date;
	EndIf;
	
	If ValueIsFilled(ContractDetails_.ARAPCurrency) And Object.Currency <> ContractDetails_.ARAPCurrency Then
		
		Object.Currency = ContractDetails_.ARAPCurrency;
		FormControl(ThisObject);
		
		ObjectData = New Structure(
			"LocalAccountingCurrency, CurrencyUSDollars, Currency",
			LocalAccountingCurrency, CurrencyUSDollars, Object.Currency);
		
		For Each LineOfATabularSection In Object.Goods Do
			CalculateAmountsInTabularPartOnServer(LineOfATabularSection, ObjectData);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsHSCodeWhenChangedOnServer()
	
	FormControl(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	UseExcisableGoods = Not Object.UseExcises
		And ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	FillInAdditionalProductAttributes();
	SetVisibilityOfExciseTaxes();
	StructureOfApplicationDetails = Application_Details();
	ExportAttributeStructure = ImportApplicationLocalization.UpdateDataOfUploadAttributes(StructureOfApplicationDetails);
EndProcedure

#EndRegion

#Region FormBasementHyperlinks

&AtClient
Procedure PrintDetailsClick(Item)
	
	
EndProcedure


#EndRegion

#Region SendingFederalTaxService

&AtClient
Procedure SendItToSupervisoryAuthority(Command)
	
	
	Return; // Not required in TM
	
EndProcedure

&AtClient
Procedure CheckOnline(Command)
	
	
	Return; // Not required in TM
	
EndProcedure

#Region SendingPanelToRegulatoryAuthorities

&AtClient
Procedure ExportingParametersCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ExportAttributeStructure = Result;
		
		Modified = True;
				
	EndIf;

EndProcedure


#EndRegion

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// TaxInvoiceNumber
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxInvoiceNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TaxInvoiceNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Số';
													|ru = 'Номер';
													|en = 'Number'; fa = 'شماره';
													|it = 'Numero';
													|pl = 'Numer';
													|tr = 'Numara'"));

	// TaxInvoiceDate
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxInvoiceDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TaxInvoiceDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ngày';
													|ru = 'Дата';
													|en = 'Date'; fa = 'تاریخ';
													|it = 'Data';
													|pl = 'Data';
													|tr = 'Tarih'"));

	// the mark of the blank "quantity according to HS"
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityByFEACN.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.QuantityByFEACN");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UnitsVary");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// QuantityByFEACN 
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityByFEACN.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UnitsVary");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không điền>';
													|ru = '<не заполняется>';
													|en = '<not filled in>'; fa = '<not filled in>';
													|it = '<non compilare>';
													|pl = '<nie jest wypełniane>';
													|tr = '<doldurulmadı>.'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Measurement Unit code 
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFEACNCodeUnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UnitsVary");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// ExciseTaxesGroup 
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsGroupExciseTaxBase.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxBaseExcises.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseUnit.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsGroupFixedExciseTaxRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFixedExciseDuty.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCurrencyUnitOfExciseTaxRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAdValoremExciseRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsGroupExciseTaxAmount.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseTaxAmount.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCurrencyLocalExciseTax.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseExcises");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Cost
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxInvoicedPrice.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Patch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DocumentInflow");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFixedExciseDuty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfExcisableCategoryRates.FixedRate;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseExcises");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAdValoremExciseRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfExcisableCategoryRates.AdValoremRate;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseExcises");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxBaseExcises.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseTaxAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseExcises");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure	
	
&AtClientAtServerNoContext
Procedure UpdateTotals(Form)

	Object = Form.Object;
	If Form.ThisIsLocalizationOfRussianFederation Then
		Form.TotalVATTotals = Round(Object.Goods.Total("VATAmount"));
		Form.TotalExciseTax = Round(Object.Goods.Total("ExciseTaxAmount"));
	Else
		Form.TotalVATTotals = Object.Goods.Total("VATAmount");
		Form.TotalExciseTax = Object.Goods.Total("ExciseTaxAmount");
	EndIf;

EndProcedure

&AtServer
Procedure SetFunctionalOptionsOfForm()
	ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
	
	FOParameters = New Structure();
	FOParameters.Insert("Organization", ParentCompany);
	FOParameters.Insert("Period", Object.Date);
	
	SetFormFunctionalOptionParameters(FOParameters);
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	ThisIsLocalizationOfRussianFederation = GetFunctionalOption("LocalizationRFService");
	
	VisibilityCondition = ThisIsLocalizationOfRussianFederation
						And Not GetFunctionalOption("TradeManagement");
	Items.InvoicePaymentStatus.Visible = (ThisIsLocalizationOfRussianFederation And Not Object.Patch);
	
	RoundUpAmountOfLBSiExciseTaxesToWholeInStatementsAboutImportOfGoods = False;
	
	
	Items.RoundUpTotalAmountOfVATToRubles.Visible = RoundUpAmountOfLBSiExciseTaxesToWholeInStatementsAboutImportOfGoods;
	Items.RoundUpTotalAmountOfExciseTaxesToRubles.Visible = RoundUpAmountOfLBSiExciseTaxesToWholeInStatementsAboutImportOfGoods;
	
	CommonClientServer.SetFormItemProperty(Items,
		"GroupSubmissionPanel",
		"Visible",
		VisibilityCondition);
		
	CommonClientServer.SetFormItemProperty(Items,
		"PrintDetails",
		"Visible",
		ThisIsLocalizationOfRussianFederation);
		
	CommonClientServer.SetFormItemProperty(Items,
		"CheckSubmenu",
		"Visible",
		VisibilityCondition);
		
	CommonClientServer.SetFormItemProperty(Items,
		"SendItToSupervisoryAuthority",
		"Visible",
		VisibilityCondition);
		
	CommonClientServer.SetFormItemProperty(Items,
		"UploadImportStatement",
		"Visible",
		VisibilityCondition);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	UseExcisableGoods = Not Object.UseExcises
		And ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	Kilograms = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("166");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrencyUSDollars = Catalogs.Currencies.FindByCode("840");
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = LocalAccountingCurrency;
	EndIf;
	
	VATAccountingERP.SetTitleOfStateOfVATPaymentOnInvoice(
		Object.Ref,
		Items.InvoicePaymentStatus);

	SetFormItemsVisibility();
	FillInAdditionalProductAttributes();
	FormControl(ThisObject);
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Object	 = Form.Object;
	
	For Each String In Object.Goods Do
	
		If IsBlankString(String.OwnGoods) Then
			If ValueIsFilled(String.Content) Then
				String.OwnGoods = String.Content;
			Else
				String.OwnGoods = 	"" + String.Products
							+ ?(ValueIsFilled(String.Characteristic), ", " + String.Characteristic, "")
							+ ?(ValueIsFilled(String.Series), ", " + String.Series, "");
			EndIf;
		EndIf;
		
		UnitOfFuelTaxCode = GeneralPurposeTMServerCall.ObjectAttributeValue(String.FEACNCode, "UnitOfMeasure");
		If UnitOfFuelTaxCode = Form.Kilograms Then
			String.QuantityByFEACN = String.NetWeightKg;
		ElsIf UnitOfFuelTaxCode = String.UnitOfMeasure Then
			String.QuantityByFEACN = String.Count;
		EndIf;
		String.UnitsVary = UnitOfFuelTaxCode <> Form.Kilograms;
		String.ComplCurrency = Form.LocalAccountingCurrency;
		If ValueIsFilled(String.ExciseUnit) Then
			String.CurrencyUnitOfExciseTaxRate = StrTemplate("%1/%2", String.CurrencyOfExciseDuty, String.ExciseUnit);
		Else
			String.CurrencyUnitOfExciseTaxRate =
				?(ValueIsFilled(String.CurrencyOfExciseDuty), String.CurrencyOfExciseDuty, String.ComplCurrency);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function PartyDocuments()
	
	GoodsTable = Object.Goods.Unload(, "DocumentInflow");
	GoodsTable.GroupBy("DocumentInflow");
	ArrayOfReceiptDocuments = GoodsTable.UnloadColumn("DocumentInflow");
	AddRowsManually = GoodsTable.Count() > 0;
	
	For Each DocumentInflow In ArrayOfReceiptDocuments Do 
		//@skip-check bsl-legacy-check-string-literal
		If Not (AccessRight("Read", Metadata.Documents["VendorInvoiceServicesAndAssets"])
			And TypeOf(DocumentInflow) = Type("DocumentRef.VendorInvoiceServicesAndAssets")
			Or AccessRight("Read", Metadata.Documents["VendorInvoice"])
			And TypeOf(DocumentInflow) = Type("DocumentRef.VendorInvoice")
			And Common.ObjectAttributeValue(DocumentInflow, "Contract.ContractType") = Enums.ContractTypes.SubcontractingToTheEAEUCountries) Then 
			AddRowsManually = False;
			Break;
		EndIf;
	EndDo;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("PartyDocuments", ArrayOfReceiptDocuments);
	ReturnStructure.Insert("AddRowsManually", AddRowsManually);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure ProcessingAddLinesSelectionFromBatchDocument(DocumentsArray)
	
	For Each ArrayElement In DocumentsArray Do
		
		DateOfRemainingGoods = Undefined;
		If TypeOf(ArrayElement.Ref) = Type("DocumentRef.SigningOfLeaseContract") Then
			DateOfRemainingGoods = ?(ValueIsFilled(Object.Date), EndOfDay(Object.Date), EndOfDay(CurrentSessionDate()));
		EndIf;
		GoodsTable = Documents.ApplicationForImportationOfGoods.TableOfBalancesOfGoodsForProcessingApplicationsForImportOfGoods(ArrayElement.Ref, False, DateOfRemainingGoods);
		
		For Each RowOfProductsTable In GoodsTable Do
				
			If Not Object.UseExcises And Not UseExcisableGoods Then
				RowOfProductsTable.TaxBaseExcises = 0;
			EndIf;
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, RowOfProductsTable);
			
		EndDo;
		
		If Not ValueIsFilled(Object.Contract) Then
			Object.Contract = ArrayElement.Ref.Contract;
		EndIf;
		
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency = ArrayElement.Currency;
		EndIf;
		
		Modified = True;
	EndDo;
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateAmountOfExciseTaxes(CurrentRow)
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FixedExciseDuty = CurrentRow.FixedExciseDuty; 
	If ValueIsFilled(CurrentRow.CurrencyOfExciseDuty)
		And CurrentRow.CurrencyOfExciseDuty <> CurrentRow.ComplCurrency Then
		FixedExciseDuty = Round(CurrentRow.FixedExciseDuty
			* ConversionRatioToExciseCurrency(
				CurrentRow.CurrencyOfExciseDuty,
				CurrentRow.ComplCurrency,
				CurrentRow.AccountingRecordDate), 2);
	EndIf;
	
	CurrentRow.ExciseTaxAmount = CurrentRow.TaxBaseExcises * FixedExciseDuty 
									+ CurrentRow.TaxBaseExcises * CurrentRow.AdValoremExciseRate / 100;

EndProcedure

&AtServer
Procedure CalculateAmountsInTabularPart(TabularSectionRowNumber, ObjectData)
	
	CalculateAmountsInTabularPartOnServer(Object.Goods[TabularSectionRowNumber-1], ObjectData);
	
EndProcedure

&AtClient
Procedure OpenDocument(Ref, StandardProcessing)
	
	If ValueIsFilled(Ref) Then
		StandardProcessing = False;
		ShowValue(Undefined, Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfCounterpartySOrganization(Var_AttributeName, ValueSelected, StandardProcessing)
	
	If Object.Goods.Count() > 0 And ValueSelected <> Object[Var_AttributeName] Then
		
		StandardProcessing = False;
		
		AdditionalParameters = New Structure("AttributeName, ValueSelected", Var_AttributeName, ValueSelected);
		CallbackDescription = New CallbackDescription("ChoiceProcessingCompletion", ThisObject, AdditionalParameters);
		QueryText = NStr("vi = 'Sẽ xóa Tiếp tục?';
						|ru = 'Табличная часть документа будет очищена. Продолжить?';
						|en = 'Table of the document will be cleared. Continue? '; fa = 'Table of the document will be cleared. Continue? ';
						|it = 'La tabella del documento sarà cancellata. Continuare?';
						|pl = 'Sekcja tabelaryczna dokumentu zostanie wyczyszczona. Kontynuować?';
						|tr = 'Belgenin tablo kısmı temizlenecektir. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export

	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.Yes Then
		Object[AdditionalParameters.AttributeName] = AdditionalParameters.ValueSelected;
		Object.Goods.Clear();
		ProcessingOfContractModification();
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingOfContractModification()
	
	If Object.Contract = Undefined Then
		AgreementWhenModifiedOnServer();
	Else
		
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Organization,Counterparty");
	
		If ContractDetails_.Organization <> Object.Organization
			Or ContractDetails_.Counterparty <> Object.Counterparty Then
			Object.Contract = Undefined;
			AgreementWhenModifiedOnServer();
		EndIf;
		
	EndIf;
	
	UseExcisableGoods = Not Object.UseExcises
		And ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	SetVisibilityOfExciseTaxes();
	
EndProcedure

&AtServer
Procedure AddLineForRecyclingServices(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentRowNumber = ?(AdditionalParameters.CurrentRowNumber = Undefined, 1, AdditionalParameters.CurrentRowNumber);
	
	If Result > 0 Then
		CostOfServices = Object.Goods[CurrentRowNumber-1].TaxInvoicedPrice;
		
		If Result < CostOfServices Then
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, Object.Goods[CurrentRowNumber-1]);
			NewRow.TaxInvoicedPrice = Result;
		
			Object.Goods[CurrentRowNumber-1].TaxInvoicedPrice = CostOfServices - Result;
			
			ObjectData = New Structure(
				"LocalAccountingCurrency, CurrencyUSDollars, Currency",
				LocalAccountingCurrency, CurrencyUSDollars, Object.Currency);
		
			CalculateAmountsInTabularPartOnServer(Object.Goods[CurrentRowNumber-1], ObjectData);
			CalculateAmountsInTabularPartOnServer(NewRow, ObjectData);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckUpload(Command)
	ImportApplicationClientLocalization.CheckUpload(ThisObject);
	Return; // The TM is not required
	
EndProcedure

&AtClient
Procedure ProductsInventoryLocationAttributeAnalysisClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsInventoryOwnerAttributeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsPurchaseForActivityClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtServer
Procedure Update_VATRate()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	For Each String In Object.Goods Do
		String.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
			String.VATTaxBase,
			VATAccountingERPClientServer.ValueOfVATRate(String.VATRate),
			False);
	EndDo;
	
EndProcedure
&AtServer
Function Application_Details()
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Ref", 						Object.Ref);
	AttributesStructure1.Insert("Date", 						Object.Date);
	AttributesStructure1.Insert("Organization", 				Object.Organization);
	AttributesStructure1.Insert("ExportAttributeStructure", ExportAttributeStructure);
	
	Return AttributesStructure1;
	
EndFunction
&AtServer
Procedure FillInAdditionalProductAttributes()
	
	If UseExcisableGoods Then
		ExcisableGoodsAccounting.FillInAdditionalSignsOfItemsInImportStatement(Object);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfExciseTaxes()
	
	CommonClientServer.SetFormItemProperty(Items,
		"TotalTotalExciseTax",
		"Visible",
		Object.UseExcises Or UseExcisableGoods);
	
	CommonClientServer.SetFormItemProperty(Items,
		"ProductsGroupExciseTaxes",
		"Visible",
		Object.UseExcises Or UseExcisableGoods);
	
	CommonClientServer.SetFormItemProperty(Items,
		"GoodsGroupExciseTaxBase",
		"Visible",
		Object.UseExcises Or UseExcisableGoods);
	
EndProcedure

&AtServerNoContext
Function ConversionRatioToExciseCurrency(CurrencyOfExciseDuty, BaseCurrency, Period)
	
	RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfExciseDuty, Period, BaseCurrency);
	ConversionFactor_ = RateStructure.CourseNumerator / RateStructure.CourseDenominator;
	
	Return ConversionFactor_;
	
EndFunction

#Region SendingPanelToRegulatoryAuthorities

&AtClient
Procedure UpdateSubmission(Command)
	ImportApplicationClientLocalization.UpdateSubmission(ThisObject);
	Return; // Not required in TM
	
EndProcedure

&AtClient
Procedure HyperlinkProtocolClick(Item)
	ImportApplicationClientLocalization.HyperlinkProtocolClick(ThisObject);
	Return; // Not required in TM
	
EndProcedure

&AtClient
Procedure SendUnsentNotification(Command)
	ImportApplicationClientLocalization.SendUnsentNotification(ThisObject);
	Return; // Not required in TM
	
EndProcedure

&AtClient
Procedure StagesOfSendingClick(Item)
	ImportApplicationClientLocalization.StagesOfSendingClick(ThisObject);
	Return; // Not required in TM
	
EndProcedure

&AtClient
Procedure CriticalErrorsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ImportApplicationClientLocalization.CriticalErrorsURLProcessing(ThisObject, StandardProcessing);
	Return; // Not required in TM
	
EndProcedure

&AtServer
Function ItIsNecessaryToReFillItemsWhenDateChanges()
	
	ReFillProducts = False;
	For Each LineProducts_ In Object.Goods Do 
		If TypeOf(LineProducts_.DocumentInflow) = Type("DocumentRef.SigningOfLeaseContract") Then
			ReFillProducts = True;
			Break;
		EndIf;
	EndDo;
	Return ReFillProducts;
	
EndFunction

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	ReFillProducts = False;
	
	If QuestionResult = True Then
		ReFillProducts = True;
	EndIf;
	
	If ReFillProducts Then 
		RefillItemsWhenDateChanges();
	EndIf;
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure RefillItemsWhenDateChanges()
	
	ReceiptDocuments = Object.Goods.Unload(, "DocumentInflow, Currency");
	ReceiptDocuments.GroupBy("DocumentInflow, Currency");
	ReceiptDocuments.Columns.Add("Ref");
	For Each TableRow In ReceiptDocuments Do 
		TableRow.Ref = TableRow.DocumentInflow;
	EndDo;
	
	Object.Goods.Clear();
	ProcessingAddLinesSelectionFromBatchDocument(ReceiptDocuments); 
	FormControl(ThisObject);
	
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
