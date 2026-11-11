#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Organization) Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	InitializeBankingDetails();
	SetDynamicListSelection();
	CustomizeWithLinkSeeAlso();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormParametersHaveChanged = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProcessingPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.DocumentsForRegistrationPage Then 
		PerformanceMonitorClient.TimeMeasurement("DataProcessor.RegisterDocumentsByDepreciationMethod.Form.DocumentsCreating.DocumentsForRegistrationPage");
	ElsIf CurrentPage = Items.DocumentsForCancellationPage Then 
		PerformanceMonitorClient.TimeMeasurement("DataProcessor.RegisterDocumentsByDepreciationMethod.Form.DocumentsCreating.DocumentsForCancellationPage");
	EndIf;
	
	If FormParametersHaveChanged Then
		SetDynamicListSelection();
		
		FormParametersHaveChanged = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FormParametersHaveChanged = True;
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	FormParametersHaveChanged = True;
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	FormParametersHaveChanged = True;
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FormParametersHaveChanged = True;
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", RegistrationPeriod, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		RegistrationPeriod,
		RegistrationPeriodPresentation);
	
	RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(RegistrationPeriod);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PeriodReverseTransactionOnChange(Item)
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, LogParameters);
	
EndProcedure

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("DeletionMark", False);
	FilterStructure1.Insert("OptionForRegisteringServiceReceiptDocuments", 
		PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed"));
		
	If Items.ProcessingPages.CurrentPage = Items.ProcessingPages.ChildItems.DocumentsForRegistrationPage Then
		FilterStructure1.Insert("MonthlyReceiptOfServices", True);
	EndIf;
	
	If ValueIsFilled(Organization) Then
		FilterStructure1.Insert("Organization", Organization);
	EndIf;
	If ValueIsFilled(Counterparty) Then
		FilterStructure1.Insert(?(AvailabilityOfCounterparties, "Counterparty", "Partner"), Counterparty);
	EndIf;
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfContractsForReceiptOfServices

&AtClient
Procedure ListOfContractsForReceiptOfServicesOnActivateRow(Item)
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
EndProcedure

&AtClient
Procedure ListOfContractsForReceiptOfServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	
	If Not CurrentData = Undefined Then
		MatchingContractFields = New Map;
		MatchingContractFields.Insert(Items.ListOfContractsForReceiptOfServicesCounterparty.Name, "Counterparty");
		MatchingContractFields.Insert(Items.ListOfContractsForReceiptOfServicesContract.Name, "Contract");
		MatchingContractFields.Insert(Items.ListOfServiceReceiptContractsOrderNumber.Name, "PurchaseOrder");
		MatchingContractFields.Insert(Items.ListOfContractsOfReceiptOfServicesDateOfOrder.Name, "PurchaseOrder");
		MatchingContractFields.Insert(Items.ListOfContractsForReceiptOfServicesOrderAmount.Name, "PurchaseOrder");
		MatchingContractFields.Insert(Items.ListOfServiceReceiptContractsOrderCurrency.Name, "PurchaseOrder");
		MatchingContractFields.Insert(Items.ListOfContractsForReceiptOfServicesDepartment.Name, "Department");
		
		ListBox = MatchingContractFields.Get(Field.Name);
		
		If Not ListBox = Undefined And ValueIsFilled(CurrentData[ListBox]) Then
			ShowValue(Undefined, CurrentData[ListBox]);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfDocumentsToBeCancelled

&AtClient
Procedure ListOfDocumentsToBeCancelledSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	
	If Not CurrentData = Undefined Then
		MatchingOfDocumentFields = New Map;
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledCounterparty.Name, "Counterparty");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledContract.Name, "Contract");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledNumberOfReceipt.Name, "Inpayment");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledDateOfReceipt.Name, "Inpayment");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledOrderReceiptAmount.Name, "Inpayment");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledCurrencyOfReceipt.Name, "Inpayment");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledPurchaseNumber.Name, "Purchase");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledPurchaseDate.Name, "Purchase");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledPurchase_Amount.Name, "Purchase");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledPurchaseCurrency.Name, "Purchase");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledNumberStorno.Name, "ReversingEntry");
		MatchingOfDocumentFields.Insert(Items.ListOfDocumentsToBeCancelledReversingEntryDate.Name, "ReversingEntry");
		
		ListBox = MatchingOfDocumentFields.Get(Field.Name);
		
		If Not ListBox = Undefined And ValueIsFilled(CurrentData[ListBox]) Then
			ShowValue(Undefined, CurrentData[ListBox]);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateServiceReceipt(Command)
	
	CurrentRow = Items.ListOfContractsForReceiptOfServices.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("FillingValues", New Structure);
	
	If FillInBasedOnContract(CurrentRow.Contract) Or Not ValueIsFilled(CurrentRow.PurchaseOrder) Then
		FormParameters.FillingValues.Insert("DocumentBasis", CurrentRow.Contract);
	Else
		FormParameters.FillingValues.Insert("DocumentBasis", CurrentRow.PurchaseOrder);
	EndIf;
	
	FormParameters.FillingValues.Insert("DocumentDate", DateOfReceipt());
	
	FormNotificationDetails = New CallbackDescription("WhenClosingReceipt", ThisObject);
	
	OpenForm("Document.ReceiptOfServicesToBusinessUnit.Form.DocumentForm", 
		FormParameters, 
		ThisObject,,,,
		FormNotificationDetails);
	
