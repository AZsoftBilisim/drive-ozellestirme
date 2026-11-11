
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ErrorID", Record.ErrorID);
	Query.Text = "
	|SELECT
	|	Errors.Protocol AS Protocol
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS Errors
	|WHERE
	|	Errors.ErrorID = &ErrorID
	|";
	
	Selection = Query.Execute().Select();
	
	StructureFromRepository = Undefined;
	
	If Selection.Next() Then
		ProtocolStorage = Selection.Protocol; //ValueStorage
		StructureFromRepository = ProtocolStorage.Get();
	EndIf;
	
	If TypeOf(StructureFromRepository) = Type("Structure") Then
		
		ProtocolStructure = InformationRegisters.OrderStructureCalculationProtocol.ProtocolTemplate();
		FillPropertyValues(ProtocolStructure, StructureFromRepository);
		MessageText = ProtocolStructure.MessageText;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
EndProcedure

#EndRegion
