#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Description = String(Owner);
	
	SalesSettingsForUsersServer.ClearUnusedSalesRules(ThisObject);
	
	ThereAreSpecificationsByPriceGroups = PriceGroups.Count() > 0;
	
	If Not CWP_Use Then
		CWP_ReturnOfGoods           = False;
		CWP_CashDeposit           = False;
		CWP_CashWithdrawal             = False;
		RowAdjustment      = False;
		CWP_Delay                = False;
		CWP_Reserve         = False;
		CWP_OpenShift            = False;
		CWP_CloseShift            = False;
		CWP_ManualChangeOfLoyaltyCard = False;
		CWP_ChangeLoyaltyCardHolderInformation = False;
		RMK_AllowPaymentWithoutConfirmationFromSBP = False;
		CWP_AllowPriceChangesWhenReturningWithoutReceipt = False;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If LimitDiscountAdjustments Then
		KeyAttributes = New Array;
		KeyAttributes.Add("PriceGroup");
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "PriceGroups", KeyAttributes, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf