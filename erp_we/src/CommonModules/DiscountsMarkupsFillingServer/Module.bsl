#Region Public

// This function checks whether the object's discounts need to be calculated.
//
// Parameters:
//  Object - FormDataStructure - object being checked
//  ManagedDiscounts - ValueList - list of managed discounts
//  FormIdentifier - UUID - Unique identifier of the form
//  CalculatedDiscountsAddressInStorage - String - address of the storage where the calculated discounts/mark-UPS will be placed.
//
// Returns:
//  Boolean -
//
Function DiscountsMustBeRecalculated(
	Object, ManagedDiscounts, FormIdentifier, CalculatedDiscountsAddressInStorage) Export
	
	DiscountsHaveChanged = False;
	
	CalculationParameters = NewParametersCalculate();
	CalculationParameters.ApplyToObject					 = False;
	CalculationParameters.OnlyPreliminaryCalculation		 = False;
	CalculationParameters.RestoreManagedDiscounts	 = True;
	CalculationParameters.ManagedDiscounts					 = ManagedDiscounts;
	CalculatedDiscounts = Calculate(Object, CalculationParameters);
	
	CurrentDiscountRowsCount = CalculatedDiscounts.TableDiscountsMarkups.Count();
	If CurrentDiscountRowsCount <> Object.DiscountsMarkups.Count() Then 
		DiscountsHaveChanged = True;
	Else
		
		For LineNumber = 1 To CurrentDiscountRowsCount Do
			LineCurDiscounts      = Object.DiscountsMarkups[LineNumber-1];
			LineCalculatedDiscounts = CalculatedDiscounts.TableDiscountsMarkups[LineNumber-1];
			
			If    LineCurDiscounts.Sum          <> LineCalculatedDiscounts.Sum
				Or LineCurDiscounts.ConnectionKey      <> LineCalculatedDiscounts.ConnectionKey
				Or LineCurDiscounts.DiscountMarkup  <> LineCalculatedDiscounts.DiscountMarkup
				Or LineCurDiscounts.RemindLater <> LineCalculatedDiscounts.RemindLater Then
				DiscountsHaveChanged = True;
				Break;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	If FormIdentifier <> Undefined Then
		CalculatedDiscountsAddressInStorage = PutToTempStorage(CalculatedDiscounts, FormIdentifier);
	EndIf;
	
	Return DiscountsHaveChanged;
	
EndFunction

// This procedure cancels the discounts calculated for the item.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  TSName - String - name of the table part.
//  CalculateAmountWithVAT - Boolean - Calculate the amount with VAT.
//  CalculateAmountOfSettlements_1 - Boolean - Calculate the amount of settlements.
//  CancelAutoDiscountsOnly - Boolean - Cancel only automatic discounts (mark-UPS).
//
Procedure CancelDiscounts(
	Object, 
	TSName, 
	CalculateAmountWithVAT=False, 
	CalculateAmountOfSettlements_1=False, 
	CancelAutoDiscountsOnly = False) Export
	
	If Not Object.Ref.Metadata().TabularSections.Find("DiscountsMarkups") = Undefined Then
		Object.DiscountsMarkups.Clear();
	EndIf;
	
	ClearWHDiscounts(Object, TSName, CalculateAmountWithVAT, CalculateAmountOfSettlements_1, CancelAutoDiscountsOnly);
	
	If Common.HasObjectAttribute("DiscountsAreCalculated",Object.Ref.Metadata()) Then
		Object.DiscountsAreCalculated = False;
	EndIf;
	
EndProcedure


// Calculates discounts for the document.
// Called from document forms.
//
// Parameters:
//  Object - See DiscountsMarkupsServer.Calculate.Object
//  InputParameters - See NewParametersCalculate
//
// Returns:
// 	See DiscountsMarkupsServer.Calculate
//
Function Calculate(Object, InputParameters) Export
	
	CalculationResult2 = DiscountsMarkupsServer.Calculate(Object, InputParameters);
	
	Return CalculationResult2;
	
EndFunction

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscounts - See Calculate
//  SalesInExcessOfOrder - Boolean - Implementation in excess of the order.
//
Procedure ApplyCalculationResult(Object, AppliedDiscounts, SalesInExcessOfOrder = False) Export

	DiscountsMarkupsServer.ApplyCalculationResult(Object, AppliedDiscounts, SalesInExcessOfOrder);

EndProcedure


// The procedure assigns manual discounts in the table part
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  TSName - String - name of the table part.
//  DiscountAmountForDistribution - Number - The amount of the discount (mark-up) to be distributed.
//  InputParameters - See NewOptionsAssignManualDiscount
//
Procedure AssignAManualDiscount(Object, TSName, DiscountAmountForDistribution, InputParameters) Export
	
	DiscountParameters = New Structure();
	DiscountParameters.Insert("AutomaticDiscountsAreUsed", False);
	DiscountParameters.Insert("OnlyForActiveRows", False);
	DiscountParameters.Insert("CalculateAmountWithVAT", False);
	DiscountParameters.Insert("CalculateAmountOfSettlements_1", False);
	DiscountParameters.Insert("SelectedRows", Undefined);
	DiscountParameters.Insert("AddressInTempStorage", Undefined);
	DiscountParameters.Insert("SalesInExcessOfOrder", False);
	
	FillPropertyValues(DiscountParameters, InputParameters);
	
	If TSName = "Services" Then
		QuantityName = "Count";
	ElsIf InputParameters.Property("ColumnNameQuantity") 
			  And Not IsBlankString(InputParameters.ColumnNameQuantity) Then
		QuantityName = InputParameters.ColumnNameQuantity;
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	If DiscountParameters.SelectedRows <> Undefined Then
		TabularSectionRows = New Array();
		
		For Each CurRow In DiscountParameters.SelectedRows Do
			FoundRow = Object[TSName].FindByID(CurRow);
			If ?(DiscountParameters.SalesInExcessOfOrder, FoundRow.RowCode = 0, True) Then
				TabularSectionRows.Add(FoundRow);
			EndIf;
		EndDo;
		
	Else
		If DiscountParameters.OnlyForActiveRows Then
			TabularSectionRows = Object[TSName].FindRows(New Structure("Active", True));
		ElsIf DiscountParameters.SalesInExcessOfOrder Then
			TabularSectionRows = Object[TSName].FindRows(New Structure("RowCode", 0));
		Else
			TabularSectionRows = Object[TSName];
		EndIf;
	EndIf;
	
	Data = GetFromTempStorage(DiscountParameters.AddressInTempStorage); // See NewConstraintStructure
	Data.Restrictions.Columns.Add("DiscountAmountForDistribution", New TypeDescription("Number"));
	
	Sum0Mode = False;
	
	If DiscountAmountForDistribution >=0 Then
		MaximumAmountOfDiscountMarkup = Data.Restrictions.Total("MaximumAmountOfManualDiscount");
	Else
		MaximumAmountOfDiscountMarkup = Data.Restrictions.Total("MaximumAmountOfManualMarkUp");
	EndIf;
	If MaximumAmountOfDiscountMarkup = 0 Then
		Sum0Mode = True;
	EndIf;
	If Sum0Mode Then
		MaximumAmountOfDiscountMarkup = Data.Restrictions.Total("AmountWithoutADiscount");
	EndIf;
	
	If Not ValueIsFilled(MaximumAmountOfDiscountMarkup) Then
		MaximumAmountOfDiscountMarkup = 0;
	EndIf;
	
	MAmountOfDiscountToBeDistributed = DiscountAmountForDistribution;
	For Each Restriction In Data.Restrictions Do
		
		If MAmountOfDiscountToBeDistributed >=0 Then
			MaximumAmountOfDiscountMarkUpRestrictions = Restriction.MaximumAmountOfManualDiscount;
		Else
			MaximumAmountOfDiscountMarkUpRestrictions = Restriction.MaximumAmountOfManualMarkUp;
		EndIf;
		If Sum0Mode Then
			MaximumAmountOfDiscountMarkUpRestrictions = Restriction.AmountWithoutADiscount;
		EndIf;
		
		If Not ValueIsFilled(MaximumAmountOfDiscountMarkUpRestrictions) Then
			MaximumAmountOfDiscountMarkUpRestrictions = 0;
		EndIf;
		
		If MaximumAmountOfDiscountMarkup <> 0 Then
			
			Restriction.DiscountAmountForDistribution = MAmountOfDiscountToBeDistributed * (MaximumAmountOfDiscountMarkUpRestrictions / MaximumAmountOfDiscountMarkup);
			
			MAmountOfDiscountToBeDistributed = MAmountOfDiscountToBeDistributed - Restriction.DiscountAmountForDistribution;
			MaximumAmountOfDiscountMarkup = MaximumAmountOfDiscountMarkup - MaximumAmountOfDiscountMarkUpRestrictions;
			
		EndIf;
		
	EndDo;
	
	For Each TSRow In TabularSectionRows Do
		
		
		ProductData_1 = Data.Goods.Find(TSRow.Products, "Products");
		
		For Each Restriction In Data.Restrictions Do
			
			If  Not (ProductData_1.PriceGroup = Restriction.PriceGroup
				      Or (Data.Restrictions.Find(ProductData_1.PriceGroup, "PriceGroup") = Undefined
				      And Restriction.PriceGroup = Catalogs.PriceGroups.EmptyRef())) Then
				Continue;
			EndIf;
			
			AmountWithoutADiscount = TSRow[QuantityName] * TSRow.Price;
			DiscountMarkupAmount = ?(DiscountParameters.AutomaticDiscountsAreUsed, TSRow.DiscountMarkupAmount, 0);
			
			If Restriction.AmountWithoutADiscount <> 0 Then
				TSRow.ManualDiscount = (AmountWithoutADiscount) * (Restriction.DiscountAmountForDistribution / Restriction.AmountWithoutADiscount);
			Else
				TSRow.ManualDiscount = 0;
			EndIf;
			Restriction.DiscountAmountForDistribution = Restriction.DiscountAmountForDistribution - TSRow.ManualDiscount;
			Restriction.AmountWithoutADiscount = Restriction.AmountWithoutADiscount - AmountWithoutADiscount;
			
			If AmountWithoutADiscount <> 0 Then
				TSRow.PercentRateOfManualDiscount = 100 * TSRow.ManualDiscount / AmountWithoutADiscount;
			Else
				TSRow.PercentRateOfManualDiscount = 0;
			EndIf;
			
			DiscountAmount = DiscountMarkupAmount + TSRow.ManualDiscount;
			
			If DiscountParameters.AutomaticDiscountsAreUsed Then
				If AmountWithoutADiscount <> 0 Then
					TSRow.PercentRateOfAutomaticDiscountMarkup = ?(AmountWithoutADiscount = 0, 0 , 100 * DiscountMarkupAmount / AmountWithoutADiscount);
				Else
					TSRow.PercentRateOfAutomaticDiscountMarkup = 0;
				EndIf;
			EndIf;
			
			TSRow.Sum    = AmountWithoutADiscount - ?(DiscountAmount > AmountWithoutADiscount, AmountWithoutADiscount, DiscountAmount);
			TSRow.VATAmount = DiscountsMarkupsServer.CalculateVATAmount(TSRow.Sum, TSRow.VATRate, Object);
			
			If DiscountParameters.CalculateAmountWithVAT Then
				TSRow.AmountIncludingVAT = TSRow.Sum + ?(Object.PriceIncludesVAT, 0, TSRow.VATAmount);
			EndIf;
			
			If DiscountParameters.CalculateAmountOfSettlements_1 Then
				TSRow.AmountARAP = 0;
			EndIf;
			
		EndDo;
	EndDo;
	
	Object.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object[TSName], Object.PriceIncludesVAT);
	
EndProcedure



