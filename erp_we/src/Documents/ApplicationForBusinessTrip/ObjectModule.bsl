#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForBusinessTrip.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	Status = Enums.EmployeeApplicationStatuses.IsPrepared;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If PersonsList Then
		AttributesNotToCheck.Add("Employee");
		AttributesNotToCheck.Add("PersonalAccount");
	Else
		AttributesNotToCheck.Add("FundsIssueToAdvanceHolder.Employee");
		AttributesNotToCheck.Add("FundsIssueToAdvanceHolder.PersonalAccount");
	EndIf;
	
	If Status = Enums.EmployeeApplicationStatuses.IsPrepared
		Or Status = Enums.EmployeeApplicationStatuses.IsRejected
		Or Status = Enums.EmployeeApplicationStatuses.Withdrawn Then
		
		AttributesNotToCheck.Add("FundsIssueToAdvanceHolder.CashFlowItem");
	EndIf;
	
	If Not FundsIssueToAdvanceHolder.Count() Then
		AttributesNotToCheck.Add("RequiredPaymentDate");
		AttributesNotToCheck.Add("Currency");
	EndIf;
	
	If PaymentMethodOfPaymentRequest <> Enums.PaymentForms.BankAccountPayment Then
		AttributesNotToCheck.Add("BankAccount");
		AttributesNotToCheck.Add("PersonalAccount");
		AttributesNotToCheck.Add("FundsIssueToAdvanceHolder.PersonalAccount");
	EndIf;
	
	If PaymentMethodOfPaymentRequest <> Enums.PaymentForms.CashAccountPayment_ Then
		AttributesNotToCheck.Add("CashAccount");
	EndIf;
	If Not LimitsByBudgetingDataServer.UseBDRLimits() Then
		AttributesNotToCheck.Add("Expenses.BudgetFlowItem");
	EndIf;
	More = New Structure;
	FieldSettings = CashServer.InitializeFormFieldSettings();
	Documents.ApplicationForBusinessTrip.FillInFormFieldSettings(FieldSettings);
	ItemsProperties = CashClientServer.PropertiesOfFormElements(ThisObject, FieldSettings,,, More);
	CashServer.DisableVerificationOfObjectDetails(ItemsProperties, AttributesNotToCheck);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	If Status = Enums.EmployeeApplicationStatuses.AgreedUpon
		And Not UserRightsCached.ApproveApplicationsForBusinessTrip() Then
		
		ErrorText = NStr("vi = 'Không có quyền thống nhất yêu cầu công tác';
						|ru = 'Нет права согласования заявок на командировки';
						|en = 'No right to approve applications for business trips'; fa = 'No right to approve applications for business trips';
						|it = 'Nessun diritto di approvare le richieste di viaggi di lavoro';
						|pl = 'Brak prawa uzgodnienia zgłoszeń podróży służbowych';
						|tr = 'Seyahat başvurularını onaylama yetkisi mevcut değil'");
		Common.MessageToUser(ErrorText, ThisObject,,, Cancel);
	EndIf;
	
	If ValueIsFilled(BankAccount) Then
		CashServer.CheckAvailabilityOfBankAccount(ThisObject, BankAccount, "BankAccount");
	EndIf;
	
	If Status = Enums.EmployeeApplicationStatuses.AgreedUpon Then
		ApplicationForBusinessTripLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	
	CheckWhetherApplicationHasBeenPaid(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForBusinessTrip.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	LimitsByBudgetingDataServer.CheckRelevanceOfRulesForLimitsOnBudgetItems(ThisObject, Cancel);
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	EmployeeListAsString = "";
	
	If Not PersonsList Then
		TravellingEmployees.Clear();
		TravellingEmployees.Add().Employee = Employee;
		For Each TSRow In FundsIssueToAdvanceHolder Do
			TSRow.Employee = Employee;
			TSRow.PersonalAccount = PersonalAccount;
		EndDo;
	Else
		Employee = Undefined;
		PersonalAccount = Undefined;
		DetailsOfEmployees = Common.ObjectsAttributeValue(
			TravellingEmployees.UnloadColumn("Employee"), "Description");
		EmployeesByLine = New Array;
		For Each KeyAndValue In DetailsOfEmployees Do
			EmployeesByLine.Add(KeyAndValue.Value);
		EndDo;
		EmployeeListAsString = StrConcat(EmployeesByLine, "; ");
	EndIf;
	
	ArrayOfCFItems = TMCommonUse.DeleteDuplicateElementsFromArray(
		FundsIssueToAdvanceHolder.UnloadColumn("CashFlowItem"));
	If ArrayOfCFItems.Count() = 1 Then
		CashFlowItem = ArrayOfCFItems[0];
	ElsIf ArrayOfCFItems.Count() > 1 Then
		CashFlowItem = Undefined;
	EndIf;
	
	DocumentAmount = FundsIssueToAdvanceHolder.Total("Sum");
	ExpectedExpenseAmount = Expenses.Total("Sum");
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForBusinessTrip.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
EndProcedure

Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.EmployeeApplicationStatuses[NewStatus];
	
	If MeaningOfNewStatus = Enums.EmployeeApplicationStatuses.AgreedUpon Then
		WhoDecided = Users.CurrentUser();
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

Procedure CheckWhetherApplicationHasBeenPaid(Cancel)
	
	If Not IsNew() And Status <> Enums.EmployeeApplicationStatuses.AgreedUpon Then
		
		SetPrivilegedMode(True);
		
		Query = New Query("
		|SELECT
		|	Cash.SumExpense AS Paid
		|FROM
		|	AccumulationRegister.CashToBePaid.Turnovers(,,Period,
		|		PaymentRequest = &Request
		|	) AS Cash
		|WHERE
		|	Cash.SumExpense > 0
		|");
		Query.SetParameter("Request", Ref);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Text = NStr("vi = 'Giấy đề nghị đã được thanh toán. Không thể thay đổi trạng thái giấy đề nghị là ""Đã thanh toán""';
						|ru = 'Заявка оплачена. Нельзя изменять статус заявки ""Согласована""';
						|en = 'Request is paid up. Cannot change ""Approved"" request status'; fa = 'Request is paid up. Cannot change ""Approved"" request status';
						|it = 'La richiesta è stata pagata. Non è possibile modificare lo stato della richiesta ""Approvata""';
						|pl = 'Zlecenie jest opłacone. Nie można zmienić statusu zlecenia ""Uzgodnione""';
						|tr = 'Talep ödendi. Talebin ""Onaylandı"" durumu değiştirilmemeli'");
			Common.MessageToUser(Text, ThisObject, "Status",, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf