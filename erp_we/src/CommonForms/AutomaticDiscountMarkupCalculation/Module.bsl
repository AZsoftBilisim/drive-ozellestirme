
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AppliedDiscounts = GetFromTempStorage(Parameters.AddressInTempStorage); // See DiscountsMarkupsServer.CalculateDiscountMarkUpTree
	
	DiscountTree = AppliedDiscounts.DiscountTree.Copy(); // ValueTree
	DiscountTree.Columns.Add("PictureIndex",   New TypeDescription("Number"));
	DiscountTree.Columns.Add("Valid",        New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("ConditionsAreFulfilled", New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("Expand",  New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("ThisCondition",     New TypeDescription("Boolean"));
	DiscountTree.Columns.Add("Value",       New TypeDescription("CatalogRef.DiscountsMarkups, CatalogRef.DiscountMarkupTerms"));
	DiscountTree.Columns.Add("Presentation",  New TypeDescription("String"));
	
	CalculateInformationAboutCalculatingDiscountsForDocument(DiscountTree);
	
	// If there are no discounts for the appointment, we will change the title.
	If DiscountTree.Rows.FindRows(New Structure("Managed", True), True).Count() = 0 Then
		Items.LongDesc.Visible = False;
		Items.DescriptionNoDiscountsForAppointments.Visible = True;
	EndIf;
	
	ValueToFormAttribute(DiscountTree, "InformationOnDiscountCalculationForTheDocumentAsAWhole");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandTreeToConditionsRecursively(InformationOnDiscountCalculationForTheDocumentAsAWhole, Items.InformationOnDiscountCalculationForTheDocumentAsAWhole);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Calculate(Command)
	
	Close(ListOfAssignedDiscounts());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationOnDiscountCalculationForTheDocumentAsAWhole.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.AssignedByUser");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", New Color(0, 128, 0));
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationOnDiscountCalculationForTheDocumentAsAWhole.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.AssignedByUser");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", New Color(0, 127, 0));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationOnDiscountCalculationForTheDocumentAsAWhole.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.ConditionsAreFulfilled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", New Color(255, 0, 0));
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationOnDiscountCalculationForTheDocumentAsAWholeAssignedByUser.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Valid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationOnDiscountCalculationForTheDocumentAsAWholeAssignedByUser.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InformationAboutCalculatingDiscountsForTheDocumentAsAWholeValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.Ref");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InformationOnDiscountCalculationForTheDocumentAsAWhole.ThisCondition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chứng từ chứa hàng hóa được giảm giá (đánh dấu)';
													|ru = 'В документе есть товары на которые предоставляется скидка (наценка)';
													|en = 'In the document, there are goods for which a discount (markup) is provided'; fa = 'In the document, there are goods for which a discount (markup) is provided';
													|it = 'Nel documento ci sono merci per le quali è previsto uno sconto (markup)';
													|pl = 'W dokumencie istnieją wiersze pozycji, na które jest udzielany rabat (marża)';
													|tr = 'Belgede, indirim (zam) sağlanan ürünler var'"));
	
EndProcedure

#Region Other

// Parameters:
// 	DiscountTree - ValueTreeRow, ValueTree - Addl.Fields:
// 		* Ref - CatalogRef.DiscountsMarkups
// 		* PictureIndex - Number
// 		* Valid - Boolean
// 		* ConditionsAreFulfilled - Boolean
// 		* Expand - Boolean
// 		* ReadOnly - Boolean
// 		* ThisCondition - Boolean
// 		* Value - CatalogRef.DiscountsMarkups, CatalogRef.DiscountMarkupTerms -
// 		* Presentation - String
//
// Description of DerevoSkidok in the Discount Priceserver module.Formedeverescides
//
&AtServer
Procedure CalculateInformationAboutCalculatingDiscountsForDocument(DiscountTree)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			CalculateInformationAboutCalculatingDiscountsForDocument(TreeRow);
			
			TreeRow.PictureIndex = DiscountsMarkupsServer.GetImageIndexForGroup(TreeRow);
			TreeRow.Value       = TreeRow.Ref;
			TreeRow.Presentation  = String(TreeRow.Value);
			TreeRow.Expand  = True;
			TreeRow.ReadOnly         = True;
			TreeRow.AssignedByUser = False;
			
			For Each Page1 In TreeRow.Rows Do
				If Page1.Valid Then
					TreeRow.Valid        = True;
					TreeRow.ConditionsAreFulfilled = True;
					Break;
				EndIf;
			EndDo;
			
		Else
			
			TreeRow.PictureIndex = DiscountsMarkupsServer.GetImageIndexForDiscount(TreeRow);
			TreeRow.Value = TreeRow.Ref;
			TreeRow.Presentation = String(TreeRow.Value);
			If Not TreeRow.Managed Then
				TreeRow.ReadOnly   = True;
				TreeRow.AssignedByUser = False;
			EndIf;
			
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
				NewLineCondition.Valid        = StringCondition.Completed2;
				NewLineCondition.ConditionsAreFulfilled = StringCondition.Completed2;
				NewLineCondition.Ref           = TreeRow.Ref;
				NewLineCondition.ThisCondition       = True;
				NewLineCondition.PictureIndex   = -1;
				NewLineCondition.ReadOnly   = True;
				NewLineCondition.AssignedByUser = False;
				
				If Not NewLineCondition.Valid Then
					AllConditionsAreMet = False;
				EndIf;
				
			EndDo;
			
			If AllConditionsAreMet Then
				TreeRow.Valid = True;
				TreeRow.ConditionsAreFulfilled = True;
			Else
				TreeRow.ConditionsAreFulfilled = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function ListOfAssignedDiscounts()
	
	ManagedDiscounts = New ValueList;
	
	DiscountTree = FormAttributeToValue("InformationOnDiscountCalculationForTheDocumentAsAWhole");
	FoundRows = DiscountTree.Rows.FindRows(New Structure("AssignedByUser", True), True);
	For Each FoundRow In FoundRows Do
		ManagedDiscounts.Add(FoundRow.Value);
	EndDo;
	
	Return ManagedDiscounts;
	
EndFunction

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

#EndRegion

#EndRegion