// This procedure cancels manual discounts in the table part
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  TSName - String - name of the table part.
//  AutomaticDiscountsAreUsed - Boolean - Indicates whether automatic discounts (mark-UPS) are used.
//  CalculateAmountWithVAT - Boolean - Calculate the amount with VAT.
//  CalculateAmountOfSettlements_1 - Boolean - Calculate the amount of settlements.
//  SalesInExcessOfOrder - Boolean - Implementation in excess of the order.
//  AdditionalParameters - Structure,Undefined - Additional parameters for canceling discounts :
//  	* ColumnNameQuantity - String - name of the column with the Quantity field.
//
Procedure CancelManualDiscounts(Object, TSName, AutomaticDiscountsAreUsed, CalculateAmountWithVAT, 
	CalculateAmountOfSettlements_1=False, SalesInExcessOfOrder = False, AdditionalParameters = Undefined) Export
	
	If TSName="Services" Then
		QuantityName = "Count";
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("ColumnNameQuantity") Then
		QuantityName = AdditionalParameters.ColumnNameQuantity;
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	If SalesInExcessOfOrder Then
		TabularSectionRows = Object[TSName].FindRows(New Structure("RowCode", 0));
	Else
		TabularSectionRows = Object[TSName];
	EndIf;
	
	For Each TSRow In TabularSectionRows Do
		
		If TSRow.ManualDiscount <> 0 Or TSRow.PercentRateOfManualDiscount <> 0 Then
			
			TSRow.ManualDiscount = 0;
			TSRow.PercentRateOfManualDiscount = 0;
			
			AmountWithoutADiscount = TSRow[QuantityName] * TSRow.Price;
			
			DiscountMarkupAmount = ?(AutomaticDiscountsAreUsed, TSRow.DiscountMarkupAmount, 0);
			
			TSRow.Sum    = AmountWithoutADiscount - ?(DiscountMarkupAmount > AmountWithoutADiscount, AmountWithoutADiscount, DiscountMarkupAmount);
			TSRow.VATAmount = DiscountsMarkupsServer.CalculateVATAmount(TSRow.Sum, TSRow.VATRate, Object);
			
			If CalculateAmountWithVAT Then
				TSRow.AmountIncludingVAT = TSRow.Sum + ?(Object.PriceIncludesVAT, 0, TSRow.VATAmount);
			EndIf;
			
			If CalculateAmountOfSettlements_1 Then
				TSRow.AmountARAP = 0;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Object.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object[TSName], Object.PriceIncludesVAT);
	
EndProcedure


// Address of data for calculating manual discounts in temporary storage
//
// Parameters:
//  Form						 - ClientApplicationForm - Form
//  UUID		 - UUID - address in temporary storage
//  Parameters					 - See NewParametersAddressDataForCalculatingManualDiscounts
// 
// Returns:
//  String - the address in the temporary storage.
//
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
	Form, UUID, Parameters) Export
	
	TableName 					= Parameters.TableName;
	OnlyForSelectedLines 	= Parameters.OnlyForSelectedLines;
	TableNameOfSelectedRows 	= Parameters.TableNameOfSelectedRows;
	ActiveLinesOnly 		= Parameters.ActiveLinesOnly;
	UseRestrictions_ 	= Parameters.UseRestrictions_;
	SalesInExcessOfOrder 		= Parameters.SalesInExcessOfOrder;
	
	CustomerTermsOfSales = Undefined;
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Terms") Then
		CustomerTermsOfSales = Form.Object.Terms;
	EndIf;

	UseManualDiscounts                     = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseManualDiscountRestrictionsInSales = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers");
	
	If ValueIsFilled(CustomerTermsOfSales) Then
		UseRestrictionsOnAgreements = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	Else
		UseRestrictionsOnAgreements = False;
	EndIf;

	UseRestrictionsOfManualDiscounts = UseRestrictions_ And UseManualDiscounts And (UseManualDiscountRestrictionsInSales Or UseRestrictionsOnAgreements);

	If TableName = "Services" Then
		QuantityName = "Count";
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	WhenPreparingToPlaceResultOfCalculatingManualDiscountsInTemporaryStorage(Form, QuantityName);
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products",              New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add(QuantityName,               New TypeDescription("Number",,,New NumberQualifiers(15,3)));
	Goods.Columns.Add("Price",                      New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	Goods.Columns.Add("DiscountMarkupAmount", New TypeDescription("Number"));
	Goods.Columns.Add("ManualDiscount",         New TypeDescription("Number"));
	
	If OnlyForSelectedLines Then
		
		For Each CurRow In Form.Items[?(TableNameOfSelectedRows = Undefined, TableName, TableNameOfSelectedRows)].SelectedRows Do
			
			CollectionRow = Form.Object[TableName].FindByID(CurRow);
			
			If ?(SalesInExcessOfOrder, CollectionRow = Undefined Or CollectionRow.RowCode > 0, CollectionRow = Undefined) Then
				Continue;
			EndIf;
			
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, CollectionRow);
			
		EndDo;
	Else
		If SalesInExcessOfOrder Then
			FoundRows = Form.Object[TableName].FindRows(New Structure("RowCode", 0));
			For Each TSRow In FoundRows Do
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TSRow);
			EndDo;
		ElsIf ActiveLinesOnly Then
			FoundRows =Form.Object[TableName].FindRows(New Structure("Active", True));
			For Each TSRow In FoundRows Do
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TSRow);
			EndDo;
		Else
			For Each TSRow In Form.Object[TableName] Do
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TSRow);
			EndDo;
		EndIf;
		
	EndIf;
	
	If UseRestrictionsOfManualDiscounts Then
		
		ManualDiscountRestrictions = SalesSettingsForUsersServer.RestrictionsOnDiscountsMargins(CustomerTermsOfSales, Users.CurrentUser());
		PriceGroups = ManualDiscountRestrictions.UnloadColumn("PriceGroup");
		
	Else
		
		ManualDiscountRestrictions = New ValueTable;
		ManualDiscountRestrictions.Columns.Add("PriceGroup", New TypeDescription("CatalogRef.PriceGroups"));
		ManualDiscountRestrictions.Columns.Add("MaximumPercentageForManualDiscount",  New TypeDescription("Number",,,New NumberQualifiers(15,2)));
		ManualDiscountRestrictions.Columns.Add("MaximumPercentageForManualMarkup", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
		
		Restriction = ManualDiscountRestrictions.Add();
		Restriction.PriceGroup = Catalogs.PriceGroups.EmptyRef();
		Restriction.MaximumPercentageForManualDiscount  = 999.99;
		Restriction.MaximumPercentageForManualMarkup = 999.99;
		
	EndIf;
	
	QueryText =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods." + QuantityName + " " + "AS NumberOfPackages,
	|	Goods.Price AS PricePerPackaging,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	Goods.ManualDiscount AS ManualDiscount
	|INTO TempTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.PricePerPackaging AS PricePerPackaging,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	Goods.ManualDiscount AS ManualDiscount
	|INTO TemporaryTableOfGoods_
	|FROM
	|	TempTable AS Goods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = Goods.Products)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManualDiscountRestrictions.PriceGroup AS PriceGroup,
	|	ManualDiscountRestrictions.MaximumPercentageForManualDiscount AS MaximumPercentageForManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
	|INTO ManualDiscountRestrictions
	|FROM
	|	&ManualDiscountRestrictions AS ManualDiscountRestrictions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.PriceGroup AS PriceGroup,
	|	T.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	T.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	T.ManualDiscount AS ManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualDiscount AS MaximumPercentageForManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup,
	|	CAST(ManualDiscountRestrictions.MaximumPercentageForManualDiscount / 100 * T.AmountWithoutADiscount AS NUMBER(31,2)) AS MaximumAmountOfManualDiscount,
	|	CAST(ManualDiscountRestrictions.MaximumPercentageForManualMarkup / 100 * T.AmountWithoutADiscount AS NUMBER(31,2)) AS MaximumAmountOfManualMarkUp
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN TemporaryTableOfGoods_.PriceGroup IN (&PriceGroups)
	|				THEN TemporaryTableOfGoods_.PriceGroup
	|			ELSE VALUE(Catalog.PriceGroups.EmptyRef)
	|		END AS PriceGroup,
	|		SUM(CAST(TemporaryTableOfGoods_.NumberOfPackages * TemporaryTableOfGoods_.PricePerPackaging AS NUMBER(31,2))) AS AmountWithoutADiscount,
	|		SUM(TemporaryTableOfGoods_.DiscountMarkupAmount) AS DiscountMarkupAmount,
	|		SUM(TemporaryTableOfGoods_.ManualDiscount) AS ManualDiscount
	|	FROM
	|		TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|	
	|	GROUP BY
	|		CASE
	|			WHEN TemporaryTableOfGoods_.PriceGroup IN (&PriceGroups)
	|				THEN TemporaryTableOfGoods_.PriceGroup
	|			ELSE VALUE(Catalog.PriceGroups.EmptyRef)
	|		END) AS T
	|		LEFT JOIN ManualDiscountRestrictions AS ManualDiscountRestrictions
	|		ON (ManualDiscountRestrictions.PriceGroup = T.PriceGroup)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PriceGroup AS PriceGroup
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Goods", Goods);
	Query.Parameters.Insert("ManualDiscountRestrictions", ManualDiscountRestrictions);
	Query.Parameters.Insert("PriceGroups", PriceGroups);
	
	Result = Query.ExecuteBatch();
	
	Restrictions = Result[3].Unload(); // ValueTable
	Restrictions.Indexes.Add("PriceGroup");
	
	Goods = Result[4].Unload(); // ValueTable
	Goods.Indexes.Add("Products");
	
	StructureOfConstraints = NewConstraintStructure();
	StructureOfConstraints.Restrictions = Restrictions;
	StructureOfConstraints.Goods = Goods;
	StructureOfConstraints.UseRestrictionsOfManualDiscounts = UseRestrictionsOfManualDiscounts;
	
	Return PutToTempStorage(StructureOfConstraints, UUID);
	
EndFunction

// Address of data for calculating manual discounts in the temporary purchase storage
//
// Parameters:
//  Form						 - ClientApplicationForm - Form
//  UUID		 - UUID - address in temporary storage
//  Parameters		 			 - See NewParametersAddressDataForCalculatingManualDiscounts
// 
// Returns:
//  String - the address in the temporary storage.
//
Function AddressOfDataForCalculatingManualDiscountsInTemporaryPurchaseStorage(
	Form, UUID, Parameters) Export

	TableName 					= Parameters.TableName;
	OnlyForSelectedLines 	= Parameters.OnlyForSelectedLines;
	TableNameOfSelectedRows 	= Parameters.TableNameOfSelectedRows;
	ActiveLinesOnly 		= Parameters.ActiveLinesOnly;
	UseRestrictions_ 	= Parameters.UseRestrictions_;

	TermsOfPurchases = Undefined;
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Terms") Then
		TermsOfPurchases = Form.Object.Terms;
	EndIf;

	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");

	UseRestrictionsOfManualDiscounts = UseRestrictions_ And UseManualDiscounts And Not GetFunctionalOption("BaseVersion");

	If TableName = "Services" Then
		QuantityName = "Count";
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products",              New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add(QuantityName,               New TypeDescription("Number",,,New NumberQualifiers(15,3)));
	Goods.Columns.Add("Price",                      New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	Goods.Columns.Add("DiscountMarkupAmount", New TypeDescription("Number"));
	Goods.Columns.Add("ManualDiscount",         New TypeDescription("Number"));
	
	If OnlyForSelectedLines Then
		
		For Each CurRow In Form.Items[?(TableNameOfSelectedRows = Undefined, TableName, TableNameOfSelectedRows)].SelectedRows Do
			
			CollectionRow = Form.Object[TableName].FindByID(CurRow);
			
			If CollectionRow = Undefined Then
				Continue;
			EndIf;
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, CollectionRow);
			
		EndDo;
	Else
		
		If Not ActiveLinesOnly Then
			For Each TSRow In Form.Object[TableName] Do
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TSRow);
			EndDo;
		Else
			FoundRows =Form.Object.Goods.FindRows(New Structure("Active", True));
			For Each TSRow In FoundRows Do
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, TSRow);
			EndDo;
		EndIf;
		
	EndIf;
	
	If UseRestrictionsOfManualDiscounts Then
		
		Query = New Query("
			|SELECT
			|	VALUE(Catalog.PriceGroups.EmptyRef) AS PriceGroup,
			|	TermsOfPurchaseFromVendors.PercentRateOfManualDiscount     AS MaximumPercentageForManualDiscount,
			|	TermsOfPurchaseFromVendors.MaximumPercentageForManualMarkup    AS MaximumPercentageForManualMarkup
			|FROM
			|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
			|WHERE
			|	TermsOfPurchaseFromVendors.Ref = &TermsOfPurchases
			|");
		Query.SetParameter("TermsOfPurchases", TermsOfPurchases);
		
		ManualDiscountRestrictions = Query.Execute().Unload();
		
		PriceGroups = ManualDiscountRestrictions.UnloadColumn("PriceGroup");
		
	Else
		
		ManualDiscountRestrictions = New ValueTable;
		ManualDiscountRestrictions.Columns.Add("PriceGroup", New TypeDescription("CatalogRef.PriceGroups"));
		ManualDiscountRestrictions.Columns.Add("MaximumPercentageForManualDiscount",  New TypeDescription("Number",,,New NumberQualifiers(15,2)));
		ManualDiscountRestrictions.Columns.Add("MaximumPercentageForManualMarkup", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
		
		Restriction = ManualDiscountRestrictions.Add();
		Restriction.PriceGroup = Catalogs.PriceGroups.EmptyRef();
		Restriction.MaximumPercentageForManualDiscount  = 999.99;
		Restriction.MaximumPercentageForManualMarkup = 999.99;
		
	EndIf;
	
	QueryText =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods." + QuantityName + " " + "AS NumberOfPackages,
	|	Goods.Price AS PricePerPackaging,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	Goods.ManualDiscount AS ManualDiscount
	|INTO TempTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.PricePerPackaging AS PricePerPackaging,
	|	Goods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	Goods.ManualDiscount AS ManualDiscount
	|INTO TemporaryTableOfGoods_
	|FROM
	|	TempTable AS Goods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = Goods.Products)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManualDiscountRestrictions.PriceGroup AS PriceGroup,
	|	ManualDiscountRestrictions.MaximumPercentageForManualDiscount AS MaximumPercentageForManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
	|INTO ManualDiscountRestrictions
	|FROM
	|	&ManualDiscountRestrictions AS ManualDiscountRestrictions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.PriceGroup AS PriceGroup,
	|	T.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	T.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	T.ManualDiscount AS ManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualDiscount AS MaximumPercentageForManualDiscount,
	|	ManualDiscountRestrictions.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup,
	|	CAST(ManualDiscountRestrictions.MaximumPercentageForManualDiscount / 100 * T.AmountWithoutADiscount AS NUMBER(31,2)) AS MaximumAmountOfManualDiscount,
	|	CAST(ManualDiscountRestrictions.MaximumPercentageForManualMarkup / 100 * T.AmountWithoutADiscount AS NUMBER(31,2)) AS MaximumAmountOfManualMarkUp
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN TemporaryTableOfGoods_.PriceGroup IN (&PriceGroups)
	|				THEN TemporaryTableOfGoods_.PriceGroup
	|			ELSE VALUE(Catalog.PriceGroups.EmptyRef)
	|		END AS PriceGroup,
	|		SUM(CAST(TemporaryTableOfGoods_.NumberOfPackages * TemporaryTableOfGoods_.PricePerPackaging AS NUMBER(31,2))) AS AmountWithoutADiscount,
	|		SUM(TemporaryTableOfGoods_.DiscountMarkupAmount) AS DiscountMarkupAmount,
	|		SUM(TemporaryTableOfGoods_.ManualDiscount) AS ManualDiscount
	|	FROM
	|		TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|	
	|	GROUP BY
	|		CASE
	|			WHEN TemporaryTableOfGoods_.PriceGroup IN (&PriceGroups)
	|				THEN TemporaryTableOfGoods_.PriceGroup
	|			ELSE VALUE(Catalog.PriceGroups.EmptyRef)
	|		END) AS T
	|		LEFT JOIN ManualDiscountRestrictions AS ManualDiscountRestrictions
	|		ON (ManualDiscountRestrictions.PriceGroup = T.PriceGroup)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PriceGroup AS PriceGroup
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Goods", Goods);
	Query.Parameters.Insert("ManualDiscountRestrictions", ManualDiscountRestrictions);
	Query.Parameters.Insert("PriceGroups", PriceGroups);
	
	Result = Query.ExecuteBatch();
	
	Restrictions = Result[3].Unload(); // ValueTable
	Restrictions.Indexes.Add("PriceGroup");
	
	Goods = Result[4].Unload(); // ValueTable
	Goods.Indexes.Add("Products");
	
	StructureOfConstraints = NewConstraintStructure();
	StructureOfConstraints.Restrictions = Restrictions;
	StructureOfConstraints.Goods = Goods;
	StructureOfConstraints.UseRestrictionsOfManualDiscounts = UseRestrictionsOfManualDiscounts;
	
	Return PutToTempStorage(StructureOfConstraints, UUID);

EndFunction


//
// Parameters:
//  Object - DocumentObject.CustomerInvoice - Object.
//
// Returns:
//  Structure - with properties:
//   * TableOfGoods - ValueTable- Columns:
//  	** RowCode 				- Number - line code of the client's Order document, client's Requestreferences
//  	** ConnectionKey 				- Number - link key for the client's Order, client's Requestreferences
//  	** ZoomRatio 				- Number -
//  	** PercentRateOfAutomaticDiscountMarkup - Number -
//  	** PercentRateOfManualDiscount 		- Number -
//  	** SalesOrder 				- DocumentRef.SalesOrder,DocumentRef.RequestForReturnOfGoodsFromCustomer -
//  	** ImplementationQuantity 		- Number -
//  	** OrderQuantity 			- Number -
//  	** OrderAmountOfAutomaticDiscount - Number -
//  	** OrderAmountOfManualDiscount 	- Number -
//  	** CurrencyConversionRate - Number -
//  	** DiscountMarkupAmount - Number -
//  	** ManualDiscount 		- Number -
//   * DiscountsOrderMargins - ValueTable - Columns:
//  	** ConnectionKey 	- Number -
//  	** DiscountMarkup - CatalogRef.DiscountsMarkups -
//  	** Sum 		- Number - the sum of discounts/surcharges taking into account the conversion factor
//  	** SalesOrder  - DocumentRef.SalesOrder, DocumentRef.RequestForReturnOfGoodsFromCustomer -
//
Function DiscountsMarginsOnOrder(Object) Export
	
	QueryResults = RequestDiscountMarkUpForOrder(Object).ExecuteBatch();
	
	Result = New Structure();
	Result.Insert("TableOfGoods",QueryResults[3].Unload());
	Result.Insert("DiscountsOrderMargins",QueryResults[4].Unload());
	Result.Insert("AccrualOfBonusPointsOfOrder",QueryResults[5].Unload());
	
	Return Result;
	
EndFunction



// Saves processed messages.
//
// Parameters:
//  Object - FormDataStructure - Object.
//  Messages - Array - Messages to save.
//
Procedure SaveSpentMessages(Object, Messages) Export
	
	For Each TSRow In Messages Do
		FoundRows = Object.DiscountsMarkups.FindRows(New Structure("DiscountMarkup, ConnectionKey", TSRow.DiscountMarkup, -1));
		For Each FoundRow In FoundRows Do
			FoundRow.RemindLater = TSRow.RemindLater;
		EndDo;
	EndDo;

EndProcedure

// Returns a structure containing messages for the object.
//
// Parameters:
//  Object - FormDataStructure, DocumentObject - Object.
//  AdditionalParameters - Structure - ability to define Attribute names, OPTIONAL:
//  	* BankingDetailsNamePartner -String - availability is not required
//  	* DoNotOutputMessagesByConvention -Boolean - availability is not required
//
// Returns:
//  Structure - with properties:
//   * Messages - Array of Structure:
//   	**DiscountMarkup - CatalogRef.DiscountsMarkups
//   	**RemindLater - Boolean
//   * AutomaticallyOpen - Boolean - Automatically open a message.
//   * LoyaltyCard - CatalogRef.LoyaltyCards - Loyalty card.
//   * Partner - CatalogRef.Partners - Partner.
//   * Counterparty - CatalogRef.Counterparties -
//   * Terms - CatalogRef.TermsOfSale 
//
Function TheStructureOfTheMessages(Object, AdditionalParameters = Undefined) Export
	
	Messages = New Array;
	
	BankingDetailsNamePartner = "Partner";
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		If AdditionalParameters.Property("BankingDetailsNamePartner") Then
			BankingDetailsNamePartner = AdditionalParameters.BankingDetailsNamePartner
		EndIf;
	EndIf;
	
	AutomaticallyOpen = False;
	
	ThereAreDiscountsExtraCharges = CommonClientServer.HasAttributeOrObjectProperty(Object, "DiscountsMarkups");
	If ThereAreDiscountsExtraCharges Then
		FoundRows = Object.DiscountsMarkups.FindRows(New Structure("ConnectionKey", -1));
		For Each TSRow In FoundRows Do
			Messages.Add(New Structure("DiscountMarkup, RemindLater", TSRow.DiscountMarkup, TSRow.RemindLater));
			If TSRow.RemindLater Then
				AutomaticallyOpen = True;
			EndIf;
		EndDo;
	EndIf;
	
	TheStructureOfTheMessages = New Structure;
	TheStructureOfTheMessages.Insert("Messages", Messages);
	TheStructureOfTheMessages.Insert("AutomaticallyOpen", AutomaticallyOpen);
	TheStructureOfTheMessages.Insert("LoyaltyCard", Object.LoyaltyCard);
	TheStructureOfTheMessages.Insert("Partner", Object[BankingDetailsNamePartner]);
	
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") 
		And TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceiptReturn") Then
		TheStructureOfTheMessages.Insert("Counterparty", Object.Counterparty);
	EndIf;
	
	DoNotOutputMessagesByConvention = (TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceipt"))
	                                   Or (TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceiptReturn"))
	                                   Or (TypeOf(AdditionalParameters) = Type("Structure")
	                                   And AdditionalParameters.Property("DoNotOutputMessagesByConvention")
	                                   And AdditionalParameters.DoNotOutputMessagesByConvention);
	
	If Not DoNotOutputMessagesByConvention Then
		TheStructureOfTheMessages.Insert("Terms", Object.Terms);
	EndIf;
	
	Return TheStructureOfTheMessages;
	
EndFunction

// Configures the display of the show messages command on the form.
//
// Parameters:
//  Object - FormDataStructure - Object.
//  FormItem - FormButton - form element.
//  Visible - Boolean - Indicates whether the form element is visible.
//  AdditionalParameters - See TheStructureOfTheMessages.AdditionalParameters
//
Procedure ConfigureShowMessagesCommand(Object, FormItem, Visible = True, AdditionalParameters = Undefined) Export
	
	TheStructureOfTheMessages = TheStructureOfTheMessages(Object, AdditionalParameters);
	TotalMessages = TheStructureOfTheMessages.Messages.Count();
	UnreadMessages = 0;
	For Each TSRow In TheStructureOfTheMessages.Messages Do
		If TSRow.RemindLater Then
			UnreadMessages = UnreadMessages + 1;
		EndIf;
	EndDo;
	FormItem.Visible = TotalMessages > 0 And Visible;
	If UnreadMessages > 0 Then
		FormItem.Title = StrTemplate(NStr("vi = 'Hiển thị thông báo chưa đọc (%1)';
											|ru = 'Показать непрочитанные сообщения (%1)';
											|en = 'Show unread messages (%1)'; fa = 'Show unread messages (%1)';
											|it = 'Visualizza i messaggi non letti (%1)';
											|pl = 'Pokaż nieprzeczytane wiadomości (%1)';
											|tr = 'Okunmamış mesajları göster (%1)'"), UnreadMessages);
	Else
		FormItem.Title = StrTemplate(NStr("vi = 'Hiển thị thông báo (%1)';
											|ru = 'Показать сообщения (%1)';
											|en = 'Show messages (%1)'; fa = 'Show messages (%1)';
											|it = 'Visualizza i messaggi (%1)';
											|pl = 'Pokaż wiadomości (%1)';
											|tr = 'Mesajları göster (%1)'"), TheStructureOfTheMessages.Messages.Count());
	EndIf;
	
EndProcedure

#Region Constructors

// Constructor for the Calculate () method parameter.
// 
// Returns:
//  Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - ValueList of CatalogRef.DiscountsMarkups - Managed discounts (mark-UPS).
//  depending on the document.
//   * SalesInExcessOfOrder - Boolean - for the Document.Realizationduring.
//   * ColumnNamePackaging - String - for the Document.Commercial offer to the client.
//   * ColumnNameNumberOfPackages - String - for the Document.Commercial offer to the client.
//   * FillInImplementationByOrder - Boolean - for the Document.Realizationstovarovservices when realizationposacazam = True.
//
Function NewParametersCalculate() Export
	
	Parameters = New Structure;
	Parameters.Insert("OnlyPreliminaryCalculation",		False);
	Parameters.Insert("ApplyToObject",					False);
	Parameters.Insert("RestoreManagedDiscounts",	False);
	Parameters.Insert("ManagedDiscounts",					New ValueList());
	
	Parameters.Insert("ColumnNamePackaging",				"");		// for a commercial offer to a customer
	Parameters.Insert("ColumnNameNumberOfPackages", 		"");		// for a commercial offer to a customer
	Parameters.Insert("SalesInExcessOfOrder",				False);		// for the implementation of goods services
	Parameters.Insert("FillInImplementationByOrder",		False);		// for the implementation of goods services
	
	Return Parameters;
	
EndFunction

// Parameter constructorinputparameters of the assign handshake Method()
//
// Returns:
//  Structure - A structure with properties, all properties are optional to existence:
//   * AutomaticDiscountsAreUsed - Boolean - 
//   * OnlyForActiveRows - Boolean - 
//   * CalculateAmountWithVAT - Boolean - 
//   * CalculateAmountOfSettlements_1 - Boolean - 
//   * SalesInExcessOfOrder - Boolean - 
//   * SelectedRows - Array,Undefined - 
//   * AddressInTempStorage - String,Undefined - 
//   * ColumnNameQuantity - String,Undefined - 
//
Function NewOptionsAssignManualDiscount() Export
	
	Parameters = New Structure();
	Parameters.Insert("AutomaticDiscountsAreUsed", False);
	Parameters.Insert("OnlyForActiveRows", False);
	Parameters.Insert("CalculateAmountWithVAT", False);
	Parameters.Insert("CalculateAmountOfSettlements_1", False);
	Parameters.Insert("SalesInExcessOfOrder", False);
	Parameters.Insert("SelectedRows", Undefined);
	Parameters.Insert("AddressInTempStorage", Undefined);
	Parameters.Insert("ColumnNameQuantity", Undefined);
	
	Return Parameters;
	
EndFunction
	
// Constructor of the parameter parameter Of the call method addressedfor the calculation of the handshake in the modern storage ().
// 
// Returns:
//  Structure - structure with properties:
//		* TableName 				 - String - Only a preliminary calculation.
//		* TableNameOfSelectedRows	 - String,Undefined - Name of the table of selected rows.
//		* OnlyForSelectedLines	 - Boolean - Use only for selected rows.
//		* ActiveLinesOnly		 - Boolean - Only active rows.
//		* UseRestrictions_	 - Boolean - Use restrictions.
//		* SalesInExcessOfOrder		 - Boolean - Use the implementation in excess of the order.
//
Function NewParametersAddressDataForCalculatingManualDiscounts() Export
	
	Parameters = New Structure;
	Parameters.Insert("TableName", "");
	Parameters.Insert("OnlyForSelectedLines", False);
	Parameters.Insert("TableNameOfSelectedRows", Undefined);
	Parameters.Insert("ActiveLinesOnly", False);
	Parameters.Insert("UseRestrictions_", True);
	Parameters.Insert("SalesInExcessOfOrder", False);
	
	Return Parameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// This procedure cancels manual discounts in the table part.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  TSName 							- String 	- name of the table part.
//  CalculateAmountWithVAT 			- Boolean 	- Calculate the amount with VAT.
//  CalculateAmountOfSettlements_1 - Boolean 	- Calculate the amount of settlements.
//  CancelAutoDiscountsOnly 		- Boolean 	- Cancel only automatic discounts (mark-UPS).
//
Procedure ClearWHDiscounts(
	Object, 
	TSName, 
	CalculateAmountWithVAT=False, 
	CalculateAmountOfSettlements_1=False, 
	CancelAutoDiscountsOnly = False)
	
	If TSName = "Services" Then
		QuantityName = "Count";
	Else
		QuantityName = "NumberOfPackages";
	EndIf;

	MetadataOfObject = Object.Ref.Metadata();
	ThereIsAmountOfAutomaticDiscount = TMCommonUse.ThereArePropsForPartOfObject("DiscountMarkupAmount", MetadataOfObject, TSName);
	ThereIsManualDiscountAmount = TMCommonUse.ThereArePropsForPartOfObject("ManualDiscount", MetadataOfObject, TSName);

	For Each TSRow In Object[TSName] Do
		
		If ThereIsAmountOfAutomaticDiscount Then
			TSRow.DiscountMarkupAmount   = 0;
			TSRow.PercentRateOfAutomaticDiscountMarkup = 0;
		EndIf;
		
		If ThereIsManualDiscountAmount And Not CancelAutoDiscountsOnly Then
			TSRow.ManualDiscount           = 0;
			TSRow.PercentRateOfManualDiscount         = 0;
		EndIf;
		
		AmountWithoutADiscount = TSRow[QuantityName] * TSRow.Price - TSRow.ManualDiscount;
		
		TSRow.Sum    = AmountWithoutADiscount;
		TSRow.VATAmount = DiscountsMarkupsServer.CalculateVATAmount(TSRow.Sum, TSRow.VATRate, Object);
		
		If CalculateAmountWithVAT Then
			TSRow.AmountIncludingVAT = TSRow.Sum + ?(Object.PriceIncludesVAT, 0, TSRow.VATAmount);
		EndIf;
		
		If CalculateAmountOfSettlements_1 Then
			TSRow.AmountARAP = 0;
		EndIf;
		
	EndDo;
	
	Object.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object[TSName], Object.PriceIncludesVAT);
	
EndProcedure

// The constructor function of structure constraints
// 
// Returns:
// 	Structure - with properties:
// 	* Restrictions - ValueTable - 
// 	* Goods - ValueTable - 
// 	* UseRestrictionsOfManualDiscounts - Boolean - 
// 
Function NewConstraintStructure()
	
	Result = New Structure();
	Result.Insert("Restrictions");
	Result.Insert("Goods");
	Result.Insert("UseRestrictionsOfManualDiscounts");
	
	Return Result;
	
EndFunction

Function RequestDiscountMarkUpForOrder(Object)
	
	Query = New Query(
	"SELECT
	|	MutualSettlementsExchangeRate.CourseNumerator * CurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseNumerator * MutualSettlementsExchangeRate.CourseDenominator) AS ConversionFactor_
	|INTO OrderCurrencyToDocumentCurrency
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &ARAPCurrency AND BaseCurrency = &BaseCurrency) AS MutualSettlementsExchangeRate
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.SalesOrder AS SalesOrder,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	CAST(Goods.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(Goods.RowCode AS NUMBER) AS RowCode,
	|	CAST(Goods.ConnectionKey AS NUMBER) AS ConnectionKey,
	|	CAST(Goods.Count AS NUMBER) AS Count
	|INTO DocumentGoods
	|FROM
	|	&TableOfGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.RowCode AS RowCode,
	|	GoodsFromOrder.ConnectionKey AS ConnectionKey,
	|	GoodsSales_.Count / GoodsFromOrder.Count AS ZoomRatio,
	|	GoodsFromOrder.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	GoodsFromOrder.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsFromOrder.Ref AS SalesOrder,
	|	GoodsSales_.Count AS ImplementationQuantity,
	|	GoodsFromOrder.Count AS OrderQuantity,
	|	GoodsFromOrder.DiscountMarkupAmount AS OrderAmountOfAutomaticDiscount,
	|	GoodsFromOrder.ManualDiscount AS OrderAmountOfManualDiscount,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction AS OrderAmountOfBonusPointsToBeDebited,
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency AS OrderIsAmountOfBonusPointsToBeDebitedInCurrency,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency AS OrderIsAmountOfBonusPointsAccruedInCurrency,
	|	OrderCurrencyToDocumentCurrency.ConversionFactor_ AS CurrencyConversionRate,
	|	GoodsFromOrder.DiscountMarkupAmount * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS DiscountMarkupAmount,
	|	GoodsFromOrder.ManualDiscount * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS ManualDiscount,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction * (GoodsSales_.Count / GoodsFromOrder.Count) AS AmountOfBonusPointsToDeduction,
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS AmountOfEarnedBonusPointsInCurrency
	|INTO GoodsFromOrder
	|FROM
	|	DocumentGoods AS GoodsSales_
	|		LEFT JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON GoodsSales_.RowCode = GoodsFromOrder.RowCode
	|			AND GoodsSales_.Products = GoodsFromOrder.Products
	|			AND GoodsSales_.Characteristic = GoodsFromOrder.Characteristic
	|			AND GoodsSales_.SalesOrder = GoodsFromOrder.Ref
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsFromOrder.RowCode,
	|	GoodsFromOrder.ConnectionKey,
	|	GoodsSales_.Count / GoodsFromOrder.Count,
	|	GoodsFromOrder.PercentRateOfAutomaticDiscountMarkup,
	|	GoodsFromOrder.PercentRateOfManualDiscount,
	|	GoodsFromOrder.Ref,
	|	GoodsSales_.Count,
	|	GoodsFromOrder.Count,
	|	GoodsFromOrder.DiscountMarkupAmount,
	|	GoodsFromOrder.ManualDiscount,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction,
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency,
	|	OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.DiscountMarkupAmount * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.ManualDiscount * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction * (GoodsSales_.Count / GoodsFromOrder.Count),
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency * (GoodsSales_.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_
	|FROM
	|	DocumentGoods AS GoodsSales_
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsFromOrder
	|		ON GoodsSales_.RowCode = GoodsFromOrder.RowCode
	|			AND GoodsSales_.Products = GoodsFromOrder.Products
	|			AND GoodsSales_.Characteristic = GoodsFromOrder.Characteristic
	|			AND GoodsSales_.SalesOrder = GoodsFromOrder.Ref
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.RowCode AS RowCode,
	|	GoodsFromOrder.ConnectionKey AS ConnectionKey,
	|	GoodsFromOrder.ZoomRatio AS ZoomRatio,
	|	GoodsFromOrder.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	GoodsFromOrder.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsFromOrder.SalesOrder AS SalesOrder,
	|	GoodsFromOrder.ImplementationQuantity AS ImplementationQuantity,
	|	GoodsFromOrder.OrderQuantity AS OrderQuantity,
	|	GoodsFromOrder.OrderAmountOfAutomaticDiscount AS OrderAmountOfAutomaticDiscount,
	|	GoodsFromOrder.OrderAmountOfManualDiscount AS OrderAmountOfManualDiscount,
	|	GoodsFromOrder.OrderAmountOfBonusPointsToBeDebited,
	|	GoodsFromOrder.OrderIsAmountOfBonusPointsToBeDebitedInCurrency,
	|	GoodsFromOrder.OrderIsAmountOfBonusPointsAccruedInCurrency,
	|	GoodsFromOrder.CurrencyConversionRate AS CurrencyConversionRate,
	|	GoodsFromOrder.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	GoodsFromOrder.ManualDiscount AS ManualDiscount,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction,
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS Sum,
	|	DiscountsMarkups.Ref AS SalesOrder
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		INNER JOIN Document.SalesOrder.DiscountsMarkups AS DiscountsMarkups
	|			LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|			ON (TRUE)
	|		ON GoodsFromOrder.SalesOrder = DiscountsMarkups.Ref
	|			AND GoodsFromOrder.ConnectionKey = DiscountsMarkups.ConnectionKey
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountsMarkups.ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup,
	|	DiscountsMarkups.Sum * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	DiscountsMarkups.Ref
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.DiscountsMarkups AS DiscountsMarkups
	|			LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|			ON (TRUE)
	|		ON GoodsFromOrder.SalesOrder = DiscountsMarkups.Ref
	|			AND GoodsFromOrder.ConnectionKey = DiscountsMarkups.ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref AS SalesOrder,
	|	TabularSection.ConnectionKey AS ConnectionKey,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
	|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
	|	TabularSection.AccrualDate AS AccrualDate,
	|	TabularSection.DateOfDeduction AS DateOfDeduction,
	|	TabularSection.AmountOfBonusPoints AS AmountOfBonusPoints
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		INNER JOIN Document.SalesOrder.BonusPointAccrual AS TabularSection
	|		ON GoodsFromOrder.SalesOrder = TabularSection.Ref
	|			AND GoodsFromOrder.ConnectionKey = TabularSection.ConnectionKey
	| 
	|UNION ALL
	|
	|SELECT
	|	TabularSection.Ref AS SalesOrder,
	|	TabularSection.ConnectionKey AS ConnectionKey,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
	|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
	|	TabularSection.AccrualDate AS AccrualDate,
	|	TabularSection.DateOfDeduction AS DateOfDeduction,
	|	TabularSection.AmountOfBonusPoints AS AmountOfBonusPoints
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
	|		ON GoodsFromOrder.SalesOrder = TabularSection.Ref
	|			AND GoodsFromOrder.ConnectionKey = TabularSection.ConnectionKey
	|");
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("ARAPCurrency", Object.ARAPCurrency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("TableOfGoods", Object.Goods.Unload(, "SalesOrder, Products, Characteristic, RowCode, Count, ConnectionKey"));
	
	Return Query;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - must contain:
// 		* Object - FormDataStructure - must contain:
// 			** Ref - DocumentRef.CommercialProposalForCustomer
// 	QuantityName - String - changeable parameter
//
Procedure WhenPreparingToPlaceResultOfCalculatingManualDiscountsInTemporaryStorage(Form, QuantityName) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm")
		And TypeOf(Form.Object) = Type("FormDataStructure")
		And Form.Object.Property("Ref") Then
			
		If TypeOf(Form.Object.Ref) = Type("DocumentRef.CommercialProposalForCustomer") Then
		
			QuantityName = "Count";
			
		EndIf;

	EndIf;
	
EndProcedure

#EndRegion

