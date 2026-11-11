#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.ApplicationForBusinessTrip") Then
		Documents.ApplicationForBusinessTrip.FillInUsingBaseDocument(ThisObject, FillingData);
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	BookingLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	FillParameters = Documents.ElectronicTicketTransaction.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	BookingLocalization.OnCopy(ThisObject, CopiedObject);
	
	ExpenseReport 			= Documents.ExpenseReport.EmptyRef();
	DocumentID 	= "";
	SmartwayID	= 0;
	
	If ThisIsElectronicTicket() Then
	
		TripDetails			= "";
		TicketNumber				= "";
		PostingDate			= Undefined;
		ArrivalDate			= Undefined;
		
		NonCopyableTypesOfOperations = New Array;
		NonCopyableTypesOfOperations.Add(Enums.TypesOfTicketOperations.ExtraPay);
		NonCopyableTypesOfOperations.Add(Enums.TypesOfTicketOperations.Return);
		LinesToDelete = New Array;
		
		For Each CompositionRow In Operations Do
			If NonCopyableTypesOfOperations.Find(CompositionRow.OperationType) = Undefined Then
				Continue;
			EndIf;
			LinesToDelete.Add(CompositionRow);
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			Operations.Delete(RowToDelete);
		EndDo;
		
		If Not DirectWriteOffMethod Then
			AcceptVATForDeduction = False;
		EndIf;
		
		If Not AcceptVATForDeduction Then
			TransactionKindCode = "";
		EndIf;
		
	EndIf;
	
	FillParameters = Documents.ElectronicTicketTransaction.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If BusinessOperation <> Enums.BusinessTransactions.BookingViaAgent Then
		AttributesNotToCheck.Add("Agent");
		AttributesNotToCheck.Add("CounterpartyAgent");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.BookingViaAdvanceHolder Then
		AttributesNotToCheck.Add("AdvanceHolder");
		AttributesNotToCheck.Add("AccountablePersonDepartment");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.BookingViaAgent
		And BusinessOperation <> Enums.BusinessTransactions.BookingFromVendor Then
		AttributesNotToCheck.Add("Contract");
	EndIf;
	
	If DirectWriteOffMethod Then
		AttributesNotToCheck.Add("Employee");
	Else
		AttributesNotToCheck.Add("ExpenseItem");AttributesNotToCheck.Add("PurchaseForActivity");
		AttributesNotToCheck.Add("PurchaseForActivity");
	EndIf;
	
	If Not AcceptVATForDeduction Then
		AttributesNotToCheck.Add("TransactionKindCode");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ArrayOfManualVerificationDetails = New Array;
	ArrayOfManualVerificationDetails.Add("Operations.ExpenseItem");
	ArrayOfManualVerificationDetails.Add("Operations.DimensionOfExpenses");
	ArrayOfManualVerificationDetails.Add("Operations.AssetsLiabilitiesDimension");
	
	For Each Attribute In ArrayOfManualVerificationDetails Do
		AttributesNotToCheck.Add(Attribute);
	EndDo;
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	TabularSection = Metadata().TabularSections.Find("Operations");
	Attribute = TabularSection.Attributes.Find("ExpenseItem");
	
	ReturnOperation = Enums.TypesOfTicketOperations.Return;
	
	For Each TSRow In Operations Do
		
		If TSRow.OperationType = ReturnOperation Then
			
			If TSRow.PenaltyAmount <> 0 And Not ValueIsFilled(TSRow["ExpenseItem"]) Then
		
				Field = CommonClientServer.PathToTabularSection("Operations", TSRow.LineNumber, "ExpenseItem");
				Common.MessageToUser(
					StrTemplate(NStr("vi = 'Chưa điền trường ""%1"" trong hàng %2 của danh sách ""%3""';
									|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
									|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
									|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
									|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
									|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
						Attribute.Synonym, TSRow.LineNumber, TabularSection.Synonym),
					DataKey,
					Field,
					"Object",
					Cancel);
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Attributes = New Structure("Operations", "ExpenseItem,DimensionOfExpenses");
	ChartsOfCharacteristicTypes.ExpenseItems.CheckAnalystCompletion(ThisObject, Attributes, AttributesNotToCheck, Cancel);

	ChartsOfCharacteristicTypes.ExpenseItems.CheckAnalystCompletion(ThisObject, "ExpenseItem,DimensionOfExpenses", AttributesNotToCheck, Cancel);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject, 
		PurchaseForActivity, 
		CheckParameters, 
		Cancel);
	
	CheckTravelDates(Cancel);
	
	CheckingPossibilityOfOperation(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	BookingLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		CheckPossibilityOfCancelingPurchaseAndAdditionalPayment(Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
	ThisIsElectronicTicket = ThisIsElectronicTicket();
	
	TSRow = Operations.Find(Enums.TypesOfTicketOperations.Purchase);
	If TSRow <> Undefined Then
		VATRate = TSRow.VATRate;
	EndIf;
	
	ElectronicTicketContainsOfOperationsLines = Documents.ElectronicTicketTransaction.ElectronicTicketContainsOfOperationsLines(ThisObject);
	If ElectronicTicketContainsOfOperationsLines Then
		PurchaseOperationLines = Operations.FindRows(New Structure("OperationType", Enums.TypesOfTicketOperations.Purchase));
		For Each PurchaseOperation In PurchaseOperationLines Do
			PurchaseOperation.Date = Date;
		EndDo;
	EndIf;
	
	// Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ElectronicTicketTransaction.AccountingAccountSettings_());
		
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ElectronicTicketTransaction.AccountSettingsForDirectWriteOffMethod());
	TMCommonUse.FillInDocumentIDs(ThisObject, "Operations");
	
	For Each TSRow In Operations Do
		
		If TSRow.PenaltyAmount <> 0 And Not ValueIsFilled(TSRow.RowIDOfFine) Then
			TSRow.RowIDOfFine = String(New UUID);
		EndIf;
		
		If Not ElectronicTicketContainsOfOperationsLines And Not TSRow.Date = BegOfDay(Date) Then
			TSRow.Date = Date;
		EndIf;
		
	EndDo;
	
	If WriteMode <> DocumentWriteMode.Write Then
		CheckDataModificationBan(Cancel);
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	If ThisIsElectronicTicket Then
		SeparateOfOperationsFromElectronicTicket();
	EndIf;
	
	CalculateDocumentAmount(ThisIsElectronicTicket);
	
	If ThisIsElectronicTicket Then
		State = Documents.ElectronicTicketTransaction.NewStateOfTicket(Ref, ThisObject);
	EndIf;
	
	RegistrationParameters = Documents.ElectronicTicketTransaction.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	BookingLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If ThisIsElectronicTicket And IsNew() Then
		AdditionalProperties.Insert("SkipRegistrationInNonOperationalQueue");
	EndIf;
	
	AdditionalProperties.Insert("ExpenseReport", Common.ObjectAttributeValue(Ref, "ExpenseReport"));
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.Property("RecordingWithoutRegisteringRecords") Then
		Return;
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ElectronicTicketTransaction.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	BookingLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RecordTicketOperationsWhenRecordingConducting(True, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ElectronicTicketTransaction.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	BookingLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If ValueIsFilled(ExpenseReport)
		And Not AdditionalProperties.Property("DoNotUpdateAdvanceReport") Then
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(ExpenseReport, "DocumentsRegistry");
		InformationRegisters.DocumentsRegistry.WriteData(TablesForRegisteredRecords, ExpenseReport, Undefined, Cancel);
	EndIf;
	
	If AdditionalProperties.Property("ExpenseReport")
		And Not AdditionalProperties.Property("DoNotUpdateAdvanceReport")
		And ValueIsFilled(AdditionalProperties.ExpenseReport)
		And AdditionalProperties.ExpenseReport <> ExpenseReport Then
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
			AdditionalProperties.ExpenseReport, "DocumentsRegistry");
		InformationRegisters.DocumentsRegistry.WriteData(
			TablesForRegisteredRecords,
			AdditionalProperties.ExpenseReport,
			Undefined,
			Cancel);
	EndIf;
	
	BookingLocalization.OnWrite(ThisObject, Cancel);
	
	RecordTicketOperationsWhenRecordingConducting(
		AdditionalProperties.WriteMode = DocumentWriteMode.Write And Not Posted, Cancel);
	
	CreateDocumentTasksWhenRecording();
	
EndProcedure

Procedure BeforeDelete(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	BookingLocalization.BeforeDeleteRow(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

Procedure CalculateDocumentAmount(ThisIsElectronicTicket)
	
	CumulativeAmountToIssue = 0;
	AmountOfDocumentIsCumulative = 0;
	CumulativeVATAmount = 0;
	CurrentTotal = 0;
	For Each TSRow In Operations Do
		
		PenaltyAmount = 0;
		If TSRow.OperationType = Enums.TypesOfTicketOperations.Purchase
			Or TSRow.OperationType = Enums.TypesOfTicketOperations.ExtraPay Then
			
			TransactionAmount = TSRow.Sum;
			TransactionVATAmount = TSRow.VATAmount;
			CurrentTotal = CurrentTotal + TSRow.Sum;
			TSRow.AmountTotal = CurrentTotal;
			CumulativeAmountToIssue = CumulativeAmountToIssue + TransactionAmount;
			
		ElsIf TSRow.OperationType = Enums.TypesOfTicketOperations.Return Then
			
			If ThisIsElectronicTicket Then
				TransactionAmount = -TSRow.Sum;
				TransactionVATAmount = -TSRow.VATAmount;
				PenaltyAmount = TSRow.PenaltyAmount;
				CumulativeAmountToIssue = CumulativeAmountToIssue + TransactionAmount;
			Else
				TransactionAmount = TSRow.Sum;
				TransactionVATAmount = TSRow.VATAmount;
				CumulativeAmountToIssue = CumulativeAmountToIssue - TransactionAmount;
			EndIf;
			
		EndIf;
		
		AmountOfDocumentIsCumulative = AmountOfDocumentIsCumulative + TransactionAmount + PenaltyAmount;
		CumulativeVATAmount = CumulativeVATAmount + TransactionVATAmount;
		
	EndDo;
	
	AmountForIssue = CumulativeAmountToIssue;
	DocumentAmount = AmountOfDocumentIsCumulative;
	VATAmount = CumulativeVATAmount;
	
EndProcedure

Procedure CheckingPossibilityOfOperation(Cancel)
	
	If ThisIsElectronicTicket() Then
		Return;
	EndIf;
	
	If Not Common.ObjectAttributeValue(ElectronicTicket, "Posted") Then
		
		Cancel = True;
		Common.MessageToUser(
					StrTemplate(NStr("vi = 'Không thể thực hiện thao tác %1, bởi vì chưa xác nhận vé điện tử';
									|ru = 'Невозможно провести операцию %1, т.к. не проведен электронный билет';
									|en = 'Cannot post the ""%1"" transaction as the electronic ticket is not posted'; fa = 'Cannot post the ""%1"" transaction as the electronic ticket is not posted';
									|it = 'Cannot post the ""%1"" transaction as the electronic ticket is not posted';
									|pl = 'Cannot post the ""%1"" transaction as the electronic ticket is not posted';
									|tr = 'Elektronik bilet işlenmediği için %1işlemi gerçekleştirilemiyor.'"), Ref),
					Ref,
					"ElectroncTicket",
					"Object",
					Cancel);
		
	EndIf;
	
EndProcedure

Procedure RecordTicketOperationsWhenRecordingConducting(RecordOfOperations, Cancel)
	
	If AdditionalProperties.Property("ElectronicTicketOperations") And RecordOfOperations Then
		For Each ElectronicTicketOperation In AdditionalProperties.ElectronicTicketOperations.Operations Do
			
			Try
				ElectronicTicketOperation.Write(AdditionalProperties.WriteMode);
			Except
				Cancel = True;
				Raise StrTemplate(NStr("vi = 'Không thể ghi lại giao dịch vé điện tử do %1';
										|ru = 'Не удалось записать операцию электронного билета по причине %1';
										|en = 'Cannot save the electronic ticket transaction. Reason: %1'; fa = 'Cannot save the electronic ticket transaction. Reason: %1';
										|it = 'Cannot save the electronic ticket transaction. Reason: %1';
										|pl = 'Cannot save the electronic ticket transaction. Reason: %1';
										|tr = 'Elektronik bilet işlemi %1den dolayı kaydedilemedi'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
			
		EndDo;
	EndIf;
	
EndProcedure

Procedure CheckPossibilityOfCancelingPurchaseAndAdditionalPayment(Cancel)
	
	If OperationType = Enums.TypesOfTicketOperations.ExtraPay Then
	
		TicketOperations = Documents.ElectronicTicketTransaction.ElectronicTicketOperations(ElectronicTicket,,Ref, True);
		AmountsByVATRates = TicketOperations.Copy(New Structure("Posted", True), "VATRate,CalculatedAmount");
		AmountsByVATRates.GroupBy("VATRate", "CalculatedAmount");
		
		For Each RateRow In AmountsByVATRates Do
			If RateRow.CalculatedAmount < 0 Then
				Cancel = True;
				MessageText =
				NStr("vi = 'Không thể hủy bỏ %1, bởi vì khoản phụ thu này được trả lại';
					|ru = 'Невозможно отменить %1, т.к. данная доплата возвращена';
					|en = 'Cannot cancel %1 as this extra pay is refunded'; fa = 'Cannot cancel %1 as this extra pay is refunded';
					|it = 'Cannot cancel %1 as this extra pay is refunded';
					|pl = 'Cannot cancel %1 as this extra pay is refunded';
					|tr = '%1iptal edilemez, çünkü bu ek ödeme iade edilmiştir.'");
				Common.MessageToUser(StrTemplate(MessageText, String(Ref)),,,, Cancel);
			EndIf;
		EndDo;
	
	EndIf;
	
	If ThisIsElectronicTicket() Then
		TicketOperations = Documents.ElectronicTicketTransaction.ElectronicTicketOperations(Ref,,Ref);
		PerformedOfOperations = TicketOperations.FindRows(New Structure("Posted", True));
		If PerformedOfOperations.Count() Then
			Cancel = True;
			MessageText =
			NStr("vi = 'Không thể hủy bỏ %1, bởi vì theo nó có các giao dịch';
				|ru = 'Невозможно отменить %1, т.к. по нему имеются операции';
				|en = 'Cannot cancel %1 as it has transactions'; fa = 'Cannot cancel %1 as it has transactions';
				|it = 'Cannot cancel %1 as it has transactions';
				|pl = 'Cannot cancel %1 as it has transactions';
				|tr = '%1iptal edilemez, çünkü bu belgeye bağlı işlemler mevcut.'");
			Common.MessageToUser(StrTemplate(MessageText, String(Ref)),,,, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Function ThisIsElectronicTicket()
	Return Not ValueIsFilled(ElectronicTicket);
EndFunction

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	If Not GetFunctionalOption("UseContractsWithVendors") Then
		If TypeOf(FillingData) = Type("Structure") Then
			FillingData.Insert("BusinessOperation",
				Enums.BusinessTransactions.BookingViaAdvanceHolder);
		Else
			BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
			FillOutElectronicTicketOperation(FillingData);
	EndIf;
	
EndProcedure

Procedure CheckDataModificationBan(Cancel)
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	
	CheckedAttributes = New Array;
	CheckedAttributes.Add("Date");
	
	If ThisIsElectronicTicket() Then
		CheckedAttributes.Add("ArrivalDate");
	EndIf;
	
	AttributesNotToCheck = New Structure;
	For Each Attribute In Metadata().Attributes Do
		If CheckedAttributes.Find(Attribute.Name) = Undefined Then
			AttributesNotToCheck.Insert(Attribute.Name);
		EndIf;
	EndDo;
	
	UnverifiableTableParts = New Structure;
	UnverifiableTableParts.Insert("AdditionalAttributes");
	UnverifiableTableParts.Insert("Fees");
	
	DocumentChanges = TMCommonUse.DocumentChanges(ThisObject, AttributesNotToCheck, UnverifiableTableParts);
	
	If DocumentChanges.Property("Attributes") Then
		For Each AttributeChange In DocumentChanges.Attributes Do
			
			If ValueIsFilled(AttributeChange.PreviousValue2) Then
				NewRow = DataToCheck.Add();
				NewRow.Date   = AttributeChange.PreviousValue2;
				NewRow.Section = "ExpenseReports";
				NewRow.Object = Organization;
				
				NewRow = DataToCheck.Add();
				NewRow.Date   = AttributeChange.PreviousValue2;
				NewRow.Section = "FinancialOutline";
				NewRow.Object = Organization;
			EndIf;
			
			If ValueIsFilled(AttributeChange.NewValue) Then
				NewRow = DataToCheck.Add();
				NewRow.Date   = AttributeChange.NewValue;
				NewRow.Section = "ExpenseReports";
				NewRow.Object = Organization;
				
				NewRow = DataToCheck.Add();
				NewRow.Date   = AttributeChange.NewValue;
				NewRow.Section = "FinancialOutline";
				NewRow.Object = Organization;
			EndIf;
		EndDo;
	EndIf;
	
	If DocumentChanges.Property("TabularSections") And DocumentChanges.TabularSections.Property("Operations") Then
		For Each ChangingOperation In DocumentChanges.TabularSections.Operations Do
			If ValueIsFilled(ChangingOperation.Date) Then
				NewRow = DataToCheck.Add();
				NewRow.Date   = ChangingOperation.Date;
				NewRow.Section = "ExpenseReports";
				NewRow.Object = Organization;
				
				NewRow = DataToCheck.Add();
				NewRow.Date   = ChangingOperation.Date;
				NewRow.Section = "FinancialOutline";
				NewRow.Object = Organization;
			EndIf;
		EndDo;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("NewVersion", True);
	DataDetails.Insert("Data",      ThisObject);
	
	ErrorDescription = "";
	If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

Procedure CheckTravelDates(Cancel)

	If ArrivalDate < PostingDate
		And PostingDate - ArrivalDate >= 90000 Then
		
		MessageText =
			NStr("vi = 'Giá trị trong trường ""Ngày đến"" không thể nhỏ hơn giá trị ""Ngày gửi"" nhiều hơn 25 giờ';
				|ru = 'Значение в поле ""Дата прибытия"" не может быть меньше значения ""Дата отправления"" более, чем на 25 часов';
				|en = '""Arrival date"" field value cannot be less than the ""Departure date"" value by more than 25 hours'; fa = '""Arrival date"" field value cannot be less than the ""Departure date"" value by more than 25 hours';
				|it = '""Arrival date"" field value cannot be less than the ""Departure date"" value by more than 25 hours';
				|pl = '""Arrival date"" field value cannot be less than the ""Departure date"" value by more than 25 hours';
				|tr = '""Varış tarihi"" alanındaki değer, ""Kalkış tarihi"" değerinden 25 saatten daha fazla geride olamaz.'");
		Common.MessageToUser(MessageText, Ref, "ArrivalDate", "Object", Cancel);
	
	EndIf;
	
EndProcedure

Procedure FillOutElectronicTicketOperation(DataToFill)
	
	If DataToFill.Property("DataForCreatingTicketOperation") Then
		
		KeyAttributes =
			StrConcat(Documents.ElectronicTicketTransaction.KeyDetailsOfElectronicTicket(False), ",");
			
		DataForCreatingTicketOperation = DataToFill.DataForCreatingTicketOperation;
		
		ETicketData = DataForCreatingTicketOperation.ETicketData;
		If ETicketData = Undefined Then
			ETicketData = Common.ObjectAttributesValues(ElectronicTicket, KeyAttributes);
		EndIf;
		
		OperationDescription = DataForCreatingTicketOperation.OperationDescription;
		
		FillPropertyValues(ThisObject, ETicketData, KeyAttributes);
		FillPropertyValues(ThisObject, OperationDescription);
		TicketDate = ETicketData.Date;
		
		If Not DataForCreatingTicketOperation.ThisIsTicketSplit Then
			Date = Undefined;
		EndIf;
		
		If OperationDescription.ThisIsFullReturn Then
			ProcessFullReturn();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ProcessFullReturn()
	
	Query = New Query;
	Query.SetParameter("ElectronicTicket", ElectronicTicket);
	Query.SetParameter("CurrentSessionDate", BegOfDay(CurrentSessionDate()));
	
	Query.Text =
	"SELECT
	|	VALUE(Enum.TypesOfTicketOperations.Return) AS OperationType,
	|	&CurrentSessionDate AS Date,
	|	SUM(AmountsByBids.Sum) AS Sum,
	|	SUM(AmountsByBids.VATAmount) AS VATAmount,
	|	AmountsByBids.VATRate AS VATRate
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -ElectronicTicketTransaction.Sum
	|			ELSE ElectronicTicketTransaction.Sum
	|		END AS Sum,
	|		CASE
	|			WHEN ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -ElectronicTicketTransaction.VATAmount
	|			ELSE ElectronicTicketTransaction.VATAmount
	|		END AS VATAmount,
	|		ElectronicTicketTransaction.VATRate AS VATRate
	|	FROM
	|		Document.ElectronicTicketTransaction.Operations AS ElectronicTicketTransaction
	|	WHERE
	|		ElectronicTicketTransaction.Ref = &ElectronicTicket
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.Sum
	|			ELSE CompositionOfOperation.Sum
	|		END,
	|		CASE
	|			WHEN ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperation.VATAmount
	|			ELSE CompositionOfOperation.VATAmount
	|		END,
	|		CompositionOfOperation.VATRate
	|	FROM
	|		Document.ElectronicTicketTransaction AS ElectronicTicketTransaction
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS CompositionOfOperation
	|			ON ElectronicTicketTransaction.Ref = CompositionOfOperation.Ref
	|	WHERE
	|		ElectronicTicketTransaction.ElectronicTicket = &ElectronicTicket
	|		AND NOT ElectronicTicketTransaction.DeletionMark) AS AmountsByBids
	|
	|GROUP BY
	|	AmountsByBids.VATRate
	|
	|HAVING
	|	SUM(AmountsByBids.Sum) > 0";
	
	CompositionOfOperation = Query.Execute().Unload();
	Operations.Load(CompositionOfOperation);
	
EndProcedure

Procedure SeparateOfOperationsFromElectronicTicket()
	
	CreateTicketOperations =
		Documents.ElectronicTicketTransaction.ElectronicTicketContainsOfOperationsLines(ThisObject);
		
	If Not CreateTicketOperations Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("ElectronicTicketOperations") Then
		
		ElectronicTicketOperations = New Structure;
		ElectronicTicketOperations.Insert("Operations", New Array);
		AdditionalProperties.Insert("ElectronicTicketOperations", ElectronicTicketOperations);
		
	EndIf;
	
	UpdatedOfOperations = AdditionalProperties.ElectronicTicketOperations.Operations;
	
	TransactionTypes = New Array;
	TransactionTypes.Add(Enums.TypesOfTicketOperations.ExtraPay);
	TransactionTypes.Add(Enums.TypesOfTicketOperations.Return);
	
	LinesToDelete = New Array;
	
	DimensionsOfOperations = "OperationType,Date,SmartwayVersionID";
	TableForCreatingOperations = Operations.Unload(, DimensionsOfOperations);
	TableForCreatingOperations.GroupBy(DimensionsOfOperations);
	
	DataForCreatingTicketOperation = Documents.ElectronicTicketTransaction.DataForCreatingTicketOperation();
	ThisIsNewTicket = IsNew();
	LinkToETicket = ?(ThisIsNewTicket, GetNewObjectRef(), Ref);
	
	For Each OperationDescription In TableForCreatingOperations Do
		
		If OperationDescription.OperationType = Enums.TypesOfTicketOperations.Purchase Then
			Continue;
		EndIf;
		
		NewOperation = Documents.ElectronicTicketTransaction.CreateDocument();
		
		DataToFill = New Structure();
		DataToFill.Insert("ElectronicTicket", LinkToETicket);
		DataForCreatingTicketOperation.ETicketData = ThisObject;
		FillPropertyValues(DataForCreatingTicketOperation.OperationDescription, OperationDescription);
		DataForCreatingTicketOperation.ThisIsTicketSplit = True;
			
		DataToFill.Insert("DataForCreatingTicketOperation", DataForCreatingTicketOperation);
		
		NewOperation.Fill(DataToFill);
		
		RowsFilter = New Structure(DimensionsOfOperations);
		FillPropertyValues(RowsFilter, OperationDescription);
		LinesOfCurrentTicket = Operations.FindRows(RowsFilter);
		For Each LineOfCurrentTicket In LinesOfCurrentTicket Do
			FillPropertyValues(NewOperation.Operations.Add(), LineOfCurrentTicket);
			LinesToDelete.Add(LineOfCurrentTicket);
		EndDo;
		
		If Not ThisIsNewTicket Then
			NewOperation.AdditionalProperties.Insert("SkipRegistrationInNonOperationalQueue");
		EndIf;
		UpdatedOfOperations.Add(NewOperation);
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		Operations.Delete(RowToDelete);
	EndDo;
	
EndProcedure

#Region BackdateJobQueue

Procedure CreateDocumentTasksWhenRecording()
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("SkipRegistrationInNonOperationalQueue")
		Or Not CheckFilling() Then
		Return;
	EndIf;
	
	JobKind = Catalogs.BackdateJobKinds.UpdatingOperationsAndStateOfElectronicTicket;
	
	Jobs = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.CreateRecordSet();
	
	NewJob = Jobs.Add();
	NewJob.Organization = Organization;
	NewJob.TaskPeriod = Date;
	NewJob.Document = Ref;
	NewJob.JobKind = JobKind;
	NewJob.RecordID = New UUID;
	
	SetPrivilegedMode(True);
	Jobs.Write(False);
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf