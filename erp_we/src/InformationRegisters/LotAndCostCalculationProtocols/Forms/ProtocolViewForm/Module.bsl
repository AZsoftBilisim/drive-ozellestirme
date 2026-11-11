
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Period) Then
		Cancel = True;
		Return;
	EndIf;
	
	ArrayOfProtocols = New Array;
	CalculationProtocols = GetCalculationProtocols();
	
	If ValueIsFilled(CalculationProtocols) Then
		
		For Each KeyAndValue In CalculationProtocols Do
			CurProtocol = GetPaymentProtocol(KeyAndValue.Key, Parameters.Period);
			ArrayOfProtocols.Add(New FixedStructure(CurProtocol));
		EndDo;
		
	EndIf;
	
	ProtocolsForViewing = New FixedArray(ArrayOfProtocols);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Cancel = True;
	
	For Each CollectionItem In ProtocolsForViewing Do
		
		CurProtocol = New Structure("Protocol, Title");
		FillPropertyValues(CurProtocol, CollectionItem);
		
		CurProtocol.Protocol.Show(CurProtocol.Title);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetCalculationProtocols()
	
	Return InformationRegisters.LotAndCostCalculationErrors.GetCalculationProtocols(
		Parameters.Period,
		Parameters.CompanyArray);
		
EndFunction

&AtServer
// Returns the Protocol of the calculation.
//
Function GetPaymentProtocol(Id, Period)
	
	Title = CostCalculationProtocol.OutputProtocolHeader(Period);
	Protocol  = InformationRegisters.LotAndCostCalculationProtocols.GetProtocolText(Id, , Period);
	
	Return New Structure("Protocol, Title", Protocol, Title);
	
EndFunction

#EndRegion
