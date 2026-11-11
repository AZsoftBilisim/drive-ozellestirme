#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DeletionMark And TypeOf(Owner) = Type("CatalogRef.BudgetProfiles")
		And Not BudgetReportingServerCached.ItemMarkedForDeletion_(Owner) Then
		If TypeOf(Owner) = Type("CatalogRef.BudgetProfiles") Then
			ExceptionText = NStr("vi = 'Để xóa các phần tử trong báo cáo tài chính, hãy đặt dấu xóa
									|phần tử danh mục đối tượng chủ ""Dạng ngân sách""';
									|ru = 'Для удаления элементов финансовой отчетности пометьте на удаление
									|элемент справочника-владельца ""Виды бюджетов""';
									|en = 'To delete financial statement items, mark for deletion
									|the item of the ""Budget profiles"" directory-owner'; fa = 'To delete financial statement items, mark for deletion
									|the item of the ""Budget profiles"" directory-owner';
									|it = 'Per eliminare elementi del reporting finanziario selezionare da cancellare
									|l''elemento dell''informatore del proprietario ""Tipi di budget""';
									|pl = 'Aby usunąć elementy sprawozdawczości finansowej zaznacz na usuwanie
									|element przewodnika-właściciela ""Rodzaje budżetów""';
									|tr = 'Silineceklere eklenen finansal raporlama öğelerinin silinmeleri için
									|""Bütçe profili"" sahip dizini öğesi'");
		Else
			ExceptionText = NStr("vi = 'Để xóa các phần tử trong báo cáo tài chính, hãy đặt dấu xóa
									|phần tử danh mục đối tượng chủ ""Dạng báo cáo""';
									|ru = 'Для удаления элементов финансовой отчетности пометьте на удаление
									|элемент справочника-владельца ""Виды отчетов""';
									|en = 'To delete financial statement items, mark for deletion
									|the item of the ""Report types"" owner catalog'; fa = 'To delete financial statement items, mark for deletion
									|the item of the ""Report types"" owner catalog';
									|it = 'Per eliminare elementi del reporting finanziario selezionare da cancellare
									|l''elemento dell''informatore del proprietario ""Tipi di budget""';
									|pl = 'Aby usunąć elementy sprawozdawczości finansowej zaznacz na usuwanie
									|element przewodnika-właściciela ""Rodzaje sprawozdawczości""';
									|tr = 'Silineceklere eklenen finansal raporlama öğelerinin silinmeleri için
									|""Bütçe profili"" sahip dizini öğesi'");
		EndIf;
		Raise ExceptionText;
	EndIf;
	
	Description = "" + ItemKind + ": " + NameForPrinting + ", ";
	For Each AdditionalAttribute In ItemKindAttributes Do
		If Not ValueIsFilled(AdditionalAttribute.Value) Then
			Continue;
		EndIf;
		Description = Description + AdditionalAttribute.Value + ", ";
	EndDo;
	
	Description = Left(Description, StrLen(Description) - 2);
	
	If TypeOf(Owner) = Type("CatalogRef.BudgetProfiles") Then
		SetBudgetViewSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private


// LongDesc
// 
// Parameters:
// 	Attributes - See FinancialReportingClientServer.ReportElementStructure
// Returns:
// 	DataCompositionSettingsComposer - 
Function ComposerSettingsWhenSettingSelectionSettings(Attributes)
	Composer = Undefined;
	Catalogs.FinancialReportItems.SetFilterSettings(Attributes, Composer, ItemKind, AdditionalSelection);
	Return Composer;
EndFunction

Procedure SetBudgetViewSettings()
	
	Attributes = Common.ObjectAttributesValues(Owner, 
			"UseToEnterPlan, HeaderDimensions");
	UseToEnterPlan = Attributes.UseToEnterPlan;
	TypesOfAnalyticsCaps = Attributes.HeaderDimensions.Unload();
	
	ParentView = Common.ObjectAttributeValue(Parent, "ItemKind");
	
	If ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		// If the element is subordinate to a derived indicator or budget item, then
		// this is the operand of the formula.
		// Filters can also be based on budget items and indicators with configured calculation rules.
		ResetUseOfFilters = False;
		
		If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			If Not ParentView = Enums.FinancialReportItemKinds.DerivedItem
				And Not ParentView = Enums.FinancialReportItemKinds.BudgetFlowItem
				And CalculationsRules.Count() = 0 Then
				
				ResetUseOfFilters = UseToEnterPlan;
				
			EndIf;
		EndIf;
		
		If ResetUseOfFilters Then
			FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
				"UseFilterByCompany", False);
			FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
				"UseFilterByDepartment", False);
			FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
				"UseFilterScenario", False);
			FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
				"UseStatusFilter", False);
		EndIf;
		
		Attributes = FinancialReportingClientServer.ReportElementStructure();
		FillPropertyValues(Attributes, ThisObject);
		Attributes.Insert("BudgetFlowItem", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "BudgetFlowItem"));
		Attributes.Insert("BudgetBalanceItem", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "BudgetBalanceItem"));
		Attributes.Insert("NonFinancialItem", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "NonFinancialItem"));
		Attributes.Insert("UseFilterByCompany", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "UseFilterByCompany") = True);
		Attributes.Insert("UseFilterByDepartment", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "UseFilterByDepartment") = True);
		Attributes.Insert("UseFilterScenario", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "UseFilterScenario") = True);
		Attributes.Insert("UseStatusFilter", 
			FinancialReportingServerCall.ValueOfAdditionalProps(ThisObject, "UseStatusFilter") = True);
		Attributes.Insert("UUID", New UUID());
		
		Composer = ComposerSettingsWhenSettingSelectionSettings(Attributes);
		
		ItemsList = New Array;
		If ResetUseOfFilters And CalculationsRules.Count() = 0 Then
			Composer.Settings.Filter.Items.Clear();
		EndIf;
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		
		If ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			AttributesNames = "ByCompanies, ByBusinessUnits, ByScenarios";
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				AttributesNames = AttributesNames + ", DimensionKind" + DimensionNumber;
			EndDo;
			NFPDetails = Common.ObjectAttributesValues(Attributes.NonFinancialItem, AttributesNames);
		EndIf;
		
		If Not Attributes.UseFilterByCompany Then
			BudgetReportingCacheCalculationServer.FindSelectionByName(Composer.Settings, "Organization", ItemsList);
			If ItemKind <> Enums.FinancialReportItemKinds.NonFinancialItem
				Or NFPDetails.ByCompanies Then
				FinancialReportingServer.SetFilter(Composer.Settings.Filter, "Organization", 
					"<FillIn_organization>", DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		If Not Attributes.UseFilterByDepartment Then
			BudgetReportingCacheCalculationServer.FindSelectionByName(Composer.Settings, "Department", ItemsList);
			If ItemKind <> Enums.FinancialReportItemKinds.NonFinancialItem
				Or NFPDetails.ByBusinessUnits Then
				FinancialReportingServer.SetFilter(Composer.Settings.Filter, "Department", 
					"<FillIn_district>", DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		If Not Attributes.UseFilterScenario Then
			BudgetReportingCacheCalculationServer.FindSelectionByName(Composer.Settings, "Scenario", ItemsList);
			If ItemKind <> Enums.FinancialReportItemKinds.NonFinancialItem
				Or NFPDetails.ByScenarios Then
				FinancialReportingServer.SetFilter(Composer.Settings.Filter, "Scenario", 
					"<FillIn_scene>", DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		FinancialReportingServer.SetFilter(Composer.Settings.Filter, "StorageCurrency", 
										"<FillInStorage_value>", DataCompositionComparisonType.Equal);
					
		For Each Selection In TypesOfAnalyticsCaps Do
			FieldName = FinancialReportingCached.NameOfBudgetReportField(Selection.DimensionKind);
			If ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
				NFPContainsAnalyticsCaps = False;
				For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
					If NFPDetails["DimensionKind" + DimensionNumber] = Selection.DimensionKind Then
						NFPContainsAnalyticsCaps = True;
						Break;
					EndIf;
				EndDo;
				If Not NFPContainsAnalyticsCaps Then
					Continue;
				EndIf;
			EndIf;
			
			FilterElement = FinancialReportingServer.FindSelectionElement(Composer.Settings.Filter, FieldName);
			If FilterElement = Undefined Or Not FilterElement.Use Then
				FinancialReportingServer.SetFilter(Composer.Settings.Filter, FieldName, "<FillIn" + FieldName + ">", DataCompositionComparisonType.Equal);
			EndIf;
		EndDo;
		
		BudgetReportingCacheCalculationServer.FindSelectionByName(Composer.Settings, "", ItemsList);
		
		For Each ElementToDelete In ItemsList Do
			Composer.Settings.Filter.Items.Delete(ElementToDelete);
		EndDo;
		
		AdditionalSelection = New ValueStorage(Composer.Settings);
		
	EndIf;
	
	If UseToEnterPlan Then
		
		If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			// If an element is subordinate to a derived indicator or budget item, then
			// this is the operand of the formula.
			If Not ParentView = Enums.FinancialReportItemKinds.DerivedItem
				And Not ParentView = Enums.FinancialReportItemKinds.BudgetFlowItem Then
				
				PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
				
				FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
					"LowerBoundOfData",
					PeriodVariables.DataPeriodStart.Name);
				FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
					"UpperBoundOfData",
					PeriodVariables.DataPeriodEnd.Name);
				FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
					"GroupingPeriodStart",
					PeriodVariables.PeriodOfGrouping.Name);
				FinancialReportingServerCall.SetValueOfAdditionalProps(ThisObject,
					"GroupingPeriodEnd",
					PeriodVariables.PeriodOfGrouping.Name);
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf