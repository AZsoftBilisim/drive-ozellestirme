////////////////////////////////////////////////////////////////////////////////
// The "Set of Server Calls" module contains procedures and functions for
// working with sets.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a list of blocked form elements.
// 
// Parameters:
//  TSName - String - name of the table part.
//
// Returns:
//  Array - Array of blocked elements.
//
Function ItemsToLock(TSName = Undefined) Export
	
	ItemsToLock = New Array;
	
	TabularSections = New Array;
	If TSName = Undefined Then
		TabularSections.Add("Goods");
		TabularSections.Add("junk");
		TabularSections.Add("Services");
		TabularSections.Add("ReturnedGoods");
		TabularSections.Add("SubstituteGoods");
		TabularSections.Add("CustomerShoppingCart");
		TabularSections.Add("AdjustmentTable");
	Else
		TabularSections.Add(TSName);
	EndIf;
	
	For Each TSName In TabularSections Do
		
		ItemsToLock.Add(TSName + "Products");
		ItemsToLock.Add(TSName + "Characteristic");
		ItemsToLock.Add(TSName + "Package");
		ItemsToLock.Add(TSName + "ProductsUnitOfMeasure");
		ItemsToLock.Add(TSName + "Count");
		ItemsToLock.Add(TSName + "NumberOfPackages");
		ItemsToLock.Add(TSName + "Price");
		ItemsToLock.Add(TSName + "Sum");
		ItemsToLock.Add(TSName + "VATRate");
		ItemsToLock.Add(TSName + "VATAmount");
		ItemsToLock.Add(TSName + "AmountIncludingVAT");
		ItemsToLock.Add(TSName + "PriceKind");
		ItemsToLock.Add(TSName + "SetIndex");
		ItemsToLock.Add(TSName + "CancellationReason");
		ItemsToLock.Add(TSName + "CanceledReasonsForCancellationNotUsed");
		ItemsToLock.Add(TSName + "Canceled");
		
	EndDo;
	
	Return ItemsToLock;
	
EndFunction

#Region PrintForms

// Returns True if the product String should be displayed with empty data in the columns
// except for the name.
// 
// Parameters:
//  LineProducts_ - LineOfATabularSection - Product line.
//  UseSets - Boolean - FO value use Sets.
//
// Returns:
//  Boolean - True if the product row should be displayed with empty data in the columns
//  except for the name.
Function DisplayOnlyTitle(LineProducts_, UseSets) Export
	
	If UseSetArea(LineProducts_, UseSets) Then
		Return OutputOnlySetHeader(LineProducts_, UseSets)
	ElsIf UseScope(LineProducts_, UseSets) Then
		Return DisplayOnlyComponentTitle(LineProducts_, UseSets)
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the product String should be displayed with empty data in the columns
// except for the name and this string is part of the set.
// 
// Parameters:
//  LineProducts_ - LineOfATabularSection - Product line.
//  UseSets - Boolean - FO value use Sets.
//
// Returns:
//  Boolean - True if the product line should be displayed with empty data in the columns
//  except for the name and this line is the components of the set.
Function DisplayOnlyComponentTitle(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.TheseAreComponents
		And LineProducts_.PresentationOptionInPrintForms = PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents")
		And (    LineProducts_.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares")
		   Or LineProducts_.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"))
		Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the product String should be displayed with empty data in columns
// except for the name and this string is a Set.
// 
// Parameters:
//  LineProducts_ - LineOfATabularSection - Product line.
//  UseSets - Boolean - FO value use Sets.
//
// Returns:
//  Boolean - True if the product line should be displayed with empty data in the columns
//  except for the name and this line is a Set.
Function OutputOnlySetHeader(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.IsRecordsSet
		And LineProducts_.PresentationOptionInPrintForms = PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents")
		And LineProducts_.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices")
		Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the set area should be used in the printed form.
// 
// Parameters:
//  LineProducts_ - LineOfATabularSection - The products line.
//  UseSets - Boolean - FO value use Sets.
//
// Returns:
//  Boolean - True if the set area is to be used in printed form.
//
Function UseSetArea(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.IsRecordsSet
		And LineProducts_.PresentationOptionInPrintForms = PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the component area should be used in the printed form.
// 
// Parameters:
//  LineProducts_ - LineOfATabularSection - Product line.
//  UseSets - Boolean - FO value use Sets.
//
// Returns:
//  Boolean - True if the component area is to be used in printed form.
//
Function UseScope(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.TheseAreComponents
		And LineProducts_.PresentationOptionInPrintForms = PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion