#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			Or Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale Then
		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date); 
	Else 
		Items.TraceableProductsPage.Visible = False;
	EndIf;
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.TraceableGoodsCCDNumber.Name, True);
	EndIf;
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	SetupParameters = Documents.CustomerInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisForm, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.SaleToAssociatedPerson);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure IncomeRentalComponentOfContractOnChange(Item)
	
	If Items.Income.CurrentData <> Undefined Then
		If Items.Income.CurrentData.RentalComponentOfContract = False Then
			Items.Income.CurrentData.RentalObject = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	SetupParameters = Documents.CustomerInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisForm, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.SaleToAssociatedPerson);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
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
	
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
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

	OnReadCreateAtServer();
	
	
	GLAccountSettingsServer.AfterWriteAtServer(ThisForm);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisForm);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_CustomerInvoiceServicesAndAssets", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
		
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	EndIf;
	
	If VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter);
	EndIf;
	
	If EventName = "AddingPartnerToSegment"
		Or EventName = "RemovingPartnerFromSegment" Then
		
		SetVisibilityOfShipmentBanToPartner();
	EndIf;
	
	If EventName = "Write_SaleAdjustment"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		UpdateInvoiceText();
	EndIf;
	If EventName = "Write_ApplicationForImportOfGoodsReceived"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Basis1.Find(Object.Ref) <> Undefined Then
		UpdateInvoiceText();
	EndIf;
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
   // StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands	
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	Return; // WE have an empty handler

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
EndProcedure

&AtClient
Procedure SaleBasedOnOnChange(Item)
	If Object.SaleBasedOn Then
		
		TypesList = New ValueList;
		
		If CAAccounting24IsUsed Then
			If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle") Then
			
				TypesList.Add("Document.PreparingForFixedAssetSale2_4.ChoiceForm", NStr("vi = 'Chuẩn bị chuyển giao TSCĐ hữu hình';
																						|ru = 'Подготовка к передаче ОС';
																						|en = 'Prepare for sale of fixed assets'; fa = 'آماده‌سازی برای فروش دارایی‌های ثابت';
																						|it = 'preparazione al trasferimento del capitale fisso';
																						|pl = 'Przygotowanie do przekazania środków trwałych';
																						|tr = 'sabit kıymet satışına hazırlık'"));
			Else
				TypesList.Add("Document.PreparingForIntangibleAssetSale2_4.ChoiceForm", NStr("vi = 'Chuẩn bị chuyển giao TSCĐ vô hình';
																							|ru = 'Подготовка к передаче НМА';
																							|en = 'Retire intangible assets'; fa = 'کنارگذاری دارایی‌های نامشهود';
																							|it = 'Preparazione al trasferimento dei Beni immateriali';
																							|pl = 'Przygotowanie do przekazania wartości niematerialnych';
																							|tr = 'Maddi olmayan varlıkların çekilmesi'"));
				TypesList.Add("Document.PreparingForFixedAssetSale2_4.ChoiceForm", NStr("vi = 'Chuẩn bị chuyển giao TSCĐ hữu hình';
																						|ru = 'Подготовка к передаче ОС';
																						|en = 'Prepare for sale of fixed assets'; fa = 'آماده‌سازی برای فروش دارایی‌های ثابت';
																						|it = 'preparazione al trasferimento del capitale fisso';
																						|pl = 'Przygotowanie do przekazania środków trwałych';
																						|tr = 'sabit kıymet satışına hazırlık'"));
			EndIf;
		EndIf; 
			
		CustomerInvoiceServicesAndAssetsClientLocalization.AddToListOfBaseTypes(ThisForm, TypesList);

		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle") Then
			
			SelectingBaseDocumentType(TypesList[0], Undefined);
			
		Else
			
			TypesList.ShowChooseItem(
				New CallbackDescription("SelectingBaseDocumentType", ThisForm),
				NStr("vi = 'Chứng từ cơ sở';
					|ru = 'Документ основание';
					|en = 'Base document'; fa = 'سند مبنا';
					|it = 'Documento casuale';
					|pl = 'Dokument źródłowy';
					|tr = 'Temel belge'"));
				
		EndIf; 
		
	Else
		Object.DocumentBasis = Undefined;
		FillOperationSelectionList();
	EndIf;
	Return; // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure SelectingBaseDocumentType(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.SaleBasedOn = False;
	Else
		OpenForm(Result.Value, , ThisForm, ThisForm,,, New CallbackDescription("SelectingFoundationDocument", ThisForm));
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingFoundationDocument(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		Object.DocumentBasis = Result;
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle") 
			And CAAccounting24IsUsed 
			And (TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForFixedAssetSale2_4")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForIntangibleAssetSale2_4")) Then
				
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer");
			WhenBusinessTransactionChangesServer();
			
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer") 
			And CAAccounting24IsUsed 
			And (TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForFixedAssetSale2_4")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForIntangibleAssetSale2_4")) Then
			
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.NonCurrentAssetsSale");
			WhenBusinessTransactionChangesServer();
			
		EndIf;
	Else
		Object.SaleBasedOn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "PageGeneral" Then
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	If CurrentPage = Items.Pages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	If ValueIsFilled(Object.Partner) Then
		PartnerOnChangeServer();
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
		RecalculateAmountsByCurrency();
	Else
		SetVisibilityOfShipmentBanToPartner();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	RecalculateAmountsByCurrency();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	RecalculateAmountsByCurrency();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.NonCurrentAssetsSale")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle") Then
			
		NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	EndIf;
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	
	If Not (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.NonCurrentAssetsSale")) 
		And FilledWithTSTraceableGoods() Then
		
		QueryText = 
		NStr("vi = 'Phần bảng ""Hàng hóa có truy xuất nguồn gốc"" không trống.
		|Khi chuyển giao dịch kinh tế, phần bảng ""Hàng hóa có truy xuất nguồn gốc"" sẽ bị xóa.';
		|ru = 'Табличная часть ""Прослеживаемые товары"" не пустая.
		|При переключении хозяйственной операции табличная часть ""Прослеживаемые товары"" будет очищена.';
		|en = 'The ""Traceable goods"" table is not empty.
		|The ""Traceable goods"" table will be cleared when switching the business transaction.'; fa = 'The ""Traceable goods"" table is not empty.
		|The ""Traceable goods"" table will be cleared when switching the business transaction.';
		|it = 'La parte tabellare ""Articoli tracciabili"" non è vuota.
		|Alla riattivazione dell''operazione commerciale, la parte tabellare ""Articoli tracciabili"" sarà cancellata.';
		|pl = 'Sekcja tabelaryczna ""Towary identyfikowalne"" nie jest pusta.
		|Przy przełączeniu operacji gospodarczej sekcja tabelaryczna ""Towary identyfikowalne"" zostanie wyczyszczona.';
		|tr = '""İzlenebilir ürünler"" tablo kısmı boş değildir.
		|Bir ticari işlemi değiştirdiğinizde, ""İzlenebilir ürünler"" tablo kısmı temizlenir.'");
		
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'"));
		QuestionParameters = New Structure;
		QuestionParameters.Insert("Picture", PictureLib.Information32);
		QuestionParameters.Insert("Title",
		NStr("vi = 'Cảnh báo khi xóa phần bảng';
			|ru = 'Предупреждение об очистке табличной части';
			|en = 'Warning about the table cleanup'; fa = 'Warning about the table cleanup';
			|it = 'Notifica sulla cancellazione della parte tabellare';
			|pl = 'Ostrzeżenie o wyczyszczeniu sekcji tabelarycznej';
			|tr = 'Masa parçasının temizlenmesi hakkında uyarı'"));
		HandlerResults_1 = New CallbackDescription("ProcessResponseToWarningAboutClearingTablePart", ThisObject);
		StandardSubsystemsClient.ShowQuestionToUser(
		HandlerResults_1, QueryText, Buttons, QuestionParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResponseToWarningAboutClearingTablePart(Response, AdditionalParameters) Export
	
	If Response = Undefined Or Response.Value = "Cancel" Then
		Return;
	ElsIf Response.Value = "Continue" Then
			
		ClearTabularPartOfTraceableGoods();
		Items.TraceableProductsPage.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearTabularPartOfTraceableGoods()
	
	Object.TraceableGoods.Clear();
	
EndProcedure

&AtServer
Function FilledWithTSTraceableGoods()
	
	FilledIn = False;
	
	TraceableGoods = Object.TraceableGoods;
	If TraceableGoods.Count()> 0 Then
		
		FilledIn = True;
		
	EndIf;
	
	Return FilledIn;
	
EndFunction   

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or Object.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices
			Then
		Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.Shipped
			Or Object.Status = Enums.StatusesOfCustomerInvoices.EmptyRef() Then
			Object.Status = Enums.StatusesOfCustomerInvoices.InTransit;
		EndIf;
		
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
		And Object.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		
		Items.Expenses.AutoMarkIncomplete = False;
		Items.Expenses.MarkIncomplete = False;
	Else
		Items.Expenses.AutoMarkIncomplete = True;
	EndIf; 
	
	If Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			Or Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale Then
		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);
	Else 
		Items.TraceableProductsPage.Visible = False;
	EndIf;

	If Object.SaleBasedOn
		And ((TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForFixedAssetSale2_4")
					Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForIntangibleAssetSale2_4"))
				And Object.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
				And Object.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			Or CustomerInvoiceServicesAndAssetsLocalization.ItIsRequiredToCleanUpImplementationBasedOn(Object)) Then
		Object.SaleBasedOn = False;
		Object.DocumentBasis = Undefined;
	EndIf; 
	
	// Deleting lines from the NMA, if they are not provided for by the household. operations.
	If Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		TheStructureOfTheSearch = New Structure("AssetKind", Enums.KindsOfNonCurrentAssets.IA);
		StringsList = Object.Expenses.FindRows(TheStructureOfTheSearch);
		For Each RowData In StringsList Do
			Object.Expenses.Delete(RowData);
		EndDo;
	EndIf; 
	
	EstablishVisibilityOfSathyaAssetLiability();
	SetTitleOfExpensesPage();
	
	ConfigureDependentFormElementsOnServer("BusinessOperation");
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	SetupParameters = Documents.CustomerInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisForm, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.SaleToAssociatedPerson);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextOfTheInvoiceIssuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssued(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);

	FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing);
	
	TextURLProcessing(Item, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	PriceIncludesVATOnChangeServer(CachedValues);
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	VATTaxationOnChangeServer();
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelCurrenciesClickCompletionServer(ClosingResult);
			If ChangedBankingDetails.Property("Currency") Then
				PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
		Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
		CustomizeFormElements();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisForm,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure TraceableGoodsItemOnChange(Item)
	
	CurrentData = Items.TraceableGoods.CurrentData;
	
	If Not ValueIsFilled(CurrentData.Products) Then
		Return;	
	EndIf;
	
	CurrentData.ProductName = ProductName(CurrentData.Products);
	
EndProcedure

&AtClient
Procedure TraceableGoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.TraceableGoods.CurrentData;
	
	If Not ValueIsFilled(CurrentData.CCDNumber) Then
		Return;	
	EndIf;
	
	TheseNumbersAreCCD = TheseNumbersAreCCD(CurrentData.CCDNumber);
	
	FillPropertyValues(CurrentData, TheseNumbersAreCCD);

EndProcedure

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	CustomerInvoiceServicesAndAssetsClientLocalization.OnChangeAttribute(Item.Name, ThisForm);

EndProcedure

#EndRegion

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInVATTaxationATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIncome

&AtClient
Procedure IncomeCountOnChange(Item)
	Actions = New Structure;
	AddActionsForRecalculatingAmounts(Actions, Object, Items.Income.CurrentData);
	If Items.Income.CurrentData.Count = 0 Then
		Items.Income.CurrentData.Sum = Items.Income.CurrentData.Price;
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Income.CurrentData, Actions, CachedValues);
EndProcedure

&AtClient
Procedure IncomePriceOnChange(Item)
	Actions = New Structure;
	AddActionsForRecalculatingAmounts(Actions, Object, Items.Income.CurrentData);
	If Items.Income.CurrentData.Count = 0 Then
		Items.Income.CurrentData.Sum = Items.Income.CurrentData.Price;
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Income.CurrentData, Actions, CachedValues);
EndProcedure

&AtClient
Procedure IncomeSumOnChange(Item)
	Actions = New Structure;
	AddVATRecalculationActions(Actions, Object);
	If Items.Income.CurrentData.Count = 0 Then
		Items.Income.CurrentData.Price = Items.Income.CurrentData.Sum;
	Else	
		Actions.Insert("RecalculatePriceDiscountByAmountInSales", New Structure("QuantityName", "Count"));
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Income.CurrentData, Actions, CachedValues);
EndProcedure

&AtClient
Procedure IncomeVATAmountOnChange(Item)
	Actions = New Structure;
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	Actions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Income.CurrentData, Actions, CachedValues);
EndProcedure

&AtClient
Procedure IncomeVATRateOnChange(Item)
	Actions = New Structure;
	AddActionsForRecalculatingAmounts(Actions, Object, Items.Income.CurrentData);
	If Items.Income.CurrentData.Count = 0 Then
		Items.Income.CurrentData.Sum = Items.Income.CurrentData.Price;
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Income.CurrentData, Actions, CachedValues);
EndProcedure

&AtClient
Procedure IncomeIncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure IncomeIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure IncomeOnStartEdit(Item, NewRow, Copy)
	CurrentData = Items.Income.CurrentData;
	If NewRow And Not Copy Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Income");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExpenses

&AtClient
Procedure OtherExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return; // Empty handler for UT
	
EndProcedure

&AtClient
Procedure ExpensesExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesAssetAndLiabilityItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesAssetAndLiabilityItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
EndProcedure

&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)

	TableRow = Item.CurrentData;
	If NewRow And Not Copy Then
		TableRow.AssetKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.FixedAsset");
		TableRow.NonCurrentAsset = PredefinedValue("Catalog.Assets.EmptyRef");
	//Setting up accounting accounts 
	ElsIf NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
	If TableRow.AssetKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.IA") Then
		Items.ExpensesNonCurrentAsset.TypeRestriction = New TypeDescription("CatalogRef.IntangibleAssets");
	Else
		Items.ExpensesNonCurrentAsset.TypeRestriction = New TypeDescription("CatalogRef.Assets");
	EndIf; 
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Expenses");
	
EndProcedure

&AtClient
Procedure ExpensesAssetKindOnChange(Item)
	
	TableRow = Items.Expenses.CurrentData;
	If TableRow.AssetKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.FixedAsset") Then
		TableRow.NonCurrentAsset = PredefinedValue("Catalog.Assets.EmptyRef");
	Else
		TableRow.NonCurrentAsset = PredefinedValue("Catalog.IntangibleAssets.EmptyRef");
		TableRow.ReverseBonusDepreciation = False;
		TableRow.AmountOfDepreciationAllowance = Undefined;
		TableRow.IncomeItem = Undefined;
		TableRow.DimensionOfRevenue = Undefined;
	EndIf;
	
	If TableRow.AssetKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.IA") Then
		Items.ExpensesNonCurrentAsset.TypeRestriction = New TypeDescription("CatalogRef.IntangibleAssets");
	Else
		Items.ExpensesNonCurrentAsset.TypeRestriction = New TypeDescription("CatalogRef.Assets");
	EndIf; 
	
	Return; // the UT has an empty handler.
	
EndProcedure

&AtClient
Procedure ExpensesIncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
EndProcedure

&AtClient
Procedure ExpensesReverseBonusDepreciationOnChange(Item)
	
	RowData = Items.Expenses.CurrentData;
	
	If Not RowData.ReverseBonusDepreciation Then
		RowData.AmountOfDepreciationAllowance = Undefined;
		RowData.IncomeItem = Undefined;
		RowData.DimensionOfRevenue = Undefined;
	EndIf; 
	
EndProcedure

&AtClient
Procedure ExpensesSumOnChange(Item)
	CurrentRow = Items.Expenses.CurrentData;
	CurrentRow.SumCompl = Round(CurrentRow.Sum * FactorOfConversionFromManCurrencyToRegulCurrency, 2, 1);
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Income;
	TableData = Object.Income;
	
	If FormTable.CurrentData = Undefined Then
		Return;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Sum, VATAmount, AmountIncludingVAT");
	BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "Count";
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	CurrentRow = Items.Income.CurrentData;
	If NewRow <> Undefined Then
		StructureOfActions = New Structure;
		AddActionsForRecalculatingAmounts(StructureOfActions, Object, NewRow);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVATRate(Command)
	If Object.Income.Count()>0 Then
		FormParameters = New Structure;
		FormParameters.Insert("VATTaxationType", Object.VATTaxation);
		FormParameters.Insert("UpdateDate", Object.Date);
		OpenForm("Catalog.VATRates.ChoiceForm", 
			FormParameters,,,,, 
			New CallbackDescription("SetVATRateCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure SetVATRateCompletion(Result, AdditionalParameters) Export
    
    VATRate = Result;
    If ValueIsFilled(VATRate) Then
        SetVATRateServer(VATRate, CachedValues);
    EndIf;

EndProcedure

&AtClient
Procedure SetTheIncomeItem(Command)
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.IncomeIncomeItem, Items.Income.SelectedRows);
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails(False);
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	CustomerInvoiceServicesAndAssetsClientLocalization.OnExecuteCommand(Command, ThisForm);

EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
EndProcedure

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


&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentSettlement);
	
EndProcedure

&AtClient
Procedure FillInAccordingToRentalSchedule(Command)
	If Not CheckSelectionFields() Then
		Return;
	EndIf;
	
	FillInAccrualsOnServer();
	
	If Not Object.Income.Count() Then
		Text = StrTemplate(NStr("vi = 'Theo hợp đồng ""%1"" không có lịch biểu tính lãi %2';
								|ru = 'По договору ""%1"" отсутствует график начислений на %2';
								|en = 'There is no accruals schedule for %2 as per contract ""%1""'; fa = 'There is no accruals schedule for %2 as per contract ""%1""';
								|it = 'Per l''accordo ""%1"" manca il grafico di maturazione per %2';
								|pl = 'Dla umowy ""%1"" nie ma harmonogramu naliczeń na %2';
								|tr = '%2 sözleşme için %1''lik bir tahakkuk çizelgesi bulunmamaktadır'"),
			Object.Contract,
			Format(Object.Date, "DLF=D;"));
		CommonClient.MessageToUser(Text);
	Else
		Modified = True;
	EndIf;
	Return; // The UT handler is empty

EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

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

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region DateOfTransferOfTitleToGoods
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfTransferOfTitleToGoods.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfCustomerInvoices.Shipped;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfTransferOfTitleToGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfTransferOfTitleToGoods.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfCustomerInvoices.Shipped;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfTransferOfTitleToGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "IncomeAmountIncludingVAT");
	
	//

	VATAccountingERP.EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(ThisForm, "Income", False);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm,
		"IncomeVATRate",
		"IncomeVATAmount",
		"IncomeAmountIncludingVAT");
	
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.NonCurrentAssetsSale);
	TransactionList.Add(Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
	ItemFilter.RightValue = TransactionList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#Region UnavailabilityOfDepreciationPremiumFieldsForIA
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesReverseBonusDepreciation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesAmountOfDepreciationAllowance.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesIncomeItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesDimensionOfRevenue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Expenses.AssetKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.KindsOfNonCurrentAssets.FixedAsset;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region UnavailabilityOfDepreciationPremiumFieldsIfFlagIsUnchecked
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesAmountOfDepreciationAllowance.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesIncomeItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesDimensionOfRevenue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Expenses.ReverseBonusDepreciation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region UnavailabilityOfRentalObjectField
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeRentalObject.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Income.RentalComponentOfContract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	//
	
EndProcedure

&AtServerNoContext
Function ProductName(Val Products)
	
	Return Common.ObjectAttributeValue(Products, "DescriptionFull")
		
EndFunction

&AtServerNoContext
Function TheseNumbersAreCCD(Val CCDNumber)
		
	Return Common.ObjectAttributesValues(CCDNumber, "Products, ProductName"); 
	
EndFunction

&AtServer
Procedure FillInVATTaxationATServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return; // WE have an empty handler
	
EndProcedure

#EndRegion
#Region FillingInAccordingToScheduleOfPaymentsForLeasedFA

&AtClient
Function CheckSelectionFields()
	
	HasErrors = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Contract) Then
		Text = NStr("vi = 'Để điền tính lãi, cần chỉ ra doanh nghiệp';
					|ru = 'Для заполнения начислений требуется указание договора';
					|en = 'Specify the contract to fill in accruals'; fa = 'Specify the contract to fill in accruals';
					|it = 'Per la compilazione delle maturazioni è necessario indicare l''accordo';
					|pl = 'Dla wypełnienia naliczeń należy podać umowę';
					|tr = 'Tahakkukları doldurmak için, sözleşmenin bir göstergesi gereklidir'");
		CommonClient.MessageToUser(Text,, "Contract", "Object", HasErrors);
	EndIf;
	
	If Not ValueIsFilled(Object.Date) Then
		Text = NStr("vi = 'Để điền tính lãi, cần chỉ ra ngày chứng từ';
					|ru = 'Для заполнения начислений требуется указание даты документа';
					|en = 'Specify the document date to fill in accruals'; fa = 'Specify the document date to fill in accruals';
					|it = 'Per la compilazione delle maturazioni è necessario indicare la data del documento';
					|pl = 'W celu wypełnienia naliczeń wymagane jest podanie daty dokumentu';
					|tr = 'Tahakkukları doldurmak için belgenin tarihini belirtmeniz gerekir'");
		CommonClient.MessageToUser(Text,, "Date", "Object", HasErrors);
	EndIf;
	
	// The document currency must correspond to the settlement currency of the Contract.
	If Object.Currency <> Object.ARAPCurrency Then
		MessageTemplate = NStr("vi = 'Để điền tính lãi, chứng từ cần theo tiền tệ hạch toán của hợp đồng (%1)';
								|ru = 'Для заполнения начислений документ должен быть в валюте взаиморасчетов договора (%1)';
								|en = 'To fill the charges, the document must be in the AR/AP accounting currency (%1)'; fa = 'To fill the charges, the document must be in the AR/AP accounting currency (%1)';
								|it = 'Для заполнения начислений документ должен быть в валюте взаиморасчетов договора (%1)';
								|pl = 'To fill the charges, the document must be in the AR/AP accounting currency (%1)';
								|tr = 'Tahakkukların doldurulması için belgenin, sözleşmenin alacak/borç muhasebesi para biriminde (%1) olması gerekir'");
		Text = StrTemplate(MessageTemplate, Object.ARAPCurrency);
		CommonClient.MessageToUser(Text,, "Currency", "Object", HasErrors);
	EndIf;
	
	Return Not HasErrors;
	
EndFunction

&AtServer
Procedure FillInAccrualsOnServer()
	
	Object.Income.Clear();
	
	QueryText = 
	"SELECT
	|	AssetsLeasedOutSliceLast.FixedAsset AS FixedAsset
	|INTO TTLeasedToFA
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(&Boundary, Organization = &Organization) AS
	|		AssetsLeasedOutSliceLast
	|WHERE
	|	AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND AssetsLeasedOutSliceLast.Contract = &Contract
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfChargesForIncomeRentalServices.ChangeDate AS ChangeDate,
	|	ScheduleOfChargesForIncomeRentalServices.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleOfChargesForIncomeRentalServices.RentalService AS RentalService,
	|	ScheduleOfChargesForIncomeRentalServices.Contract AS Contract,
	|	ScheduleOfChargesForIncomeRentalServices.Date AS Date,
	|	ScheduleOfChargesForIncomeRentalServices.FixedAsset AS FixedAsset
	|INTO TTSchedulesOfAccrualOfServices
	|FROM
	|	InformationRegister.ScheduleOfChargesForIncomeRentalServices AS ScheduleOfChargesForIncomeRentalServices
	|WHERE
	|	ScheduleOfChargesForIncomeRentalServices.Contract = &Contract
	|	AND ScheduleOfChargesForIncomeRentalServices.FixedAsset IN
	|		(SELECT
	|			TTLeasedToFA.FixedAsset AS FixedAsset
	|		FROM
	|			TTLeasedToFA AS TTLeasedToFA)
	|	AND ScheduleOfChargesForIncomeRentalServices.Date <= &Date
	|	AND ScheduleOfChargesForIncomeRentalServices.ChangeDate <= &Date
	|
	|INDEX BY
	|	ChangeDate,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TTSchedulesOfAccrualOfServices.ChangeDate) AS ChangeDate,
	|	TTSchedulesOfAccrualOfServices.FixedAsset AS FixedAsset
	|INTO TTScheduleOfAccrualServicesPeriod
	|FROM
	|	TTSchedulesOfAccrualOfServices AS TTSchedulesOfAccrualOfServices
	|GROUP BY
	|	TTSchedulesOfAccrualOfServices.FixedAsset
	|
	|INDEX BY
	|	ChangeDate,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TTSchedulesOfAccrualOfServices.ChangeDate) AS ChangeDate,
	|	TTSchedulesOfAccrualOfServices.FixedAsset AS FixedAsset
	|INTO TTScheduleOfAccrualServicesInitialPeriod
	|FROM
	|	TTSchedulesOfAccrualOfServices AS TTSchedulesOfAccrualOfServices
	|GROUP BY
	|	TTSchedulesOfAccrualOfServices.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSchedulesOfAccrualOfServices.ChangeDate AS ChangeDate,
	|	TTSchedulesOfAccrualOfServices.RentalServiceVAT AS RentalServiceVAT,
	|	TTSchedulesOfAccrualOfServices.RentalService AS RentalService,
	|	TTSchedulesOfAccrualOfServices.Contract AS Contract,
	|	TTSchedulesOfAccrualOfServices.Date AS Date,
	|	TTSchedulesOfAccrualOfServices.FixedAsset AS FixedAsset
	|INTO CurrentScheduleOfAccrualOfServicesIsTT
	|FROM
	|	TTSchedulesOfAccrualOfServices AS TTSchedulesOfAccrualOfServices
	|		INNER JOIN TTScheduleOfAccrualServicesPeriod AS TTScheduleOfAccrualServicesPeriod
	|		ON TTSchedulesOfAccrualOfServices.ChangeDate = TTScheduleOfAccrualServicesPeriod.ChangeDate
	|		AND TTSchedulesOfAccrualOfServices.FixedAsset = TTScheduleOfAccrualServicesPeriod.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrentScheduleOfAccrualOfServicesIsTT.FixedAsset AS FixedAsset,
	|	MAX(CurrentScheduleOfAccrualOfServicesIsTT.Date) AS Date
	|INTO TTPreviousDatesOfSchedule
	|FROM
	|	CurrentScheduleOfAccrualOfServicesIsTT AS CurrentScheduleOfAccrualOfServicesIsTT
	|WHERE
	|	CurrentScheduleOfAccrualOfServicesIsTT.Date < &Date
	|GROUP BY
	|	CurrentScheduleOfAccrualOfServicesIsTT.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Schedule.FixedAsset AS RentalObject,
	|	Schedule.FixedAsset.DescriptionFull AS Description,
	|	CASE
	|		WHEN &PriceIncludesVAT
	|			THEN Schedule.RentalService
	|		ELSE Schedule.RentalService - Schedule.RentalServiceVAT
	|	END AS Price,
	|	CASE
	|		WHEN &PriceIncludesVAT
	|			THEN Schedule.RentalService
	|		ELSE Schedule.RentalService - Schedule.RentalServiceVAT
	|	END AS Sum,
	|	Schedule.RentalService AS AmountIncludingVAT,
	|	Schedule.Contract.VATRate AS VATRate,
	|	Schedule.RentalServiceVAT AS VATAmount,
	|	Schedule.RentalService AS AmountARAP,
	|	&IncomeDimensionForFinancialLeaseServices AS DimensionOfRevenue,
	|	&IncomeItemForFinancialLeaseServices AS IncomeItem,
	|	Schedule.Date AS Date,
	|	CASE
	|		WHEN NOT PreviousDates.Date IS NULL
	|			THEN DATEADD(PreviousDates.Date, DAY, 1)
	|		ELSE InitialPeriod.ChangeDate
	|	END AS StartDateOfRentalPeriod,
	|	TRUE AS RentalComponentOfContract,
	|	CAST(&IncomeItemForFinancialLeaseServices AS ChartOfCharacteristicTypes.IncomeItems).ValueType AS
	|		TypeOfArticleAnalytics
	|FROM
	|	CurrentScheduleOfAccrualOfServicesIsTT AS Schedule
	|		INNER JOIN TTScheduleOfAccrualServicesInitialPeriod AS InitialPeriod
	|		ON Schedule.FixedAsset = InitialPeriod.FixedAsset
	|		LEFT JOIN TTPreviousDatesOfSchedule AS PreviousDates
	|		ON Schedule.FixedAsset = PreviousDates.FixedAsset
	|WHERE
	|	Schedule.Date = &Date
	|	AND Schedule.RentalService - Schedule.RentalServiceVAT > 0
	|
	|ORDER BY
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", BegOfDay(Object.Date));
	Query.SetParameter("Boundary", New Boundary(EndOfDay(Object.Date),BoundaryType.Including));
	Query.SetParameter("PriceIncludesVAT", Object.PriceIncludesVAT);
	
	AccountingPolicyOfFinancialAccounting = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Object.Organization,
		BegOfDay(Object.Date));
	If ValueIsFilled(AccountingPolicyOfFinancialAccounting.IncomeItemForFinancialLeaseServices) Then
		IncomeItemForFinancialLeaseServices = AccountingPolicyOfFinancialAccounting.IncomeItemForFinancialLeaseServices;
	Else
		IncomeItemForFinancialLeaseServices = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	EndIf;
	Query.SetParameter("IncomeItemForFinancialLeaseServices", IncomeItemForFinancialLeaseServices);
	Query.SetParameter("IncomeDimensionForFinancialLeaseServices", AccountingPolicyOfFinancialAccounting.IncomeDimensionForFinancialLeaseServices);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	TypeOfFAAnalytics = New TypeDescription("CatalogRef.Assets");
	
	While Selection.Next() Do
		RevenueRow = Object.Income.Add();
		
		FillPropertyValues(RevenueRow, Selection);
		If Selection.TypeOfArticleAnalytics = TypeOfFAAnalytics Then
			RevenueRow.DimensionOfRevenue = Selection.RentalObject;
		EndIf;
		
		RevenueRow.Content = GenerateContentOfRentalLine(Selection);
		
	EndDo;

EndProcedure

&AtServer
Function GenerateContentOfRentalLine(Selection)
	
	ContentTemplate = NStr("vi = 'Dịch vụ thuê %1 trong kỳ từ %2 đến %3';
							|ru = 'Услуги аренды %1 за период с %2 по %3';
							|en = 'The %1 rental services for the period from %2 to %3'; fa = 'The %1 rental services for the period from %2 to %3';
							|it = 'Услуги аренды %1 за период с %2 по %3';
							|pl = 'The %1 rental services for the period from %2 to %3';
							|tr = '%2 ile %3 arasındaki dönem için %1 kiralama hizmetleri'");
	
	Content = StrTemplate(ContentTemplate,
								Selection.Description,
								Format(Selection.StartDateOfRentalPeriod,"DLF=D;"),
								Format(Selection.Date,"DLF=D;"));
	Return Content;
	
EndFunction

#EndRegion
#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	CAAccounting24IsUsed = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	FillOperationSelectionList();
	ConfigureDependentFormElementsOnServer("Date");
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	AttributesArray = New Array;
	AttributesArray.Add("Partner");
	
	If ToUseTermsOfSales Then
		Documents.CustomerInvoiceServicesAndAssets.FillInByPartner(Object, Object.Partner);
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	EndIf;
	FillInDefaultContract();
	SalesServer.PartnerOnChange(Object);
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInFormDetails();
	CustomizeFormElements();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetVisibilityOfShipmentBanToPartner();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	CustomerInvoiceServicesAndAssetsLocalization.PartnerOnChange(ThisForm);
	ConfigureDependentFormElementsOnServer("Partner");
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerOnChangeServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		SalesServer.PartnerOnChange(Object);
		FillInSubordinatePropertiesForStatistics("Counterparty");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInFormDetails();
	CustomizeFormElements();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	WhenChangingKeyDetailsStatusOfEDO();
	CustomerInvoiceServicesAndAssetsLocalization.CounterpartyOnChange(ThisObject);
	ConfigureDependentFormElementsOnServer("Counterparty");
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms);
	Documents.CustomerInvoiceServicesAndAssets.FillInByTermsOfSales(Object, SalesTermsAndConditions);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInFormDetails();
	CustomizeFormElements();
	FillOperationSelectionList();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	AttributesArray = New Array;
	AttributesArray.Add("Partner");
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	CustomerInvoiceServicesAndAssetsLocalization.TermsOnChange(ThisForm);
	ConfigureDependentFormElementsOnServer("Terms");
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		AttributesArray = New Array;
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Organization");
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	FillInFormDetails();
	CustomizeFormElements();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	WhenChangingKeyDetailsStatusOfEDO();
	ConfigureDependentFormElementsOnServer("Organization");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	If ValueIsFilled(Object.Contract) Then
		Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract,"ForeignCurrencyTransaction");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillInFormDetails();
	CustomizeFormElements();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount, "Count");
	RecalculationParameters.RecalculateAutomaticDiscounts = True;
	RecalculationParameters.RecalculateManualDiscounts         = True;
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Income,
		RecalculationParameters);
	
	TMCommonUseClientServer.FillInCollectionPropertyValues(Object.Income, 0, "AmountARAP");
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(CurrencyOld, CurrencyNew)
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, CurrencyOld,CurrencyNew, LocalAccountingCurrency, DocumentDate);
	CoursesAreOld = CourseStructures.StructureOfOldCurrencyRates;
	CoursesAreNew  = CourseStructures.StructureOfNewCurrencyRates;
	PriceManagementSystem.ConvertTabularAmountsToCurrency(
		Object.Income, Object.PriceIncludesVAT, CurrencyOld, CurrencyNew, CoursesAreOld, CoursesAreNew, , , "Count");
	TMCommonUseClientServer.FillInCollectionPropertyValues(Object.Income, 0, "AmountARAP");
EndProcedure

&AtClient
Procedure RecalculateAmountsByCurrency()
	If ValueIsFilled(Object.Currency) And DocumentCurrency<>Object.Currency And Object.Income.Count()>0 Then
		CurrencyOnChangeServer(DocumentCurrency, Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	DocumentCurrency = Object.Currency;
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(ValuesCache)
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	Actions = New Structure;
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	Actions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.TreatTS(Object.Income, Actions, ValuesCache);
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Income, StructureOfActions, CachedValuesInternal);
	
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	Actions = New Structure();
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	Actions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		Actions,
		Object.Income,
		Undefined);
	
	CustomizeFormElements();
	
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddVATRecalculationActions(Actions, Object)
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	Actions.Insert("ClearAmountOfSettlements");
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsForRecalculatingAmounts(Actions, Object, TSRow)
	AddVATRecalculationActions(Actions, Object);
	If TSRow.Count > 0 Then
		Actions.Insert("RecalculateAmount", "Count");
	EndIf;
	Actions.Insert("ClearAmountOfSettlements");
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And Not ValueIsFilled(Object.Contract) Then
		FillInDefaultContract();
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If "IssueCashReceipt" = Var_URL Then
		
		StandardProcessing = False;
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf "OpenRecordOfFiscalTransaction" = Var_URL Then
		
		StandardProcessing = False;
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref);
		
	ElsIf "ConfigureHardware_" = Var_URL Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	UpdateInvoiceText();
	
EndProcedure

#EndRegion

#Region NonCurrentAssets

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	ElsIf TypeOf(ChangedDetailsOrElement) = Type("FormField") Then
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If StructureOfChangedProps.Property("Date") Then

		If Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			Or Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale Then
			AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);
		EndIf;

	EndIf;
	
	CustomerInvoiceServicesAndAssetsLocalization.ConfigureDependentFormElements(ThisForm, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedDetailsOrElement = "")

	Object = Form.Object;
	
	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	ElsIf TypeOf(ChangedDetailsOrElement) = Type("FormField") Then
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	OnChangeAttributes(Form, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	AuxiliaryAttributes = New Structure;
	NonCurrentAssetsClientServerLocalization.SupplementAuxiliaryDetails_SaleOfServicesOfOtherAssets(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentDetails_SaleOfServicesOfOtherAssets(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_ImplementServicesOtherAssets(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") Then
			
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, ChangedBankingDetails)

	If ChangedBankingDetails = "" Then
		Return;
	EndIf;

	NonCurrentAssetsClientServerLocalization.WhenChangingDetails_SaleOfServicesOfOtherAssets(Form, ChangedBankingDetails);
	
EndProcedure
 
#EndRegion

#Region EAEUExports

&AtClient
Procedure TextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure UpdateTextsDocumentsBasedOn(TextsDocumentsBasedOn, InvoicesIssuedOnBasisOf)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;
	If Not NotificationParameters.ServerCallRequired_ Then
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElements(ActionParameters);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(TagName, AdditionalParameters)
	
	Var ActionParameters;

	CustomerInvoiceServicesAndAssetsLocalization.OnChangeAttribute(TagName, ThisForm, AdditionalParameters);
	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_SetRevenueItem", ActionParameters) Then
        SetTheIncomeItemServer(ActionParameters.IncomeItem, ActionParameters.TSName);
	EndIf; 
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)

	CustomerInvoiceServicesAndAssetsLocalization.OnExecuteCommand(CommandName, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseShipmentWithDeferredTransferOfTitle = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle");
	CAAccounting24IsUsed = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	BasisChanged = False;
	PrintBasisTable.Load(Documents.CustomerInvoiceServicesAndAssets.PrintBasisTable(Object));
	If AccessRight("Update", Metadata.Documents.CustomerInvoiceServicesAndAssets) And ValueIsFilled(Object.Basis) Then
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.CustomerInvoiceServicesAndAssets.FormBase(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	EndIf;
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	FillInFormDetails(True);
	FillOperationSelectionList(False);
	CustomizeFormElements();
	SetVisibilityOfShipmentBanToPartner();
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
	EstablishVisibilityOfSathyaAssetLiability();
	SetTitleOfExpensesPage();
	If Object.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
		And Object.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		
		Items.Expenses.AutoMarkIncomplete = False;
		Items.Expenses.MarkIncomplete = False;
	Else
		Items.Expenses.AutoMarkIncomplete = True;
	EndIf; 
	ConfigureDependentFormElementsOnServer();
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
EndProcedure

&AtServerNoContext
Function ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, DocumentDate)
	
	Return ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
											ManagementAccountingCurrency,
											LocalAccountingCurrency,
											?(DocumentDate = Date(1,1,1), CurrentSessionDate(), DocumentDate));
	
EndFunction

&AtServer
Procedure FillOperationSelectionList(SetOperation = True)
	
	If Not UseShipmentWithDeferredTransferOfTitle Then
		
		SaleWithDeferredTransferOfTitleIsAllowed = False;
		
	ElsIf Not ToUseTermsOfSales
		Or Not ValueIsFilled(Object.Terms) Then

		SaleWithDeferredTransferOfTitleIsAllowed = True;
		
	Else
		
		SaleWithDeferredTransferOfTitleIsAllowed =
			TMCommonUse.ValueOfBooleanObjectSProps(Object.Terms, "SaleWithDeferredTransferOfTitleIsAllowed");
			
	EndIf;
	
	If Items.Find("BusinessOperation") <> Undefined Then
		
		NewVNAOperationsCanBeUsed = False;
		NewVNAOperationsCanBeUsed = 
			CAAccounting24IsUsed 
			And (Not Object.SaleBasedOn 
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForFixedAssetSale2_4")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.PreparingForIntangibleAssetSale2_4"));
				
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.NonCurrentAssetsSale);
		If NewVNAOperationsCanBeUsed Then
			
			If ListItem = Undefined Then
				Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.NonCurrentAssetsSale);
			EndIf; 
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
			// Income from leased FA.
			ImplementationOfRentalServicesIsAvailable = False;
			If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
				If ToUseTermsOfSales Then
					SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms);
					If SalesTermsAndConditions.ContractsAreUsed = True Then
						ImplementationOfRentalServicesIsAvailable = True;
					EndIf;
				Else
					ImplementationOfRentalServicesIsAvailable = True;
				EndIf;
			EndIf;
			
			If ImplementationOfRentalServicesIsAvailable Then
				ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.RenderRentalServices);
				If ListItem = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.RenderRentalServices);
				EndIf;
			Else
				ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.RenderRentalServices);
				If ListItem <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(ListItem);
				EndIf;	
			EndIf;
			
		Else
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.RenderRentalServices);
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
		EndIf;
		If NewVNAOperationsCanBeUsed Then
			Operation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
			OperationHeader = "";
		Else
			Operation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
			OperationHeader = NStr("vi = 'Thực hiện chuyển giao quyền hoãn lại';
									|ru = 'Реализация с отложенным переходом прав';
									|en = 'Sale with deferred title transfer'; fa = 'Sale with deferred title transfer';
									|it = 'Vendita con il trasferimento di diritti rinviato';
									|pl = 'Realizacja z odroczonym przejściem praw';
									|tr = 'Hakların ertelenmiş geçişi ile uygulama'");
		EndIf;
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Operation);
		If SaleWithDeferredTransferOfTitleIsAllowed Then
			If ListItem = Undefined Then
				Items.BusinessOperation.ChoiceList.Add(Operation, OperationHeader);
			EndIf;
		Else
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		// If the operation is not in the list, then we will change the operation to an available one.
		If SetOperation
			And ValueIsFilled(Object.BusinessOperation)
			And Items.BusinessOperation.ChoiceList.FindByValue(Object.BusinessOperation) = Undefined Then
			
			If Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer 
				And Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle) <> Undefined Then
				Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
			ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle 
				And Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) <> Undefined Then
				Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
			Else
				Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
			EndIf; 
			
			WhenBusinessTransactionChangesServer();
			
		EndIf;
		
		OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
		If SetOperation And OnlyOperation And Not ValueIsFilled(Object.BusinessOperation) Then
			Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
			WhenBusinessTransactionChangesServer();
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"BusinessOperation",
			"ReadOnly",
			OnlyOperation And ValueIsFilled(Object.BusinessOperation));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfStatusAndDateOfTransferOfOwnership()
	
	ShowStatus_ = (Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
						Or Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
	
	Items.DateOfTransferOfTitleToGoods.Visible = ShowStatus_;
	Items.Status.Visible = ShowStatus_;
	
EndProcedure

&AtServer
Procedure FillInFormDetails(WhenReadingCreating = False)
	If Not ValueIsFilled(DocumentCurrency) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
	Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
		ParametersOfAccount, Object.CounterpartyBankAccount);
	
	FillParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForFillingInSalesVATTaxation(Object);
	If Not WhenReadingCreating Then
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	EndIf;
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	If Not WhenReadingCreating Then
		VATTaxationOnChangeServer();
	EndIf;
	
	UpdateInvoiceText();
	
	If Not BasisChanged Then
		BaseStructure = Documents.CustomerInvoiceServicesAndAssets.FormBase(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.CustomerInvoiceServicesAndAssets.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation);
	If Not DisplayTotalAmountOfVAT Then
		Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
		Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
		VisibilityOfVATCommands = False;
	Else
		Items.VATPageGroup.CurrentPage   = Items.PageVAT;
		Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
		VisibilityOfVATCommands = True;
	EndIf;
	
	Items.IncomeSetVATRate.Visible = VisibilityOfVATCommands;
	Items.IncomeSetTheIncomeItem.Visible = Items.IncomeIncomeItem.Visible;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	VisibilityOfRentalItems = False;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RenderRentalServices") Then
			VisibilityOfRentalItems     = True;
			Items.Contract.Visible   = True;
			Items.Contract.Enabled = True;
	EndIf;
	
	Items.SaleBasedOn.Visible = Not (Object.BusinessOperation 
													= PredefinedValue("Enum.BusinessTransactions.RenderRentalServices"));
	
	Items.IncomeFillInAccordingToRentalSchedule.Visible  = VisibilityOfRentalItems;
	Items.IncomeRentalComponentOfContract.Visible = VisibilityOfRentalItems;
	Items.IncomeRentalObject.Visible             = VisibilityOfRentalItems;
	Items.ExpensesPage.Visible                 = Not VisibilityOfRentalItems;
EndProcedure

&AtServer
Procedure FillInDefaultContract()
		
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
	
		Contract = SalesServer.GetDefaultContract(Object, 
															Object.BusinessOperation, 
															Object.ARAPCurrency, 
															Object.LineOfBusiness);
	Else
															
		Contract = SalesServer.GetDefaultContract(Object, 
															Object.BusinessOperation, 
															Object.ARAPCurrency);
	EndIf;	
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		FillInFormDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure SetTheIncomeItemServer(Val IncomeItem, Val TSName)
	
	DataForSelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(Object[TSName], Items[TSName].SelectedRows);
	
	For Each RowData In DataForSelectedRows Do
		
		If TSName = "Expenses" And Not RowData.ReverseBonusDepreciation Then
			Continue;
		EndIf;
		
		RowData.IncomeItem = IncomeItem;
		RowData.DimensionOfRevenue = ChartsOfCharacteristicTypes.IncomeItems.GetDefaultRevenueAnalytics(
											RowData.IncomeItem,
											Object,
											Object.Department);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVATRateServer(VATRate, ValuesCache)
	Actions = New Structure;
	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Income, Items.Income.SelectedRows);

	For Each Income_2 In SelectedRows Do
		Income_2.VATRate = VATRate;
		AddActionsForRecalculatingAmounts(Actions, Object, Income_2);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		Actions,
		Object.Income,
		ValuesCache);
		
EndProcedure

&AtClient
Procedure OpenPrintDetails(ShowTTNDetails)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          "");
	ParametersStructure.Insert("DeliveryAddressFieldValues",     "");
	ParametersStructure.Insert("DeliveryZone",                   "");
	ParametersStructure.Insert("DeliveryTimeFrom",                 "");
	ParametersStructure.Insert("DeliveryTimeTo",                "");
	ParametersStructure.Insert("AdditionalDeliveryInformation", "");
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("CompanyBankAccount",      Object.CompanyBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Contract",                        Object.Contract);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("IssuiedBy",                       Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",              Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("ShowTTNDetails",         ShowTTNDetails);
	ParametersStructure.Insert("ObjectType",                     "CustomerInvoiceServicesAndAssets");
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",      PrintBasisTable);
	
	AttributesArray = New Array;
	AttributesArray.Add("BusinessOperation");
	ParametersStructure.Insert("DoNotShowBankDetails", AttributesArray);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServer
Procedure UpdateInvoiceText()
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	
	PresentationOfInvoicesIssued = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoicesIssuedOnBasisOf);
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, PresentationOfInvoicesIssued);
	
	TextsDocumentsBasedOn = New Array;
	TextsDocumentsBasedOn.Add(PresentationOfInvoicesIssued);
	
	UpdateTextsDocumentsBasedOn(TextsDocumentsBasedOn, InvoicesIssuedOnBasisOf);
	
	TextOfTheInvoiceIssued = New FormattedString(TextsDocumentsBasedOn);
	
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

