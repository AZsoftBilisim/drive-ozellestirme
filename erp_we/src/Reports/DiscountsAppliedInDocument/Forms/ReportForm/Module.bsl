
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("CommandParameter") Then
		Raise NStr("vi = 'Chỉ được mở báo cáo từ chứng từ.';
					|ru = 'Открытие отчета предусмотрено только из документов.';
					|en = 'The report can be opened only from documents.'; fa = 'The report can be opened only from documents.';
					|it = 'È possibile aprire il report solo tramite documenti.';
					|pl = 'Otwieranie raportu przewidziano tylko z dokumentów.';
					|tr = 'Rapor sadece belgelerden açılabilir.'");
	EndIf;
	
	DocumentRef = Parameters.CommandParameter;
	
	Generate();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Generate();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

// Parameters:
// 	DiscountTree - See DiscountsMarkupsServer.Calculate
// 	ArrayOfDiscounts - Array of ValueTreeRow - An array of rows from the discount/mark-up tree, including:
// 		* Ref - CatalogRef.DiscountsMarkups - 
&AtServer
Procedure RecursiveDiscountTraversal(DiscountTree, ArrayOfDiscounts)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			RecursiveDiscountTraversal(TreeRow, ArrayOfDiscounts);
			
		Else
			
			ArrayOfDiscounts.Add(TreeRow);
		
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure Generate()
	
	SpreadsheetDocument.Clear();
	
	DocumentObject = DocumentRef.GetObject();
	
	Template = Reports.DiscountsAppliedInDocument.GetTemplate("Template");
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = False;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoiceServices") Then
		TSName = "Services";
	Else
		TSName = "Goods";
	EndIf;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoice") Then
		
		TabularPartOfDocument = DocumentObject.Goods.Unload();
		TabularPartOfDocument.GroupBy("SalesOrder");
		
		If ValueIsFilled(DocumentObject.SalesOrder)
			Or (TabularPartOfDocument.Count() > 0 And ValueIsFilled(TabularPartOfDocument[0].SalesOrder)) Then
			SpreadsheetDocument.Put(Template.GetArea("ImplementationByCustomerOrder"));
			Return;
		EndIf;
		
		ParametersStructure1.SalesInExcessOfOrder = DocumentObject.OrderSales;
		
	EndIf;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoiceServices") Then
		
		TabularPartOfDocument = DocumentObject.Services.Unload();
		TabularPartOfDocument.GroupBy("SalesOrder");
		
		If ValueIsFilled(DocumentObject.SalesOrder)
			Or (TabularPartOfDocument.Count() > 0 And ValueIsFilled(TabularPartOfDocument[0].SalesOrder)) Then
			SpreadsheetDocument.Put(Template.GetArea("ActOfExecutedWorksOnOrderOfClient"));
			Return;
		EndIf;
		
	EndIf;
	
	UsingProductCharacteristics = GetFunctionalOption("UseItemVariants");
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(DocumentObject, ParametersStructure1);
	
	ArrayOfDiscounts = New Array; // See RecursiveDiscountTraversal.ArrayOfDiscounts
	RecursiveDiscountTraversal(AppliedDiscounts.DiscountTree, ArrayOfDiscounts);
	
	AreaProductHeader              = Template.GetArea("Header|Products");
	AreaHeaderCharacteristic            = Template.GetArea("Header|Characteristic");
	RegionHeaderDiscountMarkUp             = Template.GetArea("Header|DiscountMarkup");
	ConditionHeaderArea                   = Template.GetArea("Header|Condition");
	RegionHeaderTotal                     = Template.GetArea("Header|InTotal");
	
	ScopeAndProducts             = Template.GetArea("String|Products");
	ScopeAndCharacteristics           = Template.GetArea("String|Characteristic");
	AreaLineDiscountMarkUp            = Template.GetArea("String|DiscountMarkup");
	FieldStringConditionMet         = Template.GetArea("String|ConditionMet");
	FieldStringConditionNotMet       = Template.GetArea("String|ConditionIsNotFulfilled");
	FieldLineDiscountMarkUpCrossedOut  = Template.GetArea("String|DiscountMarkUpCrossedOut");
	FieldRowDiscountMarkUpNotAssigned = Template.GetArea("String|DiscountMarkUpIsNotAssigned");
	AreaRowDiscountMarkUpAssigned   = Template.GetArea("String|DiscountMarkUpAssigned");
	ScopeOfApplicationDiscountMarkUpDiscountMarkUpIsNotValidForJointApplication = Template.GetArea("String|DiscountMarkUpIsNotValidForJointUse");
	AreaRowTotal                    = Template.GetArea("String|InTotal");
	
	AreaTotalProducts              = Template.GetArea("LineTotal_|Products");
	AreaTotalCharacteristic            = Template.GetArea("LineTotal_|Characteristic");
	RegionTotalDiscountMarkUp             = Template.GetArea("LineTotal_|DiscountMarkup");
	AreaTotalCondition                   = Template.GetArea("LineTotal_|Condition");
	AreaTotalDiscountMarkUpCrossedOut   = Template.GetArea("LineTotal_|DiscountMarkUpCrossedOut");
	RegionTotalDiscountMarkUpNotAssigned  = Template.GetArea("LineTotal_|DiscountMarkUpIsNotAssigned");
	AreaTotalTotal                     = Template.GetArea("LineTotal_|InTotal");
	
	AreaLegend                        = Template.GetArea("Legend|Products");
	
	// The header of the report
	SpreadsheetDocument.Put(AreaProductHeader);
	If UsingProductCharacteristics Then
		SpreadsheetDocument.Join(AreaHeaderCharacteristic);
	EndIf;
	For Each TreeRow In ArrayOfDiscounts Do
		
		RegionHeaderDiscountMarkUp.Parameters.DiscountMarkup = TreeRow.Ref;
		SpreadsheetDocument.Join(RegionHeaderDiscountMarkUp);
		
		SpreadsheetDocument.StartColumnGroup("Conditions", False);
		For Each StringCondition In TreeRow.ConditionParameters_.TableOfConditions Do
			ConditionHeaderArea.Parameters.Condition = StringCondition.DiscountMarkupCondition;
			SpreadsheetDocument.Join(ConditionHeaderArea);
		EndDo;
		SpreadsheetDocument.EndColumnGroup();
		
	EndDo;
	SpreadsheetDocument.Join(RegionHeaderTotal);
	
	ComplianceWithConditions = New Map;
	
	DocumentObjectTablePart = DocumentObject[TSName]; // DocumentTabularSection.CustomerInvoice.Goods - specified for typing
	
	For Each LineProducts_ In DocumentObjectTablePart Do
		
		ScopeAndProducts.Parameters.Products = LineProducts_.Products;
		ScopeAndProducts.Parameters.LineNumber  = LineProducts_.LineNumber;
		SpreadsheetDocument.Put(ScopeAndProducts);
		If UsingProductCharacteristics Then
			ScopeAndCharacteristics.Parameters.Characteristic = LineProducts_.Characteristic;
			SpreadsheetDocument.Join(ScopeAndCharacteristics);
		EndIf;
		
		For Each TreeRow In ArrayOfDiscounts Do
			
			// Discount terms
			AllConditionsAreMet = True;
			For Each StringCondition In TreeRow.ConditionParameters_.TableOfConditions Do
				
				If StringCondition.ScopeOfRestriction = Enums.OptionsOfLimitationAreasOfDiscountsAndMarkups.AtRow Then
					FoundRowsInConditionValidationTable = TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Find(LineProducts_.ConnectionKey, "ConnectionKey");
					If FoundRowsInConditionValidationTable <> Undefined Then
						MatchingConditionsToColumnsInConditionVerificationTable = TreeRow.ConditionParameters_.ConditionsByLine.MatchingConditionsToColumnsInConditionVerificationTable; // Map
						NameOfColumn = MatchingConditionsToColumnsInConditionVerificationTable.Get(StringCondition.DiscountMarkupCondition);
						If NameOfColumn <> Undefined Then
							ConditionMet = FoundRowsInConditionValidationTable[NameOfColumn];
						EndIf;
					Else
						ConditionMet = False;
					EndIf;
				Else
					ConditionMet = StringCondition.Completed2;
				EndIf;
				ComplianceWithConditions.Insert(StringCondition.DiscountMarkupCondition, ConditionMet);
				
				If Not ConditionMet Then
					AllConditionsAreMet = False;
				EndIf;
				
			EndDo;
			
			// Discount amount
			FoundRow = TreeRow.CalculationResult2.Find(LineProducts_.ConnectionKey, "ConnectionKey");
			If FoundRow <> Undefined Then
				DiscountAmount = FoundRow.Sum;
			Else
				DiscountAmount = 0;
			EndIf;
			If AllConditionsAreMet Then
				If TreeRow.Managed And Not TreeRow.AssignedByUser Then
					FieldRowDiscountMarkUpNotAssigned.Parameters.Sum = DiscountAmount;
					SpreadsheetDocument.Join(FieldRowDiscountMarkUpNotAssigned);
				ElsIf TreeRow.Managed And TreeRow.AssignedByUser Then
					If DocumentObject.DiscountsMarkups.FindRows(New Structure("ConnectionKey, DiscountMarkup", LineProducts_.ConnectionKey, TreeRow.Ref)).Count() > 0 Then
						AreaRowDiscountMarkUpAssigned.Parameters.Sum = DiscountAmount;
						SpreadsheetDocument.Join(AreaRowDiscountMarkUpAssigned);
					Else
						ScopeOfApplicationDiscountMarkUpDiscountMarkUpIsNotValidForJointApplication.Parameters.Sum = DiscountAmount;
						SpreadsheetDocument.Join(ScopeOfApplicationDiscountMarkUpDiscountMarkUpIsNotValidForJointApplication);
					EndIf;
				Else
					If DocumentObject.DiscountsMarkups.FindRows(New Structure("ConnectionKey, DiscountMarkup", LineProducts_.ConnectionKey, TreeRow.Ref)).Count() > 0 Then
						AreaLineDiscountMarkUp.Parameters.Sum = DiscountAmount;
						SpreadsheetDocument.Join(AreaLineDiscountMarkUp);
					Else
						ScopeOfApplicationDiscountMarkUpDiscountMarkUpIsNotValidForJointApplication.Parameters.Sum = DiscountAmount;
						SpreadsheetDocument.Join(ScopeOfApplicationDiscountMarkUpDiscountMarkUpIsNotValidForJointApplication);
					EndIf;
				EndIf;
			Else
				FieldLineDiscountMarkUpCrossedOut.Parameters.Sum = DiscountAmount;
				SpreadsheetDocument.Join(FieldLineDiscountMarkUpCrossedOut);
			EndIf;
			
			// Discount conditions, continued
			For Each StringCondition In TreeRow.ConditionParameters_.TableOfConditions Do
				
				If ComplianceWithConditions.Get(StringCondition.DiscountMarkupCondition) Then
					SpreadsheetDocument.Join(FieldStringConditionMet);
				Else
					SpreadsheetDocument.Join(FieldStringConditionNotMet);
				EndIf;
				
			EndDo;
			
		EndDo;
		
		AreaRowTotal.Parameters.Sum = LineProducts_.DiscountMarkupAmount;
		SpreadsheetDocument.Join(AreaRowTotal);
		
	EndDo;
	
	// InTotal
	SpreadsheetDocument.Put(AreaTotalProducts);
	If UsingProductCharacteristics Then
		SpreadsheetDocument.Join(AreaTotalCharacteristic);
	EndIf;
	For Each TreeRow In ArrayOfDiscounts Do
		
		// Discount amount
		DiscountAmount = 0;
		FoundRows = DocumentObject.DiscountsMarkups.FindRows(New Structure("DiscountMarkup", TreeRow.Ref));
		For Each FoundRow In FoundRows Do
			DiscountAmount = DiscountAmount + FoundRow.Sum;
		EndDo;
		
		RegionTotalDiscountMarkUp.Parameters.Sum = DiscountAmount;
		SpreadsheetDocument.Join(RegionTotalDiscountMarkUp);
		
		// Discount conditions, continued
		For Each StringCondition In TreeRow.ConditionParameters_.TableOfConditions Do
			
			SpreadsheetDocument.Join(AreaTotalCondition);
			
		EndDo;
		
	EndDo;
	
	AreaTotalTotal.Parameters.Sum = DocumentObject[TSName].Total("DiscountMarkupAmount");
	SpreadsheetDocument.Join(AreaTotalTotal);
	
	SpreadsheetDocument.Put(AreaLegend);
	
EndProcedure

#EndRegion

#EndRegion
