
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	UsePartnersSegments = GetFunctionalOption("UsePartnersSegments");
	UseLoyaltyCards = GetFunctionalOption("UseLoyaltyCards");
	UseUserGroups = GetFunctionalOption("UseUserGroups");
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	For Each CurItem In Enums.DiscountMarkupTerms Do
		If CurItem = Enums.DiscountMarkupTerms.IncludeCustomerInSegment
			And Not UsePartnersSegments Then
			Continue;
		ElsIf CurItem = Enums.DiscountMarkupTerms.ForLoyaltyCard
			And Not UseLoyaltyCards Then
			Continue;
		ElsIf CurItem = Enums.DiscountMarkupTerms.LoyaltyCardIsNotRegistered
			And Not UseLoyaltyCards Then
			Continue;
		ElsIf CurItem = Enums.DiscountMarkupTerms.LimitationByUserGroup
			And Not UseUserGroups Then
			Continue;
		ElsIf CurItem = Enums.DiscountMarkupTerms.ForATrialSale
			And Not UsePartnersSegments Then
			Continue;
		Else
			ChoiceData.Add(CurItem);
		EndIf;
	EndDo;
	
EndProcedure
