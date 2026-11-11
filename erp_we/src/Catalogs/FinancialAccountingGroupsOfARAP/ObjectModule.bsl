#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder And Not ARAPAccountingInLocalAccountingCurrency And Not ARAPInCurrency Then
		ARAPAccountingInLocalAccountingCurrency = True;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	CalculationViewFilledIn = False;
	
	If FillingData <> Undefined Then
		
		ArrayOfCalculationTypesToDelete = New Array;
		
		Catalogs.FinancialAccountingGroupsOfARAP.ConvertSelectionParametersSelection(FillingData);
		TypesOfCalculations = Catalogs.FinancialAccountingGroupsOfARAP.TypesOfCalculations();
	
		For Each ARAPType In TypesOfCalculations Do
			UseCalculationView = False;
			If FillingData.Property(ARAPType, UseCalculationView) Then
				If UseCalculationView Then
					CalculationViewFilledIn = True;
					Break;
				Else
					ArrayOfCalculationTypesToDelete.Add(ARAPType);
				EndIf;
			EndIf;
		EndDo;
		
		If ArrayOfCalculationTypesToDelete.Count() Then
			AvailableTypesOfCalculations = CommonClientServer.ArraysDifference(TypesOfCalculations, ArrayOfCalculationTypesToDelete);
			If AvailableTypesOfCalculations.Count() Then
				ThisObject[AvailableTypesOfCalculations.Get(0)] = True;
				CalculationViewFilledIn = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not IsFolder And Not CalculationViewFilledIn Then
		CustomersARAPAccounting = True;
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf