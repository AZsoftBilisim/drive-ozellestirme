#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not Cancel 
	And GetFunctionalOption("NewOnlineARAPAccounting")
	And Filter.Period.Use 
	And Filter.Organization.Use Then
		
		DiscountingDisabled = True;
		For Each Record In ThisObject Do
			If Record.AccountingForDiscountedAccountsPayableToVendors Then
					DiscountingDisabled = False;
			EndIf;
		EndDo;
		If DiscountingDisabled Then 
			// We check if discounting has been enabled - we will create a routine task for recalculation of interest
			Query = New Query(InformationRegisters.FinancialAccountingPolicy.QueryTextCurrentTaxAccountingPolicySettings());
			Query.TempTablesManager = New TempTablesManager();
			Companies = CommonClientServer.ValueInArray(Filter.Organization.Value);
			AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(Query.TempTablesManager, Companies);
			Query.SetParameter("Period", Filter.Period.Value);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				If Selection.AccountingPoliciesExist
					And Selection.AccountingForDiscountedAccountsPayableToVendors Then
					InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
						Filter.Period.Value
						,
						,
						Filter.Organization.Value,
						Catalogs.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses);
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	LocalAccntingServer.AccountingPolicyOfFinancialAccounting_WhenRecording(Cancel, ThisObject);
	
	If Not Cancel And Count() = 0 Then
		
		RecordSet = InformationRegisters.DiscountRates.CreateRecordSet();
		If Filter.Organization.Use Then
			RecordSet.Filter.Organization.Set(Filter.Organization.Value);
		EndIf;
		If Filter.Period.Use Then
			RecordSet.Filter.Period.Set(Filter.Period.Value);
		EndIf;
		RecordSet.Write(Replacing);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf