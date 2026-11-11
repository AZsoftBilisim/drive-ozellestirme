
#Region Public

// Determines whether version 2.5 pricing is used on the specified date.
//
// Parameters:
//	Date - Date - the date to set the pricing mode for.
//
// Returns:
//	Boolean - indicates that version 2.5 pricing is being used as of the specified date
//	if no date is specified, then it is equated to the Cur current one.
//
Function UsePriceManagementSystem25(Val Date = Undefined) Export

	If Not GetFunctionalOption("UsePriceManagementSystem25") Then
		Return False; // pricing 2.5 off
	EndIf;
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	UsePriceManagementSystem25 = (Date >= DateOfTransitionToPricingVersion25());
	
	Return UsePriceManagementSystem25;

EndFunction

#Region InformingAboutRemovalOfOutdatedFunctionality

// Sets the visibility and title text of the decoration informing about the removal of pricing version 2.0.
//
// Parameters:
// 	Items - FormItems
// 	AddLinkToAssistant - Boolean
//
Procedure SetPropertiesOfSceneryInformingAboutRemovalOfPricingVersion20(Items, AddLinkToAssistant = True) Export
	
	ItemVisibility = Not PriceManagementSystemServerCall.UsePriceManagementSystem25('39990101');
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"DecorationInformingAboutRemovalOfPricingVersion20",
		"Visible",
		ItemVisibility);
	
	If ItemVisibility Then
			
		CommonClientServer.SetFormItemProperty(
			Items,
			"DecorationInformingAboutRemovalOfPricingVersion20",
			"Title",
			DecorationTextInformingAboutRemovalOfPricingVersion20(AddLinkToAssistant));
		
	EndIf;
	
EndProcedure

// Returns the header of the information message about disabling pricing version 2.0.
//
// Parameters:
// 	AddLinkToAssistant - Boolean
//
// Returns:
// 	String
//
Function DecorationTextInformingAboutRemovalOfPricingVersion20(AddLinkToAssistant) Export
	
	SubsystemVersion20 = "11.0";
	SubsystemVersion25 = "11.5";
	ApplicationVersion = "11.6.2";
	SubsystemVersion20 = "2.0";
	SubsystemVersion25 = "2.5";
	ApplicationVersion = "2.6.2";
	MessageTitle = StrTemplate(
		NStr("ru = 'Внимание! Функциональность ""Ценообразование версии %1""';
			|vi = 'Внимание! Функциональность ""Ценообразование версии %1""';
			|en = 'Внимание! Функциональность ""Ценообразование версии %1""'; fa = 'Внимание! Функциональность ""Ценообразование версии %1""';
			|it = 'Внимание! Функциональность ""Ценообразование версии %1""';
			|pl = 'Внимание! Функциональность ""Ценообразование версии %1""';
			|tr = 'Внимание! Функциональность ""Ценообразование версии %1""'")
			+ " "
			+ NStr("ru = 'устарела и будет удалена в версии программы %2.';
					|vi = 'устарела и будет удалена в версии программы %2.';
					|en = 'устарела и будет удалена в версии программы %2.'; fa = 'устарела и будет удалена в версии программы %2.';
					|it = 'устарела и будет удалена в версии программы %2.';
					|pl = 'устарела и будет удалена в версии программы %2.';
					|tr = 'устарела и будет удалена в версии программы %2.'")
			+ " "
			+ NStr("ru = 'Пожалуйста, перейдите на ценообразование версии %3.';
					|vi = 'Пожалуйста, перейдите на ценообразование версии %3.';
					|en = 'Пожалуйста, перейдите на ценообразование версии %3.'; fa = 'Пожалуйста, перейдите на ценообразование версии %3.';
					|it = 'Пожалуйста, перейдите на ценообразование версии %3.';
					|pl = 'Пожалуйста, перейдите на ценообразование версии %3.';
					|tr = 'Пожалуйста, перейдите на ценообразование версии %3.'"),
		SubsystemVersion20,
		ApplicationVersion,
		SubsystemVersion25);
	
	FormattedStrings = New Array;
	FormattedStrings.Add(New FormattedString(PictureLib.Warning));
	FormattedStrings.Add("  ");
	FormattedStrings.Add(New FormattedString(MessageTitle));
	
	If AddLinkToAssistant
		And Users.IsFullUser() Then
		
		LinkToOpeningAssistant = "e1cib/app/DataProcessor.AssistantOfMigrationToPriceManagementSystemVersion25";
		
		FormattedStrings.Add(" ");
		FormattedStrings.Add(New FormattedString(NStr("ru = 'Для этого следует воспользоваться';
														|vi = 'Для этого следует воспользоваться';
														|en = 'Для этого следует воспользоваться'; fa = 'Для этого следует воспользоваться';
														|it = 'Для этого следует воспользоваться';
														|pl = 'Для этого следует воспользоваться';
														|tr = 'Для этого следует воспользоваться'")));
		FormattedStrings.Add(" ");
		FormattedStrings.Add(New FormattedString(NStr("ru = 'помощником';
														|vi = 'помощником';
														|en = 'помощником'; fa = 'помощником';
														|it = 'помощником';
														|pl = 'помощником';
														|tr = 'помощником'"),,,,
			LinkToOpeningAssistant));
		FormattedStrings.Add(".");
		
	EndIf;
	
	Return New FormattedString(FormattedStrings);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Price type price list.
// 
// Parameters:
//  PriceIncludesVAT - Undefined, Boolean - Price includes VAT
// 
// Returns:
//  Undefined, Arbitrary - Price Type Price List
Function PriceTypePriceList_(PriceIncludesVAT = Undefined) Export

	If GetFunctionalOption("UseSeveralPriceTypes") Then
		Return Undefined;
	Else
		Return PriceManagementSystem.PriceTypePriceList_(PriceIncludesVAT);
	EndIf;

EndFunction

// Returns the date of switching to pricing version 2.5.
// the date may be empty , which means that pricing version 2.5 is enabled for all periods.
//
// Returns:
//	Date - the beginning of the day of the transition to pricing version 2.5.
//
Function DateOfTransitionToPricingVersion25() Export
	
	DateOfTransitionToPricingVersion25 = BegOfDay(Constants.DateOfMigrationToPriceManagementSystem25.Get());
	
	Return DateOfTransitionToPricingVersion25;
	
EndFunction

// Get the scheme according to the pricing version.
// 
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - 
//  ChangeNameOfSet - Boolean - True, delete the postfix
Procedure GetPricingScheme(DataCompositionSchema, ChangeNameOfSet = False) Export
	UsePriceManagementSystem25 = UsePriceManagementSystem25();
	cntOfSets = DataCompositionSchema.DataSets.Count()-1;
	If cntOfSets > 0 Then
		While cntOfSets >= 0 Do
			Set = DataCompositionSchema.DataSets[cntOfSets];//DataCompositionSchemaDataSetObject
			If UsePriceManagementSystem25 Then
				If StrFind(Set.Name, "25", SearchDirection.FromEnd) = 0  Then
					DataCompositionSchema.DataSets.Delete(Set);
				ElsIf ChangeNameOfSet Then
					Set.Name = StrReplace(Set.Name, "25", "");
				EndIf;
			Else	
				If Not StrFind(Set.Name, "25", SearchDirection.FromEnd) = 0  Then
					DataCompositionSchema.DataSets.Delete(Set);
				EndIf;
			EndIf;	
			cntOfSets = cntOfSets - 1;
		EndDo;
	EndIf;
EndProcedure

// Determines whether the price needs to be recalculated when the series changes.
// 
// Parameters:
//  Products - CatalogRef.Products - verification nomenclature
//  AttributeName - String - "Series" or "Packaging". the name of the changed props
//  Date - Undefined, Date - Date of verification
// 
// Returns:
//  Boolean - True, It is necessary to recalculate the prices
Function ItIsNecessaryToRecalculatePriceWhenChanging(Products, AttributeName, Date) Export

	RecalculationIsNecessary = False;
	
	If Not UsePriceManagementSystem25(Date) Then
		Return RecalculationIsNecessary;
	EndIf;
	
	QueryText = "SELECT
	|	&RecalculationIsNecessary AS RecalculationIsNecessary
	|FROM
	|	Catalog.Products AS Products
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON Products.ProductKind = ItemKinds.Ref
	|WHERE
	|	Products.Ref = &ProductsLink";
	
	If AttributeName = "Series" Then
		ReplacementString = "CASE
						|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
						|			THEN FALSE
						|		ELSE TRUE
						|	END";
	ElsIf AttributeName = "Package" Then
		ReplacementString = "CASE
						|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
						|			THEN FALSE
						|		ELSE TRUE
						|	END";
	Else
		Return RecalculationIsNecessary;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&RecalculationIsNecessary", ReplacementString);
	
	Query = New Query(QueryText);
	Query.SetParameter("ProductsLink", Products);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		RecalculationIsNecessary = Selection.RecalculationIsNecessary;
	Else
		RecalculationIsNecessary = False;
	EndIf;
	
	Return RecalculationIsNecessary;

EndFunction

#EndRegion
