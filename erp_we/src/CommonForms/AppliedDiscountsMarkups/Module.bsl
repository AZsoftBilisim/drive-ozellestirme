
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DoNotDisplayInformationAboutManualDiscounts = False;
	If Parameters.Property("DoNotDisplayInformationAboutManualDiscounts") And Parameters.DoNotDisplayInformationAboutManualDiscounts Then
		DoNotDisplayInformationAboutManualDiscounts = True;
	EndIf;
	
	RightToViewDiscount                = AccessRight("View", Metadata.Catalogs.DiscountsMarkups);
	RightToViewProvisionConditions = AccessRight("View", Metadata.Catalogs.DiscountMarkupTerms);
	
	Items.Characteristic.Visible = Parameters.DisplayInformationAboutDiscountsByLine;
	Items.Products.Visible   = Parameters.DisplayInformationAboutDiscountsByLine;
	
	Items.ManualDiscount.Visible = GetFunctionalOption("UseDiscountAdjustmentsInSales") 
	                                     Or DoNotDisplayInformationAboutManualDiscounts;
	
	If DoNotDisplayInformationAboutManualDiscounts Then
		Items.GroupGreen.Visible = False;
		Items.GroupGreenStrikethrough.Visible = False;
	EndIf;
	
	Currency = Parameters.Object.Currency;
	
	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	
	If Parameters.DisplayInformationAboutDiscountsByLine Then
		
		Products   = Parameters.CurrentData.Products;
		Characteristic = Parameters.CurrentData.Characteristic;
		
		// The total discount amount includes the amount of automatic and manual discounts.
		DiscountAmount       = 0;
		ManualDiscount = Parameters.CurrentData.ManualDiscount;
		DiscountAmount       = DiscountAmount + ManualDiscount;
		
		Filter = New Structure("ConnectionKey", Parameters.CurrentData.ConnectionKey);
		For Each LineVtDiscountsMargins In Parameters.Object.DiscountsMarkups.FindRows(Filter) Do
			
			NewRow = AutomaticDiscounts.Add();
			FillPropertyValues(NewRow, LineVtDiscountsMargins);
			If Parameters.CurrentData.AmountWithoutADiscount <> 0 Then
				NewRow.Percent = 100 * LineVtDiscountsMargins.Sum / Parameters.CurrentData.AmountWithoutADiscount;
			EndIf;
			
			DiscountAmount = DiscountAmount + NewRow.Sum;
			
		EndDo;
		
	Else
		
		DiscountAmount       = 0;
		ManualDiscount = Parameters.Object.Goods.Total("ManualDiscount");
		DiscountAmount       = DiscountAmount + ManualDiscount + Parameters.Object.Goods.Total("DiscountMarkupAmount");
		
	EndIf;
	
	// The information can be displayed only after the direct calculation of discounts in the document.
	// After closing the form, this information is not saved.
	If ValueIsFilled(Parameters.AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		
		AppliedDiscounts = GetFromTempStorage(Parameters.AddressOfAppliedDiscountsInTheTemporaryStorage); // See DiscountsMarkupsServer.Calculate
		
		If Parameters.DisplayInformationAboutCalculatingDiscountsByLine Then
			GenerateInformationAboutCalculatingDiscountsByLine(AppliedDiscounts, Parameters.CurrentData.ConnectionKey);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandTreeToConditionsRecursively(InformationAboutLineDiscountCalculation, Items.InformationAboutLineDiscountCalculation);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInformationAboutLineDiscountCalculation

&AtClient
Procedure InformationAboutCalculatingDiscountsOnTheValueLineStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure InformationAboutCalculatingDiscountsOnTheValueLineClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure InformationAboutLineDiscountCalculationSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.InformationAboutLineDiscountCalculation.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisCondition Then
		If Not RightToViewProvisionConditions Then
			Return;
		EndIf;
	Else
		If Not RightToViewDiscount Then
			Return;
		EndIf;
	EndIf;
	
	ShowValue(Undefined, CurrentData.Value);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutLineDiscountCalculation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", New Color(0, 128, 0));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutLineDiscountCalculation.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.AssignedByUser");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.Valid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", New Color(0, 128, 0));
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutLineDiscountCalculation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.ConditionsAreFulfilled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutCalculatingDiscountsOnTheValueLine.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("InformationAboutLineDiscountCalculation.Ref");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.ThisCondition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue(
		"Text",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giảm giá được phép đối với %1';
				|ru = 'Скидка предоставляется на %1';
				|en = 'Discount is provided for %1'; fa = 'Discount is provided for %1';
				|it = 'Sconto disponibile su %1';
				|pl = 'Rabat jest udzielany na %1';
				|tr = '%1 indirim sağlanıyor'"),
			GetProductPresentationForConditionalAppearance()));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutCalculatingDiscountsForTheAmountLine.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationAboutLineDiscountCalculation.ThisCondition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

&AtServer
Function GetProductPresentationForConditionalAppearance()
	
	Presentation = "";
	
	If TypeOf(Parameters.CurrentData) = Type("Structure") Then
		ProductsLink   = Undefined;
		CharacteristicReference = Undefined;
		
		If Parameters.CurrentData.Property("Products", ProductsLink) = Undefined Then
			Return Presentation;
		EndIf;
		
		Parameters.CurrentData.Property("Characteristic", CharacteristicReference);
		
		Presentation = ProductsClientServer.ProductPresentation(ProductsLink, CharacteristicReference);
		
	EndIf;
	
	Return Presentation;
	
EndFunction

#Region Other

&AtClient
Procedure ExpandTreeToConditionsRecursively(TreeRow, FormItem)
	
	ItemsCollection = TreeRow.GetItems();
	For Each Item In ItemsCollection Do
	
		If Item.Expand Then
			FormItem.Expand(Item.GetID());
			ExpandTreeToConditionsRecursively(Item, FormItem);
		EndIf;
	
	EndDo;
	
EndProcedure

&AtServer
Procedure DecomposeIntoColumns(TreeRow, FoundRow)
	
	For Each DecryptionString In FoundRow.Details Do
		TreeRow.DiscountMarkupAmount = TreeRow.DiscountMarkupAmount + DecryptionString.Sum;
	EndDo;
	
EndProcedure

// Parameters:
// 	DiscountTree - ValueTreeRow, ValueTree - contains including:
// 		* Ref - CatalogRef.DiscountsMarkups
//
// Description of DerevoSkidok in the Discount Priceserver module.Formedeverescides
//
&AtServer
Procedure CalculateInformationAboutCalculatingDiscountsByLine(IncomingDiscountTree, DiscountTree, ConnectionKey)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			CalculateInformationAboutCalculatingDiscountsByLine(IncomingDiscountTree, TreeRow, ConnectionKey);
			
			TreeRow.PictureIndex = DiscountsMarkupsServer.GetImageIndexForGroup(TreeRow);
			TreeRow.Value = TreeRow.Ref;
			TreeRow.Presentation = String(TreeRow.Value);
			TreeRow.Expand = True;
			
			For Each Page1 In TreeRow.Rows Do
				If Page1.Valid Then
					TreeRow.Valid        = True;
					TreeRow.ConditionsAreFulfilled = True;
					Break;
				EndIf;
			EndDo;
			
			FoundRows = TreeRow.CalculationResult2.FindRows(New Structure("Valid, ConnectionKey", True, ConnectionKey));
			For Each FoundRow In FoundRows Do
				DecomposeIntoColumns(TreeRow, FoundRow);
			EndDo;
			
		Else
			
			TreeRow.PictureIndex = DiscountsMarkupsServer.GetImageIndexForDiscount(TreeRow);
			TreeRow.Value = TreeRow.Ref;
			TreeRow.Presentation = String(TreeRow.Value);
			
			AllConditionsAreMet = True;
			For Each StringCondition In TreeRow.ConditionParameters_.TableOfConditions Do
				
				NewLineCondition = TreeRow.Rows.Add();
				NewLineCondition.Value = StringCondition.DiscountMarkupCondition;
				If StringCondition.IndicatorValue <> Undefined Then
					NewLineCondition.Presentation = StrTemplate(NStr("vi = '%1 (Giá trị hiện tại: %2)';
																	|ru = '%1 (Текущее значение: %2)';
																	|en = '%1 (Current value: %2)'; fa = '%1 (Current value: %2)';
																	|it = '%1 (valore corrente: %2)';
																	|pl = '%1 (Bieżąca wartość: %2)';
																	|tr = '%1 (Mevcut değer: %2)'"), String(StringCondition.DiscountMarkupCondition), Format(StringCondition.IndicatorValue, "NZ=0"));
				Else
					NewLineCondition.Presentation = String(StringCondition.DiscountMarkupCondition);
				EndIf;
				NewLineCondition.Ref     = TreeRow.Ref;
				NewLineCondition.ThisCondition = True;
				
				If StringCondition.ScopeOfRestriction = Enums.OptionsOfLimitationAreasOfDiscountsAndMarkups.AtRow Then
					FoundRowsInConditionValidationTable = TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Find(ConnectionKey, "ConnectionKey");
					If FoundRowsInConditionValidationTable <> Undefined Then
						MatchingConditionsToColumnsInConditionVerificationTable = TreeRow.ConditionParameters_.ConditionsByLine.MatchingConditionsToColumnsInConditionVerificationTable;// Map
						NameOfColumn = MatchingConditionsToColumnsInConditionVerificationTable.Get(StringCondition.DiscountMarkupCondition);
						If NameOfColumn <> Undefined Then
							NewLineCondition.Valid = FoundRowsInConditionValidationTable[NameOfColumn];
						EndIf;
					EndIf;
				Else
					NewLineCondition.Valid = StringCondition.Completed2;
				EndIf;
				
				NewLineCondition.PictureIndex = -1;
				
				NewLineCondition.ConditionsAreFulfilled = NewLineCondition.Valid;
				If Not NewLineCondition.Valid Then
					AllConditionsAreMet = False;
				EndIf;
				
			EndDo;
			
			If AllConditionsAreMet Then
				If TreeRow.Managed Then
					TreeRow.Valid = TreeRow.AssignedByUser;
				Else
					TreeRow.Valid = True;
				EndIf;
				TreeRow.ConditionsAreFulfilled = True;
				
				If Not (TreeRow.Managed And Not TreeRow.AssignedByUser) Then
					If IncomingDiscountTree.TableDiscountsMarkups.FindRows(New Structure("ConnectionKey, DiscountMarkup", ConnectionKey, TreeRow.Ref)).Count() = 0 Then
						TreeRow.NotAppliedUnderSharedUseTerms = True;
					EndIf;
				EndIf;
				
			Else
				TreeRow.ConditionsAreFulfilled = False;
			EndIf;
			
			FoundRows = TreeRow.CalculationResult2.FindRows(New Structure("ConnectionKey", ConnectionKey));
			For Each FoundRow In FoundRows Do
				DecomposeIntoColumns(TreeRow, FoundRow);
			EndDo;
		
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateInformationAboutCalculatingDiscountsByLine(IncomingDiscountTree, ConnectionKey)
	
	DiscountTree = IncomingDiscountTree.DiscountTree.Copy(); // ValueTree
	DiscountTree.Columns.Add("PictureIndex",   New TypeDescription("Number"));
	DiscountTree.Columns.Add("Valid",        New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("ConditionsAreFulfilled", New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("NotAppliedUnderSharedUseTerms", New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("Expand",  New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("ThisCondition",     New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("Value",       New TypeDescription("CatalogRef.DiscountsMarkups, CatalogRef.DiscountMarkupTerms"));
	DiscountTree.Columns.Add("Presentation",  New TypeDescription("String"));
	DiscountTree.Columns.Add("DiscountMarkupAmount", New TypeDescription("Number"));
	
	CalculateInformationAboutCalculatingDiscountsByLine(IncomingDiscountTree, DiscountTree, ConnectionKey);
	
	ValueToFormAttribute(DiscountTree, "InformationAboutLineDiscountCalculation");
	
EndProcedure

#EndRegion

#EndRegion
