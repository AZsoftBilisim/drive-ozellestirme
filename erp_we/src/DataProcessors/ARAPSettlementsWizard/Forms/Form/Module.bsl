#Region Variables

&AtClient
Var IdleParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.ARAPObject) = Type("Array")
		And CommonClientServer.CollapseArray(Parameters.ARAPObject).Count() = 1 Then
		ARAPObject = Parameters.ARAPObject[0];
	ElsIf TypeOf(Parameters.ARAPObject) <> Type("CatalogRef.ARAPObjects") Then
		ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Parameters.ARAPObject, Parameters.Organization, Parameters.PaymentType_);
	Else
		ARAPObject = Parameters.ARAPObject;
	EndIf;
	
	If Parameters.Property("Document") Then
		Document = Parameters.Document;
	EndIf;
	
	If Parameters.Property("DocumentPartner") Then
		DocumentPartner = Parameters.DocumentPartner;
	EndIf;
	
	If Parameters.Property("NameTchrashifrovkaPayment") Then
		NameTchrashifrovkaPayment = Parameters.NameTchrashifrovkaPayment;
	EndIf;
	
	If Parameters.Property("ARAPObjectSettings") Then
		ARAPObjectSettings = Parameters.ARAPObjectSettings;
	EndIf;
	
	ListOfObjects = New ValueList;
	If Parameters.Property("PathToTestObjects") And Parameters.PathToTestObjects <> "" Then
		Substrings = StrSplit(Parameters.PathToTestObjects,".");
		Query = New Query("
		|SELECT &FieldName AS Object
		|FROM &Path AS Table
		|WHERE Table.Ref = &Ref");
		Query.SetParameter("Ref", Document);
		Query.Text = StrReplace(Query.Text, "&Path", "Document." + Document.Metadata().Name + "."+Substrings[0]);
		Query.Text = StrReplace(Query.Text, "&FieldName", "Table." + Substrings[1]);
		ObjectsArray = Query.Execute().Unload().UnloadColumn("Object");
		ListOfObjects.LoadValues(ObjectsArray);
	EndIf;
	
	If ValueIsFilled(Parameters.AddressPaymentDecryption) Then
		ARAPDetails.Load(GetFromTempStorage(Parameters.AddressPaymentDecryption));
		DeleteFromTempStorage(Parameters.AddressPaymentDecryption);
	EndIf;
	
	If Parameters.OpeningByProcessingCommand Then
		CalculationObjectFound = ARAPObjectsServer.ObjectOfCalculationsFromLink(Parameters.Document);
		If TypeOf(CalculationObjectFound) = Type("Array") 
			And CalculationObjectFound.Count() > 0 Then
				ARAPObject = CalculationObjectFound[0];
		ElsIf TypeOf(CalculationObjectFound) = Type("CatalogRef.ARAPObjects") Then
			ARAPObject = CalculationObjectFound;
		EndIf;
		DocumentAttributes = Common.ObjectAttributesValues(Parameters.Document, "Partner, ARAPObjectSettings");
		DocumentPartner = DocumentAttributes.Partner;
		If Not ValueIsFilled(ARAPObject) Then
			ExceptionText = NStr("vi = 'Không xem xét khấu trừ thanh toán đối với đơn hàng này.';
								|ru = 'Зачет оплаты не предусмотрен для данного заказа.';
								|en = 'Payment offset for this order is not supported.'; fa = 'Payment offset for this order is not supported.';
								|it = 'Compensazione del pagamento non disponibile per questo ordine.';
								|pl = 'Zaliczenie płatności nie jest przewidziane dla danego zamówienia.';
								|tr = 'Bu sipariş için ödeme mahsubu ön görülmemiştir.'");
			Raise ExceptionText;
		EndIf;
		ARAPObjectSettings = DocumentAttributes.ARAPObjectSettings;
		If ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
			AmountARAP = AmountOfOrderAdvances(Parameters.Document);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(ARAPObject) Then
		ExceptionText = NStr("vi = 'Không thể mở biểu mẫu bộ xử lý một cách trực tiếp';
							|ru = 'Не предусмотрено непосредственное открытие формы обработки.';
							|en = 'Direct opening of the data processor form is not available.'; fa = 'Direct opening of the data processor form is not available.';
							|it = 'Non è prevista un''apertura diretta del modulo di elaborazione.';
							|pl = 'Nie przewidziano bezpośrednie otwieranie formularzu przetwarzania.';
							|tr = 'İşleme formunun doğrudan açılması sağlanmamaktadır.'");
		Raise ExceptionText;
	EndIf;
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	If Parameters.Property("AmountToPay") Then
		AmountARAP = Parameters.AmountToPay;
		AmountOfSettlementsInParameters = AmountARAP <> 0;
	EndIf;
	
	GetPaymentDetailsWithPartner();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	FillInTableForSettlementsWithPartners();
	FormItemsManagement();
	
	If Not UserRightsCached.PaymentSettlement() Then
		ReadOnly = True;
	EndIf;
	
	If DocumentCorrection.IsThereFixOrReverse(Document) Then
		ReadOnly = True;
	EndIf;
	
	EstablishContractSelection();
	
	CreateInformationLabelSelections();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Or Exit Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("DataChanged1", True);
	ArrayOfTables = New Array;
	ArrayOfTables.Add("Prepayments");
	ArrayOfTables.Add("Payments");
	ArrayOfTables.Add("SetOff");
	
	For Each TableName In ArrayOfTables Do
		
		RowsArray = ThisForm[TableName].FindRows(TheStructureOfTheSearch);
		If RowsArray.Count() > 0 Then
		
			Cancel = True;
			ShowQueryBox(
				New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
				NStr("vi = 'Đã thay đổi dữ liệu khấu trừ thanh toán. Lưu thay đổi?';
					|ru = 'Данные зачета оплаты были изменены. Сохранить изменения?';
					|en = 'Payment offset data has changed. Save the changes?'; fa = 'Payment offset data has changed. Save the changes?';
					|it = 'Dati dell''imputazione del pagamento sono stati modificati. Salvare le modifiche?';
					|pl = 'Dane zaksięgowania płatności zostały zmienione. Zapisać zmiany?';
					|tr = 'Ödeme mahsup verileri değiştirildi. Değişiklikleri kaydet?'"),
				QuestionDialogMode.YesNoCancel);
				
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		SavePaymentOffsetResultAndClose();
	ElsIf UserAnswer = DialogReturnCode.No Then
		UnlockDocumentsForEditing();
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not AdvancesAreCalculated And Not NewOnlineARAPAccounting Then
		AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
	EndIf;
	
	InstallAdvancesPage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByAllContractsOnChange(Item)
	
	EstablishContractSelection();
	
EndProcedure

&AtClient
Procedure PaymentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PaymentsDocument" Then
		
		TableRow = Items.Payments.CurrentData;
		If TableRow <> Undefined And ValueIsFilled(TableRow.Document) Then
			ShowValue(Undefined, TableRow.Document);
		EndIf;
		
	Else
		TableRow = Items.Payments.CurrentRow;
		RowsArray = CommonClientServer.ValueInArray(TableRow);
		OffsetPaymentForSelectedLines(RowsArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrepaymentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "AdvancesOrder" Then
		
		TableRow = Items.Prepayments.CurrentData;
		If TableRow <> Undefined And ValueIsFilled(TableRow.ARAPObject) Then
			ShowValue(Undefined, TableRow.ARAPObject);
		EndIf;
		
	Else
		TableRow = Items.Prepayments.CurrentRow;
		RowsArray = CommonClientServer.ValueInArray(TableRow);
		SetOffAdvanceForSelectedLines(RowsArray);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSetOff

&AtClient
Procedure SetOffSelection(Item, RowSelected, Field, StandardProcessing)
	
	TableRow = Items.SetOff.CurrentData;
	
	If TableRow <> Undefined Then
		
		If Field.Name = "CreditedOrder" Then
			If ValueIsFilled(TableRow.Document) Then
				ShowValue(Undefined, TableRow.Document);
			ElsIf ValueIsFilled(TableRow.ARAPObject) Then
				ShowValue(Undefined, TableRow.ARAPObject);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.SetOff.CurrentData;
	AmountBeforeEditing = CurrentData.AmountCredited_2;
	
EndProcedure

&AtClient
Procedure SetOffOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.SetOff.CurrentData;
	If CurrentData.AmountCredited_2 <> AmountBeforeEditing Then
		
		ClearMessages();
		
		Cancel = False;
		
		ChangingAmount = AmountBeforeEditing - CurrentData.AmountCredited_2;
		
		If ChangingAmount < 0 Then
			CurrentData.AmountCredited_2 = AmountBeforeEditing;
			WarningText = NStr("vi = 'Số tiền ghi có chỉ có thể được giảm';
								|ru = 'Зачтенная сумма может быть только уменьшена';
								|en = 'Offset amount can be only reduced'; fa = 'Offset amount can be only reduced';
								|it = 'L''importo imputato può essere solo diminuito';
								|pl = 'Zaksięgowana wartość może zostać tylko pomniejszona';
								|tr = 'Mahsup edilen tutar yalnızca azaltılabilir'");
			ShowMessageBox(, WarningText);
			Return;
		EndIf;
		
		TableRow = Items.SetOff.CurrentRow;
		MatchingDebits = New Map;
		MatchingDebits.Insert(TableRow, ChangingAmount);
		CancelCreditOnServer(MatchingDebits, , Cancel);
		
		If Cancel Then
			CurrentData.AmountCredited_2 = AmountBeforeEditing;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffOnActivateRow(Item)
	CorrectionOfExcessIsAvailable = False;
	For Each Id In Items.SetOff.SelectedRows Do
		TableRow = SetOff.FindByID(Id);
		If TableRow.EditingAvailable Then
			CorrectionOfExcessIsAvailable = True;
		EndIf;
	EndDo;
	If Items.CorrectExcess.Enabled <> CorrectionOfExcessIsAvailable Then
		Items.CorrectExcess.Enabled = CorrectionOfExcessIsAvailable;
	EndIf;
	CancellationIsAvailable = True;
	For Each Id In Items.SetOff.SelectedRows Do
		TableRow = SetOff.FindByID(Id);
		If Not TableRow.EditingAvailable 
				And TypeOf(TableRow.Object) <> Type("CatalogRef.GiftCertificates")
				And TypeOf(TableRow.Document) <> Type("DocumentRef.ARAPSettlement") Then
			CancellationIsAvailable = False;
		EndIf;
	EndDo;
	If Items.CancelTheSetOff.Enabled <> CancellationIsAvailable Then
		Items.CancelTheSetOff.Enabled = CancellationIsAvailable;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
	UpdateDataOnServer();
	
EndProcedure

&AtClient
Procedure SetOffPayment(Command)
	
	RowsArray = Items.Payments.SelectedRows;
	If RowsArray.Count() > 0 Then
		OffsetPaymentForSelectedLines(RowsArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffTheAdvancePayment(Command)
	
	RowsArray = Items.Prepayments.SelectedRows;
	If RowsArray.Count() > 0 Then
		SetOffAdvanceForSelectedLines(RowsArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelTheSetOff(Command)
	
	RowsArray = Items.SetOff.SelectedRows;
	If RowsArray.Count() > 0 Then
	
		ClearMessages();
		
		MatchingDebits = New Map;
		For Each String In RowsArray Do
			MatchingDebits.Insert(String, 0);
		EndDo;
		
		CancelCreditOnServer(MatchingDebits, False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CorrectExcess(Command)
	
	ClearMessages();
	
	Cancel = False;
	FixServerOvershoot(Cancel);
	
	If Not Cancel And Excess > 0 Then
		WarningText = NStr("vi = 'Không thể điều chỉnh hoàn toàn thừa. Có lẽ các chứng từ không thể chỉnh sửa.';
							|ru = 'Не удалось полностью исправить превышение. Возможно документы не доступны для редактирования.';
							|en = 'Cannot fully correct excess. Documents may not be available for editing.'; fa = 'Cannot fully correct excess. Documents may not be available for editing.';
							|it = 'Non è stato possibile correggere completamento l''eccesso. I documenti potrebbero non essere modificabili.';
							|pl = 'Nie udało się w pełni skorygować nadwyżkę. Być może dokumenty są niedostępne dla edycji.';
							|tr = 'Fazlalık tamamen düzeltilemedi. Belgelerin düzenlenmesi erişilebilir değil.'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffThePaymentAndCloseIt(Command)
	
	SavePaymentOffsetResultAndClose();
	
EndProcedure

&AtClient
Procedure Show(Command)
	
	Items.BasementManagementGroup.CurrentPage = Items.PageHideFooter;
	Items.TheGroupRead.Visible = True;
	
EndProcedure

&AtClient
Procedure Hide(Command)
	
	Items.BasementManagementGroup.CurrentPage = Items.PageShowFooter;
	Items.TheGroupRead.Visible = False;
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificate(Command)
	
	ClearMessages();
	
	If Currency <> LocalAccountingCurrency Then
		MessageText = NStr("vi = 'Chỉ có thể thanh toán chứng từ bằng phiếu quà tặng theo tiền tệ kế toán pháp quy.';
							|ru = 'Оплачивать подарочными сертификатами можно только документы в валюте регл. учета.';
							|en = 'With gift cards, you can pay only for documents in local accounting currency.'; fa = 'With gift cards, you can pay only for documents in local accounting currency.';
							|it = 'Con i buoni regalo è possibile pagare solo i documenti nella valuta della contabilità regolatoria.';
							|pl = 'Opłacać certyfikatami podarunkowymi można tylko dokumenty w walucie ewidencji reglamentowanej.';
							|tr = 'Sadece yerel muhasebedeki belgeler için hediye kartı ile ödeme yapılabilir.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	If ARAPCurrency <> LocalAccountingCurrency Then
		MessageText = NStr("vi = 'Chỉ có thể thanh toán chứng từ có tiền tệ hạch toán công nợ là tiền tệ kế toán pháp quy bằng phiếu quà tặng.';
							|ru = 'Оплачивать подарочными сертификатами можно только документы, валютой взаиморасчетов которых является валюта регл. учета.';
							|en = 'With gift cards, you can pay only for documents whose AR/AP currency is a local accounting currency.'; fa = 'With gift cards, you can pay only for documents whose AR/AP currency is a local accounting currency.';
							|it = 'Con i buoni regalo è possibile pagare solo i documenti la cui valuta dei conti reciproci è la valuta di contabilità regolatoria.';
							|pl = 'Opłacać certyfikatami podarunkowymi można tylko dokumenty, walutą rozliczeń których jest waluta ewidencji reglamentowanej.';
							|tr = 'Hediye kartı ile mutabakat para birimi sadece yerel muhasebe para birimi olan belgeler için ödeme yapılabilir.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	AmountCreditedByGiftCertificates = 0;
	AddressOfTableOfCreditedGiftCertificates = AddressOfTableOfCreditedGiftCertificates(AmountCreditedByGiftCertificates);
	If Lacks <= 0 And AmountCreditedByGiftCertificates = 0 Then
		MessageText = NStr("vi = 'Đã chọn toàn bộ số tiền khấu trừ.';
							|ru = 'Зачитываемые суммы полностью подобраны.';
							|en = 'Amounts to offset are selected.'; fa = 'Amounts to offset are selected.';
							|it = 'Gli importi da accreditare sono stati tutti selezionati.';
							|pl = 'Zaliczane kwoty są wybrane w całości.';
							|tr = 'Mahsup edilen tutarlar tamamen eşleşti.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	AddressOfTableOfProductsForAnalyzingPossibilityOfPayment = GiftCertificatesServerCall.AddressOfProductsTabularPartForAnalyzingPossibilityOfPayingWithGiftCertificates(Document, UUID);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Organization);
	PickingParameters.Insert("Currency", LocalAccountingCurrency);
	
	PickingParameters.Insert("AddressInStorage", AddressOfTableOfCreditedGiftCertificates);
	If ValueIsFilled(AddressOfTableOfProductsForAnalyzingPossibilityOfPayment) Then
		PickingParameters.Insert("AddressInStorageGoods", AddressOfTableOfProductsForAnalyzingPossibilityOfPayment);
	EndIf;
	PickingParameters.Insert("PayInAddition", Lacks);
	PickingParameters.Insert("ShowResultItRemainsToPayExtra", True);
	PickingParameters.Insert("RegisterNewOnes", False);
	
	PickingParameters.Insert("OnCloseNotifyDescription", New CallbackDescription("PickUpGiftCertificateCompletion", ThisObject));
	
	PickingParameters.Insert("Filter", New Structure);
	StatusesForSelection = New Array;
	StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
	StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
	
	// We select PS by organization and by currency of mutual settlements
	PickingParameters.Filter.Insert("Organization", Organization);
	PickingParameters.Filter.Insert("Currency", LocalAccountingCurrency);
	
	PickingParameters.Filter.Insert("Status", StatusesForSelection);
	PickingParameters.Filter.Insert("GiftCardAccounting25", True);
	PickingParameters.Filter.Insert("JustNotZeroBalances", True);
	
	StructureForDeterminingTypeOfOperation = New Structure("Ref", PredefinedValue("Document.ARAPSettlement.EmptyRef"));
	PickingParameters.Filter.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(StructureForDeterminingTypeOfOperation));

	GiftCertificatesClient.OpenGiftCertificateSelectionForm(ThisObject, PickingParameters);
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PickUpGiftCertificateCompletion(Result, AdditionalParameters) Export

	If IsTempStorageURL(Result) Then
		ReadGiftCertificatesOnServer(Result);		
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfTableOfCreditedGiftCertificates(AmountCreditedByGiftCertificates)

	AmountCreditedByGiftCertificates = 0;

	TableOfCreditedGiftCertificates = New ValueTable;
	TableOfCreditedGiftCertificates.Columns.Add("GiftCertificate", New TypeDescription("CatalogRef.GiftCertificates"));
	TableOfCreditedGiftCertificates.Columns.Add("Sum", New TypeDescription("Number"));
	
	For Each LineCredited In SetOff Do
		If TypeOf(LineCredited.Object) = Type("CatalogRef.GiftCertificates")
			And Not ValueIsFilled(LineCredited.Document) Then
			NewRow = TableOfCreditedGiftCertificates.Add();
			NewRow.GiftCertificate = LineCredited.Object;
			NewRow.Sum = LineCredited.AmountCredited_2;
			AmountCreditedByGiftCertificates = AmountCreditedByGiftCertificates + LineCredited.AmountCredited_2;
		EndIf;	
	EndDo;
	 
	Return PutToTempStorage(TableOfCreditedGiftCertificates, UUID);
	
EndFunction

&AtServer
Procedure ReadGiftCertificatesOnServer(AddressOfTablePartGiftCertificates)
	
	SelectedGiftCertificates = GetFromTempStorage(AddressOfTablePartGiftCertificates); // - ValueTable
	SelectedGiftCertificates.Columns.Add("AmountInPaymentCurrency");
	
	AllocateBalance = (Lacks > 0);
	
	// If the previously selected certificates were cleared in the selection, then you need to clear them and Count them from the table
	ArrayOfRowsToDelete = New Array;
	For Each LineCredited In SetOff Do
		If Not ValueIsFilled(LineCredited.Document) 
			And TypeOf(LineCredited.Object) = Type("CatalogRef.GiftCertificates") Then
			TheStructureOfTheSearch = New Structure("GiftCertificate", LineCredited.Object);
			If SelectedGiftCertificates.FindRows(TheStructureOfTheSearch).Count()=0 Then
				ArrayOfRowsToDelete.Add(LineCredited);
			EndIf;
		EndIf;
	EndDo;
	For Each RowForDeletion In ArrayOfRowsToDelete Do
		SetOff.Delete(RowForDeletion);
	EndDo;
		
	TheStructureOfTheSearch = New Structure("Object, Partner");
	TheStructureOfTheSearch.Insert("ARAPObject");
	
	For Each TableRow In SelectedGiftCertificates Do
		
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		TheStructureOfTheSearch.Object = TableRow.GiftCertificate;
		CountedLines = SetOff.FindRows(TheStructureOfTheSearch);
		
		If CountedLines.Count() = 0 Then
			CreditLine = SetOff.Add();
			CreditLine.Organization = Organization;
			CreditLine.Currency = Currency;
			CreditLine.ARAPCurrency = ARAPCurrency;
			CreditLine.Object = TableRow.GiftCertificate;
			FillPropertyValues(CreditLine, TableRow, , "AmountInPaymentCurrency");
			CreditLine.EditingAvailable = False;
		Else
			CreditLine = CountedLines[0];
		EndIf;
		
		TableRow.AmountInPaymentCurrency = TableRow.Sum;
		
		CreditLine.DataChanged1 = True;
		
		CreditLine.AmountCredited_2        = TableRow.Sum;
		CreditLine.AmountInPaymentCurrency = TableRow.AmountInPaymentCurrency;
		
		CreditLine.SumCompl 			 = TableRow.AmountInPaymentCurrency;
		CreditLine.SumMan 			 = TableRow.AmountInPaymentCurrency;
		If ARAPCurrency <> LocalAccountingCurrency Then
			CreditLine.SumCompl = ProcessingOfExchangeRatesTM.ConvertDocumentAmountToCurrency(
				TableRow.AmountInPaymentCurrency, ARAPCurrency, LocalAccountingCurrency, DocumentDate, LocalAccountingCurrency);
		EndIf;			
		If ARAPCurrency <> ManagementAccountingCurrency Then
			CreditLine.SumMan = ProcessingOfExchangeRatesTM.ConvertDocumentAmountToCurrency(
				TableRow.AmountInPaymentCurrency, ARAPCurrency, ManagementAccountingCurrency, DocumentDate, LocalAccountingCurrency);
		EndIf;
				
	EndDo;
	
	SetOff.Sort("Organization, DecryptionOfThePaymentObject ASC");
	
	CalculateAmountOfCredit();
	CalculateNumberOfRows_();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffAmountCredited_2.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffSumMan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.EditingAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Payments.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payments.EditingAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOff.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.EditingAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentsPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payments.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Partner");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Prepayments.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Partner");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdvancesOrder.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Prepayments.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("ARAPObject");
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Prepayments.ARAPObject.Object");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Contract");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.Document");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chứng từ đối chiếu công nợ sẽ được tạo ra>';
													|ru = '<Будет создан документ ""Взаимозачет задолженности"">';
													|en = '<The ""AR/AP offset"" document will be created>'; fa = '<The ""AR/AP offset"" document will be created>';
													|it = '<Sarà creato documento ""Compensazione del debito"">';
													|pl = '<Zostanie utworzony dokument ""Wzajemne rozliczenie zadłużenia"">';
													|tr = '<""Alacak/Borç mahsubu"" belgesi oluşturulacak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NewDocuments);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Prepayments.Document");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CreditedOrder.Name);

	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.Document");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("SetOff.Object");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("ARAPObject");

	Item.Appearance.SetParameterValue("Text", "");

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffSumCompl.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.SumCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Sẽ được tính toán tự động>';
													|ru = '<Будет рассчитана автоматически>';
													|en = '<Will be calculated automatically>'; fa = '<Will be calculated automatically>';
													|it = '<Sarà calcolato automaticamente>';
													|pl = '<Zostanie obliczony automatycznie>';
													|tr = '<Otomatik olarak hesaplanacaktır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOffSumMan.Name);

	ItemFilter =  Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SetOff.SumMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Sẽ được tính toán tự động>';
													|ru = '<Будет рассчитана автоматически>';
													|en = '<Will be calculated automatically>'; fa = '<Will be calculated automatically>';
													|it = '<Sarà calcolato automaticamente>';
													|pl = '<Zostanie obliczony automatycznie>';
													|tr = '<Otomatik olarak hesaplanacaktır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	Item.Appearance.SetParameterValue("Enabled", False);

	//
	
EndProcedure

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	MultipleCompanies  = AvailableCompanies.Count() > 1;
	
	Items.PaymentsOrganization.Visible  = MultipleCompanies;
	Items.PrepaymentsOrganization.Visible  = MultipleCompanies;
	Items.SetOffOrganization.Visible = MultipleCompanies;
	
	Items.PaymentsPartner.Visible = (Partner <> Catalogs.Partners.OurEnterprise);
	
	Items.PrepaymentsContract.Visible = UseContracts;
	Items.ByAllContracts.Visible = UseContracts;
	
	If UseContracts Then
		Items.ExplanationOfThePaymentTable.Title = NStr("vi = 'Danh sách các khoản thanh toán chưa được phân bổ và các chứng từ thanh toán liên quan đến hợp đồng đã chọn. Số tiền sẽ được phân bổ cho các đối tượng thanh toán phải trả.';
														|ru = 'Список нераспределенных платежей и документов оплаты, отнесенных на выбранный договор. Сумма будет распределена на зачитываемый объект расчетов.';
														|en = 'List of open payments and AR/AP transactions allocated to the selected document. The amount will be allocated to the AR/AP object being offset.'; fa = 'فهرست پرداخت‌های باز و تراکنش‌های دریافتنی/پرداختنی تخصیص‌یافته به سند انتخاب‌شده. مبلغ به شیء دریافتنی/پرداختنی مورد تهاتر تخصیص خواهد یافت.';
														|it = 'Elenco dei pagamenti non assegnati e dei documenti di pagamento relativi al contratto selezionato. L''importo verrà distribuito all''oggetto di regolamento accreditato.';
														|pl = 'Lista nieprzydzielonych płatności i dokumentów płatności, związanych z wybraną umową. Wartość zostanie przydzielona do zaliczanego obiektu rozliczeń.';
														|tr = 'Dağıtılmayan ödemelerin ve seçilen sözleşmeye ait ödeme belgelerinin listesi. Tutar, hesaplanan alacak/borç nesnesine tahsis edilecektir.'");
	Else
		Items.ExplanationOfThePaymentTable.Title = NStr("vi = 'Danh sách các khoản thanh toán chưa được phân bổ và chứng từ thanh toán. Số tiền sẽ được phân bổ cho các đối tượng thanh toán phải trả.';
														|ru = 'Список нераспределенных платежей и документов оплаты. Сумма будет распределена на зачитываемый объект расчетов.';
														|en = 'List of non-allocated payments and AR/AP transactions. Amount will be allocated to the AR/AP object being offset.'; fa = 'List of non-allocated payments and AR/AP transactions. Amount will be allocated to the AR/AP object being offset.';
														|it = 'Elenco di pagamenti e documenti di pagamento non allocati. L''importo sarà  allocato nell''oggetto del pagamento imputato.';
														|pl = 'Lista nieprzydzielonych płatności i dokumentów płatności. Wartość będzie przydzielona na obiekt kompensaty obliczeń.';
														|tr = 'Dağıtılmayan ödemelerin ve ödeme belgelerinin listesi. Tutar, mahsup edilebilir alacak/borç nesnesine dağıtılacaktır.'");
	EndIf;
	
	If UseContracts Then
		Items.ExplanationOfTheAdvancesTable.Title = NStr("vi = 'Số dư của các tiến bộ theo thỏa thuận đối tác. Để bù đắp / chuyển khoản tạm ứng, chứng từ ""Trả nợ"" sẽ được tạo.';
														|ru = 'Остатки авансов по договорам контрагента. Для зачета/переноса аванса будет создан документ ""Взаимозачет задолженности"".';
														|en = 'Remaining advances under the counterparty contracts. The ""AR/AP offset"" document will be created for prepayment applying/transfer.'; fa = 'پیش‌پرداخت‌های باقی‌مانده بر اساس قراردادهای طرف حساب. سند ""تهاتر دریافتنی/پرداختنی"" برای اعمال/انتقال پیش‌پرداخت ایجاد خواهد شد.';
														|it = 'Saldi di anticipi su contratti di controparte. Per compensare / trasferire un anticipo, verrà creato un documento ""Compensazione del debito"".';
														|pl = 'Ostatki zaliczek wg umów kontrahenta. W celu zaliczenia/przeniesienia zaliczki zostanie utworzony dokument ""Rozliczenia wzajemne zadłużenia"".';
														|tr = 'Cari hesap sözleşmeleri kapsamında avans bakiyesi. Avansı mahsup etmek / devretmek için ""Alacak/Borç mahsubu"" belgesi oluşturulacaktır.'");
	Else
		Items.ExplanationOfTheAdvancesTable.Title = NStr("vi = 'Số dư của những tiến bộ. Để bù đắp / chuyển khoản tạm ứng, chứng từ ""Trả nợ"" sẽ được tạo.';
														|ru = 'Остатки авансов. Для зачета/переноса аванса будет создан документ ""Взаимозачет задолженности"".';
														|en = 'Remaining advances. The ""AR/AP offset"" document will be created for prepayment applying/transfer.'; fa = 'Remaining advances. The ""AR/AP offset"" document will be created for prepayment applying/transfer.';
														|it = 'Saldi di anticipi. Per imputazione/ trasferimento dell''anticipo sarà creato il documento ""Compensazione di debito""';
														|pl = 'Pozostałości zaliczek. Dla zaksięgowania/przeniesienia zaliczki zostanie utworzony dokument ""Kompensata zobowiązania"".';
														|tr = 'Avans bakiyeleri. Avansı mahsup etmek / transfer etmek için ""Alacak/Borç mahsubu"" belgesi oluşturulur.'");
	EndIf;
	
	Items.PaymentsAvailableToSetOff.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Được phép (%1)';
			|ru = 'Доступно (%1)';
			|en = 'Available (%1)'; fa = 'Available (%1)';
			|it = 'Disponibile (%1)';
			|pl = 'Dostępne (%1)';
			|tr = 'Erişilebilir (%1)'"),
		String(ARAPCurrency));
	Items.PrepaymentsAvailableToSetOff.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Được phép (%1)';
			|ru = 'Доступно (%1)';
			|en = 'Available (%1)'; fa = 'Available (%1)';
			|it = 'Disponibile (%1)';
			|pl = 'Dostępne (%1)';
			|tr = 'Erişilebilir (%1)'"),
		String(ARAPCurrency));
	Items.SetOffAmountCredited_2.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã khấu trừ (%1)';
			|ru = 'Зачтено (%1)';
			|en = 'Offset (%1)'; fa = 'Offset (%1)';
			|it = 'Imputato (%1)';
			|pl = 'Zaksięgowano (%1)';
			|tr = 'Mahsup edildi (%1)'"),
		String(ARAPCurrency));
	
	Title = NStr("vi = 'Khấu trừ thanh toán theo:';
				|ru = 'Зачет оплат по:';
				|en = 'Offset payments for:'; fa = 'Offset payments for:';
				|it = 'Accreditamento di pagamenti per:';
				|pl = 'Zaliczenie płatności do:';
				|tr = 'Ödeme mahsubu:'") + " " + String(ARAPObject);
	
	Items.SetOffSumCompl.Visible = ARAPCurrency <> LocalAccountingCurrency;
	Items.SetOffSumMan.Visible  = ARAPCurrency <> ManagementAccountingCurrency;
	Items.PrepaymentsSumCompl.Visible  = ARAPCurrency <> LocalAccountingCurrency;
	Items.PrepaymentsSumMan.Visible   = ARAPCurrency <> ManagementAccountingCurrency;
	
	Items.PickUpGiftCertificate.Visible = (NewOnlineARAPAccounting
		And GetFunctionalOption("UseGiftCards")
		And GiftCertificatesServer.TypeIsAllowedForCreditingPaymentsWithGiftCertificates(TypeOf(Document)));
	
EndProcedure

#EndRegion

#Region FillingInTableOfSettlementsWithPartners

&AtServer
Procedure FillInTableForSettlementsWithPartners()
	
	Payments.Clear();
	Prepayments.Clear();
	SetOff.Clear();
	
	Query = InitializeRequestBasedOnCalculations();
	
	If ThereAreCustomersARAP Then
		Query.Text = RequestTextForSettlementsWithClients();
	Else
		Query.Text = RequestTextForSettlementsWithSuppliers();
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	NumberOfRequests_ = Result.UBound();
	
	//Payments
	SamplePayment = Result[NumberOfRequests_].Select();
	While SamplePayment.Next() Do
		
		NewRow = Payments.Add();
		FillPropertyValues(NewRow, SamplePayment);
		
		NewRow.DataVersion = DocumentDataVersion(SamplePayment.Document);
		
		If ARAPCurrency <> SamplePayment.ARAPCurrency Then
			NewRow.AvailableToSetOff = ConvertAmountToSettlementCurrency(
				SamplePayment.AmountInPaymentCurrency, SamplePayment.Currency, SamplePayment.Date);
		EndIf;
	EndDo;
	
	TableOfPayment = Payments.Unload();
	TableOfPayment.GroupBy("Organization, Document, DataVersion, DocumentAmount, Currency, Partner, DataChanged1, Date, EditingAvailable, DecryptionOfThePaymentObject, ARAPObject", "AvailableToSetOff, AmountInPaymentCurrency");
	Payments.Load(TableOfPayment);
	
	// SetOff
	TableCredited = Result[NumberOfRequests_-2].Unload();
		
	For Each LineCredited In TableCredited Do
		
		NewRow = SetOff.Add();
		FillPropertyValues(NewRow, LineCredited);
		NewRow.DataVersion = DocumentDataVersion(LineCredited.Document);
		
	EndDo;
	
	// Prepayments
	If NewOnlineARAPAccounting Then
		AdvancesAreCalculated = True;
	Else
		DimensionKeys.LoadValues(Query.TempTablesManager.Tables["TTAccountingAnalyticsForPartners"].GetData().Unload().UnloadColumn("DimensionKey"));
		AdvancesAreCalculated = Not ThereAreTasksForDistributionOfSettlements(ThereAreCustomersARAP, DimensionKeys);
	EndIf;
	
	FillInAdvanceTable(Query);
	
	CurrentDataPeriod = Undefined;
	If NewOnlineARAPAccounting Then

		ARAPObjectUsed = New Array;
		CommonClientServer.SupplementArray(ARAPObjectUsed, Payments.Unload( ,
			"ARAPObject").UnloadColumn("ARAPObject"));
		CommonClientServer.SupplementArray(ARAPObjectUsed, Prepayments.Unload( ,
			"ARAPObject").UnloadColumn("ARAPObject"));
		CommonClientServer.SupplementArray(ARAPObjectUsed, SetOff.Unload( ,
			"ARAPObject").UnloadColumn("ARAPObject"));
		ARAPObjectUsed = CommonClientServer.CollapseArray(ARAPObjectUsed);

		CurrentDataPeriod = InformationRegisters.JobsForARAPAllocating.CurrentPeriodOfCalculatedDataOnMutualSettlements(
			Undefined, ARAPObjectUsed);

		If CurrentDataPeriod <> Undefined Then
			Common.MessageToUser(
				ARAPAccountingServer.TextOfWarningOfAssignmentOfDistributionOfMutualSettlements());
		EndIf;
		
	EndIf;
	
	If CurrentDataPeriod = Undefined Then
		Items.LabelPeriodOfCurrentData.Visible = False;
	Else
		If ValueIsFilled(CurrentDataPeriod) Then
			LabelText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Dữ liệu về đối trừ công nợ có hiệu lực đến %1';
						|ru = 'Данные по взаиморасчетам актуальны на %1';
						|en = 'AR/AP accounting data is relevant as of %1'; fa = 'AR/AP accounting data is relevant as of %1';
						|it = 'AR/AP accounting data is relevant as of %1';
						|pl = 'AR/AP accounting data is relevant as of %1';
						|tr = 'Alacak/Borç muhasebesi verileri %1 itibarıyla günceldir'", Common.DefaultLanguageCode()),
				Format(CurrentDataPeriod, "DLF=DT;"));
		Else
			LabelText = NStr("vi = 'Dữ liệu về đối trừ công nợ không còn hiệu lực';
							|ru = 'Данные по взаиморасчетам неактуальны';
							|en = 'AR/AP accounting data is outdated'; fa = 'AR/AP accounting data is outdated';
							|it = 'AR/AP accounting data is outdated';
							|pl = 'AR/AP accounting data is outdated';
							|tr = 'Alacak/Borç muhasebesi verileri güncel değildir'",
				Common.DefaultLanguageCode());
		EndIf;
		Items.LabelPeriodOfCurrentData.Title = LabelText;
		Items.LabelPeriodOfCurrentData.Visible = True;
	EndIf;
	
	CalculateAmountOfCredit();
	CalculateNumberOfRows_();
	
EndProcedure

&AtServer
Function GetAmountToBePaid()
	
	If ARAPObjectType = Enums.ARAPObjectTypes.Contract
		And TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		FilterRecorder = Common.ObjectAttributeValue(Contract,"ContractSchedule");
	Else
		FilterRecorder = Document;
	EndIf;
		
	If ARAPObjectType = Enums.ARAPObjectTypes.Contract 
		And Not ValueIsFilled(FilterRecorder) Then
		AmountDueBalanceUnderContract = True;
		Query = New Query("
		|SELECT
		|	-VendorsARAPAccounting.AmountDueBalance AS AmountDue
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,ARAPObject = &ARAPObject
		|														AND AccountingDimensionByPartners.Partner = &DocumentPartner
		|														AND AccountingDimensionByPartners.Organization = (&Organization)) AS VendorsARAPAccounting
		|WHERE
		|	ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|
		|UNION ALL
		|
		|SELECT
		|	CustomersARAPAccounting.AmountDueBalance AS AmountDue
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,ARAPObject = &ARAPObject
		|														AND AccountingDimensionByPartners.Partner = &DocumentPartner
		|														AND AccountingDimensionByPartners.Organization IN (&Organization)) AS CustomersARAPAccounting
		|WHERE
		|	ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|
		|");
		Query.SetParameter("ARAPObject",ARAPObject);
		Query.SetParameter("DocumentPartner",DocumentPartner);
		Query.SetParameter("Organization",Organization);
		
	Else
		AmountDueBalanceUnderContract = False;
		AmountDueBalanceUnderContract = False;
		Query = New Query("
		|SELECT
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN VendorsARAPAccounting.AmountDue
		|		ELSE -VendorsARAPAccounting.AmountDue
		|	END) AS AmountDue
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.Recorder = &Recorder
		|	AND VendorsARAPAccounting.ARAPObject = &ARAPObject
		|	AND VendorsARAPAccounting.Active
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|HAVING
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN VendorsARAPAccounting.AmountDue
		|		ELSE -VendorsARAPAccounting.AmountDue
		|	END)  > 0
		|	
		|UNION ALL
		|
		|SELECT
		|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN -CustomersARAPAccounting.AmountDue
		|		ELSE CustomersARAPAccounting.AmountDue
		|	END) AS AmountDue
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.Recorder = &Recorder
		|	AND CustomersARAPAccounting.ARAPObject = &ARAPObject
		|	AND CustomersARAPAccounting.Active
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
		|HAVING
		|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN -CustomersARAPAccounting.AmountDue
		|		ELSE CustomersARAPAccounting.AmountDue
		|	END) > 0
		|");
		Query.SetParameter("Recorder", FilterRecorder);
		Query.SetParameter("ARAPObject", ARAPObject);
		
	EndIf;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		AmountDue = Selection.AmountDue;
	Else
		AmountDue = 0;
	EndIf;
	
	Return AmountDue;
	
EndFunction // Get the sum of the payment()

&AtServer
Function AmountOfOrderAdvances(LinkToOrder)
	
	Query = New Query;
	Query.SetParameter("Ref", LinkToOrder);  
	// The Payment Offset command is available on the list form only for customer orders
	Query.Text = 
		"SELECT
		|	ISNULL(SUM(SalesOrderPaymentScheduleSteps.PaymentAmount + SalesOrderPaymentScheduleSteps.PackageDepositValue), 0) AS Sum
		|FROM
		|	Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
		|WHERE
		|	SalesOrderPaymentScheduleSteps.Ref = &Ref
		|	AND (SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			OR SalesOrderPaymentScheduleSteps.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.BeforeShipmentDate))";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Sum;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Procedure GetPaymentDetailsWithPartner()
	
	Attributes = "Organization, Counterparty, Partner, ARAPCurrency, Currency, AmountARAP, Sum,
		|	Date, PaymentType_, State, ARAPObjectType, Contract, LineOfBusiness";
	
	AttributesStructure1 = Common.ObjectAttributesValues(ARAPObject, Attributes);
	
	DocumentDate           = AttributesStructure1.Date;
	Organization             = AttributesStructure1.Organization;
	Counterparty              = AttributesStructure1.Counterparty;
	Partner                 = AttributesStructure1.Partner;
	ARAPCurrency    = AttributesStructure1.ARAPCurrency;
	Currency                  = AttributesStructure1.Currency;
	Contract                 = AttributesStructure1.Contract;
	LineOfBusiness = AttributesStructure1.LineOfBusiness;
	PaymentType_             = AttributesStructure1.PaymentType_;
	State               = AttributesStructure1.State;
	ARAPObjectType      = AttributesStructure1.ARAPObjectType;
	
	ThereAreVendorsARAP = PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ThereAreCustomersARAP    = PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ThereAreSettlementsBetweenCompanies = Partner = Catalogs.Partners.OurEnterprise;
	
	TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed = True;
	If ValueIsFilled(Contract) And Not ThereAreSettlementsBetweenCompanies Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, "TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed,ItIsAllowedToWorkWithSubsidiaryPartners");
		TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed = ContractDetails_.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed;
	EndIf;
	If Not AmountOfSettlementsInParameters Then
		If State = 1 Or ARAPObjectType = Enums.ARAPObjectTypes.Contract Then
			AmountARAP = GetAmountToBePaid();
		Else
			If AttributesStructure1.AmountARAP = 0 Then
				If AttributesStructure1.Currency = AttributesStructure1.ARAPCurrency Then
					AmountARAP = AttributesStructure1.Sum;
				Else
					AmountARAP = ProcessingOfExchangeRatesTM.ConvertToCurrency(
															AttributesStructure1.Sum,
															SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(AttributesStructure1.Organization),
															AttributesStructure1.Currency,
															AttributesStructure1.ARAPCurrency,
															AttributesStructure1.Date,
															ARAPObject);
				EndIf;
			Else
				AmountARAP = AttributesStructure1.AmountARAP;
			EndIf;
		EndIf;
	EndIf;
	
	CompanyArray = New Array;
	ParentCompany = Organization;
	
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") 
		And (ThereAreCustomersARAP Or ThereAreVendorsARAP) Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.ParentCompany AS Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed
		|	AND Companies.BranchOffice");
		
		Query.SetParameter("Organization", Organization);
		
		CompanyArray = Query.Execute().Unload().UnloadColumn("Ref");
		If CompanyArray.Count() > 0 Then
			ParentCompany = CompanyArray[0];
		EndIf;
		
		BranchOffices_ = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(ParentCompany);
		If TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed Or Organization = ParentCompany Then
			For Each Branch_ In BranchOffices_ Do
				CompanyArray.Add(Branch_);
			EndDo;
		EndIf;
		
	EndIf;
	
	CompanyArray.Add(Organization);
	AvailableCompanies.LoadValues(CompanyArray);
	
	ArrayOfPartners = New Array;
	If Partner <> Catalogs.Partners.UnknownPartner Then
		
		Query = New Query("
		|SELECT
		|	RegisterData.Parent AS Partner
		|INTO TTHead
		|FROM
		|	InformationRegister.PartnerHierarchy AS RegisterData
		|WHERE
		|	RegisterData.Partner = &Partner
		|;
		|
		|SELECT
		|	&Partner AS Partner
		|
		|UNION ALL
		|
		|SELECT
		|	Head_1.Partner AS Partner
		|FROM
		|	TTHead AS Head_1
		|
		|UNION ALL
		|
		|SELECT
		|	RegisterData.Partner AS Partner
		|FROM
		|	InformationRegister.PartnerHierarchy AS RegisterData
		|	INNER JOIN TTHead AS Head_1
		|	ON RegisterData.Parent = Head_1.Partner");
		
		Query.SetParameter("Partner", Partner);
		ArrayOfPartners = Query.Execute().Unload().UnloadColumn("Partner");
		
	EndIf;
	
	ArrayOfPartners.Add(Catalogs.Partners.UnknownPartner);
	AvailablePartners.LoadValues(ArrayOfPartners);
	
	If (ThereAreCustomersARAP And GetFunctionalOption("UseCustomerContracts")
		Or (ThereAreVendorsARAP And GetFunctionalOption("UseContractsWithVendors"))) Then
		UseContracts = True;
	EndIf;
	
EndProcedure

&AtServer
Function InitializeRequestBasedOnCalculations()
	
	Query = New Query;
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Organization",                  AvailableCompanies);
	Query.SetParameter("Partner",                      Partner);
	Query.SetParameter("DocumentPartner",             DocumentPartner);
	Query.SetParameter("AvailablePartners",            AvailablePartners);
	Query.SetParameter("Counterparty",                   Counterparty);
	Query.SetParameter("Contract",                      Contract);
	Query.SetParameter("LineOfBusiness",      LineOfBusiness);
	Query.SetParameter("Document",                     Document);
	Query.SetParameter("ARAPCurrency",         ARAPCurrency);
	Query.SetParameter("ARAPObject",               ARAPObject);
	Query.SetParameter("DocumentDate",                BegOfDay(DocumentDate));
	Query.SetParameter("CurrentMonth",                 BegOfMonth(CurrentSessionDate()));
	Query.SetParameter("ARAPDetails",           ARAPDetails.Unload());
	Query.SetParameter("ARAPObjectInvoice",      ARAPObjectType = Enums.ARAPObjectTypes.Invoice);
	Query.SetParameter("CurrencyOfComplianceAccounting",              LocalAccountingCurrency);
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("ItIsManagementOrganization", Organization = Catalogs.Companies.ManagementCompany);
	Query.SetParameter("OffsetFromTermsOfAgreement",        ListOfObjects.Count() > 0);
	Query.SetParameter("ListOfObjects",               ListOfObjects);
	Query.SetParameter("TypeOfOperationYandexCheckout", Type("Undefined"));
	TextTemporaryTables = TextTemporaryTables();
	
	If ThereAreCustomersARAP Then
		Query.Text = TextTemporaryTables + TemporaryTablesForSettlementsWithClients();
	Else
		Query.Text = TextTemporaryTables + TemporaryTablesForSettlementsWithSuppliers();
	EndIf;
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Return Query;
	
EndFunction

&AtServer
Procedure FillInAdvanceTable(Val Query = Undefined)
	
	Prepayments.Clear();
	
	If Query = Undefined Then
		Query = InitializeRequestBasedOnCalculations();
		If ThereAreCustomersARAP Then
			Query.Text = RequestTextForSettlementsWithClients();
		Else
			Query.Text = RequestTextForSettlementsWithSuppliers();
		EndIf;
		
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);
	EndIf;
	
	If ThereAreVendorsARAP Then
		Query.Text = RequestTextAdvancesForSettlementsWithSuppliers(Query);
	Else
		Query.Text = RequestTextAdvancesForSettlementsWithCustomers(Query);
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	SamplingAdvances = Result.Select();
	While SamplingAdvances.Next() Do
		
		NewRow = Prepayments.Add();
		FillPropertyValues(NewRow, SamplingAdvances);
		NewRow.AmountInPaymentCurrency = NewRow.AvailableToSetOff;
		
		If ARAPCurrency <> SamplingAdvances.ARAPCurrency Then
			If ARAPCurrency = LocalAccountingCurrency Then
				NewRow.AvailableToSetOff = SamplingAdvances.SumCompl;
			ElsIf ARAPCurrency = ManagementAccountingCurrency Then
				NewRow.AvailableToSetOff = SamplingAdvances.SumMan;
			Else
				NewRow.AvailableToSetOff = ConvertAmountToSettlementCurrency(
					SamplingAdvances.AvailableToSetOff, SamplingAdvances.ARAPCurrency, SamplingAdvances.Date);
			EndIf;
		EndIf;
	EndDo;
	
	CalculateNumberOfRows_();
	
	InstallAdvancesPage();
	
EndProcedure

&AtServer
Function TextTemporaryTables()
	
	QueryText = "
	|SELECT
	|	DimensionByPartners.DimensionKey AS DimensionKey,
	|	DimensionByPartners.Partner AS Partner,
	|	DimensionByPartners.Organization AS Organization,
	|	DimensionByPartners.Counterparty AS Counterparty,
	|	DimensionByPartners.Contract AS Contract,
	|	DimensionByPartners.Partner = &DocumentPartner AS ThisIsPartnerOfDocument
	|
	|INTO TTAccountingAnalyticsForPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|WHERE
	|	(DimensionByPartners.Organization IN (&Organization))
	|	AND (DimensionByPartners.Partner IN (&Partner)
	|		OR DimensionByPartners.Partner IN (&AvailablePartners) AND ISNULL(DimensionByPartners.Contract.ItIsAllowedToWorkWithSubsidiaryPartners, TRUE))
	|	AND DimensionByPartners.Counterparty = &Counterparty
	|INDEX BY
	|	DimensionKey
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableDecryptionOfPaymentInvoice.Partner        AS Partner,
	|	TableDecryptionOfPaymentInvoice.ARAPObject AS ARAPObject,
	|	TableDecryptionOfPaymentInvoice.Counterparty     AS Counterparty,
	|	TableDecryptionOfPaymentInvoice.Contract        AS Contract,
	|	TableDecryptionOfPaymentInvoice.Organization    AS Organization,
	|	TableDecryptionOfPaymentInvoice.Currency         AS Currency,
	|	TableDecryptionOfPaymentInvoice.Sum          AS Sum,
	|	TableDecryptionOfPaymentInvoice.AmountARAP AS AmountARAP
	|INTO TableDecryptionOfPaymentInvoice
	|FROM &ARAPDetails AS TableDecryptionOfPaymentInvoice
	|;";
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextDocumentsThatAreNotAvailableForRecording()
	
	QueryText = "
		|SELECT
		|	UNDEFINED AS Document
		|INTO TTUnrecordedDocuments
		|";
	
	If GetFunctionalOption("UseFinancialDocumentVerification") Then
		QueryText = "
			|SELECT DISTINCT
			|	DocumentVerificationOverridable.Document AS Document
			|INTO TTUnrecordedDocuments
			|FROM
			|	(SELECT T.Document AS Document FROM TTUnallocatedPayments AS T
			|		UNION ALL SELECT &Document AS Document) AS Data
			|	INNER JOIN DocumentVerificationOverridable AS DocumentVerificationOverridable
			|		ON Data.Document = DocumentVerificationOverridable.Document
			|		AND DocumentVerificationOverridable.CheckStatus = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
			|";
		DocumentVerificationServer.OverrideVerificationStatusesInRequestTextTakingIntoAccountLocks(QueryText, "Data.Document");
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextUnallocatedPayments()
	
	QueryText = "
	|
	|SELECT *
	|INTO TTAvailableUnallocatedPayments
	|FROM TTUnallocatedPayments AS T
	|WHERE NOT (T.Document IN (SELECT TT.Document FROM TTUnrecordedDocuments AS TT)
	|			AND NOT T.DecryptionOfThePaymentObject)
	|	AND NOT (&Document IN (SELECT TT.Document FROM TTUnrecordedDocuments AS TT)
	|			AND T.DecryptionOfThePaymentObject)
	|
	|;
	|
	|SELECT *
	|FROM TTAvailableUnallocatedPayments AS T
	|WHERE T.AvailableToSetOff > 0
	|
	|ORDER BY
	|	T.Organization,
	|	T.DATE
	|;";
	
	Return QueryText;
	
EndFunction

#Region VendorsARAPAccounting

&AtServer
Function RequestTextForSettlementsWithSuppliers()
	
	QueryTexts = New Array;
	
	QueryTexts.Add("
	// Credited (credited payments and advances)
	|SELECT
	|	VendorsARAPAccounting.Currency                                   AS ARAPCurrency,
	|	CASE 
	|		WHEN NOT IsPatch.Ref IS NULL
	|			THEN IsPatch.CorrectedDocument
	|		WHEN VendorsARAPAccounting.CorARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|			AND NOT VendorsARAPAccounting.Recorder REFS Document.ARAPSettlement
	|			THEN ARAPObjects.Object
	|		ELSE VendorsARAPAccounting.Recorder
	|	END                                                         AS Document,
	|	CASE WHEN VendorsARAPAccounting.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|		THEN VendorsARAPAccounting.CorPartnerAccountingDimension.Organization
	|		ELSE ARAPObjects.Organization
	|	END                                                         AS Organization,
	|	ARAPObjects.Counterparty                                    AS Counterparty,
	|	ARAPObjects.Partner                                       AS Partner,
	|	CASE 
	|		WHEN VendorsARAPAccounting.CorARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|			AND NOT VendorsARAPAccounting.Recorder REFS Document.ARAPSettlement
	|			THEN VendorsARAPAccounting.CorARAPObject.Date
	|		ELSE ARAPObjects.Date
	|	END                                                         AS Date,
	|	ARAPObjects.Sum                                         AS DocumentAmount,
	|	ARAPObjects.Currency                                        AS Currency,
	|	VendorsARAPAccounting.CorARAPObject                        AS ARAPObject,
	|	ISNULL(VendorsARAPAccounting.CorARAPObject.Object, UNDEFINED) AS Object,
	|	ARAPObjects.Contract                                       AS Contract,
	|
	|	CASE 
	|		WHEN VendorsARAPAccounting.Sum < 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.Sum > 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
	|			THEN -VendorsARAPAccounting.Sum
	|		ELSE 0
	|	END                                                        AS AmountCredited_2,
	|	CASE 
	|		WHEN VendorsARAPAccounting.Sum < 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.Sum > 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
	|			THEN -VendorsARAPAccounting.Sum
	|		ELSE 0
	|	END *
	|	CASE WHEN ARAPObjects.Sum <> 0 AND ARAPObjects.AmountARAP <> 0
	|			THEN ARAPObjects.AmountARAP/ARAPObjects.Sum
	|		ELSE 1
	|	END                                                            AS AmountInPaymentCurrency,
	|	ISNULL(DistributedCalculations.SumCompl, 0)                     AS SumCompl,
	|	ISNULL(DistributedCalculations.SumMan, 0)                      AS SumMan,
	|	
	|	NOT VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
	|		AND ThisIsDocumentThatIsBeingCorrected.Ref IS NULL
	|		AND NOT VendorsARAPAccounting.Recorder REFS Document.ARAPAdjustment
	|		AND NOT VendorsARAPAccounting.Recorder REFS Document.OBEntry
	|		AND NOT VendorsARAPAccounting.Recorder REFS Document.OBEntryARAP
	|		AND NOT VendorsARAPAccounting.Recorder REFS Document.ReversingEntry
	|		AND NOT VendorsARAPAccounting.Recorder REFS Document.ElectronicTicketTransaction
	|		AND NOT (VendorsARAPAccounting.Recorder REFS Document.ReturnOfGoodsToVendor AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|		AND NOT (VendorsARAPAccounting.Sum < 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt) AND VendorsARAPAccounting.Recorder REFS Document.ARAPSettlement) 
	|		AND NOT (VendorsARAPAccounting.Recorder REFS Document.ARAPSettlement AND CAST(VendorsARAPAccounting.Recorder AS Document.ARAPSettlement).Currency = VALUE(Catalog.Currencies.EmptyRef)) AS EditingAvailable,
	|	VendorsARAPAccounting.Recorder = &Document                     AS DecryptionOfThePaymentObject,
	|	1                                                                AS Order
	|INTO SetOff
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		LEFT JOIN DistributedCalculations AS DistributedCalculations
	|			ON CASE 
	|				WHEN VendorsARAPAccounting.CorARAPObject <> UNDEFINED
	|					AND NOT VendorsARAPAccounting.Recorder REFS Document.ARAPSettlement
	|					THEN VendorsARAPAccounting.CorARAPObject.Object
	|				ELSE VendorsARAPAccounting.Recorder
	|			END = DistributedCalculations.Recorder
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON VendorsARAPAccounting.ARAPObject = ARAPObjects.Ref
	|				AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = ARAPObjects.Organization
	|		INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			ON VendorsARAPAccounting.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS IsPatch
	|			ON IsPatch.Ref = VendorsARAPAccounting.Recorder
	|				AND IsPatch.ReverseTransactionCorrection
	|				AND NOT IsPatch.Ref REFS Document.ReversingEntry
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS ThisIsDocumentThatIsBeingCorrected
	|			ON ThisIsDocumentThatIsBeingCorrected.ReversedDocument = VendorsARAPAccounting.Recorder
	|				AND ThisIsDocumentThatIsBeingCorrected.Posted
	|WHERE
	|	VendorsARAPAccounting.ARAPObject = &ARAPObject
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND CASE 
	|		WHEN VendorsARAPAccounting.Sum < 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VendorsARAPAccounting.Sum
	|		WHEN VendorsARAPAccounting.Sum > 0 AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
	|			THEN -VendorsARAPAccounting.Sum
	|		ELSE 0
	|	END <> 0
	|	AND VendorsARAPAccounting.Active
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor)
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)
	|	AND NOT VendorsARAPAccounting.Recorder REFS Document.ARAPAccountingScheduleAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPDetails.Currency                                        AS ARAPCurrency,
	|	ARAPDetails.ARAPObject.Object                         AS Document,
	|	ARAPDetails.ARAPObject.Organization                    AS Organization,
	|	ARAPDetails.ARAPObject.Counterparty                     AS Counterparty,
	|	ARAPDetails.ARAPObject.Partner                        AS Partner,
	|	ARAPDetails.ARAPObject.Date                           AS Date,
	|	ARAPDetails.ARAPObject.Sum                          AS DocumentAmount,
	|	ARAPDetails.ARAPObject.Currency                         AS Currency,
	|	ARAPDetails.ARAPObject                                AS ARAPObject,
	|	ARAPDetails.ARAPObject.Object                         AS Object,
	|	ARAPDetails.Contract                                       AS Contract,
	|
	|	ARAPDetails.AmountARAP                           AS AmountCredited_2,
	|	ARAPDetails.Sum                                         AS AmountInPaymentCurrency,
	|	0                                                                AS SumCompl,
	|	0                                                                AS SumMan,
	|
	|	TRUE                                                           AS EditingAvailable,
	|	TRUE                                                           AS DecryptionOfThePaymentObject,
	|	1                                                                AS Order
	|FROM
	|	TableDecryptionOfPaymentInvoice AS ARAPDetails
	|WHERE
	|	ARAPDetails.ARAPObject <> &ARAPObject
	|	AND ARAPDetails.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND &Document <> ARAPDetails.ARAPObject.OBJECT
	|;
	|SELECT
	|	SettlementOfARAP.Ref AS Ref,
	|	MAX(SettlementOfARAP.ARAPObject) AS ARAPObject,
	|	MAX(SettlementOfARAP.ARAPObject.Object) AS Object,
	|	NULL AS SumCompl,
	|	NULL AS SumMan
	|	
	|INTO TTDebtOffsets
	|FROM Document.ARAPSettlement.AccountsReceivable AS SettlementOfARAP
	|WHERE NOT &NewOnlineARAPAccounting
	|	AND SettlementOfARAP.Ref IN (SELECT T.Document FROM SetOff AS T)
	|GROUP BY
	|	SettlementOfARAP.Ref
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CalculationsByTerms.DocumentRecorder AS Ref,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	CalculationsByTerms.ARAPObject.Object AS Object,
	|	SUM(CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan) AS SumMan
	|	
	|
	|FROM AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE &NewOnlineARAPAccounting
	|	AND CalculationsByTerms.DocumentRecorder IN (SELECT T.Document FROM SetOff AS T)
	|	AND CalculationsByTerms.CalculationObjectReceiver = &ARAPObject
	|	AND CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder,
	|	CalculationsByTerms.ARAPObject
	|	
	|INDEX BY
	|	Ref,
	|	ARAPObject
	|;
	// Availability of tasks for advances
	|SELECT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|FROM
	|	TTAccountingAnalyticsForPartners AS DimensionByPartners
	|;
	|SELECT
	|	SetOff.ARAPCurrency         AS ARAPCurrency,
	|	SetOff.Document                     AS Document,
	|	SetOff.Organization                  AS Organization,
	|	SetOff.Counterparty                   AS Counterparty,
	|	SetOff.Partner                      AS Partner,
	|	SetOff.Date                         AS Date,
	|	SetOff.DocumentAmount               AS DocumentAmount,
	|	SetOff.Currency                       AS Currency,
	|	SetOff.Contract                      AS Contract,
	|
	|	SUM(SetOff.AmountCredited_2)          AS AmountCredited_2,
	|	SUM(SetOff.AmountInPaymentCurrency)   AS AmountInPaymentCurrency,
	|	MAX(ISNULL(SettlementOfARAP.SumCompl,SetOff.SumCompl)) AS SumCompl,
	|	MAX(ISNULL(SettlementOfARAP.SumMan,SetOff.SumMan))   AS SumMan,
	|
	|	MIN(SetOff.EditingAvailable)       AS EditingAvailable,
	|	SetOff.DecryptionOfThePaymentObject   AS DecryptionOfThePaymentObject,
	|	SetOff.Order                      AS Order,
	|	MAX(ISNULL(SettlementOfARAP.ARAPObject,SetOff.ARAPObject)) AS ARAPObject,
	|	MAX(ISNULL(SettlementOfARAP.ARAPObject.Object,SetOff.Object)) AS Object
	|FROM
	|	SetOff AS SetOff
	|		LEFT JOIN TTDebtOffsets AS SettlementOfARAP
	|			ON SettlementOfARAP.Ref = SetOff.Document
	|			AND (SettlementOfARAP.ARAPObject = SetOff.ARAPObject
	|				OR NOT &NewOnlineARAPAccounting)
	|GROUP BY
	|	SetOff.ARAPCurrency,
	|	SetOff.Document,
	|	SetOff.ARAPObject,
	|	SetOff.Organization,
	|	SetOff.Counterparty,
	|	SetOff.Partner,
	|	SetOff.Date,
	|	SetOff.DocumentAmount,
	|	SetOff.Currency,
	|	SetOff.Contract,
	|	SetOff.DecryptionOfThePaymentObject,
	|	SetOff.Order
	|HAVING
	|	SUM(SetOff.AmountCredited_2) <> 0
	|ORDER BY
	|	Organization,
	|	Date
	|;");
	
	QueryTexts.Add(TextUnallocatedPayments());
	
	Return StrConcat(QueryTexts);
	
EndFunction

&AtServer
Function TemporaryTablesForSettlementsWithSuppliers()
	
	QueryTexts = New Array;
	
	QueryTexts.Add("
	|SELECT
	|	VendorsARAPAccounting.ARAPObject                             AS ARAPObject,
	|	VendorsARAPAccounting.Currency                                     AS ARAPCurrency,
	|	ARAPObjects.Object                                          AS Document,
	|	VendorsARAPAccounting.AccountingDimensionByPartners                  AS DimensionKey,
	|	ARAPObjects.Organization                                     AS Organization,
	|	ARAPObjects.Partner                                         AS Partner,
	|	ARAPObjects.Counterparty                                      AS Counterparty,
	|	ARAPObjects.Date                                            AS Date,
	|	ARAPObjects.Sum                                           AS DocumentAmount,
	|	ARAPObjects.Currency                                          AS Currency,
	|	VendorsARAPAccounting.SumBalance - ISNULL(Details.Sum,0) AS AvailableToSetOff,
	|	CASE WHEN ARAPObjects.Sum <> 0 AND ARAPObjects.AmountARAP <> 0
	|		THEN (VendorsARAPAccounting.SumBalance - ISNULL(Details.Sum,0)) * ARAPObjects.AmountARAP/ARAPObjects.Sum
	|		ELSE VendorsARAPAccounting.SumBalance - ISNULL(Details.Sum,0)
	|	END                                                           AS AmountInPaymentCurrency,
	|	TRUE                                                          AS EditingAvailable,
	|	&ARAPObjectInvoice
	|		AND (&OffsetFromTermsOfAgreement 
	|				AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|					OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|			OR (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|					AND BEGINOFPERIOD(ARAPObjects.Date,DAY) < &DocumentDate)
	|			OR (&ItIsManagementOrganization
	|					AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice))
	|				)                                                    AS DecryptionOfThePaymentObject
	|INTO TTUnallocatedPayments
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,
	|		AccountingDimensionByPartners IN (
	|			SELECT
	|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
	|			FROM
	|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			)) AS VendorsARAPAccounting
	|	
	|	INNER JOIN
	|		Catalog.ARAPObjects AS ARAPObjects
	|	ON
	|		ARAPObjects.Ref = VendorsARAPAccounting.ARAPObject
	|	LEFT JOIN TableDecryptionOfPaymentInvoice AS Details
	|		ON Details.ARAPObject = VendorsARAPAccounting.ARAPObject
	|	INNER JOIN
	|		TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			ON VendorsARAPAccounting.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|	
	|WHERE
	// Exclude primary documents with a date greater than the invoice date or an empty Contract
	|	NOT (ARAPObjects.Object REFS Document.SourceDocument 
	|			AND (ARAPObjects.Date >= &DocumentDate AND &ARAPObjectInvoice 
	|				OR ARAPObjects.Contract IN (VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|												,VALUE(Catalog.IntercompanyContracts.EmptyRef))))
	// Payments of any period with the same Contract
	|	AND (ARAPObjects.Contract = &Contract
	// Payments with an empty Contract, but later than the document date
	|		OR NOT (ARAPObjects.Date < &DocumentDate AND &ARAPObjectInvoice)
	|			AND ARAPObjects.Contract IN (VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|												,VALUE(Catalog.IntercompanyContracts.EmptyRef))
	// Invoices are Local only. before the document date
	|	OR (&ItIsManagementOrganization
	|		AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)))
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND ARAPObjects.LineOfBusiness = &LineOfBusiness
	|	AND ARAPObjects.ARAPCurrency = &ARAPCurrency
	|	AND VendorsARAPAccounting.SumBalance > 0
	|	AND (&ARAPObjectInvoice
	|			AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|				OR ARAPObjects.Object IN (&ListOfObjects)
	|						AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|							OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|				OR &ItIsManagementOrganization
	|						AND BEGINOFPERIOD(ARAPObjects.Date,DAY) <= &DocumentDate
	|					)
	|		OR NOT &ARAPObjectInvoice
	|			AND &DocumentDate < BEGINOFPERIOD(ARAPObjects.Date,DAY)
	|			AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn))
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Credited to upr and regl
	|SELECT
	|	CalculationsAccordingToDocuments.Recorder AS Recorder,
	|	SUM(CalculationsAccordingToDocuments.PrepaymentLocal + CalculationsAccordingToDocuments.DebtLocal) AS SumCompl,
	|	SUM(CalculationsAccordingToDocuments.PrepaymentMan + CalculationsAccordingToDocuments.ARAPMan) AS SumMan
	|INTO DistributedCalculations
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (SELECT DimensionKey FROM TTAccountingAnalyticsForPartners)
	|	AND &ARAPObject = CalculationsAccordingToDocuments.PurchaseOrder
	|	AND CalculationsAccordingToDocuments.Active
	|GROUP BY
	|	CalculationsAccordingToDocuments.Recorder
	|	
	|UNION ALL
	|	
	// invoice calculations
	|SELECT
	|	CalculationsByTerms.ARAPDocument AS Recorder,
	|	SUM(CalculationsByTerms.PrepaymentLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.PrepaymentMan) AS SumMan
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			ON CalculationsByTerms.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND &ARAPObject = CalculationsByTerms.ARAPObject
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.Prepayment <> 0 
	|	AND CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CalculationsByTerms.ARAPObject.ARAPObjectType IN (
	|		VALUE(Enum.ARAPObjectTypes.Invoice),
	|		VALUE(Enum.ARAPObjectTypes.PaymentReturn))
	|	AND NOT CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.ARAPDocument 
	|	
	|	UNION ALL
	|	
	// calculations are not based on invoices
	|SELECT
	|	CalculationsByTerms.DocumentRecorder AS Recorder,
	|	SUM(CalculationsByTerms.PrepaymentLocal + CalculationsByTerms.DebtLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.PrepaymentMan + CalculationsByTerms.ARAPMan) AS SumMan
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			ON CalculationsByTerms.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND &ARAPObject = CalculationsByTerms.ARAPObject
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.ARAPObject.ARAPObjectType IN (
	|		VALUE(Enum.ARAPObjectTypes.Contract),
	|		VALUE(Enum.ARAPObjectTypes.OrderDocument))
	|	AND CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder
	|;");
	
	QueryTexts.Add(TextDocumentsThatAreNotAvailableForRecording());
	
	Return StrConcat(QueryTexts);
	
EndFunction

&AtServer
Function RequestTextAdvancesForSettlementsWithSuppliers(Query)
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueryText = "
		|SELECT
		|	VendorsARAPAccounting.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	VendorsARAPAccounting.PurchaseOrder.Partner           AS Partner,
		|	VendorsARAPAccounting.PurchaseOrder.Organization       AS Organization,
		|	VendorsARAPAccounting.PurchaseOrder.Counterparty        AS Counterparty,
		|	VendorsARAPAccounting.PurchaseOrder.Contract           AS Contract,
		|	VendorsARAPAccounting.PurchaseOrder.LineOfBusiness AS LineOfBusiness,
		|	VendorsARAPAccounting.PurchaseOrder                   AS ARAPObject,
		|	VendorsARAPAccounting.Currency                            AS Currency,
		|	VendorsARAPAccounting.PrepaymentBalance                 AS AdvanceAmount,
		|	VendorsARAPAccounting.PrepaymentLocalBalance             AS SumCompl,
		|	VendorsARAPAccounting.PrepaymentManBalance              AS SumMan,
		|	VendorsARAPAccounting.PurchaseOrder.Date              AS Date
		|
		|INTO TableOfDocumentBalances
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
		|			FROM
		|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
		|			WHERE
		|				TTAccountingAnalyticsForPartners.Organization IN (&Organization)
		|			)
		|		AND PurchaseOrder <> &ARAPObject
		|	) AS VendorsARAPAccounting
		|	
		|WHERE
		|	VendorsARAPAccounting.PrepaymentBalance > 0
		|	AND (VALUETYPE(VendorsARAPAccounting.PurchaseOrder.Object) <> TYPE(Document.VendorInvoice)
		|		OR &ItIsManagementOrganization)
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	PurchaseOrder,
		|	Currency
		|;";
	Else
		
		QueryText = "
		|SELECT
		|	VendorsARAPAccounting.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	VendorsARAPAccounting.AccountingDimensionByPartners.Partner AS Partner,
		|	VendorsARAPAccounting.ARAPObject.Organization        AS Organization,
		|	VendorsARAPAccounting.ARAPObject.Counterparty         AS Counterparty,
		|	VendorsARAPAccounting.ARAPObject.Contract            AS Contract,
		|	VendorsARAPAccounting.ARAPObject.LineOfBusiness AS LineOfBusiness,
		|	VendorsARAPAccounting.ARAPObject                    AS ARAPObject,
		|	VendorsARAPAccounting.ARAPObject.Object             AS Object,
		|	VendorsARAPAccounting.Currency                            AS Currency,
		|	VendorsARAPAccounting.PrepaymentBalance                 AS AdvanceAmount,
		|	VendorsARAPAccounting.PrepaymentLocalBalance             AS SumCompl,
		|	VendorsARAPAccounting.PrepaymentManBalance              AS SumMan,
		|	VendorsARAPAccounting.ARAPObject.Date               AS Date
		|
		|INTO TableOfDocumentBalances
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
		|			FROM
		|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
		|			WHERE
		|				TTAccountingAnalyticsForPartners.Organization IN (&Organization)
		|			)
		|		AND (ARAPObject <> &ARAPObject
		|			OR AccountingDimensionByPartners.Partner <> &DocumentPartner)
		|	) AS VendorsARAPAccounting
		|	
		|WHERE
		|	VendorsARAPAccounting.PrepaymentBalance > 0
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;";
	EndIf;
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDocumentBalances.ARAPObject                    AS ARAPObject,
	|	TableOfDocumentBalances.Currency                            AS ARAPCurrency,
	|	TableOfDocumentBalances.Organization                       AS Organization,
	|	TableOfDocumentBalances.Partner                           AS Partner,
	|	TableOfDocumentBalances.Counterparty                        AS Counterparty,
	|	TableOfDocumentBalances.Contract                           AS Contract,
	|	SUM(TableOfDocumentBalances.AdvanceAmount)                AS AvailableToSetOff,
	|	SUM(TableOfDocumentBalances.SumCompl)                  AS SumCompl,
	|	SUM(TableOfDocumentBalances.SumMan)                   AS SumMan,
	|	CASE
	|		WHEN TableOfDocumentBalances.Contract = &Contract THEN
	|			1
	|		ELSE
	|			2
	|	END                                                         AS Order,
	|	TableOfDocumentBalances.Date                              AS Date
	|FROM
	|	TableOfDocumentBalances AS TableOfDocumentBalances
	|		LEFT JOIN TTAvailableUnallocatedPayments AS UnallocatedPayments
	|			ON UnallocatedPayments.ARAPObject = TableOfDocumentBalances.ARAPObject
	|WHERE
	|	UnallocatedPayments.ARAPObject IS NULL
	|
	|GROUP BY
	|	TableOfDocumentBalances.ARAPObject,
	|	TableOfDocumentBalances.Currency,
	|	TableOfDocumentBalances.Organization,
	|	TableOfDocumentBalances.Partner,
	|	TableOfDocumentBalances.Counterparty,
	|	TableOfDocumentBalances.Contract,
	|	TableOfDocumentBalances.Date
	|
	|ORDER BY
	|	Organization,
	|	Order,
	|	Date,
	|	ARAPObject,
	|	Partner
	|";
	Return QueryText;
	
EndFunction
	
#EndRegion

#Region CustomersARAPAccounting

&AtServer
Function RequestTextForSettlementsWithClients()
	
	QueryTexts = New Array;
	
	QueryTexts.Add("
	// Credited (credited payments and advances)
	|SELECT
	|	CustomersARAPAccounting.Currency                                            AS ARAPCurrency,
	|	CASE 
	|		WHEN NOT IsPatch.Ref IS NULL
	|			THEN IsPatch.CorrectedDocument
	|		WHEN CustomersARAPAccounting.CorARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|			AND NOT CustomersARAPAccounting.Recorder REFS Document.ARAPSettlement
	|			THEN ARAPObjects.Object
	|		ELSE CustomersARAPAccounting.Recorder
	|	END                                                               AS Document,
	|	CASE WHEN CustomersARAPAccounting.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|		THEN CustomersARAPAccounting.CorPartnerAccountingDimension.Organization
	|		ELSE ARAPObjects.Organization
	|	END                                                               AS Organization,
	|	ARAPObjects.Counterparty                                          AS Counterparty,
	|	ARAPObjects.Partner                                             AS Partner,
	|	CASE 
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|			AND NOT CustomersARAPAccounting.Recorder REFS Document.ARAPSettlement
	|			THEN CustomersARAPAccounting.CorARAPObject.Date
	|		ELSE ARAPObjects.Date
	|	END                                                               AS Date,
	|	ARAPObjects.Sum                                               AS DocumentAmount,
	|	ARAPObjects.Currency                                              AS Currency,
	|	CustomersARAPAccounting.CorARAPObject                                 AS ARAPObject,
	|	ISNULL(CustomersARAPAccounting.CorARAPObject.Object, UNDEFINED)  AS Object,
	|	ARAPObjects.Contract                                             AS Contract,
	|
	|	CASE 
	|		WHEN CustomersARAPAccounting.Sum < 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.Sum > 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|			THEN -CustomersARAPAccounting.Sum
	|		ELSE 0
	|	END                                                        AS AmountCredited_2,
	|	CASE
	|		WHEN CustomersARAPAccounting.Sum < 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.Sum > 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|			THEN -CustomersARAPAccounting.Sum
	|		ELSE 0
	|	END * 
	|	CASE WHEN ARAPObjects.Sum <> 0 AND ARAPObjects.AmountARAP <> 0
	|			THEN ARAPObjects.AmountARAP/ARAPObjects.Sum
	|		ELSE 1
	|	END                                                            AS AmountInPaymentCurrency,
	|	ISNULL(DistributedCalculations.SumCompl, 0)                     AS SumCompl,
	|	ISNULL(DistributedCalculations.SumMan, 0)                      AS SumMan,
	|	
	|	NOT CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|		AND ThisIsDocumentThatIsBeingCorrected.Ref IS NULL
	|		AND NOT CustomersARAPAccounting.Recorder REFS Document.ARAPAdjustment
	|		AND NOT CustomersARAPAccounting.Recorder REFS Document.OBEntry
	|		AND NOT CustomersARAPAccounting.Recorder REFS Document.OBEntryARAP
	|		AND NOT CustomersARAPAccounting.Recorder REFS Document.ReversingEntry
	|		AND NOT VALUETYPE(CustomersARAPAccounting.Recorder) = &TypeOfOperationYandexCheckout
	|		AND NOT (CustomersARAPAccounting.Recorder REFS Document.ReturnOfGoodsFromCustomer AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|		AND NOT (CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense) AND CustomersARAPAccounting.Sum < 0 AND CustomersARAPAccounting.Recorder REFS Document.ARAPSettlement) 
	|		AND NOT (CustomersARAPAccounting.Recorder REFS Document.ARAPSettlement AND CAST(CustomersARAPAccounting.Recorder AS Document.ARAPSettlement).Currency = VALUE(Catalog.Currencies.EmptyRef)) AS EditingAvailable,
	|	CustomersARAPAccounting.Recorder = &Document                        AS DecryptionOfThePaymentObject,
	|	1                                                                AS Order
	|INTO SetOff
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON CustomersARAPAccounting.ARAPObject = ARAPObjects.Ref
	|				AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = ARAPObjects.Organization
	|		LEFT JOIN DistributedCalculations AS DistributedCalculations
	|			ON CASE 
	|				WHEN CustomersARAPAccounting.CorARAPObject <> UNDEFINED
	|					AND NOT CustomersARAPAccounting.Recorder REFS Document.ARAPSettlement
	|					THEN CustomersARAPAccounting.CorARAPObject.Object
	|				ELSE CustomersARAPAccounting.Recorder
	|			END = DistributedCalculations.Recorder
	|		INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			ON CustomersARAPAccounting.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS IsPatch
	|			ON IsPatch.Ref = CustomersARAPAccounting.Recorder
	|				AND IsPatch.ReverseTransactionCorrection
	|				AND NOT IsPatch.Ref REFS Document.ReversingEntry
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS ThisIsDocumentThatIsBeingCorrected
	|			ON ThisIsDocumentThatIsBeingCorrected.ReversedDocument = CustomersARAPAccounting.Recorder
	|				AND ThisIsDocumentThatIsBeingCorrected.Posted
	|WHERE
	|	CustomersARAPAccounting.ARAPObject = &ARAPObject
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND CASE 
	|		WHEN CustomersARAPAccounting.Sum < 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN CustomersARAPAccounting.Sum
	|		WHEN CustomersARAPAccounting.Sum > 0 AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|			THEN -CustomersARAPAccounting.Sum
	|		ELSE 0
	|	END <> 0 
	|	AND CustomersARAPAccounting.Active
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction)
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
	|	AND NOT (CustomersARAPAccounting.Recorder REFS Document.PurchasingReportToConsignorPrincipal
	|			AND CustomersARAPAccounting.Recorder = &Document 
	|			AND CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment))
	|	AND NOT CustomersARAPAccounting.Recorder REFS Document.ARAPAccountingScheduleAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPDetails.Currency                                        AS ARAPCurrency,
	|	ARAPDetails.ARAPObject.Object                         AS Document,
	|	ARAPDetails.Organization                                   AS Organization,
	|	ARAPDetails.Counterparty                                    AS Counterparty,
	|	ARAPDetails.ARAPObject.Partner                        AS Partner,
	|	ARAPDetails.ARAPObject.Date                           AS Date,
	|	ARAPDetails.ARAPObject.Sum                          AS DocumentAmount,
	|	ARAPDetails.ARAPObject.Currency                         AS Currency,
	|	ARAPDetails.ARAPObject                                AS ARAPObject,
	|	ARAPDetails.ARAPObject.Object                         AS Object,
	|	ARAPDetails.Contract                                       AS Contract,
	|
	|	ARAPDetails.AmountARAP                           AS AmountCredited_2,
	|	ARAPDetails.Sum                                         AS AmountInPaymentCurrency,
	|	0                                                                AS SumCompl,
	|	0                                                                AS SumMan,
	|
	|	TRUE                                                           AS EditingAvailable,
	|	TRUE                                                           AS DecryptionOfThePaymentObject,
	|	1                                                                AS Order
	|FROM
	|	TableDecryptionOfPaymentInvoice AS ARAPDetails
	|WHERE
	|	ARAPDetails.ARAPObject <> &ARAPObject
	|	AND ARAPDetails.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND &Document <> ARAPDetails.ARAPObject.OBJECT
	|;
	|SELECT
	|	SettlementOfARAP.Ref AS Ref,
	|	MAX(SettlementOfARAP.ARAPObject) AS ARAPObject,
	|	MAX(SettlementOfARAP.ARAPObject.Object) AS Object,
	|	NULL AS SumCompl,
	|	NULL AS SumMan
	|	
	|INTO TTDebtOffsets
	|FROM Document.ARAPSettlement.AccountsPayable AS SettlementOfARAP
	|WHERE NOT &NewOnlineARAPAccounting
	|	AND SettlementOfARAP.Ref IN (SELECT T.Document FROM SetOff AS T)
	|GROUP BY
	|	SettlementOfARAP.Ref
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CalculationsByTerms.DocumentRecorder AS Ref,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	CalculationsByTerms.ARAPObject.Object AS Object,
	|	SUM(CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan) AS SumMan
	|	
	|
	|FROM AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE &NewOnlineARAPAccounting
	|	AND CalculationsByTerms.DocumentRecorder IN (SELECT T.Document FROM SetOff AS T)
	|	AND CalculationsByTerms.CalculationObjectReceiver = &ARAPObject
	|	AND CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder,
	|	CalculationsByTerms.ARAPObject
	|	
	|INDEX BY
	|	Ref,
	|	ARAPObject
	|;
	// Availability of tasks for advances
	|SELECT
	|	TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
	|FROM
	|	TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOff.ARAPCurrency         AS ARAPCurrency,
	|	SetOff.Document                     AS Document,
	|	SetOff.Organization                  AS Organization,
	|	SetOff.Counterparty                   AS Counterparty,
	|	SetOff.Partner                      AS Partner,
	|	SetOff.Date                         AS Date,
	|	SetOff.DocumentAmount               AS DocumentAmount,
	|	SetOff.Currency                       AS Currency,
	|	SetOff.Contract                      AS Contract,
	|
	|	SUM(SetOff.AmountCredited_2)          AS AmountCredited_2,
	|	SUM(SetOff.AmountInPaymentCurrency)   AS AmountInPaymentCurrency,
	|	MAX(ISNULL(SettlementOfARAP.SumCompl,SetOff.SumCompl)) AS SumCompl,
	|	MAX(ISNULL(SettlementOfARAP.SumMan,SetOff.SumMan))   AS SumMan,
	|
	|	MIN(SetOff.EditingAvailable)       AS EditingAvailable,
	|	SetOff.DecryptionOfThePaymentObject   AS DecryptionOfThePaymentObject,
	|	SetOff.Order                      AS Order,
	|	MAX(ISNULL(SettlementOfARAP.ARAPObject,SetOff.ARAPObject)) AS ARAPObject,
	|	MAX(ISNULL(SettlementOfARAP.ARAPObject.Object,SetOff.Object)) AS Object
	|FROM
	|	SetOff AS SetOff
	|		LEFT JOIN TTDebtOffsets AS SettlementOfARAP
	|			ON SettlementOfARAP.Ref = SetOff.Document
	|			AND (SettlementOfARAP.ARAPObject = SetOff.ARAPObject
	|				OR NOT &NewOnlineARAPAccounting)
	|GROUP BY
	|	SetOff.ARAPCurrency,
	|	SetOff.Document,
	|	SetOff.ARAPObject,
	|	SetOff.Organization,
	|	SetOff.Counterparty,
	|	SetOff.Partner,
	|	SetOff.Date,
	|	SetOff.DocumentAmount,
	|	SetOff.Currency,
	|	SetOff.Contract,
	|	SetOff.DecryptionOfThePaymentObject,
	|	SetOff.Order
	|HAVING
	|	SUM(SetOff.AmountCredited_2) <> 0
	|ORDER BY
	|	Organization,
	|	Date
	|;");
	
	QueryTexts.Add(TextUnallocatedPayments());
	
	Return StrConcat(QueryTexts);
		
EndFunction

&AtServer
Function TemporaryTablesForSettlementsWithClients()
	
	QueryTexts = New Array;
	
	QueryTexts.Add("
	|SELECT
	|	CustomersARAPAccounting.ARAPObject                             AS ARAPObject,
	|	CustomersARAPAccounting.Currency                                     AS ARAPCurrency,
	|	ARAPObjects.Object                                       AS Document,
	|	CustomersARAPAccounting.AccountingDimensionByPartners                  AS DimensionKey,
	|	ARAPObjects.Organization                                  AS Organization,
	|	ARAPObjects.Partner                                      AS Partner,
	|	ARAPObjects.Counterparty                                   AS Counterparty,
	|	ARAPObjects.Date                                         AS Date,
	|	ARAPObjects.Sum                                        AS DocumentAmount,
	|	ARAPObjects.Currency                                       AS Currency,
	|	-CustomersARAPAccounting.SumBalance - ISNULL(Details.Sum,0) AS AvailableToSetOff,
	|	CASE WHEN ARAPObjects.Sum <> 0 AND ARAPObjects.AmountARAP <> 0
	|		THEN -(CustomersARAPAccounting.SumBalance - ISNULL(Details.Sum,0)) * ARAPObjects.AmountARAP/ARAPObjects.Sum
	|		ELSE -CustomersARAPAccounting.SumBalance - ISNULL(Details.Sum,0)
	|	END                                                        AS AmountInPaymentCurrency,
	|	TRUE                                                       AS EditingAvailable,
	|	&ARAPObjectInvoice
	|		AND (&OffsetFromTermsOfAgreement 
	|				AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|					OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|			OR (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|					AND BEGINOFPERIOD(ARAPObjects.Date,DAY) < &DocumentDate)
	|			OR (&ItIsManagementOrganization
	|					AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice))
	|				)                                                 AS DecryptionOfThePaymentObject
	|INTO TTUnallocatedPayments
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|		AccountingDimensionByPartners IN (
	|			SELECT
	|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
	|			FROM
	|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|			)
	|	) AS CustomersARAPAccounting
	|	
	|	INNER JOIN
	|		Catalog.ARAPObjects AS ARAPObjects
	|	ON
	|		ARAPObjects.Ref = CustomersARAPAccounting.ARAPObject
	|	LEFT JOIN TableDecryptionOfPaymentInvoice AS Details
	|		ON Details.ARAPObject = CustomersARAPAccounting.ARAPObject
	|	
	|	INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|	
	|WHERE
	// Exclude primary documents with a date greater than the invoice date or an empty Contract
	|	NOT (ARAPObjects.Object REFS Document.SourceDocument 
	|			AND (ARAPObjects.Date >= &DocumentDate AND &ARAPObjectInvoice 
	|				OR ARAPObjects.Contract IN (VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|												,VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|					AND ARAPObjects.Organization <> VALUE(Catalog.Companies.ManagementCompany)))
	// Payments of any period with the same Contract
	|	AND (ARAPObjects.Contract = &Contract
	// Payments with an empty Contract, but later than the document date
	|		OR NOT (ARAPObjects.Date < &DocumentDate AND &ARAPObjectInvoice)
	|			AND ARAPObjects.Contract IN (VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|												,VALUE(Catalog.IntercompanyContracts.EmptyRef))
	// Invoices are Local only. before the document date
	|		OR (&ItIsManagementOrganization
	|			AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)))
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND ARAPObjects.LineOfBusiness = &LineOfBusiness
	|	AND ARAPObjects.ARAPCurrency = &ARAPCurrency
	|	AND CustomersARAPAccounting.SumBalance < 0
	|	AND (&ARAPObjectInvoice
	|			AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|				OR ARAPObjects.Object IN (&ListOfObjects)
	|						AND (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|							OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract))
	|				OR &ItIsManagementOrganization
	|						AND BEGINOFPERIOD(ARAPObjects.Date,DAY) <= &DocumentDate
	|					)
	|		OR NOT &ARAPObjectInvoice
	|			AND &DocumentDate < BEGINOFPERIOD(ARAPObjects.Date,DAY)
	|			AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.PaymentReturn))
	|	AND NOT (ARAPObjects.Object REFS Catalog.GiftCertificates)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Credited to upr and regl
	|SELECT
	|	CalculationsAccordingToDocuments.Recorder AS Recorder,
	|	SUM(CalculationsAccordingToDocuments.PrepaymentLocal + CalculationsAccordingToDocuments.DebtLocal) AS SumCompl,
	|	SUM(CalculationsAccordingToDocuments.PrepaymentMan + CalculationsAccordingToDocuments.ARAPMan) AS SumMan
	|INTO DistributedCalculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|	AND CalculationsAccordingToDocuments.AccountingDimensionByPartners IN (SELECT DimensionKey FROM TTAccountingAnalyticsForPartners)
	|	AND &ARAPObject = CalculationsAccordingToDocuments.SalesOrder
	|	AND CalculationsAccordingToDocuments.Active
	|GROUP BY
	|	CalculationsAccordingToDocuments.Recorder
	|	
	|UNION ALL
	|	
	// invoice calculations
	|SELECT
	|	CalculationsByTerms.ARAPDocument AS Recorder,
	|	SUM(CalculationsByTerms.PrepaymentLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.PrepaymentMan) AS SumMan
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|	INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|		ON CalculationsByTerms.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND &ARAPObject = CalculationsByTerms.ARAPObject
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.Prepayment <> 0 
	|	AND CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CalculationsByTerms.ARAPObject.ARAPObjectType IN (
	|		VALUE(Enum.ARAPObjectTypes.Invoice),
	|		VALUE(Enum.ARAPObjectTypes.PaymentReturn))
	|	AND NOT CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.ARAPDocument 
	|	
	|	UNION ALL
	|	
	// calculations are not based on invoices
	|SELECT
	|	CalculationsByTerms.DocumentRecorder AS Recorder,
	|	SUM(CalculationsByTerms.PrepaymentLocal + CalculationsByTerms.DebtLocal) AS SumCompl,
	|	SUM(CalculationsByTerms.PrepaymentMan + CalculationsByTerms.ARAPMan) AS SumMan
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|	INNER JOIN TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
	|		ON CalculationsByTerms.AccountingDimensionByPartners = TTAccountingAnalyticsForPartners.DimensionKey
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND TTAccountingAnalyticsForPartners.ThisIsPartnerOfDocument
	|	AND &ARAPObject = CalculationsByTerms.ARAPObject
	|	AND CalculationsByTerms.Active
	|	AND CalculationsByTerms.ARAPObject.ARAPObjectType IN (
	|		VALUE(Enum.ARAPObjectTypes.Contract),
	|		VALUE(Enum.ARAPObjectTypes.OrderDocument))
	|	AND CalculationsByTerms.DocumentRecorder REFS Document.ARAPSettlement
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder
	|;");
	
	QueryTexts.Add(TextDocumentsThatAreNotAvailableForRecording());
	
	Return StrConcat(QueryTexts);
		
EndFunction

&AtServer
Function RequestTextAdvancesForSettlementsWithCustomers(Query)
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueryText = "
		|SELECT
		|	CustomersARAPAccounting.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	CustomersARAPAccounting.SalesOrder.Partner              AS Partner,
		|	CustomersARAPAccounting.SalesOrder.Organization          AS Organization,
		|	CustomersARAPAccounting.SalesOrder.Counterparty           AS Counterparty,
		|	CustomersARAPAccounting.SalesOrder.Contract              AS Contract,
		|	CustomersARAPAccounting.SalesOrder.LineOfBusiness AS LineOfBusiness,
		|	CustomersARAPAccounting.SalesOrder                      AS ARAPObject,
		|	CustomersARAPAccounting.Currency                            AS Currency,
		|	CustomersARAPAccounting.PrepaymentBalance                 AS AdvanceAmount,
		|	CustomersARAPAccounting.PrepaymentLocalBalance             AS SumCompl,
		|	CustomersARAPAccounting.PrepaymentManBalance              AS SumMan,
		|	CustomersARAPAccounting.SalesOrder.Date                 AS Date
		|
		|INTO TableOfDocumentBalances
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
		|			FROM
		|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
		|			WHERE
		|				TTAccountingAnalyticsForPartners.Organization IN (&Organization)
		|			)
		|		AND SalesOrder <> &ARAPObject
		|	) AS CustomersARAPAccounting
		|	
		|WHERE
		|	CustomersARAPAccounting.PrepaymentBalance < 0
		|	AND (VALUETYPE(CustomersARAPAccounting.SalesOrder.Object) <> TYPE(Document.CustomerInvoice)
		|		OR &ItIsManagementOrganization)
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
	Else
		
		QueryText = "
		|SELECT
		|	CustomersARAPAccounting.AccountingDimensionByPartners          AS AccountingDimensionByPartners,
		|	CustomersARAPAccounting.AccountingDimensionByPartners.Partner  AS Partner,
		|	CustomersARAPAccounting.ARAPObject.Organization         AS Organization,
		|	CustomersARAPAccounting.ARAPObject.Counterparty          AS Counterparty,
		|	CustomersARAPAccounting.ARAPObject.Contract             AS Contract,
		|	CustomersARAPAccounting.ARAPObject.LineOfBusiness AS LineOfBusiness,
		|	CustomersARAPAccounting.ARAPObject                     AS ARAPObject,
		|	CustomersARAPAccounting.ARAPObject.Object              AS Object,
		|	CustomersARAPAccounting.Currency                             AS Currency,
		|	-CustomersARAPAccounting.PrepaymentBalance                 AS AdvanceAmount,
		|	-CustomersARAPAccounting.PrepaymentLocalBalance             AS SumCompl,
		|	-CustomersARAPAccounting.PrepaymentManBalance              AS SumMan,
		|	CustomersARAPAccounting.ARAPObject.Date                AS Date
		|
		|INTO TableOfDocumentBalances
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				TTAccountingAnalyticsForPartners.DimensionKey AS DimensionKey
		|			FROM
		|				TTAccountingAnalyticsForPartners AS TTAccountingAnalyticsForPartners
		|			WHERE
		|				TTAccountingAnalyticsForPartners.Organization IN (&Organization)
		|			)
		|		AND (ARAPObject <> &ARAPObject
		|			OR AccountingDimensionByPartners.Partner <> &DocumentPartner)
		|	) AS CustomersARAPAccounting
		|	
		|WHERE
		|	CustomersARAPAccounting.PrepaymentBalance > 0
		|	AND CustomersARAPAccounting.ARAPObject.Object <> UNDEFINED
		|	AND NOT CustomersARAPAccounting.ARAPObject.Object REFS Catalog.GiftCertificates
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;";
	EndIf;
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDocumentBalances.ARAPObject                      AS ARAPObject,
	|	TableOfDocumentBalances.Currency                            AS ARAPCurrency,
	|	TableOfDocumentBalances.Organization                       AS Organization,
	|	TableOfDocumentBalances.Partner                           AS Partner,
	|	TableOfDocumentBalances.Counterparty                        AS Counterparty,
	|	TableOfDocumentBalances.Contract                           AS Contract,
	|	SUM(-TableOfDocumentBalances.AdvanceAmount)               AS AvailableToSetOff,
	|	SUM(-TableOfDocumentBalances.SumCompl)                 AS SumCompl,
	|	SUM(-TableOfDocumentBalances.SumMan)                  AS SumMan,
	|	TableOfDocumentBalances.Date                              AS Date,
	|	CASE
	|		WHEN TableOfDocumentBalances.Contract = &Contract THEN
	|			1
	|		ELSE
	|			2
	|	END                                                         AS Order
	|FROM
	|	TableOfDocumentBalances AS TableOfDocumentBalances
	|		LEFT JOIN TTAvailableUnallocatedPayments AS UnallocatedPayments
	|			ON UnallocatedPayments.ARAPObject = TableOfDocumentBalances.ARAPObject
	|WHERE
	|	UnallocatedPayments.ARAPObject IS NULL
	|
	|GROUP BY
	|	TableOfDocumentBalances.ARAPObject,
	|	TableOfDocumentBalances.Currency,
	|	TableOfDocumentBalances.Organization,
	|	TableOfDocumentBalances.Partner,
	|	TableOfDocumentBalances.Counterparty,
	|	TableOfDocumentBalances.Contract,
	|	TableOfDocumentBalances.Date
	|	
	|ORDER BY
	|	Organization,
	|	Order,
	|	Date,
	|	ARAPObject,
	|	Partner
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

&AtServer
Function DocumentDataVersion(DocumentRef)
	
	If DocumentRef = Undefined Then
		Return "            ";
	EndIf;
	
	DocumentName = Metadata.FindByType(TypeOf(DocumentRef)).Name;
	
	QueryText = "
	|SELECT
	|	DocumentData.DataVersion AS DataVersion
	|FROM
	|	&DocumentName AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Query = New Query;
	Query.Text = StrReplace(QueryText, "&DocumentName", "Document." + DocumentName);
	If Not Common.IsDocument(DocumentRef.Metadata()) Then
		Query.Text = StrReplace(Query.Text, "Document", "Catalog");
	EndIf;
	Query.SetParameter("Ref", DocumentRef);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		DataVersion = Selection.DataVersion;
	Else
		DataVersion = "            ";
	EndIf;
	
	Return DataVersion;
	
EndFunction

