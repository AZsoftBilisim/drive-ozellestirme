////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Production"
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region CalculationOfCostShares

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//  TSName	- String	- name of the table part.
//  MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts -
// 
// Returns:
//		Structure - a structure with the following keys:
//			*TSName - String - name of the table part with output items
//			*ThereIsFieldCanceled - Boolean - True if the table part provides for row cancellation
//			*MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts -
//				method of cost allocation for the weekend of the product
//			*FieldNameMethodOfCostAllocationForOutputProducts - String - Name of the distribution method field
//				in the table part, if the document provides different distribution methods
//			*CalculateShareCostPercentageField - Boolean - True if the percentage is to be calculated in the table part
//			*ThisFlagIndicatesThatThereAreFillInErrors - Boolean - True if the table part has a fill-in error indicator
//			*CalculateShareOfCostAttributeRequired - Boolean - True if you want to calculate whether the "cost Share" field must be filled in"
//			*CostGroupingField - String - Name of the field that identifies the cost grouping within the document
//			*CostGroupingPresentationField - String - Name of the cost grouping header field
//			*ShareOfCostOfOtherDocumentsInGrouping - Number - Share of the cost of other documents,
//				if several documents are provided for the same grouping
//			*LinkFields - String - Fields that identify identical items within the cost grouping
//				(for identical items, the share may not be specified, the quantity is used as the share)
//			*ReadOnly - Boolean - indicates that the cost shares in the document can only be viewed (the default value is FALSE).
//			*PriceFillingParameters_- Structure - the structure used to fill in the prices in the tabular part of the document:
//				* Date - Date - document date.
//				* Currency - CatalogRef.Currencies - the currency of the document.
//				
//
Function CostAllocationParametersForOutputProducts(TSName, MethodOfAllocatingFinishedProductCosts) Export
	
	CostAllocationParameters = New Structure;
	
	CostAllocationParameters.Insert("TSName", TSName);
	CostAllocationParameters.Insert("ThereIsFieldCanceled", False);
	CostAllocationParameters.Insert("AutoCalculationOfAnyCharacteristic", False);
	CostAllocationParameters.Insert("ThereIsParameterizationOfResourceSpecification", False);
	
	CostAllocationParameters.Insert("MethodOfAllocatingFinishedProductCosts", MethodOfAllocatingFinishedProductCosts);
	CostAllocationParameters.Insert("FieldNameMethodOfCostAllocationForOutputProducts", "");
	
	CostAllocationParameters.Insert("CalculateShareCostPercentageField", False);
	CostAllocationParameters.Insert("ThisFlagIndicatesThatThereAreFillInErrors", False);
	CostAllocationParameters.Insert("CalculateShareOfCostAttributeRequired", False);
	CostAllocationParameters.Insert("SetShareOfCostIsRequiredByDefault", False);
	
	CostAllocationParameters.Insert("CostGroupingField", "");
	CostAllocationParameters.Insert("CostGroupingPresentationField", "");
	CostAllocationParameters.Insert("ShareOfCostOfOtherDocumentsInGrouping");
	
	CostAllocationParameters.Insert("LinkFields", "Products,Characteristic");
	CostAllocationParameters.Insert("ReadOnly", False);

	CostAllocationParameters.Insert("ParametersForFillingInCostShares", 
											New Structure("Date, Currency", 
											Date("00010101"), 
											PredefinedValue("Catalog.Currencies.EmptyRef")));
	
	Return CostAllocationParameters;
	
EndFunction

#EndRegion

#Region ProductionCostAllocation

// Returns the text of summary information about the movement of material in the shop storeroom for the reporting period.
//
// Parameters:
//  Parameters	 - Structure	 - Structure with the fields incoming order, initial Order, Received, Transmitted, and measurement Unit.
// 
// Returns:
//   - FormattedString
//
Function DecryptingIncomingBalance(Parameters) Export
	
	If Parameters = Undefined Then
		Return "";
	EndIf;
	
	If Parameters.IncomingBalance = 0
		And Parameters.OpeningBalance = 0
		And Parameters.Received = 0
		And Parameters.Passed = 0 Then
		Return NStr("vi = 'Không có lưu chuyển mặt hàng được phát hiện.';
					|ru = 'Движения номенклатуры не обнаружено.';
					|en = 'Product movements are not found.'; fa = 'Product movements are not found.';
					|it = 'Non sono stati rilevati dei movimenti dell''articolo.';
					|pl = 'Nie wykryto żadnych ruchów produktów.';
					|tr = 'Öğe hareketi tespit edilmedi.'");
	Else
		DecryptionTemplate = NStr("vi = 'Số dư (<b>%1</b> %2) =';
									|ru = 'Входящий остаток (<b>%1</b> %2) =';
									|en = 'Provided qty (<b>%1</b> %2) ='; fa = 'Provided qty (<b>%1</b> %2) =';
									|it = 'Входящий остаток (<b>%1</b> %2) =';
									|pl = 'Provided qty (<b>%1</b> %2) =';
									|tr = 'Gelen bakiye (<b>%1</b> %2)='");
	EndIf;
	
	
	If Not Parameters.OpeningBalance = 0 Then
		DecryptionTemplate = DecryptionTemplate + " " + NStr("vi = 'số dư đầu tháng (<b>%3</b> %2)';
															|ru = 'остаток на начало месяца (<b>%3</b> %2)';
															|en = 'balance as of the beginning of the month (<b>%3</b> %2)'; fa = 'balance as of the beginning of the month (<b>%3</b> %2)';
															|it = 'остаток на начало месяца (<b>%3</b> %2)';
															|pl = 'balance as of the beginning of the month (<b>%3</b> %2)';
															|tr = 'ay başlangıcındaki bakiye (<b>%3</b> %2)'");
	EndIf;
	
	If Not Parameters.Received = 0 Then
		DecryptionTemplate = DecryptionTemplate + ?(Parameters.OpeningBalance = 0, " ", " + ")
												+ NStr("vi = 'đã tiếp nhận (<b>%4</b> %2)';
														|ru = 'поступило (<b>%4</b> %2)';
														|en = 'received (<b>%4</b> %2)'; fa = 'received (<b>%4</b> %2)';
														|it = 'поступило (<b>%4</b> %2)';
														|pl = 'received (<b>%4</b> %2)';
														|tr = 'geldi (<b>%4</b> %2)'");
	EndIf;
	
	If Not Parameters.Passed = 0 Then
		DecryptionTemplate = DecryptionTemplate + ?(Parameters.OpeningBalance = 0 And Parameters.Received = 0, " ", " - ")
												+ NStr("vi = 'đã chuyển (<b>%5</b> %2)';
														|ru = 'передано (<b>%5</b> %2)';
														|en = 'transferred (<b>%5</b> %2)'; fa = 'transferred (<b>%5</b> %2)';
														|it = 'передано (<b>%5</b> %2)';
														|pl = 'transferred (<b>%5</b> %2)';
														|tr = 'Teslim edilenler (<b>%5</b> %2)'");
	EndIf;
	
	DecryptionTemplate = DecryptionTemplate + ".";
	DecryptionText = StringFunctionsClientServer.SubstituteParametersToString(
			DecryptionTemplate,
			Parameters.IncomingBalance,
			Parameters.UnitOfMeasure,
			Parameters.OpeningBalance,
			Parameters.Received,
			Parameters.Passed);
	
	Return StringFunctionsClientServer.FormattedString(DecryptionText);;
	
EndFunction

#EndRegion

#Region FillType

// Fills in the value of the item in the PM line depending on the value of another item.
//
// Parameters:
//  TSData            - FormDataCollection - Processed strings, can also be a single string or an array of strings
//	AttributeName        - String               - name of the Bank details to fill in
//  PopulationSettings - Map of KeyAndValue:
//  * Key     - String - Name of the PM account to be checked
//  * Value - Map of KeyAndValue - Key: value of the verified account details
//                                               Value: the value of the information to be filled in.
//  CheckFilling - Boolean               - Flag of the installation value in cases of its absence
//	Filled           - Boolean               - Takes the value True when setting the value of the props for at least
//												 one row.
//
Procedure FillInPropsValue(TSData, AttributeName, PopulationSettings, CheckFilling = False, Filled = False) Export
	
	For Each Setting In PopulationSettings Do
		Break;
	EndDo;
	
	NameOfPropsToCheck = Setting.Key;
	FillingData         = Setting.Value;
	
	If TypeOf(TSData) = Type("FormDataCollection")
	 Or TypeOf(TSData) = Type("Array") Then
		
	 	For Each TSRow In TSData Do
		 
			If CheckFilling And ValueIsFilled(TSRow[AttributeName]) Then
				Continue;
			EndIf;
			
			AttributeValue = FillingData.Get(TSRow[NameOfPropsToCheck]);
			
			If AttributeValue <> Undefined Then
				TSRow[AttributeName] = AttributeValue;
				Filled              = True;
			EndIf;
			
		EndDo;
		
	Else
		
		If CheckFilling And ValueIsFilled(TSData[AttributeName]) Then
			Return;
		EndIf;
		
		AttributeValue = FillingData.Get(TSData[NameOfPropsToCheck]);
		
		If AttributeValue <> Undefined Then
			TSData[AttributeName] = AttributeValue;
			Filled              = True;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BackflushProduction_

// Parameters of formation of production documents without orders, distribution of returnable waste.
// 
// Returns:
//  Structure - Parameters For The Formation Of Production Documents Without Orders:
//  * ProductsAccordingToSpecification - Array of Structure - the list of products manufactured according to specifications.
//  * ProductsByRule - Array of Structure - the list of products manufactured according to the rules.
//  * AutoFill - Boolean - a sign of filling in expensive parts.
//  * ListOfData - Array of String - list of specification tables.
//  * FormObjects - Structure - matching the shapes of objects.
//  * RegistrationPeriod - Date - registration period.
//
Function ParametersForFormationOfProductionDocumentsWithoutOrders() Export
	
	Result = New Structure;
	
	Result.Insert("ProductsAccordingToSpecification",		New Array);
	Result.Insert("ProductsByRule",			New Array);
	Result.Insert("AutoFill",	False);
	Result.Insert("ListOfData",			New Array);
	Result.Insert("FormObjects",				New Structure);
	Result.Insert("RegistrationPeriod",			Date(1,1,1));
	
	Return Result;
	
EndFunction

// The structure of the product line.
// 
// Returns:
//  Structure - Product Line Structure:
// * Organization - CatalogRef.Companies
// * GroupCosts - EnumRef.GroupingsOfCostsInBackflushProduction
// * Department - CatalogRef.BusinessStructure
// * Recipient - Undefined
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Series - CatalogRef.ItemsBatches
// * Purpose - CatalogRef.Assignments
// * LineOfBusiness - CatalogRef.LinesOfBusiness
// * CostGenerationModel - EnumRef.ModelTypesOfCosting
// * BillOfMaterials - CatalogRef.BillsOfMaterials
// * AllocatedAccordingToRule - CatalogRef.CostAllocationRules
// * DirectionOfProductionIssue - EnumRef.BusinessTransactions
// * Count - Number
// * RecordCostsByADocument - Boolean
// * ErrorInModelSettings - Boolean
//
Function StructureProductLine() Export
	
	Result = New Structure;
	Result.Insert("Organization",                 PredefinedValue("Catalog.Companies.EmptyRef"));
	Result.Insert("GroupCosts",           PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.EmptyRef"));
	Result.Insert("Department",               PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Result.Insert("Recipient",                  Undefined);
	Result.Insert("Products",                PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("Characteristic",              PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Result.Insert("Series",                       PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	Result.Insert("Purpose",                  PredefinedValue("Catalog.Assignments.EmptyRef"));
	Result.Insert("LineOfBusiness",     PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"));
	Result.Insert("CostGenerationModel", PredefinedValue("Enum.ModelTypesOfCosting.EmptyRef"));
	Result.Insert("BillOfMaterials",                PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	Result.Insert("AllocatedAccordingToRule",        PredefinedValue("Catalog.CostAllocationRules.EmptyRef"));
	Result.Insert("DirectionOfProductionIssue",          PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	Result.Insert("Count",                  0);
	Result.Insert("RecordCostsByADocument",   False);
	Result.Insert("ErrorInModelSettings",     False);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Fractions

// Creates a structure for storing fractions
// 
// Parameters:
//  Numerator - Number
//  Denominator - Number
// 
// Returns:
//  Structure - Fraction:
// * Numerator - Number
// * Denominator - Number
// * Value - Number
Function Fraction(Val Numerator, Val Denominator) Export
	
	Result = New Structure("Numerator, Denominator, Value", 1, 1, 1);
	
	Result.Numerator   = Numerator;
	Result.Denominator = Denominator;
	Result.Value    = Numerator / Denominator;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculationOfCostShares

Function StructureOfShareValueFields() Export
	
	Result = New Structure("CostShare,CostSharePerUnit",0,0);
	Return Result;
	
EndFunction

Procedure FillInCostFractionInLine(String, CalculationResult2) Export
	
	FillPropertyValues(String, CalculationResult2, "CostShare,CostSharePerUnit");
	
EndProcedure

Procedure CalculateFractionOfCostPerLine(String, MethodOfAllocatingFinishedProductCosts) Export
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		Return;
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		
		If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCount") Then
			String.CostShare = String.Count;
		Else
		
			If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost")
				Then
				String.CostShare = Round(String.CostSharePerUnit * String.Count, 2);
			Else
				String.CostShare = String.CostSharePerUnit * String.Count;
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CalculateFractionOfValueInCollection(Collection, MethodOfAllocatingFinishedProductCosts) Export
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		Return;
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		
		For Each String In Collection Do
			
			If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCount") Then
				String.CostShare = String.Count;
			Else
			
				If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost")
					Then
					String.CostShare = Round(String.CostSharePerUnit * String.Count, 2);
				Else
					String.CostShare = String.CostSharePerUnit * String.Count;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CalculateFractionOfCostPerUnitInRow(String, MethodOfAllocatingFinishedProductCosts) Export
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		Return;
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") 
		Or MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCount") Then
		String.CostSharePerUnit = 0;
	Else
		If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost")
			Then
			String.CostSharePerUnit = Round(String.CostShare / String.Count, 2);
		Else
			String.CostSharePerUnit = String.CostShare / String.Count;
		EndIf;

	EndIf;
	
EndProcedure

Procedure RecalculateFractionOfCostWhenSplittingRow(NewRow, InitialString, MethodOfAllocatingFinishedProductCosts) Export
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		Return;
	EndIf;
	
	NewRow.CostSharePerUnit = InitialString.CostSharePerUnit;
	
	If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") 
		Or MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCount") Then
		
		If NewRow.Count + InitialString.Count = 0 Then
			NewRow.CostShare = 0;
			InitialString.CostShare = 0;
		Else
			NewRow.CostShare = NewRow.Count * InitialString.CostShare / (NewRow.Count + InitialString.Count);
			InitialString.CostShare = InitialString.CostShare - NewRow.CostShare;
		EndIf;
		
	Else
		
		If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost") Then
			NewRow.CostShare = Round(NewRow.CostSharePerUnit * NewRow.Count, 2);
			InitialString.CostShare = Round(InitialString.CostSharePerUnit * InitialString.Count, 2);
		Else
			NewRow.CostShare = NewRow.CostSharePerUnit * NewRow.Count;
			InitialString.CostShare = InitialString.CostSharePerUnit * InitialString.Count;
		EndIf;
		
	EndIf;
	
EndProcedure

Function ShareOfCostIsCalculated(String, CostAllocationParameters) Export
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		MethodOfAllocatingFinishedProductCosts = CostAllocationParameters.MethodOfAllocatingFinishedProductCosts;
	Else
		MethodOfAllocatingFinishedProductCosts = String[CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts];
	EndIf;
	
	If ValueIsFilled(MethodOfAllocatingFinishedProductCosts)
		And MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region DCS

Function CollapseColumn(Val Array, Val EmptyValue = Undefined) Export
	
	Array = CommonClientServer.CollapseArray(Array);
	
	CommonClientServer.DeleteValueFromArray(Array, NULL);
	CommonClientServer.DeleteValueFromArray(Array, Undefined);
	CommonClientServer.DeleteValueFromArray(Array, EmptyValue);
	
	Return Array;
	
EndFunction

Function CollapseColumnIntoRow(Val Array, Val NumberOfOutputElements = 1) Export
	
	ListForOutput = New Array();
	Array = CommonClientServer.CollapseArray(Array);
	
	If Array.Count() > 0 Then
		
		If NumberOfOutputElements <> Undefined Then
			Boundary = Min(NumberOfOutputElements - 1, Array.UBound());
		Else
			Boundary = Array.UBound();
		EndIf;
		
		For IndexOf = 0 To Boundary Do
			ListForOutput.Add(Array[IndexOf]);
		EndDo;
		
		Supplement = Array.Count() - ListForOutput.Count();
		Return StrConcat(ListForOutput, ", ") + ?(Supplement > 0, " " + StrTemplate(NStr("vi = 'và còn %1';
																						|ru = 'и еще %1';
																						|en = 'and also %1'; fa = 'and also %1';
																						|it = 'e anche %1';
																						|pl = 'i jeszcze %1';
																						|tr = 've %1 daha'"), Supplement), "");
		
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Region Other

// Sets up the item character element
// 
// Parameters:
//  Item - FormField
//  ItemVariantsAreUsed - Boolean
Procedure ConfigureItemVariantsElement(Item, ItemVariantsAreUsed) Export
	
	If ItemVariantsAreUsed Then
		Item.InputHint = "";
		Item.Enabled = True;
		Item.AutoMarkIncomplete = True;
	Else
		Item.InputHint = NStr("vi = '<không sử dụng đặc tính>';
								|ru = '<характеристики не используются>';
								|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
								|it = '<le caratteristiche non vengono usate>';
								|pl = '<charakterystyki nie dotyczą>';
								|tr = '<varyantlar kullanılmamaktadır>'");
		Item.Enabled = False;
		Item.AutoMarkIncomplete = False;
	EndIf;
	
EndProcedure

// Adjusts the elements of the series of the finishedproduct being repaired
// 
// Parameters:
//  Form - ClientApplicationForm
//  ProductionProcessType - EnumRef.ProductionProcessTypes
//  UnderRepairBatchSpecificationStatus - Number
Procedure EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(Form, ProductionProcessType, UnderRepairBatchSpecificationStatus) Export

	VisibilityOfBatchesOfRepairedFinishedProduct =
		ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
		And Form.SeriesSpecificationParameters.FinishedProductBeingRepaired.UseItemsBatch;
	
	Form.Items.UnderRepairBatchSpecificationStatus.Visible = VisibilityOfBatchesOfRepairedFinishedProduct;
	Form.Items.UnderRepairBatch.Visible               = VisibilityOfBatchesOfRepairedFinishedProduct;
	
	If VisibilityOfBatchesOfRepairedFinishedProduct Then
		
		If Not UnderRepairBatchSpecificationStatus = 0 Then
			Form.Items.UnderRepairBatch.Enabled = True;
			Form.Items.UnderRepairBatch.InputHint = "";
		Else
			Form.Items.UnderRepairBatch.Enabled = False;
			Form.Items.UnderRepairBatch.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
														|ru = '<серия не указывается>';
														|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
														|it = '<serie non è indicata>';
														|pl = '<seria nie jest określana>';
														|tr = '<parti belirtilmemektedir>'");
		EndIf;
		
		If UnderRepairBatchSpecificationStatus = 1 Then
			Form.Items.UnderRepairBatch.AutoMarkIncomplete = True;
		Else
			Form.Items.UnderRepairBatch.AutoMarkIncomplete = False;
			Form.Items.UnderRepairBatch.MarkIncomplete = False;
		EndIf;
		
	EndIf;
	
EndProcedure

Function ParametersForRecalculatingNumberOfUnits() Export
	
	RecalculationParameters = New Structure("MustBeRoundOff", False);
	Return RecalculationParameters;
	
EndFunction

Function TitleOfTablePartByProcessType(ProductionProcessType, LanguageCode = Undefined) Export
	
	If ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
	 Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		Title = NStr("vi = 'Sản phẩm';
					|ru = 'Продукция';
					|en = 'Manufactured products'; fa = 'محصولات تولیدی';
					|it = 'Prodotti';
					|pl = 'Wiersze pozycji';
					|tr = 'İmal edilen ürünler'", LanguageCode);
	ElsIf ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		Title = NStr("vi = 'Công việc được thực hiện';
					|ru = 'Выполняемые работы';
					|en = 'Works to perform'; fa = 'کارهای قابل انجام';
					|it = 'Works to perform';
					|pl = 'Works to perform';
					|tr = 'Yapılan işler'", LanguageCode);
	ElsIf ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		Title = NStr("vi = 'Sản phẩm tháo rời';
					|ru = 'Разбираемые изделия';
					|en = 'Products for recycling'; fa = 'Products for recycling';
					|it = 'Prodotti in fase di smontaggio';
					|pl = 'Rozbierane produkty';
					|tr = 'Sökülen nihai ürünler'", LanguageCode);
	ElsIf ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair") Then
		Title = NStr("vi = 'Sản phẩm sửa chữa';
					|ru = 'Ремонтируемые изделия';
					|en = 'Products under R&M'; fa = 'Products under R&M';
					|it = 'Prodotti in manutenzione';
					|pl = 'Naprawiane produkty';
					|tr = 'Onarılan nihai ürünler'", LanguageCode);
	Else
		Title = NStr("vi = 'Sản phẩm';
					|ru = 'Продукция';
					|en = 'Manufactured products'; fa = 'محصولات تولیدی';
					|it = 'Prodotti';
					|pl = 'Wiersze pozycji';
					|tr = 'İmal edilen ürünler'", LanguageCode);
	EndIf;
	
	Return Title;
	
EndFunction

Procedure AddToStructureActionsCheckFillProductionWarehouse(Department, StructureOfActions, WarehouseFieldName = "Warehouse") Export

	ActionParameters = New Structure("Department, WarehouseFieldName", Department, WarehouseFieldName);
	
	StructureOfActions.Insert("CheckFillProductionWarehouse" , ActionParameters);
	StructureOfActions.Insert("FillInShopPantryAttribute"     , New Structure("WarehouseFieldName", WarehouseFieldName));
	
EndProcedure

// Returns the result of dividing two numbers
// 
// Parameters:
//  OnlyWholePart - Boolean -
//  Count       - Number -
//  StandardOfPackages - Number -
//  PackageData   - Structure -
// 
// Returns:
//  Number - The coefficient on the standard
//
Function CoefficientByStandard(OnlyWholePart, Count, StandardOfPackages, PackageData) Export
	
	Result = Count * PackageData.Denominator / (StandardOfPackages * PackageData.Numerator);
	
	Return ?(OnlyWholePart, Int(Result), Result);
	
EndFunction

#EndRegion

#EndRegion