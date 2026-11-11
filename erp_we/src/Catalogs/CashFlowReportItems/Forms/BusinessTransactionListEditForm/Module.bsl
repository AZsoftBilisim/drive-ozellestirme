
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	For Each ListItem In Parameters.BusinessTransactionList Do
		BusinessTransactionList.Add().BusinessOperation = ListItem.Value;
	EndDo;

	SetListOfSelectionOfBusinessOperations();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure SetListOfSelectionOfBusinessOperations()
	
	ArrayOfItemsExcludedFromSelection = New Array;
	
	// Exchange rate differences
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		ArrayOfItemsExcludedFromSelection.Add(Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeGain);
		ArrayOfItemsExcludedFromSelection.Add(Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss);
	EndIf;	 
	
	Query = New Query("SELECT
		|	BusinessTransactionsSettings.BusinessOperation
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	(BusinessTransactionsSettings.Receipt = &AccountingDataTypeCash
		|			OR BusinessTransactionsSettings.Expense = &AccountingDataTypeCash)");
		
	Query.SetParameter("AccountingDataTypeCash", Enums.AccountingDataTypes.Cash);
	
	ArrayOfBusinessTransactions = Query.Execute().Unload().UnloadColumn("BusinessOperation");
	
	If GetFunctionalOption("ControlIssueOfCashByPurposes") Then
		ArrayOfBusinessTransactions.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	EndIf;
	
	BusinessTransactionItem = Items.BusinessOperation;
	BusinessTransactionItem.ChoiceList.LoadValues(ArrayOfBusinessTransactions);
	
	For Each ExcludeBusinessTransaction In ArrayOfItemsExcludedFromSelection Do
		ListLine = BusinessTransactionItem.ChoiceList.FindByValue(ExcludeBusinessTransaction);
		If ListLine <> Undefined Then
			BusinessTransactionItem.ChoiceList.Delete(ListLine);
		EndIf;
	EndDo;
	
	CashServer.SetVisibilityOfPaymentByPaymentCard(BusinessTransactionItem);
	CashServer.SetVisibilityOfTransferOperationsBetweenCashRegisters(BusinessTransactionItem);
	CashServer.SetVisibilityOfTransferOperationsToAnotherAccount(BusinessTransactionItem);
	CashServer.SetVisibilityOfOperationsWithCashRegisterCashRegisters(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfInternalTransferOperations(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfOperationOtherCashFlow(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfOperationOtherCashDisbursement(BusinessTransactionItem);
	CashServer.SetVisibilityOfCurrencyConversionCashOperation(BusinessTransactionItem);
	CashServer.SetVisibilityOfCurrencyConversionNonCashOperation(BusinessTransactionItem);
	CashServer.SetVisibilityOfCurrencyConversionOperation(BusinessTransactionItem);
	CashServer.SetVisibilityOfSalaryOperation(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfAcquiringOperations(BusinessTransactionItem);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(BusinessTransactionItem);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Modified Then
		Notification = New CallbackDescription("TransferData_Completion", ThisForm, New Structure("Cancel", Cancel));
		ShowQueryBox(Notification, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
										|ru = 'Данные были изменены. Сохранить изменения?';
										|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
										|it = 'I dati sono stati modificati. Salvare le modifiche?';
										|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
										|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferData_Completion(QuestionResult, AdditionalParameters) Export
	
	Cancel = AdditionalParameters.Cancel;
	
	If QuestionResult = DialogReturnCode.Yes Then
		TransferData_(Cancel);
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessTransactionListOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure BusinessTransactionListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("Array") Then
		StandardProcessing = False;
		ArrayOfBusinessTransactions = GetArrayOfBusinessTransactions(ValueSelected);
		For Each BusinessTransaction In ArrayOfBusinessTransactions Do
			BusinessTransactionList.Add().BusinessOperation = BusinessTransaction;
		EndDo;
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveList(Command)
	
	TransferData_();
	
EndProcedure

&AtClient
Procedure ListOfBusinessOperationsAdd(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("Filter", New Structure("BusinessOperation", Items.BusinessOperation.ChoiceList));
	FormParameters.Insert("RepresentedAsList", True);
	
	OpenForm("Catalog.BusinessTransactionsSettings.ChoiceForm",
			FormParameters, Items.BusinessTransactionList);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure TransferData_(Cancel = False)
	
	ClearMessages();
	
	Result = New ValueList;
	
	For IndexOf = 0 To BusinessTransactionList.Count() - 1 Do
		
		LineInListOfBusinessOperations = BusinessTransactionList[IndexOf];
		
		If Not ValueIsFilled(LineInListOfBusinessOperations.BusinessOperation) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dòng %1 không được điền vào giao dịch kinh doanh.';
					|ru = 'В строке %1 не заполнена хозяйственная операция.';
					|en = 'Business transaction is required in line %1.'; fa = 'Business transaction is required in line %1.';
					|it = 'Nella riga %1 non è stata compilata l''operazione commerciale.';
					|pl = 'W wierszu %1 nie wypełniono operacji gospodarczej.';
					|tr = '%1 satırda ticari işlem doldurulmadı.'"),
				IndexOf + 1);
			CommonClientServer.MessageToUser(
				Text,
				,
				"BusinessTransactionList["+IndexOf+"].BusinessOperation",
				,
				Cancel);
		
		EndIf;
		
		If Result.FindByValue(LineInListOfBusinessOperations.BusinessOperation) = Undefined Then
			Result.Add(LineInListOfBusinessOperations.BusinessOperation);
		EndIf;
		
	EndDo;

	If Not Cancel Then
		Modified = False;
		NotifyChoice(Result);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Function GetArrayOfBusinessTransactions(ArrayOfBusinessTransactions)
	
	Query = New Query("SELECT
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetup,
		|	BusinessTransactionsSettings.BusinessOperation AS BusinessTransaction
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	BusinessTransactionsSettings.Ref IN (&ArrayOfBusinessTransactions)");
	Query.SetParameter("ArrayOfBusinessTransactions", ArrayOfBusinessTransactions);
	
	Selection = Query.Execute().Select();
	
	Result = New Array;
	
	For Each BusinessTransactionSetup In ArrayOfBusinessTransactions Do
		Selection.FindNext(New Structure("BusinessTransactionSetup", BusinessTransactionSetup));
		Result.Add(Selection.BusinessTransaction);
		Selection.Reset();
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