&AtServer
Function StateOfSettlementBackgroundTask()
	Filter = New Structure();
	Filter.Insert("Key", Key);
	
	Jobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If Jobs.Count() > 0 Then
		If Jobs[0].State = BackgroundJobState.Active Then
			Return "Active";
		ElsIf Jobs[0].State = BackgroundJobState.Failed Then
			Return "Error";
		Else
			Return "Completed";
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Procedure BackgroundJobCheckOnClient()
	
	State = StateOfSettlementBackgroundTask();
	
	If State = Undefined Or State = "Completed" Then
		
		AdvancesAreCalculated = Not ThereAreTasksForDistributionOfSettlements(ThereAreCustomersARAP, DimensionKeys) Or NewOnlineARAPAccounting;
		
		If Not AdvancesAreCalculated Then
			
			Key = New UUID();
			StructureOfCalculations = New Structure("AccountingAnalyticsForPartners, Companies",DimensionKeys.UnloadValues(), Undefined);
			
			If ThereAreCustomersARAP Then
				ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(,StructureOfCalculations,"CustomersARAPAccounting",Key);
			Else
				ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(,StructureOfCalculations,"VendorsARAPAccounting",Key);
			EndIf;
			AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
		Else
			Key = Undefined;
			FillInAdvanceTable();
		EndIf;
		
	ElsIf State = "Active" Then
		AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
	Else
		MessageText = NStr("vi = 'Đã xảy ra lỗi trong quá trình phân bổ các khu đối trừ trên các chứng từ. Xem nhật ký để biết chi tiết.';
							|ru = 'Во время распределения расчетов по документам произошла ошибка. Подробности см. в Журнале регистрации.';
							|en = 'An error occurred while allocating settlements by the documents. For more information, see the Event log.'; fa = 'An error occurred while allocating settlements by the documents. For more information, see the Event log.';
							|it = 'Durante la ripartizione dei calcoli nei documenti si è verificato un errore. Vedere il registro per i dettagli.';
							|pl = 'Podczas podziału rozliczeń według dokumentów wystąpił błąd. Szczegóły zob. w Dzienniku rejestracji.';
							|tr = 'Ödemelerin belgeler arasında dağıtılırken hata oluştu. Ayrıntılar için Kayıt Defterine bak.'");
		CommonClientServer.MessageToUser(MessageText);
		
		AdvancesAreCalculated = True;
		Prepayments.Clear();
		InstallAdvancesPage();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConductingCredits

&AtClient
Procedure OffsetPaymentForSelectedLines(RowsArray)
	
	ClearMessages();
	
	CallbackDescription = New CallbackDescription(
		"GetConfirmationOfPaymentOffset",
		ThisForm,
		RowsArray);
	
	If Lacks <= 0 Then
		
		Mode = New ValueList;
		Text = NStr("vi = 'Tiếp tục';
					|ru = 'Продолжить';
					|en = 'Continue'; fa = 'ادامه';
					|it = 'Continuare';
					|pl = 'Kontynuuj';
					|tr = 'Devam'");
		Mode.Add(DialogReturnCode.Yes, Text);
		Mode.Add(DialogReturnCode.Cancel);
		
		If ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
			And ARAPObjectType = PredefinedValue("Enum.ARAPObjectTypes.OrderDocument") Then
			QueryText = NStr("vi = 'Đã khấu trừ đầy đủ số tiền ứng trước.';
							|ru = 'Сумма аванса полностью зачтена.';
							|en = 'Advance amount is fully offset.'; fa = 'Advance amount is fully offset.';
							|it = 'L''importo dell''acconto è stato imputato per intero.';
							|pl = 'Kwota zaliczki została w całości zaliczona.';
							|tr = 'Ön ödemenin tamamı ödenmiştir.'");
		Else
			QueryText = NStr("vi = 'Đã khấu trừ đầy đủ số tiền cần thanh toán.';
							|ru = 'Сумма к оплате полностью зачтена.';
							|en = 'Amount due is fully set off.'; fa = 'Amount due is fully set off.';
							|it = 'Importo da pagare è completamente imputato.';
							|pl = 'Wartość do płatności została w całości zaksięgowana.';
							|tr = 'Ödenecek borcun tamamı ödenmiştir.'");
		EndIf;
		
		ShowQueryBox(CallbackDescription, QueryText, Mode);
		
		Return;
		
	EndIf;
	
	RunCallback(CallbackDescription, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure GetConfirmationOfPaymentOffset(Result, RowsArray) Export
	
	If Result = DialogReturnCode.Yes Then
		ReadOnServer(RowsArray, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffAdvanceForSelectedLines(RowsArray)
	
	ClearMessages();
	
	CallbackDescription = New CallbackDescription(
		"GetConfirmationOfAdvancePaymentOffset",
		ThisForm,
		RowsArray);
	
	If Lacks <= 0 Then
		
		Mode = New ValueList;
		Text = NStr("vi = 'Tiếp tục';
					|ru = 'Продолжить';
					|en = 'Continue'; fa = 'ادامه';
					|it = 'Continuare';
					|pl = 'Kontynuuj';
					|tr = 'Devam'");
		Mode.Add(DialogReturnCode.Yes, Text);
		Mode.Add(DialogReturnCode.Cancel);
		
		If ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
			And ARAPObjectType = PredefinedValue("Enum.ARAPObjectTypes.OrderDocument") Then
			QueryText = NStr("vi = 'Đã khấu trừ đầy đủ số tiền ứng trước.';
							|ru = 'Сумма аванса полностью зачтена.';
							|en = 'Advance amount is fully offset.'; fa = 'Advance amount is fully offset.';
							|it = 'L''importo dell''acconto è stato imputato per intero.';
							|pl = 'Kwota zaliczki została w całości zaliczona.';
							|tr = 'Ön ödemenin tamamı ödenmiştir.'");
		Else
			QueryText = NStr("vi = 'Đã khấu trừ đầy đủ số tiền cần thanh toán.';
							|ru = 'Сумма к оплате полностью зачтена.';
							|en = 'Amount due is fully set off.'; fa = 'Amount due is fully set off.';
							|it = 'Importo da pagare è completamente imputato.';
							|pl = 'Wartość do płatności została w całości zaksięgowana.';
							|tr = 'Ödenecek borcun tamamı ödenmiştir.'");
		EndIf;
		
		ShowQueryBox(CallbackDescription, QueryText, Mode);
		Return;
		
	EndIf;
	
	RunCallback(CallbackDescription, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure GetConfirmationOfAdvancePaymentOffset(Result, RowsArray) Export
	
	If Result = DialogReturnCode.Yes Then
		ReadOnServer(RowsArray, False);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadOnServer(RowsArray, ThisIsPayment)
	
	If ThisIsPayment And Not BlockDocumentsForEditing(RowsArray, "Payments") Then
		Return;
	EndIf;
	
	FormTable = ThisForm[?(ThisIsPayment, "Payments", "Prepayments")];
	
	AllocateBalance = (Lacks > 0);
	
	StringsList = New ValueList;
	StringListCalculationObjects = New Array;
	For Each LineNumber In RowsArray Do
		TableRow = FormTable.FindByID(LineNumber);
		If TableRow <> Undefined Then
			StringsList.Add(TableRow, FormTable.IndexOf(TableRow));
			If StringListCalculationObjects.Find(TableRow.ARAPObject) = Undefined Then
				StringListCalculationObjects.Add(TableRow.ARAPObject);
			EndIf;
		EndIf;
	EndDo;
	
	StringsList.SortByPresentation();
	
	TheStructureOfTheSearch = New Structure("Object, Partner");
	If Not ThisIsPayment Then
		TheStructureOfTheSearch.Insert("ARAPObject");
	EndIf;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.ARAPSettlementsWizard.Form.Form.ReadOnServer");
	
	ObjectAttributeValues = Common.ObjectsAttributeValue(StringListCalculationObjects, "Object");
	
	NumberOfProcessedData = 0;
	For Each String In StringsList Do
		
		TableRow = String.Value;
		If ThisIsPayment And Not TableRow.EditingAvailable Then
			Continue;
		EndIf;
		
		NumberOfProcessedData = NumberOfProcessedData + 1;
		
		AmountToCredit         = TableRow.AvailableToSetOff;
		AmountInPaymentCurrency  = TableRow.AmountInPaymentCurrency;
		
		CalculationObject = ObjectAttributeValues[TableRow.ARAPObject];
		ObjectOfCalculationsIsGiftCertificate = TypeOf(CalculationObject) = Type("CatalogRef.GiftCertificates");
		
		If AllocateBalance And Not ObjectOfCalculationsIsGiftCertificate Then
			
			SumOfBasis  = TableRow.AvailableToSetOff;
			AmountToCredit = ARAPAccountingServer.DeductAmount(TableRow.AvailableToSetOff, Lacks);
			
			AmountInPaymentCurrency = ARAPAccountingServer.WriteOffAmountProportionally(
				TableRow.AmountInPaymentCurrency,
				AmountToCredit,
				SumOfBasis);
			If Not ThisIsPayment Then
				SumCompl= ARAPAccountingServer.WriteOffAmountProportionally(
					TableRow.SumCompl,
					AmountToCredit,
					SumOfBasis);
				SumMan = ARAPAccountingServer.WriteOffAmountProportionally(
					TableRow.SumMan,
					AmountToCredit,
					SumOfBasis);
			Else
				If Not ThisIsPayment Then
					SumCompl = 0;
					SumMan = 0;
				EndIf;
			EndIf;
			
		Else
			TableRow.AvailableToSetOff = 0;
			If Not ThisIsPayment Then
				SumCompl = TableRow.SumCompl;
				SumMan = TableRow.SumMan;
			EndIf;
		EndIf;
		
		If AmountToCredit = 0 Then
			Break;
		EndIf;
		
		If Not ThisIsPayment Then
			TheStructureOfTheSearch = New Structure("ARAPObject, Document", TableRow.ARAPObject, TableRow.Document);
		ElsIf TableRow.DecryptionOfThePaymentObject Then
			TheStructureOfTheSearch = New Structure("ARAPObject", TableRow.ARAPObject);
		Else
			TheStructureOfTheSearch = New Structure("Document", TableRow.Document);
		EndIf;
		CountedLines = SetOff.FindRows(TheStructureOfTheSearch);
		
		If CountedLines.Count() = 0 Then
			CreditLine = SetOff.Add();
			If Not ThisIsPayment Then
				FillPropertyValues(CreditLine, TableRow, , "AmountInPaymentCurrency, SumMan, SumCompl");
				CreditLine.Date = CurrentSessionDate();
			ElsIf TableRow.DecryptionOfThePaymentObject Then
				FillPropertyValues(CreditLine, TableRow, , "AmountInPaymentCurrency, Document");
				CreditLine.Document = Document;
			Else
				FillPropertyValues(CreditLine, TableRow, , "AmountInPaymentCurrency");
			EndIf;
			CreditLine.EditingAvailable = True;
		Else
			CreditLine = CountedLines[0];
		EndIf;
		
		CreditLine.AmountCredited_2        = CreditLine.AmountCredited_2 + AmountToCredit;
		CreditLine.AmountInPaymentCurrency = CreditLine.AmountInPaymentCurrency + AmountInPaymentCurrency;
		If Not ThisIsPayment Then
			CreditLine.SumCompl = CreditLine.SumCompl + SumCompl;
			CreditLine.SumMan = CreditLine.SumMan + SumMan;
		EndIf;
		
		CreditLine.DataChanged1 = True;
		
		If ObjectOfCalculationsIsGiftCertificate Then
			UnlockDataForEdit(CreditLine.Document, UUID);
			CreditLine.DataVersion = DocumentDataVersion(CreditLine.Document);
			CreditLine.Object = CalculationObject;
			CreditLine.DataChanged1 = False;
		EndIf;
		
		If TableRow.AvailableToSetOff = 0 Then
			FormTable.Delete(TableRow);
		Else
			TableRow.DataChanged1 = False;
		EndIf;
		
		Modified = True;
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);	
	
	SetOff.Sort("Organization, Date");
	
	CalculateAmountOfCredit();
	CalculateNumberOfRows_();
	
EndProcedure

&AtServer
Procedure CancelCreditOnServer(RowsMap, RowAmountChanged = True, Cancel = False)
	
	RowsArray = New Array;
	For Each StringItem In RowsMap Do
		RowsArray.Add(StringItem.Key);
	EndDo;
	
	If Not BlockDocumentsForEditing(RowsArray, "SetOff") Then
		Cancel = True;
		Return;
	EndIf;
	
	For Each StringItem In RowsMap Do
		
		TableRow = SetOff.FindByID(StringItem.Key);
		
		If TableRow = Undefined Or 
			(Not TableRow.EditingAvailable 
				And TypeOf(TableRow.Object) <> Type("CatalogRef.GiftCertificates")
				And TypeOf(TableRow.Document) <> Type("DocumentRef.ARAPSettlement")) Then
				
			Continue;
		EndIf;
		
		AmountToCancel = StringItem.Value;
		SumOfBasis  = TableRow.AmountCredited_2 + ?(RowAmountChanged, AmountToCancel, 0);
		
		If AmountToCancel = 0 Then
			AmountToCancel = TableRow.AmountCredited_2;
			TableRow.AmountCredited_2 = 0;
		ElsIf Not RowAmountChanged Then
			TableRow.AmountCredited_2 = TableRow.AmountCredited_2 - AmountToCancel;
		EndIf;
		
		ThisIsCancellationOfAdvancePaymentWithSelectedGiftCertificate = (Not ValueIsFilled(TableRow.Document) 
														And TypeOf(TableRow.Object) = Type("CatalogRef.GiftCertificates"));		
		
		If Not ThisIsCancellationOfAdvancePaymentWithSelectedGiftCertificate Then
			ThisIsCancellationOfUnusedAdvance = Not ValueIsFilled(TableRow.Document) 
				Or TypeOf(TableRow.Document) = Type("DocumentRef.ARAPSettlement");
			
			If ThisIsCancellationOfUnusedAdvance Or TableRow.DecryptionOfThePaymentObject Then
				TheStructureOfTheSearch = New Structure("Document, Partner, ARAPObject");
			Else
				TheStructureOfTheSearch = New Structure("Document, Partner");
			EndIf;
			
			If ThisIsCancellationOfUnusedAdvance Then
				SearchTable = Prepayments;
				LocalCancellationFee = ARAPAccountingServer.WriteOffAmountProportionally(
					TableRow.SumCompl,
					AmountToCancel,
					SumOfBasis);
				AmountToCancelMan = ARAPAccountingServer.WriteOffAmountProportionally(
					TableRow.SumMan,
					AmountToCancel,
					SumOfBasis);
			Else
				SearchTable = Payments;
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
			FoundRows = SearchTable.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() = 0 Then
				PaymentLine_ = SearchTable.Add();
				FillPropertyValues(PaymentLine_, TableRow, , "AmountInPaymentCurrency");
				If ThisIsCancellationOfUnusedAdvance Then
					PaymentLine_.SumCompl = LocalCancellationFee;
					PaymentLine_.SumMan = AmountToCancelMan;
				EndIf;
				If TableRow.DecryptionOfThePaymentObject Then
					PaymentLine_.Document = TableRow.Object;
				EndIf;
			Else
				PaymentLine_ = FoundRows[0];
				If ThisIsCancellationOfUnusedAdvance Then
					PaymentLine_.SumCompl = PaymentLine_.SumCompl + LocalCancellationFee;
					PaymentLine_.SumMan = PaymentLine_.SumMan + AmountToCancelMan;
				EndIf;
			EndIf;
			
			If TableRow.AmountInPaymentCurrency > 0 Then
				AmountToCancelInPaymentCurrency = ARAPAccountingServer.WriteOffAmountProportionally(
					TableRow.AmountInPaymentCurrency,
					AmountToCancel,
					SumOfBasis);
			Else 
				AmountToCancelInPaymentCurrency = PaymentLine_.AmountInPaymentCurrency / SumOfBasis * AmountToCancel;
			EndIf;
			
			PaymentLine_.AmountInPaymentCurrency = PaymentLine_.AmountInPaymentCurrency + AmountToCancelInPaymentCurrency;
			
			PaymentLine_.AvailableToSetOff = PaymentLine_.AvailableToSetOff + AmountToCancel;
			
			If Not ThisIsCancellationOfUnusedAdvance
				And PaymentLine_.DecryptionOfThePaymentObject <> TableRow.DecryptionOfThePaymentObject Then
				PaymentLine_.DecryptionOfThePaymentObject = TableRow.DecryptionOfThePaymentObject;
			EndIf;
			
		EndIf;
		
		PaymentLine_.UnsavedData = True;
		
		If TableRow.AmountCredited_2 = 0 Then
			SetOff.Delete(TableRow);
			PaymentLine_.DataChanged1 = True;
		Else
			TableRow.DataChanged1 = True;
			PaymentLine_.DataChanged1 = False;
			If ThisIsCancellationOfUnusedAdvance Then
				PaymentLine_.Document = Undefined;
			EndIf;
		EndIf;
		
		Modified = True;
		
	EndDo;
	
	Payments.Sort("Organization, Date");
	Prepayments.Sort("Organization, Order");
	
	CalculateAmountOfCredit();
	CalculateNumberOfRows_();
	
EndProcedure

&AtServer
Procedure FixServerOvershoot(Cancel)
	
	AmountForAllocation = Excess;
	
	MatchingDebits = New Map;
	
	TableSize = SetOff.Count();
	
	For Cnt = 1 To TableSize Do
		
		TableRow = SetOff[TableSize - Cnt];
		
		If Not TableRow.EditingAvailable Then
			Continue;
		EndIf;
		
		If TableRow.AmountCredited_2 < 0 Then
			Continue;
		EndIf;
		
		AmountToCancel = Min(TableRow.AmountCredited_2, AmountForAllocation);
		AmountForAllocation = AmountForAllocation - AmountToCancel;
		
		MatchingDebits.Insert(TableRow.GetID(), AmountToCancel);
		
		If AmountForAllocation = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	CancelCreditOnServer(MatchingDebits, False, Cancel);
	
EndProcedure

&AtServer
Function BlockDocumentsForEditing(RowsArray, TableName)
	
	Cancel = False;
	
	SetPrivilegedMode(True);
	
	FormTable = ThisForm[TableName];
	
	For Each RowID In RowsArray Do
		
		TableRow = FormTable.FindByID(RowID);
		RowIndex = FormTable.IndexOf(TableRow);
		
		If TableRow = Undefined
			Or TableRow.DataChanged1 Or Not ValueIsFilled(TableRow.Document) Then
			Continue;
		EndIf;
		
		If TableRow.DataVersion <> DocumentDataVersion(TableRow.Document) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể phong tỏa %1. Dữ liệu đã bị thay đổi hoặc xóa bỏ bởi người sử dụng khác.';
					|ru = 'Не удалось заблокировать %1. Данные были изменены или удалены другим пользователем.';
					|en = 'Cannot lock %1. Data was changed or removed by another user.'; fa = 'Cannot lock %1. Data was changed or removed by another user.';
					|it = 'Non è stato possibile bloccare %1. I dati sono stati modificati o cancellati da un altro utente.';
					|pl = 'Nie udało się zablokować %1. Dane zostały zmienione lub usunięte przez innego użytkownika.';
					|tr = '%1 kilitlenemedi. Veriler başka bir kullanıcı tarafından değiştirildi veya silindi.'"),
				TableRow.Document);
			Common.MessageToUser(
				ErrorText,
				, // DataKey
				TableName + "[" + (RowIndex) + "].Document");
			Cancel = True;
			Continue;
			
		EndIf;
		
		If ARAPObjectType = Enums.ARAPObjectTypes.Invoice
			And TableRow.Date < DocumentDate
			Or ListOfObjects.Count() > 0 Then
			DataChangesDenied = PeriodClosingDates.DataChangesDenied(
				Common.TableNameByRef(Document),
				Document, False);
			DocumentMessages=Document;
		Else
			DataChangesDenied = PeriodClosingDates.DataChangesDenied(
				Common.TableNameByRef(TableRow.Document),
				TableRow.Document, False);
			DocumentMessages = TableRow.Document
		EndIf;
		
		If DataChangesDenied Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay đổi %1. Chứng từ đang trong kỳ bị cấm thay đổi.';
					|ru = 'Не удалось изменить %1. Документ находится в запрещенном для изменения периоде.';
					|en = 'Cannot change %1. Document is in the change prohibition period.'; fa = 'Cannot change %1. Document is in the change prohibition period.';
					|it = 'Non è stato possibile modificare %1 Il documento è nel periodo contabile non modificabile.';
					|pl = 'Nie udało się zmienić %1. Dokument znajduje się w zabronionym dla zmiany okresie.';
					|tr = '%1 değiştirilemedi. Belge, düzenlenmesi yasak olan dönemdedir.'"),
				DocumentMessages);
			Common.MessageToUser(
				ErrorText,
				, // DataKey
				TableName + "[" + (RowIndex) + "].Document");
			Cancel = True;
			Continue;
			
		EndIf;
		
		If DocumentMessages <> Document Then
			Try
				LockDataForEdit(
						DocumentMessages,
						,// DataVersion
						UUID);
			Except
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể phong tỏa %1%2';
						|ru = 'Не удалось заблокировать %1. %2';
						|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
						|it = 'Impossibile bloccare %1. %2';
						|pl = 'Nie udało się zablokować %1. %2';
						|tr = '%1 engellenemedi. %2'"),
					TableRow.Document,
					BriefErrorDescription(ErrorInfo()));
				Common.MessageToUser(
					ErrorText,
					, // DataKey
					TableName + "[" + (RowIndex) + "].Document");
				Cancel = True;
			EndTry;
		EndIf;
		
	EndDo;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#Region RecordingChanges

&AtClient
Procedure SavePaymentOffsetResultAndClose()
	
	Var ArrayOfProcessedDocuments;
	
	ClearMessages();
	
	Cancel = False;
	
	WriteChangesAtServer(ArrayOfProcessedDocuments, Cancel);
	
	If ThereAreSettlementsBetweenCompanies And ArrayOfProcessedDocuments.Count() > 0
		And Not MatchMirrorPayments(ArrayOfProcessedDocuments) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ArrayOfProcessedDocuments", ArrayOfProcessedDocuments);
		AdditionalParameters.Insert("Document", Document);
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiến hành khấu trừ';
													|ru = 'Провести зачет';
													|en = 'Set off'; fa = 'تهاتر';
													|it = 'Registrare l''imputazione';
													|pl = 'Zatwierdzić zaksięgowanie';
													|tr = 'Mahsup etmeyi kaydet'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Từ chối';
													|ru = 'Отказаться';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'Reddet'"));
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã thay đổi khấu trừ thanh toán cho bên %1. 
			|Có cần khấu trừ thanh toán tương tự cho bên %2?';
			|ru = 'Изменен зачет оплат на стороне %1. 
			|Провести зачет аналогичных платежей на стороне %2?';
			|en = 'Payment offset on the %1 side is changed.
			|Offset similar payments on the %2 side?'; fa = 'Payment offset on the %1 side is changed.
			|Offset similar payments on the %2 side?';
			|it = 'Изменен зачет оплат на стороне %1. 
			|Провести зачет аналогичных платежей на стороне %2?';
			|pl = 'Payment offset on the %1 side is changed.
			|Offset similar payments on the %2 side?';
			|tr = '%1 tarafındaki ödeme mahsupları değiştirildi.
			|Benzer ödemeler %2 tarafında mahsup edilsin mi?'"), Organization ,Partner);

		ShowQueryBox(New CallbackDescription("PerformMirrorDocumentChanges", ThisObject, AdditionalParameters), 
				QueryText, ButtonsList);
	EndIf;
	
	NotifyAboutResultOfPaymentOffset(ArrayOfProcessedDocuments);
	
	Notify("PaymentCredited", Document);
	
	If Not Cancel Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteChangesAtServer(ArrayOfProcessedDocuments, Cancel)
	
	ArrayOfProcessedDocuments = New Array;
	
	SetPrivilegedMode(True);
	
	ArrayOfTables = New Array;
	ArrayOfTables.Add("Prepayments");
	ArrayOfTables.Add("Payments");
	ArrayOfTables.Add("SetOff");
	
	For Each TableName In ArrayOfTables Do
		
		FormTable = ThisForm[TableName]; // FormDataCollection -
		ArrayForCreditingToInvoice = New Array;
		
		For Each TableRow In FormTable Do
		
			If Not TableRow.DataChanged1 Then
				Continue;
			EndIf;
			
			BeginTransaction();
			Try
			
			RowIndex = FormTable.IndexOf(TableRow);
			ErrorField = TableName + "[" + (RowIndex) + "].Document";
			
			DocumentData = New Structure("Organization, Partner, Currency");
			
			DataBalanced       = New Structure;
			DataBalanced.Insert("Partner");
			DataBalanced.Insert("ARAPObject");
			DataBalanced.Insert("ARAPCurrency");
			DataBalanced.Insert("Organization");
			DataBalanced.Insert("Object");
			DataBalanced.Insert("Document");
			
			Amounts           = New Structure;
			Amounts.Insert("AmountCredited_2");
			Amounts.Insert("AmountInPaymentCurrency");
			Amounts.Insert("SumCompl");
			Amounts.Insert("SumMan");
			
			FillPropertyValues(DocumentData, TableRow);
			FillPropertyValues(DataBalanced, TableRow);
			FillPropertyValues(Amounts, TableRow);
			
			ErrorText = "";
			
			If TableName = "Payments" 
				And Not ValueIsFilled(TableRow.ARAPObject) And Not TableRow.DecryptionOfThePaymentObject Then
				
				Amounts.AmountCredited_2 = 0;
				
				ReflectPaymentOffsetInDocument(
					TableRow.Document,
					DocumentData,
					Amounts,
					ErrorField,
					ErrorText);
				
			ElsIf TableName = "Prepayments" Then
				
				If ValueIsFilled(TableRow.Document) Then
					
					Amounts.AmountCredited_2 = 0;
					
					ErrorField = TableName + "[" + (RowIndex) + "].ARAPObject";
					ReflectOffsetOfAdvanceInDocument(
						TableRow.Document,
						DataBalanced,
						Amounts,
						ErrorField,
						ErrorText);
					
				EndIf;
				
			ElsIf Not ValueIsFilled(TableRow.Document) Then
				
				CreateDebtOffset(DataBalanced, Amounts, ErrorField, ErrorText);
				TableRow.Document = DataBalanced.Document;
				
			ElsIf TypeOf(TableRow.Document) = Type("DocumentRef.ARAPSettlement") Then
				
				If TypeOf(TableRow.Object) = Type("CatalogRef.GiftCertificates") Then
					DataBalanced.Insert("Partner", PredefinedValue("Catalog.Partners.RetailCustomer"));
				EndIf;
				
				ReflectOffsetOfAdvanceInDocument(
					TableRow.Document,
					DataBalanced,
					Amounts,
					ErrorField,
					ErrorText);
				
			Else
					
				If TableName = "Payments" Then
					Amounts.AmountCredited_2 = 0;
				EndIf;
				
				If ARAPObjectType = Enums.ARAPObjectTypes.Invoice
					And ValueIsFilled(TableRow.ARAPObject)
					And TableRow.DecryptionOfThePaymentObject Then
					
					DataForCreditingToInvoice = New Structure("DocumentData, Amounts, ARAPObject",
					                                            DocumentData,
					                                            Amounts,
					                                            TableRow.ARAPObject);
					ArrayForCreditingToInvoice.Add(DataForCreditingToInvoice);
				Else
					ReflectPaymentOffsetInDocument(
						TableRow.Document,
						DocumentData,
						Amounts,
						ErrorField,
						ErrorText);
				EndIf;
				
			EndIf;
			
			ArrayOfProcessedDocuments.Add(TableRow.Document);
			
			CommitTransaction();
			Except
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText,,ErrorField,,Cancel);
				RollbackTransaction();
				Raise ErrorText;
			EndTry;
			
		EndDo;
		
		If ArrayForCreditingToInvoice.Count() > 0 Then
			
			BeginTransaction();
			Try
			
			DocumentObject = Document.GetObject();
			ErrorText = "";
			For Each DataForCreditingToInvoice In ArrayForCreditingToInvoice Do
				ReflectPaymentOffsetInDocument(Document,
					DataForCreditingToInvoice.DocumentData,
					DataForCreditingToInvoice.Amounts,
					"",
					ErrorText,
					DataForCreditingToInvoice.ARAPObject,
					DocumentObject);
			EndDo;
			If DocumentObject.CheckFilling() Then
				DocumentObject.AdditionalProperties.Insert("PaymentSettlement",True);
				DocumentObject.Write(DocumentWriteMode.Posting);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể ghi lại chứng từ %1';
						|ru = 'Не удалось записать документ %1';
						|en = 'Cannot save document %1'; fa = 'Cannot save document %1';
						|it = 'Non è stato possibile registrare il documento %1';
						|pl = 'Nie udało się zapisać dokument %1';
						|tr = '%1 belgesi kaydedilemedi.'"),
					Document);
				Raise(ErrorText);
			EndIf;
			CommitTransaction();
			Except
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText,,,,Cancel);
				RollbackTransaction();
				Raise ErrorText;
			EndTry;
		EndIf;
		
	EndDo;
	
	If ErrorText = "" Then
		For Each Page1 In SetOff Do
			Page1.DataChanged1 = False;
		EndDo;
		For Each Page1 In Payments Do
			Page1.DataChanged1 = False;
			Page1.UnsavedData = False;
		EndDo;
		For Each Page1 In Prepayments Do
			Page1.DataChanged1 = False;
			Page1.UnsavedData = False;
		EndDo;
	EndIf;
	
	If Not NewOnlineARAPAccounting And ErrorText = "" Then
		// Let's restore the sequence of calculations with the partner.
		Query = New Query("
		|SELECT
		|	DimensionByPartners.DimensionKey AS DimensionKey
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
		|WHERE
		|	DimensionByPartners.Organization IN (&Organization)
		|	AND DimensionByPartners.Partner IN (&Partner)
		|	AND DimensionByPartners.Counterparty = &Counterparty
		|");
		Query.SetParameter("Organization", AvailableCompanies);
		Query.SetParameter("Partner",     AvailablePartners);
		Query.SetParameter("Counterparty",  Counterparty);
		
		AnalystTable = Query.Execute().Unload();
		ArrayOfAccountingAnalystsForPartners = AnalystTable.UnloadColumn("DimensionKey");
		
		If ThereAreCustomersARAP And ArrayOfAccountingAnalystsForPartners.Count() > 0 Then
			CalculationEnd = EndOfMonth(CurrentSessionDate())+1;
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAccountingAnalystsForPartners;
			ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CalculationEnd, CalculationAnalysts);
		EndIf;
		If ThereAreVendorsARAP  And ArrayOfAccountingAnalystsForPartners.Count() > 0 Then
			CalculationEnd = EndOfMonth(CurrentSessionDate())+1;
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAccountingAnalystsForPartners;
			ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CalculationEnd, CalculationAnalysts);
		EndIf;
	EndIf;
	
	UnlockDocumentsForEditing();
	Modified = False;
	
EndProcedure

&AtServer
Procedure ReflectPaymentOffsetInDocument(DocumentRef, DocumentData, SumStructure, ErrorField, ErrorText, ObjectOfOffsettingCalculations = Undefined, DocumentObject = Undefined)
	
	// The object of calculations that we read into the document
	If ObjectOfOffsettingCalculations = Undefined Then
		ObjectOfOffsettingCalculations = ARAPObject;
		OffsetInInvoice = False;
	Else
		OffsetInInvoice = True;
	EndIf;
	
	// The invoice will be received and recorded outside the procedure, only filling is required
	If DocumentObject = Undefined Then 
		DocumentObject = DocumentRef.GetObject();
	EndIf;
	
	ThisIsAdvanceReport = (TypeOf(DocumentRef) = Type("DocumentRef.ExpenseReport"));
	ThisIsInputOfResiduals = (TypeOf(DocumentRef) = Type("DocumentRef.OBEntry"));
	ThisIsInputOfBalancesOfMutualSettlements = (TypeOf(DocumentRef) = Type("DocumentRef.OBEntryARAP"));
	If ThisIsAdvanceReport Then
		TabularSectionName = "PaymentToVendors";
	ElsIf ThisIsInputOfBalancesOfMutualSettlements Then
		TabularSectionName = "PartnersARAPAccounting";
	ElsIf ThisIsInputOfResiduals Then
		If ThereAreSettlementsBetweenCompanies Then
			TabularSectionName = "IntercompanyARAP";
		Else
			TabularSectionName = "PartnersARAPAccounting";
		EndIf;
	ElsIf OffsetInInvoice Then
		TabularSectionName = NameTchrashifrovkaPayment;
	Else
		TabularSectionName = "ARAPDetails";
	EndIf;
	
	PaymentDecryptionTable = DocumentObject[TabularSectionName].Unload(); // ValueTable
	Columns = PaymentDecryptionTable.Columns;
	
	If PaymentDecryptionTable.Count() = 0 And ARAPObjectType = Enums.ARAPObjectTypes.Invoice Then
		ThereIsSumOfMutualSettlements = Common.HasObjectAttribute("AmountARAP", DocumentObject.Metadata());
		
		If DocumentObject.Posted Then
			AmountOfSettlementsToDecrypt = ?(ThereIsSumOfMutualSettlements, DocumentObject.AmountARAP, DocumentObject.DocumentAmount);
		Else
			AmountOfSettlementsToDecrypt = AmountARAP; 
		EndIf;
		
		ARAPAccountingServer.FillInAmountOfInvoiceDecryption(DocumentObject.DocumentAmount, 
			AmountOfSettlementsToDecrypt,
			PaymentDecryptionTable,
			ARAPObject);
	EndIf;
	
	If Columns.Find("AmountARAP") = Undefined Then
		Columns.Add("AmountARAP", New TypeDescription("Number"));
	EndIf;
	If Columns.Find("ARAPObject") = Undefined Then
		Columns.Add("ARAPObject");
	EndIf;
	
	If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
		
		ArrayOfCalculationObjects_ = PaymentDecryptionTable.UnloadColumn("ARAPObject");
		PaymentDecryptionTable.LoadColumn(ArrayOfCalculationObjects_, "ARAPObject");
		
		ArrayOfAmounts = PaymentDecryptionTable.UnloadColumn("Sum");
		PaymentDecryptionTable.LoadColumn(ArrayOfAmounts, "AmountARAP");
		
	EndIf;
	
	ThereIsPartnerColumn = False;
	ThereIsSupplierColumn = False;
	
	StructureFilter = New Structure;
	If Columns.Find("Partner") <> Undefined And (Partner <> Catalogs.Partners.OurEnterprise) Then
		StructureFilter.Insert("Partner", DocumentData.Partner);
		ThereIsPartnerColumn = True;
	EndIf;
	If Columns.Find("Vendor") <> Undefined Then
		StructureFilter.Insert("Vendor", DocumentData.Partner);
		ThereIsSupplierColumn = True;
	EndIf;
	If Columns.Find("Counterparty") <> Undefined And TypeOf(Counterparty) <> Type("CatalogRef.Companies") Then
		StructureFilter.Insert("Counterparty", Counterparty);
	EndIf;
	If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
		StructureFilter.Insert("ARAPCurrency", DocumentData.Currency);
	EndIf;
	
	ThereIsPaymentBasis = (Columns.Find("PaymentPurpose") <> Undefined);
	
	If StructureFilter.Count() = 0 Then
		RowsArray = New Array;
		For Each DecryptionString In PaymentDecryptionTable Do
			RowsArray.Add(DecryptionString);
		EndDo;
	Else
		RowsArray = PaymentDecryptionTable.FindRows(StructureFilter);
	EndIf;
	
	DataChanged1 = False;
	
	RecalculateVATAmount_ = (PaymentDecryptionTable.Columns.Find("VATAmount") <> Undefined);
	
	For Each DocumentLine In RowsArray Do
		
		If SumStructure.AmountCredited_2 = 0 Then
		
			If DocumentLine.ARAPObject = ObjectOfOffsettingCalculations Then
				
				DocumentLine.ARAPObject = Undefined;
				If ThereIsPaymentBasis Then
					DocumentLine.PaymentPurpose = Undefined;
				EndIf;
				If RecalculateVATAmount_ Then
					DocumentLine.VATRate = Undefined;
					DocumentLine.VATAmount = 0;
				EndIf;
				DataChanged1 = True;
				
			EndIf;
			
		ElsIf DocumentLine.ARAPObject = ObjectOfOffsettingCalculations
			Or DocumentLine.ARAPObject = Contract
			Or Not ValueIsFilled(DocumentLine.ARAPObject) 
			// Decryption of the invoice
			Or DocumentLine.ARAPObject = ARAPObject And OffsetInInvoice
			Or Common.ObjectAttributeValue(DocumentLine.ARAPObject, "Object") = DocumentRef Then
			
			SumOfDocumentLine = DocumentLine.Sum;
			WrittenOff = ARAPAccountingServer.WriteOffAmountProportionally(DocumentLine.Sum, SumStructure.AmountCredited_2, DocumentLine.AmountARAP);
			
			If OffsetInInvoice
				Or ARAPCurrency = DocumentLine.ARAPCurrency Then
				
				DebitedInSettlementCurrency = ARAPAccountingServer.DeductAmount(
					DocumentLine.AmountARAP,
					SumStructure.AmountCredited_2);
				
			Else
				
				ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.AmountARAP,
					WrittenOff,
					SumOfDocumentLine);
					
				DebitedInSettlementCurrency = SumStructure.AmountCredited_2;
			EndIf;
			
			DataChanged1 = True;
			
			If RecalculateVATAmount_ Then
				VATDeducted = ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.VATAmount,
					WrittenOff,
					SumOfDocumentLine);
			EndIf;
			
			If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
				AmountDebitedLocal = ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.SumCompl,
					WrittenOff,
					SumOfDocumentLine);
				AmountDebitedMan = ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.SumMan,
					WrittenOff,
					SumOfDocumentLine);
			EndIf;
			
			If SumOfDocumentLine <= WrittenOff Then
				PaymentLine_ = DocumentLine;
			Else
				PaymentLine_ = PaymentDecryptionTable.Add();
				FillPropertyValues(PaymentLine_, DocumentLine);
				If DocumentLine.ARAPObject = ObjectOfOffsettingCalculations Then
					DocumentLine.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
					If ThereIsPaymentBasis Then
						DocumentLine.PaymentPurpose = Undefined;
					EndIf;
				EndIf;
				DataChanged1 = True;
			EndIf;
			
			PaymentLine_.Sum = WrittenOff;
			PaymentLine_.AmountARAP = DebitedInSettlementCurrency;
			
			If RecalculateVATAmount_ Then
				PaymentLine_.VATAmount = VATDeducted;
			EndIf;
			
			If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
				PaymentLine_.SumCompl = AmountDebitedLocal;
				PaymentLine_.SumMan = AmountDebitedMan;
			EndIf;
			
			If Not OffsetInInvoice
				And PaymentLine_.ARAPCurrency <> ARAPCurrency Then
				PaymentLine_.ARAPCurrency = ARAPCurrency;
				DataChanged1 = True;
			EndIf;
			
			If PaymentLine_.ARAPObject <> ObjectOfOffsettingCalculations Then
				PaymentLine_.ARAPObject = ObjectOfOffsettingCalculations;
				DataChanged1 = True;
			EndIf;
			
			If DocumentData.Partner <> Partner Then
				If ThereIsPartnerColumn Then
					PaymentLine_.Partner = Partner;
					DataChanged1 = True;
				EndIf;
				If ThereIsSupplierColumn Then
					PaymentLine_.Vendor = Partner;
					DataChanged1 = True;
				EndIf;
			EndIf;
			
			If ThereIsPaymentBasis And Not ValueIsFilled(PaymentLine_.PaymentPurpose) Then
				PaymentLine_.PaymentPurpose = PaymentLine_.ARAPObject;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If DataChanged1 Then
		
		ColumnsNames = "";
		ArrayOfExcludedColumns = New Array;
		ArrayOfExcludedColumns.Add("LineNumber");
		ArrayOfExcludedColumns.Add("RowID");
		ArrayOfExcludedColumns.Add("Sum");
		ArrayOfExcludedColumns.Add("AmountARAP");
		ArrayOfExcludedColumns.Add("SumCompl");
		For Each Column In Columns Do
			If ArrayOfExcludedColumns.Find(Column.Name) = Undefined Then
				ColumnsNames = ColumnsNames + Column.Name + ",";
			EndIf;
		EndDo;
		ColumnsNames = Left(ColumnsNames, StrLen(ColumnsNames) - 1);
		NamesOfSummationColumns = "Sum, AmountARAP";
		If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
			NamesOfSummationColumns = NamesOfSummationColumns + ", SumCompl";
		EndIf;
		
		PaymentDecryptionTable.GroupBy(ColumnsNames, NamesOfSummationColumns);
		PaymentDecryptionTable.Sort("ARAPObject");
		
		If ThisIsInputOfResiduals Or ThisIsInputOfBalancesOfMutualSettlements Then
			
			ArrayOfCalculationObjects_ = PaymentDecryptionTable.UnloadColumn("ARAPObject");
			PaymentDecryptionTable.LoadColumn(ArrayOfCalculationObjects_, "ARAPObject");
			
			ArrayOfAmounts = PaymentDecryptionTable.UnloadColumn("AmountARAP");
			PaymentDecryptionTable.LoadColumn(ArrayOfAmounts, "Sum");
			
			AttributesValues = Common.ObjectAttributesValues(ObjectOfOffsettingCalculations, "Date, Number");
			
			For Each TableRow In PaymentDecryptionTable Do
				
				If ValueIsFilled(TableRow.ARAPObject)
				 And Not ValueIsFilled(TableRow.NumberOfARAPDocument) Then
					TableRow.NumberOfARAPDocument = AttributesValues.Number;
				EndIf;
				
				If ValueIsFilled(TableRow.ARAPObject)
				 And Not ValueIsFilled(TableRow.APARDocumentDate) Then
					TableRow.APARDocumentDate = AttributesValues.Date;
				EndIf;
				
				If Not ValueIsFilled(TableRow.ARAPObject) Then
					TableRow.NumberOfARAPDocument = "";
					TableRow.APARDocumentDate = Date(1,1,1);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		DocumentObject[TabularSectionName].Load(PaymentDecryptionTable); 
		If Not OffsetInInvoice Then
			If DocumentObject.CheckFilling() Then
				DocumentObject.AdditionalProperties.Insert("PaymentSettlement",True);
				DocumentObject.Write(DocumentWriteMode.Posting);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể ghi lại chứng từ %1';
						|ru = 'Не удалось записать документ %1';
						|en = 'Cannot save document %1'; fa = 'Cannot save document %1';
						|it = 'Non è stato possibile registrare il documento %1';
						|pl = 'Nie udało się zapisać dokument %1';
						|tr = '%1 belgesi kaydedilemedi.'"),
					DocumentRef);
				Raise(ErrorText);
			EndIf;
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure ReflectOffsetOfAdvanceInDocument(OffsetDocument, DataBalanced, SumStructure, ErrorField, ErrorText)
	
	DocumentObject = OffsetDocument.GetObject();
	
	CorStructureOfSums = CommonClientServer.CopyStructure(SumStructure);
	
	SelectionOfCredit = New Structure;
	SelectionOfCredit.Insert("PaymentType_", 
		?(ThereAreCustomersARAP, 
		Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,
		Enums.PartnersARAPAccountingTypes.VendorARAPAccounting));
	SelectionOfCredit.Insert("Partner", Partner);
	SelectionOfCredit.Insert("ARAPObject", ARAPObject);
	
	AdvancePaymentSelection = New Structure;
	AdvancePaymentSelection.Insert("PaymentType_", SelectionOfCredit.PaymentType_);
	AdvancePaymentSelection.Insert("Partner", DataBalanced.Partner);
	AdvancePaymentSelection.Insert("ARAPObject", DataBalanced.ARAPObject);
	
	AccountsReceivable = DocumentObject.AccountsReceivable.Unload();
	
	RowsArray = AccountsReceivable.FindRows(?(ThereAreCustomersARAP, SelectionOfCredit, AdvancePaymentSelection));
	WrittenOff = 0;
	SettlementAmount_1 = 0;
	For Each DocumentLine In RowsArray Do
		
		If SumStructure.AmountCredited_2 = 0 Then
			AccountsReceivable.Delete(DocumentLine);
		Else
			
			If SumStructure.AmountCredited_2 < DocumentLine.AmountARAP Then
				
				WrittenOff = WrittenOff + (DocumentLine.AmountARAP - SumStructure.AmountCredited_2);
				DocumentLine.AmountARAP = DocumentLine.AmountARAP - WrittenOff;
				
				SettlementAmount_1 = SettlementAmount_1 + DocumentLine.AmountARAP ;
				DocumentLine.SumCompl           = SumStructure.SumCompl;
				DocumentLine.SumMan            = SumStructure.SumMan;
				
			EndIf;
			
			If ThereAreCustomersARAP Then
				DocumentLine.ARAPCurrency = ARAPCurrency;
			EndIf;
			
			SumStructure.AmountCredited_2        = SumStructure.AmountCredited_2 - DocumentLine.AmountARAP;
			SumStructure.SumCompl           = SumStructure.SumCompl - DocumentLine.SumCompl;
			SumStructure.SumMan            = SumStructure.SumMan - DocumentLine.SumMan;
		EndIf;
		
	EndDo;
	
	AccountsPayable = DocumentObject.AccountsPayable.Unload();
	
	RowsArray = AccountsPayable.FindRows(?(ThereAreCustomersARAP, AdvancePaymentSelection, SelectionOfCredit));
	
	For Each DocumentLine In RowsArray Do
		
		If CorStructureOfSums.AmountCredited_2 = 0 Then
			AccountsPayable.Delete(DocumentLine);
		Else
			
			SumCompl = CorStructureOfSums.SumCompl;
			
			If CorStructureOfSums.SumCompl < DocumentLine.SumCompl Then
				
				ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.AmountARAP,
					DocumentLine.SumCompl - SumCompl,
					DocumentLine.SumCompl);
				
				DocumentLine.SumCompl = CorStructureOfSums.SumCompl;
				DocumentLine.SumMan = CorStructureOfSums.SumMan;
				
			Else
				ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.AmountARAP,
					WrittenOff,
					SettlementAmount_1);
				
				ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.SumCompl,
					WrittenOff,
					SettlementAmount_1);
				
				ARAPAccountingServer.WriteOffAmountProportionally(
					DocumentLine.SumMan,
					WrittenOff,
					SettlementAmount_1);
				
			EndIf;
			
			CorStructureOfSums.SumCompl = CorStructureOfSums.SumCompl - DocumentLine.SumCompl;
			CorStructureOfSums.SumMan = CorStructureOfSums.SumMan - DocumentLine.SumMan;
			
			ARAPAccountingServer.WriteOffAmountProportionally(
				CorStructureOfSums.AmountCredited_2,
				SumCompl - CorStructureOfSums.SumCompl,
				SumCompl);
		EndIf;
	EndDo;
	
	DocumentObject.AccountsReceivable.Load(AccountsReceivable);
	DocumentObject.AccountsPayable.Load(AccountsPayable);
	
	DocumentObject.SumCompl = AccountsReceivable.Total("SumCompl");
	DocumentObject.SumMan  = AccountsReceivable.Total("SumMan");
	
	If AccountsPayable.Count() = 0
		Or AccountsReceivable.Count() = 0 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại chứng từ %1.';
				|ru = 'Не удалось записать документ %1.';
				|en = 'Cannot save document %1.'; fa = 'Cannot save document %1.';
				|it = 'Non è stato possibile registrare il documento %1.';
				|pl = 'Nie udało się zapisać dokument %1.';
				|tr = '%1 belgesi kaydedilemedi.'"),
			OffsetDocument);
		DocumentObject.Write(DocumentWriteMode.UndoPosting);
		DocumentObject.SetDeletionMark(True);
		ErrorText = "";
		
	ElsIf DocumentObject.CheckFilling() Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại chứng từ %1.';
				|ru = 'Не удалось записать документ %1.';
				|en = 'Cannot save document %1.'; fa = 'Cannot save document %1.';
				|it = 'Non è stato possibile registrare il documento %1.';
				|pl = 'Nie udało się zapisać dokument %1.';
				|tr = '%1 belgesi kaydedilemedi.'"),
			OffsetDocument);
		DocumentObject.Write(DocumentWriteMode.Posting);
		ErrorText = "";
		
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại chứng từ %1';
				|ru = 'Не удалось записать документ %1';
				|en = 'Cannot save document %1'; fa = 'Cannot save document %1';
				|it = 'Non è stato possibile registrare il documento %1';
				|pl = 'Nie udało się zapisać dokument %1';
				|tr = '%1 belgesi kaydedilemedi.'"),
			OffsetDocument);
		Raise(ErrorText);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDebtOffset(DataBalanced, SumStructure, ErrorField, ErrorText)
	
	Sum = SumStructure.AmountCredited_2;
	
	DocumentObject = Documents.ARAPSettlement.CreateDocument();
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
	TypesArray.Add(Type("CatalogRef.IntercompanyContracts"));
	TypesArray.Add(Type("DocumentRef.PurchaseOrder"));
	TypesArray.Add(Type("DocumentRef.SalesOrder"));
	
	TypesArray.Add(Type("DocumentRef.SubcontractOrder2_5"));
	TypesArray.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	DocumentObject.Date = CurrentSessionDate();
	DocumentObject.DocumentBasis = Document;
	
	DocumentObject.Comment = NStr("vi = 'Được tạo tự động bằng cách xử lý ""khấu trừ thanh toán"".';
									|ru = 'Сформирован автоматически обработкой ""Зачет оплат"".';
									|en = 'It is generated automatically by data processor ""Payment offset"".'; fa = 'It is generated automatically by data processor ""Payment offset"".';
									|it = 'Generato automaticamente dall''elaborazione ""Imputazione dei pagamenti"".';
									|pl = 'Sformowany automatycznie przetwarzaniem ""Księgowanie płatności"".';
									|tr = '""Ödeme mahsubu""nun işlenmesiyle otomatik olarak oluşturuldu.'");
	
	CreditGiftCertificate = TypeOf(DataBalanced.Object) = Type("CatalogRef.GiftCertificates");
	DocumentObject.Creditor = Counterparty;
	DocumentObject.CounterpartyDebtor  = Counterparty;
	
	TypeOfCounterparty = Undefined;
	If ThereAreSettlementsBetweenCompanies Then
		
		DocumentObject.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary;
		TypeOfCounterparty = ?(ThereAreCustomersARAP,
			Enums.ARAPSettlemenParticipantTypes.OrganizationClient,
			Enums.ARAPSettlemenParticipantTypes.CompanyVendor);
			
	ElsIf ThereAreCustomersARAP Then
		If DataBalanced.ARAPCurrency = ARAPCurrency Then
			If CreditGiftCertificate Then
				DocumentObject.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard;
				DocumentObject.Creditor = Common.ObjectAttributeValue(DataBalanced.ARAPObject, "Counterparty");
			Else
				DocumentObject.OperationKind  = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty;
			EndIf;
		Else
			DocumentObject.OperationKind  = Enums.KindsOfARAPSettlements.Arbitrary;
		EndIf;
		TypeOfCounterparty = Enums.ARAPSettlemenParticipantTypes.Client;
	Else //VendorsARAPAccounting
		If DataBalanced.ARAPCurrency = ARAPCurrency Then
			DocumentObject.OperationKind  = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty;
		Else
			DocumentObject.OperationKind  = Enums.KindsOfARAPSettlements.Arbitrary;
		EndIf;
		TypeOfCounterparty = Enums.ARAPSettlemenParticipantTypes.Vendor;
	EndIf;
	
	If DataBalanced.Organization <> Organization Then
		DocumentObject.Organization    = ParentCompany;
	Else
		DocumentObject.Organization    = Organization;
	EndIf;
	
	DocumentObject.CounterpartyDebtorType        = TypeOfCounterparty;
	DocumentObject.CounterpartyCreditorType       = TypeOfCounterparty;
	DocumentObject.SumCompl          = SumStructure.SumCompl;
	DocumentObject.SumMan           = SumStructure.SumMan;
	
	If ThereAreCustomersARAP Then
		AdvanceLine_ = DocumentObject.AccountsReceivable.Add();
		CreditLine = DocumentObject.AccountsPayable.Add();
	Else
		AdvanceLine_ = DocumentObject.AccountsPayable.Add();
		CreditLine = DocumentObject.AccountsReceivable.Add();
	EndIf;
	
	AdvanceLine_.Organization          = Organization;
	AdvanceLine_.Partner              = DocumentPartner;
	AdvanceLine_.ARAPObject       = ARAPObject;
	AdvanceLine_.ARAPCurrency = ARAPCurrency;
	AdvanceLine_.AmountARAP  = Sum;
	AdvanceLine_.SumCompl            = SumStructure.SumCompl;
	AdvanceLine_.SumMan             = SumStructure.SumMan;
	
	FillPropertyValues(CreditLine, DataBalanced);
	CreditLine.AmountARAP = SumStructure.AmountInPaymentCurrency;
	CreditLine.SumCompl           = SumStructure.SumCompl;
	CreditLine.SumMan            = SumStructure.SumMan;

	ErrorText = NStr("vi = 'Không thể tạo chứng từ đối trừ công nợ.';
					|ru = 'Не удалось создать документ взаимозачета.';
					|en = 'Cannot create offsetting document.'; fa = 'Cannot create offsetting document.';
					|it = 'Non è stato possibile creare il documento di compensazione.';
					|pl = 'Nie udało się stworzyć dokument kompensaty.';
					|tr = 'Uzlaşma belgesi oluşturulamadı.'");
	DocumentObject.Write(DocumentWriteMode.Posting);

	DataBalanced.Document = DocumentObject.Ref;
	ErrorText = "";
	
EndProcedure

&AtClient
Procedure NotifyAboutResultOfPaymentOffset(ArrayOfProcessedDocuments)
	
	If ArrayOfProcessedDocuments.Count() = 0 Then
		Text = NStr("vi = 'Không có thay đổi trong khấu trừ thanh toán';
					|ru = 'Изменений в зачете оплаты не было';
					|en = 'There were no changes in payment offset'; fa = 'There were no changes in payment offset';
					|it = 'Non ci sono modifiche nell''imputazione del pagamento';
					|pl = 'Zmiany w księgowaniu płatności nie było';
					|tr = 'Ödeme mahsubunda değişiklik mevcut değil'");
		Explanation = NStr("vi = 'Không có thay đổi trong chứng từ khi khấu trừ thanh toán';
							|ru = 'Изменений в документах при зачете оплаты не было';
							|en = 'There were no changes in documents on payment offset'; fa = 'There were no changes in documents on payment offset';
							|it = 'Non ci sono modifiche nei documenti durante l''imputazione del pagamento';
							|pl = 'Zmian w dokumentach podczas księgowania płatności nie było';
							|tr = 'Ödeme mahsup edilirken belgelerde herhangi bir değişiklik olmadı'");
		ShowUserNotification(
			Text,
			, // URL
			Explanation,
			PictureLib.Information32);
	Else
		For Each DocumentRef In ArrayOfProcessedDocuments Do
			Text = NStr("vi = 'Đã thay đổi khấu trừ thanh toán';
						|ru = 'Изменен зачет оплаты';
						|en = 'Payment offset is changed'; fa = 'Payment offset is changed';
						|it = 'L''imputazione del pagamento è stata modificata';
						|pl = 'Zmieniono księgowanie płatności';
						|tr = 'Ödeme mahsubu değiştirildi'");
			Explanation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã thay đổi khấu trừ thanh toán theo chứng từ: %1';
					|ru = 'Изменен зачет оплаты по документу: %1';
					|en = 'Payment offset against the document is changed: %1'; fa = 'Payment offset against the document is changed: %1';
					|it = 'È stata modificata l''imputazione del pagamento del documento: %1';
					|pl = 'Zmieniono księgowanie płatności dla dokumentu: %1';
					|tr = '%1 belge ödeme mahsubu değiştirildi'"),
				DocumentRef);
			ShowUserNotification(
				Text,
				GetURL(DocumentRef),
				Explanation,
				PictureLib.Information32);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure UnlockDocumentsForEditing()
	
	UnlockDataForEdit(
			, // Key
			UUID);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure UpdateDataOnServer()
	
	UnlockDocumentsForEditing();
	GetPaymentDetailsWithPartner();
	FillInTableForSettlementsWithPartners();
	
EndProcedure

&AtServer
Procedure CalculateAmountOfCredit()
	
	OffsetAmount_ = SetOff.Total("AmountCredited_2");
	AmountOfCancelledCredits = Payments.Unload(New Structure("UnsavedData",True)).Total("AvailableToSetOff")
		+Prepayments.Unload(New Structure("UnsavedData",True)).Total("AvailableToSetOff");
	
	If AmountDueBalanceUnderContract Then
		If AmountARAP + AmountOfCancelledCredits> 0 Then
			Lacks = AmountARAP + AmountOfCancelledCredits;
			Excess = 0;
		Else
			Lacks = 0;
			Excess = -(AmountARAP +AmountOfCancelledCredits);
		EndIf;
	Else
		If OffsetAmount_ < AmountARAP Then
			Lacks = AmountARAP - OffsetAmount_;
			Excess = 0;
		Else
			Lacks = 0;
			Excess = OffsetAmount_ - AmountARAP;
		EndIf;
	EndIf;
	
	If AmountARAP < 0 Then
		AmountToPay = 0;
	Else
		AmountToPay = AmountARAP + ?(AmountDueBalanceUnderContract,AmountOfCancelledCredits,0);
	EndIf;
	
	Items.CorrectExcess.Visible = (Excess > 0);
	
	UpdateInformationLabel();
	
EndProcedure

&AtServer
Procedure UpdateInformationLabel()
	
	RowsArray = New Array;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
		And ARAPObjectType = Enums.ARAPObjectTypes.OrderDocument Then
		TemplateForPayment = NStr("vi = 'Số tiền tạm ứng cần thanh toán %1%2.';
									|ru = 'Сумма аванса к оплате %1 %2.';
									|en = 'Advance amount to pay %1 %2.'; fa = 'Advance amount to pay %1 %2.';
									|it = 'Importo dell''acconto da pagare %1 %2.';
									|pl = 'Kwota zaliczki do zapłaty %1 %2.';
									|tr = 'Ödenecek avans tutarı %1 %2.'");
	Else
		TemplateForPayment = NStr("vi = 'Số tiền cần thanh toán %1 %2.';
									|ru = 'Сумма к оплате %1 %2.';
									|en = 'Amount due %1 %2.'; fa = 'Amount due %1 %2.';
									|it = 'Importo da pagare %1 %2.';
									|pl = 'Wartość do płatności %1 %2.';
									|tr = 'Ödenecek borç %1 %2.'");
	EndIf;
	RowsArray.Add(New FormattedString(
		StringFunctionsClientServer.SubstituteParametersToString(
		TemplateForPayment,
		Format(AmountToPay, "NFD=2; NDS=; NZ="),
		ARAPCurrency)));
	
	RowsArray.Add("   ");
	
	RowsArray.Add(New FormattedString(
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã khấu trừ số tiền %1 %2.';
			|ru = 'Зачтено на сумму %1 %2.';
			|en = 'Offset in the amount of %1 %2.'; fa = 'Offset in the amount of %1 %2.';
			|it = 'Imputato per l''importo %1 %2.';
			|pl = 'Zaksięgowano na wartość %1 %2.';
			|tr = 'Mahsup edilen tutar %1 %2.'"),
		Format(OffsetAmount_, "NFD=2; NDS=; NZ="),
		ARAPCurrency)));
	
	If Lacks > 0 Then
		
		RowsArray.Add("   ");
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = ' %1 %2 bị thiếu.';
				|ru = 'Недостает %1 %2.';
				|en = 'Missing %1 %2.'; fa = 'Missing %1 %2.';
				|it = 'Manca %1 %2.';
				|pl = 'Brakuje %1 %2.';
				|tr = 'Eksik kalıyor %1 %2.'"),
			Format(Lacks, "NFD=2; NDS=; NZ="),
			ARAPCurrency);
		
		RowsArray.Add(New FormattedString(Text, , StyleColors.OverdueDataColor));
		
	ElsIf Excess > 0 Then
		
		RowsArray.Add("   ");
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = ' %1 %2 thừa.';
				|ru = 'Превышение на %1 %2.';
				|en = 'Exceeding %1 %2.'; fa = 'Exceeding %1 %2.';
				|it = 'Eccesso di %1 %2.';
				|pl = 'Przekroczenie na %1 %2.';
				|tr = '%1 %2 fazla.'"),
			Format(Excess, "NFD=2; NDS=; NZ="),
			ARAPCurrency);
			
		RowsArray.Add(New FormattedString(Text, , StyleColors.OverdueDataColor));
		
	EndIf;
	
	HelpText = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()
	
	LabelFilters = NStr("vi = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%';
						|ru = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%';
						|en = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%'; fa = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%';
						|it = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%';
						|pl = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%';
						|tr = '%Organization%, %Partner%, %Counterparty%, %Contract%, %LineOfBusiness%'");
	
	If Not UseContracts Then
		LabelFilters = StrReplace(LabelFilters, ", %Contract%", "");
	EndIf;
	
	If UsePartnersAsCounterparties Then
		LabelFilters = StrReplace(LabelFilters, ", %Counterparty%", "");
	EndIf;
	
	If Not UseMultipleCompanies Then
		LabelFilters = StrReplace(LabelFilters, "%Organization%,", "");
	EndIf;
	
	If Not ValueIsFilled(LineOfBusiness) Then
		LabelFilters = StrReplace(LabelFilters, ", %LineOfBusiness%", "");
	EndIf;
	
	LabelFilters = StrReplace(LabelFilters,"%Organization%",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Doanh nghiệp: %1';
																		|ru = 'Организация: %1';
																		|en = 'Company: %1'; fa = 'Company: %1';
																		|it = 'Società: %1';
																		|pl = 'Firma: %1';
																		|tr = 'İş yeri: %1'"), Organization));
	LabelFilters = StrReplace(LabelFilters,"%Partner%",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Bạn hàng: %1';
																		|ru = 'Партнер: %1';
																		|en = 'Partner: %1'; fa = 'Partner: %1';
																		|it = 'Partner: %1';
																		|pl = 'Partner: %1';
																		|tr = 'İş ortağı: %1'"), Partner));
	LabelFilters = StrReplace(LabelFilters,"%Counterparty%",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối tác: %1';
																		|ru = 'Контрагент: %1';
																		|en = 'Counterparty: %1'; fa = 'Counterparty: %1';
																		|it = 'Controparte:  %1';
																		|pl = 'Kontrahent: %1';
																		|tr = 'Cari hesap: %1'"), Counterparty));
	LabelFilters = StrReplace(LabelFilters,"%Contract%",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hợp đồng: %1';
																		|ru = 'Договор: %1';
																		|en = 'Contract: %1'; fa = 'Contract: %1';
																		|it = 'Contratto: %1';
																		|pl = 'Kontrakt: %1';
																		|tr = 'Sözleşme: %1'"), Contract));
	LabelFilters = StrReplace(LabelFilters,"%LineOfBusiness%",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lĩnh vực hoạt động: %1';
																		|ru = 'Направление деятельности: %1';
																		|en = 'Line of business: %1'; fa = 'Line of business: %1';
																		|it = 'Settore di attività: %1';
																		|pl = 'Rodzaj działalności: %1';
																		|tr = 'İş kolu: %1'"), LineOfBusiness));
	
EndProcedure

&AtServer
Procedure EstablishContractSelection()
	
	If Not UseContracts Or ByAllContracts = 1 Then
		Items.Prepayments.RowFilter = Undefined;
	Else
		FilterPrepayments = New FixedStructure("Contract", Contract);
		Items.Prepayments.RowFilter = FilterPrepayments;
	EndIf;
	
EndProcedure

&AtServer
Function ConvertAmountToSettlementCurrency(Sum, SourceCurrency, Val DateOfCourse = Undefined)
	
	If Not ValueIsFilled(DateOfCourse) Then
		DateOfCourse = CurrentSessionDate();
	EndIf;
	
	Result = ProcessingOfExchangeRatesTM.ConvertDocumentAmountToCurrency(
		Sum, SourceCurrency, ARAPCurrency, DateOfCourse, LocalAccountingCurrency);
		
	Return Result;
	
EndFunction

&AtServer
Procedure CalculateNumberOfRows_()
	
	PaymentsNumberOfLines = Payments.Count();
	If AdvancesAreCalculated Then
		AdvancesLineQuantity = Prepayments.Count();
	Else
		AdvancesLineQuantity = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformMirrorDocumentChanges(QuestionResult, AdditionalParameters) Export
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		ArrayOfProcessedDocuments = PerformMirrorChangesToDocumentsOnServer(AdditionalParameters.ArrayOfProcessedDocuments);
			
		If ArrayOfProcessedDocuments.Count() > 0 Then
			NotifyAboutResultOfPaymentOffset(ArrayOfProcessedDocuments);
			
			Notify("PaymentCredited", AdditionalParameters.Document);
		EndIf;

	EndIf;
	
EndProcedure

&AtServerNoContext
Function MatchMirrorPayments(ArrayOfProcessedDocuments)
	
	CorrespondTo = True;
	
	For Each DocumentRef In ArrayOfProcessedDocuments Do
		
		InvertedPaymentReference = Undefined;
		If TypeOf(DocumentRef) = Type("DocumentRef.BankAccountIssue") Then
			
			InvertedPaymentReference = Documents.BankAccountIssue.FindMirrorPayment(DocumentRef);
			
			If ValueIsFilled(InvertedPaymentReference) Then
				If Not Documents.BankAccountIssue.CorrespondsToInvertedPayment(DocumentRef,InvertedPaymentReference) Then
					CorrespondTo = False;
				EndIf;				
			EndIf;

		ElsIf TypeOf(DocumentRef) = Type("DocumentRef.BankAccountReceiptNote") Then
			
			InvertedPaymentReference = Documents.BankAccountReceiptNote.FindMirrorPayment(DocumentRef);
			
			If ValueIsFilled(InvertedPaymentReference) Then
				If Not Documents.BankAccountReceiptNote.CorrespondsToInvertedPayment(DocumentRef,InvertedPaymentReference) Then
					CorrespondTo = False;
				EndIf;
			EndIf;

		EndIf;
		
	EndDo;
	
	Return CorrespondTo;
	
EndFunction

&AtServerNoContext
Function PerformMirrorChangesToDocumentsOnServer(ArrayOfProcessedDocuments)
	
	ProcessedDocuments = New Array();
	
	For Each DocumentRef In ArrayOfProcessedDocuments Do
		
		InvertedPaymentReference = Undefined;
		If TypeOf(DocumentRef) = Type("DocumentRef.BankAccountIssue") Then
			InvertedPaymentReference = Documents.BankAccountIssue.FindMirrorPayment(DocumentRef);
			
			If ValueIsFilled(InvertedPaymentReference) Then
				MirrorPaymentObject = InvertedPaymentReference.GetObject();
				Success = Documents.BankAccountIssue.AlignMirrorPayment(DocumentRef,MirrorPaymentObject);
				
				If Success Then
					MirrorPaymentObject.Write(DocumentWriteMode.Posting);
					ProcessedDocuments.Add(MirrorPaymentObject.Ref);
				EndIf;
			EndIf;
		ElsIf TypeOf(DocumentRef) = Type("DocumentRef.BankAccountReceiptNote") Then
			InvertedPaymentReference = Documents.BankAccountReceiptNote.FindMirrorPayment(DocumentRef);
			
			If ValueIsFilled(InvertedPaymentReference) Then
				MirrorPaymentObject = InvertedPaymentReference.GetObject();
				Success = Documents.BankAccountReceiptNote.AlignMirrorPayment(DocumentRef,MirrorPaymentObject);
				
				If Success Then
					MirrorPaymentObject.Write(DocumentWriteMode.Posting);
					ProcessedDocuments.Add(MirrorPaymentObject.Ref);
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return ProcessedDocuments;
	
EndFunction

&AtServer
Procedure InstallAdvancesPage()
	If AdvancesAreCalculated Then
		Items.PageGroupAdvances.CurrentPage = Items.PageAllocationIsCompleted;
	Else
		Items.PageGroupAdvances.CurrentPage = Items.PageAllocationIsInProgress;
	EndIf;
EndProcedure

&AtServer
Function ThereAreTasksForDistributionOfSettlements(CustomersARAPAccounting, DimensionKeys)
	
	If ThereAreCustomersARAP Then
		TaskRegisterName = "JobsForAllocatingCustomersARAP";
	Else
		TaskRegisterName = "JobsForAllocatingVendorsARAP";
	EndIf;
	
	Query = New Query;
	QueryText = "
	|SELECT TOP 1
	|	1 AS Number
	|FROM
	|	&Table AS Jobs
	|WHERE
	|	Jobs.AccountingDimensionByPartners IN (&DimensionKeys)
	|	AND Jobs.Month <= &Month";
	
	Query.Text = StrReplace(QueryText, "&Table", "InformationRegister." + TaskRegisterName);
	Query.SetParameter("DimensionKeys",DimensionKeys);
	Query.SetParameter("Month",BegOfMonth(CurrentSessionDate()));
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

#EndRegion

#EndRegion
