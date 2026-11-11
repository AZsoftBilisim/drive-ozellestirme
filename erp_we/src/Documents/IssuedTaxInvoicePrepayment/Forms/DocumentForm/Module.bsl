
#Region Variables

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues; 

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	UseSalesCommission = GetFunctionalOption("UseSalesCommission");
	UseAgentServiceSale = GetFunctionalOption("UseAgentServiceSale");
	
	VATAccountingERPInternal.ConfigureJointSelectionOfContractorsOrganizations(Items.Counterparty);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If Cancel Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Chưa điền trường ""Ngày phát hành""';
						|ru = 'Поле ""Дата выставления"" не заполнено';
						|en = 'The ""Issue date"" field is not filled in'; fa = 'The ""Issue date"" field is not filled in';
						|it = 'Il campo ""Data di fatturazione"" non è compilato';
						|pl = 'Pole ""Data wystawienia"" nie jest wypełnione';
						|tr = '""Tedarik tarihi"" alanı doldurulmamış'");
	
	If Issued And Not ValueIsFilled(Object.IssueDate) Then
		CommonClient.MessageToUser(MessageText,,"IssueDate","Object",Cancel);
	ElsIf Not Issued Then
		Object.IssueDate = '00010101';
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateInformationOnInvoiceBasis();
	FillInServiceDetailsForProductRange();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeClient();
	
EndProcedure

