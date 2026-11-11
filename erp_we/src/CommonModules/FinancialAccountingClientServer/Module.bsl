#Region Public

// Returns the type of international accounting chart of accounts
// 
// Returns:
// 	Type - Type of the international accounting chart of accounts
//
Function TypeChartOfAccounts() Export
	
	Return Type("ChartOfAccountsRef.International");
		
EndFunction

// Returns the name of the international accounting chart of accounts. 
// 
// Returns:
// 	String - Name of the international accounting chart of accounts
//
Function ChartOfAccountsName() Export
	
	Return "International";
		
EndFunction

// Returns the type of international accounting subcontent types
// 
// Returns:
// 	Type - Type of types of subconto international accounting
//
Function TypeSpeciesExtdimension() Export
	
	Return Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes");
	
EndFunction

// It is intended for getting an empty value of the specified type:
//	primitive, or reference.
//
// Parameters:
//	PreassignedType - Type - The type to get an empty value for.
//
// Returns:
//	Arbitrary - An empty value of the specified type.
//
Function EmptyTypeValue(PreassignedType) Export

	If PreassignedType = Type("Number") Then
		Return 0;

	ElsIf PreassignedType = Type("String") Then
		Return "";

	ElsIf PreassignedType = Type("Date") Then
		Return '00010101000000';

	ElsIf PreassignedType = Type("Boolean") Then
		Return False;

	Else
		Return New (PreassignedType);

	EndIf;

EndFunction // Empty Type value();

// Defines the types of invoice refinement sources that correspond to the financial accounting group.
//
// Parameters:
//  FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups,
//							 Spravochnike.Groupsfinancialaccountsreferences,
//							 Spravochnike.Groupsfinancial accounting of non-monetary funds,
//                           Spravochnike.Groupfinancial accounting of income expenses - a group of financial accounting
//                               of the nomenclature, settlements with counterparties, cash, income/expenses.
//
// Returns:
//  Array - an array of enumeration values of the types of the sources of the calculation.
//
Function AccountSpecificationSourceTypes(FinancialAccountingGroup) Export

	SourcesTypes = New Array;
	If TypeOf(FinancialAccountingGroup) = Type("CatalogRef.InventoryAccountingGroups") Then
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProducts"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsDr"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsCr"));
	ElsIf TypeOf(FinancialAccountingGroup) = Type("CatalogRef.FinancialAccountingGroupsOfARAP") Then
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPDr"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPCr"));
	ElsIf TypeOf(FinancialAccountingGroup) = Type("CatalogRef.GroupsOfFinancialAccountingOfCash") Then
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCash"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashDr"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashCr"));
	ElsIf TypeOf(FinancialAccountingGroup) = Type("CatalogRef.IncomeExpensesAccountingGroups") Then
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpenses"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesDr"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesCr"));
	ElsIf TypeOf(FinancialAccountingGroup) = Type("CatalogRef.NonCurrentAssetsAccountingGroups") Then
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssets"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsDr"));
		SourcesTypes.Add(PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsCr"));
	EndIf; 
	
	Return SourcesTypes;

EndFunction

// Defines the name of the reference list of financial accounting groups based on the type of account refinement source.
//
// Parameters:
//  SourceType - EnumRef.AccountSpecificationSourceTypes - type of invoice refinement source.
//
// Returns:
//  String - the name of the directory.
//
Function NameOfFinancialAccountingGroupsCatalog(SourceType) Export

	CatalogName = "";
	If SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProducts")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsDr")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsCr") Then
		CatalogName = "InventoryAccountingGroups";
	ElsIf SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPDr")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPCr") Then
		CatalogName = "FinancialAccountingGroupsOfARAP";
	ElsIf SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCash")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashDr")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashCr") Then
		CatalogName = "GroupsOfFinancialAccountingOfCash";
	ElsIf SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpenses")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesDr")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesCr") Then
		CatalogName = "IncomeExpensesAccountingGroups";
	ElsIf SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssets")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsDr")
		Or SourceType = PredefinedValue("Enum.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsCr") Then
		CatalogName = "NonCurrentAssetsAccountingGroups";
	EndIf; 
	
	Return CatalogName;

EndFunction

// Copies data from the value tree form.
//
// Parameters:
//  Receiver - FormDataTree - the receiver tree.
//  Source - FormDataTree - source tree.
//  IncludeSubordinates - Boolean - True if it is necessary to recursively copy elements of the lower levels of the tree.
//
Procedure CopyFormDataTree(Receiver, Source, IncludeSubordinates) Export

	SourceItems = Source.GetItems();
	DestinationItems = Receiver.GetItems();
	For Each SourceElement_ In SourceItems Do
		ReceiverElement = DestinationItems.Add();
		FillPropertyValues(ReceiverElement, SourceElement_);
		If IncludeSubordinates Then
			CopyFormDataTree(ReceiverElement, SourceElement_, IncludeSubordinates = False);
		EndIf;
	EndDo;

EndProcedure

// Searches the value tree for the specified value in the specified column of the tree.
//
// Parameters:
//  FormDataTree - FormDataTree - the value tree.
//  AttributeValue - Arbitrary - target value.
//  AttributeName - String - name of the tree attribute whose value is to be found.
//  IncludeSubordinates - Boolean - True if it is necessary to search recursively among the elements of the lower levels of the tree.
// 
// Returns:
//  Undefined, ValueTreeRow - Find a tree element
//
Function FindTreeElement(FormDataTree, AttributeValue, AttributeName, IncludeSubordinates = False) Export

	TreeItems = FormDataTree.GetItems();
	For Each TreeItem In TreeItems Do
		If TreeItem[AttributeName] = AttributeValue Then
			Return TreeItem;
		Else
			If IncludeSubordinates Then
				FoundTreeElement = FindTreeElement(TreeItem, AttributeValue, AttributeName, IncludeSubordinates);
				If FoundTreeElement <> Undefined Then
					Return FoundTreeElement;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;

EndFunction

// Expands all nodes in the tree.
//
// Parameters:
//  Form - ClientApplicationForm - a form containing a tree of elements.
//  FormTableName - String - name of the form element containing the element tree.
//  FormDataTree - FormDataTree - the value tree itself.
//  IncludeSubordinates - Boolean - True if it is necessary to recursively expand elements of the lower levels of the tree.
//
Procedure ExpandTheTree(Form, FormTableName, FormDataTree, IncludeSubordinates = False) Export

	TreeItems = FormDataTree.GetItems();
	For Each TreeItem In TreeItems Do
		Form.Items[FormTableName].Expand(TreeItem.GetID(), IncludeSubordinates);
	EndDo;

EndProcedure

#EndRegion