&AtServer
Procedure EstablishVisibilityOfSathyaAssetLiability()
	
	ImplementationOfVNA = Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		Or Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
	DeferredTransferOfOwnership = Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
	
	Items.ExpensesAssetKind.Visible = ImplementationOfVNA And Not DeferredTransferOfOwnership;
	Items.ExpensesNonCurrentAsset.Visible = ImplementationOfVNA;
	Items.ExpensesNonCurrentAsset.Title = NStr("vi = 'Tài sản dài hạn';
												|ru = 'Внеоборотный актив';
												|en = 'Fixed or intangible asset'; fa = 'دارایی ثابت یا نامشهود';
												|it = 'Attivi non circolanti';
												|pl = 'Aktyw nieobrotowy';
												|tr = 'Duran varlık'");
	If DeferredTransferOfOwnership Then
		Items.ExpensesNonCurrentAsset.Title = NStr("vi = 'Tài sản cố định';
													|ru = 'Основное средство';
													|en = 'Fixed asset'; fa = 'دارایی ثابت';
													|it = 'Capitale fisso';
													|pl = 'Środek trwały';
													|tr = 'Sabit kıymetler'");
	EndIf;
	
	Items.ExpensesSum.Visible = Not ImplementationOfVNA;
	Items.ExpensesSumCompl.Visible = Not ImplementationOfVNA;
	Items.ExpensesPermanentDifference.Visible = Not ImplementationOfVNA;
	Items.ExpensesCostTD.Visible = Not ImplementationOfVNA;
	
EndProcedure

&AtServer
Procedure SetTitleOfExpensesPage()

	If Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale Then
		Items.ExpensesPage.Title = NStr("vi = 'Tài sản dài hạn';
										|ru = 'Внеоборотные активы';
										|en = 'Fixed and intangible assets'; fa = 'دارایی‌های ثابت و نامشهود';
										|it = 'Attivi non circolanti';
										|pl = 'Środki trwałe';
										|tr = 'Duran varlıklar'");
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		Items.ExpensesPage.Title = NStr("vi = 'Tài sản cố định';
										|ru = 'Основные средства';
										|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
										|it = 'Capitali fissi';
										|pl = 'Środki trwałe';
										|tr = 'Sabit kıymetler'");
	Else
		Items.ExpensesPage.Title = NStr("vi = 'Giá vốn (chi phí)';
										|ru = 'Себестоимость (расходы)';
										|en = 'Cost (expenses)'; fa = 'بهای تمام‌شده (هزینه‌ها)';
										|it = 'Prezzo di costo (spese)';
										|pl = 'Koszty własne (wydatki)';
										|tr = 'Maliyet (giderler)'");
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function ParametersForRegisteringInvoicesIssued(Object)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.ImplementationOfWorksServices = True;
	RegistrationParameters.OtherAssetSale = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.NonCurrentAssetsSale"));
	
	Return RegistrationParameters;
	
EndFunction

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter)
	
	FillInFormDetails();
	CustomizeFormElements();
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillInByRemainingTraceableItemsOnServer()
	AccountingForTraceableGoodsLocalization.FillInTabularPartOnRemainsOfTraceableGoods(Object, AvailableFixedAssets(), , True);
EndProcedure

&AtClient
Procedure InformationOnBalanceOfTraceableGoods(Command)
			
	If Object.TraceableGoods.Count()>0 Then
		
		QueryText = NStr("vi = 'Trước khi điền, phần bảng chứng từ sẽ bị xóa, tiếp tục?';
						|ru = 'Перед заполнением табличная часть документа будет очищена, продолжить?';
						|en = 'The document table will be cleared before filling in. Do you want to continue?'; fa = 'The document table will be cleared before filling in. Do you want to continue?';
						|it = 'Prima del completamento, la parte tabellare del documento sarà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem sekcja tabelaryczna zostanie wyczyszczona, kontynuować?';
						|tr = 'Doldurmadan önce, belgenin tablo kısmı temizlenecek, devam edecek mi?'");
		Notification = New CallbackDescription("AnswerToQuestionAboutClearingTablePart", ThisForm);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			
	Else
		PerformanceMonitorClient.TimeMeasurement(
		"Document.SplitFixedAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
		FillInByRemainingTraceableItemsOnServer();	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AnswerToQuestionAboutClearingTablePart(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	PerformanceMonitorClient.TimeMeasurement(
	"Document.CustomerInvoiceServicesAndAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
	FillInByRemainingTraceableItemsOnServer();
	
EndProcedure 

&AtServer
Function AvailableFixedAssets()
	ListOfNonCurrentAssets = Object.Expenses.Unload(,"NonCurrentAsset").UnloadColumn("NonCurrentAsset");
	
	AvailableFixedAssets = New Array();
	For Each NonCurrentAsset In ListOfNonCurrentAssets Do
		If TypeOf(NonCurrentAsset) = Type("CatalogRef.Assets")Then
			AvailableFixedAssets.Add(NonCurrentAsset);		
		EndIf;
	EndDo; 
	
	NodesList = NonCurrentAssets.GetFANodes(AvailableFixedAssets, Object.Date);
	
	While NodesList.Next() Do
		AvailableFixedAssets.Add(NodesList.FixedAsset);
	EndDo;
	
	Return AvailableFixedAssets;
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa có truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản dài hạn. 
			|Không có giá trị %1 trong tài sản dài hạn.';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным о внеоборотных активах. 
			|Значение %1 отсутствует в внеоборотных активах.';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed and intangible assets. 
			|The %1 value is missing in fixed and intangible assets.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed and intangible assets. 
			|The %1 value is missing in fixed and intangible assets.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati delle attività non correnti. 
			|Il valore %1 manca nelle attività non correnti.';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi o aktywach trwałych. 
			|Brak wartości %1 w aktywach trwałych.';
			|tr = 'İzlenebilir malların tablo kısmındaki veriler duran varlıklardaki verilerle uyuşmuyor. 
			|Duran varlıklarda %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;
EndFunction

&AtServer
Procedure ExpensesNonCurrentAssetWhenChangedOnServer()
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
EndProcedure

&AtClient
Procedure ExpensesNonCurrentAssetOnChange(Item)
	ExpensesNonCurrentAssetWhenChangedOnServer();
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	Filter = New Structure;
	Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
	Filter.Insert("Period", ReportPeriod);		
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.CompanyBankAccount);
	
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