&AtClient
Procedure DateWhenCorrectedWhenChanged(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();

EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure DocumentBasisOnChange(Item)
	
	AvailabilityControl(ThisObject, Issued);
	
	If ValueIsFilled(Object.DocumentBasis) Then
		TheseGrounds = GetBaseDataOnServer(Object.DocumentBasis);
		Notification = New CallbackDescription("DocumentBasisOnChangeCompletion", ThisObject, New Structure("TheseGrounds", TheseGrounds));
		ShowQueryBox(Notification, NStr("vi = 'Điền lại dữ liệu về chứng từ thanh toán?';
										|ru = 'Перезаполнить данные о платежно-расчетном документе?';
										|en = 'Refill AR/AP document data?'; fa = 'Refill AR/AP document data?';
										|it = 'Reinserire i dati di fatturazione?';
										|pl = 'Wypełnić ponownie dane o płatniczo-rozliczeniowym dokumencie?';
										|tr = 'Ödeme belgesinin ayrıntıları yeniden doldurulsun mu?'"), QuestionDialogMode.YesNo);
	EndIf; 
	
EndProcedure

&AtClient
Procedure IssuedOnChange(Item)
	
	Modified = True;
	
	AvailabilityControl(ThisObject, Issued);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure PatchOnChange(Item)
	
	If Not Object.Patch Then
		
		Object.Number = "";
		Object.CorrectionNumber = "";
		
		ClearFoundationDocuments();
		
	Else
		
		UpdateInformationOnInvoiceBasis();
		
	EndIf;
	
	AvailabilityControl(ThisObject, Issued);
	
EndProcedure

&AtClient
Procedure TextInvoiceBaseURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "OpenOriginalInvoices" Then
		StandardProcessing = False;
		OpenInvoice();
	ElsIf Var_URL = "BaseInvoiceSelection" Then
		StandardProcessing = False;
		InvoiceSelection();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrepayments

&AtClient
Procedure PrepaymentsVATRateOnChange(Item)

	CurrentRow = Items.Prepayments.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure PrepaymentsSumOnChange(Item)
	
	CurrentRow = Items.Prepayments.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure PrepaymentsOnActivateCell(Item)
	
	CurrentData = Items.Prepayments.CurrentData;
	If Item.CurrentItem = Undefined Or CurrentData = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "PrepaymentsInventoryType" Then
		ChoiceList = InventoryTypeSelectionList(CurrentData.Products);
		Items.PrepaymentsInventoryType.ChoiceList.LoadValues(ChoiceList.UnloadValues()); 
	EndIf;
	
EndProcedure

&AtClient
Procedure PrepaymentsProductsOnChange(Item)
	
	CurrentRow = Items.Prepayments.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ChoiceList = InventoryTypeSelectionList(CurrentRow.Products);
	If ChoiceList.FindByValue(CurrentRow.InventoryType) = Undefined Then
		CurrentRow.InventoryType = ChoiceList[0].Value;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInOnTheCustomerSOrder(Command)
	
	CallbackDescription = New CallbackDescription("DistributeAdvancesOnGoods", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("PaymentDocument", Object.DocumentBasis);
	OpenForm("Document.IssuedTaxInvoicePrepayment.Form.SelectionFormOfGoodsBySalesOrders", 
		FormParameters, , , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
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

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject, "PrepaymentsVATRate", "PrepaymentsVATAmount", "PrepaymentsVATAmount");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfDocumentInARAPAccounting.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SettlementDocumentNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettlementDocumentNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfDocumentInARAPAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrectionNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "PrepaymentsCharacteristic", "Object.Prepayments.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#Region Other

&AtServer
Procedure OrganizationOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	Issued = ValueIsFilled(Object.IssueDate);
	AvailabilityControl(ThisObject, Issued);
	
	ByInvoice = Object.Patch;
	ThereIsEditRight = AccessRight("Update", Metadata.Documents.IssuedTaxInvoicePrepayment);
	UpdateInformationOnInvoiceBasis();
	
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form, Issued)
	
	Object = Form.Object;
	Items = Form.Items;
	
	IsNew = Not ValueIsFilled(Object.Ref);
	
	BasisType = TypeOf(Object.DocumentBasis);
	
	OnlyViewCounterpartyField = (Form.Issued And Not IsNew)
	                               Or Not (BasisType = Type("DocumentRef.OBEntry")
	                                       Or BasisType = Type("DocumentRef.OBEntryARAP")
	                                       Or BasisType = Type("DocumentRef.ARAPSettlement")
	                                       Or BasisType = Type("DocumentRef.ReceivedTaxInvoicePrepayment"));
	
	OnlyViewTinField        = (Form.Issued And Not IsNew) 
	                                Or Not ValueIsFilled(Form.Object.Counterparty)
	                                Or TypeOf(Form.Object.Counterparty) <> Type("CatalogRef.Counterparties");
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Counterparty", "ReadOnly", OnlyViewCounterpartyField);
	TMCommonUseClientServer.SetFormItemProperty(Items, "TINOfCounterparty", "ReadOnly", OnlyViewTinField);
	
	Items.CorrectionDetailsGroup.Visible = Object.Patch;
	Items.GroupNumberCorrectionDate.Visible = Object.Patch;
	Items.NumberDateGroup.Visible = Not Object.Patch;
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("Number");
	ArrayOfElementNames.Add("Date");
	ArrayOfElementNames.Add("Organization");
	ArrayOfElementNames.Add("DocumentBasis");
	ArrayOfElementNames.Add("TransactionKindCode");
	ArrayOfElementNames.Add("Patch");
	ArrayOfElementNames.Add("Corrective");
	ArrayOfElementNames.Add("DateOfDocumentInARAPAccounting");
	ArrayOfElementNames.Add("SettlementDocumentNumber");
	ArrayOfElementNames.Add("RuleOfPrepaymentFilter");
	ArrayOfElementNames.Add("Prepayments");
	ArrayOfElementNames.Add("AdvancesTotalAmount");
	ArrayOfElementNames.Add("AdvancesTotalAmountOfVAT");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "ReadOnly", Form.Issued And Not IsNew);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "IssuedInElectronicFormat", "Enabled", Form.Issued);
	TMCommonUseClientServer.SetFormItemProperty(Items, "IssueDate", "Enabled", Form.Issued);
	
	Items.IssueDate.AutoMarkIncomplete = Issued;
	
EndProcedure

&AtServerNoContext
Function GetBaseDataOnServer(DocumentBasis)

	TheseGrounds = Documents.IssuedTaxInvoicePrepayment.IncomingDocumentNumberAndDate(DocumentBasis);
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		
		AttributesValues = Common.ObjectAttributesValues(DocumentBasis, "Counterparty,ARAPAccountingViaSeparateCounterparty,Organization");
		If AttributesValues.ARAPAccountingViaSeparateCounterparty Then
			Counterparty = AttributesValues.Counterparty;
		Else
			Counterparty = AttributesValues.Organization;
		EndIf; 
		TheseGrounds.Insert("Counterparty", Counterparty);
		
	ElsIf TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntry")
	 	And TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntryARAP")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ARAPSettlement") Then
		TheseGrounds.Insert("Counterparty", IncomeAndExpensesServer.GetCounterpartyFromBase(DocumentBasis));
	EndIf;
	
	Return TheseGrounds;
	
EndFunction

&AtClientAtServerNoContext
Function RecalculationOfAmountOfNDSVToTS(Object)

	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("PriceIncludesVAT", True);
	PriceFillingStructure.Insert("VATTaxation", Object.VATTaxation);
	
	Return PriceFillingStructure;

EndFunction

#EndRegion

&AtClient
Procedure DateOnChangeClient()
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OpenInvoice()
	
	ShowValue(, Object.BaseDocumentTaxInvoice);
	
EndProcedure

&AtClient
Procedure InvoiceSelection(ChoosingBase = True, RowsArray = Undefined)
	
	ParametersStructure = New Structure;
	
	FilterValue = New Structure;
	FilterValue.Insert("DeletionMark", False);
	FilterValue.Insert("Posted", True);
	If ChoosingBase Then
		FilterValue.Insert("Patch", False);
	Else
		If ValueIsFilled(Object.Counterparty) Then
			FilterValue.Insert("Counterparty", Object.Counterparty)
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		FilterValue.Insert("ExcludeInvoice_", Object.Ref);
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		FilterValue.Insert("Organization", Object.Organization)
	EndIf;
	
	ParametersStructure.Insert("Filter", FilterValue);
	
	AdditionalParameters = New Structure("ChoosingBase,RowsArray", ChoosingBase, RowsArray);
	Notification = New CallbackDescription("InvoiceSelectionCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Document.IssuedTaxInvoicePrepayment.ChoiceForm",
		ParametersStructure,
		ThisObject, , , ,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InvoiceSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		If AdditionalParameters.ChoosingBase Then
			Object.BaseDocumentTaxInvoice = Result;
			FillInBasedOnInvoice();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearFoundationDocuments()
	
	Object.BaseDocumentTaxInvoice = Undefined;
	
	UpdateInformationOnInvoiceBasis();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnInvoiceBasis()
	
	RowsArray = New Array;
	
	Allowed1Update = ThereIsEditRight
		And Not (ValueIsFilled(Object.Ref) And Issued);
	
	If Object.Patch And ValueIsFilled(Object.BaseDocumentTaxInvoice) Then
		
		SFDetails = Common.ObjectAttributesValues(Object.BaseDocumentTaxInvoice, "Number, Date");
		BaseDocumentTaxInvoicePresentation = Documents.IssuedTaxInvoicePrepayment.InvoicePresentation_(SFDetails.Number, SFDetails.Date);
		
		RowsArray.Add(New FormattedString(
			BaseDocumentTaxInvoicePresentation, ,
			StyleColors.HyperlinkColor, ,
			GetURL(Object.BaseDocumentTaxInvoice)));
			
	EndIf;
	
	If Allowed1Update And Object.Patch Then
		
		If ValueIsFilled(Object.BaseDocumentTaxInvoice) Then
			
			RowsArray.Add("   ");
			
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Thay đổi';
					|ru = 'Изменить';
					|en = 'Change'; fa = 'تغییر';
					|it = 'Modificare';
					|pl = 'Change';
					|tr = 'Değiştir'"), ,
				StyleColors.HyperlinkColor, ,
				"BaseInvoiceSelection"));
			
		Else
			
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Chưa chọn hóa đơn GTGT';
					|ru = 'Не выбран счет-фактура';
					|en = 'Tax invoice is not selected'; fa = 'Tax invoice is not selected';
					|it = 'Fattura non selezionata';
					|pl = 'Nie wybrano faktury';
					|tr = 'Vergi faturası seçilmedi'"), ,
				WebColors.FireBrick, ,
				"BaseInvoiceSelection"));
				
		EndIf;
		
	EndIf;
	
	TextInvoiceBase = New FormattedString(RowsArray)
	
EndProcedure

&AtServer
Procedure FillInBasedOnInvoice()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInCorrectionOnInvoice();
	ValueToFormAttribute(DocumentObject, "Object");
	UpdateInformationOnInvoiceBasis();
	
	AvailabilityControl(ThisObject, Issued);
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	ClearFoundationDocuments();
	
	AvailabilityControl(ThisObject, Issued);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Prepayments,ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject, "Prepayments");
	
EndProcedure

&AtServer
Function InventoryTypeSelectionList(Products)
	
	InventoryTypes = New ValueList();
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReceivedTaxInvoicePrepayment") Then
		InventoryTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		Return InventoryTypes;
	EndIf;
	
	If Not ValueIsFilled(Products) Then
		InventoryTypes.Add(Enums.InventoryTypes.OwnGoods);
		If UseSalesCommission Then
			InventoryTypes.Add(Enums.InventoryTypes.ConsignedGoods);
		EndIf;
		InventoryTypes.Add(Enums.InventoryTypes.OperationService);
		If UseAgentServiceSale Then
			InventoryTypes.Add(Enums.InventoryTypes.AgentService);
		EndIf;
		Return InventoryTypes;
	EndIf;
	
	Attributes = New Structure();
	Attributes.Insert("ItemsType",  "ItemsType");
	Attributes.Insert("AccountingFeature", "AccountingFeature");
	AttributesValues = Common.ObjectAttributesValues(Products, Attributes);
	
	If AttributesValues.ItemsType = Enums.ItemsTypes.OperationService Then
		If UseAgentServiceSale
			And (AttributesValues.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis
				Or AttributesValues.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByPartner) Then
			InventoryTypes.Add(Enums.InventoryTypes.AgentService);
		Else
			InventoryTypes.Add(Enums.InventoryTypes.OperationService);
		EndIf;
	ElsIf AttributesValues.ItemsType = Enums.ItemsTypes.Work_5 Then
		InventoryTypes.Add(Enums.InventoryTypes.OperationService);
	Else
		InventoryTypes.Add(Enums.InventoryTypes.OwnGoods);
		If UseSalesCommission Then
			InventoryTypes.Add(Enums.InventoryTypes.ConsignedGoods);
		EndIf;
	EndIf;
	
	Return InventoryTypes;
	
EndFunction

&AtClient
Procedure DistributeAdvancesOnGoods(AddressInTempStorage, AdditionalParameters) Export
	
	If AddressInTempStorage = Undefined Then
		Return;
	EndIf;
	
	DistributeAdvancesOnGoodsOnServer(AddressInTempStorage);

EndProcedure

&AtServer
Procedure DistributeAdvancesOnGoodsOnServer(AddressInTempStorage)
	
	Goods = GetFromTempStorage(AddressInTempStorage);
	Prepayments = Object.Prepayments.Unload();
	Documents.IssuedTaxInvoicePrepayment.DistributeAdvancesOnGoods(Prepayments, Goods, Object.DocumentBasis);
	Object.Prepayments.Load(Prepayments);
	
	For Each LineOfAdvances In Object.Prepayments Do
		LineOfAdvances.SetIndex = ?(ValueIsFilled(LineOfAdvances.ProductsInSet), 1, 0);
	EndDo;
	
	FillInServiceDetailsForProductRange();

EndProcedure

&AtClient
Procedure DocumentBasisOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	TheseGrounds = AdditionalParameters.TheseGrounds;
	
	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		ExcludeProperties = "SettlementDocumentNumber,DateOfDocumentInARAPAccounting";
	EndIf; 
	
	FillPropertyValues(Object, TheseGrounds,, ExcludeProperties);
	
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
