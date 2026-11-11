#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the document with the advances and electronic tickets received by the accountable person
//
Procedure FillInReceivedAdvances() Export
	
	OtherExpenses.Load(GetETickets(ThisObject).Unload());
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	Cash.Currency AS Currency,
	|	Cash.SumBalance AS Sum
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|		&Date,
	|		Organization = &Organization
	|		AND AdvanceHolder = &AdvanceHolder
	|		AND Department = &Department
	|		AND (Currency = &Currency OR &Multicurrency)
	|	) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|";
	
	Query.SetParameter("Date", New Boundary(EndOfDay(Date), BoundaryType.Including));
	Query.SetParameter("AdvanceHolder", AdvanceHolder);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("Multicurrency", Multicurrency);
	
	LinesToAdd_ = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		FilterOfExpenses = New Structure("CashFlowItem, Currency",
			Selection.CashFlowItem, Selection.Currency);
		
		TicketSelection = OtherExpenses.Unload(FilterOfExpenses, "Sum");
		TicketAmount = 0;
		If TicketSelection.Count() Then
			TicketSelection.GroupBy(, "Sum");
			TicketAmount = TicketSelection[0].Sum;
		EndIf;
		
		If Selection.Sum > TicketAmount Then
			LinesToAdd_.Add(New Structure("CashFlowItem, Currency, Sum",
				Selection.CashFlowItem, Selection.Currency, Selection.Sum - TicketAmount));
		EndIf;
	EndDo;
	
	For Each LineToAdd_ In LinesToAdd_ Do
		FillPropertyValues(OtherExpenses.Add(), LineToAdd_);
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("DocumentRef.CashVoucher") Then
		
		FillInUsingExpenseCashOrder(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BankAccountIssue") Then
		
		InstructionsForDebitingNonCashFunds(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForBusinessTrip") Then
		
		FillInApplicationForBusinessTrip(FillingData, FillingData);
	
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		ToRegister = New Array;
		If FillingData.Property("ToRegister", ToRegister) Then
			
			Header = ToRegister[0];
			FillPropertyValues(ThisObject, Header);
			
			IssuanceObjectives = New Array;
			For Each LineToDesign In ToRegister Do
				If ValueIsFilled(LineToDesign.IssuancePurpose) Then
					IssuanceObjectives.Add(LineToDesign.IssuancePurpose);
				EndIf;
			EndDo;
			
			OtherExpenses.Load(GetETickets(ThisObject, IssuanceObjectives).Unload());
			
			LinesToAdd_ = New Array;
			
			For Each LineToDesign In ToRegister Do
				
				If LineToDesign.SumBalance = 0 Then
					Continue;
				EndIf;
				
				FilterOfExpenses = New Structure("CashFlowItem, Currency",
					LineToDesign.IssuancePurpose, LineToDesign.Currency);
				
				TicketSelection = OtherExpenses.Unload(FilterOfExpenses, "Sum");
				TicketAmount = 0;
				If TicketSelection.Count() Then
					TicketSelection.GroupBy(, "Sum");
					TicketAmount = TicketSelection[0].Sum;
				EndIf;
		
				If LineToDesign.SumBalance > TicketAmount Then
					LinesToAdd_.Add(New Structure("CashFlowItem, Currency, Sum",
						LineToDesign.IssuancePurpose, LineToDesign.Currency, LineToDesign.SumBalance - TicketAmount));
				EndIf;
			EndDo;
			
			For Each LineToAdd_ In LinesToAdd_ Do
				FillPropertyValues(OtherExpenses.Add(), LineToAdd_);
			EndDo;
			
		EndIf;
	EndIf;
	
	ExpenseReportLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	FillParameters = Documents.ExpenseReport.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Status);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	ConfirmationDate = Date('00010101');
	AmountExpensed		= 0;
	AmountRejected			= 0;
	DocumentsCount	= 0;
	SheetQuantity		= 0;
	DocumentBasis  = Undefined;
	
	If Not GetFunctionalOption("UseExpenseReportStatuses") Then
		Status = Enums.ExpenseReportStatuses.Upholded;
	Else
		Status = Enums.ExpenseReportStatuses.Prepared;
	EndIf;
	
	For Each TSRow In OtherExpenses Do
		TSRow.PrintFormLocalAccounting = False;
		TSRow.SourceDocument = Undefined;
		TSRow.ElectronicTicket = Undefined;
	EndDo;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "OtherExpenses,PaymentToVendors,CurrencyConversion");
	
	ExpenseReportLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	UseExpenseReportStatuses = GetFunctionalOption("UseExpenseReportStatuses");
	
	TabularSection = Metadata().TabularSections.Find("OtherExpenses");
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("OtherExpenses.CancellationReason");
	
	If Status <> Enums.ExpenseReportStatuses.Upholded Then
		NotCheckedAttributeArray.Add("ConfirmationDate");
	EndIf;
	
	ArrayOfManualVerificationDetails = New Array;
	ArrayOfManualVerificationDetails.Add("ExpenseItem");
	ArrayOfManualVerificationDetails.Add("VATRate");
	
	ArrayOfManualVerificationDetailsIsNotRequired = New Array;
	ArrayOfManualVerificationDetailsIsNotRequired.Add("Sum");
	If GetFunctionalOption("ControlIssueOfCashByPurposes") Then
		ArrayOfManualVerificationDetailsIsNotRequired.Add("CashFlowItem");
	EndIf;
	
	If GetFunctionalOption("UseBusinessUnits") Then
		ArrayOfManualVerificationDetails.Add("Department");
	EndIf;
	
	For Each Attribute In ArrayOfManualVerificationDetails Do
		NotCheckedAttributeArray.Add("OtherExpenses." + Attribute);
	EndDo;
	For Each Attribute In ArrayOfManualVerificationDetailsIsNotRequired Do
		NotCheckedAttributeArray.Add("OtherExpenses." + Attribute);
	EndDo;
	
	If Multicurrency Then
		NotCheckedAttributeArray.Add("Currency");
	Else
		NotCheckedAttributeArray.Add("OtherExpenses.Currency");
		NotCheckedAttributeArray.Add("PaymentToVendors.Currency");
		NotCheckedAttributeArray.Add("CurrencyConversion");
		NotCheckedAttributeArray.Add("CurrencyConversion.Sum");
		NotCheckedAttributeArray.Add("CurrencyConversion.Currency");
		NotCheckedAttributeArray.Add("CurrencyConversion.ConversionAmount");
		NotCheckedAttributeArray.Add("CurrencyConversion.CurrencyOfConversion");
		NotCheckedAttributeArray.Add("CurrencyConversion.Rate");
		NotCheckedAttributeArray.Add("CurrencyConversion.CashFlowItem");
	EndIf;
	
	NotCheckedAttributeArray.Add("OtherExpenses.Counterparty");
	
	If UseExpenseReportStatuses
		And Status = Enums.ExpenseReportStatuses.Upholded Then
		If Not UserRightsCached.ApprovalOfExpenseReports() Then
			ErrorText = NStr("vi = 'Bạn không có quyền phê duyệt giấy thanh toán tạm ứng.';
							|ru = 'У вас отсутствует право утверждения авансовых отчетов.';
							|en = 'You are not authorized to confirm expense reports.'; fa = 'You are not authorized to confirm expense reports.';
							|it = 'Lei non possiede il diritto di autorizzare note spese.';
							|pl = 'Nie masz uprawnienia zatwierdzenia raportów rozchodów.';
							|tr = 'Gider raporu onaylama yetkiniz bulunmuyor.'");
			CommonClientServer.MessageToUser(ErrorText, ThisObject,,, Cancel);
		EndIf;
	EndIf;
	
	ReflectDocumentInAccounting = Not UseExpenseReportStatuses
		Or UseExpenseReportStatuses And Status = Enums.ExpenseReportStatuses.Upholded;
	
	For CurIndex__ = 0 To OtherExpenses.Count()-1 Do
		
		ErrorAddress = StrTemplate(NStr("vi = 'trong dòng %1 của danh sách ""Chi phí""';
										|ru = 'в строке %1 списка ""Расходы""';
										|en = 'in the %1 line of the ""Expenses"" list'; fa = 'in the %1 line of the ""Expenses"" list';
										|it = 'nella riga %1 dell''elenco ""Spese""';
										|pl = 'w wierszu %1 listy ""Rozchody""';
										|tr = '""Giderler"" listesinde %1 satırında'"), OtherExpenses[CurIndex__].LineNumber);
		
		If UseExpenseReportStatuses
			And OtherExpenses[CurIndex__].Canceled And
			Not ValueIsFilled(OtherExpenses[CurIndex__].CancellationReason) Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ';
							|ru = 'Необходимо указать причину отмены';
							|en = 'Cancellation reason is required'; fa = 'Cancellation reason is required';
							|it = 'È necessario specificare il motivo di annullamento';
							|pl = 'Należy wskazać przyczynę anulowania';
							|tr = 'İptal nedeni belirtilmelidir'");
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("OtherExpenses", OtherExpenses[CurIndex__].LineNumber, "CancellationReason"),,
				Cancel);
		EndIf;
		
		ReflectLineInAccounting = ReflectDocumentInAccounting And Not OtherExpenses[CurIndex__].Canceled;
		
		For Each Attribute In ArrayOfManualVerificationDetails Do
			If Not ValueIsFilled(OtherExpenses[CurIndex__][Attribute])
				And ReflectLineInAccounting Then
				
				ErrorText = StrTemplate(NStr("vi = 'Cột ''''%1'''' không được điền';
											|ru = 'Не заполнена колонка ""%1""';
											|en = 'Column ""%1"" is not filled in'; fa = 'Column ""%1"" is not filled in';
											|it = 'Non è compilata la colonna ""%1""';
											|pl = 'Nie wypełniono kolumny ""%1""';
											|tr = '""%1"" sütunu doldurulmadı'"), TabularSection.Attributes[Attribute]);
				CommonClientServer.MessageToUser(
					ErrorText + " " + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("OtherExpenses", OtherExpenses[CurIndex__].LineNumber, Attribute),,
					Cancel);
			EndIf;
		EndDo;
		
		For Each Attribute In ArrayOfManualVerificationDetailsIsNotRequired Do
			If Not ValueIsFilled(OtherExpenses[CurIndex__][Attribute])
				And Not ValueIsFilled(OtherExpenses[CurIndex__].ElectronicTicket) Then
				
				ErrorText = StrTemplate(NStr("vi = 'Cột ''''%1'''' không được điền';
											|ru = 'Не заполнена колонка ""%1""';
											|en = 'Column ""%1"" is not filled in'; fa = 'Column ""%1"" is not filled in';
											|it = 'Non è compilata la colonna ""%1""';
											|pl = 'Nie wypełniono kolumny ""%1""';
											|tr = '""%1"" sütunu doldurulmadı'"), TabularSection.Attributes[Attribute]);
				CommonClientServer.MessageToUser(
					ErrorText + " " + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("OtherExpenses", OtherExpenses[CurIndex__].LineNumber, Attribute),,
					Cancel);
			EndIf;
		EndDo;
		
		If Not ValueIsFilled(OtherExpenses[CurIndex__]["Counterparty"])
			And (OtherExpenses[CurIndex__]["VATRate"] <> Catalogs.VATRates.EXCLUDINGVAT
				And (OtherExpenses[CurIndex__]["InvIsSubmitted"] Or OtherExpenses[CurIndex__]["PrintFormLocalAccounting"]))
			And ReflectLineInAccounting Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Đối tác""';
							|ru = 'Не заполнена колонка ""Контрагент""';
							|en = 'Column ""Counterparty"" is not filled in'; fa = 'Column ""Counterparty"" is not filled in';
							|it = 'La colonna ""Contraente"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Контрагент""';
							|tr = '""Cari Hesap"" sütunu doldurulmadı'");
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("OtherExpenses", OtherExpenses[CurIndex__].LineNumber, "Counterparty"),,
				Cancel);
		EndIf;
	EndDo;
	
	For Each ConversionString In CurrencyConversion Do
		If ConversionString.Currency = ConversionString.CurrencyOfConversion Then
			
			ErrorAddress = StrTemplate(NStr("vi = 'trong dòng %1 của danh sách ''''Chuyển đổi tiền tệ''''';
											|ru = 'в строке %1 списка ""Конвертация валюты""';
											|en = 'in the %1 line of the ""Currency conversion"" list'; fa = 'in the %1 line of the ""Currency conversion"" list';
											|it = 'nella riga %1 dell''elenco ""Conversione valuta""';
											|pl = 'w wierszu %1 listy „Konwersja walut”';
											|tr = '""Para birimi dönüştürücü"" listesinde %1 satırında'"), ConversionString.LineNumber);
			ErrorText = NStr("vi = 'Tiền tệ quy đổi phải khác với tiền tệ trong chứng từ';
							|ru = 'Валюта конвертации должна отличаться от валюты документа';
							|en = 'Conversion currency should differ from the document currency'; fa = 'Conversion currency should differ from the document currency';
							|it = 'La valuta di conversione deve differire dalla valuta del documento';
							|pl = 'Waluta konwersji powinna różnić się od waluty dokumentu';
							|tr = 'Dönüştürücü para birimi, belgenin para biriminden farklı olmalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("CurrencyConversion", ConversionString.LineNumber, "CurrencyOfConversion"),,
				Cancel);
		EndIf;
	EndDo;
	
	CheckDuplicatesOfVATAccountingForPrimaryDocuments(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "OtherExpenses";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Status);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ExpenseReportLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	If WriteMode = DocumentWriteMode.Posting Then
		CheckAvailabilityOfIdenticalExpenseReport(Cancel);
	EndIf;
	
	AmountExpensed = 0;
	AmountRejected = 0;
	
	If Not Multicurrency Then
		For Each Expense In OtherExpenses Do
			If Expense.Canceled Then
				AmountRejected = AmountRejected + Expense.AmountIncludingVAT;
			Else
				AmountExpensed = AmountExpensed + Expense.AmountIncludingVAT;
			EndIf;
			Expense.Currency = Currency;
		EndDo;
		For Each Payment In PaymentToVendors Do
			Payment.Currency = Currency;
		EndDo;
		AmountExpensed = AmountExpensed + PaymentToVendors.Total("Sum");
		CurrencyConversion.Clear();
	EndIf;
	
	MonitorByGoals = GetFunctionalOption("ControlIssueOfCashByPurposes");
	
	CurrencyTotals = New Map;
	For Each TSRow In OtherExpenses Do
		If ValueIsFilled(TSRow.Currency) Then
			If TSRow.Canceled Then
				Continue;
			EndIf;
			SearchKey = String(TSRow.Currency) + ?(MonitorByGoals, "/" + String(TSRow.CashFlowItem), "");
			CurrentTotal = CurrencyTotals.Get(SearchKey);
			If CurrentTotal = Undefined Then
				CurrentTotal = TSRow.AmountIncludingVAT;
			Else
				CurrentTotal = CurrentTotal + TSRow.AmountIncludingVAT;
			EndIf;
			TSRow.AmountTotal = CurrentTotal;
			CurrencyTotals.Insert(SearchKey, CurrentTotal);
		EndIf;
	EndDo;
	
	For Each TSRow In PaymentToVendors Do
		If ValueIsFilled(TSRow.Currency) Then
			SearchKey = String(TSRow.Currency) + ?(MonitorByGoals, "/" + String(TSRow.CashFlowItem), "");
			CurrentTotal = CurrencyTotals.Get(SearchKey);
			If CurrentTotal = Undefined Then
				CurrentTotal = TSRow.Sum;
			Else
				CurrentTotal = CurrentTotal + TSRow.Sum;
			EndIf;
			TSRow.AmountTotal = CurrentTotal;
			CurrencyTotals.Insert(SearchKey, CurrentTotal);
		EndIf;
	EndDo;
	
	For Each TSRow In CurrencyConversion Do
		If ValueIsFilled(TSRow.Currency) Then
			SearchKey = String(TSRow.Currency) + ?(MonitorByGoals, "/" + String(TSRow.CashFlowItem), "");
			CurrentTotal = CurrencyTotals.Get(SearchKey);
			If CurrentTotal = Undefined Then
				CurrentTotal = TSRow.Sum;
			Else
				CurrentTotal = CurrentTotal + TSRow.Sum;
			EndIf;
			TSRow.AmountTotal = CurrentTotal;
			CurrencyTotals.Insert(SearchKey, CurrentTotal);
		EndIf;
	EndDo;
	
	If Not GetFunctionalOption("UseExpenseReportStatuses") Then
		ConfirmationDate = Date;
	EndIf;
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(Currency, Date, PaymentToVendors, Organization);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "OtherExpenses,PaymentToVendors,CurrencyConversion");
	
	GeneratePrimaryDocuments(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Status);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ExpenseReport.AccountingAccountSettings_(Status));
	ExpenseReportLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DocumentsToBeAdded = New Array;
	DocumentsToDelete = New Array;
	
	If AdditionalProperties.Property("PurchaseDocumentsAll") Then
		
		DocumentsToBeAdded = New Array;
		DocumentsToDelete = New Array;
		
		PurchaseDocumentsAll = AdditionalProperties.PurchaseDocumentsAll;
		DocumentsInReport = Documents.ExpenseReport.PurchasingDocumentsList(Ref);
		
		For Each DocumentInReport In DocumentsInReport Do
			If PurchaseDocumentsAll.Find(DocumentInReport) = Undefined Then
				DocumentsToDelete.Add(DocumentInReport);
			EndIf;
		EndDo;
		
		For Each DocumentPurchases In PurchaseDocumentsAll Do
			If (TypeOf(DocumentPurchases) = Type("DocumentRef.VendorInvoice")
				Or TypeOf(DocumentPurchases) = Type("DocumentRef.ElectronicTicketTransaction"))
				And DocumentsInReport.Find(DocumentPurchases) = Undefined Then
				DocumentsToBeAdded.Add(DocumentPurchases);
			EndIf;
		EndDo;
		
		Documents.ExpenseReport.DeleteAddPurchaseDocuments(Undefined, DocumentsToDelete, AdditionalProperties, Cancel);
		Documents.ExpenseReport.DeleteAddPurchaseDocuments(Ref, DocumentsToBeAdded, AdditionalProperties, Cancel);
	EndIf;
	
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	If Not DocumentProperties.IsNew And DocumentProperties.WriteMode = DocumentWriteMode.Write Then
		UpdatePrimaryDocuments(DocumentWriteMode.Write, Cancel);
	EndIf;
	
	ExpenseReportLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	UpdatePrimaryDocuments(DocumentWriteMode.Posting, Cancel);
	
	ExpenseReportLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	UpdatePrimaryDocuments(DocumentWriteMode.UndoPosting, Cancel);
	
	ExpenseReportLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInUsingExpenseCashOrder(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	&Ref AS DocumentBasis,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.CashAccount.CashCurrency AS Currency,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.Department AS Department,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	Cash.SumBalance AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate
	|FROM
	|	Document.CashVoucher AS DocumentData
	|	
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(,
	|			AdvanceHolder = &AdvanceHolder
	|			AND Organization = &Organization
	|			AND Currency = &Currency) AS Cash
	|	ON
	|		TRUE
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|");
	
	DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, "Organization, Department, AdvanceHolder, Currency");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Organization", DetailsOfFoundation.Organization);
	Query.SetParameter("Department", DetailsOfFoundation.Department);
	Query.SetParameter("AdvanceHolder", DetailsOfFoundation.AdvanceHolder);
	Query.SetParameter("Currency", DetailsOfFoundation.Currency);
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy thanh toán tiền tạm ứng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить авансовый отчет на основании документа %1';
				|en = 'It is not required to enter an expense report based on document %1'; fa = 'It is not required to enter an expense report based on document %1';
				|it = 'Non è necessario inserire la nota spese in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie raportu rozchodów na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı gider raporu girmek gerekli değildir.'"),
			DocumentBasis);
		Raise Text;
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			DocumentBasis,
			Undefined, // Status
			Selection.ThereAreErrorsPosted);
		FillPropertyValues(FillingData, Selection);
		
		Selection.Reset();
		While Selection.Next() Do
			NewRow = OtherExpenses.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
	EndIf;
	
EndProcedure

Procedure InstructionsForDebitingNonCashFunds(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	&Ref AS DocumentBasis,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.BankAccount.CashCurrency AS Currency,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.Department AS Department,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	Cash.SumBalance AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(,
	|			AdvanceHolder = &AdvanceHolder
	|			AND Organization = &Organization
	|			AND Currency = &Currency) AS Cash
	|	ON
	|		TRUE
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|");
	
	DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, "Organization, Department, AdvanceHolder, Currency");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Organization", DetailsOfFoundation.Organization);
	Query.SetParameter("Department", DetailsOfFoundation.Department);
	Query.SetParameter("AdvanceHolder", DetailsOfFoundation.AdvanceHolder);
	Query.SetParameter("Currency", DetailsOfFoundation.Currency);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy thanh toán tiền tạm ứng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить авансовый отчет на основании документа %1';
				|en = 'It is not required to enter an expense report based on document %1'; fa = 'It is not required to enter an expense report based on document %1';
				|it = 'Non è necessario inserire la nota spese in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie raportu rozchodów na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı gider raporu girmek gerekli değildir.'"),
			DocumentBasis);
		Raise Text;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			DocumentBasis,
			Undefined, // Status
			Selection.ThereAreErrorsPosted);
		FillPropertyValues(FillingData, Selection);
		
		Selection.Reset();
		While Selection.Next() Do
			NewRow = OtherExpenses.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInApplicationForBusinessTrip(Val DocumentBasis, FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	&Ref                                        AS DocumentBasis,
	|	DocumentData.Organization                    AS Organization,
	|	DocumentData.Employee                      AS AdvanceHolder,
	|	DocumentData.Department                  AS Department,
	|	NOT DocumentData.Posted                    AS ThereAreErrorsPosted,
	|	Cash.IssuancePurpose                    AS CashFlowItem,
	|	ISNULL(Cash.SumBalance, 0)     AS Sum,
	|	DocumentData.DocumentAmount                 AS ApplicationAmount,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)          AS VATRate,
	|	&Currency                                        AS Currency,
	|	FALSE                                           AS Multicurrency
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentData
	|	
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(,
	|			AdvanceHolder = &AdvanceHolder
	|			AND Department = &Department
	|			AND Organization = &Organization
	|			AND Currency = &Currency) AS Cash
	|	ON
	|		TRUE
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, "Organization, Department, Employee, Currency");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Organization", DetailsOfFoundation.Organization);
	Query.SetParameter("Department", DetailsOfFoundation.Department);
	Query.SetParameter("AdvanceHolder", DetailsOfFoundation.Employee);
	Query.SetParameter("Currency", DetailsOfFoundation.Currency);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy thanh toán tiền tạm ứng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить авансовый отчет на основании документа %1';
				|en = 'It is not required to enter an expense report based on document %1'; fa = 'It is not required to enter an expense report based on document %1';
				|it = 'Non è necessario inserire la nota spese in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie raportu rozchodów na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı gider raporu girmek gerekli değildir.'"),
			DocumentBasis);
		Raise Text;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			DocumentBasis,
			Undefined, // Status
			Selection.ThereAreErrorsPosted);
		FillPropertyValues(FillingData, Selection);
		
		OtherExpenses.Load(GetETickets(FillingData,, DocumentBasis).Unload());
		
	EndIf;
	
EndProcedure

Function GetETickets(Val FillingData, IssuanceObjectives = Undefined, Request = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ENDOFPERIOD(DocumentData.Date, DAY) AS Date
	|INTO PreviousReport
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|WHERE
	|	DocumentData.AdvanceHolder = &AdvanceHolder
	|	AND DocumentData.Department = &Department
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	DocumentData.Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ETicketData.Ref AS Ref,
	|	ETicketData.TicketNumber AS TicketNumber,
	|	ETicketData.Date AS Date,
	|	ETicketData.Department AS Department,
	|	PRESENTATION(ETicketData.ServiceType) AS ExternalDocumentName,
	|	ETicketData.TripDetails AS TripDetails,
	|	ETicketData.Currency AS Currency,
	|	ETicketData.CashFlowItem AS CashFlowItem,
	|	ETicketData.CounterpartyCarrier AS CounterpartyCarrier
	|INTO TTETickets
	|FROM
	|	Document.ElectronicTicketTransaction AS ETicketData
	|		LEFT JOIN PreviousReport AS PreviousReport
	|		ON (TRUE)
	|		LEFT JOIN Document.ExpenseReport.OtherExpenses AS ReportData
	|		ON ETicketData.Ref = ReportData.ElectronicTicket
	|			AND (NOT ReportData.Ref = &Ref)
	|WHERE
	|	ETicketData.Employee = &AdvanceHolder
	|	AND ETicketData.Department = &Department
	|	AND ETicketData.Organization = &Organization
	|	AND ETicketData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|	AND ETicketData.Posted
	|	AND NOT ETicketData.DirectWriteOffMethod
	|	AND (ETicketData.CashFlowItem IN (&IssuanceObjectives)
	|			OR &AnyGoals)
	|	AND (ETicketData.Currency = &Currency
	|			OR &Multicurrency)
	|	AND (ETicketData.DocumentBasis IN (&Request)
	|			OR &RequestNotSpecified)
	|	AND ETicketData.ArrivalDate > ISNULL(PreviousReport.Date, DATETIME(1, 1, 1))
	|	AND ETicketData.ArrivalDate <= &ExpenseReportDate
	|	AND ReportData.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.ElectronicTicket AS ElectronicTicket,
	|	MAX(Operations.PrintFormLocalAccounting) AS PrintFormLocalAccounting,
	|	Operations.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	Operations.IncomingDocumentDate AS IncomingDocumentDate,
	|	Operations.ExternalDocumentName AS ExternalDocumentName,
	|	Operations.Department AS Department,
	|	CAST(Operations.Content AS STRING(128)) AS Content,
	|	Operations.Currency AS Currency,
	|	Operations.CashFlowItem AS CashFlowItem,
	|	Operations.VATRate AS VATRate,
	|	Operations.Counterparty AS Counterparty,
	|	SUM(Operations.Sum) AS Sum,
	|	SUM(Operations.VATAmount) AS VATAmount,
	|	SUM(Operations.Sum) AS AmountIncludingVAT
	|FROM
	|	(SELECT
	|		TicketsData.Ref AS ElectronicTicket,
	|		TicketsData.TicketNumber AS IncomingDocumentNumber,
	|		TicketsData.Date AS IncomingDocumentDate,
	|		TicketsData.Department AS Department,
	|		TicketsData.ExternalDocumentName AS ExternalDocumentName,
	|		TicketsData.TripDetails AS Content,
	|		TicketsData.Currency AS Currency,
	|		TicketsData.CashFlowItem AS CashFlowItem,
	|		TicketsData.CounterpartyCarrier AS Counterparty,
	|		CompositionOfOperation.VATRate AS VATRate,
	|		CASE
	|			WHEN CompositionOfOperation.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.Sum
	|			ELSE CompositionOfOperation.Sum
	|		END AS Sum,
	|		CASE
	|			WHEN CompositionOfOperation.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.VATAmount
	|			ELSE CompositionOfOperation.VATAmount
	|		END AS VATAmount,
	|		CompositionOfOperation.VATAmount <> 0 AS PrintFormLocalAccounting
	|	FROM
	|		TTETickets AS TicketsData
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS CompositionOfOperation
	|			ON TicketsData.Ref = CompositionOfOperation.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TicketsData.Ref,
	|		TicketsData.TicketNumber,
	|		TicketsData.Date,
	|		TicketsData.Department,
	|		TicketsData.ExternalDocumentName,
	|		TicketsData.TripDetails,
	|		TicketsData.Currency,
	|		TicketsData.CashFlowItem,
	|		TicketsData.CounterpartyCarrier,
	|		CompositionOfOperation.VATRate,
	|		CASE
	|			WHEN CompositionOfOperation.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.Sum
	|			ELSE CompositionOfOperation.Sum
	|		END,
	|		CASE
	|			WHEN CompositionOfOperation.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.VATAmount
	|			ELSE CompositionOfOperation.VATAmount
	|		END,
	|		CompositionOfOperation.VATAmount <> 0
	|	FROM
	|		TTETickets AS TicketsData
	|			INNER JOIN Document.ElectronicTicketTransaction AS TicketOperationsData
	|			ON TicketsData.Ref = TicketOperationsData.ElectronicTicket
	|				AND (TicketOperationsData.Posted)
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS CompositionOfOperation
	|			ON (TicketOperationsData.Ref = CompositionOfOperation.Ref)) AS Operations
	|
	|GROUP BY
	|	Operations.ElectronicTicket,
	|	Operations.IncomingDocumentNumber,
	|	Operations.Department,
	|	Operations.IncomingDocumentDate,
	|	Operations.ExternalDocumentName,
	|	CAST(Operations.Content AS STRING(128)),
	|	Operations.Currency,
	|	Operations.CashFlowItem,
	|	Operations.VATRate,
	|	Operations.Counterparty
	|
	|HAVING
	|	SUM(Operations.Sum) > 0";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ExpenseReportDate", Date);
	Query.SetParameter("AdvanceHolder", FillingData.AdvanceHolder);
	Query.SetParameter("Department", FillingData.Department);
	Query.SetParameter("Organization", FillingData.Organization);
	Query.SetParameter("IssuanceObjectives", IssuanceObjectives);
	Query.SetParameter("AnyGoals", Not ValueIsFilled(IssuanceObjectives) Or Not IssuanceObjectives.Count());
	Query.SetParameter("Request", Request);
	Query.SetParameter("RequestNotSpecified", Not ValueIsFilled(Request));
	Query.SetParameter("Currency", FillingData.Currency);
	Query.SetParameter("Multicurrency", FillingData.Multicurrency);

	Return Query.Execute();
	
EndFunction

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(Department) Then
		Department = PersonsTM.DivisionOfIndividual(AdvanceHolder);
	EndIf;
	
	If (TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency"))
		And Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("Multicurrency") And FillingData.Multicurrency) Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	Else
		Currency = Undefined;
	EndIf;
	
	If Not GetFunctionalOption("UseExpenseReportStatuses") Then
		Status = Enums.ExpenseReportStatuses.Upholded;
	Else
		Status = Enums.ExpenseReportStatuses.Prepared;
	EndIf;
	
	PriceIncludesVAT = True;
	StructureOfActions = New Structure("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", PriceIncludesVAT));
	BatchProcessingOfTablePartServer.TreatTS(OtherExpenses, StructureOfActions, Undefined);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
EndProcedure

#EndRegion

#Region Other

Procedure GeneratePrimaryDocuments(Cancel)
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	*
	|INTO OtherExpenses
	|FROM
	|	&OtherExpenses AS OtherExpenses
	|";
	
	Query.SetParameter("OtherExpenses", OtherExpenses.Unload());
	Query.Execute();
	
	Query.Text = "
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * LocalCurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * LocalCurrencyExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TTExchangeRatesLocal
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				&Period,
	|				Currency = &LocalAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND LocalCurrencyExchangeRate.CourseNumerator <> 0
	|;
	|SELECT
	|	OtherExpenses.IncomingDocumentNumber,
	|	OtherExpenses.IncomingDocumentDate,
	|	OtherExpenses.Counterparty,
	|	OtherExpenses.Currency,
	|	SUM(OtherExpenses.Sum) AS DocumentAmount,
	|	SUM(OtherExpenses.Sum * ISNULL(TableExchangeRatesLocalAmount.ConversionFactor_, 0)) AS SumCompl
	|INTO PrimaryDocumentsSummary
	|FROM
	|	OtherExpenses AS OtherExpenses
	|		LEFT JOIN TTExchangeRatesLocal AS TableExchangeRatesLocalAmount
	|		ON TableExchangeRatesLocalAmount.Currency = OtherExpenses.Currency
	|WHERE
	|	(OtherExpenses.InvIsSubmitted
	|	OR OtherExpenses.PrintFormLocalAccounting)
	|	AND NOT OtherExpenses.Canceled
	|	AND OtherExpenses.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|GROUP BY
	|	OtherExpenses.IncomingDocumentNumber,
	|	OtherExpenses.IncomingDocumentDate,
	|	OtherExpenses.Counterparty,
	|	OtherExpenses.Currency
	|;
	|
	|SELECT
	|	PrimaryDocumentsSummary.IncomingDocumentNumber,
	|	PrimaryDocumentsSummary.IncomingDocumentDate,
	|	PrimaryDocumentsSummary.Counterparty,
	|	PrimaryDocumentsSummary.Currency,
	|	PrimaryDocumentsSummary.DocumentAmount,
	|	PrimaryDocumentsSummary.SumCompl,
	|	PrimaryReportDocument.Ref AS SourceDocument,
	|	CASE
	|		WHEN PrimaryReportDocument.Ref IS NULL THEN
	|			1 // Create
	|		WHEN PrimaryDocumentsSummary.DocumentAmount <> PrimaryReportDocument.DocumentAmount
	|			OR PrimaryDocumentsSummary.SumCompl <> PrimaryReportDocument.SumCompl THEN
	|			2 // Refresh
	|		ELSE
	|			3 // Leave it as it is
	|	END AS ProcessingStatus
	|FROM
	|	PrimaryDocumentsSummary
	|	
	|	LEFT JOIN
	|		Document.SourceDocument AS PrimaryReportDocument
	|		
	|		INNER JOIN
	|			Document.ExpenseReport.OtherExpenses AS ThisAdvanceReport
	|		ON
	|			ThisAdvanceReport.SourceDocument = PrimaryReportDocument.Ref
	|			AND ThisAdvanceReport.Ref = &Ref
	|	ON
	|		PrimaryReportDocument.IncomingDocumentNumber = PrimaryDocumentsSummary.IncomingDocumentNumber
	|		AND PrimaryReportDocument.IncomingDocumentDate = PrimaryDocumentsSummary.IncomingDocumentDate
	|		AND PrimaryReportDocument.Counterparty = PrimaryDocumentsSummary.Counterparty
	|		AND PrimaryReportDocument.Currency = PrimaryDocumentsSummary.Currency
	|		AND PrimaryReportDocument.Organization = &Organization
	|		AND PrimaryReportDocument.Date = &Period
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Date);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	
	PrimaryDocumentsNewComposition = New Array;
	
	Selection = Result[2].Select();
	
	ArrayOfDataPropertiesToFillIn = New Array;
	ArrayOfDataPropertiesToFillIn.Add("IncomingDocumentNumber");
	ArrayOfDataPropertiesToFillIn.Add("IncomingDocumentDate");
	ArrayOfDataPropertiesToFillIn.Add("Counterparty");
	ArrayOfDataPropertiesToFillIn.Add("Currency");
	ArrayOfDataPropertiesToFillIn.Add("DocumentAmount");
	ArrayOfDataPropertiesToFillIn.Add("SumCompl");
	PropertiesForFillingInPrimaryDocument = StrConcat(ArrayOfDataPropertiesToFillIn, ",");
	
	BeginTransaction();
	
	Try
		
		MessageText = NStr("vi = 'Không thể tạo các chứng từ sơ cấp';
							|ru = 'Не удалось сформировать первичные документы';
							|en = 'Cannot generate source documents'; fa = 'Cannot generate source documents';
							|it = 'Cannot generate source documents';
							|pl = 'Cannot generate source documents';
							|tr = 'Birincil belgeler oluşturulamadı'");
		While Selection.Next() Do
			
			If Selection.ProcessingStatus = 1 And Not DeletionMark Then
				
				DocumentObject = Documents.SourceDocument.CreateDocument();
					
				AdvanceReportData = New Structure(PropertiesForFillingInPrimaryDocument);
				FillPropertyValues(AdvanceReportData, Selection);
				
				AdvanceReportData.Insert("Organization", Organization);
				AdvanceReportData.Insert("Department", Department);
				AdvanceReportData.Insert("Date", Date);
				AdvanceReportData.Insert("VATTaxation", PurchaseForActivity);
				AdvanceReportData.Insert("SourceDocumentType", Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder);
				
				DataToFill = New Structure("AdvanceReportData", AdvanceReportData);
				DocumentObject.Fill(DataToFill);
				
				MessageText = StrTemplate(NStr("vi = 'Không thể ghi lại %1';
												|ru = 'Не удалось записать %1';
												|en = 'Cannot save %1'; fa = 'Cannot save %1';
												|it = 'Cannot save %1';
												|pl = 'Cannot save %1';
												|tr = '%1 yazılamadı'"), DocumentObject);
				DocumentObject.Write(DocumentWriteMode.Posting);
				
				PrimaryDocumentsNewComposition.Add(DocumentObject.Ref);
				
			ElsIf Selection.ProcessingStatus = 2 Then
				
				DocumentObject = Selection.SourceDocument.GetObject();
				
				MessageText =
						StrTemplate(NStr("vi = '%1 đang trong quá trình chỉnh sửa và không thể thay đổi';
										|ru = '%1 находится в процессе редактирования и не может быть изменен';
										|en = '%1 is being edited and cannot be changed'; fa = '%1 is being edited and cannot be changed';
										|it = '%1 is being edited and cannot be changed';
										|pl = '%1 is being edited and cannot be changed';
										|tr = '%1 düzenleme sürecindedir ve değiştirilemez'"), DocumentObject);
				DocumentObject.Lock();
				
				DocumentObject.DocumentAmount = Selection.DocumentAmount;
				DocumentObject.SumCompl = Selection.SumCompl;
				
				MessageText = StrTemplate(NStr("vi = 'Không thể ghi lại %1';
												|ru = 'Не удалось записать %1';
												|en = 'Cannot save %1'; fa = 'Cannot save %1';
												|it = 'Cannot save %1';
												|pl = 'Cannot save %1';
												|tr = '%1 yazılamadı'"), DocumentObject);
				DocumentObject.Write(DocumentWriteMode.Posting);
				
				PrimaryDocumentsNewComposition.Add(DocumentObject.Ref);
			Else
				
				PrimaryDocumentsNewComposition.Add(Selection.SourceDocument);
			EndIf;
		EndDo;
		
		CommitTransaction();
	
	Except
	
		RollbackTransaction();
		ErrorDetailedInfo = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		CommonClientServer.MessageToUser(
			StrTemplate(NStr("vi = '%1. Chi tiết lỗi: %2';
							|ru = '%1. Подробности ошибки: %2';
							|en = '%1. Error details: %2'; fa = '%1. Error details: %2';
							|it = '%1. Error details: %2';
							|pl = '%1. Error details: %2';
							|tr = '%1. Hata ayrıntıları: %2'"), MessageText, ErrorDetailedInfo),,,, Cancel);
		Return;
	
	EndTry;
		
		Query.Text = "
		|SELECT
		|	ThisAdvanceReport.SourceDocument AS Ref
		|FROM
		|	Document.ExpenseReport.OtherExpenses AS ThisAdvanceReport
		|WHERE
		|	NOT ThisAdvanceReport.SourceDocument IN (&PrimaryDocumentsNewComposition)
		|	AND ThisAdvanceReport.Ref = &Ref
		|;
		|
		|SELECT
		|	*,
		|	DocumentSourceDocument.Ref AS SourceDocument
		|FROM
		|	OtherExpenses AS OtherExpenses
		|	
		|	LEFT JOIN
		|		Document.SourceDocument AS DocumentSourceDocument
		|	ON
		|		DocumentSourceDocument.IncomingDocumentNumber = OtherExpenses.IncomingDocumentNumber
		|		AND DocumentSourceDocument.IncomingDocumentDate = OtherExpenses.IncomingDocumentDate
		|		AND DocumentSourceDocument.Counterparty = OtherExpenses.Counterparty
		|		AND DocumentSourceDocument.Currency = OtherExpenses.Currency
		|		AND DocumentSourceDocument.Organization = &Organization
		|		AND (OtherExpenses.InvIsSubmitted
		|			OR OtherExpenses.PrintFormLocalAccounting)
		|		AND DocumentSourceDocument.Ref IN (&PrimaryDocumentsNewComposition)
		|		AND DocumentSourceDocument.Date = &Period
		|";
		
		Query.SetParameter("PrimaryDocumentsNewComposition", PrimaryDocumentsNewComposition);
		
		Result = Query.ExecuteBatchWithIntermediateData();
		
		Selection = Result[0].Select();
		
		BeginTransaction();
		
		Try
			
			MessageText = NStr("vi = 'Không thể tạo các chứng từ sơ cấp';
								|ru = 'Не удалось сформировать первичные документы';
								|en = 'Cannot generate source documents'; fa = 'Cannot generate source documents';
								|it = 'Cannot generate source documents';
								|pl = 'Cannot generate source documents';
								|tr = 'Birincil belgeler oluşturulamadı'");
			While Selection.Next() Do
				If ValueIsFilled(Selection.Ref) Then
					
					DocumentObject = Selection.Ref.GetObject();
					
					MessageText =
							StrTemplate(NStr("vi = '%1 đang trong quá trình chỉnh sửa và không thể thay đổi';
											|ru = '%1 находится в процессе редактирования и не может быть изменен';
											|en = '%1 is being edited and cannot be changed'; fa = '%1 is being edited and cannot be changed';
											|it = '%1 is being edited and cannot be changed';
											|pl = '%1 is being edited and cannot be changed';
											|tr = '%1 düzenleme sürecindedir ve değiştirilemez'"), DocumentObject);
					DocumentObject.Lock();
					
					MessageText = StrTemplate(NStr("vi = 'Không thể hủy bỏ %1';
													|ru = 'Не удалось отменить %1';
													|en = 'Cannot cancel %1'; fa = 'Cannot cancel %1';
													|it = 'Cannot cancel %1';
													|pl = 'Cannot cancel %1';
													|tr = '%1 iptal edilemedi'"), DocumentObject);
					DocumentObject.SetDeletionMark(True);
					
				EndIf;
			EndDo;
			
			CommitTransaction();
			
		Except
	
			RollbackTransaction();
			ErrorDetailedInfo = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
			CommonClientServer.MessageToUser(
				StrTemplate(NStr("vi = '%1. Chi tiết lỗi: %2';
								|ru = '%1. Подробности ошибки: %2';
								|en = '%1. Error details: %2'; fa = '%1. Error details: %2';
								|it = '%1. Error details: %2';
								|pl = '%1. Error details: %2';
								|tr = '%1. Hata ayrıntıları: %2'"), MessageText, ErrorDetailedInfo),,,, Cancel);
			Return;
	
		EndTry;
	
	SetPrivilegedMode(False);
	
	OtherExpenses.Load(Result[1].Unload());
	
EndProcedure

Procedure UpdatePrimaryDocuments(WriteMode, Cancel)
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark <> &DeletionMark AS ChangeDeletionMark,
	|	DocumentData.Posted <> &Posted AND NOT (DocumentData.DeletionMark <> &DeletionMark) AS ChangeRecordingMode
	|FROM
	|	Document.SourceDocument AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&PrimaryReportDocuments)
	|	AND (DocumentData.DeletionMark <> &DeletionMark
	|		OR DocumentData.Posted <> &Posted AND &PotentialRegimeChange)
	|";
	
	Query.SetParameter("PrimaryReportDocuments", OtherExpenses.UnloadColumn("SourceDocument"));
	Query.SetParameter("DeletionMark", DeletionMark);
	Query.SetParameter("Posted", WriteMode = DocumentWriteMode.Posting);
	Query.SetParameter("PotentialRegimeChange",
		WriteMode = DocumentWriteMode.Posting Or WriteMode = DocumentWriteMode.UndoPosting);
		
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject();
		
		Try
			DocumentObject.Lock();
		Except
			MessageText =
				StrTemplate(NStr("vi = '%1 đang trong quá trình chỉnh sửa và không thể thay đổi.';
								|ru = '%1 находится в процессе редактирования и не может быть изменен.';
								|en = '%1 is being edited and cannot be changed.'; fa = '%1 is being edited and cannot be changed.';
								|it = '%1 si trova in fase di modifica e non può esere modificato.';
								|pl = '%1 jest w trakcie edycji i nie można go zmienić.';
								|tr = '%1 düzenleme sürecinde bulunmakta ve değiştirilemez.'"), DocumentObject);
			CommonClientServer.MessageToUser(MessageText,,,, Cancel);
			Return;
		EndTry;
		
		If Selection.ChangeRecordingMode Then
			DocumentObject.Write(WriteMode);
		EndIf;
		
		If Selection.ChangeDeletionMark Then
			DocumentObject.SetDeletionMark(DeletionMark);
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

Procedure CheckDuplicatesOfVATAccountingForPrimaryDocuments(Cancel)
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	*
	|INTO DocumentData
	|FROM
	|	&OtherExpenses AS OtherExpenses
	|";
	
	Query.SetParameter("OtherExpenses", OtherExpenses.Unload());
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	DataToCheck.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DataToCheck.IncomingDocumentDate AS IncomingDocumentDate,
	|	MAX(DataToCheck.LineNumber) AS LineNumber
	|FROM
	|	(SELECT
	|		1 AS Active,
	|		DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|		DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|		DocumentData.Counterparty AS Counterparty,
	|		MAX(DocumentData.LineNumber) AS LineNumber
	|	FROM
	|		DocumentData AS DocumentData
	|	WHERE
	|		DocumentData.InvIsSubmitted
	|	
	|	GROUP BY
	|		DocumentData.IncomingDocumentNumber,
	|		DocumentData.IncomingDocumentDate,
	|		DocumentData.Counterparty
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		-1,
	|		DocumentData.IncomingDocumentNumber,
	|		DocumentData.IncomingDocumentDate,
	|		DocumentData.Counterparty,
	|		MAX(DocumentData.LineNumber)
	|	FROM
	|		DocumentData AS DocumentData
	|	WHERE
	|		DocumentData.PrintFormLocalAccounting
	|	
	|	GROUP BY
	|		DocumentData.IncomingDocumentNumber,
	|		DocumentData.IncomingDocumentDate,
	|		DocumentData.Counterparty) AS DataToCheck
	|
	|GROUP BY
	|	DataToCheck.IncomingDocumentNumber,
	|	DataToCheck.IncomingDocumentDate,
	|	DataToCheck.Counterparty
	|
	|HAVING
	|	SUM(DataToCheck.Active) = 0";
	
	Query.SetParameter("InsignificantVATRates", VATAccountingERPInternalClientServerCached.ListOfInsignificantBets());
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		ErrorText = StrTemplate(
			NStr("vi = 'Đối với chứng từ số %1 ngày %2, một số tùy chọn khấu trừ Thuế GTGT được chỉ định đồng thời';
				|ru = 'Для документа №%1 от %2 указано одновременно несколько вариантов принятия к вычету НДС';
				|en = 'Several options of accepting VAT for deduction are specified for document No. %1 dated %2'; fa = 'Several options of accepting VAT for deduction are specified for document No. %1 dated %2';
				|it = 'Several options of accepting VAT for deduction are specified for document No. %1 dated %2';
				|pl = 'Several options of accepting VAT for deduction are specified for document No. %1 dated %2';
				|tr = '%1 sayılı %2 tarihli belge için birden fazla KDV indirimi seçeneği belirtilmiştir'"),
			Selection.IncomingDocumentNumber, Format(Selection.IncomingDocumentDate, "DLF=D"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("OtherExpenses", Selection.LineNumber, "VATAccountingMethod"),,
			Cancel);
	EndDo;
	
EndProcedure

Procedure CheckAvailabilityOfIdenticalExpenseReport(Cancel)
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	Document.Ref AS Ref
	|FROM
	|	Document.ExpenseReport AS Document
	|WHERE
	|	Document.Posted
	|	AND Document.Organization = &Organization
	|	AND Document.Department = &Department
	|	AND Document.AdvanceHolder = &AdvanceHolder
	|	AND Document.Date = &Date
	|	AND Document.Ref <> &Ref";
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("AdvanceHolder", AdvanceHolder);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Common.MessageToUser(
			StrTemplate(
				NStr("vi = 'Đã tồn tại %1 theo người nhận tạm ứng %2 của doanh nghiệp %3 và bộ phận %4 vào ngày %5.';
					|ru = 'Уже существует %1 по подотчетному лицу %2 организации %3 и подразделению %4 на дату %5.';
					|en = 'There is already %1 for advance holder %2 of the %3 company and the %4 business unit as of %5.'; fa = 'There is already %1 for advance holder %2 of the %3 company and the %4 business unit as of %5.';
					|it = 'Уже существует %1 по подотчетному лицу %2 организации %3 и подразделению %4 на дату %5.';
					|pl = 'There is already %1 for advance holder %2 of the %3 company and the %4 business unit as of %5.';
					|tr = '%1, %5 tarihinde kuruluşun %3 ve departmanın %4 raporlayan kişisi %2 için zaten mevcut.'"),
				Selection.Ref,
				AdvanceHolder,
				Organization,
				Department,
				Date),,,,Cancel);
	EndIf;
EndProcedure

#EndRegion

#EndRegion

#EndIf
