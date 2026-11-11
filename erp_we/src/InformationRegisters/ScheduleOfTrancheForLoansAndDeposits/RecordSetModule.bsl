#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Total = 0;
	For Each SetRow In ThisObject Do
		Total = Total + SetRow.Sum;
		SetRow.AmountTotal = Total;
	EndDo;
	
	CreateTableOfPaymentObjects();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("PaymentObject"));
	SetPrivilegedMode(False);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		For Each SetRow In ThisObject Do
			FillPropertyValues(SetRow, FillingData);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

Procedure CreateTableOfPaymentObjects()
	
	Contract = Common.ObjectAttributeValue(Filter.ScheduleOption.Value, "Owner");
	
	TableOfPaymentObjects = New ValueTable;
	TableOfPaymentObjects.Columns.Add("PaymentObject");
	TableOfPaymentObjects.Add().PaymentObject = Contract;
	
	AdditionalProperties.Insert("TableOfPaymentObjects", TableOfPaymentObjects);
	
EndProcedure

#EndIf