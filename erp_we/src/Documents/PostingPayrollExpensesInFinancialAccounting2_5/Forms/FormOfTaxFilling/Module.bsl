
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Taxpayer", Taxpayer) Then
		Items.Taxpayer.Visible = False;
	Else
		Taxpayer = "Organization";
	EndIf;
	
	If Parameters.Property("SelectedLinesOnly")
		And Parameters.SelectedLinesOnly Then
		SelectedLinesOnly = 1;
	EndIf;
	
	FillInCalculationMethods();
	OtherTypesOfTaxes();
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaxTableOnChange(Item)
	OtherTypesOfTaxes();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTaxesKinds

&AtClient
Procedure TaxesKindsValueOnChange(Item)
	Items.TaxesKinds.CurrentData.Check = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Accept(Command)
	
	CalculationParameters = New Structure;
	
	CalculationParameters.Insert("TaxesKinds", New Map);
	For Each TableRow In TaxesKinds Do
		
		If Not TableRow.Check Then
			Continue;
		EndIf;
		
		TaxCalculationParameters = New Structure("EmployeeTax, CalculationMethod_2, Value");
		FillPropertyValues(TaxCalculationParameters, TableRow);
		TaxCalculationParameters.EmployeeTax = Taxpayer = "Employee";
		CalculationParameters.TaxesKinds.Insert(TableRow.TaxKind, TaxCalculationParameters);
		
	EndDo;
	
	CalculationParameters.Insert("SelectedLinesOnly", SelectedLinesOnly = 1);
	
	Close(CalculationParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Representations of payment methods
	
	For Each CalculationMethod_2 In CalculationMethods Do
		
		AppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = AppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.TaxesKindsCalculationMethod_2.Name);
		
		ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TaxesKinds.CalculationMethod_2");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = CalculationMethod_2.Value;
		
		AppearanceItem.Appearance.SetParameterValue("Text", CalculationMethod_2.Presentation);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInCalculationMethods()
	
	CalculationMethods.Clear();
	
	CalculationMethods.Add("AsAPercent", NStr("vi = 'Mức thuế, %';
												|ru = 'Ставка налога, %';
												|en = 'Tax rate, %'; fa = 'نرخ مالیات، درصد';
												|it = 'Aliquota d''imposta, %';
												|pl = 'Stawka podatku, %';
												|tr = 'Vergi oranı, %'"));
	
EndProcedure

&AtServer
Procedure OtherTypesOfTaxes()
	
	TaxesKinds.Clear();
	
	Query = New Query;
	Query.SetParameter("DeductedFromEmployeeWages", Taxpayer = "Employee");
	
	Query.Text =
	"SELECT
	|	TaxesKinds.Ref AS TaxKind
	|FROM
	|	Catalog.TaxContributionKinds AS TaxesKinds
	|WHERE
	|	TaxesKinds.DeductedFromEmployeeWages = &DeductedFromEmployeeWages";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = TaxesKinds.Add();
		NewRow.TaxKind = Selection.TaxKind;
		NewRow.CalculationMethod_2 = "AsAPercent";
	EndDo;
	
EndProcedure

#EndRegion