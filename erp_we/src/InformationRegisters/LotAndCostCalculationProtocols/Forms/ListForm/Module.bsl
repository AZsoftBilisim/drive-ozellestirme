
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.FormDeleteProtocolsWithoutErrors.Visible = Users.IsFullUser();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenProtocol(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenProtocol(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = GetProtocol(CurrentData);
	
	Result.Protocol.Show(Result.Title);
	
EndProcedure

&AtClient
Procedure DeleteProtocolsWithoutErrors(Command)
	
	DeleteProtocolsWithoutErrorsOnServer();
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region Private

// Get the protocol.
// 
// Parameters:
//  CurrentData - InformationRegisterRecord.LotAndCostCalculationProtocols - Current data
// 
// Returns:
//  Structure:
// * Protocol - TextDocument -
// * Title - String -
&AtServerNoContext
Function GetProtocol(CurrentData)
	
	Title = CostCalculationProtocol.OutputProtocolHeader(
		CurrentData.CalculationPeriod);
	
	Protocol  = InformationRegisters.LotAndCostCalculationProtocols.GetProtocolText(
		CurrentData.Id,
		CurrentData.Period); // protocol recording period
	
	Return New Structure("Protocol, Title", Protocol, Title);
	
EndFunction

&AtServerNoContext
Procedure DeleteProtocolsWithoutErrorsOnServer()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	LotAndCostCalculationProtocols.Period 	   AS Period,
	|	LotAndCostCalculationProtocols.Id AS Id
	|FROM
	|	InformationRegister.LotAndCostCalculationProtocols AS LotAndCostCalculationProtocols
	|WHERE
	|	NOT LotAndCostCalculationProtocols.HadErrors
	|
	|ORDER BY
	|	Period";
	
	RecordSet = InformationRegisters.LotAndCostCalculationProtocols.CreateRecordSet();
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordSet.Filter.Period.Set(Selection.Period);
		RecordSet.Filter.Id.Set(Selection.Id);
		
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

#EndRegion
