#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	AccountingTypeFilledIn = False;
	
	If FillingData <> Undefined Then
		
		ArrayOfAccountingTypesToDelete = New Array;
		
		TypesOfAccounting = New Array;
		TypesOfAccounting.Add("Expenses");
		TypesOfAccounting.Add("Income");
	
		For Each AccountingKind In TypesOfAccounting Do
			UseAccountingType = False;
			If FillingData.Property(AccountingKind, UseAccountingType) Then
				If UseAccountingType Then
					AccountingTypeFilledIn = True;
					Break;
				Else
					ArrayOfAccountingTypesToDelete.Add(AccountingKind);
				EndIf;
			EndIf;
		EndDo;
		
		If ArrayOfAccountingTypesToDelete.Count() Then
			AvailableTypesOfAccounting = CommonClientServer.ArraysDifference(TypesOfAccounting, ArrayOfAccountingTypesToDelete);
			If AvailableTypesOfAccounting.Count() Then
				ThisObject[AvailableTypesOfAccounting.Get(0)] = True;
				AccountingTypeFilledIn = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not IsFolder And Not AccountingTypeFilledIn Then
		Expenses = True;
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf