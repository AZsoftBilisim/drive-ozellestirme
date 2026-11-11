#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	SetImplementationDocumentTypeRestriction();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsAdd1", "Visible", False);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AutoTitle = False;
		GenerateHeadersThatDependOnBaseType();
		Object.Author = Users.CurrentUser();
		
	EndIf;
	
	If Parameters.RefillByReceiving Then
		FillInServerAcceptanceForm();
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		ConsignmentSales25 = True;
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
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
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");

	SetVisibilityOfCommandAndFillInVATRate();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure GenerateHeadersThatDependOnBaseType()
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận (tạo mới)';
					|ru = 'Акт о расхождениях после поступления (создание)';
					|en = 'Receipt discrepancy report (create)'; fa = 'Receipt discrepancy report (create)';
					|it = 'Atto sulle discrepanze dopo l''arrivo (Creazione)';
					|pl = 'Protokół o odchyleniu po wpływie (tworzenie)';
					|tr = 'Teslim alım sonrası tutarsızlık raporu (oluşturma)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà trong đó đã tạo biên bản về chênh lệch sau tiếp nhận';
										|ru = 'Договор, в рамках которого оформлен акт о расхождениях после приемки';
										|en = 'Contract under which the receipt discrepancy report is created'; fa = 'Contract under which the receipt discrepancy report is created';
										|it = 'Договор, в рамках которого оформлен акт о расхождениях после приемки';
										|pl = 'Contract under which the receipt discrepancy report is created';
										|tr = 'Kabul sonrasında uyuşmazlık beyanının düzenlendiği sözleşme'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi nhận trả lại từ khách (tạo mới)';
					|ru = 'Акт о расхождениях после возврата от клиента (создание)';
					|en = 'Discrepancy report following return from customer (create)'; fa = 'Discrepancy report following return from customer (create)';
					|it = 'Акт о расхождениях после возврата от клиента (создание)';
					|pl = 'Discrepancy report following return from customer (create)';
					|tr = 'Müşteriden iade sonrası tutarsızlık raporu (oluşturma)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng theo đó hoàn trả';
										|ru = 'Договор, в рамках которого оформлен возврат';
										|en = 'Contract under which the return is recorded'; fa = 'قراردادی که برگشت تحت آن ثبت می‌شود';
										|it = 'Il contratto in base al quale è stato formalizzato il reso';
										|pl = 'Kontrakt, w ramach którego sporządzony jest zwrot';
										|tr = 'Para iadesinin yapıldığı sözleşme'");
		Items.Terms.ToolTip = NStr("vi = 'Thỏa thuận mà theo đó đã bán hàng.';
									|ru = 'Соглашение, по которому был реализован товар.';
									|en = 'Agreement under which the goods have been sold.'; fa = 'Agreement under which the goods have been sold.';
									|it = 'Accordo secondo il quale è stata realizzata la merce.';
									|pl = 'Umowa, według którego został sprzedany towar.';
									|tr = 'Kapsamında ürünlerin satışının yapıldığı anlaşma.'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa để bảo quản (tạo mới)';
					|ru = 'Акт о расхождениях после приемки товаров на хранение (создание)';
					|en = 'VMI procurement discrepancy report (create)'; fa = 'VMI procurement discrepancy report (create)';
					|it = 'Atto sulle discrepanze dopo l''accettazione delle merci in deposito (Creazione)';
					|pl = 'Protokół o odchyleniu po przyjęciu towarów do depozytu (tworzenie)';
					|tr = 'Depolanan stok farkları raporu (oluştur)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng trong đó chấp nhận được thực hiện';
										|ru = 'Договор, в рамках которого оформлена приемка';
										|en = 'Contract under which the receiving is documented'; fa = 'Contract under which the receiving is documented';
										|it = 'Contratto in base al quale è formalizzata l''accettazione';
										|pl = 'Kontrakt, w ramach którego jest sporządzony odbiór';
										|tr = 'Kabulün gerçekleştirildiği sözleşme'");
		Items.Terms.ToolTip = NStr("vi = 'Thỏa thuận mà hàng hóa đã được chấp nhận.';
									|ru = 'Соглашение, по которому был принят товар.';
									|en = 'Agreement under which the goods have been received.'; fa = 'Agreement under which the goods have been received.';
									|it = 'Accordo in base al quale è stata accettata la merce.';
									|pl = 'Umowa, na podstawie której produkt został zaakceptowany.';
									|tr = 'Kapsamında ürünlerin kabul edildiği anlaşma.'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		Title = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận từ người nhận ký gửi (tạo mới)';
					|ru = 'Акт о расхождениях после поступления от комиссионера (создание)';
					|en = 'Consignment pick-up discrepancy report (create)'; fa = 'Consignment pick-up discrepancy report (create)';
					|it = 'Atto sulle discrepanze dopo la ricezione dal commissionario (creazione)';
					|pl = 'Protokół o odchyleniu po wpływie od komisanta (tworzenie)';
					|tr = 'Konsinyeden alındıktan sonra tutarsızlık raporu (oluştur)'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		Title                  = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận nguyên vật liệu từ bên đặt gia công (tạo mới)';
										|ru = 'Акт о расхождениях после поступления сырья от давальца (создание)';
										|en = 'Discrepancy report following receipt of raw materials from provider (create)'; fa = 'Discrepancy report following receipt of raw materials from provider (create)';
										|it = 'Atto di accettazione con riserva dopo la ricezione di materie prime dal fornitore (creazione)';
										|pl = 'Protokół o odchyleniu po przyjęciu surowców od właściciela surowców (tworzenie)';
										|tr = 'Sağlayıcıdan hammadde alımı sonrası tutarsızlık raporu (oluştur)'");
		Items.Contract.ToolTip = NStr("vi = 'Hợp đồng mà trong phạm vi hợp đồng đã tạo chứng từ tiếp nhận';
										|ru = 'Договор, в рамках которого оформлена поступления';
										|en = 'Contract under which receipts are registered'; fa = 'Contract under which receipts are registered';
										|it = 'Contratto entro i cui termini è formalizzata la ricezione';
										|pl = 'Umowa, w ramach której zostało zarejestrowane przyjęcie';
										|tr = 'Teslim alma işleminin gerçekleştirildiği sözleşme'");
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Title                     = Handler.TitleOfReportCreationForm();
		Items.Contract.ToolTip    = Handler.ReportAgreementHint();
		Items.Terms.ToolTip = Handler.ActAgreementHint();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.BaseDocumentChoiceForm" Then
		
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
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" 
		And (Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
			Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage")) Then
		
		DiscrepanciesClient.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

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
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisObject);
	
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance(Object);
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
 		
		FillInDetailsOfMultiTurnContainer();
		
	EndIf;
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure 

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_DiscrepancyReportFollowingReceipt", WriteParameters, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

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
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
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
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent") Then
		
		AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
		
		AgreementSelectionParameters.Item                     = Item;
		AgreementSelectionParameters.Partner                     = Object.Partner;
		AgreementSelectionParameters.Document                    = Object.Terms;
		AgreementSelectionParameters.DocumentDate               = Object.Date;
		AgreementSelectionParameters.FormDataStructure        = Object;
		
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian") Then
			AgreementSelectionParameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
		ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent") Then
			AgreementSelectionParameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
			AgreementSelectionParameters.ConsignmentSales25 = True;
		EndIf;
		
		SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
		
	Else
		
		StructureOfAdditionalSelection = New Structure;
		
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
			StructureOfAdditionalSelection.Insert("BusinessOperation", Object.BusinessOperation);
		EndIf;
		
		PurchasesClient.StartSelectingSupplierAgreement(Item, StandardProcessing, Object.Partner, Object.Terms,
			Object.Date, StructureOfAdditionalSelection);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled (Object.Terms) Then
		
		TheCommissionAgentDoesNotKeepRecordsOnTheRNPT =
			Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
		
		Return;
		
	EndIf;
	
	WhenChangingAgreementAtServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer();
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure DocumentsBasisSubmissionClick(Item, StandardProcessing)
	
	DiscrepanciesClient.DocumentsBasisSubmissionClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If Items.GroupPages.CurrentPage = Items.PageGeneral Then
		
		FormWayToReflectDiscrepancy();
		DiscrepanciesClientServer.AvailabilityControl(ThisObject);
		
	EndIf;
	
	// StandardSubsystems.Properties		
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
			
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure HowToReflectDiscrepanciesDocumentChangesOnChange(Item)
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure MethodForReflectingDiscrepanciesRevenueAdjustmentOnChange(Item)
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure IssueDocumentsClick(Item)
	
	DiscrepanciesClient.IssueDocumentsClick(ThisObject);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer(True);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
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
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

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
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice") Then
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	EndIf;
	
	PerformActionsWhenChangingProducts(CurrentRow, StructureOfActions);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	PerformActionsWhenChangingProducts(CurrentRow, New Structure);
	
EndProcedure

&AtClient
Procedure PerformActionsWhenChangingProducts(CurrentRow, StructureOfActions)
	
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
			StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		EndIf;
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	EndIf;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
																							FormName, "Goods"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.DocumentBasis) Then
		SelfServiceClientServer.FillInDocumentBaseInLine(CurrentRow, BasisDocuments, False);
	EndIf;
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		
		If CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered") Then
			CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef");
		EndIf;
		
	EndIf;
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		CurrentRow.ToExpenseAs = True;
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	ElsIf CurrentRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.Work_5") Then
		CurrentRow.ToExpenseAs = False;
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
			StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		EndIf;
		
	EndIf;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
																							FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	DiscrepanciesClient.GoodsNumberOfPackagesOnChange(ThisObject, CachedValues);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	DiscrepanciesClient.GoodsPackageOnChange(ThisObject, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	Else
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	
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
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	DiscrepanciesClient.GoodsBeforeAddRow(ThisObject, Item, Cancel, Copy, CachedValues);
	
	If Copy Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
				
		UpdateStatusesForSpecifyingClientSeries(Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.Goods");
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters, Copy);
	
EndProcedure 

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateStatusesForSpecifyingClientSeries(Item);
	
EndProcedure

&AtClient
Procedure UpdateStatusesForSpecifyingClientSeries(Item)

	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item,CachedValues,SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;

EndProcedure 

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	DiscrepanciesClient.GoodsBeforeDeleteRow(CurrentData, Cancel, False);
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
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;

	If Field = Items.GoodsPurchaseOrder Then
		
		If ValueIsFilled(CurrentRow.PurchaseOrder) And CurrentRow.FilledUsingBaseDocument Then
			ShowValue(Undefined, CurrentRow.PurchaseOrder);
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
		
	ElsIf Field = Items.GoodsThereIsSupplierComment And EditingRights_3 Then
		
		VendorCommentStartOfSelection();
		
	ElsIf Field = Items.GoodsSalesOpportunity And ValueIsFilled(CurrentRow.SalesOpportunity) Then
			
			ShowValue(, CurrentRow.SalesOpportunity);
			
	ElsIf Field = Items.GoodsAction And EditingRights_3 Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
				Items.Goods, CachedValues, SeriesSpecificationParameters);
		DiscrepanciesClient.ProductsActionStartSelection(
			Items.Goods.CurrentData,
			Object,
			ThisObject,
			Object.TypeOfBaseDocumentForNonConformanceCertificate,
			ShowExplanation);
			
	Else
		
		FormEventsClient.WhenSelectingItem(ThisObject, Item, CurrentRow, Field, StandardProcessing);
		
		If StandardProcessing 
			And EditingRights_3 
			And CurrentRow.FilledUsingBaseDocument
			And CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesByDocument
			And (Field <> Items.GoodsNumberOfPackages And Field <> Items.GoodsAction
			And Field <> Items.GoodsPassportNumber) Then
				
				DiscrepanciesClient.ShowWarningForFilledBasedOnRows();
				
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	FormEventsClient.OnActivateRow(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsDocumentBasisOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.DocumentBasis) Then
		CurrentData.Warehouse           = PredefinedValue("Catalog.Warehouses.EmptyRef");
		CurrentData.PurchaseOrder = PredefinedValue("Document.PurchaseOrder.EmptyRef");
		Return;
	EndIf;
	
	FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.DocumentBasis));
	If FoundRows.Count() = 0 Then
		CurrentData.Warehouse           = PredefinedValue("Catalog.Warehouses.EmptyRef");
		CurrentData.PurchaseOrder = PredefinedValue("Document.PurchaseOrder.EmptyRef");
		Return;
	EndIf;
	
	FoundRow = FoundRows[0];

	If ValueIsFilled(CurrentData.PurchaseOrder) Then
		If FoundRow.BasisOrders.FindByValue(CurrentData.PurchaseOrder) = Undefined Then
			CurrentData.PurchaseOrder = PredefinedValue("Document.PurchaseOrder.EmptyRef");
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurrentData.Warehouse) Then
		If FoundRow.BasisWarehouses.FindByValue(CurrentData.Warehouse) = Undefined Then
			CurrentData.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
		EndIf;
	EndIf;
	
	SelfServiceClientServer.SetDocumentBasedOnOrderAttribute(CurrentData, FoundRow, False);
	SelfServiceClientServer.FillInOrderAndWarehouseInLine(CurrentData, BasisDocuments, False);
	DiscrepanciesClientServer.FillInTransactionInLine(CurrentData, TransactionOrders);
	
	FillInMultiTurnContainerDetailsInLine(Object.TypeOfBaseDocumentForNonConformanceCertificate, CurrentData, FoundRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
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
	
	Items.GoodsPassportNumber.ReadOnly = (Not Item.CurrentItem.Name = "GoodsPassportNumber");
	Items.GoodsCertificate.ReadOnly    = (Not Item.CurrentItem.Name = "GoodsCertificate");
	
	If Item.CurrentItem.Name = "GoodsPurchaseOrder" Then
		
		If CurrentData.FilledUsingBaseDocument Then
			Return;
		EndIf;
		
		Items.GoodsPurchaseOrder.ChoiceList.Clear();
		If Not ValueIsFilled(CurrentData.DocumentBasis) Then
			Return;
		EndIf;
		
		FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.DocumentBasis));
		If FoundRows.Count() > 0 Then
			Items.GoodsPurchaseOrder.ChoiceList.LoadValues(
			FoundRows[0].BasisOrders.UnloadValues());
		EndIf;
		
	ElsIf Item.CurrentItem.Name = "GoodsWarehouse" Then
		
		If CurrentData.FilledUsingBaseDocument Then
			Return;
		EndIf;
		
		Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
		If Not ValueIsFilled(CurrentData.DocumentBasis) Then
			Return;
		EndIf;
		
		FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurrentData.DocumentBasis));
		If FoundRows.Count() > 0 Then
			Items.GoodsWarehouse.ChoiceList.LoadValues(FoundRows[0].BasisWarehouses.UnloadValues());
		EndIf;
		
	ElsIf Item.CurrentItem.Name = "GoodsSum" Then
		
		Items.GoodsSum.ReadOnly = Not CurrentData.ThereAreDiscrepancies;
		Items.GoodsVATAmount.ReadOnly = Not CurrentData.ThereAreDiscrepancies;
		
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
			
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, 
			Items.GoodsCCDNumber.ChoiceList);
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
Procedure ProductsSupplierSCommentBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	VendorCommentStartOfSelection();
	
EndProcedure

&AtClient
Procedure ProductsSupplierSCommentBasementOnChange(Item)
	
	CurrentData                           = Items.Goods.CurrentData;
	CurrentData.ThereIsSupplierComment = Not IsBlankString(CurrentData.VendorSComment);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	
	Actions = New Structure();
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	TableRow = Items.Goods.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.DocumentCurrency = Object.Currency;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

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
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByBasisExecute(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	Notification = New CallbackDescription("FillInByBasisExecuteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
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
Procedure PrintDetails(Command)
	
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.PrintDetails",
				New Structure("DocumentObject", Object),
				ThisObject);
	
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
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
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
		"Document.DiscrepancyReportFollowingReceipt.DocumentForm.Command.OpenSelection");
	
	DiscrepanciesClient.OpenSelection(ThisObject, False);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OnlyDiscrepanciesExecute(Command)
	
	DiscrepanciesClient.OnlyDiscrepanciesExecute(ThisObject);
	
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
Procedure FillInTheReceivingFact(Command)
	
	ButtonsList = New ValueList();
	ButtonsList.Add("MoveTo_", NStr("vi = 'Điền';
									|ru = 'Заполнить';
									|en = 'Fill in'; fa = 'پرکردن';
									|it = 'Compilare';
									|pl = 'Fill in';
									|tr = 'Doldur'"));
	ButtonsList.Add("NoWrap", NStr("vi = 'Không điền';
									|ru = 'Не заполнять';
									|en = 'Do not fill in'; fa = 'پر نشود';
									|it = 'Non compilare';
									|pl = 'Nie wypełniaj';
									|tr = 'Doldurma'"));
	
	ShowQueryBox(New CallbackDescription("FillInTheReceivingFactCompletion", ThisObject),
	                                        NStr("vi = 'Điền vào hàng hóa khi nhận tại kho đặt hàng?';
												|ru = 'Заполнить товары по факту по фактической приемке на ордерных складах?';
												|en = 'Fill in the actual goods by actual receiving when warehouse management is enabled?'; fa = 'Fill in the actual goods by actual receiving when warehouse management is enabled?';
												|it = 'Compilare le merci di fatto al momento di accettazione effettiva nei magazzini dei mandati?';
												|pl = 'Wypełnić wiersze pozycji faktycznie według faktycznego odbioru w zarządzanych magazynach?';
												|tr = 'Ürünler fiili kabule göre gerçeğe uygun biçimde antrepo makbuzlarına doldurulsun mu?'"),
	                                        ButtonsList);
	
EndProcedure

&AtClient
Procedure FillInTheReceivingFactCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = "MoveTo_" Then
		
		HasChanges = FillInServerAcceptanceForm();
		PurchasesClient.NotifyAboutEndOfReplenishmentOfGoodsForAcceptance(HasChanges, True);
		DiscrepanciesClientServer.AvailabilityControl(ThisObject);
		
	EndIf;

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
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
		
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
		NewRow.ThereIsSupplierComment     = False;
		NewRow.ManagerComment          = "";
		NewRow.VendorSComment         = "";
		NewRow.FilledUsingBaseDocument          = False;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		
		If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		EndIf;
		
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
		
		DiscrepanciesClient.ProcessSeriesWhenSplittingGoodsLine(ThisObject, CurrentRow, NewRow);

		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	Else
		
		If (CurrentRow.Count > CurrentRow.CountByDocument
			And CurrentRow.NumberOfPackages <= CurrentRow.NumberOfPackagesByDocument) 
			Or (CurrentRow.Count < CurrentRow.CountByDocument
			And CurrentRow.NumberOfPackages >= CurrentRow.NumberOfPackagesByDocument) Then
			
			CurrentRow["Action"] = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
			
		EndIf;
		
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
		NewRow.ThereIsSupplierComment     = False;
		NewRow.ManagerComment          = "";
		NewRow.VendorSComment         = "";
		NewRow.FilledUsingBaseDocument          = True;
		
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
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");

		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
			
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
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
	
	ParametersOfSeriesIndicationForm = ProductsServer.ParametersOfSeriesIndicationForm(Object,
		SeriesSpecificationParameters, CurDataId, ThisObject);
	CurrentData = Object.Goods.FindByID(CurDataId);
	If CurrentData.FilledUsingBaseDocument Then
		ParametersOfSeriesIndicationForm.OnlyQuantityEditing = True;
	EndIf;
	
	Return ParametersOfSeriesIndicationForm;
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text, CurrentData) Then
	
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
		
		SeriesSelectionNotification = New CallbackDescription("OpenSelectionOfSeriesCompletion",
															ThisObject,
															New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisObject,
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
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	DiscrepanciesServer.ProcessSeriesIndication_(ThisObject, ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure ActionChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.NumberOfPackages < CurrentData.NumberOfPackagesByDocument Then
		CurrentData.Action = Result.ShortfallAction;
		CurrentData.ThirdPartyIsGuilty = Result.ThirdPartyIsGuilty;
	ElsIf CurrentData.NumberOfPackages > CurrentData.NumberOfPackagesByDocument Then
		CurrentData.Action = Result.ActionSurplus;
		CurrentData.ThirdPartyIsGuilty = False;
	EndIf;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Items.Goods,CachedValues,SeriesSpecificationParameters) Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion


#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	DiscrepanciesServer.ProcessIndicationOfCCDNumber(ThisObject,
													RowID,
													CalculationResult1,
													CCDNumbersFilledIn,
													CCDNumber);
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region ServerSideEventHandlersForChangingFormElements

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		If ToUseTermsOfSales Then
			FillIn_TermsOfSales();
		EndIf;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		If ToUseTermsOfSales Or Not Handler.CustomerAgreementsAreApplicable() Then
			FillIn_TermsOfSales();
		EndIf;
		
	Else 
		FillInTermsOfPurchase();
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty, True);
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If QualityControl.UpdateActionParameters(
			Documents.DiscrepancyReportFollowingReceipt,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure 

&AtServer
Procedure ContactPersonOnChangeServer()
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerWhenChangesAreMadeOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	CompleteVATTaxation(False, True);
	WhenChangingVATTaxationServer();
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
	If ValueIsFilled(Object.Organization) Then
		
		If ValueIsFilled(Object.Partner) Then
			PartnerWhenChangesAreMadeOnServer();
		Else
			DiscrepanciesServer.FillInDefaultContract(Object, ContractBusinessTransaction);
			AgreementWhenModifiedOnServer();
		EndIf;
		
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
			CompleteVATTaxation(True, False);
			WhenChangingVATTaxationServer();
		EndIf;
		
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure WhenChangingVATTaxationServer()
	
	If DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			CachedValues.ProcessedRows,
			StructureOfActions,
			Object.Goods,
			Undefined);
	
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);

	SetVisibilityOfCommandAndFillInVATRate();

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer()
	
	If Not ToUseTermsOfSales 
		And DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;

		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
		
	EndIf;
	
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer()
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		
		DocumentSales = FormAttributeToValue("Object");
		DocumentSales.FillInTermsOfSalesUnderAgreement();
		ValueToFormAttribute(DocumentSales, "Object");
		
	Else
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchaseUnderAgreement();
		ValueToFormAttribute(DocumentPurchases, "Object");
		
	EndIf;
	
	WhenBusinessTransactionChangesServer();
	
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If QualityControl.UpdateActionParameters(
			Documents.DiscrepancyReportFollowingReceipt,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	ContractBusinessTransaction = ContractBusinessTransaction(Object.BusinessOperation, Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	DiscrepanciesServer.FillInDefaultContract(Object, ContractBusinessTransaction);
	AgreementWhenModifiedOnServer();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		Object.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments;
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		Object.PriceIncludesVAT = False;
		PriceIncludesVATOnChangeServer();
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		Object.PriceIncludesVAT = False;
		PriceIncludesVATOnChangeServer();
	EndIf;
	
	CompleteVATTaxation();
	WhenChangingVATTaxationServer();
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
	SetVisibilityOfElementsByOperationServer();
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);
	
EndProcedure

&AtServerNoContext
Function ContractBusinessTransaction(BusinessOperation, TypeOfBaseDocumentForNonConformanceCertificate)
	
	If DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Return BusinessOperation;
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		Return Handler.ContractBusinessTransaction();
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		Return TollingSchemeClientServer.ContractBusinessTransaction();
	Else
		If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
			Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
		ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer") Then
			Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
		Else
			Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
		EndIf;
	EndIf;
	
EndFunction

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	DiscrepanciesServer.ActOfDiscrepanciesEstablishConditionalAppearanceOfFormOfDocument(ThisObject);
	
	PurchasesServer.EstablishConditionalAppearanceForExpenses(ThisObject);
	
	// Agreement, type of basis for the acquisition of goods, services or acceptance of goods, storage
	
	TypesOfGroundsForActOfDivergence = New ValueList;
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice);
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage);
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Terms.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfGroundsForActOfDivergence;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Contract, type of basis for the acquisition of goods and services
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Order to supplier line code blank mark

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product line of the overorder visibility

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.BasisByOrders");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The goods are ordered to the supplier in excess of the order

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	
	// Product to the supplier hyperlink

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DocumentBasis");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// The goods are available to the supplier

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);
	
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
	
	// The goods are not delivered to the supplier according to orders

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);
	
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không theo đơn hàng>';
													|ru = '<не по заказу>';
													|en = '<not as per order>'; fa = '<not as per order>';
													|it = '<senza ordine>';
													|pl = '<nie zgodnie z zamówieniem>';
													|tr = '<sipariş dışı>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Product documentationmark blank

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product document is available for viewing only

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	// Merchandise Price mark blank

	DocumentOperations = New ValueList;
	DocumentOperations.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	DocumentOperations.Add(Enums.BusinessTransactions.ReturnFromCustodian);
	DocumentOperations.Add(Enums.BusinessTransactions.ReceiptFromToller2_5);
	DocumentOperations.Add(Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisObject;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.PathToSelectionFieldIsToReturnReusableContainer	= "Object.Goods.ToReturnReusablePackage";
	InstallationParameters.PathToSelectionFieldRequiresDepositForContainer		= "Object.Goods.PackageDepositIsRequired";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = DocumentOperations;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Unavailability of items in the products table for rows filled in on the basis
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBatchesIndicationStatus.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVendorPriceKind.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentBasis.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCertificate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue  = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	// Product number of packagingsdocument mark blank
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesByDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Merchandise Number of packages mark blank
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The product of the customer's sum is a blank mark
	
	TypesOfGroundsForActOfDivergence = New ValueList;
	TypesOfGroundsForActOfDivergence.LoadValues(DiscrepanciesClientServer.TypesOfBasisReceiptOfGoodsFromCustodian());
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FilledUsingBaseDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfGroundsForActOfDivergence;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// the mark of an unfilled division, if the Product

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ListOfTwoWayOperations = New ValueList;
	ListOfTwoWayOperations.LoadValues(PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTwoWayOperations;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling visibility of the Product Write Overspend and Product Overspend fields for two-way operations

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTwoWayOperations;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// explanatory inscription for the division, if the warehouses are not in the tabular part

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho công việc/dịch vụ)';
													|ru = '<для работ/услуг>';
													|en = '<for works/services>'; fa = '<for works/services>';
													|it = '<per i lavori/servizi>';
													|pl = '<dla robót/usług>';
													|tr = '<iş/hizmet için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Warehouse - explanatory label if the item type is a Service.
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	// Conditional appearance of import fields.
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceInDocumentPurchaseOfGoodsServices(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject, False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	OFOperationsWithoutCCD = EconomicImportOperations();
	OFOperationsWithoutCCD.Add(Enums.BusinessTransactions.PurchaseByImport);
	OFOperationsWithoutCCD.Add(Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	OFOperationsWithoutCCD.Add(Enums.BusinessTransactions.ReceiptFromToller2_5);
	ItemFilter.RightValue = OFOperationsWithoutCCD;

	Item.Appearance.SetParameterValue("Visible", False);
	
	// The transaction is a hyperlink, if filled in.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOpportunity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// Commodity action - text, if for other expenses and at the expense of a third-party company
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThirdPartyIsGuilty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses;
	
	Item.Appearance.SetParameterValue("Text",
		TextOfActionOptionForOtherExpensesAndAtExpenseOfThirdPartyCompany(Object.BusinessOperation));
	
	// Commodity Action - text, if for other expenses and at our expense
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThirdPartyIsGuilty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm bằng chi phí của chúng tôi';
													|ru = 'Списать за наш счет';
													|en = 'Write off at our expense'; fa = 'اسقاط به هزینه ما';
													|it = 'Stornare a nostre spese';
													|pl = 'Rozchodować na nasz koszt';
													|tr = 'Masrafların tarafımıza yazılması'"));
	
	// Commodity Action - text, if for other expenses and at our expense
	Item = ConditionalAppearance.Items.Add();

	TypesOfGroundsForActOfDivergence = New ValueList;
	TypesOfGroundsForActOfDivergence.LoadValues(DiscrepanciesClientServer.TypesOfBasisReceiptOfGoodsFromCustodian());
	TypesOfGroundsForActOfDivergence.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TypeOfBaseDocumentForNonConformanceCertificate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfGroundsForActOfDivergence;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThirdPartyIsGuilty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm hàng thiếu';
													|ru = 'Списать недостачи';
													|en = 'Write off shortages'; fa = 'Write off shortages';
													|it = 'Stornare ammanchi';
													|pl = 'Rozchodować niedobory';
													|tr = 'Eksiklikleri gider yazın'"));
	
	// Product Action - text if work or service and return without registration
	
	WorkAndService = New ValueList;
	WorkAndService.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	WorkAndService.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = WorkAndService;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đảo ngược';
													|ru = 'Сторнировать';
													|en = 'Reverse'; fa = 'معکوس';
													|it = 'Сторнировать';
													|pl = 'Reverse';
													|tr = 'İptal et'"));
	
	// TovarySummaNDS view only
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject);
	
	// The product is a preview only
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter =  ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.NumberOfPackagesByDocument");
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Item series
	
	DiscrepanciesServer.SetConditionalAppearanceOfSeries(ThisObject, "");
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.OperationService);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
EndProcedure

&AtServer
Procedure SetVisibilityForReflection()
	
	BasisOfActIsGoodsReceiptForStorage =
		DiscrepanciesClientServer.TypeOfBasisGoodsReceiptForStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	BasisOfActIsReceiptOfGoodsFromCustodian =
		DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	Items.GroupInformationAboutAvailabilityOfTheRecordMethod.Visible =
		DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or BasisOfActIsGoodsReceiptForStorage
		Or BasisOfActIsReceiptOfGoodsFromCustodian;
	
	Items.GroupRecordMethod.Visible =
		DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or BasisOfActIsGoodsReceiptForStorage
		Or BasisOfActIsReceiptOfGoodsFromCustodian;
	
	Items.MethodForReflectingDiscrepanciesRevenueAdjustment.Visible =
		(UseDebitNotes
			And DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate))
		Or (UseDocumentCorrection
			And (BasisOfActIsGoodsReceiptForStorage Or BasisOfActIsReceiptOfGoodsFromCustodian));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	ParametersArray = New Array;
	ArrayOfProductTypes = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", ArrayOfProductTypes));
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
	
	TypesOfStorageActs = DiscrepanciesClientServer.TypesOfBasisReceiptOfGoodsFromCustodian();
	PricesWithoutVAT = TypesOfStorageActs.Find(Object.TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	TypesOfStorageActs.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage);
	TypesOfStorageActs.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider);
	WithoutVAT = TypesOfStorageActs.Find(Object.TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
	CommonClientServer.SetFormItemProperty(Items, "VATTaxation", "Visible", Not WithoutVAT);
	CommonClientServer.SetFormItemProperty(Items, "PriceIncludesVAT", "Visible", Not PricesWithoutVAT);
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		PurchasesServer.AdjustListOfSelectionOfBusinessOperationOfReceipt(ThisObject);
	EndIf;
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure ManagingFormDetailsDependingOnBaseType()
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		//Partner
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		Items.Partner.Title       = NStr("vi = 'Khách hàng';
										|ru = 'Клиент';
										|en = 'Customer'; fa = 'مشتری';
										|it = 'Cliente';
										|pl = 'Customer';
										|tr = 'Müşteri'");
		
		Items.ProductsSupplierSCommentBasement.Title = NStr("vi = 'Ghi chú của khách hàng về chênh lệch tại dòng';
															|ru = 'Комментарии клиента по расхождениям в строке';
															|en = 'Customer comment to the line discrepancies'; fa = 'توضیح مشتری درباره مغایرت‌های سطر';
															|it = 'Commenti del cliente riguardo le discrepanze nella riga';
															|pl = 'Komentarze klienta wg odchylenia w wierszu';
															|tr = 'Müşterinin satırdaki tutarsızlıklara ilişkin yorumları'");
		Items.GoodsThereIsSupplierComment.Title   = NStr("vi = 'từ khách hàng';
														|ru = 'от клиента';
														|en = 'from customer'; fa = 'از مشتری';
														|it = 'от клиента';
														|pl = 'od nabywcy';
														|tr = 'müşteriden'");
		
		//Goods
		Items.GoodsFillInByBasis.Title  = NStr("vi = 'Theo trả lại';
												|ru = 'По возвратам';
												|en = 'By returns'; fa = 'By returns';
												|it = 'Per i resi';
												|pl = 'Według zwrotów';
												|tr = 'İadeler üzerine'");
		Items.GoodsPartnerProducts.Visible = False;
		Items.GoodsVendorPriceKind.Visible      = False;
		Items.GoodsDocumentBasis.Title      = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
													|ru = 'Возврат поставщику';
													|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
													|it = 'Reso al fornitore';
													|pl = 'Zwrot do dostawcy ';
													|tr = 'Tedarikçiye iade'");
		Items.GoodsDimensionOfExpenses.Visible      = False;
		Items.GoodsExpenseItem.Visible         = False;
		Items.GoodsToExpenseAs.Visible       = False;
		Items.GoodsDepartment.Visible          = False;
		Items.GoodsCertificate.Visible             = False;
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		If GetFormFunctionalOption("UseRetailSales") Then
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
		EndIf;
		If GetFormFunctionalOption("UseSalesCommission") Then
			SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
		EndIf;
		
		//Terms
		AgreementTypeRestriction     = New TypeDescription("CatalogRef.TermsOfSale");
		Items.Terms.Visible = ToUseTermsOfSales;
		
		//Totals
		Items.ForReasonsExcludingVAT.Title = NStr("vi = 'Theo trả lại';
													|ru = 'По возвратам';
													|en = 'By returns'; fa = 'By returns';
													|it = 'Per i resi';
													|pl = 'Według zwrotów';
													|tr = 'İadeler üzerine'");
		Items.OnGroundsOfWithVAT.Title = NStr("vi = 'Theo trả lại';
												|ru = 'По возвратам';
												|en = 'By returns'; fa = 'By returns';
												|it = 'Per i resi';
												|pl = 'Według zwrotów';
												|tr = 'İadeler üzerine'");
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		//Contract
		RelationsOfContractSelectionParameters = New Array;
		
		For Each Link In Items.Contract.ChoiceParameterLinks Do
			
			RelationshipOfSelectionParameters = Link; // ChoiceParameterLink 
			
			If Not RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
				RelationsOfContractSelectionParameters.Add(RelationshipOfSelectionParameters);
			Else
				ChoiceParameter = New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation");
				
				RelationsOfContractSelectionParameters.Add(ChoiceParameter);
			EndIf;
		EndDo;
		
		Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
		
		//Terms
		AgreementTypeRestriction = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
		Items.Terms.Visible = ToUseTermsOfSales;
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesRevenueAdjustment.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments,
			NStr("vi = 'Thay đổi chứng từ nhập hàng vào kho';
				|ru = 'Изменить приемку товаров на хранение';
				|en = 'Change the VMI procurement'; fa = 'Change the VMI procurement';
				|it = 'Change the VMI procurement';
				|pl = 'Change the VMI procurement';
				|tr = 'Depolaya mal girişini değiştir'"));
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries,
			NStr("vi = 'Lập chứng từ nhập hàng vào kho (điều chỉnh)';
				|ru = 'Оформить приемку товаров на хранение (исправление)';
				|en = 'Register the VMI procurement (correction)'; fa = 'Register the VMI procurement (correction)';
				|it = 'Register the VMI procurement (correction)';
				|pl = 'Register the VMI procurement (correction)';
				|tr = 'Depoya mal girişini oluştur (yama)'"));
		
		//Goods
		Items.GoodsDocumentSalesOfGoodsAndServices.Visible = False;
		Items.GoodsDepartment.Visible      = False;
		Items.GoodsCertificate.Visible         = False;
		Items.GoodsSalesOpportunity.Visible             = False;
		
		//Totals
		Items.ForReasonsExcludingVAT.Title = NStr("vi = 'Theo sự chấp nhận';
													|ru = 'По приемкам';
													|en = 'By available VMI'; fa = 'By available VMI';
													|it = 'Per le accettazioni';
													|pl = 'Według odbiorów';
													|tr = 'Tedariğe göre'");
		Items.OnGroundsOfWithVAT.Title = NStr("vi = 'Theo sự chấp nhận';
												|ru = 'По приемкам';
												|en = 'By available VMI'; fa = 'By available VMI';
												|it = 'Per le accettazioni';
												|pl = 'Według odbiorów';
												|tr = 'Tedariğe göre'");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
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
			New ChoiceParameter(
					"Filter.BusinessOperation", TollingSchemeClientServer.ContractBusinessTransaction()));
		
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
		Items.Terms.Visible = False;
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesRevenueAdjustment.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments,
			NStr("vi = 'Thay đổi chứng từ tiếp nhận từ người đặt gia công';
				|ru = 'Изменить поступление от давальца';
				|en = 'Change the Goods receipt — Subcontracting services delivered'; fa = 'Change the Goods receipt — Subcontracting services delivered';
				|it = 'Change the Goods receipt — Subcontracting services delivered';
				|pl = 'Change the Goods receipt — Subcontracting services delivered';
				|tr = 'Mal girişi — Verilen fason hizmetleri'"));
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries,
			NStr("vi = 'Lập chứng từ tiếp nhận từ người đặt gia công (điều chỉnh)';
				|ru = 'Оформить поступление от давальца (исправление)';
				|en = 'Register the Goods receipt — Subcontracting services delivered (correction)'; fa = 'Register the Goods receipt — Subcontracting services delivered (correction)';
				|it = 'Register the Goods receipt — Subcontracting services delivered (correction)';
				|pl = 'Register the Goods receipt — Subcontracting services delivered (correction)';
				|tr = 'Mal girişi — Verilen fason hizmetleri (düzeltme)'"));
		
		//Goods
		Items.GoodsDocumentSalesOfGoodsAndServices.Visible = False;
		Items.GoodsDepartment.Visible      = False;
		Items.GoodsCertificate.Visible         = False;
		Items.GoodsSalesOpportunity.Visible             = False;
	
		Items.Partner.Title               = NStr("vi = 'Bên đặt gia công';
												|ru = 'Давалец';
												|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
												|it = 'Fornitore';
												|pl = 'Material provider';
												|tr = 'Malzeme tedarikçisi'");
		Items.GoodsPurchaseOrder.Title = NStr("vi = 'Đơn hàng của bên đặt gia công';
												|ru = 'Заказ давальца';
												|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
												|it = 'Ordine del committente';
												|pl = 'Zamówienie dostawcy';
												|tr = 'Sağlayıcı siparişi'");
		
		//Totals
		Items.ForReasonsExcludingVAT.Title          = NStr("vi = 'Theo sự chấp nhận';
															|ru = 'По приемкам';
															|en = 'By available VMI'; fa = 'By available VMI';
															|it = 'Per le accettazioni';
															|pl = 'Według odbiorów';
															|tr = 'Tedariğe göre'");
		Items.OnGroundsOfWithVAT.Title            = NStr("vi = 'Theo sự chấp nhận';
														|ru = 'По приемкам';
														|en = 'By available VMI'; fa = 'By available VMI';
														|it = 'Per le accettazioni';
														|pl = 'Według odbiorów';
														|tr = 'Tedariğe göre'");
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
		//Partner, Counterparty, Contract
		Handler.AdjustItemSelectionSettings(ThisObject, Object);
		
		//Terms
		AgreementTypeRestriction     = New TypeDescription("CatalogRef.TermsOfSale");
		Items.Terms.Visible = ToUseTermsOfSales;
		
		//BusinessOperation
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Handler.BusinessOperation());
		
		//DiscrepanciesPostingMethod
		SelectionListIsWayToReflectDiscrepanciesChangingDocument = Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Clear();
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection = Items.MethodForReflectingDiscrepanciesRevenueAdjustment.ChoiceList;
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Clear();
		
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			Text_FixMethodCorrection   = NStr("vi = 'Thay đổi tiếp nhận hàng hóa từ người nhận ký gửi';
												|ru = 'Изменить поступление товаров от комиссионера';
												|en = 'Change the receipt of goods from consignee'; fa = 'Change the receipt of goods from consignee';
												|it = 'Change the receipt of goods from consignee';
												|pl = 'Change the receipt of goods from consignee';
												|tr = 'Ürünlerin konsinyeden alımını değiştir'");
			Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ tiếp nhận hàng hóa từ người nhận ký gửi (điều chỉnh)';
													|ru = 'Оформить поступление товаров от комиссионера (исправление)';
													|en = 'Register the receipt of goods from consignee (correction)'; fa = 'Register the receipt of goods from consignee (correction)';
													|it = 'Register the receipt of goods from consignee (correction)';
													|pl = 'Register the receipt of goods from consignee (correction)';
													|tr = 'Ürünlerin konsinyeden alımını oluştur (yama)'");
		ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor Then
			Text_FixMethodCorrection   = NStr("vi = 'Thay đổi tiếp nhận từ bên nhận gia công';
												|ru = 'Изменить поступление от переработчика';
												|en = 'Change the Goods receipt — External subcontracting'; fa = 'Change the Goods receipt — External subcontracting';
												|it = 'Change the Goods receipt — External subcontracting';
												|pl = 'Change the Goods receipt — External subcontracting';
												|tr = 'Fason üreticiye gelen alımı değiştir'");
			Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ tiếp nhận từ bên nhận gia công (điều chỉnh)';
													|ru = 'Оформить поступление от переработчика (исправление)';
													|en = 'Register the Goods receipt — External subcontracting (correction)'; fa = 'Register the Goods receipt — External subcontracting (correction)';
													|it = 'Register the Goods receipt — External subcontracting (correction)';
													|pl = 'Register the Goods receipt — External subcontracting (correction)';
													|tr = 'Fason üreticiden gelen alımı oluştur (yama)'");
		ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor Then
			Text_FixMethodCorrection   = NStr("vi = 'Thay đổi chứng từ nhận trả lại nguyên vật liệu từ bên nhận gia công';
												|ru = 'Изменить возврат сырья от переработчика';
												|en = 'Change the Goods return — Subcontracting services received'; fa = 'Change the Goods return — Subcontracting services received';
												|it = 'Change the Goods return — Subcontracting services received';
												|pl = 'Change the Goods return — Subcontracting services received';
												|tr = 'Hammaddelerin fason üreticiden iadesini değiştir'");
			Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ trả lại nguyên vật liệu từ bên nhận gia công (điều chỉnh)';
													|ru = 'Оформить возврат сырья от переработчика (исправление)';
													|en = 'Register the Goods return — Subcontracting services received (correction)'; fa = 'Register the Goods return — Subcontracting services received (correction)';
													|it = 'Register the Goods return — Subcontracting services received (correction)';
													|pl = 'Register the Goods return — Subcontracting services received (correction)';
													|tr = 'Hammaddelerin fason üreticiden iadesini oluştur (yama)'");
		Else
			Text_FixMethodCorrection   = NStr("vi = 'Thay đổi chứng từ tiếp nhận hàng hóa từ bên lưu kho';
												|ru = 'Изменить поступление товаров от хранителя';
												|en = 'Change the VMI return'; fa = 'Change the VMI return';
												|it = 'Change the VMI return';
												|pl = 'Change the VMI return';
												|tr = 'Ürünlerin VMI''dan alımını değiştir'");
			Text_ProcessingMethodCorrection = NStr("vi = 'Lập chứng từ tiếp nhận hàng hóa từ bên lưu kho (điều chỉnh)';
													|ru = 'Оформить поступление товаров от хранителя (исправление)';
													|en = 'Register the VMI return (correction)'; fa = 'Register the VMI return (correction)';
													|it = 'Register the VMI return (correction)';
													|pl = 'Register the VMI return (correction)';
													|tr = 'Ürünlerin VMI''dan alımını oluştur (yama)'");
		EndIf;
		SelectionListIsWayToReflectDiscrepanciesChangingDocument.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments,
			Text_FixMethodCorrection);
		SelectionListMethodOfReflectingDiscrepanciesCorrectionCorrection.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries,
			Text_ProcessingMethodCorrection);
		
		Items.ProductsSupplierSCommentBasement.Title = Handler.BasementVendorComment();
		Items.GoodsThereIsSupplierComment.Title   = Handler.CustomerComment();
		
		//Goods
		Items.GoodsFillInByBasis.Title  = Handler.HeadlineOnGrounds();
		Items.GoodsPartnerProducts.Visible = False;
		Items.GoodsVendorPriceKind.Visible      = False;
		Items.GoodsDocumentBasis.Title      = Handler.TitleOfDocumentGroundsOfAct();
		Items.GoodsDimensionOfExpenses.Visible      = False;
		Items.GoodsExpenseItem.Visible         = False;
		Items.GoodsToExpenseAs.Visible       = False;
		Items.GoodsDepartment.Visible          = False;
		Items.GoodsCertificate.Visible             = False;
		
		//Totals
		Items.ForReasonsExcludingVAT.Title = Handler.HeadlineOnGrounds(False);
		Items.OnGroundsOfWithVAT.Title = Handler.HeadlineOnGrounds(False);
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		And PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(Object.BusinessOperation) Then
		
		SelectionListBusinessOperations = Items.BusinessOperation.ChoiceList;
		SelectionListBusinessOperations.Clear();
		SelectionListBusinessOperations.Add(Object.BusinessOperation);
		
		//Contract
		RelationsOfContractSelectionParameters = New Array;
		For Each Link In Items.Contract.ChoiceParameterLinks Do
			
			RelationshipOfSelectionParameters = Link; // ChoiceParameterLink
			
			If Not RelationshipOfSelectionParameters.Name = "Terms" Then
				RelationsOfContractSelectionParameters.Add(RelationshipOfSelectionParameters);
			EndIf;
		EndDo;
		Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
		
		BasicOperation = PurchasesServer.MainEconomicOperationOfSeparatePurchase(Object.BusinessOperation);
		//Terms
		BusinessTransactions = New Array;
		BusinessTransactions.Add(BasicOperation);
		
		AgreementSelectionParameters = New Array;
		AgreementSelectionParameters.Add(New ChoiceParameter("Filter.BusinessOperation", BusinessTransactions));
		
		AgreementTypeRestriction     = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
		Items.Terms.Visible = UseTermsOfPurchases;
		Items.Terms.ChoiceParameters = New FixedArray(AgreementSelectionParameters);
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
		//Goods
		Items.GoodsDocumentSalesOfGoodsAndServices.Visible = False;
		
	Else
		
		//Contract
		RelationsOfContractSelectionParameters = New Array;
		For Each Link In Items.Contract.ChoiceParameterLinks Do
			
			RelationshipOfSelectionParameters = Link; // ChoiceParameterLink
			
			If Not RelationshipOfSelectionParameters.Name = "Terms" Then
				RelationsOfContractSelectionParameters.Add(RelationshipOfSelectionParameters);
			EndIf;
		EndDo;
		Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
		
		//Terms
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseByImport);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		BusinessTransactions.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		
		AgreementSelectionParameters = New Array;
		AgreementSelectionParameters.Add(New ChoiceParameter("Filter.BusinessOperation", BusinessTransactions));
		
		AgreementTypeRestriction     = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
		Items.Terms.Visible = UseTermsOfPurchases;
		Items.Terms.ChoiceParameters = New FixedArray(AgreementSelectionParameters);
		DiscrepanciesServerCall.EstablishAvailabilityOfVendorAgreements(ThisObject);
		
		//Goods
		Items.GoodsDocumentSalesOfGoodsAndServices.Visible = False;
		
	EndIf;
	
	Items.Terms.TypeRestriction = AgreementTypeRestriction;
	
	If Items.Contract.Visible Then
		If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			Items.Contract.AutoMarkIncomplete = False;
		Else 
			Items.Contract.AutoMarkIncomplete = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FormWayToReflectDiscrepancy()

	DiscrepanciesServer.FormInscriptionToReflectDiscrepancies(ThisObject,
	                                                                 Object.Goods,
	                                                                 Items.DiscrepancyLabel,
	                                                                 Items.IssueDocuments,
	                                                                 TypeOf(Object.Ref),
	                                                                 OperationType());
	Items.GroupRecordMethod.Enabled = Items.DiscrepancyLabel.Enabled;
	FormEvents.WhenChangingFormPages(ThisObject, "GroupPages");

EndProcedure

&AtServer
Procedure SetImplementationDocumentTypeRestriction()
	
	TypesArray = Metadata.Documents.DiscrepancyReportFollowingReceipt.TabularSections.Goods.Attributes.DocumentSalesOfGoodsAndServices.Type.Types();

	CommonClientServer.DeleteValueFromArray(TypesArray, Type("DocumentRef.ReceiptOfGoodsFromCustodian"));
	CommonClientServer.DeleteValueFromArray(TypesArray, Type("DocumentRef.TransferOfGoodsToBailee"));
	
	Items.GoodsDocumentSalesOfGoodsAndServices.TypeRestriction = New TypeDescription(TypesArray);
	
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

#EndRegion

#Region FillingAndProcessingSelections

&AtClient
Procedure FillInByBasisExecuteCompletion(Result, AdditionalParameters) Export 
	
	FillInByBasis();
	
EndProcedure

&AtClient
Procedure ChangeActionOfSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InstallResult = DiscrepanciesClient.SetActionOptionForSelectedLines(
		ThisObject,
		Result.ShortfallAction,
		Result.ActionSurplus,
		,
		,
		Result.ThirdPartyIsGuilty);
	
	If InstallResult.NeedServerCall Then
		NumberOfModifiedRowsMatching = InstallResult.NumberOfModifiedRowsMatching;
		SetActionOptionInLinesServer(Result, NumberOfModifiedRowsMatching);
		DiscrepanciesClient.NotifyAboutActionInstallation(NumberOfModifiedRowsMatching);
	ElsIf InstallResult.RowsForRecalculatingSeries.Count() > 0 Then
		FillInStatusesOfSeriesInLines(InstallResult.RowsForRecalculatingSeries);
	EndIf;
	
	Modified = True;

EndProcedure

&AtServer
Procedure FillInStatusesOfSeriesInLines(ProductLines_2)
	
	ArrayOfStringsToProcess = New Array;
	
	For Each SelectedRow In ProductLines_2 Do
		CurrentRow = Object.Goods.FindByID(SelectedRow);
		ArrayOfStringsToProcess.Add(CurrentRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters, ArrayOfStringsToProcess);
	
EndProcedure

&AtServer
Procedure SetActionOptionInLinesServer(Result, NumberOfModifiedRowsMatching)
	
	DiscrepanciesServer.SetActionOptionInLines(
		ThisObject,
		NumberOfModifiedRowsMatching,
		Result.ShortfallAction,
		Result.ActionSurplus,
		,
		,
		Result.ThirdPartyIsGuilty);
	
EndProcedure

&AtServer
Procedure FillInByBasis()
	
	DiscrepanciesServer.FillInByBasis(ThisObject);
	CreateOrdersTransactionsTable();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Function FillInServerAcceptanceForm()
	
	SetPrivilegedMode(True);
	
	AdvancedWarehousingOnReceiving = AdvancedWarehousingOnReceiving();
	
	SetPrivilegedMode(False);
	
	If Not AdvancedWarehousingOnReceiving Then
		Return False;
	EndIf;
	
	TableWarehouses = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	TableWarehouses = CommonClientServer.CollapseArray(TableWarehouses);
	
	ResultingTable      = Object.Goods.Unload(New Array).CopyColumns();
	ResultingSeriesTable = ResultingTable.CopyColumns();
	
	For Each Warehouse In TableWarehouses Do
		
		FactOfAcceptance = Documents.DiscrepancyReportFollowingReceipt.FillActual(
			Object,
			Warehouse,
			AccumulationRegisters.GoodsToReceive,
			Undefined);
		CommonClientServer.SupplementTable(FactOfAcceptance.ResultingTable, ResultingTable);
		CommonClientServer.SupplementTable(FactOfAcceptance.ResultingSeriesTable, ResultingSeriesTable);
		
	EndDo;
	
	Object.Goods.Load(ResultingTable);
	Object.SetOfSeries.Load(ResultingSeriesTable);
	
	// Updating the series indication statuses.
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters);
	Documents.DiscrepancyReportFollowingReceipt.UpdateDependentDetailsAfterFillingInFactOfAcceptance(Object);
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	VATIsNotRecorded = DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	LinesBeforeChange = Undefined;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate =
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
			PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
				PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Then
		
		If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
			StructureOfActions.Insert("FillInTermsOfPurchase",
				BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInPurchasePrice",
				BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
		EndIf;
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	EndIf;
	
	If Not VATIsNotRecorded Then
		
		StructureOfRecalculationOfAmount = 
			BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	DataBeforeProcessing = New Map;
	RowsToProcess = New Array;
	
	For Each LineProducts_ In Object.Goods Do

		If Not ValueIsFilled(LineProducts_.DocumentBasis) Then
			SelfServiceClientServer.FillInDocumentBaseInLine(LineProducts_, BasisDocuments, False);
		EndIf;
		
		If Not ValueIsFilled(LineProducts_.VendorPriceKind) Then
			
			If LinesBeforeChange = Undefined Then
				LinesBeforeChange = CreateStructureForRowDataBeforeModification();
			EndIf; 
			
			FillPropertyValues(LinesBeforeChange, LineProducts_);
			
			// an attempt to fill in the types of prices according to the documents of the basis and calculation of amounts
			
			DataBeforeProcessing.Insert(LineProducts_, New FixedStructure(LinesBeforeChange));
			RowsToProcess.Add(LineProducts_);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each LineProducts_ In RowsToProcess Do
		If LineProducts_.Price = 0 Then
			FillPropertyValues(LineProducts_, DataBeforeProcessing.Get(LineProducts_));
		EndIf;
	EndDo;

	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
 		
		FillInDetailsOfMultiTurnContainer();
		
	EndIf;

	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisObject);
	
	// Post-processing is individual for the document
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);

	Return True;
	
EndFunction

&AtServer
Function CreateStructureForRowDataBeforeModification()
	
	StringStructure = New Structure();
	ColumnsGoodsTable = Object.Goods.Unload(New Array()).Columns;
	
	For Each Column In ColumnsGoodsTable Do
		StringStructure.Insert(Column.Name);
	EndDo;
	
	Return StringStructure;
	
EndFunction

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	DiscrepanciesServer.ProcessingSelectionOfSelectionOnServer(ThisObject, CachedValues, ValueSelected, False);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	SelfServiceServer.GetUploadedProductsFromStorage(ThisObject,
																CachedValues,
																GoodsAddressInStorage,
																False);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	LinesToDelete = New Array();
	ReadyForProcessing_ = New Array();
	
	For Each StringTSGoods In Object.Goods Do
		If StringTSGoods.ItemsType = Enums.ItemsTypes.OwnGoods
			Or StringTSGoods.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			ReadyForProcessing_.Add(StringTSGoods);
		Else
			LinesToDelete.Add(StringTSGoods); 
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	For Each RowToDelete In LinesToDelete Do
		Object.Goods.Delete(RowToDelete);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");

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
Procedure ProcessSelectionOfDocuments(ArrayOfDocuments, FillOptionParameter)

	FillingVariant = FillOptionParameter;
	DiscrepanciesServer.GenerateTableOfDocumentsOfBases(ThisObject, ArrayOfDocuments);
	FillInByBasis();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FillInDetailsOfMultiTurnContainer();
	
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);

EndProcedure

&AtServer
Procedure CompleteVATTaxation(TaxationOfVATSales = True, TaxationOfVATPurchases = True)
	
	If DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) And TaxationOfVATPurchases Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInVATTaxationPurchases(Object);
		VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer And  TaxationOfVATSales Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	EndIf;
	
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
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);

	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If LineOfATabularSection.FilledUsingBaseDocument Then
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

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.AdditionalAttributesInfo

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

// End StandardSubsystems.AdditionalAttributesInfo

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Other

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtClient
Procedure ManagerSCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject,
	                                          "ManagerComment",
	                                          "ThereIsAManagerComment",
	                                          "ProductsManagerSCommentBasement");

EndProcedure

&AtClient
Procedure VendorCommentStartOfSelection()

	DiscrepanciesClient.CommentStartChoice(ThisObject,
	                                          "VendorSComment",
	                                          "ThereIsSupplierComment",
	                                          "ProductsSupplierSCommentBasement");

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseDocumentCorrection     = GetFunctionalOption("UseDocumentCorrection");
	UseDebitNotes = GetFunctionalOption("UseDebitNotes");
	
	DiscrepanciesServer.SetValuesOfCachedReportFormDetails(ThisObject);
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	ManagingFormDetailsDependingOnBaseType();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingReceipt));
	SetVisibilityOfSeriesElements();
	
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance(Object);
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Object);
	SetVisibilityForReflection();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	DiscrepanciesServer.FormationOfInscriptionDocumentsBase(ThisObject);
	DiscrepanciesServer.DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(ThisObject);
	CreateOrdersTransactionsTable();
	DiscrepanciesServer.SetContractAvailability(ThisObject);
	DiscrepanciesServer.VATVisibilityManagement(ThisObject);
	DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance(Object);
	SetVisibilityOfElementsByOperationServer();
	DiscrepanciesClientServer.CalculateFormTotals(ThisObject);
		
	DiscrepanciesServer.FormInscriptionToReflectDiscrepancies(
		ThisObject,
		Object.Goods,
		Items.DiscrepancyLabel,
		Items.IssueDocuments,
		TypeOf(Object.Ref),
		OperationType());
	Items.GroupRecordMethod.Enabled = Items.DiscrepancyLabel.Enabled;
	DiscrepanciesClientServer.AvailabilityControl(ThisObject);
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		Object.BusinessOperation = PredefinedValue(
			"Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
	EndIf;
	If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Object.BusinessOperation = Handler.BusinessOperation();
	EndIf;

	FillingVariant = "Variant1";
	
	ShowExplanation = GetFunctionalOption("UseDebitNotes")
			And (Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice);
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		SalesServer.SetBlankContractMark(Items, "Contract");
		If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			Items.ProductsFillInAcceptanceCertificate.Visible = False;
		EndIf;
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		SalesServer.SetBlankContractMark(Items, "Contract", True);
		If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			Items.ProductsFillInAcceptanceCertificate.Visible = False;
		EndIf;
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		SalesServer.SetBlankContractMark(Items, "Contract", Not Handler.CustomerAgreementsAreApplicable());
		If Not Handler.UseAdvancedFeaturesOfSalesOrder() Then
			Items.ProductsFillInAcceptanceCertificate.Visible = False;
		EndIf;
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInVATTaxationPurchases(Object);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
		
	EndIf;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		
		FillInDetailsOfMultiTurnContainer();
		
	EndIf;
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure CreateOrdersTransactionsTable()

	TransactionOrders.Clear();
	
	ArrayOfOrdersToSupplier = New Array;
	For Each StringBase In BasisDocuments Do
		For Each ListItem In StringBase.BasisOrders Do
			If TypeOf(ListItem.Value) = Type("DocumentRef.PurchaseOrder") 
				And ArrayOfOrdersToSupplier.Find(ListItem.Value) = Undefined Then
			 ArrayOfOrdersToSupplier.Add(ListItem.Value);
			EndIf;
		EndDo;
	EndDo;
	
	If ArrayOfOrdersToSupplier.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	PurchaseOrder.Ref AS PurchaseOrder,
	|	PurchaseOrder.SalesOpportunity AS SalesOpportunity
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN (&AnArrayOfOrders)";
	
	Query.SetParameter("AnArrayOfOrders", ArrayOfOrdersToSupplier);
	
	TransactionOrders.Load(Query.Execute().Unload());

EndProcedure 

&AtServer
Function OperationType()
	
	TwoWayOperations = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
	
	If Object.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries
		And TwoWayOperations.Find(Object.BusinessOperation) <> Undefined Then
		Return "TwoWayRegistrationOfAdjustments";
	Else
		Return "";
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function EconomicImportOperations()
	
	EconomicImportOperations = New ValueList;
	EconomicImportOperations.Add(
		PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	EconomicImportOperations.Add(
		PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
	
	Return EconomicImportOperations;
	
EndFunction

&AtServer
Procedure AgreementWhenModifiedOnServer(DirectModificationOfContractField = False)
	
	If ContractBeforeModifications <> Object.Contract Then
		ReferenceOrder = OrderToReceiveOptionOfAcceptanceOfGoods();
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Object.Contract);
		CompleteVATTaxation();
		WhenChangingVATTaxationServer();
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If QualityControl.UpdateActionParameters(
			Documents.DiscrepancyReportFollowingReceipt,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Function OrderToReceiveOptionOfAcceptanceOfGoods()
	
	OptionOfAcceptanceOfGoodsContract = Common.ObjectAttributeValue(Object.Contract, "GoodsReceiptOption");
	If Object.Terms <> Undefined
		And TypeOf(Object.Terms) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		OptionOfAcceptanceOfGoodsAgreement = Common.ObjectAttributeValue(Object.Terms, "GoodsReceiptOption");
	Else
		OptionOfAcceptanceOfGoodsAgreement = Enums.GoodsReceiptOptions.EmptyRef();
	EndIf;
	AdvancedWarehousingOnReceiving = AdvancedWarehousingOnReceiving();
	
	If Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(OptionOfAcceptanceOfGoodsContract)
		And AdvancedWarehousingOnReceiving Then
		Return Object.Contract;
	ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(OptionOfAcceptanceOfGoodsAgreement)
		And AdvancedWarehousingOnReceiving Then
		Return Object.Terms;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function AdvancedWarehousingOnReceiving()
	
	TableWarehouses = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnReceiving = WarehousesServer.ThereIsOrderForReceiptWarehouse(TableWarehouses, Object.Date);
	
	Return AdvancedWarehousingOnReceiving;
	
EndFunction

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	If QualityControl.UpdateActionParameters(
			Documents.DiscrepancyReportFollowingReceipt,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfMultiTurnContainer()
	
	CurFoundationDocument = Undefined;
	FoundRow = Undefined;
	For Each RowOfProductsTable In Object.Goods Do
		
		If CurFoundationDocument <> RowOfProductsTable.DocumentBasis Then
			CurFoundationDocument = RowOfProductsTable.DocumentBasis;
			FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurFoundationDocument));		
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
			Else	
				FoundRow = Undefined;
			EndIf;
		EndIf;
		
		If FoundRow <> Undefined Then
			FillInMultiTurnContainerDetailsInLine(
				Object.TypeOfBaseDocumentForNonConformanceCertificate, RowOfProductsTable, FoundRow);
		EndIf;
	
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInMultiTurnContainerDetailsInLine(TypeOfBasisOfAct, RowOfProductsTable, StringFoundationDocuments)
	If TypeOfBasisOfAct =
				PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice") Then
		RowOfProductsTable.ToReturnReusablePackage = StringFoundationDocuments.ToReturnReusablePackage;
		RowOfProductsTable.PackageDepositIsRequired 	  = StringFoundationDocuments.PackageDepositIsRequired;	
	EndIf; 
EndProcedure

// Parameters:
// 	ValueSelected - CatalogRef.ProductCrossReferences 
// 	AdditionalParameters - Structure:
//		* FormItem - FormItems
//		* CurrentRow - LineOfATabularSection - current row of the table part
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServer
Procedure FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer()
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT =
		Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
	
EndProcedure

#EndRegion

#Region Texts

&AtServer
Function TextOfActionOptionForOtherExpensesAndAtExpenseOfThirdPartyCompany(BusinessOperation)
	
	If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		TextOfActionOption = NStr("vi = 'Ghi giảm vào tài khoản công ty bên thứ ba';
									|ru = 'Списать за счет сторонней компании';
									|en = 'Write off at the expense of the third party'; fa = 'Write off at the expense of the third party';
									|it = 'Stornare a spese di una società terza';
									|pl = 'Rozchodować na koszt firmy zewnętrznej';
									|tr = 'Üçüncü taraf şirketin hesabına yaz'");
	Else
		TextOfActionOption = NStr("vi = 'Ghi giảm vào tài khoản của nhà cung cấp';
									|ru = 'Списать за счет поставщика';
									|en = 'Write off at vendor''s expense'; fa = 'اسقاط به هزینه فروشنده';
									|it = 'Stornare a spese di una società terza';
									|pl = 'Write off at vendor''s expense';
									|tr = 'Tedarikçi hesabına yaz'");
	EndIf;
	
	Return TextOfActionOption;
	
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
