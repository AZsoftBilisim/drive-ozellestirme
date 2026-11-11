#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Records the interest rate and Commission rate for a loan, Deposit, or loan agreement.
//
// Parameters:
//	 Contract - CatalogRef.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//	 NewBid - Number - interest rate under the agreement.
//	 NewCommission - Number - percentage of the Commission under the agreement.
//	 Period - Date - the date on which the interest rates under the agreement start to apply. By default, the current date.
//
Procedure RecordCommissionSInterestRate(Contract, NewBid, NewCommission, Period = Undefined) Export
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contract.Set(Contract);
	RecordSet.Read();
	If RecordSet.Count() <= 1 Then
		BettingHistory = RecordSet.Unload();
		If BettingHistory.Count() = 0 Then
			DataString1 = BettingHistory.Add();
		Else
			DataString1 = BettingHistory[0];
		EndIf;
		DataString1.Period         = Period;
		DataString1.Contract        = Contract;
		DataString1.Percent        = NewBid;
		DataString1.Fee       = NewCommission;
		DataString1.ChangeDate  = CurrentSessionDate();
		DataString1.ChangeAuthor = Users.CurrentUser();
		RecordSet.Load(BettingHistory);
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Gets the interest rate and Commission rate for the loan agreement, Deposit, loan.
//
// Parameters:
//    Contract - CatalogRef.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//    New - Number-the interest rate on the contract will be placed.
//    New Commission-Number-the percentage of the contract Commission will be placed.
//    Period - Date - the date on which the interest rates under the agreement start to apply. By default, the current date.
//
//Returns:
//    Structure - Bid, Commission, and multiple record flag
//
Function ReadCommissionInterestRate(Contract, Period = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Percent", 0);
	Result.Insert("Fee", 0);
	Result.Insert("Period", '00010101');
	Result.Insert("ThereIsStory", False);
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	BettingHistory = SliceLast(Period, New Structure("Contract", Contract));
	If BettingHistory.Count() > 0 Then
		FillPropertyValues(Result, BettingHistory[0]);
		Result.ThereIsStory = True;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf