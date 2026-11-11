

#Region Public

// Puts the data of the passed report type row in the temporary storage of the form.
//
// Parameters:
//  ObjectToPlace - CatalogObject.FinancialReportItems, Structure - the object being placed.
//  StorageAddress - String, UUID - Temporary storage address
//  ClearRefs - Boolean - If true, the reference of the reference list item and the reference of the report owner will be cleared.
//  					When writing such a report element, a new link will be generated, so the placed element
//  					will be copied.
//
// Returns:
//   String   - The address of the item in the storage.
//
Function PlaceItemInStorage(ObjectToPlace, StorageAddress = Undefined, ClearRefs = False) Export
	
	ElementStructure = ReportElementData(ObjectToPlace);
	If ClearRefs Then
		ElementStructure.Ref = Undefined;
		ElementStructure.Owner = Undefined;
		
		Operands = New Array;
		For Each OperandString_ In ElementStructure.FormulaOperands Do
			If TypeOf(OperandString_.Operand) = Type("CatalogRef.FinancialReportItems") Then
				Operands.Add(OperandString_.Operand);
			EndIf;
		EndDo;
		If Operands.Count() = 0 Then
			AttributesValues = Undefined;
		Else 
			ItemsProperties  = FinancialReportingClientServer.ReportElementStructure();
			ReceivedValues = "";
			For Each KeyAndValue In ItemsProperties Do
				ReceivedValues = ReceivedValues + ?(ReceivedValues = "", "", ", ") + KeyAndValue.Key;
			EndDo; 
			AttributesValues = Common.ObjectsAttributesValues(Operands, ReceivedValues);
		EndIf;
		
		For Each OperandString_ In ElementStructure.FormulaOperands Do
			Data = ReportElementData(OperandString_.Operand, AttributesValues);
			Data.Ref = Undefined;
			Data.Owner = Undefined;
			OperandString_.AddressOfItemStructure = PutToTempStorage(Data, StorageAddress);
			OperandString_.Operand = Undefined;
		EndDo;
	EndIf;
	
	Return PutToTempStorage(ElementStructure, StorageAddress);
	
EndFunction

// Puts data from the passed report type string in the temporary storage of the form without reference to the reference list item.
// When writing such a report element, a new link will be generated, so the element being placed will be copied.
//
// Parameters:
//  ObjectToPlace - Arbitrary - object to place
//  StorageAddress - String - the address of the temporary storage.
//
// Returns:
//   String - The address of the item in the storage.
//
Function PlaceCopyOfItemInRepository(ObjectToPlace, StorageAddress = Undefined) Export
	
	Return PlaceItemInStorage(ObjectToPlace, StorageAddress, True);
	
EndFunction

// Returns data for the report element
// 
// Parameters:
// 	ReportItem - CatalogObject.FinancialReportItems, Structure - LongDesc
// 	AttributesValues - Map, Undefined - LongDesc:
// * Key - CatalogRef.FinancialReportItems -
// * Value - See FinancialReportingClientServer.ReportElementStructure
// Returns:
// 	Structure, Undefined, Arbitrary - LongDesc:
// * ValueSources - ValueTable - LongDesc:
// 		** Source - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** AddedDocumentValues - Boolean -
// * DrillDownOfAppearanceItemFilterFields - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** AppearanceItemKey - UUID -
// 		** FilterFieldName - String -
// 		** ResourceName - String -
// * DesigningColumns - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** AppearanceItemKey - UUID -
// * RegisteredRows - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** AppearanceItemKey - UUID -
// * AppearanceItems - ValueTable - LongDesc:
// 		** Appearance - ValueStorage -
// 		** Condition - ValueStorage -
// 		** CreatedAreaType - EnumRef.DesignedAreaTypesOfBudgetReports -
// 		** AppearanceItemKey - UUID - 
// * AdditionalFields - ValueTable - LongDesc:
// 		** Attribute - String -
// 		** Description - String -
// 		** TitleOutput - Boolean -
// 		** InSeparateColumn - Boolean -
// * TableItems - ValueTable -:
// 		** String - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** Column - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// 		** Item - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// * FormulaOperands - ValueTable - LongDesc:
// 		** Id - String -
// 		** Operand - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// * ItemKindAttributes - ValueTable - LongDesc:
// 		** Attribute - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports -
// 		** Value - Characteristic.ItemAttributesOfFinancialReports -
// * LinkedItem1 - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
// * DimensionValue -Characteristic.BudgetFlowItemDimensions -
// * HasSettings - Boolean -
// * AdditionalSelection - ValueStorage -
// * Comment - String -
// * ReverseSign - Boolean -
// * NameForPrinting - String -
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * Code - Number -
// * Description - String -
// * Owner - CatalogRef.FinancialReportTypes, CatalogRef.BudgetProfiles -
// * Ref - CatalogRef.FinancialReportItems, String - the item or its address in temporary storage.
Function ReportElementData(ReportItem, AttributesValues = Undefined) Export
	
	ElementStructure = FinancialReportingClientServer.ReportElementStructure();
	If TypeOf(ReportItem) = Type("CatalogObject.FinancialReportItems") Then
		FillPropertyValues(ElementStructure, ReportItem);
		CopyElementTables(ReportItem, ElementStructure);
	ElsIf TypeOf(ReportItem) = Type("CatalogRef.FinancialReportItems") Then
		If ValueIsFilled(ReportItem) Then
			FoundCacheValue = Undefined;
			If AttributesValues <> Undefined Then
				FoundCacheValue = AttributesValues.Get(ReportItem);
			EndIf;
		EndIf;
		If FoundCacheValue = Undefined Then
			ElementStructure = Common.ObjectAttributesValues(
				ReportItem,
				ElementStructure); // See FinancialReportingClientServer.ReportElementStructure
		Else
			ElementStructure = FoundCacheValue;
		EndIf;
		If ValueIsFilled(ElementStructure.Ref) Then
			CopyElementTables(ElementStructure, ElementStructure);
		EndIf;
	ElsIf TypeOf(ReportItem) = Type("Structure") Then
		FillPropertyValues(ElementStructure, ReportItem);
		For Each KeyAndValue In ReportItem Do
			If StrFind(KeyAndValue.Key, "AdditionalAttribute_") Then
				NameOfAdditionalProps_ = StrReplace(KeyAndValue.Key, "AdditionalAttribute_", "");
				SetValueOfAdditionalProps(ElementStructure, NameOfAdditionalProps_, KeyAndValue.Value)
			EndIf;
		EndDo;
	Else
		Raise NStr("vi = 'Loại đối tượng được đặt không được xác định';
					|ru = 'Не определен тип помещаемого объекта';
					|en = 'Placed object type is not determined'; fa = 'Placed object type is not determined';
					|it = 'Tipo di oggetto non definito';
					|pl = 'Niezdefiniowany typ obiektu';
					|tr = 'Yardımcı nesne türü tanımlanmamış'");
	EndIf;
	
	ElementStructure.Insert("ThisIsReference", ValueIsFilled(ElementStructure.LinkedItem1));
	
	StructureOfElementTables = New Structure;
	StructureOfElementTables.Insert("FormulaOperands", StrSplit("Id,Operand", ","));
	StructureOfElementTables.Insert("ItemKindAttributes", StrSplit("Attribute,Value", ","));
	StructureOfElementTables.Insert("TableItems", StrSplit("String,Column,Item", ","));
	StructureOfElementTables.Insert("AdditionalFields", StrSplit("Attribute,Description,TitleOutput", ","));
	StructureOfElementTables.Insert("AppearanceItems", StrSplit("Appearance,Condition,CreatedAreaType,AppearanceItemKey", ","));
	StructureOfElementTables.Insert("RegisteredRows", StrSplit("ReportItem,AppearanceItemKey", ","));
	StructureOfElementTables.Insert("DesigningColumns", StrSplit("ReportItem,AppearanceItemKey", ","));
	StructureOfElementTables.Insert("DrillDownOfAppearanceItemFilterFields", StrSplit("AppearanceItemKey,ReportItem,FilterFieldName,ResourceName", ","));
	StructureOfElementTables.Insert("ValueSources", StrSplit("Source,AddedDocumentValues", ","));
	StructureOfElementTables.Insert("CalculationsRules", StrSplit("Rule", ","));
	For Each KeyAndValue In StructureOfElementTables Do
		If TypeOf(ElementStructure[KeyAndValue.Key]) <> Type("ValueTable") Then
			ElementTable = New ValueTable;
			For Each ColumnName In KeyAndValue.Value Do
				ElementTable.Columns.Add(ColumnName);
			EndDo;
			ElementStructure[KeyAndValue.Key] = ElementTable;
		EndIf;
	EndDo;
	
	FormulaOperands = ElementStructure.FormulaOperands; // ValueTable
	If FormulaOperands.Columns.Find("AddressOfItemStructure") = Undefined Then
		FormulaOperands.Columns.Add("AddressOfItemStructure");
	EndIf;
	
	Return ElementStructure;
	
EndFunction

// The procedure sets the value of the additional details of the financial report element.
//
// Parameters:
//  Source - Arbitrary - object or address of the element structure in storage
//  Attribute - String, ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports - The name of the props
//  Value - Arbitrary - the value of the props.
//
Procedure SetValueOfAdditionalProps(Source, Val Attribute, Value) Export
	
	If TypeOf(Source) = Type("String") Then
		Object = GetFromTempStorage(Source);
	Else
		Object = Source;
	EndIf;
	
	If Object.ItemKindAttributes = Undefined Then
		AttributesTable = New ValueTable;
		AttributesTable.Columns.Add("Attribute");
		AttributesTable.Columns.Add("Value");
		AttributesTable.Indexes.Add("Attribute");
		Object.ItemKindAttributes = AttributesTable;
	EndIf;
	
	If TypeOf(Attribute) = Type("String") Then
		Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports[Attribute];
	EndIf;
	
	FoundRow = Object.ItemKindAttributes.Find(Attribute);
	If FoundRow = Undefined Then
		FoundRow = Object.ItemKindAttributes.Add();
		FoundRow.Attribute = Attribute;
	EndIf;
	
	FoundRow.Value = Value;
	
	If FoundRow.Value = Undefined Then
		Object.ItemKindAttributes.Delete(FoundRow);
	EndIf;
	
	If TypeOf(Source) = Type("String") Then
		PutToTempStorage(Object, Source);
	EndIf;
	
EndProcedure

// The procedure sets the value of the additional details of the financial report element.
//
// Parameters:
//  Source - Arbitrary - object or address of the element structure in storage
//  Attributes - Structure - details for the installation.
//
Procedure SetValuesForAdditionalBankingDetails(Source, Attributes) Export
	
	For Each KeyAndValue In Attributes Do
		SetValueOfAdditionalProps(Source, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

// The procedure sets the value of the details of the financial report element in the storage.
//
// Parameters:
//  StorageAddress - String - address of the element structure
//  StructureOfValues - Structure - details for the installation.
//
Procedure SetAttributeValue(StorageAddress, StructureOfValues) Export
	
	Object = GetFromTempStorage(StorageAddress);
	For Each KeyAndValue In StructureOfValues Do
		Object[KeyAndValue.Key] = Undefined;
	EndDo;
	PutToTempStorage(Object, StorageAddress);
	
EndProcedure

// The function returns the values of additional details of the financial report element.
//
// Parameters:
//  ItemRef - CatalogObject.FinancialReportItems, CatalogRef.FinancialReportItems, Structure, String -
//                    object or address of the element structure in the storage.
//  Attributes - Structure - details for the receipt.
//
// Returns:
//   Structure - the value of the additional props.
//
Function AdditionalAttributesValues(ItemRef, Attributes) Export
	
	If TypeOf(ItemRef) = Type("String") Then
		Object = GetFromTempStorage(ItemRef); // See ReportElementData
		Cache    = Object.ItemKindAttributes;
	ElsIf TypeOf(ItemRef) = Type("CatalogRef.FinancialReportItems") Then
		Object = Common.ObjectAttributesValues(ItemRef, "ItemKindAttributes");
		Cache    = Object.ItemKindAttributes.Unload();
	Else
		Cache = ItemRef.ItemKindAttributes;
	EndIf;
	
	AttributesStructure1 = New Structure(Attributes);
	
	Result = New Structure;
	
	For Each KeyAndValue In AttributesStructure1 Do
		Result.Insert(KeyAndValue.Key, 
									FinancialReportingServer.ValueOfAdditionalProps(
										Undefined, 
										ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports[KeyAndValue.Key],
										Cache));
	EndDo;
		
	Return Result;
	
EndFunction

// The function returns the value of the additional details of the financial report element.
//
// Parameters:
//  ItemRef - Arbitrary - object or address of the element structure in storage
//  Attribute - String - details for receiving.
//
// Returns:
//   Arbitrary   - the value of the additional props.
//
Function ValueOfAdditionalProps(ItemRef, Attribute) Export
	
	Return AdditionalAttributesValues(ItemRef, Attribute)[Attribute];
	
EndFunction

// This function defines the name of the reference element form for editing the financial report element.
//
// Parameters:
//  ItemKind - EnumRef.FinancialReportItemKinds - type of element to define the form for
//  Item - String - the address in temporary storage where all the element data is located
//  AdditionalMode - EnumRef.AdditionalModesOfReportItems - indicates whether the form is in an additional mode.
//  OpeningBudgetReportElementForm - Boolean - flag for opening the budget report form, filled in only when the form is opened.
//
// Returns:
//   Structure - Structure with parameters:
//    *FormName - String - Name of the directory form.
//    *Attributes - Structure - The structure of the details.
//
Function FormUsageParameters(ItemKind, Item, AdditionalMode = Undefined, OpeningBudgetReportElementForm = False) Export
	
	AdditionalModes = Enums.AdditionalModesOfReportItems;
	DimensionsTypes = Enums.TypesOfBudgetReportDimensions;
	
	ArrayOfAdditionalAttributes = New Array;
	AdditionalAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	ElementFormName = Undefined;
	If AdditionalMode = AdditionalModes["LinkedItem1"] Then
		ElementFormName = "Form.AssociatedItemForm";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectItem);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.ReportHeader
		Or ItemKind = Enums.FinancialReportItemKinds.UneditedText
		Or ItemKind = Enums.FinancialReportItemKinds.EditedText Then
		ElementFormName = "Form.TextBlock";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Text);
		If IsTempStorageURL(Item) Then
			ItemParameters = GetFromTempStorage(Item);
			ElementOwner = ?(ItemParameters.Property("Owner"), ItemParameters.Owner, Undefined);
		Else
			ElementOwner = Item.Owner;
		EndIf;
		If TypeOf(ElementOwner) = Type("CatalogRef.BudgetProfiles") Then
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OnlyForPrinting);
		EndIf;
		If OpeningBudgetReportElementForm Then
			ElementFormName = "Form.BudgetsTextBlock";
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		ElementFormName = "Form.NonFinancialItem";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PeriodOfShift);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OffsetFrequency);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.NonFinancialItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByCompany);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByDepartment);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterScenario);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PrivilegedMode);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PresentationExpression);
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		If AdditionalMode = AdditionalModes["BudgetFlowItemInInputMode"] Then
			ElementFormName = "Form.BudgetFlowItemForEntering";
		ElsIf AdditionalMode = AdditionalModes["AllItemsInComplexTable"]
			Or AdditionalMode = AdditionalModes["ItemInBudgetBalanceItem"] Then
			ElementFormName = "Form.BudgetFlowItemWithoutSettings";
		Else
			ElementFormName = "Form.BudgetFlowItem";
		EndIf;
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.BudgetFlowItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayedIndicators);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PrivilegedMode);
		If ElementFormName = "Form.BudgetFlowItem" Then
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ExcludeEnteredDocumentDataDuringCalculation);
		EndIf;
		//DisplayFilters
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByCompany);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByDepartment);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterScenario);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseStatusFilter);
		//FillType
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.FillingMethod);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Formula);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PresentationExpression);
		// data periods
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PeriodOfShift);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OffsetFrequency);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.LowerBoundOfData);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UpperBoundOfData);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupingPeriodStart);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupingPeriodEnd);
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		If AdditionalMode = AdditionalModes["AllIndicatorsInAComplexTable"] Then
			ElementFormName = "Form.AllIndicatorsComplexTable";
		Else
			ElementFormName = "Form.BudgetBalanceItem";
		EndIf;
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.BudgetBalanceItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayedIndicators);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.IndicatorValueType);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PrivilegedMode);
		If ElementFormName = "Form.BudgetBalanceItem" Then
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ExcludeEnteredDocumentDataDuringCalculation);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PresentationExpression);
		EndIf;
		//DisplayFilters
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByCompany);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByDepartment);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterScenario);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseStatusFilter);
		// data periods
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PeriodOfShift);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OffsetFrequency);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.LowerBoundOfData);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UpperBoundOfData);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupingPeriodStart);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupingPeriodEnd);
		
	ElsIf (ItemKind = Enums.FinancialReportItemKinds.Group
		Or ItemKind = Enums.FinancialReportItemKinds.TotalByGroup) Then
		If AdditionalMode = AdditionalModes["ShowRowCodeNote"] Then
			ElementFormName = "Form.Group";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayItemTitle);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
		Else
			ElementFormName = "Form.Group";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayItemTitle);
		EndIf;
		If  ItemKind = Enums.FinancialReportItemKinds.TotalByGroup Then
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.ComplexTable
		Or ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
		Or ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
		ElementFormName = "Form.Table";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayItemTitle);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayGroupingTitle);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupHeader);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayHeadersVertically);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
		ElementFormName = "Form.GroupFormula";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GroupFormula);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.RowColumn Then
		ElementFormName = "Form.RowColumn";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectItem);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.MonetaryIndicator Then
		ElementFormName = "Form.MonetaryIndicator";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.GLAccount_);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.TotalType);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OpeningBalance);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonMonetaryItem Then
		ElementFormName = "Form.NonMonetaryItem";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.NonMonetaryItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectItem);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
		If AdditionalMode = AdditionalModes["ReportKind"] Then
			ElementFormName = "Form.ReportDerivedItem";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Formula);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ReportRowCode);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Note);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectItem);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
		Else
			ElementFormName = "Form.DerivedBudgetBalanceItem";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Formula);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PrivilegedMode);
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.CellsSettings Then
		If AdditionalMode = AdditionalModes["ReportKind"] Then
			ElementFormName = "Form.ReportKindCellSettings";
		Else
			ElementFormName = "Form.CellsSettings";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayColumnNumbering);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayRowsNumbering);
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.TableCell Then
		ElementFormName = "Form.SelectionOfComplexTableCell";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.CellRow);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.CellColumn);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DimensionType);
		DimensionType = ValueOfAdditionalProps(Item, "DimensionType");
		If DimensionType = DimensionsTypes["Period"] Then
			If AdditionalMode = AdditionalModes["ReportKind"] Then
				ElementFormName = "Form.ReportKindPeriod";
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Periodicity);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Sort);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PeriodPresentation);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.OutputIndicatorsOfSimilarPeriodsOfPreviousYears);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DisplayIndicatorsOfPreviousPeriods);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.NumberOfPreviousYears);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.NumberOfPreviousPeriods);
			Else
				ElementFormName = "Form.Period";
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Periodicity);
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PeriodValue);
			EndIf;
		ElsIf DimensionType = DimensionsTypes["RegisterDimension"]
			Or DimensionType = DimensionsTypes["AccountingRegisterDimension"] Then
			ElementFormName = "Form.RegisterDimension";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DimensionName);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
			If Not DimensionType = DimensionsTypes["AccountingRegisterDimension"] Then
				ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectedValueSources);
			EndIf;
		ElsIf DimensionType = DimensionsTypes["ExtDimension"] Then
			ElementFormName = "Form.RegisterDimension";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ExtDimensionType);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Accuracy);
		ElsIf DimensionType = DimensionsTypes["Dimension"] Then
			ElementFormName = "Form.DimensionKind";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DimensionKind);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectedValueSources);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SourceAllElements);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ShowItemHierarchy);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PresentationExpression);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SortingExpression);
		ElsIf DimensionType = DimensionsTypes["Scenario"] Then
			ElementFormName = "Form.Scenario";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Scenario);
		ElsIf DimensionType = DimensionsTypes["Organization"] Then
			ElementFormName = "Form.Organization";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Organization);
		ElsIf DimensionType = DimensionsTypes["Department"] Then
			ElementFormName = "Form.Department";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Department);
		ElsIf DimensionType = DimensionsTypes["Currency"] Then
			ElementFormName = "Form.Currency";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.Currency);
		ElsIf DimensionType = DimensionsTypes["FixedDimension"] Then
			ElementFormName = "Form.FixedDimension";
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ThisIsDimensionOther);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.EnableEdit);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.DimensionKind);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SelectedValueSources);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SourceAllElements);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.ShowItemHierarchy);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PresentationExpression);
			ArrayOfAdditionalAttributes.Add(AdditionalAttributes.SortingExpression);
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
		ElementFormName = "Form.EditedValue";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.EditedValueType);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
		ElementFormName = "Form.SetUpCalculationRules";
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.PrivilegedMode);
		//DisplayFilters
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByCompany);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterByDepartment);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseFilterScenario);
		ArrayOfAdditionalAttributes.Add(AdditionalAttributes.UseStatusFilter);
	EndIf;
	
	If ElementFormName = Undefined Then
		Raise NStr("vi = 'Loại báo cáo không xác định';
					|ru = 'Неизвестный вид элемента отчета';
					|en = 'Unknown report item kind'; fa = 'Unknown report item kind';
					|it = 'Tipo di elemento di report sconosciuto';
					|pl = 'Nieznany typ elementu raportu';
					|tr = 'Bilinmeyen rapor öğe türü'");
	EndIf;
	
	NamesOfAdditionalAttributes = Common.ObjectsAttributeValue(ArrayOfAdditionalAttributes, "PredefinedDataName");
	StructureOfAdditionalDetails = New Structure;
	For Each NameOfAdditionalProps In NamesOfAdditionalAttributes Do
		StructureOfAdditionalDetails.Insert(NameOfAdditionalProps.Value);
	EndDo;
	
	Return New Structure(
				"FormName, Attributes",
				"Catalog.FinancialReportItems." + ElementFormName,
				StructureOfAdditionalDetails);
	
EndFunction

// Returns the name of the enumeration value Periodicity
//
// Parameters:
// 	Periodicity - EnumRef.Periodicity - the value of the frequency.
// 	              - Undefined - if the periodicity value is not set.
//
// Returns:
// 	String - The name of the periodicity enumeration enumeration,
// 	         an empty string if the periodicity value is not specified.
//
Function PeriodicityByString(Periodicity) Export
	
	If Not ValueIsFilled(Periodicity) Then
		Result = "";
	Else
		Result = Common.EnumerationValueName(Periodicity);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// The function returns the index of the image based on the type of element and clarifying information
//
// Parameters:
//  ItemKind  - EnumRef.FinancialReportItemKinds - Type of element for which we get the parameter
//  NameOfAuxiliaryData  - String - clarifying value.
//
// Returns:
//   Number   - index of a picture from a collection of collectionsevidents of financial reporting.
//
Function CustomPicture(ItemKind, NameOfAuxiliaryData = Undefined) Export
	
	Return FinancialReportingCached.CustomPicture(ItemKind, NameOfAuxiliaryData);
	
EndFunction

// Returns the value of the props read from the information base or storage by reference to the object.
// 
// Parameters:
//  Ref       - CatalogRef, String -
//                 a reference to an object, a reference list item string, a document, or the address of an item in storage
//  AttributeName - String - for example, "Code".
// 
// Returns:
//  Arbitrary    - depends on the type of value of the read props.
// 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	If TypeOf(Ref) = Type("String") Then
		ElementStructure = GetFromTempStorage(Ref);
		Return ElementStructure[AttributeName];
	Else
		Return Common.ObjectAttributeValue(Ref, AttributeName);
	EndIf;
	
EndFunction

// The function returns a tree of operators in the formula constructor
//
// Parameters:
//  RequestCondition - Boolean - indicates that the "condition" statement should be returned in the format for the request.
//
// Returns:
//   ValueTree   - the operator tree.
//
Function BuildTreeOfOperators(RequestCondition = True) Export
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	
	PresentationOfOperatorGroup = NStr("vi = 'Toán tử';
										|ru = 'Операторы';
										|en = 'Operators'; fa = 'عملگرها';
										|it = 'Operatori';
										|pl = 'Operatory';
										|tr = 'Operatörler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Operators", PresentationOfOperatorGroup);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "+", " + ", "+");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "-", " - ", "-");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "*", " * ", "*");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "/", " / ", "/");
	
	PresentationOfOperatorGroup = NStr("vi = 'Toán tử lo-gic và hằng';
										|ru = 'Логические операторы и константы';
										|en = 'Logical operators and constants'; fa = 'Logical operators and constants';
										|it = 'Operatori logici e costanti';
										|pl = 'Operatory logiczne i konstanty';
										|tr = 'Mantıksal operatörler ve sabitler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "LogicalOperatorsAndConstants", PresentationOfOperatorGroup);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<", " < ", "<");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">", " > ", ">");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<=", " <= ", "<=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">=", " >= ", ">=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "=", " = ", "=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<>", " <> ", "<>");
	
	OperatorID = "And";
	OperatorPresentation = NStr("vi = 'VÀ';
								|ru = 'И';
								|en = 'AND'; fa = 'و';
								|it = 'E';
								|pl = 'ORAZ';
								|tr = 'AND'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "OR";
	OperatorPresentation = NStr("vi = 'HOẶC';
								|ru = 'ИЛИ';
								|en = 'OR'; fa = 'یا';
								|it = 'OPPURE';
								|pl = 'LUB';
								|tr = 'OR'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "NOT";
	OperatorPresentation = NStr("vi = 'KHÔNG';
								|ru = 'НЕ';
								|en = 'NOT'; fa = 'NOT';
								|it = 'NON';
								|pl = 'NIE';
								|tr = 'NOT'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "TRUE";
	OperatorPresentation = NStr("vi = 'ĐÚNG';
								|ru = 'ИСТИНА';
								|en = 'TRUE'; fa = 'TRUE';
								|it = 'VERO';
								|pl = 'PRAWDA';
								|tr = 'TRUE'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "FALSE";
	OperatorPresentation = NStr("vi = 'SAI';
								|ru = 'ЛОЖЬ';
								|en = 'FALSE'; fa = 'FALSE';
								|it = 'FALSO';
								|pl = 'FAŁSZ';
								|tr = 'FALSE'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	
	PresentationOfOperatorGroup = NStr("vi = 'Chức năng';
										|ru = 'Функции';
										|en = 'Functions'; fa = 'توابع';
										|it = 'Funzioni';
										|pl = 'Funkcje';
										|tr = 'İşlevler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Functions", PresentationOfOperatorGroup);
	
	If RequestCondition Then
		OperatorID = "CASE WHEN THEN ELSE END";
		OperatorPresentation = NStr("vi = 'Điều kiện';
									|ru = 'Условие';
									|en = 'Condition'; fa = 'شرط';
									|it = 'Condizione';
									|pl = 'Warunek';
									|tr = 'Koşul'");
		OperatorInCodeLanguageForInsertion = StringFunctionsClientServer.SubstituteParametersToString(
			"CASE WHEN %1 THEN %2 ELSE %3 END",
			NStr("vi = '<Điều kiện>';
				|ru = '<Условие>';
				|en = '<Condition>'; fa = '<Condition>';
				|it = '<Condizione>';
				|pl = '<Warunek>';
				|tr = '<Koşul>'"),
			StrTemplate(NStr("vi = '<%1>';
							|ru = '<%1>';
							|en = '<%1>'; fa = '<%1>';
							|it = '<%1>';
							|pl = '<%1>';
							|tr = '<%1>'"), "ResultIsTrue"),
			StrTemplate(NStr("vi = '<%1>';
							|ru = '<%1>';
							|en = '<%1>'; fa = '<%1>';
							|it = '<%1>';
							|pl = '<%1>';
							|tr = '<%1>'"), "ResultIsFalse'"));
		ProcessingOfFormulas.AddOperator(OperatorsGroup,
			OperatorID,
			OperatorInCodeLanguageForInsertion,
			OperatorPresentation,,
			3);
	Else
		OperatorID = "?";
		OperatorPresentation = NStr("vi = 'Điều kiện';
									|ru = 'Условие';
									|en = 'Condition'; fa = 'شرط';
									|it = 'Condizione';
									|pl = 'Warunek';
									|tr = 'Koşul'");
		TextCondition = NStr("vi = '<Điều kiện>';
							|ru = '<Условие>';
							|en = '<Condition>'; fa = '<Condition>';
							|it = '<Condizione>';
							|pl = '<Warunek>';
							|tr = '<Koşul>'");
		TextMeaningTrue = NStr("vi = '<Giá trị nếu đúng>';
								|ru = '<Значение если истина>';
								|en = '<Value if true>'; fa = '<Value if true>';
								|it = '<Valore se vero>';
								|pl = '<Wartość jeśli prawda>';
								|tr = '<Doğru ise değer>'");
		TextMeaningFalse = NStr("vi = '<Giá trị nếu sai>';
								|ru = '<Значение если ложь>';
								|en = '<Value if false>'; fa = '<Value if false>';
								|it = '<Valore se falso>';
								|pl = '<Wartość jeśli fałsz>';
								|tr = '<Yanlış ise değer>'");
		OperatorInCodeLanguageForInsertion = StringFunctionsClientServer.SubstituteParametersToString(
			"?(%1, %2, %3)",
			TextCondition,
			TextMeaningTrue,
			TextMeaningFalse);
		ExplanationOfOperator            = NStr("vi = 'Tính toán giá trị phụ thuộc vào giá trị điều kiện';
												|ru = 'Вычисляет значение в зависимости от значения условия';
												|en = 'Calculates a value based on a condition value'; fa = 'Calculates a value based on a condition value';
												|it = 'Calcola il valore in relazione al valore della condizione';
												|pl = 'Oblicza wartość w zależności od wartości warunku';
												|tr = 'Şartın değerine bağlı olarak değeri hesaplar'");
		ProcessingOfFormulas.AddOperator(OperatorsGroup,
			OperatorID,
			OperatorInCodeLanguageForInsertion,
			OperatorPresentation,
			ExplanationOfOperator,
			3);
	EndIf;
	
	Return Tree;
	
EndFunction

// The function copies an item that is in storage
//
// Parameters:
//  ElementAddress - String - address of the item in storage
//  StorageID - UUID - UID of the form under which the work is performed
//  ItemKind - Undefined - the function returns the element type in the parameter.
//
// Returns:
//   String   - The address of the new element.
//
Function CopyElementTo(ElementAddress, StorageID, ItemKind = Undefined) Export
	
	CopyOfElement = FinancialReportingClientServer.ReportElementStructure();
	ElementData = GetFromTempStorage(ElementAddress);
	FillPropertyValues(CopyOfElement, ElementData);
	CopyOfElement.Ref = Undefined;
	
	CopyOfElement.ItemKindAttributes = ElementData.ItemKindAttributes.Copy();
	CopyOfElement.FormulaOperands = ElementData.FormulaOperands.Copy();
	CopyOfElement.AdditionalFields = ElementData.AdditionalFields.Copy();
	
	For Each OperandString_ In CopyOfElement.FormulaOperands Do
		If Not ValueIsFilled(OperandString_.AddressOfItemStructure) Then
			OperandString_.AddressOfItemStructure = PlaceItemInStorage(OperandString_.Operand, StorageID);
		EndIf;
		OperandAddress = CopyElementTo(OperandString_.AddressOfItemStructure, StorageID);
		OperandString_.AddressOfItemStructure = OperandAddress;
		OperandString_.Operand = Undefined; // the operand must be created new
	EndDo;
	
	ItemKind = CopyOfElement.ItemKind;
	
	Return PutToTempStorage(CopyOfElement, StorageID);
	
EndFunction

Procedure CopyElementTables(Source, Receiver)

	TablesNames = "FormulaOperands, ItemKindAttributes, TableItems, CalculationsRules, AppearanceItems, RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields, ValueSources, AdditionalFields, AppearanceItems";
	TableStructure = New Structure(TablesNames);
	
	For Each KeyAndValue In TableStructure Do
		Receiver.Insert(KeyAndValue.Key, Source[KeyAndValue.Key].Unload());
	EndDo;
	RedefineColumnTypeOfCacheTables(Receiver, TableStructure);

EndProcedure

Procedure RedefineColumnTypeOfCacheTables(ElementStructure, TableStructure)
	
	For Each KeyAndValue In TableStructure Do
		
		Table = ElementStructure[KeyAndValue.Key]; // ValueTable
		NewTable = New ValueTable;
		For Each Column In Table.Columns Do
			NewTable.Columns.Add(Column.Name);
		EndDo;
		
		ElementStructure[KeyAndValue.Key] = NewTable; 
		
		CommonClientServer.SupplementTable(Table, ElementStructure[KeyAndValue.Key]);
		
	EndDo;
	
EndProcedure

// Returns the text of an error checking an expression or presentation for budget report analytics
//
// Parameters:
//  ExpressionText - String - the source text of the expression generated by the formula constructor
//  Source - String, ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions, CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems, CatalogRef.NonFinancialItemsOfBudgets - analytics of the budget report
//  NameForPrinting - String - current presentation of an item, indicator, or NFP of budgets
//
// Returns:
//  String - error text (if the check is successful, then an empty line)
//
Function ErrorTextOfExpressionOfSortRepresentation(ExpressionText, Source, NameForPrinting) Export
	
	QueryOptions = New Structure;
	If TypeOf(Source) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		SourceName = FinancialReportingCached.NameOfBudgetReportField(Source);
		DescriptionOfSourceTypes = FinancialReportingCached.TypeOfAnalyticsTypeValue(SourceName, Source);
	ElsIf TypeOf(Source) = Type("String") Then
		SourceName = Source;
		DescriptionOfSourceTypes = FinancialReportingCached.TypeOfAnalyticsTypeValue(SourceName, Source);
	Else
		
		SourceName = Source.Metadata().Name;
		DescriptionOfSourceTypes = New TypeDescription(CommonClientServer.ValueInArray(TypeOf(Source)));
		QueryOptions.Insert("Source", Source);
	EndIf;
	
	TextOfExpressionWithAlias = FinancialReportingCached.TextOfSortRepresentationExpressionWithDimensionName(
		ExpressionText, SourceName);
	
	QueryTemplate = "
		|SELECT TOP 1
		|	&TextOfExpressionWithAlias
		|FROM
		|	&DataTableName AS SourceName
		|WHERE
		|	&ConditionText";
	
	QueriesTexts = New Array;
	For Each Type In DescriptionOfSourceTypes.Types() Do
		DataTableName = ProcessingOfFormulasCached.FullNameOfDataTable(Metadata.FindByType(Type).FullName());
		If QueryOptions.Property("Source") Then
			ConditionText = SourceName + ".Ref = &Source"; // @query-part
		Else
			ConditionText = "TRUE"; // @query-part
		EndIf;
		QueryText = StrReplace(QueryTemplate, "&DataTableName", DataTableName);
		QueryText = StrReplace(QueryText, "SourceName", SourceName);
		QueryText = StrReplace(QueryText, "&TextOfExpressionWithAlias", TextOfExpressionWithAlias);
		QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
		QueriesTexts.Add(QueryText);
	EndDo;
	
	ErrorText = "";
	
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	Try
		QueryResult = Query.Execute();
		If Not IsBlankString(NameForPrinting) Then
			ResultTable1 = QueryResult.Unload();
			NameForPrinting = ResultTable1[0][ResultTable1.Columns[0].Name];
		EndIf;
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Lỗi khi kiểm tra biểu thức %1. Có thể sử dụng các toán hạng không chính xác để phân tích với nhiều kiểu giá trị';
			|ru = 'Ошибка при проверке выражения %1. Возможно используются некорректные операнды для аналитики с несколькими типами значений';
			|en = 'An error occurred when checking the %1 expression. The operands used for the dimension with multiple value types might be incorrect'; fa = 'An error occurred when checking the %1 expression. The operands used for the dimension with multiple value types might be incorrect';
			|it = 'Ошибка при проверке выражения %1. Возможно используются некорректные операнды для аналитики с несколькими типами значений';
			|pl = 'An error occurred when checking the %1 expression. The operands used for the dimension with multiple value types might be incorrect';
			|tr = '%1 ifadesi kontrol edilirken hata oluştu. Muhtemelen çeşitli değer türlerine sahip boyutlar için yanlış işlenenler kullanılıyor'"),
			ExpressionText);
	EndTry;
	
	Return ErrorText;
	
EndFunction

#EndRegion
