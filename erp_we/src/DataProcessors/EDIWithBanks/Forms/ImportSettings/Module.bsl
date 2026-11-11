#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(
		Object, Parameters.Object, "CreateCounterparties, PostDocuments, CounterpartyFillingModeByQRPayment");

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)

	ClosingParameters = New Structure;
	ClosingParameters.Insert("CreateCounterparties", Object.CreateCounterparties);
	ClosingParameters.Insert("PostDocuments", Object.PostDocuments);
	ClosingParameters.Insert("CounterpartyFillingModeByQRPayment", Object.CounterpartyFillingModeByQRPayment);
	
	Close(ClosingParameters);

EndProcedure

#EndRegion
