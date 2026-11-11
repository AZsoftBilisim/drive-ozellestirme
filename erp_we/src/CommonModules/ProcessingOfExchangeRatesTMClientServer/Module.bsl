///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Converts the amount from the current currency to the new currency based on their exchange rate parameters. 
// Options currencies it is possible to function Remotecharset.Getcurrencies.
//
// Parameters:
//   Sum - Number     - the amount should be recalculated.
//
//   SourceRateParameters - Structure - currency exchange rate parameters to be recalculated from:
//    * Currency - CatalogRef.Currencies - link to the currency being converted.
//    * CourseNumerator - Number - the exchange rate of the currency being converted.
//    * CourseDenominator - Number - multiplicity of the currency being recalculated.
//
//   NewRateParameters   - Structure - parameters of the currency exchange rate to be converted to:
//    * Currency - CatalogRef.Currencies - link to the currency that is being converted to.
//    * CourseNumerator - Number - the exchange rate is the numerator of the currency that is being converted.
//    * CourseDenominator - Number - the exchange rate is the denominator of the currency that is being converted.
//
// Returns: 
//   Number - the amount recalculated at the new exchange rate.
//
Function ConvertAtRate(Sum, SourceRateParameters, NewRateParameters) Export
	
	If SourceRateParameters.Currency = NewRateParameters.Currency
		Or (SourceRateParameters.CourseNumerator = NewRateParameters.CourseNumerator 
			And SourceRateParameters.CourseDenominator = NewRateParameters.CourseDenominator) Then
		
		Return Sum;
	EndIf;
	
	If SourceRateParameters.CourseNumerator = 0
		Or SourceRateParameters.CourseDenominator = 0
		Or NewRateParameters.CourseNumerator = 0
		Or NewRateParameters.CourseDenominator = 0 Then
		
		Return 0;
	EndIf;
	
	Return Round((Sum * SourceRateParameters.CourseNumerator * NewRateParameters.CourseDenominator) 
		/ (NewRateParameters.CourseNumerator * SourceRateParameters.CourseDenominator), 2);
EndFunction

#EndRegion