EndProcedure

&AtClient
Procedure ReverseAndMatchReceipt(Command)
	
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.RegisterDocumentsByDepreciationMethod.Form.MappingForm.Opening");
	
	CurrentRow = Items.ListOfDocumentsToBeCancelled.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("PeriodReverseTransaction", PeriodReverseTransaction);
	FormParameters.Insert("Contract", CurrentRow.Contract);
	FormParameters.Insert("DocumentInpayment", CurrentRow.Inpayment);
	FormParameters.Insert("PurchaseOrder", CurrentRow.PurchaseOrderToPurchasePurchaseSupplier);
	
	Notification = New CallbackDescription("UpdateListOfDocuments", ThisObject);
	
	OpenForm("DataProcessor.RegisterDocumentsByDepreciationMethod.Form.MappingForm", FormParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure CancelSelectedDate(Command)
	
	If Items.ListOfDocumentsToBeCancelled.SelectedRows.Count() = 0 Then
		ClearMessages();
		
		CommonClient.MessageToUser(NStr("vi = 'Cần tách chọn chứng từ trong danh sách';
										|ru = 'Необходимо выделить документы в списке';
										|en = 'Select documents in the list'; fa = 'Select documents in the list';
										|it = 'Select documents in the list';
										|pl = 'Select documents in the list';
										|tr = 'Listedeki belgeleri seçmek gerekir'"));
		
		Return;
	EndIf;
	
	TitleOfInputForm	= NStr("vi = 'Đảo ngược bằng ngày:';
								|ru = 'Сторнировать датой:';
								|en = 'Reverse with date:'; fa = 'Reverse with date:';
								|it = 'Reverse with date:';
								|pl = 'Reverse with date:';
								|tr = 'Tarih ile iptal et:'");
	CallbackDescription	= New CallbackDescription("SetDateStornoEnd", ThisObject);
	
	ShowInputDate(CallbackDescription, BegOfMonth(CurrentSessionDateServer()), TitleOfInputForm, DateFractions.Date);
	
EndProcedure

&AtClient
Procedure CancelDateOfPurchase(Command)
	
	If Items.ListOfDocumentsToBeCancelled.SelectedRows.Count() = 0 Then
		ClearMessages();
		
		CommonClient.MessageToUser(NStr("vi = 'Cần tách chọn chứng từ trong danh sách';
										|ru = 'Необходимо выделить документы в списке';
										|en = 'Select documents in the list'; fa = 'Select documents in the list';
										|it = 'Select documents in the list';
										|pl = 'Select documents in the list';
										|tr = 'Listedeki belgeleri seçmek gerekir'"));
		
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("CancelDateOfPurchaseContinued", ThisObject);
	
	ShowQueryBox(CallbackDescription, NStr("vi = 'Đảo ngược bằng ngày mua';
											|ru = 'Сторнировать датой приобретения?';
											|en = 'Reverse with purchase date?'; fa = 'Reverse with purchase date?';
											|it = 'Reverse with purchase date?';
											|pl = 'Reverse with purchase date?';
											|tr = 'Satın alma tarihiyle iptal edilsin mi?'"), 
		QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	If Items.ListOfContractsForReceiptOfServices.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListOfContractsForReceiptOfServices);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListOfContractsForReceiptOfServices);
EndProcedure

#EndRegion 

#Region Private

&AtServer
Function CurrentSessionDateServer()

	Return CurrentSessionDate();

EndFunction

&AtClient
Procedure SetDateStornoEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ReversingEntryDate		  = EndOfDay(Result);
	ReceiptsList = New Array;
	StateIsStorno	  = Items.State.ChoiceList.FindByValue(1);
	
	For Each RowID In Items.ListOfDocumentsToBeCancelled.SelectedRows Do
		ListLine = Items.ListOfDocumentsToBeCancelled.RowData(RowID);
		
		If Not ListLine.State = StateIsStorno.Value Then
			MessageText = StrTemplate(NStr("vi = 'Để tạo đảo ngược, trạng thái tiếp nhận ""%1"" phải là ""%2"".';
											|ru = 'Для создания сторно статус поступления ""%1"" должен быть ""%2"".';
											|en = 'To create storno, set the ""%1"" receipt status to ""%2"".'; fa = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|it = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|pl = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|tr = 'İptal işlemi oluşturmak için ""%1"" teslim alınma statüsü ""%2"" olmalıdır'"),
				ListLine.Inpayment, StateIsStorno.Presentation);
				
			CommonClient.MessageToUser(MessageText);
			
			Continue;
		EndIf;
		
		Cancel = False;
		
		If ListLine.DateOfReceipt > ReversingEntryDate Then  
			MessageText = StrTemplate(NStr("vi = 'Đối với chứng từ ""%1"" Ngày đảo ngược không thể nhỏ hơn ngày tiếp nhận.';
											|ru = 'Для документа ""%1"" Дата сторно не должна быть меньше даты поступления.';
											|en = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.'; fa = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|it = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|pl = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|tr = '""%1"" belgesi için iptal tarihi, giriş tarihinden önce olmamalıdır.'"),
				ListLine.Inpayment);
				
			CommonClient.MessageToUser(MessageText,,,, Cancel);
		EndIf;

		If Cancel Then
			Continue;
		EndIf;
		
		ReceiptsList.Add(ListLine.Inpayment);
	EndDo;
	
	ListOfDataStorno = CheckMatchedPurchases(ReversingEntryDate, ReceiptsList);
	
	If Not ListOfDataStorno.Count() = 0 Then
		CreateStornoServer(ListOfDataStorno);
	EndIf;
	
EndProcedure

&AtServer
Function CheckMatchedPurchases(ReversingEntryDate, ReceiptsList)

	ListOfDataStorno = New Array;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReceiptOfServicesToBusinessUnit.Ref AS Ref,
	|	ReceiptOfServicesToBusinessUnit.Contract AS Contract,
	|	ReceiptOfServicesToBusinessUnit.ReferenceOrder AS ReferenceOrder
	|INTO TTListOfReceipts
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServicesToBusinessUnit
	|WHERE
	|	ReceiptOfServicesToBusinessUnit.Ref IN(&ReceiptsList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReversingEntry.ReplacementDocument AS ReplacementDocument
	|INTO ttReversingEntry
	|FROM
	|	Document.ReversingEntry AS ReversingEntry
	|		INNER JOIN TTListOfReceipts AS TTListOfReceipts
	|		ON (CAST(ReversingEntry.ReversedDocument AS Document.ReceiptOfServicesToBusinessUnit).Contract = TTListOfReceipts.Contract)
	|WHERE
	|	ReversingEntry.Posted
	|	AND NOT ReversingEntry.ReversedDocument IN (&ReceiptsList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTListOfReceipts.Ref AS Inpayment,
	|	COUNT(DISTINCT VendorInvoice.Ref) AS Acquisitions
	|FROM
	|	TTListOfReceipts AS TTListOfReceipts
	|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
	|			LEFT JOIN ttReversingEntry AS ttReversingEntry
	|			ON VendorInvoice.Ref = ttReversingEntry.ReplacementDocument
	|		ON (VendorInvoice.Contract = TTListOfReceipts.Contract)
	|			AND (TTListOfReceipts.ReferenceOrder REFS Catalog.CounterpartyContracts
	|					AND VendorInvoice.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef)
	|				OR VendorInvoice.PurchaseOrder = TTListOfReceipts.ReferenceOrder)
	|			AND (VendorInvoice.Date >= &BeginOfPeriod)
	|			AND (VendorInvoice.Posted)
	|			AND (VendorInvoice.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromSupplier), VALUE(Enum.BusinessTransactions.ImportFromEAEU)))
	|WHERE
	|	ttReversingEntry.ReplacementDocument IS NULL
	|
	|GROUP BY
	|	TTListOfReceipts.Ref";
	
	Query.SetParameter("ReceiptsList", ReceiptsList);
	Query.SetParameter("BeginOfPeriod", PeriodReverseTransaction.StartDate);

	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.Acquisitions > 0 Then
			MessageText = StrTemplate(NStr("vi = 'Đối với chứng từ ""%1"" có chứng từ Mua hàng hóa và dịch vụ. 
				|Cần so sánh và đảo ngược thủ công các chứng từ như vậy bằng thao tác""So sánh với mua lại và đảo ngược"".';
				|ru = 'Для документа ""%1"" есть документ Приобретение товаров и услуг. 
				|Необходимо сопоставить и сторнировать такие документы вручную с помощью операции  ""Сопоставить с приобретением и сторнировать"".';
				|en = 'For the ""%1"" document, there is a ""Vendor invoice"" document. 
				|Map and reverse such documents manually using the ""Map with purchase and reverse"" transaction.'; fa = 'For the ""%1"" document, there is a ""Vendor invoice"" document. 
				|Map and reverse such documents manually using the ""Map with purchase and reverse"" transaction.';
				|it = 'For the ""%1"" document, there is a ""Vendor invoice"" document. 
				|Map and reverse such documents manually using the ""Map with purchase and reverse"" transaction.';
				|pl = 'For the ""%1"" document, there is a ""Vendor invoice"" document. 
				|Map and reverse such documents manually using the ""Map with purchase and reverse"" transaction.';
				|tr = '""%1"" belgesine ait bir Ürün ve hizmet alımı belgesi bulunmaktadır.  
				| Bu tür belgeleri, ""Satın alma ile eşleştir ve iptal et"" işlemini kullanarak manuel olarak eşleştirmek ve iptal etmek gerekir.'"),
				Selection.Inpayment);
				
			Common.MessageToUser(MessageText);
		Else
			StornoData = New Structure("ReversingEntryDate, Inpayment, Purchase", 
				ReversingEntryDate, Selection.Inpayment, Undefined);
			
			ListOfDataStorno.Add(StornoData);
		EndIf;
	EndDo;
	
	Return ListOfDataStorno;

EndFunction

&AtClient
Procedure CancelDateOfPurchaseContinued(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf; 
	
	ListOfDataStorno = New Array;
	StateIsStorno	   = Items.State.ChoiceList.FindByValue(2);
	
	For Each RowID In Items.ListOfDocumentsToBeCancelled.SelectedRows Do
		ListLine = Items.ListOfDocumentsToBeCancelled.RowData(RowID);
		
		If Not ListLine.State = StateIsStorno.Value Then
			MessageText = StrTemplate(NStr("vi = 'Để tạo đảo ngược, trạng thái tiếp nhận ""%1"" phải là ""%2"".';
											|ru = 'Для создания сторно статус поступления ""%1"" должен быть ""%2"".';
											|en = 'To create storno, set the ""%1"" receipt status to ""%2"".'; fa = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|it = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|pl = 'To create storno, set the ""%1"" receipt status to ""%2"".';
											|tr = 'İptal işlemi oluşturmak için ""%1"" teslim alınma statüsü ""%2"" olmalıdır'"),
				ListLine.Inpayment, StateIsStorno.Presentation);
				
			CommonClient.MessageToUser(MessageText);
			
			Continue;
		EndIf;
		
		Cancel = False;
		
		ReversingEntryDate = EndOfDay(ListLine.PurchaseDate);
		
		If ListLine.DateOfReceipt > ReversingEntryDate Then  
			MessageText = StrTemplate(NStr("vi = 'Đối với chứng từ ""%1"" Ngày đảo ngược không thể nhỏ hơn ngày tiếp nhận.';
											|ru = 'Для документа ""%1"" Дата сторно не должна быть меньше даты поступления.';
											|en = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.'; fa = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|it = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|pl = 'For the ""%1"" document, the storno date must not be earlier than the date of receipt.';
											|tr = '""%1"" belgesi için iptal tarihi, giriş tarihinden önce olmamalıdır.'"),
				ListLine.Inpayment);
				
			CommonClient.MessageToUser(MessageText,,,, Cancel);
		EndIf;
		
		If ValueIsFilled(ListLine.Purchase) Then
			If ListLine.PurchaseDate > ReversingEntryDate Then
				MessageText = StrTemplate(NStr("vi = 'Đối với chứng từ ""%1"" Ngày đảo ngược không thể nhỏ hơn ngày mua lại.';
												|ru = 'Для документа ""%1"" Дата сторно не должна быть меньше даты приобретения.';
												|en = 'For the ""%1"" document, the storno date must not be earlier than the date of purchase.'; fa = 'For the ""%1"" document, the storno date must not be earlier than the date of purchase.';
												|it = 'For the ""%1"" document, the storno date must not be earlier than the date of purchase.';
												|pl = 'For the ""%1"" document, the storno date must not be earlier than the date of purchase.';
												|tr = '“%1"" belgesi için iptal tarihi, satın alma tarihinden önce olmamalıdır.'"),
					ListLine.Inpayment);
					
				CommonClient.MessageToUser(MessageText,,,, Cancel);
			EndIf;		
		EndIf;

		If Cancel Then
			Continue;
		EndIf;
		
		StornoData = New Structure("ReversingEntryDate, Inpayment, Purchase", 
			ReversingEntryDate, ListLine.Inpayment, ListLine.Purchase);
		
		ListOfDataStorno.Add(StornoData);
	EndDo;
	
	If Not ListOfDataStorno.Count() = 0 Then
		CreateStornoServer(ListOfDataStorno);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateStornoServer(ListOfDataStorno)
	
	ReceiptsList = New Array;
	
	For Each StornoData In ListOfDataStorno Do
		ReceiptsList.Add(StornoData.Inpayment);
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ReversingEntry.Ref AS ReversingEntry,
	|	ReversingEntry.ReversedDocument AS Inpayment
	|FROM
	|	Document.ReversingEntry AS ReversingEntry
	|WHERE
	|	NOT ReversingEntry.DeletionMark
	|	AND ReversingEntry.ReversedDocument IN(&ReceiptsList)
	|
	|ORDER BY
	|	ReversingEntry.DATE DESC";
	
	Query.SetParameter("ReceiptsList", ReceiptsList);
	
	TableStorno = Query.Execute().Unload();

	For Each StornoData In ListOfDataStorno Do
		TableRowStorno = TableStorno.Find(StornoData.Inpayment, "Inpayment");
		
		If TableRowStorno = Undefined Then
			StornoObject = Documents.ReversingEntry.CreateDocument();
		Else
			StornoObject = TableRowStorno.ReversingEntry.GetObject();
		EndIf;
		
		Try
			StornoObject.Fill(StornoData.Inpayment);
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể đảo ngược chứng từ %1 do: %2';
											|ru = 'Не удалось сторнировать документ ""%1"" по причине: %2';
											|en = 'Cannot reverse the ""%1"" document due to: %2'; fa = 'Cannot reverse the ""%1"" document due to: %2';
											|it = 'Cannot reverse the ""%1"" document due to: %2';
											|pl = 'Cannot reverse the ""%1"" document due to: %2';
											|tr = '""%1"" belgesi şu nedenle iptal edilemedi: %2'"),
				StornoData.Inpayment, 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
			Common.MessageToUser(MessageText);
			
			Continue;
		EndTry;
		
		StornoObject.Date = StornoData.ReversingEntryDate;
		StornoObject.ReplacementDocument = StornoData.Purchase;
		
		Try
			StornoObject.Write(DocumentWriteMode.Posting);
			
			MessageText = StrTemplate(NStr("vi = 'Để tiếp nhận ""%1"" đã tạo chứng từ ""%2""';
											|ru = 'Для поступления ""%1"" сформирован документ ""%2""';
											|en = 'The ""%2"" document is generated for the ""%1"" receipt'; fa = 'The ""%2"" document is generated for the ""%1"" receipt';
											|it = 'The ""%2"" document is generated for the ""%1"" receipt';
											|pl = 'The ""%2"" document is generated for the ""%1"" receipt';
											|tr = '""%1""  girişi için ""%2"" belgesi düzenlendi'"),
				StornoData.Inpayment, StornoObject.Ref);
			
			Common.MessageToUser(MessageText);
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể đảo ngược chứng từ %1 do: %2';
											|ru = 'Не удалось сторнировать документ ""%1"" по причине: %2';
											|en = 'Cannot reverse the ""%1"" document due to: %2'; fa = 'Cannot reverse the ""%1"" document due to: %2';
											|it = 'Cannot reverse the ""%1"" document due to: %2';
											|pl = 'Cannot reverse the ""%1"" document due to: %2';
											|tr = '""%1"" belgesi şu nedenle iptal edilemedi: %2'"),
				StornoData.Inpayment, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(MessageText);
		EndTry;
	EndDo;
	
	Items.ListOfDocumentsToBeCancelled.Refresh();

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	// Conditional appearance of the dynamic list of "List of Service access agreements"
	ListOfConditionalAppearance = ListOfContractsForReceiptOfServices.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListOfContractsForReceiptOfServices.Date",
																	"ListOfContractsOfReceiptOfServicesDateOfOrder");
	
	// Conditional appearance of the dynamic list of "Lists of documents to be displayed"
	ListOfConditionalAppearance = ListOfDocumentsToBeCancelled.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListOfDocumentsToBeCancelled.DateOfReceipt",
																	"ListOfContractsForReceiptOfServicesDateOfReceipt");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListOfDocumentsToBeCancelled.PurchaseDate",
																	"ListOfContractsOfReceiptOfServicesDateOfPurchase");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListOfDocumentsToBeCancelled.ReversingEntryDate",
																	"ListOfContractsForReceiptOfServicesDateStorno");

EndProcedure

&AtClient
Procedure ReverseEnd(Result, AdditionalParameters) Export

	UpdateFormTable(Items.DocumentsForCancellationPage, Items.ListOfDocumentsToBeCancelled);

EndProcedure

&AtClient
Procedure UpdateListOfDocuments(ClosingResult, AdditionalParameters) Export
	
	UpdateFormTable(Items.DocumentsForCancellationPage, Items.ListOfDocumentsToBeCancelled);
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		RegistrationPeriod = SelectedPeriod;
		RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(RegistrationPeriod);
		
		SetDynamicListSelection();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeBankingDetails()
	
	AvailabilityOfCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
	UsePurchaseOrderStatuses = GetFunctionalOption("UsePurchaseOrderStatuses");
	
	If AvailabilityOfCounterparties Then
		Counterparty = Catalogs.Counterparties.EmptyRef();
	Else
		Counterparty = Catalogs.Partners.EmptyRef();
	EndIf;
	
	Items.ListOfContractsForReceiptOfServicesCounterparty.Visible = AvailabilityOfCounterparties;
	Items.ListOfContractsForReceiptOfServicesPartner.Visible = Not AvailabilityOfCounterparties;
	Items.ListOfDocumentsToBeCancelledCounterparty.Visible  = AvailabilityOfCounterparties;
	
	RightToAddAdmission = AccessRight("Insert", Metadata.Documents.ReceiptOfServicesToBusinessUnit);
	Items.ListOfServiceReceiptContractsCreateServiceReceipt.Visible = RightToAddAdmission;
	
	RegistrationPeriod = DefineRegistrationPeriod();
	RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(RegistrationPeriod);
	PeriodReverseTransaction.StartDate = RegistrationPeriod;
	PeriodReverseTransaction.EndDate = EndOfMonth(RegistrationPeriod);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	If AvailabilityOfCounterparties Then
		Partner = Common.ObjectAttributeValue(Counterparty, "Partner");
	Else
		Partner = Counterparty;
	EndIf;
	
	NewArray = New Array();
	
	If ValueIsFilled(Partner) Then
		NewLink = New ChoiceParameterLink("Partner", "Partner");
		NewArray.Add(NewLink);
	EndIf;
	
	NewLinks = New FixedArray(NewArray);
	Items.Contract.ChoiceParameterLinks = NewLinks;
	
	If Items.ProcessingPages.CurrentPage = Items.ProcessingPages.ChildItems.DocumentsForRegistrationPage Then
		ListOfContractsForReceiptOfServices.Parameters.SetParameterValue("BeginOfPeriod", BegOfMonth(RegistrationPeriod));
		ListOfContractsForReceiptOfServices.Parameters.SetParameterValue("EndOfPeriod",  EndOfMonth(RegistrationPeriod));
		ListOfContractsForReceiptOfServices.Parameters.SetParameterValue("UsePurchaseOrderStatuses", UsePurchaseOrderStatuses);
		
		CommonClientServer.SetDynamicListFilterItem(
			ListOfContractsForReceiptOfServices,
			"Organization",
			Organization,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Organization));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfContractsForReceiptOfServices,
			"Department",
			Department,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Department));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfContractsForReceiptOfServices,
			?(AvailabilityOfCounterparties, "Counterparty", "Partner"),
			Counterparty,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Counterparty));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfContractsForReceiptOfServices,
			"Contract",
			Contract,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Contract));
			
		Items.ListOfContractsForReceiptOfServices.SelectedRows.Clear();
	ElsIf Items.ProcessingPages.CurrentPage = Items.ProcessingPages.ChildItems.DocumentsForCancellationPage Then
		ListOfDocumentsToBeCancelled.Parameters.SetParameterValue("BeginOfPeriod", PeriodReverseTransaction.StartDate);
		ListOfDocumentsToBeCancelled.Parameters.SetParameterValue("EndOfPeriod", EndOfDay(PeriodReverseTransaction.EndDate));
		ListOfDocumentsToBeCancelled.Parameters.SetParameterValue("BeginningOfVocationalSchoolPeriod", AddMonth(PeriodReverseTransaction.StartDate, -3));
		ListOfDocumentsToBeCancelled.Parameters.SetParameterValue("EndOfVocationalTrainingPeriod", AddMonth(EndOfDay(PeriodReverseTransaction.EndDate), 3));
		
		CommonClientServer.SetDynamicListFilterItem(
			ListOfDocumentsToBeCancelled,
			"Organization",
			Organization,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Organization));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfDocumentsToBeCancelled,
			"Department",
			Department,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Department));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfDocumentsToBeCancelled,
			?(AvailabilityOfCounterparties, "Counterparty", "Partner"),
			Counterparty,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Counterparty));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfDocumentsToBeCancelled,
			"Contract",
			Contract,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Contract));
			
		CommonClientServer.SetDynamicListFilterItem(
			ListOfDocumentsToBeCancelled,
			"State",
			State,
			DataCompositionComparisonType.Equal,
			,
			Not State = 0);
			
		Items.ListOfDocumentsToBeCancelled.SelectedRows.Clear();
	EndIf;

EndProcedure

&AtServer
Procedure CustomizeWithLinkSeeAlso()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("PurposeUseKey", "Invoices");
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfPurchaseDocuments");
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

&AtServer
Function DefineRegistrationPeriod()
	
	CurrentUserDate = Common.CurrentUserDate();
	
	Return BegOfMonth(CurrentUserDate);
	
EndFunction

&AtServer
Function DateOfReceipt() 
	
	Return EndOfMonth(RegistrationPeriod);
	
EndFunction

&AtClient
Procedure WhenClosingReceipt(ClosingResult, AdditionalParameters) Export

	UpdateFormTable(Items.DocumentsForRegistrationPage, Items.ListOfContractsForReceiptOfServices);

EndProcedure

&AtClient
Procedure WhenClosingStorno(ClosingResult, AdditionalParameters) Export

	UpdateFormTable(Items.DocumentsForCancellationPage, Items.ListOfDocumentsToBeCancelled);

EndProcedure

&AtServerNoContext
Function FillInBasedOnContract(Contract)

 	ContractDetails_ = Common.ObjectAttributesValues(Contract, 
		"OptionForRegisteringServiceReceiptDocuments, ServiceReceiptOption");
	
 	If (ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
		And (ContractDetails_.ServiceReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices 
		Or ContractDetails_.ServiceReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices) Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

#Region Other

// Parameters:
//  Page - PanelPage
//  FormTable - FormTable
&AtClientAtServerNoContext
Procedure UpdateFormTable(Page, FormTable)
	
	If Page.Visible Then
		FormTable.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
