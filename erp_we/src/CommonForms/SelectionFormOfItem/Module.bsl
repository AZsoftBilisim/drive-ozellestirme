
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetDynamicListParameters();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AssetLiability = Undefined;
	If Parameters.Property("ChoiceParameters") Then
		
		ChoiceParameters = Parameters.ChoiceParameters; // FixedArray of ChoiceParameter
		For Each ChoiceParameter In ChoiceParameters Do
		
			If ChoiceParameter.Name = "Filter.BusinessOperation" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					FilterBusinessTransactionsForExpenseItems = ChoiceParameter.Value;
					CommonClientServer.SetDynamicListFilterItem(
						ExpenseItems,
						"Ref",
						ItemsOfExpensesWithSelectionForEconomicOperations(FilterBusinessTransactionsForExpenseItems),
						DataCompositionComparisonType.InList,,
						True);
				EndIf;
				
			EndIf;
			
			If ChoiceParameter.Name = "Filter.CostAllocationOptionManag"
			 Or ChoiceParameter.Name = "Filter.CostAllocationOption" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					CommonClientServer.SetDynamicListFilterItem(
						ExpenseItems,
						"CostAllocationOptionManag",
						ChoiceParameter.Value,
						DataCompositionComparisonType.InList,,
						True);
				EndIf;
				
			EndIf;
			
			If ChoiceParameter.Name = "Filter.CostAllocationOptionLocal"
			 Or ChoiceParameter.Name = "Filter.CostAllocationOption" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					CommonClientServer.SetDynamicListFilterItem(
						ExpenseItems,
						"CostAllocationOptionLocal",
						ChoiceParameter.Value,
						DataCompositionComparisonType.InList,,
						True);	
				EndIf;
				
			EndIf;
			
			If ChoiceParameter.Name = "Filter.CostAllocationOptionTax"
			 Or ChoiceParameter.Name = "Filter.CostAllocationOption" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					DistributionOptions = New Array();
					DistributionOptions.Add(ChoiceParameter.Value);
					DistributionOptions.Add(Enums.CostAllocationOptions.EmptyRef());
					CommonClientServer.SetDynamicListFilterItem(
						ExpenseItems,
						"CostAllocationOptionTax",
						DistributionOptions,
						DataCompositionComparisonType.InList,,
						True);	
				EndIf;
				
			EndIf;
				
			If ChoiceParameter.Name = "Filter.CostSharingOptionOr" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					FilterGroup = CommonClientServer.CreateFilterItemGroup(
						ExpenseItems.SettingsComposer.FixedSettings.Filter.Items,
						NStr("vi = 'Phương án phân bổ chi phí';
							|ru = 'Варианты распределения расходов';
							|en = 'Expense allocation options'; fa = 'گزینه‌های تسهیم هزینه';
							|it = 'Variante di allocazione delle spese';
							|pl = 'Warianty przydziału kosztów';
							|tr = 'Gider dağıtım seçenekleri'"), 
						DataCompositionFilterItemsGroupType.OrGroup);
					CommonClientServer.SetFilterItem(
						FilterGroup,
						"CostAllocationOptionManag",
						ChoiceParameter.Value, 
						DataCompositionComparisonType.InList,
						"CostAllocationOptionManag",
						True);
					CommonClientServer.SetFilterItem(
						FilterGroup,
						"CostAllocationOptionLocal",
						ChoiceParameter.Value, 
						DataCompositionComparisonType.InList,
						"CostAllocationOptionLocal",
						True);
					CommonClientServer.SetFilterItem(
						FilterGroup,
						"CostAllocationOptionTax",
						ChoiceParameter.Value, 
						DataCompositionComparisonType.InList,
						"CostAllocationOptionTax",
						True);
				EndIf;
				
			EndIf;
		
			If ChoiceParameter.Name = "Filter.ActivityTypeForTaxAccountingOfCosts" Then
				
				If ValueIsFilled(ChoiceParameter.Value) Then
					CommonClientServer.SetDynamicListFilterItem(
						ExpenseItems,
						"ActivityTypeForTaxAccountingOfCosts",
						ChoiceParameter.Value,
						DataCompositionComparisonType.InList,,
						True);
				EndIf;
				
			EndIf;
			
			If ChoiceParameter.Name = "Filter.ExpensesOnAssets" Then
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"ExpensesOnAssets",
					ChoiceParameter.Value,
					DataCompositionComparisonType.Equal,,
					True);
				
			EndIf;
			
			If ChoiceParameter.Name = "Filter.ExpensesOnConstructionObjects" Then
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"ExpensesOnConstructionObjects",
					ChoiceParameter.Value,
					DataCompositionComparisonType.Equal,,
					True);
				
			EndIf;
			
			If ChoiceParameter.Name = "AccountAsGroupFA"
				And ChoiceParameter.Value = True Then
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"ExpensesOnAssets",
					True,
					DataCompositionComparisonType.Equal,,
					True);
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"ExpensesOccur",
					Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue,
					DataCompositionComparisonType.Equal,,
					True);
					
			EndIf;
			
			If ChoiceParameter.Name = "Filter.EnteredInTaxAccounting" Then
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"EnteredInTaxAccounting",
					ChoiceParameter.Value,
					DataCompositionComparisonType.Equal,,
					True);
				
			EndIf;

			If ChoiceParameter.Name = "Filter.ExpenseTypeCategory" Then
				
				CommonClientServer.SetDynamicListFilterItem(
					ExpenseItems,
					"ExpenseTypeCategory",
					ChoiceParameter.Value,
					DataCompositionComparisonType.Equal,,
					True);
				
			EndIf;

			If ChoiceParameter.Name = "Filter.AssetLiability" Then
				If ValueIsFilled(ChoiceParameter.Value) Then
					AssetLiability = ChoiceParameter.Value;
				EndIf;
			EndIf;
			
			If ChoiceParameter.Name = "AddExpenseItems" And ChoiceParameter.Value Then
				SelectExpenseItems = True;
			EndIf;
			
			If ChoiceParameter.Name = "AddIncomeItems" And ChoiceParameter.Value Then
				SelectIncomeItems = True;
			EndIf;
			
			If ChoiceParameter.Name = "AddItemsOfAssetsLiabilities" And ChoiceParameter.Value Then
				SelectItemsOfAssetsLiabilities = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Parameters.Property("TypeRestriction") And ValueIsFilled(Parameters.TypeRestriction) Then
		TypeRestriction = Parameters.TypeRestriction; 
		If SelectExpenseItems 
			And Not TypeRestriction.ContainsType(Type("ChartOfCharacteristicTypesRef.ExpenseItems")) Then
			SelectExpenseItems = False;
		EndIf;
		If SelectIncomeItems 
			And Not TypeRestriction.ContainsType(Type("ChartOfCharacteristicTypesRef.IncomeItems")) Then
			SelectIncomeItems = False;
		EndIf;
		If SelectItemsOfAssetsLiabilities 
			And Not TypeRestriction.ContainsType(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems")) Then
			SelectItemsOfAssetsLiabilities = False;
		EndIf;
	EndIf;
	
	AssetLiabilityItems.Parameters.SetParameterValue("ArticleActivity", AssetLiability);
	AssetLiabilityItems.Parameters.SetParameterValue("NoLimitOnTheAssetLiability", Not ValueIsFilled(AssetLiability));
	AssetLiabilityItems.Parameters.SetParameterValue("OtherAssetsAndLiabilitiesRecords", Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	
	If Parameters.Property("AssetRef", AssetRef) Then
		
		If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
			ChoiceMode = 0;
			Items.ExpenseItems.CurrentRow = AssetRef;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
			ChoiceMode = 1;
			Items.IncomeItems.CurrentRow = AssetRef;
		Else
			ChoiceMode = 2;
			Items.AssetLiabilityItems.CurrentRow = AssetRef;
		EndIf;
	EndIf;
	
	ConfigureSelectionMode();
	FormControl();
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject, "AssetLiabilityItems");
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject, "IncomeItems");
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject, "ExpenseItems");
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ExpenseItem" And Not FilterBusinessTransactionsForExpenseItems.IsEmpty() Then
		CommonClientServer.SetDynamicListFilterItem(
			ExpenseItems,
			"Ref",
			ItemsOfExpensesWithSelectionForEconomicOperations(FilterBusinessTransactionsForExpenseItems),
			DataCompositionComparisonType.InList,,
			True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExpenseItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ExpenseItem = Items.ExpenseItems.CurrentRow;
	If ValueIsFilled(ExpenseItem) 
	 And Not Items.ExpenseItems.RowData(ExpenseItem).IsFolder Then
		StandardProcessing = False;
		NotifyChoice(ExpenseItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomeItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	IncomeItem = Items.IncomeItems.CurrentRow;
	If Not Items.IncomeItems.RowData(IncomeItem).IsFolder Then
		StandardProcessing = False;
		NotifyChoice(IncomeItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssetLiabilityItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	AssetAndLiabilityItem = Items.AssetLiabilityItems.CurrentRow;
	If Not Items.AssetLiabilityItems.RowData(AssetAndLiabilityItem).IsFolder Then
		StandardProcessing = False;
		NotifyChoice(AssetAndLiabilityItem);
	EndIf;

EndProcedure

&AtClient
Procedure SelectExpenseItem(Command)
	
	SelectArticle("ExpenseItems");
	
EndProcedure

&AtClient
Procedure SelectIncomeItem(Command)
	
	SelectArticle("IncomeItems");
	
EndProcedure

&AtClient
Procedure SelectAnItemOfAssetsLiabilities(Command)
	
	SelectArticle("AssetLiabilityItems");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectArticle(TableName)
	
	CurrentRow = Items[TableName].CurrentRow; 
	
	If CurrentRow = Undefined Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
								|ru = 'Команда не может быть выполнена для указанного объекта.';
								|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
								|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
								|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
								|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	// The Cur line is full, but there is no line data.
	// This situation occurs when you enter a line in the search bar and click on the "Select"
	// button until the output of the filtered values is complete. 
	If Items[TableName].RowData(CurrentRow) = Undefined Then
		Return;
	EndIf;
	
	If Items[TableName].RowData(CurrentRow).IsFolder Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn phần tử, mà không phải nhóm.';
								|ru = 'Выберите элемент, а не группу.';
								|en = 'Select an item, not a group.'; fa = 'Select an item, not a group.';
								|it = 'Scegliete un elemento, e non un gruppo';
								|pl = 'Wybierz element, a nie grupę.';
								|tr = 'Grup değil, öğe seç.'"));
		Return;
	EndIf;
	
	NotifyChoice(CurrentRow);
	
EndProcedure

&AtServer
Procedure SetDynamicListParameters()
	
	CommonClientServer.SetDynamicListFilterItem(
			ExpenseItems,
			"Ref",
			ChartsOfCharacteristicTypes.ExpenseItems.BlockedExpenditureItems(),
			DataCompositionComparisonType.NotInList);
		
	CommonClientServer.SetDynamicListFilterItem(
			IncomeItems,
			"Ref",
			ChartsOfCharacteristicTypes.IncomeItems.BlockedRevenueItems(),
			DataCompositionComparisonType.NotInList);
			
	CommonClientServer.SetDynamicListFilterItem(
			AssetLiabilityItems,
			"Ref",
			ChartsOfCharacteristicTypes.AssetLiabilityItems.BlockedItemsOfAssetsLiabilities(),
			DataCompositionComparisonType.NotInList);
	
EndProcedure

&AtServer
Procedure FormControl()
	
	If ChoiceMode = 0 Then
		Items.GroupPages.CurrentPage = Items.ExpenseItemsGroup;
		Items.ExpenseItemsSelectButton.DefaultButton = True;
	ElsIf ChoiceMode = 1 Then
		Items.GroupPages.CurrentPage = Items.GroupItemsOfIncome;
		Items.RevenueItemsSelectButton.DefaultButton = True;
	Else
		Items.GroupPages.CurrentPage = Items.GroupItemsOfAssetsLiabilities;
		Items.ItemsOfAssetsLiabilitiesSelectButton.DefaultButton = True;
	EndIf;
	
	If Items.ChoiceMode.ChoiceList.Count() = 1 Then
		
		If ChoiceMode = 0 Then
			ThisForm.Title = NStr("vi = 'Dạng chi phí';
									|ru = 'Статьи расходов';
									|en = 'Expense items'; fa = 'اقلام هزینه';
									|it = 'Voci di spese';
									|pl = 'Pozycje rozchodów';
									|tr = 'Gider kalemleri'");
		ElsIf ChoiceMode = 1 Then
			ThisForm.Title = NStr("vi = 'Dạng thu nhập';
									|ru = 'Статьи доходов';
									|en = 'Income items'; fa = 'اقلام درآمد';
									|it = 'Voci di entrate';
									|pl = 'Pozycje przychodów';
									|tr = 'Gelir kalemleri'");
		Else
			ThisForm.Title = NStr("vi = 'Dạng tài sản /nguồn vốn';
									|ru = 'Статьи активов/пассивов';
									|en = 'Asset/liability items'; fa = 'اقلام دارایی/بدهی';
									|it = 'Voci di attivi passivi';
									|pl = 'Pozycje aktywów/pasywów';
									|tr = 'Varlık/yükümlülük kalemleri'");
		EndIf;
	Else
		ThisForm.Title = NStr("vi = 'Chọn dạng';
								|ru = 'Выбор статьи';
								|en = 'Select item'; fa = 'انتخاب قلم';
								|it = 'Selezionare una voce';
								|pl = 'Wybór pozycji';
								|tr = 'Kalem seçimi'");
	EndIf;
	
	ThisIsUTBasic = GetFunctionalOption("BaseVersion");
	If ThisIsUTBasic Then
		Items.ExpenseItemsCostAllocationOptionLocal.Title = NStr("vi = 'Phương án phân bổ';
																|ru = 'Вариант распределения';
																|en = 'Allocation option'; fa = 'گزینه تسهیم';
																|it = 'Opzione di ripartizione';
																|pl = 'Wersja pakietów instalacyjnych';
																|tr = 'Dağıtım seçeneği'");
		Items.ExpenseItemsCostAllocationOptionManag.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure ConfigureSelectionMode()
	
	ChoiceList = Items.ChoiceMode.ChoiceList;
	
	If Not SelectItemsOfAssetsLiabilities
			Or Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		ChoiceList.Delete(2);
	EndIf;
	
	If Not SelectIncomeItems
			Or Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		ChoiceList.Delete(1);
	EndIf;
	
	If Not SelectExpenseItems
			Or Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		ChoiceList.Delete(0);
	EndIf;
	
	Items.ChoiceMode.Visible =  (ChoiceList.Count() > 1);
	
	If ChoiceList.Count() = 1 Then
		ChoiceMode = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ItemsOfExpensesWithSelectionForEconomicOperations(BusinessOperation)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ExpenseItems.Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	(NOT ExpenseItems.RestrictUsageInBusinessTransactions
	|			OR ExpenseItems.IsFolder
	|			OR ExpenseItems.Ref IN
	|				(SELECT
	|					AvailableTransactions.Ref
	|				FROM
	|					ChartOfCharacteristicTypes.ExpenseItems.AvailableBusinessTransactions AS AvailableTransactions
	|				WHERE
	|					AvailableTransactions.BusinessOperation = &BusinessOperation))
	|	AND NOT ExpenseItems.Ref IN (&BlockedExpenditureItems)";
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("BlockedExpenditureItems", ChartsOfCharacteristicTypes.ExpenseItems.BlockedExpenditureItems().UnloadValues());
	ARTICLES__ = Query.Execute().Unload().UnloadColumn("Ref");
	Return ARTICLES__;
					
EndFunction

#EndRegion
