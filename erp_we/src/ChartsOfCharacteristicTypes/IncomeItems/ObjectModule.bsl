#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	ValueType = New TypeDescription("CatalogRef.Partners");
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("LoanAndDepositContracts") Then
			ValueType = New TypeDescription("CatalogRef.LoanAndDepositContracts");
	EndIf;
	
	IncomeItemsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		IncomeByAssets = (ValueType.ContainsType(Type("CatalogRef.Assets")));
		IntangibleAssetsAndRDIncome = (ValueType.ContainsType(Type("CatalogRef.IntangibleAssets")));
		LoanAndDepositContracts = ValueType.ContainsType(Type("CatalogRef.LoanAndDepositContracts"));
		
	EndIf;
	
	IncomeItemsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	IncomeItemsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
	IncomeItemsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion


#EndIf