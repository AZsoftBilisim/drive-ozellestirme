
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Organization = Parameters.Organization;
	Currency = Parameters.Currency;
	PaymentDateSelection = Parameters.Date;
	
	POSTerminalsAreUsed = False;
	Parameters.Property("AcquiringContract", AcquiringContract);
	Parameters.Property("POSTerminalsAreUsed", POSTerminalsAreUsed);
	
	Items.PaymentTable_3POSTerminal.Visible = POSTerminalsAreUsed;
	
	SelectIncomingPayments  = Parameters.SelectIncomingPayments;
	AddressOfPaymentsInTheStorage = Parameters.AddressOfPaymentsInTheStorage;
	
	FillInPaymentTable();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument()

	PlacePaymentsInStorage();
	Close(DialogReturnCode.OK);
	
	Structure = New Structure("SelectIncomingPayments, AddressOfPaymentsInTheStorage", SelectIncomingPayments, AddressOfPaymentsInTheStorage);
	NotifyChoice(Structure);
	
EndProcedure

&AtClient
Procedure SelectPayments()

	For Each TableRow In PaymentTable_3 Do
		TableRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ExcludePayments()

	For Each TableRow In PaymentTable_3 Do
		TableRow.Selected = False
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectSelectedPayments(Command)
	
	RowsArray = Items.PaymentTable_3.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = PaymentTable_3.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ExcludeSelectedPayments(Command)
	
	RowsArray = Items.PaymentTable_3.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = PaymentTable_3.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PaymentDateSelectionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInPaymentTable();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure PlacePaymentsInStorage() 
	
	Payments_2 = PaymentTable_3.Unload(, "Selected, PaymentDate, POSTerminal, AuthorizationCode, Sum");
	ArrayOfRowsToDelete_1 = New Array;
	For Each TableRow In Payments_2 Do
		If Not TableRow.Selected Then
			ArrayOfRowsToDelete_1.Add(TableRow);
		EndIf;
	EndDo;
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		Payments_2.Delete(TableRow);
	EndDo;

	PutToTempStorage(Payments_2, AddressOfPaymentsInTheStorage);
	
EndProcedure

&AtServer
Procedure FillInPaymentTable()
	
	Query = New Query("
	|SELECT
	|	Payments_2.PaymentDate,
	|	&AcquiringContract,
	|	Payments_2.POSTerminal,
	|	Payments_2.AuthorizationCode
	|INTO PaymentTable_3
	|FROM
	|	&Payments_2 AS Payments_2
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	AcquiringContractARAP.Currency AS Currency,
	|	&Character * SUM(
	|		CASE WHEN AcquiringContractARAP.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			AcquiringContractARAP.Sum
	|		ELSE
	|			- AcquiringContractARAP.Sum
	|		END) AS Sum,
	|	AcquiringContractARAP.PaymentDate AS PaymentDate,
	|	AcquiringContractARAP.Contract AS Contract,
	|	AcquiringContractARAP.POSTerminal AS POSTerminal,
	|	AcquiringContractARAP.AuthorizationCode AS AuthorizationCode
	|	
	|INTO AcquiringContractARAP
	|FROM
	|	AccumulationRegister.AcquiringContractARAP AS AcquiringContractARAP
	|	
	|WHERE
	|	AcquiringContractARAP.Organization = &Organization
	|	AND AcquiringContractARAP.Currency = &Currency
	|	AND AcquiringContractARAP.CashType = &CashType
	|	AND AcquiringContractARAP.Contract = &AcquiringContract
	|	AND AcquiringContractARAP.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND (AcquiringContractARAP.PaymentDate >= &PaymentDate OR &PaymentDateIsNotFilledIn)
	|	
	|GROUP BY
	|	AcquiringContractARAP.Currency,
	|	AcquiringContractARAP.PaymentDate,
	|	AcquiringContractARAP.Contract,
	|	AcquiringContractARAP.POSTerminal,
	|	AcquiringContractARAP.AuthorizationCode
	|
	|HAVING
	|	SUM(
	|		CASE WHEN AcquiringContractARAP.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			AcquiringContractARAP.Sum
	|		ELSE
	|			- AcquiringContractARAP.Sum
	|		END) <> 0
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	CASE WHEN NOT PaymentTable_3.AcquiringContract IS NULL THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS Selected,
	|
	|	AcquiringContractARAP.Currency AS Currency,
	|	AcquiringContractARAP.Sum AS Sum,
	|	AcquiringContractARAP.PaymentDate AS PaymentDate,
	|	AcquiringContractARAP.POSTerminal AS POSTerminal,
	|	AcquiringContractARAP.AuthorizationCode AS AuthorizationCode
	|	
	|FROM
	|	AcquiringContractARAP AS AcquiringContractARAP
	|	
	|	LEFT JOIN
	|		PaymentTable_3 AS PaymentTable_3
	|	ON
	|		AcquiringContractARAP.PaymentDate = PaymentTable_3.PaymentDate
	|		AND AcquiringContractARAP.Contract = PaymentTable_3.AcquiringContract
	|		AND AcquiringContractARAP.POSTerminal = PaymentTable_3.POSTerminal
	|		AND AcquiringContractARAP.AuthorizationCode = PaymentTable_3.AuthorizationCode
	|
	|ORDER BY
	|	PaymentDate
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("AcquiringContract", AcquiringContract);
	Query.SetParameter("PaymentDate", PaymentDateSelection);
	Query.SetParameter("PaymentDateIsNotFilledIn", Not ValueIsFilled(PaymentDateSelection));
	
	If SelectIncomingPayments Then
		Query.SetParameter("CashType", Enums.AcquiringCashTypes.CashRecieptByAcquiringTransactions);
		Query.SetParameter("Character", 1);
	Else
		Query.SetParameter("CashType", Enums.AcquiringCashTypes.CashIssueByPaymentCard);
		Query.SetParameter("Character", -1);
	EndIf;
	
	Payments_2 = GetFromTempStorage(AddressOfPaymentsInTheStorage);
	Query.SetParameter("Payments_2", Payments_2);
	
	PaymentTable_3.Load(Query.Execute().Unload());
	AmountTotal = PaymentTable_3.Total("Sum");
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_PaymentDateSelection" Then
		PaymentDateSelectionOnChange(Items.PaymentDateSelection);
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
