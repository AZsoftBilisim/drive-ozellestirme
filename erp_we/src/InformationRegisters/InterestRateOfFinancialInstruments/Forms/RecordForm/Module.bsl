
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	If ValueIsFilled(Record.Contract) Then
		SetAvailabilityByAgreement();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SetAvailabilityByAgreement();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.ChangeDate = CurrentSessionDate();
	CurrentObject.ChangeAuthor = Users.CurrentUser();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Contract_Rates = New Structure("Contract, Percent, Fee");
	FillPropertyValues(Contract_Rates, Record);
	WriteParameters = New Structure("Contract_Rates", Contract_Rates);
	Notify("Write_InterestRateOfFinancialInstruments", WriteParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractOnChange(Item)
	
	SetAvailabilityByAgreement();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetAvailabilityByAgreement()
	
	If TypeOf(Record.Contract) = Type("CatalogRef.LoanAndDepositContracts") Then
		
		ContractDetails_ = Common.ObjectAttributesValues(Record.Contract, "Status, FeeType, ARAPCurrency");
		
		Items.LabelCurrency.Title = String(ContractDetails_.ARAPCurrency);
		
		If ContractDetails_.FeeType = Enums.LoanAndDepositFeeTypes.Sum Then
			Items.PagesFee.CurrentPage = Items["ByAmount"];
			Items.PagesFee.Visible = True;
		ElsIf ContractDetails_.FeeType = Enums.LoanAndDepositFeeTypes.Percent Then
			Items.PagesFee.CurrentPage = Items["AsAPercent"];
			Items.PagesFee.Visible = True;
		Else
			Items.PagesFee.Visible = False;
		EndIf;
	Else
		
		ContractDetails_ = Common.ObjectAttributesValues(Record.Contract, "Status");
	EndIf;
	
	ContractIsClosed = (ContractDetails_.Status = Enums.CounterpartyContractStatuses.Closed);
	Items.TheInscriptionTheContractIsClosed.Visible = ContractIsClosed;
	ReadOnly = ContractIsClosed;
	
EndProcedure

#EndRegion

#EndRegion
