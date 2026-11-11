#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow - a data string defining the parameters of the input command based on.
//  - Undefined - if there is no right to create a document "Writing off non-cash DS".
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.DataProcessors.CashForecast.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Lập chi tiền ...';
												|ru = 'Сформировать списания ДС...';
												|en = 'Generate cash payments...'; fa = 'Generate cash payments...';
												|it = 'Creare lo storno contanti';
												|pl = 'Sformować rozchody ŚP...';
												|tr = 'Nakit gider yazmayı oluştur...'") ;
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Picture = PictureLib.RegisterSale;
	
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Defines the bank accounts and cash accounts from which payment can be made for the payment object
// 
// Parameters:
//  Payments_2 - ValueList of String, DocumentRef.PaymentRequest
//  Exceptional - Boolean - Indicates whether all available invoices and cash registers are enabled or divided by request
//
// Returns:
//  - Array of CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts
//  - Map of KeyAndValue:
//     * Key - DocumentRef.PaymentRequest, String - A way to identify an entry in the payment schedule.
//     * Value - Array of CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts
//
Function BankAccountsCashAccountsAvailableForPaymentObject(Payments_2, Exceptional = True) Export
	
	SetPrivilegedMode(True);
	
	If Payments_2.Count() = 1
		And TypeOf(Payments_2[0].Value) = Type("DocumentRef.PaymentRequest") Then
		Requests = New Array;
		Requests.Add(Payments_2[0].Value);
		NonRequestIds = New Array;
	Else
		PaymentsData = PaymentDataById(Payments_2);
		Requests = PaymentsData.PaymentRequests;
		NonRequestIds = PaymentsData.NonRequestIds;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Request.Ref AS Request,
	|	BankAccounts.Ref AS BankAccountCashAccount
	|INTO AllCheckoutBankAccounts
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|	
	|	INNER JOIN
	|		Document.PaymentRequest AS Request
	|	ON
	|		Request.Organization = BankAccounts.Owner
	|WHERE
	|	Request.Ref IN (&Ref)
	|	AND Request.PaymentMethodBankAccount
	|	AND NOT BankAccounts.DeletionMark
	|	AND NOT BankAccounts.Closed
	|	AND NOT Request.PaymentsAsPer275FZ
	|	AND NOT BankAccounts.SeparateSDOAccount
	|
	|UNION ALL
	|
	|SELECT
	|	Request.Ref,
	|	CashAccounts.Ref
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|	
	|	INNER JOIN
	|		Document.PaymentRequest AS Request
	|	ON
	|		Request.Organization = CashAccounts.Owner
	|		AND (CashAccounts.CashCurrency = Request.Currency
	|				AND (Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InPaymentCurrency)
	|					OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.EmptyRef))
	|			OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
	|		AND (CashAccounts.CashCurrency = Request.CashAccountRecipient.CashCurrency
	|			OR Request.CashAccountRecipient = VALUE(Catalog.CashAccounts.EmptyRef)
	|		AND Request.BusinessOperation <> VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|		OR
	|		CashAccounts.CashCurrency = Request.Currency
	|			AND Request.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion))
	|WHERE
	|	Request.Ref IN (&Ref)
	|	AND NOT CashAccounts.DeletionMark
	|	AND Request.PaymentMethodCash
	|	AND NOT Request.PaymentsAsPer275FZ
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Request.Ref AS Request,
	|	BankAccounts.Ref AS BankAccountCashAccount
	|
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|	
	|	INNER JOIN
	|		Document.PaymentRequest AS Request
	|	ON
	|		Request.Organization = BankAccounts.Owner
	|		AND (BankAccounts.CashCurrency = Request.Currency
	|				AND (Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InPaymentCurrency)
	|					OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.EmptyRef))
	|			OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
	|		AND (BankAccounts.CashCurrency = Request.BankAccountBeneficiary.CashCurrency
	|			OR Request.BankAccountBeneficiary = VALUE(Catalog.CompaniesBankAccounts.EmptyRef))
	|	
	|	LEFT JOIN
	|		Document.PaymentRequest.ARAPDetails AS Details
	|	ON
	|		Details.Ref = Request.Ref
	|		AND Details.LoanDepositContract.BankAccount = BankAccounts.Ref
	|		
	|	WHERE
	|		Request.Ref IN (&Ref)
	|		AND Request.PaymentMethodBankAccount
	|		AND Request.PaymentsAsPer275FZ
	|		AND NOT BankAccounts.DeletionMark
	|		AND NOT BankAccounts.Closed
	|		AND (Request.CounterpartyBankAccount.StateContract = BankAccounts.StateContract
	|			OR (NOT Request.ContractWithSDOParticipant
	|				AND NOT Request.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|					VALUE(Enum.BusinessTransactions.LoanInterestPayment))
	|				OR NOT BankAccounts.SeparateSDOAccount)
	|			OR (Request.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|					VALUE(Enum.BusinessTransactions.LoanInterestPayment))
	|				AND NOT Details.LoanDepositContract IS NULL)
	|			)
	|		AND Request.BankAccount = BankAccounts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentsAreNotRequests.Id,
	|	BankAccounts.Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|	
	|INNER JOIN
	|	InformationRegister.ScheduleOfPayments AS PaymentsAreNotRequests
	|ON
	|	  PaymentsAreNotRequests.Organization = BankAccounts.Owner
	|	AND PaymentsAreNotRequests.Id IN (&NonRequestIds)
	|WHERE
	|	  NOT BankAccounts.DeletionMark
	|	AND NOT BankAccounts.Closed
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentsAreNotRequests.Id,
	|	CashAccounts.Ref
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|	
	|INNER JOIN
	|	InformationRegister.ScheduleOfPayments AS PaymentsAreNotRequests
	|ON
	|	  PaymentsAreNotRequests.Organization = CashAccounts.Owner
	|	AND PaymentsAreNotRequests.Id IN (&NonRequestIds)
	|WHERE
	|	NOT CashAccounts.DeletionMark
	|;
	|
	|///////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AllCheckoutBankAccounts.BankAccountCashAccount
	|FROM
	|	AllCheckoutBankAccounts AS AllCheckoutBankAccounts
	|;
	|
	|///////////////////////////////////////////////////////
	|SELECT
	|	AllCheckoutBankAccounts.Request,
	|	AllCheckoutBankAccounts.BankAccountCashAccount
	|FROM
	|	AllCheckoutBankAccounts AS AllCheckoutBankAccounts
	|TOTALS BY
	|	AllCheckoutBankAccounts.Request
	|";
	
	Query.SetParameter("Ref", Requests);
	Query.SetParameter("NonRequestIds", NonRequestIds);
	
	If Exceptional Then
		Return Query.ExecuteBatch()[1].Unload().UnloadColumn("BankAccountCashAccount");
	Else
		CheckoutBankAccountValues = New Map;
		Selection = Query.ExecuteBatch()[2].Select(QueryResultIteration.ByGroups);
		While Selection.Next() Do
			CashRegisterAccountsOfApplication = New Array;
			SelectionOfCheckoutInvoices = Selection.Select();
			While SelectionOfCheckoutInvoices.Next() Do
				CashRegisterAccountsOfApplication.Add(SelectionOfCheckoutInvoices.BankAccountCashAccount);
			EndDo;
			CheckoutBankAccountValues.Insert(Selection.Request, CashRegisterAccountsOfApplication);
		EndDo;
		Return CheckoutBankAccountValues;
	EndIf;
	
EndFunction

// The structure of the transfer of the payment object.
// 
// Returns:
//  Structure - Structure Of Application Transfer:
//   * PaymentObject - DefinedType.PaymentObject
//   * BankAccountCashAccount - Reference link.Bank accounts of organizations, reference link.Cash accounts.
//   * PaymentDate - Date
//   * PayerBeneficiary - Reference link.Organizations, Directory link.Contractors, reference link.Physical beauty.
//   * Organization - CatalogRef.Companies
//   * AmountType - Link enumeration.Type of sumgraficationcreditsdeposits, enumerationslink.Viewtranslation of reliable means, 
//   	Enumerationslink enumerationslink.The type of payments in the leasehold.
//   * ReceiptIssue - EnumRef.CashFlowTypes
//   * Currency - CatalogRef.Currencies
//   * OriginalBankAccountCashAccount - Reference link.Bank accounts of organizations, reference link.Cash accounts.
//   * PaymentDateOriginal  - Date
//   * InitialAmount_ - Number
//   * TransferAmount_ - Number
//   * ZoomRatio - Number
//   * TransferCurrency_ - CatalogRef.Currencies
//   * FlagClose - Boolean
//   * ThisIsPartition - Boolean 
//
Function TransferStructure() Export
	
	TransferStructure = New Structure;
	
	TransferStructure.Insert("PaymentObject");
	TransferStructure.Insert("BankAccountCashAccount");
	TransferStructure.Insert("PaymentDate");
	TransferStructure.Insert("PayerBeneficiary");
	TransferStructure.Insert("Organization");
	TransferStructure.Insert("AmountType");
	TransferStructure.Insert("ReceiptIssue");
	TransferStructure.Insert("Currency");
	
	TransferStructure.Insert("OriginalBankAccountCashAccount");
	TransferStructure.Insert("PaymentDateOriginal");
	TransferStructure.Insert("InitialAmount_");
	
	TransferStructure.Insert("TransferAmount_");
	TransferStructure.Insert("ZoomRatio");
	TransferStructure.Insert("TransferCurrency_");
	TransferStructure.Insert("FlagClose");
	
	TransferStructure.Insert("ThisIsPartition", False);

	Return TransferStructure;
	
EndFunction

Procedure TransferPaymentItems(Parameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CashForecasting.TransferOfRequestsForSpendingFundsInPaymentCalendar");
	
	SetPrivilegedMode(True);
	
	TransferData = Parameters.TransferData;
	PlanFromDate = Parameters.PlanFromDate;
	
	TransferredPaymentItems = New Map;
	
	BeginTransaction();
	
	Try
		ManagerOfDocument = Common.ObjectManagerByFullName("Document.PaymentRequest");
		
		For Each PaymentObject In TransferData Do
			
			If TypeOf(PaymentObject.Key) = Type("String") Then
				TransferPaymentObject(PaymentObject, PlanFromDate);
				TransferredPaymentItems.Insert(PaymentObject.Key, PaymentObject.Value);
				Continue;
			EndIf;
			
			RequestObject = PaymentObject.Key.GetObject();
			
			Try
				RequestObject.Lock();
			Except
				MessageText = StrTemplate(
					NStr("vi = '%1 đang trong quá trình chỉnh sửa bởi người dùng hoặc hệ thống và không thể thay đổi.';
						|ru = '%1 находится в процессе редактирования пользователем или системой и не может быть изменена.';
						|en = '%1 is being edited by a user or the application and cannot be changed.'; fa = '%1 is being edited by a user or the application and cannot be changed.';
						|it = '%1 si trova in fase di modifica e non può essere modificato.';
						|pl = '%1 jest w trakcie edycji przez użytkownika lub przez system i nie może być zmieniona.';
						|tr = '%1 kullanıcı veya sistem tarafından düzenlenme sürecindedir ve değiştirilemez.'"),
					RequestObject);
				Common.MessageToUser(MessageText);
				Continue;
			EndTry;
			
			YouCanChangeDesiredDate = True;
			
			For Each TransferElement In PaymentObject.Value Do
				
				If TransferElement.ZoomRatio > 0 Then
				
					If ValueIsFilled(TransferElement.BankAccountCashAccount) Then
						
						YouCanChangeDesiredDate = False;
						
						If TransferElement.PaymentDate >= PlanFromDate Then
							
							TheStructureOfTheSearch = New Structure("BankAccountCashAccount, PaymentDate");
							FillPropertyValues(TheStructureOfTheSearch, TransferElement);
							
							ReductionAmount = TransferElement.TransferAmount_;
							
							FoundRows = RequestObject.AllocationByAccounts.FindRows(TheStructureOfTheSearch);
							
							For Each FoundRow In FoundRows Do
								
								LineAmount_ = Min(ReductionAmount, FoundRow.Sum);
								FoundRow.Sum = FoundRow.Sum - LineAmount_;
								ReductionAmount = ReductionAmount - LineAmount_;
								If Not FoundRow.Sum Then
									RequestObject.AllocationByAccounts.Delete(FoundRow);
								EndIf;
								If Not ReductionAmount Then
									Break;
								EndIf;
							EndDo;
						Else
							LinesToDelete = New Array;
							AmountOfDifference = TransferElement.TransferAmount_;
							
							For Each DistributionString In RequestObject.AllocationByAccounts Do
								
								If DistributionString.BankAccountCashAccount = TransferElement.BankAccountCashAccount Then
									If DistributionString.Sum = TransferElement.TransferAmount_ Then
										LinesToDelete.Add(DistributionString);
										Break;
									ElsIf DistributionString.Sum > AmountOfDifference Then
										DistributionString.Sum = DistributionString.Sum - AmountOfDifference;
										Break;
									Else
										LinesToDelete.Add(DistributionString);
										AmountOfDifference = AmountOfDifference - DistributionString.Sum;
									EndIf;
								EndIf;
							EndDo;
							
							For Each RowToDelete In LinesToDelete Do
								RequestObject.AllocationByAccounts.Delete(RowToDelete);
							EndDo;
						EndIf;
					EndIf;
				Else
					If ValueIsFilled(TransferElement.BankAccountCashAccount) Then
						
						NewDistributionLine = RequestObject.AllocationByAccounts.Add();
						NewDistributionLine.BankAccountCashAccount = TransferElement.BankAccountCashAccount;
						NewDistributionLine.Sum = TransferElement.TransferAmount_;
						If ValueIsFilled(TransferElement.PaymentDate) Then
							NewDistributionLine.PaymentDate = TransferElement.PaymentDate;
						Else
							NewDistributionLine.PaymentDate = RequestObject.RequiredPaymentDate;
						EndIf;
					Else
						If ValueIsFilled(TransferElement.PaymentDate) Then
							If YouCanChangeDesiredDate Then
								RequestObject.RequiredPaymentDate = TransferElement.PaymentDate;
							Else
								TransferElement.PaymentDate = RequestObject.RequiredPaymentDate;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			If TransferElement.FlagClose Then
				If TransferElement.ZoomRatio = 1 Then
					RequestObject.Unlock();
					If ManagerOfDocument.CloseApplications(PaymentObject.Key) = 1 Then
						TransferredPaymentItems.Insert(PaymentObject.Key, PaymentObject.Value);
					EndIf;
				ElsIf TransferElement.ZoomRatio = -1 Then
					RequestObject.Closed_ = False;
					RequestObject.Write(DocumentWriteMode.Posting);
					TransferredPaymentItems.Insert(PaymentObject.Key, PaymentObject.Value);
				EndIf;
			Else
				If RequestObject.CheckFilling() Then
					RequestObject.Write();
					
					Tables = DocumentsPosting.DocumentDataForPosting(RequestObject.Ref, "CashToBePaid");
					
					RecordSet = AccumulationRegisters.CashToBePaid.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(RequestObject.Ref);
					RecordSet.Load(Tables["Table"+"CashToBePaid"]);
					RecordSet.Write();
					
					TransferredPaymentItems.Insert(PaymentObject.Key, PaymentObject.Value);
				EndIf;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		MessageText = NStr("vi = 'Không thể chuyển yêu cầu do: %1';
							|ru = 'Не удалось перенести заявки по причине: %1';
							|en = 'Cannot transfer requests. Reason: %1'; fa = 'Cannot transfer requests. Reason: %1';
							|it = 'Non è stato possibile trasferire la richiesta a causa di: %1';
							|pl = 'Nie udało się przenieść zgłoszenia z powodu: %1';
							|tr = '%1 nedenle başvurular taşınamadı'");
		MessageText = StrTemplate(MessageText, BriefErrorDescription(ErrorInfo));
		Common.MessageToUser(MessageText);
		
		ErrorText = NStr("vi = 'Không thể chuyển yêu cầu.';
						|ru = 'Не удалось перенести заявки.';
						|en = 'Cannot transfer requests.'; fa = 'Cannot transfer requests.';
						|it = 'Non è stato possibile trasferire la richiesta.';
						|pl = 'Nie udało się przenieść zgłoszenia.';
						|tr = 'Başvurular taşınamadı.'", Common.DefaultLanguageCode());
		WriteLogEvent(
			ErrorText,
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo));
			
		TransferredPaymentItems.Clear();
	EndTry;
	
	PutToTempStorage(TransferredPaymentItems, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, TransferredPaymentItems.Count());
	
EndProcedure

// Gets the end date based on the transmitted start date and the number of days.
// 
// Parameters:
//  PlanFromDate - Date
//  PlanningDays - Number
// 
// Returns:
//  Date
//
Function EndDateOfPlanningByDay(Val PlanFromDate, Val PlanningDays) Export
	
	Return PlanFromDate + 86400 * (PlanningDays - 1);
	
EndFunction

// Gets the end date of long-term planning.
// 
// Parameters:
//  EndDateOfPlanningByDay - Date
//  LongTermPlanningPeriods - Number
//  LongTermPlanningTimeFence - EnumRef.Periodicity
// 
// Returns:
//  Date
//
Function EndDateOfLongTermPlanning(Val EndDateOfPlanningByDay, Val LongTermPlanningPeriods,
	Val LongTermPlanningTimeFence) Export
	
	If LongTermPlanningPeriods = 0 Or Not ValueIsFilled(LongTermPlanningTimeFence) Then
		Return '00010101';
	EndIf;
	
	Date = WorkingWithClientServerPeriods.AddInterval(EndDateOfPlanningByDay,
		LongTermPlanningTimeFence, LongTermPlanningPeriods);
	
	Return WorkingWithClientServerPeriods.PeriodEndDate_(Date, LongTermPlanningTimeFence);
	
EndFunction

// Gets the end date of the planning.
// 
// Parameters:
//  LongTermPlanningPeriods - Number
//  EndDateOfPlanningByDay - Date
//  EndDateOfLongTermPlanning - Date
// 
// Returns:
//  Date
//
Function EndDate(Val LongTermPlanningPeriods, Val EndDateOfPlanningByDay,
	Val EndDateOfLongTermPlanning) Export
	
	Return ?(LongTermPlanningPeriods = 0, EndDateOfPlanningByDay, EndDateOfLongTermPlanning);
	
EndFunction

Procedure RecalculateLongTermPeriodsInSubordinateRowsOfTree(TreeRow, Val LongTermPlanningPeriods,
	Val PlanningDays) Export
	
	If LongTermPlanningPeriods = 0 Then
		Return;
	EndIf;
	
	LastDayWithRevolutions = 0;
	IndexOf = PlanningDays;
	While IndexOf >= 1 Do
		If TreeRow["Day" + IndexOf] <> 0 Then
			LastDayWithRevolutions = IndexOf;
			Break;
		EndIf;
		IndexOf = IndexOf - 1
	EndDo;
	
	If TreeRow.LineKind = 0 Or TreeRow.LineKind = 4 Then // The balance in the currency of the DS, or in the currency of the payment
		
		OpeningBalance = ?(LastDayWithRevolutions > 0, TreeRow["Day" + LastDayWithRevolutions],
			TreeRow.Balance);
		
		For Indus = 1 To LongTermPlanningPeriods Do
			ColumnName = "LongTermPeriod" + Indus;
			TreeRow[ColumnName] = OpeningBalance + TreeRow[ColumnName + "InCurrency"];
			OpeningBalance = TreeRow[ColumnName];
			
			If TreeRow.LineKind = 0 Then
				TreeRow[ColumnName + "ErrorCriticalBalance"] = (OpeningBalance <= TreeRow.CriticalBalance)
					And TreeRow.CriticalBalance > 0
					And OpeningBalance > 0;
			EndIf;
		EndDo;
		
	ElsIf TreeRow.LineKind = 2 Then // Balance in one currency
		
		OpeningBalance = ?(LastDayWithRevolutions > 0, TreeRow["Day" + LastDayWithRevolutions],
			TreeRow.BalanceInASingleCurrency);
		
		For Indus = 1 To LongTermPlanningPeriods Do
			ColumnName = "LongTermPeriod" + Indus;
			TreeRow[ColumnName] = OpeningBalance + TreeRow[ColumnName + "InOneCurrency"];
			OpeningBalance = TreeRow[ColumnName];
		EndDo;
		
	ElsIf TreeRow.LineKind = 1 Then // Turnover in the currency of the DS, or in the currency of payment
		
		For Indus = 1 To LongTermPlanningPeriods Do
			ColumnName = "LongTermPeriod" + Indus;
			TreeRow[ColumnName] = TreeRow[ColumnName + "InCurrency"];
		EndDo;
		
	ElsIf TreeRow.LineKind = 3 Then // Turnover in one currency
		
		For Indus = 1 To LongTermPlanningPeriods Do
			ColumnName = "LongTermPeriod" + Indus;
			TreeRow[ColumnName] = TreeRow[ColumnName + "InOneCurrency"];
		EndDo;
	EndIf;
	
	If TypeOf(TreeRow) = Type("FormDataTreeItem") Then
		Rows = TreeRow.GetItems();
	Else
		Rows = TreeRow.Rows;
	EndIf;
		
	For Each TreeRow In Rows Do
		RecalculateLongTermPeriodsInSubordinateRowsOfTree(TreeRow, LongTermPlanningPeriods, 
			PlanningDays);
	EndDo;
	
EndProcedure

// Filling in the dates of the end of planning.
// 
// Parameters:
//  Object - DataProcessorObject.CashForecast
//
Procedure FillInEndDates(Object) Export
	
	Object.EndDateOfPlanningByDay = EndDateOfPlanningByDay(
		Object.PlanFromDate, Object.PlanningDays);
	Object.EndDateOfLongTermPlanning = EndDateOfLongTermPlanning(
		Object.EndDateOfPlanningByDay, Object.LongTermPlanningPeriods,
		Object.LongTermPlanningTimeFence);
	Object.EndDate = EndDate(Object.LongTermPlanningPeriods,
		Object.EndDateOfPlanningByDay, Object.EndDateOfLongTermPlanning);
	
EndProcedure

Procedure InitializeSettingsComposer(LinkerSelection, FormUniqueID = Undefined,
	Filter_Settings = Undefined) Export

	DataCompositionSchema = GetTemplate("PaymentTree");

	If FormUniqueID = Undefined Then
		AddressInStorage = PutToTempStorage(Undefined, New UUID());
	EndIf;
	AddressInStorage = PutToTempStorage(DataCompositionSchema, FormUniqueID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressInStorage);
	
	LinkerSelection.Initialize(SettingsSource);
	
	LinkerSelection.LoadSettings(DataCompositionSchema.DefaultSettings);
	If Filter_Settings <> Undefined Then
		DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
	EndIf;
	
	LinkerSelection.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	If FormUniqueID = Undefined Then
		DeleteFromTempStorage(AddressInStorage);
	EndIf;

EndProcedure

Procedure FreezeRefundPaymentsForExecution(Parameters, ResultAddress) Export

	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		For Each Payment_ In Parameters.Payments_2 Do
		
			Record = InformationRegisters.ScheduleOfPayments.CreateRecordManager();
			Record.Fill(Undefined);
			FillPropertyValues(Record, Payment_);
			Record.Read();
			
			If Record.Selected() Then
				Record.Frozen = Parameters.Frozen;
				
				If Not Parameters.Frozen Then
					Record.PaymentDate = Parameters.PaymentDate;
				EndIf;
				Record.Write();
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
			
		MessageText = NStr("vi = 'Không thể xử lý các khoản thanh toán với lý do: %1';
							|ru = 'Не удалось обработать платежи по причине: %1';
							|en = 'Cannot process the payments due to: %1'; fa = 'Cannot process the payments due to: %1';
							|it = 'Cannot process the payments due to: %1';
							|pl = 'Cannot process the payments due to: %1';
							|tr = 'Ödemeler şu nedenle işlenemedi: %1'");
		MessageText = StrTemplate(MessageText, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(MessageText);
	EndTry;

EndProcedure

Procedure TransferPaymentObject(PaymentObject, PlanFromDate)
	
	PaymentRecordReceived = False;
	
	For Each TransferElement In PaymentObject.Value Do

		If TransferElement.ZoomRatio > 0 Then
			
			Try
				DataLock = New DataLock;
				LockItem = DataLock.Add("InformationRegister.ScheduleOfPayments");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("PaymentObject", TransferElement.PaymentObject);
				LockItem.SetValue("BankAccountCashAccount", TransferElement.BankAccountCashAccount);
				LockItem.SetValue("PaymentDate", TransferElement.PaymentDate);
				LockItem.SetValue("PayerBeneficiary", TransferElement.PayerBeneficiary);
				LockItem.SetValue("Organization", TransferElement.Organization);
				LockItem.SetValue("AmountType", TransferElement.AmountType);
				LockItem.SetValue("ReceiptIssue", TransferElement.ReceiptIssue);
				LockItem.SetValue("Currency", TransferElement.Currency);
				DataLock.Lock();
			Except
				Raise;
			EndTry;
	
			PaymentRecord = InformationRegisters.ScheduleOfPayments.CreateRecordManager();
			PaymentRecord.Fill(Undefined);
			FillPropertyValues(PaymentRecord, TransferElement);
			PaymentRecord.Read();
				
			PaymentRecordReceived = PaymentRecord.Selected();
			
		ElsIf PaymentRecordReceived Then
			
			If ValueIsFilled(TransferElement.BankAccountCashAccount) Then
			
				If TransferElement.ThisIsPartition Then
			
					AmountOfDifference = TransferElement.TransferAmount_;
			
					NewRecord = InformationRegisters.ScheduleOfPayments.CreateRecordManager();
					NewRecord.Fill(Undefined);
					FillPropertyValues(NewRecord, PaymentRecord, ,
						"BankAccountCashAccount, PaymentDate, Sum, Id");
					FillPropertyValues(NewRecord, TransferElement, "BankAccountCashAccount, PaymentDate");
					NewRecord.Id = New UUID();
					NewRecord.Sum = AmountOfDifference;
					NewRecord.Write();
					
					PaymentRecord.Sum = PaymentRecord.Sum - AmountOfDifference;
				Else
					PaymentRecord.BankAccountCashAccount = TransferElement.BankAccountCashAccount;
					
					If ValueIsFilled(TransferElement.PaymentDate) Then
						PaymentRecord.PaymentDate = TransferElement.PaymentDate;
					EndIf;
					PaymentRecord.Sum = TransferElement.TransferAmount_;
				EndIf;
				
				PaymentRecord.Write();
			Else
				If ValueIsFilled(TransferElement.PaymentDate) Then

					FillPropertyValues(PaymentRecord, TransferElement, "BankAccountCashAccount, PaymentDate");
					PaymentRecord.Sum = TransferElement.TransferAmount_;
					PaymentRecord.Write();
				Else
					Records = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
					Records.Fill(Undefined);
					Records.Filter.PaymentObject.Set(PaymentRecord.PaymentObject);
					Records.Read();
					
					For Each Record In Records Do
						
						Record.BankAccountCashAccount = Record.OriginalBankAccountCashAccount;
						Record.PaymentDate = Record.PaymentDateOriginal;
						Record.Sum = Record.InitialAmount_;
					EndDo;
					
					RecordTable = Records.Unload();
					RecordTable.GroupBy("PaymentObject, BankAccountCashAccount, PaymentDate, PayerBeneficiary,
						|Organization, AmountType, ReceiptIssue, Currency, Sum, CashFlowItem,
						|BusinessOperation, PlanningArea, Department, LineOfBusiness, Priority,
						|EmployeeResponsible, PaymentObjectType, Number, Date, DocumentAmount, PaymentMethod, ScheduleRelevanceDate,
						|CorrespondingCurency, Status, Frozen, OriginalBankAccountCashAccount, PaymentDateOriginal, InitialAmount_");
					
					Records.Load(RecordTable);
					
					For Each Record In Records Do 
						Record.Id = New UUID();
					EndDo;
					
					If Records.Count() > 0 Then
						Records.Write();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function PaymentDataById(IDs)

	Result = New Structure("PaymentRequests, NonRequestIds");

	Query = New Query;
	Query.Text = "
	|SELECT
	|	ScheduleOfPayments.Id AS Id,
	|	Requests.Ref AS Request
	|
	|INTO Payments_2
	|
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|	
	|LEFT JOIN
	|	Document.PaymentRequest AS Requests
	|ON
	|	Requests.Ref = ScheduleOfPayments.PaymentObject
	|WHERE
	|	ScheduleOfPayments.Id IN (&IDs)
	|;
	|
	|SELECT
	|	Payments_2.Request AS Request
	|FROM
	|	Payments_2
	|WHERE
	|	NOT Payments_2.Request IS NULL
	|;
	|
	|SELECT
	|	Payments_2.Id AS Id
	|FROM
	|	Payments_2
	|WHERE
	|	Payments_2.Request IS NULL
	|";
	
	Query.SetParameter("IDs", IDs);
	
	QueryResult = Query.ExecuteBatch();
	
	Result.PaymentRequests = QueryResult[1].Unload().UnloadColumn("Request");
	Result.NonRequestIds = QueryResult[2].Unload().UnloadColumn("Id");
	
	Return Result;

EndFunction

// The date from which overdue payments will be displayed.
// 
// Parameters:
//  PlanFromDate - Date
//  DepthOfDisplayOfOverduePayments - Number
// 
// Returns:
//  Date
//
Function StartDateForDisplayingOverduePayments(PlanFromDate, DepthOfDisplayOfOverduePayments) Export
	
	Return ?(DepthOfDisplayOfOverduePayments = 0, '00010101',
		PlanFromDate - 86400 * DepthOfDisplayOfOverduePayments);
	
EndFunction

#EndRegion

#EndIf
