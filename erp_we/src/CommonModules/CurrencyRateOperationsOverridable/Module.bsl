///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Enables or disables notifications that currency rate update is required.
//
// Parameters:
//  ShowWarning - Boolean - if False, do not show warnings.
//
Procedure OnDetermineWhetherCurrencyRateUpdateWarningRequired(ShowWarning) Export
	
EndProcedure

// Specifies the field name in the object used to determine the default currency.
// 
// Parameters:
//  PrintObjectType - Type - Valid Ref types are CatalogRef, DocumentRef, ChartOfCharacteristicTypesRef,
//   ChartOfAccountsRef, ChartOfCalculationTypesRef, BusinessProcessRef, TaskRef
//  NameOfCurrenciesField - String
// Example:
//  If PrintObjectType = Type("DocumentRef.Order") Then
//      
//      CurrencyFieldName = "DocumentCurrency";
//      
//  Else
//      
//      CurrencyFieldName = "CommonField.ManagementAccountingCurrency";
//      
//  EndIf;
//
Procedure OnDefineObjectDefaultCurrency(PrintObjectType, NameOfCurrenciesField) Export
	
	
	
EndProcedure

#EndRegion
